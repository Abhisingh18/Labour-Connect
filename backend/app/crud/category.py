from typing import Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.category import Category
from app.schemas.category import CategoryCreate, CategoryUpdate


def get(db: Session, category_id: int) -> Optional[Category]:
    return db.get(Category, category_id)


def get_by_name(db: Session, name: str) -> Optional[Category]:
    return db.scalar(select(Category).where(Category.name == name))


def list_all(db: Session, active_only: bool = False) -> list[Category]:
    stmt = select(Category).order_by(Category.name)
    if active_only:
        stmt = stmt.where(Category.is_active.is_(True))
    return list(db.scalars(stmt))


def create(db: Session, data: CategoryCreate) -> Category:
    category = Category(**data.model_dump())
    db.add(category)
    db.flush()
    return category


def update(db: Session, category: Category, data: CategoryUpdate) -> Category:
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(category, field, value)
    db.add(category)
    db.flush()
    return category


def delete(db: Session, category: Category) -> None:
    db.delete(category)
    db.flush()
