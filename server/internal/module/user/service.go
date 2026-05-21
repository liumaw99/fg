package user

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"social-server/internal/ent"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/storage"
)

// Service handles user business logic.
type Service struct {
	repo    *Repository
	storage *storage.Client
	log     *logger.Logger
}

// NewService creates a new user service.
func NewService(repo *Repository, storage *storage.Client, log *logger.Logger) *Service {
	return &Service{
		repo:    repo,
		storage: storage,
		log:     log,
	}
}

// GetProfile returns a user's complete profile.
func (s *Service) GetProfile(ctx context.Context, userID uuid.UUID) (*ProfileResponse, error) {
	user, err := s.repo.GetUser(ctx, userID)
	if err != nil {
		return nil, errors.ErrNotFound
	}

	profile, err := s.repo.GetProfile(ctx, userID)
	if err != nil {
		s.log.Warn("profile not found", logger.String("user_id", userID.String()))
		profile = &ent.UserProfile{}
	}

	stats, err := s.repo.GetStats(ctx, userID)
	if err != nil {
		s.log.Warn("stats not found", logger.String("user_id", userID.String()))
		stats = &ent.UserStats{}
	}

	return &ProfileResponse{
		ID:             user.ID.String(),
		Username:       user.Username,
		DisplayName:    profile.DisplayName,
		Bio:            profile.Bio,
		AvatarURL:      profile.AvatarURL,
		CoverURL:       profile.CoverURL,
		Location:       profile.Location,
		Website:        profile.Website,
		FollowerCount:  stats.FollowerCount,
		FollowingCount: stats.FollowingCount,
		PostCount:      stats.PostCount,
	}, nil
}

// GetProfileByUsername returns a user's profile by username.
func (s *Service) GetProfileByUsername(ctx context.Context, username string) (*ProfileResponse, error) {
	user, err := s.repo.GetUserByUsername(ctx, username)
	if err != nil {
		return nil, errors.ErrNotFound
	}
	return s.GetProfile(ctx, user.ID)
}

// UpdateProfile updates the current user's profile.
func (s *Service) UpdateProfile(ctx context.Context, userID uuid.UUID, req UpdateProfileRequest) (*ProfileResponse, error) {
	_, err := s.repo.UpdateProfile(ctx, userID, req.DisplayName, req.Bio, req.Location, req.Website)
	if err != nil {
		s.log.Error("failed to update profile", logger.Error(err))
		return nil, errors.ErrInternal
	}
	return s.GetProfile(ctx, userID)
}

// GenerateAvatarUploadURL creates a presigned URL for avatar upload.
func (s *Service) GenerateAvatarUploadURL(ctx context.Context, userID uuid.UUID, filename, mimeType string) (*UploadURLResponse, error) {
	if s.storage == nil {
		return nil, errors.New("storage_unavailable", 503, "storage service unavailable")
	}

	ext := s.fileExtension(filename)
	objectKey := fmt.Sprintf("avatars/%s/%d%s", userID.String(), time.Now().Unix(), ext)

	uploadURL, err := s.storage.PresignedPutURL(ctx, objectKey, 15*time.Minute)
	if err != nil {
		s.log.Error("failed to generate presigned url", logger.Error(err))
		return nil, errors.ErrInternal
	}

	publicURL := s.storage.PublicURL(objectKey)

	return &UploadURLResponse{
		UploadURL: uploadURL,
		PublicURL: publicURL,
	}, nil
}

func (s *Service) fileExtension(filename string) string {
	for i := len(filename) - 1; i >= 0; i-- {
		if filename[i] == '.' {
			return filename[i:]
		}
	}
	return ""
}
