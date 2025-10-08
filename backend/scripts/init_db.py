import asyncio
import sys
from pathlib import Path

# Add the app directory to the Python path
sys.path.append(str(Path(__file__).parent.parent))

from app.core.database import create_db_and_tables
from app.models import *  # Import all models
from app.core.config import settings


async def init_database():
    """Initialize the database with tables."""
    print("Initializing database...")
    print(f"Database URL: {settings.DATABASE_URL}")
    
    try:
        await create_db_and_tables()
        print("Database tables created successfully!")
    except Exception as e:
        print(f"Error creating database tables: {e}")
        raise


if __name__ == "__main__":
    asyncio.run(init_database())