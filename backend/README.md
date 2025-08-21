# Wedy Backend

FastAPI backend for the Wedy Platform - connecting couples with wedding service providers in Uzbekistan.

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- PostgreSQL 15+
- Redis 7+
- Poetry (Python package manager)

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd wedy-backend
```

2. **Install dependencies**
```bash
poetry install
```

3. **Set up environment variables**
```bash
cp .env.example .env
# Edit .env with your actual values
```

4. **Start PostgreSQL and Redis**
```bash
# Using Docker (recommended for development)
docker run --name postgres-wedy -e POSTGRES_DB=wedy_dev -e POSTGRES_USER=dev -e POSTGRES_PASSWORD=devpass -p 5432:5432 -d postgres:15

docker run --name redis-wedy -p 6379:6379 -d redis:7-alpine
```

5. **Initialize the database**
```bash
poetry run python scripts/init_db.py
```

6. **Seed sample data**
```bash
poetry run python scripts/seed_data.py
```

7. **Run the application**
```bash
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

## 📚 API Documentation

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🏗️ Architecture

### Project Structure
```
app/
├── api/v1/           # API endpoints
├── core/             # Core configuration
├── models/           # Database models
├── schemas/          # Pydantic models
├── services/         # Business logic
├── utils/            # Utilities
└── main.py           # FastAPI app
```

### Key Features

- **Phone-based Authentication**: OTP SMS verification via eskiz.uz
- **JWT Tokens**: Stateless authentication with access/refresh tokens
- **Role-based Access**: Client, Merchant, and Admin user types
- **Payment Integration**: Payme, Click, UzumBank support
- **File Upload**: AWS S3 integration for images
- **Caching**: Redis for session management and performance
- **Async/Await**: Full async support with SQLModel and asyncpg

## 🔧 Development

### Environment Variables

Key environment variables (see `.env.example` for complete list):

```bash
# Database
DATABASE_URL=postgresql+asyncpg://dev:devpass@localhost:5432/wedy_dev

# Redis
REDIS_URL=redis://localhost:6379/0

# Security
SECRET_KEY=your-super-secret-jwt-key

# SMS Service (eskiz.uz)
SMS_API_KEY=your-eskiz-api-key

# AWS S3
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_BUCKET_NAME=wedy-dev-bucket

# Payment Providers
PAYME_MERCHANT_ID=your-payme-merchant-id
PAYME_SECRET_KEY=your-payme-secret-key
# ... (Click, UzumBank)
```

### Database Migrations

```bash
# Generate migration
poetry run alembic revision --autogenerate -m "Description"

# Apply migrations
poetry run alembic upgrade head

# Rollback
poetry run alembic downgrade -1
```

### Running Tests

```bash
# Install test dependencies
poetry install --with dev

# Run tests
poetry run pytest

# Run with coverage
poetry run pytest --cov=app
```

### Code Quality

```bash
# Format code
poetry run black app/

# Check linting
poetry run flake8 app/

# Type checking
poetry run mypy app/
```

## 🔐 Authentication Flow

1. **Send OTP**: `POST /api/v1/auth/send-otp`
2. **Verify OTP**: `POST /api/v1/auth/verify-otp`
3. **Complete Registration** (if new user): `POST /api/v1/auth/complete-registration`
4. **Refresh Token**: `POST /api/v1/auth/refresh`

## 💳 Payment Flow

1. **Choose Tariff**: `GET /api/v1/payments/tariffs`
2. **Create Payment**: `POST /api/v1/payments/tariff`
3. **External Payment**: User completes payment in Payme/Click/UzumBank app
4. **Webhook Confirmation**: Payment provider sends webhook
5. **Tariff Activation**: Backend activates subscription

## 📱 API Endpoints

### Authentication
- `POST /api/v1/auth/send-otp` - Send OTP to phone
- `POST /api/v1/auth/verify-otp` - Verify OTP code
- `POST /api/v1/auth/complete-registration` - Complete registration
- `POST /api/v1/auth/refresh` - Refresh access token

