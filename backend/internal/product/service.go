package product

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"

	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
	"github.com/prabakarankannan/marketplace-backend/internal/common/pagination"
	"github.com/prabakarankannan/marketplace-backend/internal/vendor"
	"github.com/prabakarankannan/marketplace-backend/pkg/cache"
)

const (
	productCacheTTL  = 15 * time.Minute
	categoryCacheTTL = 30 * time.Minute
)

// ProductService defines the business-logic contract for the product module.
type ProductService interface {
	// Category operations
	CreateCategory(ctx context.Context, req CreateCategoryRequest) (*CategoryResponse, error)
	UpdateCategory(ctx context.Context, id uuid.UUID, req UpdateCategoryRequest) error
	DeleteCategory(ctx context.Context, id uuid.UUID) error
	GetCategory(ctx context.Context, id uuid.UUID) (*CategoryResponse, error)
	ListCategories(ctx context.Context, categoryType string) ([]CategoryResponse, error)

	// Product operations
	CreateProduct(ctx context.Context, userID uuid.UUID, req CreateProductRequest) (*ProductResponse, error)
	UpdateProduct(ctx context.Context, userID uuid.UUID, productID uuid.UUID, req UpdateProductRequest) error
	DeleteProduct(ctx context.Context, userID uuid.UUID, productID uuid.UUID) error
	GetProduct(ctx context.Context, productID uuid.UUID) (*ProductResponse, error)
	ListProducts(ctx context.Context, params pagination.Params, filters ProductListFilters) (*pagination.Result[ProductResponse], error)
	ListByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[ProductResponse], error)
	ListByCategory(ctx context.Context, categorySlug string, params pagination.Params) (*pagination.Result[ProductResponse], error)

	// Stock / Inventory
	UpdateStock(ctx context.Context, userID uuid.UUID, productID uuid.UUID, quantity int) error
	GetInventory(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[ProductResponse], error)
	GetLowStockAlerts(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[ProductResponse], error)
}

// productService is the concrete implementation of ProductService.
type productService struct {
	repo       ProductRepository
	vendorRepo vendor.VendorRepository
	cache      *cache.CacheService
}

// NewProductService returns a new ProductService with all required dependencies.
func NewProductService(
	repo ProductRepository,
	vendorRepo vendor.VendorRepository,
	cache *cache.CacheService,
) ProductService {
	return &productService{
		repo:       repo,
		vendorRepo: vendorRepo,
		cache:      cache,
	}
}

// ---------------------------------------------------------------------------
// Cache key helpers
// ---------------------------------------------------------------------------

func productCacheKey(id uuid.UUID) string {
	return fmt.Sprintf("product:%s", id.String())
}

func categoriesCacheKey(categoryType string) string {
	if categoryType == "" {
		return "categories:all"
	}
	return fmt.Sprintf("categories:%s", categoryType)
}

// ---------------------------------------------------------------------------
// Category operations
// ---------------------------------------------------------------------------

// CreateCategory creates a new category.
func (s *productService) CreateCategory(ctx context.Context, req CreateCategoryRequest) (*CategoryResponse, error) {
	cat := Category{
		ID:           uuid.New(),
		Name:         req.Name,
		Slug:         req.Slug,
		CategoryType: req.CategoryType,
		Description:  req.Description,
		ImageURL:     req.ImageURL,
		ParentID:     req.ParentID,
		IsActive:     true,
	}

	if req.SortOrder != nil {
		cat.SortOrder = *req.SortOrder
	}

	if err := s.repo.CreateCategory(ctx, &cat); err != nil {
		return nil, apperrors.Internal("failed to create category")
	}

	// Invalidate categories cache.
	_ = s.cache.Invalidate(ctx, "categories:*")

	resp := toCategoryResponse(&cat)
	return &resp, nil
}

