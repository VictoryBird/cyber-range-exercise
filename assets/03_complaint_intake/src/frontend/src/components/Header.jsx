import { Link, NavLink } from 'react-router-dom'

export default function Header() {
  const navItems = [
    { to: '/', label: 'Home', end: true },
    { to: '/submit', label: 'Submit Complaint' },
    { to: '/status', label: 'Track Status' },
    { to: '/faq', label: 'FAQ' },
  ]

  return (
    <header className="bg-gov-navy text-white shadow-md">
      {/* Top bar */}
      <div className="bg-gov-navy-dark border-b border-gov-navy-light">
        <div className="max-w-6xl mx-auto px-4 py-1.5 flex items-center justify-between text-xs text-gray-300">
          <span>Ministry of the Interior and Safety — Valdoria</span>
          <span>Official Government Portal</span>
        </div>
      </div>

      {/* Main header */}
      <div className="max-w-6xl mx-auto px-4 py-4 flex items-center gap-6">
        {/* Logo / wordmark */}
        <Link to="/" className="flex items-center gap-3 group flex-shrink-0">
          <div className="w-12 h-12 bg-gov-gold rounded flex items-center justify-center shadow">
            <svg viewBox="0 0 48 48" fill="none" className="w-8 h-8" aria-hidden="true">
              <rect x="4" y="20" width="40" height="24" rx="2" fill="#1B2A4A" />
              <rect x="8" y="16" width="32" height="8" rx="1" fill="#1B2A4A" />
              <polygon points="24,4 44,18 4,18" fill="#1B2A4A" />
              <rect x="18" y="28" width="12" height="16" rx="1" fill="#D4A843" />
            </svg>
          </div>
          <div>
            <div className="text-base font-bold leading-tight group-hover:text-gov-gold transition-colors">
              Valdoria MOIS
            </div>
            <div className="text-xs text-gray-300 leading-tight">
              발도리아 행정안전부 전자민원
            </div>
          </div>
        </Link>

        {/* Title */}
        <div className="hidden md:block flex-1 text-center">
          <h1 className="text-lg font-semibold tracking-wide">
            Electronic Complaint Portal
          </h1>
          <p className="text-xs text-gov-gold">전자민원 접수 시스템</p>
        </div>

        {/* Navigation */}
        <nav className="flex items-center gap-1 ml-auto">
          {navItems.map(({ to, label, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                `px-3 py-1.5 text-sm rounded transition-colors ${
                  isActive
                    ? 'bg-gov-gold text-gov-navy font-semibold'
                    : 'text-gray-200 hover:text-white hover:bg-gov-navy-light'
                }`
              }
            >
              {label}
            </NavLink>
          ))}
        </nav>
      </div>
    </header>
  )
}
