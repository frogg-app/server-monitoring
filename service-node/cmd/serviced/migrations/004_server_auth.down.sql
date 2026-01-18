-- 004_server_auth.down.sql
-- Revert auth method configuration from servers

DROP INDEX IF EXISTS idx_servers_auth_method;
ALTER TABLE servers DROP COLUMN IF EXISTS default_credential_id;
ALTER TABLE servers DROP COLUMN IF EXISTS auth_method;