// UpdateCategory applies partial updates to an existing category.
func (s *productService) UpdateCategory(ctx context.Context, id uuid.UUID, req UpdateCategoryRequest) error {
	cat, err := s.repo.GetCategory(ctx, id)
	if err != nil {
		return apperrors.Internal("failed to find category")
	}
	if cat == nil {
		return apperrors.NotFound("category not found")
	}

	if req.Name != nil {
		cat.Name = *req.Name
	}
	if req.Slug != nil {
		cat.Slug = *req.Slug
	}
	if req.Description != nil {
		cat.Description = req.Description
	}
	if req.ImageURL != nil {
		cat.ImageURL = req.ImageURL
	}
	if req.IsActive != nil {
		cat.IsActive = *req.IsActive
	}
	if req.SortOrder != nil {
		cat.SortOrder = *req.SortOrder
	}

	if err := s.repo.UpdateCategory(ctx, cat); err != nil {
		return apperrors.Internal("failed to update category")
	}

	// Invalidate categories cache.
	_ = s.cache.Invalidate(ctx, "categories:*")

	return nil
}

// DeleteCategory removes a category by its ID.
func (s *productService) DeleteCategory(ctx context.Context, id uuid.UUID) error {
	cat, err := s.repo.GetCategory(ctx, id)
	if err != nil {
		return apperrors.Internal("failed to find category")
	}
	if cat == nil {
		return apperrors.NotFound("category not found")
	}

	if err := s.repo.DeleteCategory(ctx, id); err != nil {
		return apperrors.Internal("failed to delete category")
	}

	// Invalidate categories cache.
	_ = s.cache.Invalidate(ctx, "categories:*")

	return nil
}

// GetCategory retrieves a category by its ID.
func (s *productService) GetCategory(ctx context.Context, id uuid.UUID) (*CategoryResponse, error) {
	cat, err := s.repo.GetCategory(ctx, id)
	if err != nil {
		return nil, apperrors.Internal("failed to find category")
	}
	if cat == nil {
		return nil, apperrors.NotFound("category not found")
	}

	resp := toCategoryResponse(cat)
	return &resp, nil
}

// ListCategories returns all categories (tree structure), with caching.
func (s *productService) ListCategories(ctx context.Context, categoryType string) ([]CategoryResponse, error) {
	key := categoriesCacheKey(categoryType)

	// Try cache first.
	var cached []CategoryResponse
	if err := s.cache.Get(ctx, key, &cached); err == nil {
		return cached, nil
	}

	cats, err := s.repo.ListCategories(ctx, categoryType)
	if err != nil {
		return nil, apperrors.Internal("failed to list categories")
	}

	responses := make([]CategoryResponse, len(cats))
	for i := range cats {
		responses[i] = toCategoryResponse(&cats[i])
	}

	// Populate cache (best-effort).
	_ = s.cache.Set(ctx, key, responses, categoryCacheTTL)

	return responses, nil
}

// ---------------------------------------------------------------------------
// Product operations
// ---------------------------------------------------------------------------

// getVendorForUser retrieves the vendor profile for the given userID and returns
// an error if the user is not a vendor.
func (s *productService) getVendorForUser(ctx context.Context, userID uuid.UUID) (*vendor.Vendor, error) {
	v, err := s.vendorRepo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, apperrors.Internal("failed to look up vendor profile")
	}
	if v == nil {
		return nil, apperrors.Forbidden("user is not a vendor")
	}
	return v, nil
}

// verifyProductOwnership ensures the product belongs to the vendor associated
// with the given userID.
func (s *productService) verifyProductOwnership(ctx context.Context, userID uuid.UUID, productID uuid.UUID) (*Product, *vendor.Vendor, error) {
	v, err := s.getVendorForUser(ctx, userID)
	if err != nil {
		return nil, nil, err
	}

	p, err := s.repo.GetProduct(ctx, productID)
	if err != nil {
		return nil, nil, apperrors.Internal("failed to find product")
	}
	if p == nil {
		return nil, nil, apperrors.NotFound("product not found")
	}
	if p.VendorID != v.ID {
		return nil, nil, apperrors.Forbidden("product does not belong to your vendor profile")
	}

	return p, v, nil
}

