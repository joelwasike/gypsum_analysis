#!/bin/bash

# Fiji Installation Script for Gypsum Analysis API
# This script downloads and installs Fiji (ImageJ) for use with the gypsum analysis API

set -e

# Configuration
FIJI_VERSION="20231219-1417"
FIJI_URL="https://downloads.imagej.net/fiji/latest/fiji-latest-linux64-jdk.zip"
INSTALL_DIR="/opt/fiji"
TEMP_DIR="/tmp/fiji-install"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check if Fiji is already installed
if [ -d "$INSTALL_DIR" ]; then
    print_warning "Fiji appears to be already installed at $INSTALL_DIR"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi
    print_status "Removing existing installation..."
    sudo rm -rf "$INSTALL_DIR"
fi

# Create installation directory
print_status "Creating installation directory..."
sudo mkdir -p "$INSTALL_DIR"
sudo chown $USER:$USER "$INSTALL_DIR"

# Create temporary directory
print_status "Creating temporary directory..."
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download Fiji
print_status "Downloading Fiji..."
wget -O fiji.zip "$FIJI_URL"

# Extract Fiji
print_status "Extracting Fiji..."
unzip -q fiji.zip -d "$INSTALL_DIR"

# Set permissions
print_status "Setting permissions..."
chmod +x "$INSTALL_DIR/Fiji.app/ImageJ-linux64"

# Create symlink for easier access
print_status "Creating symlink..."
sudo ln -sf "$INSTALL_DIR/Fiji.app/ImageJ-linux64" /usr/local/bin/fiji

# Clean up
print_status "Cleaning up..."
rm -rf "$TEMP_DIR"

# Test installation
print_status "Testing Fiji installation..."
if "$INSTALL_DIR/Fiji.app/ImageJ-linux64" --version > /dev/null 2>&1; then
    print_status "Fiji installation successful!"
else
    print_warning "Fiji installation completed, but version check failed"
    print_warning "This might be normal for some Fiji versions"
fi

# Update configuration
print_status "Updating configuration..."
CONFIG_FILE="config.yaml"
if [ -f "$CONFIG_FILE" ]; then
    # Backup original config
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
    
    # Update Fiji path in config
    sed -i "s|fiji_path:.*|fiji_path: \"$INSTALL_DIR/Fiji.app/ImageJ-linux64\"|" "$CONFIG_FILE"
    print_status "Updated $CONFIG_FILE with new Fiji path"
else
    print_warning "config.yaml not found in current directory"
    print_warning "Please manually set fiji_path to: $INSTALL_DIR/Fiji.app/ImageJ-linux64"
fi

print_status "Installation completed successfully!"
print_status "Fiji is installed at: $INSTALL_DIR"
print_status "Executable path: $INSTALL_DIR/Fiji.app/ImageJ-linux64"
print_status "Symlink created at: /usr/local/bin/fiji"

# Display next steps
echo
print_status "Next steps:"
echo "1. Build the gypsum analysis API: go build -o gypsum-analysis-api"
echo "2. Run the API: ./gypsum-analysis-api"
echo "3. Test with: curl http://localhost:8080/health"
