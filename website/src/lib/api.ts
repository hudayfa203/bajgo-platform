/**
 * Thin fetch wrapper for the BajGo API (docs/API.md).
 * - never throws on network/HTTP failure: returns `{ ok: false }` so callers can fall back
 * - aborts after API_TIMEOUT_MS
 * - unwraps `{ data: … }` envelopes used by list endpoints
 */
import { API_TIMEOUT_MS, CMS_REVALIDATE_SECONDS, PUBLIC_API_URL, SERVER_API_URL } from "./config";

export type ApiResult<T> =
  | { ok: true; data: T; status: number }
  | { ok: false; status: number; error?: { code: string; message: string; details?: unknown } };

export interface ApiOptions {
  method?: "GET" | "POST" | "PATCH" | "DELETE";
  body?: unknown;
  lang?: "so" | "en";
  /** use the server-side base URL (proxy routes) */
  server?: boolean;
  /** Next.js cache: revalidate seconds, or false for no-store */
  revalidate?: number | false;
  idempotencyKey?: string;
  timeoutMs?: number;
}

export function apiBase(server = false): string {
  return server ? SERVER_API_URL : PUBLIC_API_URL;
}

export async function api<T>(path: string, opts: ApiOptions = {}): Promise<ApiResult<T>> {
  const base = apiBase(opts.server);
  if (!base) return { ok: false, status: 0, error: { code: "NO_API", message: "API URL not configured" } };

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), opts.timeoutMs ?? API_TIMEOUT_MS);

  const headers: Record<string, string> = { Accept: "application/json" };
  if (opts.lang) headers["Accept-Language"] = opts.lang;
  if (opts.body !== undefined) headers["Content-Type"] = "application/json";
  if (opts.idempotencyKey) headers["Idempotency-Key"] = opts.idempotencyKey;

  const init: RequestInit & { next?: { revalidate?: number | false } } = {
    method: opts.method ?? "GET",
    headers,
    body: opts.body === undefined ? undefined : JSON.stringify(opts.body),
    signal: controller.signal,
  };
  if (init.method === "GET") {
    if (opts.revalidate === false) init.cache = "no-store";
    else init.next = { revalidate: opts.revalidate ?? CMS_REVALIDATE_SECONDS };
  } else {
    init.cache = "no-store";
  }

  try {
    const res = await fetch(`${base}${path}`, init);
    const text = await res.text();
    let json: unknown = null;
    try {
      json = text ? JSON.parse(text) : null;
    } catch {
      json = null;
    }
    if (!res.ok) {
      const err = (json as { error?: { code: string; message: string; details?: unknown } } | null)?.error;
      return { ok: false, status: res.status, error: err ?? { code: `HTTP_${res.status}`, message: res.statusText } };
    }
    const data = (json && typeof json === "object" && "data" in (json as object) && !("type" in (json as object))
      ? (json as { data: T }).data
      : json) as T;
    return { ok: true, data, status: res.status };
  } catch (e) {
    const aborted = e instanceof Error && e.name === "AbortError";
    return { ok: false, status: 0, error: { code: aborted ? "TIMEOUT" : "NETWORK", message: aborted ? "Request timed out" : String(e) } };
  } finally {
    clearTimeout(timer);
  }
}
