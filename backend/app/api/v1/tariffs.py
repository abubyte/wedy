from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.api.deps import get_current_admin
from app.models import User
from app.services.tariff_service import TariffService
from app.repositories.payment_repository import PaymentRepository
from app.schemas.payment_schema import (
    TariffCreateRequest,
    TariffUpdateRequest,
    TariffDetailResponse,
    TariffListResponse,
    TariffPlanResponse
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


@router.get("/", response_model=List[TariffPlanResponse])
async def get_tariff_plans(
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get all active tariff plans (public endpoint).
    
    Returns:
        List of active tariff plans
    """
    try:
        payment_repo = PaymentRepository(db)
        plans = await payment_repo.get_active_tariff_plans()
        return [TariffPlanResponse.model_validate(plan) for plan in plans]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get tariff plans: {str(e)}"
        )


@router.get("/admin/list", response_model=TariffListResponse)
async def list_tariffs_admin(
    include_inactive: bool = Query(False, description="Include inactive tariff plans"),
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get all tariff plans with pagination (admin only).
    
    Args:
        include_inactive: Whether to include inactive tariff plans
        page: Page number (1-based)
        limit: Items per page (1-100)
        current_user: Current authenticated admin user
        db: Database session
        
    Returns:
        TariffListResponse with paginated tariff plans
    """
    try:
        tariff_service = TariffService(db)
        pagination = PaginationParams(page=page, limit=limit)
        
        return await tariff_service.list_tariffs(
            include_inactive=include_inactive,
            pagination=pagination
        )
    
    except WedyException as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/{tariff_id}", response_model=TariffDetailResponse)
async def get_tariff(
    tariff_id: UUID,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get tariff plan by ID (admin only).
    
    Args:
        tariff_id: UUID of the tariff plan
        current_user: Current authenticated admin user
        db: Database session
        
    Returns:
        TariffDetailResponse with tariff plan details
    """
    try:
        tariff_service = TariffService(db)
        return await tariff_service.get_tariff(tariff_id)
    
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


@router.post("/", response_model=TariffDetailResponse, status_code=status.HTTP_201_CREATED)
async def create_tariff(
    request: TariffCreateRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Create a new tariff plan (admin only).
    
    Args:
        request: Tariff plan creation data
        current_user: Current authenticated admin user
        db: Database session
        
    Returns:
        TariffDetailResponse for created tariff plan
    """
    try:
        tariff_service = TariffService(db)
        return await tariff_service.create_tariff(request)
    
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


@router.put("/{tariff_id}", response_model=TariffDetailResponse)
async def update_tariff(
    tariff_id: UUID,
    request: TariffUpdateRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Update an existing tariff plan (admin only).
    
    Args:
        tariff_id: UUID of the tariff plan to update
        request: Tariff plan update data
        current_user: Current authenticated admin user
        db: Database session
        
    Returns:
        TariffDetailResponse for updated tariff plan
    """
    try:
        tariff_service = TariffService(db)
        return await tariff_service.update_tariff(tariff_id, request)
    
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


@router.delete("/{tariff_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tariff(
    tariff_id: UUID,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Delete a tariff plan (admin only).
    
    If tariff plan has active subscriptions, it will be soft-deleted (is_active=False).
    If no active subscriptions, it will be hard-deleted.
    
    Args:
        tariff_id: UUID of the tariff plan to delete
        current_user: Current authenticated admin user
        db: Database session
        
    Returns:
        204 No Content on success
    """
    try:
        tariff_service = TariffService(db)
        await tariff_service.delete_tariff(tariff_id)
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