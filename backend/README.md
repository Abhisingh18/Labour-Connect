# Labour Connect — Backend API

FastAPI + PostgreSQL backend for the Labour Connect service marketplace
(customer, worker, and admin roles). JWT auth with **mock OTP** for the MVP
(swap in Firebase/MSG91 later without touching the API layer).

## Stack
- FastAPI 0.111 · SQLAlchemy 2.0 · Alembic · PostgreSQL 16
- JWT (python-jose) · bcrypt (admin passwords)
- Pydantic v2 · Swagger/OpenAPI docs

## Quick start (Docker — recommended)
```bash
cp .env.example .env
docker compose up --build
```
The API container waits for Postgres, runs migrations, seeds data, then serves on
**http://localhost:8000**.

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Quick start (local, without Docker)
Requires a running PostgreSQL. Then:
```bash
python -m venv .venv
. .venv/Scripts/activate        # Windows
# source .venv/bin/activate     # macOS/Linux
pip install -r requirements.txt
cp .env.example .env            # set POSTGRES_HOST=localhost
alembic upgrade head
python -m app.db.seed
uvicorn app.main:app --reload
```

## Seeded data
- **Admin**: `admin@labourconnect.in` / `Admin@123` (from `.env`)
- **11 categories**: Plumber, Electrician, Carpenter, Painter, Mason, Labour,
  AC Repair, Appliance Repair, Cleaning, Driver, Packers & Movers

## Authentication
| Role | How to log in |
|------|---------------|
| Customer / Worker | `POST /auth/send-otp` → `POST /auth/verify-otp` (dev OTP = `123456`) |
| Admin | `POST /auth/admin/login` (email + password) |

Send `Authorization: Bearer <access_token>` on protected routes.

### Mock OTP
With `OTP_MOCK=true` (default), any phone accepts code `123456` and `/send-otp`
returns the code in the `dev_otp` field for easy testing. Set `OTP_MOCK=false`
and implement the real provider in `app/services/otp.py` for production.

## API surface
- `auth/*` — send/verify OTP, admin login, current user
- `categories` — public active categories
- `profile` — view/update own user profile (any role)
- `customer/*` — search workers, worker detail, create/cancel bookings, reviews
- `worker/*` — profile, KYC, availability, booking accept/reject/complete, earnings, reviews
- `admin/*` — dashboard, user/worker management, KYC verify, categories, bookings, reviews

Full interactive reference at `/docs`.

## Booking lifecycle
`pending` → worker `accept` → `accepted` → worker `complete` (sets amount) →
`completed` → customer can review. Customer may `cancel` while pending/accepted;
worker may `reject` while pending.

## Tests
End-to-end happy-path smoke test (runs on in-memory SQLite, no DB needed):
```bash
python smoke_test.py
```

## Project layout
```
app/
  core/        config, security (JWT, hashing)
  db/          session, base, seed
  models/      SQLAlchemy ORM models
  schemas/     Pydantic request/response models
  crud/        repository layer (DB access)
  services/    OTP provider (mock for MVP)
  api/
    deps.py    auth dependencies & role guards
    routes/    auth, categories, profile, customer, worker, admin
alembic/       migrations
```
