/**
 * Domain types for the BajGo Admin API (docs/API.md · Admin section) mirrored
 * from services/api/drizzle/0001_init.sql. All money is integer USD cents.
 */

export type LatLng = { lat: number; lng: number };
export type Place = { location: LatLng; address?: string | null; landmark?: string | null };

export type Paginated<T> = { data: T[]; meta: { page: number; limit: number; total: number } };
export type ListQuery = {
  page?: number;
  limit?: number;
  sort?: string;
  q?: string;
  [k: string]: string | number | boolean | undefined;
};

export type ApiErrorBody = { error: { code: string; message: string; details?: Record<string, unknown> } };

// ───────────────────────── identity
export type UserRole = "customer" | "driver" | "admin";
export type UserStatus = "active" | "suspended" | "deleted";
export type Language = "so" | "en";

export type User = {
  id: string;
  role: UserRole;
  phone: string | null;
  email?: string | null;
  full_name: string;
  language: Language;
  avatar_url: string | null;
  status: UserStatus;
  last_seen_at?: string | null;
  created_at: string;
};

export type AdminUser = User & { roles: string[]; permissions: string[]; totp_enabled: boolean };

export type LoginResponse = {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  user: AdminUser;
  permissions: string[];
};

// ───────────────────────── customers
export type Customer = User & {
  rating_avg: number;
  rating_count: number;
  total_rides: number;
  total_deliveries: number;
  referral_code: string | null;
  spend_cents: number;
  outstanding_cents: number;
  notes?: string | null;
};

export type CustomerDetail = Customer & {
  bookings: BookingSummary[];
  payments: Payment[];
  tickets: Ticket[];
};

// ───────────────────────── drivers & vehicles
export type DriverVerification = "pending" | "under_review" | "approved" | "rejected" | "suspended";
export type DriverAvailability = "offline" | "online" | "on_trip";
export type DocumentType =
  | "national_id"
  | "driving_licence"
  | "vehicle_registration"
  | "vehicle_insurance"
  | "vehicle_photo_front"
  | "vehicle_photo_side"
  | "vehicle_photo_rear"
  | "profile_photo"
  | "other";
export type DocumentStatus = "pending" | "approved" | "rejected" | "expired";

export type Vehicle = {
  id: string;
  fleet_code: string | null;
  plate_number: string | null;
  make_model: string;
  colour: string | null;
  year: number | null;
  seats: number;
  max_parcel_kg: number;
  livery: "none" | "sticker_kit" | "full_wrap";
  active: boolean;
  driver_id?: string | null;
  driver_name?: string | null;
  created_at: string;
  updated_at: string;
};

export type DriverDocument = {
  id: string;
  driver_id: string;
  type: DocumentType;
  file_url: string;
  status: DocumentStatus;
  expires_at: string | null;
  reviewed_by: string | null;
  reviewed_at: string | null;
  review_note: string | null;
  created_at: string;
};

export type DriverWallet = {
  balance_cents: number;
  gross_earned_cents: number;
  commission_due_cents: number;
  cash_collected_cents: number;
  paid_out_cents: number;
  updated_at: string;
};

export type Driver = User & {
  driver_profile: {
    verification: DriverVerification;
    verification_notes: string | null;
    verified_at: string | null;
    availability: DriverAvailability;
    accepts_rides: boolean;
    accepts_deliveries: boolean;
    rating_avg: number;
    rating_count: number;
    total_rides: number;
    total_deliveries: number;
    acceptance_rate: number;
    commission_pct: number | null;
    emergency_contact_name: string | null;
    emergency_contact_phone: string | null;
    payout_method: string | null;
    payout_account: string | null;
    last_location: LatLng | null;
    last_location_at: string | null;
    heading: number | null;
    online_since: string | null;
    vehicle: Vehicle | null;
  };
};

