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
    const j = JSON.parse(text) as {
      title?: string
      error?: string
      message?: string
      findings?: { message: string }[]
    }
    if (j.findings?.length) {
      return `${j.title ?? 'Lỗi'}: ${j.findings.map((f) => f.message).join('; ')}`
    }
    // Lỗi nghiệp vụ của control trả `{"error": "..."}`; dùng nguyên văn cho người dùng đọc.
    if (j.error) return j.error
    if (j.title) return j.title
    if (j.message) return j.message
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

/**
 * Gọi DELETE.
 *
 * Không trả dữ liệu: máy chủ đáp 204 không thân, gọi `res.json()` sẽ ném lỗi phân tích
 * ngay cả khi xóa đã thành công.
 */
export async function apiAdminDelete(path: string): Promise<void> {
  const res = await fetch(`${API_ADMIN_BASE}${path}`, {
    method: 'DELETE',
    headers: await authHeaders(),
  })
  if (!res.ok) throw new Error(await parseError(res))
}
