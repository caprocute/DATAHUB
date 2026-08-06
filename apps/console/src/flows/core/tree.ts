/**
 * Mô hình cây cho tài nguyên Camel (K1 — IP-07).
 *
 * Thay mô hình phẳng `StageNode[]`/`SeqEdge[]` ở `model.ts`. Lý do đổi, đo bằng
 * round-trip thật trên bộ mẫu: mô hình phẳng **không có chỗ biểu diễn cây con**, nên
 * `doTry`/`loadBalance`/`multicast`/`split` quay vòng ra khối rỗng — mất cả nhánh xử lý
 * lỗi lẫn nhánh cân tải, mà bộ đọc vẫn báo thành công (lỗi #6, xem IP-07 §3.0).
 *
 * Nguyên tắc của tệp này:
 *  - **Cây là nguồn sự thật**, sơ đồ chỉ là một cách chiếu. XYFlow giữ nguyên (ADR-017),
 *    chỉ đổi nguồn dữ liệu — `flatten.ts` lo việc chiếu.
 *  - **Không sinh mã tăng dần.** Mỗi node định danh bằng **đường dẫn** trong cây
 *    (`route[0].from.steps[2].choice.when[0].steps[1]`). Bộ đếm dùng chung phạm vi
 *    mô-đun chính là lỗi #2 của IP-06 — bỏ hẳn thì lớp lỗi đó biến mất.
 *  - **Không đoán.** Khóa nào không hiểu thì **giữ nguyên** trong `rest`, không vứt.
 */

/** Loại tài nguyên tương ứng một tệp YAML. */
export type ResourceKind = 'Route' | 'Kamelet' | 'Pipe' | 'Test';

/**
 * Một bước trong luồng.
 *
 * `name` là khóa DSL trần (`to`, `log`, `choice`, `doTry`…). `props` giữ các khóa vô hướng.
 * `branches` giữ **mọi cây con** — đây là điều mô hình phẳng không làm được.
 */
export interface StepNode {
  /** Khóa DSL, ví dụ `to` / `choice` / `doTry`. */
  name: string;
  /** Đường dẫn duy nhất trong cây; dùng thay cho mã sinh tăng dần. */
  path: string;
  /** Thuộc tính vô hướng của bước. */
  props: Record<string, string | number | boolean>;
  /**
   * Các nhánh con, theo tên khe cắm trong DSL.
   *
   * Ví dụ `doTry` có `steps` / `doCatch` / `doFinally`; `choice` có `when` / `otherwise`.
   * Giữ nguyên tên khe để lúc ghi ra trả đúng chỗ cũ.
   */
  branches: Branch[];
  /**
   * Khóa chưa hiểu, **giữ nguyên để ghi trả lại**.
   *
   * Thà ghi dư còn hơn nuốt mất cấu hình người dùng — đúng bài học lỗi #5/#6.
   */
  rest: Record<string, unknown>;
}

/** Một khe nhánh của bước (`steps`, `doCatch`, `when`, `otherwise`…). */
export interface Branch {
  /** Tên khe trong DSL. */
  slot: string;
  /** Khe dạng danh sách (`doCatch: [...]`) hay khe đơn (`otherwise: {...}`). */
  list: boolean;
  /** Thuộc tính của chính khe, ví dụ `when` có `expression`, `doCatch` có `exception`. */
  props: Record<string, unknown>;
  steps: StepNode[];
  path: string;
}

/** Một thực thể vẽ được: route, kamelet template, pipe… */
export interface VisualEntity {
  /** Khóa DSL cấp cao nhất: `route`, `routeConfiguration`, `template`… */
  kind: string;
  id: string;
  path: string;
  /** Chặng tiếp nhận. `undefined` với thực thể không có `from` (vd `routeConfiguration`). */
  from?: { uri: string; props: Record<string, unknown>; path: string };
  steps: StepNode[];
  /** Khóa cấp thực thể chưa hiểu — giữ nguyên. */
  rest: Record<string, unknown>;
}

/** Toàn bộ một tệp YAML. */
export interface CamelResource {
  kind: ResourceKind;
  entities: VisualEntity[];
  /** `metadata` của Kamelet/Pipe (K5). */
  metadata?: Record<string, unknown>;
  /** `beans` cấp tệp (K5). */
  beans: unknown[];
  /** Khóa cấp tệp chưa hiểu — giữ nguyên. */
  rest: Record<string, unknown>;
}

/* ---------- Khe nhánh theo từng mẫu EIP ---------- */

/**
 * Khe nhánh của các mẫu EIP có cây con.
 *
 * Lấy theo DSL Camel thật. Mẫu **không** có trong bảng này mà vẫn mang khóa `steps`
 * thì `deserialize` vẫn đọc được nhờ luật chung — bảng này chỉ để biết khe nào là
 * **danh sách các khối** (`doCatch`, `when`) thay vì danh sách bước phẳng.
 */
export const BRANCH_SLOTS: Record<string, { slot: string; list: boolean }[]> = {
  choice: [
    { slot: 'when', list: true },
    { slot: 'otherwise', list: false },
  ],
  doTry: [
    { slot: 'steps', list: false },
    { slot: 'doCatch', list: true },
    { slot: 'doFinally', list: false },
  ],
  split: [{ slot: 'steps', list: false }],
  multicast: [{ slot: 'steps', list: false }],
  loadBalance: [{ slot: 'steps', list: false }],
  loop: [{ slot: 'steps', list: false }],
  filter: [{ slot: 'steps', list: false }],
  aggregate: [{ slot: 'steps', list: false }],
  onException: [{ slot: 'steps', list: false }],
  onCompletion: [{ slot: 'steps', list: false }],
  circuitBreaker: [
    { slot: 'steps', list: false },
    { slot: 'onFallback', list: false },
  ],
  saga: [{ slot: 'steps', list: false }],
  transacted: [{ slot: 'steps', list: false }],
  policy: [{ slot: 'steps', list: false }],
  idempotentConsumer: [{ slot: 'steps', list: false }],
  resequence: [{ slot: 'steps', list: false }],
  step: [{ slot: 'steps', list: false }],
  whenSkipSendToEndpoint: [{ slot: 'steps', list: false }],
  pipeline: [{ slot: 'steps', list: false }],
};

/** Mẫu có cây con hay không. */
export function hasBranches(name: string): boolean {
  return name in BRANCH_SLOTS;
}

/* ---------- Đi trên cây ---------- */

/** Duyệt mọi bước trong cây theo thứ tự trước (kể cả bước lồng). */
export function* walkSteps(steps: StepNode[]): Generator<StepNode> {
  for (const s of steps) {
    yield s;
    for (const b of s.branches) yield* walkSteps(b.steps);
  }
}

/** Mọi bước của một thực thể. */
export function* walkEntity(e: VisualEntity): Generator<StepNode> {
  yield* walkSteps(e.steps);
}

/** Tìm bước theo đường dẫn. */
export function findByPath(res: CamelResource, path: string): StepNode | undefined {
  for (const e of res.entities) {
    for (const s of walkEntity(e)) if (s.path === path) return s;
  }
  return undefined;
}

/** Đếm tổng số bước, dùng cho kiểm tra và hiển thị. */
export function countSteps(res: CamelResource): number {
  let n = 0;
  for (const e of res.entities) for (const _ of walkEntity(e)) n += 1;
  return n;
}
