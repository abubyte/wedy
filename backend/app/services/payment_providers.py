import hashlib
import hmac
import json
import uuid
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from urllib.parse import urlencode
import httpx
from fastapi import HTTPException

from app.core.config import get_settings
from app.models.payment_model import PaymentMethod


settings = get_settings()


class PaymentProviderError(Exception):
    """Payment provider specific error."""
    pass


class BasePaymentProvider(ABC):
    """Base class for payment providers."""
    
    @abstractmethod
    async def create_payment(self, payment_data: Dict[str, Any]) -> Dict[str, str]:
        """Create payment and return payment URL and transaction ID."""
        pass
    
    @abstractmethod
    def verify_webhook(self, webhook_data: Dict[str, Any], signature: str) -> bool:
        """Verify webhook signature."""
        pass
    
    @abstractmethod
    def extract_payment_status(self, webhook_data: Dict[str, Any]) -> str:
        """Extract payment status from webhook data."""
        pass


class PaymeProvider(BasePaymentProvider):
    """Payme payment provider implementation."""
    
    def __init__(self):
        self.merchant_id = settings.PAYME_MERCHANT_ID
        self.secret_key = settings.PAYME_SECRET_KEY
        self.api_url = settings.PAYME_API_URL or "https://checkout.paycom.uz/api"
    
    async def create_payment(self, payment_data: Dict[str, Any]) -> Dict[str, str]:
        """Create Payme payment."""
        try:
            # Convert amount to tiyins (1 UZS = 100 tiyins)
            amount_tiyins = int(payment_data["amount"] * 100)
            
            # Create unique order ID
            order_id = str(uuid.uuid4())
            
            # Prepare payment request
            payment_params = {
                "amount": amount_tiyins,
                "account": {
                    "order_id": order_id,
                    "user_id": payment_data["user_id"]
                }
            }
            
            # Generate payment URL
            base64_params = self._encode_params(payment_params)
            payment_url = f"{self.api_url}?{urlencode({'m': self.merchant_id, 'ac': base64_params})}"
            
            return {
                "payment_url": payment_url,
                "transaction_id": order_id
            }
            
        except Exception as e:
            raise PaymentProviderError(f"Payme payment creation failed: {str(e)}")
    
    def _encode_params(self, params: Dict[str, Any]) -> str:
        """Encode parameters for Payme URL."""
        import base64
        json_params = json.dumps(params, separators=(',', ':'))
        return base64.b64encode(json_params.encode()).decode()
    
    def verify_webhook(self, webhook_data: Dict[str, Any], signature: str) -> bool:
        """Verify Payme webhook signature."""
        try:
            # Create expected signature
            data_string = json.dumps(webhook_data, separators=(',', ':'), sort_keys=True)
            expected_signature = hmac.new(
                self.secret_key.encode(),
                data_string.encode(),
                hashlib.sha256
            ).hexdigest()
            
            return hmac.compare_digest(signature, expected_signature)
            
        except Exception:
            return False
    
    def extract_payment_status(self, webhook_data: Dict[str, Any]) -> str:
        """Extract payment status from Payme webhook."""
        params = webhook_data.get("params", {})
        state = params.get("state", 0)
        
        # Payme states: 1 = created, 2 = completed, -1 = cancelled, -2 = cancelled after completion
        if state == 2:
            return "completed"
        elif state in [-1, -2]:
            return "cancelled"
        else:
            return "pending"

