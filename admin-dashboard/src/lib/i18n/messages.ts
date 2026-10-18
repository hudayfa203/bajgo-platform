/**
 * Admin UI labels. English is the admin default; Somali strings marked NEW were
 * written for this dashboard and need native review (see README "Somali strings").
 * Approved lines from packages/brand/messaging.json are reused verbatim.
 */
export const en = {
  "nav.group.operate": "Operations",
  "nav.group.money": "Money",
  "nav.group.engage": "Engagement & content",
  "nav.group.system": "System",
  "nav.overview": "Executive overview",
  "nav.live": "Live operations",
  "nav.customers": "Customers",
  "nav.drivers": "Drivers",
  "nav.verification": "Driver verification",
  "nav.vehicles": "Bajaaj vehicles",
  "nav.rides": "Rides",
  "nav.deliveries": "Deliveries",
  "nav.dispatch": "Dispatch",
  "nav.pricing": "Pricing & fares",
  "nav.commission": "Commission",
  "nav.payments": "Payments",
  "nav.payouts": "Driver payouts",
  "nav.finance": "Financial reporting",
  "nav.refunds": "Refunds & disputes",
  "nav.promotions": "Promotions & coupons",
  "nav.notifications": "Push notifications",
  "nav.sms": "SMS & OTP",
  "nav.support": "Customer support",
  "nav.zones": "Service areas",
  "nav.cms": "Website content",
  "nav.app_content": "App content",
  "nav.settings": "Branding & settings",
  "nav.roles": "Roles & permissions",
  "nav.audit": "Audit logs",
  "nav.security": "Security & monitoring",
  "nav.reports": "Analytics & reports",
  "common.search": "Search",
  "common.search_placeholder": "Search customers, drivers, bookings…",
  "common.save": "Save",
  "common.cancel": "Cancel",
  "common.confirm": "Confirm",
  "common.delete": "Delete",
  "common.edit": "Edit",
  "common.create": "Create",
  "common.close": "Close",
  "common.back": "Back",
  "common.loading": "Loading…",
  "common.retry": "Retry",
  "common.reason": "Reason",
  "common.note": "Note",
  "common.actions": "Actions",
  "common.status": "Status",
  "common.all": "All",
  "common.from": "From",
  "common.to": "To",
  "common.export_csv": "Export CSV",
  "common.logout": "Sign out",
  "common.language": "Language",
  "common.theme": "Theme",
  "common.theme_light": "Light",
  "common.theme_dark": "Dark",
  "common.theme_system": "System",
  "common.no_results": "Nothing here yet",
  "common.no_results_hint": "Try a different filter or search term.",
  "common.error_title": "Something went wrong",
  "common.error_hint": "The request failed. Check your connection and try again.",
  "common.page": "Page",
  "common.of": "of",
  "common.rows": "rows",
  "common.privacy_note": "Driver positions are shown for operations only and are retained for 30 days.",
  "login.title": "Sign in to BajGo Admin",
  "login.subtitle": "Operations dashboard for Garowe",
  "login.email": "Email",
  "login.password": "Password",
  "login.totp": "Authenticator code (if enabled)",
  "login.submit": "Sign in",
  "login.failed": "Email or password is incorrect.",
  "service.ride": "Ride",
  "service.delivery": "Delivery",
  "topbar.environment": "Environment",
  "topbar.mock": "Mock data",
} as const;

export type MessageKey = keyof typeof en;

