import pytest
from datetime import datetime, date, timedelta
from unittest.mock import Mock, AsyncMock, patch
from uuid import uuid4, UUID
from sqlmodel import Session

from app.models.payment import (
    TariffPlan, Payment, MerchantSubscription,
    PaymentType, PaymentMethod, PaymentStatus, SubscriptionStatus
)
from app.models.user import User, UserType, Merchant
from app.services.payment_service import PaymentService, PaymentError, SubscriptionError
from app.schemas.payment import (
    TariffPaymentRequest, PaymentResponse, 
    TariffPlanResponse, SubscriptionResponse
)


@pytest.fixture
def payment_service(session: Session, mock_payment_providers, mock_sms_service):
    """Create payment service instance with mocked dependencies."""
    return PaymentService(
        session=session,
        payment_providers=mock_payment_providers,
        sms_service=mock_sms_service
    )


@pytest.fixture
def sample_user_merchant(session: Session):
    """Create sample user and merchant for testing."""
    user = User(
        phone_number="998901234567",
        name="Test Merchant",
        user_type=UserType.MERCHANT
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    
    merchant = Merchant(
        user_id=user.id,
        business_name="Test Business",
        location_region="Toshkent"
    )
    session.add(merchant)
    session.commit()
    session.refresh(merchant)
    
    return user, merchant


@pytest.fixture
def sample_tariff_plan(session: Session):
    """Create sample tariff plan."""
    plan = TariffPlan(
        name="Standard Plan",
        price_per_month=75000.0,
        max_services=20,
        max_images_per_service=8,
        max_phone_numbers=3,
        max_gallery_images=50,
        max_social_accounts=5,
        allow_website=True,
        allow_cover_image=True,
        monthly_featured_cards=2
    )
    session.add(plan)
    session.commit()
    session.refresh(plan)
    return plan


class TestPaymentService:
    """Test PaymentService business logic."""

    @pytest.mark.asyncio
    async def test_get_tariff_plans(self, payment_service, session: Session):
        """Test getting available tariff plans."""
        # Create test plans
        plans = [
            TariffPlan(name="Basic", price_per_month=50000.0, max_services=10, 
                      max_images_per_service=5, max_phone_numbers=2, 
                      max_gallery_images=20, max_social_accounts=3),
            TariffPlan(name="Premium", price_per_month=100000.0, max_services=50, 
                      max_images_per_service=10, max_phone_numbers=5, 
                      max_gallery_images=100, max_social_accounts=10),
            TariffPlan(name="Inactive", price_per_month=25000.0, max_services=5, 
                      max_images_per_service=3, max_phone_numbers=1, 
                      max_gallery_images=10, max_social_accounts=2, is_active=False)
        ]
        
        for plan in plans:
            session.add(plan)
        session.commit()
        
        # Test service method
        result = await payment_service.get_active_tariff_plans()
        
        assert len(result) == 2  # Only active plans
        assert all(plan.is_active for plan in result)
        
        names = [plan.name for plan in result]
        assert "Basic" in names
        assert "Premium" in names
        assert "Inactive" not in names

    @pytest.mark.asyncio
    async def test_calculate_subscription_price_discounts(self, payment_service):
        """Test subscription price calculation with discounts."""
        base_price = 100000.0
        
        # Test different duration discounts
        assert payment_service._calculate_subscription_price(base_price, 1) == 100000.0  # 0% discount
        assert payment_service._calculate_subscription_price(base_price, 3) == 270000.0   # 10% discount
        assert payment_service._calculate_subscription_price(base_price, 6) == 480000.0   # 20% discount
        assert payment_service._calculate_subscription_price(base_price, 12) == 840000.0  # 30% discount

    @pytest.mark.asyncio
    async def test_create_tariff_payment_success(self, payment_service, sample_user_merchant, sample_tariff_plan):
        """Test successful tariff payment creation."""
        user, merchant = sample_user_merchant
        plan = sample_tariff_plan
        
        # Mock payment provider response
        mock_payment_url = "https://checkout.paycom.uz/test_payment_123"
        payment_service.payment_providers['payme'].create_payment.return_value = {
            'payment_url': mock_payment_url,
            'transaction_id': 'payme_txn_123'
        }
        
        request_data = TariffPaymentRequest(
            tariff_plan_id=plan.id,
            duration_months=3,
            payment_method=PaymentMethod.PAYME
        )
        
        result = await payment_service.create_tariff_payment(user.id, request_data)
        
        assert isinstance(result, PaymentResponse)
        assert result.payment_url == mock_payment_url
        assert result.amount == 202500.0  # 75000 * 3 * 0.9 (10% discount)
        assert result.payment_method == PaymentMethod.PAYME
        assert result.status == PaymentStatus.PENDING
        
        # Verify payment was created in database
        payments = payment_service.session.query(Payment).filter(
            Payment.user_id == user.id
        ).all()
        assert len(payments) == 1
        assert payments[0].amount == 202500.0
        assert payments[0].payment_type == PaymentType.TARIFF_SUBSCRIPTION

    @pytest.mark.asyncio
    async def test_create_tariff_payment_invalid_plan(self, payment_service, sample_user_merchant):
        """Test tariff payment creation with invalid plan ID."""
        user, _ = sample_user_merchant
        
        request_data = TariffPaymentRequest(
            tariff_plan_id=uuid4(),  # Non-existent plan
            duration_months=1,
            payment_method=PaymentMethod.PAYME
        )
        
        with pytest.raises(PaymentError, match="Tariff plan not found"):
            await payment_service.create_tariff_payment(user.id, request_data)

    @pytest.mark.asyncio
    async def test_create_tariff_payment_provider_error(self, payment_service, sample_user_merchant, sample_tariff_plan):
        """Test handling payment provider errors."""
        user, merchant = sample_user_merchant
        plan = sample_tariff_plan
        
        # Mock payment provider error
        payment_service.payment_providers['payme'].create_payment.side_effect = Exception("Provider error")
        
        request_data = TariffPaymentRequest(
            tariff_plan_id=plan.id,
            duration_months=1,
            payment_method=PaymentMethod.PAYME
        )
        
        with pytest.raises(PaymentError, match="Failed to create payment"):
            await payment_service.create_tariff_payment(user.id, request_data)

    @pytest.mark.asyncio
    async def test_process_payment_webhook_success(self, payment_service, session: Session):
        """Test successful payment webhook processing."""
        # Create pending payment
        user = User(phone_number="998901234568", name="Test User", user_type=UserType.MERCHANT)
        session.add(user)
        session.commit()
        session.refresh(user)
        
        merchant = Merchant(user_id=user.id, business_name="Test", location_region="Toshkent")
        session.add(merchant)
        session.commit()
        session.refresh(merchant)
        
        plan = TariffPlan(name="Test Plan", price_per_month=50000.0, max_services=10,
                         max_images_per_service=5, max_phone_numbers=2,
                         max_gallery_images=20, max_social_accounts=3)
        session.add(plan)
        session.commit()
        session.refresh(plan)
        
        payment = Payment(
            user_id=user.id,
            amount=50000.0,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            transaction_id="payme_txn_123",
            status=PaymentStatus.PENDING
        )
        session.add(payment)
        session.commit()
        session.refresh(payment)
        
        # Mock webhook data
        webhook_data = {
            "id": "webhook_123",
            "method": "payme",
            "params": {
                "id": "payme_txn_123",
                "state": 2,  # Completed
                "amount": 500000  # In tiyins (50000 UZS)
            }
        }
        
        # Process webhook
        result = await payment_service.process_payment_webhook(
            payment_method=PaymentMethod.PAYME,
            webhook_data=webhook_data
        )
        
        assert result is True
        
        # Verify payment status updated
        session.refresh(payment)
        assert payment.status == PaymentStatus.COMPLETED
        assert payment.completed_at is not None
        assert payment.webhook_data == webhook_data
        
        # Verify subscription was created for tariff payments
        subscriptions = session.query(MerchantSubscription).filter(
            MerchantSubscription.merchant_id == merchant.id
        ).all()
        assert len(subscriptions) == 1
        assert subscriptions[0].status == SubscriptionStatus.ACTIVE

    @pytest.mark.asyncio
    async def test_get_merchant_subscription(self, payment_service, sample_user_merchant, sample_tariff_plan):
        """Test getting merchant's current subscription."""
        user, merchant = sample_user_merchant
        plan = sample_tariff_plan
        
        # Create active subscription
        subscription = MerchantSubscription(
            merchant_id=merchant.id,
            tariff_plan_id=plan.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        payment_service.session.add(subscription)
        payment_service.session.commit()
        
        result = await payment_service.get_merchant_subscription(user.id)
        
        assert isinstance(result, SubscriptionResponse)
        assert result.status == SubscriptionStatus.ACTIVE
        assert result.tariff_plan.name == plan.name
        assert result.end_date == subscription.end_date

    @pytest.mark.asyncio
    async def test_get_merchant_subscription_no_active(self, payment_service, sample_user_merchant):
        """Test getting subscription when merchant has no active subscription."""
        user, merchant = sample_user_merchant
        
        result = await payment_service.get_merchant_subscription(user.id)
        assert result is None

    @pytest.mark.asyncio
    async def test_check_subscription_limits(self, payment_service, sample_user_merchant, sample_tariff_plan):
        """Test checking if merchant can perform action within subscription limits."""
        user, merchant = sample_user_merchant
        plan = sample_tariff_plan
        
        # Create active subscription
        subscription = MerchantSubscription(
            merchant_id=merchant.id,
            tariff_plan_id=plan.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        payment_service.session.add(subscription)
        payment_service.session.commit()
        
        # Test within limits
        result = await payment_service.check_subscription_limit(
            user.id, "services", current_count=10
        )
        assert result is True
        
        # Test exceeding limits
        result = await payment_service.check_subscription_limit(
            user.id, "services", current_count=25  # More than plan.max_services (20)
        )
        assert result is False

    @pytest.mark.asyncio
    async def test_activate_subscription(self, payment_service, sample_user_merchant, sample_tariff_plan):
        """Test subscription activation after payment."""
        user, merchant = sample_user_merchant
        plan = sample_tariff_plan
        
        # Create completed payment
        payment = Payment(
            user_id=user.id,
            amount=75000.0,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            status=PaymentStatus.COMPLETED,
            completed_at=datetime.utcnow()
        )
        payment_service.session.add(payment)
        payment_service.session.commit()
        payment_service.session.refresh(payment)
        
        # Activate subscription
        subscription = await payment_service._activate_subscription(
            payment=payment,
            merchant_id=merchant.id,
            tariff_plan_id=plan.id,
            duration_months=1
        )
        
        assert isinstance(subscription, MerchantSubscription)
        assert subscription.merchant_id == merchant.id
        assert subscription.tariff_plan_id == plan.id
        assert subscription.payment_id == payment.id
        assert subscription.status == SubscriptionStatus.ACTIVE
        assert subscription.start_date == date.today()
        assert subscription.end_date == date.today() + timedelta(days=30)

    @pytest.mark.asyncio
    async def test_expire_subscriptions(self, payment_service, sample_user_merchant, sample_tariff_plan):
        """Test expiring old subscriptions."""
        user, merchant = sample_user_merchant
        plan = sample_tariff_plan
        
        # Create expired subscription
        expired_subscription = MerchantSubscription(
            merchant_id=merchant.id,
            tariff_plan_id=plan.id,
            start_date=date.today() - timedelta(days=60),
            end_date=date.today() - timedelta(days=1),
            status=SubscriptionStatus.ACTIVE  # Still marked as active
        )
        payment_service.session.add(expired_subscription)
        payment_service.session.commit()
        
        # Run expiry process
        expired_count = await payment_service.expire_old_subscriptions()
        
        assert expired_count == 1
        
        # Verify subscription status updated
        payment_service.session.refresh(expired_subscription)
        assert expired_subscription.status == SubscriptionStatus.EXPIRED