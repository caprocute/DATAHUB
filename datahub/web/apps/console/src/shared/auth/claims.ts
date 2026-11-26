export interface AuthUser {
  sub: string;
  tenant: string;
  perms: readonly string[];
  roles: readonly string[];
  /** Tên hiển thị (claim name hoặc preferred_username), nếu có. */
  name: string;
}

function decodeBase64Url(segment: string): string {
  const base64 = segment.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4);
  const binary = atob(padded);
  const bytes = Uint8Array.from(binary, (c) => c.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}

function strings(value: unknown): string[] {
  return Array.isArray(value) ? value.filter((v): v is string => typeof v === 'string') : [];
}

/**
 * Đọc claim từ JWT chỉ để điều chỉnh giao diện (ẩn nút theo quyền). KHÔNG xác minh chữ ký: máy chủ
 * luôn kiểm quyền thật (CC-SEC-08), giao diện không phải biên bảo mật.
 */
export function parseClaims(token: string): AuthUser {
  const payload = token.split('.')[1];
  if (payload === undefined) {
    throw new Error('Token không đúng định dạng JWT');
  }
  const claims = JSON.parse(decodeBase64Url(payload)) as Record<string, unknown>;
  const sub = typeof claims['sub'] === 'string' ? claims['sub'] : '';
  const tenant = typeof claims['tenant'] === 'string' ? claims['tenant'] : '';
  const display = claims['name'] ?? claims['preferred_username'];
  return {
    sub,
    tenant,
    perms: strings(claims['perms']),
    roles: strings(claims['roles']).map((r) => (r.startsWith('ROLE-') ? r.slice('ROLE-'.length) : r)),
    name: typeof display === 'string' ? display : sub.slice(0, 8),
  };
}
