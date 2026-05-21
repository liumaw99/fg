package auth

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/ent/user"
	"social-server/internal/ent/usersession"
)

// Repository handles database operations for auth.
type Repository struct {
	client *ent.Client
}

// NewRepository creates a new auth repository.
func NewRepository(client *ent.Client) *Repository {
	return &Repository{client: client}
}

// CreateUser creates a new user.
func (r *Repository) CreateUser(ctx context.Context, username, email, passwordHash string) (*ent.User, error) {
	u, err := r.client.User.Create().
		SetUsername(username).
		SetEmail(email).
		SetPasswordHash(passwordHash).
		Save(ctx)
	if err != nil {
		if ent.IsConstraintError(err) {
			return nil, fmt.Errorf("user already exists: %w", err)
		}
		return nil, fmt.Errorf("create user: %w", err)
	}
	return u, nil
}

// GetUserByEmail retrieves a user by email.
func (r *Repository) GetUserByEmail(ctx context.Context, email string) (*ent.User, error) {
	u, err := r.client.User.Query().
		Where(user.Email(email)).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("get user by email: %w", err)
	}
	return u, nil
}

// GetUserByID retrieves a user by ID.
func (r *Repository) GetUserByID(ctx context.Context, id uuid.UUID) (*ent.User, error) {
	u, err := r.client.User.Get(ctx, id)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("get user by id: %w", err)
	}
	return u, nil
}

// CreateUserProfile creates a user profile.
func (r *Repository) CreateUserProfile(ctx context.Context, userID uuid.UUID, displayName string) (*ent.UserProfile, error) {
	p, err := r.client.UserProfile.Create().
		SetUserID(userID).
		SetDisplayName(displayName).
		Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create user profile: %w", err)
	}
	return p, nil
}

// CreateUserStats creates user stats.
func (r *Repository) CreateUserStats(ctx context.Context, userID uuid.UUID) (*ent.UserStats, error) {
	s, err := r.client.UserStats.Create().
		SetUserID(userID).
		Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create user stats: %w", err)
	}
	return s, nil
}

// CreateSession creates a new user session.
func (r *Repository) CreateSession(ctx context.Context, userID uuid.UUID, tokenID, deviceInfo, ipAddress string) (*ent.UserSession, error) {
	s, err := r.client.UserSession.Create().
		SetUserID(userID).
		SetTokenID(tokenID).
		SetDeviceInfo(deviceInfo).
		SetIPAddress(ipAddress).
		Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create session: %w", err)
	}
	return s, nil
}

// GetSessionByTokenID retrieves a session by token ID.
func (r *Repository) GetSessionByTokenID(ctx context.Context, tokenID string) (*ent.UserSession, error) {
	s, err := r.client.UserSession.Query().
		Where(usersession.TokenID(tokenID)).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("session not found")
		}
		return nil, fmt.Errorf("get session: %w", err)
	}
	return s, nil
}

// DeleteSession removes a session.
func (r *Repository) DeleteSession(ctx context.Context, id uuid.UUID) error {
	return r.client.UserSession.DeleteOneID(id).Exec(ctx)
}

// DeleteSessionsByUser removes all sessions for a user.
func (r *Repository) DeleteSessionsByUser(ctx context.Context, userID uuid.UUID) error {
	_, err := r.client.UserSession.Delete().
		Where(usersession.UserID(userID)).
		Exec(ctx)
	return err
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