export type DriverDetail = Driver & {
  documents: DriverDocument[];
  wallet: DriverWallet;
  bookings: BookingSummary[];
  ledger: LedgerEntry[];
  stats: { last_30d_trips: number; last_30d_gross_cents: number; cancel_rate: number };
};

// ───────────────────────── bookings
export type ServiceType = "ride" | "delivery";
export type DeliveryCategory = "food" | "shopping" | "parcel" | "document" | "pharmacy" | "other";
export type BookingStatus =
  | "quoted"
  | "requested"
  | "searching"
  | "accepted"
  | "driver_arriving"
  | "arrived"
  | "in_progress"
  | "arrived_pickup"
  | "collected"
  | "in_transit"
  | "arrived_dropoff"
  | "recipient_verified"
  | "completed"
  | "delivered"
  | "paid"
  | "cancelled_by_customer"
  | "cancelled_by_driver"
  | "cancelled_by_admin"
  | "expired"
  | "failed"
  | "returned";

export type PaymentMethod = "cash" | "evc_plus" | "zaad" | "sahal" | "card" | "wallet" | "sandbox";
export type PaymentStatus =
  | "pending"
  | "authorised"
  | "captured"
  | "failed"
  | "refunded"
  | "partially_refunded"
  | "cancelled";

export type DriverCard = {
  id: string;
  full_name: string;
  phone: string | null;
  avatar_url: string | null;
  rating: number;
  vehicle: { fleet_code: string | null; plate: string | null; colour: string | null } | null;
};

export type BookingSummary = {
  id: string;
  reference: string;
  service: ServiceType;
  status: BookingStatus;
  customer: { id: string; full_name: string; phone: string | null };
  driver: DriverCard | null;
  pickup: Place;
  dropoff: Place;
  quoted_fare_cents: number;
  final_fare_cents: number | null;
  payment_method: PaymentMethod;
  payment_status: PaymentStatus | null;
  zone_key: string | null;
  delivery_category: DeliveryCategory | null;
  created_at: string;
  completed_at: string | null;
};

export type TimelineEvent = {
  id: number;
  from_status: BookingStatus | null;
  to_status: BookingStatus;
  actor_role: "customer" | "driver" | "admin" | "system";
  actor_name?: string | null;
  reason: string | null;
  at: string;
};

export type DispatchOffer = {
  id: string;
  booking_id: string;
  driver_id: string;
  driver_name: string;
  fleet_code: string | null;
  round: number;
  radius_m: number;
  eta_seconds: number | null;
  distance_m: number | null;
  status: "pending" | "accepted" | "rejected" | "timed_out" | "withdrawn";
  offered_at: string;
  expires_at: string;
  responded_at: string | null;
  reason: string | null;
};

export type Booking = BookingSummary & {
  vehicle: Vehicle | null;
  route: { distance_m: number; duration_s: number; polyline: LatLng[] };
  tip_cents: number;
  discount_cents: number;
  commission_pct: number | null;
  commission_cents: number | null;
  fare_breakdown: FareBreakdown;
  pricing_version: { id: string; version: number; name: string } | null;
  delivery: {
    category: DeliveryCategory;
    sender_name: string;
    sender_phone: string;
    recipient_name: string;
    recipient_phone: string;
    package_description: string;
    package_size: "small" | "medium" | "large";
    package_weight_kg: number | null;
    package_photo_url: string | null;
    instructions: string | null;
    proof_photo_url: string | null;
    recipient_otp_verified_at: string | null;
  } | null;
  waiting_seconds: number;
  actual_distance_m: number | null;
  cancellation_reason: string | null;
  cancellation_fee_cents: number;
  customer_rating: number | null;
  driver_rating: number | null;
  customer_comment: string | null;
  driver_location: LatLng | null;
  eta_s: number | null;
  timeline: TimelineEvent[];
  offers: DispatchOffer[];
  payments: Payment[];
  ledger: LedgerEntry[];
  share_url: string | null;
};

