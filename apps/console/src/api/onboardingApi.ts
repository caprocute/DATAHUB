import { apiGet, apiPost } from './client'

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
