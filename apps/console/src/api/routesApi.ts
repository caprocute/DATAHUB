import { apiAdminGet, apiAdminPost, apiAdminPut } from './client'

export type RouteSummary = {
  routeId: string
  routeCode: string
  title: string
  routeType: string
  status: string
  sourceSystem: string
  targetSystem?: string | null
  currentVersionId?: string | null
  draftVersionNo?: number | null
  currentVersionNo?: number | null
  gitCommitRef?: string | null
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

export async function createRoute(body: {
  routeCode: string
  title: string
  sourceSystem: string
  targetSystem?: string
  definitionYaml: string
  routeType?: string
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
