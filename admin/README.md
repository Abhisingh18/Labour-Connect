# Labour Connect — Admin Panel (React)

Web admin dashboard for the Labour Connect marketplace. Built with
**React + TypeScript + Vite + Material UI**, talking to the FastAPI backend.

## Features
- **Secure admin login** (email/password → JWT, persisted, auto session restore, 401 → re-login)
- **Dashboard** — customers, workers, bookings, revenue stats + bar/pie charts (Recharts)
- **Workers** — filter by KYC status, **approve / reject KYC**, suspend / reinstate
- **Customers** — block / unblock / delete
- **Categories** — full CRUD with active toggle + icon picker (matches the app icons)
- **Bookings** — filter by status, cancel, reassign to a verified worker
- **Reviews** — hide / restore inappropriate reviews (recomputes worker ratings)
- Polished UX: responsive sidebar layout, confirm dialogs, toasts, loading/empty/error states

## Stack
React 18 · TypeScript · Vite 5 · MUI 5 · TanStack Query 5 · React Router 6 · Axios · Recharts

## Prerequisites
- Node 18+
- Backend running (see `../backend/README.md`) with an admin seeded

## Setup & run
```bash
cd admin
cp .env.example .env        # set VITE_API_BASE_URL if backend isn't on localhost:8000
npm install
npm run dev                 # http://localhost:5173
```

`.env`:
```
VITE_API_BASE_URL=http://localhost:8000/api/v1
```

## Login
Use the seeded admin (from the backend `.env`):
```
admin@labourconnect.in  /  Admin@123
```

## Scripts
| Command | Description |
|---------|-------------|
| `npm run dev` | Start dev server (HMR) |
| `npm run build` | Type-check (`tsc`) + production build to `dist/` |
| `npm run preview` | Preview the production build |
| `npm run typecheck` | Type-check only |

## Typical workflow
1. A worker signs up in the mobile app and submits KYC.
2. Here under **Workers → Pending KYC**, review and **Approve** them.
3. The worker can now go **Online** in the app and receive bookings.
4. Monitor everything from **Dashboard** / **Bookings**; moderate **Reviews** as needed.

## Project structure
```
src/
  api/          axios client, typed services, shared types
  auth/         AuthContext + ProtectedRoute
  components/   Layout (sidebar/topbar), StatCard, StatusChip, dialogs, toasts, feedback
  hooks/        TanStack Query hooks for every endpoint
  pages/        Login, Dashboard, Workers, Customers, Categories, Bookings, Reviews
  theme.ts      MUI theme (brand colors + typography)
  main.tsx      providers (Theme, Query, Router, Auth, Toast)
```

## Notes
- The build emits a single ~1 MB JS chunk (MUI + Recharts). Fine for an internal
  panel; add `manualChunks` / dynamic imports if you want to trim it.
- CORS: the backend already allows `http://localhost:5173` by default
  (`BACKEND_CORS_ORIGINS`). Add your deployed admin URL there for production.
