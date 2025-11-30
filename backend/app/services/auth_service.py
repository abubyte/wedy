import random
import string
from datetime import datetime, timedelta
from typing import Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.config import settings
from app.core.security import (
    create_access_token, 
    create_refresh_token, 
    verify_token,
    normalize_phone_number
)
from app.core.exceptions import (
    ValidationError, 
    AuthenticationError, 
    NotFoundError,
    ConflictError
)
from app.models import User, UserType, Merchant, ServiceCategory
from app.schemas.auth_schema import (
    SendOTPResponse, 
    VerifyOTPResponse, 
    TokenResponse
)
from app.services.sms_service import SMSService
from app.utils.redis_client import RedisClient


class AuthService:
    """Authentication service for handling OTP and JWT operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.sms_service = SMSService()
        self.redis_client = RedisClient()
    
    async def send_otp(self, phone_number: str) -> SendOTPResponse:
        """
        Send OTP to phone number.
        
        Args:
            phone_number: Normalized phone number
            
        Returns:
            SendOTPResponse: Success message and details
            
        Raises:
            ValidationError: If phone number is invalid
            SMSError: If SMS sending fails
        """
        # Normalize phone number
        normalized_phone = normalize_phone_number(phone_number)
        
        # Check rate limiting
        attempts_key = f"otp_attempts:{normalized_phone}"
        attempts = await self.redis_client.get(attempts_key)
        
        if attempts and int(attempts) >= settings.OTP_MAX_ATTEMPTS:
            raise ValidationError("Maximum OTP attempts exceeded. Please try again later.")
        
        # Generate OTP
        otp_code = self._generate_otp() if not settings.DEBUG else '123456'
        
        # Store OTP in Redis with expiration
        otp_key = f"otp:{normalized_phone}"
        await self.redis_client.setex(
            otp_key, 
            settings.OTP_EXPIRE_MINUTES * 60, 
            otp_code
        )
        
        # Increment attempts counter
        await self.redis_client.incr(attempts_key)
        await self.redis_client.expire(attempts_key, 3600)  # 1 hour
        
        # Send SMS
        await self.sms_service.send_otp(normalized_phone, otp_code)
        
        return SendOTPResponse(
            message="OTP sent successfully",
            phone_number=normalized_phone,
            expires_in=settings.OTP_EXPIRE_MINUTES
        )
    
    async def verify_otp(self, phone_number: str, otp_code: str) -> VerifyOTPResponse:
        """
        Verify OTP code and return tokens if user exists.
        
        Args:
            phone_number: Normalized phone number
            otp_code: OTP code to verify
            
        Returns:
            VerifyOTPResponse: Verification result and tokens
            
        Raises:
            AuthenticationError: If OTP is invalid or expired
        """
        # Normalize phone number
        normalized_phone = normalize_phone_number(phone_number)
        
        # Get stored OTP
        otp_key = f"otp:{normalized_phone}"
        stored_otp = await self.redis_client.get(otp_key)
        
        if not stored_otp or stored_otp != otp_code:
            raise AuthenticationError("Invalid or expired OTP")
        
        # Remove OTP and attempts after successful verification
        await self.redis_client.delete(otp_key)
        await self.redis_client.delete(f"otp_attempts:{normalized_phone}")
        
        # Check if user exists
        statement = select(User).where(User.phone_number == normalized_phone)
        result = await self.db.execute(statement)
        user = result.scalar_one_or_none()
        
        if user:
            # Existing user - return tokens
            if not user.is_active:
                raise AuthenticationError("Account is deactivated")
            
            access_token = create_access_token(str(user.id))
            refresh_token = create_refresh_token(str(user.id))
            
            return VerifyOTPResponse(
                is_new_user=False,
                access_token=access_token,
                refresh_token=refresh_token,
                expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES,
                message="Authentication successful"
            )
        else:
            # New user - needs registration
            return VerifyOTPResponse(
                is_new_user=True,
                message="Registration required"
            )
    
    async def complete_registration(
        self, 
        phone_number: str, 
        name: str, 
        user_type: UserType,
        # business_category: Optional[str] = None #REMOVE_CATEGORY_FROM_REGISTRATION
    ) -> TokenResponse:
        """
        Complete user registration after OTP verification.
        
        Args:
            phone_number: Normalized phone number
            name: User's full name
            user_type: Type of user account
            business_category: Business category for merchants
            
        Returns:
            TokenResponse: Authentication tokens
            
        Raises:
            ConflictError: If user already exists
            ValidationError: If category is invalid for merchant
        """
        # Normalize phone number
        normalized_phone = normalize_phone_number(phone_number)
        
        # Check if user already exists
        statement = select(User).where(User.phone_number == normalized_phone)
        result = await self.db.execute(statement)
        existing_user = result.scalar_one_or_none()
        
        if existing_user:
            raise ConflictError("User already exists")
        
        # For merchants, validate business category #REMOVE_CATEGORY_FROM_REGISTRATION
        # if user_type == UserType.MERCHANT:
        #     if not business_category:
        #         raise ValidationError("Business category is required for merchants")
            
        #     # Check if category exists
        #     category_statement = select(ServiceCategory).where(
        #         ServiceCategory.name == business_category,
        #         ServiceCategory.is_active == True
        #     )
        #     category_result = await self.db.execute(category_statement)
        #     category = category_result.first()
            
        #     if not category:
        #         raise ValidationError("Invalid business category")
        
        # Create user
        user = User(
            phone_number=normalized_phone,
            name=name.strip(),
            user_type=user_type
        )
        
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        
        # For merchants, create merchant profile
        if user_type == UserType.MERCHANT:
            merchant = Merchant(
                user_id=user.id,
                business_name=name.strip(),  # Default to user name
                location_region="Tashkent"  # Default region
            )
            
            self.db.add(merchant)
            await self.db.commit()
        
        # Generate tokens
        access_token = create_access_token(str(user.id))
        refresh_token = create_refresh_token(str(user.id))
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    
    async def refresh_token(self, refresh_token: str) -> TokenResponse:
        """
        Refresh access token using refresh token.
        
        Args:
            refresh_token: JWT refresh token
            
        Returns:
            TokenResponse: New authentication tokens
            
        Raises:
            AuthenticationError: If refresh token is invalid
        """
        # Verify refresh token
        payload = verify_token(refresh_token)
        
        if not payload or payload.get("type") != "refresh":
            raise AuthenticationError("Invalid refresh token")
        
        user_id = payload.get("sub")
        if not user_id:
            raise AuthenticationError("Invalid token payload")
        
        try:
            user_uuid = UUID(user_id)
        except ValueError:
            raise AuthenticationError("Invalid user ID in token")
        
        # Verify user exists and is active
        statement = select(User).where(User.id == user_uuid, User.is_active == True)
        result = await self.db.execute(statement)
        user = result.scalar_one_or_none()
        
        if not user:
            raise AuthenticationError("User not found or inactive")
        
        # Generate new tokens
        new_access_token = create_access_token(str(user.id))
        new_refresh_token = create_refresh_token(str(user.id))
        
        return TokenResponse(
            access_token=new_access_token,
            refresh_token=new_refresh_token,
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    
    def _generate_otp(self) -> str:
        """
        Generate a random OTP code.
        
        Returns:
            str: 6-digit OTP code
        """
        return ''.join(random.choices(string.digits, k=6))