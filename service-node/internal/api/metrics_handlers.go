package api

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/pulse-server/service-node/internal/repository"
)

// MetricsHandler handles metrics-related endpoints.
type MetricsHandler struct {
	serverRepo *repository.ServerRepository
}

// NewMetricsHandler creates a new MetricsHandler.
func NewMetricsHandler(serverRepo *repository.ServerRepository) *MetricsHandler {
	return &MetricsHandler{serverRepo: serverRepo}
}

// GetCurrentMetrics handles GET /servers/{id}/metrics
func (h *MetricsHandler) GetCurrentMetrics(w http.ResponseWriter, r *http.Request) {
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

	// TODO: Fetch actual metrics from the server via SSH/agent
	// For now, return placeholder metrics in the format expected by the frontend
	metrics := map[string]interface{}{
		"cpu_percent":        0.0,
		"memory_percent":     0.0,
		"memory_used_bytes":  0,
		"memory_total_bytes": 0,
		"disk_percent":       0.0,
		"disk_used_bytes":    0,
		"disk_total_bytes":   0,
		"load_avg_1":         0.0,
		"load_avg_5":         0.0,
		"load_avg_15":        0.0,
		"uptime":             0,
		"timestamp":          time.Now().UTC().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"metrics": metrics,
	})
}

// GetMetricsHistory handles GET /servers/{id}/metrics/history
func (h *MetricsHandler) GetMetricsHistory(w http.ResponseWriter, r *http.Request) {
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

	// TODO: Fetch metrics history from TimescaleDB
	// For now, return empty series
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"series": []interface{}{},
	})
}
