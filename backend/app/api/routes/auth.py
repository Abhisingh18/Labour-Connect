from fastapi import APIRouter, HTTPException, Request, status

from app.api.deps import CurrentUser, DbSession
from app.core import rate_limit
from app.core.config import settings
from app.core.security import verify_password
from app.crud import user as user_crud
from app.models.enums import UserRole
from app.schemas.auth import (
    AccessToken,
    AdminLoginRequest,
    LogoutRequest,
    RefreshRequest,
    SendOtpRequest,
    SendOtpResponse,
    Token,
    VerifyOtpRequest,
)
from app.schemas.user import UserOut
from app.services import otp as otp_service
from app.services import tokens as token_service

router = APIRouter(prefix="/auth", tags=["auth"])


def _client_ip(request: Request) -> str:
    fwd = request.headers.get("x-forwarded-for")
    if fwd:
        return fwd.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


@router.post("/send-otp", response_model=SendOtpResponse)
def send_otp(payload: SendOtpRequest):
    # Rate-limit OTP sends per phone to prevent SMS-bombing / OTP abuse.
    if not rate_limit.allow(
        f"otp_send:{payload.phone}",
        settings.OTP_SEND_MAX_PER_WINDOW,
        settings.OTP_SEND_WINDOW_SECONDS,
    ):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many OTP requests. Please try again later.",
        )
    code = otp_service.generate_and_send(payload.phone)
    return SendOtpResponse(
        message="OTP sent successfully",
        dev_otp=code if settings.OTP_MOCK else None,
    )


@router.post("/verify-otp", response_model=Token)
def verify_otp(payload: VerifyOtpRequest, db: DbSession, request: Request):
    if payload.role == UserRole.admin:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Admins must log in via /auth/admin/login",
        )

    lock_key = f"otp_verify:{payload.phone}"
    locked = rate_limit.is_locked(lock_key)
    if locked:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Too many failed attempts. Try again in {locked // 60 + 1} minutes.",
        )

    if not otp_service.verify(payload.phone, payload.otp):
        remaining = rate_limit.record_failure(
            lock_key,
            settings.OTP_MAX_FAILED_ATTEMPTS,
            settings.LOCKOUT_SECONDS,
            settings.OTP_SEND_WINDOW_SECONDS,
        )
        detail = "Invalid or expired OTP"
        if remaining:
            detail = "Account temporarily locked due to too many failed attempts."
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=detail)

    rate_limit.clear_failures(lock_key)

    user = user_crud.get_by_phone(db, payload.phone)
    is_new = False
    if user is None:
        user = user_crud.create_phone_user(db, payload.phone, payload.role, payload.name)
        is_new = True
    elif user.role != payload.role:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"This phone is already registered as a {user.role.value}",
        )

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is blocked")

    if user.role == UserRole.worker:
        from app.crud import worker as worker_crud

        worker_crud.get_or_create(db, user.id)

    access, refresh = token_service.issue_pair(
        db,
        user,
        device_info=request.headers.get("user-agent"),
        ip=_client_ip(request),
    )
    db.commit()
    return Token(
        access_token=access,
        refresh_token=refresh,
        role=user.role,
        user_id=user.id,
        is_new_user=is_new,
    )


@router.post("/admin/login", response_model=Token)
def admin_login(payload: AdminLoginRequest, db: DbSession, request: Request):
    ip = _client_ip(request)
    lock_key = f"admin_login:{ip}:{payload.email}"
    locked = rate_limit.is_locked(lock_key)
    if locked:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Too many failed logins. Try again in {locked // 60 + 1} minutes.",
        )

    user = user_crud.get_by_email(db, payload.email)
    if (
        user is None
        or user.role != UserRole.admin
        or not user.hashed_password
        or not verify_password(payload.password, user.hashed_password)
    ):
        rate_limit.record_failure(
            lock_key,
            settings.LOGIN_MAX_PER_WINDOW,
            settings.LOCKOUT_SECONDS,
            settings.LOGIN_WINDOW_SECONDS,
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password"
        )
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is disabled")

    rate_limit.clear_failures(lock_key)
    access, refresh = token_service.issue_pair(
        db, user, device_info=request.headers.get("user-agent"), ip=ip
    )
    db.commit()
    return Token(access_token=access, refresh_token=refresh, role=user.role, user_id=user.id)


@router.post("/refresh", response_model=AccessToken)
def refresh(payload: RefreshRequest, db: DbSession, request: Request):
    result = token_service.rotate(db, payload.refresh_token, ip=_client_ip(request))
    if result is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired session. Please log in again.",
        )
    access, new_refresh, _user = result
    db.commit()
    return AccessToken(access_token=access, refresh_token=new_refresh)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(payload: LogoutRequest, db: DbSession):
    token_service.revoke(db, payload.refresh_token)
    db.commit()


@router.post("/logout-all", status_code=status.HTTP_204_NO_CONTENT)
def logout_all(db: DbSession, current_user: CurrentUser):
    token_service.revoke_all_for_user(db, current_user.id)
    db.commit()


@router.get("/me", response_model=UserOut)
def me(current_user: CurrentUser):
    return current_user
