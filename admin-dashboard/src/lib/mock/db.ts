/* eslint-disable @typescript-eslint/no-non-null-assertion */
import type {
  AdminListItem,
  AppContent,
  AuditLog,
  Banner,
  Booking,
  BookingStatus,
  CmsPage,
  CommissionSettings,
  ContactMessage,
  Customer,
  DeliveryCategory,
  DispatchOffer,
  DispatchSettings,
  Driver,
  DriverDocument,
  Faq,
  Incident,
  LatLng,
  LedgerAccount,
  LedgerEntry,
  NotificationLogEntry,
  Payment,
  PaymentMethod,
  Payout,
  PricingVersion,
  Promotion,
  Redemption,
  Refund,
  Role,
  Session,
  Settings,
  SmsLogEntry,
  SmsSettings,
  Testimonial,
  Ticket,
  TicketMessage,
  TimelineEvent,
  Vehicle,
  Zone,
} from "@/lib/api/types";
import { Rng } from "./rng";
import { computeFare } from "./fare";

export const GAROWE: LatLng = { lat: 8.4064, lng: 48.4847 };

export const LANDMARKS: { name: string; loc: LatLng }[] = [
  { name: "Suuqa Weyn", loc: { lat: 8.4059, lng: 48.4836 } },
  { name: "Garowe General Hospital", loc: { lat: 8.4094, lng: 48.4882 } },
  { name: "Puntland State University", loc: { lat: 8.3989, lng: 48.4777 } },
  { name: "Garowe Airport road", loc: { lat: 8.4231, lng: 48.5011 } },
  { name: "Jidka Boosaaso", loc: { lat: 8.4188, lng: 48.4902 } },
  { name: "Xaafadda Israac", loc: { lat: 8.4117, lng: 48.4751 } },
  { name: "Xaafadda Waaberi", loc: { lat: 8.4003, lng: 48.4918 } },
  { name: "Xaafadda Hodan", loc: { lat: 8.3952, lng: 48.4861 } },
  { name: "Xaafadda Horseed", loc: { lat: 8.4146, lng: 48.4965 } },
  { name: "Xaafadda Wadajir", loc: { lat: 8.3927, lng: 48.4789 } },
  { name: "Xaafadda Shabelle", loc: { lat: 8.4081, lng: 48.4705 } },
  { name: "Garowe Stadium", loc: { lat: 8.3978, lng: 48.4941 } },
  { name: "Masjidka Kuwait", loc: { lat: 8.4042, lng: 48.4812 } },
  { name: "Suuqa Khayriya", loc: { lat: 8.4027, lng: 48.4866 } },
  { name: "Jidka Qardho", loc: { lat: 8.4262, lng: 48.4849 } },
  { name: "Garowe Teaching Hospital", loc: { lat: 8.4134, lng: 48.4817 } },
  { name: "Madaxtooyada", loc: { lat: 8.4088, lng: 48.4931 } },
  { name: "Xaafadda Dayax", loc: { lat: 8.3899, lng: 48.4892 } },
  { name: "Xaafadda Hantiwadaag", loc: { lat: 8.4175, lng: 48.4789 } },
  { name: "Buundada Garoowe", loc: { lat: 8.4116, lng: 48.4874 } },
];

export const PERMISSION_CATALOGUE: Record<string, string[]> = {
  super_admin: ["*"],
  operations: [
    "overview.read",
    "live.read",
    "bookings.read",
    "bookings.write",
    "dispatch.read",
    "dispatch.write",
    "drivers.read",
    "drivers.write",
    "vehicles.read",
    "vehicles.write",
    "customers.read",
    "zones.read",
    "zones.write",
    "support.read",
    "support.write",
    "notifications.write",
    "reports.read",
  ],
  finance: [
    "overview.read",
    "payments.read",
    "payments.write",
    "payouts.read",
    "payouts.write",
    "finance.read",
    "refunds.read",
    "refunds.write",
    "commission.read",
    "commission.write",
    "pricing.read",
    "reports.read",
    "audit.read",
  ],
  verification: ["drivers.read", "drivers.verify", "vehicles.read", "vehicles.write", "audit.read"],
  support: ["customers.read", "bookings.read", "support.read", "support.write", "refunds.read", "notifications.read"],
  marketing: [
    "promotions.read",
    "promotions.write",
    "cms.read",
    "cms.write",
    "app_content.read",
    "app_content.write",
    "notifications.write",
    "reports.read",
  ],
  auditor: [
    "overview.read",
    "bookings.read",
    "drivers.read",
    "customers.read",
    "payments.read",
    "payouts.read",
    "finance.read",
    "pricing.read",
    "audit.read",
    "reports.read",
    "settings.read",
  ],
};

export type MockAdmin = AdminListItem & { password: string; totp_secret: string | null };

export type LedgerTx = {
  id: string;
  kind: string;
  booking_id: string | null;
  payment_id: string | null;
  payout_id: string | null;
  description: string | null;
  created_at: string;
};

export type DbShape = {
  seededAt: number;
  zones: Zone[];
  vehicles: Vehicle[];
  drivers: Driver[];
  documents: DriverDocument[];
  customers: Customer[];
  pricing: PricingVersion[];
  bookings: Booking[];
  payments: Payment[];
  ledgerTx: LedgerTx[];
  ledger: LedgerEntry[];
  payouts: Payout[];
  refunds: Refund[];
  promotions: Promotion[];
  redemptions: Redemption[];
  tickets: Ticket[];
  ticketMessages: TicketMessage[];
  incidents: Incident[];
  notificationLog: NotificationLogEntry[];
  smsLog: SmsLogEntry[];
  smsSettings: SmsSettings;
  dispatch: DispatchSettings;
  commission: CommissionSettings;
  settings: Settings;
  appContent: AppContent;
  cmsPages: CmsPage[];
  faqs: Faq[];
  banners: Banner[];
  testimonials: Testimonial[];
  contactMessages: ContactMessage[];
  roles: Role[];
  admins: MockAdmin[];
  audit: AuditLog[];
  sessions: Session[];
  counters: { ledgerEntry: number; audit: number; sms: number; timeline: number; bookingRef: number; ticketRef: number };
};

const CATEGORIES: DeliveryCategory[] = ["food", "shopping", "parcel", "document", "pharmacy", "other"];
const METHODS: [PaymentMethod, number][] = [
  ["cash", 72],
  ["evc_plus", 14],
  ["zaad", 8],
  ["sahal", 4],
  ["sandbox", 2],
];

const RIDE_FLOW: BookingStatus[] = [
  "requested",
  "searching",
  "accepted",
  "driver_arriving",
  "arrived",
  "in_progress",
  "completed",
  "paid",
];
const DELIVERY_FLOW: BookingStatus[] = [
  "requested",
  "searching",
  "accepted",
  "driver_arriving",
  "arrived_pickup",
  "collected",
  "in_transit",
  "arrived_dropoff",
  "recipient_verified",
  "delivered",
  "paid",
];

