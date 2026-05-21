.PHONY: all build build-api build-worker test lint fmt migrate-up migrate-down seed clean docker-up docker-down dev

# Default target
all: build

# Build binaries
build: build-api build-worker

build-api:
	@echo "Building API server..."
	@go build -o bin/api ./cmd/api

build-worker:
	@echo "Building Worker..."
	@go build -o bin/worker ./cmd/worker

# Development
dev:
	@echo "Starting development environment..."
	@docker-compose -f deploy/docker/docker-compose.yml up -d postgres redis kafka minio elasticsearch

dev-down:
	@echo "Stopping development environment..."
	@docker-compose -f deploy/docker/docker-compose.yml down

# Run
run-api:
	@go run ./cmd/api

run-worker:
	@go run ./cmd/worker

# Database
migrate-up:
	@go run ./cmd/migrate up

migrate-down:
	@go run ./cmd/migrate down

migrate-status:
	@go run ./cmd/migrate status

# Tests
test:
	@go test -v -race -count=1 ./...

test-integration:
	@go test -v -race -count=1 -tags=integration ./test/integration/...

# Code quality
fmt:
	@go fmt ./...

lint:
	@golangci-lint run ./...

vet:
	@go vet ./...

# Ent
ent-generate:
	@go generate ./internal/ent/schema/...

# Wire
wire:
	@wire ./internal/container/...

# Clean
clean:
	@rm -rf bin/

# Docker
docker-build:
	@docker build -f deploy/docker/Dockerfile.api -t social-api:latest .
	@docker build -f deploy/docker/Dockerfile.worker -t social-worker:latest .

# All checks before commit
check: fmt vet test
	@echo "All checks passed."
