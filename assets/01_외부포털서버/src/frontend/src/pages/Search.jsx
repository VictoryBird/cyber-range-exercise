import { useState, useEffect } from 'react';
import { useSearchParams, Link } from 'react-router-dom';
import api from '../api';
import Breadcrumb from '../components/Breadcrumb';
import Pagination from '../components/Pagination';

export default function Search() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [results, setResults] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [inputValue, setInputValue] = useState('');

  const query = searchParams.get('q') || '';
  const page = parseInt(searchParams.get('page') || '1');

  useEffect(() => {
    setInputValue(query);
    if (!query) return;

    setLoading(true);
    // [취약점] 검색어와 페이지 정보가 콘솔에 노출됨
    console.log(`[DEBUG] Search: query="${query}", page=${page}`);

    api.get('/api/search', { params: { q: query, page, size: 10 } })
      .then((res) => {
        console.log('[DEBUG] Search results:', res.data);
        setResults(res.data.items || []);
        setTotal(res.data.total || 0);
      })
      .catch((err) => {
        console.error('[DEBUG] Search API Error:', err);
        setResults([]);
        setTotal(0);
      })
      .finally(() => setLoading(false));
  }, [query, page]);

  // 검색 실행
  const handleSearch = (e) => {
    e.preventDefault();
    if (inputValue.trim()) {
      setSearchParams({ q: inputValue.trim(), page: '1' });
    }
  };

  // 검색어 하이라이트 처리
  const highlightQuery = (text) => {
    if (!query || !text) return text;
    const regex = new RegExp(`(${query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi');
    return text.replace(regex, '<strong class="text-[#1a5276]">$1</strong>');
  };

  // 페이지 변경
  const handlePageChange = (newPage) => {
    setSearchParams({ q: query, page: String(newPage) });
  };

  return (
    <div className="max-w-6xl mx-auto px-4 py-6">
      <Breadcrumb items={[{ label: '홈', to: '/' }, { label: '통합검색' }]} />

      <h1 className="text-2xl font-bold text-[#1a5276] border-b-2 border-[#1a5276] pb-3 mb-6">
        통합검색
      </h1>

      {/* 검색 입력 */}
      <form onSubmit={handleSearch} className="flex gap-2 mb-6">
        <input
          type="text"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          className="flex-1 border-2 border-gray-300 rounded px-4 py-3 text-lg
                     focus:border-[#1a5276] focus:outline-none"
          placeholder="검색어를 입력하세요"
        />
        <button
          type="submit"
          className="px-8 py-3 bg-[#1a5276] text-white rounded text-lg hover:bg-[#154360]"
        >
          검색
        </button>
      </form>

      {/* 검색 결과 요약 */}
      {query && (
        <p className="mb-4 text-gray-600">
          검색 결과 총 <strong>{total}</strong>건 (검색어: &ldquo;{query}&rdquo;)
        </p>
      )}

      {/* 로딩 상태 */}
      {loading && (
        <div className="text-center py-20">
          <div className="loading-spinner mb-4"></div>
          <p className="text-gray-400">검색 중...</p>
        </div>
      )}

      {/* 검색 결과 목록 */}
      {!loading && query && (
        <>
          {results.length === 0 ? (
            <div className="text-center py-12 text-gray-400">
              <p>&ldquo;{query}&rdquo;에 대한 검색 결과가 없습니다.</p>
            </div>
          ) : (
            <div className="space-y-4">
              {results.map((item) => (
                <Link
                  key={item.id}
                  to={item.url || `/notices/${item.id}`}
                  className="block border rounded-lg p-4 hover:bg-gray-50 hover:border-[#1a5276] transition-colors"
                >
                  {/* 유형 배지 */}
                  <span className="text-xs text-[#1a5276] bg-blue-50 px-2 py-0.5 rounded">
                    {item.type || '공지사항'}
                  </span>

                  {/* 제목 */}
                  <h3
                    className="text-base font-medium text-gray-800 mt-2"
                    dangerouslySetInnerHTML={{ __html: highlightQuery(item.title) }}
                  />

                  {/* 본문 스니펫 */}
                  {item.snippet && (
                    <p
                      className="text-sm text-gray-500 mt-1 line-clamp-2"
                      dangerouslySetInnerHTML={{ __html: highlightQuery(item.snippet) }}
                    />
                  )}

                  {/* 날짜 */}
                  <p className="text-xs text-gray-400 mt-2">
                    {item.created_at?.slice(0, 10)}
                  </p>
                </Link>
              ))}
            </div>
          )}

          {/* 페이지네이션 */}
          <Pagination
            current={page}
            total={Math.ceil(total / 10)}
            onChange={handlePageChange}
          />
        </>
      )}

      {/* 검색어 미입력 시 안내 */}
      {!query && !loading && (
        <div className="text-center py-12 text-gray-400">
          <p>검색어를 입력하세요.</p>
        </div>
      )}
    </div>
  );
}
