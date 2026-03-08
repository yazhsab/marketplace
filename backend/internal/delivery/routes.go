package delivery

import (
	"github.com/gofiber/fiber/v2"

	"github.com/prabakarankannan/marketplace-backend/internal/middleware"
)

// RegisterRoutes mounts all delivery-related routes onto the given router.
func RegisterRoutes(app fiber.Router, h *DeliveryHandler, jwtSecret string) {
	// -----------------------------------------------------------------
	// Delivery partner registration (requires auth, any role)
	// -----------------------------------------------------------------
	deliveryAuth := app.Group("/delivery", middleware.Auth(jwtSecret))
	deliveryAuth.Post("/register", h.Register)

	// -----------------------------------------------------------------
	// Delivery partner self-service routes (requires auth + delivery/admin role)
	// -----------------------------------------------------------------
	deliveryMe := app.Group("/delivery/me", middleware.Auth(jwtSecret), middleware.RBAC("delivery", "admin"))
	deliveryMe.Get("/", h.GetProfile)
	deliveryMe.Put("/", h.UpdateProfile)
	deliveryMe.Put("/location", h.UpdateLocation)
	deliveryMe.Put("/availability", h.SetAvailability)
	deliveryMe.Put("/shift", h.SetShift)
	deliveryMe.Get("/assignments", h.ListMyAssignments)
	deliveryMe.Get("/assignments/:id", h.GetAssignment)
	deliveryMe.Put("/assignments/:id/accept", h.AcceptAssignment)
	deliveryMe.Put("/assignments/:id/reject", h.RejectAssignment)
	deliveryMe.Put("/assignments/:id/pickup", h.PickupOrder)
	deliveryMe.Put("/assignments/:id/deliver", h.DeliverOrder)
	deliveryMe.Get("/earnings", h.GetEarnings)
	deliveryMe.Get("/earnings/history", h.GetEarningsHistory)
	deliveryMe.Get("/stats", h.GetStats)

	// -----------------------------------------------------------------
	// Admin routes (requires auth + admin role)
	// -----------------------------------------------------------------
	admin := app.Group("/admin/delivery-partners", middleware.Auth(jwtSecret), middleware.RBAC("admin"))
	admin.Get("/", h.AdminListPartners)
	admin.Get("/:id", h.AdminGetPartner)
	admin.Put("/:id/status", h.AdminUpdateStatus)

	adminAssignments := app.Group("/admin/delivery-assignments", middleware.Auth(jwtSecret), middleware.RBAC("admin"))
	adminAssignments.Get("/", h.AdminListAssignments)
	adminAssignments.Post("/assign", h.AdminManualAssign)
}
