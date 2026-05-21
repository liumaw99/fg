package auth

import (
	"social-server/internal/ent"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/security"
)

// NewAuthModule creates the auth module dependencies.
func NewAuthModule(client *ent.Client, jwt *security.JWTManager, log *logger.Logger) *Handler {
	repo := NewRepository(client)
	service := NewService(repo, jwt, log)
	handler := NewHandler(service, log)
	return handler
}