export type FareBreakdown = {
  base: number;
  distance: number;
  waiting: number;
  multiplier: number;
  discount: number;
  minimum_applied: boolean;
  night_applied?: boolean;
  peak_applied?: boolean;
  delivery_extra?: number;
};

// ───────────────────────── dispatch & pricing
export type DispatchSettings = {
  mode: "sequential" | "broadcast";
  offer_timeout_s: number;
  radius_steps_m: number[];
  max_search_s: number;
  max_offers_per_round: number;
  location_stale_s: number;
};

export type SearchingBooking = BookingSummary & {
  searching_since: string;
  round: number;
  radius_m: number;
  candidates: {
    driver_id: string;
    full_name: string;
    fleet_code: string | null;
    distance_m: number;
    eta_s: number;
    offer_status: DispatchOffer["status"] | "not_offered";
  }[];
};

export type PeakWindow = { days: number[]; start: string; end: string };
export type DistanceBracket = { from_km: number; to_km: number | null; rate_cents: number };

export type PricingVersion = {
  id: string;
  version: number;
  service: ServiceType;
  zone_id: string | null;
  zone_name?: string | null;
  name: string;
  currency: string;
  rate_per_km_cents: number;
  minimum_fare_cents: number;
  base_fee_cents: number;
  waiting_fee_per_min_cents: number;
  free_waiting_minutes: number;
  cancellation_fee_cents: number;
  cancellation_free_seconds: number;
  surge_multiplier: number;
  night_multiplier: number;
  night_start: string;
  night_end: string;
  peak_multiplier: number;
  peak_windows: PeakWindow[];
  distance_brackets: DistanceBracket[];
  delivery_extras: { category?: Record<string, number>; size?: Record<string, number> };
  commission_pct: number;
  rounding_cents: number;
  effective_from: string;
  effective_to: string | null;
  created_by: string | null;
  created_by_name?: string | null;
  note: string | null;
  created_at: string;
  is_active?: boolean;
};

export type PricingVersionInput = Omit<
  PricingVersion,
  "id" | "version" | "created_by" | "created_by_name" | "created_at" | "effective_to" | "is_active" | "currency"
>;

export type PricingOverview = { active: PricingVersion[]; history: PricingVersion[] };

export type FarePreview = {
  distance_m: number;
  fare_cents: number;
  breakdown: FareBreakdown;
  pricing_version: { id: string; version: number; name: string };
};

export type CommissionSettings = { default_pct: number; by_category: Record<string, number> };

// ───────────────────────── money
export type Payment = {
  id: string;
  booking_id: string;
  booking_reference: string;
  customer_id: string;
  customer_name: string;
  driver_id: string | null;
  driver_name: string | null;
  method: PaymentMethod;
  provider: string;
  provider_ref: string | null;
  status: PaymentStatus;
  amount_cents: number;
  currency: string;
  failure_reason: string | null;
  reconciled_at?: string | null;
  created_at: string;
  updated_at: string;
};

export type PaymentDetail = Payment & {
  attempts: { attempt_no: number; status: PaymentStatus; created_at: string; response?: Record<string, unknown> }[];
  ledger: LedgerEntry[];
  refunds: Refund[];
};

export type LedgerAccount =
  | "customer"
  | "driver"
  | "platform_commission"
  | "platform_cash_clearing"
  | "provider_fees"
  | "promotions"
  | "refunds"
  | "tips"
  | "adjustments";

export type LedgerEntry = {
  id: number;
  transaction_id: string;
  kind: string;
  account: LedgerAccount;
  owner_id: string | null;
  owner_name?: string | null;
  amount_cents: number;
  currency: string;
  description: string | null;
  booking_reference?: string | null;
  created_at: string;
};

export type PayoutStatus = "requested" | "approved" | "paid" | "rejected" | "failed";
export type Payout = {
  id: string;
  driver_id: string;
  driver_name: string;
  fleet_code: string | null;
  amount_cents: number;
  method: string;
  account: string | null;
  status: PayoutStatus;
  provider_ref: string | null;
  requested_at: string;
  approved_by: string | null;
  approved_at: string | null;
  paid_at: string | null;
  note: string | null;
  wallet_balance_cents: number;
};

