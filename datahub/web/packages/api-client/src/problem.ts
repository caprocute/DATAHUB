import type { components } from './generated/rdm';

export type ProblemDetails = components['schemas']['ProblemDetails'];
export type ProblemError = components['schemas']['ProblemError'];

/** Lỗi do máy chủ trả (RFC 9457) hoặc do mạng. `problem` rỗng khi thân không phải problem+json. */
export class ApiProblemError extends Error {
  readonly status: number;
  readonly problem: ProblemDetails | undefined;

  constructor(status: number, problem: ProblemDetails | undefined) {
    super(problem?.title ?? `HTTP ${status}`);
    this.name = 'ApiProblemError';
    this.status = status;
    this.problem = problem;
  }

  get code(): string | undefined {
    return this.problem?.code;
  }

  get traceId(): string | undefined {
    return this.problem?.traceId;
  }

  get fieldErrors(): readonly ProblemError[] {
    return this.problem?.errors ?? [];
  }

  /** Thành viên mở rộng của problem (ví dụ catalogCount, childCount của ERR-07-037). */
  extension(name: string): unknown {
    return this.problem?.[name];
  }
}

/** Không nhận được phản hồi (mất mạng, hết thời gian chờ). */
export class ApiNetworkError extends Error {
  constructor(cause: unknown) {
    super('Không kết nối được tới máy chủ', { cause });
    this.name = 'ApiNetworkError';
  }
}

interface FetchResult<D> {
  data?: D | undefined;
  error?: unknown;
  response: Response;
}

function isProblem(value: unknown): value is ProblemDetails {
  return (
    typeof value === 'object' &&
    value !== null &&
    typeof (value as { code?: unknown }).code === 'string' &&
    typeof (value as { status?: unknown }).status === 'number'
  );
}

/**
 * Mở kết quả của client sinh: trả `data`, hoặc ném {@link ApiProblemError} / {@link ApiNetworkError}.
 * Mọi lệnh gọi API trong ứng dụng đi qua hàm này để lỗi được xử lý theo `code` (CC-FE-08).
 */
export async function unwrap<D>(call: Promise<FetchResult<D>>): Promise<{ data: D | undefined; response: Response }> {
  let result: FetchResult<D>;
  try {
    result = await call;
  } catch (error) {
    throw new ApiNetworkError(error);
  }
  if (result.error !== undefined || !result.response.ok) {
    throw new ApiProblemError(result.response.status, isProblem(result.error) ? result.error : undefined);
  }
  return { data: result.data, response: result.response };
}
