/**
 * Suy ra **điểm chạy thật** của một luồng từ định nghĩa YAML (góp ý người dùng 08/2026):
 * màn chạy thử trước đây không cho biết luồng đang phơi ở URL/cổng nào, cũng không có
 * cách gọi thử thật — người vận hành phải tự mò log runtime.
 *
 * Tệp này **thuần logic** (đọc YAML, dựng URL, dựng lệnh curl) để test được không cần React.
 */

import { parseDocument } from 'yaml'

/**
 * Base URL runtime theo `targetSystem` — compose DEV (Makefile run-camel / run-camel-datdai).
 *
 * Khi có đăng ký runtime chính thức ở lgsp-control thì thay bảng tĩnh này bằng API;
 * hiện control chưa giữ thông tin đó nên khai ở đây là nguồn duy nhất.
 */
export const RUNTIME_BASES: Record<string, string> = {
  'camel-dancu': 'http://localhost:8088',
  'camel-datdai': 'http://localhost:8087',
}

export interface HttpEntry {
  /** Scheme của chặng tiếp nhận: `platform-http` | `rest` | khác. */
  scheme: string
  /** Đường dẫn HTTP (`/demo/cong-dan`) — rỗng khi chặng tiếp nhận không phải HTTP. */
  path: string
  /** Phương thức đầu tiên trong `httpMethodRestrict`, mặc định GET. */
  method: string
  /** URI gốc để hiện nguyên văn khi không phải HTTP. */
  uri: string
}

/** Đọc `from.uri` của route đầu tiên trong định nghĩa; null khi YAML không đọc được. */
export function readFromUri(definitionYaml: string): string | null {
  try {
    const doc = parseDocument(definitionYaml)
    const root = doc.toJS() as unknown
    if (!Array.isArray(root)) return null
    for (const entry of root) {
      const route = (entry as Record<string, unknown>)?.route as Record<string, unknown> | undefined
      const from = route?.from as Record<string, unknown> | undefined
      const uri = from?.uri
      if (typeof uri === 'string') return uri
    }
    return null
  } catch {
    return null
  }
}

/** Tách URI chặng tiếp nhận thành đường dẫn + phương thức HTTP. */
export function parseHttpEntry(uri: string): HttpEntry {
  const scheme = uri.split(':')[0] ?? ''
  if (scheme !== 'platform-http' && scheme !== 'rest') {
    return { scheme, path: '', method: 'GET', uri }
  }
  if (scheme === 'rest') {
    // `rest:get:/api/v1/tai-nguyen` — phần tử 2 là method, 3 là path.
    const [, method = 'get', path = ''] = uri.split(':')
    return { scheme, path: path.split('?')[0], method: method.toUpperCase(), uri }
  }
  const rest = uri.slice('platform-http:'.length)
  const [path, query = ''] = rest.split('?')
  const m = /(?:^|&)httpMethodRestrict=([^&]+)/.exec(query)
  const method = m ? m[1].split(',')[0].toUpperCase() : 'GET'
  return { scheme, path, method, uri }
}

/**
 * Tham số đặt tên `:#ten` trong các bước SQL — gợi ý query param cho lệnh gọi thử.
 *
 * `:#tinh` thiếu header là camel-sql ném lỗi 500, nên phải mồi sẵn `tinh=` vào lệnh
 * curl mẫu; người dùng gặp 500 vì thiếu param là lỗi khó lần nhất ở luồng SQL.
 */
export function extractSqlParams(definitionYaml: string): string[] {
  const out = new Set<string>()
  for (const m of definitionYaml.matchAll(/:#([A-Za-z_][A-Za-z0-9_]*)/g)) out.add(m[1])
  return [...out]
}

/** Điểm chạy đầy đủ; null khi thiếu base runtime hoặc chặng tiếp nhận không phải HTTP. */
export function endpointUrl(targetSystem: string | null | undefined, entry: HttpEntry): string | null {
  const base = targetSystem ? RUNTIME_BASES[targetSystem] : undefined
  if (!base || !entry.path) return null
  return base + entry.path
}

/**
 * Dựng lệnh curl dán-chạy-được, kiểu «Copy as cURL» của trình duyệt.
 *
 * Query param mồi bằng `--data-urlencode` để giá trị tiếng Việt (`Đà Nẵng`) không phải
 * tự mã hóa tay; GET dùng `--get` nên cùng cú pháp dùng được cho cả hai chiều.
 */
export function buildCurl(url: string, method: string, params: string[], sampleBody?: string): string {
  const lines: string[] = ['curl -s']
  if (method === 'GET') {
    lines.push('--get')
  } else {
    lines.push(`-X ${method}`)
    lines.push(`-H 'Content-Type: application/json'`)
    if (sampleBody) lines.push(`-d '${sampleBody.replace(/'/g, `'\\''`)}'`)
  }
  for (const p of params) lines.push(`--data-urlencode '${p}='`)
  lines.push(`'${url}'`)
  return lines.join(' \\\n  ')
}

/**
 * Đường dẫn gọi LIVE qua proxy Vite (`/runtime/<hệ đích>/...`) — trình duyệt không gọi
 * thẳng cổng runtime được vì CORS; curl thì không vướng nên hiện URL thật.
 */
export function liveProxyPath(targetSystem: string, entry: HttpEntry, query: string): string {
  const q = query ? (query.startsWith('?') ? query : `?${query}`) : ''
  return `/runtime/${targetSystem}${entry.path}${q}`
}
