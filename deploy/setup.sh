#!/bin/bash
#
# Pulse Server Monitoring - Setup Script
#
# This script sets up a new Pulse installation:
# 1. Generates secure secrets
# 2. Creates .env file
# 3. Starts services with Docker Compose
#
# Usage: ./setup.sh [--dev|--prod]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
MODE="dev"
while [[ $# -gt 0 ]]; do
    case $1 in
        --prod|--production)
            MODE="prod"
            shift
            ;;
        --dev|--development)
            MODE="dev"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--dev|--prod]"
            echo ""
            echo "Options:"
            echo "  --dev   Development mode (default)"
            echo "  --prod  Production mode"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Pulse Server Monitoring Setup      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "Mode: ${GREEN}$MODE${NC}"
echo ""

# Check requirements
echo -e "${YELLOW}Checking requirements...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker and Docker Compose found${NC}"
echo ""

# Generate secrets
echo -e "${YELLOW}Generating secrets...${NC}"

generate_secret() {
    openssl rand -base64 32 | tr -d '/+=' | head -c 32
}

JWT_SECRET=$(generate_secret)
VAULT_KEY=$(generate_secret)
POSTGRES_PASSWORD=$(generate_secret)

echo -e "${GREEN}✓ Secrets generated${NC}"
echo ""

# Create .env file
if [ -f .env ]; then
    echo -e "${YELLOW}Existing .env file found. Creating backup...${NC}"
    cp .env .env.backup.$(date +%Y%m%d%H%M%S)
fi

echo -e "${YELLOW}Creating .env file...${NC}"

cat > .env << EOF
# Pulse Server Monitoring Configuration
# Generated: $(date)
# Mode: $MODE

# Database
POSTGRES_DB=pulse
POSTGRES_USER=pulse
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Server
PORT=8080
ENV=$MODE

# Authentication
JWT_SECRET=$JWT_SECRET
ACCESS_TOKEN_TTL=15m
REFRESH_TOKEN_TTL=168h

# Credential Vault
VAULT_KEY=$VAULT_KEY

# Metrics Collection
COLLECTION_INTERVAL=30s
RETENTION_DAYS=30
EOF

if [ "$MODE" = "prod" ]; then
    cat >> .env << EOF

# Production Settings
API_PORT=8080
DB_PORT=5432
EOF
else
    cat >> .env << EOF

# Development Settings
API_PORT=8080
DB_PORT=5432
EOF
fi

echo -e "${GREEN}✓ .env file created${NC}"
echo ""

# Create SSL directory for production
if [ "$MODE" = "prod" ]; then
    echo -e "${YELLOW}Creating SSL directory...${NC}"
    mkdir -p deploy/ssl
    
    if [ ! -f deploy/ssl/cert.pem ]; then
        echo -e "${YELLOW}Generating self-signed certificate (replace with real cert for production)...${NC}"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout deploy/ssl/key.pem \
            -out deploy/ssl/cert.pem \
            -subj "/CN=localhost" 2>/dev/null
        echo -e "${GREEN}✓ Self-signed certificate created${NC}"
    fi
    echo ""
fi

# Pull/build images
echo -e "${YELLOW}Building Docker images...${NC}"

if [ "$MODE" = "prod" ]; then
    docker compose -f docker-compose.yml -f docker-compose.prod.yml build
else
    docker compose build
fi

echo -e "${GREEN}✓ Images built${NC}"
echo ""

# Start services
echo -e "${YELLOW}Starting services...${NC}"

if [ "$MODE" = "prod" ]; then
    docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
else
    docker compose up -d
fi

echo -e "${GREEN}✓ Services started${NC}"
echo ""

# Wait for services to be healthy
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 5

# Check health
MAX_RETRIES=30
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API server is ready${NC}"
        break
    fi
    RETRY=$((RETRY + 1))
    sleep 1
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo -e "${RED}Warning: API server health check timed out${NC}"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Setup Complete!                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "API Server: ${BLUE}http://localhost:8080${NC}"
echo ""
echo -e "Default credentials:"
echo -e "  Username: ${YELLOW}admin${NC}"
echo -e "  Password: ${YELLOW}admin123${NC}"
echo ""
echo -e "${RED}⚠ IMPORTANT: Change the default password after first login!${NC}"
echo ""
echo -e "Useful commands:"
echo -e "  View logs:    ${YELLOW}docker compose logs -f${NC}"
echo -e "  Stop:         ${YELLOW}docker compose down${NC}"
echo -e "  Restart:      ${YELLOW}docker compose restart${NC}"
echo ""
