"""
Pytest configuration and shared fixtures for review tests.
"""
import os
import pytest
import random
import asyncio
from typing import AsyncGenerator
from uuid import uuid4

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlmodel import SQLModel

# Import all models to ensure they are registered with SQLModel metadata
# This ensures all tables are created during test setup
from app.models import *  # noqa: F403, F401
from app.models import (
    User, UserType,
    Merchant,
    Service, ServiceCategory,
    Review,
    Image, ImageType,
    FeaturedService, FeatureType,
    UserInteraction, InteractionType,
    TariffPlan,
    MerchantSubscription,
    Payment, PaymentType, PaymentMethod, PaymentStatus, SubscriptionStatus,
    MerchantContact, ContactType
)


# Get test database URL from environment or use default
def get_test_database_url() -> str:
    """Get test database URL from environment or construct from main DATABASE_URL."""
    test_db_url = os.getenv("TEST_DATABASE_URL")
    if test_db_url:
        return test_db_url
    
    # Try to get from main DATABASE_URL and modify it
    main_db_url = os.getenv("DATABASE_URL")
    if main_db_url:
        # Replace database name with test database
        if "+asyncpg" in main_db_url:
            # PostgreSQL async URL
            if "/wedy" in main_db_url:
                return main_db_url.replace("/wedy", "/wedy_test")
            return main_db_url.rsplit("/", 1)[0] + "/wedy_test"
        else:
            # Regular PostgreSQL URL
            if "/wedy" in main_db_url:
                return main_db_url.replace("/wedy", "/wedy_test")
            return main_db_url.rsplit("/", 1)[0] + "/wedy_test"
    
    # Default to SQLite in-memory for tests
    return "sqlite+aiosqlite:///:memory:"


# Create test database engine
test_engine = create_async_engine(
    get_test_database_url(),
    echo=False,
    pool_pre_ping=True,
)

TestSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
async def setup_test_db():
    """Create test database tables."""
    async with test_engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.drop_all)


@pytest.fixture
async def db_session(setup_test_db) -> AsyncGenerator[AsyncSession, None]:
    """Provide a database session for tests."""
    async with TestSessionLocal() as session:
        yield session
        await session.rollback()


@pytest.fixture
async def sample_client_user(db_session: AsyncSession) -> User:
    """Create a sample client user for testing."""
    # Generate unique phone number using random digits
    # Format: 90XXXXXXX (9 digits total, starting with 90)
    random_suffix = ''.join([str(random.randint(0, 9)) for _ in range(7)])
    phone_number = f"90{random_suffix}"
    
    user = User(
        phone_number=phone_number,
        name="Test Client",
        user_type=UserType.CLIENT,
        is_active=True
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
async def sample_merchant_user(db_session: AsyncSession) -> User:
    """Create a sample merchant user for testing."""
    # Generate unique phone number using random digits
    # Format: 91XXXXXXX (9 digits total, starting with 91)
    random_suffix = ''.join([str(random.randint(0, 9)) for _ in range(7)])
    phone_number = f"91{random_suffix}"
    
    user = User(
        phone_number=phone_number,
        name="Test Merchant User",
        user_type=UserType.MERCHANT,
        is_active=True
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
async def sample_merchant(db_session: AsyncSession, sample_merchant_user: User) -> Merchant:
    """Create a sample merchant for testing."""
    from app.models.merchant_model import Merchant
    merchant = Merchant(
        user_id=sample_merchant_user.id,
        business_name="Test Business",
        description="Test business description",
        location_region="Tashkent",
        is_verified=True
    )
    db_session.add(merchant)
    await db_session.commit()
    await db_session.refresh(merchant)
    return merchant


@pytest.fixture
async def sample_category(db_session: AsyncSession) -> ServiceCategory:
    """Create a sample service category for testing."""
    # Generate unique category name using UUID
    unique_id = str(uuid4())[:8].replace("-", "")
    category_name = f"Photography_{unique_id}"
    
    category = ServiceCategory(
        name=category_name,
        description="Photography services",
        is_active=True
    )
    db_session.add(category)
    await db_session.commit()
    await db_session.refresh(category)
    return category


@pytest.fixture
async def sample_service(
    db_session: AsyncSession,
    sample_merchant: Merchant,
    sample_category: ServiceCategory
) -> Service:
    """Create a sample service for testing."""
    service = Service(
        merchant_id=sample_merchant.id,
        category_id=sample_category.id,
        name="Wedding Photography",
        description="Professional wedding photography services",
        price=5000000.0,
        location_region="Tashkent",
        is_active=True
    )
    db_session.add(service)
    await db_session.commit()
    await db_session.refresh(service)
    return service


@pytest.fixture
async def sample_review(
    db_session: AsyncSession,
    sample_service: Service,
    sample_client_user: User,
    sample_merchant: Merchant
) -> Review:
    """Create a sample review for testing."""
    review = Review(
        service_id=sample_service.id,
        user_id=sample_client_user.id,
        merchant_id=sample_merchant.id,
        rating=5,
        comment="Excellent service!",
        is_active=True
    )
    db_session.add(review)
    await db_session.commit()
    await db_session.refresh(review)
    return review


@pytest.fixture
async def review_repository(db_session: AsyncSession):
    """Provide a ReviewRepository instance for testing."""
    from app.repositories.review_repository import ReviewRepository
    return ReviewRepository(db_session)


@pytest.fixture
async def review_service(db_session: AsyncSession):
    """Provide a ReviewService instance for testing."""
    from app.services.review_service import ReviewService
    return ReviewService(db_session)


@pytest.fixture
async def category_repository(db_session: AsyncSession):
    """Provide a CategoryRepository instance for testing."""
    from app.repositories.category_repository import CategoryRepository
    return CategoryRepository(db_session)


@pytest.fixture
async def category_service(db_session: AsyncSession):
    """Provide a CategoryService instance for testing."""
    from app.services.category_service import CategoryService
    return CategoryService(db_session)


@pytest.fixture
async def sample_tariff(db_session: AsyncSession):
    """Create a sample tariff plan for testing."""
    from app.models.tariff_model import TariffPlan
    from uuid import uuid4
    
    unique_id = str(uuid4())[:8]
    tariff_name = f"BasicPlan_{unique_id}"
    
    tariff = TariffPlan(
        name=tariff_name,
        price_per_month=100000.0,
        max_services=5,
        max_images_per_service=10,
        max_phone_numbers=2,
        max_gallery_images=20,
        max_social_accounts=3,
        allow_website=False,
        allow_cover_image=True,
        monthly_featured_cards=1,
        is_active=True
    )
    db_session.add(tariff)
    await db_session.commit()
    await db_session.refresh(tariff)
    return tariff


@pytest.fixture
async def payment_repository(db_session: AsyncSession):
    """Provide a PaymentRepository instance for testing."""
    from app.repositories.payment_repository import PaymentRepository
    return PaymentRepository(db_session)


@pytest.fixture
async def tariff_service(db_session: AsyncSession):
    """Provide a TariffService instance for testing."""
    from app.services.tariff_service import TariffService
    return TariffService(db_session)

