from io import BytesIO
from typing import List, Optional
from uuid import UUID, uuid4
from fastapi import APIRouter, Depends, HTTPException, status, Form, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db_session
from app.api.deps import get_current_active_merchant
from app.models import Image, ImageType, Merchant
from app.schemas.merchant_schema import MerchantGalleryResponse, ImageUploadResponse
from app.core.exceptions import PaymentRequiredError, ForbiddenError, ValidationError
from app.services.merchant_manager import MerchantManager
from app.utils.s3_client import s3_image_manager
from app.schemas.common_schema import SuccessResponse

router = APIRouter()


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
    file: UploadFile = File(..., description="Gallery image file"),
    display_order: Optional[int] = Form(0, description="Display order"),
    current_merchant: Merchant = Depends(get_current_active_merchant),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Add gallery image with tariff limit validation.
    
    Args:
        file: Gallery image file (multipart/form-data)
        display_order: Display order for the image
        current_merchant: Current authenticated merchant
        db: Database session
        
    Returns:
        ImageUploadResponse: Upload result with S3 URL
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
        
        # Read file content
        content = await file.read()
        content_type = file.content_type or 'application/octet-stream'
        content_length = len(content)
        
        # Validate image constraints
        s3_image_manager.validate_image_constraints(content_type, content_length)
        
        # Upload directly to S3
        fileobj = BytesIO(content)
        s3_url = s3_image_manager.upload_fileobj(
            fileobj=fileobj,
            file_name=file.filename,
            content_type=content_type,
            image_type="merchant_gallery",
            related_id=str(current_merchant.id)
        )
        
        # Create image record
        image = Image(
            id=uuid4(),
            s3_url=s3_url,
            file_name=file.filename,
            file_size=content_length,
            image_type=ImageType.MERCHANT_GALLERY,
            related_id=current_merchant.id,
            display_order=display_order or 0
        )
        
        created_image = await merchant_repo.create_gallery_image(image)
        
        return ImageUploadResponse(
            success=True,
            message="Gallery image uploaded successfully",
            image_id=created_image.id,
            s3_url=s3_url,
            presigned_url=None
        )
    
    except (PaymentRequiredError, ForbiddenError, ValidationError) as e:
        status_code = {
            PaymentRequiredError: status.HTTP_402_PAYMENT_REQUIRED,
            ForbiddenError: status.HTTP_403_FORBIDDEN,
            ValidationError: status.HTTP_400_BAD_REQUEST
        }[type(e)]
        
        raise HTTPException(status_code=status_code, detail=str(e))
    
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gallery image upload failed: {str(e)}"
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
