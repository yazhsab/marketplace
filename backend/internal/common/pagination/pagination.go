package pagination

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
)

const (
	defaultPage    = 1
	defaultPerPage = 20
	maxPerPage     = 100
)

// Params holds the parsed and validated pagination parameters from a request.
type Params struct {
	Page    int `json:"page"`
	PerPage int `json:"per_page"`
}

// Offset returns the SQL-style offset derived from the current page and per-page values.
func (p Params) Offset() int {
	return (p.Page - 1) * p.PerPage
}

// FromQuery extracts pagination parameters from the request query string.
// It applies defaults for missing values and clamps per_page to the allowed range.
func FromQuery(c *fiber.Ctx) Params {
	page := queryInt(c, "page", defaultPage)
	perPage := queryInt(c, "per_page", defaultPerPage)

	if page < 1 {
		page = defaultPage
	}
	if perPage < 1 {
		perPage = defaultPerPage
	}
	if perPage > maxPerPage {
		perPage = maxPerPage
	}

	return Params{
		Page:    page,
		PerPage: perPage,
	}
}

// Result is a generic container for paginated query results.
// Items holds the current page of records and Total is the unfiltered row count.
type Result[T any] struct {
	Items []T   `json:"items"`
	Total int64 `json:"total"`
}

// ToMeta converts the result into a response.Meta using the given pagination params.
func (r Result[T]) ToMeta(params Params) *response.Meta {
	totalPages := 0
	if params.PerPage > 0 {
		totalPages = int((r.Total + int64(params.PerPage) - 1) / int64(params.PerPage))
	}

	return &response.Meta{
		Page:       params.Page,
		PerPage:    params.PerPage,
		Total:      int(r.Total),
		TotalPages: totalPages,
	}
}

// queryInt reads a query parameter as an integer, returning the fallback if
// the parameter is missing or cannot be parsed.
func queryInt(c *fiber.Ctx, key string, fallback int) int {
	val := c.Query(key)
	if val == "" {
		return fallback
	}
	n, err := strconv.Atoi(val)
	if err != nil {
		return fallback
	}
	return n
}
