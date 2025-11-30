"""
Tests for PaymentService.
"""
import pytest
from uuid import uuid4
from datetime import date, datetime, timedelta
from unittest.mock import AsyncMock, MagicMock

from app.services.payment_service import PaymentService, PaymentError
from app.schemas.payment_schema import TariffPaymentRequest, FeaturedServicePaymentRequest
from app.models import PaymentMethod, PaymentType, PaymentStatus, SubscriptionStatus


@pytest.fixture
async def payment_service(db_session):
    """Create PaymentService instance with mocked providers."""
    # Mock payment provider
    mock_provider = MagicMock()
    mock_provider.create_payment = MagicMock(return_value={
        'payment_url': 'https://payment.example.com/checkout',
        'transaction_id': f'trans_{uuid4()}'
    })
    
    payment_providers = {
        PaymentMethod.PAYME.value: mock_provider
    }
    
    return PaymentService(
        session=db_session,
        payment_providers=payment_providers,
        sms_service=None
    )


@pytest.mark.asyncio
class TestPaymentService:
    """Test PaymentService methods."""
    
    async def test_get_active_tariff_plans(
        self,
        payment_service: PaymentService,
        sample_tariff
    ):
        """Test getting active tariff plans."""
        plans = await payment_service.get_active_tariff_plans()
        
        assert len(plans) >= 1
        plan_ids = [p.id for p in plans]
        assert sample_tariff.id in plan_ids
    
    async def test_calculate_subscription_price_no_discount(self, payment_service: PaymentService):
        """Test subscription price calculation with no discount (1 month)."""
        price = payment_service._calculate_subscription_price(100000.0, 1)
        assert price == 100000.0  # No discount
    
    async def test_calculate_subscription_price_3_month_discount(self, payment_service: PaymentService):
        """Test subscription price calculation with 3-month discount (10%)."""
        price = payment_service._calculate_subscription_price(100000.0, 3)
        expected = 100000.0 * 3 * 0.9  # 10% discount
        assert price == expected
    
    async def test_calculate_subscription_price_6_month_discount(self, payment_service: PaymentService):
        """Test subscription price calculation with 6-month discount (20%)."""
        price = payment_service._calculate_subscription_price(100000.0, 6)
        expected = 100000.0 * 6 * 0.8  # 20% discount
        assert price == expected
    
    async def test_calculate_subscription_price_12_month_discount(self, payment_service: PaymentService):
        """Test subscription price calculation with 12-month discount (30%)."""
        price = payment_service._calculate_subscription_price(100000.0, 12)
        expected = 100000.0 * 12 * 0.7  # 30% discount
        assert price == expected
    
    async def test_calculate_featured_service_price_no_discount(self, payment_service: PaymentService):
        """Test featured service price calculation with no discount (1-7 days)."""
        price = payment_service._calculate_featured_service_price(1500.0, 7)
        assert price == 1500.0 * 7  # No discount
    
    async def test_calculate_featured_service_price_8_day_discount(self, payment_service: PaymentService):
        """Test featured service price calculation with 8-20 day discount (10%)."""
        price = payment_service._calculate_featured_service_price(1500.0, 8)
        expected = 1500.0 * 8 * 0.9  # 10% discount
        assert price == expected
    
    async def test_calculate_featured_service_price_21_day_discount(self, payment_service: PaymentService):
        """Test featured service price calculation with 21-90 day discount (20%)."""
        price = payment_service._calculate_featured_service_price(1500.0, 21)
        expected = 1500.0 * 21 * 0.8  # 20% discount
        assert price == expected
    
    async def test_calculate_featured_service_price_91_day_discount(self, payment_service: PaymentService):
        """Test featured service price calculation with 91-365 day discount (30%)."""
        price = payment_service._calculate_featured_service_price(1500.0, 91)
        expected = 1500.0 * 91 * 0.7  # 30% discount
        assert price == expected
    
    async def test_create_tariff_payment(
        self,
        payment_service: PaymentService,
        sample_merchant_user,
        sample_tariff
    ):
        """Test creating a tariff payment."""
        request = TariffPaymentRequest(
            tariff_plan_id=sample_tariff.id,
            payment_method=PaymentMethod.PAYME,
            duration_months=1
        )
        
        response = await payment_service.create_tariff_payment(
            sample_merchant_user.id,
            request
        )
        
        assert response.id is not None
        assert response.payment_type == PaymentType.TARIFF_SUBSCRIPTION.value
        assert response.payment_method == PaymentMethod.PAYME.value
        assert response.status == PaymentStatus.PENDING.value
        assert response.payment_url is not None
        assert response.transaction_id is not None
    
    async def test_create_tariff_payment_invalid_tariff(
        self,
        payment_service: PaymentService,
        sample_merchant_user
    ):
        """Test creating tariff payment with invalid tariff plan."""
        request = TariffPaymentRequest(
            tariff_plan_id=uuid4(),  # Non-existent
            payment_method=PaymentMethod.PAYME,
            duration_months=1
        )
        
        with pytest.raises(PaymentError, match="Tariff plan not found"):
            await payment_service.create_tariff_payment(sample_merchant_user.id, request)
    
    async def test_create_tariff_payment_provider_not_available(
        self,
        payment_service: PaymentService,
        sample_merchant_user,
        sample_tariff,
        db_session
    ):
        """Test creating tariff payment when provider is not available."""
        # Create service without PAYME provider
        service_no_provider = PaymentService(
            session=db_session,
            payment_providers={},  # Empty providers
            sms_service=None
        )
        
        request = TariffPaymentRequest(
            tariff_plan_id=sample_tariff.id,
            payment_method=PaymentMethod.PAYME,
            duration_months=1
        )
        
        with pytest.raises(PaymentError, match="not available"):
            await service_no_provider.create_tariff_payment(sample_merchant_user.id, request)
    
    async def test_create_featured_service_payment(
        self,
        payment_service: PaymentService,
        sample_merchant_user,
        sample_merchant,
        sample_service
    ):
        """Test creating a featured service payment."""
        request = FeaturedServicePaymentRequest(
            service_id=sample_service.id,
            payment_method=PaymentMethod.PAYME,
            duration_days=7
        )
        
        response = await payment_service.create_featured_service_payment(
            sample_merchant_user.id,
            request
        )
        
        assert response.id is not None
        assert response.payment_type == PaymentType.FEATURED_SERVICE.value
        assert response.payment_method == PaymentMethod.PAYME.value
        assert response.status == PaymentStatus.PENDING.value
        assert response.payment_url is not None
    
    async def test_create_featured_service_payment_not_merchant(
        self,
        payment_service: PaymentService,
        sample_client_user,
        sample_service
    ):
        """Test creating featured service payment by non-merchant."""
        request = FeaturedServicePaymentRequest(
            service_id=sample_service.id,
            payment_method=PaymentMethod.PAYME,
            duration_days=7
        )
        
        with pytest.raises(PaymentError, match="not a merchant"):
            await payment_service.create_featured_service_payment(
                sample_client_user.id,
                request
            )
    
    async def test_create_featured_service_payment_service_not_owned(
        self,
        payment_service: PaymentService,
        sample_merchant_user,
        sample_service,
        db_session
    ):
        """Test creating featured service payment for service not owned by merchant."""
        # Create another merchant
        from app.models import User, UserType, Merchant
        import random
        other_merchant_user = User(
            phone_number=f"90{random.randint(1000000, 9999999)}",
            name="Other Merchant",
            user_type=UserType.MERCHANT,
            is_active=True
        )
        db_session.add(other_merchant_user)
        await db_session.commit()
        
        other_merchant = Merchant(
            user_id=other_merchant_user.id,
            business_name="Other Business",
            location_region="Tashkent",
            is_active=True
        )
        db_session.add(other_merchant)
        await db_session.commit()
        
        request = FeaturedServicePaymentRequest(
            service_id=sample_service.id,
            payment_method=PaymentMethod.PAYME,
            duration_days=7
        )
        
        with pytest.raises(PaymentError, match="not owned by merchant"):
            await payment_service.create_featured_service_payment(
                other_merchant_user.id,
                request
            )
    
    async def test_get_merchant_subscription(
        self,
        payment_service: PaymentService,
        sample_merchant_user,
        sample_merchant,
        sample_tariff
    ):
        """Test getting merchant subscription."""
        # Create active subscription
        from app.models import MerchantSubscription
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        payment_service.session.add(subscription)
        await payment_service.session.commit()
        
        response = await payment_service.get_merchant_subscription(sample_merchant_user.id)
        
        assert response is not None
        assert response.tariff_plan.id == sample_tariff.id
        assert response.status == SubscriptionStatus.ACTIVE
    
    async def test_get_merchant_subscription_no_subscription(
        self,
        payment_service: PaymentService,
        sample_merchant_user
    ):
        """Test getting subscription when merchant has no subscription."""
        response = await payment_service.get_merchant_subscription(sample_merchant_user.id)
        
        assert response is None
    
    async def test_get_merchant_subscription_not_merchant(
        self,
        payment_service: PaymentService,
        sample_client_user
    ):
        """Test getting subscription for non-merchant user."""
        response = await payment_service.get_merchant_subscription(sample_client_user.id)
        
        assert response is None
    
    async def test_check_subscription_limit_services(
        self,
        payment_service: PaymentService,
        sample_merchant_user,
        sample_merchant,
        sample_tariff
    ):
        """Test checking subscription limit for services."""
        # Create active subscription
        from app.models import MerchantSubscription
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        payment_service.session.add(subscription)
        await payment_service.session.commit()
        
        # Check limit (tariff allows 5 services)
        can_add = await payment_service.check_subscription_limit(
            sample_merchant_user.id,
            "services",
            4  # Currently has 4
        )
        assert can_add is True
        
        cannot_add = await payment_service.check_subscription_limit(
            sample_merchant_user.id,
            "services",
            5  # At limit
        )
        assert cannot_add is False
    
    async def test_check_subscription_limit_website(
        self,
        payment_service: PaymentService,
        sample_merchant_user,
        sample_merchant,
        sample_tariff
    ):
        """Test checking subscription limit for website."""
        # Create subscription
        from app.models import MerchantSubscription
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        payment_service.session.add(subscription)
        await payment_service.session.commit()
        
        # Check website limit
        can_use = await payment_service.check_subscription_limit(
            sample_merchant_user.id,
            "website",
            0
        )
        assert can_use == sample_tariff.allow_website
    
    async def test_check_subscription_limit_no_subscription(
        self,
        payment_service: PaymentService,
        sample_merchant_user
    ):
        """Test checking subscription limit when no subscription exists."""
        can_add = await payment_service.check_subscription_limit(
            sample_merchant_user.id,
            "services",
            0
        )
        assert can_add is False
    
    async def test_expire_old_subscriptions(
        self,
        payment_service: PaymentService,
        sample_merchant,
        sample_tariff
    ):
        """Test expiring old subscriptions."""
        # Create expired subscription
        from app.models import MerchantSubscription
        expired_sub = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today() - timedelta(days=60),
            end_date=date.today() - timedelta(days=1),
            status=SubscriptionStatus.ACTIVE
        )
        payment_service.session.add(expired_sub)
        await payment_service.session.commit()
        
        count = await payment_service.expire_old_subscriptions()
        
        assert count >= 1
        await payment_service.session.refresh(expired_sub)
        assert expired_sub.status == SubscriptionStatus.EXPIRED

