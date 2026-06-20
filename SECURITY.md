# Labour Connect — Security Posture

This document maps the 16-layer enterprise security checklist to **what is
implemented in this codebase today** vs **what is infrastructure/Phase-2** work.

Legend: ✅ Implemented · 🟡 Partial · 🔜 Roadmap (infra/deploy or Phase-2)

---

## Layer 1 — Authentication ✅ (mostly)
| Item | Status | Where |
|------|--------|-------|
| OTP login (mock for MVP, Firebase-ready) | ✅ | `app/services/otp.py` |
| JWT access token (15 min) | ✅ | `core/security.py`, `core/config.py` |
| Refresh token (30 days), stored **hashed** in DB | ✅ | `models/refresh_token.py`, `services/tokens.py` |
| Refresh rotation (one-time use, reuse → 401) | ✅ | `services/tokens.py::rotate` |
| Logout (revoke) / Logout-all devices | ✅ | `POST /auth/logout`, `/auth/logout-all` |
| Account lockout after N failed OTPs | ✅ | `core/rate_limit.py` |
| OTP rate limiting | ✅ | `POST /auth/send-otp` |
| Device/login tracking (UA + IP on token) | 🟡 | stored on `refresh_tokens`; no UI yet |
| Real Firebase OTP / SMS provider | 🔜 | swap `services/otp.py` when `OTP_MOCK=false` |

**Verified:** refresh rotation works; reusing an old refresh → 401; 6th OTP send → 429.

## Layer 2 — Authorization (RBAC) ✅
- Roles: `customer`, `worker`, `admin` (super-admin = an admin; extend enum if needed).
- Route guards: `require_customer/worker/admin` in `app/api/deps.py`.
- Ownership checks (IDOR defence): customers can only act on their own bookings;
  workers only on bookings assigned to them (`routes/customer.py`, `routes/worker.py`).

## Layer 3 — API Security 🟡
| Item | Status |
|------|--------|
| JWT verification middleware/deps | ✅ |
| Rate limiting (auth endpoints) | ✅ (in-memory; move to Redis for multi-instance) |
| Request/response validation (Pydantic) | ✅ |
| API versioning (`/api/v1`) | ✅ |
| Secure headers (HSTS, X-Frame, X-Content-Type, CSP, Referrer-Policy, Permissions-Policy) | ✅ `core/middleware.py` |
| CORS allow-list | ✅ `core/config.py` |
| HTTPS only / HSTS preload | 🔜 terminate TLS at Nginx/ALB in prod |
| Global per-IP rate limit / API gateway / WAF | 🔜 Nginx `limit_req` or AWS WAF |

## Layer 4 — Input Validation ✅
- Pydantic models validate every request body + length limits.
- **XSS/HTML-injection sanitisation** on all free-text (`name`, `bio`, `notes`,
  `address`, `comment`, `service_area`, category name) via `core/sanitize.py`.
- SQL injection prevented by SQLAlchemy ORM (parameterised) — no raw SQL.
- **Verified:** `<script>alert(1)</script>Amit` is stored as `alert(1)Amit` (tags stripped).

## Layer 5 — Database Security 🟡
| Item | Status |
|------|--------|
| SQLAlchemy ORM + parameterised queries | ✅ |
| Migrations (Alembic) | ✅ |
| Least-privilege DB role | 🔜 create app role without DDL/superuser in prod |
| Read/write split | 🔜 add read replica + routing at scale |
| Encryption at rest + encrypted backups | 🔜 RDS encryption / `pg_dump` + age/gpg |

## Layer 6 — Sensitive Data Protection 🟡
- Secrets via env vars only (no hardcoding); `SECRET_KEY`, DB creds, admin creds in `.env`.
- Refresh tokens stored as SHA-256 hashes (DB leak ≠ usable tokens).
- Passwords (admin) hashed with bcrypt.
- 🔜 AES-256 field encryption for Aadhaar/PAN numbers + data masking in responses
  (add a SQLAlchemy `TypeDecorator` with Fernet/KMS); key rotation via AWS KMS / Vault.

## Layer 7 — File Upload Security ✅ (MVP) / 🔜 (prod storage)
- `POST /uploads/kyc` (worker-only) validates: allowed MIME, **magic-byte sniffing**
  (content must match declared type), size ≤ 5 MB, random UUID filename. `services/uploads.py`.
- Mobile KYC screen uploads via this endpoint, then saves the returned URL.
- 🔜 Replace local disk with **private S3** (SSE + signed URLs) and **ClamAV** virus scan.

## Layer 8 — Mobile App Security 🟡
| Item | Status |
|------|--------|
| Secure token storage (`flutter_secure_storage`, Android EncryptedSharedPrefs) | ✅ |
| Auto token refresh + single-flight + logout on failure | ✅ `core/network/dio_client.dart` |
| SSL pinning | 🔜 add `dio` `badCertificateCallback` / pinning cert |
| Root/jailbreak/emulator detection | 🔜 `freerasp` / `flutter_jailbreak_detection` |
| Code obfuscation, disable debug in prod | 🔜 `flutter build apk --obfuscate --split-debug-info` |
| Biometric unlock, screenshot block on KYC | 🔜 `local_auth`, `flutter_windowmanager` |

