from sqlmodel import SQLModel, Field, Relationship
from typing import List, Optional
from datetime import datetime
from uuid import uuid4
from uuid import UUID

class Merchant(SQLModel, table=True):
    """Merchant profile extending User."""
    
    __tablename__ = "merchants"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Foreign key to User
    user_id: UUID = Field(foreign_key="users.id", unique=True)
    
    # Business information
    # business_name: str = Field(max_length=255, description="Business/company name") #REMOVE_CATEGORY_FROM_REGISTRATION
    business_name: Optional[str] = Field(max_length=255, description="Business/company name")
    description: Optional[str] = Field(default=None, description="Business description")
    cover_image_url: Optional[str] = Field(
        default=None, 
        description="AWS S3 URL for cover image"
    )
    
    # Location #REMOVE_CATEGORY_FROM_REGISTRATION
    # location_region: str = Field(
    #     max_length=100, 
    #     index=True,
    #     description="Uzbekistan region"
    # )
    location_region: Optional[str] = Field(
        max_length=100, 
        index=True,
        description="Uzbekistan region"
    )
    latitude: Optional[float] = Field(default=None, description="GPS latitude")
    longitude: Optional[float] = Field(default=None, description="GPS longitude")
    
    # Contact
    website_url: Optional[str] = Field(default=None, description="Business website")
    
    # Status and ratings
    is_verified: bool = Field(default=False, description="Account verification status")
    overall_rating: float = Field(default=0.0, description="Calculated overall rating")
    total_reviews: int = Field(default=0, description="Total number of reviews")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    
    # Relationships
    user: "User" = Relationship(back_populates="merchant")
    services: List["Service"] = Relationship(back_populates="merchant")
    subscriptions: List["MerchantSubscription"] = Relationship(back_populates="merchant")
    contacts: List["MerchantContact"] = Relationship(back_populates="merchant")
    featured_services: List["FeaturedService"] = Relationship(back_populates="merchant")
    reviews: List["Review"] = Relationship(back_populates="merchant")
