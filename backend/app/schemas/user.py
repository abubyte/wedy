from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, validator

from app.models import UserType
from app.core.security import verify_phone_number, normalize_phone_number
from app.schemas.merchant import MerchantProfileUpdateRequest


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

    id: UUID
    phone_number: str
    name: str
    avatar_url: Optional[str] = None
    user_type: UserType
    created_at: datetime
