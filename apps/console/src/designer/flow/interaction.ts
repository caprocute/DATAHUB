import { createContext, useContext } from 'react';
import type { PaletteItem } from '../catalog/catalog';

/** Thao tác mà cạnh và nút gọi ngược lên vùng sơ đồ. */
export interface Interaction {
  /** Chèn một chặng vào giữa cạnh, cắt cạnh cũ thành hai. */
  insertOnEdge: (edgeId: string, item: PaletteItem) => void;
  /** Mở danh sách chọn thành phần để chèn vào giữa cạnh. */
  openInsertMenu: (edgeId: string, at: { x: number; y: number }) => void;
  /** Sửa điều kiện của nhánh ra khỏi `choice`. */
  editBranch: (edgeId: string) => void;
}

export const InteractionContext = createContext<Interaction>({
  insertOnEdge: () => {},
  openInsertMenu: () => {},
  editBranch: () => {},
});

export function useInteraction(): Interaction {
  return useContext(InteractionContext);
}

/** Khóa dữ liệu dùng khi kéo mục từ bảng thành phần vào sơ đồ. */
export const DRAG_MIME = 'application/x-lgsp-stage';

export function readDraggedItem(dt: DataTransfer): PaletteItem | null {
  const raw = dt.getData(DRAG_MIME);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as PaletteItem;
  } catch {
    return null;
  }
}
