package notification

import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/datatypes"
)

// Notification represents a row in the notifications table.
type Notification struct {
	ID        uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	UserID    uuid.UUID      `gorm:"type:uuid;not null;index" json:"user_id"`
	Title     string         `gorm:"type:varchar(255);not null" json:"title"`
	Body      string         `gorm:"type:text;not null" json:"body"`
	Type      string         `gorm:"type:varchar(50);not null" json:"type"`
	Data      datatypes.JSON `gorm:"type:jsonb" json:"data,omitempty"`
	IsRead    bool           `gorm:"default:false" json:"is_read"`
	SentVia   pq.StringArray `gorm:"type:text[];default:'{push}'" json:"sent_via"`
	CreatedAt time.Time      `json:"created_at"`
}

// TableName overrides the default GORM table name.
func (Notification) TableName() string {
	return "notifications"
}
