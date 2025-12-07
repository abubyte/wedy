from datetime import datetime, date
from typing import Optional
from uuid import UUID, uuid4

from sqlmodel import SQLModel, Field


class DailyServiceMetrics(SQLModel, table=True):
    """Daily aggregated metrics for services."""
    
    __tablename__ = "daily_service_metrics"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Foreign keys
    service_id: str = Field(foreign_key="services.id", index=True, max_length=9)
    merchant_id: UUID = Field(foreign_key="merchants.id", index=True)
    
    # Date for metrics
    metric_date: date = Field(index=True, description="Date for these metrics")
    
    # Daily counts
    views_today: int = Field(default=0, description="Views on this date")
    likes_today: int = Field(default=0, description="Likes on this date")
    saves_today: int = Field(default=0, description="Saves on this date")
    shares_today: int = Field(default=0, description="Shares on this date")
    reviews_today: int = Field(default=0, description="Reviews on this date")
    
    # Cumulative totals (for performance)
    total_views: int = Field(default=0, description="Total views up to this date")
    total_likes: int = Field(default=0, description="Total likes up to this date")
    total_saves: int = Field(default=0, description="Total saves up to this date")
    total_shares: int = Field(default=0, description="Total shares up to this date")
    total_reviews: int = Field(default=0, description="Total reviews up to this date")
    
    # Average rating (recalculated daily)
    average_rating: float = Field(default=0.0, description="Average rating on this date")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)


class MerchantDailyMetrics(SQLModel, table=True):
    """Daily aggregated metrics for merchants."""
    
    __tablename__ = "merchant_daily_metrics"
    
    # Primary key
    id: UUID = Field(default_factory=uuid4, primary_key=True)
    
    # Foreign key
    merchant_id: UUID = Field(foreign_key="merchants.id", index=True)
    
    # Date for metrics
    metric_date: date = Field(index=True, description="Date for these metrics")
    
    # Daily counts across all merchant services
    total_views_today: int = Field(default=0, description="Total views across all services")
    total_likes_today: int = Field(default=0, description="Total likes across all services")
    total_saves_today: int = Field(default=0, description="Total saves across all services")
    total_shares_today: int = Field(default=0, description="Total shares across all services")
    total_reviews_today: int = Field(default=0, description="Total reviews across all services")
    
    # Service counts
    active_services: int = Field(default=0, description="Number of active services")
    featured_services: int = Field(default=0, description="Number of featured services")
    
    # Average rating across all services
    overall_rating: float = Field(default=0.0, description="Overall merchant rating")
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)