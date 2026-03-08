package notification

import (
	"context"
	"encoding/json"
	"log"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/datatypes"

	"github.com/prabakarankannan/marketplace-backend/internal/auth"
	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/pkg/firebase"
)

// NotificationService defines the business-logic contract for the notification module.
type NotificationService interface {
	SendNotification(ctx context.Context, userID uuid.UUID, title, body, notifType string, data map[string]string) error
	ListNotifications(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[NotificationResponse], error)
	MarkAsRead(ctx context.Context, userID uuid.UUID, notifID uuid.UUID) error
	MarkAllAsRead(ctx context.Context, userID uuid.UUID) error
	GetUnreadCount(ctx context.Context, userID uuid.UUID) (int64, error)
	AdminSendNotification(ctx context.Context, req AdminSendNotificationRequest) error
}

// notificationService is the concrete implementation of NotificationService.
type notificationService struct {
	repo     NotificationRepository
	firebase *firebase.FirebaseService
	authRepo auth.AuthRepository
}

// NewNotificationService returns a new NotificationService with all required dependencies.
func NewNotificationService(
	repo NotificationRepository,
	firebase *firebase.FirebaseService,
	authRepo auth.AuthRepository,
) NotificationService {
	return &notificationService{
		repo:     repo,
		firebase: firebase,
		authRepo: authRepo,
	}
}

// SendNotification creates a notification record in the database and sends an
// FCM push notification to the user's device (if they have an FCM token).
func (s *notificationService) SendNotification(ctx context.Context, userID uuid.UUID, title, body, notifType string, data map[string]string) error {
	// Marshal data to JSON for storage.
	var jsonData datatypes.JSON
	if data != nil {
		b, err := json.Marshal(data)
		if err != nil {
			return apperrors.Internal("failed to marshal notification data")
		}
		jsonData = datatypes.JSON(b)
	}

	notif := Notification{
		ID:      uuid.New(),
		UserID:  userID,
		Title:   title,
		Body:    body,
		Type:    notifType,
		Data:    jsonData,
		IsRead:  false,
		SentVia: pq.StringArray{"push"},
	}

	if err := s.repo.Create(ctx, &notif); err != nil {
		return apperrors.Internal("failed to create notification")
	}

	// Send FCM push notification (best-effort).
	go func() {
		user, err := s.authRepo.FindByID(ctx, userID)
		if err != nil || user == nil {
			log.Printf("[Notification] failed to look up user %s for push: %v", userID, err)
			return
		}
		if user.FCMToken == nil || *user.FCMToken == "" {
			return
		}

		if err := s.firebase.SendPushNotification(ctx, *user.FCMToken, title, body, data); err != nil {
			log.Printf("[Notification] failed to send push to user %s: %v", userID, err)
		}
	}()

	return nil
}

// ListNotifications returns a paginated list of notifications for a user.
func (s *notificationService) ListNotifications(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[NotificationResponse], error) {
	result, err := s.repo.ListByUser(ctx, userID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list notifications")
	}

	return toNotificationResultResponse(result), nil
}

// MarkAsRead marks a single notification as read.
func (s *notificationService) MarkAsRead(ctx context.Context, userID uuid.UUID, notifID uuid.UUID) error {
	if err := s.repo.MarkAsRead(ctx, notifID); err != nil {
		return apperrors.Internal("failed to mark notification as read")
	}
	return nil
}

// MarkAllAsRead marks all notifications for a user as read.
func (s *notificationService) MarkAllAsRead(ctx context.Context, userID uuid.UUID) error {
	if err := s.repo.MarkAllAsRead(ctx, userID); err != nil {
		return apperrors.Internal("failed to mark all notifications as read")
	}
	return nil
}

// GetUnreadCount returns the number of unread notifications for a user.
func (s *notificationService) GetUnreadCount(ctx context.Context, userID uuid.UUID) (int64, error) {
	count, err := s.repo.GetUnreadCount(ctx, userID)
	if err != nil {
		return 0, apperrors.Internal("failed to get unread count")
	}
	return count, nil
}

// AdminSendNotification sends notifications to the specified users or all users
// matching a role.
func (s *notificationService) AdminSendNotification(ctx context.Context, req AdminSendNotificationRequest) error {
	notifType := req.Type
	if notifType == "" {
		notifType = "admin"
	}

	for _, userID := range req.UserIDs {
		if err := s.SendNotification(ctx, userID, req.Title, req.Body, notifType, nil); err != nil {
			log.Printf("[Notification] failed to send admin notification to user %s: %v", userID, err)
		}
	}

	// NOTE: If Role is specified, additional logic to look up users by role
	// and send to each would be added here. For now we only support explicit
	// user IDs.

	return nil
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// toNotificationResultResponse converts a pagination.Result[Notification] to
// pagination.Result[NotificationResponse].
func toNotificationResultResponse(result *pagination.Result[Notification]) *pagination.Result[NotificationResponse] {
	responses := make([]NotificationResponse, len(result.Items))
	for i := range result.Items {
		responses[i] = toNotificationResponse(&result.Items[i])
	}
	return &pagination.Result[NotificationResponse]{
		Items: responses,
		Total: result.Total,
	}
}