class ClickProvider(BasePaymentProvider):
    """Click payment provider implementation."""
    
    def __init__(self):
        # Check if Click is configured
        if not settings.CLICK_SECRET_KEY or not settings.CLICK_MERCHANT_ID or not settings.CLICK_SERVICE_ID:
            raise PaymentProviderError(
                "Click payment provider not configured. "
                "Missing CLICK_SECRET_KEY, CLICK_MERCHANT_ID, or CLICK_SERVICE_ID"
            )
        
        self.merchant_id = settings.CLICK_MERCHANT_ID
        self.secret_key = settings.CLICK_SECRET_KEY
        self.service_id = settings.CLICK_SERVICE_ID
        self.api_url = settings.CLICK_API_URL or "https://api.click.uz/v2/merchant"
    
    async def create_payment(self, payment_data: Dict[str, Any]) -> Dict[str, str]:
        """
        Create Click payment.
        
        Click payment flow:
        1. Generate merchant transaction ID
        2. Create payment URL with parameters
        3. User redirects to Click payment page
        """
        try:
            from datetime import datetime
            
            # Create unique merchant transaction ID
            merchant_trans_id = str(uuid.uuid4())
            
            # Convert amount to string (Click expects amount as string)
            amount_str = str(int(payment_data["amount"]))
            
            # Generate sign_time (Unix timestamp)
            sign_time = str(int(datetime.now().timestamp()))
            
            # Prepare signature data
            # Click signature format: click_trans_id + service_id + secret_key + merchant_trans_id + amount + action + error + error_note + sign_time
            # For payment creation: click_trans_id is empty, action=0 (prepare), error=0
            signature_data = {
                "click_trans_id": "",
                "service_id": self.service_id,
                "merchant_trans_id": merchant_trans_id,
                "amount": amount_str,
                "action": "0",
                "error": "0",
                "error_note": "",
                "sign_time": sign_time
            }
            
            # Generate signature
            sign_string = self._generate_signature(signature_data)
            
            # Create payment URL
            # Click payment URL format: https://my.click.uz/services/pay?service_id=...&merchant_id=...&amount=...&transaction_param=...
            payment_url = (
                f"https://my.click.uz/services/pay"
                f"?service_id={self.service_id}"
                f"&merchant_id={self.merchant_id}"
                f"&amount={amount_str}"
                f"&transaction_param={merchant_trans_id}"
                f"&sign_time={sign_time}"
                f"&sign_string={sign_string}"
            )
            
            return {
                "payment_url": payment_url,
                "transaction_id": merchant_trans_id
            }
            
        except Exception as e:
            if isinstance(e, PaymentProviderError):
                raise
            raise PaymentProviderError(f"Click payment creation failed: {str(e)}")
    
    def _generate_signature(self, params: Dict[str, Any]) -> str:
        """
        Generate Click signature using MD5 hash.
        
        Signature format: click_trans_id + service_id + secret_key + merchant_trans_id + amount + action + error + error_note + sign_time
        """
        # Build signature string in the correct order
        sign_parts = [
            str(params.get("click_trans_id", "")),
            str(params.get("service_id", "")),
            self.secret_key,
            str(params.get("merchant_trans_id", "")),
            str(params.get("amount", "")),
            str(params.get("action", "")),
            str(params.get("error", "")),
            str(params.get("error_note", "")),
            str(params.get("sign_time", ""))
        ]
        
        sign_string = "".join(sign_parts)
        return hashlib.md5(sign_string.encode()).hexdigest()
    
    def verify_webhook(self, webhook_data: Dict[str, Any], signature: str) -> bool:
        """
        Verify Click webhook signature.
        
        Args:
            webhook_data: Webhook data from Click
            signature: Signature received in webhook (sign_string field)
            
        Returns:
            True if signature is valid, False otherwise
        """
        try:
            # Extract signature from webhook data if not provided separately
            if not signature and "sign_string" in webhook_data:
                signature = webhook_data["sign_string"]
            
            # Generate expected signature
            expected_signature = self._generate_signature(webhook_data)
            
            return hmac.compare_digest(signature, expected_signature)
        except Exception:
            return False
    
    def extract_payment_status(self, webhook_data: Dict[str, Any]) -> str:
        """
        Extract payment status from Click webhook.
        
        Click webhook actions:
        - action = 0: Payment prepared
        - action = 1: Payment completed successfully
        - action = -1: Payment cancelled
        
        Error codes:
        - error = 0: No error
        - error != 0: Error occurred
        
        Returns:
            "completed", "failed", or "pending"
        """
        action = webhook_data.get("action", 0)
        error = webhook_data.get("error", 0)
        
        # Convert to int if string
        if isinstance(action, str):
            try:
                action = int(action)
            except (ValueError, TypeError):
                action = 0
        
        if isinstance(error, str):
            try:
                error = int(error)
            except (ValueError, TypeError):
                error = 0
        
        # Completed: action = 1 and error = 0
        if action == 1 and error == 0:
            return "completed"
        # Failed: error != 0 or action = -1
        elif error != 0 or action == -1:
            return "failed"
        # Pending: action = 0
        else:
            return "pending"

# TODO: Implement UzumBankProvider similarly
# class UzumBankProvider(BasePaymentProvider):
#     """UzumBank payment provider implementation."""
    
