from datetime import datetime, date
from decimal import Decimal
from typing import List, Optional, Dict, Any
from uuid import UUID
from pydantic import BaseModel, Field, validator, ConfigDict

from app.models.payment_model import PaymentType, PaymentMethod, PaymentStatus, SubscriptionStatus

class TariffPlanResponse(BaseModel):
    """Response schema for tariff plan."""
    model_config = ConfigDict(from_attributes=True)
    
    id: UUID
    name: str
    price_per_month: float
    max_services: int
    max_images_per_service: int
    max_phone_numbers: int
    max_gallery_images: int
    max_social_accounts: int
    allow_website: bool
    allow_cover_image: bool
    monthly_featured_cards: int
    is_active: bool
    created_at: datetime


class PaymentResponse(BaseModel):
    """Response schema for payment."""
    model_config = ConfigDict(from_attributes=True)
    
    id: UUID
    amount: float
    payment_type: PaymentType
    payment_method: PaymentMethod
    status: PaymentStatus
    payment_url: Optional[str] = None
    transaction_id: Optional[str] = None
    created_at: datetime
    completed_at: Optional[datetime] = None


class TariffPaymentRequest(BaseModel):
    """Request schema for tariff subscription payment."""
    tariff_plan_id: UUID = Field(..., description="ID of the tariff plan")
    duration_months: int = Field(..., ge=1, le=12, description="Subscription duration in months")
    payment_method: PaymentMethod = Field(..., description="Payment method to use")

    @validator('duration_months')
    def validate_duration(cls, v):
        """Validate duration is one of the allowed values."""
        allowed_durations = [1, 3, 6, 12]
        if v not in allowed_durations:
            raise ValueError(f"Duration must be one of {allowed_durations}")
        return v


class FeaturedServicePaymentRequest(BaseModel):
    """Request schema for featured service payment."""
    service_id: UUID = Field(..., description="ID of the service to feature")
    duration_days: int = Field(..., ge=1, le=365, description="Feature duration in days")
    payment_method: PaymentMethod = Field(..., description="Payment method to use")


class SubscriptionResponse(BaseModel):
    """Response schema for merchant subscription."""
    model_config = ConfigDict(from_attributes=True)
    
    id: UUID
    tariff_plan: TariffPlanResponse
    start_date: date
    end_date: date
    status: SubscriptionStatus
    created_at: datetime


class LimitDetailResponse(BaseModel):
    """Response schema for a single limit detail."""
    limit: int
    current: int
    available: int


class SubscriptionWithLimitsResponse(BaseModel):
    """Universal response schema for subscription with limits."""
    subscription: Optional[SubscriptionResponse] = None
    limits: Optional[Dict[str, Any]] = None
    message: Optional[str] = None


class WebhookPaymentData(BaseModel):
    """Schema for payment webhook data."""
    id: str = Field(..., description="Webhook ID")
    method: str = Field(..., description="Payment method")
    params: dict = Field(..., description="Webhook parameters")


class PaymentWebhookResponse(BaseModel):
    """Response schema for webhook processing."""
    success: bool
    message: Optional[str] = None


# Tariff CRUD Schemas for Admin
class TariffCreateRequest(BaseModel):
    """Request schema for creating a tariff plan."""
    name: str = Field(..., min_length=1, max_length=100, description="Tariff plan name")
    price_per_month: float = Field(..., ge=0, description="Price per month in UZS")
    max_services: int = Field(..., gt=0, description="Maximum services allowed")
    max_images_per_service: int = Field(..., gt=0, description="Maximum images per service")
    max_phone_numbers: int = Field(..., gt=0, description="Maximum phone numbers")
    max_gallery_images: int = Field(..., gt=0, description="Maximum gallery images")
    max_social_accounts: int = Field(..., gt=0, description="Maximum social media accounts")
    allow_website: bool = Field(False, description="Allow website URL")
    allow_cover_image: bool = Field(False, description="Allow cover image")
    monthly_featured_cards: int = Field(0, ge=0, description="Free featured services per month")
    is_active: bool = Field(True, description="Plan active status")


class TariffUpdateRequest(BaseModel):
    """Request schema for updating a tariff plan."""
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="Tariff plan name")
    price_per_month: Optional[float] = Field(None, ge=0, description="Price per month in UZS")
    max_services: Optional[int] = Field(None, gt=0, description="Maximum services allowed")
    max_images_per_service: Optional[int] = Field(None, gt=0, description="Maximum images per service")
    max_phone_numbers: Optional[int] = Field(None, gt=0, description="Maximum phone numbers")
    max_gallery_images: Optional[int] = Field(None, gt=0, description="Maximum gallery images")
    max_social_accounts: Optional[int] = Field(None, gt=0, description="Maximum social media accounts")
    allow_website: Optional[bool] = Field(None, description="Allow website URL")
    allow_cover_image: Optional[bool] = Field(None, description="Allow cover image")
    monthly_featured_cards: Optional[int] = Field(None, ge=0, description="Free featured services per month")
    is_active: Optional[bool] = Field(None, description="Plan active status")


class TariffDetailResponse(BaseModel):
    """Detailed tariff plan response schema for admin."""
    model_config = ConfigDict(from_attributes=True)
    
    id: UUID
    name: str
    price_per_month: float
    max_services: int
    max_images_per_service: int
    max_phone_numbers: int
    max_gallery_images: int
    max_social_accounts: int
    allow_website: bool
    allow_cover_image: bool
    monthly_featured_cards: int
    is_active: bool
    created_at: datetime
    subscription_count: int = 0


class TariffListResponse(BaseModel):
    """Paginated tariff list response."""
    tariffs: List[TariffDetailResponse]
    total: int
    page: int
    limit: int
    has_more: bool
    total_pages: int
