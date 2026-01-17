// Package auth provides authentication and authorization services.
package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/pulse-server/service-node/internal/models"
	"github.com/pulse-server/service-node/internal/repository"
)

// Common errors
var (
	ErrInvalidCredentials = errors.New("invalid username or password")
	ErrUserInactive       = errors.New("user account is inactive")
	ErrTokenExpired       = errors.New("token has expired")
	ErrTokenInvalid       = errors.New("token is invalid")
	ErrTokenRevoked       = errors.New("token has been revoked")
)

// Config holds authentication configuration.
type Config struct {
	JWTSecret           string
	AccessTokenExpiry   time.Duration
	RefreshTokenExpiry  time.Duration
	Issuer              string
}

// DefaultConfig returns sensible default configuration.
func DefaultConfig(jwtSecret string) Config {
	return Config{
		JWTSecret:          jwtSecret,
		AccessTokenExpiry:  15 * time.Minute,
		RefreshTokenExpiry: 7 * 24 * time.Hour, // 7 days
		Issuer:             "pulse-service-node",
	}
}

// Service provides authentication operations.
type Service struct {
	config    Config
	userRepo  *repository.UserRepository
	tokenRepo *repository.RefreshTokenRepository
	auditRepo *repository.AuditLogRepository
}

// NewService creates a new authentication service.
func NewService(
	config Config,
	userRepo *repository.UserRepository,
	tokenRepo *repository.RefreshTokenRepository,
	auditRepo *repository.AuditLogRepository,
) *Service {
	return &Service{
		config:    config,
		userRepo:  userRepo,
		tokenRepo: tokenRepo,
		auditRepo: auditRepo,
	}
}

// JWTClaims represents the claims in a JWT token.
type JWTClaims struct {
	jwt.RegisteredClaims
	UserID   uuid.UUID        `json:"uid"`
	Username string           `json:"username"`
	Role     models.UserRole  `json:"role"`
}

// Login authenticates a user and returns tokens.
func (s *Service) Login(ctx context.Context, req *models.LoginRequest, ipAddress, userAgent string) (*models.LoginResponse, error) {
	// Find user by username
	user, err := s.userRepo.GetByUsername(ctx, req.Username)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			s.logAudit(ctx, nil, "login_failed", "user", nil, ipAddress, userAgent, map[string]string{
				"reason":   "user_not_found",
				"username": req.Username,
			})
			return nil, ErrInvalidCredentials
		}
		return nil, fmt.Errorf("failed to find user: %w", err)
	}

	// Check if user is active
	if !user.IsActive {
		s.logAudit(ctx, &user.ID, "login_failed", "user", &user.ID, ipAddress, userAgent, map[string]string{
			"reason": "user_inactive",
		})
		return nil, ErrUserInactive
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		s.logAudit(ctx, &user.ID, "login_failed", "user", &user.ID, ipAddress, userAgent, map[string]string{
			"reason": "invalid_password",
		})
		return nil, ErrInvalidCredentials
	}

	// Generate tokens
	accessToken, err := s.generateAccessToken(user)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	refreshToken, err := s.generateRefreshToken(ctx, user)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	// Update last login
	if err := s.userRepo.UpdateLastLogin(ctx, user.ID); err != nil {
		// Non-fatal error, just log it
		fmt.Printf("Warning: failed to update last login: %v\n", err)
	}

	// Audit log
	s.logAudit(ctx, &user.ID, "login_success", "user", &user.ID, ipAddress, userAgent, nil)

	return &models.LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    int(s.config.AccessTokenExpiry.Seconds()),
		TokenType:    "Bearer",
		User:         user,
	}, nil
}

// Refresh exchanges a refresh token for new tokens.
func (s *Service) Refresh(ctx context.Context, refreshToken string, ipAddress, userAgent string) (*models.LoginResponse, error) {
	// Hash the token to look it up
	tokenHash := hashToken(refreshToken)

	// Find the token
	storedToken, err := s.tokenRepo.GetByHash(ctx, tokenHash)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil, ErrTokenInvalid
		}
		return nil, fmt.Errorf("failed to find token: %w", err)
	}

	// Check if expired
	if time.Now().After(storedToken.ExpiresAt) {
		return nil, ErrTokenExpired
	}

	// Check if revoked
	if storedToken.RevokedAt != nil {
		return nil, ErrTokenRevoked
	}

	// Get the user
	user, err := s.userRepo.GetByID(ctx, storedToken.UserID)
	if err != nil {
		return nil, fmt.Errorf("failed to find user: %w", err)
	}

	// Check if user is still active
	if !user.IsActive {
		return nil, ErrUserInactive
	}

	// Revoke the old token (rotate tokens)
	if err := s.tokenRepo.Revoke(ctx, tokenHash); err != nil {
		return nil, fmt.Errorf("failed to revoke old token: %w", err)
	}

	// Generate new tokens
	accessToken, err := s.generateAccessToken(user)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	newRefreshToken, err := s.generateRefreshToken(ctx, user)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	// Audit log
	s.logAudit(ctx, &user.ID, "token_refresh", "user", &user.ID, ipAddress, userAgent, nil)

	return &models.LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		ExpiresIn:    int(s.config.AccessTokenExpiry.Seconds()),
		TokenType:    "Bearer",
		User:         user,
	}, nil
}

