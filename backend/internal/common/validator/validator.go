package validator

import (
	"strings"
	"sync"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"

	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
)

// Validate is the singleton validator instance used across the application.
// It is safe for concurrent use.
var (
	once     sync.Once
	Validate *validator.Validate
)

func init() {
	once.Do(func() {
		Validate = validator.New(validator.WithRequiredStructEnabled())
	})
}

// ValidateStruct validates the given struct and returns a slice of ValidationError
// for each field that fails validation. Returns nil if the struct is valid.
func ValidateStruct(s interface{}) []apperrors.ValidationError {
	err := Validate.Struct(s)
	if err == nil {
		return nil
	}

	var validationErrors []apperrors.ValidationError

	if errs, ok := err.(validator.ValidationErrors); ok {
		for _, e := range errs {
			validationErrors = append(validationErrors, apperrors.ValidationError{
				Field:   toSnakeCase(e.Field()),
				Message: msgForTag(e),
			})
		}
	}

	return validationErrors
}

// ParseAndValidate binds the JSON request body into a value of type T and runs
// struct validation on it. On success it returns a pointer to the parsed value.
// On failure it returns an *apperrors.AppError (either BadRequest for parse
// failures or Validation for field errors).
func ParseAndValidate[T any](c *fiber.Ctx) (*T, error) {
	var req T

	if err := c.BodyParser(&req); err != nil {
		return nil, apperrors.BadRequest("Invalid request body")
	}

	if errs := ValidateStruct(&req); errs != nil {
		return nil, apperrors.Validation(errs)
	}

	return &req, nil
}

// msgForTag returns a human-readable validation message for common tags.
func msgForTag(fe validator.FieldError) string {
	switch fe.Tag() {
	case "required":
		return "This field is required"
	case "email":
		return "Must be a valid email address"
	case "min":
		return "Must be at least " + fe.Param() + " characters"
	case "max":
		return "Must be at most " + fe.Param() + " characters"
	case "len":
		return "Must be exactly " + fe.Param() + " characters"
	case "gte":
		return "Must be greater than or equal to " + fe.Param()
	case "lte":
		return "Must be less than or equal to " + fe.Param()
	case "gt":
		return "Must be greater than " + fe.Param()
	case "lt":
		return "Must be less than " + fe.Param()
	case "oneof":
		return "Must be one of: " + fe.Param()
	case "url":
		return "Must be a valid URL"
	case "uuid":
		return "Must be a valid UUID"
	case "e164":
		return "Must be a valid phone number in E.164 format"
	case "alphanum":
		return "Must contain only alphanumeric characters"
	case "numeric":
		return "Must be a numeric value"
	case "eqfield":
		return "Must match " + toSnakeCase(fe.Param())
	default:
		return "Failed validation: " + fe.Tag()
	}
}

// toSnakeCase converts a PascalCase or camelCase field name to snake_case.
func toSnakeCase(s string) string {
	var result strings.Builder
	for i, r := range s {
		if r >= 'A' && r <= 'Z' {
			if i > 0 {
				result.WriteByte('_')
			}
			result.WriteRune(r + ('a' - 'A'))
		} else {
			result.WriteRune(r)
		}
	}
	return result.String()
}
