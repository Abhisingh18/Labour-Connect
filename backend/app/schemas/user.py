from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr, field_validator

from app.core.sanitize import clean_text
from app.models.enums import UserRole


class UserBase(BaseModel):
    name: str
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    profile_image: Optional[str] = None


class UserUpdate(BaseModel):
    name: Optional[str] = None
    profile_image: Optional[str] = None
    email: Optional[EmailStr] = None

    @field_validator("name")
    @classmethod
    def _clean_name(cls, v):
        return clean_text(v)


class UserOut(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    role: UserRole
    is_active: bool
    created_at: datetime