#     def __init__(self):
#         self.merchant_id = settings.UZUMBANK_MERCHANT_ID
#         self.secret_key = settings.UZUMBANK_SECRET_KEY
#         self.api_url = settings.UZUMBANK_API_URL or "https://api.uzumbank.uz"
    
#     async def create_payment(self, payment_data: Dict[str, Any]) -> Dict[str, str]:
#         """Create UzumBank payment."""
#         try:
#             # Create unique order ID
#             order_id = str(uuid.uuid4())
            
#             # Prepare payment request
#             payment_request = {
#                 "merchant_id": self.merchant_id,
#                 "order_id": order_id,
#                 "amount": int(payment_data["amount"] * 100),  # Convert to tiyins
#                 "currency": "UZS",
#                 "description": payment_data.get("description", "Payment"),
#                 "return_url": f"{settings.BASE_URL}/payment/return",
#                 "cancel_url": f"{settings.BASE_URL}/payment/cancel"
#             }
            
#             # Generate signature
#             signature = self._generate_signature(payment_request)
#             payment_request["signature"] = signature
            
#             # Make API request to create payment
#             async with httpx.AsyncClient() as client:
#                 response = await client.post(
#                     f"{self.api_url}/merchant/payment/create",
#                     json=payment_request,
#                     headers={"Content-Type": "application/json"}
#                 )
                
#                 if response.status_code != 200:
#                     raise PaymentProviderError(f"UzumBank API error: {response.status_code}")
                
#                 result = response.json()
                
#                 if not result.get("success"):
#                     raise PaymentProviderError(f"UzumBank error: {result.get('message')}")
                
#                 return {
#                     "payment_url": result["data"]["payment_url"],
#                     "transaction_id": order_id
#                 }
                
#         except Exception as e:
#             if isinstance(e, PaymentProviderError):
#                 raise
#             raise PaymentProviderError(f"UzumBank payment creation failed: {str(e)}")
    
#     def _generate_signature(self, params: Dict[str, Any]) -> str:
#         """Generate UzumBank signature."""
#         # Sort parameters and create signature string
#         sorted_params = sorted(params.items())
#         param_string = "&".join([f"{k}={v}" for k, v in sorted_params])
#         signature_string = param_string + self.secret_key
        
#         return hashlib.sha256(signature_string.encode()).hexdigest()
    
#     def verify_webhook(self, webhook_data: Dict[str, Any], signature: str) -> bool:
#         """Verify UzumBank webhook signature."""
#         try:
#             # Remove signature from data for verification
#             data_without_signature = {k: v for k, v in webhook_data.items() if k != "signature"}
#             expected_signature = self._generate_signature(data_without_signature)
#             return hmac.compare_digest(signature, expected_signature)
#         except Exception:
#             return False
    
#     def extract_payment_status(self, webhook_data: Dict[str, Any]) -> str:
#         """Extract payment status from UzumBank webhook."""
#         status = webhook_data.get("status", "").lower()
        
#         if status == "success":
#             return "completed"
#         elif status in ["failed", "error", "cancelled"]:
#             return "failed"
#         else:
#             return "pending"


class PaymentProviderFactory:
    """Factory for creating payment providers."""
    
    _providers = {
        PaymentMethod.PAYME: PaymeProvider,
        PaymentMethod.CLICK: ClickProvider,
        # PaymentMethod.UZUMBANK: UzumBankProvider # TODO: Uncomment when UzumBankProvider is implemented
    }
    
    @classmethod
    def create_provider(cls, method: PaymentMethod) -> BasePaymentProvider:
        """Create payment provider instance."""
        provider_class = cls._providers.get(method)
        if not provider_class:
            raise PaymentProviderError(f"Unsupported payment method: {method}")
        
        return provider_class()
    
    @classmethod
    def get_all_providers(cls) -> Dict[PaymentMethod, BasePaymentProvider]:
        """Get all available payment providers."""
        return {method: provider_class() for method, provider_class in cls._providers.items()}


# Provider instances for dependency injection
def get_payment_providers() -> Dict[str, BasePaymentProvider]:
    """
    Get payment provider instances for dependency injection.
    
    Only returns providers that are properly configured.
    Providers with missing credentials are silently skipped.
    """
    providers = {}
    
    for method in PaymentMethod:
        try:
            provider = PaymentProviderFactory.create_provider(method)
            providers[method.value] = provider
        except PaymentProviderError:
            # Provider not configured, skip it
            continue
        except Exception:
            # Other errors, skip it
            continue
    
    return providers