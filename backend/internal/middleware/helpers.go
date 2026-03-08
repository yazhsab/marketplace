package middleware

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// GetUserID extracts the authenticated user's ID from c.Locals.
// Returns uuid.Nil if the value is missing or not a valid uuid.UUID.
func GetUserID(c *fiber.Ctx) uuid.UUID {
	id, ok := c.Locals("user_id").(uuid.UUID)
	if !ok {
		return uuid.Nil
	}
	return id
}

// GetUserRole extracts the authenticated user's role from c.Locals.
// Returns an empty string if the value is missing or not a string.
func GetUserRole(c *fiber.Ctx) string {
	role, ok := c.Locals("role").(string)
	if !ok {
		return ""
	}
	return role
}
