import { Alert, Drawer, Empty, Select, Space, Table, Tag, Typography } from 'antd'
import { useCallback, useEffect, useMemo, useState } from 'react'
import { listVersions, type RouteSummary, type RouteVersion } from '../../api/routesApi'
import { YamlDiff } from '../review/YamlDiff'

interface Props {
  /** Luồng đang xem lịch sử; `null` là đóng ngăn. */
  route: RouteSummary | null
  onClose: () => void
}

const STATUS_VI: Record<string, string> = {
  DRAFT: 'Nháp',
  PENDING_REVIEW: 'Chờ duyệt',
  APPROVED: 'Đã duyệt',
  RETIRED: 'Đã gỡ',
}

/**
 * D-01 — Lịch sử phiên bản và so sánh hai phiên bản bất kỳ (FR-D-004).
 *
 * Không phải bản sao của màn duyệt: ở đây người dùng tự chọn **hai mốc bất kỳ** để so,
 * còn màn duyệt luôn so bản chờ duyệt với bản liền trước.
 */
export function VersionHistory({ route, onClose }: Props) {
  const [items, setItems] = useState<RouteVersion[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [left, setLeft] = useState<number | undefined>()
  const [right, setRight] = useState<number | undefined>()

  const load = useCallback(async (code: string) => {
    setLoading(true)
    setError(null)
    try {
      const r = await listVersions(code)
      setItems(r.items)
      // Mặc định so hai phiên bản mới nhất — đó là câu hỏi hay gặp nhất.
      setRight(r.items[0]?.versionNo)
      setLeft(r.items[1]?.versionNo)
    } catch (e) {
      setError(String(e instanceof Error ? e.message : e))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    if (route) void load(route.routeCode)
  }, [route, load])

  const byNo = useMemo(() => new Map(items.map((v) => [v.versionNo, v])), [items])
  const options = items.map((v) => ({
    value: v.versionNo,
    label: `v${v.versionNo} · ${STATUS_VI[v.status] ?? v.status}`,
  }))

  return (
    <Drawer
      open={Boolean(route)}
      onClose={onClose}
      width="min(1000px, 94vw)"
      title={route ? `Lịch sử phiên bản · ${route.routeCode}` : ''}
    >
      {error && <Alert type="error" showIcon message={error} style={{ marginBottom: 12 }} />}

      <Table<RouteVersion>
        size="small"
        rowKey="versionId"
        loading={loading}
        dataSource={items}
        pagination={false}
        style={{ marginBottom: 20 }}
        locale={{ emptyText: <Empty description="Chưa có phiên bản nào" /> }}
        columns={[
          {
            title: 'Phiên bản',
            dataIndex: 'versionNo',
            width: 100,
            render: (v: number) => <Typography.Text strong>v{v}</Typography.Text>,
          },
          {
            title: 'Trạng thái',
            dataIndex: 'status',
            width: 120,
            render: (s: string) => (
              <Tag color={s === 'APPROVED' ? '#15803d' : s === 'PENDING_REVIEW' ? '#1d4ed8' : 'default'}>
                {STATUS_VI[s] ?? s}
              </Tag>
            ),
          },
          { title: 'Nguồn', dataIndex: 'source', width: 110 },
          {
            title: 'Người tạo',
            dataIndex: 'createdBy',
            render: (v: string | null) => v ?? '—',
          },
          {
            title: 'git_commit_ref',
            dataIndex: 'gitCommitRef',
            width: 150,
            render: (v: string | null) =>
              v ? (
                <Typography.Text code ellipsis style={{ maxWidth: 130 }}>
                  {v}
                </Typography.Text>
              ) : (
                <Typography.Text type="secondary">chưa publish</Typography.Text>
              ),
          },
        ]}
      />

      <Typography.Title level={5}>So sánh hai phiên bản</Typography.Title>
      <Space wrap style={{ marginBottom: 12 }}>
        <Select
          style={{ width: 200 }}
          placeholder="Bản gốc"
          value={left}
          onChange={setLeft}
          options={options}
        />
        <Typography.Text type="secondary">→</Typography.Text>
        <Select
          style={{ width: 200 }}
          placeholder="Bản so"
          value={right}
          onChange={setRight}
          options={options}
        />
      </Space>

      {items.length < 2 ? (
        <Empty description="Cần ít nhất hai phiên bản để so sánh" />
      ) : left === right ? (
        <Alert type="info" showIcon message="Đang chọn cùng một phiên bản ở cả hai bên" />
      ) : (
        <YamlDiff
          oldYaml={(left != null ? byNo.get(left)?.definitionYaml : '') ?? ''}
          newYaml={(right != null ? byNo.get(right)?.definitionYaml : '') ?? ''}
        />
      )}
    </Drawer>
  )
}
