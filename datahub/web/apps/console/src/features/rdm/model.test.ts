import { describe, expect, it } from 'vitest';
import { adminToken, CHILD_GROUP, COMMON_GROUP, fakeToken, ROOT_GROUP, sampleTree, viewerToken } from '../../../../../test/fixtures';
import { parseClaims } from '../../shared/auth/claims';
import { canCreateGroups, canEditGroup, dataTenantOf } from './permissions';
import { childrenOf, countNodes, filterTree, findNode, flatten, normalizeSearch, parentIdOf, selfAndDescendantIds, visibleIds } from './tree-model';

describe('tree-model', () => {
  it('chuẩn hóa tìm kiếm: bỏ dấu, đ, khoảng trắng', () => {
    expect(normalizeSearch('  Hành   chính Đất ')).toBe('hanh chinh dat');
  });

  it('lọc giữ tổ tiên của nút khớp và khớp theo mã', () => {
    const tree = sampleTree();
    expect(filterTree(tree, '')).toHaveLength(2);
    const byChild = filterTree(tree, 'doanh nghiep');
    expect(byChild.map((g) => g.id)).toEqual(['g-eco']);
    expect(childrenOf(byChild[0]!).map((g) => g.id)).toEqual(['g-child']);
    expect(filterTree(tree, 'hanh_chinh').map((g) => g.id)).toEqual(['g-common']);
    expect(filterTree(tree, 'khong co')).toEqual([]);
  });

  it('phẳng hóa, đếm, tìm, cha và hậu duệ', () => {
    const tree = sampleTree();
    expect(flatten(tree).map((f) => f.level)).toEqual([1, 1, 2]);
    expect(countNodes(tree)).toBe(3);
    expect(findNode(tree, 'g-child')).toBe(CHILD_GROUP);
    expect(findNode(tree, 'nope')).toBeUndefined();
    expect(parentIdOf(tree, 'g-child')).toBe('g-eco');
    expect(parentIdOf(tree, 'g-eco')).toBeUndefined();
    expect([...selfAndDescendantIds(ROOT_GROUP)].sort()).toEqual(['g-child', 'g-eco']);
    expect(visibleIds(tree, new Set())).toEqual(['g-common', 'g-eco', 'g-child']);
    expect(visibleIds(tree, new Set(['g-eco']))).toEqual(['g-common', 'g-eco']);
  });
});

describe('permissions', () => {
  const admin = parseClaims(adminToken);
  const viewer = parseClaims(viewerToken);
  const platform = parseClaims(fakeToken({ tenant: 'PLATFORM', perms: ['PERM-07-create', 'PERM-07-update'], roles: ['PLATFORM_ADMIN'] }));
  const steward = parseClaims(fakeToken({ tenant: 'T01', perms: ['PERM-07-create', 'PERM-07-update'], roles: ['DATA_STEWARD'] }));

  it('chỉ quản trị có quyền mới thêm được nhóm', () => {
    expect(canCreateGroups(admin)).toBe(true);
    expect(canCreateGroups(viewer)).toBe(false);
    expect(canCreateGroups(steward)).toBe(false);
  });

  it('tenant ghi: PLATFORM ghi COMMON, tỉnh ghi chính nó', () => {
    expect(dataTenantOf(platform)).toBe('COMMON');
    expect(dataTenantOf(admin)).toBe('T01');
  });

  it('sửa nhóm: COMMON chỉ với PLATFORM; người xem không sửa', () => {
    expect(canEditGroup(admin, ROOT_GROUP)).toBe(true);
    expect(canEditGroup(admin, COMMON_GROUP)).toBe(false);
    expect(canEditGroup(platform, COMMON_GROUP)).toBe(true);
    expect(canEditGroup(viewer, ROOT_GROUP)).toBe(false);
  });
});
