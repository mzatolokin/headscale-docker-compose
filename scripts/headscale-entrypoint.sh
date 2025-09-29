#!/bin/sh
set -eu

CONFIG_TEMPLATE="/etc/headscale/config.yaml.tpl"
CONFIG_FILE="/etc/headscale/config.yaml"

mkdir -p /var/lib/headscale

# Render config from template and environment
if [ -f "$CONFIG_TEMPLATE" ]; then
  # Determine DB backend
  if [ "${HEADSCALE_USE_SQLITE:-false}" = "true" ] || [ -z "${HEADSCALE_DATABASE_URL:-}" ]; then
    export EFFECTIVE_DB_TYPE="sqlite"
  else
    export EFFECTIVE_DB_TYPE="postgres"
  fi

  # Read password secret if DSN missing password placeholder
  if [ "$EFFECTIVE_DB_TYPE" = "postgres" ] && [ -f /run/secrets/postgres_password ]; then
    export POSTGRES_PASSWORD="$(cat /run/secrets/postgres_password)"
  fi

  awk 'BEGIN{ while ((getline line < ENVIRON["CONFIG_TEMPLATE"]) > 0) print line }' >/dev/null 2>&1 || true

  # Simple envsubst using POSIX shell
  # shellcheck disable=SC2016
  cat "$CONFIG_TEMPLATE" \
    | sed "s|\${HEADSCALE_SERVER_URL}|${HEADSCALE_SERVER_URL:-}|g" \
    | sed "s|\${HEADSCALE_BASE_DOMAIN}|${HEADSCALE_BASE_DOMAIN:-}|g" \
    | sed "s|\${HEADSCALE_DATABASE_URL}|${HEADSCALE_DATABASE_URL:-}|g" \
    | sed "s|\${EFFECTIVE_DB_TYPE}|${EFFECTIVE_DB_TYPE:-sqlite}|g" \
    > "$CONFIG_FILE"
fi

exec headscale "$@"


