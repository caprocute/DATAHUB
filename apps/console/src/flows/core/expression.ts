/**
 * Xem trước biểu thức trên bản tin mẫu (FR-04-031).
 *
 * Camel thật diễn giải biểu thức ở phía máy chủ. Trình thiết kế chỉ cần xem trước
 * nhanh khi đang gõ, nên tệp này hiện thực **tập con** của Camel Simple và JSONPath —
 * đủ cho các dạng dùng trong luồng LGSP, và **nói rõ khi gặp cú pháp chưa hỗ trợ**
 * thay vì đoán bừa kết quả.
 *
 * Không hỗ trợ: gọi phương thức Java (`${body.getFoo()}`), hàm ngày giờ, số học phức tạp.
 */

export type ExprLang = 'simple' | 'jsonpath' | 'constant';

export interface EvalContext {
  /** Thân bản tin mẫu đã phân tích. Chuỗi không phải JSON thì giữ nguyên dạng chuỗi. */
  body: unknown;
  headers?: Record<string, unknown>;
  properties?: Record<string, unknown>;
  /** Biến môi trường theo DEV/UAT/PROD (FR-04-036). */
  env?: Record<string, string>;
}

export type EvalResult =
  | { ok: true; value: unknown; rendered: string }
  | { ok: false; error: string; at?: number };

/** Đoán ngôn ngữ biểu thức từ hình dạng chuỗi. */
export function detectLang(expr: string): ExprLang {
  const s = expr.trim();
  if (s.startsWith('$.') || s.startsWith('$[')) return 'jsonpath';
  if (s.includes('${')) return 'simple';
  return 'constant';
}

/** Đi theo đường dẫn `a.b[0].c` trên dữ liệu đã phân tích. */
function walk(root: unknown, path: string): { found: boolean; value: unknown } {
  if (path === '') return { found: true, value: root };
  let cur: unknown = root;
  // Tách theo dấu chấm và chỉ số mảng, bỏ phần rỗng do `[0]` sinh ra.
  const parts = path.split(/[.[\]]/).filter(Boolean);
  for (const p of parts) {
    if (cur === null || cur === undefined) return { found: false, value: undefined };
    if (Array.isArray(cur)) {
      const i = Number(p);
      if (!Number.isInteger(i) || i < 0 || i >= cur.length) return { found: false, value: undefined };
      cur = cur[i];
      continue;
    }
    if (typeof cur !== 'object') return { found: false, value: undefined };
    const obj = cur as Record<string, unknown>;
    if (!(p in obj)) return { found: false, value: undefined };
    cur = obj[p];
  }
  return { found: true, value: cur };
}

function render(v: unknown): string {
  if (v === undefined) return '';
  if (v === null) return 'null';
  if (typeof v === 'string') return v;
  if (typeof v === 'object') return JSON.stringify(v);
  return String(v);
}

