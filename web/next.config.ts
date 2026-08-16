import type { NextConfig } from "next";

const contentSecurityPolicy = [
  "default-src 'self'",
  "base-uri 'self'",
  "form-action 'self'",
  "frame-ancestors 'none'",
  "object-src 'none'",
  "script-src 'self' 'unsafe-inline' https://challenges.cloudflare.com",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: blob: https://books.google.com https://books.googleusercontent.com https://*.googleusercontent.com",
  "font-src 'self' data:",
  "connect-src 'self' https://*.supabase.co wss://*.supabase.co https://www.googleapis.com https://challenges.cloudflare.com",
  "frame-src https://challenges.cloudflare.com",
  "manifest-src 'self'",
  process.env.NODE_ENV === "production" ? "upgrade-insecure-requests" : "",
].filter(Boolean).join("; ");

const securityHeaders = [
  { key: "Content-Security-Policy", value: contentSecurityPolicy },
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=(), payment=()" },
];

const nextConfig: NextConfig = {
  poweredByHeader: false,
  images: { remotePatterns: [{ protocol: "https", hostname: "books.google.com" }, { protocol: "https", hostname: "books.googleusercontent.com" }, { protocol: "https", hostname: "*.googleusercontent.com" }] },
  async headers() {
    return [
      { source: "/:path*", headers: securityHeaders },
      { source: "/app/:path*", headers: [{ key: "Cache-Control", value: "private, no-cache, no-store, must-revalidate, max-age=0" }] },
      { source: "/auth/:path*", headers: [{ key: "Cache-Control", value: "private, no-cache, no-store, must-revalidate, max-age=0" }] },
      { source: "/api/export", headers: [{ key: "Cache-Control", value: "private, no-cache, no-store, must-revalidate, max-age=0" }] },
    ];
  },
};

export default nextConfig;