export type Refund = {
  id: string;
  payment_id: string;
  booking_id: string;
  booking_reference: string;
  customer_name: string;
  amount_cents: number;
  reason: string;
  status: PaymentStatus;
  provider_ref: string | null;
  requested_by: string | null;
  approved_by: string | null;
  created_at: string;
  processed_at: string | null;
};

export type FinanceSummary = {
  from: string;
  to: string;
  gbv_cents: number;
  ride_gbv_cents: number;
  delivery_gbv_cents: number;
  commission_revenue_cents: number;
  driver_payable_cents: number;
  refunds_cents: number;
  promotions_cents: number;
  provider_fees_cents: number;
  tips_cents: number;
  net_revenue_cents: number;
  cash_share_pct: number;
  bookings_count: number;
};

export type PnlRow = {
  month: string;
  gbv_cents: number;
  commission_cents: number;
  promotions_cents: number;
  refunds_cents: number;
  provider_fees_cents: number;
  net_revenue_cents: number;
  bookings: number;
};

export type CashReconciliationRow = {
  driver_id: string;
  driver_name: string;
  fleet_code: string | null;
  cash_collected_cents: number;
  commission_due_cents: number;
  digital_cents: number;
  reconciled: boolean;
};
export type CashReconciliation = {
  date: string;
  rows: CashReconciliationRow[];
  totals: { cash_collected_cents: number; commission_due_cents: number; digital_cents: number };
};

export type MonthlyStatement = {
  month: string;
  driver_id: string;
  driver_name: string;
  fleet_code: string | null;
  trips: number;
  gross_cents: number;
  commission_cents: number;
  net_cents: number;
  paid_out_cents: number;
};

// ───────────────────────── promotions
export type Promotion = {
  id: string;
  code: string;
  name: string;
  type: "percent" | "fixed";
  value: number;
  max_discount_cents: number | null;
  min_fare_cents: number;
  service: ServiceType | null;
  first_n_bookings: number | null;
  max_uses_total: number | null;
  max_uses_per_user: number;
  uses_count: number;
  starts_at: string;
  ends_at: string | null;
  active: boolean;
  created_at: string;
};
export type PromotionInput = Omit<Promotion, "id" | "uses_count" | "created_at">;
export type Redemption = {
  id: string;
  promotion_id: string;
  user_id: string;
  user_name: string;
  booking_id: string;
  booking_reference: string;
  discount_cents: number;
  created_at: string;
};

// ───────────────────────── notifications & sms
export type BroadcastInput = {
  audience: "customers" | "drivers" | "segment";
  segment?: string;
  title_so: string;
  title_en: string;
  body_so: string;
  body_en: string;
  channel: "push" | "sms" | "in_app";
  scheduled_for?: string | null;
};
export type NotificationLogEntry = {
  id: string;
  audience: string;
  channel: "push" | "sms" | "in_app";
  title_so: string;
  title_en: string;
  body_so: string;
  body_en: string;
  recipients: number;
  delivered: number;
  failed: number;
  sent_by: string;
  sent_at: string;
  status: "sent" | "scheduled" | "failed";
};

export type SmsLogEntry = {
  id: number;
  phone_e164: string;
  provider: string;
  purpose: string;
  status: "sent" | "delivered" | "failed" | "queued";
  provider_ref: string | null;
  cost_cents: number | null;
  error: string | null;
  created_at: string;
};
export type SmsSettings = {
  provider: "console" | "http" | "twilio";
  sender_id: string;
  otp_ttl_s: number;
  otp_length: number;
  resend_after_s: number;
  max_sends_per_phone_per_hour: number;
  test_numbers: string[];
  http_gateway_url?: string | null;
};

