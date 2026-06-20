from typing import Optional

from fastapi import APIRouter, HTTPException, Query, Request, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.deps import AdminUser, DbSession
from app.crud import booking as booking_crud
from app.crud import category as category_crud
from app.crud import review as review_crud
from app.crud import user as user_crud
from app.crud import worker as worker_crud
from app.models.booking import Booking
from app.models.enums import BookingStatus, KycStatus, UserRole
from app.models.user import User
from app.models.worker_profile import WorkerProfile
from app.schemas.admin import AuditLogOut, DashboardStats, SuspendAction, WorkerVerifyAction
from app.schemas.booking import BookingOut, BookingStatusUpdate, JobApprove
from app.schemas.category import CategoryCreate, CategoryOut, CategoryUpdate
from app.schemas.review import ReviewOut
from app.schemas.user import UserOut
from app.schemas.worker import WorkerProfileOut
from app.services import audit

router = APIRouter(prefix="/admin", tags=["admin"])


# ---------- Dashboard ----------
@router.get("/dashboard", response_model=DashboardStats)
def dashboard(db: DbSession, _: AdminUser):
    def count(stmt) -> int:
        return db.scalar(stmt) or 0

    total_customers = count(
        select(func.count()).select_from(User).where(User.role == UserRole.customer)
    )
    total_workers = count(
        select(func.count()).select_from(User).where(User.role == UserRole.worker)
    )
    verified_workers = count(
        select(func.count()).select_from(WorkerProfile).where(WorkerProfile.is_verified.is_(True))
    )
    pending_kyc = count(
        select(func.count())
        .select_from(WorkerProfile)
        .where(WorkerProfile.kyc_status == KycStatus.pending)
    )
    total_bookings = count(select(func.count()).select_from(Booking))
    completed_bookings = count(
        select(func.count()).select_from(Booking).where(Booking.status == BookingStatus.completed)
    )
    pending_bookings = count(
        select(func.count()).select_from(Booking).where(Booking.status == BookingStatus.pending)
    )
    total_revenue = db.scalar(
        select(func.coalesce(func.sum(Booking.amount), 0.0)).where(
            Booking.status == BookingStatus.completed
        )
    )

    return DashboardStats(
        total_customers=total_customers,
        total_workers=total_workers,
        verified_workers=verified_workers,
        pending_kyc=pending_kyc,
        total_bookings=total_bookings,
        completed_bookings=completed_bookings,
        pending_bookings=pending_bookings,
        total_revenue=round(float(total_revenue or 0), 2),
    )


# ---------- Users ----------
@router.get("/customers", response_model=list[UserOut])
def list_customers(db: DbSession, _: AdminUser, skip: int = 0, limit: int = Query(100, le=200)):
    return user_crud.list_by_role(db, UserRole.customer, skip, limit)


@router.post("/users/{user_id}/block", response_model=UserOut)
def set_user_block(
    user_id: int, payload: SuspendAction, db: DbSession, admin: AdminUser, request: Request
):
    user = user_crud.get(db, user_id)
    if user is None or user.role == UserRole.admin:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    user_crud.set_active(db, user, is_active=not payload.suspend)
    audit.record(
        db,
        actor=admin,
        action="user.block" if payload.suspend else "user.unblock",
        entity_type="user",
        entity_id=user_id,
        request=request,
    )
    db.commit()
    db.refresh(user)
    return user


@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user(user_id: int, db: DbSession, admin: AdminUser, request: Request):
    user = user_crud.get(db, user_id)
    if user is None or user.role == UserRole.admin:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    audit.record(
        db,
        actor=admin,
        action="user.delete",
        entity_type="user",
        entity_id=user_id,
        detail=f"name={user.name}",
        request=request,
    )
    db.delete(user)
    db.commit()


# ---------- Workers ----------
def _worker_out(db: Session, profile: WorkerProfile) -> dict:
    user = user_crud.get(db, profile.user_id)
    data = WorkerProfileOut.model_validate(profile).model_dump()
    data["name"] = user.name if user else None
    data["phone"] = user.phone if user else None
    data["is_active"] = user.is_active if user else None
    return data


