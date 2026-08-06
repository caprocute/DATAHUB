/**
 * Dựng ngược sơ đồ XYFlow về cây `CamelResource` (K1-6b — IP-07).
 *
 * **Vì sao cần tệp này.** Trình thiết kế hiện sửa trực tiếp trên `StageNode[]`/`SeqEdge[]`
 * ở 29 chỗ. Nếu chỉ đổi *bộ đọc* sang lõi cây mà vẫn để *bộ ghi* cũ chạy trên sơ đồ phẳng
 * thì không chỉ mất dữ liệu mà còn **bóp méo**: đo thật cho thấy `doTry` biến thành
 * `choice`, `doCatch` thành nhánh `when`, và lớp ngoại lệ biến mất — xử lý lỗi lặng lẽ
 * hóa thành định tuyến điều kiện. Tệp này khép vòng để chuyển đổi an toàn.
 *
 * **Nguyên tắc: cây gốc là nguồn sự thật.** Không dựng cây từ số không — lấy cây đã đọc
 * làm nền rồi **áp thay đổi từ sơ đồ** lên nó, nên mọi thứ sơ đồ không biểu diễn nổi
 * (khóa lạ trong `rest`, thuộc tính của khe, comment) đều còn nguyên.
 */

import type { SeqEdge, StageNode } from './model';
import type { Branch, CamelResource, StepNode, VisualEntity } from './tree';

/** Chỉ mục node theo mã (chính là đường dẫn trong cây). */
type NodeIndex = Map<string, StageNode>;

/**
 * Áp thuộc tính đã sửa trên sơ đồ vào một bước của cây.
 *
 * Chỉ đụng vào `props`; `branches` và `rest` giữ nguyên từ cây gốc.
 */
function applyStep(step: StepNode, idx: NodeIndex): StepNode {
  const node = idx.get(step.path);
  const next: StepNode = {
    ...step,
    branches: step.branches.map((b) => applyBranch(b, idx)),
  };
  if (node) {
    const props: Record<string, string | number | boolean> = {};
    for (const [k, v] of Object.entries(node.data.props)) props[k] = v;
    if (node.data.uri !== undefined) props.uri = node.data.uri;
    next.props = props;
  }
  return next;
}

function applyBranch(branch: Branch, idx: NodeIndex): Branch {
  return { ...branch, steps: branch.steps.map((s) => applyStep(s, idx)) };
}

/**
 * Bước bị **xóa trên sơ đồ** thì cũng phải biến khỏi cây.
 *
 * Không có bước này thì người dùng xóa chặng, bấm lưu, rồi thấy chặng quay lại —
 * còn khó hiểu hơn là không cho xóa.
 */
function pruneStep(step: StepNode, alive: Set<string>): StepNode | undefined {
  if (!alive.has(step.path)) return undefined;
  return {
    ...step,
    branches: step.branches.map((b) => ({
      ...b,
      steps: b.steps.map((s) => pruneStep(s, alive)).filter((s): s is StepNode => s !== undefined),
    })),
  };
}

function applyEntity(entity: VisualEntity, idx: NodeIndex, alive: Set<string>): VisualEntity {
  const next: VisualEntity = { ...entity };

  if (entity.from) {
    const fromNode = idx.get(entity.from.path);
    if (fromNode?.data.uri) next.from = { ...entity.from, uri: fromNode.data.uri };
  }

  next.steps = entity.steps
    .map((s) => pruneStep(s, alive))
    .filter((s): s is StepNode => s !== undefined)
    .map((s) => applyStep(s, idx));

  return next;
}

/**
 * Áp thay đổi từ sơ đồ lên cây.
 *
 * `base` là cây đọc lúc mở tệp. Trả về cây mới — **không** sửa tại chỗ, để nơi gọi so
 * sánh được trước/sau.
 *
 * Hạn chế đã biết: **chặng thêm mới trên sơ đồ chưa vào được cây** (chưa có đường dẫn
 * tương ứng). Thêm chặng là việc của K2 khi trình thiết kế sửa thẳng trên cây; ở bước
 * chuyển đổi này ưu tiên **không làm hỏng cấu trúc sẵn có**.
 */
export function applyGraphToTree(
  base: CamelResource,
  nodes: StageNode[],
  _edges: SeqEdge[],
  entityIndex = 0,
): CamelResource {
  const idx: NodeIndex = new Map(nodes.map((n) => [n.id, n]));
  const alive = new Set(nodes.map((n) => n.id));

  return {
    ...base,
    entities: base.entities.map((e, i) =>
      i === entityIndex ? applyEntity(e, idx, alive) : e,
    ),
  };
}

/** Chặng trên sơ đồ chưa có mặt trong cây — nơi gọi cần biết để cảnh báo. */
export function unmappedNodes(base: CamelResource, nodes: StageNode[]): StageNode[] {
  const known = new Set<string>();
  for (const e of base.entities) {
    if (e.from) known.add(e.from.path);
    collectPaths(e.steps, known);
  }
  return nodes.filter((n) => !known.has(n.id));
}

function collectPaths(steps: StepNode[], out: Set<string>): void {
  for (const s of steps) {
    out.add(s.path);
    for (const b of s.branches) collectPaths(b.steps, out);
  }
}
