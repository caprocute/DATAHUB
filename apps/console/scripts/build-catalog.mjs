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
const OUT_ROOT = path.join(CONSOLE_ROOT, 'src/flows/core/generated');

/** Phiên bản gói catalog được ghim — đổi phải kèm chạy lại script và commit đầu ra. */
const CATALOG_PKG = '@kaoto/camel-catalog';
const CATALOG_PKG_VERSION = '0.7.0';
/** Runtime + phiên bản đích. Khớp Camel Quarkus của `camel/*` trong repo. */
const RUNTIME = 'camel-quarkus';
const RUNTIME_VERSION = '3.35.0';

/**
 * Bảy loại nút của catalog Camel, đúng cách Kaoto chia.
 *
 * **`meta` là tên khóa chứa siêu dữ liệu bên trong mỗi mục, không phải tên loại.**
 * Chỉ `component` có khóa trùng tên loại; bốn loại `pattern`/`dataformat`/`language`/
 * `entity`/`loadbalancer` đều gói siêu dữ liệu dưới khóa `model` vì với Camel chúng
 * đều là *model* của DSL. Đọc theo tên loại (`node.dataformat`, `node.language`,
 * `node.entity`) trả về `undefined` — và vì mọi trường đều đọc kèm `?? mặc định`,
 * chỉ mục vẫn sinh ra "thành công" với **tiêu đề trần, mô tả rỗng, không nhãn**.
 * Lỗi im lặng đúng dạng BR-D-04b: 95/751 nút từng mất sạch siêu dữ liệu theo lối này.
 */
const KINDS = [
  { kind: 'component', file: 'camel-catalog-aggregate-components-*.json', meta: 'component' },
  { kind: 'pattern', file: 'camel-catalog-aggregate-patterns-*.json', meta: 'model' },
  { kind: 'dataformat', file: 'camel-catalog-aggregate-dataformats-*.json', meta: 'model' },
  { kind: 'language', file: 'camel-catalog-aggregate-languages-*.json', meta: 'model' },
  { kind: 'entity', file: 'camel-catalog-aggregate-entities-*.json', meta: 'model' },
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

/**
 * Tách nhãn nhóm gốc của Camel: `"cloud,messaging"` → `['cloud','messaging']`.
 *
 * **Khử trùng lặp.** Bản gốc có 3 component khai `"cloud,cloud"` (`azure-key-vault`,
 * `hashicorp-vault`, `ibm-secrets-manager`). Giữ nguyên thì chip lọc đếm 94 trong khi
 * lọc thật chỉ ra 91 — số trên nhãn không khớp số dòng người dùng nhìn thấy.
 */
function labelsOf(raw) {
  return [
    ...new Set(
      String(raw ?? '')
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean),
    ),
  ];
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
      // Bốn mục của `entity` (`ObjectMeta`, `Pipe*`, `KameletConfiguration`) là lược đồ
      // CRD trần — không có khối `model`. Lấy tiêu đề/mô tả từ chính lược đồ thay vì để
      // trống, vì màn D-07 phải hiện được chúng.
      const ps = node.propertiesSchema ?? {};
      const labels = labelsOf(m.label);
      index.push({
        name,
        kind,
        title: m.title ?? ps.title ?? name,
        description: shortDesc(m.description ?? ps.description),
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
        // Phụ thuộc Maven (FR-D-072): chỉ `component` phát hành đủ tọa độ. Người dùng
        // cần nó để biết phải thêm gì vào `pom.xml` trước khi luồng chạy được.
        groupId: m.groupId || undefined,
        artifactId: m.artifactId || undefined,
        version: m.version || undefined,
        // Không chạy được ở ảnh native là ràng buộc vận hành thật với ADR-002/020
        // (Camel Quarkus native) — phải hiện, không để người dùng phát hiện lúc build.
        nativeSupported: m.artifactId ? m.nativeSupported === true : undefined,
        javaType: m.javaType || undefined,
        firstVersion: m.firstVersion || undefined,
        camelArtifact: m.metadata?.camelArtifact || undefined,
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
      // Kamelet không có tọa độ Maven riêng — nó khai `spec.dependencies` dạng
      // `camel:aws2-s3`. Đó là thứ tương đương phải hiện ở màn chi tiết (FR-D-072).
      dependencies: Array.isArray(spec.dependencies) && spec.dependencies.length
        ? spec.dependencies
        : undefined,
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

  /*
   * Chặn lỗi *im lặng* — đếm đủ nút không có nghĩa là đọc đúng.
   *
   * Ngưỡng cũ (`< 400 nút`) từng xanh trong khi 95 nút mất sạch tiêu đề, mô tả và nhãn
   * do đọc nhầm khóa siêu dữ liệu: số nút vẫn đủ vì vòng lặp vẫn chạy hết. Kiểm theo
   * *chất lượng* từng loại mới bắt được lối hỏng đó.
   *
   * `description` rỗng là bình thường ở một số nút gốc, nên không bắt tuyệt đối; bắt
   * theo **tỷ lệ**: quá nửa một loại mà rỗng thì gần như chắc chắn đọc sai khóa.
   */
  const byKind = {};
  for (const e of index) {
    const k = (byKind[e.kind] ??= { total: 0, titled: 0, described: 0 });
    k.total += 1;
    if (e.title && e.title !== e.name) k.titled += 1;
    if (e.description) k.described += 1;
  }
  for (const [kind, k] of Object.entries(byKind)) {
    if (k.described * 2 < k.total)
      fail(
        `loại ${kind}: ${k.total - k.described}/${k.total} nút không có mô tả — nhiều khả năng ` +
          `đọc sai khóa siêu dữ liệu trong KINDS (khóa đúng thường là 'model')`,
      );
  }

  // Nhãn lặp làm số đếm trên chip lọc lệch số dòng lọc ra được — phải sạch từ nguồn.
  const dup = index.filter((e) => new Set(e.labels).size !== e.labels.length);
  if (dup.length) fail(`${dup.length} nút còn nhãn lặp, ví dụ ${dup[0].kind}/${dup[0].name}`);
  log(
    'chất lượng: ' +
      Object.entries(byKind)
        .map(([k, v]) => `${k} ${v.described}/${v.total} có mô tả`)
        .join(' · '),
  );
  return payload;
}

const fromArg = process.argv.indexOf('--from');
const dir = fromArg > -1 ? path.resolve(process.argv[fromArg + 1]) : fetchCatalog();
if (!fs.existsSync(dir)) fail(`không có thư mục catalog: ${dir}`);
fs.rmSync(OUT_ROOT, { recursive: true, force: true });
build(dir);
log(`đã ghi vào ${path.relative(CONSOLE_ROOT, OUT_ROOT)}`);
