package payment

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
	"github.com/prabakarankannan/marketplace-backend/internal/common/validator"
	"github.com/prabakarankannan/marketplace-backend/internal/middleware"
)

// PaymentHandler exposes HTTP endpoints for the payment module.
type PaymentHandler struct {
	service PaymentService
}

// NewPaymentHandler returns a new PaymentHandler wired to the given service.
func NewPaymentHandler(service PaymentService) *PaymentHandler {
	return &PaymentHandler{service: service}
}

// RegisterRoutes mounts all payment routes onto the Fiber application.
func RegisterRoutes(app fiber.Router, h *PaymentHandler, jwtSecret string) {
	// -----------------------------------------------------------------
	// Customer payment routes (require authentication)
	// -----------------------------------------------------------------
	payments := app.Group("/payments", middleware.Auth(jwtSecret))
	payments.Post("/create-order", h.CreatePaymentOrder)
	payments.Post("/verify", h.VerifyPayment)
	payments.Get("/:id", h.GetPayment)

	// -----------------------------------------------------------------
	// Vendor wallet routes (require authentication + vendor role)
	// -----------------------------------------------------------------
	wallet := app.Group("/vendors/me/wallet", middleware.Auth(jwtSecret), middleware.RBAC("vendor", "admin"))
	wallet.Get("/", h.GetWallet)
	wallet.Get("/transactions", h.ListTransactions)
	wallet.Post("/payout", h.RequestPayout)

	// -----------------------------------------------------------------
	// Admin routes (require authentication + admin role)
	// -----------------------------------------------------------------
	admin := app.Group("/admin", middleware.Auth(jwtSecret), middleware.RBAC("admin"))
	admin.Get("/payments", h.AdminListPayments)
	admin.Get("/payouts", h.AdminListPayouts)
}

// ---------------------------------------------------------------------------
// Customer endpoints
// ---------------------------------------------------------------------------

// CreatePaymentOrder handles POST /payments/create-order.
func (h *PaymentHandler) CreatePaymentOrder(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	req, err := validator.ParseAndValidate[CreatePaymentRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.CreatePaymentOrder(c.Context(), userID, *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Created(c, result)
}

// VerifyPayment handles POST /payments/verify.
func (h *PaymentHandler) VerifyPayment(c *fiber.Ctx) error {
	req, err := validator.ParseAndValidate[VerifyPaymentRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.VerifyPayment(c.Context(), *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// GetPayment handles GET /payments/:id.
func (h *PaymentHandler) GetPayment(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid payment ID")
	}

	result, err := h.service.GetPayment(c.Context(), id)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// ---------------------------------------------------------------------------
// Vendor wallet endpoints
// ---------------------------------------------------------------------------

// GetWallet handles GET /vendors/me/wallet.
func (h *PaymentHandler) GetWallet(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	result, err := h.service.GetWallet(c.Context(), userID)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// ListTransactions handles GET /vendors/me/wallet/transactions.
func (h *PaymentHandler) ListTransactions(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	params := pagination.FromQuery(c)

	result, err := h.service.ListTransactions(c.Context(), userID, params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// RequestPayout handles POST /vendors/me/wallet/payout.
func (h *PaymentHandler) RequestPayout(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	req, err := validator.ParseAndValidate[PayoutRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.RequestPayout(c.Context(), userID, *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Created(c, result)
}

// ---------------------------------------------------------------------------
// Admin endpoints
// ---------------------------------------------------------------------------

// AdminListPayments handles GET /admin/payments.
func (h *PaymentHandler) AdminListPayments(c *fiber.Ctx) error {
	params := pagination.FromQuery(c)

	result, err := h.service.AdminListPayments(c.Context(), params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// AdminListPayouts handles GET /admin/payouts.
func (h *PaymentHandler) AdminListPayouts(c *fiber.Ctx) error {
	params := pagination.FromQuery(c)

	result, err := h.service.AdminListPayouts(c.Context(), params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}
