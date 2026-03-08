package delivery

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
)

// DeliveryRepository defines the data-access contract for the delivery module.
type DeliveryRepository interface {
	// Partner CRUD
	Create(ctx context.Context, partner *DeliveryPartner) error
	Update(ctx context.Context, partner *DeliveryPartner) error
	FindByID(ctx context.Context, id uuid.UUID) (*DeliveryPartner, error)
	FindByUserID(ctx context.Context, userID uuid.UUID) (*DeliveryPartner, error)
	ListAll(ctx context.Context, params pagination.Params, status string) (*pagination.Result[DeliveryPartner], error)
	UpdateStatus(ctx context.Context, id uuid.UUID, status string) error
	UpdateAvailability(ctx context.Context, id uuid.UUID, isAvailable bool) error
	UpdateShift(ctx context.Context, id uuid.UUID, isOnShift bool) error
	UpdateLocation(ctx context.Context, id uuid.UUID, lat, lng float64) error
	SetCurrentOrder(ctx context.Context, id uuid.UUID, orderID *uuid.UUID) (int64, error)
	IncrementStats(ctx context.Context, id uuid.UUID, earnings float64) error

	// Geo queries
	FindNearbyAvailable(ctx context.Context, lat, lng, radiusKM float64, limit int) ([]DeliveryPartner, error)

	// Assignment CRUD
	CreateAssignment(ctx context.Context, assignment *DeliveryAssignment) error
	FindAssignmentByID(ctx context.Context, id uuid.UUID) (*DeliveryAssignment, error)
	UpdateAssignment(ctx context.Context, assignment *DeliveryAssignment) error
	ListAssignmentsByPartner(ctx context.Context, partnerID uuid.UUID, params pagination.Params, statusFilter *string) (*pagination.Result[DeliveryAssignment], error)
	ListAssignmentsByOrder(ctx context.Context, orderID uuid.UUID) ([]DeliveryAssignment, error)
	ListAllAssignments(ctx context.Context, params pagination.Params, statusFilter *string) (*pagination.Result[DeliveryAssignment], error)
	GetActiveAssignmentByPartner(ctx context.Context, partnerID uuid.UUID) (*DeliveryAssignment, error)

	// Earnings queries
	GetEarningsSummary(ctx context.Context, partnerID uuid.UUID) (*EarningsResponse, error)
	GetEarningsHistory(ctx context.Context, partnerID uuid.UUID, params pagination.Params) (*pagination.Result[DeliveryAssignment], error)
	GetPartnerStats(ctx context.Context, partnerID uuid.UUID) (*StatsResponse, error)
}

// deliveryRepository is the GORM-backed implementation of DeliveryRepository.
type deliveryRepository struct {
	db *gorm.DB
}

// NewDeliveryRepository returns a new DeliveryRepository backed by the provided GORM DB.
func NewDeliveryRepository(db *gorm.DB) DeliveryRepository {
	return &deliveryRepository{db: db}
}

// ---------------------------------------------------------------------------
// Partner CRUD
// ---------------------------------------------------------------------------

// Create inserts a new delivery partner using raw SQL for PostGIS location.
func (r *deliveryRepository) Create(ctx context.Context, partner *DeliveryPartner) error {
	if partner.ID == uuid.Nil {
		partner.ID = uuid.New()
	}
	now := time.Now()
	partner.CreatedAt = now
	partner.UpdatedAt = now

	sql := `INSERT INTO delivery_partners (
		id, user_id, vehicle_type, vehicle_number, license_number,
		status, current_latitude, current_longitude, location,
		is_available, is_on_shift, zone_preference,
		avg_rating, total_deliveries, total_earnings, commission_pct,
		created_at, updated_at
	) VALUES (
		?, ?, ?, ?, ?,
		?, ?, ?, ST_SetSRID(ST_MakePoint(?, ?), 4326),
		?, ?, ?,
		?, ?, ?, ?,
		?, ?
	)`

	return r.db.WithContext(ctx).Exec(sql,
		partner.ID, partner.UserID, partner.VehicleType, partner.VehicleNumber, partner.LicenseNumber,
		partner.Status, partner.CurrentLatitude, partner.CurrentLongitude,
		partner.CurrentLongitude, partner.CurrentLatitude,
		partner.IsAvailable, partner.IsOnShift, partner.ZonePreference,
		partner.AvgRating, partner.TotalDeliveries, partner.TotalEarnings, partner.CommissionPct,
		partner.CreatedAt, partner.UpdatedAt,
	).Error
}

