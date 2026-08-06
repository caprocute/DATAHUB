import { describe, expect, it } from 'vitest';
import { deserialize } from './deserialize';
import { serialize } from './serialize';
import { flatten } from './flatten';
import { applyGraphToTree, unmappedNodes } from './unflatten';

const SRC = `- route:
    id: r
    from:
      uri: direct:a
      steps:
        - doTry:
            steps:
              - to:
                  uri: http://x
            doCatch:
              - exception:
                  - java.io.IOException
                steps:
                  - log:
                      message: loi-io
            doFinally:
              steps:
                - log:
                    message: cuoi`;

describe('K1-6b — vòng cây → sơ đồ → cây', () => {
  it('không sửa gì thì YAML ra y hệt (không bào mòn)', () => {
    const base = deserialize(SRC);
    const g = flatten(base);
    const back = applyGraphToTree(base, g.nodes, g.edges);
    expect(serialize(back, SRC)).toBe(serialize(base, SRC));
  });

  it('doTry KHÔNG biến thành choice như khi dùng bộ sinh cũ', () => {
    const base = deserialize(SRC);
    const g = flatten(base);
    const out = serialize(applyGraphToTree(base, g.nodes, g.edges), SRC);
    expect(out).toContain('doTry');
    expect(out).toContain('doCatch');
    expect(out).toContain('doFinally');
    expect(out).toContain('java.io.IOException');
    expect(out).not.toContain('choice');
  });

  it('sửa thuộc tính trên sơ đồ được ghi vào cây', () => {
    const base = deserialize(SRC);
    const g = flatten(base);
    const target = g.nodes.find((n) => n.data.uri === 'http://x')!;
    target.data = { ...target.data, uri: 'http://da-doi' };
    const out = serialize(applyGraphToTree(base, g.nodes, g.edges), SRC);
    expect(out).toContain('http://da-doi');
    expect(out).not.toContain('http://x');
    // Cấu trúc lồng vẫn nguyên
    expect(out).toContain('doCatch');
  });

  it('xóa chặng trên sơ đồ thì chặng biến khỏi cây', () => {
    const base = deserialize(SRC);
    const g = flatten(base);
    const keep = g.nodes.filter((n) => n.data.props.message !== 'loi-io');
    const out = serialize(applyGraphToTree(base, keep, g.edges), SRC);
    expect(out).not.toContain('loi-io');
    // Nhưng khe doCatch và lớp ngoại lệ vẫn còn
    expect(out).toContain('java.io.IOException');
  });

  it('chỉ ra được chặng mới chưa vào cây thay vì nuốt im lặng', () => {
    const base = deserialize(SRC);
    const g = flatten(base);
    const them = [...g.nodes, { ...g.nodes[0], id: 'node-moi-chua-co-duong-dan' }];
    expect(unmappedNodes(base, them).map((n) => n.id)).toEqual(['node-moi-chua-co-duong-dan']);
  });
});
