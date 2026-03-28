/** @type {import('next').NextConfig} */
const nextConfig = {
  // [취약점] VULN-01-05: RSC (React Server Components) enabled by default.
  // Next.js 15.0.3 App Router uses RSC/Flight protocol, which is exploitable
  // via CVE-2025-55182 (React2Shell).
  // 올바른 구현: upgrade to next@15.1.0+ which patches this vulnerability
  reactStrictMode: true,
  async rewrites() {
    return [
      {
        source: "/api/:path*",
        destination: "http://127.0.0.1:8000/api/:path*",
      },
      {
        source: "/docs",
        destination: "http://127.0.0.1:8000/docs",
      },
      {
        source: "/openapi.json",
        destination: "http://127.0.0.1:8000/openapi.json",
      },
    ];
  },
};

module.exports = nextConfig;
