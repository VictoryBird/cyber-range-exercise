import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import api from '../api';
import SearchBar from '../components/SearchBar';

// 히어로 배너 컴포넌트
function HeroBanner() {
  return (
    <div className="bg-gradient-to-r from-[#1a5276] to-[#2c3e50] text-white py-16">
      <div className="max-w-6xl mx-auto px-4 text-center">
        <h1 className="text-3xl md:text-4xl font-bold mb-4">
          발도리아 행정안전부
        </h1>
        <p className="text-lg md:text-xl opacity-90 mb-2">
          Ministry of the Interior and Safety
        </p>
        <p className="text-base opacity-80 mt-6">
          &ldquo;국민과 함께하는 안전한 발도리아&rdquo;
        </p>
        <div className="max-w-xl mx-auto mt-8">
          <SearchBar placeholder="통합검색어를 입력하세요" />
        </div>
      </div>
    </div>
  );
}

// 최근 공지사항 컴포넌트
function RecentNotices({ notices, loading }) {
  return (
    <div className="card">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold text-[#1a5276]">최근 공지사항</h2>
        <Link to="/notices" className="text-sm text-[#1a5276] hover:underline">
          더보기 &gt;
        </Link>
      </div>

      {loading ? (
        <div className="text-center py-8">
          <div className="loading-spinner mb-4"></div>
          <p className="text-gray-400">로딩 중...</p>
        </div>
      ) : notices.length === 0 ? (
        <div className="text-center py-8 text-gray-400">
          <p>등록된 공지사항이 없습니다.</p>
        </div>
      ) : (
        <ul className="divide-y">
          {notices.map((notice) => (
            <li key={notice.id}>
              <Link
                to={`/notices/${notice.id}`}
                className="flex items-center justify-between py-3 hover:bg-gray-50 px-2 -mx-2 rounded transition-colors"
              >
                <span className="text-sm text-gray-800 hover:text-[#1a5276] truncate mr-4">
                  {notice.category && (
                    <span className="text-xs text-[#1a5276] bg-blue-50 px-2 py-0.5 rounded mr-2">
                      {notice.category}
                    </span>
                  )}
                  {notice.title}
                </span>
                <span className="text-xs text-gray-400 whitespace-nowrap">
                  {notice.created_at?.slice(0, 10)}
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

// 빠른 서비스 컴포넌트
function QuickLinks() {
  const links = [
    { label: '민원 조회', to: '/inquiry', icon: '📋' },
    { label: '공지사항', to: '/notices', icon: '📢' },
    { label: '정보공개 청구', to: '#', icon: '📄' },
    { label: '법령정보', to: '#', icon: '⚖️' },
  ];

  return (
    <div className="card">
      <h2 className="text-xl font-bold text-[#1a5276] mb-4">빠른 서비스</h2>
      <div className="space-y-3">
        {links.map((link) => (
          <Link
            key={link.label}
            to={link.to}
            className="flex items-center gap-3 p-3 rounded-lg border border-gray-200
                       hover:bg-[#1a5276] hover:text-white hover:border-[#1a5276]
                       transition-colors group"
          >
            <span className="text-2xl">{link.icon}</span>
            <span className="text-sm font-medium">{link.label}</span>
          </Link>
        ))}
      </div>
    </div>
  );
}

// 주요 정책 배너 컴포넌트
function PolicyBanner() {
  const banners = [
    { title: '디지털정부', desc: '전자정부 혁신으로 국민 편의 증진', color: 'from-blue-600 to-blue-800' },
    { title: '재난안전', desc: '국민 안전을 위한 재난관리 체계 강화', color: 'from-teal-600 to-teal-800' },
    { title: '지방자치', desc: '지방분권과 균형발전 추진', color: 'from-indigo-600 to-indigo-800' },
  ];

  return (
    <div className="bg-gray-50 py-8">
      <div className="max-w-6xl mx-auto px-4">
        <h2 className="text-xl font-bold text-[#1a5276] mb-6">주요 정책</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {banners.map((banner) => (
            <div
              key={banner.title}
              className={`bg-gradient-to-r ${banner.color} text-white rounded-lg p-6 cursor-pointer
                         hover:shadow-lg transition-shadow`}
            >
              <h3 className="text-lg font-bold mb-2">{banner.title}</h3>
              <p className="text-sm opacity-90">{banner.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// 메인 페이지 컴포넌트
export default function Home() {
  const [notices, setNotices] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    // [취약점] 디버그 로그가 프로덕션에서도 출력됨
    console.log('[DEBUG] Home: fetching recent notices from API');
    api.get('/api/notices', { params: { page: 1, size: 5 } })
      .then((res) => {
        console.log('[DEBUG] Home: API response:', res.data);
        setNotices(res.data.items || []);
      })
      .catch((err) => {
        console.error('[DEBUG] API Error:', err);
        // API 연결 실패 시 빈 목록 표시
        setNotices([]);
      })
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      {/* 히어로 배너 */}
      <HeroBanner />

      {/* 최근 공지사항 + 빠른 서비스 */}
      <div className="max-w-6xl mx-auto px-4 py-8 grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2">
          <RecentNotices notices={notices} loading={loading} />
        </div>
        <div>
          <QuickLinks />
        </div>
      </div>

      {/* 주요 정책 배너 */}
      <PolicyBanner />
    </div>
  );
}
