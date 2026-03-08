package order

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
)

// OrderRepository defines the data-access contract for the order module.
type OrderRepository interface {
	Create(ctx context.Context, order *Order) error
	FindByID(ctx context.Context, id uuid.UUID) (*Order, error)
	ListByCustomer(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[Order], error)
	ListByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params, statusFilter *string) (*pagination.Result[Order], error)
	ListAll(ctx context.Context, params pagination.Params, statusFilter *string) (*pagination.Result[Order], error)
	UpdateStatus(ctx context.Context, orderID uuid.UUID, status string) error
	UpdatePaymentStatus(ctx context.Context, orderID uuid.UUID, paymentStatus string) error
	UpdateDeliveryPartner(ctx context.Context, orderID uuid.UUID, deliveryPartnerID uuid.UUID) error
}

// orderRepository is the GORM-backed implementation of OrderRepository.
type orderRepository struct {
	db *gorm.DB
}

// NewOrderRepository returns a new OrderRepository backed by the provided GORM DB.
func NewOrderRepository(db *gorm.DB) OrderRepository {
	return &orderRepository{db: db}
}

// Create inserts a new order and its items into the database.
func (r *orderRepository) Create(ctx context.Context, order *Order) error {
	if order.ID == uuid.Nil {
		order.ID = uuid.New()
	}
	now := time.Now()
	order.CreatedAt = now
	order.UpdatedAt = now

	for i := range order.Items {
		if order.Items[i].ID == uuid.Nil {
			order.Items[i].ID = uuid.New()
		}
		order.Items[i].OrderID = order.ID
		order.Items[i].CreatedAt = now
	}

	return r.db.WithContext(ctx).Create(order).Error
}

// FindByID retrieves an order by its primary key, preloading its items.
func (r *orderRepository) FindByID(ctx context.Context, id uuid.UUID) (*Order, error) {
	var o Order
	if err := r.db.WithContext(ctx).
		Preload("Items").
		Where("id = ?", id).
		First(&o).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &o, nil
}

// ListByCustomer returns a paginated list of orders for a customer,
// ordered by creation date descending.
func (r *orderRepository) ListByCustomer(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[Order], error) {
	query := r.db.WithContext(ctx).Model(&Order{}).Where("customer_id = ?", customerID)

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var orders []Order
	if err := query.
		Preload("Items").
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&orders).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Order]{
		Items: orders,
		Total: total,
	}, nil
}

// ListByVendor returns a paginated list of orders for a vendor,
// optionally filtered by status.
func (r *orderRepository) ListByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params, statusFilter *string) (*pagination.Result[Order], error) {
	query := r.db.WithContext(ctx).Model(&Order{}).Where("vendor_id = ?", vendorID)

	if statusFilter != nil && *statusFilter != "" {
		query = query.Where("status = ?", *statusFilter)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var orders []Order
	if err := query.
		Preload("Items").
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&orders).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Order]{
		Items: orders,
		Total: total,
	}, nil
}

// ListAll returns a paginated list of all orders, optionally filtered by status.
func (r *orderRepository) ListAll(ctx context.Context, params pagination.Params, statusFilter *string) (*pagination.Result[Order], error) {
	query := r.db.WithContext(ctx).Model(&Order{})

	if statusFilter != nil && *statusFilter != "" {
		query = query.Where("status = ?", *statusFilter)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var orders []Order
	if err := query.
		Preload("Items").
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&orders).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Order]{
		Items: orders,
		Total: total,
	}, nil
}

// UpdateStatus sets the status column for the given order.
func (r *orderRepository) UpdateStatus(ctx context.Context, orderID uuid.UUID, status string) error {
	updates := map[string]interface{}{
		"status":     status,
		"updated_at": time.Now(),
	}

	if status == "delivered" {
		now := time.Now()
		updates["delivered_at"] = &now
	}
	if status == "cancelled" {
		now := time.Now()
		updates["cancelled_at"] = &now
	}

	return r.db.WithContext(ctx).
		Model(&Order{}).
		Where("id = ?", orderID).
		Updates(updates).Error
}

// UpdateDeliveryPartner sets the delivery_partner_id column for the given order.
func (r *orderRepository) UpdateDeliveryPartner(ctx context.Context, orderID uuid.UUID, deliveryPartnerID uuid.UUID) error {
	return r.db.WithContext(ctx).
		Model(&Order{}).
		Where("id = ?", orderID).
		Updates(map[string]interface{}{
			"delivery_partner_id": deliveryPartnerID,
			"updated_at":         time.Now(),
		}).Error
}

// UpdatePaymentStatus sets the payment_status column for the given order.
func (r *orderRepository) UpdatePaymentStatus(ctx context.Context, orderID uuid.UUID, paymentStatus string) error {
	return r.db.WithContext(ctx).
		Model(&Order{}).
		Where("id = ?", orderID).
		Updates(map[string]interface{}{
			"payment_status": paymentStatus,
			"updated_at":     time.Now(),
		}).Error
}
