#!/bin/bash
set -e

# =============================================================================
# Pulse (Server Monitoring) Build Script (Docker Compose multi-service project)
# =============================================================================

echo "=== Building Pulse (docker-compose) ==="

# Build all services with docker compose
docker compose build --no-cache

# Tag the built images for versioning
docker tag pulse-api:latest pulse-api:${VERSION:-latest}
docker tag pulse-api:latest pulse-api:${ENVIRONMENT:-dev}
docker tag pulse-web:latest pulse-web:${VERSION:-latest}
docker tag pulse-web:latest pulse-web:${ENVIRONMENT:-dev}

echo "Build completed successfully!"
