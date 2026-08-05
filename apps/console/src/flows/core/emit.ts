import { lookupNode, peekSchema, refName } from './catalog';
import { EXPR_LANGS } from './expression';
import { BRANCHING, type SeqEdge, type StageData, type StageNode } from './model';

/* ---------- Bộ ghi YAML tối giản ---------- */

type Scalar = string | number | boolean | null;
type Val = Scalar | Val[] | { [k: string]: Val };

const NEEDS_QUOTE = /[:#{}[\],&*!|>%@`"']|^\s|\s$|^$/;

function scalar(v: Scalar): string {
  if (v === null) return 'null';
  if (typeof v === 'boolean' || typeof v === 'number') return String(v);
  // URI Camel và biểu thức `${...}` đầy ký tự có nghĩa trong YAML — nháy đơn cho chắc.
  return NEEDS_QUOTE.test(v) ? `'${v.replace(/'/g, "''")}'` : v;
}

function isRecord(v: Val): v is { [k: string]: Val } {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/**
 * Bỏ giá trị trống để YAML không lẫn khóa vô nghĩa.
 *
 * Giữ lại đối tượng rỗng: chặng vừa thả vào chưa có thuộc tính nào vẫn phải hiện
 * `tênMẫu: {}`, nếu bỏ luôn thì chặng biến mất khỏi định nghĩa dù còn trên sơ đồ.
 */
function prune(v: Val): Val {
  if (Array.isArray(v)) return v.map(prune);
  if (isRecord(v)) {
    const out: { [k: string]: Val } = {};
    for (const [k, val] of Object.entries(v)) {
      if (val === undefined || val === '' || val === null) continue;
      out[k] = prune(val);
    }
    return out;
  }
  return v;
}

function write(v: Val, indent: number): string {
  const pad = ' '.repeat(indent);
  if (Array.isArray(v)) {
    return v
      .map((item) => {
        if (isRecord(item) || Array.isArray(item)) {
          const body = write(item, indent + 2);
          return `${pad}- ${body.slice(indent + 2)}`;
        }
        return `${pad}- ${scalar(item as Scalar)}`;
      })
      .join('\n');
  }
  if (isRecord(v)) {
    return Object.entries(v)
      .map(([k, val]) => {
        if (Array.isArray(val)) {
          return val.length ? `${pad}${k}:\n${write(val, indent + 2)}` : `${pad}${k}: []`;
        }
        if (isRecord(val)) {
          return Object.keys(val).length ? `${pad}${k}:\n${write(val, indent + 2)}` : `${pad}${k}: {}`;
        }
        return `${pad}${k}: ${scalar(val as Scalar)}`;
      })
      .join('\n');
  }
  return `${pad}${scalar(v as Scalar)}`;
}

/* ---------- Lọc thuộc tính theo lược đồ gốc ---------- */

/**
 * Chỉ giữ thuộc tính **có thật** trong lược đồ của mẫu EIP.
 *
 * Bản trước tự thêm `timeout` cho `enrich`; lược đồ Camel không có thuộc tính đó nên
 * khi nạp route Camel báo `Field: timeout has already been configured as an expression`
 * và **từ chối khởi động**. Lọc theo lược đồ chặn cả lớp lỗi này, không riêng `enrich`.
 *
 * Chưa nạp được lược đồ (chặng lạ, lược đồ đang tải) thì giữ nguyên thuộc tính —
 * thà sinh dư còn hơn nuốt mất cấu hình người dùng đã đặt.
 */
function schemaProps(
  ref: string,
  props: Record<string, string | number | boolean>,
  omit: string[] = [],
): { [k: string]: Val } {
  const node = lookupNode(ref);
  const schema = node ? peekSchema(node) : undefined;
  const allowed = schema?.properties ? new Set(Object.keys(schema.properties)) : null;

  const out: { [k: string]: Val } = {};
  for (const [k, v] of Object.entries(props)) {
    if (omit.includes(k)) continue;
    // `exprLang` là ghi chú nội bộ của trình thiết kế, **không phải trường Camel**.
    // Lọc thẳng ở đây vì khi chặng không có lược đồ thì `allowed` là null và mọi
    // khóa lọt qua — khi đó khóa này sẽ rơi vào YAML và Camel từ chối nạp route.
    if (k === 'exprLang') continue;
    if (allowed && !allowed.has(k)) continue;
    out[k] = v;
  }
  return out;
}

/* ---------- Sơ đồ sang Camel YAML DSL ---------- */

interface Graph {
  byId: Map<string, StageNode>;
  outs: Map<string, SeqEdge[]>;
  inDeg: Map<string, number>;
}

function buildGraph(nodes: StageNode[], edges: SeqEdge[]): Graph {
  const byId = new Map(nodes.map((n) => [n.id, n]));
  const outs = new Map<string, SeqEdge[]>();
  const inDeg = new Map<string, number>();
  for (const n of nodes) {
    outs.set(n.id, []);
    inDeg.set(n.id, 0);
  }
  for (const e of edges) {
    if (!byId.has(e.source) || !byId.has(e.target)) continue;
    outs.get(e.source)!.push(e);
    inDeg.set(e.target, (inDeg.get(e.target) ?? 0) + 1);
  }
  // Nhánh xếp trái→phải theo vị trí để YAML ổn định giữa các lần vẽ.
  for (const list of outs.values()) {
    list.sort((a, b) => (byId.get(a.target)?.position.x ?? 0) - (byId.get(b.target)?.position.x ?? 0));
  }
  return { byId, outs, inDeg };
}

/**
 * Dựng khối biểu thức, **giữ đúng ngôn ngữ đã đọc từ YAML**.
 *
 * Không có `exprLang` (chặng vừa dựng trên sơ đồ) thì dùng `simple` — đúng mặc định
 * của Camel cho dạng rút gọn. Cố ý **không** đoán ngôn ngữ theo hình dạng chuỗi ở đây:
 * đoán sai chính là cách `constant: "lgsp-camel-dancu:ok"` từng bị ghi thành `simple`,
 * đổi ngữ nghĩa mà không báo gì. Đoán chỉ dùng ở chỗ xem trước, không dùng lúc ghi.
 */
function exprWith(d: StageData, expr: string, fallback = 'simple'): Val {
  const lang = d.props.exprLang;
  const known = typeof lang === 'string' && (EXPR_LANGS as readonly string[]).includes(lang);
  return { [known ? (lang as string) : fallback]: expr };
}

/** Một chặng thành một phần tử trong danh sách `steps` của Camel. */
function stepFor(d: StageData): Val {
  const entry = lookupNode(d.ref);
  const p = d.props;
  // Chặng có thể mang `kind/name`; Camel DSL chỉ biết tên trần.
  const name = refName(d.ref);
  const expr = String(p.expression ?? '');
  // Ngôn ngữ do bộ đọc giữ lại; luồng dựng mới trên sơ đồ thì đoán theo hình dạng.
  const exprVal = exprWith(d, expr);

  switch (name) {
    case 'choice':
      // `choice` dựng riêng ở walk() vì còn phải gắn các nhánh.
      return { choice: {} };
    case 'setHeader':
      return { setHeader: { name: String(p.name ?? ''), expression: exprVal } };
    case 'setBody':
      return { setBody: { expression: exprVal } };
    case 'transform': {
      if (d.mappings?.length) {
        return {
          transform: {
            expression: { simple: d.mappings.map((m) => `${m.to} ← ${m.from}`).join('; ') },
            id: 'datamapper',
          },
        };
      }
      return { transform: { expression: exprVal } };
    }
    case 'filter':
      return { filter: { expression: exprVal } };
    case 'enrich':
      // Lược đồ `enrich` **không có** `timeout` — xem ghi chú ở `schemaProps`.
      // Mặc định `constant` (không phải `simple`) vì biểu thức ở đây là URI đích.
      return {
        enrich: {
          expression: exprWith(d, expr, 'constant'),
          ...schemaProps(d.ref, p, ['expression']),
        },
      };
    case 'pollEnrich':
      // `pollEnrich` thì có `timeout` thật (thời gian chờ lấy bản tin).
      return {
        pollEnrich: {
          expression: exprWith(d, expr, 'constant'),
          ...schemaProps(d.ref, p, ['expression']),
        },
      };
    case 'wireTap':
      return { wireTap: { uri: String(p.uri ?? d.uri ?? '') } };
    case 'log':
      return { log: { message: String(p.message ?? d.label) } };
    case 'to':
      return { to: { uri: String(p.uri ?? d.uri ?? '') } };
    default:
      break;
  }

  // Thành phần Camel luôn vào luồng qua `to`; mẫu EIP lấy chính tên mẫu làm khóa.
  if (entry?.kind === 'component' || entry?.kind === 'kamelet' || d.uri) {
    const params = schemaProps(d.ref, p);
    return {
      to: { uri: d.uri ?? '', ...(Object.keys(params).length ? { parameters: params } : {}) },
    };
  }
  return { [name]: schemaProps(d.ref, p) };
}

interface WalkResult {
  steps: Val[];
  joinAt: string | null;
}

/**
 * Đi theo cạnh, dựng danh sách `steps`.
 *
 * Gặp chặng có nhiều cạnh vào thì dừng và trả mã chặng đó: đấy là điểm các nhánh
 * `choice` hợp lại, luồng chính tiếp tục từ đó. Camel YAML không diễn đạt được
 * nhánh nối ngang nên hợp nhánh phải quy về một điểm chung.
 */
function walk(g: Graph, startId: string | null, seen: Set<string>): WalkResult {
  const steps: Val[] = [];
  let cur = startId;
  let resumeAt: string | null = null;

  while (cur) {
    const resuming = cur === resumeAt;
    resumeAt = null;

    if (seen.has(cur)) return { steps, joinAt: cur };
    if (!resuming && steps.length > 0 && (g.inDeg.get(cur) ?? 0) > 1) return { steps, joinAt: cur };

    const node = g.byId.get(cur);
    if (!node) break;
    seen.add(cur);

    const outs = g.outs.get(cur) ?? [];

    // Chặng rẽ nhánh phải sinh khối `choice` **kể cả khi mới có một nhánh**: xét theo
    // số cạnh thì `choice` một nhánh rơi xuống lối tuần tự bên dưới và điều kiện trên
    // cạnh **biến mất không báo lỗi** — luật định tuyến thành chặng chạy vô điều kiện.
    if (outs.length > 1 || (BRANCHING.has(refName(node.data.ref)) && outs.length > 0)) {
      const branches = outs.map((e) => ({ edge: e, res: walk(g, e.target, new Set(seen)) }));
      const whens: Val[] = [];
      let otherwise: Val | null = null;

      for (const b of branches) {
        if (b.edge.data?.otherwise) {
          otherwise = { steps: b.res.steps };
        } else {
          whens.push({ expression: { simple: String(b.edge.data?.when ?? '') }, steps: b.res.steps });
        }
      }

      const choice: { [k: string]: Val } = {};
      if (whens.length) choice.when = whens;
      if (otherwise) choice.otherwise = otherwise;
      steps.push({ choice });

      const joins = branches.map((b) => b.res.joinAt);
      const common = joins.every((j) => j && j === joins[0]) ? joins[0] : null;
      if (common) branches.forEach((b) => b.res.steps.length && seen.add(b.edge.target));
      resumeAt = common;
      cur = common;
      continue;
    }

    steps.push(stepFor(node.data));
    cur = outs[0]?.target ?? null;
  }

  return { steps, joinAt: null };
}

export interface EmitOptions {
  routeId: string;
  /** Bật nhánh xử lý lỗi dùng chung của nền tảng. */
  errorHandler?: boolean;
}

export function emitRouteYaml(nodes: StageNode[], edges: SeqEdge[], opts: EmitOptions): string {
  const g = buildGraph(nodes, edges);
  const fromNode = nodes.find((n) => n.data.role === 'from');

  if (!fromNode) {
    return '# Luồng chưa có chặng tiếp nhận — hãy kéo một thành phần ở nhóm "Điểm tiếp nhận" vào sơ đồ.\n';
  }

  const seen = new Set<string>([fromNode.id]);
  const firstEdge = (g.outs.get(fromNode.id) ?? [])[0];
  const { steps } = walk(g, firstEdge?.target ?? null, seen);

  const fromParams = schemaProps(fromNode.data.ref, fromNode.data.props);

  const doc: Val[] = [
    {
      route: {
        id: opts.routeId,
        from: {
          uri: fromNode.data.uri ?? '',
          ...(Object.keys(fromParams).length ? { parameters: fromParams } : {}),
          steps,
        },
      },
    },
  ];

  if (opts.errorHandler) {
    doc.push({
      onException: {
        exception: ['java.lang.Exception'],
        redeliveryPolicy: { maximumRedeliveries: 3, redeliveryDelay: 1000, backOffMultiplier: 2 },
        steps: [{ to: { uri: `kafka:lgsp.dlq.${opts.routeId}` } }],
      },
    });
  }

  const header = [
    '# Sinh từ trình thiết kế luồng LGSP — Camel YAML DSL',
    '# Định nghĩa này đi vào kho Git rồi Argo CD triển khai, không sửa trực tiếp trên môi trường.',
    '',
  ].join('\n');

  return `${header}${write(prune(doc) as Val, 0)}\n`;
}
