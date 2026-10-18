/**
 * CMS content shapes. These mirror the `cms_pages`, `cms_faqs`, `cms_banners`
 * and `cms_testimonials` tables in services/api/drizzle/0001_init.sql and the
 * JSON returned by GET /content/* (docs/API.md). The same shapes are used by the
 * local seed files in ./content so the site runs with or without the API.
 *
 * Block convention (from the schema comment `[{type, so:{...}, en:{...}}]`):
 *   - language-neutral configuration lives at the block root (type, hrefs, keys, tone…)
 *   - all human-readable text lives under `so` and `en`, with identical keys
 *   - `resolveBlock(block, locale)` merges the chosen language into the root
 */

export type Locale = "so" | "en";

export type Href = string; // site-relative ("/ride") or absolute ("https://…")

// ───────────────────────────────── block definitions

export interface HeroText {
  eyebrow?: string;
  headline: string;
  sub?: string;
  primary_label?: string;
  secondary_label?: string;
  note?: string;
}
export interface HeroBlock {
  type: "hero";
  id?: string;
  variant?: "home" | "page" | "night" | "saffron";
  primary_href?: Href;
  secondary_href?: Href;
  so: HeroText;
  en: HeroText;
}

export interface ServiceCardText {
  title: string;
  body: string;
  cta?: string;
}
export interface ServiceCardsBlock {
  type: "service_cards";
  id?: string;
  cards: Array<{ key: "ride" | "delivery"; href: Href }>;
  so: { title?: string; cards: ServiceCardText[] };
  en: { title?: string; cards: ServiceCardText[] };
}

export interface StepText {
  title: string;
  body: string;
}
export interface StepsBlock {
  type: "steps";
  id?: string;
  /** optional icon keys, same order as steps */
  icons?: Array<"pin" | "fare" | "track" | "parcel" | "phone" | "check" | "shield" | "cash" | "id" | "bajaaj" | "star">;
  layout?: "row" | "list";
  tone?: "light" | "cloud" | "night";
  so: { title: string; intro?: string; steps: StepText[]; cta_label?: string };
  en: { title: string; intro?: string; steps: StepText[]; cta_label?: string };
  cta_href?: Href;
}

export interface FaqBlock {
  type: "faq";
  id?: string;
  /** limit to one category; omit for all */
  category?: string;
  /** maximum entries to show (teaser); omit for all */
  limit?: number;
  more_href?: Href;
  so: { title: string; intro?: string; more_label?: string };
  en: { title: string; intro?: string; more_label?: string };
}

export interface RichTextBlock {
  type: "rich_text";
  id?: string;
  tone?: "light" | "cloud" | "sand";
  width?: "prose" | "wide";
  /**
   * Body is "markdown-lite": paragraphs separated by a blank line, lines starting
   * with "## " become H2, "### " become H3, "- " become list items, "1. " ordered
   * items, and **bold** is supported. Nothing else — keeps the renderer tiny.
   */
  so: { title?: string; body: string };
  en: { title?: string; body: string };
}

export interface CtaBlock {
  type: "cta";
  id?: string;
  tone?: "blue" | "saffron" | "night" | "cloud";
  href: Href;
  secondary_href?: Href;
  /** shows a QR code + store badges beside the text */
  show_download?: boolean;
  so: { title: string; body?: string; label: string; secondary_label?: string };
  en: { title: string; body?: string; label: string; secondary_label?: string };
}

export interface BannerBlock {
  type: "banner";
  id?: string;
  tone: "info" | "warning" | "draft" | "success";
  so: { title?: string; body: string };
  en: { title?: string; body: string };
}

/**
 * A site-defined interactive section whose copy (title/body) is editable in the CMS
 * but whose behaviour lives in code. Keys are fixed; unknown keys render nothing.
 */
export type ComponentKey =
  | "fare_calculator"
  | "download"
  | "testimonials"
  | "pricing_tables"
  | "coverage_map"
  | "contact_form"
  | "contact_details"
  | "driver_apply_form"
  | "delivery_rules";
export interface ComponentBlock {
  type: "component";
  id?: string;
  key: ComponentKey;
  tone?: "light" | "cloud" | "night" | "sand";
  so: { title?: string; body?: string };
  en: { title?: string; body?: string };
}

