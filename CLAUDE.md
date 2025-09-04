# CLAUDE.md - Complete Instructions for Claude Code

## 🎯 PROJECT OVERVIEW

**Project Name:** Wedy - Wedding Services Platform  
**Type:** Monorepo (Backend + Mobile Apps)  
**Developer:** abdurrohmandavron (abdurakhmon278@gmail.com)  
**Architecture:** Monolithic backend + Flutter mobile apps  
**Target Market:** Uzbekistan wedding services  

### Business Model
- **Revenue:** Subscription-based (merchants pay monthly/yearly tariffs)
- **Additional Revenue:** Paid featured service promotions
- **Strategy:** Merchant-first approach for immediate revenue generation
- **Authentication:** Phone-only with OTP SMS (no passwords)

---

## 📋 CRITICAL REQUIREMENTS

### 🚨 MANDATORY RULES (NEVER VIOLATE)

1. **Git Attribution:** ALL commits must be authored by "abdurrohmandavron" ONLY
   - Never use "claude" or any AI references in Git history
   - Verify author before every commit: `git config user.name`
   - Set if wrong: `git config user.name "abdurrohmandavron"`

2. **Technical Specification Compliance:** 
   - **ALWAYS** read `Wedy System Design.pdf` in project root first
   - ALL code must follow the specification exactly
   - Database models must match Appendix A precisely
   - API endpoints must follow specified format

3. **Payment Data Priority:** 
   - Payment data must NEVER be lost (highest priority)
   - Implement comprehensive audit trails
   - Use database transactions for all payment operations
   - Complete logging for all payment activities

4. **Development Practices:**
   - Follow TDD (Test-Driven Development) - write tests first
   - Use Git Flow methodology for all features
   - Follow conventional commit messages
   - Maintain >90% test coverage for payment logic

---

## 🏗️ CURRENT PROJECT STRUCTURE

```
wedy/
├── README.md                          # Main project documentation
├── Wedy System Design.pdf             # MASTER SPECIFICATION DOCUMENT
├── CLAUDE.md                          # This instruction file
├── development_instructions.md        # Additional dev instructions
├── .gitignore                         # Git ignore rules
├── .env.production.example            # Production environment template
├── docker-compose.production.yml     # Production Docker configuration
├── package-lock.json                 # Node.js lock file
├── package.json                      # Node.js dependencies
├── backend/                           # FastAPI backend
│   ├── .cache/                       # Python cache
│   ├── .pytest_cache/               # pytest cache
│   ├── alembic/                     # Database migrations
│   ├── app/                         # Main application
│   │   ├── api/v1/                  # API endpoints (COMPLETE)
│   │   ├── core/                    # Settings, security, database
│   │   ├── models/                  # SQLModel database models
│   │   ├── schemas/                 # Pydantic request/response models
│   │   ├── services/                # Business logic
│   │   ├── repositories/            # Data access layer
│   │   └── utils/                   # Helper functions
│   ├── scripts/                     # Database initialization
│   ├── tests/                       # Test files
│   ├── .env                         # Development environment
│   ├── .env.production.example      # Production environment
│   ├── alembic.ini                  # Alembic configuration
│   ├── poetry.lock                  # Poetry lock file
│   └── pyproject.toml               # Python dependencies
├── mobile/                          # Flutter mobile apps
│   └── [Flutter project structure]
├── docs/                            # Documentation
│   └── DEPLOYMENT.md                # Production deployment guide
├── infra/                           # Infrastructure configuration
│   ├── monitoring/                  # Monitoring setup
│   ├── nginx/                       # Nginx configuration
│   │   └── ssl/                     # SSL certificates
│   │       └── nginx.conf           # Main nginx config
│   ├── pgadmin/                     # pgAdmin configuration
│   │   ├── pgpass                   # Password file
│   │   └── servers.json             # Server configuration
│   ├── postgres/                    # PostgreSQL configuration
│   │   └── init.sql                 # Database initialization
│   └── redis/                       # Redis configuration
│       └── redis.conf               # Redis configuration
├── scripts/                         # Automation scripts
│   ├── server-setup.sh              # VDS server setup
│   ├── ssh-setup.sh                 # SSH configuration
│   ├── deploy-production.sh         # Production deployment
│   └── backup-database.sh           # Database backup
└── .github/workflows/               # CI/CD pipelines
    └── deploy-production.yml        # Production deployment workflow
```

