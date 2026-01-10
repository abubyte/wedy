from datetime import datetime, date
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field

from app.models import ContactType, SubscriptionStatus

class MerchantProfileResponse(BaseModel):
    """Merchant profile response with subscription info."""
    
    # Basic merchant info
    id: UUID
    user_id: str
    business_name: str
    description: Optional[str] = None
    cover_image_url: Optional[str] = None
    location_region: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    website_url: Optional[str] = None
    
    # Status and ratings
    is_verified: bool
    overall_rating: float
    total_reviews: int
    created_at: datetime
    
    # User info
    name: str
    phone_number: str
    avatar_url: Optional[str] = None
    
    # Current subscription info
    subscription: Optional["ActiveSubscriptionInfo"] = None
    
    # Current usage stats
    current_services_count: int = 0
    current_gallery_images_count: int = 0
    current_phone_contacts_count: int = 0
    current_social_contacts_count: int = 0


class ActiveSubscriptionInfo(BaseModel):
    """Active subscription information."""
    id: UUID
    tariff_plan_id: UUID
    tariff_plan_name: str
    start_date: date
    end_date: date
    status: SubscriptionStatus
    days_remaining: int
    
    # Tariff plan limits
    max_services: int
    max_images_per_service: int
    max_phone_numbers: int
    max_gallery_images: int
    max_social_accounts: int
    allow_website: bool
    allow_cover_image: bool
    monthly_featured_cards: int


class MerchantProfileUpdateRequest(BaseModel):
    """Request schema for updating merchant profile."""
    business_name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=2000)
    location_region: Optional[str] = Field(None, max_length=100)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    website_url: Optional[str] = Field(None, max_length=500)


class MerchantContactResponse(BaseModel):
    """Merchant contact response schema."""
    id: UUID
    contact_type: ContactType
    contact_value: str
    platform_name: Optional[str] = None
    display_order: int
    is_active: bool
    created_at: datetime


class MerchantContactRequest(BaseModel):
    """Request schema for merchant contact."""
    contact_type: ContactType
    contact_value: str = Field(min_length=1, max_length=255)
    platform_name: Optional[str] = Field(None, max_length=50)
    display_order: Optional[int] = Field(0, ge=0)


class MerchantContactUpdateRequest(BaseModel):
    """Request schema for updating merchant contact."""
    contact_value: Optional[str] = Field(None, min_length=1, max_length=255)
    platform_name: Optional[str] = Field(None, max_length=50)
    display_order: Optional[int] = Field(None, ge=0)


class MerchantGalleryResponse(BaseModel):
    """Merchant gallery image response."""
    id: UUID
    s3_url: str
    file_name: str
    file_size: Optional[int] = None
    display_order: int
    created_at: datetime


class MerchantGalleryRequest(BaseModel):
    """Request schema for adding gallery image."""
    display_order: Optional[int] = Field(0, ge=0)


class ServiceCreateRequest(BaseModel):
    """Request schema for creating a service."""
    name: str = Field(min_length=1, max_length=255)
    description: str = Field(min_length=1, max_length=2000)
    category_id: int
    price: float = Field(ge=0)
    location_region: str = Field(max_length=100)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)


class ServiceUpdateRequest(BaseModel):
    """Request schema for updating a service."""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, min_length=1, max_length=2000)
    category_id: Optional[int] = None
    price: Optional[float] = Field(None, ge=0)
    location_region: Optional[str] = Field(None, max_length=100)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)


class MerchantServiceResponse(BaseModel):
    """Merchant's service response."""
    id: str  # 9-digit service ID
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
    created_at: datetime
    updated_at: datetime
    
    # Category info
    category_id: int
    category_name: str
    
    # Images count
    images_count: int = 0
    
    # Main image URL (first image by display_order)
    main_image_url: Optional[str] = None
    
    # Featured status
    is_featured: bool = False
    featured_until: Optional[datetime] = None


class MerchantServicesResponse(BaseModel):
    """Response schema for merchant services list."""
    services: List[MerchantServiceResponse]
    total: int
    active_count: int
    inactive_count: int


class ServiceAnalyticsResponse(BaseModel):
    """Service analytics response schema."""
    service_id: str
    service_name: str
    
    # Total counts
    view_count_total: int
    like_count_total: int
    save_count_total: int
    share_count_total: int
    review_count_total: int
    
    # Today's counts (from daily metrics)
    view_count_today: int = 0
    like_count_today: int = 0
    save_count_today: int = 0
    share_count_today: int = 0
    
    # Rating
    overall_rating: float


class MerchantAnalyticsResponse(BaseModel):
    """Merchant analytics dashboard response."""
    services: List[ServiceAnalyticsResponse]
    
    # Overall stats
    total_services: int
    total_views: int
    total_likes: int
    total_saves: int
    total_shares: int
    total_reviews: int
    overall_rating: float
    
    # Today's totals
    views_today: int = 0
    likes_today: int = 0
    saves_today: int = 0
    shares_today: int = 0


class FeaturedServiceResponse(BaseModel):
    """Featured service tracking response."""
    id: UUID
    service_id: str
    service_name: str
    start_date: datetime
    end_date: datetime
    days_duration: int
    amount_paid: Optional[float] = None
    feature_type: str
    is_active: bool
    created_at: datetime
    
    # Service performance during featured period
    views_gained: int = 0
    likes_gained: int = 0


class MerchantFeaturedServicesResponse(BaseModel):
    """Response for merchant's featured services."""
    featured_services: List[FeaturedServiceResponse]
    total: int
    active_count: int
    remaining_free_slots: int


class ImageUploadResponse(BaseModel):
    """Response for image upload operations."""
    success: bool
    message: str
    image_id: Optional[UUID] = None
    s3_url: Optional[str] = None
    presigned_url: Optional[str] = None


class TariffLimitError(BaseModel):
    """Error response for tariff limit violations."""
    error: str
    limit_type: str
    current_count: int
    max_allowed: int
    tariff_plan: str


class SubscriptionRequiredError(BaseModel):
    """Error response for subscription requirement."""
    error: str
    message: str
    subscription_status: Optional[str] = None
    expired_date: Optional[date] = None
