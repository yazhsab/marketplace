package delivery

import (
	"time"

	"github.com/google/uuid"
)

// ---------------------------------------------------------------------------
// Request DTOs
// ---------------------------------------------------------------------------

// RegisterDeliveryPartnerRequest is the payload for registering as a delivery partner.
type RegisterDeliveryPartnerRequest struct {
	VehicleType    string  `json:"vehicle_type"    validate:"required,oneof=bike scooter bicycle car"`
	VehicleNumber  *string `json:"vehicle_number,omitempty"`
	LicenseNumber  *string `json:"license_number,omitempty"`
	Latitude       float64 `json:"latitude"        validate:"required"`
	Longitude      float64 `json:"longitude"       validate:"required"`
	ZonePreference *string `json:"zone_preference,omitempty"`
}

// UpdateProfileRequest is the payload for updating a delivery partner's profile.
type UpdateProfileRequest struct {
	VehicleType    *string `json:"vehicle_type,omitempty"    validate:"omitempty,oneof=bike scooter bicycle car"`
	VehicleNumber  *string `json:"vehicle_number,omitempty"`
	LicenseNumber  *string `json:"license_number,omitempty"`
	ZonePreference *string `json:"zone_preference,omitempty"`
}

// UpdateLocationRequest is the payload for updating a delivery partner's GPS location.
type UpdateLocationRequest struct {
	Latitude  float64 `json:"latitude"  validate:"required"`
	Longitude float64 `json:"longitude" validate:"required"`
}

// AvailabilityRequest is the payload for toggling availability.
type AvailabilityRequest struct {
	IsAvailable bool `json:"is_available"`
}

// ShiftRequest is the payload for toggling shift status.
type ShiftRequest struct {
	IsOnShift bool `json:"is_on_shift"`
}

// RejectAssignmentRequest is the payload for rejecting an assignment.
type RejectAssignmentRequest struct {
	Reason *string `json:"reason,omitempty"`
}

// DeliveryProofRequest is the payload for confirming delivery with proof.
type DeliveryProofRequest struct {
	ProofURL string `json:"proof_url" validate:"required,url"`
	OTP      string `json:"otp"       validate:"required,len=6"`
}

// AdminUpdatePartnerStatusRequest is the payload for admin status updates.
type AdminUpdatePartnerStatusRequest struct {
	Status string `json:"status" validate:"required,oneof=approved rejected suspended"`
}

// AdminManualAssignRequest is the payload for admin manual assignment.
type AdminManualAssignRequest struct {
	OrderID           uuid.UUID `json:"order_id"            validate:"required"`
	DeliveryPartnerID uuid.UUID `json:"delivery_partner_id" validate:"required"`
}

// ---------------------------------------------------------------------------
// Response DTOs
// ---------------------------------------------------------------------------

// DeliveryPartnerResponse is the public representation of a delivery partner.
type DeliveryPartnerResponse struct {
	ID               uuid.UUID  `json:"id"`
	UserID           uuid.UUID  `json:"user_id"`
	VehicleType      string     `json:"vehicle_type"`
	VehicleNumber    *string    `json:"vehicle_number,omitempty"`
	LicenseNumber    *string    `json:"license_number,omitempty"`
	Status           string     `json:"status"`
	CurrentLatitude  float64    `json:"current_latitude"`
	CurrentLongitude float64    `json:"current_longitude"`
	IsAvailable      bool       `json:"is_available"`
	IsOnShift        bool       `json:"is_on_shift"`
	CurrentOrderID   *uuid.UUID `json:"current_order_id,omitempty"`
	ZonePreference   *string    `json:"zone_preference,omitempty"`
	AvgRating        float64    `json:"avg_rating"`
	TotalDeliveries  int        `json:"total_deliveries"`
	TotalEarnings    float64    `json:"total_earnings"`
	CommissionPct    float64    `json:"commission_pct"`
	CreatedAt        time.Time  `json:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at"`
}

