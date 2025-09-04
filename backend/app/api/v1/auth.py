from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.services.auth_service import AuthService
from app.schemas.auth import (
    SendOTPRequest,
    SendOTPResponse,
    VerifyOTPRequest,
    VerifyOTPResponse,
    CompleteRegistrationRequest,
    TokenResponse,
    RefreshTokenRequest
)
from app.api.deps import get_current_user
from app.models import User

router = APIRouter()


@router.post("/send-otp", response_model=SendOTPResponse)
async def send_otp(
    request: SendOTPRequest,
    db: AsyncSession = Depends(get_db_session)
):
    """
    Send OTP to phone number for authentication.
    
    Args:
        request: Phone number to send OTP to
        db: Database session
        
    Returns:
        SendOTPResponse: Success message and phone number
    """
    auth_service = AuthService(db)
    result = await auth_service.send_otp(request.phone_number)
    return result


@router.post("/verify-otp", response_model=VerifyOTPResponse)
async def verify_otp(
    request: VerifyOTPRequest,
    db: AsyncSession = Depends(get_db_session)
):
    """
    Verify OTP code and return authentication tokens.
    
    Args:
        request: Phone number and OTP code
        db: Database session
        
    Returns:
        VerifyOTPResponse: Tokens and user status
    """
    auth_service = AuthService(db)
    result = await auth_service.verify_otp(request.phone_number, request.otp_code)
    return result


@router.post("/complete-registration", response_model=TokenResponse)
async def complete_registration(
    request: CompleteRegistrationRequest,
    db: AsyncSession = Depends(get_db_session)
):
    """
    Complete user registration after OTP verification.
    
    Args:
        request: Registration details (name, user_type, category)
        db: Database session
        
    Returns:
        TokenResponse: Authentication tokens
    """
    auth_service = AuthService(db)
    result = await auth_service.complete_registration(
        phone_number=request.phone_number,
        name=request.name,
        user_type=request.user_type,
        # business_category=request.business_category #REMOVE_CATEGORY_FROM_REGISTRATION
    )
    return result


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    request: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db_session)
):
    """
    Refresh access token using refresh token.
    
    Args:
        request: Refresh token
        db: Database session
        
    Returns:
        TokenResponse: New authentication tokens
    """
    auth_service = AuthService(db)
    result = await auth_service.refresh_token(request.refresh_token)
    return result
