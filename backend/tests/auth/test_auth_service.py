"""
Tests for AuthService.
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
from uuid import uuid4
from unittest.mock import AsyncMock, MagicMock, patch

from app.services.auth_service import AuthService
from app.core.exceptions import ValidationError, AuthenticationError, ConflictError
from app.models import User, UserType, Merchant


@pytest.fixture
async def auth_service(db_session):
    """Create AuthService instance with mocked dependencies."""
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
        
        service = AuthService(db_session)
        service.redis_client = mock_redis_client_instance
        service.sms_service = mock_sms
        
        yield service, mock_redis_client_instance, mock_sms


@pytest.mark.asyncio
class TestAuthService:
    """Test AuthService methods."""
    
    async def test_send_otp_success(
        self,
        auth_service,
        db_session
    ):
        """Test sending OTP successfully."""
        service, mock_redis, mock_sms = auth_service
        
        # Mock Redis to return no attempts
        mock_redis.get.return_value = None
        
        result = await service.send_otp("998901234567")
        
        assert result.message == "OTP sent successfully"
        assert result.phone_number == "901234567"  # Normalized
        assert mock_redis.setex.called
        assert mock_redis.incr.called
        assert mock_sms.send_otp.called
    
    async def test_send_otp_rate_limit_exceeded(
        self,
        auth_service,
        db_session
    ):
        """Test sending OTP when rate limit is exceeded."""
        service, mock_redis, mock_sms = auth_service
        
        # Mock Redis to return max attempts
        mock_redis.get.return_value = "5"  # OTP_MAX_ATTEMPTS
        
        with pytest.raises(ValidationError, match="Maximum OTP attempts"):
            await service.send_otp("998901234567")
        
        assert not mock_redis.setex.called
        assert not mock_sms.send_otp.called
    
    async def test_verify_otp_new_user(
        self,
        auth_service,
        db_session
    ):
        """Test verifying OTP for new user (not registered)."""
        service, mock_redis, mock_sms = auth_service
        
        # Mock Redis to return OTP
        mock_redis.get.return_value = "123456"
        
        # No user exists in DB
        result = await service.verify_otp("998901234567", "123456")
        
        assert result.is_new_user is True
        assert result.message == "Registration required"
        assert result.access_token is None
        assert mock_redis.delete.called
    
    async def test_verify_otp_existing_user(
        self,
        auth_service,
        db_session,
        sample_client_user
    ):
        """Test verifying OTP for existing user."""
        service, mock_redis, mock_sms = auth_service
        
        # Mock Redis to return OTP
        mock_redis.get.return_value = "123456"
        
        result = await service.verify_otp(sample_client_user.phone_number, "123456")
        
        assert result.is_new_user is False
        assert result.access_token is not None
        assert result.refresh_token is not None
        assert result.message == "Authentication successful"
        assert mock_redis.delete.called
    
    async def test_verify_otp_invalid_code(
        self,
        auth_service,
        db_session
    ):
        """Test verifying OTP with invalid code."""
        service, mock_redis, mock_sms = auth_service
        
        # Mock Redis to return different OTP
        mock_redis.get.return_value = "123456"
        
        with pytest.raises(AuthenticationError, match="Invalid or expired OTP"):
            await service.verify_otp("998901234567", "000000")
    
    async def test_verify_otp_expired(
        self,
        auth_service,
        db_session
    ):
        """Test verifying OTP when expired (not in Redis)."""
        service, mock_redis, mock_sms = auth_service
        
        # Mock Redis to return None (expired)
        mock_redis.get.return_value = None
        
        with pytest.raises(AuthenticationError, match="Invalid or expired OTP"):
            await service.verify_otp("998901234567", "123456")
    
    async def test_verify_otp_inactive_user(
        self,
        auth_service,
        db_session
    ):
        """Test verifying OTP for inactive user."""
        import random
        service, mock_redis, mock_sms = auth_service
        
        # Create inactive user with unique phone number
        unique_phone = f"90{random.randint(1000000, 9999999)}"
        inactive_user = User(
            phone_number=unique_phone,
            name="Inactive User",
            user_type=UserType.CLIENT,
            is_active=False
        )
        db_session.add(inactive_user)
        await db_session.commit()
        await db_session.refresh(inactive_user)
        
        # Mock Redis to return OTP
        mock_redis.get.return_value = "123456"
        
        with pytest.raises(AuthenticationError, match="Account is deactivated"):
            await service.verify_otp(f"998{unique_phone}", "123456")
    
    async def test_complete_registration_client(
        self,
        auth_service,
        db_session
    ):
        """Test completing registration for client user."""
        import random
        service, mock_redis, mock_sms = auth_service
        
        # Use unique phone number
        unique_phone = f"90{random.randint(1000000, 9999999)}"
        result = await service.complete_registration(
            phone_number=f"998{unique_phone}",
            name="Test Client",
            user_type=UserType.CLIENT
        )
        
        assert result.access_token is not None
        assert result.refresh_token is not None
        
        # Verify user was created
        from sqlalchemy import select
        statement = select(User).where(User.phone_number == unique_phone)
        result_query = await db_session.execute(statement)
        user = result_query.scalar_one_or_none()
        assert user is not None
        assert user.name == "Test Client"
        assert user.user_type == UserType.CLIENT
    
    async def test_complete_registration_merchant(
        self,
        auth_service,
        db_session
    ):
        """Test completing registration for merchant user."""
        import random
        service, mock_redis, mock_sms = auth_service
        
        # Use unique phone number
        unique_phone = f"90{random.randint(1000000, 9999999)}"
        result = await service.complete_registration(
            phone_number=f"998{unique_phone}",
            name="Test Merchant",
            user_type=UserType.MERCHANT
        )
        
        assert result.access_token is not None
        assert result.refresh_token is not None
        
        # Verify user was created
        from sqlalchemy import select
        statement = select(User).where(User.phone_number == unique_phone)
        result_query = await db_session.execute(statement)
        user = result_query.scalar_one_or_none()
        assert user is not None
        assert user.user_type == UserType.MERCHANT
        
        # Verify merchant profile was created
        merchant_stmt = select(Merchant).where(Merchant.user_id == user.id)
        merchant_result = await db_session.execute(merchant_stmt)
        merchant = merchant_result.scalar_one_or_none()
        assert merchant is not None
        assert merchant.business_name == "Test Merchant"
    
    async def test_complete_registration_user_exists(
        self,
        auth_service,
        db_session,
        sample_client_user
    ):
        """Test completing registration when user already exists."""
        service, mock_redis, mock_sms = auth_service
        
        with pytest.raises(ConflictError, match="User already exists"):
            await service.complete_registration(
                phone_number=sample_client_user.phone_number,
                name="New Name",
                user_type=UserType.CLIENT
            )
    
    async def test_refresh_token_success(
        self,
        auth_service,
        db_session,
        sample_client_user
    ):
        """Test refreshing access token successfully."""
        from app.core.security import create_refresh_token
        
        service, mock_redis, mock_sms = auth_service
        
        # Create valid refresh token
        refresh_token = create_refresh_token(str(sample_client_user.id))
        
        result = await service.refresh_token(refresh_token)
        
        assert result.access_token is not None
        assert result.refresh_token is not None
        assert result.expires_in > 0
    
    async def test_refresh_token_invalid_token(
        self,
        auth_service,
        db_session
    ):
        """Test refreshing token with invalid refresh token."""
        service, mock_redis, mock_sms = auth_service
        
        with pytest.raises(AuthenticationError, match="Invalid refresh token"):
            await service.refresh_token("invalid_token")
    
    async def test_refresh_token_inactive_user(
        self,
        auth_service,
        db_session
    ):
        """Test refreshing token for inactive user."""
        import random
        from app.core.security import create_refresh_token
        
        service, mock_redis, mock_sms = auth_service
        
        # Create inactive user with unique phone number
        unique_phone = f"90{random.randint(1000000, 9999999)}"
        inactive_user = User(
            phone_number=unique_phone,
            name="Inactive User",
            user_type=UserType.CLIENT,
            is_active=False
        )
        db_session.add(inactive_user)
        await db_session.commit()
        await db_session.refresh(inactive_user)
        
        # Create refresh token for inactive user
        refresh_token = create_refresh_token(str(inactive_user.id))
        
        with pytest.raises(AuthenticationError, match="User not found or inactive"):
            await service.refresh_token(refresh_token)
    
    async def test_phone_number_normalization(
        self,
        auth_service,
        db_session
    ):
        """Test phone number normalization in send_otp."""
        service, mock_redis, mock_sms = auth_service
        
        mock_redis.get.return_value = None
        
        # Test various phone number formats
        result = await service.send_otp("998901234567")
        assert result.phone_number == "901234567"
        
        result = await service.send_otp("+998901234567")
        assert result.phone_number == "901234567"
        
        result = await service.send_otp("901234567")
        assert result.phone_number == "901234567"

