package user

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/ent/user"
	"social-server/internal/ent/userprofile"
	"social-server/internal/ent/userstats"
)

// Repository handles database operations for users.
type Repository struct {
	client *ent.Client
}

// NewRepository creates a new user repository.
func NewRepository(client *ent.Client) *Repository {
	return &Repository{client: client}
}

// GetUser retrieves a user by ID.
func (r *Repository) GetUser(ctx context.Context, id uuid.UUID) (*ent.User, error) {
	u, err := r.client.User.Get(ctx, id)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("get user: %w", err)
	}
	return u, nil
}

// GetProfile retrieves a user's profile.
func (r *Repository) GetProfile(ctx context.Context, userID uuid.UUID) (*ent.UserProfile, error) {
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

// GetStats retrieves a user's stats.
func (r *Repository) GetStats(ctx context.Context, userID uuid.UUID) (*ent.UserStats, error) {
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

// UpdateProfile updates a user's profile.
func (r *Repository) UpdateProfile(ctx context.Context, userID uuid.UUID, displayName, bio, location, website string) (*ent.UserProfile, error) {
	p, err := r.client.UserProfile.Query().
		Where(userprofile.UserID(userID)).
		Only(ctx)
	if err != nil {
		return nil, fmt.Errorf("profile not found: %w", err)
	}

	updater := r.client.UserProfile.UpdateOneID(p.ID)
	if displayName != "" {
		updater = updater.SetDisplayName(displayName)
	}
	if bio != "" {
		updater = updater.SetBio(bio)
	}
	if location != "" {
		updater = updater.SetLocation(location)
	}
	if website != "" {
		updater = updater.SetWebsite(website)
	}

	result, err := updater.Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("update profile: %w", err)
	}
	return result, nil
}

// GetUserByUsername retrieves a user by username.
func (r *Repository) GetUserByUsername(ctx context.Context, username string) (*ent.User, error) {
	u, err := r.client.User.Query().
		Where(user.Username(username)).
		Only(ctx)
	if err != nil {
		if ent.IsNotFound(err) {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("get user by username: %w", err)
	}
	return u, nil
}
