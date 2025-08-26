package logger

import (
	"os"

	"github.com/sirupsen/logrus"
)

// Logger wraps logrus logger
type Logger struct {
	*logrus.Logger
}

// WithField adds a field to the logger
func (l *Logger) WithField(key string, value interface{}) *logrus.Entry {
	return l.Logger.WithField(key, value)
}

// WithError adds an error field to the logger
func (l *Logger) WithError(err error) *logrus.Entry {
	return l.Logger.WithError(err)
}

// New creates a new logger instance
func New(level string) *Logger {
	logger := logrus.New()
	
	// Set output to stdout
	logger.SetOutput(os.Stdout)
	
	// Set log level
	switch level {
	case "debug":
		logger.SetLevel(logrus.DebugLevel)
	case "info":
		logger.SetLevel(logrus.InfoLevel)
	case "warn":
		logger.SetLevel(logrus.WarnLevel)
	case "error":
		logger.SetLevel(logrus.ErrorLevel)
	default:
		logger.SetLevel(logrus.InfoLevel)
	}
	
	// Set formatter
	logger.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: "2006-01-02T15:04:05.000Z07:00",
	})
	
	return &Logger{logger}
}
