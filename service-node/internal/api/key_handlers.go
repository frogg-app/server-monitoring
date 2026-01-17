package api

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/json"
	"encoding/pem"
	"net/http"

	"golang.org/x/crypto/ssh"
)

// KeyHandler handles SSH key management endpoints.
type KeyHandler struct{}

// NewKeyHandler creates a new KeyHandler.
func NewKeyHandler() *KeyHandler {
	return &KeyHandler{}
}

// GenerateKeyRequest represents a key generation request.
type GenerateKeyRequest struct {
	Name    string `json:"name"`
	KeyType string `json:"key_type"` // "ed25519" (default) or "rsa"
}

// GenerateKeyResponse represents the generated key pair.
type GenerateKeyResponse struct {
	Name       string `json:"name"`
	KeyType    string `json:"key_type"`
	PublicKey  string `json:"public_key"`
	PrivateKey string `json:"private_key"` // Only returned once
}

// GenerateKey generates a new SSH key pair.
func (h *KeyHandler) GenerateKey(w http.ResponseWriter, r *http.Request) {
	var req GenerateKeyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.Name == "" {
		req.Name = "Generated Key"
	}
	if req.KeyType == "" {
		req.KeyType = "ed25519"
	}

	var publicKey, privateKey string
	var err error

	switch req.KeyType {
	case "ed25519":
		publicKey, privateKey, err = generateEd25519Key()
	default:
		WriteError(w, http.StatusBadRequest, "Unsupported key type. Use 'ed25519'")
		return
	}

	if err != nil {
		WriteError(w, http.StatusInternalServerError, "Failed to generate key pair")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(GenerateKeyResponse{
		Name:       req.Name,
		KeyType:    req.KeyType,
		PublicKey:  publicKey,
		PrivateKey: privateKey,
	})
}

// generateEd25519Key generates an Ed25519 SSH key pair.
func generateEd25519Key() (publicKey, privateKey string, err error) {
	pubKey, privKey, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		return "", "", err
	}

	// Convert to SSH format
	sshPubKey, err := ssh.NewPublicKey(pubKey)
	if err != nil {
		return "", "", err
	}
	publicKey = string(ssh.MarshalAuthorizedKey(sshPubKey))

	// Marshal private key to OpenSSH format
	pemBlock, err := ssh.MarshalPrivateKey(privKey, "")
	if err != nil {
		return "", "", err
	}
	privateKey = string(pem.EncodeToMemory(pemBlock))

	return publicKey, privateKey, nil
}
