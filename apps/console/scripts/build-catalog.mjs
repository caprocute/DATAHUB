#!/usr/bin/env node
/**
 * build-catalog — sinh danh mục thành phần Camel cho designer từ nguồn nhà sản xuất.
 *
 * Nguồn: gói npm `@kaoto/camel-catalog` (Apache-2.0) — đúng dữ liệu Kaoto dùng cho
 * trình thiết kế của họ. Chỉ đọc nhánh runtime `camel-quarkus` để khớp ADR-002/020
 * (Camel Quarkus native, Camel 4.20.0); nhánh `camel-main` / `camel-springboot` bỏ qua.
 *
 * Đầu ra hai tầng để không phình bundle:
 *   catalog/catalog-index.json          — siêu dữ liệu cho palette + tìm kiếm (nạp đồng bộ)
 *   catalog/schemas/<kind>/<name>.json  — propertiesSchema đầy đủ (nạp lười khi mở popup)
 *
 * Dùng:
 *   node scripts/build-catalog.mjs                 # tải gói theo phiên bản ghim rồi sinh
 *   node scripts/build-catalog.mjs --from <thumuc> # dùng thư mục đã giải nén sẵn
 */

import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const CONSOLE_ROOT = path.resolve(HERE, '..');
const OUT_ROOT = path.join(CONSOLE_ROOT, 'src/designer/catalog/generated');

/** Phiên bản gói catalog được ghim — đổi phải kèm chạy lại script và commit đầu ra. */
const CATALOG_PKG = '@kaoto/camel-catalog';
const CATALOG_PKG_VERSION = '0.7.0';
/** Runtime + phiên bản đích. Khớp Camel Quarkus của `camel/*` trong repo. */
const RUNTIME = 'camel-quarkus';
const RUNTIME_VERSION = '3.35.0';

/** Bảy loại nút của catalog Camel, đúng cách Kaoto chia. */
const KINDS = [
  { kind: 'component', file: 'camel-catalog-aggregate-components-*.json', meta: 'component' },
  { kind: 'pattern', file: 'camel-catalog-aggregate-patterns-*.json', meta: 'model' },
  { kind: 'dataformat', file: 'camel-catalog-aggregate-dataformats-*.json', meta: 'dataformat' },
  { kind: 'language', file: 'camel-catalog-aggregate-languages-*.json', meta: 'language' },
  { kind: 'entity', file: 'camel-catalog-aggregate-entities-*.json', meta: 'entity' },
  { kind: 'loadbalancer', file: 'camel-catalog-aggregate-loadbalancers-*.json', meta: 'model' },
];

function log(msg) {
  process.stdout.write(`[catalog] ${msg}\n`);
}

function fail(msg) {
  process.stderr.write(`[catalog] LỖI: ${msg}\n`);
  process.exit(1);
}

/** Tải và giải nén gói catalog vào thư mục tạm; trả về thư mục nhánh runtime. */
function fetchCatalog() {
  const tmp = fs.mkdtempSync(path.join(process.env.TMPDIR ?? '/tmp', 'lgsp-catalog-'));
  log(`tải ${CATALOG_PKG}@${CATALOG_PKG_VERSION} …`);
  execFileSync('npm', ['pack', `${CATALOG_PKG}@${CATALOG_PKG_VERSION}`, '--silent'], {
    cwd: tmp,
    stdio: ['ignore', 'pipe', 'inherit'],
  });
  const tgz = fs.readdirSync(tmp).find((f) => f.endsWith('.tgz'));
  if (!tgz) fail('npm pack không tạo ra tệp .tgz');
  const branch = `package/dist/camel-catalog/${RUNTIME}/${RUNTIME_VERSION}`;
  execFileSync('tar', ['xzf', tgz, '-C', tmp, branch], { cwd: tmp, stdio: 'inherit' });
  return path.join(tmp, branch);
}

function readAggregate(dir, pattern) {
  const rx = new RegExp('^' + pattern.replace('*', '[0-9a-f]+') + '$');
  const hit = fs.readdirSync(dir).find((f) => rx.test(f));
  if (!hit) fail(`không tìm thấy tệp khớp ${pattern} trong ${dir}`);
  return JSON.parse(fs.readFileSync(path.join(dir, hit), 'utf8'));
}

/** Kamelet dùng lược đồ CRD riêng, không cùng dạng aggregate. */
function readKamelets(dir) {
  const hit = fs.readdirSync(dir).find((f) => /^kamelets-aggregate-[0-9a-f]+\.json$/.test(f));
  if (!hit) fail('không tìm thấy kamelets-aggregate-*.json');
  return JSON.parse(fs.readFileSync(path.join(dir, hit), 'utf8'));
}

