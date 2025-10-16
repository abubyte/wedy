from datetime import datetime, date, timedelta
from typing import List, Optional, Dict, Any
from uuid import UUID
from sqlmodel import Session, select
from fastapi import HTTPException

from app.models.payment import (
    TariffPlan, Payment, MerchantSubscription,
    PaymentType, PaymentMethod, PaymentStatus, SubscriptionStatus
)
from app.models.user import User, Merchant
from app.models.service import Service, FeaturedService, FeatureType
from app.schemas.payment import (
    TariffPaymentRequest, FeaturedServicePaymentRequest,
    PaymentResponse, TariffPlanResponse, SubscriptionResponse
)


class PaymentError(Exception):
    """Payment-related error."""
    pass


class SubscriptionError(Exception):
    """Subscription-related error."""
    pass


class PaymentService:
    """Service for handling payments and subscriptions."""
    
    def __init__(
        self,
        session: Session,
        payment_providers: Dict[str, Any],
        sms_service: Any
    ):
        self.session = session
        self.payment_providers = payment_providers
        self.sms_service = sms_service
    
    async def get_active_tariff_plans(self) -> List[TariffPlan]:
        """Get all active tariff plans."""
        statement = select(TariffPlan).where(TariffPlan.is_active == True)
        result = self.session.exec(statement)
        return list(result.scalars().all())
    
    def _calculate_subscription_price(self, base_price: float, duration_months: int) -> float:
        """Calculate subscription price with duration discounts."""
        total_base = base_price * duration_months
        
        # Apply discounts based on duration
        if duration_months >= 12:  # 1 year: 30% discount
            discount = 0.30
        elif duration_months >= 6:  # 6 months: 20% discount
            discount = 0.20
        elif duration_months >= 3:  # 3 months: 10% discount
            discount = 0.10
        else:  # 1 month: no discount
            discount = 0.0
        
        return total_base * (1 - discount)
    
    def _calculate_featured_service_price(self, base_daily_price: float, duration_days: int) -> float:
        """Calculate featured service price with duration discounts."""
        total_base = base_daily_price * duration_days
        
        # Apply discounts based on duration
        if duration_days >= 91:  # 91-365 days: 30% discount
            discount = 0.30
        elif duration_days >= 21:  # 21-90 days: 20% discount
            discount = 0.20
        elif duration_days >= 8:  # 8-20 days: 10% discount
            discount = 0.10
        else:  # 1-7 days: no discount
            discount = 0.0
        
        return total_base * (1 - discount)
    
    async def create_tariff_payment(
        self,
        user_id: UUID,
        request: TariffPaymentRequest
    ) -> PaymentResponse:
        """Create a tariff subscription payment."""
        try:
            # Get tariff plan
            plan = self.session.get(TariffPlan, request.tariff_plan_id)
            if not plan or not plan.is_active:
                raise PaymentError("Tariff plan not found or inactive")
            
            # Calculate final amount with discounts
            final_amount = self._calculate_subscription_price(
                plan.price_per_month, request.duration_months
            )
            
            # Create payment record
            payment = Payment(
                user_id=user_id,
                amount=final_amount,
                payment_type=PaymentType.TARIFF_SUBSCRIPTION,
                payment_method=request.payment_method,
                status=PaymentStatus.PENDING
            )
            
            # Generate payment with provider
            provider = self.payment_providers.get(request.payment_method.value)
            if not provider:
                raise PaymentError(f"Payment provider {request.payment_method} not available")
            
            try:
                payment_data = provider.create_payment({
                    'amount': final_amount,
                    'description': f'Tariff subscription: {plan.name} ({request.duration_months} months)',
                    'user_id': str(user_id),
                    'tariff_plan_id': str(request.tariff_plan_id),
                    'duration_months': request.duration_months
                })
                
                payment.payment_url = payment_data['payment_url']
                payment.transaction_id = payment_data['transaction_id']
                
            except Exception as e:
                raise PaymentError(f"Failed to create payment with provider: {str(e)}")
            
            # Save to database
            self.session.add(payment)
            self.session.commit()
            self.session.refresh(payment)
            
            return PaymentResponse.from_orm(payment)
            
        except Exception as e:
            self.session.rollback()
            if isinstance(e, PaymentError):
                raise
            raise PaymentError(f"Failed to create payment: {str(e)}")
    
    async def create_featured_service_payment(
        self,
        user_id: UUID,
        request: FeaturedServicePaymentRequest
    ) -> PaymentResponse:
        """Create a featured service payment."""
        try:
            # Verify service belongs to user's merchant
            result = self.session.exec(
                select(Merchant).where(Merchant.user_id == user_id)
            )
            merchant = result.scalars().first()
            if not merchant:
                raise PaymentError("User is not a merchant")
            
            service = self.session.get(Service, request.service_id)
            if not service or service.merchant_id != merchant.id:
                raise PaymentError("Service not found or not owned by merchant")
            
            # Calculate price (base daily price would be configurable)
            base_daily_price = 1500.0  # 1500 UZS per day (configurable)
            final_amount = self._calculate_featured_service_price(
                base_daily_price, request.duration_days
            )
            
            # Create payment record
            payment = Payment(
                user_id=user_id,
                amount=final_amount,
                payment_type=PaymentType.FEATURED_SERVICE,
                payment_method=request.payment_method,
                status=PaymentStatus.PENDING
            )
            
            # Generate payment with provider
            provider = self.payment_providers.get(request.payment_method.value)
            if not provider:
                raise PaymentError(f"Payment provider {request.payment_method} not available")
            
            try:
                payment_data = provider.create_payment({
                    'amount': final_amount,
                    'description': f'Featured service: {service.name} ({request.duration_days} days)',
                    'user_id': str(user_id),
                    'service_id': str(request.service_id),
                    'duration_days': request.duration_days
                })
                
                payment.payment_url = payment_data['payment_url']
                payment.transaction_id = payment_data['transaction_id']
                
            except Exception as e:
                raise PaymentError(f"Failed to create payment with provider: {str(e)}")
            
            # Save to database
            self.session.add(payment)
            self.session.commit()
            self.session.refresh(payment)
            
            return PaymentResponse.from_orm(payment)
            
        except Exception as e:
            self.session.rollback()
            if isinstance(e, PaymentError):
                raise
            raise PaymentError(f"Failed to create featured service payment: {str(e)}")
    
    async def process_payment_webhook(
        self,
        payment_method: PaymentMethod,
        webhook_data: Dict[str, Any]
    ) -> bool:
        """Process payment webhook from provider."""
        try:
            # Extract transaction ID from webhook data
            transaction_id = self._extract_transaction_id(payment_method, webhook_data)
            if not transaction_id:
                raise PaymentError("Transaction ID not found in webhook data")
            
            # Find payment by transaction ID
            result = self.session.exec(
                select(Payment).where(Payment.transaction_id == transaction_id)
            )
            payment = result.scalars().first()

            if not payment:
                raise PaymentError(f"Payment not found for transaction ID: {transaction_id}")
            
            # Verify payment status from webhook
            is_completed = self._is_payment_completed(payment_method, webhook_data)
            
            if is_completed:
                # Update payment status
                payment.status = PaymentStatus.COMPLETED
                payment.completed_at = datetime.utcnow()
                payment.webhook_data = webhook_data
                
                # Process payment based on type
                if payment.payment_type == PaymentType.TARIFF_SUBSCRIPTION:
                    await self._process_tariff_subscription_payment(payment, webhook_data)
                elif payment.payment_type == PaymentType.FEATURED_SERVICE:
                    await self._process_featured_service_payment(payment, webhook_data)
                
                self.session.commit()
                return True
            else:
                # Handle failed payment
                payment.status = PaymentStatus.FAILED
                payment.webhook_data = webhook_data
                self.session.commit()
                return False
                
        except Exception as e:
            self.session.rollback()
            raise PaymentError(f"Failed to process webhook: {str(e)}")
    
    def _extract_transaction_id(self, method: PaymentMethod, webhook_data: Dict[str, Any]) -> Optional[str]:
        """Extract transaction ID from webhook data based on payment method."""
        if method == PaymentMethod.PAYME:
            return webhook_data.get('params', {}).get('id')
        elif method == PaymentMethod.CLICK:
            return webhook_data.get('merchant_trans_id')
        elif method == PaymentMethod.UZUMBANK:
            return webhook_data.get('transaction_id')
        return None
    
    def _is_payment_completed(self, method: PaymentMethod, webhook_data: Dict[str, Any]) -> bool:
        """Check if payment is completed based on webhook data."""
        if method == PaymentMethod.PAYME:
            state = webhook_data.get('params', {}).get('state')
            return state == 2  # Completed state
        elif method == PaymentMethod.CLICK:
            return webhook_data.get('action') == 1  # Success
        elif method == PaymentMethod.UZUMBANK:
            return webhook_data.get('status') == 'success'
        return False
    
    async def _process_tariff_subscription_payment(
        self,
        payment: Payment,
        webhook_data: Dict[str, Any]
    ):
        """Process completed tariff subscription payment."""
        # Extract duration from webhook data or payment metadata
        duration_months = webhook_data.get('duration_months', 1)  # Default to 1 month
        
        # Find merchant
        result = self.session.exec(
            select(Merchant).where(Merchant.user_id == payment.user_id)
        )
        merchant = result.scalars().first()

        if not merchant:
            raise PaymentError("Merchant not found for payment")
        
        # Find tariff plan (stored in webhook data or derive from payment amount)
        tariff_plan_id = webhook_data.get('tariff_plan_id')
        if tariff_plan_id:
            plan = self.session.get(TariffPlan, tariff_plan_id)
        else:
            # Fallback: find plan by reverse calculating from amount
            # This is a simplified approach - in production, store plan ID in payment
            plans = self.session.exec(select(TariffPlan).where(TariffPlan.is_active == True)).scalars().all()
            plan = None
            for p in plans:
                if abs(self._calculate_subscription_price(p.price_per_month, duration_months) - payment.amount) < 1.0:
                    plan = p
                    break
        
        if not plan:
            raise PaymentError("Cannot determine tariff plan for payment")
        
        # Create subscription
        await self._activate_subscription(
            payment=payment,
            merchant_id=merchant.id,
            tariff_plan_id=plan.id,
            duration_months=duration_months
        )
    
    async def _process_featured_service_payment(
        self,
        payment: Payment,
        webhook_data: Dict[str, Any]
    ):
        """Process completed featured service payment."""
        service_id = webhook_data.get('service_id')
        duration_days = webhook_data.get('duration_days', 7)  # Default to 7 days
        
        if not service_id:
            raise PaymentError("Service ID not found in webhook data")
        
        service = self.session.get(Service, service_id)
        if not service:
            raise PaymentError("Service not found")
        
        # Create featured service record
        featured_service = FeaturedService(
            service_id=service.id,
            merchant_id=service.merchant_id,
            payment_id=payment.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=duration_days),
            days_duration=duration_days,
            amount_paid=payment.amount,
            feature_type=FeatureType.PAID_FEATURE,
            is_active=True
        )
        
        self.session.add(featured_service)
    
    async def _activate_subscription(
        self,
        payment: Payment,
        merchant_id: UUID,
        tariff_plan_id: UUID,
        duration_months: int
    ) -> MerchantSubscription:
        """Activate merchant subscription."""
        # Expire any existing active subscriptions
        existing_subscriptions = self.session.exec(
            select(MerchantSubscription).where(
                MerchantSubscription.merchant_id == merchant_id,
                MerchantSubscription.status == SubscriptionStatus.ACTIVE
            )
        ).scalars().all()
        
        for sub in existing_subscriptions:
            sub.status = SubscriptionStatus.CANCELLED
        
        # Create new subscription
        subscription = MerchantSubscription(
            merchant_id=merchant_id,
            tariff_plan_id=tariff_plan_id,
            payment_id=payment.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=duration_months * 30),  # Approximate month
            status=SubscriptionStatus.ACTIVE
        )
        
        self.session.add(subscription)
        return subscription
    
    async def get_merchant_subscription(self, user_id: UUID) -> Optional[SubscriptionResponse]:
        """Get merchant's current subscription."""
        # Find merchant
        result = self.session.exec(
            select(Merchant).where(Merchant.user_id == user_id)
        )
        merchant = result.scalars().first()

        if not merchant:
            return None
        
        # Find active subscription
        result = self.session.exec(
            select(MerchantSubscription)
            .join(TariffPlan)
            .where(
                MerchantSubscription.merchant_id == merchant.id,
                MerchantSubscription.status == SubscriptionStatus.ACTIVE
            )
        )
        subscription = result.scalars().first()
        
        if not subscription:
            return None
        
        # Load relationships
        self.session.refresh(subscription)
        return SubscriptionResponse.from_orm(subscription)
    
    async def check_subscription_limit(
        self,
        user_id: UUID,
        limit_type: str,
        current_count: int
    ) -> bool:
        """Check if merchant can perform action within subscription limits."""
        subscription_response = await self.get_merchant_subscription(user_id)
        if not subscription_response:
            return False  # No active subscription
        
        plan = subscription_response.tariff_plan
        
        # Check specific limits
        if limit_type == "services":
            return current_count < plan.max_services
        elif limit_type == "images_per_service":
            return current_count < plan.max_images_per_service
        elif limit_type == "phone_numbers":
            return current_count < plan.max_phone_numbers
        elif limit_type == "gallery_images":
            return current_count < plan.max_gallery_images
        elif limit_type == "social_accounts":
            return current_count < plan.max_social_accounts
        elif limit_type == "website" and not plan.allow_website:
            return False
        elif limit_type == "cover_image" and not plan.allow_cover_image:
            return False
        
        return True
    
    async def expire_old_subscriptions(self) -> int:
        """Expire subscriptions that have passed their end date."""
        expired_subscriptions = self.session.exec(
            select(MerchantSubscription).where(
                MerchantSubscription.status == SubscriptionStatus.ACTIVE,
                MerchantSubscription.end_date < date.today()
            )
        ).scalars().all()
        
        count = 0
        for subscription in expired_subscriptions:
            subscription.status = SubscriptionStatus.EXPIRED
            count += 1
        
        if count > 0:
            self.session.commit()
        
        return count