import {
  Alert,
  App as AntApp,
  Button,
  Drawer,
  Empty,
  Form,
  Input,
  Modal,
  Select,
  Space,
  Steps,
  Table,
  Tabs,
  Upload,
  Tag,
  Timeline,
  Typography,
} from 'antd'
import { useCallback, useEffect, useRef, useState } from 'react'
import {
  ACCEPT_TYPES,
  ACTION_VI,
  MAX_ATTACHMENT_BYTES,
  STATUS_COLOR,
  STATUS_VI,
  activateApplication,
  approveApplication,
  downloadAttachment,
  exportApplications,
  getAudit,
  humanSize,
  listAttachments,
  listDueAccessReview,
  recordAccessReview,
  rejectApplication,
  resumeApplication,
  revokeApplication,
  reviewLegal,
  reviewTechnical,
  searchApplications,
  submitApplication,
  suspendApplication,
  uploadAttachment,
  type Application,
  type ApplicationStatus,
  type Attachment,
  type AuditEntry,
  type Review,
  type SubmitBody,
} from '../api/onboardingApi'
import { useRoles } from '../auth/useRoles'

const PAGE_SIZE = 10

/** Ba bước khai hồ sơ (FR-01-001, FR-01-003) — chia bước để biểu mẫu không quá dài. */
const STEPS = [
  { title: 'Hệ thống', fields: ['systemCode', 'systemName', 'ownerOrg'] as const },
  { title: 'Căn cứ & năng lực', fields: ['legalBasis', 'techProfile'] as const },
  { title: 'Đầu mối', fields: ['contactName', 'contactEmail', 'contactPhone'] as const },
]

function ReviewCard({ title, review }: { title: string; review: Review | null }) {
  const done = review?.status
  return (
    <div className="review-card">
      <div className="review-card__head">
        <strong>{title}</strong>
        {done ? (
          <Tag color={review.status === 'PASS' ? 'green' : 'red'}>
            {review.status === 'PASS' ? 'Đạt' : 'Không đạt'}
          </Tag>
        ) : (
          <Tag>Chưa thẩm định</Tag>
        )}
      </div>
      {done && (
        <Typography.Paragraph type="secondary" className="t-small" style={{ margin: 0 }}>
          {review.reviewedBy} · {review.reviewedAt?.slice(0, 19).replace('T', ' ')}
          {review.note ? ` — ${review.note}` : ''}
        </Typography.Paragraph>
      )}
    </div>
  )
}

