-- 006_server_folder.down.sql
-- Remove folder field

DROP INDEX IF EXISTS idx_servers_folder;
ALTER TABLE servers DROP COLUMN IF EXISTS folder;
