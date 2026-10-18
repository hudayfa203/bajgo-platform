import type { FareBreakdown, PricingVersion, ServiceType } from "@/lib/api/types";
import { TZDate } from "@date-fns/tz";
import { TIMEZONE } from "@/lib/format";

/**
 * Mirrors the backend fare engine (docs/ARCHITECTURE.md §6) so the mock
 * `POST /admin/pricing/preview` returns realistic figures. The live client
 * never computes fares — it always asks the API.
 *
 * fare = max(minimum, base + distance_charge + waiting) × multiplier − discount, rounded UP to rounding_cents.
 */
export function computeFare(
  pv: Pick<
    PricingVersion,
    | "rate_per_km_cents"
    | "minimum_fare_cents"
    | "base_fee_cents"
    | "waiting_fee_per_min_cents"
    | "free_waiting_minutes"
    | "surge_multiplier"
    | "night_multiplier"
    | "night_start"
    | "night_end"
    | "peak_multiplier"
    | "peak_windows"
    | "distance_brackets"
    | "delivery_extras"
    | "rounding_cents"
  >,
  input: {
    service: ServiceType;
    distance_m: number;
    at: Date;
    waiting_seconds?: number;
    discount_cents?: number;
    delivery?: { category?: string; size?: string };
  },
): { fare_cents: number; breakdown: FareBreakdown } {
  const km = Math.round(input.distance_m / 100) / 10; // rounded to 0.1 km
  const distance = distanceCharge(km, pv.rate_per_km_cents, pv.distance_brackets);
  const waitMin = Math.max(0, Math.ceil((input.waiting_seconds ?? 0) / 60) - pv.free_waiting_minutes);
  const waiting = waitMin * pv.waiting_fee_per_min_cents;
  let delivery_extra = 0;
  if (input.service === "delivery" && input.delivery) {
    delivery_extra += pv.delivery_extras.category?.[input.delivery.category ?? ""] ?? 0;
    delivery_extra += pv.delivery_extras.size?.[input.delivery.size ?? ""] ?? 0;
  }
  const local = new TZDate(input.at, TIMEZONE);
  const night_applied = isNight(local, pv.night_start, pv.night_end);
  const peak_applied = isPeak(local, pv.peak_windows);
  let multiplier = Number(pv.surge_multiplier) || 1;
  if (night_applied) multiplier *= Number(pv.night_multiplier) || 1;
  if (peak_applied) multiplier *= Number(pv.peak_multiplier) || 1;

  const raw = pv.base_fee_cents + distance + waiting + delivery_extra;
  const minimum_applied = raw < pv.minimum_fare_cents;
  const subtotal = Math.max(pv.minimum_fare_cents, raw) * multiplier;
  const discount = Math.min(input.discount_cents ?? 0, subtotal);
  const rounding = Math.max(1, pv.rounding_cents);
  const fare_cents = Math.ceil((subtotal - discount) / rounding) * rounding;
  return {
    fare_cents,
    breakdown: {
      base: pv.base_fee_cents,
      distance,
      waiting,
      multiplier: Number(multiplier.toFixed(2)),
      discount,
      minimum_applied,
      night_applied,
      peak_applied,
      delivery_extra,
    },
  };
}

function distanceCharge(km: number, rate: number, brackets: PricingVersion["distance_brackets"]): number {
  if (!brackets || brackets.length === 0) return Math.round(km * rate);
  let total = 0;
  for (const b of brackets) {
    const from = b.from_km;
    const to = b.to_km ?? Infinity;
    if (km <= from) continue;
    const span = Math.min(km, to) - from;
    total += span * b.rate_cents;
  }
  return Math.round(total);
}

function minutesOf(hhmm: string): number {
  const [h, m] = hhmm.split(":").map(Number);
  return (h ?? 0) * 60 + (m ?? 0);
}

export function isNight(local: Date, start: string, end: string): boolean {
  const now = local.getHours() * 60 + local.getMinutes();
  const s = minutesOf(start);
  const e = minutesOf(end);
  if (s === e) return false;
  return s < e ? now >= s && now < e : now >= s || now < e;
}

export function isPeak(local: Date, windows: PricingVersion["peak_windows"]): boolean {
  if (!windows || windows.length === 0) return false;
  const day = local.getDay() === 0 ? 7 : local.getDay(); // 1=Mon … 7=Sun
  const now = local.getHours() * 60 + local.getMinutes();
  return windows.some((w) => w.days.includes(day) && now >= minutesOf(w.start) && now < minutesOf(w.end));
}
