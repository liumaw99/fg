package user

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/middleware"
	"social-server/internal/platform/response"
)

// Handler handles HTTP requests for users.
type Handler struct {
	service *Service
	log     *logger.Logger
}

// NewHandler creates a new user handler.
func NewHandler(service *Service, log *logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

// GetProfile returns the current user's profile.
func (h *Handler) GetProfile(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	profile, err := h.service.GetProfile(c.Request.Context(), userID)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.OK(c, profile)
}

// UpdateProfile updates the current user's profile.
func (h *Handler) UpdateProfile(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	var req UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	profile, err := h.service.UpdateProfile(c.Request.Context(), userID, req)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.OK(c, profile)
}

// GetUserByUsername returns a user's profile by username.
func (h *Handler) GetUserByUsername(c *gin.Context) {
	username := c.Param("username")
	if username == "" {
		response.BadRequest(c, "missing_username", "username is required")
		return
	}

	profile, err := h.service.GetProfileByUsername(c.Request.Context(), username)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.OK(c, profile)
}

// GetAvatarUploadURL generates a presigned URL for avatar upload.
func (h *Handler) GetAvatarUploadURL(c *gin.Context) {
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

	result, err := h.service.GenerateAvatarUploadURL(c.Request.Context(), userID, req.Filename, req.MimeType)
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
