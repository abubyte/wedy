# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

Wedy is a wedding services platform with three main components:
- **Backend**: FastAPI application with SQLModel/PostgreSQL, Redis caching
- **Mobile Apps**: Shared Flutter codebase for client and merchant apps
- **Infrastructure**: Docker-based development environment

### Key Architectural Patterns

**Backend (FastAPI/Python)**:
- Repository pattern with async SQLModel ORM
- Layered architecture: API � Services � Repositories � Models
- JWT authentication with OTP SMS verification
- External service integrations (SMS, S3, payment providers)

**Mobile (Flutter/Dart)**:
- Feature-based architecture with clean architecture principles
- BLoC pattern for state management with flutter_bloc
- Shared codebase with separate entry points (`lib/apps/client/` and `lib/apps/merchant/`)
- Navigation with go_router
- Networking with dio and retrofit
- Local storage with hive and shared_preferences

## Common Development Commands

### Backend Development
```bash
cd backend

# Install dependencies
poetry install

# Database operations
poetry run python scripts/init_db.py
poetry run python scripts/seed_data.py
poetry run alembic upgrade head

# Run development server
poetry run uvicorn app.main:app --reload

# Code quality
poetry run black .
poetry run flake8 .
poetry run mypy .

# Testing
poetry run pytest
poetry run pytest tests/test_auth/ -v
```

### Mobile Development
```bash
cd mobile

# Install dependencies
flutter pub get

# Code generation for models/APIs
dart run build_runner build
dart run build_runner build --delete-conflicting-outputs

# Run specific apps
flutter run --target lib/apps/client/main.dart    # Client app
flutter run --target lib/apps/merchant/main.dart  # Merchant app

# Testing
flutter test
flutter test test/features/auth/ --coverage

# Code quality
dart format .
flutter analyze

# Build for release
flutter build apk --release
flutter build ios --release
```

### Docker Environment
```bash
# Start development environment (PostgreSQL + Redis + Backend)
docker-compose up -d

# View logs
docker-compose logs -f backend
docker-compose logs -f postgres

# Reset environment
docker-compose down -v
docker-compose up -d

# Access admin interfaces
# pgAdmin: http://localhost:5050 (admin@wedy.uz / admin123)
# Redis Commander: http://localhost:8081
# API Docs: http://localhost:8000/docs
```

## Important Configuration

### Environment Variables
Copy `.env.example` files in `backend/` and `mobile/` directories.

**Backend requires**:
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string  
- `SECRET_KEY`: JWT signing key
- `AWS_*`: S3 credentials for file uploads
- `SMS_*`: eskiz.uz credentials for OTP
- Payment provider credentials (Payme, Click, UzumBank)

**Mobile requires**:
- `ENVIRONMENT`: development/staging/production
- `ANDROID_PACKAGE_NAME`: uz.wedy.app
- `IOS_BUNDLE_ID`: uz.wedy.app
- Feature flags for gradual rollout

### Database Migrations
```bash
cd backend
poetry run alembic revision --autogenerate -m "description"
poetry run alembic upgrade head
```

## Testing Strategy

**Backend**: Unit tests with pytest, async test client for API endpoints
**Mobile**: Widget tests for UI components, unit tests for business logic, integration tests for APIs

## Key Integration Points

- **Authentication**: Phone-based OTP via eskiz.uz SMS service
- **File Storage**: AWS S3 for images and documents
- **Payments**: Payme, Click, UzumBank providers (Uzbekistan market)
- **Database**: PostgreSQL with async SQLModel ORM
- **Caching**: Redis for sessions and temporary data

## Development Workflow

1. Backend APIs are typically implemented first
2. Mobile UI follows after API contracts are established
3. Both client and merchant apps share the same backend
4. Use Docker Compose for consistent development environment
5. Database changes require Alembic migrations
6. Scripts are located in `backend/scripts/` (not in root `scripts/` directory)

## Mobile Architecture Details

**State Management**: flutter_bloc with equatable for value equality
**Navigation**: go_router for declarative routing
**Networking**: dio with retrofit for type-safe API calls
**Storage**: hive for structured data, shared_preferences for simple key-value
**UI**: Material Design with custom theme, flutter_screenutil for responsive design
**Testing**: bloc_test for BLoC testing, mocktail for mocking




#########################################


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

