from datetime import datetime
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4

from sqlmodel import SQLModel, Field, Relationship


class Review(SQLModel, table=True):
    """Review model for service ratings and comments."""
    
    __tablename__ = "reviews"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Foreign keys
    service_id: str = Field(foreign_key="services.id", index=True, max_length=9)
    user_id: str = Field(foreign_key="users.id", max_length=9)
    merchant_id: UUID = Field(foreign_key="merchants.id", index=True)
    
    # Review content
    rating: int = Field(ge=1, le=5, description="Rating from 1 to 5 stars")
    comment: Optional[str] = Field(default=None, description="Review comment")
    
    # Status
    is_active: bool = Field(default=True, description="Review status")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    
    # Relationships
    service: "Service" = Relationship(back_populates="reviews")
    user: "User" = Relationship(back_populates="reviews")
    merchant: "Merchant" = Relationship(back_populates="reviews")
