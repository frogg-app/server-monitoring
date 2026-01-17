# Pulse

**Server & Homelab Monitoring Platform**

A fast, visually rich, cross-platform monitoring and management platform for servers and homelabs. Scales from a single Raspberry Pi to enterprise clusters.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Go Version](https://img.shields.io/badge/go-1.22+-00ADD8.svg)
![Flutter Version](https://img.shields.io/badge/flutter-3.x-02569B.svg)

## Features

- 📊 **Real-time Metrics** - CPU, memory, disk, network monitoring with live updates
- 🐳 **Docker Management** - Container lifecycle, stats, and log viewing
- 🔔 **Smart Alerts** - Threshold-based alerts with customizable notification channels
- 🔐 **Secure Credentials** - AES-256-GCM encrypted credential vault for SSH keys
- 📈 **Historical Data** - TimescaleDB-powered time-series storage with 30-day retention
- 🌐 **Multi-platform** - Windows desktop + Web clients
- 🎨 **Modern UI** - Dark mode with electric blue accents

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│  Service Node   │
│  (Windows/Web)  │ API │   (Go + Chi)    │
└─────────────────┘     └────────┬────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
               ┌────▼────┐              ┌─────▼─────┐
               │ PostgreSQL│              │  Servers  │
               │ TimescaleDB│              │  (SSH)    │
               └──────────┘              └───────────┘
```

## Quick Start

### Automated Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/pulse-server/pulse.git
cd pulse

# Run the setup script
./deploy/setup.sh

# Access the web UI at http://localhost:8080
```

The setup script will:
- Generate secure secrets and create `.env` file
- Optionally create a self-signed SSL certificate
- Build Docker images
- Start all services
- Display default admin credentials

### Manual Installation

1. **Create environment file:**

```bash
cp .env.example .env
```

2. **Configure `.env`:**

```env
# Database
POSTGRES_USER=pulse
POSTGRES_PASSWORD=<generate-secure-password>
POSTGRES_DB=pulse
DATABASE_URL=postgres://pulse:<password>@db:5432/pulse?sslmode=disable

# Security
JWT_SECRET=<generate-32-char-secret>
VAULT_KEY=<generate-32-char-secret>

# Server
PORT=8080
LOG_LEVEL=info
```

3. **Start services:**

```bash
# Development
docker compose up -d

# Production (with nginx)
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

4. **Access the application:**
   - Web UI: http://localhost:8080
   - API: http://localhost:8080/api/v1

### Default Credentials

- **Username:** admin
- **Password:** admin123

⚠️ **Change the default password immediately after first login!**

## Development Setup

### Prerequisites

- Go 1.22+
- Flutter 3.x
- PostgreSQL 15+ with TimescaleDB
- Docker (optional)

### Backend Development

```bash
cd service-node

# Install dependencies
go mod download

# Set up local database
createdb pulse
psql pulse -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"

# Run migrations
export DATABASE_URL="postgres://localhost:5432/pulse?sslmode=disable"
go run cmd/serviced/main.go migrate

# Run the server
go run cmd/serviced/main.go

# Run tests
go test ./...
```

### Frontend Development

```bash
cd app

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on Windows
flutter run -d windows

# Build for web
flutter build web

# Build for Windows
flutter build windows
```

### API Development

The OpenAPI specification is located at [shared/openapi.yaml](shared/openapi.yaml).

## API Reference

### Authentication

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/auth/login` | POST | Authenticate user |
| `/api/v1/auth/logout` | POST | Invalidate session |
| `/api/v1/auth/refresh` | POST | Refresh access token |
| `/api/v1/auth/me` | GET | Get current user |

### Servers

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/servers` | GET | List all servers |
| `/api/v1/servers` | POST | Register new server |
| `/api/v1/servers/{id}` | GET | Get server details |
| `/api/v1/servers/{id}` | PUT | Update server |
| `/api/v1/servers/{id}` | DELETE | Remove server |
| `/api/v1/servers/{id}/metrics` | GET | Get server metrics |
| `/api/v1/servers/{id}/containers` | GET | List Docker containers |

### Alerts

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/alerts/rules` | GET | List alert rules |
| `/api/v1/alerts/rules` | POST | Create alert rule |
| `/api/v1/alerts/events` | GET | List alert events |
| `/api/v1/alerts/channels` | GET | List notification channels |

### Health

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/health` | GET | Health check |

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 8080 | HTTP server port |
| `DATABASE_URL` | - | PostgreSQL connection string |
| `JWT_SECRET` | - | Secret for JWT signing (min 32 chars) |
| `VAULT_KEY` | - | AES-256 key for credential encryption |
| `LOG_LEVEL` | info | Log verbosity (debug, info, warn, error) |
| `METRICS_RETENTION_DAYS` | 30 | Days to retain metric data |

### Alert Rule Configuration

Alert rules support the following metrics:
- `cpu_percent` - CPU usage percentage
- `memory_percent` - Memory usage percentage
- `disk_percent` - Disk usage percentage
- `load_1m` - 1-minute load average

Operators: `>`, `<`, `>=`, `<=`, `==`, `!=`

Example:
```json
{
  "name": "High CPU Alert",
  "server_id": "uuid",
  "metric": "cpu_percent",
  "operator": ">",
  "threshold": 90,
  "duration_seconds": 300
}
```

## Backup & Restore

### Creating Backups

```bash
# Create a backup
./deploy/backup.sh

# Specify output directory
./deploy/backup.sh /path/to/backups
```

Backups include:
- PostgreSQL database dump
- Configuration files (with secrets masked)

### Restoring from Backup

```bash
# Restore from a backup
./deploy/restore.sh backups/pulse_backup_20240115_120000.tar.gz
```

⚠️ Restore will overwrite the current database!

## Security

### Credential Vault

SSH credentials are encrypted using AES-256-GCM before storage. The encryption key (`VAULT_KEY`) should be:
- At least 32 characters
- Stored securely (never committed to version control)
- Backed up separately from database backups

### JWT Authentication

- Access tokens expire after 15 minutes
- Refresh tokens expire after 7 days
- Tokens are invalidated on logout

### Production Recommendations

1. **Enable HTTPS** - Use the nginx reverse proxy with valid SSL certificates
2. **Change default credentials** - Update admin password immediately
3. **Firewall rules** - Restrict access to port 443 only
4. **Regular backups** - Schedule automated backups
5. **Monitor logs** - Check for unauthorized access attempts

## Deployment

### Docker Compose (Recommended)

```bash
# Production deployment
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Kubernetes

Coming in v2.0

### Systemd (Manual)

```bash
# Build binary
cd service-node
go build -o /usr/local/bin/pulse-server cmd/serviced/main.go

# Create service file
cat > /etc/systemd/system/pulse.service << EOF
[Unit]
Description=Pulse Server Monitoring
After=network.target postgresql.service

[Service]
Type=simple
User=pulse
EnvironmentFile=/etc/pulse/environment
ExecStart=/usr/local/bin/pulse-server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
systemctl enable pulse
systemctl start pulse
```

## Troubleshooting

### Database Connection Issues

```bash
# Check if database is running
docker compose ps db

# View database logs
docker compose logs db

# Test connection
docker compose exec db psql -U pulse -c "SELECT 1"
```

### API Not Responding

```bash
# Check API logs
docker compose logs api

# Verify health endpoint
curl http://localhost:8080/api/v1/health
```

### Container Not Starting

```bash
# Check for port conflicts
lsof -i :8080

# View all logs
docker compose logs -f
```

### Reset Admin Password

```bash
# Connect to database
docker compose exec db psql -U pulse

# Update password (bcrypt hash for 'newpassword')
UPDATE users SET password_hash = '$2a$10$...' WHERE username = 'admin';
```

## Project Structure

```
pulse/
├── service-node/              # Go backend
│   ├── cmd/serviced/          # Main application
│   │   ├── main.go
│   │   └── migrations/        # SQL migrations
│   └── internal/
│       ├── api/               # HTTP handlers
│       ├── auth/              # Authentication service
│       ├── collector/         # Metric collectors
│       ├── config/            # Configuration
│       ├── db/                # Database connection
│       ├── middleware/        # HTTP middleware
│       ├── models/            # Domain models
│       ├── repository/        # Data access layer
│       └── vault/             # Credential encryption
├── app/                       # Flutter frontend
│   └── lib/
│       ├── app/               # App shell, theme, router
│       ├── core/              # API client, shared utilities
│       └── features/          # Feature modules
│           ├── auth/
│           ├── servers/
│           ├── metrics/
│           ├── containers/
│           ├── alerts/
│           └── settings/
├── shared/                    # Shared specifications
│   └── openapi.yaml           # API specification
├── deploy/                    # Deployment files
│   ├── nginx.conf
│   ├── setup.sh
│   ├── backup.sh
│   └── restore.sh
├── docker-compose.yml         # Development compose
├── docker-compose.prod.yml    # Production overrides
└── .github/workflows/         # CI/CD
    └── ci.yaml
```

## Roadmap

### v1.0 (Current)
- [x] Core metric collection (CPU, memory, disk, network)
- [x] Docker container management
- [x] Alert rules and notifications
- [x] User authentication
- [x] Web and Windows clients

### v1.1
- [ ] WebSocket real-time updates
- [ ] Email notifications
- [ ] Slack/Discord integrations
- [ ] Multi-user support

### v2.0
- [ ] Kubernetes integration
- [ ] Log aggregation
- [ ] Custom dashboards
- [ ] Mobile apps (iOS/Android)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
- All tests pass (`go test ./...`)
- Code follows project style guidelines
- Documentation is updated

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Chi Router](https://github.com/go-chi/chi) - Lightweight Go HTTP router
- [TimescaleDB](https://www.timescale.com/) - Time-series database
- [Flutter](https://flutter.dev/) - Cross-platform UI framework
- [Riverpod](https://riverpod.dev/) - State management for Flutter
