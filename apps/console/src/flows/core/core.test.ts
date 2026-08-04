import { beforeAll, describe, expect, it } from 'vitest';
import {
  CATALOG_COUNTS,
  CATALOG_LICENSE,
  CATALOG_RUNTIME,
  CATALOG_TOTAL,
  fitsRole,
  groupOf,
  labelsOfKind,
  loadSchema,
  lookupNode,
  refName,
  searchNodes,
} from './catalog';
import { emitRouteYaml } from './emit';
import { bumpSeq, duplicateStage, effectiveSample, emptyFlow, makeStage, nextId, NODE_H, NODE_W } from './model';
import { graphFromYaml } from './parse';
import type { SeqEdge, StageData, StageNode } from './model';

/* ---------- Tiện ích dựng sơ đồ cho test ---------- */

let n = 0;
function node(ref: string, extra: Partial<StageData> = {}, x = n * 100): StageNode {
  n += 1;
  return {
    id: `t${n}`,
    type: 'stage',
    position: { x, y: 0 },
    width: NODE_W,
    height: NODE_H,
    measured: { width: NODE_W, height: NODE_H },
    data: {
      ref,
      label: ref,
      icon: '·',
      role: 'step',
      props: {},
      locked: false,
      tone: 'dest',
      ...extra,
    } as StageData,
  };
}

function link(a: StageNode, b: StageNode, data?: SeqEdge['data']): SeqEdge {
  return { id: `${a.id}-${b.id}`, source: a.id, target: b.id, type: 'seq', data };
}

/* ================================================================
   Bốn chốt chặn lỗi cũ — IP-06 §0. Đây là phần quan trọng nhất.
   ================================================================ */

describe('chặn lỗi đã từng làm hỏng sản phẩm', () => {
  beforeAll(async () => {
    // Bộ sinh lọc thuộc tính theo lược đồ, nên phải nạp lược đồ trước.
    await Promise.all(
      ['pattern/enrich', 'pattern/pollEnrich', 'component/kafka', 'component/rest'].map((r) =>
        loadSchema(lookupNode(r)!),
      ),
    );
  });

  /**
   * Lỗi 1 — Camel từ chối nạp route:
   * `Field: timeout has already been configured as an expression`.
   * Lược đồ `enrich` không có `timeout`; bộ sinh cũ tự bịa ra.
   */
  it('`enrich` không sinh `timeout` (Camel sẽ từ chối nạp)', () => {
    const from = node('component/rest', { role: 'from', uri: 'rest:get:/x' });
    const en = node('pattern/enrich', { props: { expression: 'direct:tra-cuu', timeout: 4500 } });
    const yaml = emitRouteYaml([from, en], [link(from, en)], { routeId: 'r' });

    expect(yaml).toContain('enrich:');
    expect(yaml).not.toMatch(/enrich:[\s\S]*?timeout/);
  });

  it('`pollEnrich` vẫn giữ `timeout` vì lược đồ có thuộc tính này', () => {
    const from = node('component/rest', { role: 'from', uri: 'rest:get:/x' });
    const pe = node('pattern/pollEnrich', { props: { expression: 'file:in', timeout: 3000 } });
    const yaml = emitRouteYaml([from, pe], [link(from, pe)], { routeId: 'r' });
    expect(yaml).toMatch(/pollEnrich:[\s\S]*?timeout: 3000/);
  });

  it('thuộc tính không có trong lược đồ bị loại, không lọt vào YAML', () => {
    const from = node('component/rest', { role: 'from', uri: 'rest:get:/x' });
    const k = node('component/kafka', {
      uri: 'kafka:chu-de',
      props: { topic: 'chu-de', khongCoTrongLuocDo: 'x' },
    });
    const yaml = emitRouteYaml([from, k], [link(from, k)], { routeId: 'r' });
    expect(yaml).not.toContain('khongCoTrongLuocDo');
  });

  /** Lỗi 2 — bộ đếm mã đếm từ 0 nên trùng mã do bộ đọc YAML đặt. */
  it('mã sinh sau không trùng mã đang có trên sơ đồ', () => {
    bumpSeq(['n1', 'n2', 'n9']);
    const fresh = nextId('n');
    expect(['n1', 'n2', 'n9']).not.toContain(fresh);
    expect(Number(fresh.slice(1))).toBeGreaterThan(9);
  });

  /** Lỗi 3 — nút thiếu `measured` bị React Flow giữ `visibility: hidden`. */
  it('mọi chặng dựng bằng mã đều khai sẵn kích thước', () => {
    const created = makeStage(lookupNode('component/kafka')!, { position: { x: 0, y: 0 } });
    expect(created.measured).toEqual({ width: NODE_W, height: NODE_H });

    const copy = duplicateStage(created, 'x1');
    expect(copy.measured).toEqual({ width: NODE_W, height: NODE_H });

    for (const nd of emptyFlow().nodes) {
      expect(nd.measured, `chặng ${nd.data.label} thiếu measured`).toBeTruthy();
    }

    const parsed = graphFromYaml(
      "- route:\n    from:\n      uri: 'rest:get:/x'\n      steps:\n        - log:\n            message: x\n",
    );
    for (const nd of parsed.nodes) {
      expect(nd.measured, `chặng đọc từ YAML thiếu measured`).toBeTruthy();
    }
  });

  /** Lỗi 4 — tham chiếu `kind/name` không chuẩn hóa sinh khóa DSL sai. */
  it('YAML không chứa tiền tố loại của tham chiếu', () => {
    const from = node('component/rest', { role: 'from', uri: 'rest:get:/x' });
    const setH = node('pattern/setHeader', { props: { name: 'ma', expression: 'A' } });
    const yaml = emitRouteYaml([from, setH], [link(from, setH)], { routeId: 'r' });

    expect(yaml).toContain('setHeader:');
    expect(yaml).not.toContain('pattern/');
    expect(yaml).not.toContain('component/');
  });

  it('`refName` chuẩn hóa cả hai dạng tham chiếu', () => {
    expect(refName('pattern/choice')).toBe('choice');
    expect(refName('choice')).toBe('choice');
  });
});

