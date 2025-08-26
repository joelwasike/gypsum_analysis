# Gypsum Analysis API

A Go-based REST API for analyzing gypsum mineral purity using Fiji (ImageJ) open-source software. This API processes uploaded gypsum images and returns detailed mineral composition analysis including purity percentage.

## Features

- **Image Processing**: Supports JPG, PNG, and TIFF image formats
- **Mineral Analysis**: Uses Fiji/ImageJ for scientific image analysis
- **Async Processing**: Non-blocking analysis with status tracking
- **Detailed Results**: Provides comprehensive mineral composition breakdown
- **RESTful API**: Clean HTTP endpoints for easy integration

## Prerequisites

### System Requirements

- **Operating System**: Linux (Ubuntu 22.04+ recommended)
- **Go**: Version 1.21 or higher
- **Fiji/ImageJ**: Latest version installed

### Installing Fiji

1. Download Fiji from [https://imagej.net/software/fiji/](https://imagej.net/software/fiji/)
2. Extract to `/opt/fiji/` (or update the path in `config.yaml`)
3. Make the ImageJ executable:
   ```bash
   chmod +x /opt/fiji/Fiji.app/ImageJ-linux64
   ```

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd gypsum-analysis-api
   ```

2. **Install Go dependencies**:
   ```bash
   go mod tidy
   ```

3. **Configure the application**:
   - Edit `config.yaml` to match your Fiji installation path
   - Ensure the temp directory is writable

4. **Build the application**:
   ```bash
   go build -o gypsum-analysis-api
   ```

## Configuration

The application uses `config.yaml` for configuration. Key settings:

```yaml
environment: development
port: "8080"
log_level: info

# Fiji/ImageJ settings
fiji_path: "/opt/fiji/Fiji.app/ImageJ-linux64"
temp_dir: "/tmp/gypsum-analysis"
max_file_size: 52428800  # 50MB

# Analysis settings
analysis_timeout: 300  # 5 minutes
```

### Environment Variables

You can override configuration using environment variables:

- `ENVIRONMENT`: Application environment (development/production)
- `PORT`: Server port
- `LOG_LEVEL`: Logging level (debug/info/warn/error)
- `FIJI_PATH`: Path to Fiji executable
- `TEMP_DIR`: Temporary directory for file processing
- `MAX_FILE_SIZE`: Maximum file size in bytes
- `ANALYSIS_TIMEOUT`: Analysis timeout in seconds

## Usage

### Starting the Server

```bash
./gypsum-analysis-api
```

The server will start on port 8080 (or the configured port).

### API Endpoints

#### 1. Health Check
```http
GET /health
```

**Response**:
```json
{
  "status": "healthy",
  "service": "gypsum-analysis-api"
}
```

#### 2. Analyze Gypsum Image
```http
POST /api/v1/analysis/gypsum
Content-Type: multipart/form-data

Form Data:
- image: [gypsum image file]
```

**Response**:
```json
{
  "analysis_id": "uuid-string",
  "status": "processing",
  "message": "Analysis started successfully"
}
```

#### 3. Get Analysis Status
```http
GET /api/v1/analysis/status/{analysis_id}
```

**Response** (Processing):
```json
{
  "id": "uuid-string",
  "status": "processing",
  "created_at": "2024-01-01T12:00:00Z",
  "image_size": 1024000
}
```

**Response** (Completed):
```json
{
  "id": "uuid-string",
  "status": "completed",
  "created_at": "2024-01-01T12:00:00Z",
  "completed_at": "2024-01-01T12:01:30Z",
  "purity_percentage": 85.5,
  "confidence": 0.92,
  "image_path": "/tmp/gypsum-analysis/uuid-string.jpg",
  "image_size": 1024000,
  "analysis_time_ms": 90000,
  "gypsum_content_percentage": 85.5,
  "impurity_content_percentage": 14.5,
  "calcite_content_percentage": 4.35,
  "quartz_content_percentage": 2.9,
  "other_minerals_percentage": 7.25,
  "threshold_value": 128.5,
  "particle_count": 45,
  "average_particle_size_um": 125.3
}
```

**Response** (Failed):
```json
{
  "id": "uuid-string",
  "status": "failed",
  "created_at": "2024-01-01T12:00:00Z",
  "completed_at": "2024-01-01T12:00:15Z",
  "error": "Analysis failed: Fiji execution failed"
}
```

## Analysis Methodology

The gypsum analysis uses the following ImageJ processing pipeline:

1. **Image Preprocessing**:
   - Convert to 8-bit if needed
   - Enhance contrast
   - Apply Gaussian blur for noise reduction

2. **Threshold Detection**:
   - Use Otsu's method for automatic thresholding
   - Convert to binary mask

3. **Particle Analysis**:
   - Analyze particles with size and circularity filters
   - Calculate total area coverage

4. **Purity Calculation**:
   - Estimate gypsum content based on white/light areas
   - Calculate impurity percentages
   - Determine confidence score

## Docker Support

### Building Docker Image

```bash
docker build -t gypsum-analysis-api .
```

### Running with Docker

```bash
docker run -p 8080:8080 \
  -v /opt/fiji:/opt/fiji \
  -v /tmp/gypsum-analysis:/tmp/gypsum-analysis \
  gypsum-analysis-api
```

## Development

### Project Structure

```
gypsum-analysis-api/
├── main.go                 # Application entry point
├── go.mod                  # Go module file
├── go.sum                  # Go dependencies checksum
├── config.yaml             # Configuration file
├── README.md              # This file
├── internal/
│   ├── api/               # API route definitions
│   ├── config/            # Configuration management
│   ├── handlers/          # HTTP request handlers
│   ├── logger/            # Logging utilities
│   ├── models/            # Data models
│   └── services/          # Business logic services
└── scripts/               # Utility scripts
```

### Running Tests

```bash
go test ./...
```

### Code Formatting

```bash
go fmt ./...
```

## Troubleshooting

### Common Issues

1. **Fiji not found**: Ensure Fiji is installed and the path in `config.yaml` is correct
2. **Permission denied**: Make sure the temp directory is writable
3. **Analysis timeout**: Increase `analysis_timeout` in configuration for large images
4. **Memory issues**: Reduce `max_file_size` or increase system memory

### Logs

The application logs to stdout in JSON format. Set `LOG_LEVEL` to `debug` for detailed logging.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Fiji/ImageJ](https://imagej.net/software/fiji/) - Open-source image processing software
- [Gin](https://github.com/gin-gonic/gin) - HTTP web framework
- [Logrus](https://github.com/sirupsen/logrus) - Structured logger
