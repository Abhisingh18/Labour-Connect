# Labour Connect app — apne Android phone pe kaise chalayein

> Flutter app hai (Expo/QR nahi chalega). Phone pe chalane ke liye Flutter SDK
> install karke APK banana padega. Niche pura process hai.

PC ka Wi-Fi IP: **192.168.0.114**  → backend phone se: `http://192.168.0.114:8000/api/v1`

---

## ⭐ SABSE AASAN: Flutter Web (phone browser se, IP daalke — koi APK/USB nahi)

Sirf **Flutter install** karo (Android Studio ki zarurat NAHI). Fir:
```powershell
cd "f:\Labour App\mobile"
flutter create .
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 9000 --dart-define=API_BASE_URL=http://192.168.0.114:8000/api/v1
```
Ab **phone ke Chrome** mein kholo: **http://192.168.0.114:9000**
- ProtonVPN band, phone+PC same Wi-Fi
- Number + OTP `123456` se test
- Note: web pe kuch native cheezein (camera/secure storage) thodi alag chalti hain,
  par login/booking/worker ke saare flows test ho jaayenge.

> Pakka "asli app" (camera, secure storage, performance) chahiye toh niche wala
> APK / USB tareeka use karo (Android Studio chahiye).

---

---

## STEP 0 — Zaroori cheezein
- Android phone + USB cable (ya same Wi-Fi)
- PC aur phone **same Wi-Fi** pe hon
- **ProtonVPN band** rakho (warna phone↔PC block ho jaata hai)

## STEP 1 — Flutter SDK install (F: drive pe, C: pe nahi)
Flutter sirf ek folder hai — kisi bhi drive pe rakh sakte ho.
1. Download: https://docs.flutter.dev/get-started/install/windows (Windows zip)
2. Extract karo yahan: `F:\dev\flutter` (path mein space na ho)
3. PATH mein add karo: Windows search → "environment variables" → Path → New →
   `F:\dev\flutter\bin`

## STEP 2 — Android Studio install (Android SDK + build tools ke liye)
Flutter akela APK nahi banata — Android SDK chahiye.
1. Android Studio install karo: https://developer.android.com/studio
2. SDK ki jagah badalni ho toh: Android Studio → Settings → Languages & Frameworks
   → Android SDK → "Android SDK Location" → `F:\dev\Android\Sdk` choose karo
3. SDK Manager se: **Android SDK Command-line Tools** + **SDK Platform** install karo
4. Terminal mein license accept: `flutter doctor --android-licenses` (saare `y`)

## STEP 3 — Sab sahi hai check karo
```powershell
flutter doctor
```
"Flutter" aur "Android toolchain" pe ✓ hona chahiye. (Chrome/VS Code optional.)

## STEP 4 — Project taiyaar karo
```powershell
cd "f:\Labour App\mobile"
flutter create .          # android/ folder banata hai (lib/ ko chhedta nahi)
flutter pub get
```

## STEP 5 — Firewall mein port 8000 kholo (ek baar)
PowerShell ko **Run as Administrator** se kholke:
```powershell
New-NetFirewallRule -DisplayName "Labour Connect 8000" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
```

## STEP 6 — Backend chal raha hai confirm karo
PC pe backend already chal raha hai (port 8000). Phone ke browser mein khol ke dekho:
`http://192.168.0.114:8000/health` → `{"status":"healthy"}` aana chahiye.
(Na aaye toh: same Wi-Fi? ProtonVPN band? firewall rule lagi?)

Backend band ho gaya ho toh PC pe:
```powershell
cd "f:\Labour App\backend"
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## STEP 7 — App phone pe chalao (2 me se koi 1 tareeka)

### Tareeka A — USB se direct (sabse aasan, recommended)
1. Phone pe **Developer Options** → **USB Debugging** ON karo
   (Settings → About phone → "Build number" 7 baar tap → fir Developer Options)
2. USB se phone PC se jodo, "Allow USB debugging" → Allow
3. Check: `flutter devices` (tumhara phone dikhna chahiye)
4. Chalao:
```powershell
cd "f:\Labour App\mobile"
flutter run --dart-define=API_BASE_URL=http://192.168.0.114:8000/api/v1
```
App phone pe install hokar khul jayega. Code change karke `r` dabao = hot reload.

### Tareeka B — APK banao aur phone pe daalo
```powershell
cd "f:\Labour App\mobile"
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.0.114:8000/api/v1
```
APK yahan banega:
`f:\Labour App\mobile\build\app\outputs\flutter-apk\app-release.apk`
Is file ko phone pe bhejo (USB/WhatsApp/Drive) → phone pe tap karke install
("unknown sources se install" allow karna padega).

## STEP 8 — Test karo
- Koi bhi 10-digit number daalo → OTP **123456** (auto-fill ho jayega)
- **Customer** banke: category chuno → worker → book karo
- **Worker** banke: KYC upload → fir admin panel se approve karo
  (admin: http://localhost:5173 PC pe, login `admin@labourconnect.in` / `Admin@123`)
  → worker Online → booking accept/complete

---

### iPhone pe?
iPhone ke liye **Mac + Xcode** chahiye — Windows pe iOS build nahi hota.
Android pe hi test karo abhi.

### Aam dikkatein
- App khulta hai par data nahi aata → backend IP galat / ProtonVPN ON / alag Wi-Fi / firewall
- `flutter doctor` mein Android ✗ → Android Studio + SDK + licenses pending
- "INSTALL_FAILED" → phone pe purana version uninstall karke dobara