// Logout revokes the user's refresh token.
func (s *Service) Logout(ctx context.Context, refreshToken string, ipAddress, userAgent string) error {
	tokenHash := hashToken(refreshToken)

	storedToken, err := s.tokenRepo.GetByHash(ctx, tokenHash)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			return nil // Already logged out or invalid token
		}
		return fmt.Errorf("failed to find token: %w", err)
	}

	if err := s.tokenRepo.Revoke(ctx, tokenHash); err != nil {
		return fmt.Errorf("failed to revoke token: %w", err)
	}

	// Audit log
	s.logAudit(ctx, &storedToken.UserID, "logout", "user", &storedToken.UserID, ipAddress, userAgent, nil)

	return nil
}

// LogoutAll revokes all refresh tokens for a user.
func (s *Service) LogoutAll(ctx context.Context, userID uuid.UUID, ipAddress, userAgent string) error {
	if err := s.tokenRepo.RevokeAllForUser(ctx, userID); err != nil {
		return fmt.Errorf("failed to revoke all tokens: %w", err)
	}

	s.logAudit(ctx, &userID, "logout_all", "user", &userID, ipAddress, userAgent, nil)

	return nil
}

// ValidateAccessToken validates a JWT access token and returns the claims.
func (s *Service) ValidateAccessToken(tokenString string) (*JWTClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(s.config.JWTSecret), nil
	})

	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			return nil, ErrTokenExpired
		}
		return nil, ErrTokenInvalid
	}

	claims, ok := token.Claims.(*JWTClaims)
	if !ok || !token.Valid {
		return nil, ErrTokenInvalid
	}

	return claims, nil
}

// GetUserFromToken retrieves the full user object from a token's claims.
func (s *Service) GetUserFromToken(ctx context.Context, claims *JWTClaims) (*models.User, error) {
	return s.userRepo.GetByID(ctx, claims.UserID)
}

// HashPassword hashes a password using bcrypt.
func HashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", fmt.Errorf("failed to hash password: %w", err)
	}
	return string(hash), nil
}

// generateAccessToken creates a new JWT access token.
func (s *Service) generateAccessToken(user *models.User) (string, error) {
	now := time.Now()
	claims := &JWTClaims{
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    s.config.Issuer,
			Subject:   user.ID.String(),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.config.AccessTokenExpiry)),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			ID:        uuid.New().String(),
		},
		UserID:   user.ID,
		Username: user.Username,
		Role:     user.Role,
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.config.JWTSecret))
}

// generateRefreshToken creates a new refresh token and stores it.
func (s *Service) generateRefreshToken(ctx context.Context, user *models.User) (string, error) {
	// Generate random token
	tokenBytes := make([]byte, 32)
	if _, err := rand.Read(tokenBytes); err != nil {
		return "", fmt.Errorf("failed to generate random token: %w", err)
	}
	token := base64.URLEncoding.EncodeToString(tokenBytes)

	// Store hashed token
	refreshToken := &models.RefreshToken{
		UserID:    user.ID,
		TokenHash: hashToken(token),
		ExpiresAt: time.Now().Add(s.config.RefreshTokenExpiry),
	}

	if err := s.tokenRepo.Create(ctx, refreshToken); err != nil {
		return "", fmt.Errorf("failed to store refresh token: %w", err)
	}

	return token, nil
}

// hashToken creates a SHA-256 hash of a token.
func hashToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return base64.URLEncoding.EncodeToString(hash[:])
}

// logAudit records an audit event (non-blocking).
func (s *Service) logAudit(ctx context.Context, userID *uuid.UUID, action, resourceType string, resourceID *uuid.UUID, ipAddress, userAgent string, details any) {
	log := &models.AuditLog{
		UserID:       userID,
		Action:       action,
		ResourceType: resourceType,
		ResourceID:   resourceID,
		IPAddress:    ipAddress,
		UserAgent:    userAgent,
		Details:      details,
	}

	// Create in background to not block the request
	go func() {
		bgCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := s.auditRepo.Create(bgCtx, log); err != nil {
			fmt.Printf("Warning: failed to create audit log: %v\n", err)
		}
	}()
}
