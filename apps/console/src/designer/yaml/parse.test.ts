import { describe, expect, it } from 'vitest';
import { INITIAL_EDGES, INITIAL_NODES } from '../flow/model';
import { emitRouteYaml } from './emit';
import { YamlParseError, graphFromYaml, parseYaml } from './parse';

describe('bộ đọc YAML tối giản', () => {
  it('đọc map lồng, danh sách và kiểu vô hướng', () => {
    const doc = parseYaml(
      ['a: 1', 'b: hai', 'c:', '  d: true', '  e:', "    - 'x: y'", '    - 2'].join('\n'),
    ) as Record<string, unknown>;
    expect(doc.a).toBe(1);
    expect(doc.b).toBe('hai');
    expect((doc.c as Record<string, unknown>).d).toBe(true);
    expect((doc.c as Record<string, unknown>).e).toEqual(['x: y', 2]);
  });

  it('bỏ qua chú thích và dòng trống', () => {
    expect(parseYaml('# ghi chú\n\na: 1\n')).toEqual({ a: 1 });
  });

  it('nói rõ khi gặp cú pháp ngoài tập con thay vì đọc sai', () => {
    expect(() => parseYaml('a: |\n  nhiều dòng')).toThrow(YamlParseError);
    expect(() => parseYaml('a: &neo 1')).toThrow(YamlParseError);
  });
});

describe('dựng lại sơ đồ từ Camel YAML', () => {
  it('đọc được đúng tệp mà trình thiết kế vừa sinh ra (round-trip)', () => {
    const yaml = emitRouteYaml(INITIAL_NODES, INITIAL_EDGES, { routeId: 'tra-cuu-thua-dat' });
    const g = graphFromYaml(yaml);

    // Luồng mẫu có 11 chặng; đọc lại phải ra đúng số chặng và có đủ nhánh choice.
    expect(g.nodes.length).toBe(INITIAL_NODES.length);
    expect(g.nodes[0].data.role).toBe('from');
    expect(g.nodes.some((n) => n.data.ref.endsWith('choice'))).toBe(true);
    expect(g.edges.some((e) => e.data?.when)).toBe(true);
  });

  it('giữ URI và tham số của chặng tiếp nhận', () => {
    const yaml = emitRouteYaml(INITIAL_NODES, INITIAL_EDGES, { routeId: 'r' });
    const g = graphFromYaml(yaml);
    expect(g.nodes[0].data.uri).toBe('rest:get:/api/v1/thua-dat/{soThuTu}');
    expect(g.nodes[0].data.props.consumes).toBe('application/json');
  });

  it('sơ đồ đọc lại rồi sinh lại cho YAML tương đương', () => {
    const first = emitRouteYaml(INITIAL_NODES, INITIAL_EDGES, { routeId: 'r' });
    const g = graphFromYaml(first);
    const second = emitRouteYaml(g.nodes, g.edges, { routeId: 'r' });
    // So số bước sinh ra, không so từng ký tự: nhãn tiếng Việt do người dùng đặt
    // không nằm trong YAML nên vòng hai lấy tiêu đề gốc của Camel.
    const count = (s: string) => s.split('\n').filter((l) => /^\s+- \w+:/.test(l)).length;
    expect(count(second)).toBe(count(first));
  });

  it('nhánh choice nối lại vào bước sau khi hợp nhánh', () => {
    const yaml = emitRouteYaml(INITIAL_NODES, INITIAL_EDGES, { routeId: 'r' });
    const g = graphFromYaml(yaml);
    const xslt = g.nodes.find((n) => n.data.uri?.startsWith('xslt:'));
    expect(xslt).toBeDefined();
    // Hai nhánh cấp mới / chỉnh lý cùng đổ về chặng chuyển đổi định dạng.
    expect(g.edges.filter((e) => e.target === xslt!.id).length).toBe(2);
  });

  it('báo lỗi rõ khi thiếu route hoặc có nhiều route', () => {
    expect(() => graphFromYaml('- khac: {}')).toThrow(/không tìm thấy khối .route./i);
    expect(() =>
      graphFromYaml('- route:\n    from:\n      uri: a\n- route:\n    from:\n      uri: b'),
    ).toThrow(/nhiều route/i);
  });

  it('route thiếu from thì báo lỗi, không dựng sơ đồ rỗng âm thầm', () => {
    expect(() => graphFromYaml('- route:\n    id: r')).toThrow(/thiếu khối .from./i);
  });
});
