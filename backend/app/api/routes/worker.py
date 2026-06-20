from typing import Optional

from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import DbSession, WorkerUser
from app.crud import booking as booking_crud
from app.crud import review as review_crud
from app.crud import worker as worker_crud
from app.models.enums import BookingStatus, KycStatus
from app.schemas.booking import BookingOut
from app.schemas.review import ReviewOut
from app.schemas.worker import (
    AvailabilityUpdate,
    KycSubmit,
    WorkerProfileOut,
    WorkerProfileUpdate,
)

router = APIRouter(prefix="/worker", tags=["worker"])


@router.get("/profile", response_model=WorkerProfileOut)
def get_worker_profile(db: DbSession, current_user: WorkerUser):
    return worker_crud.get_or_create(db, current_user.id)


@router.put("/profile", response_model=WorkerProfileOut)
def update_worker_profile(payload: WorkerProfileUpdate, db: DbSession, current_user: WorkerUser):
    profile = worker_crud.get_or_create(db, current_user.id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)
    db.add(profile)
    db.commit()
    return worker_crud.get_by_user(db, current_user.id)


@router.post("/kyc", response_model=WorkerProfileOut)
def submit_kyc(payload: KycSubmit, db: DbSession, current_user: WorkerUser):
    profile = worker_crud.get_or_create(db, current_user.id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)
    profile.kyc_status = KycStatus.pending
    db.add(profile)
    db.commit()
    return worker_crud.get_by_user(db, current_user.id)


@router.put("/availability", response_model=WorkerProfileOut)
def set_availability(payload: AvailabilityUpdate, db: DbSession, current_user: WorkerUser):
    profile = worker_crud.get_or_create(db, current_user.id)
    if not profile.is_verified and payload.is_available:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You must be verified before going online",
        )
    profile.is_available = payload.is_available
    db.add(profile)
    db.commit()
    return worker_crud.get_by_user(db, current_user.id)


@router.get("/jobs/open", response_model=list[BookingOut])
def open_jobs(db: DbSession, current_user: WorkerUser):
    """Admin-approved open jobs for this worker's category (the pool)."""
    profile = worker_crud.get_or_create(db, current_user.id)
    if not profile.is_verified or profile.is_suspended:
        return []
    # Show jobs in the worker's category (and uncategorised jobs as a fallback).
    jobs = booking_crud.list_open_jobs(db, category_id=profile.category_id)
    return jobs


@router.post("/jobs/{booking_id}/claim", response_model=BookingOut)
def claim_job(booking_id: int, db: DbSession, current_user: WorkerUser):
    profile = worker_crud.get_or_create(db, current_user.id)
    if not profile.is_verified or profile.is_suspended:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only verified workers can accept jobs",
        )
    booking = booking_crud.claim_open_job(db, booking_id, current_user.id)
    if booking is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This job is no longer available (already taken).",
        )
    db.commit()
    return booking


@router.get("/bookings", response_model=list[BookingOut])
def worker_bookings(
    db: DbSession,
    current_user: WorkerUser,
    status_filter: Optional[BookingStatus] = Query(None, alias="status"),
):
    return booking_crud.list_for_worker(db, current_user.id, status_filter)


def _get_own_booking(db, booking_id: int, worker_id: int):
    booking = booking_crud.get(db, booking_id)
    if booking is None or booking.worker_id != worker_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    return booking


@router.post("/bookings/{booking_id}/accept", response_model=BookingOut)
def accept_booking(booking_id: int, db: DbSession, current_user: WorkerUser):
    booking = _get_own_booking(db, booking_id, current_user.id)
    if booking.status != BookingStatus.pending:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot accept a {booking.status.value} booking",
        )
    booking_crud.set_status(db, booking, BookingStatus.accepted)
    db.commit()
    return booking_crud.get(db, booking_id)


@router.post("/bookings/{booking_id}/reject", response_model=BookingOut)
def reject_booking(booking_id: int, db: DbSession, current_user: WorkerUser):
    booking = _get_own_booking(db, booking_id, current_user.id)
    if booking.status != BookingStatus.pending:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot reject a {booking.status.value} booking",
        )
    booking_crud.set_status(db, booking, BookingStatus.rejected)
    db.commit()
    return booking_crud.get(db, booking_id)


@router.post("/bookings/{booking_id}/complete", response_model=BookingOut)
def complete_booking(
    booking_id: int,
    db: DbSession,
    current_user: WorkerUser,
    amount: float = Query(0.0, ge=0),
):
    booking = _get_own_booking(db, booking_id, current_user.id)
    if booking.status != BookingStatus.accepted:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only accepted bookings can be completed",
        )
    booking_crud.set_status(db, booking, BookingStatus.completed, amount=amount)
    db.commit()
    return booking_crud.get(db, booking_id)


@router.get("/earnings")
def earnings(db: DbSession, current_user: WorkerUser):
    completed = booking_crud.list_for_worker(db, current_user.id, BookingStatus.completed)
    total = sum(b.amount for b in completed)
    from collections import defaultdict

    monthly: dict[str, float] = defaultdict(float)
    for b in completed:
        key = b.booking_date.strftime("%Y-%m")
        monthly[key] += b.amount
    return {
        "total_earnings": round(total, 2),
        "completed_jobs": len(completed),
        "monthly": [{"month": k, "amount": round(v, 2)} for k, v in sorted(monthly.items())],
    }


@router.get("/reviews", response_model=list[ReviewOut])
def worker_reviews(db: DbSession, current_user: WorkerUser):
    return review_crud.list_for_worker(db, current_user.id)
