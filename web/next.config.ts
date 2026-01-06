import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export',
  basePath: '/x-connect',
  images: {
    unoptimized: true,
  },
  trailingSlash: true,
};

export default nextConfig;
