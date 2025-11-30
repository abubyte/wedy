"""
Tests for Merchant API endpoints.
"""
import os

# Set required environment variables before importing any app modules
os.environ.setdefault("ESKIZ_EMAIL", "test@example.com")
os.environ.setdefault("ESKIZ_PASSWORD", "test_password")
os.environ.setdefault("AWS_ACCESS_KEY_ID", "test_key")
os.environ.setdefault("AWS_SECRET_ACCESS_KEY", "test_secret")
os.environ.setdefault("AWS_BUCKET_NAME", "test_bucket")
os.environ.setdefault("PAYME_SECRET_KEY", "test_payme_secret")
os.environ.setdefault("PAYME_MERCHANT_ID", "test_merchant_id")

import pytest
from uuid import uuid4
from httpx import AsyncClient
from datetime import date, timedelta

from app.models import User


# Create a test FastAPI app
@pytest.fixture
async def test_app(db_session):
    """Create a FastAPI test application."""
    from fastapi.responses import JSONResponse
    from app.core.exceptions import WedyException, NotFoundError, ConflictError, ValidationError, ForbiddenError, PaymentRequiredError
    from fastapi import HTTPException, status, Request
    from fastapi import FastAPI
    
    app = FastAPI()
    
    # Include all merchant routers
    from app.api.v1 import merchants, merchants_contacts, merchants_gallery, merchants_cover_image
    app.include_router(merchants.router, prefix="/api/v1/merchants", tags=["Merchants"])
    app.include_router(merchants_contacts.router, prefix="/api/v1/merchants", tags=["Merchants Contacts"])
    app.include_router(merchants_gallery.router, prefix="/api/v1/merchants", tags=["Merchants Gallery"])
    app.include_router(merchants_cover_image.router, prefix="/api/v1/merchants", tags=["Merchants Cover Image"])
    
    # Override database session dependency
    from app.core.database import get_db_session
    async def override_get_db_session():
        yield db_session
    
    app.dependency_overrides[get_db_session] = override_get_db_session
    
    # Mock payment providers dependency
    from app.services.payment_providers import get_payment_providers
    async def override_get_payment_providers():
        # Return empty dict - no payment providers needed for these tests
        return {}
    
    app.dependency_overrides[get_payment_providers] = override_get_payment_providers
    
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
async def authenticated_merchant_client(test_app, sample_merchant_user, sample_merchant, db_session):
    """Create an authenticated async client with merchant user."""
    from app.api.deps import get_current_user, get_current_merchant_user, get_current_merchant, get_current_active_merchant
    
    async def override_get_current_user():
        return sample_merchant_user
    
    async def override_get_current_merchant_user():
        return sample_merchant_user
    
    async def override_get_current_merchant():
        return sample_merchant
    
    async def override_get_current_active_merchant():
        # get_current_active_merchant requires get_current_merchant
        # We'll override it to return the merchant directly
        # Note: The actual dependency checks for active subscription, but we'll bypass that in tests
        # by ensuring subscriptions are created in tests that need them
        return sample_merchant
    
    test_app.dependency_overrides[get_current_user] = override_get_current_user
    test_app.dependency_overrides[get_current_merchant_user] = override_get_current_merchant_user
    test_app.dependency_overrides[get_current_merchant] = override_get_current_merchant
    test_app.dependency_overrides[get_current_active_merchant] = override_get_current_active_merchant
    
    async with AsyncClient(app=test_app, base_url="http://test") as ac:
        yield ac


