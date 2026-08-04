import { Alert, Button, Empty, Select, Space, Table, Tag, Typography } from 'antd'
import { useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import '../design/designer.css'
import { loadRuns, type StoredRun } from '../test/TestRunPage'

/**
 * D-05 — Nhật ký chạy của một luồng (FR-D-040/041).
 *
 * Nghiệp vụ này thiếu hẳn ở bản trước: chạy thử xong là mất kết quả, không tra lại được.
 */
export function RunLogPage() {
  const { code = '' } = useParams()
  const navigate = useNavigate()
  const [outcome, setOutcome] = useState<string | undefined>()
  const [selected, setSelected] = useState<StoredRun | null>(null)

  const runs = useMemo(() => loadRuns()[code] ?? [], [code])
  const shown = useMemo(
    () => (outcome ? runs.filter((r) => r.outcome === outcome) : runs),
    [runs, outcome],
  )

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

      <Alert
        type="info"
        showIcon
        style={{ marginBottom: 16 }}
        message="Nhật ký đang lưu tại trình duyệt"
        description={
          <>
            Máy chủ chưa có bảng lịch sử chạy (<code>ph04.route_test_run</code> — thuộc gói việc
            của lane L-CTRL). Trong lúc chờ, các lần chạy thử được giữ tạm ở máy này nên
            không chia sẻ được giữa người dùng và mất khi xóa dữ liệu trình duyệt.
          </>
        }
      />

      <Space wrap style={{ marginBottom: 16 }}>
        <Select
          allowClear
          placeholder="Lọc kết quả"
          style={{ width: 180 }}
          value={outcome}
          onChange={setOutcome}
          options={[
            { value: 'OK', label: 'Thành công' },
            { value: 'FAILED', label: 'Lỗi' },
          ]}
        />
        <Typography.Text type="secondary">{runs.length} lần chạy đã ghi</Typography.Text>
      </Space>

      <Table<StoredRun>
        rowKey={(r) => r.at}
        dataSource={shown}
        pagination={{ pageSize: 15 }}
        onRow={(r) => ({ onClick: () => setSelected(r), style: { cursor: 'pointer' } })}
        locale={{
          emptyText: (
            <Empty
              description={
                runs.length === 0
                  ? 'Chưa có lần chạy nào. Bấm «Chạy thử» để bắt đầu.'
                  : 'Không có lần chạy nào khớp bộ lọc'
              }
            />
          ),
        }}
        columns={[
          {
            title: 'Thời điểm',
            dataIndex: 'at',
            width: 190,
            render: (v: string) => v.slice(0, 19).replace('T', ' '),
          },
          { title: 'Phiên bản', dataIndex: 'versionNo', width: 100, render: (v: number) => `v${v}` },
          { title: 'Chế độ', dataIndex: 'mode', width: 110 },
          {
            title: 'Kết quả',
            dataIndex: 'outcome',
            width: 120,
            render: (v: string) => <Tag color={v === 'OK' ? 'green' : 'red'}>{v}</Tag>,
          },
          { title: 'Thời gian', dataIndex: 'durationMs', width: 110, render: (v: number) => `${v} ms` },
          {
            title: 'Số chặng',
            width: 100,
            render: (_, r) => r.waterfall?.length ?? 0,
          },
        ]}
      />

      {selected && (
        <div style={{ marginTop: 24 }}>
          <Typography.Title level={5}>
            Chi tiết lần chạy {selected.at.slice(0, 19).replace('T', ' ')}
          </Typography.Title>
          <Table
            size="small"
            rowKey={(r) => `${r.stage}-${r.offsetMs}`}
            pagination={false}
            dataSource={selected.waterfall}
            columns={[
              { title: 'Chặng', dataIndex: 'stage' },
              {
                title: 'Kết quả',
                dataIndex: 'status',
                width: 120,
                render: (s: string) => (
                  <Tag color={s.toUpperCase().startsWith('OK') || s.toUpperCase() === 'SUCCESS' ? 'green' : 'red'}>
                    {s}
                  </Tag>
                ),
              },
              { title: 'Thời gian', dataIndex: 'durationMs', width: 110, render: (v: number) => `${v} ms` },
              { title: 'Độ trễ tích lũy', dataIndex: 'offsetMs', width: 140, render: (v: number) => `${v} ms` },
            ]}
          />
        </div>
      )}
    </div>
  )
}
