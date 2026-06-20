"""Refresh-token lifecycle: issue, rotate, revoke.

Only the SHA-256 hash of each token is stored. Rotation invalidates the old
token on every refresh, so a stolen-then-replayed token is detected and the
whole family can be revoked.
"""
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core.security import (
    create_access_token,
    generate_refresh_token,
    hash_refresh_token,
    refresh_expiry,
)
from app.models.refresh_token import RefreshToken
from app.models.user import User


def issue_pair(
    db: Session,
    user: User,
    *,
    device_info: Optional[str] = None,
    ip: Optional[str] = None,
) -> tuple[str, str]:
    """Return (access_token, refresh_token) and persist the refresh hash."""
    raw_refresh = generate_refresh_token()
    record = RefreshToken(
        user_id=user.id,
        token_hash=hash_refresh_token(raw_refresh),
        expires_at=refresh_expiry(),
        device_info=(device_info or "")[:255] or None,
        ip_address=ip,
    )
    db.add(record)
    db.flush()
    access = create_access_token(user.id, user.role.value)
    return access, raw_refresh


def _active(db: Session, raw_refresh: str) -> Optional[RefreshToken]:
    record = db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == hash_refresh_token(raw_refresh))
    )
    if record is None or record.revoked:
        return None
    # SQLite returns naive datetimes; treat stored values as UTC for comparison.
    expires = record.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)
    if expires < datetime.now(timezone.utc):
        return None
    return record


def rotate(
    db: Session,
    raw_refresh: str,
    *,
    ip: Optional[str] = None,
) -> Optional[tuple[str, str, User]]:
    """Validate + rotate a refresh token. Returns (access, refresh, user) or None."""
    record = _active(db, raw_refresh)
    if record is None:
        return None
    user = db.get(User, record.user_id)
    if user is None or not user.is_active:
        return None

    record.revoked = True  # one-time use
    db.add(record)
    access, new_refresh = issue_pair(db, user, device_info=record.device_info, ip=ip)
    return access, new_refresh, user


def revoke(db: Session, raw_refresh: str) -> bool:
    record = db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == hash_refresh_token(raw_refresh))
    )
    if record is None:
        return False
    record.revoked = True
    db.add(record)
    db.flush()
    return True


def revoke_all_for_user(db: Session, user_id: int) -> int:
    result = db.execute(
        update(RefreshToken)
        .where(RefreshToken.user_id == user_id, RefreshToken.revoked.is_(False))
        .values(revoked=True)
    )
    db.flush()
    return result.rowcount or 0