@router.get("/workers")
def list_workers(
    db: DbSession,
    _: AdminUser,
    kyc_status: Optional[KycStatus] = None,
    skip: int = 0,
    limit: int = Query(100, le=200),
):
    stmt = select(WorkerProfile).order_by(WorkerProfile.created_at.desc())
    if kyc_status:
        stmt = stmt.where(WorkerProfile.kyc_status == kyc_status)
    profiles = list(db.scalars(stmt.offset(skip).limit(limit)))
    return [_worker_out(db, p) for p in profiles]


@router.post("/workers/{user_id}/verify")
def verify_worker(
    user_id: int,
    payload: WorkerVerifyAction,
    db: DbSession,
    admin: AdminUser,
    request: Request,
):
    profile = worker_crud.get_by_user(db, user_id)
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Worker not found")
    if payload.approve:
        profile.is_verified = True
        profile.kyc_status = KycStatus.verified
    else:
        profile.is_verified = False
        profile.is_available = False
        profile.kyc_status = KycStatus.rejected
    db.add(profile)
    audit.record(
        db,
        actor=admin,
        action="worker.verify" if payload.approve else "worker.reject",
        entity_type="worker",
        entity_id=user_id,
        request=request,
    )
    db.commit()
    return _worker_out(db, profile)


@router.post("/workers/{user_id}/suspend")
def suspend_worker(
    user_id: int,
    payload: SuspendAction,
    db: DbSession,
    admin: AdminUser,
    request: Request,
):
    profile = worker_crud.get_by_user(db, user_id)
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Worker not found")
    profile.is_suspended = payload.suspend
    if payload.suspend:
        profile.is_available = False
    db.add(profile)
    audit.record(
        db,
        actor=admin,
        action="worker.suspend" if payload.suspend else "worker.reinstate",
        entity_type="worker",
        entity_id=user_id,
        request=request,
    )
    db.commit()
    return _worker_out(db, profile)


# ---------- Categories ----------
@router.get("/categories", response_model=list[CategoryOut])
def admin_list_categories(db: DbSession, _: AdminUser):
    return category_crud.list_all(db)


@router.post("/categories", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
def create_category(payload: CategoryCreate, db: DbSession, admin: AdminUser, request: Request):
    if category_crud.get_by_name(db, payload.name):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Category already exists"
        )
    category = category_crud.create(db, payload)
    audit.record(
        db,
        actor=admin,
        action="category.create",
        entity_type="category",
        entity_id=category.id,
        detail=f"name={category.name}",
        request=request,
    )
    db.commit()
    db.refresh(category)
    return category


@router.put("/categories/{category_id}", response_model=CategoryOut)
def update_category(
    category_id: int, payload: CategoryUpdate, db: DbSession, admin: AdminUser, request: Request
):
    category = category_crud.get(db, category_id)
    if category is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    category = category_crud.update(db, category, payload)
    audit.record(
        db,
        actor=admin,
        action="category.update",
        entity_type="category",
        entity_id=category_id,
        request=request,
    )
    db.commit()
    db.refresh(category)
    return category


@router.delete("/categories/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(category_id: int, db: DbSession, admin: AdminUser, request: Request):
    category = category_crud.get(db, category_id)
    if category is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    audit.record(
        db,
        actor=admin,
        action="category.delete",
        entity_type="category",
        entity_id=category_id,
        detail=f"name={category.name}",
        request=request,
    )
    category_crud.delete(db, category)
    db.commit()


# ---------- Bookings ----------
@router.get("/bookings", response_model=list[BookingOut])
def admin_list_bookings(
    db: DbSession,
    _: AdminUser,
    status_filter: Optional[BookingStatus] = Query(None, alias="status"),
    skip: int = 0,
    limit: int = Query(100, le=200),
):
    return booking_crud.list_all(db, status_filter, skip, limit)


@router.post("/jobs/{booking_id}/approve", response_model=BookingOut)
def approve_job(
    booking_id: int, payload: JobApprove, db: DbSession, admin: AdminUser, request: Request
):
    """Approve an open job request: set agreed amount and make it visible to workers."""
    booking = booking_crud.get(db, booking_id)
    if booking is None or not booking.is_open_request:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job request not found")
    if booking.status != BookingStatus.pending_approval:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot approve a {booking.status.value} job",
        )
    booking_crud.set_status(db, booking, BookingStatus.open, amount=payload.amount)
    audit.record(
        db,
        actor=admin,
        action="job.approve",
        entity_type="booking",
        entity_id=booking_id,
        detail=f"amount={payload.amount}",
        request=request,
    )
    db.commit()
    return booking_crud.get(db, booking_id)


