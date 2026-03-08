package search

import (
	"strconv"

	"github.com/gofiber/fiber/v2"

	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
)

// SearchHandler exposes HTTP endpoints for the search module.
type SearchHandler struct {
	service SearchModuleService
}

// NewSearchHandler returns a new SearchHandler wired to the given service.
func NewSearchHandler(service SearchModuleService) *SearchHandler {
	return &SearchHandler{service: service}
}

// RegisterRoutes mounts all search routes onto the Fiber application.
// All search routes are public (no authentication required).
func RegisterRoutes(app fiber.Router, h *SearchHandler) {
	s := app.Group("/search")
	s.Get("/", h.UniversalSearch)
	s.Get("/products", h.SearchProducts)
	s.Get("/services", h.SearchServices)
	s.Get("/vendors", h.SearchVendors)
	s.Get("/suggestions", h.GetSuggestions)
}

// ---------------------------------------------------------------------------
// Endpoints
// ---------------------------------------------------------------------------

// UniversalSearch handles GET /search.
func (h *SearchHandler) UniversalSearch(c *fiber.Ctx) error {
	query := c.Query("q")
	if query == "" {
		return response.BadRequest(c, "query parameter 'q' is required")
	}

	page, perPage := parsePagination(c)

	results, err := h.service.UniversalSearch(c.Context(), query, page, perPage)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, results)
}

// SearchProducts handles GET /search/products.
func (h *SearchHandler) SearchProducts(c *fiber.Ctx) error {
	query := c.Query("q")
	if query == "" {
		return response.BadRequest(c, "query parameter 'q' is required")
	}

	page, perPage := parsePagination(c)

	result, err := h.service.SearchProducts(c.Context(), query, nil, page, perPage)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// SearchServices handles GET /search/services.
func (h *SearchHandler) SearchServices(c *fiber.Ctx) error {
	query := c.Query("q")
	if query == "" {
		return response.BadRequest(c, "query parameter 'q' is required")
	}

	page, perPage := parsePagination(c)

	result, err := h.service.SearchServices(c.Context(), query, nil, page, perPage)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// SearchVendors handles GET /search/vendors.
func (h *SearchHandler) SearchVendors(c *fiber.Ctx) error {
	query := c.Query("q")
	if query == "" {
		return response.BadRequest(c, "query parameter 'q' is required")
	}

	page, perPage := parsePagination(c)

	result, err := h.service.SearchVendors(c.Context(), query, nil, page, perPage)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, result)
}

// GetSuggestions handles GET /search/suggestions.
func (h *SearchHandler) GetSuggestions(c *fiber.Ctx) error {
	query := c.Query("q")
	if query == "" {
		return response.BadRequest(c, "query parameter 'q' is required")
	}

	suggestions, err := h.service.GetSuggestions(c.Context(), query)
	if err != nil {
		return response.Error(c, err)
	}

	return response.OK(c, suggestions)
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// parsePagination extracts page and per_page query parameters with defaults.
func parsePagination(c *fiber.Ctx) (int, int) {
	page := 1
	perPage := 20

	if p := c.Query("page"); p != "" {
		if n, err := strconv.Atoi(p); err == nil && n > 0 {
			page = n
		}
	}

	if pp := c.Query("per_page"); pp != "" {
		if n, err := strconv.Atoi(pp); err == nil && n > 0 {
			if n > 100 {
				n = 100
			}
			perPage = n
		}
	}

	return page, perPage
}
