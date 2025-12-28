#!/bin/bash

# Script to fix "archive directory exists" error in Let's Encrypt
# This script completely cleans up old certificate data

set -e

DOMAIN="api.wedy.uz"
DATA_PATH="./infra/nginx/certbot"

echo "=== Cleaning up old Let's Encrypt certificate data ==="
echo ""

# Stop certbot container if running
echo "Stopping certbot container..."
docker compose stop certbot 2>/dev/null || true

# Remove all certificate data from host
echo "Removing certificate directories..."
rm -rf "$DATA_PATH/conf/live/$DOMAIN"
rm -rf "$DATA_PATH/conf/archive/$DOMAIN"
rm -rf "$DATA_PATH/conf/renewal/${DOMAIN}.conf"
rm -rf "$DATA_PATH/conf/accounts"
rm -rf "$DATA_PATH/conf/keys"
rm -rf "$DATA_PATH/conf/csr"

# Also clean from container if it exists
echo "Cleaning from certbot container..."
docker compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$DOMAIN && \
  rm -Rf /etc/letsencrypt/archive/$DOMAIN && \
  rm -Rf /etc/letsencrypt/renewal/${DOMAIN}.conf && \
  rm -Rf /etc/letsencrypt/accounts && \
  rm -Rf /etc/letsencrypt/keys && \
  rm -Rf /etc/letsencrypt/csr" certbot 2>/dev/null || true

echo ""
echo "✅ Certificate data cleaned up successfully!"
echo ""
echo "Now you can run: ./init-letsencrypt.sh"

