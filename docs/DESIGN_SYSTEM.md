# BajGo Design System (apps, web, admin)

Source of truth for colours, type and components across Flutter, Next.js website and admin. Derived from the approved Option 03 identity (see `packages/brand/`).

## Colour tokens

| Token | Hex | Use |
|---|---|---|
| `blue` | #1E4AD6 | Primary: buttons, links, active tab, vehicle markers, customer app tile |
| `blueDark` | #1638A8 | Pressed / hover |
| `night` | #0A1230 | Headlines, dark surfaces, wordmark |
| `saffron` | #FFC21A | Accent: headlamp, highlights, pickup pin, driver app primary action |
| `sky` | #9DB8FF | Tints, routes on dark, chart secondary |
| `cloud` | #F3F6FC | Light background |
| `sand` | #FBF6EA | Warm background (onboarding, print) |
| `white` | #FFFFFF | Surfaces |
| `slate` | #4B556E | Secondary text |
| `mist` | #D9DFEC | Borders, dividers, disabled |
| `success` | #13A35A | Completed, online |
| `danger` | #D93A3F | Errors, SOS, cancel |
| Dark mode: `dBg` #060B1C · `dSurface` #0F1833 · `dSurface2` #17224A · `dBlue` #5C80FF (links/icons only — buttons stay `blue` with white text) · `dText` #F3F6FC · `dText2` #A9B4CF |

Contrast rules: body text ≥ 4.5:1. Never white on saffron. Saffron backgrounds take Night text. Driver app = dark (`dBg`) with Saffron primary actions and Night text on them; Customer app = light (`cloud`) with Blue primary actions.

## Typography

- Display / headlines: **Bricolage Grotesque** 600–800 (Flutter: `bricolage_grotesque` via google_fonts or bundled from `packages/brand/fonts-bricolage`; web: Google Fonts `Bricolage+Grotesque:opsz,wdth,wght@12..96,96,500..800`).
- UI / body: **Plus Jakarta Sans** 400–800.
- Scale: Display 32/40 · H1 28 · H2 22 · H3 18 · Body 16 · Label 13 (600) · Caption 12. Line height 1.3 (headings) / 1.45 (body). Headlines sentence case, never all-caps.
- Somali and English share size and weight. Allow wide text: Somali strings run ~20% longer.

## Spacing, radius, elevation

- 4-pt grid; screen side padding 16 (mobile) / 24 (web); card padding 16; section gap 24.
- Radius: button 14, card 20, sheet 28, chip 999, input 12.
- No gradients, no blur shadows. Cards use a 1 px `mist` border on light; on dark, `dSurface` on `dBg`. Elevated sheets use a flat 0/8 px Night 8% offset shadow.

## Core components (same names in Flutter and React)

- `BgButton` — primary (blue/white), secondary (outline night), saffron (driver primary, night text), danger, ghost. Height 52, min width 120, 16 px horizontal padding, Jakarta 700 16. Loading state replaces label with spinner. Touch target ≥ 48.
- `BgServiceCard` — the two home cards: icon tile (symbol or parcel), title (`BajGo Ride` / `BajGo Delivery`), one-line Somali/English description, chevron. 2-up on wide screens, stacked on narrow.
- `BgSheet` — bottom sheet with 36×4 grabber, 28 radius, snaps 30/60/90 %.
- `BgPlaceField` — pickup/drop-off rows with the saffron origin dot and blue destination square joined by a dotted line.
- `BgMap` — map wrapper: tiles from config, BajGo symbol as vehicle marker (small-size cut), saffron pickup pin, blue square drop-off pin, 4 px blue route line, "recentre" button bottom-right.
- `BgStatusPill` — booking status with dot: searching (saffron pulse), accepted/arriving (blue), in progress (blue), completed (success), cancelled (danger).
- `BgDriverCard` — avatar, name, rating star, fleet code `BG-0142` + plate, call/chat buttons.
- `BgOfferCard` (driver) — countdown ring (20 s), service badge, pickup/drop-off, distance, ETA, earnings, Accept (saffron) / Decline (ghost).
- `BgEarningsTile`, `BgKpiCard` (admin), `BgTimeline` (booking history), `BgEmptyState` (illustration from the symbol, one line SO + one line EN).
- Icons: 24 px grid, 2 px stroke, round caps (see guidelines §8). Flutter: custom `BgIcons` font generated from `packages/brand/icons/*.svg`; web: inline SVG components.

## Motion

- Durations: 120 ms micro (press), 220 ms sheet/transitions, 400 ms page. Curve: standard ease-out. Searching state: symbol pulses on a saffron ring; driver marker interpolates between location updates over 3 s. Respect reduced-motion.

## Language

- Somali first in the app selector; strings in `lib/l10n/app_so.arb` and `app_en.arb` (Flutter) and `messages/so.json` / `en.json` (Next.js). Keys are stable English identifiers (`home.where_to`).
- Approved copy lives in `packages/brand/messaging.json`; use it verbatim.

## Logo usage in product

- App bars: horizontal lockup, 28 px high, left-aligned. Splash: vertical lockup on Blue (customer) or Saffron (driver). Never retype "BajGo" as a logo; the wordmark is an asset. Clear space = half the symbol width.
