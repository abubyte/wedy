from functools import lru_cache
from typing import List, Optional
from pydantic import Field, validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Application
    APP_NAME: str = "Wedy API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    API_V1_STR: str = "/api/v1"
    
    # CORS
    CORS_ORIGINS: List[str] = ["http://localhost:3000"]
    
    @validator("CORS_ORIGINS", pre=True)
    def assemble_cors_origins(cls, v):
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)
    
    # Database
    DATABASE_URL: str = Field(
        ..., 
        description="PostgreSQL database URL"
    )
    DATABASE_POOL_SIZE: int = 15
    DATABASE_MAX_OVERFLOW: int = 0
    
    # Redis
    REDIS_URL: str = Field(
        default="redis://localhost:6379/0",
        description="Redis connection URL"
    )
    
    # Security
    SECRET_KEY: str = Field(
        ..., 
        description="JWT secret key for token signing"
    )
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    
    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 100
    RATE_LIMIT_PER_HOUR: int = 1000
    
    # External Services
    # SMS Service (eskiz.uz)
    SMS_API_KEY: str = Field(
        ..., 
        description="eskiz.uz API key for SMS service"
    )
    SMS_BASE_URL: str = "https://notify.eskiz.uz/api"
    
    # AWS S3
    AWS_ACCESS_KEY_ID: str = Field(
        ..., 
        description="AWS access key for S3"
    )
    AWS_SECRET_ACCESS_KEY: str = Field(
        ..., 
        description="AWS secret key for S3"
    )
    AWS_BUCKET_NAME: str = Field(
        ..., 
        description="S3 bucket name for file storage"
    )
    AWS_REGION: str = "us-east-1"
    
    # Payment Providers
    # Payme
    PAYME_MERCHANT_ID: str = Field(
        ..., 
        description="Payme merchant ID"
    )
    PAYME_SECRET_KEY: str = Field(
        ..., 
        description="Payme secret key"
    )
    PAYME_BASE_URL: str = "https://checkout.paycom.uz/api"
    
    # Click
    CLICK_MERCHANT_ID: str = Field(
        ..., 
        description="Click merchant ID"
    )
    CLICK_SECRET_KEY: str = Field(
        ..., 
        description="Click secret key"
    )
    CLICK_BASE_URL: str = "https://api.click.uz/v2"
    
    # UzumBank
    UZUMBANK_MERCHANT_ID: str = Field(
        ..., 
        description="UzumBank merchant ID"
    )
    UZUMBANK_SECRET_KEY: str = Field(
        ..., 
        description="UzumBank secret key"
    )
    UZUMBANK_BASE_URL: str = "https://api.uzumbank.uz/v1"
    
    # File Upload
    MAX_FILE_SIZE: int = 5 * 1024 * 1024  # 5MB
    ALLOWED_IMAGE_TYPES: List[str] = ["image/jpeg", "image/png"]
    
    # Uzbekistan Regions (for location filtering)
    UZBEKISTAN_REGIONS: List[str] = [
        "Tashkent", "Samarkand", "Bukhara", "Andijan", "Ferghana", 
        "Namangan", "Kashkadarya", "Surkhandarya", "Khorezm", 
        "Navoiy", "Jizzakh", "Sirdarya", "Karakalpakstan"
    ]
    
    # Business Logic
    OTP_EXPIRE_MINUTES: int = 5
    OTP_MAX_ATTEMPTS: int = 5
    PHONE_NUMBER_LENGTH: int = 9  # Uzbekistan phone numbers (without country code)
    
    # Featured Service Pricing (UZS per day)
    FEATURED_SERVICE_PRICE_PER_DAY: int = 5000  # 5000 UZS per day
    
    # Pagination
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


# Global settings instance
settings = get_settings()