### Users
- `GET /api/v1/users/profile` - Get user profile
- `PUT /api/v1/users/profile` - Update user profile
- `POST /api/v1/users/avatar` - Upload avatar

### Services
- `GET /api/v1/services/categories` - Get service categories
- `GET /api/v1/services` - Browse services
- `GET /api/v1/services/search` - Search services
- `GET /api/v1/services/{id}` - Get service details

### Merchants
- `GET /api/v1/merchants/profile` - Get merchant profile
- `PUT /api/v1/merchants/profile` - Update merchant profile
- `GET /api/v1/merchants/services` - Get merchant services
- `POST /api/v1/merchants/services` - Create service

### Payments
- `GET /api/v1/payments/tariffs` - Get tariff plans
- `POST /api/v1/payments/tariff` - Create tariff payment
- `POST /api/v1/payments/webhook/{method}` - Payment webhooks

## 🚀 Deployment

### Production Setup

1. **Server Requirements**
   - Ubuntu 20.04+ or CentOS 8+
   - 2GB+ RAM
   - PostgreSQL 15+
   - Redis 7+
   - Nginx (reverse proxy)

2. **Environment Setup**
```bash
# Install system dependencies
sudo apt update
sudo apt install python3.11 python3.11-venv postgresql redis-server nginx

# Create application user
sudo useradd -m -s /bin/bash wedy
```

3. **Application Deployment**
```bash
# Clone and setup
git clone <repo> /opt/wedy
cd /opt/wedy
python3.11 -m venv venv
source venv/bin/activate
pip install poetry
poetry install --only=main

# Setup environment
cp .env.example .env
# Edit .env with production values

# Initialize database
poetry run python scripts/init_db.py
```

4. **Systemd Service**
```ini
# /etc/systemd/system/wedy.service
[Unit]
Description=Wedy API
After=network.target

[Service]
Type=simple
User=wedy
WorkingDirectory=/opt/wedy
Environment=PATH=/opt/wedy/venv/bin
ExecStart=/opt/wedy/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

5. **Nginx Configuration**
```nginx
# /etc/nginx/sites-available/wedy
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

6. **SSL Certificate** (Let's Encrypt)
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## 🧪 Testing

### Sample API Calls

```bash
# Send OTP
curl -X POST "http://localhost:8000/api/v1/auth/send-otp" \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "901234567"}'

# Verify OTP (use the OTP from logs in development)
curl -X POST "http://localhost:8000/api/v1/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "901234567", "otp_code": "123456"}'

# Get user profile (with token)
curl -X GET "http://localhost:8000/api/v1/users/profile" \
  -H "Authorization: Bearer <your-access-token>"
```

## 🔍 Troubleshooting

### Common Issues

1. **Database Connection Error**
   - Check PostgreSQL is running: `sudo systemctl status postgresql`
   - Verify DATABASE_URL in .env
   - Test connection: `psql "postgresql://dev:devpass@localhost:5432/wedy_dev"`

2. **Redis Connection Error**
   - Check Redis is running: `sudo systemctl status redis`
   - Verify REDIS_URL in .env
   - Test connection: `redis-cli ping`

3. **SMS Service Error**
   - Check SMS_API_KEY is valid
   - Verify eskiz.uz account status
   - In development, OTP is logged to console

4. **Payment Webhook Issues**
   - Ensure webhook URLs are accessible from internet
   - Check payment provider configuration
   - Verify webhook signatures

### Logs

```bash
# Application logs
poetry run uvicorn app.main:app --log-level info

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-15-main.log

# Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## 📞 Support

For development questions or issues:

1. Check the API documentation at `/docs`
2. Review the error logs
3. Verify environment configuration
4. Test with sample data

## 🗺️ Roadmap

### Phase 1 (Current)
- ✅ Authentication system
- ✅ Database models
- ✅ Basic API structure
- 🔄 Payment integration
- 🔄 File upload system

### Phase 2 (Next)
- Service management
- Search and filtering
- Analytics dashboard
- Review system

### Phase 3 (Future)
- Push notifications
- Advanced analytics
- Mobile app integration
- Performance optimization

---

**Built with ❤️ for the Uzbekistan wedding industry**