// ───────────────────────── support
export type TicketStatus = "open" | "in_progress" | "waiting_customer" | "resolved" | "closed";
export type TicketCategory = "ride" | "delivery" | "payment" | "lost_item" | "incident" | "account" | "driver" | "other";
export type Ticket = {
  id: string;
  reference: string;
  user_id: string;
  user_name: string;
  user_role: UserRole;
  booking_id: string | null;
  booking_reference: string | null;
  category: TicketCategory;
  subject: string;
  status: TicketStatus;
  priority: 1 | 2 | 3 | 4;
  assigned_to: string | null;
  assigned_name: string | null;
  is_incident: boolean;
  created_at: string;
  updated_at: string;
  resolved_at: string | null;
};
export type TicketMessage = {
  id: string;
  ticket_id: string;
  author_id: string;
  author_name: string;
  author_role: UserRole;
  body: string;
  internal: boolean;
  created_at: string;
};
export type TicketDetail = Ticket & { messages: TicketMessage[] };

export type Incident = {
  id: string;
  booking_id: string | null;
  booking_reference: string | null;
  reporter_id: string;
  reporter_name: string;
  reporter_role: UserRole;
  kind: "sos" | "accident" | "harassment" | "lost_item" | "dispute" | "other";
  description: string | null;
  location: LatLng | null;
  status: "open" | "acknowledged" | "resolved";
  handled_by: string | null;
  created_at: string;
  resolved_at: string | null;
};

// ───────────────────────── zones
export type Zone = {
  id: string;
  key: string;
  name: string;
  kind: "service_area" | "surge" | "restricted";
  polygon: LatLng[];
  active: boolean;
  dispatch_radius_steps_m: number[];
  max_search_seconds: number;
  created_at: string;
  updated_at: string;
};
export type ZoneInput = Omit<Zone, "id" | "created_at" | "updated_at">;

// ───────────────────────── CMS & app content
export type BlockType = "hero" | "service_cards" | "steps" | "faq" | "rich_text" | "cta" | "banner";
export type LocalisedBlockContent = Record<string, unknown>;
export type CmsBlock = { id: string; type: BlockType; so: LocalisedBlockContent; en: LocalisedBlockContent };
export type CmsPage = {
  id: string;
  slug: string;
  title_so: string;
  title_en: string;
  blocks: CmsBlock[];
  seo: { title_so?: string; title_en?: string; description_so?: string; description_en?: string };
  published: boolean;
  updated_by: string | null;
  updated_at: string;
};
export type Faq = {
  id: string;
  category: string;
  question_so: string;
  answer_so: string;
  question_en: string;
  answer_en: string;
  sort_order: number;
  published: boolean;
};
export type Banner = {
  id: string;
  placement: "web_home_hero" | "app_home" | "app_promo";
  title_so: string | null;
  title_en: string | null;
  body_so: string | null;
  body_en: string | null;
  image_url: string | null;
  link_url: string | null;
  starts_at: string | null;
  ends_at: string | null;
  sort_order: number;
  published: boolean;
};
export type Testimonial = {
  id: string;
  author: string;
  role: string | null;
  quote_so: string | null;
  quote_en: string | null;
  approved: boolean;
  created_at: string;
};
export type ContactMessage = {
  id: string;
  name: string;
  phone: string | null;
  email: string | null;
  subject: string | null;
  body: string;
  handled: boolean;
  created_at: string;
};

export type AppContent = {
  home_cards: {
    ride: { title: string; so: string; en: string };
    delivery: { title: string; so: string; en: string };
  };
  onboarding: { so: string; en: string }[];
  promo_banners: { id: string; title_so: string; title_en: string; link_url: string | null; active: boolean }[];
  support_phone: string;
  support_whatsapp: string | null;
};

