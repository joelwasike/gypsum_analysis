package handlers

import (
	"bytes"
	"encoding/json"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"gypsum-analysis-api/internal/logger"
	"gypsum-analysis-api/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockAnalysisService is a mock implementation of AnalysisService
type MockAnalysisService struct {
	mock.Mock
}

func (m *MockAnalysisService) AnalyzeGypsumImage(analysisID string, file *multipart.FileHeader) error {
	args := m.Called(analysisID, file)
	return args.Error(0)
}

func (m *MockAnalysisService) GetAnalysisStatus(analysisID string) (*models.AnalysisResult, error) {
	args := m.Called(analysisID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.AnalysisResult), args.Error(1)
}

func TestAnalyzeGypsum_NoFile(t *testing.T) {
	// Setup
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	// Create a request without any form data
	req := httptest.NewRequest("POST", "/api/v1/analysis/gypsum", nil)
	c.Request = req

	mockService := new(MockAnalysisService)
	logger := logger.New("info")
	handler := NewAnalysisHandler(mockService, logger)

	// Test
	handler.AnalyzeGypsum(c)

	// Assert
	assert.Equal(t, http.StatusBadRequest, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "No image file provided", response["error"])
}

func TestAnalyzeGypsum_InvalidFileType(t *testing.T) {
	// Setup
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	// Create a temporary file with invalid extension
	tempFile, err := os.CreateTemp("", "test*.txt")
	assert.NoError(t, err)
	defer os.Remove(tempFile.Name())

	// Create multipart form
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("image", "test.txt")
	assert.NoError(t, err)
	part.Write([]byte("test content"))
	writer.Close()

	c.Request = httptest.NewRequest("POST", "/api/v1/analysis/gypsum", body)
	c.Request.Header.Set("Content-Type", writer.FormDataContentType())

	mockService := new(MockAnalysisService)
	logger := logger.New("info")
	handler := NewAnalysisHandler(mockService, logger)

	// Test
	handler.AnalyzeGypsum(c)

	// Assert
	assert.Equal(t, http.StatusBadRequest, w.Code)

	var response map[string]interface{}
	err = json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Contains(t, response["error"], "Unsupported file type")
}

func TestGetAnalysisStatus_NoID(t *testing.T) {
	// Setup
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	mockService := new(MockAnalysisService)
	logger := logger.New("info")
	handler := NewAnalysisHandler(mockService, logger)

	// Test
	handler.GetAnalysisStatus(c)

	// Assert
	assert.Equal(t, http.StatusBadRequest, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "Analysis ID is required", response["error"])
}

func TestGetAnalysisStatus_NotFound(t *testing.T) {
	// Setup
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	c.Params = gin.Params{{Key: "id", Value: "test-id"}}

	mockService := new(MockAnalysisService)
	mockService.On("GetAnalysisStatus", "test-id").Return(nil, assert.AnError)

	logger := logger.New("info")
	handler := NewAnalysisHandler(mockService, logger)

	// Test
	handler.GetAnalysisStatus(c)

	// Assert
	assert.Equal(t, http.StatusNotFound, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	assert.NoError(t, err)
	assert.Equal(t, "Analysis not found", response["error"])

	mockService.AssertExpectations(t)
}
