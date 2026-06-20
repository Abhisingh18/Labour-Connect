from typing import Optional

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.core.sanitize import clean_text
from app.models.enums import UserRole


class SendOtpRequest(BaseModel):
    phone: str = Field(..., min_length=8, max_length=20)


class SendOtpResponse(BaseModel):
    message: str
    # In mock mode we return the code so frontends/devs can test easily.
    dev_otp: Optional[str] = None


class VerifyOtpRequest(BaseModel):
    phone: str = Field(..., min_length=8, max_length=20)
    otp: str = Field(..., min_length=4, max_length=8)
    role: UserRole = UserRole.customer
    name: Optional[str] = None  # used on first-time signup

    @field_validator("name")
    @classmethod
    def _clean_name(cls, v):
        return clean_text(v)


class AdminLoginRequest(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    role: UserRole
    user_id: int
    is_new_user: bool = False


class RefreshRequest(BaseModel):
    refresh_token: str


class AccessToken(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class LogoutRequest(BaseModel):
    refresh_token: str
