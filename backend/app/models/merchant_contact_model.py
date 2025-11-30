from sqlmodel import SQLModel, Field, Relationship
from typing import Optional
from datetime import datetime
from uuid import uuid4
from enum import Enum
from uuid import UUID

class ContactType(str, Enum):
    PHONE = "phone"
    SOCIAL_MEDIA = "social_media"

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
    created_at: datetime = Field(default_factory=datetime.now)
    
    # Relationships
    merchant: "Merchant" = Relationship(back_populates="contacts")
    