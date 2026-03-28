import Link from "next/link";

const POLICY_AREAS = [
  {
    title: "Digital Governance Act 2026",
    desc: "Modernizing public administration through AI-assisted services, government cloud infrastructure, and open data mandates for all public agencies.",
    status: "Enacted",
    category: "Digital Government",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
      />
    ),
  },
  {
    title: "Public Safety Framework Act",
    desc: "National guidelines for disaster response, emergency declaration procedures, and inter-agency coordination during civil emergencies.",
    status: "Enacted",
    category: "Public Safety",
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
    title: "Data Governance & Privacy Act",
    desc: "Standards for government data collection, storage, retention, and citizen privacy rights, aligned with international data protection norms.",
    status: "Enacted",
    category: "Data & Privacy",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
      />
    ),
  },
  {
    title: "Cybersecurity Protection Act",
    desc: "Mandatory security standards and incident reporting obligations for operators of critical national infrastructure including energy, finance, and telecoms.",
    status: "Under Review",
    category: "Cybersecurity",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
      />
    ),
  },
  {
    title: "Local Autonomy Expansion Act",
    desc: "Devolving administrative authority and budgetary powers to regional and municipal governments, reducing centralization in Valdoria Capital.",
    status: "Draft",
    category: "Administration",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
      />
    ),
  },
  {
    title: "E-Government Services Modernization Plan",
    desc: "A five-year roadmap for the full digital transformation of public service delivery, targeting 95% online availability of citizen-facing services by 2030.",
    status: "In Progress",
    category: "Digital Government",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
      />
    ),
  },
];

const STATUS_STYLES = {
  Enacted: "bg-green-100 text-green-700",
  "Under Review": "bg-amber-100 text-amber-700",
  Draft: "bg-gray-100 text-gray-600",
  "In Progress": "bg-blue-100 text-blue-700",
};

const PROCESS_STEPS = [
  { step: "01", label: "Draft", desc: "Ministry prepares initial policy text and impact assessment" },
  { step: "02", label: "Review", desc: "Inter-agency review, public consultation, and legal vetting" },
  { step: "03", label: "Assembly", desc: "Presented to the National Assembly for debate and amendment" },
  { step: "04", label: "Enacted", desc: "Signed by the President, published in the Official Gazette" },
];

