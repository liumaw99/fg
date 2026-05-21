package auth

import "time"

// RegisterRequest represents a user registration request.
type RegisterRequest struct {
	Username string `json:"username" binding:"required,min=3,max=30"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=8"`
}

// LoginRequest represents a user login request.
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// RefreshRequest represents a token refresh request.
type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// TokenResponse represents the authentication token response.
type TokenResponse struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
	ExpiresAt    time.Time `json:"expires_at"`
}

// LogoutRequest represents a logout request.
type LogoutRequest struct {
	RefreshToken string `json:"refresh_token"`
}

// SessionResponse represents a user session.
type SessionResponse struct {
	ID        string `json:"id"`
	DeviceInfo string `json:"device_info"`
	CreatedAt string `json:"created_at"`
}
