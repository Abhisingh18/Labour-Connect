from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.sanitize import clean_text
from app.models.enums import KycStatus
from app.schemas.category import CategoryOut


class WorkerProfileUpdate(BaseModel):
    category_id: Optional[int] = None
    experience: Optional[int] = Field(None, ge=0, le=70)
    bio: Optional[str] = Field(None, max_length=1000)
    service_area: Optional[str] = Field(None, max_length=255)
    latitude: Optional[float] = None
    longitude: Optional[float] = None

    @field_validator("bio", "service_area")
    @classmethod
    def _clean(cls, v):
        return clean_text(v)


class KycSubmit(BaseModel):
    aadhaar_url: Optional[str] = None
    pan_url: Optional[str] = None
    selfie_url: Optional[str] = None


class AvailabilityUpdate(BaseModel):
    is_available: bool


class WorkerProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    category_id: Optional[int] = None
    experience: int
    bio: Optional[str] = None
    service_area: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    kyc_status: KycStatus
    is_verified: bool
    is_available: bool
    is_suspended: bool
    rating: float
    rating_count: int
    category: Optional[CategoryOut] = None


class WorkerListItem(BaseModel):
    """Public-facing worker card for customer listings."""

    user_id: int
    name: str
    profile_image: Optional[str] = None
    category: Optional[CategoryOut] = None
    experience: int
    rating: float
    rating_count: int
    is_available: bool
    service_area: Optional[str] = None
    distance_km: Optional[float] = None


class WorkerPublicDetail(WorkerListItem):
    bio: Optional[str] = None
    phone: Optional[str] = None
