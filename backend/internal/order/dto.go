package order

import (
	"fmt"
	"math/rand"
	"time"

	"github.com/google/uuid"
)

// ---------------------------------------------------------------------------
// Request DTOs
// ---------------------------------------------------------------------------

// CreateOrderRequest is the payload for creating a new order.
type CreateOrderRequest struct {
	VendorID    uuid.UUID          `json:"vendor_id"    validate:"required"`
	AddressID   *uuid.UUID         `json:"address_id,omitempty"`
	Items       []OrderItemRequest `json:"items"        validate:"required,min=1,dive"`
	Notes       *string            `json:"notes,omitempty"`
	DeliveryFee *float64           `json:"delivery_fee,omitempty"`
}

// OrderItemRequest represents a single item in a create-order request.
type OrderItemRequest struct {
	ProductID uuid.UUID `json:"product_id" validate:"required"`
	Quantity  int       `json:"quantity"   validate:"required,gt=0"`
}

// UpdateOrderStatusRequest is the payload for updating an order's status.
type UpdateOrderStatusRequest struct {
	Status string `json:"status" validate:"required"`
}

// ---------------------------------------------------------------------------
// Response DTOs
// ---------------------------------------------------------------------------

// OrderResponse is the public representation of an order.
type OrderResponse struct {
	ID                  uuid.UUID           `json:"id"`
	OrderNumber         string              `json:"order_number"`
	CustomerID          uuid.UUID           `json:"customer_id"`
	VendorID            uuid.UUID           `json:"vendor_id"`
	AddressID           *uuid.UUID          `json:"address_id,omitempty"`
	Status              string              `json:"status"`
	Subtotal            float64             `json:"subtotal"`
	DeliveryFee         float64             `json:"delivery_fee"`
	Discount            float64             `json:"discount"`
	Tax                 float64             `json:"tax"`
	Total               float64             `json:"total"`
	PaymentStatus       string              `json:"payment_status"`
	Notes               *string             `json:"notes,omitempty"`
	EstimatedDeliveryAt *time.Time          `json:"estimated_delivery_at,omitempty"`
	DeliveredAt         *time.Time          `json:"delivered_at,omitempty"`
	CancelledAt         *time.Time          `json:"cancelled_at,omitempty"`
	CancellationReason  *string             `json:"cancellation_reason,omitempty"`
	DeliveryPartnerID   *uuid.UUID          `json:"delivery_partner_id,omitempty"`
	CreatedAt           time.Time           `json:"created_at"`
	UpdatedAt           time.Time           `json:"updated_at"`
	Items               []OrderItemResponse `json:"items,omitempty"`
}

// OrderItemResponse is the public representation of an order item.
type OrderItemResponse struct {
	ID           uuid.UUID `json:"id"`
	OrderID      uuid.UUID `json:"order_id"`
	ProductID    uuid.UUID `json:"product_id"`
	ProductName  string    `json:"product_name"`
	ProductImage *string   `json:"product_image,omitempty"`
	Quantity     int       `json:"quantity"`
	UnitPrice    float64   `json:"unit_price"`
	TotalPrice   float64   `json:"total_price"`
	CreatedAt    time.Time `json:"created_at"`
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// GenerateOrderNumber creates a unique order number in the format
// ORD-YYYYMMDD-XXXX where XXXX is a random 4-character alphanumeric string.
func GenerateOrderNumber() string {
	const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	suffix := make([]byte, 4)
	for i := range suffix {
		suffix[i] = charset[rand.Intn(len(charset))]
	}
	return fmt.Sprintf("ORD-%s-%s", time.Now().Format("20060102"), string(suffix))
}

// toOrderResponse converts an Order model to its public response DTO.
func toOrderResponse(o *Order) *OrderResponse {
	resp := &OrderResponse{
		ID:                  o.ID,
		OrderNumber:         o.OrderNumber,
		CustomerID:          o.CustomerID,
		VendorID:            o.VendorID,
		AddressID:           o.AddressID,
		Status:              o.Status,
		Subtotal:            o.Subtotal,
		DeliveryFee:         o.DeliveryFee,
		Discount:            o.Discount,
		Tax:                 o.Tax,
		Total:               o.Total,
		PaymentStatus:       o.PaymentStatus,
		Notes:               o.Notes,
		EstimatedDeliveryAt: o.EstimatedDeliveryAt,
		DeliveredAt:         o.DeliveredAt,
		CancelledAt:         o.CancelledAt,
		CancellationReason:  o.CancellationReason,
		DeliveryPartnerID:   o.DeliveryPartnerID,
		CreatedAt:           o.CreatedAt,
		UpdatedAt:           o.UpdatedAt,
	}

	if len(o.Items) > 0 {
		resp.Items = make([]OrderItemResponse, len(o.Items))
		for i := range o.Items {
			resp.Items[i] = toOrderItemResponse(&o.Items[i])
		}
	}

	return resp
}

// toOrderItemResponse converts an OrderItem model to its public response DTO.
func toOrderItemResponse(item *OrderItem) OrderItemResponse {
	return OrderItemResponse{
		ID:           item.ID,
		OrderID:      item.OrderID,
		ProductID:    item.ProductID,
		ProductName:  item.ProductName,
		ProductImage: item.ProductImage,
		Quantity:     item.Quantity,
		UnitPrice:    item.UnitPrice,
		TotalPrice:   item.TotalPrice,
		CreatedAt:    item.CreatedAt,
	}
}
