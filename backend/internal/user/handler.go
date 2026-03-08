package user

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
	"github.com/prabakarankannan/marketplace-backend/internal/common/validator"
	"github.com/prabakarankannan/marketplace-backend/internal/middleware"
)

// Handler holds the HTTP handlers for user-related routes.
type Handler struct {
	service UserService
}

// NewHandler creates a new user Handler with the given service.
func NewHandler(service UserService) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes mounts user routes onto the given Fiber router group.
// All routes require authentication.
func (h *Handler) RegisterRoutes(r fiber.Router) {
	r.Get("/me", h.GetProfile)
	r.Put("/me", h.UpdateProfile)
	r.Delete("/me", h.DeactivateAccount)
	r.Put("/me/fcm-token", h.UpdateFCMToken)

	r.Get("/me/addresses", h.ListAddresses)
	r.Post("/me/addresses", h.AddAddress)
	r.Put("/me/addresses/:id", h.UpdateAddress)
	r.Delete("/me/addresses/:id", h.DeleteAddress)
	r.Put("/me/addresses/:id/default", h.SetDefaultAddress)
}

// GetProfile returns the authenticated user's profile.
// GET /users/me
func (h *Handler) GetProfile(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	user, err := h.service.GetProfile(c.Context(), userID)
	if err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, user)
}

// UpdateProfile updates the authenticated user's profile fields.
// PUT /users/me
func (h *Handler) UpdateProfile(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)

	req, err := validator.ParseAndValidate[UpdateProfileRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	if err := h.service.UpdateProfile(c.Context(), userID, *req); err != nil {
		return response.Error(c, err)
	}
	return response.NoContent(c)
}

// DeactivateAccount soft-deletes the authenticated user's account.
// DELETE /users/me
func (h *Handler) DeactivateAccount(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	if err := h.service.DeactivateAccount(c.Context(), userID); err != nil {
		return response.Error(c, err)
	}
	return response.NoContent(c)
}

// UpdateFCMToken updates the authenticated user's FCM push notification token.
// PUT /users/me/fcm-token
func (h *Handler) UpdateFCMToken(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)

	req, err := validator.ParseAndValidate[UpdateFCMTokenRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	if err := h.service.UpdateFCMToken(c.Context(), userID, req.FCMToken); err != nil {
		return response.Error(c, err)
	}
	return response.NoContent(c)
}

// ListAddresses returns all saved addresses for the authenticated user.
// GET /users/me/addresses
func (h *Handler) ListAddresses(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	addresses, err := h.service.ListAddresses(c.Context(), userID)
	if err != nil {
		return response.Error(c, err)
	}
	return response.OK(c, addresses)
}

// AddAddress creates a new address for the authenticated user.
// POST /users/me/addresses
func (h *Handler) AddAddress(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)

	req, err := validator.ParseAndValidate[AddressRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	addr, err := h.service.AddAddress(c.Context(), userID, *req)
	if err != nil {
		return response.Error(c, err)
	}
	return response.Created(c, addr)
}

// UpdateAddress updates an existing address for the authenticated user.
// PUT /users/me/addresses/:id
func (h *Handler) UpdateAddress(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	addressID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "Invalid address ID")
	}

	req, parseErr := validator.ParseAndValidate[AddressRequest](c)
	if parseErr != nil {
		return response.Error(c, parseErr)
	}

	addr, updateErr := h.service.UpdateAddress(c.Context(), userID, addressID, *req)
	if updateErr != nil {
		return response.Error(c, updateErr)
	}
	return response.OK(c, addr)
}

// DeleteAddress removes an address for the authenticated user.
// DELETE /users/me/addresses/:id
func (h *Handler) DeleteAddress(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	addressID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "Invalid address ID")
	}

	if err := h.service.DeleteAddress(c.Context(), userID, addressID); err != nil {
		return response.Error(c, err)
	}
	return response.NoContent(c)
}

// SetDefaultAddress marks the specified address as the user's default.
// PUT /users/me/addresses/:id/default
func (h *Handler) SetDefaultAddress(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	addressID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return response.BadRequest(c, "Invalid address ID")
	}

	if err := h.service.SetDefaultAddress(c.Context(), userID, addressID); err != nil {
		return response.Error(c, err)
	}
	return response.NoContent(c)
}
