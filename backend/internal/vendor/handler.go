package vendor

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
	"github.com/prabakarankannan/marketplace-backend/internal/common/validator"
	"github.com/prabakarankannan/marketplace-backend/internal/middleware"
)

// VendorHandler exposes HTTP endpoints for the vendor module.
type VendorHandler struct {
	service VendorService
}

// NewVendorHandler returns a new VendorHandler wired to the given service.
func NewVendorHandler(service VendorService) *VendorHandler {
	return &VendorHandler{service: service}
}

// ---------------------------------------------------------------------------
// Vendor self-service endpoints
// ---------------------------------------------------------------------------

// RegisterVendor handles POST /vendors/register.
func (h *VendorHandler) RegisterVendor(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	req, err := validator.ParseAndValidate[RegisterVendorRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.Register(c.Context(), userID, *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Created(c, result)
}

// GetVendorProfile handles GET /vendors/me.
func (h *VendorHandler) GetVendorProfile(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	result, err := h.service.GetProfile(c.Context(), userID)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// UpdateVendorProfile handles PUT /vendors/me.
func (h *VendorHandler) UpdateVendorProfile(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	req, err := validator.ParseAndValidate[UpdateVendorRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	if err := h.service.UpdateProfile(c.Context(), userID, *req); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// SetOnlineStatus handles PUT /vendors/me/online-status.
func (h *VendorHandler) SetOnlineStatus(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	req, err := validator.ParseAndValidate[OnlineStatusRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	if err := h.service.SetOnlineStatus(c.Context(), userID, req.IsOnline); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// UploadDocument handles POST /vendors/me/documents.
func (h *VendorHandler) UploadDocument(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	req, err := validator.ParseAndValidate[UploadDocumentRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.UploadDocument(c.Context(), userID, *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Created(c, result)
}

// ListMyDocuments handles GET /vendors/me/documents.
func (h *VendorHandler) ListMyDocuments(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	result, err := h.service.ListDocuments(c.Context(), userID)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// DeleteDocument handles DELETE /vendors/me/documents/:id.
func (h *VendorHandler) DeleteDocument(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if userID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	docID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid document ID")
	}

	if err := h.service.DeleteDocument(c.Context(), userID, docID); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// ---------------------------------------------------------------------------
// Public endpoints
// ---------------------------------------------------------------------------

// ListVendors handles GET /vendors.
func (h *VendorHandler) ListVendors(c *fiber.Ctx) error {
	params := pagination.FromQuery(c)
	status := c.Query("status")
	city := c.Query("city")

	result, err := h.service.ListAll(c.Context(), params, status, city)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// GetVendor handles GET /vendors/:id.
func (h *VendorHandler) GetVendor(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid vendor ID")
	}

	result, err := h.service.GetByID(c.Context(), id)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// NearbyVendors handles GET /vendors/nearby.
func (h *VendorHandler) NearbyVendors(c *fiber.Ctx) error {
	lat, err := strconv.ParseFloat(c.Query("lat"), 64)
	if err != nil {
		return response.BadRequest(c, "invalid or missing lat parameter")
	}

	lng, err := strconv.ParseFloat(c.Query("lng"), 64)
	if err != nil {
		return response.BadRequest(c, "invalid or missing lng parameter")
	}

	radiusKM := 5.0 // default radius
	if r := c.Query("radius"); r != "" {
		parsed, err := strconv.ParseFloat(r, 64)
		if err != nil {
			return response.BadRequest(c, "invalid radius parameter")
		}
		radiusKM = parsed
	}

	params := pagination.FromQuery(c)

	result, err := h.service.FindNearby(c.Context(), lat, lng, radiusKM, params)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// ---------------------------------------------------------------------------
// Admin endpoints
// ---------------------------------------------------------------------------

// AdminListVendors handles GET /admin/vendors.
func (h *VendorHandler) AdminListVendors(c *fiber.Ctx) error {
	params := pagination.FromQuery(c)
	status := c.Query("status")
	city := c.Query("city")

	result, err := h.service.ListAll(c.Context(), params, status, city)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// AdminGetVendor handles GET /admin/vendors/:id.
func (h *VendorHandler) AdminGetVendor(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid vendor ID")
	}

	result, err := h.service.GetByID(c.Context(), id)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// AdminUpdateStatus handles PUT /admin/vendors/:id/status.
func (h *VendorHandler) AdminUpdateStatus(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid vendor ID")
	}

	req, parseErr := validator.ParseAndValidate[AdminUpdateStatusRequest](c)
	if parseErr != nil {
		return response.Error(c, parseErr)
	}

	if err := h.service.AdminUpdateStatus(c.Context(), id, *req); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// AdminUpdateCommission handles PUT /admin/vendors/:id/commission.
func (h *VendorHandler) AdminUpdateCommission(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid vendor ID")
	}

	req, parseErr := validator.ParseAndValidate[AdminUpdateCommissionRequest](c)
	if parseErr != nil {
		return response.Error(c, parseErr)
	}

	if err := h.service.AdminUpdateCommission(c.Context(), id, req.CommissionPct); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}

// AdminListDocuments handles GET /admin/vendors/:id/documents.
func (h *VendorHandler) AdminListDocuments(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid vendor ID")
	}

	v, svcErr := h.service.GetByID(c.Context(), id)
	if svcErr != nil {
		return response.Error(c, svcErr)
	}

	docs, svcErr := h.service.ListDocuments(c.Context(), v.UserID)
	if svcErr != nil {
		return response.Error(c, svcErr)
	}

	return response.OK(c, docs)
}

// AdminReviewDocument handles PUT /admin/vendors/:id/documents/:docId.
func (h *VendorHandler) AdminReviewDocument(c *fiber.Ctx) error {
	docID, err := uuid.Parse(c.Params("docId"))
	if err != nil {
		return response.BadRequest(c, "invalid document ID")
	}

	adminUserID := middleware.GetUserID(c)
	if adminUserID == uuid.Nil {
		return response.Unauthorized(c, "authentication required")
	}

	req, parseErr := validator.ParseAndValidate[AdminReviewDocumentRequest](c)
	if parseErr != nil {
		return response.Error(c, parseErr)
	}

	if err := h.service.AdminReviewDocument(c.Context(), docID, *req, adminUserID); err != nil {
		return response.Error(c, err)
	}

	return response.NoContent(c)
}
