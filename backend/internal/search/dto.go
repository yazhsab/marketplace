package search

// SearchRequest is the payload for performing a search query.
type SearchRequest struct {
	Query   string                 `json:"query"   validate:"required"`
	Filters map[string]interface{} `json:"filters,omitempty"`
	Sort    *string                `json:"sort,omitempty"`
	Page    int                    `json:"page,omitempty"`
	PerPage int                    `json:"per_page,omitempty"`
}

// SearchResponse is the public representation of search results.
type SearchResponse struct {
	Hits             []map[string]interface{} `json:"hits"`
	Query            string                   `json:"query"`
	TotalHits        int64                    `json:"total_hits"`
	ProcessingTimeMs int64                    `json:"processing_time_ms"`
}