export const so: Record<MessageKey, string> = {
  "nav.group.operate": "Hawlgallada", // NEW
  "nav.group.money": "Lacagta", // NEW
  "nav.group.engage": "Xiriirka iyo macluumaadka", // NEW
  "nav.group.system": "Nidaamka", // NEW
  "nav.overview": "Guudmar", // NEW
  "nav.live": "Hawlgal toos ah", // NEW
  "nav.customers": "Macaamiisha", // NEW
  "nav.drivers": "Darawallada", // NEW
  "nav.verification": "Xaqiijinta darawallada", // NEW
  "nav.vehicles": "Bajaajta", // NEW
  "nav.rides": "Safarrada", // NEW
  "nav.deliveries": "Diritaanka", // NEW
  "nav.dispatch": "Qaybinta darawallada", // NEW
  "nav.pricing": "Qiimaha", // from messaging.json (cms page title)
  "nav.commission": "Komishanka", // NEW
  "nav.payments": "Lacag-bixinta", // NEW
  "nav.payouts": "Bixinta darawallada", // NEW
  "nav.finance": "Warbixinta maaliyadda", // NEW
  "nav.refunds": "Lacag-celin iyo khilaafaad", // NEW (based on messaging "Lacag-celin")
  "nav.promotions": "Dhimis iyo koodhadh", // NEW
  "nav.notifications": "Ogeysiisyada", // NEW
  "nav.sms": "SMS iyo OTP",
  "nav.support": "Taageerada macaamiisha", // NEW
  "nav.zones": "Meelaha adeegga", // NEW
  "nav.cms": "Macluumaadka website-ka", // NEW
  "nav.app_content": "Macluumaadka app-ka", // NEW
  "nav.settings": "Sumadda iyo dejinta", // NEW
  "nav.roles": "Doorarka iyo ogolaanshaha", // NEW
  "nav.audit": "Diiwaanka hawlaha", // NEW
  "nav.security": "Amniga iyo la-socodka", // NEW
  "nav.reports": "Falanqayn iyo warbixinno", // NEW
  "common.search": "Raadi", // NEW
  "common.search_placeholder": "Raadi macaamiil, darawal, dalab…", // NEW
  "common.save": "Kaydi", // NEW
  "common.cancel": "Jooji", // NEW
  "common.confirm": "Xaqiiji", // NEW
  "common.delete": "Tirtir", // NEW
  "common.edit": "Wax ka beddel", // NEW
  "common.create": "Abuur", // NEW
  "common.close": "Xir", // NEW
  "common.back": "Dib u noqo", // NEW
  "common.loading": "Waa la soo rarayaa…", // NEW
  "common.retry": "Isku day mar kale", // NEW
  "common.reason": "Sababta", // NEW
  "common.note": "Qoraal", // NEW
  "common.actions": "Ficillo", // NEW
  "common.status": "Xaaladda", // NEW
  "common.all": "Dhammaan", // NEW
  "common.from": "Laga bilaabo", // NEW
  "common.to": "Ilaa", // NEW
  "common.export_csv": "Soo saar CSV", // NEW
  "common.logout": "Ka bax", // NEW
  "common.language": "Luqadda", // NEW
  "common.theme": "Muuqaalka", // NEW
  "common.theme_light": "Iftiin", // NEW
  "common.theme_dark": "Mugdi", // NEW
  "common.theme_system": "Nidaamka", // NEW
  "common.no_results": "Weli waxba ma jiraan", // NEW
  "common.no_results_hint": "Isku day shaandhayn ama raadin kale.", // NEW
  "common.error_title": "Khalad ayaa dhacay", // NEW
  "common.error_hint": "Codsigu wuu fashilmay. Hubi xiriirkaaga oo isku day mar kale.", // NEW
  "common.page": "Bogga", // NEW
  "common.of": "ee", // NEW
  "common.rows": "saf", // NEW
  "common.privacy_note": "Goobaha darawallada waxaa loo muujiyaa hawlgal keliya; waxaa la hayaa 30 maalmood.", // NEW
  "login.title": "Gal BajGo Admin", // NEW
  "login.subtitle": "Dashboard-ka hawlgalka ee Garoowe", // NEW
  "login.email": "Iimayl", // NEW
  "login.password": "Furaha sirta", // NEW
  "login.totp": "Koodhka xaqiijinta (haddii la shido)", // NEW
  "login.submit": "Gal", // NEW
  "login.failed": "Iimaylka ama furaha sirta waa khalad.", // NEW
  "service.ride": "Safar", // messaging.json service_labels
  "service.delivery": "Dirid", // messaging.json service_labels
  "topbar.environment": "Deegaanka", // NEW
  "topbar.mock": "Xog tijaabo ah", // NEW
};

export const MESSAGES = { en, so };
