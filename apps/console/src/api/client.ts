import { userManager } from '../auth/oidc'

const API_BASE = import.meta.env.VITE_API_BASE ?? '/api/v1'

async function authHeaders(): Promise<HeadersInit> {
  const user = await userManager.getUser()
  if (!user?.access_token) throw new Error('Chưa đăng nhập')
  return {
    Authorization: `Bearer ${user.access_token}`,
    'Content-Type': 'application/json',
  }
}

export async function apiGet<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, { headers: await authHeaders() })
  if (!res.ok) throw new Error(await res.text())
  return res.json() as Promise<T>
}

export async function apiPost<T>(path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: 'POST',
    headers: await authHeaders(),
    body: body === undefined ? undefined : JSON.stringify(body),
  })
  if (!res.ok) throw new Error(await res.text())
  return res.json() as Promise<T>
}
