"""open job requests (Labour-Chowk flow)

Revision ID: 0003_open_jobs
Revises: 0002_security
Create Date: 2026-06-20
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0003_open_jobs"
down_revision: Union[str, None] = "0002_security"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "bookings",
        sa.Column("is_open_request", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    # New enum values. SQLite stores enums as VARCHAR (no change needed);
    # PostgreSQL needs explicit ALTER TYPE.
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        op.execute("ALTER TYPE bookingstatus ADD VALUE IF NOT EXISTS 'pending_approval'")
        op.execute("ALTER TYPE bookingstatus ADD VALUE IF NOT EXISTS 'open'")


def downgrade() -> None:
    op.drop_column("bookings", "is_open_request")
