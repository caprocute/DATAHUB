import {
  addEdge,
  useEdgesState,
  useNodesState,
  useReactFlow,
  type Connection,
  type OnBeforeDelete,
  type XYPosition,
} from '@xyflow/react';
import { App as AntApp, Button, Checkbox, Input, Modal, Segmented } from 'antd';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { CAMEL_VERSION, CATALOG_SIZE, type PaletteItem } from './catalog/catalog';
import { FlowCanvas } from './flow/FlowCanvas';
import { InsertMenu } from './flow/InsertMenu';
import { InteractionContext, type Interaction } from './flow/interaction';
import { autoLayout, NODE_H } from './flow/layout';
import {
  INITIAL_EDGES,
  INITIAL_NODES,
  nextId,
  ROUTE_ID,
  stageFromPalette,
  type FieldMapping,
  type SeqEdge,
  type StageData,
  type StageNode,
} from './flow/model';
import { StatusContext } from './flow/StatusContext';
import { useFlowHistory } from './flow/useFlowHistory';
import { FindingsPanel } from './panels/Findings';
import { Palette } from './panels/Palette';
import { PropertiesPanel } from './panels/Properties';
import { YamlPanel } from './panels/YamlPanel';
import type { Mode } from './theme/tokens';
import { statusByNode, validate } from './validate';
import { emitRouteYaml } from './yaml/emit';

/** Chặng có nhiều đường ra hợp lệ. Chặng khác chỉ có một đường ra: nối lại là thay đường. */
const BRANCHING = new Set(['choice', 'multicast', 'loadBalance', 'recipientList']);

const LAID_OUT = autoLayout(INITIAL_NODES, INITIAL_EDGES);

interface Props {
  mode: Mode;
  onDirty: () => void;
  onStatus: (counts: { errors: number; warns: number }) => void;
}

