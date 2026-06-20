from datetime import date, datetime, time
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.sanitize import clean_text
from app.models.enums import BookingStatus
from app.schemas.category import CategoryOut
from app.schemas.review import ReviewOut


class BookingCreate(BaseModel):
    worker_id: int
    category_id: Optional[int] = None
    booking_date: date
    booking_time: Optional[time] = None
    address: str = Field(..., min_length=1, max_length=500)
    notes: Optional[str] = Field(None, max_length=1000)

    @field_validator("address", "notes")
    @classmethod
    def _clean(cls, v):
        return clean_text(v)


class JobRequestCreate(BaseModel):
    """Customer posts an open job (no specific worker; admin approves)."""

    category_id: int
    booking_date: date
    booking_time: Optional[time] = None
    address: str = Field(..., min_length=1, max_length=500)
    notes: Optional[str] = Field(None, max_length=1000)

    @field_validator("address", "notes")
    @classmethod
    def _clean(cls, v):
        return clean_text(v)


class JobApprove(BaseModel):
    amount: float = Field(..., ge=0)


class BookingStatusUpdate(BaseModel):
    status: BookingStatus
    amount: Optional[float] = None


class BookingPartyOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    phone: Optional[str] = None
    profile_image: Optional[str] = None


class BookingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    customer_id: int
    worker_id: Optional[int] = None
    category_id: Optional[int] = None
    booking_date: date
    booking_time: Optional[time] = None
    address: str
    notes: Optional[str] = None
    status: BookingStatus
    amount: float
    is_open_request: bool = False
    created_at: datetime

    customer: Optional[BookingPartyOut] = None
    worker: Optional[BookingPartyOut] = None
    category: Optional[CategoryOut] = None
    review: Optional[ReviewOut] = None
