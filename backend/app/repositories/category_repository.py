from app.models.service_model import Service
from app.models.category_model import ServiceCategory
from app.repositories.base import BaseRepository
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from uuid import UUID
from typing import Optional, Tuple, List
from sqlalchemy import and_, func

class CategoryRepository(BaseRepository[ServiceCategory]):
    """Repository for category-related database operations."""
    
    def __init__(self, db: AsyncSession):
        super().__init__(ServiceCategory, db)

    async def get_category_by_id(self, category_id: UUID) -> Optional[ServiceCategory]:
        """
        Get category by ID.
        
        Args:
            category_id: UUID of the category
            
        Returns:
            ServiceCategory or None
        """
        statement = select(ServiceCategory).where(ServiceCategory.id == category_id)
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()
    
    async def get_category_by_name(self, name: str) -> Optional[ServiceCategory]:
        """
        Get category by name.
        
        Args:
            name: Category name
            
        Returns:
            ServiceCategory or None
        """
        statement = select(ServiceCategory).where(ServiceCategory.name == name)
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()
    
    async def get_all_categories(
        self, 
        include_inactive: bool = False,
        offset: int = 0,
        limit: int = 100
    ) -> Tuple[List[ServiceCategory], int]:
        """
        Get all categories with pagination.
        
        Args:
            include_inactive: Whether to include inactive categories
            offset: Pagination offset
            limit: Pagination limit
            
        Returns:
            Tuple of (categories_list, total_count)
        """
        # Count query
        count_conditions = []
        if not include_inactive:
            count_conditions.append(ServiceCategory.is_active == True)
        
        count_statement = select(func.count(ServiceCategory.id))
        if count_conditions:
            count_statement = count_statement.where(and_(*count_conditions))
        
        count_result = await self.db.execute(count_statement)
        total_count = count_result.scalar_one()
        
        # Categories query
        statement = select(ServiceCategory)
        if not include_inactive:
            statement = statement.where(ServiceCategory.is_active == True)
        
        statement = statement.order_by(
            ServiceCategory.display_order, 
            ServiceCategory.name
        ).offset(offset).limit(limit)
        
        result = await self.db.execute(statement)
        categories = result.scalars().all()
        
        return categories, total_count
    
    async def create_category(self, category: ServiceCategory) -> ServiceCategory:
        """
        Create a new category.
        
        Args:
            category: ServiceCategory instance to create
            
        Returns:
            Created ServiceCategory
        """
        self.db.add(category)
        await self.db.commit()
        await self.db.refresh(category)
        return category
    
    async def update_category(self, category: ServiceCategory) -> ServiceCategory:
        """
        Update an existing category.
        
        Args:
            category: ServiceCategory instance to update
            
        Returns:
            Updated ServiceCategory
        """
        self.db.add(category)
        await self.db.commit()
        await self.db.refresh(category)
        return category
    
    async def delete_category(self, category_id: UUID) -> bool:
        """
        Delete a category (soft delete by setting is_active=False).
        
        Args:
            category_id: UUID of the category to delete
            
        Returns:
            True if deleted, False if not found
        """
        category = await self.get_category_by_id(category_id)
        if not category:
            return False
        
        # Check if category has active services
        service_count_statement = select(func.count(Service.id)).where(
            and_(
                Service.category_id == category_id,
                Service.is_active == True
            )
        )
        service_count_result = await self.db.execute(service_count_statement)
        service_count = service_count_result.scalar_one()
        
        if service_count > 0:
            # Soft delete: set is_active to False
            category.is_active = False
            await self.db.commit()
        else:
            # Hard delete if no services
            await self.db.delete(category)
            await self.db.commit()
        
        return True
    
    async def get_category_service_count(self, category_id: UUID) -> int:
        """
        Get count of active services in a category.
        
        Args:
            category_id: UUID of the category
            
        Returns:
            Count of active services
        """
        statement = select(func.count(Service.id)).where(
            and_(
                Service.category_id == category_id,
                Service.is_active == True
            )
        )
        result = await self.db.execute(statement)
        return result.scalar_one()
    
    async def update_icon_url(self, category_id: UUID, icon_url: str) -> bool:
        """
        Update category icon URL.
        
        Args:
            category_id: UUID of the category
            icon_url: S3 URL of the icon image
            
        Returns:
            True if updated, False if category not found
        """
        category = await self.get_category_by_id(category_id)
        if not category:
            return False
        
        category.icon_url = icon_url
        self.db.add(category)
        await self.db.commit()
        return True
    
    async def delete_icon(self, category_id: UUID) -> bool:
        """
        Delete category icon (set icon_url to None).
        
        Args:
            category_id: UUID of the category
            
        Returns:
            True if deleted, False if category not found
        """
        category = await self.get_category_by_id(category_id)
        if not category:
            return False
        
        category.icon_url = None
        self.db.add(category)
        await self.db.commit()
        return True
