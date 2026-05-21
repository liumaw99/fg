package moderation

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"social-server/internal/platform/errors"
	"social-server/internal/platform/logger"
	"social-server/internal/platform/middleware"
	"social-server/internal/platform/pagination"
	"social-server/internal/platform/response"
)

// Handler handles HTTP requests for moderation.
type Handler struct {
	service *Service
	log     *logger.Logger
}

// NewHandler creates a new moderation handler.
func NewHandler(service *Service, log *logger.Logger) *Handler {
	return &Handler{service: service, log: log}
}

// CreateReport creates a new report.
func (h *Handler) CreateReport(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	var req ReportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	rep, err := h.service.CreateReport(c.Request.Context(), userID, req)
	if err != nil {
		var appErr *errors.AppError
		if errors.As(err, &appErr) {
			response.Error(c, appErr.StatusCode, appErr.Code, appErr.Message)
			return
		}
		response.InternalError(c)
		return
	}

	response.Created(c, rep)
}

// ListReports returns reports for admin review.
func (h *Handler) ListReports(c *gin.Context) {
	status := c.Query("status")
	params := pagination.DefaultParams()
	params.Cursor = c.Query("cursor")

	result, err := h.service.ListReports(c.Request.Context(), status, params)
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

// TakeAction performs a moderation action.
func (h *Handler) TakeAction(c *gin.Context) {
	userIDStr := middleware.GetUserID(c)
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		response.Unauthorized(c, "invalid_user", "invalid user id")
		return
	}

	var req ModerationActionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "validation_error", err.Error())
		return
	}

	if err := h.service.TakeAction(c.Request.Context(), userID, req); err != nil {
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

// Search handles search requests.
func (h *Handler) Search(c *gin.Context) {
	q := c.Query("q")
	if q == "" {
		response.OK(c, SearchResponse{Results: []SearchResult{}})
		return
	}

	req := SearchRequest{
		Query:  q,
		Type:   c.Query("type"),
		Cursor: c.Query("cursor"),
	}

	result, err := h.service.Search(c.Request.Context(), req)
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
