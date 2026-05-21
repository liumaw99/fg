package social

import (
	"social-server/internal/ent"
	"social-server/internal/platform/logger"
)

// NewSocialModule creates the social module dependencies.
func NewSocialModule(client *ent.Client, log *logger.Logger) *Handler {
	repo := NewRepository(client)
	service := NewService(repo, log)
	handler := NewHandler(service, log)
	return handler
}
