package vendor

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
)

// VendorRepository defines the data-access contract for the vendor module.
type VendorRepository interface {
	Create(ctx context.Context, vendor *Vendor) error
	Update(ctx context.Context, vendor *Vendor) error
	FindByID(ctx context.Context, id uuid.UUID) (*Vendor, error)
	FindByUserID(ctx context.Context, userID uuid.UUID) (*Vendor, error)
	ListAll(ctx context.Context, params pagination.Params, status, city string) (*pagination.Result[Vendor], error)
	FindNearby(ctx context.Context, lat, lng, radiusKM float64, params pagination.Params) (*pagination.Result[Vendor], error)
	UpdateStatus(ctx context.Context, id uuid.UUID, status string) error
	UpdateOnlineStatus(ctx context.Context, id uuid.UUID, isOnline bool) error
	UpdateCommission(ctx context.Context, id uuid.UUID, pct float64) error
	CreateDocument(ctx context.Context, doc *VendorDocument) error
	ListDocuments(ctx context.Context, vendorID uuid.UUID) ([]VendorDocument, error)
	GetDocument(ctx context.Context, docID uuid.UUID) (*VendorDocument, error)
	UpdateDocumentStatus(ctx context.Context, docID uuid.UUID, status string, rejectionNote *string, verifiedBy uuid.UUID) error
	DeleteDocument(ctx context.Context, docID uuid.UUID) error
}

// vendorRepository is the GORM-backed implementation of VendorRepository.
type vendorRepository struct {
	db *gorm.DB
}

// NewVendorRepository returns a new VendorRepository backed by the provided GORM DB.
func NewVendorRepository(db *gorm.DB) VendorRepository {
	return &vendorRepository{db: db}
}

// Create inserts a new vendor using raw SQL so that PostGIS ST_MakePoint is used
// to store the geographic location.
func (r *vendorRepository) Create(ctx context.Context, vendor *Vendor) error {
	if vendor.ID == uuid.Nil {
		vendor.ID = uuid.New()
	}
	now := time.Now()
	vendor.CreatedAt = now
	vendor.UpdatedAt = now

	sql := `INSERT INTO vendors (
		id, user_id, business_name, description, logo_url, banner_url,
		vendor_type, status, latitude, longitude, location,
		address, city, state, pincode,
		service_radius_km, avg_rating, total_reviews, commission_pct,
		is_online, created_at, updated_at
	) VALUES (
		?, ?, ?, ?, ?, ?,
		?, ?, ?, ?, ST_SetSRID(ST_MakePoint(?, ?), 4326),
		?, ?, ?, ?,
		?, ?, ?, ?,
		?, ?, ?
	)`

	return r.db.WithContext(ctx).Exec(sql,
		vendor.ID, vendor.UserID, vendor.BusinessName, vendor.Description, vendor.LogoURL, vendor.BannerURL,
		vendor.VendorType, vendor.Status, vendor.Latitude, vendor.Longitude,
		vendor.Longitude, vendor.Latitude, // ST_MakePoint(lng, lat)
		vendor.Address, vendor.City, vendor.State, vendor.Pincode,
		vendor.ServiceRadiusKM, vendor.AvgRating, vendor.TotalReviews, vendor.CommissionPct,
		vendor.IsOnline, vendor.CreatedAt, vendor.UpdatedAt,
	).Error
}

// Update saves all fields of the vendor back to the database.
func (r *vendorRepository) Update(ctx context.Context, vendor *Vendor) error {
	vendor.UpdatedAt = time.Now()
	return r.db.WithContext(ctx).Save(vendor).Error
}

// FindByID retrieves a vendor by its primary key.
func (r *vendorRepository) FindByID(ctx context.Context, id uuid.UUID) (*Vendor, error) {
	var v Vendor
	if err := r.db.WithContext(ctx).Where("id = ?", id).First(&v).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &v, nil
}

// FindByUserID retrieves the vendor profile associated with a given user.
func (r *vendorRepository) FindByUserID(ctx context.Context, userID uuid.UUID) (*Vendor, error) {
	var v Vendor
	if err := r.db.WithContext(ctx).Where("user_id = ?", userID).First(&v).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &v, nil
}

// ListAll returns a paginated list of vendors, optionally filtered by status
// and/or city.
func (r *vendorRepository) ListAll(ctx context.Context, params pagination.Params, status, city string) (*pagination.Result[Vendor], error) {
	query := r.db.WithContext(ctx).Model(&Vendor{})

	if status != "" {
		query = query.Where("status = ?", status)
	}
	if city != "" {
		query = query.Where("city = ?", city)
	}

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var vendors []Vendor
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&vendors).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Vendor]{
		Items: vendors,
		Total: total,
	}, nil
}

