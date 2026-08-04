import { describe, expect, it } from 'vitest';
import {
  CATALOG_COUNTS,
  CATALOG_LICENSE,
  CATALOG_NODES,
  CATALOG_RUNTIME,
  CATALOG_TOTAL,
  fitsRole,
  labelsOfKind,
  loadSchema,
  lookupNode,
  searchNodes,
} from './index';

/**
 * Chốt chặn số lượng: danh mục phải giữ đủ mức của nhà sản xuất.
 * Sinh lại catalog mà tụt số → CI đỏ, không im lặng thu hẹp bảng thành phần.
 */
describe('số lượng danh mục Camel', () => {
  it('đạt tối thiểu theo nguồn Kaoto nhánh camel-quarkus', () => {
    expect(CATALOG_COUNTS.component).toBeGreaterThanOrEqual(320);
    expect(CATALOG_COUNTS.pattern).toBeGreaterThanOrEqual(70);
    expect(CATALOG_COUNTS.kamelet).toBeGreaterThanOrEqual(250);
    expect(CATALOG_COUNTS.dataformat).toBeGreaterThanOrEqual(45);
    expect(CATALOG_COUNTS.language).toBeGreaterThanOrEqual(25);
  });

  it('tổng số nút vượt 400', () => {
    expect(CATALOG_TOTAL).toBeGreaterThanOrEqual(400);
  });

  it('ghi rõ nguồn và giấy phép', () => {
    expect(CATALOG_LICENSE).toBe('Apache-2.0');
    expect(CATALOG_RUNTIME).toContain('camel-quarkus');
  });
});

describe('dữ liệu giữ nguyên của nhà sản xuất', () => {
  it('mỗi nút có tên, loại, tiêu đề', () => {
    for (const n of CATALOG_NODES) {
      expect(n.name).toBeTruthy();
      expect(n.kind).toBeTruthy();
      expect(n.title).toBeTruthy();
    }
  });

  it('giữ đúng siêu dữ liệu gốc của một vài nút mốc', () => {
    expect(lookupNode('component/kafka')).toMatchObject({
      title: 'Kafka',
      scheme: 'kafka',
      syntax: 'kafka:topic',
      labels: ['messaging'],
    });
    expect(lookupNode('pattern/choice')).toMatchObject({ title: 'Choice', input: true });
    expect(lookupNode('component/json-validator')?.producerOnly).toBe(true);
  });

  it('tra được theo tên trần cho luồng đã lưu trước đây', () => {
    expect(lookupNode('kafka')?.kind).toBe('component');
    expect(lookupNode('choice')?.kind).toBe('pattern');
  });
});

describe('phân loại theo nhãn gốc', () => {
  it('nhóm của thành phần sinh từ nhãn thật, không cứng trong mã', () => {
    const labels = labelsOfKind('component');
    const byName = Object.fromEntries(labels.map((l) => [l.label, l.count]));
    expect(byName.cloud).toBeGreaterThanOrEqual(90);
    expect(byName.messaging).toBeGreaterThanOrEqual(40);
    expect(labels.length).toBeGreaterThan(20);
  });

  it('lọc theo vai trò: chặng tiếp nhận không nhận nút chỉ dùng để gửi', () => {
    const validator = lookupNode('component/json-validator')!;
    expect(fitsRole(validator, 'from')).toBe(false);
    expect(fitsRole(validator, 'step')).toBe(true);
    // Mẫu EIP không bao giờ mở đầu luồng.
    expect(fitsRole(lookupNode('pattern/choice')!, 'from')).toBe(false);
  });
});

describe('tìm kiếm', () => {
  it('khớp đúng tên được xếp trước', () => {
    expect(searchNodes('kafka')[0]?.name).toBe('kafka');
    expect(searchNodes('choice', { kind: 'pattern' })[0]?.name).toBe('choice');
  });

  it('tìm được theo mô tả và nhãn', () => {
    expect(searchNodes('messaging').length).toBeGreaterThan(10);
  });

  it('quét toàn danh mục dưới 50 ms', () => {
    const t0 = performance.now();
    for (let i = 0; i < 20; i += 1) searchNodes('kaf');
    expect((performance.now() - t0) / 20).toBeLessThan(50);
  });
});

describe('lược đồ tham số nạp lười', () => {
  it('nạp được lược đồ gốc của thành phần', async () => {
    const schema = await loadSchema(lookupNode('component/kafka')!);
    expect(schema.properties?.topic).toBeTruthy();
    expect(Object.keys(schema.properties ?? {}).length).toBeGreaterThan(20);
  });

  it('nút không có tham số trả lược đồ rỗng, không ném lỗi', async () => {
    const schema = await loadSchema({
      name: 'khong-co-that',
      kind: 'component',
      title: 'x',
      description: '',
      labels: [],
    });
    expect(schema.properties).toBeUndefined();
  });
});