// CreateProduct creates a new product for the vendor associated with the user.
func (s *productService) CreateProduct(ctx context.Context, userID uuid.UUID, req CreateProductRequest) (*ProductResponse, error) {
	v, err := s.getVendorForUser(ctx, userID)
	if err != nil {
		return nil, err
	}

	p := Product{
		ID:            uuid.New(),
		VendorID:      v.ID,
		CategoryID:    req.CategoryID,
		Name:          req.Name,
		Slug:          req.Slug,
		Description:   req.Description,
		Price:         req.Price,
		ComparePrice:  req.ComparePrice,
		SKU:           req.SKU,
		Images:        pq.StringArray(req.Images),
		IsActive:      true,
		StockQuantity: req.StockQuantity,
		Tags:          pq.StringArray(req.Tags),
	}

	if req.Unit != nil {
		p.Unit = *req.Unit
	} else {
		p.Unit = "piece"
	}
	if req.LowStockThreshold != nil {
		p.LowStockThreshold = *req.LowStockThreshold
	} else {
		p.LowStockThreshold = 5
	}
	if req.WeightGrams != nil {
		p.WeightGrams = req.WeightGrams
	}

	if err := s.repo.CreateProduct(ctx, &p); err != nil {
		return nil, apperrors.Internal("failed to create product")
	}

	// Re-fetch to preload category.
	created, err := s.repo.GetProduct(ctx, p.ID)
	if err != nil || created == nil {
		return nil, apperrors.Internal("failed to retrieve created product")
	}

	resp := toProductResponse(created)
	return &resp, nil
}

// UpdateProduct applies partial updates to a product after verifying ownership.
func (s *productService) UpdateProduct(ctx context.Context, userID uuid.UUID, productID uuid.UUID, req UpdateProductRequest) error {
	p, _, err := s.verifyProductOwnership(ctx, userID, productID)
	if err != nil {
		return err
	}

	if req.CategoryID != nil {
		p.CategoryID = *req.CategoryID
	}
	if req.Name != nil {
		p.Name = *req.Name
	}
	if req.Slug != nil {
		p.Slug = *req.Slug
	}
	if req.Description != nil {
		p.Description = req.Description
	}
	if req.Price != nil {
		p.Price = *req.Price
	}
	if req.ComparePrice != nil {
		p.ComparePrice = req.ComparePrice
	}
	if req.Unit != nil {
		p.Unit = *req.Unit
	}
	if req.SKU != nil {
		p.SKU = req.SKU
	}
	if req.Images != nil {
		p.Images = pq.StringArray(req.Images)
	}
	if req.IsActive != nil {
		p.IsActive = *req.IsActive
	}
	if req.StockQuantity != nil {
		p.StockQuantity = *req.StockQuantity
	}
	if req.LowStockThreshold != nil {
		p.LowStockThreshold = *req.LowStockThreshold
	}
	if req.WeightGrams != nil {
		p.WeightGrams = req.WeightGrams
	}
	if req.Tags != nil {
		p.Tags = pq.StringArray(req.Tags)
	}

	if err := s.repo.UpdateProduct(ctx, p); err != nil {
		return apperrors.Internal("failed to update product")
	}

	// Invalidate product cache.
	_ = s.cache.Delete(ctx, productCacheKey(productID))

	return nil
}

// DeleteProduct soft-deletes a product after verifying ownership.
func (s *productService) DeleteProduct(ctx context.Context, userID uuid.UUID, productID uuid.UUID) error {
	_, _, err := s.verifyProductOwnership(ctx, userID, productID)
	if err != nil {
		return err
	}

	if err := s.repo.DeleteProduct(ctx, productID); err != nil {
		return apperrors.Internal("failed to delete product")
	}

	// Invalidate product cache.
	_ = s.cache.Delete(ctx, productCacheKey(productID))

	return nil
}