export type Settings = {
  brand: {
    name: string;
    tagline_so: string;
    tagline_en: string;
    support_phone: string;
    support_email: string;
    website: string;
  };
  locale: {
    default_language: Language;
    languages: Language[];
    currency: string;
    timezone: string;
    country_code: string;
  };
  maps: {
    tiles: "osm" | "google" | "mapbox";
    routing_provider: "osrm" | "google" | "mapbox";
    geocoding_provider: "nominatim" | "google" | "mapbox";
    center: LatLng;
    default_zoom: number;
  };
  features: {
    scheduled_bookings: boolean;
    tips: boolean;
    favourite_drivers: boolean;
    card_payments: boolean;
    wallet: boolean;
  };
  delivery: { max_weight_kg: number; recipient_otp: boolean };
};

// ───────────────────────── roles, audit, security
export type Role = {
  id: string;
  key: string;
  name: string;
  permissions: string[];
  is_system: boolean;
  admins_count: number;
  created_at: string;
};
export type AdminListItem = {
  id: string;
  email: string;
  full_name: string;
  roles: string[];
  status: UserStatus;
  totp_enabled: boolean;
  last_seen_at: string | null;
  created_at: string;
};

export type AuditLog = {
  id: number;
  actor_id: string | null;
  actor_name: string | null;
  actor_role: string | null;
  action: string;
  entity_type: string | null;
  entity_id: string | null;
  before: Record<string, unknown> | null;
  after: Record<string, unknown> | null;
  ip: string | null;
  user_agent: string | null;
  created_at: string;
};

export type Session = {
  id: string;
  user_id: string;
  user_name: string;
  user_role: UserRole;
  device: string;
  platform: string;
  ip: string | null;
  user_agent: string | null;
  created_at: string;
  last_active_at: string;
  expires_at: string;
  current: boolean;
};

export type SystemHealth = {
  status: "ok" | "degraded" | "down";
  version: string;
  uptime_s: number;
  queues: { name: string; waiting: number; active: number; failed: number; delayed: number }[];
  sockets: { connections: number; drivers: number; customers: number; admins: number };
  providers: { name: string; kind: string; mode: "live" | "sandbox" | "console"; status: "ok" | "degraded" | "down"; latency_ms: number | null }[];
  database: { status: "ok" | "down"; latency_ms: number; connections: number };
  redis: { status: "ok" | "down"; latency_ms: number; memory_mb: number };
  checked_at: string;
};

// ───────────────────────── overview, live, reports
export type OverviewRange = "today" | "7d" | "30d";
export type Overview = {
  range: OverviewRange;
  customers: number;
  customers_new: number;
  drivers: number;
  drivers_online: number;
  active_rides: number;
  active_deliveries: number;
  completed: number;
  cancelled: number;
  gbv_cents: number;
  commission_revenue_cents: number;
  driver_earnings_cents: number;
  outstanding_balances_cents: number;
  customer_growth_pct: number;
  service_split: { ride: number; delivery: number };
  top_zones: { zone_key: string; zone_name: string; bookings: number; gbv_cents: number }[];
  deltas: Partial<Record<"gbv_cents" | "commission_revenue_cents" | "completed" | "cancelled" | "customers_new", number>>;
};
export type TimeseriesPoint = { t: string; value: number; ride?: number; delivery?: number };
export type Timeseries = { metric: string; range: string; granularity: "day" | "week" | "month"; points: TimeseriesPoint[] };

export type LiveDriver = {
  driver_id: string;
  full_name: string;
  fleet_code: string | null;
  availability: DriverAvailability;
  location: LatLng;
  heading: number;
  booking_id: string | null;
  updated_at: string;
};
export type LiveBooking = BookingSummary & {
  driver_location: LatLng | null;
  route: LatLng[];
  eta_s: number | null;
};

export type ReportName = "bookings" | "drivers" | "customers" | "revenue" | "cancellations" | "zones" | "promotions";
export type Report = {
  name: ReportName;
  from: string;
  to: string;
  columns: { key: string; label: string; kind: "text" | "number" | "money" | "percent" | "date" }[];
  rows: Record<string, string | number | null>[];
  chart: { x: string; series: { key: string; label: string }[] } | null;
};
