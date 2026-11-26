import type { CatalogGroup } from '@datahub/api-client';

export const BASE = 'http://localhost/api/rdm/v1';

function b64url(value: object): string {
  const bytes = new TextEncoder().encode(JSON.stringify(value));
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/** Token giả cho kiểm thử giao diện: chỉ có payload, không có chữ ký thật (giao diện không xác minh). */
export function fakeToken(claims: { tenant: string; perms?: string[]; roles?: string[]; name?: string }): string {
  return `${b64url({ alg: 'none' })}.${b64url({ sub: '0190f3a0-0000-7000-8000-000000000001', ...claims })}.sig`;
}

export const ADMIN_PERMS = ['PERM-07-read', 'PERM-07-create', 'PERM-07-update'];

export const adminToken = fakeToken({ tenant: 'T01', perms: ADMIN_PERMS, roles: ['TENANT_ADMIN'], name: 'Quản trị T01' });
export const viewerToken = fakeToken({ tenant: 'T01', perms: ['PERM-07-read'], roles: ['DATA_STEWARD'], name: 'Xem T01' });

export function group(partial: Partial<CatalogGroup> & { id: string; code: string; name: string }): CatalogGroup {
  return { tenantId: 'T01', parentId: null, sortOrder: 0, version: 1, catalogCount: 0, children: [], ...partial };
}

export const COMMON_GROUP = group({ id: 'g-common', code: 'HANH_CHINH', name: 'Hành chính', tenantId: 'COMMON', catalogCount: 3 });
export const CHILD_GROUP = group({ id: 'g-child', code: 'DOANH_NGHIEP', name: 'Doanh nghiệp', parentId: 'g-eco', catalogCount: 0 });
export const ROOT_GROUP = group({ id: 'g-eco', code: 'KINH_TE', name: 'Kinh tế', catalogCount: 2, version: 4, children: [CHILD_GROUP] });

export const sampleTree = (): CatalogGroup[] => [COMMON_GROUP, ROOT_GROUP];
