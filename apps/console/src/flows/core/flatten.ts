/**
 * Chiếu cây `CamelResource` xuống sơ đồ XYFlow (K1-6 — IP-07).
 *
 * **Cây là nguồn sự thật; sơ đồ chỉ là một cách nhìn.** ADR-017 giữ nguyên — XYFlow vẫn
 * là động cơ vẽ, chỉ đổi nguồn dữ liệu. Mọi sửa đổi phải quay về cây rồi chiếu lại, chứ
 * không sửa thẳng trên `StageNode[]` như lõi cũ; đó là cách giữ cho cây con
 * (`doTry`/`doCatch`/`when`) không bị bào mòn dần qua mỗi lần lưu — đúng lỗi #6.
 *
 * Định danh node dùng **đường dẫn trong cây** (`[0].route.from.steps[2]`) thay cho mã sinh
 * tăng dần, nên lỗi #2 của IP-06 (trùng mã) không còn cửa xảy ra.
 */

import { lookupNode, refName, toneOfNode, type NodeTone } from './catalog';
import { NODE_H, NODE_W, type SeqEdge, type StageData, type StageNode } from './model';
import { type Branch, type CamelResource, type StepNode, type VisualEntity } from './tree';

/** Khoảng cách giữa các chặng khi tự xếp. */
const DX = NODE_W + 60;
const DY = NODE_H + 48;

export interface FlatGraph {
  nodes: StageNode[];
  edges: SeqEdge[];
}

/** Ngữ cảnh xếp chỗ khi đi trên cây. */
interface Layout {
  nodes: StageNode[];
  edges: SeqEdge[];
  /** Cột hiện tại (theo chiều ngang). */
  col: number;
  /** Hàng hiện tại — nhánh con đẩy xuống hàng dưới. */
  row: number;
  maxRow: number;
}

function icon(tone: NodeTone): string {
  return { trigger: '⇥', auth: '✓', eip: '⑂', transform: '◇', enrich: '◉', dest: '⊞' }[tone];
}

/** Dựng `StageData` cho một bước trong cây. */
function dataFor(step: StepNode, role: 'from' | 'step'): StageData {
  const entry = lookupNode(step.name);
  const tone = toneOfNode(entry, role);
  const props: Record<string, string | number | boolean> = {};
  for (const [k, v] of Object.entries(step.props)) props[k] = v;

  const uri = typeof step.props.uri === 'string' ? step.props.uri : undefined;

  return {
    ref: entry ? `${entry.kind}/${entry.name}` : step.name,
    label: entry?.title ?? step.name,
    icon: icon(tone),
    role,
    uri,
    props,
    locked: false,
    tone,
  };
}

function pushNode(lay: Layout, step: StepNode, role: 'from' | 'step'): string {
  const id = step.path;
  lay.nodes.push({
    id,
    type: 'stage',
    position: { x: lay.col * DX, y: lay.row * DY },
    width: NODE_W,
    height: NODE_H,
    // Khai sẵn `measured`: React Flow v12 giữ nút ở `visibility: hidden` cho tới khi đo
    // xong, nút tạo bằng mã không phải lúc nào cũng kích hoạt được vòng đo (lỗi #3).
    measured: { width: NODE_W, height: NODE_H },
    data: dataFor(step, role),
  });
  lay.col += 1;
  return id;
}

function link(lay: Layout, source: string, target: string, data?: SeqEdge['data']): void {
  lay.edges.push({ id: `${source}->${target}`, source, target, type: 'seq', data });
}

/**
 * Chiếu một dãy bước, trả mã node đầu và cuối.
 *
 * Nhánh con của EIP được chiếu **xuống hàng dưới** và nối từ chính node EIP, nên nhìn
 * sơ đồ vẫn thấy được cấu trúc lồng thay vì bị duỗi phẳng thành một hàng.
 */
function projectSteps(lay: Layout, steps: StepNode[]): { head?: string; tail?: string } {
  let head: string | undefined;
  let prev: string | undefined;

  for (const step of steps) {
    const id = pushNode(lay, step, 'step');
    if (!head) head = id;
    if (prev) link(lay, prev, id);
    prev = id;

    for (const b of step.branches) projectBranch(lay, id, b);
  }
  return { head, tail: prev };
}

/** Chiếu một nhánh con: đẩy xuống hàng dưới, nối từ node cha. */
function projectBranch(lay: Layout, parentId: string, branch: Branch): void {
  if (!branch.steps.length) return;

  const savedCol = lay.col;
  lay.maxRow += 1;
  const savedRow = lay.row;
  lay.row = lay.maxRow;
  // Nhánh bắt đầu ngay dưới node cha.
  lay.col = savedCol - 1;

  const { head } = projectSteps(lay, branch.steps);
  if (head) {
    const when = typeof branch.props.expression === 'string' ? branch.props.expression : undefined;
    link(lay, parentId, head, {
      when: branch.slot === 'when' ? when : undefined,
      otherwise: branch.slot === 'otherwise' ? true : undefined,
      slot: branch.slot,
    });
  }

  lay.row = savedRow;
  lay.col = savedCol;
}

/** Chiếu một thực thể (một route) xuống sơ đồ. */
export function flattenEntity(entity: VisualEntity): FlatGraph {
  const lay: Layout = { nodes: [], edges: [], col: 0, row: 0, maxRow: 0 };

  let prev: string | undefined;
  if (entity.from) {
    const fromStep: StepNode = {
      name: schemeOf(entity.from.uri),
      path: entity.from.path,
      props: { uri: entity.from.uri },
      branches: [],
      rest: {},
    };
    prev = pushNode(lay, fromStep, 'from');
  }

  const { head, tail } = projectSteps(lay, entity.steps);
  if (prev && head) link(lay, prev, head);

  void tail;
  return { nodes: lay.nodes, edges: lay.edges };
}

/** Chiếu thực thể đầu tiên của tài nguyên — lối dùng thường gặp nhất. */
export function flatten(res: CamelResource, entityIndex = 0): FlatGraph {
  const entity = res.entities[entityIndex];
  if (!entity) return { nodes: [], edges: [] };
  return flattenEntity(entity);
}

/** Suy tên thành phần từ URI (`kafka:chu-de` → `kafka`) để tra danh mục. */
function schemeOf(uri: string): string {
  const scheme = uri.split(':')[0];
  return lookupNode(scheme) ? scheme : 'to';
}

/** Tên hiển thị của một thực thể trên danh sách route. */
export function entityLabel(e: VisualEntity): string {
  return e.id || refName(e.kind);
}
