from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.services.service_manager import ServiceManager
from app.schemas.service import (
    ServiceCategoriesResponse,
    ServiceSearchFilters,
    PaginatedServiceResponse,
    FeaturedServicesResponse,
    ServiceDetailResponse,
    ServiceInteractionRequest,
    ServiceInteractionResponse
)
from app.schemas.common import PaginationParams
from app.api.deps import get_current_user
from app.models import User
from app.core.exceptions import WedyException, NotFoundError, ValidationError

router = APIRouter()


@router.get("/categories", response_model=ServiceCategoriesResponse)
async def get_service_categories(
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get all active service categories with service counts.
    
    Returns:
        ServiceCategoriesResponse: List of categories with service counts
    """
    service_manager = ServiceManager(db)
    return await service_manager.get_categories()


@router.get("/", response_model=PaginatedServiceResponse)
async def browse_services(
    category_id: Optional[UUID] = Query(None, description="Filter by category ID"),
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Browse services with optional category filter and pagination.
    
    Args:
        category_id: Optional category filter
        page: Page number (1-based)
        limit: Items per page (1-100)
        db: Database session
        
    Returns:
        PaginatedServiceResponse: Services with pagination info
    """
    service_manager = ServiceManager(db)
    pagination = PaginationParams(page=page, limit=limit)
    
    return await service_manager.browse_services(
        category_id=category_id,
        pagination=pagination
    )


@router.get("/search", response_model=PaginatedServiceResponse)
async def search_services(
    query: Optional[str] = Query(None, description="Search query for name/description"),
    category_id: Optional[UUID] = Query(None, description="Filter by category"),
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
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Search services with advanced filters.
    
    Args:
        query: Search query for service name/description
        category_id: Filter by category UUID
        location_region: Filter by Uzbekistan region
        min_price: Minimum price in UZS
        max_price: Maximum price in UZS
        min_rating: Minimum rating (0-5)
        is_verified_merchant: Only show services from verified merchants
        sort_by: Sort field (created_at, price, rating, popularity, name)
        sort_order: Sort order (asc, desc)
        page: Page number
        limit: Items per page
        db: Database session
        
    Returns:
        PaginatedServiceResponse: Matching services with pagination
        
    Raises:
        HTTPException: If search filters are invalid
    """
    try:
        service_manager = ServiceManager(db)
        
        filters = ServiceSearchFilters(
            query=query,
            category_id=category_id,
            location_region=location_region,
            min_price=min_price,
            max_price=max_price,
            min_rating=min_rating,
            is_verified_merchant=is_verified_merchant,
            sort_by=sort_by,
            sort_order=sort_order
        )
        
        pagination = PaginationParams(page=page, limit=limit)
        
        return await service_manager.search_services(
            filters=filters,
            pagination=pagination
        )
    
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=e.message
        )


@router.get("/featured", response_model=FeaturedServicesResponse)
async def get_featured_services(
    limit: Optional[int] = Query(None, ge=1, le=100, description="Limit number of results"),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get currently active featured services.
    
    Args:
        limit: Optional limit for number of results
        db: Database session
        
    Returns:
        FeaturedServicesResponse: Currently featured services
    """
    service_manager = ServiceManager(db)
    return await service_manager.get_featured_services(limit=limit)


@router.get("/{service_id}", response_model=ServiceDetailResponse)
async def get_service_details(
    service_id: UUID,
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get detailed service information including merchant info and images.
    
    Args:
        service_id: UUID of the service
        db: Database session
        
    Returns:
        ServiceDetailResponse: Complete service details
        
    Raises:
        HTTPException: If service not found
    """
    try:
        service_manager = ServiceManager(db)
        return await service_manager.get_service_details(service_id)
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=e.message
        )


@router.post("/{service_id}/interact", response_model=ServiceInteractionResponse)
async def record_service_interaction(
    service_id: UUID,
    request: ServiceInteractionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Record user interaction with a service (like, save, share).
    
    Args:
        service_id: UUID of the service
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
            new_count=result["new_count"]
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


@router.get("/{service_id}/similar", response_model=PaginatedServiceResponse)
async def get_similar_services(
    service_id: UUID,
    limit: int = Query(10, ge=1, le=50, description="Number of similar services"),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get services similar to the specified service (same category, location).
    
    Args:
        service_id: UUID of the reference service
        limit: Maximum number of similar services
        db: Database session
        
    Returns:
        PaginatedServiceResponse: Similar services
        
    Raises:
        HTTPException: If service not found
    """
    try:
        service_manager = ServiceManager(db)
        
        # Get the reference service to determine similarity criteria
        service_details = await service_manager.get_service_details(service_id)
        
        # Search for similar services (same category, exclude the current service)
        filters = ServiceSearchFilters(
            category_id=service_details.category_id,
            location_region=service_details.location_region
        )
        
        pagination = PaginationParams(page=1, limit=limit + 1)  # +1 to account for current service
        
        result = await service_manager.search_services(
            filters=filters,
            pagination=pagination
        )
        
        # Remove the current service from results
        similar_services = [
            service for service in result.services 
            if service.id != service_id
        ][:limit]
        
        return PaginatedServiceResponse(
            services=similar_services,
            total=len(similar_services),
            page=1,
            limit=limit,
            has_more=False,
            total_pages=1
        )
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=e.message
        )