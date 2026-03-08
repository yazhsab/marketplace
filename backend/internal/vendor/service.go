package vendor

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/internal/auth"
	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/pkg/cache"
)

const vendorCacheTTL = 15 * time.Minute

// VendorService defines the business-logic contract for the vendor module.
type VendorService interface {
	Register(ctx context.Context, userID uuid.UUID, req RegisterVendorRequest) (*VendorResponse, error)
	GetProfile(ctx context.Context, userID uuid.UUID) (*VendorResponse, error)
	GetByID(ctx context.Context, id uuid.UUID) (*VendorResponse, error)
	UpdateProfile(ctx context.Context, userID uuid.UUID, req UpdateVendorRequest) error
	SetOnlineStatus(ctx context.Context, userID uuid.UUID, isOnline bool) error
	ListAll(ctx context.Context, params pagination.Params, status, city string) (*pagination.Result[VendorResponse], error)
	FindNearby(ctx context.Context, lat, lng, radiusKM float64, params pagination.Params) (*pagination.Result[VendorResponse], error)
	UploadDocument(ctx context.Context, userID uuid.UUID, req UploadDocumentRequest) (*VendorDocumentResponse, error)
	ListDocuments(ctx context.Context, userID uuid.UUID) ([]VendorDocumentResponse, error)
	DeleteDocument(ctx context.Context, userID uuid.UUID, docID uuid.UUID) error
	AdminUpdateStatus(ctx context.Context, vendorID uuid.UUID, req AdminUpdateStatusRequest) error
	AdminUpdateCommission(ctx context.Context, vendorID uuid.UUID, pct float64) error
	AdminReviewDocument(ctx context.Context, docID uuid.UUID, req AdminReviewDocumentRequest, adminUserID uuid.UUID) error
}

// vendorService is the concrete implementation of VendorService.
type vendorService struct {
	repo     VendorRepository
	cache    *cache.CacheService
	authRepo auth.AuthRepository
}

// NewVendorService returns a new VendorService with all required dependencies.
func NewVendorService(
	repo VendorRepository,
	cache *cache.CacheService,
	authRepo auth.AuthRepository,
) VendorService {
	return &vendorService{
		repo:     repo,
		cache:    cache,
		authRepo: authRepo,
	}
}

// cacheKey returns the Redis key for a vendor by its ID.
func vendorCacheKey(id uuid.UUID) string {
	return fmt.Sprintf("vendor:%s", id.String())
}

// Register creates a new vendor profile for the given user. It checks that the
// user exists and that they do not already have a vendor profile, creates the
// vendor record, and updates the user's role to "vendor".
func (s *vendorService) Register(ctx context.Context, userID uuid.UUID, req RegisterVendorRequest) (*VendorResponse, error) {
	// Verify the user exists.
	user, err := s.authRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to look up user")
	}
	if user == nil {
		return nil, apperrors.NotFound("user not found")
	}

	// Check for existing vendor profile.
	existing, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to check existing vendor")
	}
	if existing != nil {
		return nil, apperrors.Conflict("user already has a vendor profile")
	}

	vendor := Vendor{
		ID:           uuid.New(),
		UserID:       userID,
		BusinessName: req.BusinessName,
		Description:  req.Description,
		VendorType:   req.VendorType,
		Status:       "pending",
		Latitude:     req.Latitude,
		Longitude:    req.Longitude,
		Address:      req.Address,
		City:         req.City,
		State:        req.State,
		Pincode:      req.Pincode,
	}

	if err := s.repo.Create(ctx, &vendor); err != nil {
		return nil, apperrors.Internal("failed to create vendor")
	}

	// Update the user role to "vendor".
	user.Role = "vendor"
	if err := s.authRepo.Update(ctx, user); err != nil {
		return nil, apperrors.Internal("failed to update user role")
	}

	resp := toVendorResponse(&vendor)
	return &resp, nil
}

// GetProfile returns the vendor profile belonging to the given user.
func (s *vendorService) GetProfile(ctx context.Context, userID uuid.UUID) (*VendorResponse, error) {
	v, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to find vendor profile")
	}
	if v == nil {
		return nil, apperrors.NotFound("vendor profile not found")
	}

	resp := toVendorResponse(v)
	return &resp, nil
}