/** Tách nhãn nhóm gốc của Camel: `"cloud,messaging"` → `['cloud','messaging']`. */
function labelsOf(raw) {
  return String(raw ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

/** Rút gọn mô tả cho palette — chuỗi đầy đủ vẫn nằm trong tệp schema. */
function shortDesc(text) {
  const s = String(text ?? '').replace(/\s+/g, ' ').trim();
  return s.length > 180 ? `${s.slice(0, 177)}…` : s;
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(value));
}

function build(dir) {
  const index = [];
  let schemaCount = 0;

  for (const { kind, file, meta } of KINDS) {
    const agg = readAggregate(dir, file);
    for (const [name, node] of Object.entries(agg)) {
      const m = node[meta] ?? {};
      const labels = labelsOf(m.label);
      index.push({
        name,
        kind,
        title: m.title ?? name,
        description: shortDesc(m.description),
        labels,
        scheme: m.scheme ?? undefined,
        syntax: m.syntax ?? undefined,
        consumerOnly: m.consumerOnly === true || undefined,
        producerOnly: m.producerOnly === true || undefined,
        deprecated: m.deprecated === true || undefined,
        supportLevel: m.supportLevel ?? undefined,
        // `input`/`output` của model quyết định EIP có nhận nhánh con hay không.
        input: m.input === true || undefined,
        output: m.output === true || undefined,
      });
      if (node.propertiesSchema) {
        writeJson(path.join(OUT_ROOT, 'schemas', kind, `${name}.json`), node.propertiesSchema);
        schemaCount += 1;
      }
    }
    log(`${kind}: ${Object.keys(agg).length}`);
  }

  // Kamelet: kết nối dựng sẵn của cộng đồng — Kaoto xếp thành một loại nút riêng.
  const kamelets = readKamelets(dir);
  for (const [name, k] of Object.entries(kamelets)) {
    const meta = k?.metadata ?? {};
    const ann = meta.annotations ?? {};
    const spec = k?.spec ?? {};
    const def = spec.definition ?? {};
    const type = ann['camel.apache.org/kamelet.type'] ?? '';
    index.push({
      name,
      kind: 'kamelet',
      title: def.title ?? name,
      description: shortDesc(def.description),
      labels: labelsOf(ann['camel.apache.org/kamelet.group']),
      // Kamelet loại `source` chỉ đứng đầu luồng, `sink` chỉ đứng cuối.
      consumerOnly: type === 'source' || undefined,
      producerOnly: type === 'sink' || undefined,
      supportLevel: ann['camel.apache.org/kamelet.support.level'] ?? undefined,
      kameletType: type || undefined,
    });
    if (def.properties) {
      writeJson(path.join(OUT_ROOT, 'schemas', 'kamelet', `${name}.json`), {
        $schema: 'http://json-schema.org/draft-07/schema#',
        type: 'object',
        required: def.required ?? [],
        properties: def.properties,
      });
      schemaCount += 1;
    }
  }
  log(`kamelet: ${Object.keys(kamelets).length}`);

  index.sort((a, b) => a.kind.localeCompare(b.kind) || a.name.localeCompare(b.name));

  // Tổng hợp nhãn để palette dựng nhóm mà không phải quét lại toàn bộ chỉ mục.
  const labelCount = {};
  for (const e of index) for (const l of e.labels ?? []) labelCount[l] = (labelCount[l] ?? 0) + 1;

  const payload = {
    source: `${CATALOG_PKG} ${CATALOG_PKG_VERSION}`,
    license: 'Apache-2.0',
    runtime: RUNTIME,
    runtimeVersion: RUNTIME_VERSION,
    generatedAt: new Date().toISOString().slice(0, 10),
    counts: index.reduce((acc, e) => ({ ...acc, [e.kind]: (acc[e.kind] ?? 0) + 1 }), {}),
    labels: Object.fromEntries(Object.entries(labelCount).sort((a, b) => b[1] - a[1])),
    nodes: index,
  };
  writeJson(path.join(OUT_ROOT, 'catalog-index.json'), payload);

  const digest = createHash('sha256')
    .update(JSON.stringify(payload.counts) + index.map((e) => `${e.kind}/${e.name}`).join(','))
    .digest('hex')
    .slice(0, 16);

  log(`tổng nút: ${index.length} · schema: ${schemaCount} · vân tay: ${digest}`);
  if (index.length < 400) fail(`chỉ có ${index.length} nút, yêu cầu tối thiểu 400`);
  return payload;
}

const fromArg = process.argv.indexOf('--from');
const dir = fromArg > -1 ? path.resolve(process.argv[fromArg + 1]) : fetchCatalog();
if (!fs.existsSync(dir)) fail(`không có thư mục catalog: ${dir}`);
fs.rmSync(OUT_ROOT, { recursive: true, force: true });
build(dir);
log(`đã ghi vào ${path.relative(CONSOLE_ROOT, OUT_ROOT)}`);
