# Import all models here so Alembic's autogenerate can discover them.
from app.db.base_class import Base  # noqa: F401
from app.models.user import User  # noqa: F401
from app.models.worker_profile import WorkerProfile  # noqa: F401
from app.models.category import Category  # noqa: F401
from app.models.booking import Booking  # noqa: F401
from app.models.review import Review  # noqa: F401
from app.models.refresh_token import RefreshToken  # noqa: F401
from app.models.audit_log import AuditLog  # noqa: F401
