import logging
from typing import List
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Request, Header
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.core.database import get_db_session
from app.core.config import get_settings
from app.api.deps import get_current_user
from app.models.user_model import User
from app.models.payment_model import PaymentMethod
from app.services.payment_service import PaymentService, PaymentError, SubscriptionError
from app.services.payment_providers import get_payment_providers
from app.services.payme_merchant_api import PaymeMerchantAPI
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
        
    except HTTPException:
        # Re-raise HTTP exceptions (they're already properly formatted)
        raise
    except PaymentError as e:
        if "not found" in str(e).lower():
            raise HTTPException(status_code=404, detail=str(e))
        else:
            raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        import traceback
        import logging
        logger = logging.getLogger(__name__)
        error_details = traceback.format_exc()
        logger.error(f"API Error in create_tariff_payment: {str(e)}")
        logger.error(f"Traceback: {error_details}")
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
        
    except HTTPException:
        # Re-raise HTTP exceptions (they're already properly formatted)
        raise
    except PaymentError as e:
        if "not found" in str(e).lower():
            raise HTTPException(status_code=404, detail=str(e))
        else:
            raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        import traceback
        import logging
        logger = logging.getLogger(__name__)
        error_details = traceback.format_exc()
        logger.error(f"API Error in create_featured_service_payment: {str(e)}")
        logger.error(f"Traceback: {error_details}")
        raise HTTPException(status_code=500, detail=f"Failed to create featured service payment: {str(e)}")


