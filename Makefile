.PHONY: all help dev dev-down gen gen-watch build build-api build-worker build-app migrate migrate-down seed run-api run-worker run-app run-web test test-api test-app lint fmt clean

# Default target
all: help

# Help
help:
	@echo "Social App - Development Commands"
	@echo "================================="
	@echo ""
	@echo "Infrastructure:"
	@echo "  make dev          Start Docker infrastructure (postgres, redis, kafka, minio, elasticsearch)"
	@echo "  make dev-down     Stop Docker infrastructure"
	@echo ""
	@echo "Build:"
	@echo "  make build        Build all (backend + frontend)"
	@echo "  make build-api    Build Go API binary"
	@echo "  make build-worker Build Go Worker binary"
	@echo "  make build-app    Build Flutter app"
	@echo ""
	@echo "Database:"
	@echo "  make migrate      Run database migrations"
	@echo "  make migrate-down Run database rollback (ent auto-migration limited)"
	@echo "  make seed         Seed database with demo data"
	@echo ""
	@echo "Run:"
	@echo "  make run-api      Run API server (go run)"
	@echo "  make run-worker   Run Worker (go run)"
	@echo "  make run-app      Run Flutter app"
	@echo "  make run          Run API + Worker in background"
	@echo ""
	@echo "Test:"
	@echo "  make test         Run all tests"
	@echo "  make test-api     Run backend tests"
	@echo "  make test-app     Run Flutter tests"
	@echo ""
	@echo "Code Generation:"
	@echo "  make gen          Generate Riverpod code (build_runner)"
	@echo "  make gen-watch    Watch mode for Riverpod code generation"
	@echo ""
	@echo "Quality:"
	@echo "  make fmt          Format all code"
	@echo "  make lint         Lint backend code"
	@echo ""
	@echo "Clean:"
	@echo "  make clean        Clean build artifacts"
	@echo "  make clean-all    Clean everything including Docker volumes"
	@echo ""

# =============================================================================
# Infrastructure
# =============================================================================

dev:
	@echo "Starting development infrastructure..."
	@cd server && docker-compose -f deploy/docker/docker-compose.yml up -d --no-build postgres redis kafka minio elasticsearch
	@echo "Waiting for services to be ready..."
	@sleep 5
	@echo "Infrastructure ready:"
	@echo "  PostgreSQL:    localhost:5432"
	@echo "  Redis:         localhost:6379"
	@echo "  Kafka:         localhost:9092"
	@echo "  MinIO:         localhost:9000 (console: 9001)"
	@echo "  Elasticsearch: localhost:9200"

dev-down:
	@echo "Stopping development infrastructure..."
	@cd server && docker-compose -f deploy/docker/docker-compose.yml down

dev-logs:
	@cd server && docker-compose -f deploy/docker/docker-compose.yml logs -f

# =============================================================================
# Build
# =============================================================================

build: build-api build-worker build-app

# =============================================================================
# Code Generation
# =============================================================================

gen:
	@echo "Running Riverpod code generation..."
	@cd app && dart run build_runner build --delete-conflicting-outputs

gen-watch:
	@echo "Starting Riverpod code generation watch mode..."
	@cd app && dart run build_runner watch --delete-conflicting-outputs

# =============================================================================
# Build
# =============================================================================

build-api:
	@echo "Building API server..."
	@cd server && go build -o bin/api ./cmd/api

build-worker:
	@echo "Building Worker..."
	@cd server && go build -o bin/worker ./cmd/worker

build-app:
	@echo "Building Flutter app..."
	@cd app && flutter build apk --debug

# =============================================================================
# Database
# =============================================================================

migrate:
	@echo "Running database migrations..."
	@cd server && go run ./cmd/migrate up

seed:
	@echo "Seeding database with demo data..."
	@cd server && go run ./cmd/seed

migrate-down:
	@echo "Database rollback not fully supported with ent auto-migration"
	@cd server && go run ./cmd/migrate down

migrate-status:
	@cd server && go run ./cmd/migrate status

# =============================================================================
# Run
# =============================================================================

run-api:
	@cd server && go run ./cmd/api

run-worker:
	@cd server && go run ./cmd/worker

run-app:
	@cd app && flutter run

run-web:
	@echo "Running Flutter Web (CanvasKit, fonts cached after first load)..."
	@cd app && flutter run -d chrome

run:
	@echo "Starting API and Worker in background..."
	@cd server && go run ./cmd/api > api.log 2>&1 & echo "API PID: $$!"
	@cd server && go run ./cmd/worker > worker.log 2>&1 & echo "Worker PID: $$!"
	@echo "Logs: server/api.log, server/worker.log"

stop:
	@echo "Stopping API and Worker..."
	@pkill -f "go run ./cmd/api" 2>/dev/null || true
	@pkill -f "go run ./cmd/worker" 2>/dev/null || true
	@echo "Stopped"

# =============================================================================
# Test
# =============================================================================

test: test-api test-app

test-api:
	@echo "Running backend tests..."
	@cd server && go test -v -race -count=1 ./...

test-app:
	@echo "Running Flutter tests..."
	@cd app && flutter test

# =============================================================================
# Code Quality
# =============================================================================

fmt:
	@echo "Formatting Go code..."
	@cd server && go fmt ./...
	@echo "Formatting Flutter code..."
	@cd app && dart format lib/

lint:
	@echo "Linting Go code..."
	@cd server && go vet ./...
	@echo "Analyzing Flutter code..."
	@cd app && flutter analyze --no-pub

# =============================================================================
# Clean
# =============================================================================

clean:
	@echo "Cleaning build artifacts..."
	@cd server && rm -rf bin/
	@cd app && flutter clean

clean-all: clean dev-down
	@echo "Removing Docker volumes..."
	@cd server && docker-compose -f deploy/docker/docker-compose.yml down -v
	@echo "Everything cleaned"

# =============================================================================
# Full workflow
# =============================================================================

setup: dev migrate
	@echo "Development environment ready!"
	@echo "Run 'make run-api' to start the API server"
	@echo "Run 'make run-app' to start the Flutter app"
