import { describe, expect, it } from 'vitest';
import { deserialize } from './deserialize';
import { flatten } from './flatten';

describe('K1-6 — chiếu cây xuống sơ đồ', () => {
  it('cây con hiện thành node trên sơ đồ, không bị nuốt', () => {
    const src = `- route:
    id: r
    from:
      uri: direct:a
      steps:
        - doTry:
            steps:
              - to:
                  uri: http://trong-try
            doCatch:
              - exception:
                  - java.io.IOException
                steps:
                  - log:
                      message: bat-loi`;
    const g = flatten(deserialize(src));
    const labels = g.nodes.map((n) => n.data.uri ?? n.data.ref);
    // from + doTry + to(trong-try) + log(bat-loi) = 4 node
    expect(g.nodes).toHaveLength(4);
    expect(labels.join(' ')).toContain('http://trong-try');
    expect(g.nodes.some((n) => n.data.ref.includes('doTry'))).toBe(true);
  });

  it('mã node là đường dẫn trong cây, không trùng nhau (chặn lỗi #2)', () => {
    const src = `- route:
    id: r
    from:
      uri: direct:a
      steps:
        - log:
            message: a
        - log:
            message: b
        - choice:
            when:
              - simple: "x"
                steps:
                  - log:
                      message: c`;
    const g = flatten(deserialize(src));
    const ids = g.nodes.map((n) => n.id);
    expect(new Set(ids).size).toBe(ids.length);
    // Đường dẫn phải nói lên vị trí trong cây.
    expect(ids.some((i) => i.includes('steps'))).toBe(true);
  });

  it('mọi node khai measured để React Flow không giấu (chặn lỗi #3)', () => {
    const src = `- route:
    id: r
    from:
      uri: direct:a
      steps:
        - log:
            message: a`;
    const g = flatten(deserialize(src));
    for (const n of g.nodes) {
      expect(n.measured).toEqual({ width: n.width, height: n.height });
    }
  });

  it('cạnh của nhánh when mang theo điều kiện', () => {
    const src = `- route:
    id: r
    from:
      uri: direct:a
      steps:
        - choice:
            when:
              - simple: "\${header.a} == 1"
                steps:
                  - log:
                      message: mot`;
    const g = flatten(deserialize(src));
    const whenEdge = g.edges.find((e) => e.data?.slot === 'when');
    expect(whenEdge).toBeDefined();
    expect(whenEdge!.data!.when).toContain('== 1');
  });
});
