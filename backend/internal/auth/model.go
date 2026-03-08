package auth

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// User represents a row in the users table.
type User struct {
	ID           uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	Phone        *string        `gorm:"type:varchar(15);uniqueIndex:idx_users_phone_active,where:deleted_at IS NULL" json:"phone,omitempty"`
	Email        *string        `gorm:"type:varchar(255);uniqueIndex:idx_users_email_active,where:deleted_at IS NULL" json:"email,omitempty"`
	PasswordHash string         `gorm:"type:varchar(255)" json:"-"`
	FullName     string         `gorm:"type:varchar(255);not null" json:"full_name"`
	AvatarURL    *string        `gorm:"type:varchar(500)" json:"avatar_url,omitempty"`
	Role         string         `gorm:"type:varchar(20);not null;default:customer" json:"role"`
	IsActive     bool           `gorm:"default:true" json:"is_active"`
	FCMToken     *string        `gorm:"type:varchar(500)" json:"-"`
	LastLoginAt  *time.Time     `json:"last_login_at,omitempty"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

// TableName overrides the default GORM table name.
func (User) TableName() string {
	return "users"
}
