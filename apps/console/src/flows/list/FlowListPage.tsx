import {
  App as AntApp,
  Button,
  Empty,
  Form,
  Input,
  Modal,
  Select,
  Space,
  Table,
  Tag,
  Tooltip,
  Typography,
} from 'antd'
import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { createRoute, listRoutes, type RouteSummary } from '../../api/routesApi'
import { useRoles } from '../../auth/useRoles'
import { emitRouteYaml } from '../core/emit'
import { emptyFlow } from '../core/model'

/** Nhãn tiếng Việt của trạng thái luồng. */
const STATUS_VI: Record<string, string> = {
  DRAFT: 'Bản nháp',
  PENDING_REVIEW: 'Chờ duyệt',
  ACTIVE: 'Đang chạy',
  PAUSED: 'Tạm dừng',
  RETIRED: 'Đã gỡ',
}

const STATUS_COLOR: Record<string, string> = {
  DRAFT: 'default',
  PENDING_REVIEW: 'blue',
  ACTIVE: 'green',
  PAUSED: 'orange',
  RETIRED: 'red',
}

/**
 * D-01 — Danh sách luồng tích hợp.
 *
 * Chỉ làm một nhiệm vụ: tìm luồng và mở việc. Thiết kế, chạy thử, nhật ký, duyệt
 * đều là màn riêng — không dồn vào đây như bản trước.
 */
