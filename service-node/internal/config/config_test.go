package config

import (
	"os"
	"testing"
)

func TestLoad(t *testing.T) {
	// Test default values
	cfg := Load()

	if cfg.BindAddr != "127.0.0.1:8080" {
		t.Errorf("expected default BindAddr '127.0.0.1:8080', got '%s'", cfg.BindAddr)
	}

	if cfg.LogLevel != "info" {
		t.Errorf("expected default LogLevel 'info', got '%s'", cfg.LogLevel)
	}

	if cfg.RateLimit != 100 {
		t.Errorf("expected default RateLimit 100, got %d", cfg.RateLimit)
	}
}

func TestLoadWithEnvVars(t *testing.T) {
	// Set environment variables
	os.Setenv("BIND_ADDR", "0.0.0.0:9000")
	os.Setenv("LOG_LEVEL", "debug")
	os.Setenv("RATE_LIMIT", "200")
	defer func() {
		os.Unsetenv("BIND_ADDR")
		os.Unsetenv("LOG_LEVEL")
		os.Unsetenv("RATE_LIMIT")
	}()

	cfg := Load()

	if cfg.BindAddr != "0.0.0.0:9000" {
		t.Errorf("expected BindAddr '0.0.0.0:9000', got '%s'", cfg.BindAddr)
	}

	if cfg.LogLevel != "debug" {
		t.Errorf("expected LogLevel 'debug', got '%s'", cfg.LogLevel)
	}

	if cfg.RateLimit != 200 {
		t.Errorf("expected RateLimit 200, got %d", cfg.RateLimit)
	}
}

func TestGetEnv(t *testing.T) {
	// Test with unset variable
	result := getEnv("NONEXISTENT_VAR", "default")
	if result != "default" {
		t.Errorf("expected 'default', got '%s'", result)
	}

	// Test with set variable
	os.Setenv("TEST_VAR", "custom")
	defer os.Unsetenv("TEST_VAR")

	result = getEnv("TEST_VAR", "default")
	if result != "custom" {
		t.Errorf("expected 'custom', got '%s'", result)
	}
}

func TestGetEnvInt(t *testing.T) {
	// Test with unset variable
	result := getEnvInt("NONEXISTENT_INT_VAR", 42)
	if result != 42 {
		t.Errorf("expected 42, got %d", result)
	}

	// Test with valid integer
	os.Setenv("TEST_INT_VAR", "100")
	defer os.Unsetenv("TEST_INT_VAR")

	result = getEnvInt("TEST_INT_VAR", 42)
	if result != 100 {
		t.Errorf("expected 100, got %d", result)
	}

	// Test with invalid integer
	os.Setenv("TEST_INVALID_INT", "not-a-number")
	defer os.Unsetenv("TEST_INVALID_INT")

	result = getEnvInt("TEST_INVALID_INT", 42)
	if result != 42 {
		t.Errorf("expected 42 for invalid int, got %d", result)
	}
}
