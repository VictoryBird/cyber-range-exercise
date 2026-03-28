// @ts-check
const { test, expect } = require('@playwright/test');

const BASE = 'http://localhost:8080';
const API = 'http://localhost:8001';

// ─── Page Navigation Tests ───

test.describe('Complaint Portal - Pages', () => {
  test('homepage loads with hero banner and quick links', async ({ page }) => {
    await page.goto(BASE, { waitUntil: 'networkidle' });
    await expect(page.locator('text=Valdoria Electronic Complaint Portal')).toBeVisible({ timeout: 10000 });
    await expect(page.locator('text=Submit a Complaint').first()).toBeVisible();
    await expect(page.locator('text=Track Status').first()).toBeVisible();
    await page.screenshot({ path: 'test-results/03-homepage.png', fullPage: true });
  });

  test('submit page loads with step indicator', async ({ page }) => {
    await page.goto(`${BASE}/submit`, { waitUntil: 'networkidle' });
    await expect(page.locator('h1:has-text("Submit")').first()).toBeVisible({ timeout: 10000 });
    await expect(page.locator('text=Category').first()).toBeVisible();
    await expect(page.locator('text=Road & Traffic')).toBeVisible();
    await page.screenshot({ path: 'test-results/03-submit-step1.png', fullPage: true });
  });

  test('status page loads with search form', async ({ page }) => {
    await page.goto(`${BASE}/status`);
    await expect(page.locator('text=Track Complaint Status').first()).toBeVisible();
    await page.screenshot({ path: 'test-results/03-status.png', fullPage: true });
  });

  test('FAQ page loads with accordion items', async ({ page }) => {
    await page.goto(`${BASE}/faq`);
    await expect(page.locator('text=Frequently Asked Questions').first()).toBeVisible();
    await expect(page.locator('text=How long does it take')).toBeVisible();
    await page.screenshot({ path: 'test-results/03-faq.png', fullPage: true });
  });

  test('navigation links work', async ({ page }) => {
    await page.goto(BASE);
    // Click Submit Complaint nav
    await page.click('nav >> text=Submit Complaint');
    await expect(page).toHaveURL(/\/submit/);
    // Click Track Status nav
    await page.click('nav >> text=Track Status');
    await expect(page).toHaveURL(/\/status/);
    // Click FAQ nav
    await page.click('nav >> text=FAQ');
    await expect(page).toHaveURL(/\/faq/);
    // Click Home
    await page.click('nav >> text=Home');
    await expect(page).toHaveURL(BASE + '/');
  });
});

// ─── Complaint Submission Flow ───

test.describe('Complaint Submission - 4-Step Wizard', () => {
  test('full complaint submission flow', async ({ page }) => {
    await page.goto(`${BASE}/submit`);

    // Step 1: Select category
    await page.click('text=Road & Traffic');
    await page.click('button:has-text("Continue")');

    // Step 2: Fill details
    await page.fill('#title', 'Pothole on Central Avenue near Block 42');
    await page.fill('#content', 'A large pothole has formed on Central Avenue near Block 42. It is approximately 30cm deep and poses a serious hazard to vehicles and pedestrians.');
    await page.fill('#submitter_name', 'John Doe');
    await page.fill('#submitter_phone', '+1-555-0123');
    await page.fill('#submitter_email', 'john.doe@example.com');
    await page.screenshot({ path: 'test-results/03-submit-step2.png', fullPage: true });
    await page.click('button:has-text("Continue")');

    // Step 3: Skip file upload
    await page.screenshot({ path: 'test-results/03-submit-step3.png', fullPage: true });
    await page.click('button:has-text("Continue")');

    // Step 4: Review and submit
    await expect(page.locator('text=Road & Traffic')).toBeVisible();
    await expect(page.locator('text=Pothole on Central Avenue')).toBeVisible();
    await expect(page.locator('text=John Doe')).toBeVisible();
    await page.screenshot({ path: 'test-results/03-submit-step4.png', fullPage: true });

    // Check privacy consent
    await page.click('input[type="checkbox"]');

    // Submit
    await page.click('button:has-text("Submit Complaint")');

    // Wait for success modal
    await expect(page.locator('text=Complaint Submitted')).toBeVisible({ timeout: 10000 });
    const complaintNumber = await page.locator('text=/COMP-\\d{4}-\\d{5}/').textContent();
    console.log('Created complaint:', complaintNumber);
    await page.screenshot({ path: 'test-results/03-submit-success.png', fullPage: true });

    expect(complaintNumber).toMatch(/COMP-\d{4}-\d{5}/);
  });

  test('validation prevents empty submission', async ({ page }) => {
    await page.goto(`${BASE}/submit`);

    // Try to continue without selecting category
    await page.click('button:has-text("Continue")');
    // Should stay on step 1 (toast warning)

    // Select category and continue
    await page.click('text=Environment');
    await page.click('button:has-text("Continue")');

    // Try to continue with empty form
    await page.click('button:has-text("Continue")');
    // Should show validation errors
    await expect(page.locator('text=/Title is required|Title must be/').first()).toBeVisible({ timeout: 5000 });
  });
});

