/**
 * Pipe — nối nguồn → đích (K3-3 — IP-07 · FR-D-063).
 *
 * Pipe khác Route ở **hình dạng**: `spec.source` → `spec.steps[]` → `spec.sink`, mỗi mắt
 * là một tham chiếu Kamelet (`ref`) hoặc URI, và **không rẽ nhánh**. Vì vậy canvas Pipe
 * phải khóa mọi thao tác rẽ nhánh — cho phép thả `choice` vào Pipe là dựng ra thứ Camel
 * không nạp được.
 *
 * `deserialize` đã dựng Pipe thành dãy `StepNode` tuyến tính; tệp này lo phần **ngữ nghĩa
 * từng mắt** để giao diện hiện đúng và sửa được.
 */

import type { CamelResource, StepNode } from './tree';

/** Một mắt của Pipe. */
export interface PipeLink {
  role: 'source' | 'step' | 'sink';
  /** Tên Kamelet khi mắt là tham chiếu; `undefined` nếu dùng URI trần. */
  kameletName?: string;
  /** URI khi mắt không phải tham chiếu Kamelet. */
  uri?: string;
  /** Tham số truyền cho Kamelet. */
  properties: Record<string, string | number | boolean>;
  /** Đường dẫn trong cây, dùng làm mã node trên sơ đồ. */
  path: string;
}

function isRec(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/** Đọc một mắt từ `rest` của `StepNode` mà `deserialize` giữ nguyên. */
function readLink(step: StepNode): PipeLink {
  const raw = step.rest;
  const ref = isRec(raw.ref) ? raw.ref : undefined;
  const props: Record<string, string | number | boolean> = {};
  if (isRec(raw.properties)) {
    for (const [k, v] of Object.entries(raw.properties)) {
      if (typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean') props[k] = v;
    }
  }
  return {
    role: step.name === 'source' ? 'source' : step.name === 'sink' ? 'sink' : 'step',
    kameletName: ref && typeof ref.name === 'string' ? ref.name : undefined,
    uri: typeof raw.uri === 'string' ? raw.uri : undefined,
    properties: props,
    path: step.path,
  };
}

/** Mọi mắt của Pipe, theo đúng thứ tự chạy. */
export function readLinks(res: CamelResource): PipeLink[] {
  if (res.kind !== 'Pipe') return [];
  return (res.entities[0]?.steps ?? []).map(readLink);
}

/**
 * Đổi tham số của một mắt.
 *
 * Giữ nguyên `ref` và mọi khóa khác trong `rest` — chỉ thay `properties`. Dựng lại cả mắt
 * sẽ làm bay `apiVersion`/`kind` của tham chiếu, thứ Camel cần để tra đúng Kamelet.
 */
export function updateLink(
  res: CamelResource,
  path: string,
  properties: Record<string, string | number | boolean>,
): CamelResource {
  if (res.kind !== 'Pipe') return res;
  return {
    ...res,
    entities: res.entities.map((e) => ({
      ...e,
      steps: e.steps.map((s) =>
        s.path === path ? { ...s, rest: { ...s.rest, properties: { ...properties } } } : s,
      ),
    })),
  };
}

/** Đổi Kamelet của một mắt, giữ nguyên `apiVersion`/`kind` của tham chiếu. */
export function setLinkKamelet(
  res: CamelResource,
  path: string,
  kameletName: string,
): CamelResource {
  if (res.kind !== 'Pipe') return res;
  return {
    ...res,
    entities: res.entities.map((e) => ({
      ...e,
      steps: e.steps.map((s) => {
        if (s.path !== path) return s;
        const ref = isRec(s.rest.ref) ? { ...s.rest.ref } : {};
        return {
          ...s,
          rest: {
            ...s.rest,
            ref: {
              apiVersion: ref.apiVersion ?? 'camel.apache.org/v1',
              kind: ref.kind ?? 'Kamelet',
              ...ref,
              name: kameletName,
            },
          },
        };
      }),
    })),
  };
}

/**
 * Thao tác **không hợp lệ** trên Pipe.
 *
 * Pipe là dãy tuyến tính: không rẽ nhánh, không xóa `source`/`sink` (Camel bắt buộc có cả
 * hai). Giao diện phải khóa những thao tác này thay vì để người dùng dựng ra thứ không
 * triển khai được rồi mới báo lỗi lúc publish.
 */
export const PIPE_FORBIDDEN_STEPS = new Set([
  'choice',
  'doTry',
  'multicast',
  'loadBalance',
  'split',
  'recipientList',
  'circuitBreaker',
]);

/** Bước này thả vào Pipe được không. */
export function allowedInPipe(stepName: string): boolean {
  return !PIPE_FORBIDDEN_STEPS.has(stepName);
}

/** Kiểm hình dạng Pipe trước khi lưu. */
export function validatePipe(res: CamelResource): string[] {
  if (res.kind !== 'Pipe') return [];
  const links = readLinks(res);
  const errs: string[] = [];
  if (!links.some((l) => l.role === 'source')) errs.push('Pipe phải có nguồn (`spec.source`)');
  if (!links.some((l) => l.role === 'sink')) errs.push('Pipe phải có đích (`spec.sink`)');
  for (const l of links) {
    if (!l.kameletName && !l.uri) {
      errs.push(`Mắt “${l.role}” chưa chọn Kamelet hoặc URI`);
    }
  }
  return errs;
}
