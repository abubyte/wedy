"""
Tests for tariff-related methods in PaymentRepository.
"""
import pytest
from uuid import uuid4

from app.repositories.payment_repository import PaymentRepository
from app.models import TariffPlan, MerchantSubscription, SubscriptionStatus


@pytest.mark.asyncio
class TestTariffRepository:
    """Test PaymentRepository tariff-related methods."""
    
    async def test_get_tariff_plan_by_id(
        self,
        payment_repository: PaymentRepository,
        sample_tariff: TariffPlan
    ):
        """Test getting tariff plan by ID."""
        tariff = await payment_repository.get_tariff_plan_by_id(sample_tariff.id)
        
        assert tariff is not None
        assert tariff.id == sample_tariff.id
        assert tariff.name == sample_tariff.name
        assert tariff.price_per_month == 100000.0
        assert tariff.is_active is True
        
        # Test non-existent tariff
        non_existent = await payment_repository.get_tariff_plan_by_id(uuid4())
        assert non_existent is None
    
    async def test_get_tariff_plan_by_name(
        self,
        payment_repository: PaymentRepository,
        sample_tariff: TariffPlan
    ):
        """Test getting tariff plan by name."""
        tariff = await payment_repository.get_tariff_plan_by_name(sample_tariff.name)
        
        assert tariff is not None
        assert tariff.id == sample_tariff.id
        assert tariff.name == sample_tariff.name
        
        # Test non-existent tariff
        non_existent = await payment_repository.get_tariff_plan_by_name("NonExistentTariff")
        assert non_existent is None
    
    async def test_get_active_tariff_plans(
        self,
        payment_repository: PaymentRepository,
        sample_tariff: TariffPlan,
        db_session
    ):
        """Test getting all active tariff plans."""
        # Create another active tariff
        tariff2 = TariffPlan(
            name=f"PremiumPlan_{str(uuid4())[:8]}",
            price_per_month=200000.0,
            max_services=10,
            max_images_per_service=20,
            max_phone_numbers=3,
            max_gallery_images=50,
            max_social_accounts=5,
            allow_website=True,
            allow_cover_image=True,
            monthly_featured_cards=3,
            is_active=True
        )
        db_session.add(tariff2)
        
        # Create an inactive tariff
        tariff3 = TariffPlan(
            name=f"InactivePlan_{str(uuid4())[:8]}",
            price_per_month=50000.0,
            max_services=3,
            max_images_per_service=5,
            max_phone_numbers=1,
            max_gallery_images=10,
            max_social_accounts=2,
            is_active=False
        )
        db_session.add(tariff3)
        await db_session.commit()
        
        active_tariffs = await payment_repository.get_active_tariff_plans()
        
        assert len(active_tariffs) >= 2
        assert all(tariff.is_active for tariff in active_tariffs)
        assert any(tariff.id == sample_tariff.id for tariff in active_tariffs)
        assert any(tariff.id == tariff2.id for tariff in active_tariffs)
        assert not any(tariff.id == tariff3.id for tariff in active_tariffs)
    
    async def test_get_all_tariff_plans(
        self,
        payment_repository: PaymentRepository,
        sample_tariff: TariffPlan,
        db_session
    ):
        """Test getting all tariff plans with pagination."""
        # Create additional tariffs
        tariff2 = TariffPlan(
            name=f"Plan_{str(uuid4())[:8]}",
            price_per_month=150000.0,
            max_services=7,
            max_images_per_service=15,
            max_phone_numbers=2,
            max_gallery_images=30,
            max_social_accounts=3,
            is_active=True
        )
        tariff3 = TariffPlan(
            name=f"InactivePlan_{str(uuid4())[:8]}",
            price_per_month=75000.0,
            max_services=3,
            max_images_per_service=5,
            max_phone_numbers=1,
            max_gallery_images=10,
            max_social_accounts=2,
            is_active=False
        )
        db_session.add(tariff2)
        db_session.add(tariff3)
        await db_session.commit()
        
        # Test getting active tariffs only
        tariffs, total = await payment_repository.get_all_tariff_plans(
            include_inactive=False,
            offset=0,
            limit=100
        )
        
        assert total >= 2  # sample_tariff + tariff2
        assert len(tariffs) >= 2
        assert all(tariff.is_active for tariff in tariffs)
        
        # Test including inactive
        tariffs_all, total_all = await payment_repository.get_all_tariff_plans(
            include_inactive=True,
            offset=0,
            limit=100
        )
        
        assert total_all >= 3  # All tariffs
        assert len(tariffs_all) >= 3
        assert any(not tariff.is_active for tariff in tariffs_all)
        
        # Test pagination
        tariffs_page, total_page = await payment_repository.get_all_tariff_plans(
            include_inactive=False,
            offset=0,
            limit=1
        )
        
        assert len(tariffs_page) == 1
        assert total_page >= 2
    
    async def test_create_tariff_plan(
        self,
        payment_repository: PaymentRepository,
        db_session
    ):
        """Test creating a new tariff plan."""
        new_tariff = TariffPlan(
            name=f"NewTariff_{str(uuid4())[:8]}",
            price_per_month=120000.0,
            max_services=6,
            max_images_per_service=12,
            max_phone_numbers=2,
            max_gallery_images=25,
            max_social_accounts=3,
            allow_website=True,
            allow_cover_image=True,
            monthly_featured_cards=2,
            is_active=True
        )
        
        created = await payment_repository.create_tariff_plan(new_tariff)
        
        assert created.id is not None
        assert created.name == new_tariff.name
        assert created.price_per_month == 120000.0
        assert created.max_services == 6
        assert created.is_active is True
        
        # Verify it's in the database
        retrieved = await payment_repository.get_tariff_plan_by_id(created.id)
        assert retrieved is not None
        assert retrieved.name == created.name
    
    async def test_update_tariff_plan(
        self,
        payment_repository: PaymentRepository,
        sample_tariff: TariffPlan
    ):
        """Test updating a tariff plan."""
        # Update tariff fields
        sample_tariff.price_per_month = 150000.0
        sample_tariff.max_services = 8
        sample_tariff.allow_website = True
        sample_tariff.is_active = False
        
        updated = await payment_repository.update_tariff_plan(sample_tariff)
        
        assert updated.price_per_month == 150000.0
        assert updated.max_services == 8
        assert updated.allow_website is True
        assert updated.is_active is False
        
        # Verify changes persisted
        retrieved = await payment_repository.get_tariff_plan_by_id(sample_tariff.id)
        assert retrieved.price_per_month == 150000.0
        assert retrieved.max_services == 8
        assert retrieved.allow_website is True
        assert retrieved.is_active is False
    
    async def test_delete_tariff_plan_with_subscriptions_soft_delete(
        self,
        payment_repository: PaymentRepository,
        sample_tariff: TariffPlan,
        sample_merchant: "Merchant",
        db_session
    ):
        """Test deleting a tariff plan with active subscriptions (soft delete)."""
        from app.models.merchant_subscription_model import MerchantSubscription
        from datetime import date, timedelta
        
        # Create an active subscription
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        # Delete should soft delete (set is_active=False)
        result = await payment_repository.delete_tariff_plan(sample_tariff.id)
        
        assert result is True
        
        # Verify tariff is soft deleted
        deleted_tariff = await payment_repository.get_tariff_plan_by_id(sample_tariff.id)
        assert deleted_tariff is not None  # Still exists
        assert deleted_tariff.is_active is False  # But inactive
    
    async def test_delete_tariff_plan_without_subscriptions_hard_delete(
        self,
        payment_repository: PaymentRepository,
        db_session
    ):
        """Test deleting a tariff plan without active subscriptions (hard delete)."""
        # Create a tariff without subscriptions
        tariff = TariffPlan(
            name=f"TariffToDelete_{str(uuid4())[:8]}",
            price_per_month=50000.0,
            max_services=3,
            max_images_per_service=5,
            max_phone_numbers=1,
            max_gallery_images=10,
            max_social_accounts=2,
            is_active=True
        )
        db_session.add(tariff)
        await db_session.commit()
        tariff_id = tariff.id
        
        # Delete should hard delete
        result = await payment_repository.delete_tariff_plan(tariff_id)
        
        assert result is True
        
        # Verify tariff is hard deleted (doesn't exist)
        deleted_tariff = await payment_repository.get_tariff_plan_by_id(tariff_id)
        assert deleted_tariff is None
    
    async def test_delete_tariff_plan_not_found(
        self,
        payment_repository: PaymentRepository
    ):
        """Test deleting a non-existent tariff plan."""
        non_existent_id = uuid4()
        result = await payment_repository.delete_tariff_plan(non_existent_id)
        
        assert result is False
    
    async def test_get_tariff_plan_subscription_count(
        self,
        payment_repository: PaymentRepository,
        sample_tariff: TariffPlan,
        sample_merchant: "Merchant",
        db_session
    ):
        """Test getting subscription count for a tariff plan."""
        from app.models.merchant_subscription_model import MerchantSubscription
        from datetime import date, timedelta
        
        # Create active subscriptions
        subscription1 = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription1)
        
        # Create another merchant for second subscription
        from app.models import User, UserType
        import random
        
        random_suffix = ''.join([str(random.randint(0, 9)) for _ in range(7)])
        user2 = User(
            phone_number=f"93{random_suffix}",
            name="Second Merchant User",
            user_type=UserType.MERCHANT,
            is_active=True
        )
        db_session.add(user2)
        await db_session.commit()
        
        merchant2 = type(sample_merchant)(
            user_id=user2.id,
            business_name="Second Business",
            is_verified=True
        )
        db_session.add(merchant2)
        await db_session.commit()
        
        subscription2 = MerchantSubscription(
            merchant_id=merchant2.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription2)
        
        # Create an expired subscription (should not be counted)
        subscription3 = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today() - timedelta(days=60),
            end_date=date.today() - timedelta(days=30),
            status=SubscriptionStatus.EXPIRED
        )
        db_session.add(subscription3)
        await db_session.commit()
        
        count = await payment_repository.get_tariff_plan_subscription_count(sample_tariff.id)
        
        assert count >= 2  # subscription1 + subscription2 (subscription3 is expired)
        
        # Test tariff with no subscriptions
        empty_tariff = TariffPlan(
            name=f"EmptyTariff_{str(uuid4())[:8]}",
            price_per_month=75000.0,
            max_services=4,
            max_images_per_service=8,
            max_phone_numbers=1,
            max_gallery_images=15,
            max_social_accounts=2,
            is_active=True
        )
        db_session.add(empty_tariff)
        await db_session.commit()
        
        empty_count = await payment_repository.get_tariff_plan_subscription_count(empty_tariff.id)
        assert empty_count == 0

