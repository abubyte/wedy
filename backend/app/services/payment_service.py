from datetime import datetime, date, timedelta
from typing import List, Optional, Dict, Any
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from dateutil.relativedelta import relativedelta

from app.models import (
    TariffPlan, Payment, MerchantSubscription,
    PaymentType, PaymentMethod, PaymentStatus,
    SubscriptionStatus, User, Merchant, Service,
    FeaturedService, FeatureType,
)
from app.schemas.payment_schema import (
    TariffPaymentRequest, FeaturedServicePaymentRequest,
    PaymentResponse, TariffPlanResponse, SubscriptionResponse
)
from app.repositories.payment_repository import PaymentRepository
from app.core.exceptions import PaymentError
from app.core.config import get_settings


class SubscriptionError(Exception):
    """Subscription-related error."""
    pass


class PaymentService:
    """Service for handling payments and subscriptions."""
    
    def __init__(
        self,
        session: AsyncSession,
        payment_providers: Dict[str, Any],
        sms_service: Any
    ):
        self.session = session
        self.payment_providers = payment_providers
        self.sms_service = sms_service
        self.payment_repo = PaymentRepository(session)
    
    async def get_active_tariff_plans(self) -> List[TariffPlan]:
        """Get all active tariff plans."""
        return await self.payment_repo.get_active_tariff_plans()
    
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
        elif duration_days >= 31:  # 31-90 days: 20% discount
            discount = 0.20
        elif duration_days >= 8:  # 8-30 days: 10% discount
            discount = 0.10
        else:  # 1-7 days: no discount
            discount = 0.0
        
        return total_base * (1 - discount)
    
    async def create_tariff_payment(
        self,
        user_id: str,
        request: TariffPaymentRequest
    ) -> PaymentResponse:
        """Create a tariff subscription payment."""
        try:
            # Get tariff plan
            plan = await self.payment_repo.get_tariff_plan_by_id(request.tariff_plan_id)
            if not plan or not plan.is_active:
                raise PaymentError("Tariff plan not found or inactive")
            
            # Calculate final amount with discounts
            final_amount = self._calculate_subscription_price(
                plan.price_per_month, request.duration_months
            )
            
            # Create payment record with metadata
            payment = Payment(
                user_id=user_id,
                amount=final_amount,
                payment_type=PaymentType.TARIFF_SUBSCRIPTION,
                payment_method=request.payment_method,
                status=PaymentStatus.PENDING,
                payment_metadata={
                    'tariff_plan_id': str(request.tariff_plan_id),
                    'duration_months': request.duration_months,
                    'plan_name': plan.name
                }
            )
            
            # Generate payment with provider
            provider = self.payment_providers.get(request.payment_method.value)
            if not provider:
                raise PaymentError(
                    f"Payment provider {request.payment_method} is not available. "
                    f"Please configure the required credentials in your environment variables."
                )
            
            try:
                # Get user to retrieve phone number
                user_stmt = select(User).where(User.id == user_id)
                user_result = await self.session.execute(user_stmt)
                user = user_result.scalar_one_or_none()
                
                if not user:
                    raise PaymentError("User not found")
                
                # Pass payment.id (UUID generated on object creation) to provider
                settings = get_settings()
                payment_data = await provider.create_payment({
                    'payment_id': str(payment.id),  # Payment UUID for account_id
                    'payment_type': PaymentType.TARIFF_SUBSCRIPTION.value,  # Payment type for terminal selection
                    'amount': final_amount,
                    'description': f'Tariff subscription: {plan.name} ({request.duration_months} months)',
                    'user_id': str(user_id),
                    'phone_number': user.phone_number,  # User's 9-digit phone number
                    'tariff_id': str(request.tariff_plan_id),  # Tariff plan ID for Payme requisite
                    'tariff_plan_id': str(request.tariff_plan_id),  # Keep for backward compatibility
                    'month_count': request.duration_months,  # Duration in months for Payme requisite
                    'duration_months': request.duration_months,  # Keep for backward compatibility
                    'return_url': f"{settings.BASE_URL}/payment/success"
                })
                
                payment.payment_url = payment_data['payment_url']
                payment.transaction_id = payment_data['transaction_id']
                
            except Exception as e:
                error_msg = str(e) if str(e) else f"{type(e).__name__}: {repr(e)}"
                raise PaymentError(f"Failed to create payment with provider: {error_msg}")
            
            # Save to database
            payment = await self.payment_repo.create_payment(payment)
            
            return PaymentResponse.model_validate(payment)
            
        except Exception as e:
            await self.session.rollback()
            if isinstance(e, PaymentError):
                raise
            import traceback
            error_details = traceback.format_exc()
            error_msg = str(e) if str(e) else f"{type(e).__name__}: {repr(e)}"
            print(f"Payment creation error: {error_msg}")
            print(f"Error type: {type(e).__name__}")
            print(f"Traceback: {error_details}")
            raise PaymentError(f"Failed to create payment: {error_msg}")
    
    async def create_featured_service_payment(
        self,
        user_id: str,
        request: FeaturedServicePaymentRequest
    ) -> PaymentResponse:
        """Create a featured service payment."""
        try:
            # Verify service belongs to user's merchant
            merchant_stmt = select(Merchant).where(Merchant.user_id == user_id)
            merchant_result = await self.session.execute(merchant_stmt)
            merchant = merchant_result.scalar_one_or_none()
            
            if not merchant:
                raise PaymentError("User is not a merchant")
            
            service_stmt = select(Service).where(Service.id == request.service_id)
            service_result = await self.session.execute(service_stmt)
            service = service_result.scalar_one_or_none()
            
            if not service or service.merchant_id != merchant.id:
                raise PaymentError("Service not found or not owned by merchant")
            
            # Calculate price (base daily price would be configurable)
            base_daily_price = 20000.0  # 20000 UZS per day (configurable)
            final_amount = self._calculate_featured_service_price(
                base_daily_price, request.duration_days
            )
            
            # Create payment record with metadata
            payment = Payment(
                user_id=user_id,
                amount=final_amount,
                payment_type=PaymentType.FEATURED_SERVICE,
                payment_method=request.payment_method,
                status=PaymentStatus.PENDING,
                payment_metadata={
                    'service_id': str(request.service_id),
                    'duration_days': request.duration_days,
                    'service_name': service.name
                }
            )
            
            # Generate payment with provider
            provider = self.payment_providers.get(request.payment_method.value)
            if not provider:
                raise PaymentError(
                    f"Payment provider {request.payment_method} is not available. "
                    f"Please configure the required credentials in your environment variables."
                )
            
            try:
                # Get user to retrieve phone number
                user_stmt = select(User).where(User.id == user_id)
                user_result = await self.session.execute(user_stmt)
                user = user_result.scalar_one_or_none()
                
                if not user:
                    raise PaymentError("User not found")
                
                # Pass payment.id (UUID generated on object creation) to provider
                settings = get_settings()
                payment_data = await provider.create_payment({
                    'payment_id': str(payment.id),  # Payment UUID for account_id
                    'payment_type': PaymentType.FEATURED_SERVICE.value,  # Payment type for terminal selection
                    'amount': final_amount,
                    'description': f'Featured service: {service.name} ({request.duration_days} days)',
                    'user_id': str(user_id),
                    'phone_number': user.phone_number,  # User's 9-digit phone number
                    'service_id': str(request.service_id),  # Service ID (9-digit numeric)
                    'days_count': request.duration_days,  # Duration in days
                    'duration_days': request.duration_days,  # Keep for backward compatibility
                    'return_url': f"{settings.BASE_URL}/payment/success"
                })
                
                payment.payment_url = payment_data['payment_url']
                payment.transaction_id = payment_data['transaction_id']
                
            except Exception as e:
                error_msg = str(e) if str(e) else f"{type(e).__name__}: {repr(e)}"
                raise PaymentError(f"Failed to create payment with provider: {error_msg}")
            
            # Save to database
            payment = await self.payment_repo.create_payment(payment)
            
            return PaymentResponse.model_validate(payment)
            
        except Exception as e:
            await self.session.rollback()
            if isinstance(e, PaymentError):
                raise
            import traceback
            error_details = traceback.format_exc()
            error_msg = str(e) if str(e) else f"{type(e).__name__}: {repr(e)}"
            print(f"Featured service payment creation error: {error_msg}")
            print(f"Error type: {type(e).__name__}")
            print(f"Traceback: {error_details}")
            raise PaymentError(f"Failed to create featured service payment: {error_msg}")
    
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
            payment = await self.payment_repo.get_payment_by_transaction_id(transaction_id)

            if not payment:
                raise PaymentError(f"Payment not found for transaction ID: {transaction_id}")
            
            # Verify payment status from webhook
            is_completed = self._is_payment_completed(payment_method, webhook_data)
            
            if is_completed:
                # Update payment status
                await self.payment_repo.update_payment_status(
                    payment.id,
                    PaymentStatus.COMPLETED,
                    completed_at=datetime.now(),
                    webhook_data=webhook_data
                )
                
                # Refresh payment to get updated version
                payment = await self.payment_repo.get_payment_by_id(payment.id)
                
                # Process payment based on type
                if payment.payment_type == PaymentType.TARIFF_SUBSCRIPTION:
                    await self._process_tariff_subscription_payment(payment, webhook_data)
                elif payment.payment_type == PaymentType.FEATURED_SERVICE:
                    await self._process_featured_service_payment(payment, webhook_data)
                
                await self.session.commit()
                return True
            else:
                # Handle failed payment
                await self.payment_repo.update_payment_status(
                    payment.id,
                    PaymentStatus.FAILED,
                    webhook_data=webhook_data
                )
                await self.session.commit()
                return False
                
        except Exception as e:
            await self.session.rollback()
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
        # Extract duration and tariff_plan_id from payment metadata (preferred) or webhook data
        payment_metadata = payment.payment_metadata or {}
        duration_months = payment_metadata.get('duration_months') or webhook_data.get('duration_months', 1)
        tariff_plan_id_str = payment_metadata.get('tariff_plan_id') or webhook_data.get('tariff_plan_id')
        
        # Find merchant
        merchant_stmt = select(Merchant).where(Merchant.user_id == payment.user_id)
        merchant_result = await self.session.execute(merchant_stmt)
        merchant = merchant_result.scalar_one_or_none()

        if not merchant:
            raise PaymentError("Merchant not found for payment")
        
        # Find tariff plan
        if tariff_plan_id_str:
            tariff_plan_id = UUID(tariff_plan_id_str)
            plan = await self.payment_repo.get_tariff_plan_by_id(tariff_plan_id)
        else:
            # Fallback: find plan by reverse calculating from amount
            plans = await self.payment_repo.get_active_tariff_plans()
            plan = None
            for p in plans:
                calculated_amount = self._calculate_subscription_price(p.price_per_month, duration_months)
                if abs(calculated_amount - payment.amount) < 1.0:
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
        # Extract from payment metadata (preferred) or webhook data
        payment_metadata = payment.payment_metadata or {}
        service_id_str = payment_metadata.get('service_id') or webhook_data.get('service_id')
        duration_days = payment_metadata.get('duration_days') or webhook_data.get('duration_days', 7)
        
        if not service_id_str:
            raise PaymentError("Service ID not found in payment metadata or webhook data")
        
        service_id = service_id_str  # Already a string, no conversion needed
        service_stmt = select(Service).where(Service.id == service_id)
        service_result = await self.session.execute(service_stmt)
        service = service_result.scalar_one_or_none()
        
        if not service:
            raise PaymentError("Service not found")
        
        # Create featured service record
        featured_service = FeaturedService(
            service_id=service.id,
            merchant_id=service.merchant_id,
            payment_id=payment.id,
            start_date=datetime.now(),
            end_date=datetime.now() + timedelta(days=duration_days),
            days_duration=duration_days,
            amount_paid=payment.amount,
            feature_type=FeatureType.PAID_FEATURE,
            is_active=True
        )
        
        self.session.add(featured_service)
        await self.session.flush()
    
    async def _activate_subscription(
        self,
        payment: Payment,
        merchant_id: UUID,
        tariff_plan_id: UUID,
        duration_months: int
    ) -> MerchantSubscription:
        """Activate merchant subscription with proper calendar month calculation."""
        # Expire any existing active subscriptions
        existing_subscriptions = await self.payment_repo.get_merchant_subscriptions(
            merchant_id, 
            status=SubscriptionStatus.ACTIVE
        )
        
        for sub in existing_subscriptions:
            sub.status = SubscriptionStatus.CANCELLED
            self.session.add(sub)
        
        # Calculate end date using proper calendar months
        start_date = date.today()
        end_date = start_date + relativedelta(months=duration_months)
        
        # Create new subscription
        subscription = MerchantSubscription(
            merchant_id=merchant_id,
            tariff_plan_id=tariff_plan_id,
            payment_id=payment.id,
            start_date=start_date,
            end_date=end_date,
            status=SubscriptionStatus.ACTIVE
        )
        
        subscription = await self.payment_repo.create_subscription(subscription)
        return subscription
    
    async def get_merchant_subscription(self, user_id: str) -> Optional[SubscriptionResponse]:
        """Get merchant's current subscription."""
        # Find merchant
        merchant_stmt = select(Merchant).where(Merchant.user_id == user_id)
        merchant_result = await self.session.execute(merchant_stmt)
        merchant = merchant_result.scalar_one_or_none()

        if not merchant:
            return None
        
        # Find active subscription
        subscription = await self.payment_repo.get_merchant_active_subscription(merchant.id)
        
        if not subscription:
            return None
        
        # Load tariff plan relationship
        plan_stmt = select(TariffPlan).where(TariffPlan.id == subscription.tariff_plan_id)
        plan_result = await self.session.execute(plan_stmt)
        tariff_plan = plan_result.scalar_one_or_none()
        
        if not tariff_plan:
            return None
        
        # Create response with tariff plan
        return SubscriptionResponse(
            id=subscription.id,
            tariff_plan=TariffPlanResponse.model_validate(tariff_plan),
            start_date=subscription.start_date,
            end_date=subscription.end_date,
            status=subscription.status,
            created_at=subscription.created_at
        )
    
    async def check_subscription_limit(
        self,
        user_id: str,
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
        return await self.payment_repo.expire_subscriptions_by_date(date.today())