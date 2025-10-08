from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Form, UploadFile, File, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.services.merchant_manager import MerchantManager
from app.schemas.merchant import (
    MerchantProfileResponse,
    MerchantProfileUpdateRequest,
    MerchantContactResponse,
    MerchantContactRequest,
    MerchantContactUpdateRequest,
    MerchantGalleryResponse,
    ServiceCreateRequest,
    ServiceUpdateRequest,
    MerchantServiceResponse,
    MerchantServicesResponse,
    MerchantAnalyticsResponse,
    MerchantFeaturedServicesResponse,
    ImageUploadResponse
)
from app.api.deps import get_current_merchant_user, get_current_active_merchant
from app.models import User, Merchant, Image, ImageType
from app.core.exceptions import (
    WedyException, 
    NotFoundError, 
    ValidationError, 
    ForbiddenError, 
    PaymentRequiredError
)
from app.utils.s3_client import s3_image_manager
from uuid import uuid4

router = APIRouter()


@router.get("/profile", response_model=MerchantProfileResponse)
async def get_merchant_profile(
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get merchant profile with subscription and usage information.
    
    Returns:
        MerchantProfileResponse: Complete merchant profile with subscription info
    """
    try:
        merchant_manager = MerchantManager(db)
        return await merchant_manager.get_merchant_profile(current_user.id)
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.put("/profile", response_model=MerchantProfileResponse)
async def update_merchant_profile(
    profile_data: MerchantProfileUpdateRequest,
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Update merchant profile with business rule validation.
    
    Args:
        profile_data: Profile update data
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        MerchantProfileResponse: Updated merchant profile
    """
    try:
        merchant_manager = MerchantManager(db)
        return await merchant_manager.update_merchant_profile(
            current_user.id, profile_data
        )
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except PaymentRequiredError as e:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=str(e)
        )
    except ForbiddenError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/cover-image", response_model=ImageUploadResponse)
async def upload_cover_image(
    file_name: str = Form(..., description="Original file name"),
    content_type: str = Form(..., description="MIME type of the file"),
    current_merchant: Merchant = Depends(get_current_active_merchant),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Generate presigned URL for cover image upload.
    
    Args:
        file_name: Original file name
        content_type: MIME type of the file
        current_merchant: Current authenticated merchant
        db: Database session
        
    Returns:
        ImageUploadResponse: Presigned URL for upload
    """
    try:
        # Check if cover image is allowed in tariff plan
        merchant_manager = MerchantManager(db)
        merchant_repo = merchant_manager.merchant_repo
        
        subscription_data = await merchant_repo.get_active_subscription(current_merchant.id)
        if not subscription_data:
            raise PaymentRequiredError("Active subscription required")
        
        _, tariff_plan = subscription_data
        if not tariff_plan.allow_cover_image:
            raise ForbiddenError("Cover image not allowed in current tariff plan")
        
        # Validate image constraints
        s3_image_manager.validate_image_constraints(content_type, 5 * 1024 * 1024)  # Max check
        
        # Generate presigned URL
        s3_url, presigned_url = s3_image_manager.generate_presigned_upload_url(
            file_name=file_name,
            content_type=content_type,
            image_type="merchant_cover",
            related_id=str(current_merchant.id)
        )
        
        # Update merchant cover image URL
        await merchant_repo.update_cover_image(current_merchant.id, s3_url)
        
        return ImageUploadResponse(
            success=True,
            message="Cover image upload URL generated",
            s3_url=s3_url,
            presigned_url=presigned_url
        )
    
    except (PaymentRequiredError, ForbiddenError, ValidationError) as e:
        status_code = {
            PaymentRequiredError: status.HTTP_402_PAYMENT_REQUIRED,
            ForbiddenError: status.HTTP_403_FORBIDDEN,
            ValidationError: status.HTTP_400_BAD_REQUEST
        }[type(e)]
        
        raise HTTPException(status_code=status_code, detail=str(e))
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Upload preparation failed: {str(e)}"
        )


@router.get("/gallery", response_model=List[MerchantGalleryResponse])
async def get_gallery_images(
    current_merchant: Merchant = Depends(get_current_active_merchant),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get merchant gallery images.
    
    Args:
        current_merchant: Current authenticated merchant
        db: Database session
        
    Returns:
        List[MerchantGalleryResponse]: Gallery images
    """
    try:
        merchant_manager = MerchantManager(db)
        images = await merchant_manager.merchant_repo.get_merchant_gallery_images(
            current_merchant.id
        )
        
        return [
            MerchantGalleryResponse(
                id=image.id,
                s3_url=image.s3_url,
                file_name=image.file_name,
                file_size=image.file_size,
                display_order=image.display_order,
                created_at=image.created_at
            )
            for image in images
        ]
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get gallery images: {str(e)}"
        )


