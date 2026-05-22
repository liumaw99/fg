package media

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/storage"
)

// Service handles media business logic.
type Service struct {
	repo    *Repository
	storage *storage.Client
	log     *logger.Logger
}

// NewService creates a new media service.
func NewService(repo *Repository, storage *storage.Client, log *logger.Logger) *Service {
	return &Service{repo: repo, storage: storage, log: log}
}

// GenerateUploadURL creates a presigned URL and media asset record.
func (s *Service) GenerateUploadURL(ctx context.Context, userID uuid.UUID, req UploadURLRequest) (*UploadURLResponse, error) {
	if s.storage == nil {
		return nil, errors.New("storage_unavailable", 503, "storage service unavailable")
	}
	if !strings.HasPrefix(req.MimeType, "image/") {
		return nil, errors.New("invalid_media_type", 400, "only image uploads are supported")
	}
	if req.Size > 10*1024*1024 {
		return nil, errors.New("media_too_large", 400, "image must be 10MB or smaller")
	}

	purpose := normalizePurpose(req.Purpose)
	objectKey := fmt.Sprintf("%s/%s/%d-%s%s", purpose, userID.String(), time.Now().UnixNano(), uuid.NewString(), fileExtension(req.Filename))
	uploadURL, err := s.storage.PresignedPutURL(ctx, objectKey, 15*time.Minute)
	if err != nil {
		s.log.Error("failed to generate media presigned url", logger.Error(err))
		return nil, errors.ErrInternal
	}
	publicURL := s.storage.PublicURL(objectKey)

	asset, err := s.repo.CreateMediaAsset(ctx, userID, req.Filename, req.MimeType, req.Size, publicURL)
	if err != nil {
		s.log.Error("failed to create media asset", logger.Error(err))
		return nil, errors.ErrInternal
	}

	return &UploadURLResponse{
		MediaAssetID: asset.ID.String(),
		UploadURL:    uploadURL,
		PublicURL:    publicURL,
	}, nil
}

func normalizePurpose(purpose string) string {
	switch purpose {
	case "avatars", "covers", "messages", "posts":
		return purpose
	default:
		return "uploads"
	}
}

func fileExtension(filename string) string {
	for i := len(filename) - 1; i >= 0; i-- {
		if filename[i] == '.' {
			return filename[i:]
		}
	}
	return ""
}