// Update saves modified partner fields back to the database.
func (r *deliveryRepository) Update(ctx context.Context, partner *DeliveryPartner) error {
	partner.UpdatedAt = time.Now()
	return r.db.WithContext(ctx).Save(partner).Error
}

// FindByID retrieves a delivery partner by its primary key.
func (r *deliveryRepository) FindByID(ctx context.Context, id uuid.UUID) (*DeliveryPartner, error) {
	var dp DeliveryPartner
	if err := r.db.WithContext(ctx).Where("id = ? AND deleted_at IS NULL", id).First(&dp).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &dp, nil
}

// FindByUserID retrieves a delivery partner by user ID.
func (r *deliveryRepository) FindByUserID(ctx context.Context, userID uuid.UUID) (*DeliveryPartner, error) {
	var dp DeliveryPartner
	if err := r.db.WithContext(ctx).Where("user_id = ? AND deleted_at IS NULL", userID).First(&dp).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &dp, nil
}

// ListAll returns a paginated list of delivery partners, optionally filtered by status.
func (r *deliveryRepository) ListAll(ctx context.Context, params pagination.Params, status string) (*pagination.Result[DeliveryPartner], error) {
	query := r.db.WithContext(ctx).Model(&DeliveryPartner{})

	if status != "" {
		query = query.Where("status = ?", status)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var partners []DeliveryPartner
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&partners).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[DeliveryPartner]{
		Items: partners,
		Total: total,
	}, nil
}

// UpdateStatus sets the status column for the given delivery partner.
func (r *deliveryRepository) UpdateStatus(ctx context.Context, id uuid.UUID, status string) error {
	return r.db.WithContext(ctx).
		Model(&DeliveryPartner{}).
		Where("id = ? AND deleted_at IS NULL", id).
		Updates(map[string]interface{}{
			"status":     status,
			"updated_at": time.Now(),
		}).Error
}

// UpdateAvailability toggles the is_available flag.
func (r *deliveryRepository) UpdateAvailability(ctx context.Context, id uuid.UUID, isAvailable bool) error {
	return r.db.WithContext(ctx).
		Model(&DeliveryPartner{}).
		Where("id = ? AND deleted_at IS NULL", id).
		Updates(map[string]interface{}{
			"is_available": isAvailable,
			"updated_at":   time.Now(),
		}).Error
}

// UpdateShift toggles the is_on_shift flag.
func (r *deliveryRepository) UpdateShift(ctx context.Context, id uuid.UUID, isOnShift bool) error {
	return r.db.WithContext(ctx).
		Model(&DeliveryPartner{}).
		Where("id = ? AND deleted_at IS NULL", id).
		Updates(map[string]interface{}{
			"is_on_shift": isOnShift,
			"updated_at":  time.Now(),
		}).Error
}

// UpdateLocation updates the GPS coordinates and PostGIS location column.
func (r *deliveryRepository) UpdateLocation(ctx context.Context, id uuid.UUID, lat, lng float64) error {
	sql := `UPDATE delivery_partners
		SET current_latitude = ?,
			current_longitude = ?,
			location = ST_SetSRID(ST_MakePoint(?, ?), 4326),
			updated_at = NOW()
		WHERE id = ? AND deleted_at IS NULL`
	return r.db.WithContext(ctx).Exec(sql, lat, lng, lng, lat, id).Error
}

// SetCurrentOrder sets the current_order_id for a delivery partner.
// When orderID is non-nil, it uses an optimistic lock (current_order_id IS NULL)
// to prevent double-assignment. Returns the number of rows affected.
func (r *deliveryRepository) SetCurrentOrder(ctx context.Context, id uuid.UUID, orderID *uuid.UUID) (int64, error) {
	updates := map[string]interface{}{
		"updated_at": time.Now(),
	}
	query := r.db.WithContext(ctx).Model(&DeliveryPartner{}).Where("id = ? AND deleted_at IS NULL", id)

	if orderID != nil {
		// Optimistic lock: only set if currently null
		query = query.Where("current_order_id IS NULL")
		updates["current_order_id"] = orderID
	} else {
		updates["current_order_id"] = nil
	}

	result := query.Updates(updates)
	return result.RowsAffected, result.Error
}

// IncrementStats increments total_deliveries and total_earnings.
func (r *deliveryRepository) IncrementStats(ctx context.Context, id uuid.UUID, earnings float64) error {
	return r.db.WithContext(ctx).
		Model(&DeliveryPartner{}).
		Where("id = ? AND deleted_at IS NULL", id).
		Updates(map[string]interface{}{
			"total_deliveries": gorm.Expr("total_deliveries + 1"),
			"total_earnings":   gorm.Expr("total_earnings + ?", earnings),
			"updated_at":       time.Now(),
		}).Error
}

