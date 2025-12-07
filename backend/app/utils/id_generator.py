"""Utility functions for generating IDs."""
import random
from typing import Set


def generate_6digit_id(existing_ids: Set[str] = None) -> str:
    """
    Generate a unique 9-digit numeric string ID.
    
    Uses only digits (0-9) for simplicity.
    Total possible combinations: 10^9 = 1,000,000,000
    
    Args:
        existing_ids: Set of existing IDs to avoid collisions
        
    Returns:
        9-digit numeric string (e.g., "123456789")
    """
    if existing_ids is None:
        existing_ids = set()
    
    # Use only digits
    max_attempts = 1000
    for _ in range(max_attempts):
        # Generate random 9-digit number (100000000 to 999999999)
        new_id = str(random.randint(100000000, 999999999))
        
        if new_id not in existing_ids:
            return new_id
    
    # If we couldn't find a unique ID after max_attempts, raise error
    raise ValueError("Could not generate unique 9-digit ID after maximum attempts")

