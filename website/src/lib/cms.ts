/**
 * Content access: API first (docs/API.md → GET /content/*, GET /geo/zones),
 * local seed JSON from ./content when the API is unset or unreachable.
 */
import "server-only";
import { api } from "./api";
import { hasApi } from "./config";
import { seedPages, seedFaqs, seedBanners, seedTestimonials, seedSettings, seedZones } from "@content/index";
import type { CmsBanner, CmsFaq, CmsPage, CmsTestimonial, Locale, SiteSettings, ZonesGeoJson } from "./cms-types";

export type ContentSource = "api" | "seed";

export interface WithSource<T> {
  data: T;
  source: ContentSource;
}

export async function getPage(slug: string, locale: Locale): Promise<WithSource<CmsPage | null>> {
  if (hasApi()) {
    const res = await api<CmsPage>(`/content/pages/${encodeURIComponent(slug)}?lang=${locale}`, { lang: locale });
    if (res.ok && res.data && Array.isArray(res.data.blocks)) {
      return { data: res.data.published === false ? null : res.data, source: "api" };
    }
    if (res.ok === false && res.status === 404) return { data: null, source: "api" };
  }
  const page = seedPages[slug];
  return { data: page && page.published ? page : null, source: "seed" };
}

export async function getFaqs(locale: Locale): Promise<WithSource<CmsFaq[]>> {
  if (hasApi()) {
    const res = await api<CmsFaq[]>(`/content/faqs?lang=${locale}`, { lang: locale });
    if (res.ok && Array.isArray(res.data)) return { data: sortFaqs(res.data), source: "api" };
  }
  return { data: sortFaqs(seedFaqs), source: "seed" };
}

function sortFaqs(list: CmsFaq[]): CmsFaq[] {
  return list.filter((f) => f.published !== false).sort((a, b) => a.sort_order - b.sort_order);
}

export async function getBanners(placement: string): Promise<WithSource<CmsBanner[]>> {
  const now = Date.now();
  const live = (b: CmsBanner) =>
    b.published !== false &&
    b.placement === placement &&
    (!b.starts_at || Date.parse(b.starts_at) <= now) &&
    (!b.ends_at || Date.parse(b.ends_at) >= now);
  if (hasApi()) {
    const res = await api<CmsBanner[]>(`/content/banners?placement=${encodeURIComponent(placement)}`);
    if (res.ok && Array.isArray(res.data)) return { data: res.data.filter(live).sort((a, b) => a.sort_order - b.sort_order), source: "api" };
  }
  return { data: seedBanners.filter(live).sort((a, b) => a.sort_order - b.sort_order), source: "seed" };
}

/** Only `approved` testimonials are ever rendered. */
export async function getTestimonials(): Promise<WithSource<CmsTestimonial[]>> {
  const approved = (t: CmsTestimonial) => t.approved === true && (t.quote_so || t.quote_en);
  if (hasApi()) {
    const res = await api<CmsTestimonial[]>(`/content/testimonials`);
    if (res.ok && Array.isArray(res.data)) return { data: res.data.filter(approved), source: "api" };
  }
  return { data: seedTestimonials.filter(approved), source: "seed" };
}

/**
 * Site settings (brand contact, delivery rules, pricing defaults). There is no public
 * settings endpoint in docs/API.md; the admin-facing one is `/admin/settings`. The
 * website therefore ships the subset it needs as seed content and re-exports it for
 * the CMS import. When a public endpoint is added, wire it here.
 */
export async function getSettings(): Promise<WithSource<SiteSettings>> {
  return { data: seedSettings, source: "seed" };
}

export async function getZones(): Promise<WithSource<ZonesGeoJson>> {
  if (hasApi()) {
    const res = await api<ZonesGeoJson>(`/geo/zones`);
    if (res.ok && res.data && res.data.type === "FeatureCollection") return { data: res.data, source: "api" };
  }
  return { data: seedZones, source: "seed" };
}

export function pageTitle(page: CmsPage, locale: Locale): string {
  return (locale === "so" ? page.seo?.title_so ?? page.title_so : page.seo?.title_en ?? page.title_en) || page.title_en;
}

export function pageDescription(page: CmsPage, locale: Locale): string | undefined {
  return locale === "so" ? page.seo?.description_so ?? page.seo?.description_en : page.seo?.description_en ?? page.seo?.description_so;
}
