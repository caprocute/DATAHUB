import { Alert, App as AntApp, Button, Empty, Input, Select, Space, Table, Tag, Typography } from 'antd'
import { useCallback, useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import '../design/designer.css'
import {
  getRoute,
  getVersion,
  runTest,
  validateYaml,
  type RouteSummary,
  type TestRunResult,
  type ValidationResult,
} from '../../api/routesApi'

/** Nhãn tiếng Việt cho trạng thái từng chặng trong waterfall. */
const STAGE_VI: Record<string, { label: string; color: string }> = {
  OK: { label: 'Thành công', color: '#15803d' },
  SUCCESS: { label: 'Thành công', color: '#15803d' },
  SKIPPED: { label: 'Bỏ qua', color: 'default' },
  FAILED: { label: 'Lỗi', color: '#b91c1c' },
  ERROR: { label: 'Lỗi', color: '#b91c1c' },
}

/**
 * D-04 — Chạy thử một luồng.
 *
 * Tách khỏi trình thiết kế: chạy thử là nhiệm vụ riêng, cần chỗ cho bản tin đầu vào
 * và bảng waterfall. Nhồi vào canvas như bản trước thì không đủ không gian.
 */
export function TestRunPage() {
  const { code = '' } = useParams()
  const navigate = useNavigate()
  const { message } = AntApp.useApp()

  const [route, setRoute] = useState<RouteSummary | null>(null)
  const [versionNo, setVersionNo] = useState<number>(1)
  const [mode, setMode] = useState('MOCK')
  const [sample, setSample] = useState('{\n  "loaiHoSo": "CAP_MOI"\n}')
  const [result, setResult] = useState<TestRunResult | null>(null)
  const [running, setRunning] = useState(false)
  const [error, setError] = useState<string | null>(null)
  /** Kết quả kiểm tra định nghĩa; có lỗi chặn thì không cho chạy (G5-2). */
  const [findings, setFindings] = useState<ValidationResult['findings']>([])
  const [checking, setChecking] = useState(false)

  useEffect(() => {
    let alive = true
    void getRoute(code)
      .then((r) => {
        if (!alive) return
        setRoute(r)
        setVersionNo(r.currentVersionNo ?? r.draftVersionNo ?? 1)
      })
      .catch((e: unknown) => alive && setError(String(e instanceof Error ? e.message : e)))
    return () => {
      alive = false
    }
  }, [code])

  /**
   * Kiểm tra định nghĩa trước khi cho chạy (FR-D-030, G5-2).
   *
   * Máy chủ vẫn là chốt chặn thật (`testRun` từ chối YAML lỗi), nhưng để người dùng bấm
   * rồi mới báo lỗi là phí một vòng chờ — kiểm trước và **khóa nút** cho biết ngay.
   */
  useEffect(() => {
    let alive = true
    if (!versionNo) return
    setChecking(true)
    void getVersion(code, versionNo)
      .then((v) => validateYaml(v.definitionYaml ?? ''))
      .then((r) => alive && setFindings(r.valid ? [] : r.findings))
      .catch(() => {
        // Không kiểm được thì **không** chặn: để máy chủ quyết khi bấm chạy, chặn
        // dựa trên một lần gọi hỏng sẽ khóa oan luồng vốn hợp lệ.
        if (alive) setFindings([])
      })
      .finally(() => alive && setChecking(false))
    return () => {
      alive = false
    }
  }, [code, versionNo])

  const blocking = findings.filter((f) => f.severity?.toUpperCase() === 'ERROR')

  const run = useCallback(async () => {
    setRunning(true)
    setError(null)
    try {
      const r = await runTest(code, versionNo, mode)
      setResult(r)
      message.success(`${r.outcome} · ${r.durationMs} ms`)
    } catch (e) {
      setError(String(e instanceof Error ? e.message : e))
    } finally {
      setRunning(false)
    }
  }, [code, versionNo, mode, message])

  return (
    <div className="page-card">
      <Space style={{ marginBottom: 12 }}>
        <Button size="small" onClick={() => navigate('/flows')}>
          ← Danh sách
        </Button>
        <Button size="small" onClick={() => navigate(`/flows/${code}/design`)}>
          Mở trình thiết kế
        </Button>
        <Button size="small" onClick={() => navigate(`/flows/${code}/runs`)}>
          Nhật ký chạy
        </Button>
      </Space>

      <Typography.Title level={3} style={{ marginTop: 0 }}>
        Chạy thử · {code}
      </Typography.Title>
      <Typography.Paragraph type="secondary">
        Gọi API chạy thử của máy chủ trên môi trường giả lập. Kết quả trả về theo từng chặng.
      </Typography.Paragraph>

      <Space wrap align="start" style={{ width: '100%', marginBottom: 16 }}>
        <div>
          <div className="t-small t-muted">Phiên bản</div>
          <Select
            style={{ width: 140 }}
            value={versionNo}
            onChange={setVersionNo}
            options={[
              ...(route?.currentVersionNo ? [{ value: route.currentVersionNo, label: `v${route.currentVersionNo} (đang chạy)` }] : []),
              ...(route?.draftVersionNo && route.draftVersionNo !== route.currentVersionNo
                ? [{ value: route.draftVersionNo, label: `v${route.draftVersionNo} (nháp)` }]
                : []),
            ]}
          />
        </div>
        <div>
          <div className="t-small t-muted">Chế độ</div>
          <Select
            style={{ width: 160 }}
            value={mode}
            onChange={setMode}
            options={[
              { value: 'MOCK', label: 'Giả lập đích (MOCK)' },
              { value: 'SANDBOX', label: 'Môi trường thử' },
            ]}
          />
        </div>
        <div>
          <div className="t-small t-muted">&nbsp;</div>
          <Button
            type="primary"
            loading={running || checking}
            disabled={blocking.length > 0}
            title={blocking.length > 0 ? 'Còn lỗi kiểm tra — sửa ở trình thiết kế trước' : undefined}
            onClick={() => void run()}
          >
            Chạy thử
          </Button>
        </div>
      </Space>

      {blocking.length > 0 && (
        <Alert
          type="error"
          showIcon
          style={{ marginBottom: 16 }}
          message={`Chặn chạy thử — còn ${blocking.length} lỗi trong định nghĩa`}
          description={
            <>
              <ul style={{ margin: '4px 0 8px', paddingLeft: 18 }}>
                {blocking.slice(0, 5).map((f, i) => (
                  <li key={i}>{f.message}</li>
                ))}
              </ul>
              <Button size="small" onClick={() => navigate(`/flows/${code}/design`)}>
                Mở trình thiết kế để sửa
              </Button>
            </>
          }
        />
      )}

      <div className="tst__grid">
        <section>
          <Typography.Text strong>Bản tin đầu vào</Typography.Text>
          <Input.TextArea
            className="t-mono"
            autoSize={{ minRows: 10, maxRows: 20 }}
            value={sample}
            onChange={(e) => setSample(e.target.value)}
            style={{ marginTop: 6 }}
          />
          <Typography.Paragraph type="secondary" className="t-small" style={{ marginTop: 6 }}>
            Không dán dữ liệu cá nhân thật — nhật ký chạy thử lưu lại kết quả từng chặng.
          </Typography.Paragraph>
        </section>

        <section>
          <Typography.Text strong>Kết quả theo chặng</Typography.Text>
          {error && (
            <Typography.Paragraph type="danger" style={{ marginTop: 6 }}>
              {error}
            </Typography.Paragraph>
          )}
          {result ? (
            <>
              <Space style={{ margin: '6px 0' }}>
                <Tag color={result.outcome === 'OK' ? '#15803d' : '#b91c1c'}>{result.outcome}</Tag>
                <Typography.Text type="secondary">
                  {result.durationMs} ms · {result.mode} · v{result.versionNo}
                </Typography.Text>
              </Space>
              <Table
                size="small"
                rowKey={(r) => `${r.stage}-${r.offsetMs}`}
                pagination={false}
                dataSource={result.waterfall}
                columns={[
                  { title: 'Chặng', dataIndex: 'stage' },
                  {
                    title: 'Kết quả',
                    dataIndex: 'status',
                    width: 120,
                    render: (s: string) => {
                      const v = STAGE_VI[s.toUpperCase()] ?? { label: s, color: 'default' }
                      return <Tag color={v.color}>{v.label}</Tag>
                    },
                  },
                  { title: 'Thời gian', dataIndex: 'durationMs', width: 100, render: (v: number) => `${v} ms` },
                  {
                    title: 'Tiến trình',
                    render: (_, r) => (
                      // Thanh biểu diễn độ trễ tích lũy — thấy ngay chặng nào chậm.
                      <div className="tst__bar">
                        <span
                          style={{
                            marginLeft: `${(r.offsetMs / Math.max(result.durationMs, 1)) * 100}%`,
                            width: `${Math.max((r.durationMs / Math.max(result.durationMs, 1)) * 100, 2)}%`,
                          }}
                        />
                      </div>
                    ),
                  },
                ]}
              />
            </>
          ) : (
            <Empty
              style={{ marginTop: 24 }}
              description="Chưa chạy lần nào. Bấm «Chạy thử» để bắt đầu."
            />
          )}
        </section>
      </div>
    </div>
  )
}

