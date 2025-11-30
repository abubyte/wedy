"""
Tests for CategoryRepository.
"""
import pytest
from uuid import uuid4

from app.repositories.category_repository import CategoryRepository
from app.models import ServiceCategory, Service


@pytest.mark.asyncio
class TestCategoryRepository:
    """Test CategoryRepository methods."""
    
    async def test_get_category_by_id(
        self,
        db_session,
        sample_category: ServiceCategory
    ):
        """Test getting category by ID."""
        repo = CategoryRepository(db_session)
        
        category = await repo.get_category_by_id(sample_category.id)
        
        assert category is not None
        assert category.id == sample_category.id
        assert category.name == sample_category.name
        assert category.is_active is True
        
        # Test non-existent category
        non_existent = await repo.get_category_by_id(uuid4())
        assert non_existent is None
    
    async def test_get_category_by_name(
        self,
        db_session,
        sample_category: ServiceCategory
    ):
        """Test getting category by name."""
        repo = CategoryRepository(db_session)
        
        category = await repo.get_category_by_name(sample_category.name)
        
        assert category is not None
        assert category.id == sample_category.id
        assert category.name == sample_category.name
        
        # Test non-existent category
        non_existent = await repo.get_category_by_name("NonExistentCategory")
        assert non_existent is None
    
    async def test_get_all_categories(
        self,
        db_session,
        sample_category: ServiceCategory
    ):
        """Test getting all categories with pagination."""
        repo = CategoryRepository(db_session)
        
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
        
        # Test getting active categories only
        categories, total = await repo.get_all_categories(
            include_inactive=False,
            offset=0,
            limit=100
        )
        
        assert total >= 2  # sample_category + category2
        assert len(categories) >= 2
        assert all(cat.is_active for cat in categories)
        
        # Test including inactive
        categories_all, total_all = await repo.get_all_categories(
            include_inactive=True,
            offset=0,
            limit=100
        )
        
        assert total_all >= 3  # All categories
        assert len(categories_all) >= 3
        assert any(not cat.is_active for cat in categories_all)
        
        # Test pagination
        categories_page, total_page = await repo.get_all_categories(
            include_inactive=False,
            offset=0,
            limit=1
        )
        
        assert len(categories_page) == 1
        assert total_page >= 2
    
    async def test_get_all_categories_with_display_order(
        self,
        db_session
    ):
        """Test that categories are ordered by display_order and name."""
        repo = CategoryRepository(db_session)
        
        # Create categories with different display orders
        cat1 = ServiceCategory(
            name="CategoryA",
            description="First",
            display_order=2,
            is_active=True
        )
        cat2 = ServiceCategory(
            name="CategoryB",
            description="Second",
            display_order=1,  # Lower order should come first
            is_active=True
        )
        cat3 = ServiceCategory(
            name="CategoryC",
            description="Third",
            display_order=2,  # Same order, should be sorted by name
            is_active=True
        )
        
        db_session.add(cat1)
        db_session.add(cat2)
        db_session.add(cat3)
        await db_session.commit()
        
        categories, _ = await repo.get_all_categories(
            include_inactive=False,
            offset=0,
            limit=10
        )
        
        # Find our categories in the results
        cat_names = [c.name for c in categories if c.name in ["CategoryA", "CategoryB", "CategoryC"]]
        
        # Ensure all three categories are in the results
        assert "CategoryA" in cat_names
        assert "CategoryB" in cat_names
        assert "CategoryC" in cat_names
        
        # CategoryB (order=1) should come before CategoryA and CategoryC (order=2)
        # Among same order, alphabetical: CategoryA should come before CategoryC
        assert cat_names.index("CategoryB") < cat_names.index("CategoryA")
        assert cat_names.index("CategoryA") < cat_names.index("CategoryC")
    
    async def test_create_category(
        self,
        db_session
    ):
        """Test creating a new category."""
        repo = CategoryRepository(db_session)
        
        new_category = ServiceCategory(
            name=f"NewCategory_{str(uuid4())[:8]}",
            description="New category description",
            display_order=5,
            is_active=True
        )
        
        created = await repo.create_category(new_category)
        
        assert created.id is not None
        assert created.name == new_category.name
        assert created.description == new_category.description
        assert created.display_order == 5
        assert created.is_active is True
        
        # Verify it's in the database
        retrieved = await repo.get_category_by_id(created.id)
        assert retrieved is not None
        assert retrieved.name == created.name
    
    async def test_update_category(
        self,
        db_session,
        sample_category: ServiceCategory
    ):
        """Test updating a category."""
        repo = CategoryRepository(db_session)
        
        # Update category fields
        sample_category.description = "Updated description"
        sample_category.display_order = 99
        sample_category.is_active = False
        
        updated = await repo.update_category(sample_category)
        
        assert updated.description == "Updated description"
        assert updated.display_order == 99
        assert updated.is_active is False
        
        # Verify changes persisted
        retrieved = await repo.get_category_by_id(sample_category.id)
        assert retrieved.description == "Updated description"
        assert retrieved.display_order == 99
        assert retrieved.is_active is False
    
    async def test_delete_category_with_services_soft_delete(
        self,
        db_session,
        sample_category: ServiceCategory,
        sample_service: Service
    ):
        """Test deleting a category with active services (soft delete)."""
        repo = CategoryRepository(db_session)
        
        # Ensure the service is associated with the category
        sample_service.category_id = sample_category.id
        sample_service.is_active = True
        await db_session.commit()
        
        # Delete should soft delete (set is_active=False)
        result = await repo.delete_category(sample_category.id)
        
        assert result is True
        
        # Verify category is soft deleted
        deleted_category = await repo.get_category_by_id(sample_category.id)
        assert deleted_category is not None  # Still exists
        assert deleted_category.is_active is False  # But inactive
    
    async def test_delete_category_without_services_hard_delete(
        self,
        db_session
    ):
        """Test deleting a category without services (hard delete)."""
        repo = CategoryRepository(db_session)
        
        # Create a category without services
        category = ServiceCategory(
            name=f"CategoryToDelete_{str(uuid4())[:8]}",
            description="Category to delete",
            is_active=True
        )
        db_session.add(category)
        await db_session.commit()
        category_id = category.id
        
        # Delete should hard delete
        result = await repo.delete_category(category_id)
        
        assert result is True
        
        # Verify category is hard deleted (doesn't exist)
        deleted_category = await repo.get_category_by_id(category_id)
        assert deleted_category is None
    
    async def test_delete_category_not_found(
        self,
        db_session
    ):
        """Test deleting a non-existent category."""
        repo = CategoryRepository(db_session)
        
        non_existent_id = uuid4()
        result = await repo.delete_category(non_existent_id)
        
        assert result is False
    
    async def test_get_category_service_count(
        self,
        db_session,
        sample_category: ServiceCategory,
        sample_service: Service
    ):
        """Test getting service count for a category."""
        repo = CategoryRepository(db_session)
        
        # Ensure service is associated with category
        sample_service.category_id = sample_category.id
        sample_service.is_active = True
        await db_session.commit()
        
        # Create another active service
        service2 = Service(
            merchant_id=sample_service.merchant_id,
            category_id=sample_category.id,
            name="Another Service",
            description="Another service description",
            price=3000000.0,
            location_region="Tashkent",
            is_active=True
        )
        db_session.add(service2)
        await db_session.commit()
        
        # Create an inactive service (should not be counted)
        service3 = Service(
            merchant_id=sample_service.merchant_id,
            category_id=sample_category.id,
            name="Inactive Service",
            description="Inactive service description",
            price=2000000.0,
            location_region="Tashkent",
            is_active=False
        )
        db_session.add(service3)
        await db_session.commit()
        
        count = await repo.get_category_service_count(sample_category.id)
        
        assert count >= 2  # sample_service + service2 (service3 is inactive)
        
        # Test category with no services
        empty_category = ServiceCategory(
            name=f"EmptyCategory_{str(uuid4())[:8]}",
            description="Category with no services",
            is_active=True
        )
        db_session.add(empty_category)
        await db_session.commit()
        
        empty_count = await repo.get_category_service_count(empty_category.id)
        assert empty_count == 0

