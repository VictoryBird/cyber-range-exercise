import { Link } from 'react-router-dom'

export default function Footer() {
  return (
    <footer className="bg-gov-navy text-gray-300 mt-auto">
      <div className="max-w-6xl mx-auto px-4 py-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-6">
          {/* Organization info */}
          <div>
            <h3 className="text-gov-gold font-semibold text-sm mb-3">
              Ministry of the Interior and Safety
            </h3>
            <p className="text-xs leading-relaxed text-gray-400">
              Government Complex Valdoria, 209 Sejong-daero,<br />
              Jongno-gu, Valdoria Capital District 03171
            </p>
            <p className="text-xs text-gray-400 mt-2">
              Registration No: 000-83-000123
            </p>
          </div>

          {/* Operating hours */}
          <div>
            <h3 className="text-gov-gold font-semibold text-sm mb-3">
              Operating Hours
            </h3>
            <ul className="text-xs space-y-1 text-gray-400">
              <li>Monday – Friday: 09:00 – 18:00</li>
              <li>Saturday, Sunday: Closed</li>
              <li>Public Holidays: Closed</li>
              <li className="text-gray-300 pt-1">
                Online submissions: 24 hours / 365 days
              </li>
            </ul>
          </div>

          {/* Contact & Links */}
          <div>
            <h3 className="text-gov-gold font-semibold text-sm mb-3">
              Contact &amp; Support
            </h3>
            <ul className="text-xs space-y-1 text-gray-400">
              <li>Call Center: 110 (domestic)</li>
              <li>International: +82-2-2100-3399</li>
              <li>Email: mois@valdoria.gov.vl</li>
            </ul>
            <div className="flex gap-4 mt-3 text-xs">
              <Link to="/faq" className="hover:text-gov-gold transition-colors">FAQ</Link>
              <a href="#" className="hover:text-gov-gold transition-colors">Privacy Policy</a>
              <a href="#" className="hover:text-gov-gold transition-colors">Accessibility</a>
            </div>
          </div>
        </div>

        <div className="border-t border-gov-navy-light pt-4 flex flex-col md:flex-row items-center justify-between gap-2 text-xs text-gray-500">
          <p>
            Copyright 2026 Ministry of the Interior and Safety, Valdoria.
            All rights reserved.
          </p>
          <p>
            This is an official government website of the Republic of Valdoria.
          </p>
        </div>
      </div>
    </footer>
  )
}
