from fastapi import APIRouter

router = APIRouter()

@router.get("/categories")
async def get_categories():
    """Get all categories (admin)."""
    return {"message": "Admin categories endpoint - TODO"} # TODO

@router.post("/categories")
async def create_category():
    """Create new category."""
    return {"message": "Create category endpoint - TODO"}

@router.get("/tariffs")
async def get_tariffs():
    """Get all tariff plans (admin)."""
    return {"message": "Admin tariffs endpoint - TODO"}

@router.post("/tariffs")
async def create_tariff():
    """Create new tariff plan."""
    return {"message": "Create tariff endpoint - TODO"}