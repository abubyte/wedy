import pytest
import asyncio
from typing import Generator, AsyncGenerator
from unittest.mock import Mock
from sqlalchemy import create_engine
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from sqlmodel import SQLModel, Session
from fastapi.testclient import TestClient
from httpx import AsyncClient

from app.models import *  # Import all models to register them
from app.main import app
from app.core.database import get_db_session


# Test database URL (in-memory SQLite)
TEST_DATABASE_URL = "sqlite:///:memory:"


@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
def engine():
    """Create test database engine."""
    engine = create_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    SQLModel.metadata.create_all(engine)
    yield engine


@pytest.fixture
def session(engine) -> Generator[Session, None, None]:
    """Create database session for tests."""
    with Session(engine) as session:
        yield session


@pytest.fixture
def client(session: Session) -> Generator[TestClient, None, None]:
    """Create test client with overridden dependencies."""
    def get_session_override():
        return session

    app.dependency_overrides[get_db_session] = get_session_override
    client = TestClient(app)
    yield client
    app.dependency_overrides.clear()


@pytest.fixture
async def async_client(session: Session) -> AsyncGenerator[AsyncClient, None]:
    """Create async test client."""
    def get_session_override():
        return session

    app.dependency_overrides[get_db_session] = get_session_override
    
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac
    
    app.dependency_overrides.clear()


# Mock external services
@pytest.fixture
def mock_sms_service():
    """Mock SMS service for testing."""
    return Mock()


@pytest.fixture
def mock_payment_providers():
    """Mock payment providers for testing."""
    return {
        'payme': Mock(),
        'click': Mock(),
        'uzumbank': Mock()
    }


@pytest.fixture
def mock_s3_service():
    """Mock AWS S3 service for testing."""
    return Mock()


# Sample test data fixtures
@pytest.fixture
def sample_user_data():
    """Sample user data for testing."""
    return {
        "phone_number": "998901234567",
        "name": "Test User",
        "user_type": "merchant"
    }


@pytest.fixture
def sample_tariff_plan_data():
    """Sample tariff plan data for testing."""
    return {
        "name": "Basic Plan",
        "price_per_month": 50000.0,
        "max_services": 10,
        "max_images_per_service": 5,
        "max_phone_numbers": 2,
        "max_gallery_images": 20,
        "max_social_accounts": 3,
        "allow_website": False,
        "allow_cover_image": True,
        "monthly_featured_cards": 1
    }


@pytest.fixture
def sample_payment_data():
    """Sample payment data for testing."""
    return {
        "amount": 50000.0,
        "payment_type": "tariff_subscription",
        "payment_method": "payme"
    }


@pytest.fixture
def sample_subscription_data():
    """Sample subscription data for testing."""
    return {
        "start_date": "2025-08-31",
        "end_date": "2025-09-30",
        "status": "active"
    }