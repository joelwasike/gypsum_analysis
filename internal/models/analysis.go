package models

import (
	"time"
)

// AnalysisStatus represents the status of an analysis
type AnalysisStatus string

const (
	StatusPending   AnalysisStatus = "pending"
	StatusProcessing AnalysisStatus = "processing"
	StatusCompleted  AnalysisStatus = "completed"
	StatusFailed     AnalysisStatus = "failed"
)

// AnalysisResult represents the result of a gypsum analysis
type AnalysisResult struct {
	ID          string         `json:"id"`
	Status      AnalysisStatus `json:"status"`
	CreatedAt   time.Time      `json:"created_at"`
	CompletedAt *time.Time     `json:"completed_at,omitempty"`
	Error       string         `json:"error,omitempty"`
	
	// Analysis results
	PurityPercentage float64 `json:"purity_percentage,omitempty"`
	Confidence       float64 `json:"confidence,omitempty"`
	
	// Image analysis details
	ImagePath     string `json:"image_path,omitempty"`
	ImageSize     int64  `json:"image_size,omitempty"`
	AnalysisTime  int64  `json:"analysis_time_ms,omitempty"`
	
	// Mineral composition details
	GypsumContent    float64 `json:"gypsum_content_percentage,omitempty"`
	ImpurityContent  float64 `json:"impurity_content_percentage,omitempty"`
	CalciteContent   float64 `json:"calcite_content_percentage,omitempty"`
	QuartzContent    float64 `json:"quartz_content_percentage,omitempty"`
	OtherMinerals    float64 `json:"other_minerals_percentage,omitempty"`
	
	// Processing parameters
	ThresholdValue   float64 `json:"threshold_value,omitempty"`
	ParticleCount    int     `json:"particle_count,omitempty"`
	AverageParticleSize float64 `json:"average_particle_size_um,omitempty"`
}