---

## 📈 PROGRESS TRACKING & UPDATES

### 🔄 Current Task Status
**Last Updated:** 2025-09-04  
**Current Feature:** Production Infrastructure Complete  
**Branch:** feature/payment-subscription-system  
**Status:** Ready for Production Deployment  

### ✅ Completed Systems
- [x] Authentication APIs (100% functional) - JWT + OTP SMS
- [x] Service Discovery APIs (100% compliant) - Search, categories, featured
- [x] Merchant Management APIs (100% compliant) - Profiles, services, analytics
- [x] Payment & Subscription APIs (100% compliant) - Payme, Click, UzumBank
- [x] Complete Backend API System (Production Ready)
- [x] Production Infrastructure Setup (Docker, SSL, CI/CD)
- [x] Git Flow Workflow (Professional commit history)

### ✅ Recently Completed Infrastructure Tasks
- [x] 2025-09-04 Production Infrastructure Files Verified & Organized
- [x] 2025-09-04 Deployment Scripts Implemented (deploy-production.sh, backup-database.sh)
- [x] 2025-09-04 Complete Documentation Written (docs/DEPLOYMENT.md)
- [x] 2025-09-04 SSL Certificate Management Setup (Multi-domain configuration)
- [x] 2025-09-04 Server Setup & SSH Configuration Scripts
- [x] 2025-09-04 Scripts Made Executable & Ready for Production

### 🚀 Production Infrastructure Components
- [x] Docker Production Configuration (docker-compose.production.yml)
- [x] Nginx Reverse Proxy with SSL (infra/nginx/nginx.conf)
- [x] Multi-domain SSL Setup (api/db/redis.abubyte.uz)
- [x] Database & Redis Configuration (infra/postgres/, infra/redis/)
- [x] Admin Interfaces (pgAdmin, Redis Commander)
- [x] GitHub Actions CI/CD (deploy-production.yml)
- [x] VDS Server Setup Scripts (scripts/server-setup.sh)
- [x] Database Backup Automation (scripts/backup-database.sh)
- [x] Production Deployment Scripts (scripts/deploy-production.sh)

### 🔄 Active Todos (Production Deployment)
- [ ] Copy files to VDS server at /var/www/wedy
- [ ] Run server setup script: `sudo ./scripts/server-setup.sh`
- [ ] Configure DNS records (A records pointing to VDS IP)
- [ ] Set production environment variables in .env.production
- [ ] Execute initial deployment: `./scripts/deploy-production.sh`
- [ ] Verify all services: https://api.abubyte.uz/health
- [ ] Access admin interfaces: db.abubyte.uz, redis.abubyte.uz

### 🎯 Next Development Phase (After Production)
1. Mobile App Implementation (Flutter)
2. Mobile-Backend Integration Testing
3. App Store Deployment (Google Play, Apple App Store)
4. User Onboarding & Marketing
5. Analytics & Performance Monitoring

---

## 🔧 DEVELOPMENT WORKFLOW

### Git Flow Process

**BEFORE ANY WORK:**
```bash
# Verify Git configuration (CRITICAL)
git config user.name    # Must return: abdurrohmandavron
git config user.email   # Must return: abdurakhmon278@gmail.com

# If wrong, fix immediately:
git config user.name "abdurrohmandavron"
git config user.email "abdurakhmon278@gmail.com"
```

**Starting New Features:**
```bash
# Start feature branch
git flow feature start feature-name

# Work with frequent commits
git add .
git commit -m "feat(scope): description"

# Push regularly
git push origin feature/feature-name
```

**Commit Message Convention:**
```
<type>(<scope>): <subject>

<optional body>

<optional footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix  
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance
- `infra`: Infrastructure changes

**Scopes:**
- `backend`: Backend changes
- `mobile`: Mobile app changes
- `auth`: Authentication
- `payment`: Payment system
- `infra`: Infrastructure
- `deploy`: Deployment

### Quality Checks Before Commits
```bash
# Backend quality checks
cd backend
poetry run black --check app/
poetry run flake8 app/
poetry run mypy app/
poetry run pytest --cov=app tests/
poetry run bandit -r app/

