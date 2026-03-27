const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  const BASE = 'http://host.docker.internal:8880';
  const SHOTS = '/screenshots';

  console.log('=== D1 군 외부 포털 Playwright 테스트 ===\n');

  console.log('[1/5] 메인 페이지...');
  await page.goto(BASE, { waitUntil: 'load', timeout: 20000 });
  await page.screenshot({ path: `${SHOTS}/01_main.png`, fullPage: true });
  console.log('  ✅ 01_main.png');

  console.log('[2/5] 공지사항 목록...');
  await page.goto(`${BASE}/notice.html`, { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/02_notice.png`, fullPage: true });
  console.log('  ✅ 02_notice.png');

  console.log('[3/5] 공지사항 상세...');
  await page.goto(`${BASE}/notice_view.html?id=1`, { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/03_notice_detail.png`, fullPage: true });
  console.log('  ✅ 03_notice_detail.png');

  console.log('[4/5] 검색 (Spring4Shell 진입점)...');
  await page.goto(`${BASE}/search.html`, { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/04_search.png`, fullPage: true });
  console.log('  ✅ 04_search.png');

  console.log('[5/5] 연락처...');
  await page.goto(`${BASE}/contact.html`, { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/05_contact.png`, fullPage: true });
  console.log('  ✅ 05_contact.png');

  await browser.close();
  console.log('\n=== 완료! 5장 생성 ===');
})();
