/**
 * Local fare estimate — mirrors the published launch rule from docs/BUILD_BRIEF.md §4:
 *   fare = max(minimum, round_up_10(distance_km × rate_per_km))   (integer cents)
 * The website never shows this as "the fare": it is labelled an estimate, and when
 * NEXT_PUBLIC_API_URL is set the fare calculator asks POST /quotes instead.
 */
import type { PricingRates } from "./cms-types";

export const DEFAULT_RATES: PricingRates = {
  rate_per_km_cents: 50,
  minimum_fare_cents: 100,
  base_fee_cents: 0,
  waiting_fee_per_min_cents: 0,
  free_waiting_minutes: 3,
  rounding_cents: 10,
  version_name: "Launch pricing v1",
};

export interface FareEstimate {
  fare_cents: number;
  distance_km: number;
  minimum_applied: boolean;
  breakdown: { base: number; distance: number; waiting: number; multiplier: number; discount: number; minimum_applied: boolean };
}

export function roundUpTo(cents: number, step: number): number {
  if (step <= 0) return Math.ceil(cents);
  return Math.ceil((cents - 1e-9) / step) * step;
}

/** Distance is rounded to 0.1 km first, as the API does (ARCHITECTURE.md §6). */
export function normaliseDistanceKm(km: number): number {
  if (!Number.isFinite(km) || km < 0) return 0;
  return Math.round(km * 10) / 10;
}

export function estimateFare(distanceKm: number, rates: PricingRates = DEFAULT_RATES): FareEstimate {
  const km = normaliseDistanceKm(distanceKm);
  const distanceCents = roundUpTo(km * rates.rate_per_km_cents, rates.rounding_cents);
  const raw = rates.base_fee_cents + distanceCents;
  const minimumApplied = raw < rates.minimum_fare_cents;
  const fare = Math.max(rates.minimum_fare_cents, raw);
  return {
    fare_cents: fare,
    distance_km: km,
    minimum_applied: minimumApplied,
    breakdown: {
      base: rates.base_fee_cents,
      distance: distanceCents,
      waiting: 0,
      multiplier: 1,
      discount: 0,
      minimum_applied: minimumApplied,
    },
  };
}

export function formatUsd(cents: number, locale: "so" | "en" = "en"): string {
  const value = cents / 100;
  // Both locales show "$1.50" — USD with a dot is what Garowe users see on receipts.
  void locale;
  return `$${value.toFixed(2)}`;
}
