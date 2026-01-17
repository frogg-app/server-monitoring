package repository

import (
	"context"
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/pulse-server/service-node/internal/models"
)

// AlertRepository handles database operations for alerts
type AlertRepository struct {
	pool *pgxpool.Pool
}

// NewAlertRepository creates a new AlertRepository
func NewAlertRepository(pool *pgxpool.Pool) *AlertRepository {
	return &AlertRepository{pool: pool}
}

// ===================== Notification Channels =====================

// ListNotificationChannels returns all notification channels
func (r *AlertRepository) ListNotificationChannels(ctx context.Context) ([]*models.NotificationChannel, error) {
	query := `
		SELECT id, name, type, config, is_enabled, created_at, updated_at
		FROM notification_channels
		ORDER BY created_at DESC
	`
	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var channels []*models.NotificationChannel
	for rows.Next() {
		c := &models.NotificationChannel{}
		var configBytes []byte
		if err := rows.Scan(&c.ID, &c.Name, &c.Type, &configBytes, &c.Enabled, &c.CreatedAt, &c.UpdatedAt); err != nil {
			return nil, err
		}
		if err := json.Unmarshal(configBytes, &c.Config); err != nil {
			c.Config = map[string]interface{}{}
		}
		channels = append(channels, c)
	}
	if channels == nil {
		channels = []*models.NotificationChannel{}
	}
	return channels, rows.Err()
}

// GetNotificationChannel returns a notification channel by ID
func (r *AlertRepository) GetNotificationChannel(ctx context.Context, id uuid.UUID) (*models.NotificationChannel, error) {
	query := `
		SELECT id, name, type, config, is_enabled, created_at, updated_at
		FROM notification_channels
		WHERE id = $1
	`
	c := &models.NotificationChannel{}
	var configBytes []byte
	err := r.pool.QueryRow(ctx, query, id).Scan(&c.ID, &c.Name, &c.Type, &configBytes, &c.Enabled, &c.CreatedAt, &c.UpdatedAt)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, err
	}
	if err := json.Unmarshal(configBytes, &c.Config); err != nil {
		c.Config = map[string]interface{}{}
	}
	return c, nil
}

