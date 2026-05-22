package media

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/middleware"
	"social-server/internal/platform/response"
)

// Handler handles HTTP requests for media.
type Handler struct {
	service *Service
	log     *logger.Logger
}

// NewHandler creates a new media handler.
func NewHandler(service *Service, log *logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

// GetUploadURL generates a presigned URL for media upload.
func (h *Handler) GetUploadURL(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	var req UploadURLRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	result, err := h.service.GenerateUploadURL(c.Request.Context(), userID, req)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.OK(c, result)
}