export function Designer({ mode, onDirty, onStatus }: Props) {
  const [nodes, setNodes, onNodesChange] = useNodesState<StageNode>(LAID_OUT);
  const [edges, setEdges, onEdgesChange] = useEdgesState<SeqEdge>(INITIAL_EDGES);
  const [view, setView] = useState<'so-do' | 'van-ban'>('so-do');
  const [insertAt, setInsertAt] = useState<{ edgeId: string; at: XYPosition } | null>(null);
  const [branchEdgeId, setBranchEdgeId] = useState<string | null>(null);
  const { fitView } = useReactFlow();
  const { message } = AntApp.useApp();
  const history = useFlowHistory(nodes, edges, setNodes, setEdges);
  const { commit, undo: undoHist, redo: redoHist, canUndo, canRedo } = history;

  const edgesRef = useRef(edges);
  edgesRef.current = edges;

  const findings = useMemo(() => validate(nodes, edges), [nodes, edges]);
  const status = useMemo(() => statusByNode(findings), [findings]);
  const yaml = useMemo(
    () => emitRouteYaml(nodes, edges, { routeId: ROUTE_ID, errorHandler: true }),
    [nodes, edges],
  );

  const selected = nodes.find((n) => n.selected);
  const hasFrom = nodes.some((n) => n.data.role === 'from');
  const errorCount = findings.filter((f) => f.level === 'error').length;

  /** Phiên sửa thuộc tính: chỉ chụp lịch sử một lần khi bắt đầu sửa chặng đang chọn. */
  const editSession = useRef(false);
  useEffect(() => {
    editSession.current = false;
  }, [selected?.id]);

  const markDirty = useCallback(() => {
    commit();
    onDirty();
  }, [commit, onDirty]);

  useEffect(() => {
    onStatus({ errors: errorCount, warns: findings.length - errorCount });
  }, [errorCount, findings.length, onStatus]);

  const patchSelected = useCallback(
    (patch: (d: StageData) => StageData) => {
      if (!editSession.current) {
        commit();
        editSession.current = true;
      }
      setNodes((ns) => ns.map((n) => (n.selected ? { ...n, data: patch(n.data) } : n)));
      onDirty();
    },
    [setNodes, commit, onDirty],
  );

  const onConnect = useCallback(
    (c: Connection) => {
      markDirty();
      setEdges((es) => {
        const source = nodes.find((n) => n.id === c.source);
        const branching = source ? BRANCHING.has(source.data.ref) : false;
        const kept = branching ? es : es.filter((e) => e.source !== c.source);
        return addEdge({ ...c, type: 'seq' }, kept);
      });
    },
    [nodes, setEdges, markDirty],
  );

  const onReconnect = useCallback(
    (oldEdge: SeqEdge, c: Connection) => {
      markDirty();
      setEdges((es) =>
        addEdge({ ...c, type: 'seq', data: oldEdge.data }, es.filter((e) => e.id !== oldEdge.id)),
      );
    },
    [setEdges, markDirty],
  );

  const addStage = useCallback(
    (item: PaletteItem, pos: XYPosition) => {
      const role = item.consumerOnly && !hasFrom ? 'from' : 'step';
      const node: StageNode = {
        id: nextId('n'),
        type: 'stage',
        position: pos,
        data: stageFromPalette(item, role),
        selected: true,
      };

      const tails = nodes.filter((n) => !edges.some((e) => e.source === n.id));
      const tail = role === 'step' && tails.length === 1 ? tails[0] : null;

      markDirty();
      setNodes((ns) => [...ns.map((n) => ({ ...n, selected: false })), node]);
      if (tail) {
        setEdges((es) => [...es, { id: nextId('e'), source: tail.id, target: node.id, type: 'seq' }]);
        message.info(`Đã thêm “${item.label}” nối sau chặng “${tail.data.label}”`);
      } else {
        message.info(`Đã thêm “${item.label}” — hãy nối vào luồng bằng điểm nối trên nút`);
      }
    },
    [nodes, edges, hasFrom, setNodes, setEdges, markDirty, message],
  );

  const insertOnEdge = useCallback(
    (edgeId: string, item: PaletteItem) => {
      const edge = edges.find((e) => e.id === edgeId);
      if (!edge) return;
      const src = nodes.find((n) => n.id === edge.source);
      const tgt = nodes.find((n) => n.id === edge.target);
      if (!src || !tgt) return;

      const midY = (src.position.y + tgt.position.y) / 2;
      const node: StageNode = {
        id: nextId('n'),
        type: 'stage',
        position: { x: (src.position.x + tgt.position.x) / 2, y: midY },
        data: stageFromPalette(item, 'step'),
        selected: true,
      };
      const shift = NODE_H + 44;

      markDirty();
      setNodes((ns) => [
        ...ns.map((n) => ({
          ...n,
          selected: false,
          position: n.position.y > midY ? { ...n.position, y: n.position.y + shift } : n.position,
        })),
        node,
      ]);
      setEdges((es) => [
        ...es.filter((e) => e.id !== edgeId),
        { id: nextId('e'), source: edge.source, target: node.id, type: 'seq', data: edge.data },
        { id: nextId('e'), source: node.id, target: edge.target, type: 'seq' },
      ]);
      setInsertAt(null);
    },
    [nodes, edges, setNodes, setEdges, markDirty],
  );

  const onBeforeDelete = useCallback<OnBeforeDelete<StageNode, SeqEdge>>(
    async ({ nodes: toDelete, edges: edgesToDelete }) => {
      const locked = toDelete.filter((n) => n.data.locked);
      if (locked.length > 0) {
        message.warning(
          locked.length === 1
            ? `Chặng “${locked[0].data.label}” là chặng bắt buộc của khung chuẩn, không gỡ được`
            : `${locked.length} chặng bắt buộc của khung chuẩn không gỡ được`,
        );
      }
      const allowed = toDelete.filter((n) => !n.data.locked);
      if (allowed.length === 0 && edgesToDelete.length === 0) return false;
      return { nodes: allowed, edges: edgesToDelete };
    },
    [message],
  );

  const onNodesDelete = useCallback(
    (deleted: StageNode[]) => {
      const before = edgesRef.current;
      const bypass: SeqEdge[] = [];
      for (const n of deleted) {
        const ins = before.filter((e) => e.target === n.id);
        const outs = before.filter((e) => e.source === n.id);
        for (const i of ins) {
          for (const o of outs) {
            if (deleted.some((d) => d.id === i.source || d.id === o.target)) continue;
            bypass.push({ id: nextId('e'), source: i.source, target: o.target, type: 'seq', data: i.data });
          }
        }
      }
      if (bypass.length) setEdges((es) => [...es, ...bypass]);
      onDirty();
    },
    [setEdges, onDirty],
  );

  const deleteSelected = useCallback(() => {
    const n = nodes.find((x) => x.selected);
    if (!n) return;
    if (n.data.locked) {
      message.warning(`Chặng “${n.data.label}” là chặng bắt buộc của khung chuẩn, không gỡ được`);
      return;
    }
    markDirty();
    onNodesDelete([n]);
    setNodes((ns) => ns.filter((x) => x.id !== n.id));
    setEdges((es) => es.filter((e) => e.source !== n.id && e.target !== n.id));
  }, [nodes, onNodesDelete, setNodes, setEdges, message, markDirty]);

  const relayout = useCallback(() => {
    markDirty();
    setNodes((ns) => autoLayout(ns, edgesRef.current));
    window.setTimeout(() => fitView({ padding: 0.18, maxZoom: 1, duration: 300 }), 30);
  }, [setNodes, fitView, markDirty]);

  const selectNode = useCallback(
    (id: string) => {
      setNodes((ns) => ns.map((n) => ({ ...n, selected: n.id === id })));
      setView('so-do');
    },
    [setNodes],
  );

  const interaction = useMemo<Interaction>(
    () => ({
      insertOnEdge,
      openInsertMenu: (edgeId, at) => setInsertAt({ edgeId, at }),
      editBranch: (edgeId) => setBranchEdgeId(edgeId),
    }),
    [insertOnEdge],
  );

  const branchEdge = edges.find((e) => e.id === branchEdgeId);
  const [draftWhen, setDraftWhen] = useState('');
  const [draftOtherwise, setDraftOtherwise] = useState(false);

  useEffect(() => {
    if (branchEdge) {
      setDraftWhen(branchEdge.data?.when ?? '');
      setDraftOtherwise(Boolean(branchEdge.data?.otherwise));
    }
  }, [branchEdgeId, branchEdge]);

  const saveBranch = () => {
    markDirty();
    setEdges((es) =>
      es.map((e) =>
        e.id === branchEdgeId
          ? { ...e, data: draftOtherwise ? { otherwise: true } : { when: draftWhen } }
          : e,
      ),
    );
    setBranchEdgeId(null);
  };

  const undo = () => {
    if (undoHist()) {
      editSession.current = false;
      onDirty();
      message.info('Đã hoàn tác');
    }
  };
  const redo = () => {
    if (redoHist()) {
      editSession.current = false;
      onDirty();
      message.info('Đã làm lại');
    }
  };

  return (
    <InteractionContext.Provider value={interaction}>
      <StatusContext.Provider value={status}>
        <div className="designer designer--rf mb-5">
          <Palette hasFrom={hasFrom} />

          <div className="panel panel--canvas">
            <div className="panel__head">
              <Segmented<'so-do' | 'van-ban'>
                size="small"
                value={view}
                onChange={setView}
                options={[
                  { label: 'Sơ đồ', value: 'so-do' },
                  { label: 'Văn bản', value: 'van-ban' },
                ]}
              />
              <span className="t-small t-muted" style={{ fontWeight: 400 }}>
                {nodes.length} chặng · Camel {CAMEL_VERSION}
              </span>
              <div style={{ marginLeft: 'auto' }} className="row">
                <Button size="small" onClick={undo} disabled={!canUndo || view !== 'so-do'} title="⌘Z / Ctrl+Z">
                  ↶ Hoàn tác
                </Button>
                <Button size="small" onClick={redo} disabled={!canRedo || view !== 'so-do'} title="⇧⌘Z / Ctrl+Y">
                  ↷ Làm lại
                </Button>
                <Button size="small" onClick={relayout} disabled={view !== 'so-do'}>
                  Tự sắp xếp
                </Button>
                <Button
                  size="small"
                  onClick={() => fitView({ padding: 0.18, maxZoom: 1, duration: 300 })}
                  disabled={view !== 'so-do'}
                >
                  Vừa khung
                </Button>
                <Button size="small" danger onClick={deleteSelected} disabled={!selected || view !== 'so-do'}>
                  Gỡ chặng
                </Button>
              </div>
            </div>

            {view === 'so-do' ? (
              <FlowCanvas
                nodes={nodes}
                edges={edges}
                onNodesChange={onNodesChange}
                onEdgesChange={(c) => {
                  if (c.some((x) => x.type === 'remove')) markDirty();
                  onEdgesChange(c);
                }}
                onConnect={onConnect}
                onReconnect={onReconnect}
                onBeforeDelete={async (args) => {
                  const allowed = await onBeforeDelete(args);
                  if (allowed) markDirty();
                  return allowed;
                }}
                onNodesDelete={onNodesDelete}
                onDropItem={addStage}
                colorMode={mode}
              />
            ) : (
              <div className="panel__body panel__body--flush">
                <pre className="code code--yaml code--tall">{yaml}</pre>
              </div>
            )}
          </div>

          <PropertiesPanel
            node={selected}
            onLabel={(v) => patchSelected((d) => ({ ...d, label: v }))}
            onUri={(v) => patchSelected((d) => ({ ...d, uri: v }))}
            onProp={(k, v) =>
              patchSelected((d) => {
                const props = { ...d.props };
                if (v === undefined) delete props[k];
                else props[k] = v;
                return { ...d, props };
              })
            }
            onMappings={(m: FieldMapping[]) => patchSelected((d) => ({ ...d, mappings: m }))}
            onDelete={deleteSelected}
          />
        </div>

        <div className="grid grid--2 mb-5">
          <FindingsPanel findings={findings} onSelect={selectNode} />
          <YamlPanel yaml={yaml} routeId={ROUTE_ID} />
        </div>

        <p className="t-small t-muted">
          Danh mục thành phần trong bản minh họa gồm {CATALOG_SIZE.components} thành phần Camel và{' '}
          {CATALOG_SIZE.patterns} mẫu EIP, trích từ catalog chính thức của Camel {CAMEL_VERSION}. Bản đầy đủ có hơn 400
          thành phần, nạp từ máy chủ theo phiên bản Camel đang chạy.
          {errorCount > 0 && ' Còn lỗi nên nút gửi duyệt đang bị chặn.'} Hoàn tác / làm lại: ⌘Z · ⇧⌘Z (hoặc Ctrl+Z ·
          Ctrl+Y).
        </p>

        {insertAt && (
          <InsertMenu
            at={insertAt.at}
            onPick={(item) => insertOnEdge(insertAt.edgeId, item)}
            onClose={() => setInsertAt(null)}
          />
        )}

        <Modal
          title="Điều kiện nhánh định tuyến"
          open={Boolean(branchEdgeId)}
          onCancel={() => setBranchEdgeId(null)}
          onOk={saveBranch}
          okText="Lưu"
          cancelText="Hủy"
          width={520}
        >
          <div className="field">
            <label className="field__label">Biểu thức điều kiện</label>
            <Input
              className="t-mono"
              placeholder="${header.loaiHoSo} == 'CAP_MOI'"
              value={draftWhen}
              disabled={draftOtherwise}
              onChange={(e) => setDraftWhen(e.target.value)}
            />
            <div className="field__hint">
              Ngôn ngữ biểu thức <span className="t-mono">simple</span> của Camel. Bản tin khớp điều kiện sẽ đi theo
              nhánh này.
            </div>
          </div>
          <Checkbox checked={draftOtherwise} onChange={(e) => setDraftOtherwise(e.target.checked)}>
            Đặt làm nhánh mặc định — nhận mọi bản tin không khớp luật nào
          </Checkbox>
        </Modal>
      </StatusContext.Provider>
    </InteractionContext.Provider>
  );
}
