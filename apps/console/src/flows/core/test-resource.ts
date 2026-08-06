/**
 * Tài nguyên **Test** — khai báo ca kiểm thử cho một route (K3-4 — IP-07 · FR-D-064).
 *
 * Dạng tệp theo Camel JBang: `kind: Test`, `spec.route` trỏ tới route được kiểm,
 * `spec.cases[]` mỗi ca gồm bản tin vào và khẳng định đầu ra.
 *
 * **Phạm vi tệp này là mô hình, không phải bộ chạy.** Xem `runnerStatus()` — bộ chạy thật
 * chưa có, và `testRun` phía máy chủ hiện **mô phỏng** chứ không nạp Camel. Trình bày đúng
 * sự thật đó cho người dùng còn hơn để họ tưởng ca kiểm thử đã chạy thật.
 */

import type { CamelResource } from './tree';

export interface TestCase {
  name: string;
  /** Bản tin đầu vào (thân). */
  body: string;
  /** Header gửi kèm. */
  headers: Record<string, string>;
  /** Khẳng định: thân đầu ra phải chứa chuỗi này. */
  expectBodyContains?: string;
  /** Khẳng định: route phải chạy qua chặng có tên này. */
  expectStage?: string;
}

function isRec(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/** Route mà bộ kiểm thử này nhắm tới. */
export function readTargetRoute(res: CamelResource): string {
  const spec = isRec(res.rest.spec) ? res.rest.spec : {};
  return typeof spec.route === 'string' ? spec.route : '';
}

export function writeTargetRoute(res: CamelResource, routeCode: string): CamelResource {
  const spec = isRec(res.rest.spec) ? { ...res.rest.spec } : {};
  spec.route = routeCode;
  return { ...res, rest: { ...res.rest, spec } };
}

/** Đọc danh sách ca kiểm thử. */
export function readCases(res: CamelResource): TestCase[] {
  const spec = isRec(res.rest.spec) ? res.rest.spec : {};
  const raw = Array.isArray(spec.cases) ? spec.cases : [];
  return raw.filter(isRec).map((c, i) => {
    const headers: Record<string, string> = {};
    if (isRec(c.headers)) {
      for (const [k, v] of Object.entries(c.headers)) headers[k] = String(v);
    }
    return {
      name: typeof c.name === 'string' ? c.name : `Ca ${i + 1}`,
      body: c.body === undefined ? '' : String(c.body),
      headers,
      expectBodyContains:
        typeof c.expectBodyContains === 'string' ? c.expectBodyContains : undefined,
      expectStage: typeof c.expectStage === 'string' ? c.expectStage : undefined,
    };
  });
}

/** Ghi danh sách ca kiểm thử, giữ nguyên các khóa khác của `spec`. */
export function writeCases(res: CamelResource, cases: TestCase[]): CamelResource {
  const spec = isRec(res.rest.spec) ? { ...res.rest.spec } : {};
  spec.cases = cases.map((c) => {
    const out: Record<string, unknown> = { name: c.name, body: c.body };
    if (Object.keys(c.headers).length) out.headers = { ...c.headers };
    if (c.expectBodyContains) out.expectBodyContains = c.expectBodyContains;
    if (c.expectStage) out.expectStage = c.expectStage;
    return out;
  });
  return { ...res, rest: { ...res.rest, spec } };
}

/**
 * Kiểm bộ Test trước khi lưu.
 *
 * Ca kiểm thử **không có khẳng định nào** là bẫy nguy hiểm nhất: nó luôn "đạt", nên đội
 * vận hành tưởng luồng đã được kiểm trong khi thực tế không kiểm gì cả.
 */
export function validateTest(res: CamelResource): string[] {
  const errs: string[] = [];
  if (!readTargetRoute(res)) errs.push('Chưa chọn route để kiểm thử (`spec.route`)');

  const cases = readCases(res);
  if (!cases.length) errs.push('Chưa có ca kiểm thử nào');

  const seen = new Set<string>();
  for (const c of cases) {
    if (!c.name.trim()) errs.push('Có ca kiểm thử chưa đặt tên');
    else if (seen.has(c.name)) errs.push(`Ca “${c.name}” bị đặt tên trùng`);
    seen.add(c.name);

    if (!c.expectBodyContains && !c.expectStage) {
      errs.push(`Ca “${c.name}” không có khẳng định nào — ca như vậy luôn đạt, không kiểm được gì`);
    }
  }
  return errs;
}

/**
 * Trạng thái bộ chạy kiểm thử.
 *
 * **Nói thẳng cho người dùng biết ca kiểm thử có thật sự chạy hay không.** `testRun` phía
 * máy chủ hiện dựng waterfall chín chặng cố định từ mã băm tên chặng — **không nạp Camel,
 * không đọc định nghĩa luồng**. Ẩn chuyện này đi thì "chạy thử PASSED" trở thành lời hứa
 * sai, nguy hiểm hơn là không có chức năng chạy thử.
 */
export function runnerStatus(): { available: boolean; reason: string } {
  return {
    available: false,
    reason:
      'Bộ chạy thật chưa có: máy chủ đang **mô phỏng** kết quả chạy thử, chưa nạp Camel. ' +
      'Ca kiểm thử khai ở đây được lưu và version hóa, nhưng chưa được thi hành.',
  };
}
