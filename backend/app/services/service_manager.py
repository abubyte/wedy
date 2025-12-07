from datetime import datetime
from typing import List, Optional

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError, ValidationError
from app.models import User, InteractionType
from app.repositories.service_repository import ServiceRepository
from app.repositories.user_repository import UserRepository
from app.schemas.service_schema import (
    ServiceCategoryResponse,
    ServiceCategoriesResponse,
    ServiceListItem,
    ServiceDetailResponse,
    ServiceSearchFilters,
    PaginatedServiceResponse,
    FeaturedServicesResponse,
    MerchantBasicInfo,
    ServiceImageResponse
)
from app.schemas.common_schema import PaginationParams
from app.utils.constants import UZBEKISTAN_REGIONS, INTERACTION_TYPES


class ServiceManager:
    """Service business logic manager."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.service_repo = ServiceRepository(db)
        self.user_repo = UserRepository(db)
    
    async def get_categories(self) -> ServiceCategoriesResponse:
        """
        Get all service categories with service counts.
        
        Returns:
            ServiceCategoriesResponse with categories and total count
        """
        categories_data = await self.service_repo.get_categories_with_count()
        
        categories = [
            ServiceCategoryResponse(
                id=category.id,
                name=category.name,
                description=category.description,
                icon_url=category.icon_url,
                display_order=category.display_order,
                service_count=count
            )
            for category, count in categories_data
        ]
        
        return ServiceCategoriesResponse(
            categories=categories,
            total=len(categories)
        )
    
    async def browse_services(
        self,
        category_id: Optional[int] = None,
        pagination: PaginationParams = PaginationParams()
    ) -> PaginatedServiceResponse:
        """
        Browse services with optional category filter.
        
        Args:
            category_id: Optional category filter
            pagination: Pagination parameters
            
        Returns:
            PaginatedServiceResponse with services and pagination info
        """
        if category_id:
            services, total = await self.service_repo.get_services_by_category(
                category_id=category_id,
                offset=pagination.offset,
                limit=pagination.limit
            )
        else:
            # Get all services with default filters
            filters = ServiceSearchFilters()
            services, total = await self.service_repo.search_services(
                filters=filters,
                offset=pagination.offset,
                limit=pagination.limit
            )
        
        # Convert to response format
        service_items = []
        for service in services:
            service_item = await self._convert_to_service_list_item(service)
            service_items.append(service_item)
        
        total_pages = (total + pagination.limit - 1) // pagination.limit
        has_more = pagination.page < total_pages
        
        return PaginatedServiceResponse(
            services=service_items,
            total=total,
            page=pagination.page,
            limit=pagination.limit,
            has_more=has_more,
            total_pages=total_pages
        )
    
    async def search_services(
        self,
        filters: ServiceSearchFilters,
        pagination: PaginationParams = PaginationParams()
    ) -> PaginatedServiceResponse:
        """
        Search services with filters.
        
        Args:
            filters: Search filters
            pagination: Pagination parameters
            
        Returns:
            PaginatedServiceResponse with matching services
            
        Raises:
            ValidationError: If filters are invalid
        """
        # Validate filters
        await self._validate_search_filters(filters)
        
        services, total = await self.service_repo.search_services(
            filters=filters,
            offset=pagination.offset,
            limit=pagination.limit
        )
        
        # Convert to response format
        service_items = []
        for service in services:
            service_item = await self._convert_to_service_list_item(service)
            service_items.append(service_item)
        
        total_pages = (total + pagination.limit - 1) // pagination.limit
        has_more = pagination.page < total_pages
        
        return PaginatedServiceResponse(
            services=service_items,
            total=total,
            page=pagination.page,
            limit=pagination.limit,
            has_more=has_more,
            total_pages=total_pages
        )
    
    async def get_featured_services(self, limit: Optional[int] = None) -> FeaturedServicesResponse:
        """
        Get currently active featured services.
        
        Args:
            limit: Optional limit for results
            
        Returns:
            FeaturedServicesResponse with featured services
        """
        services = await self.service_repo.get_featured_services(limit=limit)
        
        # Convert to response format
        service_items = []
        for service in services:
            service_item = await self._convert_to_service_list_item(service)
            service_item.is_featured = True
            service_items.append(service_item)
        
        return FeaturedServicesResponse(
            services=service_items,
            total=len(service_items)
        )
    
    async def get_service_details(self, service_id: str) -> ServiceDetailResponse:
        """
        Get detailed service information.
        
        Args:
            service_id: 9-digit numeric string ID of the service
            
        Returns:
            ServiceDetailResponse with complete service info
            
        Raises:
            NotFoundError: If service not found or inactive
        """
        service = await self.service_repo.get_service_with_details(service_id)
        if not service:
            raise NotFoundError("Service not found or inactive")
        
        # Get related data
        merchant = await self.service_repo.get_merchant_by_service(service_id)
        category = await self.service_repo.get_category_by_service(service_id)
        images = await self.service_repo.get_service_images(service_id)
        is_featured, featured_until = await self.service_repo.is_service_featured(service_id)
        
        if not merchant or not category:
            raise NotFoundError("Service data incomplete")
        
        # Convert images
        image_responses = [
            ServiceImageResponse(
                id=img.id,
                s3_url=img.s3_url,
                file_name=img.file_name,
                display_order=img.display_order
            )
            for img in images
        ]
        
        # Get merchant user info
        merchant_user = await self.user_repo.get_by_id(merchant.user_id)
        if not merchant_user:
            raise NotFoundError("Merchant user not found")
        
        merchant_info = MerchantBasicInfo(
            id=merchant.id,
            business_name=merchant.business_name,
            overall_rating=merchant.overall_rating,
            total_reviews=merchant.total_reviews,
            location_region=merchant.location_region,
            is_verified=merchant.is_verified,
            avatar_url=merchant_user.avatar_url
        )
        
        return ServiceDetailResponse(
            id=service.id,
            name=service.name,
            description=service.description,
            price=service.price,
            location_region=service.location_region,
            latitude=service.latitude,
            longitude=service.longitude,
            view_count=service.view_count,
            like_count=service.like_count,
            save_count=service.save_count,
            share_count=service.share_count,
            overall_rating=service.overall_rating,
            total_reviews=service.total_reviews,
            is_active=service.is_active,
            created_at=service.created_at,
            updated_at=service.updated_at,
            merchant=merchant_info,
            category_id=category.id,
            category_name=category.name,
            images=image_responses,
            is_featured=is_featured,
            featured_until=featured_until
        )
    
    async def record_service_interaction(
        self,
        user_id: str,
        service_id: str,
        interaction_type: str
    ) -> dict:
        """
        Record user interaction with a service.
        
        Args:
            user_id: 9-digit numeric string ID of the user
            service_id: 9-digit numeric string ID of the service
            interaction_type: Type of interaction
            
        Returns:
            Dict with success status and new count
            
        Raises:
            NotFoundError: If user or service not found
            ValidationError: If interaction type invalid
        """
        # Validate interaction type
        if interaction_type not in INTERACTION_TYPES:
            raise ValidationError(f"Invalid interaction type: {interaction_type}")
        
        # Check if user exists
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError("User not found")
        
        # Check if service exists
        service = await self.service_repo.get_by_id(service_id)
        if not service or not service.is_active:
            raise NotFoundError("Service not found or inactive")
        
        # Convert string to enum
        interaction_enum = InteractionType(interaction_type)
        
        # Record interaction (returns True if created, False if already existed)
        was_created = await self.service_repo.record_user_interaction(
            user_id=user_id,
            service_id=service_id,
            interaction_type=interaction_enum
        )
        
        # Get updated service to return new count
        updated_service = await self.service_repo.get_by_id(service_id)
        
        # Return appropriate count based on interaction type
        if interaction_type == "like":
            new_count = updated_service.like_count
        elif interaction_type == "save":
            new_count = updated_service.save_count
        elif interaction_type == "share":
            new_count = updated_service.share_count
        else:  # view
            new_count = updated_service.view_count
        
        # Return success message - even if interaction already existed
        if was_created:
            message = f"Service {interaction_type} recorded successfully"
        else:
            message = f"Service {interaction_type} already recorded"
        
        return {
            "success": True,
            "message": message,
            "new_count": new_count
        }
    
    async def _convert_to_service_list_item(self, service) -> ServiceListItem:
        """
        Convert Service model to ServiceListItem response.
        
        Args:
            service: Service model instance
            
        Returns:
            ServiceListItem response object
            
        Raises:
            NotFoundError: If merchant or category not found for service
        """
        # Get merchant info
        merchant = await self.service_repo.get_merchant_by_service(service.id)
        if not merchant:
            raise NotFoundError(f"Merchant not found for service {service.id}")
        
        merchant_user = await self.user_repo.get_by_id(merchant.user_id)
        
        # Get category info
        category = await self.service_repo.get_category_by_service(service.id)
        if not category:
            raise NotFoundError(f"Category not found for service {service.id}")
        
        # Get main image (first image)
        images = await self.service_repo.get_service_images(service.id)
        main_image_url = images[0].s3_url if images else None
        
        # Check if featured
        is_featured, _ = await self.service_repo.is_service_featured(service.id)
        
        merchant_info = MerchantBasicInfo(
            id=merchant.id,
            business_name=merchant.business_name or "",
            overall_rating=merchant.overall_rating,
            total_reviews=merchant.total_reviews,
            location_region=merchant.location_region or "",
            is_verified=merchant.is_verified,
            avatar_url=merchant_user.avatar_url if merchant_user else None
        )
        
        return ServiceListItem(
            id=service.id,
            name=service.name,
            description=service.description,
            price=service.price,
            location_region=service.location_region,
            overall_rating=service.overall_rating,
            total_reviews=service.total_reviews,
            view_count=service.view_count,
            like_count=service.like_count,
            save_count=service.save_count,
            created_at=service.created_at,
            merchant=merchant_info,
            category_id=category.id,
            category_name=category.name,
            main_image_url=main_image_url,
            is_featured=is_featured
        )
    
    async def _validate_search_filters(self, filters: ServiceSearchFilters) -> None:
        """
        Validate search filters.
        
        Args:
            filters: ServiceSearchFilters to validate
            
        Raises:
            ValidationError: If filters are invalid
        """
        # Validate region
        if filters.location_region and filters.location_region not in UZBEKISTAN_REGIONS:
            raise ValidationError(f"Invalid region: {filters.location_region}")
        
        # Validate price range
        if (filters.min_price is not None and 
            filters.max_price is not None and 
            filters.min_price > filters.max_price):
            raise ValidationError("min_price cannot be greater than max_price")
        
        # Validate sort options
        valid_sort_by = ["created_at", "price", "rating", "popularity", "name"]
        if filters.sort_by and filters.sort_by not in valid_sort_by:
            raise ValidationError(f"Invalid sort_by: {filters.sort_by}")
        
        valid_sort_order = ["asc", "desc"]
        if filters.sort_order and filters.sort_order not in valid_sort_order:
            raise ValidationError(f"Invalid sort_order: {filters.sort_order}")
        
        # Validate rating range
        if filters.min_rating is not None and (filters.min_rating < 0 or filters.min_rating > 5):
            raise ValidationError("min_rating must be between 0 and 5")
