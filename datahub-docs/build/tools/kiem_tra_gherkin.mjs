#!/usr/bin/env node
// Soát cú pháp mọi tệp Gherkin của datahub-docs (cổng CI "Gherkin chạy được").
//
//   npm i --no-save @cucumber/gherkin@31.0.0 @cucumber/messages@26.0.1
//   DATAHUB_DOCS=$PWD/datahub-docs node datahub-docs/build/tools/kiem_tra_gherkin.mjs
// (trình phân tích được cài ngoài repo nên đặt DATAHUB_DOCS; mặc định là thư mục cha của build/).
//
// Kiểm cho từng tệp 05-kiem-thu/test-case/phNN/gherkin/*.feature:
//   1. Phân tích được bằng trình phân tích Gherkin chính thức (dòng `# language: vi`).
//   2. Mỗi Kịch bản / Khung kịch bản có ít nhất một bước, Khung kịch bản có Ví dụ.
//   3. Mỗi Kịch bản mang đúng một thẻ định danh @TC-... (hoặc @UAT-... cho kịch bản nghiệm thu),
//      không trùng trong cùng phân hệ.
// Có lỗi thì thoát mã 1 và in tệp:dòng.
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { AstBuilder, GherkinClassicTokenMatcher, Parser } from '@cucumber/gherkin';
import { IdGenerator } from '@cucumber/messages';

const DOCS = process.env.DATAHUB_DOCS ?? join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const GOC = join(DOCS, '05-kiem-thu', 'test-case');

const loi = [];
let soTep = 0;
let soKichBan = 0;

for (const ph of readdirSync(GOC).sort()) {
  const dir = join(GOC, ph, 'gherkin');
  try { if (!statSync(dir).isDirectory()) continue; } catch { continue; }
  const tcDaGap = new Map();
  for (const ten of readdirSync(dir).filter((f) => f.endsWith('.feature')).sort()) {
    const tep = join(dir, ten);
    const rel = relative(DOCS, tep);
    soTep += 1;
    const parser = new Parser(new AstBuilder(IdGenerator.uuid()), new GherkinClassicTokenMatcher());
    let doc;
    try {
      doc = parser.parse(readFileSync(tep, 'utf8'));
    } catch (e) {
      const ds = e.errors ?? [e];
      for (const x of ds) loi.push(`${rel}:${x.location?.line ?? '?'}: ${x.message}`);
      continue;
    }
    if (!doc.feature) { loi.push(`${rel}: không có Tính năng`); continue; }
    const cac = [];
    for (const c of doc.feature.children) {
      if (c.scenario) cac.push(c.scenario);
      if (c.rule) for (const rc of c.rule.children) if (rc.scenario) cac.push(rc.scenario);
    }
    if (cac.length === 0) loi.push(`${rel}: Tính năng không có Kịch bản nào`);
    for (const s of cac) {
      soKichBan += 1;
      const dong = s.location.line;
      if (s.steps.length === 0) loi.push(`${rel}:${dong}: Kịch bản "${s.name}" không có bước`);
      if (s.keyword.includes('Khung') && s.examples.length === 0) {
        loi.push(`${rel}:${dong}: Khung kịch bản "${s.name}" thiếu Ví dụ`);
      }
      const tc = s.tags.map((t) => t.name).filter((t) => /^@(TC|UAT)-/.test(t));
      if (tc.length !== 1) {
        loi.push(`${rel}:${dong}: Kịch bản "${s.name}" cần đúng một thẻ @TC-... hoặc @UAT-..., có ${tc.length}`);
        continue;
      }
      if (tcDaGap.has(tc[0])) {
        loi.push(`${rel}:${dong}: thẻ ${tc[0]} trùng với ${tcDaGap.get(tc[0])}`);
      } else {
        tcDaGap.set(tc[0], `${ten}:${dong}`);
      }
    }
  }
}

for (const l of loi) console.log(`::error::${l}`);
console.log(`${soTep} tệp, ${soKichBan} kịch bản, ${loi.length} lỗi.`);
process.exit(loi.length ? 1 : 0);
