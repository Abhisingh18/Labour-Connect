"""OTP service.

MVP uses a mock provider: codes are stored in-memory and any phone is accepted
with the configured DEV_OTP_CODE. Swap `generate_and_send` / `verify` for a real
provider (Firebase, MSG91, Twilio) later without touching the API layer.
"""
import random
from datetime import datetime, timedelta, timezone

from app.core.config import settings

# phone -> (code, expires_at)
_otp_store: dict[str, tuple[str, datetime]] = {}


def generate_and_send(phone: str) -> str:
    if settings.OTP_MOCK:
        code = settings.DEV_OTP_CODE
    else:
        code = f"{random.randint(0, 999999):06d}"

    expires = datetime.now(timezone.utc) + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)
    _otp_store[phone] = (code, expires)

    # TODO: integrate real SMS/Firebase here when OTP_MOCK is False.
    return code


def verify(phone: str, otp: str) -> bool:
    # In mock mode the dev code always works, even without a prior send call.
    if settings.OTP_MOCK and otp == settings.DEV_OTP_CODE:
        _otp_store.pop(phone, None)
        return True

    entry = _otp_store.get(phone)
    if not entry:
        return False
    code, expires = entry
    if datetime.now(timezone.utc) > expires:
        _otp_store.pop(phone, None)
        return False
    if code != otp:
        return False
    _otp_store.pop(phone, None)
    return True
