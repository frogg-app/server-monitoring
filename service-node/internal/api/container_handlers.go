package api

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/pulse-server/service-node/internal/repository"
)

// ContainerHandler handles container-related endpoints.
type ContainerHandler struct {
	serverRepo *repository.ServerRepository
}

// NewContainerHandler creates a new ContainerHandler.
func NewContainerHandler(serverRepo *repository.ServerRepository) *ContainerHandler {
	return &ContainerHandler{serverRepo: serverRepo}
}

// ListContainers handles GET /servers/{id}/containers
func (h *ContainerHandler) ListContainers(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid server ID")
		return
	}

	// Verify server exists
	_, err = h.serverRepo.GetByID(ctx, id)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "server not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to get server")
		return
	}

	// TODO: Fetch actual containers from the server via SSH/Docker API
	// For now, return empty list
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"containers": []interface{}{},
		"total":      0,
	})
}

// GetContainerStats handles GET /servers/{id}/containers/{containerId}/stats
func (h *ContainerHandler) GetContainerStats(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid server ID")
		return
	}

	// Verify server exists
	_, err = h.serverRepo.GetByID(ctx, id)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "server not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to get server")
		return
	}

	containerId := chi.URLParam(r, "containerId")
	if containerId == "" {
		WriteError(w, http.StatusBadRequest, "container ID required")
		return
	}

	// TODO: Fetch actual container stats
	stats := map[string]interface{}{
		"container_id": containerId,
		"cpu_percent":  0.0,
		"memory_usage": 0,
		"memory_limit": 0,
		"network_rx":   0,
		"network_tx":   0,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"stats": stats,
	})
}

// ContainerAction handles POST /servers/{id}/containers/{containerId}/{action}
func (h *ContainerHandler) ContainerAction(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid server ID")
		return
	}

	// Verify server exists
	_, err = h.serverRepo.GetByID(ctx, id)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "server not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to get server")
		return
	}

	containerId := chi.URLParam(r, "containerId")
	action := chi.URLParam(r, "action")

	validActions := map[string]bool{
		"start":   true,
		"stop":    true,
		"restart": true,
		"pause":   true,
		"unpause": true,
	}

	if !validActions[action] {
		WriteError(w, http.StatusBadRequest, "invalid action")
		return
	}

	// TODO: Execute actual container action via SSH/Docker API
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":      true,
		"container_id": containerId,
		"action":       action,
		"message":      "Action queued (placeholder)",
	})
}

// GetContainerLogs handles GET /servers/{id}/containers/{containerId}/logs
func (h *ContainerHandler) GetContainerLogs(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid server ID")
		return
	}

	// Verify server exists
	_, err = h.serverRepo.GetByID(ctx, id)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "server not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to get server")
		return
	}

	// TODO: Fetch actual container logs
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"logs": []interface{}{},
	})
}
