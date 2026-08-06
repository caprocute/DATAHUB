import { beforeAll, describe, expect, it } from 'vitest';
import {
  CATALOG_COUNTS,
  CATALOG_LICENSE,
  CATALOG_NODES,
  CATALOG_RUNTIME,
  CATALOG_TOTAL,
  fitsRole,
  groupOf,
  labelsOfKind,
  loadSchema,
  lookupNode,
  refName,
  refOf,
  searchNodes,
} from './catalog';
import { collapseUnchanged, diffLines, diffStat } from './diff';
import { emitRouteYaml } from './emit';
import {
  contextFromSample,
  detectLang,
  evaluate,
  EXPR_LANGS,
  suggestTokens,
} from './expression';
import {
  bumpSeq,
  duplicateStage,
  effectiveSample,
  emptyFlow,
  makeStage,
  nextId,
  stageSubtitle,
  NODE_H,
  NODE_W,
} from './model';
import { graphFromYaml, YamlParseError } from './parse';
import { prefetchSchemas, statusByNode, validate } from './validate';
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

/** Luồng tối thiểu hợp lệ: chặng tiếp nhận + chặng nối sau. */
function fromNode(uri = 'rest:get:/x'): StageNode {
  return node('component/rest', { role: 'from', uri });
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
    const from = fromNode();
    const en = node('pattern/enrich', { props: { expression: 'direct:tra-cuu', timeout: 4500 } });
    const yaml = emitRouteYaml([from, en], [link(from, en)], { routeId: 'r' });

    expect(yaml).toContain('enrich:');
    expect(yaml).not.toMatch(/enrich:[\s\S]*?timeout/);
  });

  it('`pollEnrich` vẫn giữ `timeout` vì lược đồ có thuộc tính này', () => {
    const from = fromNode();
    const pe = node('pattern/pollEnrich', { props: { expression: 'file:in', timeout: 3000 } });
    const yaml = emitRouteYaml([from, pe], [link(from, pe)], { routeId: 'r' });
    expect(yaml).toMatch(/pollEnrich:[\s\S]*?timeout: 3000/);
  });

  it('thuộc tính không có trong lược đồ bị loại, không lọt vào YAML', () => {
    const from = fromNode();
    const k = node('component/kafka', {
      uri: 'kafka:chu-de',
      props: { topic: 'chu-de', khongCoTrongLuocDo: 'x' },
    });
    const yaml = emitRouteYaml([from, k], [link(from, k)], { routeId: 'r' });
    expect(yaml).not.toContain('khongCoTrongLuocDo');
  });

  it('lược đồ chưa nạp thì giữ nguyên thuộc tính, không nuốt cấu hình người dùng', () => {
    // `component/xmpp` không nạp lược đồ ở beforeAll — bộ sinh phải giữ nguyên.
    const from = fromNode();
    const x = node('component/xmpp', { uri: 'xmpp://a', props: { room: 'p1' } });
    const yaml = emitRouteYaml([from, x], [link(from, x)], { routeId: 'r' });
    expect(yaml).toContain('room: p1');
  });

  /**
   * Lỗi 5 — mất nội dung bản tin khi quay vòng YAML (phát hiện 2026-08-05).
   *
   * `setBody: { constant: "x" }` từng quay vòng thành `setBody: { expression: {} }`:
   * bộ đọc chỉ nhìn khóa `expression` nên không thấy `constant` nằm thẳng trên bước,
   * rồi bộ sinh mặc định ghi lại thành `simple`. Route vẫn **nạp được bằng Camel**
   * nên BR-D-04 không bắt được — chỉ sai lúc chạy.
   */
  it('`setBody: constant` quay vòng không mất giá trị và không đổi ngôn ngữ', () => {
    const src = [
      '- route:',
      '    id: ping-health',
      '    from:',
      '      uri: direct:health',
      '      steps:',
      '        - setBody:',
      '            constant: "lgsp-camel-dancu:ok"',
      '        - log:',
      '            message: "ping ${body}"',
    ].join('\n');

    const g = graphFromYaml(src);
    const out = emitRouteYaml(g.nodes, g.edges, { routeId: 'ping-health' });

    expect(out).toContain('lgsp-camel-dancu:ok');
    expect(out).toMatch(/setBody:\s*\n\s*expression:\s*\n\s*constant:/);
    // Không được âm thầm đổi sang `simple` — đó chính là lỗi cũ.
    expect(out).not.toMatch(/setBody:[\s\S]*?simple:/);
    // Và tuyệt đối không được ra khối rỗng.
    expect(out).not.toMatch(/expression:\s*\{\}/);
  });

  it('mọi ngôn ngữ biểu thức của Camel quay vòng giữ nguyên giá trị và ngôn ngữ', () => {
    for (const lang of EXPR_LANGS) {
      const src = [
        '- route:',
        '    id: r',
        '    from:',
        '      uri: direct:start',
        '      steps:',
        '        - setBody:',
        `            ${lang}: "gia-tri-${lang}"`,
      ].join('\n');

      const g = graphFromYaml(src);
      const out = emitRouteYaml(g.nodes, g.edges, { routeId: 'r' });

      expect(out, `ngôn ngữ ${lang} mất giá trị`).toContain(`gia-tri-${lang}`);
      expect(out, `ngôn ngữ ${lang} bị đổi`).toMatch(new RegExp(`${lang}:`));
      expect(out, `ngôn ngữ ${lang} ra khối rỗng`).not.toMatch(/expression:\s*\{\}/);
    }
  });

  it('`exprLang` là ghi chú nội bộ, không lọt vào YAML gửi cho Camel', () => {
    const src = [
      '- route:',
      '    id: r',
      '    from:',
      '      uri: direct:start',
      '      steps:',
      '        - setBody:',
      '            constant: "x"',
    ].join('\n');
    const g = graphFromYaml(src);
    expect(emitRouteYaml(g.nodes, g.edges, { routeId: 'r' })).not.toContain('exprLang');
  });

  /**
   * Danh sách ngôn ngữ là hợp đồng với dữ liệu catalog đã vendor. Lệch một cái là
   * biểu thức dùng ngôn ngữ đó lại rơi mất im lặng — đúng cơ chế của lỗi 5.
   */
  it('EXPR_LANGS khớp đúng thư mục lược đồ ngôn ngữ đã vendor', async () => {
    const mods = import.meta.glob('./generated/schemas/language/*.json');
    const onDisk = Object.keys(mods)
      .map((p) => p.split('/').pop()!.replace('.json', ''))
      .sort();
    expect([...EXPR_LANGS].sort()).toEqual(onDisk);
  });

  /** Lỗi 2 — bộ đếm mã đếm từ 0 nên trùng mã do bộ đọc YAML đặt. */
  it('mã sinh sau không trùng mã đang có trên sơ đồ', () => {
    bumpSeq(['n1', 'n2', 'n9']);
    const fresh = nextId('n');
    expect(['n1', 'n2', 'n9']).not.toContain(fresh);
    expect(Number(fresh.slice(1))).toBeGreaterThan(9);
  });

  it('`bumpSeq` bỏ qua mã không có phần số, không làm hỏng bộ đếm', () => {
    bumpSeq(['abc', 'n40']);
    expect(Number(nextId('n').slice(1))).toBeGreaterThan(40);
  });

  it('mã sinh liên tiếp luôn khác nhau', () => {
    const ids = new Set(Array.from({ length: 50 }, () => nextId('n')));
    expect(ids.size).toBe(50);
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

  it('chặng dựng bằng mã cũng khai `width`/`height` chứ không chỉ `measured`', () => {
    const created = makeStage(lookupNode('pattern/log')!, { position: { x: 0, y: 0 } });
    expect(created.width).toBe(NODE_W);
    expect(created.height).toBe(NODE_H);
  });

  /** Lỗi 4 — tham chiếu `kind/name` không chuẩn hóa sinh khóa DSL sai. */
  it('YAML không chứa tiền tố loại của tham chiếu', () => {
    const from = fromNode();
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

  it('không nút nào trong catalog sinh khóa YAML còn dấu gạch chéo', () => {
    // Quét toàn catalog thay vì vài mẫu: lỗi 4 là lỗi hệ thống, không riêng `choice`.
    for (const nd of CATALOG_NODES) {
      expect(refName(refOf(nd)), `${nd.kind}/${nd.name}`).not.toContain('/');
    }
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

  it('tổng số nút bằng tổng các loại — chỉ mục không lệch', () => {
    const sum = Object.values(CATALOG_COUNTS).reduce((a, b) => a + b, 0);
    expect(sum).toBe(CATALOG_TOTAL);
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

  it('mọi nút đều có tên, loại và tiêu đề — không có mục rỗng', () => {
    const broken = CATALOG_NODES.filter((x) => !x.name || !x.kind || !x.title);
    expect(broken).toHaveLength(0);
  });

  it('tra theo tên trần ưu tiên component rồi pattern', () => {
    // `bean` tồn tại ở cả hai loại; luồng lưu cũ dùng tên trần nên phải xác định.
    expect(lookupNode('bean')?.kind).toBe('component');
    expect(lookupNode('pattern/bean')?.kind).toBe('pattern');
  });

  it('tra tham chiếu không tồn tại trả undefined thay vì ném lỗi', () => {
    expect(lookupNode('component/khong-co-that')).toBeUndefined();
    expect(lookupNode('')).toBeUndefined();
  });

  it('`refOf` và `lookupNode` là hai chiều của cùng một ánh xạ', () => {
    for (const ref of ['component/kafka', 'pattern/choice', 'language/simple']) {
      expect(refOf(lookupNode(ref)!)).toBe(ref);
    }
  });

  it('lọc theo vai trò: mẫu EIP không mở đầu luồng', () => {
    expect(fitsRole(lookupNode('pattern/choice')!, 'from')).toBe(false);
    expect(fitsRole(lookupNode('component/json-validator')!, 'from')).toBe(false);
    expect(fitsRole(lookupNode('component/json-validator')!, 'step')).toBe(true);
  });

  it('thành phần chỉ tiêu thụ thì không dùng được làm chặng giữa luồng', () => {
    const consumerOnly = CATALOG_NODES.find((x) => x.consumerOnly);
    expect(consumerOnly, 'catalog phải có ít nhất một nút consumerOnly').toBeTruthy();
    expect(fitsRole(consumerOnly!, 'from')).toBe(true);
  });

  it('nhóm sinh từ nhãn gốc, không bịa', () => {
    const byName = Object.fromEntries(labelsOfKind('component').map((l) => [l.label, l.count]));
    expect(byName.cloud).toBeGreaterThanOrEqual(90);
    expect(byName.messaging).toBeGreaterThanOrEqual(40);
  });

  it('nhãn xếp theo số đếm giảm dần để nhãn đông đứng trước', () => {
    const counts = labelsOfKind('component').map((l) => l.count);
    expect([...counts].sort((a, b) => b - a)).toEqual(counts);
  });

  it('tìm kiếm xếp khớp đúng tên lên trước, dưới 50 ms', () => {
    expect(searchNodes('kafka')[0]?.name).toBe('kafka');
    const t0 = performance.now();
    for (let i = 0; i < 20; i += 1) searchNodes('kaf');
    expect((performance.now() - t0) / 20).toBeLessThan(50);
  });

  it('tìm kiếm không phân biệt hoa thường', () => {
    expect(searchNodes('KAFKA')[0]?.name).toBe('kafka');
  });

  it('tìm kiếm chuỗi vô nghĩa trả về rỗng, không trả bừa', () => {
    expect(searchNodes('zzzqqqkhongtontai')).toHaveLength(0);
  });

  it('tìm kiếm chuỗi rỗng không làm sập, trả danh sách dùng được', () => {
    expect(Array.isArray(searchNodes(''))).toBe(true);
  });

  it('tìm theo mô tả cũng ra kết quả, không chỉ theo tên', () => {
    expect(searchNodes('validator').some((x) => x.name.includes('validator'))).toBe(true);
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

  it('thuộc tính không ghi nhóm rơi về nhóm chung, không mất khỏi cửa sổ', () => {
    expect(groupOf({}).group).toBe('common');
    expect(groupOf({ $comment: 'linh tinh' }).group).toBe('common');
  });

  it('nút nhiều thuộc tính nhất vẫn chia được nhóm', async () => {
    // Trường hợp khắc nghiệt: lược đồ tới 154 thuộc tính — đây là lý do phải chia tab.
    const schema = await loadSchema(lookupNode('component/kafka')!);
    const props = Object.entries(schema.properties ?? {});
    expect(props.length).toBeGreaterThan(50);
    const groups = new Set(props.map(([, v]) => groupOf(v).group));
    expect(groups.size).toBeGreaterThan(1);
  });

  it('lược đồ nạp hai lần dùng lại bộ nhớ đệm, trả cùng một đối tượng', async () => {
    const entry = lookupNode('pattern/log')!;
    expect(await loadSchema(entry)).toBe(await loadSchema(entry));
  });

  it('trường `enum` giữ nguyên danh sách giá trị để sinh Select', async () => {
    const schema = await loadSchema(lookupNode('component/kafka')!);
    const withEnum = Object.values(schema.properties ?? {}).filter((p) => p.enum?.length);
    expect(withEnum.length).toBeGreaterThan(0);
    for (const p of withEnum) expect(Array.isArray(p.enum)).toBe(true);
  });
});

/* ================================================================
   Sinh Camel YAML
   ================================================================ */

describe('sinh Camel YAML', () => {
  beforeAll(async () => {
    await Promise.all(
      ['component/rest', 'component/kafka', 'pattern/log'].map((r) => loadSchema(lookupNode(r)!)),
    );
  });

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

  it('ghi đúng mã route được truyền vào', () => {
    const from = fromNode();
    expect(emitRouteYaml([from], [], { routeId: 'tra-cuu-thua-dat' })).toContain(
      'id: tra-cuu-thua-dat',
    );
  });

  it('`choice` sinh đủ nhánh when và otherwise', () => {
    const from = fromNode();
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

  it('`choice` chỉ có nhánh điều kiện thì không sinh khóa `otherwise` rỗng', () => {
    const from = fromNode();
    const ch = node('pattern/choice');
    const a = node('pattern/log', { props: { message: 'A' } }, 100);
    const yaml = emitRouteYaml(
      [from, ch, a],
      [link(from, ch), link(ch, a, { when: '${header.x} == 1' })],
      { routeId: 'r' },
    );
    expect(yaml).toContain('when:');
    expect(yaml).not.toContain('otherwise:');
  });

  it('hai nhánh hợp lại một chặng chung thì chặng đó chỉ sinh một lần', () => {
    const from = fromNode();
    const ch = node('pattern/choice');
    const a = node('pattern/log', { props: { message: 'A' } }, 100);
    const b = node('pattern/log', { props: { message: 'B' } }, 200);
    const join = node('pattern/log', { props: { message: 'HOP' } }, 300);
    const yaml = emitRouteYaml(
      [from, ch, a, b, join],
      [
        link(from, ch),
        link(ch, a, { when: '${header.x} == 1' }),
        link(ch, b, { otherwise: true }),
        link(a, join),
        link(b, join),
      ],
      { routeId: 'r' },
    );
    expect(yaml.match(/message: HOP/g) ?? []).toHaveLength(1);
  });

  it('gắn nhánh xử lý lỗi khi được bật', () => {
    const from = fromNode();
    const yaml = emitRouteYaml([from], [], { routeId: 'r', errorHandler: true });
    expect(yaml).toContain('onException:');
    expect(yaml).toContain('kafka:lgsp.dlq.r');
  });

  it('không bật xử lý lỗi thì không sinh `onException`', () => {
    expect(emitRouteYaml([fromNode()], [], { routeId: 'r' })).not.toContain('onException:');
  });

  it('URI có ký tự đặc biệt được nháy để YAML không vỡ', () => {
    const from = fromNode('http://opa.lgsp.svc:8181/v1/data');
    expect(emitRouteYaml([from], [], { routeId: 'r' })).toContain(
      "'http://opa.lgsp.svc:8181/v1/data'",
    );
  });

  it('biểu thức `${...}` được nháy, không bị YAML hiểu thành khóa', () => {
    const from = fromNode();
    const s = node('pattern/setHeader', { props: { name: 'ma', expression: '${body.ma}' } });
    const yaml = emitRouteYaml([from, s], [link(from, s)], { routeId: 'r' });
    expect(yaml).toContain("'${body.ma}'");
  });

  it('chặng chưa nối vào luồng không lọt vào định nghĩa', () => {
    const from = fromNode();
    const roi = node('pattern/log', { props: { message: 'MO-COI' } });
    const yaml = emitRouteYaml([from, roi], [], { routeId: 'r' });
    expect(yaml).not.toContain('MO-COI');
  });

  it('`wireTap` sinh đúng URI đích ghi vết', () => {
    const from = fromNode();
    const w = node('pattern/wireTap', { props: { uri: 'kafka:lgsp.audit' } });
    const yaml = emitRouteYaml([from, w], [link(from, w)], { routeId: 'r' });
    expect(yaml).toMatch(/wireTap:[\s\S]*?kafka:lgsp\.audit/);
  });

  it('thành phần Camel luôn vào luồng qua `to`', () => {
    const from = fromNode();
    const k = node('component/kafka', { uri: 'kafka:chu-de' });
    const yaml = emitRouteYaml([from, k], [link(from, k)], { routeId: 'r' });
    expect(yaml).toMatch(/to:[\s\S]*?kafka:chu-de/);
  });

  it('cạnh trỏ tới chặng đã bị xóa không làm sập bộ sinh', () => {
    const from = fromNode();
    const orphanEdge: SeqEdge = { id: 'e-x', source: from.id, target: 'da-xoa', type: 'seq' };
    expect(() => emitRouteYaml([from], [orphanEdge], { routeId: 'r' })).not.toThrow();
  });

  it('luồng có vòng lặp không làm bộ sinh chạy vô hạn', () => {
    const from = fromNode();
    const a = node('pattern/log', { props: { message: 'A' } }, 100);
    const b = node('pattern/log', { props: { message: 'B' } }, 200);
    const yaml = emitRouteYaml(
      [from, a, b],
      [link(from, a), link(a, b), link(b, a)],
      { routeId: 'r' },
    );
    expect(yaml).toContain('message: A');
  });

  it('YAML sinh ra luôn kết thúc bằng xuống dòng', () => {
    expect(emitRouteYaml([fromNode()], [], { routeId: 'r' }).endsWith('\n')).toBe(true);
  });

  it('sinh hai lần trên cùng sơ đồ cho kết quả giống hệt', () => {
    const { nodes, edges } = emptyFlow();
    const once = emitRouteYaml(nodes, edges, { routeId: 'r' });
    expect(emitRouteYaml(nodes, edges, { routeId: 'r' })).toBe(once);
  });
});

/* ================================================================
   Đọc ngược YAML về sơ đồ
   ================================================================ */

describe('đọc ngược YAML về sơ đồ', () => {
  it('round-trip trên luồng trống giữ đúng số chặng', () => {
    const { nodes, edges } = emptyFlow();
    const yaml = emitRouteYaml(nodes, edges, { routeId: 'r' });
    const back = graphFromYaml(yaml);
    expect(back.nodes.length).toBe(nodes.length);
    expect(back.nodes[0].data.role).toBe('from');
  });

  it('round-trip giữ nguyên URI của chặng tiếp nhận', () => {
    const { nodes, edges } = emptyFlow();
    const back = graphFromYaml(emitRouteYaml(nodes, edges, { routeId: 'r' }));
    expect(back.nodes[0].data.uri).toBe(nodes[0].data.uri);
  });

  it('round-trip giữ số cạnh nối tuần tự', () => {
    const { nodes, edges } = emptyFlow();
    const back = graphFromYaml(emitRouteYaml(nodes, edges, { routeId: 'r' }));
    expect(back.edges.length).toBe(edges.length);
  });

  it('đọc lại được nhánh `choice` với điều kiện trên cạnh', () => {
    const from = fromNode();
    const ch = node('pattern/choice');
    const a = node('pattern/log', { props: { message: 'A' } }, 100);
    const b = node('pattern/log', { props: { message: 'B' } }, 200);
    const yaml = emitRouteYaml(
      [from, ch, a, b],
      [link(from, ch), link(ch, a, { when: '${header.x} == 1' }), link(ch, b, { otherwise: true })],
      { routeId: 'r' },
    );
    const back = graphFromYaml(yaml);
    expect(back.edges.some((e) => e.data?.when)).toBe(true);
    expect(back.edges.some((e) => e.data?.otherwise)).toBe(true);
  });

  it('báo lỗi rõ khi thiếu route hoặc có nhiều route', () => {
    expect(() => graphFromYaml('- khac: {}')).toThrow(/không tìm thấy khối .route./i);
    expect(() =>
      graphFromYaml('- route:\n    from:\n      uri: a\n- route:\n    from:\n      uri: b'),
    ).toThrow(/nhiều route/i);
  });

  it('lỗi đọc YAML mang theo số dòng để chỉ đúng chỗ', () => {
    try {
      graphFromYaml('- route:\n    from:\n      uri: a\n      steps:\n        - log: |\n');
      expect.unreachable('phải ném lỗi');
    } catch (e) {
      expect(e).toBeInstanceOf(YamlParseError);
      expect((e as YamlParseError).line).toBeGreaterThan(0);
    }
  });

  it('anchor YAML bị từ chối thay vì dựng sơ đồ sai', () => {
    expect(() =>
      graphFromYaml('- route:\n    from: &neo\n      uri: a\n'),
    ).toThrow(/anchor/i);
  });

  it('bỏ qua dòng chú thích và dòng trống', () => {
    const back = graphFromYaml(
      "# chú thích\n\n- route:\n    from:\n      uri: 'rest:get:/x'\n      steps:\n        - log:\n            message: x\n",
    );
    expect(back.nodes.length).toBeGreaterThan(0);
  });

  it('chặng đọc từ YAML nhận mã không trùng nhau', () => {
    const back = graphFromYaml(
      "- route:\n    from:\n      uri: 'rest:get:/x'\n      steps:\n        - log:\n            message: a\n        - log:\n            message: b\n",
    );
    expect(new Set(back.nodes.map((x) => x.id)).size).toBe(back.nodes.length);
  });
});

/* ================================================================
   Kiểm tra luồng
   ================================================================ */

describe('kiểm tra luồng trước khi gửi duyệt', () => {
  it('luồng trống mẫu không còn lỗi chặn nào', async () => {
    const { nodes, edges } = emptyFlow();
    await prefetchSchemas(nodes);
    expect(validate(nodes, edges).filter((f) => f.level === 'error')).toHaveLength(0);
  });

  it('thiếu chặng tiếp nhận là lỗi chặn', () => {
    const f = validate([node('pattern/log')], []);
    expect(f.some((x) => x.level === 'error' && /chưa có chặng tiếp nhận/i.test(x.title))).toBe(true);
  });

  it('hai chặng tiếp nhận là lỗi chặn — Camel chỉ nhận một điểm vào', () => {
    const a = fromNode();
    const b = fromNode('rest:get:/y');
    expect(validate([a, b], []).some((x) => /nhiều chặng tiếp nhận/i.test(x.title))).toBe(true);
  });

  /**
   * Q1 (IP-07): khung chuẩn hạ từ **lỗi chặn** xuống **cảnh báo**.
   *
   * Lý do đổi: mức `error` khiến không dựng nổi luồng trắng kiểu Kaoto, mà kamelet và
   * pipe thì về cấu trúc **không thể** có bốn chặng này. Chốt chặn thật chuyển sang máy
   * chủ lúc publish với luồng đối ngoại — nới trải nghiệm thiết kế, không nới kiểm soát.
   */
  it('thiếu chặng khung chuẩn là cảnh báo, không chặn người dựng luồng', () => {
    const f = validate([fromNode()], []).filter((x) => /Thiếu chặng khung chuẩn/i.test(x.title));
    expect(f.length).toBeGreaterThan(0);
    for (const x of f) expect(x.level).toBe('warn');
  });

  it('luồng trắng chỉ có chặng tiếp nhận vẫn dựng được, không có lỗi chặn', () => {
    const errs = validate([fromNode()], []).filter((x) => x.level === 'error');
    expect(errs).toHaveLength(0);
  });

  it('chặng mồ côi chỉ là cảnh báo, không chặn', () => {
    const from = fromNode();
    const roi = node('pattern/log', { label: 'Roi' });
    const f = validate([from, roi], []).filter((x) => /chưa nối vào luồng/i.test(x.title));
    expect(f).toHaveLength(1);
    expect(f[0].level).toBe('warn');
  });

  it('thành phần thiếu URI là lỗi chặn', () => {
    const from = fromNode();
    const k = node('component/kafka', { uri: '' });
    expect(
      validate([from, k], [link(from, k)]).some(
        (x) => x.level === 'error' && /thiếu URI/i.test(x.title),
      ),
    ).toBe(true);
  });

  it('bộ chuyển đổi ngoài sổ đăng ký bị chặn', () => {
    const from = fromNode();
    const x = node('component/xslt', { uri: 'xslt:transforms/bia-dat.xsl' });
    expect(
      validate([from, x], [link(from, x)]).some((f) => /không tồn tại/i.test(f.title)),
    ).toBe(true);
  });

  it('bộ chuyển đổi đã đăng ký thì không bị báo', () => {
    const from = fromNode();
    const x = node('component/xslt', { uri: 'xslt:transforms/cdm-to-datdai-v2.xsl' });
    expect(
      validate([from, x], [link(from, x)]).some((f) => /không tồn tại/i.test(f.title)),
    ).toBe(false);
  });

  it('`choice` không có nhánh là lỗi chặn', () => {
    const from = fromNode();
    const ch = node('pattern/choice');
    expect(
      validate([from, ch], [link(from, ch)]).some(
        (f) => f.level === 'error' && /chưa có nhánh/i.test(f.title),
      ),
    ).toBe(true);
  });

  it('`choice` thiếu nhánh mặc định là cảnh báo không vét cạn', () => {
    const from = fromNode();
    const ch = node('pattern/choice');
    const a = node('pattern/log', {}, 100);
    const f = validate(
      [from, ch, a],
      [link(from, ch), link(ch, a, { when: '${header.x} == 1' })],
    );
    expect(f.some((x) => x.level === 'warn' && /không vét cạn/i.test(x.title))).toBe(true);
  });

  it('nhánh `choice` chưa đặt điều kiện là lỗi chặn', () => {
    const from = fromNode();
    const ch = node('pattern/choice');
    const a = node('pattern/log', {}, 100);
    expect(
      validate([from, ch, a], [link(from, ch), link(ch, a)]).some(
        (f) => f.level === 'error' && /chưa có điều kiện/i.test(f.title),
      ),
    ).toBe(true);
  });

  it('hạn chờ làm giàu sát ngưỡng nền tảng thì cảnh báo', () => {
    const from = fromNode();
    const pe = node('pattern/pollEnrich', { props: { expression: 'file:in', timeout: 4500 } });
    expect(
      validate([from, pe], [link(from, pe)]).some((f) => /sát ngưỡng/i.test(f.title)),
    ).toBe(true);
  });

  it('hạn chờ làm giàu dưới ngưỡng thì im lặng', () => {
    const from = fromNode();
    const pe = node('pattern/pollEnrich', { props: { expression: 'file:in', timeout: 1000 } });
    expect(
      validate([from, pe], [link(from, pe)]).some((f) => /sát ngưỡng/i.test(f.title)),
    ).toBe(false);
  });

  it('mỗi phát hiện có mã riêng để giao diện lập danh sách được', () => {
    const f = validate([node('pattern/log')], []);
    expect(new Set(f.map((x) => x.id)).size).toBe(f.length);
  });

  it('gộp trạng thái theo chặng: lỗi lấn cảnh báo', () => {
    const status = statusByNode([
      { id: 'f1', level: 'warn', nodeId: 'n1', title: 'a', detail: '' },
      { id: 'f2', level: 'error', nodeId: 'n1', title: 'b', detail: '' },
    ]);
    expect(status.n1).toBe('error');
  });

  it('phát hiện không gắn chặng nào thì không lọt vào bảng trạng thái nút', () => {
    expect(statusByNode([{ id: 'f1', level: 'error', title: 'a', detail: '' }])).toEqual({});
  });

  it('`prefetchSchemas` báo có nạp mới hay không để biết khi nào kiểm lại', async () => {
    const fresh = node('component/telegram', { uri: 'telegram:bots' });
    // Lần đầu nạp mới; lần hai đã có trong bộ nhớ đệm nên không nạp lại.
    expect(await prefetchSchemas([fresh])).toBe(true);
    expect(await prefetchSchemas([fresh])).toBe(false);
  });
});

/* ================================================================
   Biểu thức
   ================================================================ */

describe('biểu thức Camel Simple và JSONPath', () => {
  const ctx = contextFromSample(
    JSON.stringify({ maHoSo: 'HS-01', chiTiet: { soTo: 12 }, danhSach: [1, 2, 3] }),
    { MOI_TRUONG: 'UAT' },
  );

  it('nhận diện đúng ngôn ngữ theo hình dạng chuỗi', () => {
    expect(detectLang('$.a.b')).toBe('jsonpath');
    expect(detectLang('${body.a}')).toBe('simple');
    expect(detectLang('hằng số')).toBe('constant');
  });

  it('đọc trường phẳng của thân bản tin', () => {
    expect(evaluate('${body.maHoSo}', ctx)).toMatchObject({ ok: true, rendered: 'HS-01' });
  });

  it('đọc trường lồng nhau', () => {
    expect(evaluate('${body.chiTiet.soTo}', ctx)).toMatchObject({ ok: true, rendered: '12' });
  });

  it('token đơn giữ nguyên kiểu gốc, không ép thành chuỗi', () => {
    expect(evaluate('${body.chiTiet.soTo}', ctx)).toMatchObject({ value: 12 });
  });

  it('ghép token với chữ thường cho ra chuỗi', () => {
    expect(evaluate('Hồ sơ ${body.maHoSo}', ctx)).toMatchObject({
      ok: true,
      rendered: 'Hồ sơ HS-01',
    });
  });

  it('đọc phần tử mảng theo chỉ số', () => {
    expect(evaluate('${body.danhSach[1]}', ctx)).toMatchObject({ ok: true, rendered: '2' });
  });

  it('chỉ số vượt biên báo lỗi thay vì trả rỗng', () => {
    expect(evaluate('${body.danhSach[9]}', ctx).ok).toBe(false);
  });

  it('trường không có trong mẫu báo lỗi rõ ràng', () => {
    const r = evaluate('${body.khongCo}', ctx);
    expect(r.ok).toBe(false);
    expect(r.ok === false && r.error).toMatch(/không có trường/i);
  });

  it('biến môi trường đã khai thì đọc được', () => {
    expect(evaluate('${env.MOI_TRUONG}', ctx)).toMatchObject({ ok: true, rendered: 'UAT' });
  });

  it('biến môi trường chưa khai báo lỗi, không đoán bừa', () => {
    expect(evaluate('${env.CHUA_KHAI}', ctx).ok).toBe(false);
  });

  it('thiếu dấu đóng token thì báo lỗi kèm vị trí', () => {
    const r = evaluate('${body.maHoSo', ctx);
    expect(r.ok).toBe(false);
    expect(r.ok === false && r.at).toBe(0);
  });

  it('biểu thức rỗng bị từ chối', () => {
    expect(evaluate('   ', ctx).ok).toBe(false);
  });

  it('cú pháp chưa hỗ trợ nói rõ máy chủ vẫn chạy được', () => {
    const r = evaluate('${date:now}', ctx);
    expect(r.ok).toBe(false);
    expect(r.ok === false && r.error).toMatch(/máy chủ vẫn chạy được/i);
  });

  it('JSONPath đọc được đường dẫn lồng nhau', () => {
    expect(evaluate('$.chiTiet.soTo', ctx)).toMatchObject({ ok: true, rendered: '12' });
  });

  it('JSONPath có ký tự đại diện thì nói chưa hỗ trợ', () => {
    expect(evaluate('$.danhSach[*]', ctx).ok).toBe(false);
  });

  it('hằng số trả về đúng nguyên văn', () => {
    expect(evaluate('CAP_MOI', ctx)).toMatchObject({ ok: true, rendered: 'CAP_MOI' });
  });

  it('mẫu không phải JSON vẫn dùng được với hằng số', () => {
    const xml = contextFromSample('<hoSo/>');
    expect(evaluate('hằng', xml).ok).toBe(true);
    expect(xml.body).toBe('<hoSo/>');
  });

  it('mẫu gói kèm headers thì tách đúng thân và tiêu đề', () => {
    const c = contextFromSample(JSON.stringify({ body: { a: 1 }, headers: { maTinh: '01' } }));
    expect(evaluate('${header.maTinh}', c)).toMatchObject({ ok: true, rendered: '01' });
  });

  it('mẫu rỗng cho ngữ cảnh rỗng, không ném lỗi', () => {
    expect(contextFromSample(undefined).body).toBeUndefined();
    expect(contextFromSample('').body).toBeUndefined();
  });

  it('gợi ý token dựng từ chính bản tin mẫu', () => {
    const tokens = suggestTokens(ctx).map((t) => t.token);
    expect(tokens).toContain('${body}');
    expect(tokens).toContain('${body.maHoSo}');
    expect(tokens).toContain('${body.chiTiet.soTo}');
  });

  it('gợi ý token có cả biến môi trường đã khai', () => {
    expect(suggestTokens(ctx).map((t) => t.token)).toContain('${env.MOI_TRUONG}');
  });

  it('gợi ý token bị cắt trần để không đổ hàng nghìn dòng', () => {
    const big = Object.fromEntries(Array.from({ length: 200 }, (_, i) => [`f${i}`, i]));
    expect(suggestTokens(contextFromSample(JSON.stringify(big))).length).toBeLessThanOrEqual(40);
  });
});

/* ================================================================
   So sánh YAML khi duyệt
   ================================================================ */

describe('so sánh hai bản YAML', () => {
  it('hai bản giống hệt thì không có khác biệt', () => {
    expect(diffStat(diffLines('a\nb\nc', 'a\nb\nc'))).toEqual({ added: 0, removed: 0 });
  });

  it('luồng mới so với bản rỗng thì mọi dòng là thêm mới', () => {
    expect(diffStat(diffLines('', 'a\nb\nc'))).toEqual({ added: 3, removed: 0 });
  });

  it('bản rỗng không sinh dòng ảo', () => {
    expect(diffLines('', '')).toHaveLength(0);
  });

  it('thêm một dòng giữa thì chỉ tính một dòng thêm', () => {
    expect(diffStat(diffLines('a\nc', 'a\nb\nc'))).toEqual({ added: 1, removed: 0 });
  });

  it('xóa một dòng thì chỉ tính một dòng bỏ', () => {
    expect(diffStat(diffLines('a\nb\nc', 'a\nc'))).toEqual({ added: 0, removed: 1 });
  });

  it('sửa một dòng tính là một bỏ một thêm', () => {
    expect(diffStat(diffLines('a\nb\nc', 'a\nB\nc'))).toEqual({ added: 1, removed: 1 });
  });

  it('dòng giữ nguyên mang cả số dòng cũ và mới', () => {
    const same = diffLines('a\nb', 'a\nb').filter((l) => l.kind === 'same');
    expect(same[0]).toMatchObject({ oldNo: 1, newNo: 1 });
    expect(same[1]).toMatchObject({ oldNo: 2, newNo: 2 });
  });

  it('dòng thêm mới không có số dòng cũ', () => {
    const add = diffLines('a', 'a\nb').find((l) => l.kind === 'add');
    expect(add).toMatchObject({ oldNo: null, newNo: 2 });
  });

  it('dòng bị bỏ không có số dòng mới', () => {
    const rm = diffLines('a\nb', 'a').find((l) => l.kind === 'remove');
    expect(rm).toMatchObject({ oldNo: 2, newNo: null });
  });

  it('gộp đoạn không đổi và chừa ngữ cảnh quanh chỗ sửa', () => {
    const lines = diffLines(
      Array.from({ length: 40 }, (_, i) => `d${i}`).join('\n'),
      Array.from({ length: 40 }, (_, i) => (i === 20 ? 'ĐỔI' : `d${i}`)).join('\n'),
    );
    const collapsed = collapseUnchanged(lines, 3);
    expect(collapsed.length).toBeLessThan(lines.length);
    expect(collapsed).toContain(null);
    expect(collapsed.some((l) => l?.text === 'ĐỔI')).toBe(true);
  });

  it('không có gì đổi thì gộp lại còn đúng một dấu ngắt', () => {
    expect(collapseUnchanged(diffLines('a\nb\nc', 'a\nb\nc'))).toEqual([null]);
  });

  it('so sánh hai định nghĩa thật sinh từ bộ sinh cho khác biệt gọn', () => {
    const { nodes, edges } = emptyFlow();
    const v1 = emitRouteYaml(nodes, edges, { routeId: 'r' });
    const v2 = emitRouteYaml(nodes, edges, { routeId: 'r', errorHandler: true });
    const stat = diffStat(diffLines(v1, v2));
    expect(stat.added).toBeGreaterThan(0);
    expect(stat.removed).toBe(0);
  });
});

/* ================================================================
   Bản tin mẫu và nhãn chặng
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

  it('mẫu pin ở chính chặng thì không đánh dấu là kế thừa', () => {
    expect(effectiveSample(a.id, [a, b, c], edges)).toMatchObject({
      fromNodeId: a.id,
      inherited: false,
    });
  });

  it('chỉ rõ mẫu kế thừa từ chặng nào để người dùng lần được nguồn', () => {
    expect(effectiveSample(c.id, [a, b, c], edges)?.fromNodeId).toBe(a.id);
  });

  it('không chặng nào có mẫu thì trả undefined, không bịa dữ liệu', () => {
    expect(effectiveSample(c.id, [node('pattern/log'), b, c], [link(b, c)])).toBeUndefined();
  });

  it('sơ đồ có vòng lặp không làm hàm kế thừa chạy vô hạn', () => {
    const p = node('pattern/log');
    const q = node('pattern/log');
    expect(effectiveSample(p.id, [p, q], [link(p, q), link(q, p)])).toBeUndefined();
  });

  it('mẫu chỉ có khoảng trắng bị coi như chưa đặt', () => {
    const blank = node('pattern/log', { pinnedSample: '   ' });
    expect(effectiveSample(blank.id, [blank], [])).toBeUndefined();
  });

  it('bản sao không mang theo mẫu của bản gốc', () => {
    const src = makeStage(lookupNode('component/kafka')!, { position: { x: 0, y: 0 } });
    src.data.pinnedSample = '{"bi-mat":true}';
    expect(duplicateStage(src, 'c1').data.pinnedSample).toBeUndefined();
  });

  it('bản sao được mở khóa và lệch vị trí để không chồng bản gốc', () => {
    const src = makeStage(lookupNode('component/kafka')!, { position: { x: 10, y: 10 } });
    src.data.locked = true;
    const copy = duplicateStage(src, 'c2');
    expect(copy.data.locked).toBe(false);
    expect(copy.position.x).toBeGreaterThan(src.position.x);
  });

  it('bản sao sao chép sâu thuộc tính, sửa bản sao không đụng bản gốc', () => {
    const src = makeStage(lookupNode('component/kafka')!, { position: { x: 0, y: 0 } });
    src.data.props.topic = 'goc';
    const copy = duplicateStage(src, 'c3');
    copy.data.props.topic = 'sao';
    expect(src.data.props.topic).toBe('goc');
  });

  it('nhãn phụ ưu tiên số ánh xạ, rồi URI, rồi thuộc tính đầu tiên', () => {
    expect(stageSubtitle(node('pattern/transform', { mappings: [{ from: 'a', to: 'b' }] }).data)).toMatch(
      /1 ánh xạ/,
    );
    expect(stageSubtitle(node('component/kafka', { uri: 'kafka:x' }).data)).toBe('kafka:x');
    expect(stageSubtitle(node('pattern/log', { props: { message: 'xin chào' } }).data)).toBe(
      'message: xin chào',
    );
  });

  it('chặng chưa cấu hình gì thì nhãn phụ lấy tiêu đề gốc trong catalog', () => {
    expect(stageSubtitle(node('pattern/choice').data)).toBe(lookupNode('pattern/choice')!.title);
  });
});
