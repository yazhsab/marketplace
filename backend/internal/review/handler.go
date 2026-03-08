package review

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
	"github.com/prabakarankannan/marketplace-backend/internal/common/validator"
	"github.com/prabakarankannan/marketplace-backend/internal/middleware"
)

// ReviewHandler exposes HTTP endpoints for the review module.
type ReviewHandler struct {
	service ReviewService
}

// NewReviewHandler returns a new ReviewHandler wired to the given service.
func NewReviewHandler(service ReviewService) *ReviewHandler {
	return &ReviewHandler{service: service}
}

// RegisterRoutes mounts all review routes onto the Fiber application.
func RegisterRoutes(app fiber.Router, h *ReviewHandler, jwtSecret string) {
	// -----------------------------------------------------------------
	// Public routes
	// -----------------------------------------------------------------
	reviews := app.Group("/reviews")
	reviews.Get("/product/:id", h.ListProductReviews)
	reviews.Get("/service/:id", h.ListServiceReviews)
	reviews.Get("/vendor/:id", h.ListVendorReviews)

	// -----------------------------------------------------------------
	// Authenticated customer routes
	// -----------------------------------------------------------------
	authReviews := app.Group("/reviews", middleware.Auth(jwtSecret))
	authReviews.Post("/", h.CreateReview)
	authReviews.Put("/:id", h.UpdateReview)
	authReviews.Delete("/:id", h.DeleteReview)

	myReviews := app.Group("/me/reviews", middleware.Auth(jwtSecret))
	myReviews.Get("/", h.ListMyReviews)

	// -----------------------------------------------------------------
	// Vendor routes
	// -----------------------------------------------------------------
	vendorReviews := app.Group("/vendors/me/reviews", middleware.Auth(jwtSecret), middleware.RBAC("vendor", "admin"))
	vendorReviews.Get("/", h.VendorListReviews)
	vendorReviews.Put("/:id/reply", h.VendorReply)

	// -----------------------------------------------------------------
	// Admin routes
	// -----------------------------------------------------------------
	adminReviews := app.Group("/admin/reviews", middleware.Auth(jwtSecret), middleware.RBAC("admin"))
	adminReviews.Get("/", h.AdminListReviews)
	adminReviews.Delete("/:id", h.AdminDeleteReview)
}

// ---------------------------------------------------------------------------
// Public endpoints
// ---------------------------------------------------------------------------

// ListProductReviews handles GET /reviews/product/:id.
func (h *ReviewHandler) ListProductReviews(c *fiber.Ctx) error {
	productID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid product ID")
	}

	params := pagination.FromQuery(c)

	result, err := h.service.ListReviewsForProduct(c.Context(), productID, params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// ListServiceReviews handles GET /reviews/service/:id.
func (h *ReviewHandler) ListServiceReviews(c *fiber.Ctx) error {
	serviceID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid service ID")
	}

	params := pagination.FromQuery(c)

	result, err := h.service.ListReviewsForService(c.Context(), serviceID, params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// ListVendorReviews handles GET /reviews/vendor/:id.
func (h *ReviewHandler) ListVendorReviews(c *fiber.Ctx) error {
	vendorID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid vendor ID")
	}

	params := pagination.FromQuery(c)

	result, err := h.service.ListReviewsForVendor(c.Context(), vendorID, params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// ---------------------------------------------------------------------------
// Authenticated customer endpoints
// ---------------------------------------------------------------------------

// CreateReview handles POST /reviews.
func (h *ReviewHandler) CreateReview(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	req, err := validator.ParseAndValidate[CreateReviewRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.CreateReview(c.Context(), userID, *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Created(c, result)
}

// UpdateReview handles PUT /reviews/:id.
func (h *ReviewHandler) UpdateReview(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	reviewID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid review ID")
	}

	req, parseErr := validator.ParseAndValidate[UpdateReviewRequest](c)
	if parseErr != nil {
		return response.Error(c, parseErr)
	}

	if err := h.service.UpdateReview(c.Context(), userID, reviewID, *req); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// DeleteReview handles DELETE /reviews/:id.
func (h *ReviewHandler) DeleteReview(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	reviewID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid review ID")
	}

	if err := h.service.DeleteReview(c.Context(), userID, reviewID); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// ListMyReviews handles GET /me/reviews.
func (h *ReviewHandler) ListMyReviews(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	params := pagination.FromQuery(c)

	result, err := h.service.ListMyReviews(c.Context(), userID, params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// ---------------------------------------------------------------------------
// Vendor endpoints
// ---------------------------------------------------------------------------

// VendorListReviews handles GET /vendors/me/reviews.
func (h *ReviewHandler) VendorListReviews(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	params := pagination.FromQuery(c)

	result, err := h.service.ListMyReviews(c.Context(), userID, params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// VendorReply handles PUT /vendors/me/reviews/:id/reply.
func (h *ReviewHandler) VendorReply(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	reviewID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid review ID")
	}

	req, parseErr := validator.ParseAndValidate[VendorReplyRequest](c)
	if parseErr != nil {
		return response.Error(c, parseErr)
	}

	if err := h.service.VendorReplyToReview(c.Context(), userID, reviewID, *req); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// ---------------------------------------------------------------------------
// Admin endpoints
// ---------------------------------------------------------------------------

// AdminListReviews handles GET /admin/reviews.
func (h *ReviewHandler) AdminListReviews(c *fiber.Ctx) error {
	params := pagination.FromQuery(c)

	result, err := h.service.AdminListReviews(c.Context(), params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// AdminDeleteReview handles DELETE /admin/reviews/:id.
func (h *ReviewHandler) AdminDeleteReview(c *fiber.Ctx) error {
	reviewID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid review ID")
	}

	if err := h.service.AdminDeleteReview(c.Context(), reviewID); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}
