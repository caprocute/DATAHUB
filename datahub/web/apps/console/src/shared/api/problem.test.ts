import { ApiNetworkError, ApiProblemError } from '@datahub/api-client';
import { describe, expect, it } from 'vitest';
import { fieldErrorMessage, toUserMessage } from './problem';

const problem = (status: number, code: string | undefined, extra: Record<string, unknown> = {}) =>
  new ApiProblemError(status, { type: 't', title: 'Tiêu đề máy chủ', status, ...(code ? { code } : {}), traceId: 'tr-1', ...extra } as never);

describe('toUserMessage', () => {
  it('ERR-07-037 báo số danh mục, kèm gợi ý, mã và traceId', () => {
    const m = toUserMessage(problem(409, 'ERR-07-037', { catalogCount: 3, childCount: 0 }), { name: 'Kinh tế' });
    expect(m.title).toContain('3');
    expect(m.hint).toBeDefined();
    expect(m.code).toBe('ERR-07-037');
    expect(m.traceId).toBe('tr-1');
  });

  it('ERR-07-037 chỉ còn nhóm con dùng câu riêng', () => {
    const m = toUserMessage(problem(409, 'ERR-07-037', { catalogCount: 0, childCount: 2 }));
    expect(m.title).toContain('con');
  });

  it('lỗi mạng, lỗi lạ và theo mã HTTP', () => {
    expect(toUserMessage(new ApiNetworkError('x')).title).toBeTruthy();
    expect(toUserMessage(new Error('x')).title).toBeTruthy();
    for (const status of [401, 403, 429, 500]) {
      expect(toUserMessage(problem(status, 'ERR-00-xxx')).title).not.toBe('Tiêu đề máy chủ');
    }
    expect(toUserMessage(problem(400, undefined)).title).toBe('Tiêu đề máy chủ');
    expect(toUserMessage(new ApiProblemError(418, undefined)).title).toBeTruthy();
  });
});

describe('fieldErrorMessage', () => {
  it('ưu tiên câu theo mã lỗi rồi câu chung theo mã con', () => {
    expect(fieldErrorMessage('ERR-07-039', 'CYCLE')).toContain('');
    expect(fieldErrorMessage('ERR-07-xx', 'UNIQUE', { code: 'A' })).toBeTruthy();
    expect(fieldErrorMessage(undefined, 'KHONG_CO')).toBeTruthy();
  });
});
