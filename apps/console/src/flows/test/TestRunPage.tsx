import { App as AntApp, Button, Empty, Input, Select, Space, Table, Tag, Typography } from 'antd'
import { useCallback, useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import '../design/designer.css'
import { getRoute, runTest, type RouteSummary, type TestRunResult } from '../../api/routesApi'

/** Nhãn tiếng Việt cho trạng thái từng chặng trong waterfall. */
const STAGE_VI: Record<string, { label: string; color: string }> = {
  OK: { label: 'Thành công', color: 'green' },
  SUCCESS: { label: 'Thành công', color: 'green' },
  SKIPPED: { label: 'Bỏ qua', color: 'default' },
  FAILED: { label: 'Lỗi', color: 'red' },
  ERROR: { label: 'Lỗi', color: 'red' },
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

  const run = useCallback(async () => {
    setRunning(true)
    setError(null)
    try {
      const r = await runTest(code, versionNo, mode)
      setResult(r)
      // Lưu lại để màn nhật ký đọc được ngay cả khi máy chủ chưa có API lịch sử.
      rememberRun(code, r)
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
          <Button type="primary" loading={running} onClick={() => void run()}>
            Chạy thử
          </Button>
        </div>
      </Space>

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
                <Tag color={result.outcome === 'OK' ? 'green' : 'red'}>{result.outcome}</Tag>
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

/* ---------- Nhật ký chạy phía trình duyệt ---------- */

export interface StoredRun extends TestRunResult {
  at: string
}

const RUNS_KEY = 'lgsp.flow-runs'
/** Giữ tối đa 50 lần chạy gần nhất mỗi luồng. */
const MAX_RUNS = 50

/**
 * Ghi lại lần chạy.
 *
 * Máy chủ **chưa có** bảng lịch sử chạy (IP-06 G5-6 thuộc lane L-CTRL), nên tạm lưu
 * ở trình duyệt để màn nhật ký dùng được ngay. Đây là chỗ chứa tạm, không phải
 * nguồn sự thật — khi API có thì đọc từ máy chủ.
 */
export function rememberRun(code: string, result: TestRunResult): void {
  try {
    const all = loadRuns()
    const list = [{ ...result, at: new Date().toISOString() }, ...(all[code] ?? [])].slice(0, MAX_RUNS)
    localStorage.setItem(RUNS_KEY, JSON.stringify({ ...all, [code]: list }))
  } catch {
    // Hết chỗ lưu hoặc trình duyệt chặn — không chặn luồng chính vì việc này.
  }
}

export function loadRuns(): Record<string, StoredRun[]> {
  try {
    return JSON.parse(localStorage.getItem(RUNS_KEY) ?? '{}') as Record<string, StoredRun[]>
  } catch {
    return {}
  }
}
