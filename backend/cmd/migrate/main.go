package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"

	_ "github.com/lib/pq"
)

func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL environment variable is required")
	}

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		log.Fatalf("Failed to connect: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}
	fmt.Println("Connected to Neon PostgreSQL successfully!")

	// Find migrations directory
	migrationsDir := "migrations"
	if _, err := os.Stat(migrationsDir); os.IsNotExist(err) {
		migrationsDir = "backend/migrations"
	}

	files, err := filepath.Glob(filepath.Join(migrationsDir, "*.up.sql"))
	if err != nil {
		log.Fatalf("Failed to find migration files: %v", err)
	}

	sort.Strings(files)
	fmt.Printf("Found %d migration files\n\n", len(files))

	for _, file := range files {
		name := filepath.Base(file)
		content, err := os.ReadFile(file)
		if err != nil {
			log.Fatalf("Failed to read %s: %v", name, err)
		}

		sql := string(content)
		// Skip empty files
		if strings.TrimSpace(sql) == "" {
			fmt.Printf("  SKIP  %s (empty)\n", name)
			continue
		}

		_, err = db.Exec(sql)
		if err != nil {
			// Check if it's a "already exists" error — safe to skip
			if strings.Contains(err.Error(), "already exists") {
				fmt.Printf("  SKIP  %s (already applied)\n", name)
				continue
			}
			log.Fatalf("  FAIL  %s: %v", name, err)
		}
		fmt.Printf("  OK    %s\n", name)
	}

	fmt.Println("\nAll migrations applied successfully!")

	// Verify tables
	rows, err := db.Query(`
		SELECT table_name
		FROM information_schema.tables
		WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
		ORDER BY table_name
	`)
	if err != nil {
		log.Fatalf("Failed to list tables: %v", err)
	}
	defer rows.Close()

	fmt.Println("\nTables in database:")
	count := 0
	for rows.Next() {
		var name string
		rows.Scan(&name)
		count++
		fmt.Printf("  %2d. %s\n", count, name)
	}
	fmt.Printf("\nTotal: %d tables\n", count)
}
