package review

import (
	"time"

	"github.com/google/uuid"
)

// ---------------------------------------------------------------------------
// Request DTOs
// ---------------------------------------------------------------------------

// CreateReviewRequest is the payload for creating a new review.
type CreateReviewRequest struct {
	VendorID    uuid.UUID  `json:"vendor_id"    validate:"required"`
	ReferenceID uuid.UUID  `json:"reference_id" validate:"required"`
	ReviewType  string     `json:"review_type"  validate:"required,oneof=product service vendor"`
	OrderID     *uuid.UUID `json:"order_id,omitempty"`
	Rating      int        `json:"rating"       validate:"required,min=1,max=5"`
	Title       *string    `json:"title,omitempty"`
	Comment     *string    `json:"comment,omitempty"`
	Images      []string   `json:"images,omitempty"`
}

// UpdateReviewRequest is the payload for updating an existing review.
type UpdateReviewRequest struct {
	Rating  *int      `json:"rating,omitempty"  validate:"omitempty,min=1,max=5"`
	Title   *string   `json:"title,omitempty"`
	Comment *string   `json:"comment,omitempty"`
	Images  *[]string `json:"images,omitempty"`
}

// VendorReplyRequest is the payload for a vendor replying to a review.
type VendorReplyRequest struct {
	Reply string `json:"reply" validate:"required"`
}

// ---------------------------------------------------------------------------
// Response DTOs
// ---------------------------------------------------------------------------

// ReviewResponse is the public representation of a review.
type ReviewResponse struct {
	ID              uuid.UUID  `json:"id"`
	CustomerID      uuid.UUID  `json:"customer_id"`
	VendorID        uuid.UUID  `json:"vendor_id"`
	ReviewType      string     `json:"review_type"`
	ReferenceID     uuid.UUID  `json:"reference_id"`
	OrderID         *uuid.UUID `json:"order_id,omitempty"`
	Rating          int        `json:"rating"`
	Title           *string    `json:"title,omitempty"`
	Comment         *string    `json:"comment,omitempty"`
	Images          []string   `json:"images,omitempty"`
	IsVerified      bool       `json:"is_verified"`
	VendorReply     *string    `json:"vendor_reply,omitempty"`
	VendorRepliedAt *time.Time `json:"vendor_replied_at,omitempty"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

// ---------------------------------------------------------------------------
// Mapping helpers
// ---------------------------------------------------------------------------

// toReviewResponse converts a Review model to its public response DTO.
func toReviewResponse(r *Review) ReviewResponse {
	return ReviewResponse{
		ID:              r.ID,
		CustomerID:      r.CustomerID,
		VendorID:        r.VendorID,
		ReviewType:      r.ReviewType,
		ReferenceID:     r.ReferenceID,
		OrderID:         r.OrderID,
		Rating:          r.Rating,
		Title:           r.Title,
		Comment:         r.Comment,
		Images:          r.Images,
		IsVerified:      r.IsVerified,
		VendorReply:     r.VendorReply,
		VendorRepliedAt: r.VendorRepliedAt,
		CreatedAt:       r.CreatedAt,
		UpdatedAt:       r.UpdatedAt,
	}
}
