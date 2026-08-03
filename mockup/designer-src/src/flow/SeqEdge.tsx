import { BaseEdge, EdgeLabelRenderer, getBezierPath, type EdgeProps } from '@xyflow/react';
import { useState } from 'react';
import { readDraggedItem, useInteraction } from './interaction';
import type { SeqEdge as TSeqEdge } from './model';

/**
 * Cạnh cong kiểu n8N giữa hai chặng.
 *
 * Chốt `＋` giữa cạnh: bấm mở menu hoặc thả thành phần từ palette để chèn vào giữa.
 */
export function SeqEdgeView({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  sourcePosition,
  targetPosition,
  data,
  selected,
}: EdgeProps<TSeqEdge>) {
  const [path, labelX, labelY] = getBezierPath({
    sourceX,
    sourceY,
    targetX,
    targetY,
    sourcePosition,
    targetPosition,
    curvature: 0.25,
  });
  const { openInsertMenu, insertOnEdge, editBranch } = useInteraction();
  const [over, setOver] = useState(false);

  const branchLabel = data?.otherwise ? 'mặc định' : data?.when;

  return (
    <>
      <BaseEdge id={id} path={path} className={selected ? 'seq-edge is-selected' : 'seq-edge'} />
      <EdgeLabelRenderer>
        <div
          className="seq-edge__tools"
          style={{ transform: `translate(-50%, -50%) translate(${labelX}px, ${labelY}px)` }}
        >
          {branchLabel && (
            <button
              type="button"
              className="seq-edge__cond t-mono"
              title="Sửa điều kiện nhánh"
              onClick={() => editBranch(id)}
            >
              {branchLabel}
            </button>
          )}
          <button
            type="button"
            className={over ? 'seq-edge__add is-over' : 'seq-edge__add'}
            title="Chèn chặng vào giữa — bấm để chọn, hoặc thả thành phần đang kéo vào đây"
            onClick={(e) => openInsertMenu(id, { x: e.clientX, y: e.clientY })}
            onDragOver={(e) => {
              e.preventDefault();
              e.stopPropagation();
              e.dataTransfer.dropEffect = 'copy';
              setOver(true);
            }}
            onDragLeave={() => setOver(false)}
            onDrop={(e) => {
              e.preventDefault();
              e.stopPropagation();
              setOver(false);
              const item = readDraggedItem(e.dataTransfer);
              if (item) insertOnEdge(id, item);
            }}
          >
            ＋
          </button>
        </div>
      </EdgeLabelRenderer>
    </>
  );
}
