package user

import (
	"social-server/internal/ent"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/storage"
)

// NewUserModule creates the user module dependencies.
func NewUserModule(client *ent.Client, storage *storage.Client, log *logger.Logger) *Handler {
	repo := NewRepository(client)
	service := NewService(repo, storage, log)
	handler := NewHandler(service, log)
	return handler
}