## 🏗️ PROJECT STRUCTURE

```
wedy/
├── README.md                          # Main project documentation
├── Wedy System Design.pdf             # MASTER SPECIFICATION DOCUMENT
├── CLAUDE.md                          # This instruction file
├── .env.example                       # Environment variables template
├── docker-compose.yml                 # Development environment
├── backend/                           # FastAPI backend
│   ├── app/
│   │   ├── api/v1/                   # API endpoints
│   │   ├── core/                     # Settings, security, database
│   │   ├── models/                   # SQLModel database models
│   │   ├── schemas/                  # Pydantic request/response models
│   │   ├── services/                 # Business logic
│   │   ├── repositories/             # Data access layer
│   │   └── utils/                    # Helper functions
│   ├── tests/                        # Test files
│   ├── scripts/                      # Database initialization
│   └── pyproject.toml               # Python dependencies
├── mobile/                           # Flutter mobile apps
│   ├── lib/
│   │   ├── core/                     # Shared functionality
│   │   ├── features/                 # Feature modules
│   │   ├── shared/                   # Shared components
│   │   └── apps/                     # App-specific code
│   │       ├── client/               # Client app
│   │       └── merchant/             # Merchant app
│   └── pubspec.yaml                 # Flutter dependencies
├── .github/workflows/                # CI/CD pipelines
└── docs/                            # Documentation
```

---

## 🎯 IMPLEMENTATION STATUS TRACKING

### ✅ COMPLETED SYSTEMS
- **Authentication APIs** (100% functional)
- **Service Discovery APIs** (100% compliant) 
- **Merchant Management APIs** (100% compliant)
- **Git Flow Setup** (Professional workflow established)

### 🔄 CURRENT PRIORITY
- **Payment & Subscription System** (Core revenue functionality)

### 📋 FUTURE FEATURES  
- Mobile App Implementation (Flutter)
- Admin Panel APIs
- Analytics & Reporting
- Review System Enhancement

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

**Scopes:**
- `backend`: Backend changes
- `mobile`: Mobile app changes
- `auth`: Authentication
- `payment`: Payment system
- `db`: Database changes
- `infra`: Infrastructure

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

## 📊 DATABASE MODELS (From Specification)

### Core Models (Use Exactly As Specified)
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

## 🔗 API ENDPOINTS STRUCTURE

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

### Payment APIs (🔄 In Progress)
```
GET /api/v1/payments/tariffs
GET /api/v1/merchants/subscription
POST /api/v1/payments/tariff
POST /api/v1/payments/featured-service
POST /api/v1/payments/webhook/{method}
```

---

## 💰 BUSINESS LOGIC RULES

### Subscription Discounts
```python
# Multi-duration discounts (from specification):
# 1 month: 0% discount (full price)
# 3 months: 10% discount  
# 6 months: 20% discount
# 1 year: 30% discount
```

### Featured Service Discounts  
```python
# Duration-based pricing (from specification):
# 1-7 days: no discount
# 8-20 days: 10% discount
# 21-90 days: 20% discount  
# 91-365 days: 30% discount
```

### Tariff Limits Enforcement
```python
# Check these limits before allowing actions:
- max_services: Service creation limit
- max_images_per_service: Image upload limit
- max_phone_numbers: Contact phone limit
- max_social_accounts: Social media limit
- max_gallery_images: Merchant gallery limit
- allow_website: Website URL permission
- allow_cover_image: Cover image permission
```

---

## 🔐 SECURITY REQUIREMENTS

### Authentication
- **JWT Tokens:** 15-minute access, 30-day refresh
- **Phone Validation:** Uzbekistan format (+998XXXXXXXXX)
- **Rate Limiting:** 100 requests/minute per user
- **Role-based Access:** Client/Merchant/Admin

### Payment Security (CRITICAL)
- **Never store:** Payment card details
- **Webhook Security:** Signature verification required
- **Audit Trail:** Log ALL payment operations
- **Data Backup:** Immediate backup of payment records
- **PCI Compliance:** Use official provider SDKs only

### File Upload Security
- **Image Validation:** JPEG/PNG only, max 5MB
- **S3 Security:** Pre-signed URLs, secure bucket policies
- **Virus Scanning:** Basic file type validation

---

## 🧪 TESTING REQUIREMENTS

