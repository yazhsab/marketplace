package order

import (
	"time"

	"github.com/google/uuid"
)

// Order represents a row in the orders table.
type Order struct {
	ID                  uuid.UUID    `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	OrderNumber         string       `gorm:"type:varchar(50);uniqueIndex;not null" json:"order_number"`
	CustomerID          uuid.UUID    `gorm:"type:uuid;not null;index" json:"customer_id"`
	VendorID            uuid.UUID    `gorm:"type:uuid;not null;index" json:"vendor_id"`
	AddressID           *uuid.UUID   `gorm:"type:uuid" json:"address_id,omitempty"`
	Status              string       `gorm:"type:varchar(30);not null;default:'pending'" json:"status"`
	Subtotal            float64      `gorm:"type:float8;not null;default:0" json:"subtotal"`
	DeliveryFee         float64      `gorm:"type:float8;not null;default:0" json:"delivery_fee"`
	Discount            float64      `gorm:"type:float8;not null;default:0" json:"discount"`
	Tax                 float64      `gorm:"type:float8;not null;default:0" json:"tax"`
	Total               float64      `gorm:"type:float8;not null;default:0" json:"total"`
	PaymentStatus       string       `gorm:"type:varchar(30);not null;default:'pending'" json:"payment_status"`
	Notes               *string      `gorm:"type:text" json:"notes,omitempty"`
	EstimatedDeliveryAt *time.Time   `json:"estimated_delivery_at,omitempty"`
	DeliveredAt         *time.Time   `json:"delivered_at,omitempty"`
	CancelledAt         *time.Time   `json:"cancelled_at,omitempty"`
	CancellationReason  *string      `gorm:"type:text" json:"cancellation_reason,omitempty"`
	DeliveryPartnerID   *uuid.UUID   `gorm:"type:uuid" json:"delivery_partner_id,omitempty"`
	CreatedAt           time.Time    `json:"created_at"`
	UpdatedAt           time.Time    `json:"updated_at"`
	Items               []OrderItem  `gorm:"foreignKey:OrderID" json:"items,omitempty"`
}

// TableName overrides the default GORM table name.
func (Order) TableName() string {
	return "orders"
}

// OrderItem represents a row in the order_items table.
type OrderItem struct {
	ID           uuid.UUID `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	OrderID      uuid.UUID `gorm:"type:uuid;not null;index" json:"order_id"`
	ProductID    uuid.UUID `gorm:"type:uuid;not null" json:"product_id"`
	ProductName  string    `gorm:"type:varchar(255);not null" json:"product_name"`
	ProductImage *string   `gorm:"type:varchar(500)" json:"product_image,omitempty"`
	Quantity     int       `gorm:"not null" json:"quantity"`
	UnitPrice    float64   `gorm:"type:float8;not null" json:"unit_price"`
	TotalPrice   float64   `gorm:"type:float8;not null" json:"total_price"`
	CreatedAt    time.Time `json:"created_at"`
}

// TableName overrides the default GORM table name.
func (OrderItem) TableName() string {
	return "order_items"
}
