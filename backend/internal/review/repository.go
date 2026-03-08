package review

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"

	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
)

// ReviewRepository defines the data-access contract for the review module.
type ReviewRepository interface {
	Create(ctx context.Context, review *Review) error
	Update(ctx context.Context, review *Review) error
	Delete(ctx context.Context, id uuid.UUID) error
	FindByID(ctx context.Context, id uuid.UUID) (*Review, error)
	ListByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[Review], error)
	ListByProduct(ctx context.Context, referenceID uuid.UUID, params pagination.Params) (*pagination.Result[Review], error)
	ListByService(ctx context.Context, referenceID uuid.UUID, params pagination.Params) (*pagination.Result[Review], error)
	ListByCustomer(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[Review], error)
	ListAll(ctx context.Context, params pagination.Params) (*pagination.Result[Review], error)
	UpdateVendorReply(ctx context.Context, id uuid.UUID, reply string) error
	GetAverageRating(ctx context.Context, reviewType string, referenceID uuid.UUID) (float64, int, error)
}

// reviewRepository is the GORM-backed implementation of ReviewRepository.
type reviewRepository struct {
	db *gorm.DB
}

// NewReviewRepository returns a new ReviewRepository backed by the provided GORM DB.
func NewReviewRepository(db *gorm.DB) ReviewRepository {
	return &reviewRepository{db: db}
}

// Create inserts a new review into the database.
func (r *reviewRepository) Create(ctx context.Context, review *Review) error {
	if review.ID == uuid.Nil {
		review.ID = uuid.New()
	}
	now := time.Now()
	review.CreatedAt = now
	review.UpdatedAt = now
	return r.db.WithContext(ctx).Create(review).Error
}

// Update saves all fields of the review back to the database.
func (r *reviewRepository) Update(ctx context.Context, review *Review) error {
	review.UpdatedAt = time.Now()
	return r.db.WithContext(ctx).Save(review).Error
}

// Delete soft-deletes a review by its ID.
func (r *reviewRepository) Delete(ctx context.Context, id uuid.UUID) error {
	return r.db.WithContext(ctx).Where("id = ?", id).Delete(&Review{}).Error
}

// FindByID retrieves a review by its primary key.
func (r *reviewRepository) FindByID(ctx context.Context, id uuid.UUID) (*Review, error) {
	var rev Review
	if err := r.db.WithContext(ctx).Where("id = ?", id).First(&rev).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &rev, nil
}

// ListByVendor returns a paginated list of reviews for a specific vendor
// (review_type = 'vendor').
func (r *reviewRepository) ListByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[Review], error) {
	query := r.db.WithContext(ctx).Model(&Review{}).
		Where("vendor_id = ? AND review_type = ?", vendorID, "vendor")

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var reviews []Review
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&reviews).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Review]{
		Items: reviews,
		Total: total,
	}, nil
}

// ListByProduct returns a paginated list of reviews where review_type = 'product'
// and reference_id matches.
func (r *reviewRepository) ListByProduct(ctx context.Context, referenceID uuid.UUID, params pagination.Params) (*pagination.Result[Review], error) {
	query := r.db.WithContext(ctx).Model(&Review{}).
		Where("reference_id = ? AND review_type = ?", referenceID, "product")

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var reviews []Review
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&reviews).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Review]{
		Items: reviews,
		Total: total,
	}, nil
}

// ListByService returns a paginated list of reviews where review_type = 'service'
// and reference_id matches.
func (r *reviewRepository) ListByService(ctx context.Context, referenceID uuid.UUID, params pagination.Params) (*pagination.Result[Review], error) {
	query := r.db.WithContext(ctx).Model(&Review{}).
		Where("reference_id = ? AND review_type = ?", referenceID, "service")

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var reviews []Review
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&reviews).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Review]{
		Items: reviews,
		Total: total,
	}, nil
}

// ListByCustomer returns a paginated list of reviews authored by a specific customer.
func (r *reviewRepository) ListByCustomer(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[Review], error) {
	query := r.db.WithContext(ctx).Model(&Review{}).
		Where("customer_id = ?", customerID)

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var reviews []Review
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&reviews).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Review]{
		Items: reviews,
		Total: total,
	}, nil
}

// ListAll returns a paginated list of all reviews (for admin use).
func (r *reviewRepository) ListAll(ctx context.Context, params pagination.Params) (*pagination.Result[Review], error) {
	query := r.db.WithContext(ctx).Model(&Review{})

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, err
	}

	var reviews []Review
	if err := query.
		Order("created_at DESC").
		Offset(params.Offset()).
		Limit(params.PerPage).
		Find(&reviews).Error; err != nil {
		return nil, err
	}

	return &pagination.Result[Review]{
		Items: reviews,
		Total: total,
	}, nil
}

// UpdateVendorReply sets the vendor_reply and vendor_replied_at fields.
func (r *reviewRepository) UpdateVendorReply(ctx context.Context, id uuid.UUID, reply string) error {
	now := time.Now()
	return r.db.WithContext(ctx).
		Model(&Review{}).
		Where("id = ?", id).
		Updates(map[string]interface{}{
			"vendor_reply":     reply,
			"vendor_replied_at": now,
			"updated_at":       now,
		}).Error
}

// GetAverageRating computes the average rating and total count for a given
// review type and reference ID.
func (r *reviewRepository) GetAverageRating(ctx context.Context, reviewType string, referenceID uuid.UUID) (float64, int, error) {
	var result struct {
		Avg   float64
		Count int
	}

	err := r.db.WithContext(ctx).
		Model(&Review{}).
		Select("COALESCE(AVG(rating), 0) as avg, COUNT(*) as count").
		Where("review_type = ? AND reference_id = ?", reviewType, referenceID).
		Scan(&result).Error
	if err != nil {
		return 0, 0, err
	}

	return result.Avg, result.Count, nil
}
