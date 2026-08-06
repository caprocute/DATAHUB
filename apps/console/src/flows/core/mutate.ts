/**
 * Sửa cây `CamelResource` (K2 — IP-07).
 *
 * Gỡ hạn chế còn lại của K1: chặng **thêm mới** trên canvas chưa có đường dẫn nên chưa
 * vào được cây, buộc phải lùi về bộ sinh cũ. Ở đây mọi thao tác đều thực hiện **thẳng
 * trên cây**, nên sơ đồ chỉ còn là cách chiếu thuần túy.
 *
 * Nguyên tắc:
 *  - **Bất biến.** Mọi hàm trả cây mới, không sửa tại chỗ — để `useFlowHistory` hoàn tác
 *    được và để so sánh trước/sau.
 *  - **Đường dẫn tính lại sau mỗi thao tác.** Chèn một bước làm lệch chỉ số của mọi bước
 *    sau nó; giữ đường dẫn cũ sẽ khiến node trỏ nhầm chỗ. `reindex` chạy ở cuối mỗi thao tác.
 *  - **Không đụng `rest`.** Khóa lạ của bước là dữ liệu người dùng, thao tác cấu trúc
 *    không có quyền vứt.
 */

import type { Branch, CamelResource, StepNode, VisualEntity } from './tree';

/** Dựng lại đường dẫn cho cả cây sau khi cấu trúc đổi. */
export function reindex(res: CamelResource): CamelResource {
  return {
    ...res,
    entities: res.entities.map((e, i) => reindexEntity(e, entityPath(e, i))),
  };
}

function entityPath(e: VisualEntity, i: number): string {
  // Kamelet/Pipe có đường dẫn cố định theo cấu trúc tệp; route thì theo chỉ số danh sách.
  if (e.path.startsWith('spec')) return e.path;
  return `[${i}].${e.kind}`;
}

function reindexEntity(e: VisualEntity, path: string): VisualEntity {
  const stepsPath = e.from ? `${path}.from.steps` : `${path}.steps`;
  return {
    ...e,
    path,
    from: e.from ? { ...e.from, path: `${path}.from` } : undefined,
    steps: reindexSteps(e.steps, stepsPath),
  };
}

function reindexSteps(steps: StepNode[], base: string): StepNode[] {
  return steps.map((s, i) => reindexStep(s, `${base}[${i}]`));
}

function reindexStep(s: StepNode, path: string): StepNode {
  // Khe danh sách (`when`, `doCatch`) đánh số riêng theo từng khe.
  const perSlot = new Map<string, number>();
  return {
    ...s,
    path,
    branches: s.branches.map((b) => {
      if (!b.list) {
        return { ...b, path: `${path}.${b.slot}`, steps: reindexSteps(b.steps, `${path}.${b.slot}`) };
      }
      const n = perSlot.get(b.slot) ?? 0;
      perSlot.set(b.slot, n + 1);
      const bp = `${path}.${b.slot}[${n}]`;
      return { ...b, path: bp, steps: reindexSteps(b.steps, `${bp}.steps`) };
    }),
  };
}

/* ---------- Tìm chỗ ---------- */

/** Vị trí một bước trong cây: mảng chứa nó và chỉ số trong mảng đó. */
interface Slot {
  list: StepNode[];
  index: number;
}

/** Tìm mảng chứa bước có đường dẫn `path`, kèm chỉ số. */
function locate(steps: StepNode[], path: string): Slot | undefined {
  for (let i = 0; i < steps.length; i += 1) {
    if (steps[i].path === path) return { list: steps, index: i };
    for (const b of steps[i].branches) {
      const found = locate(b.steps, path);
      if (found) return found;
    }
  }
  return undefined;
}

/** Áp một phép biến đổi lên danh sách bước của thực thể đang chọn. */
function onEntity(
  res: CamelResource,
  entityIndex: number,
  fn: (steps: StepNode[]) => StepNode[],
): CamelResource {
  return reindex({
    ...res,
    entities: res.entities.map((e, i) => (i === entityIndex ? { ...e, steps: fn(e.steps) } : e)),
  });
}

/**
 * Sao chép sâu giá trị thuần dữ liệu (mảng/đối tượng trong `props` và `rest`).
 *
 * Sao chép nông là **không đủ**: `doCatch` mang `exception: [...]`, chia sẻ đúng mảng đó
 * giữa bản gốc và bản sao khiến thư viện `yaml` nhận ra hai nơi cùng trỏ một đối tượng và
 * ghi ra **anchor/alias** (`&a1` … `*a1`). YAML vẫn hợp lệ nhưng định nghĩa route trở nên
 * khó đọc và phụ thuộc vào việc nơi tiêu thụ có nở alias hay không — không đáng mạo hiểm
 * với tệp đem triển khai.
 */
