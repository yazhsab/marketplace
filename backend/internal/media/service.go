package media

import (
	"context"
	"fmt"
	"mime/multipart"
	"path/filepath"
	"strings"

	"github.com/google/uuid"

	"github.com/prabakarankannan/marketplace-backend/config"
	apperrors "github.com/prabakarankannan/marketplace-backend/internal/common/errors"
	"github.com/prabakarankannan/marketplace-backend/pkg/storage"
)

// Allowed MIME types and their corresponding extensions.
var allowedTypes = map[string]string{
	"image/jpeg":      ".jpg",
	"image/jpg":       ".jpg",
	"image/png":       ".png",
	"image/webp":      ".webp",
	"application/pdf": ".pdf",
}

const (
	maxImageSize = 5 << 20  // 5 MB
	maxPDFSize   = 10 << 20 // 10 MB
)

// MediaService defines the business-logic contract for file upload operations.
type MediaService interface {
	Upload(ctx context.Context, file multipart.File, header *multipart.FileHeader, folder string) (*UploadResponse, error)
	Delete(ctx context.Context, key string) error
	GetURL(ctx context.Context, key string) (string, error)
}

// mediaService is the default implementation of MediaService.
type mediaService struct {
	storage *storage.StorageService
	cfg     config.MinIOConfig
}

// NewMediaService creates a new MediaService with the given storage backend and config.
func NewMediaService(s *storage.StorageService, cfg config.MinIOConfig) MediaService {
	return &mediaService{
		storage: s,
		cfg:     cfg,
	}
}

func (s *mediaService) Upload(ctx context.Context, file multipart.File, header *multipart.FileHeader, folder string) (*UploadResponse, error) {
	contentType := header.Header.Get("Content-Type")

	ext, ok := allowedTypes[strings.ToLower(contentType)]
	if !ok {
		return nil, apperrors.BadRequest("Unsupported file type. Allowed: jpg, jpeg, png, webp, pdf")
	}

	// Validate file size based on type.
	if ext == ".pdf" {
		if header.Size > maxPDFSize {
			return nil, apperrors.BadRequest("PDF file size must not exceed 10 MB")
		}
	} else {
		if header.Size > maxImageSize {
			return nil, apperrors.BadRequest("Image file size must not exceed 5 MB")
		}
	}

	// Generate a unique object key: {folder}/{uuid}.{ext}
	key := fmt.Sprintf("%s/%s%s", folder, uuid.New().String(), ext)

	if err := s.storage.Upload(ctx, key, file, header.Size, contentType); err != nil {
		return nil, apperrors.Internal("Failed to upload file")
	}

	url := s.buildURL(key)

	return &UploadResponse{
		Key: key,
		URL: url,
	}, nil
}

func (s *mediaService) Delete(ctx context.Context, key string) error {
	if err := s.storage.Delete(ctx, key); err != nil {
		return apperrors.Internal("Failed to delete file")
	}
	return nil
}

func (s *mediaService) GetURL(ctx context.Context, key string) (string, error) {
	_ = ctx
	url := s.buildURL(key)
	return url, nil
}

// buildURL constructs the public URL for an object in the configured bucket.
func (s *mediaService) buildURL(key string) string {
	scheme := "http"
	if s.cfg.UseSSL {
		scheme = "https"
	}

	// Clean the key to prevent path traversal.
	key = filepath.Clean(key)

	return fmt.Sprintf("%s://%s/%s/%s", scheme, s.cfg.Endpoint, s.cfg.Bucket, key)
}
