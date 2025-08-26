#!/bin/bash

# Demo Script for Gypsum Analysis API
# This script demonstrates the API functionality with a mock Fiji installation

set -e

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
    echo -e "${BLUE}[DEMO]${NC} $1"
}

# Function to create mock Fiji executable
create_mock_fiji() {
    print_status "Creating mock Fiji executable for demo..."
    
    # Create mock Fiji directory
    sudo mkdir -p /opt/fiji/Fiji.app
    
    # Create mock ImageJ executable
    cat > /tmp/mock_imagej.sh << 'EOF'
#!/bin/bash
# Mock ImageJ executable for demo purposes
echo "Mock ImageJ running..."
echo "Processing image: $1"
echo "ANALYSIS_RESULTS_START"
echo "purity_percentage:85.5"
echo "gypsum_content:85.5"
echo "impurity_content:14.5"
echo "particle_count:45"
echo "total_area:125000"
echo "image_area:150000"
echo "threshold_value:128.5"
echo "ANALYSIS_RESULTS_END"
exit 0
EOF
    
    sudo cp /tmp/mock_imagej.sh /opt/fiji/Fiji.app/ImageJ-linux64
    sudo chmod +x /opt/fiji/Fiji.app/ImageJ-linux64
    rm /tmp/mock_imagej.sh
    
    print_status "Mock Fiji created successfully!"
}

# Function to cleanup mock Fiji
cleanup_mock_fiji() {
    print_status "Cleaning up mock Fiji..."
    sudo rm -rf /opt/fiji
}

# Function to start API
start_api() {
    print_status "Starting Gypsum Analysis API..."
    ./gypsum-analysis-api &
    API_PID=$!
    
    # Wait for API to start
    sleep 5
    
    # Check if API is running
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        print_status "API started successfully!"
    else
        print_error "Failed to start API"
        exit 1
    fi
}

# Function to stop API
stop_api() {
    if [ ! -z "$API_PID" ]; then
        print_status "Stopping API..."
        kill $API_PID 2>/dev/null || true
        wait $API_PID 2>/dev/null || true
    fi
}

# Function to create sample image
create_sample_image() {
    print_status "Creating sample gypsum image..."
    
    # Create a simple test image using ImageMagick or fallback to a text file
    if command -v convert >/dev/null 2>&1; then
        convert -size 200x200 xc:white -fill gray -draw "circle 100,100 50,50" testdata/sample_gypsum.jpg
    else
        # Create a simple text file as fallback
        mkdir -p testdata
        echo "Mock gypsum image data" > testdata/sample_gypsum.jpg
    fi
    
    print_status "Sample image created!"
}

# Function to demonstrate API endpoints
demonstrate_api() {
    print_header "Demonstrating API Endpoints"
    
    # Test health endpoint
    print_status "Testing health endpoint..."
    curl -s http://localhost:8080/health | jq .
    echo
    
    # Test gypsum analysis
    print_status "Testing gypsum analysis..."
    if [ -f "testdata/sample_gypsum.jpg" ]; then
        response=$(curl -s -X POST \
            -F "image=@testdata/sample_gypsum.jpg" \
            http://localhost:8080/api/v1/analysis/gypsum)
        
        echo "Analysis response:"
        echo "$response" | jq .
        
        # Extract analysis ID
        analysis_id=$(echo "$response" | jq -r '.analysis_id')
        
        if [ "$analysis_id" != "null" ]; then
            print_status "Waiting for analysis to complete..."
            
            # Wait for analysis to complete
            for i in {1..30}; do
                status_response=$(curl -s "http://localhost:8080/api/v1/analysis/status/$analysis_id")
                status=$(echo "$status_response" | jq -r '.status')
                
                if [ "$status" = "completed" ]; then
                    print_status "Analysis completed!"
                    echo "Results:"
                    echo "$status_response" | jq .
                    break
                elif [ "$status" = "failed" ]; then
                    print_error "Analysis failed!"
                    echo "$status_response" | jq .
                    break
                fi
                
                echo -n "."
                sleep 2
            done
        fi
    else
        print_warning "Sample image not found, skipping analysis test"
    fi
    
    echo
}

# Main demo function
main() {
    print_header "Gypsum Analysis API Demo"
    echo
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq is required for this demo. Please install it first."
        print_status "Install with: sudo apt-get install jq"
        exit 1
    fi
    
    # Check if API binary exists
    if [ ! -f "./gypsum-analysis-api" ]; then
        print_error "API binary not found. Please build it first:"
        print_status "go build -o gypsum-analysis-api"
        exit 1
    fi
    
    # Setup
    create_mock_fiji
    create_sample_image
    
    # Start API
    start_api
    
    # Demonstrate API
    demonstrate_api
    
    # Cleanup
    stop_api
    cleanup_mock_fiji
    
    print_status "Demo completed successfully!"
    echo
    print_status "To run the real API with actual Fiji:"
    echo "1. Install Fiji: ./scripts/install-fiji.sh"
    echo "2. Start API: ./gypsum-analysis-api"
    echo "3. Test API: ./scripts/test-api.sh"
}

# Trap to cleanup on exit
trap 'stop_api; cleanup_mock_fiji' EXIT

# Run main function
main "$@"
