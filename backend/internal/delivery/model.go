package delivery

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// DeliveryPartner represents a row in the delivery_partners table.
type DeliveryPartner struct {
	ID               uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	UserID           uuid.UUID      `gorm:"type:uuid;uniqueIndex;not null" json:"user_id"`
	VehicleType      string         `gorm:"type:varchar(20);not null" json:"vehicle_type"`
	VehicleNumber    *string        `gorm:"type:varchar(20)" json:"vehicle_number,omitempty"`
	LicenseNumber    *string        `gorm:"type:varchar(50)" json:"license_number,omitempty"`
	Status           string         `gorm:"type:varchar(20);not null;default:'pending'" json:"status"`
	CurrentLatitude  float64        `gorm:"type:float8;default:0" json:"current_latitude"`
	CurrentLongitude float64        `gorm:"type:float8;default:0" json:"current_longitude"`
	IsAvailable      bool           `gorm:"default:false" json:"is_available"`
	IsOnShift        bool           `gorm:"default:false" json:"is_on_shift"`
	CurrentOrderID   *uuid.UUID     `gorm:"type:uuid" json:"current_order_id,omitempty"`
	ZonePreference   *string        `gorm:"type:varchar(255)" json:"zone_preference,omitempty"`
	AvgRating        float64        `gorm:"type:float8;default:0" json:"avg_rating"`
	TotalDeliveries  int            `gorm:"default:0" json:"total_deliveries"`
	TotalEarnings    float64        `gorm:"type:float8;default:0" json:"total_earnings"`
	CommissionPct    float64        `gorm:"type:float8;not null;default:15.0" json:"commission_pct"`
	CreatedAt        time.Time      `json:"created_at"`
	UpdatedAt        time.Time      `json:"updated_at"`
	DeletedAt        gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName overrides the default GORM table name.
func (DeliveryPartner) TableName() string { return "delivery_partners" }

// DeliveryAssignment represents a row in the delivery_assignments table.
type DeliveryAssignment struct {
	ID                uuid.UUID  `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	OrderID           uuid.UUID  `gorm:"type:uuid;not null;index" json:"order_id"`
	DeliveryPartnerID uuid.UUID  `gorm:"type:uuid;not null;index" json:"delivery_partner_id"`
	Status            string     `gorm:"type:varchar(20);not null;default:'assigned'" json:"status"`
	AssignedAt        time.Time  `json:"assigned_at"`
	AcceptedAt        *time.Time `json:"accepted_at,omitempty"`
	PickedUpAt        *time.Time `json:"picked_up_at,omitempty"`
	DeliveredAt       *time.Time `json:"delivered_at,omitempty"`
	DeliveryProofURL  *string    `gorm:"type:varchar(500)" json:"delivery_proof_url,omitempty"`
	DeliveryOTP       string     `gorm:"type:varchar(6)" json:"-"`
	DistanceKM        *float64   `gorm:"type:float8" json:"distance_km,omitempty"`
	Earnings          *float64   `gorm:"type:float8" json:"earnings,omitempty"`
	RejectionReason   *string    `gorm:"type:text" json:"rejection_reason,omitempty"`
	CreatedAt         time.Time  `json:"created_at"`
}

// TableName overrides the default GORM table name.
func (DeliveryAssignment) TableName() string { return "delivery_assignments" }
