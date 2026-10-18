import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: ["class", '[data-theme="dark"]'],
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        blue: { DEFAULT: "#1E4AD6", dark: "#1638A8", soft: "#5C80FF" },
        night: "#0A1230",
        saffron: "#FFC21A",
        sky: "#9DB8FF",
        cloud: "#F3F6FC",
        sand: "#FBF6EA",
        slate: "#4B556E",
        mist: "#D9DFEC",
        success: "#13A35A",
        danger: "#D93A3F",
        dbg: "#060B1C",
        dsurface: "#0F1833",
        dsurface2: "#17224A",
        dtext: "#F3F6FC",
        dtext2: "#A9B4CF",
        // semantic tokens driven by CSS variables (light/dark)
        bg: "rgb(var(--bg) / <alpha-value>)",
        surface: "rgb(var(--surface) / <alpha-value>)",
        surface2: "rgb(var(--surface2) / <alpha-value>)",
        fg: "rgb(var(--fg) / <alpha-value>)",
        fg2: "rgb(var(--fg2) / <alpha-value>)",
        line: "rgb(var(--line) / <alpha-value>)",
        link: "rgb(var(--link) / <alpha-value>)",
      },
      fontFamily: {
        display: ["var(--font-display)", "system-ui", "sans-serif"],
        sans: ["var(--font-body)", "system-ui", "sans-serif"],
      },
      borderRadius: { btn: "14px", card: "20px", sheet: "28px", input: "12px" },
      boxShadow: { sheet: "0 8px 0 0 rgba(10,18,48,0.08)", none: "none" },
      fontSize: {
        display: ["32px", { lineHeight: "40px" }],
        h1: ["28px", { lineHeight: "1.3" }],
        h2: ["22px", { lineHeight: "1.3" }],
        h3: ["18px", { lineHeight: "1.3" }],
        body: ["16px", { lineHeight: "1.45" }],
        label: ["13px", { lineHeight: "1.3", fontWeight: "600" }],
        caption: ["12px", { lineHeight: "1.3" }],
      },
      transitionDuration: { micro: "120ms", sheet: "220ms", page: "400ms" },
    },
  },
  plugins: [],
};
export default config;
