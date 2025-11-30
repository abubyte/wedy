from typing import Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.models.user_model import User
from app.models.merchant_model import Merchant
from app.repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    """Repository for user-related database operations."""
    
    def __init__(self, db: AsyncSession):
        super().__init__(User, db)
    
    async def get_by_phone_number(self, phone_number: str) -> Optional[User]:
        """
        Get user by phone number.
        
        Args:
            phone_number: Phone number to search for
            
        Returns:
            User instance or None if not found
        """
        statement = select(User).where(User.phone_number == phone_number)
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()
    
    async def get_merchant_by_user_id(self, user_id: UUID) -> Optional[Merchant]:
        """
        Get merchant profile by user ID.
        
        Args:
            user_id: UUID of the user
            
        Returns:
            Merchant instance or None if not found
        """
        statement = select(Merchant).where(Merchant.user_id == user_id)
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()
    
    async def is_phone_number_taken(self, phone_number: str, exclude_user_id: Optional[UUID] = None) -> bool:
        """
        Check if phone number is already taken by another user.
        
        Args:
            phone_number: Phone number to check
            exclude_user_id: Optional user ID to exclude from check
            
        Returns:
            True if phone number is taken, False otherwise
        """
        statement = select(User).where(User.phone_number == phone_number)
        
        if exclude_user_id:
            statement = statement.where(User.id != exclude_user_id)
        
        result = await self.db.execute(statement)
        return result.scalar_one_or_none() is not None
    
    async def soft_delete_user(self, user_id: UUID) -> bool:
        """
        Soft delete a user by setting is_active=False.
        
        Args:
            user_id: UUID of the user to delete
            
        Returns:
            True if deleted, False if not found
        """
        user = await self.get_by_id(user_id)
        if user:
            user.is_active = False
            await self.update(user)
            return True
        return False