from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from jose import jwt, JWTError
from passlib.context import CryptContext

from app.core.config import settings


# Password hashing context (for future use if needed)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def create_access_token(
    subject: str, 
    expires_delta: Optional[timedelta] = None,
    additional_claims: Optional[Dict[str, Any]] = None
) -> str:
    """
    Create a JWT access token.
    
    Args:
        subject: The subject (usually user ID) for the token
        expires_delta: Custom expiration time
        additional_claims: Additional data to include in token
        
    Returns:
        str: Encoded JWT token
    """
    if expires_delta:
        expire = datetime.now() + expires_delta
    else:
        expire = datetime.now() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    
    to_encode = {
        "exp": expire,
        "sub": str(subject),
        "type": "access"
    }
    
    if additional_claims:
        to_encode.update(additional_claims)
    
    encoded_jwt = jwt.encode(
        to_encode, 
        settings.SECRET_KEY, 
        algorithm=settings.ALGORITHM
    )
    return encoded_jwt


def create_refresh_token(subject: str) -> str:
    """
    Create a JWT refresh token.
    
    Args:
        subject: The subject (usually user ID) for the token
        
    Returns:
        str: Encoded JWT refresh token
    """
    expire = datetime.now() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    
    to_encode = {
        "exp": expire,
        "sub": str(subject),
        "type": "refresh"
    }
    
    encoded_jwt = jwt.encode(
        to_encode, 
        settings.SECRET_KEY, 
        algorithm=settings.ALGORITHM
    )
    return encoded_jwt


def verify_token(token: str) -> Optional[Dict[str, Any]]:
    """
    Verify and decode a JWT token.
    
    Args:
        token: JWT token to verify
        
    Returns:
        Optional[Dict[str, Any]]: Decoded token payload or None if invalid
    """
    try:
        payload = jwt.decode(
            token, 
            settings.SECRET_KEY, 
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError:
        return None


def get_subject_from_token(token: str) -> Optional[str]:
    """
    Extract subject (user ID) from JWT token.
    
    Args:
        token: JWT token
        
    Returns:
        Optional[str]: User ID or None if invalid token
    """
    payload = verify_token(token)
    if payload and "sub" in payload:
        return payload["sub"]
    return None


def verify_phone_number(phone: str) -> bool:
    """
    Verify Uzbekistan phone number format.
    
    Args:
        phone: Phone number to verify
        
    Returns:
        bool: True if valid Uzbekistan phone number
    """
    # Remove any non-digit characters
    cleaned_phone = ''.join(filter(str.isdigit, phone))
    
    # Check if it's 9 digits (Uzbekistan format without country code)
    if len(cleaned_phone) == settings.PHONE_NUMBER_LENGTH:
        return True
    
    # Check if it starts with 998 (country code) + 9 digits
    if len(cleaned_phone) == 12 and cleaned_phone.startswith('998'):
        return True
    
    return False


def normalize_phone_number(phone: str) -> str:
    """
    Normalize phone number to standard format (9 digits).
    
    Args:
        phone: Phone number to normalize
        
    Returns:
        str: Normalized phone number (9 digits)
    """
    # Remove any non-digit characters
    cleaned_phone = ''.join(filter(str.isdigit, phone))
    
    # If it starts with country code 998, remove it
    if cleaned_phone.startswith('998') and len(cleaned_phone) == 12:
        return cleaned_phone[3:]
    
    # Return last 9 digits
    return cleaned_phone[-9:]


def hash_password(password: str) -> str:
    """
    Hash a password using bcrypt.
    
    Args:
        password: Plain text password
        
    Returns:
        str: Hashed password
    """
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a password against its hash.
    
    Args:
        plain_password: Plain text password
        hashed_password: Hashed password
        
    Returns:
        bool: True if password matches
    """
    return pwd_context.verify(plain_password, hashed_password)