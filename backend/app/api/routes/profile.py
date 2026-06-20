from fastapi import APIRouter

from app.api.deps import CurrentUser, DbSession
from app.crud import user as user_crud
from app.schemas.user import UserOut, UserUpdate

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("", response_model=UserOut)
def get_profile(current_user: CurrentUser):
    return current_user


@router.put("", response_model=UserOut)
def update_profile(payload: UserUpdate, db: DbSession, current_user: CurrentUser):
    user = user_crud.update(db, current_user, payload)
    db.commit()
    db.refresh(user)
    return user
