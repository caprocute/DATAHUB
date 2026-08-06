import { ReactFlowProvider, useReactFlow, addEdge, useEdgesState, useNodesState, type Connection, type XYPosition } from '@xyflow/react'
import { App as AntApp, Button, Tag, Typography } from 'antd'
import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import {
  getRoute,
  getTestRun,
  getVersion,
  listTestRuns,
  saveDefinition,
  submitVersion,
  type RouteSummary,
} from '../../api/routesApi'
import { useRoles } from '../../auth/useRoles'
import { CATALOG_RUNTIME, lookupNode, refName } from '../core/catalog'
import { emitRouteYaml } from '../core/emit'
import {
  BRANCHING,
  bumpSeq,
  duplicateStage,
  effectiveSample,
  emptyFlow,
  makeStage,
  nextId,
  NODE_W,
  type SeqEdge,
  type StageData,
  type StageNode,
} from '../core/model'
import { deserialize } from '../core/deserialize'
import { serialize } from '../core/serialize'
import { flatten } from '../core/flatten'
import { applyGraphToTree, unmappedNodes } from '../core/unflatten'
import {
  addEntity,
  duplicateEntity,
  insertAfterAt,
  newStep,
  removeEntity,
  renameEntity,
} from '../core/mutate'
import type { CamelResource } from '../core/tree'
import { prefetchSchemas, statusByNode, validate } from '../core/validate'
import { FlowCanvas } from './FlowCanvas'
import { InteractionContext, type DraggedNode, type Interaction } from './interaction'
import { autoLayout } from './layout'
import { NodeConfig } from './NodeConfig'
import { EntityList } from './EntityList'
import { KameletSpec } from './KameletSpec'
import { Palette } from './Palette'
import { mapWaterfall, RunContext, type StageRun } from './RunContext'
import { StatusContext } from './StatusContext'
import { YamlEditor } from './YamlEditor'
import { useFlowHistory } from './useFlowHistory'
import '@xyflow/react/dist/style.css'
import './designer.css'

/** Biến môi trường gợi ý cho biểu thức (FR-04-036). */
const ENV_VARS: Record<string, string> = {
  LGSP_MOI_TRUONG: import.meta.env.MODE === 'production' ? 'PROD' : 'DEV',
  LGSP_MIEN: 'lgsp.svc',
}

const EMPTY_RUN: Record<string, StageRun> = {}

/**
 * Trạng thái thu gọn panel, nhớ qua các phiên (FR-D-013, G3-6).
 *
 * Dùng `localStorage` là đúng chỗ ở đây: đây là tùy chọn hiển thị của riêng máy này,
 * không phải dữ liệu nghiệp vụ — khác hẳn nhật ký chạy vốn phải nằm ở máy chủ.
 */
function usePanelState(key: string, fallback: boolean) {
  const [open, setOpen] = useState<boolean>(() => {
    try {
      const raw = localStorage.getItem(key)
      return raw === null ? fallback : raw === '1'
    } catch {
      // Trình duyệt chặn lưu trữ (chế độ riêng tư) — vẫn chạy, chỉ là không nhớ.
      return fallback
    }
  })
  useEffect(() => {
    try {
      localStorage.setItem(key, open ? '1' : '0')
    } catch {
      /* không nhớ được thì thôi, không chặn việc chính */
    }
  }, [key, open])
  return [open, setOpen] as const
}

type SaveState = 'saved' | 'dirty' | 'saving' | 'error'

const SAVE_LABEL: Record<SaveState, string> = {
  saved: 'đã lưu',
  dirty: 'chưa lưu',
  saving: 'đang lưu…',
  error: 'lưu lỗi',
}

