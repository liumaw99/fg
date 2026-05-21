package post

import (
	"social-server/internal/ent"
	"social-server/internal/platform/logger"
)

// NewPostModule creates the post module dependencies.
func NewPostModule(client *ent.Client, log *logger.Logger) *Handler {
	repo := NewRepository(client)
	service := NewService(repo, log)
	handler := NewHandler(service, log)
	return handler
}
