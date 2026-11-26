import type { CatalogGroup } from '@datahub/api-client';

/** Bỏ dấu, chữ thường, gộp khoảng trắng: so khớp lọc không phân biệt dấu (FR-00-020). */
export function normalizeSearch(text: string): string {
  return text
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

export const childrenOf = (node: CatalogGroup): readonly CatalogGroup[] => node.children ?? [];

/** Giữ nút khớp (mã hoặc tên) và tổ tiên của nút khớp; nút khớp giữ nguyên cây con. */
export function filterTree(nodes: readonly CatalogGroup[], query: string): CatalogGroup[] {
  const needle = normalizeSearch(query);
  if (needle === '') {
    return [...nodes];
  }
  const walk = (list: readonly CatalogGroup[]): CatalogGroup[] => {
    const kept: CatalogGroup[] = [];
    for (const node of list) {
      const self = normalizeSearch(`${node.name} ${node.code}`).includes(needle);
      if (self) {
        kept.push(node);
        continue;
      }
      const sub = walk(childrenOf(node));
      if (sub.length > 0) {
        kept.push({ ...node, children: sub });
      }
    }
    return kept;
  };
  return walk(nodes);
}

export interface FlatNode {
  node: CatalogGroup;
  level: number;
}

/** Duyệt cây theo thứ tự hiển thị. */
export function flatten(nodes: readonly CatalogGroup[], level = 1): FlatNode[] {
  return nodes.flatMap((node) => [{ node, level }, ...flatten(childrenOf(node), level + 1)]);
}

/** Số nút trong cây. */
export const countNodes = (nodes: readonly CatalogGroup[]): number => flatten(nodes).length;

/** Id nhìn thấy được theo thứ tự DOM, bỏ qua cây con của nút đang thu gọn. */
export function visibleIds(nodes: readonly CatalogGroup[], collapsed: ReadonlySet<string>): string[] {
  return nodes.flatMap((node) => [
    node.id,
    ...(collapsed.has(node.id) ? [] : visibleIds(childrenOf(node), collapsed)),
  ]);
}

export function findNode(nodes: readonly CatalogGroup[], id: string): CatalogGroup | undefined {
  return flatten(nodes).find((f) => f.node.id === id)?.node;
}

/** Id nhóm cha của nút (undefined với nhóm gốc). */
export function parentIdOf(nodes: readonly CatalogGroup[], id: string): string | undefined {
  return flatten(nodes).find((f) => f.node.id === id)?.node.parentId ?? undefined;
}

/** Nhóm tự thân và hậu duệ (để loại khỏi danh sách chọn nhóm cha khi sửa). */
export function selfAndDescendantIds(node: CatalogGroup): Set<string> {
  return new Set(flatten([node]).map((f) => f.node.id));
}
