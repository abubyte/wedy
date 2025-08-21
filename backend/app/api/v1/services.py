from fastapi import APIRouter

router = APIRouter()

@router.get("/categories")
async def get_service_categories():
    """Get all service categories."""
    return {"message": "Service categories endpoint - TODO"}

@router.get("/")
async def browse_services():
    """Browse services by category."""
    return {"message": "Browse services endpoint - TODO"}

@router.get("/search")
async def search_services():
    """Search services with filters."""
    return {"message": "Search services endpoint - TODO"}

@router.get("/featured")
async def get_featured_services():
    """Get featured services."""
    return {"message": "Featured services endpoint - TODO"}

@router.get("/{service_id}")
async def get_service_details():
    """Get service details."""
    return {"message": "Service details endpoint - TODO"}
