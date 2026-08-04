import { ReactFlowProvider } from '@xyflow/react'
import {
  App as AntApp,
  Button,
  ConfigProvider,
  Input,
  Segmented,
  Space,
  Tag,
  Typography,
  message,
} from 'antd'
import { useCallback, useRef, useState } from 'react'
import {
  createRoute,
  getRoute,
  saveDefinition,
  submitVersion,
  validateYaml,
} from '../api/routesApi'
import { Designer } from '../designer/Designer'
import { ReviewPanel } from '../designer/panels/ReviewPanel'
import { TestPanel } from '../designer/panels/TestPanel'
import { antdThemeFor } from '../designer/theme/tokens'
import { useTheme } from '../designer/theme/useTheme'
import '../theme-mockup/tokens.css'
import '@xyflow/react/dist/style.css'
import '../designer/designer.css'

type Tab = 'design' | 'test' | 'review'

const TEST_STUB = import.meta.env.VITE_TEST_RUN_STUB !== 'false'

export function FlowsPage() {
  const { mode } = useTheme()
  const [tab, setTab] = useState<Tab>('design')
  const [dirty, setDirty] = useState(false)
  const [counts, setCounts] = useState({ errors: 0, warns: 0 })
  const [routeCode, setRouteCode] = useState('tra-cuu-thua-dat')
  const [versionNo, setVersionNo] = useState(1)
  const [status, setStatus] = useState<string>('DRAFT')
  const [saving, setSaving] = useState(false)
  const yamlRef = useRef('')

  const onDirty = useCallback(() => setDirty(true), [])
  const onYamlChange = useCallback((yaml: string) => {
    yamlRef.current = yaml
  }, [])

  async function persistDraft(): Promise<number> {
    const yaml = yamlRef.current
    if (!yaml.trim()) throw new Error('Chưa có YAML từ designer')

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
      message.success('Đã lưu bản nháp YAML (WP-23)')
    } catch (e) {
      message.error(String(e))
    } finally {
      setSaving(false)
    }
  }

  async function runServerValidate() {
    try {
      const r = await validateYaml(yamlRef.current)
      if (r.valid) message.success('Server validate OK')
      else
        message.error(
          r.findings
            .filter((f) => f.severity === 'ERROR')
            .map((f) => f.message)
            .join('; ') || 'Validate lỗi',
        )
    } catch (e) {
      message.error(String(e))
    }
  }

  async function runSubmit() {
    if (counts.errors > 0) {
      message.error('Chặn gửi duyệt — còn lỗi trên canvas')
      return
    }
    setSaving(true)
    try {
      const ver = await persistDraft()
      const v = await submitVersion(routeCode, ver)
      setStatus(v.status)
      message.success('Đã gửi duyệt (PENDING_REVIEW)')
      setTab('review')
    } catch (e) {
      message.error(String(e))
    } finally {
      setSaving(false)
    }
  }

  return (
    <ConfigProvider theme={antdThemeFor(mode)}>
      <AntApp>
        <div className="designer-page">
          <div style={{ marginBottom: 12 }}>
            <Typography.Title level={3} style={{ marginBottom: 4 }}>
              Thiết kế luồng
            </Typography.Title>
            <Typography.Paragraph type="secondary" style={{ marginBottom: 12 }}>
              WP-24 — designer trong console · lưu nháp API WP-23 · findings + validate server
              {TEST_STUB && (
                <>
                  {' '}
                  · <Tag color="gold">TEST_RUN stub</Tag>
                </>
              )}
            </Typography.Paragraph>

            <Space wrap style={{ marginBottom: 12 }}>
              <Input
                addonBefore="routeCode"
                value={routeCode}
                onChange={(e) => setRouteCode(e.target.value.trim().toLowerCase())}
                style={{ width: 280 }}
              />
              <Tag>{status}</Tag>
              <Tag color={dirty ? 'orange' : 'default'}>{dirty ? 'chưa lưu' : 'đã lưu'}</Tag>
              <Tag color={counts.errors ? 'red' : 'green'}>
                {counts.errors} lỗi / {counts.warns} cảnh báo
              </Tag>
              <Button type="primary" loading={saving} onClick={() => void onSaveDraft()}>
                Lưu bản nháp
              </Button>
              <Button onClick={() => void runServerValidate()}>Validate server</Button>
              <Button onClick={() => setTab('test')}>Chạy thử</Button>
              <Button disabled={counts.errors > 0} loading={saving} onClick={() => void runSubmit()}>
                Gửi duyệt
              </Button>
            </Space>

            <Segmented
              value={tab}
              onChange={(v) => setTab(v as Tab)}
              options={[
                { label: 'Thiết kế', value: 'design' },
                { label: 'Chạy thử', value: 'test' },
                { label: 'Duyệt', value: 'review' },
              ]}
            />
          </div>

          {tab === 'design' && (
            <ReactFlowProvider>
              <Designer
                mode={mode}
                onDirty={onDirty}
                onStatus={setCounts}
                onYamlChange={onYamlChange}
              />
            </ReactFlowProvider>
          )}
          {tab === 'test' && (
            <div>
              {TEST_STUB && (
                <Typography.Paragraph>
                  <Tag color="gold">stub</Tag> Backend test-runner (WP-25) chưa sẵn — waterfall giả lập.
                  Tắt stub: <code>VITE_TEST_RUN_STUB=false</code>.
                </Typography.Paragraph>
              )}
              <TestPanel />
            </div>
          )}
          {tab === 'review' && <ReviewPanel />}
        </div>
      </AntApp>
    </ConfigProvider>
  )
}
