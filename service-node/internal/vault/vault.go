// Package vault provides encrypted credential storage.
package vault

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"io"
)

// Common errors
var (
	ErrInvalidKey    = errors.New("invalid encryption key: must be 32 bytes")
	ErrDecryptFailed = errors.New("decryption failed")
)

// Vault provides encryption and decryption for credentials.
type Vault struct {
	key []byte
}

// New creates a new Vault with the given encryption key.
// The key must be exactly 32 bytes for AES-256.
func New(key []byte) (*Vault, error) {
	if len(key) != 32 {
		return nil, ErrInvalidKey
	}
	return &Vault{key: key}, nil
}

// NewFromString creates a new Vault from a string key.
// The key will be padded or truncated to 32 bytes.
func NewFromString(key string) (*Vault, error) {
	keyBytes := []byte(key)
	
	// Ensure key is exactly 32 bytes
	if len(keyBytes) < 32 {
		// Pad with zeros
		padded := make([]byte, 32)
		copy(padded, keyBytes)
		keyBytes = padded
	} else if len(keyBytes) > 32 {
		// Truncate
		keyBytes = keyBytes[:32]
	}
	
	return New(keyBytes)
}

// CredentialData represents the decrypted credential data.
type CredentialData struct {
	Password   string `json:"password,omitempty"`
	PrivateKey string `json:"private_key,omitempty"`
	Passphrase string `json:"passphrase,omitempty"`
	Token      string `json:"token,omitempty"`
	Extra      map[string]string `json:"extra,omitempty"`
}

// Encrypt encrypts credential data using AES-256-GCM.
// Returns the encrypted data and the nonce.
func (v *Vault) Encrypt(data *CredentialData) ([]byte, []byte, error) {
	// Serialize to JSON
	plaintext, err := json.Marshal(data)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to serialize credential data: %w", err)
	}

	// Create cipher
	block, err := aes.NewCipher(v.key)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to create cipher: %w", err)
	}

	// Create GCM
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to create GCM: %w", err)
	}

	// Generate nonce
	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, nil, fmt.Errorf("failed to generate nonce: %w", err)
	}

	// Encrypt
	ciphertext := gcm.Seal(nil, nonce, plaintext, nil)

	return ciphertext, nonce, nil
}

// Decrypt decrypts credential data using AES-256-GCM.
func (v *Vault) Decrypt(ciphertext, nonce []byte) (*CredentialData, error) {
	// Create cipher
	block, err := aes.NewCipher(v.key)
	if err != nil {
		return nil, fmt.Errorf("failed to create cipher: %w", err)
	}

	// Create GCM
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, fmt.Errorf("failed to create GCM: %w", err)
	}

	// Decrypt
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return nil, ErrDecryptFailed
	}

	// Deserialize from JSON
	var data CredentialData
	if err := json.Unmarshal(plaintext, &data); err != nil {
		return nil, fmt.Errorf("failed to deserialize credential data: %w", err)
	}

	return &data, nil
}

// EncryptString encrypts a simple string value.
func (v *Vault) EncryptString(value string) ([]byte, []byte, error) {
	data := &CredentialData{Password: value}
	return v.Encrypt(data)
}

// DecryptString decrypts a simple string value.
func (v *Vault) DecryptString(ciphertext, nonce []byte) (string, error) {
	data, err := v.Decrypt(ciphertext, nonce)
	if err != nil {
		return "", err
	}
	return data.Password, nil
}
