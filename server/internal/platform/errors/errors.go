package errors

import (
	"errors"
	"fmt"
)

// AppError is the domain error used across the application.
type AppError struct {
	Code       string
	Message    string
	StatusCode int
	Cause      error
}

func (e *AppError) Error() string {
	if e.Cause != nil {
		return fmt.Sprintf("%s: %v", e.Message, e.Cause)
	}
	return e.Message
}

func (e *AppError) Unwrap() error {
	return e.Cause
}

// New creates a new AppError.
func New(code string, status int, message string) *AppError {
	return &AppError{Code: code, StatusCode: status, Message: message}
}

// Wrap wraps an existing error.
func Wrap(code string, status int, message string, cause error) *AppError {
	return &AppError{Code: code, StatusCode: status, Message: message, Cause: cause}
}

// Is checks if target matches the error.
func Is(err, target error) bool {
	return errors.Is(err, target)
}

// As finds the first error in err's chain that matches target.
func As(err error, target any) bool {
	return errors.As(err, target)
}

// Common domain errors.
var (
	ErrInternal           = New("internal_error", 500, "internal server error")
	ErrBadRequest         = New("bad_request", 400, "bad request")
	ErrUnauthorized       = New("unauthorized", 401, "unauthorized")
	ErrForbidden          = New("forbidden", 403, "forbidden")
	ErrNotFound           = New("not_found", 404, "resource not found")
	ErrConflict           = New("conflict", 409, "resource conflict")
	ErrTooManyRequests    = New("too_many_requests", 429, "too many requests")
	ErrValidation         = New("validation_error", 422, "validation failed")
	ErrInvalidCredentials = New("invalid_credentials", 401, "invalid credentials")
	ErrTokenExpired       = New("token_expired", 401, "token expired")
	ErrTokenInvalid       = New("token_invalid", 401, "token invalid")
	ErrRateLimited        = New("rate_limited", 429, "rate limit exceeded")
)

// IsNotFound reports whether err is or wraps ErrNotFound.
func IsNotFound(err error) bool {
	var appErr *AppError
	if errors.As(err, &appErr) {
		return appErr.Code == ErrNotFound.Code
	}
	return false
}

// IsConflict reports whether err is or wraps ErrConflict.
func IsConflict(err error) bool {
	var appErr *AppError
	if errors.As(err, &appErr) {
		return appErr.Code == ErrConflict.Code
	}
	return false
}
