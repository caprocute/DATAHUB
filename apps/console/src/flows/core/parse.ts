/**
 * Đọc ngược Camel YAML DSL về sơ đồ (FR-04-026 — round-trip hai chiều).
 *
 * Chỉ đọc **tập con** mà chính trình thiết kế sinh ra: một `route` với `from` và
 * danh sách `steps`, trong đó `choice` có `when` / `otherwise`. Cấu trúc ngoài tập
 * con (nhiều route trong một tệp, `doTry`, YAML anchor, chuỗi nhiều dòng) được báo
 * là **chưa đọc được** thay vì dựng ra sơ đồ sai — người dùng vẫn sửa YAML bằng tay
 * được, chỉ là sơ đồ không tự cập nhật cho tới khi cấu trúc quay về tập con.
 *
 * Bộ đọc này cố ý tự viết thay vì kéo thư viện YAML: đầu vào là YAML do chính
 * `emit.ts` sinh (thụt lề hai khoảng, không anchor, không tài liệu nhiều phần),
 * nên một bộ đọc nhỏ đủ dùng và không thêm phụ thuộc vào bundle.
 */

import { lookupNode, toneOfNode } from './catalog';
import { EXPR_LANGS } from './expression';
import { NODE_H, NODE_W, nextId, type SeqEdge, type StageData, type StageNode } from './model';

/* ---------- Bộ đọc YAML tối giản ---------- */

type Node = string | number | boolean | null | YMap | YList;
interface YMap {
  [k: string]: Node;
}
type YList = Node[];

interface Line {
  indent: number;
  text: string;
  no: number;
}

export class YamlParseError extends Error {
  constructor(
    message: string,
    readonly line?: number,
  ) {
    super(message);
    this.name = 'YamlParseError';
  }
}

function scalar(raw: string): Node {
  const s = raw.trim();
  if (s === '' ) return '';
  if (s === 'null' || s === '~') return null;
  if (s === 'true') return true;
  if (s === 'false') return false;
  if (s === '{}') return {};
  if (s === '[]') return [];
  if (/^'(?:[^']|'')*'$/.test(s)) return s.slice(1, -1).replace(/''/g, "'");
  if (/^"(?:[^"\\]|\\.)*"$/.test(s)) return s.slice(1, -1).replace(/\\(.)/g, '$1');
  if (/^-?\d+$/.test(s)) return Number(s);
  if (/^-?\d*\.\d+$/.test(s)) return Number(s);
  return s;
}

