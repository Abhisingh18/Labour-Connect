from typing import Optional

from sqlalchemy import select, update
from sqlalchemy.orm import Session, joinedload

from app.models.booking import Booking
from app.models.enums import BookingStatus
from app.schemas.booking import BookingCreate, JobRequestCreate

_LOADS = (
    joinedload(Booking.customer),
    joinedload(Booking.worker),
    joinedload(Booking.category),
    joinedload(Booking.review),
)


def get(db: Session, booking_id: int) -> Optional[Booking]:
    return db.scalar(select(Booking).options(*_LOADS).where(Booking.id == booking_id))


def create(db: Session, customer_id: int, data: BookingCreate) -> Booking:
    booking = Booking(
        customer_id=customer_id,
        worker_id=data.worker_id,
        category_id=data.category_id,
        booking_date=data.booking_date,
        booking_time=data.booking_time,
        address=data.address,
        notes=data.notes,
        status=BookingStatus.pending,
    )
    db.add(booking)
    db.flush()
    return get(db, booking.id)


def create_open_job(db: Session, customer_id: int, data: JobRequestCreate) -> Booking:
    booking = Booking(
        customer_id=customer_id,
        worker_id=None,
        category_id=data.category_id,
        booking_date=data.booking_date,
        booking_time=data.booking_time,
        address=data.address,
        notes=data.notes,
        status=BookingStatus.pending_approval,
        is_open_request=True,
    )
    db.add(booking)
    db.flush()
    return get(db, booking.id)


def list_open_jobs(db: Session, category_id: Optional[int] = None) -> list[Booking]:
    """Admin-approved open jobs visible to the worker pool."""
    stmt = (
        select(Booking)
        .options(*_LOADS)
        .where(
            Booking.status == BookingStatus.open,
            Booking.is_open_request.is_(True),
            Booking.worker_id.is_(None),
        )
    )
    if category_id is not None:
        stmt = stmt.where(Booking.category_id == category_id)
    return list(db.scalars(stmt.order_by(Booking.created_at.desc())))


def claim_open_job(db: Session, booking_id: int, worker_id: int) -> Optional[Booking]:
    """Atomically claim an open job; returns the booking or None if already taken."""
    result = db.execute(
        update(Booking)
        .where(
            Booking.id == booking_id,
            Booking.status == BookingStatus.open,
            Booking.worker_id.is_(None),
        )
        .values(worker_id=worker_id, status=BookingStatus.accepted)
    )
    if result.rowcount == 0:
        return None
    db.flush()
    return get(db, booking_id)


def list_for_customer(
    db: Session, customer_id: int, status: Optional[BookingStatus] = None
) -> list[Booking]:
    stmt = select(Booking).options(*_LOADS).where(Booking.customer_id == customer_id)
    if status:
        stmt = stmt.where(Booking.status == status)
    return list(db.scalars(stmt.order_by(Booking.created_at.desc())))


def list_for_worker(
    db: Session, worker_id: int, status: Optional[BookingStatus] = None
) -> list[Booking]:
    stmt = select(Booking).options(*_LOADS).where(Booking.worker_id == worker_id)
    if status:
        stmt = stmt.where(Booking.status == status)
    return list(db.scalars(stmt.order_by(Booking.created_at.desc())))


def list_all(
    db: Session, status: Optional[BookingStatus] = None, skip: int = 0, limit: int = 100
) -> list[Booking]:
    stmt = select(Booking).options(*_LOADS)
    if status:
        stmt = stmt.where(Booking.status == status)
    return list(db.scalars(stmt.order_by(Booking.created_at.desc()).offset(skip).limit(limit)))


def set_status(
    db: Session, booking: Booking, status: BookingStatus, amount: Optional[float] = None
) -> Booking:
    booking.status = status
    if amount is not None:
        booking.amount = amount
    db.add(booking)
    db.flush()
    return booking


def assign_worker(db: Session, booking: Booking, worker_id: int) -> Booking:
    booking.worker_id = worker_id
    db.add(booking)
    db.flush()
    return booking
