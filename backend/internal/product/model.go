package product

import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

// Category represents a row in the categories table.
type Category struct {
	ID           uuid.UUID   `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	Name         string      `gorm:"type:varchar(255);not null" json:"name"`
	Slug         string      `gorm:"type:varchar(255);uniqueIndex;not null" json:"slug"`
	Description  *string     `gorm:"type:text" json:"description,omitempty"`
	ImageURL     *string     `gorm:"type:varchar(500)" json:"image_url,omitempty"`
	ParentID     *uuid.UUID  `gorm:"type:uuid;index" json:"parent_id,omitempty"`
	SortOrder    int         `gorm:"default:0" json:"sort_order"`
	IsActive     bool        `gorm:"default:true" json:"is_active"`
	CategoryType string      `gorm:"type:varchar(50);not null;default:'product'" json:"category_type"`
	CreatedAt    time.Time   `json:"created_at"`
	UpdatedAt    time.Time   `json:"updated_at"`
	Children     []Category  `gorm:"foreignKey:ParentID" json:"children,omitempty"`
}

// TableName overrides the default GORM table name.
func (Category) TableName() string {
	return "categories"
}

// Product represents a row in the products table.
type Product struct {
	ID                uuid.UUID      `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	VendorID          uuid.UUID      `gorm:"type:uuid;not null;index" json:"vendor_id"`
	CategoryID        uuid.UUID      `gorm:"type:uuid;not null;index" json:"category_id"`
	Name              string         `gorm:"type:varchar(255);not null" json:"name"`
	Slug              string         `gorm:"type:varchar(255);uniqueIndex;not null" json:"slug"`
	Description       *string        `gorm:"type:text" json:"description,omitempty"`
	Price             float64        `gorm:"type:float8;not null" json:"price"`
	ComparePrice      *float64       `gorm:"type:float8" json:"compare_price,omitempty"`
	Unit              string         `gorm:"type:varchar(50);not null;default:'piece'" json:"unit"`
	SKU               *string        `gorm:"type:varchar(100)" json:"sku,omitempty"`
	Images            pq.StringArray `gorm:"type:text[]" json:"images,omitempty"`
	IsActive          bool           `gorm:"default:true" json:"is_active"`
	AvgRating         float64        `gorm:"type:float8;default:0" json:"avg_rating"`
	TotalReviews      int            `gorm:"default:0" json:"total_reviews"`
	StockQuantity     int            `gorm:"not null;default:0" json:"stock_quantity"`
	LowStockThreshold int            `gorm:"not null;default:5" json:"low_stock_threshold"`
	WeightGrams       *int           `json:"weight_grams,omitempty"`
	Tags              pq.StringArray `gorm:"type:text[]" json:"tags,omitempty"`
	CreatedAt         time.Time      `json:"created_at"`
	UpdatedAt         time.Time      `json:"updated_at"`
	DeletedAt         gorm.DeletedAt `gorm:"index" json:"-"`
	Category          Category       `gorm:"foreignKey:CategoryID" json:"category,omitempty"`
}

// TableName overrides the default GORM table name.
func (Product) TableName() string {
	return "products"
}
