"use client";

import Link from "next/link";

const SERVICES = [
  {
    title: "Digital ID & Authentication",
    desc: "Secure digital identity verification and single sign-on for all government services. Register for your Valdoria Digital ID to access services online.",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2"
      />
    ),
    status: "active",
  },
  {
    title: "Online Tax Filing",
    desc: "File your annual income tax return, view tax statements, and manage payment schedules through the integrated Valdoria Revenue Service portal.",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"
      />
    ),
    status: "coming_soon",
  },
  {
    title: "Business Registration",
    desc: "Register a new business, update company information, or file annual reports. Streamlined processing with real-time application tracking.",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
      />
    ),
    status: "active",
  },
  {
    title: "Public Records Request",
    desc: "Submit requests for public government records, view the status of pending requests, and download approved documents securely.",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M8 7v8a2 2 0 002 2h6M8 7V5a2 2 0 012-2h4.586a1 1 0 01.707.293l4.414 4.414a1 1 0 01.293.707V15a2 2 0 01-2 2h-2M8 7H6a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2v-2"
      />
    ),
    status: "coming_soon",
  },
  {
    title: "Permit Applications",
    desc: "Apply for building permits, environmental clearances, event permits, and other government authorizations. Track approval progress in real time.",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
      />
    ),
    status: "active",
  },
  {
    title: "Social Welfare Services",
    desc: "Access social welfare programs, check benefit eligibility, submit applications for assistance, and manage your enrolled services.",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
      />
    ),
    status: "coming_soon",
  },
];

export default function EGovernmentPage() {
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
        <span className="text-gray-600 font-medium">E-Government Services</span>
      </nav>

      {/* Page header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          E-Government Services
        </h1>
        <p className="text-gray-500">
          Access digital government services provided by the Republic of Valdoria.
          Apply for permits, file taxes, manage your digital identity, and more.
        </p>
      </div>

      {/* Info banner */}
      <div className="rounded-lg border border-valdoria-gold/30 bg-valdoria-cream p-4 mb-8">
        <div className="flex items-start gap-3">
          <svg
            className="w-5 h-5 text-valdoria-gold flex-shrink-0 mt-0.5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={1.5}
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <div>
            <p className="text-sm font-medium text-valdoria-navy">
              Valdoria Digital ID Required
            </p>
            <p className="text-sm text-gray-600 mt-1">
              Most services require a verified Valdoria Digital ID. If you have not
              yet registered, please visit the Digital ID & Authentication service
              below to get started.
            </p>
          </div>
        </div>
      </div>

      {/* Services grid */}
      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {SERVICES.map((service) => (
          <div
            key={service.title}
            className="govt-card flex flex-col"
          >
            {/* Icon and status */}
            <div className="flex items-start justify-between mb-4">
              <div className="w-12 h-12 rounded-lg bg-valdoria-navy/5 flex items-center justify-center text-valdoria-navy">
                <svg
                  className="w-6 h-6"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  {service.icon}
                </svg>
              </div>
              {service.status === "coming_soon" && (
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-800">
                  Coming Soon
                </span>
              )}
              {service.status === "active" && (
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                  Available
                </span>
              )}
            </div>

            {/* Content */}
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              {service.title}
            </h3>
            <p className="text-sm text-gray-600 leading-relaxed mb-6 flex-grow">
              {service.desc}
            </p>

            {/* Action */}
            {service.status === "active" ? (
              <button
                className="govt-btn-primary w-full text-center text-sm"
                onClick={() => {}}
              >
                Visit Service
              </button>
            ) : (
              <button
                className="w-full text-center text-sm px-4 py-2.5 rounded-lg bg-gray-100 text-gray-400 font-medium cursor-not-allowed"
                disabled
              >
                Coming Soon
              </button>
            )}
          </div>
        ))}
      </div>

      {/* Help section */}
      <div className="mt-12 rounded-lg border border-gray-200 bg-white p-6 sm:p-8">
        <div className="flex flex-col sm:flex-row items-start gap-6">
          <div className="w-12 h-12 rounded-lg bg-valdoria-navy flex items-center justify-center text-white flex-shrink-0">
            <svg
              className="w-6 h-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={1.5}
                d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </div>
          <div>
            <h3 className="text-lg font-semibold text-gray-900 mb-2">
              Need Help?
            </h3>
            <p className="text-sm text-gray-600 leading-relaxed mb-4">
              If you need assistance with any e-government service, our support
              team is available Monday to Friday, 09:00 to 18:00.
            </p>
            <div className="flex flex-wrap gap-4 text-sm">
              <div className="flex items-center gap-2 text-gray-700">
                <svg
                  className="w-4 h-4 text-valdoria-gold"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={1.5}
                    d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                  />
                </svg>
                <span>+42 (0)2 3100-7000</span>
              </div>
              <div className="flex items-center gap-2 text-gray-700">
                <svg
                  className="w-4 h-4 text-valdoria-gold"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={1.5}
                    d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                  />
                </svg>
                <span>eservices@mois.gov.vd</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
