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

export default function HomePage() {
  const [notices, setNotices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchNotices({ page: 1, size: 5 })
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
      {/* Hero banner */}
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
              Serving the citizens of the Republic of Valdoria with
              transparent governance, public safety, and accessible digital
              government services.
            </p>
            <div className="flex flex-wrap gap-3">
              <Link href="/notices" className="govt-btn-primary !bg-valdoria-gold !text-valdoria-navy-dark hover:!bg-valdoria-gold-light">
                View Notices
              </Link>
              <Link href="/services" className="govt-btn-primary !bg-white !text-valdoria-navy-dark hover:!bg-gray-200">
                Civil Services
              </Link>
            </div>
          </div>
        </div>

        {/* Bottom gold accent */}
        <div className="h-1 bg-gradient-to-r from-valdoria-gold via-valdoria-gold-light to-valdoria-gold" />
      </section>

      {/* Quick links */}
      <section className="bg-valdoria-cream border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              {
                href: "/notices",
                icon: (
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={1.5}
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                ),
                label: "Notice Board",
                desc: "Official announcements",
              },
              {
                href: "/search",
                icon: (
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={1.5}
                    d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                  />
                ),
                label: "Search",
                desc: "Find information",
              },
              {
                href: "/services",
                icon: (
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={1.5}
                    d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                  />
                ),
                label: "Civil Services",
                desc: "Government services",
              },
              {
                href: "/egovernment",
                icon: (
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={1.5}
                    d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"
                  />
                ),
                label: "E-Government",
                desc: "Digital services",
              },
            ].map((item) => (
              <Link
                key={item.label}
                href={item.href}
                className="flex items-center gap-3 p-4 bg-white rounded-lg border border-gray-200
                           hover:border-valdoria-navy/20 hover:shadow-sm transition-all duration-200 group"
              >
                <div className="flex-shrink-0 w-10 h-10 rounded-lg bg-valdoria-navy/5 flex items-center justify-center
                                group-hover:bg-valdoria-navy group-hover:text-white text-valdoria-navy transition-colors duration-200">
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    {item.icon}
                  </svg>
                </div>
                <div>
                  <div className="text-sm font-semibold text-gray-800 group-hover:text-valdoria-navy transition-colors">
                    {item.label}
                  </div>
                  <div className="text-xs text-gray-500">{item.desc}</div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Recent notices */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-2xl font-bold text-gray-900">
              Recent Notices
            </h2>
            <p className="text-sm text-gray-500 mt-1">
              Latest announcements from the Ministry
            </p>
          </div>
          <Link
            href="/notices"
            className="text-sm font-medium text-valdoria-navy hover:text-valdoria-gold transition-colors flex items-center gap-1"
          >
            View all
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </Link>
        </div>

        {error && (
          <div className="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
            {error}
          </div>
        )}

        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {loading
            ? Array.from({ length: 5 }).map((_, i) => (
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
                        CATEGORY_BADGE[notice.category] || "govt-badge-default"
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
                      <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                      </svg>
                      {notice.view_count ?? 0}
                    </span>
                  </div>
                </Link>
              ))}
        </div>

        {!loading && notices.length === 0 && !error && (
          <div className="text-center py-12 text-gray-500">
            <svg className="w-12 h-12 mx-auto mb-3 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <p>No notices available at this time.</p>
          </div>
        )}
      </section>

      {/* Stats strip */}
      <section className="bg-valdoria-navy">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-6 text-center">
            {[
              { value: "24/7", label: "Service Availability" },
              { value: "15+", label: "Government Departments" },
              { value: "1,200+", label: "Published Notices" },
              { value: "99.9%", label: "System Uptime" },
            ].map((stat) => (
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