function readLines(src: string): Line[] {
  const out: Line[] = [];
  src.split('\n').forEach((raw, i) => {
    if (/^\s*(#.*)?$/.test(raw)) return; // bỏ dòng trống và chú thích
    if (/[|>]\s*$/.test(raw)) throw new YamlParseError('Chưa đọc được chuỗi nhiều dòng', i + 1);
    // Anchor `&ten` / tham chiếu `*ten` đứng đầu dòng hoặc ngay sau `khóa:`.
    if (/(^\s*|:\s+)[&*][\w-]+/.test(raw))
      throw new YamlParseError('Chưa đọc được anchor YAML', i + 1);
    out.push({ indent: raw.length - raw.trimStart().length, text: raw.trim(), no: i + 1 });
  });
  return out;
}

/** Dựng cây từ danh sách dòng, bắt đầu tại `i`, chỉ nhận dòng thụt sâu hơn `base`. */
function parseBlock(lines: Line[], i: number, base: number): { value: Node; next: number } {
  if (i >= lines.length) return { value: null, next: i };

  if (lines[i].text.startsWith('- ') || lines[i].text === '-') {
    const list: YList = [];
    let k = i;
    while (k < lines.length && lines[k].indent === base && (lines[k].text.startsWith('- ') || lines[k].text === '-')) {
      const rest = lines[k].text === '-' ? '' : lines[k].text.slice(2).trim();
      if (rest === '') {
        const r = parseBlock(lines, k + 1, base + 2);
        list.push(r.value);
        k = r.next;
        continue;
      }
      // `- khóa: giá trị` — phần tử là map bắt đầu ngay trên dòng gạch đầu dòng.
      if (/^[\w.-]+:/.test(rest)) {
        const virtual: Line[] = [{ indent: base + 2, text: rest, no: lines[k].no }];
        let k2 = k + 1;
        while (k2 < lines.length && lines[k2].indent >= base + 2) {
          virtual.push(lines[k2]);
          k2 += 1;
        }
        const r = parseBlock(virtual, 0, base + 2);
        list.push(r.value);
        k = k2;
        continue;
      }
      list.push(scalar(rest));
      k += 1;
    }
    return { value: list, next: k };
  }

  const map: YMap = {};
  let k = i;
  while (k < lines.length && lines[k].indent === base) {
    const m = /^([\w.$-]+):\s*(.*)$/.exec(lines[k].text);
    if (!m) throw new YamlParseError(`Không hiểu dòng: ${lines[k].text}`, lines[k].no);
    const [, key, rest] = m;
    if (rest !== '') {
      map[key] = scalar(rest);
      k += 1;
      continue;
    }
    const child = parseBlock(lines, k + 1, lines[k + 1] ? lines[k + 1].indent : base + 2);
    map[key] = child.value ?? {};
    k = child.next;
  }
  return { value: map, next: k };
}

export function parseYaml(src: string): Node {
  const lines = readLines(src);
  if (lines.length === 0) return null;
  return parseBlock(lines, 0, lines[0].indent).value;
}

/* ---------- Cây YAML sang sơ đồ ---------- */

function isMap(v: Node): v is YMap {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/** Khóa của một bước không phải tham số phụ. */
const NOT_A_STEP = new Set(['id', 'description', 'disabled']);

export interface ParsedGraph {
  nodes: StageNode[];
  edges: SeqEdge[];
}

function makeStage(ref: string, label: string, props: YMap, uri?: string, role: 'from' | 'step' = 'step'): StageData {
  const entry = lookupNode(ref);
  const flat: Record<string, string | number | boolean> = {};
  for (const [k, v] of Object.entries(props)) {
    if (v === null || isMap(v) || Array.isArray(v)) continue;
    flat[k] = v;
  }
  const tone = toneOfNode(entry, role);
  return {
    ref: entry ? `${entry.kind}/${entry.name}` : ref,
    label,
    icon: role === 'from' ? '⇥' : '⊞',
    role,
    uri,
    props: flat,
    locked: false,
    tone,
    catalogTitle: entry?.title ?? ref,
  };
}

/**
 * Rút biểu thức của một bước về chuỗi để hiện trên sơ đồ, **kèm ngôn ngữ**.
 *
 * Ngôn ngữ phải giữ lại: trước đây bộ đọc trả về mỗi chuỗi rồi bộ sinh mặc định
 * ghi lại thành `simple`, nên `constant: "x"` quay vòng thành `simple: "x"` —
 * đổi ngữ nghĩa mà không báo gì. Danh sách lấy đúng theo `schemas/language/`
 * (26 ngôn ngữ) thay vì năm cái đoán tay như bản cũ.
 */
export function exprOfWithLang(v: Node): { value: string; lang: string } | undefined {
  // Dạng rút gọn `expression: "..."` không nói ngôn ngữ; Camel hiểu là `simple`.
  if (typeof v === 'string') return { value: v, lang: 'simple' };
  if (isMap(v)) {
    for (const lang of EXPR_LANGS) {
      const e = v[lang];
      if (typeof e === 'string') return { value: e, lang };
      // Dạng đầy đủ `simple: { expression: "..." }` — còn mang `resultType`, `trim`…
      if (isMap(e) && typeof e.expression === 'string') return { value: e.expression, lang };
    }
  }
  return undefined;
}

/** Rút biểu thức về chuỗi (bỏ ngôn ngữ) — giữ cho nơi gọi chỉ cần hiển thị. */
function exprOf(v: Node): string | undefined {
  return exprOfWithLang(v)?.value;
}

interface Ctx {
  nodes: StageNode[];
  edges: SeqEdge[];
}

/** Dựng chuỗi bước; trả mã nút đầu và cuối của đoạn. */
function buildSteps(steps: YList, ctx: Ctx): { head?: string; tail?: string } {
  let head: string | undefined;
  let tail: string | undefined;

  const connect = (id: string) => {
    if (!head) head = id;
    else if (tail) ctx.edges.push({ id: nextId('e'), source: tail, target: id, type: 'seq' });
    tail = id;
  };

  for (const raw of steps) {
    if (!isMap(raw)) continue;
    const key = Object.keys(raw).find((k) => !NOT_A_STEP.has(k));
    if (!key) continue;
    const body = raw[key];
    const props: YMap = isMap(body) ? body : {};

    if (key === 'choice') {
      const id = nextId('n');
      ctx.nodes.push({
        id,
        type: 'stage',
        position: { x: 0, y: 0 },
        width: NODE_W,
        height: NODE_H,
        measured: { width: NODE_W, height: NODE_H },
        data: makeStage('choice', 'Định tuyến theo nội dung', {}),
      });
      connect(id);

      const whens = Array.isArray(props.when) ? props.when : [];
      const branchTails: string[] = [];
      for (const w of whens) {
        if (!isMap(w)) continue;
        const sub = buildSteps(Array.isArray(w.steps) ? w.steps : [], ctx);
        if (!sub.head) continue;
        ctx.edges.push({
          id: nextId('e'),
          source: id,
          target: sub.head,
          type: 'seq',
          data: { when: exprOf(w.expression) ?? '' },
        });
        if (sub.tail) branchTails.push(sub.tail);
      }
      const other = props.otherwise;
      if (isMap(other)) {
        const sub = buildSteps(Array.isArray(other.steps) ? other.steps : [], ctx);
        if (sub.head) {
          ctx.edges.push({
            id: nextId('e'),
            source: id,
            target: sub.head,
            type: 'seq',
            data: { otherwise: true },
          });
          if (sub.tail) branchTails.push(sub.tail);
        }
      }
      // Các nhánh hợp lại ở bước kế tiếp: đánh dấu bằng cách coi mọi đuôi nhánh là đuôi hiện tại.
      tail = branchTails.length === 1 ? branchTails[0] : (branchTails[branchTails.length - 1] ?? id);
      if (branchTails.length > 1) {
        // Nhiều nhánh: bước sau nối từ tất cả các đuôi để giữ đúng hình dạng hợp nhánh.
        (ctx as Ctx & { pendingJoins?: string[] }).pendingJoins = branchTails;
      }
      continue;
    }

    const uri = typeof props.uri === 'string' ? props.uri : undefined;
    const entry = lookupNode(key);
    const label = entry?.title ?? key;
    const params = isMap(props.parameters) ? props.parameters : props;
    // Biểu thức nằm ở một trong hai chỗ: lồng dưới `expression:`, hoặc **thẳng trên
    // chính bước** (`setBody: { constant: "x" }`) — dạng thứ hai trước đây bị bỏ qua
    // hoàn toàn nên giá trị rơi mất im lặng.
    const found = exprOfWithLang(props.expression) ?? exprOfWithLang(props);
    const merged: YMap = { ...params };
    if (found !== undefined) {
      merged.expression = found.value;
      // Giữ ngôn ngữ để bộ sinh ghi lại đúng thứ đã đọc, thay vì mặc định `simple`.
      merged.exprLang = found.lang;
      // Khóa ngôn ngữ ở cấp bước đã được rút vào `expression`; để lại sẽ ghi ra hai lần.
      for (const lang of EXPR_LANGS) delete merged[lang];
    }
    delete merged.uri;

    const id = nextId('n');
    ctx.nodes.push({
      id,
      type: 'stage',
      position: { x: 0, y: 0 },
      width: NODE_W,
      height: NODE_H,
      measured: { width: NODE_W, height: NODE_H },
      data: makeStage(key === 'to' && uri ? guessRef(uri) : key, label, merged, uri),
    });

    const joins = (ctx as Ctx & { pendingJoins?: string[] }).pendingJoins;
    if (joins?.length) {
      for (const j of joins) ctx.edges.push({ id: nextId('e'), source: j, target: id, type: 'seq' });
      (ctx as Ctx & { pendingJoins?: string[] }).pendingJoins = undefined;
      tail = id;
      if (!head) head = id;
      continue;
    }
    connect(id);
  }

  return { head, tail };
}

/** `to: { uri: 'kafka:...' }` — lấy scheme làm tên thành phần để tra danh mục. */
function guessRef(uri: string): string {
  const scheme = uri.split(':')[0];
  return lookupNode(scheme) ? scheme : 'to';
}

/**
 * Dựng lại sơ đồ từ Camel YAML DSL.
 *
 * Ném `YamlParseError` khi gặp cấu trúc ngoài tập con — nơi gọi phải báo cho người
 * dùng biết sơ đồ chưa cập nhật, **không** được im lặng giữ sơ đồ cũ.
 */
export function graphFromYaml(src: string): ParsedGraph {
  const doc = parseYaml(src);
  const list: YList = Array.isArray(doc) ? doc : doc === null ? [] : [doc];

  const routes = list.filter((d) => isMap(d) && isMap(d.route));
  if (routes.length === 0) throw new YamlParseError('Không tìm thấy khối `route` nào trong tệp');
  if (routes.length > 1) throw new YamlParseError('Tệp có nhiều route — trình thiết kế chỉ mở được một route');

  const route = (routes[0] as YMap).route as YMap;
  const from = route.from;
  if (!isMap(from)) throw new YamlParseError('Route thiếu khối `from`');

  const ctx: Ctx = { nodes: [], edges: [] };
  const uri = typeof from.uri === 'string' ? from.uri : '';
  const entry = lookupNode(uri.split(':')[0]);
  const fromId = nextId('n');
  ctx.nodes.push({
    id: fromId,
    type: 'stage',
    position: { x: 0, y: 0 },
    width: NODE_W,
    height: NODE_H,
    measured: { width: NODE_W, height: NODE_H },
    data: makeStage(entry?.name ?? 'rest', entry?.title ?? 'Tiếp nhận', isMap(from.parameters) ? from.parameters : {}, uri, 'from'),
  });

  const steps = Array.isArray(from.steps) ? from.steps : [];
  const built = buildSteps(steps, ctx);
  if (built.head) {
    ctx.edges.push({ id: nextId('e'), source: fromId, target: built.head, type: 'seq' });
  }

  return ctx;
}
