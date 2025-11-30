from datetime import datetime
from enum import Enum
from typing import List, Optional
from uuid import UUID, uuid4

from sqlmodel import SQLModel, Field, Relationship

class TariffPlan(SQLModel, table=True):
    """Tariff plan model for merchant subscriptions."""
    
    __tablename__ = "tariff_plans"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Plan information
    name: str = Field(max_length=100, unique=True, description="Tariff plan name")
    price_per_month: float = Field(ge=0, description="Price per month in UZS")
    
    # Service limits
    max_services: int = Field(gt=0, description="Maximum services allowed")
    max_images_per_service: int = Field(gt=0, description="Maximum images per service")
    max_phone_numbers: int = Field(gt=0, description="Maximum phone numbers")
    max_gallery_images: int = Field(gt=0, description="Maximum gallery images")
    max_social_accounts: int = Field(gt=0, description="Maximum social media accounts")
    
    # Feature permissions
    allow_website: bool = Field(default=False, description="Allow website URL")
    allow_cover_image: bool = Field(default=False, description="Allow cover image")
    monthly_featured_cards: int = Field(default=0, description="Free featured services per month")
    
    # Status
    is_active: bool = Field(default=True, description="Plan status")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    
    # Relationships
    subscriptions: List["MerchantSubscription"] = Relationship(back_populates="tariff_plan")
