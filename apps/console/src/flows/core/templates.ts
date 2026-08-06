/**
 * Bộ mẫu khởi tạo luồng (K2-2 — IP-07 · FR-D-003).
 *
 * Trước đây mọi luồng mới đều dựng bằng `emptyFlow()` với **bốn chặng khóa cứng** —
 * không dựng nổi luồng trắng kiểu Kaoto, mà Kamelet/Pipe thì về cấu trúc không thể có
 * bốn chặng đó. Theo Q1/BR-D-01: khung chuẩn nay là **một mẫu trong bộ mẫu**, gỡ được;
 * `validate` cảnh báo chứ không chặn.
 *
 * Mẫu viết thẳng bằng YAML rồi cho lõi cây đọc, thay vì dựng `StepNode` bằng tay: YAML là
 * thứ người vận hành đọc và sửa, nên sai lệch giữa mẫu và định nghĩa thật lộ ra ngay.
 */

import { deserialize } from './deserialize';
import type { CamelResource } from './tree';

export interface FlowTemplate {
  id: string;
  title: string;
  description: string;
  /** Loại tài nguyên mẫu này sinh ra — khớp `resource_kind` ở máy chủ. */
  resourceKind: 'ROUTE' | 'KAMELET' | 'PIPE' | 'TEST';
  /** Sinh YAML cho một mã luồng cụ thể. */
  yaml: (routeCode: string) => string;
}

/**
 * Luồng trắng: một chặng tiếp nhận và **một bước ghi log** để chạy được ngay.
 *
 * Vì sao không để `steps: []` cho thật trắng: Camel từ chối nạp route không có bước nào —
 * *Route … has no output processors. You need to add outputs*. Luồng vừa tạo mà không
 * triển khai nổi thì người dùng gặp lỗi ở tận lúc publish, không hiểu vì sao. Một bước
 * `log` là chỗ bám tối thiểu, xóa đi lúc nào cũng được.
 */
const BLANK: FlowTemplate = {
  id: 'blank',
  title: 'Luồng trắng',
  description: 'Một chặng tiếp nhận và một bước ghi log. Tự dựng phần còn lại.',
  resourceKind: 'ROUTE',
  yaml: (code) => `- route:
    id: ${code}
    from:
      uri: direct:${code}
      steps:
        - log:
            message: '${code} nhan ban tin'
`,
};

/**
 * Khung chuẩn LGSP — chín chặng theo WP-20.
 *
 * Giữ nguyên **thứ tự và tên chặng** của `routes/_templates/standard-9-stage.camel.yaml`
 * vì `CamelYamlValidator` phía máy chủ dò đúng những từ khóa này. Lệch một chữ là luồng
 * dựng từ mẫu lại bị chính chốt chặn của nền tảng báo thiếu chặng.
 */
const STANDARD: FlowTemplate = {
  id: 'standard-9-stage',
  title: 'Khung chuẩn LGSP (9 chặng)',
  description:
    'Đủ chín chặng receive → respond theo WP-20. Gỡ bớt được — validate chỉ cảnh báo.',
  resourceKind: 'ROUTE',
  yaml: (code) => `- route:
    id: ${code}
    from:
      uri: direct:${code}
      steps:
        - log:
            message: receive
        - log:
            message: schema
        - log:
            message: authz
        - log:
            message: transform
        - log:
            message: enrich
        - log:
            message: route
        - log:
            message: deliver
        - log:
            message: audit
        - log:
            message: respond
`,
};

/**
 * Luồng REST đối ngoại: tiếp nhận HTTP, gọi hệ đích, bắt lỗi.
 *
 * **Chỉ dùng thành phần chắc chắn có trên runtime** (`platform-http`, `http`, `log`) —
 * đúng quy ước của `routes/_templates/standard-9-stage.camel.yaml`. Mẫu ban đầu của tôi
 * dùng `json-validator` và `kafka`, Camel thật từ chối nạp: *No endpoint could be found …
 * please check your classpath*. Mẫu mà không triển khai được thì tệ hơn là không có mẫu:
 * người dùng dựng xong mới biết, và lỗi hiện ra ở tận lúc publish.
 */
