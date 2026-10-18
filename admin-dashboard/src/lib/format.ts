import { format as dfFormat, formatDistanceToNowStrict, isValid, parseISO } from "date-fns";
import { TZDate } from "@date-fns/tz";

export const TIMEZONE = "Africa/Mogadishu";

const usd = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "USD",
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

/** Integer cents → "$12.50". Negative values keep the sign: "-$3.00". */
export function money(cents: number | null | undefined, opts?: { signed?: boolean }): string {
  if (cents == null || Number.isNaN(cents)) return "—";
  const v = usd.format(cents / 100);
  if (opts?.signed && cents > 0) return `+${v}`;
  return v;
}

/** Compact money for KPI cards: $1.2k, $34.5k, $1.02m — still USD. */
export function moneyCompact(cents: number | null | undefined): string {
  if (cents == null) return "—";
  const d = cents / 100;
  const abs = Math.abs(d);
  if (abs >= 1_000_000) return `${d < 0 ? "-" : ""}$${(abs / 1_000_000).toFixed(2)}m`;
  if (abs >= 10_000) return `${d < 0 ? "-" : ""}$${(abs / 1_000).toFixed(1)}k`;
  return usd.format(d);
}

export function num(n: number | null | undefined, digits = 0): string {
  if (n == null || Number.isNaN(n)) return "—";
  return new Intl.NumberFormat("en-US", { maximumFractionDigits: digits, minimumFractionDigits: digits }).format(n);
}

export function pct(n: number | null | undefined, digits = 1): string {
  if (n == null || Number.isNaN(n)) return "—";
  return `${n.toFixed(digits)}%`;
}

export function km(meters: number | null | undefined): string {
  if (meters == null) return "—";
  return `${(meters / 1000).toFixed(1)} km`;
}

export function duration(seconds: number | null | undefined): string {
  if (seconds == null) return "—";
  const m = Math.round(seconds / 60);
  if (m < 60) return `${m} min`;
  const h = Math.floor(m / 60);
  return `${h} h ${m % 60} min`;
}

function toTz(iso: string | Date): TZDate | null {
  const d = typeof iso === "string" ? parseISO(iso) : iso;
  if (!isValid(d)) return null;
  return new TZDate(d, TIMEZONE);
}

/** 18 Oct 2026, 14:05 (Africa/Mogadishu, EAT) */
export function dateTime(iso: string | Date | null | undefined): string {
  if (!iso) return "—";
  const d = toTz(iso);
  return d ? dfFormat(d, "d MMM yyyy, HH:mm") : "—";
}
export function dateOnly(iso: string | Date | null | undefined): string {
  if (!iso) return "—";
  const d = toTz(iso);
  return d ? dfFormat(d, "d MMM yyyy") : "—";
}
export function timeOnly(iso: string | Date | null | undefined): string {
  if (!iso) return "—";
  const d = toTz(iso);
  return d ? dfFormat(d, "HH:mm:ss") : "—";
}
export function relative(iso: string | Date | null | undefined): string {
  if (!iso) return "—";
  const d = typeof iso === "string" ? parseISO(iso) : iso;
  if (!isValid(d)) return "—";
  return `${formatDistanceToNowStrict(d)} ago`;
}
export function toDateInputValue(iso: string | Date | null | undefined): string {
  if (!iso) return "";
  const d = toTz(iso);
  return d ? dfFormat(d, "yyyy-MM-dd'T'HH:mm") : "";
}

export function phone(p: string | null | undefined): string {
  if (!p) return "—";
  // +2529XXXXXXXX → +252 9X XXX XXXX
  const m = p.match(/^\+252(\d{2})(\d{3})(\d{4})$/);
  return m ? `+252 ${m[1]} ${m[2]} ${m[3]}` : p;
}

export function titleCase(s: string | null | undefined): string {
  if (!s) return "—";
  return s.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

export function statusLabel(s: string | null | undefined): string {
  if (!s) return "—";
  return s.replace(/_/g, " ").replace(/^\w/, (c) => c.toUpperCase());
}

export function initials(name: string | null | undefined): string {
  if (!name) return "?";
  return name
    .split(/\s+/)
    .slice(0, 2)
    .map((w) => w[0]?.toUpperCase() ?? "")
    .join("");
}

export function shortId(id: string | null | undefined): string {
  return id ? id.slice(0, 8) : "—";
}
