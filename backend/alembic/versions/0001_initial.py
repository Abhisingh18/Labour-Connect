"""initial schema

Revision ID: 0001_initial
Revises:
Create Date: 2026-06-18
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# Each enum is used by exactly one table, so we let the table's CREATE handle
# the enum type creation (once each). No explicit .create() — that caused a
# double CREATE TYPE on PostgreSQL ("type already exists").
user_role = sa.Enum("customer", "worker", "admin", name="userrole")
booking_status = sa.Enum(
    "pending", "accepted", "rejected", "completed", "cancelled", name="bookingstatus"
)
kyc_status = sa.Enum(
    "not_submitted", "pending", "verified", "rejected", name="kycstatus"
)


def upgrade() -> None:
    bind = op.get_bind()
    # Clean any leftover enum types from a previous failed deploy (Postgres only;
    # SQLite has no native enum types). Safe here because no tables exist yet.
    if bind.dialect.name == "postgresql":
        op.execute("DROP TYPE IF EXISTS userrole")
        op.execute("DROP TYPE IF EXISTS bookingstatus")
        op.execute("DROP TYPE IF EXISTS kycstatus")

    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=True),
        sa.Column("email", sa.String(length=255), nullable=True),
        sa.Column("hashed_password", sa.String(length=255), nullable=True),
        sa.Column("role", user_role, nullable=False),
        sa.Column("profile_image", sa.String(length=512), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_users_id", "users", ["id"])
    op.create_index("ix_users_phone", "users", ["phone"], unique=True)
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "categories",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=120), nullable=False, unique=True),
        sa.Column("icon", sa.String(length=512), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_categories_id", "categories", ["id"])

    op.create_table(
        "worker_profiles",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True),
        sa.Column("category_id", sa.Integer(), sa.ForeignKey("categories.id", ondelete="SET NULL"), nullable=True),
        sa.Column("experience", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("bio", sa.String(length=1000), nullable=True),
        sa.Column("service_area", sa.String(length=255), nullable=True),
        sa.Column("latitude", sa.Float(), nullable=True),
        sa.Column("longitude", sa.Float(), nullable=True),
        sa.Column("aadhaar_url", sa.String(length=512), nullable=True),
        sa.Column("pan_url", sa.String(length=512), nullable=True),
        sa.Column("selfie_url", sa.String(length=512), nullable=True),
        sa.Column("kyc_status", kyc_status, nullable=False, server_default="not_submitted"),
        sa.Column("is_verified", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("is_available", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("is_suspended", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("rating", sa.Float(), nullable=False, server_default="0"),
        sa.Column("rating_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_worker_profiles_id", "worker_profiles", ["id"])
    op.create_index("ix_worker_profiles_category_id", "worker_profiles", ["category_id"])

    op.create_table(
        "bookings",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("customer_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("worker_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("category_id", sa.Integer(), sa.ForeignKey("categories.id", ondelete="SET NULL"), nullable=True),
        sa.Column("booking_date", sa.Date(), nullable=False),
        sa.Column("booking_time", sa.Time(), nullable=True),
        sa.Column("address", sa.String(length=500), nullable=False),
        sa.Column("notes", sa.String(length=1000), nullable=True),
        sa.Column("status", booking_status, nullable=False, server_default="pending"),
        sa.Column("amount", sa.Float(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_bookings_id", "bookings", ["id"])
    op.create_index("ix_bookings_customer_id", "bookings", ["customer_id"])
    op.create_index("ix_bookings_worker_id", "bookings", ["worker_id"])
    op.create_index("ix_bookings_status", "bookings", ["status"])

    op.create_table(
        "reviews",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("booking_id", sa.Integer(), sa.ForeignKey("bookings.id", ondelete="CASCADE"), nullable=False, unique=True),
        sa.Column("rating", sa.Integer(), nullable=False),
        sa.Column("comment", sa.String(length=1000), nullable=True),
        sa.Column("is_hidden", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index("ix_reviews_id", "reviews", ["id"])
    op.create_index("ix_reviews_booking_id", "reviews", ["booking_id"])


def downgrade() -> None:
    op.drop_table("reviews")
    op.drop_table("bookings")
    op.drop_table("worker_profiles")
    op.drop_table("categories")
    op.drop_table("users")
    bind = op.get_bind()
    kyc_status.drop(bind, checkfirst=True)
    booking_status.drop(bind, checkfirst=True)
    user_role.drop(bind, checkfirst=True)
