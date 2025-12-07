from typing import List
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db_session
from app.api.deps import get_current_user
from app.models.user_model import User
from app.models.payment_model import PaymentMethod
from app.services.payment_service import PaymentService, PaymentError, SubscriptionError
from app.services.payment_providers import get_payment_providers
from app.schemas.payment_schema import (
    PaymentResponse, SubscriptionResponse,
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
        sms_service=None  # SMS service would be injected here # TODO
    )


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
        import traceback
        error_details = traceback.format_exc()
        print(f"API Error in create_tariff_payment: {str(e)}")
        print(f"Traceback: {error_details}")
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