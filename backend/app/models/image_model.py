from datetime import datetime
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4
from sqlmodel import SQLModel, Field, Relationship

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
    related_id: str = Field(
        max_length=50,
        description="ID of related entity (service, merchant, user, category) as string"
    )
    
    # Display settings
    display_order: int = Field(default=0, description="Order for display")
    is_active: bool = Field(default=True, description="Image status")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    
    # Note: We use related_id instead of foreign keys for flexibility
    # The relationship is established through the image_type and related_id
    service: Optional["Service"] = Relationship(
        back_populates="images",
        sa_relationship_kwargs={
            "primaryjoin": "and_(Image.related_id == Service.id, Image.image_type == 'service_image')",
            "foreign_keys": "[Image.related_id]"
        }
    )