export function FlowListPage() {
  const navigate = useNavigate()
  const { canDesign } = useRoles()
  const { message } = AntApp.useApp()

  const [items, setItems] = useState<RouteSummary[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [q, setQ] = useState('')
  const [status, setStatus] = useState<string | undefined>()

  const [createOpen, setCreateOpen] = useState(false)
  const [form] = Form.useForm<{ routeCode: string; title: string; sourceSystem: string; targetSystem?: string }>()

  const refresh = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      setItems((await listRoutes()).items)
    } catch (e) {
      setError(String(e instanceof Error ? e.message : e))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void refresh()
  }, [refresh])

  // Máy chủ chưa có tham số lọc cho danh sách luồng nên lọc tại chỗ; khi API bổ
  // sung thì chuyển sang lọc phía máy chủ theo FR-D-001.
  const shown = items.filter((r) => {
    if (status && r.status !== status) return false
    if (!q.trim()) return true
    const needle = q.trim().toLowerCase()
    return (
      r.routeCode.toLowerCase().includes(needle) ||
      r.title.toLowerCase().includes(needle) ||
      r.sourceSystem?.toLowerCase().includes(needle)
    )
  })

  async function doCreate() {
    const v = await form.validateFields()
    const { nodes, edges } = emptyFlow()
    try {
      await createRoute({
        ...v,
        definitionYaml: emitRouteYaml(nodes, edges, { routeId: v.routeCode, errorHandler: true }),
      })
      message.success('Đã tạo luồng mới')
      setCreateOpen(false)
      form.resetFields()
      // Vào thẳng trình thiết kế — người dùng tạo luồng là để thiết kế ngay.
      navigate(`/flows/${v.routeCode}/design`)
    } catch (e) {
      message.error(String(e instanceof Error ? e.message : e))
    }
  }

  return (
    <div className="page-card">
      <Typography.Title level={3} style={{ marginTop: 0 }}>
        Luồng tích hợp
      </Typography.Title>
      <Typography.Paragraph type="secondary">
        PH-04 — thiết kế, chạy thử và triển khai luồng qua GitOps. Mỗi luồng có trình thiết kế
        toàn màn hình riêng.
      </Typography.Paragraph>

      <Space wrap style={{ marginBottom: 16 }}>
        <Input.Search
          allowClear
          placeholder="Tìm theo mã, tên, hệ nguồn"
          style={{ width: 320 }}
          onSearch={setQ}
          onChange={(e) => !e.target.value && setQ('')}
        />
        <Select
          allowClear
          placeholder="Lọc trạng thái"
          style={{ width: 180 }}
          value={status}
          onChange={setStatus}
          options={Object.entries(STATUS_VI).map(([value, label]) => ({ value, label }))}
        />
        {canDesign && (
          <Button type="primary" onClick={() => setCreateOpen(true)}>
            Tạo luồng mới
          </Button>
        )}
        <Button onClick={() => void refresh()}>Làm mới</Button>
        <Button onClick={() => navigate('/flows/review')}>Hàng đợi duyệt</Button>
      </Space>

      {error && (
        <Typography.Paragraph type="danger">
          Không tải được danh sách: {error}
        </Typography.Paragraph>
      )}

      <Table<RouteSummary>
        rowKey="routeCode"
        loading={loading}
        dataSource={shown}
        pagination={{ pageSize: 15, showTotal: (t) => `${t} luồng` }}
        locale={{
          emptyText: (
            <Empty
              description={
                q || status
                  ? 'Không có luồng nào khớp bộ lọc'
                  : 'Chưa có luồng nào. Bấm «Tạo luồng mới» để bắt đầu.'
              }
            />
          ),
        }}
        columns={[
          {
            title: 'Mã luồng',
            dataIndex: 'routeCode',
            render: (v: string) => <Typography.Text strong>{v}</Typography.Text>,
          },
          { title: 'Tên', dataIndex: 'title' },
          {
            title: 'Trạng thái',
            dataIndex: 'status',
            width: 130,
            render: (s: string) => <Tag color={STATUS_COLOR[s] ?? 'default'}>{STATUS_VI[s] ?? s}</Tag>,
          },
          {
            title: 'Phiên bản',
            width: 130,
            render: (_, r) => (
              <Space size={4}>
                {r.currentVersionNo != null && <Tag color="green">v{r.currentVersionNo}</Tag>}
                {r.draftVersionNo != null && <Tag>nháp v{r.draftVersionNo}</Tag>}
              </Space>
            ),
          },
          {
            title: 'git_commit_ref',
            dataIndex: 'gitCommitRef',
            width: 160,
            render: (v: string | null) =>
              v ? (
                <Tooltip title={v}>
                  <Typography.Text code ellipsis style={{ maxWidth: 140 }}>
                    {v}
                  </Typography.Text>
                </Tooltip>
              ) : (
                <Typography.Text type="secondary">—</Typography.Text>
              ),
          },
          {
            title: 'Nguồn → Đích',
            width: 200,
            render: (_, r) => (
              <Typography.Text type="secondary">
                {r.sourceSystem} → {r.targetSystem ?? '—'}
              </Typography.Text>
            ),
          },
          {
            title: 'Thao tác',
            width: 260,
            render: (_, r) => (
              <Space size={4}>
                <Button size="small" type="primary" onClick={() => navigate(`/flows/${r.routeCode}/design`)}>
                  Thiết kế
                </Button>
                <Button size="small" onClick={() => navigate(`/flows/${r.routeCode}/test`)}>
                  Chạy thử
                </Button>
                <Button size="small" onClick={() => navigate(`/flows/${r.routeCode}/runs`)}>
                  Nhật ký
                </Button>
              </Space>
            ),
          },
        ]}
      />

      <Modal
        open={createOpen}
        title="Tạo luồng mới"
        onCancel={() => setCreateOpen(false)}
        onOk={() => void doCreate()}
        okText="Tạo & thiết kế"
        cancelText="Hủy"
      >
        <Typography.Paragraph type="secondary" className="t-small">
          Luồng mới dựng sẵn bốn chặng bắt buộc của khung chuẩn (Tiếp nhận · Kiểm tra lược đồ ·
          Ủy quyền · Ghi vết). Bổ sung phần nghiệp vụ vào giữa ở trình thiết kế.
        </Typography.Paragraph>
        <Form form={form} layout="vertical">
          <Form.Item
            name="routeCode"
            label="Mã luồng"
            rules={[
              { required: true, message: 'Bắt buộc' },
              {
                pattern: /^[a-z][a-z0-9-]{2,63}$/,
                message: 'Chữ thường, chữ số và gạch ngang, 3–64 ký tự',
              },
            ]}
          >
            <Input placeholder="tra-cuu-thua-dat" />
          </Form.Item>
          <Form.Item name="title" label="Tên luồng" rules={[{ required: true, message: 'Bắt buộc' }]}>
            <Input placeholder="Tra cứu thửa đất" />
          </Form.Item>
          <Form.Item name="sourceSystem" label="Hệ nguồn" rules={[{ required: true, message: 'Bắt buộc' }]}>
            <Input placeholder="HE_THONG_MOT_CUA" />
          </Form.Item>
          <Form.Item name="targetSystem" label="Hệ đích">
            <Input placeholder="CSDL_DAT_DAI" />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  )
}
