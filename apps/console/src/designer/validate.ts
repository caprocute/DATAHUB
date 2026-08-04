import { loadSchema, lookup, peekSchema } from './catalog/catalog';
import { MANDATORY_STAGES, REGISTERED_CONVERTERS, type SeqEdge, type StageNode } from './flow/model';
import type { NodeStatus } from './flow/StatusContext';

export interface Finding {
  id: string;
  level: NodeStatus;
  /** Chặng liên quan, nếu phát hiện gắn với một chặng cụ thể. */
  nodeId?: string;
  title: string;
  detail: string;
  hint?: string;
}

/** Hạn chờ làm giàu vượt mức này thì cảnh báo — ngưỡng của nền tảng là 5 giây. */
const ENRICH_TIMEOUT_WARN = 4000;

export function validate(nodes: StageNode[], edges: SeqEdge[]): Finding[] {
  const out: Finding[] = [];
  const push = (f: Omit<Finding, 'id'>) => out.push({ ...f, id: `f${out.length + 1}` });

  /* --- Khung xương chuẩn --- */

  const fromNodes = nodes.filter((n) => n.data.role === 'from');
  if (fromNodes.length === 0) {
    push({
      level: 'error',
      title: 'Luồng chưa có chặng tiếp nhận',
      detail: 'Mỗi luồng phải có đúng một chặng tiếp nhận làm đầu vào.',
      hint: 'Kéo một mục ở nhóm “Điểm tiếp nhận” vào sơ đồ.',
    });
  } else if (fromNodes.length > 1) {
    push({
      level: 'error',
      nodeId: fromNodes[1].id,
      title: 'Luồng có nhiều chặng tiếp nhận',
      detail: `Đang có ${fromNodes.length} chặng tiếp nhận. Camel chỉ nhận một điểm vào cho mỗi route.`,
    });
  }

  for (const name of MANDATORY_STAGES) {
    if (!nodes.some((n) => n.data.label === name)) {
      push({
        level: 'error',
        title: `Thiếu chặng bắt buộc: ${name}`,
        detail: 'Khung xương chuẩn của nền tảng yêu cầu chặng này ở mọi luồng tích hợp.',
        hint: 'Xem BR-04-001 tại SRS PH-04.',
      });
    }
  }

  /* --- Cấu trúc sơ đồ --- */

  const inDeg = new Map(nodes.map((n) => [n.id, 0]));
  const outDeg = new Map(nodes.map((n) => [n.id, 0]));
  for (const e of edges) {
    inDeg.set(e.target, (inDeg.get(e.target) ?? 0) + 1);
    outDeg.set(e.source, (outDeg.get(e.source) ?? 0) + 1);
  }

  for (const n of nodes) {
    if (n.data.role === 'from') continue;
    if ((inDeg.get(n.id) ?? 0) === 0) {
      push({
        level: 'warn',
        nodeId: n.id,
        title: `Chặng chưa nối vào luồng: ${n.data.label}`,
        detail: 'Chặng không có cạnh vào nên sẽ không được sinh ra trong định nghĩa Camel.',
        hint: 'Kéo từ điểm nối dưới chặng trước tới điểm nối trên chặng này.',
      });
    }
  }

  /* --- Từng chặng --- */

  for (const n of nodes) {
    const d = n.data;
    const entry = lookup(d.ref);

    // Với chặng dựng trên thành phần Camel, URI là bắt buộc; với mẫu EIP thì xét
    // danh sách `required` của lược đồ gốc.
    if (entry?.kind === 'component' || d.uri !== undefined) {
      if (!d.uri) {
        push({
          level: 'error',
          nodeId: n.id,
          title: `Chặng thiếu URI: ${d.label}`,
          detail: `Thành phần ${entry?.title ?? d.ref} cần URI để Camel biết gọi đi đâu.`,
        });
      }
    } else {
      // Lược đồ nạp lười; chặng chưa có lược đồ trong bộ nhớ đệm thì bỏ qua vòng này,
      // `prefetchSchemas` sẽ nạp rồi trình thiết kế chạy lại kiểm tra.
      const schema = entry ? peekSchema(entry) : undefined;
      for (const key of schema?.required ?? []) {
        const v = d.props[key];
        if (v === undefined || v === '') {
          const title = schema?.properties?.[key]?.title ?? key;
          push({
            level: 'error',
            nodeId: n.id,
            title: `Thiếu thuộc tính bắt buộc: ${title}`,
            detail: `Chặng “${d.label}” chưa đặt thuộc tính ${key}, mẫu ${entry?.title ?? d.ref} yêu cầu thuộc tính này.`,
          });
        }
      }
    }

    // Bộ chuyển đổi phải có trong sổ đăng ký của nền tảng.
    if (d.uri?.startsWith('xslt:')) {
      const res = d.uri.slice('xslt:'.length);
      if (!REGISTERED_CONVERTERS.includes(res)) {
        push({
          level: 'error',
          nodeId: n.id,
          title: 'Bộ chuyển đổi không tồn tại',
          detail: `Chặng “${d.label}” tham chiếu ${res}, không có trong sổ đăng ký bộ chuyển đổi.`,
          hint: `Bản đã đăng ký gần nhất: ${REGISTERED_CONVERTERS[0]}`,
        });
      }
    }

    if ((d.ref === 'enrich' || d.ref === 'pollEnrich') && typeof d.props.timeout === 'number') {
      if (d.props.timeout >= ENRICH_TIMEOUT_WARN) {
        push({
          level: 'warn',
          nodeId: n.id,
          title: 'Hạn chờ làm giàu sát ngưỡng',
          detail: `Chặng “${d.label}” đặt hạn chờ ${d.props.timeout} ms, sát ngưỡng 5000 ms của nền tảng.`,
          hint: 'Hạ hạn chờ hoặc chuyển sang làm giàu bất đồng bộ.',
        });
      }
    }

    /* --- Nhánh của choice --- */

    if (d.ref === 'choice') {
      const branches = edges.filter((e) => e.source === n.id);
      if (branches.length === 0) {
        push({
          level: 'error',
          nodeId: n.id,
          title: 'Chặng định tuyến chưa có nhánh',
          detail: `Chặng “${d.label}” không có cạnh ra nên bản tin sẽ đi vào ngõ cụt.`,
        });
      }
      if (branches.length > 0 && !branches.some((e) => e.data?.otherwise)) {
        push({
          level: 'warn',
          nodeId: n.id,
          title: 'Luật định tuyến không vét cạn',
          detail: `Chặng “${d.label}” có ${branches.length} luật nhưng thiếu nhánh mặc định. Bản tin không khớp luật nào sẽ bị bỏ qua.`,
          hint: 'Đánh dấu một nhánh là “mặc định” trên cạnh (nhấp nhãn điều kiện).',
        });
      }
      for (const e of branches) {
        if (!e.data?.otherwise && !e.data?.when) {
          push({
            level: 'error',
            nodeId: n.id,
            title: 'Nhánh định tuyến chưa có điều kiện',
            detail: `Một nhánh ra khỏi “${d.label}” chưa đặt biểu thức điều kiện.`,
            hint: 'Bấm vào nhãn điều kiện trên cạnh để sửa.',
          });
        }
      }
    }
  }

  return out;
}

