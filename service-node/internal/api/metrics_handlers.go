package api

import (
	"encoding/json"
	"net/http"

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
	// For now, return placeholder metrics
	metrics := map[string]interface{}{
		"cpu": map[string]interface{}{
			"usage_percent": 0.0,
			"cores":         0,
			"model":         "Unknown",
		},
		"memory": map[string]interface{}{
			"total_bytes":     0,
			"used_bytes":      0,
			"available_bytes": 0,
			"usage_percent":   0.0,
		},
		"disk": map[string]interface{}{
			"total_bytes":   0,
			"used_bytes":    0,
			"free_bytes":    0,
			"usage_percent": 0.0,
		},
		"network": map[string]interface{}{
			"bytes_sent":     0,
			"bytes_received": 0,
		},
		"uptime_seconds": 0,
		"load_average":   []float64{0, 0, 0},
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