@router.post(
    "/webhook/{method}",
    status_code=200,
    response_class=JSONResponse,
    include_in_schema=False  # Don't include in OpenAPI schema to avoid any path issues
)
async def payment_webhook(
    method: str,
    request: Request,
    authorization: Optional[str] = Header(None, alias="Authorization"),
    test_operation: Optional[str] = Header(None, alias="Test-Operation"),
    background_tasks: BackgroundTasks = BackgroundTasks(),
    payment_service: PaymentService = Depends(get_payment_service),
    session: AsyncSession = Depends(get_db_session)
):
    """
    Handle payment webhooks from providers.
    
    For Payme, this endpoint handles both:
    1. JSON-RPC 2.0 Merchant API requests (CheckPerformTransaction, etc.)
    2. Webhook notifications
    
    If the request is a JSON-RPC 2.0 request, it validates authorization
    and routes to the Merchant API handler.
    """
    # Initialize webhook_data early to avoid issues in exception handler
    webhook_data = {}
    try:
        logger = logging.getLogger(__name__)
        
        # Log request details for debugging
        logger.info(f"Request URL: {request.url}")
        logger.info(f"Request method: {request.method}")
        logger.info(f"Request headers: {dict(request.headers)}")
        
        # Get raw request body for signature verification
        raw_body_bytes = await request.body()
        logger.info(f"Raw body bytes: {raw_body_bytes}")
        raw_body = raw_body_bytes.decode('utf-8') if raw_body_bytes else ''
        logger.info(f"Raw body: {raw_body}")
        # Parse JSON for processing
        import json as json_lib
        try:
            webhook_data = json_lib.loads(raw_body) if raw_body else {}
        except json_lib.JSONDecodeError as e:
            logger.warning(f"Failed to parse JSON body: {str(e)}")
            webhook_data = {}
        logger.info(f"Webhook data: {webhook_data}")
        # Check if this is a Payme JSON-RPC 2.0 Merchant API request
        if method.lower() == "payme" and _is_jsonrpc_request(webhook_data):
            # This is a Merchant API request - handle with proper authorization
            settings = get_settings()
            logger.info(f"Settings: {settings}")
            # Verify authorization
            if not authorization:
                logger.info(f"Authorization not found")
                return JSONResponse(
                    status_code=200,
                    content={
                        "id": webhook_data.get("id"),
                        "result": None,
                        "error": {
                            "code": -32504,
                            "message": "Неверная авторизация",
                            "data": {}
                        }
                    }
                )
            logger.info(f"Authorization found")
            # Extract merchant_id from Authorization header to determine which secret key to use
            # For Payme Sandbox, we need to try both secret keys since merchant_id might not match
            secret_keys_to_try = []
            logger.info(f"Secret keys to try: {secret_keys_to_try}")
            # Check if this is a Sandbox test request (Payme Sandbox sends "Test-Operation: Paycom" header)
            is_sandbox = test_operation and test_operation.lower() == "paycom"
            logger.info(f"Is sandbox: {is_sandbox}")
            # Get merchant_id from authorization
            merchant_id = _extract_merchant_id_from_auth(authorization)
            logger.info(f"Merchant ID: {merchant_id}")
            # If Sandbox request, prioritize Sandbox secret key
            if is_sandbox and settings.PAYME_SANDBOX_SECRET_KEY:
                secret_keys_to_try = [settings.PAYME_SANDBOX_SECRET_KEY]
                logger.info(f"Secret keys to try: {secret_keys_to_try}")
            elif merchant_id:
                # Try to match merchant_id to configured terminals
                if settings.PAYME_TARIFF_MERCHANT_ID and merchant_id == settings.PAYME_TARIFF_MERCHANT_ID:
                    secret_keys_to_try = [settings.PAYME_TARIFF_SECRET_KEY]
                    logger.info(f"Secret keys to try: {secret_keys_to_try}")
                elif settings.PAYME_SERVICE_BOOST_MERCHANT_ID and merchant_id == settings.PAYME_SERVICE_BOOST_MERCHANT_ID:
                    secret_keys_to_try = [settings.PAYME_SERVICE_BOOST_SECRET_KEY]
                    logger.info(f"Secret keys to try: {secret_keys_to_try}")
                else:
                    # Merchant ID doesn't match - try Sandbox key first, then both production keys
                    if settings.PAYME_SANDBOX_SECRET_KEY:
                        secret_keys_to_try = [settings.PAYME_SANDBOX_SECRET_KEY]
                    secret_keys_to_try.extend([
                        settings.PAYME_TARIFF_SECRET_KEY,
                        settings.PAYME_SERVICE_BOOST_SECRET_KEY
                    ])
                    logger.info(f"Secret keys to try: {secret_keys_to_try}")
            else:
                # Can't extract merchant_id - try Sandbox key first, then both production keys
                if settings.PAYME_SANDBOX_SECRET_KEY:
                    secret_keys_to_try = [settings.PAYME_SANDBOX_SECRET_KEY]
                secret_keys_to_try.extend([
                    settings.PAYME_TARIFF_SECRET_KEY,
                    settings.PAYME_SERVICE_BOOST_SECRET_KEY
                ])
            
            # Filter out None values
            secret_keys_to_try = [sk for sk in secret_keys_to_try if sk]
            
            if not secret_keys_to_try:
                # No secret key configured
                return JSONResponse(
                    status_code=200,
                    content={
                        "id": webhook_data.get("id"),
                        "result": None,
                        "error": {
                            "code": -32504,
                            "message": "Неверная авторизация",
                            "data": {}
                        }
                    }
                )
            
            # Try each secret key until one works
            authorization_valid = False
            valid_secret_key = None
            verification_errors = []
            
            # For Sandbox, check if the Authorization header contains a secret key directly
            # Payme Sandbox sometimes sends merchant_id:secret_key instead of merchant_id:signature
            if is_sandbox:
                import base64
                try:
                    auth_string = authorization[6:] if authorization.startswith("Basic ") else authorization
                    decoded = base64.b64decode(auth_string).decode('utf-8')
                    if ":" in decoded:
                        _, received_key = decoded.split(":", 1)
                        # Check if the received key matches any of our configured secret keys
                        for secret_key in secret_keys_to_try:
                            if received_key == secret_key:
                                logger.info(
                                    f"Payme Sandbox: Authorization header contains matching secret key. "
                                    f"Merchant ID: {merchant_id}"
                                )
                                authorization_valid = True
                                valid_secret_key = secret_key
                                break
                except Exception as e:
                    logger.debug(f"Failed to check Sandbox secret key in Authorization: {str(e)}")
            
            # If not already validated (or not Sandbox), try signature verification
            if not authorization_valid:
                for secret_key in secret_keys_to_try:
                    try:
                        merchant_api = PaymeMerchantAPI(
                            session=session,
                            secret_key=secret_key
                        )
                        
                        # Use raw body for signature verification to match exact format
                        if merchant_api.verify_request_with_raw_body(raw_body, authorization):
                            authorization_valid = True
                            valid_secret_key = secret_key
                            break
                    except Exception as e:
                        verification_errors.append(str(e))
                        continue
            
            if not authorization_valid:
                # Log more details for debugging
                logger.warning(
                    f"Payme authorization failed. "
                    f"Merchant ID: {merchant_id}, "
                    f"Is Sandbox: {is_sandbox}, "
                    f"Tried {len(secret_keys_to_try)} secret keys, "
                    f"Errors: {verification_errors}, "
                    f"Request method: {webhook_data.get('method')}, "
                    f"Request ID: {webhook_data.get('id')}, "
                    f"Body length: {len(raw_body)}"
                )
                
                # Log debug info about secret keys (without exposing actual keys)
                if secret_keys_to_try:
                    logger.debug(
                        f"Secret keys configured: {len(secret_keys_to_try)} keys, "
                        f"First key length: {len(secret_keys_to_try[0]) if secret_keys_to_try[0] else 0}"
                    )
                
                return JSONResponse(
                    status_code=200,
                    content={
                        "id": webhook_data.get("id"),
                        "result": None,
                        "error": {
                            "code": -32504,
                            "message": "Неверная авторизация",
                            "data": {}
                        }
                    }
                )
            
            # Use the valid secret key for the API handler
            merchant_api = PaymeMerchantAPI(
                session=session,
                secret_key=valid_secret_key
            )
            
            # Handle Merchant API request
            response = await merchant_api.handle_request(webhook_data)
            # Explicitly set media_type and headers to ensure JSON response and prevent redirects
            return JSONResponse(
                status_code=200,
                content=response,
                media_type="application/json",
                headers={
                    "Content-Type": "application/json",
                    "Cache-Control": "no-cache, no-store, must-revalidate",
                    "Pragma": "no-cache",
                    "Expires": "0"
                }
            )
        
        # Regular webhook notification handling
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
        import traceback
        logger = logging.getLogger(__name__)
        error_details = traceback.format_exc()
        logger.error(f"Exception in payment_webhook: {str(e)}")
        logger.error(f"Traceback: {error_details}")
        
        # If it's a JSON-RPC request, return JSON-RPC error format
        if method.lower() == "payme" and _is_jsonrpc_request(webhook_data):
            return JSONResponse(
                status_code=200,
                content={
                    "id": webhook_data.get("id"),
                    "result": None,
                    "error": {
                        "code": -32603,
                        "message": f"Internal error: {str(e)}",
                        "data": {}
                    }
                },
                media_type="application/json"
            )
        raise HTTPException(
            status_code=500, 
            detail=f"Failed to process webhook: {str(e)}"
        )


def _is_jsonrpc_request(data: dict) -> bool:
    """Check if the request is a JSON-RPC 2.0 request."""
    return (
        isinstance(data, dict) and
        "jsonrpc" in data and
        "method" in data and
        "id" in data
    )


def _extract_merchant_id_from_auth(authorization: str) -> Optional[str]:
    """
    Extract merchant_id from Authorization header.
    
    Authorization format: Basic base64(merchant_id:signature)
    """
    try:
        import base64
        
        if not authorization.startswith("Basic "):
            return None
        
        auth_string = authorization[6:]  # Remove "Basic "
        decoded = base64.b64decode(auth_string).decode()
        
        if ":" not in decoded:
            return None
        
        merchant_id, _ = decoded.split(":", 1)
        return merchant_id
            
    except Exception:
        return None


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