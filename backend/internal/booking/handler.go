package booking

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
	"github.com/prabakarankannan/marketplace-backend/internal/common/validator"
	"github.com/prabakarankannan/marketplace-backend/internal/middleware"
)

// BookingHandler exposes HTTP endpoints for the booking module.
type BookingHandler struct {
	service BookingService
}

// NewBookingHandler returns a new BookingHandler wired to the given service.
func NewBookingHandler(service BookingService) *BookingHandler {
	return &BookingHandler{service: service}
}

// RegisterRoutes mounts all booking routes onto the Fiber application.
func RegisterRoutes(app fiber.Router, h *BookingHandler, jwtSecret string) {
	// -----------------------------------------------------------------
	// Public routes (no authentication required)
	// -----------------------------------------------------------------
	services := app.Group("/services")
	services.Get("/", h.ListServices)
	services.Get("/:id", h.GetService)
	services.Get("/:id/slots", h.GetAvailableSlots)
	services.Get("/vendor/:vendorId", h.ListServicesByVendor)

	// -----------------------------------------------------------------
	// Customer routes (require authentication)
	// -----------------------------------------------------------------
	bookings := app.Group("/bookings", middleware.Auth(jwtSecret))
	bookings.Post("/", h.CreateBooking)
	bookings.Get("/", h.ListMyBookings)
	bookings.Get("/:id", h.GetBooking)
	bookings.Put("/:id/cancel", h.CancelBooking)

	// -----------------------------------------------------------------
	// Vendor routes (require authentication + vendor role)
	// -----------------------------------------------------------------
	vendorServices := app.Group("/vendors/me/services", middleware.Auth(jwtSecret), middleware.RBAC("vendor", "admin"))
	vendorServices.Post("/", h.CreateService)
	vendorServices.Get("/", h.ListMyServices)
	vendorServices.Put("/:id", h.UpdateService)
	vendorServices.Delete("/:id", h.DeleteService)

	vendorSlots := app.Group("/vendors/me/slots", middleware.Auth(jwtSecret), middleware.RBAC("vendor", "admin"))
	vendorSlots.Post("/", h.CreateSlots)
	vendorSlots.Get("/", h.ListMySlots)

	vendorBookings := app.Group("/vendors/me/bookings", middleware.Auth(jwtSecret), middleware.RBAC("vendor", "admin"))
	vendorBookings.Get("/", h.ListVendorBookings)
	vendorBookings.Put("/:id/status", h.UpdateBookingStatus)

	// -----------------------------------------------------------------
	// Admin routes (require authentication + admin role)
	// -----------------------------------------------------------------
	adminBookings := app.Group("/admin/bookings", middleware.Auth(jwtSecret), middleware.RBAC("admin"))
	adminBookings.Get("/", h.AdminListBookings)

	adminServices := app.Group("/admin/services", middleware.Auth(jwtSecret), middleware.RBAC("admin"))
	adminServices.Get("/", h.AdminListServices)
}

// ---------------------------------------------------------------------------
// Public endpoints
// ---------------------------------------------------------------------------

