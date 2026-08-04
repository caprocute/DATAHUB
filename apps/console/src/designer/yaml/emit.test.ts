import { describe, expect, it } from 'vitest';
import type { SeqEdge, StageData, StageNode } from '../flow/model';
import { emitRouteYaml } from './emit';

let n = 0;
function node(ref: string, extra: Partial<StageData> = {}, x = n * 100): StageNode {
  n += 1;
  return {
    id: `n${n}`,
    type: 'stage',
    position: { x, y: 0 },
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

describe('sinh Camel YAML từ sơ đồ', () => {
  it('dựng route có chặng tiếp nhận và các bước', () => {
    const from = node('component/rest', { role: 'from', uri: 'rest:get:/api/v1/thua-dat' });
    const log = node('pattern/log', { props: { message: 'xong' } });
    const yaml = emitRouteYaml([from, log], [link(from, log)], { routeId: 'tra-cuu' });

    expect(yaml).toContain('id: tra-cuu');
    expect(yaml).toContain("uri: 'rest:get:/api/v1/thua-dat'");
    expect(yaml).toContain('log:');
  });

  it('luồng chưa có chặng tiếp nhận thì nói rõ, không sinh route hỏng', () => {
    expect(emitRouteYaml([node('pattern/log')], [], { routeId: 'x' })).toContain(
      'chưa có chặng tiếp nhận',
    );
  });

  /**
   * Chặng kéo từ bảng thành phần đầy đủ mang `kind/name`. Không chuẩn hóa thì YAML
   * sinh ra thành khóa `pattern/choice` — Camel không nạp được.
   */
  describe('chuẩn hóa tham chiếu `kind/name`', () => {
    it('mẫu EIP kéo từ danh mục đầy đủ sinh đúng khóa Camel', () => {
      const from = node('component/rest', { role: 'from', uri: 'rest:get:/x' });
      const setH = node('pattern/setHeader', { props: { name: 'ma', expression: 'A' } });
      const yaml = emitRouteYaml([from, setH], [link(from, setH)], { routeId: 'r' });

      expect(yaml).toContain('setHeader:');
      expect(yaml).not.toContain('pattern/setHeader');
      expect(yaml).not.toContain('pattern/');
    });

    it('`choice` sinh nhánh when/otherwise dù mang tiền tố loại', () => {
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
      expect(yaml).not.toContain('pattern/choice');
    });

    it('tên trần của luồng lưu trước đây vẫn chạy như cũ', () => {
      const from = node('rest', { role: 'from', uri: 'rest:get:/x' });
      const setH = node('setHeader', { props: { name: 'ma', expression: 'A' } });
      const yaml = emitRouteYaml([from, setH], [link(from, setH)], { routeId: 'r' });
      expect(yaml).toContain('setHeader:');
    });
  });

  it('gắn nhánh xử lý lỗi khi được bật', () => {
    const from = node('component/rest', { role: 'from', uri: 'rest:get:/x' });
    const yaml = emitRouteYaml([from], [], { routeId: 'r', errorHandler: true });
    expect(yaml).toContain('onException:');
    expect(yaml).toContain('kafka:lgsp.dlq.r');
  });
});
