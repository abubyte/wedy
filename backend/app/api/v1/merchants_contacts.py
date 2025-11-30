from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db_session
from app.api.deps import get_current_merchant_user
from app.models import User
from app.schemas.merchant_schema import MerchantContactResponse, MerchantContactRequest, MerchantContactUpdateRequest
from app.core.exceptions import NotFoundError, PaymentRequiredError, ForbiddenError
from app.services.merchant_manager import MerchantManager
from app.schemas.common_schema import SuccessResponse
from typing import List
from uuid import UUID

router = APIRouter()


@router.get("/contacts", response_model=List[MerchantContactResponse])
async def get_merchant_contacts(
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Get all merchant contacts.
    
    Args:
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        List[MerchantContactResponse]: Merchant contacts
    """
    try:
        merchant_manager = MerchantManager(db)
        return await merchant_manager.get_merchant_contacts(current_user.id)
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.post("/contacts", response_model=MerchantContactResponse)
async def add_merchant_contact(
    contact_data: MerchantContactRequest,
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Add merchant contact with tariff limit validation.
    
    Args:
        contact_data: Contact data
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        MerchantContactResponse: Created contact
    """
    try:
        merchant_manager = MerchantManager(db)
        return await merchant_manager.add_merchant_contact(current_user.id, contact_data)
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except PaymentRequiredError as e:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=str(e)
        )
    except ForbiddenError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )


@router.put("/contacts/{contact_id}", response_model=MerchantContactResponse)
async def update_merchant_contact(
    contact_id: UUID,
    contact_data: MerchantContactUpdateRequest,
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Update merchant contact.
    
    Args:
        contact_id: UUID of the contact to update
        contact_data: Contact update data
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        MerchantContactResponse: Updated contact
    """
    try:
        merchant_manager = MerchantManager(db)
        merchant_repo = merchant_manager.merchant_repo
        
        # Get merchant
        merchant = await merchant_repo.get_merchant_by_user_id(current_user.id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        # Get contact and verify ownership
        contact = await merchant_repo.get_contact_by_id(contact_id, merchant.id)
        if not contact:
            raise NotFoundError("Contact not found or does not belong to merchant")
        
        # Update contact fields
        if contact_data.contact_value is not None:
            contact.contact_value = contact_data.contact_value
        if contact_data.platform_name is not None:
            contact.platform_name = contact_data.platform_name
        if contact_data.display_order is not None:
            contact.display_order = contact_data.display_order
        
        # Save updates
        updated_contact = await merchant_repo.update_contact(contact)
        
        return MerchantContactResponse(
            id=updated_contact.id,
            contact_type=updated_contact.contact_type,
            contact_value=updated_contact.contact_value,
            platform_name=updated_contact.platform_name,
            display_order=updated_contact.display_order,
            is_active=updated_contact.is_active,
            created_at=updated_contact.created_at
        )
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update contact: {str(e)}"
        )


@router.delete("/contacts/{contact_id}", response_model=SuccessResponse)
async def remove_merchant_contact(
    contact_id: UUID,
    current_user: User = Depends(get_current_merchant_user),
    db: AsyncSession = Depends(get_db_session)
):
    """
    Delete merchant contact (soft delete by deactivating).
    
    Args:
        contact_id: UUID of the contact to delete
        current_user: Current authenticated merchant user
        db: Database session
        
    Returns:
        SuccessResponse: Confirmation of deletion
    """
    try:
        merchant_manager = MerchantManager(db)
        merchant_repo = merchant_manager.merchant_repo
        
        # Get merchant
        merchant = await merchant_repo.get_merchant_by_user_id(current_user.id)
        if not merchant:
            raise NotFoundError("Merchant profile not found")
        
        # Get contact and verify ownership
        contact = await merchant_repo.get_contact_by_id(contact_id, merchant.id)
        if not contact:
            raise NotFoundError("Contact not found or does not belong to merchant")
        
        # Delete contact (soft delete)
        deleted = await merchant_repo.delete_contact(contact_id)
        
        if not deleted:
            raise NotFoundError("Contact not found")
        
        return SuccessResponse(
            success=True,
            message="Contact deleted successfully"
        )
    
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete contact: {str(e)}"
        )
