/**
 * YAML → cây `CamelResource` (K1 — IP-07).
 *
 * Thay `parse.ts`. Khác biệt cốt lõi so với bộ đọc cũ:
 *
 *  1. **Không còn khái niệm "ngoài tập con".** Bộ cũ chỉ đọc được một `route` với `from`
 *     + `steps` phẳng; gặp `doTry`/`loadBalance` thì *báo thành công* rồi **vứt cây con**
 *     (lỗi #6). Ở đây mọi cây con đều vào `branches`, khóa lạ vào `rest`.
 *  2. **Dùng thư viện `yaml`** thay bộ đọc tự viết, nên giữ được comment và mọi cú pháp
 *     YAML thật (anchor, chuỗi nhiều dòng, tài liệu nhiều phần).
 *  3. **Không sinh mã tăng dần** — định danh bằng đường dẫn trong cây (bỏ hẳn lỗi #2).
 */

import { parseDocument, type Document } from 'yaml';
import { EXPR_LANGS } from './expression';
import {
  BRANCH_SLOTS,
  type Branch,
  type CamelResource,
  type ResourceKind,
  type StepNode,
  type VisualEntity,
} from './tree';

export class DeserializeError extends Error {
  constructor(
    message: string,
    readonly line?: number,
  ) {
    super(message);
    this.name = 'DeserializeError';
  }
}

type Rec = Record<string, unknown>;

