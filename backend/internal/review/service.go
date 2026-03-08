package review

import (
	"context"

	"github.com/google/uuid"
	"github.com/lib/pq"

	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/internal/vendor"
)

// ReviewService defines the business-logic contract for the review module.
type ReviewService interface {
	CreateReview(ctx context.Context, customerID uuid.UUID, req CreateReviewRequest) (*ReviewResponse, error)
	UpdateReview(ctx context.Context, customerID uuid.UUID, reviewID uuid.UUID, req UpdateReviewRequest) error
	DeleteReview(ctx context.Context, customerID uuid.UUID, reviewID uuid.UUID) error
	GetReview(ctx context.Context, reviewID uuid.UUID) (*ReviewResponse, error)
	ListReviewsForProduct(ctx context.Context, productID uuid.UUID, params pagination.Params) (*pagination.Result[ReviewResponse], error)
	ListReviewsForService(ctx context.Context, serviceID uuid.UUID, params pagination.Params) (*pagination.Result[ReviewResponse], error)
	ListReviewsForVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[ReviewResponse], error)
	ListMyReviews(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[ReviewResponse], error)
	VendorReplyToReview(ctx context.Context, userID uuid.UUID, reviewID uuid.UUID, req VendorReplyRequest) error
	AdminDeleteReview(ctx context.Context, reviewID uuid.UUID) error
	AdminListReviews(ctx context.Context, params pagination.Params) (*pagination.Result[ReviewResponse], error)
}

// reviewService is the concrete implementation of ReviewService.
type reviewService struct {
	repo       ReviewRepository
	vendorRepo vendor.VendorRepository
}

// NewReviewService returns a new ReviewService with all required dependencies.
func NewReviewService(
	repo ReviewRepository,
	vendorRepo vendor.VendorRepository,
) ReviewService {
	return &reviewService{
		repo:       repo,
		vendorRepo: vendorRepo,
	}
}

// CreateReview creates a new review for a product, service, or vendor.
func (s *reviewService) CreateReview(ctx context.Context, customerID uuid.UUID, req CreateReviewRequest) (*ReviewResponse, error) {
	rev := Review{
		ID:          uuid.New(),
		CustomerID:  customerID,
		VendorID:    req.VendorID,
		ReviewType:  req.ReviewType,
		ReferenceID: req.ReferenceID,
		OrderID:     req.OrderID,
		Rating:      req.Rating,
		Title:       req.Title,
		Comment:     req.Comment,
		Images:      pq.StringArray(req.Images),
		IsVerified:  false,
	}

	if err := s.repo.Create(ctx, &rev); err != nil {
		return nil, apperrors.Internal("failed to create review")
	}

	// TODO: After create, recalculate average rating for the referenced
	// product/service/vendor using GetAverageRating and update the record.

	resp := toReviewResponse(&rev)
	return &resp, nil
}

// UpdateReview applies partial updates to an existing review after verifying
// that the caller is the review author.
func (s *reviewService) UpdateReview(ctx context.Context, customerID uuid.UUID, reviewID uuid.UUID, req UpdateReviewRequest) error {
	rev, err := s.repo.FindByID(ctx, reviewID)
	if err != nil {
		return apperrors.Internal("failed to find review")
	}
	if rev == nil {
		return apperrors.NotFound("review not found")
	}
	if rev.CustomerID != customerID {
		return apperrors.Forbidden("you can only update your own reviews")
	}

	if req.Rating != nil {
		rev.Rating = *req.Rating
	}
	if req.Title != nil {
		rev.Title = req.Title
	}
	if req.Comment != nil {
		rev.Comment = req.Comment
	}
	if req.Images != nil {
		rev.Images = pq.StringArray(*req.Images)
	}

	if err := s.repo.Update(ctx, rev); err != nil {
		return apperrors.Internal("failed to update review")
	}

	// TODO: After update, recalculate average rating for the referenced
	// product/service/vendor using GetAverageRating and update the record.

	return nil
}

// DeleteReview soft-deletes a review after verifying that the caller is the
// review author.
func (s *reviewService) DeleteReview(ctx context.Context, customerID uuid.UUID, reviewID uuid.UUID) error {
	rev, err := s.repo.FindByID(ctx, reviewID)
	if err != nil {
		return apperrors.Internal("failed to find review")
	}
	if rev == nil {
		return apperrors.NotFound("review not found")
	}
	if rev.CustomerID != customerID {
		return apperrors.Forbidden("you can only delete your own reviews")
	}

	if err := s.repo.Delete(ctx, reviewID); err != nil {
		return apperrors.Internal("failed to delete review")
	}

	return nil
}

