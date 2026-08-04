/**
 * Danh mục thành phần Camel.
 *
 * Dữ liệu sinh bằng `scripts/build-catalog.mjs` từ `@kaoto/camel-catalog` (Apache-2.0),
 * nhánh `camel-quarkus/3.35.0` — đúng runtime của `camel/*` trong repo (ADR-002/020).
 *
 * Số liệu định hình thiết kế (đo trên chính dữ liệu này):
 *  - 751 nút → bảng thành phần phải có tab + lọc nhãn + ảo hóa;
 *  - thuộc tính mỗi component: trung vị 19, p90 64, **tối đa 154** → cửa sổ cấu hình
 *    phải chia nhóm và cho tìm trong trường;
 *  - 876 trường `enum` → sinh `Select`, không dùng ô text.
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
  counts: Record<string, number>;
  labels: Record<string, number>;
  nodes: CatalogNode[];
}

const data = indexRaw as unknown as IndexShape;

export const CATALOG_SOURCE = data.source;
export const CATALOG_LICENSE = data.license;
export const CATALOG_RUNTIME = `${data.runtime} ${data.runtimeVersion}`;
export const CATALOG_COUNTS = data.counts;
export const CATALOG_NODES = data.nodes;
export const CATALOG_TOTAL = data.nodes.length;

const KIND_ORDER: NodeKind[] = [
  'component',
  'pattern',
  'kamelet',
  'dataformat',
  'language',
  'entity',
  'loadbalancer',
];

const byKey = new Map<string, CatalogNode>();
const byName = new Map<string, CatalogNode>();
for (const n of data.nodes) {
  byKey.set(`${n.kind}/${n.name}`, n);
  // Tra theo tên trần: ưu tiên component rồi pattern, vì luồng lưu cũ dùng tên trần.
  const prev = byName.get(n.name);
  if (!prev || KIND_ORDER.indexOf(n.kind) < KIND_ORDER.indexOf(prev.kind)) byName.set(n.name, n);
}

/** Tra một nút theo `kind/name`, hoặc theo tên trần cho dữ liệu luồng cũ. */
export function lookupNode(ref: string): CatalogNode | undefined {
  return byKey.get(ref) ?? byName.get(ref);
}

/**
 * Tên Camel trần của một tham chiếu chặng.
 *
 * Chặng kéo từ bảng thành phần mang `kind/name` (ví dụ `pattern/choice`), còn Camel
 * DSL chỉ biết tên trần. **Mọi chỗ so khớp tên mẫu phải đi qua hàm này** — không
 * chuẩn hóa thì YAML sinh ra có khóa `pattern/choice`, Camel không nạp được.
 */
export function refName(ref: string): string {
  const slash = ref.indexOf('/');
  return slash === -1 ? ref : ref.slice(slash + 1);
}

/** Khóa đầy đủ `kind/name` của một nút. */
export function refOf(node: CatalogNode): string {
  return `${node.kind}/${node.name}`;
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
  /** Bản gốc ghi nhóm thuộc tính ở đây, dạng `group:producer (advanced)`. */
  $comment?: string;
}

export interface PropertiesSchema {
  required?: string[];
  properties?: Record<string, SchemaProp>;
}

// Vite gom sẵn mỗi tệp lược đồ thành một khối tách riêng — nạp theo nhu cầu.
const loaders = import.meta.glob<{ default: PropertiesSchema }>('./generated/schemas/*/*.json');
const cache = new Map<string, PropertiesSchema>();

/** Lược đồ đã nạp trước đó; dùng cho lối vẽ đồng bộ (huy hiệu thiếu trường). */
export function peekSchema(node: CatalogNode): PropertiesSchema | undefined {
  return cache.get(refOf(node));
}

export async function loadSchema(node: CatalogNode): Promise<PropertiesSchema> {
  const key = refOf(node);
  const hit = cache.get(key);
  if (hit) return hit;
  const loader = loaders[`./generated/schemas/${node.kind}/${node.name}.json`];
  if (!loader) {
    const empty: PropertiesSchema = {};
    cache.set(key, empty);
    return empty;
  }
  const mod = await loader();
  const schema = (mod.default ?? mod) as PropertiesSchema;
  cache.set(key, schema);
  return schema;
}

/* ---------- Nhóm thuộc tính (nền cho tab của cửa sổ cấu hình) ---------- */

