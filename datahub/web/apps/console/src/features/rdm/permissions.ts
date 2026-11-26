import type { CatalogGroup } from '@datahub/api-client';
import type { AuthUser } from '../../shared/auth/claims';

const MANAGER_ROLES = ['TENANT_ADMIN', 'PLATFORM_ADMIN'];

/**
 * Quản lý nhóm danh mục (SS-07-03): cần quyền PERM-07-create/update VÀ vai trò TA hoặc PA (DS không
 * quản lý nhóm dù có quyền). Chỉ để ẩn/hiện nút; máy chủ luôn kiểm quyền thật.
 */
function canManage(user: AuthUser, permission: 'PERM-07-create' | 'PERM-07-update'): boolean {
  return user.perms.includes(permission) && user.roles.some((r) => MANAGER_ROLES.includes(r));
}

export const canCreateGroups = (user: AuthUser): boolean => canManage(user, 'PERM-07-create');

/** Tenant sở hữu dữ liệu ghi: PLATFORM ghi vào COMMON, tenant tỉnh ghi vào chính nó. */
export const dataTenantOf = (user: AuthUser): string => (user.tenant === 'PLATFORM' ? 'COMMON' : user.tenant);

/** Sửa, xóa nhóm: có quyền cập nhật và nhóm thuộc tenant mình ghi được (COMMON chỉ với PLATFORM). */
export function canEditGroup(user: AuthUser, group: CatalogGroup): boolean {
  return canManage(user, 'PERM-07-update') && group.tenantId === dataTenantOf(user);
}
