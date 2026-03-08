package middleware

import (
	"context"
	"fmt"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/redis/go-redis/v9"

	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
)

// RateLimit returns a Fiber middleware that enforces per-IP, per-endpoint
// rate limiting using a Redis counter. The key is composed of the client IP
// and the request path. Each request increments the counter; when the count
// exceeds maxRequests within the given window a 429 Too Many Requests
// response is returned.
func RateLimit(cache *redis.Client, maxRequests int, window time.Duration) fiber.Handler {
	return func(c *fiber.Ctx) error {
		ctx := context.Background()
		key := fmt.Sprintf("ratelimit:%s:%s", c.IP(), c.Path())

		count, err := cache.Incr(ctx, key).Result()
		if err != nil {
			// If Redis is unavailable, allow the request through rather than
			// blocking all traffic.
			return c.Next()
		}

		// Set expiry only on the first increment (when counter transitions
		// from 0 to 1) so the window is anchored to the first request.
		if count == 1 {
			cache.Expire(ctx, key, window)
		}

		if count > int64(maxRequests) {
			return response.Error(c, apperrors.RateLimited("Too many requests, please try again later"))
		}

		return c.Next()
	}
}
