package config

import (
	"fmt"
	"os"

	"github.com/spf13/viper"
)

// Config holds all configuration for the application
type Config struct {
	Environment string `mapstructure:"ENVIRONMENT"`
	Port        string `mapstructure:"PORT"`
	LogLevel    string `mapstructure:"LOG_LEVEL"`
	
	// Fiji/ImageJ settings
	FijiPath     string `mapstructure:"FIJI_PATH"`
	TempDir      string `mapstructure:"TEMP_DIR"`
	MaxFileSize  int64  `mapstructure:"MAX_FILE_SIZE"`
	
	// Analysis settings
	AnalysisTimeout int `mapstructure:"ANALYSIS_TIMEOUT"`
}

// Load reads configuration from file or environment variables
func Load() (*Config, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")
	
	// Set default values
	setDefaults()
	
	// Read environment variables
	viper.AutomaticEnv()
	
	// Read config file if it exists
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("failed to read config file: %w", err)
		}
	}
	
	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}
	
	// Validate configuration
	if err := validateConfig(&config); err != nil {
		return nil, fmt.Errorf("invalid configuration: %w", err)
	}
	
	return &config, nil
}

func setDefaults() {
	viper.SetDefault("ENVIRONMENT", "development")
	viper.SetDefault("PORT", "8080")
	viper.SetDefault("LOG_LEVEL", "info")
	viper.SetDefault("FIJI_PATH", "/opt/fiji/Fiji.app/ImageJ-linux64")
	viper.SetDefault("TEMP_DIR", "/tmp/gypsum-analysis")
	viper.SetDefault("MAX_FILE_SIZE", 50*1024*1024) // 50MB
	viper.SetDefault("ANALYSIS_TIMEOUT", 300) // 5 minutes
}

func validateConfig(config *Config) error {
	// Check if Fiji executable exists
	if _, err := os.Stat(config.FijiPath); os.IsNotExist(err) {
		return fmt.Errorf("Fiji executable not found at %s", config.FijiPath)
	}
	
	// Create temp directory if it doesn't exist
	if err := os.MkdirAll(config.TempDir, 0755); err != nil {
		return fmt.Errorf("failed to create temp directory: %w", err)
	}
	
	return nil
}
