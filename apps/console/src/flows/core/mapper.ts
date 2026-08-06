/**
 * Ánh xạ trường nguồn → đích (K6 — IP-07 · FR-D-083…085).
 *
 * ## Vì sao sinh JQ chứ không phải AtlasMap
 *
 * Q4 chốt "UI tự viết + engine AtlasMap ở `apps/control`". Khảo sát mã thật cho thấy hai
 * điều làm lệch quyết định đó:
 *
 *  1. **Dự án đã có cơ chế ánh xạ chạy được, và không phải AtlasMap.** ADR-013 chốt CDM làm
 *     trung gian, `contracts/cdm/mappers/*.jq` là bộ ánh xạ, và `CdmMapperTest` chứng minh
 *     nó chạy trên Camel thật. Thêm AtlasMap là **cơ chế ánh xạ thứ hai** song song — hai
 *     nguồn sự thật cho cùng một việc.
 *  2. **Vấn đề thật đang là ánh xạ viết tay bằng Java.** `LegacyCitizenToPersonMapper` là
 *     60 dòng Java cho một ánh xạ 4 trường, còn tệp `.jq` cạnh nó chỉ là tài liệu — hai bản
 *     **trôi khỏi nhau lúc nào không biết**. Sinh JQ từ ánh xạ vẽ trên giao diện xóa hẳn
 *     lớp viết tay đó.
 *
 * `atlasmap-runtime` cũng **không có trong kho Maven offline**, nên hướng AtlasMap không
 * kiểm chứng được ở môi trường này. Sinh JQ thì kiểm được ngay bằng chính bộ mẫu CDM.
 *
 * Tệp này **thuần logic**: đọc lược đồ, dựng ánh xạ, sinh biểu thức. Không phụ thuộc React.
 */

/** Một trường phẳng hóa từ JSON Schema, dùng để vẽ cây nguồn/đích. */
export interface SchemaField {
  /** Đường dẫn chấm: `nguoi.hoTen`. */
  path: string;
  /** Tên hiển thị ở nút lá. */
  name: string;
  type: string;
  required: boolean;
  /** Độ sâu, để thụt lề trên cây. */
  depth: number;
}

/** Hàm biến đổi áp lên giá trị nguồn trước khi gán vào đích (FR-D-084). */
export type TransformFn =
  | 'none'
  | 'trim'
  | 'upper'
  | 'lower'
  | 'toString'
  | 'toNumber'
  | 'defaultIfEmpty';

export interface FieldMapping {
  /** Đường dẫn nguồn; nhiều nguồn = ghép chuỗi (nhiều–1). */
  from: string[];
  /** Đường dẫn đích. */
  to: string;
  transform: TransformFn;
  /** Tham số của hàm — hiện chỉ `defaultIfEmpty` dùng tới. */
  arg?: string;
}

/* ---------- Đọc lược đồ ---------- */

