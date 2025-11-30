from datetime import date, datetime
from typing import Optional, TYPE_CHECKING
from uuid import UUID, uuid4

from sqlmodel import SQLModel, Field, Relationship
from app.models.payment_model import SubscriptionStatus

if TYPE_CHECKING:
    from app.models.merchant_model import Merchant
    from app.models.payment_model import Payment
    from app.models.tariff_model import TariffPlan


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
    created_at: datetime = Field(default_factory=datetime.now)
    
    # Relationships
    merchant: "Merchant" = Relationship(back_populates="subscriptions")
    tariff_plan: "TariffPlan" = Relationship(back_populates="subscriptions")
    payment: Optional["Payment"] = Relationship(back_populates="subscriptions")
