"""Lightweight in-memory rate limiter + lockout tracker.

Adequate for a single-instance MVP. For multi-instance production move this to
Redis (same interface) — see SECURITY.md.
"""
import threading
import time
from collections import defaultdict

_lock = threading.Lock()
_hits: dict[str, list[float]] = defaultdict(list)
_failures: dict[str, list[float]] = defaultdict(list)
_lockouts: dict[str, float] = {}


def allow(key: str, limit: int, window_seconds: int) -> bool:
    """Sliding-window limiter. Returns False once `limit` hits occur in window."""
    now = time.time()
    with _lock:
        bucket = [t for t in _hits[key] if now - t < window_seconds]
        if len(bucket) >= limit:
            _hits[key] = bucket
            return False
        bucket.append(now)
        _hits[key] = bucket
        return True


def is_locked(key: str) -> int:
    """Return remaining lockout seconds (0 if not locked)."""
    now = time.time()
    with _lock:
        until = _lockouts.get(key, 0)
        return max(0, int(until - now)) if until > now else 0


def record_failure(key: str, max_attempts: int, lockout_seconds: int, window_seconds: int) -> int:
    """Record a failed attempt; lock the key if threshold reached.

    Returns remaining lockout seconds (0 if not yet locked).
    """
    now = time.time()
    with _lock:
        bucket = [t for t in _failures[key] if now - t < window_seconds]
        bucket.append(now)
        _failures[key] = bucket
        if len(bucket) >= max_attempts:
            _lockouts[key] = now + lockout_seconds
            _failures[key] = []
            return lockout_seconds
        return 0


def clear_failures(key: str) -> None:
    with _lock:
        _failures.pop(key, None)
        _lockouts.pop(key, None)
