## Headscale + Traefik (Production-Ready Docker Compose)

Secure, minimal Docker Compose stack for running Headscale behind Traefik with automatic TLS via Let's Encrypt. Designed for Ubuntu 24 with Docker Compose v2.24+.


### Quickstart

1) Copy environment and prepare directories

```bash
cp .env.example .env
mkdir -p secrets data/traefik data/headscale
chmod 700 secrets
touch data/traefik/acme.json && chmod 600 data/traefik/acme.json
```

2) Configure `.env`

- Set `ACME_EMAIL`, `HEADSCALE_FQDN`, `HEADSCALE_SERVER_URL`, `HEADSCALE_BASE_DOMAIN`.
- Choose ACME mode: `TRAEFIK_ACME_DNS01=true` (Cloudflare) or keep `false` for HTTP-01.
- For sqlite fallback: set `HEADSCALE_USE_SQLITE=true` and leave `HEADSCALE_DATABASE_URL` empty.

3) Generate Headscale config

```bash
./scripts/generate-config.sh
```

4) Launch

```bash
docker compose up -d
```

Headscale will be available at `https://$HEADSCALE_FQDN` when certs are issued.

**Optional secrets:**
- If using DNS-01 with Cloudflare: put your API token in `secrets/cloudflare_api_token`.
- If using Postgres: put the DB password in `secrets/postgres_password` and set `HEADSCALE_DATABASE_URL` accordingly.

### Environment variables

| Variable | Description |
|---|---|
| `ACME_EMAIL` | Email used for Let's Encrypt registration and expiry notices |
| `TRAEFIK_ACME_DNS01` | `true` to use DNS-01 (Cloudflare token required), `false` for HTTP-01 |
| `TRAEFIK_LOG_LEVEL` | Traefik log level: DEBUG, INFO, WARN, ERROR |
| `HEADSCALE_FQDN` | Public FQDN used by Traefik router and Headscale server URL |
| `HEADSCALE_BASE_DOMAIN` | Base domain used by Headscale for MagicDNS |
| `HEADSCALE_SERVER_URL` | Public URL of Headscale (must be https and match FQDN) |
| `HEADSCALE_DATABASE_URL` | Postgres DSN (leave empty for sqlite fallback) |
| `HEADSCALE_USE_SQLITE` | `true` to use sqlite at `data/headscale/db.sqlite` |
| `TRAEFIK_IMAGE_TAG` | Traefik image tag (default `latest`) |
| `HEADSCALE_IMAGE_TAG` | Headscale image tag (default `latest`) |
| `HEADSCALE_UI_IMAGE_TAG` | Headscale UI image tag (default `latest`) |
| `HEADSCALE_UI_PATH_PREFIX` | UI path prefix under FQDN in override (default `/web`) |
| `TRAEFIK_DASHBOARD_HOST` | Dashboard host in override (default `dashboard.localtest.me`) |
| `TRAEFIK_DEFAULT_MIDDLEWARES` | Default middlewares list for routers (file refs) |


### Backup and restore

- Traefik ACME: `data/traefik/acme.json` (contains certificates and private keys).
- Headscale: `data/headscale/` (keys and sqlite DB if used).
- If using Postgres: back up the external database according to your RPO/RTO.