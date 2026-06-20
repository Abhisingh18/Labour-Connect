from typing import Optional

from sqlalchemy import Boolean, Enum, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base, TimestampMixin
from app.models.enums import KycStatus


class WorkerProfile(Base, TimestampMixin):
    __tablename__ = "worker_profiles"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    category_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL"), nullable=True, index=True
    )
    experience: Mapped[int] = mapped_column(Integer, default=0, nullable=False)  # years
    bio: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True)
    service_area: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    # geo (for nearby search)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)

    # KYC documents
    aadhaar_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    pan_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    selfie_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    kyc_status: Mapped[KycStatus] = mapped_column(
        Enum(KycStatus), default=KycStatus.not_submitted, nullable=False
    )

    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_available: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_suspended: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    rating: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    rating_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    user: Mapped["User"] = relationship(back_populates="worker_profile")
    category: Mapped[Optional["Category"]] = relationship()
