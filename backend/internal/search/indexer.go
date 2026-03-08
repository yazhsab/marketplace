package search

import (
	"context"

	"github.com/meilisearch/meilisearch-go"

	pkgsearch "github.com/prabakarankannan/marketplace-backend/pkg/search"
)

// Index names used across the search module.
const (
	IndexProducts = "products"
	IndexServices = "services"
	IndexVendors  = "vendors"
)

// Indexer manages the creation and maintenance of search indexes.
type Indexer struct {
	search *pkgsearch.SearchService
}

// NewIndexer returns a new Indexer backed by the provided SearchService.
func NewIndexer(search *pkgsearch.SearchService) *Indexer {
	return &Indexer{search: search}
}

// InitIndexes creates the "products", "services", and "vendors" indexes with
// the appropriate searchable, filterable, and sortable attributes.
func (idx *Indexer) InitIndexes() error {
	// Create indexes (idempotent on the MeiliSearch side).
	if err := idx.search.CreateIndex(IndexProducts, "id"); err != nil {
		return err
	}
	if err := idx.search.CreateIndex(IndexServices, "id"); err != nil {
		return err
	}
	if err := idx.search.CreateIndex(IndexVendors, "id"); err != nil {
		return err
	}

	// Configure products index.
	productsIdx := idx.search.Index(IndexProducts)
	if _, err := productsIdx.UpdateSearchableAttributes(&[]string{
		"name", "description", "tags",
	}); err != nil {
		return err
	}
	prodFilterable := toInterfaceSlice("vendor_id", "category_id", "price", "avg_rating", "is_active")
	if _, err := productsIdx.UpdateFilterableAttributes(&prodFilterable); err != nil {
		return err
	}
	if _, err := productsIdx.UpdateSortableAttributes(&[]string{
		"price", "avg_rating", "created_at",
	}); err != nil {
		return err
	}

	// Configure services index.
	servicesIdx := idx.search.Index(IndexServices)
	if _, err := servicesIdx.UpdateSearchableAttributes(&[]string{
		"name", "description", "tags",
	}); err != nil {
		return err
	}
	svcFilterable := toInterfaceSlice("vendor_id", "category_id", "price", "is_active")
	if _, err := servicesIdx.UpdateFilterableAttributes(&svcFilterable); err != nil {
		return err
	}
	if _, err := servicesIdx.UpdateSortableAttributes(&[]string{
		"price", "avg_rating",
	}); err != nil {
		return err
	}

	// Configure vendors index.
	vendorsIdx := idx.search.Index(IndexVendors)
	if _, err := vendorsIdx.UpdateSearchableAttributes(&[]string{
		"business_name", "description", "city",
	}); err != nil {
		return err
	}
	vendorFilterable := toInterfaceSlice("vendor_type", "status", "city", "is_online")
	if _, err := vendorsIdx.UpdateFilterableAttributes(&vendorFilterable); err != nil {
		return err
	}
	if _, err := vendorsIdx.UpdateSortableAttributes(&[]string{
		"avg_rating",
	}); err != nil {
		return err
	}

	return nil
}

// IndexProduct indexes a single product document.
func (idx *Indexer) IndexProduct(_ context.Context, product map[string]interface{}) error {
	return idx.search.AddDocuments(IndexProducts, []map[string]interface{}{product}, "id")
}

// IndexService indexes a single service document.
func (idx *Indexer) IndexService(_ context.Context, service map[string]interface{}) error {
	return idx.search.AddDocuments(IndexServices, []map[string]interface{}{service}, "id")
}

// IndexVendor indexes a single vendor document.
func (idx *Indexer) IndexVendor(_ context.Context, vendor map[string]interface{}) error {
	return idx.search.AddDocuments(IndexVendors, []map[string]interface{}{vendor}, "id")
}

// DeleteProduct removes a product document from the search index.
func (idx *Indexer) DeleteProduct(_ context.Context, id string) error {
	return idx.search.DeleteDocument(IndexProducts, id)
}

// DeleteService removes a service document from the search index.
func (idx *Indexer) DeleteService(_ context.Context, id string) error {
	return idx.search.DeleteDocument(IndexServices, id)
}

// DeleteVendor removes a vendor document from the search index.
func (idx *Indexer) DeleteVendor(_ context.Context, id string) error {
	return idx.search.DeleteDocument(IndexVendors, id)
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// toInterfaceSlice converts string arguments to a []interface{} slice, as
// required by the MeiliSearch UpdateFilterableAttributes API.
func toInterfaceSlice(values ...string) []interface{} {
	result := make([]interface{}, len(values))
	for i, v := range values {
		result[i] = v
	}
	return result
}

// buildFilterString converts a map of filters to a MeiliSearch-compatible
// filter string. Each entry produces a filter clause.
func buildFilterString(filters map[string]interface{}) []string {
	if len(filters) == 0 {
		return nil
	}

	var result []string
	for _, v := range filters {
		if s, ok := v.(string); ok {
			result = append(result, s)
		}
	}
	return result
}

// buildSearchRequest creates a MeiliSearch SearchRequest from the given parameters.
func buildSearchRequest(filters map[string]interface{}, sort *string, page, perPage int) *meilisearch.SearchRequest {
	req := &meilisearch.SearchRequest{
		Offset: int64((page - 1) * perPage),
		Limit:  int64(perPage),
	}

	if f := buildFilterString(filters); len(f) > 0 {
		req.Filter = f
	}

	if sort != nil && *sort != "" {
		req.Sort = []string{*sort}
	}

	return req
}
