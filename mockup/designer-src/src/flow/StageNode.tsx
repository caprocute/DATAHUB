import { Handle, Position, type NodeProps } from '@xyflow/react';
import { memo } from 'react';
import type { NodeTone } from '../catalog/catalog';
import { stageSubtitle, type StageNode as TStageNode } from './model';
import { useNodeStatus } from './StatusContext';

const TONE_LABEL: Record<NodeTone, string> = {
  trigger: 'Trigger',
  auth: 'Auth',
  eip: 'Logic',
  transform: 'Transform',
  enrich: 'Enrich',
  dest: 'Action',
};

/** Node kiểu n8N: thẻ ngang, ô icon màu theo nhóm, cổng trái/phải. */
function StageNodeInner({ id, data, selected }: NodeProps<TStageNode>) {
  const status = useNodeStatus(id);
  const tone = (data.tone as NodeTone | undefined) ?? 'dest';
  const cls = [
    'n8n-node',
    `n8n-node--${tone}`,
    data.role === 'from' ? 'n8n-node--from' : '',
    data.locked ? 'n8n-node--locked' : '',
    status ? `n8n-node--${status}` : '',
    selected ? 'n8n-node--selected' : '',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div className={cls}>
      {data.role !== 'from' && (
        <Handle type="target" position={Position.Left} className="n8n-node__port" />
      )}

      <div className="n8n-node__icon" aria-hidden="true">
        {data.icon}
      </div>
      <div className="n8n-node__body">
        <div className="n8n-node__kind">{TONE_LABEL[tone]}</div>
        <div className="n8n-node__name">{data.label}</div>
        <div className="n8n-node__sub t-mono">{stageSubtitle(data)}</div>
      </div>
      <div className="n8n-node__meta">
        {data.locked && (
          <span className="n8n-node__lock" title="Chặng bắt buộc — không gỡ được">
            🔒
          </span>
        )}
        {status === 'error' && <span className="n8n-node__dot n8n-node__dot--err" title="Có lỗi" />}
        {status === 'warn' && <span className="n8n-node__dot n8n-node__dot--warn" title="Có cảnh báo" />}
      </div>

      <Handle type="source" position={Position.Right} className="n8n-node__port" />
    </div>
  );
}

export const StageNodeView = memo(StageNodeInner);
