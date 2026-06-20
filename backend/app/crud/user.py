from typing import Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.enums import UserRole
from app.models.user import User
from app.schemas.user import UserUpdate


def get(db: Session, user_id: int) -> Optional[User]:
    return db.get(User, user_id)


def get_by_phone(db: Session, phone: str) -> Optional[User]:
    return db.scalar(select(User).where(User.phone == phone))


def get_by_email(db: Session, email: str) -> Optional[User]:
    return db.scalar(select(User).where(User.email == email))


def create_phone_user(db: Session, phone: str, role: UserRole, name: Optional[str]) -> User:
    user = User(phone=phone, role=role, name=name or "User")
    db.add(user)
    db.flush()
    return user


def update(db: Session, user: User, data: UserUpdate) -> User:
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(user, field, value)
    db.add(user)
    db.flush()
    return user


def list_by_role(
    db: Session, role: UserRole, skip: int = 0, limit: int = 100
) -> list[User]:
    stmt = select(User).where(User.role == role).order_by(User.created_at.desc()).offset(skip).limit(limit)
    return list(db.scalars(stmt))


def set_active(db: Session, user: User, is_active: bool) -> User:
    user.is_active = is_active
    db.add(user)
    db.flush()
    return user
