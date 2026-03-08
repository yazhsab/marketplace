package middleware

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
)

// Claims holds the custom JWT claims extracted from the access token.
type Claims struct {
	UserID uuid.UUID `json:"user_id"`
	Role   string    `json:"role"`
	jwt.RegisteredClaims
}

// Auth returns a Fiber middleware that validates a Bearer JWT from the
// Authorization header. On success it stores "user_id" (uuid.UUID) and
// "role" (string) in c.Locals so downstream handlers can access them.
func Auth(jwtSecret string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return response.Unauthorized(c, "Missing authorization header")
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			return response.Unauthorized(c, "Invalid authorization header format")
		}

		tokenString := parts[1]

		token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(t *jwt.Token) (interface{}, error) {
			if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}
			return []byte(jwtSecret), nil
		})
		if err != nil || !token.Valid {
			return response.Unauthorized(c, "Invalid or expired token")
		}

		claims, ok := token.Claims.(*Claims)
		if !ok {
			return response.Unauthorized(c, "Invalid token claims")
		}

		if claims.UserID == uuid.Nil {
			return response.Unauthorized(c, "Invalid user ID in token")
		}

		c.Locals("user_id", claims.UserID)
		c.Locals("role", claims.Role)

		return c.Next()
	}
}