// GetReview retrieves a single review by ID.
func (s *reviewService) GetReview(ctx context.Context, reviewID uuid.UUID) (*ReviewResponse, error) {
	rev, err := s.repo.FindByID(ctx, reviewID)
	if err != nil {
		return nil, apperrors.Internal("failed to find review")
	}
	if rev == nil {
		return nil, apperrors.NotFound("review not found")
	}

	resp := toReviewResponse(rev)
	return &resp, nil
}

// ListReviewsForProduct returns a paginated list of product reviews.
func (s *reviewService) ListReviewsForProduct(ctx context.Context, productID uuid.UUID, params pagination.Params) (*pagination.Result[ReviewResponse], error) {
	result, err := s.repo.ListByProduct(ctx, productID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list product reviews")
	}

	return toReviewResultResponse(result), nil
}

// ListReviewsForService returns a paginated list of service reviews.
func (s *reviewService) ListReviewsForService(ctx context.Context, serviceID uuid.UUID, params pagination.Params) (*pagination.Result[ReviewResponse], error) {
	result, err := s.repo.ListByService(ctx, serviceID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list service reviews")
	}

	return toReviewResultResponse(result), nil
}

// ListReviewsForVendor returns a paginated list of vendor reviews.
func (s *reviewService) ListReviewsForVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[ReviewResponse], error) {
	result, err := s.repo.ListByVendor(ctx, vendorID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list vendor reviews")
	}

	return toReviewResultResponse(result), nil
}

// ListMyReviews returns a paginated list of reviews authored by the given customer.
func (s *reviewService) ListMyReviews(ctx context.Context, customerID uuid.UUID, params pagination.Params) (*pagination.Result[ReviewResponse], error) {
	result, err := s.repo.ListByCustomer(ctx, customerID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list my reviews")
	}

	return toReviewResultResponse(result), nil
}

// VendorReplyToReview allows a vendor to reply to a review that targets their
// vendor profile. Verifies the caller owns the vendor being reviewed.
func (s *reviewService) VendorReplyToReview(ctx context.Context, userID uuid.UUID, reviewID uuid.UUID, req VendorReplyRequest) error {
	rev, err := s.repo.FindByID(ctx, reviewID)
	if err != nil {
		return apperrors.Internal("failed to find review")
	}
	if rev == nil {
		return apperrors.NotFound("review not found")
	}

	// Look up the vendor profile for the authenticated user.
	v, err := s.vendorRepo.FindByUserID(ctx, userID)
	if err != nil {
		return apperrors.Internal("failed to look up vendor profile")
	}
	if v == nil {
		return apperrors.Forbidden("user is not a vendor")
	}

	// Ensure the review belongs to this vendor.
	if rev.VendorID != v.ID {
		return apperrors.Forbidden("this review does not belong to your vendor profile")
	}

	if err := s.repo.UpdateVendorReply(ctx, reviewID, req.Reply); err != nil {
		return apperrors.Internal("failed to save vendor reply")
	}

	return nil
}

// AdminDeleteReview soft-deletes any review without ownership checks.
func (s *reviewService) AdminDeleteReview(ctx context.Context, reviewID uuid.UUID) error {
	rev, err := s.repo.FindByID(ctx, reviewID)
	if err != nil {
		return apperrors.Internal("failed to find review")
	}
	if rev == nil {
		return apperrors.NotFound("review not found")
	}

	if err := s.repo.Delete(ctx, reviewID); err != nil {
		return apperrors.Internal("failed to delete review")
	}

	return nil
}

// AdminListReviews returns a paginated list of all reviews.
func (s *reviewService) AdminListReviews(ctx context.Context, params pagination.Params) (*pagination.Result[ReviewResponse], error) {
	result, err := s.repo.ListAll(ctx, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list reviews")
	}

	return toReviewResultResponse(result), nil
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// toReviewResultResponse converts a pagination.Result[Review] to
// pagination.Result[ReviewResponse].
func toReviewResultResponse(result *pagination.Result[Review]) *pagination.Result[ReviewResponse] {
	responses := make([]ReviewResponse, len(result.Items))
	for i := range result.Items {
		responses[i] = toReviewResponse(&result.Items[i])
	}
	return &pagination.Result[ReviewResponse]{
		Items: responses,
		Total: result.Total,
	}
}
