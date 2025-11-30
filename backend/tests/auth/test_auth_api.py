"""
Tests for Auth API endpoints.
"""
import os

# Set required environment variables before importing any app modules
os.environ.setdefault("ESKIZ_EMAIL", "test@example.com")
os.environ.setdefault("ESKIZ_PASSWORD", "test_password")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")
os.environ.setdefault("JWT_SECRET_KEY", "test_secret_key")
os.environ.setdefault("JWT_REFRESH_SECRET_KEY", "test_refresh_secret_key")
os.environ.setdefault("ACCESS_TOKEN_EXPIRE_MINUTES", "30")
os.environ.setdefault("REFRESH_TOKEN_EXPIRE_DAYS", "7")
os.environ.setdefault("OTP_EXPIRE_MINUTES", "5")
os.environ.setdefault("OTP_MAX_ATTEMPTS", "5")
os.environ.setdefault("DEBUG", "True")

import pytest
import random
from uuid import uuid4
from httpx import AsyncClient
from unittest.mock import AsyncMock, MagicMock, patch

from app.models import User, UserType


# Create a test FastAPI app
@pytest.fixture
async def test_app(db_session):
    """Create a FastAPI test application."""
    from fastapi.responses import JSONResponse
    from app.core.exceptions import WedyException, NotFoundError, ConflictError, ValidationError, ForbiddenError, PaymentRequiredError, AuthenticationError
    from fastapi import HTTPException, status, Request
    from fastapi import FastAPI
    
    app = FastAPI()
    from app.api.v1 import auth
    app.include_router(auth.router, prefix="/api/v1/auth", tags=["Auth"])
    
    # Override database session dependency
    from app.core.database import get_db_session
    async def override_get_db_session():
        yield db_session
    
    app.dependency_overrides[get_db_session] = override_get_db_session
    
    # Mock Redis and SMS services
    with patch('app.services.auth_service.RedisClient') as MockRedisClient, \
         patch('app.services.auth_service.SMSService') as MockSMSService:
        
        # Create mock Redis client
        mock_redis = AsyncMock()
        mock_redis.get = AsyncMock(return_value=None)
        mock_redis.setex = AsyncMock(return_value=True)
        mock_redis.incr = AsyncMock(return_value=1)
        mock_redis.expire = AsyncMock(return_value=True)
        mock_redis.delete = AsyncMock(return_value=1)
        
        # Create mock RedisClient instance
        mock_redis_client_instance = MagicMock()
        mock_redis_client_instance.get = mock_redis.get
        mock_redis_client_instance.setex = mock_redis.setex
        mock_redis_client_instance.incr = mock_redis.incr
        mock_redis_client_instance.expire = mock_redis.expire
        mock_redis_client_instance.delete = mock_redis.delete
        
        MockRedisClient.return_value = mock_redis_client_instance
        
        # Create mock SMS service
        mock_sms = AsyncMock()
        mock_sms.send_otp = AsyncMock(return_value=True)
        MockSMSService.return_value = mock_sms
        
        # Store mocks in app state for later access
        app.state.mock_redis = mock_redis_client_instance
        app.state.mock_sms = mock_sms
        
        # Add exception handlers (same as main.py)
        @app.exception_handler(WedyException)
        async def wedy_exception_handler(request: Request, exc: WedyException) -> JSONResponse:
            from app.core.exceptions import map_exception_to_http
            http_exc = map_exception_to_http(exc)
            return JSONResponse(
                status_code=http_exc.status_code,
                content={
                    "error": {
                        "message": exc.message,
                        "details": exc.details,
                        "type": exc.__class__.__name__
                    }
                }
            )
        
        @app.exception_handler(HTTPException)
        async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
            return JSONResponse(
                status_code=exc.status_code,
                content={
                    "error": {
                        "message": exc.detail,
                        "type": "HTTPException"
                    }
                }
            )
        
        yield app
        
        # Clean up overrides
        app.dependency_overrides.clear()


