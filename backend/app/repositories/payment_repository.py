from datetime import date, datetime, timedelta
from typing import List, Optional
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from app.models import (
    TariffPlan,
    Payment,
    MerchantSubscription,
    PaymentType,
    PaymentMethod,
    PaymentStatus,
    SubscriptionStatus,
    Merchant,
    Service,
    FeaturedService,
    FeatureType,
    Image,
    ImageType,
    MerchantContact,
    ContactType
)

class PaymentRepository:
    """Repository for payment-related database operations."""
    
    def __init__(self, session: AsyncSession):
        self.session = session
    
    # TariffPlan operations
    async def get_active_tariff_plans(self) -> List[TariffPlan]:
        """Get all active tariff plans."""
        statement = select(TariffPlan).where(TariffPlan.is_active == True)
        result = await self.session.execute(statement)
        return list(result.scalars().all())
    
    async def get_tariff_plan_by_id(self, plan_id: UUID) -> Optional[TariffPlan]:
        """Get tariff plan by ID."""
        return await self.session.get(TariffPlan, plan_id)
    
    async def get_tariff_plan_by_name(self, name: str) -> Optional[TariffPlan]:
        """Get tariff plan by name."""
        statement = select(TariffPlan).where(TariffPlan.name == name)
        result = await self.session.execute(statement)
        return result.scalar_one_or_none()
    
    async def get_all_tariff_plans(
        self,
        include_inactive: bool = False,
        offset: int = 0,
        limit: int = 100
    ) -> tuple[List[TariffPlan], int]:
        """
        Get all tariff plans with pagination.
        
        Args:
            include_inactive: Whether to include inactive plans
            offset: Pagination offset
            limit: Pagination limit
            
        Returns:
            Tuple of (tariff_plans_list, total_count)
        """
        # Count query
        count_conditions = []
        if not include_inactive:
            count_conditions.append(TariffPlan.is_active == True)
        
        count_statement = select(func.count(TariffPlan.id))
        if count_conditions:
            count_statement = count_statement.where(and_(*count_conditions))
        
        count_result = await self.session.execute(count_statement)
        total_count = count_result.scalar_one()
        
        # Tariff plans query
        statement = select(TariffPlan)
        if not include_inactive:
            statement = statement.where(TariffPlan.is_active == True)
        
        statement = statement.order_by(TariffPlan.created_at.desc()).offset(offset).limit(limit)
        
        result = await self.session.execute(statement)
        tariff_plans = result.scalars().all()
        
        return list(tariff_plans), total_count
    
    async def create_tariff_plan(self, tariff_plan: TariffPlan) -> TariffPlan:
        """Create a new tariff plan."""
        self.session.add(tariff_plan)
        await self.session.commit()
        await self.session.refresh(tariff_plan)
        return tariff_plan
    
    async def update_tariff_plan(self, tariff_plan: TariffPlan) -> TariffPlan:
        """Update tariff plan."""
        self.session.add(tariff_plan)
        await self.session.commit()
        await self.session.refresh(tariff_plan)
        return tariff_plan
    
    async def delete_tariff_plan(self, plan_id: UUID) -> bool:
        """
        Delete a tariff plan (soft delete by setting is_active=False).
        
        Args:
            plan_id: UUID of the tariff plan to delete
            
        Returns:
            True if deleted, False if not found
        """
        plan = await self.get_tariff_plan_by_id(plan_id)
        if not plan:
            return False
        
        # Check if plan has active subscriptions
        subscription_count_statement = select(func.count(MerchantSubscription.id)).where(
            and_(
                MerchantSubscription.tariff_plan_id == plan_id,
                MerchantSubscription.status == SubscriptionStatus.ACTIVE
            )
        )
        subscription_count_result = await self.session.execute(subscription_count_statement)
        subscription_count = subscription_count_result.scalar_one()
        
        if subscription_count > 0:
            # Soft delete: set is_active to False
            plan.is_active = False
            await self.session.commit()
        else:
            # Hard delete if no active subscriptions
            await self.session.delete(plan)
            await self.session.commit()
        
        return True
    
    async def get_tariff_plan_subscription_count(self, plan_id: UUID) -> int:
        """
        Get count of active subscriptions for a tariff plan.
        
        Args:
            plan_id: UUID of the tariff plan
            
        Returns:
            Count of active subscriptions
        """
        statement = select(func.count(MerchantSubscription.id)).where(
            and_(
                MerchantSubscription.tariff_plan_id == plan_id,
                MerchantSubscription.status == SubscriptionStatus.ACTIVE
            )
        )
        result = await self.session.execute(statement)
        return result.scalar_one() or 0
    
    # Payment operations
    async def create_payment(self, payment: Payment) -> Payment:
        """Create a new payment record."""
        self.session.add(payment)
        await self.session.commit()
        await self.session.refresh(payment)
        return payment
    
    async def get_payment_by_id(self, payment_id: UUID) -> Optional[Payment]:
        """Get payment by ID."""
        return await self.session.get(Payment, payment_id)
    
    async def get_payment_by_transaction_id(self, transaction_id: str) -> Optional[Payment]:
        """Get payment by transaction ID."""
        statement = select(Payment).where(Payment.transaction_id == transaction_id)
        result = await self.session.execute(statement)
        return result.scalar_one_or_none()
    
    async def get_payments_by_user_id(
        self, 
        user_id: str, 
        payment_type: Optional[PaymentType] = None,
        status: Optional[PaymentStatus] = None
    ) -> List[Payment]:
        """Get payments by user ID with optional filters."""
        statement = select(Payment).where(Payment.user_id == user_id)
        
        if payment_type:
            statement = statement.where(Payment.payment_type == payment_type)
        
        if status:
            statement = statement.where(Payment.status == status)
        
        result = await self.session.execute(statement)
        return list(result.scalars().all())
    
    async def update_payment_status(
        self, 
        payment_id: UUID, 
        status: PaymentStatus,
        completed_at: Optional[datetime] = None,
        webhook_data: Optional[dict] = None
    ) -> Optional[Payment]:
        """Update payment status."""
        payment = await self.session.get(Payment, payment_id)
        if not payment:
            return None
        
        payment.status = status
        if completed_at:
            payment.completed_at = completed_at
        if webhook_data:
            payment.webhook_data = webhook_data
        
        await self.session.commit()
        await self.session.refresh(payment)
        return payment
    
    async def get_pending_payments(self, older_than_minutes: int = 30) -> List[Payment]:
        """Get pending payments older than specified minutes."""
        cutoff_time = datetime.now() - timedelta(minutes=older_than_minutes)
        statement = select(Payment).where(
            and_(
                Payment.status == PaymentStatus.PENDING,
                Payment.created_at < cutoff_time
            )
        )
        result = await self.session.execute(statement)
        return list(result.scalars().all())
    
    # MerchantSubscription operations
    async def create_subscription(self, subscription: MerchantSubscription) -> MerchantSubscription:
        """Create a new merchant subscription."""
        self.session.add(subscription)
        await self.session.commit()
        await self.session.refresh(subscription)
        return subscription
    
    async def get_merchant_active_subscription(self, merchant_id: UUID) -> Optional[MerchantSubscription]:
        """Get merchant's active subscription."""
        today = date.today()
        statement = select(MerchantSubscription).where(
            and_(
                MerchantSubscription.merchant_id == merchant_id,
                MerchantSubscription.status == SubscriptionStatus.ACTIVE,
                MerchantSubscription.end_date >= today
            )
        )
        result = await self.session.execute(statement)
        return result.scalar_one_or_none()
    
    async def get_merchant_subscriptions(
        self, 
        merchant_id: UUID,
        status: Optional[SubscriptionStatus] = None
    ) -> List[MerchantSubscription]:
        """Get all subscriptions for a merchant."""
        statement = select(MerchantSubscription).where(
            MerchantSubscription.merchant_id == merchant_id
        )
        
        if status:
            statement = statement.where(MerchantSubscription.status == status)
        
        result = await self.session.execute(statement)
        return list(result.scalars().all())
    
    async def expire_subscriptions_by_date(self, end_date: date) -> int:
        """Expire subscriptions that have passed the given date."""
        statement = select(MerchantSubscription).where(
            and_(
                MerchantSubscription.status == SubscriptionStatus.ACTIVE,
                MerchantSubscription.end_date < end_date
            )
        )
        
        result = await self.session.execute(statement)
        subscriptions = result.scalars().all()
        count = 0

        for subscription in subscriptions:
            subscription.status = SubscriptionStatus.EXPIRED
            count += 1

        if count > 0:
            await self.session.commit()

        return count
    
    async def get_expiring_subscriptions(self, days_ahead: int = 7) -> List[MerchantSubscription]:
        """Get subscriptions expiring within specified days."""
        today = date.today()
        expiry_date = today + timedelta(days=days_ahead)
        statement = select(MerchantSubscription).where(
            and_(
                MerchantSubscription.status == SubscriptionStatus.ACTIVE,
                MerchantSubscription.end_date <= expiry_date,
                MerchantSubscription.end_date >= today
            )
        )
        result = await self.session.execute(statement)
        return list(result.scalars().all())
    
    async def cancel_subscription(self, subscription_id: UUID) -> Optional[MerchantSubscription]:
        """Cancel a subscription."""
        subscription = await self.session.get(MerchantSubscription, subscription_id)
        if not subscription:
            return None
        
        subscription.status = SubscriptionStatus.CANCELLED
        await self.session.commit()
        await self.session.refresh(subscription)
        return subscription
    
    # Usage calculation methods
    async def count_merchant_services(self, merchant_id: UUID) -> int:
        """Count active services for a merchant."""
        statement = select(func.count(Service.id)).where(
            and_(
                Service.merchant_id == merchant_id,
                Service.is_active == True
            )
        )
        result = await self.session.execute(statement)
        return result.scalar_one() or 0
    
    async def count_service_images(self, service_id: str) -> int:
        """Count images for a service."""
        statement = select(func.count(Image.id)).where(
            and_(
                Image.related_id == str(service_id),
                Image.image_type == ImageType.SERVICE_IMAGE,
                Image.is_active == True
            )
        )
        result = await self.session.execute(statement)
        return result.scalar_one() or 0
    
    async def count_merchant_phone_numbers(self, merchant_id: UUID) -> int:
        """Count phone numbers for a merchant."""
        statement = select(func.count(MerchantContact.id)).where(
            and_(
                MerchantContact.merchant_id == merchant_id,
                MerchantContact.contact_type == ContactType.PHONE,
                MerchantContact.is_active == True
            )
        )
        result = await self.session.execute(statement)
        return result.scalar_one() or 0
    
    async def count_merchant_gallery_images(self, merchant_id: UUID) -> int:
        """Count gallery images for a merchant."""
        statement = select(func.count(Image.id)).where(
            and_(
                Image.related_id == merchant_id,
                Image.image_type == ImageType.MERCHANT_GALLERY,
                Image.is_active == True
            )
        )
        result = await self.session.execute(statement)
        return result.scalar_one() or 0
    
    async def count_merchant_social_accounts(self, merchant_id: UUID) -> int:
        """Count social media accounts for a merchant."""
        statement = select(func.count(MerchantContact.id)).where(
            and_(
                MerchantContact.merchant_id == merchant_id,
                MerchantContact.contact_type == ContactType.SOCIAL_MEDIA,
                MerchantContact.is_active == True
            )
        )
        result = await self.session.execute(statement)
        return result.scalar_one() or 0
    
    async def count_monthly_featured_allocations_used(
        self, 
        merchant_id: UUID, 
        year: int, 
        month: int
    ) -> int:
        """Count monthly featured allocations used in a specific month."""
        # Get featured services that started in the given month/year
        # and are of type MONTHLY_ALLOCATION
        start_of_month = datetime(year, month, 1)
        if month == 12:
            end_of_month = datetime(year + 1, 1, 1)
        else:
            end_of_month = datetime(year, month + 1, 1)
        
        statement = select(func.count(FeaturedService.id)).where(
            and_(
                FeaturedService.merchant_id == merchant_id,
                FeaturedService.feature_type == FeatureType.MONTHLY_ALLOCATION,
                FeaturedService.start_date >= start_of_month,
                FeaturedService.start_date < end_of_month
            )
        )
        result = await self.session.execute(statement)
        return result.scalar_one() or 0
    
    # Analytics and reporting
    async def get_revenue_by_period(
        self, 
        start_date: date, 
        end_date: date,
        payment_type: Optional[PaymentType] = None
    ) -> float:
        """Get total revenue for a period."""
        start_datetime = datetime.combine(start_date, datetime.min.time())
        end_datetime = datetime.combine(end_date + timedelta(days=1), datetime.min.time())
        
        statement = select(Payment).where(
            and_(
                Payment.status == PaymentStatus.COMPLETED,
                Payment.completed_at >= start_datetime,
                Payment.completed_at < end_datetime
            )
        )
        
        if payment_type:
            statement = statement.where(Payment.payment_type == payment_type)

        result = await self.session.execute(statement)
        payments = result.scalars().all()
        return sum(payment.amount for payment in payments)
    
    async def get_payment_stats(self) -> dict:
        """Get payment statistics."""
        statement = select(Payment)
        result = await self.session.execute(statement)
        total_payments = result.scalars().all()
        total_list = list(total_payments)

        stats = {
            "total_payments": len(total_list),
            "completed_payments": len([p for p in total_list if p.status == PaymentStatus.COMPLETED]),
            "pending_payments": len([p for p in total_list if p.status == PaymentStatus.PENDING]),
            "failed_payments": len([p for p in total_list if p.status == PaymentStatus.FAILED]),
            "total_revenue": sum(p.amount for p in total_list if p.status == PaymentStatus.COMPLETED),
            "tariff_payments": len([p for p in total_list if p.payment_type == PaymentType.TARIFF_SUBSCRIPTION]),
            "featured_payments": len([p for p in total_list if p.payment_type == PaymentType.FEATURED_SERVICE])
        }

        return stats
    
    async def get_subscription_stats(self) -> dict:
        """Get subscription statistics."""
        statement = select(MerchantSubscription)
        result = await self.session.execute(statement)
        all_subscriptions = result.scalars().all()
        subscriptions_list = list(all_subscriptions)

        stats = {
            "total_subscriptions": len(subscriptions_list),
            "active_subscriptions": len([s for s in subscriptions_list if s.status == SubscriptionStatus.ACTIVE]),
            "expired_subscriptions": len([s for s in subscriptions_list if s.status == SubscriptionStatus.EXPIRED]),
            "cancelled_subscriptions": len([s for s in subscriptions_list if s.status == SubscriptionStatus.CANCELLED])
        }

        return stats
