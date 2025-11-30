"""
Tests for TariffService.
"""
import pytest
from uuid import uuid4

from app.services.tariff_service import TariffService
from app.core.exceptions import NotFoundError, ConflictError, ValidationError
from app.schemas.payment_schema import TariffCreateRequest, TariffUpdateRequest
from app.schemas.common_schema import PaginationParams


@pytest.mark.asyncio
class TestTariffService:
    """Test TariffService methods."""
    
    async def test_get_tariff(
        self,
        tariff_service: TariffService,
        sample_tariff,
        sample_merchant,
        db_session
    ):
        """Test getting tariff plan by ID with subscription count."""
        from app.models.merchant_subscription_model import MerchantSubscription
        from datetime import date, timedelta
        
        # Create a subscription for the tariff
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status="ACTIVE"
        )
        db_session.add(subscription)
        await db_session.commit()
        
        tariff_detail = await tariff_service.get_tariff(sample_tariff.id)
        
        assert tariff_detail.id == sample_tariff.id
        assert tariff_detail.name == sample_tariff.name
        assert tariff_detail.price_per_month == 100000.0
        assert tariff_detail.max_services == 5
        assert tariff_detail.is_active is True
        assert tariff_detail.subscription_count >= 1
    
    async def test_get_tariff_not_found(
        self,
        tariff_service: TariffService
    ):
        """Test getting non-existent tariff raises NotFoundError."""
        with pytest.raises(NotFoundError, match="Tariff plan with ID .* not found"):
            await tariff_service.get_tariff(uuid4())
    
    async def test_list_tariffs(
        self,
        tariff_service: TariffService,
        sample_tariff,
        db_session
    ):
        """Test listing tariff plans."""
        from app.models import TariffPlan
        
        # Create additional tariffs
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
        db_session.add(tariff2)
        db_session.add(tariff3)
        await db_session.commit()
        
        # List active tariffs only
        response = await tariff_service.list_tariffs(
            include_inactive=False,
            pagination=PaginationParams(page=1, limit=100)
        )
        
        assert response.total >= 2
        assert len(response.tariffs) >= 2
        assert all(tariff.is_active for tariff in response.tariffs)
        
        # List all tariffs including inactive
        response_all = await tariff_service.list_tariffs(
            include_inactive=True,
            pagination=PaginationParams(page=1, limit=100)
        )
        
        assert response_all.total >= 3
        assert len(response_all.tariffs) >= 3
        assert any(not tariff.is_active for tariff in response_all.tariffs)
    
    async def test_list_tariffs_with_pagination(
        self,
        tariff_service: TariffService,
        sample_tariff,
        db_session
    ):
        """Test listing tariff plans with pagination."""
        from app.models import TariffPlan
        
        # Create multiple tariffs
        for i in range(5):
            tariff = TariffPlan(
                name=f"Tariff_{str(uuid4())[:8]}",
                price_per_month=100000.0 + i * 10000,
                max_services=5 + i,
                max_images_per_service=10,
                max_phone_numbers=2,
                max_gallery_images=20,
                max_social_accounts=3,
                is_active=True
            )
            db_session.add(tariff)
        await db_session.commit()
        
        # Test pagination
        pagination = PaginationParams(page=1, limit=2)
        response = await tariff_service.list_tariffs(
            include_inactive=False,
            pagination=pagination
        )
        
        assert response.page == 1
        assert response.limit == 2
        assert len(response.tariffs) == 2
        assert response.total >= 6  # sample_tariff + 5 created
        assert response.total_pages > 1
        assert response.has_more is True
    
    async def test_list_tariffs_empty(
        self,
        tariff_service: TariffService,
        db_session
    ):
        """Test listing tariffs when none are active."""
        from app.models import TariffPlan
        from sqlmodel import select
        
        # Get all tariffs and mark them inactive
        stmt = select(TariffPlan)
        result = await db_session.execute(stmt)
        all_tariffs = result.scalars().all()
        
        for tariff in all_tariffs:
            tariff.is_active = False
            db_session.add(tariff)
        await db_session.commit()
        
        # List active tariffs
        response = await tariff_service.list_tariffs(
            include_inactive=False,
            pagination=PaginationParams(page=1, limit=20)
        )
        
        assert response.total == 0
        assert len(response.tariffs) == 0
    
    async def test_list_tariffs_subscription_counts(
        self,
        tariff_service: TariffService,
        sample_tariff,
        sample_merchant,
        db_session
    ):
        """Test that subscription counts are correctly calculated."""
        from app.models import TariffPlan
        from app.models.merchant_subscription_model import MerchantSubscription
        from datetime import date, timedelta
        
        # Create another tariff with subscriptions
        tariff2 = TariffPlan(
            name=f"TariffWithSubs_{str(uuid4())[:8]}",
            price_per_month=150000.0,
            max_services=7,
            max_images_per_service=15,
            max_phone_numbers=2,
            max_gallery_images=30,
            max_social_accounts=3,
            is_active=True
        )
        db_session.add(tariff2)
        await db_session.commit()
        
        # Add subscriptions to tariff2
        subscription1 = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=tariff2.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status="ACTIVE"
        )
        db_session.add(subscription1)
        await db_session.commit()
        
        response = await tariff_service.list_tariffs(
            include_inactive=False,
            pagination=PaginationParams(page=1, limit=100)
        )
        
        # Find our tariffs in the response
        tariff1_detail = next((t for t in response.tariffs if t.id == sample_tariff.id), None)
        tariff2_detail = next((t for t in response.tariffs if t.id == tariff2.id), None)
        
        assert tariff1_detail is not None
        assert tariff2_detail is not None
        assert tariff2_detail.subscription_count >= 1
    
    async def test_create_tariff(
        self,
        tariff_service: TariffService
    ):
        """Test creating a new tariff plan."""
        request = TariffCreateRequest(
            name=f"NewTariff_{str(uuid4())[:8]}",
            price_per_month=125000.0,
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
        
        created = await tariff_service.create_tariff(request)
        
        assert created.id is not None
        assert created.name == request.name
        assert created.price_per_month == 125000.0
        assert created.max_services == 6
        assert created.allow_website is True
        assert created.is_active is True
        assert created.subscription_count == 0
    
    async def test_create_tariff_duplicate_name(
        self,
        tariff_service: TariffService,
        sample_tariff
    ):
        """Test creating tariff with duplicate name raises ConflictError."""
        request = TariffCreateRequest(
            name=sample_tariff.name,  # Use existing name
            price_per_month=100000.0,
            max_services=5,
            max_images_per_service=10,
            max_phone_numbers=2,
            max_gallery_images=20,
            max_social_accounts=3,
            is_active=True
        )
        
        with pytest.raises(ConflictError, match="already exists"):
            await tariff_service.create_tariff(request)
    
    async def test_create_tariff_with_whitespace(
        self,
        tariff_service: TariffService
    ):
        """Test that whitespace in name is trimmed."""
        unique_name = f"  TariffWithSpaces_{str(uuid4())[:8]}  "
        request = TariffCreateRequest(
            name=unique_name,
            price_per_month=100000.0,
            max_services=5,
            max_images_per_service=10,
            max_phone_numbers=2,
            max_gallery_images=20,
            max_social_accounts=3,
            is_active=True
        )
        
        created = await tariff_service.create_tariff(request)
        
        assert created.name == unique_name.strip()  # Trimmed
    
    async def test_update_tariff(
        self,
        tariff_service: TariffService,
        sample_tariff
    ):
        """Test updating a tariff plan."""
        request = TariffUpdateRequest(
            name=f"UpdatedTariff_{str(uuid4())[:8]}",
            price_per_month=150000.0,
            max_services=8,
            allow_website=True,
            monthly_featured_cards=3,
            is_active=False
        )
        
        updated = await tariff_service.update_tariff(sample_tariff.id, request)
        
        assert updated.id == sample_tariff.id
        assert updated.name == request.name
        assert updated.price_per_month == 150000.0
        assert updated.max_services == 8
        assert updated.allow_website is True
        assert updated.monthly_featured_cards == 3
        assert updated.is_active is False
    
    async def test_update_tariff_not_found(
        self,
        tariff_service: TariffService
    ):
        """Test updating non-existent tariff raises NotFoundError."""
        request = TariffUpdateRequest(
            name="UpdatedName",
            price_per_month=150000.0
        )
        
        with pytest.raises(NotFoundError, match="Tariff plan with ID .* not found"):
            await tariff_service.update_tariff(uuid4(), request)
    
    async def test_update_tariff_name_conflict(
        self,
        tariff_service: TariffService,
        sample_tariff,
        db_session
    ):
        """Test updating tariff with conflicting name raises ConflictError."""
        from app.models import TariffPlan
        
        # Create another tariff
        tariff2 = TariffPlan(
            name=f"Tariff2_{str(uuid4())[:8]}",
            price_per_month=200000.0,
            max_services=10,
            max_images_per_service=20,
            max_phone_numbers=3,
            max_gallery_images=50,
            max_social_accounts=5,
            is_active=True
        )
        db_session.add(tariff2)
        await db_session.commit()
        
        # Try to update sample_tariff with tariff2's name
        request = TariffUpdateRequest(
            name=tariff2.name
        )
        
        with pytest.raises(ConflictError, match="already exists"):
            await tariff_service.update_tariff(sample_tariff.id, request)
    
    async def test_update_tariff_partial(
        self,
        tariff_service: TariffService,
        sample_tariff
    ):
        """Test updating only specific fields."""
        original_name = sample_tariff.name
        
        # Update only price
        request = TariffUpdateRequest(
            price_per_month=150000.0
        )
        
        updated = await tariff_service.update_tariff(sample_tariff.id, request)
        
        assert updated.name == original_name  # Unchanged
        assert updated.price_per_month == 150000.0
        
        # Update only max_services
        request2 = TariffUpdateRequest(
            max_services=10
        )
        
        updated2 = await tariff_service.update_tariff(sample_tariff.id, request2)
        
        assert updated2.max_services == 10
        assert updated2.price_per_month == 150000.0  # Previous update preserved
    
    async def test_update_tariff_same_name(
        self,
        tariff_service: TariffService,
        sample_tariff
    ):
        """Test updating tariff with same name (should succeed)."""
        request = TariffUpdateRequest(
            name=sample_tariff.name,  # Same name
            price_per_month=150000.0
        )
        
        updated = await tariff_service.update_tariff(sample_tariff.id, request)
        
        assert updated.name == sample_tariff.name
        assert updated.price_per_month == 150000.0
    
    async def test_delete_tariff(
        self,
        tariff_service: TariffService,
        db_session
    ):
        """Test deleting a tariff plan without subscriptions (hard delete)."""
        from app.models import TariffPlan
        
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
        
        # Delete the tariff
        result = await tariff_service.delete_tariff(tariff_id)
        
        assert result is True
        
        # Verify it's deleted
        with pytest.raises(NotFoundError):
            await tariff_service.get_tariff(tariff_id)
    
    async def test_delete_tariff_with_subscriptions(
        self,
        tariff_service: TariffService,
        sample_tariff,
        sample_merchant,
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
            status="ACTIVE"
        )
        db_session.add(subscription)
        await db_session.commit()
        
        # Delete the tariff (should soft delete)
        result = await tariff_service.delete_tariff(sample_tariff.id)
        
        assert result is True
        
        # Verify tariff is soft deleted (still exists but inactive)
        deleted_tariff = await tariff_service.get_tariff(sample_tariff.id)
        assert deleted_tariff.is_active is False
    
    async def test_delete_tariff_not_found(
        self,
        tariff_service: TariffService
    ):
        """Test deleting non-existent tariff raises NotFoundError."""
        with pytest.raises(NotFoundError, match="Tariff plan with ID .* not found"):
            await tariff_service.delete_tariff(uuid4())
    
    async def test_delete_tariff_only_active_subscriptions_counted(
        self,
        tariff_service: TariffService,
        sample_tariff,
        sample_merchant,
        db_session
    ):
        """Test that only active subscriptions prevent soft delete."""
        from app.models.merchant_subscription_model import MerchantSubscription
        from datetime import date, timedelta
        
        # Create an active subscription
        active_subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status="ACTIVE"
        )
        db_session.add(active_subscription)
        await db_session.commit()
        
        # Delete should soft delete since there's an active subscription
        result = await tariff_service.delete_tariff(sample_tariff.id)
        
        assert result is True
        
        # Verify tariff is soft deleted (active subscriptions prevent hard delete)
        deleted_tariff = await tariff_service.get_tariff(sample_tariff.id)
        assert deleted_tariff.is_active is False

