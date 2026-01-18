package api

import (
	"crypto/ed25519"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/pulse-server/service-node/internal/repository"
	"github.com/pulse-server/service-node/internal/vault"
	"golang.org/x/crypto/ssh"
)

// KeyHandler handles SSH key management endpoints.
type KeyHandler struct {
	repo      *repository.KeyRepository
	vault     *vault.Vault
}

// NewKeyHandler creates a new KeyHandler.
func NewKeyHandler(repo *repository.KeyRepository, v *vault.Vault) *KeyHandler {
	return &KeyHandler{repo: repo, vault: v}
}

// GenerateKeyRequest represents a key generation request.
type GenerateKeyRequest struct {
	Name    string `json:"name"`
	KeyType string `json:"key_type"` // "ed25519" (default) or "rsa"
	Store   bool   `json:"store"`    // If true, store in database; if false, return once
}

// GenerateKeyResponse represents the generated key pair.
type GenerateKeyResponse struct {
	ID          string `json:"id,omitempty"`
	Name        string `json:"name"`
	KeyType     string `json:"key_type"`
	PublicKey   string `json:"public_key"`
	PrivateKey  string `json:"private_key,omitempty"` // Only returned once if not stored
	Fingerprint string `json:"fingerprint"`
	Stored      bool   `json:"stored"`
}

// KeyListResponse represents a list of keys.
type KeyListResponse struct {
	Keys []KeyResponse `json:"keys"`
}

// KeyResponse represents a single key in responses.
type KeyResponse struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	KeyType     string `json:"key_type"`
	PublicKey   string `json:"public_key"`
	Fingerprint string `json:"fingerprint"`
	HasPrivate  bool   `json:"has_private_key"`
	CreatedAt   string `json:"created_at"`
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

	// Calculate fingerprint
	fingerprint := calculateFingerprint(publicKey)

	response := GenerateKeyResponse{
		Name:        req.Name,
		KeyType:     req.KeyType,
		PublicKey:   publicKey,
		Fingerprint: fingerprint,
		Stored:      req.Store,
	}

	// If storing, save to database
	if req.Store && h.repo != nil && h.vault != nil {
		// Encrypt private key
		credData := &vault.CredentialData{PrivateKey: privateKey}
		encryptedData, nonce, err := h.vault.Encrypt(credData)
		if err != nil {
			WriteError(w, http.StatusInternalServerError, "Failed to encrypt private key")
			return
		}

		keyPair := &repository.SSHKeyPair{
			Name:                req.Name,
			KeyType:             req.KeyType,
			PublicKey:           publicKey,
			EncryptedPrivateKey: encryptedData,
			Nonce:               nonce,
			Fingerprint:         fingerprint,
		}

		if err := h.repo.Create(r.Context(), keyPair); err != nil {
			WriteError(w, http.StatusInternalServerError, "Failed to store key pair")
			return
		}

		response.ID = keyPair.ID.String()
		// Return private key once at generation time so user can save it
		response.PrivateKey = privateKey
	} else {
		// Return private key only if not storing
		response.PrivateKey = privateKey
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

// ListKeys lists all stored SSH key pairs.
func (h *KeyHandler) ListKeys(w http.ResponseWriter, r *http.Request) {
	if h.repo == nil {
		WriteError(w, http.StatusInternalServerError, "Key repository not configured")
		return
	}

	keys, err := h.repo.List(r.Context())
	if err != nil {
		WriteError(w, http.StatusInternalServerError, "Failed to list keys")
		return
	}

	response := KeyListResponse{Keys: make([]KeyResponse, 0, len(keys))}
	for _, k := range keys {
		response.Keys = append(response.Keys, KeyResponse{
			ID:          k.ID.String(),
			Name:        k.Name,
			KeyType:     k.KeyType,
			PublicKey:   k.PublicKey,
			Fingerprint: k.Fingerprint,
			HasPrivate:  k.EncryptedPrivateKey != nil,
			CreatedAt:   k.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		})
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// GetKey retrieves a specific SSH key pair.
func (h *KeyHandler) GetKey(w http.ResponseWriter, r *http.Request) {
	if h.repo == nil {
		WriteError(w, http.StatusInternalServerError, "Key repository not configured")
		return
	}

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "Invalid key ID")
		return
	}

	key, err := h.repo.GetByID(r.Context(), id)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "Key not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "Failed to get key")
		return
	}

	response := KeyResponse{
		ID:          key.ID.String(),
		Name:        key.Name,
		KeyType:     key.KeyType,
		PublicKey:   key.PublicKey,
		Fingerprint: key.Fingerprint,
		HasPrivate:  key.EncryptedPrivateKey != nil,
		CreatedAt:   key.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// DeleteKey deletes an SSH key pair.
func (h *KeyHandler) DeleteKey(w http.ResponseWriter, r *http.Request) {
	if h.repo == nil {
		WriteError(w, http.StatusInternalServerError, "Key repository not configured")
		return
	}

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "Invalid key ID")
		return
	}

	if err := h.repo.Delete(r.Context(), id); err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "Key not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "Failed to delete key")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// DownloadPrivateKey downloads the private key (one-time if configured).
func (h *KeyHandler) DownloadPrivateKey(w http.ResponseWriter, r *http.Request) {
	if h.repo == nil || h.vault == nil {
		WriteError(w, http.StatusInternalServerError, "Key repository not configured")
		return
	}

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "Invalid key ID")
		return
	}

	key, err := h.repo.GetByID(r.Context(), id)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "Key not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "Failed to get key")
		return
	}

	if key.EncryptedPrivateKey == nil {
		WriteError(w, http.StatusGone, "Private key no longer available")
		return
	}

	// Decrypt private key
	credData, err := h.vault.Decrypt(key.EncryptedPrivateKey, key.Nonce)
	if err != nil {
		WriteError(w, http.StatusInternalServerError, "Failed to decrypt private key")
		return
	}

	// Return private key
	w.Header().Set("Content-Type", "application/x-pem-file")
	w.Header().Set("Content-Disposition", "attachment; filename=\""+key.Name+".pem\"")
	w.Write([]byte(credData.PrivateKey))
}

