package vendor

import (
	"time"

	"github.com/google/uuid"
	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
)

// ---------------------------------------------------------------------------
// Request DTOs
// ---------------------------------------------------------------------------

// RegisterVendorRequest is the payload for registering a new vendor profile.
type RegisterVendorRequest struct {
	BusinessName string  `json:"business_name" validate:"required"`
	Description  *string `json:"description,omitempty"`
	VendorType   string  `json:"vendor_type"   validate:"required"`
	Address      string  `json:"address"       validate:"required"`
	City         string  `json:"city"          validate:"required"`
	State        string  `json:"state"         validate:"required"`
	Pincode      string  `json:"pincode"       validate:"required"`
	Latitude     float64 `json:"latitude"      validate:"required"`
	Longitude    float64 `json:"longitude"     validate:"required"`
}

// UpdateVendorRequest is the payload for updating vendor profile fields.
type UpdateVendorRequest struct {
	BusinessName  *string  `json:"business_name,omitempty"`
	Description   *string  `json:"description,omitempty"`
	LogoURL       *string  `json:"logo_url,omitempty"`
	BannerURL     *string  `json:"banner_url,omitempty"`
	ServiceRadiusKM *float64 `json:"service_radius_km,omitempty"`
}

// OnlineStatusRequest is the payload for toggling online/offline status.
type OnlineStatusRequest struct {
	IsOnline bool `json:"is_online"`
}

// UploadDocumentRequest is the payload for uploading a vendor document.
type UploadDocumentRequest struct {
	DocType string `json:"doc_type" validate:"required"`
	DocURL  string `json:"doc_url"  validate:"required"`
}

// AdminUpdateStatusRequest is the payload for admin vendor status changes.
type AdminUpdateStatusRequest struct {
	Status string `json:"status" validate:"required,oneof=approved rejected suspended"`
}

// AdminUpdateCommissionRequest is the payload for admin commission changes.
type AdminUpdateCommissionRequest struct {
	CommissionPct float64 `json:"commission_pct" validate:"required,gt=0,lte=100"`
}

// AdminReviewDocumentRequest is the payload for admin document review.
type AdminReviewDocumentRequest struct {
	Status        string  `json:"status"         validate:"required,oneof=approved rejected"`
	RejectionNote *string `json:"rejection_note,omitempty"`
}

// NearbyVendorsRequest holds query parameters for the nearby vendors search.
type NearbyVendorsRequest struct {
	Latitude  float64 `json:"latitude"  validate:"required"`
	Longitude float64 `json:"longitude" validate:"required"`
	RadiusKM  float64 `json:"radius_km"`
}

// ---------------------------------------------------------------------------
// Response DTOs
// ---------------------------------------------------------------------------

// VendorResponse is the public representation of a vendor.
type VendorResponse struct {
	ID              uuid.UUID  `json:"id"`
	UserID          uuid.UUID  `json:"user_id"`
	BusinessName    string     `json:"business_name"`
	Description     *string    `json:"description,omitempty"`
	LogoURL         *string    `json:"logo_url,omitempty"`
	BannerURL       *string    `json:"banner_url,omitempty"`
	VendorType      string     `json:"vendor_type"`
	Status          string     `json:"status"`
	Latitude        float64    `json:"latitude"`
	Longitude       float64    `json:"longitude"`
	Address         string     `json:"address"`
	City            string     `json:"city"`
	State           string     `json:"state"`
	Pincode         string     `json:"pincode"`
	ServiceRadiusKM float64    `json:"service_radius_km"`
	AvgRating       float64    `json:"avg_rating"`
	TotalReviews    int        `json:"total_reviews"`
	CommissionPct   float64    `json:"commission_pct"`
	IsOnline        bool       `json:"is_online"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

// VendorDocumentResponse is the public representation of a vendor document.
type VendorDocumentResponse struct {
	ID            uuid.UUID  `json:"id"`
	VendorID      uuid.UUID  `json:"vendor_id"`
	DocType       string     `json:"doc_type"`
	DocURL        string     `json:"doc_url"`
	Status        string     `json:"status"`
	RejectionNote *string    `json:"rejection_note,omitempty"`
	VerifiedBy    *uuid.UUID `json:"verified_by,omitempty"`
	VerifiedAt    *time.Time `json:"verified_at,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`
}

// VendorListResponse carries a page of vendors together with pagination meta.
type VendorListResponse struct {
	Vendors []VendorResponse `json:"vendors"`
	Meta    *response.Meta   `json:"meta"`
}

// ---------------------------------------------------------------------------
// Mapping helpers
// ---------------------------------------------------------------------------

// toVendorResponse converts a Vendor model to its public response DTO.
func toVendorResponse(v *Vendor) VendorResponse {
	return VendorResponse{
		ID:              v.ID,
		UserID:          v.UserID,
		BusinessName:    v.BusinessName,
		Description:     v.Description,
		LogoURL:         v.LogoURL,
		BannerURL:       v.BannerURL,
		VendorType:      v.VendorType,
		Status:          v.Status,
		Latitude:        v.Latitude,
		Longitude:       v.Longitude,
		Address:         v.Address,
		City:            v.City,
		State:           v.State,
		Pincode:         v.Pincode,
		ServiceRadiusKM: v.ServiceRadiusKM,
		AvgRating:       v.AvgRating,
		TotalReviews:    v.TotalReviews,
		CommissionPct:   v.CommissionPct,
		IsOnline:        v.IsOnline,
		CreatedAt:       v.CreatedAt,
		UpdatedAt:       v.UpdatedAt,
	}
}

// toVendorDocumentResponse converts a VendorDocument model to its DTO.
func toVendorDocumentResponse(d *VendorDocument) VendorDocumentResponse {
	return VendorDocumentResponse{
		ID:            d.ID,
		VendorID:      d.VendorID,
		DocType:       d.DocType,
		DocURL:        d.DocURL,
		Status:        d.Status,
		RejectionNote: d.RejectionNote,
		VerifiedBy:    d.VerifiedBy,
		VerifiedAt:    d.VerifiedAt,
		CreatedAt:     d.CreatedAt,
		UpdatedAt:     d.UpdatedAt,
	}
}
