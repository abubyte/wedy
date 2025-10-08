# Production Deployment Guide - Wedy Wedding Services Platform

## Overview

This guide covers the complete production deployment of the Wedy platform on a VDS (Virtual Dedicated Server) with multi-domain SSL configuration for:

- **api.abubyte.uz** - Main API backend
- **db.abubyte.uz** - Database administration (pgAdmin)
- **redis.abubyte.uz** - Redis administration (Redis Commander)

## Prerequisites

### Server Requirements

**Minimum Specifications:**
- CPU: 2 cores (4 cores recommended)
- RAM: 4GB (8GB recommended) 
- Storage: 50GB SSD (100GB recommended)
- OS: Ubuntu 20.04+ or compatible Linux distribution
- Network: Public IP with ports 80, 443 accessible

### Domain Configuration

Before deployment, ensure your DNS records point to your VDS server:

```bash
# DNS Records (A Records)
api.abubyte.uz      -> YOUR_SERVER_IP
db.abubyte.uz       -> YOUR_SERVER_IP  
redis.abubyte.uz    -> YOUR_SERVER_IP
```

### Required Access

- Root SSH access to your VDS server
- GitHub repository access for CI/CD
- Domain control for SSL certificate generation

## Step 1: Initial Server Setup

### 1.1 Connect to Your Server

```bash
# Connect via SSH
ssh root@YOUR_SERVER_IP

# Update system packages
apt update && apt upgrade -y
```

### 1.2 Run Automated Server Setup

```bash
# Download and execute the server setup script
wget https://raw.githubusercontent.com/abubyte/wedy/main/scripts/server-setup.sh
chmod +x server-setup.sh

# Run setup (this will take 10-15 minutes)
./server-setup.sh
```

**The setup script will:**
- Install Docker and Docker Compose
- Create deployment user
- Configure firewall (UFW)
- Generate SSL certificates
- Setup automatic certificate renewal
- Configure backup automation
- Setup monitoring and health checks

### 1.3 Verify Setup

```bash
# Check Docker installation
docker --version
docker-compose --version

# Check services
systemctl status docker
ufw status

# Verify user creation
id deploy
```

## Step 2: Project Deployment

### 2.1 Switch to Deployment User

```bash
# Switch to deploy user
su - deploy
cd /var/www/wedy
```

### 2.2 Clone Repository

```bash
# Clone the repository
git clone https://github.com/abubyte/wedy.git .

# Checkout main branch
git checkout main
```

### 2.3 Configure Environment

```bash
# Copy and edit production environment
cp .env.production.example .env.production

# Edit with your production values
nano .env.production
```

**Required Environment Variables:**

```bash
# Security (Generate strong keys)
SECRET_KEY=your-super-secure-secret-key-min-32-chars
JWT_SECRET_KEY=your-jwt-secret-key-different-from-main

# Database
POSTGRES_DB=wedy_production
POSTGRES_USER=wedy_user
POSTGRES_PASSWORD=your-super-secure-database-password

# Admin Interfaces
PGADMIN_EMAIL=admin@abubyte.uz
PGADMIN_PASSWORD=your-pgadmin-password
REDIS_COMMANDER_USER=admin
REDIS_COMMANDER_PASSWORD=your-redis-commander-password

# AWS S3
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
AWS_BUCKET_NAME=wedy-production-bucket

# SMS Service
ESKIZ_EMAIL=your-eskiz-email@example.com
ESKIZ_PASSWORD=your-eskiz-password

# Payment Providers
PAYME_MERCHANT_ID=your-payme-merchant-id
PAYME_SECRET_KEY=your-payme-secret-key
CLICK_MERCHANT_ID=your-click-merchant-id
CLICK_SECRET_KEY=your-click-secret-key
UZUMBANK_MERCHANT_ID=your-uzumbank-merchant-id
UZUMBANK_SECRET_KEY=your-uzumbank-secret-key

# SSL
SSL_EMAIL=admin@abubyte.uz
```

## Step 3: Initial Deployment

