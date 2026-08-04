import { apiGet, apiPost } from './client'
import { userManager } from '../auth/oidc'

/** Trạng thái hồ sơ theo máy trạng thái của PH-01. */
export type ApplicationStatus =
  | 'SUBMITTED'
  | 'REVIEWED'
  | 'APPROVED'
  | 'ACTIVE'
  | 'SUSPENDED'
  | 'REJECTED'
  | 'REVOKED'

export type Review = {
  status: 'PASS' | 'FAIL' | null
  reviewedBy: string | null
  note: string | null
  reviewedAt: string | null
}

export type Application = {
  id: string
  systemCode: string
  systemName: string
  ownerOrg: string
  status: ApplicationStatus
  clientId: string | null
  /** Chỉ có giá trị ngay sau lần duyệt; mọi lối đọc khác là `null` (FR-01-009). */
  clientSecretSealed: string | null
  legalBasis: string | null
  techProfile: string | null
  contactName: string | null
  contactEmail: string | null
  contactPhone: string | null
  submittedBy: string | null
  approvedBy: string | null
  statusReason: string | null
  legalReview: Review | null
  techReview: Review | null
  createdAt: string | null
  updatedAt: string | null
}

export type AuditEntry = {
  id: string
  action: string
  fromStatus: string | null
  toStatus: string | null
  actor: string
  note: string | null
  createdAt: string
}

export type Page<T> = { items: T[]; page: number; size: number; total: number }

export type SubmitBody = {
  systemCode: string
  systemName: string
  ownerOrg: string
  legalBasis: string
  techProfile: string
  contactName: string
  contactEmail: string
  contactPhone?: string
}

/** Nhãn tiếng Việt của trạng thái — dùng chung cho bảng và thẻ chi tiết. */
export const STATUS_VI: Record<ApplicationStatus, string> = {
  SUBMITTED: 'Chờ thẩm định',
  REVIEWED: 'Đã thẩm định',
  APPROVED: 'Đã duyệt',
  ACTIVE: 'Đang hoạt động',
  SUSPENDED: 'Tạm ngừng',
  REJECTED: 'Từ chối',
  REVOKED: 'Đã thu hồi',
}

export const STATUS_COLOR: Record<ApplicationStatus, string> = {
  SUBMITTED: 'default',
  REVIEWED: 'blue',
  APPROVED: 'cyan',
  ACTIVE: 'green',
  SUSPENDED: 'orange',
  REJECTED: 'red',
  REVOKED: 'red',
}

/** Nhãn hành vi trong nhật ký kiểm toán. */
export const ACTION_VI: Record<string, string> = {
  SUBMIT: 'Nộp hồ sơ',
  REVIEW_LEGAL: 'Thẩm định pháp lý',
  REVIEW_TECH: 'Thẩm định kỹ thuật',
  REVIEWED: 'Hoàn tất thẩm định',
  APPROVE: 'Phê duyệt',
  REJECT: 'Từ chối',
  ACTIVATE: 'Kích hoạt',
  SUSPEND: 'Tạm ngừng',
  RESUME: 'Khôi phục',
  REVOKE: 'Thu hồi',
  ATTACH: 'Đính kèm tệp',
  ACCESS_REVIEW: 'Rà soát quyền định kỳ',
}

export async function searchApplications(params: {
  q?: string
  status?: string
  page?: number
  size?: number
}) {
  const qs = new URLSearchParams()
  if (params.q) qs.set('q', params.q)
  if (params.status) qs.set('status', params.status)
  qs.set('page', String(params.page ?? 0))
  qs.set('size', String(params.size ?? 20))
  return apiGet<Page<Application>>(`/onboarding/applications?${qs}`)
}

export async function getApplication(id: string) {
  return apiGet<Application>(`/onboarding/applications/${id}`)
}

export async function getAudit(id: string) {
  return apiGet<{ items: AuditEntry[] }>(`/onboarding/applications/${id}/audit`)
}

export async function submitApplication(body: SubmitBody) {
  return apiPost<Application>('/onboarding/applications', body)
}

export async function reviewLegal(id: string, decision: 'PASS' | 'FAIL', note?: string) {
  return apiPost<Application>(`/onboarding/applications/${id}/review/legal`, { decision, note })
}

