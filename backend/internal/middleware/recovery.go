package middleware

import (
	"log/slog"
	"runtime/debug"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

// Recovery returns a Fiber middleware that catches panics in downstream
// handlers, logs the panic value and stack trace, and returns a 500
// Internal Server Error response instead of crashing the process.
func Recovery() fiber.Handler {
	return recover.New(recover.Config{
		EnableStackTrace: true,
		StackTraceHandler: func(c *fiber.Ctx, e interface{}) {
			slog.Error("panic recovered",
				slog.Any("error", e),
				slog.String("stack", string(debug.Stack())),
			)
		},
	})
}
