import math
from typing import Optional

from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from app.models.enums import KycStatus
from app.models.user import User
from app.models.worker_profile import WorkerProfile


def get_by_user(db: Session, user_id: int) -> Optional[WorkerProfile]:
    return db.scalar(
        select(WorkerProfile)
        .options(joinedload(WorkerProfile.category))
        .where(WorkerProfile.user_id == user_id)
    )


def get_or_create(db: Session, user_id: int) -> WorkerProfile:
    profile = get_by_user(db, user_id)
    if profile is None:
        profile = WorkerProfile(user_id=user_id)
        db.add(profile)
        db.flush()
    return profile


def search(
    db: Session,
    *,
    category_id: Optional[int] = None,
    query: Optional[str] = None,
    available_only: bool = True,
    lat: Optional[float] = None,
    lng: Optional[float] = None,
    skip: int = 0,
    limit: int = 50,
) -> list[tuple[WorkerProfile, User]]:
    stmt = (
        select(WorkerProfile, User)
        .join(User, User.id == WorkerProfile.user_id)
        .options(joinedload(WorkerProfile.category))
        .where(
            User.is_active.is_(True),
            WorkerProfile.is_verified.is_(True),
            WorkerProfile.is_suspended.is_(False),
        )
    )
    if category_id is not None:
        stmt = stmt.where(WorkerProfile.category_id == category_id)
    if available_only:
        stmt = stmt.where(WorkerProfile.is_available.is_(True))
    if query:
        stmt = stmt.where(User.name.ilike(f"%{query}%"))

    stmt = stmt.order_by(WorkerProfile.rating.desc()).offset(skip).limit(limit)
    rows = list(db.execute(stmt).all())
    return [(row[0], row[1]) for row in rows]


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371.0
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lng / 2) ** 2
    )
    return round(r * 2 * math.asin(math.sqrt(a)), 1)


def recalc_rating(db: Session, worker_user_id: int) -> None:
    """Recompute a worker's average rating from completed bookings' reviews."""
    from app.models.booking import Booking
    from app.models.review import Review

    rows = db.execute(
        select(Review.rating)
        .join(Booking, Booking.id == Review.booking_id)
        .where(Booking.worker_id == worker_user_id, Review.is_hidden.is_(False))
    ).all()
    ratings = [r[0] for r in rows]
    profile = get_by_user(db, worker_user_id)
    if profile is None:
        return
    if ratings:
        profile.rating = round(sum(ratings) / len(ratings), 2)
        profile.rating_count = len(ratings)
    else:
        profile.rating = 0.0
        profile.rating_count = 0
    db.add(profile)
    db.flush()
