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
  type SeqEdge,
  type StageData,
  type StageNode,
} from './flow/model';
import { StatusContext } from './flow/StatusContext';
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
  // Lấy `message` qua context để hộp thông báo đổi màu theo chế độ sáng/tối.
  const { message } = AntApp.useApp();

  // Việc gỡ chặng cần biết các cạnh trước khi React Flow bỏ chúng đi, để nối lại
  // chặng trước với chặng sau.
  const edgesRef = useRef(edges);
  edgesRef.current = edges;

  const findings = useMemo(() => validate(nodes, edges), [nodes, edges]);
  const status = useMemo(() => statusByNode(findings), [findings]);
  const yaml = useMemo(() => emitRouteYaml(nodes, edges, { routeId: ROUTE_ID, errorHandler: true }), [nodes, edges]);

  const selected = nodes.find((n) => n.selected);
  const hasFrom = nodes.some((n) => n.data.role === 'from');
  const errorCount = findings.filter((f) => f.level === 'error').length;

  // Nút “Gửi duyệt” nằm ở đầu trang nên số lỗi phải báo ngược lên đó.
  useEffect(() => {
    onStatus({ errors: errorCount, warns: findings.length - errorCount });
  }, [errorCount, findings.length, onStatus]);

  /* ---------- Sửa dữ liệu chặng ---------- */

  const patchSelected = useCallback(
    (patch: (d: StageData) => StageData) => {
      setNodes((ns) => ns.map((n) => (n.selected ? { ...n, data: patch(n.data) } : n)));
      onDirty();
    },
    [setNodes, onDirty],
  );

  /* ---------- Nối và đổi đường ---------- */

  const onConnect = useCallback(
    (c: Connection) => {
      setEdges((es) => {
        const source = nodes.find((n) => n.id === c.source);
        const branching = source ? BRANCHING.has(source.data.ref) : false;
        // Chặng thường chỉ đi tiếp một đường, nên nối lại là thay đường cũ chứ không
        // sinh nhánh — nhánh chỉ có nghĩa ở chặng định tuyến.
        const kept = branching ? es : es.filter((e) => e.source !== c.source);
        return addEdge({ ...c, type: 'seq' }, kept);
      });
      onDirty();
    },
    [nodes, setEdges, onDirty],
  );

  const onReconnect = useCallback(
    (oldEdge: SeqEdge, c: Connection) => {
      setEdges((es) => addEdge({ ...c, type: 'seq', data: oldEdge.data }, es.filter((e) => e.id !== oldEdge.id)));
      onDirty();
    },
    [setEdges, onDirty],
  );

  /* ---------- Thêm chặng ---------- */

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

      // Nối tiếp vào đuôi luồng nếu chỉ có một chặng đang hở đường ra — đây là ý muốn
      // thường gặp khi thả một thành phần vào chỗ trống.
      const tails = nodes.filter((n) => !edges.some((e) => e.source === n.id));
      const tail = role === 'step' && tails.length === 1 ? tails[0] : null;

      setNodes((ns) => [...ns.map((n) => ({ ...n, selected: false })), node]);
      if (tail) {
        setEdges((es) => [...es, { id: nextId('e'), source: tail.id, target: node.id, type: 'seq' }]);
        message.info(`Đã thêm “${item.label}” nối sau chặng “${tail.data.label}”`);
      } else {
        message.info(`Đã thêm “${item.label}” — hãy nối vào luồng bằng điểm nối trên nút`);
      }
      onDirty();
    },
    [nodes, edges, hasFrom, setNodes, setEdges, onDirty, message],
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

      setNodes((ns) => [
        // Đẩy phần dưới xuống để chỗ chèn có khoảng trống, thay vì sắp xếp lại cả sơ đồ
        // và làm mất cách bố trí người dùng đã kéo.
        ...ns.map((n) => ({
          ...n,
          selected: false,
          position: n.position.y > midY ? { ...n.position, y: n.position.y + shift } : n.position,
        })),
        node,
      ]);
      setEdges((es) => [
        ...es.filter((e) => e.id !== edgeId),
        // Cạnh đầu giữ điều kiện nhánh của cạnh cũ, cạnh sau là nối tiếp bình thường.
        { id: nextId('e'), source: edge.source, target: node.id, type: 'seq', data: edge.data },
        { id: nextId('e'), source: node.id, target: edge.target, type: 'seq' },
      ]);
      setInsertAt(null);
      onDirty();
    },
    [nodes, edges, setNodes, setEdges, onDirty],
  );

  /* ---------- Gỡ chặng ---------- */

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
        // Nối chặng trước với chặng sau để luồng không bị đứt khi gỡ một chặng ở giữa.
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
    onNodesDelete([n]);
    setNodes((ns) => ns.filter((x) => x.id !== n.id));
    setEdges((es) => es.filter((e) => e.source !== n.id && e.target !== n.id));
  }, [nodes, onNodesDelete, setNodes, setEdges, message]);

  /* ---------- Thao tác trên sơ đồ ---------- */

  const relayout = useCallback(() => {
    setNodes((ns) => autoLayout(ns, edgesRef.current));
    window.setTimeout(() => fitView({ padding: 0.18, maxZoom: 1, duration: 300 }), 30);
  }, [setNodes, fitView]);

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

  /* ---------- Sửa điều kiện nhánh ---------- */

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
    setEdges((es) =>
      es.map((e) =>
        e.id === branchEdgeId
          ? { ...e, data: draftOtherwise ? { otherwise: true } : { when: draftWhen } }
          : e,
      ),
    );
    setBranchEdgeId(null);
    onDirty();
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
                onEdgesChange={onEdgesChange}
                onConnect={onConnect}
                onReconnect={onReconnect}
                onBeforeDelete={onBeforeDelete}
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
          {errorCount > 0 && ' Còn lỗi nên nút gửi duyệt đang bị chặn.'}
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
