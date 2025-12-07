#!/bin/bash

# Script to check HTTPS status and diagnose issues

set -e

DOMAIN="api.wedy.uz"
CERT_PATH="./infra/nginx/certbot/conf/live/$DOMAIN"

echo "=== HTTPS Status Check for $DOMAIN ==="
echo ""

# Check if certificates exist
echo "1. Checking SSL certificates..."
if [ -f "$CERT_PATH/fullchain.pem" ] && [ -f "$CERT_PATH/privkey.pem" ]; then
    echo "   ✅ Certificates found at: $CERT_PATH"
    
    # Check certificate details
    if command -v openssl &> /dev/null; then
        echo ""
        echo "   Certificate details:"
        openssl x509 -in "$CERT_PATH/fullchain.pem" -noout -subject -dates 2>/dev/null || echo "   ⚠️  Could not read certificate details"
    fi
else
    echo "   ❌ Certificates NOT found at: $CERT_PATH"
    echo ""
    echo "   Run: ./infra/nginx/create-dummy-cert.sh"
    echo "   Then: ./infra/nginx/init-letsencrypt.sh (for real certificates)"
fi

echo ""
echo "2. Checking nginx status..."
if docker compose ps nginx | grep -q "Up"; then
    echo "   ✅ Nginx is running"
else
    echo "   ❌ Nginx is not running"
    echo "   Run: docker compose ps nginx"
fi

echo ""
echo "3. Checking port 443..."
if docker compose exec nginx netstat -tuln 2>/dev/null | grep -q ":443"; then
    echo "   ✅ Nginx is listening on port 443"
else
    echo "   ⚠️  Nginx might not be listening on port 443"
    echo "   Check: docker compose logs nginx"
fi

echo ""
echo "4. Checking DNS..."
DNS_IP=$(dig +short $DOMAIN | tail -1)
if [ -n "$DNS_IP" ]; then
    echo "   ✅ DNS resolved: $DOMAIN → $DNS_IP"
else
    echo "   ⚠️  DNS not configured or not propagated"
    echo "   Configure A record: $DOMAIN → Your server IP"
fi

echo ""
echo "5. Testing HTTP connection..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN/health 2>/dev/null || echo "000")
if [ "$HTTP_STATUS" = "301" ] || [ "$HTTP_STATUS" = "200" ]; then
    echo "   ✅ HTTP is working (status: $HTTP_STATUS)"
else
    echo "   ⚠️  HTTP returned status: $HTTP_STATUS"
fi

echo ""
echo "6. Testing HTTPS connection..."
HTTPS_STATUS=$(curl -s -k -o /dev/null -w "%{http_code}" https://$DOMAIN/health 2>/dev/null || echo "000")
if [ "$HTTPS_STATUS" = "200" ]; then
    echo "   ✅ HTTPS is working (status: $HTTPS_STATUS)"
elif [ "$HTTPS_STATUS" = "000" ]; then
    echo "   ❌ HTTPS connection failed"
    echo "   Possible issues:"
    echo "   - Port 443 not open in firewall"
    echo "   - SSL certificates missing"
    echo "   - Nginx not configured for HTTPS"
else
    echo "   ⚠️  HTTPS returned status: $HTTPS_STATUS"
fi

echo ""
echo "=== Summary ==="
if [ "$HTTPS_STATUS" = "200" ]; then
    echo "✅ HTTPS is working correctly!"
else
    echo "❌ HTTPS needs to be configured"
    echo ""
    echo "Next steps:"
    echo "1. Create certificates: ./infra/nginx/create-dummy-cert.sh"
    echo "2. Get real certificates: ./infra/nginx/init-letsencrypt.sh"
    echo "3. Check firewall: sudo ufw allow 443/tcp"
fi