// ---------------------------------------------------------------------------
// Geo queries
// ---------------------------------------------------------------------------

// FindNearbyAvailable finds available, on-shift, approved delivery partners
// within the given radius, ordered by distance.
func (r *deliveryRepository) FindNearbyAvailable(ctx context.Context, lat, lng, radiusKM float64, limit int) ([]DeliveryPartner, error) {
	radiusMeters := radiusKM * 1000
	var partners []DeliveryPartner
	sql := `SELECT * FROM delivery_partners
		WHERE deleted_at IS NULL
		  AND status = 'approved'
		  AND is_available = true
		  AND is_on_shift = true
		  AND current_order_id IS NULL
		  AND ST_DWithin(
			location,
			ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
			?
		  )
		ORDER BY ST_Distance(
		  location,
		  ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography
		)
		LIMIT ?`
	if err := r.db.WithContext(ctx).Raw(sql, lng, lat, radiusMeters, lng, lat, limit).Scan(&partners).Error; err != nil {
		return nil, err
	}
	return partners, nil
}

// ---------------------------------------------------------------------------
// Assignment CRUD
// ---------------------------------------------------------------------------

// CreateAssignment inserts a new delivery assignment.
func (r *deliveryRepository) CreateAssignment(ctx context.Context, assignment *DeliveryAssignment) error {
	if assignment.ID == uuid.Nil {
		assignment.ID = uuid.New()
	}
	assignment.CreatedAt = time.Now()
	if assignment.AssignedAt.IsZero() {
		assignment.AssignedAt = assignment.CreatedAt
	}
	return r.db.WithContext(ctx).Create(assignment).Error
}

// FindAssignmentByID retrieves a delivery assignment by its primary key.
func (r *deliveryRepository) FindAssignmentByID(ctx context.Context, id uuid.UUID) (*DeliveryAssignment, error) {
	var a DeliveryAssignment
	if err := r.db.WithContext(ctx).Where("id = ?", id).First(&a).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &a, nil
}

// UpdateAssignment saves modified assignment fields.
func (r *deliveryRepository) UpdateAssignment(ctx context.Context, assignment *DeliveryAssignment) error {
	return r.db.WithContext(ctx).Save(assignment).Error
}

// ListAssignmentsByPartner returns a paginated list of assignments for a partner.
func (r *deliveryRepository) ListAssignmentsByPartner(ctx context.Context, partnerID uuid.UUID, params pagination.Params, statusFilter *string) (*pagination.Result[DeliveryAssignment], error) {
	query := r.db.WithContext(ctx).Model(&DeliveryAssignment{}).Where("delivery_partner_id = ?", partnerID)

	if statusFilter != nil && *statusFilter != "" {
		query = query.Where("status = ?", *statusFilter)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var assignments []DeliveryAssignment
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&assignments).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[DeliveryAssignment]{
		Items: assignments,
		Total: total,
	}, nil
}

// ListAssignmentsByOrder returns all assignments for an order.
func (r *deliveryRepository) ListAssignmentsByOrder(ctx context.Context, orderID uuid.UUID) ([]DeliveryAssignment, error) {
	var assignments []DeliveryAssignment
	if err := r.db.WithContext(ctx).
		Where("order_id = ?", orderID).
		Order("created_at DESC").
		Find(&assignments).Error; err != nil {
		return nil, err
	}
	return assignments, nil
}

// ListAllAssignments returns a paginated list of all assignments.
func (r *deliveryRepository) ListAllAssignments(ctx context.Context, params pagination.Params, statusFilter *string) (*pagination.Result[DeliveryAssignment], error) {
	query := r.db.WithContext(ctx).Model(&DeliveryAssignment{})

	if statusFilter != nil && *statusFilter != "" {
		query = query.Where("status = ?", *statusFilter)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var assignments []DeliveryAssignment
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&assignments).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[DeliveryAssignment]{
		Items: assignments,
		Total: total,
	}, nil
}

// GetActiveAssignmentByPartner returns the active (non-terminal) assignment for a partner.
func (r *deliveryRepository) GetActiveAssignmentByPartner(ctx context.Context, partnerID uuid.UUID) (*DeliveryAssignment, error) {
	var a DeliveryAssignment
	if err := r.db.WithContext(ctx).
		Where("delivery_partner_id = ? AND status IN ('assigned', 'accepted', 'picked_up')", partnerID).
		Order("created_at DESC").
		First(&a).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &a, nil
}

// ---------------------------------------------------------------------------
// Earnings & Stats queries
// ---------------------------------------------------------------------------