// CreateNotificationChannel creates a new notification channel
func (r *AlertRepository) CreateNotificationChannel(ctx context.Context, channel *models.NotificationChannel) error {
	channel.ID = uuid.New()
	channel.CreatedAt = time.Now()
	channel.UpdatedAt = time.Now()
	if channel.Config == nil {
		channel.Config = map[string]interface{}{}
	}

	configBytes, err := json.Marshal(channel.Config)
	if err != nil {
		return err
	}

	query := `
		INSERT INTO notification_channels (id, name, type, config, is_enabled, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err = r.pool.Exec(ctx, query,
		channel.ID, channel.Name, channel.Type, configBytes, channel.Enabled, channel.CreatedAt, channel.UpdatedAt,
	)
	return err
}

// DeleteNotificationChannel deletes a notification channel
func (r *AlertRepository) DeleteNotificationChannel(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM notification_channels WHERE id = $1`
	result, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// ===================== Alert Rules =====================

// ListAlertRules returns all alert rules
func (r *AlertRepository) ListAlertRules(ctx context.Context, serverID *uuid.UUID) ([]*models.AlertRule, error) {
	query := `
		SELECT id, name, description, metric_type, condition, threshold, duration_seconds,
		       severity, is_enabled, server_id, notify_channels, created_at, updated_at
		FROM alert_rules
		WHERE ($1::uuid IS NULL OR server_id = $1)
		ORDER BY created_at DESC
	`
	rows, err := r.pool.Query(ctx, query, serverID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var rules []*models.AlertRule
	for rows.Next() {
		rule := &models.AlertRule{}
		var notifyChannels []byte
		if err := rows.Scan(
			&rule.ID, &rule.Name, &rule.Description, &rule.MetricType, &rule.Operator,
			&rule.Threshold, &rule.DurationSeconds, &rule.Severity, &rule.Enabled,
			&rule.ServerID, &notifyChannels, &rule.CreatedAt, &rule.UpdatedAt,
		); err != nil {
			return nil, err
		}
		// Parse notify_channels JSONB to UUID array
		if err := json.Unmarshal(notifyChannels, &rule.NotificationChannelIDs); err != nil {
			rule.NotificationChannelIDs = []uuid.UUID{}
		}
		rules = append(rules, rule)
	}
	if rules == nil {
		rules = []*models.AlertRule{}
	}
	return rules, rows.Err()
}

// GetAlertRule returns an alert rule by ID
func (r *AlertRepository) GetAlertRule(ctx context.Context, id uuid.UUID) (*models.AlertRule, error) {
	query := `
		SELECT id, name, description, metric_type, condition, threshold, duration_seconds,
		       severity, is_enabled, server_id, notify_channels, created_at, updated_at
		FROM alert_rules
		WHERE id = $1
	`
	rule := &models.AlertRule{}
	var notifyChannels []byte
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&rule.ID, &rule.Name, &rule.Description, &rule.MetricType, &rule.Operator,
		&rule.Threshold, &rule.DurationSeconds, &rule.Severity, &rule.Enabled,
		&rule.ServerID, &notifyChannels, &rule.CreatedAt, &rule.UpdatedAt,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, err
	}
	// Parse notify_channels JSONB to UUID array
	if err := json.Unmarshal(notifyChannels, &rule.NotificationChannelIDs); err != nil {
		rule.NotificationChannelIDs = []uuid.UUID{}
	}
	return rule, nil
}

// CreateAlertRule creates a new alert rule
func (r *AlertRepository) CreateAlertRule(ctx context.Context, rule *models.AlertRule) error {
	rule.ID = uuid.New()
	rule.CreatedAt = time.Now()
	rule.UpdatedAt = time.Now()
	if rule.NotificationChannelIDs == nil {
		rule.NotificationChannelIDs = []uuid.UUID{}
	}

	notifyChannels, err := json.Marshal(rule.NotificationChannelIDs)
	if err != nil {
		return err
	}

	query := `
		INSERT INTO alert_rules (id, name, description, metric_type, metric_name, condition, threshold, duration_seconds,
		                         severity, is_enabled, server_id, notify_channels, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
	`
	_, err = r.pool.Exec(ctx, query,
		rule.ID, rule.Name, rule.Description, rule.MetricType, rule.MetricType, rule.Operator,
		rule.Threshold, rule.DurationSeconds, rule.Severity, rule.Enabled,
		rule.ServerID, notifyChannels, rule.CreatedAt, rule.UpdatedAt,
	)
	return err
}

// UpdateAlertRule updates an alert rule
func (r *AlertRepository) UpdateAlertRule(ctx context.Context, id uuid.UUID, req *models.UpdateAlertRuleRequest) (*models.AlertRule, error) {
	rule, err := r.GetAlertRule(ctx, id)
	if err != nil {
		return nil, err
	}

	if req.Name != nil {
		rule.Name = *req.Name
	}
	if req.Description != nil {
		rule.Description = req.Description
	}
	if req.MetricType != nil {
		rule.MetricType = *req.MetricType
	}
	if req.Operator != nil {
		rule.Operator = *req.Operator
	}
	if req.Threshold != nil {
		rule.Threshold = *req.Threshold
	}
	if req.DurationSeconds != nil {
		rule.DurationSeconds = *req.DurationSeconds
	}
	if req.Severity != nil {
		rule.Severity = *req.Severity
	}
	if req.Enabled != nil {
		rule.Enabled = *req.Enabled
	}
	if req.ServerID != nil {
		rule.ServerID = req.ServerID
	}
	if req.NotificationChannelIDs != nil {
		rule.NotificationChannelIDs = req.NotificationChannelIDs
	}
	rule.UpdatedAt = time.Now()

	notifyChannels, err := json.Marshal(rule.NotificationChannelIDs)
	if err != nil {
		return nil, err
	}

	query := `
		UPDATE alert_rules
		SET name = $2, description = $3, metric_type = $4, condition = $5, threshold = $6,
		    duration_seconds = $7, severity = $8, is_enabled = $9, server_id = $10,
		    notify_channels = $11, updated_at = $12
		WHERE id = $1
	`
	_, err = r.pool.Exec(ctx, query,
		rule.ID, rule.Name, rule.Description, rule.MetricType, rule.Operator,
		rule.Threshold, rule.DurationSeconds, rule.Severity, rule.Enabled,
		rule.ServerID, notifyChannels, rule.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return rule, nil
}

// DeleteAlertRule deletes an alert rule
func (r *AlertRepository) DeleteAlertRule(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM alert_rules WHERE id = $1`
	result, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// ===================== Alert Events =====================

// ListAlertEvents returns alert events
func (r *AlertRepository) ListAlertEvents(ctx context.Context, serverID *uuid.UUID, state *models.AlertEventState, limit int) ([]*models.AlertEvent, error) {
	if limit <= 0 {
		limit = 100
	}

	query := `
		SELECT e.id, e.rule_id, r.name as rule_name, e.server_id, s.name as server_name,
		       e.severity, CASE WHEN e.resolved_at IS NULL THEN 'firing' ELSE 'resolved' END as state,
		       e.value, e.message, e.triggered_at, e.resolved_at,
		       CASE WHEN e.acknowledged_at IS NOT NULL THEN true ELSE false END as acknowledged,
		       e.acknowledged_by, e.acknowledged_at
		FROM alert_events e
		JOIN alert_rules r ON e.rule_id = r.id
		LEFT JOIN servers s ON e.server_id = s.id
		WHERE ($1::uuid IS NULL OR e.server_id = $1)
		  AND ($2::text IS NULL OR 
		       ($2 = 'firing' AND e.resolved_at IS NULL) OR
		       ($2 = 'resolved' AND e.resolved_at IS NOT NULL))
		ORDER BY e.triggered_at DESC
		LIMIT $3
	`
	var stateStr *string
	if state != nil {
		s := string(*state)
		stateStr = &s
	}

	rows, err := r.pool.Query(ctx, query, serverID, stateStr, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []*models.AlertEvent
	for rows.Next() {
		e := &models.AlertEvent{}
		if err := rows.Scan(
			&e.ID, &e.RuleID, &e.RuleName, &e.ServerID, &e.ServerName,
			&e.Severity, &e.State, &e.Value, &e.Message, &e.FiredAt, &e.ResolvedAt,
			&e.Acknowledged, &e.AcknowledgedBy, &e.AcknowledgedAt,
		); err != nil {
			return nil, err
		}
		events = append(events, e)
	}
	if events == nil {
		events = []*models.AlertEvent{}
	}
	return events, rows.Err()
}

// GetAlertEvent returns an alert event by ID
func (r *AlertRepository) GetAlertEvent(ctx context.Context, id uuid.UUID) (*models.AlertEvent, error) {
	query := `
		SELECT e.id, e.rule_id, r.name as rule_name, e.server_id, s.name as server_name,
		       e.severity, CASE WHEN e.resolved_at IS NULL THEN 'firing' ELSE 'resolved' END as state,
		       e.value, e.message, e.triggered_at, e.resolved_at,
		       CASE WHEN e.acknowledged_at IS NOT NULL THEN true ELSE false END as acknowledged,
		       e.acknowledged_by, e.acknowledged_at
		FROM alert_events e
		JOIN alert_rules r ON e.rule_id = r.id
		LEFT JOIN servers s ON e.server_id = s.id
		WHERE e.id = $1
	`
	e := &models.AlertEvent{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&e.ID, &e.RuleID, &e.RuleName, &e.ServerID, &e.ServerName,
		&e.Severity, &e.State, &e.Value, &e.Message, &e.FiredAt, &e.ResolvedAt,
		&e.Acknowledged, &e.AcknowledgedBy, &e.AcknowledgedAt,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return e, nil
}

// AcknowledgeAlertEvent acknowledges an alert event
func (r *AlertRepository) AcknowledgeAlertEvent(ctx context.Context, id uuid.UUID, userID uuid.UUID) (*models.AlertEvent, error) {
	now := time.Now()
	query := `
		UPDATE alert_events
		SET acknowledged = true, acknowledged_by = $2, acknowledged_at = $3
		WHERE id = $1
	`
	result, err := r.pool.Exec(ctx, query, id, userID, now)
	if err != nil {
		return nil, err
	}
	if result.RowsAffected() == 0 {
		return nil, ErrNotFound
	}
	return r.GetAlertEvent(ctx, id)
}
