from fastapi import APIRouter, Depends, HTTPException, status, Form, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.api.deps import get_current_user, get_current_client
from app.models import User
from app.repositories.user_repository import UserRepository
from app.schemas.user_schema import UserProfileResponse, UserProfileUpdateRequest, UserInteractionsResponse
from app.schemas.common_schema import SuccessResponse
from app.core.exceptions import ValidationError, ConflictError, NotFoundError, AuthenticationError
from app.core.security import verify_phone_number, normalize_phone_number
from app.models import UserType
from app.services.merchant_manager import MerchantManager
from app.services.auth_service import AuthService
from app.utils.s3_client import s3_image_manager
from app.schemas.merchant_schema import ImageUploadResponse

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
    auth_service = AuthService(db)

    try:
        # Update phone number if provided
        if profile_data.phone_number is not None:
            # Check if phone number is actually changing
            normalized = normalize_phone_number(profile_data.phone_number)
            if normalized != current_user.phone_number:
                # Phone number is changing - require OTP verification
                if not profile_data.otp_code:
                    raise ValidationError("OTP code is required when changing phone number")
                
                # Verify OTP for the new phone number
                try:
                    await auth_service.verify_otp_only(normalized, profile_data.otp_code)
                except AuthenticationError as e:
                    raise ValidationError(f"OTP verification failed: {str(e)}")
                
                # Check if new phone number is already taken
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
    except AuthenticationError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))


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


@router.delete("/avatar", response_model=SuccessResponse)
async def delete_avatar(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session)
):
    """Delete user avatar from S3 and clear avatar_url."""
    try:
        user_repo = UserRepository(db)

        # Delete from S3 if exists
        if current_user.avatar_url:
            try:
                s3_image_manager.delete_image(current_user.avatar_url)
            except Exception:
                # Log error but continue - S3 deletion is not critical
                pass

        # Clear avatar URL
        current_user.avatar_url = None
        await user_repo.update(current_user)

        return SuccessResponse(
            success=True,
            message="Avatar deleted successfully"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Avatar deletion failed: {str(e)}"
        )


@router.get("/interactions", response_model=UserInteractionsResponse)
async def get_user_interactions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get user's liked and saved services.
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        UserInteractionsResponse: List of liked and saved services
    """
    try:
        from app.repositories.service_repository import ServiceRepository
        from app.services.service_manager import ServiceManager
        from app.models import InteractionType
        from app.schemas.user_schema import UserInteractionItem
        
        service_repo = ServiceRepository(db)
        service_manager = ServiceManager(db)
        
        # Get all user interactions (likes and saves)
        interactions = await service_repo.get_user_interactions(current_user.id)
        
        # Separate liked and saved services
        liked_items = []
        saved_items = []
        
        for interaction, service in interactions:
            # Convert service to ServiceListItem with user_id to get interaction status
            service_item = await service_manager._convert_to_service_list_item(service, user_id=current_user.id)
            
            # Explicitly set interaction status based on interaction type
            # Pydantic models allow attribute assignment in newer versions
            if interaction.interaction_type == InteractionType.LIKE:
                # For liked services, ensure is_liked is True
                service_item.is_liked = True
                service_item.is_saved = False  # Clear save status for liked items
            elif interaction.interaction_type == InteractionType.SAVE:
                # For saved services, ensure is_saved is True
                service_item.is_saved = True
                service_item.is_liked = False  # Clear like status for saved items
            
            interaction_item = UserInteractionItem(
                interaction_type=interaction.interaction_type,
                interacted_at=interaction.created_at,
                service=service_item
            )
            
            if interaction.interaction_type == InteractionType.LIKE:
                liked_items.append(interaction_item)
            elif interaction.interaction_type == InteractionType.SAVE:
                saved_items.append(interaction_item)
        
        return UserInteractionsResponse(
            liked_services=liked_items,
            saved_services=saved_items,
            total_liked=len(liked_items),
            total_saved=len(saved_items)
        )
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve user interactions: {str(e)}"
        )


@router.delete("/profile", response_model=SuccessResponse)
async def delete_user_account(
    current_user: User = Depends(get_current_client),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Delete client user account (soft delete).
    
    Only client users can delete their own accounts.
    This performs a soft delete by setting is_active=False to preserve data integrity.
    Related data (payments, reviews, interactions) will remain for historical records.
    
    Args:
        current_user: Current authenticated client user (enforced by get_current_client)
        db: Database session
        
    Returns:
        SuccessResponse: Confirmation of account deletion
        
    Raises:
        HTTPException: If deletion fails
    """
    try:
        user_repo = UserRepository(db)
        
        # Perform soft delete
        deleted = await user_repo.soft_delete_user(current_user.id)
        
        if not deleted:
            raise NotFoundError("User account not found")
        
        return SuccessResponse(
            success=True,
            message="User account deleted successfully"
        )
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=e.message
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete user account: {str(e)}"
        )