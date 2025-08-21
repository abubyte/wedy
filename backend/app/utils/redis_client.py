import json
from typing import Any, Optional, Union
import redis.asyncio as redis

from app.core.config import settings


class RedisClient:
    """Async Redis client wrapper."""
    
    def __init__(self):
        self._redis: Optional[redis.Redis] = None
    
    async def get_redis(self) -> redis.Redis:
        """Get Redis connection."""
        if not self._redis:
            self._redis = redis.from_url(settings.REDIS_URL)
        return self._redis
    
    async def get(self, key: str) -> Optional[str]:
        """
        Get value by key.
        
        Args:
            key: Redis key
            
        Returns:
            Optional[str]: Value or None if not found
        """
        r = await self.get_redis()
        value = await r.get(key)
        return value.decode() if value else None
    
    async def set(self, key: str, value: Union[str, int, float], ex: Optional[int] = None) -> bool:
        """
        Set key-value pair.
        
        Args:
            key: Redis key
            value: Value to store
            ex: Expiration time in seconds
            
        Returns:
            bool: True if successful
        """
        r = await self.get_redis()
        return await r.set(key, str(value), ex=ex)
    
    async def setex(self, key: str, time: int, value: Union[str, int, float]) -> bool:
        """
        Set key-value pair with expiration.
        
        Args:
            key: Redis key
            time: Expiration time in seconds
            value: Value to store
            
        Returns:
            bool: True if successful
        """
        r = await self.get_redis()
        return await r.setex(key, time, str(value))
    
    async def delete(self, key: str) -> int:
        """
        Delete key.
        
        Args:
            key: Redis key to delete
            
        Returns:
            int: Number of keys deleted
        """
        r = await self.get_redis()
        return await r.delete(key)
    
    async def incr(self, key: str, amount: int = 1) -> int:
        """
        Increment key value.
        
        Args:
            key: Redis key
            amount: Amount to increment
            
        Returns:
            int: New value after increment
        """
        r = await self.get_redis()
        return await r.incr(key, amount)
    
    async def expire(self, key: str, time: int) -> bool:
        """
        Set expiration time for key.
        
        Args:
            key: Redis key
            time: Expiration time in seconds
            
        Returns:
            bool: True if successful
        """
        r = await self.get_redis()
        return await r.expire(key, time)
    
    async def exists(self, key: str) -> bool:
        """
        Check if key exists.
        
        Args:
            key: Redis key
            
        Returns:
            bool: True if key exists
        """
        r = await self.get_redis()
        return bool(await r.exists(key))
    
    async def get_json(self, key: str) -> Optional[Any]:
        """
        Get JSON value by key.
        
        Args:
            key: Redis key
            
        Returns:
            Optional[Any]: Parsed JSON value or None
        """
        value = await self.get(key)
        if value:
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                return None
        return None
    
    async def set_json(self, key: str, value: Any, ex: Optional[int] = None) -> bool:
        """
        Set JSON value.
        
        Args:
            key: Redis key
            value: Value to serialize and store
            ex: Expiration time in seconds
            
        Returns:
            bool: True if successful
        """
        try:
            json_value = json.dumps(value)
            return await self.set(key, json_value, ex)
        except (TypeError, ValueError):
            return False
    
    async def close(self):
        """Close Redis connection."""
        if self._redis:
            await self._redis.close()