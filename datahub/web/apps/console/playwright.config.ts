import { existsSync } from 'node:fs';
import { defineConfig, devices } from '@playwright/test';
import { CONSOLE_PORT, CONSOLE_URL, API_URL } from './e2e/support/env';

/**
 * Trình duyệt: mặc định dùng Chromium do Playwright quản lý (PLAYWRIGHT_BROWSERS_PATH hoặc bộ nhớ đệm,
 * như trên CI GitHub). Chỉ khi đặt PW_CHROMIUM_PATH tới một tệp có thật mới dùng executablePath đó.
 */
const chromiumPath = process.env['PW_CHROMIUM_PATH'];
const launchOptions = chromiumPath !== undefined && existsSync(chromiumPath) ? { executablePath: chromiumPath } : {};

/**
 * E2E tự dựng môi trường: global-setup khởi PostgreSQL 18 (docker) nạp DDL + seed, build và chạy
 * dh-data (profile e2e, khóa JWT sinh lúc chạy); webServer build console với VITE_DH_E2E_AUTH=1
 * rồi phục vụ bằng vite preview (proxy /api tới backend). Một worker vì các bài chung một CSDL.
 */
export default defineConfig({
  testDir: './e2e',
  globalSetup: './e2e/global-setup.ts',
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 60_000,
  reporter: [['list'], ['html', { outputFolder: 'playwright-report', open: 'never' }]],
  use: { baseURL: CONSOLE_URL, locale: 'vi-VN', trace: 'retain-on-failure' },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'], launchOptions } }],
  webServer: {
    command: 'npx vite build --outDir dist/e2e && npx vite preview --outDir dist/e2e',
    url: CONSOLE_URL,
    reuseExistingServer: false,
    timeout: 180_000,
    env: { VITE_DH_E2E_AUTH: '1', DH_CONSOLE_PORT: String(CONSOLE_PORT), DH_API_URL: API_URL },
  },
});
