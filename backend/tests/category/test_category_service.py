"""
Tests for CategoryService.
"""
import pytest
from uuid import uuid4

from app.services.category_service import CategoryService
from app.core.exceptions import NotFoundError, ConflictError, ValidationError
from app.schemas.category_schema import CategoryCreateRequest, CategoryUpdateRequest
from app.schemas.common_schema import PaginationParams


@pytest.mark.asyncio
class TestCategoryService:
    """Test CategoryService methods."""
    
    async def test_get_category(
        self,
        category_service: CategoryService,
        sample_category,
        sample_service
    ):
        """Test getting category by ID with service count."""
        category_detail = await category_service.get_category(sample_category.id)
        
        assert category_detail.id == sample_category.id
        assert category_detail.name == sample_category.name
        assert category_detail.description == sample_category.description
        assert category_detail.is_active is True
        assert category_detail.service_count >= 1  # sample_service is in this category
    
    async def test_get_category_not_found(
        self,
        category_service: CategoryService
    ):
        """Test getting non-existent category raises NotFoundError."""
        with pytest.raises(NotFoundError, match="Category with ID .* not found"):
            await category_service.get_category(uuid4())
    
    async def test_list_categories(
        self,
        category_service: CategoryService,
        sample_category,
        db_session
    ):
        """Test listing categories."""
        from app.models import ServiceCategory
        
        # Create additional categories
        category2 = ServiceCategory(
            name=f"Category_{str(uuid4())[:8]}",
            description="Second category",
            is_active=True,
            display_order=2
        )
        category3 = ServiceCategory(
            name=f"Category_{str(uuid4())[:8]}",
            description="Inactive category",
            is_active=False,
            display_order=3
        )
        db_session.add(category2)
        db_session.add(category3)
        await db_session.commit()
        
        # List active categories only
        response = await category_service.list_categories(
            include_inactive=False,
            pagination=PaginationParams(page=1, limit=100)
        )
        
        assert response.total >= 2
        assert len(response.categories) >= 2
        assert all(cat.is_active for cat in response.categories)
        
        # List all categories including inactive
        response_all = await category_service.list_categories(
            include_inactive=True,
            pagination=PaginationParams(page=1, limit=100)
        )
        
        assert response_all.total >= 3
        assert len(response_all.categories) >= 3
        assert any(not cat.is_active for cat in response_all.categories)
    
    async def test_list_categories_with_pagination(
        self,
        category_service: CategoryService,
        sample_category,
        db_session
    ):
        """Test listing categories with pagination."""
        from app.models import ServiceCategory
        
        # Create multiple categories
        for i in range(5):
            category = ServiceCategory(
                name=f"Category_{str(uuid4())[:8]}",
                description=f"Category {i+1}",
                is_active=True,
                display_order=i
            )
            db_session.add(category)
        await db_session.commit()
        
        # Test pagination
        pagination = PaginationParams(page=1, limit=2)
        response = await category_service.list_categories(
            include_inactive=False,
            pagination=pagination
        )
        
        assert response.page == 1
        assert response.limit == 2
        assert len(response.categories) == 2
        assert response.total >= 6  # sample_category + 5 created
        assert response.total_pages > 1
        assert response.has_more is True
    
    async def test_list_categories_empty(
        self,
        category_service: CategoryService,
        db_session
    ):
        """Test listing categories when none exist."""
        # Get all categories and mark them inactive or delete
        from app.models import ServiceCategory
        from sqlmodel import select
        
        stmt = select(ServiceCategory)
        result = await db_session.execute(stmt)
        all_categories = result.scalars().all()
        
        for cat in all_categories:
            cat.is_active = False
            db_session.add(cat)
        await db_session.commit()
        
        # List active categories
        response = await category_service.list_categories(
            include_inactive=False,
            pagination=PaginationParams(page=1, limit=20)
        )
        
        assert response.total == 0
        assert len(response.categories) == 0
    
    async def test_list_categories_service_counts(
        self,
        category_service: CategoryService,
        sample_category,
        sample_service,
        db_session
    ):
        """Test that service counts are correctly calculated."""
        from app.models import ServiceCategory, Service
        
        # Create another category with services
        category2 = ServiceCategory(
            name=f"Category_{str(uuid4())[:8]}",
            description="Category with services",
            is_active=True
        )
        db_session.add(category2)
        await db_session.commit()
        
        # Add services to category2
        service2 = Service(
            merchant_id=sample_service.merchant_id,
            category_id=category2.id,
            name="Service 2",
            description="Service 2 description",
            price=3000000.0,
            location_region="Tashkent",
            is_active=True
        )
        service3 = Service(
            merchant_id=sample_service.merchant_id,
            category_id=category2.id,
            name="Service 3",
            description="Service 3 description",
            price=4000000.0,
            location_region="Tashkent",
            is_active=True
        )
        db_session.add(service2)
        db_session.add(service3)
        await db_session.commit()
        
        response = await category_service.list_categories(
            include_inactive=False,
            pagination=PaginationParams(page=1, limit=100)
        )
        
        # Find our categories in the response
        cat1_detail = next((c for c in response.categories if c.id == sample_category.id), None)
        cat2_detail = next((c for c in response.categories if c.id == category2.id), None)
        
        assert cat1_detail is not None
        assert cat2_detail is not None
        assert cat1_detail.service_count >= 1  # sample_service
        assert cat2_detail.service_count >= 2  # service2 + service3
    
    async def test_create_category(
        self,
        category_service: CategoryService
    ):
        """Test creating a new category."""
        request = CategoryCreateRequest(
            name=f"NewCategory_{str(uuid4())[:8]}",
            description="New category description",
            display_order=5,
            is_active=True
        )
        
        created = await category_service.create_category(request)
        
        assert created.id is not None
        assert created.name == request.name
        assert created.description == request.description
        assert created.display_order == 5
        assert created.is_active is True
        assert created.service_count == 0
    
    async def test_create_category_duplicate_name(
        self,
        category_service: CategoryService,
        sample_category
    ):
        """Test creating category with duplicate name raises ConflictError."""
        request = CategoryCreateRequest(
            name=sample_category.name,  # Use existing name
            description="Duplicate category",
            is_active=True
        )
        
        with pytest.raises(ConflictError, match="already exists"):
            await category_service.create_category(request)
    
    async def test_create_category_with_whitespace(
        self,
        category_service: CategoryService
    ):
        """Test that whitespace in name and description is trimmed."""
        request = CategoryCreateRequest(
            name="  CategoryWithSpaces  ",
            description="  Description with spaces  ",
            is_active=True
        )
        
        created = await category_service.create_category(request)
        
        assert created.name == "CategoryWithSpaces"  # Trimmed
        assert created.description == "Description with spaces"  # Trimmed
    
    async def test_update_category(
        self,
        category_service: CategoryService,
        sample_category
    ):
        """Test updating a category."""
        request = CategoryUpdateRequest(
            name=f"UpdatedCategory_{str(uuid4())[:8]}",
            description="Updated description",
            display_order=99,
            is_active=False
        )
        
        updated = await category_service.update_category(sample_category.id, request)
        
        assert updated.id == sample_category.id
        assert updated.name == request.name
        assert updated.description == request.description
        assert updated.display_order == 99
        assert updated.is_active is False
    
    async def test_update_category_not_found(
        self,
        category_service: CategoryService
    ):
        """Test updating non-existent category raises NotFoundError."""
        request = CategoryUpdateRequest(
            name="UpdatedName",
            description="Updated description"
        )
        
        with pytest.raises(NotFoundError, match="Category with ID .* not found"):
            await category_service.update_category(uuid4(), request)
    
    async def test_update_category_name_conflict(
        self,
        category_service: CategoryService,
        sample_category,
        db_session
    ):
        """Test updating category with conflicting name raises ConflictError."""
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
        request = CategoryUpdateRequest(
            name=category2.name
        )
        
        with pytest.raises(ConflictError, match="already exists"):
            await category_service.update_category(sample_category.id, request)
    
    async def test_update_category_partial(
        self,
        category_service: CategoryService,
        sample_category
    ):
        """Test updating only specific fields."""
        original_name = sample_category.name
        
        # Update only description
        request = CategoryUpdateRequest(
            description="Only description updated"
        )
        
        updated = await category_service.update_category(sample_category.id, request)
        
        assert updated.name == original_name  # Unchanged
        assert updated.description == "Only description updated"
        
        # Note: icon_url update is now handled by a separate endpoint (upload_category_icon)
        # This test only verifies partial updates of name and description
    
    async def test_update_category_same_name(
        self,
        category_service: CategoryService,
        sample_category
    ):
        """Test updating category with same name (should succeed)."""
        request = CategoryUpdateRequest(
            name=sample_category.name,  # Same name
            description="Updated description"
        )
        
        updated = await category_service.update_category(sample_category.id, request)
        
        assert updated.name == sample_category.name
        assert updated.description == "Updated description"
    
    async def test_delete_category(
        self,
        category_service: CategoryService,
        db_session
    ):
        """Test deleting a category without services (hard delete)."""
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
        result = await category_service.delete_category(category_id)
        
        assert result is True
        
        # Verify it's deleted
        with pytest.raises(NotFoundError):
            await category_service.get_category(category_id)
    
    async def test_delete_category_with_services(
        self,
        category_service: CategoryService,
        sample_category,
        sample_service,
        db_session
    ):
        """Test deleting a category with services (soft delete)."""
        # Ensure service is in the category (it should already be from fixture)
        # Verify service is in the category
        assert sample_service.category_id == sample_category.id
        
        # Delete the category (should soft delete)
        result = await category_service.delete_category(sample_category.id)
        
        assert result is True
        
        # Verify category is soft deleted (still exists but inactive)
        deleted_category = await category_service.get_category(sample_category.id)
        assert deleted_category.is_active is False
    
    async def test_delete_category_not_found(
        self,
        category_service: CategoryService
    ):
        """Test deleting non-existent category raises NotFoundError."""
        with pytest.raises(NotFoundError, match="Category with ID .* not found"):
            await category_service.delete_category(uuid4())
    
    async def test_delete_category_only_active_services_counted(
        self,
        category_service: CategoryService,
        sample_category,
        sample_service,
        db_session
    ):
        """Test that only active services are counted when deciding soft vs hard delete."""
        from app.models import Service
        
        # Create an inactive service in the same category
        inactive_service = Service(
            merchant_id=sample_service.merchant_id,
            category_id=sample_category.id,
            name="Inactive Service",
            description="Inactive service",
            price=2000000.0,
            location_region="Tashkent",
            is_active=False  # Inactive
        )
        db_session.add(inactive_service)
        await db_session.commit()
        
        # Delete should soft delete since there's an active service
        # (even though there's also an inactive service)
        result = await category_service.delete_category(sample_category.id)
        
        assert result is True
        
        # Verify category is soft deleted (inactive services don't prevent soft delete)
        deleted_category = await category_service.get_category(sample_category.id)
        assert deleted_category.is_active is False

