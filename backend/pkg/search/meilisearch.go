package search

import (
	"fmt"

	"github.com/meilisearch/meilisearch-go"
	"github.com/prabakarankannan/marketplace-backend/config"
)

// SearchService provides full-text search capabilities backed by MeiliSearch.
type SearchService struct {
	client meilisearch.ServiceManager
}

// NewSearchService creates a new SearchService connected to the MeiliSearch
// instance described by cfg. It performs a health check to verify connectivity.
func NewSearchService(cfg config.MeiliConfig) (*SearchService, error) {
	client := meilisearch.New(cfg.Host, meilisearch.WithAPIKey(cfg.MasterKey))

	if !client.IsHealthy() {
		return nil, fmt.Errorf("meilisearch at %s is not healthy", cfg.Host)
	}

	return &SearchService{client: client}, nil
}

// Index returns a handle to the named MeiliSearch index for direct operations.
func (s *SearchService) Index(name string) meilisearch.IndexManager {
	return s.client.Index(name)
}

// CreateIndex creates a new index with the given name and primary key. The
// operation is enqueued by MeiliSearch and processed asynchronously.
func (s *SearchService) CreateIndex(name, primaryKey string) error {
	_, err := s.client.CreateIndex(&meilisearch.IndexConfig{
		Uid:        name,
		PrimaryKey: primaryKey,
	})
	if err != nil {
		return fmt.Errorf("failed to create index %q: %w", name, err)
	}

	return nil
}

// AddDocuments indexes the provided documents into the named index. docs should
// be a slice of structs or maps. primaryKey identifies the unique field.
func (s *SearchService) AddDocuments(indexName string, docs interface{}, primaryKey string) error {
	opts := &meilisearch.DocumentOptions{
		PrimaryKey: &primaryKey,
	}

	_, err := s.client.Index(indexName).AddDocuments(docs, opts)
	if err != nil {
		return fmt.Errorf("failed to add documents to %q: %w", indexName, err)
	}

	return nil
}

// Search executes a search query against the named index with the given options.
func (s *SearchService) Search(indexName, query string, opts *meilisearch.SearchRequest) (*meilisearch.SearchResponse, error) {
	resp, err := s.client.Index(indexName).Search(query, opts)
	if err != nil {
		return nil, fmt.Errorf("search in %q failed: %w", indexName, err)
	}

	return resp, nil
}

// DeleteDocument removes a single document identified by docID from the named index.
func (s *SearchService) DeleteDocument(indexName, docID string) error {
	_, err := s.client.Index(indexName).DeleteDocument(docID, nil)
	if err != nil {
		return fmt.Errorf("failed to delete document %q from %q: %w", docID, indexName, err)
	}

	return nil
}
