package notification

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// ---------------------------------------------------------------------------
// Response DTOs
// ---------------------------------------------------------------------------

// NotificationResponse is the public representation of a notification.
type NotificationResponse struct {
	ID        uuid.UUID              `json:"id"`
	UserID    uuid.UUID              `json:"user_id"`
	Title     string                 `json:"title"`
	Body      string                 `json:"body"`
	Type      string                 `json:"type"`
	Data      map[string]interface{} `json:"data,omitempty"`
	IsRead    bool                   `json:"is_read"`
	SentVia   []string               `json:"sent_via"`
	CreatedAt time.Time              `json:"created_at"`
}

// ---------------------------------------------------------------------------
// Request DTOs
// ---------------------------------------------------------------------------

// SendNotificationRequest is the internal payload for sending a notification
// to a single user.
type SendNotificationRequest struct {
	UserID *uuid.UUID             `json:"user_id,omitempty"`
	Title  string                 `json:"title"  validate:"required"`
	Body   string                 `json:"body"   validate:"required"`
	Type   string                 `json:"type"   validate:"required"`
	Data   map[string]interface{} `json:"data,omitempty"`
}

// AdminSendNotificationRequest is the payload for admin-initiated notifications,
// which may target specific users or users matching a role.
type AdminSendNotificationRequest struct {
	Title   string      `json:"title"    validate:"required"`
	Body    string      `json:"body"     validate:"required"`
	Type    string      `json:"type,omitempty"`
	UserIDs []uuid.UUID `json:"user_ids,omitempty"`
	Role    *string     `json:"role,omitempty"`
}

// ---------------------------------------------------------------------------
// Mapping helpers
// ---------------------------------------------------------------------------

// toNotificationResponse converts a Notification model to its public response DTO.
func toNotificationResponse(n *Notification) NotificationResponse {
	var data map[string]interface{}
	if n.Data != nil {
		// Best-effort unmarshal; ignore errors.
		_ = json.Unmarshal([]byte(n.Data), &data)
	}

	return NotificationResponse{
		ID:        n.ID,
		UserID:    n.UserID,
		Title:     n.Title,
		Body:      n.Body,
		Type:      n.Type,
		Data:      data,
		IsRead:    n.IsRead,
		SentVia:   n.SentVia,
		CreatedAt: n.CreatedAt,
	}
}