// GetByID returns a vendor by its ID, using Redis cache when available.
func (s *vendorService) GetByID(ctx context.Context, id uuid.UUID) (*VendorResponse, error) {
	key := vendorCacheKey(id)

	// Try cache first.
	var cached VendorResponse
	if err := s.cache.Get(ctx, key, &cached); err == nil {
		return &cached, nil
	}

	v, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, apperrors.Internal("failed to find vendor")
	}
	if v == nil {
		return nil, apperrors.NotFound("vendor not found")
	}

	resp := toVendorResponse(v)

	// Populate cache (best-effort).
	_ = s.cache.Set(ctx, key, &resp, vendorCacheTTL)

	return &resp, nil
}

// UpdateProfile applies partial updates to the vendor profile owned by the user.
func (s *vendorService) UpdateProfile(ctx context.Context, userID uuid.UUID, req UpdateVendorRequest) error {
	v, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return apperrors.Internal("failed to find vendor profile")
	}
	if v == nil {
		return apperrors.NotFound("vendor profile not found")
	}

	if req.BusinessName != nil {
		v.BusinessName = *req.BusinessName
	}
	if req.Description != nil {
		v.Description = req.Description
	}
	if req.LogoURL != nil {
		v.LogoURL = req.LogoURL
	}
	if req.BannerURL != nil {
		v.BannerURL = req.BannerURL
	}
	if req.ServiceRadiusKM != nil {
		v.ServiceRadiusKM = *req.ServiceRadiusKM
	}

	if err := s.repo.Update(ctx, v); err != nil {
		return apperrors.Internal("failed to update vendor profile")
	}

	// Invalidate cache.
	_ = s.cache.Delete(ctx, vendorCacheKey(v.ID))

	return nil
}

// SetOnlineStatus toggles the is_online flag for the vendor owned by the user.
func (s *vendorService) SetOnlineStatus(ctx context.Context, userID uuid.UUID, isOnline bool) error {
	v, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return apperrors.Internal("failed to find vendor profile")
	}
	if v == nil {
		return apperrors.NotFound("vendor profile not found")
	}

	if err := s.repo.UpdateOnlineStatus(ctx, v.ID, isOnline); err != nil {
		return apperrors.Internal("failed to update online status")
	}

	_ = s.cache.Delete(ctx, vendorCacheKey(v.ID))

	return nil
}

// ListAll returns a paginated list of vendors with optional status and city filters.
func (s *vendorService) ListAll(ctx context.Context, params pagination.Params, status, city string) (*pagination.Result[VendorResponse], error) {
	result, err := s.repo.ListAll(ctx, params, status, city)
	if err != nil {
		return nil, apperrors.Internal("failed to list vendors")
	}

	responses := make([]VendorResponse, len(result.Items))
	for i := range result.Items {
		responses[i] = toVendorResponse(&result.Items[i])
	}

	return &pagination.Result[VendorResponse]{
		Items: responses,
		Total: result.Total,
	}, nil
}

// FindNearby returns vendors within the given radius of a geographic point.
func (s *vendorService) FindNearby(ctx context.Context, lat, lng, radiusKM float64, params pagination.Params) (*pagination.Result[VendorResponse], error) {
	result, err := s.repo.FindNearby(ctx, lat, lng, radiusKM, params)
	if err != nil {
		return nil, apperrors.Internal("failed to find nearby vendors")
	}

	responses := make([]VendorResponse, len(result.Items))
	for i := range result.Items {
		responses[i] = toVendorResponse(&result.Items[i])
	}

	return &pagination.Result[VendorResponse]{
		Items: responses,
		Total: result.Total,
	}, nil
}

