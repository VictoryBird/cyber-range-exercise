import Link from "next/link";

const MISSION_PILLARS = [
  {
    title: "Public Administration",
    desc: "Delivering efficient, transparent, and citizen-centered administrative services across all regions of Valdoria.",
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
    title: "National Safety",
    desc: "Protecting citizens from natural disasters, civil emergencies, and safety hazards through preparedness and rapid response.",
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
    title: "Digital Government",
    desc: "Leading Valdoria's transformation to a data-driven, digitally accessible government that serves every citizen.",
    icon: (
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={1.5}
        d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
      />
    ),
  },
];

const TIMELINE = [
  {
    year: "2003",
    title: "Ministry of Interior established",
    desc: "Founded in the aftermath of the Siros Strait Crisis to consolidate national administrative authority and coordinate emergency response.",
  },
  {
    year: "2008",
    title: "National Emergency Management Agency merged",
    desc: "NEMA integrated into the Ministry, creating a unified command structure for disaster preparedness and civil protection.",
  },
  {
    year: "2012",
    title: "Digital Government Bureau created",
    desc: "Launched Valdoria's first national e-government initiative, digitizing civil registration and government service portals.",
  },
  {
    year: "2016",
    title: "Renamed Ministry of Interior and Safety",
    desc: "Mandate expanded to formally encompass national safety policy, reflecting the growing importance of disaster and crisis management.",
  },
  {
    year: "2020",
    title: "Cyber Defense Command liaison office established",
    desc: "A dedicated CDC liaison office was formed within the Ministry to coordinate civilian-military response to cyber incidents.",
  },
  {
    year: "2025",
    title: "Minister Elias Koren appointed",
    desc: "Minister Koren assumed leadership and announced the National Cybersecurity Framework, prioritizing digital resilience across all government operations.",
  },
];

const DEPARTMENTS = [
  "Public Administration Bureau",
  "Safety Policy Bureau",
  "Digital Government Bureau",
  "Emergency Management Office",
  "Cyber Affairs Division",
];

