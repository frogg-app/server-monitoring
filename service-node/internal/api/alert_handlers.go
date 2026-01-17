package api

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/pulse-server/service-node/internal/middleware"
	"github.com/pulse-server/service-node/internal/models"
	"github.com/pulse-server/service-node/internal/repository"
)

// AlertHandler handles alert-related endpoints
type AlertHandler struct {
	alertRepo *repository.AlertRepository
}

// NewAlertHandler creates a new AlertHandler
func NewAlertHandler(alertRepo *repository.AlertRepository) *AlertHandler {
	return &AlertHandler{alertRepo: alertRepo}
}

// ===================== Notification Channels =====================

// ListNotificationChannels handles GET /settings/notifications
func (h *AlertHandler) ListNotificationChannels(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	channels, err := h.alertRepo.ListNotificationChannels(ctx)
	if err != nil {
		WriteError(w, http.StatusInternalServerError, "failed to list notification channels")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"channels": channels,
		"total":    len(channels),
	})
}

// CreateNotificationChannel handles POST /settings/notifications
func (h *AlertHandler) CreateNotificationChannel(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req models.CreateNotificationChannelRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Name == "" {
		WriteError(w, http.StatusBadRequest, "name is required")
		return
	}
	if req.Type == "" {
		WriteError(w, http.StatusBadRequest, "type is required")
		return
	}

	channel := &models.NotificationChannel{
		Name:    req.Name,
		Type:    req.Type,
		Config:  req.Config,
		Enabled: true,
	}

	if err := h.alertRepo.CreateNotificationChannel(ctx, channel); err != nil {
		WriteError(w, http.StatusInternalServerError, "failed to create notification channel")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]any{
		"channel": channel,
	})
}

// DeleteNotificationChannel handles DELETE /settings/notifications/{id}
func (h *AlertHandler) DeleteNotificationChannel(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid channel ID")
		return
	}

	if err := h.alertRepo.DeleteNotificationChannel(ctx, id); err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "notification channel not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to delete notification channel")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// TestNotificationChannel handles POST /settings/notifications/{id}/test
func (h *AlertHandler) TestNotificationChannel(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid channel ID")
		return
	}

	_, err = h.alertRepo.GetNotificationChannel(ctx, id)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "notification channel not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to get notification channel")
		return
	}

	// TODO: Actually send a test notification
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"success": true,
		"message": "Test notification sent (placeholder)",
	})
}

// ===================== Alert Rules =====================

// ListAlertRules handles GET /alerts/rules
func (h *AlertHandler) ListAlertRules(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var serverID *uuid.UUID
	if sid := r.URL.Query().Get("server_id"); sid != "" {
		id, err := uuid.Parse(sid)
		if err == nil {
			serverID = &id
		}
	}

	rules, err := h.alertRepo.ListAlertRules(ctx, serverID)
	if err != nil {
		WriteError(w, http.StatusInternalServerError, "failed to list alert rules")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"rules": rules,
		"total": len(rules),
	})
}

// GetAlertRule handles GET /alerts/rules/{id}
func (h *AlertHandler) GetAlertRule(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid rule ID")
		return
	}

	rule, err := h.alertRepo.GetAlertRule(ctx, id)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "alert rule not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to get alert rule")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"rule": rule,
	})
}

// CreateAlertRule handles POST /alerts/rules
func (h *AlertHandler) CreateAlertRule(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req models.CreateAlertRuleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Name == "" {
		WriteError(w, http.StatusBadRequest, "name is required")
		return
	}
	if req.MetricType == "" {
		WriteError(w, http.StatusBadRequest, "metric_type is required")
		return
	}
	if req.DurationSeconds <= 0 {
		req.DurationSeconds = 60
	}
	if req.Severity == "" {
		req.Severity = models.AlertSeverityWarning
	}

	rule := &models.AlertRule{
		Name:                   req.Name,
		Description:            req.Description,
		MetricType:             req.MetricType,
		Operator:               req.Operator,
		Threshold:              req.Threshold,
		DurationSeconds:        req.DurationSeconds,
		Severity:               req.Severity,
		Enabled:                true,
		ServerID:               req.ServerID,
		NotificationChannelIDs: req.NotificationChannelIDs,
	}

	if err := h.alertRepo.CreateAlertRule(ctx, rule); err != nil {
		WriteError(w, http.StatusInternalServerError, "failed to create alert rule")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]any{
		"rule": rule,
	})
}

// UpdateAlertRule handles PATCH /alerts/rules/{id}
func (h *AlertHandler) UpdateAlertRule(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid rule ID")
		return
	}

	var req models.UpdateAlertRuleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	rule, err := h.alertRepo.UpdateAlertRule(ctx, id, &req)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "alert rule not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to update alert rule")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"rule": rule,
	})
}

// DeleteAlertRule handles DELETE /alerts/rules/{id}
func (h *AlertHandler) DeleteAlertRule(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid rule ID")
		return
	}

	if err := h.alertRepo.DeleteAlertRule(ctx, id); err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "alert rule not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to delete alert rule")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ===================== Alert Events =====================

// ListAlertEvents handles GET /alerts/events
func (h *AlertHandler) ListAlertEvents(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var serverID *uuid.UUID
	if sid := r.URL.Query().Get("server_id"); sid != "" {
		id, err := uuid.Parse(sid)
		if err == nil {
			serverID = &id
		}
	}

	var state *models.AlertEventState
	if s := r.URL.Query().Get("state"); s != "" {
		st := models.AlertEventState(s)
		state = &st
	}

	limit := 100
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	events, err := h.alertRepo.ListAlertEvents(ctx, serverID, state, limit)
	if err != nil {
		WriteError(w, http.StatusInternalServerError, "failed to list alert events")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"events": events,
		"total":  len(events),
	})
}

// GetAlertEvent handles GET /alerts/events/{id}
func (h *AlertHandler) GetAlertEvent(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid event ID")
		return
	}

	event, err := h.alertRepo.GetAlertEvent(ctx, id)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "alert event not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to get alert event")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"event": event,
	})
}

// AcknowledgeAlertEvent handles POST /alerts/events/{id}/acknowledge
func (h *AlertHandler) AcknowledgeAlertEvent(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	idStr := chi.URLParam(r, "id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid event ID")
		return
	}

	claims, ok := middleware.GetUserClaims(ctx)
	if !ok {
		WriteError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	event, err := h.alertRepo.AcknowledgeAlertEvent(ctx, id, claims.UserID)
	if err != nil {
		if err == repository.ErrNotFound {
			WriteError(w, http.StatusNotFound, "alert event not found")
			return
		}
		WriteError(w, http.StatusInternalServerError, "failed to acknowledge alert event")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{
		"event": event,
	})
}
