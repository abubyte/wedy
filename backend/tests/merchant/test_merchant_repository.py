"""
Tests for MerchantRepository.
"""
import pytest
from uuid import uuid4
from datetime import datetime, date, timedelta

from app.repositories.merchant_repository import MerchantRepository
from app.models import (
    Merchant, User, UserType, MerchantContact, ContactType,
    Service, ServiceCategory, MerchantSubscription, TariffPlan,
    SubscriptionStatus, FeaturedService, FeatureType, Image, ImageType
)


@pytest.mark.asyncio
class TestMerchantRepository:
    """Test MerchantRepository methods."""
    
    async def test_get_merchant_by_user_id(
        self,
        db_session,
        sample_merchant: Merchant,
        sample_merchant_user: User
    ):
        """Test getting merchant by user ID."""
        repo = MerchantRepository(db_session)
        
        merchant = await repo.get_merchant_by_user_id(sample_merchant_user.id)
        
        assert merchant is not None
        assert merchant.id == sample_merchant.id
        assert merchant.user_id == sample_merchant_user.id
        assert merchant.business_name == sample_merchant.business_name
        
        # Test non-existent user
        non_existent = await repo.get_merchant_by_user_id(uuid4())
        assert non_existent is None
    
    async def test_get_merchant_with_user(
        self,
        db_session,
        sample_merchant: Merchant,
        sample_merchant_user: User
    ):
        """Test getting merchant with associated user."""
        repo = MerchantRepository(db_session)
        
        result = await repo.get_merchant_with_user(sample_merchant.id)
        
        assert result is not None
        merchant, user = result
        assert merchant.id == sample_merchant.id
        assert user.id == sample_merchant_user.id
        assert user.phone_number == sample_merchant_user.phone_number
        
        # Test non-existent merchant
        non_existent = await repo.get_merchant_with_user(uuid4())
        assert non_existent is None
    
    async def test_get_active_subscription(
        self,
        db_session,
        sample_merchant: Merchant,
        sample_tariff: TariffPlan
    ):
        """Test getting active subscription."""
        repo = MerchantRepository(db_session)
        
        # No subscription initially
        subscription_data = await repo.get_active_subscription(sample_merchant.id)
        assert subscription_data is None
        
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
        
        subscription_data = await repo.get_active_subscription(sample_merchant.id)
        assert subscription_data is not None
        sub, tariff = subscription_data
        assert sub.merchant_id == sample_merchant.id
        assert tariff.id == sample_tariff.id
        assert sub.status == SubscriptionStatus.ACTIVE
    
    async def test_get_active_subscription_expired(
        self,
        db_session,
        sample_merchant: Merchant,
        sample_tariff: TariffPlan
    ):
        """Test that expired subscriptions are not returned."""
        repo = MerchantRepository(db_session)
        
        # Create expired subscription
        yesterday = date.today() - timedelta(days=1)
        expired_subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=yesterday - timedelta(days=30),
            end_date=yesterday,
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(expired_subscription)
        await db_session.commit()
        
        subscription_data = await repo.get_active_subscription(sample_merchant.id)
        assert subscription_data is None  # Expired subscriptions are not returned
    
    async def test_get_merchant_contacts(
        self,
        db_session,
        sample_merchant: Merchant
    ):
        """Test getting merchant contacts."""
        repo = MerchantRepository(db_session)
        
        # No contacts initially
        contacts = await repo.get_merchant_contacts(sample_merchant.id)
        assert len(contacts) == 0
        
        # Create contacts
        contact1 = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998901234567",
            display_order=1,
            is_active=True
        )
        contact2 = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.SOCIAL_MEDIA,
            contact_value="https://instagram.com/test",
            platform_name="Instagram",
            display_order=2,
            is_active=True
        )
        contact3 = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998907654321",
            display_order=3,
            is_active=False  # Inactive
        )
        db_session.add_all([contact1, contact2, contact3])
        await db_session.commit()
        
        contacts = await repo.get_merchant_contacts(sample_merchant.id)
        assert len(contacts) == 2  # Only active contacts
        assert all(contact.is_active for contact in contacts)
        assert contacts[0].display_order == 1
        assert contacts[1].display_order == 2
    
    async def test_count_contacts_by_type(
        self,
        db_session,
        sample_merchant: Merchant
    ):
        """Test counting contacts by type."""
        repo = MerchantRepository(db_session)
        
        # Create contacts of different types
        phone1 = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998901234567",
            is_active=True
        )
        phone2 = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998907654321",
            is_active=True
        )
        email = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.SOCIAL_MEDIA,
            contact_value="https://instagram.com/test",
            platform_name="Instagram",
            is_active=True
        )
        phone_inactive = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998909999999",
            is_active=False
        )
        db_session.add_all([phone1, phone2, email, phone_inactive])
        await db_session.commit()
        
        phone_count = await repo.count_contacts_by_type(sample_merchant.id, ContactType.PHONE)
        assert phone_count == 2  # Only active phones
        
        social_count = await repo.count_contacts_by_type(sample_merchant.id, ContactType.SOCIAL_MEDIA)
        assert social_count == 1
    
    async def test_get_merchant_services(
        self,
        db_session,
        sample_merchant: Merchant,
        sample_category: ServiceCategory
    ):
        """Test getting merchant services."""
        repo = MerchantRepository(db_session)
        
        # Create services
        service1 = Service(
            merchant_id=sample_merchant.id,
            category_id=sample_category.id,
            name="Service 1",
            description="First service",
            price=1000000.0,
            location_region="Tashkent",
            is_active=True
        )
        service2 = Service(
            merchant_id=sample_merchant.id,
            category_id=sample_category.id,
            name="Service 2",
            description="Second service",
            price=2000000.0,
            location_region="Tashkent",
            is_active=True
        )
        db_session.add_all([service1, service2])
        await db_session.commit()
        
        services = await repo.get_merchant_services(sample_merchant.id)
        assert len(services) >= 2
        
        # Check that services are returned with categories
        service_ids = [s[0].id for s in services]
        assert service1.id in service_ids
        assert service2.id in service_ids
        
        # Verify category is included
        for service, category in services:
            assert category.id == sample_category.id
    
    async def test_count_merchant_services(
        self,
        db_session,
        sample_merchant: Merchant,
        sample_category: ServiceCategory
    ):
        """Test counting merchant services."""
        repo = MerchantRepository(db_session)
        
        # Count should include existing sample_service
        initial_count = await repo.count_merchant_services(sample_merchant.id)
        # Count may be 0 if no services exist yet
        initial_count = await repo.count_merchant_services(sample_merchant.id)
        
        # Create more services
        service1 = Service(
            merchant_id=sample_merchant.id,
            category_id=sample_category.id,
            name="Active Service",
            description="Active service",
            price=1000000.0,
            location_region="Tashkent",
            is_active=True
        )
        service2 = Service(
            merchant_id=sample_merchant.id,
            category_id=sample_category.id,
            name="Inactive Service",
            description="Inactive service",
            price=2000000.0,
            location_region="Tashkent",
            is_active=False
        )
        db_session.add_all([service1, service2])
        await db_session.commit()
        
        count = await repo.count_merchant_services(sample_merchant.id)
        assert count == initial_count + 1  # Only active services are counted
    
    async def test_get_merchant_gallery_images(
        self,
        db_session,
        sample_merchant: Merchant
    ):
        """Test getting merchant gallery images."""
        repo = MerchantRepository(db_session)
        
        # No images initially
        images = await repo.get_merchant_gallery_images(sample_merchant.id)
        assert len(images) == 0
        
        # Create gallery images
        image1 = Image(
            related_id=sample_merchant.id,
            image_type=ImageType.MERCHANT_GALLERY,
            s3_url="https://example.com/gallery1.jpg",
            file_name="gallery1.jpg",
            display_order=1,
            is_active=True
        )
        image2 = Image(
            related_id=sample_merchant.id,
            image_type=ImageType.MERCHANT_GALLERY,
            s3_url="https://example.com/gallery2.jpg",
            file_name="gallery2.jpg",
            display_order=2,
            is_active=True
        )
        image3 = Image(
            related_id=sample_merchant.id,
            image_type=ImageType.MERCHANT_GALLERY,
            s3_url="https://example.com/gallery3.jpg",
            file_name="gallery3.jpg",
            display_order=3,
            is_active=False  # Inactive
        )
        db_session.add_all([image1, image2, image3])
        await db_session.commit()
        
        images = await repo.get_merchant_gallery_images(sample_merchant.id)
        assert len(images) == 2  # Only active images
        assert all(img.is_active for img in images)
        assert images[0].display_order == 1
        assert images[1].display_order == 2
    
    async def test_count_gallery_images(
        self,
        db_session,
        sample_merchant: Merchant
    ):
        """Test counting gallery images."""
        repo = MerchantRepository(db_session)
        
        # Create gallery images
        image1 = Image(
            related_id=sample_merchant.id,
            image_type=ImageType.MERCHANT_GALLERY,
            s3_url="https://example.com/gallery1.jpg",
            file_name="gallery1.jpg",
            is_active=True
        )
        image2 = Image(
            related_id=sample_merchant.id,
            image_type=ImageType.MERCHANT_GALLERY,
            s3_url="https://example.com/gallery2.jpg",
            file_name="gallery2.jpg",
            is_active=True
        )
        image3 = Image(
            related_id=sample_merchant.id,
            image_type=ImageType.MERCHANT_GALLERY,
            s3_url="https://example.com/gallery3.jpg",
            file_name="gallery3.jpg",
            is_active=False
        )
        db_session.add_all([image1, image2, image3])
        await db_session.commit()
        
        count = await repo.count_gallery_images(sample_merchant.id)
        assert count == 2  # Only active images
    
    async def test_count_service_images(
        self,
        db_session,
        sample_service: Service
    ):
        """Test counting service images."""
        repo = MerchantRepository(db_session)
        
        # Create service images
        image1 = Image(
            related_id=sample_service.id,
            image_type=ImageType.SERVICE_IMAGE,
            s3_url="https://example.com/service1.jpg",
            file_name="service1.jpg",
            is_active=True
        )
        image2 = Image(
            related_id=sample_service.id,
            image_type=ImageType.SERVICE_IMAGE,
            s3_url="https://example.com/service2.jpg",
            file_name="service2.jpg",
            is_active=True
        )
        image3 = Image(
            related_id=sample_service.id,
            image_type=ImageType.SERVICE_IMAGE,
            s3_url="https://example.com/service3.jpg",
            file_name="service3.jpg",
            is_active=False
        )
        db_session.add_all([image1, image2, image3])
        await db_session.commit()
        
        count = await repo.count_service_images(sample_service.id)
        assert count == 2  # Only active images
    
    async def test_create_contact(
        self,
        db_session,
        sample_merchant: Merchant
    ):
        """Test creating merchant contact."""
        repo = MerchantRepository(db_session)
        
        contact = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998901234567",
            display_order=1,
            is_active=True
        )
        
        created = await repo.create_contact(contact)
        
        assert created.id is not None
        assert created.merchant_id == sample_merchant.id
        assert created.contact_value == "+998901234567"
    
    async def test_update_contact(
        self,
        db_session,
        sample_merchant: Merchant
    ):
        """Test updating merchant contact."""
        repo = MerchantRepository(db_session)
        
        contact = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998901234567",
            is_active=True
        )
        db_session.add(contact)
        await db_session.commit()
        
        contact.contact_value = "+998907654321"
        updated = await repo.update_contact(contact)
        
        assert updated.contact_value == "+998907654321"
    
    async def test_get_contact_by_id(
        self,
        db_session,
        sample_merchant: Merchant
    ):
        """Test getting contact by ID."""
        repo = MerchantRepository(db_session)
        
        contact = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998901234567",
            is_active=True
        )
        db_session.add(contact)
        await db_session.commit()
        await db_session.refresh(contact)
        
        found = await repo.get_contact_by_id(contact.id, sample_merchant.id)
        assert found is not None
        assert found.id == contact.id
        assert found.merchant_id == sample_merchant.id
        
        # Test with wrong merchant_id
        other_merchant = Merchant(
            user_id=uuid4(),
            business_name="Other Business",
            location_region="Tashkent"
        )
        db_session.add(other_merchant)
        await db_session.commit()
        
        not_found = await repo.get_contact_by_id(contact.id, other_merchant.id)
        assert not_found is None
    
    async def test_delete_contact(
        self,
        db_session,
        sample_merchant: Merchant
    ):
        """Test deleting (deactivating) merchant contact."""
        repo = MerchantRepository(db_session)
        
        contact = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998901234567",
            is_active=True
        )
        db_session.add(contact)
        await db_session.commit()
        await db_session.refresh(contact)
        
        deleted = await repo.delete_contact(contact.id)
        assert deleted is True
        
        # Verify contact is deactivated
        contacts = await repo.get_merchant_contacts(sample_merchant.id)
        assert contact.id not in [c.id for c in contacts]
        
        # Test deleting non-existent contact
        result = await repo.delete_contact(uuid4())
        assert result is False
    
    async def test_create_gallery_image(
        self,
        db_session,
        sample_merchant: Merchant
    ):
        """Test creating gallery image."""
        repo = MerchantRepository(db_session)
        
        image = Image(
            related_id=sample_merchant.id,
            image_type=ImageType.MERCHANT_GALLERY,
            s3_url="https://example.com/gallery.jpg",
            file_name="gallery.jpg",
            display_order=1,
            is_active=True
        )
        
        created = await repo.create_gallery_image(image)
        
        assert created.id is not None
        assert created.related_id == sample_merchant.id
        assert created.image_type == ImageType.MERCHANT_GALLERY
    
    async def test_delete_gallery_image(
        self,
        db_session,
        sample_merchant: Merchant
    ):
        """Test deleting gallery image."""
        repo = MerchantRepository(db_session)
        
        image = Image(
            related_id=sample_merchant.id,
            image_type=ImageType.MERCHANT_GALLERY,
            s3_url="https://example.com/gallery.jpg",
            file_name="gallery.jpg",
            is_active=True
        )
        db_session.add(image)
        await db_session.commit()
        await db_session.refresh(image)
        
        deleted = await repo.delete_gallery_image(image.id, sample_merchant.id)
        assert deleted is True
        
        # Verify image is deactivated
        images = await repo.get_merchant_gallery_images(sample_merchant.id)
        assert image.id not in [img.id for img in images]
        
        # Test with wrong merchant_id
        other_merchant = Merchant(
            user_id=uuid4(),
            business_name="Other Business",
            location_region="Tashkent"
        )
        db_session.add(other_merchant)
        await db_session.commit()
        
        result = await repo.delete_gallery_image(image.id, other_merchant.id)
        assert result is False
    
    async def test_update_cover_image(
        self,
        db_session,
        sample_merchant: Merchant
    ):
        """Test updating cover image."""
        repo = MerchantRepository(db_session)
        
        s3_url = "https://example.com/cover.jpg"
        updated = await repo.update_cover_image(sample_merchant.id, s3_url)
        
        assert updated is True
        
        # Verify cover image was updated
        await db_session.refresh(sample_merchant)
        assert sample_merchant.cover_image_url == s3_url
        
        # Test with non-existent merchant
        result = await repo.update_cover_image(uuid4(), s3_url)
        assert result is False
    
    async def test_delete_cover_image(
        self,
        db_session,
        sample_merchant: Merchant
    ):
        """Test deleting cover image."""
        repo = MerchantRepository(db_session)
        
        # Set cover image first
        sample_merchant.cover_image_url = "https://example.com/cover.jpg"
        db_session.add(sample_merchant)
        await db_session.commit()
        
        deleted = await repo.delete_cover_image(sample_merchant.id)
        assert deleted is True
        
        # Verify cover image was deleted
        await db_session.refresh(sample_merchant)
        assert sample_merchant.cover_image_url is None
        
        # Test with non-existent merchant
        result = await repo.delete_cover_image(uuid4())
        assert result is False
    
    async def test_get_featured_services(
        self,
        db_session,
        sample_merchant: Merchant,
        sample_service: Service
    ):
        """Test getting featured services for merchant."""
        repo = MerchantRepository(db_session)
        
        # Create featured service
        now = datetime.now()
        featured = FeaturedService(
            service_id=sample_service.id,
            merchant_id=sample_merchant.id,
            start_date=now - timedelta(days=1),
            end_date=now + timedelta(days=7),
            days_duration=7,
            feature_type=FeatureType.MONTHLY_ALLOCATION,
            is_active=True
        )
        db_session.add(featured)
        await db_session.commit()
        
        featured_services = await repo.get_featured_services(sample_merchant.id)
        assert len(featured_services) >= 1
        
        # Verify service is included
        featured_ids = [fs[0].id for fs in featured_services]
        assert featured.id in featured_ids
        
        # Verify service data is included
        for fs, service in featured_services:
            assert service.id == sample_service.id
    
    async def test_count_active_featured_services(
        self,
        db_session,
        sample_merchant: Merchant,
        sample_service: Service
    ):
        """Test counting active featured services."""
        repo = MerchantRepository(db_session)
        
        now = datetime.now()
        
        # Create active featured service
        active_featured = FeaturedService(
            service_id=sample_service.id,
            merchant_id=sample_merchant.id,
            start_date=now - timedelta(days=1),
            end_date=now + timedelta(days=7),
            days_duration=7,
            feature_type=FeatureType.MONTHLY_ALLOCATION,
            is_active=True
        )
        
        # Create inactive featured service
        inactive_featured = FeaturedService(
            service_id=sample_service.id,
            merchant_id=sample_merchant.id,
            start_date=now - timedelta(days=10),
            end_date=now - timedelta(days=1),
            days_duration=7,
            feature_type=FeatureType.MONTHLY_ALLOCATION,
            is_active=True
        )
        
        db_session.add_all([active_featured, inactive_featured])
        await db_session.commit()
        
        count = await repo.count_active_featured_services(sample_merchant.id)
        assert count == 1  # Only currently active (within date range)
    
    async def test_count_monthly_featured_allocations_used(
        self,
        db_session,
        sample_merchant: Merchant,
        sample_service: Service
    ):
        """Test counting monthly featured allocations used."""
        repo = MerchantRepository(db_session)
        
        now = datetime.now()
        current_month = now.month
        current_year = now.year
        
        # Create featured service in current month
        featured = FeaturedService(
            service_id=sample_service.id,
            merchant_id=sample_merchant.id,
            start_date=datetime(current_year, current_month, 15),
            end_date=datetime(current_year, current_month, 22),
            days_duration=7,
            feature_type=FeatureType.MONTHLY_ALLOCATION,
            is_active=True
        )
        db_session.add(featured)
        await db_session.commit()
        
        count = await repo.count_monthly_featured_allocations_used(
            sample_merchant.id, current_year, current_month
        )
        assert count == 1
        
        # Count for different month should be 0
        count_other = await repo.count_monthly_featured_allocations_used(
            sample_merchant.id, current_year, current_month - 1 if current_month > 1 else 12
        )
        assert count_other == 0
    
    async def test_create_featured_service(
        self,
        db_session,
        sample_merchant: Merchant,
        sample_service: Service
    ):
        """Test creating featured service."""
        repo = MerchantRepository(db_session)
        
        now = datetime.now()
        featured = FeaturedService(
            service_id=sample_service.id,
            merchant_id=sample_merchant.id,
            start_date=now,
            end_date=now + timedelta(days=7),
            days_duration=7,
            feature_type=FeatureType.MONTHLY_ALLOCATION,
            is_active=True
        )
        
        created = await repo.create_featured_service(featured)
        
        assert created.id is not None
        assert created.service_id == sample_service.id
        assert created.merchant_id == sample_merchant.id

