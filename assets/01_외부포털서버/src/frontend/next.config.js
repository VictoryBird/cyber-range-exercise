/** @type {import('next').NextConfig} */
const nextConfig = {
  // [취약점] VULN-01-05: RSC (React Server Components) enabled by default.
  // Next.js 15.0.3 App Router uses RSC/Flight protocol, which is exploitable
  // via CVE-2025-55182 (React2Shell).
  // 올바른 구현: upgrade to next@15.1.0+ which patches this vulnerability
  reactStrictMode: true,
};

module.exports = nextConfig;
