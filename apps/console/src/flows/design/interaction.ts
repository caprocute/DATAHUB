import { createContext, useContext } from 'react';

/**
 * Dữ liệu kéo từ bảng thành phần.
 *
 * Chỉ mang **tham chiếu catalog** thay vì cả mục palette như bản trước: mọi thứ
 * khác (tiêu đề, cú pháp, nhóm màu) tra được từ catalog, chép lại dễ lệch.
 */
export interface DraggedNode {
  ref: string;
}

/** Thao tác mà cạnh và nút gọi ngược lên vùng sơ đồ. */
export interface Interaction {
  /** Chèn một chặng vào giữa cạnh, cắt cạnh cũ thành hai. */
  insertOnEdge: (edgeId: string, item: DraggedNode) => void;
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

export function readDraggedItem(dt: DataTransfer): DraggedNode | null {
  const raw = dt.getData(DRAG_MIME);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as DraggedNode;
    return parsed.ref ? parsed : null;
  } catch {
    return null;
  }
}
