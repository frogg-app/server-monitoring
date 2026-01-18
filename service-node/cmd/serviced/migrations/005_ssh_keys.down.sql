-- 005_ssh_keys.down.sql
-- Rollback SSH key pair storage

DROP TRIGGER IF EXISTS update_server_key_deployments_updated_at ON server_key_deployments;
DROP TRIGGER IF EXISTS update_ssh_key_pairs_updated_at ON ssh_key_pairs;

DROP TABLE IF EXISTS server_key_deployments;
DROP TABLE IF EXISTS ssh_key_pairs;
