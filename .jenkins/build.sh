#!/bin/bash
set -e

# =============================================================================
# Pulse (Server Monitoring) Build Script (Docker Compose multi-service project)
# =============================================================================

echo "=== Building Pulse (docker-compose) ==="

# Set compose project name to avoid directory-based naming
export COMPOSE_PROJECT_NAME=pulse

# Build all services with docker compose
docker compose build --no-cache

# The built images will be named pulse-api and pulse-web
# Tag them for deployment
docker tag pulse-api:latest pulse-api:${VERSION:-latest}
docker tag pulse-web:latest pulse-web:${VERSION:-latest}

echo "Build completed successfully!"
