import type { Edge, Node } from '@xyflow/react';
import { lookupNode, refName, toneOfNode, type CatalogNode, type NodeTone } from './catalog';

/** Ánh xạ một trường nguồn sang trường đích (DataMapper). */
export interface FieldMapping {
  from: string;
  to: string;
}

export interface StageData extends Record<string, unknown> {
  /** Tham chiếu catalog dạng `kind/name`; luồng lưu cũ có thể là tên trần. */
  ref: string;
  label: string;
  icon: string;
  /** `from` là chặng tiếp nhận — mỗi luồng có đúng một chặng loại này. */
  role: 'from' | 'step';
  /** URI Camel, chỉ có ở chặng dựng trên thành phần. */
  uri?: string;
  props: Record<string, string | number | boolean>;
  mappings?: FieldMapping[];
  /** Chặng bắt buộc của khung chuẩn — không gỡ được (BR-D-01). */
  locked: boolean;
  tone: NodeTone;
  /** Bản tin mẫu gắn theo chặng; **không** đi vào định nghĩa triển khai (BR-D-03). */
  pinnedSample?: string;
  /** Ghi chú nghiệp vụ, hiện khi duyệt. */
  note?: string;
}

export type StageNode = Node<StageData, 'stage'>;

export interface SeqEdgeData extends Record<string, unknown> {
  /** Biểu thức điều kiện của nhánh `when`. */
  when?: string;
  /** Nhánh mặc định của `choice`. */
  otherwise?: boolean;
  /**
   * Tên khe nhánh trong DSL (`steps`, `doCatch`, `doFinally`, `when`, `otherwise`).
   *
   * Do `flatten.ts` (K1) đặt khi chiếu cây xuống sơ đồ — nhờ nó mà cạnh biết mình
   * thuộc nhánh nào để vẽ nhãn và để dựng ngược về đúng khe cũ.
   */
  slot?: string;
}

export type SeqEdge = Edge<SeqEdgeData>;

/* ---------- Sinh mã ---------- */

let seq = 0;

/**
 * Sinh mã chặng/cạnh mới.
 *
 * Bộ đếm ở phạm vi mô-đun nên dùng chung cả phiên. Nếu chỉ tăng dần từ 0 thì `n1`
 * sinh sau sẽ **trùng** `n1` mà bộ đọc YAML đã đặt; React Flow bỏ nút trùng mã và
 * nút mới hiện rỗng. Luôn gọi `bumpSeq` sau khi nạp một sơ đồ có sẵn.
 */
export function nextId(prefix = 'n'): string {
  seq += 1;
  return `${prefix}${seq}`;
}

/** Đẩy bộ đếm vượt mọi mã đang dùng để lần sinh sau không trùng. */
export function bumpSeq(ids: Iterable<string>): void {
  for (const id of ids) {
    const m = /(\d+)$/.exec(id);
    if (m) seq = Math.max(seq, Number(m[1]));
  }
}

/* ---------- Kích thước thẻ node ---------- */

/**
 * Kích thước thẻ node — **nguồn sự thật duy nhất**.
 *
 * Ba chỗ phải khớp nhau tuyệt đối, lệch một pixel là đường nối vẽ sai:
 *   1. hằng số này (báo cho React Flow qua `width`/`height`/`measured`),
 *   2. `.n8n-node { width }` trong `designer.css`,
 *   3. bộ sắp xếp `autoLayout` (nay import thẳng từ đây, không khai lại).
 *
 * React Flow neo cổng vào/ra theo kích thước **đã đo**, còn dagre đặt nút theo kích
 * thước ta khai với nó. Trước đây `layout.ts` khai riêng 220×68 trong khi chỗ này là
 * 240×72, nên mọi cạnh lệch 10px ngang và 2px dọc so với cổng thật.
 */
export const NODE_W = 240;
export const NODE_H = 72;

/**
 * Dựng một chặng mới.
 *
 * Khai sẵn `width`/`height`/`measured`: React Flow v12 giữ nút ở `visibility: hidden`
 * cho tới khi đo xong, mà nút tạo bằng mã không phải lúc nào cũng kích hoạt được
 * vòng đo — thiếu thì nút thêm vào **không hiện trên sơ đồ**.
 */
