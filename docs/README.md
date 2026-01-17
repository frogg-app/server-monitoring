# Pulse Server Monitoring - Documentation

Pulse is a self-hosted server monitoring platform with real-time metrics, alerts, and container management.

## Table of Contents

- [Getting Started](#getting-started)
- [Installation](#installation)
- [API Reference](#api-reference)
- [Features](#features)
- [Configuration](#configuration)

---

## Getting Started

### Prerequisites

- Docker and Docker Compose (v2.0+)
- PostgreSQL 15+ with TimescaleDB (included in Docker setup)
- Modern web browser

### Quick Start

1. Clone the repository and navigate to the project directory
2. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```
3. Start the services:
   ```bash
   docker compose up -d
   ```
4. Access the web UI at `http://localhost:8080`

Default credentials:
- Username: `admin`
- Password: `admin123`

---

## Installation

### Docker Compose (Recommended)

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

### Manual Installation

See the main [README.md](../README.md) for detailed manual installation instructions.

---

## API Reference

All API endpoints are prefixed with `/api/v1`.

### Authentication

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/auth/login` | POST | Login with username/password |
| `/auth/logout` | POST | Logout and invalidate tokens |
| `/auth/refresh` | POST | Refresh access token |
| `/auth/me` | GET | Get current user info |

### Servers

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/servers` | GET | List all servers |
| `/servers` | POST | Create a new server |
| `/servers/{id}` | GET | Get server details |
| `/servers/{id}` | PUT | Update server |
| `/servers/{id}` | DELETE | Delete server |
| `/servers/{id}/test` | POST | Test server connection |
| `/servers/{id}/metrics` | GET | Get current server metrics |
| `/servers/{id}/containers` | GET | List Docker containers |

### Alerts

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/alerts/rules` | GET | List alert rules |
| `/alerts/rules` | POST | Create alert rule |
| `/alerts/rules/{id}` | GET | Get alert rule |
| `/alerts/rules/{id}` | PATCH | Update alert rule |
| `/alerts/rules/{id}` | DELETE | Delete alert rule |
| `/alerts/events` | GET | List alert events |
| `/alerts/events/{id}` | GET | Get alert event |
| `/alerts/events/{id}/acknowledge` | POST | Acknowledge alert |

### Settings

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/settings/notifications` | GET | List notification channels |
| `/settings/notifications` | POST | Create notification channel |
| `/settings/notifications/{id}` | DELETE | Delete notification channel |
| `/settings/notifications/{id}/test` | POST | Test notification channel |

---

## Features

### Dashboard
- Overview of all monitored servers
- Quick status summary (online/offline counts)
- Quick actions for common tasks

### Server Management
- Add, edit, and remove servers
- View real-time CPU, memory, disk, and network metrics
- Docker container management

### Alerting
- Create custom alert rules based on metrics thresholds
- Multiple notification channels (Email, Webhook, Slack, Discord, Telegram)
- Alert history and acknowledgement

### Settings
- User profile management
- Notification channel configuration
- Theme switching (dark/light mode)

---

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | Required |
| `SERVICE_NODE_SECRET` | JWT signing secret | Required |
| `BIND_ADDR` | API server bind address | `:8080` |

### Docker Compose Configuration

The `docker-compose.yml` file defines the following services:
- `db`: PostgreSQL with TimescaleDB
- `api`: Go backend service
- `web`: Flutter web frontend

---

## Support

For issues and feature requests, please use the project issue tracker.
