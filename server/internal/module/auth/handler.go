package auth

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/middleware"
	"social-server/internal/platform/response"
)

// Handler handles HTTP requests for auth.
type Handler struct {
	service *Service
	log     *logger.Logger
}

// NewHandler creates a new auth handler.
func NewHandler(service *Service, log *logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

// Register godoc
func (h *Handler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	tokens, err := h.service.Register(c.Request.Context(), req)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.Created(c, tokens)
}

// Login godoc
func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	deviceInfo := c.GetHeader("User-Agent")
	ipAddress := c.ClientIP()

	tokens, err := h.service.Login(c.Request.Context(), req, deviceInfo, ipAddress)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.OK(c, tokens)
}

// Refresh godoc
func (h *Handler) Refresh(c *gin.Context) {
	var req RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	tokens, err := h.service.Refresh(c.Request.Context(), req.RefreshToken)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.OK(c, tokens)
}

// Logout godoc
func (h *Handler) Logout(c *gin.Context) {
	var req LogoutRequest
	_ = c.ShouldBindJSON(&req)

	if err := h.service.Logout(c.Request.Context(), req.RefreshToken); err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.NoContent(c)
}

// Me returns the current user.
func (h *Handler) Me(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	user, err := h.service.GetUserByID(c.Request.Context(), userID)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.OK(c, gin.H{
		"id":       user.ID.String(),
		"username": user.Username,
		"email":    user.Email,
		"status":   user.Status,
	})
}
