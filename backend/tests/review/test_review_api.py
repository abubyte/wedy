"""
Tests for Review API endpoints.
"""
import pytest
from uuid import uuid4
from httpx import AsyncClient
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api.v1.reviews import router
from app.models import User, UserType
from app.core.security import create_access_token


# Create a test FastAPI app
@pytest.fixture
async def test_app(db_session):
    """Create a FastAPI test application."""
    from fastapi.responses import JSONResponse
    from app.core.exceptions import WedyException, NotFoundError, ConflictError, ValidationError, ForbiddenError
    from fastapi import HTTPException, status, Request
    
    app = FastAPI()
    app.include_router(router, prefix="/api/v1/reviews", tags=["Reviews"])
    
    # Override database session dependency
    from app.core.database import get_db_session
    async def override_get_db_session():
        yield db_session
    
    app.dependency_overrides[get_db_session] = override_get_db_session
    
    # Add exception handlers (same as main.py)
    @app.exception_handler(WedyException)
    async def wedy_exception_handler(request: Request, exc: WedyException) -> JSONResponse:
        from app.core.exceptions import map_exception_to_http
        http_exc = map_exception_to_http(exc)
        return JSONResponse(
            status_code=http_exc.status_code,
            content={
                "error": {
                    "message": exc.message,
                    "details": exc.details,
                    "type": exc.__class__.__name__
                }
            }
        )
    
    @app.exception_handler(HTTPException)
    async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "error": {
                    "message": exc.detail,
                    "type": "HTTPException"
                }
            }
        )
    
    yield app
    
    # Clean up overrides
    app.dependency_overrides.clear()


@pytest.fixture
async def client_user_token(sample_client_user):
    """Create an access token for the client user."""
    return create_access_token(str(sample_client_user.id))


@pytest.fixture
async def merchant_user_token(sample_merchant_user):
    """Create an access token for the merchant user."""
    return create_access_token(str(sample_merchant_user.id))


@pytest.fixture
async def authenticated_client(test_app, sample_client_user):
    """Create an authenticated async client with client user."""
    from app.api.deps import get_current_user, get_current_client
    
    # Override authentication dependencies
    async def override_get_current_user():
        return sample_client_user
    
    async def override_get_current_client():
        return sample_client_user
    
    test_app.dependency_overrides[get_current_user] = override_get_current_user
    test_app.dependency_overrides[get_current_client] = override_get_current_client
    
    async with AsyncClient(app=test_app, base_url="http://test") as ac:
        yield ac


