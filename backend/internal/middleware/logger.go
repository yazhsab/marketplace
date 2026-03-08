package middleware

import (
	"log/slog"
	"time"

	"github.com/gofiber/fiber/v2"
)

// Logger returns a Fiber middleware that logs every HTTP request using Go's
// structured slog package. It records the method, path, status code, latency,
// and client IP address.
func Logger() fiber.Handler {
	return func(c *fiber.Ctx) error {
		start := time.Now()

		err := c.Next()

		latency := time.Since(start)

		slog.Info("request",
			slog.String("method", c.Method()),
			slog.String("path", c.Path()),
			slog.Int("status", c.Response().StatusCode()),
			slog.Duration("latency", latency),
			slog.String("ip", c.IP()),
		)

		return err
	}
}
