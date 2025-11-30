from typing import List, Optional, Tuple
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError, ConflictError, ValidationError, ForbiddenError
from app.models import ServiceCategory, Service
from app.repositories.category_repository import CategoryRepository
from app.schemas.category_schema import (
    CategoryCreateRequest,
    CategoryUpdateRequest,
    CategoryDetailResponse,
    CategoryListResponse
)
from app.schemas.common_schema import PaginationParams


class CategoryService:
    """Service for managing service categories (admin operations)."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.category_repo = CategoryRepository(db)
    
    async def get_category(self, category_id: UUID) -> CategoryDetailResponse:
        """
        Get category by ID with service count.
        
        Args:
            category_id: UUID of the category
            
        Returns:
            CategoryDetailResponse with category details
            
        Raises:
            NotFoundError: If category not found
        """
        category = await self.category_repo.get_category_by_id(category_id)
        if not category:
            raise NotFoundError(f"Category with ID {category_id} not found")
        
        service_count = await self.category_repo.get_category_service_count(category_id)
        
        return CategoryDetailResponse(
            id=category.id,
            name=category.name,
            description=category.description,
            icon_url=category.icon_url,
            display_order=category.display_order,
            is_active=category.is_active,
            created_at=category.created_at,
            service_count=service_count
        )
    
    async def list_categories(
        self,
        include_inactive: bool = False,
        pagination: PaginationParams = PaginationParams()
    ) -> CategoryListResponse:
        """
        List all categories with pagination.
        
        Args:
            include_inactive: Whether to include inactive categories
            pagination: Pagination parameters
            
        Returns:
            CategoryListResponse with paginated categories
        """
        categories, total = await self.category_repo.get_all_categories(
            include_inactive=include_inactive,
            offset=pagination.offset,
            limit=pagination.limit
        )
        
        # Get service counts for each category
        category_responses = []
        for category in categories:
            service_count = await self.category_repo.get_category_service_count(category.id)
            category_responses.append(
                CategoryDetailResponse(
                    id=category.id,
                    name=category.name,
                    description=category.description,
                    icon_url=category.icon_url,
                    display_order=category.display_order,
                    is_active=category.is_active,
                    created_at=category.created_at,
                    service_count=service_count
                )
            )
        
        total_pages = (total + pagination.limit - 1) // pagination.limit
        has_more = pagination.page < total_pages
        
        return CategoryListResponse(
            categories=category_responses,
            total=total,
            page=pagination.page,
            limit=pagination.limit,
            has_more=has_more,
            total_pages=total_pages
        )
    
    async def create_category(self, request: CategoryCreateRequest) -> CategoryDetailResponse:
        """
        Create a new category.
        
        Args:
            request: Category creation data
            
        Returns:
            CategoryDetailResponse for created category
            
        Raises:
            ConflictError: If category name already exists
            ValidationError: If validation fails
        """
        # Check if category with same name exists
        existing = await self.category_repo.get_category_by_name(request.name)
        if existing:
            raise ConflictError(f"Category with name '{request.name}' already exists")
        
        # Create category
        category = ServiceCategory(
            name=request.name.strip(),
            description=request.description.strip() if request.description else None,
            display_order=request.display_order,
            is_active=request.is_active
        )
        
        category = await self.category_repo.create_category(category)
        
        return CategoryDetailResponse(
            id=category.id,
            name=category.name,
            description=category.description,
            icon_url=category.icon_url,
            display_order=category.display_order,
            is_active=category.is_active,
            created_at=category.created_at,
            service_count=0
        )
    
    async def update_category(
        self,
        category_id: UUID,
        request: CategoryUpdateRequest
    ) -> CategoryDetailResponse:
        """
        Update an existing category.
        
        Args:
            category_id: UUID of the category to update
            request: Category update data
            
        Returns:
            CategoryDetailResponse for updated category
            
        Raises:
            NotFoundError: If category not found
            ConflictError: If new name conflicts with existing category
        """
        category = await self.category_repo.get_category_by_id(category_id)
        if not category:
            raise NotFoundError(f"Category with ID {category_id} not found")
        
        # Check name conflict if name is being updated
        if request.name and request.name.strip() != category.name:
            existing = await self.category_repo.get_category_by_name(request.name.strip())
            if existing and existing.id != category_id:
                raise ConflictError(f"Category with name '{request.name}' already exists")
            category.name = request.name.strip()
        
        # Update other fields
        if request.description is not None:
            category.description = request.description.strip() if request.description else None
        
        if request.display_order is not None:
            category.display_order = request.display_order
        
        if request.is_active is not None:
            category.is_active = request.is_active
        
        category = await self.category_repo.update_category(category)
        
        service_count = await self.category_repo.get_category_service_count(category_id)
        
        return CategoryDetailResponse(
            id=category.id,
            name=category.name,
            description=category.description,
            icon_url=category.icon_url,
            display_order=category.display_order,
            is_active=category.is_active,
            created_at=category.created_at,
            service_count=service_count
        )
    
    async def delete_category(self, category_id: UUID) -> bool:
        """
        Delete a category.
        
        If category has active services, it will be soft-deleted (is_active=False).
        If no active services, it will be hard-deleted.
        
        Args:
            category_id: UUID of the category to delete
            
        Returns:
            True if deleted successfully
            
        Raises:
            NotFoundError: If category not found
        """
        category = await self.category_repo.get_category_by_id(category_id)
        if not category:
            raise NotFoundError(f"Category with ID {category_id} not found")
        
        # Repository method handles soft/hard delete logic
        return await self.category_repo.delete_category(category_id)
