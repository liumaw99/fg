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

	// Parse media asset IDs
	var mediaAssetIDs []uuid.UUID
	for _, idStr := range req.MediaAssetIDs {
		id, err := uuid.Parse(idStr)
		if err != nil {
			return nil, errors.New("invalid_media_id", 400, fmt.Sprintf("invalid media asset id: %s", idStr))
		}
		mediaAssetIDs = append(mediaAssetIDs, id)
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
	return s.assemblePostResponse(ctx, post, currentUserID, authors), nil
}

// assemblePostResponse turns a Post + prefetched authors map into a PostResponse.
func (s *Service) assemblePostResponse(ctx context.Context, post *ent.Post, currentUserID uuid.UUID, authors map[uuid.UUID]*AuthorInfo) *PostResponse {
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

	resp := &PostResponse{
		ID:            post.ID.String(),
		UserID:        post.UserID.String(),
		Content:       post.Content,
		Status:        post.Status,
		Visibility:    post.Visibility,
		LikeCount:     stats.LikeCount,
		ReplyCount:    stats.ReplyCount,
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
	}
	if post.RepostOfID != uuid.Nil {
		resp.RepostOfID = post.RepostOfID.String()
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
		if _, ok := seen[p.UserID]; ok {
			continue
		}
		seen[p.UserID] = struct{}{}
		authorIDs = append(authorIDs, p.UserID)
	}

	authors, err := s.repo.GetAuthorsByIDs(ctx, authorIDs)
	if err != nil {
		authors = map[uuid.UUID]*AuthorInfo{}
	}

	items := make([]PostResponse, 0, len(posts))
	for _, p := range posts {
		items = append(items, *s.assemblePostResponse(ctx, p, currentUserID, authors))
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
