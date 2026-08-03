import { Handle, Position, type NodeProps } from '@xyflow/react';
import { memo } from 'react';
import { stageSubtitle, type StageNode as TStageNode } from './model';
import { useNodeStatus } from './StatusContext';

/** Một chặng trên sơ đồ. Hình khối theo lớp `.stage` của mockup để hai bên nhìn như một. */
function StageNodeInner({ id, data, selected }: NodeProps<TStageNode>) {
  const status = useNodeStatus(id);
  const cls = [
    'stage-node',
    data.role === 'from' ? 'stage-node--from' : '',
    data.locked ? 'stage-node--locked' : '',
    status ? `stage-node--${status}` : '',
    selected ? 'stage-node--selected' : '',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div className={cls}>
      {/* Chặng tiếp nhận là đầu luồng nên không có điểm nối vào. */}
      {data.role !== 'from' && <Handle type="target" position={Position.Top} className="stage-node__port" />}

      <span className="stage-node__icon" aria-hidden="true">
        {data.icon}
      </span>
      <div className="stage-node__main">
        <div className="stage-node__name">{data.label}</div>
        <div className="stage-node__sub t-mono">{stageSubtitle(data)}</div>
      </div>
      <div className="stage-node__tail">
        {data.role === 'from' && <span className="badge badge--info badge--plain">NGUỒN</span>}
        {data.locked && (
          <span className="stage-node__lock" title="Chặng bắt buộc của khung chuẩn, không gỡ được">
            🔒
          </span>
        )}
        {status === 'error' && <span className="badge badge--err">lỗi</span>}
        {status === 'warn' && <span className="badge badge--warn">cảnh báo</span>}
      </div>

      <Handle type="source" position={Position.Bottom} className="stage-node__port" />
    </div>
  );
}

export const StageNodeView = memo(StageNodeInner);
