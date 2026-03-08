package media

import (
	"github.com/gofiber/fiber/v2"

	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
	"github.com/prabakarankannan/marketplace-backend/internal/common/response"
)

// Handler holds the HTTP handlers for media upload and management routes.
type Handler struct {
	service MediaService
}

// NewHandler creates a new media Handler with the given service.
func NewHandler(service MediaService) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes mounts media routes onto the given Fiber router group.
func (h *Handler) RegisterRoutes(r fiber.Router) {
	r.Post("/upload", h.Upload)
	r.Post("/upload/multiple", h.UploadMultiple)
	r.Delete("/:key", h.Delete)
}

// Upload handles a single file upload.
// POST /media/upload
func (h *Handler) Upload(c *fiber.Ctx) error {
	fileHeader, err := c.FormFile("file")
	if err != nil {
		return response.Error(c, apperrors.BadRequest("File is required"))
	}

	folder := c.FormValue("folder", "uploads")

	file, err := fileHeader.Open()
	if err != nil {
		return response.Error(c, apperrors.Internal("Failed to read uploaded file"))
	}
	defer file.Close()

	result, err := h.service.Upload(c.Context(), file, fileHeader, folder)
	if err != nil {
		return response.Error(c, err)
	}
	return response.Created(c, result)
}

// UploadMultiple handles multiple file uploads.
// POST /media/upload/multiple
func (h *Handler) UploadMultiple(c *fiber.Ctx) error {
	form, err := c.MultipartForm()
	if err != nil {
		return response.Error(c, apperrors.BadRequest("Invalid multipart form"))
	}

	files := form.File["files"]
	if len(files) == 0 {
		return response.Error(c, apperrors.BadRequest("At least one file is required"))
	}

	folder := c.FormValue("folder", "uploads")

	results := make([]UploadResponse, 0, len(files))
	for _, fileHeader := range files {
		file, err := fileHeader.Open()
		if err != nil {
			return response.Error(c, apperrors.Internal("Failed to read uploaded file"))
		}

		result, err := h.service.Upload(c.Context(), file, fileHeader, folder)
		file.Close()
		if err != nil {
			return response.Error(c, err)
		}
		results = append(results, *result)
	}

	return response.Created(c, results)
}

// Delete removes a file by its storage key.
// DELETE /media/:key
func (h *Handler) Delete(c *fiber.Ctx) error {
	key := c.Params("key")
	if key == "" {
		return response.Error(c, apperrors.BadRequest("File key is required"))
	}

	if err := h.service.Delete(c.Context(), key); err != nil {
		return response.Error(c, err)
	}
	return response.NoContent(c)
}