export default function PolicyPage() {
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
        <span className="text-gray-600 font-medium">Policy &amp; Legislation</span>
      </nav>

      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Policy &amp; Legislation</h1>
        <p className="text-gray-500 max-w-2xl">
          Key policies and legislative frameworks of the Ministry of Interior and Safety.
        </p>
      </div>

      {/* Featured Policy */}
      <div className="bg-valdoria-navy rounded-xl p-6 sm:p-8 mb-8 text-white relative overflow-hidden">
        {/* Decorative background element */}
        <div className="absolute inset-0 opacity-5">
          <svg viewBox="0 0 200 200" className="w-64 h-64 absolute -right-8 -top-8 text-white" fill="currentColor">
            <path d="M100 0C44.8 0 0 44.8 0 100s44.8 100 100 100 100-44.8 100-100S155.2 0 100 0zm0 180c-44.1 0-80-35.9-80-80s35.9-80 80-80 80 35.9 80 80-35.9 80-80 80z" />
          </svg>
        </div>
        <div className="relative">
          <div className="flex items-center gap-2 mb-3">
            <span className="bg-valdoria-gold/20 text-valdoria-gold text-xs font-semibold px-2.5 py-1 rounded uppercase tracking-wide">
              Featured Policy
            </span>
            <span className="text-white/50 text-xs">Announced March 2026</span>
          </div>
          <h2 className="text-2xl font-bold text-white mb-3">National Cybersecurity Framework 2026</h2>
          <p className="text-white/80 leading-relaxed max-w-2xl mb-5">
            A comprehensive national strategy for protecting Valdoria's digital infrastructure, government
            systems, and critical services against evolving cyber threats. The Framework establishes
            mandatory baseline controls for all public agencies, a national incident response coordination
            center, and a partnership model with Silicon Coast technology industry to strengthen resilience
            across both public and private sectors.
          </p>
          <div className="flex flex-wrap gap-3">
            <button className="inline-flex items-center gap-2 bg-valdoria-gold text-valdoria-navy text-sm font-semibold px-4 py-2 rounded-lg hover:bg-valdoria-gold/90 transition-colors">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              Download Framework (PDF)
            </button>
            <button className="inline-flex items-center gap-2 border border-white/30 text-white text-sm font-medium px-4 py-2 rounded-lg hover:bg-white/10 transition-colors">
              Read Summary
            </button>
          </div>
        </div>
      </div>

      {/* Policy Areas */}
      <section className="mb-8">
        <h2 className="text-xl font-semibold text-valdoria-navy mb-5">Policy Areas</h2>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {POLICY_AREAS.map((policy) => (
            <div key={policy.title} className="govt-card group">
              <div className="flex items-start justify-between mb-3">
                <div className="w-10 h-10 rounded-lg bg-valdoria-navy/5 flex items-center justify-center text-valdoria-navy group-hover:bg-valdoria-navy group-hover:text-white transition-colors flex-shrink-0">
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    {policy.icon}
                  </svg>
                </div>
                <span className={`text-xs font-medium px-2 py-0.5 rounded ${STATUS_STYLES[policy.status] || "bg-gray-100 text-gray-600"}`}>
                  {policy.status}
                </span>
              </div>
              <p className="text-xs text-valdoria-navy/60 font-medium uppercase tracking-wide mb-1">
                {policy.category}
              </p>
              <h3 className="font-semibold text-gray-900 group-hover:text-valdoria-navy transition-colors mb-2 leading-snug">
                {policy.title}
              </h3>
              <p className="text-sm text-gray-500 leading-relaxed">{policy.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Legislative Process */}
      <section className="mb-8">
        <h2 className="text-xl font-semibold text-valdoria-navy mb-2">Legislative Process</h2>
        <p className="text-sm text-gray-500 mb-5">
          Policies developed by the Ministry of Interior and Safety follow a structured legislative pathway
          before taking effect as national law.
        </p>
        <div className="bg-gray-50 rounded-lg p-6">
          <div className="grid gap-4 sm:grid-cols-4 relative">
            {/* Connector line (desktop) */}
            <div className="hidden sm:block absolute top-8 left-[12.5%] right-[12.5%] h-0.5 bg-valdoria-gold/30" />
            {PROCESS_STEPS.map((s) => (
              <div key={s.step} className="relative flex flex-col items-center text-center">
                <div className="w-16 h-16 rounded-full bg-valdoria-navy flex items-center justify-center mb-3 z-10">
                  <span className="text-valdoria-gold font-bold text-sm">{s.step}</span>
                </div>
                <p className="font-semibold text-gray-900 mb-1">{s.label}</p>
                <p className="text-xs text-gray-500 leading-relaxed">{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Downloads */}
      <section>
        <h2 className="text-xl font-semibold text-valdoria-navy mb-5">Official Publications</h2>
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="govt-card flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-valdoria-navy/5 flex items-center justify-center text-valdoria-navy flex-shrink-0">
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10l6 6v10a2 2 0 01-2 2z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2-10v4h-4" />
              </svg>
            </div>
            <div className="flex-1">
              <h3 className="font-semibold text-gray-900 mb-0.5">Official Gazette</h3>
              <p className="text-sm text-gray-500">Enacted laws, ministerial orders, and official announcements</p>
            </div>
            <button className="flex-shrink-0 inline-flex items-center gap-1.5 text-sm text-valdoria-navy font-medium hover:text-valdoria-navy/70 transition-colors">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
              Access
            </button>
          </div>
          <div className="govt-card flex items-center gap-4">
            <div className="w-12 h-12 rounded-lg bg-valdoria-navy/5 flex items-center justify-center text-valdoria-navy flex-shrink-0">
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4m0 5c0 2.21-3.582 4-8 4s-8-1.79-8-4" />
              </svg>
            </div>
            <div className="flex-1">
              <h3 className="font-semibold text-gray-900 mb-0.5">Legislative Database</h3>
              <p className="text-sm text-gray-500">Searchable archive of all Valdorian statutes and regulations</p>
            </div>
            <button className="flex-shrink-0 inline-flex items-center gap-1.5 text-sm text-valdoria-navy font-medium hover:text-valdoria-navy/70 transition-colors">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
              Access
            </button>
          </div>
        </div>
      </section>
    </div>
  );
}
