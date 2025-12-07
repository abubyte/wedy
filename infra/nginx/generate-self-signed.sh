#!/bin/bash

# Script to generate self-signed SSL certificate for default server
# This is used as a fallback for the default nginx server

set -e

SSL_DIR="./infra/nginx/ssl/default"
DOMAIN="localhost"

mkdir -p "$SSL_DIR"

echo "Generating self-signed certificate for $DOMAIN..."

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$SSL_DIR/key.pem" \
  -out "$SSL_DIR/cert.pem" \
  -subj "/C=UZ/ST=Tashkent/L=Tashkent/O=Wedy/CN=$DOMAIN"

echo "Self-signed certificate generated:"
echo "  Certificate: $SSL_DIR/cert.pem"
echo "  Private Key: $SSL_DIR/key.pem"
echo ""
echo "Note: This is a self-signed certificate for development/testing."
echo "For production, use Let's Encrypt certificates."

