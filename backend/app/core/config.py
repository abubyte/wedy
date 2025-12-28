from functools import lru_cache
from typing import List, Union, Optional
from pydantic import Field, field_validator

try:
    from pydantic_settings import BaseSettings, SettingsConfigDict
    HAS_PYDANTIC_SETTINGS = True
except ImportError:
    try:
        from pydantic.v1 import BaseSettings
        # For pydantic v1, we'll use class Config instead
        SettingsConfigDict = None
        HAS_PYDANTIC_SETTINGS = False
    except ImportError:
        raise ImportError(
            "Either 'pydantic-settings' or 'pydantic' must be installed. "
            "Install with: pip install pydantic-settings"
        )


class Settings(BaseSettings):
    # Application
    DEBUG: bool = True
    APP_NAME: str = "Wedy API"
    APP_VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    BASE_URL: str = "https://api.wedy.uz"

    # Application Constants
    OTP_EXPIRE_MINUTES: int = 5
    OTP_MAX_ATTEMPTS: int = 5
    PHONE_NUMBER_LENGTH: int = 9

    # CORS
    CORS_ORIGINS: Union[str, List[str]] = ["http://localhost:8000"] #

    # Documentation
    ENABLE_DOCS: bool = True  # Enable docs in development (set to False in production via env var)

    # Database
    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 10
    DATABASE_MAX_OVERFLOW: int = 20
    REDIS_URL: str = "redis://localhost:6379/0"

    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30 

    # SMS Service
    ESKIZ_BASE_URL: str = "https://notify.eskiz.uz/api"
    ESKIZ_EMAIL: str
    ESKIZ_PASSWORD: str

    # AWS S3
    AWS_ACCESS_KEY_ID: str
    AWS_SECRET_ACCESS_KEY: str
    AWS_BUCKET_NAME: str
    AWS_REGION: str = "eu-north-1"

    # Payment Providers
    PAYME_TARIFF_SECRET_KEY: Optional[str] = None
    PAYME_TARIFF_MERCHANT_ID: Optional[str] = None
    PAYME_SERVICE_BOOST_SECRET_KEY: Optional[str] = None
    PAYME_SERVICE_BOOST_MERCHANT_ID: Optional[str] = None
    PAYME_SANDBOX_SECRET_KEY: Optional[str] = None  # For Payme Sandbox testing - get from Payme Sandbox dashboard
    PAYME_API_URL: str = "https://checkout.paycom.uz"
    PAYME_TEST_API_URL: str = "https://test.paycom.uz"

    CLICK_SECRET_KEY: Optional[str] = None
    CLICK_MERCHANT_ID: Optional[str] = None
    CLICK_SERVICE_ID: Optional[str] = None
    CLICK_API_URL: str = "https://api.click.uz/v2/merchant"
    CLICK_TEST_API_URL: str = "https://api.click.uz/v2/merchant"

    # UZUMBANK_SECRET_KEY: str
    # UZUMBANK_MERCHANT_ID: str
    UZUMBANK_API_URL: str = "https://api.uzumbank.uz"
    UZUMBANK_TEST_API_URL: str = "https://api.uzumbank.uz"

    # Deep Links / Universal Links
    ANDROID_PACKAGE_NAME: str = "uz.wedy.app"
    ANDROID_SHA256_FINGERPRINT: Optional[str] = None  # Get from: keytool -list -v -keystore <keystore> -alias <alias>
    IOS_TEAM_ID: Optional[str] = None  # Apple Developer Team ID
    IOS_BUNDLE_ID: str = "uz.wedy.app"

    # Pydantic configuration
    if HAS_PYDANTIC_SETTINGS:
        model_config = SettingsConfigDict(
            env_file=".env",
            env_file_encoding="utf-8",
            case_sensitive=True,
            extra="ignore"
        )
    else:
        # Pydantic v1 configuration
        class Config:
            env_file = ".env"
            env_file_encoding = "utf-8"
            case_sensitive = True
            extra = "ignore"


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()