@pytest.fixture
async def client(test_app):
    """Create an unauthenticated async client."""
    async with AsyncClient(app=test_app, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
class TestAuthAPI:
    """Test Auth API endpoints."""
    
    async def test_send_otp_success(
        self,
        test_app,
        client
    ):
        """Test POST /send-otp (send OTP successfully)."""
        mock_redis = test_app.state.mock_redis
        mock_redis.get.return_value = None  # No rate limit
        
        response = await client.post(
            "/api/v1/auth/send-otp",
            json={
                "phone_number": "998901234567"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "OTP sent successfully"
        assert data["phone_number"] == "901234567"  # Normalized
        assert "expires_in" in data
    
    async def test_send_otp_rate_limit_exceeded(
        self,
        test_app,
        client
    ):
        """Test POST /send-otp (rate limit exceeded)."""
        mock_redis = test_app.state.mock_redis
        mock_redis.get.return_value = "5"  # Max attempts
        
        response = await client.post(
            "/api/v1/auth/send-otp",
            json={
                "phone_number": "998901234567"
            }
        )
        
        assert response.status_code in [400, 422]
        error_data = response.json()
        assert "error" in error_data or "maximum" in str(error_data).lower()
    
    async def test_verify_otp_new_user(
        self,
        test_app,
        client,
        db_session
    ):
        """Test POST /verify-otp (new user, needs registration)."""
        mock_redis = test_app.state.mock_redis
        mock_redis.get.return_value = "123456"  # OTP stored
        
        unique_phone = f"90{random.randint(1000000, 9999999)}"
        
        response = await client.post(
            "/api/v1/auth/verify-otp",
            json={
                "phone_number": f"998{unique_phone}",
                "otp_code": "123456"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["is_new_user"] is True
        assert data["message"] == "Registration required"
        assert data.get("access_token") is None
    
    async def test_verify_otp_existing_user(
        self,
        test_app,
        client,
        sample_client_user
    ):
        """Test POST /verify-otp (existing user, returns tokens)."""
        mock_redis = test_app.state.mock_redis
        mock_redis.get.return_value = "123456"  # OTP stored
        
        response = await client.post(
            "/api/v1/auth/verify-otp",
            json={
                "phone_number": f"998{sample_client_user.phone_number}",
                "otp_code": "123456"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["is_new_user"] is False
        assert data["access_token"] is not None
        assert data["refresh_token"] is not None
        assert data["message"] == "Authentication successful"
    
    async def test_verify_otp_invalid_code(
        self,
        test_app,
        client
    ):
        """Test POST /verify-otp (invalid OTP code)."""
        mock_redis = test_app.state.mock_redis
        mock_redis.get.return_value = "123456"  # Stored OTP
        
        response = await client.post(
            "/api/v1/auth/verify-otp",
            json={
                "phone_number": "998901234567",
                "otp_code": "000000"  # Wrong code
            }
        )
        
        assert response.status_code in [401, 403]
        error_data = response.json()
        assert "error" in error_data
    
    async def test_verify_otp_expired(
        self,
        test_app,
        client
    ):
        """Test POST /verify-otp (expired OTP)."""
        mock_redis = test_app.state.mock_redis
        mock_redis.get.return_value = None  # OTP expired/not found
        
        response = await client.post(
            "/api/v1/auth/verify-otp",
            json={
                "phone_number": "998901234567",
                "otp_code": "123456"
            }
        )
        
        assert response.status_code in [401, 403]
        error_data = response.json()
        assert "error" in error_data
    
    async def test_complete_registration_client(
        self,
        test_app,
        client,
        db_session
    ):
        """Test POST /complete-registration (client user)."""
        unique_phone = f"90{random.randint(1000000, 9999999)}"
        
        response = await client.post(
            "/api/v1/auth/complete-registration",
            json={
                "phone_number": f"998{unique_phone}",
                "name": "Test Client",
                "user_type": "client"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["access_token"] is not None
        assert data["refresh_token"] is not None
        
        # Verify user was created
        from sqlalchemy import select
        statement = select(User).where(User.phone_number == unique_phone)
        result = await db_session.execute(statement)
        user = result.scalar_one_or_none()
        assert user is not None
        assert user.user_type == UserType.CLIENT
    
    async def test_complete_registration_merchant(
        self,
        test_app,
        client,
        db_session
    ):
        """Test POST /complete-registration (merchant user)."""
        unique_phone = f"90{random.randint(1000000, 9999999)}"
        
        response = await client.post(
            "/api/v1/auth/complete-registration",
            json={
                "phone_number": f"998{unique_phone}",
                "name": "Test Merchant",
                "user_type": "merchant"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["access_token"] is not None
        assert data["refresh_token"] is not None
        
        # Verify user and merchant were created
        from sqlalchemy import select
        from app.models import Merchant
        statement = select(User).where(User.phone_number == unique_phone)
        result = await db_session.execute(statement)
        user = result.scalar_one_or_none()
        assert user is not None
        assert user.user_type == UserType.MERCHANT
        
        merchant_stmt = select(Merchant).where(Merchant.user_id == user.id)
        merchant_result = await db_session.execute(merchant_stmt)
        merchant = merchant_result.scalar_one_or_none()
        assert merchant is not None
    
    async def test_complete_registration_user_exists(
        self,
        test_app,
        client,
        sample_client_user
    ):
        """Test POST /complete-registration (user already exists)."""
        response = await client.post(
            "/api/v1/auth/complete-registration",
            json={
                "phone_number": f"998{sample_client_user.phone_number}",
                "name": "New Name",
                "user_type": "client"
            }
        )
        
        assert response.status_code in [400, 409]  # Conflict
        error_data = response.json()
        assert "error" in error_data
    
    async def test_refresh_token_success(
        self,
        test_app,
        client,
        sample_client_user
    ):
        """Test POST /refresh (refresh token successfully)."""
        from app.core.security import create_refresh_token
        
        refresh_token = create_refresh_token(str(sample_client_user.id))
        
        response = await client.post(
            "/api/v1/auth/refresh",
            json={
                "refresh_token": refresh_token
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["access_token"] is not None
        assert data["refresh_token"] is not None
        assert data["expires_in"] > 0
    
    async def test_refresh_token_invalid(
        self,
        test_app,
        client
    ):
        """Test POST /refresh (invalid refresh token)."""
        response = await client.post(
            "/api/v1/auth/refresh",
            json={
                "refresh_token": "invalid_token"
            }
        )
        
        assert response.status_code in [401, 403]
        error_data = response.json()
        assert "error" in error_data
    
    async def test_invalid_phone_number(
        self,
        test_app,
        client
    ):
        """Test POST /send-otp (invalid phone number format)."""
        response = await client.post(
            "/api/v1/auth/send-otp",
            json={
                "phone_number": "123"  # Invalid
            }
        )
        
        assert response.status_code == 422  # Validation error
        error_data = response.json()
        assert "error" in error_data or "detail" in error_data
    
    async def test_invalid_otp_code(
        self,
        test_app,
        client
    ):
        """Test POST /verify-otp (invalid OTP code format)."""
        response = await client.post(
            "/api/v1/auth/verify-otp",
            json={
                "phone_number": "998901234567",
                "otp_code": "12"  # Too short
            }
        )
        
        assert response.status_code == 422  # Validation error
        error_data = response.json()
        assert "error" in error_data or "detail" in error_data

