package delivery

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
	"github.com/prabakarankannan/marketplace-backend/internal/common/validator"
	"github.com/prabakarankannan/marketplace-backend/internal/middleware"
)

// DeliveryHandler handles HTTP requests for the delivery module.
type DeliveryHandler struct {
	service DeliveryService
}

// NewDeliveryHandler returns a new DeliveryHandler.
func NewDeliveryHandler(service DeliveryService) *DeliveryHandler {
	return &DeliveryHandler{service: service}
}

// ---------------------------------------------------------------------------
// Partner self-service handlers
// ---------------------------------------------------------------------------

// Register registers the authenticated user as a delivery partner.
func (h *DeliveryHandler) Register(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	req, err := validator.ParseAndValidate[RegisterDeliveryPartnerRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.Register(c.Context(), userID, *req)
	if err != nil {
		return response.Error(c, err)
	}
	return response.Created(c, result)
}

// GetProfile returns the delivery partner profile for the authenticated user.
func (h *DeliveryHandler) GetProfile(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	result, err := h.service.GetProfile(c.Context(), userID)
	if err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, result)
}

// UpdateProfile updates the delivery partner profile.
func (h *DeliveryHandler) UpdateProfile(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	req, err := validator.ParseAndValidate[UpdateProfileRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	if err := h.service.UpdateProfile(c.Context(), userID, *req); err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, fiber.Map{"message": "profile updated"})
}

// UpdateLocation updates the delivery partner's GPS location.
func (h *DeliveryHandler) UpdateLocation(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	req, err := validator.ParseAndValidate[UpdateLocationRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	if err := h.service.UpdateLocation(c.Context(), userID, *req); err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, fiber.Map{"message": "location updated"})
}

// SetAvailability toggles the delivery partner's availability.
func (h *DeliveryHandler) SetAvailability(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	req, err := validator.ParseAndValidate[AvailabilityRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	if err := h.service.SetAvailability(c.Context(), userID, req.IsAvailable); err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, fiber.Map{"message": "availability updated"})
}

// SetShift toggles the delivery partner's shift status.
func (h *DeliveryHandler) SetShift(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	req, err := validator.ParseAndValidate[ShiftRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	if err := h.service.SetShift(c.Context(), userID, req.IsOnShift); err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, fiber.Map{"message": "shift status updated"})
}

// ---------------------------------------------------------------------------
// Assignment handlers
// ---------------------------------------------------------------------------

// ListMyAssignments returns paginated assignments for the authenticated partner.
func (h *DeliveryHandler) ListMyAssignments(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	params := pagination.FromQuery(c)
	statusFilter := c.Query("status")

	var sf *string
	if statusFilter != "" {
		sf = &statusFilter
	}

	result, err := h.service.ListMyAssignments(c.Context(), userID, params, sf)
	if err != nil {
		return response.Error(c, err)
	}
	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// GetAssignment returns a single assignment by ID.
func (h *DeliveryHandler) GetAssignment(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	assignmentID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid assignment ID")
	}

	result, err := h.service.GetAssignment(c.Context(), userID, assignmentID)
	if err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, result)
}

// AcceptAssignment accepts a delivery assignment.
func (h *DeliveryHandler) AcceptAssignment(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	assignmentID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid assignment ID")
	}

	if err := h.service.AcceptAssignment(c.Context(), userID, assignmentID); err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, fiber.Map{"message": "assignment accepted"})
}

// RejectAssignment rejects a delivery assignment.
func (h *DeliveryHandler) RejectAssignment(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	assignmentID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid assignment ID")
	}

	var req RejectAssignmentRequest
	_ = c.BodyParser(&req)

	if err := h.service.RejectAssignment(c.Context(), userID, assignmentID, req.Reason); err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, fiber.Map{"message": "assignment rejected"})
}

// PickupOrder marks the order as picked up.
func (h *DeliveryHandler) PickupOrder(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	assignmentID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid assignment ID")
	}

	if err := h.service.PickupOrder(c.Context(), userID, assignmentID); err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, fiber.Map{"message": "order picked up"})
}

// DeliverOrder confirms delivery with proof and OTP.
func (h *DeliveryHandler) DeliverOrder(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	assignmentID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid assignment ID")
	}

	req, err := validator.ParseAndValidate[DeliveryProofRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	if err := h.service.DeliverOrder(c.Context(), userID, assignmentID, *req); err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, fiber.Map{"message": "order delivered successfully"})
}

// ---------------------------------------------------------------------------
// Earnings & stats handlers
// ---------------------------------------------------------------------------

// GetEarnings returns the earnings summary for the authenticated partner.
func (h *DeliveryHandler) GetEarnings(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	result, err := h.service.GetEarnings(c.Context(), userID)
	if err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, result)
}

// GetEarningsHistory returns paginated earnings history.
func (h *DeliveryHandler) GetEarningsHistory(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	params := pagination.FromQuery(c)
	result, err := h.service.GetEarningsHistory(c.Context(), userID, params)
	if err != nil {
		return response.Error(c, err)
	}
	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// GetStats returns performance stats for the authenticated partner.
func (h *DeliveryHandler) GetStats(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	result, err := h.service.GetStats(c.Context(), userID)
	if err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, result)
}

// ---------------------------------------------------------------------------
// Admin handlers
// ---------------------------------------------------------------------------

// AdminListPartners returns paginated delivery partners for admin.
func (h *DeliveryHandler) AdminListPartners(c *fiber.Ctx) error {
	params := pagination.FromQuery(c)
	status := c.Query("status")
	result, err := h.service.AdminListPartners(c.Context(), params, status)
	if err != nil {
		return response.Error(c, err)
	}
	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// AdminGetPartner returns a single delivery partner for admin.
func (h *DeliveryHandler) AdminGetPartner(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid partner ID")
	}

	result, err := h.service.AdminGetPartner(c.Context(), id)
	if err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, result)
}

// AdminUpdateStatus updates a delivery partner's status.
func (h *DeliveryHandler) AdminUpdateStatus(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "invalid partner ID")
	}

	req, err := validator.ParseAndValidate[AdminUpdatePartnerStatusRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	if err := h.service.AdminUpdateStatus(c.Context(), id, *req); err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, fiber.Map{"message": "status updated"})
}

// AdminListAssignments returns paginated assignments for admin.
func (h *DeliveryHandler) AdminListAssignments(c *fiber.Ctx) error {
	params := pagination.FromQuery(c)
	statusFilter := c.Query("status")

	var sf *string
	if statusFilter != "" {
		sf = &statusFilter
	}

	result, err := h.service.AdminListAssignments(c.Context(), params, sf)
	if err != nil {
		return response.Error(c, err)
	}
	return response.Paginated(c, result.Items, result.ToMeta(params))
}

// AdminManualAssign manually assigns a delivery partner to an order.
func (h *DeliveryHandler) AdminManualAssign(c *fiber.Ctx) error {
	req, err := validator.ParseAndValidate[AdminManualAssignRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.AdminManualAssign(c.Context(), *req)
	if err != nil {
		return response.Error(c, err)
	}
	return response.Created(c, result)
}
