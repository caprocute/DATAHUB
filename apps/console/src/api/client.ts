import { userManager } from '../auth/oidc'

const API_BASE = import.meta.env.VITE_API_BASE ?? '/api/v1'
const API_ADMIN_BASE = import.meta.env.VITE_API_ADMIN_BASE ?? '/api/admin/v1'

async function authHeaders(): Promise<HeadersInit> {
  const user = await userManager.getUser()
  if (!user?.access_token) throw new Error('Chưa đăng nhập')
  return {
    Authorization: `Bearer ${user.access_token}`,
    'Content-Type': 'application/json',
  }
}

async function parseError(res: Response): Promise<string> {
  const text = await res.text()
  try {
    const j = JSON.parse(text) as { title?: string; findings?: { message: string }[] }
    if (j.findings?.length) {
      return `${j.title ?? 'Lỗi'}: ${j.findings.map((f) => f.message).join('; ')}`
    }
    if (j.title) return j.title
  } catch {
    /* plain text */
  }
  return text || res.statusText
}

export async function apiGet<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, { headers: await authHeaders() })
  if (!res.ok) throw new Error(await parseError(res))
  return res.json() as Promise<T>
}

export async function apiPost<T>(path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: 'POST',
    headers: await authHeaders(),
    body: body === undefined ? undefined : JSON.stringify(body),
  })
  if (!res.ok) throw new Error(await parseError(res))
  return res.json() as Promise<T>
}

export async function apiAdminGet<T>(path: string): Promise<T> {
  const res = await fetch(`${API_ADMIN_BASE}${path}`, { headers: await authHeaders() })
  if (!res.ok) throw new Error(await parseError(res))
  return res.json() as Promise<T>
}

export async function apiAdminPost<T>(path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${API_ADMIN_BASE}${path}`, {
    method: 'POST',
    headers: await authHeaders(),
    body: body === undefined ? undefined : JSON.stringify(body),
  })
  if (!res.ok) throw new Error(await parseError(res))
  return res.json() as Promise<T>
}

export async function apiAdminPut<T>(path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${API_ADMIN_BASE}${path}`, {
    method: 'PUT',
    headers: await authHeaders(),
    body: body === undefined ? undefined : JSON.stringify(body),
  })
  if (!res.ok) throw new Error(await parseError(res))
  return res.json() as Promise<T>
}
