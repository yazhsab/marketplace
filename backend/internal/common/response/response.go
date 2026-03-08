package response

import (
	"net/http"

	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"

	"github.com/gofiber/fiber/v2"
)

// Response is the standard success envelope returned by all API endpoints.
type Response struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Message string      `json:"message,omitempty"`
	Meta    *Meta       `json:"meta,omitempty"`
}

// Meta carries pagination metadata for list endpoints.
type Meta struct {
	Page       int `json:"page"`
	PerPage    int `json:"per_page"`
	Total      int `json:"total"`
	TotalPages int `json:"total_pages"`
}

// ErrorResponse is the standard error envelope returned by all API endpoints.
type ErrorResponse struct {
	Success bool        `json:"success"`
	Error   ErrorDetail `json:"error"`
}

// ErrorDetail contains the machine-readable code, human-readable message,
// and optional field-level validation errors.
type ErrorDetail struct {
	Code    string                      `json:"code"`
	Message string                      `json:"message"`
	Details []apperrors.ValidationError  `json:"details,omitempty"`
}

// OK sends a 200 response with the provided data.
func OK(c *fiber.Ctx, data interface{}) error {
	return c.Status(http.StatusOK).JSON(Response{
		Success: true,
		Data:    data,
	})
}

// OKWithMessage sends a 200 response with data and a message.
func OKWithMessage(c *fiber.Ctx, data interface{}, message string) error {
	return c.Status(http.StatusOK).JSON(Response{
		Success: true,
		Data:    data,
		Message: message,
	})
}

// Created sends a 201 response with the provided data.
func Created(c *fiber.Ctx, data interface{}) error {
	return c.Status(http.StatusCreated).JSON(Response{
		Success: true,
		Data:    data,
	})
}

// NoContent sends a 204 response with no body.
func NoContent(c *fiber.Ctx) error {
	return c.SendStatus(http.StatusNoContent)
}

// Paginated sends a 200 response with the provided data and pagination meta.
func Paginated(c *fiber.Ctx, data interface{}, meta *Meta) error {
	return c.Status(http.StatusOK).JSON(Response{
		Success: true,
		Data:    data,
		Meta:    meta,
	})
}

// Error inspects the error type and sends the appropriate error response.
// If the error is an *apperrors.AppError, its status code and details are used.
// Otherwise a generic 500 Internal Server Error is returned.
func Error(c *fiber.Ctx, err error) error {
	appErr, ok := err.(*apperrors.AppError)
	if !ok {
		appErr = apperrors.Internal("An unexpected error occurred")
	}

	return c.Status(appErr.StatusCode).JSON(ErrorResponse{
		Success: false,
		Error: ErrorDetail{
			Code:    appErr.Code,
			Message: appErr.Message,
			Details: appErr.Details,
		},
	})
}

// ValidationErr sends a 422 response with field-level validation errors.
func ValidationErr(c *fiber.Ctx, details []apperrors.ValidationError) error {
	return Error(c, apperrors.Validation(details))
}

// Unauthorized sends a 401 error response with the provided message.
func Unauthorized(c *fiber.Ctx, msg string) error {
	return Error(c, apperrors.Unauthorized(msg))
}

// Forbidden sends a 403 error response with the provided message.
func Forbidden(c *fiber.Ctx, msg string) error {
	return Error(c, apperrors.Forbidden(msg))
}

// NotFound sends a 404 error response with the provided message.
func NotFound(c *fiber.Ctx, msg string) error {
	return Error(c, apperrors.NotFound(msg))
}

// BadRequest sends a 400 error response with the provided message.
func BadRequest(c *fiber.Ctx, msg string) error {
	return Error(c, apperrors.BadRequest(msg))
}

// Conflict sends a 409 error response with the provided message.
func Conflict(c *fiber.Ctx, msg string) error {
	return Error(c, apperrors.Conflict(msg))
}

// InternalError sends a 500 error response with the provided message.
func InternalError(c *fiber.Ctx, msg string) error {
	return Error(c, apperrors.Internal(msg))
}
