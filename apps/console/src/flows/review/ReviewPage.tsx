import { Alert, App as AntApp, Button, Drawer, Empty, Input, Space, Table, Tag, Typography } from 'antd'
import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import '../design/designer.css'
import {
  getVersion,
  listPendingReview,
  reviewVersion,
  type RouteVersion,
} from '../../api/routesApi'
import { useRoles } from '../../auth/useRoles'
import { YamlDiff } from './YamlDiff'

/**
 * D-06 — Hàng đợi duyệt phiên bản luồng.
 *
 * Tách thành màn riêng thay vì một tab lẫn trong trình thiết kế: duyệt là việc của
 * người khác, ở thời điểm khác, và cần đủ chỗ để đọc khác biệt.
 */
export function ReviewPage() {
  const navigate = useNavigate()
  const { message, modal } = AntApp.useApp()
  const { canReview, subject, username } = useRoles()

  const [items, setItems] = useState<RouteVersion[]>([])
  const [loading, setLoading] = useState(false)
  const [viewing, setViewing] = useState<RouteVersion | null>(null)
  const [baseYaml, setBaseYaml] = useState('')
  /** Định nghĩa của bản chờ duyệt — phải lấy riêng, xem ghi chú ở `openDiff`. */
  const [newYaml, setNewYaml] = useState('')
  const [diffLoading, setDiffLoading] = useState(false)
  /** Đã mở xem khác biệt của phiên bản nào — chưa xem thì không cho duyệt. */
  const [reviewed, setReviewed] = useState<Set<string>>(new Set())

  const refresh = useCallback(async () => {
    if (!canReview) return
    setLoading(true)
    try {
      setItems((await listPendingReview()).items)
    } catch (e) {
      message.error(String(e instanceof Error ? e.message : e))
    } finally {
      setLoading(false)
    }
  }, [canReview, message])

  useEffect(() => {
    void refresh()
  }, [refresh])

  /** Mở ngăn so sánh; lấy bản trước làm mốc, không có thì coi như luồng mới. */
  async function openDiff(row: RouteVersion) {
    setViewing(row)
    setBaseYaml('')
    setNewYaml('')
    setReviewed((s) => new Set(s).add(row.versionId))
    setDiffLoading(true)
    try {
      // Hàng đợi cố ý chỉ trả siêu dữ liệu (ATTT phía máy chủ), nên định nghĩa
      // phải lấy riêng từng phiên bản khi người duyệt thật sự mở ra xem.
      const cur = await getVersion(row.routeCode, row.versionNo)
      setNewYaml(cur.definitionYaml ?? '')
      if (row.versionNo > 1) {
        try {
          const prev = await getVersion(row.routeCode, row.versionNo - 1)
          setBaseYaml(prev.definitionYaml ?? '')
        } catch {
          // Không đọc được bản trước thì diff hiện toàn bộ là thêm mới.
          setBaseYaml('')
        }
      }
    } catch (e) {
      message.error(`Không đọc được định nghĩa: ${e instanceof Error ? e.message : e}`)
    } finally {
      setDiffLoading(false)
    }
  }

  function decide(row: RouteVersion, decision: 'APPROVE' | 'REJECT') {
    // Bốn mắt: chốt chặn thật ở máy chủ (403), đây chỉ đỡ cho người dùng khỏi bấm nhầm.
    if (row.createdBy && subject && row.createdBy === subject) {
      message.error('Bốn mắt: không tự duyệt phiên bản do chính mình tạo')
      return
    }
    modal.confirm({
      title: decision === 'APPROVE' ? 'Phê duyệt và publish?' : 'Trả lại bản nháp?',
      content:
        decision === 'APPROVE'
          ? `${row.routeCode} v${row.versionNo} sẽ được kiểm tra lại rồi ghi vào routes/ (GitOps). Người duyệt: ${username}`
          : `${row.routeCode} v${row.versionNo} trả về DRAFT để sửa.`,
      okText: decision === 'APPROVE' ? 'Phê duyệt' : 'Trả lại',
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await reviewVersion(row.routeCode, row.versionNo, decision)
          message.success(decision === 'APPROVE' ? 'Đã phê duyệt và publish' : 'Đã trả lại bản nháp')
          setViewing(null)
          await refresh()
        } catch (e) {
          message.error(String(e instanceof Error ? e.message : e))
        }
      },
    })
  }

  if (!canReview) {
    return (
      <div className="page-card">
        <Typography.Title level={3} style={{ marginTop: 0 }}>
          Hàng đợi duyệt
        </Typography.Title>
        <Alert
          type="info"
          showIcon
          message="Bạn không có quyền duyệt luồng"
          description={
            <>
              Cần vai trò <Tag>INTEGRATION_REVIEWER</Tag> hoặc quản trị (SRS-19).
            </>
          }
        />
        <Button style={{ marginTop: 16 }} onClick={() => navigate('/flows')}>
          ← Về danh sách luồng
        </Button>
      </div>
    )
  }

  return (
    <div className="page-card">
      <Space style={{ marginBottom: 12 }}>
        <Button size="small" onClick={() => navigate('/flows')}>
          ← Danh sách
        </Button>
        <Button size="small" onClick={() => void refresh()}>
          Làm mới
        </Button>
      </Space>

      <Typography.Title level={3} style={{ marginTop: 0 }}>
        Hàng đợi duyệt luồng
      </Typography.Title>
      <Typography.Paragraph type="secondary">
        FR-04-029 — phải xem khác biệt trước khi quyết định. Phê duyệt sẽ kiểm tra lại và ghi
        định nghĩa vào kho Git.
      </Typography.Paragraph>

      <Table<RouteVersion>
        rowKey="versionId"
        loading={loading}
        dataSource={items}
        pagination={false}
        locale={{ emptyText: <Empty description="Không có phiên bản nào chờ duyệt" /> }}
        columns={[
          { title: 'Mã luồng', dataIndex: 'routeCode' },
          { title: 'Phiên bản', dataIndex: 'versionNo', width: 110, render: (v: number) => `v${v}` },
          { title: 'Nguồn', dataIndex: 'source', width: 130 },
          {
            title: 'Người tạo',
            dataIndex: 'createdBy',
            width: 200,
            render: (v: string | null) =>
              v ? (
                <Typography.Text code ellipsis style={{ maxWidth: 180 }}>
                  {v}
                </Typography.Text>
              ) : (
                '—'
              ),
          },
          {
            title: 'Thao tác',
            width: 300,
            render: (_, row) => {
              const seen = reviewed.has(row.versionId)
              const own = Boolean(row.createdBy && subject && row.createdBy === subject)
              return (
                <Space size={4}>
                  <Button size="small" type="primary" onClick={() => void openDiff(row)}>
                    Xem khác biệt
                  </Button>
                  <Button
                    size="small"
                    disabled={!seen || own}
                    title={
                      own
                        ? 'Bốn mắt: không tự duyệt phiên bản của mình'
                        : !seen
                          ? 'Xem khác biệt trước đã'
                          : undefined
                    }
                    onClick={() => decide(row, 'APPROVE')}
                  >
                    Phê duyệt
                  </Button>
                  <Button size="small" danger disabled={own} onClick={() => decide(row, 'REJECT')}>
                    Trả lại
                  </Button>
                </Space>
              )
            },
          },
        ]}
      />

      <Drawer
        open={Boolean(viewing)}
        onClose={() => setViewing(null)}
        width="min(900px, 92vw)"
        title={viewing ? `${viewing.routeCode} · phiên bản ${viewing.versionNo}` : ''}
        extra={
          viewing && (
            <Space>
              <Button danger onClick={() => decide(viewing, 'REJECT')}>
                Trả lại
              </Button>
              <Button
                type="primary"
                disabled={Boolean(viewing.createdBy && subject && viewing.createdBy === subject)}
                onClick={() => decide(viewing, 'APPROVE')}
              >
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
                description="Luật bốn mắt: phải để người khác duyệt. Máy chủ cũng sẽ từ chối."
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
              <YamlDiff oldYaml={baseYaml} newYaml={newYaml} />
            )}

            <div>
              <Typography.Text strong>Ghi chú khi duyệt</Typography.Text>
              <Input.TextArea
                rows={3}
                placeholder="Ý kiến thẩm định, điều kiện kèm theo…"
                style={{ marginTop: 6 }}
              />
            </div>
          </Space>
        )}
      </Drawer>
    </div>
  )
}
