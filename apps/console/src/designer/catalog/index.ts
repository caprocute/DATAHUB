/**
 * Danh mục thành phần Camel — bản đầy đủ theo nhà sản xuất.
 *
 * Dữ liệu sinh bằng `scripts/build-catalog.mjs` từ gói `@kaoto/camel-catalog` (Apache-2.0),
 * nhánh `camel-quarkus/3.35.0` — đúng runtime của `camel/*` trong repo (ADR-002/020).
 * Cách chia loại nút và cách nhóm theo nhãn lấy nguyên của Kaoto, không tự đặt.
 *
 * Hai tầng dữ liệu:
 *  - chỉ mục (tệp này) nạp đồng bộ, đủ cho bảng thành phần và tìm kiếm;
 *  - `propertiesSchema` nạp lười theo từng nút khi mở popup cấu hình (FR-04-037),
 *    tránh kéo cả 7 MB lược đồ vào bundle.
 */

import indexRaw from './generated/catalog-index.json';

export type NodeKind =
  | 'component'
  | 'pattern'
  | 'kamelet'
  | 'dataformat'
  | 'language'
  | 'entity'
  | 'loadbalancer';

export interface CatalogNode {
  name: string;
  kind: NodeKind;
  title: string;
  description: string;
  labels: string[];
  scheme?: string;
  syntax?: string;
  /** Chỉ dùng được làm chặng tiếp nhận (đầu luồng). */
  consumerOnly?: boolean;
  /** Không dùng được làm chặng tiếp nhận. */
  producerOnly?: boolean;
  deprecated?: boolean;
  supportLevel?: string;
  /** EIP nhận nhánh con (ví dụ `choice`, `split`). */
  input?: boolean;
  output?: boolean;
  kameletType?: string;
}

interface IndexShape {
  source: string;
  license: string;
  runtime: string;
  runtimeVersion: string;
  generatedAt: string;
  counts: Record<string, number>;
  labels: Record<string, number>;
  nodes: CatalogNode[];
}

const data = indexRaw as unknown as IndexShape;

export const CATALOG_SOURCE = data.source;
export const CATALOG_LICENSE = data.license;
export const CATALOG_RUNTIME = `${data.runtime} ${data.runtimeVersion}`;
export const CATALOG_COUNTS = data.counts;
export const CATALOG_LABELS = data.labels;
export const CATALOG_NODES = data.nodes;
export const CATALOG_TOTAL = data.nodes.length;

const byKey = new Map<string, CatalogNode>();
const byName = new Map<string, CatalogNode>();
for (const n of data.nodes) {
  byKey.set(`${n.kind}/${n.name}`, n);
  // Tra theo tên trần: ưu tiên component rồi pattern, vì luồng cũ tham chiếu bằng tên.
  const prev = byName.get(n.name);
  if (!prev || rankKind(n.kind) < rankKind(prev.kind)) byName.set(n.name, n);
}

function rankKind(k: NodeKind): number {
  return ['component', 'pattern', 'kamelet', 'dataformat', 'language', 'entity', 'loadbalancer'].indexOf(k);
}

/** Tra một nút theo `kind/name`, hoặc theo tên trần cho dữ liệu luồng cũ. */
export function lookupNode(ref: string): CatalogNode | undefined {
  return byKey.get(ref) ?? byName.get(ref);
}

/* ---------- Lược đồ tham số: nạp lười ---------- */

export type PropType = 'string' | 'boolean' | 'integer' | 'number' | 'enum' | 'object' | 'array';

export interface SchemaProp {
  title?: string;
  description?: string;
  type?: PropType | string;
  default?: unknown;
  enum?: string[];
  format?: string;
  deprecated?: boolean;
  /** Bản gốc ghi nhóm thuộc tính ở đây, dạng `group:consumer (advanced)`. */
  $comment?: string;
}

export interface PropertiesSchema {
  required?: string[];
  properties?: Record<string, SchemaProp>;
}

// Vite gom sẵn mọi tệp lược đồ thành các import động — mỗi nút một khối tách riêng.
const schemaLoaders = import.meta.glob<{ default: PropertiesSchema }>('./generated/schemas/*/*.json');