## Layer 9 — Admin Panel Security 🟡
| Item | Status |
|------|--------|
| **Audit logs** (login-gated mutations: verify/suspend/block/delete/category/booking/review) | ✅ `services/audit.py`, `GET /admin/audit-logs` |
| Session via short-lived JWT + refresh | ✅ |
| MFA / 2FA (TOTP) | 🔜 add `pyotp` enrolment + verify on admin login |
| IP allow-list / login alerts | 🔜 middleware + email/Slack webhook |
**Verified:** admin actions write audit rows with actor name + action + IP.

## Layer 10 — Cloud Security 🔜 (infra)
VPC + private subnets, security groups, IAM least-privilege, S3 bucket policies,
WAF, AWS Shield. See `SCALING.md` for the target topology. Not codeable here.

## Layer 11 — Network Security 🔜 (infra)
TLS 1.3 everywhere, firewall rules, admin VPN/bastion, network segmentation.
App is ready behind a TLS-terminating reverse proxy (HSTS header already sent).

## Layer 12 — Logging & Monitoring 🟡
- App + access logs via Uvicorn; audit log table for admin actions.
- 🔜 Sentry (errors), Prometheus + Grafana (metrics), alerting on failed-login/OTP spikes.
  FastAPI integrates with `sentry-sdk` and `prometheus-fastapi-instrumentator`.

## Layer 13 — Fraud Detection 🟡
- KYC verification flow (admin approve/reject) ✅; phone verification via OTP ✅;
  review only allowed on **completed** bookings by the **owning** customer ✅ (anti fake-review).
- 🔜 Device fingerprinting, duplicate-account detection, velocity rules on bookings.

## Layer 14 — Backup & DR 🔜 (infra)
Daily encrypted backups, multi-region storage, restore drills. Target **RPO < 24 h,
RTO < 4 h**. With RDS: automated snapshots + PITR + cross-region copy.

## Layer 15 — DevSecOps 🔜 (pipeline)
Secret scanning (gitleaks), dependency scan (`pip-audit`, `npm audit`), SAST (Bandit,
SonarQube), DAST (OWASP ZAP), container scan (Trivy) in GitHub Actions. A starter
workflow is the recommended next addition.

## Layer 16 — Compliance 🔜
Privacy policy, T&C, consent tracking, data-retention + deletion (DPDP/GDPR
"right to erasure" — `DELETE /admin/users/{id}` already hard-deletes). Add consent
timestamps to `users` and a retention job.

---

## OWASP Top 10 (2021) coverage
| Risk | Mitigation |
|------|-----------|
| A01 Broken Access Control | RBAC guards + ownership checks (IDOR) |
| A02 Cryptographic Failures | bcrypt passwords, hashed refresh tokens, TLS/HSTS, (KMS field-enc 🔜) |
| A03 Injection | ORM/parameterised queries + input sanitisation |
| A04 Insecure Design | layered auth, least privilege, rate limits |
| A05 Security Misconfiguration | secure headers, env-based secrets, CORS allow-list |
| A06 Vulnerable Components | pinned deps; `pip-audit`/`npm audit` 🔜 in CI |
| A07 Auth Failures | OTP lockout, rate limiting, short tokens, rotation, revoke |
| A08 Integrity Failures | signed JWTs, magic-byte file validation; supply-chain scan 🔜 |
| A09 Logging/Monitoring | audit logs ✅; Sentry/Prometheus 🔜 |
| A10 SSRF | no server-side URL fetching of user input |

## Config knobs (backend `.env`)
```
SECRET_KEY=<long-random>
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=30
OTP_SEND_MAX_PER_WINDOW=5
OTP_MAX_FAILED_ATTEMPTS=5
LOCKOUT_SECONDS=900
UPLOAD_MAX_BYTES=5242880
```

## Production hardening checklist (before launch)
- [ ] Real `SECRET_KEY` + rotate admin password; `OTP_MOCK=false` with real SMS
- [ ] PostgreSQL (not SQLite) with least-privilege app role + TLS
- [ ] TLS termination + HSTS preload at Nginx/ALB; force HTTPS
- [ ] Move rate-limit store to Redis (multi-instance correctness)
- [ ] Private S3 + SSE + AV scan for KYC; drop local disk storage
- [ ] AES-256 field encryption for Aadhaar/PAN + masked responses
- [ ] Admin 2FA (TOTP) + IP allow-list
- [ ] Sentry + Prometheus/Grafana + alerts
- [ ] CI security gates (gitleaks, pip-audit, npm audit, Bandit, Trivy)
- [ ] Mobile: SSL pinning, obfuscation, root/emulator detection
- [ ] Backups: automated, encrypted, cross-region, tested restore
