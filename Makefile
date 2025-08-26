# Makefile for Gypsum Analysis API

# Variables
BINARY_NAME=gypsum-analysis-api
BUILD_DIR=build
DOCKER_IMAGE=gypsum-analysis-api

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod

# Build flags
LDFLAGS=-ldflags "-X main.Version=$(shell git describe --tags --always --dirty)"

.PHONY: all build clean test deps run docker-build docker-run install-fiji help

# Default target
all: clean deps test build

# Build the application
build:
	@echo "Building $(BINARY_NAME)..."
	$(GOBUILD) $(LDFLAGS) -o $(BINARY_NAME) .
	@echo "Build complete!"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	$(GOCLEAN)
	rm -f $(BINARY_NAME)
	rm -rf $(BUILD_DIR)
	@echo "Clean complete!"

# Run tests
test:
	@echo "Running tests..."
	$(GOTEST) -v ./...
	@echo "Tests complete!"

# Install dependencies
deps:
	@echo "Installing dependencies..."
	$(GOMOD) download
	$(GOMOD) tidy
	@echo "Dependencies installed!"

# Run the application
run: build
	@echo "Starting $(BINARY_NAME)..."
	./$(BINARY_NAME)

# Run in development mode
dev:
	@echo "Starting $(BINARY_NAME) in development mode..."
	$(GOCMD) run .

# Install Fiji (requires sudo)
install-fiji:
	@echo "Installing Fiji..."
	@chmod +x scripts/install-fiji.sh
	./scripts/install-fiji.sh

# Test the API
test-api:
	@echo "Testing API..."
	@chmod +x scripts/test-api.sh
	./scripts/test-api.sh

# Docker commands
docker-build:
	@echo "Building Docker image..."
	docker build -t $(DOCKER_IMAGE) .

docker-run:
	@echo "Running Docker container..."
	docker run -p 8080:8080 \
		-v /opt/fiji:/opt/fiji \
		-v /tmp/gypsum-analysis:/tmp/gypsum-analysis \
		$(DOCKER_IMAGE)

# Format code
fmt:
	@echo "Formatting code..."
	$(GOCMD) fmt ./...

# Lint code
lint:
	@echo "Linting code..."
	golangci-lint run

# Generate documentation
docs:
	@echo "Generating documentation..."
	godoc -http=:6060

# Create release build
release: clean deps test
	@echo "Creating release build..."
	mkdir -p $(BUILD_DIR)
	GOOS=linux GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 .
	GOOS=darwin GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64 .
	GOOS=windows GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe .
	@echo "Release builds complete!"

# Show help
help:
	@echo "Available targets:"
	@echo "  build        - Build the application"
	@echo "  clean        - Clean build artifacts"
	@echo "  test         - Run tests"
	@echo "  deps         - Install dependencies"
	@echo "  run          - Build and run the application"
	@echo "  dev          - Run in development mode"
	@echo "  install-fiji - Install Fiji (requires sudo)"
	@echo "  test-api     - Test the API endpoints"
	@echo "  docker-build - Build Docker image"
	@echo "  docker-run   - Run Docker container"
	@echo "  fmt          - Format code"
	@echo "  lint         - Lint code"
	@echo "  docs         - Generate documentation"
	@echo "  release      - Create release builds"
	@echo "  help         - Show this help message"