// ─── API Tests ───

test.describe('Complaint API - Direct', () => {
  let complaintNumber;

  test('POST /api/complaint/submit creates a complaint', async ({ request }) => {
    const res = await request.post(`${API}/api/complaint/submit`, {
      data: {
        category: 'facility',
        title: 'Broken streetlight on Oak Street',
        content: 'The streetlight near 55 Oak Street has been malfunctioning for over a week. It flickers constantly and is a safety concern for pedestrians at night.',
        submitter_name: 'Jane Smith',
        submitter_phone: '+1-555-9876',
        submitter_email: 'jane.smith@example.com',
      },
    });
    expect(res.status()).toBe(201);
    const body = await res.json();
    expect(body.complaint_number).toMatch(/COMP-\d{4}-\d{5}/);
    complaintNumber = body.complaint_number;
    console.log('API created complaint:', complaintNumber);
  });

  test('GET /api/complaint/{number} returns complaint detail', async ({ request }) => {
    // First create one
    const create = await request.post(`${API}/api/complaint/submit`, {
      data: {
        category: 'road',
        title: 'API test complaint for retrieval',
        content: 'This is a test complaint created by Playwright to verify the GET endpoint works correctly.',
        submitter_name: 'Test User',
        submitter_phone: '555-0000',
        submitter_email: 'test@example.com',
      },
    });
    const { complaint_number } = await create.json();

    const res = await request.get(`${API}/api/complaint/${complaint_number}`);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.complaint_number).toBe(complaint_number);
    expect(body.title).toBe('API test complaint for retrieval');
    expect(body.applicant_name).toBe('Test User');
    expect(body.status).toBe('Received');
  });

  test('GET /api/complaint/nonexistent returns 404', async ({ request }) => {
    const res = await request.get(`${API}/api/complaint/COMP-9999-99999`);
    expect(res.status()).toBe(404);
  });

  test('GET /api/health returns ok', async ({ request }) => {
    const res = await request.get(`${API}/api/health`);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.status).toBe('ok');
  });
});

// ─── Vulnerability Tests ───

