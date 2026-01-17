-- 003_metrics.up.sql
-- Metrics storage schema using TimescaleDB hypertables

-- Enable TimescaleDB extension (must be installed on the database)
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- Metrics table for time-series data
CREATE TABLE IF NOT EXISTS metrics (
    time TIMESTAMPTZ NOT NULL,
    server_id UUID NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    metric_type VARCHAR(64) NOT NULL, -- 'cpu', 'memory', 'disk', 'network', 'process', etc.
    metric_name VARCHAR(128) NOT NULL, -- 'usage_percent', 'bytes_sent', etc.
    value DOUBLE PRECISION NOT NULL,
    tags JSONB DEFAULT '{}'::jsonb,
    PRIMARY KEY (time, server_id, metric_type, metric_name)
);

-- Convert to hypertable (TimescaleDB)
SELECT create_hypertable('metrics', 'time', if_not_exists => TRUE);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_metrics_server_id ON metrics(server_id, time DESC);
CREATE INDEX IF NOT EXISTS idx_metrics_type ON metrics(metric_type, time DESC);

-- Retention policy: keep raw metrics for 30 days
SELECT add_retention_policy('metrics', INTERVAL '30 days', if_not_exists => TRUE);

-- Continuous aggregates for hourly summaries
CREATE MATERIALIZED VIEW IF NOT EXISTS metrics_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    server_id,
    metric_type,
    metric_name,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value,
    COUNT(*) as sample_count
FROM metrics
GROUP BY bucket, server_id, metric_type, metric_name
WITH NO DATA;

-- Refresh policy for continuous aggregates
SELECT add_continuous_aggregate_policy('metrics_hourly',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour',
    if_not_exists => TRUE);

-- Alerts table for storing alert rules
CREATE TABLE IF NOT EXISTS alert_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(128) NOT NULL,
    description TEXT,
    server_id UUID REFERENCES servers(id) ON DELETE CASCADE, -- NULL means all servers
    metric_type VARCHAR(64) NOT NULL,
    metric_name VARCHAR(128) NOT NULL,
    condition VARCHAR(16) NOT NULL, -- 'gt', 'lt', 'gte', 'lte', 'eq', 'neq'
    threshold DOUBLE PRECISION NOT NULL,
    duration_seconds INTEGER NOT NULL DEFAULT 60, -- must exceed for this duration
    severity VARCHAR(16) NOT NULL DEFAULT 'warning', -- 'info', 'warning', 'critical'
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    notify_channels JSONB DEFAULT '[]'::jsonb, -- array of channel IDs
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alert_rules_server_id ON alert_rules(server_id);
CREATE INDEX IF NOT EXISTS idx_alert_rules_is_enabled ON alert_rules(is_enabled);

-- Alert events (triggered alerts)
CREATE TABLE IF NOT EXISTS alert_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES alert_rules(id) ON DELETE CASCADE,
    server_id UUID NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    severity VARCHAR(16) NOT NULL,
    message TEXT NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    threshold DOUBLE PRECISION NOT NULL,
    triggered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_alert_events_rule_id ON alert_events(rule_id);
CREATE INDEX IF NOT EXISTS idx_alert_events_server_id ON alert_events(server_id);
CREATE INDEX IF NOT EXISTS idx_alert_events_triggered_at ON alert_events(triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_alert_events_unresolved ON alert_events(triggered_at DESC) WHERE resolved_at IS NULL;

-- Notification channels
CREATE TABLE IF NOT EXISTS notification_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(128) NOT NULL,
    type VARCHAR(32) NOT NULL, -- 'email', 'smtp', 'discord', 'slack', 'webhook'
    config JSONB NOT NULL, -- encrypted or structured config
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger for updated_at on alert_rules
CREATE TRIGGER update_alert_rules_updated_at
    BEFORE UPDATE ON alert_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for updated_at on notification_channels
CREATE TRIGGER update_notification_channels_updated_at
    BEFORE UPDATE ON notification_channels
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
