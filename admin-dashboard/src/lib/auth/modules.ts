/**
 * The 27 admin modules, grouped for the sidebar. `permission` is the read
 * permission that makes the module visible (hidden otherwise, never just disabled).
 */
export type ModuleDef = {
  key: string;
  href: string;
  /** i18n key in messages (nav.*) */
  label: string;
  icon: string;
  permission: string | string[];
};

export type ModuleGroup = { key: string; label: string; modules: ModuleDef[] };

export const MODULE_GROUPS: ModuleGroup[] = [
  {
    key: "operate",
    label: "nav.group.operate",
    modules: [
      { key: "overview", href: "/app", label: "nav.overview", icon: "LayoutDashboard", permission: "overview.read" },
      { key: "live", href: "/app/live", label: "nav.live", icon: "Radar", permission: "live.read" },
      { key: "customers", href: "/app/customers", label: "nav.customers", icon: "Users", permission: "customers.read" },
      { key: "drivers", href: "/app/drivers", label: "nav.drivers", icon: "UserRound", permission: "drivers.read" },
      { key: "verification", href: "/app/verification", label: "nav.verification", icon: "BadgeCheck", permission: ["drivers.verify", "drivers.write"] },
      { key: "vehicles", href: "/app/vehicles", label: "nav.vehicles", icon: "Truck", permission: "vehicles.read" },
      { key: "rides", href: "/app/rides", label: "nav.rides", icon: "Route", permission: "bookings.read" },
      { key: "deliveries", href: "/app/deliveries", label: "nav.deliveries", icon: "Package", permission: "bookings.read" },
      { key: "dispatch", href: "/app/dispatch", label: "nav.dispatch", icon: "Waypoints", permission: "dispatch.read" },
    ],
  },
  {
    key: "money",
    label: "nav.group.money",
    modules: [
      { key: "pricing", href: "/app/pricing", label: "nav.pricing", icon: "Calculator", permission: "pricing.read" },
      { key: "commission", href: "/app/commission", label: "nav.commission", icon: "Percent", permission: "commission.read" },
      { key: "payments", href: "/app/payments", label: "nav.payments", icon: "CreditCard", permission: "payments.read" },
      { key: "payouts", href: "/app/payouts", label: "nav.payouts", icon: "Banknote", permission: "payouts.read" },
      { key: "finance", href: "/app/finance", label: "nav.finance", icon: "BarChart3", permission: "finance.read" },
      { key: "refunds", href: "/app/refunds", label: "nav.refunds", icon: "Undo2", permission: "refunds.read" },
      { key: "promotions", href: "/app/promotions", label: "nav.promotions", icon: "Ticket", permission: "promotions.read" },
    ],
  },
  {
    key: "engage",
    label: "nav.group.engage",
    modules: [
      { key: "notifications", href: "/app/notifications", label: "nav.notifications", icon: "BellRing", permission: ["notifications.read", "notifications.write"] },
      { key: "sms", href: "/app/sms", label: "nav.sms", icon: "MessageSquareText", permission: "sms.read" },
      { key: "support", href: "/app/support", label: "nav.support", icon: "LifeBuoy", permission: "support.read" },
      { key: "zones", href: "/app/zones", label: "nav.zones", icon: "MapPinned", permission: "zones.read" },
      { key: "cms", href: "/app/cms", label: "nav.cms", icon: "Globe", permission: "cms.read" },
      { key: "app-content", href: "/app/app-content", label: "nav.app_content", icon: "Smartphone", permission: "app_content.read" },
    ],
  },
  {
    key: "system",
    label: "nav.group.system",
    modules: [
      { key: "settings", href: "/app/settings", label: "nav.settings", icon: "Settings2", permission: "settings.read" },
      { key: "roles", href: "/app/roles", label: "nav.roles", icon: "ShieldCheck", permission: "roles.read" },
      { key: "audit", href: "/app/audit", label: "nav.audit", icon: "ScrollText", permission: "audit.read" },
      { key: "security", href: "/app/security", label: "nav.security", icon: "Activity", permission: "security.read" },
      { key: "reports", href: "/app/reports", label: "nav.reports", icon: "FileBarChart", permission: "reports.read" },
    ],
  },
];

export const ALL_MODULES: ModuleDef[] = MODULE_GROUPS.flatMap((g) => g.modules);

/** Map a pathname under /app to the module that owns it. */
export function moduleForPath(pathname: string): ModuleDef | undefined {
  if (pathname === "/app" || pathname === "/app/") return ALL_MODULES[0];
  if (pathname.startsWith("/app/bookings/")) return ALL_MODULES.find((m) => m.key === "rides");
  return ALL_MODULES.filter((m) => m.href !== "/app")
    .sort((a, b) => b.href.length - a.href.length)
    .find((m) => pathname === m.href || pathname.startsWith(m.href + "/"));
}
