# BajGo — Bajaaj Ride & Delivery Platform

On-demand Bajaaj (three-wheel auto-rickshaw) rides and deliveries for **Garowe, Puntland, Somalia**.
The same drivers serve both services. Somali first, English second.

**baj-go.com · info@baj-go.com**

> **Status: in active development.** This README states plainly what runs today and what
> does not. Nothing here is described as finished unless it has been verified.

---

## Repository layout

| Folder | What it is | Stack |
|---|---|---|
| `backend/` | API, real-time dispatch, pricing, payments, ledger | NestJS 11 · TypeScript · Node 22 |
| `customer-app/` | BajGo Customer app (Android/iOS) | Flutter 3.24 |
| `driver-app/` | BajGo Driver app (Android/iOS) | Flutter 3.24 |
| `admin-dashboard/` | Super Admin dashboard, 27 modules | Next.js 15 · TypeScript |
| `website/` | Public bilingual website | Next.js 15 · TypeScript |
| `database/` | SQL migrations (PostgreSQL 16 + PostGIS) | `.sql` |
| `brand/` | Approved logo, app icons, colours, fonts, messaging | — |
| `docs/` | Architecture, API contract, design system, build brief | — |
| `deployment/` | Docker Compose, Dockerfiles, deployment guide | — |

Start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), then
[`docs/API.md`](docs/API.md) (the contract every app follows) and
[`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md).

---

## Core business rules

- **Fare:** `max($1.00, $0.50 × road_km)` rounded up to the nearest 10¢ — i.e. **$1 per 2 km**.
  1 km → $1.00 · 2 km → $1.00 · 3 km → $1.50 · 4 km → $2.00 · 6 km → $3.00 · 10 km → $5.00.
  Set per service and per zone from the admin dashboard; it is **never hard-coded in an app**.
- **Customer login:** full name + phone number + OTP. No email, no password.
- **One driver, two services.** A Bajaaj driver takes either a passenger ride or a delivery.
- **Money** is stored as integer USD cents in a double-entry ledger. Commission is a ledger
  entry, not a derived number.
- **Existing bookings keep their quoted fare** when pricing changes.

---

## Android demo APKs

The two demo APKs are built by GitHub Actions, not committed to the repo.

1. Open the **Actions** tab → **Android APKs** → **Run workflow** (branch `main`).
2. When it finishes, download the artifacts **BajGo-Customer-Demo** and **BajGo-Driver-Demo**.
3. Each artifact is a `.zip` containing the `.apk` plus `SHA256SUMS.txt`.

Demo APKs are built with `--dart-define=DEMO=true`: the app runs against a **simulated backend
inside the app itself**. No server is needed, no booking is real, no money moves. The demo
banner is visible in the app at all times.

To build APKs that talk to a real backend, run the workflow with the **api_base_url** input set
(e.g. `https://api.baj-go.com`); it then also produces `BajGo-customer-Live.apk` and
`BajGo-driver-Live.apk`.

See [`docs/TESTING.md`](docs/TESTING.md) for install steps on Samsung, demo accounts and the
end-to-end test script.

---

## Running the platform locally

```bash
# 1. Infrastructure (PostgreSQL + PostGIS, Redis)
cd deployment && docker compose up -d postgres redis

# 2. Backend
cd ../backend
cp .env.example .env
npm install
npm run db:migrate
npm run seed:demo
npm run start:dev          # http://localhost:4000/v1 , OpenAPI at /docs

# 3. Admin dashboard
cd ../admin-dashboard && npm install && npm run dev     # http://localhost:3001

# 4. Website
cd ../website && npm install && npm run dev             # http://localhost:3000
```

Point the phone apps at your machine with
`--dart-define=DEMO=false --dart-define=API_BASE_URL=http://<your-lan-ip>:4000/v1`.

---

## Security

No secrets are committed. Every service reads configuration from the environment and ships an
`.env.example` listing the variables it needs. Test accounts, the fixed demo OTP and the data
reset endpoint exist **only** when `APP_ENV` is not `production`.

---

© 2026 BajGo. Brand identity and platform by Somali Digital.