export default function AboutPage() {
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
        <span className="text-gray-600 font-medium">About</span>
      </nav>

      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">About the Ministry</h1>
        <p className="text-gray-500 max-w-2xl">
          The Ministry of Interior and Safety is the central government authority responsible for public
          administration, national safety, and digital governance in the Republic of Valdoria.
        </p>
      </div>

      {/* Minister's Message */}
      <section className="govt-card mb-8">
        <h2 className="text-xl font-semibold text-valdoria-navy mb-5">Minister's Message</h2>
        <div className="flex flex-col sm:flex-row gap-6 items-start">
          <div className="flex-shrink-0 flex flex-col items-center gap-2">
            <div className="w-20 h-20 rounded-full bg-valdoria-navy flex items-center justify-center">
              <span className="text-2xl font-bold text-valdoria-gold tracking-wider">EK</span>
            </div>
            <div className="text-center">
              <p className="text-sm font-semibold text-gray-800">Elias Koren</p>
              <p className="text-xs text-gray-500">Minister of Interior and Safety</p>
              <p className="text-xs text-gray-400">Appointed 2025</p>
            </div>
          </div>
          <blockquote className="flex-1 border-l-4 border-valdoria-gold pl-5">
            <p className="text-gray-700 leading-relaxed italic mb-3">
              "Public safety and digital governance are not competing priorities — they are two pillars of the
              same commitment to our citizens. As Valdoria accelerates its digital transformation, this Ministry
              is determined to ensure that every service, every system, and every decision is built on a foundation
              of transparency, security, and trust. We serve 8.2 million people; every one of them deserves a
              government that is both capable and accountable."
            </p>
            <p className="text-sm text-valdoria-navy font-medium">
              — Minister Elias Koren, Address to the National Assembly, March 2025
            </p>
          </blockquote>
        </div>
      </section>

      {/* Our Mission */}
      <section className="mb-8">
        <h2 className="text-xl font-semibold text-valdoria-navy mb-5">Our Mission</h2>
        <div className="grid gap-4 sm:grid-cols-3">
          {MISSION_PILLARS.map((pillar) => (
            <div key={pillar.title} className="govt-card">
              <div className="w-12 h-12 rounded-lg bg-valdoria-navy/5 flex items-center justify-center text-valdoria-navy mb-4">
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  {pillar.icon}
                </svg>
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">{pillar.title}</h3>
              <p className="text-sm text-gray-500 leading-relaxed">{pillar.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* History Timeline */}
      <section className="mb-8">
        <h2 className="text-xl font-semibold text-valdoria-navy mb-5">History</h2>
        <div className="relative">
          {/* Vertical line */}
          <div className="absolute left-16 top-0 bottom-0 w-0.5 bg-valdoria-gold/30 hidden sm:block" />
          <div className="space-y-0">
            {TIMELINE.map((item, idx) => (
              <div key={item.year} className="flex gap-4 sm:gap-0 relative">
                {/* Year */}
                <div className="flex-shrink-0 w-14 sm:w-16 pt-4 text-right">
                  <span className="text-sm font-bold text-valdoria-navy">{item.year}</span>
                </div>
                {/* Dot */}
                <div className="hidden sm:flex flex-col items-center mx-4 pt-4">
                  <div className="w-3 h-3 rounded-full bg-valdoria-gold border-2 border-white ring-2 ring-valdoria-gold/30 flex-shrink-0 z-10" />
                  {idx < TIMELINE.length - 1 && (
                    <div className="w-0.5 flex-1 bg-transparent" />
                  )}
                </div>
                {/* Content */}
                <div className={`flex-1 pb-6 ${idx < TIMELINE.length - 1 ? "" : ""}`}>
                  <div className="bg-gray-50 rounded-lg p-4 sm:ml-0">
                    <h3 className="font-semibold text-gray-900 mb-1">{item.title}</h3>
                    <p className="text-sm text-gray-500 leading-relaxed">{item.desc}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Organization */}
      <section className="mb-8">
        <h2 className="text-xl font-semibold text-valdoria-navy mb-5">Organization</h2>
        <div className="govt-card">
          {/* Minister at top */}
          <div className="flex justify-center mb-6">
            <div className="bg-valdoria-navy text-white rounded-lg px-6 py-3 text-center shadow-md">
              <p className="text-xs text-valdoria-gold font-medium uppercase tracking-wide mb-0.5">Minister</p>
              <p className="font-semibold">Elias Koren</p>
              <p className="text-xs text-white/70">Ministry of Interior and Safety</p>
            </div>
          </div>
          {/* Connector */}
          <div className="flex justify-center mb-2">
            <div className="w-0.5 h-6 bg-valdoria-gold/40" />
          </div>
          <div className="flex justify-center mb-2">
            <div className="h-0.5 w-full max-w-2xl bg-valdoria-gold/30" />
          </div>
          {/* Departments */}
          <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
            {DEPARTMENTS.map((dept) => (
              <div
                key={dept}
                className="border border-valdoria-navy/20 rounded-lg px-3 py-3 text-center bg-valdoria-cream/40"
              >
                <p className="text-xs font-medium text-valdoria-navy leading-snug">{dept}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Contact */}
      <section>
        <h2 className="text-xl font-semibold text-valdoria-navy mb-5">Contact Information</h2>
        <div className="bg-gray-50 rounded-lg p-6">
          <div className="grid gap-6 sm:grid-cols-2">
            <div className="flex gap-3">
              <div className="flex-shrink-0 w-10 h-10 rounded-lg bg-valdoria-navy/5 flex items-center justify-center text-valdoria-navy">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </div>
              <div>
                <p className="text-sm font-semibold text-gray-800 mb-0.5">Address</p>
                <p className="text-sm text-gray-600">14 Republic Avenue, Central District</p>
                <p className="text-sm text-gray-600">Valdoria Capital 10100</p>
                <p className="text-sm text-gray-600">Republic of Valdoria</p>
              </div>
            </div>
            <div className="flex gap-3">
              <div className="flex-shrink-0 w-10 h-10 rounded-lg bg-valdoria-navy/5 flex items-center justify-center text-valdoria-navy">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                </svg>
              </div>
              <div>
                <p className="text-sm font-semibold text-gray-800 mb-0.5">Phone</p>
                <p className="text-sm text-gray-600">
                  <span className="font-medium">110</span> — Government Helpline (domestic)
                </p>
                <p className="text-sm text-gray-600">
                  <span className="font-medium">+42-2-3100-7000</span> — Main Office
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
