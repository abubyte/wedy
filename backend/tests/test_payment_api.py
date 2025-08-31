import pytest
from datetime import date, timedelta
from unittest.mock import patch, AsyncMock
from fastapi.testclient import TestClient
from sqlmodel import Session

from app.models.payment import TariffPlan, Payment, MerchantSubscription, PaymentMethod, PaymentStatus, SubscriptionStatus
from app.models.user import User, UserType, Merchant


class TestPaymentAPI:
    """Test payment API endpoints."""

    def test_get_tariffs_endpoint(self, client: TestClient, session: Session):
        """Test GET /api/v1/payments/tariffs endpoint."""
        # Create test tariff plans
        plans = [
            TariffPlan(name="Basic", price_per_month=50000.0, max_services=10,
                      max_images_per_service=5, max_phone_numbers=2,
                      max_gallery_images=20, max_social_accounts=3),
            TariffPlan(name="Premium", price_per_month=100000.0, max_services=50,
                      max_images_per_service=10, max_phone_numbers=5,
                      max_gallery_images=100, max_social_accounts=10),
            TariffPlan(name="Inactive", price_per_month=75000.0, max_services=25,
                      max_images_per_service=8, max_phone_numbers=3,
                      max_gallery_images=50, max_social_accounts=5, is_active=False)
        ]
        
        for plan in plans:
            session.add(plan)
        session.commit()
        
        response = client.get("/api/v1/payments/tariffs")
        
        assert response.status_code == 200
        data = response.json()
        
        assert len(data) == 2  # Only active plans
        plan_names = [plan["name"] for plan in data]
        assert "Basic" in plan_names
        assert "Premium" in plan_names
        assert "Inactive" not in plan_names
        
        # Check plan structure
        basic_plan = next(p for p in data if p["name"] == "Basic")
        assert basic_plan["price_per_month"] == 50000.0
        assert basic_plan["max_services"] == 10
        assert basic_plan["is_active"] is True

    def test_get_merchant_subscription_endpoint_authenticated(self, client: TestClient, session: Session):
        """Test GET /api/v1/merchants/subscription endpoint with authentication."""
        # Create user and merchant
        user = User(phone_number="998901234567", name="Test Merchant", user_type=UserType.MERCHANT)
        session.add(user)
        session.commit()
        session.refresh(user)
        
        merchant = Merchant(user_id=user.id, business_name="Test Business", location_region="Toshkent")
        session.add(merchant)
        session.commit()
        session.refresh(merchant)
        
        # Create tariff plan
        plan = TariffPlan(name="Standard", price_per_month=75000.0, max_services=20,
                         max_images_per_service=8, max_phone_numbers=3,
                         max_gallery_images=50, max_social_accounts=5)
        session.add(plan)
        session.commit()
        session.refresh(plan)
        
        # Create active subscription
        subscription = MerchantSubscription(
            merchant_id=merchant.id,
            tariff_plan_id=plan.id,
            start_date=date.today(),
            end_date=date.today() + timedelta(days=30),
            status=SubscriptionStatus.ACTIVE
        )
        session.add(subscription)
        session.commit()
        
        # Mock authentication
        with patch("app.api.deps.get_current_user", return_value=user):
            response = client.get("/api/v1/merchants/subscription")
        
        assert response.status_code == 200
        data = response.json()
        
        assert data["status"] == "active"
        assert data["tariff_plan"]["name"] == "Standard"
        assert data["start_date"] == str(subscription.start_date)
        assert data["end_date"] == str(subscription.end_date)

    def test_get_merchant_subscription_no_active_subscription(self, client: TestClient, session: Session):
        """Test getting subscription when merchant has no active subscription."""
        # Create user and merchant without subscription
        user = User(phone_number="998901234568", name="Test Merchant 2", user_type=UserType.MERCHANT)
        session.add(user)
        session.commit()
        session.refresh(user)
        
        merchant = Merchant(user_id=user.id, business_name="Test Business 2", location_region="Samarqand")
        session.add(merchant)
        session.commit()
        
        # Mock authentication
        with patch("app.api.deps.get_current_user", return_value=user):
            response = client.get("/api/v1/merchants/subscription")
        
        assert response.status_code == 404
        data = response.json()
        assert "No active subscription" in data["detail"]

    def test_create_tariff_payment_endpoint(self, client: TestClient, session: Session):
        """Test POST /api/v1/payments/tariff endpoint."""
        # Create user and merchant
        user = User(phone_number="998901234569", name="Test Merchant 3", user_type=UserType.MERCHANT)
        session.add(user)
        session.commit()
        session.refresh(user)
        
        merchant = Merchant(user_id=user.id, business_name="Test Business 3", location_region="Buxoro")
        session.add(merchant)
        session.commit()
        
        # Create tariff plan
        plan = TariffPlan(name="Business", price_per_month=100000.0, max_services=30,
                         max_images_per_service=10, max_phone_numbers=4,
                         max_gallery_images=75, max_social_accounts=8)
        session.add(plan)
        session.commit()
        session.refresh(plan)
        
        payment_data = {
            "tariff_plan_id": str(plan.id),
            "duration_months": 3,
            "payment_method": "payme"
        }
        
        # Mock payment service
        with patch("app.services.payment_service.PaymentService") as mock_service:
            mock_instance = mock_service.return_value
            mock_instance.create_tariff_payment = AsyncMock(return_value={
                "id": "payment_123",
                "amount": 270000.0,  # 100000 * 3 * 0.9 (10% discount)
                "payment_method": "payme",
                "status": "pending",
                "payment_url": "https://checkout.paycom.uz/payment_123"
            })
            
            with patch("app.api.deps.get_current_user", return_value=user):
                response = client.post("/api/v1/payments/tariff", json=payment_data)
        
        assert response.status_code == 201
        data = response.json()
        
        assert data["amount"] == 270000.0
        assert data["payment_method"] == "payme"
        assert data["status"] == "pending"
        assert "payment_url" in data

    def test_create_tariff_payment_invalid_plan(self, client: TestClient, session: Session):
        """Test tariff payment creation with invalid plan ID."""
        user = User(phone_number="998901234570", name="Test Merchant 4", user_type=UserType.MERCHANT)
        session.add(user)
        session.commit()
        session.refresh(user)
        
        payment_data = {
            "tariff_plan_id": "550e8400-e29b-41d4-a716-446655440000",  # Non-existent UUID
            "duration_months": 1,
            "payment_method": "payme"
        }
        
        with patch("app.api.deps.get_current_user", return_value=user):
            response = client.post("/api/v1/payments/tariff", json=payment_data)
        
        assert response.status_code == 404

    def test_create_featured_service_payment_endpoint(self, client: TestClient, session: Session):
        """Test POST /api/v1/payments/featured-service endpoint."""
        # Create user, merchant, and service setup would go here
        user = User(phone_number="998901234571", name="Test Merchant 5", user_type=UserType.MERCHANT)
        session.add(user)
        session.commit()
        session.refresh(user)
        
        payment_data = {
            "service_id": "550e8400-e29b-41d4-a716-446655440001",
            "duration_days": 15,
            "payment_method": "click"
        }
        
        # Mock payment service for featured services
        with patch("app.services.payment_service.PaymentService") as mock_service:
            mock_instance = mock_service.return_value
            mock_instance.create_featured_service_payment = AsyncMock(return_value={
                "id": "payment_124",
                "amount": 13500.0,  # Featured service pricing with discount
                "payment_method": "click",
                "status": "pending",
                "payment_url": "https://my.click.uz/payment_124"
            })
            
            with patch("app.api.deps.get_current_user", return_value=user):
                response = client.post("/api/v1/payments/featured-service", json=payment_data)
        
        assert response.status_code == 201
        data = response.json()
        
        assert data["payment_method"] == "click"
        assert data["status"] == "pending"
        assert "payment_url" in data

    def test_payment_webhook_payme(self, client: TestClient, session: Session):
        """Test POST /api/v1/payments/webhook/payme endpoint."""
        # Create test payment
        user = User(phone_number="998901234572", name="Test User", user_type=UserType.MERCHANT)
        session.add(user)
        session.commit()
        session.refresh(user)
        
        payment = Payment(
            user_id=user.id,
            amount=50000.0,
            payment_type="tariff_subscription",
            payment_method=PaymentMethod.PAYME,
            transaction_id="payme_txn_123",
            status=PaymentStatus.PENDING
        )
        session.add(payment)
        session.commit()
        
        webhook_data = {
            "id": "webhook_123",
            "method": "payme",
            "params": {
                "id": "payme_txn_123",
                "state": 2,  # Completed
                "amount": 500000  # In tiyins
            }
        }
        
        # Mock webhook processing
        with patch("app.services.payment_service.PaymentService") as mock_service:
            mock_instance = mock_service.return_value
            mock_instance.process_payment_webhook = AsyncMock(return_value=True)
            
            response = client.post("/api/v1/payments/webhook/payme", json=webhook_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True

    def test_payment_webhook_invalid_method(self, client: TestClient):
        """Test webhook with invalid payment method."""
        webhook_data = {"test": "data"}
        
        response = client.post("/api/v1/payments/webhook/invalid", json=webhook_data)
        
        assert response.status_code == 400
        data = response.json()
        assert "Invalid payment method" in data["detail"]

    def test_payment_endpoints_require_authentication(self, client: TestClient):
        """Test that payment endpoints require authentication."""
        # Test protected endpoints without authentication
        protected_endpoints = [
            ("GET", "/api/v1/merchants/subscription"),
            ("POST", "/api/v1/payments/tariff"),
            ("POST", "/api/v1/payments/featured-service")
        ]
        
        for method, endpoint in protected_endpoints:
            if method == "GET":
                response = client.get(endpoint)
            else:
                response = client.post(endpoint, json={})
            
            assert response.status_code == 401  # Unauthorized

    def test_payment_validation_errors(self, client: TestClient, session: Session):
        """Test payment request validation errors."""
        user = User(phone_number="998901234573", name="Test User", user_type=UserType.MERCHANT)
        session.add(user)
        session.commit()
        session.refresh(user)
        
        # Test invalid tariff payment data
        invalid_data = {
            "tariff_plan_id": "invalid-uuid",
            "duration_months": 0,  # Invalid duration
            "payment_method": "invalid_method"
        }
        
        with patch("app.api.deps.get_current_user", return_value=user):
            response = client.post("/api/v1/payments/tariff", json=invalid_data)
        
        assert response.status_code == 422  # Validation error
        
        # Test missing required fields
        incomplete_data = {
            "duration_months": 1
            # Missing tariff_plan_id and payment_method
        }
        
        with patch("app.api.deps.get_current_user", return_value=user):
            response = client.post("/api/v1/payments/tariff", json=incomplete_data)
        
        assert response.status_code == 422