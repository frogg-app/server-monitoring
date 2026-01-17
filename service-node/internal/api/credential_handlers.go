package api

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/pulse-server/service-node/internal/models"
	"github.com/pulse-server/service-node/internal/repository"
)

// CredentialHandler handles credential API endpoints.
type CredentialHandler struct {
	repo *repository.CredentialRepository
}

// NewCredentialHandler creates a new CredentialHandler.
func NewCredentialHandler(repo *repository.CredentialRepository) *CredentialHandler {
	return &CredentialHandler{repo: repo}
}

// ListForServer returns all credentials for a server.
func (h *CredentialHandler) ListForServer(w http.ResponseWriter, r *http.Request) {
	serverIDStr := chi.URLParam(r, "id")
	serverID, err := uuid.Parse(serverIDStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "Invalid server ID")
		return
	}

	creds, err := h.repo.ListForServer(r.Context(), serverID)
	if err != nil {
		WriteError(w, http.StatusInternalServerError, "Failed to list credentials")
		return
	}

	// Convert to response format (excluding sensitive data)
	type credentialResponse struct {
		ID        string `json:"id"`
		Name      string `json:"name"`
		Type      string `json:"type"`
		Username  string `json:"username,omitempty"`
		IsDefault bool   `json:"is_default"`
		CreatedAt string `json:"created_at"`
		UpdatedAt string `json:"updated_at"`
	}

	response := make([]credentialResponse, 0, len(creds))
	for _, c := range creds {
		response = append(response, credentialResponse{
			ID:        c.ID.String(),
			Name:      c.Name,
			Type:      string(c.Type),
			Username:  c.Username,
			IsDefault: c.IsDefault,
			CreatedAt: c.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
			UpdatedAt: c.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
		})
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"credentials": response,
	})
}

// Create creates a new credential for a server.
func (h *CredentialHandler) Create(w http.ResponseWriter, r *http.Request) {
	serverIDStr := chi.URLParam(r, "id")
	serverID, err := uuid.Parse(serverIDStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "Invalid server ID")
		return
	}

	var req models.CredentialCreate
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.Name == "" {
		WriteError(w, http.StatusBadRequest, "Name is required")
		return
	}
	if req.Type == "" {
		WriteError(w, http.StatusBadRequest, "Type is required")
		return
	}

	// Validate based on type
	switch req.Type {
	case models.CredTypeSSHPassword:
		if req.Username == "" || req.Password == "" {
			WriteError(w, http.StatusBadRequest, "Username and password are required for SSH password credentials")
			return
		}
	case models.CredTypeSSHKey:
		if req.Username == "" || req.PrivateKey == "" {
			WriteError(w, http.StatusBadRequest, "Username and private key are required for SSH key credentials")
			return
		}
	}

	// Create credential model (simplified - no encryption for now)
	// In production, this should encrypt the password/private_key before storing
	cred := &models.Credential{
		ID:        uuid.New(),
		ServerID:  &serverID,
		Name:      req.Name,
		Type:      req.Type,
		Username:  req.Username,
		IsDefault: req.IsDefault,
		// Note: In production, encrypt Password/PrivateKey into EncryptedData with Nonce
		EncryptedData: []byte{}, // Placeholder
		Nonce:         []byte{}, // Placeholder
	}

	if err := h.repo.Create(r.Context(), cred); err != nil {
		WriteError(w, http.StatusInternalServerError, "Failed to create credential")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]any{
		"credential": map[string]any{
			"id":         cred.ID.String(),
			"name":       cred.Name,
			"type":       string(cred.Type),
			"username":   cred.Username,
			"is_default": cred.IsDefault,
			"created_at": cred.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
			"updated_at": cred.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
		},
	})
}

// Delete removes a credential.
func (h *CredentialHandler) Delete(w http.ResponseWriter, r *http.Request) {
	credIDStr := chi.URLParam(r, "credentialId")
	credID, err := uuid.Parse(credIDStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "Invalid credential ID")
		return
	}

	if err := h.repo.Delete(r.Context(), credID); err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "Credential not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "Failed to delete credential")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// SetDefault sets a credential as the default for its server.
func (h *CredentialHandler) SetDefault(w http.ResponseWriter, r *http.Request) {
	credIDStr := chi.URLParam(r, "credentialId")
	credID, err := uuid.Parse(credIDStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "Invalid credential ID")
		return
	}

	if err := h.repo.SetDefault(r.Context(), credID); err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "Credential not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "Failed to set default credential")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"message": "Credential set as default",
	})
}
