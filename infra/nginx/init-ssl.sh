#!/bin/bash

# ===========================================
# SSL Certificate Initialization Script
# ===========================================
# Usage: ./init-ssl.sh [email] [domain]
# Example: ./init-ssl.sh admin@wedy.uz api.wedy.uz

set -e

# Configuration
EMAIL="${1:-admin@wedy.uz}"
DOMAIN="${2:-api.wedy.uz}"
DATA_PATH="./certbot"
RSA_KEY_SIZE=4096

echo "============================================"
echo "SSL Certificate Setup for $DOMAIN"
echo "============================================"

# Create directories
mkdir -p "$DATA_PATH/conf"
mkdir -p "$DATA_PATH/www"

# Check if certificate already exists
if [ -d "$DATA_PATH/conf/live/$DOMAIN" ]; then
    read -p "Certificate already exists. Renew? (y/N) " decision
    if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
        exit 0
    fi
fi

# Download recommended TLS parameters
if [ ! -e "$DATA_PATH/conf/options-ssl-nginx.conf" ] || [ ! -e "$DATA_PATH/conf/ssl-dhparams.pem" ]; then
    echo "Downloading recommended TLS parameters..."
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$DATA_PATH/conf/options-ssl-nginx.conf"
    curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$DATA_PATH/conf/ssl-dhparams.pem"
fi

# Create dummy certificate for nginx to start
echo "Creating dummy certificate for $DOMAIN..."
CERT_PATH="/etc/letsencrypt/live/$DOMAIN"
mkdir -p "$DATA_PATH/conf/live/$DOMAIN"

docker compose run --rm --entrypoint "\
    openssl req -x509 -nodes -newkey rsa:$RSA_KEY_SIZE -days 1 \
    -keyout '$CERT_PATH/privkey.pem' \
    -out '$CERT_PATH/fullchain.pem' \
    -subj '/CN=localhost'" certbot

echo "Starting nginx with dummy certificate..."
docker compose up --force-recreate -d nginx

echo "Deleting dummy certificate..."
docker compose run --rm --entrypoint "\
    rm -Rf /etc/letsencrypt/live/$DOMAIN && \
    rm -Rf /etc/letsencrypt/archive/$DOMAIN && \
    rm -Rf /etc/letsencrypt/renewal/$DOMAIN.conf" certbot

echo "Requesting Let's Encrypt certificate for $DOMAIN..."

# Select staging or production
read -p "Use staging environment? (recommended for testing) (y/N) " staging
if [ "$staging" = "Y" ] || [ "$staging" = "y" ]; then
    STAGING_ARG="--staging"
else
    STAGING_ARG=""
fi

docker compose run --rm --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
    $STAGING_ARG \
    --email $EMAIL \
    --rsa-key-size $RSA_KEY_SIZE \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d $DOMAIN" certbot

echo "Reloading nginx..."
docker compose exec nginx nginx -s reload

echo "============================================"
echo "SSL Certificate setup complete!"
echo "============================================"
echo ""
echo "Your API is now available at:"
echo "  HTTP:  http://$DOMAIN"
echo "  HTTPS: https://$DOMAIN"
echo ""
echo "Certificate will auto-renew via certbot container."

