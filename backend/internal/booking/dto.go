package booking

import (
	"fmt"
	"math/rand"
	"time"

	"github.com/google/uuid"
)

// ---------------------------------------------------------------------------
// Service Request DTOs
// ---------------------------------------------------------------------------

// CreateServiceRequest is the payload for creating a new service.
type CreateServiceRequest struct {
	CategoryID   uuid.UUID `json:"category_id"    validate:"required"`
	Name         string    `json:"name"            validate:"required"`
	Slug         string    `json:"slug"            validate:"required"`
	Description  *string   `json:"description,omitempty"`
	Price        float64   `json:"price"           validate:"required,gt=0"`
	DurationMins *int      `json:"duration_mins,omitempty"`
	Images       []string  `json:"images,omitempty"`
	Tags         []string  `json:"tags,omitempty"`
}

// UpdateServiceRequest is the payload for updating an existing service.
type UpdateServiceRequest struct {
	CategoryID   *uuid.UUID `json:"category_id,omitempty"`
	Name         *string    `json:"name,omitempty"`
	Slug         *string    `json:"slug,omitempty"`
	Description  *string    `json:"description,omitempty"`
	Price        *float64   `json:"price,omitempty"        validate:"omitempty,gt=0"`
	DurationMins *int       `json:"duration_mins,omitempty"`
	Images       []string   `json:"images,omitempty"`
	IsActive     *bool      `json:"is_active,omitempty"`
	Tags         []string   `json:"tags,omitempty"`
}

// ---------------------------------------------------------------------------
// Service Response DTOs
// ---------------------------------------------------------------------------

// ServiceResponse is the public representation of a service.
type ServiceResponse struct {
	ID           uuid.UUID `json:"id"`
	VendorID     uuid.UUID `json:"vendor_id"`
	CategoryID   uuid.UUID `json:"category_id"`
	Name         string    `json:"name"`
	Slug         string    `json:"slug"`
	Description  *string   `json:"description,omitempty"`
	Price        float64   `json:"price"`
	DurationMins int       `json:"duration_mins"`
	Images       []string  `json:"images,omitempty"`
	IsActive     bool      `json:"is_active"`
	AvgRating    float64   `json:"avg_rating"`
	TotalReviews int       `json:"total_reviews"`
	Tags         []string  `json:"tags,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// ---------------------------------------------------------------------------
// Slot DTOs
// ---------------------------------------------------------------------------

// CreateSlotsRequest is the payload for creating service slots in batch.
type CreateSlotsRequest struct {
	ServiceID uuid.UUID   `json:"service_id" validate:"required"`
	Slots     []SlotInput `json:"slots"      validate:"required,min=1,dive"`
}

// SlotInput represents a single slot to be created.
type SlotInput struct {
	Date        string `json:"date"         validate:"required"`
	StartTime   string `json:"start_time"   validate:"required"`
	EndTime     string `json:"end_time"     validate:"required"`
	MaxBookings *int   `json:"max_bookings,omitempty"`
}

// SlotResponse is the public representation of a service slot.
type SlotResponse struct {
	ID          uuid.UUID `json:"id"`
	ServiceID   uuid.UUID `json:"service_id"`
	VendorID    uuid.UUID `json:"vendor_id"`
	SlotDate    time.Time `json:"slot_date"`
	StartTime   string    `json:"start_time"`
	EndTime     string    `json:"end_time"`
	MaxBookings int       `json:"max_bookings"`
	BookedCount int       `json:"booked_count"`
	IsAvailable bool      `json:"is_available"`
	CreatedAt   time.Time `json:"created_at"`
}

// ---------------------------------------------------------------------------
// Booking DTOs
// ---------------------------------------------------------------------------

// BookingRequest is the payload for creating a new booking.
type BookingRequest struct {
	ServiceID uuid.UUID  `json:"service_id" validate:"required"`
	SlotID    uuid.UUID  `json:"slot_id"    validate:"required"`
	AddressID *uuid.UUID `json:"address_id,omitempty"`
	Notes     *string    `json:"notes,omitempty"`
}

// BookingResponse is the public representation of a booking.
type BookingResponse struct {
	ID                 uuid.UUID  `json:"id"`
	BookingNumber      string     `json:"booking_number"`
	CustomerID         uuid.UUID  `json:"customer_id"`
	VendorID           uuid.UUID  `json:"vendor_id"`
	ServiceID          uuid.UUID  `json:"service_id"`
	SlotID             uuid.UUID  `json:"slot_id"`
	AddressID          *uuid.UUID `json:"address_id,omitempty"`
	Status             string     `json:"status"`
	ScheduledDate      time.Time  `json:"scheduled_date"`
	ScheduledStart     string     `json:"scheduled_start"`
	ScheduledEnd       string     `json:"scheduled_end"`
	ServiceName        string     `json:"service_name"`
	Price              float64    `json:"price"`
	Tax                float64    `json:"tax"`
	Total              float64    `json:"total"`
	PaymentStatus      string     `json:"payment_status"`
	Notes              *string    `json:"notes,omitempty"`
	StartedAt          *time.Time `json:"started_at,omitempty"`
	CompletedAt        *time.Time `json:"completed_at,omitempty"`
	CancelledAt        *time.Time `json:"cancelled_at,omitempty"`
	CancellationReason *string    `json:"cancellation_reason,omitempty"`
	CreatedAt          time.Time  `json:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at"`
}

