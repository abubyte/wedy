from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Form, UploadFile, File, Query
from sqlalchemy.ext.asyncio import AsyncSession

from datetime import datetime
from app.core.database import get_db_session
from app.services.merchant_manager import MerchantManager
from app.services.payment_service import PaymentService
from app.services.payment_providers import get_payment_providers
from app.repositories.merchant_repository import MerchantRepository
from app.schemas.merchant_schema import (
    MerchantProfileResponse,
    MerchantProfileUpdateRequest,
    MerchantContactResponse,
    MerchantContactRequest,
    MerchantContactUpdateRequest,
    MerchantGalleryResponse,
    MerchantAnalyticsResponse,
    MerchantFeaturedServicesResponse,
    FeaturedServiceResponse,
    ImageUploadResponse,
    MerchantServicesResponse,
    ServiceCreateRequest,
    ServiceUpdateRequest,
    MerchantServiceResponse
)
from app.schemas.payment_schema import SubscriptionResponse, SubscriptionWithLimitsResponse
from app.schemas.common_schema import SuccessResponse
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


def get_payment_service(
    session: AsyncSession = Depends(get_db_session),
    payment_providers = Depends(get_payment_providers)
) -> PaymentService:
    """Get payment service instance."""
    return PaymentService(
        session=session,
        payment_providers=payment_providers,
        sms_service=None  # SMS service would be injected here # TODO
    )


