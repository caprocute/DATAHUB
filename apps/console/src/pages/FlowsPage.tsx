import { ReactFlowProvider } from '@xyflow/react'
import {
  App as AntApp,
  Button,
  ConfigProvider,
  Input,
  Segmented,
  Select,
  Space,
  Table,
  Tag,
  Typography,
  message,
} from 'antd'
import { useCallback, useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { apiGet } from '../api/client'
import {
  createRoute,
  getRoute,
  getVersion,
  listRoutes,
  runTest,
  saveDefinition,
  submitVersion,
  validateYaml,
  type RouteSummary,
  type TestRunResult,
} from '../api/routesApi'
import { useRoles } from '../auth/useRoles'
import {
  embedCanvas,
  extractCanvas,
  stripCanvas,
  type CanvasGraph,
} from '../designer/canvasCodec'
import { Designer } from '../designer/Designer'
import type { SeqEdge, StageNode } from '../designer/flow/model'
import { ReviewPanel } from '../designer/panels/ReviewPanel'
import { mapWaterfall, type StageRun } from '../designer/flow/RunContext'
import { antdThemeFor } from '../designer/theme/tokens'
import { useTheme } from '../designer/theme/useTheme'
import '../theme-mockup/tokens.css'
import '@xyflow/react/dist/style.css'
import '../designer/designer.css'

type Tab = 'list' | 'design' | 'test' | 'review'

/** Chỉ bật stub khi cố ý — mặc định tắt (audit repair). */
const TEST_STUB = import.meta.env.VITE_TEST_RUN_STUB === 'true'

export function FlowsPage() {
  const { mode } = useTheme()
  const { canDesign, canSubmit, canReview } = useRoles()
  const [tab, setTab] = useState<Tab>('list')
  const [dirty, setDirty] = useState(false)
  const [counts, setCounts] = useState({ errors: 0, warns: 0 })
  const [routeCode, setRouteCode] = useState('')
  const [versionNo, setVersionNo] = useState(1)
  const [status, setStatus] = useState<string>('DRAFT')
  const [gitRef, setGitRef] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [serverOk, setServerOk] = useState(false)
  const [routes, setRoutes] = useState<RouteSummary[]>([])
  const [listLoading, setListLoading] = useState(false)
  const [systems, setSystems] = useState<{ code: string; name: string }[]>([])
  const [sourceSystem, setSourceSystem] = useState('console-designer')
  const [targetSystem, setTargetSystem] = useState('camel-dancu')
  const [canvasBoot, setCanvasBoot] = useState<{
    nodes?: StageNode[]
    edges?: SeqEdge[]
    key: string
  }>({ key: 'new' })
  const [testResult, setTestResult] = useState<TestRunResult | null>(null)
  const yamlRef = useRef('')
  const graphRef = useRef<CanvasGraph | null>(null)
  /** Kết quả chạy thử quy về từng chặng để tô lên sơ đồ (FR-04-035). */
  const [runByNode, setRunByNode] = useState<Record<string, StageRun>>({})

  const onDirty = useCallback(() => {
    setDirty(true)
    setServerOk(false)
  }, [])
  const onYamlChange = useCallback((yaml: string) => {
    yamlRef.current = yaml
  }, [])
  const onGraphChange = useCallback((graph: CanvasGraph) => {
    graphRef.current = graph
  }, [])

  async function refreshList() {
    setListLoading(true)
    try {
      const data = await listRoutes()
      setRoutes(data.items)
    } catch (e) {
      message.error(String(e))
    } finally {
      setListLoading(false)
    }
  }

  async function loadApprovedSystems() {
    try {
      const data = await apiGet<{
        items: { systemCode: string; systemName: string; status: string }[]
      }>('/onboarding/applications')
      setSystems(
        data.items
          .filter((a) => a.status === 'APPROVED')
          .map((a) => ({ code: a.systemCode, name: a.systemName })),
      )
    } catch {
      /* ignore */
    }
  }

  useEffect(() => {
    if (tab === 'list') {
      void refreshList()
      void loadApprovedSystems()
    }
  }, [tab])

  async function openDesign(code: string) {
    setRouteCode(code)
    setTab('design')
    setDirty(false)
    setServerOk(false)
    setTestResult(null)
    try {
      const r = await getRoute(code)
      setStatus(r.status)
      setSourceSystem(r.sourceSystem || 'console-designer')
      setTargetSystem(r.targetSystem || 'camel-dancu')
      const ver = r.draftVersionNo ?? 1
      setVersionNo(ver)
      const v = await getVersion(code, ver)
      setGitRef(v.gitCommitRef ?? null)
      const canvas = extractCanvas(v.definitionYaml)
      if (canvas) {
        setCanvasBoot({ nodes: canvas.nodes, edges: canvas.edges, key: `${code}-${ver}-${Date.now()}` })
      } else {
        setCanvasBoot({ key: `${code}-${ver}-default-${Date.now()}` })
      }
    } catch {
      setStatus('DRAFT')
      setVersionNo(1)
      setGitRef(null)
      setCanvasBoot({ key: `${code}-new-${Date.now()}` })
    }
  }

  async function persistDraft(): Promise<number> {
    if (!canDesign) throw new Error('Không có quyền thiết kế luồng')
    let yaml = yamlRef.current
    if (!yaml.trim()) throw new Error('Chưa có YAML từ designer')
    if (!/^[a-z0-9-]+$/.test(routeCode)) throw new Error('routeCode chỉ gồm a-z, 0-9, dấu gạch')
    if (graphRef.current) {
      yaml = embedCanvas(yaml, graphRef.current)
    }

    let ver = versionNo
    let exists = true
    try {
      const r = await getRoute(routeCode)
      setStatus(r.status)
      ver = r.draftVersionNo ?? 1
      setVersionNo(ver)
    } catch {
      exists = false
    }

    if (!exists) {
      await createRoute({
        routeCode,
        title: routeCode,
        sourceSystem,
        targetSystem,
        definitionYaml: yaml,
      })
      ver = 1
      setVersionNo(1)
      setStatus('DRAFT')
    } else {
      if (status !== 'DRAFT' && status !== 'TESTING') {
        throw new Error(`Chỉ sửa khi DRAFT/TESTING — hiện ${status}`)
      }
      const v = await saveDefinition(routeCode, ver, yaml)
      setStatus(v.status)
      setGitRef(v.gitCommitRef ?? null)
    }
    setDirty(false)
    return ver
  }

  async function onSaveDraft() {
    setSaving(true)
    try {
      await persistDraft()
      message.success('Đã lưu bản nháp (+ canvas metadata)')
      await refreshList()
    } catch (e) {
      message.error(String(e))
    } finally {
      setSaving(false)
    }
  }

  async function runServerValidate() {
    try {
      const bare = stripCanvas(yamlRef.current)
      const r = await validateYaml(bare)
      setServerOk(r.valid)
      if (r.valid) message.success('Validate server OK')
      else
        message.error(
          r.findings
            .filter((f) => f.severity === 'ERROR')
            .map((f) => f.message)
            .join('; ') || 'Validate lỗi',
        )
    } catch (e) {
      setServerOk(false)
      message.error(String(e))
    }
  }

  async function runSubmit() {
    if (!canSubmit) {
      message.error('Không có quyền gửi duyệt')
      return
    }
    if (counts.errors > 0) {
      message.error('Chặn gửi duyệt — còn lỗi trên canvas')
      return
    }
    if (!serverOk) {
      message.error('Chặn gửi duyệt — cần Validate server OK trước')
      return
    }
    setSaving(true)
    try {
      const ver = await persistDraft()
      const v = await submitVersion(routeCode, ver)
      setStatus(v.status)
      message.success('Đã gửi duyệt — chờ INTEGRATION_REVIEWER')
      setTab('review')
    } catch (e) {
      message.error(String(e))
    } finally {
      setSaving(false)
    }
  }

  async function runTestApi() {
    if (!routeCode) {
      message.error('Chưa chọn route')
      return
    }
    setSaving(true)
    setTestResult(null)
    setRunByNode({})
    try {
      const result = await runTest(routeCode, versionNo, 'MOCK')
      setTestResult(result)
      // Quy kết quả về từng chặng để sơ đồ tô được đường chạy.
      setRunByNode(mapWaterfall(result.waterfall ?? [], graphRef.current?.nodes ?? []))
      message.success(`${result.outcome} · ${result.durationMs}ms`)
    } catch (e) {
      message.error(String(e))
    } finally {
      setSaving(false)
    }
  }

  const tabOptions = [
    { label: 'Danh sách', value: 'list' as const },
    { label: 'Thiết kế', value: 'design' as const, disabled: !routeCode && tab !== 'design' },
    { label: 'Chạy thử', value: 'test' as const, disabled: !routeCode },
    ...(canReview ? [{ label: 'Duyệt', value: 'review' as const }] : []),
  ]

  return (
    <ConfigProvider theme={antdThemeFor(mode)}>
      <AntApp>
        <div className="designer-page">
          <Typography.Title level={3} style={{ marginBottom: 4 }}>
            Luồng tích hợp
          </Typography.Title>
          <Typography.Paragraph type="secondary" style={{ marginBottom: 12 }}>
            UI-04-01/07/08/09 · <Link to="/onboarding">Kết nạp</Link> ·{' '}
            <Link to="/catalog">Catalog</Link> · GitOps <code>routes/</code>
          </Typography.Paragraph>

          <Segmented
            style={{ marginBottom: 16 }}
            value={tab}
            onChange={(v) => setTab(v as Tab)}
            options={tabOptions}
          />

          {tab === 'list' && (
            <>
              <Space style={{ marginBottom: 12 }} wrap>
                <Select
                  style={{ width: 220 }}
                  placeholder="Hệ nguồn (đã duyệt)"
                  allowClear
                  options={systems.map((s) => ({ value: s.code, label: `${s.code} — ${s.name}` }))}
                  onChange={(v) => setSourceSystem(v || 'console-designer')}
                />
                <Button
                  type="primary"
                  disabled={!canDesign}
                  onClick={() => {
                    const code = `route-${Date.now().toString(36)}`
                    setRouteCode(code)
                    setStatus('DRAFT')
                    setVersionNo(1)
                    setGitRef(null)
                    setCanvasBoot({ key: `new-${code}` })
                    setTab('design')
                  }}
                >
                  Tạo luồng mới
                </Button>
                <Button onClick={() => void refreshList()}>Làm mới</Button>
              </Space>
              <Table
                rowKey="routeId"
                loading={listLoading}
                dataSource={routes}
                pagination={false}
                columns={[
                  { title: 'Mã', dataIndex: 'routeCode' },
                  { title: 'Tên', dataIndex: 'title' },
                  {
                    title: 'Trạng thái',
                    dataIndex: 'status',
                    render: (s: string) => <Tag>{s}</Tag>,
                  },
                  {
                    title: 'Version',
                    width: 100,
                    render: (_: unknown, row: RouteSummary) =>
                      row.currentVersionNo != null
                        ? `v${row.currentVersionNo}`
                        : row.draftVersionNo != null
                          ? `draft v${row.draftVersionNo}`
                          : '—',
                  },
                  {
                    title: 'git_commit_ref',
                    dataIndex: 'gitCommitRef',
                    ellipsis: true,
                    render: (v: string | null | undefined) =>
                      v ? <Typography.Text code>{v.slice(0, 12)}</Typography.Text> : '—',
                  },
                  { title: 'Nguồn', dataIndex: 'sourceSystem' },
                  { title: 'Đích', dataIndex: 'targetSystem' },
                  {
                    title: '',
                    width: 120,
                    render: (_, row) => (
                      <Button size="small" onClick={() => void openDesign(row.routeCode)}>
                        Mở thiết kế
                      </Button>
                    ),
                  },
                ]}
              />
            </>
          )}

          {tab === 'design' && (
            <>
              <Space wrap style={{ marginBottom: 12 }}>
                <Input
                  addonBefore="routeCode"
                  value={routeCode}
                  disabled={status !== 'DRAFT' && status !== 'TESTING'}
                  onChange={(e) => setRouteCode(e.target.value.trim().toLowerCase())}
                  style={{ width: 280 }}
                />
                <Select
                  style={{ width: 200 }}
                  value={sourceSystem}
                  disabled={!canDesign}
                  options={[
                    { value: 'console-designer', label: 'console-designer' },
                    ...systems.map((s) => ({ value: s.code, label: s.code })),
                  ]}
                  onChange={setSourceSystem}
                />
                <Input
                  addonBefore="đích"
                  value={targetSystem}
                  disabled={!canDesign}
                  onChange={(e) => setTargetSystem(e.target.value)}
                  style={{ width: 200 }}
                />
                <Tag>{status || 'DRAFT'}</Tag>
                {gitRef && <Tag color="blue">git:{gitRef.slice(0, 12)}</Tag>}
                <Tag color={dirty ? 'orange' : 'default'}>{dirty ? 'chưa lưu' : 'đã lưu'}</Tag>
                <Tag color={counts.errors ? 'red' : 'green'}>
                  {counts.errors} lỗi / {counts.warns} cảnh báo
                </Tag>
                <Tag color={serverOk ? 'green' : 'default'}>
                  server: {serverOk ? 'OK' : 'chưa'}
                </Tag>
                <Button type="primary" disabled={!canDesign} loading={saving} onClick={() => void onSaveDraft()}>
                  Lưu bản nháp
                </Button>
                <Button disabled={!canDesign} onClick={() => void runServerValidate()}>
                  Validate server
                </Button>
                <Button disabled={!routeCode} onClick={() => setTab('test')}>
                  Chạy thử
                </Button>
                <Button
                  disabled={!canSubmit || counts.errors > 0 || !serverOk}
                  loading={saving}
                  onClick={() => void runSubmit()}
                >
                  Gửi duyệt
                </Button>
              </Space>
              {!canDesign && (
                <Typography.Paragraph type="danger">
                  Chỉ đọc — cần INTEGRATION_DEVELOPER.
                </Typography.Paragraph>
              )}
              <ReactFlowProvider key={canvasBoot.key}>
                <Designer
                  mode={mode}
                  routeId={routeCode || 'draft-route'}
                  initialNodes={canvasBoot.nodes}
                  initialEdges={canvasBoot.edges}
                  onDirty={onDirty}
                  onStatus={setCounts}
                  onYamlChange={onYamlChange}
                  onGraphChange={onGraphChange}
                  runByNode={runByNode}
                />
              </ReactFlowProvider>
            </>
          )}

          {tab === 'test' && (
            <div>
              <Typography.Paragraph>
                UI-04-08 · <Tag>{routeCode || '—'}</Tag> v{versionNo}
              </Typography.Paragraph>
              {TEST_STUB ? (
                <Typography.Paragraph type="warning">
                  Stub bật (`VITE_TEST_RUN_STUB=true`) — không dùng dữ liệu giả production. Tắt stub và dùng API.
                </Typography.Paragraph>
              ) : !routeCode ? (
                <Typography.Paragraph type="secondary">
                  Chưa có test-runner cho route trống — mở một luồng rồi chạy thử.
                </Typography.Paragraph>
              ) : (
                <Space direction="vertical" style={{ width: '100%' }}>
                  <Button type="primary" loading={saving} onClick={() => void runTestApi()}>
                    Chạy thử (API test-runner)
                  </Button>
                  {testResult != null && (
                    <>
                      <Typography.Text>
                        {testResult.outcome} · {testResult.durationMs}ms · mode {testResult.mode}
                      </Typography.Text>
                      <Table
                        size="small"
                        pagination={false}
                        rowKey="stage"
                        dataSource={testResult.waterfall}
                        columns={[
                          { title: 'Chặng', dataIndex: 'stage' },
                          { title: 'TT', dataIndex: 'status', width: 80 },
                          { title: 'ms', dataIndex: 'durationMs', width: 80 },
                          { title: 'offset', dataIndex: 'offsetMs', width: 90 },
                        ]}
                      />
                    </>
                  )}
                </Space>
              )}
            </div>
          )}

          {tab === 'review' && <ReviewPanel />}
        </div>
      </AntApp>
    </ConfigProvider>
  )
}
