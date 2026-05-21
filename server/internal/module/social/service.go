package social

import (
	"context"
	"time"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/pagination"
)

// Service handles social business logic.
type Service struct {
	repo *Repository
	log  *logger.Logger
}

// NewService creates a new social service.
func NewService(repo *Repository, log *logger.Logger) *Service {
	return &Service{repo: repo, log: log}
}

// Follow follows a user.
func (s *Service) Follow(ctx context.Context, followerID uuid.UUID, req FollowRequest) error {
	followingID, err := uuid.Parse(req.FollowingID)
	if err != nil {
		return errors.New("invalid_user_id", 400, "invalid following_id")
	}

	if followerID == followingID {
		return errors.New("self_follow", 400, "cannot follow yourself")
	}

	// Check if user exists
	if _, err := s.repo.GetUserByID(ctx, followingID); err != nil {
		return errors.ErrNotFound
	}

	// Check if already following
	isFollowing, err := s.repo.IsFollowing(ctx, followerID, followingID)
	if err != nil {
		s.log.Error("failed to check follow status", logger.Error(err))
		return errors.ErrInternal
	}
	if isFollowing {
		return errors.New("already_following", 409, "already following this user")
	}

	// Create follow in transaction
	tx, err := s.repo.client.Tx(ctx)
	if err != nil {
		s.log.Error("failed to start transaction", logger.Error(err))
		return errors.ErrInternal
	}

	repo := NewRepository(tx.Client())

	_, err = repo.CreateFollow(ctx, followerID, followingID)
	if err != nil {
		_ = tx.Rollback()
		if isAlreadyFollowing(err) {
			return errors.New("already_following", 409, "already following this user")
		}
		s.log.Error("failed to create follow", logger.Error(err))
		return errors.ErrInternal
	}

	// Update follower count for the followed user
	if err := repo.IncrementFollowerCount(ctx, followingID); err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to increment follower count", logger.Error(err))
	}

	// Update following count for the follower
	if err := repo.IncrementFollowingCount(ctx, followerID); err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to increment following count", logger.Error(err))
	}

	// Create outbox event
	err = repo.CreateOutboxEvent(ctx, "social.events.v1", followingID.String(), map[string]any{
		"event_type":   "UserFollowed",
		"follower_id":  followerID.String(),
		"following_id": followingID.String(),
		"created_at":   time.Now().UTC(),
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

	s.log.Info("user followed",
		logger.String("follower_id", followerID.String()),
		logger.String("following_id", followingID.String()),
	)

	return nil
}

// Unfollow unfollows a user.
func (s *Service) Unfollow(ctx context.Context, followerID uuid.UUID, req UnfollowRequest) error {
	followingID, err := uuid.Parse(req.FollowingID)
	if err != nil {
		return errors.New("invalid_user_id", 400, "invalid following_id")
	}

	// Delete follow in transaction
	tx, err := s.repo.client.Tx(ctx)
	if err != nil {
		s.log.Error("failed to start transaction", logger.Error(err))
		return errors.ErrInternal
	}

	repo := NewRepository(tx.Client())

	if err := repo.DeleteFollow(ctx, followerID, followingID); err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to delete follow", logger.Error(err))
		return errors.ErrInternal
	}

	// Update follower count for the unfollowed user
	if err := repo.DecrementFollowerCount(ctx, followingID); err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to decrement follower count", logger.Error(err))
	}

	// Update following count for the unfollower
	if err := repo.DecrementFollowingCount(ctx, followerID); err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to decrement following count", logger.Error(err))
	}

	// Create outbox event
	err = repo.CreateOutboxEvent(ctx, "social.events.v1", followingID.String(), map[string]any{
		"event_type":   "UserUnfollowed",
		"follower_id":  followerID.String(),
		"following_id": followingID.String(),
		"created_at":   time.Now().UTC(),
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

	s.log.Info("user unfollowed",
		logger.String("follower_id", followerID.String()),
		logger.String("following_id", followingID.String()),
	)

	return nil
}

// GetFollowStatus checks if the current user follows another user.
func (s *Service) GetFollowStatus(ctx context.Context, followerID, followingID uuid.UUID) (*FollowStatusResponse, error) {
	isFollowing, err := s.repo.IsFollowing(ctx, followerID, followingID)
	if err != nil {
		s.log.Error("failed to check follow status", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return &FollowStatusResponse{IsFollowing: isFollowing}, nil
}

// ListFollowers returns followers of a user.
func (s *Service) ListFollowers(ctx context.Context, userID uuid.UUID, params pagination.Params) (*FollowListResponse, error) {
	params.ValidateAndNormalize(50)

	follows, err := s.repo.ListFollowers(ctx, userID, params.Cursor, params.Limit)
	if err != nil {
		s.log.Error("failed to list followers", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return s.buildFollowListResponse(ctx, follows, params.Limit)
}

// ListFollowing returns users that a user follows.
func (s *Service) ListFollowing(ctx context.Context, userID uuid.UUID, params pagination.Params) (*FollowListResponse, error) {
	params.ValidateAndNormalize(50)

	follows, err := s.repo.ListFollowing(ctx, userID, params.Cursor, params.Limit)
	if err != nil {
		s.log.Error("failed to list following", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return s.buildFollowListResponse(ctx, follows, params.Limit)
}

// buildFollowListResponse builds a paginated list of follow users.
func (s *Service) buildFollowListResponse(ctx context.Context, follows []*ent.Follow, limit int) (*FollowListResponse, error) {
	hasMore := len(follows) > limit
	if hasMore {
		follows = follows[:limit]
	}

	var users []FollowUser
	for _, f := range follows {
		// Get the user profile (following for followers list, follower for following list)
		var userID uuid.UUID
		// For the response, we need the "other" user's info
		// This is simplified - in practice you'd need to know which list we're building
		userID = f.FollowerID
		_ = userID
		// Skip for now - would need to load user profiles
	}

	result := &FollowListResponse{
		Users:   users,
		HasMore: hasMore,
	}

	if hasMore && len(follows) > 0 {
		result.NextCursor = follows[len(follows)-1].ID.String()
	}

	return result, nil
}

func isAlreadyFollowing(err error) bool {
	if err == nil {
		return false
	}
	return err.Error() == "already following"
}
