from typing import Generic, TypeVar, Type, Optional, List, Union

from sqlalchemy import func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import SQLModel, select

T = TypeVar("T", bound=SQLModel)

# ID can be str (9-digit numeric), int (auto-increment), or UUID
IDType = Union[str, int, "UUID"]


class BaseRepository(Generic[T]):
    """Base repository class with common CRUD operations."""
    
    def __init__(self, model_class: Type[T], db: AsyncSession):
        self.model_class = model_class
        self.db = db
    
    async def get_by_id(self, id: IDType) -> Optional[T]:
        """
        Get a record by ID.
        
        Args:
            id: ID of the record (can be str, int, or UUID)
            
        Returns:
            Model instance or None if not found
        """
        statement = select(self.model_class).where(self.model_class.id == id)
        result = await self.db.execute(statement)
        # Return mapped model instance or None
        return result.scalar_one_or_none()
    
    async def get_all(self, offset: int = 0, limit: int = 100) -> List[T]:
        """
        Get all records with pagination.
        
        Args:
            offset: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of model instances
        """
        statement = select(self.model_class).offset(offset).limit(limit)
        result = await self.db.execute(statement)
        # Return list of mapped model instances
        return result.scalars().all()
    
    async def count(self) -> int:
        """
        Count total records.
        
        Returns:
            Total count of records
        """
        statement = select(func.count(self.model_class.id))
        result = await self.db.execute(statement)
        # Return scalar count
        return result.scalar_one()
    
    async def create(self, obj: T) -> T:
        """
        Create a new record.
        
        Args:
            obj: Model instance to create
            
        Returns:
            Created model instance
        """
        self.db.add(obj)
        await self.db.commit()
        await self.db.refresh(obj)
        return obj
    
    async def update(self, obj: T) -> T:
        """
        Update an existing record.
        
        Args:
            obj: Model instance to update
            
        Returns:
            Updated model instance
        """
        self.db.add(obj)
        await self.db.commit()
        await self.db.refresh(obj)
        return obj
    
    async def delete(self, id: IDType) -> bool:
        """
        Delete a record by ID.
        
        Args:
            id: ID of the record to delete (can be str, int, or UUID)
            
        Returns:
            True if deleted, False if not found
        """
        obj = await self.get_by_id(id)
        if obj:
            await self.db.delete(obj)
            await self.db.commit()
            return True
        return False
    
    async def exists(self, id: IDType) -> bool:
        """
        Check if a record exists by ID.
        
        Args:
            id: ID of the record (can be str, int, or UUID)
            
        Returns:
            True if exists, False otherwise
        """
        statement = select(func.count(self.model_class.id)).where(self.model_class.id == id)
        result = await self.db.execute(statement)
        count = result.scalar_one()
        return count > 0