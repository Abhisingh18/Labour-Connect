from functools import lru_cache
from typing import List

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # App
    PROJECT_NAME: str = "Labour Connect API"
    API_V1_PREFIX: str = "/api/v1"
    ENVIRONMENT: str = "development"

    # Security
    SECRET_KEY: str = "change-me"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Rate limiting / lockout
    OTP_SEND_MAX_PER_WINDOW: int = 5      # max send-otp per phone per window
    OTP_SEND_WINDOW_SECONDS: int = 900    # 15 min
    OTP_MAX_FAILED_ATTEMPTS: int = 5      # failed verifies before lockout
    LOCKOUT_SECONDS: int = 900            # 15 min lockout
    LOGIN_MAX_PER_WINDOW: int = 10        # admin login attempts per ip+email
    LOGIN_WINDOW_SECONDS: int = 900

    # File uploads
    UPLOAD_DIR: str = "uploads"
    UPLOAD_MAX_BYTES: int = 5 * 1024 * 1024  # 5 MB

    # Database
    POSTGRES_USER: str = "labour"
    POSTGRES_PASSWORD: str = "labour"
    POSTGRES_DB: str = "labour_connect"
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    # Optional full override (e.g. sqlite:///./labour.db for local dev without Postgres).
    # When set, takes precedence over the POSTGRES_* settings above.
    DATABASE_URL: str = ""

    # OTP
    OTP_MOCK: bool = True
    DEV_OTP_CODE: str = "123456"
    OTP_EXPIRE_MINUTES: int = 5

    # First admin
    FIRST_ADMIN_EMAIL: str = "admin@labourconnect.in"
    FIRST_ADMIN_PASSWORD: str = "Admin@123"
    FIRST_ADMIN_NAME: str = "Super Admin"

    # CORS — comma-separated list of allowed origins.
    BACKEND_CORS_ORIGINS: str = "http://localhost:3000,http://localhost:5173"

    @property
    def cors_origins(self) -> List[str]:
        return [o.strip() for o in self.BACKEND_CORS_ORIGINS.split(",") if o.strip()]

    @property
    def database_url(self) -> str:
        if self.DATABASE_URL:
            url = self.DATABASE_URL
            # Managed hosts (Render/Heroku/Railway) hand out "postgres://" URLs;
            # SQLAlchemy needs an explicit driver.
            if url.startswith("postgres://"):
                url = url.replace("postgres://", "postgresql+psycopg2://", 1)
            elif url.startswith("postgresql://"):
                url = url.replace("postgresql://", "postgresql+psycopg2://", 1)
            return url
        return (
            f"postgresql+psycopg2://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
