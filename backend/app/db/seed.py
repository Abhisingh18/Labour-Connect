"""Seed initial data: default admin + service categories.

Idempotent — safe to run on every startup. Invoked by entrypoint.sh and can be
run manually with `python -m app.db.seed`.
"""
from app.core.config import settings
from app.core.security import hash_password
from app.crud import category as category_crud
from app.crud import user as user_crud
from app.db.session import SessionLocal
from app.models.enums import UserRole
from app.models.user import User
from app.schemas.category import CategoryCreate

DEFAULT_CATEGORIES = [
    ("Plumber", "plumbing"),
    ("Electrician", "electrical"),
    ("Carpenter", "carpenter"),
    ("Painter", "painter"),
    ("Mason", "mason"),
    ("Labour", "labour"),
    ("AC Repair", "ac"),
    ("Appliance Repair", "appliance"),
    ("Cleaning", "cleaning"),
    ("Driver", "driver"),
    ("Packers & Movers", "movers"),
]


def seed() -> None:
    db = SessionLocal()
    try:
        # Admin
        admin = user_crud.get_by_email(db, settings.FIRST_ADMIN_EMAIL)
        if admin is None:
            admin = User(
                name=settings.FIRST_ADMIN_NAME,
                email=settings.FIRST_ADMIN_EMAIL,
                hashed_password=hash_password(settings.FIRST_ADMIN_PASSWORD),
                role=UserRole.admin,
                is_active=True,
            )
            db.add(admin)
            print(f"  + created admin {settings.FIRST_ADMIN_EMAIL}")

        # Categories
        created = 0
        for name, icon in DEFAULT_CATEGORIES:
            if category_crud.get_by_name(db, name) is None:
                category_crud.create(db, CategoryCreate(name=name, icon=icon))
                created += 1
        if created:
            print(f"  + created {created} categories")

        db.commit()
        print("Seed complete.")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
