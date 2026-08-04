import { describe, expect, it } from 'vitest';
import { contextFromSample, detectLang, evaluate, suggestTokens } from './expression';

const SAMPLE = JSON.stringify({
  loaiHoSo: 'CAP_MOI',
  dienTich: 120.5,
  chuSoHuu: { hoTen: 'Nguyễn Văn A', soDinhDanh: '001099001234' },
  thuaDat: [{ soThuTu: 12 }, { soThuTu: 34 }],
});

const ctx = contextFromSample(SAMPLE, { MOI_TRUONG: 'DEV' });

describe('nhận dạng ngôn ngữ biểu thức', () => {
  it('phân biệt Simple, JSONPath và hằng', () => {
    expect(detectLang('${body.loaiHoSo}')).toBe('simple');
    expect(detectLang('$.chuSoHuu.hoTen')).toBe('jsonpath');
    expect(detectLang('CAP_MOI')).toBe('constant');
  });
});

describe('Camel Simple', () => {
  it('đọc trường lồng nhau và giữ nguyên kiểu khi chỉ có một token', () => {
    expect(evaluate('${body.dienTich}', ctx)).toMatchObject({ ok: true, value: 120.5 });
    expect(evaluate('${body.chuSoHuu.hoTen}', ctx)).toMatchObject({ ok: true, value: 'Nguyễn Văn A' });
  });

  it('ghép chuỗi khi có nhiều token', () => {
    const r = evaluate('${body.loaiHoSo}-${body.chuSoHuu.soDinhDanh}', ctx);
    expect(r).toMatchObject({ ok: true, rendered: 'CAP_MOI-001099001234' });
  });

  it('đọc được phần tử mảng', () => {
    expect(evaluate('${body.thuaDat[1].soThuTu}', ctx)).toMatchObject({ ok: true, value: 34 });
  });

  it('đọc tiêu đề và biến môi trường', () => {
    expect(evaluate('${header.loaiHoSo}', ctx)).toMatchObject({ ok: true, value: 'CAP_MOI' });
    expect(evaluate('${env.MOI_TRUONG}', ctx)).toMatchObject({ ok: true, value: 'DEV' });
  });

  it('báo lỗi rõ khi trường không có trong bản tin mẫu', () => {
    const r = evaluate('${body.khongTonTai}', ctx);
    expect(r.ok).toBe(false);
    expect(r.ok === false && r.error).toContain('khongTonTai');
  });

  it('báo thiếu dấu đóng kèm vị trí', () => {
    const r = evaluate('${body.loaiHoSo', ctx);
    expect(r).toMatchObject({ ok: false, at: 0 });
  });

  it('nói rõ khi cú pháp chưa hỗ trợ, không đoán bừa', () => {
    const r = evaluate('${date:now:yyyy}', ctx);
    expect(r.ok).toBe(false);
    expect(r.ok === false && r.error).toContain('chưa hỗ trợ');
  });
});

describe('JSONPath', () => {
  it('đọc đường dẫn có sẵn', () => {
    expect(evaluate('$.chuSoHuu.hoTen', ctx)).toMatchObject({ ok: true, value: 'Nguyễn Văn A' });
  });

  it('từ chối bộ lọc chưa hỗ trợ', () => {
    expect(evaluate('$.thuaDat[*].soThuTu', ctx).ok).toBe(false);
  });
});

describe('ngữ cảnh từ bản tin mẫu', () => {
  it('mẫu không phải JSON vẫn dùng được, không ném lỗi', () => {
    const xml = contextFromSample('<ThuaDat/>');
    expect(xml.body).toBe('<ThuaDat/>');
    expect(evaluate('hằng số', xml)).toMatchObject({ ok: true });
  });

  it('mẫu gói kèm headers được tách đúng', () => {
    const c = contextFromSample(JSON.stringify({ body: { a: 1 }, headers: { h: 'x' } }));
    expect(evaluate('${body.a}', c)).toMatchObject({ ok: true, value: 1 });
    expect(evaluate('${header.h}', c)).toMatchObject({ ok: true, value: 'x' });
  });

  it('không có mẫu thì biểu thức báo lỗi thay vì trả giá trị giả', () => {
    const empty = contextFromSample(undefined);
    expect(evaluate('${body.a}', empty).ok).toBe(false);
  });
});

describe('gợi ý token', () => {
  it('dựng từ chính bản tin mẫu', () => {
    const tokens = suggestTokens(ctx).map((t) => t.token);
    expect(tokens).toContain('${body.loaiHoSo}');
    expect(tokens).toContain('${body.chuSoHuu.hoTen}');
    expect(tokens).toContain('${env.MOI_TRUONG}');
  });
});
