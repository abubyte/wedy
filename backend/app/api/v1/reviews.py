from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.api.deps import get_current_user, get_current_client
from app.models import User
from app.services.review_service import ReviewService
from app.schemas.review_schema import (
    ReviewCreateRequest,
    ReviewUpdateRequest,
    ReviewDetailResponse,
    ReviewListResponse
)
from app.schemas.common_schema import PaginationParams
from app.core.exceptions import (
    WedyException,
    NotFoundError,
    ConflictError,
    ValidationError,
    ForbiddenError
)

router = APIRouter()


@router.get("/services/{service_id}/reviews", response_model=ReviewListResponse)
async def get_service_reviews(
    service_id: UUID,
    include_inactive: bool = Query(False, description="Include inactive reviews"),
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get all reviews for a specific service (public endpoint).
    
    Args:
        service_id: UUID of the service
        include_inactive: Whether to include inactive reviews
        page: Page number (1-based)
        limit: Items per page (1-100)
        db: Database session
        
    Returns:
        ReviewListResponse with paginated reviews
    """
    try:
        review_service = ReviewService(db)
        pagination = PaginationParams(page=page, limit=limit)
        
        return await review_service.list_reviews(
            service_id=service_id,
            include_inactive=include_inactive,
            pagination=pagination
        )
    
    except WedyException as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/", response_model=ReviewListResponse)
async def list_reviews(
    service_id: Optional[UUID] = Query(None, description="Filter by service ID"),
    merchant_id: Optional[UUID] = Query(None, description="Filter by merchant ID"),
    user_id: Optional[UUID] = Query(None, description="Filter by user ID"),
    include_inactive: bool = Query(False, description="Include inactive reviews"),
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get all reviews with optional filters and pagination (public endpoint).
    
    Args:
        service_id: Optional filter by service ID
        merchant_id: Optional filter by merchant ID
        user_id: Optional filter by user ID
        include_inactive: Whether to include inactive reviews
        page: Page number (1-based)
        limit: Items per page (1-100)
        db: Database session
        
    Returns:
        ReviewListResponse with paginated reviews
    """
    try:
        review_service = ReviewService(db)
        pagination = PaginationParams(page=page, limit=limit)
        
        return await review_service.list_reviews(
            service_id=service_id,
            merchant_id=merchant_id,
            user_id=user_id,
            include_inactive=include_inactive,
            pagination=pagination
        )
    
    except WedyException as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/{review_id}", response_model=ReviewDetailResponse)
async def get_review(
    review_id: UUID,
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get review by ID (public endpoint).
    
    Args:
        review_id: UUID of the review
        db: Database session
        
    Returns:
        ReviewDetailResponse with review details
    """
    try:
        review_service = ReviewService(db)
        return await review_service.get_review(review_id)
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except WedyException as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/", response_model=ReviewDetailResponse, status_code=status.HTTP_201_CREATED)
async def create_review(
    request: ReviewCreateRequest,
    current_user: User = Depends(get_current_client),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Create a new review (authenticated client only).
    
    Args:
        request: Review creation data
        current_user: Current authenticated client user
        db: Database session
        
    Returns:
        ReviewDetailResponse for created review
    """
    try:
        review_service = ReviewService(db)
        return await review_service.create_review(current_user.id, request)
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except ConflictError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(e)
        )
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e)
        )
    except WedyException as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.put("/{review_id}", response_model=ReviewDetailResponse)
async def update_review(
    review_id: UUID,
    request: ReviewUpdateRequest,
    current_user: User = Depends(get_current_client),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Update an existing review (authenticated client, own reviews only).
    
    Args:
        review_id: UUID of the review to update
        request: Review update data
        current_user: Current authenticated client user
        db: Database session
        
    Returns:
        ReviewDetailResponse for updated review
    """
    try:
        review_service = ReviewService(db)
        return await review_service.update_review(review_id, current_user.id, request)
    
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
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e)
        )
    except WedyException as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.delete("/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_review(
    review_id: UUID,
    current_user: User = Depends(get_current_client),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Delete a review (soft delete, authenticated client, own reviews only).
    
    Args:
        review_id: UUID of the review to delete
        current_user: Current authenticated client user
        db: Database session
        
    Returns:
        204 No Content on success
    """
    try:
        review_service = ReviewService(db)
        await review_service.delete_review(review_id, current_user.id)
        return None
    
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
    except WedyException as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