// GetProduct retrieves a product by ID, using cache when available.
func (s *productService) GetProduct(ctx context.Context, productID uuid.UUID) (*ProductResponse, error) {
	key := productCacheKey(productID)

	// Try cache first.
	var cached ProductResponse
	if err := s.cache.Get(ctx, key, &cached); err == nil {
		return &cached, nil
	}

	p, err := s.repo.GetProduct(ctx, productID)
	if err != nil {
		return nil, apperrors.Internal("failed to find product")
	}
	if p == nil {
		return nil, apperrors.NotFound("product not found")
	}

	resp := toProductResponse(p)

	// Populate cache (best-effort).
	_ = s.cache.Set(ctx, key, &resp, productCacheTTL)

	return &resp, nil
}

// ListProducts returns a paginated, filtered list of products.
func (s *productService) ListProducts(ctx context.Context, params pagination.Params, filters ProductListFilters) (*pagination.Result[ProductResponse], error) {
	result, err := s.repo.ListProducts(ctx, params, filters)
	if err != nil {
		return nil, apperrors.Internal("failed to list products")
	}

	return toProductResultResponse(result), nil
}

// ListByVendor returns a paginated list of products belonging to a vendor.
func (s *productService) ListByVendor(ctx context.Context, vendorID uuid.UUID, params pagination.Params) (*pagination.Result[ProductResponse], error) {
	result, err := s.repo.ListByVendor(ctx, vendorID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list vendor products")
	}

	return toProductResultResponse(result), nil
}

// ListByCategory returns a paginated list of active products for a category slug.
func (s *productService) ListByCategory(ctx context.Context, categorySlug string, params pagination.Params) (*pagination.Result[ProductResponse], error) {
	cat, err := s.repo.GetCategoryBySlug(ctx, categorySlug)
	if err != nil {
		return nil, apperrors.Internal("failed to find category")
	}
	if cat == nil {
		return nil, apperrors.NotFound("category not found")
	}

	result, err := s.repo.ListByCategory(ctx, cat.ID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list category products")
	}

	return toProductResultResponse(result), nil
}

// ---------------------------------------------------------------------------
// Stock / Inventory
// ---------------------------------------------------------------------------

// UpdateStock sets the stock quantity for a product after verifying ownership.
func (s *productService) UpdateStock(ctx context.Context, userID uuid.UUID, productID uuid.UUID, quantity int) error {
	_, _, err := s.verifyProductOwnership(ctx, userID, productID)
	if err != nil {
		return err
	}

	if err := s.repo.UpdateStock(ctx, productID, quantity); err != nil {
		return apperrors.Internal("failed to update stock")
	}

	// Invalidate product cache.
	_ = s.cache.Delete(ctx, productCacheKey(productID))

	return nil
}

// GetInventory returns a paginated list of products for the vendor associated
// with the user.
func (s *productService) GetInventory(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[ProductResponse], error) {
	v, err := s.getVendorForUser(ctx, userID)
	if err != nil {
		return nil, err
	}

	result, err := s.repo.ListByVendor(ctx, v.ID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to list inventory")
	}

	return toProductResultResponse(result), nil
}

// GetLowStockAlerts returns products where stock is at or below the threshold
// for the vendor associated with the user.
func (s *productService) GetLowStockAlerts(ctx context.Context, userID uuid.UUID, params pagination.Params) (*pagination.Result[ProductResponse], error) {
	v, err := s.getVendorForUser(ctx, userID)
	if err != nil {
		return nil, err
	}

	result, err := s.repo.GetLowStockProducts(ctx, v.ID, params)
	if err != nil {
		return nil, apperrors.Internal("failed to get low stock alerts")
	}

	return toProductResultResponse(result), nil
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// toProductResultResponse converts a pagination.Result[Product] to
// pagination.Result[ProductResponse].
func toProductResultResponse(result *pagination.Result[Product]) *pagination.Result[ProductResponse] {
	responses := make([]ProductResponse, len(result.Items))
	for i := range result.Items {
		responses[i] = toProductResponse(&result.Items[i])
	}
	return &pagination.Result[ProductResponse]{
		Items: responses,
		Total: result.Total,
	}
}
