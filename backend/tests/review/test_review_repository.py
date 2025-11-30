"""
Tests for ReviewRepository.
"""
import pytest
from uuid import uuid4

from app.repositories.review_repository import ReviewRepository
from app.models import Review


@pytest.mark.asyncio
class TestReviewRepository:
    """Test ReviewRepository methods."""
    
    async def test_get_review_by_id(
        self,
        review_repository: ReviewRepository,
        sample_review: Review
    ):
        """Test getting review by ID."""
        review = await review_repository.get_review_by_id(sample_review.id)
        
        assert review is not None
        assert review.id == sample_review.id
        assert review.rating == 5
        assert review.comment == "Excellent service!"
        assert review.is_active is True
        
        # Test non-existent review
        non_existent = await review_repository.get_review_by_id(uuid4())
        assert non_existent is None
    
    async def test_get_reviews_by_service(
        self,
        review_repository: ReviewRepository,
        sample_review: Review,
        sample_service,
        sample_client_user,
        sample_merchant,
        db_session
    ):
        """Test getting reviews by service ID."""
        # Create another review for the same service
        from app.models import Review
        review2 = Review(
            service_id=sample_service.id,
            user_id=sample_client_user.id,
            merchant_id=sample_merchant.id,
            rating=4,
            comment="Good service",
            is_active=True
        )
        db_session.add(review2)
        await db_session.commit()
        
        # Get all reviews for the service
        reviews, total = await review_repository.get_reviews_by_service(
            service_id=sample_service.id,
            include_inactive=False
        )
        
        assert total >= 2
        assert len(reviews) >= 2
        assert all(review.service_id == sample_service.id for review in reviews)
        assert all(review.is_active for review in reviews)
        
        # Test with inactive reviews
        review2.is_active = False
        await db_session.commit()
        
        reviews_active, total_active = await review_repository.get_reviews_by_service(
            service_id=sample_service.id,
            include_inactive=False
        )
        assert total_active == total - 1
        
        reviews_all, total_all = await review_repository.get_reviews_by_service(
            service_id=sample_service.id,
            include_inactive=True
        )
        assert total_all == total
    
    async def test_get_user_review_for_service(
        self,
        review_repository: ReviewRepository,
        sample_review: Review,
        sample_service,
        sample_client_user
    ):
        """Test getting a user's review for a specific service."""
        review = await review_repository.get_user_review_for_service(
            user_id=sample_client_user.id,
            service_id=sample_service.id
        )
        
        assert review is not None
        assert review.id == sample_review.id
        assert review.user_id == sample_client_user.id
        assert review.service_id == sample_service.id
        
        # Test non-existent review
        non_existent = await review_repository.get_user_review_for_service(
            user_id=uuid4(),
            service_id=sample_service.id
        )
        assert non_existent is None
    
    async def test_create_review(
        self,
        review_repository: ReviewRepository,
        sample_service,
        sample_client_user,
        sample_merchant,
        db_session
    ):
        """Test creating a new review."""
        review = Review(
            service_id=sample_service.id,
            user_id=sample_client_user.id,
            merchant_id=sample_merchant.id,
            rating=4,
            comment="Great service!"
        )
        
        created_review = await review_repository.create_review(review)
        
        assert created_review.id is not None
        assert created_review.rating == 4
        assert created_review.comment == "Great service!"
        assert created_review.is_active is True
        
        # Verify it's in the database
        retrieved = await review_repository.get_review_by_id(created_review.id)
        assert retrieved is not None
        assert retrieved.id == created_review.id
    
    async def test_update_review(
        self,
        review_repository: ReviewRepository,
        sample_review: Review
    ):
        """Test updating a review."""
        original_comment = sample_review.comment
        sample_review.rating = 3
        sample_review.comment = "Updated comment"
        
        updated_review = await review_repository.update_review(sample_review)
        
        assert updated_review.rating == 3
        assert updated_review.comment == "Updated comment"
        assert updated_review.updated_at is not None
        
        # Verify update persisted
        retrieved = await review_repository.get_review_by_id(sample_review.id)
        assert retrieved.rating == 3
        assert retrieved.comment == "Updated comment"
    
    async def test_delete_review(
        self,
        review_repository: ReviewRepository,
        sample_service,
        sample_client_user,
        sample_merchant,
        db_session
    ):
        """Test soft deleting a review."""
        # Create a review to delete
        review = Review(
            service_id=sample_service.id,
            user_id=sample_client_user.id,
            merchant_id=sample_merchant.id,
            rating=2,
            comment="Will be deleted"
        )
        db_session.add(review)
        await db_session.commit()
        await db_session.refresh(review)
        
        review_id = review.id
        
        # Soft delete
        deleted = await review_repository.delete_review(review_id)
        assert deleted is True
        
        # Verify soft deleted
        retrieved = await review_repository.get_review_by_id(review_id)
        assert retrieved is not None
        assert retrieved.is_active is False
        
        # Test deleting non-existent review
        deleted_fake = await review_repository.delete_review(uuid4())
        assert deleted_fake is False
    
    async def test_calculate_service_rating(
        self,
        review_repository: ReviewRepository,
        sample_service,
        sample_review,
        sample_client_user,
        sample_merchant,
        db_session
    ):
        """Test calculating service rating."""
        # Create multiple reviews with different ratings
        from app.models import Review
        review1 = Review(
            service_id=sample_service.id,
            user_id=sample_client_user.id,
            merchant_id=sample_merchant.id,
            rating=5,
            is_active=True
        )
        review2 = Review(
            service_id=sample_service.id,
            user_id=sample_client_user.id,
            merchant_id=sample_merchant.id,
            rating=4,
            is_active=True
        )
        review3 = Review(
            service_id=sample_service.id,
            user_id=sample_client_user.id,
            merchant_id=sample_merchant.id,
            rating=3,
            is_active=True
        )
        
        db_session.add_all([review1, review2, review3])
        await db_session.commit()
        
        # Calculate rating
        avg_rating, total_count = await review_repository.calculate_service_rating(
            sample_service.id
        )
        
        # Should include all active reviews (original + 3 new = at least 4)
        assert total_count >= 4
        assert 0 <= avg_rating <= 5
        
        # Test with inactive reviews excluded
        review3.is_active = False
        await db_session.commit()
        
        avg_rating_active, total_active = await review_repository.calculate_service_rating(
            sample_service.id
        )
        assert total_active == total_count - 1
    
    async def test_update_service_rating(
        self,
        review_repository: ReviewRepository,
        sample_service,
        sample_client_user,
        sample_merchant,
        db_session
    ):
        """Test updating service rating and total reviews."""
        from app.models import Review
        
        # Create reviews
        review1 = Review(
            service_id=sample_service.id,
            user_id=sample_client_user.id,
            merchant_id=sample_merchant.id,
            rating=5,
            is_active=True
        )
        review2 = Review(
            service_id=sample_service.id,
            user_id=sample_client_user.id,
            merchant_id=sample_merchant.id,
            rating=4,
            is_active=True
        )
        db_session.add_all([review1, review2])
        await db_session.commit()
        
        # Update service rating
        await review_repository.update_service_rating(sample_service.id)
        await db_session.refresh(sample_service)
        
        assert sample_service.total_reviews >= 2
        assert 0 <= sample_service.overall_rating <= 5

