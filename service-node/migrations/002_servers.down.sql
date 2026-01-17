-- 002_servers.down.sql
-- Rollback servers and credentials schema

DROP TRIGGER IF EXISTS update_credentials_updated_at ON credentials;
DROP TRIGGER IF EXISTS update_servers_updated_at ON servers;

DROP TABLE IF EXISTS ssh_host_keys;
DROP TABLE IF EXISTS credentials;
DROP TABLE IF EXISTS servers;
