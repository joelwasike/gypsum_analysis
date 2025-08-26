#!/bin/bash

# Gypsum Analysis API - Image Upload Examples
# This script demonstrates how to upload images using form data

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Configuration
API_BASE_URL="http://localhost:8080"
TEST_IMAGE="testdata/test_gypsum.jpg"

# Check if API is running
check_api() {
    if curl -s "$API_BASE_URL/health" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Wait for API to be ready
wait_for_api() {
    print_status "Waiting for API to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if check_api; then
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

# Upload image and get analysis
upload_and_analyze() {
    local image_path=$1
    
    if [ ! -f "$image_path" ]; then
        print_error "Image file not found: $image_path"
        return 1
    fi
    
    print_status "Uploading image: $image_path"
    
    # Upload image
    local upload_response=$(curl -s -X POST \
        -F "image=@$image_path" \
        "$API_BASE_URL/api/v1/analysis/gypsum")
    
    # Extract analysis ID
    local analysis_id=$(echo "$upload_response" | jq -r '.analysis_id' 2>/dev/null)
    local status=$(echo "$upload_response" | jq -r '.status' 2>/dev/null)
    
    if [ "$analysis_id" = "null" ] || [ "$status" != "processing" ]; then
        print_error "Upload failed"
        echo "Response: $upload_response"
        return 1
    fi
    
    print_status "Analysis started with ID: $analysis_id"
    echo "Upload response: $upload_response"
    
    # Wait for analysis to complete
    print_status "Waiting for analysis to complete..."
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        local status_response=$(curl -s "$API_BASE_URL/api/v1/analysis/status/$analysis_id")
        local analysis_status=$(echo "$status_response" | jq -r '.status' 2>/dev/null)
        
        case $analysis_status in
            "completed")
                print_status "Analysis completed successfully!"
                echo "Results:"
                echo "$status_response" | jq '.'
                return 0
                ;;
            "failed")
                print_error "Analysis failed"
                local error=$(echo "$status_response" | jq -r '.error' 2>/dev/null)
                echo "Error: $error"
                return 1
                ;;
            "processing"|"pending")
                echo -n "."
                sleep 2
                attempts=$((attempts + 1))
                ;;
            *)
                print_error "Unknown status: $analysis_status"
                return 1
                ;;
        esac
    done
    
    print_error "Analysis timed out after $((max_attempts * 2)) seconds"
    return 1
}

# Main function
main() {
    print_status "Gypsum Analysis API - Image Upload Examples"
    echo
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq is required for this script. Please install it first."
        print_status "Install with: sudo apt-get install jq"
        exit 1
    fi
    
    # Wait for API
    if ! wait_for_api; then
        exit 1
    fi
    
    echo
    
    # Example 1: Upload test image
    print_status "Example 1: Uploading test image"
    if upload_and_analyze "$TEST_IMAGE"; then
        print_status "Example 1 completed successfully!"
    else
        print_error "Example 1 failed"
    fi
    
    echo
    
    # Example 2: Show different upload methods
    print_status "Example 2: Different upload methods"
    echo
    echo "Method 1 - Using curl:"
    echo "curl -X POST $API_BASE_URL/api/v1/analysis/gypsum \\"
    echo "  -F \"image=@your_image.jpg\""
    echo
    echo "Method 2 - Using HTML form:"
    echo "Open upload_form.html in your browser"
    echo
    echo "Method 3 - Using Python:"
    echo "python3 -c \""
    echo "import requests"
    echo "with open('your_image.jpg', 'rb') as f:"
    echo "    response = requests.post('$API_BASE_URL/api/v1/analysis/gypsum', files={'image': f})"
    echo "    print(response.json())"
    echo "\""
    echo
    echo "Method 4 - Using JavaScript:"
    echo "const formData = new FormData();"
    echo "formData.append('image', fileInput.files[0]);"
    echo "fetch('$API_BASE_URL/api/v1/analysis/gypsum', {"
    echo "    method: 'POST',"
    echo "    body: formData"
    echo "});"
    
    echo
    print_status "Upload examples completed!"
}

# Run main function
main "$@"
