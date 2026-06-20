from fastapi import APIRouter

from app.api.deps import DbSession
from app.crud import category as category_crud
from app.schemas.category import CategoryOut

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryOut])
def list_categories(db: DbSession):
    """Public list of active service categories (customer home screen)."""
    return category_crud.list_all(db, active_only=True)
