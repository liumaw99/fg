package social

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/ent/follow"
	"social-server/internal/ent/userprofile"
	"social-server/internal/ent/userstats"
)

// Repository handles database operations for social.
type Repository struct {
	client *ent.Client
}

// NewRepository creates a new social repository.
func NewRepository(client *ent.Client) *Repository {
	return &Repository{client: client}
}

// CreateFollow creates a follow relationship.
func (r *Repository) CreateFollow(ctx context.Context, followerID, followingID uuid.UUID) (*ent.Follow, error) {
	f, err := r.client.Follow.Create().
		SetFollowerID(followerID).
		SetFollowingID(followingID).
		Save(ctx)
	if err != nil {
		if ent.IsConstraintError(err) {
			return nil, fmt.Errorf("already following")
		}
		return nil, fmt.Errorf("create follow: %w", err)
	}
	return f, nil
}

// DeleteFollow removes a follow relationship.
func (r *Repository) DeleteFollow(ctx context.Context, followerID, followingID uuid.UUID) error {
	_, err := r.client.Follow.Delete().
		Where(
			follow.FollowerID(followerID),
			follow.FollowingID(followingID),
		).
		Exec(ctx)
	if err != nil {
		return fmt.Errorf("delete follow: %w", err)
	}
	return nil
}

// IsFollowing checks if followerID is following followingID.
func (r *Repository) IsFollowing(ctx context.Context, followerID, followingID uuid.UUID) (bool, error) {
	exists, err := r.client.Follow.Query().
		Where(
			follow.FollowerID(followerID),
			follow.FollowingID(followingID),
		).
		Exist(ctx)
	if err != nil {
		return false, fmt.Errorf("check follow: %w", err)
	}
	return exists, nil
}

// ListFollowers retrieves followers of a user.
func (r *Repository) ListFollowers(ctx context.Context, userID uuid.UUID, cursor string, limit int) ([]*ent.Follow, error) {
	q := r.client.Follow.Query().
		Where(follow.FollowingID(userID)).
		Order(ent.Desc(follow.FieldCreatedAt))

	if cursor != "" {
		cursorID, err := uuid.Parse(cursor)
		if err == nil {
			f, err := r.client.Follow.Get(ctx, cursorID)
			if err == nil {
				q = q.Where(
					follow.Or(
						follow.CreatedAtLT(f.CreatedAt),
						follow.And(
							follow.CreatedAtEQ(f.CreatedAt),
							follow.IDLT(cursorID),
						),
					),
				)
			}
		}
	}

	followers, err := q.Limit(limit + 1).All(ctx)
	if err != nil {
		return nil, fmt.Errorf("list followers: %w", err)
	}
	return followers, nil
}

// ListFollowing retrieves users that a user follows.
func (r *Repository) ListFollowing(ctx context.Context, userID uuid.UUID, cursor string, limit int) ([]*ent.Follow, error) {
	q := r.client.Follow.Query().
		Where(follow.FollowerID(userID)).
		Order(ent.Desc(follow.FieldCreatedAt))

	if cursor != "" {
		cursorID, err := uuid.Parse(cursor)
		if err == nil {
			f, err := r.client.Follow.Get(ctx, cursorID)
			if err == nil {
				q = q.Where(
					follow.Or(
						follow.CreatedAtLT(f.CreatedAt),
						follow.And(
							follow.CreatedAtEQ(f.CreatedAt),
							follow.IDLT(cursorID),
						),
					),
				)
			}
		}
	}

	following, err := q.Limit(limit + 1).All(ctx)
	if err != nil {
		return nil, fmt.Errorf("list following: %w", err)
	}
	return following, nil
}

// GetUserByID retrieves a user by ID.
func (r *Repository) GetUserByID(ctx context.Context, id uuid.UUID) (*ent.User, error) {
	u, err := r.client.User.Get(ctx, id)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("get user: %w", err)
	}
	return u, nil
}

// GetUserProfile retrieves a user profile.
func (r *Repository) GetUserProfile(ctx context.Context, userID uuid.UUID) (*ent.UserProfile, error) {
	p, err := r.client.UserProfile.Query().
		Where(userprofile.UserID(userID)).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("profile not found")
		}
		return nil, fmt.Errorf("get profile: %w", err)
	}
	return p, nil
}

// GetUserStats retrieves user stats.
func (r *Repository) GetUserStats(ctx context.Context, userID uuid.UUID) (*ent.UserStats, error) {
	s, err := r.client.UserStats.Query().
		Where(userstats.UserID(userID)).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("stats not found")
		}
		return nil, fmt.Errorf("get stats: %w", err)
	}
	return s, nil
}

// IncrementFollowerCount increments a user's follower count.
func (r *Repository) IncrementFollowerCount(ctx context.Context, userID uuid.UUID) error {
	stats, err := r.client.UserStats.Query().
		Where(userstats.UserID(userID)).
		Only(ctx)
	if err != nil {
		return fmt.Errorf("get stats: %w", err)
	}
	return r.client.UserStats.UpdateOne(stats).
		SetFollowerCount(stats.FollowerCount + 1).
		Exec(ctx)
}

// DecrementFollowerCount decrements a user's follower count.
func (r *Repository) DecrementFollowerCount(ctx context.Context, userID uuid.UUID) error {
	stats, err := r.client.UserStats.Query().
		Where(userstats.UserID(userID)).
		Only(ctx)
	if err != nil {
		return fmt.Errorf("get stats: %w", err)
	}
	newCount := stats.FollowerCount - 1
	if newCount < 0 {
		newCount = 0
	}
	return r.client.UserStats.UpdateOne(stats).
		SetFollowerCount(newCount).
		Exec(ctx)
}

// IncrementFollowingCount increments a user's following count.
func (r *Repository) IncrementFollowingCount(ctx context.Context, userID uuid.UUID) error {
	stats, err := r.client.UserStats.Query().
		Where(userstats.UserID(userID)).
		Only(ctx)
	if err != nil {
		return fmt.Errorf("get stats: %w", err)
	}
	return r.client.UserStats.UpdateOne(stats).
		SetFollowingCount(stats.FollowingCount + 1).
		Exec(ctx)
}

// DecrementFollowingCount decrements a user's following count.
func (r *Repository) DecrementFollowingCount(ctx context.Context, userID uuid.UUID) error {
	stats, err := r.client.UserStats.Query().
		Where(userstats.UserID(userID)).
		Only(ctx)
	if err != nil {
		return fmt.Errorf("get stats: %w", err)
	}
	newCount := stats.FollowingCount - 1
	if newCount < 0 {
		newCount = 0
	}
	return r.client.UserStats.UpdateOne(stats).
		SetFollowingCount(newCount).
		Exec(ctx)
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
