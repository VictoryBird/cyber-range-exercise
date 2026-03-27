const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  const BASE = 'http://host.docker.internal';
  const SHOTS = '/screenshots';

  console.log('=== 웹메일 서버 Playwright 테스트 ===\n');

  console.log('[1/3] Roundcube 로그인 페이지 (포트 80)...');
  await page.goto(BASE, { waitUntil: 'load', timeout: 20000 });
  await page.screenshot({ path: `${SHOTS}/01_roundcube_login.png`, fullPage: true });
  console.log('  ✅ 01_roundcube_login.png');

  console.log('[2/3] 프록시용 포트 8080...');
  await page.goto(`${BASE}:8080`, { waitUntil: 'load', timeout: 15000 });
  await page.screenshot({ path: `${SHOTS}/02_roundcube_proxy.png`, fullPage: true });
  console.log('  ✅ 02_roundcube_proxy.png');

  console.log('[3/3] Roundcube 정보 노출 확인...');
  await page.goto(`${BASE}/?_task=utils&_action=health`, { waitUntil: 'load', timeout: 10000 });
  await page.screenshot({ path: `${SHOTS}/03_roundcube_info.png`, fullPage: true });
  console.log('  ✅ 03_roundcube_info.png');

  await browser.close();
  console.log('\n=== 완료! 스크린샷 3장 생성 ===');
})();
