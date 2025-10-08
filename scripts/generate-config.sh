#!/bin/bash
set -eu

# Load environment variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Default values
HEADSCALE_SERVER_URL=${HEADSCALE_SERVER_URL:-"https://headscale.example.com"}
HEADSCALE_BASE_DOMAIN=${HEADSCALE_BASE_DOMAIN:-"example.com"}
HEADSCALE_USE_SQLITE=${HEADSCALE_USE_SQLITE:-"true"}
HEADSCALE_DATABASE_URL=${HEADSCALE_DATABASE_URL:-""}

# Determine database type
if [ "${HEADSCALE_USE_SQLITE}" = "true" ] || [ -z "${HEADSCALE_DATABASE_URL}" ]; then
  DB_TYPE="sqlite"
else
  DB_TYPE="postgres"
fi

# Create directories and acme.json file
mkdir -p data/headscale data/traefik headscale
if [ ! -f data/traefik/acme.json ]; then
  touch data/traefik/acme.json
  chmod 600 data/traefik/acme.json
fi

# Create basic auth users file if it doesn't exist
if [ ! -f data/traefik/users ]; then
  echo "Creating basic auth users file..."
  echo "# Basic auth users for headscale-ui"
  echo "# Format: username:hashed_password"
  echo "# Generate password hash with: htpasswd -nb username password"
  echo "# Example: admin:\$2y\$10\$example_hash_here"
  echo "# Replace with your actual username and hashed password"
  echo "admin:\$2y\$10\$example_hash_here" > data/traefik/users
  chmod 600 data/traefik/users
  echo "⚠️  Please edit data/traefik/users with your actual username and password hash"
fi

echo "Generating headscale config..."
echo "Server URL: $HEADSCALE_SERVER_URL"
echo "Base Domain: $HEADSCALE_BASE_DOMAIN"
echo "Database: $DB_TYPE"

# Generate config.yaml
cat > headscale/config.yaml << EOF
server_url: "$HEADSCALE_SERVER_URL"
listen_addr: "0.0.0.0:8080"
metrics_listen_addr: "127.0.0.1:9090"
grpc_listen_addr: "0.0.0.0:50443"
grpc_allow_insecure: false

prefixes:
  v6nat: fd7a:115c:a1e0::/48
  v4: 100.64.0.0/10
  v6: fd7a:115c:a1e0::/48

dns:
  base_domain: "$HEADSCALE_BASE_DOMAIN"
  magic_dns: true
  override_local_dns: false
  nameservers:
    global: ["1.1.1.1", "8.8.8.8"]

noise:
  private_key_path: "/var/lib/headscale/noise_private.key"

log:
  level: info

database:
  type: $DB_TYPE
EOF

if [ "$DB_TYPE" = "postgres" ]; then
  cat >> headscale/config.yaml << EOF
  postgres:
    connection_string: "$HEADSCALE_DATABASE_URL"
EOF
else
  cat >> headscale/config.yaml << EOF
  sqlite:
    path: "/var/lib/headscale/db.sqlite"
EOF
fi

cat >> headscale/config.yaml << EOF

derp:
  server:
    enabled: true
    region_id: 999
    region_code: "headscale"
    region_name: "Headscale Embedded DERP"
    stun_listen_addr: "0.0.0.0:3478"
    private_key_path: "/var/lib/headscale/derp_server.key"

tls_letsencrypt_challenge:
  enabled: false

tls_cert_path: ""
tls_key_path: ""
EOF

echo "✅ Headscale config generated: headscale/config.yaml"
echo "✅ Database type: $DB_TYPE"

if [ "$DB_TYPE" = "sqlite" ]; then
  echo "✅ SQLite database will be created at: data/headscale/db.sqlite"
else
  echo "✅ Using Postgres database: $HEADSCALE_DATABASE_URL"
fi

echo ""
echo "⚠️  Important: Headscale v0.26.1 requires noise private key and DERP server"
echo "   Keys will be auto-generated on first run:"
echo "   - data/headscale/noise_private.key"
echo "   - data/headscale/derp_server.key"
echo ""
echo "Next steps:"
echo "1. Review headscale/config.yaml"
echo "2. Run: docker compose up -d"
echo "3. Check logs: docker logs headscale"
