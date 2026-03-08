package vendor

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Vendor represents a row in the vendors table.
type Vendor struct {
	ID              uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	UserID          uuid.UUID      `gorm:"type:uuid;uniqueIndex;not null" json:"user_id"`
	BusinessName    string         `gorm:"type:varchar(255);not null" json:"business_name"`
	Description     *string        `gorm:"type:text" json:"description,omitempty"`
	LogoURL         *string        `gorm:"type:varchar(500)" json:"logo_url,omitempty"`
	BannerURL       *string        `gorm:"type:varchar(500)" json:"banner_url,omitempty"`
	VendorType      string         `gorm:"type:varchar(50);not null" json:"vendor_type"`
	Status          string         `gorm:"type:varchar(20);not null;default:'pending'" json:"status"`
	Latitude        float64        `gorm:"type:float8;not null" json:"latitude"`
	Longitude       float64        `gorm:"type:float8;not null" json:"longitude"`
	Address         string         `gorm:"type:text;not null" json:"address"`
	City            string         `gorm:"type:varchar(100);not null" json:"city"`
	State           string         `gorm:"type:varchar(100);not null" json:"state"`
	Pincode         string         `gorm:"type:varchar(10);not null" json:"pincode"`
	ServiceRadiusKM float64        `gorm:"type:float8;not null;default:10.0" json:"service_radius_km"`
	AvgRating       float64        `gorm:"type:float8;default:0" json:"avg_rating"`
	TotalReviews    int            `gorm:"default:0" json:"total_reviews"`
	CommissionPct   float64        `gorm:"type:float8;not null;default:10.0" json:"commission_pct"`
	IsOnline        bool           `gorm:"default:false" json:"is_online"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
	DeletedAt       gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName overrides the default GORM table name.
func (Vendor) TableName() string {
	return "vendors"
}

// VendorDocument represents a row in the vendor_documents table.
type VendorDocument struct {
	ID            uuid.UUID  `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	VendorID      uuid.UUID  `gorm:"type:uuid;not null;index" json:"vendor_id"`
	DocType       string     `gorm:"type:varchar(50);not null" json:"doc_type"`
	DocURL        string     `gorm:"type:varchar(500);not null" json:"doc_url"`
	Status        string     `gorm:"type:varchar(20);not null;default:'pending'" json:"status"`
	RejectionNote *string    `gorm:"type:text" json:"rejection_note,omitempty"`
	VerifiedBy    *uuid.UUID `gorm:"type:uuid" json:"verified_by,omitempty"`
	VerifiedAt    *time.Time `json:"verified_at,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`
}

// TableName overrides the default GORM table name.
func (VendorDocument) TableName() string {
	return "vendor_documents"
}