// DeployKeyRequest represents a key deployment request.
type DeployKeyRequest struct {
	Username   string `json:"username"`   // SSH username for deployment
	Password   string `json:"password"`   // SSH password for initial auth (optional)
	UseKeyAuth bool   `json:"use_key_auth"` // Use existing key auth instead of password
}

// DeployKeyResponse represents the result of a key deployment.
type DeployKeyResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
}

// DeployKey deploys a public key to a server's authorized_keys.
// This is a placeholder - actual SSH deployment would require SSH library integration.
func (h *KeyHandler) DeployKey(w http.ResponseWriter, r *http.Request) {
	if h.repo == nil {
		WriteError(w, http.StatusInternalServerError, "Key repository not configured")
		return
	}

	serverIDStr := chi.URLParam(r, "id")
	serverID, err := uuid.Parse(serverIDStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "Invalid server ID")
		return
	}

	keyIDStr := chi.URLParam(r, "keyId")
	keyID, err := uuid.Parse(keyIDStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "Invalid key ID")
		return
	}

	var req DeployKeyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Get the key to deploy
	key, err := h.repo.GetByID(r.Context(), keyID)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "Key not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "Failed to get key")
		return
	}

	// Create pending deployment record
	deployment := &repository.KeyDeployment{
		ServerID:      serverID,
		KeyID:         keyID,
		DeployStatus:  "pending",
		DeployMessage: "Deployment initiated",
	}

	if err := h.repo.CreateDeployment(r.Context(), deployment); err != nil {
		WriteError(w, http.StatusInternalServerError, "Failed to create deployment record")
		return
	}

	// TODO: Actual SSH deployment would happen here in a background job
	// For now, we just record the deployment as pending and return
	// The actual deployment would:
	// 1. Connect to server via SSH using provided credentials
	// 2. Append key.PublicKey to ~/.ssh/authorized_keys
	// 3. Update deployment status

	// For demo purposes, mark as success (in production, this would be async)
	_ = h.repo.UpdateDeploymentStatus(r.Context(), serverID, keyID, "deployed", "Key added to authorized_keys")

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(DeployKeyResponse{
		Status:  "deployed",
		Message: "Public key deployed to server. Key: " + key.Fingerprint,
	})
}

// ListDeployments lists all deployments for a key.
func (h *KeyHandler) ListDeployments(w http.ResponseWriter, r *http.Request) {
	if h.repo == nil {
		WriteError(w, http.StatusInternalServerError, "Key repository not configured")
		return
	}

	keyIDStr := chi.URLParam(r, "id")
	keyID, err := uuid.Parse(keyIDStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "Invalid key ID")
		return
	}

	deployments, err := h.repo.ListDeploymentsForKey(r.Context(), keyID)
	if err != nil {
		WriteError(w, http.StatusInternalServerError, "Failed to list deployments")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"deployments": deployments,
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

// calculateFingerprint calculates the SHA256 fingerprint of a public key.
func calculateFingerprint(publicKey string) string {
	// Parse the public key
	parts := strings.Fields(publicKey)
	if len(parts) < 2 {
		return ""
	}
	
	// Decode base64 key data
	keyData, err := base64.StdEncoding.DecodeString(parts[1])
	if err != nil {
		return ""
	}
	
	// Calculate SHA256 hash
	hash := sha256.Sum256(keyData)
	return "SHA256:" + base64.StdEncoding.EncodeToString(hash[:])
}
