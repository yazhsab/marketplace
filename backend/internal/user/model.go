package user

import (
	"time"

	"github.com/google/uuid"
)

// Address represents a saved delivery address for a user.
type Address struct {
	ID          uuid.UUID `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	UserID      uuid.UUID `gorm:"type:uuid;not null;index" json:"user_id"`
	Label       string    `gorm:"type:varchar(50);not null;default:'home'" json:"label"`
	FullAddress string    `gorm:"type:text;not null" json:"full_address"`
	Landmark    *string   `gorm:"type:varchar(255)" json:"landmark,omitempty"`
	City        string    `gorm:"type:varchar(100);not null" json:"city"`
	State       string    `gorm:"type:varchar(100);not null" json:"state"`
	Pincode     string    `gorm:"type:varchar(10);not null" json:"pincode"`
	Latitude    float64   `gorm:"column:latitude;not null" json:"latitude"`
	Longitude   float64   `gorm:"column:longitude;not null" json:"longitude"`
	IsDefault   bool      `gorm:"default:false" json:"is_default"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// TableName overrides the default GORM table name.
func (Address) TableName() string {
	return "addresses"
}
