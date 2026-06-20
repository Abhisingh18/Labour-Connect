import enum


class UserRole(str, enum.Enum):
    customer = "customer"
    worker = "worker"
    admin = "admin"


class BookingStatus(str, enum.Enum):
    pending_approval = "pending_approval"  # open job posted by customer, awaiting admin
    open = "open"              # admin-approved open job, visible to worker pool
    pending = "pending"        # direct booking, awaiting the chosen worker
    accepted = "accepted"      # worker accepted / claimed
    rejected = "rejected"      # worker rejected
    completed = "completed"    # job done
    cancelled = "cancelled"    # cancelled by customer/admin


class KycStatus(str, enum.Enum):
    not_submitted = "not_submitted"
    pending = "pending"
    verified = "verified"
    rejected = "rejected"
