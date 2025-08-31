from typing import List
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.api.deps import get_current_user
from app.models.user import User
from app.models.payment import PaymentMethod
from app.services.payment_service import PaymentService, PaymentError, SubscriptionError
from app.services.payment_providers import get_payment_providers
from app.schemas.payment import (
    TariffPlanResponse, PaymentResponse, SubscriptionResponse,
    TariffPaymentRequest, FeaturedServicePaymentRequest,
    WebhookPaymentData, PaymentWebhookResponse
)


router = APIRouter()


def get_payment_service(
    session: AsyncSession = Depends(get_db_session),
    payment_providers = Depends(get_payment_providers)
) -> PaymentService:
    """Get payment service instance."""
    return PaymentService(
        session=session,
        payment_providers=payment_providers,
        sms_service=None  # SMS service would be injected here
    )


@router.get("/tariffs", response_model=List[TariffPlanResponse])
async def get_tariff_plans(
    payment_service: PaymentService = Depends(get_payment_service)
):
    """Get available tariff plans."""
    try:
        plans = await payment_service.get_active_tariff_plans()
        return [TariffPlanResponse.from_orm(plan) for plan in plans]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get tariff plans: {str(e)}")


@router.get("/merchants/subscription", response_model=SubscriptionResponse)
async def get_merchant_subscription(
    current_user: User = Depends(get_current_user),
    payment_service: PaymentService = Depends(get_payment_service)
):
    """Get merchant's current subscription."""
    try:
        subscription = await payment_service.get_merchant_subscription(current_user.id)
        if not subscription:
            raise HTTPException(
                status_code=404, 
                detail="No active subscription found for this merchant"
            )
        return subscription
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get subscription: {str(e)}")


@router.post("/tariff", response_model=PaymentResponse, status_code=201)
async def create_tariff_payment(
    request: TariffPaymentRequest,
    current_user: User = Depends(get_current_user),
    payment_service: PaymentService = Depends(get_payment_service)
):
    """Create tariff subscription payment."""
    try:
        # Verify user is a merchant
        if current_user.user_type != "merchant":
            raise HTTPException(
                status_code=403,
                detail="Only merchants can purchase tariff plans"
            )
        
        payment = await payment_service.create_tariff_payment(current_user.id, request)
        return payment
        
    except PaymentError as e:
        if "not found" in str(e).lower():
            raise HTTPException(status_code=404, detail=str(e))
        else:
            raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create payment: {str(e)}")


@router.post("/featured-service", response_model=PaymentResponse, status_code=201)
async def create_featured_service_payment(
    request: FeaturedServicePaymentRequest,
    current_user: User = Depends(get_current_user),
    payment_service: PaymentService = Depends(get_payment_service)
):
    """Create featured service payment."""
    try:
        # Verify user is a merchant
        if current_user.user_type != "merchant":
            raise HTTPException(
                status_code=403,
                detail="Only merchants can feature services"
            )
        
        payment = await payment_service.create_featured_service_payment(current_user.id, request)
        return payment
        
    except PaymentError as e:
        if "not found" in str(e).lower():
            raise HTTPException(status_code=404, detail=str(e))
        else:
            raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create featured service payment: {str(e)}")


@router.post("/webhook/{method}", response_model=PaymentWebhookResponse)
async def payment_webhook(
    method: str,
    webhook_data: dict,
    background_tasks: BackgroundTasks,
    payment_service: PaymentService = Depends(get_payment_service)
):
    """Handle payment webhooks from providers."""
    try:
        # Validate payment method
        try:
            payment_method = PaymentMethod(method.lower())
        except ValueError:
            raise HTTPException(
                status_code=400, 
                detail=f"Invalid payment method: {method}"
            )
        
        # Process webhook in background
        background_tasks.add_task(
            _process_webhook_background,
            payment_service,
            payment_method,
            webhook_data
        )
        
        return PaymentWebhookResponse(
            success=True,
            message="Webhook received and will be processed"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Failed to process webhook: {str(e)}"
        )


