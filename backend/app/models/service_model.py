from datetime import datetime
from enum import Enum
from typing import List, Optional
from uuid import UUID

from sqlmodel import SQLModel, Field, Relationship

from app.utils.id_generator import generate_6digit_id


class Service(SQLModel, table=True):
    """Service model for merchant offerings."""
    
    __tablename__ = "services"
    
    # Primary key - 9-digit numeric string
    id: str = Field(
        default_factory=lambda: generate_6digit_id(),
        primary_key=True,
        max_length=9,
        description="9-digit numeric service ID"
    )
    
    # Foreign keys
    merchant_id: UUID = Field(foreign_key="merchants.id", index=True)  # Merchant.id is still UUID
    category_id: int = Field(foreign_key="service_categories.id", index=True)
    
    # Service information
    name: str = Field(max_length=255, description="Service name")
    description: str = Field(description="Service description")
    price: float = Field(ge=0, description="Service price in UZS")
    price_type: Optional[str] = Field(default="fixed", max_length=20, description="Price type: fixed, negotiable, daily, hourly")
    
    # Location
    location_region: str = Field(
        max_length=100, 
        index=True,
        description="Service location region"
    )
    latitude: Optional[float] = Field(default=None, description="GPS latitude")
    longitude: Optional[float] = Field(default=None, description="GPS longitude")
    
    # Interaction counters
    view_count: int = Field(default=0, description="Total views")
    like_count: int = Field(default=0, description="Total likes")
    save_count: int = Field(default=0, description="Total saves")
    share_count: int = Field(default=0, description="Total shares")
    
    # Ratings
    overall_rating: float = Field(default=0.0, description="Calculated overall rating")
    total_reviews: int = Field(default=0, description="Total number of reviews")
    
    # Status
    is_active: bool = Field(default=True, description="Service status")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    
    # Relationships
    merchant: "Merchant" = Relationship(back_populates="services")
    category: "ServiceCategory" = Relationship(back_populates="services")
    reviews: List["Review"] = Relationship(back_populates="service")
    interactions: List["UserInteraction"] = Relationship(back_populates="service")
    featured_services: List["FeaturedService"] = Relationship(back_populates="service")
    images: List["Image"] = Relationship(
        back_populates="service",
        sa_relationship_kwargs={
            "primaryjoin": "and_(Service.id == Image.related_id, Image.image_type == 'service_image')",
            "foreign_keys": "[Image.related_id]"
        }
    )
