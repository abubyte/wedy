from fastapi import APIRouter, Depends, HTTPException, status, Form, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.api.deps import get_current_user
from app.models import User
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserProfileResponse, UserProfileUpdateRequest
from app.core.exceptions import ValidationError, ConflictError
from app.core.security import verify_phone_number, normalize_phone_number
from app.models import UserType
from app.services.merchant_manager import MerchantManager
from app.utils.s3_client import s3_image_manager
from app.schemas.merchant import ImageUploadResponse

router = APIRouter()


@router.get("/profile", response_model=UserProfileResponse)
async def get_user_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session)
):
    """Get current user profile."""
    return UserProfileResponse(
        id=current_user.id,
        phone_number=current_user.phone_number,
        name=current_user.name,
        avatar_url=current_user.avatar_url,
        user_type=current_user.user_type,
        created_at=current_user.created_at
    )


@router.put("/profile", response_model=UserProfileResponse)
async def update_user_profile(
    profile_data: UserProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session)
):
    """Update user profile (name and phone number)."""
    user_repo = UserRepository(db)

    try:
        # Update phone number if provided
        if profile_data.phone_number is not None:
            # validator in schema already normalizes, but double-check
            if not verify_phone_number(profile_data.phone_number):
                raise ValidationError("Invalid phone number format")

            normalized = normalize_phone_number(profile_data.phone_number)

            taken = await user_repo.is_phone_number_taken(
                normalized, exclude_user_id=current_user.id
            )
            if taken:
                raise ConflictError("Phone number is already taken")

            current_user.phone_number = normalized

        # Update name if provided
        if profile_data.name is not None:
            current_user.name = profile_data.name.strip()

        # Persist changes
        await user_repo.update(current_user)

        return UserProfileResponse(
            id=current_user.id,
            phone_number=current_user.phone_number,
            name=current_user.name,
            avatar_url=current_user.avatar_url,
            user_type=current_user.user_type,
            created_at=current_user.created_at
        )

    except ValidationError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except ConflictError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))


@router.post("/avatar")
async def upload_avatar(
    file: UploadFile = File(..., description="Avatar image file"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session)
):
    """Upload user avatar directly to S3 and update user's avatar_url."""
    try:
        # Read a small amount to validate content type and size
        content = await file.read()
        content_type = file.content_type or 'application/octet-stream'
        content_length = len(content)

        # Validate image constraints
        s3_image_manager.validate_image_constraints(content_type, content_length)

        # Upload file object to S3
        # Create a BytesIO stream from content for upload_fileobj
        from io import BytesIO
        fileobj = BytesIO(content)

        s3_url = s3_image_manager.upload_fileobj(
            fileobj=fileobj,
            file_name=file.filename,
            content_type=content_type,
            image_type="user_avatar",
            related_id=str(current_user.id)
        )

        # Persist avatar URL on user
        user_repo = UserRepository(db)
        current_user.avatar_url = s3_url
        await user_repo.update(current_user)

        return ImageUploadResponse(
            success=True,
            message="Avatar uploaded successfully",
            s3_url=s3_url,
            presigned_url=None
        )

    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Avatar upload failed: {str(e)}")


@router.get("/interactions")
async def get_user_interactions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session)
):
    """Get user's liked/saved services."""
    # TODO: Implement user interactions retrieval
    return {"message": "User interactions endpoint - TODO"}