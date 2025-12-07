from datetime import datetime, date, timedelta
from typing import List, Optional
from uuid import uuid4, UUID

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from app.core.exceptions import NotFoundError, ValidationError, ForbiddenError, PaymentRequiredError
from app.models import (
    User,
    Merchant,
    MerchantContact,
    ContactType,
    Service,
    ServiceCategory,
    Image,
    ImageType,
    FeatureType,
    FeaturedService,
    InteractionType
)
from app.repositories.merchant_repository import MerchantRepository
from app.repositories.user_repository import UserRepository
from app.repositories.service_repository import ServiceRepository
from app.schemas.merchant_schema import (
    MerchantProfileResponse,
    ActiveSubscriptionInfo,
    MerchantProfileUpdateRequest,
    MerchantContactResponse,
    MerchantContactRequest,
    MerchantContactUpdateRequest,
    MerchantGalleryResponse,
    ServiceCreateRequest,
    ServiceUpdateRequest,
    MerchantServiceResponse,
    MerchantServicesResponse,
    ServiceAnalyticsResponse,
    MerchantAnalyticsResponse,
    FeaturedServiceResponse,
    MerchantFeaturedServicesResponse
)
from app.utils.constants import UZBEKISTAN_REGIONS


class MerchantManager:
    """Merchant business logic manager with tariff enforcement."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.merchant_repo = MerchantRepository(db)
        self.user_repo = UserRepository(db)
        self.service_repo = ServiceRepository(db)
    
    async def get_merchant_profile(self, user_id: UUID) -> MerchantProfileResponse:
        """
        Get merchant profile with subscription and usage information.
        
        Args:
            user_id: 9-digit numeric string ID of the user
            
        Returns:
            Complete merchant profile with subscription info
            
        Raises:
            NotFoundError: If merchant profile not found
        """
        # Get merchant with user data
        merchant = await self.merchant_repo.get_merchant_by_user_id(user_id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError("User not found")
        
        # Get active subscription
        subscription_info = None
        subscription_data = await self.merchant_repo.get_active_subscription(merchant.id)
        
        if subscription_data:
            subscription, tariff_plan = subscription_data
            days_remaining = (subscription.end_date - date.today()).days
            
            subscription_info = ActiveSubscriptionInfo(
                id=subscription.id,
                tariff_plan_id=tariff_plan.id,
                tariff_plan_name=tariff_plan.name,
                start_date=subscription.start_date,
                end_date=subscription.end_date,
                status=subscription.status,
                days_remaining=max(0, days_remaining),
                max_services=tariff_plan.max_services,
                max_images_per_service=tariff_plan.max_images_per_service,
                max_phone_numbers=tariff_plan.max_phone_numbers,
                max_gallery_images=tariff_plan.max_gallery_images,
                max_social_accounts=tariff_plan.max_social_accounts,
                allow_website=tariff_plan.allow_website,
                allow_cover_image=tariff_plan.allow_cover_image,
                monthly_featured_cards=tariff_plan.monthly_featured_cards
            )
        
        # Get current usage stats
        current_services_count = await self.merchant_repo.count_merchant_services(merchant.id)
        current_gallery_images_count = await self.merchant_repo.count_gallery_images(merchant.id)
        current_phone_contacts_count = await self.merchant_repo.count_contacts_by_type(
            merchant.id, ContactType.PHONE
        )
        current_social_contacts_count = await self.merchant_repo.count_contacts_by_type(
            merchant.id, ContactType.SOCIAL_MEDIA
        )
        
        return MerchantProfileResponse(
            id=merchant.id,
            user_id=merchant.user_id,
            business_name=merchant.business_name,
            description=merchant.description,
            cover_image_url=merchant.cover_image_url,
            location_region=merchant.location_region,
            latitude=merchant.latitude,
            longitude=merchant.longitude,
            website_url=merchant.website_url,
            is_verified=merchant.is_verified,
            overall_rating=merchant.overall_rating,
            total_reviews=merchant.total_reviews,
            created_at=merchant.created_at,
            name=user.name,
            phone_number=user.phone_number,
            avatar_url=user.avatar_url,
            subscription=subscription_info,
            current_services_count=current_services_count,
            current_gallery_images_count=current_gallery_images_count,
            current_phone_contacts_count=current_phone_contacts_count,
            current_social_contacts_count=current_social_contacts_count
        )
    
    async def update_merchant_profile(
        self, 
        user_id: str, 
        update_data: MerchantProfileUpdateRequest
    ) -> MerchantProfileResponse:
        """
        Update merchant profile with business rule validation.
        
        Args:
            user_id: 9-digit numeric string ID of the user
            update_data: Profile update data
            
        Returns:
            Updated merchant profile
            
        Raises:
            NotFoundError: If merchant not found
            PaymentRequiredError: If subscription expired
            ForbiddenError: If trying to set website without permission
            ValidationError: If data validation fails
        """
        merchant = await self.merchant_repo.get_merchant_by_user_id(user_id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        # Check active subscription
        await self._ensure_active_subscription(merchant.id)
        
        # Validate location region
        if update_data.location_region and update_data.location_region not in UZBEKISTAN_REGIONS:
            raise ValidationError(f"Invalid region: {update_data.location_region}")
        
        # Check website permission
        if update_data.website_url is not None:
            subscription_data = await self.merchant_repo.get_active_subscription(merchant.id)
            if subscription_data:
                _, tariff_plan = subscription_data
                if not tariff_plan.allow_website:
                    raise ForbiddenError("Website URL not allowed in current tariff plan")
        
        # Update merchant fields
        if update_data.business_name is not None:
            merchant.business_name = update_data.business_name
        if update_data.description is not None:
            merchant.description = update_data.description
        if update_data.location_region is not None:
            merchant.location_region = update_data.location_region
        if update_data.latitude is not None:
            merchant.latitude = update_data.latitude
        if update_data.longitude is not None:
            merchant.longitude = update_data.longitude
        if update_data.website_url is not None:
            merchant.website_url = update_data.website_url
        
        await self.merchant_repo.update(merchant)
        
        # Return updated profile
        return await self.get_merchant_profile(user_id)
    
    async def get_merchant_contacts(self, user_id: UUID) -> List[MerchantContactResponse]:
        """
        Get all merchant contacts.
        
        Args:
            user_id: 9-digit numeric string ID of the user
            
        Returns:
            List of merchant contacts
        """
        merchant = await self.merchant_repo.get_merchant_by_user_id(user_id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        contacts = await self.merchant_repo.get_merchant_contacts(merchant.id)
        
        return [
            MerchantContactResponse(
                id=contact.id,
                contact_type=contact.contact_type,
                contact_value=contact.contact_value,
                platform_name=contact.platform_name,
                display_order=contact.display_order,
                is_active=contact.is_active,
                created_at=contact.created_at
            )
            for contact in contacts
        ]
    
    async def add_merchant_contact(
        self, 
        user_id: str, 
        contact_data: MerchantContactRequest
    ) -> MerchantContactResponse:
        """
        Add merchant contact with tariff limit validation.
        
        Args:
            user_id: 9-digit numeric string ID of the user
            contact_data: Contact data
            
        Returns:
            Created contact
            
        Raises:
            NotFoundError: If merchant not found
            PaymentRequiredError: If subscription expired
            ForbiddenError: If tariff limit exceeded
        """
        merchant = await self.merchant_repo.get_merchant_by_user_id(user_id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        # Check active subscription and limits
        subscription_data = await self._ensure_active_subscription(merchant.id)
        _, tariff_plan = subscription_data
        
        # Check contact type limits
        current_count = await self.merchant_repo.count_contacts_by_type(
            merchant.id, contact_data.contact_type
        )
        
        if contact_data.contact_type == ContactType.PHONE:
            if current_count >= tariff_plan.max_phone_numbers:
                raise ForbiddenError(
                    f"Phone contact limit exceeded. Current: {current_count}, "
                    f"Max allowed: {tariff_plan.max_phone_numbers}"
                )
        elif contact_data.contact_type == ContactType.SOCIAL_MEDIA:
            if current_count >= tariff_plan.max_social_accounts:
                raise ForbiddenError(
                    f"Social media contact limit exceeded. Current: {current_count}, "
                    f"Max allowed: {tariff_plan.max_social_accounts}"
                )
        
        # Create new contact
        contact = MerchantContact(
            id=uuid4(),
            merchant_id=merchant.id,
            contact_type=contact_data.contact_type,
            contact_value=contact_data.contact_value,
            platform_name=contact_data.platform_name,
            display_order=contact_data.display_order or 0
        )
        
        created_contact = await self.merchant_repo.create_contact(contact)
        
        return MerchantContactResponse(
            id=created_contact.id,
            contact_type=created_contact.contact_type,
            contact_value=created_contact.contact_value,
            platform_name=created_contact.platform_name,
            display_order=created_contact.display_order,
            is_active=created_contact.is_active,
            created_at=created_contact.created_at
        )
    
    async def get_merchant_services(self, user_id: UUID) -> MerchantServicesResponse:
        """
        Get all merchant services with analytics.
        
        Args:
            user_id: 9-digit numeric string ID of the user
            
        Returns:
            Merchant services with statistics
        """
        merchant = await self.merchant_repo.get_merchant_by_user_id(user_id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        services_with_categories = await self.merchant_repo.get_merchant_services(merchant.id)
        
        service_responses = []
        active_count = 0
        
        for service, category in services_with_categories:
            # Count images for this service
            images_count = await self.merchant_repo.count_service_images(service.id)
            
            # Check if featured
            is_featured, featured_until = await self.service_repo.is_service_featured(service.id)
            
            service_response = MerchantServiceResponse(
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
                category_id=category.id,
                category_name=category.name,
                images_count=images_count,
                is_featured=is_featured,
                featured_until=featured_until
            )
            
            service_responses.append(service_response)
            if service.is_active:
                active_count += 1
        
        return MerchantServicesResponse(
            services=service_responses,
            total=len(service_responses),
            active_count=active_count,
            inactive_count=len(service_responses) - active_count
        )
    
    async def create_merchant_service(
        self, 
        user_id: str, 
        service_data: ServiceCreateRequest
    ) -> MerchantServiceResponse:
        """
        Create merchant service with tariff limit validation.
        
        Args:
            user_id: 9-digit numeric string ID of the user
            service_data: Service creation data
            
        Returns:
            Created service
            
        Raises:
            NotFoundError: If merchant or category not found
            PaymentRequiredError: If subscription expired
            ForbiddenError: If service limit exceeded
            ValidationError: If data validation fails
        """
        merchant = await self.merchant_repo.get_merchant_by_user_id(user_id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        # Check active subscription and limits
        subscription_data = await self._ensure_active_subscription(merchant.id)
        _, tariff_plan = subscription_data
        
        # Check service limit
        current_services = await self.merchant_repo.count_merchant_services(merchant.id)
        if current_services >= tariff_plan.max_services:
            raise ForbiddenError(
                f"Service limit exceeded. Current: {current_services}, "
                f"Max allowed: {tariff_plan.max_services}"
            )
        
        # Validate category exists
        from app.models import ServiceCategory
        category_stmt = select(ServiceCategory).where(ServiceCategory.id == service_data.category_id)
        category_result = await self.db.execute(category_stmt)
        category = category_result.scalar_one_or_none()
        if not category:
            raise NotFoundError("Service category not found")
        
        # Validate location region
        if service_data.location_region not in UZBEKISTAN_REGIONS:
            raise ValidationError(f"Invalid region: {service_data.location_region}")
        
        # Create service (ID will be auto-generated by default_factory)
        service = Service(
            merchant_id=merchant.id,
            category_id=service_data.category_id,
            name=service_data.name,
            description=service_data.description,
            price=service_data.price,
            location_region=service_data.location_region,
            latitude=service_data.latitude,
            longitude=service_data.longitude
        )
        
        created_service = await self.service_repo.create(service)
        
        # Get category for response (already validated above)
        
        return MerchantServiceResponse(
            id=created_service.id,
            name=created_service.name,
            description=created_service.description,
            price=created_service.price,
            location_region=created_service.location_region,
            latitude=created_service.latitude,
            longitude=created_service.longitude,
            view_count=created_service.view_count,
            like_count=created_service.like_count,
            save_count=created_service.save_count,
            share_count=created_service.share_count,
            overall_rating=created_service.overall_rating,
            total_reviews=created_service.total_reviews,
            is_active=created_service.is_active,
            created_at=created_service.created_at,
            updated_at=created_service.updated_at,
            category_id=category.id if category else service_data.category_id,
            category_name=category.name if category else "Unknown",
            images_count=0,
            is_featured=False
        )
    
    async def get_merchant_analytics(self, user_id: UUID) -> MerchantAnalyticsResponse:
        """
        Get comprehensive merchant analytics.
        
        Args:
            user_id: 9-digit numeric string ID of the user
            
        Returns:
            Merchant analytics dashboard data
        """
        merchant = await self.merchant_repo.get_merchant_by_user_id(user_id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        # Get service analytics
        analytics_data = await self.merchant_repo.get_service_analytics(merchant.id)
        
        service_analytics = []
        total_views = total_likes = total_saves = total_shares = total_reviews = 0
        views_today = likes_today = saves_today = shares_today = 0
        ratings_sum = 0
        rated_services = 0
        
        for service, review_count, daily_metrics in analytics_data:
            service_analysis = ServiceAnalyticsResponse(
                service_id=service.id,
                service_name=service.name,
                view_count_total=service.view_count,
                like_count_total=service.like_count,
                save_count_total=service.save_count,
                share_count_total=service.share_count,
                review_count_total=review_count,
                view_count_today=daily_metrics.views_today if daily_metrics else 0,
                like_count_today=daily_metrics.likes_today if daily_metrics else 0,
                save_count_today=daily_metrics.saves_today if daily_metrics else 0,
                share_count_today=daily_metrics.shares_today if daily_metrics else 0,
                overall_rating=service.overall_rating
            )
            
            service_analytics.append(service_analysis)
            
            # Accumulate totals
            total_views += service.view_count
            total_likes += service.like_count
            total_saves += service.save_count
            total_shares += service.share_count
            total_reviews += review_count
            
            if daily_metrics:
                views_today += daily_metrics.views_today
                likes_today += daily_metrics.likes_today
                saves_today += daily_metrics.saves_today
                shares_today += daily_metrics.shares_today
            
            if service.overall_rating > 0:
                ratings_sum += service.overall_rating
                rated_services += 1
        
        overall_rating = ratings_sum / rated_services if rated_services > 0 else 0
        
        return MerchantAnalyticsResponse(
            services=service_analytics,
            total_services=len(service_analytics),
            total_views=total_views,
            total_likes=total_likes,
            total_saves=total_saves,
            total_shares=total_shares,
            total_reviews=total_reviews,
            overall_rating=round(overall_rating, 2),
            views_today=views_today,
            likes_today=likes_today,
            saves_today=saves_today,
            shares_today=shares_today
        )
    
    async def get_featured_services_tracking(self, user_id: UUID) -> MerchantFeaturedServicesResponse:
        """
        Get featured services tracking for merchant.
        
        Args:
            user_id: 9-digit numeric string ID of the user
            
        Returns:
            Featured services tracking data
        """
        merchant = await self.merchant_repo.get_merchant_by_user_id(user_id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        featured_data = await self.merchant_repo.get_featured_services(merchant.id)
        
        featured_responses = []
        active_count = 0
        
        now = datetime.now()
        
        for featured_service, service in featured_data:
            is_currently_active = (
                featured_service.is_active and
                featured_service.start_date <= now and
                featured_service.end_date > now
            )
            
            if is_currently_active:
                active_count += 1
            
            featured_response = FeaturedServiceResponse(
                id=featured_service.id,
                service_id=service.id,
                service_name=service.name,
                start_date=featured_service.start_date,
                end_date=featured_service.end_date,
                days_duration=featured_service.days_duration,
                amount_paid=featured_service.amount_paid,
                feature_type=featured_service.feature_type.value,
                is_active=is_currently_active,
                created_at=featured_service.created_at
            )
            
            featured_responses.append(featured_response)
        
        # Get remaining free slots (monthly allocations used this month)
        subscription_data = await self.merchant_repo.get_active_subscription(merchant.id)
        remaining_free_slots = 0
        if subscription_data:
            _, tariff_plan = subscription_data
            # Use the now variable already defined above
            # Count monthly allocations used in current month
            monthly_used = await self.merchant_repo.count_monthly_featured_allocations_used(
                merchant.id, now.year, now.month
            )
            remaining_free_slots = max(0, tariff_plan.monthly_featured_cards - monthly_used)
        
        return MerchantFeaturedServicesResponse(
            featured_services=featured_responses,
            total=len(featured_responses),
            active_count=active_count,
            remaining_free_slots=remaining_free_slots
        )
    
    async def create_monthly_featured_service(
        self,
        user_id: str,
        service_id: UUID
    ) -> FeaturedServiceResponse:
        """
        Create monthly featured service allocation (free).
        
        Args:
            user_id: 9-digit numeric string ID of the user
            service_id: 9-digit numeric string ID of the service to feature
            
        Returns:
            Featured service response
            
        Raises:
            NotFoundError: If merchant or service not found
            PaymentRequiredError: If subscription expired
            ForbiddenError: If monthly allocation limit exceeded
        """
        merchant = await self.merchant_repo.get_merchant_by_user_id(user_id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        # Check active subscription and limits
        subscription_data = await self._ensure_active_subscription(merchant.id)
        _, tariff_plan = subscription_data
        
        # Check monthly allocation limit
        from datetime import datetime
        now = datetime.now()
        monthly_used = await self.merchant_repo.count_monthly_featured_allocations_used(
            merchant.id, now.year, now.month
        )
        
        if monthly_used >= tariff_plan.monthly_featured_cards:
            raise ForbiddenError(
                f"Monthly featured allocation limit exceeded. Used: {monthly_used}, "
                f"Max allowed: {tariff_plan.monthly_featured_cards}"
            )
        
        # Verify service belongs to merchant
        service_stmt = select(Service).where(
            and_(
                Service.id == service_id,
                Service.merchant_id == merchant.id
            )
        )
        service_result = await self.db.execute(service_stmt)
        service = service_result.scalar_one_or_none()
        
        if not service:
            raise NotFoundError("Service not found or not owned by merchant")
        
        # Create monthly featured service (1 month duration)
        start_date = datetime.now()
        end_date = start_date + timedelta(days=30)  # 1 month
        
        featured_service = FeaturedService(
            service_id=service.id,
            merchant_id=merchant.id,
            payment_id=None,  # No payment for monthly allocation
            start_date=start_date,
            end_date=end_date,
            days_duration=30,
            amount_paid=None,
            feature_type=FeatureType.MONTHLY_ALLOCATION,
            is_active=True
        )
        
        created_featured = await self.merchant_repo.create_featured_service(featured_service)
        
        return FeaturedServiceResponse(
            id=created_featured.id,
            service_id=service.id,
            service_name=service.name,
            start_date=created_featured.start_date,
            end_date=created_featured.end_date,
            days_duration=created_featured.days_duration,
            amount_paid=created_featured.amount_paid,
            feature_type=created_featured.feature_type.value,
            is_active=True,
            created_at=created_featured.created_at
        )
    
    async def _ensure_active_subscription(self, merchant_id: UUID) -> tuple:
        """
        Ensure merchant has active subscription.
        
        Args:
            merchant_id: UUID of the merchant
            
        Returns:
            Tuple of (subscription, tariff_plan)
            
        Raises:
            PaymentRequiredError: If subscription expired or not found
        """
        subscription_data = await self.merchant_repo.get_active_subscription(merchant_id)
        
        if not subscription_data:
            raise PaymentRequiredError(
                "Active subscription required to perform this action"
            )
        
        subscription, tariff_plan = subscription_data
        
        # Double-check date
        if subscription.end_date < date.today():
            raise PaymentRequiredError(
                f"Subscription expired on {subscription.end_date}. Please renew to continue."
            )
        
        return subscription_data