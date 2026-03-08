package booking

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
)

// BookingRepository defines the data-access contract for the booking module.
type BookingRepository interface {
	// Service CRUD
	CreateService(ctx context.Context, svc *Service) error
	UpdateService(ctx context.Context, svc *Service) error
	DeleteService(ctx context.Context, id uuid.UUID) error
	GetService(ctx context.Context, id uuid.UUID) (*Service, error)
	ListServicesByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[Service], error)
	ListAllServices(ctx context.Context, params pagination.Params) (*pagination.Result[Service], error)
	ListServicesByCategory(ctx context.Context, categoryID uuid.UUID, params pagination.Params) (*pagination.Result[Service], error)

	// Slot CRUD
	CreateSlots(ctx context.Context, slots []ServiceSlot) error
	GetSlot(ctx context.Context, id uuid.UUID) (*ServiceSlot, error)
	ListSlots(ctx context.Context, serviceID uuid.UUID, startDate, endDate *time.Time) ([]ServiceSlot, error)
	UpdateSlot(ctx context.Context, slot *ServiceSlot) error
	DeleteSlot(ctx context.Context, id uuid.UUID) error
	ReserveSlot(ctx context.Context, tx *gorm.DB, slotID uuid.UUID) error
	ReleaseSlot(ctx context.Context, slotID uuid.UUID) error

	// Booking CRUD
	CreateBooking(ctx context.Context, booking *Booking) error
	FindByID(ctx context.Context, id uuid.UUID) (*Booking, error)
	ListByCustomer(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[Booking], error)
	ListByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[Booking], error)
	ListAll(ctx context.Context, params pagination.Params) (*pagination.Result[Booking], error)
	UpdateStatus(ctx context.Context, bookingID uuid.UUID, status string) error
	UpdatePaymentStatus(ctx context.Context, bookingID uuid.UUID, paymentStatus string) error

	// DB returns the underlying *gorm.DB for transaction support.
	DB() *gorm.DB
}

// bookingRepository is the GORM-backed implementation of BookingRepository.
type bookingRepository struct {
	db *gorm.DB
}

// NewBookingRepository returns a new BookingRepository backed by the provided GORM DB.
func NewBookingRepository(db *gorm.DB) BookingRepository {
	return &bookingRepository{db: db}
}

// DB returns the underlying *gorm.DB.
func (r *bookingRepository) DB() *gorm.DB {
	return r.db
}

// ---------------------------------------------------------------------------
// Service CRUD
// ---------------------------------------------------------------------------

// CreateService inserts a new service into the database.
func (r *bookingRepository) CreateService(ctx context.Context, svc *Service) error {
	if svc.ID == uuid.Nil {
		svc.ID = uuid.New()
	}
	now := time.Now()
	svc.CreatedAt = now
	svc.UpdatedAt = now
	return r.db.WithContext(ctx).Create(svc).Error
}

// UpdateService saves all fields of the service back to the database.
func (r *bookingRepository) UpdateService(ctx context.Context, svc *Service) error {
	svc.UpdatedAt = time.Now()
	return r.db.WithContext(ctx).Save(svc).Error
}

// DeleteService soft-deletes a service by its ID.
func (r *bookingRepository) DeleteService(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Where("id = ?", id).Delete(&Service{}).Error
}

// GetService retrieves a service by its primary key.
func (r *bookingRepository) GetService(ctx context.Context, id uuid.UUID) (*Service, error) {
	var svc Service
	if err := r.db.WithContext(ctx).Where("id = ?", id).First(&svc).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &svc, nil
}

// ListServicesByVendor returns a paginated list of services for a vendor.
func (r *bookingRepository) ListServicesByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[Service], error) {
	query := r.db.WithContext(ctx).Model(&Service{}).Where("vendor_id = ?", vendorID)

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var services []Service
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&services).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Service]{
		Items: services,
		Total: total,
	}, nil
}

// ListAllServices returns a paginated list of all active services.
func (r *bookingRepository) ListAllServices(ctx context.Context, params pagination.Params) (*pagination.Result[Service], error) {
	query := r.db.WithContext(ctx).Model(&Service{}).Where("is_active = true")

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var services []Service
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&services).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Service]{
		Items: services,
		Total: total,
	}, nil
}

// ListServicesByCategory returns a paginated list of active services in a category.
func (r *bookingRepository) ListServicesByCategory(ctx context.Context, categoryID uuid.UUID, params pagination.Params) (*pagination.Result[Service], error) {
	query := r.db.WithContext(ctx).Model(&Service{}).
		Where("category_id = ? AND is_active = true", categoryID)

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var services []Service
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&services).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Service]{
		Items: services,
		Total: total,
	}, nil
}

// ---------------------------------------------------------------------------
// Slot CRUD
// ---------------------------------------------------------------------------

// CreateSlots inserts a batch of service slots.
func (r *bookingRepository) CreateSlots(ctx context.Context, slots []ServiceSlot) error {
	now := time.Now()
	for i := range slots {
		if slots[i].ID == uuid.Nil {
			slots[i].ID = uuid.New()
		}
		slots[i].CreatedAt = now
	}
	return r.db.WithContext(ctx).Create(&slots).Error
}

// GetSlot retrieves a slot by its primary key.
func (r *bookingRepository) GetSlot(ctx context.Context, id uuid.UUID) (*ServiceSlot, error) {
	var slot ServiceSlot
	if err := r.db.WithContext(ctx).Where("id = ?", id).First(&slot).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &slot, nil
}

