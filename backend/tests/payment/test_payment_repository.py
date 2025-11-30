"""
Tests for PaymentRepository.
"""
import pytest
from uuid import uuid4
from datetime import date, datetime, timedelta

from app.repositories.payment_repository import PaymentRepository
from app.models import (
    Payment, PaymentType, PaymentMethod, PaymentStatus,
    MerchantSubscription, SubscriptionStatus, TariffPlan,
    Merchant, Service, FeaturedService, FeatureType,
    Image, ImageType, MerchantContact, ContactType
)


@pytest.mark.asyncio
class TestPaymentRepository:
    """Test PaymentRepository methods."""
    
    async def test_create_payment(self, db_session, sample_merchant_user):
        """Test creating a payment."""
        repo = PaymentRepository(db_session)
        
        payment = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            amount=100000.0,
            status=PaymentStatus.PENDING,
            transaction_id=f"trans_{uuid4()}"
        )
        
        created = await repo.create_payment(payment)
        
        assert created.id is not None
        assert created.amount == 100000.0
        assert created.status == PaymentStatus.PENDING
    
    async def test_get_payment_by_id(self, db_session, sample_merchant_user):
        """Test getting payment by ID."""
        repo = PaymentRepository(db_session)
        
        payment = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            amount=100000.0,
            status=PaymentStatus.PENDING,
            transaction_id=f"trans_{uuid4()}"
        )
        db_session.add(payment)
        await db_session.commit()
        await db_session.refresh(payment)
        
        retrieved = await repo.get_payment_by_id(payment.id)
        
        assert retrieved is not None
        assert retrieved.id == payment.id
        assert retrieved.amount == payment.amount
    
    async def test_get_payment_by_transaction_id(self, db_session, sample_merchant_user):
        """Test getting payment by transaction ID."""
        repo = PaymentRepository(db_session)
        
        transaction_id = f"trans_{uuid4()}"
        payment = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            amount=100000.0,
            status=PaymentStatus.PENDING,
            transaction_id=transaction_id
        )
        db_session.add(payment)
        await db_session.commit()
        
        retrieved = await repo.get_payment_by_transaction_id(transaction_id)
        
        assert retrieved is not None
        assert retrieved.transaction_id == transaction_id
    
    async def test_get_payments_by_user_id(self, db_session, sample_merchant_user):
        """Test getting payments by user ID."""
        repo = PaymentRepository(db_session)
        
        # Create multiple payments
        payment1 = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            amount=100000.0,
            status=PaymentStatus.PENDING,
            transaction_id=f"trans_{uuid4()}"
        )
        payment2 = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.FEATURED_SERVICE,
            payment_method=PaymentMethod.PAYME,
            amount=50000.0,
            status=PaymentStatus.COMPLETED,
            transaction_id=f"trans_{uuid4()}"
        )
        db_session.add(payment1)
        db_session.add(payment2)
        await db_session.commit()
        
        payments = await repo.get_payments_by_user_id(sample_merchant_user.id)
        
        assert len(payments) >= 2
        payment_ids = [p.id for p in payments]
        assert payment1.id in payment_ids
        assert payment2.id in payment_ids
    
    async def test_get_payments_by_user_id_with_filters(self, db_session, sample_merchant_user):
        """Test getting payments by user ID with filters."""
        repo = PaymentRepository(db_session)
        
        # Create payments with different types and statuses
        payment1 = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            amount=100000.0,
            status=PaymentStatus.COMPLETED,
            transaction_id=f"trans_{uuid4()}"
        )
        payment2 = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.FEATURED_SERVICE,
            payment_method=PaymentMethod.PAYME,
            amount=50000.0,
            status=PaymentStatus.COMPLETED,
            transaction_id=f"trans_{uuid4()}"
        )
        payment3 = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            amount=100000.0,
            status=PaymentStatus.PENDING,
            transaction_id=f"trans_{uuid4()}"
        )
        db_session.add(payment1)
        db_session.add(payment2)
        db_session.add(payment3)
        await db_session.commit()
        
        # Filter by type
        tariff_payments = await repo.get_payments_by_user_id(
            sample_merchant_user.id,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION
        )
        assert len(tariff_payments) >= 2
        
        # Filter by status
        completed_payments = await repo.get_payments_by_user_id(
            sample_merchant_user.id,
            status=PaymentStatus.COMPLETED
        )
        assert len(completed_payments) >= 2
        
        # Filter by both
        completed_tariff = await repo.get_payments_by_user_id(
            sample_merchant_user.id,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            status=PaymentStatus.COMPLETED
        )
        assert len(completed_tariff) >= 1
    
    async def test_update_payment_status(self, db_session, sample_merchant_user):
        """Test updating payment status."""
        repo = PaymentRepository(db_session)
        
        payment = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            amount=100000.0,
            status=PaymentStatus.PENDING,
            transaction_id=f"trans_{uuid4()}"
        )
        db_session.add(payment)
        await db_session.commit()
        await db_session.refresh(payment)
        
        updated = await repo.update_payment_status(
            payment.id,
            PaymentStatus.COMPLETED,
            completed_at=datetime.now()
        )
        
        assert updated is not None
        assert updated.status == PaymentStatus.COMPLETED
        assert updated.completed_at is not None
    
    async def test_get_pending_payments(self, db_session, sample_merchant_user):
        """Test getting pending payments older than specified time."""
        repo = PaymentRepository(db_session)
        
        # Create old pending payment
        old_payment = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            amount=100000.0,
            status=PaymentStatus.PENDING,
            transaction_id=f"trans_{uuid4()}",
            created_at=datetime.now() - timedelta(hours=1)
        )
        db_session.add(old_payment)
        await db_session.commit()
        
        # Get payments older than 30 minutes
        pending = await repo.get_pending_payments(older_than_minutes=30)
        
        assert len(pending) >= 1
        payment_ids = [p.id for p in pending]
        assert old_payment.id in payment_ids
    
    async def test_create_subscription(self, db_session, sample_merchant, sample_tariff):
        """Test creating a merchant subscription."""
        repo = PaymentRepository(db_session)
        
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        
        created = await repo.create_subscription(subscription)
        
        assert created.id is not None
        assert created.status == SubscriptionStatus.ACTIVE
    
    async def test_get_merchant_active_subscription(
        self,
        db_session,
        sample_merchant,
        sample_tariff
    ):
        """Test getting merchant's active subscription."""
        repo = PaymentRepository(db_session)
        
        # Create active subscription
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        active = await repo.get_merchant_active_subscription(sample_merchant.id)
        
        assert active is not None
        assert active.status == SubscriptionStatus.ACTIVE
        assert active.merchant_id == sample_merchant.id
    
    async def test_get_merchant_subscriptions(
        self,
        db_session,
        sample_merchant,
        sample_tariff
    ):
        """Test getting all subscriptions for a merchant."""
        repo = PaymentRepository(db_session)
        
        # Create multiple subscriptions
        sub1 = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        sub2 = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today() - timedelta(days=60),
            end_date=date.today() - timedelta(days=30),
            status=SubscriptionStatus.EXPIRED
        )
        db_session.add(sub1)
        db_session.add(sub2)
        await db_session.commit()
        
        all_subs = await repo.get_merchant_subscriptions(sample_merchant.id)
        assert len(all_subs) >= 2
        
        active_subs = await repo.get_merchant_subscriptions(
            sample_merchant.id,
            status=SubscriptionStatus.ACTIVE
        )
        assert len(active_subs) >= 1
    
    async def test_expire_subscriptions_by_date(
        self,
        db_session,
        sample_merchant,
        sample_tariff
    ):
        """Test expiring subscriptions by date."""
        repo = PaymentRepository(db_session)
        
        # Create expired subscription
        expired_sub = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today() - timedelta(days=60),
            end_date=date.today() - timedelta(days=1),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(expired_sub)
        await db_session.commit()
        
        # Expire subscriptions before today
        count = await repo.expire_subscriptions_by_date(date.today())
        
        assert count >= 1
        await db_session.refresh(expired_sub)
        assert expired_sub.status == SubscriptionStatus.EXPIRED
    
    async def test_get_expiring_subscriptions(
        self,
        db_session,
        sample_merchant,
        sample_tariff
    ):
        """Test getting subscriptions expiring soon."""
        repo = PaymentRepository(db_session)
        
        # Create subscription expiring in 5 days
        expiring_sub = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today() - timedelta(days=25),
            end_date=date.today() + timedelta(days=5),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(expiring_sub)
        await db_session.commit()
        
        expiring = await repo.get_expiring_subscriptions(days_ahead=7)
        
        assert len(expiring) >= 1
        sub_ids = [s.id for s in expiring]
        assert expiring_sub.id in sub_ids
    
    async def test_cancel_subscription(
        self,
        db_session,
        sample_merchant,
        sample_tariff
    ):
        """Test canceling a subscription."""
        repo = PaymentRepository(db_session)
        
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        await db_session.refresh(subscription)
        
        cancelled = await repo.cancel_subscription(subscription.id)
        
        assert cancelled is not None
        assert cancelled.status == SubscriptionStatus.CANCELLED
    
    async def test_count_merchant_services(self, db_session, sample_merchant, sample_category):
        """Test counting merchant services."""
        repo = PaymentRepository(db_session)
        
        # Create a service
        service = Service(
            merchant_id=sample_merchant.id,
            category_id=sample_category.id,
            name="Test Service",
            description="Test service description",
            price=100000.0,
            location_region="Tashkent",
            is_active=True
        )
        db_session.add(service)
        await db_session.commit()
        
        count = await repo.count_merchant_services(sample_merchant.id)
        
        assert count >= 1
    
    async def test_count_service_images(self, db_session, sample_service):
        """Test counting service images."""
        repo = PaymentRepository(db_session)
        
        # Create an image
        image = Image(
            related_id=sample_service.id,
            image_type=ImageType.SERVICE_IMAGE,
            s3_url="https://example.com/image.jpg",
            file_name="image.jpg",
            is_active=True
        )
        db_session.add(image)
        await db_session.commit()
        
        count = await repo.count_service_images(sample_service.id)
        
        assert count >= 1
    
    async def test_count_merchant_phone_numbers(self, db_session, sample_merchant):
        """Test counting merchant phone numbers."""
        repo = PaymentRepository(db_session)
        
        # Create a phone contact
        contact = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="998901234567",
            is_active=True
        )
        db_session.add(contact)
        await db_session.commit()
        
        count = await repo.count_merchant_phone_numbers(sample_merchant.id)
        
        assert count >= 1
    
    async def test_count_merchant_gallery_images(self, db_session, sample_merchant):
        """Test counting merchant gallery images."""
        repo = PaymentRepository(db_session)
        
        # Create a gallery image
        image = Image(
            related_id=sample_merchant.id,
            image_type=ImageType.MERCHANT_GALLERY,
            s3_url="https://example.com/gallery.jpg",
            file_name="gallery.jpg",
            is_active=True
        )
        db_session.add(image)
        await db_session.commit()
        
        count = await repo.count_merchant_gallery_images(sample_merchant.id)
        
        assert count >= 1
    
    async def test_count_merchant_social_accounts(self, db_session, sample_merchant):
        """Test counting merchant social accounts."""
        repo = PaymentRepository(db_session)
        
        # Create a social media contact
        contact = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.SOCIAL_MEDIA,
            contact_value="https://instagram.com/test",
            platform_name="instagram",
            is_active=True
        )
        db_session.add(contact)
        await db_session.commit()
        
        count = await repo.count_merchant_social_accounts(sample_merchant.id)
        
        assert count >= 1
    
    async def test_count_monthly_featured_allocations_used(
        self,
        db_session,
        sample_merchant,
        sample_service
    ):
        """Test counting monthly featured allocations used."""
        repo = PaymentRepository(db_session)
        
        # Create a monthly featured service
        now = datetime.now()
        featured = FeaturedService(
            service_id=sample_service.id,
            merchant_id=sample_merchant.id,
            start_date=datetime(now.year, now.month, 1),
            end_date=datetime(now.year, now.month, 1) + timedelta(days=30),
            days_duration=30,
            feature_type=FeatureType.MONTHLY_ALLOCATION,
            is_active=True
        )
        db_session.add(featured)
        await db_session.commit()
        
        count = await repo.count_monthly_featured_allocations_used(
            sample_merchant.id,
            now.year,
            now.month
        )
        
        assert count >= 1
    
    async def test_get_revenue_by_period(self, db_session, sample_merchant_user):
        """Test getting revenue by period."""
        repo = PaymentRepository(db_session)
        
        # Create completed payments
        payment1 = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            amount=100000.0,
            status=PaymentStatus.COMPLETED,
            transaction_id=f"trans_{uuid4()}",
            completed_at=datetime.now()
        )
        payment2 = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.FEATURED_SERVICE,
            payment_method=PaymentMethod.PAYME,
            amount=50000.0,
            status=PaymentStatus.COMPLETED,
            transaction_id=f"trans_{uuid4()}",
            completed_at=datetime.now()
        )
        db_session.add(payment1)
        db_session.add(payment2)
        await db_session.commit()
        
        revenue = await repo.get_revenue_by_period(
            date.today() - timedelta(days=1),
            date.today() + timedelta(days=1)
        )
        
        assert revenue >= 150000.0
    
    async def test_get_payment_stats(self, db_session, sample_merchant_user):
        """Test getting payment statistics."""
        repo = PaymentRepository(db_session)
        
        # Create payments with different statuses
        completed = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.TARIFF_SUBSCRIPTION,
            payment_method=PaymentMethod.PAYME,
            amount=100000.0,
            status=PaymentStatus.COMPLETED,
            transaction_id=f"trans_{uuid4()}"
        )
        pending = Payment(
            user_id=sample_merchant_user.id,
            payment_type=PaymentType.FEATURED_SERVICE,
            payment_method=PaymentMethod.PAYME,
            amount=50000.0,
            status=PaymentStatus.PENDING,
            transaction_id=f"trans_{uuid4()}"
        )
        db_session.add(completed)
        db_session.add(pending)
        await db_session.commit()
        
        stats = await repo.get_payment_stats()
        
        assert "total_payments" in stats
        assert "completed_payments" in stats
        assert "pending_payments" in stats
        assert "total_revenue" in stats
        assert stats["completed_payments"] >= 1
        assert stats["pending_payments"] >= 1
    
    async def test_get_subscription_stats(
        self,
        db_session,
        sample_merchant,
        sample_tariff
    ):
        """Test getting subscription statistics."""
        repo = PaymentRepository(db_session)
        
        # Create subscriptions with different statuses
        active = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        expired = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today() - timedelta(days=60),
            end_date=date.today() - timedelta(days=30),
            status=SubscriptionStatus.EXPIRED
        )
        db_session.add(active)
        db_session.add(expired)
        await db_session.commit()
        
        stats = await repo.get_subscription_stats()
        
        assert "total_subscriptions" in stats
        assert "active_subscriptions" in stats
        assert "expired_subscriptions" in stats
        assert stats["active_subscriptions"] >= 1
        assert stats["expired_subscriptions"] >= 1

