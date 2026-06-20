from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import decode_access_token
from app.crud import user as user_crud
from app.db.session import get_db
from app.models.enums import UserRole
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_PREFIX}/auth/admin/login", auto_error=True)

DbSession = Annotated[Session, Depends(get_db)]


def get_current_user(
    db: DbSession, token: Annotated[str, Depends(oauth2_scheme)]
) -> User:
    credentials_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_access_token(token)
    if not payload or "sub" not in payload:
        raise credentials_exc
    user = user_crud.get(db, int(payload["sub"]))
    if user is None:
        raise credentials_exc
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is blocked")
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


def _require_role(*roles: UserRole):
    def checker(current_user: CurrentUser) -> User:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions for this resource",
            )
        return current_user

    return checker


def require_customer(
    user: Annotated[User, Depends(_require_role(UserRole.customer))]
) -> User:
    return user


def require_worker(
    user: Annotated[User, Depends(_require_role(UserRole.worker))]
) -> User:
    return user


def require_admin(
    user: Annotated[User, Depends(_require_role(UserRole.admin))]
) -> User:
    return user


CustomerUser = Annotated[User, Depends(require_customer)]
WorkerUser = Annotated[User, Depends(require_worker)]
AdminUser = Annotated[User, Depends(require_admin)]