test.describe('Vulnerability Tests', () => {

  test('VULN: double extension file upload bypass', async ({ request }) => {
    // First create a complaint
    const create = await request.post(`${API}/api/complaint/submit`, {
      data: {
        category: 'other',
        title: 'Vulnerability test - file extension bypass',
        content: 'Testing that the intentional file extension bypass vulnerability works as designed.',
        submitter_name: 'Red Team',
        submitter_phone: '555-1337',
        submitter_email: 'redteam@test.com',
      },
    });
    const { complaint_number } = await create.json();

    // Upload file with double extension: shell.pdf.py
    // The vulnerable code checks if ".pdf" EXISTS in the filename, so this passes
    const res = await request.post(`${API}/api/complaint/upload`, {
      multipart: {
        complaint_number: complaint_number,
        file: {
          name: 'shell.pdf.py',
          mimeType: 'application/pdf',
          buffer: Buffer.from('#!/usr/bin/env python3\nprint("This is a test payload")\n'),
        },
      },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.original_name).toBe('shell.pdf.py');
    console.log('VULN: Double extension bypass successful - shell.pdf.py uploaded');
  });

  test('VULN: Content-Type manipulation accepted', async ({ request }) => {
    const create = await request.post(`${API}/api/complaint/submit`, {
      data: {
        category: 'other',
        title: 'Vulnerability test - content-type',
        content: 'Testing content-type manipulation vulnerability works as designed.',
        submitter_name: 'Red Team',
        submitter_phone: '555-1337',
        submitter_email: 'redteam@test.com',
      },
    });
    const { complaint_number } = await create.json();

    // Upload a text file claiming to be a PDF
    const res = await request.post(`${API}/api/complaint/upload`, {
      multipart: {
        complaint_number: complaint_number,
        file: {
          name: 'report.pdf',
          mimeType: 'application/pdf',
          buffer: Buffer.from('This is not actually a PDF, but will be accepted'),
        },
      },
    });
    expect(res.status()).toBe(200);
    console.log('VULN: Content-Type manipulation accepted as designed');
  });

  test('VULN: IDOR - any complaint accessible without auth', async ({ request }) => {
    // Create a complaint
    const create = await request.post(`${API}/api/complaint/submit`, {
      data: {
        category: 'welfare',
        title: 'Sensitive complaint with personal info',
        content: 'This complaint contains sensitive personal information that should be protected.',
        submitter_name: 'Confidential Person',
        submitter_phone: '555-SECRET',
        submitter_email: 'secret@private.com',
      },
    });
    const { complaint_number } = await create.json();

    // Access without any authentication - should succeed (IDOR vulnerability)
    const res = await request.get(`${API}/api/complaint/${complaint_number}`);
    expect(res.status()).toBe(200);
    const body = await res.json();
    // Personal info is exposed without authentication
    expect(body.applicant_name).toBe('Confidential Person');
    expect(body.applicant_phone).toBe('555-SECRET');
    console.log('VULN: IDOR confirmed - personal info accessible without auth');
  });

  test('VULN: hardcoded admin token works', async ({ request }) => {
    // Use the hardcoded admin token from source code (Bearer auth)
    const res = await request.get(`${API}/api/complaints`, {
      headers: {
        'Authorization': 'Bearer admin-token-mois-2026',
      },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.total).toBeGreaterThanOrEqual(0);
    console.log(`VULN: Hardcoded admin token works - ${body.total} complaints accessible`);
  });

  test('VULN: admin list partially accessible without token', async ({ request }) => {
    const res = await request.get(`${API}/api/complaints`);
    // Should still return 200 but with limited info (or full info depending on implementation)
    // The vulnerability is that the token check may not fully block access
    console.log('Admin list without token status:', res.status());
  });
});

// ─── Status Tracking Flow ───

test.describe('Status Tracking', () => {
  test('search for complaint by number', async ({ page, request }) => {
    // Create a complaint via API first
    const create = await request.post(`${API}/api/complaint/submit`, {
      data: {
        category: 'environment',
        title: 'Noise pollution from construction site',
        content: 'Construction work is continuing past 10 PM on weeknights. Please enforce the noise ordinance.',
        submitter_name: 'Sarah Johnson',
        submitter_phone: '+1-555-4567',
        submitter_email: 'sarah.j@example.com',
      },
    });
    const { complaint_number } = await create.json();

    // Navigate to status page
    await page.goto(`${BASE}/status`);
    await page.fill('input[placeholder*="COMP"]', complaint_number);
    await page.click('button:has-text("Search")');

    // Should navigate to detail page
    await expect(page).toHaveURL(new RegExp(`/status/${complaint_number}`), { timeout: 10000 });
    await expect(page.locator(`text=${complaint_number}`).first()).toBeVisible();
    await expect(page.locator('text=Noise pollution').first()).toBeVisible();
    await page.screenshot({ path: 'test-results/03-status-detail.png', fullPage: true });
  });
});
