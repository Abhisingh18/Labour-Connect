"""In-process end-to-end smoke test over SQLite (no Postgres/Docker needed).

Run: ./.venv/Scripts/python.exe smoke_test.py
Exercises the full happy path across customer, worker, and admin roles.
"""
import os

os.environ["POSTGRES_HOST"] = "localhost"

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.base_class import Base
import app.models  # noqa: F401  (populate registry)

# ---- SQLite test DB wired into the app's get_db dependency ----
engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestSession = sessionmaker(bind=engine, autoflush=False, autocommit=False)
Base.metadata.create_all(engine)

from app.db import session as session_mod

session_mod.SessionLocal = TestSession  # so seed.py uses the test DB

from fastapi.testclient import TestClient

from app.api.deps import get_db
from app.db.seed import seed
from app.main import app


def override_get_db():
    db = TestSession()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db
seed()

client = TestClient(app)
P = "/api/v1"
passed = 0


def check(label, cond):
    global passed
    assert cond, f"FAILED: {label}"
    passed += 1
    print(f"  ok  {label}")


print("\n== Auth ==")
r = client.post(f"{P}/auth/send-otp", json={"phone": "9990001111"})
check("send otp returns dev code", r.json().get("dev_otp") == "123456")

r = client.post(f"{P}/auth/verify-otp", json={"phone": "9990001111", "otp": "123456", "role": "customer", "name": "Ravi"})
check("customer signup", r.status_code == 200 and r.json()["is_new_user"])
cust_token = r.json()["access_token"]
CUST = {"Authorization": f"Bearer {cust_token}"}

r = client.post(f"{P}/auth/verify-otp", json={"phone": "8880002222", "otp": "123456", "role": "worker", "name": "Sunil"})
check("worker signup", r.status_code == 200)
worker_token = r.json()["access_token"]
worker_uid = r.json()["user_id"]
WORK = {"Authorization": f"Bearer {worker_token}"}

r = client.post(f"{P}/auth/admin/login", json={"email": "admin@labourconnect.in", "password": "Admin@123"})
check("admin login", r.status_code == 200)
ADMIN = {"Authorization": f"Bearer {r.json()['access_token']}"}

print("\n== Categories ==")
r = client.get(f"{P}/categories")
cats = r.json()
check("default categories seeded", len(cats) >= 11)
plumber_id = next(c["id"] for c in cats if c["name"] == "Plumber")

print("\n== Worker onboarding ==")
r = client.put(f"{P}/worker/profile", headers=WORK, json={"category_id": plumber_id, "experience": 5, "bio": "Expert plumber", "service_area": "Sector 21"})
check("worker sets profile", r.status_code == 200 and r.json()["experience"] == 5)

r = client.put(f"{P}/worker/availability", headers=WORK, json={"is_available": True})
check("unverified worker blocked from going online", r.status_code == 400)

r = client.post(f"{P}/worker/kyc", headers=WORK, json={"aadhaar_url": "http://x/a.png", "selfie_url": "http://x/s.png"})
check("worker submits kyc -> pending", r.json()["kyc_status"] == "pending")

print("\n== Admin verifies worker ==")
r = client.get(f"{P}/admin/workers", headers=ADMIN, params={"kyc_status": "pending"})
check("admin sees pending kyc worker", any(w["user_id"] == worker_uid for w in r.json()))

r = client.post(f"{P}/admin/workers/{worker_uid}/verify", headers=ADMIN, json={"approve": True})
check("admin approves worker", r.json()["is_verified"] is True)

r = client.put(f"{P}/worker/availability", headers=WORK, json={"is_available": True})
check("verified worker goes online", r.status_code == 200 and r.json()["is_available"])

print("\n== Customer search + book ==")
r = client.get(f"{P}/customer/workers", headers=CUST, params={"category_id": plumber_id})
check("customer finds worker", len(r.json()) == 1 and r.json()[0]["user_id"] == worker_uid)

r = client.post(f"{P}/customer/bookings", headers=CUST, json={"worker_id": worker_uid, "category_id": plumber_id, "booking_date": "2026-07-01", "booking_time": "10:30:00", "address": "12 MG Road", "notes": "Leaking tap"})
check("customer creates booking", r.status_code == 201 and r.json()["status"] == "pending")
booking_id = r.json()["id"]

print("\n== Worker handles booking ==")
r = client.get(f"{P}/worker/bookings", headers=WORK, params={"status": "pending"})
check("worker sees pending request", any(b["id"] == booking_id for b in r.json()))

r = client.post(f"{P}/worker/bookings/{booking_id}/accept", headers=WORK)
check("worker accepts", r.json()["status"] == "accepted")

r = client.post(f"{P}/worker/bookings/{booking_id}/complete", headers=WORK, params={"amount": 800})
check("worker completes with amount", r.json()["status"] == "completed" and r.json()["amount"] == 800)

print("\n== Review + earnings ==")
r = client.post(f"{P}/customer/bookings/{booking_id}/review", headers=CUST, json={"rating": 5, "comment": "Great work"})
check("customer reviews", r.status_code == 201)

r = client.post(f"{P}/customer/bookings/{booking_id}/review", headers=CUST, json={"rating": 4})
check("duplicate review rejected", r.status_code == 409)

r = client.get(f"{P}/customer/workers/{worker_uid}", headers=CUST)
check("worker rating updated to 5", r.json()["rating"] == 5.0 and r.json()["rating_count"] == 1)

r = client.get(f"{P}/worker/earnings", headers=WORK)
check("worker earnings reflect job", r.json()["total_earnings"] == 800 and r.json()["completed_jobs"] == 1)

print("\n== Admin dashboard + auth guards ==")
r = client.get(f"{P}/admin/dashboard", headers=ADMIN)
d = r.json()
check("dashboard totals", d["total_customers"] == 1 and d["total_workers"] == 1 and d["completed_bookings"] == 1 and d["total_revenue"] == 800)

r = client.get(f"{P}/admin/dashboard", headers=CUST)
check("customer blocked from admin route", r.status_code == 403)

r = client.get(f"{P}/worker/profile")
check("missing token rejected", r.status_code == 401)

print(f"\nALL {passed} CHECKS PASSED")
