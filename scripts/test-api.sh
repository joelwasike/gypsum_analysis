#!/bin/bash

# Test Script for Gypsum Analysis API
# This script tests the API endpoints with sample data

set -e

# Configuration
API_BASE_URL="http://localhost:8080"
TEST_IMAGE_DIR="testdata"
SAMPLE_IMAGE_URL="https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Gypsum_crystal.jpg/800px-Gypsum_crystal.jpg"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Function to check if API is running
check_api_running() {
    if curl -s "$API_BASE_URL/health" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to wait for API to be ready
wait_for_api() {
    print_status "Waiting for API to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if check_api_running; then
            print_status "API is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "API failed to start within $((max_attempts * 2)) seconds"
    return 1
}

# Function to download sample image
download_sample_image() {
    if [ ! -d "$TEST_IMAGE_DIR" ]; then
        mkdir -p "$TEST_IMAGE_DIR"
    fi
    
    local sample_image="$TEST_IMAGE_DIR/sample_gypsum.jpg"
    
    if [ ! -f "$sample_image" ]; then
        print_status "Downloading sample gypsum image..."
        curl -L -o "$sample_image" "$SAMPLE_IMAGE_URL"
    else
        print_status "Sample image already exists"
    fi
    
    echo "$sample_image"
}

# Function to test health endpoint
test_health() {
    print_header "Testing Health Endpoint"
    
    local response=$(curl -s "$API_BASE_URL/health")
    local status=$(echo "$response" | jq -r '.status' 2>/dev/null || echo "unknown")
    
    if [ "$status" = "healthy" ]; then
        print_status "Health check passed"
        echo "Response: $response"
    else
        print_error "Health check failed"
        echo "Response: $response"
        return 1
    fi
}

# Function to test gypsum analysis
test_gypsum_analysis() {
    print_header "Testing Gypsum Analysis"
    
    local sample_image=$(download_sample_image)
    
    print_status "Uploading sample image for analysis..."
    local response=$(curl -s -X POST \
        -F "image=@$sample_image" \
        "$API_BASE_URL/api/v1/analysis/gypsum")
    
    local analysis_id=$(echo "$response" | jq -r '.analysis_id' 2>/dev/null)
    local status=$(echo "$response" | jq -r '.status' 2>/dev/null)
    
    if [ "$analysis_id" != "null" ] && [ "$status" = "processing" ]; then
        print_status "Analysis started successfully"
        echo "Analysis ID: $analysis_id"
        echo "Response: $response"
        
        # Wait for analysis to complete
        wait_for_analysis_completion "$analysis_id"
    else
        print_error "Failed to start analysis"
        echo "Response: $response"
        return 1
    fi
}

# Function to wait for analysis completion
wait_for_analysis_completion() {
    local analysis_id=$1
    local max_attempts=60
    local attempt=1
    
    print_status "Waiting for analysis to complete..."
    
    while [ $attempt -le $max_attempts ]; do
        local response=$(curl -s "$API_BASE_URL/api/v1/analysis/status/$analysis_id")
        local status=$(echo "$response" | jq -r '.status' 2>/dev/null)
        
        case $status in
            "completed")
                print_status "Analysis completed successfully!"
                echo "Results:"
                echo "$response" | jq '.'
                return 0
                ;;
            "failed")
                print_error "Analysis failed"
                echo "Error: $(echo "$response" | jq -r '.error')"
                return 1
                ;;
            "processing"|"pending")
                echo -n "."
                sleep 5
                attempt=$((attempt + 1))
                ;;
            *)
                print_error "Unknown status: $status"
                return 1
                ;;
        esac
    done
    
    print_error "Analysis did not complete within $((max_attempts * 5)) seconds"
    return 1
}

# Function to test invalid requests
test_invalid_requests() {
    print_header "Testing Invalid Requests"
    
    # Test without image file
    print_status "Testing POST without image file..."
    local response=$(curl -s -X POST "$API_BASE_URL/api/v1/analysis/gypsum")
    local error=$(echo "$response" | jq -r '.error' 2>/dev/null)
    
    if [ "$error" != "null" ]; then
        print_status "Correctly rejected request without image"
    else
        print_warning "Should have rejected request without image"
    fi
    
    # Test invalid analysis ID
    print_status "Testing invalid analysis ID..."
    response=$(curl -s "$API_BASE_URL/api/v1/analysis/status/invalid-id")
    error=$(echo "$response" | jq -r '.error' 2>/dev/null)
    
    if [ "$error" != "null" ]; then
        print_status "Correctly handled invalid analysis ID"
    else
        print_warning "Should have rejected invalid analysis ID"
    fi
}

# Main test function
main() {
    print_status "Starting Gypsum Analysis API Tests"
    echo
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq is required for testing. Please install it first."
        print_status "Install with: sudo apt-get install jq"
        exit 1
    fi
    
    # Wait for API to be ready
    if ! wait_for_api; then
        exit 1
    fi
    
    echo
    
    # Run tests
    local tests_passed=0
    local tests_failed=0
    
    # Test health endpoint
    if test_health; then
        tests_passed=$((tests_passed + 1))
    else
        tests_failed=$((tests_failed + 1))
    fi
    
    echo
    
    # Test gypsum analysis
    if test_gypsum_analysis; then
        tests_passed=$((tests_passed + 1))
    else
        tests_failed=$((tests_failed + 1))
    fi
    
    echo
    
    # Test invalid requests
    if test_invalid_requests; then
        tests_passed=$((tests_passed + 1))
    else
        tests_failed=$((tests_failed + 1))
    fi
    
    echo
    print_status "Test Results:"
    print_status "Tests passed: $tests_passed"
    if [ $tests_failed -gt 0 ]; then
        print_error "Tests failed: $tests_failed"
        exit 1
    else
        print_status "All tests passed!"
    fi
}

# Run main function
main "$@"
