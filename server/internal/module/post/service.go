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

	return s.buildPostResponse(ctx, post)
}

// GetPost retrieves a post by ID.
func (s *Service) GetPost(ctx context.Context, postID uuid.UUID) (*PostResponse, error) {
	post, err := s.repo.GetPostByID(ctx, postID)
	if err != nil {
		return nil, errors.ErrNotFound
	}

	if post.Status != "active" {
		return nil, errors.New("post_deleted", 404, "post not found")
	}

	return s.buildPostResponse(ctx, post)
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
func (s *Service) ListUserPosts(ctx context.Context, userID uuid.UUID, params pagination.Params) (*PostListResponse, error) {
	params.ValidateAndNormalize(50)

	posts, err := s.repo.ListUserPosts(ctx, userID, params.Cursor, params.Limit)
	if err != nil {
		s.log.Error("failed to list user posts", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return s.buildPostListResponse(ctx, posts, params.Limit)
}

// ListPosts retrieves all active posts.
func (s *Service) ListPosts(ctx context.Context, params pagination.Params) (*PostListResponse, error) {
	params.ValidateAndNormalize(50)

	posts, err := s.repo.ListPosts(ctx, params.Cursor, params.Limit)
	if err != nil {
		s.log.Error("failed to list posts", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return s.buildPostListResponse(ctx, posts, params.Limit)
}

// buildPostResponse builds a PostResponse from an ent.Post.
func (s *Service) buildPostResponse(ctx context.Context, post *ent.Post) (*PostResponse, error) {
	stats, err := s.repo.GetPostStats(ctx, post.ID)
	if err != nil {
		stats = &ent.PostStats{}
	}

	// Get media
	postMedia, err := s.repo.GetPostMediaAssets(ctx, post.ID)
	if err != nil {
		postMedia = []*ent.PostMedia{}
	}

	var mediaURLs []MediaItem
	if len(postMedia) > 0 {
		var mediaAssetIDs []uuid.UUID
		for _, pm := range postMedia {
			mediaAssetIDs = append(mediaAssetIDs, pm.MediaAssetID)
		}

		assets, err := s.repo.GetMediaAssets(ctx, mediaAssetIDs)
		if err == nil {
			assetMap := make(map[uuid.UUID]*ent.MediaAsset)
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

	if post.ReplyToID != uuid.Nil {
		resp.ReplyToID = post.ReplyToID.String()
	}
	if post.RepostOfID != uuid.Nil {
		resp.RepostOfID = post.RepostOfID.String()
	}

	return resp, nil
}

// buildPostListResponse builds a paginated list response.
func (s *Service) buildPostListResponse(ctx context.Context, posts []*ent.Post, limit int) (*PostListResponse, error) {
	hasMore := len(posts) > limit
	if hasMore {
		posts = posts[:limit]
	}

	var items []PostResponse
	for _, p := range posts {
		resp, err := s.buildPostResponse(ctx, p)
		if err != nil {
			continue
		}
		items = append(items, *resp)
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
