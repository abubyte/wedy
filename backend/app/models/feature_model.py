from enum import Enum
from typing import Optional
from uuid import UUID, uuid4
from sqlmodel import SQLModel, Field, Relationship
from datetime import datetime


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
    service_id: str = Field(foreign_key="services.id", max_length=9)
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
    created_at: datetime = Field(default_factory=datetime.now)
    
    # Relationships
    service: "Service" = Relationship(back_populates="featured_services")
    merchant: "Merchant" = Relationship(back_populates="featured_services")
    payment: Optional["Payment"] = Relationship(back_populates="featured_services")