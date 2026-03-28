const { test, expect } = require('@playwright/test');

const BASE = 'http://host.docker.internal';

test.describe('MOIS Portal - Full Stack Tests', () => {

  test('Homepage loads with government header', async ({ page }) => {
    await page.goto(BASE, { waitUntil: 'load' });
    await page.waitForTimeout(3000);
    await expect(page.locator('header')).toBeVisible();
    await page.screenshot({ path: '/results/01-home.png', fullPage: true });
  });

  test('Notice list page loads', async ({ page }) => {
    await page.goto(`${BASE}/notices`, { waitUntil: 'load' });
    await page.waitForTimeout(3000);
    await page.screenshot({ path: '/results/02-notices.png', fullPage: true });
  });

  test('Notice detail page loads', async ({ page }) => {
    await page.goto(`${BASE}/notices/1`, { waitUntil: 'load' });
    await page.waitForTimeout(3000);
    await page.screenshot({ path: '/results/03-notice-detail.png', fullPage: true });
  });

  test('Search page works', async ({ page }) => {
    await page.goto(`${BASE}/search?q=security`, { waitUntil: 'load' });
    await page.waitForTimeout(3000);
    await page.screenshot({ path: '/results/04-search.png', fullPage: true });
  });

  test('Inquiry page loads', async ({ page }) => {
    await page.goto(`${BASE}/inquiry`, { waitUntil: 'load' });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: '/results/05-inquiry.png', fullPage: true });
  });

  test('Swagger docs accessible (vulnerability)', async ({ page }) => {
    await page.goto(`${BASE}/docs`, { waitUntil: 'load' });
    await page.waitForTimeout(3000);
    await page.screenshot({ path: '/results/06-swagger.png', fullPage: true });
  });

  test('Internal config exposes DB credentials (vulnerability)', async ({ request }) => {
    const res = await request.get(`${BASE}/api/internal/config`);
    const data = await res.json();
    expect(data.database.password).toBe('P0rtal#DB@2026!');
  });

  test('Hidden login page exists (vulnerability)', async ({ page }) => {
    await page.goto(`${BASE}/login`, { waitUntil: 'load' });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: '/results/07-hidden-login.png', fullPage: true });
  });

  test('API returns notice data', async ({ request }) => {
    const res = await request.get(`${BASE}/api/notices?page=1&size=3`);
    const data = await res.json();
    expect(data.total).toBeGreaterThan(0);
    expect(data.items.length).toBeGreaterThan(0);
  });

  test('Admin API accessible without auth (vulnerability)', async ({ request }) => {
    const res = await request.get(`${BASE}/api/admin/users`);
    const data = await res.json();
    expect(data.users.length).toBeGreaterThan(0);
  });

});
