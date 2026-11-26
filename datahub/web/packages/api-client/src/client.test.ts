import { describe, expect, it, vi } from 'vitest';
import { ApiNetworkError, ApiProblemError, createRdmClient, ifMatch, newIdempotencyKey, requestHeaders, unwrap } from './index';

const problem = {
  type: 'https://datahub.gov.vn/problems/rdm/group-not-empty',
  title: 'Nhóm còn dữ liệu',
  status: 409,
  code: 'ERR-07-037',
  traceId: 'abc',
  catalogCount: 3,
  errors: [{ field: 'code', code: 'UNIQUE' }],
};

describe('api-client', () => {
  it('ifMatch sinh ETag yếu từ version', () => {
    expect(ifMatch(7)).toBe('W/"7"');
  });

  it('newIdempotencyKey dùng UUID (mặc định và tùy biến)', () => {
    expect(newIdempotencyKey()).toMatch(/^[0-9a-f-]{36}$/);
    expect(newIdempotencyKey(() => 'khoa-co-dinh-1234567')).toBe('khoa-co-dinh-1234567');
  });

  it('middleware gắn Bearer, traceparent, Idempotency-Key cho POST', async () => {
    const mw = requestHeaders({ getToken: () => 'tok', randomUuid: () => '11111111-2222-3333-4444-555555555555' });
    const request = new Request('http://x/a', { method: 'POST' });
    await mw.onRequest?.({ request } as never);
    expect(request.headers.get('Authorization')).toBe('Bearer tok');
    expect(request.headers.get('traceparent')).toMatch(/^00-[0-9a-f]{32}-[0-9a-f]{16}-01$/);
    expect(request.headers.get('Idempotency-Key')).toBe('11111111-2222-3333-4444-555555555555');
  });

  it('middleware không đè khóa do người gọi đặt, không gắn khóa cho GET, bỏ Bearer khi chưa có token', async () => {
    const mw = requestHeaders({ getToken: () => undefined });
    const idem = 'giu-nguyen-0123456';
    const post = new Request('http://x/a', { method: 'POST', headers: { 'Idempotency-Key': idem, traceparent: 'tp' } });
    await mw.onRequest?.({ request: post } as never);
    expect(post.headers.get('Idempotency-Key')).toBe(idem);
    expect(post.headers.get('traceparent')).toBe('tp');
    expect(post.headers.has('Authorization')).toBe(false);
    const get = new Request('http://x/a');
    await mw.onRequest?.({ request: get } as never);
    expect(get.headers.has('Idempotency-Key')).toBe(false);
  });

  it('createRdmClient gọi đúng URL kèm tiêu đề', async () => {
    const fetchMock = vi.fn<(r: Request) => Promise<Response>>(() =>
      Promise.resolve(new Response(JSON.stringify({ items: [] }), { status: 200, headers: { 'content-type': 'application/json' } })),
    );
    const client = createRdmClient({ baseUrl: 'http://h/api', getToken: () => 'tok', fetch: fetchMock as never });
    const { data } = await unwrap(client.GET('/catalog-groups', { params: { query: { flat: false } } }));
    expect(data?.items).toEqual([]);
    const sent = fetchMock.mock.calls[0]?.[0];
    expect(sent?.url).toBe('http://h/api/catalog-groups?flat=false');
    expect(sent?.headers.get('Authorization')).toBe('Bearer tok');
  });

  it('unwrap ném ApiProblemError với mã, traceId, trường lỗi và thành viên mở rộng', async () => {
    const call = Promise.resolve({ error: problem, response: new Response(null, { status: 409 }) });
    const error = await unwrap(call).catch((e: unknown) => e);
    expect(error).toBeInstanceOf(ApiProblemError);
    const e = error as ApiProblemError;
    expect(e.status).toBe(409);
    expect(e.code).toBe('ERR-07-037');
    expect(e.traceId).toBe('abc');
    expect(e.fieldErrors).toHaveLength(1);
    expect(e.extension('catalogCount')).toBe(3);
    expect(e.message).toBe('Nhóm còn dữ liệu');
  });

  it('unwrap chịu được thân lỗi không phải problem+json', async () => {
    const error = (await unwrap(Promise.resolve({ error: 'html', response: new Response(null, { status: 502 }) })).catch((e: unknown) => e)) as ApiProblemError;
    expect(error.code).toBeUndefined();
    expect(error.fieldErrors).toEqual([]);
    expect(error.message).toBe('HTTP 502');
  });

  it('unwrap đổi lỗi mạng thành ApiNetworkError và trả data khi thành công', async () => {
    await expect(unwrap(Promise.reject(new TypeError('failed')))).rejects.toBeInstanceOf(ApiNetworkError);
    const ok = await unwrap(Promise.resolve({ data: { a: 1 }, response: new Response(null, { status: 200 }) }));
    expect(ok.data).toEqual({ a: 1 });
  });
});
