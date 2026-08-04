import type { Edge, Node } from '@xyflow/react';
import { lookup, toneOf, type NodeTone, type PaletteItem } from '../catalog/catalog';

/** Dữ liệu gắn vào một nút của sơ đồ — tương ứng một chặng của luồng tích hợp. */
export interface FieldMapping {
  /** Đường dẫn JSONPath / Simple của trường nguồn. */
  from: string;
  /** Đường dẫn trường đích trên lược đồ ra. */
  to: string;
}

export interface StageData extends Record<string, unknown> {
  /** Tên mục trong catalog Camel, ví dụ `rest`, `choice`. */
  ref: string;
  /** Nhãn tiếng Việt của chặng, người dùng sửa được. */
  label: string;
  icon: string;
  /** `from` là chặng tiếp nhận, mỗi luồng có đúng một chặng loại này. */
  role: 'from' | 'step';
  /** URI Camel, chỉ có ở chặng dựng trên thành phần. */
  uri?: string;
  props: Record<string, string | number | boolean>;
  /** Ánh xạ trường DataMapper — dùng với chặng `transform` / ánh xạ. */
  mappings?: FieldMapping[];
  /** Chặng bắt buộc theo khung xương chuẩn — không gỡ được. */
  locked: boolean;
  /**
   * Bản tin mẫu gắn vào chặng (FR-04-033), dạng JSON/XML thô do người thiết kế dán vào
   * hoặc lấy từ lần chạy thử trước. Không đi vào DSL production.
   */
  pinnedSample?: string;
  /** Ghi chú nghiệp vụ hiện khi duyệt (FR-04-039). */
  note?: string;
  /** Nhóm màu kiểu n8N trên canvas. */
  tone: NodeTone;
}

export type StageNode = Node<StageData, 'stage'>;

/** Dữ liệu gắn vào một cạnh. Cạnh ra khỏi nút `choice` mang điều kiện nhánh. */
export interface SeqEdgeData extends Record<string, unknown> {
  /** Biểu thức điều kiện của nhánh `when`. */
  when?: string;
  /** Nhánh mặc định của `choice`. */
  otherwise?: boolean;
}

export type SeqEdge = Edge<SeqEdgeData>;

let seq = 0;
export function nextId(prefix = 'n'): string {
  seq += 1;
  return `${prefix}${seq}`;
}

/** Dựng dữ liệu chặng từ một mục trên bảng thành phần. */
export function stageFromPalette(item: PaletteItem, role: 'from' | 'step' = 'step'): StageData {
  const entry = lookup(item.ref);
  const props: Record<string, string | number | boolean> = { ...(item.preset ?? {}) };
  const isMapper = item.label.includes('DataMapper') || props.expression === 'datamapper';
  return {
    ref: item.ref,
    label: item.label,
    icon: item.icon,
    role,
    uri: item.uri,
    props,
    mappings: isMapper ? [] : undefined,
    locked: false,
    tone: item.tone ?? toneOf(item.ref, role),
    // Giữ lại mô tả gốc của Camel để hiện trong bảng thuộc tính.
    catalogTitle: entry?.title ?? item.ref,
  };
}

/**
 * Bản tin mẫu hiệu lực của một chặng (FR-04-033).
 *
 * Ưu tiên pin của chính chặng; thiếu thì lần ngược theo cạnh vào lấy pin của chặng
 * trước đó trên đường đi. Không có pin nào thì trả `undefined` — giao diện hiện
 * trạng thái rỗng, **không** bịa dữ liệu mẫu.
 */
export function effectiveSample(
  nodeId: string,
  nodes: StageNode[],
  edges: SeqEdge[],
): { sample: string; fromNodeId: string; inherited: boolean } | undefined {
  const byId = new Map(nodes.map((n) => [n.id, n]));
  const seen = new Set<string>();
  let cursor: string | undefined = nodeId;

  while (cursor && !seen.has(cursor)) {
    seen.add(cursor);
    const data = byId.get(cursor)?.data;
    if (data?.pinnedSample?.trim()) {
      return { sample: data.pinnedSample, fromNodeId: cursor, inherited: cursor !== nodeId };
    }
    cursor = edges.find((e) => e.target === cursor)?.source;
  }
  return undefined;
}

/** Mô tả phụ hiện dưới tên chặng trên sơ đồ. */
export function stageSubtitle(d: StageData): string {
  if (d.mappings?.length) return `${d.mappings.length} ánh xạ trường`;
  if (d.uri) return d.uri;
  const first = Object.entries(d.props).find(([, v]) => v !== '' && v !== undefined);
  if (first) return `${first[0]}: ${first[1]}`;
  return lookup(d.ref)?.title ?? d.ref;
}

/* ---------- Luồng mẫu: tra-cuu-thua-dat ---------- */

export const ROUTE_ID = 'tra-cuu-thua-dat';

/** Bốn chặng bắt buộc của khung xương chuẩn — trùng danh sách ở BR-04-001 của SRS PH-04. */
export const MANDATORY_STAGES = ['Tiếp nhận', 'Kiểm tra lược đồ', 'Ủy quyền', 'Ghi vết'];

