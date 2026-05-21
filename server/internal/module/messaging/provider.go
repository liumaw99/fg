package messaging

import (
	"social-server/internal/ent"
	"social-server/internal/platform/logger"
)

// NewMessagingModule creates the messaging module dependencies.
func NewMessagingModule(client *ent.Client, log *logger.Logger) *Handler {
	repo := NewRepository(client)
	service := NewService(repo, log)
	handler := NewHandler(service, log)
	return handler
}
