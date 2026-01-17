-- 003_metrics.down.sql
-- Rollback metrics schema

DROP TRIGGER IF EXISTS update_notification_channels_updated_at ON notification_channels;
DROP TRIGGER IF EXISTS update_alert_rules_updated_at ON alert_rules;

DROP TABLE IF EXISTS notification_channels;
DROP TABLE IF EXISTS alert_events;
DROP TABLE IF EXISTS alert_rules;

-- Drop continuous aggregate and policies
DROP MATERIALIZED VIEW IF EXISTS metrics_hourly CASCADE;

-- Drop metrics table (hypertable)
DROP TABLE IF EXISTS metrics;

-- Note: TimescaleDB extension is not dropped as other tables might use it
