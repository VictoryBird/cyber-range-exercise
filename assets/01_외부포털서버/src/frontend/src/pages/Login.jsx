import { useState } from 'react';

// [취약점] 숨겨진 관리자 로그인 페이지
// 이 페이지는 내비게이션 메뉴에 노출되지 않으며, URL 직접 입력(/login)으로만 접근 가능
// Security through obscurity: JS 번들 분석 시 라우터 설정에서 /login 경로 발견 가능
// 이 페이지의 존재 자체가 /api/admin/* 엔드포인트의 힌트로 작용함

export default function Login() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    // [취약점] 입력된 계정 정보가 콘솔에 노출됨
    console.log(`[DEBUG] Login attempt: username=${username}, password=${password}`);

    // 실제 로그인 API는 미구현
    // 폼 전송 시 "시스템 점검 중" 메시지만 표시
    setTimeout(() => {
      setLoading(false);
      setError('현재 시스템 점검 중입니다. 잠시 후 다시 시도해 주세요.');
      // [취약점] 에러 메시지에서 관리 API 엔드포인트가 힌트로 노출됨
      console.log('[DEBUG] Admin login endpoint: POST /api/admin/auth/login');
      console.log('[DEBUG] Admin panel: /api/admin/dashboard');
    }, 1500);
  };

  return (
    <div className="min-h-[60vh] flex items-center justify-center py-12 px-4">
      <div className="w-full max-w-md">
        <div className="bg-white border rounded-lg shadow-lg p-8">
          {/* 로고 */}
          <div className="text-center mb-8">
            <div className="w-16 h-16 bg-[#1a5276] rounded-full flex items-center justify-center mx-auto mb-4">
              <span className="text-white font-bold text-2xl">V</span>
            </div>
            <h1 className="text-xl font-bold text-[#1a5276]">관리자 로그인</h1>
            <p className="text-sm text-gray-500 mt-1">발도리아 행정안전부</p>
          </div>

          {/* 로그인 폼 */}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                아이디
              </label>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="관리자 아이디를 입력하세요"
                className="w-full border-2 border-gray-300 rounded px-4 py-2
                           focus:border-[#1a5276] focus:outline-none"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                비밀번호
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="비밀번호를 입력하세요"
                className="w-full border-2 border-gray-300 rounded px-4 py-2
                           focus:border-[#1a5276] focus:outline-none"
                required
              />
            </div>

            {/* 에러 메시지 */}
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 rounded p-3 text-sm">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full py-2.5 bg-[#1a5276] text-white rounded font-medium
                         hover:bg-[#154360] disabled:opacity-50 disabled:cursor-not-allowed
                         transition-colors"
            >
              {loading ? '로그인 중...' : '로그인'}
            </button>
          </form>

          {/* 안내 문구 */}
          <p className="text-center text-xs text-gray-400 mt-6">
            ※ 관리자 전용 페이지입니다.
          </p>
        </div>
      </div>
    </div>
  );
}