function stage(
  id: string,
  ref: string,
  icon: string,
  label: string,
  props: Record<string, string | number | boolean>,
  opts: { role?: 'from' | 'step'; uri?: string; locked?: boolean; mappings?: FieldMapping[]; tone?: NodeTone } = {},
): StageNode {
  const role = opts.role ?? 'step';
  return {
    id,
    type: 'stage',
    position: { x: 0, y: 0 },
    data: {
      ref,
      icon,
      label,
      role,
      uri: opts.uri,
      props,
      mappings: opts.mappings,
      locked: opts.locked ?? false,
      tone: opts.tone ?? toneOf(ref, role),
      catalogTitle: lookup(ref)?.title ?? ref,
    },
  };
}

export const INITIAL_NODES: StageNode[] = [
  stage('s1', 'rest', '⇥', 'Tiếp nhận', { consumes: 'application/json' }, {
    role: 'from',
    uri: 'rest:get:/api/v1/thua-dat/{soThuTu}',
    locked: true,
  }),
  stage('s2', 'json-validator', '✓', 'Kiểm tra lược đồ', {}, {
    uri: 'json-validator:schema/thua-dat-v2.json',
    locked: true,
  }),
  stage('s3', 'http', '⊙', 'Ủy quyền', { httpMethod: 'POST' }, {
    uri: 'http://opa.lgsp.svc:8181/v1/data/lgsp/authz/thuadat.read',
    locked: true,
  }),
  stage(
    's4',
    'transform',
    '◇',
    'Chuẩn hóa CDM',
    { expression: 'ThuaDat v2' },
    {
      mappings: [
        { from: '$.soThuTu', to: '$.ThuaDat.SoThuTu' },
        { from: '$.chuSoHuu.hoTen', to: '$.ThuaDat.ChuSoHuu.HoTen' },
        { from: '$.chuSoHuu.soDinhDanh', to: '$.ThuaDat.ChuSoHuu.SoDinhDanh' },
        { from: '$.viTri.maDonViHanhChinh', to: '$.ThuaDat.ViTri.MaDonViHanhChinh' },
        { from: '$.dienTich', to: '$.ThuaDat.DienTich' },
      ],
    },
  ),
  // Hạn chờ 4500 ms sát ngưỡng 5000 ms — sinh cảnh báo ở bảng phát hiện.
  stage('s5', 'enrich', '◉', 'Làm giàu', {
    expression: 'direct:tra-cuu-danh-muc-dvhc',
    timeout: 4500,
  }, {}),
  // Chưa có nhánh mặc định — sinh cảnh báo luật định tuyến không vét cạn.
  stage('s6', 'choice', '⑂', 'Định tuyến theo nội dung', {}, {}),
  stage('b1', 'setHeader', '⊤', 'Gắn dấu cấp mới', { name: 'lgspPhanLoai', expression: 'CAP_MOI' }, {}),
  stage('b2', 'setHeader', '⊤', 'Gắn dấu chỉnh lý', { name: 'lgspPhanLoai', expression: 'CHINH_LY' }, {}),
  // Bộ chuyển đổi chưa đăng ký — sinh lỗi chặn việc gửi duyệt.
  stage('s7', 'xslt', '⇄', 'Chuyển đổi định dạng', {}, {
    uri: 'xslt:transforms/cdm-to-datdai-v3.xsl',
  }),
  stage('s8', 'http', '⊞', 'Gửi tới hệ thống đích', { httpMethod: 'POST' }, {
    uri: 'http://adapter-csdl-datdai.lgsp.svc:8080/api/v1/thua-dat',
  }),
  stage('s9', 'wireTap', '⑃', 'Ghi vết', { uri: 'kafka:lgsp.audit.trace' }, { locked: true }),
];

export const INITIAL_EDGES: SeqEdge[] = [
  { id: 'e1', source: 's1', target: 's2', type: 'seq' },
  { id: 'e2', source: 's2', target: 's3', type: 'seq' },
  { id: 'e3', source: 's3', target: 's4', type: 'seq' },
  { id: 'e4', source: 's4', target: 's5', type: 'seq' },
  { id: 'e5', source: 's5', target: 's6', type: 'seq' },
  { id: 'e6', source: 's6', target: 'b1', type: 'seq', data: { when: "${header.loaiHoSo} == 'CAP_MOI'" } },
  { id: 'e7', source: 's6', target: 'b2', type: 'seq', data: { when: "${header.loaiHoSo} == 'CHINH_LY'" } },
  { id: 'e8', source: 'b1', target: 's7', type: 'seq' },
  { id: 'e9', source: 'b2', target: 's7', type: 'seq' },
  { id: 'e10', source: 's7', target: 's8', type: 'seq' },
  { id: 'e11', source: 's8', target: 's9', type: 'seq' },
];

/** Bộ chuyển đổi đã đăng ký trong sổ đăng ký của nền tảng (PH-04). */
export const REGISTERED_CONVERTERS = [
  'transforms/cdm-to-datdai-v2.xsl',
  'transforms/cdm-to-hotich-v1.xsl',
  'transforms/cdm-to-dangky-kinhdoanh-v1.xsl',
];
