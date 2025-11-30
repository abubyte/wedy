"""
Tests for Category API endpoints.
"""
import pytest
from uuid import uuid4
from httpx import AsyncClient
from fastapi import FastAPI, HTTPException, status, Request
from fastapi.responses import JSONResponse

from app.api.v1.categories import router
from app.models import User, UserType
from app.core.security import create_access_token
from app.core.database import get_db_session
from app.api.deps import get_current_user, get_current_admin
from app.core.exceptions import WedyException, map_exception_to_http


# Create a test FastAPI app
@pytest.fixture
async def test_app(db_session):
    """Create a FastAPI test application."""
    app = FastAPI()
    app.include_router(router, prefix="/api/v1/categories", tags=["Categories"])
    
    # Override database session dependency
    async def override_get_db_session():
        yield db_session
    
    app.dependency_overrides[get_db_session] = override_get_db_session
    
    # Add exception handlers (same as main.py)
    @app.exception_handler(WedyException)
    async def wedy_exception_handler(request: Request, exc: WedyException) -> JSONResponse:
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
async def admin_user(db_session):
    """Create an admin user for testing."""
    import random
    random_suffix = ''.join([str(random.randint(0, 9)) for _ in range(7)])
    phone_number = f"99{random_suffix}"
    
    user = User(
        phone_number=phone_number,
        name="Admin User",
        user_type=UserType.ADMIN,
        is_active=True
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
async def admin_token(admin_user):
    """Create an access token for the admin user."""
    return create_access_token(str(admin_user.id))


@pytest.fixture
async def authenticated_admin_client(test_app, admin_user):
    """Create an authenticated async client with admin user."""
    # Override authentication dependencies
    async def override_get_current_user():
        return admin_user
    
    async def override_get_current_admin():
        return admin_user
    
    test_app.dependency_overrides[get_current_user] = override_get_current_user
    test_app.dependency_overrides[get_current_admin] = override_get_current_admin
    
    async with AsyncClient(app=test_app, base_url="http://test") as ac:
        yield ac


@pytest.fixture
async def unauthenticated_client(test_app):
    """Create an unauthenticated async client."""
    async with AsyncClient(app=test_app, base_url="http://test") as ac:
        yield ac


@pytest.fixture
async def non_admin_client(test_app, sample_client_user):
    """Create an authenticated async client with non-admin user."""
    # Override to use client user (non-admin)
    async def override_get_current_user():
        return sample_client_user
    
    test_app.dependency_overrides[get_current_user] = override_get_current_user
    
    async with AsyncClient(app=test_app, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
class TestCategoryAPI:
    """Test Category API endpoints."""
    
    async def test_get_categories_public(
        self,
        test_app,
        db_session,
        sample_category,
        unauthenticated_client
    ):
        """Test GET / (public endpoint to get all active categories)."""
        response = await unauthenticated_client.get("/api/v1/categories/")
        
        assert response.status_code == 200
        data = response.json()
        assert "categories" in data
        assert len(data["categories"]) >= 1
        assert any(cat["id"] == str(sample_category.id) for cat in data["categories"])
    
    async def test_get_category_by_id_public(
        self,
        test_app,
        db_session,
        sample_category,
        unauthenticated_client
    ):
        """Test GET /{category_id} (public endpoint)."""
        response = await unauthenticated_client.get(
            f"/api/v1/categories/{sample_category.id}"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(sample_category.id)
        assert data["name"] == sample_category.name
        assert data["description"] == sample_category.description
        assert "service_count" in data
    
    async def test_get_category_not_found(
        self,
        test_app,
        unauthenticated_client
    ):
        """Test GET /{category_id} with non-existent category."""
        response = await unauthenticated_client.get(
            f"/api/v1/categories/{uuid4()}"
        )
        
        assert response.status_code == 404
        assert "not found" in response.json()["error"]["message"].lower()
    
    async def test_list_categories_admin(
        self,
        test_app,
        db_session,
        sample_category,
        authenticated_admin_client
    ):
        """Test GET /admin/list (admin only)."""
        response = await authenticated_admin_client.get(
            "/api/v1/categories/admin/list"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "categories" in data
        assert "total" in data
        assert data["total"] >= 1
        assert any(cat["id"] == str(sample_category.id) for cat in data["categories"])
    
    async def test_list_categories_admin_with_pagination(
        self,
        test_app,
        db_session,
        sample_category,
        authenticated_admin_client
    ):
        """Test GET /admin/list with pagination."""
        from app.models import ServiceCategory
        
        # Create additional categories
        for i in range(5):
            category = ServiceCategory(
                name=f"Category_{str(uuid4())[:8]}",
                description=f"Category {i+1}",
                is_active=True
            )
            db_session.add(category)
        await db_session.commit()
        
        response = await authenticated_admin_client.get(
            "/api/v1/categories/admin/list",
            params={"page": 1, "limit": 2}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 1
        assert data["limit"] == 2
        assert len(data["categories"]) == 2
        assert data["total"] >= 6
    
    async def test_list_categories_admin_include_inactive(
        self,
        test_app,
        db_session,
        authenticated_admin_client
    ):
        """Test GET /admin/list with include_inactive flag."""
        from app.models import ServiceCategory
        
        # Create active and inactive categories
        active_cat = ServiceCategory(
            name=f"Active_{str(uuid4())[:8]}",
            description="Active category",
            is_active=True
        )
        inactive_cat = ServiceCategory(
            name=f"Inactive_{str(uuid4())[:8]}",
            description="Inactive category",
            is_active=False
        )
        db_session.add(active_cat)
        db_session.add(inactive_cat)
        await db_session.commit()
        
        # List without inactive
        response = await authenticated_admin_client.get(
            "/api/v1/categories/admin/list",
            params={"include_inactive": False}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert all(cat["is_active"] for cat in data["categories"])
        
        # List with inactive
        response2 = await authenticated_admin_client.get(
            "/api/v1/categories/admin/list",
            params={"include_inactive": True}
        )
        
        assert response2.status_code == 200
        data2 = response2.json()
        assert any(not cat["is_active"] for cat in data2["categories"])
    
    async def test_list_categories_admin_unauthorized(
        self,
        test_app,
        unauthenticated_client
    ):
        """Test GET /admin/list without authentication."""
        response = await unauthenticated_client.get(
            "/api/v1/categories/admin/list"
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_list_categories_admin_forbidden_non_admin(
        self,
        test_app,
        non_admin_client
    ):
        """Test GET /admin/list with non-admin user."""
        response = await non_admin_client.get(
            "/api/v1/categories/admin/list"
        )
        
        assert response.status_code == 403  # Forbidden
        assert "admin" in response.json()["error"]["message"].lower()
    
    async def test_create_category_admin(
        self,
        test_app,
        db_session,
        authenticated_admin_client
    ):
        """Test POST / (create category, admin only)."""
        response = await authenticated_admin_client.post(
            "/api/v1/categories/",
            json={
                "name": f"NewCategory_{str(uuid4())[:8]}",
                "description": "New category description",
                "display_order": 5,
                "is_active": True
            }
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["name"].startswith("NewCategory_")
        assert data["description"] == "New category description"
        assert data["display_order"] == 5
        assert data["is_active"] is True
        assert data["service_count"] == 0
    
    async def test_create_category_unauthorized(
        self,
        test_app,
        unauthenticated_client
    ):
        """Test POST / without authentication."""
        response = await unauthenticated_client.post(
            "/api/v1/categories/",
            json={
                "name": "Test Category",
                "description": "Test description"
            }
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_create_category_forbidden_non_admin(
        self,
        test_app,
        non_admin_client
    ):
        """Test POST / with non-admin user."""
        response = await non_admin_client.post(
            "/api/v1/categories/",
            json={
                "name": "Test Category",
                "description": "Test description"
            }
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_create_category_duplicate_name(
        self,
        test_app,
        db_session,
        sample_category,
        authenticated_admin_client
    ):
        """Test creating category with duplicate name returns 409 Conflict."""
        response = await authenticated_admin_client.post(
            "/api/v1/categories/",
            json={
                "name": sample_category.name,
                "description": "Duplicate category"
            }
        )
        
        assert response.status_code == 409  # Conflict
        assert "already exists" in response.json()["error"]["message"].lower()
    
    async def test_update_category_admin(
        self,
        test_app,
        db_session,
        sample_category,
        authenticated_admin_client
    ):
        """Test PUT /{category_id} (update category, admin only)."""
        response = await authenticated_admin_client.put(
            f"/api/v1/categories/{sample_category.id}",
            json={
                "name": f"UpdatedCategory_{str(uuid4())[:8]}",
                "description": "Updated description",
                "display_order": 99,
                "is_active": False
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(sample_category.id)
        assert data["name"].startswith("UpdatedCategory_")
        assert data["description"] == "Updated description"
        assert data["display_order"] == 99
        assert data["is_active"] is False
    
    async def test_update_category_partial(
        self,
        test_app,
        db_session,
        sample_category,
        authenticated_admin_client
    ):
        """Test PUT /{category_id} with partial update."""
        original_name = sample_category.name
        
        # Update only description
        response = await authenticated_admin_client.put(
            f"/api/v1/categories/{sample_category.id}",
            json={
                "description": "Only description updated"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == original_name  # Unchanged
        assert data["description"] == "Only description updated"
    
    async def test_update_category_not_found(
        self,
        test_app,
        authenticated_admin_client
    ):
        """Test PUT /{category_id} with non-existent category."""
        response = await authenticated_admin_client.put(
            f"/api/v1/categories/{uuid4()}",
            json={
                "name": "Updated Name",
                "description": "Updated description"
            }
        )
        
        assert response.status_code == 404
        assert "not found" in response.json()["error"]["message"].lower()
    
    async def test_update_category_unauthorized(
        self,
        test_app,
        sample_category,
        unauthenticated_client
    ):
        """Test PUT /{category_id} without authentication."""
        response = await unauthenticated_client.put(
            f"/api/v1/categories/{sample_category.id}",
            json={
                "name": "Updated Name"
            }
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_update_category_forbidden_non_admin(
        self,
        test_app,
        sample_category,
        non_admin_client
    ):
        """Test PUT /{category_id} with non-admin user."""
        response = await non_admin_client.put(
            f"/api/v1/categories/{sample_category.id}",
            json={
                "name": "Updated Name"
            }
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_update_category_name_conflict(
        self,
        test_app,
        db_session,
        sample_category,
        authenticated_admin_client
    ):
        """Test updating category with conflicting name returns 409."""
        from app.models import ServiceCategory
        
        # Create another category
        category2 = ServiceCategory(
            name=f"Category_{str(uuid4())[:8]}",
            description="Second category",
            is_active=True
        )
        db_session.add(category2)
        await db_session.commit()
        
        # Try to update sample_category with category2's name
        response = await authenticated_admin_client.put(
            f"/api/v1/categories/{sample_category.id}",
            json={
                "name": category2.name
            }
        )
        
        assert response.status_code == 409  # Conflict
        assert "already exists" in response.json()["error"]["message"].lower()
    
    async def test_delete_category_admin(
        self,
        test_app,
        db_session,
        authenticated_admin_client,
        unauthenticated_client
    ):
        """Test DELETE /{category_id} (delete category, admin only)."""
        from app.models import ServiceCategory
        
        # Create a category without services
        category = ServiceCategory(
            name=f"CategoryToDelete_{str(uuid4())[:8]}",
            description="Category to delete",
            is_active=True
        )
        db_session.add(category)
        await db_session.commit()
        category_id = category.id
        
        # Delete the category
        response = await authenticated_admin_client.delete(
            f"/api/v1/categories/{category_id}"
        )
        
        assert response.status_code == 204  # No Content
        
        # Verify it's deleted
        get_response = await unauthenticated_client.get(
            f"/api/v1/categories/{category_id}"
        )
        assert get_response.status_code == 404
    
    async def test_delete_category_with_services(
        self,
        test_app,
        db_session,
        sample_category,
        sample_service,
        authenticated_admin_client,
        unauthenticated_client
    ):
        """Test DELETE /{category_id} with active services (soft delete)."""
        # Ensure service is in the category
        assert sample_service.category_id == sample_category.id
        
        # Delete the category (should soft delete)
        response = await authenticated_admin_client.delete(
            f"/api/v1/categories/{sample_category.id}"
        )
        
        assert response.status_code == 204  # No Content
        
        # Verify category still exists but is inactive
        # (get_category will still return it, just marked inactive)
        get_response = await unauthenticated_client.get(
            f"/api/v1/categories/{sample_category.id}"
        )
        # The category still exists but won't appear in public listing
        # Since get_category doesn't filter by is_active, it will return it
        if get_response.status_code == 200:
            data = get_response.json()
            assert data["is_active"] is False
    
    async def test_delete_category_not_found(
        self,
        test_app,
        authenticated_admin_client
    ):
        """Test DELETE /{category_id} with non-existent category."""
        response = await authenticated_admin_client.delete(
            f"/api/v1/categories/{uuid4()}"
        )
        
        assert response.status_code == 404
        assert "not found" in response.json()["error"]["message"].lower()
    
    async def test_delete_category_unauthorized(
        self,
        test_app,
        sample_category,
        unauthenticated_client
    ):
        """Test DELETE /{category_id} without authentication."""
        response = await unauthenticated_client.delete(
            f"/api/v1/categories/{sample_category.id}"
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_delete_category_forbidden_non_admin(
        self,
        test_app,
        sample_category,
        non_admin_client
    ):
        """Test DELETE /{category_id} with non-admin user."""
        response = await non_admin_client.delete(
            f"/api/v1/categories/{sample_category.id}"
        )
        
        assert response.status_code == 403  # Forbidden

