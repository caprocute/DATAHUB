---
ma_tai_lieu: D03-04-PH10
ten: Đặc tả API và sự kiện phân hệ PH-10 Sự kiện
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-integration, dh-runtime, giao diện; đơn vị kết nối HTTT; ATTT; hội đồng thẩm định
phan_he: PH-10
---

# D03-04-PH10 · Đặc tả API và sự kiện Sự kiện

## Tóm tắt cho hội đồng thẩm định

Tập này là hợp đồng giao tiếp của phân hệ PH-10 Sự kiện, phân hệ thay Hub Apache Pulsar của hệ cũ bằng trục sự kiện Kafka có đăng ký lược đồ, duyệt bốn mắt và giao nhận có ký. PH-10 công bố **121 operation REST** chia ba mặt:

- **Control plane** `/api/event/v1` (module `event` của `dh-integration`): 99 operation cho dự án, topic, lược đồ, bên phát, bên nhận, publication, subscription, duyệt, DLQ, phát lại, danh mục, hạn mức, tham số, xuất nhập và di trú Pulsar, cộng 4 operation máy với máy cho PH-04 và `dh-runtime`.
- **Data plane** `/event/v1` (cổng sự kiện của `dh-runtime`, qua `apisix-ext` và `apisix-int`): 6 operation cho HTTT phát, kéo, xác nhận, báo lỗi và tra lược đồ chỉ đọc.
- **API nội bộ cho `dh-runtime`** (API-10-085…090 và mã tách 119): 7 operation báo giao nhận, ngắt mạch, phát lại, cầu nối; chỉ qua `apisix-int` với mTLS và token máy, không hiện ở BFF.

Mã API-10-001…091 giữ đúng thứ tự gợi ý của FRS §8.3. 18 dòng gộp nhiều hành động ở FRS được tách thành operation riêng, cấp mã mới **API-10-092…119** (28 mã, bảng §3.1). Thêm **API-10-120** (nhận khóa ký đầu tiên) theo đề nghị B7 của tập màn hình D03-06-PH10 (§10.3) và **API-10-121** (hủy tác vụ nhập) theo FRS 0.3. Từ FRS 0.3, §8.3 liệt kê đủ 121 mã. Sự kiện gồm **EVT-10-01…16** theo CloudEvents 1.0, kênh **giao ĐẨY webhook ký HMAC** theo ADR-044 và ADR-071 (dạng có cấu trúc, dạng nhị phân, bắt tay xác minh) và hai **kênh mẫu** cho topic nghiệp vụ `{tenant}.{miền}.{thực-thể}.{sự-kiện}.v{n}` và topic DLQ `{topicName}.dlq`.

Hợp đồng máy đọc được, sinh từ một nguồn và đã kiểm:

- [`ph10/openapi-event.yaml`](ph10/openapi-event.yaml): OpenAPI 3.1, 196 lược đồ, mỗi operation có ví dụ yêu cầu (khi có thân) và ví dụ phản hồi; 264 ví dụ (gồm 73 ví dụ lỗi, mỗi mã ERR-10 có HTTP một ví dụ) khớp lược đồ theo [`check_contracts.py`](ph10/tools/check_contracts.py). `openapi-spec-validator` hợp lệ; `@redocly/cli lint` hợp lệ, một cảnh báo (máy chủ `localhost` cho phát triển cục bộ).
- [`ph10/asyncapi-event.yaml`](ph10/asyncapi-event.yaml): AsyncAPI 3.0, 20 kênh, 38 operation, 21 thông điệp; `@asyncapi/parser` 3.3 không lỗi, không cảnh báo; 44 ví dụ khớp payload và tiêu đề.

Bốn nguyên tắc hợp đồng:

1. **Mọi enum, tên trường lấy theo Phụ lục A của FRS** (D02-03-PH10 0.2). Script [`doi_chieu_frs.py`](ph10/tools/doi_chieu_frs.py) đối chiếu YAML và tài liệu này với FRS; trường chỉ có ở API mà phụ lục chưa có được liệt kê ở §10 để FRS hấp thụ, không tự thêm vào phụ lục.
2. **HTTT chỉ chạm data plane với scope do PH-10 cấp** (`topic:{topicName}:publish`, `:subscribe`), cấp khi publication, subscription được duyệt; máy nội bộ dùng scope `event:*`; người dùng dùng `PERM-10-*`.
3. **Không API, không sự kiện nào trả giá trị khóa ký**, trừ đúng một lần trong phản hồi xoay khóa (`SigningKeyIssued.secret`, `readOnly`); kiểm tra hợp đồng chặn trường bí mật ở mọi lược đồ khác.
4. **Mọi lệnh tạo có `Idempotency-Key`, mọi lệnh sửa và hành động control plane có `If-Match`**, giống PH-04, PH-05; cổng phát chống trùng 24 giờ theo `id` của CloudEvents.

Căn cứ: FRS D02-03-PH10 §8 và Phụ lục A; SDD D03-02-PH10 §3.3, §4.6…4.16; CSDL D03-03-PH10 (DDL `ph10_event`); ADR-044, ADR-070, ADR-071, ADR-072, ADR-073. Mọi tên miền, dữ liệu trong ví dụ là giả lập, tenant T68.

## 1. Quy ước chung

| Mục | Quy ước |
|---|---|
| Đường gốc | Control plane `/api/event/v1` (BFF console của tenant; trong cụm `dh-integration.dh-control.svc`). Data plane `/event/v1` (`event.{tenant}.datahub…` qua `apisix-ext`; `apisix-int` cho HTTT trong TTDL). API nội bộ `/api/event/v1/runtime/*` chỉ qua `apisix-int` |
| Phiên bản | Đường dẫn `v1`; thay đổi phá vỡ sang `v2`, chạy song song ≥ 6 tháng; oasdiff ở CI-5 chặn thay đổi phá vỡ trong `v1` |
| Tenant | Lấy từ token (claim `tenant`), không bao giờ từ thân. Tên topic mang tiền tố tenant và phải khớp tenant của token (ERR-10-005 ở control plane, ERR-10-103 ở data plane, không lộ topic của tenant khác) |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên (`:submit`, `:approve`, `:pause`, `:rotate`, `:cut-over`) theo AIP-136 |
| Khóa lạc quan | `GET` đối tượng trả `ETag: W/"{version}"`; `PUT`, `PATCH` và hành động bắt buộc `If-Match`, lệch trả ERR-10-007 (412) kèm `currentEtag`. Miễn: hành động không sửa bản ghi có phiên bản (API-10-026, 051, 071, 072) và hành động tạo bản ghi mới (API-10-064, 111, 113) |
| Chống trùng | `POST` tạo, xoay khóa, loại bỏ DLQ, nhập bắt buộc `Idempotency-Key` (16…128 ký tự), giữ 24 giờ ở Valkey `dh:{tenant}:evt:idem:{chủ thể}:{khóa}` (FRS A.8). Cùng khóa cùng thân trả lại phản hồi cũ; cùng khóa khác thân ERR-10-037. Cổng phát (API-10-079) nhận `Idempotency-Key` tùy chọn, mặc định dùng `id` của CloudEvents |
| Phân trang | `page` (từ 0), `size` (1…200, mặc định 20), `sort=truong,asc\|desc`; phản hồi `items`, `page`, `size`, `totalElements`, kèm `facets` đếm theo trạng thái ở danh sách chính (FR-10-001). Vượt miền ERR-10-049 |
| Lọc | Tham số lặp dạng `status=ACTIVE,DEPRECATED`; tìm `q` không dấu trên mã, tên, mô tả; khoảng thời gian `from`, `to` |
| Lỗi | RFC 9457 `application/problem+json`, `type = https://datahub.gov.vn/errors/{code}`, `code = ERR-10-nnn`, `traceId`; trường mở rộng ở §6.3 |
| Tiến trình dài | Cấp phát topic do máy đăng ký, thử lại cấp phát, nhập, áp dụng nhập, xuất lớn trả 202 kèm `Location`; theo dõi bằng `GET` hoặc sự kiện EVT-10-01 |
| Truy vết | `traceparent` W3C xuyên APISIX, BFF, `dh-integration`, Kafka (tiêu đề `traceparent` của CloudEvents), bộ giao nhận và đầu nhận webhook |
| Ngôn ngữ | `Accept-Language: vi` (mặc định) hoặc `en` cho `title`, `detail` ở control plane; data plane chỉ tiếng Anh ngắn trong `title` để HTTT ghi log |
| Định dạng sự kiện | Control plane và Kafka: CloudEvents 1.0 nhị phân (`ce_*`). Webhook và API kéo: CloudEvents JSON có cấu trúc (`application/cloudevents+json`), hoặc nhị phân (`ce-*`) khi subscription chọn `CLOUDEVENTS_BINARY` (FRS §4.9) |

### 1.1. Ba mặt giao tiếp và đường mạng

| Mặt | Bên gọi | Đường vào | Xác thực | Operation |
|---|---|---|---|---|
| Control plane, người dùng | Console qua BFF | `apisix-int` → BFF → `dh-integration` | OIDC + PKCE ở BFF, token không ra trình duyệt; `PERM-10-*` | 99 |
| Control plane, máy | PH-04, PH-05, PH-13, PH-18, DU nội bộ | Gọi trong tiến trình khi cùng DU; REST trong cụm khi tách DU | `client_credentials` + `private_key_jwt`, mTLS mesh; scope `event:*` | Dùng chung 9 operation với người dùng (API-10-008, 009, 010, 018, 023, 060, 061, 063, 064) và 3 riêng (071, 072, 109) |
| Runtime nội bộ | `dh-runtime` của tenant | `apisix-int`, không qua BFF | mTLS và token máy `dh-runtime-{tenant}`, scope `event:runtime-config`, `event:replay` | 8 (073, 085…090, 119) |
| Data plane | HTTT thành viên | `apisix-ext` (mạng TSLCD) hoặc `apisix-int` | Token HTTT `client_credentials` có scope `topic:{topicName}:*`, hoặc mTLS (CN `{systemCode}.{tenant}`); OPA kiểm quan hệ bên phát, bên nhận | 6 (079…084) |

APISIX xác thực token và gọi OPA trước khi tới cổng sự kiện; cổng chỉ tin danh tính ở tiêu đề do APISIX ghi lại sau xác thực (`X-Dh-Client-Id`, `X-Dh-Tenant`, chỉ chấp nhận trên kết nối mTLS từ APISIX, SEC-15), không tin tiêu đề do HTTT gửi (SDD §4.6).

## 2. Xác thực và phân quyền

### 2.1. Quyền người dùng

Quyền theo FRS §3.2 và A.4. Bảng sau tóm tắt quyền theo nhóm operation; cột "Quyền" của §3 là nguồn chi tiết và trùng với `x-datahub-permission` trong OpenAPI.

| Quyền | Vai trò (FRS §3.2) | Operation tiêu biểu |
|---|---|---|
| `PERM-10-read` | PA, PO, TA, TO, SO, IE, IA, SV, OR (○), VW, AU | Mọi `GET` control plane, xuất khai báo (074), sơ đồ (007), dashboard (066) |
| `PERM-10-create` | TA, IE, SV (○) | Tạo dự án, topic, phiên bản lược đồ, bên phát, bên nhận; đề nghị publication; gửi duyệt; nhập khai báo |
| `PERM-10-update` | TA, IE, SV (○) | Sửa, lưu trữ dự án; sửa topic, đề nghị đổi cấu hình, ngừng topic; sửa lược đồ nháp; ngừng dùng bên tham gia; thu hồi publication |
| `PERM-10-subscribe` | TA, IE, OR (○) | Đề nghị, sửa, thu hồi subscription; xác minh endpoint; xoay khóa ký (cùng `PERM-10-operate`) |
| `PERM-10-approve` | TA, IA | Duyệt, từ chối mọi yêu cầu (API-10-059, 101) |
| `PERM-10-operate` | TA, TO, SO | Tạm ngừng, tiếp tục bên tham gia, publication, subscription; xoay, thu hồi khóa; xem nội dung và loại bỏ mục DLQ; đề nghị, hủy phát lại; xác nhận cảnh báo lag |
| `PERM-10-admin` | PA, TA | Danh mục kiểu giao tiếp, chế độ định tuyến, hạn mức, tham số `10.*`, ngoại lệ xác minh endpoint (091), nhập kiểm kê Pulsar, cầu nối, chuyển hẳn, quay lui |

Quy tắc vượt quyền chức năng, máy chủ kiểm:

- **Bốn mắt** (BR-10-010, FR-00-071): người duyệt khác người tạo đối tượng và người gửi yêu cầu (ERR-10-008). TA có cả `create` và `approve` nên bốn mắt kiểm theo từng yêu cầu, không theo vai trò. IE và IA là cặp loại trừ ở D02-08 §4.
- **Phạm vi tổ chức**: OR và SV chỉ thao tác trên HTTT thuộc tổ chức của mình; ngoài phạm vi ERR-10-044. Danh sách của OR chỉ trả đối tượng có HTTT của tổ chức mình.
- **SO** chỉ dùng `PERM-10-operate` để tạm ngừng khi có sự cố ATTT và tiếp tục đối tượng do chính SO tạm ngừng (`suspendSource = SECURITY`); không phát lại, không xử lý DLQ (FRS §3.2).
- **Rút yêu cầu** (API-10-102): chỉ người gửi, với quyền đã dùng để gửi (`create`, `update`, `subscribe` hoặc `operate`).
- **Topic `CDC`, `SYSTEM`**: người dùng chỉ sửa mô tả; cấu hình do tài khoản dịch vụ chủ quản sửa (ERR-10-045). Topic nền tảng tiền tố `dh.` chỉ PA và tài khoản dịch vụ nền tảng.
- **Tham số phạm vi N** và `10.external-kafka.enabled` chỉ PA sửa qua API-10-108; TA chỉ sửa tham số phạm vi T, T* trong trần.

### 2.2. Scope máy và scope HTTT

| Scope | Cấp cho | Operation | Ghi chú |
|---|---|---|---|
| `event:topic-register` | `dh-integration` (mô-đun PH-05), DU nội bộ | API-10-009, 010, 018, 023 | Topic `CDC`, `SYSTEM`; tự duyệt theo BR-10-031 |
| `event:permission-check` | `dh-integration` (mô-đun PH-04) | API-10-008 (`usableBy`), 071, 072, 109 | Gọi trong tiến trình khi cùng DU |
| `event:runtime-config` | `dh-runtime-{tenant}` | API-10-073, 085, 086, 090, 119 | Đọc cấu hình, báo giao nhận, ngắt mạch, cầu nối |
| `event:replay` | PH-18; `dh-runtime-{tenant}` | API-10-063, 064, 104; 087, 088, 089 | PH-18 đề nghị; runtime chạy |
| `event:dlq-read` | PH-18 | API-10-060, 061 | Siêu dữ liệu DLQ |
| `event:metrics-read` | PH-13 | API-10-055, 066 | Lag và dashboard; chỉ số chính đi bằng OTLP |
| `topic:{topicName}:publish` | Client của HTTT có publication `ACTIVE` | API-10-079, 084 | Cấp ở Keycloak khi duyệt (FR-10-031), gỡ khi tạm ngừng, thu hồi; dữ liệu OPA gỡ trước ≤ 60 giây |
| `topic:{topicName}:subscribe` | Client của HTTT có subscription `ACTIVE` | API-10-080…084 | Client của token phải là client của bên nhận |

