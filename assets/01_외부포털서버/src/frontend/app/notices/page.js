"use client";

import { useState, useEffect, useCallback } from "react";
import Link from "next/link";
import { fetchNotices } from "../../lib/api";
import Pagination from "../../components/Pagination";

const CATEGORIES = [
  { key: null, label: "All" },
  { key: "policy", label: "Policy" },
  { key: "security", label: "Security" },
  { key: "service", label: "Service" },
  { key: "system", label: "System" },
  { key: "recruitment", label: "Recruitment" },
];

const CATEGORY_BADGE = {
  policy: "govt-badge-policy",
  security: "govt-badge-security",
  service: "govt-badge-service",
  system: "govt-badge-system",
  recruitment: "govt-badge-recruitment",
};

const PAGE_SIZE = 10;

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
      <div className="flex items-center gap-2 mb-3">
        <div className="skeleton h-5 w-16 rounded-full" />
      </div>
      <div className="skeleton h-5 w-4/5 mb-2" />
      <div className="skeleton h-4 w-3/5 mb-3" />
      <div className="flex gap-4">
        <div className="skeleton h-3 w-20" />
        <div className="skeleton h-3 w-16" />
      </div>
    </div>
  );
}

export default function NoticesPage() {
  const [notices, setNotices] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [category, setCategory] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const loadNotices = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await fetchNotices({ page, size: PAGE_SIZE, category });
      setNotices(data.items || []);
      setTotal(data.total || 0);
    } catch (err) {
      setError("Failed to load notices. Please try again later.");
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, [page, category]);

  useEffect(() => {
    loadNotices();
  }, [loadNotices]);

  const totalPages = Math.ceil(total / PAGE_SIZE);

  const handleCategoryChange = (key) => {
    setCategory(key);
    setPage(1);
  };

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
        <span className="text-gray-600 font-medium">Notices</span>
      </nav>

      {/* Page header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Notice Board</h1>
        <p className="text-gray-500">
          Official announcements and updates from the Ministry of Interior and
          Safety.
        </p>
      </div>

      {/* Category filter tabs */}
      <div className="flex flex-wrap gap-2 mb-6 pb-4 border-b border-gray-200">
        {CATEGORIES.map((cat) => (
          <button
            key={cat.label}
            onClick={() => handleCategoryChange(cat.key)}
            className={`px-4 py-2 text-sm font-medium rounded-full transition-colors duration-150 ${
              category === cat.key
                ? "bg-valdoria-navy text-white"
                : "bg-gray-100 text-gray-600 hover:bg-gray-200"
            }`}
          >
            {cat.label}
          </button>
        ))}
      </div>

      {/* Error state */}
      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-800 mb-6">
          <div className="flex items-center gap-2">
            <svg className="w-4 h-4 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            {error}
          </div>
        </div>
      )}

      {/* Results info */}
      {!loading && !error && (
        <div className="text-sm text-gray-500 mb-4">
          Showing {notices.length} of {total} notice{total !== 1 ? "s" : ""}
          {category && (
            <span>
              {" "}
              in <span className="font-medium text-gray-700">{category}</span>
            </span>
          )}
        </div>
      )}

      {/* Notice grid */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {loading
          ? Array.from({ length: 6 }).map((_, i) => <NoticeSkeleton key={i} />)
          : notices.map((notice) => (
              <Link
                key={notice.id}
                href={`/notices/${notice.id}`}
                className="govt-card group"
              >
                <div className="flex items-center gap-2 mb-3">
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
                <div className="flex items-center gap-3 text-xs text-gray-500 mt-auto pt-2">
                  <span>{formatDate(notice.created_at)}</span>
                  <span className="text-gray-300">|</span>
                  <span>{notice.author}</span>
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

      {/* Empty state */}
      {!loading && notices.length === 0 && !error && (
        <div className="text-center py-16 text-gray-500">
          <svg className="w-16 h-16 mx-auto mb-4 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <p className="text-lg font-medium mb-1">No notices found</p>
          <p className="text-sm">
            {category
              ? "Try selecting a different category."
              : "There are no notices available at this time."}
          </p>
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="mt-8 pt-6 border-t border-gray-200">
          <Pagination
            currentPage={page}
            totalPages={totalPages}
            onPageChange={setPage}
          />
        </div>
      )}
    </div>
  );
}
