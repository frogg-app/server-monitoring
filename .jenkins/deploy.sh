#!/bin/bash
set -e

make down 2>/dev/null || true

# Launch the app on port 5030 (web) and 5031 (api)
echo "=== Launching server-monitoring on ports 5030 (web) and 5031 (api) ==="
export WEB_PORT=5030
export API_PORT=5031
export POSTGRES_PASSWORD=jenkins-deployment-password
export JWT_SECRET=jenkins-jwt-secret-minimum-32-characters-required
export VAULT_KEY=jenkins-vault-key-minimum-32-characters-required
make up

echo "App launched on ports 5030 (web) and 5031 (api)"