Mã lỗi xác thực, quyền chung theo FRS 0.3: control plane (`/api/event/v1`, kể cả API nội bộ `runtime`) dùng ERR-10-053 (401) và ERR-10-054 (403 thiếu `PERM-10-*` hoặc scope dịch vụ); data plane (`/event/v1`) dùng ERR-10-101 (401) và ERR-10-102 (403). Mọi operation đều có thể trả hai mã của mặt mình nên bảng §3 không nhắc lại.

## 3. Danh mục endpoint

Bảng sinh từ [`ph10/tools/spec.py`](ph10/tools/spec.py) bằng `gen_md.py`, cùng nguồn với OpenAPI. Cột "FR" ghi số FR-10 bỏ tiền tố. Cột "Lỗi riêng" ghi mã ERR-10 ngoài các mã chung: 101, 102 (mọi operation), 001 (đường dẫn có tham số), 003 (có thân), 007 (có `If-Match`), 037 (có `Idempotency-Key` bắt buộc), 039 (lệnh ghi control plane khi tenant tạm ngừng hoặc đóng băng), 049 (danh sách). Danh sách đầy đủ theo operation nằm ở `x-datahub-errors` trong OpenAPI. Đường dẫn data plane ghi đủ gốc `/event/v1`; đường dẫn khác tương đối với `/api/event/v1`.

<!-- gen:endpoints:start -->
**Dự án tích hợp**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-001 | `GET /projects` | Danh sách, tìm kiếm, lọc dự án | 001 | `PERM-10-read` |  | 200 | 049 |
| API-10-002 | `POST /projects` | Tạo dự án tích hợp | 003 | `PERM-10-create` | bắt buộc | 201 | 002, 011, 037, 039 |
| API-10-003 | `GET /projects/{projectCode}` | Chi tiết dự án | 002 | `PERM-10-read` |  | 200 | 044 |
| API-10-004 | `PATCH /projects/{projectCode}` | Sửa dự án | 004 | `PERM-10-update` |  | 200 | 006, 044 |
| API-10-005 | `POST /projects/{projectCode}:archive` | Lưu trữ dự án | 005 | `PERM-10-update` |  | 200 | 006, 009, 010 |
| API-10-006 | `POST /projects/{projectCode}:restore` | Khôi phục dự án đã lưu trữ | 005 | `PERM-10-update` |  | 200 | 006 |

**Giám sát, dashboard, sơ đồ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-007 | `GET /graph` | Sơ đồ kết nối bên phát, topic, bên nhận | 058 | `PERM-10-read` |  | 200 | 049 |

**Topic**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-008 | `GET /topics` | Danh sách topic; tra cứu topic dùng được cho luồng | 006, 069 | `PERM-10-read` hoặc `event:permission-check` (dịch vụ) |  | 200 | 049 |
| API-10-009 | `POST /topics` | Tạo topic (người) hoặc đăng ký topic CDC, SYSTEM (máy) | 008, 066, 067 | `PERM-10-create` hoặc `event:topic-register` (dịch vụ) | bắt buộc | 201 | 002, 004, 005, 006, 011, 012, 015, 017, 018, 020, 029, 037, 039, 046, 048 |
| API-10-010 | `GET /topics/{topicName}` | Chi tiết topic | 007 | `PERM-10-read` hoặc `event:topic-register` (dịch vụ) |  | 200 |  |
| API-10-011 | `PATCH /topics/{topicName}` | Sửa mô tả; sửa cấu hình khi còn DRAFT | 008, 014 | `PERM-10-update` |  | 200 | 006, 012, 045, 046, 048 |
| API-10-012 | `POST /topics/{topicName}:submit` | Gửi duyệt tạo topic | 008 | `PERM-10-create` |  | 200 | 006, 011, 015, 017, 018 |
| API-10-013 | `POST /topics/{topicName}:retry-provisioning` | Thử lại cấp phát topic FAILED | 010 | `PERM-10-update` |  | 202 | 006, 029, 038 |
| API-10-014 | `POST /topics/{topicName}:cancel-provisioning` | Hủy cấp phát, đưa topic về DRAFT | 010 | `PERM-10-update` |  | 200 | 006, 038 |
| API-10-015 | `POST /topics/{topicName}/change-requests` | Đề nghị đổi phân vùng, lưu giữ, dọn, định tuyến, mức tương thích | 011, 012, 013, 021 | `PERM-10-update` | bắt buộc | 201 | 006, 011, 012, 013, 014, 019, 045, 046, 047, 048 |
| API-10-016 | `POST /topics/{topicName}:deprecate` | Ngừng khuyến nghị topic | 014 | `PERM-10-update` |  | 200 | 006, 009, 045 |
| API-10-017 | `POST /topics/{topicName}:retire` | Đề nghị ngừng dùng topic | 014 | `PERM-10-update` |  | 200 | 006, 009, 010, 045 |
| API-10-018 | `POST /topics/{topicName}:new-major-version` | Tạo phiên bản chính mới của topic | 015, 068 | `PERM-10-update` hoặc `event:topic-register` (dịch vụ) | bắt buộc | 201 | 006, 011, 015, 017, 018, 029, 045, 047 |
| API-10-019 | `GET /topics/{topicName}/migration-status` | Tiến độ chuyển bên nhận sang topic kế nhiệm | 016 | `PERM-10-read` |  | 200 |  |
| API-10-020 | `GET /topics/{topicName}/connection-info` | Thông tin kết nối và cấu hình mẫu cho bên phát, bên nhận | 007, 024, 034 | `PERM-10-read` |  | 200 |  |

**Lược đồ sự kiện**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-021 | `GET /topics/{topicName}/schema` | Lược đồ của topic (định dạng, mức tương thích) | 020 | `PERM-10-read` |  | 200 |  |
| API-10-022 | `GET /topics/{topicName}/schema/versions` | Danh sách phiên bản lược đồ | 020 | `PERM-10-read` |  | 200 | 049 |
| API-10-023 | `POST /topics/{topicName}/schema/versions` | Tạo phiên bản lược đồ nháp (người) hoặc đăng ký phiên bản CDC (máy) | 017, 068 | `PERM-10-create` hoặc `event:topic-register` (dịch vụ) | bắt buộc | 201 | 006, 015, 016, 017, 018, 020, 029, 037, 045 |
| API-10-024 | `GET /topics/{topicName}/schema/versions/{versionNo}` | Chi tiết một phiên bản lược đồ | 020 | `PERM-10-read` |  | 200 |  |
| API-10-025 | `PUT /topics/{topicName}/schema/versions/{versionNo}` | Sửa nội dung phiên bản nháp | 017 | `PERM-10-update` |  | 200 | 006, 015, 017, 018, 020 |
| API-10-026 | `POST /topics/{topicName}/schema/versions/{versionNo}:check` | Kiểm tra cú pháp, tương thích, dữ liệu cá nhân | 017, 018 | `PERM-10-create` |  | 200 | 015, 029 |
| API-10-027 | `POST /topics/{topicName}/schema/versions/{versionNo}:submit` | Gửi duyệt phiên bản lược đồ | 019 | `PERM-10-create` |  | 200 | 006, 015, 016, 017, 018 |
| API-10-028 | `POST /topics/{topicName}/schema/versions/{versionNo}:deprecate` | Ngừng khuyến nghị phiên bản lược đồ | 022 | `PERM-10-update` |  | 200 | 006, 009 |
| API-10-029 | `POST /topics/{topicName}/schema/versions/{versionNo}:disable` | Vô hiệu phiên bản lược đồ | 022 | `PERM-10-update` |  | 200 | 006, 009 |
| API-10-030 | `GET /topics/{topicName}/schema/diff` | So sánh hai phiên bản lược đồ | 020 | `PERM-10-read` |  | 200 | 049 |
| API-10-031 | `GET /topics/{topicName}/compliance` | Tuân thủ lược đồ của bên phát Kafka trực tiếp | 023 | `PERM-10-read` |  | 200 | 049 |

**Bên phát, bên nhận**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-032 | `GET /publishers` | Danh sách bên phát | 025 | `PERM-10-read` |  | 200 | 049 |
| API-10-033 | `POST /publishers` | Đăng ký bên phát | 026 | `PERM-10-create` | bắt buộc | 201 | 002, 021, 022, 023, 024, 037, 044 |
| API-10-034 | `GET /publishers/{publisherCode}` | Chi tiết bên phát | 025 | `PERM-10-read` |  | 200 | 044 |
| API-10-035 | `PATCH /publishers/{publisherCode}` | Sửa bên phát | 028 | `PERM-10-update` |  | 200 | 006, 044 |
| API-10-036 | `POST /publishers/{publisherCode}:suspend` | Tạm ngừng bên phát | 028 | `PERM-10-operate` |  | 200 | 006, 009 |
| API-10-092 | `POST /publishers/{publisherCode}:resume` | Tiếp tục bên phát | 028 | `PERM-10-operate` |  | 200 | 006, 009 |
| API-10-093 | `POST /publishers/{publisherCode}:retire` | Ngừng dùng bên phát | 028 | `PERM-10-update` |  | 200 | 006, 009 |
| API-10-037 | `GET /subscribers` | Danh sách bên nhận | 025 | `PERM-10-read` |  | 200 | 049 |
| API-10-038 | `POST /subscribers` | Đăng ký bên nhận | 027 | `PERM-10-create` | bắt buộc | 201 | 002, 021, 022, 023, 024, 037, 044 |
| API-10-039 | `GET /subscribers/{subscriberCode}` | Chi tiết bên nhận | 025 | `PERM-10-read` |  | 200 | 044 |
| API-10-040 | `PATCH /subscribers/{subscriberCode}` | Sửa bên nhận | 028 | `PERM-10-update` |  | 200 | 006, 044 |
| API-10-041 | `POST /subscribers/{subscriberCode}:suspend` | Tạm ngừng bên nhận | 028 | `PERM-10-operate` |  | 200 | 006, 009 |
| API-10-094 | `POST /subscribers/{subscriberCode}:resume` | Tiếp tục bên nhận | 028 | `PERM-10-operate` |  | 200 | 006, 009 |
| API-10-095 | `POST /subscribers/{subscriberCode}:retire` | Ngừng dùng bên nhận | 028 | `PERM-10-update` |  | 200 | 006, 009 |

**Publication**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-042 | `GET /publications` | Danh sách publication | 030 | `PERM-10-read` |  | 200 | 049 |
| API-10-043 | `POST /publications` | Đề nghị publication | 030 | `PERM-10-create` | bắt buộc | 201 | 011, 024, 025, 037, 044, 051 |
| API-10-044 | `GET /publications/{publicationCode}` | Chi tiết publication | 030 | `PERM-10-read` |  | 200 |  |
| API-10-045 | `POST /publications/{publicationCode}:suspend` | Tạm ngừng publication | 032 | `PERM-10-operate` |  | 200 | 006, 009 |
| API-10-096 | `POST /publications/{publicationCode}:resume` | Tiếp tục publication | 032 | `PERM-10-operate` |  | 200 | 006, 009, 025 |
| API-10-097 | `POST /publications/{publicationCode}:revoke` | Thu hồi publication | 032 | `PERM-10-update` |  | 200 | 006, 009 |

**Subscription và giao nhận**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-046 | `GET /subscriptions` | Danh sách subscription | 035 | `PERM-10-read` |  | 200 | 049 |
| API-10-047 | `POST /subscriptions` | Đề nghị subscription | 035 | `PERM-10-subscribe` | bắt buộc | 201 | 011, 024, 025, 026, 027, 028, 030, 031, 037, 044, 051 |
| API-10-048 | `GET /subscriptions/{subscriptionCode}` | Chi tiết subscription | 035, 056 | `PERM-10-read` |  | 200 | 044 |
| API-10-049 | `PATCH /subscriptions/{subscriptionCode}` | Sửa tham số subscription | 046 | `PERM-10-subscribe` |  | 200 | 006, 012, 026, 027, 030, 044 |
| API-10-050 | `POST /subscriptions/{subscriptionCode}:pause` | Tạm dừng subscription | 041 | `PERM-10-operate` |  | 200 | 006, 009, 052 |
| API-10-098 | `POST /subscriptions/{subscriptionCode}:resume` | Tiếp tục subscription | 041 | `PERM-10-operate` |  | 200 | 006, 009, 052 |
| API-10-099 | `POST /subscriptions/{subscriptionCode}:revoke` | Thu hồi subscription | 047 | `PERM-10-subscribe` |  | 200 | 006, 009, 044 |
| API-10-051 | `POST /endpoint-verifications` | Xác minh endpoint webhook | 036 | `PERM-10-subscribe` |  | 200 | 026, 027 |
| API-10-091 | `POST /subscriptions/{subscriptionCode}/endpoint-verification:waive` | Ngoại lệ xác minh endpoint có thời hạn | 036 | `PERM-10-admin` |  | 200 | 006, 009, 012 |
| API-10-052 | `GET /subscriptions/{subscriptionCode}/stats` | Thống kê giao nhận theo thời gian | 056 | `PERM-10-read` |  | 200 | 049 |
| API-10-053 | `GET /subscriptions/{subscriptionCode}/failures` | Lượt giao lỗi gần đây | 056 | `PERM-10-read` |  | 200 | 049 |
| API-10-054 | `POST /subscriptions/{subscriptionCode}/signing-keys:rotate` | Xoay khóa ký webhook | 042 | `PERM-10-operate` hoặc `PERM-10-subscribe` | bắt buộc | 200 | 006, 029 |
| API-10-100 | `POST /subscriptions/{subscriptionCode}/signing-keys:revoke` | Thu hồi khẩn khóa ký, sinh khóa mới | 042 | `PERM-10-operate` | bắt buộc | 200 | 006, 009, 029 |
| API-10-120 | `POST /subscriptions/{subscriptionCode}/signing-keys:claim` | Nhận khóa ký đầu tiên một lần sau khi duyệt | 037, 042 | `PERM-10-subscribe` |  | 200 | 006, 029, 044 |
| API-10-055 | `GET /subscriptions/{subscriptionCode}/lag` | Độ trễ tiêu thụ theo phân vùng | 054 | `PERM-10-read` hoặc `event:metrics-read` (dịch vụ) |  | 200 | 049 |
| API-10-056 | `POST /subscriptions/{subscriptionCode}/lag-alerts:acknowledge` | Xác nhận cảnh báo lag | 055 | `PERM-10-operate` |  | 200 | 006 |

**Yêu cầu duyệt**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-057 | `GET /approval-requests` | Danh sách yêu cầu duyệt | 009, 019, 031, 037, 051 | `PERM-10-read` |  | 200 | 049 |
| API-10-058 | `GET /approval-requests/{requestCode}` | Chi tiết yêu cầu duyệt | 009, 019, 031, 037, 051 | `PERM-10-read` |  | 200 |  |
| API-10-059 | `POST /approval-requests/{requestCode}:approve` | Duyệt yêu cầu | 009, 019, 031, 037, 051 | `PERM-10-approve` |  | 200 | 006, 008, 009, 011, 016, 029, 038, 051 |
| API-10-101 | `POST /approval-requests/{requestCode}:reject` | Từ chối yêu cầu | 009, 019, 031, 037, 051 | `PERM-10-approve` |  | 200 | 006, 008, 009 |
| API-10-102 | `POST /approval-requests/{requestCode}:withdraw` | Rút yêu cầu đã gửi | 009, 019, 031, 037, 051 | `PERM-10-create` hoặc `PERM-10-update` hoặc `PERM-10-subscribe` hoặc `PERM-10-operate` |  | 200 | 006, 009 |

