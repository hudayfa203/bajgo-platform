import { defineRouting } from "next-intl/routing";

export const locales = ["so", "en"] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = "so";

export const routing = defineRouting({
  locales,
  defaultLocale,
  // Somali is the default but we still prefix it (/so, /en) so every URL is explicit
  // and hreflang/sitemap entries are unambiguous.
  localePrefix: "always",
  localeDetection: true,
});

export function isLocale(value: string): value is Locale {
  return (locales as readonly string[]).includes(value);
}
