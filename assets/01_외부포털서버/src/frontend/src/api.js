import axios from 'axios';

// [취약점] API base URL이 소스 코드에 하드코딩됨
// 공격자가 빌드된 JS 번들을 분석하면 API 서버 주소와 엔드포인트를 확인할 수 있음
// 프로덕션에서는 환경변수를 사용해야 하지만, 여기서는 직접 하드코딩되어 있음
const API_BASE_URL = 'http://203.238.140.10:8000';

// [취약점] 프로덕션 빌드에서도 디버그 로그가 남아있음
// 브라우저 콘솔에서 API 서버 주소가 노출됨
console.log('[DEBUG] API Base URL:', API_BASE_URL);
console.log('[DEBUG] API module loaded at:', new Date().toISOString());

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
  // [취약점] CSRF 토큰 미적용 - withCredentials도 미설정
});

// 요청 인터셉터
// [취약점] 모든 API 요청 정보가 브라우저 콘솔에 출력됨
api.interceptors.request.use(
  (config) => {
    // [취약점] 요청 URL, 메서드, 파라미터가 콘솔에 노출
    console.log(`[DEBUG] API Request: ${config.method?.toUpperCase()} ${config.url}`, config.params);
    return config;
  },
  (error) => {
    console.error('[DEBUG] API Request Error:', error);
    return Promise.reject(error);
  }
);

// 응답 인터셉터
// [취약점] 모든 API 응답 데이터가 브라우저 콘솔에 출력됨
api.interceptors.response.use(
  (response) => {
    // [취약점] 응답 상태 코드와 전체 응답 데이터가 콘솔에 노출
    console.log(`[DEBUG] API Response: ${response.status}`, response.data);
    return response;
  },
  (error) => {
    // [취약점] 에러 응답의 상세 정보(상태 코드, 에러 데이터, URL)가 콘솔에 노출
    console.error('[DEBUG] API Response Error:', {
      status: error.response?.status,
      data: error.response?.data,
      url: error.config?.url,
    });
    return Promise.reject(error);
  }
);

export default api;
