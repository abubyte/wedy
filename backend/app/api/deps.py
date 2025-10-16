from typing import Optional
from uuid import UUID
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.database import get_db_session
from app.core.security import verify_token
from app.core.exceptions import HTTPUnauthorized, HTTPForbidden
from app.models import User, UserType, Merchant, MerchantSubscription, SubscriptionStatus

# HTTP Bearer token security
security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db_session)
) -> User:
    """
    Get current authenticated user from JWT token.
    
    Args:
        credentials: Bearer token credentials
        db: Database session
        
    Returns:
        User: Current authenticated user
        
    Raises:
        HTTPUnauthorized: If token is invalid or user not found
    """
    token = credentials.credentials
    payload = verify_token(token)
    
    if not payload:
        raise HTTPUnauthorized("Invalid or expired token")
    
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPUnauthorized("Invalid token payload")
    
    try:
        user_uuid = UUID(user_id)
    except ValueError:
        raise HTTPUnauthorized("Invalid user ID in token")
    
    # Get user from database
    statement = select(User).where(User.id == user_uuid, User.is_active == True)
    result = await db.execute(statement)
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPUnauthorized("User not found or inactive")
    
    return user


async def get_current_client(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Get current client user (non-merchant).
    
    Args:
        current_user: Current authenticated user
        
    Returns:
        User: Current client user
        
    Raises:
        HTTPForbidden: If user is not a client
    """
    if current_user.user_type != UserType.CLIENT:
        raise HTTPForbidden("Client access required")
    
    return current_user


async def get_current_merchant_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Get current merchant user.
    
    Args:
        current_user: Current authenticated user
        
    Returns:
        User: Current merchant user
        
    Raises:
        HTTPForbidden: If user is not a merchant
    """
    if current_user.user_type != UserType.MERCHANT:
        raise HTTPForbidden("Merchant access required")
    
    return current_user


async def get_current_merchant(
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
) -> Merchant:
    """
    Get current merchant profile.
    
    Args:
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        Merchant: Current merchant profile
        
    Raises:
        HTTPForbidden: If merchant profile not found
    """
    statement = select(Merchant).where(Merchant.user_id == current_user.id)
    result = await db.execute(statement)
    merchant = result.scalar_one_or_none()
    
    if not merchant:
        raise HTTPForbidden("Merchant profile not found")
    
    return merchant


async def get_current_active_merchant(
    merchant: Merchant = Depends(get_current_merchant),
    db: AsyncSession = Depends(get_db_session)
) -> Merchant:
    """
    Get current merchant with active subscription.
    
    Args:
        merchant: Current merchant
        db: Database session
        
    Returns:
        Merchant: Current merchant with active subscription
        
    Raises:
        HTTPForbidden: If merchant doesn't have active subscription
    """
    # Check for active subscription
    statement = select(MerchantSubscription).where(
        MerchantSubscription.merchant_id == merchant.id,
        MerchantSubscription.status == SubscriptionStatus.ACTIVE
    )
    result = await db.execute(statement)
    subscription = result.scalar_one_or_none()
    
    if not subscription:
        raise HTTPForbidden("Active subscription required")
    
    return merchant


async def get_current_admin(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Get current admin user.
    
    Args:
        current_user: Current authenticated user
        
    Returns:
        User: Current admin user
        
    Raises:
        HTTPForbidden: If user is not an admin
    """
    if current_user.user_type != UserType.ADMIN:
        raise HTTPForbidden("Admin access required")
    
    return current_user


# Optional authentication (for endpoints that work with or without auth)
async def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer(auto_error=False)),
    db: AsyncSession = Depends(get_db_session)
) -> Optional[User]:
    """
    Get current user if authenticated, None otherwise.
    
    Args:
        credentials: Optional bearer token credentials
        db: Database session
        
    Returns:
        Optional[User]: Current user if authenticated, None otherwise
    """
    if not credentials:
        return None
    
    try:
        return await get_current_user(credentials, db)
    except HTTPException:
        return None