import createClient, { type Client, type Middleware } from 'openapi-fetch';
import type { paths } from './generated/rdm';

export type RdmClient = Client<paths>;

export interface RdmClientOptions {
  /** Mặc định `/api/rdm/v1` (cùng gốc với giao diện, qua APISIX hoặc proxy dev). */
  baseUrl?: string;
  /** Token Bearer lấy tại thời điểm gửi (chỉ giữ trong bộ nhớ). */
  getToken: () => string | undefined;
  fetch?: typeof globalThis.fetch;
  /** Sinh chuỗi ngẫu nhiên cho Idempotency-Key và traceparent; mặc định dùng Web Crypto. */
  randomUuid?: () => string;
}

/** ETag yếu `W/"{version}"` cho If-Match, sinh từ trường `version` của tài nguyên (CC-FE-07). */
export function ifMatch(version: number): string {
  return `W/"${version}"`;
}

/** Idempotency-Key hợp lệ (16–128 ký tự `[A-Za-z0-9_-]`) từ một UUID. */
export function newIdempotencyKey(randomUuid: () => string = () => globalThis.crypto.randomUUID()): string {
  return randomUuid();
}

function traceparent(randomUuid: () => string): string {
  const hex = (randomUuid() + randomUuid()).replace(/-/g, '');
  return `00-${hex.slice(0, 32)}-${hex.slice(32, 48)}-01`;
}

/**
 * Middleware gắn Bearer token và traceparent cho mọi yêu cầu; gắn Idempotency-Key cho lệnh tạo
 * (POST) nếu người gọi chưa tự đặt khóa (người gọi giữ khóa khi thử lại để chống tạo trùng).
 */
export function requestHeaders(options: Pick<RdmClientOptions, 'getToken'> & { randomUuid?: () => string }): Middleware {
  const randomUuid = options.randomUuid ?? (() => globalThis.crypto.randomUUID());
  return {
    onRequest({ request }) {
      const token = options.getToken();
      if (token !== undefined && token !== '') {
        request.headers.set('Authorization', `Bearer ${token}`);
      }
      if (!request.headers.has('traceparent')) {
        request.headers.set('traceparent', traceparent(randomUuid));
      }
      if (request.method === 'POST' && !request.headers.has('Idempotency-Key')) {
        request.headers.set('Idempotency-Key', newIdempotencyKey(randomUuid));
      }
      return request;
    },
  };
}

export function createRdmClient(options: RdmClientOptions): RdmClient {
  const client = createClient<paths>({
    baseUrl: options.baseUrl ?? '/api/rdm/v1',
    ...(options.fetch ? { fetch: options.fetch } : {}),
  });
  client.use(requestHeaders(options));
  return client;
}