@router.get("/subscription", response_model=SubscriptionWithLimitsResponse)
async def get_merchant_subscription(
    current_user: User = Depends(get_current_merchant_user),
    payment_service: PaymentService = Depends(get_payment_service),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get merchant's current subscription with limits and usage information (universal endpoint).
    
    Args:
        current_user: Current authenticated merchant user
        payment_service: Payment service instance
        db: Database session
        
    Returns:
        SubscriptionWithLimitsResponse: Subscription details with limits and usage
    """
    try:
        subscription = await payment_service.get_merchant_subscription(current_user.id)
        
        # If no subscription, return empty response
        if not subscription:
            return SubscriptionWithLimitsResponse(
                subscription=None,
                limits=None,
                message="No active subscription found for this merchant"
            )
        
        # Get merchant
        merchant_repo = MerchantRepository(db)
        merchant = await merchant_repo.get_merchant_by_user_id(current_user.id)
        if not merchant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Merchant not found"
            )
        
        # Calculate actual usage
        current_services = await payment_service.payment_repo.count_merchant_services(merchant.id)
        current_phone_numbers = await payment_service.payment_repo.count_merchant_phone_numbers(merchant.id)
        current_gallery_images = await payment_service.payment_repo.count_merchant_gallery_images(merchant.id)
        current_social_accounts = await payment_service.payment_repo.count_merchant_social_accounts(merchant.id)
        
        # Calculate monthly featured allocations used (current month)
        now = datetime.now()
        monthly_used = await payment_service.payment_repo.count_monthly_featured_allocations_used(
            merchant.id, now.year, now.month
        )
        
        plan = subscription.tariff_plan
        
        limits = {
            "services": {
                "limit": plan.max_services,
                "current": current_services,
                "available": max(0, plan.max_services - current_services)
            },
            "images_per_service": {
                "limit": plan.max_images_per_service,
                "current": 0,  # Per-service, calculated when needed
                "available": plan.max_images_per_service
            },
            "phone_numbers": {
                "limit": plan.max_phone_numbers,
                "current": current_phone_numbers,
                "available": max(0, plan.max_phone_numbers - current_phone_numbers)
            },
            "gallery_images": {
                "limit": plan.max_gallery_images,
                "current": current_gallery_images,
                "available": max(0, plan.max_gallery_images - current_gallery_images)
            },
            "social_accounts": {
                "limit": plan.max_social_accounts,
                "current": current_social_accounts,
                "available": max(0, plan.max_social_accounts - current_social_accounts)
            },
            "website_allowed": plan.allow_website,
            "cover_image_allowed": plan.allow_cover_image,
            "monthly_featured_cards": {
                "limit": plan.monthly_featured_cards,
                "used": monthly_used,
                "available": max(0, plan.monthly_featured_cards - monthly_used)
            }
        }
        
        return SubscriptionWithLimitsResponse(
            subscription=subscription,
            limits=limits,
            message=None
        )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get subscription: {str(e)}"
        )


@router.post("/subscription/check-limit")
async def check_subscription_limit(
    limit_type: str,
    current_count: int,
    current_user: User = Depends(get_current_merchant_user),
    payment_service: PaymentService = Depends(get_payment_service)
):
    """
    Check if merchant can perform action within subscription limits.
    
    Args:
        limit_type: Type of limit to check (services, images_per_service, etc.)
        current_count: Current count for the limit type
        current_user: Current authenticated merchant user
        payment_service: Payment service instance
        
    Returns:
        Dict with can_proceed status and limit information
    """
    try:
        can_proceed = await payment_service.check_subscription_limit(
            current_user.id, limit_type, current_count
        )
        
        return {
            "can_proceed": can_proceed,
            "limit_type": limit_type,
            "current_count": current_count
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to check subscription limit: {str(e)}"
        )


@router.get("/services", response_model=MerchantServicesResponse)
async def get_merchant_services(
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get all services for the current merchant with analytics.
    
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
async def create_merchant_service(
    service_data: ServiceCreateRequest,
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Create a new service for the current merchant with tariff limit validation.
    
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


@router.put("/services/{service_id}", response_model=MerchantServiceResponse)
async def update_merchant_service(
    service_id: str,
    service_data: ServiceUpdateRequest,
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Update a service. Only the merchant who owns the service can update it.
    
    Args:
        service_id: 9-digit numeric string ID of the service to update
        service_data: Service update data
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        MerchantServiceResponse: Updated service
    """
    try:
        from app.repositories.service_repository import ServiceRepository
        from app.models import ServiceCategory
        from sqlalchemy import select
        
        merchant_manager = MerchantManager(db)
        merchant_repo = merchant_manager.merchant_repo
        service_repo = ServiceRepository(db)
        
        # Get merchant
        merchant = await merchant_repo.get_merchant_by_user_id(current_user.id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        # Get service and verify ownership
        service = await service_repo.get_by_id(service_id)
        if not service:
            raise NotFoundError("Service not found")
        
        if service.merchant_id != merchant.id:
            raise ForbiddenError("You don't have permission to update this service")
        
        # Update service fields
        if service_data.name is not None:
            service.name = service_data.name
        if service_data.description is not None:
            service.description = service_data.description
        if service_data.category_id is not None:
            # Validate category exists
            category_stmt = select(ServiceCategory).where(ServiceCategory.id == service_data.category_id)
            category_result = await db.execute(category_stmt)
            category = category_result.scalar_one_or_none()
            if not category:
                raise NotFoundError("Service category not found")
            service.category_id = service_data.category_id
        if service_data.price is not None:
            service.price = service_data.price
        if service_data.location_region is not None:
            from app.utils.constants import UZBEKISTAN_REGIONS
            if service_data.location_region not in UZBEKISTAN_REGIONS:
                raise ValidationError(f"Invalid region: {service_data.location_region}")
            service.location_region = service_data.location_region
        if service_data.latitude is not None:
            service.latitude = service_data.latitude
        if service_data.longitude is not None:
            service.longitude = service_data.longitude
        
        # Save updates
        updated_service = await service_repo.update(service)
        
        # Get category for response
        category_stmt = select(ServiceCategory).where(ServiceCategory.id == updated_service.category_id)
        category_result = await db.execute(category_stmt)
        category = category_result.scalar_one_or_none()
        
        # Count images for this service
        images_count = await merchant_repo.count_service_images(updated_service.id)
        
        return MerchantServiceResponse(
            id=updated_service.id,
            name=updated_service.name,
            description=updated_service.description,
            category_id=updated_service.category_id,
            category_name=category.name if category else "",
            price=updated_service.price,
            location_region=updated_service.location_region,
            latitude=updated_service.latitude,
            longitude=updated_service.longitude,
            is_active=updated_service.is_active,
            images_count=images_count,
            created_at=updated_service.created_at,
            updated_at=updated_service.updated_at
        )
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
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


@router.delete("/services/{service_id}", response_model=SuccessResponse)
async def delete_merchant_service(
    service_id: str,
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Delete (soft delete) a service. Only the merchant who owns the service can delete it.
    
    Args:
        service_id: 9-digit numeric string ID of the service to delete
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        SuccessResponse: Confirmation of deletion
    """
    try:
        from app.repositories.service_repository import ServiceRepository
        
        merchant_manager = MerchantManager(db)
        merchant_repo = merchant_manager.merchant_repo
        service_repo = ServiceRepository(db)
        
        # Get merchant
        merchant = await merchant_repo.get_merchant_by_user_id(current_user.id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        # Get service and verify ownership
        service = await service_repo.get_by_id(service_id)
        if not service:
            raise NotFoundError("Service not found")
        
        if service.merchant_id != merchant.id:
            raise ForbiddenError("You don't have permission to delete this service")
        
        # Soft delete service
        service.is_active = False
        await service_repo.update(service)
        
        return SuccessResponse(
            success=True,
            message="Service deleted successfully"
        )
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except ForbiddenError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )


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


@router.post("/featured-services/monthly", response_model=FeaturedServiceResponse)
async def create_monthly_featured_service(
    service_id: str = Form(..., description="9-digit numeric string ID of the service to feature"),
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Create monthly featured service allocation (free, uses monthly quota).
    
    Args:
        service_id: 9-digit numeric string ID of the service to feature
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        FeaturedServiceResponse: Created featured service
    """
    try:
        merchant_manager = MerchantManager(db)
        return await merchant_manager.create_monthly_featured_service(
            current_user.id, 
            service_id
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