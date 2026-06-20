# Labour Connect — Scaling Guide (20k users)

You're right: **20k registered / 2k DAU / 200–500 peak concurrent / 500–1000
bookings’ day is comfortably a single-server workload.** This codebase is already
shaped for it. This doc maps your target architecture to what exists and what to
add, in order of impact.

## Target topology
```
            Flutter App  +  React Admin
                     │ HTTPS (TLS 1.3)
                     ▼
              Nginx (LB + TLS + rate-limit + static)
                     │
                     ▼
        Gunicorn + Uvicorn workers (FastAPI)   ← stateless, scale horizontally
              │            │            │
              ▼            ▼            ▼
           Redis      PostgreSQL    Object Storage (S3)
        (cache +     (primary +     (KYC docs, images)
         rate-limit   read replica
         + Celery     at scale)
         broker)
              │
              ▼
      Background workers (Celery/RQ)  ← SMS/OTP, FCM push, image processing
```

## Capacity math (sanity check)
- 2k DAU, peak 500 concurrent. Even at 5 req/user-action, that's a few hundred
  req/s **burst**, not sustained. A single 4-vCPU box running Gunicorn handles this.
- 500–1000 bookings/day = **< 1 write/sec average**. The DB is essentially idle;
  reads (worker search, listings) dominate → cache those.

## 1. App server — run it like production
Replace the single Uvicorn dev process with Gunicorn managing Uvicorn workers:
```bash
gunicorn app.main:app \
  -k uvicorn.workers.UvicornWorker \
  -w 4 --threads 2 \
  -b 0.0.0.0:8000 \
  --timeout 60 --max-requests 1000 --max-requests-jitter 100
```
Rule of thumb: `workers = 2 × vCPU + 1`. Stateless app → add boxes behind Nginx
when needed. **One caveat:** our in-memory rate limiter (`core/rate_limit.py`) is
per-process — with multiple workers/instances, **move it to Redis** (same interface,
swap the dict for Redis INCR + EXPIRE). Until then run `-w 1` or accept per-worker limits.

## 2. PostgreSQL — already indexed
Move off SQLite to Postgres (just unset `DATABASE_URL`, set `POSTGRES_*`). The
schema already has the indexes that matter at this scale:
- `bookings`: indexed on `customer_id`, `worker_id`, `status`
- `worker_profiles`: indexed on `category_id`; search filters on verified/available
- `users`: unique indexes on `phone`, `email`

At 20k users no sharding/partitioning is needed. Add a **read replica** only when
read latency climbs; route `GET` traffic to it. Connection pooling via `pool_pre_ping`
is on; add **PgBouncer** if you run many app instances.

## 3. Redis — the highest-leverage addition
Use it for three things (one dependency, big wins):
1. **Cache** hot reads: category list, worker search results (short TTL 30–60s).
   Wrap `crud.category.list_all` and `crud.worker.search` with a cache-aside helper.
2. **Distributed rate-limiting / OTP lockout** (replaces in-memory store).
3. **Celery broker** (below).

## 4. Background workers (Celery/RQ)
Anything slow or external must leave the request path:
- **OTP SMS send** (when `OTP_MOCK=false`) — fire-and-forget task.
- **FCM push notifications** (new booking → worker, status change → customer).
- **Image processing / AV scan** for KYC uploads.
- **Rating recompute** could be async on review create.
```
celery -A app.worker worker --concurrency=4
```
(Add `app/worker.py` with a Celery app bound to the Redis broker.)

## 5. Object storage (S3)
KYC docs + profile images go to **private S3** (not the app disk). The upload
endpoint already centralises this in `services/uploads.py` — swap the local write
for `boto3.put_object` with server-side encryption, return a key, serve via signed URLs.

## 6. Nginx (LB + edge)
- TLS 1.3 termination, HTTP→HTTPS redirect (HSTS header already emitted by the app).
- `limit_req` zone for a global per-IP throttle (defence beyond app rate-limits).
- Serve the built React admin (`admin/dist`) as static; proxy `/api` to Gunicorn.
- gzip/brotli; cache static assets.

## Single-box vs scale-out
| Stage | Setup | Good for |
|-------|-------|----------|
| **MVP / launch** | 1 box: Nginx + Gunicorn(4w) + Postgres + Redis; S3 for files | up to ~20–50k users |
| **Growth** | Separate DB (managed RDS) + Redis (ElastiCache); 2–3 app boxes behind ALB; Celery workers | 100k+ |
| **Scale** | Read replica + PgBouncer, autoscaling app tier, CDN for assets | 500k+ |

## What to add to this repo next (priority order)
1. `gunicorn` to `requirements.txt` + a `gunicorn.conf.py` (prod run).
2. Redis-backed `rate_limit` + cache-aside on category/worker reads.
3. Celery app + tasks for SMS + FCM push.
4. S3 storage backend in `services/uploads.py`.
5. `docker-compose.prod.yml`: nginx + api(gunicorn) + postgres + redis + worker.

> Bottom line: the code is already “single-server for 20k” ready. The only
> correctness change required before horizontal scale-out is **moving the rate
> limiter to Redis**; everything else (replica, Celery, S3, CDN) is additive.