/* ================================================================
   Danh mục
   ================================================================ */

describe('danh mục Camel', () => {
  it('giữ đủ số lượng của nhà sản xuất', () => {
    expect(CATALOG_COUNTS.component).toBeGreaterThanOrEqual(320);
    expect(CATALOG_COUNTS.pattern).toBeGreaterThanOrEqual(70);
    expect(CATALOG_COUNTS.kamelet).toBeGreaterThanOrEqual(250);
    expect(CATALOG_TOTAL).toBeGreaterThanOrEqual(400);
  });

  it('ghi rõ nguồn và giấy phép', () => {
    expect(CATALOG_LICENSE).toBe('Apache-2.0');
    expect(CATALOG_RUNTIME).toContain('camel-quarkus');
  });

  it('giữ nguyên siêu dữ liệu gốc của nút mốc', () => {
    expect(lookupNode('component/kafka')).toMatchObject({
      title: 'Kafka',
      scheme: 'kafka',
      syntax: 'kafka:topic',
    });
    expect(lookupNode('component/json-validator')?.producerOnly).toBe(true);
  });

  it('lọc theo vai trò: mẫu EIP không mở đầu luồng', () => {
    expect(fitsRole(lookupNode('pattern/choice')!, 'from')).toBe(false);
    expect(fitsRole(lookupNode('component/json-validator')!, 'from')).toBe(false);
    expect(fitsRole(lookupNode('component/json-validator')!, 'step')).toBe(true);
  });

  it('nhóm sinh từ nhãn gốc, không bịa', () => {
    const byName = Object.fromEntries(labelsOfKind('component').map((l) => [l.label, l.count]));
    expect(byName.cloud).toBeGreaterThanOrEqual(90);
    expect(byName.messaging).toBeGreaterThanOrEqual(40);
  });

  it('tìm kiếm xếp khớp đúng tên lên trước, dưới 50 ms', () => {
    expect(searchNodes('kafka')[0]?.name).toBe('kafka');
    const t0 = performance.now();
    for (let i = 0; i < 20; i += 1) searchNodes('kaf');
    expect((performance.now() - t0) / 20).toBeLessThan(50);
  });
});