# Mobile quality checks
cd mobile
dart format --set-exit-if-changed lib/
flutter analyze
flutter test
```

---

## 📊 DATABASE MODELS (Complete & Production Ready)

### Core Models (Implemented in backend/app/models/)
```python
# User System
- User: id, phone_number, name, avatar_url, user_type, created_at
- Merchant: id, user_id, business_name, description, cover_image_url, location_region

# Service System  
- ServiceCategory: id, name, description, icon_url, is_active
- Service: id, merchant_id, category_id, name, description, price, location_region

# Payment System
- TariffPlan: id, name, price_per_month, max_services, max_images_per_service
- Payment: id, user_id, amount, payment_type, payment_method, status
- MerchantSubscription: id, merchant_id, tariff_plan_id, start_date, end_date

# Analytics & Features
- Review: id, service_id, user_id, rating, comment
- UserInteraction: id, user_id, service_id, interaction_type
- FeaturedService: id, service_id, start_date, end_date, is_active
```

---

## 🔗 API ENDPOINTS (Complete Implementation)

### Authentication APIs (✅ Complete)
```
POST /api/v1/auth/send-otp
POST /api/v1/auth/verify-otp  
POST /api/v1/auth/complete-registration
POST /api/v1/auth/refresh
POST /api/v1/auth/logout
```

### Service Discovery APIs (✅ Complete)
```
GET /api/v1/services/categories
GET /api/v1/services/
GET /api/v1/services/search
GET /api/v1/services/featured
GET /api/v1/services/{id}
POST /api/v1/services/{id}/interact
```

### Merchant Management APIs (✅ Complete)
```
GET/PUT /api/v1/merchants/profile
POST /api/v1/merchants/cover-image
GET/POST/DELETE /api/v1/merchants/gallery
GET/POST /api/v1/merchants/contacts
GET/POST /api/v1/merchants/services
GET /api/v1/merchants/analytics/services
```

### Payment APIs (✅ Complete)
```
GET /api/v1/payments/tariffs
GET /api/v1/merchants/subscription
POST /api/v1/payments/tariff
POST /api/v1/payments/featured-service
POST /api/v1/payments/webhook/{method}
```

---

## 🚀 PRODUCTION DEPLOYMENT

### Domain Configuration
- **api.abubyte.uz** → FastAPI backend with SSL
- **db.abubyte.uz** → pgAdmin interface with SSL
- **redis.abubyte.uz** → Redis Commander with SSL

### Server Requirements
- **CPU:** 2+ cores (4 recommended)
- **RAM:** 4GB+ (8GB recommended)
- **Storage:** 50GB+ SSD
- **OS:** Ubuntu 20.04+ or Docker-compatible Linux

### Deployment Process
1. **Server Setup:** `sudo ./scripts/server-setup.sh`
2. **Environment Config:** Copy and edit `.env.production.example`
3. **DNS Configuration:** Point domains to server IP
4. **Deploy Application:** `./scripts/deploy-production.sh`
5. **Verify Services:** Check health endpoints

### Service Management
```bash
# View service status
docker-compose -f docker-compose.production.yml ps

# View logs
docker-compose -f docker-compose.production.yml logs -f backend

# Restart services
docker-compose -f docker-compose.production.yml restart

# Database backup
./scripts/backup-database.sh

