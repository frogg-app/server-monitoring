package api

import (
	"encoding/json"
	"net/http"
	"time"
)

// HealthResponse represents the health check response
type HealthResponse struct {
	Status    string    `json:"status"`
	Version   string    `json:"version"`
	Timestamp time.Time `json:"timestamp"`
	Uptime    string    `json:"uptime"`
}

var startTime = time.Now()

// HealthHandler returns a handler for the health endpoint
func HealthHandler(version string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		resp := HealthResponse{
			Status:    "ok",
			Version:   version,
			Timestamp: time.Now().UTC(),
			Uptime:    time.Since(startTime).Round(time.Second).String(),
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(resp)
	}
}

// ErrorResponse represents an API error
type ErrorResponse struct {
	Error string `json:"error"`
}

// WriteError writes an error response
func WriteError(w http.ResponseWriter, statusCode int, message string) {
	resp := ErrorResponse{Error: message}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(resp)
}

// NotImplementedHandler returns 501 for unimplemented endpoints
func NotImplementedHandler(w http.ResponseWriter, r *http.Request) {
	WriteError(w, http.StatusNotImplemented, "This endpoint is not yet implemented")
}
