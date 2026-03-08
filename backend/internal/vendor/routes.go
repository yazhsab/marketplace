package vendor

import (
	"github.com/gofiber/fiber/v2"

	"github.com/prabakarankannan/marketplace-backend/internal/middleware"
)

// RegisterRoutes mounts all vendor routes onto the Fiber application.
// It expects the Auth middleware to be applied externally on the groups that
// require authentication (vendor self-service and admin).
func RegisterRoutes(app fiber.Router, h *VendorHandler, jwtSecret string) {
	// -----------------------------------------------------------------
	// Public routes (no authentication required)
	// -----------------------------------------------------------------
	vendors := app.Group("/vendors")
	vendors.Get("/", h.ListVendors)
	vendors.Get("/nearby", h.NearbyVendors)
	vendors.Get("/:id", h.GetVendor)

	// -----------------------------------------------------------------
	// Vendor self-service routes (require authentication)
	// -----------------------------------------------------------------
	vendorAuth := app.Group("/vendors", middleware.Auth(jwtSecret))
	vendorAuth.Post("/register", h.RegisterVendor)
	vendorAuth.Get("/me", h.GetVendorProfile)
	vendorAuth.Put("/me", h.UpdateVendorProfile)
	vendorAuth.Put("/me/online-status", h.SetOnlineStatus)
	vendorAuth.Post("/me/documents", h.UploadDocument)
	vendorAuth.Get("/me/documents", h.ListMyDocuments)
	vendorAuth.Delete("/me/documents/:id", h.DeleteDocument)

	// -----------------------------------------------------------------
	// Admin routes (require authentication + admin role)
	// -----------------------------------------------------------------
	admin := app.Group("/admin/vendors", middleware.Auth(jwtSecret), middleware.RBAC("admin"))
	admin.Get("/", h.AdminListVendors)
	admin.Get("/:id", h.AdminGetVendor)
	admin.Put("/:id/status", h.AdminUpdateStatus)
	admin.Put("/:id/commission", h.AdminUpdateCommission)
	admin.Get("/:id/documents", h.AdminListDocuments)
	admin.Put("/:id/documents/:docId", h.AdminReviewDocument)
}
