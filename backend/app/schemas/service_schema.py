from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class ServiceCategoryResponse(BaseModel):
    """Service category response schema."""
    id: int  # ServiceCategory.id is auto-incrementing integer
    name: str
    description: Optional[str] = None
    icon_url: Optional[str] = None
    display_order: int
    service_count: int = 0


class ServiceCategoriesResponse(BaseModel):
    """Response schema for service categories list."""
    categories: List[ServiceCategoryResponse]
    total: int


class ServiceImageResponse(BaseModel):
    """Service image response schema."""
    id: UUID  # Image.id is UUID, Pydantic will serialize to string in JSON
    s3_url: str
    file_name: str
    display_order: int


class MerchantBasicInfo(BaseModel):
    """Basic merchant information for service listings."""
    id: UUID  # Pydantic will automatically serialize UUID to string in JSON
    business_name: str
    overall_rating: float
    total_reviews: int
    location_region: str
    is_verified: bool
    avatar_url: Optional[str] = None


class ServiceListItem(BaseModel):
    """Service item for listings and search results."""
    id: str
    name: str
    description: str
    price: float
    location_region: str
    overall_rating: float
    total_reviews: int
    view_count: int
    like_count: int
    save_count: int
    created_at: datetime
    
    # Merchant info
    merchant: MerchantBasicInfo
    
    # Category info
    category_id: int
    category_name: str
    
    # Main image
    main_image_url: Optional[str] = None
    
    # Featured status
    is_featured: bool = False
    
    # User interaction status (only populated if user is authenticated)
    is_liked: bool = False
    is_saved: bool = False


class ServiceDetailResponse(BaseModel):
    """Detailed service information response."""
    id: str
    name: str
    description: str
    price: float
    location_region: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    
    # Interaction stats
    view_count: int
    like_count: int
    save_count: int
    share_count: int
    
    # Rating info
    overall_rating: float
    total_reviews: int
    
    # Status
    is_active: bool
    
    # Timestamps
    created_at: datetime
    updated_at: datetime
    
    # Merchant details
    merchant: MerchantBasicInfo
    
    # Category info
    category_id: int
    category_name: str
    
    # Images
    images: List[ServiceImageResponse] = []
    
    # Featured status
    is_featured: bool = False
    featured_until: Optional[datetime] = None
    
    # User interaction status (only populated if user is authenticated)
    is_liked: bool = False
    is_saved: bool = False


class ServiceSearchFilters(BaseModel):
    """Service search filters."""
    query: Optional[str] = Field(None, description="Search query for service name/description")
    category_id: Optional[int] = Field(None, description="Filter by category")
    location_region: Optional[str] = Field(None, description="Filter by Uzbekistan region")
    min_price: Optional[float] = Field(None, ge=0, description="Minimum price in UZS")
    max_price: Optional[float] = Field(None, ge=0, description="Maximum price in UZS")
    min_rating: Optional[float] = Field(None, ge=0, le=5, description="Minimum rating")
    is_verified_merchant: Optional[bool] = Field(None, description="Only verified merchants")
    sort_by: Optional[str] = Field(
        "created_at", 
        description="Sort by: created_at, price, rating, popularity"
    )
    sort_order: Optional[str] = Field(
        "desc", 
        description="Sort order: asc, desc"
    )


class PaginatedServiceResponse(BaseModel):
    """Paginated service list response."""
    services: List[ServiceListItem]
    total: int
    page: int
    limit: int
    has_more: bool
    total_pages: int


class FeaturedServicesResponse(BaseModel):
    """Featured services response."""
    services: List[ServiceListItem]
    total: int


class ServiceInteractionRequest(BaseModel):
    """Request schema for service interactions (like, save, share)."""
    interaction_type: str = Field(description="Type: like, save, share")


class ServiceInteractionResponse(BaseModel):
    """Response for service interaction."""
    success: bool
    message: str
    new_count: int
    is_active: bool = True  # True if interaction is now active, False if removed (for toggle interactions)
