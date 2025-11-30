from datetime import datetime, date
from enum import Enum
from typing import List, Optional, Dict, Any
from uuid import UUID, uuid4

from sqlmodel import SQLModel, Field, Relationship, Column, JSON


class PaymentType(str, Enum):
    """Payment type enumeration."""
    TARIFF_SUBSCRIPTION = "tariff_subscription"
    FEATURED_SERVICE = "featured_service"


class PaymentMethod(str, Enum):
    """Payment method enumeration."""
    PAYME = "payme"
    CLICK = "click"
    UZUMBANK = "uzumbank"


class PaymentStatus(str, Enum):
    """Payment status enumeration."""
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class SubscriptionStatus(str, Enum):
    """Subscription status enumeration."""
    ACTIVE = "active"
    EXPIRED = "expired"
    CANCELLED = "cancelled"

class Payment(SQLModel, table=True):
    """Payment model for all payment transactions."""
    
    __tablename__ = "payments"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Foreign key
    user_id: UUID = Field(foreign_key="users.id")
    
    # Payment information
    amount: float = Field(ge=0, description="Payment amount in UZS")
    payment_type: PaymentType = Field(description="Type of payment")
    payment_method: PaymentMethod = Field(description="Payment method used")
    
    # External payment tracking
    transaction_id: Optional[str] = Field(
        default=None, 
        description="Transaction ID from payment provider"
    )
    status: PaymentStatus = Field(default=PaymentStatus.PENDING)
    payment_url: Optional[str] = Field(
        default=None, 
        description="Payment URL for external payment"
    )
    
    # Webhook data storage
    webhook_data: Optional[Dict[str, Any]] = Field(
        default=None, 
        sa_column=Column(JSON),
        description="Raw webhook data from payment provider"
    )
    
    # Payment metadata for easier webhook processing
    payment_metadata: Optional[Dict[str, Any]] = Field(
        default=None,
        sa_column=Column(JSON),
        description="Payment metadata (tariff_plan_id, duration_months, service_id, duration_days, etc.)"
    )
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    completed_at: Optional[datetime] = Field(
        default=None, 
        description="When payment was completed"
    )
    
    # Relationships
    user: "User" = Relationship(back_populates="payments")
    subscriptions: List["MerchantSubscription"] = Relationship(back_populates="payment")
    featured_services: List["FeaturedService"] = Relationship(back_populates="payment")
