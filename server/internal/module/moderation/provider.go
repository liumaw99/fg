package moderation

import (
	"social-server/internal/ent"
	"social-server/internal/platform/logger"
)

// NewModerationModule creates the moderation module dependencies.
func NewModerationModule(client *ent.Client, log *logger.Logger) *Handler {
	repo := NewRepository(client)
	service := NewService(repo, log)
	handler := NewHandler(service, log)
	return handler
}
