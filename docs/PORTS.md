Frontend Port Policy

- Purpose: Ensure the frontend (web UI) is always published on host port 32200 by default.
- Where it's enforced:
  - `docker-compose.yml` — `web` service ports default to `${WEB_PORT:-32200}:80`
  - `docker-compose.prod.yml` — `nginx` service maps `${WEB_PORT:-32200}:80` (HTTP)
  - `app/nginx.conf` — Nginx inside the container listens on port `80` (unchanged)
  - `.env.example` — `WEB_PORT=32200` documented for developers

- How to override temporarily: set `WEB_PORT` in your environment or `.env` before running `docker compose up`.

- Bind address recommendation: set `BIND_ADDR=0.0.0.0:8080` in your `.env` to bind the API to all interfaces so it's reachable from other machines on your LAN. Avoid leaving it as `127.0.0.1:8080` if you expect remote access.

- API host port (local dev): `API_PORT=32201` maps to container `8080`.
- Postgres host port (local dev): `DB_PORT=32202` maps to container `5432`.

- Important reminder for deploys:
  - If deploying to a host where HTTP/HTTPS standard ports are required (80/443), update your host routing or reverse proxy to forward `32200` to `80`, or adjust `docker-compose.prod.yml` as needed.

- Do not change the container's internal nginx listen port (80) unless you update all references to the target port in Compose and healthchecks.

If you'd like, I can also add a CI check or a Makefile target that validates `WEB_PORT` is set to `32200` to avoid accidental changes.
