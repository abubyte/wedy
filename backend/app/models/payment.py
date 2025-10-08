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


class TariffPlan(SQLModel, table=True):
    """Tariff plan model for merchant subscriptions."""
    
    __tablename__ = "tariff_plans"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Plan information
    name: str = Field(max_length=100, unique=True, description="Tariff plan name")
    price_per_month: float = Field(ge=0, description="Price per month in UZS")
    
    # Service limits
    max_services: int = Field(gt=0, description="Maximum services allowed")
    max_images_per_service: int = Field(gt=0, description="Maximum images per service")
    max_phone_numbers: int = Field(gt=0, description="Maximum phone numbers")
    max_gallery_images: int = Field(gt=0, description="Maximum gallery images")
    max_social_accounts: int = Field(gt=0, description="Maximum social media accounts")
    
    # Feature permissions
    allow_website: bool = Field(default=False, description="Allow website URL")
    allow_cover_image: bool = Field(default=False, description="Allow cover image")
    monthly_featured_cards: int = Field(default=0, description="Free featured services per month")
    
    # Status
    is_active: bool = Field(default=True, description="Plan status")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    subscriptions: List["MerchantSubscription"] = Relationship(back_populates="tariff_plan")


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
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    completed_at: Optional[datetime] = Field(
        default=None, 
        description="When payment was completed"
    )
    
    # Relationships
    user: "User" = Relationship(back_populates="payments")
    subscriptions: List["MerchantSubscription"] = Relationship(back_populates="payment")
    featured_services: List["FeaturedService"] = Relationship(back_populates="payment")


class MerchantSubscription(SQLModel, table=True):
    """Merchant subscription model for tariff plans."""
    
    __tablename__ = "merchant_subscriptions"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Foreign keys
    merchant_id: UUID = Field(foreign_key="merchants.id")
    tariff_plan_id: UUID = Field(foreign_key="tariff_plans.id")
    payment_id: Optional[UUID] = Field(
        default=None, 
        foreign_key="payments.id",
        description="Payment that activated this subscription"
    )
    
    # Subscription period
    start_date: date = Field(description="Subscription start date")
    end_date: date = Field(description="Subscription end date")
    
    # Status
    status: SubscriptionStatus = Field(default=SubscriptionStatus.ACTIVE)
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    # Relationships
    merchant: "Merchant" = Relationship(back_populates="subscriptions")
    tariff_plan: TariffPlan = Relationship(back_populates="subscriptions")
    payment: Optional[Payment] = Relationship(back_populates="subscriptions")