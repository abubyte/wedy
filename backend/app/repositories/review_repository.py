from typing import List, Optional, Tuple
from uuid import UUID
from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_
from sqlmodel import SQLModel

from app.models.review_model import Review
from app.models.service_model import Service
from app.models.user_model import User
from app.repositories.base import BaseRepository


class ReviewRepository(BaseRepository[Review]):
    """Repository for review-related database operations."""
    
    def __init__(self, db: AsyncSession):
        super().__init__(Review, db)
    
    async def get_review_by_id(self, review_id: UUID) -> Optional[Review]:
        """
        Get review by ID with relationships.
        
        Args:
            review_id: UUID of the review
            
        Returns:
            Review or None
        """
        statement = (
            select(Review)
            .where(Review.id == review_id)
            .options(
                # Load relationships if needed
            )
        )
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()
    
    async def get_reviews_by_service(
        self,
        service_id: UUID,
        include_inactive: bool = False,
        offset: int = 0,
        limit: int = 100
    ) -> Tuple[List[Review], int]:
        """
        Get all reviews for a service with pagination.
        
        Args:
            service_id: UUID of the service
            include_inactive: Whether to include inactive reviews
            offset: Pagination offset
            limit: Pagination limit
            
        Returns:
            Tuple of (reviews_list, total_count)
        """
        # Count query
        count_conditions = [Review.service_id == service_id]
        if not include_inactive:
            count_conditions.append(Review.is_active == True)
        
        count_statement = select(func.count(Review.id)).where(and_(*count_conditions))
        count_result = await self.db.execute(count_statement)
        total_count = count_result.scalar_one()
        
        # Reviews query
        statement = select(Review).where(and_(*count_conditions))
        statement = statement.order_by(Review.created_at.desc()).offset(offset).limit(limit)
        
        result = await self.db.execute(statement)
        reviews = result.scalars().all()
        
        return reviews, total_count
    
    async def get_reviews_by_merchant(
        self,
        merchant_id: UUID,
        include_inactive: bool = False,
        offset: int = 0,
        limit: int = 100
    ) -> Tuple[List[Review], int]:
        """
        Get all reviews for a merchant with pagination.
        
        Args:
            merchant_id: UUID of the merchant
            include_inactive: Whether to include inactive reviews
            offset: Pagination offset
            limit: Pagination limit
            
        Returns:
            Tuple of (reviews_list, total_count)
        """
        # Count query
        count_conditions = [Review.merchant_id == merchant_id]
        if not include_inactive:
            count_conditions.append(Review.is_active == True)
        
        count_statement = select(func.count(Review.id)).where(and_(*count_conditions))
        count_result = await self.db.execute(count_statement)
        total_count = count_result.scalar_one()
        
        # Reviews query
        statement = select(Review).where(and_(*count_conditions))
        statement = statement.order_by(Review.created_at.desc()).offset(offset).limit(limit)
        
        result = await self.db.execute(statement)
        reviews = result.scalars().all()
        
        return reviews, total_count
    
    async def get_reviews_by_user(
        self,
        user_id: UUID,
        include_inactive: bool = False,
        offset: int = 0,
        limit: int = 100
    ) -> Tuple[List[Review], int]:
        """
        Get all reviews by a user with pagination.
        
        Args:
            user_id: UUID of the user
            include_inactive: Whether to include inactive reviews
            offset: Pagination offset
            limit: Pagination limit
            
        Returns:
            Tuple of (reviews_list, total_count)
        """
        # Count query
        count_conditions = [Review.user_id == user_id]
        if not include_inactive:
            count_conditions.append(Review.is_active == True)
        
        count_statement = select(func.count(Review.id)).where(and_(*count_conditions))
        count_result = await self.db.execute(count_statement)
        total_count = count_result.scalar_one()
        
        # Reviews query
        statement = select(Review).where(and_(*count_conditions))
        statement = statement.order_by(Review.created_at.desc()).offset(offset).limit(limit)
        
        result = await self.db.execute(statement)
        reviews = result.scalars().all()
        
        return reviews, total_count
    
    async def get_user_review_for_service(
        self,
        user_id: UUID,
        service_id: UUID
    ) -> Optional[Review]:
        """
        Get a user's review for a specific service.
        
        Args:
            user_id: UUID of the user
            service_id: UUID of the service
            
        Returns:
            Review or None
        """
        statement = select(Review).where(
            and_(
                Review.user_id == user_id,
                Review.service_id == service_id
            )
        )
        result = await self.db.execute(statement)
        return result.scalar_one_or_none()
    
    async def create_review(self, review: Review) -> Review:
        """
        Create a new review.
        
        Args:
            review: Review instance to create
            
        Returns:
            Created Review
        """
        self.db.add(review)
        await self.db.commit()
        await self.db.refresh(review)
        return review
    
    async def update_review(self, review: Review) -> Review:
        """
        Update an existing review.
        
        Args:
            review: Review instance to update
            
        Returns:
            Updated Review
        """
        review.updated_at = datetime.now()
        self.db.add(review)
        await self.db.commit()
        await self.db.refresh(review)
        return review
    
    async def delete_review(self, review_id: UUID) -> bool:
        """
        Soft delete a review (set is_active=False).
        
        Args:
            review_id: UUID of the review to delete
            
        Returns:
            True if deleted, False if not found
        """
        review = await self.get_review_by_id(review_id)
        if review:
            review.is_active = False
            review.updated_at = datetime.now()
            await self.update_review(review)
            return True
        return False
    
    async def calculate_service_rating(self, service_id: UUID) -> Tuple[float, int]:
        """
        Calculate average rating and total review count for a service.
        
        Args:
            service_id: UUID of the service
            
        Returns:
            Tuple of (average_rating, total_count)
        """
        statement = select(
            func.avg(Review.rating).label('avg_rating'),
            func.count(Review.id).label('total_count')
        ).where(
            and_(
                Review.service_id == service_id,
                Review.is_active == True
            )
        )
        result = await self.db.execute(statement)
        row = result.first()
        
        if row and row.total_count > 0:
            avg_rating = float(row.avg_rating) if row.avg_rating else 0.0
            total_count = int(row.total_count)
            return avg_rating, total_count
        return 0.0, 0
    
    async def update_service_rating(self, service_id: UUID) -> None:
        """
        Update service's overall_rating and total_reviews based on active reviews.
        
        Args:
            service_id: UUID of the service
        """
        avg_rating, total_count = await self.calculate_service_rating(service_id)
        
        service = await self.db.get(Service, service_id)
        if service:
            service.overall_rating = avg_rating
            service.total_reviews = total_count
            self.db.add(service)
            await self.db.commit()
    
    async def get_all_reviews(
        self,
        service_id: Optional[UUID] = None,
        merchant_id: Optional[UUID] = None,
        user_id: Optional[UUID] = None,
        include_inactive: bool = False,
        offset: int = 0,
        limit: int = 100
    ) -> Tuple[List[Review], int]:
        """
        Get all reviews with optional filters and pagination.
        
        Args:
            service_id: Optional filter by service ID
            merchant_id: Optional filter by merchant ID
            user_id: Optional filter by user ID
            include_inactive: Whether to include inactive reviews
            offset: Pagination offset
            limit: Pagination limit
            
        Returns:
            Tuple of (reviews_list, total_count)
        """
        # Build conditions
        conditions = []
        if service_id:
            conditions.append(Review.service_id == service_id)
        if merchant_id:
            conditions.append(Review.merchant_id == merchant_id)
        if user_id:
            conditions.append(Review.user_id == user_id)
        if not include_inactive:
            conditions.append(Review.is_active == True)
        
        # Count query
        count_statement = select(func.count(Review.id))
        if conditions:
            count_statement = count_statement.where(and_(*conditions))
        count_result = await self.db.execute(count_statement)
        total_count = count_result.scalar_one()
        
        # Reviews query
        statement = select(Review)
        if conditions:
            statement = statement.where(and_(*conditions))
        statement = statement.order_by(Review.created_at.desc()).offset(offset).limit(limit)
        
        result = await self.db.execute(statement)
        reviews = result.scalars().all()
        
        return reviews, total_count

