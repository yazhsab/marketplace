package notification

import (
	"context"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
)

// NotificationRepository defines the data-access contract for the notification module.
type NotificationRepository interface {
	Create(ctx context.Context, notification *Notification) error
	ListByUser(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[Notification], error)
	MarkAsRead(ctx context.Context, id uuid.UUID) error
	MarkAllAsRead(ctx context.Context, userID uuid.UUID) error
	GetUnreadCount(ctx context.Context, userID uuid.UUID) (int64, error)
}

// notificationRepository is the GORM-backed implementation of NotificationRepository.
type notificationRepository struct {
	db *gorm.DB
}

// NewNotificationRepository returns a new NotificationRepository backed by the provided GORM DB.
func NewNotificationRepository(db *gorm.DB) NotificationRepository {
	return &notificationRepository{db: db}
}

// Create inserts a new notification into the database.
func (r *notificationRepository) Create(ctx context.Context, notification *Notification) error {
	if notification.ID == uuid.Nil {
		notification.ID = uuid.New()
	}
	notification.CreatedAt = time.Now()
	return r.db.WithContext(ctx).Create(notification).Error
}

// ListByUser returns a paginated list of notifications for a specific user,
// ordered by created_at descending (newest first).
func (r *notificationRepository) ListByUser(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[Notification], error) {
	query := r.db.WithContext(ctx).Model(&Notification{}).
		Where("user_id = ?", userID)

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var notifications []Notification
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&notifications).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Notification]{
		Items: notifications,
		Total: total,
	}, nil
}

// MarkAsRead sets is_read to true for a single notification.
func (r *notificationRepository) MarkAsRead(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).
		Model(&Notification{}).
		Where("id = ?", id).
		Update("is_read", true).Error
}

// MarkAllAsRead sets is_read to true for all notifications belonging to a user.
func (r *notificationRepository) MarkAllAsRead(ctx context.Context, userID uuid.UUID) error {
	return r.db.WithContext(ctx).
		Model(&Notification{}).
		Where("user_id = ? AND is_read = false", userID).
		Update("is_read", true).Error
}

// GetUnreadCount returns the number of unread notifications for a user.
func (r *notificationRepository) GetUnreadCount(ctx context.Context, userID uuid.UUID) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&Notification{}).
		Where("user_id = ? AND is_read = false", userID).
		Count(&count).Error
	return count, err
}
