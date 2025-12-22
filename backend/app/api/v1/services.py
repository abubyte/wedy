from typing import Optional
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, Query, HTTPException, status, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.core.database import get_db_session
from app.services.service_manager import ServiceManager
from app.services.merchant_manager import MerchantManager
from app.schemas.service_schema import (
    ServiceSearchFilters,
    PaginatedServiceResponse,
    FeaturedServicesResponse,
    ServiceDetailResponse,
    ServiceInteractionRequest,
    ServiceInteractionResponse
)
from app.schemas.merchant_schema import (
    ServiceCreateRequest,
    ServiceUpdateRequest,
    MerchantServiceResponse,
    MerchantServicesResponse,
    ImageUploadResponse,
    FeaturedServiceResponse
)
from app.schemas.common_schema import PaginationParams, SuccessResponse
from app.api.deps import get_current_user, get_current_merchant_user, get_current_admin, get_current_user_optional
from app.models import User, Service, Image, ImageType, FeatureType
from app.repositories.service_repository import ServiceRepository
from app.repositories.merchant_repository import MerchantRepository
from app.core.exceptions import (
    WedyException, 
    NotFoundError, 
    ValidationError, 
    ForbiddenError, 
    PaymentRequiredError
)
from app.utils.s3_client import s3_image_manager

router = APIRouter()


@router.get("/", response_model=PaginatedServiceResponse)
async def get_services(
    # Featured mode
    featured: Optional[bool] = Query(None, description="Get only featured services"),
    
    # Browse/Search filters
    query: Optional[str] = Query(None, description="Search query for name/description"),
    category_id: Optional[int] = Query(None, description="Filter by category ID"),
    location_region: Optional[str] = Query(None, description="Filter by Uzbekistan region"),
    min_price: Optional[float] = Query(None, ge=0, description="Minimum price in UZS"),
    max_price: Optional[float] = Query(None, ge=0, description="Maximum price in UZS"),
    min_rating: Optional[float] = Query(None, ge=0, le=5, description="Minimum rating"),
    is_verified_merchant: Optional[bool] = Query(None, description="Only verified merchants"),
    sort_by: Optional[str] = Query(
        "created_at", 
        description="Sort by: created_at, price, rating, popularity, name"
    ),
    sort_order: Optional[str] = Query(
        "desc", 
        description="Sort order: asc, desc"
    ),
    
    # Pagination
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    
    current_user: Optional[User] = Depends(get_current_user_optional),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Universal endpoint for browsing, searching, and getting featured services.
    
    Modes:
    1. Featured: Set featured=true to get only featured services
    2. Search: Provide any search filters (query, location, price, etc.)
    3. Browse: Default mode - browse all services with optional category filter
    
    Args:
        featured: If True, returns only featured services (other filters ignored)
        query: Search query for service name/description
        category_id: Filter by category ID (integer)
        location_region: Filter by Uzbekistan region
        min_price: Minimum price in UZS
        max_price: Maximum price in UZS
        min_rating: Minimum rating (0-5)
        is_verified_merchant: Only show services from verified merchants
        sort_by: Sort field (created_at, price, rating, popularity, name)
        sort_order: Sort order (asc, desc)
        page: Page number (1-based)
        limit: Items per page (1-100)
        db: Database session
        
    Returns:
        PaginatedServiceResponse: Services with pagination info
        
    Raises:
        HTTPException: If filters are invalid
    """
    try:
        service_manager = ServiceManager(db)
        pagination = PaginationParams(page=page, limit=limit)
        
        # Get user_id if authenticated
        user_id = current_user.id if current_user else None
        
        # Featured mode - return only featured services
        if featured:
            # Get all featured services (typically small number)
            featured_response = await service_manager.get_featured_services(limit=None, user_id=user_id)
            total_featured = featured_response.total
            
            # Apply pagination to featured services
            start_idx = (page - 1) * limit
            end_idx = start_idx + limit
            paginated_services = featured_response.services[start_idx:end_idx]
            
            total_pages = (total_featured + limit - 1) // limit if total_featured > 0 else 1
            has_more = page < total_pages
            
            return PaginatedServiceResponse(
                services=paginated_services,
                total=total_featured,
                page=page,
                limit=limit,
                has_more=has_more,
                total_pages=total_pages
            )
        
        # Check if any search filters are provided (search mode)
        has_search_filters = any([
            query,
            location_region,
            min_price is not None,
            max_price is not None,
            min_rating is not None,
            is_verified_merchant is not None,
            sort_by and sort_by != "created_at",  # If sort_by is something other than default
            sort_order and sort_order != "desc"  # If sort_order is something other than default
        ])
        
        if has_search_filters:
            # Search mode with advanced filters
            filters = ServiceSearchFilters(
                query=query,
                category_id=category_id,
                location_region=location_region,
                min_price=min_price,
                max_price=max_price,
                min_rating=min_rating,
                is_verified_merchant=is_verified_merchant,
                sort_by=sort_by or "created_at",
                sort_order=sort_order or "desc"
            )
            
            return await service_manager.search_services(
                filters=filters,
                pagination=pagination,
                user_id=user_id
            )
        else:
            # Browse mode - simple browsing with optional category filter
            return await service_manager.browse_services(
                category_id=category_id,
                pagination=pagination,
                user_id=user_id
            )
    
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=e.message
        )


# Merchant Service Management Endpoints
# NOTE: Specific routes like /my must come BEFORE parameterized routes like /{service_id}
# to avoid route matching conflicts
@router.get("/my", response_model=MerchantServicesResponse)
async def get_my_services(
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
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get merchant services: {str(e)}"
        )


@router.get("/{service_id}", response_model=ServiceDetailResponse)
async def get_service_details(
    service_id: str,
    current_user: Optional[User] = Depends(get_current_user_optional),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get detailed service information including merchant info and images.
    
    Args:
        service_id: 9-digit numeric string ID of the service
        current_user: Optional authenticated user
        db: Database session
        
    Returns:
        ServiceDetailResponse: Complete service details
        
    Raises:
        HTTPException: If service not found
    """
    try:
        service_manager = ServiceManager(db)
        user_id = current_user.id if current_user else None
        return await service_manager.get_service_details(service_id, user_id=user_id)
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=e.message
        )