export function OnboardingPage() {
  const { canReview, canDesign, roles, username } = useRoles()
  const canAdmin = roles.has('INTEGRATION_ADMIN') || roles.has('PLATFORM_ADMIN')
  const canRevoke = roles.has('PLATFORM_ADMIN')
  const { message, modal } = AntApp.useApp()

  const [items, setItems] = useState<Application[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(0)
  const [q, setQ] = useState('')
  const [status, setStatus] = useState<string | undefined>()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const [detail, setDetail] = useState<Application | null>(null)
  const [audit, setAudit] = useState<AuditEntry[]>([])
  const [files, setFiles] = useState<Attachment[]>([])
  const [uploading, setUploading] = useState(false)
  /** Chỉ hiện hồ sơ tới hạn rà soát quyền (FR-01-013). */
  const [dueOnly, setDueOnly] = useState(false)
  const dueRef = useRef(false)
  dueRef.current = dueOnly
  const [secret, setSecret] = useState<{ code: string; value: string } | null>(null)

  const [formOpen, setFormOpen] = useState(false)
  const [step, setStep] = useState(0)
  const [form] = Form.useForm<SubmitBody>()

  const refresh = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      if (dueRef.current) {
        // Danh sách nhắc việc là tập nhỏ, máy chủ trả hết một lần.
        const due = await listDueAccessReview()
        setItems(due.items)
        setTotal(due.items.length)
        return
      }
      const data = await searchApplications({ q, status, page, size: PAGE_SIZE })
      setItems(data.items)
      setTotal(data.total)
    } catch (e) {
      setError(String(e instanceof Error ? e.message : e))
    } finally {
      setLoading(false)
    }
  }, [q, status, page, dueOnly])

  useEffect(() => {
    void refresh()
  }, [refresh])

  /** Chạy một hành vi rồi làm mới cả bảng lẫn ngăn chi tiết. */
  async function run(fn: () => Promise<Application>, ok: string) {
    try {
      const updated = await fn()
      message.success(ok)
      setDetail(updated)
      await refresh()
      if (detail) void loadAudit(updated.id)
      return updated
    } catch (e) {
      message.error(String(e instanceof Error ? e.message : e))
      return null
    }
  }

  async function loadAudit(id: string) {
    try {
      const data = await getAudit(id)
      setAudit(data.items)
    } catch {
      // Không có quyền đọc nhật ký thì ẩn phần này, không chặn xem chi tiết.
      setAudit([])
    }
  }

  async function loadFiles(id: string) {
    try {
      setFiles((await listAttachments(id)).items)
    } catch {
      setFiles([])
    }
  }

  async function openDetail(row: Application) {
    setDetail(row)
    setAudit([])
    setFiles([])
    void loadAudit(row.id)
    void loadFiles(row.id)
  }

  /** Hỏi lý do trước các hành vi cần ghi vết (từ chối, tạm ngừng, thu hồi). */
  function askReason(title: string, onOk: (reason: string) => Promise<unknown>) {
    let reason = ''
    modal.confirm({
      title,
      content: (
        <Input.TextArea
          rows={3}
          placeholder="Lý do — bắt buộc, sẽ lưu vào nhật ký kiểm toán"
          onChange={(e) => {
            reason = e.target.value
          }}
        />
      ),
      okText: 'Xác nhận',
      cancelText: 'Hủy',
      onOk: async () => {
        if (!reason.trim()) {
          message.error('Phải ghi lý do')
          throw new Error('thiếu lý do')
        }
        await onOk(reason.trim())
      },
    })
  }

  async function nextStep() {
    try {
      await form.validateFields(STEPS[step].fields as unknown as string[])
      setStep((s) => s + 1)
    } catch {
      /* antd đã hiện lỗi tại trường */
    }
  }

  return (
    <div className="page-card">
      <Typography.Title level={3}>Kết nạp hệ thống</Typography.Title>
      <Typography.Paragraph type="secondary">
        PH-01 — nộp hồ sơ, thẩm định pháp lý và kỹ thuật, duyệt bốn mắt, quản lý vòng đời thành
        viên. Danh sách không bao giờ trả bí mật.
      </Typography.Paragraph>

      {secret && (
        <Alert
          type="warning"
          showIcon
          closable
          onClose={() => setSecret(null)}
          style={{ marginBottom: 16 }}
          message={`Bí mật của ${secret.code} — chỉ hiện một lần`}
          description={
            <Space direction="vertical" style={{ width: '100%' }}>
              <Typography.Text code copyable={{ text: secret.value }}>
                {secret.value}
              </Typography.Text>
              <Typography.Text type="secondary" className="t-small">
                Chép và bàn giao an toàn ngay. Đóng thông báo này là không xem lại được.
              </Typography.Text>
            </Space>
          }
        />
      )}

      <Space wrap style={{ marginBottom: 16 }}>
        <Input.Search
          allowClear
          placeholder="Tìm theo mã, tên hệ thống, đơn vị"
          style={{ width: 320 }}
          onSearch={(v) => {
            setPage(0)
            setQ(v)
          }}
        />
        <Select
          allowClear
          placeholder="Lọc trạng thái"
          style={{ width: 190 }}
          value={status}
          onChange={(v) => {
            setPage(0)
            setStatus(v)
          }}
          options={Object.entries(STATUS_VI).map(([value, label]) => ({ value, label }))}
        />
        {canDesign && (
          <Button
            type="primary"
            onClick={() => {
              form.resetFields()
              setStep(0)
              setFormOpen(true)
            }}
          >
            Nộp hồ sơ mới
          </Button>
        )}
        {canAdmin && (
          <Button
            type={dueOnly ? 'primary' : 'default'}
            onClick={() => {
              setPage(0)
              setDueOnly((v) => !v)
            }}
          >
            {dueOnly ? 'Đang xem: tới hạn rà soát' : 'Tới hạn rà soát quyền'}
          </Button>
        )}
        {canReview && (
          <Button
            onClick={async () => {
              try {
                await exportApplications({ q, status })
                message.success('Đã xuất danh sách theo bộ lọc đang áp')
              } catch (e) {
                message.error(String(e instanceof Error ? e.message : e))
              }
            }}
          >
            Xuất CSV
          </Button>
        )}
      </Space>

      {error && (
        <Alert
          type="error"
          showIcon
          style={{ marginBottom: 16 }}
          message="Không tải được danh sách"
          description={error}
          action={
            <Button size="small" onClick={() => void refresh()}>
              Thử lại
            </Button>
          }
        />
      )}

      <Table<Application>
        rowKey="id"
        loading={loading}
        dataSource={items}
        locale={{
          emptyText: (
            <Empty
              description={
                dueOnly
                  ? 'Không có hồ sơ nào tới hạn rà soát quyền.'
                  : q || status
                    ? 'Không có hồ sơ nào khớp bộ lọc'
                    : 'Chưa có hồ sơ kết nạp nào. Bấm «Nộp hồ sơ mới» để bắt đầu.'
              }
            />
          ),
        }}
        pagination={{
          current: page + 1,
          pageSize: dueOnly ? Math.max(total, 1) : PAGE_SIZE,
          total,
          showSizeChanger: false,
          showTotal: (t) => `${t} hồ sơ`,
          onChange: (p) => setPage(p - 1),
        }}
        onRow={(row) => ({ onClick: () => void openDetail(row), style: { cursor: 'pointer' } })}
        columns={[
          { title: 'Mã hệ thống', dataIndex: 'systemCode', width: 180 },
          { title: 'Tên', dataIndex: 'systemName' },
          { title: 'Đơn vị chủ quản', dataIndex: 'ownerOrg' },
          {
            title: 'Trạng thái',
            dataIndex: 'status',
            width: 150,
            render: (s: ApplicationStatus) => <Tag color={STATUS_COLOR[s]}>{STATUS_VI[s]}</Tag>,
          },
          {
            title: 'Thẩm định',
            width: 130,
            render: (_, r) => (
              <Space size={4}>
                <Tag color={r.legalReview?.status === 'PASS' ? 'green' : r.legalReview?.status === 'FAIL' ? 'red' : undefined}>
                  PL
                </Tag>
                <Tag color={r.techReview?.status === 'PASS' ? 'green' : r.techReview?.status === 'FAIL' ? 'red' : undefined}>
                  KT
                </Tag>
              </Space>
            ),
          },
          { title: 'clientId', dataIndex: 'clientId', width: 200 },
        ]}
      />

      {/* ---------- Ngăn chi tiết ---------- */}
      <Drawer
        open={Boolean(detail)}
        onClose={() => setDetail(null)}
        width={720}
        title={detail ? `${detail.systemCode} — ${detail.systemName}` : ''}
        extra={
          detail && <Tag color={STATUS_COLOR[detail.status]}>{STATUS_VI[detail.status]}</Tag>
        }
      >
        {detail && (
          <Tabs
            items={[
              {
                key: 'info',
                label: 'Hồ sơ',
                children: (
                  <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                    <div>
                      <Typography.Text type="secondary">Đơn vị chủ quản</Typography.Text>
                      <div>{detail.ownerOrg}</div>
                    </div>
                    <div>
                      <Typography.Text type="secondary">Căn cứ pháp lý</Typography.Text>
                      <div style={{ whiteSpace: 'pre-wrap' }}>{detail.legalBasis || '—'}</div>
                    </div>
                    <div>
                      <Typography.Text type="secondary">Năng lực kỹ thuật</Typography.Text>
                      <div style={{ whiteSpace: 'pre-wrap' }}>{detail.techProfile || '—'}</div>
                    </div>
                    <div>
                      <Typography.Text type="secondary">Đầu mối liên hệ</Typography.Text>
                      <div>
                        {detail.contactName || '—'}
                        {detail.contactEmail ? ` · ${detail.contactEmail}` : ''}
                        {detail.contactPhone ? ` · ${detail.contactPhone}` : ''}
                      </div>
                    </div>
                    <div>
                      <Typography.Text type="secondary">Người nộp</Typography.Text>
                      <div>{detail.submittedBy || '—'}</div>
                    </div>
                    {detail.statusReason && (
                      <Alert type="info" message="Lý do trạng thái" description={detail.statusReason} />
                    )}
                  </Space>
                ),
              },
              {
                key: 'review',
                label: 'Thẩm định & duyệt',
                children: (
                  <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                    <ReviewCard title="Thẩm định pháp lý (FR-01-004)" review={detail.legalReview} />
                    <ReviewCard title="Thẩm định kỹ thuật (FR-01-005)" review={detail.techReview} />

                    {detail.submittedBy === username && (
                      <Alert
                        type="info"
                        showIcon
                        message="Bạn là người nộp hồ sơ này"
                        description="Luật bốn mắt: không tự thẩm định hoặc tự duyệt hồ sơ của mình."
                      />
                    )}

                    {canReview && detail.status === 'SUBMITTED' && detail.submittedBy !== username && (
                      <Space wrap>
                        <Button
                          onClick={() =>
                            void run(() => reviewLegal(detail.id, 'PASS'), 'Đã ghi thẩm định pháp lý')
                          }
                          disabled={Boolean(detail.legalReview?.status)}
                        >
                          Pháp lý: Đạt
                        </Button>
                        <Button
                          danger
                          onClick={() =>
                            askReason('Thẩm định pháp lý không đạt', async (r) => {
                              await run(() => reviewLegal(detail.id, 'FAIL', r), 'Đã ghi kết quả')
                            })
                          }
                          disabled={Boolean(detail.legalReview?.status)}
                        >
                          Pháp lý: Không đạt
                        </Button>
                        <Button
                          onClick={() =>
                            void run(
                              () => reviewTechnical(detail.id, 'PASS'),
                              'Đã ghi thẩm định kỹ thuật',
                            )
                          }
                          disabled={Boolean(detail.techReview?.status)}
                        >
                          Kỹ thuật: Đạt
                        </Button>
                        <Button
                          danger
                          onClick={() =>
                            askReason('Thẩm định kỹ thuật không đạt', async (r) => {
                              await run(() => reviewTechnical(detail.id, 'FAIL', r), 'Đã ghi kết quả')
                            })
                          }
                          disabled={Boolean(detail.techReview?.status)}
                        >
                          Kỹ thuật: Không đạt
                        </Button>
                      </Space>
                    )}

                    {canReview && detail.status === 'REVIEWED' && (
                      <Space wrap>
                        <Button
                          type="primary"
                          onClick={async () => {
                            const updated = await run(
                              () => approveApplication(detail.id),
                              'Đã duyệt và cấp danh tính',
                            )
                            if (updated?.clientSecretSealed) {
                              setSecret({
                                code: updated.systemCode,
                                value: updated.clientSecretSealed,
                              })
                            }
                          }}
                        >
                          Duyệt & cấp danh tính
                        </Button>
                        <Button
                          danger
                          onClick={() =>
                            askReason('Từ chối hồ sơ', async (r) => {
                              await run(() => rejectApplication(detail.id, r), 'Đã từ chối')
                            })
                          }
                        >
                          Từ chối
                        </Button>
                      </Space>
                    )}

                    {canAdmin && (
                      <Space wrap>
                        {detail.status === 'APPROVED' && (
                          <Button
                            type="primary"
                            onClick={() =>
                              void run(() => activateApplication(detail.id), 'Đã kích hoạt')
                            }
                          >
                            Kích hoạt
                          </Button>
                        )}
                        {detail.status === 'ACTIVE' && (
                          <Button
                            onClick={() =>
                              askReason('Tạm ngừng thành viên', async (r) => {
                                await run(() => suspendApplication(detail.id, r), 'Đã tạm ngừng')
                              })
                            }
                          >
                            Tạm ngừng
                          </Button>
                        )}
                        {detail.status === 'SUSPENDED' && (
                          <Button
                            onClick={() => void run(() => resumeApplication(detail.id), 'Đã khôi phục')}
                          >
                            Khôi phục
                          </Button>
                        )}
                        {['ACTIVE', 'SUSPENDED'].includes(detail.status) && (
                          <Button
                            onClick={() =>
                              askReason('Ghi nhận rà soát quyền định kỳ', async (r) => {
                                await run(
                                  () => recordAccessReview(detail.id, r),
                                  'Đã ghi nhận rà soát, hẹn lại sau 12 tháng',
                                )
                              })
                            }
                          >
                            Rà soát quyền
                          </Button>
                        )}
                        {canRevoke && ['APPROVED', 'ACTIVE', 'SUSPENDED'].includes(detail.status) && (
                          <Button
                            danger
                            onClick={() =>
                              askReason('Thu hồi kết nạp', async (r) => {
                                await run(() => revokeApplication(detail.id, r), 'Đã thu hồi')
                              })
                            }
                          >
                            Thu hồi
                          </Button>
                        )}
                      </Space>
                    )}
                  </Space>
                ),
              },
              {
                key: 'files',
                label: `Tệp đính kèm${files.length ? ` (${files.length})` : ''}`,
                children: (
                  <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                    {canDesign && ['SUBMITTED', 'REVIEWED'].includes(detail.status) && (
                      <Upload
                        accept={ACCEPT_TYPES}
                        showUploadList={false}
                        maxCount={1}
                        // Chặn tại chỗ để không gửi tệp quá cỡ lên máy chủ rồi mới bị từ chối.
                        beforeUpload={(file) => {
                          if (file.size > MAX_ATTACHMENT_BYTES) {
                            message.error('Tệp vượt 20 MB')
                            return Upload.LIST_IGNORE
                          }
                          setUploading(true)
                          uploadAttachment(detail.id, file)
                            .then(async () => {
                              message.success('Đã tải tệp lên')
                              await loadFiles(detail.id)
                              void loadAudit(detail.id)
                            })
                            .catch((e: unknown) =>
                              message.error(String(e instanceof Error ? e.message : e)),
                            )
                            .finally(() => setUploading(false))
                          return Upload.LIST_IGNORE
                        }}
                      >
                        <Button loading={uploading}>Tải tệp lên</Button>
                      </Upload>
                    )}
                    {!['SUBMITTED', 'REVIEWED'].includes(detail.status) && (
                      <Typography.Text type="secondary" className="t-small">
                        Hồ sơ đã chốt — không nhận thêm tệp để giữ nguyên bản đã duyệt.
                      </Typography.Text>
                    )}
                    {files.length ? (
                      <Table<Attachment>
                        rowKey="id"
                        size="small"
                        pagination={false}
                        dataSource={files}
                        columns={[
                          { title: 'Tên tệp', dataIndex: 'fileName' },
                          {
                            title: 'Cỡ',
                            dataIndex: 'sizeBytes',
                            width: 100,
                            render: (b: number) => humanSize(b),
                          },
                          { title: 'Người tải', dataIndex: 'uploadedBy', width: 140 },
                          {
                            title: '',
                            width: 90,
                            render: (_, f) => (
                              <Button
                                size="small"
                                onClick={() =>
                                  void downloadAttachment(detail.id, f).catch((e: unknown) =>
                                    message.error(String(e instanceof Error ? e.message : e)),
                                  )
                                }
                              >
                                Tải về
                              </Button>
                            ),
                          },
                        ]}
                      />
                    ) : (
                      <Empty description="Chưa có tệp đính kèm" />
                    )}
                  </Space>
                ),
              },
              {
                key: 'audit',
                label: 'Nhật ký',
                children: audit.length ? (
                  <Timeline
                    items={audit.map((a) => ({
                      children: (
                        <>
                          <strong>{ACTION_VI[a.action] ?? a.action}</strong>
                          <div className="t-small t-muted">
                            {a.actor} · {a.createdAt.slice(0, 19).replace('T', ' ')}
                            {a.fromStatus && a.toStatus ? ` · ${a.fromStatus} → ${a.toStatus}` : ''}
                          </div>
                          {a.note && <div className="t-small">{a.note}</div>}
                        </>
                      ),
                    }))}
                  />
                ) : (
                  <Empty description="Chưa có nhật ký, hoặc bạn không có quyền đọc." />
                ),
              },
            ]}
          />
        )}
      </Drawer>

      {/* ---------- Biểu mẫu nộp hồ sơ nhiều bước ---------- */}
      <Modal
        open={formOpen}
        title="Nộp hồ sơ kết nạp"
        onCancel={() => setFormOpen(false)}
        width={640}
        footer={
          <Space>
            {step > 0 && <Button onClick={() => setStep((s) => s - 1)}>Quay lại</Button>}
            {step < STEPS.length - 1 && (
              <Button type="primary" onClick={() => void nextStep()}>
                Tiếp
              </Button>
            )}
            {step === STEPS.length - 1 && (
              <Button
                type="primary"
                onClick={async () => {
                  try {
                    const v = await form.validateFields()
                    await submitApplication(v)
                    message.success('Đã nộp hồ sơ')
                    setFormOpen(false)
                    setPage(0)
                    await refresh()
                  } catch (e) {
                    if (e instanceof Error) message.error(e.message)
                  }
                }}
              >
                Nộp hồ sơ
              </Button>
            )}
          </Space>
        }
      >
        <Steps
          size="small"
          current={step}
          items={STEPS.map((s) => ({ title: s.title }))}
          style={{ marginBottom: 24 }}
        />
        {/* Giữ nguyên tất cả trường trong DOM để chuyển bước không mất dữ liệu đã gõ. */}
        <Form form={form} layout="vertical" preserve>
          <div hidden={step !== 0}>
            <Form.Item
              name="systemCode"
              label="Mã hệ thống"
              rules={[
                { required: true, message: 'Bắt buộc' },
                {
                  pattern: /^[A-Z][A-Z0-9_]{2,63}$/,
                  message: 'Viết hoa, dùng chữ số và gạch dưới, 3–64 ký tự',
                },
              ]}
            >
              <Input placeholder="HE_THONG_MOT_CUA" />
            </Form.Item>
            <Form.Item name="systemName" label="Tên hệ thống" rules={[{ required: true, message: 'Bắt buộc' }]}>
              <Input />
            </Form.Item>
            <Form.Item name="ownerOrg" label="Đơn vị chủ quản" rules={[{ required: true, message: 'Bắt buộc' }]}>
              <Input />
            </Form.Item>
          </div>

          <div hidden={step !== 1}>
            <Form.Item
              name="legalBasis"
              label="Căn cứ pháp lý"
              tooltip="Quyết định, văn bản giao nhiệm vụ — cơ sở để thẩm định pháp lý"
              rules={[{ required: true, message: 'Phải nêu căn cứ pháp lý' }]}
            >
              <Input.TextArea rows={3} placeholder="Quyết định số …/QĐ-UBND ngày …" />
            </Form.Item>
            <Form.Item
              name="techProfile"
              label="Hồ sơ năng lực kỹ thuật"
              rules={[{ required: true, message: 'Phải khai năng lực kỹ thuật' }]}
            >
              <Input.TextArea rows={4} placeholder="Hạ tầng, giao thức, chứng thư số, phương án kết nối…" />
            </Form.Item>
          </div>

          <div hidden={step !== 2}>
            <Form.Item name="contactName" label="Cán bộ đầu mối" rules={[{ required: true, message: 'Bắt buộc' }]}>
              <Input />
            </Form.Item>
            <Form.Item
              name="contactEmail"
              label="Thư điện tử"
              rules={[
                { required: true, message: 'Bắt buộc' },
                { type: 'email', message: 'Địa chỉ thư không hợp lệ' },
              ]}
            >
              <Input placeholder="can.bo@example.gov.vn" />
            </Form.Item>
            <Form.Item name="contactPhone" label="Điện thoại">
              <Input />
            </Form.Item>
          </div>
        </Form>
      </Modal>
    </div>
  )
}
