# Wedy Platform

<div align="center">

**A comprehensive wedding services platform connecting couples with service providers in Uzbekistan**

[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green.svg)](https://fastapi.tiangolo.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.9+-blue.svg)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7-red.svg)](https://redis.io/)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Quick Start](#quick-start)
  - [Backend Setup](#backend-setup)
  - [Mobile App Setup](#mobile-app-setup)
- [Development](#development)
- [Testing](#testing)
- [API Documentation](#api-documentation)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Overview

**Wedy** is a full-stack platform designed to streamline wedding planning in Uzbekistan. It connects engaged couples (clients) with local wedding service providers (merchants) through two mobile applications and a robust backend API.

### Key Highlights

- 🌍 **Local Focus**: Built specifically for the Uzbekistan market with UZS currency support
- 💰 **Revenue Model**: Subscription-based tariff system for merchants with featured service promotions
- 📱 **Dual Apps**: Separate Flutter applications for clients and merchants
- 🔐 **Secure**: Phone-based OTP authentication, JWT tokens, and secure payment processing
- 🚀 **Production-Ready**: Comprehensive test coverage, error handling, and monitoring

### Business Model

- **Client App**: Free discovery platform for couples to find wedding services
- **Merchant App**: Subscription-based platform for service providers with:
  - Multiple tariff plans (Basic, Standard, Premium)
  - Featured service promotions
  - Analytics dashboard
  - Service management tools

---

## 🏗️ Architecture

The platform consists of three main components:

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Mobile App                        │
│                    (Flutter - Discovery)                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ HTTPS/REST API
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                    Backend API (FastAPI)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Auth &   │  │ Service  │  │ Payment  │  │Analytics │   │
│  │  Users   │  │  Mgmt    │  │  System  │  │          │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │PostgreSQL│  │  Redis   │  │   S3     │                  │
│  │ Database │  │   Cache  │  │  Storage │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ HTTPS/REST API
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  Merchant Mobile App                         │
│                (Flutter - Business Mgmt)                     │
└─────────────────────────────────────────────────────────────┘
```

---

## ✨ Features

### Authentication & User Management
- ✅ Phone-based authentication with OTP SMS verification (via Eskiz.uz)
- ✅ JWT token-based authentication (access + refresh tokens)
- ✅ User profile management with avatar uploads
- ✅ Role-based access control (Client, Merchant, Admin)
- ✅ Soft delete for account deactivation

### Service Management
- ✅ Dynamic service categories managed by admin
- ✅ Service CRUD operations with image uploads (S3)
- ✅ Advanced search and filtering (by category, price, location)
- ✅ Featured services system with duration-based pricing
- ✅ Service interactions (view, like, save, share)
- ✅ Service analytics and popularity metrics

### Merchant Management
- ✅ Comprehensive merchant profiles (avatar, cover, gallery)
- ✅ Contact management (phone numbers, social media)
- ✅ Location and geolocation support
- ✅ Service management within tariff limits
- ✅ Analytics dashboard with real-time metrics
- ✅ Subscription management and tariff enforcement

### Review & Rating System
- ✅ Review creation, updates, and deletion
- ✅ Star rating system (1-5 stars)
- ✅ Service rating aggregation
- ✅ Review listing with pagination

### Payment System
- ✅ Multiple payment providers:
  - ✅ **Payme** (fully integrated)
  - ✅ **Click** (integrated, requires credentials)
  - ⚠️ **UzumBank** (planned)
- ✅ Tariff subscription payments with duration discounts
- ✅ Featured service payment processing
- ✅ Webhook handling for payment confirmations
- ✅ Transaction logging and status tracking

### Tariff & Subscription
- ✅ Dynamic tariff plan management (CRUD)
- ✅ Multi-duration pricing (1, 3, 6, 12 months)
- ✅ Automatic discount calculation
- ✅ Usage limit enforcement (services, images, contacts, etc.)
- ✅ Subscription expiration handling
- ✅ Subscription status tracking

### Analytics
- ✅ Service interaction tracking (views, likes, saves, shares)
- ✅ Daily progress calculation for merchants
- ✅ Dashboard metrics aggregation
- ✅ Per-service analytics
- ✅ Overall rating calculations
- ✅ Featured services performance tracking

---

## 🛠️ Tech Stack

### Backend
- **Framework**: [FastAPI](https://fastapi.tiangolo.com/) 0.104+
- **Language**: Python 3.11+
- **ORM**: [SQLModel](https://sqlmodel.tiangolo.com/) with SQLAlchemy
- **Database**: PostgreSQL 15 with asyncpg
- **Cache**: Redis 7
- **Storage**: AWS S3 (via boto3)
- **SMS**: Eskiz.uz API integration
- **Authentication**: JWT (python-jose)
- **Migrations**: Alembic
- **Testing**: pytest, pytest-asyncio
- **Package Manager**: Poetry

### Mobile
- **Framework**: [Flutter](https://flutter.dev/) 3.9+
- **Language**: Dart
- **State Management**: BLoC (flutter_bloc)
- **Navigation**: go_router
- **Networking**: Dio with Retrofit
- **Local Storage**: Hive, SharedPreferences
- **Image Handling**: cached_network_image, image_picker
- **Maps**: google_maps_flutter (for geolocation)

### Infrastructure
- **Containerization**: Docker & Docker Compose
- **Web Server**: Nginx (for production)
- **CI/CD**: (To be configured)

---

## 📁 Project Structure

```
wedy/
├── backend/                    # Backend API (FastAPI)
│   ├── app/
│   │   ├── api/               # API endpoints
│   │   │   └── v1/            # API version 1
│   │   ├── core/              # Core functionality
│   │   │   ├── config.py      # Configuration
│   │   │   ├── database.py    # Database setup
│   │   │   ├── exceptions.py  # Custom exceptions
│   │   │   └── security.py    # Security utilities
│   │   ├── models/            # SQLModel models
│   │   ├── repositories/      # Data access layer
│   │   ├── schemas/           # Pydantic schemas
│   │   ├── services/          # Business logic
│   │   ├── utils/             # Utility functions
│   │   └── main.py            # Application entry
│   ├── alembic/               # Database migrations
│   ├── scripts/               # Utility scripts
│   ├── tests/                 # Test suite
│   ├── Dockerfile             # Docker configuration
│   ├── pyproject.toml         # Poetry dependencies
│   └── README.md              # Backend-specific docs
│
├── mobile/                     # Flutter mobile app
│   ├── lib/
│   │   ├── apps/              # App-specific code
│   │   │   ├── client/        # Client app
│   │   │   └── merchant/      # Merchant app
│   │   ├── core/              # Core functionality
│   │   │   ├── api/           # API client
│   │   │   ├── bloc/          # BLoC state management
│   │   │   ├── models/        # Data models
│   │   │   ├── repositories/  # Repository pattern
│   │   │   ├── services/      # Services
│   │   │   └── utils/         # Utilities
│   │   ├── features/          # Feature modules
│   │   └── shared/            # Shared components
│   ├── android/               # Android configuration
│   ├── ios/                   # iOS configuration
│   ├── scripts/               # Build scripts
│   └── pubspec.yaml           # Flutter dependencies
│
├── infra/                      # Infrastructure
│   └── nginx/                 # Nginx configuration
│
├── docs/                       # Documentation
│   ├── CURRENT_STATUS.md      # Current development status
│   ├── PRODUCTION_PLAN.md     # Production roadmap
│   └── README.md              # Documentation index
│
├── docker-compose.yml          # Docker Compose setup
└── README.md                   # This file
```

---

## 🚀 Getting Started

### Prerequisites

#### Backend
- **Python** 3.11 or higher
- **Poetry** (package manager)
- **PostgreSQL** 15 or higher
- **Redis** 7 or higher
- **AWS Account** (for S3 storage)
- **Eskiz.uz Account** (for SMS service)

#### Mobile
- **Flutter SDK** 3.9 or higher
- **Dart** 3.0 or higher
- **Android Studio** / **Xcode** (for mobile development)
- **CocoaPods** (for iOS - installed via Flutter)

#### Infrastructure
- **Docker** 20.10 or higher
- **Docker Compose** 2.0 or higher

---

### Quick Start

The fastest way to get started is using Docker Compose:

```bash
# Clone the repository
git clone <repository-url>
cd wedy

# Copy environment file
cp backend/.env.example backend/.env

# Edit backend/.env with your configuration
# (See Backend Setup for required variables)

# Start all services
docker-compose up -d

# Run database migrations
docker-compose exec backend poetry run alembic upgrade head

# Seed initial data (optional)
# First, ensure dependencies are installed:
docker compose exec backend poetry install

# Then run the seed script:
docker compose exec backend poetry run python scripts/seed_data.py --all
```

The API will be available at `http://localhost:8000`

API Documentation (when enabled): `http://localhost:8000/docs`

---

### Backend Setup

#### 1. Install Dependencies

```bash
cd backend

# Install Poetry (if not installed)
pip install poetry

# Install project dependencies
poetry install
```

#### 2. Environment Configuration

Create a `.env` file in the `backend/` directory:

```bash
cp .env.example .env
```

Required environment variables:

```env
# Application
DEBUG=True
APP_NAME=Wedy API
APP_VERSION=1.0.0
BASE_URL=http://localhost:8000
API_V1_STR=/api/v1

# Database
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/wedy_db

# Redis
REDIS_URL=redis://localhost:6379/0

# Security
SECRET_KEY=your-secret-key-here  # Generate with: openssl rand -hex 32
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=30

# SMS Service (Eskiz.uz)
ESKIZ_EMAIL=your-email@example.com
ESKIZ_PASSWORD=your-password

# AWS S3
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_BUCKET_NAME=wedy-storage
AWS_REGION=eu-north-1

# Payment Providers
PAYME_SECRET_KEY=your-payme-secret
PAYME_MERCHANT_ID=your-payme-merchant-id

# Click (Optional)
CLICK_SECRET_KEY=your-click-secret
CLICK_MERCHANT_ID=your-click-merchant-id
CLICK_SERVICE_ID=your-click-service-id

# CORS (comma-separated origins)
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

#### 3. Database Setup

```bash
# Create database (PostgreSQL must be running)
createdb wedy_db

# Run migrations
poetry run alembic upgrade head

# Seed initial data (optional)
poetry run python scripts/seed_data.py
```

#### 4. Run the Server

```bash
# Development mode (with auto-reload)
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Production mode
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

The API will be available at `http://localhost:8000`

---

### Mobile App Setup

#### 1. Install Flutter

Follow the official [Flutter installation guide](https://docs.flutter.dev/get-started/install).

Verify installation:

```bash
flutter doctor
```

#### 2. Install Dependencies

```bash
cd mobile

# Install Flutter dependencies
flutter pub get

# Install iOS dependencies (macOS only)
cd ios && pod install && cd ..
```

#### 3. Configure API Endpoint

Update the API base URL in `mobile/lib/core/api/api_client.dart`:

```dart
static const String baseUrl = 'http://localhost:8000/api/v1';
```

For Android emulator, use:
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
```

For iOS simulator, use:
```dart
static const String baseUrl = 'http://localhost:8000/api/v1';
```

#### 4. Run the App

**Client App:**
```bash
# Development
flutter run -t lib/apps/client/app.dart

# Or use script
./scripts/run_client_dev.sh
```

**Merchant App:**
```bash
# Development
flutter run -t lib/apps/merchant/app.dart

# Or use script
./scripts/run_merchant_dev.sh
```

#### 5. Build for Production

See `mobile/scripts/README.md` for detailed build instructions.

---

## 💻 Development

### Backend Development

#### Code Style

```bash
# Format code with Black
poetry run black app/

# Check code style
poetry run flake8 app/

# Type checking
poetry run mypy app/
```

#### Database Migrations

```bash
# Create a new migration
poetry run alembic revision --autogenerate -m "description"

# Apply migrations
poetry run alembic upgrade head

# Rollback migration
poetry run alembic downgrade -1
```

#### Adding New Features

1. Create model in `app/models/`
2. Create repository in `app/repositories/`
3. Create service in `app/services/`
4. Create schemas in `app/schemas/`
5. Create API endpoints in `app/api/v1/`
6. Write tests in `tests/`

### Mobile Development

#### Code Generation

```bash
# Generate API client code
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for code generation
flutter pub run build_runner watch
```

#### Project Structure

The mobile app follows Clean Architecture:

- **apps/**: App-specific entry points (client/merchant)
- **core/**: Core functionality (API, BLoC, repositories)
- **features/**: Feature modules (auth, services, payments)
- **shared/**: Shared UI components and utilities

---

## 🧪 Testing

### Backend Testing

```bash
cd backend

# Run all tests
poetry run pytest

# Run with coverage
poetry run pytest --cov=app --cov-report=html

# Run specific test file
poetry run pytest tests/user/test_user_api.py -v

# Run specific test
poetry run pytest tests/user/test_user_api.py::TestUserAPI::test_create_user -v
```

**Test Coverage**: ~99.5% (395/397 tests passing)

Test categories:
- ✅ API endpoint tests
- ✅ Service layer tests
- ✅ Repository tests
- ✅ Authentication tests
- ✅ Payment integration tests

### Mobile Testing

```bash
cd mobile

# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

---

## 📚 API Documentation

### Interactive API Docs

When `DEBUG=True` or `ENABLE_DOCS=True`, API documentation is available at:

- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

### API Endpoints Overview

#### Authentication (`/api/v1/auth`)
- `POST /send-otp` - Send OTP via SMS
- `POST /verify-otp` - Verify OTP and get tokens
- `POST /refresh-token` - Refresh access token
- `POST /complete-registration` - Complete user registration

#### Users (`/api/v1/users`)
- `GET /me` - Get current user profile
- `PUT /me` - Update user profile
- `POST /avatar` - Upload avatar
- `DELETE /me` - Delete account (soft delete)
- `GET /interactions` - Get user's liked/saved services

#### Services (`/api/v1/services`)
- `GET /` - List services (with filters)
- `POST /` - Create service (merchant only)
- `GET /{service_id}` - Get service details
- `PUT /{service_id}` - Update service (merchant only)
- `DELETE /{service_id}` - Delete service (merchant only)
- `POST /{service_id}/interact` - Interact with service (view/like/save/share)

#### Merchants (`/api/v1/merchants`)
- `GET /me` - Get merchant profile
- `PUT /me` - Update merchant profile
- `POST /cover-image` - Upload cover image
- `POST /gallery` - Add gallery image
- `GET /subscription` - Get subscription details

#### Payments (`/api/v1/payments`)
- `POST /tariff` - Create tariff subscription payment
- `POST /featured-service` - Create featured service payment
- `POST /webhook/{method}` - Payment webhook handler

#### Categories (`/api/v1/categories`)
- `GET /` - List all categories
- `POST /` - Create category (admin only)
- `GET /{category_id}` - Get category details

#### Reviews (`/api/v1/reviews`)
- `GET /service/{service_id}` - Get reviews for service
- `POST /` - Create review
- `PUT /{review_id}` - Update review
- `DELETE /{review_id}` - Delete review

See `/docs` endpoint for complete interactive documentation.

---

## 🚢 Deployment

### Docker Deployment

The easiest way to deploy is using Docker Compose:

```bash
# Production environment variables
export DEBUG=False
export DATABASE_URL=postgresql+asyncpg://...
# ... other variables

# Start services
docker-compose -f docker-compose.prod.yml up -d
```

### Manual Deployment

#### Backend

1. Set up PostgreSQL database
2. Set up Redis server
3. Configure environment variables
4. Run migrations: `alembic upgrade head`
5. Start with production WSGI server (Gunicorn + Uvicorn workers)

#### Mobile

1. Configure API endpoint for production
2. Build APK/IPA:
   ```bash
   # Android
   flutter build apk --release
   
   # iOS
   flutter build ios --release
   ```
3. Submit to app stores

See `docs/DEPLOYMENT.md` for detailed deployment instructions.

---

## 📊 Project Status

### Backend: ~95% Complete ✅

- ✅ Core authentication & user management
- ✅ Service management & search
- ✅ Merchant management
- ✅ Payment system (Payme ✅, Click ✅, UzumBank ⚠️)
- ✅ Review & rating system
- ✅ Analytics dashboard
- ✅ Tariff & subscription system

### Mobile: ~10% Complete ⚠️

- ✅ Project structure & architecture
- ⚠️ Feature implementation (in progress)
- ❌ App store submission (pending)

See `backend/FEATURE_STATUS.md` for detailed status.

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow existing code style (Black for Python, Dart formatting for Flutter)
- Write tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting PR

---

## 📝 License

This project is proprietary software. All rights reserved.

---

## 📧 Contact

**Project**: Wedy Platform  
**Author**: Abdurakhmon Davronov  
**Email**: abdurakhmon278@gmail.com

---

## 🙏 Acknowledgments

- FastAPI team for the excellent framework
- Flutter team for the cross-platform framework
- All open-source contributors whose libraries power this project

---

<div align="center">

**Made with ❤️ for Uzbekistan's wedding industry**

[Documentation](docs/) • [Backend README](backend/README.md) • [Mobile README](mobile/README.md)

</div>
