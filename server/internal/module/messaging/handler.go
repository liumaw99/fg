package messaging

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/middleware"
	"social-server/internal/platform/pagination"
	"social-server/internal/platform/response"
)

// Handler handles HTTP requests for messaging.
type Handler struct {
	service *Service
	log     *logger.Logger
}

// NewHandler creates a new messaging handler.
func NewHandler(service *Service, log *logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

// CreateConversation creates a new direct conversation.
func (h *Handler) CreateConversation(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	var req CreateConversationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	conv, err := h.service.CreateOrGetConversation(c.Request.Context(), userID, req)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.Created(c, conv)
}

// SendMessage sends a message in a conversation.
func (h *Handler) SendMessage(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	var req SendMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	msg, err := h.service.SendMessage(c.Request.Context(), userID, req)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.Created(c, msg)
}

// ListMessages retrieves messages for a conversation.
func (h *Handler) ListMessages(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	convIDStr := c.Param("conversation_id")
	convID, err := uuid.Parse(convIDStr)
	if err != nil {
		response.BadRequest(c, "invalid_conversation_id", "invalid conversation id")
		return
	}

	params := pagination.DefaultParams()
	params.Cursor = c.Query("cursor")

	result, err := h.service.ListMessages(c.Request.Context(), userID, convID, params)
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

// ListConversations retrieves conversations for the current user.
func (h *Handler) ListConversations(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	params := pagination.DefaultParams()
	params.Cursor = c.Query("cursor")

	result, err := h.service.ListConversations(c.Request.Context(), userID, params)
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

// MarkAsRead marks messages in a conversation as read.
func (h *Handler) MarkAsRead(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	var req MarkReadRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	if err := h.service.MarkAsRead(c.Request.Context(), userID, req); err != nil {
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