### 3.1 Run Initial Deployment

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run the deployment script
./scripts/deploy-production.sh
```

**Deployment Process:**
1. Creates backup of current state
2. Pulls latest Docker images
3. Starts all services with health checks
4. Runs database migrations
5. Verifies deployment health
6. Cleans up old resources

### 3.2 Verify Services

```bash
# Check service status
docker-compose -f docker-compose.production.yml ps

# All services should show "Up" status:
# - wedy-nginx (80, 443)
# - wedy-postgres (internal)
# - wedy-redis (internal)
# - wedy-backend (internal)
# - wedy-pgadmin (internal)
# - wedy-redis-commander (internal)
```

## Step 4: SSL Certificate Verification

### 4.1 Check Certificate Status

```bash
# Check SSL certificates
sudo certbot certificates

# Should show certificates for:
# - api.abubyte.uz
# - db.abubyte.uz  
# - redis.abubyte.uz
```

### 4.2 Test SSL Connections

```bash
# Test API endpoint
curl -I https://api.abubyte.uz/health

# Should return: HTTP/2 200

# Test admin interfaces (may require authentication)
curl -I https://db.abubyte.uz
curl -I https://redis.abubyte.uz
```

## Step 5: Access Services

### 5.1 API Documentation

**URL:** https://api.abubyte.uz/docs  
**Description:** Interactive Swagger/OpenAPI documentation  
**Authentication:** Bearer token required for protected endpoints

### 5.2 Database Administration

**URL:** https://db.abubyte.uz  
**Login:** Use PGADMIN_EMAIL and PGADMIN_PASSWORD from .env.production  
**Purpose:** PostgreSQL database management  

**Pre-configured server connection:**
- Name: Wedy Production
- Host: postgres
- Port: 5432
- Database: wedy_production
- Username: wedy_user

### 5.3 Redis Administration

**URL:** https://redis.abubyte.uz  
**Login:** Use REDIS_COMMANDER_USER and REDIS_COMMANDER_PASSWORD  
**Purpose:** Redis cache management and monitoring

## Step 6: Configure CI/CD (Optional)

### 6.1 GitHub Secrets

Add these secrets to your GitHub repository:

```bash
VDS_HOST=YOUR_SERVER_IP
VDS_USER=deploy
VDS_SSH_KEY=<contents of deploy user's private SSH key>
VDS_SSH_PORT=22
GITHUB_TOKEN=<GitHub token for container registry>
```

### 6.2 Enable Automated Deployment

The included GitHub Actions workflow (`.github/workflows/deploy-production.yml`) will:
- Run tests on every push to main
- Build and push Docker images
- Deploy to production automatically
- Perform health checks
- Rollback on failure

## Step 7: Monitoring and Maintenance

### 7.1 Health Monitoring

**Automated health checks run every 5 minutes:**
```bash
# View health check logs
tail -f /var/log/wedy/health-check.log

# Manual health check
./scripts/deploy-production.sh health
```

### 7.2 Database Backups

**Automated daily backups:**
```bash
# View backup status
ls -la /backups/database/

# Manual backup
./scripts/backup-database.sh

# Restore from backup (if needed)
docker exec -i wedy-postgres psql -U wedy_user -d wedy_production < /backups/database/backup_file.sql.gz
```

### 7.3 Log Management

**View service logs:**
```bash
# Backend application logs
docker-compose -f docker-compose.production.yml logs -f backend

# Nginx access/error logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# All services
docker-compose -f docker-compose.production.yml logs -f
```

### 7.4 Service Management

**Common maintenance commands:**
```bash
# Restart all services
docker-compose -f docker-compose.production.yml restart

# Restart specific service
docker-compose -f docker-compose.production.yml restart backend

# Update to latest code
./scripts/deploy-production.sh

# Rollback to previous version
./scripts/deploy-production.sh rollback

