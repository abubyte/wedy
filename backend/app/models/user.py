from datetime import datetime
from enum import Enum
from typing import List, Optional
from uuid import UUID, uuid4

from sqlmodel import SQLModel, Field, Relationship, Column, String


class UserType(str, Enum):
    """User type enumeration."""
    CLIENT = "client"
    MERCHANT = "merchant"
    ADMIN = "admin"


class ContactType(str, Enum):
    """Contact type enumeration."""
    PHONE = "phone"
    SOCIAL_MEDIA = "social_media"


class User(SQLModel, table=True):
    """User model for both clients and merchants."""
    
    __tablename__ = "users"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Basic information
    phone_number: str = Field(
        max_length=9, 
        unique=True, 
        index=True,
        description="Phone number (9 digits, Uzbekistan format)"
    )
    name: str = Field(max_length=255, description="User's full name")
    avatar_url: Optional[str] = Field(default=None, description="AWS S3 URL for avatar")
    
    # User classification
    user_type: UserType = Field(description="Type of user account")
    is_active: bool = Field(default=True, description="Account status")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    merchant: Optional["Merchant"] = Relationship(
        back_populates="user",
        sa_relationship_kwargs={"uselist": False}
    )
    payments: List["Payment"] = Relationship(back_populates="user")
    reviews: List["Review"] = Relationship(back_populates="user")
    interactions: List["UserInteraction"] = Relationship(back_populates="user")


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
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    user: User = Relationship(back_populates="merchant")
    services: List["Service"] = Relationship(back_populates="merchant")
    subscriptions: List["MerchantSubscription"] = Relationship(back_populates="merchant")
    contacts: List["MerchantContact"] = Relationship(back_populates="merchant")
    featured_services: List["FeaturedService"] = Relationship(back_populates="merchant")
    reviews: List["Review"] = Relationship(back_populates="merchant")


class MerchantContact(SQLModel, table=True):
    """Merchant contact information (phones and social media)."""
    
    __tablename__ = "merchant_contacts"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Foreign key
    merchant_id: UUID = Field(foreign_key="merchants.id")
    
    # Contact details
    contact_type: ContactType = Field(description="Type of contact")
    contact_value: str = Field(description="Phone number or social media URL")
    platform_name: Optional[str] = Field(
        default=None, 
        description="Platform name for social media (instagram, telegram, etc.)"
    )
    
    # Display order
    display_order: int = Field(default=0, description="Order for display")
    is_active: bool = Field(default=True, description="Contact status")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    merchant: Merchant = Relationship(back_populates="contacts")