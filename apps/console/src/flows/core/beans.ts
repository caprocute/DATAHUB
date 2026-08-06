/**
 * Bean registry cấp tệp (K5-1 — IP-07 · FR-D-080).
 *
 * `beans` là **danh sách `BeanFactoryDefinition`** ở cấp cao nhất của tệp Camel YAML, không
 * nằm trong route nào. `deserialize` đã gom sẵn vào `CamelResource.beans`; tệp này lo phần
 * đọc/ghi có kiểu và kiểm tra.
 *
 * Bắt buộc `name` + `type` — đúng `required` của lược đồ gốc. Thiếu một trong hai thì Camel
 * từ chối nạp, mà lỗi chỉ hiện ra lúc publish.
 */

import type { CamelResource } from './tree';

export interface BeanDef {
  name: string;
  /** Tên lớp đầy đủ (fully qualified). */
  type: string;
  /** Thuộc tính đặt lên bean sau khi tạo. */
  properties: Record<string, string>;
  /** Các khóa khác của lược đồ (`initMethod`, `factoryMethod`…) — giữ nguyên, không vứt. */
  rest: Record<string, unknown>;
}

function isRec(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/** Khóa do tệp này quản; khóa ngoài danh sách đi vào `rest`. */
const OWNED = new Set(['name', 'type', 'properties']);

export function readBeans(res: CamelResource): BeanDef[] {
  return res.beans.filter(isRec).map((b) => {
    const properties: Record<string, string> = {};
    if (isRec(b.properties)) {
      for (const [k, v] of Object.entries(b.properties)) properties[k] = String(v);
    }
    const rest: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(b)) if (!OWNED.has(k)) rest[k] = v;

    return {
      name: typeof b.name === 'string' ? b.name : '',
      type: typeof b.type === 'string' ? b.type : '',
      properties,
      rest,
    };
  });
}

export function writeBeans(res: CamelResource, beans: BeanDef[]): CamelResource {
  return {
    ...res,
    beans: beans.map((b) => {
      const out: Record<string, unknown> = { ...b.rest, name: b.name, type: b.type };
      // `properties: {}` là nhiễu — bean không có thuộc tính nào vẫn hợp lệ.
      if (Object.keys(b.properties).length) out.properties = { ...b.properties };
      return out;
    }),
  };
}

/** Tên bean hợp lệ: dùng được trong tham chiếu `#tenBean` của Camel. */
export const BEAN_NAME_RE = /^[a-zA-Z_][a-zA-Z0-9_-]*$/;

/**
 * Mẫu bắt chuỗi **giống bí mật** trong giá trị thuộc tính bean (BR-D-02, K5-4).
 *
 * Giữ **đồng bộ với `CamelYamlValidator.SECRET_PATTERN`** phía máy chủ. Console cảnh báo
 * sớm cho người dùng sửa ngay; máy chủ mới là chốt chặn thật lúc publish.
 */
const SECRET_KEY_RE = /(password|secret|api[_-]?key|private[_-]?key|token)/i;

/** Giá trị chỉ **tham chiếu** tới kho bí mật thì không phải bí mật lộ. */
function isReference(value: string): boolean {
  const v = value.trim();
  // `{{...}}` là property placeholder của Camel; `#` là tham chiếu bean;
  // `vault:`/`secret:` là tham chiếu kho bí mật.
  return (
    v.startsWith('{{') ||
    v.startsWith('#') ||
    v.startsWith('vault:') ||
    v.startsWith('secret:') ||
    v === ''
  );
}

export interface BeanFinding {
  level: 'error' | 'warn';
  message: string;
}

/**
 * Kiểm danh sách bean trước khi lưu.
 *
 * Trùng tên là lỗi nặng: Camel giữ bean sau đè bean trước, nên cấu hình của bean đầu **biến
 * mất lặng lẽ** — luồng dùng nó vẫn chạy nhưng với thứ khác hẳn.
 */
