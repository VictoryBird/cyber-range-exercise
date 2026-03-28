"use client";

import { useState } from "react";
import Link from "next/link";
import { fetchInquiry } from "../../lib/api";

const STATUS_CLASS = {
  received: "status-received",
  in_progress: "status-in-progress",
  completed: "status-completed",
  rejected: "status-rejected",
};

const STATUS_LABEL = {
  received: "Received",
  in_progress: "In Progress",
  completed: "Completed",
  rejected: "Rejected",
};

function formatDate(dateStr) {
  if (!dateStr) return "";
  const d = new Date(dateStr);
  return d.toLocaleDateString("en-GB", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

export default function InquiryPage() {
  const [trackingNumber, setTrackingNumber] = useState("");
  const [inquiry, setInquiry] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [searched, setSearched] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    const tn = trackingNumber.trim();
    if (!tn) return;

    setLoading(true);
    setError(null);
    setInquiry(null);
    setSearched(true);

    try {
      const data = await fetchInquiry(tn);
      setInquiry(data);
    } catch (err) {
      if (err.response?.status === 404) {
        setError("No inquiry found with the provided tracking number.");
      } else {
        setError("Failed to look up inquiry. Please try again later.");
      }
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Breadcrumb */}
      <nav className="flex items-center gap-2 text-sm mb-6" aria-label="Breadcrumb">
        <Link href="/" className="breadcrumb-link">Home</Link>
        <svg className="w-3.5 h-3.5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
        </svg>
        <span className="text-gray-600 font-medium">Inquiry Status</span>
      </nav>

      {/* Page header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          Inquiry Status Tracker
        </h1>
        <p className="text-gray-500">
          Enter your tracking number to check the status of your submitted
          inquiry or complaint.
        </p>
      </div>

      {/* Search form */}
      <div className="bg-valdoria-cream rounded-lg border border-gray-200 p-6 mb-8">
        <form onSubmit={handleSubmit} className="flex gap-3">
          <div className="flex-1">
            <label htmlFor="tracking" className="sr-only">
              Tracking Number
            </label>
            <input
              id="tracking"
              type="text"
              value={trackingNumber}
              onChange={(e) => setTrackingNumber(e.target.value)}
              placeholder="e.g., INQ-2026-00001"
              className="govt-input"
              disabled={loading}
            />
          </div>
          <button
            type="submit"
            disabled={loading || !trackingNumber.trim()}
            className="govt-btn-primary disabled:opacity-50 disabled:cursor-not-allowed flex-shrink-0"
          >
            {loading ? (
              <svg className="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
              </svg>
            ) : (
              "Look Up"
            )}
          </button>
        </form>
        <p className="text-xs text-gray-500 mt-2">
          Your tracking number was provided when you submitted your inquiry.
        </p>
      </div>

      {/* Error */}
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

      {/* Loading */}
      {loading && (
        <div className="govt-card">
          <div className="skeleton h-5 w-32 mb-4" />
          <div className="skeleton h-6 w-3/4 mb-3" />
          <div className="grid grid-cols-2 gap-4">
            <div className="skeleton h-4 w-full" />
            <div className="skeleton h-4 w-full" />
            <div className="skeleton h-4 w-full" />
            <div className="skeleton h-4 w-full" />
          </div>
        </div>
      )}

      {/* Inquiry result */}
      {inquiry && !loading && (
        <div className="govt-card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">
              Inquiry Details
            </h2>
            <span className={STATUS_CLASS[inquiry.status] || "govt-badge-default"}>
              {STATUS_LABEL[inquiry.status] || inquiry.status}
            </span>
          </div>

          <div className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <dt className="text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
                  Tracking Number
                </dt>
                <dd className="text-sm font-mono font-medium text-valdoria-navy">
                  {inquiry.tracking_number}
                </dd>
              </div>
              <div>
                <dt className="text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
                  Department
                </dt>
                <dd className="text-sm text-gray-800">
                  {inquiry.department || "Not assigned"}
                </dd>
              </div>
              <div>
                <dt className="text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
                  Submitted By
                </dt>
                <dd className="text-sm text-gray-800">
                  {inquiry.submitter_name}
                </dd>
              </div>
              <div>
                <dt className="text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
                  Submitted Date
                </dt>
                <dd className="text-sm text-gray-800">
                  {formatDate(inquiry.submitted_at)}
                </dd>
              </div>
            </div>

            <div className="pt-3 border-t border-gray-100">
              <dt className="text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
                Subject
              </dt>
              <dd className="text-sm text-gray-800">{inquiry.subject}</dd>
            </div>

            {inquiry.updated_at && (
              <div className="pt-3 border-t border-gray-100 text-xs text-gray-400">
                Last updated: {formatDate(inquiry.updated_at)}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Initial state */}
      {!searched && !loading && (
        <div className="text-center py-12 text-gray-400">
          <svg className="w-16 h-16 mx-auto mb-4 text-gray-200" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
          </svg>
          <p className="text-lg font-medium mb-1">Track your inquiry</p>
          <p className="text-sm">
            Enter your tracking number above to view the current status.
          </p>
        </div>
      )}
    </div>
  );
}