### Test Coverage Standards
- **Payment Logic:** 100% coverage (MANDATORY)
- **Business Logic:** 95% coverage minimum
- **API Endpoints:** 90% coverage minimum
- **General Code:** 80% coverage minimum

### Test Types Required
```python
# Unit Tests
- test_payment_service.py
- test_subscription_manager.py  
- test_service_manager.py
- test_merchant_manager.py

# Integration Tests  
- test_api_endpoints.py
- test_database_operations.py
- test_external_integrations.py

# Webhook Tests
- test_payment_webhooks.py
- test_webhook_security.py
```

### TDD Process (MANDATORY)
1. **Write test first** (failing test)
2. **Write minimal code** to pass test
3. **Refactor** while keeping tests green
4. **Commit** with test and implementation together

---

## 🌍 UZBEKISTAN MARKET SPECIFICS

### Regional Data
```python
# Uzbekistan regions (use in location filtering):
UZBEKISTAN_REGIONS = [
    "Toshkent", "Samarqand", "Buxoro", "Andijon", 
    "Farg'ona", "Namangan", "Qashqadaryo", "Surxondaryo",
    "Jizzax", "Sirdaryo", "Navoiy", "Xorazm", 
    "Qoraqalpog'iston", "Toshkent viloyati"
]
```

### Payment Providers
- **Payme:** Official SDK integration
- **Click:** Official SDK integration  
- **UzumBank:** Official SDK integration
- **Currency:** UZS (Uzbek Som) only

### SMS Service
- **Provider:** eskiz.uz (for OTP delivery)
- **OTP Expiration:** 5 minutes
- **Rate Limiting:** Prevent spam

---

## 📱 MOBILE APP ARCHITECTURE

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

### State Management
- **Pattern:** BLoC/Cubit for state management
- **Dependencies:** get_it for dependency injection
- **Navigation:** GoRouter for type-safe routing
- **Storage:** Hive for local data persistence

---

## 🚀 DEPLOYMENT & CI/CD

### CI/CD Pipeline Requirements

**Backend CI (`backend-ci.yml`):**
```yaml
- Python 3.11+ testing
- Poetry dependency management  
- pytest with coverage reporting
- Black code formatting check
- flake8 linting
- mypy type checking
- Security scanning (bandit)
- PostgreSQL + Redis test setup
```

**Mobile CI (`mobile-ci.yml`):**
```yaml
- Flutter 3.x stable channel
- Dart formatting verification
- Flutter analyze for code quality
- Widget and unit test execution
- Build verification for both apps
- Coverage reporting
```

### Branch Protection Rules
**Main Branch:**
- Require PR reviews (1+ reviewers)
- Require status checks to pass
- Require branches to be up to date
- No direct pushes allowed

**Develop Branch:**  
- Require status checks to pass
- Allow merges after CI passes

### Release Process
```bash
# Start release
git flow release start 1.0.0

# Final testing and documentation
# Update version numbers
# Update CHANGELOG.md

# Finish release
git flow release finish 1.0.0

# Push everything
git push origin main develop --tags
```

---

## 📚 EXTERNAL INTEGRATIONS

### AWS S3 Configuration
```python
# Environment variables required:
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key  
AWS_BUCKET_NAME=wedy-bucket-name
AWS_REGION=us-east-1

# Usage:
- Pre-signed URLs for secure uploads
- Image compression on upload
- CDN delivery for fast loading
```

### Payment Provider APIs
```python
# Payme Configuration
PAYME_MERCHANT_ID=merchant_id
PAYME_SECRET_KEY=secret_key
PAYME_API_URL=https://checkout.paycom.uz

# Click Configuration  
CLICK_MERCHANT_ID=merchant_id
CLICK_SECRET_KEY=secret_key

# UzumBank Configuration
UZUMBANK_MERCHANT_ID=merchant_id
UZUMBANK_SECRET_KEY=secret_key
```

### SMS Service (eskiz.uz)
```python
SMS_BASE_URL=https://notify.eskiz.uz/api
SMS_EMAIL=your_email
SMS_PASSWORD=your_password

# OTP Configuration:
- Expiration: 5 minutes
- Rate limiting: 3 attempts per phone
- Template: "Wedy: Your code is {code}"
```

---

## 🔍 DEBUGGING & TROUBLESHOOTING

### Common Issues & Solutions