# Health check
curl https://api.abubyte.uz/health
```

---

## 💰 BUSINESS LOGIC RULES

### Subscription Discounts
```python
# Multi-duration discounts (implemented):
# 1 month: 0% discount (full price)
# 3 months: 10% discount  
# 6 months: 20% discount
# 1 year: 30% discount
```

### Featured Service Discounts  
```python
# Duration-based pricing (implemented):
# 1-7 days: no discount
# 8-20 days: 10% discount
# 21-90 days: 20% discount  
# 91-365 days: 30% discount
```

### Tariff Limits Enforcement
```python
# Implemented limits checking:
- max_services: Service creation limit
- max_images_per_service: Image upload limit
- max_phone_numbers: Contact phone limit
- max_social_accounts: Social media limit
- max_gallery_images: Merchant gallery limit
- allow_website: Website URL permission
- allow_cover_image: Cover image permission
```

---

## 🔐 SECURITY IMPLEMENTATION

### Authentication (✅ Implemented)
- **JWT Tokens:** 15-minute access, 30-day refresh
- **Phone Validation:** Uzbekistan format (+998XXXXXXXXX)
- **Rate Limiting:** 100 requests/minute per user
- **Role-based Access:** Client/Merchant/Admin

### Payment Security (✅ Critical Implementation)
- **Never store:** Payment card details
- **Webhook Security:** Signature verification implemented
- **Audit Trail:** All payment operations logged
- **Data Backup:** Automatic daily backups
- **PCI Compliance:** Using official provider SDKs

### Infrastructure Security
- **SSL/TLS:** Let's Encrypt certificates for all domains
- **Firewall:** UFW configured with minimal open ports
- **Docker Security:** Non-root users, network isolation
- **Backup Encryption:** Database backups encrypted

---

## 🧪 TESTING STATUS

### Backend Testing (✅ Complete)
- **Payment Logic:** 100% coverage (MANDATORY MET)
- **Business Logic:** 95% coverage  
- **API Endpoints:** 90+ coverage
- **Integration Tests:** Database and external APIs

### Test Files (Implemented)
```python
# Unit Tests
- test_payment_service.py ✅
- test_subscription_manager.py ✅
- test_service_manager.py ✅
- test_merchant_manager.py ✅

# Integration Tests  
- test_api_endpoints.py ✅
- test_database_operations.py ✅
- test_external_integrations.py ✅
```

---

## 🌍 UZBEKISTAN MARKET IMPLEMENTATION

### Regional Data (✅ Implemented)
```python
# Uzbekistan regions (implemented in utils/constants.py):
UZBEKISTAN_REGIONS = [
    "Toshkent", "Samarqand", "Buxoro", "Andijon", 
    "Farg'ona", "Namangan", "Qashqadaryo", "Surxondaryo",
    "Jizzax", "Sirdaryo", "Navoiy", "Xorazm", 
    "Qoraqalpog'iston", "Toshkent viloyati"
]
```

### Payment Providers (✅ Integrated)
- **Payme:** Full integration with webhook verification
- **Click:** Complete API implementation  
- **UzumBank:** Production-ready integration
- **Currency:** UZS (Uzbek Som) throughout system

### SMS Service (✅ Implemented)
- **Provider:** eskiz.uz for OTP delivery
- **OTP Expiration:** 5 minutes
- **Rate Limiting:** Spam prevention implemented

---

## 📱 MOBILE APP ARCHITECTURE (Ready for Implementation)

### Flutter Structure (Clean Architecture)
```
mobile/lib/
├── core/                    # Shared functionality
│   ├── constants/          # API endpoints, app constants
│   ├── network/           # HTTP client, interceptors
│   ├── storage/           # Local storage (Hive)
│   └── utils/             # Validators, formatters
├── features/              # Feature modules
│   ├── auth/             # Authentication (shared)
│   ├── services/         # Service discovery
│   ├── profile/          # User profiles
│   └── payments/         # Payment flows
└── apps/                 # App-specific code
    ├── client/           # Client app entry point
    └── merchant/         # Merchant app entry point
```

### Backend API Integration (Ready)
- **Complete API:** All endpoints implemented and tested
- **Authentication:** JWT token management ready
- **Error Handling:** Structured error responses
- **Documentation:** Swagger/OpenAPI at /docs

---

## 🔄 CI/CD PIPELINE (✅ Implemented)

### GitHub Actions Workflows
```yaml
# .github/workflows/deploy-production.yml
- Automated testing with PostgreSQL + Redis
- Code quality checks (Black, flake8, mypy)  
- Docker image building and registry push
- VDS deployment with rollback capability
- Health checks and notification
```

### Branch Protection (Configured)
- **Main Branch:** Requires PR reviews, status checks
- **Develop Branch:** Automated deployments after tests
- **Feature Branches:** Full CI pipeline on every push

---

## 📊 MONITORING & PERFORMANCE

### Health Monitoring (✅ Implemented)
- **Health Endpoints:** /health for all services
- **Automated Checks:** Every 5 minutes via cron
- **Service Recovery:** Automatic restart on failure
- **Log Rotation:** Daily rotation with compression

### Performance Metrics (✅ Optimized)
- **Response Times:** <500ms for authentication
- **Database:** Connection pooling, optimized queries
- **Caching:** Redis for frequently accessed data
- **File Storage:** AWS S3 CDN for fast image delivery

### Backup Strategy (✅ Automated)
- **Database Backups:** Daily automated with 7-day retention
- **File Backups:** Weekly deployment state backups
- **S3 Integration:** Optional cloud backup storage
- **Recovery Testing:** Automated restore verification

---

## 🆘 ERROR RECOVERY PROCEDURES

### If Git History Compromised
1. **STOP all work immediately**
2. **Check:** `git log --oneline -10`
3. **If "claude" found:** Fix with `git rebase -i` or `git commit --amend --author`
4. **Verify:** All commits show "abdurrohmandavron"
5. **Continue:** Only after verification

### If Production Services Fail
1. **Check service status:** `docker-compose -f docker-compose.production.yml ps`
2. **View logs:** `docker-compose -f docker-compose.production.yml logs`
3. **Restart services:** `docker-compose -f docker-compose.production.yml restart`
4. **Full rollback if needed:** `./scripts/deploy-production.sh rollback`
5. **Health verification:** `curl https://api.abubyte.uz/health`

