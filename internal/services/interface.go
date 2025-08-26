package services

import (
	"mime/multipart"
	"gypsum-analysis-api/internal/models"
)

// AnalysisServiceInterface defines the interface for analysis services
type AnalysisServiceInterface interface {
	AnalyzeGypsumImage(analysisID string, file *multipart.FileHeader) error
	GetAnalysisStatus(analysisID string) (*models.AnalysisResult, error)
}
