import asyncio
import sys
import time
from pathlib import Path

# Add the app directory to the Python path
sys.path.append(str(Path(__file__).parent.parent))

import asyncpg
from app.core.config import settings


async def wait_for_database():
    """Wait for the database to be ready."""
    max_retries = 30
    retry_interval = 2
    
    for attempt in range(max_retries):
        try:
            # Extract connection details from DATABASE_URL
            # Format: postgresql+asyncpg://user:password@host:port/database
            url = settings.DATABASE_URL.replace('postgresql+asyncpg://', 'postgresql://')
            
            conn = await asyncpg.connect(url)
            await conn.execute('SELECT 1')
            await conn.close()
            
            print("✅ Database is ready!")
            return True
            
        except Exception as e:
            print(f"⏳ Waiting for database... (attempt {attempt + 1}/{max_retries})")
            print(f"   Error: {e}")
            
            if attempt == max_retries - 1:
                print("❌ Database failed to become ready")
                return False
                
            time.sleep(retry_interval)
    
    return False


if __name__ == "__main__":
    success = asyncio.run(wait_for_database())
    sys.exit(0 if success else 1)
