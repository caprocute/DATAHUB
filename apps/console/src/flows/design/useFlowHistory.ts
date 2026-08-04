import { useCallback, useEffect, useRef, useState } from 'react';
import type { SeqEdge, StageNode } from '../core/model';

interface Snapshot {
  nodes: StageNode[];
  edges: SeqEdge[];
}

const LIMIT = 60;

/**
 * Chụp trạng thái sơ đồ.
 *
 * Sao thủ công thay vì `structuredClone`: nút của React Flow có thể mang giá trị
 * không sao chép được (hàm, phần tử DOM đo đạc), khi đó `structuredClone` ném
 * `DataCloneError` và cả lịch sử hỏng theo. Chỉ cần tách các mức mà thao tác sửa
 * chạm tới là đủ để hoàn tác đúng.
 */
function clone(nodes: StageNode[], edges: SeqEdge[]): Snapshot {
  return {
    nodes: nodes.map((n) => ({
      ...n,
      position: { ...n.position },
      data: {
        ...n.data,
        props: { ...n.data.props },
        mappings: n.data.mappings?.map((m) => ({ ...m })),
      },
    })),
    edges: edges.map((e) => ({ ...e, data: e.data ? { ...e.data } : undefined })),
  };
}

/**
 * Lịch sử thao tác trên sơ đồ. Mỗi lần `commit` chụp trạng thái hiện tại
 * trước khi áp thay đổi; Undo/Redo đổi qua lại giữa các bản chụp.
 *
 * Không ghi lại từng khung hình khi kéo nút — chỉ ghi khi thao tác nghiệp vụ
 * (thêm/gỡ/nối/sửa thuộc tính) gọi `commit`.
 */
export function useFlowHistory(
  nodes: StageNode[],
  edges: SeqEdge[],
  setNodes: (n: StageNode[] | ((prev: StageNode[]) => StageNode[])) => void,
  setEdges: (e: SeqEdge[] | ((prev: SeqEdge[]) => SeqEdge[])) => void,
) {
  const nodesRef = useRef(nodes);
  const edgesRef = useRef(edges);
  nodesRef.current = nodes;
  edgesRef.current = edges;

  const past = useRef<Snapshot[]>([]);
  const future = useRef<Snapshot[]>([]);
  const [version, setVersion] = useState(0);

  const commit = useCallback(() => {
    past.current.push(clone(nodesRef.current, edgesRef.current));
    if (past.current.length > LIMIT) past.current.shift();
    future.current = [];
    setVersion((v) => v + 1);
  }, []);

  const undo = useCallback(() => {
    const snap = past.current.pop();
    if (!snap) return false;
    future.current.push(clone(nodesRef.current, edgesRef.current));
    setNodes(snap.nodes);
    setEdges(snap.edges);
    setVersion((v) => v + 1);
    return true;
  }, [setNodes, setEdges]);

  const redo = useCallback(() => {
    const snap = future.current.pop();
    if (!snap) return false;
    past.current.push(clone(nodesRef.current, edgesRef.current));
    setNodes(snap.nodes);
    setEdges(snap.edges);
    setVersion((v) => v + 1);
    return true;
  }, [setNodes, setEdges]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const mod = e.metaKey || e.ctrlKey;
      if (!mod) return;
      const t = e.target as HTMLElement | null;
      if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return;
      const key = e.key.toLowerCase();
      if (key === 'z' && !e.shiftKey) {
        e.preventDefault();
        undo();
      } else if (key === 'z' && e.shiftKey) {
        e.preventDefault();
        redo();
      } else if (key === 'y') {
        e.preventDefault();
        redo();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [undo, redo]);

  return {
    commit,
    undo,
    redo,
    canUndo: past.current.length > 0,
    canRedo: future.current.length > 0,
    /** Chỉ để buộc re-render khi canUndo/canRedo đổi. */
    version,
  };
}
