from fastapi import APIRouter, Depends, HTTPException, status, Form
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db_session
from app.api.deps import get_current_active_merchant
from app.models import Merchant
from app.schemas.merchant_schema import ImageUploadResponse
from app.core.exceptions import NotFoundError, PaymentRequiredError, ForbiddenError, ValidationError
from app.services.merchant_manager import MerchantManager
from app.utils.s3_client import s3_image_manager
from app.schemas.common_schema import SuccessResponse

router = APIRouter()


@router.post("/cover-image", response_model=ImageUploadResponse)
async def add_cover_image(
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


@router.put("/cover-image", response_model=ImageUploadResponse)
async def update_cover_image(
    file_name: str = Form(..., description="Original file name"),
    content_type: str = Form(..., description="MIME type of the file"),
    current_merchant: Merchant = Depends(get_current_active_merchant),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Update cover image by generating a new presigned URL.
    
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
            message="Cover image update URL generated",
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
            detail=f"Cover image update preparation failed: {str(e)}"
        )


@router.delete("/cover-image", response_model=SuccessResponse)
async def remove_cover_image(
    current_merchant: Merchant = Depends(get_current_active_merchant),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Delete merchant cover image.
    
    Args:
        current_merchant: Current authenticated merchant
        db: Database session
        
    Returns:
        SuccessResponse: Confirmation of deletion
    """
    try:
        merchant_manager = MerchantManager(db)
        merchant_repo = merchant_manager.merchant_repo
        
        # Delete cover image (set to None)
        deleted = await merchant_repo.delete_cover_image(current_merchant.id)
        
        if not deleted:
            raise NotFoundError("Merchant not found")
        
        return SuccessResponse(
            success=True,
            message="Cover image deleted successfully"
        )
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete cover image: {str(e)}"
        )
