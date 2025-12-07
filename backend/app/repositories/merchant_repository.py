from datetime import datetime, date
from typing import List, Optional, Tuple
from uuid import UUID

from sqlalchemy import and_, func, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.models import (
    Merchant,
    User,
    MerchantContact,
    ContactType,
    Service,
    ServiceCategory,
    Image,
    ImageType,
    MerchantSubscription,
    TariffPlan,
    SubscriptionStatus,
    FeaturedService,
    FeatureType,
    DailyServiceMetrics,
    Review
)
from app.repositories.base import BaseRepository


class MerchantRepository(BaseRepository[Merchant]):
    """Repository for merchant-related database operations."""
    
    def __init__(self, db: AsyncSession):
        super().__init__(Merchant, db)
    
    async def get_merchant_by_user_id(self, user_id: str) -> Optional[Merchant]:
        """
        Get merchant profile by user ID.
        
        Args:
            user_id: 9-digit numeric string ID of the user
            
        Returns:
            Merchant profile or None
        """
        statement = select(Merchant).where(Merchant.user_id == user_id)
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()
    
    async def get_merchant_with_user(self, merchant_id: UUID) -> Optional[Tuple[Merchant, User]]:
        """
        Get merchant with associated user data.
        
        Args:
            merchant_id: UUID of the merchant
            
        Returns:
            Tuple of (Merchant, User) or None
        """
        statement = (
            select(Merchant, User)
            .join(User, Merchant.user_id == User.id)
            .where(Merchant.id == merchant_id)
        )
        result = await self.db.execute(statement)
        row = result.first()
        return (row[0], row[1]) if row else None
    
    async def get_active_subscription(self, merchant_id: UUID) -> Optional[Tuple[MerchantSubscription, TariffPlan]]:
        """
        Get active subscription with tariff plan details.
        
        Args:
            merchant_id: UUID of the merchant
            
        Returns:
            Tuple of (MerchantSubscription, TariffPlan) or None
        """
        today = date.today()
        
        statement = (
            select(MerchantSubscription, TariffPlan)
            .join(TariffPlan, MerchantSubscription.tariff_plan_id == TariffPlan.id)
            .where(
                and_(
                    MerchantSubscription.merchant_id == merchant_id,
                    MerchantSubscription.status == SubscriptionStatus.ACTIVE,
                    MerchantSubscription.end_date >= today
                )
            )
            .order_by(MerchantSubscription.end_date.desc())
        )
        result = await self.db.execute(statement)
        row = result.first()
        return (row[0], row[1]) if row else None
    
    async def get_merchant_contacts(self, merchant_id: UUID) -> List[MerchantContact]:
        """
        Get all contacts for a merchant.
        
        Args:
            merchant_id: UUID of the merchant
            
        Returns:
            List of merchant contacts
        """
        statement = (
            select(MerchantContact)
            .where(
                and_(
                    MerchantContact.merchant_id == merchant_id,
                    MerchantContact.is_active == True
                )
            )
            .order_by(MerchantContact.display_order, MerchantContact.created_at)
        )
        result = await self.db.execute(statement)
        return result.scalars().all()
    
    async def count_contacts_by_type(self, merchant_id: UUID, contact_type: ContactType) -> int:
        """
        Count active contacts by type for a merchant.
        
        Args:
            merchant_id: UUID of the merchant
            contact_type: Type of contact to count
            
        Returns:
            Count of contacts
        """
        statement = (
            select(func.count(MerchantContact.id))
            .where(
                and_(
                    MerchantContact.merchant_id == merchant_id,
                    MerchantContact.contact_type == contact_type,
                    MerchantContact.is_active == True
                )
            )
        )
        result = await self.db.execute(statement)
        return result.scalar_one()
    
    async def get_merchant_services(self, merchant_id: UUID) -> List[Tuple[Service, ServiceCategory]]:
        """
        Get all services for a merchant with category info.
        
        Args:
            merchant_id: UUID of the merchant
            
        Returns:
            List of (Service, ServiceCategory) tuples
        """
        statement = (
            select(Service, ServiceCategory)
            .join(ServiceCategory, Service.category_id == ServiceCategory.id)
            .where(Service.merchant_id == merchant_id)
            .order_by(Service.created_at.desc())
        )
        result = await self.db.execute(statement)
        rows = result.all()
        return [(r[0], r[1]) for r in rows]
    
    async def count_merchant_services(self, merchant_id: UUID) -> int:
        """
        Count active services for a merchant.
        
        Args:
            merchant_id: UUID of the merchant
            
        Returns:
            Count of active services
        """
        statement = (
            select(func.count(Service.id))
            .where(
                and_(
                    Service.merchant_id == merchant_id,
                    Service.is_active == True
                )
            )
        )
        result = await self.db.execute(statement)
        return result.scalar_one()
    
    async def get_merchant_gallery_images(self, merchant_id: UUID) -> List[Image]:
        """
        Get gallery images for a merchant.
        
        Args:
            merchant_id: UUID of the merchant
            
        Returns:
            List of gallery images
        """
        statement = (
            select(Image)
            .where(
                and_(
                    Image.related_id == merchant_id,
                    Image.image_type == ImageType.MERCHANT_GALLERY,
                    Image.is_active == True
                )
            )
            .order_by(Image.display_order, Image.created_at)
        )
        result = await self.db.execute(statement)
        return result.scalars().all()
    
    async def count_gallery_images(self, merchant_id: UUID) -> int:
        """
        Count gallery images for a merchant.
        
        Args:
            merchant_id: UUID of the merchant
            
        Returns:
            Count of gallery images
        """
        statement = (
            select(func.count(Image.id))
            .where(
                and_(
                    Image.related_id == merchant_id,
                    Image.image_type == ImageType.MERCHANT_GALLERY,
                    Image.is_active == True
                )
            )
        )
        result = await self.db.execute(statement)
        return result.scalar_one()
    
    async def count_service_images(self, service_id: str) -> int:
        """
        Count images for a specific service.
        
        Args:
            service_id: 9-digit numeric string ID of the service
            
        Returns:
            Count of service images
        """
        statement = (
            select(func.count(Image.id))
            .where(
                and_(
                    Image.related_id == str(service_id),
                    Image.image_type == ImageType.SERVICE_IMAGE,
                    Image.is_active == True
                )
            )
        )
        result = await self.db.execute(statement)
        return result.scalar_one()
    
    async def get_service_analytics(self, merchant_id: UUID) -> List[Tuple[Service, int, Optional[DailyServiceMetrics]]]:
        """
        Get service analytics for a merchant.
        
        Args:
            merchant_id: UUID of the merchant
            
        Returns:
            List of (Service, review_count, today_metrics) tuples
        """
        today = date.today()
        
        # Get services with review counts and today's metrics
        statement = (
            select(
                Service,
                func.count(Review.id).label("review_count"),
                DailyServiceMetrics
            )
            .outerjoin(Review, and_(
                Review.service_id == Service.id,
                Review.is_active == True
            ))
            .outerjoin(DailyServiceMetrics, and_(
                DailyServiceMetrics.service_id == Service.id,
                DailyServiceMetrics.metric_date == today
            ))
            .where(Service.merchant_id == merchant_id)
            .group_by(Service.id, DailyServiceMetrics.id)
            .order_by(Service.created_at.desc())
        )
        result = await self.db.execute(statement)
        rows = result.all()
        return [(r[0], r[1], r[2]) for r in rows]
    
    async def get_featured_services(self, merchant_id: UUID) -> List[Tuple[FeaturedService, Service]]:
        """
        Get featured services for a merchant.
        
        Args:
            merchant_id: UUID of the merchant
            
        Returns:
            List of (FeaturedService, Service) tuples
        """
        statement = (
            select(FeaturedService, Service)
            .join(Service, FeaturedService.service_id == Service.id)
            .where(FeaturedService.merchant_id == merchant_id)
            .order_by(FeaturedService.created_at.desc())
        )
        result = await self.db.execute(statement)
        rows = result.all()
        return [(r[0], r[1]) for r in rows]
    
    async def count_active_featured_services(self, merchant_id: UUID) -> int:
        """
        Count currently active featured services.
        
        Args:
            merchant_id: UUID of the merchant
            
        Returns:
            Count of active featured services
        """
        now = datetime.now()
        
        statement = (
            select(func.count(FeaturedService.id))
            .where(
                and_(
                    FeaturedService.merchant_id == merchant_id,
                    FeaturedService.is_active == True,
                    FeaturedService.start_date <= now,
                    FeaturedService.end_date > now
                )
            )
        )
        result = await self.db.execute(statement)
        return result.scalar_one() or 0
    
    async def count_monthly_featured_allocations_used(
        self, 
        merchant_id: UUID, 
        year: int, 
        month: int
    ) -> int:
        """
        Count monthly featured allocations used in a specific month.
        
        Args:
            merchant_id: UUID of the merchant
            year: Year to check
            month: Month to check (1-12)
            
        Returns:
            Count of monthly allocations used in the given month
        """
        # Get featured services that started in the given month/year
        # and are of type MONTHLY_ALLOCATION
        start_of_month = datetime(year, month, 1)
        if month == 12:
            end_of_month = datetime(year + 1, 1, 1)
        else:
            end_of_month = datetime(year, month + 1, 1)
        
        statement = (
            select(func.count(FeaturedService.id))
            .where(
                and_(
                    FeaturedService.merchant_id == merchant_id,
                    FeaturedService.feature_type == FeatureType.MONTHLY_ALLOCATION,
                    FeaturedService.start_date >= start_of_month,
                    FeaturedService.start_date < end_of_month
                )
            )
        )
        result = await self.db.execute(statement)
        return result.scalar_one() or 0
    
    async def create_featured_service(self, featured_service: FeaturedService) -> FeaturedService:
        """
        Create a featured service record.
        
        Args:
            featured_service: FeaturedService instance
            
        Returns:
            Created featured service
        """
        self.db.add(featured_service)
        await self.db.commit()
        await self.db.refresh(featured_service)
        return featured_service
    
    async def create_contact(self, contact: MerchantContact) -> MerchantContact:
        """
        Create a new merchant contact.
        
        Args:
            contact: MerchantContact instance
            
        Returns:
            Created contact
        """
        self.db.add(contact)
        await self.db.commit()
        await self.db.refresh(contact)
        return contact
    
    async def update_contact(self, contact: MerchantContact) -> MerchantContact:
        """
        Update merchant contact.
        
        Args:
            contact: Updated MerchantContact instance
            
        Returns:
            Updated contact
        """
        self.db.add(contact)
        await self.db.commit()
        await self.db.refresh(contact)
        return contact
    
    async def get_contact_by_id(self, contact_id: UUID, merchant_id: UUID) -> Optional[MerchantContact]:
        """
        Get merchant contact by ID, verifying it belongs to the merchant.
        
        Args:
            contact_id: UUID of the contact
            merchant_id: UUID of the merchant
            
        Returns:
            MerchantContact instance or None if not found
        """
        statement = select(MerchantContact).where(
            and_(
                MerchantContact.id == contact_id,
                MerchantContact.merchant_id == merchant_id
            )
        )
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()
    
    async def delete_contact(self, contact_id: UUID) -> bool:
        """
        Delete (deactivate) a merchant contact.
        
        Args:
            contact_id: UUID of the contact
            
        Returns:
            True if deleted, False if not found
        """
        statement = select(MerchantContact).where(MerchantContact.id == contact_id)
        result = await self.db.execute(statement)
        contact = result.scalar_one_or_none()

        if contact:
            contact.is_active = False
            self.db.add(contact)
            await self.db.commit()
            return True
        return False
    
    async def create_gallery_image(self, image: Image) -> Image:
        """
        Create a gallery image record.
        
        Args:
            image: Image instance
            
        Returns:
            Created image record
        """
        self.db.add(image)
        await self.db.commit()
        await self.db.refresh(image)
        return image
    
    async def delete_gallery_image(self, image_id: UUID, merchant_id: UUID) -> bool:
        """
        Delete a gallery image.
        
        Args:
            image_id: UUID of the image
            merchant_id: UUID of the merchant (for security)
            
        Returns:
            True if deleted, False if not found
        """
        statement = (
            select(Image)
            .where(
                and_(
                    Image.id == image_id,
                    Image.related_id == merchant_id,
                    Image.image_type == ImageType.MERCHANT_GALLERY
                )
            )
        )
        result = await self.db.execute(statement)
        image = result.scalar_one_or_none()

        if image:
            image.is_active = False
            self.db.add(image)
            await self.db.commit()
            return True
        return False
    
    async def update_cover_image(self, merchant_id: UUID, s3_url: str) -> bool:
        """
        Update merchant cover image URL.
        
        Args:
            merchant_id: UUID of the merchant
            s3_url: S3 URL of the cover image
            
        Returns:
            True if updated, False if merchant not found
        """
        statement = select(Merchant).where(Merchant.id == merchant_id)
        result = await self.db.execute(statement)
        merchant = result.scalar_one_or_none()

        if merchant:
            merchant.cover_image_url = s3_url
            self.db.add(merchant)
            await self.db.commit()
            return True
        return False
    
    async def delete_cover_image(self, merchant_id: UUID) -> bool:
        """
        Delete merchant cover image (set to None).
        
        Args:
            merchant_id: UUID of the merchant
            
        Returns:
            True if deleted, False if merchant not found
        """
        statement = select(Merchant).where(Merchant.id == merchant_id)
        result = await self.db.execute(statement)
        merchant = result.scalar_one_or_none()

        if merchant:
            merchant.cover_image_url = None
            self.db.add(merchant)
            await self.db.commit()
            return True
        return False
