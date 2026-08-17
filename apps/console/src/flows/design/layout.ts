import dagre from 'dagre';
import { NODE_H, NODE_W, type SeqEdge, type StageNode } from '../core/model';

// Kích thước thẻ lấy thẳng từ `core/model` — **không khai lại ở đây**. Bản sao cũ ghi
// 220×68 trong khi model khai 240×72; dagre đặt nút theo số nhỏ còn React Flow neo cổng
// theo số lớn, nên đường nối lệch khỏi cổng ở mọi cạnh.
export { NODE_H, NODE_W };

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
