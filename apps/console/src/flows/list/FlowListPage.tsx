import {
  App as AntApp,
  Button,
  Dropdown,
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
import type { TablePaginationConfig } from 'antd'
import type { SorterResult } from 'antd/es/table/interface'
import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  createRoute,
  deleteDraftVersion,
  duplicateRoute,
  renameRoute,
  searchRoutes,
  setRoutePaused,
  type RouteSummary,
} from '../../api/routesApi'
import { useRoles } from '../../auth/useRoles'
import { emitRouteYaml } from '../core/emit'
import { emptyFlow } from '../core/model'
import '../design/designer.css'
import { VersionHistory } from './VersionHistory'

/** Nhãn tiếng Việt của trạng thái luồng. */
const STATUS_VI: Record<string, string> = {
  DRAFT: 'Bản nháp',
  PENDING_REVIEW: 'Chờ duyệt',
  TESTING: 'Đang thử',
  ACTIVE: 'Đang chạy',
  PAUSED: 'Tạm dừng',
  RETIRED: 'Đã gỡ',
}

/**
 * Màu thẻ trạng thái — dùng mã màu thật, **không** dùng tên màu dựng sẵn của antd.
 *
 * Bảng màu dựng sẵn (`green`, `orange`…) cho chữ tông -600 trên nền rất nhạt, chỉ đạt
 * ~3,3:1 — dưới ngưỡng 4,5:1 của WCAG AA cho chữ thường. Bảng đó là hằng số của thư
 * viện, token `colorSuccess` không đổi được, nên phải chỉ định màu thẳng ở đây (N-7).
 */
const STATUS_COLOR: Record<string, string> = {
  DRAFT: 'default',
  PENDING_REVIEW: '#1d4ed8',
  TESTING: '#0e7490',
  ACTIVE: '#15803d',
  PAUSED: '#b45309',
  RETIRED: '#b91c1c',
}

/** Cột máy chủ cho phép sắp xếp — phải khớp danh sách trắng ở `RouteQuery`. */
const SORT_KEY: Record<string, string> = {
  routeCode: 'route_code',
  title: 'title',
  status: 'status',
  sourceSystem: 'source_system',
  updatedAt: 'updated_at',
}

const PAGE_SIZE = 15

function formatTime(iso?: string | null): string {
  if (!iso) return '—'
  return iso.slice(0, 16).replace('T', ' ')
}

/**
 * D-01 — Danh sách luồng tích hợp.
 *
 * Chỉ làm một nhiệm vụ: tìm luồng và mở việc. Thiết kế, chạy thử, nhật ký, duyệt
 * đều là màn riêng — không dồn vào đây như bản trước.
 */