const REST_INTEGRATION: FlowTemplate = {
  id: 'rest-integration',
  title: 'Tích hợp REST',
  description: 'Tiếp nhận HTTP → gọi hệ đích → bắt lỗi. Dùng thành phần có sẵn trên runtime.',
  resourceKind: 'ROUTE',
  yaml: (code) => `- route:
    id: ${code}
    from:
      uri: platform-http:/api/v1/${code}
      steps:
        - log:
            message: receive
        - doTry:
            steps:
              - to:
                  uri: http://he-dich.lgsp.svc/api
            doCatch:
              - exception:
                  - java.io.IOException
                steps:
                  - log:
                      message: 'loi goi he dich: \${exception.message}'
        - log:
            message: audit
`,
};

/** Kamelet: mảnh dùng lại, có tham số khai báo được. */
const KAMELET: FlowTemplate = {
  id: 'kamelet',
  title: 'Kamelet (mảnh dùng lại)',
  description: 'Mảnh luồng có tham số, dùng lại được ở nhiều luồng khác.',
  resourceKind: 'KAMELET',
  yaml: (code) => `apiVersion: camel.apache.org/v1
kind: Kamelet
metadata:
  name: ${code}
spec:
  definition:
    title: ${code}
    description: Mo ta kamelet
    properties: {}
  template:
    from:
      uri: timer:tick
      steps:
        - to:
            uri: kamelet:sink
`,
};

/** Pipe: nối nguồn → đích, không rẽ nhánh. */
const PIPE: FlowTemplate = {
  id: 'pipe',
  title: 'Pipe (nguồn → đích)',
  description: 'Nối một nguồn với một đích qua các bước trung gian. Không rẽ nhánh.',
  resourceKind: 'PIPE',
  yaml: (code) => `apiVersion: camel.apache.org/v1
kind: Pipe
metadata:
  name: ${code}
spec:
  source:
    ref:
      kind: Kamelet
      apiVersion: camel.apache.org/v1
      name: timer-source
  sink:
    ref:
      kind: Kamelet
      apiVersion: camel.apache.org/v1
      name: log-sink
`,
};

/**
 * Test: ca kiểm thử cho một route.
 *
 * Mỗi ca **phải có ít nhất một khẳng định** — ca không khẳng định gì thì luôn đạt, và đội
 * vận hành tưởng luồng đã được kiểm trong khi thực tế không kiểm gì cả. Mẫu này làm gương
 * đúng ngay từ đầu.
 */
const TEST: FlowTemplate = {
  id: 'test',
  title: 'Test (ca kiểm thử)',
  description: 'Khai báo bản tin vào và khẳng định đầu ra cho một route.',
  resourceKind: 'TEST',
  yaml: (code) => `apiVersion: camel.apache.org/v1
kind: Test
metadata:
  name: ${code}
spec:
  route: ${code.replace(/^test-/, '')}
  cases:
    - name: Truong hop thuan
      body: '{"maHoSo":"HS001"}'
      headers:
        Content-Type: application/json
      expectBodyContains: HS001
`,
};

export const TEMPLATES: FlowTemplate[] = [BLANK, STANDARD, REST_INTEGRATION, KAMELET, PIPE, TEST];

export function templateById(id: string): FlowTemplate | undefined {
  return TEMPLATES.find((t) => t.id === id);
}

/**
 * Dựng cây từ một mẫu.
 *
 * Đi qua `deserialize` để mẫu chịu **đúng bộ kiểm** như định nghĩa thật — mẫu hỏng thì
 * lộ ra ở test chứ không đợi tới lúc người dùng tạo luồng mới biết.
 */
export function fromTemplate(id: string, routeCode: string): CamelResource {
  const tpl = templateById(id) ?? BLANK;
  return deserialize(tpl.yaml(routeCode));
}
