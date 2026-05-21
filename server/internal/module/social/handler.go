package social

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/middleware"
	"social-server/internal/platform/pagination"
	"social-server/internal/platform/response"
)

// Handler handles HTTP requests for social.
type Handler struct {
	service *Service
	log     *logger.Logger
}

// NewHandler creates a new social handler.
func NewHandler(service *Service, log *logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

// Follow follows a user.
func (h *Handler) Follow(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	var req FollowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	if err := h.service.Follow(c.Request.Context(), userID, req); err != nil {
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

// Unfollow unfollows a user.
func (h *Handler) Unfollow(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	var req UnfollowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	if err := h.service.Unfollow(c.Request.Context(), userID, req); err != nil {
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

// GetFollowStatus checks if current user follows a target user.
func (h *Handler) GetFollowStatus(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	targetIDStr := c.Param("user_id")
	targetID, err := uuid.Parse(targetIDStr)
	if err != nil {
		response.BadRequest(c, "invalid_user_id", "invalid user id")
		return
	}

	status, err := h.service.GetFollowStatus(c.Request.Context(), userID, targetID)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.OK(c, status)
}

// ListFollowers returns followers of a user.
func (h *Handler) ListFollowers(c *gin.Context) {
	userIDStr := c.Param("user_id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "invalid_user_id", "invalid user id")
		return
	}

	params := pagination.DefaultParams()
	params.Cursor = c.Query("cursor")

	result, err := h.service.ListFollowers(c.Request.Context(), userID, params)
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

// ListFollowing returns users that a user follows.
func (h *Handler) ListFollowing(c *gin.Context) {
	userIDStr := c.Param("user_id")
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.BadRequest(c, "invalid_user_id", "invalid user id")
		return
	}

	params := pagination.DefaultParams()
	params.Cursor = c.Query("cursor")

	result, err := h.service.ListFollowing(c.Request.Context(), userID, params)
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
