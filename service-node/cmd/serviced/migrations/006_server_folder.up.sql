-- 006_server_folder.up.sql
-- Add folder field for server categorization

ALTER TABLE servers ADD COLUMN IF NOT EXISTS folder VARCHAR(128);

CREATE INDEX IF NOT EXISTS idx_servers_folder ON servers(folder);
