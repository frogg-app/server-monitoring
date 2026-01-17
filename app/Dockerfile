# Flutter Web Build and Serve Dockerfile
#
# Multi-stage build:
# 1. Build Flutter web app
# 2. Serve with nginx

# Build stage - use official Flutter image
FROM ghcr.io/cirruslabs/flutter:3.24.0 AS builder

WORKDIR /app

# Copy all source (pubspec.lock may not exist initially)
COPY . .

# Get dependencies
RUN flutter pub get

# Build web app
RUN flutter build web --release --no-tree-shake-icons

# Runtime stage - serve with nginx
FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
