package interaction

import (
	"social-server/internal/ent"
	"social-server/internal/platform/logger"
)

// NewInteractionModule creates the interaction module dependencies.
func NewInteractionModule(client *ent.Client, log *logger.Logger) *Handler {
	repo := NewRepository(client)
	service := NewService(repo, log)
	handler := NewHandler(service, log)
	return handler
}
