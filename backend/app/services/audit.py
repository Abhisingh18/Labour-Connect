"""Audit logging for sensitive admin actions."""
from typing import Optional

from fastapi import Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.audit_log import AuditLog
from app.models.user import User


def record(
    db: Session,
    *,
    actor: User,
    action: str,
    entity_type: Optional[str] = None,
    entity_id: Optional[int] = None,
    detail: Optional[str] = None,
    request: Optional[Request] = None,
) -> None:
    """Add an audit entry to the session (committed by the caller)."""
    db.add(
        AuditLog(
            actor_user_id=actor.id,
            actor_name=actor.name,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            detail=(detail or "")[:500] or None,
            ip_address=_client_ip(request),
        )
    )


def list_logs(db: Session, skip: int = 0, limit: int = 100) -> list[AuditLog]:
    stmt = select(AuditLog).order_by(AuditLog.created_at.desc()).offset(skip).limit(limit)
    return list(db.scalars(stmt))


def _client_ip(request: Optional[Request]) -> Optional[str]:
    if request is None:
        return None
    fwd = request.headers.get("x-forwarded-for")
    if fwd:
        return fwd.split(",")[0].strip()[:64]
    return request.client.host if request.client else None
