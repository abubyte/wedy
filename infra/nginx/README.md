# Nginx Configuration with SSL

This directory contains the Nginx reverse proxy configuration with SSL support using Let's Encrypt.

## Quick Start

1. **Generate self-signed certificate** (required for nginx to start):
   ```bash
   ./generate-self-signed.sh
   ```

2. **Start services**:
   ```bash
   docker compose up -d
   ```

3. **Obtain Let's Encrypt certificate**:
   ```bash
   # Edit init-letsencrypt.sh and set your email
   nano init-letsencrypt.sh
   
   # Run the initialization
   ./init-letsencrypt.sh
   ```

## Files

- `nginx.conf` - Main Nginx configuration
- `init-letsencrypt.sh` - Script to obtain Let's Encrypt SSL certificates
- `generate-self-signed.sh` - Script to generate self-signed certificates for development
- `SSL_SETUP.md` - Detailed SSL setup documentation

## Architecture

```
Internet → Nginx (Port 80/443) → Backend (Port 8000)
                ↓
            Certbot (Auto-renewal)
```

## Domain Configuration

The default domain is `api.wedy.uz`. To change it:

1. Update `nginx.conf` - replace all instances of `api.wedy.uz`
2. Update `init-letsencrypt.sh` - change the `domains` array
3. Update `docker-compose.yml` - if needed for any domain-specific configs

## See Also

- [SSL_SETUP.md](./SSL_SETUP.md) - Complete SSL setup guide
- [../../docker-compose.yml](../../docker-compose.yml) - Docker Compose configuration

