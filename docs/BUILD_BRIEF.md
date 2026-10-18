# BajGo build brief (read before writing code in any package)

You are building one surface of **BajGo**, a Bajaaj (three-wheel auto-rickshaw) ride & delivery platform launching in Garowe, Puntland, Somalia. The same drivers do rides and deliveries. Read in this order: `docs/ARCHITECTURE.md`, `docs/API.md` (the contract every surface follows — do not invent endpoints; if you need one, add it to API.md and say so in your report), `docs/DESIGN_SYSTEM.md`, `services/api/drizzle/0001_init.sql` (schema), `packages/brand/messaging.json` (approved copy).

## Non-negotiables
1. **Honesty.** Never claim something is tested, deployed or integrated if it isn't. Integrations that need external credentials (SMS, mobile money, FCM, Google/Mapbox) are built behind interfaces with a working dev/sandbox implementation and a clearly-named stub for the real provider. Your final report lists exactly what runs, what was verified (how), and what awaits credentials.
2. **Brand.** Use `packages/brand` assets and the design-system tokens. Spelling is always **BajGo**. Never retype the name where the logo belongs; use the SVG/PNG wordmark. Colours: Blue #1E4AD6 primary, Night #0A1230, Saffron #FFC21A accent. No gradients, no stock illustrations, no emoji in UI. Do not copy Uber/Bolt/Careem layouts — build the BajGo language from DESIGN_SYSTEM.md.
3. **Bilingual.** Somali (`so`) is the default language, English (`en`) second. Every user-facing string is localised; approved lines come from `messaging.json`. Where you must write new Somali, keep it short and plain and flag it in your report for native review. City: Somali *Garoowe*, English *Garowe*.
4. **Money** is integer cents in USD. Default fare: `max(100, round_up_10(distance_km × 50))` cents — never hard-code it in a client; always use the quote from the API.
5. **No invented facts.** No fake statistics, testimonials, driver counts or company numbers. Placeholders are explicit: `[number]`, `[X]`.
6. **Security.** No provider keys in mobile/web clients. All inputs validated. Test/demo accounts and reset endpoints exist only when `APP_ENV != production` (compile-time or env guard) and are clearly labelled.
7. **Low bandwidth.** Assume 2G/3G and affordable Android phones: small bundles, cached tiles, retry with backoff, explicit offline state, idempotent writes.
8. **Verification before reporting.** Run the project's own test suite / type-check / build (`npm test`, `npm run build`, `flutter analyze`, `flutter test`) and fix failures. Where a tool is unavailable in this environment (Flutter SDK, Android SDK, Packagist), say so plainly and describe exactly how it is verified elsewhere (CI workflow you wrote, commands to run).
9. **Reporting.** End with: what was built (file tree summary), what was verified and how, what is stubbed/awaiting credentials, new Somali strings, and anything you changed in the shared contract.

## Environment facts
- Network: npm registry and GitHub reachable. **Blocked**: pub.dev, Flutter/Android SDK downloads, Packagist. So Flutter apps are written and type-checked by reading only; their CI workflow (`.github/workflows/android-apks.yml`) must build them on GitHub Actions.
- Local services available for the backend: PostgreSQL 16 + PostGIS at `postgres://bajgo:bajgo@localhost:5432/bajgo` (migrations 0001/0002 already applied), Redis at `localhost:6379`.
- Node 22, npm 10. Two CPUs; keep builds lean.
