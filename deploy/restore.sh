#!/bin/bash
#
# Pulse Server Monitoring - Restore Script
#
# Restores from a backup archive created by backup.sh
#
# Usage: ./restore.sh <backup_file.tar.gz>
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Backup file not specified${NC}"
    echo "Usage: $0 <backup_file.tar.gz>"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "${BACKUP_FILE}" ]; then
    echo -e "${RED}Error: Backup file not found: ${BACKUP_FILE}${NC}"
    exit 1
fi

echo -e "${YELLOW}Pulse Restore Script${NC}"
echo "====================="
echo ""
echo -e "Restoring from: ${GREEN}${BACKUP_FILE}${NC}"
echo ""

# Confirm
read -p "This will overwrite the current database. Continue? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Restore cancelled."
    exit 0
fi

# Load environment
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please run setup.sh first or create .env manually."
    exit 1
fi

# Extract backup
TEMP_DIR=$(mktemp -d)
echo -e "${YELLOW}Extracting backup...${NC}"
tar -xzf "${BACKUP_FILE}" -C "${TEMP_DIR}"
BACKUP_NAME=$(ls "${TEMP_DIR}")
BACKUP_PATH="${TEMP_DIR}/${BACKUP_NAME}"

echo -e "${GREEN}✓ Backup extracted${NC}"

# Check for database dump
if [ ! -f "${BACKUP_PATH}/database.dump" ]; then
    echo -e "${RED}Error: database.dump not found in backup${NC}"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Ensure database is running
echo -e "${YELLOW}Ensuring database is running...${NC}"
docker compose up -d db

# Wait for database
echo -e "${YELLOW}Waiting for database...${NC}"
for i in {1..30}; do
    if docker compose exec -T db pg_isready -U "${POSTGRES_USER:-pulse}" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

echo -e "${GREEN}✓ Database is ready${NC}"

# Stop API to prevent connections
echo -e "${YELLOW}Stopping API service...${NC}"
docker compose stop api 2>/dev/null || true

# Restore database
echo -e "${YELLOW}Restoring database...${NC}"

# Copy dump into container
docker compose cp "${BACKUP_PATH}/database.dump" db:/tmp/database.dump

# Drop and recreate database
docker compose exec -T db psql -U "${POSTGRES_USER:-pulse}" -d postgres -c "DROP DATABASE IF EXISTS ${POSTGRES_DB:-pulse};" || true
docker compose exec -T db psql -U "${POSTGRES_USER:-pulse}" -d postgres -c "CREATE DATABASE ${POSTGRES_DB:-pulse};"

# Restore
docker compose exec -T db pg_restore \
    -U "${POSTGRES_USER:-pulse}" \
    -d "${POSTGRES_DB:-pulse}" \
    --clean \
    --if-exists \
    /tmp/database.dump || true

docker compose exec -T db rm /tmp/database.dump

echo -e "${GREEN}✓ Database restored${NC}"

# Restart services
echo -e "${YELLOW}Restarting services...${NC}"
docker compose up -d

echo -e "${GREEN}✓ Services restarted${NC}"

# Cleanup
rm -rf "${TEMP_DIR}"

echo ""
echo -e "${GREEN}Restore complete!${NC}"
echo ""
echo "You may want to verify the restore by logging into the application."
