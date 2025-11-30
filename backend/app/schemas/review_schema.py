from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List
from uuid import UUID
from datetime import datetime


class ReviewCreateRequest(BaseModel):
    """Request schema for creating a review."""
    service_id: UUID = Field(..., description="ID of the service being reviewed")
    rating: int = Field(..., ge=1, le=5, description="Rating from 1 to 5 stars")
    comment: Optional[str] = Field(None, max_length=2000, description="Review comment")


class ReviewUpdateRequest(BaseModel):
    """Request schema for updating a review."""
    rating: Optional[int] = Field(None, ge=1, le=5, description="Rating from 1 to 5 stars")
    comment: Optional[str] = Field(None, max_length=2000, description="Review comment")


class ReviewUserResponse(BaseModel):
    """User information in review response."""
    model_config = ConfigDict(from_attributes=True)
    
    id: UUID
    name: str
    avatar_url: Optional[str] = None


class ReviewServiceResponse(BaseModel):
    """Service information in review response."""
    model_config = ConfigDict(from_attributes=True)
    
    id: UUID
    name: str


class ReviewDetailResponse(BaseModel):
    """Detailed review response schema."""
    model_config = ConfigDict(from_attributes=True)
    
    id: UUID
    service_id: UUID
    user_id: UUID
    merchant_id: UUID
    rating: int
    comment: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime
    user: Optional[ReviewUserResponse] = None
    service: Optional[ReviewServiceResponse] = None


class ReviewListResponse(BaseModel):
    """Paginated review list response."""
    reviews: List[ReviewDetailResponse]
    total: int
    page: int
    limit: int
    has_more: bool
    total_pages: int

