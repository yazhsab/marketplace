package notification

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
	"github.com/prabakarankannan/marketplace-backend/internal/common/validator"
	"github.com/prabakarankannan/marketplace-backend/internal/middleware"
)

// NotificationHandler exposes HTTP endpoints for the notification module.
type NotificationHandler struct {
	service NotificationService
}

// NewNotificationHandler returns a new NotificationHandler wired to the given service.
func NewNotificationHandler(service NotificationService) *NotificationHandler {
	return &NotificationHandler{service: service}
}

// RegisterRoutes mounts all notification routes onto the Fiber application.
func RegisterRoutes(app fiber.Router, h *NotificationHandler, jwtSecret string) {
	// -----------------------------------------------------------------
	// Authenticated user routes
	// -----------------------------------------------------------------
	notifications := app.Group("/notifications", middleware.Auth(jwtSecret))
	notifications.Get("/", h.ListNotifications)
	notifications.Put("/:id/read", h.MarkAsRead)
	notifications.Put("/read-all", h.MarkAllAsRead)
	notifications.Get("/unread-count", h.GetUnreadCount)

	// -----------------------------------------------------------------
	// Admin routes
	// -----------------------------------------------------------------
	admin := app.Group("/admin/notifications", middleware.Auth(jwtSecret), middleware.RBAC("admin"))
	admin.Post("/send", h.AdminSendNotification)
}

// ---------------------------------------------------------------------------
// Authenticated user endpoints
// ---------------------------------------------------------------------------

// ListNotifications handles GET /notifications.
func (h *NotificationHandler) ListNotifications(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	params := pagination.FromQuery(c)

	result, err := h.service.ListNotifications(c.Context(), userID, params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// MarkAsRead handles PUT /notifications/:id/read.
func (h *NotificationHandler) MarkAsRead(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	notifID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid notification ID")
	}

	if err := h.service.MarkAsRead(c.Context(), userID, notifID); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// MarkAllAsRead handles PUT /notifications/read-all.
func (h *NotificationHandler) MarkAllAsRead(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	if err := h.service.MarkAllAsRead(c.Context(), userID); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// GetUnreadCount handles GET /notifications/unread-count.
func (h *NotificationHandler) GetUnreadCount(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	count, err := h.service.GetUnreadCount(c.Context(), userID)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, fiber.Map{"unread_count": count})
}

// ---------------------------------------------------------------------------
// Admin endpoints
// ---------------------------------------------------------------------------

// AdminSendNotification handles POST /admin/notifications/send.
func (h *NotificationHandler) AdminSendNotification(c *fiber.Ctx) error {
	req, err := validator.ParseAndValidate[AdminSendNotificationRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	if err := h.service.AdminSendNotification(c.Context(), *req); err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, fiber.Map{"message": "notifications sent"})
}
