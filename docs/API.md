# BajGo API Contract · v1

Base URL: `https://api.baj-go.com/v1` (dev: `http://localhost:4000/v1`). JSON everywhere. All timestamps ISO-8601 UTC. All money as **integer cents** + `currency: "USD"`. Coordinates as `{ "lat": 8.4064, "lng": 48.4847 }`.

Auth: `Authorization: Bearer <access_jwt>`. Access tokens last 15 min; refresh with `POST /auth/refresh`. Every mutating request may send `Idempotency-Key: <uuid>`; the same key returns the same response for 24 h.

Errors: `{ "error": { "code": "INVALID_TRANSITION", "message": "…", "details": {} } }`. Codes are UPPER_SNAKE. HTTP: 400 validation, 401 auth, 403 permission, 404, 409 state conflict, 422 business rule, 429 rate limit.

Pagination: `?page=1&limit=25` → `{ "data": [...], "meta": { "page", "limit", "total" } }`. Filtering uses explicit query params per endpoint. Sorting `?sort=-created_at`.

Localisation: `Accept-Language: so|en` controls message text; every user also has a stored `language`.

---

## Auth (customers & drivers)

| Method | Path | Body → Response |
|---|---|---|
| POST | `/auth/otp/request` | `{ phone: "+2529xxxxxxx", purpose: "login", role: "customer"\|"driver" }` → `{ expires_in: 300, resend_after: 45, dev_code?: "123456" }` (dev_code only when `APP_ENV!=production` and phone is an allow-listed test number) |
| POST | `/auth/otp/verify` | `{ phone, code, device: { platform, name, push_token?, app_version } }` → `{ status: "ok", is_new: bool, access_token, refresh_token, user }` — if `is_new` the user has `full_name: null` and must call `/me` to set it |
| POST | `/auth/refresh` | `{ refresh_token }` → new pair (old refresh revoked) |
| POST | `/auth/logout` | `{ all_devices?: bool }` → 204 |
| POST | `/auth/admin/login` | `{ email, password, totp? }` → tokens + `permissions[]` |

Rate limits: otp/request 5 per phone/h and 10 per IP/h; otp/verify 5 attempts per code.

## Me

| GET | `/me` | → `User` (+ `driver_profile` for drivers) |
| PATCH | `/me` | `{ full_name?, language?, avatar_url?, marketing_consent? }` |
| GET/POST/PATCH/DELETE | `/me/places` | saved places: `{ label, kind: home\|work\|custom, address, landmark, location }` |
| GET | `/me/devices` · DELETE `/me/devices/:id` | |
| POST | `/me/delete-request` | starts account deletion (OTP confirm) |
| GET | `/me/export` | JSON export of personal data |
| GET | `/me/notifications` · POST `/me/notifications/:id/read` | |

## Geo & routing (proxied — apps never hold map keys)

| GET | `/geo/search?q=suuqa&near=lat,lng` | → `[ { name, address, location, source } ]` (saved places + landmarks + provider geocoding) |
| GET | `/geo/reverse?lat&lng` | → `{ address, landmark?, zone_key? }` |
| POST | `/geo/route` | `{ from, to }` → `{ distance_m, duration_s, polyline }` |
| GET | `/geo/zones` | public service-area polygons (GeoJSON) |
| GET | `/geo/nearby-drivers?lat&lng` | → `[ { location, heading } ]` anonymised, for the home-screen map |

## Quotes & bookings (customer)

| POST | `/quotes` | `{ service: ride\|delivery, pickup: {location,address?,landmark?}, dropoff: {...}, delivery?: { category, package_size } , promo_code? }` → `{ quote_id, service, distance_m, duration_s, polyline, fare_cents, breakdown: { base, distance, waiting, multiplier, discount, minimum_applied }, pricing_version, expires_at }` |
| POST | `/bookings` | `{ quote_id, payment_method, delivery?: { sender_name, sender_phone, recipient_name, recipient_phone, package_description, package_size, package_weight_kg?, package_photo_url?, instructions? }, scheduled_for? }` → `Booking` (status `searching`) |
| GET | `/bookings?status=active\|history&service=` | |
| GET | `/bookings/:id` | full booking incl. driver card `{ id, full_name, avatar_url, rating, vehicle: { fleet_code, plate, colour } }`, live `driver_location`, `eta_s` |
| POST | `/bookings/:id/cancel` | `{ reason }` → booking (fee applied per policy) |
| POST | `/bookings/:id/rate` | `{ score, tags[], comment?, tip_cents? }` |
| POST | `/bookings/:id/share` | → `{ url: "https://baj-go.com/t/<token>" }` |
| GET | `/public/trips/:token` | public share page data (no PII beyond first name + fleet code) |
| POST | `/bookings/:id/sos` | `{ location, note? }` → incident created, ops alerted |
| POST | `/bookings/:id/report` | `{ kind, description }` |
| GET | `/bookings/:id/receipt` | → receipt JSON (+ `?format=pdf`) |
| POST | `/bookings/:id/payment/confirm` | customer-side mobile-money confirmation (`{ method, phone }`) → payment intent |

