package repository

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// SSHKeyPair represents a stored SSH key pair.
type SSHKeyPair struct {
	ID                  uuid.UUID  `json:"id"`
	Name                string     `json:"name"`
	KeyType             string     `json:"key_type"`
	PublicKey           string     `json:"public_key"`
	EncryptedPrivateKey []byte     `json:"-"`
	Nonce               []byte     `json:"-"`
	Fingerprint         string     `json:"fingerprint"`
	CreatedBy           *uuid.UUID `json:"created_by,omitempty"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
}

// KeyDeployment represents a key deployment to a server.
type KeyDeployment struct {
	ID            uuid.UUID  `json:"id"`
	ServerID      uuid.UUID  `json:"server_id"`
	KeyID         uuid.UUID  `json:"key_id"`
	DeployedAt    *time.Time `json:"deployed_at,omitempty"`
	DeployStatus  string     `json:"deploy_status"`
	DeployMessage string     `json:"deploy_message,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	UpdatedAt     time.Time  `json:"updated_at"`
}

// KeyRepository handles SSH key data operations.
type KeyRepository struct {
	pool *pgxpool.Pool
}

// NewKeyRepository creates a new KeyRepository.
func NewKeyRepository(pool *pgxpool.Pool) *KeyRepository {
	return &KeyRepository{pool: pool}
}

// Create inserts a new SSH key pair into the database.
func (r *KeyRepository) Create(ctx context.Context, key *SSHKeyPair) error {
	query := `
		INSERT INTO ssh_key_pairs (id, name, key_type, public_key, encrypted_private_key, nonce, fingerprint, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING created_at, updated_at
	`

	if key.ID == uuid.Nil {
		key.ID = uuid.New()
	}

	err := r.pool.QueryRow(ctx, query,
		key.ID,
		key.Name,
		key.KeyType,
		key.PublicKey,
		key.EncryptedPrivateKey,
		key.Nonce,
		key.Fingerprint,
		key.CreatedBy,
	).Scan(&key.CreatedAt, &key.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to create SSH key pair: %w", err)
	}

	return nil
}

// GetByID retrieves an SSH key pair by ID.
func (r *KeyRepository) GetByID(ctx context.Context, id uuid.UUID) (*SSHKeyPair, error) {
	query := `
		SELECT id, name, key_type, public_key, encrypted_private_key, nonce, fingerprint, created_by, created_at, updated_at
		FROM ssh_key_pairs
		WHERE id = $1
	`

	key := &SSHKeyPair{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&key.ID,
		&key.Name,
		&key.KeyType,
		&key.PublicKey,
		&key.EncryptedPrivateKey,
		&key.Nonce,
		&key.Fingerprint,
		&key.CreatedBy,
		&key.CreatedAt,
		&key.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("failed to get SSH key pair: %w", err)
	}

	return key, nil
}

// List retrieves all SSH key pairs.
func (r *KeyRepository) List(ctx context.Context) ([]*SSHKeyPair, error) {
	query := `
		SELECT id, name, key_type, public_key, fingerprint, created_by, created_at, updated_at
		FROM ssh_key_pairs
		ORDER BY created_at DESC
	`

	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to list SSH key pairs: %w", err)
	}
	defer rows.Close()

	keys := make([]*SSHKeyPair, 0)
	for rows.Next() {
		key := &SSHKeyPair{}
		if err := rows.Scan(
			&key.ID,
			&key.Name,
			&key.KeyType,
			&key.PublicKey,
			&key.Fingerprint,
			&key.CreatedBy,
			&key.CreatedAt,
			&key.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan SSH key pair: %w", err)
		}
		keys = append(keys, key)
	}

	return keys, nil
}

