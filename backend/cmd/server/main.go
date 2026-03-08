package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/prabakarankannan/marketplace-backend/config"
	"github.com/prabakarankannan/marketplace-backend/internal/app"
)

func main() {
	// -----------------------------------------------------------------
	// Load configuration
	// -----------------------------------------------------------------
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// -----------------------------------------------------------------
	// Create application
	// -----------------------------------------------------------------
	application, err := app.NewApp(cfg)
	if err != nil {
		log.Fatalf("Failed to initialise application: %v", err)
	}

	// -----------------------------------------------------------------
	// Graceful shutdown
	// -----------------------------------------------------------------
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-quit
		log.Println("Received shutdown signal")
		if err := application.Shutdown(); err != nil {
			log.Printf("Error during shutdown: %v", err)
		}
	}()

	// -----------------------------------------------------------------
	// Start server (blocks until shutdown)
	// -----------------------------------------------------------------
	if err := application.Run(); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}
