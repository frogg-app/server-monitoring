// Package models defines the data structures used throughout the application.
package models

import (
	"time"

	"github.com/google/uuid"
)

// UserRole represents the role of a user in the system.
type UserRole string

const (
	RoleAdmin  UserRole = "admin"
	RoleEditor UserRole = "editor"
	RoleViewer UserRole = "viewer"
)

// User represents a user account.
type User struct {
	ID           uuid.UUID  `json:"id"`
	Username     string     `json:"username"`
	Email        string     `json:"email"`
	PasswordHash string     `json:"-"` // Never expose in JSON
	DisplayName  string     `json:"display_name,omitempty"`
	Role         UserRole   `json:"role"`
	IsActive     bool       `json:"is_active"`
	LastLoginAt  *time.Time `json:"last_login_at,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
}

// UserCreate is used when creating a new user.
type UserCreate struct {
	Username    string   `json:"username" validate:"required,min=3,max=64"`
	Email       string   `json:"email" validate:"required,email"`
	Password    string   `json:"password" validate:"required,min=8"`
	DisplayName string   `json:"display_name,omitempty"`
	Role        UserRole `json:"role,omitempty"`
}

// UserUpdate is used when updating an existing user.
type UserUpdate struct {
	Email       *string   `json:"email,omitempty" validate:"omitempty,email"`
	DisplayName *string   `json:"display_name,omitempty"`
	Role        *UserRole `json:"role,omitempty"`
	IsActive    *bool     `json:"is_active,omitempty"`
}

// RefreshToken represents a stored refresh token.
type RefreshToken struct {
	ID        uuid.UUID  `json:"id"`
	UserID    uuid.UUID  `json:"user_id"`
	TokenHash string     `json:"-"`
	ExpiresAt time.Time  `json:"expires_at"`
	CreatedAt time.Time  `json:"created_at"`
	RevokedAt *time.Time `json:"revoked_at,omitempty"`
}

// AuditLog represents a security audit event.
type AuditLog struct {
	ID           uuid.UUID  `json:"id"`
	UserID       *uuid.UUID `json:"user_id,omitempty"`
	Action       string     `json:"action"`
	ResourceType string     `json:"resource_type,omitempty"`
	ResourceID   *uuid.UUID `json:"resource_id,omitempty"`
	IPAddress    string     `json:"ip_address,omitempty"`
	UserAgent    string     `json:"user_agent,omitempty"`
	Details      any        `json:"details,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
}

// LoginRequest represents a login attempt.
type LoginRequest struct {
	Username string `json:"username" validate:"required"`
	Password string `json:"password" validate:"required"`
}

// LoginResponse contains the tokens returned after successful login.
type LoginResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in"` // seconds
	TokenType    string `json:"token_type"`
	User         *User  `json:"user"`
}

// RefreshRequest is used to refresh an access token.
type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

// TokenClaims represents the JWT claims.
type TokenClaims struct {
	UserID   uuid.UUID `json:"uid"`
	Username string    `json:"username"`
	Role     UserRole  `json:"role"`
}
