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
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    
    # Relationships
    merchant: Optional["Merchant"] = Relationship(
        back_populates="user",
        sa_relationship_kwargs={"uselist": False}
    )
    payments: List["Payment"] = Relationship(back_populates="user")
    reviews: List["Review"] = Relationship(back_populates="user")
    interactions: List["UserInteraction"] = Relationship(back_populates="user")
