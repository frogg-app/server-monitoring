package repository

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/pulse-server/service-node/internal/models"
)

// CredentialRepository handles credential data operations.
type CredentialRepository struct {
	pool *pgxpool.Pool
}

// NewCredentialRepository creates a new CredentialRepository.
func NewCredentialRepository(pool *pgxpool.Pool) *CredentialRepository {
	return &CredentialRepository{pool: pool}
}

// Create inserts a new credential into the database.
func (r *CredentialRepository) Create(ctx context.Context, cred *models.Credential) error {
	query := `
		INSERT INTO credentials (id, server_id, name, type, username, encrypted_data, nonce, is_default)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING created_at, updated_at
	`

	if cred.ID == uuid.Nil {
		cred.ID = uuid.New()
	}

	// If this credential is default, unset other defaults for this server
	if cred.IsDefault && cred.ServerID != nil {
		if err := r.unsetDefaultsForServer(ctx, *cred.ServerID, cred.Type); err != nil {
			return err
		}
	}

	err := r.pool.QueryRow(ctx, query,
		cred.ID,
		cred.ServerID,
		cred.Name,
		cred.Type,
		cred.Username,
		cred.EncryptedData,
		cred.Nonce,
		cred.IsDefault,
	).Scan(&cred.CreatedAt, &cred.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to create credential: %w", err)
	}

	return nil
}

// GetByID retrieves a credential by its ID.
func (r *CredentialRepository) GetByID(ctx context.Context, id uuid.UUID) (*models.Credential, error) {
	query := `
		SELECT id, server_id, name, type, username, encrypted_data, nonce, is_default, created_at, updated_at
		FROM credentials
		WHERE id = $1
	`

	cred := &models.Credential{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&cred.ID,
		&cred.ServerID,
		&cred.Name,
		&cred.Type,
		&cred.Username,
		&cred.EncryptedData,
		&cred.Nonce,
		&cred.IsDefault,
		&cred.CreatedAt,
		&cred.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("failed to get credential: %w", err)
	}

	return cred, nil
}

// GetDefaultForServer retrieves the default credential for a server and type.
func (r *CredentialRepository) GetDefaultForServer(ctx context.Context, serverID uuid.UUID, credType models.CredentialType) (*models.Credential, error) {
	query := `
		SELECT id, server_id, name, type, username, encrypted_data, nonce, is_default, created_at, updated_at
		FROM credentials
		WHERE server_id = $1 AND type = $2 AND is_default = true
		LIMIT 1
	`

	cred := &models.Credential{}
	err := r.pool.QueryRow(ctx, query, serverID, credType).Scan(
		&cred.ID,
		&cred.ServerID,
		&cred.Name,
		&cred.Type,
		&cred.Username,
		&cred.EncryptedData,
		&cred.Nonce,
		&cred.IsDefault,
		&cred.CreatedAt,
		&cred.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("failed to get default credential: %w", err)
	}

	return cred, nil
}

// ListForServer retrieves all credentials for a server.
func (r *CredentialRepository) ListForServer(ctx context.Context, serverID uuid.UUID) ([]*models.Credential, error) {
	query := `
		SELECT id, server_id, name, type, username, encrypted_data, nonce, is_default, created_at, updated_at
		FROM credentials
		WHERE server_id = $1
		ORDER BY is_default DESC, name ASC
	`

	rows, err := r.pool.Query(ctx, query, serverID)
	if err != nil {
		return nil, fmt.Errorf("failed to list credentials: %w", err)
	}
	defer rows.Close()

	creds := make([]*models.Credential, 0)
	for rows.Next() {
		cred := &models.Credential{}
		err := rows.Scan(
			&cred.ID,
			&cred.ServerID,
			&cred.Name,
			&cred.Type,
			&cred.Username,
			&cred.EncryptedData,
			&cred.Nonce,
			&cred.IsDefault,
			&cred.CreatedAt,
			&cred.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan credential: %w", err)
		}
		creds = append(creds, cred)
	}

	return creds, nil
}

// Delete removes a credential from the database.
func (r *CredentialRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := "DELETE FROM credentials WHERE id = $1"
	result, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete credential: %w", err)
	}
	if result.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// SetDefault makes a credential the default for its server and type.
