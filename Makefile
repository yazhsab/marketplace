.PHONY: help dev stop backend admin migrate seed test lint

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Infrastructure
infra-up: ## Start infrastructure services (postgres, redis, meilisearch, minio)
	docker-compose up -d postgres redis meilisearch minio

infra-down: ## Stop infrastructure services
	docker-compose down

infra-logs: ## View infrastructure logs
	docker-compose logs -f postgres redis meilisearch minio

# Backend
backend-dev: ## Run Go backend with hot reload
	cd backend && go run ./cmd/server

backend-build: ## Build Go backend binary
	cd backend && go build -o bin/server ./cmd/server

backend-test: ## Run Go backend tests
	cd backend && go test ./... -v

backend-lint: ## Lint Go code
	cd backend && golangci-lint run ./...

# Database
migrate-up: ## Run all database migrations
	cd backend && go run ./cmd/server migrate up

migrate-down: ## Rollback last migration
	cd backend && go run ./cmd/server migrate down

migrate-create: ## Create new migration (usage: make migrate-create name=create_xxx)
	cd backend && migrate create -ext sql -dir migrations -seq $(name)

seed: ## Seed database with sample data
	cd backend && go run ./scripts/seed.go

# Admin Panel
admin-dev: ## Run NextJS admin in development
	cd admin && npm run dev

admin-build: ## Build NextJS admin
	cd admin && npm run build

# Flutter
customer-app: ## Run customer Flutter app
	cd apps/customer_app && flutter run

vendor-app: ## Run vendor Flutter app
	cd apps/vendor_app && flutter run

# Docker
up: ## Start all services with Docker
	docker-compose up -d --build

down: ## Stop all Docker services
	docker-compose down

logs: ## View all Docker logs
	docker-compose logs -f

# Development
dev: infra-up ## Start full development environment
	@echo "Infrastructure started. Run 'make backend-dev' and 'make admin-dev' in separate terminals."
