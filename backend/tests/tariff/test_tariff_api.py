"""
Tests for Tariff API endpoints.
"""
import pytest
from uuid import uuid4
from httpx import AsyncClient
from fastapi import FastAPI, HTTPException, status, Request
from fastapi.responses import JSONResponse

from app.api.v1.tariffs import router
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
    app.include_router(router, prefix="/api/v1/tariffs", tags=["Tariffs"])
    
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
class TestTariffAPI:
    """Test Tariff API endpoints."""
    
    async def test_get_tariff_plans_public(
        self,
        test_app,
        db_session,
        sample_tariff,
        unauthenticated_client
    ):
        """Test GET / (public endpoint to get all active tariff plans)."""
        response = await unauthenticated_client.get("/api/v1/tariffs/")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1
        assert any(tariff["id"] == str(sample_tariff.id) for tariff in data)
        assert all(tariff["is_active"] for tariff in data)
    
    async def test_get_tariff_admin(
        self,
        test_app,
        db_session,
        sample_tariff,
        authenticated_admin_client
    ):
        """Test GET /{tariff_id} (admin only)."""
        response = await authenticated_admin_client.get(
            f"/api/v1/tariffs/{sample_tariff.id}"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(sample_tariff.id)
        assert data["name"] == sample_tariff.name
        assert data["price_per_month"] == 100000.0
        assert data["max_services"] == 5
        assert "subscription_count" in data
    
    async def test_get_tariff_not_found(
        self,
        test_app,
        authenticated_admin_client
    ):
        """Test GET /{tariff_id} with non-existent tariff."""
        response = await authenticated_admin_client.get(
            f"/api/v1/tariffs/{uuid4()}"
        )
        
        assert response.status_code == 404
        assert "not found" in response.json()["error"]["message"].lower()
    
    async def test_get_tariff_unauthorized(
        self,
        test_app,
        sample_tariff,
        unauthenticated_client
    ):
        """Test GET /{tariff_id} without authentication."""
        response = await unauthenticated_client.get(
            f"/api/v1/tariffs/{sample_tariff.id}"
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_list_tariffs_admin(
        self,
        test_app,
        db_session,
        sample_tariff,
        authenticated_admin_client
    ):
        """Test GET /admin/list (admin only)."""
        response = await authenticated_admin_client.get(
            "/api/v1/tariffs/admin/list"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "tariffs" in data
        assert "total" in data
        assert data["total"] >= 1
        assert any(tariff["id"] == str(sample_tariff.id) for tariff in data["tariffs"])
    
    async def test_list_tariffs_admin_with_pagination(
        self,
        test_app,
        db_session,
        sample_tariff,
        authenticated_admin_client
    ):
        """Test GET /admin/list with pagination."""
        from app.models import TariffPlan
        
        # Create additional tariffs
        for i in range(5):
            tariff = TariffPlan(
                name=f"Tariff_{str(uuid4())[:8]}",
                price_per_month=100000.0 + i * 10000,
                max_services=5 + i,
                max_images_per_service=10,
                max_phone_numbers=2,
                max_gallery_images=20,
                max_social_accounts=3,
                is_active=True
            )
            db_session.add(tariff)
        await db_session.commit()
        
        response = await authenticated_admin_client.get(
            "/api/v1/tariffs/admin/list",
            params={"page": 1, "limit": 2}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 1
        assert data["limit"] == 2
        assert len(data["tariffs"]) == 2
        assert data["total"] >= 6
    
    async def test_list_tariffs_admin_include_inactive(
        self,
        test_app,
        db_session,
        authenticated_admin_client
    ):
        """Test GET /admin/list with include_inactive flag."""
        from app.models import TariffPlan
        
        # Create active and inactive tariffs
        active_tariff = TariffPlan(
            name=f"Active_{str(uuid4())[:8]}",
            price_per_month=100000.0,
            max_services=5,
            max_images_per_service=10,
            max_phone_numbers=2,
            max_gallery_images=20,
            max_social_accounts=3,
            is_active=True
        )
        inactive_tariff = TariffPlan(
            name=f"Inactive_{str(uuid4())[:8]}",
            price_per_month=50000.0,
            max_services=3,
            max_images_per_service=5,
            max_phone_numbers=1,
            max_gallery_images=10,
            max_social_accounts=2,
            is_active=False
        )
        db_session.add(active_tariff)
        db_session.add(inactive_tariff)
        await db_session.commit()
        
        # List without inactive
        response = await authenticated_admin_client.get(
            "/api/v1/tariffs/admin/list",
            params={"include_inactive": False}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert all(tariff["is_active"] for tariff in data["tariffs"])
        
        # List with inactive
        response2 = await authenticated_admin_client.get(
            "/api/v1/tariffs/admin/list",
            params={"include_inactive": True}
        )
        
        assert response2.status_code == 200
        data2 = response2.json()
        assert any(not tariff["is_active"] for tariff in data2["tariffs"])
    
    async def test_list_tariffs_admin_unauthorized(
        self,
        test_app,
        unauthenticated_client
    ):
        """Test GET /admin/list without authentication."""
        response = await unauthenticated_client.get(
            "/api/v1/tariffs/admin/list"
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_list_tariffs_admin_forbidden_non_admin(
        self,
        test_app,
        non_admin_client
    ):
        """Test GET /admin/list with non-admin user."""
        response = await non_admin_client.get(
            "/api/v1/tariffs/admin/list"
        )
        
        assert response.status_code == 403  # Forbidden
        assert "admin" in response.json()["error"]["message"].lower()
    
    async def test_create_tariff_admin(
        self,
        test_app,
        db_session,
        authenticated_admin_client
    ):
        """Test POST / (create tariff, admin only)."""
        response = await authenticated_admin_client.post(
            "/api/v1/tariffs/",
            json={
                "name": f"NewTariff_{str(uuid4())[:8]}",
                "price_per_month": 125000.0,
                "max_services": 6,
                "max_images_per_service": 12,
                "max_phone_numbers": 2,
                "max_gallery_images": 25,
                "max_social_accounts": 3,
                "allow_website": True,
                "allow_cover_image": True,
                "monthly_featured_cards": 2,
                "is_active": True
            }
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["name"].startswith("NewTariff_")
        assert data["price_per_month"] == 125000.0
        assert data["max_services"] == 6
        assert data["allow_website"] is True
        assert data["is_active"] is True
        assert data["subscription_count"] == 0
    
    async def test_create_tariff_unauthorized(
        self,
        test_app,
        unauthenticated_client
    ):
        """Test POST / without authentication."""
        response = await unauthenticated_client.post(
            "/api/v1/tariffs/",
            json={
                "name": "Test Tariff",
                "price_per_month": 100000.0,
                "max_services": 5,
                "max_images_per_service": 10,
                "max_phone_numbers": 2,
                "max_gallery_images": 20,
                "max_social_accounts": 3
            }
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_create_tariff_forbidden_non_admin(
        self,
        test_app,
        non_admin_client
    ):
        """Test POST / with non-admin user."""
        response = await non_admin_client.post(
            "/api/v1/tariffs/",
            json={
                "name": "Test Tariff",
                "price_per_month": 100000.0,
                "max_services": 5,
                "max_images_per_service": 10,
                "max_phone_numbers": 2,
                "max_gallery_images": 20,
                "max_social_accounts": 3
            }
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_create_tariff_duplicate_name(
        self,
        test_app,
        db_session,
        sample_tariff,
        authenticated_admin_client
    ):
        """Test creating tariff with duplicate name returns 409 Conflict."""
        response = await authenticated_admin_client.post(
            "/api/v1/tariffs/",
            json={
                "name": sample_tariff.name,
                "price_per_month": 100000.0,
                "max_services": 5,
                "max_images_per_service": 10,
                "max_phone_numbers": 2,
                "max_gallery_images": 20,
                "max_social_accounts": 3
            }
        )
        
        assert response.status_code == 409  # Conflict
        assert "already exists" in response.json()["error"]["message"].lower()
    
    async def test_update_tariff_admin(
        self,
        test_app,
        db_session,
        sample_tariff,
        authenticated_admin_client
    ):
        """Test PUT /{tariff_id} (update tariff, admin only)."""
        response = await authenticated_admin_client.put(
            f"/api/v1/tariffs/{sample_tariff.id}",
            json={
                "name": f"UpdatedTariff_{str(uuid4())[:8]}",
                "price_per_month": 150000.0,
                "max_services": 8,
                "allow_website": True,
                "monthly_featured_cards": 3,
                "is_active": False
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(sample_tariff.id)
        assert data["name"].startswith("UpdatedTariff_")
        assert data["price_per_month"] == 150000.0
        assert data["max_services"] == 8
        assert data["allow_website"] is True
        assert data["monthly_featured_cards"] == 3
        assert data["is_active"] is False
    
    async def test_update_tariff_partial(
        self,
        test_app,
        db_session,
        sample_tariff,
        authenticated_admin_client
    ):
        """Test PUT /{tariff_id} with partial update."""
        original_name = sample_tariff.name
        
        # Update only price
        response = await authenticated_admin_client.put(
            f"/api/v1/tariffs/{sample_tariff.id}",
            json={
                "price_per_month": 150000.0
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == original_name  # Unchanged
        assert data["price_per_month"] == 150000.0
    
    async def test_update_tariff_not_found(
        self,
        test_app,
        authenticated_admin_client
    ):
        """Test PUT /{tariff_id} with non-existent tariff."""
        response = await authenticated_admin_client.put(
            f"/api/v1/tariffs/{uuid4()}",
            json={
                "name": "Updated Name",
                "price_per_month": 150000.0
            }
        )
        
        assert response.status_code == 404
        assert "not found" in response.json()["error"]["message"].lower()
    
    async def test_update_tariff_unauthorized(
        self,
        test_app,
        sample_tariff,
        unauthenticated_client
    ):
        """Test PUT /{tariff_id} without authentication."""
        response = await unauthenticated_client.put(
            f"/api/v1/tariffs/{sample_tariff.id}",
            json={
                "name": "Updated Name"
            }
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_update_tariff_forbidden_non_admin(
        self,
        test_app,
        sample_tariff,
        non_admin_client
    ):
        """Test PUT /{tariff_id} with non-admin user."""
        response = await non_admin_client.put(
            f"/api/v1/tariffs/{sample_tariff.id}",
            json={
                "name": "Updated Name"
            }
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_update_tariff_name_conflict(
        self,
        test_app,
        db_session,
        sample_tariff,
        authenticated_admin_client
    ):
        """Test updating tariff with conflicting name returns 409."""
        from app.models import TariffPlan
        
        # Create another tariff
        tariff2 = TariffPlan(
            name=f"Tariff2_{str(uuid4())[:8]}",
            price_per_month=200000.0,
            max_services=10,
            max_images_per_service=20,
            max_phone_numbers=3,
            max_gallery_images=50,
            max_social_accounts=5,
            is_active=True
        )
        db_session.add(tariff2)
        await db_session.commit()
        
        # Try to update sample_tariff with tariff2's name
        response = await authenticated_admin_client.put(
            f"/api/v1/tariffs/{sample_tariff.id}",
            json={
                "name": tariff2.name
            }
        )
        
        assert response.status_code == 409  # Conflict
        assert "already exists" in response.json()["error"]["message"].lower()
    
    async def test_delete_tariff_admin(
        self,
        test_app,
        db_session,
        authenticated_admin_client
    ):
        """Test DELETE /{tariff_id} (delete tariff, admin only)."""
        from app.models import TariffPlan
        
        # Create a tariff without subscriptions
        tariff = TariffPlan(
            name=f"TariffToDelete_{str(uuid4())[:8]}",
            price_per_month=50000.0,
            max_services=3,
            max_images_per_service=5,
            max_phone_numbers=1,
            max_gallery_images=10,
            max_social_accounts=2,
            is_active=True
        )
        db_session.add(tariff)
        await db_session.commit()
        tariff_id = tariff.id
        
        # Delete the tariff
        response = await authenticated_admin_client.delete(
            f"/api/v1/tariffs/{tariff_id}"
        )
        
        assert response.status_code == 204  # No Content
        
        # Verify it's deleted
        get_response = await authenticated_admin_client.get(
            f"/api/v1/tariffs/{tariff_id}"
        )
        assert get_response.status_code == 404
    
    async def test_delete_tariff_with_subscriptions(
        self,
        test_app,
        db_session,
        sample_tariff,
        sample_merchant,
        authenticated_admin_client
    ):
        """Test DELETE /{tariff_id} with active subscriptions (soft delete)."""
        from app.models.merchant_subscription_model import MerchantSubscription
        from datetime import date, timedelta
        
        # Create an active subscription
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status="ACTIVE"
        )
        db_session.add(subscription)
        await db_session.commit()
        
        # Delete the tariff (should soft delete)
        response = await authenticated_admin_client.delete(
            f"/api/v1/tariffs/{sample_tariff.id}"
        )
        
        assert response.status_code == 204  # No Content
        
        # Verify tariff still exists but is inactive
        get_response = await authenticated_admin_client.get(
            f"/api/v1/tariffs/{sample_tariff.id}"
        )
        if get_response.status_code == 200:
            data = get_response.json()
            assert data["is_active"] is False
    
    async def test_delete_tariff_not_found(
        self,
        test_app,
        authenticated_admin_client
    ):
        """Test DELETE /{tariff_id} with non-existent tariff."""
        response = await authenticated_admin_client.delete(
            f"/api/v1/tariffs/{uuid4()}"
        )
        
        assert response.status_code == 404
        assert "not found" in response.json()["error"]["message"].lower()
    
    async def test_delete_tariff_unauthorized(
        self,
        test_app,
        sample_tariff,
        unauthenticated_client
    ):
        """Test DELETE /{tariff_id} without authentication."""
        response = await unauthenticated_client.delete(
            f"/api/v1/tariffs/{sample_tariff.id}"
        )
        
        assert response.status_code == 403  # Forbidden
    
    async def test_delete_tariff_forbidden_non_admin(
        self,
        test_app,
        sample_tariff,
        non_admin_client
    ):
        """Test DELETE /{tariff_id} with non-admin user."""
        response = await non_admin_client.delete(
            f"/api/v1/tariffs/{sample_tariff.id}"
        )
        
        assert response.status_code == 403  # Forbidden

