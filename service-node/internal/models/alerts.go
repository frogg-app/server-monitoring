package models

import (
	"time"

	"github.com/google/uuid"
)

// NotificationChannelType represents the type of notification channel
type NotificationChannelType string

const (
	NotificationChannelEmail    NotificationChannelType = "email"
	NotificationChannelWebhook  NotificationChannelType = "webhook"
	NotificationChannelSlack    NotificationChannelType = "slack"
	NotificationChannelDiscord  NotificationChannelType = "discord"
	NotificationChannelTelegram NotificationChannelType = "telegram"
	NotificationChannelPushover NotificationChannelType = "pushover"
)

// NotificationChannel represents a notification channel configuration
type NotificationChannel struct {
	ID        uuid.UUID               `json:"id"`
	Name      string                  `json:"name"`
	Type      NotificationChannelType `json:"type"`
	Config    map[string]interface{}  `json:"config"`
	Enabled   bool                    `json:"enabled"`
	CreatedAt time.Time               `json:"created_at"`
	UpdatedAt time.Time               `json:"updated_at"`
}

// CreateNotificationChannelRequest is the request body for creating a notification channel
type CreateNotificationChannelRequest struct {
	Name   string                  `json:"name"`
	Type   NotificationChannelType `json:"type"`
	Config map[string]interface{}  `json:"config"`
}

// AlertSeverity represents the severity of an alert
type AlertSeverity string

const (
	AlertSeverityCritical AlertSeverity = "critical"
	AlertSeverityWarning  AlertSeverity = "warning"
	AlertSeverityInfo     AlertSeverity = "info"
)

// AlertOperator represents comparison operators for alert rules
type AlertOperator string

const (
	AlertOperatorGT  AlertOperator = "gt"
	AlertOperatorGTE AlertOperator = "gte"
	AlertOperatorLT  AlertOperator = "lt"
	AlertOperatorLTE AlertOperator = "lte"
	AlertOperatorEQ  AlertOperator = "eq"
	AlertOperatorNEQ AlertOperator = "neq"
)

// AlertRule represents an alerting rule
type AlertRule struct {
	ID                     uuid.UUID     `json:"id"`
	Name                   string        `json:"name"`
	Description            *string       `json:"description,omitempty"`
	MetricType             string        `json:"metric_type"`
	Operator               AlertOperator `json:"operator"`
	Threshold              float64       `json:"threshold"`
	DurationSeconds        int           `json:"duration_seconds"`
	Severity               AlertSeverity `json:"severity"`
	Enabled                bool          `json:"enabled"`
	ServerID               *uuid.UUID    `json:"server_id,omitempty"`
	NotificationChannelIDs []uuid.UUID   `json:"notification_channel_ids"`
	CreatedAt              time.Time     `json:"created_at"`
	UpdatedAt              time.Time     `json:"updated_at"`
}

// CreateAlertRuleRequest is the request body for creating an alert rule
type CreateAlertRuleRequest struct {
	Name                   string        `json:"name"`
	Description            *string       `json:"description,omitempty"`
	MetricType             string        `json:"metric_type"`
	Operator               AlertOperator `json:"operator"`
	Threshold              float64       `json:"threshold"`
	DurationSeconds        int           `json:"duration_seconds"`
	Severity               AlertSeverity `json:"severity"`
	ServerID               *uuid.UUID    `json:"server_id,omitempty"`
	NotificationChannelIDs []uuid.UUID   `json:"notification_channel_ids,omitempty"`
}

// UpdateAlertRuleRequest is the request body for updating an alert rule
type UpdateAlertRuleRequest struct {
	Name                   *string        `json:"name,omitempty"`
	Description            *string        `json:"description,omitempty"`
	MetricType             *string        `json:"metric_type,omitempty"`
	Operator               *AlertOperator `json:"operator,omitempty"`
	Threshold              *float64       `json:"threshold,omitempty"`
	DurationSeconds        *int           `json:"duration_seconds,omitempty"`
	Severity               *AlertSeverity `json:"severity,omitempty"`
	Enabled                *bool          `json:"enabled,omitempty"`
	ServerID               *uuid.UUID     `json:"server_id,omitempty"`
	NotificationChannelIDs []uuid.UUID    `json:"notification_channel_ids,omitempty"`
}

// AlertEventState represents the state of an alert event
type AlertEventState string

const (
	AlertEventStateFiring   AlertEventState = "firing"
	AlertEventStateResolved AlertEventState = "resolved"
)

// AlertEvent represents an alert event (triggered alert)
type AlertEvent struct {
	ID             uuid.UUID       `json:"id"`
	RuleID         uuid.UUID       `json:"rule_id"`
	RuleName       string          `json:"rule_name"`
	ServerID       *uuid.UUID      `json:"server_id,omitempty"`
	ServerName     *string         `json:"server_name,omitempty"`
	Severity       AlertSeverity   `json:"severity"`
	State          AlertEventState `json:"state"`
	Value          float64         `json:"value"`
	Message        string          `json:"message"`
	FiredAt        time.Time       `json:"fired_at"`
	ResolvedAt     *time.Time      `json:"resolved_at,omitempty"`
	Acknowledged   bool            `json:"acknowledged"`
	AcknowledgedBy *uuid.UUID      `json:"acknowledged_by,omitempty"`
	AcknowledgedAt *time.Time      `json:"acknowledged_at,omitempty"`
}
