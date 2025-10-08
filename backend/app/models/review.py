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
    service_id: UUID = Field(foreign_key="services.id", index=True)
    user_id: UUID = Field(foreign_key="users.id")
    merchant_id: UUID = Field(foreign_key="merchants.id", index=True)
    
    # Review content
    rating: int = Field(ge=1, le=5, description="Rating from 1 to 5 stars")
    comment: Optional[str] = Field(default=None, description="Review comment")
    
    # Status
    is_active: bool = Field(default=True, description="Review status")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    service: "Service" = Relationship(back_populates="reviews")
    user: "User" = Relationship(back_populates="reviews")
    merchant: "Merchant" = Relationship(back_populates="reviews")


class InteractionType(str, Enum):
    """User interaction type enumeration."""
    VIEW = "view"
    LIKE = "like"
    SAVE = "save"
    SHARE = "share"


class UserInteraction(SQLModel, table=True):
    """User interaction model for tracking engagement."""
    
    __tablename__ = "user_interactions"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Foreign keys
    user_id: UUID = Field(foreign_key="users.id", index=True)
    service_id: UUID = Field(foreign_key="services.id", index=True)
    
    # Interaction details
    interaction_type: InteractionType = Field(description="Type of interaction")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    user: "User" = Relationship(back_populates="interactions")
    service: "Service" = Relationship(back_populates="interactions")
    
    # Composite indexes for performance
    __table_args__ = (
        # Index for finding user's interactions
        {"sqlite_autoincrement": True},
    )