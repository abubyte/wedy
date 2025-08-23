from typing import List

# Uzbekistan regions for location filtering
UZBEKISTAN_REGIONS: List[str] = [
    "Tashkent",
    "Samarkand", 
    "Bukhara",
    "Andijan",
    "Ferghana",
    "Namangan",
    "Kashkadarya",
    "Surkhandarya",
    "Khorezm",
    "Navoiy",
    "Jizzakh",
    "Sirdarya",
    "Karakalpakstan"
]

# Service sorting options
SERVICE_SORT_OPTIONS = {
    "created_at": "Created Date",
    "price": "Price",
    "rating": "Rating",
    "popularity": "Popularity (views + likes)",
    "name": "Name"
}

# Valid interaction types
INTERACTION_TYPES = ["view", "like", "save", "share"]

# Default pagination
DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100

# Service search limits
MAX_SEARCH_QUERY_LENGTH = 200

# Image constraints
MAX_IMAGES_PER_SERVICE = 10

# Price constraints
MIN_SERVICE_PRICE = 0
MAX_SERVICE_PRICE = 100_000_000  # 100M UZS
