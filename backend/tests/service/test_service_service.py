"""
Tests for ServiceManager.
"""
import pytest
from uuid import uuid4

from app.services.service_manager import ServiceManager
from app.core.exceptions import NotFoundError, ValidationError
from app.schemas.service_schema import ServiceSearchFilters
from app.schemas.common_schema import PaginationParams


@pytest.mark.asyncio
class TestServiceManager:
    """Test ServiceManager methods."""
    
    async def test_get_categories(
        self,
        db_session,
        sample_category: "ServiceCategory",
        sample_service: "Service"
    ):
        """Test getting all categories with service counts."""
        manager = ServiceManager(db_session)
        
        response = await manager.get_categories()
        
        assert response.total >= 1
        assert len(response.categories) >= 1
        
        # Find our sample category
        sample_cat = next(
            (cat for cat in response.categories if cat.id == sample_category.id),
            None
        )
        assert sample_cat is not None
        assert sample_cat.name == sample_category.name
        assert sample_cat.service_count >= 1  # At least our sample service
    
    async def test_browse_services_no_category(
        self,
        db_session,
        sample_service: "Service",
        sample_merchant: "Merchant"
    ):
        """Test browsing services without category filter."""
        manager = ServiceManager(db_session)
        
        response = await manager.browse_services(
            category_id=None,
            pagination=PaginationParams(page=1, limit=10)
        )
        
        assert response.total >= 1
        assert len(response.services) >= 1
        assert any(s.id == sample_service.id for s in response.services)
    
    async def test_browse_services_with_category(
        self,
        db_session,
        sample_service: "Service",
        sample_category: "ServiceCategory",
        sample_merchant: "Merchant",
        sample_merchant_user: "User"
    ):
        """Test browsing services filtered by category."""
        manager = ServiceManager(db_session)
        
        # Create service in different category
        from app.models import ServiceCategory, Service
        other_category = ServiceCategory(
            name=f"OtherCategory_{str(uuid4())[:8]}",
            description="Other category",
            is_active=True
        )
        db_session.add(other_category)
        await db_session.commit()
        await db_session.refresh(other_category)
        
        other_service = Service(
            merchant_id=sample_merchant.id,
            category_id=other_category.id,
            name="Other Service",
            description="Service in other category",
            price=3000000.0,
            location_region="Tashkent",
            is_active=True
        )
        db_session.add(other_service)
        await db_session.commit()
        
        # Browse by sample category
        response = await manager.browse_services(
            category_id=sample_category.id,
            pagination=PaginationParams(page=1, limit=100)
        )
        
        # All services should be in the specified category
        service_ids = [s.id for s in response.services]
        assert sample_service.id in service_ids
        assert other_service.id not in service_ids
    
    async def test_browse_services_pagination(
        self,
        db_session,
        sample_category: "ServiceCategory",
        sample_merchant: "Merchant"
    ):
        """Test browsing services with pagination."""
        manager = ServiceManager(db_session)
        
        # Create multiple services
        from app.models import Service
        for i in range(5):
            service = Service(
                merchant_id=sample_merchant.id,
                category_id=sample_category.id,
                name=f"Service {i}",
                description=f"Description {i}",
                price=1000000.0 * (i + 1),
                location_region="Tashkent",
                is_active=True
            )
            db_session.add(service)
        await db_session.commit()
        
        # First page
        page1 = await manager.browse_services(
            category_id=sample_category.id,
            pagination=PaginationParams(page=1, limit=2)
        )
        
        assert page1.total >= 5
        assert len(page1.services) == 2
        assert page1.page == 1
        assert page1.limit == 2
        assert page1.has_more is True
        
        # Second page
        page2 = await manager.browse_services(
            category_id=sample_category.id,
            pagination=PaginationParams(page=2, limit=2)
        )
        
        assert len(page2.services) == 2
        assert page2.page == 2
        
        # No overlap
        page1_ids = {s.id for s in page1.services}
        page2_ids = {s.id for s in page2.services}
        assert page1_ids.isdisjoint(page2_ids)
    
    async def test_search_services_no_filters(
        self,
        db_session,
        sample_service: "Service"
    ):
        """Test searching services with no filters."""
        manager = ServiceManager(db_session)
        
        filters = ServiceSearchFilters()
        response = await manager.search_services(
            filters=filters,
            pagination=PaginationParams(page=1, limit=100)
        )
        
        assert response.total >= 1
        assert any(s.id == sample_service.id for s in response.services)
    
    async def test_search_services_with_query(
        self,
        db_session,
        sample_service: "Service"
    ):
        """Test searching services with text query."""
        manager = ServiceManager(db_session)
        
        filters = ServiceSearchFilters(query="Wedding")
        response = await manager.search_services(
            filters=filters,
            pagination=PaginationParams(page=1, limit=100)
        )
        
        service_ids = [s.id for s in response.services]
        assert sample_service.id in service_ids
        
        # All services should match the query
        for service in response.services:
            assert "wedding" in service.name.lower() or "wedding" in (service.description or "").lower()
    
    async def test_search_services_with_category(
        self,
        db_session,
        sample_service: "Service",
        sample_category: "ServiceCategory",
        sample_merchant: "Merchant"
    ):
        """Test searching services filtered by category."""
        manager = ServiceManager(db_session)
        
        # Create another category and service
        from app.models import ServiceCategory, Service
        category2 = ServiceCategory(
            name=f"Category2_{str(uuid4())[:8]}",
            is_active=True
        )
        db_session.add(category2)
        await db_session.commit()
        await db_session.refresh(category2)
        
        service2 = Service(
            merchant_id=sample_merchant.id,
            category_id=category2.id,
            name="Different Service",
            description="Service in different category",
            price=3000000.0,
            location_region="Tashkent",
            is_active=True
        )
        db_session.add(service2)
        await db_session.commit()
        
        # Search by sample category
        filters = ServiceSearchFilters(category_id=sample_category.id)
        response = await manager.search_services(
            filters=filters,
            pagination=PaginationParams(page=1, limit=100)
        )
        
        service_ids = [s.id for s in response.services]
        assert sample_service.id in service_ids
        assert service2.id not in service_ids
    
    async def test_search_services_with_price_filters(
        self,
        db_session,
        sample_service: "Service",
        sample_category: "ServiceCategory",
        sample_merchant: "Merchant"
    ):
        """Test searching services with price range filters."""
        manager = ServiceManager(db_session)
        
        # Create services with different prices
        from app.models import Service
        service_cheap = Service(
            merchant_id=sample_merchant.id,
            category_id=sample_category.id,
            name="Cheap Service",
            description="Affordable service",
            price=1000000.0,
            location_region="Tashkent",
            is_active=True
        )
        service_expensive = Service(
            merchant_id=sample_merchant.id,
            category_id=sample_category.id,
            name="Expensive Service",
            description="Premium service",
            price=10000000.0,
            location_region="Tashkent",
            is_active=True
        )
        db_session.add(service_cheap)
        db_session.add(service_expensive)
        await db_session.commit()
        
        # Search with min_price
        filters = ServiceSearchFilters(min_price=5000000.0)
        response = await manager.search_services(
            filters=filters,
            pagination=PaginationParams(page=1, limit=100)
        )
        
        for service in response.services:
            assert service.price >= 5000000.0
        
        # Search with max_price
        filters = ServiceSearchFilters(max_price=6000000.0)
        response = await manager.search_services(
            filters=filters,
            pagination=PaginationParams(page=1, limit=100)
        )
        
        for service in response.services:
            assert service.price <= 6000000.0
    
    async def test_search_services_with_location(
        self,
        db_session,
        sample_service: "Service",
        sample_category: "ServiceCategory",
        sample_merchant: "Merchant"
    ):
        """Test searching services filtered by location."""
        manager = ServiceManager(db_session)
        
        # Create service in different region
        from app.models import Service
        service2 = Service(
            merchant_id=sample_merchant.id,
            category_id=sample_category.id,
            name="Samarkand Service",
            description="Service in Samarkand",
            price=4000000.0,
            location_region="Samarkand",
            is_active=True
        )
        db_session.add(service2)
        await db_session.commit()
        
        filters = ServiceSearchFilters(location_region="Tashkent")
        response = await manager.search_services(
            filters=filters,
            pagination=PaginationParams(page=1, limit=100)
        )
        
        for service in response.services:
            assert service.location_region == "Tashkent"
        
        service_ids = [s.id for s in response.services]
        assert sample_service.id in service_ids
        assert service2.id not in service_ids
    
    async def test_search_services_validation_invalid_region(
        self,
        db_session
    ):
        """Test search validation with invalid region."""
        manager = ServiceManager(db_session)
        
        filters = ServiceSearchFilters(location_region="InvalidRegion")
        
        with pytest.raises(ValidationError, match="Invalid region"):
            await manager.search_services(
                filters=filters,
                pagination=PaginationParams()
            )
    
    async def test_search_services_validation_invalid_price_range(
        self,
        db_session
    ):
        """Test search validation with invalid price range."""
        manager = ServiceManager(db_session)
        
        filters = ServiceSearchFilters(min_price=10000000.0, max_price=5000000.0)
        
        with pytest.raises(ValidationError, match="min_price cannot be greater than max_price"):
            await manager.search_services(
                filters=filters,
                pagination=PaginationParams()
            )
    
    async def test_search_services_validation_invalid_sort_by(
        self,
        db_session
    ):
        """Test search validation with invalid sort_by."""
        manager = ServiceManager(db_session)
        
        filters = ServiceSearchFilters(sort_by="invalid_sort")
        
        with pytest.raises(ValidationError, match="Invalid sort_by"):
            await manager.search_services(
                filters=filters,
                pagination=PaginationParams()
            )
    
    async def test_search_services_validation_invalid_sort_order(
        self,
        db_session
    ):
        """Test search validation with invalid sort_order."""
        manager = ServiceManager(db_session)
        
        filters = ServiceSearchFilters(sort_order="invalid")
        
        with pytest.raises(ValidationError, match="Invalid sort_order"):
            await manager.search_services(
                filters=filters,
                pagination=PaginationParams()
            )
    
    async def test_search_services_validation_invalid_rating(
        self,
        db_session
    ):
        """Test search validation with invalid rating range."""
        from pydantic import ValidationError as PydanticValidationError
        
        # Rating validation happens at Pydantic schema level
        # Try to create filter with invalid rating - should fail at schema validation
        with pytest.raises(PydanticValidationError):
            ServiceSearchFilters(min_rating=10.0)
        
        # Test valid rating range (should work)
        filters = ServiceSearchFilters(min_rating=4.5)
        manager = ServiceManager(db_session)
        
        # This should work without ValidationError
        response = await manager.search_services(
            filters=filters,
            pagination=PaginationParams()
        )
        
        # Response should be valid (even if empty)
        assert response is not None
    
    async def test_get_featured_services(
        self,
        db_session,
        sample_service: "Service",
        sample_merchant: "Merchant"
    ):
        """Test getting featured services."""
        manager = ServiceManager(db_session)
        
        # Create featured service
        from datetime import datetime, timedelta
        from app.models import FeaturedService, FeatureType
        now = datetime.now()
        start_date = now - timedelta(days=1)
        end_date = now + timedelta(days=7)
        days_duration = (end_date - start_date).days
        
        featured = FeaturedService(
            service_id=sample_service.id,
            merchant_id=sample_merchant.id,
            start_date=start_date,
            end_date=end_date,
            days_duration=days_duration,
            feature_type=FeatureType.MONTHLY_ALLOCATION,
            is_active=True
        )
        db_session.add(featured)
        await db_session.commit()
        
        response = await manager.get_featured_services()
        
        assert response.total >= 1
        assert any(s.id == sample_service.id for s in response.services)
        
        # Check that featured flag is set
        featured_service = next(
            (s for s in response.services if s.id == sample_service.id),
            None
        )
        assert featured_service is not None
        assert featured_service.is_featured is True
    
    async def test_get_featured_services_with_limit(
        self,
        db_session,
        sample_category: "ServiceCategory",
        sample_merchant: "Merchant"
    ):
        """Test getting featured services with limit."""
        manager = ServiceManager(db_session)
        
        # Create multiple featured services
        from datetime import datetime, timedelta
        from app.models import Service, FeaturedService, FeatureType
        now = datetime.now()
        
        for i in range(3):
            service = Service(
                merchant_id=sample_merchant.id,
                category_id=sample_category.id,
                name=f"Featured Service {i}",
                description=f"Featured service {i} description",
                price=5000000.0,
                location_region="Tashkent",
                is_active=True
            )
            db_session.add(service)
            await db_session.flush()
            
            start_date = now - timedelta(days=1)
            end_date = now + timedelta(days=7)
            days_duration = (end_date - start_date).days
            
            featured = FeaturedService(
                service_id=service.id,
                merchant_id=sample_merchant.id,
                start_date=start_date,
                end_date=end_date,
                days_duration=days_duration,
                feature_type=FeatureType.MONTHLY_ALLOCATION,
                is_active=True
            )
            db_session.add(featured)
        await db_session.commit()
        
        # Get with limit
        response = await manager.get_featured_services(limit=2)
        assert len(response.services) == 2
        assert response.total == 2
    
    async def test_get_service_details(
        self,
        db_session,
        sample_service: "Service",
        sample_merchant: "Merchant",
        sample_category: "ServiceCategory",
        sample_merchant_user: "User"
    ):
        """Test getting service details."""
        manager = ServiceManager(db_session)
        
        # Create service images
        from app.models import Image, ImageType
        image1 = Image(
            related_id=sample_service.id,
            image_type=ImageType.SERVICE_IMAGE,
            s3_url="https://example.com/image1.jpg",
            file_name="image1.jpg",
            display_order=1,
            is_active=True
        )
        db_session.add(image1)
        await db_session.commit()
        
        details = await manager.get_service_details(sample_service.id)
        
        assert details.id == sample_service.id
        assert details.name == sample_service.name
        assert details.description == sample_service.description
        assert details.price == sample_service.price
        assert details.merchant.id == sample_merchant.id
        assert details.merchant.business_name == sample_merchant.business_name
        assert details.category_id == sample_category.id
        assert details.category_name == sample_category.name
        assert len(details.images) >= 1
        assert details.images[0].s3_url == "https://example.com/image1.jpg"
    
    async def test_get_service_details_not_found(
        self,
        db_session
    ):
        """Test getting non-existent service details raises NotFoundError."""
        manager = ServiceManager(db_session)
        
        with pytest.raises(NotFoundError, match="Service not found or inactive"):
            await manager.get_service_details(uuid4())
    
    async def test_record_service_interaction_like(
        self,
        db_session,
        sample_service: "Service",
        sample_client_user: "User"
    ):
        """Test recording like interaction."""
        manager = ServiceManager(db_session)
        
        result = await manager.record_service_interaction(
            user_id=sample_client_user.id,
            service_id=sample_service.id,
            interaction_type="like"
        )
        
        assert result["success"] is True
        assert "like" in result["message"].lower()
        assert "new_count" in result
    
    async def test_record_service_interaction_save(
        self,
        db_session,
        sample_service: "Service",
        sample_client_user: "User"
    ):
        """Test recording save interaction."""
        manager = ServiceManager(db_session)
        
        result = await manager.record_service_interaction(
            user_id=sample_client_user.id,
            service_id=sample_service.id,
            interaction_type="save"
        )
        
        assert result["success"] is True
        assert "save" in result["message"].lower()
        assert "new_count" in result
    
    async def test_record_service_interaction_share(
        self,
        db_session,
        sample_service: "Service",
        sample_client_user: "User"
    ):
        """Test recording share interaction."""
        manager = ServiceManager(db_session)
        
        result = await manager.record_service_interaction(
            user_id=sample_client_user.id,
            service_id=sample_service.id,
            interaction_type="share"
        )
        
        assert result["success"] is True
        assert "share" in result["message"].lower()
        assert "new_count" in result
    
    async def test_record_service_interaction_invalid_type(
        self,
        db_session,
        sample_service: "Service",
        sample_client_user: "User"
    ):
        """Test recording interaction with invalid type raises ValidationError."""
        manager = ServiceManager(db_session)
        
        with pytest.raises(ValidationError, match="Invalid interaction type"):
            await manager.record_service_interaction(
                user_id=sample_client_user.id,
                service_id=sample_service.id,
                interaction_type="invalid_type"
            )
    
    async def test_record_service_interaction_user_not_found(
        self,
        db_session,
        sample_service: "Service"
    ):
        """Test recording interaction with non-existent user raises NotFoundError."""
        manager = ServiceManager(db_session)
        
        with pytest.raises(NotFoundError, match="User not found"):
            await manager.record_service_interaction(
                user_id=uuid4(),
                service_id=sample_service.id,
                interaction_type="like"
            )
    
    async def test_record_service_interaction_service_not_found(
        self,
        db_session,
        sample_client_user: "User"
    ):
        """Test recording interaction with non-existent service raises NotFoundError."""
        manager = ServiceManager(db_session)
        
        with pytest.raises(NotFoundError, match="Service not found or inactive"):
            await manager.record_service_interaction(
                user_id=sample_client_user.id,
                service_id=uuid4(),
                interaction_type="like"
            )

