import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

// 내비게이션 메뉴 항목
// [취약점] /login 경로는 의도적으로 내비게이션에 포함하지 않음
// 하지만 빌드된 JS 번들의 라우터 설정에서 /login 경로를 확인할 수 있음
const NAV_ITEMS = [
  { label: '홈', to: '/' },
  { label: '공지사항', to: '/notices' },
  { label: '민원조회', to: '/inquiry' },
  { label: '정보공개', to: '#' },    // 더미 링크 (미구현 페이지)
  { label: '기관소개', to: '#' },    // 더미 링크 (미구현 페이지)
];

export default function Header() {
  const [searchQuery, setSearchQuery] = useState('');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const navigate = useNavigate();

  const handleSearch = (e) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      navigate(`/search?q=${encodeURIComponent(searchQuery.trim())}`);
      setSearchQuery('');
    }
  };

  return (
    <header>
      {/* 상단 메인 바 */}
      <div className="bg-[#1a5276] text-white">
        <div className="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between">
          {/* 로고 및 기관명 */}
          <Link to="/" className="flex items-center gap-3">
            <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center">
              <span className="text-[#1a5276] font-bold text-sm">V</span>
            </div>
            <div>
              <div className="text-lg font-bold">발도리아 행정안전부</div>
              <div className="text-xs opacity-80">
                Ministry of the Interior and Safety
              </div>
            </div>
          </Link>

          {/* 검색바 */}
          <form onSubmit={handleSearch} className="hidden md:flex">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="검색어 입력"
              className="px-3 py-1.5 rounded-l text-gray-800 text-sm w-48 focus:outline-none"
            />
            <button
              type="submit"
              className="px-3 py-1.5 bg-[#154360] rounded-r hover:bg-[#0e2f44] text-sm"
            >
              검색
            </button>
          </form>

          {/* 모바일 메뉴 토글 */}
          <button
            className="md:hidden text-white"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                d={mobileMenuOpen ? "M6 18L18 6M6 6l12 12" : "M4 6h16M4 12h16M4 18h16"} />
            </svg>
          </button>
        </div>
      </div>

      {/* 내비게이션 바 */}
      <nav className="bg-[#f8f9fa] border-b">
        <div className="max-w-6xl mx-auto px-4">
          <ul className={`${mobileMenuOpen ? 'block' : 'hidden'} md:flex`}>
            {NAV_ITEMS.map((item) => (
              <li key={item.label}>
                <Link
                  to={item.to}
                  className="block px-5 py-3 text-sm font-medium text-gray-700
                             hover:text-[#1a5276] hover:bg-gray-100 transition-colors"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      </nav>

      {/* 모바일 검색바 */}
      {mobileMenuOpen && (
        <div className="md:hidden bg-[#f8f9fa] border-b px-4 py-3">
          <form onSubmit={handleSearch} className="flex">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="검색어 입력"
              className="flex-1 px-3 py-1.5 rounded-l text-gray-800 text-sm border focus:outline-none"
            />
            <button
              type="submit"
              className="px-3 py-1.5 bg-[#1a5276] text-white rounded-r text-sm"
            >
              검색
            </button>
          </form>
        </div>
      )}
    </header>
  );
}
