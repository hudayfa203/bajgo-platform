import type { Config } from "tailwindcss";

/**
 * BajGo design tokens — source: docs/DESIGN_SYSTEM.md + packages/brand/BajGo_Colours.json
 * No gradients, no blur shadows. Cards: 1px mist border. Sheets: flat 0/8 Night 8% offset shadow.
 */
const config: Config = {
  content: ["./src/**/*.{ts,tsx}", "./content/**/*.json", "./messages/**/*.json"],
  darkMode: ["class", '[data-theme="dark"]'],
  theme: {
    extend: {
      colors: {
        blue: { DEFAULT: "#1E4AD6", dark: "#1638A8" },
        night: "#0A1230",
        saffron: "#FFC21A",
        sky: "#9DB8FF",
        cloud: "#F3F6FC",
        sand: "#FBF6EA",
        slate: "#4B556E",
        mist: "#D9DFEC",
        success: "#13A35A",
        danger: "#D93A3F",
        d: {
          bg: "#060B1C",
          surface: "#0F1833",
          surface2: "#17224A",
          blue: "#5C80FF",
          text: "#F3F6FC",
          text2: "#A9B4CF",
        },
      },
      fontFamily: {
        display: ["var(--font-display)", "Bricolage Grotesque", "system-ui", "sans-serif"],
        sans: ["var(--font-sans)", "Plus Jakarta Sans", "system-ui", "sans-serif"],
      },
      fontSize: {
        display: ["2rem", { lineHeight: "2.5rem", fontWeight: "700" }],
        h1: ["1.75rem", { lineHeight: "1.3", fontWeight: "700" }],
        h2: ["1.375rem", { lineHeight: "1.3", fontWeight: "700" }],
        h3: ["1.125rem", { lineHeight: "1.3", fontWeight: "600" }],
        body: ["1rem", { lineHeight: "1.45" }],
        label: ["0.8125rem", { lineHeight: "1.3", fontWeight: "600" }],
        caption: ["0.75rem", { lineHeight: "1.3" }],
      },
      borderRadius: {
        btn: "14px",
        card: "20px",
        sheet: "28px",
        input: "12px",
        chip: "999px",
      },
      boxShadow: {
        sheet: "0 8px 0 0 rgba(10, 18, 48, 0.08)",
        none: "none",
      },
      spacing: {
        gutter: "16px",
        "gutter-lg": "24px",
      },
      maxWidth: {
        site: "1200px",
        prose: "68ch",
      },
      transitionDuration: {
        micro: "120ms",
        sheet: "220ms",
        page: "400ms",
      },
      keyframes: {
        pulseRing: {
          "0%": { transform: "scale(1)", opacity: "0.6" },
          "100%": { transform: "scale(1.6)", opacity: "0" },
        },
      },
      animation: {
        pulseRing: "pulseRing 1.6s ease-out infinite",
      },
    },
  },
  plugins: [],
};

export default config;
