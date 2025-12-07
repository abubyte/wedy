"""
Tests for UserRepository.
"""
import pytest
import random
# UUID import removed - using 9-digit string IDs now

from app.repositories.user_repository import UserRepository
from app.models import User, UserType, Merchant


@pytest.mark.asyncio
class TestUserRepository:
    """Test UserRepository methods."""
    
    async def test_get_by_id(self, db_session, sample_client_user: User):
        """Test getting user by ID."""
        repo = UserRepository(db_session)
        
        user = await repo.get_by_id(sample_client_user.id)
        
        assert user is not None
        assert user.id == sample_client_user.id
        assert user.phone_number == sample_client_user.phone_number
    
    async def test_get_by_id_not_found(self, db_session):
        """Test getting non-existent user returns None."""
        repo = UserRepository(db_session)
        
        # Use a 9-digit string ID instead of UUID
        user = await repo.get_by_id("999999999")
        
        assert user is None
    
    async def test_get_by_phone_number(self, db_session, sample_client_user: User):
        """Test getting user by phone number."""
        repo = UserRepository(db_session)
        
        user = await repo.get_by_phone_number(sample_client_user.phone_number)
        
        assert user is not None
        assert user.id == sample_client_user.id
        assert user.phone_number == sample_client_user.phone_number
    
    async def test_get_by_phone_number_not_found(self, db_session):
        """Test getting user by non-existent phone number returns None."""
        repo = UserRepository(db_session)
        
        user = await repo.get_by_phone_number("999999999")
        
        assert user is None
    
    async def test_get_merchant_by_user_id(
        self,
        db_session,
        sample_merchant_user: User,
        sample_merchant: Merchant
    ):
        """Test getting merchant by user ID."""
        repo = UserRepository(db_session)
        
        merchant = await repo.get_merchant_by_user_id(sample_merchant_user.id)
        
        assert merchant is not None
        assert merchant.id == sample_merchant.id
        assert merchant.user_id == sample_merchant_user.id
    
    async def test_get_merchant_by_user_id_not_found(self, db_session, sample_client_user: User):
        """Test getting merchant for non-merchant user returns None."""
        repo = UserRepository(db_session)
        
        merchant = await repo.get_merchant_by_user_id(sample_client_user.id)
        
        assert merchant is None
    
    async def test_is_phone_number_taken(self, db_session, sample_client_user: User):
        """Test checking if phone number is taken."""
        repo = UserRepository(db_session)
        
        # Check with existing phone number
        is_taken = await repo.is_phone_number_taken(sample_client_user.phone_number)
        assert is_taken is True
        
        # Check with non-existent phone number
        is_taken = await repo.is_phone_number_taken("999999999")
        assert is_taken is False
    
    async def test_is_phone_number_taken_exclude_user(
        self,
        db_session,
        sample_client_user: User
    ):
        """Test checking phone number with exclusion."""
        repo = UserRepository(db_session)
        
        # Phone number is taken by sample_client_user, but we exclude that user
        is_taken = await repo.is_phone_number_taken(
            sample_client_user.phone_number,
            exclude_user_id=sample_client_user.id
        )
        assert is_taken is False
        
        # Phone number is taken by another user
        is_taken = await repo.is_phone_number_taken(
            sample_client_user.phone_number,
            exclude_user_id="999999999"  # Different user ID (9-digit string)
        )
        assert is_taken is True
    
    async def test_get_all(self, db_session):
        """Test getting all users with pagination."""
        repo = UserRepository(db_session)
        
        # Create additional users
        user1 = User(
            phone_number=f"90{random.randint(1000000, 9999999)}",
            name="User 1",
            user_type=UserType.CLIENT,
            is_active=True
        )
        user2 = User(
            phone_number=f"90{random.randint(1000000, 9999999)}",
            name="User 2",
            user_type=UserType.CLIENT,
            is_active=True
        )
        db_session.add(user1)
        db_session.add(user2)
        await db_session.commit()
        await db_session.refresh(user1)
        await db_session.refresh(user2)
        
        # Get all users - might need higher limit if there are fixture users
        users = await repo.get_all(offset=0, limit=100)
        
        assert len(users) >= 2
        user_ids = [u.id for u in users]
        # Verify both users are in the results
        assert user1.id in user_ids, f"User1 {user1.id} not found in {len(users)} users"
        assert user2.id in user_ids, f"User2 {user2.id} not found in {len(users)} users"
    
    async def test_get_all_with_pagination(self, db_session):
        """Test getting all users with pagination parameters."""
        repo = UserRepository(db_session)
        
        # Create additional users
        users_to_create = []
        for i in range(5):
            user = User(
                phone_number=f"90{random.randint(1000000, 9999999)}",
                name=f"User {i}",
                user_type=UserType.CLIENT,
                is_active=True
            )
            users_to_create.append(user)
            db_session.add(user)
        await db_session.commit()
        
        # Get first page
        users_page1 = await repo.get_all(offset=0, limit=2)
        assert len(users_page1) == 2
        
        # Get second page
        users_page2 = await repo.get_all(offset=2, limit=2)
        assert len(users_page2) == 2
        
        # Ensure different users
        page1_ids = {u.id for u in users_page1}
        page2_ids = {u.id for u in users_page2}
        assert page1_ids.isdisjoint(page2_ids)
    
    async def test_count(self, db_session):
        """Test counting users."""
        repo = UserRepository(db_session)
        
        initial_count = await repo.count()
        
        # Create additional user
        user = User(
            phone_number=f"90{random.randint(1000000, 9999999)}",
            name="New User",
            user_type=UserType.CLIENT,
            is_active=True
        )
        db_session.add(user)
        await db_session.commit()
        
        new_count = await repo.count()
        assert new_count == initial_count + 1
    
    async def test_create(self, db_session):
        """Test creating a new user."""
        repo = UserRepository(db_session)
        
        new_user = User(
            phone_number=f"90{random.randint(1000000, 9999999)}",
            name="New User",
            user_type=UserType.CLIENT,
            is_active=True
        )
        
        created = await repo.create(new_user)
        
        assert created.id is not None
        assert created.name == "New User"
        assert created.user_type == UserType.CLIENT
        
        # Verify it's in database
        retrieved = await repo.get_by_id(created.id)
        assert retrieved is not None
        assert retrieved.name == created.name
    
    async def test_update(self, db_session, sample_client_user: User):
        """Test updating a user."""
        repo = UserRepository(db_session)
        
        sample_client_user.name = "Updated Name"
        updated = await repo.update(sample_client_user)
        
        assert updated.name == "Updated Name"
        
        # Verify in database
        retrieved = await repo.get_by_id(sample_client_user.id)
        assert retrieved.name == "Updated Name"
    
    async def test_soft_delete_user(self, db_session):
        """Test soft deleting a user."""
        repo = UserRepository(db_session)
        
        # Create a user to delete
        user = User(
            phone_number=f"90{random.randint(1000000, 9999999)}",
            name="User to Delete",
            user_type=UserType.CLIENT,
            is_active=True
        )
        db_session.add(user)
        await db_session.commit()
        await db_session.refresh(user)
        
        # Soft delete
        deleted = await repo.soft_delete_user(user.id)
        assert deleted is True
        
        # Verify user is inactive
        await db_session.refresh(user)
        assert user.is_active is False
        
        # Verify user still exists but is inactive
        retrieved = await repo.get_by_id(user.id)
        assert retrieved is not None
        assert retrieved.is_active is False
    
    async def test_soft_delete_user_not_found(self, db_session):
        """Test soft deleting non-existent user returns False."""
        repo = UserRepository(db_session)
        
        deleted = await repo.soft_delete_user("999999999")  # Non-existent 9-digit string ID
        
        assert deleted is False

