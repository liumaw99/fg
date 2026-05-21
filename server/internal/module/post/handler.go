package post

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/middleware"
	"social-server/internal/platform/pagination"
	"social-server/internal/platform/response"
)

// Handler handles HTTP requests for posts.
type Handler struct {
	service *Service
	log     *logger.Logger
}

// NewHandler creates a new post handler.
func NewHandler(service *Service, log *logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

// CreatePost creates a new post.
func (h *Handler) CreatePost(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	var req CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	post, err := h.service.CreatePost(c.Request.Context(), userID, req)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.Created(c, post)
}

// GetPost retrieves a post by ID.
func (h *Handler) GetPost(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	postIDStr := c.Param("id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		response.BadRequest(c, "invalid_post_id", "invalid post id")
		return
	}

	post, err := h.service.GetPost(c.Request.Context(), userID, postID)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.OK(c, post)
}

// DeletePost soft-deletes a post.
func (h *Handler) DeletePost(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	postIDStr := c.Param("id")
	postID, err := uuid.Parse(postIDStr)
	if err != nil {
		response.BadRequest(c, "invalid_post_id", "invalid post id")
		return
	}

	if err := h.service.DeletePost(c.Request.Context(), userID, postID); err != nil {
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

// ListUserPosts retrieves posts by a user.
func (h *Handler) ListUserPosts(c *gin.Context) {
	currentUserIDStr := middleware.GetUserID(c)
	currentUserID, err := uuid.Parse(currentUserIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	targetUserIDStr := c.Param("user_id")
	targetUserID, err := uuid.Parse(targetUserIDStr)
	if err != nil {
		response.BadRequest(c, "invalid_user_id", "invalid user id")
		return
	}

	params := pagination.DefaultParams()
	params.Cursor = c.Query("cursor")
	if limitStr := c.Query("limit"); limitStr != "" {
		if n, err := strconv.Atoi(limitStr); err == nil && n > 0 {
			params.Limit = n
		}
	}

	result, err := h.service.ListUserPosts(c.Request.Context(), targetUserID, currentUserID, params)
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

// ListPosts retrieves all active posts (timeline).
func (h *Handler) ListPosts(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	params := pagination.DefaultParams()
	params.Cursor = c.Query("cursor")

	result, err := h.service.ListPosts(c.Request.Context(), userID, params)
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
