#!/bin/sh
set -eu

# Ensure acme.json exists with correct permissions
if [ ! -f /acme.json ]; then
  touch /acme.json
  chmod 600 /acme.json
fi

# If DNS-01 is requested, export CF token from secret and adjust env
if [ "${TRAEFIK_ACME_DNS01:-false}" = "true" ]; then
  if [ -f /run/secrets/cloudflare_api_token ]; then
    export CF_DNS_API_TOKEN="$(cat /run/secrets/cloudflare_api_token)"
    export CF_API_TOKEN="$CF_DNS_API_TOKEN"
  else
    echo "TRAEFIK_ACME_DNS01=true but secrets/cloudflare_api_token is missing" >&2
    exit 1
  fi
  # Traefik uses env vars CF_API_TOKEN; static config must include dnsChallenge
  # We keep both http and dns in static config; Traefik will try based on challenge used by router
fi

exec traefik "$@"


