import pytest
from datetime import datetime, date, timedelta
from uuid import uuid4
from sqlmodel import Session, select

from app.models.payment import (
    TariffPlan, Payment, MerchantSubscription,
    PaymentType, PaymentMethod, PaymentStatus, SubscriptionStatus
)
from app.models.user import User, UserType, Merchant


class TestTariffPlan:
    """Test TariffPlan model."""

    def test_create_tariff_plan(self, session: Session):
        """Test creating a tariff plan."""
        plan = TariffPlan(
            name="Premium Plan",
            price_per_month=100000.0,
            max_services=50,
            max_images_per_service=10,
            max_phone_numbers=5,
            max_gallery_images=100,
            max_social_accounts=10,
            allow_website=True,
            allow_cover_image=True,
            monthly_featured_cards=5
        )
        
        session.add(plan)
        session.commit()
        session.refresh(plan)
        
        assert plan.id is not None
        assert plan.name == "Premium Plan"
        assert plan.price_per_month == 100000.0
        assert plan.max_services == 50
        assert plan.is_active is True
        assert isinstance(plan.created_at, datetime)

    def test_tariff_plan_unique_name(self, session: Session):
        """Test that tariff plan names are unique."""
        plan1 = TariffPlan(
            name="Unique Plan",
            price_per_month=50000.0,
            max_services=10,
            max_images_per_service=5,
            max_phone_numbers=2,
            max_gallery_images=20,
            max_social_accounts=3
        )
        
        plan2 = TariffPlan(
            name="Unique Plan",  # Same name
            price_per_month=75000.0,
            max_services=20,
            max_images_per_service=8,
            max_phone_numbers=3,
            max_gallery_images=30,
            max_social_accounts=5
        )
        
        session.add(plan1)
        session.commit()
        
        session.add(plan2)
        with pytest.raises(Exception):  # Should raise integrity error
            session.commit()


class TestPayment:
    """Test Payment model."""

    def test_create_payment(self, session: Session):
        """Test creating a payment record."""
        # Create user first
        user = User(
            phone_number="998901234567",
            name="Test User",
            user_type=UserType.MERCHANT
        )
        session.add(user)
        session.commit()
        session.refresh(user)
        
        payment = Payment(
            user_id=user.id,
            amount=50000.0,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            transaction_id="test_txn_123",
            payment_url="https://checkout.paycom.uz/test"
        )
        
        session.add(payment)
        session.commit()
        session.refresh(payment)
        
        assert payment.id is not None
        assert payment.user_id == user.id
        assert payment.amount == 50000.0
        assert payment.payment_type == PaymentType.TARIFF_SUBSCRIPTION
        assert payment.payment_method == PaymentMethod.PAYME
        assert payment.status == PaymentStatus.PENDING
        assert payment.transaction_id == "test_txn_123"
        assert isinstance(payment.created_at, datetime)
        assert payment.completed_at is None

    def test_payment_status_transitions(self, session: Session):
        """Test payment status transitions."""
        # Create user
        user = User(
            phone_number="998901234568",
            name="Test User 2",
            user_type=UserType.MERCHANT
        )
        session.add(user)
        session.commit()
        session.refresh(user)
        
        payment = Payment(
            user_id=user.id,
            amount=25000.0,
            payment_type=PaymentType.FEATURED_SERVICE,
            payment_method=PaymentMethod.CLICK
        )
        
        # Initially pending
        assert payment.status == PaymentStatus.PENDING
        
        # Mark as completed
        payment.status = PaymentStatus.COMPLETED
        payment.completed_at = datetime.utcnow()
        
        session.add(payment)
        session.commit()
        
        assert payment.status == PaymentStatus.COMPLETED
        assert payment.completed_at is not None

    def test_payment_webhook_data(self, session: Session):
        """Test storing webhook data in payment."""
        user = User(
            phone_number="998901234569",
            name="Test User 3",
            user_type=UserType.MERCHANT
        )
        session.add(user)
        session.commit()
        session.refresh(user)
        
        webhook_data = {
            "id": "webhook_123",
            "method": "payme",
            "params": {
                "id": "payment_123",
                "state": 2,
                "amount": 500000
            }
        }
        
        payment = Payment(
            user_id=user.id,
            amount=50000.0,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            webhook_data=webhook_data
        )
        
        session.add(payment)
        session.commit()
        session.refresh(payment)
        
        assert payment.webhook_data == webhook_data
        assert payment.webhook_data["method"] == "payme"


