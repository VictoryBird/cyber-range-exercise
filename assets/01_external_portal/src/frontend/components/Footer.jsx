import Link from "next/link";

export default function Footer() {
  return (
    <footer className="bg-valdoria-navy-dark text-white mt-auto">
      {/* Main footer */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
          {/* Agency info */}
          <div className="lg:col-span-2">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-full border-2 border-valdoria-gold flex items-center justify-center bg-valdoria-navy">
                <span className="text-valdoria-gold font-bold text-sm">V</span>
              </div>
              <div>
                <div className="text-xs tracking-widest uppercase text-valdoria-gold-light/70">
                  Republic of Valdoria
                </div>
                <div className="font-semibold text-sm">
                  Ministry of Interior and Safety
                </div>
              </div>
            </div>
            <p className="text-gray-400 text-sm leading-relaxed max-w-md">
              The Ministry of Interior and Safety oversees domestic
              administration, public safety, disaster management, and
              e-government services for the citizens of the Republic of
              Valdoria.
            </p>
          </div>

          {/* Quick links */}
          <div>
            <h3 className="text-sm font-semibold uppercase tracking-wider text-valdoria-gold mb-4">
              Quick Links
            </h3>
            <ul className="space-y-2 text-sm">
              <li>
                <Link
                  href="/notices"
                  className="text-gray-400 hover:text-white transition-colors"
                >
                  Notice Board
                </Link>
              </li>
              <li>
                <Link
                  href="/services"
                  className="text-gray-400 hover:text-white transition-colors"
                >
                  Civil Services
                </Link>
              </li>
              <li>
                <Link
                  href="/search"
                  className="text-gray-400 hover:text-white transition-colors"
                >
                  Search
                </Link>
              </li>
              <li>
                <Link
                  href="/egovernment"
                  className="text-gray-400 hover:text-white transition-colors"
                >
                  E-Government Services
                </Link>
              </li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h3 className="text-sm font-semibold uppercase tracking-wider text-valdoria-gold mb-4">
              Contact
            </h3>
            <ul className="space-y-2.5 text-sm text-gray-400">
              <li className="flex items-start gap-2">
                <svg
                  className="w-4 h-4 mt-0.5 text-valdoria-gold/60 flex-shrink-0"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={1.5}
                    d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                  />
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={1.5}
                    d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
                <span>
                  47 Constitution Avenue
                  <br />
                  Elaris, Republic of Valdoria
                </span>
              </li>
              <li className="flex items-center gap-2">
                <svg
                  className="w-4 h-4 text-valdoria-gold/60 flex-shrink-0"
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
              </li>
              <li className="flex items-center gap-2">
                <svg
                  className="w-4 h-4 text-valdoria-gold/60 flex-shrink-0"
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
                <span>contact@mois.gov.vd</span>
              </li>
            </ul>
          </div>
        </div>
      </div>

      {/* Bottom bar */}
      <div className="border-t border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-gray-500">
            <p>&copy; 2026 Republic of Valdoria. All rights reserved.</p>
            <div className="flex items-center gap-4">
              <Link href="/terms" className="hover:text-gray-300 transition-colors">
                Terms of Use
              </Link>
              <span className="text-gray-700">|</span>
              <Link href="/privacy" className="hover:text-gray-300 transition-colors">
                Privacy Policy
              </Link>
              <span className="text-gray-700">|</span>
              <Link href="/sitemap-page" className="hover:text-gray-300 transition-colors">
                Sitemap
              </Link>
              <span className="text-gray-700">|</span>
              <Link href="/accessibility" className="hover:text-gray-300 transition-colors">
                Accessibility
              </Link>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}
