package types

import "math"

// ---------------------------------------------------------------------------
// GeoPoint
// ---------------------------------------------------------------------------

// GeoPoint represents a geographic coordinate (latitude/longitude pair).
type GeoPoint struct {
	Lat float64 `json:"lat" validate:"required,gte=-90,lte=90"`
	Lng float64 `json:"lng" validate:"required,gte=-180,lte=180"`
}

// ---------------------------------------------------------------------------
// Money
// ---------------------------------------------------------------------------

// Money represents a monetary value in the smallest currency unit
// (e.g., paise for INR, cents for USD). Using an integer avoids
// floating-point rounding issues in financial calculations.
type Money int64

// ToFloat converts the integer representation to a human-readable float
// (e.g., 1050 paise -> 10.50).
func (m Money) ToFloat() float64 {
	return float64(m) / 100
}

// MoneyFromFloat converts a floating-point amount (e.g., 10.50) to its
// smallest-unit integer representation (e.g., 1050). It rounds to the
// nearest integer to avoid truncation errors.
func MoneyFromFloat(amount float64) Money {
	return Money(math.Round(amount * 100))
}

// ---------------------------------------------------------------------------
// OrderStatus
// ---------------------------------------------------------------------------

// OrderStatus represents the lifecycle state of an order.
type OrderStatus string

const (
	OrderStatusPending    OrderStatus = "pending"
	OrderStatusConfirmed  OrderStatus = "confirmed"
	OrderStatusProcessing OrderStatus = "processing"
	OrderStatusShipped    OrderStatus = "shipped"
	OrderStatusDelivered  OrderStatus = "delivered"
	OrderStatusCancelled  OrderStatus = "cancelled"
	OrderStatusRefunded   OrderStatus = "refunded"
)

// IsValid reports whether the status is one of the known order statuses.
func (s OrderStatus) IsValid() bool {
	switch s {
	case OrderStatusPending, OrderStatusConfirmed, OrderStatusProcessing,
		OrderStatusShipped, OrderStatusDelivered, OrderStatusCancelled,
		OrderStatusRefunded:
		return true
	}
	return false
}

// String implements the Stringer interface.
func (s OrderStatus) String() string {
	return string(s)
}

// ---------------------------------------------------------------------------
// BookingStatus
// ---------------------------------------------------------------------------

// BookingStatus represents the lifecycle state of a booking.
type BookingStatus string

const (
	BookingStatusPending   BookingStatus = "pending"
	BookingStatusConfirmed BookingStatus = "confirmed"
	BookingStatusActive    BookingStatus = "active"
	BookingStatusCompleted BookingStatus = "completed"
	BookingStatusCancelled BookingStatus = "cancelled"
	BookingStatusExpired   BookingStatus = "expired"
)

// IsValid reports whether the status is one of the known booking statuses.
func (s BookingStatus) IsValid() bool {
	switch s {
	case BookingStatusPending, BookingStatusConfirmed, BookingStatusActive,
		BookingStatusCompleted, BookingStatusCancelled, BookingStatusExpired:
		return true
	}
	return false
}

// String implements the Stringer interface.
func (s BookingStatus) String() string {
	return string(s)
}

// ---------------------------------------------------------------------------
// VendorStatus
// ---------------------------------------------------------------------------

// VendorStatus represents the approval state of a vendor account.
type VendorStatus string

const (
	VendorStatusPending  VendorStatus = "pending"
	VendorStatusApproved VendorStatus = "approved"
	VendorStatusRejected VendorStatus = "rejected"
	VendorStatusSuspended VendorStatus = "suspended"
	VendorStatusInactive VendorStatus = "inactive"
)

// IsValid reports whether the status is one of the known vendor statuses.
func (s VendorStatus) IsValid() bool {
	switch s {
	case VendorStatusPending, VendorStatusApproved, VendorStatusRejected,
		VendorStatusSuspended, VendorStatusInactive:
		return true
	}
	return false
}

// String implements the Stringer interface.
func (s VendorStatus) String() string {
	return string(s)
}

// ---------------------------------------------------------------------------
// PaymentStatus
// ---------------------------------------------------------------------------

// PaymentStatus represents the state of a payment transaction.
type PaymentStatus string

const (
	PaymentStatusPending   PaymentStatus = "pending"
	PaymentStatusCompleted PaymentStatus = "completed"
	PaymentStatusFailed    PaymentStatus = "failed"
	PaymentStatusRefunded  PaymentStatus = "refunded"
	PaymentStatusCancelled PaymentStatus = "cancelled"
)

// IsValid reports whether the status is one of the known payment statuses.
func (s PaymentStatus) IsValid() bool {
	switch s {
	case PaymentStatusPending, PaymentStatusCompleted, PaymentStatusFailed,
		PaymentStatusRefunded, PaymentStatusCancelled:
		return true
	}
	return false
}

// String implements the Stringer interface.
func (s PaymentStatus) String() string {
	return string(s)
}
