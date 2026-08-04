import { describe, expect, it } from 'vitest';
import { mapWaterfall } from './RunContext';

const nodes = [
  { id: 's1', data: { label: 'Tiếp nhận', ref: 'component/rest' } },
  { id: 's2', data: { label: 'Kiểm tra lược đồ', ref: 'component/json-validator' } },
  { id: 's3', data: { label: 'Ủy quyền', ref: 'component/http' } },
  { id: 's9', data: { label: 'Ghi vết', ref: 'pattern/wireTap' } },
];

describe('ghép waterfall vào chặng trên sơ đồ', () => {
  it('ghép theo nhãn, bỏ qua khác biệt dấu và hoa thường', () => {
    const run = mapWaterfall(
      [
        { stage: 'Tiếp nhận', status: 'OK', durationMs: 4, offsetMs: 0 },
        { stage: 'kiem tra luoc do', status: 'OK', durationMs: 7, offsetMs: 4 },
      ],
      nodes,
    );
    expect(run.s1).toMatchObject({ status: 'ok', durationMs: 4, order: 1 });
    expect(run.s2).toMatchObject({ status: 'ok', order: 2 });
  });

  it('phân biệt thành công, lỗi và bỏ qua', () => {
    const run = mapWaterfall(
      [
        { stage: 'Tiếp nhận', status: 'SUCCESS', durationMs: 1, offsetMs: 0 },
        { stage: 'Ủy quyền', status: 'FAILED', durationMs: 2, offsetMs: 1 },
        { stage: 'Ghi vết', status: 'SKIPPED', durationMs: 0, offsetMs: 3 },
      ],
      nodes,
    );
    expect(run.s1.status).toBe('ok');
    expect(run.s3.status).toBe('error');
    expect(run.s9.status).toBe('skipped');
  });

  it('ghép được theo tên thành phần khi nhãn đã bị đổi', () => {
    const run = mapWaterfall(
      [{ stage: 'wireTap', status: 'OK', durationMs: 1, offsetMs: 0 }],
      [{ id: 'x', data: { label: 'Ghi nhật ký kiểm toán', ref: 'pattern/wireTap' } }],
    );
    expect(run.x?.status).toBe('ok');
  });

  it('chặng không ghép được thì bỏ qua, không gán bừa cho nút khác', () => {
    const run = mapWaterfall(
      [{ stage: 'Chặng máy chủ tự thêm', status: 'OK', durationMs: 1, offsetMs: 0 }],
      nodes,
    );
    expect(Object.keys(run)).toHaveLength(0);
  });

  it('hai chặng cùng nhãn không cùng trỏ về một nút', () => {
    const run = mapWaterfall(
      [
        { stage: 'Tiếp nhận', status: 'OK', durationMs: 1, offsetMs: 0 },
        { stage: 'Tiếp nhận', status: 'OK', durationMs: 1, offsetMs: 1 },
      ],
      nodes,
    );
    expect(Object.keys(run)).toEqual(['s1']);
  });

  it('waterfall rỗng trả về bản đồ rỗng', () => {
    expect(mapWaterfall([], nodes)).toEqual({});
  });
});
