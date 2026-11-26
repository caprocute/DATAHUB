import { viVN } from './vi-VN';

export type MessageParams = Readonly<Record<string, string | number>>;

/** Khóa có trong bộ chuỗi hay không (để chọn câu dự phòng). */
export function hasMessage(key: string): boolean {
  return Object.prototype.hasOwnProperty.call(viVN, key);
}

/**
 * Dịch khóa sang vi-VN và thay `{tham_số}`. Khóa lạ trả về chính khóa để lỗi thiếu chuỗi lộ rõ
 * khi kiểm thử thay vì hiện chuỗi rỗng.
 */
export function t(key: string, params?: MessageParams): string {
  const template = viVN[key] ?? key;
  if (params === undefined) {
    return template;
  }
  return template.replace(/\{(\w+)\}/g, (whole, name: string) => {
    const value = params[name];
    return value === undefined ? whole : String(value);
  });
}

export { viVN };
