"""
Payme Merchant API Handler

This module implements the Payme Merchant API according to the official documentation:
https://developer.help.paycom.uz/

The Merchant API uses JSON-RPC 2.0 protocol where Payme server calls our endpoints.
"""
import hashlib
import hmac
import json
import time
from typing import Dict, Any, Optional, Tuple
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm.attributes import flag_modified

from app.core.config import get_settings
from app.models import FeaturedService, FeatureType
from app.models.payment_model import Payment, PaymentStatus, PaymentMethod, PaymentType, SubscriptionStatus
from app.models.merchant_model import Merchant
from app.models.merchant_subscription_model import MerchantSubscription
from app.models.service_model import Service
from app.repositories.payment_repository import PaymentRepository
from app.services.payment_providers import PaymentProviderError


settings = get_settings()


class PaymeMerchantAPIError(Exception):
    """Payme Merchant API specific error with error codes."""
    
    def __init__(self, code: int, message: str, data: Optional[Dict[str, Any]] = None):
        self.code = code
        self.message = message
        self.data = data or {}
        super().__init__(f"Payme API Error {code}: {message}")


class PaymeMerchantAPI:
    """
    Payme Merchant API Handler
    
    Handles incoming JSON-RPC 2.0 requests from Payme server.
    Implements all 5 required methods:
    1. CheckPerformTransaction
    2. CreateTransaction
    3. PerformTransaction
    4. CancelTransaction
    5. CheckTransaction
    """
    
    # Payme error codes
    ERROR_INVALID_AMOUNT = -31001
    ERROR_TRANSACTION_NOT_FOUND = -31003
    ERROR_CANNOT_PERFORM_OPERATION = -31008
    ERROR_ORDER_ALREADY_PAID = -31007
    ERROR_ACCOUNT_ERROR_MIN = -31050
    ERROR_ACCOUNT_ERROR_MAX = -31099
    
    # Transaction states
    STATE_CREATED = 1
    STATE_COMPLETED = 2
    STATE_CANCELLED = -1
    STATE_CANCELLED_AFTER_COMPLETION = -2
    
    def __init__(self, session: AsyncSession, secret_key: str):
        self.session = session
        self.secret_key = secret_key
        self.payment_repo = PaymentRepository(session)
    
    def verify_request(self, request_data: Dict[str, Any], authorization: str) -> bool:
        """
        Verify Payme request using Authorization header.
        
        Payme sends requests with Authorization header containing:
        Authorization: Basic base64(merchant_id:signature)
        
        Signature is calculated as HMAC-SHA256 of the request body.
        
        Note: This method re-serializes the JSON, which might not match exactly.
        Use verify_request_with_raw_body for exact signature matching.
        """
        try:
            import base64
            
            # Extract merchant_id and signature from Authorization header
            if not authorization.startswith("Basic "):
                return False
            
            auth_string = authorization[6:]  # Remove "Basic "
            decoded = base64.b64decode(auth_string).decode()
            
            if ":" not in decoded:
                return False
            
            merchant_id, signature = decoded.split(":", 1)
            
            # Calculate expected signature
            # Payme uses HMAC-SHA256 of the request body
            # Try with sorted keys first (standard JSON-RPC format)
            request_json = json.dumps(request_data, separators=(',', ':'), ensure_ascii=False, sort_keys=True)
            expected_signature = hmac.new(
                self.secret_key.encode(),
                request_json.encode('utf-8'),
                hashlib.sha256
            ).hexdigest()
            
            if hmac.compare_digest(signature, expected_signature):
                return True
            
            # If sorted doesn't work, try without sorting (some implementations don't sort)
            request_json_no_sort = json.dumps(request_data, separators=(',', ':'), ensure_ascii=False)
            expected_signature_no_sort = hmac.new(
                self.secret_key.encode(),
                request_json_no_sort.encode('utf-8'),
                hashlib.sha256
            ).hexdigest()
            
            return hmac.compare_digest(signature, expected_signature_no_sort)
            
        except Exception:
            return False
    
    def verify_request_with_raw_body(self, raw_body: str, authorization: str) -> bool:
        """
        Verify Payme request using raw request body (exact format as sent).
        
        This method uses the exact request body as received, which ensures
        the signature matches exactly what Payme calculated.
        """
        try:
            import base64
            import logging
            
            logger = logging.getLogger(__name__)
            
            # Extract merchant_id and signature from Authorization header
            if not authorization.startswith("Basic "):
                logger.debug("Authorization header doesn't start with 'Basic '")
                return False
            
            auth_string = authorization[6:]  # Remove "Basic "
            try:
                decoded = base64.b64decode(auth_string).decode('utf-8')
            except Exception as e:
                logger.warning(f"Failed to decode Authorization header: {str(e)}")
                return False
            
            if ":" not in decoded:
                logger.warning(f"Authorization header doesn't contain ':' separator. Decoded: {decoded[:50]}...")
                return False
            
            merchant_id, signature = decoded.split(":", 1)
            
            # Log the extracted values for debugging
            logger.debug(
                f"Extracted from Authorization: merchant_id='{merchant_id}', "
                f"signature_length={len(signature)}, signature_preview={signature[:20]}..."
            )
            
            # Check if Payme Sandbox is sending the secret key directly instead of a signature
            # In Sandbox, they sometimes send merchant_id:secret_key instead of merchant_id:signature
            if signature == self.secret_key:
                logger.info(
                    f"Payme Sandbox detected: Authorization contains secret key directly. "
                    f"Merchant ID: {merchant_id}, Secret key matches."
                )
                return True
            
            # Calculate expected signature using raw body (exact format)
            # Payme uses the raw request body as-is for signature calculation
            # The secret key should be a separate credential, not the merchant_id
            logger.debug(
                f"Calculating signature with secret_key length: {len(self.secret_key) if self.secret_key else 0}, "
                f"raw_body length: {len(raw_body)}"
            )
            
            expected_signature = hmac.new(
                self.secret_key.encode('utf-8'),
                raw_body.encode('utf-8'),
                hashlib.sha256
            ).hexdigest()
            
            is_valid = hmac.compare_digest(signature, expected_signature)
            
            if not is_valid:
                # Use warning level for signature mismatches to help debug Sandbox issues
                logger.warning(
                    f"Payme signature mismatch. "
                    f"Merchant ID: {merchant_id}, "
                    f"Secret key length: {len(self.secret_key) if self.secret_key else 0}, "
                    f"Secret key preview: {self.secret_key[:10] if self.secret_key and len(self.secret_key) > 10 else self.secret_key}..., "
                    f"Expected signature (first 32 chars): {expected_signature[:32]}, "
                    f"Received signature (first 32 chars): {signature[:32]}, "
                    f"Body length: {len(raw_body)}, "
                    f"Body preview: {raw_body[:100]}..."
                )
            
            return is_valid
            
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.debug(f"Exception in verify_request_with_raw_body: {str(e)}")
            return False
    
    async def handle_request(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle incoming JSON-RPC 2.0 request from Payme.
        
        Args:
            request_data: JSON-RPC 2.0 request object
            
        Returns:
            JSON-RPC 2.0 response object
        """
        request_id = request_data.get("id")
        method = request_data.get("method")
        params = request_data.get("params", {})
        
        try:
            # Route to appropriate handler
            if method == "CheckPerformTransaction":
                result = await self.check_perform_transaction(params)
            elif method == "CreateTransaction":
                result = await self.create_transaction(params)
            elif method == "PerformTransaction":
                result = await self.perform_transaction(params)
            elif method == "CancelTransaction":
                result = await self.cancel_transaction(params)
            elif method == "CheckTransaction":
                result = await self.check_transaction(params)
            elif method == "GetStatement":
                result = await self.get_statement(params)
            else:
                raise PaymeMerchantAPIError(
                    -32601,
                    f"Method not found: {method}"
                )
            
            # JSON-RPC 2.0: Success response should only include id and result (no error field)
            return {
                "id": request_id,
                "result": result
            }
            
        except PaymeMerchantAPIError as e:
            # JSON-RPC 2.0: Error response should only include id and error (no result field)
            return {
                "id": request_id,
                "error": {
                    "code": e.code,
                    "message": e.message,
                    "data": e.data
                }
            }
        except Exception as e:
            # JSON-RPC 2.0: Error response should only include id and error (no result field)
            return {
                "id": request_id,
                "error": {
                    "code": -32603,
                    "message": f"Internal error: {str(e)}",
                    "data": {}
                }
            }
    
    async def check_perform_transaction(self, params: Dict[str, Any]) -> Dict[str, bool]:
        """
        CheckPerformTransaction - Проверка возможности создания финансовой транзакции
        
        Validates if a transaction can be created with the given parameters.
        
        Parameters:
            - amount: Payment amount in tiyins
            - account: Account information (order_id, user_id, etc.)
        
        Returns:
            {"allow": True} if transaction can be created
        """
        amount = params.get("amount")
        account = params.get("account", {})
        
        # Validate amount
        if not amount or not isinstance(amount, int) or amount <= 0:
            raise PaymeMerchantAPIError(
                self.ERROR_INVALID_AMOUNT,
                "Неверная сумма платежа",
                {"reason": "amount"}
            )
        
        # Validate account - support multiple formats:
        # 1. Legacy: order_id
        # 2. Tariff: phone_number, tariff_id, month_count (for tariff payments)
        # 3. Boost: phone_number, service_id, days_count (for service boost payments)
        order_id = account.get("order_id")
        phone_number = account.get("phone_number")
        tariff_id = account.get("tariff_id")
        month_count = account.get("month_count")
        service_id = account.get("service_id")
        days_count = account.get("days_count")
        
        # Determine which format is being used
        # Tariff format: has tariff_id or month_count (tariff-specific fields)
        # Boost format: has service_id or days_count (boost-specific fields)
        # phone_number alone doesn't determine the format
        is_tariff_format = tariff_id is not None or month_count is not None
        is_boost_format = service_id is not None or days_count is not None

        # Prevent mixed format (both tariff and boost fields)
        if is_tariff_format and is_boost_format:
            raise PaymeMerchantAPIError(
                self.ERROR_ACCOUNT_ERROR_MIN,
                "Неверный формат данных в поле account",
                {
                    "reason": "mixed_account_format",
                    "message": "Cannot mix tariff fields (tariff_id, month_count) with boost fields (service_id, days_count)"
                }
            )

        # Validate account parameters format
        # For tariff format, all three fields are required
        if is_tariff_format:
            # If any of the tariff format fields are provided, all must be provided
            if not (phone_number and tariff_id and month_count):
                raise PaymeMerchantAPIError(
                    self.ERROR_ACCOUNT_ERROR_MIN,
                    "Неверный формат данных в поле account",
                    {
                        "reason": "invalid_account_format",
                        "message": "phone_number, tariff_id, and month_count must all be provided together"
                    }
                )
            
            # Validate phone_number format - strip country code prefix only
            if phone_number.startswith("+998"):
                normalized_phone = phone_number[4:].strip()
            elif phone_number.startswith("998"):
                normalized_phone = phone_number[3:].strip()
            else:
                normalized_phone = phone_number.strip()
            if not normalized_phone or len(normalized_phone) != 9 or not normalized_phone.isdigit():
                raise PaymeMerchantAPIError(
                    self.ERROR_ACCOUNT_ERROR_MIN,
                    "Неверный формат данных в поле account",
                    {
                        "reason": "invalid_phone_number",
                        "message": "phone_number must be a valid 9-digit number (with or without +998 prefix)"
                    }
                )
            
            # Validate tariff_id format (should be a valid UUID)
            try:
                from uuid import UUID
                UUID(str(tariff_id))
            except (ValueError, TypeError):
                raise PaymeMerchantAPIError(
                    self.ERROR_ACCOUNT_ERROR_MIN,
                    "Неверный формат данных в поле account",
                    {
                        "reason": "invalid_tariff_id",
                        "message": "tariff_id must be a valid UUID"
                    }
                )
            
            # Validate month_count format (should be a positive integer)
            try:
                month_count_int = int(month_count) if isinstance(month_count, str) else month_count
                if month_count_int <= 0:
                    raise ValueError("month_count must be positive")
            except (ValueError, TypeError):
                raise PaymeMerchantAPIError(
                    self.ERROR_ACCOUNT_ERROR_MIN,
                    "Неверный формат данных в поле account",
                    {
                        "reason": "invalid_month_count",
                        "message": "month_count must be a positive integer"
                    }
                )
        
        # Validate boost service format (only if not already a tariff format)
        if is_boost_format and not is_tariff_format:
            # If any of the boost format fields are provided, all must be provided
            if not (phone_number and service_id and days_count):
                raise PaymeMerchantAPIError(
                    self.ERROR_ACCOUNT_ERROR_MIN,
                    "Неверный формат данных в поле account",
                    {
                        "reason": "invalid_account_format",
                        "message": "phone_number, service_id, and days_count must all be provided together"
                    }
                )
            
            # Validate phone_number format (reuse validation from tariff format if not already validated)
            if not is_tariff_format:
                # Strip country code prefix only
                if phone_number.startswith("+998"):
                    normalized_phone = phone_number[4:].strip()
                elif phone_number.startswith("998"):
                    normalized_phone = phone_number[3:].strip()
                else:
                    normalized_phone = phone_number.strip()
                if not normalized_phone or len(normalized_phone) != 9 or not normalized_phone.isdigit():
                    raise PaymeMerchantAPIError(
                        self.ERROR_ACCOUNT_ERROR_MIN,
                        "Неверный формат данных в поле account",
                        {
                            "reason": "invalid_phone_number",
                            "message": "phone_number must be a valid 9-digit number (with or without +998 prefix)"
                        }
                    )
            
            # Validate service_id format (should be a 9-digit numeric string)
            service_id_str = str(service_id).strip()
            if not service_id_str or len(service_id_str) != 9 or not service_id_str.isdigit():
                raise PaymeMerchantAPIError(
                    self.ERROR_ACCOUNT_ERROR_MIN,
                    "Неверный формат данных в поле account",
                    {
                        "reason": "invalid_service_id",
                        "message": "service_id must be a valid 9-digit numeric string"
                    }
                )
            
            # Validate days_count format (should be a positive integer, 1-365)
            try:
                days_count_int = int(days_count) if isinstance(days_count, str) else days_count
                if days_count_int <= 0 or days_count_int > 365:
                    raise ValueError("days_count must be between 1 and 365")
            except (ValueError, TypeError):
                raise PaymeMerchantAPIError(
                    self.ERROR_ACCOUNT_ERROR_MIN,
                    "Неверный формат данных в поле account",
                    {
                        "reason": "invalid_days_count",
                        "message": "days_count must be a positive integer between 1 and 365"
                    }
                )
        
        payment = None
        
        if phone_number and tariff_id and month_count:
            # New format: find payment by tariff parameters
            # month_count_int was already validated above
            month_count_int = int(month_count) if isinstance(month_count, str) else month_count
            payment = await self.payment_repo.get_payment_by_tariff_params(
                phone_number=phone_number,
                tariff_id=str(tariff_id),
                month_count=month_count_int
            )
            
            # If payment not found, try to validate account parameters and calculate expected amount
            # This allows us to return -31001 (invalid amount) instead of -31050 (payment not found)
            # when account parameters are valid but amount is wrong
            if not payment:
                import logging
                from uuid import UUID
                logger = logging.getLogger(__name__)
                logger.debug(
                    f"Payment not found for tariff params. "
                    f"Validating account parameters and calculating expected amount..."
                )
                
                # Validate account parameters by checking if tariff plan exists
                try:
                    tariff_plan = await self.payment_repo.get_tariff_plan_by_id(UUID(str(tariff_id)))
                    if tariff_plan:
                        # Calculate expected amount based on tariff plan and duration
                        # Use the same discount logic as PaymentService
                        total_base = tariff_plan.price_per_month * month_count_int
                        
                        # Apply discounts based on duration
                        if month_count_int >= 12:  # 1 year: 30% discount
                            discount = 0.30
                        elif month_count_int >= 6:  # 6 months: 20% discount
                            discount = 0.20
                        elif month_count_int >= 3:  # 3 months: 10% discount
                            discount = 0.10
                        else:  # 1 month: no discount
                            discount = 0.0
                        
                        expected_amount = total_base * (1 - discount)
                        expected_amount_tiyins = int(expected_amount * 100)
                        
                        # If amount doesn't match, return -31001 (invalid amount)
                        # This handles the case where Payme Sandbox tests with wrong amount
                        if amount != expected_amount_tiyins:
                            logger.warning(
                                f"Amount mismatch in CheckPerformTransaction (no payment found): "
                                f"Expected: {expected_amount_tiyins}, Received: {amount}, "
                                f"Tariff: {tariff_plan.name}, Months: {month_count_int}, "
                                f"Base price: {tariff_plan.price_per_month}, Discount: {discount*100}%"
                            )
                            raise PaymeMerchantAPIError(
                                self.ERROR_INVALID_AMOUNT,
                                "Неверная сумма платежа",
                                {
                                    "reason": "amount",
                                    "expected": expected_amount_tiyins,
                                    "received": amount
                                }
                            )
                        # If amount matches but payment doesn't exist, return payment not found
                        # This is a valid scenario - payment might not have been created yet
                    else:
                        # Tariff plan not found - invalid account parameter
                        raise PaymeMerchantAPIError(
                            self.ERROR_ACCOUNT_ERROR_MIN,
                            "Неверный формат данных в поле account",
                            {
                                "reason": "tariff_not_found",
                                "message": f"Tariff plan with ID {tariff_id} not found"
                            }
                        )
                except PaymeMerchantAPIError:
                    # Re-raise Payme errors (amount validation, account errors, etc.)
                    raise
                except (ValueError, TypeError) as e:
                    logger.debug(f"Could not validate tariff plan: {str(e)}")
                    # Fall through to payment not found error
        
        elif phone_number and service_id and days_count:
            # Boost service format: find payment by service boost parameters
            days_count_int = int(days_count) if isinstance(days_count, str) else days_count
            payment = await self.payment_repo.get_payment_by_service_boost_params(
                phone_number=phone_number,
                service_id=str(service_id),
                days_count=days_count_int
            )
            
            # If payment not found, try to validate account parameters and calculate expected amount
            if not payment:
                import logging
                logger = logging.getLogger(__name__)
                logger.debug(
                    f"Payment not found for service boost params. "
                    f"Validating account parameters and calculating expected amount..."
                )
                
                # Validate account parameters by checking if service exists
                try:
                    from app.models.service_model import Service
                    service_stmt = select(Service).where(Service.id == str(service_id))
                    service_result = await self.session.execute(service_stmt)
                    service = service_result.scalar_one_or_none()
                    
                    if service:
                        # Calculate expected amount based on featured service pricing
                        # Use the same discount logic as PaymentService
                        base_daily_price = 1500.0  # 1500 UZS per day (should match PaymentService)
                        total_base = base_daily_price * days_count_int
                        
                        # Apply discounts based on duration
                        if days_count_int >= 91:  # 91-365 days: 30% discount
                            discount = 0.30
                        elif days_count_int >= 31:  # 31-90 days: 20% discount
                            discount = 0.20
                        elif days_count_int >= 8:  # 8-30 days: 10% discount
                            discount = 0.10
                        else:  # 1-7 days: no discount
                            discount = 0.0
                        
                        expected_amount = total_base * (1 - discount)
                        expected_amount_tiyins = int(expected_amount * 100)
                        
                        # If amount doesn't match, return -31001 (invalid amount)
                        if amount != expected_amount_tiyins:
                            logger.warning(
                                f"Amount mismatch in CheckPerformTransaction (no payment found): "
                                f"Expected: {expected_amount_tiyins}, Received: {amount}, "
                                f"Service ID: {service_id}, Days: {days_count_int}, "
                                f"Base price: {base_daily_price}, Discount: {discount*100}%"
                            )
                            raise PaymeMerchantAPIError(
                                self.ERROR_INVALID_AMOUNT,
                                "Неверная сумма платежа",
                                {
                                    "reason": "amount",
                                    "expected": expected_amount_tiyins,
                                    "received": amount
                                }
                            )
                        # If amount matches but payment doesn't exist, return payment not found
                    else:
                        # Service not found - invalid account parameter
                        raise PaymeMerchantAPIError(
                            self.ERROR_ACCOUNT_ERROR_MIN,
                            "Неверный формат данных в поле account",
                            {
                                "reason": "service_not_found",
                                "message": f"Service with ID {service_id} not found"
                            }
                        )
                except PaymeMerchantAPIError:
                    # Re-raise Payme errors (amount validation, account errors, etc.)
                    raise
                except Exception as e:
                    logger.debug(f"Could not validate service: {str(e)}")
                    # Fall through to payment not found error
        
        elif order_id:
            # Legacy format: find payment by transaction_id
            payment = await self.payment_repo.get_payment_by_transaction_id(str(order_id))
        else:
            # Neither format provided
            raise PaymeMerchantAPIError(
                self.ERROR_ACCOUNT_ERROR_MIN,
                "Неверный формат данных в поле account",
                {"reason": "missing_fields", "required": "order_id OR (phone_number, tariff_id, month_count) OR (phone_number, service_id, days_count)"}
            )
        
        if not payment:
            # Payment not found - use ERROR_ACCOUNT_ERROR_MIN for consistency
            # Note: According to Payme spec, -31050 to -31099 is for account errors
            # "Payment not found" could be considered an account error if the account params are wrong
            raise PaymeMerchantAPIError(
                self.ERROR_ACCOUNT_ERROR_MIN,
                "Заказ не найден",
                {"reason": "payment_not_found"}
            )
        
        # Check if payment is already completed
        if payment.status == PaymentStatus.COMPLETED:
            raise PaymeMerchantAPIError(
                self.ERROR_CANNOT_PERFORM_OPERATION,
                "Заказ уже оплачен",
                {"reason": "already_paid"}
            )
        
        # Check if payment is cancelled
        if payment.status == PaymentStatus.FAILED or payment.status == PaymentStatus.CANCELLED:
            raise PaymeMerchantAPIError(
                self.ERROR_CANNOT_PERFORM_OPERATION,
                "Заказ отменен",
                {"reason": "cancelled"}
            )
        
        # Convert payment amount to tiyins for comparison
        # IMPORTANT: Amount validation should happen AFTER payment is found
        # This ensures we return -31001 (invalid amount) instead of -31049 (payment not found)
        # when the payment exists but amount is wrong
        amount_tiyins = int(payment.amount * 100)
        
        # Verify amount matches
        if amount != amount_tiyins:
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(
                f"Amount mismatch in CheckPerformTransaction: "
                f"Payment ID: {payment.id}, Expected: {amount_tiyins}, Received: {amount}"
            )
            raise PaymeMerchantAPIError(
                self.ERROR_INVALID_AMOUNT,
                "Неверная сумма платежа",
                {
                    "reason": "amount",
                    "expected": amount_tiyins,
                    "received": amount
                }
            )
        
        return {"allow": True}
    
    async def create_transaction(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        CreateTransaction - Создание финансовой транзакции
        
        Creates a financial transaction in the merchant's billing system.
        
        Parameters:
            - id: Payme transaction ID
            - time: Timestamp of transaction creation
            - amount: Payment amount in tiyins
            - account: Account information
        
        Returns:
            Transaction details with create_time, transaction (order_id), and state
        """
        transaction_id = params.get("id")  # Payme's transaction ID
        time_param = params.get("time")
        amount = params.get("amount")
        account = params.get("account", {})
        
        # Validate required fields
        if not transaction_id:
            raise PaymeMerchantAPIError(
                -32602,
                "Неверный формат параметров",
                {"reason": "id"}
            )
        
        if not amount or amount <= 0:
            raise PaymeMerchantAPIError(
                self.ERROR_INVALID_AMOUNT,
                "Неверная сумма платежа",
                {"reason": "amount"}
            )
        
        # Support multiple formats:
        # 1. Legacy: order_id
        # 2. Tariff: phone_number, tariff_id, month_count (for tariff payments)
        # 3. Boost: phone_number, service_id, days_count (for service boost payments)
        order_id = account.get("order_id")
        phone_number = account.get("phone_number")
        tariff_id = account.get("tariff_id")
        month_count = account.get("month_count")
        service_id = account.get("service_id")
        days_count = account.get("days_count")
        
        payment = None
        
        if phone_number and tariff_id and month_count:
            # New format: find payment by tariff parameters
            try:
                month_count_int = int(month_count) if isinstance(month_count, str) else month_count
                payment = await self.payment_repo.get_payment_by_tariff_params(
                    phone_number=phone_number,
                    tariff_id=str(tariff_id),
                    month_count=month_count_int
                )
                import logging
                logger = logging.getLogger(__name__)
                if payment:
                    payment_metadata_check = payment.payment_metadata or {}
                    existing_payme_id_check = None
                    if payment.transaction_id and len(payment.transaction_id) == 24 and all(c in '0123456789abcdef' for c in payment.transaction_id.lower()):
                        existing_payme_id_check = payment.transaction_id
                    if not existing_payme_id_check and "payme_transaction_id" in payment_metadata_check:
                        existing_payme_id_check = payment_metadata_check.get("payme_transaction_id")
                    logger.debug(
                        f"Found payment for CreateTransaction: payment_id={payment.id}, "
                        f"status={payment.status}, existing_payme_id={existing_payme_id_check}, "
                        f"new_transaction_id={transaction_id}, phone={phone_number}, "
                        f"tariff_id={tariff_id}, month_count={month_count_int}"
                    )
            except (ValueError, TypeError) as e:
                import logging
                logger = logging.getLogger(__name__)
                logger.warning(f"Invalid month_count format: {month_count}, error: {str(e)}")
        
        elif phone_number and service_id and days_count:
            # Boost service format: find payment by service boost parameters
            try:
                days_count_int = int(days_count) if isinstance(days_count, str) else days_count
                payment = await self.payment_repo.get_payment_by_service_boost_params(
                    phone_number=phone_number,
                    service_id=str(service_id),
                    days_count=days_count_int
                )
                import logging
                logger = logging.getLogger(__name__)
                if payment:
                    payment_metadata_check = payment.payment_metadata or {}
                    existing_payme_id_check = None
                    if payment.transaction_id and len(payment.transaction_id) == 24 and all(c in '0123456789abcdef' for c in payment.transaction_id.lower()):
                        existing_payme_id_check = payment.transaction_id
                    if not existing_payme_id_check and "payme_transaction_id" in payment_metadata_check:
                        existing_payme_id_check = payment_metadata_check.get("payme_transaction_id")
                    logger.debug(
                        f"Found payment for CreateTransaction (boost): payment_id={payment.id}, "
                        f"status={payment.status}, existing_payme_id={existing_payme_id_check}, "
                        f"new_transaction_id={transaction_id}, phone={phone_number}, "
                        f"service_id={service_id}, days_count={days_count_int}"
                    )
            except (ValueError, TypeError) as e:
                import logging
                logger = logging.getLogger(__name__)
                logger.warning(f"Invalid days_count format: {days_count}, error: {str(e)}")
        
        elif order_id:
            # Legacy format: find payment by transaction_id
            payment = await self.payment_repo.get_payment_by_transaction_id(str(order_id))
        else:
            # Neither format provided
            raise PaymeMerchantAPIError(
                self.ERROR_ACCOUNT_ERROR_MIN,
                "Неверный формат данных в поле account",
                {"reason": "missing_fields", "required": "order_id OR (phone_number, tariff_id, month_count) OR (phone_number, service_id, days_count)"}
            )
        
        if not payment:
            # Payment not found - use ERROR_ACCOUNT_ERROR_MIN for consistency
            # Note: According to Payme spec, -31050 to -31099 is for account errors
            # "Payment not found" could be considered an account error if the account params are wrong
            raise PaymeMerchantAPIError(
                self.ERROR_ACCOUNT_ERROR_MIN,
                "Заказ не найден",
                {"reason": "payment_not_found"}
            )
        
        # Refresh payment from database to ensure we have the latest metadata
        # This is important because the payment might have been updated in a previous request
        await self.session.refresh(payment)
        
        # Check payment status first - if already paid or cancelled, return appropriate error
        # This should be checked before checking for existing Payme transaction ID
        if payment.status == PaymentStatus.COMPLETED:
            raise PaymeMerchantAPIError(
                self.ERROR_ACCOUNT_ERROR_MIN,
                "Заказ уже оплачен",
                {"reason": "already_paid"}
            )
        
        if payment.status in [PaymentStatus.CANCELLED, PaymentStatus.FAILED]:
            raise PaymeMerchantAPIError(
                self.ERROR_ACCOUNT_ERROR_MIN,
                "Заказ отменен",
                {"reason": "cancelled"}
            )
        
        # Check if transaction with this Payme ID already exists
        # Store Payme transaction ID in payment metadata
        payment_metadata = payment.payment_metadata or {}
        
        # Check both transaction_id field and metadata for existing Payme transaction ID
        existing_payme_id = None
        if payment.transaction_id:
            # Check if transaction_id contains a Payme transaction ID (not our payment UUID)
            # Payme transaction IDs are typically 24-character hex strings
            # Our payment UUIDs are UUID format (with dashes)
            if len(payment.transaction_id) == 24 and all(c in '0123456789abcdef' for c in payment.transaction_id.lower()):
                existing_payme_id = payment.transaction_id
        
        # Also check metadata (for backward compatibility or if transaction_id has UUID)
        if not existing_payme_id and "payme_transaction_id" in payment_metadata:
            existing_payme_id = payment_metadata.get("payme_transaction_id")
        
        # If payment already has a Payme transaction ID, check if it's the same
        if existing_payme_id:
            if existing_payme_id == transaction_id:
                # Same transaction, return existing state
                # Use stored payme_create_time from metadata to ensure consistency with CheckTransaction
                stored_create_time = payment_metadata.get("payme_create_time")
                if stored_create_time is not None:
                    create_time = int(stored_create_time)
                else:
                    # Fallback to payment.created_at if metadata doesn't have it
                    create_time = int(payment.created_at.timestamp() * 1000)
                return {
                    "create_time": create_time,
                    "transaction": str(payment.id),
                    "state": self.STATE_CREATED
                }
            else:
                # Different transaction ID is trying to process the same account
                # Check if the existing transaction was never performed (no perform_time in metadata)
                # If payment is PENDING and existing transaction was never performed, we might allow updating
                # However, according to Payme spec, once a transaction is created, it's "processing" the account
                # So we should return -31050 (account being processed) unless the existing transaction was cancelled
                has_perform_time = "payme_perform_time" in payment_metadata
                has_cancel_time = "payme_cancel_time" in payment_metadata
                
                # If the existing transaction was never performed and never cancelled, it's still "processing"
                # But if it was cancelled, we might allow a new transaction
                # However, Payme spec says we should return -31050 for any existing transaction
                # So we'll stick to the spec and return -31050
                import logging
                logger = logging.getLogger(__name__)
                logger.warning(
                    f"Attempted to create transaction with new ID {transaction_id} "
                    f"for account already being processed by transaction {existing_payme_id}, "
                    f"Payment ID={payment.id}, Status={payment.status}, "
                    f"Has perform_time: {has_perform_time}, Has cancel_time: {has_cancel_time}"
                )
                raise PaymeMerchantAPIError(
                    self.ERROR_ACCOUNT_ERROR_MIN,
                    "Другая транзакция обрабатывает этот заказ",
                    {
                        "reason": "account_being_processed",
                        "message": "Another transaction is already processing this account",
                        "existing_transaction_id": existing_payme_id
                    }
                )
        
        # Check if payment can be created
        amount_tiyins = int(payment.amount * 100)
        if amount != amount_tiyins:
            raise PaymeMerchantAPIError(
                self.ERROR_INVALID_AMOUNT,
                "Неверная сумма платежа",
                {"reason": "amount"}
            )
        
        # Create transaction - update payment with Payme transaction ID
        # Store Payme transaction ID in both transaction_id field and metadata
        payment.transaction_id = transaction_id  # Use Payme's transaction ID
        payment_metadata["payme_transaction_id"] = transaction_id
        payment_metadata["payme_create_time"] = time_param
        
        # Update payment
        payment.payment_metadata = payment_metadata
        # Mark the JSON field as modified so SQLAlchemy persists it
        flag_modified(payment, "payment_metadata")
        
        # Store Payme transaction ID for later lookup
        # Commit the transaction to ensure it's persisted
        await self.session.commit()
        await self.session.refresh(payment)
        
        # Verify the transaction ID was stored correctly
        import logging
        logger = logging.getLogger(__name__)
        stored_metadata = payment.payment_metadata or {}
        stored_transaction_id = stored_metadata.get("payme_transaction_id")
        logger.debug(
            f"Created transaction: Payme ID={transaction_id}, Payment ID={payment.id}, "
            f"Stored Payme ID={stored_transaction_id}, Full metadata={stored_metadata}"
        )
        
        # Use time_param (stored as payme_create_time) to ensure consistency with CheckTransaction
        # This ensures CreateTransaction and CheckTransaction return the same create_time
        create_time = time_param if time_param is not None else int(payment.created_at.timestamp() * 1000)
        
        return {
            "create_time": create_time,
            "transaction": str(payment.id),
            "state": self.STATE_CREATED
        }
    
    async def perform_transaction(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        PerformTransaction - Проведение финансовой транзакции
        
        Completes the financial transaction, transferring funds to merchant account.
        
        Parameters:
            - id: Payme transaction ID
        
        Returns:
            Transaction details with transaction (order_id), perform_time, and state
        """
        transaction_id = params.get("id")  # Payme's transaction ID
        
        if not transaction_id:
            raise PaymeMerchantAPIError(
                -32602,
                "Неверный формат параметров",
                {"reason": "id"}
            )
        
        # Find payment by Payme transaction ID
        payment = await self._find_payment_by_payme_id(transaction_id)
        
        if not payment:
            raise PaymeMerchantAPIError(
                self.ERROR_TRANSACTION_NOT_FOUND,
                "Транзакция не найдена",
                {"reason": "transaction_id"}
            )
        
        # Check if already performed
        if payment.status == PaymentStatus.COMPLETED:
            # Transaction already completed, return current state
            payment_metadata = payment.payment_metadata or {}
            # Use stored perform_time or fallback to completed_at timestamp
            if "payme_perform_time" in payment_metadata:
                perform_time = payment_metadata.get("payme_perform_time")
            elif payment.completed_at:
                perform_time = int(payment.completed_at.timestamp() * 1000)
            else:
                # Fallback to created_at if completed_at is not set
                perform_time = int(payment.created_at.timestamp() * 1000)
            
            return {
                "transaction": str(payment.id),
                "perform_time": perform_time,
                "state": self.STATE_COMPLETED
            }
        
        # Check if payment can be performed
        if payment.status != PaymentStatus.PENDING:
            raise PaymeMerchantAPIError(
                self.ERROR_CANNOT_PERFORM_OPERATION,
                "Невозможно выполнить операцию",
                {"reason": f"invalid_status: {payment.status}"}
            )
        
        # Perform transaction - complete the payment
        perform_time = int(time.time() * 1000)
        
        payment.status = PaymentStatus.COMPLETED
        payment.completed_at = datetime.now()
        
        payment_metadata = payment.payment_metadata or {}
        payment_metadata["payme_perform_time"] = perform_time
        payment.payment_metadata = payment_metadata
        # Mark the JSON field as modified so SQLAlchemy persists it
        flag_modified(payment, "payment_metadata")
        
        await self.session.commit()
        await self.session.refresh(payment)

        # Process payment completion - create subscription or featured service
        try:
            await self._process_completed_payment(payment)
            await self.session.commit()
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to process completed payment {payment.id}: {str(e)}")
            # Don't fail the transaction - payment is already marked as completed
            # The subscription/featured service can be created manually or via retry

        return {
            "transaction": str(payment.id),
            "perform_time": perform_time,
            "state": self.STATE_COMPLETED
        }
    
    async def cancel_transaction(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        CancelTransaction - Отмена финансовой транзакции
        
        Cancels a created or completed transaction.
        
        Parameters:
            - id: Payme transaction ID
            - reason: Cancellation reason code
        
        Returns:
            Transaction details with transaction, cancel_time, and state
        """
        transaction_id = params.get("id")
        reason = params.get("reason", 4)  # Default reason: Other
        
        if not transaction_id:
            raise PaymeMerchantAPIError(
                -32602,
                "Неверный формат параметров",
                {"reason": "id"}
            )
        
        # Find payment by Payme transaction ID
        payment = await self._find_payment_by_payme_id(transaction_id)
        
        if not payment:
            raise PaymeMerchantAPIError(
                self.ERROR_TRANSACTION_NOT_FOUND,
                "Транзакция не найдена",
                {"reason": "transaction_id"}
            )
        
        # Refresh payment to ensure we have the latest metadata
        await self.session.refresh(payment)
        
        # Check if already cancelled - return idempotent result
        if payment.status in [PaymentStatus.CANCELLED, PaymentStatus.FAILED]:
            payment_metadata = payment.payment_metadata or {}
            import logging
            logger = logging.getLogger(__name__)
            
            # Check if metadata needs to be saved (missing cancel_time or reason)
            metadata_needs_update = False
            
            # Use stored cancel_time from metadata (must be present if already cancelled)
            # This ensures idempotency - same cancel_time returned for repeated calls
            if "payme_cancel_time" in payment_metadata:
                cancel_time = payment_metadata.get("payme_cancel_time")
                logger.debug(
                    f"CancelTransaction (idempotent): Using stored cancel_time={cancel_time} "
                    f"from metadata for payment {payment.id}, Payme ID={transaction_id}"
                )
            else:
                # Metadata is missing - this shouldn't happen, but we'll fix it
                # Use completed_at or created_at as fallback, but also save it to metadata
                if payment.completed_at:
                    cancel_time = int(payment.completed_at.timestamp() * 1000)
                else:
                    cancel_time = int(payment.created_at.timestamp() * 1000)
                
                logger.warning(
                    f"CancelTransaction (idempotent): cancel_time not in metadata, "
                    f"using fallback={cancel_time} for payment {payment.id}, "
                    f"Payme ID={transaction_id}, Metadata keys: {list(payment_metadata.keys())}. "
                    f"Saving metadata now..."
                )
                
                # Save missing metadata to fix the issue
                payment_metadata["payme_cancel_time"] = cancel_time
                metadata_needs_update = True
            
            # Ensure reason is also present in metadata
            if "payme_cancel_reason" not in payment_metadata:
                payment_metadata["payme_cancel_reason"] = int(reason) if reason is not None else None
                metadata_needs_update = True
            
            # Save metadata if it was updated
            if metadata_needs_update:
                payment.payment_metadata = payment_metadata
                # Mark the JSON field as modified so SQLAlchemy persists it
                flag_modified(payment, "payment_metadata")
                await self.session.commit()
                # Don't refresh here - it starts a new transaction that might get rolled back
                # The metadata is already updated in payment_metadata dict
            
            # Determine state: if payment was completed before cancellation, return -2, otherwise -1
            # Check if payment was completed by looking at completed_at or payme_perform_time in metadata
            was_completed = (
                payment.completed_at is not None or 
                "payme_perform_time" in payment_metadata
            )
            state = self.STATE_CANCELLED_AFTER_COMPLETION if was_completed else self.STATE_CANCELLED
            
            return {
                "transaction": str(payment.id),
                "cancel_time": cancel_time,
                "state": state
            }
        
        # Cancel transaction
        cancel_time = int(time.time() * 1000)
        
        # If already completed, mark as cancelled after completion
        if payment.status == PaymentStatus.COMPLETED:
            payment.status = PaymentStatus.CANCELLED
            state = self.STATE_CANCELLED_AFTER_COMPLETION
        else:
            payment.status = PaymentStatus.CANCELLED
            state = self.STATE_CANCELLED
        
        payment_metadata = payment.payment_metadata or {}
        payment_metadata["payme_cancel_time"] = cancel_time
        # Ensure reason is stored as integer
        payment_metadata["payme_cancel_reason"] = int(reason) if reason is not None else None
        payment.payment_metadata = payment_metadata
        # Mark the JSON field as modified so SQLAlchemy persists it
        flag_modified(payment, "payment_metadata")
        
        await self.session.commit()
        # Don't refresh here - it starts a new transaction that might get rolled back
        # The metadata is already updated in payment_metadata dict
        
        # Verify the reason was stored correctly (using the dict we just updated)
        import logging
        logger = logging.getLogger(__name__)
        stored_reason = payment_metadata.get("payme_cancel_reason")
        logger.debug(
            f"Cancelled transaction: Payme ID={transaction_id}, Payment ID={payment.id}, "
            f"Reason={reason}, Stored reason={stored_reason}, Full metadata={payment_metadata}"
        )
        
        return {
            "transaction": str(payment.id),
            "cancel_time": cancel_time,
            "state": state
        }
    
    async def check_transaction(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        CheckTransaction - Проверка состояния финансовой транзакции
        
        Checks the state of a financial transaction.
        
        Parameters:
            - id: Payme transaction ID
        
        Returns:
            Full transaction details with all timestamps and state
        """
        transaction_id = params.get("id")
        
        if not transaction_id:
            raise PaymeMerchantAPIError(
                -32602,
                "Неверный формат параметров",
                {"reason": "id"}
            )
        
        # Find payment by Payme transaction ID
        payment = await self._find_payment_by_payme_id(transaction_id)
        
        if not payment:
            raise PaymeMerchantAPIError(
                self.ERROR_TRANSACTION_NOT_FOUND,
                "Транзакция не найдена",
                {"reason": "transaction_id"}
            )
        
        # Refresh payment to ensure we have the latest metadata
        await self.session.refresh(payment)
        
        payment_metadata = payment.payment_metadata or {}
        
        # Determine transaction state
        if payment.status == PaymentStatus.COMPLETED:
            state = self.STATE_COMPLETED
        elif payment.status in [PaymentStatus.CANCELLED, PaymentStatus.FAILED]:
            # Check if was completed before cancellation
            # Check if payment was completed by looking at completed_at or payme_perform_time
            was_completed = (
                payment.completed_at is not None or 
                "payme_perform_time" in payment_metadata
            )
            state = self.STATE_CANCELLED_AFTER_COMPLETION if was_completed else self.STATE_CANCELLED
        else:
            state = self.STATE_CREATED
        
        # Get timestamps
        # Use stored payme_create_time from metadata to ensure consistency with CreateTransaction
        stored_create_time = payment_metadata.get("payme_create_time")
        if stored_create_time is not None:
            try:
                create_time = int(stored_create_time)
            except (ValueError, TypeError):
                # If conversion fails, fallback to payment.created_at
                create_time = int(payment.created_at.timestamp() * 1000)
        else:
            # Fallback to payment.created_at if metadata doesn't have it
            create_time = int(payment.created_at.timestamp() * 1000)
        
        # Get perform_time - use metadata if available, otherwise fallback to completed_at
        # For cancelled transactions that were completed, we should still show perform_time
        perform_time = 0
        if payment.status == PaymentStatus.COMPLETED:
            if "payme_perform_time" in payment_metadata:
                perform_time = payment_metadata.get("payme_perform_time")
            elif payment.completed_at:
                perform_time = int(payment.completed_at.timestamp() * 1000)
        elif payment.status in [PaymentStatus.CANCELLED, PaymentStatus.FAILED]:
            # If cancelled but was completed before cancellation, show perform_time
            if "payme_perform_time" in payment_metadata:
                perform_time = payment_metadata.get("payme_perform_time")
            elif payment.completed_at:
                perform_time = int(payment.completed_at.timestamp() * 1000)
        
        # Get cancel_time - use metadata if available, otherwise fallback to completed_at or created_at
        cancel_time = 0
        if payment.status in [PaymentStatus.CANCELLED, PaymentStatus.FAILED]:
            if "payme_cancel_time" in payment_metadata:
                cancel_time = payment_metadata.get("payme_cancel_time")
            elif payment.completed_at:
                cancel_time = int(payment.completed_at.timestamp() * 1000)
            else:
                cancel_time = int(payment.created_at.timestamp() * 1000)
        
        # Get cancellation reason - should be present if transaction is cancelled
        reason = None
        if payment.status in [PaymentStatus.CANCELLED, PaymentStatus.FAILED]:
            reason = payment_metadata.get("payme_cancel_reason")
            # Ensure reason is an integer if present
            if reason is not None:
                try:
                    reason = int(reason)
                except (ValueError, TypeError):
                    # If conversion fails, keep original value
                    pass
            # If reason is still None but transaction is cancelled, log a warning
            if reason is None:
                import logging
                logger = logging.getLogger(__name__)
                logger.warning(
                    f"CheckTransaction: Payment {payment.id} is cancelled but reason is None. "
                    f"Metadata: {payment_metadata}"
                )
        
        return {
            "create_time": create_time,
            "perform_time": perform_time,
            "cancel_time": cancel_time,
            "transaction": str(payment.id),
            "state": state,
            "reason": reason
        }
    
    async def get_statement(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        GetStatement - Получение списка транзакций за период
        
        Returns a list of transactions for a specified period.
        Only includes transactions where CreateTransaction was successfully executed.
        
        Parameters:
            - from: Start timestamp (milliseconds)
            - to: End timestamp (milliseconds)
        
        Returns:
            List of transactions sorted by creation time (ascending)
        """
        from_time = params.get("from")
        to_time = params.get("to")
        
        # Validate required parameters
        if from_time is None or to_time is None:
            raise PaymeMerchantAPIError(
                -32602,
                "Неверный формат параметров",
                {"reason": "missing_fields", "required": ["from", "to"]}
            )
        
        if not isinstance(from_time, int) or not isinstance(to_time, int):
            raise PaymeMerchantAPIError(
                -32602,
                "Неверный формат параметров",
                {"reason": "invalid_type", "message": "from and to must be integers (timestamps in milliseconds)"}
            )
        
        if from_time > to_time:
            raise PaymeMerchantAPIError(
                -32602,
                "Неверный формат параметров",
                {"reason": "invalid_range", "message": "from must be less than or equal to to"}
            )
        
        # Query all Payme payments that have a transaction_id
        # A transaction_id exists only if CreateTransaction succeeded
        # Payme transaction IDs are 24-character hex strings
        from sqlalchemy import and_, or_, func
        import logging
        logger = logging.getLogger(__name__)
        
        # Query Payme payments with transaction_id (meaning CreateTransaction succeeded)
        # Payme transaction IDs are 24-character hex strings
        # We query all Payme payments with non-null transaction_id, then filter in Python
        # to ensure we only include those with valid Payme transaction IDs
        stmt = select(Payment).where(
            and_(
                Payment.payment_method == PaymentMethod.PAYME,
                Payment.transaction_id.isnot(None)
            )
        ).order_by(Payment.created_at.asc())
        
        result = await self.session.execute(stmt)
        all_payments = result.scalars().all()
        
        logger.debug(f"GetStatement: Found {len(all_payments)} Payme payments with transaction_id")
        
        transactions = []
        
        for payment in all_payments:
            payment_metadata = payment.payment_metadata or {}
            
            # Get creation time from metadata (payme_create_time) or fallback to created_at
            create_time = payment_metadata.get("payme_create_time")
            if create_time is None:
                # Fallback to created_at timestamp
                create_time = int(payment.created_at.timestamp() * 1000)
            else:
                # Ensure it's an integer
                try:
                    create_time = int(create_time)
                except (ValueError, TypeError):
                    create_time = int(payment.created_at.timestamp() * 1000)
            
            # Filter by time range: from <= create_time <= to
            if create_time < from_time or create_time > to_time:
                continue
            
            # Only include if transaction_id is a Payme transaction ID (24-char hex)
            # This ensures CreateTransaction succeeded
            payme_transaction_id = None
            if payment.transaction_id:
                # Check if it's a Payme transaction ID (24-char hex string)
                if len(payment.transaction_id) == 24 and all(c in '0123456789abcdef' for c in payment.transaction_id.lower()):
                    payme_transaction_id = payment.transaction_id
                elif "payme_transaction_id" in payment_metadata:
                    payme_transaction_id = payment_metadata.get("payme_transaction_id")
            
            # Skip if no valid Payme transaction ID found
            if not payme_transaction_id:
                continue
            
            # Get perform_time
            perform_time = 0
            if payment.status == PaymentStatus.COMPLETED:
                if "payme_perform_time" in payment_metadata:
                    perform_time = payment_metadata.get("payme_perform_time")
                elif payment.completed_at:
                    perform_time = int(payment.completed_at.timestamp() * 1000)
            elif payment.status in [PaymentStatus.CANCELLED, PaymentStatus.FAILED]:
                # If cancelled but was completed before cancellation, show perform_time
                if "payme_perform_time" in payment_metadata:
                    perform_time = payment_metadata.get("payme_perform_time")
                elif payment.completed_at:
                    perform_time = int(payment.completed_at.timestamp() * 1000)
            
            # Get cancel_time
            cancel_time = 0
            if payment.status in [PaymentStatus.CANCELLED, PaymentStatus.FAILED]:
                if "payme_cancel_time" in payment_metadata:
                    cancel_time = payment_metadata.get("payme_cancel_time")
                elif payment.completed_at:
                    cancel_time = int(payment.completed_at.timestamp() * 1000)
                else:
                    cancel_time = int(payment.created_at.timestamp() * 1000)
            
            # Get reason
            reason = None
            if payment.status in [PaymentStatus.CANCELLED, PaymentStatus.FAILED]:
                reason = payment_metadata.get("payme_cancel_reason")
                if reason is not None:
                    try:
                        reason = int(reason)
                    except (ValueError, TypeError):
                        pass
            
            # Determine state
            if payment.status == PaymentStatus.COMPLETED:
                state = self.STATE_COMPLETED
            elif payment.status in [PaymentStatus.CANCELLED, PaymentStatus.FAILED]:
                was_completed = (
                    payment.completed_at is not None or 
                    "payme_perform_time" in payment_metadata
                )
                state = self.STATE_CANCELLED_AFTER_COMPLETION if was_completed else self.STATE_CANCELLED
            else:
                state = self.STATE_CREATED
            
            # Build account information
            account = {}
            # Check if we have phone_number, tariff_id, month_count (new format)
            if "phone_number" in payment_metadata:
                account["phone_number"] = payment_metadata.get("phone_number")
            if "tariff_id" in payment_metadata:
                account["tariff_id"] = payment_metadata.get("tariff_id")
            if "month_count" in payment_metadata:
                account["month_count"] = payment_metadata.get("month_count")
            
            # If no account info in metadata, try to extract from payment
            # For legacy payments, we might not have this info
            if not account:
                # Try to use payment ID as order_id for backward compatibility
                account["order_id"] = str(payment.id)
            
            # Build transaction object
            transaction = {
                "id": payme_transaction_id,
                "time": create_time,
                "amount": int(payment.amount * 100),  # Convert to tiyins
                "account": account,
                "create_time": create_time,
                "perform_time": perform_time,
                "cancel_time": cancel_time,
                "transaction": str(payment.id),  # Our payment ID (order_id)
                "state": state,
                "reason": reason
            }
            
            # Note: receivers field is for split payments (not implemented in our system)
            # We can add an empty array or omit it
            
            transactions.append(transaction)
        
        # Sort by create_time ascending (should already be sorted, but ensure it)
        transactions.sort(key=lambda t: t["create_time"])
        
        logger.debug(f"GetStatement: Returning {len(transactions)} transactions for period {from_time} to {to_time}")
        
        return {
            "transactions": transactions
        }
    
    async def _find_payment_by_payme_id(self, payme_transaction_id: str) -> Optional[Payment]:
        """
        Find payment by Payme transaction ID.
        
        First tries to find by transaction_id field (where we store Payme's transaction ID),
        then falls back to searching metadata for backward compatibility.
        """
        import logging
        logger = logging.getLogger(__name__)
        logger.debug(f"Searching for payment with Payme transaction ID: {payme_transaction_id}")
        
        # First, try to find by transaction_id field (where we now store Payme's transaction ID)
        from sqlalchemy import and_
        stmt = select(Payment).where(
            and_(
                Payment.payment_method == PaymentMethod.PAYME,
                Payment.transaction_id == payme_transaction_id
            )
        )
        result = await self.session.execute(stmt)
        payment = result.scalar_one_or_none()
        
        if payment:
            logger.debug(
                f"Found payment by transaction_id: Payment ID={payment.id}, "
                f"Payme transaction ID={payme_transaction_id}, Status={payment.status}"
            )
            return payment
        
        # Fallback: search through metadata for backward compatibility
        # (in case there are old payments that only have it in metadata)
        logger.debug("Not found by transaction_id, searching metadata...")
        stmt = select(Payment).where(
            Payment.payment_method == PaymentMethod.PAYME
        )
        result = await self.session.execute(stmt)
        payments = result.scalars().all()
        
        logger.debug(f"Found {len(payments)} Payme payments to search through")
        
        for payment in payments:
            payment_metadata = payment.payment_metadata or {}
            stored_transaction_id = payment_metadata.get("payme_transaction_id")
            if stored_transaction_id == payme_transaction_id:
                logger.debug(
                    f"Found payment by metadata: Payment ID={payment.id}, "
                    f"Payme transaction ID={stored_transaction_id}, "
                    f"Status={payment.status}"
                )
                return payment
        
        logger.warning(f"No payment found with Payme transaction ID: {payme_transaction_id}")
        return None

    async def _process_completed_payment(self, payment: Payment):
        """
        Process a completed payment to create subscription or featured service.

        This is called after PerformTransaction successfully marks a payment as completed.
        """
        import logging
        logger = logging.getLogger(__name__)

        payment_metadata = payment.payment_metadata or {}

        if payment.payment_type == PaymentType.TARIFF_SUBSCRIPTION:
            await self._activate_tariff_subscription(payment, payment_metadata)
        elif payment.payment_type == PaymentType.FEATURED_SERVICE:
            await self._activate_featured_service(payment, payment_metadata)
        else:
            logger.warning(f"Unknown payment type for payment {payment.id}: {payment.payment_type}")

    async def _activate_tariff_subscription(self, payment: Payment, metadata: Dict[str, Any]):
        """Activate tariff subscription after successful payment."""
        import logging
        logger = logging.getLogger(__name__)

        duration_months = metadata.get('month_count') or metadata.get('duration_months', 1)
        if isinstance(duration_months, str):
            duration_months = int(duration_months)

        tariff_plan_id_str = metadata.get('tariff_id') or metadata.get('tariff_plan_id')

        # Find merchant
        merchant_stmt = select(Merchant).where(Merchant.user_id == payment.user_id)
        merchant_result = await self.session.execute(merchant_stmt)
        merchant = merchant_result.scalar_one_or_none()

        if not merchant:
            logger.error(f"Merchant not found for payment {payment.id}, user_id={payment.user_id}")
            raise PaymeMerchantAPIError(-31050, "Merchant not found")

        # Find tariff plan
        if tariff_plan_id_str:
            tariff_plan_id = UUID(str(tariff_plan_id_str))
            plan = await self.payment_repo.get_tariff_plan_by_id(tariff_plan_id)
        else:
            logger.error(f"Tariff plan ID not found in payment metadata for payment {payment.id}")
            raise PaymeMerchantAPIError(-31050, "Tariff plan ID not found")

        if not plan:
            logger.error(f"Tariff plan {tariff_plan_id_str} not found for payment {payment.id}")
            raise PaymeMerchantAPIError(-31050, "Tariff plan not found")

        # Check if subscription already exists for this payment
        existing_sub_stmt = select(MerchantSubscription).where(
            MerchantSubscription.payment_id == payment.id
        )
        existing_sub_result = await self.session.execute(existing_sub_stmt)
        existing_subscription = existing_sub_result.scalar_one_or_none()

        if existing_subscription:
            logger.info(f"Subscription already exists for payment {payment.id}")
            return

        # Expire any existing active subscriptions
        active_subs_stmt = select(MerchantSubscription).where(
            MerchantSubscription.merchant_id == merchant.id,
            MerchantSubscription.status == SubscriptionStatus.ACTIVE
        )
        active_subs_result = await self.session.execute(active_subs_stmt)
        active_subscriptions = active_subs_result.scalars().all()

        for sub in active_subscriptions:
            sub.status = SubscriptionStatus.CANCELLED
            self.session.add(sub)

        # Create new subscription
        start_date = datetime.now()
        end_date = start_date + relativedelta(months=duration_months)

        subscription = MerchantSubscription(
            merchant_id=merchant.id,
            tariff_plan_id=plan.id,
            payment_id=payment.id,
            status=SubscriptionStatus.ACTIVE,
            start_date=start_date,
            end_date=end_date,
            duration_months=duration_months,
            amount_paid=payment.amount,
            auto_renewal=False
        )

        self.session.add(subscription)
        await self.session.flush()

        logger.info(
            f"Activated tariff subscription for merchant {merchant.id}, "
            f"plan={plan.name}, duration={duration_months} months, "
            f"end_date={end_date}"
        )

    async def _activate_featured_service(self, payment: Payment, metadata: Dict[str, Any]):
        """Activate featured service after successful payment."""
        import logging
        logger = logging.getLogger(__name__)

        service_id_str = metadata.get('service_id')
        duration_days = metadata.get('days_count') or metadata.get('duration_days', 7)
        if isinstance(duration_days, str):
            duration_days = int(duration_days)

        if not service_id_str:
            logger.error(f"Service ID not found in payment metadata for payment {payment.id}")
            raise PaymeMerchantAPIError(-31050, "Service ID not found")

        # Find service
        service_stmt = select(Service).where(Service.id == str(service_id_str))
        service_result = await self.session.execute(service_stmt)
        service = service_result.scalar_one_or_none()

        if not service:
            logger.error(f"Service {service_id_str} not found for payment {payment.id}")
            raise PaymeMerchantAPIError(-31050, "Service not found")

        # Check if featured service already exists for this payment
        existing_fs_stmt = select(FeaturedService).where(
            FeaturedService.payment_id == payment.id
        )
        existing_fs_result = await self.session.execute(existing_fs_stmt)
        existing_featured = existing_fs_result.scalar_one_or_none()

        if existing_featured:
            logger.info(f"Featured service already exists for payment {payment.id}")
            return

        # Create featured service record
        start_date = datetime.now()
        end_date = start_date + timedelta(days=duration_days)

        featured_service = FeaturedService(
            service_id=service.id,
            merchant_id=service.merchant_id,
            payment_id=payment.id,
            start_date=start_date,
            end_date=end_date,
            days_duration=duration_days,
            amount_paid=payment.amount,
            feature_type=FeatureType.PAID_FEATURE,
            is_active=True
        )

        self.session.add(featured_service)
        await self.session.flush()

        logger.info(
            f"Activated featured service for service {service.id}, "
            f"duration={duration_days} days, end_date={end_date}"
        )
