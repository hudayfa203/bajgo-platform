/** Typed view over the `settings` table (seeded in drizzle/0002_seed_core.sql). */
export interface SettingsMap {
  brand: { name: string; tagline_so: string; tagline_en: string; support_phone: string; support_email: string; website: string };
  locale: { default_language: 'so' | 'en'; languages: string[]; currency: string; timezone: string; country_code: string };
  dispatch: {
    mode: 'sequential' | 'broadcast';
    offer_timeout_s: number;
    radius_steps_m: number[];
    max_search_s: number;
    max_offers_per_round: number;
    location_stale_s: number;
  };
  commission: { default_pct: number; by_category: Record<string, number> };
  otp: {
    ttl_s: number;
    resend_after_s: number;
    max_sends_per_phone_per_hour: number;
    max_sends_per_ip_per_hour: number;
    max_verify_attempts: number;
    length: number;
  };
  delivery: {
    max_weight_kg: number;
    sizes: Record<string, { max_kg: number }>;
    prohibited_items_so: string[];
    prohibited_items_en: string[];
    recipient_otp: boolean;
  };
  maps: { tiles: string; routing_provider: string; geocoding_provider: string; center: { lat: number; lng: number }; default_zoom: number };
  features: { scheduled_bookings: boolean; tips: boolean; favourite_drivers: boolean; card_payments: boolean; wallet: boolean };
  location_privacy: { driver_history_retention_days: number; customer_sees_driver_only_on_trip: boolean };
  app_content: Record<string, unknown>;
  sms: { provider?: string; sender_id?: string; otp_ttl_s?: number; test_numbers?: string[] };
}
export type SettingKey = keyof SettingsMap;

export const SETTING_DEFAULTS: SettingsMap = {
  brand: { name: 'BajGo', tagline_so: 'Meel kasta, waqti kasta.', tagline_en: 'Garowe, one tap away.', support_phone: '+252 [number]', support_email: 'info@baj-go.com', website: 'https://baj-go.com' },
  locale: { default_language: 'so', languages: ['so', 'en'], currency: 'USD', timezone: 'Africa/Mogadishu', country_code: '+252' },
  dispatch: { mode: 'sequential', offer_timeout_s: 20, radius_steps_m: [2000, 4000, 7000], max_search_s: 180, max_offers_per_round: 1, location_stale_s: 60 },
  commission: { default_pct: 15, by_category: {} },
  otp: { ttl_s: 300, resend_after_s: 45, max_sends_per_phone_per_hour: 5, max_sends_per_ip_per_hour: 10, max_verify_attempts: 5, length: 6 },
  delivery: { max_weight_kg: 30, sizes: { small: { max_kg: 5 }, medium: { max_kg: 15 }, large: { max_kg: 30 } }, prohibited_items_so: [], prohibited_items_en: [], recipient_otp: true },
  maps: { tiles: 'osm', routing_provider: 'osrm', geocoding_provider: 'nominatim', center: { lat: 8.4064, lng: 48.4847 }, default_zoom: 14 },
  features: { scheduled_bookings: false, tips: true, favourite_drivers: true, card_payments: false, wallet: false },
  location_privacy: { driver_history_retention_days: 30, customer_sees_driver_only_on_trip: true },
  app_content: {},
  sms: {},
};
