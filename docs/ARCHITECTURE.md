# BajGo — System Architecture

Version 1.0 · Stage 1 · October 2026

BajGo is one platform with five surfaces. Every surface talks to one backend, one PostgreSQL database and one real-time event bus. The same Bajaaj driver serves both **Ride** and **Delivery**.

```
┌─────────────────┐  ┌─────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  Customer App   │  │   Driver App    │  │  Website (SSR)   │  │ Admin Dashboard  │
│  Flutter        │  │   Flutter       │  │  Next.js 15      │  │  Next.js 15      │
└────────┬────────┘  └────────┬────────┘  └────────┬─────────┘  └────────┬─────────┘
         │ HTTPS + WSS        │ HTTPS + WSS        │ HTTPS               │ HTTPS + WSS
         └──────────┬─────────┴────────────────────┴─────────────────────┘
                    ▼
         ┌──────────────────────────────────────────────────────────┐
         │  BajGo API  (NestJS 11 · TypeScript · Node 22)           │
         │  REST /v1 · Socket.IO /rt · OpenAPI at /docs             │
         │  Modules: auth · users · drivers · vehicles · zones ·    │
         │  pricing · bookings · dispatch · tracking · payments ·   │
         │  wallets · promotions · notifications · support · cms ·  │
         │  admin · audit · reports                                 │
         └───────┬───────────────────┬───────────────────┬──────────┘
                 ▼                   ▼                   ▼
      ┌──────────────────┐ ┌──────────────────┐ ┌────────────────────────┐
      │ PostgreSQL 16    │ │ Redis 7          │ │ External providers     │
      │ + PostGIS 3.4    │ │ cache · queues   │ │ (behind abstractions)  │
      │ source of truth  │ │ (BullMQ) · pub/  │ │ SMS/OTP · Maps/Routing │
      │                  │ │ sub · geo index  │ │ Mobile money · FCM     │
      └──────────────────┘ └──────────────────┘ └────────────────────────┘
```

## 1. Technology decisions

| Layer | Choice | Why |
|---|---|---|
| Backend | **NestJS 11 + TypeScript**, Node 22 | Modular (one Nest module per admin module), typed end-to-end, testable, runs anywhere Node runs. Chosen over Laravel for this build so every API could be built *and verified* in the build environment; the module boundaries map 1:1 to the brief so a Laravel port is mechanical if ever wanted. |
| Database | **PostgreSQL 16 + PostGIS** | Relational integrity for money and bookings; PostGIS for geofences, nearest-driver queries and service zones. |
| ORM / migrations | **Drizzle ORM + drizzle-kit** | Plain-SQL migrations committed to git; no binary engines; PostGIS via SQL. |
| Cache / queues / realtime fan-out | **Redis 7** with BullMQ | Dispatch timers, OTP rate limits, driver geo index (`GEOADD`), Socket.IO adapter for multi-instance. |
| Real-time | **Socket.IO** (`/rt` namespace) | Driver location stream, booking status, admin live map. Falls back to long-polling on bad networks. |
| Mobile | **Flutter 3.24+**, Riverpod, go_router, Dio, socket_io_client, flutter_map | One codebase for Android & iOS; `flutter_map` (OpenStreetMap tiles by default) keeps map costs at zero until a Google/Mapbox key is configured. |
| Web + Admin | **Next.js 15 (App Router) + TypeScript + Tailwind** | SSR for SEO on the website; the admin reuses the same UI kit. |
| Maps / routing | Provider abstraction: `RoutingProvider` (OSRM public demo in dev → Google/Mapbox in prod), `GeocodingProvider`, map tiles chosen per app config | Garowe address data is thin; manual pin + landmark is first-class. |
| OTP / SMS | `SmsProvider` abstraction: `ConsoleSmsProvider` (dev), `HttpSmsProvider` (generic HTTP gateway, e.g. local aggregator), Twilio adapter | No fake OTP in production; dev test numbers are explicit and isolated. |
| Payments | `PaymentProvider` abstraction: `CashProvider`, `SandboxMobileMoneyProvider` (dev), stubs for EVC Plus / ZAAD / Sahal that fail closed until credentials exist | Nothing is claimed live until reconciled. |
| Push | Firebase Cloud Messaging via `PushProvider` (`ConsolePushProvider` in dev) | |
| Auth | Phone + OTP → short-lived JWT access token (15 min) + rotating refresh token (30 days) bound to a device record | No passwords for customers/drivers; admins use email + password + optional TOTP. |
| Infra | Docker Compose (api, web, admin, postgres, redis, worker); GitHub Actions for CI, APK builds and image builds | |
| Observability | Pino structured logs, OpenTelemetry hooks, `/health` + `/ready`, Sentry DSN optional | |

## 2. Monorepo layout

```
bajgo/
├── services/api/          NestJS backend (+ worker process for queues)
├── apps/customer/         Flutter customer app
├── apps/driver/           Flutter driver app
├── apps/web/              Next.js public website (bilingual, CMS-driven)
├── apps/admin/            Next.js super-admin dashboard
├── packages/brand/        Approved logo, icons, colours, fonts
├── packages/contracts/    OpenAPI spec + generated TS types shared by web/admin
├── infra/docker/          Compose files, Dockerfiles, nginx
├── docs/                  Architecture, database, API, deployment, manuals
└── .github/workflows/     ci.yml · android-apks.yml · docker-images.yml
```