function isRec(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/**
 * Phẳng hóa JSON Schema thành danh sách trường.
 *
 * Đệ quy vào `properties` lồng nhau; mảng lấy lược đồ phần tử (`items`) và đánh dấu `[]`
 * trên đường dẫn để người dùng thấy rõ đây là nhiều giá trị.
 */
export function flattenSchema(schema: unknown, prefix = '', depth = 0): SchemaField[] {
  if (!isRec(schema)) return [];
  const props = isRec(schema.properties) ? schema.properties : {};
  const required = new Set(Array.isArray(schema.required) ? schema.required.map(String) : []);
  const out: SchemaField[] = [];

  for (const [name, raw] of Object.entries(props)) {
    if (!isRec(raw)) continue;
    const path = prefix ? `${prefix}.${name}` : name;
    const type = typeof raw.type === 'string' ? raw.type : 'string';

    if (type === 'object' && isRec(raw.properties)) {
      out.push({ path, name, type, required: required.has(name), depth });
      out.push(...flattenSchema(raw, path, depth + 1));
    } else if (type === 'array' && isRec(raw.items)) {
      const arrPath = `${path}[]`;
      out.push({ path: arrPath, name, type, required: required.has(name), depth });
      out.push(...flattenSchema(raw.items, arrPath, depth + 1));
    } else {
      out.push({ path, name, type, required: required.has(name), depth });
    }
  }
  return out;
}

/** Suy lược đồ từ một bản tin mẫu, cho trường hợp không có JSON Schema sẵn. */
export function schemaFromSample(sample: string): unknown {
  let data: unknown;
  try {
    data = JSON.parse(sample);
  } catch {
    return {};
  }
  const build = (v: unknown): Record<string, unknown> => {
    if (Array.isArray(v)) {
      return { type: 'array', items: build(v[0]) };
    }
    if (isRec(v)) {
      const properties: Record<string, unknown> = {};
      for (const [k, val] of Object.entries(v)) properties[k] = build(val);
      return { type: 'object', properties };
    }
    return { type: typeof v === 'number' ? 'number' : typeof v === 'boolean' ? 'boolean' : 'string' };
  };
  return build(data);
}

/* ---------- Sinh biểu thức JQ ---------- */

/** Đường dẫn chấm → biểu thức truy cập JQ. `a.b[]` → `.a.b[]`. */
function jqPath(path: string): string {
  return (
    '.' +
    path
      .split('.')
      .map((seg) => (seg.endsWith('[]') ? `${seg.slice(0, -2)}[]` : seg))
      .join('.')
  );
}

/** Bọc biểu thức nguồn bằng hàm biến đổi. */
function applyTransform(expr: string, m: FieldMapping): string {
  switch (m.transform) {
    case 'trim':
      return `(${expr} | tostring | ltrimstr(" ") | rtrimstr(" "))`;
    case 'upper':
      return `(${expr} | tostring | ascii_upcase)`;
    case 'lower':
      return `(${expr} | tostring | ascii_downcase)`;
    case 'toString':
      return `(${expr} | tostring)`;
    case 'toNumber':
      return `(${expr} | tonumber? // null)`;
    case 'defaultIfEmpty':
      // `// ` của JQ nhận cả `null` lẫn `false`; thêm kiểm chuỗi rỗng cho đúng ý người dùng.
      return `((${expr}) as $v | if $v == null or $v == "" then ${JSON.stringify(m.arg ?? '')} else $v end)`;
    default:
      return expr;
  }
}

/** Nhiều nguồn cho một đích = **ghép chuỗi**, ngăn bằng khoảng trắng. */
function sourceExpr(m: FieldMapping): string {
  const paths = m.from.filter(Boolean);
  if (!paths.length) return 'null';
  if (paths.length === 1) return applyTransform(jqPath(paths[0]), m);
  const joined = paths.map((p) => `(${jqPath(p)} // "" | tostring)`).join(' + " " + ');
  return applyTransform(`(${joined})`, m);
}

/**
 * Dựng cây lồng từ danh sách ánh xạ phẳng, để đích `a.b.c` ra đúng `{a:{b:{c:…}}}`.
 *
 * Ghi phẳng `"a.b.c": …` sẽ tạo **một khóa tên "a.b.c"** chứ không phải cấu trúc lồng —
 * JSON ra đúng cú pháp nhưng sai hình dạng, và chỉ lộ ra khi hệ đích từ chối.
 */
interface Nest {
  [key: string]: Nest | string;
}

function buildNest(mappings: FieldMapping[]): Nest {
  const root: Nest = {};
  for (const m of mappings) {
    if (!m.to.trim()) continue;
    const segs = m.to.split('.');
    let cur = root;
    for (let i = 0; i < segs.length - 1; i += 1) {
      const seg = segs[i];
      if (typeof cur[seg] !== 'object') cur[seg] = {};
      cur = cur[seg] as Nest;
    }
    cur[segs[segs.length - 1]] = sourceExpr(m);
  }
  return root;
}

function renderNest(n: Nest, indent: number): string {
  const pad = ' '.repeat(indent);
  const inner = ' '.repeat(indent + 2);
  const entries = Object.entries(n);
  if (!entries.length) return '{}';
  const body = entries
    .map(([k, v]) => {
      const key = /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(k) ? k : JSON.stringify(k);
      return typeof v === 'string'
        ? `${inner}${key}: ${v}`
        : `${inner}${key}: ${renderNest(v, indent + 2)}`;
    })
    .join(',\n');
  return `{\n${body}\n${pad}}`;
}

/**
 * Sinh biểu thức JQ từ danh sách ánh xạ.
 *
 * Đầu ra khớp dạng `contracts/cdm/mappers/*.jq` đang dùng, nên dùng được ngay ở bước
 * `.transform().jq(...)` của Camel mà không phải viết Java tay.
 */
export function toJq(mappings: FieldMapping[], header?: string): string {
  const usable = mappings.filter((m) => m.to.trim() && m.from.some(Boolean));
  const body = renderNest(buildNest(usable), 0);
  return header ? `# ${header}\n${body}\n` : `${body}\n`;
}

/* ---------- Kiểm tra ---------- */

export interface MappingFinding {
  level: 'error' | 'warn';
  message: string;
}

/**
 * Kiểm ánh xạ trước khi lưu.
 *
 * **Trường đích bắt buộc chưa được ánh xạ** là lỗi quan trọng nhất: bản tin sinh ra thiếu
 * trường mà hệ đích bắt buộc, nên hỏng ở **hệ bên kia** — xa chỗ gây ra, khó lần nhất.
 */
export function validateMappings(
  mappings: FieldMapping[],
  targetFields: SchemaField[],
): MappingFinding[] {
  const out: MappingFinding[] = [];
  const mapped = new Set(mappings.filter((m) => m.from.some(Boolean)).map((m) => m.to));

  for (const f of targetFields) {
    // Nút nhánh (`object`/`array`) không cần ánh xạ trực tiếp — con của nó mới cần.
    if (f.type === 'object' || f.type === 'array') continue;
    if (f.required && !mapped.has(f.path)) {
      out.push({
        level: 'error',
        message: `Trường đích bắt buộc “${f.path}” chưa được ánh xạ`,
      });
    }
  }

  const seen = new Set<string>();
  for (const m of mappings) {
    if (!m.to.trim()) continue;
    if (seen.has(m.to)) {
      out.push({
        level: 'error',
        message: `Trường đích “${m.to}” được ánh xạ hai lần — bản sau đè bản trước`,
      });
    }
    seen.add(m.to);

    if (m.transform === 'defaultIfEmpty' && !m.arg) {
      out.push({
        level: 'warn',
        message: `“${m.to}” dùng giá trị mặc định nhưng chưa nhập giá trị`,
      });
    }
  }
  return out;
}

/**
 * Chạy thử ánh xạ **trong trình duyệt** để xem trước nhanh.
 *
 * ⚠ Đây là **xem trước**, không phải kết quả thật: JQ thật chạy ở máy chủ (FR-D-085). Chỉ
 * hiện thực tập con đủ dùng cho các hàm ở `TransformFn`. Gặp thứ không diễn giải được thì
 * **nói rõ** thay vì đoán bừa — kết quả xem trước sai còn tệ hơn không có xem trước.
 */
export function previewMapping(
  mappings: FieldMapping[],
  sampleJson: string,
): { ok: true; value: unknown } | { ok: false; error: string } {
  let src: unknown;
  try {
    src = JSON.parse(sampleJson);
  } catch (e) {
    return { ok: false, error: `Bản tin mẫu không phải JSON hợp lệ: ${(e as Error).message}` };
  }

  const read = (path: string): unknown => {
    let cur: unknown = src;
    for (const seg of path.split('.')) {
      const key = seg.endsWith('[]') ? seg.slice(0, -2) : seg;
      if (!isRec(cur)) return undefined;
      cur = cur[key];
      // Mảng: xem trước lấy phần tử đầu cho gọn, và nói rõ ở giao diện.
      if (seg.endsWith('[]') && Array.isArray(cur)) cur = cur[0];
    }
    return cur;
  };

  const transform = (v: unknown, m: FieldMapping): unknown => {
    switch (m.transform) {
      case 'trim':
        return String(v ?? '').trim();
      case 'upper':
        return String(v ?? '').toUpperCase();
      case 'lower':
        return String(v ?? '').toLowerCase();
      case 'toString':
        return String(v ?? '');
      case 'toNumber': {
        const n = Number(v);
        return Number.isFinite(n) ? n : null;
      }
      case 'defaultIfEmpty':
        return v === undefined || v === null || v === '' ? (m.arg ?? '') : v;
      default:
        return v;
    }
  };

  const out: Record<string, unknown> = {};
  for (const m of mappings) {
    if (!m.to.trim() || !m.from.some(Boolean)) continue;
    const paths = m.from.filter(Boolean);
    const raw =
      paths.length === 1
        ? read(paths[0])
        : paths.map((p) => String(read(p) ?? '')).join(' ');
    const value = transform(raw, m);

    const segs = m.to.split('.');
    let cur = out;
    for (let i = 0; i < segs.length - 1; i += 1) {
      if (!isRec(cur[segs[i]])) cur[segs[i]] = {};
      cur = cur[segs[i]] as Record<string, unknown>;
    }
    cur[segs[segs.length - 1]] = value;
  }
  return { ok: true, value: out };
}
