from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status, File, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.api.deps import get_current_admin
from app.models import User
from app.services.category_service import CategoryService
from app.services.service_manager import ServiceManager
from app.repositories.category_repository import CategoryRepository
from app.schemas.category_schema import (
    CategoryCreateRequest,
    CategoryUpdateRequest,
    CategoryDetailResponse,
    CategoryListResponse
)
from app.schemas.service_schema import ServiceCategoriesResponse
from app.schemas.merchant_schema import ImageUploadResponse
from app.schemas.common_schema import PaginationParams, SuccessResponse
from app.core.exceptions import (
    WedyException,
    NotFoundError,
    ConflictError,
    ValidationError,
    ForbiddenError
)
from app.utils.s3_client import s3_image_manager

router = APIRouter()


@router.get("/", response_model=ServiceCategoriesResponse)
async def get_categories(
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get all active service categories with service counts (public endpoint).
    
    Returns:
        ServiceCategoriesResponse: List of active categories with service counts
    """
    service_manager = ServiceManager(db)
    return await service_manager.get_categories()


@router.get("/admin/list", response_model=CategoryListResponse)
async def list_categories_admin(
    include_inactive: bool = Query(False, description="Include inactive categories"),
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get all categories with pagination (admin only).
    
    Args:
        include_inactive: Whether to include inactive categories
        page: Page number (1-based)
        limit: Items per page (1-100)
        current_user: Current authenticated admin user
        db: Database session
        
    Returns:
        CategoryListResponse with paginated categories
    """
    try:
        category_service = CategoryService(db)
        pagination = PaginationParams(page=page, limit=limit)
        
        return await category_service.list_categories(
            include_inactive=include_inactive,
            pagination=pagination
        )
    
    except WedyException as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/{category_id}", response_model=CategoryDetailResponse)
async def get_category(
    category_id: int,
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get category by ID (public endpoint).
    
    Args:
        category_id: Integer ID of the category
        db: Database session
        
    Returns:
        CategoryDetailResponse with category details
    """
    try:
        category_service = CategoryService(db)
        return await category_service.get_category(category_id)
    
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


@router.post("/", response_model=CategoryDetailResponse, status_code=status.HTTP_201_CREATED)
async def create_category(
    request: CategoryCreateRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Create a new category (admin only).
    
    Args:
        request: Category creation data
        current_user: Current authenticated admin user
        db: Database session
        
    Returns:
        CategoryDetailResponse for created category
    """
    try:
        category_service = CategoryService(db)
        return await category_service.create_category(request)
    
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


@router.put("/{category_id}", response_model=CategoryDetailResponse)
async def update_category(
    category_id: int,
    request: CategoryUpdateRequest,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Update an existing category (admin only).
    
    Args:
        category_id: Integer ID of the category to update
        request: Category update data
        current_user: Current authenticated admin user
        db: Database session
        
    Returns:
        CategoryDetailResponse for updated category
    """
    try:
        category_service = CategoryService(db)
        return await category_service.update_category(category_id, request)
    
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


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    category_id: int,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Delete a category (admin only).
    
    If category has active services, it will be soft-deleted (is_active=False).
    If no active services, it will be hard-deleted.
    
    Args:
        category_id: Integer ID of the category to delete
        current_user: Current authenticated admin user
        db: Database session
        
    Returns:
        204 No Content on success
    """
    try:
        category_service = CategoryService(db)
        await category_service.delete_category(category_id)
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


@router.post("/{category_id}/icon", response_model=ImageUploadResponse)
async def upload_category_icon(
    category_id: int,
    file: UploadFile = File(..., description="Category icon image file"),
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Upload category icon directly to S3 and update category's icon_url (admin only).
    
    Args:
        category_id: Integer ID of the category
        file: Icon image file
        current_user: Current authenticated admin user
        db: Database session
        
    Returns:
        ImageUploadResponse: Confirmation of upload with S3 URL
    """
    try:
        # Get category to check for existing icon
        category_repo = CategoryRepository(db)
        category = await category_repo.get_category_by_id(category_id)
        if not category:
            raise NotFoundError(f"Category with ID {category_id} not found")
        
        # Delete old icon from S3 if it exists
        old_icon_url = category.icon_url
        if old_icon_url:
            s3_image_manager.delete_image(old_icon_url)
        
        # Read file content for validation and upload
        content = await file.read()
        content_type = file.content_type or 'application/octet-stream'
        content_length = len(content)
        
        # Validate image constraints
        s3_image_manager.validate_image_constraints(content_type, content_length)
        
        # Upload file object to S3
        from io import BytesIO
        fileobj = BytesIO(content)
        
        s3_url = s3_image_manager.upload_fileobj(
            fileobj=fileobj,
            file_name=file.filename or "icon",
            content_type=content_type,
            image_type="category_icon",
            related_id=str(category_id)
        )
        
        # Update category icon URL
        updated = await category_repo.update_icon_url(category_id, s3_url)
        
        if not updated:
            raise NotFoundError(f"Category with ID {category_id} not found")
        
        return ImageUploadResponse(
            success=True,
            message="Category icon uploaded successfully",
            s3_url=s3_url,
            presigned_url=None
        )
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Category icon upload failed: {str(e)}"
        )


@router.delete("/{category_id}/icon", response_model=SuccessResponse)
async def delete_category_icon(
    category_id: int,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Delete category icon (admin only).
    
    Args:
        category_id: Integer ID of the category
        current_user: Current authenticated admin user
        db: Database session
        
    Returns:
        SuccessResponse: Confirmation of deletion
    """
    try:
        # Get category to get icon URL before deletion
        category_repo = CategoryRepository(db)
        category = await category_repo.get_category_by_id(category_id)
        if not category:
            raise NotFoundError(f"Category with ID {category_id} not found")
        
        # Delete icon from S3 if it exists
        if category.icon_url:
            s3_image_manager.delete_image(category.icon_url)
        
        # Delete icon (set to None)
        deleted = await category_repo.delete_icon(category_id)
        
        return SuccessResponse(
            success=True,
            message="Category icon deleted successfully"
        )
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete category icon: {str(e)}"
        )
