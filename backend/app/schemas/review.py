from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.sanitize import clean_text


class ReviewCreate(BaseModel):
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = Field(None, max_length=1000)

    @field_validator("comment")
    @classmethod
    def _clean_comment(cls, v):
        return clean_text(v)


class ReviewOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    booking_id: int
    rating: int
    comment: Optional[str] = None
    is_hidden: bool
    created_at: datetime


class ReviewWithContext(ReviewOut):
    customer_name: Optional[str] = None
    worker_name: Optional[str] = None