Delivery recipient OTP: on `arrived_dropoff` the backend SMSes the recipient a 4-digit code; the driver enters it (`/driver/bookings/:id/verify-recipient`). Customer may also see it in-app if `delivery.recipient_phone == customer.phone`.

## Driver

| POST | `/driver/register` | `{ full_name, vehicle: { plate_number, make_model, colour, year }, emergency_contact: {name, phone}, payout: {method, account} }` (after OTP login as driver) → profile `pending` |
| POST | `/driver/documents` | multipart `{ type, file }` → document `pending` |
| GET | `/driver/me` | profile + verification + vehicle + wallet summary |
| POST | `/driver/availability` | `{ online: bool }` → 409 if not approved or has active booking |
| POST | `/driver/location` | `{ lat, lng, heading?, speed_kmh?, recorded_at }` (also via socket `driver:location`) |
| GET | `/driver/offers` | pending offer(s) |
| POST | `/driver/offers/:id/accept` · `/reject` | `{ reason? }` → 409 `OFFER_TAKEN` if another driver won |
| GET | `/driver/bookings?status=active\|history` | |
| POST | `/driver/bookings/:id/transition` | `{ to: driver_arriving\|arrived\|in_progress\|completed\|arrived_pickup\|collected\|in_transit\|arrived_dropoff\|delivered, location, proof_photo_url?, note? }` → booking; 409 on illegal transition |
| POST | `/driver/bookings/:id/verify-recipient` | `{ code }` → `recipient_verified` |
| POST | `/driver/bookings/:id/collect-cash` | `{ amount_cents }` → records cash + ledger |
| POST | `/driver/bookings/:id/fail` | `{ reason: recipient_unreachable\|refused\|wrong_address\|other, note }` → `failed` + return-to-sender workflow |
| POST | `/driver/bookings/:id/cancel` | `{ reason }` |
| GET | `/driver/earnings?period=today\|week\|month&from&to` | `{ gross_cents, commission_cents, net_cents, cash_cents, digital_cents, trips, deliveries, by_day[] }` |
| GET | `/driver/wallet` · GET `/driver/wallet/entries` | balance + ledger entries |
| POST | `/driver/payouts` | `{ amount_cents }` → payout `requested` |
| GET | `/driver/statements?month=2026-10` | → PDF/JSON statement |

## Payments

| GET | `/payments/methods` | enabled methods for this environment (`[ { method, provider, live: bool, label_so, label_en } ]`) |
| POST | `/payments/:id/retry` | |
| POST | `/webhooks/payments/:provider` | provider → API; signature verified; idempotent on `event_id` |

## Support & content (public/app)

| GET | `/content/pages/:slug?lang=` · `/content/faqs` · `/content/banners?placement=` · `/content/testimonials` | |
| POST | `/content/contact` | contact form |
| POST | `/support/tickets` · GET `/support/tickets` · GET/POST `/support/tickets/:id/messages` | |
| POST | `/driver/apply` (public website form) | pre-registration lead → `drivers` module |

## Admin (`/admin/*`, permission-guarded)

Every list endpoint supports `page, limit, sort, q` plus the filters shown. Every write is written to `audit_logs`.