export function validateBeans(beans: BeanDef[]): BeanFinding[] {
  const out: BeanFinding[] = [];
  const seen = new Set<string>();

  for (const b of beans) {
    const name = b.name.trim();
    if (!name) {
      out.push({ level: 'error', message: 'Có bean chưa đặt tên' });
    } else {
      if (!BEAN_NAME_RE.test(name)) {
        out.push({
          level: 'error',
          message: `Tên bean “${name}” không hợp lệ — dùng chữ, số, gạch dưới và gạch ngang`,
        });
      }
      if (seen.has(name)) {
        out.push({
          level: 'error',
          message: `Bean “${name}” bị khai hai lần — Camel giữ bean sau, cấu hình bean trước mất`,
        });
      }
      seen.add(name);
    }

    if (!b.type.trim()) {
      out.push({
        level: 'error',
        message: `Bean “${name || '(chưa đặt tên)'}” chưa có lớp (\`type\`)`,
      });
    }

    // BR-D-02 — không lưu bí mật trong định nghĩa luồng.
    for (const [k, v] of Object.entries(b.properties)) {
      if (SECRET_KEY_RE.test(k) && !isReference(v)) {
        out.push({
          level: 'error',
          message:
            `Bean “${name}” đặt bí mật thẳng vào “${k}” — vi phạm BR-D-02. ` +
            'Dùng `{{...}}` trỏ tới Vault hoặc kết nối PH-05.',
        });
      }
    }
  }
  return out;
}

/** Tham chiếu bean dùng trong trường cấu hình: Camel viết là `#tenBean`. */
export function beanRef(name: string): string {
  return `#${name}`;
}

/** Tên bean rút từ một tham chiếu; không phải tham chiếu thì trả `undefined`. */
export function refToBeanName(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined;
  const v = value.trim();
  return v.startsWith('#') ? v.slice(1) : undefined;
}

/**
 * Trường này có nhận bean không (K5-2).
 *
 * Camel nhận bean ở trường kiểu `object` hoặc tên trường gợi ý rõ. Đoán rộng quá thì mọi ô
 * text đều thành ô chọn bean; hẹp quá thì người dùng phải gõ tay `#tenBean` — thứ K5-2 sinh
 * ra để tránh.
 */
export function acceptsBean(fieldName: string, fieldType?: string): boolean {
  if (fieldType === 'object') return true;
  return /(bean|strategy|resolver|factory|processor|aggregationStrategy|converter)$/i.test(
    fieldName,
  );
}

/* ---------- Metadata cho Kamelet/Pipe (K5-3 · FR-D-082) ---------- */

export interface ResourceMeta {
  name: string;
  labels: Record<string, string>;
  annotations: Record<string, string>;
}

/**
 * Ba trường người dùng đặt được trong `metadata`.
 *
 * `ObjectMeta` còn `uid`, `resourceVersion`, `creationTimestamp`, `managedFields`… nhưng
 * đó là **trường do máy chủ Kubernetes quản** — cho người dùng sửa là mời gọi lỗi khó lần.
 * Đọc thì giữ nguyên tất cả (qua `rest`), ghi thì chỉ đụng ba trường này.
 */
const META_OWNED = new Set(['name', 'labels', 'annotations']);

export function readMetadata(res: CamelResource): ResourceMeta {
  const m = res.metadata ?? {};
  const pick = (v: unknown): Record<string, string> => {
    const out: Record<string, string> = {};
    if (isRec(v)) for (const [k, val] of Object.entries(v)) out[k] = String(val);
    return out;
  };
  return {
    name: typeof m.name === 'string' ? m.name : '',
    labels: pick(m.labels),
    annotations: pick(m.annotations),
  };
}

export function writeMetadata(res: CamelResource, meta: ResourceMeta): CamelResource {
  const keep: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(res.metadata ?? {})) if (!META_OWNED.has(k)) keep[k] = v;

  const next: Record<string, unknown> = { ...keep, name: meta.name };
  if (Object.keys(meta.labels).length) next.labels = { ...meta.labels };
  if (Object.keys(meta.annotations).length) next.annotations = { ...meta.annotations };
  return { ...res, metadata: next };
}

/** Tên tài nguyên Kubernetes: chữ thường, số, gạch ngang — RFC 1123. */
export const K8S_NAME_RE = /^[a-z0-9]([a-z0-9-]*[a-z0-9])?$/;

export function validateMetadata(meta: ResourceMeta): BeanFinding[] {
  const out: BeanFinding[] = [];
  if (!meta.name.trim()) {
    out.push({ level: 'error', message: 'Tài nguyên chưa có tên (`metadata.name`)' });
  } else if (!K8S_NAME_RE.test(meta.name)) {
    out.push({
      level: 'error',
      message: `Tên “${meta.name}” không hợp lệ — chữ thường, số và gạch ngang (RFC 1123)`,
    });
  }
  // Nhãn/chú thích cũng nằm trong định nghĩa đem triển khai nên BR-D-02 vẫn áp.
  for (const [k, v] of Object.entries({ ...meta.labels, ...meta.annotations })) {
    if (SECRET_KEY_RE.test(k) && !isReference(v)) {
      out.push({
        level: 'error',
        message: `“${k}” trong metadata chứa bí mật — vi phạm BR-D-02`,
      });
    }
  }
  return out;
}
