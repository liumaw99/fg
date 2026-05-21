package interaction

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

// Service handles interaction business logic.
type Service struct {
	repo *Repository
	log  *logger.Logger
}

// NewService creates a new interaction service.
func NewService(repo *Repository, log *logger.Logger) *Service {
	return &Service{repo: repo, log: log}
}

// Like adds a like to a post.
func (s *Service) Like(ctx context.Context, userID uuid.UUID, req LikeRequest) error {
	postID, err := uuid.Parse(req.PostID)
	if err != nil {
		return errors.New("invalid_post_id", 400, "invalid post id")
	}

	// Check if already liked
	isLiked, err := s.repo.IsLiked(ctx, postID, userID)
	if err != nil {
		s.log.Error("failed to check like status", logger.Error(err))
		return errors.ErrInternal
	}
	if isLiked {
		return errors.New("already_liked", 409, "already liked this post")
	}

	// Get post owner for notification
	postOwner, err := s.repo.GetPostOwner(ctx, postID)
	if err != nil {
		return errors.ErrNotFound
	}

	// Create like and increment count in transaction
	tx, err := s.repo.client.Tx(ctx)
	if err != nil {
		s.log.Error("failed to start transaction", logger.Error(err))
		return errors.ErrInternal
	}

	repo := NewRepository(tx.Client())

	_, err = repo.CreateLike(ctx, postID, userID)
	if err != nil {
		_ = tx.Rollback()
		if isAlreadyLiked(err) {
			return errors.New("already_liked", 409, "already liked this post")
		}
		s.log.Error("failed to create like", logger.Error(err))
		return errors.ErrInternal
	}

	if err := repo.IncrementLikeCount(ctx, postID); err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to increment like count", logger.Error(err))
		return errors.ErrInternal
	}

	// Create notification for post owner (if not self-like)
	if postOwner != userID {
		_, err = repo.CreateNotification(ctx, postOwner, userID, "like", &postID,
			fmt.Sprintf("liked your post"))
		if err != nil {
			s.log.Error("failed to create notification", logger.Error(err))
		}
	}

	// Create outbox event
	err = repo.CreateOutboxEvent(ctx, "interaction.events.v1", postID.String(), map[string]any{
		"event_type": "PostLiked",
		"post_id":    postID.String(),
		"user_id":    userID.String(),
		"created_at": time.Now().UTC(),
	})
	if err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to create outbox event", logger.Error(err))
		return errors.ErrInternal
	}

	if err := tx.Commit(); err != nil {
		s.log.Error("failed to commit transaction", logger.Error(err))
		return errors.ErrInternal
	}

	s.log.Info("post liked",
		logger.String("post_id", postID.String()),
		logger.String("user_id", userID.String()),
	)

	return nil
}

// Unlike removes a like from a post.
func (s *Service) Unlike(ctx context.Context, userID uuid.UUID, req UnlikeRequest) error {
	postID, err := uuid.Parse(req.PostID)
	if err != nil {
		return errors.New("invalid_post_id", 400, "invalid post id")
	}

	tx, err := s.repo.client.Tx(ctx)
	if err != nil {
		s.log.Error("failed to start transaction", logger.Error(err))
		return errors.ErrInternal
	}

	repo := NewRepository(tx.Client())

	if err := repo.DeleteLike(ctx, postID, userID); err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to delete like", logger.Error(err))
		return errors.ErrInternal
	}

	if err := repo.DecrementLikeCount(ctx, postID); err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to decrement like count", logger.Error(err))
		return errors.ErrInternal
	}

	if err := tx.Commit(); err != nil {
		s.log.Error("failed to commit transaction", logger.Error(err))
		return errors.ErrInternal
	}

	s.log.Info("post unliked",
		logger.String("post_id", postID.String()),
		logger.String("user_id", userID.String()),
	)

	return nil
}

// GetLikeStatus returns whether the current user liked a post and the total count.
func (s *Service) GetLikeStatus(ctx context.Context, userID, postID uuid.UUID) (*LikeStatusResponse, error) {
	isLiked, err := s.repo.IsLiked(ctx, postID, userID)
	if err != nil {
		s.log.Error("failed to check like status", logger.Error(err))
		return nil, errors.ErrInternal
	}

	count, err := s.repo.GetLikeCount(ctx, postID)
	if err != nil {
		s.log.Error("failed to get like count", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return &LikeStatusResponse{IsLiked: isLiked, Count: count}, nil
}

// Reply creates a reply to a post.
func (s *Service) Reply(ctx context.Context, userID uuid.UUID, req ReplyRequest) error {
	// Replies are just posts with reply_to_id set
	// This is handled by the post module
	return errors.New("not_implemented", 501, "reply via post creation")
}

// ListNotifications returns notifications for the current user.
func (s *Service) ListNotifications(ctx context.Context, userID uuid.UUID, params pagination.Params) (*NotificationListResponse, error) {
	params.ValidateAndNormalize(50)

	notifications, err := s.repo.ListNotifications(ctx, userID, params.Cursor, params.Limit)
	if err != nil {
		s.log.Error("failed to list notifications", logger.Error(err))
		return nil, errors.ErrInternal
	}

	unreadCount, err := s.repo.GetUnreadCount(ctx, userID)
	if err != nil {
		s.log.Error("failed to get unread count", logger.Error(err))
		unreadCount = 0
	}

	hasMore := len(notifications) > params.Limit
	if hasMore {
		notifications = notifications[:params.Limit]
	}

	var items []NotificationResponse
	for _, n := range notifications {
		resp := NotificationResponse{
			ID:        n.ID.String(),
			UserID:    n.UserID.String(),
			Type:      n.Type,
			Content:   n.Content,
			IsRead:    n.IsRead,
			CreatedAt: n.CreatedAt,
		}
		if n.ActorID != uuid.Nil {
			resp.ActorID = n.ActorID.String()
		}
		if n.PostID != uuid.Nil {
			resp.PostID = n.PostID.String()
		}
		items = append(items, resp)
	}

	result := &NotificationListResponse{
		Notifications: items,
		UnreadCount:   unreadCount,
		HasMore:       hasMore,
	}

	if hasMore && len(notifications) > 0 {
		result.NextCursor = notifications[len(notifications)-1].ID.String()
	}

	return result, nil
}

// MarkNotificationAsRead marks a notification as read.
func (s *Service) MarkNotificationAsRead(ctx context.Context, userID, notifID uuid.UUID) error {
	// Verify the notification belongs to the user
	n, err := s.repo.client.Notification.Get(ctx, notifID)
	if err != nil {
		if ent.IsNotFound(err) {
			return errors.ErrNotFound
		}
		return errors.ErrInternal
	}

	if n.UserID != userID {
		return errors.New("forbidden", 403, "notification does not belong to user")
	}

	if err := s.repo.MarkAsRead(ctx, notifID); err != nil {
		s.log.Error("failed to mark as read", logger.Error(err))
		return errors.ErrInternal
	}

	return nil
}

// MarkAllNotificationsAsRead marks all notifications as read.
func (s *Service) MarkAllNotificationsAsRead(ctx context.Context, userID uuid.UUID) error {
	if err := s.repo.MarkAllAsRead(ctx, userID); err != nil {
		s.log.Error("failed to mark all as read", logger.Error(err))
		return errors.ErrInternal
	}
	return nil
}

func isAlreadyLiked(err error) bool {
	if err == nil {
		return false
	}
	return err.Error() == "already liked"
}
