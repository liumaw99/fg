package auth

import "time"

// UserRegisteredEvent is emitted when a new user registers.
type UserRegisteredEvent struct {
	UserID    string    `json:"user_id"`
	Username  string    `json:"username"`
	Email     string    `json:"email"`
	CreatedAt time.Time `json:"created_at"`
}

// UserProfileUpdatedEvent is emitted when a user profile is updated.
type UserProfileUpdatedEvent struct {
	UserID      string    `json:"user_id"`
	DisplayName string    `json:"display_name"`
	Bio         string    `json:"bio"`
	AvatarURL   string    `json:"avatar_url"`
	UpdatedAt   time.Time `json:"updated_at"`
}
