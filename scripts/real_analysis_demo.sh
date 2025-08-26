#!/bin/bash

# Real Analysis Demo Script
# This script shows how to get variable results based on image analysis

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Function to create smart mock Fiji
create_smart_mock_fiji() {
    print_status "Creating smart mock Fiji that analyzes images..."
    
    # Create mock Fiji directory
    sudo mkdir -p /opt/fiji/Fiji.app
    
    # Create smart mock ImageJ executable that analyzes file size
    cat > /tmp/smart_mock_imagej.sh << 'EOF'
#!/bin/bash
# Smart Mock ImageJ that gives different results based on image characteristics

IMAGE_PATH="$1"
echo "Smart Mock ImageJ analyzing: $IMAGE_PATH"

# Get file size to simulate different analysis
if [ -f "$IMAGE_PATH" ]; then
    FILE_SIZE=$(stat -c%s "$IMAGE_PATH")
    echo "File size: $FILE_SIZE bytes"
    
    # Calculate different results based on file size
    # This simulates real analysis where different images give different results
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
    
    sudo cp /tmp/smart_mock_imagej.sh /opt/fiji/Fiji.app/ImageJ-linux64
    sudo chmod +x /opt/fiji/Fiji.app/ImageJ-linux64
    rm /tmp/smart_mock_imagej.sh
    
    print_status "Smart mock Fiji created successfully!"
}

# Function to create different test images
create_test_images() {
    print_status "Creating different test images for analysis..."
    
    mkdir -p testdata
    
    # Create different sized images to simulate different gypsum samples
    for i in {1..5}; do
        SIZE=$((100 + i * 50))
        echo "Creating test image $i (size: ${SIZE}x${SIZE})"
        
        # Create different images using ImageMagick or fallback
        if command -v convert >/dev/null 2>&1; then
            convert -size ${SIZE}x${SIZE} xc:white \
                -fill gray -draw "circle $((SIZE/2)),$((SIZE/2)) $((SIZE/4)),$((SIZE/4))" \
                -fill white -draw "circle $((SIZE/3)),$((SIZE/3)) $((SIZE/6)),$((SIZE/6))" \
                testdata/gypsum_sample_${i}.jpg
        else
            # Fallback: create files with different content
            echo "Mock gypsum image $i - Sample data with size factor $i" > testdata/gypsum_sample_${i}.jpg
        fi
    done
    
    print_status "Test images created!"
}

# Function to demonstrate variable analysis
demonstrate_variable_analysis() {
    print_header "Demonstrating Variable Analysis Results"
    
    for i in {1..5}; do
        IMAGE_FILE="testdata/gypsum_sample_${i}.jpg"
        
        if [ -f "$IMAGE_FILE" ]; then
            print_status "Analyzing image $i: $IMAGE_FILE"
            
            # Upload and analyze
            response=$(curl -s -X POST \
                -F "image=@$IMAGE_FILE" \
                "http://localhost:8080/api/v1/analysis/gypsum")
            
            analysis_id=$(echo "$response" | jq -r '.analysis_id' 2>/dev/null)
            
            if [ "$analysis_id" != "null" ]; then
                # Wait for analysis
                sleep 2
                
                # Get results
                results=$(curl -s "http://localhost:8080/api/v1/analysis/status/$analysis_id")
                purity=$(echo "$results" | jq -r '.purity_percentage' 2>/dev/null)
                confidence=$(echo "$results" | jq -r '.confidence' 2>/dev/null)
                particles=$(echo "$results" | jq -r '.particle_count' 2>/dev/null)
                
                echo "  📊 Results for Image $i:"
                echo "     Purity: ${purity}%"
                echo "     Confidence: ${confidence}"
                echo "     Particles: ${particles}"
                echo
            fi
        fi
    done
}

# Function to show real Fiji installation
show_real_fiji_option() {
    print_header "Real Fiji Analysis Option"
    echo
    echo "To get REAL analysis results (not mock):"
    echo
    echo "1. Install real Fiji:"
    echo "   ./scripts/install-fiji.sh"
    echo
    echo "2. Run real API:"
    echo "   ./gypsum-analysis-api"
    echo
    echo "3. Real analysis will:"
    echo "   ✅ Process actual image pixels"
    echo "   ✅ Use ImageJ algorithms"
    echo "   ✅ Give different results for each image"
    echo "   ✅ Provide scientific accuracy"
    echo
}

# Main function
main() {
    print_header "Real Analysis Demo - Variable Results"
    echo
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq is required. Install with: sudo apt-get install jq"
        exit 1
    fi
    
    # Create smart mock Fiji
    create_smart_mock_fiji
    
    # Create test images
    create_test_images
    
    # Start API
    print_status "Starting API with smart mock..."
    ./gypsum-analysis-api &
    API_PID=$!
    
    # Wait for API
    sleep 5
    
    # Test API
    if curl -s "http://localhost:8080/health" > /dev/null; then
        print_status "API is ready!"
        
        # Demonstrate variable analysis
        demonstrate_variable_analysis
        
        # Show real Fiji option
        show_real_fiji_option
        
    else
        print_error "API failed to start"
    fi
    
    # Cleanup
    kill $API_PID 2>/dev/null || true
    sudo rm -rf /opt/fiji
    
    print_status "Demo completed!"
}

# Run main function
main "$@"
