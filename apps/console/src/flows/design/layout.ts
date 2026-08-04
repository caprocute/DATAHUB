import dagre from 'dagre';
import type { SeqEdge, StageNode } from '../core/model';

/** Kích thước node kiểu n8N (thẻ ngang, icon trái). */
export const NODE_W = 220;
export const NODE_H = 68;

/**
 * Sắp xếp sơ đồ trái → phải (giống n8N).
 *
 * Nhánh `choice` tự tách theo chiều dọc rồi hợp lại tại chặng có nhiều cạnh vào.
 */
export function autoLayout(nodes: StageNode[], edges: SeqEdge[]): StageNode[] {
  const g = new dagre.graphlib.Graph();
  g.setDefaultEdgeLabel(() => ({}));
  g.setGraph({ rankdir: 'LR', nodesep: 36, ranksep: 72, marginx: 40, marginy: 40 });

  for (const n of nodes) g.setNode(n.id, { width: NODE_W, height: NODE_H });
  for (const e of edges) g.setEdge(e.source, e.target);

  dagre.layout(g);

  return nodes.map((n) => {
    const p = g.node(n.id);
    // dagre trả về tâm nút, React Flow cần góc trên bên trái.
    return p ? { ...n, position: { x: p.x - NODE_W / 2, y: p.y - NODE_H / 2 } } : n;
  });
}
