package auth

import (
	"context"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/security"
)

// Service handles authentication business logic.
type Service struct {
	repo *Repository
	jwt  *security.JWTManager
	log  *logger.Logger
}

// NewService creates a new auth service.
func NewService(repo *Repository, jwt *security.JWTManager, log *logger.Logger) *Service {
	return &Service{
		repo: repo,
		jwt:  jwt,
		log:  log,
	}
}

// Register creates a new user account.
func (s *Service) Register(ctx context.Context, req RegisterRequest) (*TokenResponse, error) {
	// Hash password
	hash, err := security.HashPassword(req.Password)
	if err != nil {
		s.log.Error("failed to hash password", logger.Error(err))
		return nil, errors.Wrap("internal_error", 500, "failed to process password", err)
	}

	// Create user within transaction
	tx, err := s.repo.client.Tx(ctx)
	if err != nil {
		s.log.Error("failed to start transaction", logger.Error(err))
		return nil, errors.ErrInternal
	}

	repo := NewRepository(tx.Client())

	// Create user
	user, err := repo.CreateUser(ctx, req.Username, req.Email, hash)
	if err != nil {
		_ = tx.Rollback()
		if errors.IsConflict(err) {
			return nil, errors.New("user_exists", 409, "username or email already taken")
		}
		s.log.Error("failed to create user", logger.Error(err))
		return nil, errors.ErrInternal
	}

	// Create profile
	_, err = repo.CreateUserProfile(ctx, user.ID, req.Username)
	if err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to create profile", logger.Error(err))
		return nil, errors.ErrInternal
	}

	// Create stats
	_, err = repo.CreateUserStats(ctx, user.ID)
	if err != nil {
		_ = tx.Rollback()
		s.log.Error("failed to create stats", logger.Error(err))
		return nil, errors.ErrInternal
	}

	// Create outbox event for UserRegistered
	err = repo.CreateOutboxEvent(ctx, "user.events.v1", user.ID.String(), map[string]any{
		"event_type": "UserRegistered",
		"user_id":    user.ID.String(),
		"username":   user.Username,
		"email":      user.Email,
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

	// Generate tokens
	tokens, err := s.generateTokens(ctx, user.ID)
	if err != nil {
		return nil, err
	}

	s.log.Info("user registered",
		logger.String("user_id", user.ID.String()),
		logger.String("username", user.Username),
	)

	return tokens, nil
}

// Login authenticates a user and returns tokens.
func (s *Service) Login(ctx context.Context, req LoginRequest, deviceInfo, ipAddress string) (*TokenResponse, error) {
	// Find user
	user, err := s.repo.GetUserByEmail(ctx, req.Email)
	if err != nil {
		return nil, errors.ErrInvalidCredentials
	}

	// Check if user is active
	if user.Status != "active" {
		return nil, errors.New("account_disabled", 403, "account has been disabled")
	}

	// Verify password
	if err := security.VerifyPassword(req.Password, user.PasswordHash); err != nil {
		return nil, errors.ErrInvalidCredentials
	}

	// Generate tokens
	tokens, err := s.generateTokens(ctx, user.ID)
	if err != nil {
		return nil, err
	}

	// Create session
	claims, _ := s.jwt.ValidateRefreshToken(tokens.RefreshToken)
	_, err = s.repo.CreateSession(ctx, user.ID, claims.GetTokenID(), deviceInfo, ipAddress)
	if err != nil {
		s.log.Error("failed to create session", logger.Error(err))
	}

	s.log.Info("user logged in",
		logger.String("user_id", user.ID.String()),
		logger.String("email", user.Email),
	)

	return tokens, nil
}

// Refresh generates new access and refresh tokens.
func (s *Service) Refresh(ctx context.Context, refreshToken string) (*TokenResponse, error) {
	// Validate refresh token
	claims, err := s.jwt.ValidateRefreshToken(refreshToken)
	if err != nil {
		return nil, errors.ErrTokenInvalid
	}

	// Check session exists
	session, err := s.repo.GetSessionByTokenID(ctx, claims.GetTokenID())
	if err != nil {
		return nil, errors.ErrTokenInvalid
	}

	// Delete old session
	if err := s.repo.DeleteSession(ctx, session.ID); err != nil {
		s.log.Error("failed to delete old session", logger.Error(err))
	}

	userID, err := uuid.Parse(claims.GetUserID())
	if err != nil {
		return nil, errors.ErrTokenInvalid
	}

	// Generate new tokens
	tokens, err := s.generateTokens(ctx, userID)
	if err != nil {
		return nil, err
	}

	// Create new session
	newClaims, _ := s.jwt.ValidateRefreshToken(tokens.RefreshToken)
	_, err = s.repo.CreateSession(ctx, userID, newClaims.GetTokenID(), session.DeviceInfo, session.IPAddress)
	if err != nil {
		s.log.Error("failed to create new session", logger.Error(err))
	}

	return tokens, nil
}

// Logout invalidates the user's session.
func (s *Service) Logout(ctx context.Context, refreshToken string) error {
	if refreshToken == "" {
		return nil
	}

	claims, err := s.jwt.ValidateRefreshToken(refreshToken)
	if err != nil {
		return nil // Token is already invalid, nothing to do
	}

	session, err := s.repo.GetSessionByTokenID(ctx, claims.GetTokenID())
	if err != nil {
		return nil
	}

	if err := s.repo.DeleteSession(ctx, session.ID); err != nil {
		s.log.Error("failed to delete session", logger.Error(err))
	}

	return nil
}

// LogoutAll invalidates all sessions for a user.
func (s *Service) LogoutAll(ctx context.Context, userID uuid.UUID) error {
	if err := s.repo.DeleteSessionsByUser(ctx, userID); err != nil {
		s.log.Error("failed to delete all sessions", logger.Error(err))
		return errors.ErrInternal
	}
	return nil
}

// GetUserByID retrieves a user by ID.
func (s *Service) GetUserByID(ctx context.Context, id uuid.UUID) (*ent.User, error) {
	user, err := s.repo.GetUserByID(ctx, id)
	if err != nil {
		return nil, errors.ErrNotFound
	}
	return user, nil
}

// GetUserProfile retrieves a user profile by user ID.
func (s *Service) GetUserProfile(ctx context.Context, id uuid.UUID) (*ent.UserProfile, error) {
	profile, err := s.repo.GetUserProfile(ctx, id)
	if err != nil {
		return nil, errors.ErrNotFound
	}
	return profile, nil
}

func (s *Service) generateTokens(ctx context.Context, userID uuid.UUID) (*TokenResponse, error) {
	accessToken, accessClaims, err := s.jwt.GenerateAccessToken(userID.String())
	if err != nil {
		s.log.Error("failed to generate access token", logger.Error(err))
		return nil, errors.ErrInternal
	}

	refreshToken, _, err := s.jwt.GenerateRefreshToken(userID.String())
	if err != nil {
		s.log.Error("failed to generate refresh token", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return &TokenResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresAt:    accessClaims.ExpiresAt.Time,
	}, nil
}