**DLQ và phát lại**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-060 | `GET /dlq-entries` | Danh sách mục DLQ (siêu dữ liệu) | 050 | `PERM-10-read` hoặc `event:dlq-read` (dịch vụ) |  | 200 | 049 |
| API-10-061 | `GET /dlq-entries/{dlqEntryId}` | Siêu dữ liệu một mục DLQ | 050 | `PERM-10-read` hoặc `event:dlq-read` (dịch vụ) |  | 200 |  |
| API-10-103 | `GET /dlq-entries/{dlqEntryId}/payload` | Nội dung một mục DLQ | 050 | `PERM-10-operate` |  | 200 | 009, 029 |
| API-10-062 | `POST /dlq-entries:discard` | Loại bỏ mục DLQ | 050 | `PERM-10-operate` | bắt buộc | 200 | 009, 036 |
| API-10-063 | `GET /replays` | Danh sách lượt phát lại | 052 | `PERM-10-read` hoặc `event:replay` (dịch vụ) |  | 200 | 049 |
| API-10-104 | `GET /replays/{replayCode}` | Chi tiết, tiến độ lượt phát lại | 052 | `PERM-10-read` hoặc `event:replay` (dịch vụ) |  | 200 |  |
| API-10-064 | `POST /replays` | Đề nghị phát lại theo khoảng, đặt lại offset, mục DLQ | 051, 053 | `PERM-10-operate` hoặc `event:replay` (dịch vụ) | bắt buộc | 201 | 006, 009, 026, 027, 032, 033, 034, 035, 036 |
| API-10-065 | `POST /replays/{replayCode}:cancel` | Hủy lượt phát lại | 052 | `PERM-10-operate` |  | 200 | 006, 009 |

**Giám sát, dashboard, sơ đồ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-066 | `GET /dashboard` | Dashboard sự kiện của tenant | 057 | `PERM-10-read` hoặc `event:metrics-read` (dịch vụ) |  | 200 | 049 |

**Danh mục, hạn mức, tham số**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-067 | `GET /comm-types` | Danh mục kiểu giao tiếp | 060 | `PERM-10-read` |  | 200 |  |
| API-10-105 | `PATCH /comm-types/{commTypeCode}` | Bật, tắt kiểu giao tiếp cho tenant | 060 | `PERM-10-admin` |  | 200 | 009, 043 |
| API-10-068 | `GET /routing-modes` | Danh mục chế độ định tuyến | 061 | `PERM-10-read` |  | 200 |  |
| API-10-106 | `PATCH /routing-modes/{routingModeCode}` | Bật, tắt chế độ định tuyến cho tenant | 061 | `PERM-10-admin` |  | 200 | 009, 043 |
| API-10-069 | `GET /quota` | Hạn mức sự kiện của tenant và mức dùng | 062 | `PERM-10-read` |  | 200 |  |
| API-10-107 | `PUT /quota` | Đặt trần (PA) hoặc phân bổ hạn mức (TA) | 062 | `PERM-10-admin` |  | 200 | 009, 011, 012 |
| API-10-070 | `GET /settings` | Tham số 10.* hiệu lực của tenant | 063 | `PERM-10-read` |  | 200 |  |
| API-10-108 | `PATCH /settings` | Sửa tham số 10.* trong miền cho phép | 063 | `PERM-10-admin` |  | 200 | 009, 012 |

**Máy với máy (PH-04)**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-071 | `POST /permissions:check` | Kiểm tra quyền phát, nhận của luồng PH-04 | 069 | `event:permission-check` (dịch vụ) |  | 200 | 029 |
| API-10-072 | `POST /flows/{flowCode}:ensure-party` | Tạo bên tham gia FLOW và đề nghị quan hệ cho luồng | 069 | `event:permission-check` (dịch vụ) | bắt buộc | 200 | 022, 024, 025, 029 |
| API-10-109 | `GET /flows/{flowCode}/dependencies` | Publication, subscription của luồng (cho API-04-016) | 069 | `event:permission-check` (dịch vụ) |  | 200 |  |

**Nội bộ dh-runtime**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-073 | `GET /runtime/subscriptions` | Cấu hình runtime: topic, subscription, lượt phát lại | 038, 043 | `event:runtime-config` (dịch vụ) |  | 200 |  |

**Xuất nhập, di trú Pulsar**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-074 | `POST /exports` | Xuất khai báo EventManifest | 070 | `PERM-10-read` |  | 200 | 049 |
| API-10-075 | `POST /imports` | Tải tệp khai báo hoặc kiểm kê Pulsar để kiểm tra | 071, 072 | `PERM-10-create` hoặc `PERM-10-admin` | bắt buộc | 202 | 040, 050 |
| API-10-110 | `GET /imports/{jobCode}` | Trạng thái, xem trước tác vụ nhập | 071, 072 | `PERM-10-read` |  | 200 |  |
| API-10-111 | `POST /imports/{jobCode}:apply` | Áp dụng tác vụ nhập (tạo đối tượng ở trạng thái đầu) | 071, 072 | `PERM-10-create` | bắt buộc | 202 | 006, 040, 041, 050 |
| API-10-121 | `POST /imports/{jobCode}:cancel` | Hủy tác vụ nhập ở `VALIDATING`, `PREVIEW` (người tạo) | 071 | `PERM-10-create` |  | 200 | 006, 008 |
| API-10-076 | `GET /migrations/mappings` | Danh sách ánh xạ di trú Pulsar | 072 | `PERM-10-read` |  | 200 | 049 |
| API-10-112 | `PATCH /migrations/mappings/{mappingId}` | Sửa đích hoặc bỏ qua một ánh xạ | 072 | `PERM-10-admin` |  | 200 | 006, 041 |
| API-10-077 | `GET /migrations/bridges` | Danh sách cầu nối di trú | 073, 074 | `PERM-10-read` |  | 200 | 049 |
| API-10-113 | `POST /migrations/bridges` | Đề nghị cầu nối Pulsar sang Kafka hoặc ngược lại | 073, 074 | `PERM-10-admin` | bắt buộc | 201 | 012, 025, 041, 042 |
| API-10-114 | `POST /migrations/bridges/{bridgeCode}:stop` | Dừng cầu nối | 073, 074 | `PERM-10-admin` |  | 200 | 006, 009 |
| API-10-115 | `POST /migrations/bridges/{bridgeCode}:resume` | Chạy lại cầu nối đã dừng | 073, 074 | `PERM-10-admin` |  | 200 | 006, 009, 042 |
| API-10-078 | `POST /migrations/mappings/{mappingId}:cut-over` | Đề nghị chuyển hẳn một ánh xạ | 075 | `PERM-10-admin` |  | 200 | 006, 009, 041 |
| API-10-116 | `POST /migrations/mappings/{mappingId}:rollback` | Quay lui một ánh xạ đã chuyển hẳn | 075 | `PERM-10-admin` |  | 200 | 006, 009, 042 |
| API-10-117 | `GET /migrations/reconciliations` | Kết quả đối chiếu Pulsar và Kafka | 075 | `PERM-10-read` |  | 200 | 049 |
| API-10-118 | `GET /migrations/progress` | Báo cáo tiến độ di trú | 076 | `PERM-10-read` |  | 200 |  |

**Data plane: phát, kéo, lược đồ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-079 | `POST /event/v1/topics/{topicName}/events` | Phát một sự kiện hoặc một lô sự kiện | 033 | `topic:{topicName}:publish` | tùy chọn | 202 | 103, 104, 105, 106, 107, 108, 121 |
| API-10-080 | `GET /event/v1/subscriptions/{subscriptionCode}/events` | Kéo lô sự kiện (lease, chờ dài) | 043 | `topic:{topicName}:subscribe` |  | 200 | 107, 110, 121 |
| API-10-081 | `POST /event/v1/subscriptions/{subscriptionCode}/events:ack` | Xác nhận lô đã kéo | 043 | `topic:{topicName}:subscribe` |  | 204 | 109, 110, 121 |
| API-10-082 | `POST /event/v1/subscriptions/{subscriptionCode}/events:nack` | Báo sự kiện xử lý lỗi, đưa vào DLQ | 043 | `topic:{topicName}:subscribe` |  | 204 | 109, 110, 121 |
| API-10-083 | `POST /event/v1/subscriptions/{subscriptionCode}/dead-letters` | Bên nhận Kafka ngoài báo bản tin lỗi vào DLQ | 044 | `topic:{topicName}:subscribe` | tùy chọn | 202 | 106, 107, 110 |
| API-10-084 | `GET /event/v1/registry/{registryPath}` | Tra cứu lược đồ chỉ đọc (Apicurio v3, ccompat/v7) | 024 | `topic:{topicName}:publish` hoặc `:subscribe` |  | 200 | 103 |

**Nội bộ dh-runtime**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |
|---|---|---|---|---|---|---|---|
| API-10-085 | `POST /runtime/delivery-reports` | Báo cáo giao nhận theo phút | 056 | `event:runtime-config` (dịch vụ) |  | 204 |  |
| API-10-086 | `POST /runtime/subscriptions/{subscriptionCode}:suspend` | Tạm ngừng do ngắt mạch hoặc failurePolicy BLOCK | 039 | `event:runtime-config` (dịch vụ) |  | 200 | 006 |
| API-10-119 | `POST /runtime/subscriptions/{subscriptionCode}:resume` | Tự tiếp tục sau ngắt mạch (chỉ CIRCUIT_BREAKER) | 039 | `event:runtime-config` (dịch vụ) |  | 200 | 006 |
| API-10-087 | `POST /runtime/replays/{replayCode}:start` | Nhận chạy lượt phát lại APPROVED | 052 | `event:replay` (dịch vụ) |  | 200 | 006 |
| API-10-088 | `POST /runtime/replays/{replayCode}/results` | Báo tiến độ, kết quả từng mục DLQ, kết thúc lượt phát lại | 052, 053 | `event:replay` (dịch vụ) |  | 200 | 006 |
| API-10-089 | `POST /runtime/dlq-entries:fetch-payloads` | Lấy nội dung mục DLQ theo lô ≤ 100 | 053 | `event:replay` (dịch vụ) |  | 200 | 029 |
| API-10-090 | `POST /runtime/bridges/{bridgeCode}/status` | Báo trạng thái, số bản tin, lag của cầu nối | 073, 074 | `event:runtime-config` (dịch vụ) |  | 204 | 006 |
<!-- gen:endpoints:end -->

### 3.1. Tách dòng gộp của FRS

FRS §8.3 gộp nhiều hành động vào một dòng để giữ thứ tự mã. Mỗi operation cần một mã (khuôn K-API), nên tập này giữ mã FRS cho hành động đầu tiên và cấp mã kế tiếp từ API-10-092 cho hành động còn lại theo thứ tự dòng. Đề nghị FRS cập nhật §8.3 theo bảng dưới (§10.2).

<!-- gen:split:start -->
| Dòng FRS §8.3 | Nội dung gộp ở FRS | Giữ mã cho | Mã cấp mới |
|---|---|---|---|
| API-10-036 | `POST /publishers/{publisherCode}:suspend` · `:resume` · `:retire` | `POST /publishers/{publisherCode}:suspend` | API-10-092 `POST /publishers/{publisherCode}:resume`; API-10-093 `POST /publishers/{publisherCode}:retire` |
| API-10-041 | `POST /subscribers/{subscriberCode}:suspend` · `:resume` · `:retire` | `POST /subscribers/{subscriberCode}:suspend` | API-10-094 `POST /subscribers/{subscriberCode}:resume`; API-10-095 `POST /subscribers/{subscriberCode}:retire` |
| API-10-045 | `POST /publications/{publicationCode}:suspend` · `:resume` · `:revoke` | `POST /publications/{publicationCode}:suspend` | API-10-096 `POST /publications/{publicationCode}:resume`; API-10-097 `POST /publications/{publicationCode}:revoke` |
| API-10-050 | `POST /subscriptions/{subscriptionCode}:pause` · `:resume` · `:revoke` | `POST /subscriptions/{subscriptionCode}:pause` | API-10-098 `POST /subscriptions/{subscriptionCode}:resume`; API-10-099 `POST /subscriptions/{subscriptionCode}:revoke` |
| API-10-054 | `POST /subscriptions/{subscriptionCode}/signing-keys:rotate` · `:revoke` | `POST /subscriptions/{subscriptionCode}/signing-keys:rotate` | API-10-100 `POST /subscriptions/{subscriptionCode}/signing-keys:revoke` |
| API-10-059 | `POST /approval-requests/{requestCode}:approve` · `:reject` · `:withdraw` | `POST /approval-requests/{requestCode}:approve` | API-10-101 `POST /approval-requests/{requestCode}:reject`; API-10-102 `POST /approval-requests/{requestCode}:withdraw` |
| API-10-061 | `GET /dlq-entries/{dlqEntryId}` (siêu dữ liệu), `GET /dlq-entries/{dlqEntryId}/payload` | `GET /dlq-entries/{dlqEntryId}` | API-10-103 `GET /dlq-entries/{dlqEntryId}/payload` |
| API-10-063 | `GET /replays`, `GET /replays/{replayCode}` | `GET /replays` | API-10-104 `GET /replays/{replayCode}` |
| API-10-067 | `GET /comm-types`, `PATCH /comm-types/{commTypeCode}` | `GET /comm-types` | API-10-105 `PATCH /comm-types/{commTypeCode}` |
| API-10-068 | `GET /routing-modes`, `PATCH /routing-modes/{routingModeCode}` | `GET /routing-modes` | API-10-106 `PATCH /routing-modes/{routingModeCode}` |
| API-10-069 | `GET /quota`, `PUT /quota` | `GET /quota` | API-10-107 `PUT /quota` |
| API-10-070 | `GET /settings`, `PATCH /settings` | `GET /settings` | API-10-108 `PATCH /settings` |
| API-10-072 | `POST /flows/{flowCode}:ensure-party`, `GET /flows/{flowCode}/dependencies` | `POST /flows/{flowCode}:ensure-party` | API-10-109 `GET /flows/{flowCode}/dependencies` |
| API-10-075 | `POST /imports`, `GET /imports/{jobCode}`, `POST /imports/{jobCode}:apply` | `POST /imports` | API-10-110 `GET /imports/{jobCode}`; API-10-111 `POST /imports/{jobCode}:apply` |
| API-10-076 | `GET /migrations/mappings`, `PATCH /migrations/mappings/{mappingId}` | `GET /migrations/mappings` | API-10-112 `PATCH /migrations/mappings/{mappingId}` |
| API-10-077 | `GET /migrations/bridges`, `POST /migrations/bridges`, `POST /migrations/bridges/{bridgeCode}:stop` · `:resume` | `GET /migrations/bridges` | API-10-113 `POST /migrations/bridges`; API-10-114 `POST /migrations/bridges/{bridgeCode}:stop`; API-10-115 `POST /migrations/bridges/{bridgeCode}:resume` |
| API-10-078 | `POST /migrations/mappings/{mappingId}:cut-over` · `:rollback`, `GET /migrations/reconciliations`, `GET /migrations/progress` | `POST /migrations/mappings/{mappingId}:cut-over` | API-10-116 `POST /migrations/mappings/{mappingId}:rollback`; API-10-117 `GET /migrations/reconciliations`; API-10-118 `GET /migrations/progress` |
| API-10-086 | `POST /runtime/subscriptions/{subscriptionCode}:suspend` (scope `event:runtime-config`; `suspendSource` `CIRCUIT_BREAKER` hoặc `DELIVERY_BLOCKED`), `POST /runtime/subscriptions/{subscriptionCode}:resume` (chỉ khi `CIRCUIT_BREAKER`) | `POST /runtime/subscriptions/{subscriptionCode}:suspend` | API-10-119 `POST /runtime/subscriptions/{subscriptionCode}:resume` |
<!-- gen:split:end -->

