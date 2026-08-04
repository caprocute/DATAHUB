import { lookup, refName } from '../catalog/catalog';
import type { SeqEdge, StageData, StageNode } from '../flow/model';

/* ---------- Bộ ghi YAML tối giản ---------- */

type Scalar = string | number | boolean | null;
type Val = Scalar | Val[] | { [k: string]: Val };

const NEEDS_QUOTE = /[:#{}[\],&*!|>%@`"']|^\s|\s$|^$/;

function scalar(v: Scalar): string {
  if (v === null) return 'null';
  if (typeof v === 'boolean' || typeof v === 'number') return String(v);
  // URI của Camel và biểu thức `${...}` đầy ký tự có nghĩa trong YAML, nên nháy đơn
  // cho chắc thay vì dò từng trường hợp.
  return NEEDS_QUOTE.test(v) ? `'${v.replace(/'/g, "''")}'` : v;
}

function isRecord(v: Val): v is { [k: string]: Val } {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/**
 * Bỏ giá trị trống để bản YAML sinh ra không lẫn khóa vô nghĩa.
 *
 * Cố tình giữ lại đối tượng rỗng: một chặng vừa thả vào sơ đồ chưa có thuộc tính nào
 * vẫn phải hiện thành `tênMẫu: {}`. Bỏ luôn thì chặng biến mất khỏi định nghĩa dù
 * vẫn nằm trên sơ đồ, và người dùng không hiểu vì sao.
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
  // Nhánh xếp từ trái sang phải theo vị trí trên sơ đồ, để YAML sinh ra ổn định
  // chứ không đổi thứ tự sau mỗi lần vẽ lại.
  for (const list of outs.values()) {
    list.sort((a, b) => (byId.get(a.target)?.position.x ?? 0) - (byId.get(b.target)?.position.x ?? 0));
  }
  return { byId, outs, inDeg };
}

/** Một chặng thành một phần tử trong danh sách `steps` của Camel. */
function stepFor(d: StageData): Val {
  const entry = lookup(d.ref);
  const p = d.props;
  // Chặng có thể mang `kind/name` (kéo từ danh mục đầy đủ) — Camel DSL chỉ biết tên trần.
  const name = refName(d.ref);

  switch (name) {
    case 'choice':
      // `choice` được dựng riêng ở walk() vì còn phải gắn các nhánh.
      return { choice: {} };
    case 'setHeader':
      return { setHeader: { name: p.name as string, expression: { simple: String(p.expression ?? '') } } };
    case 'setBody':
      return { setBody: { expression: { simple: String(p.expression ?? '') } } };
    case 'transform': {
      if (d.mappings?.length) {
        return {
          transform: {
            expression: {
              // Minh họa: sản phẩm thật có thể dùng jq / DataSonnet / bean ánh xạ.
              simple: d.mappings.map((m) => `${m.to} ← ${m.from}`).join('; '),
            },
            // Giữ danh sách ánh xạ dạng chú thích cấu trúc để dễ đọc khi so diff.
            id: 'datamapper',
          },
        };
      }
      return { transform: { expression: { simple: String(p.expression ?? '') } } };
    }
    case 'filter':
      return { filter: { expression: { simple: String(p.expression ?? '') } } };
    case 'enrich':
      // `enrich` không có thuộc tính `timeout` trong lược đồ Camel; đặt kèm
      // `expression` sẽ bị từ chối lúc nạp ("has already been configured as an
      // expression"). Hạn chờ thuộc về endpoint được gọi, khai trong URI.
      return { enrich: { expression: { constant: String(p.expression ?? '') } } };
    case 'pollEnrich':
      return {
        pollEnrich: {
          expression: { constant: String(p.expression ?? '') },
          // `pollEnrich` có `timeout` thật trong lược đồ (thời gian chờ lấy bản tin).
          timeout: p.timeout as number,
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

  // Thành phần Camel luôn đi vào luồng qua `to`; mẫu EIP thì lấy chính tên mẫu làm khóa.
  if (entry?.kind === 'component' || d.uri) {
    const hasParams = Object.keys(p).length > 0;
    return { to: { uri: d.uri ?? '', ...(hasParams ? { parameters: p as { [k: string]: Val } } : {}) } };
  }
  return { [name]: p as { [k: string]: Val } };
}

interface WalkResult {
  steps: Val[];
  joinAt: string | null;
}

/**
 * Đi theo cạnh, dựng danh sách `steps`.
 *
 * Gặp chặng có nhiều cạnh vào thì dừng lại và trả về mã chặng đó: đây là điểm các
 * nhánh của `choice` hợp lại, và luồng chính tiếp tục từ đấy. Camel YAML không diễn
 * đạt được việc nhánh nối ngang, nên hợp nhánh phải quy về một điểm chung.
 */
function walk(g: Graph, startId: string | null, seen: Set<string>): WalkResult {
  const steps: Val[] = [];
  let cur = startId;
  // Chặng mà lượt đi này chủ ý tiếp tục từ đó sau khi đã dựng xong khối `choice`.
  // Không có dấu này thì phép kiểm tra bên dưới sẽ dừng ngay tại điểm hợp nhánh và
  // bỏ mất toàn bộ phần luồng phía sau.
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

    if (outs.length > 1) {
      const branches = outs.map((e) => ({ edge: e, res: walk(g, e.target, new Set(seen)) }));
      const whens: Val[] = [];
      let otherwise: Val | null = null;

      for (const b of branches) {
        if (b.edge.data?.otherwise) {
          otherwise = { steps: b.res.steps };
        } else {
          whens.push({
            expression: { simple: String(b.edge.data?.when ?? '') },
            steps: b.res.steps,
          });
        }
      }

      const choice: { [k: string]: Val } = {};
      if (whens.length) choice.when = whens;
      if (otherwise) choice.otherwise = otherwise;
      steps.push({ choice });

      // Các nhánh chỉ tiếp tục được nếu cùng hợp về một chặng.
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
    return '# Luồng chưa có chặng tiếp nhận — hãy kéo một thành phần ở nhóm "Điểm tiếp nhận" vào sơ đồ.';
  }

  const seen = new Set<string>([fromNode.id]);
  const firstEdge = (g.outs.get(fromNode.id) ?? [])[0];
  const { steps } = walk(g, firstEdge?.target ?? null, seen);

  const route: { [k: string]: Val } = {
    route: {
      id: opts.routeId,
      from: {
        uri: fromNode.data.uri ?? '',
        parameters: fromNode.data.props as { [k: string]: Val },
        steps,
      },
    },
  };

  const doc: Val[] = [route];

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
    `# Sinh từ trình thiết kế luồng LGSP — Camel YAML DSL`,
    `# Định nghĩa này đi vào kho Git rồi Argo CD triển khai, không sửa trực tiếp trên môi trường.`,
    '',
  ].join('\n');

  return `${header}${write(prune(doc) as Val, 0)}\n`;
}
