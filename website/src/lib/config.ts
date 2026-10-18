/** Runtime configuration — all values come from the environment (see .env.example). */

const trimSlash = (v: string) => v.replace(/\/+$/, "");

/** Public API base (browser + server). Empty string means "no API → local seed content". */
export const PUBLIC_API_URL = trimSlash(process.env.NEXT_PUBLIC_API_URL ?? "");

/** Server-only API base for proxy routes; defaults to the public one. */
export const SERVER_API_URL = trimSlash(process.env.API_URL ?? process.env.NEXT_PUBLIC_API_URL ?? "");

export const SITE_URL = trimSlash(process.env.NEXT_PUBLIC_SITE_URL ?? "https://baj-go.com");

export const APP_ENV = (process.env.APP_ENV ?? process.env.NODE_ENV ?? "development") as
  | "development"
  | "staging"
  | "production"
  | "test";

export const IS_PRODUCTION = APP_ENV === "production";

export const hasApi = () => PUBLIC_API_URL.length > 0;
export const hasServerApi = () => SERVER_API_URL.length > 0;

/** Seconds between CMS re-fetches when the API is configured (ISR). */
export const CMS_REVALIDATE_SECONDS = 300;

/** Fetch timeout — the site must stay fast on 2G/3G even when the API is slow. */
export const API_TIMEOUT_MS = 6000;