// AssignmentResponse is the public representation of a delivery assignment.
type AssignmentResponse struct {
	ID                uuid.UUID  `json:"id"`
	OrderID           uuid.UUID  `json:"order_id"`
	DeliveryPartnerID uuid.UUID  `json:"delivery_partner_id"`
	Status            string     `json:"status"`
	AssignedAt        time.Time  `json:"assigned_at"`
	AcceptedAt        *time.Time `json:"accepted_at,omitempty"`
	PickedUpAt        *time.Time `json:"picked_up_at,omitempty"`
	DeliveredAt       *time.Time `json:"delivered_at,omitempty"`
	DeliveryProofURL  *string    `json:"delivery_proof_url,omitempty"`
	DistanceKM        *float64   `json:"distance_km,omitempty"`
	Earnings          *float64   `json:"earnings,omitempty"`
	RejectionReason   *string    `json:"rejection_reason,omitempty"`
	CreatedAt         time.Time  `json:"created_at"`
}

// EarningsResponse is the response for earnings summary.
type EarningsResponse struct {
	TotalEarnings   float64 `json:"total_earnings"`
	TotalDeliveries int     `json:"total_deliveries"`
	TodayEarnings   float64 `json:"today_earnings"`
	TodayDeliveries int     `json:"today_deliveries"`
	WeekEarnings    float64 `json:"week_earnings"`
	WeekDeliveries  int     `json:"week_deliveries"`
	CommissionPct   float64 `json:"commission_pct"`
}

// StatsResponse is the response for delivery partner performance stats.
type StatsResponse struct {
	TotalDeliveries    int     `json:"total_deliveries"`
	AvgRating          float64 `json:"avg_rating"`
	AcceptanceRate     float64 `json:"acceptance_rate"`
	AvgDeliveryTimeMin float64 `json:"avg_delivery_time_min"`
	TotalEarnings      float64 `json:"total_earnings"`
	TodayDeliveries    int     `json:"today_deliveries"`
}

// ---------------------------------------------------------------------------
// Mapping helpers
// ---------------------------------------------------------------------------

func toDeliveryPartnerResponse(dp *DeliveryPartner) DeliveryPartnerResponse {
	return DeliveryPartnerResponse{
		ID:               dp.ID,
		UserID:           dp.UserID,
		VehicleType:      dp.VehicleType,
		VehicleNumber:    dp.VehicleNumber,
		LicenseNumber:    dp.LicenseNumber,
		Status:           dp.Status,
		CurrentLatitude:  dp.CurrentLatitude,
		CurrentLongitude: dp.CurrentLongitude,
		IsAvailable:      dp.IsAvailable,
		IsOnShift:        dp.IsOnShift,
		CurrentOrderID:   dp.CurrentOrderID,
		ZonePreference:   dp.ZonePreference,
		AvgRating:        dp.AvgRating,
		TotalDeliveries:  dp.TotalDeliveries,
		TotalEarnings:    dp.TotalEarnings,
		CommissionPct:    dp.CommissionPct,
		CreatedAt:        dp.CreatedAt,
		UpdatedAt:        dp.UpdatedAt,
	}
}

func toAssignmentResponse(a *DeliveryAssignment) AssignmentResponse {
	return AssignmentResponse{
		ID:                a.ID,
		OrderID:           a.OrderID,
		DeliveryPartnerID: a.DeliveryPartnerID,
		Status:            a.Status,
		AssignedAt:        a.AssignedAt,
		AcceptedAt:        a.AcceptedAt,
		PickedUpAt:        a.PickedUpAt,
		DeliveredAt:       a.DeliveredAt,
		DeliveryProofURL:  a.DeliveryProofURL,
		DistanceKM:        a.DistanceKM,
		Earnings:          a.Earnings,
		RejectionReason:   a.RejectionReason,
		CreatedAt:         a.CreatedAt,
	}
}