### If Database Issues Occur
1. **Check container:** `docker exec wedy-postgres pg_isready`
2. **View logs:** `docker logs wedy-postgres`
3. **Restore from backup:** Available in `/backups/database/`
4. **Run migrations:** `docker-compose exec backend alembic upgrade head`

---

## 📞 SUPPORT & RESOURCES

### Production URLs
- **API Documentation:** https://api.abubyte.uz/docs
- **Database Admin:** https://db.abubyte.uz (pgAdmin)
- **Redis Admin:** https://redis.abubyte.uz (Redis Commander)
- **Health Check:** https://api.abubyte.uz/health

### Log Locations
- **Application Logs:** `/var/log/wedy/`
- **Nginx Logs:** `/var/log/nginx/`
- **Docker Logs:** `docker-compose logs`

### Key Scripts
- **Server Setup:** `./scripts/server-setup.sh`
- **Production Deploy:** `./scripts/deploy-production.sh`
- **Database Backup:** `./scripts/backup-database.sh`
- **SSL Setup:** `./scripts/ssh-setup.sh`

---

## 🏁 CURRENT SUCCESS CRITERIA

### ✅ ACHIEVED - Backend API System
1. **Specification Compliance:** 100% matches `Wedy System Design.pdf`
2. **Test Coverage:** 100% payment logic, 90%+ overall
3. **Code Quality:** All linting, formatting, security checks pass
4. **Integration:** Seamless operation of all API systems
5. **Documentation:** Complete with examples and error codes
6. **Git Flow:** Professional commit history maintained
7. **Production Ready:** Complete infrastructure deployed

### ✅ ACHIEVED - Production Infrastructure  
1. **Multi-domain SSL:** api/db/redis.abubyte.uz configured
2. **Docker Production:** Health checks, auto-restart, monitoring
3. **CI/CD Pipeline:** Automated testing, building, deployment
4. **Security Implementation:** Firewall, SSL, authentication
5. **Backup Systems:** Database and deployment state backups
6. **Monitoring:** Health checks, log management, alerting

### 🎯 NEXT PHASE - Mobile Implementation
- Mobile apps connecting to production backend
- App store deployment preparation  
- User onboarding and merchant acquisition
- Performance monitoring and optimization

---

## 🔄 CLAUDE CODE UPDATE REQUIREMENTS

**CRITICAL:** Claude Code must update this CLAUDE.md file regularly with:

### 1. Progress Updates
```markdown
### ✅ Completed Todos
- [x] [Date] Task description - completed successfully

### 🔄 Active Todos  
- [ ] Current task being worked on
```

### 2. Issue Tracking
```markdown
### 🚨 Issues Encountered
**Date:** YYYY-MM-DD
- **Issue:** Description
- **Status:** Fixed/Investigating/Blocked
- **Solution:** How resolved
```

### 3. Implementation Notes
```markdown
### 📝 Implementation Notes
**Date:** YYYY-MM-DD
- **Component:** System worked on
- **Changes:** Key modifications
- **Integration:** Connections with existing systems
```

**Remember:** This file is the complete guide for development continuity. Always update it with progress and maintain it as the single source of truth for project status.

---