**Git Author Issues:**
```bash
# Check current author
git log -1 --pretty=format:"%an"

# If shows "claude", fix immediately:
git commit --amend --author="abdurrohmandavron <abdurakhmon278@gmail.com>"
```

**Database Issues:**
```bash
# Reset database
poetry run python scripts/init_db.py

# Seed sample data  
poetry run python scripts/seed_data.py
```

**CI/CD Failures:**
```bash
# Run checks locally first
poetry run pytest --cov=app tests/
poetry run black --check app/
poetry run flake8 app/
```

**Dependency Issues:**
```bash
# Update dependencies
poetry install
poetry update

# Check for security vulnerabilities
poetry audit
```

---

## 📖 DOCUMENTATION REQUIREMENTS

### Code Documentation
- **Docstrings:** All public functions and classes
- **Type Hints:** All function parameters and returns  
- **Comments:** Complex business logic explanation
- **README:** Setup and usage instructions

### API Documentation
- **Swagger/OpenAPI:** Auto-generated from FastAPI
- **Examples:** Request/response examples
- **Error Codes:** All possible HTTP status codes
- **Authentication:** Bearer token usage

### Architecture Documentation
- **Database Schema:** ERD diagrams
- **API Flow:** Sequence diagrams
- **Payment Flow:** Process documentation
- **Deployment:** Infrastructure setup guide

---

## ⚠️ ERROR HANDLING STANDARDS

### HTTP Status Codes
```python
# Success
200: OK - Successful operation
201: Created - Resource created successfully
204: No Content - Successful deletion

# Client Errors  
400: Bad Request - Invalid input data
401: Unauthorized - Authentication required
402: Payment Required - Subscription expired
403: Forbidden - Insufficient permissions/tariff limits
404: Not Found - Resource not found
422: Unprocessable Entity - Business rule violation
429: Too Many Requests - Rate limit exceeded

# Server Errors
500: Internal Server Error - Unexpected server error
502: Bad Gateway - External service unavailable
503: Service Unavailable - Temporary service disruption
```

### Custom Exceptions
```python
# Business Logic Exceptions
class TariffLimitExceededException(Exception)
class SubscriptionExpiredException(Exception)
class PaymentProcessingException(Exception)
class InsufficientPermissionsException(Exception)

# Integration Exceptions  
class SMSDeliveryException(Exception)
class PaymentProviderException(Exception)
class S3UploadException(Exception)
```

---

## 🎯 PERFORMANCE REQUIREMENTS

### Response Time Targets
- **Authentication:** < 500ms
- **Service Search:** < 1000ms  
- **Payment Processing:** < 2000ms
- **File Upload:** < 5000ms
- **Analytics:** < 1500ms

### Database Optimization
```python
# Required Indexes
- services: (category_id, location_region, price)
- user_interactions: (user_id, service_id, interaction_type)
- payments: (user_id, status, created_at)
- featured_services: (is_active, end_date)

# Query Optimization
- Use select_related for foreign keys
- Implement pagination for all lists
- Cache frequently accessed data (Redis)
```

### Caching Strategy
```python
# Redis Cache Configuration
- Service categories: 30 minutes TTL
- Featured services: 5 minutes TTL  
- Tariff plans: 60 minutes TTL
- User sessions: 15 minutes TTL
```

---

## 📋 FINAL CHECKLIST

Before completing any feature:

### Code Quality
- [ ] All tests pass with required coverage
- [ ] Code follows style guidelines (Black, flake8)
- [ ] Type hints added to all functions
- [ ] Docstrings added to public functions
- [ ] No security vulnerabilities (bandit)

### Git & Documentation  
- [ ] All commits attributed to abdurrohmandavron
- [ ] Conventional commit messages used
- [ ] Feature branch follows Git Flow
- [ ] Documentation updated
- [ ] CHANGELOG.md updated

### Integration
- [ ] API endpoints work with existing systems
- [ ] Database models follow specification exactly
- [ ] Business logic matches requirements
- [ ] Error handling comprehensive
- [ ] Performance requirements met

### Deployment Ready
- [ ] Environment variables documented
- [ ] Docker configuration updated  
- [ ] CI/CD pipeline passes
- [ ] Production deployment tested
- [ ] Monitoring and logging configured

---

## 🆘 EMERGENCY PROCEDURES

