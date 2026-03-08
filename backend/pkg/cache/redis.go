package cache

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/prabakarankannan/marketplace-backend/config"
	"github.com/redis/go-redis/v9"
)

// ErrCacheMiss is returned when a key is not found in the cache.
var ErrCacheMiss = errors.New("cache: key not found")

// CacheService wraps a redis.Client and provides convenient typed
// cache operations with JSON serialization.
type CacheService struct {
	client *redis.Client
}

// NewCacheService creates a new CacheService connected to the Redis instance
// described by cfg. It pings the server to verify connectivity.
func NewCacheService(cfg config.RedisConfig) (*CacheService, error) {
	opts := &redis.Options{
		Addr:         cfg.Addr(),
		Password:     cfg.Password,
		DB:           cfg.DB,
		PoolSize:     50,
		MinIdleConns: 10,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
	}

	// Enable TLS for cloud Redis providers (Upstash, etc.)
	if cfg.UseTLS {
		opts.TLSConfig = &tls.Config{
			MinVersion: tls.VersionTLS12,
		}
	}

	client := redis.NewClient(opts)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("failed to connect to redis at %s: %w", cfg.Addr(), err)
	}

	return &CacheService{client: client}, nil
}

// Get retrieves the value stored at key and JSON-unmarshals it into dest.
// Returns ErrCacheMiss if the key does not exist.
func (s *CacheService) Get(ctx context.Context, key string, dest interface{}) error {
	val, err := s.client.Get(ctx, key).Bytes()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return ErrCacheMiss
		}
		return fmt.Errorf("cache get %q: %w", key, err)
	}

	if err := json.Unmarshal(val, dest); err != nil {
		return fmt.Errorf("cache unmarshal %q: %w", key, err)
	}

	return nil
}

// Set stores a value under key with the given TTL. The value is JSON-marshaled
// before storage. A TTL of 0 means the key will not expire.
func (s *CacheService) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	data, err := json.Marshal(value)
	if err != nil {
		return fmt.Errorf("cache marshal %q: %w", key, err)
	}

	if err := s.client.Set(ctx, key, data, ttl).Err(); err != nil {
		return fmt.Errorf("cache set %q: %w", key, err)
	}

	return nil
}

// Delete removes one or more keys from the cache.
func (s *CacheService) Delete(ctx context.Context, keys ...string) error {
	if len(keys) == 0 {
		return nil
	}

	if err := s.client.Del(ctx, keys...).Err(); err != nil {
		return fmt.Errorf("cache delete: %w", err)
	}

	return nil
}

// Invalidate deletes all keys matching the given glob pattern.
// Example: Invalidate(ctx, "products:*") removes all product cache entries.
func (s *CacheService) Invalidate(ctx context.Context, pattern string) error {
	var cursor uint64
	for {
		keys, nextCursor, err := s.client.Scan(ctx, cursor, pattern, 100).Result()
		if err != nil {
			return fmt.Errorf("cache invalidate scan %q: %w", pattern, err)
		}

		if len(keys) > 0 {
			if err := s.client.Del(ctx, keys...).Err(); err != nil {
				return fmt.Errorf("cache invalidate delete %q: %w", pattern, err)
			}
		}

		cursor = nextCursor
		if cursor == 0 {
			break
		}
	}

	return nil
}

// Exists returns true if the key exists in the cache.
func (s *CacheService) Exists(ctx context.Context, key string) bool {
	n, err := s.client.Exists(ctx, key).Result()
	if err != nil {
		return false
	}
	return n > 0
}

// Client returns the underlying *redis.Client for advanced operations
// that are not covered by CacheService methods.
func (s *CacheService) Client() *redis.Client {
	return s.client
}