export type CmsBlock = HeroBlock | ServiceCardsBlock | StepsBlock | FaqBlock | RichTextBlock | CtaBlock | BannerBlock | ComponentBlock;
export type BlockType = CmsBlock["type"];

// ───────────────────────────────── page row (cms_pages)

export interface CmsPage {
  slug: string;
  title_so: string;
  title_en: string;
  blocks: CmsBlock[];
  seo: {
    description_so?: string;
    description_en?: string;
    /** optional override for <title> */
    title_so?: string;
    title_en?: string;
    noindex?: boolean;
  };
  published: boolean;
  updated_at?: string;
}

// ───────────────────────────────── cms_faqs

export interface CmsFaq {
  id: string;
  category: string;
  question_so: string;
  answer_so: string;
  question_en: string;
  answer_en: string;
  sort_order: number;
  published: boolean;
}

// ───────────────────────────────── cms_banners

export interface CmsBanner {
  id: string;
  placement: "web_home_hero" | "web_global" | "app_home" | "app_promo" | string;
  title_so?: string | null;
  title_en?: string | null;
  body_so?: string | null;
  body_en?: string | null;
  image_url?: string | null;
  link_url?: string | null;
  starts_at?: string | null;
  ends_at?: string | null;
  sort_order: number;
  published: boolean;
}

// ───────────────────────────────── cms_testimonials

export interface CmsTestimonial {
  id: string;
  author: string;
  role?: string | null;
  quote_so?: string | null;
  quote_en?: string | null;
  approved: boolean;
  created_at?: string;
}

// ───────────────────────────────── settings used by the site (subset of `settings` table)

export interface SiteSettings {
  brand: {
    name: string;
    tagline_so: string;
    tagline_en: string;
    support_phone: string;
    support_email: string;
    website: string;
    address_so?: string;
    address_en?: string;
  };
  social: Array<{ network: string; handle: string; url?: string; placeholder: boolean }>;
  delivery: {
    max_weight_kg: number;
    sizes: Record<"small" | "medium" | "large", { max_kg: number; label_so: string; label_en: string; example_so: string; example_en: string }>;
    categories: Array<{ key: string; label_so: string; label_en: string }>;
    prohibited_items_so: string[];
    prohibited_items_en: string[];
    recipient_otp: boolean;
  };
  pricing: {
    currency: "USD";
    ride: PricingRates;
    delivery: PricingRates;
    example_distances_km: number[];
  };
}

export interface PricingRates {
  rate_per_km_cents: number;
  minimum_fare_cents: number;
  base_fee_cents: number;
  waiting_fee_per_min_cents: number;
  free_waiting_minutes: number;
  rounding_cents: number;
  version_name: string;
}

// ───────────────────────────────── zones (GET /geo/zones)

export interface ZoneFeatureProperties {
  key: string;
  name: string;
  kind: "service_area" | "surge" | "restricted";
  active: boolean;
  placeholder?: boolean;
}
export interface ZonesGeoJson {
  type: "FeatureCollection";
  features: Array<{
    type: "Feature";
    properties: ZoneFeatureProperties;
    geometry: { type: "Polygon" | "MultiPolygon"; coordinates: number[][][] | number[][][][] };
  }>;
}

// ───────────────────────────────── helpers

type Resolved<B> = B extends { so: infer T } ? Omit<B, "so" | "en"> & T : never;
export type ResolvedBlock<B extends CmsBlock = CmsBlock> = B extends CmsBlock ? Resolved<B> : never;

/** Merge the chosen language's text into the block root. */
export function resolveBlock<B extends CmsBlock>(block: B, locale: Locale): Resolved<B> {
  const { so, en, ...rest } = block as B & { so: unknown; en: unknown };
  const text = (locale === "so" ? so : en) ?? so ?? en;
  return { ...(rest as object), ...(text as object) } as Resolved<B>;
}

export function pick<T extends Record<string, unknown>>(row: T, field: string, locale: Locale): string {
  const primary = row[`${field}_${locale}`];
  const fallback = row[`${field}_${locale === "so" ? "en" : "so"}`];
  return (typeof primary === "string" && primary) || (typeof fallback === "string" ? fallback : "");
}
