package auth

import (
	"github.com/gofiber/fiber/v2"

	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
	"github.com/prabakarankannan/marketplace-backend/internal/common/validator"
	"github.com/prabakarankannan/marketplace-backend/internal/middleware"
)

// AuthHandler exposes HTTP endpoints for the auth module.
type AuthHandler struct {
	service AuthService
}

// NewAuthHandler returns a new AuthHandler wired to the given service.
func NewAuthHandler(service AuthService) *AuthHandler {
	return &AuthHandler{service: service}
}

// Register handles POST /auth/register.
func (h *AuthHandler) Register(c *fiber.Ctx) error {
	req, err := validator.ParseAndValidate[RegisterRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.Register(c.Context(), *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.Created(c, result)
}

// LoginEmail handles POST /auth/login/email.
func (h *AuthHandler) LoginEmail(c *fiber.Ctx) error {
	req, err := validator.ParseAndValidate[LoginEmailRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.LoginWithEmail(c.Context(), *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// SendOTP handles POST /auth/otp/send.
func (h *AuthHandler) SendOTP(c *fiber.Ctx) error {
	req, err := validator.ParseAndValidate[SendOTPRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	if err := h.service.SendOTP(c.Context(), *req); err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, fiber.Map{"message": "OTP sent successfully"})
}

// VerifyOTP handles POST /auth/otp/verify.
func (h *AuthHandler) VerifyOTP(c *fiber.Ctx) error {
	req, err := validator.ParseAndValidate[VerifyOTPRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.VerifyOTP(c.Context(), *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// RefreshToken handles POST /auth/refresh.
func (h *AuthHandler) RefreshToken(c *fiber.Ctx) error {
	req, err := validator.ParseAndValidate[RefreshTokenRequest](c)
	if err != nil {
		return response.Error(c, err)
	}

	result, err := h.service.RefreshToken(c.Context(), *req)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// GetMe handles GET /auth/me (requires authentication middleware).
func (h *AuthHandler) GetMe(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)

	result, err := h.service.GetUserByID(c.Context(), userID)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}
