package user

import "github.com/google/uuid"

// UpdateProfileRequest contains fields that can be updated on the user profile.
// Both fields are optional; only non-nil values are applied.
type UpdateProfileRequest struct {
	FullName  *string `json:"full_name"`
	AvatarURL *string `json:"avatar_url"`
}

// UpdateFCMTokenRequest carries the Firebase Cloud Messaging token.
type UpdateFCMTokenRequest struct {
	FCMToken string `json:"fcm_token" validate:"required"`
}

// AddressRequest is the payload for creating or updating an address.
type AddressRequest struct {
	Label       string  `json:"label" validate:"required"`
	FullAddress string  `json:"full_address" validate:"required"`
	Landmark    *string `json:"landmark"`
	City        string  `json:"city" validate:"required"`
	State       string  `json:"state" validate:"required"`
	Pincode     string  `json:"pincode" validate:"required"`
	Latitude    float64 `json:"latitude" validate:"required"`
	Longitude   float64 `json:"longitude" validate:"required"`
}

// AddressResponse is the API representation of an address.
type AddressResponse struct {
	ID          uuid.UUID `json:"id"`
	Label       string    `json:"label"`
	FullAddress string    `json:"full_address"`
	Landmark    *string   `json:"landmark,omitempty"`
	City        string    `json:"city"`
	State       string    `json:"state"`
	Pincode     string    `json:"pincode"`
	Latitude    float64   `json:"latitude"`
	Longitude   float64   `json:"longitude"`
	IsDefault   bool      `json:"is_default"`
}

// toResponse converts an Address model to its API response representation.
func toResponse(a *Address) *AddressResponse {
	return &AddressResponse{
		ID:          a.ID,
		Label:       a.Label,
		FullAddress: a.FullAddress,
		Landmark:    a.Landmark,
		City:        a.City,
		State:       a.State,
		Pincode:     a.Pincode,
		Latitude:    a.Latitude,
		Longitude:   a.Longitude,
		IsDefault:   a.IsDefault,
	}
}
