from typing import List, Optional, Tuple
from uuid import UUID
from datetime import datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError, ConflictError, ValidationError, ForbiddenError
from app.models import Review, Service, User, Merchant
from app.repositories.review_repository import ReviewRepository
from app.schemas.review_schema import (
    ReviewCreateRequest,
    ReviewUpdateRequest,
    ReviewDetailResponse,
    ReviewListResponse,
    ReviewUserResponse,
    ReviewServiceResponse
)
from app.schemas.common_schema import PaginationParams


class ReviewService:
    """Service for managing reviews."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.review_repo = ReviewRepository(db)
    
    async def get_review(self, review_id: UUID) -> ReviewDetailResponse:
        """
        Get review by ID with relationships.
        
        Args:
            review_id: UUID of the review
            
        Returns:
            ReviewDetailResponse with review details
            
        Raises:
            NotFoundError: If review not found
        """
        review = await self.review_repo.get_review_by_id(review_id)
        if not review:
            raise NotFoundError(f"Review with ID {review_id} not found")
        
        # Load relationships
        user = await self.db.get(User, review.user_id)
        service = await self.db.get(Service, review.service_id)
        
        user_response = None
        if user:
            user_response = ReviewUserResponse(
                id=user.id,
                name=user.name,
                avatar_url=user.avatar_url
            )
        
        service_response = None
        if service:
            service_response = ReviewServiceResponse(
                id=service.id,
                name=service.name
            )
        
        return ReviewDetailResponse(
            id=review.id,
            service_id=review.service_id,
            user_id=review.user_id,
            merchant_id=review.merchant_id,
            rating=review.rating,
            comment=review.comment,
            is_active=review.is_active,
            created_at=review.created_at,
            updated_at=review.updated_at,
            user=user_response,
            service=service_response
        )
    
    async def list_reviews(
        self,
        service_id: Optional[UUID] = None,
        merchant_id: Optional[UUID] = None,
        user_id: Optional[UUID] = None,
        include_inactive: bool = False,
        pagination: PaginationParams = PaginationParams()
    ) -> ReviewListResponse:
        """
        List reviews with optional filters and pagination.
        
        Args:
            service_id: Optional filter by service ID
            merchant_id: Optional filter by merchant ID
            user_id: Optional filter by user ID
            include_inactive: Whether to include inactive reviews
            pagination: Pagination parameters
            
        Returns:
            ReviewListResponse with paginated reviews
        """
        reviews, total = await self.review_repo.get_all_reviews(
            service_id=service_id,
            merchant_id=merchant_id,
            user_id=user_id,
            include_inactive=include_inactive,
            offset=pagination.offset,
            limit=pagination.limit
        )
        
        # Build response with relationships
        review_responses = []
        for review in reviews:
            # Load relationships
            user = await self.db.get(User, review.user_id)
            service = await self.db.get(Service, review.service_id)
            
            user_response = None
            if user:
                user_response = ReviewUserResponse(
                    id=user.id,
                    name=user.name,
                    avatar_url=user.avatar_url
                )
            
            service_response = None
            if service:
                service_response = ReviewServiceResponse(
                    id=service.id,
                    name=service.name
                )
            
            review_responses.append(
                ReviewDetailResponse(
                    id=review.id,
                    service_id=review.service_id,
                    user_id=review.user_id,
                    merchant_id=review.merchant_id,
                    rating=review.rating,
                    comment=review.comment,
                    is_active=review.is_active,
                    created_at=review.created_at,
                    updated_at=review.updated_at,
                    user=user_response,
                    service=service_response
                )
            )
        
        total_pages = (total + pagination.limit - 1) // pagination.limit
        has_more = pagination.page < total_pages
        
        return ReviewListResponse(
            reviews=review_responses,
            total=total,
            page=pagination.page,
            limit=pagination.limit,
            has_more=has_more,
            total_pages=total_pages
        )
    
    async def create_review(
        self,
        user_id: UUID,
        request: ReviewCreateRequest
    ) -> ReviewDetailResponse:
        """
        Create a new review.
        
        Args:
            user_id: UUID of the user creating the review
            request: Review creation data
            
        Returns:
            ReviewDetailResponse for created review
            
        Raises:
            NotFoundError: If service or user not found
            ConflictError: If user already reviewed this service
            ValidationError: If user is not a client
        """
        # Verify user exists and is a client
        user = await self.db.get(User, user_id)
        if not user:
            raise NotFoundError("User not found")
        
        from app.models.user_model import UserType
        if user.user_type != UserType.CLIENT:
            raise ValidationError("Only client users can create reviews")
        
        # Verify service exists
        service = await self.db.get(Service, request.service_id)
        if not service or not service.is_active:
            raise NotFoundError("Service not found or inactive")
        
        # Check if user already reviewed this service
        existing_review = await self.review_repo.get_user_review_for_service(
            user_id=user_id,
            service_id=request.service_id
        )
        if existing_review:
            raise ConflictError("You have already reviewed this service")
        
        # Get merchant_id from service
        merchant = await self.db.get(Merchant, service.merchant_id)
        if not merchant:
            raise NotFoundError("Merchant not found")
        
        # Create review
        review = Review(
            service_id=request.service_id,
            user_id=user_id,
            merchant_id=merchant.id,
            rating=request.rating,
            comment=request.comment
        )
        
        review = await self.review_repo.create_review(review)
        
        # Update service rating and review count
        await self.review_repo.update_service_rating(request.service_id)
        
        # Load relationships for response
        user = await self.db.get(User, review.user_id)
        service = await self.db.get(Service, review.service_id)
        
        user_response = None
        if user:
            user_response = ReviewUserResponse(
                id=user.id,
                name=user.name,
                avatar_url=user.avatar_url
            )
        
        service_response = None
        if service:
            service_response = ReviewServiceResponse(
                id=service.id,
                name=service.name
            )
        
        return ReviewDetailResponse(
            id=review.id,
            service_id=review.service_id,
            user_id=review.user_id,
            merchant_id=review.merchant_id,
            rating=review.rating,
            comment=review.comment,
            is_active=review.is_active,
            created_at=review.created_at,
            updated_at=review.updated_at,
            user=user_response,
            service=service_response
        )
    
    async def update_review(
        self,
        review_id: UUID,
        user_id: UUID,
        request: ReviewUpdateRequest
    ) -> ReviewDetailResponse:
        """
        Update an existing review.
        
        Args:
            review_id: UUID of the review to update
            user_id: UUID of the user updating the review
            request: Review update data
            
        Returns:
            ReviewDetailResponse for updated review
            
        Raises:
            NotFoundError: If review not found
            ForbiddenError: If user doesn't own the review
        """
        review = await self.review_repo.get_review_by_id(review_id)
        if not review:
            raise NotFoundError(f"Review with ID {review_id} not found")
        
        # Verify ownership
        if review.user_id != user_id:
            raise ForbiddenError("You can only update your own reviews")
        
        # Update fields
        if request.rating is not None:
            review.rating = request.rating
        
        if request.comment is not None:
            review.comment = request.comment
        
        review.updated_at = datetime.now()
        review = await self.review_repo.update_review(review)
        
        # Update service rating and review count
        await self.review_repo.update_service_rating(review.service_id)
        
        # Load relationships for response
        user = await self.db.get(User, review.user_id)
        service = await self.db.get(Service, review.service_id)
        
        user_response = None
        if user:
            user_response = ReviewUserResponse(
                id=user.id,
                name=user.name,
                avatar_url=user.avatar_url
            )
        
        service_response = None
        if service:
            service_response = ReviewServiceResponse(
                id=service.id,
                name=service.name
            )
        
        return ReviewDetailResponse(
            id=review.id,
            service_id=review.service_id,
            user_id=review.user_id,
            merchant_id=review.merchant_id,
            rating=review.rating,
            comment=review.comment,
            is_active=review.is_active,
            created_at=review.created_at,
            updated_at=review.updated_at,
            user=user_response,
            service=service_response
        )
    
    async def delete_review(
        self,
        review_id: UUID,
        user_id: UUID
    ) -> bool:
        """
        Delete a review (soft delete).
        
        Args:
            review_id: UUID of the review to delete
            user_id: UUID of the user deleting the review
            
        Returns:
            True if deleted successfully
            
        Raises:
            NotFoundError: If review not found
            ForbiddenError: If user doesn't own the review
        """
        review = await self.review_repo.get_review_by_id(review_id)
        if not review:
            raise NotFoundError(f"Review with ID {review_id} not found")
        
        # Verify ownership
        if review.user_id != user_id:
            raise ForbiddenError("You can only delete your own reviews")
        
        # Soft delete
        service_id = review.service_id
        deleted = await self.review_repo.delete_review(review_id)
        
        if deleted:
            # Update service rating and review count
            await self.review_repo.update_service_rating(service_id)
        
        return deleted