export async function reviewTechnical(id: string, decision: 'PASS' | 'FAIL', note?: string) {
  return apiPost<Application>(`/onboarding/applications/${id}/review/technical`, { decision, note })
}

export async function approveApplication(id: string) {
  return apiPost<Application>(`/onboarding/applications/${id}/approve`)
}

export async function rejectApplication(id: string, reason: string) {
  return apiPost<Application>(`/onboarding/applications/${id}/reject`, { reason })
}

export async function activateApplication(id: string) {
  return apiPost<Application>(`/onboarding/applications/${id}/activate`)
}

export async function suspendApplication(id: string, reason: string) {
  return apiPost<Application>(`/onboarding/applications/${id}/suspend`, { reason })
}

export async function resumeApplication(id: string) {
  return apiPost<Application>(`/onboarding/applications/${id}/resume`)
}

export async function revokeApplication(id: string, reason: string) {
  return apiPost<Application>(`/onboarding/applications/${id}/revoke`, { reason })
}

/* ---------- Tệp đính kèm (FR-01-003) ---------- */

export type Attachment = {
  id: string
  fileName: string
  contentType: string
  sizeBytes: number
  sha256: string
  uploadedBy: string
  createdAt: string
}

/** Định dạng máy chủ nhận — dùng cho thuộc tính `accept` của ô chọn tệp. */
export const ACCEPT_TYPES =
  '.pdf,.png,.jpg,.jpeg,.doc,.docx,.xls,.xlsx,application/pdf,image/png,image/jpeg'

export const MAX_ATTACHMENT_BYTES = 20 * 1024 * 1024

async function bearer(): Promise<string> {
  const user = await userManager.getUser()
  if (!user?.access_token) throw new Error('Chưa đăng nhập')
  return `Bearer ${user.access_token}`
}

export async function listAttachments(id: string) {
  return apiGet<{ items: Attachment[] }>(`/onboarding/applications/${id}/attachments`)
}

/** Tải tệp lên bằng multipart — không dùng `apiPost` vì phải để trình duyệt tự đặt boundary. */
export async function uploadAttachment(id: string, file: File): Promise<Attachment> {
  const body = new FormData()
  body.append('file', file)
  const res = await fetch(`/api/v1/onboarding/applications/${id}/attachments`, {
    method: 'POST',
    headers: { Authorization: await bearer() },
    body,
  })
  if (!res.ok) {
    const text = await res.text()
    try {
      const j = JSON.parse(text) as { error?: string }
      throw new Error(j.error ?? text)
    } catch (e) {
      throw e instanceof Error ? e : new Error(text)
    }
  }
  return (await res.json()) as Attachment
}

/** Tải tệp về qua blob để giữ được header Authorization. */
export async function downloadAttachment(id: string, att: Attachment) {
  const res = await fetch(`/api/v1/onboarding/applications/${id}/attachments/${att.id}`, {
    headers: { Authorization: await bearer() },
  })
  if (!res.ok) throw new Error('Không tải được tệp')
  saveBlob(await res.blob(), att.fileName)
}

/* ---------- Rà soát quyền định kỳ (FR-01-013) ---------- */

export async function listDueAccessReview() {
  return apiGet<{ items: Application[] }>('/onboarding/applications/due-access-review')
}

export async function recordAccessReview(id: string, note: string, nextInMonths = 12) {
  return apiPost<Application>(`/onboarding/applications/${id}/access-review`, {
    note,
    nextInMonths,
  })
}

/* ---------- Xuất danh sách (C4-3) ---------- */

export async function exportApplications(params: { q?: string; status?: string }) {
  const qs = new URLSearchParams()
  if (params.q) qs.set('q', params.q)
  if (params.status) qs.set('status', params.status)
  const res = await fetch(`/api/v1/onboarding/applications/export?${qs}`, {
    headers: { Authorization: await bearer() },
  })
  if (!res.ok) throw new Error('Không xuất được danh sách')
  saveBlob(await res.blob(), 'ho-so-ket-nap.csv')
}

/** Kích hoạt tải tệp về máy từ một blob đã nhận. */
function saveBlob(blob: Blob, fileName: string) {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = fileName
  a.click()
  URL.revokeObjectURL(url)
}

/** Cỡ tệp cho người đọc. */
export function humanSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}
