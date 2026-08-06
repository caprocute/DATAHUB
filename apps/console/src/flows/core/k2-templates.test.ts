import { describe, expect, it } from 'vitest';
import { deserialize } from './deserialize';
import { serialize } from './serialize';
import { flatten } from './flatten';
import { TEMPLATES, fromTemplate, templateById } from './templates';

/** Từ khóa `CamelYamlValidator` phía máy chủ dò để biết luồng có đủ khung chuẩn. */
const REQUIRED_STAGES = [
  'receive','schema','authz','transform','enrich','route','deliver','audit','respond',
];

describe('K2-2 — bộ mẫu khởi tạo luồng', () => {
  it('mọi mẫu đọc được bằng lõi cây', () => {
    for (const t of TEMPLATES) {
      expect(() => fromTemplate(t.id, 'ma-thu'), `mẫu ${t.id} không đọc được`).not.toThrow();
    }
  });

  it('mọi mẫu quay vòng không mất dữ liệu và không sinh khối rỗng', () => {
    for (const t of TEMPLATES) {
      const src = t.yaml('ma-thu');
      const out = serialize(deserialize(src), src);
      // Chỉ soi khối **cấu trúc** rỗng — dấu hiệu mất cây con (lỗi #6). `properties: {}`
      // của Kamelet là map tham số rỗng **hợp lệ**, không phải dữ liệu bị vứt.
      for (const eip of ['doTry', 'doCatch', 'choice', 'multicast', 'loadBalance', 'split']) {
        expect(out, `mẫu ${t.id}: ${eip} thành khối rỗng`).not.toMatch(
          new RegExp(`${eip}:\\s*\\{\\}`),
        );
      }
      expect(out, `mẫu ${t.id}: biểu thức rỗng`).not.toMatch(/expression:\s*\{\}/);
      // Quay vòng lần hai phải y hệt — mẫu không được bào mòn dần.
      expect(serialize(deserialize(out), out), `mẫu ${t.id} không ổn định`).toBe(out);
    }
  });

  it('mã luồng được nhúng đúng vào mẫu', () => {
    for (const t of TEMPLATES) {
      expect(t.yaml('luong-cua-toi'), `mẫu ${t.id}`).toContain('luong-cua-toi');
    }
  });

  it('luồng trắng không có chặng khóa nào của khung chuẩn', () => {
    const res = fromTemplate('blank', 'ma-thu');
    expect(res.entities).toHaveLength(1);
    expect(res.entities[0].from?.uri).toBe('direct:ma-thu');
    // Không mang sẵn chặng nào của khung chín chặng — đó chính là điểm của "luồng trắng".
    const yaml = templateById('blank')!.yaml('ma-thu').toLowerCase();
    for (const stage of ['schema', 'authz', 'transform', 'enrich', 'deliver', 'respond']) {
      expect(yaml, `luồng trắng lại có chặng "${stage}"`).not.toContain(stage);
    }
  });

  /**
   * Camel **từ chối nạp** route không có bước nào: *Route … has no output processors*.
   * Mẫu mà không triển khai được thì tệ hơn không có mẫu — người dùng chỉ gặp lỗi ở tận
   * lúc publish. Kiểm chứng trên Camel 4.18.2 thật.
   */
  it('mọi mẫu route đều có ít nhất một bước — Camel không nạp route rỗng', () => {
    for (const t of TEMPLATES.filter((x) => x.resourceKind === 'ROUTE')) {
      const res = fromTemplate(t.id, 'ma-thu');
      expect(res.entities[0].steps.length, `mẫu ${t.id} không có bước nào`).toBeGreaterThan(0);
    }
    // Và không mẫu nào ghi ra danh sách bước rỗng.
    for (const t of TEMPLATES) {
      expect(t.yaml('ma-thu'), `mẫu ${t.id}`).not.toMatch(/steps:\s*\[\]/);
    }
  });

  /**
   * `camel/dancu` chỉ có 7 thành phần. Mẫu dùng thành phần ngoài danh sách đó thì Camel
   * báo *No endpoint could be found … check your classpath* — đã gặp thật với
   * `json-validator` và `kafka` ở bản mẫu đầu.
   */
  it('mẫu chỉ dùng thành phần có trên runtime', () => {
    const CO_SAN = ['direct', 'log', 'platform-http', 'http', 'seda', 'timer', 'kamelet'];
    for (const t of TEMPLATES) {
      for (const m of t.yaml('ma-thu').matchAll(/uri:\s*'?([a-z0-9-]+):/g)) {
        expect(CO_SAN, `mẫu ${t.id} dùng thành phần "${m[1]}" không có trên runtime`).toContain(
          m[1],
        );
      }
    }
  });

  /**
   * Mẫu khung chuẩn phải chứa **đúng** từ khóa mà `CamelYamlValidator` dò. Lệch một chữ
   * là luồng dựng từ mẫu lại bị chính chốt chặn của nền tảng báo thiếu chặng — vô lý với
   * người dùng và rất khó lần ra.
   */
  it('mẫu khung chuẩn qua được bộ kiểm chín chặng của máy chủ', () => {
    const yaml = templateById('standard-9-stage')!.yaml('ma-thu').toLowerCase();
    for (const stage of REQUIRED_STAGES) {
      expect(yaml, `mẫu khung chuẩn thiếu chặng "${stage}"`).toContain(stage);
    }
  });

  it('mẫu tích hợp REST giữ được cấu trúc doTry sau khi đọc', () => {
    const res = fromTemplate('rest-integration', 'ma-thu');
    const out = serialize(res, undefined);
    expect(out).toContain('doTry');
    expect(out).toContain('doCatch');
    expect(out).toContain('java.io.IOException');
  });

  it('Kamelet và Pipe nhận đúng loại tài nguyên', () => {
    expect(fromTemplate('kamelet', 'ma-thu').kind).toBe('Kamelet');
    expect(fromTemplate('pipe', 'ma-thu').kind).toBe('Pipe');
    expect(templateById('kamelet')!.resourceKind).toBe('KAMELET');
    expect(templateById('pipe')!.resourceKind).toBe('PIPE');
  });

  it('mọi mẫu chiếu xuống sơ đồ được, không nổ', () => {
    for (const t of TEMPLATES) {
      expect(() => flatten(fromTemplate(t.id, 'ma-thu')), `mẫu ${t.id}`).not.toThrow();
    }
  });

  it('mã mẫu lạ thì lùi về luồng trắng thay vì nổ', () => {
    const la = fromTemplate('khong-ton-tai', 'ma-thu');
    const trang = fromTemplate('blank', 'ma-thu');
    expect(la.entities[0].from?.uri).toBe(trang.entities[0].from?.uri);
  });
});