/** Nhóm gốc của Camel; cửa sổ cấu hình chia tab đúng theo đây, không tự đặt nhóm. */
export type PropGroup =
  | 'common'
  | 'producer'
  | 'consumer'
  | 'security'
  | 'scheduler'
  | 'advanced'
  | 'khac';

const KNOWN_GROUPS = new Set(['common', 'producer', 'consumer', 'security', 'scheduler']);

export interface GroupInfo {
  group: PropGroup;
  advanced: boolean;
  /** Nhãn gốc đầy đủ, ví dụ `producer (advanced)`. */
  raw: string;
}

/**
 * Đọc nhóm từ `$comment` của bản gốc.
 *
 * Trường đánh `(advanced)` được xếp hết vào nhóm `advanced`: chúng hiếm khi cần đặt,
 * gom lại giúp tab chính gọn cho người dùng thường.
 */
export function groupOf(prop: SchemaProp): GroupInfo {
  const m = /^group:\s*([^(]+?)\s*(\(advanced\))?$/.exec(prop.$comment ?? '');
  const raw = (m?.[1] ?? 'common').trim();
  const advanced = Boolean(m?.[2]);
  if (advanced || raw === 'advanced') return { group: 'advanced', advanced: true, raw: prop.$comment ?? '' };
  const group = (KNOWN_GROUPS.has(raw) ? raw : 'khac') as PropGroup;
  return { group, advanced: false, raw };
}

export const GROUP_VI: Record<PropGroup, string> = {
  common: 'Chung',
  producer: 'Gửi đi',
  consumer: 'Nhận về',
  security: 'An toàn',
  scheduler: 'Lập lịch',
  advanced: 'Nâng cao',
  khac: 'Khác',
};

/* ---------- Phân loại hiển thị ---------- */

export const KIND_VI: Record<NodeKind, string> = {
  component: 'Thành phần',
  pattern: 'Mẫu EIP',
  kamelet: 'Kamelet',
  dataformat: 'Định dạng dữ liệu',
  language: 'Ngôn ngữ biểu thức',
  entity: 'Thực thể',
  loadbalancer: 'Cân bằng tải',
};

/** Nhãn tiếng Việt cho nhóm gốc; nhóm chưa dịch thì giữ tên gốc. */
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

export function toneOfNode(node: CatalogNode | undefined, role: 'from' | 'step' = 'step'): NodeTone {
  if (role === 'from') return 'trigger';
  if (!node) return 'dest';
  const l = new Set(node.labels);
  if (l.has('validation') || l.has('security')) return 'auth';
  if (node.kind === 'pattern' || node.kind === 'loadbalancer' || l.has('eip') || l.has('routing'))
    return 'eip';
  if (node.kind === 'dataformat' || node.kind === 'language' || l.has('transformation') || l.has('script'))
    return 'transform';
  if (l.has('database') || l.has('search') || l.has('cache')) return 'enrich';
  return 'dest';
}

export function toneOf(ref: string, role: 'from' | 'step' = 'step'): NodeTone {
  return toneOfNode(lookupNode(ref), role);
}

export const TONE_ICON: Record<NodeTone, string> = {
  trigger: '⇥',
  auth: '✓',
  eip: '⑂',
  transform: '◇',
  enrich: '◉',
  dest: '⊞',
};

/* ---------- Tìm kiếm ---------- */

// Chuỗi tìm kiếm dựng sẵn một lần, tránh dựng lại mỗi lần gõ phím (NFR-D-02).
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

function score(n: CatalogNode, term: string): number {
  const name = n.name.toLowerCase();
  if (name === term) return 0;
  if (name.startsWith(term)) return 1;
  if (name.includes(term)) return 2;
  if (n.title.toLowerCase().includes(term)) return 3;
  return 4;
}

export function searchNodes(query: string, opts: SearchOptions = {}): CatalogNode[] {
  const needle = query.trim().toLowerCase();
  const terms = needle.split(/\s+/).filter(Boolean);
  const out: CatalogNode[] = [];

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
    const first = terms[0];
    out.sort((a, b) => score(a, first) - score(b, first) || a.name.localeCompare(b.name));
  } else {
    out.sort((a, b) => a.title.localeCompare(b.title, 'vi'));
  }
  return opts.limit ? out.slice(0, opts.limit) : out;
}

/** Nhãn có thật trong một loại nút, kèm số lượng — dựng bộ lọc của bảng thành phần. */
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
