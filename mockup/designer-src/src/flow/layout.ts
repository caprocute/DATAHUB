import dagre from 'dagre';
import type { SeqEdge, StageNode } from './model';

export const NODE_W = 264;
export const NODE_H = 60;

/**
 * Sắp xếp sơ đồ theo chiều dọc.
 *
 * Luồng tích hợp đọc từ trên xuống nên dùng `TB`; nhánh của `choice` tự tách sang hai
 * bên rồi hợp lại tại chặng có nhiều cạnh vào.
 */
export function autoLayout(nodes: StageNode[], edges: SeqEdge[]): StageNode[] {
  const g = new dagre.graphlib.Graph();
  g.setDefaultEdgeLabel(() => ({}));
  g.setGraph({ rankdir: 'TB', nodesep: 28, ranksep: 44, marginx: 24, marginy: 24 });

  for (const n of nodes) g.setNode(n.id, { width: NODE_W, height: NODE_H });
  for (const e of edges) g.setEdge(e.source, e.target);

  dagre.layout(g);

  return nodes.map((n) => {
    const p = g.node(n.id);
    // dagre trả về tâm nút, React Flow cần góc trên bên trái.
    return p ? { ...n, position: { x: p.x - NODE_W / 2, y: p.y - NODE_H / 2 } } : n;
  });
}