### 3.2. Ví dụ yêu cầu và phản hồi

Mỗi operation có ví dụ trong OpenAPI (`components/examples`, dùng chung giữa operation cùng lược đồ). Dưới đây là các luồng chính, tenant T68, dữ liệu giả lập. Khóa `Idempotency-Key` trong tài liệu dùng dạng đọc được, không dùng UUID.

**API-10-009 Tạo topic và gửi duyệt ngay (IE)**

```http
POST /api/event/v1/topics
Idempotency-Key: t68-tao-topic-dkkd-20261126-01
Content-Type: application/json

{"projectCode": "dang-ky-kinh-doanh", "domain": "dkkd", "entity": "doanh-nghiep", "eventName": "da-cap-phep",
 "description": "Phát khi Sở KH&ĐT cấp mới giấy chứng nhận đăng ký doanh nghiệp.", "partitions": 6, "retentionHours": 168,
 "cleanupPolicy": "DELETE", "routingMode": "KEY_HASH", "partitionKeyField": "maDoanhNghiep", "orderingRequired": true,
 "dataClass": "INTERNAL", "schema": {"schemaFormat": "AVRO", "content": "{\"type\":\"record\",…}", "compatibility": "BACKWARD"},
 "submit": true}
```

```http
HTTP/1.1 201 Created
ETag: W/"0"
Location: /api/event/v1/topics/t68.dkkd.doanh-nghiep.da-cap-phep.v1

{"topicName": "t68.dkkd.doanh-nghiep.da-cap-phep.v1", "projectCode": "dang-ky-kinh-doanh", "topicKind": "BUSINESS",
 "majorVersion": 1, "partitions": 6, "replicationFactor": 3, "minInsyncReplicas": 2, "retentionHours": 168,
 "cleanupPolicy": "DELETE", "routingMode": "KEY_HASH", "partitionKeyField": "maDoanhNghiep", "orderingRequired": true,
 "dataClass": "INTERNAL", "status": "PENDING_APPROVAL", "latestSchemaVersion": 1,
 "approvalRequestCode": "apr-01jd3y9b4c6d8e0f2g4h6j8k0m", "version": 0}
```

**API-10-009 PH-05 đăng ký topic CDC (máy, tự duyệt)**

```http
POST /api/event/v1/topics
Authorization: Bearer <token dh-integration, scope event:topic-register>
Idempotency-Key: t68-cdc-qldd-oracle-thua-dat-v1

{"topicKind": "CDC", "topicName": "t68.cdc.qldd-oracle.qldd.thua-dat.v1", "projectCode": "cdc-qldd-oracle",
 "description": "Thay đổi bảng QLDD.THUA_DAT do PH-05 thu bằng Debezium.", "partitions": 6, "retentionHours": 168,
 "routingMode": "KEY_HASH", "partitionKeyField": "ID_THUA", "dataClass": "RESTRICTED",
 "schema": {"schemaFormat": "AVRO", "content": "{…sinh từ cấu trúc bảng…}"}, "onBehalfOf": "an.nv",
 "sourceRef": {"adapterCode": "qldd-oracle", "table": "QLDD.THUA_DAT"}}
```

```http
HTTP/1.1 202 Accepted
Location: /api/event/v1/topics/t68.cdc.qldd-oracle.qldd.thua-dat.v1

{"topicName": "t68.cdc.qldd-oracle.qldd.thua-dat.v1", "topicKind": "CDC", "status": "PROVISIONING",
 "ownerServiceCode": "dh-cdc", "approvalRequestCode": "apr-01jd3y9b4c6d8e0f2g4h6j8k0m", "…": "…"}
```

Gửi lại cùng cấu hình trả 200 với trạng thái hiện tại; khác cấu hình trả ERR-10-002. PH-05 chờ tối đa 5 giây rồi theo dõi bằng EVT-10-01 hoặc API-10-010 (FR-10-066).

**API-10-047 Đề nghị subscription ĐẨY**

```http
POST /api/event/v1/subscriptions
Idempotency-Key: t68-sub-ht-thue-dn-cap-phep-01

{"subscriberCode": "ht-thue", "topicName": "t68.dkkd.doanh-nghiep.da-cap-phep.v1", "deliveryMode": "PUSH",
 "purpose": "Thông báo doanh nghiệp được cấp đăng ký cho cơ quan thuế xử lý mã số thuế.", "startPosition": "LATEST",
 "push": {"endpointUrl": "https://thue.t68.gov.vn/hooks/dh", "workerCount": 3, "maxRetries": 8,
          "retryBackoff": {"initialMs": 1000, "multiplier": 2, "maxMs": 300000}, "timeoutMs": 10000,
          "failurePolicy": "BLOCK", "payloadFormat": "CLOUDEVENTS_STRUCTURED"},
 "lagWarnSeconds": 300, "lagCriticalSeconds": 1800}
```

Phản hồi 201 mang `subscriptionCode = ht-thue-dn-cap-phep` (sinh theo FR-10-035), `consumerGroup = dh-sub-t68-ht-thue-dn-cap-phep`, `status = PENDING_APPROVAL`, `push.lastVerification` của lần bắt tay gần nhất và `approvalRequestCode`. Endpoint chưa xác minh được trả ERR-10-027 kèm `errors[]` nêu bước lỗi (DNS, TLS, bắt tay).

**API-10-059 Duyệt yêu cầu (IA)**

```http
POST /api/event/v1/approval-requests/apr-01jd3y9b4c6d8e0f2g4h6j8k0m:approve
If-Match: W/"0"

{"comment": "Đã rà soát lược đồ và phân loại dữ liệu.", "acknowledgePii": true}
```

Phản hồi 200 là `ApprovalRequest` với `status = APPROVED`, `decidedBy`, `decidedAt`. Với `TOPIC_CREATE`, topic sang `PROVISIONING` và EVT-10-01 phát khi Strimzi báo `Ready`. Người duyệt cũng là người gửi trả ERR-10-008:

```json
{"type": "https://datahub.gov.vn/errors/ERR-10-008", "title": "Vi phạm bốn mắt", "status": 403,
 "code": "ERR-10-008", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736"}
```

**API-10-079 Phát một sự kiện (HTTT)**

```http
POST /event/v1/topics/t68.dkkd.doanh-nghiep.da-cap-phep.v1/events
Authorization: Bearer <token HT-DKKD, scope topic:t68.dkkd.doanh-nghiep.da-cap-phep.v1:publish>
Content-Type: application/cloudevents+json

{"specversion": "1.0", "id": "01JD3Y8K2M9P3Q7R4T6V8W0Y2Z", "source": "/t68/systems/HT-DKKD",
 "type": "vn.datahub.dkkd.doanh-nghiep.da-cap-phep", "time": "2026-11-26T09:15:02+07:00", "subject": "0312345678",
 "datacontenttype": "application/json", "data": {"maDoanhNghiep": "0312345678", "loaiThayDoi": "CAP_MOI", "phienBan": 1}}
```

```http
HTTP/1.1 202 Accepted

{"results": [{"id": "01JD3Y8K2M9P3Q7R4T6V8W0Y2Z", "partition": 2, "offset": 182312, "schemaVersion": 3}]}
```

Lô dùng `Content-Type: application/cloudevents-batch+json` với mảng ≤ `10.publish.max-batch` sự kiện, ≤ 1 MiB; lô là tất cả hoặc không, lỗi một sự kiện trả ERR-10-105 kèm `failedIndex`. Gọi lặp cùng `id` trong 24 giờ trả lại đúng kết quả cũ, không ghi lại.

**API-10-080, 081 Kéo và xác nhận (HTTT)**

```http
GET /event/v1/subscriptions/ht-thue-dn-cap-phep/events?max=100&waitSeconds=20
```

```http
HTTP/1.1 200 OK

{"events": [{"specversion": "1.0", "id": "01JD3Y8K2M9P3Q7R4T6V8W0Y2Z", "source": "/t68/systems/HT-DKKD",
             "type": "vn.datahub.dkkd.doanh-nghiep.da-cap-phep", "subject": "0312345678", "dhtenant": "T68",
             "dataschema": "/apis/registry/v3/groups/t68/artifacts/t68.dkkd.doanh-nghiep.da-cap-phep.v1/versions/3",
             "data": {"maDoanhNghiep": "0312345678", "loaiThayDoi": "CAP_MOI", "phienBan": 1}}],
 "cursor": "eyJzIjoiaHQtdGh1ZS1kbi1jYXAtcGhlcCIs….c2lnbmF0dXJl", "leaseExpiresAt": "2026-11-26T09:16:02+07:00"}
```

```http
POST /event/v1/subscriptions/ht-thue-dn-cap-phep/events:ack

{"cursor": "eyJzIjoiaHQtdGh1ZS1kbi1jYXAtcGhlcCIs….c2lnbmF0dXJl"}
```

Phản hồi 204. Mỗi subscription có một lease; kéo lại trước khi ack và trước `leaseExpiresAt` trả đúng lô cũ; hết lease không ack thì lô được trả lại ở lượt sau (at-least-once). Cursor ký HMAC bằng khóa của tenant ở OpenBao `kv/dh/{tenant}/event/runtime/cursor`, không giả được và không dùng được cho subscription khác (ERR-10-109). Valkey ngừng thì cổng kéo trả 503 ERR-10-121 kèm `Retry-After: 5` (SDD §4.7).

**API-10-064 Đề nghị phát lại theo thời gian (TO)**

```http
POST /api/event/v1/replays
Idempotency-Key: t68-replay-ht-thue-2011-2111

{"subscriptionCode": "ht-thue-dn-cap-phep", "replayMode": "REDELIVER_RANGE", "rangeType": "TIME",
 "fromTime": "2026-11-20T00:00:00+07:00", "toTime": "2026-11-21T23:59:59+07:00", "ratePerSecond": 500,
 "reason": "Hệ thống thuế lỗi xử lý 20–21/11, cần nhận lại.", "acknowledgeDuplicates": true}
```

Phản hồi 201 là `ReplayRequest` `PENDING_APPROVAL` với `estimatedRecords` và `approvalRequestCode`. Khoảng ngoài lưu giữ trả ERR-10-033 kèm `availableRange` theo phân vùng:

```json
{"type": "https://datahub.gov.vn/errors/ERR-10-033", "title": "Khoảng phát lại không hợp lệ hoặc ngoài lưu giữ",
 "status": 422, "code": "ERR-10-033", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
 "availableRange": [{"partition": 0, "fromOffset": 120400, "toOffset": 182311}]}
```

**API-10-054 Xoay khóa ký**

```http
POST /api/event/v1/subscriptions/ht-thue-dn-cap-phep/signing-keys:rotate
If-Match: W/"5"
Idempotency-Key: t68-rotate-ht-thue-20261126

{"reason": "Xoay định kỳ 12 tháng."}
```

```http
HTTP/1.1 200 OK
Cache-Control: no-store

{"subscriptionCode": "ht-thue-dn-cap-phep", "keyId": "k-20261126", "status": "ACTIVE", "activatedAt": "2026-11-26T09:15:02+07:00",
 "previousUntil": "2026-12-03T09:15:02+07:00", "secret": "whsec_VI-DU-CHI-HIEN-MOT-LAN"}
```

`secret` chỉ có ở phản hồi này, không ghi log, không lưu PostgreSQL (BR-10-027). Khóa cũ sang `PREVIOUS` và mọi lượt giao mang hai chữ ký `v1` trong `10.push.key-rotation-overlap-days` ngày.

**API-10-071 PH-04 kiểm tra quyền của luồng**

```http
POST /api/event/v1/permissions:check
Authorization: Bearer <token dh-integration, scope event:permission-check>

{"environment": "PROD", "items": [
  {"flowCode": "dkkd-dong-bo-thue", "topicName": "t68.dkkd.doanh-nghiep.da-cap-phep.v1", "action": "SUBSCRIBE"},
  {"flowCode": "dkkd-dong-bo-thue", "topicName": "t68.thue.ma-so-thue.da-cap.v1", "action": "PUBLISH"}]}
```

Phản hồi 200 trả từng bộ: bộ thứ nhất `ALLOWED` với `consumerGroup = dh-flow-t68-dkkd-dong-bo-thue`; bộ thứ hai `DENIED` với `reason = NO_GRANT`. API không ném lỗi theo từng bộ; PH-04 ánh xạ thành WARN hoặc ERROR theo môi trường (FR-10-069, VR-10 của PH-04).

### 3.3. Ghi chú hiện thực theo operation

| Mã | Điểm cần chú ý |
|---|---|
| API-10-008 | `usableBy=flow:{flowCode}&action=SUBSCRIBE` trả topic `ACTIVE` (và `DEPRECATED` khi luồng đã có subscription) kèm phiên bản lược đồ hiện hành để DataMapper đọc cấu trúc |
| API-10-009 | Một operation, hai cách gọi: người (`projectCode`, `domain`, `entity`, `eventName`, ghép tên theo BR-10-002) và máy (`topicKind`, `topicName` đầy đủ). Người dùng gửi `topicKind` khác `BUSINESS` hoặc gửi `topicName` trả ERR-10-003 |
| API-10-015 | Một đề nghị đổi nhiều trường được tách thành phần áp dụng ngay (tăng lưu giữ, tăng `maxMessageBytes`) và phần cần duyệt (`TOPIC_CHANGE`); phản hồi nêu cả hai |
| API-10-020 | Cấu hình mẫu cho Java, .NET, Python, Node.js (serde Apicurio, OAUTHBEARER); không có bí mật; listener `external` chỉ hiện khi tenant bật |
| API-10-024 | `Accept: application/octet-stream` tải nội dung lược đồ (`.avsc` hoặc JSON Schema) |
| API-10-026 | Kiểm tra không phải lỗi khi không tương thích: trả 200 với `compatibilityReport.compatible = false`; lỗi chỉ trả ở `:submit` (ERR-10-016) |
| API-10-051 | Gọi riêng để thử endpoint trước khi đề nghị; kết quả `FAILED` vẫn là 200. Trong API-10-047, 049 thì `FAILED` thành ERR-10-027 |
| API-10-062 | Tất cả hoặc không; loại bỏ theo bộ lọc chạy nền (FR-00-054) chưa có ở API này, xem §10.2 |
| API-10-073 | `since={configVersion}` trả phần đổi (`full = false`); `If-None-Match` khớp trả 304; `dh-runtime` giữ ảnh chụp ở Valkey để chạy tiếp khi control plane ngừng (SDD §4.12) |
| API-10-084 | `registryPath` chứa `/`; APISIX chuyển nguyên phần sau `/registry/` tới Apicurio 3 (`apis/registry/v3/...`, `apis/ccompat/v7/...`), plugin kiểm OPA để chỉ trả artifact của topic mà token có scope. OpenAPI không biểu diễn được tham số nhiều đoạn nên mô tả bằng một tham số và ghi rõ (Q10-57) |
| API-10-085 | Một dòng `delivery_stat` mỗi (subscription, phút), gửi lặp ghi đè cùng giá trị; bộ giao nhận đệm 15 phút khi control plane ngừng (SDD §4.10) |
| API-10-086, 119 | `DELIVERY_BLOCKED` không tự tiếp tục; API-10-119 chỉ nhận subscription `SUSPENDED` với `suspendSource = CIRCUIT_BREAKER` |
| API-10-015, 064 | `dryRun=true` chạy đủ kiểm tra rồi trả 200 (`TopicChangeResult` với `impactedSubscriptions`; `ReplayEstimate` với `estimatedRecords`, `estimatedDurationSeconds`, `availableRange`) mà không ghi gì, không tạo yêu cầu duyệt; lỗi kiểm tra trả như gọi thật |
| API-10-120 | Khóa ký đầu tiên sinh lúc duyệt, ghi OpenBao, chưa hiện cho ai; `signingKeyPending = true` tới khi nhận. Chỉ một lần, không `Idempotency-Key`, phản hồi `Cache-Control: no-store`. Người nhận không còn ở đơn vị thì người có `PERM-10-subscribe` trên bên nhận xoay khóa (API-10-054) |
| API-10-089 | Chỉ trả nội dung mục thuộc lượt phát lại `RUNNING` có `replayCode` đã cho; nội dung topic `RESTRICTED`, `SENSITIVE` giải mã phong bì bằng `transit/dh-{tenant}-event-dlq` |

