import { Alert, App as AntApp, Button, Empty, Input, Select, Space, Table, Tag, Typography } from 'antd'
import { useCallback, useEffect, useMemo, useState } from 'react'
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
import {
  buildCurl,
  endpointUrl,
  extractSqlParams,
  liveProxyPath,
  parseHttpEntry,
  readFromUri,
} from './runtime'

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
  /** Định nghĩa của phiên bản đang chọn — nguồn suy ra điểm chạy thật + tham số SQL. */
  const [defYaml, setDefYaml] = useState('')
  /** Query string cho lần gọi LIVE (`tinh=Đà Nẵng`); mồi từ tham số SQL khi đọc xong YAML. */
  const [liveQuery, setLiveQuery] = useState('')
  const [liveResult, setLiveResult] = useState<{
    status: number
    ok: boolean
    durationMs: number
    body: string
    url: string
  } | null>(null)

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
      .then((v) => {
        if (alive) setDefYaml(v.definitionYaml ?? '')
        return validateYaml(v.definitionYaml ?? '')
      })
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

  /** Điểm chạy thật suy từ định nghĩa + hệ đích (góp ý: «không biết luồng chạy ở đâu»). */
  const entry = useMemo(() => {
    const uri = readFromUri(defYaml)
    return uri ? parseHttpEntry(uri) : null
  }, [defYaml])
  const realUrl = useMemo(
    () => (entry ? endpointUrl(route?.targetSystem, entry) : null),
    [entry, route?.targetSystem],
  )
  const sqlParams = useMemo(() => extractSqlParams(defYaml), [defYaml])

  // Mồi query LIVE bằng tham số SQL — thiếu param là camel-sql trả 500, khó lần.
  useEffect(() => {
    if (sqlParams.length) setLiveQuery(sqlParams.map((p) => `${p}=`).join('&'))
  }, [sqlParams])

  const curlCmd = useMemo(() => {
    if (!realUrl || !entry) return null
    return buildCurl(realUrl, entry.method, sqlParams, entry.method === 'GET' ? undefined : sample)
  }, [realUrl, entry, sqlParams, sample])

  const copy = useCallback(
    (text: string, label: string) => {
      void navigator.clipboard
        .writeText(text)
        .then(() => message.success(`Đã chép ${label}`))
        .catch(() => message.error('Trình duyệt chặn clipboard — chép tay giúp'))
    },
    [message],
  )

  /**
   * Gọi thật vào runtime qua proxy Vite (trình duyệt vướng CORS nếu gọi thẳng cổng
   * runtime; curl thì không). Kết quả là phản hồi HTTP thật, không phải waterfall giả lập.
   */
  const runLive = useCallback(async () => {
    if (!entry || !route?.targetSystem) return
    setRunning(true)
    setError(null)
    const t0 = performance.now()
    try {
      const url = liveProxyPath(route.targetSystem, entry, liveQuery.trim())
      const res = await fetch(url, {
        method: entry.method,
        ...(entry.method === 'GET'
          ? {}
          : { headers: { 'Content-Type': 'application/json' }, body: sample }),
      })
      const text = await res.text()
      let pretty = text
      try {
        pretty = JSON.stringify(JSON.parse(text), null, 2)
      } catch {
        // giữ nguyên body không phải JSON
      }
      setLiveResult({
        status: res.status,
        ok: res.ok,
        durationMs: Math.round(performance.now() - t0),
        body: pretty,
        url: realUrl ?? url,
      })
    } catch (e) {
      setError(
        `Không nối được runtime — kiểm tra hệ đích đang chạy (${realUrl ?? '?'}): ${String(
          e instanceof Error ? e.message : e,
        )}`,
      )
    } finally {
      setRunning(false)
    }
  }, [entry, route?.targetSystem, liveQuery, sample, realUrl])

  const run = useCallback(async () => {
    if (mode === 'LIVE') return runLive()
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
  }, [code, versionNo, mode, message, runLive])

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
        {mode === 'LIVE'
          ? 'Gọi thẳng vào runtime thật và hiện phản hồi HTTP nguyên văn.'
          : 'Giả lập khung 9 chặng trên máy chủ — không gọi hệ đích thật, chỉ để kiểm định nghĩa và ghi nhật ký.'}
      </Typography.Paragraph>

      {/* Điểm chạy thật — luồng phơi ở đâu, gọi bằng gì (góp ý người dùng 08/2026). */}
      {entry &&
        (realUrl ? (
          <Alert
            type="info"
            style={{ marginBottom: 16 }}
            message={
              <Space wrap>
                <Tag color="#1d4ed8">{entry.method}</Tag>
                <Typography.Text className="t-mono" copyable={{ text: realUrl }}>
                  {realUrl}
                </Typography.Text>
                <Typography.Text type="secondary" className="t-small">
                  hệ đích {route?.targetSystem} · cổng {new URL(realUrl).port || '80'}
                </Typography.Text>
                {curlCmd && (
                  <Button size="small" onClick={() => copy(curlCmd, 'lệnh curl')}>
                    Copy curl
                  </Button>
                )}
              </Space>
            }
          />
        ) : (
          <Alert
            type="warning"
            style={{ marginBottom: 16 }}
            message={
              entry.path
                ? `Chưa khai base URL cho hệ đích «${route?.targetSystem ?? '—'}» — bổ sung vào RUNTIME_BASES (flows/test/runtime.ts) để hiện điểm chạy và curl.`
                : `Chặng tiếp nhận không phơi HTTP (${entry.uri}) — luồng này gọi nội bộ, không có URL để curl.`
            }
          />
        ))}

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
              { value: 'MOCK', label: 'Giả lập 9 chặng (MOCK)' },
              { value: 'SANDBOX', label: 'Môi trường thử' },
              // Chỉ mở LIVE khi luồng có URL thật để gọi.
              ...(realUrl ? [{ value: 'LIVE', label: 'Gọi thật (LIVE)' }] : []),
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
          {mode === 'LIVE' && entry?.method === 'GET' ? (
            <>
              <Typography.Text strong>Query string</Typography.Text>
              <Input
                className="t-mono"
                value={liveQuery}
                onChange={(e) => setLiveQuery(e.target.value)}
                placeholder="tinh=Đà Nẵng"
                style={{ marginTop: 6 }}
              />
              <Typography.Paragraph type="secondary" className="t-small" style={{ marginTop: 6 }}>
                {sqlParams.length
                  ? `Luồng dùng tham số SQL: ${sqlParams.map((p) => `:#${p}`).join(', ')} — để trống giá trị (vd «${sqlParams[0]}=») nghĩa là không lọc; bỏ hẳn tham số sẽ bị runtime báo lỗi.`
                  : 'Thêm query string nếu luồng cần; để trống thì gọi URL trần.'}
              </Typography.Paragraph>
            </>
          ) : (
            <>
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
            </>
          )}
        </section>

        <section>
          <Typography.Text strong>
            {mode === 'LIVE' ? 'Phản hồi HTTP thật' : 'Kết quả theo chặng'}
          </Typography.Text>
          {error && (
            <Typography.Paragraph type="danger" style={{ marginTop: 6 }}>
              {error}
            </Typography.Paragraph>
          )}
          {mode === 'LIVE' ? (
            liveResult ? (
              <>
                <Space style={{ margin: '6px 0' }}>
                  <Tag color={liveResult.ok ? '#15803d' : '#b91c1c'}>HTTP {liveResult.status}</Tag>
                  <Typography.Text type="secondary">
                    {liveResult.durationMs} ms · <span className="t-mono">{liveResult.url}</span>
                  </Typography.Text>
                  <Button size="small" onClick={() => copy(liveResult.body, 'body phản hồi')}>
                    Copy body
                  </Button>
                </Space>
                {/* Cuộn trong khung, không đẩy cả trang (luật bố cục §6.1). */}
                <pre
                  className="t-mono"
                  style={{
                    margin: 0,
                    padding: 10,
                    maxHeight: 420,
                    overflow: 'auto',
                    border: '1px solid rgba(100,116,139,.25)',
                    borderRadius: 8,
                    fontSize: 12,
                  }}
                >
                  {liveResult.body}
                </pre>
              </>
            ) : (
              <Empty
                style={{ marginTop: 24 }}
                description="Chưa gọi lần nào. Bấm «Chạy thử» để gọi thẳng runtime."
              />
            )
          ) : result ? (
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

