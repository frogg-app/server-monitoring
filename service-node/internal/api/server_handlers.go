package api

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/pulse-server/service-node/internal/middleware"
	"github.com/pulse-server/service-node/internal/models"
	"github.com/pulse-server/service-node/internal/repository"
)

// ServerHandler handles server-related endpoints.
type ServerHandler struct {
	serverRepo *repository.ServerRepository
}

// NewServerHandler creates a new ServerHandler.
func NewServerHandler(serverRepo *repository.ServerRepository) *ServerHandler {
	return &ServerHandler{serverRepo: serverRepo}
}

// List handles GET /servers
func (h *ServerHandler) List(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	
	// Parse query parameters
	status := r.URL.Query().Get("status")
	var statusFilter *models.ServerStatus
	if status != "" {
		s := models.ServerStatus(status)
		statusFilter = &s
	}

	servers, err := h.serverRepo.List(ctx, statusFilter, 100, 0)
	if err != nil {
		WriteError(w, http.StatusInternalServerError, "failed to list servers")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"servers": servers,
		"total":   len(servers),
	})
}

// Get handles GET /servers/{id}
func (h *ServerHandler) Get(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid server ID")
		return
	}

	server, err := h.serverRepo.GetByID(ctx, id)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "server not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to get server")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(server)
}

// Create handles POST /servers
func (h *ServerHandler) Create(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	
	var req models.ServerCreate
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Name == "" {
		WriteError(w, http.StatusBadRequest, "name is required")
		return
	}
	if req.Hostname == "" {
		WriteError(w, http.StatusBadRequest, "hostname is required")
		return
	}

	// Get current user from context
	claims, ok := middleware.GetUserClaims(ctx)
	var createdBy *uuid.UUID
	if ok {
		createdBy = &claims.UserID
	}

	server := &models.Server{
		Name:        req.Name,
		Hostname:    req.Hostname,
		Port:        req.Port,
		Description: req.Description,
		Tags:        req.Tags,
		CreatedBy:   createdBy,
	}

	if server.Port == 0 {
		server.Port = 22
	}
	if server.Tags == nil {
		server.Tags = []string{}
	}

	if err := h.serverRepo.Create(ctx, server); err != nil {
		WriteError(w, http.StatusInternalServerError, "failed to create server")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(server)
}

// Update handles PATCH /servers/{id}
func (h *ServerHandler) Update(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid server ID")
		return
	}

	var req models.ServerUpdate
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	server, err := h.serverRepo.Update(ctx, id, &req)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "server not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to update server")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(server)
}

// Delete handles DELETE /servers/{id}
func (h *ServerHandler) Delete(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid server ID")
		return
	}

	if err := h.serverRepo.Delete(ctx, id); err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "server not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to delete server")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// TestConnection handles POST /servers/{id}/test
func (h *ServerHandler) TestConnection(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	
	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid server ID")
		return
	}

	server, err := h.serverRepo.GetByID(ctx, id)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "server not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to get server")
		return
	}

	// TODO: Actually test connection via SSH
	// For now, just return success
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"success":  true,
		"message":  "Connection test placeholder",
		"server":   server.Hostname,
		"port":     server.Port,
	})
}
