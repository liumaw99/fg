package post

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/pagination"
)

// Service handles post business logic.
type Service struct {
	repo *Repository
	log  *logger.Logger
}

// NewService creates a new post service.
func NewService(repo *Repository, log *logger.Logger) *Service {
	return &Service{repo: repo, log: log}
}

// CreatePost creates a new post.
func (s *Service) CreatePost(ctx context.Context, userID uuid.UUID, req CreatePostRequest) (*PostResponse, error) {
	// Validate content
	if req.Content == "" {
		return nil, errors.New("invalid_content", 400, "content is required")
	}

	mediaAssetIDs, err := s.validateMediaAssetIDs(ctx, userID, req.MediaAssetIDs)
	if err != nil {
		return nil, err
	}

	// Create post in transaction
	tx, err := s.repo.client.Tx(ctx)
	if err != nil {
		s.log.Error("failed to start transaction", logger.Error(err))
		return nil, errors.ErrInternal
	}

	repo := NewRepository(tx.Client())

	post, err := repo.CreatePost(ctx, userID, req.Content, mediaAssetIDs)
	if err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to create post", logger.Error(err))
		return nil, errors.ErrInternal
	}

	// Create outbox event
	err = repo.CreateOutboxEvent(ctx, "post.events.v1", post.ID.String(), map[string]any{
		"event_type": "PostCreated",
		"post_id":    post.ID.String(),
		"user_id":    userID.String(),
		"content":    req.Content,
		"created_at": time.Now().UTC(),
	})
	if err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to create outbox event", logger.Error(err))
		return nil, errors.ErrInternal
	}

	if err := tx.Commit(); err != nil {
		s.log.Error("failed to commit transaction", logger.Error(err))
		return nil, errors.ErrInternal
	}

	s.log.Info("post created",
		logger.String("post_id", post.ID.String()),
		logger.String("user_id", userID.String()),
	)

	return s.buildPostResponse(ctx, post, uuid.Nil)
}

