/**
 * Cây `CamelResource` → YAML (K1 — IP-07).
 *
 * Thay `emit.ts`. Ba điều bộ cũ không làm được và ở đây là bắt buộc:
 *
 *  1. **Ghi trả cây con.** `doTry`/`loadBalance`/`multicast`/`split` giữ nguyên nhánh
 *     thay vì ra khối rỗng (lỗi #6).
 *  2. **Giữ comment.** Ghi đè lên tài liệu `yaml` gốc nên comment người vận hành viết —
 *     kể cả dòng xuất xứ `# routeCode=… version=…` do `GitOpsPublisher` sinh — còn nguyên.
 *  3. **Giữ ngôn ngữ biểu thức** đã đọc, không ép về `simple` (lỗi #5).
 */

import { Document, parseDocument, stringify } from 'yaml';
import { EXPR_LANGS } from './expression';
import type { Branch, CamelResource, StepNode, VisualEntity } from './tree';

type Rec = Record<string, unknown>;

/** Khóa nội bộ của trình thiết kế, **không phải trường Camel** — không được ghi ra. */
const INTERNAL_KEYS = new Set(['exprLang']);

function isRec(v: unknown): v is Rec {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/** Bỏ khóa rỗng để YAML không lẫn khóa vô nghĩa; giữ `0` và `false`. */
function clean(v: Rec): Rec {
  const out: Rec = {};
  for (const [k, val] of Object.entries(v)) {
    if (val === undefined || val === null || val === '') continue;
    if (INTERNAL_KEYS.has(k)) continue;
    out[k] = val;
  }
  return out;
}

/** Dựng khối biểu thức đúng ngôn ngữ đã đọc. */
function exprBlock(props: Rec, fallback = 'simple'): Rec | undefined {
  const value = props.expression;
  if (typeof value !== 'string' || value === '') return undefined;
  const lang = props.exprLang;
  const known = typeof lang === 'string' && (EXPR_LANGS as readonly string[]).includes(lang);
  return { [known ? lang : fallback]: value };
}

/** Một bước → khối YAML. */
function writeStep(s: StepNode): Rec {
  const body: Rec = { ...s.rest };

  for (const [k, v] of Object.entries(s.props)) {
    if (INTERNAL_KEYS.has(k) || k === 'expression') continue;
    body[k] = v;
  }

  const expr = exprBlock(s.props, s.name === 'enrich' || s.name === 'pollEnrich' ? 'constant' : 'simple');
  if (expr) body.expression = expr;

  // Cây con: trả đúng khe cũ. Khe danh sách gom lại theo tên khe, giữ thứ tự khối.
  const listSlots = new Map<string, Rec[]>();
  for (const b of s.branches) {
    if (b.list) {
      if (!listSlots.has(b.slot)) listSlots.set(b.slot, []);
      listSlots.get(b.slot)!.push(writeBlockBranch(b));
    } else {
      const steps = b.steps.map(writeStepEntry);
      // Khe đơn rỗng thì bỏ hẳn, trừ `steps` — bước rỗng vẫn phải hiện để không biến mất.
      if (!steps.length && b.slot !== 'steps') continue;
      // `steps` là **danh sách trần**, còn khe đơn khác (`otherwise`, `doFinally`,
      // `onFallback`) là **đối tượng bọc `steps`**. Ghi sai dạng thì Camel từ chối nạp
      // với `Unsupported type: SEQUENCE` — đã kiểm chứng trên Camel 4.18.2 thật.
      body[b.slot] = b.slot === 'steps' ? steps : clean({ ...b.props, steps });
    }
  }
  for (const [slot, blocks] of listSlots) body[slot] = blocks;

  return clean(body);
}

/** Một khối của khe danh sách (`when[i]`, `doCatch[i]`). */
function writeBlockBranch(b: Branch): Rec {
  const out: Rec = {};
  for (const [k, v] of Object.entries(b.props)) {
    if (INTERNAL_KEYS.has(k) || k === 'expression') continue;
    out[k] = v;
  }
  const expr = exprBlock(b.props as Rec);
  if (expr) out.expression = expr;
  out.steps = b.steps.map(writeStepEntry);
  return clean(out);
}

/** Bước thành phần tử trong danh sách `steps`: `{ ten: {...} }`. */
function writeStepEntry(s: StepNode): Rec {
  return { [s.name]: writeStep(s) };
}

/** Một thực thể → khối YAML. */
function writeEntity(e: VisualEntity): Rec {
  const body: Rec = { ...e.rest };
  if (e.id) body.id = e.id;

  const steps = e.steps.map(writeStepEntry);

  if (e.from) {
    body.from = clean({ ...e.from.props, uri: e.from.uri, steps });
  } else {
    body.steps = steps;
  }
  return clean(body);
}

/**
 * Ghi cây ra YAML, **giữ comment của tệp gốc**.
 *
 * `original` là nội dung tệp lúc mở. Có nó thì ghi đè lên chính tài liệu đó nên comment
 * và thứ tự khóa còn nguyên; không có (luồng dựng mới) thì sinh tài liệu mới.
 */
export function serialize(res: CamelResource, original?: string): string {
  if (res.kind === 'Kamelet') return writeKamelet(res, original);
  if (res.kind === 'Pipe') return writePipe(res, original);

  const list: Rec[] = [];
  if (res.beans.length) list.push({ beans: res.beans });
  for (const e of res.entities) list.push({ [e.kind]: writeEntity(e) });

  return withComments(list, original);
}

/**
 * Ghép nội dung mới vào tài liệu gốc để **không mất comment**.
 *
 * Đây là điểm khác biệt lớn nhất so với `emit.ts`: bộ cũ sinh chuỗi từ đầu nên comment
 * bị thay bằng banner mặc định — mất cả dòng xuất xứ kiểm toán mà nhìn tệp không nhận ra.
 */
function withComments(value: unknown, original?: string): string {
  if (!original) return stringify(value, { lineWidth: 0 });
  let doc: Document.Parsed;
  try {
    doc = parseDocument(original);
  } catch {
    return stringify(value, { lineWidth: 0 });
  }
  if (doc.errors.length) return stringify(value, { lineWidth: 0 });

  const fresh = new Document(value);
  fresh.commentBefore = doc.commentBefore ?? null;
  fresh.comment = doc.comment ?? null;

  // Với tệp route (danh sách ở cấp cao nhất), `yaml` gắn comment mở đầu vào **phần tử
  // đầu tiên**, không phải vào tài liệu — đây chính là chỗ `GitOpsPublisher` ghi dòng
  // xuất xứ `# routeCode=… version=…`. Bỏ qua chỗ này là mất dấu vết kiểm toán (BR-D-06).
  const srcFirst = firstItem(doc);
  const dstFirst = firstItem(fresh);
  if (srcFirst?.commentBefore && dstFirst) dstFirst.commentBefore = srcFirst.commentBefore;

  return fresh.toString({ lineWidth: 0 });
}

/** Phần tử đầu của tài liệu dạng danh sách — nơi `yaml` treo comment mở đầu. */
function firstItem(doc: Document): { commentBefore?: string | null } | undefined {
  const contents = doc.contents as unknown as { items?: unknown[] } | null;
  const items = contents?.items;
  if (!Array.isArray(items) || !items.length) return undefined;
  return items[0] as { commentBefore?: string | null };
}

function writeKamelet(res: CamelResource, original?: string): string {
  const e = res.entities[0];
  const rest = res.rest as Rec;
  const spec = isRec(rest.spec) ? { ...rest.spec } : {};
  const steps = e ? e.steps.map(writeStepEntry) : [];
  spec.template = e?.from
    ? { from: clean({ ...e.from.props, uri: e.from.uri, steps }) }
    : { from: { steps } };

  return withComments(
    clean({
      apiVersion: rest.apiVersion ?? 'camel.apache.org/v1',
      kind: 'Kamelet',
      metadata: res.metadata,
      spec,
    }),
    original,
  );
}

function writePipe(res: CamelResource, original?: string): string {
  const e = res.entities[0];
  const rest = res.rest as Rec;
  const spec = isRec(rest.spec) ? { ...rest.spec } : {};

  const mid: Rec[] = [];
  for (const s of e?.steps ?? []) {
    if (s.name === 'source') spec.source = s.rest;
    else if (s.name === 'sink') spec.sink = s.rest;
    else mid.push(s.rest as Rec);
  }
  if (mid.length) spec.steps = mid;

  return withComments(
    clean({
      apiVersion: rest.apiVersion ?? 'camel.apache.org/v1',
      kind: 'Pipe',
      metadata: res.metadata,
      spec,
    }),
    original,
  );
}
