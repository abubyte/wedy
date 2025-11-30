# Wedy Backend API

<div align="center">

**FastAPI-based REST API for the Wedy wedding services platform**

[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green.svg)](https://fastapi.tiangolo.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7-red.svg)](https://redis.io/)
[![Test Coverage](https://img.shields.io/badge/Test%20Coverage-99.5%25-green.svg)](./tests/)
[![Tests](https://img.shields.io/badge/Tests-395%2F397%20Passing-green.svg)](./tests/)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Environment Configuration](#environment-configuration)
  - [Database Setup](#database-setup)
  - [Running the Server](#running-the-server)
- [API Documentation](#api-documentation)
- [Development](#development)
  - [Code Style](#code-style)
  - [Database Migrations](#database-migrations)
  - [Adding New Features](#adding-new-features)
- [Testing](#testing)
- [Payment Integration](#payment-integration)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

The Wedy Backend API is a high-performance REST API built with FastAPI, designed to power the Wedy wedding services platform. It provides comprehensive endpoints for authentication, service management, merchant operations, payment processing, and analytics.

### Key Features

- 🔐 **Authentication**: Phone-based OTP verification with JWT tokens
- 💳 **Payments**: Multiple payment provider integrations (Payme, Click)
- 📊 **Analytics**: Real-time tracking and metrics for merchants
- 💰 **Subscriptions**: Tariff-based subscription system with usage limits
- 🖼️ **Media**: AWS S3 integration for image storage
- 🧪 **Testing**: Comprehensive test suite with 99.5% coverage
- 📝 **Documentation**: Auto-generated API docs with Swagger/ReDoc

---

## 🏗️ Architecture

The backend follows a **clean architecture** pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    API Layer (FastAPI)                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │   Auth   │  │ Services │  │ Payments │  │  ...    │ │
│  │ Endpoint │  │ Endpoint │  │ Endpoint │  │         │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬────┘ │
└───────┼─────────────┼─────────────┼─────────────┼───────┘
        │             │             │             │
┌───────▼─────────────▼─────────────▼─────────────▼───────┐
│                  Service Layer                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │   Auth   │  │ Service  │  │ Payment  │  │  ...    │ │
│  │ Service  │  │ Manager  │  │ Service  │  │         │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬────┘ │
└───────┼─────────────┼─────────────┼─────────────┼───────┘
        │             │             │             │
┌───────▼─────────────▼─────────────▼─────────────▼───────┐
│                Repository Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │   User   │  │ Service  │  │ Payment  │  │  ...    │ │
│  │Repository│  │Repository│  │Repository│  │         │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬────┘ │
└───────┼─────────────┼─────────────┼─────────────┼───────┘
        │             │             │             │
┌───────▼─────────────▼─────────────▼─────────────▼───────┐
│                    Database Layer                        │
│              PostgreSQL + Redis + S3                      │
└──────────────────────────────────────────────────────────┘
```

### Design Principles

- **Async/Await**: Full asynchronous operations for better performance
- **Type Safety**: Extensive use of type hints and Pydantic models
- **Dependency Injection**: Clean dependency management with FastAPI
- **Error Handling**: Custom exception hierarchy with proper HTTP mapping
- **Repository Pattern**: Separation of data access logic

---

## 🛠️ Technology Stack

### Core Framework
- **FastAPI** 0.104+ - Modern, fast web framework
- **Python** 3.11+ - Programming language
- **Uvicorn** - ASGI server

### Database & ORM
- **PostgreSQL** 15 - Primary database
- **SQLModel** - ORM (SQLAlchemy + Pydantic)
- **Alembic** - Database migrations
- **asyncpg** - Async PostgreSQL driver

### Caching & Storage
- **Redis** 7 - Caching and OTP storage
- **AWS S3** (boto3) - Image storage

### Authentication & Security
- **JWT** (python-jose) - Token-based authentication
- **OTP** - Phone verification via Eskiz.uz

### Payment Providers
- **Payme** - Fully integrated ✅
- **Click** - Integrated (requires credentials) ✅
- **UzumBank** - Planned ⚠️

### External Services
- **Eskiz.uz** - SMS service for OTP delivery

### Development Tools
- **Poetry** - Dependency management
- **pytest** - Testing framework
- **Black** - Code formatting
- **Flake8** - Linting
- **mypy** - Type checking

---

## 📁 Project Structure

```
backend/
├── app/
│   ├── api/                      # API endpoints
│   │   ├── deps.py              # Dependency injection
│   │   └── v1/                  # API version 1
│   │       ├── auth.py          # Authentication endpoints
│   │       ├── users.py         # User endpoints
│   │       ├── merchants.py     # Merchant endpoints
│   │       ├── services.py      # Service endpoints
│   │       ├── categories.py    # Category endpoints
│   │       ├── payments.py      # Payment endpoints
│   │       ├── reviews.py       # Review endpoints
│   │       ├── tariffs.py       # Tariff endpoints
│   │       └── merchants_*.py   # Merchant-specific endpoints
│   │
│   ├── core/                     # Core functionality
│   │   ├── config.py            # Configuration & settings
│   │   ├── database.py          # Database connection & setup
│   │   ├── exceptions.py        # Custom exceptions
│   │   └── security.py          # Security utilities (JWT, hashing)
│   │
│   ├── models/                   # SQLModel database models
│   │   ├── user_model.py
│   │   ├── merchant_model.py
│   │   ├── service_model.py
│   │   ├── payment_model.py
│   │   ├── review_model.py
│   │   └── ...
│   │
│   ├── repositories/             # Data access layer
│   │   ├── base.py              # Base repository class
│   │   ├── user_repository.py
│   │   ├── merchant_repository.py
│   │   ├── service_repository.py
│   │   └── ...
│   │
│   ├── schemas/                  # Pydantic schemas (request/response)
│   │   ├── auth_schema.py
│   │   ├── user_schema.py
│   │   ├── merchant_schema.py
│   │   ├── service_schema.py
│   │   └── ...
│   │
│   ├── services/                 # Business logic layer
│   │   ├── auth_service.py      # Authentication logic
│   │   ├── merchant_manager.py  # Merchant operations
│   │   ├── service_manager.py   # Service operations
│   │   ├── payment_service.py   # Payment processing
│   │   ├── payment_providers.py # Payment provider integrations
│   │   ├── review_service.py    # Review operations
│   │   └── ...
│   │
│   ├── utils/                    # Utility functions
│   │   ├── redis_client.py      # Redis client
│   │   ├── s3_client.py         # S3 client
│   │   └── constants.py         # Constants
│   │
│   └── main.py                   # FastAPI application entry point
│
├── alembic/                      # Database migrations
│   ├── versions/                # Migration files
│   └── env.py                   # Alembic configuration
│
├── tests/                        # Test suite
│   ├── conftest.py              # Pytest fixtures
│   ├── auth/                    # Auth tests
│   ├── user/                    # User tests
│   ├── merchant/                # Merchant tests
│   ├── service/                 # Service tests
│   ├── payment/                 # Payment tests
│   └── ...
│
├── scripts/                      # Utility scripts
│   ├── init_db.py              # Database initialization
│   ├── seed_data.py            # Seed sample data
│   └── wait_for_db.py          # Database wait script
│
├── Dockerfile                    # Docker configuration
├── pyproject.toml               # Poetry dependencies
├── alembic.ini                  # Alembic configuration
├── pytest.ini                   # Pytest configuration
└── README.md                    # This file
```

---

## 🚀 Getting Started

### Prerequisites

- **Python** 3.11 or higher
- **Poetry** (package manager)
- **PostgreSQL** 15 or higher
- **Redis** 7 or higher
- **AWS Account** (for S3 storage)
- **Eskiz.uz Account** (for SMS service)

### Installation

#### 1. Install Poetry

```bash
# On macOS/Linux
curl -sSL https://install.python-poetry.org | python3 -

# Or with pip
pip install poetry
```

#### 2. Clone and Install Dependencies

```bash
cd backend

# Install dependencies
poetry install

# Activate virtual environment
poetry shell
```

### Environment Configuration

Create a `.env` file in the `backend/` directory:

```bash
cp .env.example .env
```

#### Required Environment Variables

```env
# Application Settings
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

# CORS
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

### Database Setup

#### 1. Create Database

```bash
# Create PostgreSQL database
createdb wedy_db

# Or using psql
psql -U postgres
CREATE DATABASE wedy_db;
```

#### 2. Run Migrations

```bash
# Upgrade to latest migration
poetry run alembic upgrade head

# Create a new migration (after model changes)
poetry run alembic revision --autogenerate -m "description"
```

#### 3. Seed Initial Data (Optional)

```bash
poetry run python scripts/seed_data.py
```

### Running the Server

#### Development Mode

```bash
# With auto-reload
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Or using Python directly
poetry run python -m app.main
```

#### Production Mode

```bash
# Using Uvicorn with multiple workers
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4

# Or using Gunicorn with Uvicorn workers
poetry run gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
```

#### Using Docker

```bash
# Build and run with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f backend
```

The API will be available at `http://localhost:8000`

---

## 📚 API Documentation

### Interactive Documentation

When `DEBUG=True` or `ENABLE_DOCS=True`, access the interactive API documentation:

- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

### API Endpoints

#### Authentication (`/api/v1/auth`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `POST` | `/send-otp` | Send OTP via SMS | ❌ |
| `POST` | `/verify-otp` | Verify OTP and get tokens | ❌ |
| `POST` | `/refresh-token` | Refresh access token | ❌ |
| `POST` | `/complete-registration` | Complete user registration | ✅ |

#### Users (`/api/v1/users`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `GET` | `/profile` | Get current user profile | ✅ |
| `PUT` | `/profile` | Update user profile | ✅ |
| `POST` | `/avatar` | Upload user avatar | ✅ |
| `DELETE` | `/profile` | Delete account (soft delete) | ✅ |
| `GET` | `/interactions` | Get liked/saved services | ✅ |

#### Services (`/api/v1/services`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `GET` | `/` | List services (with filters) | ❌ |
| `GET` | `/{service_id}` | Get service details | ❌ |
| `POST` | `/` | Create service | ✅ (Merchant) |
| `PUT` | `/{service_id}` | Update service | ✅ (Merchant) |
| `DELETE` | `/{service_id}` | Delete service | ✅ (Merchant) |
| `POST` | `/{service_id}/interact` | Interact (view/like/save/share) | ✅ |
| `GET` | `/featured` | Get featured services | ❌ |

#### Merchants (`/api/v1/merchants`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `GET` | `/me` | Get merchant profile | ✅ (Merchant) |
| `PUT` | `/me` | Update merchant profile | ✅ (Merchant) |
| `GET` | `/subscription` | Get subscription details | ✅ (Merchant) |
| `GET` | `/analytics` | Get analytics dashboard | ✅ (Merchant) |
| `GET` | `/featured-services` | Get featured services tracking | ✅ (Merchant) |
| `POST` | `/cover-image` | Upload cover image | ✅ (Merchant) |
| `POST` | `/gallery` | Add gallery image | ✅ (Merchant) |
| `DELETE` | `/gallery/{image_id}` | Delete gallery image | ✅ (Merchant) |

#### Payments (`/api/v1/payments`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `POST` | `/tariff` | Create tariff subscription payment | ✅ (Merchant) |
| `POST` | `/featured-service` | Create featured service payment | ✅ (Merchant) |
| `POST` | `/webhook/{method}` | Payment webhook handler | ❌ (Signed) |

#### Categories (`/api/v1/categories`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `GET` | `/` | List all categories | ❌ |
| `GET` | `/{category_id}` | Get category details | ❌ |
| `POST` | `/` | Create category | ✅ (Admin) |
| `PUT` | `/{category_id}` | Update category | ✅ (Admin) |
| `DELETE` | `/{category_id}` | Delete category | ✅ (Admin) |

#### Reviews (`/api/v1/reviews`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `GET` | `/service/{service_id}` | Get reviews for service | ❌ |
| `POST` | `/` | Create review | ✅ (Client) |
| `PUT` | `/{review_id}` | Update review | ✅ (Owner) |
| `DELETE` | `/{review_id}` | Delete review | ✅ (Owner) |

#### Tariffs (`/api/v1/tariffs`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `GET` | `/` | List tariff plans | ❌ |
| `GET` | `/{tariff_id}` | Get tariff details | ❌ |
| `POST` | `/` | Create tariff plan | ✅ (Admin) |
| `PUT` | `/{tariff_id}` | Update tariff plan | ✅ (Admin) |

### Authentication

Most endpoints require authentication via JWT tokens:

```http
Authorization: Bearer <access_token>
```

Access tokens expire in 15 minutes (configurable). Use the refresh token to get a new access token:

```http
POST /api/v1/auth/refresh-token
Content-Type: application/json

{
  "refresh_token": "your_refresh_token"
}
```

---

## 💻 Development

### Code Style

We use **Black** for code formatting and **Flake8** for linting:

```bash
# Format code
poetry run black app/

# Check code style
poetry run flake8 app/

# Type checking
poetry run mypy app/
```

**Black Configuration** (from `pyproject.toml`):
- Line length: 88 characters
- Target Python version: 3.11

### Database Migrations

#### Create a Migration

```bash
# Auto-generate migration from model changes
poetry run alembic revision --autogenerate -m "add new field to user model"

# Create empty migration
poetry run alembic revision -m "custom migration"
```

#### Apply Migrations

```bash
# Upgrade to latest
poetry run alembic upgrade head

# Upgrade to specific revision
poetry run alembic upgrade <revision>

# Rollback one migration
poetry run alembic downgrade -1

# Rollback to specific revision
poetry run alembic downgrade <revision>
```

#### Migration Best Practices

1. Always review auto-generated migrations before applying
2. Test migrations on development database first
3. Never edit existing migrations in production
4. Create data migrations separately from schema migrations

### Adding New Features

Follow this workflow when adding new features:

#### 1. Create Database Model

```python
# app/models/my_model.py
from sqlmodel import SQLModel, Field
from uuid import UUID, uuid4
from datetime import datetime

class MyModel(SQLModel, table=True):
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    name: str
    created_at: datetime = Field(default_factory=datetime.now)
```

#### 2. Create Repository

```python
# app/repositories/my_repository.py
from app.repositories.base import BaseRepository
from app.models.my_model import MyModel

class MyRepository(BaseRepository[MyModel]):
    def __init__(self, session: AsyncSession):
        super().__init__(session, MyModel)
    
    async def find_by_name(self, name: str) -> Optional[MyModel]:
        # Custom query logic
        pass
```

#### 3. Create Service/Manager

```python
# app/services/my_service.py
from app.repositories.my_repository import MyRepository

class MyService:
    def __init__(self, session: AsyncSession):
        self.session = session
        self.repo = MyRepository(session)
    
    async def create_my_model(self, data: dict):
        # Business logic
        pass
```

#### 4. Create Schemas

```python
# app/schemas/my_schema.py
from pydantic import BaseModel
from uuid import UUID

class MyModelCreate(BaseModel):
    name: str

class MyModelResponse(BaseModel):
    id: UUID
    name: str
```

#### 5. Create API Endpoint

```python
# app/api/v1/my_endpoint.py
from fastapi import APIRouter, Depends
from app.core.database import get_db_session
from app.services.my_service import MyService

router = APIRouter()

@router.post("/", response_model=MyModelResponse)
async def create_my_model(
    data: MyModelCreate,
    db: AsyncSession = Depends(get_db_session)
):
    service = MyService(db)
    result = await service.create_my_model(data.dict())
    return result
```

#### 6. Register Router

```python
# app/main.py
from app.api.v1 import my_endpoint

app.include_router(
    my_endpoint.router,
    prefix=settings.API_V1_STR + "/my-endpoint",
    tags=["My Endpoint"]
)
```

#### 7. Write Tests

```python
# tests/my_endpoint/test_my_api.py
import pytest

class TestMyAPI:
    async def test_create_my_model(self, client):
        response = await client.post("/api/v1/my-endpoint/", json={"name": "Test"})
        assert response.status_code == 201
```

---

## 🧪 Testing

### Running Tests

```bash
# Run all tests
poetry run pytest

# Run with verbose output
poetry run pytest -v

# Run specific test file
poetry run pytest tests/user/test_user_api.py

# Run specific test
poetry run pytest tests/user/test_user_api.py::TestUserAPI::test_create_user

# Run with coverage
poetry run pytest --cov=app --cov-report=html

# Run only unit tests
poetry run pytest -m unit

# Run only integration tests
poetry run pytest -m integration
```

### Test Structure

Tests are organized by feature/domain:

```
tests/
├── conftest.py              # Shared fixtures
├── auth/                    # Authentication tests
│   ├── test_auth_api.py
│   └── test_auth_service.py
├── user/                    # User tests
├── merchant/                # Merchant tests
├── service/                 # Service tests
└── ...
```

### Test Coverage

Current test coverage: **99.5%** (395/397 tests passing)

- ✅ API endpoint tests
- ✅ Service layer tests
- ✅ Repository tests
- ✅ Authentication & authorization tests
- ✅ Payment integration tests
- ✅ Error handling tests

### Writing Tests

Example test structure:

```python
import pytest
from httpx import AsyncClient

class TestMyFeature:
    async def test_endpoint_success(self, authenticated_client: AsyncClient):
        """Test successful endpoint call."""
        response = await authenticated_client.get("/api/v1/my-endpoint/")
        assert response.status_code == 200
        assert "data" in response.json()
    
    async def test_endpoint_unauthorized(self, client: AsyncClient):
        """Test unauthorized access."""
        response = await client.get("/api/v1/my-endpoint/")
        assert response.status_code == 401
```

---

## 💳 Payment Integration

### Supported Payment Providers

1. **Payme** ✅ - Fully integrated and tested
2. **Click** ✅ - Integrated (requires credentials)
3. **UzumBank** ⚠️ - Planned

### Payment Flow

```
1. Client creates payment request
   ↓
2. Backend generates payment URL via provider
   ↓
3. Client redirects to payment provider
   ↓
4. User completes payment
   ↓
5. Provider sends webhook to backend
   ↓
6. Backend verifies webhook and processes payment
```

### Adding a New Payment Provider

1. Create provider class in `app/services/payment_providers.py`:

```python
class MyProvider(BasePaymentProvider):
    async def create_payment(self, payment_data: Dict[str, Any]) -> Dict[str, str]:
        # Implementation
        pass
    
    def verify_webhook(self, webhook_data: Dict[str, Any], signature: str) -> bool:
        # Implementation
        pass
    
    def extract_payment_status(self, webhook_data: Dict[str, Any]) -> str:
        # Implementation
        pass
```

2. Register in `PaymentProviderFactory`:

```python
_providers = {
    PaymentMethod.PAYME: PaymeProvider,
    PaymentMethod.CLICK: ClickProvider,
    PaymentMethod.MYPROVIDER: MyProvider,  # Add here
}
```

3. Add environment variables for credentials

4. Test webhook handling

### Webhook Configuration

Configure webhook URLs in your payment provider dashboard:

- **Payme**: `https://your-domain.com/api/v1/payments/webhook/payme`
- **Click**: `https://your-domain.com/api/v1/payments/webhook/click`

---

## 🚢 Deployment

### Docker Deployment

The easiest way to deploy:

```bash
# Build Docker image
docker build -t wedy-backend .

# Run with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f backend
```

### Manual Deployment

#### 1. Install Dependencies

```bash
poetry install --no-dev
```

#### 2. Set Environment Variables

Configure all required environment variables in production environment.

#### 3. Run Migrations

```bash
poetry run alembic upgrade head
```

#### 4. Start Server

```bash
# Using Gunicorn (recommended for production)
poetry run gunicorn app.main:app \
    -w 4 \
    -k uvicorn.workers.UvicornWorker \
    --bind 0.0.0.0:8000 \
    --access-logfile - \
    --error-logfile -
```

### Production Checklist

- [ ] Set `DEBUG=False`
- [ ] Configure proper `CORS_ORIGINS`
- [ ] Set secure `SECRET_KEY`
- [ ] Enable HTTPS (via Nginx)
- [ ] Configure database connection pooling
- [ ] Set up logging
- [ ] Configure monitoring
- [ ] Set up backups for PostgreSQL
- [ ] Configure Redis persistence
- [ ] Set up SSL certificates for S3

### Environment-Specific Configuration

Use environment-specific `.env` files:
- `.env.development` - Development settings
- `.env.staging` - Staging settings
- `.env.production` - Production settings

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Database Connection Error

**Error**: `Connection refused` or `database does not exist`

**Solution**:
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Verify DATABASE_URL in .env
# Ensure database exists
createdb wedy_db
```

#### 2. Redis Connection Error

**Error**: `Connection refused` to Redis

**Solution**:
```bash
# Check Redis is running
redis-cli ping

# Verify REDIS_URL in .env
# Start Redis if needed
redis-server
```

#### 3. Migration Errors

**Error**: `Target database is not up to date`

**Solution**:
```bash
# Check current revision
poetry run alembic current

# Upgrade to latest
poetry run alembic upgrade head

# If conflicts, review migration history
poetry run alembic history
```

#### 4. Import Errors

**Error**: `ModuleNotFoundError` or `ImportError`

**Solution**:
```bash
# Ensure virtual environment is activated
poetry shell

# Reinstall dependencies
poetry install

# Check Python path
poetry run python -c "import sys; print(sys.path)"
```

#### 5. Payment Provider Errors

**Error**: `PaymentProviderError` or webhook verification fails

**Solution**:
- Verify credentials in `.env`
- Check webhook signature verification logic
- Ensure webhook URL is publicly accessible
- Review payment provider logs

### Debugging

Enable debug logging:

```python
# In .env
DEBUG=True

# Or set log level
import logging
logging.basicConfig(level=logging.DEBUG)
```

View application logs:

```bash
# Docker
docker-compose logs -f backend

# Direct
poetry run uvicorn app.main:app --log-level debug
```

---

## 📊 Project Status

### Current Status: ~95% Complete ✅

**Fully Functional:**
- ✅ Authentication & authorization
- ✅ User & merchant management
- ✅ Service management
- ✅ Review & rating system
- ✅ Payment processing (Payme, Click)
- ✅ Tariff & subscription system
- ✅ Analytics dashboard

**In Progress:**
- ⚠️ UzumBank payment integration

**Test Coverage:**
- ✅ 395/397 tests passing (99.5%)
- ✅ Comprehensive test suite

See [FEATURE_STATUS.md](./FEATURE_STATUS.md) for detailed status.

---

## 📝 Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLModel Documentation](https://sqlmodel.tiangolo.com/)
- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [Pytest Documentation](https://docs.pytest.org/)

---

## 📧 Support

For issues, questions, or contributions:

- **Email**: abdurakhmon278@gmail.com
- **Project**: Wedy Platform
- **Repository**: [Link to repository]

---

<div align="center">

**Built with ❤️ using FastAPI**

[Main Project README](../README.md) • [API Documentation](/docs)

</div>
