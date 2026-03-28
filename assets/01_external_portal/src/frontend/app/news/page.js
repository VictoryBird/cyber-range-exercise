import Link from "next/link";

const FEATURED_STORY = {
  date: "Mar 25, 2026",
  category: "Policy",
  title: "Minister Koren Announces National Cybersecurity Framework 2026",
  excerpt:
    "The Ministry unveiled a comprehensive cybersecurity strategy covering critical infrastructure protection, public awareness, and international cooperation. The framework sets binding standards for all government agencies and establishes a new public-private partnership board.",
};

const NEWS_ITEMS = [
  {
    date: "Mar 20, 2026",
    category: "Policy",
    title: "Valdoria Ranks 4th in Global E-Government Index",
    excerpt:
      "The annual UN E-Government Survey ranked Valdoria fourth worldwide, up from seventh in 2024, citing improvements in digital service delivery.",
  },
  {
    date: "Mar 18, 2026",
    category: "Safety",
    title: "Southern Coast Typhoon Preparedness Exercise Completed",
    excerpt:
      "Over 2,000 personnel participated in the annual disaster response drill, testing coordination across civil defense, police, and medical units.",
  },
  {
    date: "Mar 15, 2026",
    category: "Service",
    title: "New Digital ID System Rollout Begins in Capital District",
    excerpt:
      "Citizens can now apply for the enhanced digital identification card at district offices or via the government online portal.",
  },
  {
    date: "Mar 12, 2026",
    category: "Policy",
    title: "Data Governance Act Passes Assembly with Bipartisan Support",
    excerpt:
      "The landmark legislation establishes new standards for government data management, privacy protections, and inter-agency data sharing.",
  },
  {
    date: "Mar 8, 2026",
    category: "Safety",
    title: "Cybersecurity Awareness Week: 50,000 Citizens Participated",
    excerpt:
      "Record participation in the annual nationwide cybersecurity education campaign, with workshops held in all 14 provinces.",
  },
  {
    date: "Mar 5, 2026",
    category: "Service",
    title: "Rural Digital Connectivity Program Reaches 95% Coverage",
    excerpt:
      "High-speed internet now available to nearly all Valdorian households, completing the final phase of the national broadband expansion.",
  },
];

const MINISTER_ACTIVITIES = [
  {
    date: "Mar 22",
    text: "Minister Koren meets with Arventan delegation on intelligence cooperation",
  },
  {
    date: "Mar 19",
    text: "Minister attends National Emergency Response Center briefing",
  },
  {
    date: "Mar 14",
    text: "Minister opens Silicon Coast Innovation Forum 2026",
  },
];

const CATEGORY_COLORS = {
  Policy: "bg-blue-100 text-blue-700",
  Safety: "bg-red-100 text-red-700",
  Service: "bg-green-100 text-green-700",
};

export default function NewsPage() {
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
        <span className="text-gray-600 font-medium">News &amp; Media</span>
      </nav>

      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">News &amp; Media</h1>
        <p className="text-gray-500 max-w-2xl">
          Official news releases, ministerial announcements, and media resources from the Ministry of Interior and Safety.
        </p>
      </div>

      <div className="lg:grid lg:grid-cols-3 lg:gap-8">
        {/* Main content */}
        <div className="lg:col-span-2 space-y-8">
          {/* Featured Story */}
          <div>
            <h2 className="text-xs font-semibold text-valdoria-navy uppercase tracking-widest mb-4">
              Featured Story
            </h2>
            <div className="bg-valdoria-navy rounded-xl p-6 text-white">
              <div className="flex items-center gap-3 mb-3">
                <span className="text-xs font-medium px-2 py-0.5 rounded bg-valdoria-gold text-valdoria-navy">
                  {FEATURED_STORY.category}
                </span>
                <span className="text-sm text-white/60">{FEATURED_STORY.date}</span>
              </div>
              <h3 className="text-xl font-bold mb-3 leading-snug">{FEATURED_STORY.title}</h3>
              <p className="text-sm text-white/80 leading-relaxed mb-4">{FEATURED_STORY.excerpt}</p>
              <a href="#" className="inline-flex items-center gap-1.5 text-sm font-medium text-valdoria-gold hover:text-white transition-colors">
                Read full announcement
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </a>
            </div>
          </div>

          {/* Latest News */}
          <div>
            <h2 className="text-xs font-semibold text-valdoria-navy uppercase tracking-widest mb-4">
              Latest News
            </h2>
            <div className="grid gap-4 sm:grid-cols-2">
              {NEWS_ITEMS.map((item) => (
                <a
                  key={item.title}
                  href="#"
                  className="govt-card group block hover:border-valdoria-navy/20 transition-colors"
                >
                  <div className="flex items-center gap-2 mb-2">
                    <span
                      className={`text-xs font-medium px-2 py-0.5 rounded ${
                        CATEGORY_COLORS[item.category] ?? "bg-gray-100 text-gray-600"
                      }`}
                    >
                      {item.category}
                    </span>
                    <span className="text-xs text-gray-400">{item.date}</span>
                  </div>
                  <h3 className="font-semibold text-gray-900 group-hover:text-valdoria-navy transition-colors text-sm leading-snug mb-1">
                    {item.title}
                  </h3>
                  <p className="text-xs text-gray-500 leading-relaxed line-clamp-2">{item.excerpt}</p>
                </a>
              ))}
            </div>
          </div>
        </div>

        {/* Sidebar */}
        <div className="mt-8 lg:mt-0 space-y-6">
          {/* Minister's Activities */}
          <div className="govt-card">
            <h2 className="text-sm font-semibold text-valdoria-navy uppercase tracking-wider mb-4">
              Minister&#39;s Activities
            </h2>
            <ul className="space-y-4">
              {MINISTER_ACTIVITIES.map((activity) => (
                <li key={activity.text} className="flex gap-3">
                  <div className="flex-shrink-0 mt-0.5">
                    <div className="w-1.5 h-1.5 rounded-full bg-valdoria-gold mt-1.5"></div>
                  </div>
                  <div>
                    <p className="text-sm text-gray-700 leading-snug">{activity.text}</p>
                    <span className="text-xs text-gray-400">{activity.date}</span>
                  </div>
                </li>
              ))}
            </ul>
          </div>

          {/* Media Resources */}
          <div className="govt-card">
            <h2 className="text-sm font-semibold text-valdoria-navy uppercase tracking-wider mb-4">
              Media Resources
            </h2>
            <ul className="space-y-2">
              {[
                {
                  label: "Photo Gallery",
                  icon: (
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                  ),
                },
                {
                  label: "Press Releases",
                  icon: (
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  ),
                },
                {
                  label: "Media Contact",
                  icon: (
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  ),
                },
              ].map((res) => (
                <li key={res.label}>
                  <a
                    href="#"
                    className="flex items-center gap-2.5 text-sm text-gray-700 hover:text-valdoria-navy transition-colors py-1"
                  >
                    <svg className="w-4 h-4 text-valdoria-navy/60 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      {res.icon}
                    </svg>
                    {res.label}
                    <svg className="w-3 h-3 ml-auto text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                    </svg>
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Subscribe */}
          <div className="bg-valdoria-cream border border-valdoria-gold/30 rounded-lg p-4">
            <h2 className="text-sm font-semibold text-valdoria-navy mb-1">
              Press Subscription
            </h2>
            <p className="text-xs text-gray-600 mb-3">
              Subscribe to receive official press releases by email.
            </p>
            <a href="#" className="govt-btn-primary text-sm w-full justify-center flex">
              Subscribe
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
