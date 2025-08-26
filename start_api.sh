#!/bin/bash

# Start Gypsum Analysis API and keep it running
# This script starts the API with mock Fiji and keeps it running

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

# Function to create mock Fiji
create_mock_fiji() {
    print_status "Creating mock Fiji executable..."
    
    # Create mock Fiji directory
    sudo mkdir -p /opt/fiji/Fiji.app
    
    # Create smart mock ImageJ executable
    cat > /tmp/mock_imagej.sh << 'EOF'
#!/bin/bash
# Smart Mock ImageJ that gives different results based on image characteristics

IMAGE_PATH="$1"
echo "Smart Mock ImageJ analyzing: $IMAGE_PATH"

# Get file size to simulate different analysis
if [ -f "$IMAGE_PATH" ]; then
    FILE_SIZE=$(stat -c%s "$IMAGE_PATH")
    echo "File size: $FILE_SIZE bytes"
    
    # Calculate different results based on file size
    SIZE_FACTOR=$((FILE_SIZE % 100))
    
    # Calculate purity based on file size (simulating real analysis)
    PURITY=$((50 + SIZE_FACTOR))
    if [ $PURITY -gt 95 ]; then
        PURITY=95
    fi
    
    # Calculate other parameters
    GYPSUM_CONTENT=$PURITY
    IMPURITY_CONTENT=$((100 - PURITY))
    PARTICLE_COUNT=$((20 + (SIZE_FACTOR / 10)))
    THRESHOLD=$((100 + SIZE_FACTOR))
    
    # Calculate confidence based on file size
    CONFIDENCE=$(echo "scale=2; 0.6 + ($SIZE_FACTOR / 100.0)" | bc 2>/dev/null || echo "0.8")
    
    echo "ANALYSIS_RESULTS_START"
    echo "purity_percentage:$PURITY"
    echo "gypsum_content:$GYPSUM_CONTENT"
    echo "impurity_content:$IMPURITY_CONTENT"
    echo "particle_count:$PARTICLE_COUNT"
    echo "total_area:$((100000 + SIZE_FACTOR * 1000))"
    echo "image_area:$((150000 + SIZE_FACTOR * 500))"
    echo "threshold_value:$THRESHOLD"
    echo "confidence:$CONFIDENCE"
    echo "ANALYSIS_RESULTS_END"
else
    echo "ANALYSIS_RESULTS_START"
    echo "purity_percentage:0"
    echo "gypsum_content:0"
    echo "impurity_content:100"
    echo "particle_count:0"
    echo "total_area:0"
    echo "image_area:0"
    echo "threshold_value:0"
    echo "confidence:0"
    echo "ANALYSIS_RESULTS_END"
fi

exit 0
EOF
    
    sudo cp /tmp/mock_imagej.sh /opt/fiji/Fiji.app/ImageJ-linux64
    sudo chmod +x /opt/fiji/Fiji.app/ImageJ-linux64
    rm /tmp/mock_imagej.sh
    
    print_status "Mock Fiji created successfully!"
}

# Function to cleanup on exit
cleanup() {
    print_status "Cleaning up..."
    sudo rm -rf /opt/fiji
    print_status "Cleanup complete!"
}

# Set up cleanup trap
trap cleanup EXIT

# Main function
main() {
    print_status "Starting Gypsum Analysis API..."
    
    # Create mock Fiji
    create_mock_fiji
    
    # Create temp directory
    mkdir -p /tmp/gypsum-analysis
    
    print_status "API is starting on http://localhost:8080"
    print_status "Press Ctrl+C to stop the API"
    echo
    
    # Start the API
    ./gypsum-analysis-api
}

# Run main function
main "$@"