// Delete removes an SSH key pair by ID.
func (r *KeyRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM ssh_key_pairs WHERE id = $1`
	result, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete SSH key pair: %w", err)
	}
	if result.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// ClearPrivateKey sets the encrypted private key to NULL (after download).
func (r *KeyRepository) ClearPrivateKey(ctx context.Context, id uuid.UUID) error {
	query := `UPDATE ssh_key_pairs SET encrypted_private_key = NULL, nonce = NULL, updated_at = NOW() WHERE id = $1`
	_, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to clear private key: %w", err)
	}
	return nil
}

// CreateDeployment creates a deployment record for a key on a server.
func (r *KeyRepository) CreateDeployment(ctx context.Context, deployment *KeyDeployment) error {
	query := `
		INSERT INTO server_key_deployments (id, server_id, key_id, deploy_status, deploy_message)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (server_id, key_id) DO UPDATE SET
			deploy_status = EXCLUDED.deploy_status,
			deploy_message = EXCLUDED.deploy_message,
			updated_at = NOW()
		RETURNING created_at, updated_at
	`

	if deployment.ID == uuid.Nil {
		deployment.ID = uuid.New()
	}

	err := r.pool.QueryRow(ctx, query,
		deployment.ID,
		deployment.ServerID,
		deployment.KeyID,
		deployment.DeployStatus,
		deployment.DeployMessage,
	).Scan(&deployment.CreatedAt, &deployment.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to create deployment: %w", err)
	}

	return nil
}

// UpdateDeploymentStatus updates the status of a deployment.
func (r *KeyRepository) UpdateDeploymentStatus(ctx context.Context, serverID, keyID uuid.UUID, status, message string) error {
	var query string
	var args []interface{}
	
	if status == "deployed" {
		query = `
			UPDATE server_key_deployments 
			SET deploy_status = $1, deploy_message = $2, deployed_at = NOW(), updated_at = NOW()
			WHERE server_id = $3 AND key_id = $4
		`
		args = []interface{}{status, message, serverID, keyID}
	} else {
		query = `
			UPDATE server_key_deployments 
			SET deploy_status = $1, deploy_message = $2, updated_at = NOW()
			WHERE server_id = $3 AND key_id = $4
		`
		args = []interface{}{status, message, serverID, keyID}
	}
	
	_, err := r.pool.Exec(ctx, query, args...)
	if err != nil {
		return fmt.Errorf("failed to update deployment status: %w", err)
	}
	return nil
}

// ListDeploymentsForKey lists all deployments for a specific key.
func (r *KeyRepository) ListDeploymentsForKey(ctx context.Context, keyID uuid.UUID) ([]*KeyDeployment, error) {
	query := `
		SELECT id, server_id, key_id, deployed_at, deploy_status, deploy_message, created_at, updated_at
		FROM server_key_deployments
		WHERE key_id = $1
		ORDER BY created_at DESC
	`

	rows, err := r.pool.Query(ctx, query, keyID)
	if err != nil {
		return nil, fmt.Errorf("failed to list deployments: %w", err)
	}
	defer rows.Close()

	deployments := make([]*KeyDeployment, 0)
	for rows.Next() {
		d := &KeyDeployment{}
		if err := rows.Scan(
			&d.ID,
			&d.ServerID,
			&d.KeyID,
			&d.DeployedAt,
			&d.DeployStatus,
			&d.DeployMessage,
			&d.CreatedAt,
			&d.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan deployment: %w", err)
		}
		deployments = append(deployments, d)
	}

	return deployments, nil
}

// ListDeploymentsForServer lists all deployments for a specific server.
func (r *KeyRepository) ListDeploymentsForServer(ctx context.Context, serverID uuid.UUID) ([]*KeyDeployment, error) {
	query := `
		SELECT id, server_id, key_id, deployed_at, deploy_status, deploy_message, created_at, updated_at
		FROM server_key_deployments
		WHERE server_id = $1
		ORDER BY created_at DESC
	`

	rows, err := r.pool.Query(ctx, query, serverID)
	if err != nil {
		return nil, fmt.Errorf("failed to list deployments: %w", err)
	}
	defer rows.Close()

	deployments := make([]*KeyDeployment, 0)
	for rows.Next() {
		d := &KeyDeployment{}
		if err := rows.Scan(
			&d.ID,
			&d.ServerID,
			&d.KeyID,
			&d.DeployedAt,
			&d.DeployStatus,
			&d.DeployMessage,
			&d.CreatedAt,
			&d.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan deployment: %w", err)
		}
		deployments = append(deployments, d)
	}

	return deployments, nil
}
