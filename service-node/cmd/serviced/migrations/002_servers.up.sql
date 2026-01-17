-- 002_servers.up.sql
-- Server and credential storage schema

-- Servers table
CREATE TABLE IF NOT EXISTS servers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(128) NOT NULL,
    hostname VARCHAR(255) NOT NULL,
    port INTEGER NOT NULL DEFAULT 22,
    description TEXT,
    tags JSONB DEFAULT '[]'::jsonb,
    status VARCHAR(32) NOT NULL DEFAULT 'unknown',
    last_seen_at TIMESTAMPTZ,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_servers_status ON servers(status);
CREATE INDEX IF NOT EXISTS idx_servers_created_by ON servers(created_by);

-- Credentials table (encrypted)
CREATE TABLE IF NOT EXISTS credentials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    server_id UUID REFERENCES servers(id) ON DELETE CASCADE,
    name VARCHAR(128) NOT NULL,
    type VARCHAR(32) NOT NULL, -- 'ssh_password', 'ssh_key', 'docker', 'kubernetes', 'proxmox'
    username VARCHAR(128),
    encrypted_data BYTEA NOT NULL, -- AES-256-GCM encrypted
    nonce BYTEA NOT NULL, -- GCM nonce
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_credentials_server_id ON credentials(server_id);
CREATE INDEX IF NOT EXISTS idx_credentials_type ON credentials(type);

-- SSH host keys (for fingerprint verification)
CREATE TABLE IF NOT EXISTS ssh_host_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    server_id UUID NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    key_type VARCHAR(32) NOT NULL, -- 'ssh-rsa', 'ssh-ed25519', etc.
    public_key TEXT NOT NULL,
    fingerprint VARCHAR(128) NOT NULL,
    verified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(server_id, key_type)
);

CREATE INDEX IF NOT EXISTS idx_ssh_host_keys_server_id ON ssh_host_keys(server_id);
CREATE INDEX IF NOT EXISTS idx_ssh_host_keys_fingerprint ON ssh_host_keys(fingerprint);

-- Trigger to update updated_at on servers table
CREATE TRIGGER update_servers_updated_at
    BEFORE UPDATE ON servers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update updated_at on credentials table
CREATE TRIGGER update_credentials_updated_at
    BEFORE UPDATE ON credentials
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
