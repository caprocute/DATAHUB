import { describe, expect, it } from 'vitest';
import { embedCanvas, extractCanvas, stripCanvas } from './canvasCodec';
import type { SeqEdge, StageNode } from './flow/model';

const nodes: StageNode[] = [
  {
    id: 's1',
    type: 'stage',
    position: { x: 0, y: 0 },
    data: {
      ref: 'component/rest',
      label: 'Tiếp nhận',
      icon: '⇥',
      role: 'from',
      uri: 'rest:get:/api/v1/thua-dat',
      props: {},
      locked: true,
      tone: 'trigger',
      note: 'Đầu vào của luồng tra cứu.',
      pinnedSample: '{"soDinhDanh":"001099001234"}',
    },
  },
  {
    id: 's2',
    type: 'stage',
    position: { x: 300, y: 0 },
    data: {
      ref: 'pattern/setHeader',
      label: 'Gắn dấu',
      icon: '⊤',
      role: 'step',
      props: { name: 'x' },
      locked: false,
      tone: 'transform',
    },
  },
];

const edges: SeqEdge[] = [{ id: 'e1', source: 's1', target: 's2', type: 'seq' }];

const YAML = '- route:\n    id: tra-cuu\n';

describe('round-trip canvas trong YAML', () => {
  it('khôi phục lại được chặng và cạnh', () => {
    const back = extractCanvas(embedCanvas(YAML, { nodes, edges }));
    expect(back?.nodes).toHaveLength(2);
    expect(back?.edges).toHaveLength(1);
    expect(back?.nodes[0].data.label).toBe('Tiếp nhận');
    expect(back?.nodes[0].position).toEqual({ x: 0, y: 0 });
  });

  it('giữ ghi chú nghiệp vụ để người duyệt đọc lại được', () => {
    const back = extractCanvas(embedCanvas(YAML, { nodes, edges }));
    expect(back?.nodes[0].data.note).toBe('Đầu vào của luồng tra cứu.');
  });

  it('KHÔNG mang bản tin mẫu vào định nghĩa đem đi triển khai (FR-04-033)', () => {
    const out = embedCanvas(YAML, { nodes, edges });
    expect(out).not.toContain('001099001234');
    const back = extractCanvas(out);
    expect(back?.nodes[0].data.pinnedSample).toBeUndefined();
  });

  it('gỡ được dòng đánh dấu để lấy YAML thuần cho Camel', () => {
    const bare = stripCanvas(embedCanvas(YAML, { nodes, edges }));
    expect(bare).not.toContain('@lgsp-canvas-v1');
    expect(bare.trim()).toBe(YAML.trim());
  });

  it('YAML không có đánh dấu thì trả null, không ném lỗi', () => {
    expect(extractCanvas(YAML)).toBeNull();
    expect(extractCanvas('# @lgsp-canvas-v1: khong-phai-base64!!')).toBeNull();
  });
});