@pytest.fixture
async def unauthenticated_client(test_app):
    """Create an unauthenticated async client."""
    async with AsyncClient(app=test_app, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
class TestReviewAPI:
    """Test Review API endpoints."""
    
    async def test_get_service_reviews_public(
        self,
        test_app,
        db_session,
        sample_review,
        sample_service,
        sample_client_user,
        sample_merchant,
        unauthenticated_client
    ):
        """Test GET /services/{service_id}/reviews (public endpoint)."""
        from app.models import Review
        
        # Create another review
        review2 = Review(
            service_id=sample_service.id,
            user_id=sample_client_user.id,
            merchant_id=sample_merchant.id,
            rating=4,
            comment="Another review",
            is_active=True
        )
        db_session.add(review2)
        await db_session.commit()
        
        response = await unauthenticated_client.get(
            f"/api/v1/reviews/services/{sample_service.id}/reviews"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 2
        assert len(data["reviews"]) >= 2
        assert all(review["service_id"] == str(sample_service.id) for review in data["reviews"])
    
    async def test_get_service_reviews_with_pagination(
        self,
        test_app,
        db_session,
        sample_service,
        sample_client_user,
        sample_merchant,
        unauthenticated_client
    ):
        """Test GET /services/{service_id}/reviews with pagination."""
        from app.models import Review
        
        # Create multiple reviews
        for i in range(5):
            review = Review(
                service_id=sample_service.id,
                user_id=sample_client_user.id,
                merchant_id=sample_merchant.id,
                rating=5,
                comment=f"Review {i+1}",
                is_active=True
            )
            db_session.add(review)
        await db_session.commit()
        
        response = await unauthenticated_client.get(
            f"/api/v1/reviews/services/{sample_service.id}/reviews",
            params={"page": 1, "limit": 2}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 1
        assert data["limit"] == 2
        assert len(data["reviews"]) == 2
        assert data["total"] >= 5
    
    async def test_list_reviews_public(
        self,
        test_app,
        db_session,
        sample_review,
        sample_service,
        unauthenticated_client
    ):
        """Test GET / (list all reviews, public endpoint)."""
        response = await unauthenticated_client.get("/api/v1/reviews/")
        
        assert response.status_code == 200
        data = response.json()
        assert "reviews" in data
        assert "total" in data
        assert data["total"] >= 1
    
    async def test_list_reviews_with_filters(
        self,
        test_app,
        db_session,
        sample_review,
        sample_service,
        sample_client_user,
        unauthenticated_client
    ):
        """Test GET / with filters."""
        # Filter by service
        response = await unauthenticated_client.get(
            "/api/v1/reviews/",
            params={"service_id": str(sample_service.id)}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert all(review["service_id"] == str(sample_service.id) for review in data["reviews"])
        
        # Filter by user
        response2 = await unauthenticated_client.get(
            "/api/v1/reviews/",
            params={"user_id": str(sample_client_user.id)}
        )
        
        assert response2.status_code == 200
        data2 = response2.json()
        assert all(review["user_id"] == str(sample_client_user.id) for review in data2["reviews"])
    
    async def test_get_review_by_id_public(
        self,
        test_app,
        db_session,
        sample_review,
        unauthenticated_client
    ):
        """Test GET /{review_id} (public endpoint)."""
        response = await unauthenticated_client.get(
            f"/api/v1/reviews/{sample_review.id}"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(sample_review.id)
        assert data["rating"] == 5
        assert data["comment"] == "Excellent service!"
    
    async def test_get_review_not_found(
        self,
        test_app,
        unauthenticated_client
    ):
        """Test GET /{review_id} with non-existent review."""
        response = await unauthenticated_client.get(
            f"/api/v1/reviews/{uuid4()}"
        )
        
        assert response.status_code == 404
    
    async def test_create_review_authenticated(
        self,
        test_app,
        db_session,
        sample_client_user,
        sample_service,
        authenticated_client
    ):
        """Test POST / (create review, authenticated)."""
        from app.models import Review
        
        # First, ensure no existing review for this service by this user
        from sqlmodel import select
        statement = select(Review).where(
            Review.service_id == sample_service.id,
            Review.user_id == sample_client_user.id,
            Review.is_active == True
        )
        result = await db_session.execute(statement)
        existing_reviews = result.scalars().all()
        
        # Remove any existing reviews
        for review in existing_reviews:
            review.is_active = False
        await db_session.commit()
        
        response = await authenticated_client.post(
            "/api/v1/reviews/",
            json={
                "service_id": str(sample_service.id),
                "rating": 5,
                "comment": "Great service from API!"
            }
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["rating"] == 5
        assert data["comment"] == "Great service from API!"
        assert data["service_id"] == str(sample_service.id)
        assert data["user_id"] == str(sample_client_user.id)
    
    async def test_create_review_unauthenticated(
        self,
        test_app,
        sample_service,
        unauthenticated_client
    ):
        """Test POST / without authentication."""
        response = await unauthenticated_client.post(
            "/api/v1/reviews/",
            json={
                "service_id": str(sample_service.id),
                "rating": 5,
                "comment": "Test"
            }
        )
        
        assert response.status_code == 403  # Forbidden - no authentication
    
    async def test_create_review_duplicate(
        self,
        test_app,
        db_session,
        sample_review,
        sample_client_user,
        sample_service,
        authenticated_client
    ):
        """Test creating duplicate review returns 409 Conflict."""
        response = await authenticated_client.post(
            "/api/v1/reviews/",
            json={
                "service_id": str(sample_service.id),
                "rating": 4,
                "comment": "Another review"
            }
        )
        
        assert response.status_code == 409  # Conflict
        error_data = response.json()
        # Error can be in "detail" or "error.message" depending on handler
        error_msg = error_data.get("detail") or error_data.get("error", {}).get("message", "")
        assert "already reviewed" in error_msg.lower()
    
    async def test_update_review_authenticated(
        self,
        test_app,
        db_session,
        sample_review,
        sample_client_user,
        authenticated_client
    ):
        """Test PUT /{review_id} (update review, authenticated)."""
        response = await authenticated_client.put(
            f"/api/v1/reviews/{sample_review.id}",
            json={
                "rating": 4,
                "comment": "Updated via API"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["rating"] == 4
        assert data["comment"] == "Updated via API"
    
    async def test_update_review_unauthenticated(
        self,
        test_app,
        sample_review,
        unauthenticated_client
    ):
        """Test PUT /{review_id} without authentication."""
        response = await unauthenticated_client.put(
            f"/api/v1/reviews/{sample_review.id}",
            json={
                "rating": 4,
                "comment": "Updated"
            }
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_update_review_not_found(
        self,
        test_app,
        sample_client_user,
        authenticated_client
    ):
        """Test PUT /{review_id} with non-existent review."""
        response = await authenticated_client.put(
            f"/api/v1/reviews/{uuid4()}",
            json={
                "rating": 4,
                "comment": "Updated"
            }
        )
        
        assert response.status_code == 404
    
    async def test_update_review_forbidden(
        self,
        test_app,
        db_session,
        sample_review,
        sample_client_user,
        authenticated_client
    ):
        """Test updating someone else's review returns 403."""
        # The authenticated_client uses sample_client_user who owns the review
        # But we can test by using a different user in dependency override
        from app.models import User, UserType
        import random
        
        random_suffix = ''.join([str(random.randint(0, 9)) for _ in range(7)])
        other_user = User(
            phone_number=f"95{random_suffix}",
            name="Other User",
            user_type=UserType.CLIENT,
            is_active=True
        )
        db_session.add(other_user)
        await db_session.commit()
        
        # Override to use other_user (who doesn't own the review)
        from app.api.deps import get_current_client
        async def override_get_current_client():
            return other_user
        
        test_app.dependency_overrides[get_current_client] = override_get_current_client
        
        try:
            response = await authenticated_client.put(
                f"/api/v1/reviews/{sample_review.id}",
                json={
                    "rating": 4,
                    "comment": "Updated"
                }
            )
            
            assert response.status_code == 403  # Forbidden
        finally:
            # Restore original override
            async def restore_get_current_client():
                return sample_client_user
            test_app.dependency_overrides[get_current_client] = restore_get_current_client
    
    async def test_delete_review_authenticated(
        self,
        test_app,
        db_session,
        sample_review,
        sample_client_user,
        sample_service,
        authenticated_client
    ):
        """Test DELETE /{review_id} (delete review, authenticated)."""
        response = await authenticated_client.delete(
            f"/api/v1/reviews/{sample_review.id}"
        )
        
        assert response.status_code == 204  # No Content
        
        # Verify review is soft deleted
        await db_session.refresh(sample_review)
        assert sample_review.is_active is False
    
    async def test_delete_review_unauthenticated(
        self,
        test_app,
        sample_review,
        unauthenticated_client
    ):
        """Test DELETE /{review_id} without authentication."""
        response = await unauthenticated_client.delete(
            f"/api/v1/reviews/{sample_review.id}"
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_delete_review_not_found(
        self,
        test_app,
        authenticated_client
    ):
        """Test DELETE /{review_id} with non-existent review."""
        response = await authenticated_client.delete(
            f"/api/v1/reviews/{uuid4()}"
        )
        
        assert response.status_code == 404
    
    async def test_delete_review_forbidden(
        self,
        test_app,
        db_session,
        sample_review,
        sample_client_user,
        authenticated_client
    ):
        """Test deleting someone else's review returns 403."""
        from app.models import User, UserType
        import random
        
        random_suffix = ''.join([str(random.randint(0, 9)) for _ in range(7)])
        other_user = User(
            phone_number=f"96{random_suffix}",
            name="Other User",
            user_type=UserType.CLIENT,
            is_active=True
        )
        db_session.add(other_user)
        await db_session.commit()
        
        # Override to use other_user
        from app.api.deps import get_current_client
        async def override_get_current_client():
            return other_user
        
        test_app.dependency_overrides[get_current_client] = override_get_current_client
        
        try:
            response = await authenticated_client.delete(
                f"/api/v1/reviews/{sample_review.id}"
            )
            
            assert response.status_code == 403  # Forbidden
        finally:
            # Restore original override
            async def restore_get_current_client():
                return sample_client_user
            test_app.dependency_overrides[get_current_client] = restore_get_current_client

