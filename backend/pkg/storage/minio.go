package storage

import (
	"context"
	"fmt"
	"io"
	"net/url"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"github.com/prabakarankannan/marketplace-backend/config"
)

// StorageService provides object storage operations backed by MinIO (or any
// S3-compatible store).
type StorageService struct {
	client *minio.Client
	bucket string
}

// NewStorageService creates a new StorageService connected to the MinIO
// instance described by cfg. Works with any S3-compatible provider including
// MinIO, Cloudflare R2, AWS S3, etc.
func NewStorageService(cfg config.MinIOConfig) (*StorageService, error) {
	opts := &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.AccessKey, cfg.SecretKey, ""),
		Secure: cfg.UseSSL,
	}

	// Cloudflare R2 requires a specific region to be set
	if cfg.Region != "" {
		opts.Region = cfg.Region
	}

	client, err := minio.New(cfg.Endpoint, opts)
	if err != nil {
		return nil, fmt.Errorf("failed to create storage client: %w", err)
	}

	return &StorageService{
		client: client,
		bucket: cfg.Bucket,
	}, nil
}

// EnsureBucket creates the configured bucket if it does not already exist.
// For cloud providers like Cloudflare R2, buckets are created via their dashboard,
// so this may be a no-op. Errors are logged but not fatal for R2 compatibility.
func (s *StorageService) EnsureBucket(ctx context.Context) error {
	exists, err := s.client.BucketExists(ctx, s.bucket)
	if err != nil {
		// R2 and some providers may not support BucketExists; log and continue
		fmt.Printf("[Storage] Warning: could not check bucket %q (may be normal for R2): %v\n", s.bucket, err)
		return nil
	}

	if !exists {
		if err := s.client.MakeBucket(ctx, s.bucket, minio.MakeBucketOptions{}); err != nil {
			// R2 buckets are created via dashboard; log and continue
			fmt.Printf("[Storage] Warning: could not create bucket %q (may be normal for R2): %v\n", s.bucket, err)
			return nil
		}
	}

	return nil
}

// Upload stores an object in the configured bucket. objectName is the full key
// (e.g. "products/images/abc.jpg"). contentType should be a valid MIME type.
func (s *StorageService) Upload(ctx context.Context, objectName string, reader io.Reader, size int64, contentType string) error {
	opts := minio.PutObjectOptions{
		ContentType: contentType,
	}

	// When size is unknown (e.g. streaming), pass -1 to let MinIO handle chunked upload.
	if size <= 0 {
		size = -1
	}

	_, err := s.client.PutObject(ctx, s.bucket, objectName, reader, size, opts)
	if err != nil {
		return fmt.Errorf("failed to upload %q: %w", objectName, err)
	}

	return nil
}

// Delete removes an object from the configured bucket.
func (s *StorageService) Delete(ctx context.Context, objectName string) error {
	err := s.client.RemoveObject(ctx, s.bucket, objectName, minio.RemoveObjectOptions{})
	if err != nil {
		return fmt.Errorf("failed to delete %q: %w", objectName, err)
	}

	return nil
}

// GetPresignedURL returns a pre-signed URL that grants temporary read access to
// the specified object. The URL is valid for the given expiry duration.
func (s *StorageService) GetPresignedURL(ctx context.Context, objectName string, expiry time.Duration) (string, error) {
	reqParams := make(url.Values)

	presignedURL, err := s.client.PresignedGetObject(ctx, s.bucket, objectName, expiry, reqParams)
	if err != nil {
		return "", fmt.Errorf("failed to generate presigned URL for %q: %w", objectName, err)
	}

	return presignedURL.String(), nil
}
