package auth

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/pulse-server/service-node/internal/models"
)

func TestDefaultConfig(t *testing.T) {
	secret := "test-secret-key"
	cfg := DefaultConfig(secret)

	if cfg.JWTSecret != secret {
		t.Errorf("expected JWTSecret '%s', got '%s'", secret, cfg.JWTSecret)
	}

	if cfg.AccessTokenExpiry != 15*time.Minute {
		t.Errorf("expected AccessTokenExpiry 15m, got %v", cfg.AccessTokenExpiry)
	}

	if cfg.RefreshTokenExpiry != 7*24*time.Hour {
		t.Errorf("expected RefreshTokenExpiry 7 days, got %v", cfg.RefreshTokenExpiry)
	}

	if cfg.Issuer != "pulse-service-node" {
		t.Errorf("expected Issuer 'pulse-service-node', got '%s'", cfg.Issuer)
	}
}

func TestHashPassword(t *testing.T) {
	password := "testpassword123"

	hash, err := HashPassword(password)
	if err != nil {
		t.Fatalf("failed to hash password: %v", err)
	}

	if hash == "" {
		t.Error("expected non-empty hash")
	}

	if hash == password {
		t.Error("hash should not equal plain password")
	}

	// Hash should be different each time (due to salt)
	hash2, err := HashPassword(password)
	if err != nil {
		t.Fatalf("failed to hash password second time: %v", err)
	}

	if hash == hash2 {
		t.Error("hashes should be different due to salt")
	}
}

func TestGenerateAndValidateAccessToken(t *testing.T) {
	config := DefaultConfig("test-secret-key-32-bytes-long!!")
	service := &Service{config: config}

	user := &models.User{
		ID:       uuid.New(),
		Username: "testuser",
		Role:     models.RoleAdmin,
	}

	// Generate token
	token, err := service.generateAccessToken(user)
	if err != nil {
		t.Fatalf("failed to generate access token: %v", err)
	}

	if token == "" {
		t.Error("expected non-empty token")
	}

	// Validate token
	claims, err := service.ValidateAccessToken(token)
	if err != nil {
		t.Fatalf("failed to validate access token: %v", err)
	}

	if claims.UserID != user.ID {
		t.Errorf("expected UserID %s, got %s", user.ID, claims.UserID)
	}

	if claims.Username != user.Username {
		t.Errorf("expected Username '%s', got '%s'", user.Username, claims.Username)
	}

	if claims.Role != user.Role {
		t.Errorf("expected Role '%s', got '%s'", user.Role, claims.Role)
	}
}

func TestValidateAccessToken_Invalid(t *testing.T) {
	config := DefaultConfig("test-secret-key-32-bytes-long!!")
	service := &Service{config: config}

	// Test with invalid token
	_, err := service.ValidateAccessToken("invalid-token")
	if err == nil {
		t.Error("expected error for invalid token")
	}

	if err != ErrTokenInvalid {
		t.Errorf("expected ErrTokenInvalid, got %v", err)
	}
}

func TestValidateAccessToken_WrongSecret(t *testing.T) {
	config1 := DefaultConfig("secret-key-one-32-bytes-long!!!")
	config2 := DefaultConfig("secret-key-two-32-bytes-long!!!")
	
	service1 := &Service{config: config1}
	service2 := &Service{config: config2}

	user := &models.User{
		ID:       uuid.New(),
		Username: "testuser",
		Role:     models.RoleViewer,
	}

	// Generate token with service1
	token, err := service1.generateAccessToken(user)
	if err != nil {
		t.Fatalf("failed to generate access token: %v", err)
	}

	// Try to validate with service2 (different secret)
	_, err = service2.ValidateAccessToken(token)
	if err == nil {
		t.Error("expected error when validating with wrong secret")
	}
}

func TestHashToken(t *testing.T) {
	token := "test-refresh-token-12345"

	hash1 := hashToken(token)
	hash2 := hashToken(token)

	// Same input should produce same hash
	if hash1 != hash2 {
		t.Error("expected same hash for same input")
	}

	// Different input should produce different hash
	hash3 := hashToken("different-token")
	if hash1 == hash3 {
		t.Error("expected different hash for different input")
	}
}
