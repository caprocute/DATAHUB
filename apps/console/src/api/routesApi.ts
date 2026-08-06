import { apiAdminDelete, apiAdminGet, apiAdminPost, apiAdminPut } from './client'

export type RouteSummary = {
  routeId: string
  routeCode: string
  title: string
  routeType: string
  /**
   * Loại tài nguyên Camel: `ROUTE` | `KAMELET` | `PIPE` | `TEST` (IP-07 K2-5).
   *
   * Khác `routeType` — cột đó nói cách vận chuyển (`SYNC`/`ASYNC`), cột này nói loại tệp.
   */
  resourceKind?: string
  status: string
  sourceSystem: string
  targetSystem?: string | null
  currentVersionId?: string | null
  draftVersionNo?: number | null
  currentVersionNo?: number | null
  gitCommitRef?: string | null
  updatedBy?: string | null
  updatedAt?: string | null
}

/** Một lần chạy thử đã ghi ở máy chủ (FR-D-040). */
export type TestRunSummary = {
  runId: string
  routeCode: string
  versionNo: number
  mode: string
  outcome: string
  durationMs: number
  traceId?: string | null
  runBy: string
  runAt: string
  stageCount: number
}

export type TestRunDetail = {
  run: TestRunSummary
  stages: {
    seqNo: number
    stage: string
    status: string
    durationMs: number
    offsetMs: number
    errorText?: string | null
  }[]
}

export type TestRunResult = {
  routeCode: string
  versionNo: number
  mode: string
  outcome: string
  durationMs: number
  waterfall: { stage: string; status: string; durationMs: number; offsetMs: number }[]
}

export type RouteVersion = {
  versionId: string
  routeId: string
  routeCode: string
  versionNo: number
  status: string
  definitionYaml: string
  gitCommitRef?: string | null
  gitPath?: string | null
  source: string
  createdBy?: string | null
}

export type ValidationResult = {
  valid: boolean
  findings: { code: string; message: string; severity: string }[]
}

export async function listRoutes() {
  return apiAdminGet<{ items: RouteSummary[] }>('/routes')
}

/** Điều kiện lọc gửi lên máy chủ (FR-D-001). */
export type RouteQuery = {
  q?: string
  status?: string
  sort?: string
  desc?: boolean
  page?: number
  size?: number
}

/**
 * Danh sách luồng lọc/phân trang **phía máy chủ**.
 *
 * Bỏ tham số rỗng thay vì gửi `q=`: máy chủ coi chuỗi rỗng là không lọc, nhưng gửi
 * tham số thừa làm URL khó đọc khi soi nhật ký.
 */
export async function searchRoutes(query: RouteQuery = {}) {
  const p = new URLSearchParams()
  if (query.q?.trim()) p.set('q', query.q.trim())
  if (query.status) p.set('status', query.status)
  if (query.sort) p.set('sort', query.sort)
  if (query.desc !== undefined) p.set('desc', String(query.desc))
  p.set('page', String(query.page ?? 0))
  p.set('size', String(query.size ?? 20))
  return apiAdminGet<{ items: RouteSummary[]; total: number; page: number; size: number }>(
    `/routes?${p.toString()}`,
  )
}

export async function listVersions(routeCode: string) {
  return apiAdminGet<{ items: RouteVersion[] }>(`/routes/${routeCode}/versions`)
}

export async function renameRoute(routeCode: string, title: string) {
  return apiAdminPut<RouteSummary>(`/routes/${routeCode}/title`, { title })
}

export async function duplicateRoute(routeCode: string, body: { routeCode: string; title: string }) {
  return apiAdminPost<RouteSummary>(`/routes/${routeCode}/duplicate`, body)
}

export async function setRoutePaused(routeCode: string, paused: boolean) {
  return apiAdminPost<RouteSummary>(`/routes/${routeCode}/paused?value=${paused}`)
}

export async function deleteDraftVersion(routeCode: string, versionNo: number) {
  return apiAdminDelete(`/routes/${routeCode}/versions/${versionNo}`)
}

/* ---------- Nhật ký chạy thử ---------- */

export async function listTestRuns(routeCode: string, outcome?: string, limit = 50) {
  const p = new URLSearchParams()
  if (outcome) p.set('outcome', outcome)
  p.set('limit', String(limit))
  return apiAdminGet<{ items: TestRunSummary[] }>(`/routes/${routeCode}/test-runs?${p.toString()}`)
}

export async function getTestRun(routeCode: string, runId: string) {
  return apiAdminGet<TestRunDetail>(`/routes/${routeCode}/test-runs/${runId}`)
}

export async function createRoute(body: {
  routeCode: string
  title: string
  sourceSystem: string
  targetSystem?: string
  definitionYaml: string
  routeType?: string
  /** Loại tài nguyên Camel: `ROUTE` | `KAMELET` | `PIPE` | `TEST` (IP-07 K2-5). */
  resourceKind?: string
}) {
  return apiAdminPost<RouteSummary>('/routes', body)
}

export async function saveDefinition(routeCode: string, versionNo: number, definitionYaml: string) {
  return apiAdminPut<RouteVersion>(`/routes/${routeCode}/versions/${versionNo}/definition`, {
    definitionYaml,
  })
}

export async function validateYaml(definitionYaml: string) {
  return apiAdminPost<ValidationResult>('/routes/validate', { definitionYaml })
}

export async function submitVersion(routeCode: string, versionNo: number) {
  return apiAdminPost<RouteVersion>(`/routes/${routeCode}/versions/${versionNo}/submit`)
}

export async function getRoute(routeCode: string) {
  return apiAdminGet<RouteSummary>(`/routes/${routeCode}`)
}

export async function getVersion(routeCode: string, versionNo: number) {
  return apiAdminGet<RouteVersion>(`/routes/${routeCode}/versions/${versionNo}`)
}

export async function listPendingReview() {
  return apiAdminGet<{ items: RouteVersion[] }>('/routes/pending-review')
}

export async function reviewVersion(
  routeCode: string,
  versionNo: number,
  decision: 'APPROVE' | 'REJECT',
  comment?: string,
) {
  return apiAdminPost<RouteVersion>(`/routes/${routeCode}/versions/${versionNo}/review`, {
    decision,
    comment,
  })
}

export async function runTest(routeCode: string, versionNo: number, mode = 'MOCK') {
  return apiAdminPost<TestRunResult>(`/routes/${routeCode}/versions/${versionNo}/test-runs`, {
    mode,
    sample: { ping: true },
  })
}