@router.post("/jobs/{booking_id}/reject", response_model=BookingOut)
def reject_job(booking_id: int, db: DbSession, admin: AdminUser, request: Request):
    booking = booking_crud.get(db, booking_id)
    if booking is None or not booking.is_open_request:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job request not found")
    if booking.status != BookingStatus.pending_approval:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot reject a {booking.status.value} job",
        )
    booking_crud.set_status(db, booking, BookingStatus.cancelled)
    audit.record(
        db,
        actor=admin,
        action="job.reject",
        entity_type="booking",
        entity_id=booking_id,
        request=request,
    )
    db.commit()
    return booking_crud.get(db, booking_id)


@router.put("/bookings/{booking_id}/status", response_model=BookingOut)
def admin_update_booking(
    booking_id: int,
    payload: BookingStatusUpdate,
    db: DbSession,
    admin: AdminUser,
    request: Request,
):
    booking = booking_crud.get(db, booking_id)
    if booking is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    booking_crud.set_status(db, booking, payload.status, payload.amount)
    audit.record(
        db,
        actor=admin,
        action="booking.status",
        entity_type="booking",
        entity_id=booking_id,
        detail=f"status={payload.status.value}",
        request=request,
    )
    db.commit()
    return booking_crud.get(db, booking_id)


@router.post("/bookings/{booking_id}/assign", response_model=BookingOut)
def admin_assign_worker(
    booking_id: int, worker_id: int, db: DbSession, admin: AdminUser, request: Request
):
    booking = booking_crud.get(db, booking_id)
    if booking is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    worker = user_crud.get(db, worker_id)
    if worker is None or worker.role != UserRole.worker:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Worker not found")
    booking_crud.assign_worker(db, booking, worker_id)
    audit.record(
        db,
        actor=admin,
        action="booking.assign",
        entity_type="booking",
        entity_id=booking_id,
        detail=f"worker_id={worker_id}",
        request=request,
    )
    db.commit()
    return booking_crud.get(db, booking_id)


# ---------- Reviews ----------
@router.get("/reviews", response_model=list[ReviewOut])
def admin_list_reviews(db: DbSession, _: AdminUser, skip: int = 0, limit: int = Query(100, le=200)):
    return review_crud.list_all(db, skip, limit)


@router.post("/reviews/{review_id}/hide", response_model=ReviewOut)
def hide_review(
    review_id: int, payload: SuspendAction, db: DbSession, admin: AdminUser, request: Request
):
    review = review_crud.get(db, review_id)
    if review is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found")
    review_crud.set_hidden(db, review, hidden=payload.suspend)
    # recompute affected worker rating
    booking = booking_crud.get(db, review.booking_id)
    if booking and booking.worker_id:
        worker_crud.recalc_rating(db, booking.worker_id)
    audit.record(
        db,
        actor=admin,
        action="review.hide" if payload.suspend else "review.restore",
        entity_type="review",
        entity_id=review_id,
        request=request,
    )
    db.commit()
    db.refresh(review)
    return review


# ---------- Audit logs ----------
@router.get("/audit-logs", response_model=list[AuditLogOut])
def list_audit_logs(db: DbSession, _: AdminUser, skip: int = 0, limit: int = Query(100, le=200)):
    return audit.list_logs(db, skip, limit)
