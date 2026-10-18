-- BajGo seed · migration 0002 — roles, settings, Garowe zone, default pricing.
-- Safe to re-run (idempotent on keys).

INSERT INTO roles (key, name, permissions, is_system) VALUES
 ('super_admin','Super Administrator', ARRAY['*'], true),
 ('operations','Operations Manager', ARRAY['overview.read','live.read','bookings.read','bookings.write','dispatch.read','dispatch.write','drivers.read','drivers.write','vehicles.read','vehicles.write','customers.read','zones.read','zones.write','support.read','support.write','notifications.write','reports.read'], true),
 ('finance','Finance Manager', ARRAY['overview.read','payments.read','payments.write','payouts.read','payouts.write','finance.read','refunds.read','refunds.write','commission.read','commission.write','pricing.read','reports.read','audit.read'], true),
 ('verification','Driver Verification Officer', ARRAY['drivers.read','drivers.verify','vehicles.read','vehicles.write','audit.read'], true),
 ('support','Customer Support Officer', ARRAY['customers.read','bookings.read','support.read','support.write','refunds.read','notifications.read'], true),
 ('marketing','Marketing Manager', ARRAY['promotions.read','promotions.write','cms.read','cms.write','app_content.read','app_content.write','notifications.write','reports.read'], true),
 ('auditor','Read-Only Auditor', ARRAY['overview.read','bookings.read','drivers.read','customers.read','payments.read','payouts.read','finance.read','pricing.read','audit.read','reports.read','settings.read'], true)
ON CONFLICT (key) DO UPDATE SET permissions = EXCLUDED.permissions, name = EXCLUDED.name;

INSERT INTO settings (key, value) VALUES
 ('brand', '{"name":"BajGo","tagline_so":"Meel kasta, waqti kasta.","tagline_en":"Garowe, one tap away.","support_phone":"+252 [number]","support_email":"info@baj-go.com","website":"https://baj-go.com"}'),
 ('locale', '{"default_language":"so","languages":["so","en"],"currency":"USD","timezone":"Africa/Mogadishu","country_code":"+252"}'),
 ('dispatch', '{"mode":"sequential","offer_timeout_s":20,"radius_steps_m":[2000,4000,7000],"max_search_s":180,"max_offers_per_round":1,"location_stale_s":60}'),
 ('commission', '{"default_pct":15,"by_category":{}}'),
 ('otp', '{"ttl_s":300,"resend_after_s":45,"max_sends_per_phone_per_hour":5,"max_sends_per_ip_per_hour":10,"max_verify_attempts":5,"length":6}'),
 ('delivery', '{"max_weight_kg":30,"sizes":{"small":{"max_kg":5},"medium":{"max_kg":15},"large":{"max_kg":30}},"prohibited_items_so":["Daroogo","Hub","Lacag caddaan ah oo badan","Xayawaan nool","Wax burbura oo aan la xidhin"],"prohibited_items_en":["Illegal drugs","Weapons","Large amounts of cash","Live animals","Unpackaged fragile items"],"recipient_otp":true}'),
 ('maps', '{"tiles":"osm","routing_provider":"osrm","geocoding_provider":"nominatim","center":{"lat":8.4064,"lng":48.4847},"default_zoom":14}'),
 ('features', '{"scheduled_bookings":false,"tips":true,"favourite_drivers":true,"card_payments":false,"wallet":false}'),
 ('location_privacy', '{"driver_history_retention_days":30,"customer_sees_driver_only_on_trip":true}'),
 ('app_content', '{"home_cards":{"ride":{"title":"BajGo Ride","so":"Ku dalbo Bajaaj meel kasta oo aad u socoto.","en":"Book a Bajaaj to take you anywhere."},"delivery":{"title":"BajGo Delivery","so":"Dir xirmooyin, cunto, dukumeenti iyo alaab.","en":"Send packages, food, documents and shopping."}},"onboarding":[{"so":"Garoowe, hal taabasho.","en":"Garowe, one tap away."},{"so":"Qiimaha ka hor intaadan bixin.","en":"See your fare before you go."},{"so":"La soco darawalkaaga si toos ah.","en":"Track your driver live."}]}')
ON CONFLICT (key) DO NOTHING;

-- Garowe service area: an initial polygon around the city centre (8.4064 N, 48.4847 E), ~6 × 6 km.
-- PLACEHOLDER BOUNDARY — refine from the admin dashboard (Zones) with local knowledge before launch.
INSERT INTO zones (key, name, kind, geom) VALUES (
 'garowe', 'Garowe', 'service_area',
 ST_Multi(ST_GeomFromText('POLYGON((48.455 8.435, 48.515 8.435, 48.515 8.375, 48.455 8.375, 48.455 8.435))', 4326))::geography
) ON CONFLICT (key) DO NOTHING;

-- Default pricing v1: $0.50/km, $1.00 minimum (both services), 15% commission, rounds up to 10 cents.
INSERT INTO pricing_versions (version, service, zone_id, name, rate_per_km_cents, minimum_fare_cents, base_fee_cents, commission_pct, note)
SELECT 1, 'ride', NULL, 'Launch pricing — Ride', 50, 100, 0, 15, '$1 per 2 km initial default'
WHERE NOT EXISTS (SELECT 1 FROM pricing_versions WHERE service='ride' AND zone_id IS NULL);
INSERT INTO pricing_versions (version, service, zone_id, name, rate_per_km_cents, minimum_fare_cents, base_fee_cents, commission_pct, note)
SELECT 1, 'delivery', NULL, 'Launch pricing — Delivery', 50, 100, 0, 15, '$1 per 2 km initial default'
WHERE NOT EXISTS (SELECT 1 FROM pricing_versions WHERE service='delivery' AND zone_id IS NULL);

-- CMS pages skeleton (content filled by the website build / editable in admin)
INSERT INTO cms_pages (slug, title_so, title_en, published) VALUES
 ('home','Bogga hore','Home',true),('about','Ku saabsan BajGo','About BajGo',true),('ride','BajGo Ride','BajGo Ride',true),
 ('delivery','BajGo Delivery','BajGo Delivery',true),('how-it-works','Sida uu u shaqeeyo','How it works',true),
 ('drivers','Noqo darawal','Become a driver',true),('download','Soo deji app-ka','Download the app',true),
 ('coverage','Meelaha aan ka shaqeyno','Service coverage',true),('pricing','Qiimaha','Pricing',true),
 ('safety','Badbaado iyo kalsooni','Safety & trust',true),('faq','Su''aalaha badanaa la isweydiiyo','FAQ',true),
 ('contact','Nala soo xiriir','Contact & support',true),('privacy','Siyaasadda asturnaanta','Privacy policy',true),
 ('terms','Shuruudaha adeegga','Terms of service',true),('delivery-terms','Shuruudaha dirista','Delivery terms',true),
 ('driver-terms','Shuruudaha darawalka','Driver terms',true),('refunds','Lacag-celin iyo joojin','Refund & cancellation policy',true)
ON CONFLICT (slug) DO NOTHING;