## 4. Danh mục sự kiện

### 4.1. Sự kiện của PH-10 (EVT-10-01…16)

Sự kiện ghi vào `ph10_event.outbox_event` cùng giao dịch nghiệp vụ, Debezium đưa lên Kafka trên topic `{tenant}.event.{thực-thể}.{sự-kiện}.v1` (FRS A.7). CloudEvents 1.0 nhị phân: `ce_type = vn.datahub.event.{thực-thể}.{sự-kiện}`, `ce_source = /{tenant}/services/dh-integration`, `ce_subject` bằng khóa phân vùng, `dhtenant`. Topic là `SYSTEM` của PH-10, tự đăng ký khi khởi tạo tenant (FR-10-067), 3 phân vùng, lưu giữ 7 ngày (giả định theo mức của PH-05, Q10-58), lược đồ JSON Schema ở Apicurio mức BACKWARD.

<!-- gen:events:start -->
| Mã | Topic | Khi nào | Khóa | Payload | Bên nhận | FR |
|---|---|---|---|---|---|---|
| EVT-10-01 | `{tenant}.event.topic.activated.v1` | Topic sang `ACTIVE`. | `topicName` | `TopicActivated` | PH-04, PH-05, PH-02, PH-13 | 009, 066 |
| EVT-10-02 | `{tenant}.event.topic.changed.v1` | Cấu hình topic, mức tương thích, trạng thái phiên bản lược đồ đổi. | `topicName` | `TopicChanged` | dh-runtime, PH-04, PH-13 | 011, 012, 021, 022 |
| EVT-10-03 | `{tenant}.event.topic.deprecated.v1` | Topic sang `DEPRECATED` (kèm kế nhiệm, `sunsetAt`). | `topicName` | `TopicDeprecated` | PH-04, PH-02, PH-18 | 014, 015, 068 |
| EVT-10-04 | `{tenant}.event.topic.retired.v1` | Topic sang `RETIRED`. | `topicName` | `TopicRetired` | PH-04, PH-05, PH-02, PH-13 | 014 |
| EVT-10-05 | `{tenant}.event.schema.version-enabled.v1` | Phiên bản lược đồ `ENABLED`. | `topicName` | `SchemaVersionEnabled` | dh-runtime, PH-04, PH-05, PH-15 | 009, 019, 068 |
| EVT-10-06 | `{tenant}.event.publication.activated.v1` | Publication `ACTIVE`. | `publicationCode` | `PublicationActivated` | PH-04, PH-13 | 031 |
| EVT-10-07 | `{tenant}.event.publication.state-changed.v1` | Tạm ngừng, tiếp tục, thu hồi publication. | `publicationCode` | `PublicationStateChanged` | PH-04, PH-13, PH-18 | 028, 029, 032 |
| EVT-10-08 | `{tenant}.event.subscription.activated.v1` | Subscription `ACTIVE`. | `subscriptionCode` | `SubscriptionActivated` | dh-runtime, PH-04, PH-13 | 037 |
| EVT-10-09 | `{tenant}.event.subscription.state-changed.v1` | Tạm dừng, tiếp tục, tạm ngừng, thu hồi, đổi tham số có hiệu lực. | `subscriptionCode` | `SubscriptionStateChanged` | dh-runtime, PH-04, PH-13, PH-18 | 039, 041, 046, 047 |
| EVT-10-10 | `{tenant}.event.subscription.lag-alerted.v1` | `alertState` đổi mức (cả khi về `OK`). | `subscriptionCode` | `LagAlerted` | PH-13, PH-18 | 055 |
| EVT-10-11 | `{tenant}.event.delivery.dead-lettered.v1` | Có mục DLQ mới (gộp 1 phút theo subscription). | `subscriptionCode` | `DeadLettered` | PH-18, PH-13 | 049 |
| EVT-10-12 | `{tenant}.event.replay.completed.v1` | Lượt phát lại `COMPLETED`, `FAILED`, `CANCELLED`. | `replayCode` | `ReplayCompleted` | PH-18, PH-13 | 052, 053 |
| EVT-10-13 | `{tenant}.event.signing-key.rotated.v1` | Xoay, thu hồi khóa ký. Không mang giá trị khóa. | `subscriptionCode` | `SigningKeyRotated` | dh-runtime, PH-13 | 042 |
| EVT-10-14 | `{tenant}.event.compliance.violated.v1` | Vi phạm lược đồ của bên phát Kafka trực tiếp vượt ngưỡng trong 15 phút. | `publicationCode` | `ComplianceViolated` | PH-13, PH-18 | 023 |
| EVT-10-15 | `{tenant}.event.migration.cut-over.v1` | Ánh xạ di trú chuyển hẳn hoặc quay lui. | `mappingId` | `MigrationCutOver` | PH-13, PH-18 | 075 |
| EVT-10-16 | `{tenant}.event.bridge.state-changed.v1` | Cầu nối di trú đổi trạng thái (`RUNNING`, `STOPPED`, `ERROR`, `EXPIRED`, `REJECTED`). | `bridgeCode` | `BridgeStateChanged` | PH-13, PH-18 | 073, 074 |
<!-- gen:events:end -->

Người nhận xử lý lũy đẳng: inbox theo (`consumer`, `ce_id`) và bỏ qua sự kiện có `configVersion` nhỏ hơn bản đang giữ (`dh-runtime` dùng cách này cho EVT-10-02, 08, 09). Không sự kiện nào mang giá trị khóa ký, nội dung sự kiện nghiệp vụ hay dữ liệu cá nhân. Ví dụ EVT-10-09 khi ngắt mạch:

```text
key: ht-thue-dn-cap-phep
headers: ce_specversion=1.0, ce_id=01JD3Z5Q8R2S4T6V8W0X2Y4Z6A, ce_source=/t68/services/dh-integration,
         ce_type=vn.datahub.event.subscription.state-changed, ce_subject=ht-thue-dn-cap-phep, dhtenant=T68
value: {"tenantId": "T68", "subscriptionCode": "ht-thue-dn-cap-phep", "topicName": "t68.dkkd.doanh-nghiep.da-cap-phep.v1",
        "previousStatus": "ACTIVE", "status": "SUSPENDED", "suspendSource": "CIRCUIT_BREAKER",
        "suspendReason": "Tỷ lệ lỗi ≥ 50% liên tục 30 phút.", "changedFields": [], "configVersion": 4183}
```

Sự kiện PH-10 tiêu thụ (FRS §8.2): EVT-05-11 `{tenant}.adapter.cdc.schema-changed.v1` (FR-10-068); EVT-04-09 `{tenant}.integration.flow.retired.v1` (FR-10-029); sự kiện đổi trạng thái HTTT của PH-01, giả định `{tenant}.connect.system.state-changed.v1` (Q10-17); sự kiện khởi tạo, tạm ngừng tenant của PH-20 (FR-10-064). Nhóm tiêu thụ theo A.8: `dh-svc-dh-integration-{tenant}-{consumer}` cho từng bộ tiêu thụ inbox.

### 4.2. Kênh giao ĐẨY webhook (PUSH)

Kênh `webhookDelivery` ở AsyncAPI mô tả yêu cầu `POST` của bộ giao nhận webhook (`dh-runtime`, ADR-071) tới `push.endpointUrl`. Hai thông điệp: `webhookStructured` (`CLOUDEVENTS_STRUCTURED`, thân `application/cloudevents+json`) và `webhookBinary` (`CLOUDEVENTS_BINARY`, thuộc tính ở tiêu đề `ce-*`, thân là `data` JSON).

| Tiêu đề | Giá trị | Ghi chú |
|---|---|---|
| `Webhook-Id` | `ce_id` của sự kiện | Giữ nguyên khi thử lại và khi phát lại; bên nhận chống trùng theo giá trị này (BR-10-009) |
| `Webhook-Timestamp` | Giây Unix lúc ký | Bên nhận từ chối khi lệch quá `10.push.signature-tolerance-seconds` (mặc định 300) |
| `X-Datahub-Signature` | `t={ts},v1={hex}` hoặc `t={ts},v1={hex},v1={hex}` | `hex = HMAC-SHA256(secret, "{Webhook-Id}.{Webhook-Timestamp}.{body}")`, `body` là byte thân đúng như gửi; hai `v1` trong thời gian xoay khóa (ADR-044) |
| `X-Datahub-Subscription` | `subscriptionCode` | |
| `X-Datahub-Attempt` | 1, 2, … | Lần giao của sự kiện này |
| `X-Datahub-Key-Id` | `keyId` của khóa `ACTIVE` | Bên nhận chọn khóa khi giữ nhiều khóa |
| `X-Datahub-Replay` | `replayCode` | Chỉ khi giao từ lượt phát lại |
| `traceparent` | W3C | Nối tiếp từ bên phát |

Bộ giao nhận chỉ gửi HTTPS TLS ≥ 1.2 qua egress gateway, không theo chuyển hướng, ghim IP đã kiểm cho từng kết nối (chống DNS rebinding, BR-10-026). Phân loại kết quả: `2xx` thành công; `408`, `425`, `429`, `5xx`, quá `timeoutMs`, lỗi mạng là lỗi tạm thời (ERR-10-111, 112), thử lại giãn dần theo FR-10-039 và tôn trọng `Retry-After`; `4xx` khác là vĩnh viễn, vào DLQ ngay (ERR-10-113); `410 Gone` vào DLQ và tạm ngừng subscription; lỗi TLS ERR-10-114; đích bị chặn ERR-10-115. Không đọc được khóa ký thì tạm dừng phân vùng (ERR-10-117), không bao giờ gửi không ký.

Mã mẫu xác minh phía bên nhận (Python, các ngôn ngữ khác ở tài liệu hướng dẫn tích hợp của PH-15):

```python
import hmac, hashlib, time

def verify(headers: dict, body: bytes, secrets: list[str], tolerance: int = 300) -> bool:
    ts = int(headers["Webhook-Timestamp"])
    if abs(time.time() - ts) > tolerance:
        return False
    parts = dict(p.split("=", 1) for p in headers["X-Datahub-Signature"].split(",") if p.startswith("t="))
    if int(parts["t"]) != ts:
        return False
    sigs = [p[3:] for p in headers["X-Datahub-Signature"].split(",") if p.startswith("v1=")]
    msg = f'{headers["Webhook-Id"]}.{ts}.'.encode() + body
    for s in secrets:                       # khóa ACTIVE và PREVIOUS trong thời gian xoay
        mac = hmac.new(s.encode(), msg, hashlib.sha256).hexdigest()
        if any(hmac.compare_digest(mac, v) for v in sigs):
            return True
    return False
```

Kênh `webhookHandshake` mô tả bắt tay xác minh (FR-10-036, API-10-051): `OPTIONS` với `WebHook-Request-Origin: event.{tenant}.datahub` và `WebHook-Request-Rate`; endpoint trả `200` hoặc `204` với `WebHook-Allowed-Origin` khớp hoặc `*` trong `push.timeoutMs`. HTTT cũ không sửa được để trả lời bắt tay dùng ngoại lệ API-10-091 (≤ 180 ngày), thay bằng một `POST` sự kiện kiểm tra `vn.datahub.event.subscription.verification` có ký như sự kiện thường.

### 4.3. Topic nghiệp vụ và topic DLQ

Kênh `businessTopic` (địa chỉ `{tenant}.{domain}.{entity}.{eventName}.v{majorVersion}`) là mẫu chung cho mọi topic do PH-10 cấp phát; lược đồ cụ thể nằm ở Apicurio (`groupId = {tenant}`, `artifactId = {topicName}`, ADR-070), không lặp trong AsyncAPI. Thông điệp theo FRS §4.9: khóa là giá trị `partitionKeyField` khi `KEY_HASH`; tiêu đề `ce_id`, `ce_source`, `ce_type`, `ce_specversion`, `ce_time`, `ce_subject`, `ce_dataschema`, `traceparent`, `dhtenant`; giá trị có tiền tố định danh lược đồ (byte 0 và 4 byte `contentId`). Topic CDC của PH-05 theo cùng kênh với địa chỉ `{tenant}.cdc.{adapterCode}.{schema}.{table}.v1` (bốn đoạn giữa, BR-10-002).

| Listener | Bên dùng | Xác thực | Ghi chú |
|---|---|---|---|
| `internal` (9093) | DU, `dh-runtime`, Kafka Connect, luồng PH-04 | mTLS, principal `CN=…` | ACL theo tiền tố tenant do PH-10 sinh vào `dh-config-{tenant}` (ADR-072) |
| `external` (9093 qua TSLCD) | HTTT `KAFKA_NATIVE` khi `10.external-kafka.enabled` | SASL OAUTHBEARER (principal theo `azp`) hoặc mTLS | Nhóm tiêu thụ bắt buộc `dh-ext-{tenant}-{subscriptionCode}`; serde Apicurio đọc lược đồ qua API-10-084 |
| `replication` | MirrorMaker 2 sang site DR | mTLS | Ngoài phạm vi API |

Kênh `deadLetterTopic` (`{topicName}.dlq`) giữ bản tin gốc nguyên vẹn kèm tiêu đề `dh_dlq_subscription`, `dh_dlq_source_partition`, `dh_dlq_source_offset`, `dh_dlq_error_code`, `dh_dlq_attempts`, `dh_dlq_first_failed_at`, `dh_dlq_origin`, `dh_dlq_bridge` (FRS A.8). Năm nguồn ghi và `origin` tương ứng: bộ giao nhận `PUSH`, cổng kéo khi nack `PULL_NACK`, API-10-083 `EXTERNAL_REPORT`, bộ phát lại `REPLAY`, cầu nối `BRIDGE`. `DlqIngestor` (nhóm `dh-svc-dh-integration-{tenant}`) lưu bền vào `dlq_entry`, `dlq_payload`; HTTT không đọc topic DLQ trực tiếp mà xem qua API-10-060, 061, 103.

