package review

import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

// Review represents a row in the reviews table.
type Review struct {
	ID             uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	CustomerID     uuid.UUID      `gorm:"type:uuid;not null;index" json:"customer_id"`
	VendorID       uuid.UUID      `gorm:"type:uuid;not null;index" json:"vendor_id"`
	ReviewType     string         `gorm:"type:varchar(50);not null" json:"review_type"`
	ReferenceID    uuid.UUID      `gorm:"type:uuid;not null;index" json:"reference_id"`
	OrderID        *uuid.UUID     `gorm:"type:uuid" json:"order_id,omitempty"`
	Rating         int            `gorm:"not null" json:"rating"`
	Title          *string        `gorm:"type:varchar(255)" json:"title,omitempty"`
	Comment        *string        `gorm:"type:text" json:"comment,omitempty"`
	Images         pq.StringArray `gorm:"type:text[]" json:"images,omitempty"`
	IsVerified     bool           `gorm:"default:false" json:"is_verified"`
	VendorReply    *string        `gorm:"type:text" json:"vendor_reply,omitempty"`
	VendorRepliedAt *time.Time    `json:"vendor_replied_at,omitempty"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
	DeletedAt      gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName overrides the default GORM table name.
func (Review) TableName() string {
	return "reviews"
}
