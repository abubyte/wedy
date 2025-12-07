from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging

from app.core.config import settings
from app.core.database import create_db_and_tables, close_db_connection
from app.core.exceptions import WedyException, map_exception_to_http
from app.api.v1 import auth, categories, users, services, merchants, merchants_cover_image, merchants_gallery, merchants_contacts, payments, reviews, tariffs, payme_merchant

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan management.
    
    This function handles startup and shutdown events for the FastAPI application.
    """
    # Startup
    logger.info("Starting up Wedy API...")
    
    # Create database tables
    await create_db_and_tables()
    logger.info("Database tables created successfully")
    
    yield
    
    # Shutdown
    logger.info("Shutting down Wedy API...")
    await close_db_connection()
    logger.info("Database connection closed")


# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Wedy Platform API for Uzbekistan",
    lifespan=lifespan,
    # Enable docs when in DEBUG or when explicitly allowed via ENABLE_DOCS
    docs_url="/docs" if (settings.DEBUG or settings.ENABLE_DOCS) else None,
    redoc_url="/redoc" if (settings.DEBUG or settings.ENABLE_DOCS) else None,
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Global exception handler for custom exceptions
@app.exception_handler(WedyException)
async def wedy_exception_handler(
    request: Request, 
    exc: WedyException
) -> JSONResponse:
    """
    Handle custom Wedy exceptions.
    
    Args:
        request: The HTTP request
        exc: The custom exception
        
    Returns:
        JSONResponse: Formatted error response
    """
    http_exc = map_exception_to_http(exc)
    return JSONResponse(
        status_code=http_exc.status_code,
        content={
            "error": {
                "message": exc.message,
                "details": exc.details,
                "type": exc.__class__.__name__
            }
        }
    )


# Global exception handler for HTTP exceptions
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """
    Handle FastAPI HTTP exceptions.
    
    Args:
        request: The HTTP request
        exc: The HTTP exception
        
    Returns:
        JSONResponse: Formatted error response
    """
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "message": exc.detail,
                "type": "HTTPException"
            }
        }
    )


# Health check endpoint
@app.get("/health", include_in_schema=False)
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "app_name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": "development" if settings.DEBUG else "production"
    }


# Root endpoint
@app.get("/", include_in_schema=False)
async def root():
    """Root endpoint with API information."""
    return {
        "message": "Wedy API",
        "version": settings.APP_VERSION,
        "docs": "/docs" if settings.DEBUG else None,
        "description": "Wedy Platform API for Uzbekistan"
    }


# Include API routers
app.include_router(
    auth.router,
    prefix=settings.API_V1_STR + "/auth",
    tags=["Authentication"]
)

app.include_router(
    users.router,
    prefix=settings.API_V1_STR + "/users",
    tags=["Users"]
)

app.include_router(
    merchants.router,
    prefix=settings.API_V1_STR + "/merchants",
    tags=["Merchants"]
)

app.include_router(
    merchants_cover_image.router,
    prefix=settings.API_V1_STR + "/merchants",
    tags=["Merchants Cover Image"]
)

app.include_router(
    merchants_gallery.router,
    prefix=settings.API_V1_STR + "/merchants",
    tags=["Merchants Gallery"]
)

app.include_router(
    merchants_contacts.router,
    prefix=settings.API_V1_STR + "/merchants",
    tags=["Merchants Contacts"]
)

app.include_router(
    tariffs.router,
    prefix=settings.API_V1_STR + "/tariffs",
    tags=["Tariffs"]
)

app.include_router(
    payments.router,
    prefix=settings.API_V1_STR + "/payments",
    tags=["Payments"]
)

app.include_router(
    categories.router,
    prefix=settings.API_V1_STR + "/categories",
    tags=["Categories"]
)

app.include_router(
    services.router,
    prefix=settings.API_V1_STR + "/services",
    tags=["Services"]
)

app.include_router(
    reviews.router,
    prefix=settings.API_V1_STR + "/reviews",
    tags=["Reviews"]
)

app.include_router(
    payme_merchant.router,
    prefix=settings.API_V1_STR,
    tags=["Payme Merchant API"]
)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG
    )