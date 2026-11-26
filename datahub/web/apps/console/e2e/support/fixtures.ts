import AxeBuilder from '@axe-core/playwright';
import { expect, test as base, type Page } from '@playwright/test';
import { createSign, randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { privateKeyPath } from './env';

export type Persona = 'TA' | 'DS' | 'PA';

const PERSONAS: Record<Persona, { tenant: string; perms: string[]; roles: string[]; name: string }> = {
  TA: { tenant: 'T01', perms: ['PERM-07-read', 'PERM-07-create', 'PERM-07-update'], roles: ['TENANT_ADMIN'], name: 'Quản trị T01' },
  DS: { tenant: 'T01', perms: ['PERM-07-read'], roles: ['DATA_STEWARD'], name: 'Chuyên viên T01' },
  PA: { tenant: 'PLATFORM', perms: ['PERM-07-read', 'PERM-07-create', 'PERM-07-update'], roles: ['PLATFORM_ADMIN'], name: 'Quản trị nền tảng' },
};

const b64url = (value: Buffer | string): string => Buffer.from(value).toString('base64url');

/** Ký JWT RS256 bằng khóa riêng sinh lúc chạy ở global-setup (backend chỉ có khóa công khai). */
export function signToken(persona: Persona): string {
  const p = PERSONAS[persona];
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const payload = b64url(JSON.stringify({ sub: randomUUID(), tenant: p.tenant, perms: p.perms, roles: p.roles, name: p.name, iat: now, exp: now + 3600 }));
  const signature = createSign('RSA-SHA256').update(`${header}.${payload}`).sign(readFileSync(privateKeyPath));
  return `${header}.${payload}.${b64url(signature)}`;
}

/** Mở trang với token của vai trò (qua cơ chế e2e chỉ có khi build VITE_DH_E2E_AUTH=1). */
export async function openAs(page: Page, persona: Persona, path = '/du-lieu/danh-muc'): Promise<void> {
  const token = signToken(persona);
  await page.addInitScript((value) => {
    (window as unknown as { __DH_E2E_TOKEN__: string }).__DH_E2E_TOKEN__ = value;
  }, token);
  await page.goto(path);
}

/** axe-core: không được có vi phạm WCAG 2.x A/AA nào trên màn hình hiện tại. */
export async function expectNoAxeViolations(page: Page): Promise<void> {
  // Chờ hiệu ứng chuyển động của antd kết thúc để axe đo tương phản trên trạng thái cuối, không phải khung hình mờ dần.
  // Chỉ chờ hiệu ứng hữu hạn đang chạy: hiệu ứng lặp vô hạn (con trỏ nhấp nháy, sóng nút, biểu tượng đang tải) không bao giờ kết thúc
  // và từng làm test chập chờn khi trùng thời điểm (đánh giá vòng 2, T5).
  await page.waitForFunction(() =>
    document
      .getAnimations()
      .every((a) => a.playState !== 'running' || (a.effect?.getComputedTiming().endTime ?? 0) === Infinity),
  );
  const results = await new AxeBuilder({ page }).withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa']).analyze();
  const summary = results.violations.map((v) => `${v.id} (${v.impact ?? '?'}): ${v.nodes.map((n) => n.target.join(' ')).join(' | ')}`);
  expect(summary, 'vi phạm axe A/AA').toEqual([]);
}

export const test = base;
export { expect };
