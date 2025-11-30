# Import all models to register them with SQLModel
from app.models.user_model import (
    User,
    UserType,
)

from app.models.merchant_model import (
    Merchant,
)

from app.models.merchant_contact_model import (
    MerchantContact,
    ContactType,
)

from app.models.category_model import (
    ServiceCategory,
)

from app.models.service_model import (
    Service,
)

from app.models.image_model import (
    Image,
    ImageType,
)

from app.models.feature_model import (
    FeaturedService,
    FeatureType,
)

from app.models.tariff_model import (
    TariffPlan,
)

from app.models.payment_model import (
    Payment,
    PaymentType,
    PaymentMethod,
    PaymentStatus,
    SubscriptionStatus,
)

from app.models.merchant_subscription_model import (
    MerchantSubscription,
)

from app.models.review_model import (
    Review,
)

from app.models.user_interaction_model import (
    UserInteraction,
    InteractionType,
)

from app.models.analytics_model import (
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