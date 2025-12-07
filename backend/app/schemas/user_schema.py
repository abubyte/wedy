from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field, validator

from app.models import UserType, InteractionType
from app.core.security import verify_phone_number, normalize_phone_number
from app.schemas.merchant_schema import MerchantProfileUpdateRequest
from app.schemas.service_schema import ServiceListItem


class UserProfileUpdateRequest(BaseModel):
    """Request schema for updating basic user profile."""

    phone_number: Optional[str] = Field(
        None, description="Phone number (9 digits, Uzbekistan format)", example="901234567"
    )
    name: Optional[str] = Field(None, min_length=2, max_length=255)

    @validator("phone_number")
    def validate_phone_number(cls, v):
        if v is None:
            return v
        if not verify_phone_number(v):
            raise ValueError("Invalid Uzbekistan phone number format")
        return normalize_phone_number(v)

    @validator("name")
    def validate_name(cls, v):
        if v is None:
            return v
        v = v.strip()
        if len(v) < 2:
            raise ValueError("Name must be at least 2 characters long")
        return v


class UserProfileResponse(BaseModel):
    """Response schema for user profile."""

    id: str
    phone_number: str
    name: str
    avatar_url: Optional[str] = None
    user_type: UserType
    created_at: datetime


class UserInteractionItem(BaseModel):
    """User interaction item with service details."""
    interaction_type: InteractionType
    interacted_at: datetime
    service: ServiceListItem


class UserInteractionsResponse(BaseModel):
    """Response schema for user interactions."""
    liked_services: List[UserInteractionItem] = []
    saved_services: List[UserInteractionItem] = []
    total_liked: int = 0
    total_saved: int = 0
