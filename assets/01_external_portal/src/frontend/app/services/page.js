import Link from "next/link";

const SERVICES = [
  {
    title: "Complaint Filing Portal",
    desc: "Submit civil complaints, attach supporting documents, and track processing status online.",
    href: "https://minwon.mois.valdoria.gov",
    external: true,
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
      />
    ),
    badge: "Online",
  },
  {
    title: "Resident Registration",
    desc: "Apply for resident registration, address changes, and family relation certificates.",
    href: "#",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0"
      />
    ),
    badge: "In-person",
  },
  {
    title: "Passport Services",
    desc: "Apply for new passports, renewals, and travel document modifications.",
    href: "#",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"
      />
    ),
    badge: "In-person",
  },
  {
    title: "Vehicle Registration",
    desc: "Register vehicles, transfer ownership, and manage license plates.",
    href: "#",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M8 17h8M8 17v-4m8 4v-4m-8 0h8m-8 0V9a2 2 0 012-2h4a2 2 0 012 2v4M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
      />
    ),
    badge: "Online",
  },
  {
    title: "Business Permits & Licenses",
    desc: "Apply for business registration, food safety permits, and commercial licenses.",
    href: "#",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
      />
    ),
    badge: "Online",
  },
  {
    title: "Public Safety Reports",
    desc: "Report safety hazards, request fire inspections, and access emergency contact information.",
    href: "#",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
      />
    ),
    badge: "Online",
  },
];

export default function ServicesPage() {
  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Breadcrumb */}
      <nav
        className="flex items-center gap-2 text-sm mb-6"
        aria-label="Breadcrumb"
      >
        <Link href="/" className="breadcrumb-link">
          Home
        </Link>
        <svg
          className="w-3.5 h-3.5 text-gray-400"
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
        <span className="text-gray-600 font-medium">Civil Services</span>
      </nav>

      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          Civil Services
        </h1>
        <p className="text-gray-500 max-w-2xl">
          Access government services provided by the Ministry of Interior and
          Safety. Some services are available online while others require an
          in-person visit to your local government office.
        </p>
      </div>

      {/* Complaint portal callout */}
      <div className="bg-valdoria-cream border border-valdoria-gold/30 rounded-lg p-6 mb-8 flex flex-col sm:flex-row items-start sm:items-center gap-4">
        <div className="flex-1">
          <h2 className="text-lg font-semibold text-valdoria-navy mb-1">
            Need to file a complaint?
          </h2>
          <p className="text-sm text-gray-600">
            Use the dedicated Complaint Filing Portal to submit civil
            complaints, attach documents, and track your case in real time.
          </p>
        </div>
        <a
          href="https://minwon.mois.valdoria.gov"
          target="_blank"
          rel="noopener noreferrer"
          className="govt-btn-primary flex-shrink-0 flex items-center gap-2"
        >
          Go to Complaint Portal
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
              d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
            />
          </svg>
        </a>
      </div>

      {/* Services grid */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {SERVICES.map((svc) => {
          const Tag = svc.external ? "a" : "div";
          const extraProps = svc.external
            ? {
                href: svc.href,
                target: "_blank",
                rel: "noopener noreferrer",
              }
            : {};
          return (
            <Tag
              key={svc.title}
              {...extraProps}
              className="govt-card group cursor-pointer"
            >
              <div className="flex items-center gap-3 mb-3">
                <div className="w-10 h-10 rounded-lg bg-valdoria-navy/5 flex items-center justify-center text-valdoria-navy group-hover:bg-valdoria-navy group-hover:text-white transition-colors">
                  <svg
                    className="w-5 h-5"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    {svc.icon}
                  </svg>
                </div>
                <span
                  className={`text-xs font-medium px-2 py-0.5 rounded ${
                    svc.badge === "Online"
                      ? "bg-green-100 text-green-700"
                      : "bg-gray-100 text-gray-600"
                  }`}
                >
                  {svc.badge}
                </span>
              </div>
              <h3 className="font-semibold text-gray-900 group-hover:text-valdoria-navy transition-colors mb-1">
                {svc.title}
              </h3>
              <p className="text-sm text-gray-500 leading-relaxed">
                {svc.desc}
              </p>
              {svc.external && (
                <div className="mt-3 text-xs text-valdoria-navy font-medium flex items-center gap-1">
                  Visit portal
                  <svg
                    className="w-3 h-3"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                    />
                  </svg>
                </div>
              )}
            </Tag>
          );
        })}
      </div>

      {/* Contact info */}
      <div className="mt-10 bg-gray-50 rounded-lg p-6 text-center">
        <h2 className="text-lg font-semibold text-gray-800 mb-2">
          Need Assistance?
        </h2>
        <p className="text-sm text-gray-500 mb-4">
          Contact the Government Call Center for guidance on available services.
        </p>
        <div className="flex justify-center gap-6 text-sm text-gray-600">
          <div className="flex items-center gap-2">
            <svg
              className="w-4 h-4 text-valdoria-navy"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
              />
            </svg>
            110 (domestic) | +42 (0)2 3100-7000
          </div>
        </div>
      </div>
    </div>
  );
}