@router.post("/gallery", response_model=ImageUploadResponse)
async def add_gallery_image(
    file_name: str = Form(..., description="Original file name"),
    content_type: str = Form(..., description="MIME type of the file"),
    display_order: Optional[int] = Form(0, description="Display order"),
    current_merchant: Merchant = Depends(get_current_active_merchant),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Add gallery image with tariff limit validation.
    
    Args:
        file_name: Original file name
        content_type: MIME type of the file
        display_order: Display order for the image
        current_merchant: Current authenticated merchant
        db: Database session
        
    Returns:
        ImageUploadResponse: Presigned URL and image info
    """
    try:
        merchant_manager = MerchantManager(db)
        merchant_repo = merchant_manager.merchant_repo
        
        # Check tariff limits
        subscription_data = await merchant_repo.get_active_subscription(current_merchant.id)
        if not subscription_data:
            raise PaymentRequiredError("Active subscription required")
        
        _, tariff_plan = subscription_data
        
        current_count = await merchant_repo.count_gallery_images(current_merchant.id)
        if current_count >= tariff_plan.max_gallery_images:
            raise ForbiddenError(
                f"Gallery image limit exceeded. Current: {current_count}, "
                f"Max allowed: {tariff_plan.max_gallery_images}"
            )
        
        # Validate image constraints
        s3_image_manager.validate_image_constraints(content_type, 5 * 1024 * 1024)
        
        # Generate presigned URL
        s3_url, presigned_url = s3_image_manager.generate_presigned_upload_url(
            file_name=file_name,
            content_type=content_type,
            image_type="merchant_gallery",
            related_id=str(current_merchant.id)
        )
        
        # Create image record
        image = Image(
            id=uuid4(),
            s3_url=s3_url,
            file_name=file_name,
            image_type=ImageType.MERCHANT_GALLERY,
            related_id=current_merchant.id,
            display_order=display_order or 0
        )
        
        created_image = await merchant_repo.create_gallery_image(image)
        
        return ImageUploadResponse(
            success=True,
            message="Gallery image upload URL generated",
            image_id=created_image.id,
            s3_url=s3_url,
            presigned_url=presigned_url
        )
    
    except (PaymentRequiredError, ForbiddenError, ValidationError) as e:
        status_code = {
            PaymentRequiredError: status.HTTP_402_PAYMENT_REQUIRED,
            ForbiddenError: status.HTTP_403_FORBIDDEN,
            ValidationError: status.HTTP_400_BAD_REQUEST
        }[type(e)]
        
        raise HTTPException(status_code=status_code, detail=str(e))
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gallery image preparation failed: {str(e)}"
        )


@router.delete("/gallery/{image_id}")
async def remove_gallery_image(
    image_id: UUID,
    current_merchant: Merchant = Depends(get_current_active_merchant),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Remove gallery image.
    
    Args:
        image_id: UUID of the image to remove
        current_merchant: Current authenticated merchant
        db: Database session
        
    Returns:
        dict: Success message
    """
    try:
        merchant_manager = MerchantManager(db)
        merchant_repo = merchant_manager.merchant_repo
        
        # Delete image record
        deleted = await merchant_repo.delete_gallery_image(image_id, current_merchant.id)
        
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Gallery image not found"
            )
        
        return {"message": "Gallery image removed successfully"}
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to remove gallery image: {str(e)}"
        )


@router.get("/contacts", response_model=List[MerchantContactResponse])
async def get_merchant_contacts(
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get all merchant contacts.
    
    Args:
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        List[MerchantContactResponse]: Merchant contacts
    """
    try:
        merchant_manager = MerchantManager(db)
        return await merchant_manager.get_merchant_contacts(current_user.id)
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.post("/contacts", response_model=MerchantContactResponse)
async def add_merchant_contact(
    contact_data: MerchantContactRequest,
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Add merchant contact with tariff limit validation.
    
    Args:
        contact_data: Contact data
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        MerchantContactResponse: Created contact
    """
    try:
        merchant_manager = MerchantManager(db)
        return await merchant_manager.add_merchant_contact(current_user.id, contact_data)
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except PaymentRequiredError as e:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=str(e)
        )
    except ForbiddenError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )


@router.get("/services", response_model=MerchantServicesResponse)
async def get_merchant_services(
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get all merchant services with analytics.
    
    Args:
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        MerchantServicesResponse: Merchant services with statistics
    """
    try:
        merchant_manager = MerchantManager(db)
        return await merchant_manager.get_merchant_services(current_user.id)
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.post("/services", response_model=MerchantServiceResponse)
async def create_service(
    service_data: ServiceCreateRequest,
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Create merchant service with tariff limit validation.
    
    Args:
        service_data: Service creation data
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        MerchantServiceResponse: Created service
    """
    try:
        merchant_manager = MerchantManager(db)
        return await merchant_manager.create_merchant_service(current_user.id, service_data)
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except PaymentRequiredError as e:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=str(e)
        )
    except ForbiddenError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/analytics/services", response_model=MerchantAnalyticsResponse)
async def get_merchant_analytics(
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get comprehensive merchant analytics.
    
    Args:
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        MerchantAnalyticsResponse: Merchant analytics dashboard data
    """
    try:
        merchant_manager = MerchantManager(db)
        return await merchant_manager.get_merchant_analytics(current_user.id)
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/featured-services", response_model=MerchantFeaturedServicesResponse)
async def get_featured_services_tracking(
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get featured services tracking for merchant.
    
    Args:
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        MerchantFeaturedServicesResponse: Featured services tracking data
    """
    try:
        merchant_manager = MerchantManager(db)
        return await merchant_manager.get_featured_services_tracking(current_user.id)
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )