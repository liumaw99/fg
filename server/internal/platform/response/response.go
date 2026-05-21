package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Body is the standard API response envelope.
type Body[T any] struct {
	Code    string `json:"code"`
	Message string `json:"message,omitempty"`
	Data    T      `json:"data,omitempty"`
}

// ListData wraps paginated list responses.
type ListData[T any] struct {
	Items      []T    `json:"items"`
	NextCursor string `json:"next_cursor,omitempty"`
	HasMore    bool   `json:"has_more"`
}

// OK responds with 200 and data.
func OK[T any](c *gin.Context, data T) {
	c.JSON(http.StatusOK, Body[T]{Code: "ok", Data: data})
}

// Created responds with 201 and data.
func Created[T any](c *gin.Context, data T) {
	c.JSON(http.StatusCreated, Body[T]{Code: "ok", Data: data})
}

// NoContent responds with 204.
func NoContent(c *gin.Context) {
	c.Status(http.StatusNoContent)
}

// Error responds with an error status and standard error body.
func Error(c *gin.Context, status int, code, message string) {
	c.AbortWithStatusJSON(status, Body[any]{Code: code, Message: message})
}

// BadRequest responds with 400.
func BadRequest(c *gin.Context, code, message string) {
	Error(c, http.StatusBadRequest, code, message)
}

// Unauthorized responds with 401.
func Unauthorized(c *gin.Context, code, message string) {
	Error(c, http.StatusUnauthorized, code, message)
}

// Forbidden responds with 403.
func Forbidden(c *gin.Context, code, message string) {
	Error(c, http.StatusForbidden, code, message)
}

// NotFound responds with 404.
func NotFound(c *gin.Context, code, message string) {
	Error(c, http.StatusNotFound, code, message)
}

// Conflict responds with 409.
func Conflict(c *gin.Context, code, message string) {
	Error(c, http.StatusConflict, code, message)
}

// Unprocessable responds with 422.
func Unprocessable(c *gin.Context, code, message string) {
	Error(c, http.StatusUnprocessableEntity, code, message)
}

// TooManyRequests responds with 429.
func TooManyRequests(c *gin.Context, code, message string) {
	Error(c, http.StatusTooManyRequests, code, message)
}

// InternalError responds with 500.
func InternalError(c *gin.Context) {
	Error(c, http.StatusInternalServerError, "internal_error", "internal server error")
}
