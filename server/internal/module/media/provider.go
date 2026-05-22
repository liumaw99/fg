package media

import (
	"social-server/internal/ent"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/storage"
)

// NewMediaModule creates the media module dependencies.
func NewMediaModule(client *ent.Client, storage *storage.Client, log *logger.Logger) *Handler {
	repo := NewRepository(client)
	service := NewService(repo, storage, log)
	handler := NewHandler(service, log)
	return handler
}
