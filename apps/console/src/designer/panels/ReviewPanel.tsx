import { Alert, App as AntApp, Button, Drawer, Empty, Space, Table, Tag, Typography } from 'antd'
import { useCallback, useEffect, useState } from 'react'
import { getVersion, listPendingReview, reviewVersion, type RouteVersion } from '../../api/routesApi'
import { useRoles } from '../../auth/useRoles'
import { stripCanvas } from '../canvasCodec'
import { YamlDiff } from './YamlDiff'

/** UI-04-09 — hàng đợi duyệt thật từ API (không dữ liệu giả). */
export function ReviewPanel() {
  const { message, modal } = AntApp.useApp()
  const { canReview, subject, username } = useRoles()
  const [items, setItems] = useState<RouteVersion[]>([])
  const [loading, setLoading] = useState(false)
  /** Phiên bản đang xem diff trước khi quyết định (B7-5). */
  const [viewing, setViewing] = useState<RouteVersion | null>(null)
  const [baseYaml, setBaseYaml] = useState('')
  const [diffLoading, setDiffLoading] = useState(false)

  const refresh = useCallback(async () => {
    if (!canReview) {
      setItems([])
      return
    }
    setLoading(true)
    try {
      const data = await listPendingReview()
      setItems(data.items)
    } catch (e) {
      message.error(String(e))
    } finally {
      setLoading(false)
    }
  }, [canReview, message])

  useEffect(() => {
    void refresh()
  }, [refresh])

  if (!canReview) {
    return (
      <Typography.Paragraph type="secondary">
        Cần vai trò <Tag>INTEGRATION_REVIEWER</Tag> (hoặc admin) để xem hàng đợi duyệt — SRS-19 /
        bốn mắt.
      </Typography.Paragraph>
    )
  }

  /** Mở ngăn so sánh: lấy bản trước đó làm mốc, không có thì coi như luồng mới. */
  async function openDiff(row: RouteVersion) {
    setViewing(row)
    setBaseYaml('')
    if (row.versionNo <= 1) return
    setDiffLoading(true)
    try {
      const prev = await getVersion(row.routeCode, row.versionNo - 1)
      setBaseYaml(stripCanvas(prev.definitionYaml ?? ''))
    } catch {
      // Không đọc được bản trước thì vẫn cho duyệt, chỉ là diff hiện toàn bộ là thêm mới.
      setBaseYaml('')
    } finally {
      setDiffLoading(false)
    }
  }

  async function decide(row: RouteVersion, decision: 'APPROVE' | 'REJECT') {
    if (row.createdBy && subject && row.createdBy === subject) {
      message.error('Bốn mắt: không tự duyệt phiên bản do chính mình tạo')
      return
    }
    modal.confirm({
      title: decision === 'APPROVE' ? 'Phê duyệt và publish GitOps?' : 'Trả lại DRAFT?',
      content:
        decision === 'APPROVE'
          ? `${row.routeCode} v${row.versionNo} → validate + ghi routes/ (GitOps). Người duyệt: ${username}`
          : `${row.routeCode} v${row.versionNo} trả về DRAFT để sửa.`,
      onOk: async () => {
        try {
          await reviewVersion(row.routeCode, row.versionNo, decision)
          message.success(decision === 'APPROVE' ? 'Đã phê duyệt + publish' : 'Đã trả lại DRAFT')
          setViewing(null)
          await refresh()
        } catch (e) {
          message.error(String(e))
        }
      },
    })
  }

  return (
    <div>
      <Typography.Paragraph type="secondary">
        UI-04-09 · FR-04-029 — chỉ phiên bản <Tag>PENDING_REVIEW</Tag>. Approve kích hoạt GitOps;
        không hiển thị secret trong YAML panel (chỉ metadata).
      </Typography.Paragraph>
      <Table
        rowKey="versionId"
        loading={loading}
        dataSource={items}
        locale={{ emptyText: <Empty description="Không có luồng chờ duyệt" /> }}
        pagination={false}
        columns={[
          { title: 'Mã luồng', dataIndex: 'routeCode' },
          { title: 'Phiên bản', dataIndex: 'versionNo', width: 100 },
          { title: 'Nguồn', dataIndex: 'source', width: 110 },
          {
            title: 'Người tạo (sub)',
            dataIndex: 'createdBy',
            ellipsis: true,
            render: (v: string) => <Typography.Text code>{v?.slice(0, 12) ?? '—'}…</Typography.Text>,
          },
          {
            title: 'Thao tác',
            width: 320,
            render: (_, row) => (
              <Space>
                <Button size="small" onClick={() => void openDiff(row)}>
                  Xem thay đổi
                </Button>
                <Button type="primary" size="small" onClick={() => void decide(row, 'APPROVE')}>
                  Phê duyệt
                </Button>
                <Button danger size="small" onClick={() => void decide(row, 'REJECT')}>
                  Trả lại
                </Button>
              </Space>
            ),
          },
        ]}
      />
      <Button style={{ marginTop: 12 }} onClick={() => void refresh()}>
        Làm mới
      </Button>

      <Drawer
        open={Boolean(viewing)}
        onClose={() => setViewing(null)}
        width={860}
        title={viewing ? `${viewing.routeCode} · phiên bản ${viewing.versionNo}` : ''}
        extra={
          viewing && (
            <Space>
              <Button danger onClick={() => void decide(viewing, 'REJECT')}>
                Trả lại
              </Button>
              <Button type="primary" onClick={() => void decide(viewing, 'APPROVE')}>
                Phê duyệt
              </Button>
            </Space>
          )
        }
      >
        {viewing && (
          <Space direction="vertical" size="middle" style={{ width: '100%' }}>
            {viewing.createdBy && subject && viewing.createdBy === subject && (
              <Alert
                type="warning"
                showIcon
                message="Bạn là người tạo phiên bản này"
                description="Luật bốn mắt: phải để người khác duyệt."
              />
            )}
            <Typography.Text type="secondary" className="t-small">
              {viewing.versionNo <= 1
                ? 'Luồng mới — so với bản rỗng.'
                : `So với phiên bản ${viewing.versionNo - 1}.`}
            </Typography.Text>
            {diffLoading ? (
              <Typography.Text type="secondary">Đang tải bản trước…</Typography.Text>
            ) : (
              <YamlDiff
                oldYaml={baseYaml}
                newYaml={stripCanvas(viewing.definitionYaml ?? '')}
              />
            )}
          </Space>
        )}
      </Drawer>
    </div>
  )
}
