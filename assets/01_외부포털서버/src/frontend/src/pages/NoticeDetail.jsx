import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../api';
import Breadcrumb from '../components/Breadcrumb';

export default function NoticeDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [notice, setNotice] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    // [취약점] 디버그 로그로 요청 ID가 콘솔에 노출됨
    console.log(`[DEBUG] NoticeDetail: fetching notice id=${id}`);
    setLoading(true);
    setError(null);

    api.get(`/api/notices/${id}`)
      .then((res) => {
        console.log('[DEBUG] NoticeDetail: response:', res.data);
        setNotice(res.data);
      })
      .catch((err) => {
        console.error('[DEBUG] NoticeDetail Error:', err);
        setError('공지사항을 찾을 수 없습니다.');
      })
      .finally(() => setLoading(false));
  }, [id]);

  // 로딩 상태
  if (loading) {
    return (
      <div className="text-center py-20">
        <div className="loading-spinner mb-4"></div>
        <p className="text-gray-400">로딩 중...</p>
      </div>
    );
  }

  // 에러 상태
  if (error) {
    return (
      <div className="max-w-6xl mx-auto px-4 py-6">
        <Breadcrumb items={[
          { label: '홈', to: '/' },
          { label: '공지사항', to: '/notices' },
          { label: '상세보기' }
        ]} />
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg p-4 my-8">
          <p className="font-medium">오류가 발생했습니다</p>
          <p className="text-sm mt-1">{error}</p>
        </div>
        <button
          onClick={() => navigate('/notices')}
          className="px-6 py-2 bg-[#1a5276] text-white rounded hover:bg-[#154360]"
        >
          &lt; 목록
        </button>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto px-4 py-6">
      <Breadcrumb items={[
        { label: '홈', to: '/' },
        { label: '공지사항', to: '/notices' },
        { label: '상세보기' }
      ]} />

      {/* 공지사항 상세 */}
      <div className="border-t-2 border-[#1a5276] mt-4">
        {/* 제목 */}
        <h1 className="text-xl font-bold py-4 px-4 bg-gray-50 border-b">
          {notice.title}
        </h1>

        {/* 메타 정보 */}
        <div className="flex flex-wrap gap-x-8 gap-y-2 py-3 px-4 text-sm text-gray-600 border-b bg-gray-50">
          <span>작성자: {notice.author}</span>
          <span>등록일: {notice.created_at?.slice(0, 10)}</span>
          <span>카테고리: {notice.category}</span>
          {notice.views !== undefined && (
            <span>조회수: {notice.views?.toLocaleString()}</span>
          )}
        </div>

        {/* 본문 */}
        <div className="py-8 px-4 min-h-[300px] leading-relaxed whitespace-pre-wrap border-b">
          {notice.content}
        </div>

        {/* 첨부파일 */}
        {notice.attachments?.length > 0 && (
          <div className="border-b py-3 px-4 bg-gray-50">
            <span className="font-medium text-sm">첨부파일:</span>
            {notice.attachments.map((file, i) => (
              <a
                key={i}
                href={file.url}
                className="ml-3 text-sm text-[#1a5276] underline hover:text-[#154360]"
              >
                {file.name}
              </a>
            ))}
          </div>
        )}
      </div>

      {/* 목록 버튼 */}
      <div className="mt-6">
        <button
          onClick={() => navigate('/notices')}
          className="px-6 py-2 bg-[#1a5276] text-white rounded hover:bg-[#154360]"
        >
          &lt; 목록
        </button>
      </div>
    </div>
  );
}