// ListSlots returns all slots for a service, optionally filtered by date range.
func (r *bookingRepository) ListSlots(ctx context.Context, serviceID uuid.UUID, startDate, endDate *time.Time) ([]ServiceSlot, error) {
	query := r.db.WithContext(ctx).Where("service_id = ?", serviceID)

	if startDate != nil {
		query = query.Where("slot_date >= ?", *startDate)
	}
	if endDate != nil {
		query = query.Where("slot_date <= ?", *endDate)
	}

	var slots []ServiceSlot
	if err := query.Order("slot_date ASC, start_time ASC").Find(&slots).Error; err != nil {
		return nil, err
	}
	return slots, nil
}

// UpdateSlot saves all fields of the slot back to the database.
func (r *bookingRepository) UpdateSlot(ctx context.Context, slot *ServiceSlot) error {
	return r.db.WithContext(ctx).Save(slot).Error
}

// DeleteSlot hard-deletes a slot by its ID.
func (r *bookingRepository) DeleteSlot(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Where("id = ?", id).Delete(&ServiceSlot{}).Error
}

// ReserveSlot atomically increments the booked_count of a slot using
// SELECT FOR UPDATE to prevent race conditions. It returns an error if
// the slot is full or not available.
func (r *bookingRepository) ReserveSlot(ctx context.Context, tx *gorm.DB, slotID uuid.UUID) error {
	var slot ServiceSlot
	if err := tx.WithContext(ctx).
		Clauses(clause.Locking{Strength: "UPDATE"}).
		Where("id = ?", slotID).
		First(&slot).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return fmt.Errorf("slot not found")
		}
		return err
	}

	if !slot.IsAvailable {
		return fmt.Errorf("slot is not available")
	}
	if slot.BookedCount >= slot.MaxBookings {
		return fmt.Errorf("slot is fully booked")
	}

	return tx.WithContext(ctx).
		Model(&ServiceSlot{}).
		Where("id = ?", slotID).
		Updates(map[string]interface{}{
			"booked_count": gorm.Expr("booked_count + 1"),
		}).Error
}

// ReleaseSlot decrements the booked_count of a slot.
func (r *bookingRepository) ReleaseSlot(ctx context.Context, slotID uuid.UUID) error {
	return r.db.WithContext(ctx).
		Model(&ServiceSlot{}).
		Where("id = ? AND booked_count > 0", slotID).
		Updates(map[string]interface{}{
			"booked_count": gorm.Expr("booked_count - 1"),
		}).Error
}

// ---------------------------------------------------------------------------
// Booking CRUD
// ---------------------------------------------------------------------------

// CreateBooking inserts a new booking into the database.
func (r *bookingRepository) CreateBooking(ctx context.Context, booking *Booking) error {
	if booking.ID == uuid.Nil {
		booking.ID = uuid.New()
	}
	now := time.Now()
	booking.CreatedAt = now
	booking.UpdatedAt = now
	return r.db.WithContext(ctx).Create(booking).Error
}

// FindByID retrieves a booking by its primary key.
func (r *bookingRepository) FindByID(ctx context.Context, id uuid.UUID) (*Booking, error) {
	var b Booking
	if err := r.db.WithContext(ctx).Where("id = ?", id).First(&b).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &b, nil
}

// ListByCustomer returns a paginated list of bookings for a customer.
func (r *bookingRepository) ListByCustomer(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[Booking], error) {
	query := r.db.WithContext(ctx).Model(&Booking{}).Where("customer_id = ?", customerID)

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var bookings []Booking
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&bookings).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Booking]{
		Items: bookings,
		Total: total,
	}, nil
}

// ListByVendor returns a paginated list of bookings for a vendor.
func (r *bookingRepository) ListByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[Booking], error) {
	query := r.db.WithContext(ctx).Model(&Booking{}).Where("vendor_id = ?", vendorID)

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var bookings []Booking
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&bookings).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Booking]{
		Items: bookings,
		Total: total,
	}, nil
}

// ListAll returns a paginated list of all bookings.
func (r *bookingRepository) ListAll(ctx context.Context, params pagination.Params) (*pagination.Result[Booking], error) {
	query := r.db.WithContext(ctx).Model(&Booking{})

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var bookings []Booking
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&bookings).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Booking]{
		Items: bookings,
		Total: total,
	}, nil
}

// UpdateStatus sets the status column for the given booking.
func (r *bookingRepository) UpdateStatus(ctx context.Context, bookingID uuid.UUID, status string) error {
	updates := map[string]interface{}{
		"status":     status,
		"updated_at": time.Now(),
	}

	if status == "active" {
		now := time.Now()
		updates["started_at"] = &now
	}
	if status == "completed" {
		now := time.Now()
		updates["completed_at"] = &now
	}
	if status == "cancelled" {
		now := time.Now()
		updates["cancelled_at"] = &now
	}

	return r.db.WithContext(ctx).
		Model(&Booking{}).
		Where("id = ?", bookingID).
		Updates(updates).Error
}

// UpdatePaymentStatus sets the payment_status column for the given booking.
func (r *bookingRepository) UpdatePaymentStatus(ctx context.Context, bookingID uuid.UUID, paymentStatus string) error {
	return r.db.WithContext(ctx).
		Model(&Booking{}).
		Where("id = ?", bookingID).
		Updates(map[string]interface{}{
			"payment_status": paymentStatus,
			"updated_at":     time.Now(),
		}).Error
}