// GetEarningsSummary returns an earnings summary for a delivery partner.
func (r *deliveryRepository) GetEarningsSummary(ctx context.Context, partnerID uuid.UUID) (*EarningsResponse, error) {
	partner, err := r.FindByID(ctx, partnerID)
	if err != nil || partner == nil {
		return nil, err
	}

	var todayEarnings float64
	var todayCount int64
	today := time.Now().Format("2006-01-02")
	r.db.WithContext(ctx).Model(&DeliveryAssignment{}).
		Where("delivery_partner_id = ? AND status = 'delivered' AND DATE(delivered_at) = ?", partnerID, today).
		Count(&todayCount)
	r.db.WithContext(ctx).Model(&DeliveryAssignment{}).
		Select("COALESCE(SUM(earnings), 0)").
		Where("delivery_partner_id = ? AND status = 'delivered' AND DATE(delivered_at) = ?", partnerID, today).
		Scan(&todayEarnings)

	var weekEarnings float64
	var weekCount int64
	weekAgo := time.Now().AddDate(0, 0, -7).Format("2006-01-02")
	r.db.WithContext(ctx).Model(&DeliveryAssignment{}).
		Where("delivery_partner_id = ? AND status = 'delivered' AND DATE(delivered_at) >= ?", partnerID, weekAgo).
		Count(&weekCount)
	r.db.WithContext(ctx).Model(&DeliveryAssignment{}).
		Select("COALESCE(SUM(earnings), 0)").
		Where("delivery_partner_id = ? AND status = 'delivered' AND DATE(delivered_at) >= ?", partnerID, weekAgo).
		Scan(&weekEarnings)

	return &EarningsResponse{
		TotalEarnings:   partner.TotalEarnings,
		TotalDeliveries: partner.TotalDeliveries,
		TodayEarnings:   todayEarnings,
		TodayDeliveries: int(todayCount),
		WeekEarnings:    weekEarnings,
		WeekDeliveries:  int(weekCount),
		CommissionPct:   partner.CommissionPct,
	}, nil
}

// GetEarningsHistory returns a paginated list of delivered assignments (earnings history).
func (r *deliveryRepository) GetEarningsHistory(ctx context.Context, partnerID uuid.UUID, params pagination.Params) (*pagination.Result[DeliveryAssignment], error) {
	query := r.db.WithContext(ctx).Model(&DeliveryAssignment{}).
		Where("delivery_partner_id = ? AND status = 'delivered'", partnerID)

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var assignments []DeliveryAssignment
	if err := query.
		Order("delivered_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&assignments).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[DeliveryAssignment]{
		Items: assignments,
		Total: total,
	}, nil
}

// GetPartnerStats returns performance stats for a delivery partner.
func (r *deliveryRepository) GetPartnerStats(ctx context.Context, partnerID uuid.UUID) (*StatsResponse, error) {
	partner, err := r.FindByID(ctx, partnerID)
	if err != nil || partner == nil {
		return nil, err
	}

	var totalAssignments int64
	r.db.WithContext(ctx).Model(&DeliveryAssignment{}).
		Where("delivery_partner_id = ?", partnerID).
		Count(&totalAssignments)

	var acceptedCount int64
	r.db.WithContext(ctx).Model(&DeliveryAssignment{}).
		Where("delivery_partner_id = ? AND status != 'rejected'", partnerID).
		Count(&acceptedCount)

	var acceptanceRate float64
	if totalAssignments > 0 {
		acceptanceRate = float64(acceptedCount) / float64(totalAssignments) * 100
	}

	var avgDeliveryTimeMin float64
	r.db.WithContext(ctx).Model(&DeliveryAssignment{}).
		Select("COALESCE(AVG(EXTRACT(EPOCH FROM (delivered_at - accepted_at)) / 60), 0)").
		Where("delivery_partner_id = ? AND status = 'delivered' AND delivered_at IS NOT NULL AND accepted_at IS NOT NULL", partnerID).
		Scan(&avgDeliveryTimeMin)

	today := time.Now().Format("2006-01-02")
	var todayDeliveries int64
	r.db.WithContext(ctx).Model(&DeliveryAssignment{}).
		Where("delivery_partner_id = ? AND status = 'delivered' AND DATE(delivered_at) = ?", partnerID, today).
		Count(&todayDeliveries)

	return &StatsResponse{
		TotalDeliveries:    partner.TotalDeliveries,
		AvgRating:          partner.AvgRating,
		AcceptanceRate:     acceptanceRate,
		AvgDeliveryTimeMin: avgDeliveryTimeMin,
		TotalEarnings:      partner.TotalEarnings,
		TodayDeliveries:    int(todayDeliveries),
	}, nil
}
