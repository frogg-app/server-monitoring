#!/bin/bash
#
# Pulse Server Monitoring - Backup Script
#
# Creates a backup of:
# - PostgreSQL database
# - Configuration files
#
# Usage: ./backup.sh [output_dir]
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
BACKUP_DIR="${1:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="pulse_backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

echo -e "${YELLOW}Pulse Backup Script${NC}"
echo "===================="
echo ""

# Create backup directory
mkdir -p "${BACKUP_PATH}"

# Load environment
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Backup database
echo -e "${YELLOW}Backing up database...${NC}"
docker compose exec -T db pg_dump \
    -U "${POSTGRES_USER:-pulse}" \
    -d "${POSTGRES_DB:-pulse}" \
    --format=custom \
    --file=/tmp/database.dump

docker compose cp db:/tmp/database.dump "${BACKUP_PATH}/database.dump"
docker compose exec -T db rm /tmp/database.dump

echo -e "${GREEN}✓ Database backed up${NC}"

# Backup configuration
echo -e "${YELLOW}Backing up configuration...${NC}"

# Copy .env (with secrets masked)
sed 's/\(PASSWORD\|SECRET\|KEY\)=.*/\1=***MASKED***/g' .env > "${BACKUP_PATH}/.env.masked"

# Copy docker-compose files
cp docker-compose.yml "${BACKUP_PATH}/"
[ -f docker-compose.prod.yml ] && cp docker-compose.prod.yml "${BACKUP_PATH}/"

# Copy deploy config
[ -d deploy ] && cp -r deploy "${BACKUP_PATH}/"

echo -e "${GREEN}✓ Configuration backed up${NC}"

# Create archive
echo -e "${YELLOW}Creating archive...${NC}"
cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
rm -rf "${BACKUP_NAME}"

echo -e "${GREEN}✓ Archive created: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz${NC}"
echo ""

# Cleanup old backups (keep last 7)
echo -e "${YELLOW}Cleaning up old backups...${NC}"
ls -t "${BACKUP_DIR}"/pulse_backup_*.tar.gz 2>/dev/null | tail -n +8 | xargs -r rm --
echo -e "${GREEN}✓ Old backups cleaned${NC}"
echo ""

# Show backup size
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)
echo -e "Backup size: ${GREEN}${BACKUP_SIZE}${NC}"
echo -e "Location: ${GREEN}${BACKUP_DIR}/${BACKUP_NAME}.tar.gz${NC}"
echo ""
echo -e "${GREEN}Backup complete!${NC}"
