from fastapi import APIRouter

router = APIRouter()

@router.get("/services/{service_id}/reviews")
async def get_service_reviews():
    """Get service reviews."""
    return {"message": "Service reviews endpoint - TODO"} # TODO

@router.post("/")
async def create_review():
    """Create new review."""
    return {"message": "Create review endpoint - TODO"}