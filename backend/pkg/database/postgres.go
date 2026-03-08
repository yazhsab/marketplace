package database

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/prabakarankannan/marketplace-backend/config"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// NewPostgresDB creates and returns a configured *gorm.DB instance using the
// provided DBConfig. It sets up connection pooling and configures the logger
// based on the current environment.
func NewPostgresDB(cfg config.DBConfig) (*gorm.DB, error) {
	gormLogger := logger.New(
		log.New(os.Stdout, "\r\n", log.LstdFlags),
		logger.Config{
			SlowThreshold:             200 * time.Millisecond,
			LogLevel:                  logger.Warn,
			IgnoreRecordNotFoundError: true,
			Colorful:                  true,
		},
	)

	// In development, use verbose logging to aid debugging and AutoMigrate workflows.
	env := os.Getenv("APP_ENV")
	if env == "" || env == "development" || env == "dev" {
		gormLogger = logger.New(
			log.New(os.Stdout, "\r\n", log.LstdFlags),
			logger.Config{
				SlowThreshold:             200 * time.Millisecond,
				LogLevel:                  logger.Info,
				IgnoreRecordNotFoundError: false,
				Colorful:                  true,
			},
		)
	}

	db, err := gorm.Open(postgres.Open(cfg.DSN()), &gorm.Config{
		Logger:                                   gormLogger,
		DisableForeignKeyConstraintWhenMigrating: false,
		PrepareStmt:                              true,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to postgres: %w", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("failed to get underlying sql.DB: %w", err)
	}

	// Connection pool settings tuned for a high-throughput marketplace backend.
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(1 * time.Hour)

	// Verify the connection is alive.
	if err := sqlDB.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping postgres: %w", err)
	}

	return db, nil
}
