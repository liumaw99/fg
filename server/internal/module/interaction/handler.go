package interaction

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/middleware"
	"social-server/internal/platform/pagination"
	"social-server/internal/platform/response"
)

// Handler handles HTTP requests for interactions.
type Handler struct {
	service *Service
	log     *logger.Logger
}

// NewHandler creates a new interaction handler.
func NewHandler(service *Service, log *logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

// Like adds a like to a post.
func (h *Handler) Like(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	var req LikeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	if err := h.service.Like(c.Request.Context(), userID, req); err != nil {
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

// Unlike removes a like from a post.
func (h *Handler) Unlike(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	var req UnlikeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	if err := h.service.Unlike(c.Request.Context(), userID, req); err != nil {
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

// GetLikeStatus checks if the current user liked a post.
func (h *Handler) GetLikeStatus(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	postIDStr := c.Param("post_id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		response.BadRequest(c, "invalid_post_id", "invalid post id")
		return
	}

	status, err := h.service.GetLikeStatus(c.Request.Context(), userID, postID)
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

// ListNotifications returns notifications for the current user.
func (h *Handler) ListNotifications(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	params := pagination.DefaultParams()
	params.Cursor = c.Query("cursor")

	result, err := h.service.ListNotifications(c.Request.Context(), userID, params)
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

// MarkNotificationAsRead marks a notification as read.
func (h *Handler) MarkNotificationAsRead(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	notifIDStr := c.Param("id")
	notifID, err := uuid.Parse(notifIDStr)
	if err != nil {
		response.BadRequest(c, "invalid_notification_id", "invalid notification id")
		return
	}

	if err := h.service.MarkNotificationAsRead(c.Request.Context(), userID, notifID); err != nil {
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

// MarkAllNotificationsAsRead marks all notifications as read.
func (h *Handler) MarkAllNotificationsAsRead(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	if err := h.service.MarkAllNotificationsAsRead(c.Request.Context(), userID); err != nil {
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
