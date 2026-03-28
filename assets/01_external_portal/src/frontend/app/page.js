"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { fetchNotices } from "../lib/api";

const CATEGORY_BADGE = {
  policy: "govt-badge-policy",
  security: "govt-badge-security",
  service: "govt-badge-service",
  system: "govt-badge-system",
  recruitment: "govt-badge-recruitment",
};

function formatDate(dateStr) {
  if (!dateStr) return "";
  const d = new Date(dateStr);
  return d.toLocaleDateString("en-GB", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

function NoticeSkeleton() {
  return (
    <div className="govt-card">
      <div className="skeleton h-4 w-16 mb-3" />
      <div className="skeleton h-5 w-4/5 mb-2" />
      <div className="skeleton h-4 w-1/3" />
    </div>
  );
}

const STATIC_NEWS = [
  {
    id: 1,
    date: "Mar 25, 2026",
    title: "Minister Koren Announces National Cybersecurity Framework 2026",
    excerpt:
      "The Ministry of Interior and Safety unveiled a comprehensive cybersecurity strategy to protect critical national infrastructure and digital public services.",
  },
  {
    id: 2,
    date: "Mar 20, 2026",
    title: "Valdoria Ranks 4th in Global E-Government Index",
    excerpt:
      "The Republic of Valdoria has achieved a top-five ranking in the UN E-Government Development Index, reflecting continued investment in digital governance.",
  },
  {
    id: 3,
    date: "Mar 18, 2026",
    title: "Southern Coast Typhoon Preparedness Exercise Completed",
    excerpt:
      "Joint emergency response drills covering evacuation routes, shelter coordination, and inter-agency communication were successfully concluded.",
  },
];

const QUICK_LINKS = [
  {
    href: "/notices",
    label: "Notice Board",
    desc: "Official announcements and public notices",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
      />
    ),
  },
  {
    href: "/services",
    label: "Civil Services",
    desc: "Apply for government services and documents",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
      />
    ),
  },
  {
    href: "/policy",
    label: "Policy & Legislation",
    desc: "Browse acts, regulations, and policy papers",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3"
      />
    ),
  },
  {
    href: "/safety",
    label: "Public Safety",
    desc: "Emergency alerts, safety guidelines, and advisories",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
      />
    ),
  },
  {
    href: "/open-data",
    label: "Open Data",
    desc: "Access government datasets and statistics",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4"
      />
    ),
  },
  {
    href: "/participate",
    label: "Citizen Participation",
    desc: "Submit feedback, petitions, and public comments",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
      />
    ),
  },
];

const POLICY_HIGHLIGHTS = [
  {
    category: "Digital Governance",
    badgeClass: "govt-badge-policy",
    title: "Digital Governance Act 2026",
    desc: "Modernizing public services through technology and interoperable government systems.",
  },
  {
    category: "Public Safety",
    badgeClass: "govt-badge-security",
    title: "National Safety Plan",
    desc: "Comprehensive disaster preparedness framework covering all regions of Valdoria.",
  },
  {
    category: "Open Government",
    badgeClass: "govt-badge-service",
    title: "Open Data Initiative",
    desc: "Making government data accessible to all citizens and researchers.",
  },
];

const STATS = [
  { value: "24/7", label: "Service Availability" },
  { value: "15+", label: "Departments" },
  { value: "8.2M", label: "Citizens" },
  { value: "87%", label: "Digital Adoption" },
];

