-- 005_ssh_keys.up.sql
-- SSH key pair storage for key management feature

-- SSH key pairs table (for generated keys)
CREATE TABLE IF NOT EXISTS ssh_key_pairs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(128) NOT NULL,
    key_type VARCHAR(32) NOT NULL DEFAULT 'ed25519', -- 'ed25519' or 'rsa'
    public_key TEXT NOT NULL,
    encrypted_private_key BYTEA, -- AES-256-GCM encrypted, NULL if downloaded once
    nonce BYTEA, -- GCM nonce for encryption
    fingerprint VARCHAR(128) NOT NULL,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ssh_key_pairs_created_by ON ssh_key_pairs(created_by);
CREATE INDEX IF NOT EXISTS idx_ssh_key_pairs_fingerprint ON ssh_key_pairs(fingerprint);

-- Key-server association for tracking which keys are deployed to which servers
CREATE TABLE IF NOT EXISTS server_key_deployments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    server_id UUID NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    key_id UUID NOT NULL REFERENCES ssh_key_pairs(id) ON DELETE CASCADE,
    deployed_at TIMESTAMPTZ,
    deploy_status VARCHAR(32) NOT NULL DEFAULT 'pending', -- 'pending', 'deployed', 'failed'
    deploy_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(server_id, key_id)
);

CREATE INDEX IF NOT EXISTS idx_server_key_deployments_server_id ON server_key_deployments(server_id);
CREATE INDEX IF NOT EXISTS idx_server_key_deployments_key_id ON server_key_deployments(key_id);

-- Trigger to update updated_at on ssh_key_pairs table
CREATE TRIGGER update_ssh_key_pairs_updated_at
    BEFORE UPDATE ON ssh_key_pairs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update updated_at on server_key_deployments table
CREATE TRIGGER update_server_key_deployments_updated_at
    BEFORE UPDATE ON server_key_deployments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
