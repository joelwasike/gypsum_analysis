# Server Installation Guide for Gypsum Analysis API

This guide will help you install and configure the Gypsum Analysis API on your server to run on port 8089.

## Prerequisites

- Ubuntu/Debian Linux server
- Sudo access
- Internet connection

## Quick Installation (Automated)

If you want to run the automated setup script:

```bash
# Make the script executable
chmod +x server-setup.sh

# Run the automated installation
./server-setup.sh
```

## Manual Installation (Step by Step)

### Step 1: Update System Packages

```bash
sudo apt update
sudo apt install -y wget unzip curl git build-essential
```

### Step 2: Install Go

```bash
# Download Go
cd /tmp
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz

# Install Go
sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# Add Go to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin

# Verify installation
go version
```

### Step 3: Install Fiji (ImageJ)

```bash
# Create installation directory
sudo mkdir -p /opt/fiji
sudo chown $USER:$USER /opt/fiji

# Download and extract Fiji
cd /tmp
wget -O fiji.zip "https://downloads.imagej.net/fiji/latest/fiji-latest-linux64-jdk.zip"
unzip -q fiji.zip -d /opt/fiji

# Set permissions
chmod +x /opt/fiji/Fiji.app/ImageJ-linux64

# Create symlink for easier access
sudo ln -sf /opt/fiji/Fiji.app/ImageJ-linux64 /usr/local/bin/fiji

# Test Fiji installation
/opt/fiji/Fiji.app/ImageJ-linux64 --version
```

### Step 4: Create Service User

```bash
# Create service user
sudo useradd -r -s /bin/bash -d /home/gypsum-api -m gypsum-api
sudo usermod -aG sudo gypsum-api
```

### Step 5: Build the Application

```bash
# Navigate to your project directory
cd /path/to/your/gypsum-analysis-api

# Install dependencies
go mod download
go mod tidy

# Build the application
go build -o gypsum-analysis-api .

# Create application directory
sudo mkdir -p /opt/gypsum-analysis-api
sudo cp gypsum-analysis-api /opt/gypsum-analysis-api/
sudo chown gypsum-api:gypsum-api /opt/gypsum-analysis-api/gypsum-analysis-api
sudo chmod +x /opt/gypsum-analysis-api/gypsum-analysis-api
```

### Step 6: Configure the Application

```bash
# Create configuration file
sudo tee /opt/gypsum-analysis-api/config.yaml > /dev/null <<EOF
environment: production
port: "8089"
log_level: info

# Fiji/ImageJ settings
fiji_path: "/opt/fiji/Fiji.app/ImageJ-linux64"
temp_dir: "/tmp/gypsum-analysis"
max_file_size: 52428800  # 50MB

# Analysis settings
analysis_timeout: 300  # 5 minutes
EOF

sudo chown gypsum-api:gypsum-api /opt/gypsum-analysis-api/config.yaml
```

### Step 7: Create Temporary Directory

```bash
# Create temp directory
sudo mkdir -p /tmp/gypsum-analysis
sudo chown gypsum-api:gypsum-api /tmp/gypsum-analysis
sudo chmod 755 /tmp/gypsum-analysis
```

### Step 8: Create Systemd Service

```bash
# Create systemd service file
sudo tee /etc/systemd/system/gypsum-analysis-api.service > /dev/null <<EOF
[Unit]
Description=Gypsum Analysis API
After=network.target

[Service]
Type=simple
User=gypsum-api
Group=gypsum-api
WorkingDirectory=/opt/gypsum-analysis-api
ExecStart=/opt/gypsum-analysis-api/gypsum-analysis-api
Restart=always
RestartSec=10
Environment=PATH=/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/tmp/gypsum-analysis

[Install]
WantedBy=multi-user.target
EOF
```

### Step 9: Enable and Start the Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service
sudo systemctl enable gypsum-analysis-api

# Start service
sudo systemctl start gypsum-analysis-api

# Check status
sudo systemctl status gypsum-analysis-api
```

### Step 10: Configure Firewall

```bash
# For UFW firewall
sudo ufw allow 8089/tcp

# For iptables
sudo iptables -A INPUT -p tcp --dport 8089 -j ACCEPT
```

### Step 11: Test the Installation

```bash
# Test health endpoint
curl http://localhost:8089/health

# Expected response:
# {"service":"gypsum-analysis-api","status":"healthy"}
```

## Management Commands

### Service Management

```bash
# Start the service
sudo systemctl start gypsum-analysis-api

# Stop the service
sudo systemctl stop gypsum-analysis-api

# Restart the service
sudo systemctl restart gypsum-analysis-api

# Check service status
sudo systemctl status gypsum-analysis-api

# View logs
sudo journalctl -u gypsum-analysis-api -f
```

### API Testing

```bash
# Health check
curl http://localhost:8089/health

# Analyze an image
curl -X POST -F "image=@your_image.jpg" http://localhost:8089/api/v1/analysis/gypsum

# Check analysis status (replace {analysis_id} with actual ID)
curl http://localhost:8089/api/v1/analysis/status/{analysis_id}
```

## Troubleshooting

### Check Service Logs

```bash
# View recent logs
sudo journalctl -u gypsum-analysis-api -n 50

# Follow logs in real-time
sudo journalctl -u gypsum-analysis-api -f
```

### Common Issues

1. **Permission Denied**: Make sure the service user has proper permissions
   ```bash
   sudo chown -R gypsum-api:gypsum-api /opt/gypsum-analysis-api
   sudo chown gypsum-api:gypsum-api /tmp/gypsum-analysis
   ```

2. **Fiji Not Found**: Verify Fiji installation
   ```bash
   ls -la /opt/fiji/Fiji.app/ImageJ-linux64
   /opt/fiji/Fiji.app/ImageJ-linux64 --version
   ```

3. **Port Already in Use**: Check if port 8089 is available
   ```bash
   sudo netstat -tlnp | grep 8089
   ```

4. **Go Not Found**: Ensure Go is in PATH
   ```bash
   echo $PATH
   which go
   ```

### Uninstall

If you need to remove the installation:

```bash
# Stop and disable service
sudo systemctl stop gypsum-analysis-api
sudo systemctl disable gypsum-analysis-api

# Remove service file
sudo rm /etc/systemd/system/gypsum-analysis-api.service

# Remove application files
sudo rm -rf /opt/gypsum-analysis-api

# Remove service user
sudo userdel -r gypsum-api

# Remove Fiji (optional)
sudo rm -rf /opt/fiji
sudo rm /usr/local/bin/fiji

# Reload systemd
sudo systemctl daemon-reload
```

## API Endpoints

Once installed, your API will be available at:

- **Health Check**: `GET http://your-server:8089/health`
- **Analyze Image**: `POST http://your-server:8089/api/v1/analysis/gypsum`
- **Check Status**: `GET http://your-server:8089/api/v1/analysis/status/{id}`

## Security Considerations

1. **Firewall**: Ensure only necessary ports are open
2. **Service User**: The API runs as a dedicated user with minimal privileges
3. **File Permissions**: Temporary files are properly secured
4. **HTTPS**: Consider adding SSL/TLS for production use

## Performance Tuning

For production environments, consider:

1. **Resource Limits**: Adjust memory and CPU limits in systemd service
2. **Log Rotation**: Configure log rotation for systemd logs
3. **Monitoring**: Set up monitoring for the service
4. **Backup**: Regular backups of configuration and data
