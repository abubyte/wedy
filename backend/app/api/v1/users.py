from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.api.deps import get_current_user
from app.models import User

router = APIRouter()


@router.get("/profile")
async def get_user_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session)
):
    """Get current user profile."""
    return {
        "id": current_user.id,
        "phone_number": current_user.phone_number,
        "name": current_user.name,
        "avatar_url": current_user.avatar_url,
        "user_type": current_user.user_type,
        "created_at": current_user.created_at
    }


@router.put("/profile")
async def update_user_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session)
):
    """Update user profile."""
    # TODO: Implement profile update logic
    return {"message": "Profile update endpoint - TODO"}


@router.post("/avatar")
async def upload_avatar(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session)
):
    """Upload user avatar."""
    # TODO: Implement avatar upload logic
    return {"message": "Avatar upload endpoint - TODO"}


@router.get("/interactions")
async def get_user_interactions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session)
):
    """Get user's liked/saved services."""
    # TODO: Implement user interactions retrieval
    return {"message": "User interactions endpoint - TODO"}