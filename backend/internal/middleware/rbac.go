package middleware

import (
	"github.com/gofiber/fiber/v2"

	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
)

// RBAC returns a Fiber middleware that enforces role-based access control.
// It reads the "role" value set by the Auth middleware from c.Locals and
// checks whether it matches any of the allowedRoles. If the role is missing
// or not in the allowed list, it returns a 403 Forbidden response.
func RBAC(allowedRoles ...string) fiber.Handler {
	allowed := make(map[string]struct{}, len(allowedRoles))
	for _, r := range allowedRoles {
		allowed[r] = struct{}{}
	}

	return func(c *fiber.Ctx) error {
		role, ok := c.Locals("role").(string)
		if !ok || role == "" {
			return response.Forbidden(c, "Access denied: role not found")
		}

		if _, found := allowed[role]; !found {
			return response.Forbidden(c, "Access denied: insufficient permissions")
		}

		return c.Next()
	}
}
