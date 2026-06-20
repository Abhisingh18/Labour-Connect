from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.sanitize import clean_text


class CategoryBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=120)
    icon: Optional[str] = None
    is_active: bool = True

    @field_validator("name")
    @classmethod
    def _clean_name(cls, v):
        return clean_text(v)


class CategoryCreate(CategoryBase):
    pass


class CategoryUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=120)
    icon: Optional[str] = None
    is_active: Optional[bool] = None

    @field_validator("name")
    @classmethod
    def _clean_name(cls, v):
        return clean_text(v)


class CategoryOut(CategoryBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
