"use client";

import Link from "next/link";

const SITEMAP_SECTIONS = [
  {
    title: "Main Pages",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
      />
    ),
    links: [
      { href: "/", label: "Home", desc: "Portal homepage" },
      { href: "/login", label: "Login", desc: "Staff authentication" },
      { href: "/search", label: "Search", desc: "Search the portal" },
    ],
  },
  {
    title: "Services",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
      />
    ),
    links: [
      { href: "/notices", label: "Notice Board", desc: "Official announcements and updates" },
      { href: "/inquiry", label: "Inquiry Status", desc: "Track your submitted inquiries" },
      { href: "/egovernment", label: "E-Government Services", desc: "Digital government services directory" },
    ],
  },
  {
    title: "Legal",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
      />
    ),
    links: [
      { href: "/terms", label: "Terms of Use", desc: "Website usage terms and conditions" },
      { href: "/privacy", label: "Privacy Policy", desc: "How we handle your personal data" },
      { href: "/accessibility", label: "Accessibility", desc: "Our commitment to accessibility" },
    ],
  },
  {
    title: "Contact",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
      />
    ),
    links: [
      {
        href: null,
        label: "Ministry of Interior and Safety",
        desc: "47 Constitution Avenue, Elaris, Republic of Valdoria",
      },
      {
        href: null,
        label: "Phone: +42 (0)2 3100-7000",
        desc: "Monday to Friday, 09:00 - 18:00",
      },
      {
        href: null,
        label: "Email: contact@mois.gov.vd",
        desc: "General inquiries and feedback",
      },
    ],
  },
];

export default function SitemapPage() {
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Breadcrumb */}
      <nav className="flex items-center gap-2 text-sm mb-6" aria-label="Breadcrumb">
        <Link href="/" className="breadcrumb-link">
          Home
        </Link>
        <svg className="w-3.5 h-3.5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
        </svg>
        <span className="text-gray-600 font-medium">Sitemap</span>
      </nav>

      {/* Page header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Sitemap</h1>
        <p className="text-gray-500">
          A complete overview of all pages and resources available on this portal.
        </p>
      </div>

      {/* Sitemap grid */}
      <div className="grid gap-6 sm:grid-cols-2">
        {SITEMAP_SECTIONS.map((section) => (
          <div key={section.title} className="govt-card">
            <div className="flex items-center gap-3 mb-5">
              <div className="w-10 h-10 rounded-lg bg-valdoria-navy/5 flex items-center justify-center text-valdoria-navy">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  {section.icon}
                </svg>
              </div>
              <h2 className="text-lg font-semibold text-valdoria-navy">
                {section.title}
              </h2>
            </div>
            <ul className="space-y-3">
              {section.links.map((link) => {
                const content = (
                  <div>
                    <div className="text-sm font-medium text-gray-800 group-hover:text-valdoria-navy transition-colors">
                      {link.label}
                    </div>
                    <div className="text-xs text-gray-500">{link.desc}</div>
                  </div>
                );
                return link.href ? (
                  <li key={link.label}>
                    <Link
                      href={link.href}
                      className="flex items-center gap-3 p-3 rounded-lg hover:bg-valdoria-cream transition-colors group"
                    >
                      <svg
                        className="w-4 h-4 text-valdoria-gold flex-shrink-0"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={2}
                          d="M9 5l7 7-7 7"
                        />
                      </svg>
                      {content}
                    </Link>
                  </li>
                ) : (
                  <li
                    key={link.label}
                    className="flex items-center gap-3 p-3 rounded-lg"
                  >
                    <svg
                      className="w-4 h-4 text-gray-400 flex-shrink-0"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={2}
                        d="M5 13l4 4L19 7"
                      />
                    </svg>
                    {content}
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </div>
    </div>
  );
}
