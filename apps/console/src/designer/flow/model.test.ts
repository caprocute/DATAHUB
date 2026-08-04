import { describe, expect, it } from 'vitest';
import { bumpSeq, effectiveSample, nextId, type SeqEdge, type StageNode } from './model';

function node(id: string, pinnedSample?: string): StageNode {
  return {
    id,
    type: 'stage',
    position: { x: 0, y: 0 },
    data: {
      ref: 'pattern/log',
      label: id,
      icon: '·',
      role: 'step',
      props: {},
      locked: false,
      tone: 'dest',
      pinnedSample,
    },
  };
}

describe('sinh mã chặng', () => {
  /**
   * Bộ đọc YAML đặt mã `n1, n2…`. Nếu bộ đếm không vượt qua các mã đó thì lần
   * nhân bản sau sinh lại `n1` — React Flow bỏ nút trùng mã và nút mới hiện rỗng.
   */
  it('không trùng mã đang có sau khi dựng lại sơ đồ', () => {
    bumpSeq(['n1', 'n2', 'n7']);
    const fresh = nextId('n');
    expect(['n1', 'n2', 'n7']).not.toContain(fresh);
    expect(Number(fresh.slice(1))).toBeGreaterThan(7);
  });

  it('mã sinh liên tiếp không lặp lại', () => {
    const ids = new Set([nextId('n'), nextId('n'), nextId('n')]);
    expect(ids.size).toBe(3);
  });

  it('bỏ qua mã không có phần số', () => {
    const before = nextId('n');
    bumpSeq(['khong-co-so']);
    expect(Number(nextId('n').slice(1))).toBeGreaterThan(Number(before.slice(1)));
  });
});

describe('bản tin mẫu hiệu lực', () => {
  const edges: SeqEdge[] = [
    { id: 'e1', source: 'a', target: 'b', type: 'seq' },
    { id: 'e2', source: 'b', target: 'c', type: 'seq' },
  ];

  it('ưu tiên mẫu của chính chặng', () => {
    const nodes = [node('a', '{"x":1}'), node('b', '{"y":2}'), node('c')];
    expect(effectiveSample('b', nodes, edges)).toMatchObject({
      sample: '{"y":2}',
      inherited: false,
    });
  });

  it('thiếu thì lần ngược lấy mẫu của chặng trước', () => {
    const nodes = [node('a', '{"x":1}'), node('b'), node('c')];
    expect(effectiveSample('c', nodes, edges)).toMatchObject({
      sample: '{"x":1}',
      fromNodeId: 'a',
      inherited: true,
    });
  });

  it('không chặng nào có mẫu thì trả undefined, không bịa dữ liệu', () => {
    expect(effectiveSample('c', [node('a'), node('b'), node('c')], edges)).toBeUndefined();
  });

  it('sơ đồ có vòng không làm treo vòng lặp', () => {
    const loop: SeqEdge[] = [
      { id: 'e1', source: 'a', target: 'b', type: 'seq' },
      { id: 'e2', source: 'b', target: 'a', type: 'seq' },
    ];
    expect(effectiveSample('a', [node('a'), node('b')], loop)).toBeUndefined();
  });
});