// CreateRepost creates a repost of an active top-level post.
func (s *Service) CreateRepost(ctx context.Context, userID, targetPostID uuid.UUID, req CreateRepostRequest) (*PostResponse, error) {
	mediaAssetIDs, err := s.validateMediaAssetIDs(ctx, userID, req.MediaAssetIDs)
	if err != nil {
		return nil, err
	}

	original, err := s.repo.GetPostByID(ctx, targetPostID)
	if err != nil || original.Status != "active" {
		return nil, errors.ErrNotFound
	}
	if original.ReplyToID != uuid.Nil {
		return nil, errors.New("invalid_repost_target", 400, "replies cannot be reposted")
	}
	if original.RepostOfID != uuid.Nil {
		original, err = s.repo.GetPostByID(ctx, original.RepostOfID)
		if err != nil || original.Status != "active" {
			return nil, errors.ErrNotFound
		}
	}

	tx, err := s.repo.client.Tx(ctx)
	if err != nil {
		s.log.Error("failed to start transaction", logger.Error(err))
		return nil, errors.ErrInternal
	}
	repo := NewRepository(tx.Client())

	repost, err := repo.CreateRepost(ctx, userID, original.ID, req.Content, mediaAssetIDs)
	if err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to create repost", logger.Error(err))
		return nil, errors.ErrInternal
	}

	if err := repo.IncrementRepostCount(ctx, original.ID); err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to increment repost count", logger.Error(err))
		return nil, errors.ErrInternal
	}

	if err := repo.CreateNotification(ctx, original.UserID, userID, "repost", original.ID, "reposted your post"); err != nil {
		s.log.Error("failed to create repost notification", logger.Error(err))
	}

	err = repo.CreateOutboxEvent(ctx, "post.events.v1", repost.ID.String(), map[string]any{
		"event_type":       "PostReposted",
		"post_id":          repost.ID.String(),
		"original_post_id": original.ID.String(),
		"user_id":          userID.String(),
		"created_at":       time.Now().UTC(),
	})
	if err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to create outbox event", logger.Error(err))
		return nil, errors.ErrInternal
	}

	if err := tx.Commit(); err != nil {
		s.log.Error("failed to commit transaction", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return s.buildPostResponse(ctx, repost, userID)
}

// GetPost retrieves a post by ID.
func (s *Service) GetPost(ctx context.Context, userID, postID uuid.UUID) (*PostResponse, error) {
	post, err := s.repo.GetPostByID(ctx, postID)
	if err != nil {
		return nil, errors.ErrNotFound
	}

	if post.Status != "active" {
		return nil, errors.New("post_deleted", 404, "post not found")
	}

	return s.buildPostResponse(ctx, post, userID)
}

// CreateReply creates a reply under a post or another reply.
func (s *Service) CreateReply(ctx context.Context, userID, parentPostID uuid.UUID, req CreateReplyRequest) (*PostResponse, error) {
	if req.Content == "" {
		return nil, errors.New("invalid_content", 400, "content is required")
	}

	parent, err := s.repo.GetPostByID(ctx, parentPostID)
	if err != nil || parent.Status != "active" {
		return nil, errors.ErrNotFound
	}

	tx, err := s.repo.client.Tx(ctx)
	if err != nil {
		s.log.Error("failed to start transaction", logger.Error(err))
		return nil, errors.ErrInternal
	}
	repo := NewRepository(tx.Client())

	reply, err := repo.CreateReply(ctx, userID, parentPostID, req.Content)
	if err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to create reply", logger.Error(err))
		return nil, errors.ErrInternal
	}

	if err := repo.IncrementReplyCount(ctx, parentPostID); err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to increment reply count", logger.Error(err))
		return nil, errors.ErrInternal
	}

	if err := repo.CreateNotification(ctx, parent.UserID, userID, "reply", parentPostID, "replied to your post"); err != nil {
		s.log.Error("failed to create reply notification", logger.Error(err))
	}

	err = repo.CreateOutboxEvent(ctx, "post.events.v1", reply.ID.String(), map[string]any{
		"event_type":     "PostReplied",
		"post_id":        reply.ID.String(),
		"parent_post_id": parentPostID.String(),
		"user_id":        userID.String(),
		"created_at":     time.Now().UTC(),
	})
	if err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to create outbox event", logger.Error(err))
		return nil, errors.ErrInternal
	}

	if err := tx.Commit(); err != nil {
		s.log.Error("failed to commit transaction", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return s.buildPostResponse(ctx, reply, userID)
}

// ListReplies retrieves replies for the given post as a bounded nested tree.
func (s *Service) ListReplies(ctx context.Context, postID, currentUserID uuid.UUID, params pagination.Params) (*PostListResponse, error) {
	params.ValidateAndNormalize(100)
	if _, err := s.repo.GetPostByID(ctx, postID); err != nil {
		return nil, errors.ErrNotFound
	}

	replies, err := s.repo.ListReplies(ctx, postID, params.Limit+1)
	if err != nil {
		s.log.Error("failed to list replies", logger.Error(err))
		return nil, errors.ErrInternal
	}

	result, err := s.buildPostListResponse(ctx, replies, params.Limit, currentUserID)
	if err != nil {
		return nil, err
	}

	parentIDs := make([]uuid.UUID, 0, len(result.Posts))
	for _, reply := range result.Posts {
		id, err := uuid.Parse(reply.ID)
		if err == nil {
			parentIDs = append(parentIDs, id)
		}
	}

	children, err := s.repo.ListReplyDescendants(ctx, parentIDs, 5, 50)
	if err != nil {
		return result, nil
	}
	s.attachNestedReplies(ctx, result.Posts, children, currentUserID)

	return result, nil
}

func (s *Service) attachNestedReplies(ctx context.Context, replies []PostResponse, children map[uuid.UUID][]*ent.Post, currentUserID uuid.UUID) {
	for i := range replies {
		parentID, err := uuid.Parse(replies[i].ID)
		if err != nil {
			continue
		}
		childList := children[parentID]
		if len(childList) == 0 {
			continue
		}
		childResult, err := s.buildPostListResponse(ctx, childList, len(childList), currentUserID)
		if err != nil {
			continue
		}
		replies[i].Replies = childResult.Posts
		s.attachNestedReplies(ctx, replies[i].Replies, children, currentUserID)
	}
}

// DeletePost soft-deletes a post if the user owns it.
func (s *Service) DeletePost(ctx context.Context, userID, postID uuid.UUID) error {
	post, err := s.repo.GetPostByID(ctx, postID)
	if err != nil {
		return errors.ErrNotFound
	}

	if post.UserID != userID {
		return errors.New("forbidden", 403, "you can only delete your own posts")
	}

	if err := s.repo.DeletePost(ctx, postID); err != nil {
		s.log.Error("failed to delete post", logger.Error(err))
		return errors.ErrInternal
	}

	if post.ReplyToID != uuid.Nil {
		if err := s.repo.DecrementReplyCount(ctx, post.ReplyToID); err != nil {
			s.log.Error("failed to decrement reply count", logger.Error(err))
		}
	}
	if post.RepostOfID != uuid.Nil {
		if err := s.repo.DecrementRepostCount(ctx, post.RepostOfID); err != nil {
			s.log.Error("failed to decrement repost count", logger.Error(err))
		}
	}

	s.log.Info("post deleted",
		logger.String("post_id", postID.String()),
		logger.String("user_id", userID.String()),
	)

	return nil
}

// ListUserPosts retrieves posts by a user.
func (s *Service) ListUserPosts(ctx context.Context, targetUserID, currentUserID uuid.UUID, params pagination.Params) (*PostListResponse, error) {
	params.ValidateAndNormalize(50)

	posts, err := s.repo.ListUserPosts(ctx, targetUserID, params.Cursor, params.Limit)
	if err != nil {
		s.log.Error("failed to list user posts", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return s.buildPostListResponse(ctx, posts, params.Limit, currentUserID)
}

// ListPosts retrieves all active posts.
func (s *Service) ListPosts(ctx context.Context, currentUserID uuid.UUID, params pagination.Params) (*PostListResponse, error) {
	params.ValidateAndNormalize(50)

	posts, err := s.repo.ListPosts(ctx, params.Cursor, params.Limit)
	if err != nil {
		s.log.Error("failed to list posts", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return s.buildPostListResponse(ctx, posts, params.Limit, currentUserID)
}

// buildPostResponse builds a PostResponse from an ent.Post (single-post path).
func (s *Service) buildPostResponse(ctx context.Context, post *ent.Post, currentUserID uuid.UUID) (*PostResponse, error) {
	authors, _ := s.repo.GetAuthorsByIDs(ctx, []uuid.UUID{post.UserID})
	return s.assemblePostResponse(ctx, post, currentUserID, authors, true), nil
}

// assemblePostResponse turns a Post + prefetched authors map into a PostResponse.
func (s *Service) assemblePostResponse(ctx context.Context, post *ent.Post, currentUserID uuid.UUID, authors map[uuid.UUID]*AuthorInfo, includeRepost bool) *PostResponse {
	stats, err := s.repo.GetPostStats(ctx, post.ID)
	if err != nil {
		stats = &ent.PostStats{}
	}

	postMedia, err := s.repo.GetPostMediaAssets(ctx, post.ID)
	if err != nil {
		postMedia = []*ent.PostMedia{}
	}

	var mediaURLs []MediaItem
	if len(postMedia) > 0 {
		mediaAssetIDs := make([]uuid.UUID, 0, len(postMedia))
		for _, pm := range postMedia {
			mediaAssetIDs = append(mediaAssetIDs, pm.MediaAssetID)
		}

		assets, err := s.repo.GetMediaAssets(ctx, mediaAssetIDs)
		if err == nil {
			assetMap := make(map[uuid.UUID]*ent.MediaAsset, len(assets))
			for _, a := range assets {
				assetMap[a.ID] = a
			}
			for _, pm := range postMedia {
				if asset, ok := assetMap[pm.MediaAssetID]; ok {
					mediaURLs = append(mediaURLs, MediaItem{
						ID:           asset.ID.String(),
						URL:          asset.URL,
						ThumbnailURL: asset.ThumbnailURL,
						MimeType:     asset.MimeType,
					})
				}
			}
		}
	}

	replyCount := stats.ReplyCount
	if count, err := s.repo.CountReplyDescendants(ctx, post.ID, 50); err == nil {
		replyCount = count
	}

	resp := &PostResponse{
		ID:            post.ID.String(),
		UserID:        post.UserID.String(),
		Content:       post.Content,
		Status:        post.Status,
		Visibility:    post.Visibility,
		LikeCount:     stats.LikeCount,
		ReplyCount:    replyCount,
		RepostCount:   stats.RepostCount,
		BookmarkCount: stats.BookmarkCount,
		ViewCount:     stats.ViewCount,
		MediaURLs:     mediaURLs,
		CreatedAt:     post.CreatedAt,
		UpdatedAt:     post.UpdatedAt,
	}

	if author, ok := authors[post.UserID]; ok && author != nil {
		resp.Author = &PostAuthor{
			ID:          author.ID.String(),
			Username:    author.Username,
			DisplayName: author.DisplayName,
			AvatarURL:   author.AvatarURL,
		}
	}

	if post.ReplyToID != uuid.Nil {
		resp.ReplyToID = post.ReplyToID.String()
		if parent, err := s.repo.GetPostByID(ctx, post.ReplyToID); err == nil {
			if author, ok := authors[parent.UserID]; ok && author != nil {
				resp.ReplyToAuthorName = author.DisplayName
				if resp.ReplyToAuthorName == "" {
					resp.ReplyToAuthorName = author.Username
				}
			}
		}
	}
	if post.RepostOfID != uuid.Nil {
		resp.RepostOfID = post.RepostOfID.String()
		if includeRepost {
			if original, err := s.repo.GetPostByID(ctx, post.RepostOfID); err == nil && original.Status == "active" {
				if _, ok := authors[original.UserID]; !ok {
					if originalAuthors, err := s.repo.GetAuthorsByIDs(ctx, []uuid.UUID{original.UserID}); err == nil {
						for id, author := range originalAuthors {
							authors[id] = author
						}
					}
				}
				resp.RepostOf = s.assemblePostResponse(ctx, original, currentUserID, authors, false)
			}
		}
	}

	if currentUserID != uuid.Nil {
		isLiked, _ := s.repo.IsLiked(ctx, post.ID, currentUserID)
		resp.IsLiked = isLiked
	}

	return resp
}

// buildPostListResponse builds a paginated list response with one batched author query.
func (s *Service) buildPostListResponse(ctx context.Context, posts []*ent.Post, limit int, currentUserID uuid.UUID) (*PostListResponse, error) {
	hasMore := len(posts) > limit
	if hasMore {
		posts = posts[:limit]
	}

	authorIDs := make([]uuid.UUID, 0, len(posts))
	seen := make(map[uuid.UUID]struct{}, len(posts))
	for _, p := range posts {
		if _, ok := seen[p.UserID]; !ok {
			seen[p.UserID] = struct{}{}
			authorIDs = append(authorIDs, p.UserID)
		}
		if p.RepostOfID != uuid.Nil {
			if original, err := s.repo.GetPostByID(ctx, p.RepostOfID); err == nil {
				if _, ok := seen[original.UserID]; !ok {
					seen[original.UserID] = struct{}{}
					authorIDs = append(authorIDs, original.UserID)
				}
			}
		}
		if p.ReplyToID != uuid.Nil {
			if parent, err := s.repo.GetPostByID(ctx, p.ReplyToID); err == nil {
				if _, ok := seen[parent.UserID]; !ok {
					seen[parent.UserID] = struct{}{}
					authorIDs = append(authorIDs, parent.UserID)
				}
			}
		}
	}

	authors, err := s.repo.GetAuthorsByIDs(ctx, authorIDs)
	if err != nil {
		authors = map[uuid.UUID]*AuthorInfo{}
	}

	items := make([]PostResponse, 0, len(posts))
	for _, p := range posts {
		items = append(items, *s.assemblePostResponse(ctx, p, currentUserID, authors, true))
	}

	result := &PostListResponse{
		Posts:   items,
		HasMore: hasMore,
	}

	if hasMore && len(posts) > 0 {
		result.NextCursor = posts[len(posts)-1].ID.String()
	}

	return result, nil
}

func (s *Service) validateMediaAssetIDs(ctx context.Context, userID uuid.UUID, idStrings []string) ([]uuid.UUID, error) {
	var mediaAssetIDs []uuid.UUID
	for _, idStr := range idStrings {
		id, err := uuid.Parse(idStr)
		if err != nil {
			return nil, errors.New("invalid_media_id", 400, fmt.Sprintf("invalid media asset id: %s", idStr))
		}
		mediaAssetIDs = append(mediaAssetIDs, id)
	}
	if len(mediaAssetIDs) > 4 {
		return nil, errors.New("too_many_media", 400, "a post can include up to 4 images")
	}
	if len(mediaAssetIDs) == 0 {
		return mediaAssetIDs, nil
	}

	count, err := s.repo.CountOwnedMediaAssets(ctx, userID, mediaAssetIDs)
	if err != nil {
		s.log.Error("failed to validate media assets", logger.Error(err))
		return nil, errors.ErrInternal
	}
	if count != len(mediaAssetIDs) {
		return nil, errors.New("invalid_media_id", 400, "one or more media assets are invalid")
	}
	return mediaAssetIDs, nil
}
