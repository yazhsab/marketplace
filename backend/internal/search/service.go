package search

import (
	"context"
	"encoding/json"
	"log"

	"github.com/meilisearch/meilisearch-go"

	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
	pkgsearch "github.com/prabakarankannan/marketplace-backend/pkg/search"
)

// SearchModuleService defines the business-logic contract for the search module.
type SearchModuleService interface {
	SearchProducts(ctx context.Context, query string, filters map[string]interface{}, page, perPage int) (*SearchResponse, error)
	SearchServices(ctx context.Context, query string, filters map[string]interface{}, page, perPage int) (*SearchResponse, error)
	SearchVendors(ctx context.Context, query string, filters map[string]interface{}, page, perPage int) (*SearchResponse, error)
	UniversalSearch(ctx context.Context, query string, page, perPage int) (map[string]*SearchResponse, error)
	GetSuggestions(ctx context.Context, query string) ([]string, error)
}

// searchModuleService is the concrete implementation of SearchModuleService.
type searchModuleService struct {
	search  *pkgsearch.SearchService
	indexer *Indexer
}

// NewSearchModuleService returns a new SearchModuleService with all required dependencies.
func NewSearchModuleService(
	search *pkgsearch.SearchService,
	indexer *Indexer,
) SearchModuleService {
	return &searchModuleService{
		search:  search,
		indexer: indexer,
	}
}

// SearchProducts searches the products index.
func (s *searchModuleService) SearchProducts(_ context.Context, query string, filters map[string]interface{}, page, perPage int) (*SearchResponse, error) {
	return s.searchIndex(IndexProducts, query, filters, nil, page, perPage)
}

// SearchServices searches the services index.
func (s *searchModuleService) SearchServices(_ context.Context, query string, filters map[string]interface{}, page, perPage int) (*SearchResponse, error) {
	return s.searchIndex(IndexServices, query, filters, nil, page, perPage)
}

// SearchVendors searches the vendors index.
func (s *searchModuleService) SearchVendors(_ context.Context, query string, filters map[string]interface{}, page, perPage int) (*SearchResponse, error) {
	return s.searchIndex(IndexVendors, query, filters, nil, page, perPage)
}

// UniversalSearch searches all three indexes (products, services, vendors) and
// returns the combined results keyed by index name.
func (s *searchModuleService) UniversalSearch(_ context.Context, query string, page, perPage int) (map[string]*SearchResponse, error) {
	results := make(map[string]*SearchResponse)

	for _, index := range []string{IndexProducts, IndexServices, IndexVendors} {
		resp, err := s.searchIndex(index, query, nil, nil, page, perPage)
		if err != nil {
			return nil, err
		}
		results[index] = resp
	}

	return results, nil
}

// GetSuggestions returns up to 5 product and service name suggestions matching
// the given query prefix.
func (s *searchModuleService) GetSuggestions(_ context.Context, query string) ([]string, error) {
	req := &meilisearch.SearchRequest{
		Limit:                int64(5),
		AttributesToRetrieve: []string{"name"},
	}

	var suggestions []string

	// Search products for suggestions.
	prodResp, err := s.search.Search(IndexProducts, query, req)
	if err != nil {
		return nil, apperrors.Internal("failed to search product suggestions")
	}
	for _, hit := range prodResp.Hits {
		if name := extractName(hit); name != "" {
			suggestions = append(suggestions, name)
		}
	}

	// Search services for suggestions.
	svcResp, err := s.search.Search(IndexServices, query, req)
	if err != nil {
		return nil, apperrors.Internal("failed to search service suggestions")
	}
	for _, hit := range svcResp.Hits {
		if name := extractName(hit); name != "" {
			suggestions = append(suggestions, name)
		}
	}

	// Limit to 5 total suggestions.
	if len(suggestions) > 5 {
		suggestions = suggestions[:5]
	}

	return suggestions, nil
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// decodeHit converts a meilisearch.Hit (map[string]json.RawMessage) to a
// map[string]interface{}.
func decodeHit(hit meilisearch.Hit) map[string]interface{} {
	m := make(map[string]interface{}, len(hit))
	for k, raw := range hit {
		var v interface{}
		if err := json.Unmarshal(raw, &v); err != nil {
			log.Printf("[Search] failed to decode hit field %q: %v", k, err)
			continue
		}
		m[k] = v
	}
	return m
}

// extractName extracts the "name" field from a hit as a string.
func extractName(hit meilisearch.Hit) string {
	raw, ok := hit["name"]
	if !ok {
		return ""
	}
	var name string
	if err := json.Unmarshal(raw, &name); err != nil {
		return ""
	}
	return name
}

// searchIndex performs a search against the named index and converts the
// MeiliSearch response to a SearchResponse.
func (s *searchModuleService) searchIndex(indexName, query string, filters map[string]interface{}, sort *string, page, perPage int) (*SearchResponse, error) {
	if page < 1 {
		page = 1
	}
	if perPage < 1 {
		perPage = 20
	}

	req := buildSearchRequest(filters, sort, page, perPage)

	resp, err := s.search.Search(indexName, query, req)
	if err != nil {
		return nil, apperrors.Internal("search failed for index " + indexName)
	}

	hits := make([]map[string]interface{}, 0, len(resp.Hits))
	for _, hit := range resp.Hits {
		hits = append(hits, decodeHit(hit))
	}

	return &SearchResponse{
		Hits:             hits,
		Query:            query,
		TotalHits:        resp.EstimatedTotalHits,
		ProcessingTimeMs: resp.ProcessingTimeMs,
	}, nil
}
