from functools import lru_cache
from typing import List, Union
from pydantic import Field, validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # =========================
    # Application
    # =========================
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    APP_NAME: str = "Wedy API"
    APP_VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"

    # =========================
    # CORS
    # =========================
    CORS_ORIGINS: Union[str, List[str]] = ["http://localhost:3000"]

    @validator("CORS_ORIGINS", pre=True)
    def assemble_cors_origins(cls, v):
        if isinstance(v, str) and v.startswith("["):
            # if it comes from .env as JSON-like string
            import json
            return json.loads(v)
        if isinstance(v, str):
            return [i.strip() for i in v.split(",")]
        return v

    # =========================
    # Database
    # =========================
    DATABASE_URL: str = Field(..., description="PostgreSQL database URL")
    TEST_DATABASE_URL: str = Field(
        default="", description="PostgreSQL test database URL"
    )
    DATABASE_POOL_SIZE: int = 15
    DATABASE_MAX_OVERFLOW: int = 0

    # =========================
    # Redis
    # =========================
    REDIS_URL: str = "redis://localhost:6379/0"

    # =========================
    # Security
    # =========================
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # =========================
    # SMS Service
    # =========================
    SMS_BASE_URL: str = "https://notify.eskiz.uz/api"
    SMS_EMAIL: str = ""
    SMS_PASSWORD: str = ""

    # =========================
    # AWS S3
    # =========================
    AWS_ACCESS_KEY_ID: str
    AWS_SECRET_ACCESS_KEY: str
    AWS_BUCKET_NAME: str
    AWS_REGION: str = "us-east-1"

    # =========================
    # Payment Providers (optional)
    # =========================
    PAYME_MERCHANT_ID: str = ""
    PAYME_SECRET_KEY: str = ""
    PAYME_TEST_MODE: bool = False
    PAYME_CALLBACK_URL: str = ""
    PAYME_API_URL: str = "https://checkout.paycom.uz"
    PAYME_TEST_API_URL: str = "https://test.paycom.uz"

    CLICK_MERCHANT_ID: str = ""
    CLICK_SECRET_KEY: str = ""

    UZUMBANK_MERCHANT_ID: str = ""
    UZUMBANK_SECRET_KEY: str = ""

    # =========================
    # Application Constants
    # =========================
    OTP_EXPIRE_MINUTES: int = 5
    OTP_MAX_ATTEMPTS: int = 5
    MAX_FILE_SIZE: int = 5 * 1024 * 1024  # 5MB
    ALLOWED_IMAGE_TYPES: List[str] = ["image/jpeg", "image/png"]
    RATE_LIMIT_PER_MINUTE: int = 100
    RATE_LIMIT_PER_HOUR: int = 1000
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100
    FEATURED_SERVICE_PRICE_PER_DAY: int = 5000

    # =========================
    # Default Regions
    # =========================
    DEFAULT_REGIONS: List[str] = [
        "Tashkent", "Samarkand", "Bukhara", "Andijan", "Ferghana",
        "Namangan", "Kashkadarya", "Surkhandarya", "Khorezm",
        "Navoiy", "Jizzakh", "Sirdarya", "Karakalpakstan"
    ]

    # =========================
    # Documentation
    # =========================
    ENABLE_DOCS: bool = True
    ENABLE_REDOC: bool = True

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True
        extra = "ignore"  # Ignore extra environment variables


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
