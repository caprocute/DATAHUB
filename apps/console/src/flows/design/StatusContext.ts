import { createContext, useContext } from 'react';

export type NodeStatus = 'error' | 'warn';

/**
 * Kết quả kiểm tra theo từng chặng.
 *
 * Đi qua context thay vì nhét vào `data` của nút, để việc kiểm tra lại không phải
 * dựng lại toàn bộ mảng nút — React Flow so sánh tham chiếu nên làm vậy sẽ vẽ lại
 * cả sơ đồ sau mỗi lần bấm phím trong bảng thuộc tính.
 */
export const StatusContext = createContext<Record<string, NodeStatus>>({});

export function useNodeStatus(id: string): NodeStatus | undefined {
  return useContext(StatusContext)[id];
}
