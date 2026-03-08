package errors

// Error codes used throughout the application to identify error categories.
// These codes are returned in API responses to allow clients to programmatically
// handle different error conditions.
const (
	// CodeValidation indicates one or more request fields failed validation.
	CodeValidation = "VALIDATION_ERROR"

	// CodeNotFound indicates the requested resource does not exist.
	CodeNotFound = "NOT_FOUND"

	// CodeUnauthorized indicates the request lacks valid authentication credentials.
	CodeUnauthorized = "UNAUTHORIZED"

	// CodeForbidden indicates the authenticated user does not have permission
	// to perform the requested action.
	CodeForbidden = "FORBIDDEN"

	// CodeConflict indicates the request conflicts with the current state of
	// the resource (e.g., duplicate creation).
	CodeConflict = "CONFLICT"

	// CodeInternal indicates an unexpected server-side error.
	CodeInternal = "INTERNAL_ERROR"

	// CodeBadRequest indicates the request is malformed or contains invalid data
	// that does not fall under field-level validation.
	CodeBadRequest = "BAD_REQUEST"

	// CodeRateLimited indicates the client has exceeded the allowed request rate.
	CodeRateLimited = "RATE_LIMITED"
)
