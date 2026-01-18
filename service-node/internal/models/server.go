// Package models defines server and credential structures.
package models

import (
	"time"

	"github.com/google/uuid"
)

// ServerStatus represents the current status of a server.
type ServerStatus string

const (
	StatusOnline  ServerStatus = "online"
	StatusOffline ServerStatus = "offline"
	StatusWarning ServerStatus = "warning"
	StatusUnknown ServerStatus = "unknown"
)

// AuthMethod represents the authentication method for a server.
type AuthMethod string

const (
	AuthMethodPassword AuthMethod = "password"
	AuthMethodSSHKey   AuthMethod = "ssh_key"
	AuthMethodNone     AuthMethod = "none"
)

// Server represents a monitored server.
type Server struct {
	ID                  uuid.UUID    `json:"id"`
	Name                string       `json:"name"`
	Hostname            string       `json:"hostname"`
	Port                int          `json:"port"`
	Description         string       `json:"description,omitempty"`
	Tags                []string     `json:"tags"`
	Folder              string       `json:"folder,omitempty"`
	Status              ServerStatus `json:"status"`
	AuthMethod          AuthMethod   `json:"auth_method"`
	DefaultCredentialID *uuid.UUID   `json:"default_credential_id,omitempty"`
	LastSeenAt          *time.Time   `json:"last_seen_at,omitempty"`
	CreatedBy           *uuid.UUID   `json:"created_by,omitempty"`
	CreatedAt           time.Time    `json:"created_at"`
	UpdatedAt           time.Time    `json:"updated_at"`
}

// ServerCreate is used when creating a new server.
type ServerCreate struct {
	Name                string     `json:"name" validate:"required,min=1,max=128"`
	Hostname            string     `json:"hostname" validate:"required"`
	Port                int        `json:"port,omitempty"`
	Description         string     `json:"description,omitempty"`
	Tags                []string   `json:"tags,omitempty"`
	Folder              string     `json:"folder,omitempty"`
	AuthMethod          AuthMethod `json:"auth_method,omitempty"`
	DefaultCredentialID *uuid.UUID `json:"default_credential_id,omitempty"`
}

// ServerUpdate is used when updating an existing server.
type ServerUpdate struct {
	Name                *string     `json:"name,omitempty"`
	Hostname            *string     `json:"hostname,omitempty"`
	Port                *int        `json:"port,omitempty"`
	Description         *string     `json:"description,omitempty"`
	Tags                *[]string   `json:"tags,omitempty"`
	Folder              *string     `json:"folder,omitempty"`
	AuthMethod          *AuthMethod `json:"auth_method,omitempty"`
	DefaultCredentialID *uuid.UUID  `json:"default_credential_id,omitempty"`
}

// CredentialType represents the type of credential.
type CredentialType string

const (
	CredTypeSSHPassword CredentialType = "ssh_password"
	CredTypeSSHKey      CredentialType = "ssh_key"
	CredTypeDocker      CredentialType = "docker"
	CredTypeKubernetes  CredentialType = "kubernetes"
	CredTypeProxmox     CredentialType = "proxmox"
)

// Credential represents stored credentials for a server.
type Credential struct {
	ID            uuid.UUID      `json:"id"`
	ServerID      *uuid.UUID     `json:"server_id,omitempty"`
	Name          string         `json:"name"`
	Type          CredentialType `json:"type"`
	Username      string         `json:"username,omitempty"`
	EncryptedData []byte         `json:"-"` // Never expose
	Nonce         []byte         `json:"-"` // Never expose
	IsDefault     bool           `json:"is_default"`
	CreatedAt     time.Time      `json:"created_at"`
	UpdatedAt     time.Time      `json:"updated_at"`
}

// CredentialCreate is used when creating new credentials.
type CredentialCreate struct {
	ServerID  *uuid.UUID     `json:"server_id,omitempty"`
	Name      string         `json:"name" validate:"required"`
	Type      CredentialType `json:"type" validate:"required"`
	Username  string         `json:"username,omitempty"`
	Password  string         `json:"password,omitempty"`  // For SSH password
	PrivateKey string        `json:"private_key,omitempty"` // For SSH key
	Passphrase string        `json:"passphrase,omitempty"` // For SSH key passphrase
	Token     string         `json:"token,omitempty"`      // For API tokens
	IsDefault bool           `json:"is_default,omitempty"`
}

// SSHHostKey represents a stored SSH host key.
type SSHHostKey struct {
	ID          uuid.UUID  `json:"id"`
	ServerID    uuid.UUID  `json:"server_id"`
	KeyType     string     `json:"key_type"`
	PublicKey   string     `json:"public_key"`
	Fingerprint string     `json:"fingerprint"`
	VerifiedAt  time.Time  `json:"verified_at"`
	CreatedAt   time.Time  `json:"created_at"`
}

// ServerWithMetrics represents a server with its latest metrics.
type ServerWithMetrics struct {
	Server
	CPUPercent    float64 `json:"cpu_percent,omitempty"`
	MemoryPercent float64 `json:"memory_percent,omitempty"`
	DiskPercent   float64 `json:"disk_percent,omitempty"`
	Uptime        int64   `json:"uptime,omitempty"` // seconds
}
