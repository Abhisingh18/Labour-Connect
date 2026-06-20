from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class DashboardStats(BaseModel):
    total_customers: int
    total_workers: int
    verified_workers: int
    pending_kyc: int
    total_bookings: int
    completed_bookings: int
    pending_bookings: int
    total_revenue: float


class WorkerVerifyAction(BaseModel):
    approve: bool


class SuspendAction(BaseModel):
    suspend: bool


class AuditLogOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    actor_user_id: Optional[int] = None
    actor_name: Optional[str] = None
    action: str
    entity_type: Optional[str] = None
    entity_id: Optional[int] = None
    detail: Optional[str] = None
    ip_address: Optional[str] = None
    created_at: datetime
