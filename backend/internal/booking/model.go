package booking

import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

// Service represents a row in the services table.
type Service struct {
	ID           uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	VendorID     uuid.UUID      `gorm:"type:uuid;not null;index" json:"vendor_id"`
	CategoryID   uuid.UUID      `gorm:"type:uuid;not null;index" json:"category_id"`
	Name         string         `gorm:"type:varchar(255);not null" json:"name"`
	Slug         string         `gorm:"type:varchar(255);uniqueIndex;not null" json:"slug"`
	Description  *string        `gorm:"type:text" json:"description,omitempty"`
	Price        float64        `gorm:"type:float8;not null" json:"price"`
	DurationMins int            `gorm:"not null;default:60" json:"duration_mins"`
	Images       pq.StringArray `gorm:"type:text[]" json:"images,omitempty"`
	IsActive     bool           `gorm:"default:true" json:"is_active"`
	AvgRating    float64        `gorm:"type:float8;default:0" json:"avg_rating"`
	TotalReviews int            `gorm:"default:0" json:"total_reviews"`
	Tags         pq.StringArray `gorm:"type:text[]" json:"tags,omitempty"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName overrides the default GORM table name.
func (Service) TableName() string {
	return "services"
}

// ServiceSlot represents a row in the service_slots table.
type ServiceSlot struct {
	ID          uuid.UUID `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	ServiceID   uuid.UUID `gorm:"type:uuid;not null;index" json:"service_id"`
	VendorID    uuid.UUID `gorm:"type:uuid;not null;index" json:"vendor_id"`
	SlotDate    time.Time `gorm:"type:date;not null" json:"slot_date"`
	StartTime   string    `gorm:"type:varchar(10);not null" json:"start_time"`
	EndTime     string    `gorm:"type:varchar(10);not null" json:"end_time"`
	MaxBookings int       `gorm:"not null;default:1" json:"max_bookings"`
	BookedCount int       `gorm:"not null;default:0" json:"booked_count"`
	IsAvailable bool      `gorm:"default:true" json:"is_available"`
	CreatedAt   time.Time `json:"created_at"`
}

// TableName overrides the default GORM table name.
func (ServiceSlot) TableName() string {
	return "service_slots"
}

// Booking represents a row in the bookings table.
type Booking struct {
	ID                 uuid.UUID  `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	BookingNumber      string     `gorm:"type:varchar(50);uniqueIndex;not null" json:"booking_number"`
	CustomerID         uuid.UUID  `gorm:"type:uuid;not null;index" json:"customer_id"`
	VendorID           uuid.UUID  `gorm:"type:uuid;not null;index" json:"vendor_id"`
	ServiceID          uuid.UUID  `gorm:"type:uuid;not null" json:"service_id"`
	SlotID             uuid.UUID  `gorm:"type:uuid;not null" json:"slot_id"`
	AddressID          *uuid.UUID `gorm:"type:uuid" json:"address_id,omitempty"`
	Status             string     `gorm:"type:varchar(30);not null;default:'pending'" json:"status"`
	ScheduledDate      time.Time  `gorm:"type:date;not null" json:"scheduled_date"`
	ScheduledStart     string     `gorm:"type:varchar(10);not null" json:"scheduled_start"`
	ScheduledEnd       string     `gorm:"type:varchar(10);not null" json:"scheduled_end"`
	ServiceName        string     `gorm:"type:varchar(255);not null" json:"service_name"`
	Price              float64    `gorm:"type:float8;not null" json:"price"`
	Tax                float64    `gorm:"type:float8;not null;default:0" json:"tax"`
	Total              float64    `gorm:"type:float8;not null" json:"total"`
	PaymentStatus      string     `gorm:"type:varchar(30);not null;default:'pending'" json:"payment_status"`
	Notes              *string    `gorm:"type:text" json:"notes,omitempty"`
	StartedAt          *time.Time `json:"started_at,omitempty"`
	CompletedAt        *time.Time `json:"completed_at,omitempty"`
	CancelledAt        *time.Time `json:"cancelled_at,omitempty"`
	CancellationReason *string    `gorm:"type:text" json:"cancellation_reason,omitempty"`
	CreatedAt          time.Time  `json:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at"`
}

// TableName overrides the default GORM table name.
func (Booking) TableName() string {
	return "bookings"
}
