import { describe, expect, it } from 'vitest';
import { hasMessage, t, viVN } from './index';

describe('i18n vi-VN', () => {
  it('thay tham số trong câu', () => {
    expect(t('rdm.groups.success.deleted', { name: 'Kinh tế' })).toBe('Đã xóa nhóm "Kinh tế".');
  });

  it('giữ nguyên tham số không được cấp', () => {
    expect(t('rdm.groups.success.deleted')).toContain('{name}');
    expect(t('rdm.groups.success.deleted', { khac: 1 })).toContain('{name}');
  });

  it('khóa lạ trả về chính khóa để lỗi thiếu chuỗi lộ rõ', () => {
    expect(t('khong.ton.tai')).toBe('khong.ton.tai');
    expect(hasMessage('khong.ton.tai')).toBe(false);
  });

  it('có đủ ERR-07-001 đến ERR-07-037 kèm gợi ý (D03-06-PH07 §5.3)', () => {
    for (let n = 1; n <= 37; n += 1) {
      const key = `rdm.err.${String(n).padStart(3, '0')}`;
      expect(hasMessage(key), key).toBe(true);
      expect(hasMessage(`${key}.hint`), `${key}.hint`).toBe(true);
    }
    expect(Object.keys(viVN).length).toBeGreaterThan(100);
  });

  it('câu ERR-07-037 báo số danh mục đang dùng nhóm', () => {
    expect(t('rdm.err.037', { count: 3 })).toContain('3');
  });
});
