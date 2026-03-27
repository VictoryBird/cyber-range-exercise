import { useState } from 'react';
import api from '../api';
import Breadcrumb from '../components/Breadcrumb';

// 처리 상태 배지 컴포넌트
function StatusBadge({ status }) {
  const styles = {
    '접수': 'bg-gray-200 text-gray-700',
    '처리중': 'bg-blue-100 text-blue-700',
    '완료': 'bg-green-100 text-green-700',
    '반려': 'bg-red-100 text-red-700',
  };

  return (
    <span className={`px-3 py-1 rounded-full text-sm font-medium ${styles[status] || styles['접수']}`}>
      {status}
    </span>
  );
}

export default function Inquiry() {
  const [trackingNumber, setTrackingNumber] = useState('');
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = (e) => {
    e.preventDefault();

    // 클라이언트 입력 검증
    if (!trackingNumber.trim()) {
      setError('접수번호를 입력해 주세요.');
      return;
    }

    setLoading(true);
    setError(null);
    setResult(null);

    // [취약점] 민원 접수번호가 콘솔에 노출됨
    console.log(`[DEBUG] Inquiry: tracking_number=${trackingNumber}`);

    api.get(`/api/inquiry/${trackingNumber.trim()}`)
      .then((res) => {
        console.log('[DEBUG] Inquiry result:', res.data);
        setResult(res.data);
      })
      .catch((err) => {
        console.error('[DEBUG] Inquiry Error:', err);
        if (err.response?.status === 404) {
          setError('해당 접수번호의 민원을 찾을 수 없습니다. 접수번호를 다시 확인해 주세요.');
        } else {
          setError('조회 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');
        }
      })
      .finally(() => setLoading(false));
  };

  return (
    <div className="max-w-4xl mx-auto px-4 py-6">
      <Breadcrumb items={[{ label: '홈', to: '/' }, { label: '민원조회' }]} />

      <h1 className="text-2xl font-bold text-[#1a5276] border-b-2 border-[#1a5276] pb-3 mb-6">
        민원 처리 상태 조회
      </h1>

      {/* 접수번호 입력 폼 */}
      <div className="bg-gray-50 border rounded-lg p-6 mb-6">
        <p className="text-gray-600 mb-2">
          민원 접수번호를 입력하여 처리 상태를 확인하세요.
        </p>
        <p className="text-sm text-gray-500 mb-4">
          접수번호 형식: INQ-YYYYMMDD-XXXX (예: INQ-20260315-0042)
        </p>
        <form onSubmit={handleSubmit} className="flex gap-2">
          <input
            type="text"
            value={trackingNumber}
            onChange={(e) => setTrackingNumber(e.target.value)}
            placeholder="INQ-YYYYMMDD-XXXX"
            className="flex-1 border-2 border-gray-300 rounded px-4 py-2
                       focus:border-[#1a5276] focus:outline-none"
          />
          <button
            type="submit"
            disabled={loading}
            className="px-6 py-2 bg-[#1a5276] text-white rounded hover:bg-[#154360]
                       disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? '조회 중...' : '조회'}
          </button>
        </form>
      </div>

      {/* 에러 메시지 */}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg p-4 mb-6">
          <div className="flex items-start gap-2">
            <span className="text-lg">!</span>
            <div>
              <p className="font-medium">{error}</p>
            </div>
          </div>
        </div>
      )}

      {/* 조회 결과 */}
      {result && (
        <div className="border rounded-lg overflow-hidden">
          <div className="bg-[#1a5276] text-white px-4 py-3">
            <h2 className="font-bold">민원 처리 상태</h2>
          </div>
          <table className="w-full">
            <tbody>
              <tr className="border-b">
                <td className="px-4 py-3 bg-gray-50 font-medium text-sm w-32">접수번호</td>
                <td className="px-4 py-3 text-sm">{result.tracking_number}</td>
              </tr>
              <tr className="border-b">
                <td className="px-4 py-3 bg-gray-50 font-medium text-sm">민원제목</td>
                <td className="px-4 py-3 text-sm">{result.title}</td>
              </tr>
              <tr className="border-b">
                <td className="px-4 py-3 bg-gray-50 font-medium text-sm">처리상태</td>
                <td className="px-4 py-3 text-sm">
                  <StatusBadge status={result.status} />
                </td>
              </tr>
              <tr className="border-b">
                <td className="px-4 py-3 bg-gray-50 font-medium text-sm">접수일시</td>
                <td className="px-4 py-3 text-sm">{result.created_at}</td>
              </tr>
              <tr>
                <td className="px-4 py-3 bg-gray-50 font-medium text-sm">담당부서</td>
                <td className="px-4 py-3 text-sm">{result.department}</td>
              </tr>
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