| Area | Endpoints |
|---|---|
| Overview | `GET /admin/overview?range=today\|7d\|30d` → KPI cards; `GET /admin/overview/timeseries?metric=bookings\|gbv\|commission&range=` |
| Live ops | `GET /admin/live/drivers` · `GET /admin/live/bookings` · socket room `admin:live` |
| Customers | `GET /admin/customers?status=` · `GET /admin/customers/:id` (bookings, payments, tickets) · `POST /admin/customers/:id/suspend` · `/unsuspend` · `/delete` |
| Drivers | `GET /admin/drivers?verification=&availability=` · `GET /admin/drivers/:id` · `POST /admin/drivers/:id/approve` `{ fleet_code? }` · `/reject` `{ reason }` · `/suspend` · `/commission` `{ pct }` · `GET/POST /admin/drivers/:id/documents/:docId/review` `{ status, note }` |
| Vehicles | CRUD `/admin/vehicles` · `POST /admin/vehicles/:id/assign` `{ driver_id }` |
| Bookings | `GET /admin/bookings?service=&status=&from=&to=&driver_id=&customer_id=` · `GET /admin/bookings/:id` (timeline, offers, payments, ledger) · `POST /admin/bookings/:id/assign` `{ driver_id }` · `/cancel` · `/adjust-fare` `{ final_fare_cents, reason }` · `/transition` |
| Dispatch | `GET /admin/dispatch/settings` · `PUT` `{ mode: sequential\|broadcast, offer_timeout_s, radius_steps_m[], max_search_s, max_offers_per_round }` · `GET /admin/dispatch/searching` (bookings currently searching with candidate list) |
| Pricing | `GET /admin/pricing` (active + history per service/zone) · `POST /admin/pricing` (creates new version; body = pricing fields + `effective_from`) · `GET /admin/pricing/:id` · `POST /admin/pricing/preview` `{ service, zone_id?, distance_m, at }` → fare |
| Commission | `GET/PUT /admin/commission` `{ default_pct, by_category: {...} }` |
| Payments | `GET /admin/payments?status=&method=` · `GET /admin/payments/:id` · `POST /admin/payments/:id/mark-paid` (cash reconciliation) |
| Payouts | `GET /admin/payouts?status=` · `POST /admin/payouts/:id/approve` · `/pay` `{ provider_ref }` · `/reject` |
| Finance | `GET /admin/finance/summary?from&to` → GBV, ride/delivery revenue, commission revenue, driver payable, refunds, promotions, provider fees, net revenue · `GET /admin/finance/pnl?month=` · `GET /admin/finance/cash-reconciliation?date=` · `GET /admin/finance/statements?month=` · `GET /admin/finance/export.csv` |
| Refunds & disputes | `GET /admin/refunds` · `POST /admin/refunds` · `POST /admin/refunds/:id/approve` · `GET /admin/disputes` (tickets with category delivery/payment + incidents) |
| Promotions | CRUD `/admin/promotions` · `GET /admin/promotions/:id/redemptions` |
| Notifications | `POST /admin/notifications/broadcast` `{ audience: customers\|drivers\|segment, title_so, title_en, body_so, body_en, channel }` · `GET /admin/notifications/log` |
| SMS & OTP | `GET /admin/sms/log` · `GET/PUT /admin/sms/settings` `{ provider, sender_id, otp_ttl_s, test_numbers[] }` |
| Support | `GET /admin/support/tickets?status=&category=&assigned=` · `POST …/:id/assign` · `/reply` · `/status` · incidents `GET /admin/incidents` |
| Zones | CRUD `/admin/zones` (GeoJSON) |
| Website CMS | CRUD `/admin/cms/pages` · `/faqs` · `/banners` · `/testimonials` (approve) · `GET /admin/cms/contact-messages` |
| App content | `GET/PUT /admin/app-content` (home cards copy, promo banners, onboarding slides, support phone) |
| Settings | `GET/PUT /admin/settings` (brand name, support phone/email, currency, timezone, languages, map provider, feature flags) |
| Roles | CRUD `/admin/roles` · `GET /admin/admins` · `POST /admin/admins` · `PATCH /admin/admins/:id/roles` |
| Audit | `GET /admin/audit?actor=&entity_type=&entity_id=&from=&to=` |
| Security | `GET /admin/security/sessions` · `POST /admin/security/sessions/:id/revoke` · `GET /admin/security/health` (queue depth, socket connections, provider status) |
| Reports | `GET /admin/reports/:name?from&to&format=json\|csv` — bookings, drivers, customers, revenue, cancellations, zones, promotions |
| Dev only | `POST /admin/dev/reset` · `POST /admin/dev/simulate` `{ scenario: ride\|delivery, drivers: n }` — 404 in production |

## Real-time (Socket.IO, namespace `/rt`, auth via `auth: { token }`)

Client → server: `driver:location {lat,lng,heading,speed_kmh,recorded_at}`, `driver:offer:accept {offer_id}`, `driver:offer:reject {offer_id, reason}`, `booking:subscribe {booking_id}`, `admin:live:subscribe`.

Server → client:
- customer: `booking:status {booking_id, status, at}`, `booking:driver {driver card}`, `booking:location {lat,lng,heading,eta_s}`, `booking:expired`, `payment:status`
- driver: `offer:new {offer}`, `offer:withdrawn {offer_id}`, `booking:status`, `booking:cancelled`
- admin: `live:driver {driver_id, location, availability}`, `live:booking {booking summary}`, `live:alert {incident}`

## Core objects

```ts
User { id, role, phone, full_name, language, avatar_url, status, created_at }
Driver = User & { driver_profile: { verification, availability, rating_avg, rating_count, vehicle: Vehicle, accepts_rides, accepts_deliveries, online_since } }
Vehicle { id, fleet_code, plate_number, make_model, colour, year, seats, livery }
Place { location: {lat,lng}, address?: string, landmark?: string }
Quote { quote_id, service, pickup: Place, dropoff: Place, distance_m, duration_s, polyline, fare_cents, currency, breakdown, pricing_version: {id, version, name}, expires_at }
Booking { id, reference, service, status, customer, driver?, vehicle?, pickup: Place, dropoff: Place, route: {distance_m, duration_s, polyline}, quoted_fare_cents, final_fare_cents?, tip_cents, discount_cents, payment_method, payment_status?, delivery?: {...}, timeline: [{status, at, actor_role}], eta_s?, driver_location?, share_url?, created_at }
```
