package auth

import "github.com/google/uuid"

// ---------------------------------------------------------------------------
// Request DTOs
// ---------------------------------------------------------------------------

// RegisterRequest is the payload for email/password registration.
type RegisterRequest struct {
	FullName string  `json:"full_name" validate:"required"`
	Email    string  `json:"email"     validate:"required,email"`
	Password string  `json:"password"  validate:"required,min=8"`
	Phone    *string `json:"phone,omitempty"`
}

// LoginEmailRequest is the payload for email/password login.
type LoginEmailRequest struct {
	Email    string `json:"email"    validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

// SendOTPRequest is the payload for requesting an OTP via SMS.
type SendOTPRequest struct {
	Phone string `json:"phone" validate:"required"`
}

// VerifyOTPRequest is the payload for verifying a phone OTP.
type VerifyOTPRequest struct {
	Phone string `json:"phone" validate:"required"`
	OTP   string `json:"otp"   validate:"required"`
}

// RefreshTokenRequest is the payload for refreshing the token pair.
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

// ---------------------------------------------------------------------------
// Response DTOs
// ---------------------------------------------------------------------------

// AuthResponse is returned after successful authentication.
type AuthResponse struct {
	User         UserResponse `json:"user"`
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token"`
}

// UserResponse is the public representation of a user.
type UserResponse struct {
	ID        uuid.UUID `json:"id"`
	FullName  string    `json:"full_name"`
	Email     string    `json:"email"`
	Phone     string    `json:"phone"`
	Role      string    `json:"role"`
	AvatarURL string    `json:"avatar_url"`
}

// toUserResponse converts a User model to its public response representation.
func toUserResponse(u *User) UserResponse {
	resp := UserResponse{
		ID:       u.ID,
		FullName: u.FullName,
		Role:     u.Role,
	}
	if u.Email != nil {
		resp.Email = *u.Email
	}
	if u.Phone != nil {
		resp.Phone = *u.Phone
	}
	if u.AvatarURL != nil {
		resp.AvatarURL = *u.AvatarURL
	}
	return resp
}