## 3. Core domain model

- **User** — one row per person; `role` ∈ customer | driver | admin. Phone is the identity for customers and drivers.
- **Driver** — extends User: verification status (`pending → under_review → approved | rejected | suspended`), rating, availability (`offline | online | on_trip`), current vehicle.
- **Vehicle** — a Bajaaj: plate, BajGo fleet ID (`BG-0142`), colour/livery, photos, documents.
- **Booking** — one table for both services with `service` ∈ ride | delivery. Shared lifecycle; delivery adds sender/recipient/package fields and the recipient OTP.
- **FareQuote** — immutable snapshot of the pricing version and the computed fare at booking time. Bookings keep their quote even if pricing changes later.
- **PricingVersion** — versioned, effective-dated pricing rules; only admins write; every change audited.
- **DispatchOffer** — one row per driver offered a booking; carries the countdown, response and reason. Assignment is a single transactional `UPDATE … WHERE status='searching'` so two drivers can never win the same booking.
- **Payment / Transaction / LedgerEntry** — payments are intents against a provider; transactions are the settled facts; ledger entries are double-entry rows into customer, driver, platform and provider accounts. Commission is a ledger entry, not a derived number.
- **DriverWallet** — balances are *computed* from ledger entries and cached; never written directly.

## 4. Booking lifecycle (server-validated state machine)

```
RIDE:      quoted → requested → searching → accepted → driver_arriving → arrived → in_progress → completed → paid
DELIVERY:  quoted → requested → searching → accepted → driver_arriving → arrived_pickup → collected → in_transit
           → arrived_dropoff → recipient_verified → delivered → paid
Any state before in_progress/collected → cancelled_by_customer | cancelled_by_driver | cancelled_by_admin | expired
```

Transitions are defined once in `bookings/booking-state.ts`; each transition declares who may trigger it (customer / driver / system / admin) and side effects (notify, ledger, timers). Illegal transitions return `409 INVALID_TRANSITION`.

## 5. Dispatch engine

1. Customer confirms → booking `searching`; a `dispatch` job is enqueued.
2. Worker loads online drivers within radius *r₀* (default 2 km) from Redis `GEORADIUS`, excludes drivers on a trip or with a pending offer, filters by service capability (every approved Bajaaj does both).
3. Candidates are ranked by **road ETA** from the routing provider (batched matrix call); straight-line distance is only the pre-filter.
4. Offers go out **sequentially by default** (configurable to broadcast-to-N): the top driver gets a 20 s countdown via socket + push. Reject / timeout → next candidate.
5. After the list is exhausted the radius expands (2 → 4 → 7 km, configurable) up to a max search time (default 3 min) → `expired`, customer notified.
6. Acceptance is `UPDATE bookings SET status='accepted', driver_id=$1 WHERE id=$2 AND status='searching'` inside a transaction; 0 rows → the driver sees "already taken".
7. Admin can force-assign or reassign from the dashboard; the action is audited.

## 6. Fare engine

`fare = max(minimum_fare, base_fee + distance_km × rate_per_km + waiting_fee + night/peak uplift) × surge − promotion`

- Distance comes from the **routing provider's road distance**, rounded to 0.1 km.
- Defaults (v1): rate 0.50 USD/km, minimum 1.00, base 0, waiting 0, surge 1.0, cancellation 0 → 1 km = $1.00, 3 km = $1.50, 10 km = $5.00.
- Rules live in `pricing_versions` (JSONB rule set + effective window + zone). `PricingService.resolve(service, zone, at)` picks the active version; `quote()` stores the version id on the FareQuote.
- Admin edits create a new version; the old one is closed; both are in `audit_logs`.

## 7. Security baseline

- OTP: 6 digits, 5-minute expiry, max 5 sends / phone / hour and 10 / IP / hour, 5 verify attempts then lockout; codes hashed at rest.
- JWT RS256; refresh tokens hashed; device rows allow "sign out everywhere".
- RBAC: permissions are strings (`bookings.read`, `pricing.write`…); roles are permission sets; guards check per route.
- Rate limiting on all public routes (Redis token bucket); Helmet; strict CORS; input validation with Zod on every DTO.
- Secrets only via environment; mobile apps hold **no** provider keys — routing/geocoding is proxied through the API.
- Location privacy: precise driver positions retained 30 days then downsampled; customers only ever see their own trip's driver.

## 8. Low-bandwidth posture

- Driver location updates: 3 s while on trip, 10 s idle, batched when offline and replayed.
- Map tiles cached on device; vector data gzipped; images served as WebP via the API's image proxy.
- Every mutation is idempotent (`Idempotency-Key` header) so retries are safe.
- Apps show explicit offline state and queue non-critical actions.

## 9. Environments

| | dev | staging | production |
|---|---|---|---|
| OTP | console / allow-listed test numbers | real SMS to allow-listed numbers | real SMS |
| Payments | sandbox provider | provider sandboxes | live (only after reconciliation sign-off) |
| Routing | OSRM demo server | Google/Mapbox | Google/Mapbox |
| Data | seed + reset endpoint | seed | backups every 6 h, PITR |

Test accounts and the reset endpoint exist **only** when `APP_ENV != production`; the code path is compiled out of production builds.
