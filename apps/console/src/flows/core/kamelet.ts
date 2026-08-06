/**
 * Tham số Kamelet — đọc/ghi `spec.definition` (K3-1 — IP-07 · FR-D-061).
 *
 * `spec.definition` là **JSON Schema draft-07**, đúng dạng 243 kamelet đã vendor dùng:
 * `properties` là map tên → đặc tả, `required` là danh sách tên bắt buộc. Trình soạn cần
 * dạng **danh sách** để hiện bảng và giữ thứ tự, nên tệp này lo việc đổi qua lại.
 *
 * Không tự đặt cấu trúc riêng: sai lệch với dạng gốc thì kamelet tự viết sẽ không dùng
 * được ở nơi khác, mà lỗi chỉ lộ ra lúc Camel nạp.
 */

import type { CamelResource } from './tree';

/**
 * Kiểu tham số Kamelet.
 *
 * Lấy theo **kiểu 243 kamelet đã vendor thật sự dùng** (đếm trên chính dữ liệu đó:
 * `string` 1256 · `boolean` 316 · `integer` 111 · `binary` 9 · `long` 1), **không** theo
 * enum `['string','number','boolean']` của `KameletConfiguration.kameletProperties` —
 * enum đó thiếu `integer` (kiểu phổ biến thứ ba) và có `number` mà không kamelet gốc nào
 * dùng. Đặt theo enum ấy thì trình soạn vừa thiếu kiểu người dùng cần, vừa chào kiểu lạ.
 */
export type KameletPropType = 'string' | 'boolean' | 'integer' | 'long' | 'binary';

/** Thứ tự hiện trong ô chọn — phổ biến nhất lên trước. */
export const KAMELET_PROP_TYPES: KameletPropType[] = [
  'string',
  'boolean',
  'integer',
  'long',
  'binary',
];

export interface KameletProp {
  name: string;
  title?: string;
  description?: string;
  type: KameletPropType;
  /** Giá trị mặc định; `undefined` là không có. */
  default?: string | number | boolean;
  example?: string;
  required: boolean;
}

interface RawProp {
  title?: string;
  description?: string;
  type?: string;
  default?: unknown;
  example?: unknown;
}

function isRec(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/** Kiểu lạ thì coi là `string` — giữ được giá trị, không nuốt tham số. */
function normType(raw: unknown): KameletPropType {
  return (KAMELET_PROP_TYPES as readonly unknown[]).includes(raw)
    ? (raw as KameletPropType)
    // `number` xuất hiện trong enum của `KameletConfiguration` nhưng không kamelet gốc nào
    // dùng; quy về `integer` thay vì `string` để không đổi ngữ nghĩa số thành chuỗi.
    : raw === 'number'
      ? 'integer'
      : 'string';
}

/** `spec.definition` → danh sách tham số cho trình soạn. */
export function readProps(res: CamelResource): KameletProp[] {
  const spec = isRec(res.rest.spec) ? res.rest.spec : {};
  const def = isRec(spec.definition) ? spec.definition : {};
  const props = isRec(def.properties) ? def.properties : {};
  const required = new Set(Array.isArray(def.required) ? def.required.map(String) : []);

  return Object.entries(props).map(([name, raw]) => {
    const p = (isRec(raw) ? raw : {}) as RawProp;
    return {
      name,
      title: typeof p.title === 'string' ? p.title : undefined,
      description: typeof p.description === 'string' ? p.description : undefined,
      type: normType(p.type),
      default: (typeof p.default === 'string' ||
      typeof p.default === 'number' ||
      typeof p.default === 'boolean'
        ? p.default
        : undefined) as KameletProp['default'],
      example: p.example === undefined ? undefined : String(p.example),
      required: required.has(name),
    };
  });
}

/**
 * Danh sách tham số → `spec.definition`, **giữ nguyên các khóa khác** của `definition`
 * (`title`, `description`…) và của `spec`.
 *
 * Dựng lại `definition` từ số không sẽ làm bay tiêu đề và mô tả kamelet — dữ liệu người
 * dùng đã nhập, không phải thứ suy ra được.
 */
export function writeProps(res: CamelResource, props: KameletProp[]): CamelResource {
  const spec = isRec(res.rest.spec) ? { ...res.rest.spec } : {};
  const def = isRec(spec.definition) ? { ...spec.definition } : {};

  const properties: Record<string, unknown> = {};
  const required: string[] = [];

  for (const p of props) {
    const name = p.name.trim();
    if (!name) continue;
    const out: Record<string, unknown> = { type: p.type };
    if (p.title) out.title = p.title;
    if (p.description) out.description = p.description;
    if (p.default !== undefined && p.default !== '') out.default = p.default;
    if (p.example !== undefined && p.example !== '') out.example = p.example;
    properties[name] = out;
    if (p.required) required.push(name);
  }

  def.properties = properties;
  // `required` rỗng thì bỏ hẳn khóa: `required: []` là nhiễu, và một số bộ đọc JSON Schema
  // coi mảng rỗng là bất hợp lệ.
  if (required.length) def.required = required;
  else delete def.required;

  spec.definition = def;
  return { ...res, rest: { ...res.rest, spec } };
}

/** Tên tham số hợp lệ: chữ, số, gạch dưới — dùng được trong `{{tenThamSo}}` của Camel. */
export const PROP_NAME_RE = /^[a-zA-Z][a-zA-Z0-9_]*$/;

/**
 * Kiểm danh sách tham số trước khi ghi.
 *
 * Trùng tên là lỗi nặng nhất: map `properties` chỉ giữ được một, tham số kia **biến mất
 * lặng lẽ** — đúng lớp lỗi mà cả đợt này đang chặn.
 */
export function validateProps(props: KameletProp[]): string[] {
  const errs: string[] = [];
  const seen = new Set<string>();
  for (const p of props) {
    const name = p.name.trim();
    if (!name) {
      errs.push('Có tham số chưa đặt tên');
      continue;
    }
    if (!PROP_NAME_RE.test(name)) {
      errs.push(`Tên “${name}” không hợp lệ — dùng chữ, số và gạch dưới, bắt đầu bằng chữ`);
    }
    if (seen.has(name)) errs.push(`Tham số “${name}” bị khai hai lần`);
    seen.add(name);
  }
  return errs;
}

/** Tiêu đề/mô tả của chính kamelet (`spec.definition.title`/`.description`). */
export function readMeta(res: CamelResource): { title: string; description: string } {
  const spec = isRec(res.rest.spec) ? res.rest.spec : {};
  const def = isRec(spec.definition) ? spec.definition : {};
  return {
    title: typeof def.title === 'string' ? def.title : '',
    description: typeof def.description === 'string' ? def.description : '',
  };
}

export function writeMeta(
  res: CamelResource,
  meta: { title?: string; description?: string },
): CamelResource {
  const spec = isRec(res.rest.spec) ? { ...res.rest.spec } : {};
  const def = isRec(spec.definition) ? { ...spec.definition } : {};
  if (meta.title !== undefined) def.title = meta.title;
  if (meta.description !== undefined) def.description = meta.description;
  spec.definition = def;
  return { ...res, rest: { ...res.rest, spec } };
}