function DesignerInner() {
  const { code = '' } = useParams()
  const navigate = useNavigate()
  const { message, modal } = AntApp.useApp()
  const { canDesign, canSubmit } = useRoles()
  const { fitView } = useReactFlow()

  const [nodes, setNodes, onNodesChange] = useNodesState<StageNode>([])
  const [edges, setEdges, onEdgesChange] = useEdgesState<SeqEdge>([])
  const [route, setRoute] = useState<RouteSummary | null>(null)
  const [versionNo, setVersionNo] = useState(1)
  const [saveState, setSaveState] = useState<SaveState>('saved')
  const [loading, setLoading] = useState(true)
  const [configOpen, setConfigOpen] = useState(false)
  /** Cửa sổ soạn tham số Kamelet (K3-1) — chỉ mở được khi tài nguyên là Kamelet. */
  const [kameletOpen, setKameletOpen] = useState(false)
  /** Cửa sổ xem/sửa YAML toàn màn hình (đồng bộ ngược về sơ đồ). */
  const [yamlOpen, setYamlOpen] = useState(false)
  // G3-6 — nhớ trạng thái thu gọn giữa các phiên. Người dùng thu panel lại là vì
  // muốn rộng chỗ; mở lại mỗi lần vào là bắt họ thao tác lại từ đầu.
  const [leftOpen, setLeftOpen] = usePanelState('lgsp.designer.left', true)
  const [rightOpen, setRightOpen] = usePanelState('lgsp.designer.right', true)

  /**
   * Bản định nghĩa lúc mở luồng — mốc phát hiện người khác sửa cùng lúc (G3-5).
   *
   * Khai ở đây, trước mọi effect dùng tới. Không dùng `useState`: giá trị chỉ để so
   * sánh lúc lưu, đổi nó không cần vẽ lại sơ đồ.
   */
  const baseYamlRef = useRef<string>('')
  /**
   * Cây `CamelResource` của định nghĩa đang mở (K1 — IP-07).
   *
   * Sơ đồ chỉ là **một cách chiếu** của cây này. Giữ cây lại để lúc sinh YAML thì áp
   * thay đổi lên nó thay vì dựng lại từ sơ đồ phẳng — sơ đồ không biểu diễn nổi khe
   * `doCatch`/`doFinally`, nên sinh từ sơ đồ sẽ **bóp méo** `doTry` thành `choice`
   * và làm bay lớp ngoại lệ (đo thật, xem IP-07 §3.0).
   *
   * `null` khi định nghĩa đã lưu không đọc được — khi đó lùi về bộ sinh cũ.
   */
  const treeRef = useRef<CamelResource | null>(null)
  /**
   * Bản cây để **vẽ** danh sách route (K2-1).
   *
   * `treeRef` là nguồn sự thật lúc sinh YAML (ref nên không gây vẽ lại mỗi lần gõ), còn
   * state này chỉ để giao diện biết mà cập nhật. Hai chỗ luôn đặt cùng lúc qua `setTree`.
   */
  const [tree, setTreeState] = useState<CamelResource | null>(null)
  /** Route đang mở trên canvas; chỉ số trong `tree.entities`. */
  const [activeEntity, setActiveEntity] = useState(0)

  /** Đặt cây ở cả hai chỗ — quên một bên là sinh YAML từ cây cũ. */
  const setTree = useCallback((next: CamelResource | null) => {
    treeRef.current = next
    setTreeState(next)
  }, [])

  const history = useFlowHistory(nodes, edges, setNodes, setEdges)
  const { commit, undo, redo, canUndo, canRedo } = history

  const edgesRef = useRef(edges)
  edgesRef.current = edges

  /* ---------- Nạp luồng ---------- */

  useEffect(() => {
    let alive = true
    ;(async () => {
      setLoading(true)
      try {
        const r = await getRoute(code)
        if (!alive) return
        setRoute(r)
        const v = r.draftVersionNo ?? r.currentVersionNo ?? 1
        setVersionNo(v)
        const ver = await getVersion(code, v)
        if (!alive) return
        // Mốc chống ghi đè: nhớ đúng bản vừa đọc về (G3-5).
        baseYamlRef.current = ver.definitionYaml ?? ''
        try {
          // Lõi cây (K1) đọc được mọi cấu trúc Camel hợp lệ, kể cả `doTry`/`loadBalance`
          // và nhiều route một tệp — thứ bộ đọc cũ hoặc vứt cây con hoặc từ chối mở.
          const parsed = deserialize(ver.definitionYaml ?? '')
          setTree(parsed)
          setActiveEntity(0)
          const g = flatten(parsed)
          bumpSeq([...g.nodes.map((n) => n.id), ...g.edges.map((e) => e.id)])
          setNodes(autoLayout(g.nodes, g.edges))
          setEdges(g.edges)
        } catch {
          // Định nghĩa đã lưu không đọc được (YAML hỏng cú pháp) — dựng luồng
          // trống và nói rõ, không im lặng ghi đè công sức của người dùng.
          setTree(null)
          message.warning('Không đọc được định nghĩa đã lưu — mở luồng trống. Bản trên máy chủ chưa bị thay đổi.')
          const g = emptyFlow()
          setNodes(autoLayout(g.nodes, g.edges))
          setEdges(g.edges)
        }
      } catch (e) {
        message.error(`Không mở được luồng: ${e instanceof Error ? e.message : e}`)
      } finally {
        if (alive) setLoading(false)
      }
    })()
    return () => {
      alive = false
    }
  }, [code, setNodes, setEdges, message])

  /* ---------- Dẫn xuất ---------- */

  const [schemaEpoch, setSchemaEpoch] = useState(0)
  useEffect(() => {
    let alive = true
    void prefetchSchemas(nodes).then((loaded) => alive && loaded && setSchemaEpoch((e) => e + 1))
    return () => {
      alive = false
    }
  }, [nodes])

  const findings = useMemo(() => validate(nodes, edges), [nodes, edges, schemaEpoch])
  const status = useMemo(() => statusByNode(findings), [findings])

  /* ---------- Tô đường chạy của lần chạy thử gần nhất (FR-D-031, G5-4) ---------- */

  const [runStages, setRunStages] = useState<Record<string, StageRun>>(EMPTY_RUN)
  const [runInfo, setRunInfo] = useState<{ at: string; outcome: string } | null>(null)
  const [showRun, setShowRun] = useState(true)

  useEffect(() => {
    let alive = true
    if (!code || nodes.length === 0) return
    void listTestRuns(code, undefined, 1)
      .then(async (r) => {
        const latest = r.items[0]
        if (!alive || !latest) return
        const detail = await getTestRun(code, latest.runId)
        if (!alive) return
        // `mapWaterfall` bỏ qua chặng không ghép được thay vì gán bừa cho nút gần nhất.
        setRunStages(mapWaterfall(detail.stages, nodes))
        setRunInfo({ at: latest.runAt, outcome: latest.outcome })
      })
      .catch(() => {
        // Chưa chạy lần nào, hoặc không đọc được nhật ký — sơ đồ vẫn dùng bình thường.
      })
    return () => {
      alive = false
    }
    // Chỉ phụ thuộc số chặng: `nodes` đổi mỗi lần kéo thả, tải lại nhật ký theo từng
    // cú kéo là gọi máy chủ vô ích.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [code, nodes.length])

  const runOverlay = showRun ? runStages : EMPTY_RUN
  /**
   * YAML của luồng đang sửa.
   *
   * Có cây (mở từ định nghĩa đã lưu) thì **áp thay đổi lên cây** rồi ghi ra — giữ được
   * `doCatch`/`doFinally`, khóa lạ và comment. Sinh thẳng từ sơ đồ phẳng sẽ bóp méo
   * `doTry` thành `choice` và làm bay lớp ngoại lệ.
   *
   * Chưa có cây (luồng dựng mới trên canvas) thì dùng bộ sinh cũ. Chặng **thêm mới**
   * cũng chưa vào được cây, nên khi có chặng như vậy thì cũng lùi về bộ sinh cũ —
   * thà YAML kém tinh gọn còn hơn lặng lẽ bỏ rơi chặng người dùng vừa thêm.
   */
  const yaml = useMemo(() => {
    const current = treeRef.current
    if (current && unmappedNodes(current, nodes).length === 0) {
      return serialize(
        applyGraphToTree(current, nodes, edges, activeEntity),
        baseYamlRef.current || undefined,
      )
    }
    return emitRouteYaml(nodes, edges, { routeId: code || 'draft', errorHandler: true })
  }, [nodes, edges, code, activeEntity])
  const errorCount = findings.filter((f) => f.level === 'error').length
  const selected = nodes.find((n) => n.selected)
  const selectedSample = useMemo(
    () => (selected ? effectiveSample(selected.id, nodes, edges) : undefined),
    [selected, nodes, edges],
  )
  const hasFrom = nodes.some((n) => n.data.role === 'from')

  const markDirty = useCallback(() => {
    commit()
    setSaveState('dirty')
  }, [commit])

  /* ---------- Lưu ---------- */

  const doSave = useCallback(async () => {
    if (!canDesign) return
    setSaveState('saving')
    try {
      // Chống ghi đè khi hai người cùng sửa (FR-D-013): đọc lại bản trên máy chủ, nếu
      // nó đã khác mốc lúc ta mở ra thì có người khác vừa lưu. Ghi đè lặng lẽ ở đây
      // là **mất trắng công sức của người kia** mà không ai biết.
      const current = await getVersion(code, versionNo)
      const server = current.definitionYaml ?? ''
      if (baseYamlRef.current && server !== baseYamlRef.current) {
        setSaveState('dirty')
        modal.confirm({
          title: 'Người khác vừa sửa luồng này',
          content:
            'Bản trên máy chủ đã thay đổi kể từ lúc bạn mở. Ghi đè sẽ mất phần sửa của họ.',
          okText: 'Vẫn ghi đè',
          okButtonProps: { danger: true },
          cancelText: 'Để tôi xem lại',
          onOk: async () => {
            await saveDefinition(code, versionNo, yaml)
            baseYamlRef.current = yaml
            setSaveState('saved')
            message.warning('Đã ghi đè bản của người khác')
          },
        })
        return
      }
      await saveDefinition(code, versionNo, yaml)
      baseYamlRef.current = yaml
      setSaveState('saved')
    } catch (e) {
      setSaveState('error')
      message.error(`Lưu lỗi: ${e instanceof Error ? e.message : e}`)
    }
  }, [canDesign, code, versionNo, yaml, message, modal])

  // Tự lưu sau 30 giây không thao tác (FR-D-013).
  useEffect(() => {
    if (saveState !== 'dirty') return
    const t = window.setTimeout(() => void doSave(), 30_000)
    return () => window.clearTimeout(t)
  }, [saveState, doSave])

  /**
   * Rời trình thiết kế khi còn thay đổi chưa lưu thì hỏi trước (FR-D-2-3).
   *
   * Không dùng `useBlocker`: hàm đó chỉ chạy dưới data router (`createBrowserRouter`),
   * còn ứng dụng đang dùng `BrowserRouter` — gọi vào sẽ ném lỗi và cả trang trắng.
   */
  const leaveTo = useCallback(
    (to: string) => {
      if (saveState !== 'dirty') {
        navigate(to)
        return
      }
      modal.confirm({
        title: 'Còn thay đổi chưa lưu',
        content: 'Rời trình thiết kế bây giờ sẽ mất phần chưa lưu. Bạn muốn làm gì?',
        okText: 'Lưu rồi rời',
        cancelText: 'Ở lại',
        onOk: async () => {
          await doSave()
          navigate(to)
        },
      })
    },
    [saveState, navigate, modal, doSave],
  )

  // Cảnh báo khi đóng tab.
  useEffect(() => {
    if (saveState !== 'dirty') return
    const h = (e: BeforeUnloadEvent) => e.preventDefault()
    window.addEventListener('beforeunload', h)
    return () => window.removeEventListener('beforeunload', h)
  }, [saveState])

  /* ---------- Thao tác sơ đồ ---------- */

  /**
   * Đưa một chặng vừa dựng vào **cây**, trả về đường dẫn thật để dùng làm mã node (K2).
   *
   * Sơ đồ và cây phải khớp mã: `unflatten` tra bước theo `node.id === step.path`. Chặng
   * chỉ tồn tại trên sơ đồ sẽ bị `unmappedNodes` phát hiện và ép cả luồng lùi về bộ sinh
   * cũ — tức là **mất cấu trúc lồng** đang giữ. Nên thêm chặng phải vào cây trước.
   *
   * Chưa có cây (luồng dựng mới hoàn toàn) thì trả `undefined`, giữ mã sinh sẵn.
   */
  const adoptIntoTree = useCallback(
    (node: StageNode, afterNodeId: string | undefined, role: 'from' | 'step'): string | undefined => {
      const tree = treeRef.current
      // Chặng tiếp nhận nằm ở `from`, không phải trong `steps` — chưa hỗ trợ thay `from`
      // qua lối này, để `unmappedNodes` bắt và lùi về bộ sinh cũ thay vì dựng cây sai.
      if (!tree || role === 'from') return undefined

      const name = refName(node.data.ref)
      const props: Record<string, string | number | boolean> = { ...node.data.props }
      if (node.data.uri) props.uri = node.data.uri

      // Chỉ chèn "sau" khi chặng neo nằm ở **cấp gốc** của route. Đuôi luồng tính theo
      // cạnh ra có thể rơi vào trong `doCatch`/`when` — luồng rẽ nhánh có nhiều đuôi —
      // và khi đó chặng người dùng thả sẽ **chui vào nhánh xử lý lỗi** thay vì nối tiếp
      // route. Neo không ở cấp gốc thì nối vào cuối danh sách gốc.
      const topLevel = new Set((tree.entities[activeEntity]?.steps ?? []).map((s) => s.path))
      const anchor = afterNodeId && topLevel.has(afterNodeId) ? afterNodeId : undefined
      const { resource, path } = insertAfterAt(tree, activeEntity, anchor, newStep(name, props))
      setTree(resource)
      return path
    },
    [activeEntity, setTree],
  )

  /**
   * Chuyển sang route khác trong cùng tệp (FR-D-005).
   *
   * Áp thay đổi của route đang mở vào cây **trước khi** chuyển — không thì công sức trên
   * canvas biến mất lặng lẽ khi người dùng bấm sang route khác rồi bấm quay lại.
   */
  const selectEntity = useCallback(
    (index: number) => {
      const current = treeRef.current
      if (!current || index === activeEntity) return
      const saved =
        unmappedNodes(current, nodes).length === 0
          ? applyGraphToTree(current, nodes, edges, activeEntity)
          : current
      setTree(saved)
      setActiveEntity(index)
      const g = flatten(saved, index)
      bumpSeq([...g.nodes.map((n) => n.id), ...g.edges.map((e) => e.id)])
      setNodes(autoLayout(g.nodes, g.edges))
      setEdges(g.edges)
    },
    [activeEntity, nodes, edges, setNodes, setEdges, setTree],
  )

  /** Vẽ lại canvas theo một cây và một route — dùng chung cho mọi thao tác thực thể. */
  const showEntity = useCallback(
    (next: CamelResource, index: number) => {
      setTree(next)
      setActiveEntity(index)
      const g = flatten(next, index)
      bumpSeq([...g.nodes.map((n) => n.id), ...g.edges.map((e) => e.id)])
      setNodes(autoLayout(g.nodes, g.edges))
      setEdges(g.edges)
      markDirty()
    },
    [setNodes, setEdges, setTree, markDirty],
  )

  const addEntityAt = useCallback(
    (id: string) => {
      const current = treeRef.current
      if (!current) return
      const next = addEntity(current, id)
      showEntity(next, next.entities.length - 1)
    },
    [showEntity],
  )

  const removeEntityAt = useCallback(
    (index: number) => {
      const current = treeRef.current
      if (!current || current.entities.length <= 1) return
      const next = removeEntity(current, index)
      showEntity(next, Math.max(0, Math.min(index, next.entities.length - 1)))
    },
    [showEntity],
  )

  const duplicateEntityAt = useCallback(
    (index: number, newId: string) => {
      const current = treeRef.current
      if (!current) return
      showEntity(duplicateEntity(current, index, newId), index + 1)
    },
    [showEntity],
  )

  /**
   * Đổi mã route, **cập nhật cả tham chiếu** trỏ tới nó (FR-D-007).
   *
   * Nói rõ số tham chiếu đã sửa: đổi mã mà im lặng sửa luồng khác trong cùng tệp là thứ
   * người dùng cần biết, không phải thứ nên giấu đi cho gọn.
   */
  const renameEntityAt = useCallback(
    (index: number, newId: string) => {
      const current = treeRef.current
      if (!current) return
      const { resource, updatedRefs } = renameEntity(current, index, newId)
      showEntity(resource, index)
      message.success(
        updatedRefs > 0
          ? `Đã đổi mã route và sửa ${updatedRefs} tham chiếu trỏ tới nó`
          : 'Đã đổi mã route (không có tham chiếu nào cần sửa)',
      )
    },
    [showEntity, message],
  )

  const addStage = useCallback(
    (item: DraggedNode, pos: XYPosition) => {
      const cat = lookupNode(item.ref)
      if (!cat) return
      const role = !hasFrom && !cat.producerOnly ? 'from' : 'step'
      const node = makeStage(cat, { role, position: pos })
      const tails = nodes.filter((n) => !edges.some((e) => e.source === n.id))
      const tail = role === 'step' && tails.length === 1 ? tails[0] : null

      markDirty()
      // Chèn vào **cây** trước, rồi lấy đường dẫn thật làm mã node (K2). Không làm bước
      // này thì chặng mới không có chỗ trong cây, `unmappedNodes` phát hiện và cả luồng
      // phải lùi về bộ sinh cũ — mất hết cấu trúc lồng đang giữ.
      const id = adoptIntoTree(node, tail?.id, role)
      const placed = { ...node, id: id ?? node.id }
      setNodes((ns) => [...ns.map((n) => ({ ...n, selected: false })), { ...placed, selected: true }])
      if (tail) {
        setEdges((es) => [...es, { id: nextId('e'), source: tail.id, target: placed.id, type: 'seq' }])
      }
    },
    [hasFrom, nodes, edges, setNodes, setEdges, markDirty, adoptIntoTree],
  )

  const insertOnEdge = useCallback(
    (edgeId: string, item: DraggedNode) => {
      const edge = edgesRef.current.find((e) => e.id === edgeId)
      const cat = lookupNode(item.ref)
      if (!edge || !cat) return
      const src = nodes.find((n) => n.id === edge.source)
      if (!src) return

      markDirty()
      const node = makeStage(cat, {
        position: { x: src.position.x + NODE_W + 40, y: src.position.y },
      })
      setNodes((ns) => [...ns.map((n) => ({ ...n, selected: false })), { ...node, selected: true }])
      setEdges((es) => [
        ...es.filter((e) => e.id !== edgeId),
        { id: nextId('e'), source: edge.source, target: node.id, type: 'seq', data: edge.data },
        { id: nextId('e'), source: node.id, target: edge.target, type: 'seq' },
      ])
    },
    [nodes, setNodes, setEdges, markDirty],
  )

  const duplicateSelected = useCallback(() => {
    const src = nodes.find((n) => n.selected)
    if (!src) return
    markDirty()
    const copyId = nextId('n')
    const edgeId = nextId('e')
    const copy = duplicateStage(src, copyId)
    // Hàm cập nhật phải thuần: StrictMode gọi hai lần.
    setNodes((ns) => (ns.some((x) => x.id === copyId) ? ns : [...ns.map((x) => ({ ...x, selected: false })), copy]))
    setEdges((es) =>
      es.some((e) => e.id === edgeId)
        ? es
        : [...es, { id: edgeId, source: src.id, target: copyId, type: 'seq' }],
    )
  }, [nodes, setNodes, setEdges, markDirty])

  const deleteSelected = useCallback(() => {
    const n = nodes.find((x) => x.selected)
    if (!n) return
    if (n.data.locked) {
      message.warning(`Chặng “${n.data.label}” là chặng bắt buộc của khung chuẩn, không gỡ được`)
      return
    }
    markDirty()
    setNodes((ns) => ns.filter((x) => x.id !== n.id))
    setEdges((es) => es.filter((e) => e.source !== n.id && e.target !== n.id))
  }, [nodes, setNodes, setEdges, markDirty, message])

  const patchSelected = useCallback(
    (patch: (d: StageData) => StageData) => {
      markDirty()
      setNodes((ns) => ns.map((n) => (n.selected ? { ...n, data: patch(n.data) } : n)))
    },
    [setNodes, markDirty],
  )

  const onConnect = useCallback(
    (c: Connection) => {
      markDirty()
      setEdges((es) => {
        const src = nodes.find((n) => n.id === c.source)
        const branching = src ? BRANCHING.has(refName(src.data.ref)) : false
        return addEdge({ ...c, type: 'seq' }, branching ? es : es.filter((e) => e.source !== c.source))
      })
    },
    [nodes, setEdges, markDirty],
  )

  const relayout = useCallback(() => {
    markDirty()
    setNodes((ns) => autoLayout(ns, edgesRef.current))
    window.setTimeout(() => fitView({ padding: 0.15, duration: 300 }), 30)
  }, [setNodes, fitView, markDirty])

  // Phím tắt nhân bản.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (!(e.metaKey || e.ctrlKey) || e.key.toLowerCase() !== 'd') return
      const t = e.target as HTMLElement | null
      if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return
      e.preventDefault()
      duplicateSelected()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [duplicateSelected])

  const interaction = useMemo<Interaction>(
    () => ({
      insertOnEdge,
      openInsertMenu: () => {},
      editBranch: () => {},
    }),
    [insertOnEdge],
  )

  async function doSubmit() {
    if (errorCount > 0) {
      message.error('Còn lỗi kiểm tra — sửa hết rồi mới gửi duyệt được')
      return
    }
    await doSave()
    try {
      await submitVersion(code, versionNo)
      message.success('Đã gửi duyệt')
      navigate('/flows')
    } catch (e) {
      message.error(String(e instanceof Error ? e.message : e))
    }
  }

  if (loading) {
    return (
      <div className="dsg">
        <div className="dsg__bar">
          <Typography.Text>Đang mở luồng {code}…</Typography.Text>
        </div>
      </div>
    )
  }

  return (
    <div className="dsg">
      <div className="dsg__bar">
        <Button size="small" onClick={() => leaveTo('/flows')}>
          ← Danh sách
        </Button>
        <div className="dsg__bar-id">
          <span className="dsg__bar-code">{code}</span>
          <Tag>v{versionNo}</Tag>
          <Tag color={route?.status === 'ACTIVE' ? '#15803d' : 'default'}>{route?.status ?? 'DRAFT'}</Tag>
        </div>
        <span className={`dsg__saved dsg__saved--${saveState}`}>{SAVE_LABEL[saveState]}</span>
        <span className="dsg__bar-sub">
          <Typography.Text type="secondary" style={{ fontSize: 12 }}>
            {nodes.length} chặng · {CATALOG_RUNTIME}
            {errorCount > 0 && ` · ${errorCount} lỗi`}
          </Typography.Text>
          {/* Tô đường chạy của lần chạy gần nhất (FR-D-031). Tắt được vì khi đang
              sửa sơ đồ, màu của lần chạy cũ dễ gây hiểu nhầm là trạng thái hiện tại. */}
          {runInfo && (
            <Button
              size="small"
              type={showRun ? 'primary' : 'default'}
              onClick={() => setShowRun((v) => !v)}
              title={`Lần chạy ${runInfo.at.slice(0, 19).replace('T', ' ')} · ${runInfo.outcome}`}
            >
              {showRun ? 'Đang tô đường chạy' : 'Tô đường chạy'}
            </Button>
          )}
        </span>

        <div className="dsg__bar-actions">
          <Button size="small" onClick={undo} disabled={!canUndo}>
            ↶
          </Button>
          <Button size="small" onClick={redo} disabled={!canRedo}>
            ↷
          </Button>
          <Button size="small" onClick={relayout}>
            Tự sắp xếp
          </Button>
          <Button size="small" onClick={duplicateSelected} disabled={!selected}>
            Nhân bản
          </Button>
          <Button size="small" onClick={() => setConfigOpen(true)} disabled={!selected}>
            Cấu hình
          </Button>
          {/* Chỉ Kamelet mới có `spec.definition` — nút này vô nghĩa với Route/Pipe. */}
          {tree?.kind === 'Kamelet' && (
            <Button size="small" onClick={() => setKameletOpen(true)}>
              Tham số Kamelet
            </Button>
          )}
          <Button size="small" onClick={() => leaveTo(`/flows/${code}/test`)}>
            Chạy thử
          </Button>
          <Button size="small" type="primary" onClick={() => void doSave()} disabled={!canDesign}>
            Lưu
          </Button>
          <Button size="small" onClick={() => void doSubmit()} disabled={!canSubmit || errorCount > 0}>
            Gửi duyệt
          </Button>
        </div>
      </div>

      <div className="dsg__body">
        <aside className={leftOpen ? 'dsg__left' : 'dsg__left is-collapsed'}>
          {leftOpen && (
            <>
              <EntityList
                resource={tree}
                activeIndex={activeEntity}
                onSelect={selectEntity}
                onAdd={addEntityAt}
                onRemove={removeEntityAt}
                onDuplicate={duplicateEntityAt}
                onRename={renameEntityAt}
                disabled={!canDesign || !tree}
              />
              <Palette hasFrom={hasFrom} />
            </>
          )}
        </aside>

        <div className="dsg__center">
          <button
            type="button"
            className="dsg__toggle dsg__toggle--left"
            onClick={() => setLeftOpen((v) => !v)}
            title={leftOpen ? 'Thu gọn bảng thành phần' : 'Mở bảng thành phần'}
          >
            {leftOpen ? '‹' : '›'}
          </button>
          <button
            type="button"
            className="dsg__toggle dsg__toggle--right"
            onClick={() => setRightOpen((v) => !v)}
            title={rightOpen ? 'Thu gọn panel kiểm tra' : 'Mở panel kiểm tra'}
          >
            {rightOpen ? '›' : '‹'}
          </button>

          <div className="dsg__canvas">
            <StatusContext.Provider value={status}>
              <RunContext.Provider value={runOverlay}>
                <InteractionContext.Provider value={interaction}>
                  <FlowCanvas
                    nodes={nodes}
                    edges={edges}
                    onNodesChange={onNodesChange}
                    onEdgesChange={onEdgesChange}
                    onConnect={onConnect}
                    onDropStage={addStage}
                    onNodeDoubleClick={() => setConfigOpen(true)}
                  />
                </InteractionContext.Provider>
              </RunContext.Provider>
            </StatusContext.Provider>
          </div>
        </div>

        <aside className={rightOpen ? 'dsg__right' : 'dsg__right is-collapsed'}>
          {rightOpen && (
            <div className="dsg__right-split">
              <section className="dsg__findings">
                <div className="dsg__panel-head">
                  Kiểm tra
                  <span className="count">
                    {errorCount} lỗi · {findings.length - errorCount} cảnh báo
                  </span>
                </div>
                <div className="dsg__panel-body">
                  {findings.length === 0 ? (
                    <p className="pal__empty">Không có phát hiện nào — luồng hợp lệ.</p>
                  ) : (
                    findings.map((f) => (
                      <button
                        key={f.id}
                        type="button"
                        className={`fnd fnd--${f.level}`}
                        onClick={() =>
                          f.nodeId && setNodes((ns) => ns.map((n) => ({ ...n, selected: n.id === f.nodeId })))
                        }
                      >
                        <span className="fnd__mark">{f.level === 'error' ? '✕' : '⚠'}</span>
                        <span className="fnd__text">
                          <span className="fnd__title">{f.title}</span>
                          <span className="fnd__detail">{f.detail}</span>
                        </span>
                      </button>
                    ))
                  )}
                </div>
              </section>

              <section className="dsg__yaml">
                <div className="dsg__panel-head">
                  Camel YAML DSL
                  <span className="count">{yaml.trimEnd().split('\n').length} dòng</span>
                  <Button
                    size="small"
                    className="dsg__yaml-open"
                    onClick={() => setYamlOpen(true)}
                    title="Mở toàn màn hình để đọc và sửa"
                  >
                    ⤢ Mở rộng
                  </Button>
                </div>
                <div className="dsg__panel-body">
                  <pre className="dsg__yaml-code">{yaml}</pre>
                </div>
              </section>
            </div>
          )}
        </aside>
      </div>

      <YamlEditor
        open={yamlOpen}
        yaml={yaml}
        onClose={() => setYamlOpen(false)}
        onApply={(n, e, tree) => {
          // Ghi vào lịch sử trước khi thay để hoàn tác được nếu áp nhầm.
          commit()
          // Thay luôn cây đang giữ: không thì lần sinh YAML sau vẫn áp thay đổi lên
          // cây cũ và **nuốt mất** bản người dùng vừa sửa tay.
          treeRef.current = tree
          setNodes(autoLayout(n, e))
          setEdges(e)
          setSaveState('dirty')
          message.success('Đã áp YAML vào sơ đồ')
        }}
      />

      <KameletSpec
        open={kameletOpen}
        resource={tree}
        onClose={() => setKameletOpen(false)}
        onSave={(next) => {
          setTree(next)
          markDirty()
          message.success('Đã lưu tham số Kamelet')
        }}
      />

      <NodeConfig
        open={configOpen && Boolean(selected)}
        node={selected}
        onClose={() => setConfigOpen(false)}
        onLabel={(v) => patchSelected((d) => ({ ...d, label: v }))}
        onUri={(v) => patchSelected((d) => ({ ...d, uri: v }))}
        onProp={(k, v) =>
          patchSelected((d) => {
            const props = { ...d.props }
            if (v === undefined) delete props[k]
            else props[k] = v
            return { ...d, props }
          })
        }
        onPin={(v) => patchSelected((d) => ({ ...d, pinnedSample: v }))}
        onNote={(v) => patchSelected((d) => ({ ...d, note: v }))}
        onDelete={deleteSelected}
        sample={selectedSample}
        env={ENV_VARS}
      />
    </div>
  )
}

/** D-02 — Trình thiết kế toàn màn hình, có route riêng `/flows/:code/design`. */
export function DesignerPage() {
  return (
    <ReactFlowProvider>
      <DesignerInner />
    </ReactFlowProvider>
  )
}
