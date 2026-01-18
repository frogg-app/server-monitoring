-- 004_server_auth.up.sql
-- Add explicit auth method configuration to servers

-- Add auth method column to servers
ALTER TABLE servers ADD COLUMN IF NOT EXISTS auth_method VARCHAR(32) DEFAULT 'password';
-- Valid values: 'password', 'ssh_key', 'none'

-- Add default credential reference (for quick access)
ALTER TABLE servers ADD COLUMN IF NOT EXISTS default_credential_id UUID REFERENCES credentials(id) ON DELETE SET NULL;

-- Add index for auth method filtering
CREATE INDEX IF NOT EXISTS idx_servers_auth_method ON servers(auth_method);