@pytest.fixture
async def unauthenticated_client(test_app):
    """Create an unauthenticated async client."""
    async with AsyncClient(app=test_app, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
class TestMerchantAPI:
    """Test Merchant API endpoints."""
    
    async def test_get_merchant_profile(
        self,
        test_app,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        authenticated_merchant_client
    ):
        """Test GET /profile (get merchant profile)."""
        response = await authenticated_merchant_client.get("/api/v1/merchants/profile")
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(sample_merchant.id)
        assert data["business_name"] == sample_merchant.business_name
        assert data["name"] == sample_merchant_user.name
    
    async def test_get_merchant_profile_unauthenticated(
        self,
        test_app,
        unauthenticated_client
    ):
        """Test GET /profile without authentication."""
        response = await unauthenticated_client.get("/api/v1/merchants/profile")
        
        assert response.status_code == 403  # Forbidden
    
    async def test_update_merchant_profile(
        self,
        test_app,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_tariff: "TariffPlan",
        authenticated_merchant_client,
        db_session
    ):
        """Test PUT /profile (update merchant profile)."""
        # Create active subscription
        from app.models import MerchantSubscription, SubscriptionStatus
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        response = await authenticated_merchant_client.put(
            "/api/v1/merchants/profile",
            json={
                "business_name": "Updated Business Name",
                "description": "Updated description",
                "location_region": "Samarkand"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["business_name"] == "Updated Business Name"
        assert data["description"] == "Updated description"
        assert data["location_region"] == "Samarkand"
    
    async def test_get_merchant_subscription(
        self,
        test_app,
        sample_merchant: "Merchant",
        sample_merchant_user: "User",
        sample_tariff: "TariffPlan",
        authenticated_merchant_client,
        db_session
    ):
        """Test GET /subscription (get merchant subscription)."""
        # Create active subscription
        from app.models import MerchantSubscription, SubscriptionStatus
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        response = await authenticated_merchant_client.get("/api/v1/merchants/subscription")
        
        assert response.status_code == 200
        data = response.json()
        assert data["subscription"] is not None
        assert data["limits"] is not None
        assert "services" in data["limits"]
        assert "gallery_images" in data["limits"]
    
    async def test_get_merchant_subscription_no_subscription(
        self,
        test_app,
        authenticated_merchant_client
    ):
        """Test GET /subscription when no subscription exists."""
        response = await authenticated_merchant_client.get("/api/v1/merchants/subscription")
        
        assert response.status_code == 200
        data = response.json()
        assert data["subscription"] is None
        assert "No active subscription" in data.get("message", "")
    
    async def test_get_merchant_analytics(
        self,
        test_app,
        authenticated_merchant_client
    ):
        """Test GET /analytics/services (get merchant analytics)."""
        response = await authenticated_merchant_client.get("/api/v1/merchants/analytics/services")
        
        assert response.status_code == 200
        data = response.json()
        assert "services" in data
        assert "total_services" in data
        assert "total_views" in data
    
    async def test_get_featured_services_tracking(
        self,
        test_app,
        authenticated_merchant_client
    ):
        """Test GET /featured-services (get featured services tracking)."""
        response = await authenticated_merchant_client.get("/api/v1/merchants/featured-services")
        
        assert response.status_code == 200
        data = response.json()
        assert "featured_services" in data
        assert "total" in data
        assert "active_count" in data
    
    async def test_get_merchant_contacts(
        self,
        test_app,
        sample_merchant: "Merchant",
        authenticated_merchant_client,
        db_session
    ):
        """Test GET /contacts (get merchant contacts)."""
        # Create a contact
        from app.models import MerchantContact, ContactType
        contact = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998901234567",
            is_active=True
        )
        db_session.add(contact)
        await db_session.commit()
        
        response = await authenticated_merchant_client.get("/api/v1/merchants/contacts")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1
        assert data[0]["contact_value"] == "+998901234567"
    
    async def test_add_merchant_contact(
        self,
        test_app,
        sample_merchant: "Merchant",
        sample_tariff: "TariffPlan",
        authenticated_merchant_client,
        db_session
    ):
        """Test POST /contacts (add merchant contact)."""
        # Create active subscription
        from app.models import MerchantSubscription, SubscriptionStatus
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        response = await authenticated_merchant_client.post(
            "/api/v1/merchants/contacts",
            json={
                "contact_type": "phone",
                "contact_value": "+998901234567",
                "display_order": 1
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["contact_value"] == "+998901234567"
        assert data["contact_type"] == "phone"
    
    async def test_update_merchant_contact(
        self,
        test_app,
        sample_merchant: "Merchant",
        authenticated_merchant_client,
        db_session
    ):
        """Test PUT /contacts/{contact_id} (update merchant contact)."""
        # Create a contact
        from app.models import MerchantContact, ContactType
        contact = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998901234567",
            is_active=True
        )
        db_session.add(contact)
        await db_session.commit()
        await db_session.refresh(contact)
        
        response = await authenticated_merchant_client.put(
            f"/api/v1/merchants/contacts/{contact.id}",
            json={
                "contact_value": "+998907654321"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["contact_value"] == "+998907654321"
    
    async def test_delete_merchant_contact(
        self,
        test_app,
        sample_merchant: "Merchant",
        authenticated_merchant_client,
        db_session
    ):
        """Test DELETE /contacts/{contact_id} (delete merchant contact)."""
        # Create a contact
        from app.models import MerchantContact, ContactType
        contact = MerchantContact(
            merchant_id=sample_merchant.id,
            contact_type=ContactType.PHONE,
            contact_value="+998901234567",
            is_active=True
        )
        db_session.add(contact)
        await db_session.commit()
        await db_session.refresh(contact)
        
        response = await authenticated_merchant_client.delete(
            f"/api/v1/merchants/contacts/{contact.id}"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        
        # Verify contact is soft deleted
        response2 = await authenticated_merchant_client.get("/api/v1/merchants/contacts")
        contact_ids = [c["id"] for c in response2.json()]
        assert str(contact.id) not in contact_ids
    
    async def test_get_gallery_images(
        self,
        test_app,
        sample_merchant: "Merchant",
        authenticated_merchant_client,
        db_session
    ):
        """Test GET /gallery (get gallery images)."""
        # Create gallery image
        from app.models import Image, ImageType
        image = Image(
            related_id=sample_merchant.id,
            image_type=ImageType.MERCHANT_GALLERY,
            s3_url="https://example.com/gallery.jpg",
            file_name="gallery.jpg",
            display_order=1,
            is_active=True
        )
        db_session.add(image)
        await db_session.commit()
        
        response = await authenticated_merchant_client.get("/api/v1/merchants/gallery")
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1
        assert data[0]["s3_url"] == "https://example.com/gallery.jpg"
    
    async def test_add_gallery_image(
        self,
        test_app,
        sample_merchant: "Merchant",
        sample_tariff: "TariffPlan",
        authenticated_merchant_client,
        db_session
    ):
        """Test POST /gallery (add gallery image)."""
        # Create active subscription
        from app.models import MerchantSubscription, SubscriptionStatus
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        response = await authenticated_merchant_client.post(
            "/api/v1/merchants/gallery",
            data={
                "file_name": "gallery.jpg",
                "content_type": "image/jpeg",
                "display_order": 1
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "s3_url" in data
        assert "presigned_url" in data
    
    async def test_delete_gallery_image(
        self,
        test_app,
        sample_merchant: "Merchant",
        authenticated_merchant_client,
        db_session
    ):
        """Test DELETE /gallery/{image_id} (delete gallery image)."""
        # Create gallery image
        from app.models import Image, ImageType
        image = Image(
            related_id=sample_merchant.id,
            image_type=ImageType.MERCHANT_GALLERY,
            s3_url="https://example.com/gallery.jpg",
            file_name="gallery.jpg",
            is_active=True
        )
        db_session.add(image)
        await db_session.commit()
        await db_session.refresh(image)
        
        response = await authenticated_merchant_client.delete(
            f"/api/v1/merchants/gallery/{image.id}"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "successfully" in data.get("message", "").lower()
    
    async def test_add_cover_image(
        self,
        test_app,
        sample_merchant: "Merchant",
        sample_tariff: "TariffPlan",
        authenticated_merchant_client,
        db_session
    ):
        """Test POST /cover-image (add cover image)."""
        # Create subscription with cover image allowed
        sample_tariff.allow_cover_image = True
        db_session.add(sample_tariff)
        
        from app.models import MerchantSubscription, SubscriptionStatus
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        response = await authenticated_merchant_client.post(
            "/api/v1/merchants/cover-image",
            data={
                "file_name": "cover.jpg",
                "content_type": "image/jpeg"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "s3_url" in data
    
    async def test_add_cover_image_not_allowed(
        self,
        test_app,
        sample_merchant: "Merchant",
        sample_tariff: "TariffPlan",
        authenticated_merchant_client,
        db_session
    ):
        """Test POST /cover-image when not allowed in tariff."""
        # Create subscription without cover image permission
        sample_tariff.allow_cover_image = False
        db_session.add(sample_tariff)
        
        from app.models import MerchantSubscription, SubscriptionStatus
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        response = await authenticated_merchant_client.post(
            "/api/v1/merchants/cover-image",
            data={
                "file_name": "cover.jpg",
                "content_type": "image/jpeg"
            }
        )
        
        assert response.status_code == 403
        error_data = response.json()
        assert "error" in error_data
    
    async def test_update_cover_image(
        self,
        test_app,
        sample_merchant: "Merchant",
        sample_tariff: "TariffPlan",
        authenticated_merchant_client,
        db_session
    ):
        """Test PUT /cover-image (update cover image)."""
        # Create subscription with cover image allowed
        sample_tariff.allow_cover_image = True
        db_session.add(sample_tariff)
        
        from app.models import MerchantSubscription, SubscriptionStatus
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        response = await authenticated_merchant_client.put(
            "/api/v1/merchants/cover-image",
            data={
                "file_name": "new-cover.jpg",
                "content_type": "image/jpeg"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "s3_url" in data
    
    async def test_delete_cover_image(
        self,
        test_app,
        sample_merchant: "Merchant",
        authenticated_merchant_client,
        db_session
    ):
        """Test DELETE /cover-image (delete cover image)."""
        # Set cover image first
        sample_merchant.cover_image_url = "https://example.com/cover.jpg"
        db_session.add(sample_merchant)
        await db_session.commit()
        
        response = await authenticated_merchant_client.delete("/api/v1/merchants/cover-image")
        
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
    
    async def test_create_monthly_featured_service(
        self,
        test_app,
        sample_merchant: "Merchant",
        sample_service: "Service",
        sample_tariff: "TariffPlan",
        authenticated_merchant_client,
        db_session
    ):
        """Test POST /featured-services/monthly (create monthly featured service)."""
        # Create subscription with monthly allocations
        sample_tariff.monthly_featured_cards = 5
        db_session.add(sample_tariff)
        
        from app.models import MerchantSubscription, SubscriptionStatus
        now = date.today()
        subscription = MerchantSubscription(
            merchant_id=sample_merchant.id,
            tariff_plan_id=sample_tariff.id,
            start_date=now,
            end_date=now + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        db_session.add(subscription)
        await db_session.commit()
        
        response = await authenticated_merchant_client.post(
            "/api/v1/merchants/featured-services/monthly",
            data={
                "service_id": str(sample_service.id)
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["service_id"] == str(sample_service.id)
        assert data["feature_type"] == "monthly_allocation"
    
    async def test_create_monthly_featured_service_unauthenticated(
        self,
        test_app,
        sample_service: "Service",
        unauthenticated_client
    ):
        """Test POST /featured-services/monthly without authentication."""
        response = await unauthenticated_client.post(
            "/api/v1/merchants/featured-services/monthly",
            data={
                "service_id": str(sample_service.id)
            }
        )
        
        assert response.status_code == 403  # Forbidden

