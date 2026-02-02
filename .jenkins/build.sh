#!/bin/bash
set -e

# =============================================================================
# Pulse (Server Monitoring) Build Script (Docker Compose multi-service project)
# =============================================================================

echo "=== Building Pulse (docker-compose) ==="

# Set compose project name to avoid directory-based naming
export COMPOSE_PROJECT_NAME=pulse

# Set required environment variables for docker compose
export POSTGRES_PASSWORD=build_time_placeholder
export JWT_SECRET=build_time_jwt_secret_placeholder_32chars
export VAULT_KEY=build_time_vault_key_placeholder_32chars

# Build only the buildable services (not db which uses a pre-built image)
docker compose build api web --no-cache

# The built images will be named pulse-api and pulse-web
# Tag them for deployment
docker tag pulse-api:latest pulse-api:${VERSION:-latest}
docker tag pulse-web:latest pulse-web:${VERSION:-latest}

echo "Build completed successfully!"
