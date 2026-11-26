/**
 * runtime-version — nguồn chung cho phiên bản runtime Camel Quarkus của designer.
 *
 * Catalog của designer phải khớp runtime chạy luồng thật (`camel/*`). Không ghim số
 * thứ hai ở phía console: đọc thẳng `camel-quarkus.platform.version` trong các
 * `camel/<du>/pom.xml`, nên nâng runtime ở pom là đủ để `npm run catalog:check` (chạy
 * trong CI) báo catalog đã lệch và buộc sinh lại.
 */

import fs from 'node:fs';
import path from 'node:path';

const PROP = 'camel-quarkus.platform.version';

/**
 * Đọc phiên bản Camel Quarkus từ mọi `camel/<du>/pom.xml`.
 * Các DU phải cùng một phiên bản — designer chỉ có một catalog.
 */
export function readRuntimeVersion(repoRoot) {
  const camelDir = path.join(repoRoot, 'camel');
  const found = [];
  for (const du of fs.readdirSync(camelDir).sort()) {
    const pom = path.join(camelDir, du, 'pom.xml');
    if (!fs.existsSync(pom)) continue;
    const m = fs.readFileSync(pom, 'utf8').match(/<camel-quarkus\.platform\.version>\s*([^<\s]+)\s*</);
    if (!m) throw new Error(`${path.relative(repoRoot, pom)} không khai <${PROP}>`);
    found.push({ du, version: m[1] });
  }
  if (!found.length) throw new Error(`không có camel/*/pom.xml nào khai <${PROP}>`);
  const versions = [...new Set(found.map((f) => f.version))];
  if (versions.length > 1)
    throw new Error(
      `các DU Camel lệch phiên bản Camel Quarkus: ${found.map((f) => `${f.du}=${f.version}`).join(', ')}` +
        ' — designer chỉ có một catalog, phải thống nhất trước',
    );
  return { version: versions[0], modules: found.map((f) => f.du) };
}

/** `3.33.2` → `[3, 33, 2]`; bản dựng sản phẩm (`3.33.0.redhat-00010`) trả `null`. */
function parseCommunity(v) {
  const m = /^(\d+)\.(\d+)\.(\d+)$/.exec(v);
  return m ? m.slice(1).map(Number) : null;
}

export function minorOf(v) {
  return String(v).split('.').slice(0, 2).join('.');
}

/**
 * Chọn nhánh catalog cho runtime đích, trong số nhánh gói catalog phát hành.
 *
 * Luật: cùng `major.minor` (cùng dòng Camel LTS) là bắt buộc. Có đúng bản thì lấy;
 * không có thì lấy bản vá cộng đồng **cao nhất không vượt** runtime (không đưa vào
 * designer tùy chọn mà runtime chưa có); chỉ khi không còn bản nào thấp hơn mới lấy
 * bản vá thấp nhất cao hơn. Bản dựng `redhat-*` bỏ qua trừ khi trùng khít.
 */
export function pickCatalogBranch(available, target) {
  if (available.includes(target)) return { branch: target, exact: true };
  const t = parseCommunity(target);
  if (!t) throw new Error(`phiên bản runtime không hợp lệ: ${target}`);
  const same = available
    .map((v) => ({ v, p: parseCommunity(v) }))
    .filter((x) => x.p && x.p[0] === t[0] && x.p[1] === t[1])
    .sort((a, b) => a.p[2] - b.p[2]);
  const below = same.filter((x) => x.p[2] <= t[2]);
  const hit = below.length ? below[below.length - 1] : same[0];
  if (!hit)
    throw new Error(
      `gói catalog không có nhánh camel-quarkus ${minorOf(target)}.x cho runtime ${target}; ` +
        `có: ${available.join(', ')} — đổi CATALOG_PKG_VERSION sang bản có dòng này`,
    );
  return { branch: hit.v, exact: false };
}
