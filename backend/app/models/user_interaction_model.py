from datetime import datetime
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4

from sqlmodel import SQLModel, Field, Relationship

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
    user_id: str = Field(foreign_key="users.id", index=True, max_length=9)
    service_id: str = Field(foreign_key="services.id", index=True, max_length=9)
    
    # Interaction details
    interaction_type: InteractionType = Field(description="Type of interaction")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    
    # Relationships
    user: "User" = Relationship(back_populates="interactions")
    service: "Service" = Relationship(back_populates="interactions")
    
    # Composite indexes for performance
    __table_args__ = (
        # Index for finding user's interactions
        {"sqlite_autoincrement": True},
    )