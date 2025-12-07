from datetime import datetime
from typing import Optional, List
from sqlmodel import SQLModel, Field, Relationship

class ServiceCategory(SQLModel, table=True):
    """Service category model (admin-managed)."""
    
    __tablename__ = "service_categories"
    
    # Primary key - auto-incrementing integer
    id: int = Field(primary_key=True, sa_column_kwargs={"autoincrement": True})
    
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
    created_at: datetime = Field(default_factory=datetime.now)
    
    # Relationships
    services: List["Service"] = Relationship(back_populates="category")
