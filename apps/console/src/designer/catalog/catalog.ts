import raw from './camel-catalog.subset.json';

/**
 * Danh mục thành phần Camel.
 *
 * Dữ liệu trong `camel-catalog.subset.json` được trích từ gói `@kaoto/camel-catalog`
 * (Apache-2.0), nhánh Camel Main 4.20.0. Giữ nguyên `title`, `description`, `label`,
 * `syntax` và `propertiesSchema` của bản gốc, nên biểu mẫu thuộc tính trong nguyên mẫu
 * sinh ra từ đúng lược đồ mà sản phẩm thật sẽ dùng.
 *
 * Bản đầy đủ nặng 446 MB (401 thành phần, 74 mẫu EIP, đủ mọi phiên bản Camel) nên
 * không đóng vào mockup. Sản phẩm thật nạp catalog từ máy chủ theo phiên bản Camel
 * đang chạy; nguyên mẫu chỉ cần tập con phục vụ khung xương chín chặng.
 */

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

export interface CatalogEntry {
  name: string;
  title: string;
  description: string;
  label: string;
  kind: 'component' | 'pattern';
  scheme?: string;
  syntax?: string;
  consumerOnly?: boolean;
  producerOnly?: boolean;
  propertiesSchema: PropertiesSchema;
}

interface RawShape {
  camelVersion: string;
  runtime: string;
  source: string;
  components: Omit<CatalogEntry, 'kind'>[];
  patterns: Omit<CatalogEntry, 'kind'>[];
}

const data = raw as unknown as RawShape;

export const CAMEL_VERSION = data.camelVersion;
export const CATALOG_SOURCE = data.source;

const byName = new Map<string, CatalogEntry>();
for (const c of data.components) byName.set(c.name, { ...c, kind: 'component' });
for (const p of data.patterns) if (!byName.has(p.name)) byName.set(p.name, { ...p, kind: 'pattern' });

export function lookup(name: string): CatalogEntry | undefined {
  return byName.get(name);
}

export const CATALOG_SIZE = { components: data.components.length, patterns: data.patterns.length };