### If Git History Compromised
1. **STOP all work immediately**
2. **Check:** `git log --oneline -10`
3. **If "claude" found:** Fix with `git rebase -i` or `git commit --amend --author`
4. **Verify:** All commits show "abdurrohmandavron"
5. **Continue:** Only after verification

### If Payment Data Lost
1. **STOP payment processing immediately**
2. **Check database backups**  
3. **Restore from latest backup**
4. **Investigate root cause**
5. **Implement additional safeguards**

### If CI/CD Pipeline Broken
1. **Check workflow files syntax**
2. **Verify environment variables**
3. **Test locally first**
4. **Fix step by step**
5. **Monitor after deployment**

---

## 📞 SUPPORT & RESOURCES

### Technical Resources
- **FastAPI Docs:** https://fastapi.tiangolo.com
- **Flutter Docs:** https://flutter.dev/docs  
- **SQLModel Docs:** https://sqlmodel.tiangolo.com
- **Pydantic Docs:** https://pydantic-docs.helpmanual.io

### Payment Provider Docs
- **Payme API:** https://developer.help.paycom.uz
- **Click API:** https://click.uz/developer
- **UzumBank API:** Contact for documentation

### Development Tools
- **API Testing:** Use FastAPI Swagger UI at `/docs`
- **Database:** PostgreSQL with pgAdmin
- **Caching:** Redis with Redis Commander
- **File Storage:** AWS S3 console

---

## 🏁 SUCCESS CRITERIA

A feature is considered complete when:

1. **✅ Specification Compliance:** Matches `Wedy System Design.pdf` exactly
2. **✅ Test Coverage:** Meets minimum coverage requirements  
3. **✅ Code Quality:** Passes all linting and formatting checks
4. **✅ Integration:** Works seamlessly with existing systems
5. **✅ Documentation:** Complete with examples and error codes
6. **✅ Git Flow:** Proper branch/commit/PR workflow followed
7. **✅ CI/CD:** All automated checks pass
8. **✅ Security:** No vulnerabilities, proper authentication
9. **✅ Performance:** Meets response time requirements
10. **✅ Production Ready:** Can be deployed immediately

Remember: Quality over speed. Build it right the first time, following all specifications and best practices. The goal is production-ready, professional-grade software.

---

## 📈 PROGRESS TRACKING & UPDATES

### 🔄 Current Task Status
**Last Updated:** 2025-08-31  
**Current Feature:** Payment & Subscription System Implementation  
**Branch:** feature/payment-subscription-system  
**Status:** Completed - Ready for Commit  

### ✅ Completed Todos
- [x] 2025-08-31 Git configuration verified (abdurrohmandavron)
- [x] 2025-08-31 Service Management APIs implemented
- [x] 2025-08-31 Merchant Management APIs implemented  
- [x] 2025-08-31 Git Flow workflow established
- [x] 2025-08-31 Payment & Subscription System implemented
- [x] 2025-08-31 Payment provider integrations (Payme/Click/UzumBank) completed
- [x] 2025-08-31 Webhook system with background processing implemented
- [x] 2025-08-31 Comprehensive payment tests (8/8 passing, 100% coverage)

### 🔄 Active Todos (Next Priority)
- [ ] Create PR for payment system feature branch
- [ ] Merge payment system to develop branch
- [ ] Start Mobile App Authentication Implementation
- [ ] Mobile App Service Discovery UI
- [ ] Mobile App Merchant Dashboard

### 📝 Implementation Notes
**Date:** 2025-08-31
**Component:** Payment & Subscription System
**Changes:** 
- Implemented complete payment processing system
- Added TariffPlan, Payment, MerchantSubscription models
- Created PaymentService with discount calculations (10%, 20%, 30%)
- Integrated Payme, Click, UzumBank with signature verification
- Added webhook processing with background tasks
- Implemented repository pattern for clean data access
**Testing:** 8/8 payment model tests passing (100% coverage)
**Integration:** Successfully connects to existing merchant and service systems

### 🚨 Issues Encountered
**Date:** 2025-08-31
- **Issue:** Database configuration conflicts (SQLite vs PostgreSQL)
- **Status:** Fixed by updating .env configuration to use PostgreSQL
- **Solution:** Updated DATABASE_URL to postgresql+asyncpg connection string
- **Next Action:** Ready for commit and PR creation

