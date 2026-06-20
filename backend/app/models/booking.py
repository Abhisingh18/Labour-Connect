from datetime import date, time
from typing import Optional

from sqlalchemy import Boolean, Date, Enum, Float, ForeignKey, String, Time
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base_class import Base, TimestampMixin
from app.models.enums import BookingStatus


class Booking(Base, TimestampMixin):
    __tablename__ = "bookings"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    customer_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    worker_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    category_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL"), nullable=True
    )

    booking_date: Mapped[date] = mapped_column(Date, nullable=False)
    booking_time: Mapped[Optional[time]] = mapped_column(Time, nullable=True)
    address: Mapped[str] = mapped_column(String(500), nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True)
    status: Mapped[BookingStatus] = mapped_column(
        Enum(BookingStatus), default=BookingStatus.pending, nullable=False, index=True
    )
    amount: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    # True = open "posted job" (Labour-Chowk flow); False = direct worker booking.
    is_open_request: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    customer: Mapped["User"] = relationship(foreign_keys=[customer_id])
    worker: Mapped[Optional["User"]] = relationship(foreign_keys=[worker_id])
    category: Mapped[Optional["Category"]] = relationship()
    review: Mapped[Optional["Review"]] = relationship(
        back_populates="booking", uselist=False, cascade="all, delete-orphan"
    )