class TestMerchantSubscription:
    """Test MerchantSubscription model."""

    def test_create_subscription(self, session: Session):
        """Test creating a merchant subscription."""
        # Create user and merchant
        user = User(
            phone_number="998901234570",
            name="Merchant User",
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
        
        # Create tariff plan
        plan = TariffPlan(
            name="Business Plan",
            price_per_month=75000.0,
            max_services=25,
            max_images_per_service=8,
            max_phone_numbers=3,
            max_gallery_images=50,
            max_social_accounts=5
        )
        session.add(plan)
        session.commit()
        session.refresh(plan)
        
        # Create payment
        payment = Payment(
            user_id=user.id,
            amount=75000.0,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.UZUMBANK,
            status=PaymentStatus.COMPLETED
        )
        session.add(payment)
        session.commit()
        session.refresh(payment)
        
        # Create subscription
        subscription = MerchantSubscription(
            merchant_id=merchant.id,
            tariff_plan_id=plan.id,
            payment_id=payment.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30)
        )
        
        session.add(subscription)
        session.commit()
        session.refresh(subscription)
        
        assert subscription.id is not None
        assert subscription.merchant_id == merchant.id
        assert subscription.tariff_plan_id == plan.id
        assert subscription.payment_id == payment.id
        assert subscription.status == SubscriptionStatus.ACTIVE
        assert isinstance(subscription.start_date, date)
        assert isinstance(subscription.end_date, date)
        assert isinstance(subscription.created_at, datetime)

    def test_subscription_relationships(self, session: Session):
        """Test subscription model relationships."""
        # Create user, merchant, plan, and subscription
        user = User(
            phone_number="998901234571",
            name="Merchant User 2",
            user_type=UserType.MERCHANT
        )
        session.add(user)
        session.commit()
        session.refresh(user)
        
        merchant = Merchant(
            user_id=user.id,
            business_name="Test Business 2",
            location_region="Samarqand"
        )
        session.add(merchant)
        session.commit()
        session.refresh(merchant)
        
        plan = TariffPlan(
            name="Enterprise Plan",
            price_per_month=150000.0,
            max_services=100,
            max_images_per_service=15,
            max_phone_numbers=10,
            max_gallery_images=200,
            max_social_accounts=20
        )
        session.add(plan)
        session.commit()
        session.refresh(plan)
        
        subscription = MerchantSubscription(
            merchant_id=merchant.id,
            tariff_plan_id=plan.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30)
        )
        
        session.add(subscription)
        session.commit()
        session.refresh(subscription)
        
        # Test relationships
        assert subscription.merchant == merchant
        assert subscription.tariff_plan == plan
        assert merchant.subscriptions == [subscription]
        assert plan.subscriptions == [subscription]

    def test_subscription_expiry(self, session: Session):
        """Test subscription expiry status."""
        user = User(
            phone_number="998901234572",
            name="Merchant User 3",
            user_type=UserType.MERCHANT
        )
        session.add(user)
        session.commit()
        session.refresh(user)
        
        merchant = Merchant(
            user_id=user.id,
            business_name="Test Business 3",
            location_region="Buxoro"
        )
        session.add(merchant)
        session.commit()
        session.refresh(merchant)
        
        plan = TariffPlan(
            name="Starter Plan",
            price_per_month=25000.0,
            max_services=5,
            max_images_per_service=3,
            max_phone_numbers=1,
            max_gallery_images=10,
            max_social_accounts=2
        )
        session.add(plan)
        session.commit()
        session.refresh(plan)
        
        # Create expired subscription
        subscription = MerchantSubscription(
            merchant_id=merchant.id,
            tariff_plan_id=plan.id,
            start_date=date.today() - timedelta(days=60),
            end_date=date.today() - timedelta(days=30),
            status=SubscriptionStatus.EXPIRED
        )
        
        session.add(subscription)
        session.commit()
        session.refresh(subscription)
        
        assert subscription.status == SubscriptionStatus.EXPIRED
        assert subscription.end_date < date.today()