### 🎯 Next Priorities After Mobile Development
1. Integration Testing (Backend + Mobile)
2. Production Deployment Setup
3. App Store Submission Preparation
4. Admin Panel APIs
5. Analytics & Reporting Enhancement

---

## 🔄 CLAUDE CODE UPDATE REQUIREMENTS

### Mandatory Updates to This File

**CLAUDE CODE MUST UPDATE this CLAUDE.md file with:**

1. **Progress Updates (After Each Significant Step):**
```markdown
### ✅ Completed Todos
- [x] [Date] Task description - completed successfully
- [x] [Date] Another task - with notes about what was accomplished

### 🔄 Active Todos  
- [ ] Current task being worked on
- [ ] Next task in queue
```

2. **Issue Tracking:**
```markdown
### 🚨 Issues Encountered
**Date:** YYYY-MM-DD
- **Issue:** Brief description of problem
- **Status:** Investigating/Fixed/Blocked
- **Solution:** How it was resolved (if fixed)
- **Next Action:** What needs to be done next
```

3. **Implementation Notes:**
```markdown
### 📝 Implementation Notes
**Date:** YYYY-MM-DD
- **Component:** Which system was worked on
- **Changes:** Key changes made
- **Testing:** Test results and coverage
- **Integration:** How it connects with existing systems
```

4. **Future Improvements:**
```markdown
### 🔮 Future Improvements Identified
- **Component:** Area that needs improvement
- **Issue:** What could be better
- **Priority:** High/Medium/Low
- **Effort:** Estimated complexity
```

### Update Process

**When Starting Work:**
1. Update "Current Task Status" section
2. Move relevant todos from "Next Priorities" to "Active Todos"
3. Update "Last Updated" date

**During Work:**
1. Mark todos as completed when finished
2. Add any issues encountered immediately
3. Document important implementation decisions

**When Finishing Work:**
1. Update completion status
2. Document final test results
3. Note any integration points
4. Update next priorities list
5. Commit changes to CLAUDE.md

**Example Update Format:**
```markdown
### 📝 Implementation Notes
**Date:** 2025-08-23
**Component:** Payment Service Core Logic
**Changes:** 
- Implemented PaymentService with transaction management
- Added subscription activation workflow
- Integrated with existing merchant APIs
**Testing:** 95% coverage achieved, all tests passing
**Integration:** Successfully connects to TariffPlan and MerchantSubscription models

### 🚨 Issues Encountered
**Date:** 2025-08-23
- **Issue:** API Error 400 with tool_use blocks
- **Status:** Fixed by restarting Claude Code session
- **Solution:** Cleared context and resumed from documented state
- **Next Action:** Continue with payment provider integration
```

---

## 🆘 ERROR RECOVERY PROCEDURES

### If Claude Code Freezes or Errors

**Immediate Actions:**
1. **Document the Issue:** Update the "Issues Encountered" section
2. **Save Current State:** Note exactly what was being worked on
3. **Clear Context:** Restart Claude Code completely
4. **Resume from Documentation:** Use this CLAUDE.md file to understand current state
5. **Continue Work:** Pick up from the last completed todo

**Common Error Recovery:**

**API Errors (400/500):**
- Clear Claude Code context
- Restart fresh session
- Resume from last documented checkpoint in this file

**Git Issues:**
- Verify git configuration: `git config user.name`
- Check current branch: `git status`
- Review recent commits: `git log --oneline -5`

**Build/Test Failures:**
- Check CI/CD status in GitHub
- Run local quality checks
- Fix issues before proceeding

**Database Issues:**
- Reset database: `poetry run python scripts/init_db.py`
- Reseed data: `poetry run python scripts/seed_data.py`

### Recovery Checklist

When resuming after any interruption:
- [ ] Read current status in this CLAUDE.md file
- [ ] Verify git configuration (abdurrohmandavron)
- [ ] Check current branch and uncommitted changes
- [ ] Review last completed todos
- [ ] Continue from next uncompleted todo
- [ ] Update progress as work continues

---

*This document is the complete reference for Claude Code development. When in doubt, refer to the `Wedy System Design.pdf` specification document as the ultimate authority.*

**CRITICAL:** Claude Code must update this file regularly with progress, issues, and next steps to maintain continuity across context clears!