package media

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"social-server/internal/ent"
)

// Repository handles media database operations.
type Repository struct {
	client *ent.Client
}

// NewRepository creates a new media repository.
func NewRepository(client *ent.Client) *Repository {
	return &Repository{client: client}
}

// CreateMediaAsset records an uploaded media asset.
func (r *Repository) CreateMediaAsset(ctx context.Context, ownerID uuid.UUID, filename, mimeType string, size int64, url string) (*ent.MediaAsset, error) {
	asset, err := r.client.MediaAsset.Create().
		SetOwnerID(ownerID).
		SetFilename(filename).
		SetMimeType(mimeType).
		SetSize(size).
		SetURL(url).
		SetStatus("uploaded").
		Save(ctx)
	if err != nil {
		return nil, fmt.Errorf("create media asset: %w", err)
	}
	return asset, nil
}
