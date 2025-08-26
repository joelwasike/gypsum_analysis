package handlers

import (
	"net/http"
	"path/filepath"
	"strings"

	"gypsum-analysis-api/internal/logger"
	"gypsum-analysis-api/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AnalysisHandler handles analysis-related HTTP requests
type AnalysisHandler struct {
	analysisService services.AnalysisServiceInterface
	logger          *logger.Logger
}

// NewAnalysisHandler creates a new analysis handler
func NewAnalysisHandler(analysisService services.AnalysisServiceInterface, logger *logger.Logger) *AnalysisHandler {
	return &AnalysisHandler{
		analysisService: analysisService,
		logger:          logger,
	}
}

// AnalyzeGypsum handles gypsum image analysis requests
func (h *AnalysisHandler) AnalyzeGypsum(c *gin.Context) {
	// Get the uploaded file
	file, err := c.FormFile("image")
	if err != nil {
		h.logger.WithError(err).Error("Failed to get uploaded file")
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "No image file provided",
		})
		return
	}

	// Validate file type
	ext := strings.ToLower(filepath.Ext(file.Filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".tiff" && ext != ".tif" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Unsupported file type. Please upload JPG, PNG, or TIFF images",
		})
		return
	}

	// Generate analysis ID
	analysisID := uuid.New().String()

	// Start analysis in background
	go func() {
		if err := h.analysisService.AnalyzeGypsumImage(analysisID, file); err != nil {
			h.logger.WithError(err).WithField("analysis_id", analysisID).Error("Analysis failed")
		}
	}()

	// Return immediate response with analysis ID
	c.JSON(http.StatusAccepted, gin.H{
		"analysis_id": analysisID,
		"status":      "processing",
		"message":     "Analysis started successfully",
	})
}

// GetAnalysisStatus returns the status and results of an analysis
func (h *AnalysisHandler) GetAnalysisStatus(c *gin.Context) {
	analysisID := c.Param("id")
	if analysisID == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Analysis ID is required",
		})
		return
	}

	// Get analysis status from service
	status, err := h.analysisService.GetAnalysisStatus(analysisID)
	if err != nil {
		h.logger.WithError(err).WithField("analysis_id", analysisID).Error("Failed to get analysis status")
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Analysis not found",
		})
		return
	}

	c.JSON(http.StatusOK, status)
}