function isRec(v: unknown): v is Rec {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/** Tách khóa vô hướng (vào `props`) khỏi khóa cấu trúc (giữ lại cho nơi gọi xử lý). */
function splitProps(
  src: Rec,
  structural: Set<string>,
): { props: Record<string, string | number | boolean>; rest: Rec } {
  const props: Record<string, string | number | boolean> = {};
  const rest: Rec = {};
  for (const [k, v] of Object.entries(src)) {
    if (structural.has(k)) continue;
    if (typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean') props[k] = v;
    // Khóa không vô hướng và không phải cấu trúc: giữ nguyên để ghi trả lại.
    else if (v !== undefined) rest[k] = v;
  }
  return { props, rest };
}

/**
 * Rút biểu thức kèm ngôn ngữ.
 *
 * Giống `exprOfWithLang` ở `parse.ts` — giữ **ngôn ngữ** chứ không chỉ giá trị, vì ghi lại
 * bằng ngôn ngữ khác là đổi ngữ nghĩa (lỗi #5).
 */
export function readExpr(v: unknown): { value: string; lang: string } | undefined {
  if (typeof v === 'string') return { value: v, lang: 'simple' };
  if (isRec(v)) {
    for (const lang of EXPR_LANGS) {
      const e = v[lang];
      if (typeof e === 'string') return { value: e, lang };
      if (isRec(e) && typeof e.expression === 'string') return { value: e.expression, lang };
    }
  }
  return undefined;
}

/** Đọc một danh sách bước. */
function readSteps(raw: unknown, path: string): StepNode[] {
  if (!Array.isArray(raw)) return [];
  const out: StepNode[] = [];
  raw.forEach((item, i) => {
    if (!isRec(item)) return;
    // Mỗi phần tử `steps` là map một khóa: `{ to: {...} }`.
    const name = Object.keys(item)[0];
    if (!name) return;
    const body = item[name];
    out.push(readStep(name, body, `${path}[${i}]`));
  });
  return out;
}

/** Đọc một bước và toàn bộ cây con của nó. */
function readStep(name: string, body: unknown, path: string): StepNode {
  // Dạng rút gọn `- to: "direct:x"`.
  if (typeof body === 'string') {
    return { name, path, props: { uri: body }, branches: [], rest: {} };
  }
  if (!isRec(body)) {
    return { name, path, props: {}, branches: [], rest: {} };
  }

  const slots = BRANCH_SLOTS[name] ?? [];
  const structural = new Set(slots.map((s) => s.slot));
  // `steps` luôn là khe nhánh kể cả với mẫu không khai trong bảng — luật chung, để
  // mẫu lạ vẫn giữ được cây con thay vì rơi mất.
  if ('steps' in body) structural.add('steps');

  const branches: Branch[] = [];
  for (const { slot, list } of slots) {
    if (!(slot in body)) continue;
    if (list) {
      // Khe danh sách khối (`when: [...]`, `doCatch: [...]`): **mỗi khối một Branch**.
      // Giữ đúng số khối và thứ tự, vì `when` thứ hai là một điều kiện định tuyến khác
      // hẳn — gộp lại là mất luật nghiệp vụ.
      const blocks = Array.isArray(body[slot]) ? (body[slot] as unknown[]) : [];
      blocks.forEach((blk, bi) => {
        branches.push(readBlockBranch(slot, blk, `${path}.${slot}[${bi}]`));
      });
    } else {
      branches.push(readBranch(slot, false, body[slot], `${path}.${slot}`));
    }
  }
  // Khe `steps` của mẫu ngoài bảng.
  if ('steps' in body && !slots.some((s) => s.slot === 'steps')) {
    branches.push(readBranch('steps', false, body.steps, `${path}.steps`));
  }

  const { props, rest } = splitProps(body, structural);

  // Biểu thức: giữ giá trị **và** ngôn ngữ (lỗi #5).
  const expr = readExpr(body.expression) ?? readExpr(body);
  if (expr) {
    props.expression = expr.value;
    props.exprLang = expr.lang;
    // Khóa ngôn ngữ đã được rút vào `expression` thì phải dọn ở **cả hai** chỗ:
    // `constant: "x"` là chuỗi nên `splitProps` xếp vào `props`, còn dạng đầy đủ
    // `simple: {expression: …}` mới vào `rest`. Bỏ sót một bên là ghi ra hai lần.
    delete rest.expression;
    for (const l of EXPR_LANGS) {
      delete rest[l];
      delete props[l];
    }
  }

  return { name, path, props, branches, rest };
}

/**
 * Đọc **một khối** của khe danh sách (`when[i]`, `doCatch[i]`).
 *
 * Thuộc tính của chính khối được giữ trong `props` — với `when` đó là `expression`
 * (điều kiện định tuyến), với `doCatch` là `exception` (danh sách lớp ngoại lệ).
 */
function readBlockBranch(slot: string, raw: unknown, path: string): Branch {
  const body = isRec(raw) ? raw : {};
  const { props, rest } = splitProps(body, new Set(['steps']));
  const merged: Record<string, unknown> = { ...rest, ...props };

  // `when` mang biểu thức — giữ cả ngôn ngữ như mọi chỗ khác (lỗi #5).
  const expr = readExpr(body.expression) ?? readExpr(body);
  if (expr) {
    merged.expression = expr.value;
    merged.exprLang = expr.lang;
    for (const l of EXPR_LANGS) delete merged[l];
  }

  return { slot, list: true, props: merged, steps: readSteps(body.steps, `${path}.steps`), path };
}

/** Đọc một khe nhánh đơn. */
function readBranch(slot: string, list: boolean, raw: unknown, path: string): Branch {
  // Khe đơn: có thể là danh sách bước thẳng (`steps: [...]`) hoặc khối có `steps`.
  if (Array.isArray(raw)) {
    return { slot, list, props: {}, steps: readSteps(raw, path), path };
  }
  if (isRec(raw)) {
    const { props } = splitProps(raw, new Set(['steps']));
    return { slot, list, props, steps: readSteps(raw.steps, `${path}.steps`), path };
  }
  return { slot, list, props: {}, steps: [], path };
}

/** Đọc một thực thể vẽ được (`route`, `routeConfiguration`, `template`…). */
function readEntity(kind: string, body: unknown, path: string): VisualEntity {
  if (!isRec(body)) return { kind, id: '', path, steps: [], rest: {} };

  const structural = new Set(['from', 'steps']);
  const { props, rest } = splitProps(body, structural);

  let from: VisualEntity['from'];
  if (isRec(body.from)) {
    const f = body.from;
    const uri = typeof f.uri === 'string' ? f.uri : '';
    const { rest: fRest } = splitProps(f, new Set(['steps', 'uri']));
    from = { uri, props: fRest, path: `${path}.from` };
  }

  // Bước nằm dưới `from.steps` (route) hoặc thẳng `steps` (routeConfiguration).
  const stepsRaw = isRec(body.from) ? body.from.steps : body.steps;
  const stepsPath = isRec(body.from) ? `${path}.from.steps` : `${path}.steps`;

  return {
    kind,
    id: typeof props.id === 'string' ? props.id : '',
    path,
    from,
    steps: readSteps(stepsRaw, stepsPath),
    rest: { ...rest, ...(props.id !== undefined ? {} : {}) },
  };
}

/** Khóa cấp cao nhất được coi là thực thể vẽ được. */
const ENTITY_KEYS = new Set([
  'route',
  'routeConfiguration',
  'routeTemplate',
  'templatedRoute',
  'rest',
  'onException',
  'errorHandler',
  'intercept',
  'interceptFrom',
  'interceptSendToEndpoint',
  'onCompletion',
]);

/** Suy ra loại tài nguyên từ nội dung tệp. */
function detectKind(root: unknown): ResourceKind {
  if (isRec(root)) {
    const k = root.kind;
    if (k === 'Kamelet') return 'Kamelet';
    if (k === 'Pipe' || k === 'KameletBinding') return 'Pipe';
    if (typeof k === 'string' && k.endsWith('Test')) return 'Test';
  }
  return 'Route';
}

/**
 * Đọc một tệp YAML về cây.
 *
 * Ném `DeserializeError` khi YAML **hỏng cú pháp**. Cấu trúc lạ thì **không** ném —
 * giữ nguyên trong `rest` để ghi trả lại, vì báo lỗi ở đây đồng nghĩa chặn người dùng
 * mở tệp hợp lệ mà bộ đọc chưa hiểu hết.
 */
export function deserialize(src: string): CamelResource {
  let doc: Document.Parsed;
  try {
    doc = parseDocument(src, { keepSourceTokens: false });
  } catch (e) {
    throw new DeserializeError(`YAML không hợp lệ: ${(e as Error).message}`);
  }
  if (doc.errors.length) {
    const err = doc.errors[0];
    throw new DeserializeError(`YAML không hợp lệ: ${err.message}`, err.linePos?.[0]?.line);
  }

  const root = doc.toJS({ maxAliasCount: -1 }) as unknown;
  const kind = detectKind(root);

  if (kind === 'Kamelet') return readKamelet(root as Rec);
  if (kind === 'Pipe') return readPipe(root as Rec);
  if (kind === 'Test') return readTest(root as Rec);

  // Tệp route: danh sách các khối cấp cao nhất.
  const list: unknown[] = Array.isArray(root) ? root : root == null ? [] : [root];
  const entities: VisualEntity[] = [];
  const beans: unknown[] = [];
  const rest: Rec = {};

  list.forEach((item, i) => {
    if (!isRec(item)) return;
    for (const [key, body] of Object.entries(item)) {
      if (key === 'beans' && Array.isArray(body)) {
        beans.push(...body);
        continue;
      }
      if (ENTITY_KEYS.has(key)) {
        entities.push(readEntity(key, body, `[${i}].${key}`));
      } else {
        rest[`[${i}].${key}`] = body;
      }
    }
  });

  return { kind: 'Route', entities, beans, rest };
}

/**
 * Test: `spec.route` + `spec.cases[]` (K3-4).
 *
 * Không có luồng để vẽ — giữ toàn bộ `spec` trong `rest` để `test-resource.ts` đọc/ghi.
 * Thiếu nhánh này thì tệp Test rơi vào lối đọc route và **mất sạch nội dung**: đã gặp
 * thật, tệp quay vòng ra `[]`.
 */
function readTest(root: Rec): CamelResource {
  return {
    kind: 'Test',
    entities: [],
    metadata: isRec(root.metadata) ? root.metadata : undefined,
    beans: [],
    rest: { apiVersion: root.apiVersion, kind: root.kind, spec: root.spec },
  };
}

/** Kamelet: `spec.template.from` + `spec.definition`. */
function readKamelet(root: Rec): CamelResource {
  const spec = isRec(root.spec) ? root.spec : {};
  const template = isRec(spec.template) ? spec.template : {};
  const entity = readEntity('template', template, 'spec.template');
  const { template: _t, ...specRest } = spec as Rec;
  return {
    kind: 'Kamelet',
    entities: [entity],
    metadata: isRec(root.metadata) ? root.metadata : undefined,
    beans: [],
    rest: { apiVersion: root.apiVersion, kind: root.kind, spec: specRest },
  };
}

/**
 * Pipe: `spec.source` → `spec.steps[]` → `spec.sink`.
 *
 * Dựng thành một thực thể tuyến tính để dùng chung bộ chiếu sơ đồ; `source`/`sink` là
 * tham chiếu Kamelet chứ không phải URI nên giữ nguyên trong `rest` của bước.
 */
function readPipe(root: Rec): CamelResource {
  const spec = isRec(root.spec) ? root.spec : {};
  const steps: StepNode[] = [];

  if (isRec(spec.source)) {
    steps.push({ name: 'source', path: 'spec.source', props: {}, branches: [], rest: spec.source });
  }
  if (Array.isArray(spec.steps)) {
    spec.steps.forEach((s, i) => {
      if (isRec(s)) {
        steps.push({ name: 'step', path: `spec.steps[${i}]`, props: {}, branches: [], rest: s });
      }
    });
  }
  if (isRec(spec.sink)) {
    steps.push({ name: 'sink', path: 'spec.sink', props: {}, branches: [], rest: spec.sink });
  }

  const { source: _s, sink: _k, steps: _st, ...specRest } = spec as Rec;
  return {
    kind: 'Pipe',
    entities: [{ kind: 'pipe', id: '', path: 'spec', steps, rest: {} }],
    metadata: isRec(root.metadata) ? root.metadata : undefined,
    beans: [],
    rest: { apiVersion: root.apiVersion, kind: root.kind, spec: specRest },
  };
}
