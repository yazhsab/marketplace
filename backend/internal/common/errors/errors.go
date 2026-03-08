package errors

import (
	"fmt"
	"net/http"
)

// ValidationError represents a single field-level validation failure.
type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

// AppError is the standard application error type used across all layers.
// It carries a machine-readable code, a human-readable message, the HTTP
// status code to return, and optional field-level validation details.
type AppError struct {
	Code       string            `json:"code"`
	Message    string            `json:"message"`
	StatusCode int               `json:"-"`
	Details    []ValidationError `json:"details,omitempty"`
}

// Error implements the error interface.
func (e *AppError) Error() string {
	if len(e.Details) > 0 {
		return fmt.Sprintf("%s: %s (%d validation errors)", e.Code, e.Message, len(e.Details))
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

// WithDetails returns a copy of the error with the given validation details attached.
func (e *AppError) WithDetails(details []ValidationError) *AppError {
	return &AppError{
		Code:       e.Code,
		Message:    e.Message,
		StatusCode: e.StatusCode,
		Details:    details,
	}
}

// Is allows comparison with errors.Is by matching the error code.
func (e *AppError) Is(target error) bool {
	t, ok := target.(*AppError)
	if !ok {
		return false
	}
	return e.Code == t.Code
}

// NotFound creates a 404 error for a missing resource.
func NotFound(message string) *AppError {
	return &AppError{
		Code:       CodeNotFound,
		Message:    message,
		StatusCode: http.StatusNotFound,
	}
}

// BadRequest creates a 400 error for malformed or invalid requests.
func BadRequest(message string) *AppError {
	return &AppError{
		Code:       CodeBadRequest,
		Message:    message,
		StatusCode: http.StatusBadRequest,
	}
}

// Unauthorized creates a 401 error for unauthenticated requests.
func Unauthorized(message string) *AppError {
	return &AppError{
		Code:       CodeUnauthorized,
		Message:    message,
		StatusCode: http.StatusUnauthorized,
	}
}

// Forbidden creates a 403 error for insufficient permissions.
func Forbidden(message string) *AppError {
	return &AppError{
		Code:       CodeForbidden,
		Message:    message,
		StatusCode: http.StatusForbidden,
	}
}

// Conflict creates a 409 error for resource conflicts (e.g., duplicates).
func Conflict(message string) *AppError {
	return &AppError{
		Code:       CodeConflict,
		Message:    message,
		StatusCode: http.StatusConflict,
	}
}

// Internal creates a 500 error for unexpected server-side failures.
// The provided message is logged but a generic message is returned to clients
// to avoid leaking implementation details.
func Internal(message string) *AppError {
	return &AppError{
		Code:       CodeInternal,
		Message:    message,
		StatusCode: http.StatusInternalServerError,
	}
}

// Validation creates a 422 error with field-level validation details.
func Validation(details []ValidationError) *AppError {
	return &AppError{
		Code:       CodeValidation,
		Message:    "Validation failed",
		StatusCode: http.StatusUnprocessableEntity,
		Details:    details,
	}
}

// RateLimited creates a 429 error for rate-limited requests.
func RateLimited(message string) *AppError {
	return &AppError{
		Code:       CodeRateLimited,
		Message:    message,
		StatusCode: http.StatusTooManyRequests,
	}
}
