# Wedy Project Documentation

## Overview

Wedy is a comprehensive platform designed to streamline wedding planning and management. The system consists of a backend API (Python/FastAPI), a mobile application (Flutter), and supporting infrastructure for deployment and development.

---

## Table of Contents
- [Project Structure](#project-structure)
- [Backend](#backend)
  - [Setup](#backend-setup)
  - [Development](#backend-development)
  - [Testing](#backend-testing)
- [Mobile App](#mobile-app)
  - [Setup](#mobile-setup)
  - [Development](#mobile-development)
  - [Testing](#mobile-testing)
- [Infrastructure](#infrastructure)
- [Deployment](#deployment)
- [Scripts](#scripts)
- [Contributing](#contributing)
- [License](#license)

---

## Project Structure

```
root/
├── backend/         # Python FastAPI backend
├── mobile/          # Flutter mobile app
├── infra/           # Infrastructure (nginx, postgres, redis, etc.)
├── docs/            # Documentation
├── assets/          # Shared assets (images, fonts, etc.)
├── scripts/         # Utility and deployment scripts
```

---

## Backend

### Backend Setup
1. **Install Python 3.12+**
2. **Install Poetry:**
   ```sh
   pip install poetry
   ```
3. **Install dependencies:**
   ```sh
   cd backend
   poetry install
   ```
4. **Configure environment variables:**
   - Copy `.env.example` to `.env` and update values as needed.

### Backend Development
- **Run the API locally:**
  ```sh
  poetry run uvicorn app.main:app --reload
  ```
- **Database migrations:**
  ```sh
  alembic upgrade head
  ```
- **Seeding the database:**
  ```sh
  poetry run python scripts/seed_data.py
  ```

### Backend Testing
- **Run tests:**
  ```sh
  poetry run pytest
  ```

---

## Mobile App

### Mobile Setup
1. **Install Flutter SDK** ([Flutter installation guide](https://docs.flutter.dev/get-started/install))
2. **Install dependencies:**
   ```sh
   cd mobile
   flutter pub get
   ```

### Mobile Development
- **Run the app:**
  ```sh
  flutter run
  ```
- **Build for release:**
  ```sh
  flutter build apk   # Android
  flutter build ios   # iOS
  ```

### Mobile Testing
- **Run tests:**
  ```sh
  flutter test
  ```

---

## Infrastructure
- **Docker Compose** files for local and production environments are in the root directory.
- **Nginx, Postgres, Redis** configuration files are in `infra/`.
- **To start all services locally:**
  ```sh
  docker-compose up
  ```

---

## Deployment
- See `docs/DEPLOYMENT.md` for detailed deployment instructions.
- Production deployment uses `docker-compose.production.yml` and scripts in `scripts/`.

---

## Scripts
- Utility scripts for database setup, deployment, and server management are in `scripts/` and `backend/scripts/`.
- Example:
  - `backup-database.sh`: Backup the database
  - `deploy-production.sh`: Deploy to production
  - `init_db.py`: Initialize the database

---

## Contributing
1. Fork the repository
2. Create a new branch (`git checkout -b feature/your-feature`)
3. Commit your changes
4. Push to your branch
5. Open a Pull Request

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---


## Backend Documentation

### Architecture Overview
The backend is a modern, modular FastAPI application using SQLModel (SQLAlchemy ORM), async PostgreSQL, Redis, and AWS S3. It is organized for scalability, maintainability, and clear separation of concerns.

#### Key Technologies
- **Python 3.11+**
- **FastAPI** for REST APIs
- **SQLModel** (SQLAlchemy ORM)
- **Alembic** for migrations
- **Redis** (async) for caching, OTP, and rate limiting
- **AWS S3** for file storage
- **httpx** for async HTTP requests (e.g., SMS)
- **Poetry** for dependency management

### Main Modules
- `app/main.py`: FastAPI app, routers, middleware, exception handling, startup/shutdown events
- `app/core/`: Core config, database, security, exceptions
- `app/models/`: SQLModel ORM models for all entities (User, Merchant, Service, Payment, etc.)
- `app/schemas/`: Pydantic schemas for request/response validation
- `app/services/`: Business logic (auth, merchant, payment, etc.)
- `app/api/v1/`: API routers (auth, users, services, merchants, payments, reviews, admin)
- `app/utils/`: Utilities (Redis, S3, constants)

### API Structure
All endpoints are versioned under `/api/v1`. Main routers:
- `/auth`: OTP login, registration, token refresh
- `/users`: Profile, avatar, interactions
- `/services`: Browse, search, details, interactions, featured, similar
- `/merchants`: Merchant profile, contacts, gallery, analytics, services
- `/payments`: Tariff plans, subscriptions, payment webhooks
- `/reviews`: Service reviews (TODO)
- `/admin`: Categories, tariffs (admin only, TODO)

#### Example: Auth Flow
1. **Send OTP**: `POST /api/v1/auth/send-otp` (phone number)
2. **Verify OTP**: `POST /api/v1/auth/verify-otp` (phone, code)
3. **Complete Registration**: `POST /api/v1/auth/complete-registration`
4. **Refresh Token**: `POST /api/v1/auth/refresh`

#### Example: Service Search
`GET /api/v1/services/search?query=photo&min_price=100000&max_price=500000&sort_by=rating`

### Models Overview
- **User**: Clients, merchants, admins (UUID, phone, name, type, avatar, etc.)
- **Merchant**: Business profile, location, contacts, ratings
- **Service**: Merchant offerings (category, price, location, images, stats)
- **Payment**: Tariff/feature payments, status, method, webhooks
- **TariffPlan**: Subscription plans for merchants
- **FeaturedService**: Promoted services
- **Review**: User reviews for services (TODO)

### Configuration
All settings are managed via environment variables and `app/core/config.py` (Pydantic). Key settings:
- `DATABASE_URL`, `REDIS_URL`, `AWS_*`, `SECRET_KEY`, `CORS_ORIGINS`, etc.
- `.env.example` provided for reference

### Database & Migrations
- **Alembic** is used for migrations (`alembic.ini`, `alembic/`)
- Models are in `app/models/`
- Scripts for DB init and seeding: `backend/scripts/init_db.py`, `backend/scripts/seed_data.py`

### OTP & SMS
- OTPs are generated, rate-limited, and stored in Redis
- SMS sent via Eskiz.uz (see `app/services/external/sms_service.py`)

### File Storage
- AWS S3 is used for user avatars, merchant images, etc. (`app/utils/s3_client.py`)

### Development Workflow
1. **Install dependencies**: `poetry install`
2. **Configure `.env`**
3. **Run DB migrations**: `alembic upgrade head`
4. **Seed sample data**: `poetry run python scripts/seed_data.py`
5. **Run server**: `poetry run uvicorn app.main:app --reload`
6. **Run tests**: `poetry run pytest`

### Testing
- Uses `pytest` and `pytest-asyncio`
- Test files are in `backend/tests/`

### Extending the API
- Add new models to `app/models/`
- Add new endpoints to `app/api/v1/`
- Add business logic to `app/services/`
- Add/modify schemas in `app/schemas/`

### What Does the Backend Do?
The Wedy backend powers the entire wedding platform, providing:
- Secure user authentication via phone number and OTP
- Merchant onboarding and business profile management
- Service listing, search, and discovery for clients
- Subscription and payment management for merchants
- Ratings, reviews, and featured promotions
- File uploads (images, avatars) to AWS S3
- Admin endpoints for managing categories and tariffs

### How Does It Work?
1. **User Authentication**: Users sign up or log in with their phone number. An OTP is sent via SMS for verification. After verifying, users receive JWT tokens for secure API access.
2. **Merchant Onboarding**: Merchants register, create a business profile, and subscribe to a tariff plan to unlock features (e.g., more services, gallery, featured listings).
3. **Service Discovery**: Clients can search, filter, and view wedding services by category, price, region, and more. They can interact (like, save) and leave reviews (coming soon).
4. **Payments**: Merchants pay for subscriptions and featured promotions using integrated payment providers (Payme, Click, UzumBank). Payment status is tracked and webhooks are handled.
5. **Admin Tools**: Admins can manage service categories and tariff plans (API endpoints, UI not included).

### How to Use the Backend (as a User or API Consumer)

#### 1. Authentication Flow
- **Send OTP**: `POST /api/v1/auth/send-otp` with `{ "phone_number": "901234567" }`
- **Verify OTP**: `POST /api/v1/auth/verify-otp` with `{ "phone_number": "901234567", "otp_code": "123456" }`
- **Complete Registration** (if new): `POST /api/v1/auth/complete-registration` with name and user type
- **Use JWT tokens**: All further requests require `Authorization: Bearer <access_token>`

#### 2. Browsing and Searching Services
- **List services**: `GET /api/v1/services/`
- **Search**: `GET /api/v1/services/search?query=photo&min_price=100000`
- **View details**: `GET /api/v1/services/{service_id}`

#### 3. Merchant Features
- **View/update profile**: `GET/PUT /api/v1/merchants/profile`
- **Upload images**: Use presigned S3 URLs from `/api/v1/merchants/cover-image` and `/gallery-image`
- **Manage services**: Create, update, and feature services
- **Subscribe to plans**: `GET /api/v1/payments/tariffs` and follow payment flow

#### 4. Payments
- **Get tariff plans**: `GET /api/v1/payments/tariffs`
- **Subscribe**: `POST /api/v1/payments/subscribe` (see API docs for details)
- **Handle payment webhooks**: Payment status is updated automatically

#### 5. Admin Endpoints
- **Categories**: `GET/POST /api/v1/admin/categories`
- **Tariffs**: `GET/POST /api/v1/admin/tariffs`

### Example Usage (with curl)
```sh
# 1. Send OTP
curl -X POST http://localhost:8000/api/v1/auth/send-otp -H "Content-Type: application/json" -d '{"phone_number": "901234567"}'

# 2. Verify OTP
curl -X POST http://localhost:8000/api/v1/auth/verify-otp -H "Content-Type: application/json" -d '{"phone_number": "901234567", "otp_code": "123456"}'

# 3. Get services (with token)
curl -H "Authorization: Bearer <access_token>" http://localhost:8000/api/v1/services/
```

### Who Should Use This Backend?
- **Mobile app developers**: Integrate via REST API for user auth, service discovery, merchant features, payments, etc.
- **Web developers**: Build admin panels, dashboards, or client-facing web apps
- **DevOps/Infra**: Deploy, monitor, and scale the backend using Docker, Compose, and cloud services

### API Documentation
- Interactive docs available at `/docs` (Swagger UI) and `/redoc` (if enabled in DEBUG mode)
- All endpoints, request/response schemas, and error codes are documented there

---

## Additional Resources
- [Wedy System Design.pdf](../Wedy%20System%20Design.pdf)
- [development_instructions.md](../development_instructions.md)