export function makeStage(
  node: CatalogNode,
  opts: { role?: 'from' | 'step'; position: { x: number; y: number }; label?: string } ,
): StageNode {
  const role = opts.role ?? 'step';
  const tone = toneOfNode(node, role);
  return {
    id: nextId('n'),
    type: 'stage',
    position: opts.position,
    width: NODE_W,
    height: NODE_H,
    measured: { width: NODE_W, height: NODE_H },
    data: {
      ref: `${node.kind}/${node.name}`,
      label: opts.label ?? node.title,
      icon: iconFor(tone),
      role,
      uri: node.scheme ? node.syntax : undefined,
      props: {},
      locked: false,
      tone,
    },
  };
}

function iconFor(tone: NodeTone): string {
  return { trigger: '⇥', auth: '✓', eip: '⑂', transform: '◇', enrich: '◉', dest: '⊞' }[tone];
}

/** Nhân bản một chặng: bỏ khóa và **không** mang theo bản tin mẫu của bản gốc. */
export function duplicateStage(source: StageNode, id: string): StageNode {
  return {
    id,
    type: 'stage',
    position: { x: source.position.x + NODE_W + 40, y: source.position.y + 40 },
    width: NODE_W,
    height: NODE_H,
    measured: { width: NODE_W, height: NODE_H },
    selected: true,
    data: {
      ...source.data,
      props: { ...source.data.props },
      mappings: source.data.mappings?.map((m) => ({ ...m })),
      label: `${source.data.label} (bản sao)`,
      role: 'step',
      locked: false,
      pinnedSample: undefined,
    },
  };
}

/* ---------- Bản tin mẫu ---------- */

/**
 * Bản tin mẫu hiệu lực của một chặng.
 *
 * Ưu tiên pin của chính chặng; thiếu thì lần ngược theo cạnh vào. Không có pin nào
 * thì trả `undefined` — giao diện hiện trạng thái rỗng, **không bịa dữ liệu mẫu**.
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
  return lookupNode(d.ref)?.title ?? refName(d.ref);
}

/* ---------- Khung chuẩn ---------- */

/** Bốn chặng bắt buộc của khung xương chuẩn (BR-04-001). */
export const MANDATORY_STAGES = ['Tiếp nhận', 'Kiểm tra lược đồ', 'Ủy quyền', 'Ghi vết'];

/** Bộ chuyển đổi đã đăng ký trong sổ đăng ký của nền tảng. */
export const REGISTERED_CONVERTERS = [
  'transforms/cdm-to-datdai-v2.xsl',
  'transforms/cdm-to-hotich-v1.xsl',
  'transforms/cdm-to-dangky-kinhdoanh-v1.xsl',
];

/** Chặng có nhiều đường ra hợp lệ; chặng khác nối lại là thay đường. */
export const BRANCHING = new Set(['choice', 'multicast', 'loadBalance', 'recipientList']);

/**
 * Luồng trống: chỉ có bốn chặng bắt buộc, nối tuần tự.
 *
 * Dùng khi tạo luồng mới — người dùng bổ sung phần nghiệp vụ vào giữa.
 */
export function emptyFlow(): { nodes: StageNode[]; edges: SeqEdge[] } {
  const specs: { ref: string; label: string; uri?: string; role?: 'from' | 'step' }[] = [
    { ref: 'component/rest', label: 'Tiếp nhận', uri: 'rest:get:/api/v1/tai-nguyen', role: 'from' },
    { ref: 'component/json-validator', label: 'Kiểm tra lược đồ', uri: 'json-validator:schema/tai-nguyen.json' },
    { ref: 'component/http', label: 'Ủy quyền', uri: 'http://opa.lgsp.svc:8181/v1/data/lgsp/authz' },
    { ref: 'pattern/wireTap', label: 'Ghi vết', uri: 'kafka:lgsp.audit.trace' },
  ];

  const nodes: StageNode[] = specs.map((s, i) => {
    const node = lookupNode(s.ref);
    const role = s.role ?? 'step';
    const tone = toneOfNode(node, role);
    return {
      id: nextId('n'),
      type: 'stage',
      position: { x: i * (NODE_W + 60), y: 0 },
      width: NODE_W,
      height: NODE_H,
      measured: { width: NODE_W, height: NODE_H },
      data: {
        ref: s.ref,
        label: s.label,
        icon: iconFor(tone),
        role,
        uri: s.uri,
        props: {},
        locked: true,
        tone,
      },
    };
  });

  const edges: SeqEdge[] = nodes.slice(0, -1).map((n, i) => ({
    id: nextId('e'),
    source: n.id,
    target: nodes[i + 1].id,
    type: 'seq',
  }));

  return { nodes, edges };
}
