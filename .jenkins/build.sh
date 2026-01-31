#!/bin/bash
set -e

echo "=== Building server-monitoring ==="

# Set required environment variables for build
export POSTGRES_PASSWORD=build-only-password
export JWT_SECRET=build-only-jwt-secret-min-32-chars
export VAULT_KEY=build-only-vault-key-min-32-chars

# Build using Makefile
make build

# Configure git

echo "Build completed successfully!"
