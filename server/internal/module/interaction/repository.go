package interaction

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/ent/notification"
	"social-server/internal/ent/postlike"
	"social-server/internal/ent/poststats"
)

// Repository handles database operations for interactions.
type Repository struct {
	client *ent.Client
}

// NewRepository creates a new interaction repository.
func NewRepository(client *ent.Client) *Repository {
	return &Repository{client: client}
}

// CreateLike creates a like record.
func (r *Repository) CreateLike(ctx context.Context, postID, userID uuid.UUID) (*ent.PostLike, error) {
	l, err := r.client.PostLike.Create().
		SetPostID(postID).
		SetUserID(userID).
		Save(ctx)
	if err != nil {
		if ent.IsConstraintError(err) {
			return nil, fmt.Errorf("already liked")
		}
		return nil, fmt.Errorf("create like: %w", err)
	}
	return l, nil
}

// DeleteLike removes a like record.
func (r *Repository) DeleteLike(ctx context.Context, postID, userID uuid.UUID) error {
	_, err := r.client.PostLike.Delete().
		Where(
			postlike.PostID(postID),
			postlike.UserID(userID),
		).
		Exec(ctx)
	if err != nil {
		return fmt.Errorf("delete like: %w", err)
	}
	return nil
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

// GetLikeCount returns the number of likes for a post.
func (r *Repository) GetLikeCount(ctx context.Context, postID uuid.UUID) (int, error) {
	count, err := r.client.PostLike.Query().
		Where(postlike.PostID(postID)).
		Count(ctx)
	if err != nil {
		return 0, fmt.Errorf("count likes: %w", err)
	}
	return count, nil
}

// IncrementLikeCount increments the like count in post stats.
func (r *Repository) IncrementLikeCount(ctx context.Context, postID uuid.UUID) error {
	stats, err := r.client.PostStats.Query().
		Where(poststats.PostID(postID)).
		Only(ctx)
	if err != nil {
		return fmt.Errorf("get stats: %w", err)
	}
	return r.client.PostStats.UpdateOne(stats).
		SetLikeCount(stats.LikeCount + 1).
		Exec(ctx)
}

// DecrementLikeCount decrements the like count in post stats.
func (r *Repository) DecrementLikeCount(ctx context.Context, postID uuid.UUID) error {
	stats, err := r.client.PostStats.Query().
		Where(poststats.PostID(postID)).
		Only(ctx)
	if err != nil {
		return fmt.Errorf("get stats: %w", err)
	}
	newCount := stats.LikeCount - 1
	if newCount < 0 {
		newCount = 0
	}
	return r.client.PostStats.UpdateOne(stats).
		SetLikeCount(newCount).
		Exec(ctx)
}

// GetPostOwner retrieves the owner of a post.
func (r *Repository) GetPostOwner(ctx context.Context, postID uuid.UUID) (uuid.UUID, error) {
	post, err := r.client.Post.Get(ctx, postID)
	if err != nil {
		return uuid.Nil, fmt.Errorf("get post: %w", err)
	}
	return post.UserID, nil
}

// CreateNotification creates a notification.
func (r *Repository) CreateNotification(ctx context.Context, userID, actorID uuid.UUID, notifType string, postID *uuid.UUID, content string) (*ent.Notification, error) {
	builder := r.client.Notification.Create().
		SetUserID(userID).
		SetType(notifType).
		SetContent(content)

	if actorID != uuid.Nil {
		builder = builder.SetActorID(actorID)
	}
	if postID != nil {
		builder = builder.SetPostID(*postID)
	}

	n, err := builder.Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create notification: %w", err)
	}
	return n, nil
}

// ListNotifications retrieves notifications for a user.
func (r *Repository) ListNotifications(ctx context.Context, userID uuid.UUID, cursor string, limit int) ([]*ent.Notification, error) {
	q := r.client.Notification.Query().
		Where(notification.UserID(userID)).
		Order(ent.Desc(notification.FieldCreatedAt))

	if cursor != "" {
		cursorID, err := uuid.Parse(cursor)
		if err == nil {
			n, err := r.client.Notification.Get(ctx, cursorID)
			if err == nil {
				q = q.Where(
					notification.Or(
						notification.CreatedAtLT(n.CreatedAt),
						notification.And(
							notification.CreatedAtEQ(n.CreatedAt),
							notification.IDLT(cursorID),
						),
					),
				)
			}
		}
	}

	notifications, err := q.Limit(limit + 1).All(ctx)
	if err != nil {
		return nil, fmt.Errorf("list notifications: %w", err)
	}
	return notifications, nil
}

// GetUnreadCount returns the number of unread notifications.
func (r *Repository) GetUnreadCount(ctx context.Context, userID uuid.UUID) (int, error) {
	count, err := r.client.Notification.Query().
		Where(
			notification.UserID(userID),
			notification.IsRead(false),
		).
		Count(ctx)
	if err != nil {
		return 0, fmt.Errorf("count unread: %w", err)
	}
	return count, nil
}

// MarkAsRead marks a notification as read.
func (r *Repository) MarkAsRead(ctx context.Context, notifID uuid.UUID) error {
	_, err := r.client.Notification.UpdateOneID(notifID).
		SetIsRead(true).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("mark as read: %w", err)
	}
	return nil
}

// MarkAllAsRead marks all notifications for a user as read.
func (r *Repository) MarkAllAsRead(ctx context.Context, userID uuid.UUID) error {
	_, err := r.client.Notification.Update().
		Where(
			notification.UserID(userID),
			notification.IsRead(false),
		).
		SetIsRead(true).
		Save(ctx)
	if err != nil {
		return fmt.Errorf("mark all as read: %w", err)
	}
	return nil
}

// CreateOutboxEvent creates an outbox event.
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
