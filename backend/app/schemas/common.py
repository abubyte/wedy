from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class PaginationParams(BaseModel):
    """Standard pagination parameters."""
    page: int = Field(1, ge=1, description="Page number (1-based)")
    limit: int = Field(20, ge=1, le=100, description="Items per page")
    
    @property
    def offset(self) -> int:
        """Calculate offset for database queries."""
        return (self.page - 1) * self.limit


class SuccessResponse(BaseModel):
    """Standard success response."""
    success: bool = True
    message: str
    data: Optional[Dict[str, Any]] = None


class ErrorResponse(BaseModel):
    """Standard error response."""
    success: bool = False
    message: str
    details: Optional[Dict[str, Any]] = None
    error_code: Optional[str] = None


class LocationFilter(BaseModel):
    """Location-based filtering."""
    region: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    radius_km: Optional[float] = None


class PriceRange(BaseModel):
    """Price range filter."""
    min_price: Optional[float] = Field(None, ge=0)
    max_price: Optional[float] = Field(None, ge=0)
    
    def __post_init__(self):
        if self.min_price and self.max_price and self.min_price > self.max_price:
            raise ValueError("min_price cannot be greater than max_price")
