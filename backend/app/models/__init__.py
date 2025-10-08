# Import all models to register them with SQLModel
from app.models.user import (
    User,
    UserType,
    Merchant,
    MerchantContact,
    ContactType,
)

from app.models.service import (
    ServiceCategory,
    Service,
    Image,
    ImageType,
    FeaturedService,
    FeatureType,
)

from app.models.payment import (
    TariffPlan,
    Payment,
    PaymentType,
    PaymentMethod,
    PaymentStatus,
    MerchantSubscription,
    SubscriptionStatus,
)

from app.models.review import (
    Review,
    UserInteraction,
    InteractionType,
)

from app.models.analytics import (
    DailyServiceMetrics,
    MerchantDailyMetrics,
)

# Export all models for easy importing
__all__ = [
    # User models
    "User",
    "UserType", 
    "Merchant",
    "MerchantContact",
    "ContactType",
    
    # Service models
    "ServiceCategory",
    "Service",
    "Image",
    "ImageType",
    "FeaturedService",
    "FeatureType",
    
    # Payment models
    "TariffPlan",
    "Payment",
    "PaymentType",
    "PaymentMethod", 
    "PaymentStatus",
    "MerchantSubscription",
    "SubscriptionStatus",
    
    # Review models
    "Review",
    "UserInteraction", 
    "InteractionType",
    
    # Analytics models
    "DailyServiceMetrics",
    "MerchantDailyMetrics",
]