function iso(ms: number): string {
  return new Date(ms).toISOString();
}
function jitter(rng: Rng, loc: LatLng, r = 0.004): LatLng {
  return { lat: +(loc.lat + rng.float(-r, r)).toFixed(5), lng: +(loc.lng + rng.float(-r, r)).toFixed(5) };
}
export function haversineM(a: LatLng, b: LatLng): number {
  const R = 6371000;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const s =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((a.lat * Math.PI) / 180) * Math.cos((b.lat * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(s));
}
export function roadLine(rng: Rng, from: LatLng, to: LatLng): LatLng[] {
  // crude "road-ish" polyline: 4 intermediate points with lateral wobble
  const pts: LatLng[] = [from];
  for (let i = 1; i <= 4; i++) {
    const t = i / 5;
    pts.push({
      lat: +(from.lat + (to.lat - from.lat) * t + rng.float(-0.0008, 0.0008)).toFixed(5),
      lng: +(from.lng + (to.lng - from.lng) * t + rng.float(-0.0008, 0.0008)).toFixed(5),
    });
  }
  pts.push(to);
  return pts;
}

export function buildDb(seed = 20261018): DbShape {
  const rng = new Rng(seed);
  const now = Date.now();
  const DAY = 86_400_000;
  const HOUR = 3_600_000;
  const start = now - 30 * DAY;
  const counters = { ledgerEntry: 1, audit: 1, sms: 1, timeline: 1, bookingRef: 1000, ticketRef: 500 };

  // ── zones
  const zones: Zone[] = [
    {
      id: rng.uuid(),
      key: "garowe",
      name: "Garowe",
      kind: "service_area",
      polygon: [
        { lat: 8.435, lng: 48.455 },
        { lat: 8.435, lng: 48.515 },
        { lat: 8.375, lng: 48.515 },
        { lat: 8.375, lng: 48.455 },
      ],
      active: true,
      dispatch_radius_steps_m: [2000, 4000, 7000],
      max_search_seconds: 180,
      created_at: iso(start - 20 * DAY),
      updated_at: iso(start - 2 * DAY),
    },
    {
      id: rng.uuid(),
      key: "airport-road",
      name: "Airport road (surge)",
      kind: "surge",
      polygon: [
        { lat: 8.428, lng: 48.495 },
        { lat: 8.428, lng: 48.512 },
        { lat: 8.416, lng: 48.512 },
        { lat: 8.416, lng: 48.495 },
      ],
      active: true,
      dispatch_radius_steps_m: [3000, 5000, 7000],
      max_search_seconds: 240,
      created_at: iso(start - 10 * DAY),
      updated_at: iso(start - 10 * DAY),
    },
    {
      id: rng.uuid(),
      key: "state-house-restricted",
      name: "State House perimeter (restricted)",
      kind: "restricted",
      polygon: [
        { lat: 8.4105, lng: 48.4915 },
        { lat: 8.4105, lng: 48.4948 },
        { lat: 8.4072, lng: 48.4948 },
        { lat: 8.4072, lng: 48.4915 },
      ],
      active: true,
      dispatch_radius_steps_m: [2000, 4000, 7000],
      max_search_seconds: 180,
      created_at: iso(start - 5 * DAY),
      updated_at: iso(start - 5 * DAY),
    },
  ];
  const garowe = zones[0]!;

  // ── pricing versions
  const pricing: PricingVersion[] = [];
  const basePv = (over: Partial<PricingVersion>): PricingVersion => ({
    id: rng.uuid(),
    version: 1,
    service: "ride",
    zone_id: null,
    zone_name: null,
    name: "Launch pricing — Ride",
    currency: "USD",
    rate_per_km_cents: 50,
    minimum_fare_cents: 100,
    base_fee_cents: 0,
    waiting_fee_per_min_cents: 0,
    free_waiting_minutes: 3,
    cancellation_fee_cents: 0,
    cancellation_free_seconds: 120,
    surge_multiplier: 1,
    night_multiplier: 1,
    night_start: "22:00",
    night_end: "05:00",
    peak_multiplier: 1,
    peak_windows: [],
    distance_brackets: [],
    delivery_extras: {},
    commission_pct: 15,
    rounding_cents: 10,
    effective_from: iso(start - 15 * DAY),
    effective_to: null,
    created_by: null,
    created_by_name: "System seed",
    note: "$1 per 2 km initial default",
    created_at: iso(start - 15 * DAY),
    ...over,
  });
  pricing.push(
    basePv({ effective_to: iso(start + 12 * DAY) }),
    basePv({
      version: 2,
      name: "Ride v2 — night uplift",
      night_multiplier: 1.2,
      peak_multiplier: 1.1,
      peak_windows: [
        { days: [1, 2, 3, 4, 5, 6], start: "07:00", end: "09:00" },
        { days: [1, 2, 3, 4, 5, 6], start: "16:30", end: "18:30" },
      ],
      waiting_fee_per_min_cents: 5,
      cancellation_fee_cents: 50,
      effective_from: iso(start + 12 * DAY),
      effective_to: null,
      created_by_name: "Admin 0001",
      note: "Added night (22:00–05:00) and peak windows after driver feedback.",
      created_at: iso(start + 11 * DAY),
    }),
    basePv({
      service: "delivery",
      name: "Launch pricing — Delivery",
      delivery_extras: { category: { food: 0, pharmacy: 50, shopping: 30 }, size: { medium: 50, large: 100 } },
      created_at: iso(start - 15 * DAY),
    }),
    basePv({
      service: "ride",
      zone_id: zones[1]!.id,
      zone_name: zones[1]!.name,
      name: "Airport road surge",
      surge_multiplier: 1.3,
      effective_from: iso(start + 5 * DAY),
      created_by_name: "Admin 0001",
      note: "Flat surge on the airport corridor during flight days.",
      created_at: iso(start + 5 * DAY),
    }),
  );
  const activePricing = (service: "ride" | "delivery", at: number) =>
    pricing
      .filter(
        (p) =>
          p.service === service &&
          p.zone_id === null &&
          new Date(p.effective_from).getTime() <= at &&
          (!p.effective_to || new Date(p.effective_to).getTime() > at),
      )
      .sort((a, b) => b.version - a.version)[0]!;

  // ── vehicles & drivers
  const vehicles: Vehicle[] = [];
  const drivers: Driver[] = [];
  const documents: DriverDocument[] = [];
  const colours = ["Blue", "Yellow", "Green", "Red", "Black", "White"];
  const driverCount = 140;
  let fleetSeq = 1;
  for (let i = 1; i <= driverCount; i++) {
    const verification = rng.weighted<Driver["driver_profile"]["verification"]>([
      ["approved", 78],
      ["pending", 9],
      ["under_review", 7],
      ["rejected", 3],
      ["suspended", 3],
    ]);
    const createdAt = now - rng.int(2, 120) * DAY;
    const id = rng.uuid();
    const approved = verification === "approved" || verification === "suspended";
    const vehicle: Vehicle = {
      id: rng.uuid(),
      fleet_code: approved ? `BG-${String(fleetSeq++).padStart(4, "0")}` : null,
      plate_number: `PL ${rng.int(10, 99)}${rng.pick(["A", "B", "C", "D"])} ${rng.int(100, 999)}`,
      make_model: rng.weighted([
        ["Bajaj RE", 70],
        ["TVS King", 20],
        ["Piaggio Ape", 10],
      ]),
      colour: rng.pick(colours),
      year: rng.int(2015, 2025),
      seats: 3,
      max_parcel_kg: 30,
      livery: approved ? rng.weighted([["sticker_kit", 60], ["full_wrap", 15], ["none", 25]]) : "none",
      active: verification !== "rejected",
      driver_id: id,
      driver_name: `Driver ${String(i).padStart(4, "0")}`,
      created_at: iso(createdAt),
      updated_at: iso(createdAt),
    };
    vehicles.push(vehicle);
    const availability: Driver["driver_profile"]["availability"] =
      verification === "approved" ? rng.weighted([["online", 32], ["offline", 60], ["on_trip", 8]]) : "offline";
    const totalRides = approved ? rng.int(5, 420) : 0;
    const totalDeliveries = approved ? rng.int(0, 160) : 0;
    const loc = jitter(rng, rng.pick(LANDMARKS).loc, 0.006);
    drivers.push({
      id,
      role: "driver",
      phone: `+25290${rng.int(1000000, 9999999)}`,
      full_name: `Driver ${String(i).padStart(4, "0")}`,
      language: rng.chance(0.85) ? "so" : "en",
      avatar_url: null,
      status: verification === "suspended" ? "suspended" : "active",
      last_seen_at: iso(now - rng.int(1, 600) * 60000),
      created_at: iso(createdAt),
      driver_profile: {
        verification,
        verification_notes: verification === "rejected" ? "Licence photo unreadable; vehicle insurance expired." : null,
        verified_at: approved ? iso(createdAt + rng.int(1, 5) * DAY) : null,
        availability,
        accepts_rides: true,
        accepts_deliveries: rng.chance(0.92),
        rating_avg: approved ? +rng.float(3.9, 5).toFixed(2) : 5,
        rating_count: Math.round(totalRides * 0.6),
        total_rides: totalRides,
        total_deliveries: totalDeliveries,
        acceptance_rate: approved ? +rng.float(62, 99).toFixed(1) : 100,
        commission_pct: rng.chance(0.08) ? rng.pick([10, 12.5, 20]) : null,
        emergency_contact_name: `Contact ${String(i).padStart(4, "0")}`,
        emergency_contact_phone: `+25290${rng.int(1000000, 9999999)}`,
        payout_method: rng.weighted([["evc_plus", 55], ["zaad", 30], ["sahal", 10], ["cash", 5]]),
        payout_account: `+25290${rng.int(1000000, 9999999)}`,
        last_location: availability === "offline" && rng.chance(0.3) ? null : loc,
        last_location_at: iso(now - rng.int(5, 900) * 1000),
        heading: rng.int(0, 359),
        online_since: availability !== "offline" ? iso(now - rng.int(10, 540) * 60000) : null,
        vehicle,
      },
    });
    const docTypes: DriverDocument["type"][] = [
      "national_id",
      "driving_licence",
      "vehicle_registration",
      "vehicle_insurance",
      "vehicle_photo_front",
      "vehicle_photo_side",
      "vehicle_photo_rear",
      "profile_photo",
    ];
    for (const type of docTypes) {
      const status: DriverDocument["status"] =
        verification === "approved"
          ? rng.chance(0.03)
            ? "expired"
            : "approved"
          : verification === "rejected"
            ? rng.pick(["rejected", "approved", "pending"])
            : verification === "under_review"
              ? rng.pick(["pending", "approved", "pending"])
              : "pending";
      documents.push({
        id: rng.uuid(),
        driver_id: id,
        type,
        file_url: `/mock/docs/${type}.svg`,
        status,
        expires_at:
          type === "vehicle_insurance" || type === "driving_licence"
            ? iso(now + (status === "expired" ? -rng.int(1, 40) : rng.int(30, 700)) * DAY).slice(0, 10)
            : null,
        reviewed_by: status === "pending" ? null : "admin-0003",
        reviewed_at: status === "pending" ? null : iso(createdAt + 2 * DAY),
        review_note: status === "rejected" ? "Image is blurry; please re-upload in daylight." : null,
        created_at: iso(createdAt + rng.int(0, 2) * HOUR),
      });
    }
  }
  const approvedDrivers = drivers.filter((d) => d.driver_profile.verification === "approved");

  // ── customers
  const customers: Customer[] = [];
  const customerCount = 480;
  for (let i = 1; i <= customerCount; i++) {
    const createdAt = now - rng.int(0, 150) * DAY - rng.int(0, 23) * HOUR;
    customers.push({
      id: rng.uuid(),
      role: "customer",
      phone: `+25290${rng.int(1000000, 9999999)}`,
      full_name: `Customer ${String(i).padStart(4, "0")}`,
      language: rng.chance(0.8) ? "so" : "en",
      avatar_url: null,
      status: rng.weighted([["active", 95], ["suspended", 3], ["deleted", 2]]),
      last_seen_at: iso(now - rng.int(1, 20000) * 60000),
      created_at: iso(createdAt),
      rating_avg: +rng.float(4.2, 5).toFixed(2),
      rating_count: 0,
      total_rides: 0,
      total_deliveries: 0,
      referral_code: `BJ${rng.hex(5).toUpperCase()}`,
      spend_cents: 0,
      outstanding_cents: 0,
    });
  }

  // ── promotions
  const promotions: Promotion[] = [
    {
      id: rng.uuid(),
      code: "BAJGO3",
      name: "First 3 rides launch offer",
      type: "percent",
      value: 20,
      max_discount_cents: 100,
      min_fare_cents: 100,
      service: "ride",
      first_n_bookings: 3,
      max_uses_total: 5000,
      max_uses_per_user: 3,
      uses_count: 0,
      starts_at: iso(start - 5 * DAY),
      ends_at: iso(now + 40 * DAY),
      active: true,
      created_at: iso(start - 6 * DAY),
    },
    {
      id: rng.uuid(),
      code: "DIRID50",
      name: "Delivery 50c off",
      type: "fixed",
      value: 50,
      max_discount_cents: null,
      min_fare_cents: 150,
      service: "delivery",
      first_n_bookings: null,
      max_uses_total: 1000,
      max_uses_per_user: 2,
      uses_count: 0,
      starts_at: iso(start + 3 * DAY),
      ends_at: iso(now + 10 * DAY),
      active: true,
      created_at: iso(start + 2 * DAY),
    },
    {
      id: rng.uuid(),
      code: "EID26",
      name: "Eid weekend 10%",
      type: "percent",
      value: 10,
      max_discount_cents: 80,
      min_fare_cents: 0,
      service: null,
      first_n_bookings: null,
      max_uses_total: null,
      max_uses_per_user: 5,
      uses_count: 0,
      starts_at: iso(start - 40 * DAY),
      ends_at: iso(start - 36 * DAY),
      active: false,
      created_at: iso(start - 45 * DAY),
    },
  ];
  const redemptions: Redemption[] = [];

  // ── bookings + money
  const bookings: Booking[] = [];
  const payments: Payment[] = [];
  const ledgerTx: LedgerTx[] = [];
  const ledger: LedgerEntry[] = [];
  const refunds: Refund[] = [];
  const nameOf = new Map<string, string>();
  drivers.forEach((d) => nameOf.set(d.id, d.full_name));
  customers.forEach((c) => nameOf.set(c.id, c.full_name));

  const addTx = (
    kind: string,
    entries: { account: LedgerAccount; owner_id: string | null; amount_cents: number }[],
    meta: { booking_id?: string | null; payment_id?: string | null; payout_id?: string | null; description?: string; at: number; booking_reference?: string },
  ) => {
    const sum = entries.reduce((s, e) => s + e.amount_cents, 0);
    if (sum !== 0) throw new Error(`mock ledger tx ${kind} does not balance (${sum})`);
    const tx: LedgerTx = {
      id: rng.uuid(),
      kind,
      booking_id: meta.booking_id ?? null,
      payment_id: meta.payment_id ?? null,
      payout_id: meta.payout_id ?? null,
      description: meta.description ?? null,
      created_at: iso(meta.at),
    };
    ledgerTx.push(tx);
    for (const e of entries) {
      ledger.push({
        id: counters.ledgerEntry++,
        transaction_id: tx.id,
        kind,
        account: e.account,
        owner_id: e.owner_id,
        owner_name: e.owner_id ? (nameOf.get(e.owner_id) ?? null) : null,
        amount_cents: e.amount_cents,
        currency: "USD",
        description: tx.description,
        booking_reference: meta.booking_reference ?? null,
        created_at: tx.created_at,
      });
    }
    return tx;
  };

  const bookingRef = (at: number) => {
    const d = new Date(at);
    const yymmdd = `${String(d.getUTCFullYear()).slice(2)}${String(d.getUTCMonth() + 1).padStart(2, "0")}${String(d.getUTCDate()).padStart(2, "0")}`;
    return `BJ${yymmdd}-${String(counters.bookingRef++).padStart(5, "0")}`;
  };

  // volume curve: grows over the 30 days, with evening peaks
  const totalBookings = 1650;
  const bookingTimes: number[] = [];
  for (let i = 0; i < totalBookings; i++) {
    const dayIdx = Math.floor(Math.pow(rng.next(), 0.72) * 30); // skew to recent days
    const hour = rng.weighted([
      [rng.int(6, 9), 22],
      [rng.int(10, 15), 30],
      [rng.int(16, 20), 36],
      [rng.int(21, 23), 8],
      [rng.int(0, 5), 4],
    ]);
    const t = start + dayIdx * DAY + hour * HOUR + rng.int(0, 59) * 60000;
    if (t < now - 10 * 60000) bookingTimes.push(t);
  }
  bookingTimes.sort((a, b) => a - b);

  const activeStatusesRide: BookingStatus[] = ["searching", "accepted", "driver_arriving", "arrived", "in_progress"];
  const activeStatusesDelivery: BookingStatus[] = [
    "searching",
    "accepted",
    "driver_arriving",
    "arrived_pickup",
    "collected",
    "in_transit",
    "arrived_dropoff",
  ];

  const onTripDrivers = drivers.filter((d) => d.driver_profile.availability === "on_trip");
  let onTripIdx = 0;

  const makeBooking = (createdAt: number, forceActive?: BookingStatus): Booking => {
    const service: "ride" | "delivery" = rng.chance(0.68) ? "ride" : "delivery";
    const customer = rng.pick(customers);
    const pickL = rng.pick(LANDMARKS);
    let dropL = rng.pick(LANDMARKS);
    while (dropL === pickL) dropL = rng.pick(LANDMARKS);
    const pickup = { location: jitter(rng, pickL.loc), address: `${pickL.name}, Garoowe`, landmark: pickL.name };
    const dropoff = { location: jitter(rng, dropL.loc), address: `${dropL.name}, Garoowe`, landmark: dropL.name };
    const straight = haversineM(pickup.location, dropoff.location);
    const distance_m = Math.round(straight * rng.float(1.15, 1.4));
    const duration_s = Math.round((distance_m / 1000 / 22) * 3600 + rng.int(60, 180));
    const pv = activePricing(service, createdAt);
    const category = service === "delivery" ? rng.pick(CATEGORIES) : null;
    const size = service === "delivery" ? rng.weighted<"small" | "medium" | "large">([["small", 60], ["medium", 30], ["large", 10]]) : null;
    const promo =
      rng.chance(0.09) && promotions.find((p) => p.active && (p.service === null || p.service === service))
        ? promotions.find((p) => p.active && (p.service === null || p.service === service))!
        : null;
    const pre = computeFare(pv, { service, distance_m, at: new Date(createdAt), delivery: { category: category ?? undefined, size: size ?? undefined } });
    let discount = 0;
    if (promo) {
      discount = promo.type === "percent" ? Math.round((pre.fare_cents * promo.value) / 100) : promo.value;
      if (promo.max_discount_cents) discount = Math.min(discount, promo.max_discount_cents);
      discount = Math.min(discount, pre.fare_cents);
    }
    const waiting_seconds = rng.chance(0.25) ? rng.int(60, 600) : 0;
    const quote = computeFare(pv, {
      service,
      distance_m,
      at: new Date(createdAt),
      discount_cents: discount,
      delivery: { category: category ?? undefined, size: size ?? undefined },
    });
    const payment_method = rng.weighted(METHODS);
    const flow = service === "ride" ? RIDE_FLOW : DELIVERY_FLOW;

    // outcome
    let finalStatus: BookingStatus;
    if (forceActive) finalStatus = forceActive;
    else
      finalStatus = rng.weighted<BookingStatus>([
        ["paid", 78],
        [service === "ride" ? "completed" : "delivered", 4],
        ["cancelled_by_customer", 8],
        ["cancelled_by_driver", 3],
        ["cancelled_by_admin", 1],
        ["expired", 4],
        ["failed", service === "delivery" ? 2 : 0],
      ]);

    const id = rng.uuid();
    const reference = bookingRef(createdAt);
    const timeline: TimelineEvent[] = [];
    let t = createdAt;
    const push = (from: BookingStatus | null, to: BookingStatus, actor: TimelineEvent["actor_role"], reason: string | null = null) => {
      timeline.push({ id: counters.timeline++, from_status: from, to_status: to, actor_role: actor, reason, at: iso(t) });
    };
    push(null, "quoted", "customer");
    t += rng.int(5, 40) * 1000;

    const isActive = forceActive !== undefined;
    const cancelled = finalStatus.startsWith("cancelled") || finalStatus === "expired";
    const stopAtIdx = isActive ? flow.indexOf(finalStatus) : cancelled ? rng.int(1, 4) : finalStatus === "failed" ? flow.indexOf("arrived_dropoff") : flow.indexOf(finalStatus);

    let driver: Driver | null = null;
    const offers: DispatchOffer[] = [];
    let prev: BookingStatus = "quoted";
    let acceptedAt: number | null = null;
    let completedAt: number | null = null;
    let startedAt: number | null = null;
    for (let i = 0; i <= stopAtIdx; i++) {
      const s = flow[i]!;
      if (s === "searching") {
        push(prev, s, "system");
        // dispatch offers
        const rounds = cancelled || finalStatus === "expired" ? rng.int(1, 3) : rng.int(1, 2);
        let offerT = t;
        for (let r = 1; r <= rounds; r++) {
          const n = rng.int(1, 3);
          for (let k = 0; k < n; k++) {
            const cand = rng.pick(approvedDrivers);
            const last = r === rounds && k === n - 1 && !cancelled && finalStatus !== "expired";
            const status: DispatchOffer["status"] = last && stopAtIdx > 1 ? "accepted" : rng.weighted([["timed_out", 60], ["rejected", 40]]);
            const d = rng.int(300, 2500);
            offers.push({
              id: rng.uuid(),
              booking_id: id,
              driver_id: cand.id,
              driver_name: cand.full_name,
              fleet_code: cand.driver_profile.vehicle?.fleet_code ?? null,
              round: r,
              radius_m: [2000, 4000, 7000][Math.min(r - 1, 2)]!,
              eta_seconds: Math.round(d / 6),
              distance_m: d,
              status,
              offered_at: iso(offerT),
              expires_at: iso(offerT + 20000),
              responded_at: status === "timed_out" ? iso(offerT + 20000) : iso(offerT + rng.int(3, 18) * 1000),
              reason: status === "rejected" ? rng.pick(["too far", "low fare", "busy", null]) : null,
            });
            if (status === "accepted") driver = cand;
            offerT += status === "timed_out" ? 20000 : rng.int(3, 18) * 1000;
          }
        }
        t = Math.max(t + 1000, offerT);
        if (isActive && s === finalStatus) {
          // keep a pending offer for the live screen
          const cand = rng.pick(approvedDrivers.filter((d) => d.driver_profile.availability === "online"));
          offers.push({
            id: rng.uuid(),
            booking_id: id,
            driver_id: cand.id,
            driver_name: cand.full_name,
            fleet_code: cand.driver_profile.vehicle?.fleet_code ?? null,
            round: 1,
            radius_m: 2000,
            eta_seconds: 240,
            distance_m: 1200,
            status: "pending",
            offered_at: iso(now - 8000),
            expires_at: iso(now + 12000),
            responded_at: null,
            reason: null,
          });
        }
      } else if (s === "accepted") {
        if (!driver) driver = rng.pick(approvedDrivers);
        if (isActive && onTripIdx < onTripDrivers.length) driver = onTripDrivers[onTripIdx++]!;
        acceptedAt = t;
        push(prev, s, "driver");
        t += rng.int(20, 90) * 1000;
      } else if (s === "requested") {
        push(prev, s, "customer");
        t += rng.int(1, 3) * 1000;
      } else if (s === "driver_arriving") {
        push(prev, s, "driver");
        t += rng.int(120, 480) * 1000;
      } else if (s === "arrived" || s === "arrived_pickup") {
        push(prev, s, "driver");
        t += (waiting_seconds || rng.int(30, 150)) * 1000;
      } else if (s === "in_progress" || s === "collected") {
        startedAt = t;
        push(prev, s, "driver");
        t += duration_s * 1000 * rng.float(0.9, 1.3);
      } else if (s === "in_transit") {
        push(prev, s, "driver");
        t += duration_s * 1000 * rng.float(0.6, 0.9);
      } else if (s === "arrived_dropoff") {
        push(prev, s, "driver");
        t += rng.int(60, 240) * 1000;
      } else if (s === "recipient_verified") {
        push(prev, s, "driver", "OTP verified");
        t += rng.int(10, 40) * 1000;
      } else if (s === "completed" || s === "delivered") {
        completedAt = t;
        push(prev, s, "driver");
        t += rng.int(5, 120) * 1000;
      } else if (s === "paid") {
        push(prev, s, payment_method === "cash" ? "driver" : "system");
      }
      prev = s;
    }
    if (!isActive && cancelled) {
      const actor: TimelineEvent["actor_role"] =
        finalStatus === "cancelled_by_customer" ? "customer" : finalStatus === "cancelled_by_driver" ? "driver" : finalStatus === "expired" ? "system" : "admin";
      t += rng.int(15, 240) * 1000;
      push(prev, finalStatus, actor, finalStatus === "expired" ? "No driver accepted within 3 min" : rng.pick(["Changed my mind", "Driver too far", "Found another Bajaaj", "Wrong pickup location", "Customer unreachable"]));
      if (finalStatus === "cancelled_by_driver" || finalStatus === "cancelled_by_admin") driver = driver ?? rng.pick(approvedDrivers);
    }
    if (!isActive && finalStatus === "failed") {
      t += 120000;
      push(prev, "failed", "driver", "recipient_unreachable");
    }

    const driverCard = driver
      ? {
          id: driver.id,
          full_name: driver.full_name,
          phone: driver.phone,
          avatar_url: null,
          rating: driver.driver_profile.rating_avg,
          vehicle: driver.driver_profile.vehicle
            ? { fleet_code: driver.driver_profile.vehicle.fleet_code, plate: driver.driver_profile.vehicle.plate_number, colour: driver.driver_profile.vehicle.colour }
            : null,
        }
      : null;

    const done = finalStatus === "paid" || finalStatus === "completed" || finalStatus === "delivered";
    const tip = done && payment_method !== "cash" && rng.chance(0.12) ? rng.pick([25, 50, 100]) : 0;
    const final_fare_cents = done ? quote.fare_cents + (waiting_seconds > 180 ? Math.ceil((waiting_seconds - 180) / 60) * pv.waiting_fee_per_min_cents : 0) : null;
    const commission_pct = driver?.driver_profile.commission_pct ?? pv.commission_pct;
    const commission_cents = final_fare_cents != null ? Math.round((final_fare_cents * commission_pct) / 100) : null;
    const cancellation_fee_cents = finalStatus === "cancelled_by_customer" && pv.cancellation_fee_cents > 0 && rng.chance(0.4) ? pv.cancellation_fee_cents : 0;

    const booking: Booking = {
      id,
      reference,
      service,
      status: finalStatus,
      customer: { id: customer.id, full_name: customer.full_name, phone: customer.phone },
      driver: driverCard,
      vehicle: driver?.driver_profile.vehicle ?? null,
      pickup,
      dropoff,
      route: { distance_m, duration_s, polyline: roadLine(rng, pickup.location, dropoff.location) },
      quoted_fare_cents: quote.fare_cents,
      final_fare_cents,
      tip_cents: tip,
      discount_cents: discount,
      commission_pct,
      commission_cents,
      payment_method,
      payment_status: null,
      fare_breakdown: quote.breakdown,
      pricing_version: { id: pv.id, version: pv.version, name: pv.name },
      zone_key: garowe.key,
      delivery_category: category,
      delivery:
        service === "delivery"
          ? {
              category: category!,
              sender_name: customer.full_name,
              sender_phone: customer.phone ?? "",
              recipient_name: `Recipient ${rng.int(1, 999)}`,
              recipient_phone: `+25290${rng.int(1000000, 9999999)}`,
              package_description: rng.pick(["Food order", "Documents envelope", "Pharmacy bag", "Shopping bags ×2", "Small parcel", "Phone accessory"]),
              package_size: size!,
              package_weight_kg: +rng.float(0.3, 12).toFixed(1),
              package_photo_url: null,
              instructions: rng.chance(0.4) ? "Call on arrival, gate is blue." : null,
              proof_photo_url: done ? "/mock/docs/proof.svg" : null,
              recipient_otp_verified_at: done ? iso(completedAt! - 20000) : null,
            }
          : null,
      waiting_seconds,
      actual_distance_m: done ? Math.round(distance_m * rng.float(0.95, 1.1)) : null,
      cancellation_reason: cancelled ? (timeline[timeline.length - 1]?.reason ?? null) : null,
      cancellation_fee_cents,
      customer_rating: done && rng.chance(0.55) ? rng.weighted([[5, 65], [4, 25], [3, 7], [2, 2], [1, 1]]) : null,
      driver_rating: done && rng.chance(0.4) ? rng.weighted([[5, 80], [4, 15], [3, 5]]) : null,
      customer_comment: done && rng.chance(0.1) ? rng.pick(["Darawal fiican, mahadsanid.", "Fast and polite.", "Bajaaj was clean.", "Arrived late but ok."]) : null,
      driver_location: isActive && driver?.driver_profile.last_location ? driver.driver_profile.last_location : null,
      eta_s: isActive ? rng.int(60, 600) : null,
      timeline,
      offers,
      payments: [],
      ledger: [],
      share_url: `https://baj-go.com/t/${rng.hex(10)}`,
      created_at: iso(createdAt),
      completed_at: completedAt ? iso(completedAt) : null,
    };
    void acceptedAt;
    void startedAt;

    // ── payment + ledger
    if (done || cancellation_fee_cents > 0) {
      const amount = done ? final_fare_cents! + tip : cancellation_fee_cents;
      const payStatus: Payment["status"] =
        finalStatus === "paid" || cancellation_fee_cents > 0
          ? payment_method === "cash"
            ? "captured"
            : rng.weighted([["captured", 94], ["failed", 4], ["refunded", 2]])
          : "pending";
      const payment: Payment = {
        id: rng.uuid(),
        booking_id: id,
        booking_reference: reference,
        customer_id: customer.id,
        customer_name: customer.full_name,
        driver_id: driver?.id ?? null,
        driver_name: driver?.full_name ?? null,
        method: payment_method,
        provider: payment_method === "cash" ? "cash" : payment_method === "sandbox" ? "sandbox" : payment_method,
        provider_ref: payment_method === "cash" ? null : `${payment_method.toUpperCase()}-${rng.hex(8).toUpperCase()}`,
        status: payStatus,
        amount_cents: amount,
        currency: "USD",
        failure_reason: payStatus === "failed" ? "Insufficient balance" : null,
        reconciled_at: payment_method === "cash" && payStatus === "captured" && rng.chance(0.7) ? iso(t + 6 * HOUR) : null,
        created_at: iso(completedAt ?? t),
        updated_at: iso(t),
      };
      payments.push(payment);
      booking.payment_status = payment.status;
      booking.payments.push(payment);

      if (done && driver && final_fare_cents != null && (payStatus === "captured" || payStatus === "refunded")) {
        const at = completedAt ?? t;
        addTx(
          "fare",
          [
            { account: "customer", owner_id: customer.id, amount_cents: -final_fare_cents },
            { account: "driver", owner_id: driver.id, amount_cents: final_fare_cents },
          ],
          { booking_id: id, payment_id: payment.id, description: `Fare ${reference}`, at, booking_reference: reference },
        );
        addTx(
          "commission",
          [
            { account: "driver", owner_id: driver.id, amount_cents: -commission_cents! },
            { account: "platform_commission", owner_id: null, amount_cents: commission_cents! },
          ],
          { booking_id: id, description: `Commission ${commission_pct}% ${reference}`, at: at + 1, booking_reference: reference },
        );
        if (discount > 0) {
          addTx(
            "promo",
            [
              { account: "promotions", owner_id: null, amount_cents: -discount },
              { account: "customer", owner_id: customer.id, amount_cents: discount },
            ],
            { booking_id: id, description: `Promotion ${promo?.code} ${reference}`, at: at + 2, booking_reference: reference },
          );
          if (promo) {
            promo.uses_count++;
            redemptions.push({
              id: rng.uuid(),
              promotion_id: promo.id,
              user_id: customer.id,
              user_name: customer.full_name,
              booking_id: id,
              booking_reference: reference,
              discount_cents: discount,
              created_at: iso(createdAt),
            });
          }
        }
        if (tip > 0) {
          addTx(
            "tip",
            [
              { account: "customer", owner_id: customer.id, amount_cents: -tip },
              { account: "tips", owner_id: driver.id, amount_cents: tip },
            ],
            { booking_id: id, payment_id: payment.id, description: `Tip ${reference}`, at: at + 3, booking_reference: reference },
          );
        }
        if (payment_method === "cash") {
          addTx(
            "cash_collected",
            [
              { account: "driver", owner_id: driver.id, amount_cents: -final_fare_cents },
              { account: "platform_cash_clearing", owner_id: driver.id, amount_cents: final_fare_cents },
            ],
            { booking_id: id, payment_id: payment.id, description: `Cash collected by driver ${reference}`, at: at + 4, booking_reference: reference },
          );
        } else {
          const fee = Math.max(2, Math.round(final_fare_cents * 0.015));
          addTx(
            "provider_fee",
            [
              { account: "platform_commission", owner_id: null, amount_cents: -fee },
              { account: "provider_fees", owner_id: null, amount_cents: fee },
            ],
            { booking_id: id, payment_id: payment.id, description: `${payment.provider} fee ${reference}`, at: at + 5, booking_reference: reference },
          );
        }
        if (payStatus === "refunded") {
          const refund: Refund = {
            id: rng.uuid(),
            payment_id: payment.id,
            booking_id: id,
            booking_reference: reference,
            customer_name: customer.full_name,
            amount_cents: final_fare_cents,
            reason: rng.pick(["Driver took a longer route", "Charged twice", "Parcel damaged"]),
            status: "refunded",
            provider_ref: `RF-${rng.hex(6).toUpperCase()}`,
            requested_by: "admin-0005",
            approved_by: "admin-0002",
            created_at: iso(at + 2 * HOUR),
            processed_at: iso(at + 5 * HOUR),
          };
          refunds.push(refund);
          addTx(
            "refund",
            [
              { account: "refunds", owner_id: null, amount_cents: -final_fare_cents },
              { account: "customer", owner_id: customer.id, amount_cents: final_fare_cents },
            ],
            { booking_id: id, payment_id: payment.id, description: `Refund ${reference}`, at: at + 5 * HOUR, booking_reference: reference },
          );
        }
      }
    }
    return booking;
  };

  for (const t of bookingTimes) bookings.push(makeBooking(t));
  // currently active bookings (last ~25 minutes)
  for (let i = 0; i < 9; i++) bookings.push(makeBooking(now - rng.int(2, 25) * 60000, rng.pick(activeStatusesRide)));
  for (let i = 0; i < 6; i++) bookings.push(makeBooking(now - rng.int(2, 25) * 60000, rng.pick(activeStatusesDelivery)));
  for (let i = 0; i < 3; i++) bookings.push(makeBooking(now - rng.int(1, 3) * 60000, "searching"));
  bookings.sort((a, b) => (a.created_at < b.created_at ? 1 : -1));

  // attach ledger rows to bookings & pending refunds
  const ledgerByBooking = new Map<string, LedgerEntry[]>();
  const txById = new Map(ledgerTx.map((t) => [t.id, t]));
  for (const e of ledger) {
    const tx = txById.get(e.transaction_id)!;
    if (tx.booking_id) {
      if (!ledgerByBooking.has(tx.booking_id)) ledgerByBooking.set(tx.booking_id, []);
      ledgerByBooking.get(tx.booking_id)!.push(e);
    }
  }
  for (const b of bookings) b.ledger = ledgerByBooking.get(b.id) ?? [];
  for (const p of payments.filter((p) => p.status === "captured" && p.method !== "cash").slice(0, 5)) {
    refunds.push({
      id: rng.uuid(),
      payment_id: p.id,
      booking_id: p.booking_id,
      booking_reference: p.booking_reference,
      customer_name: p.customer_name,
      amount_cents: Math.round(p.amount_cents * rng.pick([0.5, 1])),
      reason: rng.pick(["Customer reports overcharge", "Trip ended early by driver", "Duplicate charge"]),
      status: "pending",
      provider_ref: null,
      requested_by: "admin-0005",
      approved_by: null,
      created_at: iso(now - rng.int(2, 70) * HOUR),
      processed_at: null,
    });
  }

  // customer aggregates
  for (const b of bookings) {
    const c = customers.find((x) => x.id === b.customer.id)!;
    if (b.status === "paid" || b.status === "completed" || b.status === "delivered") {
      if (b.service === "ride") c.total_rides++;
      else c.total_deliveries++;
      c.spend_cents += b.final_fare_cents ?? 0;
      if (b.status !== "paid") c.outstanding_cents += b.final_fare_cents ?? 0;
    }
    if (b.customer_rating) c.rating_count++;
  }
  // driver rating counts: keep seeded values

  // ── payouts
  const payouts: Payout[] = [];
  const walletOf = (driverId: string) => {
    const rows = ledger.filter((e) => e.owner_id === driverId && (e.account === "driver" || e.account === "tips"));
    return rows.reduce((s, e) => s + e.amount_cents, 0);
  };
  for (const d of rng.shuffle(approvedDrivers).slice(0, 38)) {
    const bal = walletOf(d.id);
    const status = rng.weighted<Payout["status"]>([["requested", 35], ["approved", 15], ["paid", 40], ["rejected", 7], ["failed", 3]]);
    const amount = Math.max(500, Math.round(Math.abs(bal) * rng.float(0.3, 0.9)));
    const requestedAt = now - rng.int(1, 20) * DAY;
    const payout: Payout = {
      id: rng.uuid(),
      driver_id: d.id,
      driver_name: d.full_name,
      fleet_code: d.driver_profile.vehicle?.fleet_code ?? null,
      amount_cents: amount,
      method: d.driver_profile.payout_method ?? "evc_plus",
      account: d.driver_profile.payout_account,
      status,
      provider_ref: status === "paid" ? `PO-${rng.hex(8).toUpperCase()}` : null,
      requested_at: iso(requestedAt),
      approved_by: status === "requested" ? null : "admin-0002",
      approved_at: status === "requested" ? null : iso(requestedAt + 4 * HOUR),
      paid_at: status === "paid" ? iso(requestedAt + 9 * HOUR) : null,
      note: status === "rejected" ? "Balance below requested amount." : null,
      wallet_balance_cents: bal,
    };
    payouts.push(payout);
    if (status === "paid") {
      addTx(
        "payout",
        [
          { account: "driver", owner_id: d.id, amount_cents: -amount },
          { account: "platform_cash_clearing", owner_id: d.id, amount_cents: amount },
        ],
        { payout_id: payout.id, description: `Payout to ${d.full_name}`, at: requestedAt + 9 * HOUR },
      );
      payout.wallet_balance_cents = walletOf(d.id);
    }
  }
  payouts.sort((a, b) => (a.requested_at < b.requested_at ? 1 : -1));

  // ── support tickets, incidents
  const admins: MockAdmin[] = [
    { id: "admin-0001", email: "admin@baj-go.com", full_name: "Admin 0001", roles: ["super_admin"], status: "active", totp_enabled: false, last_seen_at: iso(now - 120000), created_at: iso(start - 30 * DAY), password: "BajGo!2026", totp_secret: null },
    { id: "admin-0002", email: "finance@baj-go.com", full_name: "Admin 0002", roles: ["finance"], status: "active", totp_enabled: true, last_seen_at: iso(now - 3 * HOUR), created_at: iso(start - 28 * DAY), password: "BajGo!2026", totp_secret: "MOCK" },
    { id: "admin-0003", email: "verify@baj-go.com", full_name: "Admin 0003", roles: ["verification"], status: "active", totp_enabled: false, last_seen_at: iso(now - 40 * 60000), created_at: iso(start - 25 * DAY), password: "BajGo!2026", totp_secret: null },
    { id: "admin-0004", email: "ops@baj-go.com", full_name: "Admin 0004", roles: ["operations"], status: "active", totp_enabled: false, last_seen_at: iso(now - 5 * 60000), created_at: iso(start - 25 * DAY), password: "BajGo!2026", totp_secret: null },
    { id: "admin-0005", email: "support@baj-go.com", full_name: "Admin 0005", roles: ["support"], status: "active", totp_enabled: false, last_seen_at: iso(now - 15 * 60000), created_at: iso(start - 20 * DAY), password: "BajGo!2026", totp_secret: null },
    { id: "admin-0006", email: "marketing@baj-go.com", full_name: "Admin 0006", roles: ["marketing"], status: "active", totp_enabled: false, last_seen_at: iso(now - 2 * DAY), created_at: iso(start - 18 * DAY), password: "BajGo!2026", totp_secret: null },
    { id: "admin-0007", email: "auditor@baj-go.com", full_name: "Admin 0007", roles: ["auditor"], status: "active", totp_enabled: false, last_seen_at: iso(now - 6 * DAY), created_at: iso(start - 15 * DAY), password: "BajGo!2026", totp_secret: null },
    { id: "admin-0008", email: "former@baj-go.com", full_name: "Admin 0008", roles: ["operations"], status: "suspended", totp_enabled: false, last_seen_at: iso(start - 2 * DAY), created_at: iso(start - 30 * DAY), password: "BajGo!2026", totp_secret: null },
  ];
  admins.forEach((a) => nameOf.set(a.id, a.full_name));

  const tickets: Ticket[] = [];
  const ticketMessages: TicketMessage[] = [];
  const subjects: Record<Ticket["category"], string[]> = {
    ride: ["Driver took a longer route", "Darawalku wuu daahay", "Bajaaj was not the one shown in app"],
    delivery: ["Parcel delivered to wrong address", "Xirmadu way dhaawacantay", "Recipient OTP never arrived"],
    payment: ["Charged twice via EVC Plus", "Lacagta laba jeer ayaa la iga qaaday", "Cash fare different from quote"],
    lost_item: ["Left my phone in the Bajaaj", "Boorsadayda waan ku ilaaway Bajaajta"],
    incident: ["Unsafe driving on Jidka Boosaaso", "Shil yar ayaa dhacay"],
    account: ["Cannot log in — OTP not received", "Change my phone number"],
    driver: ["Customer refused to pay", "App crashes when going online"],
    other: ["Question about pricing", "Su'aal ku saabsan qiimaha"],
  };
  for (let i = 0; i < 64; i++) {
    const category = rng.weighted<Ticket["category"]>([["ride", 25], ["delivery", 18], ["payment", 18], ["lost_item", 8], ["incident", 6], ["account", 12], ["driver", 8], ["other", 5]]);
    const fromDriver = category === "driver";
    const user = fromDriver ? rng.pick(approvedDrivers) : rng.pick(customers);
    const booking = rng.chance(0.7) ? rng.pick(bookings.slice(0, 600)) : null;
    const createdAt = now - rng.int(1, 29) * DAY - rng.int(0, 23) * HOUR;
    const status = rng.weighted<Ticket["status"]>([["open", 25], ["in_progress", 20], ["waiting_customer", 12], ["resolved", 30], ["closed", 13]]);
    const assigned = status === "open" && rng.chance(0.5) ? null : rng.pick(["admin-0005", "admin-0004"]);
    const isIncident = category === "incident";
    const ticket: Ticket = {
      id: rng.uuid(),
      reference: `T${String(counters.ticketRef++).padStart(6, "0")}`,
      user_id: user.id,
      user_name: user.full_name,
      user_role: fromDriver ? "driver" : "customer",
      booking_id: booking?.id ?? null,
      booking_reference: booking?.reference ?? null,
      category,
      subject: rng.pick(subjects[category]),
      status,
      priority: isIncident ? 1 : rng.weighted<1 | 2 | 3 | 4>([[1, 5], [2, 45], [3, 35], [4, 15]]),
      assigned_to: assigned,
      assigned_name: assigned ? nameOf.get(assigned) ?? null : null,
      is_incident: isIncident,
      created_at: iso(createdAt),
      updated_at: iso(createdAt + rng.int(1, 48) * HOUR),
      resolved_at: status === "resolved" || status === "closed" ? iso(createdAt + rng.int(2, 72) * HOUR) : null,
    };
    tickets.push(ticket);
    ticketMessages.push({
      id: rng.uuid(),
      ticket_id: ticket.id,
      author_id: user.id,
      author_name: user.full_name,
      author_role: ticket.user_role,
      body: `${ticket.subject}. ${rng.pick(["Fadlan i caawi.", "Please help.", "Booking reference attached.", "Waxaan rabaa lacagtayda."])}`,
      internal: false,
      created_at: ticket.created_at,
    });
    if (status !== "open") {
      ticketMessages.push({
        id: rng.uuid(),
        ticket_id: ticket.id,
        author_id: assigned ?? "admin-0005",
        author_name: nameOf.get(assigned ?? "admin-0005")!,
        author_role: "admin",
        body: rng.pick(["Thanks, we are checking the trip log now.", "Mahadsanid, waan eegaynaa safarka.", "We have contacted the driver and will update you today."]),
        internal: false,
        created_at: iso(createdAt + 2 * HOUR),
      });
      if (rng.chance(0.5))
        ticketMessages.push({
          id: rng.uuid(),
          ticket_id: ticket.id,
          author_id: "admin-0004",
          author_name: "Admin 0004",
          author_role: "admin",
          body: rng.pick(["Driver confirms; approve a 50% refund.", "Trip GPS matches the quoted route — no refund.", "Escalate to ops if it repeats."]),
          internal: true,
          created_at: iso(createdAt + 3 * HOUR),
        });
    }
  }
  tickets.sort((a, b) => (a.created_at < b.created_at ? 1 : -1));

  const incidents: Incident[] = [];
  for (let i = 0; i < 14; i++) {
    const b = rng.pick(bookings.slice(0, 400));
    const kind = rng.weighted<Incident["kind"]>([["sos", 20], ["accident", 15], ["harassment", 10], ["lost_item", 25], ["dispute", 25], ["other", 5]]);
    const createdAt = now - rng.int(0, 25) * DAY - rng.int(0, 23) * HOUR;
    const status = i < 2 && kind === "sos" ? "open" : rng.weighted<Incident["status"]>([["open", 25], ["acknowledged", 25], ["resolved", 50]]);
    incidents.push({
      id: rng.uuid(),
      booking_id: b.id,
      booking_reference: b.reference,
      reporter_id: rng.chance(0.7) ? b.customer.id : (b.driver?.id ?? b.customer.id),
      reporter_name: rng.chance(0.7) ? b.customer.full_name : (b.driver?.full_name ?? b.customer.full_name),
      reporter_role: rng.chance(0.7) ? "customer" : "driver",
      kind,
      description: kind === "sos" ? "SOS pressed in app" : rng.pick(["Minor collision at junction, no injuries.", "Customer disputes the fare.", "Phone left on the seat.", null]),
      location: jitter(rng, b.pickup.location, 0.003),
      status,
      handled_by: status === "open" ? null : "admin-0004",
      created_at: iso(createdAt),
      resolved_at: status === "resolved" ? iso(createdAt + rng.int(1, 12) * HOUR) : null,
    });
  }
  // one live SOS right now
  const liveB = bookings.find((b) => b.status === "in_progress" || b.status === "in_transit");
  if (liveB)
    incidents.unshift({
      id: rng.uuid(),
      booking_id: liveB.id,
      booking_reference: liveB.reference,
      reporter_id: liveB.customer.id,
      reporter_name: liveB.customer.full_name,
      reporter_role: "customer",
      kind: "sos",
      description: "SOS pressed in app",
      location: liveB.driver_location ?? liveB.pickup.location,
      status: "open",
      handled_by: null,
      created_at: iso(now - 90000),
      resolved_at: null,
    });
  incidents.sort((a, b) => (a.created_at < b.created_at ? 1 : -1));

  // ── notifications + sms logs
  const notificationLog: NotificationLogEntry[] = [
    { id: rng.uuid(), audience: "customers", channel: "push", title_so: "BajGo waa yimid.", title_en: "BajGo is here.", body_so: "Garoowe, hal taabasho.", body_en: "Garowe, one tap away.", recipients: 412, delivered: 388, failed: 24, sent_by: "Admin 0006", sent_at: iso(start + 1 * DAY), status: "sent" },
    { id: rng.uuid(), audience: "drivers", channel: "push", title_so: "Qiimo cusub habeenkii", title_en: "New night pricing", body_so: "Laga bilaabo caawa 22:00, qiimaha habeenkii wuxuu kordhayaa 20%.", body_en: "From tonight 22:00, night fares are 20% higher.", recipients: 108, delivered: 104, failed: 4, sent_by: "Admin 0004", sent_at: iso(start + 12 * DAY), status: "sent" },
    { id: rng.uuid(), audience: "customers", channel: "sms", title_so: "Saddexda safar ee ugu horreeya", title_en: "First 3 rides", body_so: "Saddexda safar ee ugu horreeya: 20% dhimis, koodh BAJGO3.", body_en: "First 3 rides: 20% off with code BAJGO3.", recipients: 450, delivered: 441, failed: 9, sent_by: "Admin 0006", sent_at: iso(start + 6 * DAY), status: "sent" },
    { id: rng.uuid(), audience: "segment", channel: "in_app", title_so: "Mahadsanid", title_en: "Thank you", body_so: "Waad ku mahadsan tahay isticmaalka BajGo.", body_en: "Thanks for riding with BajGo this month.", recipients: 120, delivered: 120, failed: 0, sent_by: "Admin 0006", sent_at: iso(now - 2 * DAY), status: "sent" },
    { id: rng.uuid(), audience: "drivers", channel: "push", title_so: "Kulan darawallada", title_en: "Driver meeting", body_so: "Kulan Sabtida 10:00, xafiiska BajGo.", body_en: "Driver meeting Saturday 10:00 at the BajGo office.", recipients: 0, delivered: 0, failed: 0, sent_by: "Admin 0004", sent_at: iso(now + 2 * DAY), status: "scheduled" },
  ];
  const smsLog: SmsLogEntry[] = [];
  for (let i = 0; i < 180; i++) {
    const purpose = rng.weighted(["otp.login", "otp.recipient_delivery", "broadcast", "booking.accepted", "otp.account_recovery"].map((p, idx) => [p, [60, 18, 8, 10, 4][idx]!] as [string, number]));
    const status = rng.weighted<SmsLogEntry["status"]>([["delivered", 86], ["sent", 6], ["failed", 6], ["queued", 2]]);
    smsLog.push({
      id: counters.sms++,
      phone_e164: `+25290${rng.int(1000000, 9999999)}`,
      provider: rng.weighted([["http", 85], ["console", 15]]),
      purpose,
      status,
      provider_ref: status === "failed" ? null : `SM${rng.hex(10)}`,
      cost_cents: status === "failed" ? 0 : 2,
      error: status === "failed" ? rng.pick(["Number unreachable", "Gateway timeout", "Invalid number"]) : null,
      created_at: iso(now - rng.int(1, 29 * 24 * 60) * 60000),
    });
  }
  smsLog.sort((a, b) => (a.created_at < b.created_at ? 1 : -1));

  // ── CMS
  const cmsPages: CmsPage[] = [
    ["home", "Bogga hore", "Home"],
    ["about", "Ku saabsan BajGo", "About BajGo"],
    ["ride", "BajGo Ride", "BajGo Ride"],
    ["delivery", "BajGo Delivery", "BajGo Delivery"],
    ["how-it-works", "Sida uu u shaqeeyo", "How it works"],
    ["drivers", "Noqo darawal", "Become a driver"],
    ["download", "Soo deji app-ka", "Download the app"],
    ["coverage", "Meelaha aan ka shaqeyno", "Service coverage"],
    ["pricing", "Qiimaha", "Pricing"],
    ["safety", "Badbaado iyo kalsooni", "Safety & trust"],
    ["faq", "Su'aalaha badanaa la isweydiiyo", "FAQ"],
    ["contact", "Nala soo xiriir", "Contact & support"],
    ["privacy", "Siyaasadda asturnaanta", "Privacy policy"],
    ["terms", "Shuruudaha adeegga", "Terms of service"],
    ["delivery-terms", "Shuruudaha dirista", "Delivery terms"],
    ["driver-terms", "Shuruudaha darawalka", "Driver terms"],
    ["refunds", "Lacag-celin iyo joojin", "Refund & cancellation policy"],
  ].map(([slug, so, en]) => ({
    id: rng.uuid(),
    slug: slug!,
    title_so: so!,
    title_en: en!,
    blocks:
      slug === "home"
        ? [
            { id: rng.uuid(), type: "hero" as const, so: { title: "Fuul. Dir. BajGo.", subtitle: "Meel kasta, waqti kasta.", cta_label: "Soo deji app-ka", cta_url: "/download" }, en: { title: "Ride. Send. BajGo.", subtitle: "Garowe, one tap away.", cta_label: "Get the app", cta_url: "/download" } },
            { id: rng.uuid(), type: "service_cards" as const, so: { ride_title: "BajGo Ride", ride_text: "Ku dalbo Bajaaj meel kasta oo aad u socoto.", delivery_title: "BajGo Delivery", delivery_text: "Dir xirmooyin, cunto, dukumeenti iyo alaab." }, en: { ride_title: "BajGo Ride", ride_text: "Book a Bajaaj to take you anywhere.", delivery_title: "BajGo Delivery", delivery_text: "Send packages, food, documents and shopping." } },
            { id: rng.uuid(), type: "steps" as const, so: { title: "Sida uu u shaqeeyo", steps: ["Dooro meesha aad u socoto", "Arag qiimaha ka hor", "La soco darawalkaaga"] }, en: { title: "How it works", steps: ["Choose where to go", "See your fare before you go", "Track your driver live"] } },
            { id: rng.uuid(), type: "cta" as const, so: { title: "La shaqee BajGo.", body: "Safarro badan, dakhli caddaalad ah, Bajaajkaaga.", button: "Noqo darawal", url: "/drivers" }, en: { title: "Drive with BajGo.", body: "More trips. Fair pay. Your Bajaaj.", button: "Become a driver", url: "/drivers" } },
          ]
        : slug === "pricing"
          ? [{ id: rng.uuid(), type: "rich_text" as const, so: { html: "<p>Qiimaha ugu yar waa $1.00. $0.50 kiiloomitirkiiba.</p>" }, en: { html: "<p>Minimum fare $1.00. $0.50 per kilometre.</p>" } }]
          : [{ id: rng.uuid(), type: "rich_text" as const, so: { html: `<p>${so}</p>` }, en: { html: `<p>${en}</p>` } }],
    seo: { title_so: so, title_en: en, description_so: "", description_en: "" },
    published: true,
    updated_by: "Admin 0006",
    updated_at: iso(now - rng.int(1, 20) * DAY),
  }));
  const faqs: Faq[] = [
    { id: rng.uuid(), category: "general", question_so: "BajGo waa maxay?", answer_so: "BajGo waa app-ka Bajaajta ee Garoowe ee safarka iyo dirista alaabta.", question_en: "What is BajGo?", answer_en: "BajGo is Garowe's on-demand Bajaaj app for rides and deliveries.", sort_order: 1, published: true },
    { id: rng.uuid(), category: "pricing", question_so: "Qiimaha sidee loo xisaabiyaa?", answer_so: "Qiimaha waxaad arkaysaa ka hor intaadan dalban. Ugu yaraan $1.00.", question_en: "How is the fare calculated?", answer_en: "You see the fare before you book. Minimum fare is $1.00.", sort_order: 2, published: true },
    { id: rng.uuid(), category: "delivery", question_so: "Maxaan diri karaa?", answer_so: "Xirmooyin ilaa 30 kg. Daroogo, hub iyo xayawaan nool waa mamnuuc.", question_en: "What can I send?", answer_en: "Packages up to 30 kg. Illegal drugs, weapons and live animals are prohibited.", sort_order: 3, published: true },
    { id: rng.uuid(), category: "drivers", question_so: "Sidee darawal u noqon karaa?", answer_so: "Soo deji app-ka darawalka oo soo gudbi dukumeentiyadaada.", question_en: "How do I become a driver?", answer_en: "Download the driver app and submit your documents.", sort_order: 4, published: true },
    { id: rng.uuid(), category: "payment", question_so: "Sidee loo bixiyaa?", answer_so: "Lacag caddaan ah ama EVC Plus / ZAAD / Sahal.", question_en: "How do I pay?", answer_en: "Cash or EVC Plus / ZAAD / Sahal.", sort_order: 5, published: false },
  ];
  const banners: Banner[] = [
    { id: rng.uuid(), placement: "web_home_hero", title_so: "BajGo waa yimid.", title_en: "BajGo is here.", body_so: "Garoowe, hal taabasho.", body_en: "Garowe, one tap away.", image_url: null, link_url: "/download", starts_at: iso(start), ends_at: null, sort_order: 1, published: true },
    { id: rng.uuid(), placement: "app_home", title_so: "Saddexda safar ee ugu horreeya", title_en: "First 3 rides", body_so: "20% dhimis, koodh BAJGO3.", body_en: "20% off with code BAJGO3.", image_url: null, link_url: null, starts_at: iso(start), ends_at: iso(now + 40 * DAY), sort_order: 1, published: true },
    { id: rng.uuid(), placement: "app_promo", title_so: "U dir Garoowe oo dhan", title_en: "Send it across Garowe", body_so: "daqiiqado gudahood.", body_en: "in minutes.", image_url: null, link_url: null, starts_at: null, ends_at: null, sort_order: 2, published: false },
  ];
  const testimonials: Testimonial[] = [
    { id: rng.uuid(), author: "[Customer name]", role: "Customer, Waaberi", quote_so: "Darawalku si degdeg ah ayuu u yimid.", quote_en: "The driver arrived fast.", approved: false, created_at: iso(now - 3 * DAY) },
    { id: rng.uuid(), author: "[Driver name]", role: "Driver, BG-0012", quote_so: "Safarro badan maalin kasta.", quote_en: "More trips every day.", approved: true, created_at: iso(now - 9 * DAY) },
    { id: rng.uuid(), author: "[Customer name]", role: "Customer, Hodan", quote_so: null, quote_en: "Fair fare, no surprises.", approved: false, created_at: iso(now - 1 * DAY) },
  ];
  const contactMessages: ContactMessage[] = [];
  for (let i = 0; i < 18; i++) {
    contactMessages.push({
      id: rng.uuid(),
      name: `Visitor ${String(i + 1).padStart(3, "0")}`,
      phone: rng.chance(0.7) ? `+25290${rng.int(1000000, 9999999)}` : null,
      email: rng.chance(0.4) ? `visitor${i + 1}@example.com` : null,
      subject: rng.pick(["Partnership", "Darawal noqosho", "Delivery for my shop", "Complaint", "Press enquiry"]),
      body: rng.pick(["Waxaan rabaa inaan darawal noqdo, sidee?", "We run a restaurant in Israac and want delivery integration.", "I could not find the app on the Play Store.", "Is BajGo available in Boosaaso?"]),
      handled: rng.chance(0.5),
      created_at: iso(now - rng.int(1, 28) * DAY),
    });
  }
  contactMessages.sort((a, b) => (a.created_at < b.created_at ? 1 : -1));

  // ── roles
  const roleNames: Record<string, string> = {
    super_admin: "Super Administrator",
    operations: "Operations Manager",
    finance: "Finance Manager",
    verification: "Driver Verification Officer",
    support: "Customer Support Officer",
    marketing: "Marketing Manager",
    auditor: "Read-Only Auditor",
  };
  const roles: Role[] = Object.entries(PERMISSION_CATALOGUE).map(([key, perms]) => ({
    id: rng.uuid(),
    key,
    name: roleNames[key]!,
    permissions: [...perms],
    is_system: true,
    admins_count: admins.filter((a) => a.roles.includes(key)).length,
    created_at: iso(start - 30 * DAY),
  }));

  // ── audit logs
  const audit: AuditLog[] = [];
  const auditActions = [
    ["pricing.create", "pricing_version"],
    ["driver.approve", "driver"],
    ["driver.reject", "driver"],
    ["booking.cancel", "booking"],
    ["booking.assign", "booking"],
    ["booking.adjust_fare", "booking"],
    ["payout.approve", "payout"],
    ["payout.pay", "payout"],
    ["refund.approve", "refund"],
    ["settings.update", "settings"],
    ["zone.update", "zone"],
    ["cms.page.update", "cms_page"],
    ["promotion.create", "promotion"],
    ["dispatch.settings.update", "settings"],
    ["admin.login", "admin"],
  ] as const;
  for (let i = 0; i < 220; i++) {
    const [action, entity] = rng.pick(auditActions);
    const actor = rng.pick(admins.slice(0, 7));
    const b = rng.pick(bookings.slice(0, 500));
    const d = rng.pick(approvedDrivers);
    let before: Record<string, unknown> | null = null;
    let after: Record<string, unknown> | null = null;
    let entity_id = "";
    if (entity === "booking") {
      entity_id = b.id;
      if (action === "booking.cancel") {
        before = { status: "accepted", driver_id: d.id };
        after = { status: "cancelled_by_admin", reason: "Customer unreachable" };
      } else if (action === "booking.assign") {
        before = { status: "searching", driver_id: null };
        after = { status: "accepted", driver_id: d.id, note: "Manual assign from dispatch" };
      } else {
        before = { final_fare_cents: b.quoted_fare_cents };
        after = { final_fare_cents: b.quoted_fare_cents - 30, reason: "Driver took longer route" };
      }
    } else if (entity === "driver") {
      entity_id = d.id;
      before = { verification: "under_review", fleet_code: null };
      after = action === "driver.approve" ? { verification: "approved", fleet_code: d.driver_profile.vehicle?.fleet_code } : { verification: "rejected", reason: "Insurance expired" };
    } else if (entity === "pricing_version") {
      entity_id = pricing[1]!.id;
      before = { night_multiplier: 1, peak_multiplier: 1 };
      after = { night_multiplier: 1.2, peak_multiplier: 1.1, version: 2 };
    } else if (entity === "settings") {
      entity_id = action.startsWith("dispatch") ? "dispatch" : "features";
      before = action.startsWith("dispatch") ? { offer_timeout_s: 15 } : { tips: false };
      after = action.startsWith("dispatch") ? { offer_timeout_s: 20 } : { tips: true };
    } else if (entity === "payout") {
      const p = rng.pick(payouts);
      entity_id = p.id;
      before = { status: "requested" };
      after = { status: action === "payout.pay" ? "paid" : "approved", amount_cents: p.amount_cents };
    } else if (entity === "refund") {
      entity_id = refunds[0]?.id ?? "";
      before = { status: "pending" };
      after = { status: "refunded" };
    } else if (entity === "zone") {
      entity_id = garowe.id;
      before = { max_search_seconds: 120 };
      after = { max_search_seconds: 180 };
    } else if (entity === "cms_page") {
      entity_id = cmsPages[0]!.id;
      before = { published: false };
      after = { published: true };
    } else if (entity === "promotion") {
      entity_id = promotions[0]!.id;
      after = { code: "BAJGO3", value: 20 };
    } else {
      entity_id = actor.id;
      after = { method: "password", totp: actor.totp_enabled };
    }
    audit.push({
      id: counters.audit++,
      actor_id: actor.id,
      actor_name: actor.full_name,
      actor_role: actor.roles[0] ?? null,
      action,
      entity_type: entity,
      entity_id,
      before,
      after,
      ip: `41.78.${rng.int(0, 255)}.${rng.int(1, 254)}`,
      user_agent: rng.pick(["Chrome 130 / Windows", "Chrome 130 / Android", "Safari 18 / macOS", "Firefox 131 / Linux"]),
      created_at: iso(now - rng.int(1, 29 * 24 * 60) * 60000),
    });
  }
  audit.sort((a, b) => (a.created_at < b.created_at ? 1 : -1));
  audit.forEach((a, i) => (a.id = audit.length - i));

  // ── sessions
  const sessions: Session[] = [];
  admins.slice(0, 6).forEach((a, i) => {
    sessions.push({
      id: rng.uuid(),
      user_id: a.id,
      user_name: a.full_name,
      user_role: "admin",
      device: i === 0 ? "This browser" : rng.pick(["Office PC", "Laptop", "Android phone"]),
      platform: "web",
      ip: `41.78.${rng.int(0, 255)}.${rng.int(1, 254)}`,
      user_agent: rng.pick(["Chrome 130 / Windows", "Chrome 130 / Android", "Safari 18 / macOS"]),
      created_at: iso(now - rng.int(1, 20) * DAY),
      last_active_at: a.last_seen_at!,
      expires_at: iso(now + rng.int(5, 29) * DAY),
      current: i === 0,
    });
  });
  for (const d of approvedDrivers.slice(0, 25)) {
    sessions.push({
      id: rng.uuid(),
      user_id: d.id,
      user_name: d.full_name,
      user_role: "driver",
      device: rng.pick(["Tecno Spark 10", "Samsung A05", "Itel A60", "Infinix Smart 8"]),
      platform: "android",
      ip: `41.78.${rng.int(0, 255)}.${rng.int(1, 254)}`,
      user_agent: "BajGo Driver 1.0.0 (Android 13)",
      created_at: iso(now - rng.int(1, 25) * DAY),
      last_active_at: d.last_seen_at!,
      expires_at: iso(now + rng.int(5, 29) * DAY),
      current: false,
    });
  }
  for (const c of customers.slice(0, 25)) {
    sessions.push({
      id: rng.uuid(),
      user_id: c.id,
      user_name: c.full_name,
      user_role: "customer",
      device: rng.pick(["Tecno Spark 10", "Samsung A14", "iPhone 12", "Infinix Hot 30"]),
      platform: rng.chance(0.85) ? "android" : "ios",
      ip: `41.78.${rng.int(0, 255)}.${rng.int(1, 254)}`,
      user_agent: "BajGo 1.0.0",
      created_at: iso(now - rng.int(1, 25) * DAY),
      last_active_at: c.last_seen_at!,
      expires_at: iso(now + rng.int(5, 29) * DAY),
      current: false,
    });
  }

  return {
    seededAt: now,
    zones,
    vehicles,
    drivers,
    documents,
    customers,
    pricing,
    bookings,
    payments,
    ledgerTx,
    ledger,
    payouts,
    refunds,
    promotions,
    redemptions,
    tickets,
    ticketMessages,
    incidents,
    notificationLog,
    smsLog,
    smsSettings: {
      provider: "http",
      sender_id: "BajGo",
      otp_ttl_s: 300,
      otp_length: 6,
      resend_after_s: 45,
      max_sends_per_phone_per_hour: 5,
      test_numbers: ["+252901000001", "+252901000002", "+252901000003"],
      http_gateway_url: "https://sms.example-gateway.so/api/send",
    },
    dispatch: { mode: "sequential", offer_timeout_s: 20, radius_steps_m: [2000, 4000, 7000], max_search_s: 180, max_offers_per_round: 1, location_stale_s: 60 },
    commission: { default_pct: 15, by_category: { food: 12, pharmacy: 10 } },
    settings: {
      brand: { name: "BajGo", tagline_so: "Meel kasta, waqti kasta.", tagline_en: "Garowe, one tap away.", support_phone: "+252 [number]", support_email: "info@baj-go.com", website: "https://baj-go.com" },
      locale: { default_language: "so", languages: ["so", "en"], currency: "USD", timezone: "Africa/Mogadishu", country_code: "+252" },
      maps: { tiles: "osm", routing_provider: "osrm", geocoding_provider: "nominatim", center: GAROWE, default_zoom: 14 },
      features: { scheduled_bookings: false, tips: true, favourite_drivers: true, card_payments: false, wallet: false },
      delivery: { max_weight_kg: 30, recipient_otp: true },
    },
    appContent: {
      home_cards: {
        ride: { title: "BajGo Ride", so: "Ku dalbo Bajaaj meel kasta oo aad u socoto.", en: "Book a Bajaaj to take you anywhere." },
        delivery: { title: "BajGo Delivery", so: "Dir xirmooyin, cunto, dukumeenti iyo alaab.", en: "Send packages, food, documents and shopping." },
      },
      onboarding: [
        { so: "Garoowe, hal taabasho.", en: "Garowe, one tap away." },
        { so: "Qiimaha ka hor intaadan bixin.", en: "See your fare before you go." },
        { so: "La soco darawalkaaga si toos ah.", en: "Track your driver live." },
      ],
      promo_banners: [{ id: rng.uuid(), title_so: "Saddexda safar ee ugu horreeya: 20% dhimis, koodh BAJGO3.", title_en: "First 3 rides: 20% off with code BAJGO3.", link_url: null, active: true }],
      support_phone: "+252 [number]",
      support_whatsapp: null,
    },
    cmsPages,
    faqs,
    banners,
    testimonials,
    contactMessages,
    roles,
    admins,
    audit,
    sessions,
    counters,
  };
}

let _db: DbShape | null = null;
export function getDb(): DbShape {
  if (!_db) _db = buildDb();
  return _db;
}
export function resetDb(): DbShape {
  _db = buildDb();
  return _db;
}