async def _process_webhook_background(
    payment_service: PaymentService,
    payment_method: PaymentMethod,
    webhook_data: dict
):
    """Process webhook in background task."""
    try:
        success = await payment_service.process_payment_webhook(
            payment_method=payment_method,
            webhook_data=webhook_data
        )
        
        # Log the result (in production, use proper logging)
        if success:
            print(f"Webhook processed successfully for {payment_method}")
        else:
            print(f"Webhook processing failed for {payment_method}")
            
    except Exception as e:
        # Log error (in production, use proper logging and maybe retry logic)
        print(f"Background webhook processing error: {str(e)}")


@router.get("/subscription/limits")
async def get_subscription_limits(
    current_user: User = Depends(get_current_user),
    payment_service: PaymentService = Depends(get_payment_service)
):
    """Get merchant's subscription limits and current usage."""
    try:
        if current_user.user_type != "merchant":
            raise HTTPException(
                status_code=403,
                detail="Only merchants can check subscription limits"
            )
        
        subscription = await payment_service.get_merchant_subscription(current_user.id)
        if not subscription:
            return {
                "subscription": None,
                "limits": {},
                "message": "No active subscription"
            }
        
        # In a real implementation, you would calculate current usage
        # For now, return the limits from the tariff plan
        limits = {
            "services": {
                "limit": subscription.tariff_plan.max_services,
                "current": 0,  # Would be calculated from database
                "available": subscription.tariff_plan.max_services
            },
            "images_per_service": {
                "limit": subscription.tariff_plan.max_images_per_service,
                "current": 0,
                "available": subscription.tariff_plan.max_images_per_service
            },
            "phone_numbers": {
                "limit": subscription.tariff_plan.max_phone_numbers,
                "current": 0,
                "available": subscription.tariff_plan.max_phone_numbers
            },
            "gallery_images": {
                "limit": subscription.tariff_plan.max_gallery_images,
                "current": 0,
                "available": subscription.tariff_plan.max_gallery_images
            },
            "social_accounts": {
                "limit": subscription.tariff_plan.max_social_accounts,
                "current": 0,
                "available": subscription.tariff_plan.max_social_accounts
            },
            "website_allowed": subscription.tariff_plan.allow_website,
            "cover_image_allowed": subscription.tariff_plan.allow_cover_image,
            "monthly_featured_cards": subscription.tariff_plan.monthly_featured_cards
        }
        
        return {
            "subscription": subscription,
            "limits": limits
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get subscription limits: {str(e)}"
        )


@router.post("/subscription/check-limit")
async def check_subscription_limit(
    limit_type: str,
    current_count: int,
    current_user: User = Depends(get_current_user),
    payment_service: PaymentService = Depends(get_payment_service)
):
    """Check if merchant can perform action within subscription limits."""
    try:
        if current_user.user_type != "merchant":
            raise HTTPException(
                status_code=403,
                detail="Only merchants can check subscription limits"
            )
        
        can_proceed = await payment_service.check_subscription_limit(
            current_user.id, limit_type, current_count
        )
        
        return {
            "can_proceed": can_proceed,
            "limit_type": limit_type,
            "current_count": current_count
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to check subscription limit: {str(e)}"
        )


# Admin endpoints (would require admin authentication in production)
@router.post("/admin/expire-subscriptions")
async def expire_old_subscriptions(
    background_tasks: BackgroundTasks,
    payment_service: PaymentService = Depends(get_payment_service)
):
    """Expire old subscriptions (admin only)."""
    try:
        # In production, this would require admin authentication
        background_tasks.add_task(_expire_subscriptions_background, payment_service)
        
        return {
            "message": "Subscription expiry process started in background"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to start expiry process: {str(e)}"
        )


async def _expire_subscriptions_background(payment_service: PaymentService):
    """Expire subscriptions in background task."""
    try:
        expired_count = await payment_service.expire_old_subscriptions()
        print(f"Expired {expired_count} subscriptions")
    except Exception as e:
        print(f"Background subscription expiry error: {str(e)}")


@router.get("/admin/stats")
async def get_payment_stats(
    payment_service: PaymentService = Depends(get_payment_service)
):
    """Get payment and subscription statistics (admin only)."""
    try:
        # In production, this would require admin authentication
        # For now, return basic stats from the payment service
        return {
            "message": "Payment statistics endpoint",
            "note": "Would return comprehensive stats in full implementation"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get payment stats: {str(e)}"
        )