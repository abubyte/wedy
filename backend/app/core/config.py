from functools import lru_cache
from typing import List, Union
from pydantic import Field, validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # =========================
    # Application
    # =========================
    DEBUG: bool = True
    APP_NAME: str = "Wedy API"
    APP_VERSION: str = "1.0.0"
    API_VERSION_STR: str = "/api/v1" #

    # =========================
    # CORS
    # =========================
    CORS_ORIGINS: Union[str, List[str]] = ["http://localhost:3000"] #

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
    DATABASE_URL: str = Field(..., description="PostgreSQL database URL") #
    TEST_DATABASE_URL: str = Field(
        default="", description="PostgreSQL test database URL" #
    )
    DATABASE_POOL_SIZE: int = 15 #
    DATABASE_MAX_OVERFLOW: int = 0 #

    # =========================
    # Redis
    # =========================
    REDIS_URL: str = "redis://localhost:6379/0" #

    # =========================
    # Security
    # =========================
    SECRET_KEY: str #
    ALGORITHM: str = "HS256" #
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15 #
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30 #

    # =========================
    # SMS Service
    # =========================
    ESKIZ_BASE_URL: str = "https://notify.eskiz.uz/api"
    ESKIZ_EMAIL: str = ""
    ESKIZ_PASSWORD: str = ""

    # =========================
    # AWS S3
    # =========================
    AWS_ACCESS_KEY_ID: str #
    AWS_SECRET_ACCESS_KEY: str #
    AWS_BUCKET_NAME: str #
    AWS_REGION: str = "us-east-1" #

    # =========================
    # Payment Providers (optional)
    # =========================
    PAYME_SECRET_KEY: str = "" #
    PAYME_API_URL: str = "https://checkout.paycom.uz" #
    PAYME_TEST_API_URL: str = "https://test.paycom.uz" #

    CLICK_SECRET_KEY: str = "" #
    CLICK_API_URL: str = "https://api.click.uz/v2/merchant" #
    CLICK_TEST_API_URL: str = "https://api.click.uz/v2/merchant" #

    UZUMBANK_SECRET_KEY: str = "" #
    UZUMBANK_API_URL: str = "https://api.uzumbank.uz" #
    UZUMBANK_TEST_API_URL: str = "https://api.uzumbank.uz" #
    
    # Base URL for payment callbacks
    BASE_URL: str = "http://api.abubyte.uz"

    # =========================
    # Application Constants
    # =========================
    OTP_EXPIRE_MINUTES: int = 5
    OTP_MAX_ATTEMPTS: int = 5
    PHONE_NUMBER_LENGTH: int = 9

    # =========================
    # Documentation
    # =========================
    ENABLE_DOCS: bool = True #
    ENABLE_REDOC: bool = True #

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True
        extra = "ignore"  # Ignore extra environment variables


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
