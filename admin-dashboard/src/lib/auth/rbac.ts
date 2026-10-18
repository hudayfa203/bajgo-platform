/**
 * RBAC helper. Permissions are strings such as `bookings.read`, `pricing.write`.
 * `*` grants everything; `bookings.*` grants every action on bookings.
 * A `.write` (or `.verify`) permission implies `.read` on the same resource.
 */
export type Permission = string;

export function hasPermission(granted: readonly Permission[] | null | undefined, required: Permission | Permission[]): boolean {
  if (!granted || granted.length === 0) return false;
  const list = Array.isArray(required) ? required : [required];
  if (list.length === 0) return true;
  return list.every((req) => matches(granted, req));
}

/** True when ANY of the required permissions is granted. */
export function hasAnyPermission(granted: readonly Permission[] | null | undefined, required: Permission[]): boolean {
  if (!granted || granted.length === 0) return false;
  return required.some((req) => matches(granted, req));
}

function matches(granted: readonly Permission[], req: Permission): boolean {
  if (granted.includes("*") || granted.includes(req)) return true;
  const [resource, action] = req.split(".");
  if (!resource || !action) return false;
  if (granted.includes(`${resource}.*`)) return true;
  // write/verify imply read
  if (action === "read") {
    return granted.includes(`${resource}.write`) || granted.includes(`${resource}.verify`);
  }
  return false;
}

export function resourceOf(perm: Permission): string {
  return perm.split(".")[0] ?? perm;
}

/** All distinct resources mentioned in a permission list (for the matrix editor). */
export const ALL_RESOURCES = [
  "overview",
  "live",
  "customers",
  "drivers",
  "vehicles",
  "bookings",
  "dispatch",
  "pricing",
  "commission",
  "payments",
  "payouts",
  "finance",
  "refunds",
  "promotions",
  "notifications",
  "sms",
  "support",
  "zones",
  "cms",
  "app_content",
  "settings",
  "roles",
  "audit",
  "security",
  "reports",
] as const;

export const ACTIONS = ["read", "write", "verify"] as const;

export function togglePermission(list: Permission[], perm: Permission): Permission[] {
  return list.includes(perm) ? list.filter((p) => p !== perm) : [...list, perm];
}
