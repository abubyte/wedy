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
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.config import get_settings
from app.models.payment_model import Payment, PaymentStatus, PaymentMethod
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
            
            # Extract merchant_id and signature from Authorization header
            if not authorization.startswith("Basic "):
                return False
            
            auth_string = authorization[6:]  # Remove "Basic "
            decoded = base64.b64decode(auth_string).decode()
            
            if ":" not in decoded:
                return False
            
            merchant_id, signature = decoded.split(":", 1)
            
            # Calculate expected signature using raw body (exact format)
            expected_signature = hmac.new(
                self.secret_key.encode(),
                raw_body.encode('utf-8'),
                hashlib.sha256
            ).hexdigest()
            
            return hmac.compare_digest(signature, expected_signature)
            
        except Exception:
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
            else:
                raise PaymeMerchantAPIError(
                    -32601,
                    f"Method not found: {method}"
                )
            
            return {
                "id": request_id,
                "result": result,
                "error": None
            }
            
        except PaymeMerchantAPIError as e:
            return {
                "id": request_id,
                "result": None,
                "error": {
                    "code": e.code,
                    "message": e.message,
                    "data": e.data
                }
            }
        except Exception as e:
            return {
                "id": request_id,
                "result": None,
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
        
        # Validate account (order_id is required)
        order_id = account.get("order_id")
        if not order_id:
            raise PaymeMerchantAPIError(
                self.ERROR_ACCOUNT_ERROR_MIN,
                "Неверный формат данных в поле account",
                {"reason": "order_id"}
            )
        
        # Check if payment exists and can be paid
        payment = await self.payment_repo.get_payment_by_transaction_id(str(order_id))
        
        if not payment:
            raise PaymeMerchantAPIError(
                self.ERROR_ACCOUNT_ERROR_MIN + 1,
                "Заказ не найден",
                {"reason": "order_id"}
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
        amount_tiyins = int(payment.amount * 100)
        
        # Verify amount matches
        if amount != amount_tiyins:
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
        
        order_id = account.get("order_id")
        if not order_id:
            raise PaymeMerchantAPIError(
                self.ERROR_ACCOUNT_ERROR_MIN,
                "Неверный формат данных в поле account",
                {"reason": "order_id"}
            )
        
        # Find payment by order_id (transaction_id in our system)
        payment = await self.payment_repo.get_payment_by_transaction_id(str(order_id))
        
        if not payment:
            raise PaymeMerchantAPIError(
                self.ERROR_ACCOUNT_ERROR_MIN + 1,
                "Заказ не найден",
                {"reason": "order_id"}
            )
        
        # Check if transaction with this Payme ID already exists
        # Store Payme transaction ID in payment metadata
        payment_metadata = payment.payment_metadata or {}
        
        # If payment already has a Payme transaction ID, check if it's the same
        if "payme_transaction_id" in payment_metadata:
            existing_payme_id = payment_metadata.get("payme_transaction_id")
            if existing_payme_id == transaction_id:
                # Same transaction, return existing state
                return {
                    "create_time": int(payment.created_at.timestamp() * 1000),
                    "transaction": str(payment.id),
                    "state": self.STATE_CREATED
                }
            else:
                # Different transaction ID - error
                raise PaymeMerchantAPIError(
                    self.ERROR_CANNOT_PERFORM_OPERATION,
                    "Невозможно выполнить операцию",
                    {"reason": "transaction_exists"}
                )
        
        # Check if payment can be created
        amount_tiyins = int(payment.amount * 100)
        if amount != amount_tiyins:
            raise PaymeMerchantAPIError(
                self.ERROR_INVALID_AMOUNT,
                "Неверная сумма платежа",
                {"reason": "amount"}
            )
        
        # Check if already paid
        if payment.status == PaymentStatus.COMPLETED:
            raise PaymeMerchantAPIError(
                self.ERROR_CANNOT_PERFORM_OPERATION,
                "Заказ уже оплачен",
                {"reason": "already_paid"}
            )
        
        # Create transaction - update payment metadata with Payme transaction ID
        payment_metadata["payme_transaction_id"] = transaction_id
        payment_metadata["payme_create_time"] = time_param
        
        # Update payment
        payment.payment_metadata = payment_metadata
        
        # Store Payme transaction ID for later lookup
        # We can use a separate field or store in metadata
        await self.session.commit()
        await self.session.refresh(payment)
        
        return {
            "create_time": int(payment.created_at.timestamp() * 1000),
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
            perform_time = payment_metadata.get("payme_perform_time", 
                                                int(payment.updated_at.timestamp() * 1000))
            
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
        
        await self.session.commit()
        await self.session.refresh(payment)
        
        # Process payment completion (create subscription, feature service, etc.)
        # This should be done asynchronously or via background task
        # For now, we'll mark it as completed and process later
        
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
        
        # Check if already cancelled
        if payment.status in [PaymentStatus.CANCELLED, PaymentStatus.FAILED]:
            payment_metadata = payment.payment_metadata or {}
            cancel_time = payment_metadata.get("payme_cancel_time",
                                              int(payment.updated_at.timestamp() * 1000))
            state = self.STATE_CANCELLED_AFTER_COMPLETION if payment.status == PaymentStatus.COMPLETED else self.STATE_CANCELLED
            
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
        payment_metadata["payme_cancel_reason"] = reason
        payment.payment_metadata = payment_metadata
        
        await self.session.commit()
        await self.session.refresh(payment)
        
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
        
        payment_metadata = payment.payment_metadata or {}
        
        # Determine transaction state
        if payment.status == PaymentStatus.COMPLETED:
            state = self.STATE_COMPLETED
        elif payment.status in [PaymentStatus.CANCELLED, PaymentStatus.FAILED]:
            # Check if was completed before cancellation
            state = self.STATE_CANCELLED_AFTER_COMPLETION if payment.completed_at else self.STATE_CANCELLED
        else:
            state = self.STATE_CREATED
        
        # Get timestamps
        create_time = payment_metadata.get("payme_create_time",
                                          int(payment.created_at.timestamp() * 1000))
        perform_time = payment_metadata.get("payme_perform_time", 0) if payment.status == PaymentStatus.COMPLETED else 0
        cancel_time = payment_metadata.get("payme_cancel_time", 0) if payment.status in [PaymentStatus.CANCELLED, PaymentStatus.FAILED] else 0
        reason = payment_metadata.get("payme_cancel_reason") if cancel_time > 0 else None
        
        return {
            "create_time": create_time,
            "perform_time": perform_time,
            "cancel_time": cancel_time,
            "transaction": str(payment.id),
            "state": state,
            "reason": reason
        }
    
    async def _find_payment_by_payme_id(self, payme_transaction_id: str) -> Optional[Payment]:
        """
        Find payment by Payme transaction ID stored in payment_metadata.
        
        Since Payme transaction ID is stored in metadata, we need to search through payments.
        """
        # Query payments and filter by metadata
        # This is a simplified version - in production, consider adding an index or separate field
        stmt = select(Payment).where(
            Payment.payment_method == PaymentMethod.PAYME
        )
        
        result = await self.session.execute(stmt)
        payments = result.scalars().all()
        
        for payment in payments:
            payment_metadata = payment.payment_metadata or {}
            if payment_metadata.get("payme_transaction_id") == payme_transaction_id:
                return payment
        
        return None

