#!/bin/bash

# Server Setup Script for Gypsum Analysis API
# This script sets up the complete environment for running the API on a server

set -e

# Configuration
API_PORT="8089"
FIJI_INSTALL_DIR="/opt/fiji"
TEMP_DIR="/tmp/gypsum-analysis"
SERVICE_USER="gypsum-api"
SERVICE_NAME="gypsum-analysis-api"

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
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

print_header "Gypsum Analysis API Server Setup"
print_status "This script will set up the complete environment for the Gypsum Analysis API"

# Step 1: Update system packages
print_header "Step 1: Updating System Packages"
print_status "Updating package list..."
sudo apt update

print_status "Installing required system packages..."
sudo apt install -y wget unzip curl git build-essential

# Step 2: Install Go
print_header "Step 2: Installing Go"
if ! command -v go &> /dev/null; then
    print_status "Go not found. Installing Go..."
    
    # Download and install Go
    GO_VERSION="1.21.5"
    GO_ARCH="linux-amd64"
    GO_URL="https://go.dev/dl/go${GO_VERSION}.${GO_ARCH}.tar.gz"
    
    cd /tmp
    wget "$GO_URL"
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.${GO_ARCH}.tar.gz"
    
    # Add Go to PATH
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
    
    print_status "Go installed successfully!"
else
    print_status "Go is already installed: $(go version)"
fi

# Step 3: Install Fiji
print_header "Step 3: Installing Fiji (ImageJ)"
if [ ! -f "$FIJI_INSTALL_DIR/Fiji.app/ImageJ-linux64" ]; then
    print_status "Installing Fiji..."
    
    # Create installation directory
    sudo mkdir -p "$FIJI_INSTALL_DIR"
    sudo chown $USER:$USER "$FIJI_INSTALL_DIR"
    
    # Download and extract Fiji
    cd /tmp
    wget -O fiji.zip "https://downloads.imagej.net/fiji/latest/fiji-latest-linux64-jdk.zip"
    unzip -q fiji.zip -d "$FIJI_INSTALL_DIR"
    
    # Set permissions
    chmod +x "$FIJI_INSTALL_DIR/Fiji.app/ImageJ-linux64"
    
    # Create symlink
    sudo ln -sf "$FIJI_INSTALL_DIR/Fiji.app/ImageJ-linux64" /usr/local/bin/fiji
    
    print_status "Fiji installed successfully!"
else
    print_status "Fiji is already installed at $FIJI_INSTALL_DIR"
fi

# Step 4: Create service user
print_header "Step 4: Creating Service User"
if ! id "$SERVICE_USER" &>/dev/null; then
    print_status "Creating service user: $SERVICE_USER"
    sudo useradd -r -s /bin/bash -d /home/$SERVICE_USER -m $SERVICE_USER
    sudo usermod -aG sudo $SERVICE_USER
    print_status "Service user created successfully!"
else
    print_status "Service user $SERVICE_USER already exists"
fi

# Step 5: Set up application directory
print_header "Step 5: Setting Up Application Directory"
APP_DIR="/opt/gypsum-analysis-api"
sudo mkdir -p "$APP_DIR"
sudo chown $SERVICE_USER:$SERVICE_USER "$APP_DIR"

# Step 6: Build the application
print_header "Step 6: Building the Application"
print_status "Building gypsum-analysis-api..."

# Ensure we're in the project directory
cd /home/joel/projects/mamlaka\ projects/fiji

# Install Go dependencies
go mod download
go mod tidy

# Build the application
go build -o gypsum-analysis-api .

# Copy binary to application directory
sudo cp gypsum-analysis-api "$APP_DIR/"
sudo chown $SERVICE_USER:$SERVICE_USER "$APP_DIR/gypsum-analysis-api"
sudo chmod +x "$APP_DIR/gypsum-analysis-api"

# Step 7: Configure the application
print_header "Step 7: Configuring the Application"
print_status "Creating configuration file..."

# Create config file
sudo tee "$APP_DIR/config.yaml" > /dev/null <<EOF
environment: production
port: "$API_PORT"
log_level: info

# Fiji/ImageJ settings
fiji_path: "$FIJI_INSTALL_DIR/Fiji.app/ImageJ-linux64"
temp_dir: "$TEMP_DIR"
max_file_size: 52428800  # 50MB

# Analysis settings
analysis_timeout: 300  # 5 minutes
EOF

sudo chown $SERVICE_USER:$SERVICE_USER "$APP_DIR/config.yaml"

# Step 8: Create temp directory
print_header "Step 8: Creating Temporary Directory"
sudo mkdir -p "$TEMP_DIR"
sudo chown $SERVICE_USER:$SERVICE_USER "$TEMP_DIR"
sudo chmod 755 "$TEMP_DIR"

# Step 9: Create systemd service
print_header "Step 9: Creating Systemd Service"
print_status "Creating systemd service file..."

sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=Gypsum Analysis API
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/gypsum-analysis-api
Restart=always
RestartSec=10
Environment=PATH=/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$TEMP_DIR

[Install]
WantedBy=multi-user.target
EOF

# Step 10: Enable and start the service
print_header "Step 10: Enabling and Starting Service"
print_status "Reloading systemd..."
sudo systemctl daemon-reload

