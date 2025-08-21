from fastapi import APIRouter

router = APIRouter()

@router.get("/profile")
async def get_merchant_profile():
    """Get merchant profile."""
    return {"message": "Merchant profile endpoint - TODO"}

@router.put("/profile")
async def update_merchant_profile():
    """Update merchant profile."""
    return {"message": "Update merchant profile endpoint - TODO"}

@router.get("/services")
async def get_merchant_services():
    """Get merchant's services."""
    return {"message": "Merchant services endpoint - TODO"}

@router.post("/services")
async def create_service():
    """Create new service."""
    return {"message": "Create service endpoint - TODO"}