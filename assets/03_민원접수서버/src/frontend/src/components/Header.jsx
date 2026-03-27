import { Link, useLocation } from 'react-router-dom'

const NAV = [
  { to: '/', label: '홈' },
  { to: '/submit', label: '민원접수' },
  { to: '/status', label: '처리현황' },
]

export default function Header() {
  const { pathname } = useLocation()

  return (
    <header className="bg-gov-700 text-white shadow-lg">
      <div className="max-w-6xl mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          <Link to="/" className="flex items-center gap-3">
            <div className="w-9 h-9 bg-amber-500 rounded-full flex items-center justify-center text-gov-900 font-bold text-sm">V</div>
            <div>
              <div className="font-bold text-lg leading-tight">발도리아 행정안전부</div>
              <div className="text-gov-200 text-xs">민원포털</div>
            </div>
          </Link>
          <nav className="flex gap-1">
            {NAV.map(({ to, label }) => (
              <Link
                key={to}
                to={to}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  pathname === to
                    ? 'bg-gov-800 text-white'
                    : 'text-gov-100 hover:bg-gov-600'
                }`}
              >
                {label}
              </Link>
            ))}
          </nav>
        </div>
      </div>
    </header>
  )
}
