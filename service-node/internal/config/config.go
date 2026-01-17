package config

import (
	"fmt"
	"os"
)

// Config holds application configuration
type Config struct {
	// Server
	BindAddr string
	LogLevel string

	// Database
	DatabaseURL string

	// Security
	ServiceNodeSecret string

	// SMTP
	SMTPHost     string
	SMTPPort     string
	SMTPUser     string
	SMTPPassword string
	SMTPFrom     string
	SMTPTLS      bool

	// Rate limiting
	RateLimit int

	// Collectors
	CollectInterval int
	CollectTimeout  int
	CollectWorkers  int

	// Retention
	MetricsRetentionDays           int
	MetricsDownsampleRetentionDays int
	LogsRetentionDays              int
}

// Load reads configuration from environment variables
func Load() *Config {
	return &Config{
		BindAddr:          getEnv("BIND_ADDR", "127.0.0.1:8080"),
		LogLevel:          getEnv("LOG_LEVEL", "info"),
		DatabaseURL:       getEnv("DATABASE_URL", "postgres://pulse:pulse@localhost:5432/pulse?sslmode=disable"),
		ServiceNodeSecret: getEnv("SERVICE_NODE_SECRET", ""),
		SMTPHost:          getEnv("SMTP_HOST", ""),
		SMTPPort:          getEnv("SMTP_PORT", "587"),
		SMTPUser:          getEnv("SMTP_USER", ""),
		SMTPPassword:      getEnv("SMTP_PASSWORD", ""),
		SMTPFrom:          getEnv("SMTP_FROM", ""),
		SMTPTLS:           getEnv("SMTP_TLS", "true") == "true",
		RateLimit:         getEnvInt("RATE_LIMIT", 100),
		CollectInterval:   getEnvInt("COLLECT_INTERVAL", 15),
		CollectTimeout:    getEnvInt("COLLECT_TIMEOUT", 10),
		CollectWorkers:    getEnvInt("COLLECT_WORKERS", 10),
		MetricsRetentionDays:           getEnvInt("METRICS_RETENTION_DAYS", 7),
		MetricsDownsampleRetentionDays: getEnvInt("METRICS_DOWNSAMPLE_RETENTION_DAYS", 90),
		LogsRetentionDays:              getEnvInt("LOGS_RETENTION_DAYS", 7),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		var result int
		if _, err := fmt.Sscanf(value, "%d", &result); err == nil {
			return result
		}
	}
	return defaultValue
}