/** Giải một token bên trong `${…}` của Camel Simple. */
function resolveToken(token: string, ctx: EvalContext): { ok: true; value: unknown } | { ok: false; error: string } {
  const t = token.trim();

  const header = /^(?:header|headers)\.(.+)$/.exec(t) ?? /^(?:header|headers)\[['"]?(.+?)['"]?\]$/.exec(t);
  if (header) {
    const key = header[1];
    const found = ctx.headers && key in ctx.headers;
    if (!found) return { ok: false, error: `Không có tiêu đề “${key}” trong bản tin mẫu` };
    return { ok: true, value: ctx.headers![key] };
  }

  const prop = /^(?:exchangeProperty|property)\.(.+)$/.exec(t);
  if (prop) {
    const key = prop[1];
    if (!ctx.properties || !(key in ctx.properties))
      return { ok: false, error: `Không có thuộc tính trao đổi “${key}”` };
    return { ok: true, value: ctx.properties[key] };
  }

  const env = /^env[.:](.+)$/.exec(t);
  if (env) {
    const key = env[1];
    if (!ctx.env || !(key in ctx.env)) return { ok: false, error: `Chưa khai báo biến môi trường “${key}”` };
    return { ok: true, value: ctx.env[key] };
  }

  if (t === 'body') return { ok: true, value: ctx.body };

  const body = /^body\.(.+)$/.exec(t) ?? /^body\[(.+)\]$/.exec(t);
  if (body) {
    const r = walk(ctx.body, body[1]);
    if (!r.found) return { ok: false, error: `Bản tin mẫu không có trường “${body[1]}”` };
    return { ok: true, value: r.value };
  }

  if (/^(date|bean|random|uuid)[:(]/.test(t))
    return { ok: false, error: `Xem trước chưa hỗ trợ “${t.split(/[:(]/)[0]}” — máy chủ vẫn chạy được` };

  return { ok: false, error: `Chưa hiểu token “${t}”` };
}

/** Chạy thử một biểu thức trên ngữ cảnh mẫu. */
export function evaluate(expr: string, ctx: EvalContext, lang: ExprLang = detectLang(expr)): EvalResult {
  const s = expr ?? '';
  if (!s.trim()) return { ok: false, error: 'Biểu thức đang để trống' };

  if (lang === 'constant') return { ok: true, value: s, rendered: s };

  if (lang === 'jsonpath') {
    const m = /^\$\.?(.*)$/.exec(s.trim());
    if (!m) return { ok: false, error: 'JSONPath phải bắt đầu bằng “$”' };
    if (/[*?@]/.test(s)) return { ok: false, error: 'Xem trước chưa hỗ trợ bộ lọc / ký tự đại diện' };
    const r = walk(ctx.body, m[1]);
    if (!r.found) return { ok: false, error: `Bản tin mẫu không có đường dẫn “${s.trim()}”` };
    return { ok: true, value: r.value, rendered: render(r.value) };
  }

  // Camel Simple: thay từng `${…}`, phần ngoài giữ nguyên.
  let out = '';
  let i = 0;
  let last: unknown = undefined;
  let count = 0;

  while (i < s.length) {
    const open = s.indexOf('${', i);
    if (open === -1) {
      out += s.slice(i);
      break;
    }
    const close = s.indexOf('}', open);
    if (close === -1) return { ok: false, error: 'Thiếu dấu “}” đóng token', at: open };
    out += s.slice(i, open);
    const res = resolveToken(s.slice(open + 2, close), ctx);
    if (!res.ok) return { ok: false, error: res.error, at: open };
    out += render(res.value);
    last = res.value;
    count += 1;
    i = close + 1;
  }

  // Biểu thức chỉ gồm đúng một token thì giữ nguyên kiểu gốc (số, đối tượng…).
  const only = count === 1 && s.trim().startsWith('${') && s.trim().endsWith('}');
  return { ok: true, value: only ? last : out, rendered: out };
}

/** Phân tích bản tin mẫu thành ngữ cảnh chạy thử. */
export function contextFromSample(sample: string | undefined, env?: Record<string, string>): EvalContext {
  if (!sample?.trim()) return { body: undefined, headers: {}, properties: {}, env };
  try {
    const parsed = JSON.parse(sample) as unknown;
    // Mẫu có thể là bản tin trần, hoặc gói kèm headers do lần chạy thử trước trả về.
    if (parsed && typeof parsed === 'object' && 'body' in (parsed as Record<string, unknown>)) {
      const p = parsed as { body?: unknown; headers?: Record<string, unknown> };
      return { body: p.body, headers: p.headers ?? {}, properties: {}, env };
    }
    const headers =
      parsed && typeof parsed === 'object' ? (parsed as Record<string, unknown>) : {};
    return { body: parsed, headers, properties: {}, env };
  } catch {
    // Không phải JSON (ví dụ XML) — vẫn dùng được với biểu thức hằng.
    return { body: sample, headers: {}, properties: {}, env };
  }
}

/** Gợi ý token khi gõ — dựng từ chính bản tin mẫu, không phải danh sách cứng. */
export function suggestTokens(ctx: EvalContext): { token: string; hint: string }[] {
  const out: { token: string; hint: string }[] = [{ token: '${body}', hint: 'toàn bộ thân bản tin' }];
  const push = (token: string, v: unknown) => out.push({ token, hint: render(v).slice(0, 40) });

  if (ctx.body && typeof ctx.body === 'object' && !Array.isArray(ctx.body)) {
    for (const [k, v] of Object.entries(ctx.body as Record<string, unknown>)) {
      push(`\${body.${k}}`, v);
      if (v && typeof v === 'object' && !Array.isArray(v)) {
        for (const [k2, v2] of Object.entries(v as Record<string, unknown>)) push(`\${body.${k}.${k2}}`, v2);
      }
    }
  }
  for (const [k, v] of Object.entries(ctx.headers ?? {})) push(`\${header.${k}}`, v);
  for (const [k, v] of Object.entries(ctx.env ?? {})) push(`\${env.${k}}`, v);
  return out.slice(0, 40);
}
