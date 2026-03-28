import Link from "next/link";

const KEY_STATS = [
  { label: "Population (2026 est.)", value: "8,247,000", sub: "Republic of Valdoria" },
  { label: "Government Employees", value: "241,000", sub: "Civil servants nationwide" },
  { label: "E-Government Usage", value: "87.3%", sub: "Citizens using digital services" },
  { label: "Emergency Response Time", value: "4.2 min", sub: "National average" },
  { label: "Public Satisfaction Rating", value: "78.6%", sub: "2026 annual survey" },
  { label: "Digital Services Available", value: "342", sub: "Online government services" },
];

const DATASETS = [
  {
    title: "Annual Government Budget Summary 2026",
    format: "CSV",
    size: "2.4 MB",
    updated: "Mar 1, 2026",
  },
  {
    title: "Regional Population Statistics",
    format: "CSV",
    size: "1.1 MB",
    updated: "Feb 15, 2026",
  },
  {
    title: "Public Safety Incident Reports Q4 2025",
    format: "CSV",
    size: "3.8 MB",
    updated: "Jan 31, 2026",
  },
  {
    title: "E-Government Service Usage Statistics",
    format: "CSV",
    size: "890 KB",
    updated: "Mar 10, 2026",
  },
  {
    title: "Civil Complaint Processing Metrics",
    format: "CSV",
    size: "1.5 MB",
    updated: "Mar 5, 2026",
  },
  {
    title: "National Emergency Shelter Locations",
    format: "GeoJSON",
    size: "4.2 MB",
    updated: "Feb 28, 2026",
  },
];

const INFOGRAPHIC_BARS = [
  { label: "E-Gov Usage", value: 87, color: "bg-valdoria-navy" },
  { label: "Satisfaction", value: 79, color: "bg-valdoria-gold" },
  { label: "Digital Coverage", value: 95, color: "bg-blue-500" },
  { label: "Response SLA Met", value: 93, color: "bg-green-500" },
];

const FORMAT_COLORS = {
  CSV: "bg-blue-100 text-blue-700",
  GeoJSON: "bg-purple-100 text-purple-700",
};

export default function DataPage() {
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
        <span className="text-gray-600 font-medium">Open Data &amp; Statistics</span>
      </nav>

      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Open Data &amp; Statistics</h1>
        <p className="text-gray-500 max-w-2xl">
          Transparency through accessible government data. Download official datasets and explore key indicators for the Republic of Valdoria.
        </p>
      </div>

      {/* Key Statistics Dashboard */}
      <section className="mb-10">
        <h2 className="text-xs font-semibold text-valdoria-navy uppercase tracking-widest mb-4">
          Key Statistics Dashboard
        </h2>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
          {KEY_STATS.map((stat) => (
            <div key={stat.label} className="govt-card text-center">
              <p className="text-2xl font-bold text-valdoria-navy leading-none mb-1">{stat.value}</p>
              <p className="text-xs font-medium text-gray-700 mb-0.5">{stat.label}</p>
              <p className="text-xs text-gray-400">{stat.sub}</p>
            </div>
          ))}
        </div>
      </section>

      <div className="lg:grid lg:grid-cols-3 lg:gap-8">
        {/* Datasets table */}
        <div className="lg:col-span-2">
          <h2 className="text-xs font-semibold text-valdoria-navy uppercase tracking-widest mb-4">
            Downloadable Datasets
          </h2>
          <div className="bg-white border border-gray-200 rounded-lg overflow-hidden divide-y divide-gray-100">
            {DATASETS.map((ds) => (
              <div
                key={ds.title}
                className="flex items-center gap-4 px-5 py-4 hover:bg-gray-50 transition-colors"
              >
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900 truncate">{ds.title}</p>
                  <p className="text-xs text-gray-400 mt-0.5">Updated {ds.updated}</p>
                </div>
                <div className="flex items-center gap-3 flex-shrink-0">
                  <span
                    className={`text-xs font-medium px-2 py-0.5 rounded ${
                      FORMAT_COLORS[ds.format] ?? "bg-gray-100 text-gray-600"
                    }`}
                  >
                    {ds.format}
                  </span>
                  <span className="text-xs text-gray-500 w-14 text-right">{ds.size}</span>
                  <a
                    href="#"
                    aria-label={`Download ${ds.title}`}
                    className="text-valdoria-navy hover:text-valdoria-gold transition-colors"
                  >
                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={1.5}
                        d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                      />
                    </svg>
                  </a>
                </div>
              </div>
            ))}
          </div>
          <p className="text-xs text-gray-400 mt-2">
            All datasets are published under the Valdoria Open Government Licence v2.0.
          </p>
        </div>

        {/* Sidebar: Infographic + Policy */}
        <div className="mt-8 lg:mt-0 space-y-6">
          {/* Government at a Glance */}
          <div className="bg-valdoria-navy rounded-xl p-5 text-white">
            <h2 className="text-xs font-semibold uppercase tracking-widest text-white/60 mb-1">
              Infographic
            </h2>
            <p className="font-bold text-lg mb-4 leading-snug">Government at a Glance 2026</p>
            <div className="space-y-3">
              {INFOGRAPHIC_BARS.map((bar) => (
                <div key={bar.label}>
                  <div className="flex justify-between text-xs mb-1">
                    <span className="text-white/80">{bar.label}</span>
                    <span className="font-semibold">{bar.value}%</span>
                  </div>
                  <div className="h-2 rounded-full bg-white/10 overflow-hidden">
                    <div
                      className={`h-full rounded-full ${bar.color}`}
                      style={{ width: `${bar.value}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
            <p className="text-xs text-white/40 mt-4">Source: Ministry of Interior and Safety, March 2026</p>
          </div>

          {/* Open Data Policy */}
          <div className="govt-card">
            <div className="flex items-center gap-2 mb-3">
              <div className="w-8 h-8 rounded-lg bg-valdoria-navy/5 flex items-center justify-center text-valdoria-navy">
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={1.5}
                    d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                  />
                </svg>
              </div>
              <h2 className="text-sm font-semibold text-valdoria-navy">Open Data Policy</h2>
            </div>
            <p className="text-sm text-gray-600 leading-relaxed mb-4">
              Valdoria is committed to proactive data transparency. Government datasets are released
              in machine-readable formats and updated on regular publication schedules under our open
              data framework adopted in 2022.
            </p>
            <Link
              href="/policy"
              className="inline-flex items-center gap-1.5 text-sm font-medium text-valdoria-navy hover:text-valdoria-gold transition-colors"
            >
              View full policy
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
              </svg>
            </Link>
          </div>

          {/* Contact */}
          <div className="bg-gray-50 rounded-lg p-4">
            <p className="text-sm font-semibold text-gray-800 mb-1">Data Requests</p>
            <p className="text-xs text-gray-500 mb-2">
              Need a dataset not listed here? Submit a data request to the Statistics Division.
            </p>
            <a href="#" className="govt-btn-primary text-sm w-full flex justify-center">
              Submit Data Request
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