// FindNearby returns vendors within radiusKM of the given point, ordered by
// distance (nearest first). Uses PostGIS ST_DWithin for the spatial filter and
// ST_Distance for ordering.
func (r *vendorRepository) FindNearby(ctx context.Context, lat, lng, radiusKM float64, params pagination.Params) (*pagination.Result[Vendor], error) {
	radiusMeters := radiusKM * 1000

	// Count matching rows.
	var total int64
	countSQL := `SELECT COUNT(*) FROM vendors
		WHERE deleted_at IS NULL
		  AND status = 'approved'
		  AND is_online = true
		  AND ST_DWithin(
		    location,
		    ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
		    ?
		  )`
	if err := r.db.WithContext(ctx).Raw(countSQL, lng, lat, radiusMeters).Scan(&total).Error; err != nil {
		return nil, err
	}

	// Fetch the current page ordered by distance.
	var vendors []Vendor
	dataSQL := `SELECT * FROM vendors
		WHERE deleted_at IS NULL
		  AND status = 'approved'
		  AND is_online = true
		  AND ST_DWithin(
		    location,
		    ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
		    ?
		  )
		ORDER BY ST_Distance(
		  location,
		  ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography
		)
		LIMIT ? OFFSET ?`
	if err := r.db.WithContext(ctx).Raw(dataSQL, lng, lat, radiusMeters, lng, lat, params.PerPage, params.Offset()).Scan(&vendors).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Vendor]{
		Items: vendors,
		Total: total,
	}, nil
}

// UpdateStatus sets the status column for the given vendor.
func (r *vendorRepository) UpdateStatus(ctx context.Context, id uuid.UUID, status string) error {
	return r.db.WithContext(ctx).
		Model(&Vendor{}).
		Where("id = ?", id).
		Updates(map[string]interface{}{
			"status":     status,
			"updated_at": time.Now(),
		}).Error
}

// UpdateOnlineStatus sets the is_online column for the given vendor.
func (r *vendorRepository) UpdateOnlineStatus(ctx context.Context, id uuid.UUID, isOnline bool) error {
	return r.db.WithContext(ctx).
		Model(&Vendor{}).
		Where("id = ?", id).
		Updates(map[string]interface{}{
			"is_online":  isOnline,
			"updated_at": time.Now(),
		}).Error
}

// UpdateCommission sets the commission_pct column for the given vendor.
func (r *vendorRepository) UpdateCommission(ctx context.Context, id uuid.UUID, pct float64) error {
	return r.db.WithContext(ctx).
		Model(&Vendor{}).
		Where("id = ?", id).
		Updates(map[string]interface{}{
			"commission_pct": pct,
			"updated_at":     time.Now(),
		}).Error
}

// CreateDocument inserts a new vendor document.
func (r *vendorRepository) CreateDocument(ctx context.Context, doc *VendorDocument) error {
	if doc.ID == uuid.Nil {
		doc.ID = uuid.New()
	}
	now := time.Now()
	doc.CreatedAt = now
	doc.UpdatedAt = now
	return r.db.WithContext(ctx).Create(doc).Error
}

// ListDocuments returns all documents belonging to a vendor.
func (r *vendorRepository) ListDocuments(ctx context.Context, vendorID uuid.UUID) ([]VendorDocument, error) {
	var docs []VendorDocument
	if err := r.db.WithContext(ctx).
		Where("vendor_id = ?", vendorID).
		Order("created_at DESC").
		Find(&docs).Error; err != nil {
		return nil, err
	}
	return docs, nil
}

// GetDocument retrieves a single document by its ID.
func (r *vendorRepository) GetDocument(ctx context.Context, docID uuid.UUID) (*VendorDocument, error) {
	var doc VendorDocument
	if err := r.db.WithContext(ctx).Where("id = ?", docID).First(&doc).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &doc, nil
}

// UpdateDocumentStatus sets the status, optional rejection note, verifier and
// timestamp on a document.
func (r *vendorRepository) UpdateDocumentStatus(ctx context.Context, docID uuid.UUID, status string, rejectionNote *string, verifiedBy uuid.UUID) error {
	now := time.Now()
	updates := map[string]interface{}{
		"status":      status,
		"verified_by": verifiedBy,
		"verified_at": now,
		"updated_at":  now,
	}
	if rejectionNote != nil {
		updates["rejection_note"] = *rejectionNote
	}

	return r.db.WithContext(ctx).
		Model(&VendorDocument{}).
		Where("id = ?", docID).
		Updates(updates).Error
}

// DeleteDocument hard-deletes a document by its ID.
func (r *vendorRepository) DeleteDocument(ctx context.Context, docID uuid.UUID) error {
	return r.db.WithContext(ctx).Where("id = ?", docID).Delete(&VendorDocument{}).Error
}