## 5. Hợp đồng với phân hệ khác và bên ngoài

| Bên | Hướng | Hợp đồng | Ghi chú |
|---|---|---|---|
| PH-04 | PH-04 → PH-10 | API-10-071 (`EventPermissionApi.check`), 008 (`usableBy`), 072 (`ensureParty`), 109 (`dependenciesOf`, cho API-04-016) | Trong tiến trình khi cùng DU; REST với scope `event:permission-check`, ngắt mạch 5 giây khi tách DU (SDD §3.3). PH-10 không khả dụng thì PH-04 chặn gửi duyệt luồng (ERR-10-029) |
| PH-04 | Luồng ↔ Kafka | Topic đã đăng ký; nhóm `dh-flow-{tenant}-{flow}`; sự kiện PH-04 phát lên `{tenant}.integration.{đối tượng}.{động từ}.v1` (topic `SYSTEM`) | BR-04-009, VR-10; tenant lấy từ tiền tố topic |
| PH-04 | PH-04 → PH-10 | EVT-04-09 luồng ngừng dùng | Thu hồi publication, subscription của bên `FLOW` (FR-10-029) |
| PH-05 | PH-05 → PH-10 | API-10-009 (`topicKind = CDC`), 023 (phiên bản lược đồ), 018 (phiên bản chính mới), scope `event:topic-register`; EVT-05-11 | Một topic mỗi bảng `{topicPrefix}.{schema}.{table}.v1`, Avro; tự duyệt, trả 202 ≤ 2 giây. Kết nối `kafka-external` của PH-05 là Kafka ngoài, không qua PH-10 |
| PH-05 | PH-10 → PH-05 | EVT-10-01, 04, 05 | PH-05 theo dõi cấp phát và phiên bản lược đồ |
| PH-07 | HTTT ↔ PH-10 | Topic `{tenant}.rdm.*` đăng ký máy (`SYSTEM`); HTTT đề nghị subscription qua API-10-047, nhận scope `topic:{tên}:subscribe` | Miền `rdm` dành riêng |
| PH-01 | PH-10 đọc | HTTT tồn tại, `ACTIVE`, cấp độ ATTT (ERR-10-021, 051); sự kiện đổi trạng thái HTTT (Q10-17) | Tạm ngừng theo PH-01 đặt `suspendSource = PH01` |
| PH-12 | PH-10 → Keycloak, OPA | Cấp, gỡ scope `topic:*` ở client HTTT; dữ liệu quyền OPA cho APISIX; chứng thư khách mTLS do CA nội bộ cấp | Gỡ OPA trước, hiệu lực ≤ 60 giây (NFR-10-009) |
| PH-13 | PH-10 → PH-13 | Kiểm toán qua outbox; EVT-10-07, 09…16; chỉ số `dh_event_*` OTLP; API-10-055, 066 cho bảng điều khiển | Biểu đồ CPU, bộ nhớ cụm Kafka thuộc PH-13 (LGC-HUB-005, 006) |
| PH-18 | PH-18 ↔ PH-10 | API-10-060, 061 (`event:dlq-read`), 063, 064, 104 (`event:replay`); EVT-10-07, 09, 10, 11, 12, 14, 15, 16 | Màn xử lý lỗi chung ở PH-18 dùng cùng API; PH-10 chỉ giữ DLQ tầng sự kiện theo topic |
| PH-20 | PH-20 → PH-10 | Sự kiện khởi tạo, tạm ngừng tenant | Tạm ngừng tenant: lệnh ghi trả ERR-10-039 |
| PH-02, PH-15 | PH-10 → PH-02, PH-15 | EVT-10-01, 03, 04, 05 | Danh mục dịch vụ sự kiện; tài liệu cổng nhà phát triển, mã mẫu xác minh chữ ký |
| Apicurio Registry 3 | PH-10 ghi; HTTT đọc | Artifact `groupId = {tenant}`, `artifactId = {topicName}`, quy tắc tương thích theo topic (ADR-070); đường chỉ đọc API-10-084 | HTTT, luồng không có quyền ghi registry (`auto.register=false`) |
| Strimzi, Argo CD | PH-10 → Git | `KafkaTopic`, `KafkaUser` trong `dh-config-{tenant}` (`kafka/topics/`, `kafka/users/`), ACL theo tiền tố tenant (ADR-072) | Không qua API này; trạng thái thấy qua `provisioningCommit`, `provisioningError` |
| OpenBao | `dh-integration` ghi; `dh-runtime` đọc | `kv/dh/{tenant}/event/subscriptions/{subscriptionCode}/signing`, `transit/dh-{tenant}-event-dlq`, `kv/dh/{tenant}/event/runtime/cursor` | Không qua API này |
| Hub Pulsar cũ | Cầu nối ↔ Pulsar | API-10-075 (kiểm kê), 113…116, 078, 117, 118 | Kết nối nguồn tới Pulsar khai ở PH-05 (ADR-073) |

## 6. Bảng mã lỗi ERR-10

Ý nghĩa và HTTP theo FRS §8.1 (nạp tự động từ FRS khi sinh, không chép tay). Cột "API phát sinh" sinh từ `x-datahub-errors` của OpenAPI; mã chung (001, 003, 007, 037, 039, 049, 101, 102) ghi số lượng.

<!-- gen:errors:start -->
### 6.1. Control plane (ERR-10-001…054)

| Mã | HTTP | Ý nghĩa | API phát sinh (API-10-) |
|---|---|---|---|
| ERR-10-001 | 404 | Không tìm thấy đối tượng hoặc đối tượng thuộc tenant khác | 78 API |
| ERR-10-002 | 409 | Mã hoặc tên đã tồn tại (kể cả đối tượng đã lưu trữ, ngừng dùng) | 002, 009, 033, 038 |
| ERR-10-003 | 400 | Dữ liệu yêu cầu không hợp lệ (mẫu mã, từ dành riêng, trường bất biến, tổ hợp không hợp lệ) | 65 API |
| ERR-10-004 | 422 | Tên topic sai quy ước hoặc dùng miền dành riêng | 009 |
| ERR-10-005 | 422 | Tiền tố tenant của topic không khớp tenant ngữ cảnh | 009 |
| ERR-10-006 | 409 | Chuyển trạng thái không hợp lệ với trạng thái hiện tại | 54 API |
| ERR-10-007 | 412 | Xung đột phiên bản (`If-Match`) | Chung |
| ERR-10-008 | 403 | Vi phạm bốn mắt | 059, 101, 121 |
| ERR-10-009 | 400 | Thiếu lý do, ý kiến hoặc xác nhận bắt buộc | 34 API |
| ERR-10-010 | 409 | Còn đối tượng phụ thuộc (topic trong dự án, subscription trên topic) | 005, 017 |
| ERR-10-011 | 422 | Vượt hạn mức tenant | 002, 009, 012, 015, 018, 043, 047, 059, 107 |
| ERR-10-012 | 422 | Tham số vượt trần hoặc ngoài miền | 009, 011, 015, 049, 091, 107, 108, 113 |
| ERR-10-013 | 422 | Không được giảm số phân vùng | 015 |
| ERR-10-014 | 409 | Cần xác nhận tác động thứ tự khi tăng phân vùng | 015 |
| ERR-10-015 | 422 | Lược đồ sai cú pháp | 009, 012, 018, 023, 025, 026, 027 |
| ERR-10-016 | 409 | Lược đồ không tương thích theo mức đã đặt | 023, 027, 059 |
| ERR-10-017 | 422 | Lược đồ thiếu hoặc sai kiểu trường khóa phân vùng | 009, 012, 018, 023, 025, 027 |
| ERR-10-018 | 422 | Lược đồ có trường nghi dữ liệu cá nhân bị chặn theo chính sách | 009, 012, 018, 023, 025, 027 |
| ERR-10-019 | 422 | Mức tương thích không được phép | 015 |
| ERR-10-020 | 422 | Định dạng lược đồ không được phép hoặc khác định dạng đã có | 009, 023, 025 |
| ERR-10-021 | 422 | HTTT không tồn tại hoặc không `ACTIVE` ở PH-01 | 033, 038 |
| ERR-10-022 | 422 | Luồng không tồn tại hoặc không hợp lệ ở PH-04 | 033, 038, 072 |
| ERR-10-023 | 422 | DU nội bộ không có trong danh sách | 033, 038 |
| ERR-10-024 | 409 | Quan hệ đã tồn tại cho cặp này (bên tham gia, topic) hoặc cặp (HTTT, kiểu giao tiếp) | 033, 038, 043, 047, 072 |
| ERR-10-025 | 422 | Topic hoặc bên tham gia không ở trạng thái nhận quan hệ mới | 043, 047, 072, 096, 113 |
| ERR-10-026 | 422 | Endpoint webhook không hợp lệ (không HTTPS, địa chỉ riêng, ngoài egress) | 047, 049, 051, 064 |
| ERR-10-027 | 422 | Xác minh endpoint thất bại hoặc đã quá hạn | 047, 049, 051, 064 |
| ERR-10-028 | 422 | Kafka ngoài chưa được bật cho tenant | 047 |
| ERR-10-029 | 503 | Phụ thuộc không khả dụng (Apicurio, Kafka Admin, Git, Keycloak, OpenBao, PH-01, PH-04) | 13 API |
| ERR-10-030 | 422 | Số worker vượt số phân vùng hoặc trần | 047, 049 |
| ERR-10-031 | 422 | Thời điểm bắt đầu ngoài khoảng lưu giữ | 047 |
| ERR-10-032 | 409 | Subscription phải `PAUSED` trước khi đặt lại offset | 064 |
| ERR-10-033 | 422 | Khoảng phát lại không hợp lệ hoặc ngoài lưu giữ | 064 |
| ERR-10-034 | 422 | Khoảng phát lại vượt trần số bản ghi | 064 |
| ERR-10-035 | 409 | Đang có lượt phát lại khác cho subscription | 064 |
| ERR-10-036 | 409 | Mục DLQ đã được xử lý | 062, 064 |
| ERR-10-037 | 422 | Khóa idempotency trùng với thân khác | 17 API |
| ERR-10-038 | 409 | Cấp phát thất bại hoặc chưa hoàn tất | 013, 014, 059 |
| ERR-10-039 | 423 | Tenant đang tạm ngừng hoặc đóng băng thay đổi | 64 API |
| ERR-10-040 | 422 | Tệp nhập sai cấu trúc hoặc phiên bản định dạng | 075, 111 |
| ERR-10-041 | 422 | Ánh xạ di trú không hợp lệ | 078, 111, 112, 113 |
| ERR-10-042 | 409 | Đã có cầu nối cho topic hoặc cầu nối ngược chiều | 113, 115, 116 |
| ERR-10-043 | 422 | Không tắt được mục danh mục đang dùng | 105, 106 |
| ERR-10-044 | 403 | Đối tượng ngoài phạm vi tổ chức của người dùng | 14 API |
| ERR-10-045 | 422 | Topic `CDC`, `SYSTEM` chỉ do tài khoản dịch vụ chủ quản sửa | 011, 015, 016, 017, 018, 023 |
| ERR-10-046 | 422 | Thiếu khóa phân vùng hoặc tổ hợp thứ tự, định tuyến không hợp lệ | 009, 011, 015 |
| ERR-10-047 | 409 | Thay đổi cần phiên bản topic mới, hoặc topic kế nhiệm đã tồn tại | 015, 018 |
| ERR-10-048 | 422 | Compaction đòi topic có khóa | 009, 011, 015 |
| ERR-10-049 | 400 | Tham số truy vấn sai (kích thước trang, khoảng thời gian, quá số nút sơ đồ) | 21 API |
| ERR-10-050 | 422 | Đối tượng tham chiếu trong tệp nhập không tồn tại ở tenant đích | 075, 111 |
| ERR-10-051 | 422 | Bên phát, bên nhận chưa đạt cấp độ ATTT yêu cầu cho topic `RESTRICTED`, `SENSITIVE` (BR-10-019) | 043, 047, 059 |
| ERR-10-052 | 422 | Thao tác không áp dụng cho chế độ giao nhận của subscription (tạm dừng, tiếp tục subscription `INTERNAL`) | 050, 098 |
| ERR-10-053 | 401 | Control plane: token thiếu, không hợp lệ hoặc hết hạn | 115 API |
| ERR-10-054 | 403 | Control plane: thiếu quyền `PERM-10-*` hoặc scope dịch vụ cho thao tác (khác ERR-10-008 bốn mắt, ERR-10-044 ngoài phạm vi tổ chức) | 115 API |

### 6.2. Data plane và runtime (ERR-10-101…121)

Mã có HTTP trả qua cổng sự kiện hoặc API nội bộ; mã không có HTTP (111…120) không trả cho bên gọi mà ghi ở `DeliveryFailure.errorCode`, `DlqEntry.errorCode`, tiêu đề `dh_dlq_error_code` và chỉ số.

| Mã | HTTP | Ý nghĩa | Nơi phát sinh |
|---|---|---|---|
| ERR-10-101 | 401 | Data plane: token không hợp lệ hoặc hết hạn | 079, 080, 081, 082, 083, 084 |
| ERR-10-102 | 403 | Data plane: thiếu scope hoặc quan hệ phát, nhận không `ACTIVE` | 079, 080, 081, 082, 083, 084 |
| ERR-10-103 | 404 | Topic không tồn tại, không `ACTIVE`, `DEPRECATED` hoặc khác tenant | 079, 084 |
| ERR-10-104 | 400 | Sự kiện không phải CloudEvents 1.0 hợp lệ hoặc `source` không thuộc bên phát | 079 |
| ERR-10-105 | 422 | Dữ liệu không khớp lược đồ, thiếu khóa khi bắt buộc | 079 |
| ERR-10-106 | 413 | Sự kiện hoặc lô vượt kích thước | 079, 083 |
| ERR-10-107 | 429 | Vượt hạn mức phát hoặc kéo | 079, 080, 083 |
| ERR-10-108 | 503 | Không đủ bản sao đồng bộ, từ chối ghi | 079 |
| ERR-10-109 | 409 | Cursor hết hiệu lực hoặc không khớp lease | 081, 082 |
| ERR-10-110 | 409 | Subscription không `ACTIVE` khi kéo | 080, 081, 082, 083 |
| ERR-10-111 | — | Đầu nhận quá thời gian chờ (ghi ở lượt lỗi, DLQ) | Lượt giao, DLQ (`errorCode`): Tạm thời, thử lại |
| ERR-10-112 | — | Đầu nhận trả lỗi `5xx`, `408`, `425`, `429` | Lượt giao, DLQ (`errorCode`): Tạm thời, thử lại |
| ERR-10-113 | — | Đầu nhận từ chối vĩnh viễn (`4xx`) hoặc bên nhận nack | Lượt giao, DLQ (`errorCode`): Vĩnh viễn, DLQ ngay |
| ERR-10-114 | — | Lỗi TLS hoặc chứng thư đầu nhận | Lượt giao, DLQ (`errorCode`): Tạm thời; lặp lại thì cảnh báo ATTT |
| ERR-10-115 | — | Địa chỉ đích bị chặn (địa chỉ riêng, DNS rebinding, ngoài egress) | Lượt giao, DLQ (`errorCode`): An ninh, DLQ ngay |
| ERR-10-116 | — | Không giải tuần tự được bản tin theo lược đồ | Lượt giao, DLQ (`errorCode`): Giải tuần tự, DLQ ngay |
| ERR-10-117 | — | Không đọc được khóa ký từ OpenBao | Lượt giao, DLQ (`errorCode`): Tạm dừng phân vùng, không gửi không ký |
| ERR-10-118 | — | Cầu nối di trú không chuyển được bản tin | Lượt giao, DLQ (`errorCode`): DLQ của cầu nối |
| ERR-10-119 | — | Bản tin của bên phát Kafka trực tiếp không có định danh lược đồ hợp lệ | Lượt giao, DLQ (`errorCode`): Tuân thủ lược đồ (chỉ số, EVT-10-14) |
| ERR-10-120 | — | Kafka từ chối do ACL hoặc hạn mức (ghi nhận theo principal) | Lượt giao, DLQ (`errorCode`): Chỉ số theo principal |
| ERR-10-121 | 503 | Phụ thuộc runtime không khả dụng (Valkey cho lease, Apicurio khi bộ đệm lược đồ rỗng, OpenBao cho khóa cursor); kèm `Retry-After` | 079, 080, 081, 082 |
<!-- gen:errors:end -->

