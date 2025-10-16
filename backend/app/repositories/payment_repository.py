from datetime import date, datetime, timedelta
from typing import List, Optional
from uuid import UUID
from sqlmodel import Session, select

from app.models.payment import (
    TariffPlan, Payment, MerchantSubscription,
    PaymentType, PaymentMethod, PaymentStatus, SubscriptionStatus
)
from app.models.user import Merchant


class PaymentRepository:
    """Repository for payment-related database operations."""
    
    def __init__(self, session: Session):
        self.session = session
    
    # TariffPlan operations
    def get_active_tariff_plans(self) -> List[TariffPlan]:
        """Get all active tariff plans."""
        statement = select(TariffPlan).where(TariffPlan.is_active == True)
        return list(self.session.exec(statement).scalars().all())
    
    def get_tariff_plan_by_id(self, plan_id: UUID) -> Optional[TariffPlan]:
        """Get tariff plan by ID."""
        return self.session.get(TariffPlan, plan_id)
    
    def create_tariff_plan(self, tariff_plan: TariffPlan) -> TariffPlan:
        """Create a new tariff plan."""
        self.session.add(tariff_plan)
        self.session.commit()
        self.session.refresh(tariff_plan)
        return tariff_plan
    
    def update_tariff_plan(self, tariff_plan: TariffPlan) -> TariffPlan:
        """Update tariff plan."""
        self.session.add(tariff_plan)
        self.session.commit()
        self.session.refresh(tariff_plan)
        return tariff_plan
    
    # Payment operations
    def create_payment(self, payment: Payment) -> Payment:
        """Create a new payment record."""
        self.session.add(payment)
        self.session.commit()
        self.session.refresh(payment)
        return payment
    
    def get_payment_by_id(self, payment_id: UUID) -> Optional[Payment]:
        """Get payment by ID."""
        return self.session.get(Payment, payment_id)
    
    def get_payment_by_transaction_id(self, transaction_id: str) -> Optional[Payment]:
        """Get payment by transaction ID."""
        statement = select(Payment).where(Payment.transaction_id == transaction_id)
        result = self.session.exec(statement)
        return result.scalars().first()
    
    def get_payments_by_user_id(
        self, 
        user_id: UUID, 
        payment_type: Optional[PaymentType] = None,
        status: Optional[PaymentStatus] = None
    ) -> List[Payment]:
        """Get payments by user ID with optional filters."""
        statement = select(Payment).where(Payment.user_id == user_id)
        
        if payment_type:
            statement = statement.where(Payment.payment_type == payment_type)
        
        if status:
            statement = statement.where(Payment.status == status)
        
        return list(self.session.exec(statement).scalars().all())
    
    def update_payment_status(
        self, 
        payment_id: UUID, 
        status: PaymentStatus,
        completed_at: Optional[datetime] = None,
        webhook_data: Optional[dict] = None
    ) -> Optional[Payment]:
        """Update payment status."""
        payment = self.session.get(Payment, payment_id)
        if not payment:
            return None
        
        payment.status = status
        if completed_at:
            payment.completed_at = completed_at
        if webhook_data:
            payment.webhook_data = webhook_data
        
        self.session.commit()
        self.session.refresh(payment)
        return payment
    
    def get_pending_payments(self, older_than_minutes: int = 30) -> List[Payment]:
        """Get pending payments older than specified minutes."""
        cutoff_time = datetime.utcnow() - timedelta(minutes=older_than_minutes)
        statement = select(Payment).where(
            Payment.status == PaymentStatus.PENDING,
            Payment.created_at < cutoff_time
        )
        return list(self.session.exec(statement).scalars().all())
    
    # MerchantSubscription operations
    def create_subscription(self, subscription: MerchantSubscription) -> MerchantSubscription:
        """Create a new merchant subscription."""
        self.session.add(subscription)
        self.session.commit()
        self.session.refresh(subscription)
        return subscription
    
    def get_merchant_active_subscription(self, merchant_id: UUID) -> Optional[MerchantSubscription]:
        """Get merchant's active subscription."""
        statement = select(MerchantSubscription).where(
            MerchantSubscription.merchant_id == merchant_id,
            MerchantSubscription.status == SubscriptionStatus.ACTIVE
        )
        result = self.session.exec(statement)
        return result.scalars().first()
    
    def get_merchant_subscriptions(
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
        
        return list(self.session.exec(statement).scalars().all())
    
    def expire_subscriptions_by_date(self, end_date: date) -> int:
        """Expire subscriptions that have passed the given date."""
        statement = select(MerchantSubscription).where(
            MerchantSubscription.status == SubscriptionStatus.ACTIVE,
            MerchantSubscription.end_date < end_date
        )
        
        subscriptions = self.session.exec(statement).scalars().all()
        count = 0

        for subscription in subscriptions:
            subscription.status = SubscriptionStatus.EXPIRED
            count += 1

        if count > 0:
            self.session.commit()

        return count
    
    def get_expiring_subscriptions(self, days_ahead: int = 7) -> List[MerchantSubscription]:
        """Get subscriptions expiring within specified days."""
        expiry_date = date.today() + timedelta(days=days_ahead)
        statement = select(MerchantSubscription).where(
            MerchantSubscription.status == SubscriptionStatus.ACTIVE,
            MerchantSubscription.end_date <= expiry_date,
            MerchantSubscription.end_date >= date.today()
        )
        return list(self.session.exec(statement).scalars().all())
    
    def cancel_subscription(self, subscription_id: UUID) -> Optional[MerchantSubscription]:
        """Cancel a subscription."""
        subscription = self.session.get(MerchantSubscription, subscription_id)
        if not subscription:
            return None
        
        subscription.status = SubscriptionStatus.CANCELLED
        self.session.commit()
        self.session.refresh(subscription)
        return subscription
    
    # Analytics and reporting
    def get_revenue_by_period(
        self, 
        start_date: date, 
        end_date: date,
        payment_type: Optional[PaymentType] = None
    ) -> float:
        """Get total revenue for a period."""
        statement = select(Payment).where(
            Payment.status == PaymentStatus.COMPLETED,
            Payment.completed_at >= datetime.combine(start_date, datetime.min.time()),
            Payment.completed_at < datetime.combine(end_date + timedelta(days=1), datetime.min.time())
        )
        
        if payment_type:
            statement = statement.where(Payment.payment_type == payment_type)

        payments = self.session.exec(statement).scalars().all()
        return sum(payment.amount for payment in payments)
    
    def get_payment_stats(self) -> dict:
        """Get payment statistics."""
        total_payments = self.session.exec(select(Payment)).scalars().all()

        stats = {
            "total_payments": len(total_payments),
            "completed_payments": len([p for p in total_payments if p.status == PaymentStatus.COMPLETED]),
            "pending_payments": len([p for p in total_payments if p.status == PaymentStatus.PENDING]),
            "failed_payments": len([p for p in total_payments if p.status == PaymentStatus.FAILED]),
            "total_revenue": sum(p.amount for p in total_payments if p.status == PaymentStatus.COMPLETED),
            "tariff_payments": len([p for p in total_payments if p.payment_type == PaymentType.TARIFF_SUBSCRIPTION]),
            "featured_payments": len([p for p in total_payments if p.payment_type == PaymentType.FEATURED_SERVICE])
        }

        return stats
    
    def get_subscription_stats(self) -> dict:
        """Get subscription statistics."""
        all_subscriptions = self.session.exec(select(MerchantSubscription)).scalars().all()

        stats = {
            "total_subscriptions": len(all_subscriptions),
            "active_subscriptions": len([s for s in all_subscriptions if s.status == SubscriptionStatus.ACTIVE]),
            "expired_subscriptions": len([s for s in all_subscriptions if s.status == SubscriptionStatus.EXPIRED]),
            "cancelled_subscriptions": len([s for s in all_subscriptions if s.status == SubscriptionStatus.CANCELLED])
        }

        return stats