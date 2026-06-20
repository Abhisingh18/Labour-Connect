from typing import Optional

from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import CustomerUser, DbSession
from app.crud import booking as booking_crud
from app.crud import review as review_crud
from app.crud import user as user_crud
from app.crud import worker as worker_crud
from app.models.enums import BookingStatus
from app.schemas.booking import BookingCreate, BookingOut, JobRequestCreate
from app.schemas.review import ReviewCreate, ReviewOut
from app.schemas.worker import WorkerListItem, WorkerPublicDetail

router = APIRouter(prefix="/customer", tags=["customer"])


def _to_list_item(profile, user, lat=None, lng=None) -> WorkerListItem:
    distance = None
    if lat is not None and lng is not None and profile.latitude and profile.longitude:
        distance = worker_crud.haversine_km(lat, lng, profile.latitude, profile.longitude)
    return WorkerListItem(
        user_id=user.id,
        name=user.name,
        profile_image=user.profile_image,
        category=profile.category,
        experience=profile.experience,
        rating=profile.rating,
        rating_count=profile.rating_count,
        is_available=profile.is_available,
        service_area=profile.service_area,
        distance_km=distance,
    )


@router.get("/workers", response_model=list[WorkerListItem])
def search_workers(
    db: DbSession,
    _: CustomerUser,
    category_id: Optional[int] = None,
    q: Optional[str] = Query(None, description="Search by worker name"),
    available_only: bool = True,
    lat: Optional[float] = None,
    lng: Optional[float] = None,
    skip: int = 0,
    limit: int = Query(50, le=100),
):
    rows = worker_crud.search(
        db,
        category_id=category_id,
        query=q,
        available_only=available_only,
        skip=skip,
        limit=limit,
    )
    items = [_to_list_item(p, u, lat, lng) for p, u in rows]
    if lat is not None and lng is not None:
        items.sort(key=lambda x: (x.distance_km is None, x.distance_km or 0))
    return items


@router.get("/workers/{user_id}", response_model=WorkerPublicDetail)
def worker_detail(user_id: int, db: DbSession, _: CustomerUser):
    profile = worker_crud.get_by_user(db, user_id)
    user = user_crud.get(db, user_id)
    if profile is None or user is None or not profile.is_verified or profile.is_suspended:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Worker not found")
    base = _to_list_item(profile, user)
    return WorkerPublicDetail(**base.model_dump(), bio=profile.bio, phone=user.phone)


@router.post("/bookings", response_model=BookingOut, status_code=status.HTTP_201_CREATED)
def create_booking(payload: BookingCreate, db: DbSession, current_user: CustomerUser):
    worker = user_crud.get(db, payload.worker_id)
    if worker is None or worker.role.value != "worker":
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Worker not found")
    profile = worker_crud.get_by_user(db, payload.worker_id)
    if profile is None or not profile.is_verified or profile.is_suspended:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Worker is not available for booking"
        )
    booking = booking_crud.create(db, current_user.id, payload)
    db.commit()
    return booking


@router.post("/jobs", response_model=BookingOut, status_code=status.HTTP_201_CREATED)
def post_job(payload: JobRequestCreate, db: DbSession, current_user: CustomerUser):
    """Post an open job (no specific worker). Admin reviews & approves it."""
    from app.crud import category as category_crud

    if category_crud.get(db, payload.category_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    booking = booking_crud.create_open_job(db, current_user.id, payload)
    db.commit()
    return booking


@router.get("/bookings", response_model=list[BookingOut])
def my_bookings(
    db: DbSession,
    current_user: CustomerUser,
    status_filter: Optional[BookingStatus] = Query(None, alias="status"),
):
    return booking_crud.list_for_customer(db, current_user.id, status_filter)


@router.post("/bookings/{booking_id}/cancel", response_model=BookingOut)
def cancel_booking(booking_id: int, db: DbSession, current_user: CustomerUser):
    booking = booking_crud.get(db, booking_id)
    if booking is None or booking.customer_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    if booking.status in (BookingStatus.completed, BookingStatus.cancelled):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot cancel a {booking.status.value} booking",
        )
    booking_crud.set_status(db, booking, BookingStatus.cancelled)
    db.commit()
    return booking_crud.get(db, booking_id)


@router.post(
    "/bookings/{booking_id}/review",
    response_model=ReviewOut,
    status_code=status.HTTP_201_CREATED,
)
def add_review(booking_id: int, payload: ReviewCreate, db: DbSession, current_user: CustomerUser):
    booking = booking_crud.get(db, booking_id)
    if booking is None or booking.customer_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    if booking.status != BookingStatus.completed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You can only review completed bookings",
        )
    if review_crud.get_by_booking(db, booking_id) is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="This booking is already reviewed"
        )
    review = review_crud.create(db, booking_id, payload)
    if booking.worker_id:
        worker_crud.recalc_rating(db, booking.worker_id)
    db.commit()
    db.refresh(review)
    return review
