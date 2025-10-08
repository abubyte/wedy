from datetime import datetime, date
from decimal import Decimal
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, Field, validator

from app.models.payment import PaymentType, PaymentMethod, PaymentStatus, SubscriptionStatus


class TariffPlanResponse(BaseModel):
    """Response schema for tariff plan."""
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

    class Config:
        from_attributes = True


class PaymentResponse(BaseModel):
    """Response schema for payment."""
    id: UUID
    amount: float
    payment_type: PaymentType
    payment_method: PaymentMethod
    status: PaymentStatus
    payment_url: Optional[str] = None
    transaction_id: Optional[str] = None
    created_at: datetime
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True


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
    id: UUID
    tariff_plan: TariffPlanResponse
    start_date: date
    end_date: date
    status: SubscriptionStatus
    created_at: datetime

    class Config:
        from_attributes = True


class WebhookPaymentData(BaseModel):
    """Schema for payment webhook data."""
    id: str = Field(..., description="Webhook ID")
    method: str = Field(..., description="Payment method")
    params: dict = Field(..., description="Webhook parameters")


class PaymentWebhookResponse(BaseModel):
    """Response schema for webhook processing."""
    success: bool
    message: Optional[str] = None


class PaymentCalculation(BaseModel):
    """Schema for payment calculation results."""
    base_amount: float
    discount_percentage: float
    discount_amount: float
    final_amount: float
    duration_months: Optional[int] = None
    duration_days: Optional[int] = None


class SubscriptionStatus(BaseModel):
    """Schema for subscription status check."""
    has_active_subscription: bool
    current_subscription: Optional[SubscriptionResponse] = None
    expires_at: Optional[date] = None
    days_remaining: Optional[int] = None


class UsageLimitStatus(BaseModel):
    """Schema for usage limit status."""
    limit_type: str
    current_usage: int
    max_allowed: int
    can_add_more: bool
    remaining: int


class MerchantLimitsResponse(BaseModel):
    """Response schema for merchant's current limits and usage."""
    subscription: Optional[SubscriptionResponse]
    limits: dict[str, UsageLimitStatus]


# Payment provider specific schemas
class PaymePaymentRequest(BaseModel):
    """Payme payment request schema."""
    amount: int  # Amount in tiyins (UZS * 100)
    account: dict
    description: str


class PaymePaymentResponse(BaseModel):
    """Payme payment response schema."""
    payment_url: str
    transaction_id: str


class ClickPaymentRequest(BaseModel):
    """Click payment request schema."""
    amount: float
    merchant_trans_id: str
    service_id: str
    merchant_id: str


class ClickPaymentResponse(BaseModel):
    """Click payment response schema."""
    payment_url: str
    transaction_id: str


class UzumBankPaymentRequest(BaseModel):
    """UzumBank payment request schema."""
    amount: float
    order_id: str
    description: str
    return_url: str


class UzumBankPaymentResponse(BaseModel):
    """UzumBank payment response schema."""
    payment_url: str
    transaction_id: str