package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/pulse-server/service-node/internal/models"
)

// ServerRepository handles server data operations.
type ServerRepository struct {
	pool *pgxpool.Pool
}

// NewServerRepository creates a new ServerRepository.
func NewServerRepository(pool *pgxpool.Pool) *ServerRepository {
	return &ServerRepository{pool: pool}
}

// Create inserts a new server into the database.
func (r *ServerRepository) Create(ctx context.Context, server *models.Server) error {
	query := `
		INSERT INTO servers (id, name, hostname, port, description, tags, status, auth_method, default_credential_id, created_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING created_at, updated_at
	`

	if server.ID == uuid.Nil {
		server.ID = uuid.New()
	}
	if server.Port == 0 {
		server.Port = 22
	}
	if server.Status == "" {
		server.Status = models.StatusUnknown
	}
	if server.AuthMethod == "" {
		server.AuthMethod = models.AuthMethodPassword
	}

	tagsJSON, err := json.Marshal(server.Tags)
	if err != nil {
		tagsJSON = []byte("[]")
	}

	err = r.pool.QueryRow(ctx, query,
		server.ID,
		server.Name,
		server.Hostname,
		server.Port,
		server.Description,
		tagsJSON,
		server.Status,
		server.AuthMethod,
		server.DefaultCredentialID,
		server.CreatedBy,
	).Scan(&server.CreatedAt, &server.UpdatedAt)

	if err != nil {
		if isDuplicateKeyError(err) {
			return ErrDuplicateKey
		}
		return fmt.Errorf("failed to create server: %w", err)
	}

	return nil
}

// GetByID retrieves a server by its ID.
func (r *ServerRepository) GetByID(ctx context.Context, id uuid.UUID) (*models.Server, error) {
	query := `
		SELECT id, name, hostname, port, description, tags, status, 
		       auth_method, default_credential_id,
		       last_seen_at, created_by, created_at, updated_at
		FROM servers
		WHERE id = $1
	`

	server := &models.Server{}
	var tagsJSON []byte

	err := r.pool.QueryRow(ctx, query, id).Scan(
		&server.ID,
		&server.Name,
		&server.Hostname,
		&server.Port,
		&server.Description,
		&tagsJSON,
		&server.Status,
		&server.AuthMethod,
		&server.DefaultCredentialID,
		&server.LastSeenAt,
		&server.CreatedBy,
		&server.CreatedAt,
		&server.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("failed to get server: %w", err)
	}

	if err := json.Unmarshal(tagsJSON, &server.Tags); err != nil {
		server.Tags = []string{}
	}

	return server, nil
}

// Update modifies an existing server.
func (r *ServerRepository) Update(ctx context.Context, id uuid.UUID, update *models.ServerUpdate) (*models.Server, error) {
	query := "UPDATE servers SET updated_at = NOW()"
	args := []any{}
	argCount := 0

	if update.Name != nil {
		argCount++
		query += fmt.Sprintf(", name = $%d", argCount)
		args = append(args, *update.Name)
	}
	if update.Hostname != nil {
		argCount++
		query += fmt.Sprintf(", hostname = $%d", argCount)
		args = append(args, *update.Hostname)
	}
	if update.Port != nil {
		argCount++
		query += fmt.Sprintf(", port = $%d", argCount)
		args = append(args, *update.Port)
	}
	if update.Description != nil {
		argCount++
		query += fmt.Sprintf(", description = $%d", argCount)
		args = append(args, *update.Description)
	}
	if update.Tags != nil {
		argCount++
		tagsJSON, _ := json.Marshal(*update.Tags)
		query += fmt.Sprintf(", tags = $%d", argCount)
		args = append(args, tagsJSON)
	}
	if update.AuthMethod != nil {
		argCount++
		query += fmt.Sprintf(", auth_method = $%d", argCount)
		args = append(args, *update.AuthMethod)
	}
	if update.DefaultCredentialID != nil {
		argCount++
		query += fmt.Sprintf(", default_credential_id = $%d", argCount)
		args = append(args, *update.DefaultCredentialID)
	}

	argCount++
	query += fmt.Sprintf(" WHERE id = $%d", argCount)
	args = append(args, id)

	query += ` RETURNING id, name, hostname, port, description, tags, status, 
	           auth_method, default_credential_id,
	           last_seen_at, created_by, created_at, updated_at`

	server := &models.Server{}
	var tagsJSON []byte

	err := r.pool.QueryRow(ctx, query, args...).Scan(
		&server.ID,
		&server.Name,
		&server.Hostname,
		&server.Port,
		&server.Description,
		&tagsJSON,
		&server.Status,
		&server.AuthMethod,
		&server.DefaultCredentialID,
		&server.LastSeenAt,
		&server.CreatedBy,
		&server.CreatedAt,
		&server.UpdatedAt,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("failed to update server: %w", err)
	}

	if err := json.Unmarshal(tagsJSON, &server.Tags); err != nil {
		server.Tags = []string{}
	}

	return server, nil
}

// UpdateStatus updates a server's status and last_seen_at timestamp.
func (r *ServerRepository) UpdateStatus(ctx context.Context, id uuid.UUID, status models.ServerStatus) error {
	query := "UPDATE servers SET status = $1, last_seen_at = NOW(), updated_at = NOW() WHERE id = $2"
	result, err := r.pool.Exec(ctx, query, status, id)
	if err != nil {
		return fmt.Errorf("failed to update server status: %w", err)
	}
	if result.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// Delete removes a server from the database.
func (r *ServerRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := "DELETE FROM servers WHERE id = $1"
	result, err := r.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete server: %w", err)
	}
	if result.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// List retrieves all servers with optional filtering.
func (r *ServerRepository) List(ctx context.Context, status *models.ServerStatus, limit, offset int) ([]*models.Server, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}

	query := `
		SELECT id, name, hostname, port, description, tags, status, 
		       auth_method, default_credential_id,
		       last_seen_at, created_by, created_at, updated_at
		FROM servers
		WHERE ($1::varchar IS NULL OR status = $1)
		ORDER BY name ASC
		LIMIT $2 OFFSET $3
	`

	var statusStr *string
	if status != nil {
		s := string(*status)
		statusStr = &s
	}

	rows, err := r.pool.Query(ctx, query, statusStr, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to list servers: %w", err)
	}
	defer rows.Close()

	servers := make([]*models.Server, 0)
	for rows.Next() {
		server := &models.Server{}
		var tagsJSON []byte

		err := rows.Scan(
			&server.ID,
			&server.Name,
			&server.Hostname,
			&server.Port,
			&server.Description,
			&tagsJSON,
			&server.Status,
			&server.AuthMethod,
			&server.DefaultCredentialID,
			&server.LastSeenAt,
			&server.CreatedBy,
			&server.CreatedAt,
			&server.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan server: %w", err)
		}

		if err := json.Unmarshal(tagsJSON, &server.Tags); err != nil {
			server.Tags = []string{}
		}

		servers = append(servers, server)
	}

	return servers, nil
}

// Count returns the total number of servers.
func (r *ServerRepository) Count(ctx context.Context, status *models.ServerStatus) (int, error) {
	query := "SELECT COUNT(*) FROM servers WHERE ($1::varchar IS NULL OR status = $1)"

	var statusStr *string
	if status != nil {
		s := string(*status)
		statusStr = &s
	}

	var count int
	err := r.pool.QueryRow(ctx, query, statusStr).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count servers: %w", err)
	}

	return count, nil
}
