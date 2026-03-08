package payment

import (
	"time"

	"github.com/google/uuid"
)

// ---------------------------------------------------------------------------
// Request DTOs
// ---------------------------------------------------------------------------

// CreatePaymentRequest is the payload for creating a new payment order.
type CreatePaymentRequest struct {
	PaymentType string    `json:"payment_type" validate:"required,oneof=order booking"`
	ReferenceID uuid.UUID `json:"reference_id" validate:"required"`
}

// VerifyPaymentRequest is the payload for verifying a Razorpay payment.
type VerifyPaymentRequest struct {
	RazorpayOrderID   string `json:"razorpay_order_id"   validate:"required"`
	RazorpayPaymentID string `json:"razorpay_payment_id" validate:"required"`
	RazorpaySignature string `json:"razorpay_signature"  validate:"required"`
}

// PayoutRequest is the payload for requesting a vendor payout.
type PayoutRequest struct {
	Amount float64 `json:"amount" validate:"required,gt=0"`
}

// ---------------------------------------------------------------------------
// Response DTOs
// ---------------------------------------------------------------------------

// PaymentResponse is the public representation of a payment.
type PaymentResponse struct {
	ID                uuid.UUID  `json:"id"`
	PaymentType       string     `json:"payment_type"`
	ReferenceID       uuid.UUID  `json:"reference_id"`
	CustomerID        uuid.UUID  `json:"customer_id"`
	VendorID          uuid.UUID  `json:"vendor_id"`
	Amount            float64    `json:"amount"`
	Currency          string     `json:"currency"`
	Status            string     `json:"status"`
	RazorpayOrderID   *string    `json:"razorpay_order_id,omitempty"`
	RazorpayPaymentID *string    `json:"razorpay_payment_id,omitempty"`
	Method            *string    `json:"method,omitempty"`
	ErrorCode         *string    `json:"error_code,omitempty"`
	ErrorDescription  *string    `json:"error_description,omitempty"`
	PaidAt            *time.Time `json:"paid_at,omitempty"`
	CreatedAt         time.Time  `json:"created_at"`
	UpdatedAt         time.Time  `json:"updated_at"`
}

// WalletResponse is the public representation of a wallet.
type WalletResponse struct {
	ID                uuid.UUID  `json:"id"`
	VendorID          *uuid.UUID `json:"vendor_id,omitempty"`
	DeliveryPartnerID *uuid.UUID `json:"delivery_partner_id,omitempty"`
	Balance           float64    `json:"balance"`
	TotalEarned       float64    `json:"total_earned"`
	TotalWithdrawn    float64    `json:"total_withdrawn"`
	CreatedAt         time.Time  `json:"created_at"`
	UpdatedAt         time.Time  `json:"updated_at"`
}

// WalletTransactionResponse is the public representation of a wallet transaction.
type WalletTransactionResponse struct {
	ID               uuid.UUID  `json:"id"`
	WalletID         uuid.UUID  `json:"wallet_id"`
	Type             string     `json:"type"`
	Amount           float64    `json:"amount"`
	BalanceAfter     float64    `json:"balance_after"`
	ReferenceType    *string    `json:"reference_type,omitempty"`
	ReferenceID      *uuid.UUID `json:"reference_id,omitempty"`
	Description      string     `json:"description"`
	RazorpayPayoutID *string    `json:"razorpay_payout_id,omitempty"`
	Status           string     `json:"status"`
	CreatedAt        time.Time  `json:"created_at"`
}

// ---------------------------------------------------------------------------
// Mapping helpers
// ---------------------------------------------------------------------------

// toPaymentResponse converts a Payment model to its public response DTO.
func toPaymentResponse(p *Payment) *PaymentResponse {
	return &PaymentResponse{
		ID:                p.ID,
		PaymentType:       p.PaymentType,
		ReferenceID:       p.ReferenceID,
		CustomerID:        p.CustomerID,
		VendorID:          p.VendorID,
		Amount:            p.Amount,
		Currency:          p.Currency,
		Status:            p.Status,
		RazorpayOrderID:   p.RazorpayOrderID,
		RazorpayPaymentID: p.RazorpayPaymentID,
		Method:            p.Method,
		ErrorCode:         p.ErrorCode,
		ErrorDescription:  p.ErrorDescription,
		PaidAt:            p.PaidAt,
		CreatedAt:         p.CreatedAt,
		UpdatedAt:         p.UpdatedAt,
	}
}

// toWalletResponse converts a Wallet model to its public response DTO.
func toWalletResponse(w *Wallet) *WalletResponse {
	return &WalletResponse{
		ID:                w.ID,
		VendorID:          w.VendorID,
		DeliveryPartnerID: w.DeliveryPartnerID,
		Balance:           w.Balance,
		TotalEarned:       w.TotalEarned,
		TotalWithdrawn:    w.TotalWithdrawn,
		CreatedAt:         w.CreatedAt,
		UpdatedAt:         w.UpdatedAt,
	}
}

// toWalletTransactionResponse converts a WalletTransaction model to its
// public response DTO.
func toWalletTransactionResponse(t *WalletTransaction) *WalletTransactionResponse {
	return &WalletTransactionResponse{
		ID:               t.ID,
		WalletID:         t.WalletID,
		Type:             t.Type,
		Amount:           t.Amount,
		BalanceAfter:     t.BalanceAfter,
		ReferenceType:    t.ReferenceType,
		ReferenceID:      t.ReferenceID,
		Description:      t.Description,
		RazorpayPayoutID: t.RazorpayPayoutID,
		Status:           t.Status,
		CreatedAt:        t.CreatedAt,
	}
}
