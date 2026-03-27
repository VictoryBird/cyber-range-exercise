const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  const BASE = 'http://host.docker.internal';
  const SHOTS = '/screenshots';

  console.log('=== 민원 접수 서버 Playwright 테스트 ===\n');

  console.log('[1/5] 메인 페이지...');
  await page.goto(BASE, { waitUntil: 'load', timeout: 20000 });
  await page.screenshot({ path: `${SHOTS}/01_home.png`, fullPage: true });
  console.log('  ✅ 01_home.png');

  console.log('[2/5] 민원 접수 페이지...');
  await page.goto(`${BASE}/submit`, { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/02_submit.png`, fullPage: true });
  console.log('  ✅ 02_submit.png');

  console.log('[3/5] 처리현황 조회...');
  await page.goto(`${BASE}/status`, { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/03_status.png`, fullPage: true });
  console.log('  ✅ 03_status.png');

  console.log('[4/5] 민원 상세 조회...');
  await page.goto(`${BASE}/status/COMP-2026-00001`, { waitUntil: 'load', timeout: 15000 });
  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${SHOTS}/04_detail.png`, fullPage: true });
  console.log('  ✅ 04_detail.png');

  console.log('[5/5] MinIO 콘솔...');
  await page.goto('http://host.docker.internal:9001', { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/05_minio.png`, fullPage: true });
  console.log('  ✅ 05_minio.png');

  await browser.close();
  console.log('\n=== 완료! 스크린샷 5장 생성 ===');
})();