function deepClone<T>(v: T): T {
  if (Array.isArray(v)) return v.map(deepClone) as unknown as T;
  if (v !== null && typeof v === 'object') {
    const out: Record<string, unknown> = {};
    for (const [k, val] of Object.entries(v as Record<string, unknown>)) out[k] = deepClone(val);
    return out as T;
  }
  return v;
}

/** Sao chép cây bước để sửa mà không đụng bản gốc. */
function cloneSteps(steps: StepNode[]): StepNode[] {
  return steps.map((s) => ({
    ...s,
    props: { ...s.props },
    rest: deepClone(s.rest),
    branches: s.branches.map((b) => ({
      ...b,
      props: deepClone(b.props),
      steps: cloneSteps(b.steps),
    })),
  }));
}

/* ---------- Thao tác ---------- */

/** Dựng một bước mới rỗng. Đường dẫn đặt tạm, `reindex` sẽ đặt lại cho đúng. */
export function newStep(name: string, props: StepNode['props'] = {}): StepNode {
  return { name, path: `tam/${name}`, props, branches: [], rest: {} };
}

/**
 * Chèn một bước **sau** bước có đường dẫn `afterPath`.
 *
 * `afterPath` không tìm thấy (hoặc rỗng) thì nối vào cuối danh sách gốc — đúng hành vi
 * người dùng mong đợi khi kéo một thành phần vào chỗ trống trên canvas.
 */
export function insertAfter(
  res: CamelResource,
  entityIndex: number,
  afterPath: string | undefined,
  step: StepNode,
): CamelResource {
  return insertAfterAt(res, entityIndex, afterPath, step).resource;
}

/**
 * Như `insertAfter` nhưng trả kèm **đường dẫn thật** của bước vừa chèn.
 *
 * Nơi gọi cần đường dẫn này để đặt làm mã node trên sơ đồ. Suy ngược bằng cách so sánh
 * tập đường dẫn trước/sau là **không đáng tin**: `reindex` đánh số lại nên bước cũ cũng
 * đổi đường dẫn, dễ nhận nhầm một bước đã dịch chỗ thành bước mới. Đánh dấu trực tiếp
 * bằng một khóa tạm rồi tìm lại thì chắc chắn.
 */
export function insertAfterAt(
  res: CamelResource,
  entityIndex: number,
  afterPath: string | undefined,
  step: StepNode,
): { resource: CamelResource; path?: string } {
  const MARK = '__lgsp_vua_chen__';
  const marked: StepNode = { ...step, rest: { ...step.rest, [MARK]: true } };

  const resource = onEntity(res, entityIndex, (steps) => {
    const next = cloneSteps(steps);
    const at = afterPath ? locate(next, afterPath) : undefined;
    if (at) at.list.splice(at.index + 1, 0, marked);
    else next.push(marked);
    return next;
  });

  let path: string | undefined;
  const strip = (steps: StepNode[]): StepNode[] =>
    steps.map((s) => {
      const hit = s.rest[MARK] === true;
      if (hit) path = s.path;
      const rest = { ...s.rest };
      delete rest[MARK];
      return { ...s, rest, branches: s.branches.map((b) => ({ ...b, steps: strip(b.steps) })) };
    });

  return {
    resource: {
      ...resource,
      entities: resource.entities.map((e, i) =>
        i === entityIndex ? { ...e, steps: strip(e.steps) } : e,
      ),
    },
    path,
  };
}

/** Chèn một bước vào **đầu** một khe nhánh (ví dụ thả vào trong `doCatch`). */
export function insertIntoBranch(
  res: CamelResource,
  entityIndex: number,
  branchPath: string,
  step: StepNode,
): CamelResource {
  return onEntity(res, entityIndex, (steps) => {
    const next = cloneSteps(steps);
    const branch = findBranch(next, branchPath);
    if (branch) branch.steps = [...branch.steps, step];
    return next;
  });
}

function findBranch(steps: StepNode[], path: string): Branch | undefined {
  for (const s of steps) {
    for (const b of s.branches) {
      if (b.path === path) return b;
      const deeper = findBranch(b.steps, path);
      if (deeper) return deeper;
    }
  }
  return undefined;
}

/** Xóa một bước (kèm toàn bộ cây con của nó). */
export function removeStep(
  res: CamelResource,
  entityIndex: number,
  path: string,
): CamelResource {
  return onEntity(res, entityIndex, (steps) => {
    const next = cloneSteps(steps);
    const at = locate(next, path);
    if (at) at.list.splice(at.index, 1);
    return next;
  });
}

/** Nhân bản một bước, chèn ngay sau bản gốc. */
export function duplicateStep(
  res: CamelResource,
  entityIndex: number,
  path: string,
): CamelResource {
  return onEntity(res, entityIndex, (steps) => {
    const next = cloneSteps(steps);
    const at = locate(next, path);
    if (!at) return next;
    const [copy] = cloneSteps([at.list[at.index]]);
    at.list.splice(at.index + 1, 0, copy);
    return next;
  });
}