export function FlowListPage() {
  const navigate = useNavigate()
  const { canDesign, canReview } = useRoles()
  const { message, modal } = AntApp.useApp()

  const [items, setItems] = useState<RouteSummary[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(0)
  const [sort, setSort] = useState('updated_at')
  const [desc, setDesc] = useState(true)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [q, setQ] = useState('')
  const [status, setStatus] = useState<string | undefined>()

  const [createOpen, setCreateOpen] = useState(false)
  const [historyOf, setHistoryOf] = useState<RouteSummary | null>(null)
  const [form] = Form.useForm<{ routeCode: string; title: string; sourceSystem: string; targetSystem?: string }>()

  /** Lọc/sắp xếp/phân trang đều ở máy chủ (FR-D-001) — trình duyệt không tự lọc nữa. */
  const refresh = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const r = await searchRoutes({ q, status, sort, desc, page, size: PAGE_SIZE })
      setItems(r.items)
      setTotal(r.total)
    } catch (e) {
      setError(String(e instanceof Error ? e.message : e))
    } finally {
      setLoading(false)
    }
  }, [q, status, sort, desc, page])

  useEffect(() => {
    void refresh()
  }, [refresh])

  /** Đổi bộ lọc thì phải quay về trang đầu, không thì lọc xong rơi vào trang trống. */
  function applyFilter(next: { q?: string; status?: string | undefined }) {
    if (next.q !== undefined) setQ(next.q)
    if ('status' in next) setStatus(next.status)
    setPage(0)
  }

  function onTableChange(
    pagination: TablePaginationConfig,
    _f: unknown,
    sorter: SorterResult<RouteSummary> | SorterResult<RouteSummary>[],
  ) {
    const s = Array.isArray(sorter) ? sorter[0] : sorter
    if (s?.field && s.order) {
      setSort(SORT_KEY[String(s.field)] ?? 'updated_at')
      setDesc(s.order === 'descend')
    }
    setPage((pagination.current ?? 1) - 1)
  }

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

  /* ---------- Thao tác từng dòng (FR-D-002) ---------- */

  function doRename(row: RouteSummary) {
    let next = row.title
    modal.confirm({
      title: `Đổi tên ${row.routeCode}`,
      content: (
        <>
          <Typography.Paragraph type="secondary" className="t-small">
            Mã luồng không đổi được — nó là khóa của tệp định nghĩa trong kho Git.
          </Typography.Paragraph>
          <Input defaultValue={row.title} onChange={(e) => (next = e.target.value)} />
        </>
      ),
      okText: 'Lưu',
      cancelText: 'Hủy',
      onOk: async () => {
        if (!next.trim()) {
          message.error('Tên luồng không được để trống')
          throw new Error('tên rỗng')
        }
        await renameRoute(row.routeCode, next.trim())
        message.success('Đã đổi tên')
        await refresh()
      },
    })
  }

  function doDuplicate(row: RouteSummary) {
    let code = `${row.routeCode}-ban-sao`
    let title = `${row.title} (bản sao)`
    modal.confirm({
      title: `Nhân bản ${row.routeCode}`,
      content: (
        <Space direction="vertical" style={{ width: '100%' }}>
          <Typography.Paragraph type="secondary" className="t-small" style={{ marginBottom: 0 }}>
            Bản sao chép định nghĩa đang chạy, bắt đầu lại từ phiên bản 1 ở trạng thái nháp.
          </Typography.Paragraph>
          <Input addonBefore="Mã" defaultValue={code} onChange={(e) => (code = e.target.value)} />
          <Input addonBefore="Tên" defaultValue={title} onChange={(e) => (title = e.target.value)} />
        </Space>
      ),
      okText: 'Nhân bản',
      cancelText: 'Hủy',
      onOk: async () => {
        const created = await duplicateRoute(row.routeCode, {
          routeCode: code.trim(),
          title: title.trim(),
        })
        message.success('Đã nhân bản')
        navigate(`/flows/${created.routeCode}/design`)
      },
    })
  }

  function doTogglePause(row: RouteSummary) {
    const paused = row.status === 'ACTIVE'
    modal.confirm({
      title: paused ? `Tạm dừng ${row.routeCode}?` : `Kích hoạt lại ${row.routeCode}?`,
      content: paused
        ? 'Luồng sẽ ngừng nhận bản tin mới. Bản tin đang xử lý vẫn chạy nốt.'
        : 'Luồng sẽ nhận bản tin trở lại theo định nghĩa đang publish.',
      okText: paused ? 'Tạm dừng' : 'Kích hoạt',
      cancelText: 'Hủy',
      onOk: async () => {
        await setRoutePaused(row.routeCode, paused)
        message.success(paused ? 'Đã tạm dừng' : 'Đã kích hoạt lại')
        await refresh()
      },
    })
  }

  function doDeleteDraft(row: RouteSummary) {
    if (row.draftVersionNo == null) return
    modal.confirm({
      title: `Xóa bản nháp v${row.draftVersionNo}?`,
      content: 'Định nghĩa của bản nháp này sẽ mất hẳn. Phiên bản đang chạy không bị ảnh hưởng.',
      okText: 'Xóa',
      okButtonProps: { danger: true },
      cancelText: 'Hủy',
      onOk: async () => {
        await deleteDraftVersion(row.routeCode, row.draftVersionNo!)
        message.success('Đã xóa bản nháp')
        await refresh()
      },
    })
  }

  const columns = useMemo(
    () => [
      {
        title: 'Mã luồng',
        dataIndex: 'routeCode',
        sorter: true,
        render: (v: string) => <Typography.Text strong>{v}</Typography.Text>,
      },
      { title: 'Tên', dataIndex: 'title', sorter: true },
      {
        title: 'Trạng thái',
        dataIndex: 'status',
        width: 120,
        sorter: true,
        render: (s: string) => <Tag color={STATUS_COLOR[s] ?? 'default'}>{STATUS_VI[s] ?? s}</Tag>,
      },
      {
        title: 'Phiên bản',
        width: 130,
        render: (_: unknown, r: RouteSummary) => (
          <Space size={4}>
            {r.currentVersionNo != null && <Tag color="#15803d">v{r.currentVersionNo}</Tag>}
            {r.draftVersionNo != null && <Tag>nháp v{r.draftVersionNo}</Tag>}
          </Space>
        ),
      },
      {
        title: 'git_commit_ref',
        dataIndex: 'gitCommitRef',
        width: 140,
        render: (v: string | null) =>
          v ? (
            <Tooltip title={v}>
              <Typography.Text code ellipsis style={{ maxWidth: 120 }}>
                {v}
              </Typography.Text>
            </Tooltip>
          ) : (
            <Typography.Text type="secondary">—</Typography.Text>
          ),
      },
      {
        title: 'Nguồn → Đích',
        width: 180,
        render: (_: unknown, r: RouteSummary) => (
          <Typography.Text type="secondary">
            {r.sourceSystem} → {r.targetSystem ?? '—'}
          </Typography.Text>
        ),
      },
      {
        // G2-2 — khi có sự cố, câu hỏi đầu tiên là "ai sửa gần nhất, lúc nào".
        title: 'Sửa gần nhất',
        dataIndex: 'updatedAt',
        width: 190,
        sorter: true,
        defaultSortOrder: 'descend' as const,
        render: (_: unknown, r: RouteSummary) => (
          <Space direction="vertical" size={0}>
            <Typography.Text className="t-small">{formatTime(r.updatedAt)}</Typography.Text>
            <Typography.Text type="secondary" className="t-small" ellipsis style={{ maxWidth: 170 }}>
              {r.updatedBy ?? 'không rõ'}
            </Typography.Text>
          </Space>
        ),
      },
      {
        title: 'Thao tác',
        width: 230,
        fixed: 'right' as const,
        render: (_: unknown, r: RouteSummary) => (
          <Space size={4}>
            <Button size="small" type="primary" onClick={() => navigate(`/flows/${r.routeCode}/design`)}>
              Thiết kế
            </Button>
            <Button size="small" onClick={() => navigate(`/flows/${r.routeCode}/test`)}>
              Chạy thử
            </Button>
            <Dropdown
              trigger={['click']}
              menu={{
                items: [
                  { key: 'runs', label: 'Nhật ký chạy' },
                  { key: 'history', label: 'Lịch sử phiên bản' },
                  { type: 'divider' as const },
                  { key: 'rename', label: 'Đổi tên', disabled: !canDesign },
                  { key: 'duplicate', label: 'Nhân bản', disabled: !canDesign },
                  {
                    key: 'pause',
                    label: r.status === 'ACTIVE' ? 'Tạm dừng' : 'Kích hoạt lại',
                    // Chỉ ACTIVE ↔ PAUSED mới đổi qua lại được; máy chủ cũng chặn.
                    disabled: !canReview || !['ACTIVE', 'PAUSED'].includes(r.status),
                  },
                  {
                    key: 'delete-draft',
                    label: 'Xóa bản nháp',
                    danger: true,
                    disabled: !canDesign || r.draftVersionNo == null,
                  },
                ],
                onClick: ({ key }) => {
                  if (key === 'runs') navigate(`/flows/${r.routeCode}/runs`)
                  else if (key === 'history') setHistoryOf(r)
                  else if (key === 'rename') doRename(r)
                  else if (key === 'duplicate') doDuplicate(r)
                  else if (key === 'pause') doTogglePause(r)
                  else if (key === 'delete-draft') doDeleteDraft(r)
                },
              }}
            >
              <Button size="small">Thêm ▾</Button>
            </Dropdown>
          </Space>
        ),
      },
    ],
    // `doRename` và bạn bè đóng trên `refresh`; đưa vào phụ thuộc để không giữ bản cũ.
    [navigate, canDesign, canReview, refresh],
  )

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
          onSearch={(v) => applyFilter({ q: v })}
          onChange={(e) => !e.target.value && applyFilter({ q: '' })}
        />
        <Select
          allowClear
          placeholder="Lọc trạng thái"
          style={{ width: 180 }}
          value={status}
          onChange={(v) => applyFilter({ status: v })}
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
        dataSource={items}
        scroll={{ x: 1200 }}
        onChange={onTableChange}
        pagination={{
          current: page + 1,
          pageSize: PAGE_SIZE,
          total,
          showSizeChanger: false,
          showTotal: (t) => `${t} luồng`,
        }}
        locale={{
          emptyText: (
            <Empty
              description={
                // Gọi API hỏng thì **không** được nói "chưa có luồng nào": người dùng
                // sẽ tưởng dữ liệu đã mất trong khi thật ra chỉ là hết phiên hay
                // máy chủ không trả lời. Ba trạng thái rỗng phải phân biệt rõ.
                error
                  ? 'Không tải được danh sách — xem thông báo lỗi phía trên.'
                  : q || status
                    ? 'Không có luồng nào khớp bộ lọc'
                    : 'Chưa có luồng nào. Bấm «Tạo luồng mới» để bắt đầu.'
              }
            />
          ),
        }}
        columns={columns}
      />

      <VersionHistory route={historyOf} onClose={() => setHistoryOf(null)} />

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
