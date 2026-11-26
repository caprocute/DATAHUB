import { ApiNetworkError, ApiProblemError } from '@datahub/api-client';
import { hasMessage, t, type MessageParams } from '@datahub/i18n';

export interface UserMessage {
  /** Câu hiển thị chính, tra theo mã lỗi (không bao giờ là `detail` thô của máy chủ). */
  title: string;
  /** Gợi ý khắc phục. */
  hint?: string;
  code?: string;
  traceId?: string;
}

function numberExt(error: ApiProblemError, name: string): number | undefined {
  const value = error.extension(name);
  return typeof value === 'number' ? value : undefined;
}

/**
 * Chuyển lỗi API thành câu hiển thị theo D03-06-PH07 §5.3 (CC-FE-08: xử lý theo `code`, không
 * theo câu chữ). Khóa `rdm.err.{nnn}` và `.hint`; lỗi không có mã PH-07 dùng câu theo mã HTTP.
 */
export function toUserMessage(error: unknown, params: MessageParams = {}): UserMessage {
  if (error instanceof ApiNetworkError) {
    return { title: t('err.network') };
  }
  if (!(error instanceof ApiProblemError)) {
    return { title: t('err.unknown') };
  }
  const code = error.code;
  const traceId = error.traceId;
  const base = { ...(code !== undefined ? { code } : {}), ...(traceId !== undefined ? { traceId } : {}) };

  const match = code?.match(/^ERR-07-(\d{3})$/);
  if (match?.[1] !== undefined) {
    const catalogCount = numberExt(error, 'catalogCount');
    const childCount = numberExt(error, 'childCount');
    let key = `rdm.err.${match[1]}`;
    if (match[1] === '037' && (catalogCount ?? 0) === 0 && (childCount ?? 0) > 0) {
      key = 'rdm.err.037.children';
    }
    if (hasMessage(key)) {
      const merged: MessageParams = {
        ...(catalogCount !== undefined ? { count: catalogCount } : {}),
        ...(childCount !== undefined ? { childCount } : {}),
        ...params,
      };
      return { ...base, title: t(key, merged), ...(hasMessage(`${key}.hint`) ? { hint: t(`${key}.hint`) } : {}) };
    }
  }
  return { ...base, title: statusMessage(error), };
}

function statusMessage(error: ApiProblemError): string {
  if (error.status === 401) {
    return t('err.401');
  }
  if (error.status === 403) {
    return t('err.403');
  }
  if (error.status === 429) {
    return t('err.429', { retryAfter: 30 });
  }
  if (error.status >= 500) {
    return t('err.5xx');
  }
  return error.problem?.title ?? t('err.unknown');
}

/** Câu cho một lỗi theo trường (`errors[]`): khóa `rdm.err.{nnn}.{mã con}` hoặc `rdm.err.fieldCode.{mã con}`. */
export function fieldErrorMessage(problemCode: string | undefined, subCode: string, params: MessageParams = {}): string {
  const nnn = problemCode?.match(/^ERR-07-(\d{3})$/)?.[1];
  if (nnn !== undefined && hasMessage(`rdm.err.${nnn}.${subCode}`)) {
    return t(`rdm.err.${nnn}.${subCode}`, params);
  }
  const generic = `rdm.err.fieldCode.${subCode}`;
  return hasMessage(generic) ? t(generic, params) : t('err.unknown');
}
