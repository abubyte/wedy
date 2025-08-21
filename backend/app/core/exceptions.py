from typing import Any, Dict, Optional
from fastapi import HTTPException, status


class WedyException(Exception):
    """Base exception for all custom exceptions."""
    
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        self.message = message
        self.details = details or {}
        super().__init__(self.message)


class ValidationError(WedyException):
    """Raised when data validation fails."""
    pass


class AuthenticationError(WedyException):
    """Raised when authentication fails."""
    pass


class AuthorizationError(WedyException):
    """Raised when user lacks required permissions."""
    pass


class NotFoundError(WedyException):
    """Raised when a requested resource is not found."""
    pass


class ConflictError(WedyException):
    """Raised when there's a conflict with existing data."""
    pass


class PaymentError(WedyException):
    """Raised when payment processing fails."""
    pass


class TariffLimitError(WedyException):
    """Raised when user exceeds tariff limits."""
    pass


class SMSError(WedyException):
    """Raised when SMS sending fails."""
    pass


class FileUploadError(WedyException):
    """Raised when file upload fails."""
    pass


# HTTP Exception Classes for FastAPI
class HTTPBadRequest(HTTPException):
    """400 Bad Request"""
    def __init__(self, detail: str = "Bad request"):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)


class HTTPUnauthorized(HTTPException):
    """401 Unauthorized"""
    def __init__(self, detail: str = "Authentication required"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            headers={"WWW-Authenticate": "Bearer"},
        )


class HTTPForbidden(HTTPException):
    """403 Forbidden"""
    def __init__(self, detail: str = "Insufficient permissions"):
        super().__init__(status_code=status.HTTP_403_FORBIDDEN, detail=detail)


class HTTPNotFound(HTTPException):
    """404 Not Found"""
    def __init__(self, detail: str = "Resource not found"):
        super().__init__(status_code=status.HTTP_404_NOT_FOUND, detail=detail)


class HTTPConflict(HTTPException):
    """409 Conflict"""
    def __init__(self, detail: str = "Resource conflict"):
        super().__init__(status_code=status.HTTP_409_CONFLICT, detail=detail)


class HTTPUnprocessableEntity(HTTPException):
    """422 Unprocessable Entity"""
    def __init__(self, detail: str = "Validation error"):
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, 
            detail=detail
        )


class HTTPTooManyRequests(HTTPException):
    """429 Too Many Requests"""
    def __init__(self, detail: str = "Rate limit exceeded"):
        super().__init__(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS, 
            detail=detail
        )


class HTTPInternalServerError(HTTPException):
    """500 Internal Server Error"""
    def __init__(self, detail: str = "Internal server error"):
        super().__init__(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=detail
        )


# Exception to HTTP Exception mapping
EXCEPTION_MAPPING = {
    ValidationError: HTTPUnprocessableEntity,
    AuthenticationError: HTTPUnauthorized,
    AuthorizationError: HTTPForbidden,
    NotFoundError: HTTPNotFound,
    ConflictError: HTTPConflict,
    PaymentError: HTTPBadRequest,
    TariffLimitError: HTTPForbidden,
    SMSError: HTTPInternalServerError,
    FileUploadError: HTTPBadRequest,
}


def map_exception_to_http(exc: WedyException) -> HTTPException:
    """
    Map custom exception to appropriate HTTP exception.
    
    Args:
        exc: Custom exception instance
        
    Returns:
        HTTPException: Appropriate HTTP exception
    """
    exception_class = EXCEPTION_MAPPING.get(type(exc), HTTPInternalServerError)
    return exception_class(detail=exc.message)