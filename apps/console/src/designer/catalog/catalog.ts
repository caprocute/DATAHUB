/**
 * Lớp tương thích + bảng thành phần theo cách gọi nghiệp vụ của LGSP.
 *
 * Dữ liệu danh mục thật nằm ở `./index` (751 nút sinh từ `@kaoto/camel-catalog`,
 * nhánh `camel-quarkus`). Tệp này chỉ giữ hai việc:
 *  1. tái xuất các hàm tra cứu để mã cũ không phải đổi đường dẫn nhập;
 *  2. định nghĩa nhóm «Dùng nhiều» — các mục hay dùng của LGSP, đặt trước
 *     các tab phân loại gốc trong bảng thành phần.
 */

import {
  CATALOG_COUNTS,
  CATALOG_RUNTIME,
  lookupNode,
  toneOf,
  type CatalogNode,
  type NodeTone,
} from './index';

export {
  CATALOG_COUNTS,
  CATALOG_LABELS,
  CATALOG_LICENSE,
  CATALOG_NODES,
  CATALOG_RUNTIME,
  CATALOG_SOURCE,
  CATALOG_TOTAL,
  KIND_VI,
  LABEL_VI,
  fitsRole,
  groupOf,
  labelVi,
  labelsOfKind,
  loadSchema,
  lookupNode,
  peekSchema,
  searchNodes,
  toneOf,
  toneOfNode,
} from './index';
export type {
  CatalogNode,
  NodeKind,
  NodeTone,
  PropType,
  PropertiesSchema,
  SchemaProp,
  SearchOptions,
} from './index';

/** Phiên bản Camel của danh mục đang nạp — hiện trên thanh trạng thái của trình thiết kế. */
export const CAMEL_VERSION = CATALOG_RUNTIME;
export const CATALOG_SIZE = {
  components: CATALOG_COUNTS.component ?? 0,
  patterns: CATALOG_COUNTS.pattern ?? 0,
  kamelets: CATALOG_COUNTS.kamelet ?? 0,
  total: Object.values(CATALOG_COUNTS).reduce((a, b) => a + b, 0),
};

/** Tên gọi cũ của `lookupNode`, giữ cho mã đã có. */
export function lookup(name: string): CatalogNode | undefined {
  return lookupNode(name);
}

/* ---------- Bảng thành phần theo cách gọi nghiệp vụ của LGSP ---------- */

export interface PaletteItem {
  /** Tên mục trong catalog Camel, dạng `kind/name` hoặc tên trần. */
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

/** Dựng mục palette từ một nút bất kỳ của danh mục đầy đủ. */
export function paletteItemOf(node: CatalogNode, role: 'from' | 'step' = 'step'): PaletteItem {
  return {
    ref: `${node.kind}/${node.name}`,
    label: node.title,
    icon: ICON_BY_TONE[toneOf(`${node.kind}/${node.name}`, role)],
    consumerOnly: node.consumerOnly,
    uri: node.syntax && node.scheme ? node.syntax : undefined,
    tone: toneOf(`${node.kind}/${node.name}`, role),
  };
}

/** Biểu tượng mặc định theo nhóm màu, dùng cho nút dựng từ danh mục đầy đủ. */
export const ICON_BY_TONE: Record<NodeTone, string> = {
  trigger: '\u21e5',
  auth: '\u2713',
  eip: '\u2442',
  transform: '\u25c7',
  enrich: '\u25c9',
  dest: '\u229e',
};

/** Nhóm «Dùng nhiều» — không thay thế phân loại gốc, chỉ đặt trước cho tiện. */
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