const schemaCache = new Map<string, PropertiesSchema>();

/** Lược đồ đã nạp trước đó; dùng cho lối vẽ đồng bộ (badge thiếu trường). */
export function peekSchema(node: CatalogNode): PropertiesSchema | undefined {
  return schemaCache.get(`${node.kind}/${node.name}`);
}

/** Nạp lược đồ tham số gốc của một nút. Trả rỗng nếu nút không có tham số. */
export async function loadSchema(node: CatalogNode): Promise<PropertiesSchema> {
  const key = `${node.kind}/${node.name}`;
  const cached = schemaCache.get(key);
  if (cached) return cached;
  const loader = schemaLoaders[`./generated/schemas/${node.kind}/${node.name}.json`];
  if (!loader) {
    const empty: PropertiesSchema = {};
    schemaCache.set(key, empty);
    return empty;
  }
  const mod = await loader();
  const schema = (mod.default ?? mod) as PropertiesSchema;
  schemaCache.set(key, schema);
  return schema;
}

/** Nhóm thuộc tính, đọc từ `$comment` của bản gốc. `advanced` bị gập lại trong biểu mẫu. */
export function groupOf(prop: SchemaProp): { group: string; advanced: boolean } {
  const m = /^group:([^(]+)(\(advanced\))?/.exec(prop.$comment ?? '');
  return { group: (m?.[1] ?? 'common').trim(), advanced: Boolean(m?.[2]) };
}

/* ---------- Phân loại hiển thị ---------- */

/** Nhãn tiếng Việt của loại nút — cách chia loại giữ nguyên của Kaoto. */
export const KIND_VI: Record<NodeKind, string> = {
  component: 'Thành phần',
  pattern: 'Mẫu EIP',
  kamelet: 'Kamelet',
  dataformat: 'Định dạng dữ liệu',
  language: 'Ngôn ngữ biểu thức',
  entity: 'Thực thể',
  loadbalancer: 'Cân bằng tải',
};

/** Nhãn tiếng Việt cho nhóm gốc của Camel. Nhóm nào chưa dịch thì giữ tên gốc. */
export const LABEL_VI: Record<string, string> = {
  cloud: 'Điện toán đám mây',
  messaging: 'Bản tin & hàng đợi',
  database: 'Cơ sở dữ liệu',
  transformation: 'Chuyển đổi dữ liệu',
  clustering: 'Cụm & điều phối',
  core: 'Lõi',
  container: 'Vùng chứa',
  file: 'Tệp',
  cache: 'Bộ đệm',
  ai: 'Trí tuệ nhân tạo',
  api: 'Giao diện lập trình',
  management: 'Quản trị',
  iot: 'Thiết bị kết nối',
  monitoring: 'Giám sát',
  mail: 'Thư điện tử',
  saas: 'Dịch vụ phần mềm',
  document: 'Tài liệu',
  bigdata: 'Dữ liệu lớn',
  security: 'An toàn thông tin',
  http: 'Giao thức HTTP',
  search: 'Tìm kiếm',
  script: 'Kịch bản',
  networking: 'Mạng',
  mobile: 'Di động',
  scheduling: 'Lập lịch',
  testing: 'Kiểm thử',
  validation: 'Kiểm tra hợp lệ',
  chat: 'Trò chuyện',
  social: 'Mạng xã hội',
  rest: 'REST',
  workflow: 'Quy trình',
  rpc: 'Gọi thủ tục từ xa',
  cms: 'Quản trị nội dung',
  blockchain: 'Chuỗi khối',
  serverless: 'Không máy chủ',
  finance: 'Tài chính',
  webservice: 'Dịch vụ web',
  health: 'Sức khỏe hệ thống',
  eip: 'Mẫu tích hợp',
  routing: 'Định tuyến',
  Actions: 'Hành động',
  Source: 'Nguồn dữ liệu',
  Sink: 'Đích dữ liệu',
};

export function labelVi(label: string): string {
  return LABEL_VI[label] ?? label;
}

/** Nhóm màu trên canvas — suy từ nhãn gốc, không từ danh sách tên cứng. */
export type NodeTone = 'trigger' | 'auth' | 'eip' | 'transform' | 'enrich' | 'dest';

/** Suy tone của một nút theo nhãn gốc + vai trò trên luồng. */
export function toneOfNode(node: CatalogNode | undefined, role: 'from' | 'step' = 'step'): NodeTone {
  if (role === 'from') return 'trigger';
  if (!node) return 'dest';
  const l = new Set(node.labels);
  if (l.has('validation') || l.has('security')) return 'auth';
  if (node.kind === 'pattern' || node.kind === 'loadbalancer' || l.has('eip') || l.has('routing')) return 'eip';
  if (node.kind === 'dataformat' || node.kind === 'language' || l.has('transformation') || l.has('script'))
    return 'transform';
  if (l.has('database') || l.has('search') || l.has('cache')) return 'enrich';
  return 'dest';
}

/** Giữ lối gọi cũ theo tên trần cho mã đã có. */
export function toneOf(ref: string, role: 'from' | 'step' = 'step'): NodeTone {
  return toneOfNode(lookupNode(ref), role);
}

/* ---------- Tìm kiếm ---------- */

/** Chuỗi tìm kiếm dựng sẵn một lần, tránh dựng lại mỗi lần gõ phím. */
const haystack = new Map<CatalogNode, string>();
for (const n of data.nodes) {
  haystack.set(n, `${n.name} ${n.title} ${n.description} ${n.labels.join(' ')}`.toLowerCase());
}

export interface SearchOptions {
  kind?: NodeKind;
  label?: string;
  /** `from` chỉ lấy nút đứng đầu được; `step` loại nút chỉ làm đầu luồng. */
  role?: 'from' | 'step';
  limit?: number;
}

/** Nút có dùng được ở vị trí này của luồng không — luật lọc giống Kaoto. */
export function fitsRole(n: CatalogNode, role: 'from' | 'step'): boolean {
  // Mẫu EIP, định dạng, ngôn ngữ không bao giờ mở đầu luồng.
  if (role === 'from') return !n.producerOnly && (n.kind === 'component' || n.kind === 'kamelet');
  return !n.consumerOnly;
}

export function searchNodes(query: string, opts: SearchOptions = {}): CatalogNode[] {
  const needle = query.trim().toLowerCase();
  const terms = needle.split(/\s+/).filter(Boolean);
  const out: CatalogNode[] = [];
  const limit = opts.limit ?? 200;

  for (const n of data.nodes) {
    if (opts.kind && n.kind !== opts.kind) continue;
    if (opts.label && !n.labels.includes(opts.label)) continue;
    if (opts.role && !fitsRole(n, opts.role)) continue;
    if (terms.length) {
      const hay = haystack.get(n) ?? '';
      if (!terms.every((t) => hay.includes(t))) continue;
    }
    out.push(n);
  }

  if (terms.length) {
    // Khớp đúng tên lên trước, rồi tới khớp đầu tên, cuối cùng mới tới khớp mô tả.
    const first = terms[0];
    out.sort((a, b) => score(a, first) - score(b, first) || a.name.localeCompare(b.name));
  }
  return out.slice(0, limit);
}

function score(n: CatalogNode, term: string): number {
  const name = n.name.toLowerCase();
  if (name === term) return 0;
  if (name.startsWith(term)) return 1;
  if (name.includes(term)) return 2;
  if (n.title.toLowerCase().includes(term)) return 3;
  return 4;
}

/** Các nhãn có thật trong một loại nút, kèm số lượng — dùng dựng nhóm của bảng thành phần. */
export function labelsOfKind(kind: NodeKind): { label: string; count: number }[] {
  const c = new Map<string, number>();
  for (const n of data.nodes) {
    if (n.kind !== kind) continue;
    for (const l of n.labels) c.set(l, (c.get(l) ?? 0) + 1);
  }
  return [...c.entries()]
    .map(([label, count]) => ({ label, count }))
    .sort((a, b) => b.count - a.count || a.label.localeCompare(b.label));
}