### 6.3. Trường mở rộng của phản hồi lỗi

| Mã | Trường bổ sung | Ví dụ `detail` |
|---|---|---|
| ERR-10-003 | `errors[]` (`field`, `rule`, `message`) | "`moi` là từ dành riêng của route, không dùng làm mã dự án." |
| ERR-10-007 | `currentEtag` | "Đối tượng đã đổi sau khi bạn mở; tải lại để xem phiên bản 7." |
| ERR-10-010 | `dependents[]` (`kind`, `code`, `status`) | "Dự án còn 2 topic đang hoạt động." |
| ERR-10-015…018 | `errors[]` với `field` là đường dẫn trong lược đồ | "Trường khóa phân vùng `maDoanhNghiep` không có trong lược đồ." |
| ERR-10-029, 107, 121 | `retryAfterSeconds` và tiêu đề `Retry-After` | "Kho lược đồ tạm thời không khả dụng; yêu cầu chưa được ghi." |
| ERR-10-031, 033 | `availableRange[]` (`partition`, `fromOffset`, `toOffset`) | "Dữ liệu trước 19/11/2026 đã hết lưu giữ." |
| ERR-10-105 | `failedIndex`, `errors[]` | "Sự kiện thứ 3 của lô thiếu trường bắt buộc." |

Thông điệp không bao giờ lặp lại nội dung sự kiện, giá trị khóa ký hay thân phản hồi của đầu nhận; `responseSnippet` ở lượt lỗi đã cắt 512 byte và che theo SEC-32.

## 7. Kiểm tra hợp đồng trong CI

| Kiểm | Công cụ | Cổng |
|---|---|---|
| OpenAPI 3.1 hợp lệ; mọi ví dụ yêu cầu, phản hồi, lỗi, lược đồ khớp lược đồ; mỗi operation có `x-datahub-id` duy nhất, `x-datahub-fr`, `x-datahub-permission`, `x-datahub-errors`; lệnh ghi có `If-Match`, lệnh tạo có `Idempotency-Key`; mọi mã ERR ở `x-datahub-errors` có ở FRS và mã HTTP của nó có trong `responses` | [`check_contracts.py`](ph10/tools/check_contracts.py) (`openapi-spec-validator`, `jsonschema` 2020-12) | CI-5 |
| Không trường bí mật ngoài `SigningKeyIssued.secret`; trường này `readOnly` | `check_contracts.py` | CI-5 |
| AsyncAPI 3.0: kênh, operation, thông điệp tham chiếu đúng; ví dụ khớp payload và tiêu đề | `check_contracts.py`; `@asyncapi/parser` 3 | CI-5 |
| Lint quy ước | `@redocly/cli lint` (bộ luật `recommended`); Spectral với bộ luật dự án khi có | CI-5 |
| Thay đổi phá vỡ trong `v1` | oasdiff `breaking` so với `main` | CI-5 |
| Enum, trường, ERR, EVT, PERM, scope, đường dẫn API-10-001…091 khớp FRS | [`doi_chieu_frs.py`](ph10/tools/doi_chieu_frs.py) | CI-5 |
| Tệp sinh khớp nguồn | Chạy lại `gen_openapi.py`, `gen_asyncapi.py`, `gen_md.py`, rồi `git diff --exit-code` | CI-5 |
| Mã API, EVT, ERR khớp tài liệu gốc | `build/tools/kiem_tra_ma.py` | CI-1 |

Kết quả chạy ngày 26/11/2026 trên máy viết tài liệu:

| Kiểm | Kết quả |
|---|---|
| `check_contracts.py` | OpenAPI hợp lệ, 121 operation, 121 mã; 267 ví dụ khớp; AsyncAPI 20 kênh, 38 operation, 21 thông điệp, 44 ví dụ khớp; 0 lỗi |
| `@redocly/cli` 1.25 `lint` | Hợp lệ; 1 cảnh báo `no-server-example.com` (máy chủ `localhost` cho phát triển cục bộ, giữ chủ ý) |
| `@asyncapi/parser` 3.3 | 0 lỗi, 0 cảnh báo |
| Spectral | Không cài trong môi trường viết; chạy ở CI-5 |
| `doi_chieu_frs.py` | 91 mã FRS §8.3 khớp phương thức và đường dẫn; enum A.2 có đủ; ERR, EVT, PERM, scope không lệch; trường, enum chỉ có ở API liệt kê đủ ở §10.1 |

Lệnh chạy lại:

```bash
cd datahub-docs/03-thiet-ke/api/ph10
python3 tools/gen_openapi.py && python3 tools/gen_asyncapi.py && python3 tools/gen_md.py
python3 tools/check_contracts.py && python3 tools/doi_chieu_frs.py
npx @redocly/cli@1.25.0 lint openapi-event.yaml
```

## 8. Ánh xạ từ hệ cũ

### 8.1. Hub Pulsar (LGC-HUB) và Bus

| Mã | Chức năng hệ cũ | API, sự kiện mới | Ghi chú |
|---|---|---|---|
| LGC-HUB-001…004 | Dashboard đếm publisher, subscriber, project, topic | API-10-066 (`counts`) | Giữ, thêm phân rã theo trạng thái |
| LGC-HUB-005, 006 | Biểu đồ % Memory, % CPU | Không có ở PH-10 | Thuộc PH-13; dashboard có liên kết sang |
| LGC-HUB-007 | Sơ đồ kết nối publisher, topic, subscriber | API-10-007 (`overlay` `LAG`, `TRAFFIC`, `DLQ`), 055 | Lọc theo dự án, HTTT |
| LGC-HUB-008 | Quản lý project | API-10-001…006 | Không xóa cứng, thay bằng lưu trữ |
| LGC-HUB-009 | Quản lý topic: tên, mô tả, phân vùng, cấu trúc, định tuyến | API-10-008…031 | "Cấu trúc" thành lược đồ bắt buộc ở Apicurio |
| LGC-HUB-010 | Quản lý publisher: tên, kiểu giao tiếp, khóa tham chiếu | API-10-032…036, 092, 093 | `referenceKey`, `commType`; gắn HTTT PH-01 |
| LGC-HUB-011 | Quản lý subscriber, đánh dấu là luồng | API-10-037…041, 094, 095 | `partyType = FLOW` thay cờ "là luồng" |
| LGC-HUB-012 | Quản lý publication | API-10-042…045, 096, 097, 059 | Thêm duyệt bốn mắt, scope, ACL |
| LGC-HUB-013 | Quản lý subscription: URI nhận, số worker, số lần thử lại, thời điểm bắt đầu | API-10-046…056, 091, 098…100; kênh `webhookDelivery`; API-10-080…083 | `push.endpointUrl`, `workerCount`, `maxRetries`, `startPosition`, `startAt`; thêm ký HMAC, kéo API, Kafka ngoài |
| LGC-HUB-014 | Danh mục `type_of_comm`, `routing_mode` | API-10-067, 068, 105, 106 | `legacyCode` để di trú |
| LGC-TOOL-010 | Nhóm Message Broker | API-10-071, 072, 009 (`SYSTEM`); kênh `businessTopic` qua listener `internal` | Broker ngoài ở PH-05 FR-05-035 |
| LGC-BUS-039 | Document message và event message | API-10-079, 080; kênh `businessTopic`, `webhookDelivery` | Event message bất đồng bộ qua PH-10; document message đồng bộ ở PH-04 |

Di trú dữ liệu cấu hình Hub dùng API-10-075 (`sourceKind = PULSAR_HUB`), 110, 111, 076, 112; chạy song song bằng cầu nối API-10-113…115, 090; chuyển hẳn và quay lui API-10-078, 116; đối chiếu và tiến độ API-10-117, 118; sự kiện EVT-10-15, 16.

### 8.2. API M5 của SRS repo

SRS repo `docs/07-srs/SRS-PH-10-event.md` §M5 mô tả đường quản trị `/api/admin/v1/events` và Schema Registry `/apis/registry/v2`. Các đường này chưa có mã chạy; bảng dưới để người đọc SRS cũ tìm đường mới.

| Đường cũ (SRS repo) | Đường mới | Ghi chú |
|---|---|---|
| `GET`, `POST /api/admin/v1/events/topics` | API-10-008, 009 | Có dự án, lược đồ bắt buộc, duyệt |
| `PATCH /api/admin/v1/events/topics/{name}`, `POST …/partitions` | API-10-011, 015 | Tăng phân vùng qua đề nghị thay đổi |
| `GET …/topics/{name}/partitions` | API-10-055 (lag theo phân vùng), 010 | Chi tiết phân vùng cụm ở PH-13 |
| `GET …/cluster/health`, `POST …/cluster/rebalance` | Không có | PH-13 và vận hành nền tảng (D03-09 §6.4) |
| `GET …/consumer-groups`, `…/{name}/lag` | API-10-046, 055 | Nhóm tiêu thụ gắn với subscription |
| `POST …/replay`, `GET …/replay/{id}` | API-10-064, 104 | Có duyệt; bỏ chế độ sao chép sang chủ đề tạm |
| `GET …/connectors`, `POST …/connectors/{name}/restart` | Không có ở PH-10 | CDC thuộc PH-05 (ADR-059) |
| `GET …/dlt` | API-10-060 | DLQ theo topic, lưu bền |
| `/apis/registry/v2/groups/lgsp/artifacts…` | API-10-021…030 (quản trị), 084 (đọc) | Apicurio 3, `groupId` theo tenant; ghi registry chỉ qua control plane |
| Cấu trúc sự kiện chung `eventId`, `eventType`, `traceId`, `payload` | CloudEvents 1.0 (`id`, `type`, `traceparent`, `data`) | FRS §4.9, CC-API-04 |

## 9. Truy vết FR → API

Mỗi FR-10 có ít nhất một API, một kênh AsyncAPI hoặc ghi rõ nơi xử lý. Bảng sinh từ cột FR của `spec.py`.

<!-- gen:fr:start -->
| FR | Tên | API (API-10-) |
|---|---|---|
| FR-10-001 | Liệt kê, tìm kiếm và lọc dự án tích hợp | 001 |
| FR-10-002 | Xem chi tiết dự án | 003 |
| FR-10-003 | Tạo dự án tích hợp | 002 |
| FR-10-004 | Sửa dự án | 004 |
| FR-10-005 | Lưu trữ và khôi phục dự án | 005, 006 |
| FR-10-006 | Liệt kê, tìm kiếm và lọc topic | 008 |
| FR-10-007 | Xem chi tiết topic | 010, 020 |
| FR-10-008 | Tạo topic và gửi duyệt | 009, 011, 012 |
| FR-10-009 | Duyệt tạo topic và cấp phát trên cụm | 057, 058, 059, 101, 102 |
| FR-10-010 | Theo dõi cấp phát và xử lý cấp phát thất bại | 013, 014 |
| FR-10-011 | Tăng số phân vùng của topic đang hoạt động | 015 |
| FR-10-012 | Thay đổi lưu giữ và chính sách dọn (compaction) | 015 |
| FR-10-013 | Chế độ định tuyến và khóa phân vùng | 015 |
| FR-10-014 | Ngừng khuyến nghị và ngừng dùng topic | 011, 016, 017 |
| FR-10-015 | Tạo phiên bản chính mới của topic khi thay đổi phá vỡ | 018 |
| FR-10-016 | Theo dõi chuyển đổi bên nhận sang phiên bản topic mới | 019 |
| FR-10-017 | Soạn và kiểm tra lược đồ | 023, 025, 026 |
| FR-10-018 | Kiểm tra tương thích với các phiên bản đã có | 026 |
| FR-10-019 | Gửi duyệt và duyệt phiên bản lược đồ | 027, 057, 058, 059, 101, 102 |
| FR-10-020 | Xem lịch sử phiên bản, so sánh và tải lược đồ | 021, 022, 024, 030 |
| FR-10-021 | Đặt mức tương thích của lược đồ | 015 |
| FR-10-022 | Ngừng khuyến nghị và vô hiệu phiên bản lược đồ | 028, 029 |
| FR-10-023 | Giám sát tuân thủ lược đồ của bên phát Kafka trực tiếp | 031 |
| FR-10-024 | Cung cấp tra cứu lược đồ cho bên ngoài | 020, 084 |
| FR-10-025 | Liệt kê bên phát và bên nhận | 032, 034, 037, 039 |
| FR-10-026 | Đăng ký bên phát | 033 |
| FR-10-027 | Đăng ký bên nhận | 038 |
| FR-10-028 | Sửa, tạm ngừng, tiếp tục và ngừng dùng bên phát, bên nhận | 035, 036, 040, 041, 092, 093, 094, 095 |
| FR-10-029 | Đồng bộ trạng thái với PH-01 và PH-04 | Tiêu thụ sự kiện PH-01, EVT-04-09 (§5); kết quả thấy qua API-10-034, 039 (`suspendSource = PH01`) |
| FR-10-030 | Đề nghị publication | 042, 043, 044 |
| FR-10-031 | Duyệt publication, cấp scope OAuth và ACL Kafka | 057, 058, 059, 101, 102 |
| FR-10-032 | Tạm ngừng, tiếp tục và thu hồi publication | 045, 096, 097 |
| FR-10-033 | Phát sự kiện qua API phát | 079 |
| FR-10-034 | Phát sự kiện trực tiếp qua Kafka | 020; Kafka trực tiếp: kênh `businessTopic` ở AsyncAPI; cấu hình mẫu qua API-10-020 |
| FR-10-035 | Đề nghị subscription | 046, 047, 048 |
| FR-10-036 | Xác minh endpoint webhook | 051, 091 |
| FR-10-037 | Duyệt subscription và cấp phát nhóm tiêu thụ | 057, 058, 059, 101, 102, 120 |
| FR-10-038 | Giao nhận ĐẨY: webhook ký HMAC | 073; Kênh `webhookDelivery` ở AsyncAPI; cấu hình qua API-10-073 |
| FR-10-039 | Thử lại giãn dần và chính sách khi thất bại | 086, 119 |
| FR-10-040 | Điểm bắt đầu và offset bắt đầu | Trường `startPosition`, `startAt` của API-10-047; đổi sau khi chạy bằng API-10-064 (`RESET_OFFSET`) |
| FR-10-041 | Tạm dừng, tiếp tục subscription | 050, 098 |
| FR-10-042 | Xoay khóa ký webhook | 054, 100, 120 |
| FR-10-043 | Giao nhận KÉO qua API | 073, 080, 081, 082 |
| FR-10-044 | Giao nhận KÉO qua Kafka listener ngoài | 083; Kênh `businessTopic` qua listener `external`; báo lỗi qua API-10-083 |
| FR-10-045 | Giao nhận nội bộ cho luồng và DU | Subscription `INTERNAL` qua API-10-047, 072 |
| FR-10-046 | Sửa tham số subscription | 049 |
| FR-10-047 | Thu hồi subscription | 099 |
| FR-10-048 | Lọc sự kiện và gộp lô khi đẩy | Đợt sau; chưa có trường ở FRS (§10.2) |
| FR-10-049 | Chuyển sự kiện giao thất bại vào DLQ tầng sự kiện | Kênh `deadLetterTopic`; xem qua API-10-060, 061; EVT-10-11 |
| FR-10-050 | Tra cứu, xem và loại bỏ mục DLQ | 060, 061, 062, 103 |
| FR-10-051 | Đề nghị và duyệt phát lại theo khoảng offset hoặc thời gian | 057, 058, 059, 064, 101, 102 |
| FR-10-052 | Thực thi, theo dõi và hủy lượt phát lại | 063, 065, 087, 088, 104 |
| FR-10-053 | Phát lại mục DLQ | 064, 088, 089 |
| FR-10-054 | Thu thập consumer lag | 055 |
| FR-10-055 | Cảnh báo lag và nhóm tiêu thụ ngừng tiến | 056 |
| FR-10-056 | Thống kê giao nhận và lượt giao gần đây | 048, 052, 053, 085 |
| FR-10-057 | Dashboard sự kiện | 066 |
| FR-10-058 | Sơ đồ kết nối tương tác | 007 |
| FR-10-059 | Xuất số liệu sang PH-13 | Chỉ số OTLP sang PH-13, không qua API này |
| FR-10-060 | Danh mục kiểu giao tiếp | 067, 105 |
| FR-10-061 | Danh mục chế độ định tuyến | 068, 106 |
| FR-10-062 | Hạn mức theo tenant và phân bổ cho bên tham gia | 069, 107 |
| FR-10-063 | Tham số phân hệ theo tenant | 070, 108 |
| FR-10-064 | Cách ly đa tenant trên trục sự kiện | Tiền tố tenant kiểm ở mọi API (ERR-10-005, 103) |
| FR-10-065 | Kiểm toán và lịch sử thay đổi | Kiểm toán qua outbox sang PH-13; tab Lịch sử đọc API của PH-13 (FR-00-043) |
| FR-10-066 | Đăng ký topic hộ PH-05 cho CDC | 009 |
| FR-10-067 | Đăng ký topic cho DU nội bộ và topic nền tảng | 009 |
| FR-10-068 | Xử lý thông báo thay đổi lược đồ CDC | 018, 023 |
| FR-10-069 | Kiểm tra quyền phát, nhận cho PH-04 và tra cứu topic cho trình thiết kế | 008, 071, 072, 109 |
| FR-10-070 | Xuất khai báo | 074 |
| FR-10-071 | Nhập khai báo có xem trước | 075, 110, 111, 121 |
| FR-10-072 | Nhập kiểm kê Pulsar và lập ánh xạ | 075, 076, 110, 111, 112 |
| FR-10-073 | Cầu nối Pulsar sang Kafka tạm thời | 077, 090, 113, 114, 115 |
| FR-10-074 | Cầu nối ngược Kafka sang Pulsar cho bên nhận cũ chưa chuyển | 077, 090, 113, 114, 115 |
| FR-10-075 | Đối chiếu, chuyển hẳn và quay lui | 078, 116, 117 |
| FR-10-076 | Báo cáo tiến độ di trú | 118 |
<!-- gen:fr:end -->

