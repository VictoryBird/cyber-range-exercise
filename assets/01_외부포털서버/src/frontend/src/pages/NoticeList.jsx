import { useState, useEffect } from 'react';
import { useSearchParams, Link } from 'react-router-dom';
import api from '../api';
import Breadcrumb from '../components/Breadcrumb';
import Pagination from '../components/Pagination';

const CATEGORIES = ['전체', '정책', '보도', '채용', '교육', '일반'];

export default function NoticeList() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [notices, setNotices] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);

  const page = parseInt(searchParams.get('page') || '1');
  const category = searchParams.get('category') || '';
  const size = 10;

  useEffect(() => {
    setLoading(true);
    // [취약점] 디버그 로그가 프로덕션에서도 출력됨
    console.log(`[DEBUG] NoticeList: fetching page=${page}, category=${category}`);

    const params = { page, size };
    if (category) params.category = category;

    api.get('/api/notices', { params })
      .then((res) => {
        console.log('[DEBUG] NoticeList: response:', res.data);
        setNotices(res.data.items || []);
        setTotal(res.data.total || 0);
      })
      .catch((err) => {
        console.error('[DEBUG] NoticeList API Error:', err);
        setNotices([]);
        setTotal(0);
      })
      .finally(() => setLoading(false));
  }, [page, category]);

  // 카테고리 변경 핸들러
  const handleCategoryChange = (cat) => {
    if (cat === '전체') {
      setSearchParams({ page: '1' });
    } else {
      setSearchParams({ page: '1', category: cat });
    }
  };

  // 페이지 변경 핸들러
  const handlePageChange = (newPage) => {
    const params = { page: String(newPage) };
    if (category) params.category = category;
    setSearchParams(params);
  };

  return (
    <div className="max-w-6xl mx-auto px-4 py-6">
      <Breadcrumb items={[{ label: '홈', to: '/' }, { label: '공지사항' }]} />

      <h1 className="text-2xl font-bold text-[#1a5276] border-b-2 border-[#1a5276] pb-3 mb-6">
        공지사항
      </h1>

      {/* 카테고리 필터 */}
      <div className="flex flex-wrap items-center gap-2 mb-6">
        <span className="text-sm font-medium text-gray-600 mr-2">카테고리:</span>
        {CATEGORIES.map((cat) => (
          <button
            key={cat}
            onClick={() => handleCategoryChange(cat)}
            className={`px-3 py-1 text-sm rounded-full border transition-colors
              ${(cat === '전체' && !category) || cat === category
                ? 'bg-[#1a5276] text-white border-[#1a5276]'
                : 'bg-white text-gray-600 border-gray-300 hover:border-[#1a5276] hover:text-[#1a5276]'
              }`}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* 로딩 상태 */}
      {loading && (
        <div className="text-center py-20">
          <div className="loading-spinner mb-4"></div>
          <p className="text-gray-400">로딩 중...</p>
        </div>
      )}

      {/* 공지사항 테이블 */}
      {!loading && (
        <>
          {notices.length === 0 ? (
            <div className="text-center py-12 text-gray-400">
              <p>등록된 공지사항이 없습니다.</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full border-t-2 border-[#1a5276]">
                <thead>
                  <tr className="bg-[#f8f9fa] border-b">
                    <th className="px-4 py-3 text-sm font-medium text-gray-600 text-center w-16">번호</th>
                    <th className="px-4 py-3 text-sm font-medium text-gray-600 text-center w-20">카테고리</th>
                    <th className="px-4 py-3 text-sm font-medium text-gray-600 text-left">제목</th>
                    <th className="px-4 py-3 text-sm font-medium text-gray-600 text-center w-24">등록일</th>
                    <th className="px-4 py-3 text-sm font-medium text-gray-600 text-center w-16">조회</th>
                  </tr>
                </thead>
                <tbody>
                  {notices.map((notice) => (
                    <tr
                      key={notice.id}
                      className="border-b hover:bg-gray-50 transition-colors cursor-pointer"
                    >
                      <td className="px-4 py-3 text-sm text-center text-gray-500">
                        {notice.id}
                      </td>
                      <td className="px-4 py-3 text-sm text-center">
                        <span className="text-xs text-[#1a5276] bg-blue-50 px-2 py-0.5 rounded">
                          {notice.category}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm">
                        <Link
                          to={`/notices/${notice.id}`}
                          className="text-gray-800 hover:text-[#1a5276] hover:underline"
                        >
                          {notice.title}
                        </Link>
                      </td>
                      <td className="px-4 py-3 text-sm text-center text-gray-500">
                        {notice.created_at?.slice(5, 10)}
                      </td>
                      <td className="px-4 py-3 text-sm text-center text-gray-500">
                        {notice.views?.toLocaleString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* 페이지네이션 */}
          <Pagination
            current={page}
            total={Math.ceil(total / size)}
            onChange={handlePageChange}
          />
        </>
      )}
    </div>
  );
}