// ListServices handles GET /services.
func (h *BookingHandler) ListServices(c *fiber.Ctx) error {
	params := pagination.FromQuery(c)

	if catID := c.Query("category_id"); catID != "" {
		categoryID, err := uuid.Parse(catID)
		if err != nil {
			return response.BadRequest(c, "invalid category ID")
		}
		result, err := h.service.ListServicesByCategory(c.Context(), categoryID, params)
		if err != nil {
			return response.Error(c, err)
		}
		return response.Paginated(c, result.Items, result.ToMeta(params))
	}

	result, err := h.service.ListServices(c.Context(), params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// GetService handles GET /services/:id.
func (h *BookingHandler) GetService(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid service ID")
	}

	result, err := h.service.GetService(c.Context(), id)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// GetAvailableSlots handles GET /services/:id/slots.
func (h *BookingHandler) GetAvailableSlots(c *fiber.Ctx) error {
	serviceID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid service ID")
	}

	var date *time.Time
	if d := c.Query("date"); d != "" {
		parsed, parseErr := time.Parse("2006-01-02", d)
		if parseErr != nil {
			return response.BadRequest(c, "invalid date format, expected YYYY-MM-DD")
		}
		date = &parsed
	}

	result, err := h.service.GetAvailableSlots(c.Context(), serviceID, date)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// ListServicesByVendor handles GET /services/vendor/:vendorId.
func (h *BookingHandler) ListServicesByVendor(c *fiber.Ctx) error {
	vendorID, err := uuid.Parse(c.Params("vendorId"))
	if err != nil {
		return response.BadRequest(c, "invalid vendor ID")
	}

	params := pagination.FromQuery(c)

	result, err := h.service.ListServicesByVendor(c.Context(), vendorID, params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// ---------------------------------------------------------------------------
// Customer endpoints
// ---------------------------------------------------------------------------

// CreateBooking handles POST /bookings.
func (h *BookingHandler) CreateBooking(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	req, err := validator.ParseAndValidate[BookingRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.CreateBooking(c.Context(), userID, *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Created(c, result)
}

// ListMyBookings handles GET /bookings.
func (h *BookingHandler) ListMyBookings(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	params := pagination.FromQuery(c)

	result, err := h.service.ListMyBookings(c.Context(), userID, params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// GetBooking handles GET /bookings/:id.
func (h *BookingHandler) GetBooking(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid booking ID")
	}

	result, err := h.service.GetBooking(c.Context(), id)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// CancelBooking handles PUT /bookings/:id/cancel.
func (h *BookingHandler) CancelBooking(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	bookingID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid booking ID")
	}

	if err := h.service.CancelBooking(c.Context(), userID, bookingID); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// ---------------------------------------------------------------------------
// Vendor endpoints
// ---------------------------------------------------------------------------

// CreateService handles POST /vendors/me/services.
func (h *BookingHandler) CreateService(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	req, err := validator.ParseAndValidate[CreateServiceRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.CreateService(c.Context(), userID, *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Created(c, result)
}

// UpdateService handles PUT /vendors/me/services/:id.
func (h *BookingHandler) UpdateService(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	serviceID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid service ID")
	}

	req, parseErr := validator.ParseAndValidate[UpdateServiceRequest](c)
	if parseErr != nil {
		return response.Error(c, parseErr)
	}

	if err := h.service.UpdateService(c.Context(), userID, serviceID, *req); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// DeleteService handles DELETE /vendors/me/services/:id.
func (h *BookingHandler) DeleteService(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	serviceID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid service ID")
	}

	if err := h.service.DeleteService(c.Context(), userID, serviceID); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// ListMyServices handles GET /vendors/me/services.
func (h *BookingHandler) ListMyServices(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	params := pagination.FromQuery(c)

	result, err := h.service.ListMyServices(c.Context(), userID, params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// CreateSlots handles POST /vendors/me/slots.
func (h *BookingHandler) CreateSlots(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	req, err := validator.ParseAndValidate[CreateSlotsRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.CreateSlots(c.Context(), userID, *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Created(c, result)
}

// ListMySlots handles GET /vendors/me/slots.
func (h *BookingHandler) ListMySlots(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	serviceID, err := uuid.Parse(c.Query("service_id"))
	if err != nil {
		return response.BadRequest(c, "service_id query parameter is required and must be a valid UUID")
	}

	var startDate, endDate *time.Time
	if d := c.Query("start_date"); d != "" {
		parsed, parseErr := time.Parse("2006-01-02", d)
		if parseErr != nil {
			return response.BadRequest(c, "invalid start_date format, expected YYYY-MM-DD")
		}
		startDate = &parsed
	}
	if d := c.Query("end_date"); d != "" {
		parsed, parseErr := time.Parse("2006-01-02", d)
		if parseErr != nil {
			return response.BadRequest(c, "invalid end_date format, expected YYYY-MM-DD")
		}
		endDate = &parsed
	}

	result, err := h.service.ListMySlots(c.Context(), userID, serviceID, startDate, endDate)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// ListVendorBookings handles GET /vendors/me/bookings.
func (h *BookingHandler) ListVendorBookings(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	params := pagination.FromQuery(c)

	result, err := h.service.ListVendorBookings(c.Context(), userID, params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// UpdateBookingStatus handles PUT /vendors/me/bookings/:id/status.
func (h *BookingHandler) UpdateBookingStatus(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	bookingID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid booking ID")
	}

	req, parseErr := validator.ParseAndValidate[UpdateBookingStatusRequest](c)
	if parseErr != nil {
		return response.Error(c, parseErr)
	}

	if err := h.service.UpdateBookingStatus(c.Context(), userID, bookingID, req.Status); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// ---------------------------------------------------------------------------
// Admin endpoints
// ---------------------------------------------------------------------------

// AdminListBookings handles GET /admin/bookings.
func (h *BookingHandler) AdminListBookings(c *fiber.Ctx) error {
	params := pagination.FromQuery(c)

	result, err := h.service.AdminListBookings(c.Context(), params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// AdminListServices handles GET /admin/services.
func (h *BookingHandler) AdminListServices(c *fiber.Ctx) error {
	params := pagination.FromQuery(c)

	result, err := h.service.AdminListServices(c.Context(), params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}
