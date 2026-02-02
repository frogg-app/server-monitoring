#!/bin/bash
set -e

# =============================================================================
# Pulse (Server Monitoring) Deploy Script (Docker Compose multi-service project)
# =============================================================================

echo "=== Deploying Pulse to $ENVIRONMENT ==="

if [ "$ENVIRONMENT" = "stable" ]; then
    echo ">>> Deploying to production (${DEPLOY_SERVER})"
    
    # Save images and transfer
    docker save pulse-api:latest -o /tmp/pulse-api.tar
    docker save pulse-web:latest -o /tmp/pulse-web.tar
    
    scp -o StrictHostKeyChecking=no /tmp/pulse-api.tar /tmp/pulse-web.tar frogg@${DEPLOY_SERVER}:/tmp/
    
    # Load images on remote server and deploy
    ssh -o StrictHostKeyChecking=no frogg@${DEPLOY_SERVER} bash << 'REMOTE'
set -e

# Load the images
docker load -i /tmp/pulse-api.tar
docker load -i /tmp/pulse-web.tar
rm -f /tmp/pulse-api.tar /tmp/pulse-web.tar

# Stop existing containers
docker stop pulse-api pulse-web pulse-db 2>/dev/null || true
docker rm pulse-api pulse-web pulse-db 2>/dev/null || true

# Create network if not exists
docker network create pulse-network 2>/dev/null || true

# Create volumes if not exists
docker volume create pulse_postgres_data 2>/dev/null || true

# Start TimescaleDB
docker run -d \
  --name pulse-db \
  --network pulse-network \
  -p 32202:5432 \
  -v pulse_postgres_data:/var/lib/postgresql/data \
  -e POSTGRES_DB=pulse \
  -e POSTGRES_USER=pulse \
  -e POSTGRES_PASSWORD=pulse_prod_password \
  --restart unless-stopped \
  timescale/timescaledb:latest-pg15

# Wait for database
echo "Waiting for database..."
sleep 15

# Start API
docker run -d \
  --name pulse-api \
  --network pulse-network \
  -p 5031:8080 \
  -e DATABASE_URL=postgres://pulse:pulse_prod_password@pulse-db:5432/pulse?sslmode=disable \
  -e PORT=8080 \
  -e BIND_ADDR=0.0.0.0:8080 \
  -e ENV=production \
  -e JWT_SECRET=prod_jwt_secret_key_min_32_chars_long_change_in_prod \
  -e VAULT_KEY=prod_vault_key_32_chars_change_in_prod \
  -e COLLECTION_INTERVAL=30s \
  -e RETENTION_DAYS=30 \
  --restart unless-stopped \
  pulse-api:latest

# Wait for API
echo "Waiting for API..."
sleep 10

# Start Web
docker run -d \
  --name pulse-web \
  --network pulse-network \
  -p 5030:80 \
  --restart unless-stopped \
  pulse-web:latest

echo "Deployed Pulse to production!"
REMOTE
    
    rm -f /tmp/pulse-api.tar /tmp/pulse-web.tar
else
    echo ">>> Deploying locally for dev"
    
    # Just use docker compose for local dev deployment
    docker compose down || true
    docker compose up -d
fi

echo "=== Deployment complete ==="