// UploadDocument attaches a new document to the vendor profile of the given user.
func (s *vendorService) UploadDocument(ctx context.Context, userID uuid.UUID, req UploadDocumentRequest) (*VendorDocumentResponse, error) {
	v, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to find vendor profile")
	}
	if v == nil {
		return nil, apperrors.NotFound("vendor profile not found")
	}

	doc := VendorDocument{
		ID:       uuid.New(),
		VendorID: v.ID,
		DocType:  req.DocType,
		DocURL:   req.DocURL,
		Status:   "pending",
	}

	if err := s.repo.CreateDocument(ctx, &doc); err != nil {
		return nil, apperrors.Internal("failed to upload document")
	}

	resp := toVendorDocumentResponse(&doc)
	return &resp, nil
}

// ListDocuments returns all documents for the vendor profile of the given user.
func (s *vendorService) ListDocuments(ctx context.Context, userID uuid.UUID) ([]VendorDocumentResponse, error) {
	v, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to find vendor profile")
	}
	if v == nil {
		return nil, apperrors.NotFound("vendor profile not found")
	}

	docs, err := s.repo.ListDocuments(ctx, v.ID)
	if err != nil {
		return nil, apperrors.Internal("failed to list documents")
	}

	responses := make([]VendorDocumentResponse, len(docs))
	for i := range docs {
		responses[i] = toVendorDocumentResponse(&docs[i])
	}

	return responses, nil
}

// DeleteDocument removes a document that belongs to the vendor owned by the user.
func (s *vendorService) DeleteDocument(ctx context.Context, userID uuid.UUID, docID uuid.UUID) error {
	v, err := s.repo.FindByUserID(ctx, userID)
	if err != nil {
		return apperrors.Internal("failed to find vendor profile")
	}
	if v == nil {
		return apperrors.NotFound("vendor profile not found")
	}

	doc, err := s.repo.GetDocument(ctx, docID)
	if err != nil {
		return apperrors.Internal("failed to find document")
	}
	if doc == nil {
		return apperrors.NotFound("document not found")
	}

	// Ensure the document belongs to this vendor.
	if doc.VendorID != v.ID {
		return apperrors.Forbidden("document does not belong to your vendor profile")
	}

	if err := s.repo.DeleteDocument(ctx, docID); err != nil {
		return apperrors.Internal("failed to delete document")
	}

	return nil
}

// AdminUpdateStatus changes the vendor status (approved, rejected, suspended)
// and invalidates the vendor cache.
func (s *vendorService) AdminUpdateStatus(ctx context.Context, vendorID uuid.UUID, req AdminUpdateStatusRequest) error {
	v, err := s.repo.FindByID(ctx, vendorID)
	if err != nil {
		return apperrors.Internal("failed to find vendor")
	}
	if v == nil {
		return apperrors.NotFound("vendor not found")
	}

	if err := s.repo.UpdateStatus(ctx, vendorID, req.Status); err != nil {
		return apperrors.Internal("failed to update vendor status")
	}

	_ = s.cache.Delete(ctx, vendorCacheKey(vendorID))

	return nil
}

// AdminUpdateCommission sets the commission percentage for a vendor.
func (s *vendorService) AdminUpdateCommission(ctx context.Context, vendorID uuid.UUID, pct float64) error {
	v, err := s.repo.FindByID(ctx, vendorID)
	if err != nil {
		return apperrors.Internal("failed to find vendor")
	}
	if v == nil {
		return apperrors.NotFound("vendor not found")
	}

	if err := s.repo.UpdateCommission(ctx, vendorID, pct); err != nil {
		return apperrors.Internal("failed to update commission")
	}

	_ = s.cache.Delete(ctx, vendorCacheKey(vendorID))

	return nil
}

// AdminReviewDocument approves or rejects a vendor document, recording the
// reviewer and optional rejection note.
func (s *vendorService) AdminReviewDocument(ctx context.Context, docID uuid.UUID, req AdminReviewDocumentRequest, adminUserID uuid.UUID) error {
	doc, err := s.repo.GetDocument(ctx, docID)
	if err != nil {
		return apperrors.Internal("failed to find document")
	}
	if doc == nil {
		return apperrors.NotFound("document not found")
	}

	if err := s.repo.UpdateDocumentStatus(ctx, docID, req.Status, req.RejectionNote, adminUserID); err != nil {
		return apperrors.Internal("failed to update document status")
	}

	return nil
}
