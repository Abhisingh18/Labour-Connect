# Labour Connect — Mobile App (Flutter)

A single Flutter app with two roles — **Customer** and **Worker** — for the
Labour Connect service marketplace. Talks to the FastAPI backend in `../backend`.

## Highlights
- **Material 3** custom design system (Plus Jakarta Sans + Inter, indigo/amber brand)
- **Riverpod** state management + clean feature-first architecture
- **go_router** with role-aware redirects & session restore
- Polished UX: shimmer skeletons, empty/error states, animations, pull-to-refresh,
  OTP input, charts (fl_chart), bottom-sheet flows
- Secure JWT storage (`flutter_secure_storage`), centralised Dio client with
  auto token injection + global 401 handling

## Prerequisites
- **Flutter 3.27+** (stable) / Dart 3.6+
- The backend running and reachable (see `../backend/README.md`)

## First-time setup
This repo ships the `lib/`, `pubspec.yaml` and assets. Generate the native
platform folders (android/ios), then fetch packages:

```bash
cd mobile
flutter create .          # adds android/ ios/ etc. — keeps lib/ & pubspec intact
flutter pub get
```

## Run

Point the app at your backend with `--dart-define`. The base URL differs by target:

```bash
# Android emulator (host machine is 10.0.2.2) — this is the default
flutter run

# iOS simulator / desktop / web
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1

# Physical device (use your machine's LAN IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/api/v1
```

> Ensure your device/emulator can reach the backend. For Android release builds,
> confirm the `INTERNET` permission and (for plain http) a network-security config.

## Test login (mock OTP)
The backend runs OTP in mock mode for the MVP:
- Enter any 10-digit number → OTP screen
- The dev OTP **`123456`** is shown and pre-filled automatically
- Pick **Customer** or **Worker** on the welcome screen to try each flow

### Worker happy path
Worker login → **KYC verification** (upload Aadhaar + selfie) → wait for admin to
approve (use the Admin panel or Swagger) → toggle **Online** → receive booking
requests → Accept → Mark completed (enter amount) → see it in **Earnings**.

### Customer happy path
Customer login → browse **categories** → pick a worker → **Book service**
(date/time/address) → track under **Bookings** → after completion, **Rate & review**.

## Project structure
```
lib/
  main.dart                 app entry (ProviderScope)
  app.dart                  MaterialApp.router + session bootstrap
  core/
    config/env.dart         API base URL (dart-define)
    theme/                  colors, typography, Material 3 theme
    network/                Dio client + error normalisation
    storage/                secure token storage
    router/                 go_router + role-aware redirects
    utils/                  validators, formatters, helpers
    widgets/                buttons, fields, avatar, badges, states, ratings
    providers.dart          Dio / storage Riverpod providers
  features/
    auth/                   splash, role select, phone, OTP, auth controller
    customer/               home, search, worker detail, booking, history, profile
    worker/                 dashboard, requests, earnings, KYC, profile, edit
    shared/                 cross-role models & widgets
```

## Notes / Phase-2 hooks
- **File uploads (KYC):** the backend stores document *URLs*. This MVP sends a
  stand-in path; wire an object-storage upload (S3/Firebase/Cloudinary) and send
  the real URL — see `worker_kyc_screen.dart`.
- **Push notifications, live tracking, in-app payments, chat** are intentionally
  out of scope for the MVP.
- **Maps / nearby:** the worker search already supports `lat`/`lng` distance
  sorting on the backend; plug in `geolocator` to pass the device location.