@router.post("/{service_id}/interact", response_model=ServiceInteractionResponse)
async def record_service_interaction(
    service_id: str,
    request: ServiceInteractionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Record user interaction with a service (like, save, share).
    
    Args:
        service_id: 9-digit numeric string ID of the service
        request: Interaction request data
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        ServiceInteractionResponse: Interaction result
        
    Raises:
        HTTPException: If service not found or interaction invalid
    """
    try:
        service_manager = ServiceManager(db)
        
        result = await service_manager.record_service_interaction(
            user_id=current_user.id,
            service_id=service_id,
            interaction_type=request.interaction_type
        )
        
        return ServiceInteractionResponse(
            success=result["success"],
            message=result["message"],
            new_count=result["new_count"],
            is_active=result.get("is_active", True)
        )
    
    except (NotFoundError, ValidationError) as e:
        if isinstance(e, NotFoundError):
            status_code = status.HTTP_404_NOT_FOUND
        else:
            status_code = status.HTTP_400_BAD_REQUEST
            
        raise HTTPException(
            status_code=status_code,
            detail=e.message
        )


@router.post("/", response_model=MerchantServiceResponse)
async def create_service(
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


@router.put("/{service_id}", response_model=MerchantServiceResponse)
async def update_service(
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
            # Validate category exists - query ServiceCategory directly
            from app.models import ServiceCategory
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
        from app.models import ServiceCategory
        category_stmt = select(ServiceCategory).where(ServiceCategory.id == updated_service.category_id)
        category_result = await db.execute(category_stmt)
        category = category_result.scalar_one_or_none()
        
        return MerchantServiceResponse(
            id=updated_service.id,
            name=updated_service.name,
            description=updated_service.description,
            price=updated_service.price,
            location_region=updated_service.location_region,
            latitude=updated_service.latitude,
            longitude=updated_service.longitude,
            view_count=updated_service.view_count,
            like_count=updated_service.like_count,
            save_count=updated_service.save_count,
            share_count=updated_service.share_count,
            overall_rating=updated_service.overall_rating,
            total_reviews=updated_service.total_reviews,
            is_active=updated_service.is_active,
            created_at=updated_service.created_at,
            updated_at=updated_service.updated_at,
            category_id=category.id if category else updated_service.category_id,
            category_name=category.name if category else "Unknown",
            images_count=await merchant_repo.count_service_images(updated_service.id),
            is_featured=(await service_repo.is_service_featured(updated_service.id))[0]
        )
    
    except (NotFoundError, ForbiddenError, ValidationError) as e:
        status_code = {
            NotFoundError: status.HTTP_404_NOT_FOUND,
            ForbiddenError: status.HTTP_403_FORBIDDEN,
            ValidationError: status.HTTP_400_BAD_REQUEST
        }[type(e)]
        raise HTTPException(
            status_code=status_code,
            detail=str(e)
        )


@router.delete("/{service_id}", response_model=SuccessResponse)
async def delete_service(
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
        
        # Soft delete by setting is_active=False
        service.is_active = False
        await service_repo.update(service)
        
        return SuccessResponse(
            success=True,
            message="Service deleted successfully"
        )
    
    except (NotFoundError, ForbiddenError) as e:
        status_code = status.HTTP_404_NOT_FOUND if isinstance(e, NotFoundError) else status.HTTP_403_FORBIDDEN
        raise HTTPException(
            status_code=status_code,
            detail=str(e)
        )


@router.post("/{service_id}/images", response_model=ImageUploadResponse)
async def upload_service_image(
    service_id: str,
    file_name: str = Form(..., description="Original file name"),
    content_type: str = Form(..., description="MIME type of the file"),
    display_order: Optional[int] = Form(0, description="Display order"),
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Upload service image with tariff limit validation.
    
    Args:
        service_id: 9-digit numeric string ID of the service
        file_name: Original file name
        content_type: MIME type of the file
        display_order: Display order for the image
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        ImageUploadResponse: Presigned URL and image info
    """
    try:
        merchant_manager = MerchantManager(db)
        merchant_repo = merchant_manager.merchant_repo
        
        # Get merchant
        merchant = await merchant_repo.get_merchant_by_user_id(current_user.id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        # Verify service belongs to merchant
        service_repo = ServiceRepository(db)
        service_stmt = select(Service).where(
            and_(
                Service.id == service_id,
                Service.merchant_id == merchant.id
            )
        )
        service_result = await db.execute(service_stmt)
        service = service_result.scalar_one_or_none()
        
        if not service:
            raise NotFoundError("Service not found or not owned by merchant")
        
        # Check tariff limits
        subscription_data = await merchant_repo.get_active_subscription(merchant.id)
        if not subscription_data:
            raise PaymentRequiredError("Active subscription required")
        
        _, tariff_plan = subscription_data
        
        # Count current images for this service
        current_count = await merchant_repo.count_service_images(service_id)
        if current_count >= tariff_plan.max_images_per_service:
            raise ForbiddenError(
                f"Service image limit exceeded. Current: {current_count}, "
                f"Max allowed: {tariff_plan.max_images_per_service}"
            )
        
        # Validate image constraints
        s3_image_manager.validate_image_constraints(content_type, 5 * 1024 * 1024)
        
        # Generate presigned URL
        s3_url, presigned_url = s3_image_manager.generate_presigned_upload_url(
            file_name=file_name,
            content_type=content_type,
            image_type="service_image",
            related_id=str(service_id)
        )
        
        # Create image record
        image = Image(
            id=uuid4(),
            s3_url=s3_url,
            file_name=file_name,
            image_type=ImageType.SERVICE_IMAGE,
            related_id=service_id,
            display_order=display_order or 0
        )
        
        created_image = await merchant_repo.create_service_image(image)
        
        return ImageUploadResponse(
            success=True,
            message="Service image upload URL generated",
            image_id=created_image.id,
            s3_url=s3_url,
            presigned_url=presigned_url
        )
    
    except (PaymentRequiredError, ForbiddenError, NotFoundError, ValidationError) as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if isinstance(e, ForbiddenError)
            else status.HTTP_402_PAYMENT_REQUIRED if isinstance(e, PaymentRequiredError)
            else status.HTTP_404_NOT_FOUND if isinstance(e, NotFoundError)
            else status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to upload service image: {str(e)}"
        )


@router.delete("/{service_id}/images/{image_id}", response_model=SuccessResponse)
async def delete_service_image(
    service_id: str,
    image_id: UUID,
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Delete a service image. Only the merchant who owns the service can delete its images.
    
    Args:
        service_id: 9-digit numeric string ID of the service
        image_id: UUID of the image to delete
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        SuccessResponse: Confirmation of deletion
    """
    try:
        merchant_manager = MerchantManager(db)
        merchant_repo = merchant_manager.merchant_repo
        service_repo = ServiceRepository(db)
        
        # Get merchant
        merchant = await merchant_repo.get_merchant_by_user_id(current_user.id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        # Verify service belongs to merchant
        service = await service_repo.get_by_id(service_id)
        if not service or service.merchant_id != merchant.id:
            raise NotFoundError("Service not found or not owned by merchant")
        
        # Verify image belongs to service
        image_stmt = select(Image).where(
            and_(
                Image.id == image_id,
                Image.related_id == service_id,
                Image.image_type == ImageType.SERVICE_IMAGE
            )
        )
        image_result = await db.execute(image_stmt)
        image = image_result.scalar_one_or_none()
        
        if not image:
            raise NotFoundError("Service image not found")
        
        # Soft delete image
        image.is_active = False
        merchant_repo.db.add(image)
        await merchant_repo.db.commit()
        
        return SuccessResponse(
            success=True,
            message="Service image deleted successfully"
        )
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete service image: {str(e)}"
        )


@router.post("/admin/feature", response_model=FeaturedServiceResponse)
async def admin_feature_service(
    service_id: str = Form(..., description="9-digit numeric string ID of the service to feature"),
    duration_days: int = Form(30, ge=1, le=365, description="Feature duration in days"),
    feature_type: str = Form("monthly_allocation", description="Feature type: monthly_allocation or paid_feature"),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Manually feature a service as admin (bypasses subscription and ownership checks).
    
    Args:
        service_id: 9-digit numeric string ID of the service to feature
        duration_days: Feature duration in days (1-365, default: 30)
        feature_type: Feature type - "monthly_allocation" or "paid_feature" (default: monthly_allocation)
        current_user: Current authenticated admin user
        db: Database session
        
    Returns:
        FeaturedServiceResponse: Created featured service
        
    Raises:
        HTTPException: If service not found or invalid parameters
    """
    try:
        # Validate feature type
        try:
            feature_type_enum = FeatureType(feature_type)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid feature_type: {feature_type}. Must be 'monthly_allocation' or 'paid_feature'"
            )
        
        merchant_manager = MerchantManager(db)
        result = await merchant_manager.create_featured_service_admin(
            service_id=service_id,
            duration_days=duration_days,
            feature_type=feature_type_enum
        )
        
        return result
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create featured service: {str(e)}"
        )