func (r *CredentialRepository) SetDefault(ctx context.Context, id uuid.UUID) error {
	// First get the credential to know server_id and type
	cred, err := r.GetByID(ctx, id)
	if err != nil {
		return err
	}

	if cred.ServerID == nil {
		return ErrInvalidInput
	}

	// Unset other defaults
	if err := r.unsetDefaultsForServer(ctx, *cred.ServerID, cred.Type); err != nil {
		return err
	}

	// Set this one as default
	query := "UPDATE credentials SET is_default = true, updated_at = NOW() WHERE id = $1"
	_, err = r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to set default credential: %w", err)
	}

	return nil
}

// unsetDefaultsForServer removes the default flag from all credentials for a server and type.
func (r *CredentialRepository) unsetDefaultsForServer(ctx context.Context, serverID uuid.UUID, credType models.CredentialType) error {
	query := "UPDATE credentials SET is_default = false, updated_at = NOW() WHERE server_id = $1 AND type = $2 AND is_default = true"
	_, err := r.pool.Exec(ctx, query, serverID, credType)
	if err != nil {
		return fmt.Errorf("failed to unset default credentials: %w", err)
	}
	return nil
}

// SSHHostKeyRepository handles SSH host key operations.
type SSHHostKeyRepository struct {
	pool *pgxpool.Pool
}

// NewSSHHostKeyRepository creates a new SSHHostKeyRepository.
func NewSSHHostKeyRepository(pool *pgxpool.Pool) *SSHHostKeyRepository {
	return &SSHHostKeyRepository{pool: pool}
}

// Upsert creates or updates an SSH host key.
func (r *SSHHostKeyRepository) Upsert(ctx context.Context, key *models.SSHHostKey) error {
	query := `
		INSERT INTO ssh_host_keys (id, server_id, key_type, public_key, fingerprint, verified_at)
		VALUES ($1, $2, $3, $4, $5, NOW())
		ON CONFLICT (server_id, key_type)
		DO UPDATE SET public_key = $4, fingerprint = $5, verified_at = NOW()
		RETURNING id, created_at
	`

	if key.ID == uuid.Nil {
		key.ID = uuid.New()
	}

	err := r.pool.QueryRow(ctx, query,
		key.ID,
		key.ServerID,
		key.KeyType,
		key.PublicKey,
		key.Fingerprint,
	).Scan(&key.ID, &key.CreatedAt)

	if err != nil {
		return fmt.Errorf("failed to upsert SSH host key: %w", err)
	}

	return nil
}

// GetForServer retrieves all SSH host keys for a server.
func (r *SSHHostKeyRepository) GetForServer(ctx context.Context, serverID uuid.UUID) ([]*models.SSHHostKey, error) {
	query := `
		SELECT id, server_id, key_type, public_key, fingerprint, verified_at, created_at
		FROM ssh_host_keys
		WHERE server_id = $1
		ORDER BY key_type
	`

	rows, err := r.pool.Query(ctx, query, serverID)
	if err != nil {
		return nil, fmt.Errorf("failed to get SSH host keys: %w", err)
	}
	defer rows.Close()

	keys := make([]*models.SSHHostKey, 0)
	for rows.Next() {
		key := &models.SSHHostKey{}
		err := rows.Scan(
			&key.ID,
			&key.ServerID,
			&key.KeyType,
			&key.PublicKey,
			&key.Fingerprint,
			&key.VerifiedAt,
			&key.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan SSH host key: %w", err)
		}
		keys = append(keys, key)
	}

	return keys, nil
}

// GetByFingerprint retrieves an SSH host key by fingerprint.
func (r *SSHHostKeyRepository) GetByFingerprint(ctx context.Context, serverID uuid.UUID, fingerprint string) (*models.SSHHostKey, error) {
	query := `
		SELECT id, server_id, key_type, public_key, fingerprint, verified_at, created_at
		FROM ssh_host_keys
		WHERE server_id = $1 AND fingerprint = $2
	`

	key := &models.SSHHostKey{}
	err := r.pool.QueryRow(ctx, query, serverID, fingerprint).Scan(
		&key.ID,
		&key.ServerID,
		&key.KeyType,
		&key.PublicKey,
		&key.Fingerprint,
		&key.VerifiedAt,
		&key.CreatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("failed to get SSH host key: %w", err)
	}

	return key, nil
}

// Delete removes an SSH host key.
func (r *SSHHostKeyRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := "DELETE FROM ssh_host_keys WHERE id = $1"
	result, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete SSH host key: %w", err)
	}
	if result.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}