export default function HomePage() {
  const [notices, setNotices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [alertDismissed, setAlertDismissed] = useState(false);

  useEffect(() => {
    fetchNotices({ page: 1, size: 3 })
      .then((data) => {
        setNotices(data.items || []);
      })
      .catch((err) => {
        setError("Unable to load recent notices.");
        console.error(err);
      })
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      {/* Section 1: Emergency Alert Banner */}
      {!alertDismissed && (
        <div className="bg-amber-500 text-amber-950">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex items-center justify-between py-2.5 gap-4">
              <div className="flex items-center gap-3 min-w-0">
                <svg
                  className="w-5 h-5 flex-shrink-0"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                  />
                </svg>
                <span className="text-sm font-medium">
                  <span className="font-bold">ALERT:</span> Typhoon Miran
                  advisory in effect for Valdoria Southern Coast —{" "}
                  <Link
                    href="/safety"
                    className="underline underline-offset-2 hover:text-amber-800 transition-colors"
                  >
                    Check Safety Guidelines
                  </Link>
                </span>
              </div>
              <button
                onClick={() => setAlertDismissed(true)}
                className="flex-shrink-0 p-1 rounded hover:bg-amber-400/50 transition-colors"
                aria-label="Dismiss alert"
              >
                <svg
                  className="w-4 h-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Section 2: Hero Banner */}
      <section className="relative bg-valdoria-navy overflow-hidden">
        {/* Decorative background pattern */}
        <div className="absolute inset-0 opacity-[0.04]">
          <div
            className="absolute inset-0"
            style={{
              backgroundImage: `repeating-linear-gradient(
                45deg,
                transparent,
                transparent 40px,
                currentColor 40px,
                currentColor 41px
              )`,
            }}
          />
        </div>

        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 lg:py-24">
          <div className="max-w-3xl">
            {/* Government seal */}
            <div className="flex items-center gap-3 mb-6">
              <div className="w-16 h-16 rounded-full border-2 border-valdoria-gold/60 flex items-center justify-center bg-valdoria-navy-dark govt-seal">
                <div className="text-center">
                  <div className="text-valdoria-gold text-2xl font-bold leading-none">
                    V
                  </div>
                  <div className="text-valdoria-gold/60 text-[6px] tracking-widest uppercase mt-0.5">
                    MOIS
                  </div>
                </div>
              </div>
              <div className="h-10 w-px bg-valdoria-gold/30" />
              <div className="text-valdoria-gold-light text-xs tracking-widest uppercase">
                Official Government Portal
              </div>
            </div>

            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-bold text-white leading-tight mb-4">
              Ministry of Interior
              <br />
              <span className="text-valdoria-gold">and Safety</span>
            </h1>
            <p className="text-lg text-gray-300 mb-8 max-w-2xl leading-relaxed">
              Serving the citizens of the Republic of Valdoria with transparent
              governance, public safety, and accessible digital government
              services.
            </p>
            <div className="flex flex-wrap gap-3">
              <Link
                href="/notices"
                className="govt-btn-primary !bg-valdoria-gold !text-valdoria-navy-dark hover:!bg-valdoria-gold-light"
              >
                View Notices
              </Link>
              <Link
                href="/services"
                className="govt-btn-primary !bg-white !text-valdoria-navy-dark hover:!bg-gray-200"
              >
                Civil Services
              </Link>
            </div>
          </div>
        </div>

        {/* Bottom gold accent */}
        <div className="h-1 bg-gradient-to-r from-valdoria-gold via-valdoria-gold-light to-valdoria-gold" />
      </section>

      {/* Section 3: Quick Links Grid (6 items) */}
      <section className="bg-valdoria-cream border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
            {QUICK_LINKS.map((item) => (
              <Link
                key={item.label}
                href={item.href}
                className="flex flex-col items-center text-center gap-3 p-4 bg-white rounded-lg border border-gray-200
                           hover:border-valdoria-navy/20 hover:shadow-md transition-all duration-200 group"
              >
                <div
                  className="flex-shrink-0 w-11 h-11 rounded-lg bg-valdoria-navy/5 flex items-center justify-center
                                group-hover:bg-valdoria-navy group-hover:text-white text-valdoria-navy transition-colors duration-200"
                >
                  <svg
                    className="w-5 h-5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    {item.icon}
                  </svg>
                </div>
                <div>
                  <div className="text-sm font-semibold text-gray-800 group-hover:text-valdoria-navy transition-colors leading-snug">
                    {item.label}
                  </div>
                  <div className="text-xs text-gray-500 mt-1 leading-snug hidden md:block">
                    {item.desc}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Section 4: News + Notices (2-column layout) */}
      <section className="bg-white border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-10">
            {/* Left: Latest News */}
            <div>
              <div className="flex items-center justify-between mb-5">
                <div>
                  <h2 className="text-xl font-bold text-gray-900">
                    Latest News
                  </h2>
                  <p className="text-xs text-gray-500 mt-0.5">
                    Updates from the Ministry
                  </p>
                </div>
                <Link
                  href="/news"
                  className="text-sm font-medium text-valdoria-navy hover:text-valdoria-gold transition-colors flex items-center gap-1"
                >
                  View all
                  <svg
                    className="w-4 h-4"
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
                </Link>
              </div>
              <div className="space-y-4">
                {STATIC_NEWS.map((item) => (
                  <Link
                    key={item.id}
                    href="/news"
                    className="govt-card group flex gap-4 items-start"
                  >
                    <div className="flex-shrink-0 mt-0.5">
                      <div className="w-2 h-2 rounded-full bg-valdoria-gold mt-1.5" />
                    </div>
                    <div className="min-w-0">
                      <div className="text-xs text-gray-400 mb-1">
                        {item.date}
                      </div>
                      <h3 className="font-semibold text-gray-900 group-hover:text-valdoria-navy transition-colors leading-snug mb-1.5">
                        {item.title}
                      </h3>
                      <p className="text-sm text-gray-500 line-clamp-2 leading-relaxed">
                        {item.excerpt}
                      </p>
                    </div>
                  </Link>
                ))}
              </div>
            </div>

            {/* Right: Recent Notices */}
            <div>
              <div className="flex items-center justify-between mb-5">
                <div>
                  <h2 className="text-xl font-bold text-gray-900">
                    Recent Notices
                  </h2>
                  <p className="text-xs text-gray-500 mt-0.5">
                    Latest announcements from the Ministry
                  </p>
                </div>
                <Link
                  href="/notices"
                  className="text-sm font-medium text-valdoria-navy hover:text-valdoria-gold transition-colors flex items-center gap-1"
                >
                  View all
                  <svg
                    className="w-4 h-4"
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
                </Link>
              </div>

              {error && (
                <div className="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800 mb-4">
                  {error}
                </div>
              )}

              <div className="space-y-4">
                {loading
                  ? Array.from({ length: 3 }).map((_, i) => (
                      <NoticeSkeleton key={i} />
                    ))
                  : notices.map((notice) => (
                      <Link
                        key={notice.id}
                        href={`/notices/${notice.id}`}
                        className="govt-card group"
                      >
                        <div className="flex items-center gap-2 mb-2">
                          <span
                            className={
                              CATEGORY_BADGE[notice.category] ||
                              "govt-badge-default"
                            }
                          >
                            {notice.category || "General"}
                          </span>
                        </div>
                        <h3 className="font-semibold text-gray-900 group-hover:text-valdoria-navy transition-colors line-clamp-2 mb-2">
                          {notice.title}
                        </h3>
                        <div className="flex items-center gap-3 text-xs text-gray-500">
                          <span>{formatDate(notice.created_at)}</span>
                          <span className="text-gray-300">|</span>
                          <span className="flex items-center gap-1">
                            <svg
                              className="w-3.5 h-3.5"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke="currentColor"
                            >
                              <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth={2}
                                d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                              />
                              <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth={2}
                                d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                              />
                            </svg>
                            {notice.view_count ?? 0}
                          </span>
                        </div>
                      </Link>
                    ))}
              </div>

              {!loading && notices.length === 0 && !error && (
                <div className="text-center py-10 text-gray-500">
                  <svg
                    className="w-10 h-10 mx-auto mb-3 text-gray-300"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={1.5}
                      d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                    />
                  </svg>
                  <p>No notices available at this time.</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </section>

      {/* Section 5: Policy Highlights */}
      <section className="bg-gray-50 border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="mb-7">
            <h2 className="text-xl font-bold text-gray-900">
              Policy Highlights
            </h2>
            <p className="text-sm text-gray-500 mt-1">
              Key legislation and policy frameworks
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {POLICY_HIGHLIGHTS.map((policy) => (
              <div
                key={policy.title}
                className="govt-card flex flex-col gap-3"
              >
                <span className={policy.badgeClass}>{policy.category}</span>
                <h3 className="font-semibold text-gray-900 leading-snug">
                  {policy.title}
                </h3>
                <p className="text-sm text-gray-600 flex-1 leading-relaxed">
                  {policy.desc}
                </p>
                <Link
                  href="/policy"
                  className="inline-flex items-center gap-1 text-sm font-medium text-valdoria-navy hover:text-valdoria-gold transition-colors mt-auto"
                >
                  Learn more
                  <svg
                    className="w-4 h-4"
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
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Section 6: Stats Strip */}
      <section className="bg-valdoria-navy">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-6 text-center">
            {STATS.map((stat) => (
              <div key={stat.label}>
                <div className="text-3xl font-bold text-valdoria-gold mb-1">
                  {stat.value}
                </div>
                <div className="text-sm text-gray-400">{stat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}
