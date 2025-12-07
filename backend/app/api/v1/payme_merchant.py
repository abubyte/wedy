"""
Payme Merchant API Endpoint

This endpoint receives JSON-RPC 2.0 requests from Payme server.
Implements the full Merchant API according to Payme documentation.
"""
from fastapi import APIRouter, Depends, Request, HTTPException, Header, Body
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any, Optional

from app.core.database import get_db_session
from app.core.config import get_settings
from app.services.payme_merchant_api import PaymeMerchantAPI


router = APIRouter()
settings = get_settings()


@router.post("/payme/merchant")
async def payme_merchant_api(
    request: Request,
    authorization: Optional[str] = Header(None, alias="Authorization"),
    session: AsyncSession = Depends(get_db_session)
):
    """
    Payme Merchant API endpoint.
    
    Receives JSON-RPC 2.0 requests from Payme server and handles:
    - CheckPerformTransaction
    - CreateTransaction
    - PerformTransaction
    - CancelTransaction
    - CheckTransaction
    
    Request format (JSON-RPC 2.0):
    {
        "id": "request-id",
        "method": "MethodName",
        "params": {...}
    }
    
    Response format:
    {
        "id": "request-id",
        "result": {...} or null,
        "error": {...} or null
    }
    """
    try:
        # Get request body
        request_data = await request.json()
        
        # Initialize Merchant API handler
        merchant_api = PaymeMerchantAPI(
            session=session,
            secret_key=settings.PAYME_SECRET_KEY
        )
        
        # Verify request signature
        if not authorization:
            return {
                "id": request_data.get("id"),
                "result": None,
                "error": {
                    "code": -32504,
                    "message": "Неверная авторизация",
                    "data": {}
                }
            }
        
        if not merchant_api.verify_request(request_data, authorization):
            return {
                "id": request_data.get("id"),
                "result": None,
                "error": {
                    "code": -32504,
                    "message": "Неверная авторизация",
                    "data": {}
                }
            }
        
        # Handle request
        response = await merchant_api.handle_request(request_data)
        return response
        
    except Exception as e:
        # Return error response
        return {
            "id": request_data.get("id") if 'request_data' in locals() else None,
            "result": None,
            "error": {
                "code": -32603,
                "message": f"Internal error: {str(e)}",
                "data": {}
            }
        }