print_status "Enabling service..."
sudo systemctl enable $SERVICE_NAME

print_status "Starting service..."
sudo systemctl start $SERVICE_NAME

# Step 11: Configure firewall
print_header "Step 11: Configuring Firewall"
if command -v ufw &> /dev/null; then
    print_status "Configuring UFW firewall..."
    sudo ufw allow $API_PORT/tcp
    print_status "Firewall rule added for port $API_PORT"
elif command -v iptables &> /dev/null; then
    print_status "Configuring iptables..."
    sudo iptables -A INPUT -p tcp --dport $API_PORT -j ACCEPT
    print_status "iptables rule added for port $API_PORT"
else
    print_warning "No firewall detected. Please manually configure firewall for port $API_PORT"
fi

# Step 12: Test the installation
print_header "Step 12: Testing the Installation"
print_status "Waiting for service to start..."
sleep 5

# Check service status
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    print_status "Service is running successfully!"
else
    print_error "Service failed to start. Checking logs..."
    sudo journalctl -u $SERVICE_NAME -n 20
    exit 1
fi

# Test API endpoint
print_status "Testing API health endpoint..."
if curl -s "http://localhost:$API_PORT/health" > /dev/null; then
    print_status "API health check passed!"
else
    print_error "API health check failed!"
    exit 1
fi

# Step 13: Create management scripts
print_header "Step 13: Creating Management Scripts"

# Create service management script
sudo tee /usr/local/bin/gypsum-api-manage > /dev/null <<'EOF'
#!/bin/bash

SERVICE_NAME="gypsum-analysis-api"

case "$1" in
    start)
        sudo systemctl start $SERVICE_NAME
        echo "Service started"
        ;;
    stop)
        sudo systemctl stop $SERVICE_NAME
        echo "Service stopped"
        ;;
    restart)
        sudo systemctl restart $SERVICE_NAME
        echo "Service restarted"
        ;;
    status)
        sudo systemctl status $SERVICE_NAME
        ;;
    logs)
        sudo journalctl -u $SERVICE_NAME -f
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
EOF

sudo chmod +x /usr/local/bin/gypsum-api-manage

# Create test script
sudo tee /usr/local/bin/gypsum-api-test > /dev/null <<EOF
#!/bin/bash

API_PORT="$API_PORT"
SAMPLE_IMAGE="/opt/gypsum-analysis-api/testdata/sample_gypsum.jpg"

echo "Testing Gypsum Analysis API on port \$API_PORT..."

# Test health endpoint
echo "1. Testing health endpoint..."
curl -s "http://localhost:\$API_PORT/health" | jq .

# Test analysis endpoint (if sample image exists)
if [ -f "\$SAMPLE_IMAGE" ]; then
    echo -e "\n2. Testing analysis endpoint..."
    ANALYSIS_RESPONSE=\$(curl -s -X POST -F "image=@\$SAMPLE_IMAGE" "http://localhost:\$API_PORT/api/v1/analysis/gypsum")
    echo "\$ANALYSIS_RESPONSE" | jq .
    
    # Extract analysis ID and check status
    ANALYSIS_ID=\$(echo "\$ANALYSIS_RESPONSE" | jq -r '.analysis_id')
    if [ "\$ANALYSIS_ID" != "null" ]; then
        echo -e "\n3. Checking analysis status..."
        sleep 2
        curl -s "http://localhost:\$API_PORT/api/v1/analysis/status/\$ANALYSIS_ID" | jq .
    fi
else
    echo -e "\n2. No sample image found for testing analysis endpoint"
fi

echo -e "\nAPI test completed!"
EOF

sudo chmod +x /usr/local/bin/gypsum-api-test

print_header "Installation Complete!"
print_status "Gypsum Analysis API has been successfully installed and configured!"
echo
print_status "Service Details:"
echo "  - Service Name: $SERVICE_NAME"
echo "  - Port: $API_PORT"
echo "  - User: $SERVICE_USER"
echo "  - Application Directory: $APP_DIR"
echo "  - Temp Directory: $TEMP_DIR"
echo "  - Fiji Path: $FIJI_INSTALL_DIR/Fiji.app/ImageJ-linux64"
echo
print_status "Management Commands:"
echo "  - Start service: sudo systemctl start $SERVICE_NAME"
echo "  - Stop service: sudo systemctl stop $SERVICE_NAME"
echo "  - Restart service: sudo systemctl restart $SERVICE_NAME"
echo "  - Check status: sudo systemctl status $SERVICE_NAME"
echo "  - View logs: sudo journalctl -u $SERVICE_NAME -f"
echo "  - Or use: gypsum-api-manage {start|stop|restart|status|logs}"
echo
print_status "Testing:"
echo "  - Health check: curl http://localhost:$API_PORT/health"
echo "  - Run tests: gypsum-api-test"
echo
print_status "API Endpoints:"
echo "  - Health: GET http://localhost:$API_PORT/health"
echo "  - Analyze: POST http://localhost:$API_PORT/api/v1/analysis/gypsum"
echo "  - Status: GET http://localhost:$API_PORT/api/v1/analysis/status/{id}"
echo
print_status "The API is now running and ready to use!"
