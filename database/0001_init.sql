-- BajGo core schema · migration 0001
-- PostgreSQL 16 + PostGIS. All money in USD cents (bigint) to avoid float error.

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS citext;

-- ───────────────────────────────────────── enums
CREATE TYPE user_role AS ENUM ('customer','driver','admin');
CREATE TYPE user_status AS ENUM ('active','suspended','deleted');
CREATE TYPE language AS ENUM ('so','en');
CREATE TYPE driver_verification AS ENUM ('pending','under_review','approved','rejected','suspended');
CREATE TYPE driver_availability AS ENUM ('offline','online','on_trip');
CREATE TYPE document_type AS ENUM ('national_id','driving_licence','vehicle_registration','vehicle_insurance','vehicle_photo_front','vehicle_photo_side','vehicle_photo_rear','profile_photo','other');
CREATE TYPE document_status AS ENUM ('pending','approved','rejected','expired');
CREATE TYPE service_type AS ENUM ('ride','delivery');
CREATE TYPE delivery_category AS ENUM ('food','shopping','parcel','document','pharmacy','other');
CREATE TYPE booking_status AS ENUM (
  'quoted','requested','searching','accepted','driver_arriving','arrived',
  'in_progress','arrived_pickup','collected','in_transit','arrived_dropoff','recipient_verified',
  'completed','delivered','paid',
  'cancelled_by_customer','cancelled_by_driver','cancelled_by_admin','expired','failed','returned'
);
CREATE TYPE offer_status AS ENUM ('pending','accepted','rejected','timed_out','withdrawn');
CREATE TYPE payment_method AS ENUM ('cash','evc_plus','zaad','sahal','card','wallet','sandbox');
CREATE TYPE payment_status AS ENUM ('pending','authorised','captured','failed','refunded','partially_refunded','cancelled');
CREATE TYPE ledger_account AS ENUM ('customer','driver','platform_commission','platform_cash_clearing','provider_fees','promotions','refunds','tips','adjustments');
CREATE TYPE payout_status AS ENUM ('requested','approved','paid','rejected','failed');
CREATE TYPE promo_type AS ENUM ('percent','fixed');
CREATE TYPE notification_channel AS ENUM ('push','sms','in_app');
CREATE TYPE ticket_status AS ENUM ('open','in_progress','waiting_customer','resolved','closed');
CREATE TYPE ticket_category AS ENUM ('ride','delivery','payment','lost_item','incident','account','driver','other');
CREATE TYPE otp_purpose AS ENUM ('login','recipient_delivery','account_recovery','account_deletion');
CREATE TYPE zone_kind AS ENUM ('service_area','surge','restricted');

-- ───────────────────────────────────────── identity
CREATE TABLE users (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  role          user_role NOT NULL,
  phone_e164    text UNIQUE,                       -- +2529XXXXXXX (customers/drivers)
  email         citext UNIQUE,                     -- admins
  password_hash text,                              -- admins only
  full_name     text NOT NULL,
  language      language NOT NULL DEFAULT 'so',
  avatar_url    text,
  status        user_status NOT NULL DEFAULT 'active',
  phone_verified_at timestamptz,
  last_seen_at  timestamptz,
  marketing_consent boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  deleted_at    timestamptz
);
CREATE INDEX users_role_idx ON users(role);
CREATE INDEX users_name_trgm ON users USING gin (full_name gin_trgm_ops);

