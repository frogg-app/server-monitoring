# Assumptions

This document records decisions made when the implementation plan was ambiguous or incomplete.

---

## General

1. **App Name:** Using "Pulse" as the product name per the branding section recommendation.

2. **Go Version:** Using Go 1.22+ for the service node backend.

3. **Flutter Version:** Using Flutter 3.x stable channel.

4. **Database:** PostgreSQL 15 with TimescaleDB extension, deployed via Docker Compose.

---

## Backend

1. **HTTP Framework:** Using `chi` router for the Go API - lightweight, stdlib-compatible, good middleware support.

2. **JWT Library:** Using `golang-jwt/jwt/v5` for JWT generation and validation.

3. **Database Driver:** Using `jackc/pgx/v5` for PostgreSQL - best performance and feature support.

4. **SSH Library:** Using `golang.org/x/crypto/ssh` for SSH connections to monitored hosts.

5. **Docker SDK:** Using official `docker/docker` client library for Docker API interactions.

6. **Kubernetes Client:** Using `k8s.io/client-go` for Kubernetes API interactions.

7. **Password Hashing:** Using bcrypt with cost factor 12.

8. **Encryption:** AES-256-GCM for credential encryption, key derived from SERVICE_NODE_SECRET using HKDF.

9. **Default Port:** Service node binds to port 8080 by default.

10. **Default Bind Address:** 127.0.0.1 (localhost only) for security; configurable via BIND_ADDR.

---

## Frontend (Flutter)

1. **State Management:** Using Riverpod for reactive state management.

2. **HTTP Client:** Using `dio` package for HTTP requests with interceptors.

3. **WebSocket:** Using `web_socket_channel` package for WebSocket connections.

4. **Charts:** Using `fl_chart` package for metric visualizations.

5. **Routing:** Using `go_router` for declarative routing.

6. **Secure Storage:** Using `flutter_secure_storage` for storing tokens on Windows.

7. **Theme:** Dark mode as default, electric blue (#00BFFF) as accent color.

---

## API

1. **Pagination Defaults:** page=1, per_page=50 (max 100).

2. **Rate Limiting:** 100 requests/second per IP, configurable via RATE_LIMIT env var.

3. **Access Token Expiry:** 15 minutes.

4. **Refresh Token Expiry:** 7 days.

5. **WebSocket Ping Interval:** 30 seconds to keep connections alive.

---

## Collectors

1. **Default Collection Interval:** 15 seconds for system metrics, 30 seconds for network/process/docker.

2. **Collection Timeout:** 10 seconds per collection job.

3. **Worker Pool Size:** 10 concurrent collection jobs by default.

4. **Failure Backoff:** Exponential backoff starting at 30s, max 5 minutes after consecutive failures.

5. **Cache TTL:** 5 minutes for in-memory metric cache.

---

## Deployment

1. **Docker Registry:** Placeholder ${REGISTRY} - users configure their own registry.

2. **TLS:** Recommend reverse proxy (Caddy/Traefik) for production TLS; service node can generate self-signed certs for development.

3. **Log Format:** Structured JSON to stdout.

4. **Metrics Retention:** 7 days raw (15s granularity), 90 days downsampled (5 min avg).

---

## Testing

1. **Backend Coverage Target:** 80% on critical packages (auth, collectors, alerting).

2. **Frontend Coverage Target:** 70% widget test coverage.

3. **Integration Tests:** Run against TimescaleDB in Docker, not a mock.

---

*This document will be updated as implementation progresses and new decisions are made.*
