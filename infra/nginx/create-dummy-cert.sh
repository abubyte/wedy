#!/bin/bash

# Script to create dummy SSL certificates for nginx to start
# This allows nginx to start before Let's Encrypt certificates are obtained

set -e

DOMAIN="api.wedy.uz"
CERT_DIR="./infra/nginx/certbot/conf/live/$DOMAIN"

echo "Creating dummy SSL certificates for $DOMAIN..."

# Create directory structure (including archive for Let's Encrypt compatibility)
mkdir -p "$CERT_DIR"
mkdir -p "./infra/nginx/certbot/conf/archive/$DOMAIN"

# Generate dummy certificate
echo "Generating self-signed certificate..."
openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
  -keyout "$CERT_DIR/privkey.pem" \
  -out "$CERT_DIR/fullchain.pem" \
  -subj "/CN=$DOMAIN"

# Also create chain.pem (sometimes required)
cp "$CERT_DIR/fullchain.pem" "$CERT_DIR/chain.pem"

# Copy to archive directory (Let's Encrypt structure)
cp "$CERT_DIR/privkey.pem" "./infra/nginx/certbot/conf/archive/$DOMAIN/privkey1.pem"
cp "$CERT_DIR/fullchain.pem" "./infra/nginx/certbot/conf/archive/$DOMAIN/fullchain1.pem"
cp "$CERT_DIR/chain.pem" "./infra/nginx/certbot/conf/archive/$DOMAIN/chain1.pem"

# Set permissions
chmod 644 "$CERT_DIR/fullchain.pem"
chmod 644 "$CERT_DIR/chain.pem"
chmod 600 "$CERT_DIR/privkey.pem"

echo "✅ Dummy certificates created at: $CERT_DIR"
echo ""
echo "⚠️  WARNING: These are temporary dummy certificates for nginx to start."
echo "   Run ./infra/nginx/init-letsencrypt.sh to get real Let's Encrypt certificates."
echo ""
echo "Now restart nginx: docker compose restart nginx"

