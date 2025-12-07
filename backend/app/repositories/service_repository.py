from datetime import datetime
from typing import List, Optional, Tuple

from sqlalchemy import and_, func, or_, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.models import (
    Service, 
    ServiceCategory, 
    Merchant, 
    User, 
    Image, 
    ImageType,
    FeaturedService,
    UserInteraction,
    InteractionType
)
from app.repositories.base import BaseRepository
from app.schemas.service_schema import ServiceSearchFilters
from app.utils.constants import UZBEKISTAN_REGIONS


class ServiceRepository(BaseRepository[Service]):
    """Repository for service-related database operations."""
    
    def __init__(self, db: AsyncSession):
        super().__init__(Service, db)
    
    async def get_categories_with_count(self) -> List[Tuple[ServiceCategory, int]]:
        """
        Get all active service categories with service counts.
        
        Returns:
            List of tuples: (ServiceCategory, service_count)
        """
        statement = (
            select(
                ServiceCategory,
                func.count(Service.id).label("service_count")
            )
            .outerjoin(Service, and_(
                Service.category_id == ServiceCategory.id,
                Service.is_active == True
            ))
            .where(ServiceCategory.is_active == True)
            .group_by(ServiceCategory.id)
            .order_by(ServiceCategory.display_order, ServiceCategory.name)
        )
        
        result = await self.db.execute(statement)
        rows = result.all()
        return [(r[0], r[1]) for r in rows]
    
    async def search_services(
        self,
        filters: ServiceSearchFilters,
        offset: int = 0,
        limit: int = 20
    ) -> Tuple[List[Service], int]:
        """
        Search services with filters and pagination.
        
        Args:
            filters: Search filters
            offset: Pagination offset
            limit: Pagination limit
            
        Returns:
            Tuple of (services_list, total_count)
        """
        # Base query with joins
        base_query = (
            select(Service)
            .join(Merchant, Service.merchant_id == Merchant.id)
            .join(User, Merchant.user_id == User.id)
            .join(ServiceCategory, Service.category_id == ServiceCategory.id)
            .where(
                and_(
                    Service.is_active == True,
                    User.is_active == True,
                    ServiceCategory.is_active == True
                )
            )
        )
        
        # Apply filters
        conditions = []
        
        # Text search in name and description
        if filters.query:
            search_term = f"%{filters.query.lower()}%"
            conditions.append(
                or_(
                    func.lower(Service.name).contains(search_term),
                    func.lower(Service.description).contains(search_term)
                )
            )
        
        # Category filter
        if filters.category_id:
            conditions.append(Service.category_id == filters.category_id)
        
        # Location filter
        if filters.location_region:
            conditions.append(Service.location_region == filters.location_region)
        
        # Price range filters
        if filters.min_price is not None:
            conditions.append(Service.price >= filters.min_price)
        if filters.max_price is not None:
            conditions.append(Service.price <= filters.max_price)
        
        # Rating filter
        if filters.min_rating is not None:
            conditions.append(Service.overall_rating >= filters.min_rating)
        
        # Verified merchant filter
        if filters.is_verified_merchant:
            conditions.append(Merchant.is_verified == True)
        
        # Apply all conditions
        if conditions:
            base_query = base_query.where(and_(*conditions))
        
        # Count query for total results
        count_statement = select(func.count()).select_from(
            base_query.subquery()
        )
        count_result = await self.db.execute(count_statement)
        total_count = count_result.scalar_one()
        
        # Apply sorting
        if filters.sort_by == "price":
            sort_column = Service.price
        elif filters.sort_by == "rating":
            sort_column = Service.overall_rating
        elif filters.sort_by == "popularity":
            sort_column = Service.view_count + Service.like_count
        elif filters.sort_by == "name":
            sort_column = Service.name
        else:  # Default to created_at
            sort_column = Service.created_at
        
        if filters.sort_order == "asc":
            base_query = base_query.order_by(sort_column.asc())
        else:
            base_query = base_query.order_by(sort_column.desc())
        
        # Apply pagination
        base_query = base_query.offset(offset).limit(limit)
        
        # Execute query
        result = await self.db.execute(base_query)
        services = result.scalars().all()

        return services, total_count
    
    async def get_featured_services(
        self, 
        limit: Optional[int] = None
    ) -> List[Service]:
        """
        Get currently active featured services.
        
        Args:
            limit: Optional limit for results
            
        Returns:
            List of featured services
        """
        now = datetime.now()
        
        statement = (
            select(Service)
            .join(FeaturedService, Service.id == FeaturedService.service_id)
            .join(Merchant, Service.merchant_id == Merchant.id)
            .join(User, Merchant.user_id == User.id)
            .where(
                and_(
                    Service.is_active == True,
                    User.is_active == True,
                    FeaturedService.is_active == True,
                    FeaturedService.start_date <= now,
                    FeaturedService.end_date > now
                )
            )
            .order_by(FeaturedService.created_at.desc())
        )
        
        if limit:
            statement = statement.limit(limit)

        result = await self.db.execute(statement)
        return result.scalars().all()
    
    async def get_service_with_details(self, service_id: str) -> Optional[Service]:
        """
        Get service with all related data loaded.
        
        Args:
            service_id: 9-digit numeric string ID of the service
            
        Returns:
            Service with relationships loaded or None
        """
        statement = (
            select(Service)
            .where(
                and_(
                    Service.id == service_id,
                    Service.is_active == True
                )
            )
        )
        
        result = await self.db.execute(statement)
        # scalar_one_or_none returns the model instance or None
        service = result.scalar_one_or_none()

        if service:
            # Increment view count
            await self.increment_view_count(service_id)

        return service
    
    async def get_service_images(self, service_id: str) -> List[Image]:
        """
        Get all images for a service ordered by display_order.
        
        Args:
            service_id: 9-digit numeric string ID of the service
            
        Returns:
            List of service images
        """
        statement = (
            select(Image)
            .where(
                and_(
                    Image.related_id == str(service_id),
                    Image.image_type == ImageType.SERVICE_IMAGE,
                    Image.is_active == True
                )
            )
            .order_by(Image.display_order, Image.created_at)
        )
        
        result = await self.db.execute(statement)
        # We expect a list of Image model instances
        return result.scalars().all()
    
    async def get_merchant_by_service(self, service_id: str) -> Optional[Merchant]:
        """
        Get merchant information for a service.
        
        Args:
            service_id: 9-digit numeric string ID of the service
            
        Returns:
            Merchant object or None
        """
        statement = (
            select(Merchant)
            .join(Service, Merchant.id == Service.merchant_id)
            .where(Service.id == service_id)
        )
        
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()
    
    async def get_category_by_service(self, service_id: str) -> Optional[ServiceCategory]:
        """
        Get category for a service.
        
        Args:
            service_id: 9-digit numeric string ID of the service
            
        Returns:
            ServiceCategory or None
        """
        statement = (
            select(ServiceCategory)
            .join(Service, ServiceCategory.id == Service.category_id)
            .where(Service.id == service_id)
        )
        
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()
    
    async def is_service_featured(self, service_id: str) -> Tuple[bool, Optional[datetime]]:
        """
        Check if service is currently featured and get end date.
        
        Args:
            service_id: 9-digit numeric string ID of the service
            
        Returns:
            Tuple of (is_featured, end_date)
        """
        now = datetime.now()
        
        statement = (
            select(FeaturedService.end_date)
            .where(
                and_(
                    FeaturedService.service_id == service_id,
                    FeaturedService.is_active == True,
                    FeaturedService.start_date <= now,
                    FeaturedService.end_date > now
                )
            )
            .order_by(FeaturedService.end_date.desc())
        )
        
        result = await self.db.execute(statement)
        # We selected a single column (end_date) so use scalar_one_or_none
        end_date = result.scalar_one_or_none()

        return (end_date is not None, end_date)
    
    async def increment_view_count(self, service_id: str) -> None:
        """
        Increment the view count for a service.
        
        Args:
            service_id: 9-digit numeric string ID of the service
        """
        statement = text(
            "UPDATE services SET view_count = view_count + 1 WHERE id = :service_id"
        )
        await self.db.execute(statement, {"service_id": service_id})
        await self.db.commit()
    
    async def record_user_interaction(
        self, 
        user_id: str, 
        service_id: str, 
        interaction_type: InteractionType
    ) -> bool:
        """
        Record a user interaction with a service.
        
        Args:
            user_id: 9-digit numeric string ID of the user
            service_id: 9-digit numeric string ID of the service
            interaction_type: Type of interaction
            
        Returns:
            bool: True if interaction was created, False if it already existed
        """
        # Check if interaction already exists for like/save/view
        if interaction_type in [InteractionType.LIKE, InteractionType.SAVE, InteractionType.VIEW]:
            existing_statement = select(UserInteraction).where(
                and_(
                    UserInteraction.user_id == user_id,
                    UserInteraction.service_id == service_id,
                    UserInteraction.interaction_type == interaction_type
                )
            )
            existing_result = await self.db.execute(existing_statement)
            if existing_result.scalars().first():
                return False  # Already exists, don't duplicate
        
        # Create new interaction
        interaction = UserInteraction(
            user_id=user_id,
            service_id=service_id,
            interaction_type=interaction_type
        )
        
        self.db.add(interaction)
        await self.db.commit()
        
        # Update service counters
        if interaction_type == InteractionType.LIKE:
            await self._increment_counter(service_id, "like_count")
        elif interaction_type == InteractionType.SAVE:
            await self._increment_counter(service_id, "save_count")
        elif interaction_type == InteractionType.SHARE:
            await self._increment_counter(service_id, "share_count")
        elif interaction_type == InteractionType.VIEW:
            await self._increment_counter(service_id, "view_count")
        
        return True  # Interaction was created
    
    async def _increment_counter(self, service_id: str, counter_field: str) -> None:
        """
        Increment a specific counter field for a service.
        
        Args:
            service_id: 9-digit numeric string ID of the service
            counter_field: Field name to increment
        """
        statement = text(
            f"UPDATE services SET {counter_field} = {counter_field} + 1 WHERE id = :service_id"
        )
        await self.db.execute(statement, {"service_id": service_id})
        await self.db.commit()
    
    async def get_services_by_category(
        self, 
        category_id: int, 
        offset: int = 0, 
        limit: int = 20
    ) -> Tuple[List[Service], int]:
        """
        Get services by category with pagination.
        
        Args:
            category_id: Integer ID of the category
            offset: Pagination offset
            limit: Pagination limit
            
        Returns:
            Tuple of (services_list, total_count)
        """
        base_conditions = and_(
            Service.category_id == category_id,
            Service.is_active == True
        )
        
        # Count query
        count_statement = select(func.count(Service.id)).where(base_conditions)
        count_result = await self.db.execute(count_statement)
        total_count = count_result.scalar_one()

        # Services query
        statement = (
            select(Service)
            .where(base_conditions)
            .order_by(Service.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        
        result = await self.db.execute(statement)
        services = result.scalars().all()

        return services, total_count
    
    async def get_user_interactions(
        self,
        user_id: str,
        interaction_type: Optional[InteractionType] = None
    ) -> List[Tuple['UserInteraction', Service]]:
        """
        Get user interactions with services.
        
        Args:
            user_id: 9-digit numeric string ID of the user
            interaction_type: Optional filter by interaction type (LIKE or SAVE)
            
        Returns:
            List of tuples (UserInteraction, Service)
        """
        # Build query
        conditions = [UserInteraction.user_id == user_id]
        
        # Filter by interaction type if specified (only LIKE and SAVE are meaningful for listing)
        if interaction_type and interaction_type in [InteractionType.LIKE, InteractionType.SAVE]:
            conditions.append(UserInteraction.interaction_type == interaction_type)
        else:
            # Default to LIKE and SAVE only (not VIEW or SHARE)
            conditions.append(
                UserInteraction.interaction_type.in_([InteractionType.LIKE, InteractionType.SAVE])
            )
        
        # Join with services and filter only active services
        statement = (
            select(UserInteraction, Service)
            .join(Service, UserInteraction.service_id == Service.id)
            .where(
                and_(
                    *conditions,
                    Service.is_active == True
                )
            )
            .order_by(UserInteraction.created_at.desc())
        )
        
        result = await self.db.execute(statement)
        return result.all()