# View resource usage
docker stats
```

## Step 8: Security Considerations

### 8.1 Access Control

**Admin interfaces are public but password-protected:**
- Consider restricting access by IP if needed
- Use strong passwords for admin accounts
- Regularly rotate credentials

**To restrict admin access by IP:**
```nginx
# Edit /infra/nginx/nginx.conf
location / {
    allow 192.168.1.0/24;  # Your office network
    allow YOUR_IP_ADDRESS;  # Your personal IP
    deny all;
    
    proxy_pass http://wedy_pgadmin;
    # ... rest of configuration
}
```

### 8.2 Firewall Status

```bash
# Check firewall rules
sudo ufw status numbered

# Should show:
# 22/tcp (SSH)
# 80/tcp (HTTP)  
# 443/tcp (HTTPS)
```

### 8.3 Security Updates

```bash
# Regular system updates
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker-compose -f docker-compose.production.yml pull
./scripts/deploy-production.sh
```

## Troubleshooting

### Common Issues

**1. Services Won't Start**
```bash
# Check Docker daemon
sudo systemctl status docker

# Check system resources
df -h
free -m
htop

# Restart Docker
sudo systemctl restart docker
```

**2. SSL Certificate Issues**
```bash
# Check certificate status
sudo certbot certificates

# Manual renewal
sudo certbot renew

# Check DNS records
dig api.abubyte.uz
nslookup db.abubyte.uz
```

**3. Database Connection Issues**
```bash
# Check PostgreSQL container
docker exec wedy-postgres pg_isready -U wedy_user

# View PostgreSQL logs
docker logs wedy-postgres

# Restart database
docker-compose -f docker-compose.production.yml restart postgres
```

**4. High Resource Usage**
```bash
# Monitor resources
docker stats
htop

# Check log sizes
du -sh /var/log/*
du -sh /var/lib/docker/*

# Clean up
docker system prune -af
```

### Emergency Procedures

**1. Complete Service Recovery**
```bash
cd /var/www/wedy
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml up -d
```

**2. Database Recovery**
```bash
# Stop services
docker-compose -f docker-compose.production.yml down

# Restore from backup
docker-compose -f docker-compose.production.yml up -d postgres
sleep 30
docker exec -i wedy-postgres psql -U wedy_user -d wedy_production < /backups/database/latest_backup.sql.gz

# Start all services
docker-compose -f docker-compose.production.yml up -d
```

**3. Rollback Deployment**
```bash
./scripts/deploy-production.sh rollback
```

## Performance Optimization

### Database Optimization

**Monitor database performance:**
```bash
# Connect to database
docker exec -it wedy-postgres psql -U wedy_user -d wedy_production

# Check slow queries
SELECT query, mean_time, calls FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;

# Check database size
SELECT pg_database_size('wedy_production');
```

### Redis Monitoring

Access Redis Commander at https://redis.abubyte.uz to monitor:
- Memory usage
- Key statistics  
- Slow queries
- Connection metrics

### Nginx Performance

**Monitor web server:**
```bash
# Check connection stats
sudo tail -f /var/log/nginx/access.log | grep -E "(POST|GET|PUT|DELETE)"

# Monitor response times
sudo tail -f /var/log/nginx/access.log | awk '{print $4 " " $7 " " $10}'
```

## Scaling Considerations

### Horizontal Scaling

**Current setup supports:**
- Multiple backend containers
- Load balancing via Nginx
- Database read replicas (future)

**To scale backend services:**
```bash
# Edit docker-compose.production.yml
# Add multiple backend instances
# Configure load balancing in nginx.conf
```

### Vertical Scaling

**Monitor resource usage and upgrade server:**
- CPU utilization
- Memory consumption  
- Disk I/O
- Network bandwidth

## Support and Contacts

**Repository:** https://github.com/abubyte/wedy  
**Documentation:** https://api.abubyte.uz/docs  
**Health Check:** https://api.abubyte.uz/health  

**Log Locations:**
- Application: `/var/log/wedy/`
- Nginx: `/var/log/nginx/`
- Docker: `docker-compose logs`

**Backup Locations:**
- Database: `/backups/database/`
- Deployments: `/backups/deployments/`
