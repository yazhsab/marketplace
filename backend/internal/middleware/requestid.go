package middleware

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/requestid"
)

// RequestID returns a Fiber middleware that propagates or generates an
// X-Request-ID header on every request. If the incoming request already
// contains the header its value is reused; otherwise a new UUID is
// generated. The ID is also stored in c.Locals("requestid") for use by
// downstream handlers and loggers.
func RequestID() fiber.Handler {
	return requestid.New()
}