/** Đổi thuộc tính của một bước. */
export function updateStepProps(
  res: CamelResource,
  entityIndex: number,
  path: string,
  props: StepNode['props'],
): CamelResource {
  return onEntity(res, entityIndex, (steps) => {
    const next = cloneSteps(steps);
    const at = locate(next, path);
    if (at) at.list[at.index] = { ...at.list[at.index], props: { ...props } };
    return next;
  });
}

/** Đổi chỗ hai bước trong cùng một danh sách (kéo thả sắp xếp lại). */
export function moveStep(
  res: CamelResource,
  entityIndex: number,
  path: string,
  delta: number,
): CamelResource {
  return onEntity(res, entityIndex, (steps) => {
    const next = cloneSteps(steps);
    const at = locate(next, path);
    if (!at) return next;
    const to = at.index + delta;
    if (to < 0 || to >= at.list.length) return next;
    const [moved] = at.list.splice(at.index, 1);
    at.list.splice(to, 0, moved);
    return next;
  });
}

/* ---------- Thao tác cấp thực thể (K2-1) ---------- */

/** Thêm một route mới vào tệp. */
export function addEntity(res: CamelResource, id: string, uri = 'direct:moi'): CamelResource {
  const entity: VisualEntity = {
    kind: 'route',
    id,
    path: 'tam',
    from: { uri, props: {}, path: 'tam.from' },
    steps: [],
    rest: {},
  };
  return reindex({ ...res, entities: [...res.entities, entity] });
}

/** Xóa một route khỏi tệp. */
export function removeEntity(res: CamelResource, entityIndex: number): CamelResource {
  return reindex({ ...res, entities: res.entities.filter((_, i) => i !== entityIndex) });
}

/** Nhân bản một route; mã mới do nơi gọi đặt để tránh trùng. */
export function duplicateEntity(
  res: CamelResource,
  entityIndex: number,
  newId: string,
): CamelResource {
  const src = res.entities[entityIndex];
  if (!src) return res;
  const copy: VisualEntity = {
    ...src,
    id: newId,
    from: src.from ? { ...src.from, props: { ...src.from.props } } : undefined,
    steps: cloneSteps(src.steps),
    rest: { ...src.rest },
  };
  const entities = [...res.entities];
  entities.splice(entityIndex + 1, 0, copy);
  return reindex({ ...res, entities });
}

/**
 * Đổi mã route và **cập nhật mọi tham chiếu trỏ tới nó** (K2-4).
 *
 * Route nội bộ được gọi qua `direct:`/`seda:` theo tên. Đổi mã mà không sửa nơi gọi là
 * làm đứt luồng khác trong cùng tệp — hỏng lặng lẽ, chỉ lộ ra lúc chạy. Trả về cả **số
 * tham chiếu đã sửa** để giao diện nói rõ cho người dùng thay vì âm thầm đổi.
 */
export function renameEntity(
  res: CamelResource,
  entityIndex: number,
  newId: string,
): { resource: CamelResource; updatedRefs: number } {
  const src = res.entities[entityIndex];
  if (!src) return { resource: res, updatedRefs: 0 };

  const oldFrom = src.from?.uri ?? '';
  const scheme = oldFrom.split(':')[0];
  // Chỉ đổi tham chiếu khi chặng tiếp nhận là điểm gọi nội bộ; `rest:`/`kafka:` thì
  // tên route không phải là địa chỉ nên không có gì để sửa.
  const internal = scheme === 'direct' || scheme === 'seda';
  const oldTarget = internal ? oldFrom : '';
  const newTarget = internal ? `${scheme}:${newId}` : '';

  let updatedRefs = 0;

  const entities = res.entities.map((e, i) => {
    const renamed = i === entityIndex ? { ...e, id: newId } : e;
    const withFrom =
      i === entityIndex && internal && renamed.from
        ? { ...renamed, from: { ...renamed.from, uri: newTarget } }
        : renamed;
    if (!oldTarget) return withFrom;
    return {
      ...withFrom,
      steps: retarget(withFrom.steps, oldTarget, newTarget, () => {
        updatedRefs += 1;
      }),
    };
  });

  return { resource: reindex({ ...res, entities }), updatedRefs };
}

/** Đổi mọi `uri` trỏ tới `from` cũ sang `to` mới, trong cả cây con. */
function retarget(steps: StepNode[], from: string, to: string, onHit: () => void): StepNode[] {
  return steps.map((s) => {
    const next: StepNode = {
      ...s,
      branches: s.branches.map((b) => ({ ...b, steps: retarget(b.steps, from, to, onHit) })),
    };
    if (typeof s.props.uri === 'string' && s.props.uri === from) {
      onHit();
      next.props = { ...s.props, uri: to };
    }
    return next;
  });
}
