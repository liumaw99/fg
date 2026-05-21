package post

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/ent/mediaasset"
	"social-server/internal/ent/post"
	"social-server/internal/ent/postlike"
	"social-server/internal/ent/postmedia"
	"social-server/internal/ent/poststats"
)

// Repository handles database operations for posts.
type Repository struct {
	client *ent.Client
}

// NewRepository creates a new post repository.
func NewRepository(client *ent.Client) *Repository {
	return &Repository{client: client}
}

// CreatePost creates a new post.
func (r *Repository) CreatePost(ctx context.Context, userID uuid.UUID, content string, mediaAssetIDs []uuid.UUID) (*ent.Post, error) {
	builder := r.client.Post.Create().
		SetUserID(userID).
		SetContent(content)

	p, err := builder.Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create post: %w", err)
	}

	// Create post media links
	for i, mediaID := range mediaAssetIDs {
		err = r.client.PostMedia.Create().
			SetPostID(p.ID).
			SetMediaAssetID(mediaID).
			SetSortOrder(i).
			Exec(ctx)
		if err != nil {
			return nil, fmt.Errorf("create post media: %w", err)
		}
	}

	// Create stats
	_, err = r.client.PostStats.Create().
		SetPostID(p.ID).
		Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create post stats: %w", err)
	}

	return p, nil
}

// GetPostByID retrieves a post by ID.
func (r *Repository) GetPostByID(ctx context.Context, id uuid.UUID) (*ent.Post, error) {
	p, err := r.client.Post.Get(ctx, id)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("post not found")
		}
		return nil, fmt.Errorf("get post: %w", err)
	}
	return p, nil
}

// GetPostWithMedia retrieves a post with its media.
func (r *Repository) GetPostWithMedia(ctx context.Context, id uuid.UUID) (*ent.Post, []*ent.PostMedia, error) {
	p, err := r.GetPostByID(ctx, id)
	if err != nil {
		return nil, nil, err
	}

	media, err := r.client.PostMedia.Query().
		Where(postmedia.PostID(id)).
		Order(ent.Asc(postmedia.FieldSortOrder)).
		All(ctx)
	if err != nil {
		return nil, nil, fmt.Errorf("get post media: %w", err)
	}

	return p, media, nil
}

// GetPostStats retrieves stats for a post.
func (r *Repository) GetPostStats(ctx context.Context, postID uuid.UUID) (*ent.PostStats, error) {
	s, err := r.client.PostStats.Query().
		Where(poststats.PostID(postID)).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("post stats not found")
		}
		return nil, fmt.Errorf("get post stats: %w", err)
	}
	return s, nil
}

// DeletePost soft-deletes a post.
func (r *Repository) DeletePost(ctx context.Context, id uuid.UUID) error {
	_, err := r.client.Post.UpdateOneID(id).
		SetStatus("deleted").
		Save(ctx)
	if err != nil {
		return fmt.Errorf("delete post: %w", err)
	}
	return nil
}

// ListUserPosts retrieves posts by a user with cursor pagination.
func (r *Repository) ListUserPosts(ctx context.Context, userID uuid.UUID, cursor string, limit int) ([]*ent.Post, error) {
	q := r.client.Post.Query().
		Where(
			post.UserID(userID),
			post.Status("active"),
		).
		Order(ent.Desc(post.FieldCreatedAt))

	if cursor != "" {
		cursorID, err := uuid.Parse(cursor)
		if err == nil {
			p, err := r.client.Post.Get(ctx, cursorID)
			if err == nil {
				q = q.Where(
					post.Or(
						post.CreatedAtLT(p.CreatedAt),
						post.And(
							post.CreatedAtEQ(p.CreatedAt),
							post.IDLT(cursorID),
						),
					),
				)
			}
		}
	}

	posts, err := q.Limit(limit + 1).All(ctx)
	if err != nil {
		return nil, fmt.Errorf("list user posts: %w", err)
	}
	return posts, nil
}

// ListPosts retrieves all active posts with cursor pagination.
func (r *Repository) ListPosts(ctx context.Context, cursor string, limit int) ([]*ent.Post, error) {
	q := r.client.Post.Query().
		Where(post.Status("active")).
		Order(ent.Desc(post.FieldCreatedAt))

	if cursor != "" {
		cursorID, err := uuid.Parse(cursor)
		if err == nil {
			p, err := r.client.Post.Get(ctx, cursorID)
			if err == nil {
				q = q.Where(
					post.Or(
						post.CreatedAtLT(p.CreatedAt),
						post.And(
							post.CreatedAtEQ(p.CreatedAt),
							post.IDLT(cursorID),
						),
					),
				)
			}
		}
	}

	posts, err := q.Limit(limit + 1).All(ctx)
	if err != nil {
		return nil, fmt.Errorf("list posts: %w", err)
	}
	return posts, nil
}

// GetMediaAssets retrieves media assets by IDs.
func (r *Repository) GetMediaAssets(ctx context.Context, ids []uuid.UUID) ([]*ent.MediaAsset, error) {
	assets, err := r.client.MediaAsset.Query().
		Where(mediaasset.IDIn(ids...)).
		All(ctx)
	if err != nil {
		return nil, fmt.Errorf("get media assets: %w", err)
	}
	return assets, nil
}

// GetPostMediaAssets retrieves media assets for a post.
func (r *Repository) GetPostMediaAssets(ctx context.Context, postID uuid.UUID) ([]*ent.PostMedia, error) {
	media, err := r.client.PostMedia.Query().
		Where(postmedia.PostID(postID)).
		Order(ent.Asc(postmedia.FieldSortOrder)).
		All(ctx)
	if err != nil {
		return nil, fmt.Errorf("get post media: %w", err)
	}
	return media, nil
}

// IsLiked checks if a user liked a post.
func (r *Repository) IsLiked(ctx context.Context, postID, userID uuid.UUID) (bool, error) {
	exists, err := r.client.PostLike.Query().
		Where(
			postlike.PostID(postID),
			postlike.UserID(userID),
		).
		Exist(ctx)
	if err != nil {
		return false, fmt.Errorf("check like: %w", err)
	}
	return exists, nil
}

// CreateOutboxEvent creates an outbox event within the same transaction.
func (r *Repository) CreateOutboxEvent(ctx context.Context, topic, key string, payload map[string]any) error {
	err := r.client.OutboxEvent.Create().
		SetTopic(topic).
		SetKey(key).
		SetPayload(payload).
		SetStatus("pending").
		Exec(ctx)
	if err != nil {
		return fmt.Errorf("create outbox event: %w", err)
	}
	return nil
}