/**
 * Nạp trước lược đồ của mọi chặng đang có trên sơ đồ.
 *
 * `validate` chạy đồng bộ trong lúc vẽ nên không tự `await` được. Trình thiết kế
 * gọi hàm này mỗi khi tập chặng đổi; nạp xong thì chạy lại `validate` để phần
 * kiểm tra thuộc tính bắt buộc có dữ liệu.
 * Trả `true` nếu có lược đồ mới được nạp (tức là nên kiểm tra lại).
 */
export async function prefetchSchemas(nodes: StageNode[]): Promise<boolean> {
  const refs = new Set(nodes.map((n) => n.data.ref));
  let loaded = false;
  await Promise.all(
    [...refs].map(async (ref) => {
      const entry = lookup(ref);
      if (!entry || peekSchema(entry)) return;
      await loadSchema(entry);
      loaded = true;
    }),
  );
  return loaded;
}

/** Gộp phát hiện theo chặng, lỗi lấn cảnh báo. */
export function statusByNode(findings: Finding[]): Record<string, NodeStatus> {
  const map: Record<string, NodeStatus> = {};
  for (const f of findings) {
    if (!f.nodeId) continue;
    if (map[f.nodeId] !== 'error') map[f.nodeId] = f.level;
  }
  return map;
}
