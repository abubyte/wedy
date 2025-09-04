from typing import Optional
from pydantic import BaseModel, Field, validator

from app.models import UserType
from app.core.security import verify_phone_number, normalize_phone_number


class SendOTPRequest(BaseModel):
    """Request model for sending OTP."""
    
    phone_number: str = Field(
        ..., 
        description="Phone number (9 digits, Uzbekistan format)",
        example="901234567"
    )
    
    @validator('phone_number')
    def validate_phone_number(cls, v):
        if not verify_phone_number(v):
            raise ValueError('Invalid Uzbekistan phone number format')
        return normalize_phone_number(v)


class SendOTPResponse(BaseModel):
    """Response model for sending OTP."""
    
    message: str = Field(..., description="Success message")
    phone_number: str = Field(..., description="Normalized phone number")
    expires_in: int = Field(..., description="OTP expiration time in minutes")


class VerifyOTPRequest(BaseModel):
    """Request model for verifying OTP."""
    
    phone_number: str = Field(
        ..., 
        description="Phone number (9 digits, Uzbekistan format)",
        example="901234567"
    )
    otp_code: str = Field(
        ..., 
        description="OTP code received via SMS",
        min_length=4,
        max_length=6,
        example="123456"
    )
    
    @validator('phone_number')
    def validate_phone_number(cls, v):
        if not verify_phone_number(v):
            raise ValueError('Invalid Uzbekistan phone number format')
        return normalize_phone_number(v)
    
    @validator('otp_code')
    def validate_otp_code(cls, v):
        if not v.isdigit():
            raise ValueError('OTP code must contain only digits')
        return v


class TokenResponse(BaseModel):
    """Response model for authentication tokens."""
    
    access_token: str = Field(..., description="JWT access token")
    refresh_token: str = Field(..., description="JWT refresh token")
    token_type: str = Field(default="bearer", description="Token type")
    expires_in: int = Field(..., description="Access token expiration time in minutes")


class VerifyOTPResponse(BaseModel):
    """Response model for OTP verification."""
    
    is_new_user: bool = Field(..., description="Whether user is new and needs registration")
    access_token: Optional[str] = Field(None, description="JWT access token (if existing user)")
    refresh_token: Optional[str] = Field(None, description="JWT refresh token (if existing user)")
    token_type: str = Field(default="bearer", description="Token type")
    expires_in: Optional[int] = Field(None, description="Access token expiration time in minutes")
    message: str = Field(..., description="Status message")


class CompleteRegistrationRequest(BaseModel):
    """Request model for completing user registration."""
    
    phone_number: str = Field(
        ..., 
        description="Phone number (must match OTP verification)",
        example="901234567"
    )
    name: str = Field(
        ..., 
        description="User's full name",
        min_length=2,
        max_length=255,
        example="John Doe"
    )
    user_type: UserType = Field(
        ..., 
        description="Type of user account"
    )
    # business_category: Optional[str] = Field( #REMOVE_CATEGORY_FROM_REGISTRATION
    #     None, 
    #     description="Business category (required for merchants)",
    #     example="Photography"
    # )
    
    @validator('phone_number')
    def validate_phone_number(cls, v):
        if not verify_phone_number(v):
            raise ValueError('Invalid Uzbekistan phone number format')
        return normalize_phone_number(v)
    
    @validator('name')
    def validate_name(cls, v):
        v = v.strip()
        if len(v) < 2:
            raise ValueError('Name must be at least 2 characters long')
        return v
    
    # @validator('business_category') #REMOVE_CATEGORY_FROM_REGISTRATION
    # def validate_business_category(cls, v, values):
    #     user_type = values.get('user_type')
    #     if user_type == UserType.MERCHANT and not v:
    #         raise ValueError('Business category is required for merchants')
    #     if user_type != UserType.MERCHANT and v:
    #         raise ValueError('Business category is only allowed for merchants')
    #     return v


class RefreshTokenRequest(BaseModel):
    """Request model for refreshing access token."""
    
    refresh_token: str = Field(
        ..., 
        description="JWT refresh token"
    )