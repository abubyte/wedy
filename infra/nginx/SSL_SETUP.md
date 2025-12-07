# SSL Certificate Setup Guide

This guide explains how to set up SSL certificates for the Wedy API using Let's Encrypt with Certbot.

## Prerequisites

1. **Domain DNS configured**: Make sure `api.wedy.uz` points to your server's IP address
2. **Ports open**: Ports 80 and 443 must be open in your firewall
3. **Docker and Docker Compose**: Installed and running

## Quick Start

### Option 1: Let's Encrypt (Production - Recommended)

For production use, obtain free SSL certificates from Let's Encrypt:

```bash
# 1. Generate self-signed certificate for default server (required for nginx to start)
./infra/nginx/generate-self-signed.sh

# 2. Edit init-letsencrypt.sh and set your email address
nano infra/nginx/init-letsencrypt.sh
# Change: email="your-email@example.com"

# 3. Start services (nginx will start with dummy certificate)
docker compose up -d

# 4. Run the Let's Encrypt initialization script
./infra/nginx/init-letsencrypt.sh

# 5. Reload nginx to use the new certificates
docker compose exec nginx nginx -s reload
```

### Option 2: Self-Signed Certificate (Development/Testing)

For development or testing purposes:

```bash
# Generate self-signed certificate
./infra/nginx/generate-self-signed.sh

# Copy to domain directory
mkdir -p infra/nginx/ssl/api.wedy.uz
cp infra/nginx/ssl/default/cert.pem infra/nginx/ssl/api.wedy.uz/fullchain.pem
cp infra/nginx/ssl/default/key.pem infra/nginx/ssl/api.wedy.uz/privkey.pem

# Update nginx.conf to use self-signed certs (already configured for Let's Encrypt)
# You may need to modify nginx.conf temporarily to use the self-signed path
```

## Detailed Setup

### Step 1: Configure DNS

Ensure your domain `api.wedy.uz` has an A record pointing to your server's public IP:

```
Type: A
Name: api
Value: YOUR_SERVER_IP
TTL: 300
```

### Step 2: Configure Firewall

Open ports 80 (HTTP) and 443 (HTTPS):

```bash
# UFW example
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Or iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

### Step 3: Generate Self-Signed Certificate (Default Server)

This is required for nginx to start before Let's Encrypt certificates are obtained:

```bash
./infra/nginx/generate-self-signed.sh
```

### Step 4: Start Services

Start Docker Compose services:

```bash
docker compose up -d
```

Verify nginx is running:

```bash
docker compose ps nginx
```

### Step 5: Obtain Let's Encrypt Certificate

1. **Edit the initialization script**:

```bash
nano infra/nginx/init-letsencrypt.sh
```

Update the email address:
```bash
email="your-email@example.com"  # Change this
```

2. **Run the initialization script**:

```bash
./infra/nginx/init-letsencrypt.sh
```

This script will:
- Create necessary directories
- Download recommended TLS parameters
- Start nginx with a dummy certificate
- Request a real certificate from Let's Encrypt
- Reload nginx with the new certificate

### Step 6: Verify SSL Certificate

Check if the certificate was obtained successfully:

```bash
# Check certificate files
ls -la infra/nginx/certbot/conf/live/api.wedy.uz/

# Test SSL connection
openssl s_client -connect api.wedy.uz:443 -servername api.wedy.uz
```

### Step 7: Test HTTPS Access

```bash
# Test from command line
curl -I https://api.wedy.uz/health

# Test in browser
# Visit: https://api.wedy.uz/health
```

## Automatic Certificate Renewal

The `certbot` service in `docker-compose.yml` automatically renews certificates every 12 hours:

```yaml
certbot:
  image: certbot/certbot:latest
  entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"
```

Certificates are valid for 90 days, and Let's Encrypt recommends renewing when they have 30 days left. The automatic renewal handles this.

To manually renew:

```bash
docker compose run --rm certbot renew
docker compose exec nginx nginx -s reload
```

## Troubleshooting

### Nginx fails to start

**Problem**: Nginx can't find SSL certificates

**Solution**: Generate the self-signed certificate first:
```bash
./infra/nginx/generate-self-signed.sh
```

### Let's Encrypt certificate request fails

**Common issues**:

1. **DNS not configured**: Verify DNS with `dig api.wedy.uz` or `nslookup api.wedy.uz`
2. **Port 80 blocked**: Check firewall rules
3. **Domain already has certificate**: Use `--force-renewal` flag
4. **Rate limiting**: Let's Encrypt has rate limits. Use `--staging` flag for testing

**Staging mode** (for testing):

Edit `init-letsencrypt.sh`:
```bash
staging=1  # Enable staging mode
```

### Certificate renewal fails

Check certbot logs:
```bash
docker compose logs certbot
```

Manually test renewal:
```bash
docker compose run --rm certbot renew --dry-run
```

### Mixed content warnings

If your API returns HTTP URLs, update `BASE_URL` in `.env`:
```bash
BASE_URL=https://api.wedy.uz
```

## File Structure

```
infra/nginx/
├── nginx.conf              # Main nginx configuration
├── ssl/
│   ├── api.wedy.uz/     # Domain SSL directory (not used with Let's Encrypt)
│   └── default/            # Self-signed certificate for default server
│       ├── cert.pem
│       └── key.pem
├── certbot/
│   ├── www/                # Webroot for ACME challenge
│   └── conf/               # Let's Encrypt certificates
│       ├── live/
│       │   └── api.wedy.uz/
│       │       ├── fullchain.pem
│       │       └── privkey.pem
│       ├── options-ssl-nginx.conf
│       └── ssl-dhparams.pem
├── init-letsencrypt.sh     # Script to obtain Let's Encrypt certificates
└── generate-self-signed.sh # Script to generate self-signed certificates
```

## Security Notes

1. **Let's Encrypt certificates**: Valid for 90 days, automatically renewed
2. **Self-signed certificates**: Only for default server catch-all, not for production API
3. **HTTPS redirect**: HTTP (port 80) automatically redirects to HTTPS (port 443)
4. **Security headers**: Configured in nginx.conf (HSTS, X-Frame-Options, etc.)

## Production Checklist

- [ ] DNS A record configured
- [ ] Ports 80 and 443 open in firewall
- [ ] Self-signed certificate generated for default server
- [ ] Let's Encrypt certificate obtained successfully
- [ ] HTTPS access verified
- [ ] Certificate auto-renewal tested
- [ ] BASE_URL updated to HTTPS
- [ ] CORS origins updated if needed

## Support

For issues with Let's Encrypt: https://letsencrypt.org/docs/
For Certbot documentation: https://certbot.eff.org/docs/

