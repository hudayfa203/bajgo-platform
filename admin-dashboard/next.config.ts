import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  output: "standalone",
  poweredByHeader: false,
  images: { unoptimized: true },
  experimental: { optimizePackageImports: ["lucide-react", "recharts", "date-fns"] },
};

export default nextConfig;
