"use client";

import { useState, useEffect, useCallback, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import Link from "next/link";
import SearchBar from "../../components/SearchBar";
import Pagination from "../../components/Pagination";
import { searchPortal } from "../../lib/api";

const PAGE_SIZE = 10;

const TYPE_BADGE = {
  notice: "govt-badge-policy",
  inquiry: "govt-badge-service",
};

function SearchContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const q = searchParams.get("q") || "";

  const [results, setResults] = useState([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [searched, setSearched] = useState(false);

  const doSearch = useCallback(
    async (query, pageNum) => {
      if (!query.trim()) return;
      setLoading(true);
      setError(null);
      setSearched(true);
      try {
        const data = await searchPortal({ q: query, page: pageNum, size: PAGE_SIZE });
        setResults(data.items || []);
        setTotal(data.total || 0);
      } catch (err) {
        setError("Search failed. Please try again.");
        console.error(err);
      } finally {
        setLoading(false);
      }
    },
    []
  );

  useEffect(() => {
    if (q) {
      doSearch(q, page);
    }
  }, [q, page, doSearch]);

  const handleSearch = (query) => {
    setPage(1);
    router.push(`/search?q=${encodeURIComponent(query)}`);
  };

  const totalPages = Math.ceil(total / PAGE_SIZE);

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Breadcrumb */}
      <nav className="flex items-center gap-2 text-sm mb-6" aria-label="Breadcrumb">
        <Link href="/" className="breadcrumb-link">Home</Link>
        <svg className="w-3.5 h-3.5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
        </svg>
        <span className="text-gray-600 font-medium">Search</span>
      </nav>

      {/* Page header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Search Portal</h1>
        <p className="text-gray-500">
          Search across notices, announcements, and inquiries.
        </p>
      </div>

      {/* Search bar */}
      <div className="mb-8 max-w-xl">
        <SearchBar
          onSearch={handleSearch}
          placeholder="Enter keywords to search..."
          initialValue={q}
        />
      </div>

      {/* Error */}
      {error && (
        <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-800 mb-6">
          {error}
        </div>
      )}

      {/* Results */}
      {searched && !loading && (
        <div className="text-sm text-gray-500 mb-4">
          {total > 0 ? (
            <>
              Found <span className="font-medium text-gray-700">{total}</span>{" "}
              result{total !== 1 ? "s" : ""} for{" "}
              <span className="font-medium text-gray-700">&ldquo;{q}&rdquo;</span>
            </>
          ) : (
            <>
              No results found for{" "}
              <span className="font-medium text-gray-700">&ldquo;{q}&rdquo;</span>
            </>
          )}
        </div>
      )}

      {/* Loading */}
      {loading && (
        <div className="space-y-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="govt-card">
              <div className="skeleton h-4 w-16 rounded-full mb-3" />
              <div className="skeleton h-5 w-3/4 mb-2" />
              <div className="skeleton h-4 w-full" />
            </div>
          ))}
        </div>
      )}

      {/* Result list */}
      {!loading && results.length > 0 && (
        <div className="space-y-4">
          {results.map((item) => (
            <Link
              key={`${item.type}-${item.id}`}
              href={item.type === "notice" ? `/notices/${item.id}` : `/inquiry`}
              className="govt-card block group"
            >
              <div className="flex items-center gap-2 mb-2">
                <span className={TYPE_BADGE[item.type] || "govt-badge-default"}>
                  {item.type}
                </span>
              </div>
              <h3 className="font-semibold text-gray-900 group-hover:text-valdoria-navy transition-colors mb-1">
                {item.title}
              </h3>
              {item.snippet && (
                <p className="text-sm text-gray-500 line-clamp-2">
                  {item.snippet}
                </p>
              )}
            </Link>
          ))}
        </div>
      )}

      {/* Empty state */}
      {!loading && searched && results.length === 0 && !error && (
        <div className="text-center py-16 text-gray-500">
          <svg className="w-16 h-16 mx-auto mb-4 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <p className="text-lg font-medium mb-1">No results found</p>
          <p className="text-sm">
            Try different keywords or check your spelling.
          </p>
        </div>
      )}

      {/* Initial state (no search yet) */}
      {!searched && !loading && (
        <div className="text-center py-16 text-gray-400">
          <svg className="w-16 h-16 mx-auto mb-4 text-gray-200" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <p className="text-lg font-medium mb-1">Search the portal</p>
          <p className="text-sm">
            Enter keywords above to find notices and information.
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

export default function SearchPage() {
  return (
    <Suspense
      fallback={
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="skeleton h-8 w-48 mb-4" />
          <div className="skeleton h-10 w-full max-w-xl mb-8" />
        </div>
      }
    >
      <SearchContent />
    </Suspense>
  );
}
