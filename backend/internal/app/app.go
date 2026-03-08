package app

import (
	"context"
	"fmt"
	"log"

	"github.com/gofiber/fiber/v2"

	"github.com/prabakarankannan/marketplace-backend/config"
	"github.com/prabakarankannan/marketplace-backend/internal/middleware"
	"github.com/prabakarankannan/marketplace-backend/pkg/cache"
	"github.com/prabakarankannan/marketplace-backend/pkg/database"
	"github.com/prabakarankannan/marketplace-backend/pkg/firebase"
	"github.com/prabakarankannan/marketplace-backend/pkg/search"
	"github.com/prabakarankannan/marketplace-backend/pkg/sms"
	"github.com/prabakarankannan/marketplace-backend/pkg/storage"
	"gorm.io/gorm"
)

// App holds the top-level application dependencies and the Fiber HTTP server.
type App struct {
	Config      *config.Config
	DB          *gorm.DB
	Cache       *cache.CacheService
	Storage     *storage.StorageService
	Search      *search.SearchService
	Firebase    *firebase.FirebaseService
	SMSProvider sms.SMSProvider
	Fiber       *fiber.App
}

// NewApp initialises all infrastructure services and returns a ready-to-run App.
func NewApp(cfg *config.Config) (*App, error) {
	// -----------------------------------------------------------------
	// Fiber HTTP server
	// -----------------------------------------------------------------
	fiberApp := fiber.New(fiber.Config{
		AppName:   cfg.App.Name,
		BodyLimit: 10 * 1024 * 1024, // 10 MB
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}
			return c.Status(code).JSON(fiber.Map{
				"success": false,
				"message": err.Error(),
			})
		},
	})

	// -----------------------------------------------------------------
	// Postgres
	// -----------------------------------------------------------------
	db, err := database.NewPostgresDB(cfg.DB)
	if err != nil {
		return nil, fmt.Errorf("postgres: %w", err)
	}
	log.Println("[App] Connected to PostgreSQL")

	// -----------------------------------------------------------------
	// Redis cache
	// -----------------------------------------------------------------
	cacheService, err := cache.NewCacheService(cfg.Redis)
	if err != nil {
		return nil, fmt.Errorf("redis: %w", err)
	}
	log.Println("[App] Connected to Redis")

	// -----------------------------------------------------------------
	// MinIO storage
	// -----------------------------------------------------------------
	storageService, err := storage.NewStorageService(cfg.MinIO)
	if err != nil {
		return nil, fmt.Errorf("minio: %w", err)
	}
	if err := storageService.EnsureBucket(context.Background()); err != nil {
		return nil, fmt.Errorf("minio ensure bucket: %w", err)
	}
	log.Println("[App] MinIO storage ready")

	// -----------------------------------------------------------------
	// MeiliSearch
	// -----------------------------------------------------------------
	searchService, err := search.NewSearchService(cfg.Meili)
	if err != nil {
		return nil, fmt.Errorf("meilisearch: %w", err)
	}
	log.Println("[App] Connected to MeiliSearch")

	// -----------------------------------------------------------------
	// Firebase
	// -----------------------------------------------------------------
	firebaseService, err := firebase.NewFirebaseService(cfg.Firebase)
	if err != nil {
		return nil, fmt.Errorf("firebase: %w", err)
	}
	log.Println("[App] Firebase service initialised")

	// -----------------------------------------------------------------
	// SMS provider
	// -----------------------------------------------------------------
	smsProvider := sms.NewSMSProvider(cfg.SMS)
	log.Println("[App] SMS provider initialised")

	return &App{
		Config:      cfg,
		DB:          db,
		Cache:       cacheService,
		Storage:     storageService,
		Search:      searchService,
		Firebase:    firebaseService,
		SMSProvider: smsProvider,
		Fiber:       fiberApp,
	}, nil
}

// Run registers global middleware, mounts all module routes, and starts the
// HTTP server on the configured port.
func (a *App) Run() error {
	// Global middleware
	a.Fiber.Use(middleware.RequestID())
	a.Fiber.Use(middleware.Logger())
	a.Fiber.Use(middleware.Recovery())
	a.Fiber.Use(middleware.CORS())

	// Module routes
	a.registerRoutes()

	addr := fmt.Sprintf(":%d", a.Config.App.Port)
	log.Printf("[App] Starting server on %s", addr)
	return a.Fiber.Listen(addr)
}

// Shutdown gracefully shuts down the Fiber server and closes database
// connections.
func (a *App) Shutdown() error {
	log.Println("[App] Shutting down...")

	if err := a.Fiber.Shutdown(); err != nil {
		return fmt.Errorf("fiber shutdown: %w", err)
	}

	sqlDB, err := a.DB.DB()
	if err == nil {
		_ = sqlDB.Close()
	}

	log.Println("[App] Shutdown complete")
	return nil
}
