import { ReactFlowProvider } from '@xyflow/react'
import {
  App as AntApp,
  Button,
  ConfigProvider,
  Input,
  Segmented,
  Space,
  Table,
  Tag,
  Typography,
  message,
} from 'antd'
import { useCallback, useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  createRoute,
  getRoute,
  listRoutes,
  saveDefinition,
  submitVersion,
  validateYaml,
  type RouteSummary,
} from '../api/routesApi'
import { useRoles } from '../auth/useRoles'
import { Designer } from '../designer/Designer'
import { ReviewPanel } from '../designer/panels/ReviewPanel'
import { TestPanel } from '../designer/panels/TestPanel'
import { antdThemeFor } from '../designer/theme/tokens'
import { useTheme } from '../designer/theme/useTheme'
import '../theme-mockup/tokens.css'
import '@xyflow/react/dist/style.css'
import '../designer/designer.css'

type Tab = 'list' | 'design' | 'test' | 'review'

const TEST_STUB = import.meta.env.VITE_TEST_RUN_STUB !== 'false'

export function FlowsPage() {
  const { mode } = useTheme()
  const { canDesign, canSubmit, canReview } = useRoles()
  const [tab, setTab] = useState<Tab>('list')
  const [dirty, setDirty] = useState(false)
  const [counts, setCounts] = useState({ errors: 0, warns: 0 })
  const [routeCode, setRouteCode] = useState('')
  const [versionNo, setVersionNo] = useState(1)
  const [status, setStatus] = useState<string>('DRAFT')
  const [saving, setSaving] = useState(false)
  const [serverOk, setServerOk] = useState(false)
  const [routes, setRoutes] = useState<RouteSummary[]>([])
  const [listLoading, setListLoading] = useState(false)
  const yamlRef = useRef('')

  const onDirty = useCallback(() => {
    setDirty(true)
    setServerOk(false)
  }, [])
  const onYamlChange = useCallback((yaml: string) => {
    yamlRef.current = yaml
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

  useEffect(() => {
    if (tab === 'list') void refreshList()
  }, [tab])

  function openDesign(code: string) {
    setRouteCode(code)
    setTab('design')
    setDirty(false)
    setServerOk(false)
    void getRoute(code)
      .then((r) => {
        setStatus(r.status)
        setVersionNo(r.draftVersionNo ?? 1)
      })
      .catch(() => {
        setStatus('DRAFT')
        setVersionNo(1)
      })
  }

  async function persistDraft(): Promise<number> {
    if (!canDesign) throw new Error('Không có quyền thiết kế luồng')
    const yaml = yamlRef.current
    if (!yaml.trim()) throw new Error('Chưa có YAML từ designer')
    if (!/^[a-z0-9-]+$/.test(routeCode)) throw new Error('routeCode chỉ gồm a-z, 0-9, dấu gạch')

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
        sourceSystem: 'console-designer',
        targetSystem: 'camel-dancu',
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
    }
    setDirty(false)
    return ver
  }

  async function onSaveDraft() {
    setSaving(true)
    try {
      await persistDraft()
      message.success('Đã lưu bản nháp')
      await refreshList()
    } catch (e) {
      message.error(String(e))
    } finally {
      setSaving(false)
    }
  }

  async function runServerValidate() {
    try {
      const r = await validateYaml(yamlRef.current)
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
      message.error('Chặn gửi duyệt — còn lỗi trên canvas (UI-04-07)')
      return
    }
    if (!serverOk) {
      message.error('Chặn gửi duyệt — cần Validate server OK trước (FR-04-027)')
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
            UI-04-01/07/08/09 · Liên kết{' '}
            <Link to="/onboarding">Kết nạp</Link> (client OIDC) ·{' '}
            <Link to="/catalog">Catalog</Link> (APISIX) · GitOps <code>routes/</code>
            {TEST_STUB && (
              <>
                {' '}
                · <Tag color="gold">chạy thử stub (WP-25)</Tag>
              </>
            )}
          </Typography.Paragraph>

          <Segmented
            style={{ marginBottom: 16 }}
            value={tab}
            onChange={(v) => setTab(v as Tab)}
            options={tabOptions}
          />

          {tab === 'list' && (
            <>
              <Space style={{ marginBottom: 12 }}>
                <Button
                  type="primary"
                  disabled={!canDesign}
                  onClick={() => {
                    const code = `route-${Date.now().toString(36)}`
                    setRouteCode(code)
                    setStatus('DRAFT')
                    setVersionNo(1)
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
                  { title: 'Nguồn', dataIndex: 'sourceSystem' },
                  { title: 'Đích', dataIndex: 'targetSystem' },
                  {
                    title: '',
                    width: 120,
                    render: (_, row) => (
                      <Button size="small" onClick={() => openDesign(row.routeCode)}>
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
                  disabled={status !== 'DRAFT' && status !== 'TESTING' && status !== ''}
                  onChange={(e) => setRouteCode(e.target.value.trim().toLowerCase())}
                  style={{ width: 280 }}
                />
                <Tag>{status || 'DRAFT'}</Tag>
                <Tag color={dirty ? 'orange' : 'default'}>{dirty ? 'chưa lưu' : 'đã lưu'}</Tag>
                <Tag color={counts.errors ? 'red' : 'green'}>
                  {counts.errors} lỗi / {counts.warns} cảnh báo
                </Tag>
                <Tag color={serverOk ? 'green' : 'default'}>
                  server validate: {serverOk ? 'OK' : 'chưa'}
                </Tag>
                <Button
                  type="primary"
                  disabled={!canDesign}
                  loading={saving}
                  onClick={() => void onSaveDraft()}
                >
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
                  Chỉ đọc — cần INTEGRATION_DEVELOPER để sửa.
                </Typography.Paragraph>
              )}
              <ReactFlowProvider>
                <Designer
                  mode={mode}
                  onDirty={onDirty}
                  onStatus={setCounts}
                  onYamlChange={onYamlChange}
                />
              </ReactFlowProvider>
            </>
          )}

          {tab === 'test' && (
            <div>
              <Typography.Paragraph>
                UI-04-08 · Luồng <Tag>{routeCode || '—'}</Tag>
                {TEST_STUB ? (
                  <>
                    {' '}
                    — <Tag color="gold">stub</Tag> chưa gọi test-runner (WP-25). Không ghi secret vào
                    log.
                  </>
                ) : (
                  ' — chế độ thật (cần WP-25).'
                )}
              </Typography.Paragraph>
              {TEST_STUB ? <TestPanel /> : <Typography.Text>Chờ API test-runner.</Typography.Text>}
            </div>
          )}

          {tab === 'review' && <ReviewPanel />}
        </div>
      </AntApp>
    </ConfigProvider>
  )
}
