package api

import (
	"gypsum-analysis-api/internal/config"
	"gypsum-analysis-api/internal/handlers"
	"gypsum-analysis-api/internal/logger"
	"gypsum-analysis-api/internal/services"

	"github.com/gin-gonic/gin"
)

// SetupRoutes configures all API routes
func SetupRoutes(router *gin.Engine, cfg *config.Config, logger *logger.Logger) {
	// Configure maximum multipart memory to support large image uploads
	// Allow configured max file size plus a small overhead buffer
	router.MaxMultipartMemory = cfg.MaxFileSize + int64(10<<20) // +10MB overhead
	// Add CORS middleware
	router.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

		// Handle preflight requests
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	})

	// Initialize services
	analysisService := services.NewAnalysisService(cfg, logger)

	// Initialize handlers
	analysisHandler := handlers.NewAnalysisHandler(analysisService, logger)

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "healthy",
			"service": "gypsum-analysis-api",
		})
	})

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// Analysis endpoints
		analysis := v1.Group("/analysis")
		{
			analysis.POST("/gypsum", analysisHandler.AnalyzeGypsum)
			analysis.GET("/status/:id", analysisHandler.GetAnalysisStatus)
		}
	}
}