// UpdateBookingStatusRequest is the payload for updating a booking's status.
type UpdateBookingStatusRequest struct {
	Status string `json:"status" validate:"required"`
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// GenerateBookingNumber creates a unique booking number in the format
// BKG-YYYYMMDD-XXXX where XXXX is a random 4-character alphanumeric string.
func GenerateBookingNumber() string {
	const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	suffix := make([]byte, 4)
	for i := range suffix {
		suffix[i] = charset[rand.Intn(len(charset))]
	}
	return fmt.Sprintf("BKG-%s-%s", time.Now().Format("20060102"), string(suffix))
}

// toServiceResponse converts a Service model to its public response DTO.
func toServiceResponse(s *Service) ServiceResponse {
	return ServiceResponse{
		ID:           s.ID,
		VendorID:     s.VendorID,
		CategoryID:   s.CategoryID,
		Name:         s.Name,
		Slug:         s.Slug,
		Description:  s.Description,
		Price:        s.Price,
		DurationMins: s.DurationMins,
		Images:       s.Images,
		IsActive:     s.IsActive,
		AvgRating:    s.AvgRating,
		TotalReviews: s.TotalReviews,
		Tags:         s.Tags,
		CreatedAt:    s.CreatedAt,
		UpdatedAt:    s.UpdatedAt,
	}
}

// toSlotResponse converts a ServiceSlot model to its public response DTO.
func toSlotResponse(s *ServiceSlot) SlotResponse {
	return SlotResponse{
		ID:          s.ID,
		ServiceID:   s.ServiceID,
		VendorID:    s.VendorID,
		SlotDate:    s.SlotDate,
		StartTime:   s.StartTime,
		EndTime:     s.EndTime,
		MaxBookings: s.MaxBookings,
		BookedCount: s.BookedCount,
		IsAvailable: s.IsAvailable,
		CreatedAt:   s.CreatedAt,
	}
}

// toBookingResponse converts a Booking model to its public response DTO.
func toBookingResponse(b *Booking) *BookingResponse {
	return &BookingResponse{
		ID:                 b.ID,
		BookingNumber:      b.BookingNumber,
		CustomerID:         b.CustomerID,
		VendorID:           b.VendorID,
		ServiceID:          b.ServiceID,
		SlotID:             b.SlotID,
		AddressID:          b.AddressID,
		Status:             b.Status,
		ScheduledDate:      b.ScheduledDate,
		ScheduledStart:     b.ScheduledStart,
		ScheduledEnd:       b.ScheduledEnd,
		ServiceName:        b.ServiceName,
		Price:              b.Price,
		Tax:                b.Tax,
		Total:              b.Total,
		PaymentStatus:      b.PaymentStatus,
		Notes:              b.Notes,
		StartedAt:          b.StartedAt,
		CompletedAt:        b.CompletedAt,
		CancelledAt:        b.CancelledAt,
		CancellationReason: b.CancellationReason,
		CreatedAt:          b.CreatedAt,
		UpdatedAt:          b.UpdatedAt,
	}
}
