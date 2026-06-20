# Deploy backend to the cloud + send APK to client

Goal: client kahin se bhi app test kar sake. Iske liye backend internet pe
(Render) deploy hoga, aur APK us public URL pe point karega.

---

## PART 1 — Code GitHub pe daalo

> Maine repo locally `git init` + commit kar diya hai. Bas GitHub pe push karna hai.

1. https://github.com/new pe ek **naya repo** banao (e.g. `labour-connect`).
   - **Private** rakho. README/gitignore add **mat** karo (already hai).
2. Apne PC pe (is project folder mein) terminal kholo aur chalao
   (`<URL>` ko apne repo URL se badlo):
   ```powershell
   cd "F:\Labour App"
   git remote add origin https://github.com/<tumhara-username>/labour-connect.git
   git branch -M main
   git push -u origin main
   ```
   - Push ke time GitHub login maangega → GitHub Desktop already installed hai,
     ya browser se authorize ho jayega.

## PART 2 — Render pe deploy

1. https://render.com pe **GitHub se sign up** karo (free).
2. Dashboard → **New +** → **Blueprint**.
3. Apna `labour-connect` repo connect/select karo.
4. Render `render.yaml` padh lega — ek **web service** + ek **Postgres** dikhega.
   **Apply / Create** dabao.
5. ~5-10 min mein deploy hoga. Web service ka URL milega, jaise:
   **`https://labour-connect-api.onrender.com`**
6. Test: browser mein `https://labour-connect-api.onrender.com/health`
   → `{"status":"healthy"}` aana chahiye.
   (Free plan: pehli request ke baad 15 min idle rehne par "sleep" ho jaata hai;
   agli request 30-50s slow hoti hai — ye normal hai.)

7. **Ye URL mujhe bhej do** → main APK is URL pe rebuild kar dunga.

### Admin panel client/khud dekhne ke liye (optional)
Render pe ek aur **Static Site** bana sakte ho admin ke liye:
- Root dir: `admin`, Build: `npm install && npm run build`, Publish dir: `dist`
- Env: `VITE_API_BASE_URL = https://labour-connect-api.onrender.com/api/v1`

---

## PART 3 — APK client ko bhejo (Diawi)

1. Maine final APK bana ke path bata dunga
   (`F:\Labour App\mobile\build\app\outputs\flutter-apk\app-release.apk`).
2. https://www.diawi.com kholo → APK file **drag & drop** → Upload.
3. Ek **link + QR** milega → wo client ko WhatsApp/email kar do.
4. Client phone pe link khole → Install → "unknown sources" allow → app chalu.
   - OTP abhi mock hai → koi number + OTP **123456** se login.

---

## Baad mein (real launch)
- `OTP_MOCK=false` + real SMS (Firebase/MSG91) → asli OTP.
- KYC files local disk ki jagah S3 pe (SECURITY.md dekho).
- Render free Postgres ~30 din baad expire ho sakta hai — paid ya naya banана padega.
