from typing import List, Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError, ConflictError, ValidationError
from app.models import TariffPlan
from app.repositories.payment_repository import PaymentRepository
from app.schemas.payment_schema import (
    TariffCreateRequest,
    TariffUpdateRequest,
    TariffDetailResponse,
    TariffListResponse
)
from app.schemas.common_schema import PaginationParams


class TariffService:
    """Service for managing tariff plans (admin operations)."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.payment_repo = PaymentRepository(db)
    
    async def get_tariff(self, tariff_id: UUID) -> TariffDetailResponse:
        """
        Get tariff plan by ID with subscription count.
        
        Args:
            tariff_id: UUID of the tariff plan
            
        Returns:
            TariffDetailResponse with tariff details
            
        Raises:
            NotFoundError: If tariff plan not found
        """
        tariff = await self.payment_repo.get_tariff_plan_by_id(tariff_id)
        if not tariff:
            raise NotFoundError(f"Tariff plan with ID {tariff_id} not found")
        
        subscription_count = await self.payment_repo.get_tariff_plan_subscription_count(tariff_id)
        
        return TariffDetailResponse(
            id=tariff.id,
            name=tariff.name,
            price_per_month=tariff.price_per_month,
            max_services=tariff.max_services,
            max_images_per_service=tariff.max_images_per_service,
            max_phone_numbers=tariff.max_phone_numbers,
            max_gallery_images=tariff.max_gallery_images,
            max_social_accounts=tariff.max_social_accounts,
            allow_website=tariff.allow_website,
            allow_cover_image=tariff.allow_cover_image,
            monthly_featured_cards=tariff.monthly_featured_cards,
            is_active=tariff.is_active,
            created_at=tariff.created_at,
            subscription_count=subscription_count
        )
    
    async def list_tariffs(
        self,
        include_inactive: bool = False,
        pagination: PaginationParams = PaginationParams()
    ) -> TariffListResponse:
        """
        List all tariff plans with pagination.
        
        Args:
            include_inactive: Whether to include inactive plans
            pagination: Pagination parameters
            
        Returns:
            TariffListResponse with paginated tariff plans
        """
        tariffs, total = await self.payment_repo.get_all_tariff_plans(
            include_inactive=include_inactive,
            offset=pagination.offset,
            limit=pagination.limit
        )
        
        # Get subscription counts for each tariff
        tariff_responses = []
        for tariff in tariffs:
            subscription_count = await self.payment_repo.get_tariff_plan_subscription_count(tariff.id)
            tariff_responses.append(
                TariffDetailResponse(
                    id=tariff.id,
                    name=tariff.name,
                    price_per_month=tariff.price_per_month,
                    max_services=tariff.max_services,
                    max_images_per_service=tariff.max_images_per_service,
                    max_phone_numbers=tariff.max_phone_numbers,
                    max_gallery_images=tariff.max_gallery_images,
                    max_social_accounts=tariff.max_social_accounts,
                    allow_website=tariff.allow_website,
                    allow_cover_image=tariff.allow_cover_image,
                    monthly_featured_cards=tariff.monthly_featured_cards,
                    is_active=tariff.is_active,
                    created_at=tariff.created_at,
                    subscription_count=subscription_count
                )
            )
        
        total_pages = (total + pagination.limit - 1) // pagination.limit
        has_more = pagination.page < total_pages
        
        return TariffListResponse(
            tariffs=tariff_responses,
            total=total,
            page=pagination.page,
            limit=pagination.limit,
            has_more=has_more,
            total_pages=total_pages
        )
    
    async def create_tariff(self, request: TariffCreateRequest) -> TariffDetailResponse:
        """
        Create a new tariff plan.
        
        Args:
            request: Tariff creation data
            
        Returns:
            TariffDetailResponse for created tariff plan
            
        Raises:
            ConflictError: If tariff plan name already exists
            ValidationError: If validation fails
        """
        # Check if tariff with same name exists
        existing = await self.payment_repo.get_tariff_plan_by_name(request.name)
        if existing:
            raise ConflictError(f"Tariff plan with name '{request.name}' already exists")
        
        # Create tariff plan
        tariff = TariffPlan(
            name=request.name.strip(),
            price_per_month=request.price_per_month,
            max_services=request.max_services,
            max_images_per_service=request.max_images_per_service,
            max_phone_numbers=request.max_phone_numbers,
            max_gallery_images=request.max_gallery_images,
            max_social_accounts=request.max_social_accounts,
            allow_website=request.allow_website,
            allow_cover_image=request.allow_cover_image,
            monthly_featured_cards=request.monthly_featured_cards,
            is_active=request.is_active
        )
        
        tariff = await self.payment_repo.create_tariff_plan(tariff)
        
        return TariffDetailResponse(
            id=tariff.id,
            name=tariff.name,
            price_per_month=tariff.price_per_month,
            max_services=tariff.max_services,
            max_images_per_service=tariff.max_images_per_service,
            max_phone_numbers=tariff.max_phone_numbers,
            max_gallery_images=tariff.max_gallery_images,
            max_social_accounts=tariff.max_social_accounts,
            allow_website=tariff.allow_website,
            allow_cover_image=tariff.allow_cover_image,
            monthly_featured_cards=tariff.monthly_featured_cards,
            is_active=tariff.is_active,
            created_at=tariff.created_at,
            subscription_count=0
        )
    
    async def update_tariff(
        self,
        tariff_id: UUID,
        request: TariffUpdateRequest
    ) -> TariffDetailResponse:
        """
        Update an existing tariff plan.
        
        Args:
            tariff_id: UUID of the tariff plan to update
            request: Tariff update data
            
        Returns:
            TariffDetailResponse for updated tariff plan
            
        Raises:
            NotFoundError: If tariff plan not found
            ConflictError: If new name conflicts with existing tariff plan
        """
        tariff = await self.payment_repo.get_tariff_plan_by_id(tariff_id)
        if not tariff:
            raise NotFoundError(f"Tariff plan with ID {tariff_id} not found")
        
        # Check name conflict if name is being updated
        if request.name and request.name.strip() != tariff.name:
            existing = await self.payment_repo.get_tariff_plan_by_name(request.name.strip())
            if existing and existing.id != tariff_id:
                raise ConflictError(f"Tariff plan with name '{request.name}' already exists")
            tariff.name = request.name.strip()
        
        # Update other fields
        if request.price_per_month is not None:
            tariff.price_per_month = request.price_per_month
        
        if request.max_services is not None:
            tariff.max_services = request.max_services
        
        if request.max_images_per_service is not None:
            tariff.max_images_per_service = request.max_images_per_service
        
        if request.max_phone_numbers is not None:
            tariff.max_phone_numbers = request.max_phone_numbers
        
        if request.max_gallery_images is not None:
            tariff.max_gallery_images = request.max_gallery_images
        
        if request.max_social_accounts is not None:
            tariff.max_social_accounts = request.max_social_accounts
        
        if request.allow_website is not None:
            tariff.allow_website = request.allow_website
        
        if request.allow_cover_image is not None:
            tariff.allow_cover_image = request.allow_cover_image
        
        if request.monthly_featured_cards is not None:
            tariff.monthly_featured_cards = request.monthly_featured_cards
        
        if request.is_active is not None:
            tariff.is_active = request.is_active
        
        tariff = await self.payment_repo.update_tariff_plan(tariff)
        
        subscription_count = await self.payment_repo.get_tariff_plan_subscription_count(tariff_id)
        
        return TariffDetailResponse(
            id=tariff.id,
            name=tariff.name,
            price_per_month=tariff.price_per_month,
            max_services=tariff.max_services,
            max_images_per_service=tariff.max_images_per_service,
            max_phone_numbers=tariff.max_phone_numbers,
            max_gallery_images=tariff.max_gallery_images,
            max_social_accounts=tariff.max_social_accounts,
            allow_website=tariff.allow_website,
            allow_cover_image=tariff.allow_cover_image,
            monthly_featured_cards=tariff.monthly_featured_cards,
            is_active=tariff.is_active,
            created_at=tariff.created_at,
            subscription_count=subscription_count
        )
    
    async def delete_tariff(self, tariff_id: UUID) -> bool:
        """
        Delete a tariff plan.
        
        If tariff plan has active subscriptions, it will be soft-deleted (is_active=False).
        If no active subscriptions, it will be hard-deleted.
        
        Args:
            tariff_id: UUID of the tariff plan to delete
            
        Returns:
            True if deleted successfully
            
        Raises:
            NotFoundError: If tariff plan not found
        """
        tariff = await self.payment_repo.get_tariff_plan_by_id(tariff_id)
        if not tariff:
            raise NotFoundError(f"Tariff plan with ID {tariff_id} not found")
        
        # Repository method handles soft/hard delete logic
        return await self.payment_repo.delete_tariff_plan(tariff_id)

