from typing import Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.booking import Booking
from app.models.review import Review
from app.schemas.review import ReviewCreate


def get_by_booking(db: Session, booking_id: int) -> Optional[Review]:
    return db.scalar(select(Review).where(Review.booking_id == booking_id))


def get(db: Session, review_id: int) -> Optional[Review]:
    return db.get(Review, review_id)


def create(db: Session, booking_id: int, data: ReviewCreate) -> Review:
    review = Review(booking_id=booking_id, rating=data.rating, comment=data.comment)
    db.add(review)
    db.flush()
    return review


def list_for_worker(db: Session, worker_user_id: int) -> list[Review]:
    stmt = (
        select(Review)
        .join(Booking, Booking.id == Review.booking_id)
        .where(Booking.worker_id == worker_user_id, Review.is_hidden.is_(False))
        .order_by(Review.created_at.desc())
    )
    return list(db.scalars(stmt))


def list_all(db: Session, skip: int = 0, limit: int = 100) -> list[Review]:
    stmt = select(Review).order_by(Review.created_at.desc()).offset(skip).limit(limit)
    return list(db.scalars(stmt))


def set_hidden(db: Session, review: Review, hidden: bool) -> Review:
    review.is_hidden = hidden
    db.add(review)
    db.flush()
    return review
