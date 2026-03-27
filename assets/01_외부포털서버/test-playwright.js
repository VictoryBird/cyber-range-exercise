const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

  const BASE = 'http://host.docker.internal';
  const API = 'http://host.docker.internal:8000';
  const SHOTS = '/screenshots';

  console.log('=== 외부 포털 서버 Playwright 테스트 시작 ===\n');

  // 1. 메인 페이지
  console.log('[1/8] 메인 페이지...');
  await page.goto(BASE, { waitUntil: 'load', timeout: 20000 });
  await page.screenshot({ path: `${SHOTS}/01_home.png`, fullPage: true });
  console.log('  ✅ 스크린샷: 01_home.png');

  // 2. 공지사항 목록
  console.log('[2/8] 공지사항 목록...');
  await page.goto(`${BASE}/notices`, { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/02_notices.png`, fullPage: true });
  console.log('  ✅ 스크린샷: 02_notices.png');

  // 3. 공지사항 상세
  console.log('[3/8] 공지사항 상세...');
  await page.goto(`${BASE}/notices/1`, { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/03_notice_detail.png`, fullPage: true });
  console.log('  ✅ 스크린샷: 03_notice_detail.png');

  // 4. 검색
  console.log('[4/8] 검색 페이지...');
  await page.goto(`${BASE}/search`, { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/04_search.png`, fullPage: true });
  console.log('  ✅ 스크린샷: 04_search.png');

  // 5. 민원 조회
  console.log('[5/8] 민원 조회...');
  await page.goto(`${BASE}/inquiry`, { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/05_inquiry.png`, fullPage: true });
  console.log('  ✅ 스크린샷: 05_inquiry.png');

  // 6. 숨겨진 로그인 페이지
  console.log('[6/8] [취약] 숨겨진 로그인...');
  await page.goto(`${BASE}/login`, { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/06_hidden_login.png`, fullPage: true });
  console.log('  ✅ 스크린샷: 06_hidden_login.png');

  // 7. Swagger UI
  console.log('[7/8] [취약] Swagger UI...');
  await page.goto(`${API}/docs`, { waitUntil: 'load', timeout: 20000 });
  await page.screenshot({ path: `${SHOTS}/07_swagger.png`, fullPage: true });
  console.log('  ✅ 스크린샷: 07_swagger.png');

  // 8. API 직접 접근 (내부 설정 노출)
  console.log('[8/8] [취약] 내부 설정 API...');
  await page.goto(`${API}/api/internal/config`, { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/08_internal_config.png`, fullPage: true });
  console.log('  ✅ 스크린샷: 08_internal_config.png');

  await browser.close();
  console.log('\n=== 전체 테스트 완료! 스크린샷 8장 생성 ===');
})();
