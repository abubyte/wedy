from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from uuid import UUID
from datetime import datetime
from typing import List

class CategoryCreateRequest(BaseModel):
    """Request schema for creating a category."""
    name: str = Field(..., min_length=1, max_length=100, description="Category name")
    description: Optional[str] = Field(None, max_length=500, description="Category description")
    display_order: int = Field(0, ge=0, description="Display order for sorting")
    is_active: bool = Field(True, description="Category active status")


class CategoryUpdateRequest(BaseModel):
    """Request schema for updating a category."""
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="Category name")
    description: Optional[str] = Field(None, max_length=500, description="Category description")
    display_order: Optional[int] = Field(None, ge=0, description="Display order for sorting")
    is_active: Optional[bool] = Field(None, description="Category active status")


class CategoryDetailResponse(BaseModel):
    """Detailed category response schema for admin."""
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    name: str
    description: Optional[str] = None
    icon_url: Optional[str] = None
    display_order: int
    is_active: bool
    created_at: datetime
    service_count: int = 0


class CategoryListResponse(BaseModel):
    """Paginated category list response."""
    categories: List[CategoryDetailResponse]
    total: int
    page: int
    limit: int
    has_more: bool
    total_pages: int
