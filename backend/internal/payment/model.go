package payment

import (
	"time"

	"github.com/google/uuid"
)

// Payment represents a row in the payments table.
type Payment struct {
	ID               uuid.UUID  `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	PaymentType      string     `gorm:"type:varchar(30);not null" json:"payment_type"`
	ReferenceID      uuid.UUID  `gorm:"type:uuid;not null" json:"reference_id"`
	CustomerID       uuid.UUID  `gorm:"type:uuid;not null;index" json:"customer_id"`
	VendorID         uuid.UUID  `gorm:"type:uuid;not null;index" json:"vendor_id"`
	Amount           float64    `gorm:"type:float8;not null" json:"amount"`
	Currency         string     `gorm:"type:varchar(10);not null;default:'INR'" json:"currency"`
	Status           string     `gorm:"type:varchar(30);not null;default:'created'" json:"status"`
	RazorpayOrderID  *string    `gorm:"type:varchar(255)" json:"razorpay_order_id,omitempty"`
	RazorpayPaymentID *string   `gorm:"type:varchar(255)" json:"razorpay_payment_id,omitempty"`
	RazorpaySignature *string   `gorm:"type:varchar(500)" json:"razorpay_signature,omitempty"`
	RefundID         *string    `gorm:"type:varchar(255)" json:"refund_id,omitempty"`
	RefundAmount     *float64   `gorm:"type:float8" json:"refund_amount,omitempty"`
	Method           *string    `gorm:"type:varchar(50)" json:"method,omitempty"`
	ErrorCode        *string    `gorm:"type:varchar(100)" json:"error_code,omitempty"`
	ErrorDescription *string    `gorm:"type:text" json:"error_description,omitempty"`
	PaidAt           *time.Time `json:"paid_at,omitempty"`
	CreatedAt        time.Time  `json:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at"`
}

// TableName overrides the default GORM table name.
func (Payment) TableName() string {
	return "payments"
}

// Wallet represents a row in the wallets table.
type Wallet struct {
	ID                uuid.UUID  `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	VendorID          *uuid.UUID `gorm:"type:uuid" json:"vendor_id,omitempty"`
	DeliveryPartnerID *uuid.UUID `gorm:"type:uuid" json:"delivery_partner_id,omitempty"`
	Balance           float64    `gorm:"type:float8;not null;default:0" json:"balance"`
	TotalEarned       float64    `gorm:"type:float8;not null;default:0" json:"total_earned"`
	TotalWithdrawn    float64    `gorm:"type:float8;not null;default:0" json:"total_withdrawn"`
	CreatedAt         time.Time  `json:"created_at"`
	UpdatedAt         time.Time  `json:"updated_at"`
}

// TableName overrides the default GORM table name.
func (Wallet) TableName() string {
	return "wallets"
}

// WalletTransaction represents a row in the wallet_transactions table.
type WalletTransaction struct {
	ID               uuid.UUID  `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	WalletID         uuid.UUID  `gorm:"type:uuid;not null;index" json:"wallet_id"`
	Type             string     `gorm:"type:varchar(30);not null" json:"type"`
	Amount           float64    `gorm:"type:float8;not null" json:"amount"`
	BalanceAfter     float64    `gorm:"type:float8;not null" json:"balance_after"`
	ReferenceType    *string    `gorm:"type:varchar(50)" json:"reference_type,omitempty"`
	ReferenceID      *uuid.UUID `gorm:"type:uuid" json:"reference_id,omitempty"`
	Description      string     `gorm:"type:text;not null" json:"description"`
	RazorpayPayoutID *string    `gorm:"type:varchar(255)" json:"razorpay_payout_id,omitempty"`
	Status           string     `gorm:"type:varchar(30);not null;default:'completed'" json:"status"`
	CreatedAt        time.Time  `json:"created_at"`
}

// TableName overrides the default GORM table name.
func (WalletTransaction) TableName() string {
	return "wallet_transactions"
}
