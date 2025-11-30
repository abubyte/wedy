from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlmodel import SQLModel

from app.core.config import settings


# Create async engine
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    pool_size=settings.DATABASE_POOL_SIZE,
    max_overflow=settings.DATABASE_MAX_OVERFLOW,
    pool_pre_ping=True,
)

# Create async session factory
AsyncSessionLocal = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency to get database session.
    
    Yields:
        AsyncSession: Database session
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def create_db_and_tables() -> None:
    """
    Create database tables.
    This should be called during application startup.
    """
    async with engine.begin() as conn:
        # Import all models to ensure they are registered with SQLModel
        from app.models import User, Service, Payment, Review, DailyServiceMetrics, MerchantDailyMetrics  # noqa
        
        # Create all tables
        await conn.run_sync(SQLModel.metadata.create_all)


async def close_db_connection() -> None:
    """
    Close database connection.
    This should be called during application shutdown.
    """
    await engine.dispose()