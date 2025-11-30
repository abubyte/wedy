"""
Tests for MerchantManager.
"""
import pytest
from uuid import uuid4
from datetime import datetime, date, timedelta

from app.services.merchant_manager import MerchantManager
from app.core.exceptions import NotFoundError, ValidationError, ForbiddenError, PaymentRequiredError
from app.schemas.merchant_schema import (
    MerchantProfileUpdateRequest,
    MerchantContactRequest,
    ServiceCreateRequest
)
from app.models import (
    MerchantSubscription, SubscriptionStatus,
    MerchantContact, ContactType
)


@pytest.mark.asyncio
class TestMerchantManager:
    """Test MerchantManager methods."""
    
    async def test_get_merchant_profile(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User"
    ):
        """Test getting merchant profile."""
        manager = MerchantManager(db_session)
        
        profile = await manager.get_merchant_profile(sample_merchant_user.id)
        
        assert profile.id == sample_merchant.id
        assert profile.user_id == sample_merchant_user.id
        assert profile.business_name == sample_merchant.business_name
        assert profile.name == sample_merchant_user.name
        assert profile.phone_number == sample_merchant_user.phone_number
        assert profile.subscription is None  # No subscription initially
    
    async def test_get_merchant_profile_with_subscription(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_tariff: "TariffPlan"
    ):
        """Test getting merchant profile with active subscription."""
        manager = MerchantManager(db_session)
        
        # Create active subscription
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        profile = await manager.get_merchant_profile(sample_merchant_user.id)
        
        assert profile.subscription is not None
        assert profile.subscription.tariff_plan_id == sample_tariff.id
        assert profile.subscription.days_remaining >= 0
    
    async def test_get_merchant_profile_not_found(
        self,
        db_session
    ):
        """Test getting non-existent merchant profile raises NotFoundError."""
        manager = MerchantManager(db_session)
        
        with pytest.raises(NotFoundError, match="Merchant profile not found"):
            await manager.get_merchant_profile(uuid4())
    
    async def test_update_merchant_profile(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_tariff: "TariffPlan"
    ):
        """Test updating merchant profile."""
        manager = MerchantManager(db_session)
        
        # Create active subscription
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        update_data = MerchantProfileUpdateRequest(
            business_name="Updated Business Name",
            description="Updated description",
            location_region="Samarkand"
        )
        
        updated_profile = await manager.update_merchant_profile(
            sample_merchant_user.id,
            update_data
        )
        
        assert updated_profile.business_name == "Updated Business Name"
        assert updated_profile.description == "Updated description"
        assert updated_profile.location_region == "Samarkand"
    
    async def test_update_merchant_profile_no_subscription(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User"
    ):
        """Test updating profile without subscription raises PaymentRequiredError."""
        manager = MerchantManager(db_session)
        
        update_data = MerchantProfileUpdateRequest(
            business_name="Updated Name"
        )
        
        with pytest.raises(PaymentRequiredError, match="Active subscription required"):
            await manager.update_merchant_profile(sample_merchant_user.id, update_data)
    
    async def test_update_merchant_profile_invalid_region(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_tariff: "TariffPlan"
    ):
        """Test updating profile with invalid region raises ValidationError."""
        manager = MerchantManager(db_session)
        
        # Create active subscription
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        update_data = MerchantProfileUpdateRequest(
            location_region="InvalidRegion"
        )
        
        with pytest.raises(ValidationError, match="Invalid region"):
            await manager.update_merchant_profile(sample_merchant_user.id, update_data)
    
    async def test_get_merchant_contacts(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User"
    ):
        """Test getting merchant contacts."""
        manager = MerchantManager(db_session)
        
        # Create contacts
        contact = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998901234567",
            is_active=True
        )
        db_session.add(contact)
        await db_session.commit()
        
        contacts = await manager.get_merchant_contacts(sample_merchant_user.id)
        
        assert len(contacts) == 1
        assert contacts[0].contact_value == "+998901234567"
        assert contacts[0].contact_type == ContactType.PHONE
    
    async def test_get_merchant_contacts_not_found(
        self,
        db_session
    ):
        """Test getting contacts for non-existent merchant raises NotFoundError."""
        manager = MerchantManager(db_session)
        
        with pytest.raises(NotFoundError, match="Merchant profile not found"):
            await manager.get_merchant_contacts(uuid4())
    
    async def test_add_merchant_contact(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_tariff: "TariffPlan"
    ):
        """Test adding merchant contact."""
        manager = MerchantManager(db_session)
        
        # Create active subscription
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        contact_data = MerchantContactRequest(
            contact_type=ContactType.PHONE,
            contact_value="+998901234567",
            display_order=1
        )
        
        created = await manager.add_merchant_contact(
            sample_merchant_user.id,
            contact_data
        )
        
        assert created.contact_value == "+998901234567"
        assert created.contact_type == ContactType.PHONE
    
    async def test_add_merchant_contact_limit_exceeded(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_tariff: "TariffPlan"
    ):
        """Test adding contact when limit exceeded raises ForbiddenError."""
        manager = MerchantManager(db_session)
        
        # Create subscription with low limit
        sample_tariff.max_phone_numbers = 1
        db_session.add(sample_tariff)
        await db_session.commit()
        
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        
        # Create one contact (at limit)
        contact1 = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998901234567",
            is_active=True
        )
        db_session.add(contact1)
        await db_session.commit()
        
        # Try to add another
        contact_data = MerchantContactRequest(
            contact_type=ContactType.PHONE,
            contact_value="+998907654321"
        )
        
        with pytest.raises(ForbiddenError, match="Phone contact limit exceeded"):
            await manager.add_merchant_contact(sample_merchant_user.id, contact_data)
    
    async def test_get_merchant_services(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_service: "Service"
    ):
        """Test getting merchant services."""
        manager = MerchantManager(db_session)
        
        response = await manager.get_merchant_services(sample_merchant_user.id)
        
        assert response.total >= 1
        assert response.active_count >= 1
        service_ids = [s.id for s in response.services]
        assert sample_service.id in service_ids
    
    async def test_get_merchant_services_not_found(
        self,
        db_session
    ):
        """Test getting services for non-existent merchant raises NotFoundError."""
        manager = MerchantManager(db_session)
        
        with pytest.raises(NotFoundError, match="Merchant profile not found"):
            await manager.get_merchant_services(uuid4())
    
    async def test_create_merchant_service(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_category: "ServiceCategory",
        sample_tariff: "TariffPlan"
    ):
        """Test creating merchant service."""
        manager = MerchantManager(db_session)
        
        # Create active subscription
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        service_data = ServiceCreateRequest(
            name="New Service",
            description="Service description",
            category_id=sample_category.id,
            price=1000000.0,
            location_region="Tashkent"
        )
        
        created = await manager.create_merchant_service(
            sample_merchant_user.id,
            service_data
        )
        
        assert created.name == "New Service"
        assert created.price == 1000000.0
        assert created.category_id == sample_category.id
    
    async def test_create_merchant_service_limit_exceeded(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_category: "ServiceCategory",
        sample_tariff: "TariffPlan"
    ):
        """Test creating service when limit exceeded raises ForbiddenError."""
        manager = MerchantManager(db_session)
        
        # Create subscription with low limit
        sample_tariff.max_services = 1
        db_session.add(sample_tariff)
        await db_session.commit()
        
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        # Create one service (at limit)
        from app.models import Service
        service = Service(
            merchant_id=sample_merchant.id,
            category_id=sample_category.id,
            name="Existing Service",
            description="Existing service",
            price=1000000.0,
            location_region="Tashkent",
            is_active=True
        )
        db_session.add(service)
        await db_session.commit()
        
        # Try to create another
        service_data = ServiceCreateRequest(
            name="New Service",
            description="Service description",
            category_id=sample_category.id,
            price=2000000.0,
            location_region="Tashkent"
        )
        
        with pytest.raises(ForbiddenError, match="Service limit exceeded"):
            await manager.create_merchant_service(sample_merchant_user.id, service_data)
    
    async def test_create_merchant_service_invalid_category(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_tariff: "TariffPlan"
    ):
        """Test creating service with invalid category raises NotFoundError."""
        manager = MerchantManager(db_session)
        
        # Create active subscription
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        service_data = ServiceCreateRequest(
            name="New Service",
            description="Service description",
            category_id=uuid4(),  # Non-existent category
            price=1000000.0,
            location_region="Tashkent"
        )
        
        with pytest.raises(NotFoundError, match="Service category not found"):
            await manager.create_merchant_service(sample_merchant_user.id, service_data)
    
    async def test_create_merchant_service_invalid_region(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_category: "ServiceCategory",
        sample_tariff: "TariffPlan"
    ):
        """Test creating service with invalid region raises ValidationError."""
        manager = MerchantManager(db_session)
        
        # Create active subscription
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        service_data = ServiceCreateRequest(
            name="New Service",
            description="Service description",
            category_id=sample_category.id,
            price=1000000.0,
            location_region="InvalidRegion"
        )
        
        with pytest.raises(ValidationError, match="Invalid region"):
            await manager.create_merchant_service(sample_merchant_user.id, service_data)
    
    async def test_get_merchant_analytics(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_service: "Service"
    ):
        """Test getting merchant analytics."""
        manager = MerchantManager(db_session)
        
        analytics = await manager.get_merchant_analytics(sample_merchant_user.id)
        
        assert analytics.total_services >= 1
        assert len(analytics.services) >= 1
        assert analytics.total_views >= 0
        assert analytics.total_likes >= 0
    
    async def test_get_featured_services_tracking(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_service: "Service",
        sample_tariff: "TariffPlan"
    ):
        """Test getting featured services tracking."""
        manager = MerchantManager(db_session)
        
        # Create active subscription
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        
        # Create featured service
        from app.models import FeaturedService, FeatureType
        featured = FeaturedService(
            service_id=sample_service.id,
            merchant_id=sample_merchant.id,
            start_date=datetime.now() - timedelta(days=1),
            end_date=datetime.now() + timedelta(days=7),
            days_duration=7,
            feature_type=FeatureType.MONTHLY_ALLOCATION,
            is_active=True
        )
        db_session.add(featured)
        await db_session.commit()
        
        response = await manager.get_featured_services_tracking(sample_merchant_user.id)
        
        assert response.total >= 1
        assert response.active_count >= 1
        assert response.remaining_free_slots >= 0
    
    async def test_create_monthly_featured_service(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_service: "Service",
        sample_tariff: "TariffPlan"
    ):
        """Test creating monthly featured service."""
        manager = MerchantManager(db_session)
        
        # Create subscription with monthly allocations
        sample_tariff.monthly_featured_cards = 5
        db_session.add(sample_tariff)
        await db_session.commit()
        
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        featured = await manager.create_monthly_featured_service(
            sample_merchant_user.id,
            sample_service.id
        )
        
        assert featured.service_id == sample_service.id
        assert featured.feature_type == "monthly_allocation"
        assert featured.is_active is True
    
    async def test_create_monthly_featured_service_limit_exceeded(
        self,
        db_session,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_service: "Service",
        sample_tariff: "TariffPlan"
    ):
        """Test creating monthly featured service when limit exceeded."""
        manager = MerchantManager(db_session)
        
        # Create subscription with 1 monthly allocation
        sample_tariff.monthly_featured_cards = 1
        db_session.add(sample_tariff)
        await db_session.commit()
        
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        
        # Create one monthly featured service (uses allocation)
        from app.models import FeaturedService, FeatureType
        from datetime import datetime
        current_month = datetime.now()
        featured1 = FeaturedService(
            service_id=sample_service.id,
            merchant_id=sample_merchant.id,
            start_date=datetime(current_month.year, current_month.month, 1),
            end_date=datetime(current_month.year, current_month.month, 1) + timedelta(days=30),
            days_duration=30,
            feature_type=FeatureType.MONTHLY_ALLOCATION,
            is_active=True
        )
        db_session.add(featured1)
        await db_session.commit()
        
        # Try to create another
        with pytest.raises(ForbiddenError, match="Monthly featured allocation limit exceeded"):
            await manager.create_monthly_featured_service(
                sample_merchant_user.id,
                sample_service.id
            )

