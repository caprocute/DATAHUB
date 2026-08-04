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