## 10. Đề nghị bổ sung cho FRS

### 10.1. Trường và enum chỉ có ở API

Bảng dưới sinh bằng `gen_md.py`: tên trường, giá trị enum dùng trong OpenAPI, AsyncAPI mà không xuất hiện ở FRS. Bản 0.1 liệt kê 91 trường và 6 giá trị enum (trường cấu trúc phản hồi, trường sự kiện như `previousStatus`, `changedFields`, `configVersion`); đã xử lý ở FRS bản 0.3: FRS hấp thụ nguyên tên vào A.3 (bảng "Trường chỉ ở API") và A.2.15, nên bảng hiện trống. `doi_chieu_frs.py` báo lỗi nếu có trường mới mà bảng này chưa liệt kê.

<!-- gen:proposals:start -->
Không còn trường, enum nào chỉ có ở API: FRS bản 0.3 đã hấp thụ đủ vào A.2.15, A.3.
<!-- gen:proposals:end -->

### 10.2. Đề nghị khác

Các đề nghị dưới đây và ở §10.1, §10.3 đã xử lý ở FRS bản 0.3 (D02-03-PH10 §14); tập này đã sửa theo: ERR-10-053, 054 thay 101, 102 ở control plane; API-10-121 hủy tác vụ nhập; `legalBasis` 10…1.000 ký tự; miền `retryBackoff.multiplier` 1…5; mặc định `failurePolicy` theo `orderingRequired`. Mục 4 (loại bỏ DLQ theo bộ lọc) để Đợt sau, MVP giữ danh sách ≤ 1.000 mục.

| Số | Đề nghị | Lý do | Nơi sửa |
|---|---|---|---|
| 1 | Cập nhật §8.3: mỗi dòng một operation theo bảng §3.1 (API-10-092…119) và thêm dòng API-10-120 `POST /subscriptions/{subscriptionCode}/signing-keys:claim` | Khuôn K-API đòi mỗi operation một mã | FRS §8.3 |
| 2 | Mã lỗi chung cho control plane: 401 token, 403 thiếu `PERM-10-*` (hiện tạm dùng ERR-10-101, 102) | Dải 001…099 chưa có mã xác thực, quyền chung; PH-04 có ERR-04-044, 045 | FRS §8.1 |
| 3 | API hủy tác vụ nhập ở `VALIDATING`, `PREVIEW` (FR-10-071 cho phép người tạo hủy) | FRS §8.3 chưa có dòng; tập này không tự cấp | FRS §8.3, rồi tập API cấp mã kế tiếp |
| 4 | Loại bỏ mục DLQ theo bộ lọc chạy nền (FR-10-050, FR-00-054) | API-10-062 hiện chỉ nhận danh sách ≤ 1.000 mục | FRS §8.3 |
| 5 | Đầu vào duyệt dùng `comment` (FR-10-009) và lưu `decisionComment` (A.3); đề nghị A.3 ghi rõ ánh xạ | Tránh hai tên cho một trường | FRS A.3 |
| 6 | Bỏ `decision` (A.2.10) khỏi đầu vào vì API tách `:approve`, `:reject` | Không còn trường nào nhận `APPROVE`, `REJECT` | FRS A.2.10 |
| 7 | Lưu giữ, số phân vùng của topic `{tenant}.event.*` (tạm 7 ngày, 3 phân vùng) | FRS §7.2 chưa nêu | FRS §7.2 (Q10-58) |
| 8 | FR-10-048 (lọc, gộp lô, Đợt sau) cần tên trường `filters`, `batchSize`, `batchWaitMs` ở A.3 trước khi thêm vào API | FR đã nêu `batchSize`, `batchWaitMs` nhưng phụ lục chưa có | FRS A.3 |
| 9 | Kiểu node, cạnh của sơ đồ (`PUBLISHER`, `TOPIC`, `SUBSCRIBER`; `PUBLICATION`, `SUBSCRIPTION`) và bước xác minh (`DNS`, `TLS`, `HANDSHAKE`, `TEST_EVENT`) vào A.2.15 | Enum chỉ ở API | FRS A.2.15 |
| 10 | CSDL D03-03-PH10 kiểm `push.endpointVerification` trong `ck_subscription_push`, còn FRS A.3 và API dùng `push.lastVerification` | Lệch tên khóa JSON giữa CSDL và FRS | D03-03-PH10 DDL (luồng CSDL sửa) |
| 11 | Thêm `Cache-Control: no-store` bắt buộc cho phản hồi API-10-054, 100 vào BR-10-027 | Khóa ký chỉ hiển thị một lần | FRS BR-10-027 |

### 10.3. Đề nghị của tập màn hình D03-06-PH10 (Phụ lục B)

Đã xử lý ở FRS bản 0.3: các trường mới dưới đây vào FRS A.3, `dryRun` vào A.3, enum bước xác minh vào A.2.15.

| Số | Đề nghị | Xử lý ở tập này |
|---|---|---|
| B1 | `allowedActions` ở `GET` chi tiết | Nhận: thêm `allowedActions` (mảng chuỗi, không phải enum) vào `Project`, `Topic`, bên phát, bên nhận (`PartyBase`), `Publication`, `Subscription`, `ApprovalRequest`, `ReplayRequest`. Chỉ để ẩn nút, máy chủ vẫn kiểm |
| B2 | Chia dashboard API-10-066 thành khối, mỗi khối có `available` | Nhận một phần: `Dashboard` đã có khối `counts`, `traffic`, `lag`, `dlq`, `pendingApprovals`, `deprecatedSoon`, `failedTopics`, `quotaUsage`. Chỉ `traffic` dựa vào nguồn ngoài (PH-13) và trả null khi nguồn lỗi; không thêm cờ `available` cho khối tính từ `ph10_event` |
| B3 | Trường sơ đồ API-10-007 | Nhận: đã có `nodes[].dlqNewCount`, `nodes[].partyType`, `edges[].alertState`; thêm `edges[].dlqNewCount`, `edges[].commType` và `metricsCollectedAt` (thay cho `stats.collectedAt`, giữ phẳng) |
| B4 | `dryRun` cho API-10-015 | Nhận: tham số truy vấn `dryRun`, trả 200 `TopicChangeResult` không ghi |
| B5 | Lọc API-10-046 theo `alertState`, `deliveryMode`, `subscriberCode`, `topicName`, `projectCode`; sắp theo `lagSeconds` | Đã có đủ bộ lọc; sắp `sort=lagSeconds,desc` dùng tham số `sort` chung |
| B6 | Trạng thái worker và cờ khóa ký chờ nhận ở API-10-048 | Nhận một phần: thêm `signingKeyPending` (đổi tên từ `signingSecretPending` để không trùng luật chặn trường bí mật). Không nhận trạng thái worker vì là dữ liệu chạy của `dh-runtime`; tab Worker dùng API-10-055 (offset, lag theo phân vùng) và API-10-052 (lần giao cuối) |
| B7 | Đường lấy khóa ký đầu tiên (FR-10-037 bước 6) | Nhận: API-10-120 `POST /subscriptions/{subscriptionCode}/signing-keys:claim` (§3.3); đề nghị FRS thêm vào §8.3 (§10.2 mục 1) |
| B8 | Chạy thử API-10-064 | Nhận: `dryRun` trả 200 `ReplayEstimate` |
| B9 | Miễn xác minh khi tạo subscription | Không nhận thay đổi API: miễn chỉ làm sau khi tạo, qua API-10-091 trên subscription `PENDING_APPROVAL`, vì miễn cần lý do và quyền `PERM-10-admin` khác người đề nghị. Trả lời Q10-31 của tập màn hình |
| B10 | `steps[]` có mã bước cố định, `detail`, `validUntil` ở API-10-051 | Nhận: `steps[].name` đã là enum `DNS`, `TLS`, `HANDSHAKE`, `TEST_EVENT` và có `detail`; thêm `validUntil` (hết 24 giờ hiệu lực xác minh) |

Tham số `dryRun` và các trường mới (`allowedActions`, `signingKeyPending`, `validUntil`, `metricsCollectedAt`, `estimatedDurationSeconds`, `commType` ở cạnh sơ đồ) chưa có ở FRS và được liệt kê ở §10.1 để FRS hấp thụ.

## 11. Câu hỏi mở

> **Câu hỏi mở Q10-55:** Khi tách `dh-integration` thành DU riêng cho PH-10, API máy với máy (API-10-071, 072, 109) có đi qua `apisix-int` không, hay chỉ mTLS mesh trong cụm. Đề xuất tạm: chỉ mesh, không qua APISIX, giống Q05-61 của PH-05.

> **Câu hỏi mở Q10-56:** API kéo (API-10-080) có cần trả `application/cloudevents-batch+json` thay cho bao `events[]` để HTTT dùng thư viện CloudEvents chuẩn không. Đề xuất tạm: giữ bao JSON vì cần `cursor`, `leaseExpiresAt`; xem lại khi Đợt sau mở kéo song song theo phân vùng (Q10-16).

> **Câu hỏi mở Q10-57:** API-10-084 dùng một tham số đường dẫn nhiều đoạn (`registryPath`) mà OpenAPI không biểu diễn chuẩn. Có nên liệt kê tường minh các đường Apicurio v3 và `ccompat/v7` mà HTTT được dùng (khoảng 6 đường đọc) với mã API riêng không. Đề xuất tạm: giữ một mã, mô tả danh sách đường cho phép trong plugin APISIX và tài liệu PH-15.

> **Câu hỏi mở Q10-58:** Lưu giữ và số phân vùng của topic sự kiện `{tenant}.event.*` chưa có ở FRS. Tập này giả định 7 ngày, 3 phân vùng theo mức của PH-05 (EVT-05), đủ cho `dh-runtime` dựng lại cấu hình sau sự cố dài nhất dự kiến (giả định GĐ-07). Cần FRS chốt ở §7.2.

> **Câu hỏi mở Q10-59:** Có cần một webhook "ping" chủ động định kỳ (không phải bắt tay xác minh) để phát hiện endpoint hỏng trước khi có sự kiện thật với subscription lưu lượng thấp không. Đề xuất tạm: không ở MVP; ngắt mạch và cảnh báo lag `STALLED` đủ, xem lại sau thí điểm.

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung | Người thực hiện |
|---|---|---|---|
| 0.1 | 26/11/2026 | Bản đầu theo khuôn K-API trên FRS 0.2: 120 operation (API-10-001…091 theo FRS, 092…119 tách dòng gộp, 120 theo đề nghị của tập màn hình), EVT-10-01…16, kênh webhook PUSH ký HMAC, kênh mẫu topic nghiệp vụ và DLQ; OpenAPI 3.1, AsyncAPI 3.0 sinh từ bảng mã, đã kiểm hợp đồng và đối chiếu FRS | Nhóm viết tài liệu (Claude) |
| 0.2 | 26/11/2026 | Theo FRS 0.3: ERR-10-053, 054 cho 401, 403 control plane (data plane giữ 101, 102); API-10-121 `POST /imports/{jobCode}:cancel`; `legalBasis` 10…1.000 ký tự, `multiplier` 1…5, mặc định `failurePolicy` theo `orderingRequired`, ràng buộc ngưỡng lag; §10.1 trống vì FRS đã hấp thụ 91 trường, 6 enum; sinh lại OpenAPI, AsyncAPI và bảng, kiểm hợp đồng và đối chiếu FRS sạch | Nhóm viết tài liệu (Claude) |
