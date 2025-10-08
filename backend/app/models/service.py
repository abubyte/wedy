from datetime import datetime
from enum import Enum
from typing import List, Optional
from uuid import UUID, uuid4

from sqlmodel import SQLModel, Field, Relationship


class ServiceCategory(SQLModel, table=True):
    """Service category model (admin-managed)."""
    
    __tablename__ = "service_categories"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Category information
    name: str = Field(max_length=100, unique=True, description="Category name")
    description: Optional[str] = Field(default=None, description="Category description")
    icon_url: Optional[str] = Field(
        default=None, 
        description="AWS S3 URL for category icon"
    )
    
    # Display settings
    display_order: int = Field(default=0, description="Order for display")
    is_active: bool = Field(default=True, description="Category status")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    services: List["Service"] = Relationship(back_populates="category")


class Service(SQLModel, table=True):
    """Service model for merchant offerings."""
    
    __tablename__ = "services"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Foreign keys
    merchant_id: UUID = Field(foreign_key="merchants.id", index=True)
    category_id: UUID = Field(foreign_key="service_categories.id", index=True)
    
    # Service information
    name: str = Field(max_length=255, description="Service name")
    description: str = Field(description="Service description")
    price: float = Field(ge=0, description="Service price in UZS")
    
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
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    merchant: "Merchant" = Relationship(back_populates="services")
    category: ServiceCategory = Relationship(back_populates="services")
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


class ImageType(str, Enum):
    """Image type enumeration."""
    SERVICE_IMAGE = "service_image"
    MERCHANT_GALLERY = "merchant_gallery"
    USER_AVATAR = "user_avatar"
    MERCHANT_COVER = "merchant_cover"
    CATEGORY_ICON = "category_icon"


class Image(SQLModel, table=True):
    """Image model for all types of images."""
    
    __tablename__ = "images"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Image information
    s3_url: str = Field(description="AWS S3 URL")
    file_name: str = Field(max_length=255, description="Original file name")
    file_size: Optional[int] = Field(default=None, description="File size in bytes")
    
    # Classification
    image_type: ImageType = Field(description="Type of image")
    related_id: UUID = Field(description="ID of related entity (service, merchant, user)")
    
    # Display settings
    display_order: int = Field(default=0, description="Order for display")
    is_active: bool = Field(default=True, description="Image status")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Note: We use related_id instead of foreign keys for flexibility
    # The relationship is established through the image_type and related_id
    service: Optional[Service] = Relationship(
        back_populates="images",
        sa_relationship_kwargs={
            "primaryjoin": "and_(Image.related_id == Service.id, Image.image_type == 'service_image')",
            "foreign_keys": "[Image.related_id]"
        }
    )


class FeatureType(str, Enum):
    """Featured service type enumeration."""
    MONTHLY_ALLOCATION = "monthly_allocation"
    PAID_FEATURE = "paid_feature"


class FeaturedService(SQLModel, table=True):
    """Featured service model for promoted services."""
    
    __tablename__ = "featured_services"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Foreign keys
    service_id: UUID = Field(foreign_key="services.id")
    merchant_id: UUID = Field(foreign_key="merchants.id")
    payment_id: Optional[UUID] = Field(
        default=None, 
        foreign_key="payments.id",
        description="Payment ID for paid features (null for free allocation)"
    )
    
    # Feature details
    start_date: datetime = Field(description="Feature start date")
    end_date: datetime = Field(description="Feature end date")
    days_duration: int = Field(description="Feature duration in days")
    amount_paid: Optional[float] = Field(
        default=None, 
        description="Amount paid for featuring (null for free allocation)"
    )
    feature_type: FeatureType = Field(description="Type of featuring")
    
    # Status
    is_active: bool = Field(default=True, description="Feature status")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    service: Service = Relationship(back_populates="featured_services")
    merchant: "Merchant" = Relationship(back_populates="featured_services")
    payment: Optional["Payment"] = Relationship(back_populates="featured_services")