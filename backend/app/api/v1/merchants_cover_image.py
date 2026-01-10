from io import BytesIO
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
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
    file: UploadFile = File(..., description="Cover image file"),
    current_merchant: Merchant = Depends(get_current_active_merchant),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Upload cover image directly to S3.
    
    Args:
        file: Cover image file (multipart/form-data)
        current_merchant: Current authenticated merchant
        db: Database session
        
    Returns:
        ImageUploadResponse: Upload result with S3 URL
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
            image_type="merchant_cover",
            related_id=str(current_merchant.id)
        )
        
        # Update merchant cover image URL
        await merchant_repo.update_cover_image(current_merchant.id, s3_url)
        
        return ImageUploadResponse(
            success=True,
            message="Cover image uploaded successfully",
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
            detail=f"Cover image upload failed: {str(e)}"
        )


@router.put("/cover-image", response_model=ImageUploadResponse)
async def update_cover_image(
    file: UploadFile = File(..., description="Cover image file"),
    current_merchant: Merchant = Depends(get_current_active_merchant),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Update cover image by uploading a new file directly to S3.
    
    Args:
        file: Cover image file (multipart/form-data)
        current_merchant: Current authenticated merchant
        db: Database session
        
    Returns:
        ImageUploadResponse: Upload result with S3 URL
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
            image_type="merchant_cover",
            related_id=str(current_merchant.id)
        )
        
        # Update merchant cover image URL
        await merchant_repo.update_cover_image(current_merchant.id, s3_url)
        
        return ImageUploadResponse(
            success=True,
            message="Cover image updated successfully",
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
            detail=f"Cover image update failed: {str(e)}"
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