describe('nhóm thuộc tính cho cửa sổ cấu hình', () => {
  it('đọc đúng nhóm gốc và gộp `(advanced)` vào nhóm nâng cao', () => {
    expect(groupOf({ $comment: 'group:common' }).group).toBe('common');
    expect(groupOf({ $comment: 'group:producer' }).group).toBe('producer');
    expect(groupOf({ $comment: 'group:consumer (advanced)' })).toMatchObject({
      group: 'advanced',
      advanced: true,
    });
  });

  it('nút nhiều thuộc tính nhất vẫn chia được nhóm', async () => {
    // Trường hợp khắc nghiệt: lược đồ tới 154 thuộc tính — đây là lý do phải chia tab.
    const schema = await loadSchema(lookupNode('component/kafka')!);
    const props = Object.entries(schema.properties ?? {});
    expect(props.length).toBeGreaterThan(50);
    const groups = new Set(props.map(([, v]) => groupOf(v).group));
    expect(groups.size).toBeGreaterThan(1);
  });
});

/* ================================================================
   Sinh và đọc YAML
   ================================================================ */

describe('sinh Camel YAML', () => {
  it('luồng trống dựng đủ bốn chặng bắt buộc và nối tuần tự', () => {
    const { nodes, edges } = emptyFlow();
    expect(nodes).toHaveLength(4);
    expect(edges).toHaveLength(3);
    expect(nodes[0].data.role).toBe('from');
    expect(nodes.every((x) => x.data.locked)).toBe(true);
  });

  it('luồng chưa có chặng tiếp nhận thì nói rõ', () => {
    expect(emitRouteYaml([node('pattern/log')], [], { routeId: 'x' })).toContain(
      'chưa có chặng tiếp nhận',
    );
  });

  it('`choice` sinh đủ nhánh when và otherwise', () => {
    const from = node('component/rest', { role: 'from', uri: 'rest:get:/x' });
    const ch = node('pattern/choice');
    const a = node('pattern/log', { props: { message: 'A' } }, 100);
    const b = node('pattern/log', { props: { message: 'B' } }, 200);
    const yaml = emitRouteYaml(
      [from, ch, a, b],
      [link(from, ch), link(ch, a, { when: "${header.x} == 'A'" }), link(ch, b, { otherwise: true })],
      { routeId: 'r' },
    );
    expect(yaml).toContain('choice:');
    expect(yaml).toContain('when:');
    expect(yaml).toContain('otherwise:');
  });

  it('gắn nhánh xử lý lỗi khi được bật', () => {
    const from = node('component/rest', { role: 'from', uri: 'rest:get:/x' });
    const yaml = emitRouteYaml([from], [], { routeId: 'r', errorHandler: true });
    expect(yaml).toContain('onException:');
    expect(yaml).toContain('kafka:lgsp.dlq.r');
  });
});

describe('đọc ngược YAML về sơ đồ', () => {
  it('round-trip trên luồng trống giữ đúng số chặng', () => {
    const { nodes, edges } = emptyFlow();
    const yaml = emitRouteYaml(nodes, edges, { routeId: 'r' });
    const back = graphFromYaml(yaml);
    expect(back.nodes.length).toBe(nodes.length);
    expect(back.nodes[0].data.role).toBe('from');
  });

  it('báo lỗi rõ khi thiếu route hoặc có nhiều route', () => {
    expect(() => graphFromYaml('- khac: {}')).toThrow(/không tìm thấy khối .route./i);
    expect(() =>
      graphFromYaml('- route:\n    from:\n      uri: a\n- route:\n    from:\n      uri: b'),
    ).toThrow(/nhiều route/i);
  });
});

/* ================================================================
   Bản tin mẫu
   ================================================================ */

describe('bản tin mẫu theo chặng', () => {
  const a = node('pattern/log', { pinnedSample: '{"x":1}' });
  const b = node('pattern/log');
  const c = node('pattern/log');
  const edges = [link(a, b), link(b, c)];

  it('kế thừa mẫu của chặng trước khi chặng hiện tại chưa pin', () => {
    expect(effectiveSample(c.id, [a, b, c], edges)).toMatchObject({
      sample: '{"x":1}',
      inherited: true,
    });
  });

  it('không chặng nào có mẫu thì trả undefined, không bịa dữ liệu', () => {
    expect(effectiveSample(c.id, [node('pattern/log'), b, c], [link(b, c)])).toBeUndefined();
  });

  it('bản sao không mang theo mẫu của bản gốc', () => {
    const src = makeStage(lookupNode('component/kafka')!, { position: { x: 0, y: 0 } });
    src.data.pinnedSample = '{"bi-mat":true}';
    expect(duplicateStage(src, 'c1').data.pinnedSample).toBeUndefined();
  });
});
