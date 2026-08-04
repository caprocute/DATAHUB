import { Alert, Button, Empty, Select, Space, Table, Tag, Typography } from 'antd'
import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import '../design/designer.css'
import {
  getTestRun,
  listTestRuns,
  type TestRunDetail,
  type TestRunSummary,
} from '../../api/routesApi'

const OUTCOME_COLOR: Record<string, string> = {
  OK: 'green',
  PASSED: 'green',
  FAILED: 'red',
  ERROR: 'red',
}

function isOk(s: string): boolean {
  const v = s.toUpperCase()
  return v === 'OK' || v === 'PASSED' || v === 'SUCCESS'
}

function formatTime(iso: string): string {
  return iso.slice(0, 19).replace('T', ' ')
}

/**
 * D-05 — Nhật ký chạy của một luồng (FR-D-040/041).
 *
 * Đọc từ `ph04.route_test_run` ở máy chủ. Bản trước giữ tạm ở `localStorage` nên nhật
 * ký không chia sẻ được giữa người dùng và mất khi xóa dữ liệu trình duyệt — đúng lúc
 * cần tra cứu sự cố thì không còn gì để tra.
 */
export function RunLogPage() {
  const { code = '' } = useParams()
  const navigate = useNavigate()

  const [runs, setRuns] = useState<TestRunSummary[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [outcome, setOutcome] = useState<string | undefined>()

  const [detail, setDetail] = useState<TestRunDetail | null>(null)
  const [detailLoading, setDetailLoading] = useState(false)
  /** Hai lần chạy được chọn để so sánh (FR-D-032). */
  const [compare, setCompare] = useState<string[]>([])

  const refresh = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      setRuns((await listTestRuns(code, outcome)).items)
    } catch (e) {
      setError(String(e instanceof Error ? e.message : e))
    } finally {
      setLoading(false)
    }
  }, [code, outcome])

  useEffect(() => {
    void refresh()
  }, [refresh])

  async function openDetail(run: TestRunSummary) {
    setDetailLoading(true)
    try {
      setDetail(await getTestRun(code, run.runId))
    } catch (e) {
      setError(String(e instanceof Error ? e.message : e))
    } finally {
      setDetailLoading(false)
    }
  }

  /* ---------- So sánh hai lần chạy (G5-5) ---------- */

  const [diffA, setDiffA] = useState<TestRunDetail | null>(null)
  const [diffB, setDiffB] = useState<TestRunDetail | null>(null)

  useEffect(() => {
    if (compare.length !== 2) {
      setDiffA(null)
      setDiffB(null)
      return
    }
    let alive = true
    void Promise.all([getTestRun(code, compare[0]), getTestRun(code, compare[1])])
      .then(([a, b]) => {
        if (!alive) return
        setDiffA(a)
        setDiffB(b)
      })
      .catch((e: unknown) => alive && setError(String(e instanceof Error ? e.message : e)))
    return () => {
      alive = false
    }
  }, [compare, code])

  /** Ghép hai lần chạy theo tên chặng để thấy chặng nào chậm đi / hỏng thêm. */
  const comparison = useMemo(() => {
    if (!diffA || !diffB) return []
    const bByStage = new Map(diffB.stages.map((s) => [s.stage, s]))
    return diffA.stages.map((s) => {
      const other = bByStage.get(s.stage)
      return {
        stage: s.stage,
        aMs: s.durationMs,
        bMs: other?.durationMs ?? null,
        aStatus: s.status,
        bStatus: other?.status ?? null,
        deltaMs: other ? other.durationMs - s.durationMs : null,
      }
    })
  }, [diffA, diffB])

  return (
    <div className="page-card">
      <Space style={{ marginBottom: 12 }}>
        <Button size="small" onClick={() => navigate('/flows')}>
          ← Danh sách
        </Button>
        <Button size="small" onClick={() => navigate(`/flows/${code}/design`)}>
          Mở trình thiết kế
        </Button>
        <Button size="small" onClick={() => navigate(`/flows/${code}/test`)}>
          Chạy thử
        </Button>
      </Space>

      <Typography.Title level={3} style={{ marginTop: 0 }}>
        Nhật ký chạy · {code}
      </Typography.Title>
      <Typography.Paragraph type="secondary">
        Lịch sử chạy thử lưu ở máy chủ, chia sẻ được giữa người dùng. Theo FR-D-041, nhật ký
        chỉ ghi tên chặng, trạng thái và thời gian — <b>không</b> lưu nội dung bản tin.
      </Typography.Paragraph>

      {error && <Alert type="error" showIcon message={error} style={{ marginBottom: 12 }} />}

      <Space wrap style={{ marginBottom: 16 }}>
        <Select
          allowClear
          placeholder="Lọc kết quả"
          style={{ width: 180 }}
          value={outcome}
          onChange={setOutcome}
          options={[
            { value: 'PASSED', label: 'Thành công' },
            { value: 'FAILED', label: 'Lỗi' },
          ]}
        />
        <Button size="small" onClick={() => void refresh()}>
          Làm mới
        </Button>
        <Typography.Text type="secondary">
          {runs.length} lần chạy
          {compare.length > 0 && ` · đã chọn ${compare.length}/2 để so sánh`}
        </Typography.Text>
      </Space>

      <Table<TestRunSummary>
        rowKey="runId"
        loading={loading}
        dataSource={runs}
        pagination={{ pageSize: 15 }}
        rowSelection={{
          selectedRowKeys: compare,
          // Chỉ cho chọn tối đa hai lần chạy — so ba lần cùng lúc không đọc được.
          onChange: (keys) => setCompare(keys.slice(-2).map(String)),
          getCheckboxProps: (r) => ({
            disabled: compare.length >= 2 && !compare.includes(r.runId),
          }),
        }}
        onRow={(r) => ({ onClick: () => void openDetail(r), style: { cursor: 'pointer' } })}
        locale={{
          emptyText: (
            <Empty
              description={
                outcome
                  ? 'Không có lần chạy nào khớp bộ lọc'
                  : 'Chưa có lần chạy nào. Bấm «Chạy thử» để bắt đầu.'
              }
            />
          ),
        }}
        columns={[
          { title: 'Thời điểm', dataIndex: 'runAt', width: 180, render: formatTime },
          { title: 'Phiên bản', dataIndex: 'versionNo', width: 100, render: (v: number) => `v${v}` },
          { title: 'Chế độ', dataIndex: 'mode', width: 100 },
          {
            title: 'Kết quả',
            dataIndex: 'outcome',
            width: 120,
            render: (v: string) => <Tag color={OUTCOME_COLOR[v.toUpperCase()] ?? 'default'}>{v}</Tag>,
          },
          {
            title: 'Thời gian',
            dataIndex: 'durationMs',
            width: 110,
            render: (v: number) => `${v} ms`,
          },
          { title: 'Số chặng', dataIndex: 'stageCount', width: 100 },
          {
            title: 'Người chạy',
            dataIndex: 'runBy',
            render: (v: string) => (
              <Typography.Text ellipsis style={{ maxWidth: 200 }}>
                {v}
              </Typography.Text>
            ),
          },
        ]}
      />

      {comparison.length > 0 && diffA && diffB && (
        <div style={{ marginTop: 24 }}>
          <Typography.Title level={5}>
            So sánh · {formatTime(diffA.run.runAt)} → {formatTime(diffB.run.runAt)}
          </Typography.Title>
          <Typography.Paragraph type="secondary" className="t-small">
            Tổng: {diffA.run.durationMs} ms → {diffB.run.durationMs} ms
            {diffB.run.durationMs !== diffA.run.durationMs && (
              <b>
                {' '}
                ({diffB.run.durationMs > diffA.run.durationMs ? '+' : ''}
                {diffB.run.durationMs - diffA.run.durationMs} ms)
              </b>
            )}
          </Typography.Paragraph>
          <Table
            size="small"
            rowKey="stage"
            pagination={false}
            dataSource={comparison}
            columns={[
              { title: 'Chặng', dataIndex: 'stage' },
              {
                title: 'Lần A',
                width: 150,
                render: (_, r) => (
                  <Space size={4}>
                    <Tag color={isOk(r.aStatus) ? 'green' : 'red'}>{r.aStatus}</Tag>
                    <span>{r.aMs} ms</span>
                  </Space>
                ),
              },
              {
                title: 'Lần B',
                width: 150,
                render: (_, r) =>
                  r.bStatus == null ? (
                    <Typography.Text type="secondary">không có chặng này</Typography.Text>
                  ) : (
                    <Space size={4}>
                      <Tag color={isOk(r.bStatus) ? 'green' : 'red'}>{r.bStatus}</Tag>
                      <span>{r.bMs} ms</span>
                    </Space>
                  ),
              },
              {
                title: 'Chênh lệch',
                width: 120,
                render: (_, r) =>
                  r.deltaMs == null ? (
                    '—'
                  ) : (
                    <Typography.Text type={r.deltaMs > 0 ? 'danger' : 'success'}>
                      {r.deltaMs > 0 ? '+' : ''}
                      {r.deltaMs} ms
                    </Typography.Text>
                  ),
              },
            ]}
          />
        </div>
      )}

      {detail && (
        <div style={{ marginTop: 24 }}>
          <Typography.Title level={5}>
            Chi tiết lần chạy {formatTime(detail.run.runAt)}
          </Typography.Title>
          <Table
            size="small"
            loading={detailLoading}
            rowKey="seqNo"
            pagination={false}
            dataSource={detail.stages}
            columns={[
              { title: '#', dataIndex: 'seqNo', width: 60 },
              { title: 'Chặng', dataIndex: 'stage' },
              {
                title: 'Kết quả',
                dataIndex: 'status',
                width: 120,
                render: (s: string) => <Tag color={isOk(s) ? 'green' : 'red'}>{s}</Tag>,
              },
              {
                title: 'Thời gian',
                dataIndex: 'durationMs',
                width: 110,
                render: (v: number) => `${v} ms`,
              },
              {
                title: 'Độ trễ tích lũy',
                dataIndex: 'offsetMs',
                width: 140,
                render: (v: number) => `${v} ms`,
              },
              {
                title: 'Ghi chú lỗi',
                dataIndex: 'errorText',
                render: (v: string | null) => v ?? '—',
              },
            ]}
          />
        </div>
      )}
    </div>
  )
}
