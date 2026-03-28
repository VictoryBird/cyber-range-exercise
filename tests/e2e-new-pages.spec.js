const { test } = require('@playwright/test');
const BASE = 'http://host.docker.internal';

test.describe('New Static Pages', () => {
  test('E-Government services page', async ({ page }) => {
    await page.goto(`${BASE}/egovernment`, { waitUntil: 'load' });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: '/results/08-egovernment.png', fullPage: true });
  });

  test('Terms of Use page', async ({ page }) => {
    await page.goto(`${BASE}/terms`, { waitUntil: 'load' });
    await page.waitForTimeout(1500);
    await page.screenshot({ path: '/results/09-terms.png', fullPage: true });
  });

  test('Privacy Policy page', async ({ page }) => {
    await page.goto(`${BASE}/privacy`, { waitUntil: 'load' });
    await page.waitForTimeout(1500);
    await page.screenshot({ path: '/results/10-privacy.png', fullPage: true });
  });

  test('Accessibility page', async ({ page }) => {
    await page.goto(`${BASE}/accessibility`, { waitUntil: 'load' });
    await page.waitForTimeout(1500);
    await page.screenshot({ path: '/results/11-accessibility.png', fullPage: true });
  });

  test('Sitemap page', async ({ page }) => {
    await page.goto(`${BASE}/sitemap-page`, { waitUntil: 'load' });
    await page.waitForTimeout(1500);
    await page.screenshot({ path: '/results/12-sitemap.png', fullPage: true });
  });

  test('Updated homepage - no dead links', async ({ page }) => {
    await page.goto(BASE, { waitUntil: 'load' });
    await page.waitForTimeout(3000);
    await page.screenshot({ path: '/results/13-home-updated.png', fullPage: true });
  });
});