CREATE TABLE otp_codes (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone_e164  text NOT NULL,
  purpose     otp_purpose NOT NULL,
  code_hash   text NOT NULL,
  attempts    smallint NOT NULL DEFAULT 0,
  expires_at  timestamptz NOT NULL,
  consumed_at timestamptz,
  ip          inet,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX otp_codes_phone_idx ON otp_codes(phone_e164, purpose, created_at DESC);

CREATE TABLE devices (
  id             uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  platform       text NOT NULL,                    -- android | ios | web
  device_name    text,
  push_token     text,
  app_version    text,
  last_active_at timestamptz NOT NULL DEFAULT now(),
  created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX devices_user_idx ON devices(user_id);

CREATE TABLE sessions (
  id                 uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id            uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id          uuid REFERENCES devices(id) ON DELETE SET NULL,
  refresh_token_hash text NOT NULL UNIQUE,
  expires_at         timestamptz NOT NULL,
  revoked_at         timestamptz,
  ip                 inet,
  user_agent         text,
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX sessions_user_idx ON sessions(user_id) WHERE revoked_at IS NULL;

-- RBAC for admins
CREATE TABLE roles (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  key         text UNIQUE NOT NULL,                -- super_admin, operations, finance, verification, support, marketing, auditor
  name        text NOT NULL,
  permissions text[] NOT NULL DEFAULT '{}',
  is_system   boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE user_roles (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, role_id)
);

-- ───────────────────────────────────────── customers & drivers
CREATE TABLE customer_profiles (
  user_id        uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  rating_avg     numeric(3,2) NOT NULL DEFAULT 5.00,
  rating_count   integer NOT NULL DEFAULT 0,
  total_rides    integer NOT NULL DEFAULT 0,
  total_deliveries integer NOT NULL DEFAULT 0,
  referral_code  text UNIQUE,
  referred_by    uuid REFERENCES users(id),
  notes          text
);

CREATE TABLE saved_places (
  id        uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label     text NOT NULL,                         -- Home, Work, or custom
  kind      text NOT NULL DEFAULT 'custom',        -- home | work | custom | recent
  address   text,
  landmark  text,
  location  geography(Point,4326) NOT NULL,
  use_count integer NOT NULL DEFAULT 0,
  last_used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX saved_places_user_idx ON saved_places(user_id, kind);

CREATE TABLE vehicles (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  fleet_code    text UNIQUE,                        -- BG-0142, assigned on approval
  plate_number  text UNIQUE,
  make_model    text NOT NULL DEFAULT 'Bajaj RE',
  colour        text,
  year          smallint,
  seats         smallint NOT NULL DEFAULT 3,
  max_parcel_kg numeric(5,1) NOT NULL DEFAULT 30,
  livery        text NOT NULL DEFAULT 'none',       -- none | sticker_kit | full_wrap
  active        boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE driver_profiles (
  user_id            uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  vehicle_id         uuid REFERENCES vehicles(id),
  verification       driver_verification NOT NULL DEFAULT 'pending',
  verification_notes text,
  verified_by        uuid REFERENCES users(id),
  verified_at        timestamptz,
  availability       driver_availability NOT NULL DEFAULT 'offline',
  accepts_rides      boolean NOT NULL DEFAULT true,
  accepts_deliveries boolean NOT NULL DEFAULT true,
  rating_avg         numeric(3,2) NOT NULL DEFAULT 5.00,
  rating_count       integer NOT NULL DEFAULT 0,
  total_rides        integer NOT NULL DEFAULT 0,
  total_deliveries   integer NOT NULL DEFAULT 0,
  acceptance_rate    numeric(5,2) NOT NULL DEFAULT 100,
  commission_pct     numeric(5,2),                 -- NULL → use global setting
  emergency_contact_name  text,
  emergency_contact_phone text,
  payout_method      text,                         -- evc_plus | zaad | sahal | cash
  payout_account     text,
  last_location      geography(Point,4326),
  last_location_at   timestamptz,
  heading            smallint,
  online_since       timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX driver_profiles_avail_idx ON driver_profiles(availability) WHERE verification = 'approved';
CREATE INDEX driver_profiles_loc_gix ON driver_profiles USING gist (last_location);

CREATE TABLE driver_documents (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type        document_type NOT NULL,
  file_url    text NOT NULL,
  status      document_status NOT NULL DEFAULT 'pending',
  expires_at  date,
  reviewed_by uuid REFERENCES users(id),
  reviewed_at timestamptz,
  review_note text,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX driver_documents_driver_idx ON driver_documents(driver_id, type);

CREATE TABLE driver_location_history (
  driver_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  booking_id  uuid,
  location    geography(Point,4326) NOT NULL,
  speed_kmh   numeric(5,1),
  heading     smallint,
  recorded_at timestamptz NOT NULL
) PARTITION BY RANGE (recorded_at);
CREATE TABLE driver_location_history_default PARTITION OF driver_location_history DEFAULT;
CREATE INDEX dlh_driver_time_idx ON driver_location_history(driver_id, recorded_at DESC);
CREATE INDEX dlh_booking_idx ON driver_location_history(booking_id) WHERE booking_id IS NOT NULL;

-- ───────────────────────────────────────── geography & pricing
CREATE TABLE zones (
  id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  key        text UNIQUE NOT NULL,                 -- garowe
  name       text NOT NULL,
  kind       zone_kind NOT NULL DEFAULT 'service_area',
  geom       geography(MultiPolygon,4326) NOT NULL,
  active     boolean NOT NULL DEFAULT true,
  dispatch_radius_steps_m integer[] NOT NULL DEFAULT '{2000,4000,7000}',
  max_search_seconds integer NOT NULL DEFAULT 180,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX zones_gix ON zones USING gist (geom);

CREATE TABLE pricing_versions (
  id             uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  version        integer NOT NULL,
  service        service_type NOT NULL,
  zone_id        uuid REFERENCES zones(id),        -- NULL → global default
  name           text NOT NULL,
  currency       char(3) NOT NULL DEFAULT 'USD',
  rate_per_km_cents      integer NOT NULL,         -- 50
  minimum_fare_cents     integer NOT NULL,         -- 100
  base_fee_cents         integer NOT NULL DEFAULT 0,
  waiting_fee_per_min_cents integer NOT NULL DEFAULT 0,
  free_waiting_minutes   smallint NOT NULL DEFAULT 3,
  cancellation_fee_cents integer NOT NULL DEFAULT 0,
  cancellation_free_seconds integer NOT NULL DEFAULT 120,
  surge_multiplier       numeric(4,2) NOT NULL DEFAULT 1.00,
  night_multiplier       numeric(4,2) NOT NULL DEFAULT 1.00,
  night_start            time NOT NULL DEFAULT '22:00',
  night_end              time NOT NULL DEFAULT '05:00',
  peak_multiplier        numeric(4,2) NOT NULL DEFAULT 1.00,
  peak_windows           jsonb NOT NULL DEFAULT '[]',   -- [{"days":[1,2,3,4,5],"start":"07:00","end":"09:00"}]
  distance_brackets      jsonb NOT NULL DEFAULT '[]',   -- [{"from_km":0,"to_km":10,"rate_cents":50},...] overrides rate_per_km when present
  delivery_extras        jsonb NOT NULL DEFAULT '{}',   -- {"category":{"food":0,"pharmacy":50},"size":{"large":100}}
  commission_pct         numeric(5,2) NOT NULL DEFAULT 15.00,
  rounding_cents         smallint NOT NULL DEFAULT 10,  -- round fare up to nearest 10 cents
  effective_from         timestamptz NOT NULL DEFAULT now(),
  effective_to           timestamptz,
  created_by             uuid REFERENCES users(id),
  note                   text,
  created_at             timestamptz NOT NULL DEFAULT now(),
  UNIQUE (service, zone_id, version)
);
CREATE INDEX pricing_versions_active_idx ON pricing_versions(service, zone_id, effective_from DESC);

-- ───────────────────────────────────────── bookings
CREATE SEQUENCE booking_ref_seq START 1000;

CREATE TABLE bookings (
  id               uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  reference        text UNIQUE NOT NULL DEFAULT ('BJ' || to_char(now(),'YYMMDD') || '-' || lpad(nextval('booking_ref_seq')::text, 5, '0')),
  service          service_type NOT NULL,
  status           booking_status NOT NULL DEFAULT 'quoted',
  customer_id      uuid NOT NULL REFERENCES users(id),
  driver_id        uuid REFERENCES users(id),
  vehicle_id       uuid REFERENCES vehicles(id),
  zone_id          uuid REFERENCES zones(id),
  -- places
  pickup_location  geography(Point,4326) NOT NULL,
  pickup_address   text,
  pickup_landmark  text,
  dropoff_location geography(Point,4326) NOT NULL,
  dropoff_address  text,
  dropoff_landmark text,
  route_polyline   text,
  route_distance_m integer,
  route_duration_s integer,
  -- quote & money (cents)
  pricing_version_id uuid REFERENCES pricing_versions(id),
  quoted_fare_cents  integer NOT NULL DEFAULT 0,
  final_fare_cents   integer,
  tip_cents          integer NOT NULL DEFAULT 0,
  discount_cents     integer NOT NULL DEFAULT 0,
  promotion_id       uuid,
  commission_pct     numeric(5,2),
  commission_cents   integer,
  payment_method     payment_method NOT NULL DEFAULT 'cash',
  fare_breakdown     jsonb NOT NULL DEFAULT '{}',
  -- delivery fields
  delivery_category  delivery_category,
  sender_name        text,
  sender_phone       text,
  recipient_name     text,
  recipient_phone    text,
  package_description text,
  package_size       text,                          -- small | medium | large
  package_weight_kg  numeric(5,1),
  package_photo_url  text,
  delivery_instructions text,
  proof_photo_url    text,
  recipient_otp_verified_at timestamptz,
  -- lifecycle
  scheduled_for      timestamptz,
  requested_at       timestamptz,
  accepted_at        timestamptz,
  arrived_at         timestamptz,
  started_at         timestamptz,
  completed_at       timestamptz,
  cancelled_at       timestamptz,
  cancellation_reason text,
  cancellation_fee_cents integer NOT NULL DEFAULT 0,
  waiting_seconds    integer NOT NULL DEFAULT 0,
  actual_distance_m  integer,
  customer_rating    smallint CHECK (customer_rating BETWEEN 1 AND 5),
  driver_rating      smallint CHECK (driver_rating BETWEEN 1 AND 5),
  customer_comment   text,
  driver_comment     text,
  share_token        text UNIQUE,
  idempotency_key    text UNIQUE,
  metadata           jsonb NOT NULL DEFAULT '{}',
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX bookings_customer_idx ON bookings(customer_id, created_at DESC);
CREATE INDEX bookings_driver_idx ON bookings(driver_id, created_at DESC);
CREATE INDEX bookings_status_idx ON bookings(status) WHERE status NOT IN ('paid','cancelled_by_customer','cancelled_by_driver','cancelled_by_admin','expired');
CREATE INDEX bookings_pickup_gix ON bookings USING gist (pickup_location);
CREATE INDEX bookings_created_idx ON bookings(created_at DESC);

CREATE TABLE booking_status_history (
  id          bigserial PRIMARY KEY,
  booking_id  uuid NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  from_status booking_status,
  to_status   booking_status NOT NULL,
  actor_id    uuid REFERENCES users(id),
  actor_role  text NOT NULL,                       -- customer | driver | admin | system
  reason      text,
  location    geography(Point,4326),
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX bsh_booking_idx ON booking_status_history(booking_id, created_at);

CREATE TABLE dispatch_offers (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id   uuid NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  driver_id    uuid NOT NULL REFERENCES users(id),
  round        smallint NOT NULL DEFAULT 1,
  radius_m     integer NOT NULL,
  eta_seconds  integer,
  distance_m   integer,
  status       offer_status NOT NULL DEFAULT 'pending',
  offered_at   timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL,
  responded_at timestamptz,
  reason       text
);
CREATE INDEX dispatch_offers_booking_idx ON dispatch_offers(booking_id, offered_at);
CREATE UNIQUE INDEX dispatch_offers_one_pending_per_driver ON dispatch_offers(driver_id) WHERE status = 'pending';

-- ───────────────────────────────────────── money
CREATE TABLE payments (
  id             uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id     uuid NOT NULL REFERENCES bookings(id),
  customer_id    uuid NOT NULL REFERENCES users(id),
  driver_id      uuid REFERENCES users(id),
  method         payment_method NOT NULL,
  provider       text NOT NULL,                    -- cash | sandbox | evc_plus | zaad | sahal | stripe
  provider_ref   text,
  status         payment_status NOT NULL DEFAULT 'pending',
  amount_cents   integer NOT NULL,
  currency       char(3) NOT NULL DEFAULT 'USD',
  idempotency_key text UNIQUE,
  failure_reason text,
  raw_response   jsonb,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX payments_booking_idx ON payments(booking_id);
CREATE INDEX payments_status_idx ON payments(status, created_at DESC);

CREATE TABLE payment_attempts (
  id          bigserial PRIMARY KEY,
  payment_id  uuid NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
  attempt_no  smallint NOT NULL,
  request     jsonb,
  response    jsonb,
  status      payment_status NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE payment_webhooks (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  provider     text NOT NULL,
  event_id     text NOT NULL,
  signature_ok boolean NOT NULL,
  payload      jsonb NOT NULL,
  processed_at timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, event_id)
);

-- Double-entry ledger. Every money movement is two or more rows summing to zero per transaction.
CREATE TABLE ledger_transactions (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  kind        text NOT NULL,                       -- fare | commission | tip | refund | payout | adjustment | promo | provider_fee | cash_collected
  booking_id  uuid REFERENCES bookings(id),
  payment_id  uuid REFERENCES payments(id),
  payout_id   uuid,
  description text,
  created_by  uuid REFERENCES users(id),
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE ledger_entries (
  id             bigserial PRIMARY KEY,
  transaction_id uuid NOT NULL REFERENCES ledger_transactions(id) ON DELETE CASCADE,
  account        ledger_account NOT NULL,
  owner_id       uuid REFERENCES users(id),        -- customer/driver the account belongs to
  amount_cents   bigint NOT NULL,                  -- + credit, − debit
  currency       char(3) NOT NULL DEFAULT 'USD',
  created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ledger_entries_owner_idx ON ledger_entries(owner_id, account, created_at DESC);
CREATE INDEX ledger_entries_tx_idx ON ledger_entries(transaction_id);

-- Cached wallet balances (recomputed from ledger by a job and after each tx).
CREATE TABLE driver_wallets (
  driver_id            uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  balance_cents        bigint NOT NULL DEFAULT 0,   -- + platform owes driver, − driver owes commission
  gross_earned_cents   bigint NOT NULL DEFAULT 0,
  commission_due_cents bigint NOT NULL DEFAULT 0,
  cash_collected_cents bigint NOT NULL DEFAULT 0,
  paid_out_cents       bigint NOT NULL DEFAULT 0,
  updated_at           timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE payouts (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id     uuid NOT NULL REFERENCES users(id),
  amount_cents  bigint NOT NULL,
  method        text NOT NULL,
  account       text,
  status        payout_status NOT NULL DEFAULT 'requested',
  provider_ref  text,
  requested_at  timestamptz NOT NULL DEFAULT now(),
  approved_by   uuid REFERENCES users(id),
  approved_at   timestamptz,
  paid_at       timestamptz,
  note          text
);
CREATE INDEX payouts_driver_idx ON payouts(driver_id, requested_at DESC);

CREATE TABLE refunds (
  id            uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  payment_id    uuid NOT NULL REFERENCES payments(id),
  booking_id    uuid NOT NULL REFERENCES bookings(id),
  amount_cents  integer NOT NULL,
  reason        text NOT NULL,
  status        payment_status NOT NULL DEFAULT 'pending',
  provider_ref  text,
  requested_by  uuid REFERENCES users(id),
  approved_by   uuid REFERENCES users(id),
  created_at    timestamptz NOT NULL DEFAULT now(),
  processed_at  timestamptz
);

-- ───────────────────────────────────────── promotions
CREATE TABLE promotions (
  id              uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  code            text UNIQUE NOT NULL,
  name            text NOT NULL,
  type            promo_type NOT NULL,
  value           integer NOT NULL,                -- percent (0–100) or cents
  max_discount_cents integer,
  min_fare_cents  integer NOT NULL DEFAULT 0,
  service         service_type,                    -- NULL → both
  first_n_bookings smallint,                       -- e.g. first 3 rides
  max_uses_total  integer,
  max_uses_per_user smallint NOT NULL DEFAULT 1,
  uses_count      integer NOT NULL DEFAULT 0,
  starts_at       timestamptz NOT NULL DEFAULT now(),
  ends_at         timestamptz,
  active          boolean NOT NULL DEFAULT true,
  created_by      uuid REFERENCES users(id),
  created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE promotion_redemptions (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  promotion_id uuid NOT NULL REFERENCES promotions(id),
  user_id      uuid NOT NULL REFERENCES users(id),
  booking_id   uuid NOT NULL REFERENCES bookings(id),
  discount_cents integer NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (promotion_id, booking_id)
);
ALTER TABLE bookings ADD CONSTRAINT bookings_promotion_fk FOREIGN KEY (promotion_id) REFERENCES promotions(id);

-- ───────────────────────────────────────── ratings, notifications, support
CREATE TABLE ratings (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id  uuid NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  rater_id    uuid NOT NULL REFERENCES users(id),
  ratee_id    uuid NOT NULL REFERENCES users(id),
  score       smallint NOT NULL CHECK (score BETWEEN 1 AND 5),
  tags        text[] NOT NULL DEFAULT '{}',
  comment     text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (booking_id, rater_id)
);

CREATE TABLE notifications (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  channel     notification_channel NOT NULL,
  template    text NOT NULL,                       -- booking.accepted, driver.arrived, …
  title       text,
  body        text NOT NULL,
  data        jsonb NOT NULL DEFAULT '{}',
  read_at     timestamptz,
  sent_at     timestamptz,
  delivery_status text,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX notifications_user_idx ON notifications(user_id, created_at DESC);

CREATE TABLE sms_log (
  id          bigserial PRIMARY KEY,
  phone_e164  text NOT NULL,
  provider    text NOT NULL,
  purpose     text NOT NULL,
  status      text NOT NULL,
  provider_ref text,
  cost_cents  integer,
  error       text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE support_tickets (
  id           uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  reference    text UNIQUE NOT NULL DEFAULT ('T' || lpad(nextval('booking_ref_seq')::text, 6, '0')),
  user_id      uuid NOT NULL REFERENCES users(id),
  booking_id   uuid REFERENCES bookings(id),
  category     ticket_category NOT NULL,
  subject      text NOT NULL,
  status       ticket_status NOT NULL DEFAULT 'open',
  priority     smallint NOT NULL DEFAULT 2,         -- 1 urgent … 4 low
  assigned_to  uuid REFERENCES users(id),
  is_incident  boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  resolved_at  timestamptz
);
CREATE TABLE support_messages (
  id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  ticket_id  uuid NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  author_id  uuid NOT NULL REFERENCES users(id),
  body       text NOT NULL,
  attachments jsonb NOT NULL DEFAULT '[]',
  internal   boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE incident_reports (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id  uuid REFERENCES bookings(id),
  reporter_id uuid NOT NULL REFERENCES users(id),
  kind        text NOT NULL,                       -- sos | accident | harassment | lost_item | dispute | other
  description text,
  location    geography(Point,4326),
  status      text NOT NULL DEFAULT 'open',
  handled_by  uuid REFERENCES users(id),
  created_at  timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz
);

-- ───────────────────────────────────────── content & settings
CREATE TABLE settings (
  key        text PRIMARY KEY,
  value      jsonb NOT NULL,
  updated_by uuid REFERENCES users(id),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE cms_pages (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug        text UNIQUE NOT NULL,                -- home, about, ride, delivery, how-it-works, drivers, download, coverage, pricing, safety, faq, contact, privacy, terms, delivery-terms, driver-terms, refunds
  title_so    text NOT NULL,
  title_en    text NOT NULL,
  blocks      jsonb NOT NULL DEFAULT '[]',         -- [{type, so:{...}, en:{...}}]
  seo         jsonb NOT NULL DEFAULT '{}',
  published   boolean NOT NULL DEFAULT false,
  updated_by  uuid REFERENCES users(id),
  updated_at  timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE cms_faqs (
  id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  category    text NOT NULL,
  question_so text NOT NULL, answer_so text NOT NULL,
  question_en text NOT NULL, answer_en text NOT NULL,
  sort_order  integer NOT NULL DEFAULT 0,
  published   boolean NOT NULL DEFAULT true
);
CREATE TABLE cms_banners (
  id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  placement  text NOT NULL,                        -- web_home_hero | app_home | app_promo
  title_so   text, title_en text,
  body_so    text, body_en text,
  image_url  text,
  link_url   text,
  starts_at  timestamptz, ends_at timestamptz,
  sort_order integer NOT NULL DEFAULT 0,
  published  boolean NOT NULL DEFAULT true
);
CREATE TABLE cms_testimonials (
  id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  author     text NOT NULL,
  role       text,
  quote_so   text, quote_en text,
  approved   boolean NOT NULL DEFAULT false,       -- only approved, real content is shown
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE contact_messages (
  id         uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name       text NOT NULL, phone text, email text,
  subject    text, body text NOT NULL,
  handled    boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE audit_logs (
  id          bigserial PRIMARY KEY,
  actor_id    uuid REFERENCES users(id),
  actor_role  text,
  action      text NOT NULL,                       -- pricing.update, driver.approve, booking.reassign …
  entity_type text,
  entity_id   text,
  before      jsonb,
  after       jsonb,
  ip          inet,
  user_agent  text,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX audit_logs_entity_idx ON audit_logs(entity_type, entity_id, created_at DESC);
CREATE INDEX audit_logs_actor_idx ON audit_logs(actor_id, created_at DESC);

-- ───────────────────────────────────────── triggers
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$ LANGUAGE plpgsql;
DO $$ DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['users','vehicles','driver_profiles','zones','bookings','payments','support_tickets','cms_pages'] LOOP
    EXECUTE format('CREATE TRIGGER %I_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION set_updated_at()', t, t);
  END LOOP;
END $$;

-- Ledger integrity: entries of a transaction must sum to zero (checked by the service in a tx; this is the DB-side guard).
CREATE OR REPLACE FUNCTION ledger_balance_check() RETURNS trigger AS $$
DECLARE s bigint;
BEGIN
  SELECT coalesce(sum(amount_cents),0) INTO s FROM ledger_entries WHERE transaction_id = NEW.transaction_id;
  IF s <> 0 THEN RAISE EXCEPTION 'ledger transaction % does not balance (sum=%)', NEW.transaction_id, s; END IF;
  RETURN NULL;
END $$ LANGUAGE plpgsql;
CREATE CONSTRAINT TRIGGER ledger_entries_balance AFTER INSERT OR UPDATE OR DELETE ON ledger_entries
  DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION ledger_balance_check();