/** Nhóm thuộc tính, đọc từ `$comment` của bản gốc. `advanced` bị gập lại trong biểu mẫu. */
export function groupOf(prop: SchemaProp): { group: string; advanced: boolean } {
  const m = /^group:([^(]+)(\(advanced\))?/.exec(prop.$comment ?? '');
  return { group: (m?.[1] ?? 'common').trim(), advanced: Boolean(m?.[2]) };
}

/* ---------- Bảng thành phần theo cách gọi nghiệp vụ của LGSP ---------- */

/** Nhóm màu kiểu n8N — dùng tô ô icon trên node và palette. */
export type NodeTone = 'trigger' | 'auth' | 'eip' | 'transform' | 'enrich' | 'dest';

export interface PaletteItem {
  /** Tên mục trong catalog Camel. */
  ref: string;
  /** Nhãn tiếng Việt hiện trên bảng thành phần và trên nút của sơ đồ. */
  label: string;
  icon: string;
  /** Chỉ được dùng làm chặng tiếp nhận (đầu luồng). */
  consumerOnly?: boolean;
  /** Giá trị gợi ý sẵn khi thả vào sơ đồ. */
  preset?: Record<string, string | number | boolean>;
  /** URI Camel gợi ý sẵn, chỉ áp cho thành phần. */
  uri?: string;
  /** Ghi đè tone nhóm nếu mục lệch với nhóm cha. */
  tone?: NodeTone;
}

export interface PaletteGroup {
  label: string;
  tone: NodeTone;
  items: PaletteItem[];
}

/** Suy ra tone khi dựng chặng từ catalog / luồng mẫu. */
export function toneOf(ref: string, role: 'from' | 'step' = 'step'): NodeTone {
  if (role === 'from') return 'trigger';
  if (['json-validator', 'validator'].includes(ref)) return 'auth';
  if (['choice', 'filter', 'split', 'aggregate', 'multicast', 'wireTap', 'idempotentConsumer', 'circuitBreaker', 'throttle', 'delay'].includes(ref))
    return 'eip';
  if (['transform', 'xslt', 'marshal', 'unmarshal', 'setHeader', 'setBody', 'process'].includes(ref)) return 'transform';
  if (['enrich', 'pollEnrich', 'bean'].includes(ref)) return 'enrich';
  if (['rest', 'timer', 'file', 'sftp'].includes(ref)) return 'trigger';
  return 'dest';
}

export const PALETTE: PaletteGroup[] = [
  {
    label: 'Điểm tiếp nhận',
    tone: 'trigger',
    items: [
      { ref: 'rest', label: 'REST endpoint', icon: '⇥', consumerOnly: true, uri: 'rest:get:/api/v1/tai-nguyen' },
      { ref: 'kafka', label: 'Kafka consumer', icon: '≋', consumerOnly: true, uri: 'kafka:chu-de-vao' },
      { ref: 'timer', label: 'Lịch định kỳ', icon: '◷', consumerOnly: true, uri: 'timer:dinh-ky', preset: { period: 60000 } },
      { ref: 'file', label: 'Thư mục tệp', icon: '▤', consumerOnly: true, uri: 'file:/du-lieu/vao' },
      { ref: 'sftp', label: 'SFTP', icon: '⇟', consumerOnly: true, uri: 'sftp:host:22/du-lieu' },
    ],
  },
  {
    label: 'Kiểm tra & ủy quyền',
    tone: 'auth',
    items: [
      { ref: 'json-validator', label: 'Kiểm tra JSON Schema', icon: '✓', uri: 'json-validator:schema/tai-nguyen.json' },
      { ref: 'validator', label: 'Kiểm tra XML Schema', icon: '✓', uri: 'validator:schema/tai-nguyen.xsd' },
      { ref: 'http', label: 'Gọi OPA ủy quyền', icon: '⊙', uri: 'http://opa.lgsp.svc:8181/v1/data/lgsp/authz', tone: 'auth' },
    ],
  },
  {
    label: 'Mẫu EIP',
    tone: 'eip',
    items: [
      { ref: 'choice', label: 'Định tuyến nội dung', icon: '⑂' },
      { ref: 'filter', label: 'Lọc bản tin', icon: '⌦' },
      { ref: 'split', label: 'Tách bản tin', icon: '⋔' },
      { ref: 'aggregate', label: 'Gộp bản tin', icon: '⋈' },
      { ref: 'multicast', label: 'Gọi song song', icon: '⇉' },
      { ref: 'wireTap', label: 'Wire Tap', icon: '⑃' },
      { ref: 'idempotentConsumer', label: 'Chống trùng bản tin', icon: '⊜' },
      { ref: 'circuitBreaker', label: 'Ngắt mạch', icon: '⏻' },
      { ref: 'throttle', label: 'Điều tiết lưu lượng', icon: '⧖' },
      { ref: 'delay', label: 'Trễ có kiểm soát', icon: '◷' },
    ],
  },
  {
    label: 'Chuẩn hóa & chuyển đổi',
    tone: 'transform',
    items: [
      { ref: 'transform', label: 'Chuẩn hóa CDM', icon: '◇' },
      {
        ref: 'transform',
        label: 'Ánh xạ trường (DataMapper)',
        icon: '⧉',
        preset: { expression: 'datamapper' },
      },
      { ref: 'xslt', label: 'XSLT', icon: '⇄', uri: 'xslt:transforms/chuyen-doi.xsl' },
      { ref: 'marshal', label: 'Đóng gói dữ liệu', icon: '⇉' },
      { ref: 'unmarshal', label: 'Mở gói dữ liệu', icon: '⇇' },
      { ref: 'setHeader', label: 'Đặt tiêu đề', icon: '⊤' },
      { ref: 'setBody', label: 'Đặt nội dung', icon: '⊥' },
      { ref: 'process', label: 'Che dữ liệu', icon: '⊘' },
    ],
  },
  {
    label: 'Làm giàu',
    tone: 'enrich',
    items: [
      { ref: 'enrich', label: 'Tra cứu MDM', icon: '◉' },
      { ref: 'pollEnrich', label: 'Tra cứu danh mục', icon: '☰' },
      { ref: 'bean', label: 'Gọi bean nội bộ', icon: '⊞', uri: 'bean:boLamGiau' },
    ],
  },
  {
    label: 'Điểm đến',
    tone: 'dest',
    items: [
      { ref: 'to', label: 'Gửi tới đích', icon: '⇥' },
      { ref: 'http', label: 'Adapter hệ thống', icon: '⊞', uri: 'http://adapter.lgsp.svc:8080/api' },
      { ref: 'kafka', label: 'Kafka producer', icon: '≋', uri: 'kafka:chu-de-ra' },
      { ref: 'sql', label: 'Ghi cơ sở dữ liệu', icon: '▦', uri: 'sql:INSERT INTO ...' },
      { ref: 'log', label: 'Ghi nhật ký', icon: '▤' },
    ],
  },
];
