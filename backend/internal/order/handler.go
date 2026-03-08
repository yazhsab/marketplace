package order

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
	"github.com/prabakarankannan/marketplace-backend/internal/common/validator"
	"github.com/prabakarankannan/marketplace-backend/internal/middleware"
)

// OrderHandler exposes HTTP endpoints for the order module.
type OrderHandler struct {
	service OrderService
}

// NewOrderHandler returns a new OrderHandler wired to the given service.
func NewOrderHandler(service OrderService) *OrderHandler {
	return &OrderHandler{service: service}
}

// RegisterRoutes mounts all order routes onto the Fiber application.
func RegisterRoutes(app fiber.Router, h *OrderHandler, jwtSecret string) {
	// -----------------------------------------------------------------
	// Customer routes (require authentication)
	// -----------------------------------------------------------------
	orders := app.Group("/orders", middleware.Auth(jwtSecret))
	orders.Post("/", h.CreateOrder)
	orders.Get("/", h.ListMyOrders)
	orders.Get("/:id", h.GetOrder)
	orders.Put("/:id/cancel", h.CancelOrder)

	// -----------------------------------------------------------------
	// Vendor routes (require authentication + vendor role)
	// -----------------------------------------------------------------
	vendorOrders := app.Group("/vendors/me/orders", middleware.Auth(jwtSecret), middleware.RBAC("vendor", "admin"))
	vendorOrders.Get("/", h.VendorListOrders)
	vendorOrders.Get("/:id", h.VendorGetOrder)
	vendorOrders.Put("/:id/status", h.VendorUpdateStatus)

	// -----------------------------------------------------------------
	// Admin routes (require authentication + admin role)
	// -----------------------------------------------------------------
	adminOrders := app.Group("/admin/orders", middleware.Auth(jwtSecret), middleware.RBAC("admin"))
	adminOrders.Get("/", h.AdminListOrders)
	adminOrders.Get("/:id", h.AdminGetOrder)
}

// ---------------------------------------------------------------------------
// Customer endpoints
// ---------------------------------------------------------------------------

// CreateOrder handles POST /orders.
func (h *OrderHandler) CreateOrder(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	req, err := validator.ParseAndValidate[CreateOrderRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.CreateOrder(c.Context(), userID, *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Created(c, result)
}

// GetOrder handles GET /orders/:id.
func (h *OrderHandler) GetOrder(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid order ID")
	}

	result, err := h.service.GetOrder(c.Context(), id)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// ListMyOrders handles GET /orders.
func (h *OrderHandler) ListMyOrders(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	params := pagination.FromQuery(c)

	result, err := h.service.ListMyOrders(c.Context(), userID, params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// CancelOrder handles PUT /orders/:id/cancel.
func (h *OrderHandler) CancelOrder(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	orderID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid order ID")
	}

	if err := h.service.CancelOrder(c.Context(), userID, orderID); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// ---------------------------------------------------------------------------
// Vendor endpoints
// ---------------------------------------------------------------------------

// VendorListOrders handles GET /vendors/me/orders.
func (h *OrderHandler) VendorListOrders(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	params := pagination.FromQuery(c)
	var statusFilter *string
	if s := c.Query("status"); s != "" {
		statusFilter = &s
	}

	result, err := h.service.ListVendorOrders(c.Context(), userID, params, statusFilter)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// VendorGetOrder handles GET /vendors/me/orders/:id.
func (h *OrderHandler) VendorGetOrder(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid order ID")
	}

	result, err := h.service.GetOrder(c.Context(), id)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// VendorUpdateStatus handles PUT /vendors/me/orders/:id/status.
func (h *OrderHandler) VendorUpdateStatus(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	orderID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid order ID")
	}

	req, parseErr := validator.ParseAndValidate[UpdateOrderStatusRequest](c)
	if parseErr != nil {
		return response.Error(c, parseErr)
	}

	if err := h.service.UpdateOrderStatus(c.Context(), userID, orderID, req.Status); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// ---------------------------------------------------------------------------
// Admin endpoints
// ---------------------------------------------------------------------------

// AdminListOrders handles GET /admin/orders.
func (h *OrderHandler) AdminListOrders(c *fiber.Ctx) error {
	params := pagination.FromQuery(c)
	var statusFilter *string
	if s := c.Query("status"); s != "" {
		statusFilter = &s
	}

	result, err := h.service.ListAllOrders(c.Context(), params, statusFilter)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// AdminGetOrder handles GET /admin/orders/:id.
func (h *OrderHandler) AdminGetOrder(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid order ID")
	}

	result, err := h.service.GetOrder(c.Context(), id)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}
