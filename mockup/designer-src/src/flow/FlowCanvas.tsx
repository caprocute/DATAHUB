import {
  Background,
  BackgroundVariant,
  ConnectionLineType,
  Controls,
  MiniMap,
  ReactFlow,
  useReactFlow,
  type Connection,
  type EdgeChange,
  type NodeChange,
  type OnBeforeDelete,
  type XYPosition,
} from '@xyflow/react';
import { useCallback, useMemo, useRef, type DragEvent } from 'react';
import type { PaletteItem } from '../catalog/catalog';
import { readDraggedItem } from './interaction';
import type { SeqEdge, StageNode } from './model';
import { SeqEdgeView } from './SeqEdge';
import { StageNodeView } from './StageNode';

interface Props {
  nodes: StageNode[];
  edges: SeqEdge[];
  onNodesChange: (c: NodeChange<StageNode>[]) => void;
  onEdgesChange: (c: EdgeChange<SeqEdge>[]) => void;
  onConnect: (c: Connection) => void;
  onReconnect: (oldEdge: SeqEdge, c: Connection) => void;
  onBeforeDelete: OnBeforeDelete<StageNode, SeqEdge>;
  onNodesDelete: (deleted: StageNode[]) => void;
  onDropItem: (item: PaletteItem, pos: XYPosition) => void;
  colorMode: 'light' | 'dark';
}

export function FlowCanvas({
  nodes,
  edges,
  onNodesChange,
  onEdgesChange,
  onConnect,
  onReconnect,
  onBeforeDelete,
  onNodesDelete,
  onDropItem,
  colorMode,
}: Props) {
  const nodeTypes = useMemo(() => ({ stage: StageNodeView }), []);
  const edgeTypes = useMemo(() => ({ seq: SeqEdgeView }), []);
  const { screenToFlowPosition } = useReactFlow();
  const wrap = useRef<HTMLDivElement>(null);

  const onDragOver = useCallback((e: DragEvent) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'copy';
  }, []);

  const onDrop = useCallback(
    (e: DragEvent) => {
      e.preventDefault();
      const item = readDraggedItem(e.dataTransfer);
      if (!item) return;
      // Quy đổi toạ độ con trỏ sang hệ toạ độ sơ đồ để chặng rơi đúng chỗ thả,
      // kể cả khi người dùng đã kéo hoặc phóng khung nhìn.
      onDropItem(item, screenToFlowPosition({ x: e.clientX, y: e.clientY }));
    },
    [onDropItem, screenToFlowPosition],
  );

  return (
    <div className="canvas-rf" ref={wrap} onDragOver={onDragOver} onDrop={onDrop}>
      <ReactFlow<StageNode, SeqEdge>
        nodes={nodes}
        edges={edges}
        nodeTypes={nodeTypes}
        edgeTypes={edgeTypes}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onConnect={onConnect}
        onReconnect={onReconnect}
        onBeforeDelete={onBeforeDelete}
        onNodesDelete={onNodesDelete}
        defaultEdgeOptions={{ type: 'seq' }}
        defaultMarkerColor="var(--c-border-2)"
        connectionLineType={ConnectionLineType.Bezier}
        colorMode={colorMode}
        fitView
        fitViewOptions={{ padding: 0.22, maxZoom: 1 }}
        minZoom={0.25}
        maxZoom={1.6}
        proOptions={{ hideAttribution: false }}
        deleteKeyCode={['Backspace', 'Delete']}
        multiSelectionKeyCode={['Meta', 'Control']}
        nodesConnectable
        elevateEdgesOnSelect
      >
        <Background variant={BackgroundVariant.Dots} gap={20} size={1.2} />
        <Controls showInteractive={false} position="bottom-left" />
        <MiniMap
          pannable
          zoomable
          nodeStrokeWidth={2}
          position="bottom-right"
          nodeColor={(n) => {
            const t = (n.data as { tone?: string } | undefined)?.tone;
            if (t === 'trigger') return 'var(--c-ok-500)';
            if (t === 'auth') return 'var(--c-warn-500)';
            if (t === 'eip') return 'var(--c-brand-500)';
            if (t === 'transform') return '#0d9488';
            if (t === 'enrich') return '#7c3aed';
            return 'var(--c-text-3)';
          }}
        />
      </ReactFlow>
    </div>
  );
}
