#!/usr/bin/env node
/**
 * sync-fixtures — đồng bộ bản sao tệp route thật dùng cho test lõi luồng.
 *
 * Vì sao cần bản sao: console là ứng dụng trình duyệt, **cố ý không cài `@types/node`**
 * (đọc bằng `node:fs` trong test làm `tsc --noEmit` đỏ), và Vite chặn nạp tệp ngoài gốc
 * dự án — nên test K1 đọc `src/flows/core/__fixtures__/` chứ không đọc thẳng `routes/`.
 *
 * Rủi ro của bản sao là **âm thầm lạc hậu**: tệp gốc đổi mà bản sao đứng yên thì test
 * vẫn xanh trong khi sản phẩm đã khác. Kịch bản này chặn đúng chỗ đó.
 *
 *   node scripts/sync-fixtures.mjs          # kiểm, khác thì thoát mã 1
 *   node scripts/sync-fixtures.mjs --write  # chép lại cho khớp
 */

import { readFileSync, writeFileSync, readdirSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, '../../..');
const routesDir = join(repoRoot, 'routes');
const fixturesDir = resolve(here, '../src/flows/core/__fixtures__');

/** Mọi tệp `*.camel.yaml` dưới `routes/`, trả về đường dẫn tương đối. */
function findRoutes(dir, base = '') {
  const out = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const rel = base ? `${base}/${entry.name}` : entry.name;
    if (entry.isDirectory()) out.push(...findRoutes(join(dir, entry.name), rel));
    else if (entry.name.endsWith('.camel.yaml')) out.push(rel);
  }
  return out;
}

/** `_examples/ping.camel.yaml` → `_examples__ping.camel.yaml` (thư mục phẳng). */
const flatten = (rel) => rel.replaceAll('/', '__');

const write = process.argv.includes('--write');
if (!existsSync(fixturesDir)) mkdirSync(fixturesDir, { recursive: true });

const sources = findRoutes(routesDir);
const problems = [];

for (const rel of sources) {
  const src = readFileSync(join(routesDir, rel), 'utf8');
  const dest = join(fixturesDir, flatten(rel));
  const current = existsSync(dest) ? readFileSync(dest, 'utf8') : null;
  if (current === src) continue;
  if (write) {
    writeFileSync(dest, src);
    console.log(`cập nhật ${flatten(rel)}`);
  } else {
    problems.push(current === null ? `thiếu bản sao: ${rel}` : `bản sao lạc hậu: ${rel}`);
  }
}

// Bản sao thừa: tệp gốc đã xóa hoặc đổi tên.
const expected = new Set(sources.map(flatten));
for (const name of readdirSync(fixturesDir)) {
  if (name.endsWith('.camel.yaml') && !expected.has(name)) {
    problems.push(`bản sao thừa (tệp gốc đã đổi tên hoặc xóa): ${name}`);
  }
}

if (problems.length) {
  console.error('Bản sao tệp route đã lệch với `routes/`:');
  for (const p of problems) console.error(`  - ${p}`);
  console.error('\nChạy `npm run fixtures:write` để đồng bộ.');
  process.exit(1);
}

console.log(`Bản sao khớp với ${sources.length} tệp route gốc.`);
