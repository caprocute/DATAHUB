---
ma_tai_lieu: D03-04-PH08
ten: Đặc tả API và sự kiện phân hệ PH-08 Chất lượng dữ liệu
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-data, kỹ sư tích hợp PH-04 và PH-06, kiểm thử viên, hội đồng thẩm định
phan_he: PH-08
mo_ta: Hợp đồng REST gồm 132 operation gốc /api/dq/v1 và 14 sự kiện phát, 8 sự kiện tiêu thụ của PH-08 Chất lượng dữ liệu, kèm quy ước, quyền, scope máy, mã lỗi RFC 9457, thông báo hiển thị, kiểm tra hợp đồng và đề nghị đồng bộ.
tai_lieu_lien_quan: D02-03-PH08 FRS; D03-03-PH08 CSDL; D03-04-PH06; D03-04-PH07; D03-04-PH04; D05-02-PH08 Test case
---

# D03-04-PH08 · Đặc tả API và sự kiện Chất lượng dữ liệu

## Tóm tắt cho hội đồng thẩm định

Tập này là hợp đồng giao tiếp của PH-08 Chất lượng dữ liệu: nơi sở ngành tự đo sáu chiều chất lượng (đầy đủ, chính xác, nhất quán, kịp thời, duy nhất, hợp lệ) trên bản ghi vàng PH-06, danh mục PH-07, bảng của HTTT và bản tin luồng PH-04, rồi giao phiếu khắc phục cho chủ quản và lập báo cáo kỳ, báo cáo năm. PH-08 công bố **132 operation REST** gốc `/api/dq/v1` (module `dq` của `dh-data`), **14 sự kiện** `EVT-08-01…14` và nhận 8 sự kiện của PH-06, PH-07. Mã API-08-001…131 giữ đúng phương thức và đường dẫn của FRS 0.2 mục 9.4 (129 là `POST /findings:search`, 130 và 131 bật, tắt đo tăng dần).

Hợp đồng máy đọc được, sinh từ một nguồn và đã kiểm:

- [`ph08/openapi-dq.yaml`](ph08/openapi-dq.yaml): OpenAPI 3.1, 229 lược đồ, mỗi operation có ví dụ yêu cầu (khi có thân) và phản hồi; 221 ví dụ khớp lược đồ theo [`check_contracts.py`](ph08/tools/check_contracts.py); `openapi-spec-validator` và `@redocly/cli lint` hợp lệ.
- [`ph08/asyncapi-dq.yaml`](ph08/asyncapi-dq.yaml): AsyncAPI 3.0, 22 kênh (14 phát, 8 nhận), 22 ví dụ khớp payload; `@asyncapi/cli validate` hợp lệ.

Bốn nguyên tắc hợp đồng:

1. **Kiểm tra trực tuyến nhanh, có chính sách khi lỗi.** `POST /checks:evaluate` trả kết luận trong 40 ms (p95 ≤ 50 ms); khi phụ thuộc lỗi, đối tượng đo quyết định `FAIL_OPEN` (cho qua, `degraded = true`) hay `FAIL_CLOSED` (503, 504).
2. **Không lộ giá trị dữ liệu.** Phản hồi chỉ có mã quy tắc, tên trường, giá trị đã che hoặc băm (trường Nhạy cảm chỉ băm); sự kiện chỉ mang mã, số đếm, điểm; khóa bản ghi cá nhân đi trong thân `POST`.
3. **Mọi lệnh tạo có `Idempotency-Key`, mọi lệnh sửa và hành động có `If-Match`;** duyệt theo bốn mắt (ERR-08-005).
4. **PH-08 không sửa dữ liệu nguồn.** Phiếu giao chủ quản; lỗi bản ghi vàng chuyển hàng đợi steward PH-06; đóng phiếu bằng lần đo kiểm chứng (`VERIFY`).

Căn cứ: FRS D02-03-PH08 §3.2, §9 và Phụ lục A; CSDL D03-03-PH08 (schema `ph08_dq`). Mọi tên miền, dữ liệu trong ví dụ là giả lập, tenant T68.

## 0. Giới thiệu

### 0.1. Mục đích

Tài liệu đặc tả mặt giao tiếp của PH-08 đủ để kỹ sư `dh-data` hiện thực, kỹ sư PH-04, PH-06, PH-16 tích hợp và kiểm thử viên viết ca kiểm thử hợp đồng.

### 0.2. Phạm vi

Gồm API REST của module `dq`, sự kiện Kafka phát và nhận, quyền, scope, mã lỗi. Không gồm lưu bản ghi vàng (PH-06), bảng mã (PH-07), che dữ liệu (PH-09), KPI tổng hợp (PH-16), điều phối luồng (PH-04), gửi thông báo (PH-13).

### 0.3. Người đọc

Kỹ sư `dh-data` đọc chương 1, 2, 11; kỹ sư PH-04, PH-06 đọc 3.1, 4, 5; kiểm thử viên đọc 6, 7, 10; hội đồng thẩm định đọc tóm tắt, chương 2 và Phụ lục A.

### 0.4. Thuật ngữ và chữ viết tắt

Bảng giải thích các thuật ngữ riêng của tập này.

| Thuật ngữ | Giải thích |
|---|---|
| Đối tượng đo (`assetCode`) | Thứ được đo: `MDM_DOMAIN`, `RDM_CATALOG`, `SOURCE_DATASET` hoặc `FLOW_MESSAGE` |
| Bộ quy tắc, phiên bản | Tập quy tắc theo chiều của một đối tượng đo; mỗi phiên bản bất biến sau khi duyệt |
| Lần đo (`scanId`) | Một lượt đo theo lô, chia thành tác vụ phân mảnh, cho ra ảnh chụp điểm |
| Bản ghi lỗi (finding) | Lỗi một bản ghi theo một quy tắc, có dấu vân tay `fingerprint` để biết mới, còn, hết |
| Pushdown | Dịch quy tắc tập hợp sang SQL chạy ngay ở CSDL nguồn (bản sao chỉ đọc) |
| CEL | Common Expression Language, ngôn ngữ biểu thức cho quy tắc mức bản ghi |
| CDE | Phần tử dữ liệu trọng yếu (critical data element) |
| `FAIL_OPEN`, `FAIL_CLOSED` | Chính sách khi phụ thuộc lỗi: cho qua kèm cờ, hoặc từ chối |
| DS, DA, DO, TA, TO, SO, PA | Vai trò theo D02-08: cán bộ dữ liệu, duyệt, chủ quản, quản trị tenant, vận hành, an ninh, quản trị nền tảng |

: Thuật ngữ và chữ viết tắt của tập API PH-08

### 0.5. Tài liệu tham chiếu

FRS D02-03-PH08 (nguồn chuẩn mã FR, ERR, EVT, PERM, enum), CSDL D03-03-PH08 (tên cột, camelCase ở API), D02-08 (ma trận quyền), D03-04-PH06 và D03-04-PH07 (bên phát sự kiện), `docs/07-srs/SRS-PH-08-dq.md` (mục 8).

### 0.6. Cấu trúc tài liệu

Chương 1, 2: quy ước và quyền; 3, 4, 5: endpoint, sự kiện, hợp đồng với phân hệ khác; 6, 7: mã lỗi và kiểm tra; 8, 9: hệ cũ và câu hỏi mở; 10: truy vết FR; 11: đặc tả từng endpoint; Phụ lục A: đề nghị đồng bộ.

## 1. Quy ước chung

Quy ước áp dụng cho mọi operation. Cột "Khóa" ở chương 3: `I` là bắt buộc `Idempotency-Key`, `M` là bắt buộc `If-Match`.

| Mục | Quy ước |
|---|---|
| Đường gốc | `/api/dq/v1`: BFF console của tenant, trong cụm `dh-data.dh-data.svc`, cổng API cho máy gọi. `/api/dq/v1/internal/*` (API-08-024) chỉ trong mạng nội bộ |
| Phiên bản | `v1`; thay đổi phá vỡ sang `v2`, chạy song song tối thiểu 6 tháng; oasdiff ở CI chặn thay đổi phá vỡ trong `v1` |
| Tenant | Lấy từ token (claim `tenant`), không từ thân hay đường dẫn; đối tượng của tenant khác trả `404` ERR-08-001 |
| Hành động | Hậu tố `:{hành-động}` trên tài nguyên hoặc tập (`:approve`, `:evaluate`) |
| Khóa lạc quan | `GET` trả `ETag: W/"{version}"`; `PUT`, `PATCH`, `DELETE` và hành động trên tài nguyên có `If-Match`; lệch trả `409` ERR-08-004, thiếu trả `428` ERR-00-428. Tạo mới bằng `PUT` khi chưa có tài nguyên: `If-Match: *` |
| Chống trùng | `POST` tạo hoặc chạy bất đồng bộ bắt buộc `Idempotency-Key` (UUID), giữ 24 giờ; cùng khóa cùng thân trả lại phản hồi cũ, khác thân `409` ERR-08-055. API trực tuyến 068, 069 không dùng, bên gọi dùng `correlationId` |
| Phân trang | `page` (từ 0), `size` (1…100, mặc định 20); phản hồi `items`, `page`, `size`, `totalElements`. Mọi danh sách có hai tham số này nên chương 11 không lặp lại |
| Lỗi | RFC 9457 `application/problem+json`, `type = https://datahub.gov.vn/errors/{code}`, `code`, `traceId`, `errors[]` theo trường |
| Mã lỗi chung | Mọi operation có thể trả `401`, `403` (ERR-00-401, ERR-00-403), ERR-08-001 (không thấy), ERR-08-003 (sai lược đồ), ERR-08-004 (xung đột), ERR-08-006 (sai trạng thái), ERR-08-045 (tham số danh sách sai), ERR-08-054 (503 dùng chung khi dịch vụ phụ thuộc hoặc kiểm toán không khả dụng); lệnh có `M` thiếu `If-Match` trả `428`. Chương 11 chỉ nêu mã riêng; ERR-08-055 nêu ở từng lệnh có `Idempotency-Key` |
| Tham số đường dẫn | Các `{…}` trong đường dẫn, kiểu chuỗi theo mẫu mã hoặc UUID, bắt buộc; chương 11 không lặp lại |
| Tác vụ dài | Hồ sơ, đo, xuất tệp trả `202` kèm tài nguyên ở trạng thái `QUEUED` hoặc `RUNNING`; theo dõi bằng `GET`, sự kiện EVT-08-02, 03 |
| Che dữ liệu | Giá trị trường Nhạy cảm (PH-09) chỉ là băm; trường Riêng tư che một phần; không phản hồi nào trả giá trị gốc của bản ghi |
| Truy vết, ngôn ngữ | `traceparent` W3C xuyên APISIX, BFF, `dh-data`, Kafka; `Accept-Language: vi` (mặc định) hoặc `en` |

: Quy ước chung của API PH-08

## 2. Xác thực và phân quyền

Người dùng vào qua BFF console bằng OIDC và PKCE (token không ra trình duyệt), quyền `PERM-08-*`. Máy gọi máy (PH-04, PH-06, PH-16, HTTT) dùng OAuth 2.1 `client_credentials` kèm mTLS, scope `dq.*`. PH-05 vào `/internal` qua mTLS mesh, chỉ `apisix-int`.

### 2.1. Quyền người dùng

Quyền theo FRS 3.2; cột "Quyền" ở chương 3 và `x-datahub-permission` là nguồn chi tiết; "a hoặc b" là có một trong hai.

| Quyền | Vai trò | Operation tiêu biểu |
|---|---|---|
| `PERM-08-read` | PA, TA, TO, SO, DS, DA, DO (○), VW (tổng hợp), AU | Mọi `GET` cấu hình, thẻ điểm, lần đo, báo cáo đã công bố, bảng điều khiển |
| `PERM-08-asset` | TA, DS | Miền, đối tượng đo, CDE, chạy hồ sơ (002…019) |
| `PERM-08-rule-admin` | PA (mẫu `COMMON`), TA, DS | Soạn quy tắc, trọng số, cảnh báo, gửi duyệt, cấu hình trực tuyến, đề nghị ngoại lệ |
| `PERM-08-approve` | DA | Duyệt, từ chối bộ quy tắc, trọng số, ngoại lệ, báo cáo; kích hoạt sớm; ký số |
| `PERM-08-run` | TA, TO, DS | Lịch, chạy, hủy, chạy lại lần đo; bật, tắt đo tăng dần (130, 131); xác nhận cảnh báo |
| `PERM-08-finding-read` | SO, DS, DA, DO (○) | Bản ghi lỗi đã che (073, 074, 078, 129), ngoại lệ |
| `PERM-08-remediate` | TA, DS, DO (○) | Phiếu khắc phục (084…096) |
| `PERM-08-report` | TA, DS | Soạn, sinh, xuất báo cáo |
| `PERM-08-export` | DS, DA | Xuất bản ghi lỗi; DO chấp thuận khi có trường Nhạy cảm (Phụ lục A) |
| `PERM-08-config` | TA, PA (trần) | Tham số tenant, lưu giữ |
| `PERM-08-audit-read` | SO, AU | Nhật ký kiểm toán (127) |

: Quyền người dùng

Quy tắc vượt quyền chức năng, máy chủ kiểm theo từng yêu cầu:

- **Bốn mắt**: người duyệt khác người gửi, kể cả DA có đủ quyền (ERR-08-005).
- **Phạm vi tổ chức**: DO chỉ thấy đối tượng, lỗi, phiếu của tổ chức mình; ngoài phạm vi trả ERR-08-032. VW không mở được danh sách bản ghi lỗi.
- **Chủ quản không tự xác nhận**: DO báo đã sửa, hệ thống đo kiểm chứng; DO tự xác nhận trả ERR-08-035.

### 2.2. Scope máy

Scope cấp ở Keycloak khi đăng ký client.

| Scope | Cấp cho | Operation | Ghi chú |
|---|---|---|---|
| `dq.check` | PH-04 (`dh-runtime`), PH-06 | 068, 069 | Kiểm tra trực tuyến; không có quyền người dùng |
| `dq.read` | PH-16, HTTT | 065, 066, 105, 106, 122 | Đọc điểm, thẻ điểm, KPI; HTTT chỉ thấy đối tượng của mình |
| `dq.ingest` | PH-05 (`dh-integration`) | 024 | Nhận chỉ số hồ sơ; FRS 0.2 đã nhận scope, D02-08 cần bổ sung |

: Scope máy

## 3. Danh mục endpoint

Danh mục sinh từ [`ph08/tools/spec.py`](ph08/tools/spec.py) bằng `gen_md.py`, cùng nguồn với OpenAPI. Cột "FR" bỏ tiền tố `FR-08-`; "HTTP" là mã thành công; "read hoặc dq.read" là người dùng có quyền đó hoặc máy có scope đó.

<!-- gen:endpoints:start -->
| Mã | Phương thức, đường dẫn | Quyền (PERM-08-) | FR | Khóa | HTTP |
|---|---|---|---|---|---|
| API-08-001 | `GET /domains` | read | 001 | - | 200 |
| API-08-002 | `POST /domains` | asset | 001 | I | 201 |
| API-08-003 | `GET /domains/{domainCode}` | read | 001 | - | 200 |
| API-08-004 | `PATCH /domains/{domainCode}` | asset | 001 | M | 200 |
| API-08-005 | `GET /assets` | read | 006 | - | 200 |
| API-08-006 | `POST /assets` | asset | 002, 003, 004 | I | 201 |
| API-08-007 | `GET /assets/{assetCode}` | read | 006 | - | 200 |
| API-08-008 | `PATCH /assets/{assetCode}` | asset | 002, 003, 004 | M | 200 |
| API-08-009 | `POST /assets/{assetCode}:activate` | asset | 002, 003, 004 | M | 200 |
| API-08-010 | `POST /assets/{assetCode}:suspend` | asset | 007 | M | 200 |
| API-08-011 | `POST /assets/{assetCode}:resume` | asset | 007 | M | 200 |
| API-08-012 | `POST /assets/{assetCode}:retire` | asset | 007 | M | 200 |
| API-08-013 | `GET /assets/{assetCode}/fields` | read | 005 | - | 200 |
| API-08-014 | `PUT /assets/{assetCode}/fields/{fieldPath}` | asset | 005 | M | 200 |
| API-08-015 | `POST /assets/{assetCode}/fields:sync-classification` | asset | 005 | - | 200 |
| API-08-016 | `GET /sources/mdm-domains` | asset | 002 | - | 200 |
| API-08-017 | `GET /sources/rdm-catalogs` | asset | 003 | - | 200 |
| API-08-018 | `POST /sources/connections/{connectionCode}:discover` | asset | 004 | - | 200 |
| API-08-019 | `POST /assets/{assetCode}/profile-runs` | asset | 008 | I | 202 |
| API-08-020 | `GET /assets/{assetCode}/profile-runs` | read | 008, 009 | - | 200 |
| API-08-021 | `GET /profile-runs/{runId}` | read | 008, 009 | - | 200 |
| API-08-022 | `GET /profile-runs/{runId}/columns` | read | 009 | - | 200 |
| API-08-023 | `POST /profile-runs/{runId}:suggest-rules` | rule-admin | 010 | - | 200 |
| API-08-024 | `POST /internal/profile-metrics` | `dq.ingest` | 011 | - | 202 |
| API-08-025 | `GET /rule-sets` | read | 022 | - | 200 |
| API-08-026 | `POST /rule-sets` | rule-admin | 012 | I | 201 |
| API-08-027 | `GET /rule-sets/{ruleSetCode}` | read | 012 | - | 200 |
| API-08-028 | `GET /rule-sets/{ruleSetCode}/versions` | read | 019 | - | 200 |
| API-08-029 | `POST /rule-sets/{ruleSetCode}/versions` | rule-admin | 012 | I | 201 |
| API-08-030 | `GET /rule-sets/{ruleSetCode}/versions/{version}` | read | 012, 019 | - | 200 |
| API-08-031 | `POST /rule-sets/{ruleSetCode}/versions/{version}/rules` | rule-admin | 010, 013, 014 | I | 201 |
| API-08-032 | `PUT /rule-sets/{ruleSetCode}/versions/{version}/rules/{ruleCode}` | rule-admin | 013, 014 | M | 200 |
| API-08-033 | `DELETE /rule-sets/{ruleSetCode}/versions/{version}/rules/{ruleCode}` | rule-admin | 013 | M | 204 |
| API-08-034 | `POST /rules:validate-expression` | rule-admin | 014 | - | 200 |
| API-08-035 | `GET /rule-templates` | read | 015 | - | 200 |
| API-08-036 | `POST /rule-templates` | rule-admin | 015 | I | 201 |
| API-08-037 | `POST /rule-sets/{ruleSetCode}/versions/{version}:dry-run` | rule-admin | 016 | - | 200 |
| API-08-038 | `POST /rule-sets/{ruleSetCode}/versions/{version}:submit` | rule-admin | 017 | M | 200 |
| API-08-039 | `POST /rule-sets/{ruleSetCode}/versions/{version}:approve` | approve | 017 | M | 200 |
| API-08-040 | `POST /rule-sets/{ruleSetCode}/versions/{version}:reject` | approve | 017 | M | 200 |
| API-08-041 | `POST /rule-sets/{ruleSetCode}/versions/{version}:activate` | approve | 018 | M | 200 |
| API-08-042 | `POST /rule-sets/{ruleSetCode}:retire` | rule-admin | 018 | M | 200 |
| API-08-043 | `GET /rule-sets/{ruleSetCode}/versions/{version}/diff` | read | 019 | - | 200 |
| API-08-044 | `POST /rule-sets/{ruleSetCode}:copy` | rule-admin | 020 | I | 201 |
| API-08-045 | `GET /rule-sets/{ruleSetCode}/versions/{version}/export` | rule-admin | 020 | - | 200 |
| API-08-046 | `POST /rule-sets:import` | rule-admin | 020 | I | 201 |
| API-08-047 | `GET /weight-configs` | read | 021 | - | 200 |
| API-08-048 | `POST /weight-configs` | rule-admin | 021 | I | 201 |
| API-08-049 | `PUT /weight-configs/{configId}` | rule-admin | 021 | M | 200 |
| API-08-050 | `POST /weight-configs/{configId}:submit` | rule-admin | 021 | M | 200 |
| API-08-051 | `POST /weight-configs/{configId}:approve` | approve | 021 | M | 200 |
| API-08-052 | `POST /weight-configs/{configId}:reject` | approve | 021 | M | 200 |
| API-08-053 | `GET /rules` | read | 022 | - | 200 |
| API-08-054 | `GET /schedules` | read | 023 | - | 200 |
| API-08-055 | `POST /schedules` | run | 023 | I | 201 |
| API-08-056 | `PATCH /schedules/{scheduleId}` | run | 023 | M | 200 |
| API-08-057 | `POST /schedules/{scheduleId}:pause` | run | 023 | M | 200 |
| API-08-058 | `POST /schedules/{scheduleId}:resume` | run | 023 | M | 200 |
| API-08-059 | `POST /scans` | run | 024, 054 | I | 202 |
| API-08-060 | `GET /scans` | read | 030 | - | 200 |
| API-08-061 | `GET /scans/{scanId}` | read | 026, 030, 031 | - | 200 |
| API-08-062 | `POST /scans/{scanId}:cancel` | run | 030 | M | 200 |
| API-08-063 | `POST /scans/{scanId}:rerun` | run | 030 | I | 202 |
| API-08-064 | `GET /scans/{scanId}/rule-results` | read | 026, 027 | - | 200 |
| API-08-065 | `GET /scans/{scanId}/score` | read hoặc `dq.read` | 028, 029 | - | 200 |
| API-08-066 | `GET /assets/{assetCode}/score-history` | read hoặc `dq.read` | 029 | - | 200 |
| API-08-067 | `GET /scans/{scanId}/tasks` | read | 026, 030 | - | 200 |
| API-08-068 | `POST /checks:evaluate` | `dq.check` | 032, 033, 035 | - | 200 |
| API-08-069 | `POST /checks:evaluate-batch` | `dq.check` | 032 | - | 200 |
| API-08-070 | `GET /inline-stats` | read | 034 | - | 200 |
| API-08-071 | `PUT /assets/{assetCode}/inline-config` | rule-admin | 032, 035 | M | 200 |
| API-08-072 | `GET /assets/{assetCode}/inline-config` | read | 032 | - | 200 |
| API-08-073 | `GET /findings` | finding-read | 037 | - | 200 |
| API-08-074 | `GET /findings/{findingId}` | finding-read | 038 | - | 200 |
| API-08-075 | `POST /findings:export` | export | 039 | I | 202 |
| API-08-076 | `POST /exports/{exportId}:approve` | export hoặc finding-read | 039 | M | 200 |
| API-08-077 | `GET /exports/{exportId}` | export | 039 | - | 200 |
| API-08-078 | `GET /finding-groups` | finding-read | 037, 041 | - | 200 |
| API-08-079 | `POST /waivers` | rule-admin | 040 | I | 201 |
| API-08-080 | `GET /waivers` | finding-read | 040 | - | 200 |
| API-08-081 | `POST /waivers/{waiverId}:approve` | approve | 040 | M | 200 |
| API-08-082 | `POST /waivers/{waiverId}:reject` | approve | 040 | M | 200 |
| API-08-083 | `POST /waivers/{waiverId}:revoke` | approve | 040 | M | 200 |
| API-08-084 | `POST /issues` | remediate | 041 | I | 201 |
| API-08-085 | `GET /issues` | read | 042 | - | 200 |
| API-08-086 | `GET /issues/{issueCode}` | read | 042, 043 | - | 200 |
| API-08-087 | `POST /issues/{issueCode}:assign` | remediate | 042 | M | 200 |
| API-08-088 | `POST /issues/{issueCode}:start` | remediate | 043 | M | 200 |
| API-08-089 | `POST /issues/{issueCode}/activities` | remediate | 043 | I | 201 |
| API-08-090 | `POST /issues/{issueCode}:mark-fixed` | remediate | 044 | M | 200 |
| API-08-091 | `POST /issues/{issueCode}:verify` | remediate | 044 | M | 200 |
| API-08-092 | `POST /issues/{issueCode}:reject` | remediate | 045 | M | 200 |
| API-08-093 | `POST /issues/{issueCode}:transfer` | remediate | 045 | M | 200 |
| API-08-094 | `POST /issues/{issueCode}:escalate` | remediate | 045 | M | 200 |
| API-08-095 | `POST /issues/{issueCode}:send-to-steward` | remediate | 046 | M | 200 |
| API-08-096 | `POST /issues/{issueCode}:cancel` | remediate | 045 | M | 200 |
| API-08-097 | `GET /issues/{issueCode}/activities` | read | 043 | - | 200 |
| API-08-098 | `GET /alert-rules` | read | 047 | - | 200 |
| API-08-099 | `POST /alert-rules` | rule-admin | 047 | I | 201 |
| API-08-100 | `PUT /alert-rules/{alertRuleCode}` | rule-admin | 047 | M | 200 |
| API-08-101 | `GET /alerts` | read | 048, 049 | - | 200 |
| API-08-102 | `POST /alerts/{alertId}:acknowledge` | run hoặc rule-admin | 049 | M | 200 |
| API-08-103 | `POST /alerts/{alertId}:silence` | run hoặc rule-admin | 049 | M | 200 |
| API-08-104 | `GET /dashboard` | read | 050 | - | 200 |
| API-08-105 | `GET /scorecards` | read hoặc `dq.read` | 051 | - | 200 |
| API-08-106 | `GET /scorecards/assets/{assetCode}` | read hoặc `dq.read` | 051 | - | 200 |
| API-08-107 | `POST /reports` | report | 052, 054 | I | 201 |
| API-08-108 | `GET /reports` | read | 052 | - | 200 |
| API-08-109 | `GET /reports/{reportCode}` | read | 052 | - | 200 |
| API-08-110 | `PATCH /reports/{reportCode}` | report | 052 | M | 200 |
| API-08-111 | `POST /reports/{reportCode}:submit` | report | 053 | M | 200 |
| API-08-112 | `POST /reports/{reportCode}:approve` | approve | 053 | M | 200 |
| API-08-113 | `POST /reports/{reportCode}:reject` | approve | 053 | M | 200 |
| API-08-114 | `POST /reports/{reportCode}:withdraw` | approve | 053 | M | 200 |
| API-08-115 | `POST /reports:check-annual-readiness` | report | 054 | - | 200 |
| API-08-116 | `POST /reports/{reportCode}/exports` | report | 055 | I | 202 |
| API-08-117 | `GET /reports/{reportCode}/exports/{exportId}` | read | 055 | - | 200 |
| API-08-118 | `POST /reports/{reportCode}:sign` | approve | 055 | M | 200 |
| API-08-119 | `GET /report-subscriptions` | read | 056 | - | 200 |
| API-08-120 | `POST /report-subscriptions` | read | 056 | I | 201 |
| API-08-121 | `DELETE /report-subscriptions/{subscriptionId}` | read | 056 | M | 204 |
| API-08-122 | `GET /kpi/snapshots` | read hoặc `dq.read` | 057 | - | 200 |
| API-08-123 | `GET /settings` | read | 058 | - | 200 |
| API-08-124 | `PUT /settings` | config | 058 | M | 200 |
| API-08-125 | `GET /retention-runs` | config | 059 | - | 200 |
| API-08-126 | `POST /retention-runs:preview` | config | 059 | - | 200 |
| API-08-127 | `GET /audit-events` | audit-read | 060 | - | 200 |
| API-08-128 | `GET /platform/benchmarks` | read | 061 | - | 200 |
| API-08-129 | `POST /findings:search` | finding-read | 037 | - | 200 |
| API-08-130 | `POST /assets/{assetCode}:enable-incremental` | run | 025 | M | 200 |
| API-08-131 | `POST /assets/{assetCode}:disable-incremental` | run | 025 | M | 200 |
| API-08-132 | `POST /weight-configs:preview` | rule-admin | 021 | - | 200 |

: Danh mục endpoint PH-08
<!-- gen:endpoints:end -->

### 3.1. Trình tự kiểm tra trực tuyến

Kiểm tra trực tuyến là đường nóng của PH-08: luồng PH-04 hoặc cổng đầu vào PH-06 hỏi kết luận cho từng bản ghi trước khi cho đi tiếp.

```{.mermaid caption="Trình tự kiểm tra trực tuyến có chính sách khi phụ thuộc lỗi"}
sequenceDiagram
  participant B as Bên gọi PH-04 hoặc PH-06
  participant G as APISIX
  participant I as dq-inline
  participant C as Bộ đệm quy tắc
  participant R as PH-07 bộ đệm danh mục
  B->>G: POST /checks:evaluate scope dq.check
  G->>I: Chuyển yêu cầu kèm traceparent
  I->>C: Lấy quy tắc INLINE đã biên dịch
  I->>R: Tra mã IN_RDM trong bộ đệm
  alt Trả lời trong 40 ms
    I-->>B: 200 verdict PASS, WARN hoặc FAIL kèm violations
  else Hết ngân sách hoặc PH-07 lỗi
    I->>I: Áp onDependencyFailure của đối tượng
    I-->>B: 200 PASS degraded true (FAIL_OPEN) hoặc 503, 504 (FAIL_CLOSED)
  end
  I-)I: Cộng số đếm theo phút, phát EVT-08-13 khi có FAIL
```

Hình cho thấy bên gọi luôn nhận câu trả lời trong ngân sách thời gian; chính sách khi lỗi do đối tượng đo khai báo trước (API-08-071), không do bên gọi tự đoán. Quyết định chặn bản tin thuộc luồng PH-04 (`STOP_TO_DLQ`, `CONTINUE_WITH_HEADER`), PH-08 chỉ trả kết luận.

### 3.2. Trình tự đo theo lô

Đo theo lô chạy theo lịch (mặc định ngày 1 hằng tháng, 02:00), theo yêu cầu hoặc khi kiểm chứng phiếu; người dùng theo dõi bằng API.

```{.mermaid caption="Trình tự đo theo lô và kiểm chứng phiếu khắc phục"}
sequenceDiagram
  participant U as DS qua BFF
  participant A as dq-api
  participant S as dq-scan
  participant W as dq-worker
  participant N as Nguồn chỉ đọc PH-05 hoặc PH-06
  participant K as Kafka outbox
  U->>A: POST /scans Idempotency-Key
  A->>A: Kiểm bộ quy tắc ACTIVE, trọng số, hạn mức
  A-->>U: 202 scanId trạng thái QUEUED
  S->>W: Chia tác vụ phân mảnh theo khóa bản ghi
  W->>N: SQL pushdown và CEL trên bản sao chỉ đọc
  W->>W: Ghi kết quả quy tắc, bản ghi lỗi có dấu vân tay
  S->>S: Tính điểm có trọng số, so kỳ trước
  S->>K: EVT-08-02, 04, 05, 06 cùng giao dịch
  U->>A: GET /scans/scanId và /scans/scanId/score
  A-->>U: 200 điểm, điểm chiều, cờ INCOMPLETE_DIMENSIONS
  U->>A: POST /issues/issueCode:verify mode SCAN
  A->>S: Tạo lần đo trigger VERIFY, phát EVT-08-09 khi đạt
```

Hình cho thấy ba điểm: việc nặng chạy ở `dq-worker` trên bản sao chỉ đọc chứ không đọc CSDL control; kết quả và sự kiện ghi cùng giao dịch (outbox); phiếu khắc phục đóng bằng lần đo kiểm chứng chứ không bằng lời của chủ quản.

### 3.3. Ví dụ luồng chính

Dữ liệu giả lập, tenant T68, rút gọn trường tùy chọn; ví dụ đầy đủ của mọi operation nằm ở OpenAPI.

<!-- gen:flows:start -->
**API-08-068 · Kiểm tra trực tuyến, kết luận không đạt**

```http
POST /api/dq/v1/checks:evaluate

{
 "assetCode": "mdm-cong-dan",
 "record": {"citizenId": "0791234567", "fullName": "Nguyễn Văn A", "ethnicCode": "01"},
 "caller": "luong-dang-ky-khai-sinh",
 "mode": "STRICT",
 "dimensions": ["VALIDITY"],
 "correlationId": "msg-20261126-0001"
}
```

```http
HTTP/1.1 200

{
 "verdict": "FAIL",
 "degraded": false,
 "violations": [{"ruleCode": "CD-ACC-001", "dimension": "VALIDITY", "severity": "CRITICAL", "fieldPath": "citizenId", "message": "Số định danh không đủ 12 chữ số"}],
 "evaluatedRules": 14,
 "durationMs": 12,
 "ruleSetVersion": 4,
 "correlationId": "msg-20261126-0001"
}
```

**API-08-059 · Chạy đo theo yêu cầu**

```http
POST /api/dq/v1/scans
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{
 "assetCode": "mdm-cong-dan",
 "scanMode": "FULL",
 "scanTrigger": "MANUAL",
 "sampleSize": 10000,
 "sampleSeed": 20261126,
 "periodCode": "2026-11",
 "note": "Đo trước kỳ báo cáo"
}
```

```http
HTTP/1.1 202

{
 "scanId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "assetCode": "mdm-cong-dan",
 "scanTrigger": "MANUAL",
 "scanMode": "FULL",
 "status": "QUEUED",
 "version": 3,
 "ruleSetVersionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"
}
```

**API-08-091 · Xác nhận phiếu bằng đo kiểm chứng**

```http
POST /api/dq/v1/issues/DQ-2026-000142:verify
If-Match: W/"3"

{"mode": "SCAN", "comment": "Đo lại sau khi PH-06 nhận cập nhật."}
```

```http
HTTP/1.1 200

{
 "issueCode": "DQ-2026-000142",
 "assetCode": "mdm-cong-dan",
 "title": "Số định danh sai mẫu ở hộ tịch",
 "severity": "CRITICAL",
 "findingCount": 312,
 "ownerOrgCode": "so-tu-phap",
 "status": "FIXED"
}
```
<!-- gen:flows:end -->

Khi `FAIL_CLOSED` và phụ thuộc lỗi, API-08-068 trả `503` thân lỗi `code = ERR-08-104`; bên gọi áp chính sách của luồng.

## 4. Danh mục sự kiện

### 4.1. Sự kiện PH-08 phát và nhận

Sự kiện ghi vào `ph08_dq.outbox_event` cùng giao dịch nghiệp vụ, Debezium Outbox Event Router đưa lên Kafka theo topic `{tenant}.dq.{thực-thể}.{sự-kiện}.v1` (FRS 9.3; ví dụ `t68.dq.scan.completed.v1`). CloudEvents 1.0 dạng cấu trúc, `type = vn.datahub.dq.{thực-thể}.{sự-kiện}.v1`, `source = dh-data/dq/{tenant}`; mọi kênh có trong [`asyncapi-dq.yaml`](ph08/asyncapi-dq.yaml).

<!-- gen:events:start -->
| Mã | Topic | Khi nào | Khóa | Payload `data` | Bên nhận |
|---|---|---|---|---|---|
| EVT-08-01 | `{tenant}.dq.ruleset.activated.v1` | Phiên bản bộ quy tắc `ACTIVE` | `assetCode` | `RuleSetActivatedData` | `dq-inline` (bộ đệm), PH-13 |
| EVT-08-02 | `{tenant}.dq.scan.completed.v1` | Lần đo `SUCCEEDED` hoặc `PARTIAL` (kèm `flags`, `score`, `verdict`) | `assetCode` | `ScanCompletedData` | PH-13, PH-18 |
| EVT-08-03 | `{tenant}.dq.scan.failed.v1` | Lần đo `FAILED` | `assetCode` | `ScanFailedData` | PH-13, PH-18 |
| EVT-08-04 | `{tenant}.dq.score.degraded.v1` | Điểm giảm ≥ `08.trend.degraded-alert` | `assetCode` | `ScoreDegradedData` | PH-13 |
| EVT-08-05 | `{tenant}.dq.score.threshold-breached.v1` | Kết luận chuyển sang `FAIL` hoặc xuống dưới ngưỡng cảnh báo | `assetCode` | `ThresholdBreachedData` | PH-13, PH-16 |
| EVT-08-06 | `{tenant}.dq.finding.opened.v1` | Lần đo có lỗi mới (gộp theo lần đo: số lỗi mới theo mức, quy tắc) | `assetCode` | `FindingOpenedData` | PH-13 |
| EVT-08-07 | `{tenant}.dq.issue.created.v1` | Mở phiếu | `issueCode` | `IssueCreatedData` | PH-13 ("Việc của tôi") |
| EVT-08-08 | `{tenant}.dq.issue.status-changed.v1` | Phiếu đổi trạng thái, quá hạn, leo thang | `issueCode` | `IssueStatusChangedData` | PH-13 |
| EVT-08-09 | `{tenant}.dq.issue.verified.v1` | Phiếu `VERIFIED` | `issueCode` | `IssueVerifiedData` | PH-13, PH-16 |
| EVT-08-10 | `{tenant}.dq.waiver.approved.v1` | Ngoại lệ `ACTIVE` | `assetCode` | `WaiverApprovedData` | PH-13 |
| EVT-08-11 | `{tenant}.dq.report.published.v1` | Báo cáo `PUBLISHED` hoặc `WITHDRAWN` | `reportCode` | `ReportPublishedData` | PH-13, PH-16 |
| EVT-08-12 | `{tenant}.dq.alert.fired.v1` | Cảnh báo `FIRING` hoặc `RESOLVED` | `assetCode` | `AlertFiredData` | PH-13 (kênh thông báo) |
| EVT-08-13 | `{tenant}.dq.check.failed.v1` | Phút có kết luận `FAIL` trực tuyến (gộp theo phút, đối tượng, bên gọi) | `assetCode` | `CheckFailedData` | PH-13, PH-04 (bảng luồng) |
| EVT-08-14 | `{tenant}.dq.kpi.published.v1` | Ảnh chụp đầy đủ mới, báo cáo công bố, chỉ số phiếu hằng ngày | `tenant` | `KpiPublishedData` | PH-16 |

: Sự kiện PH-08 phát ra

| Mã | Topic | Hành động của PH-08 | Payload `data` |
|---|---|---|---|
| EVT-06-01 | `{tenant}.mdm.golden.created.v1` | Gom `goldenId` cho lần đo tăng dần | `MdmGoldenEventData` |
| EVT-06-02 | `{tenant}.mdm.golden.updated.v1` | Như trên | `MdmGoldenEventData` |
| EVT-06-03 | `{tenant}.mdm.golden.merged.v1` | Như trên; lỗi của bản bị hợp nhất chuyển `RESOLVED` lý do `RECORD_REMOVED` | `MdmGoldenEventData` |
| EVT-06-04 | `{tenant}.mdm.golden.split.v1` | Gom cả hai `goldenId` | `MdmGoldenEventData` |
| EVT-06-10 | `{tenant}.mdm.model.activated.v1` | So lược đồ đối tượng `MDM_DOMAIN` | `MdmModelActivatedData` |
| EVT-07-03 | `{tenant}.rdm.catalog.retired.v1` | Cảnh báo quy tắc `IN_RDM` trỏ danh mục ngừng | `RdmCatalogRetiredData` |
| EVT-07-05 | `{tenant}.rdm.catalog.published.v1` | Đo tăng dần đối tượng có quy tắc trỏ danh mục và đối tượng `RDM_CATALOG` | `RdmCatalogPublishedData` |
| EVT-07-10 | `common.rdm.adminunit.reorganized.v1` | Đo tăng dần mọi đối tượng có quy tắc `IN_RDM` với `DVHC` | `RdmAdminUnitData` |

: Sự kiện PH-08 tiêu thụ
<!-- gen:events:end -->

### 4.2. Quy tắc chung của sự kiện

Các quy tắc sau áp dụng cho cả 14 sự kiện phát.

- **Không giá trị dữ liệu, không khóa bản ghi cá nhân**: chỉ mã đối tượng, số đếm, điểm; EVT-08-06 và EVT-08-13 gộp theo lần đo hoặc theo phút.
- **Thứ tự và khử trùng**: khóa phân vùng ở cột "Khóa"; phát ít nhất một lần, bên nhận khử trùng theo `id` và xử lý lũy đẳng; PH-08 khử trùng sự kiện nhận ở `ph08_dq.inbox_event`.
- **Đăng ký topic**: 14 topic đăng ký ở PH-10 theo FR-10-067; PH-13, PH-16, PH-18 là bên nhận chính.
- **Tương thích**: chỉ thêm trường tùy chọn trong `v1` (BACKWARD); lưu giữ topic 7 ngày, 3 phân vùng (giả định).

## 5. Hợp đồng với phân hệ khác và bên ngoài

Bảng nêu hợp đồng PH-08 gọi các phân hệ phụ thuộc và hợp đồng họ gọi PH-08. Không có hợp đồng với NDXP, NDOP, PayGov hay dịch vụ NGSP.

| Phân hệ | Chiều | Hợp đồng |
|---|---|---|
| PH-04 | Gọi PH-08 | Kamelet `dh-dq-check` gọi API-08-068, 069 (scope `dq.check`); tiêu đề luồng `dh-dq-verdict`, `dh-dq-violations`; lý do DLQ `DQ_FAIL` |
| PH-06 | Gọi PH-08 | Cổng chất lượng đầu vào gọi API-08-068 với `caller = PH-06` (FR-08-035) |
| PH-06 | PH-08 gọi | Đọc bản ghi vàng qua khung nhìn `ph06_mdm.v_dq_{domain}` chỉ đọc; chuyển lỗi bản ghi vàng sang hàng đợi steward qua API nội bộ (API-08-095); nhận EVT-06-01…04, 10 |
| PH-07 | PH-08 gọi | Tra mã `IN_RDM` bằng ảnh chụp danh mục và tra lô; nhận EVT-07-03, 05, 10 |
| PH-05 | Hai chiều | Kết nối chỉ đọc cho đối tượng `SOURCE_DATASET`, khám phá bảng (API-08-018); đẩy chỉ số hồ sơ vào API-08-024 (scope `dq.ingest`) |
| PH-09 | PH-08 gọi | Tra phân loại trường cho CDE (API-08-015), che giá trị bản ghi lỗi |
| PH-13, PH-16, PH-18 | Nhận sự kiện | EVT-08-02…14; PH-16 đọc lại KPI qua API-08-065, 066, 105, 106, 122 (scope `dq.read`) |

: Hợp đồng với phân hệ khác

## 6. Bảng mã lỗi ERR-08 và thông báo hiển thị

PH-08 dùng dải ERR-08-001…099 cho control plane và ERR-08-101…199 cho runtime (đo lô, kiểm tra trực tuyến). Bảng dưới ghép FRS 9.1 (mã, HTTP, ý nghĩa; HTTP trống là mã không trả cho người gọi, chỉ ghi ở nhật ký hoặc thông báo vận hành) với câu chuẩn của FRS 9.2 mà tập màn hình D03-06-PH08 dùng đúng; `{…}` là biến điền lúc chạy. Cột "Vị trí" là nơi người dùng hoặc người vận hành thấy câu; lỗi runtime không có người nhìn trực tiếp hiện ở nhật ký luồng PH-04 hoặc trung tâm thông báo PH-13. Thân lỗi theo RFC 9457; `401`, `403` do thiếu quyền chức năng và `428` dùng mã nền ERR-00-401, ERR-00-403, ERR-00-428.

<!-- gen:errors:start -->
| Mã | HTTP | Ý nghĩa | Câu hiển thị | Vị trí |
|---|---|---|---|---|
| ERR-08-001 | 404 | Không tìm thấy đối tượng hoặc thuộc tenant khác | "Không tìm thấy {đối tượng} {mã} trong tỉnh đang làm việc." | Trang lỗi, thông báo nổi |
| ERR-08-002 | 409 | Mã đã tồn tại (miền, đối tượng đo, bộ quy tắc, quy tắc, lịch) | "Mã {mã} đã được dùng. Chọn mã khác." | Dưới trường mã |
| ERR-08-003 | 400 | Dữ liệu sai lược đồ, mẫu mã, che lỏng hơn phân loại | "{Trường} không hợp lệ: {chi tiết}." | Dưới trường |
| ERR-08-004 | 409 | Xung đột phiên bản (`If-Match` không khớp `ETag`) | "{Đối tượng} đã được người khác sửa. Tải lại để xem thay đổi." | Hộp thoại xung đột |
| ERR-08-005 | 403 | Vi phạm bốn mắt | "Anh/chị là người soạn hoặc gửi duyệt nên không được tự duyệt." | Thông báo nổi ở màn duyệt |
| ERR-08-006 | 409 | Trạng thái hiện tại không cho thao tác | "Không thể {thao tác} khi {đối tượng} đang ở trạng thái {trạng thái}." | Thông báo nổi |
| ERR-08-007 | 422 | Thiếu lý do hoặc lý do ngắn hơn mức tối thiểu | "Nhập lý do (tối thiểu {n} ký tự)." | Dưới ô lý do |
| ERR-08-008 | 422 | Miền thiếu tổ chức chủ quản hoặc cán bộ phụ trách hợp lệ | "Miền {mã} cần tổ chức chủ quản và cán bộ phụ trách hợp lệ trước khi dùng." | Biểu mẫu miền, wizard |
| ERR-08-009 | 422 | Domain PH-06 không `ACTIVE` hoặc chưa có khung nhìn hợp đồng | "Domain {mã} chưa sẵn sàng cho đo chất lượng. Đề nghị PH-06 cấp khung nhìn hợp đồng." | Wizard UI-08-03 |
| ERR-08-010 | 422 | Danh mục PH-07 không tồn tại hoặc chưa phát hành | "Danh mục {mã} chưa phát hành ở PH-07." | Wizard, ngăn kéo quy tắc |
| ERR-08-011 | 422 | Kết nối PH-05 không `ACTIVE`, không chỉ đọc, chưa cấp cho PH-08 | "Kết nối {mã} không phải kết nối chỉ đọc được cấp cho chất lượng dữ liệu." | Wizard UI-08-03 |
| ERR-08-012 | 422 | Bảng không tồn tại hoặc thuộc CSDL control của Datahub | "Không đo được bảng {tên}. Bảng không tồn tại hoặc thuộc CSDL quản trị của Datahub." | Wizard UI-08-03 |
| ERR-08-013 | 422 | Khóa bản ghi không hợp lệ | "Khóa bản ghi {cột} không có trong bảng {tên}." | Wizard UI-08-03 |
| ERR-08-014 | 422 | Trường không thuộc lược đồ đối tượng đo | "Trường {đường dẫn} không có trong đối tượng đo {mã}." | Ngăn kéo quy tắc, tab trường |
| ERR-08-015 | 422 | Toán tử không thuộc chiều, chiều không hợp lệ | "Toán tử {toán tử} không dùng được cho chiều {chiều}." | Ngăn kéo quy tắc |
| ERR-08-016 | 422 | Tham số toán tử sai | "Tham số {tên} của quy tắc {mã} không hợp lệ: {chi tiết}." | Ngăn kéo quy tắc |
| ERR-08-017 | 422 | Quy tắc hợp lệ thiếu danh mục | "Quy tắc chiều Hợp lệ phải chọn danh mục PH-07 để đối chiếu." | Ngăn kéo quy tắc |
| ERR-08-018 | 422 | Quy tắc nhất quán thiếu nguồn đối chiếu | "Quy tắc chiều Nhất quán phải chọn đối tượng đo và trường để đối chiếu." | Ngăn kéo quy tắc |
| ERR-08-019 | 422 | Biểu thức CEL sai cú pháp, kiểu hoặc vượt chi phí | "Biểu thức không hợp lệ ở vị trí {dòng}:{cột}: {chi tiết}." | Trình soạn biểu thức |
| ERR-08-020 | 422 | Vị từ SQL vi phạm danh sách cho phép | "Vị từ SQL dùng {thành phần} không được phép. Chỉ được viết điều kiện trên cột của bảng đang đo." | Trình soạn biểu thức |
| ERR-08-021 | 422 | Phiên bản không có quy tắc bật | "Phiên bản {n} chưa có quy tắc nào đang bật." | UI-08-07 |
| ERR-08-022 | 409 | Đã có bản nháp | "Bộ quy tắc {mã} đang có bản nháp phiên bản {n} do {người} tạo." | UI-08-06, UI-08-07 |
| ERR-08-023 | 422 | Tổng trọng số khác 1 hoặc trọng số ngoài 0…1 | "Tổng trọng số sáu chiều phải bằng 1 (hiện là {tổng})." | UI-08-10 |
| ERR-08-024 | 422 | Ngưỡng không hợp lệ | "Ngưỡng cảnh báo phải nhỏ hơn hoặc bằng ngưỡng đạt và trong khoảng 0 đến 100." | UI-08-10 |
| ERR-08-025 | 422 | Tệp nhập sai lược đồ bộ quy tắc | "Tệp không đúng định dạng bộ quy tắc ở {vị trí}: {chi tiết}." | Hộp thoại nhập |
| ERR-08-026 | 422 | Sao chép sang đối tượng không tương thích | "Đối tượng đích thiếu trường {danh sách}. Khai báo ánh xạ trường trước khi sao chép." | Hộp thoại sao chép |
| ERR-08-027 | 422 | Chưa có bộ quy tắc hoặc trọng số hiệu lực | "Đối tượng {mã} chưa có bộ quy tắc đang hiệu lực." | UI-08-04, UI-08-11, UI-08-18 |
| ERR-08-028 | 409 | Đã có lần đo hoặc lần hồ sơ đang chạy | "Đối tượng đang có lần chạy {mã}. Đợi lần này xong hoặc hủy." | Thông báo nổi |
| ERR-08-029 | 422 | Lịch cron sai hoặc quá dày | "Lịch {biểu thức} không hợp lệ hoặc dày hơn mức cho phép ({n} giờ một lần)." | Biểu mẫu lịch |
| ERR-08-030 | 422 | Cỡ mẫu sai; đo năm không được dùng mẫu | "Kích thước mẫu phải từ 100 đến 1.000.000 bản ghi; lần đo cho báo cáo năm phải đo toàn bộ." | Hộp thoại đo |
| ERR-08-031 | 422 | Chạy thử vượt giới hạn | "Chạy thử tối đa {n} bản ghi. Giảm kích thước mẫu." | Ngăn kéo quy tắc |
| ERR-08-032 | 403 | Ngoài phạm vi tổ chức hoặc quyền khai thác | "Đối tượng {mã} không thuộc tổ chức của anh/chị." | Trang lỗi 403 |
| ERR-08-033 | 422 | Ngoại lệ quá hạn tối đa hoặc phạm vi rỗng | "Ngoại lệ tối đa {n} ngày và phải có phạm vi lỗi cụ thể." | UI-08-14 |
| ERR-08-034 | 409 | Bản ghi lỗi đã thuộc phiếu mở khác | "Có {n} bản ghi lỗi đã thuộc phiếu {mã}. Bỏ chọn hoặc gắn vào phiếu đó." | UI-08-13 |
| ERR-08-035 | 403 | Chủ quản tự xác nhận phiếu | "Chủ quản không tự xác nhận phiếu. Hệ thống sẽ đo lại để kiểm chứng." | UI-08-16 |
| ERR-08-036 | 422 | Báo đã sửa thiếu ghi chú | "Mô tả việc đã sửa (tối thiểu 20 ký tự) trước khi báo đã sửa." | UI-08-16 |
| ERR-08-037 | 422 | Quy tắc cảnh báo không hợp lệ | "Quy tắc cảnh báo {mã} không hợp lệ: {chi tiết}." | UI-08-17 |
| ERR-08-038 | 422 | Báo cáo năm chưa đủ điều kiện | "Chưa đủ điều kiện báo cáo chính thức năm {năm}: {n} đối tượng thiếu lần đo toàn bộ hoặc có điểm thiếu chiều." | UI-08-18, khối sẵn sàng |
| ERR-08-039 | 422 | Báo cáo thiếu khuyến nghị | "Báo cáo cần ít nhất một khuyến nghị trước khi gửi duyệt." | UI-08-18 |
| ERR-08-040 | 409 | Báo cáo đã công bố không sửa được | "Báo cáo {mã} đã công bố và không sửa được. Thu hồi và lập báo cáo thay thế." | UI-08-18 |
| ERR-08-041 | 409, 410 | Tệp xuất chưa được chấp thuận (`409`) hoặc hết hạn (`410`) | "Tệp xuất {mã} chưa được chấp thuận hoặc đã hết hạn tải." | Trang tải |
| ERR-08-042 | 422 | Tham số ngoài miền hoặc vượt trần | "Giá trị {giá trị} của {khóa} ngoài khoảng cho phép {miền}." | UI-08-19 |
| ERR-08-043 | 422 | Lưu giữ dưới mức sàn | "Thời gian lưu {loại} không được dưới {n} {đơn vị}." | UI-08-19 |
| ERR-08-044 | 422 | Nhóm so sánh nhỏ hơn ngưỡng ẩn danh | "Chưa đủ {n} tỉnh tham gia để so sánh ẩn danh." | UI-08-01 chế độ so sánh |
| ERR-08-045 | 422 | Tham số danh sách, thống kê sai | "Tham số {tên} không hợp lệ: {chi tiết}." | Thông báo nổi |
| ERR-08-046 | 413 | Tệp quá lớn | "Tệp vượt {n} MB." | Hộp chọn tệp |
| ERR-08-047 | 422 | CDE chưa có phân loại xác nhận ở PH-09 (cảnh báo, không chặn) | "Trường {đường dẫn} chưa có phân loại xác nhận ở PH-09. Giá trị sẽ được che như dữ liệu Nhạy cảm." | Wizard, tab trường (cảnh báo vàng) |
| ERR-08-048 | 422 | Ký số thất bại | "Không ký số được báo cáo {mã}: {nguyên nhân}." | UI-08-18 |
| ERR-08-049 | 409 | Lịch trùng | "Đối tượng {mã} đã có lịch {chế độ} {biểu thức}." | Biểu mẫu lịch |
| ERR-08-050 | 422 | Loại đối tượng không hỗ trợ thao tác | "Đối tượng loại bản tin trên luồng không chạy hồ sơ hoặc đo theo lô." | UI-08-04, UI-08-05 |
| ERR-08-051 | 422 | Chuyển PH-06 cho lỗi không thuộc bản ghi vàng | "Chỉ lỗi của bản ghi vàng mới chuyển được sang hàng đợi dữ liệu chủ." | UI-08-16 |
| ERR-08-052 | 429 | Vượt hạn mức đo theo yêu cầu | "Đã đạt {n} lần đo theo yêu cầu trong một giờ. Thử lại sau {phút} phút." | Thông báo nổi |
| ERR-08-053 | 422 | Gửi duyệt khi chưa chạy thử nội dung hiện tại | "Chạy thử phiên bản sau lần sửa cuối trước khi gửi duyệt." | UI-08-07 |
| ERR-08-054 | 503 | Không ghi được kiểm toán, thao tác bị từ chối (mã chung cho mọi lệnh ghi) | "Hệ thống tạm thời không ghi được nhật ký. Thao tác chưa được thực hiện." | Thông báo nổi |
| ERR-08-055 | 409 | `Idempotency-Key` đã dùng cho một yêu cầu có thân khác (cùng khóa, cùng đường dẫn, nội dung khác) | "Khóa chống trùng này đã dùng cho một yêu cầu khác nội dung. Tạo khóa mới rồi gửi lại." | Thông báo nổi |
| ERR-08-056 | 422 | Không có lần đo thành công nào trong kỳ báo cáo | "Không có lần đo thành công nào trong kỳ {kỳ} để lập báo cáo." | UI-08-18 |
| ERR-08-101 | 422 | Bản ghi trực tuyến sai lược đồ hoặc quá 64 KB; lô quá 100 bản ghi | "Bản ghi không đúng lược đồ của đối tượng {mã}: {chi tiết}." | Nhật ký luồng PH-04, UI-08-20 |
| ERR-08-102 | 404 | Đối tượng chưa bật kiểm tra trực tuyến | "Đối tượng {mã} chưa bật kiểm tra trực tuyến." | Nhật ký luồng PH-04 |
| ERR-08-103 | 504 | Vượt ngân sách thời gian khi `FAIL_CLOSED` | "Kiểm tra chất lượng vượt {n} ms." | Nhật ký luồng PH-04, UI-08-20 |
| ERR-08-104 | 503 | Phụ thuộc lỗi khi `FAIL_CLOSED` | "Dịch vụ đối chiếu danh mục tạm thời không khả dụng." | Nhật ký luồng PH-04, UI-08-20 |
| ERR-08-105 | 503 | Nguồn đo không khả dụng (lần đo `FAILED`, chạy thử, chuyển PH-06) | "Không đọc được nguồn của đối tượng {mã}: {nguyên nhân}. Thử lại sau." | UI-08-12, PH-13 |
| ERR-08-106 | - | Lần đo quá thời gian tối đa | "Lần đo {mã} vượt {n} giờ và đã dừng." | UI-08-12, PH-13 |
| ERR-08-107 | - | Quy tắc lỗi khi chạy | "Quy tắc {mã} lỗi khi chạy: {chi tiết}." | UI-08-12 |
| ERR-08-108 | - | PH-07 không khả dụng, chiều hợp lệ `SKIPPED` | "Không đối chiếu được danh mục {mã}. Chiều Hợp lệ bị bỏ qua ở lần đo này." | UI-08-12, thẻ điểm |
| ERR-08-109 | - | Bản ghi thiếu khóa, lỗi cấu trúc `CRITICAL` | "{n} bản ghi thiếu khóa và được ghi là lỗi cấu trúc." | UI-08-12 |
| ERR-08-110 | - | Vượt trần số bản ghi lỗi lưu | "Quy tắc {mã} có hơn {n} bản ghi lỗi. Chỉ lưu {n} bản ghi đầu, số đếm vẫn đủ." | UI-08-12 |
| ERR-08-111 | - | Lần hồ sơ thất bại | "Lần hồ sơ {mã} thất bại: {nguyên nhân}." | UI-08-05, PH-13 |
| ERR-08-112 | - | Sinh báo cáo hoặc tệp xuất thất bại | "Không tạo được {báo cáo hoặc tệp} {mã}. Thử lại sau." | Trung tâm thông báo |
| ERR-08-113 | - | Đẩy KPI, sự kiện chậm quá 24 giờ | "Chưa đẩy được {n} bản tin KPI chất lượng dữ liệu sang PH-16." | UI-08-19, PH-13 |
| ERR-08-114 | - | Gửi cảnh báo, phân phối qua PH-13 thất bại | "Cảnh báo hoặc thông báo {mã} chưa gửi được tới kênh thông báo." | UI-08-17, UI-08-18 |
| ERR-08-115 | - | Đo kiểm chứng lỗi kỹ thuật | "Đo kiểm chứng phiếu {mã} lỗi kỹ thuật. Hệ thống sẽ thử lại." | UI-08-16 |
| ERR-08-116 | - | Lược đồ nguồn đổi, trường quy tắc không còn | "Trường {đường dẫn} không còn ở nguồn. Quy tắc {mã} không chạy được." | UI-08-12, UI-08-07 |
| ERR-08-117 | - | Dọn dữ liệu lưu giữ thất bại | "Lần dọn dữ liệu {ngày} chưa hoàn tất: {nguyên nhân}." | UI-08-19, PH-13 |
| ERR-08-118 | 422 | Lô chỉ số PH-05 hoặc sự kiện tiêu thụ sai định dạng | "Lô dữ liệu từ {nguồn} sai định dạng: {chi tiết}." | PH-13 (vận hành) |
| ERR-08-119 | - | Lần đo chờ quá hạn, tự hủy | "Lần đo {mã} chờ quá {n} giờ và đã bị hủy." | UI-08-11 |

: Mã lỗi ERR-08 và thông báo hiển thị
<!-- gen:errors:end -->

### 6.1. Thân lỗi

Thân lỗi mang `code` và `errors[]` theo trường; ví dụ cho ERR-08-023 (tổng trọng số sai):

```json
{ "type": "https://datahub.gov.vn/errors/ERR-08-023", "title": "Tổng trọng số khác 1", "status": 422,
  "code": "ERR-08-023", "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "errors": [{"field": "weights", "message": "Tổng trọng số sáu chiều phải bằng 1 (hiện là 0,95)."}] }
```

## 7. Kiểm tra hợp đồng trong CI

Hợp đồng sinh từ một nguồn (`tools/spec.py`, enum đọc thẳng từ Phụ lục A của FRS) nên khó lệch FRS; ba lớp kiểm chạy ở CI (CI-5).

| Công cụ | Kiểm gì |
|---|---|
| [`check_contracts.py`](ph08/tools/check_contracts.py) | OpenAPI 3.1 hợp lệ; 219 ví dụ khớp lược đồ; mỗi operation có `x-datahub-id` duy nhất, `-fr`, `-permission`, `-errors`; lệnh sửa, hành động có `If-Match` (trừ `noifm`), lệnh tạo có `Idempotency-Key`; mã lỗi có ở FRS 9.1 và có mã HTTP trong `responses`; không trường bí mật; AsyncAPI 3.0 đủ 14 + 8 kênh đúng topic |
| [`doi_chieu_frs.py`](ph08/tools/doi_chieu_frs.py) | Đối chiếu đường dẫn, phương thức, FR của 132 mã FRS 9.4; mã ERR, EVT, PERM; liệt kê trường và enum chỉ có ở API (Phụ lục A) |
| `redocly lint`, `asyncapi validate`, `openapi-spec-validator`, Spectral, oasdiff | Lint cú pháp và phong cách; oasdiff chặn thay đổi phá vỡ trong `v1` |

: Kiểm tra hợp đồng trong CI

## 8. Ánh xạ từ hệ cũ

Hệ cũ (Viettel 2021) không có chức năng chất lượng dữ liệu (FRS 2.6), nên không có API cũ để ánh xạ. SRS cũ của repo (`docs/07-srs/SRS-PH-08-dq.md`, mục 5.3) có bốn API, đã được gom vào hợp đồng mới như sau.

| API của SRS cũ | API mới |
|---|---|
| `POST /api/v1/dq/domains/{maMien}/scans` (kích hoạt quét) | API-08-059 `POST /scans` (miền thành `assetCode` trong thân) |
| `GET /api/v1/dq/scans/{jobId}/scores` (điểm) | API-08-065 `GET /scans/{scanId}/score` |
| `POST /api/v1/dq/check` (inline từ PH-04) | API-08-068 `POST /checks:evaluate` |
| `POST /api/v1/dq/reports/annual` (báo cáo năm) | API-08-107 `POST /reports` với `reportType = ANNUAL`, kiểm trước ở API-08-115 |

: Ánh xạ API của SRS cũ sang API mới

## 9. Câu hỏi mở

Các câu hỏi dưới chưa có câu trả lời; tập này dùng phương án ở cột "Tạm dùng" để không chặn thiết kế. Q08-55, 56, 57 của bản 0.1 đã chốt ở FRS 0.2 (ERR-08-055, scope `dq.ingest`, API-08-130, 131 cùng cột `dq_asset`).

| Mã | Câu hỏi | Tạm dùng |
|---|---|---|
| Q08-58 | Phân trang bản ghi lỗi dạng con trỏ (keyset) khi trên 10.000 dòng, thay `page` | `page`, `size` ≤ 100, giới hạn vị trí 10.000; lọc thêm bằng `scanId`, `fieldName` |
| Q08-59 | Giới hạn kiểm tra lô (100 bản ghi, 64 KB mỗi bản ghi) và mục tiêu thời gian lô có đủ cho luồng PH-04 | Giữ 100 và 64 KB, mục tiêu lô p95 ≤ 150 ms (giả định) |

: Câu hỏi mở của tập API PH-08

## 10. Truy vết FR → API

Mỗi FR của PH-08 có ít nhất một API hoặc ghi rõ lý do không có. Bảng dưới sinh từ OpenAPI; FR chỉ có giao diện hoặc do hệ thống thực hiện được ghi bằng lời.

<!-- gen:fr:start -->
| FR | Tên | API (API-08-) |
|---|---|---|
| FR-08-001 | Khai báo miền chất lượng, chủ quản, cán bộ phụ trách | 001, 002, 003, 004 |
| FR-08-002 | Đăng ký đối tượng đo từ domain PH-06 | 006, 008, 009, 016 |
| FR-08-003 | Đăng ký đối tượng đo từ danh mục PH-07 | 006, 008, 009, 017 |
| FR-08-004 | Đăng ký đối tượng đo nguồn qua kết nối PH-05 chỉ đọc | 006, 008, 009, 018 |
| FR-08-005 | Khai báo phần tử dữ liệu trọng yếu, lấy phân loại PH-09 | 013, 014, 015 |
| FR-08-006 | Liệt kê, tìm, xem đối tượng đo | 005, 007 |
| FR-08-007 | Ngừng, khôi phục đối tượng đo | 010, 011, 012 |
| FR-08-008 | Chạy hồ sơ dữ liệu | 019, 020, 021 |
| FR-08-009 | Xem hồ sơ dữ liệu theo cột | 020, 021, 022 |
| FR-08-010 | Gợi ý quy tắc từ hồ sơ | 023, 031 |
| FR-08-011 | Nhận chỉ số hồ sơ từ PH-05 | 024 |
| FR-08-012 | Tạo bộ quy tắc phiên bản nháp | 026, 027, 029, 030 |
| FR-08-013 | Định nghĩa quy tắc theo chiều và toán tử | 031, 032, 033 |
| FR-08-014 | Quy tắc biểu thức CEL và vị từ SQL có kiểm soát | 031, 032, 034 |
| FR-08-015 | Thư viện quy tắc mẫu ở `COMMON` | 035, 036 |
| FR-08-016 | Chạy thử quy tắc trên mẫu | 037 |
| FR-08-017 | Gửi duyệt, duyệt, từ chối bộ quy tắc | 038, 039, 040 |
| FR-08-018 | Kích hoạt, thay thế, ngừng phiên bản bộ quy tắc | 041, 042 |
| FR-08-019 | So sánh phiên bản, xem lịch sử | 028, 030, 043 |
| FR-08-020 | Sao chép, nhập, xuất bộ quy tắc YAML, JSON | 044, 045, 046 |
| FR-08-021 | Cấu hình trọng số và ngưỡng có phiên bản, có duyệt | 047, 048, 049, 050, 051, 052, 132 |
| FR-08-022 | Liệt kê, tìm quy tắc | 025, 053 |
| FR-08-023 | Lập lịch đo | 054, 055, 056, 057, 058 |
| FR-08-024 | Chạy đo theo yêu cầu | 059 |
| FR-08-025 | Đo tăng dần theo sự kiện PH-06, PH-07 | 130, 131 |
| FR-08-026 | Thực thi quy tắc theo lô | 061, 064, 067 |
| FR-08-027 | Đối chiếu danh mục PH-07 cho chiều hợp lệ | 064 |
| FR-08-028 | Tính điểm có trọng số | 065 |
| FR-08-029 | So kỳ trước, xu hướng | 065, 066 |
| FR-08-030 | Theo dõi tiến độ, hủy, chạy lại lần đo | 060, 061, 062, 063, 067 |
| FR-08-031 | Xử lý phụ thuộc không khả dụng | 061 |
| FR-08-032 | API kiểm tra trực tuyến bản ghi | 068, 069, 071, 072 |
| FR-08-033 | Bước kiểm tra chất lượng trong luồng PH-04 | 068 |
| FR-08-034 | Thống kê kiểm tra trực tuyến | 070 |
| FR-08-035 | Cổng chất lượng đầu vào cho PH-06 | 068, 071 |
| FR-08-036 | Ghi bản ghi lỗi, dấu vân tay, che giá trị | Hệ thống ghi; xem qua API-08-073, 074, 078 |
| FR-08-037 | Tra cứu, lọc bản ghi lỗi | 073, 078, 129 |
| FR-08-038 | Xem chi tiết bản ghi lỗi, nguồn gốc | 074 |
| FR-08-039 | Xuất bản ghi lỗi có duyệt khi có trường Nhạy cảm | 075, 076, 077 |
| FR-08-040 | Ngoại lệ chấp nhận có hạn, có duyệt | 079, 080, 081, 082, 083 |
| FR-08-041 | Mở phiếu khắc phục từ nhóm lỗi | 078, 084 |
| FR-08-042 | Phân công cho tổ chức chủ quản, SLA | 085, 086, 087 |
| FR-08-043 | Cập nhật tiến độ, trao đổi trên phiếu | 086, 088, 089, 097 |
| FR-08-044 | Xác nhận đã sửa và đo lại kiểm chứng | 090, 091 |
| FR-08-045 | Từ chối, chuyển, leo thang phiếu quá hạn | 092, 093, 094, 096 |
| FR-08-046 | Chuyển lỗi bản ghi vàng sang hàng đợi PH-06 | 095 |
| FR-08-047 | Khai báo quy tắc cảnh báo | 098, 099, 100 |
| FR-08-048 | Phát cảnh báo qua kênh thông báo PH-13 | 101 |
| FR-08-049 | Xác nhận, tắt tiếng cảnh báo | 101, 102, 103 |
| FR-08-050 | Bảng điều khiển chất lượng tenant | 104 |
| FR-08-051 | Thẻ điểm theo đối tượng đo, miền, tổ chức | 105, 106 |
| FR-08-052 | Sinh báo cáo kỳ | 107, 108, 109, 110 |
| FR-08-053 | Duyệt và công bố báo cáo | 111, 112, 113, 114 |
| FR-08-054 | Báo cáo chính thức hằng năm | 059, 107, 115 |
| FR-08-055 | Xuất báo cáo PDF, XLSX, ký số | 116, 117, 118 |
| FR-08-056 | Phân phối báo cáo, đăng ký nhận | 119, 120, 121 |
| FR-08-057 | Đẩy chỉ số sang PH-16, PH-13 | 122 |
| FR-08-058 | Tham số chất lượng theo tenant | 123, 124 |
| FR-08-059 | Lưu giữ và dọn dữ liệu đo | 125, 126 |
| FR-08-060 | Nhật ký kiểm toán PH-08 | 127 |
| FR-08-061 | So sánh liên tenant tổng hợp ẩn danh | 128 |

: Truy vết FR-08 sang API
<!-- gen:fr:end -->

## 11. Đặc tả từng endpoint

Chương này sinh từ OpenAPI bằng `build/tools/sinh_dac_ta_api.py` (qua `tools/gen_md.py`); sửa OpenAPI rồi chạy lại, không sửa tay. Mỗi endpoint một bảng 10 mục; để tập không quá 240 KB, bảng bỏ các thông tin lặp ở chương 1 và 3: `page`, `size`, tham số đường dẫn, `If-Match`, `401`, `403`, `428` và mã lỗi chung. Mỗi endpoint có ít nhất một ví dụ phản hồi (rút gọn trường tùy chọn); ví dụ đầy đủ nằm ở [`openapi-dq.yaml`](ph08/openapi-dq.yaml) (219 ví dụ đã kiểm); ba luồng tiêu biểu in ở 3.3.

<!-- gen:dac-ta-api:start -->
<!-- gen:dac-ta-api:start -->

### Miền và đối tượng đo

#### API-08-001 · Danh sách miền chất lượng

::: dac-ta
**Mục đích.** Danh sách miền chất lượng.

**Phương thức, đường dẫn.** `GET /domains`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-001.

**Tham số.** `status` (query, DomainStatus, tùy chọn); `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DomainPage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/domains
```

```http
HTTP/1.1 200 OK

{"items": [{"domainCode": "HO_TICH", "name": "Hộ tịch", "ownerOrgCode": "so-tu-phap",
   "stewardUser": "tran.van.nam", "status": "ACTIVE"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-08-002 · Khai báo miền chất lượng

::: dac-ta
**Mục đích.** Khai báo miền chất lượng.

**Phương thức, đường dẫn.** `POST /domains`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-001.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `DomainCreate`; trường bắt buộc: `domainCode`, `name`, `ownerOrgCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Domain`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-08-002, ERR-08-008, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/domains
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"domainCode": "HO_TICH", "name": "Hộ tịch", "ownerOrgCode": "so-tu-phap",
 "stewardUser": "tran.van.nam", "description": "Dữ liệu đăng ký hộ tịch",
 "onDependencyFailure": "FAIL_OPEN"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/domains/ma-moi

{"domainCode": "HO_TICH", "name": "Hộ tịch", "ownerOrgCode": "so-tu-phap",
 "stewardUser": "tran.van.nam", "status": "ACTIVE", "version": 3,
 "description": "Dữ liệu đăng ký hộ tịch của tỉnh"}
```

#### API-08-003 · Chi tiết miền chất lượng

::: dac-ta
**Mục đích.** Chi tiết miền chất lượng.

**Phương thức, đường dẫn.** `GET /domains/{domainCode}`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-001.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Domain`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/domains/{domainCode}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"domainCode": "HO_TICH", "name": "Hộ tịch", "ownerOrgCode": "so-tu-phap",
 "stewardUser": "tran.van.nam", "status": "ACTIVE", "version": 3,
 "description": "Dữ liệu đăng ký hộ tịch của tỉnh"}
```

#### API-08-004 · Sửa miền chất lượng

::: dac-ta
**Mục đích.** Sửa miền chất lượng.

**Phương thức, đường dẫn.** `PATCH /domains/{domainCode}`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-001.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `DomainUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Domain`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-002, ERR-08-008 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/dq/v1/domains/{domainCode}

{"name": "Hộ tịch và quốc tịch", "description": "Dữ liệu hộ tịch",
 "ownerOrgCode": "so-tu-phap", "stewardUser": "le.thi.hoa", "status": "INACTIVE",
 "statusReason": "Ngừng khai thác miền", "onDependencyFailure": "FAIL_CLOSED"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"domainCode": "HO_TICH", "name": "Hộ tịch", "ownerOrgCode": "so-tu-phap",
 "stewardUser": "tran.van.nam", "status": "ACTIVE", "version": 3,
 "description": "Dữ liệu đăng ký hộ tịch của tỉnh"}
```

#### API-08-005 · Danh sách đối tượng đo

::: dac-ta
**Mục đích.** Danh sách đối tượng đo.

**Phương thức, đường dẫn.** `GET /assets`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-006.

**Tham số.** `domainCode` (query, string, tùy chọn); `assetType` (query, AssetType, tùy chọn); `status` (query, AssetStatus, tùy chọn); `verdict` (query, Verdict, tùy chọn); `ownerOrgCode` (query, string, tùy chọn); `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AssetPage`.

**Lỗi.** HTTP `404`, `422`; mã lỗi của thao tác: ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/assets
```

```http
HTTP/1.1 200 OK

{"items": [{"assetCode": "mdm-cong-dan", "name": "Bản ghi vàng công dân", "domainCode": "HO_TICH",
   "assetType": "MDM_DOMAIN", "status": "ACTIVE"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-08-006 · Đăng ký đối tượng đo

::: dac-ta
**Mục đích.** Đăng ký đối tượng đo.

**Phương thức, đường dẫn.** `POST /assets`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-002, FR-08-003, FR-08-004.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AssetCreate`; trường bắt buộc: `assetCode`, `name`, `domainCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Asset`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-08-002, ERR-08-008, ERR-08-009, ERR-08-010, ERR-08-032, ERR-08-011, ERR-08-012, ERR-08-013, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Loại `MDM_DOMAIN` cần `mdmDomainCode` có khung nhìn hợp đồng (ERR-08-009); `RDM_CATALOG` cần `rdmCatalogCode` đã phát hành (ERR-08-010); `SOURCE_DATASET` cần `connectionId` chỉ đọc và `objectName` (ERR-08-011, 012); `FLOW_MESSAGE` cần `flowCode`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/assets
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"assetCode": "mdm-cong-dan", "name": "Bản ghi vàng công dân", "domainCode": "HO_TICH",
 "assetType": "MDM_DOMAIN", "ownerOrgCode": "so-tu-phap", "mdmDomainCode": "CITIZEN",
 "rdmCatalogCode": "DM_DAN_TOC"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/assets/ma-moi

{"assetCode": "mdm-cong-dan", "name": "Bản ghi vàng công dân", "domainCode": "HO_TICH",
 "assetType": "MDM_DOMAIN", "status": "ACTIVE", "ownerOrgCode": "so-tu-phap", "version": 3}
```

#### API-08-007 · Chi tiết đối tượng đo

::: dac-ta
**Mục đích.** Chi tiết đối tượng đo.

**Phương thức, đường dẫn.** `GET /assets/{assetCode}`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-006.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Asset`; tiêu đề `ETag`.

**Lỗi.** HTTP `404`, `422`; mã lỗi của thao tác: ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/assets/{assetCode}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assetCode": "mdm-cong-dan", "name": "Bản ghi vàng công dân", "domainCode": "HO_TICH",
 "assetType": "MDM_DOMAIN", "status": "ACTIVE", "ownerOrgCode": "so-tu-phap", "version": 3}
```

#### API-08-008 · Sửa đối tượng đo

::: dac-ta
**Mục đích.** Sửa đối tượng đo.

**Phương thức, đường dẫn.** `PATCH /assets/{assetCode}`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-002, FR-08-003, FR-08-004.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `AssetUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Asset`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-002, ERR-08-008, ERR-08-009, ERR-08-010, ERR-08-032, ERR-08-011, ERR-08-012, ERR-08-013 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/dq/v1/assets/{assetCode}

{"name": "Bản ghi vàng công dân", "ownerOrgCode": "so-tu-phap",
 "keyColumns": ["citizenId"], "defaultScanMode": "SAMPLE", "sampleRatio": 0.1,
 "updatedAtField": "updatedAt", "description": "Cập nhật mô tả"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assetCode": "mdm-cong-dan", "name": "Bản ghi vàng công dân", "domainCode": "HO_TICH",
 "assetType": "MDM_DOMAIN", "status": "ACTIVE", "ownerOrgCode": "so-tu-phap", "version": 3}
```

#### API-08-009 · Kích hoạt đối tượng đo

::: dac-ta
**Mục đích.** Kích hoạt đối tượng đo.

**Phương thức, đường dẫn.** `POST /assets/{assetCode}:activate`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-002, FR-08-003, FR-08-004.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Asset`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-002, ERR-08-008, ERR-08-009, ERR-08-010, ERR-08-032, ERR-08-011, ERR-08-012, ERR-08-013 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Cần miền có tổ chức chủ quản và cán bộ phụ trách (ERR-08-008); sinh lịch mặc định theo `08.scan.default-cron`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/assets/{assetCode}:activate

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assetCode": "mdm-cong-dan", "name": "Bản ghi vàng công dân", "domainCode": "HO_TICH",
 "assetType": "MDM_DOMAIN", "status": "ACTIVE", "ownerOrgCode": "so-tu-phap", "version": 3}
```

#### API-08-010 · Tạm ngừng đối tượng đo

::: dac-ta
**Mục đích.** Tạm ngừng đối tượng đo.

**Phương thức, đường dẫn.** `POST /assets/{assetCode}:suspend`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-007.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Asset`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007, ERR-08-028 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/assets/{assetCode}:suspend

{"reason": "Nguồn dữ liệu đã ngừng cung cấp theo công văn số 123."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assetCode": "mdm-cong-dan", "name": "Bản ghi vàng công dân", "domainCode": "HO_TICH",
 "assetType": "MDM_DOMAIN", "status": "SUSPENDED", "ownerOrgCode": "so-tu-phap",
 "version": 3}
```

#### API-08-011 · Tiếp tục đối tượng đo

::: dac-ta
**Mục đích.** Tiếp tục đối tượng đo.

**Phương thức, đường dẫn.** `POST /assets/{assetCode}:resume`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-007.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Asset`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007, ERR-08-028 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/assets/{assetCode}:resume

{"reason": "Nguồn dữ liệu đã ngừng cung cấp theo công văn số 123."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assetCode": "mdm-cong-dan", "name": "Bản ghi vàng công dân", "domainCode": "HO_TICH",
 "assetType": "MDM_DOMAIN", "status": "ACTIVE", "ownerOrgCode": "so-tu-phap", "version": 3}
```

#### API-08-012 · Ngừng đối tượng đo

::: dac-ta
**Mục đích.** Ngừng đối tượng đo.

**Phương thức, đường dẫn.** `POST /assets/{assetCode}:retire`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-007.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Asset`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007, ERR-08-028 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/assets/{assetCode}:retire

{"reason": "Nguồn dữ liệu đã ngừng cung cấp theo công văn số 123."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assetCode": "mdm-cong-dan", "name": "Bản ghi vàng công dân", "domainCode": "HO_TICH",
 "assetType": "MDM_DOMAIN", "status": "RETIRED", "ownerOrgCode": "so-tu-phap", "version": 3}
```

#### API-08-013 · Danh sách trường và CDE của đối tượng

::: dac-ta
**Mục đích.** Danh sách trường và CDE của đối tượng.

**Phương thức, đường dẫn.** `GET /assets/{assetCode}/fields`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-005.

**Tham số.** `cde` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AssetFieldPage`.

**Lỗi.** `404` Không tìm thấy; `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/assets/{assetCode}/fields
```

```http
HTTP/1.1 200 OK

{"items": [{"fieldName": "citizenId", "fieldType": "STRING", "cde": true, "dataClass": "SENSITIVE",
   "classificationStatus": "CONFIRMED"}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-08-014 · Khai báo trường và CDE

::: dac-ta
**Mục đích.** Khai báo trường và CDE.

**Phương thức, đường dẫn.** `PUT /assets/{assetCode}/fields/{fieldPath}`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-005.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `AssetFieldPut`; trường bắt buộc: `fieldType`, `cde`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AssetField`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-014, ERR-08-047 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phân loại lấy từ PH-09; trường chưa có phân loại xác nhận bị che như Nhạy cảm (cảnh báo ERR-08-047, không chặn). Chưa có trường thì gửi `If-Match: *` để tạo.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/dq/v1/assets/{assetCode}/fields/{fieldPath}

{"fieldType": "STRING", "cde": true, "label": "Số định danh công dân",
 "valueMode": "HASH_ONLY", "rdmCatalogCode": "DM_DAN_TOC", "sortOrder": 1}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"fieldName": "citizenId", "fieldType": "STRING", "cde": true, "dataClass": "SENSITIVE",
 "classificationStatus": "CONFIRMED", "valueMode": "HASH_ONLY", "version": 3}
```

#### API-08-015 · Đồng bộ phân loại trường từ PH-09

::: dac-ta
**Mục đích.** Đồng bộ phân loại trường từ PH-09.

**Phương thức, đường dẫn.** `POST /assets/{assetCode}/fields:sync-classification`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-005.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ClassificationSyncResult`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `422`; mã lỗi của thao tác: ERR-08-014, ERR-08-047 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Gọi API tra phân loại của PH-09, cập nhật `dataClass` và `classificationStatus`; không đổi `valueMode` lỏng hơn.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/assets/{assetCode}/fields:sync-classification
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assetCode": "mdm-cong-dan", "updated": 12, "unconfirmed": ["permanentAddress"]}
```

#### API-08-130 · Bật đo tăng dần cho đối tượng

::: dac-ta
**Mục đích.** Bật đo tăng dần cho đối tượng.

**Phương thức, đường dẫn.** `POST /assets/{assetCode}:enable-incremental`.

**Quyền.** `PERM-08-run`.

**FR hiện thực.** FR-08-025.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `EnableIncrementalRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Asset`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy; `409` Xung đột.

**Ghi chú.** Đối tượng phải `ACTIVE` (ERR-08-006); `FLOW_MESSAGE` bị ERR-08-050; `SOURCE_DATASET` cần `updatedAtField`. Bật rồi bộ lập lịch nội bộ và sự kiện PH-06, PH-07 kích hoạt lần đo `INCREMENTAL`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/assets/{assetCode}:enable-incremental

{"updatedAtField": "updatedAt", "reason": "Đo theo sự kiện bản ghi vàng đổi."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assetCode": "mdm-cong-dan", "name": "Bản ghi vàng công dân", "domainCode": "HO_TICH",
 "assetType": "MDM_DOMAIN", "status": "ACTIVE", "ownerOrgCode": "so-tu-phap", "version": 3}
```

#### API-08-131 · Tắt đo tăng dần cho đối tượng

::: dac-ta
**Mục đích.** Tắt đo tăng dần cho đối tượng.

**Phương thức, đường dẫn.** `POST /assets/{assetCode}:disable-incremental`.

**Quyền.** `PERM-08-run`.

**FR hiện thực.** FR-08-025.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Asset`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy; `409` Xung đột.

**Ghi chú.** Tắt đo tăng dần; lý do từ 20 ký tự; bộ đệm khóa đổi còn lại được đo bù ở lần `FULL` kế tiếp.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/assets/{assetCode}:disable-incremental

{"reason": "Nguồn dữ liệu đã ngừng cung cấp theo công văn số 123."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assetCode": "mdm-cong-dan", "name": "Bản ghi vàng công dân", "domainCode": "HO_TICH",
 "assetType": "MDM_DOMAIN", "status": "ACTIVE", "ownerOrgCode": "so-tu-phap", "version": 3}
```

### Nguồn đối tượng đo

#### API-08-016 · Domain PH-06 có thể đo

::: dac-ta
**Mục đích.** Domain PH-06 có thể đo.

**Phương thức, đường dẫn.** `GET /sources/mdm-domains`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-002.

**Tham số.** `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MdmDomainSourcePage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/sources/mdm-domains
```

```http
HTTP/1.1 200 OK

{"items": [{"mdmDomainCode": "CITIZEN", "name": "Công dân", "status": "ACTIVE",
   "hasContractView": true, "attributeCount": 14}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-08-017 · Danh mục PH-07 có thể đo

::: dac-ta
**Mục đích.** Danh mục PH-07 có thể đo.

**Phương thức, đường dẫn.** `GET /sources/rdm-catalogs`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-003.

**Tham số.** `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RdmCatalogSourcePage`.

**Lỗi.** HTTP `422`; mã lỗi của thao tác: ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/sources/rdm-catalogs
```

```http
HTTP/1.1 200 OK

{"items": [{"rdmCatalogCode": "DM_DAN_TOC", "name": "Danh mục dân tộc", "publishedVersion": 3,
   "itemCount": 54}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-08-018 · Khám phá bảng của kết nối PH-05

::: dac-ta
**Mục đích.** Khám phá bảng của kết nối PH-05.

**Phương thức, đường dẫn.** `POST /sources/connections/{connectionCode}:discover`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-004.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `DiscoverRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DiscoverResult`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `422`; mã lỗi của thao tác: ERR-08-011, ERR-08-012, ERR-08-013 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Dùng kết nối PH-05 chỉ đọc; không bao giờ đọc CSDL control của Datahub (ERR-08-012).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/sources/connections/{connectionCode}:discover

{"schemaName": "public", "namePattern": "ho_so_%"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"connectionCode": "kn-ho-tich",
 "objects": [{"objectName": "public.ho_so_cong_dan", "objectType": "TABLE", "columnCount": 18,
   "estimatedRows": 1200000}]}
```

### Hồ sơ dữ liệu

#### API-08-019 · Chạy hồ sơ dữ liệu

::: dac-ta
**Mục đích.** Chạy hồ sơ dữ liệu.

**Phương thức, đường dẫn.** `POST /assets/{assetCode}/profile-runs`.

**Quyền.** `PERM-08-asset`.

**FR hiện thực.** FR-08-008.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ProfileRunCreate`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ProfileRun`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-028, ERR-08-030, ERR-08-050, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đối tượng `FLOW_MESSAGE` không chạy hồ sơ (ERR-08-050); đang có lần hồ sơ chạy trả ERR-08-028.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/assets/{assetCode}/profile-runs
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"scanMode": "SAMPLE", "sampleRows": 100000}
```

```http
HTTP/1.1 202 Accepted
ETag: W/"3"

{"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
 "status": "QUEUED", "version": 3, "scanMode": "SAMPLE", "sampleRows": 100000,
 "rowCount": 1200000}
```

#### API-08-020 · Danh sách lần hồ sơ của đối tượng

::: dac-ta
**Mục đích.** Danh sách lần hồ sơ của đối tượng.

**Phương thức, đường dẫn.** `GET /assets/{assetCode}/profile-runs`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-008, FR-08-009.

**Tham số.** `status` (query, ProfileStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProfileRunPage`.

**Lỗi.** `404` Không tìm thấy; `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/assets/{assetCode}/profile-runs
```

```http
HTTP/1.1 200 OK

{"items": [{"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
   "status": "SUCCEEDED", "version": 3, "scanMode": "SAMPLE"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-08-021 · Chi tiết lần hồ sơ

::: dac-ta
**Mục đích.** Chi tiết lần hồ sơ.

**Phương thức, đường dẫn.** `GET /profile-runs/{runId}`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-008, FR-08-009.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProfileRun`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/profile-runs/{runId}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
 "status": "SUCCEEDED", "version": 3, "scanMode": "SAMPLE", "sampleRows": 100000,
 "rowCount": 1200000}
```

#### API-08-022 · Thống kê cột của lần hồ sơ

::: dac-ta
**Mục đích.** Thống kê cột của lần hồ sơ.

**Phương thức, đường dẫn.** `GET /profile-runs/{runId}/columns`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-009.

**Tham số.** `fieldName` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ProfileColumnPage`.

**Lỗi.** `404` Không tìm thấy; `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/profile-runs/{runId}/columns
```

```http
HTTP/1.1 200 OK

{"items": [{"fieldName": "citizenId", "sensitive": false, "rowCount": 100000, "nullCount": 120,
   "inferredType": "STRING"}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-08-023 · Gợi ý quy tắc từ hồ sơ

::: dac-ta
**Mục đích.** Gợi ý quy tắc từ hồ sơ.

**Phương thức, đường dẫn.** `POST /profile-runs/{runId}:suggest-rules`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-010.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `SuggestRulesRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SuggestRulesResult`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-08-022 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/profile-runs/{runId}:suggest-rules

{"fieldNames": ["citizenId"], "dimensions": ["COMPLETENESS"]}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"suggestions": [{"ruleCode": "CD-ACC-001", "dimension": "COMPLETENESS", "operator": "NOT_NULL",
   "severity": "MAJOR", "fieldName": "citizenId"}]}
```

#### API-08-024 · Nhận chỉ số hồ sơ từ PH-05

::: dac-ta
**Mục đích.** Nhận chỉ số hồ sơ từ PH-05.

**Phương thức, đường dẫn.** `POST /internal/profile-metrics`.

**Quyền.** scope `dq.ingest`.

**FR hiện thực.** FR-08-011.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ProfileMetricsIn`; trường bắt buộc: `connectionCode`, `objectName`, `collectedAt`.

**Chống trùng.** Không.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ProfileMetricsResult`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ.

**Ghi chú.** Chỉ qua `/internal` trong mạng nội bộ, token máy của PH-05 (scope `dq.ingest`); không có ở BFF. Lô sai định dạng ERR-08-118.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/internal/profile-metrics

{"connectionCode": "kn-ho-tich", "objectName": "public.ho_so_cong_dan",
 "collectedAt": "2026-11-20T08:00:00+07:00", "rowCount": 1200000,
 "columns": [{"fieldName": "citizenId", "nullCount": 12, "distinctEstimate": 9900, "minMasked": "A",
   "maxMasked": "Z"}]}
```

```http
HTTP/1.1 202 Accepted
ETag: W/"3"

{"accepted": 18, "profileRunId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"}
```

### Bộ quy tắc

#### API-08-025 · Danh sách bộ quy tắc

::: dac-ta
**Mục đích.** Danh sách bộ quy tắc.

**Phương thức, đường dẫn.** `GET /rule-sets`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-022.

**Tham số.** `assetCode` (query, string, tùy chọn); `status` (query, VersionStatus, tùy chọn); `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSetPage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/rule-sets
```

```http
HTTP/1.1 200 OK

{"items": [{"ruleSetCode": "bq-cong-dan", "name": "Bộ quy tắc công dân", "assetCode": "mdm-cong-dan",
   "version": 3, "description": "Bộ quy tắc cho bản ghi vàng công dân"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-08-026 · Tạo bộ quy tắc

::: dac-ta
**Mục đích.** Tạo bộ quy tắc.

**Phương thức, đường dẫn.** `POST /rule-sets`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-012.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RuleSetCreate`; trường bắt buộc: `ruleSetCode`, `name`, `assetCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `RuleSet`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`; mã lỗi của thao tác: ERR-08-002, ERR-08-022, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/rule-sets
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"ruleSetCode": "bq-cong-dan", "name": "Bộ quy tắc công dân", "assetCode": "mdm-cong-dan",
 "description": "Bộ quy tắc cho bản ghi vàng công dân"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/rule-sets/ma-moi

{"ruleSetCode": "bq-cong-dan", "name": "Bộ quy tắc công dân", "assetCode": "mdm-cong-dan",
 "version": 3, "description": "Bộ quy tắc cho bản ghi vàng công dân",
 "currentVersionNo": 4, "activeVersionNo": 3}
```

#### API-08-027 · Chi tiết bộ quy tắc

::: dac-ta
**Mục đích.** Chi tiết bộ quy tắc.

**Phương thức, đường dẫn.** `GET /rule-sets/{ruleSetCode}`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-012.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSet`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/rule-sets/{ruleSetCode}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"ruleSetCode": "bq-cong-dan", "name": "Bộ quy tắc công dân", "assetCode": "mdm-cong-dan",
 "version": 3, "description": "Bộ quy tắc cho bản ghi vàng công dân",
 "currentVersionNo": 4, "activeVersionNo": 3}
```

#### API-08-028 · Danh sách phiên bản bộ quy tắc

::: dac-ta
**Mục đích.** Danh sách phiên bản bộ quy tắc.

**Phương thức, đường dẫn.** `GET /rule-sets/{ruleSetCode}/versions`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-019.

**Tham số.** `status` (query, VersionStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSetVersionPage`.

**Lỗi.** `404` Không tìm thấy; `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/rule-sets/{ruleSetCode}/versions
```

```http
HTTP/1.1 200 OK

{"items": [{"ruleSetCode": "bq-cong-dan", "versionNo": 4, "status": "DRAFT", "version": 3,
   "weightConfigId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-08-029 · Tạo phiên bản nháp

::: dac-ta
**Mục đích.** Tạo phiên bản nháp.

**Phương thức, đường dẫn.** `POST /rule-sets/{ruleSetCode}/versions`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-012.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `VersionCreate`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `RuleSetVersion`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `404`, `409`; mã lỗi của thao tác: ERR-08-002, ERR-08-022, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/rule-sets/{ruleSetCode}/versions
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"basedOnVersionNo": 3, "changeNote": "Thêm quy tắc đối chiếu danh mục dân tộc"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/rule-sets/ma-moi

{"ruleSetCode": "bq-cong-dan", "versionNo": 4, "status": "DRAFT", "version": 3,
 "weightConfigId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "contentHash": "9f86d081884c7d659a2feaa0c55ad015", "ruleCount": 18}
```

#### API-08-030 · Chi tiết phiên bản kèm quy tắc

::: dac-ta
**Mục đích.** Chi tiết phiên bản kèm quy tắc.

**Phương thức, đường dẫn.** `GET /rule-sets/{ruleSetCode}/versions/{version}`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-012, FR-08-019.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSetVersion`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/rule-sets/{ruleSetCode}/versions/{version}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"ruleSetCode": "bq-cong-dan", "versionNo": 4, "status": "DRAFT", "version": 3,
 "weightConfigId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "contentHash": "9f86d081884c7d659a2feaa0c55ad015", "ruleCount": 18}
```

#### API-08-037 · Chạy thử phiên bản trên mẫu

::: dac-ta
**Mục đích.** Chạy thử phiên bản trên mẫu.

**Phương thức, đường dẫn.** `POST /rule-sets/{ruleSetCode}/versions/{version}:dry-run`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-016.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `DryRunRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `DryRunResult`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `422`, `503`; mã lỗi của thao tác: ERR-08-031, ERR-08-105 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Đồng bộ, tối đa `08.dryrun.max-rows` bản ghi (ERR-08-031); không ghi bản ghi lỗi; ví dụ lỗi đã che.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/rule-sets/{ruleSetCode}/versions/{version}:dry-run

{"sampleSize": 1000, "sampleSeed": 42, "recordKeys": ["2024-0001234"],
 "ruleCodes": ["CD-ACC-001"]}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"sampleSize": 1000, "durationMs": 840,
 "results": [{"ruleCode": "CD-ACC-001", "status": "FAILED", "rowsEvaluated": 1000, "rowsFailed": 12,
   "passRate": 0.988}], "sampleSeed": 42, "estimatedScore": 92.5}
```

#### API-08-038 · Gửi duyệt phiên bản

::: dac-ta
**Mục đích.** Gửi duyệt phiên bản.

**Phương thức, đường dẫn.** `POST /rule-sets/{ruleSetCode}/versions/{version}:submit`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-017.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSetVersion`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-021, ERR-08-053 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phải có kết quả chạy thử của đúng nội dung hiện tại (ERR-08-053) và ít nhất một quy tắc bật (ERR-08-021).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/rule-sets/{ruleSetCode}/versions/{version}:submit

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"ruleSetCode": "bq-cong-dan", "versionNo": 4, "status": "PENDING_APPROVAL", "version": 3,
 "weightConfigId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "contentHash": "9f86d081884c7d659a2feaa0c55ad015", "ruleCount": 18}
```

#### API-08-039 · Duyệt phiên bản

::: dac-ta
**Mục đích.** Duyệt phiên bản.

**Phương thức, đường dẫn.** `POST /rule-sets/{ruleSetCode}/versions/{version}:approve`.

**Quyền.** `PERM-08-approve`.

**FR hiện thực.** FR-08-017.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSetVersion`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-021, ERR-08-053 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Người duyệt khác người gửi (ERR-08-005, bốn mắt).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/rule-sets/{ruleSetCode}/versions/{version}:approve

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"ruleSetCode": "bq-cong-dan", "versionNo": 4, "status": "APPROVED", "version": 3,
 "weightConfigId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "contentHash": "9f86d081884c7d659a2feaa0c55ad015", "ruleCount": 18}
```

#### API-08-040 · Từ chối phiên bản

::: dac-ta
**Mục đích.** Từ chối phiên bản.

**Phương thức, đường dẫn.** `POST /rule-sets/{ruleSetCode}/versions/{version}:reject`.

**Quyền.** `PERM-08-approve`.

**FR hiện thực.** FR-08-017.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSetVersion`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-021, ERR-08-053 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/rule-sets/{ruleSetCode}/versions/{version}:reject

{"comment": "Thiếu căn cứ về ngưỡng, đề nghị bổ sung và gửi lại."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"ruleSetCode": "bq-cong-dan", "versionNo": 4, "status": "DRAFT", "version": 3,
 "weightConfigId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "contentHash": "9f86d081884c7d659a2feaa0c55ad015", "ruleCount": 18}
```

#### API-08-041 · Kích hoạt phiên bản

::: dac-ta
**Mục đích.** Kích hoạt phiên bản.

**Phương thức, đường dẫn.** `POST /rule-sets/{ruleSetCode}/versions/{version}:activate`.

**Quyền.** `PERM-08-approve`.

**FR hiện thực.** FR-08-018.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ActivateRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSetVersion`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Phiên bản phải `APPROVED`; thay phiên bản `ACTIVE` cũ (chuyển `SUPERSEDED`), phát EVT-08-01.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/rule-sets/{ruleSetCode}/versions/{version}:activate

{"comment": "Kích hoạt trước kỳ đo tháng 12."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"ruleSetCode": "bq-cong-dan", "versionNo": 4, "status": "ACTIVE", "version": 3,
 "weightConfigId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "contentHash": "9f86d081884c7d659a2feaa0c55ad015", "ruleCount": 18}
```

#### API-08-042 · Ngừng bộ quy tắc

::: dac-ta
**Mục đích.** Ngừng bộ quy tắc.

**Phương thức, đường dẫn.** `POST /rule-sets/{ruleSetCode}:retire`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-018.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSet`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/rule-sets/{ruleSetCode}:retire

{"reason": "Nguồn dữ liệu đã ngừng cung cấp theo công văn số 123."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"ruleSetCode": "bq-cong-dan", "name": "Bộ quy tắc công dân", "assetCode": "mdm-cong-dan",
 "version": 3, "description": "Bộ quy tắc cho bản ghi vàng công dân",
 "currentVersionNo": 4, "activeVersionNo": 3}
```

#### API-08-043 · So sánh hai phiên bản

::: dac-ta
**Mục đích.** So sánh hai phiên bản.

**Phương thức, đường dẫn.** `GET /rule-sets/{ruleSetCode}/versions/{version}/diff`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-019.

**Tham số.** `with` (query, integer, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `VersionDiff`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy; `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/rule-sets/{ruleSetCode}/versions/{version}/diff?with=3
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"ruleSetCode": "bq-cong-dan", "fromVersionNo": 3, "toVersionNo": 4,
 "added": ["CD-VAL-010"], "removed": [], "changed": [{"ruleCode": "CD-ACC-001",
   "changes": [{"field": "severity", "from": "MAJOR", "to": "CRITICAL"}]}]}
```

#### API-08-044 · Sao chép bộ quy tắc

::: dac-ta
**Mục đích.** Sao chép bộ quy tắc.

**Phương thức, đường dẫn.** `POST /rule-sets/{ruleSetCode}:copy`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-020.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RuleSetCopyRequest`; trường bắt buộc: `newRuleSetCode`, `name`, `targetAssetCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `RuleSet`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `404`, `409`, `413`, `422`; mã lỗi của thao tác: ERR-08-022, ERR-08-025, ERR-08-026, ERR-08-046, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/rule-sets/{ruleSetCode}:copy
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"newRuleSetCode": "bq-cong-dan", "name": "Bộ quy tắc công dân bản sao",
 "targetAssetCode": "mdm-cong-dan", "fieldMapping": {"citizenId": "personalId"}}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/rule-sets/ma-moi

{"ruleSetCode": "bq-cong-dan", "name": "Bộ quy tắc công dân", "assetCode": "mdm-cong-dan",
 "version": 3, "description": "Bộ quy tắc cho bản ghi vàng công dân",
 "currentVersionNo": 4, "activeVersionNo": 3}
```

#### API-08-045 · Xuất phiên bản YAML, JSON

::: dac-ta
**Mục đích.** Xuất phiên bản YAML, JSON.

**Phương thức, đường dẫn.** `GET /rule-sets/{ruleSetCode}/versions/{version}/export`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-020.

**Tham số.** `format` (query, RuleFileFormat, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleSetExport`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy; `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/rule-sets/{ruleSetCode}/versions/{version}/export
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"format": "YAML", "content": "ruleSet: bq-cong-dan\nrules: []\n",
 "contentSha256": "9f86d081884c7d659a2feaa0c55ad015"}
```

#### API-08-046 · Nhập bộ quy tắc từ tệp

::: dac-ta
**Mục đích.** Nhập bộ quy tắc từ tệp.

**Phương thức, đường dẫn.** `POST /rule-sets:import`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-020.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RuleSetImportRequest`; trường bắt buộc: `format`, `content`, `ruleSetCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `RuleSet`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `413`, `422`; mã lỗi của thao tác: ERR-08-022, ERR-08-025, ERR-08-026, ERR-08-046, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/rule-sets:import
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"format": "YAML", "content": "ruleSet: bq-cong-dan\nrules: []\n",
 "ruleSetCode": "bq-cong-dan", "targetAssetCode": "mdm-cong-dan"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/rule-sets:import/ma-moi

{"ruleSetCode": "bq-cong-dan", "name": "Bộ quy tắc công dân", "assetCode": "mdm-cong-dan",
 "version": 3, "description": "Bộ quy tắc cho bản ghi vàng công dân",
 "currentVersionNo": 4, "activeVersionNo": 3}
```

### Quy tắc

#### API-08-031 · Thêm quy tắc vào phiên bản nháp

::: dac-ta
**Mục đích.** Thêm quy tắc vào phiên bản nháp.

**Phương thức, đường dẫn.** `POST /rule-sets/{ruleSetCode}/versions/{version}/rules`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-010, FR-08-013, FR-08-014.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RuleUpsert`; trường bắt buộc: `ruleCode`, `name`, `dimension`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Rule`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-022, ERR-08-014, ERR-08-015, ERR-08-016, ERR-08-017, ERR-08-018, ERR-08-019, ERR-08-020, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/rule-sets/{ruleSetCode}/versions/{version}/rules
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"ruleCode": "CD-ACC-001", "name": "Số định danh đủ 12 chữ số", "dimension": "VALIDITY",
 "operator": "REGEX", "severity": "CRITICAL", "execMode": "BOTH",
 "description": "Kiểm số định danh công dân"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/rule-sets/ma-moi

{"ruleCode": "CD-ACC-001", "name": "Số định danh đủ 12 chữ số", "dimension": "VALIDITY",
 "operator": "REGEX", "severity": "CRITICAL", "execMode": "BOTH", "enabled": true}
```

#### API-08-032 · Sửa quy tắc trong phiên bản nháp

::: dac-ta
**Mục đích.** Sửa quy tắc trong phiên bản nháp.

**Phương thức, đường dẫn.** `PUT /rule-sets/{ruleSetCode}/versions/{version}/rules/{ruleCode}`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-013, FR-08-014.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `RuleUpsert`; trường bắt buộc: `ruleCode`, `name`, `dimension`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Rule`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-014, ERR-08-015, ERR-08-016, ERR-08-017, ERR-08-018, ERR-08-019, ERR-08-020 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/dq/v1/rule-sets/{ruleSetCode}/versions/{version}/rules/{ruleCode}

{"ruleCode": "CD-ACC-001", "name": "Số định danh đủ 12 chữ số", "dimension": "VALIDITY",
 "operator": "REGEX", "severity": "CRITICAL", "execMode": "BOTH",
 "description": "Kiểm số định danh công dân"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"ruleCode": "CD-ACC-001", "name": "Số định danh đủ 12 chữ số", "dimension": "VALIDITY",
 "operator": "REGEX", "severity": "CRITICAL", "execMode": "BOTH", "enabled": true}
```

#### API-08-033 · Xóa quy tắc khỏi phiên bản nháp

::: dac-ta
**Mục đích.** Xóa quy tắc khỏi phiên bản nháp.

**Phương thức, đường dẫn.** `DELETE /rule-sets/{ruleSetCode}/versions/{version}/rules/{ruleCode}`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-013.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-014, ERR-08-015, ERR-08-016, ERR-08-017, ERR-08-018 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
DELETE /api/dq/v1/rule-sets/{ruleSetCode}/versions/{version}/rules/{ruleCode}
```

```http
HTTP/1.1 204 No Content
```

#### API-08-034 · Kiểm biểu thức CEL, vị từ SQL

::: dac-ta
**Mục đích.** Kiểm biểu thức CEL, vị từ SQL.

**Phương thức, đường dẫn.** `POST /rules:validate-expression`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-014.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ExpressionValidateRequest`; trường bắt buộc: `assetCode`, `operator`, `expression`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ExpressionValidateResult`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-08-019, ERR-08-020 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/rules:validate-expression

{"assetCode": "mdm-cong-dan", "operator": "CEL_EXPRESSION",
 "expression": "record.citizenId.size() == 12"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"valid": true, "costEstimate": 12, "referencedFields": ["citizenId"],
 "issues": [{"line": 1, "column": 12, "message": "Trường không tồn tại."}]}
```

#### API-08-035 · Danh sách quy tắc mẫu

::: dac-ta
**Mục đích.** Danh sách quy tắc mẫu.

**Phương thức, đường dẫn.** `GET /rule-templates`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-015.

**Tham số.** `dimension` (query, Dimension, tùy chọn); `operator` (query, Operator, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleTemplatePage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/rule-templates
```

```http
HTTP/1.1 200 OK

{"items": [{"templateCode": "CCCD_12", "name": "Số định danh công dân 12 chữ số",
   "dimension": "VALIDITY", "operator": "REGEX", "defaultSeverity": "CRITICAL"}],
 "page": 0, "size": 20, "totalElements": 1}
```

#### API-08-036 · Tạo quy tắc mẫu

::: dac-ta
**Mục đích.** Tạo quy tắc mẫu.

**Phương thức, đường dẫn.** `POST /rule-templates`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-015.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RuleTemplateCreate`; trường bắt buộc: `templateCode`, `name`, `dimension`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `RuleTemplate`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-08-016, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/rule-templates
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"templateCode": "MST_10", "name": "Mã số thuế 10 chữ số", "dimension": "VALIDITY",
 "operator": "CHECKSUM", "defaultSeverity": "MAJOR", "params": {"algorithm": "MST_10"},
 "expressionTemplate": "ví dụ"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/rule-templates/ma-moi

{"templateCode": "CCCD_12", "name": "Số định danh công dân 12 chữ số",
 "dimension": "VALIDITY", "operator": "REGEX", "defaultSeverity": "CRITICAL",
 "status": "ACTIVE", "version": 3}
```

#### API-08-053 · Tìm quy tắc trong toàn tenant

::: dac-ta
**Mục đích.** Tìm quy tắc trong toàn tenant.

**Phương thức, đường dẫn.** `GET /rules`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-022.

**Tham số.** `assetCode` (query, string, tùy chọn); `dimension` (query, Dimension, tùy chọn); `operator` (query, Operator, tùy chọn); `severity` (query, Severity, tùy chọn); `enabled` (query, boolean, tùy chọn); `q` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleListItemPage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/rules
```

```http
HTTP/1.1 200 OK

{"items": [{"ruleCode": "CD-ACC-001", "ruleSetCode": "bq-cong-dan", "versionNo": 4,
   "versionStatus": "ACTIVE", "assetCode": "mdm-cong-dan"}], "page": 0, "size": 20,
 "totalElements": 1}
```

### Trọng số và ngưỡng

#### API-08-047 · Danh sách cấu hình trọng số

::: dac-ta
**Mục đích.** Danh sách cấu hình trọng số.

**Phương thức, đường dẫn.** `GET /weight-configs`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-021.

**Tham số.** `scope` (query, WeightScope, tùy chọn); `status` (query, WeightStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WeightConfigPage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/weight-configs
```

```http
HTTP/1.1 200 OK

{"items": [{"configCode": "tm-mac-dinh", "versionNo": 2, "scope": "TENANT", "status": "ACTIVE",
   "weights": {"completeness": 0.2, "accuracy": 0.2, "consistency": 0.15, "timeliness": 0.1,
    "uniqueness": 0.15}}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-08-048 · Tạo cấu hình trọng số nháp

::: dac-ta
**Mục đích.** Tạo cấu hình trọng số nháp.

**Phương thức, đường dẫn.** `POST /weight-configs`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-021.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `WeightConfigCreate`; trường bắt buộc: `configCode`, `scope`, `weights`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `WeightConfig`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-023, ERR-08-024, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/weight-configs
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"configCode": "tm-mac-dinh", "scope": "TENANT",
 "weights": {"completeness": 0.2, "accuracy": 0.2, "consistency": 0.15, "timeliness": 0.1,
  "uniqueness": 0.15}, "passMin": 90, "warnMin": 75, "domainCode": "HO_TICH",
 "assetCode": "mdm-cong-dan"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/weight-configs/ma-moi

{"configCode": "tm-mac-dinh", "versionNo": 2, "scope": "TENANT", "status": "ACTIVE",
 "weights": {"completeness": 0.2, "accuracy": 0.2, "consistency": 0.15, "timeliness": 0.1,
  "uniqueness": 0.15}, "passMin": 90, "warnMin": 75}
```

#### API-08-049 · Sửa cấu hình trọng số nháp

::: dac-ta
**Mục đích.** Sửa cấu hình trọng số nháp.

**Phương thức, đường dẫn.** `PUT /weight-configs/{configId}`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-021.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `WeightConfigUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WeightConfig`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-023, ERR-08-024 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/dq/v1/weight-configs/{configId}

{"weights": {"completeness": 0.2, "accuracy": 0.2, "consistency": 0.15, "timeliness": 0.1,
  "uniqueness": 0.15}, "passMin": 90, "warnMin": 75, "changeNote": "Điều chỉnh ngưỡng"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"configCode": "tm-mac-dinh", "versionNo": 2, "scope": "TENANT", "status": "ACTIVE",
 "weights": {"completeness": 0.2, "accuracy": 0.2, "consistency": 0.15, "timeliness": 0.1,
  "uniqueness": 0.15}, "passMin": 90, "warnMin": 75}
```

#### API-08-050 · Gửi duyệt cấu hình trọng số

::: dac-ta
**Mục đích.** Gửi duyệt cấu hình trọng số.

**Phương thức, đường dẫn.** `POST /weight-configs/{configId}:submit`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-021.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WeightConfig`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-023, ERR-08-024 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/weight-configs/{configId}:submit

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"configCode": "tm-mac-dinh", "versionNo": 2, "scope": "TENANT",
 "status": "PENDING_APPROVAL",
 "weights": {"completeness": 0.2, "accuracy": 0.2, "consistency": 0.15, "timeliness": 0.1,
  "uniqueness": 0.15}, "passMin": 90, "warnMin": 75}
```

#### API-08-051 · Duyệt cấu hình trọng số

::: dac-ta
**Mục đích.** Duyệt cấu hình trọng số.

**Phương thức, đường dẫn.** `POST /weight-configs/{configId}:approve`.

**Quyền.** `PERM-08-approve`.

**FR hiện thực.** FR-08-021.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WeightConfig`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-023, ERR-08-024 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/weight-configs/{configId}:approve

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"configCode": "tm-mac-dinh", "versionNo": 2, "scope": "TENANT", "status": "ACTIVE",
 "weights": {"completeness": 0.2, "accuracy": 0.2, "consistency": 0.15, "timeliness": 0.1,
  "uniqueness": 0.15}, "passMin": 90, "warnMin": 75}
```

#### API-08-052 · Từ chối cấu hình trọng số

::: dac-ta
**Mục đích.** Từ chối cấu hình trọng số.

**Phương thức, đường dẫn.** `POST /weight-configs/{configId}:reject`.

**Quyền.** `PERM-08-approve`.

**FR hiện thực.** FR-08-021.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WeightConfig`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-023, ERR-08-024 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/weight-configs/{configId}:reject

{"comment": "Thiếu căn cứ về ngưỡng, đề nghị bổ sung và gửi lại."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"configCode": "tm-mac-dinh", "versionNo": 2, "scope": "TENANT", "status": "DRAFT",
 "weights": {"completeness": 0.2, "accuracy": 0.2, "consistency": 0.15, "timeliness": 0.1,
  "uniqueness": 0.15}, "passMin": 90, "warnMin": 75}
```

#### API-08-132 · Xem trước điểm theo trọng số và ngưỡng

::: dac-ta
**Mục đích.** Xem trước điểm theo trọng số và ngưỡng.

**Phương thức, đường dẫn.** `POST /weight-configs:preview`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-021.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `WeightPreviewRequest`; trường bắt buộc: `scope`, `weights`, `passMin`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WeightPreview`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `422`; mã lỗi của thao tác: ERR-08-023, ERR-08-024, ERR-08-027 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ đọc: tính điểm giả định từ ảnh chụp đầy đủ gần nhất của các đối tượng trong phạm vi, không ghi dữ liệu, không cần bản nháp; chưa có ảnh chụp thì ERR-08-027.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/weight-configs:preview

{"scope": "DOMAIN",
 "weights": {"completeness": 0.2, "accuracy": 0.2, "consistency": 0.15, "timeliness": 0.1,
  "uniqueness": 0.15}, "passMin": 85, "warnMin": 75, "domainCode": "HO_TICH",
 "assetCode": "mdm-cong-dan"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"scope": "DOMAIN", "assetCount": 6, "changedVerdictCount": 0,
 "assets": [{"assetCode": "mdm-cong-dan", "currentScore": 91.2, "projectedScore": 90.1,
   "currentVerdict": "PASS", "projectedVerdict": "PASS"}], "currentScore": 91.2,
 "projectedScore": 90.1, "delta": -1.1}
```

### Lịch và lần đo

#### API-08-054 · Danh sách lịch đo

::: dac-ta
**Mục đích.** Danh sách lịch đo.

**Phương thức, đường dẫn.** `GET /schedules`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-023.

**Tham số.** `assetCode` (query, string, tùy chọn); `status` (query, ScheduleStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SchedulePage`.

**Lỗi.** HTTP `422`; mã lỗi của thao tác: ERR-08-027 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/schedules
```

```http
HTTP/1.1 200 OK

{"items": [{"scheduleId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
   "scheduleCode": "lich-cong-dan-thang", "assetCode": "mdm-cong-dan",
   "cron": "0 0 2 1 * ?", "timezone": "Asia/Ho_Chi_Minh"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-08-055 · Tạo lịch đo

::: dac-ta
**Mục đích.** Tạo lịch đo.

**Phương thức, đường dẫn.** `POST /schedules`.

**Quyền.** `PERM-08-run`.

**FR hiện thực.** FR-08-023.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ScheduleCreate`; trường bắt buộc: `scheduleCode`, `assetCode`, `cron`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Schedule`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-08-027, ERR-08-029, ERR-08-049, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/schedules
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"scheduleCode": "lich-cong-dan-thang", "assetCode": "mdm-cong-dan", "cron": "0 0 2 1 * ?",
 "scanMode": "FULL", "timezone": "Asia/Ho_Chi_Minh"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/schedules/ma-moi

{"scheduleId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "scheduleCode": "lich-cong-dan-thang", "assetCode": "mdm-cong-dan", "cron": "0 0 2 1 * ?",
 "timezone": "Asia/Ho_Chi_Minh", "scanMode": "FULL", "enabled": true}
```

#### API-08-056 · Sửa lịch đo

::: dac-ta
**Mục đích.** Sửa lịch đo.

**Phương thức, đường dẫn.** `PATCH /schedules/{scheduleId}`.

**Quyền.** `PERM-08-run`.

**FR hiện thực.** FR-08-023.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ScheduleUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Schedule`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-027, ERR-08-029, ERR-08-049 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/dq/v1/schedules/{scheduleId}

{"cron": "0 0 2 1 * ?", "timezone": "Asia/Ho_Chi_Minh", "scanMode": "FULL"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"scheduleId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "scheduleCode": "lich-cong-dan-thang", "assetCode": "mdm-cong-dan", "cron": "0 0 2 1 * ?",
 "timezone": "Asia/Ho_Chi_Minh", "scanMode": "FULL", "enabled": true}
```

#### API-08-057 · Tạm dừng lịch đo

::: dac-ta
**Mục đích.** Tạm dừng lịch đo.

**Phương thức, đường dẫn.** `POST /schedules/{scheduleId}:pause`.

**Quyền.** `PERM-08-run`.

**FR hiện thực.** FR-08-023.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Schedule`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-027, ERR-08-029, ERR-08-049 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/schedules/{scheduleId}:pause

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"scheduleId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "scheduleCode": "lich-cong-dan-thang", "assetCode": "mdm-cong-dan", "cron": "0 0 2 1 * ?",
 "timezone": "Asia/Ho_Chi_Minh", "scanMode": "FULL", "enabled": true}
```

#### API-08-058 · Tiếp tục lịch đo

::: dac-ta
**Mục đích.** Tiếp tục lịch đo.

**Phương thức, đường dẫn.** `POST /schedules/{scheduleId}:resume`.

**Quyền.** `PERM-08-run`.

**FR hiện thực.** FR-08-023.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Schedule`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-027, ERR-08-029, ERR-08-049 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/schedules/{scheduleId}:resume

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"scheduleId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "scheduleCode": "lich-cong-dan-thang", "assetCode": "mdm-cong-dan", "cron": "0 0 2 1 * ?",
 "timezone": "Asia/Ho_Chi_Minh", "scanMode": "FULL", "enabled": true}
```

#### API-08-059 · Chạy đo theo yêu cầu

::: dac-ta
**Mục đích.** Chạy đo theo yêu cầu.

**Phương thức, đường dẫn.** `POST /scans`.

**Quyền.** `PERM-08-run`.

**FR hiện thực.** FR-08-024, FR-08-054.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ScanCreate`; trường bắt buộc: `assetCode`, `scanMode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ScanJob`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `409`, `422`, `429`; mã lỗi của thao tác: ERR-08-027, ERR-08-028, ERR-08-030, ERR-08-052, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Hạn mức `08.scan.manual-per-hour` (ERR-08-052); đang có lần đo chạy trả ERR-08-028; báo cáo năm bắt buộc `FULL` (ERR-08-030).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/scans
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"assetCode": "mdm-cong-dan", "scanMode": "FULL", "scanTrigger": "MANUAL",
 "sampleSize": 10000, "sampleSeed": 20261126, "periodCode": "2026-11",
 "note": "Đo trước kỳ báo cáo"}
```

```http
HTTP/1.1 202 Accepted
ETag: W/"3"

{"scanId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
 "scanTrigger": "MANUAL", "scanMode": "FULL", "status": "QUEUED", "version": 3,
 "ruleSetVersionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"}
```

#### API-08-060 · Danh sách lần đo

::: dac-ta
**Mục đích.** Danh sách lần đo.

**Phương thức, đường dẫn.** `GET /scans`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-030.

**Tham số.** `assetCode` (query, string, tùy chọn); `status` (query, ScanStatus, tùy chọn); `scanTrigger` (query, ScanTrigger, tùy chọn); `periodCode` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ScanJobPage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/scans
```

```http
HTTP/1.1 200 OK

{"items": [{"scanId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
   "scanTrigger": "MANUAL", "scanMode": "FULL", "status": "RUNNING"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-08-061 · Chi tiết lần đo

::: dac-ta
**Mục đích.** Chi tiết lần đo.

**Phương thức, đường dẫn.** `GET /scans/{scanId}`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-026, FR-08-030, FR-08-031.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ScanJob`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/scans/{scanId}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"scanId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
 "scanTrigger": "MANUAL", "scanMode": "FULL", "status": "RUNNING", "version": 3,
 "ruleSetVersionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"}
```

#### API-08-062 · Hủy lần đo

::: dac-ta
**Mục đích.** Hủy lần đo.

**Phương thức, đường dẫn.** `POST /scans/{scanId}:cancel`.

**Quyền.** `PERM-08-run`.

**FR hiện thực.** FR-08-030.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ScanJob`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/scans/{scanId}:cancel

{"reason": "Nguồn dữ liệu đã ngừng cung cấp theo công văn số 123."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"scanId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
 "scanTrigger": "MANUAL", "scanMode": "FULL", "status": "CANCELLED", "version": 3,
 "ruleSetVersionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"}
```

#### API-08-063 · Chạy lại lần đo

::: dac-ta
**Mục đích.** Chạy lại lần đo.

**Phương thức, đường dẫn.** `POST /scans/{scanId}:rerun`.

**Quyền.** `PERM-08-run`.

**FR hiện thực.** FR-08-030.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RerunRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ScanJob`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tạo lần đo mới có `rerunOf` trỏ lần cũ; lần cũ phải ở trạng thái cuối.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/scans/{scanId}:rerun
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"reason": "Chạy lại sau khi nguồn khôi phục."}
```

```http
HTTP/1.1 202 Accepted
ETag: W/"3"

{"scanId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
 "scanTrigger": "MANUAL", "scanMode": "FULL", "status": "QUEUED", "version": 3,
 "ruleSetVersionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"}
```

#### API-08-064 · Kết quả theo quy tắc của lần đo

::: dac-ta
**Mục đích.** Kết quả theo quy tắc của lần đo.

**Phương thức, đường dẫn.** `GET /scans/{scanId}/rule-results`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-026, FR-08-027.

**Tham số.** `status` (query, RuleResultStatus, tùy chọn); `dimension` (query, Dimension, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RuleResultPage`.

**Lỗi.** `404` Không tìm thấy; `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/scans/{scanId}/rule-results
```

```http
HTTP/1.1 200 OK

{"items": [{"ruleCode": "CD-ACC-001", "dimension": "VALIDITY", "severity": "CRITICAL",
   "status": "FAILED", "rowsEvaluated": 400000}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-08-067 · Tác vụ phân mảnh của lần đo

::: dac-ta
**Mục đích.** Tác vụ phân mảnh của lần đo.

**Phương thức, đường dẫn.** `GET /scans/{scanId}/tasks`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-026, FR-08-030.

**Tham số.** `status` (query, TaskStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ScanTaskPage`.

**Lỗi.** `404` Không tìm thấy; `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/scans/{scanId}/tasks
```

```http
HTTP/1.1 200 OK

{"items": [{"taskId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "shardNo": 1, "shardCount": 6,
   "status": "SUCCEEDED", "keyFrom": "000000000001"}], "page": 0, "size": 20,
 "totalElements": 1}
```

### Điểm và thẻ điểm

#### API-08-065 · Điểm và điểm chiều của lần đo

::: dac-ta
**Mục đích.** Điểm và điểm chiều của lần đo.

**Phương thức, đường dẫn.** `GET /scans/{scanId}/score`.

**Quyền.** `PERM-08-read hoặc scope `dq.read``.

**FR hiện thực.** FR-08-028, FR-08-029.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ScoreSnapshot`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Điểm có cờ `INCOMPLETE_DIMENSIONS` khi một chiều `SKIPPED` (ERR-08-108).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/scans/{scanId}/score
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"snapshotId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "scanId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
 "scanMode": "FULL", "score": 92.5, "verdict": "PASS", "trend": "IMPROVED"}
```

#### API-08-066 · Lịch sử điểm của đối tượng

::: dac-ta
**Mục đích.** Lịch sử điểm của đối tượng.

**Phương thức, đường dẫn.** `GET /assets/{assetCode}/score-history`.

**Quyền.** `PERM-08-read hoặc scope `dq.read``.

**FR hiện thực.** FR-08-029.

**Tham số.** `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `official` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ScorePointPage`.

**Lỗi.** `404` Không tìm thấy; `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/assets/{assetCode}/score-history
```

```http
HTTP/1.1 200 OK

{"items": [{"snapshotId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
   "scanId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
   "measuredAt": "2026-11-20T08:00:00+07:00", "score": 92.5, "verdict": "PASS"}],
 "page": 0, "size": 20, "totalElements": 1}
```

### Kiểm tra trực tuyến

#### API-08-068 · Kiểm tra trực tuyến một bản ghi

::: dac-ta
**Mục đích.** Kiểm tra trực tuyến một bản ghi.

**Phương thức, đường dẫn.** `POST /checks:evaluate`.

**Quyền.** scope `dq.check`.

**FR hiện thực.** FR-08-032, FR-08-033, FR-08-035.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CheckRequest`; trường bắt buộc: `assetCode`, `record`, `caller`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CheckResult`.

**Lỗi.** HTTP `400`, `404`, `422`, `503`, `504`; mã lỗi của thao tác: ERR-08-101, ERR-08-102, ERR-08-103, ERR-08-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Scope `dq.check`; ngân sách `08.inline.timeout-ms` (mặc định 40 ms, p95 ≤ 50 ms). Không có tiêu đề `If-Match`. `FAIL_OPEN` trả `200` kèm `degraded = true`; `FAIL_CLOSED` trả `503` hoặc `504`. Phản hồi không chứa giá trị bản ghi.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/checks:evaluate

{"assetCode": "mdm-cong-dan",
 "record": {"citizenId": "0791234567", "fullName": "Nguyễn Văn A", "ethnicCode": "01"},
 "caller": "luong-dang-ky-khai-sinh", "mode": "STRICT", "dimensions": ["VALIDITY"],
 "correlationId": "msg-20261126-0001"}
```

```http
HTTP/1.1 200 OK

{"verdict": "FAIL", "degraded": false,
 "violations": [{"ruleCode": "CD-ACC-001", "dimension": "VALIDITY", "severity": "CRITICAL",
   "fieldPath": "citizenId", "message": "Số định danh không đủ 12 chữ số"}],
 "evaluatedRules": 14, "durationMs": 12, "ruleSetVersion": 4,
 "correlationId": "msg-20261126-0001"}
```

#### API-08-069 · Kiểm tra trực tuyến lô bản ghi

::: dac-ta
**Mục đích.** Kiểm tra trực tuyến lô bản ghi.

**Phương thức, đường dẫn.** `POST /checks:evaluate-batch`.

**Quyền.** scope `dq.check`.

**FR hiện thực.** FR-08-032.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CheckBatchRequest`; trường bắt buộc: `assetCode`, `records`, `caller`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CheckBatchResult`.

**Lỗi.** HTTP `400`, `404`, `422`, `503`, `504`; mã lỗi của thao tác: ERR-08-101, ERR-08-102, ERR-08-103, ERR-08-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tối đa 100 bản ghi mỗi lần; kết luận từng bản ghi, cùng chính sách phụ thuộc lỗi như API-08-068.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/checks:evaluate-batch

{"assetCode": "mdm-cong-dan",
 "records": [{"correlationId": "msg-20261126-0001", "record": {"citizenId": "079123456789"}}],
 "caller": "PH-06", "mode": "ADVISORY", "dimensions": ["VALIDITY"]}
```

```http
HTTP/1.1 200 OK

{"results": [{"correlationId": "msg-20261126-0001", "verdict": "PASS", "violations": []}],
 "degraded": false, "durationMs": 31, "ruleSetVersion": 4}
```

#### API-08-070 · Thống kê kiểm tra trực tuyến

::: dac-ta
**Mục đích.** Thống kê kiểm tra trực tuyến.

**Phương thức, đường dẫn.** `GET /inline-stats`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-034.

**Tham số.** `assetCode` (query, string, tùy chọn); `caller` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `granularity` (query, Granularity, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `InlineStats`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/inline-stats
```

```http
HTTP/1.1 200 OK

{"granularity": "MINUTE",
 "series": [{"bucketAt": "2026-11-20T08:00:00+07:00", "assetCode": "mdm-cong-dan", "checkCount": 1200,
   "passCount": 1130, "failCount": 30}],
 "topRules": [{"ruleCode": "CD-ACC-001", "failCount": 21}], "p95Ms": 18}
```

#### API-08-071 · Cấu hình kiểm tra trực tuyến

::: dac-ta
**Mục đích.** Cấu hình kiểm tra trực tuyến.

**Phương thức, đường dẫn.** `PUT /assets/{assetCode}/inline-config`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-032, FR-08-035.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `InlineConfigPut`; trường bắt buộc: `inlineEnabled`, `inlineMode`, `onDependencyFailure`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `InlineConfig`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`, `503`, `504`; mã lỗi của thao tác: ERR-08-101, ERR-08-102, ERR-08-103, ERR-08-104 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Bật hoặc tắt kiểm tra trực tuyến, chế độ `STRICT` hoặc `ADVISORY`, chính sách khi phụ thuộc lỗi; chưa có cấu hình thì gửi `If-Match: *`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/dq/v1/assets/{assetCode}/inline-config

{"inlineEnabled": true, "inlineMode": "STRICT", "onDependencyFailure": "FAIL_OPEN",
 "timeoutMs": 40, "gateEnabled": false}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assetCode": "mdm-cong-dan", "inlineEnabled": true, "inlineMode": "STRICT",
 "onDependencyFailure": "FAIL_OPEN", "timeoutMs": 40, "version": 2, "gateEnabled": false}
```

#### API-08-072 · Xem cấu hình kiểm tra trực tuyến

::: dac-ta
**Mục đích.** Xem cấu hình kiểm tra trực tuyến.

**Phương thức, đường dẫn.** `GET /assets/{assetCode}/inline-config`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-032.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `InlineConfig`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/assets/{assetCode}/inline-config
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assetCode": "mdm-cong-dan", "inlineEnabled": true, "inlineMode": "STRICT",
 "onDependencyFailure": "FAIL_OPEN", "timeoutMs": 40, "version": 2, "gateEnabled": false}
```

### Bản ghi lỗi

#### API-08-073 · Danh sách bản ghi lỗi

::: dac-ta
**Mục đích.** Danh sách bản ghi lỗi.

**Phương thức, đường dẫn.** `GET /findings`.

**Quyền.** `PERM-08-finding-read`.

**FR hiện thực.** FR-08-037.

**Tham số.** `assetCode` (query, string, tùy chọn); `ruleCode` (query, string, tùy chọn); `dimension` (query, Dimension, tùy chọn); `severity` (query, Severity, tùy chọn); `status` (query, FindingStatus, tùy chọn); `ownerOrgCode` (query, string, tùy chọn); `scanId` (query, string, tùy chọn); `fieldName` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FindingPage`.

**Lỗi.** HTTP `422`; mã lỗi của thao tác: ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giá trị trường Nhạy cảm chỉ là băm; DO chỉ thấy lỗi của tổ chức mình (ERR-08-032). Tìm theo khóa cá nhân dùng API-08-129.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/findings
```

```http
HTTP/1.1 200 OK

{"items": [{"findingId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
   "ruleCode": "CD-ACC-001", "dimension": "VALIDITY", "severity": "CRITICAL"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-08-074 · Chi tiết bản ghi lỗi

::: dac-ta
**Mục đích.** Chi tiết bản ghi lỗi.

**Phương thức, đường dẫn.** `GET /findings/{findingId}`.

**Quyền.** `PERM-08-finding-read`.

**FR hiện thực.** FR-08-038.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FindingDetail`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/findings/{findingId}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"finding": {"findingId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
  "ruleCode": "CD-ACC-001", "dimension": "VALIDITY", "severity": "CRITICAL"},
 "history": [{"scanId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "seenAt": "2026-11-20T08:00:00+07:00",
   "status": "OPEN"}],
 "goldenRecord": {"domainCode": "CITIZEN", "goldenId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"}}
```

#### API-08-075 · Đề nghị xuất bản ghi lỗi

::: dac-ta
**Mục đích.** Đề nghị xuất bản ghi lỗi.

**Phương thức, đường dẫn.** `POST /findings:export`.

**Quyền.** `PERM-08-export`.

**FR hiện thực.** FR-08-039.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `FindingExportCreate`; trường bắt buộc: `assetCode`, `format`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ExportRequest`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-041, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Có trường Nhạy cảm thì `status = PENDING_APPROVAL` đến khi DO chấp thuận (API-08-076).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/findings:export
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"assetCode": "mdm-cong-dan", "format": "XLSX",
 "filter": {"severity": "CRITICAL", "status": "OPEN"},
 "reason": "Gửi danh sách lỗi cho chủ quản xử lý."}
```

```http
HTTP/1.1 202 Accepted
ETag: W/"3"

{"exportId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "format": "XLSX",
 "status": "PENDING_APPROVAL", "containsRestricted": false, "version": 3,
 "kind": "FINDINGS", "assetCode": "mdm-cong-dan"}
```

#### API-08-076 · Chấp thuận hoặc từ chối xuất

::: dac-ta
**Mục đích.** Chấp thuận hoặc từ chối xuất.

**Phương thức, đường dẫn.** `POST /exports/{exportId}:approve`.

**Quyền.** `PERM-08-export hoặc PERM-08-finding-read`.

**FR hiện thực.** FR-08-039.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ExportDecision`; trường bắt buộc: `decision`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ExportRequest`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `410`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-041 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Tệp chưa chấp thuận trả `409`, hết hạn tải `410` (ERR-08-041).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/exports/{exportId}:approve

{"decision": "APPROVE", "comment": "Đồng ý, tệp chỉ gửi cho đầu mối của sở."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"exportId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "format": "XLSX",
 "status": "APPROVED", "containsRestricted": false, "version": 3, "kind": "FINDINGS",
 "assetCode": "mdm-cong-dan"}
```

#### API-08-077 · Trạng thái và liên kết tải tệp xuất

::: dac-ta
**Mục đích.** Trạng thái và liên kết tải tệp xuất.

**Phương thức, đường dẫn.** `GET /exports/{exportId}`.

**Quyền.** `PERM-08-export`.

**FR hiện thực.** FR-08-039.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ExportRequest`; tiêu đề `ETag`.

**Lỗi.** HTTP `404`, `409`, `410`; mã lỗi của thao tác: ERR-08-041 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/exports/{exportId}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"exportId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "format": "XLSX", "status": "READY",
 "containsRestricted": false, "version": 3, "kind": "FINDINGS", "assetCode": "mdm-cong-dan"}
```

#### API-08-078 · Nhóm bản ghi lỗi

::: dac-ta
**Mục đích.** Nhóm bản ghi lỗi.

**Phương thức, đường dẫn.** `GET /finding-groups`.

**Quyền.** `PERM-08-finding-read`.

**FR hiện thực.** FR-08-037, FR-08-041.

**Tham số.** `assetCode` (query, string, tùy chọn); `severity` (query, Severity, tùy chọn); `ownerOrgCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FindingGroupPage`.

**Lỗi.** HTTP `422`; mã lỗi của thao tác: ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/finding-groups
```

```http
HTTP/1.1 200 OK

{"items": [{"groupKey": "mdm-cong-dan|CD-ACC-001|so-tu-phap", "assetCode": "mdm-cong-dan",
   "ruleCode": "CD-ACC-001", "dimension": "VALIDITY", "severity": "CRITICAL"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-08-129 · Tìm bản ghi lỗi theo khóa bản ghi

::: dac-ta
**Mục đích.** Tìm bản ghi lỗi theo khóa bản ghi.

**Phương thức, đường dẫn.** `POST /findings:search`.

**Quyền.** `PERM-08-finding-read`.

**FR hiện thực.** FR-08-037.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `FindingSearchRequest`; trường bắt buộc: `assetCode`, `recordKey`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `FindingPage`.

**Lỗi.** HTTP `400`, `422`; mã lỗi của thao tác: ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Mã API cấp thêm vì FRS dùng chung API-08-073 cho GET và POST; khóa bản ghi gửi trong thân để không lọt vào log của cổng.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/findings:search

{"assetCode": "mdm-cong-dan", "recordKey": "079123456789"}
```

```http
HTTP/1.1 200 OK

{"items": [{"findingId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
   "ruleCode": "CD-ACC-001", "dimension": "VALIDITY", "severity": "CRITICAL"}], "page": 0,
 "size": 20, "totalElements": 1}
```

### Ngoại lệ

#### API-08-079 · Đề nghị ngoại lệ chấp nhận

::: dac-ta
**Mục đích.** Đề nghị ngoại lệ chấp nhận.

**Phương thức, đường dẫn.** `POST /waivers`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-040.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `WaiverCreate`; trường bắt buộc: `assetCode`, `scope`, `reason`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Waiver`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-033, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/waivers
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"assetCode": "mdm-cong-dan", "scope": "FINDINGS",
 "reason": "Dữ liệu lịch sử trước 2015 chưa thể bổ sung số định danh.",
 "validFrom": "2026-11-26", "validTo": "2027-05-25", "ruleCode": "CD-ACC-001",
 "findingIds": ["0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"]}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/waivers/ma-moi

{"waiverId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
 "scope": "FINDINGS", "status": "PENDING_APPROVAL",
 "reason": "Dữ liệu lịch sử trước 2015 chưa thể bổ sung số định danh.", "version": 3,
 "ruleCode": "CD-ACC-001"}
```

#### API-08-080 · Danh sách ngoại lệ

::: dac-ta
**Mục đích.** Danh sách ngoại lệ.

**Phương thức, đường dẫn.** `GET /waivers`.

**Quyền.** `PERM-08-finding-read`.

**FR hiện thực.** FR-08-040.

**Tham số.** `assetCode` (query, string, tùy chọn); `status` (query, WaiverStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `WaiverPage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/waivers
```

```http
HTTP/1.1 200 OK

{"items": [{"waiverId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
   "scope": "FINDINGS", "status": "PENDING_APPROVAL",
   "reason": "Dữ liệu lịch sử trước 2015 chưa thể bổ sung số định danh."}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-08-081 · Duyệt ngoại lệ

::: dac-ta
**Mục đích.** Duyệt ngoại lệ.

**Phương thức, đường dẫn.** `POST /waivers/{waiverId}:approve`.

**Quyền.** `PERM-08-approve`.

**FR hiện thực.** FR-08-040.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Waiver`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-033 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/waivers/{waiverId}:approve

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"waiverId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
 "scope": "FINDINGS", "status": "ACTIVE",
 "reason": "Dữ liệu lịch sử trước 2015 chưa thể bổ sung số định danh.", "version": 3,
 "ruleCode": "CD-ACC-001"}
```

#### API-08-082 · Từ chối ngoại lệ

::: dac-ta
**Mục đích.** Từ chối ngoại lệ.

**Phương thức, đường dẫn.** `POST /waivers/{waiverId}:reject`.

**Quyền.** `PERM-08-approve`.

**FR hiện thực.** FR-08-040.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Waiver`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-033 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/waivers/{waiverId}:reject

{"comment": "Thiếu căn cứ về ngưỡng, đề nghị bổ sung và gửi lại."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"waiverId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
 "scope": "FINDINGS", "status": "REJECTED",
 "reason": "Dữ liệu lịch sử trước 2015 chưa thể bổ sung số định danh.", "version": 3,
 "ruleCode": "CD-ACC-001"}
```

#### API-08-083 · Thu hồi ngoại lệ

::: dac-ta
**Mục đích.** Thu hồi ngoại lệ.

**Phương thức, đường dẫn.** `POST /waivers/{waiverId}:revoke`.

**Quyền.** `PERM-08-approve`.

**FR hiện thực.** FR-08-040.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Waiver`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-033 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/waivers/{waiverId}:revoke

{"reason": "Nguồn dữ liệu đã ngừng cung cấp theo công văn số 123."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"waiverId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
 "scope": "FINDINGS", "status": "REVOKED",
 "reason": "Dữ liệu lịch sử trước 2015 chưa thể bổ sung số định danh.", "version": 3,
 "ruleCode": "CD-ACC-001"}
```

### Phiếu khắc phục

#### API-08-084 · Mở phiếu khắc phục

::: dac-ta
**Mục đích.** Mở phiếu khắc phục.

**Phương thức, đường dẫn.** `POST /issues`.

**Quyền.** `PERM-08-remediate`.

**FR hiện thực.** FR-08-041.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IssueCreate`; trường bắt buộc: `assetCode`, `ruleCode`, `title`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Issue`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`; mã lỗi của thao tác: ERR-08-034, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/issues
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"assetCode": "mdm-cong-dan", "ruleCode": "CD-ACC-001",
 "title": "Số định danh sai mẫu ở hộ tịch", "severity": "CRITICAL",
 "ownerOrgCode": "so-tu-phap", "findingIds": ["0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01"],
 "groupKey": "mdm-cong-dan|CD-ACC-001|so-tu-phap"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/issues/ma-moi

{"issueCode": "DQ-2026-000142", "assetCode": "mdm-cong-dan",
 "title": "Số định danh sai mẫu ở hộ tịch", "severity": "CRITICAL", "findingCount": 312,
 "ownerOrgCode": "so-tu-phap", "status": "ASSIGNED"}
```

#### API-08-085 · Danh sách phiếu khắc phục

::: dac-ta
**Mục đích.** Danh sách phiếu khắc phục.

**Phương thức, đường dẫn.** `GET /issues`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-042.

**Tham số.** `assetCode` (query, string, tùy chọn); `status` (query, IssueStatus, tùy chọn); `severity` (query, Severity, tùy chọn); `ownerOrgCode` (query, string, tùy chọn); `assignee` (query, string, tùy chọn); `overdue` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IssuePage`.

**Lỗi.** HTTP `422`; mã lỗi của thao tác: ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/issues
```

```http
HTTP/1.1 200 OK

{"items": [{"issueCode": "DQ-2026-000142", "assetCode": "mdm-cong-dan",
   "title": "Số định danh sai mẫu ở hộ tịch", "severity": "CRITICAL", "findingCount": 312}],
 "page": 0, "size": 20, "totalElements": 1,
 "facets": {"byStatus": {"ASSIGNED": 6, "IN_PROGRESS": 9, "FIXED": 2}, "overdue": 3, "dueSoon": 4}}
```

#### API-08-086 · Chi tiết phiếu khắc phục

::: dac-ta
**Mục đích.** Chi tiết phiếu khắc phục.

**Phương thức, đường dẫn.** `GET /issues/{issueCode}`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-042, FR-08-043.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Issue`; tiêu đề `ETag`.

**Lỗi.** HTTP `404`; mã lỗi của thao tác: ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/issues/{issueCode}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"issueCode": "DQ-2026-000142", "assetCode": "mdm-cong-dan",
 "title": "Số định danh sai mẫu ở hộ tịch", "severity": "CRITICAL", "findingCount": 312,
 "ownerOrgCode": "so-tu-phap", "status": "ASSIGNED"}
```

#### API-08-087 · Phân công phiếu

::: dac-ta
**Mục đích.** Phân công phiếu.

**Phương thức, đường dẫn.** `POST /issues/{issueCode}:assign`.

**Quyền.** `PERM-08-remediate`.

**FR hiện thực.** FR-08-042.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `IssueAssign`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Issue`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007, ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/issues/{issueCode}:assign

{"ownerOrgCode": "so-tu-phap", "assignee": "le.thi.hoa", "slaDays": 5,
 "comment": "Đề nghị xử lý trong 5 ngày làm việc."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"issueCode": "DQ-2026-000142", "assetCode": "mdm-cong-dan",
 "title": "Số định danh sai mẫu ở hộ tịch", "severity": "CRITICAL", "findingCount": 312,
 "ownerOrgCode": "so-tu-phap", "status": "ASSIGNED"}
```

#### API-08-088 · Bắt đầu xử lý phiếu

::: dac-ta
**Mục đích.** Bắt đầu xử lý phiếu.

**Phương thức, đường dẫn.** `POST /issues/{issueCode}:start`.

**Quyền.** `PERM-08-remediate`.

**FR hiện thực.** FR-08-043.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Issue`; tiêu đề `ETag`.

**Lỗi.** `400` Dữ liệu không hợp lệ; `404` Không tìm thấy; `409` Xung đột.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/issues/{issueCode}:start

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"issueCode": "DQ-2026-000142", "assetCode": "mdm-cong-dan",
 "title": "Số định danh sai mẫu ở hộ tịch", "severity": "CRITICAL", "findingCount": 312,
 "ownerOrgCode": "so-tu-phap", "status": "IN_PROGRESS"}
```

#### API-08-089 · Thêm trao đổi vào phiếu

::: dac-ta
**Mục đích.** Thêm trao đổi vào phiếu.

**Phương thức, đường dẫn.** `POST /issues/{issueCode}/activities`.

**Quyền.** `PERM-08-remediate`.

**FR hiện thực.** FR-08-043.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `IssueActivityCreate`; trường bắt buộc: `activityType`, `comment`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `IssueActivity`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `404`, `409`, `413`; mã lỗi của thao tác: ERR-08-046, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/issues/{issueCode}/activities
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"activityType": "COMMENT", "comment": "Đã đối chiếu với sổ gốc, đang sửa lô đầu.",
 "attachmentRef": "ví dụ"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/issues/ma-moi

{"activityId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "activityType": "COMMENT",
 "actor": "le.thi.hoa", "occurredAt": "2026-11-20T08:00:00+07:00",
 "fromStatus": "ASSIGNED", "toStatus": "IN_PROGRESS", "comment": "Đã bắt đầu xử lý"}
```

#### API-08-090 · Báo đã sửa

::: dac-ta
**Mục đích.** Báo đã sửa.

**Phương thức, đường dẫn.** `POST /issues/{issueCode}:mark-fixed`.

**Quyền.** `PERM-08-remediate`.

**FR hiện thực.** FR-08-044.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `IssueMarkFixed`; trường bắt buộc: `fixNote`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Issue`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-035, ERR-08-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/issues/{issueCode}:mark-fixed

{"fixNote": "Đã rà soát và sửa số định danh theo sổ hộ tịch, lô 312 bản ghi."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"issueCode": "DQ-2026-000142", "assetCode": "mdm-cong-dan",
 "title": "Số định danh sai mẫu ở hộ tịch", "severity": "CRITICAL", "findingCount": 312,
 "ownerOrgCode": "so-tu-phap", "status": "FIXED"}
```

#### API-08-091 · Xác nhận, đo kiểm chứng

::: dac-ta
**Mục đích.** Xác nhận, đo kiểm chứng.

**Phương thức, đường dẫn.** `POST /issues/{issueCode}:verify`.

**Quyền.** `PERM-08-remediate`.

**FR hiện thực.** FR-08-044.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `IssueVerify`; trường bắt buộc: `mode`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Issue`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-035, ERR-08-036 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chế độ `SCAN` tạo lần đo trigger `VERIFY`; DO không tự xác nhận (ERR-08-035).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/issues/{issueCode}:verify

{"mode": "SCAN", "comment": "Đo lại sau khi PH-06 nhận cập nhật."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"issueCode": "DQ-2026-000142", "assetCode": "mdm-cong-dan",
 "title": "Số định danh sai mẫu ở hộ tịch", "severity": "CRITICAL", "findingCount": 312,
 "ownerOrgCode": "so-tu-phap", "status": "FIXED"}
```

#### API-08-092 · Từ chối phiếu

::: dac-ta
**Mục đích.** Từ chối phiếu.

**Phương thức, đường dẫn.** `POST /issues/{issueCode}:reject`.

**Quyền.** `PERM-08-remediate`.

**FR hiện thực.** FR-08-045.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `IssueReject`; trường bắt buộc: `rejectType`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Issue`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/issues/{issueCode}:reject

{"rejectType": "WRONG_OWNER",
 "reason": "Dữ liệu này do sở khác quản lý theo quyết định số 45."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"issueCode": "DQ-2026-000142", "assetCode": "mdm-cong-dan",
 "title": "Số định danh sai mẫu ở hộ tịch", "severity": "CRITICAL", "findingCount": 312,
 "ownerOrgCode": "so-tu-phap", "status": "REJECTED"}
```

#### API-08-093 · Chuyển phiếu sang tổ chức khác

::: dac-ta
**Mục đích.** Chuyển phiếu sang tổ chức khác.

**Phương thức, đường dẫn.** `POST /issues/{issueCode}:transfer`.

**Quyền.** `PERM-08-remediate`.

**FR hiện thực.** FR-08-045.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `IssueTransfer`; trường bắt buộc: `ownerOrgCode`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Issue`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/issues/{issueCode}:transfer

{"ownerOrgCode": "so-tu-phap",
 "reason": "Chuyển sang sở chủ quản đúng theo quyết định số 45.", "assignee": "ví dụ"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"issueCode": "DQ-2026-000142", "assetCode": "mdm-cong-dan",
 "title": "Số định danh sai mẫu ở hộ tịch", "severity": "CRITICAL", "findingCount": 312,
 "ownerOrgCode": "so-tu-phap", "status": "ASSIGNED"}
```

#### API-08-094 · Leo thang phiếu

::: dac-ta
**Mục đích.** Leo thang phiếu.

**Phương thức, đường dẫn.** `POST /issues/{issueCode}:escalate`.

**Quyền.** `PERM-08-remediate`.

**FR hiện thực.** FR-08-045.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `IssueEscalate`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Issue`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/issues/{issueCode}:escalate

{"reason": "Quá hạn 6 ngày làm việc, chưa có phản hồi.", "toLevel": 1}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"issueCode": "DQ-2026-000142", "assetCode": "mdm-cong-dan",
 "title": "Số định danh sai mẫu ở hộ tịch", "severity": "CRITICAL", "findingCount": 312,
 "ownerOrgCode": "so-tu-phap", "status": "ASSIGNED"}
```

#### API-08-095 · Chuyển lỗi bản ghi vàng sang steward PH-06

::: dac-ta
**Mục đích.** Chuyển lỗi bản ghi vàng sang steward PH-06.

**Phương thức, đường dẫn.** `POST /issues/{issueCode}:send-to-steward`.

**Quyền.** `PERM-08-remediate`.

**FR hiện thực.** FR-08-046.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `IssueSendToSteward`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `StewardTransfer`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`, `503`; mã lỗi của thao tác: ERR-08-051, ERR-08-105 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ lỗi của bản ghi vàng (ERR-08-051); PH-06 nhận qua API nội bộ, tạo mục hàng đợi lý do `DQ_FINDING`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/issues/{issueCode}:send-to-steward

{"action": "REVIEW_VALUE", "comment": "Hai bản ghi vàng nghi trùng."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"issueCode": "DQ-2026-000142", "stewardItemRef": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
 "status": "IN_PROGRESS", "forwardedAt": "2026-11-20T08:00:00+07:00"}
```

#### API-08-096 · Hủy phiếu

::: dac-ta
**Mục đích.** Hủy phiếu.

**Phương thức, đường dẫn.** `POST /issues/{issueCode}:cancel`.

**Quyền.** `PERM-08-remediate`.

**FR hiện thực.** FR-08-045.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Issue`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/issues/{issueCode}:cancel

{"reason": "Nguồn dữ liệu đã ngừng cung cấp theo công văn số 123."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"issueCode": "DQ-2026-000142", "assetCode": "mdm-cong-dan",
 "title": "Số định danh sai mẫu ở hộ tịch", "severity": "CRITICAL", "findingCount": 312,
 "ownerOrgCode": "so-tu-phap", "status": "CANCELLED"}
```

#### API-08-097 · Lịch sử trao đổi của phiếu

::: dac-ta
**Mục đích.** Lịch sử trao đổi của phiếu.

**Phương thức, đường dẫn.** `GET /issues/{issueCode}/activities`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-043.

**Tham số.** `activityType` (query, ActivityType, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `IssueActivityPage`.

**Lỗi.** `404` Không tìm thấy; `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/issues/{issueCode}/activities
```

```http
HTTP/1.1 200 OK

{"items": [{"activityId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "activityType": "COMMENT",
   "actor": "le.thi.hoa", "occurredAt": "2026-11-20T08:00:00+07:00",
   "fromStatus": "ASSIGNED"}], "page": 0, "size": 20, "totalElements": 1}
```

### Cảnh báo

#### API-08-098 · Danh sách quy tắc cảnh báo

::: dac-ta
**Mục đích.** Danh sách quy tắc cảnh báo.

**Phương thức, đường dẫn.** `GET /alert-rules`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-047.

**Tham số.** `assetCode` (query, string, tùy chọn); `enabled` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AlertRulePage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/alert-rules
```

```http
HTTP/1.1 200 OK

{"items": [{"alertRuleCode": "cb-diem-duoi-ngung", "name": "Điểm dưới ngưỡng cảnh báo",
   "conditionType": "SCORE_BELOW", "severity": "HIGH", "channels": ["IN_APP"]}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-08-099 · Tạo quy tắc cảnh báo

::: dac-ta
**Mục đích.** Tạo quy tắc cảnh báo.

**Phương thức, đường dẫn.** `POST /alert-rules`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-047.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AlertRuleUpsert`; trường bắt buộc: `alertRuleCode`, `name`, `conditionType`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `AlertRule`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-08-037, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/alert-rules
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"alertRuleCode": "cb-diem-duoi-ngung", "name": "Điểm dưới ngưỡng cảnh báo",
 "conditionType": "SCORE_BELOW", "severity": "HIGH", "channels": ["IN_APP"],
 "recipients": [{"recipientType": "ROLE", "recipientRef": "DS"}], "domainCode": "HO_TICH"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/alert-rules/ma-moi

{"alertRuleCode": "cb-diem-duoi-ngung", "name": "Điểm dưới ngưỡng cảnh báo",
 "conditionType": "SCORE_BELOW", "severity": "HIGH", "channels": ["IN_APP"],
 "recipients": [{"recipientType": "ROLE", "recipientRef": "DS"}], "enabled": true}
```

#### API-08-100 · Sửa quy tắc cảnh báo

::: dac-ta
**Mục đích.** Sửa quy tắc cảnh báo.

**Phương thức, đường dẫn.** `PUT /alert-rules/{alertRuleCode}`.

**Quyền.** `PERM-08-rule-admin`.

**FR hiện thực.** FR-08-047.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `AlertRuleUpsert`; trường bắt buộc: `alertRuleCode`, `name`, `conditionType`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AlertRule`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-037 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/dq/v1/alert-rules/{alertRuleCode}

{"alertRuleCode": "cb-diem-duoi-ngung", "name": "Điểm dưới ngưỡng cảnh báo",
 "conditionType": "SCORE_BELOW", "severity": "HIGH", "channels": ["IN_APP"],
 "recipients": [{"recipientType": "ROLE", "recipientRef": "DS"}], "domainCode": "HO_TICH"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"alertRuleCode": "cb-diem-duoi-ngung", "name": "Điểm dưới ngưỡng cảnh báo",
 "conditionType": "SCORE_BELOW", "severity": "HIGH", "channels": ["IN_APP"],
 "recipients": [{"recipientType": "ROLE", "recipientRef": "DS"}], "enabled": true}
```

#### API-08-101 · Danh sách cảnh báo

::: dac-ta
**Mục đích.** Danh sách cảnh báo.

**Phương thức, đường dẫn.** `GET /alerts`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-048, FR-08-049.

**Tham số.** `status` (query, AlertStatus, tùy chọn); `severity` (query, AlertSeverity, tùy chọn); `assetCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AlertPage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/alerts
```

```http
HTTP/1.1 200 OK

{"items": [{"alertId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "alertRuleCode": "cb-diem-duoi-ngung",
   "severity": "HIGH", "status": "FIRING",
   "message": "Điểm chất lượng 71,2 thấp hơn ngưỡng cảnh báo 75."}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-08-102 · Xác nhận cảnh báo

::: dac-ta
**Mục đích.** Xác nhận cảnh báo.

**Phương thức, đường dẫn.** `POST /alerts/{alertId}:acknowledge`.

**Quyền.** `PERM-08-run hoặc PERM-08-rule-admin`.

**FR hiện thực.** FR-08-049.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Alert`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007, ERR-08-042 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/alerts/{alertId}:acknowledge

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"alertId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "alertRuleCode": "cb-diem-duoi-ngung",
 "severity": "HIGH", "status": "ACKNOWLEDGED",
 "message": "Điểm chất lượng 71,2 thấp hơn ngưỡng cảnh báo 75.",
 "firedAt": "2026-11-20T08:00:00+07:00", "version": 3}
```

#### API-08-103 · Tắt tiếng cảnh báo

::: dac-ta
**Mục đích.** Tắt tiếng cảnh báo.

**Phương thức, đường dẫn.** `POST /alerts/{alertId}:silence`.

**Quyền.** `PERM-08-run hoặc PERM-08-rule-admin`.

**FR hiện thực.** FR-08-049.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `AlertSilence`; trường bắt buộc: `silencedUntil`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Alert`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-007, ERR-08-042 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/alerts/{alertId}:silence

{"silencedUntil": "2026-11-20T08:00:00+07:00",
 "reason": "Đang bảo trì nguồn dữ liệu, tắt trong 24 giờ."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"alertId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "alertRuleCode": "cb-diem-duoi-ngung",
 "severity": "HIGH", "status": "SILENCED",
 "message": "Điểm chất lượng 71,2 thấp hơn ngưỡng cảnh báo 75.",
 "firedAt": "2026-11-20T08:00:00+07:00", "version": 3}
```

### Bảng điều khiển và thẻ điểm

#### API-08-104 · Bảng điều khiển chất lượng

::: dac-ta
**Mục đích.** Bảng điều khiển chất lượng.

**Phương thức, đường dẫn.** `GET /dashboard`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-050.

**Tham số.** `periodCode` (query, string, tùy chọn); `domainCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Dashboard`.

**Lỗi.** HTTP `422`; mã lỗi của thao tác: ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/dashboard
```

```http
HTTP/1.1 200 OK

{"domains": [{"domainCode": "HO_TICH", "name": "Hộ tịch", "assetCount": 6, "score": 92.5,
   "verdict": "PASS"}], "dimensions": [{"dimension": "VALIDITY", "score": 92.5}],
 "trendSeries": [{"periodCode": "2026-11", "score": 92.5}],
 "issues": {"open": 18, "overdue": 3, "bySeverity": {"CRITICAL": 2, "MAJOR": 9, "MINOR": 7}},
 "periodCode": "2026-11", "tenantScore": 92.5, "verdict": "PASS"}
```

#### API-08-105 · Thẻ điểm theo phạm vi

::: dac-ta
**Mục đích.** Thẻ điểm theo phạm vi.

**Phương thức, đường dẫn.** `GET /scorecards`.

**Quyền.** `PERM-08-read hoặc scope `dq.read``.

**FR hiện thực.** FR-08-051.

**Tham số.** `scope` (query, ScorecardScope, tùy chọn); `periodCode` (query, string, tùy chọn); `verdict` (query, Verdict, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ScorecardPage`.

**Lỗi.** HTTP `404`, `422`; mã lỗi của thao tác: ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/scorecards
```

```http
HTTP/1.1 200 OK

{"items": [{"scope": "DOMAIN", "key": "HO_TICH", "name": "Hộ tịch", "score": 92.5, "verdict": "PASS"}],
 "page": 0, "size": 20, "totalElements": 1}
```

#### API-08-106 · Thẻ điểm của một đối tượng đo

::: dac-ta
**Mục đích.** Thẻ điểm của một đối tượng đo.

**Phương thức, đường dẫn.** `GET /scorecards/assets/{assetCode}`.

**Quyền.** `PERM-08-read hoặc scope `dq.read``.

**FR hiện thực.** FR-08-051.

**Tham số.** `periodCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AssetScorecard`; tiêu đề `ETag`.

**Lỗi.** HTTP `404`, `422`; mã lỗi của thao tác: ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/scorecards/assets/{assetCode}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"assetCode": "mdm-cong-dan",
 "snapshot": {"snapshotId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
  "scanId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "assetCode": "mdm-cong-dan",
  "scanMode": "FULL", "score": 92.5}, "openFindings": 312,
 "openFindingsBySeverity": {"CRITICAL": 12, "MAJOR": 150, "MINOR": 150}, "openIssues": 2,
 "cde": [{"fieldName": "citizenId", "score": 92.5, "failedRules": 1}],
 "history": [{"snapshotId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
   "scanId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
   "measuredAt": "2026-11-20T08:00:00+07:00", "score": 92.5, "verdict": "PASS"}]}
```

#### API-08-122 · Ảnh chụp KPI đã đẩy sang PH-16

::: dac-ta
**Mục đích.** Ảnh chụp KPI đã đẩy sang PH-16.

**Phương thức, đường dẫn.** `GET /kpi/snapshots`.

**Quyền.** `PERM-08-read hoặc scope `dq.read``.

**FR hiện thực.** FR-08-057.

**Tham số.** `periodCode` (query, string, tùy chọn); `kind` (query, KpiKind, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `KpiSnapshotPage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Chỉ đọc lại bản tin KPI đã phát (EVT-08-14); PH-16 dùng scope `dq.read`.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/kpi/snapshots
```

```http
HTTP/1.1 200 OK

{"items": [{"snapshotId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "kind": "SCAN_SNAPSHOT",
   "kpiSchemaVersion": 1, "publishedAt": "2026-11-20T08:00:00+07:00",
   "periodCode": "2026-11"}], "page": 0, "size": 20, "totalElements": 1}
```

### Báo cáo

#### API-08-107 · Tạo báo cáo

::: dac-ta
**Mục đích.** Tạo báo cáo.

**Phương thức, đường dẫn.** `POST /reports`.

**Quyền.** `PERM-08-report`.

**FR hiện thực.** FR-08-052, FR-08-054.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReportCreate`; trường bắt buộc: `reportType`, `periodCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Report`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-08-056, ERR-08-038, ERR-08-039, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/reports
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"reportType": "PERIODIC", "periodCode": "2026-11",
 "title": "Báo cáo chất lượng dữ liệu tháng 11/2026",
 "scope": {"domainCodes": ["HO_TICH"]}, "annualMethod": "FULL_DECEMBER"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/reports/ma-moi

{"reportCode": "BC-DQ-2026-11-T68", "reportType": "PERIODIC", "periodCode": "2026-11",
 "title": "Báo cáo chất lượng dữ liệu tháng 11/2026", "status": "DRAFT", "version": 3,
 "scope": {"domainCodes": ["HO_TICH"]}}
```

#### API-08-108 · Danh sách báo cáo

::: dac-ta
**Mục đích.** Danh sách báo cáo.

**Phương thức, đường dẫn.** `GET /reports`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-052.

**Tham số.** `reportType` (query, ReportType, tùy chọn); `status` (query, ReportStatus, tùy chọn); `periodCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ReportPage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/reports
```

```http
HTTP/1.1 200 OK

{"items": [{"reportCode": "BC-DQ-2026-11-T68", "reportType": "PERIODIC", "periodCode": "2026-11",
   "title": "Báo cáo chất lượng dữ liệu tháng 11/2026", "status": "DRAFT"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-08-109 · Chi tiết báo cáo

::: dac-ta
**Mục đích.** Chi tiết báo cáo.

**Phương thức, đường dẫn.** `GET /reports/{reportCode}`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-052.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/reports/{reportCode}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "BC-DQ-2026-11-T68", "reportType": "PERIODIC", "periodCode": "2026-11",
 "title": "Báo cáo chất lượng dữ liệu tháng 11/2026", "status": "DRAFT", "version": 3,
 "scope": {"domainCodes": ["HO_TICH"]}}
```

#### API-08-110 · Sửa báo cáo nháp

::: dac-ta
**Mục đích.** Sửa báo cáo nháp.

**Phương thức, đường dẫn.** `PATCH /reports/{reportCode}`.

**Quyền.** `PERM-08-report`.

**FR hiện thực.** FR-08-052.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReportUpdate`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-056 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PATCH /api/dq/v1/reports/{reportCode}

{"title": "Báo cáo chất lượng dữ liệu tháng 11/2026",
 "summary": {"narrative": "Điểm toàn tỉnh tăng 2,4 điểm.",
  "recommendations": ["Bổ sung số định danh cho hồ sơ trước 2015"]},
 "scope": {"domainCodes": ["HO_TICH"]}}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "BC-DQ-2026-11-T68", "reportType": "PERIODIC", "periodCode": "2026-11",
 "title": "Báo cáo chất lượng dữ liệu tháng 11/2026", "status": "DRAFT", "version": 3,
 "scope": {"domainCodes": ["HO_TICH"]}}
```

#### API-08-111 · Gửi duyệt báo cáo

::: dac-ta
**Mục đích.** Gửi duyệt báo cáo.

**Phương thức, đường dẫn.** `POST /reports/{reportCode}:submit`.

**Quyền.** `PERM-08-report`.

**FR hiện thực.** FR-08-053.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-039, ERR-08-040 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/reports/{reportCode}:submit

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "BC-DQ-2026-11-T68", "reportType": "PERIODIC", "periodCode": "2026-11",
 "title": "Báo cáo chất lượng dữ liệu tháng 11/2026", "status": "IN_REVIEW", "version": 3,
 "scope": {"domainCodes": ["HO_TICH"]}}
```

#### API-08-112 · Duyệt và công bố báo cáo

::: dac-ta
**Mục đích.** Duyệt và công bố báo cáo.

**Phương thức, đường dẫn.** `POST /reports/{reportCode}:approve`.

**Quyền.** `PERM-08-approve`.

**FR hiện thực.** FR-08-053.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `CommentBody`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-039, ERR-08-040 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Công bố phát EVT-08-11; người duyệt khác người gửi (ERR-08-005).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/reports/{reportCode}:approve

{"comment": "Đồng ý theo biên bản họp ngày 20/11/2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "BC-DQ-2026-11-T68", "reportType": "PERIODIC", "periodCode": "2026-11",
 "title": "Báo cáo chất lượng dữ liệu tháng 11/2026", "status": "PUBLISHED", "version": 3,
 "scope": {"domainCodes": ["HO_TICH"]}}
```

#### API-08-113 · Từ chối báo cáo

::: dac-ta
**Mục đích.** Từ chối báo cáo.

**Phương thức, đường dẫn.** `POST /reports/{reportCode}:reject`.

**Quyền.** `PERM-08-approve`.

**FR hiện thực.** FR-08-053.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `RejectBody`; trường bắt buộc: `comment`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-039, ERR-08-040 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/reports/{reportCode}:reject

{"comment": "Thiếu căn cứ về ngưỡng, đề nghị bổ sung và gửi lại."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "BC-DQ-2026-11-T68", "reportType": "PERIODIC", "periodCode": "2026-11",
 "title": "Báo cáo chất lượng dữ liệu tháng 11/2026", "status": "DRAFT", "version": 3,
 "scope": {"domainCodes": ["HO_TICH"]}}
```

#### API-08-114 · Thu hồi báo cáo

::: dac-ta
**Mục đích.** Thu hồi báo cáo.

**Phương thức, đường dẫn.** `POST /reports/{reportCode}:withdraw`.

**Quyền.** `PERM-08-approve`.

**FR hiện thực.** FR-08-053.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReasonBody`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-005, ERR-08-007, ERR-08-039, ERR-08-040 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/reports/{reportCode}:withdraw

{"reason": "Nguồn dữ liệu đã ngừng cung cấp theo công văn số 123."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "BC-DQ-2026-11-T68", "reportType": "PERIODIC", "periodCode": "2026-11",
 "title": "Báo cáo chất lượng dữ liệu tháng 11/2026", "status": "WITHDRAWN", "version": 3,
 "scope": {"domainCodes": ["HO_TICH"]}}
```

#### API-08-115 · Kiểm điều kiện báo cáo năm

::: dac-ta
**Mục đích.** Kiểm điều kiện báo cáo năm.

**Phương thức, đường dẫn.** `POST /reports:check-annual-readiness`.

**Quyền.** `PERM-08-report`.

**FR hiện thực.** FR-08-054.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `AnnualReadinessRequest`; trường bắt buộc: `year`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AnnualReadinessResult`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `422`; mã lỗi của thao tác: ERR-08-038, ERR-08-039 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ đọc, không tạo báo cáo; trả danh sách đối tượng chưa đủ điều kiện (ERR-08-038).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/reports:check-annual-readiness

{"year": 2026, "annualMethod": "FULL_DECEMBER"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"year": 2026, "ready": false,
 "blockers": [{"assetCode": "mdm-cong-dan", "reason": "Thiếu lần đo toàn bộ trong kỳ"}]}
```

#### API-08-116 · Xuất báo cáo PDF, XLSX

::: dac-ta
**Mục đích.** Xuất báo cáo PDF, XLSX.

**Phương thức, đường dẫn.** `POST /reports/{reportCode}/exports`.

**Quyền.** `PERM-08-report`.

**FR hiện thực.** FR-08-055.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ReportExportCreate`; trường bắt buộc: `format`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ExportRequest`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-048, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** `202` khi tạo tệp bất đồng bộ; theo dõi ở API-08-117; ký số tách ở API-08-118 (ERR-08-048).
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/reports/{reportCode}/exports
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"format": "PDF"}
```

```http
HTTP/1.1 202 Accepted
ETag: W/"3"

{"exportId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "format": "XLSX", "status": "RUNNING",
 "containsRestricted": false, "version": 3, "kind": "FINDINGS", "assetCode": "mdm-cong-dan"}
```

#### API-08-117 · Tải tệp xuất báo cáo

::: dac-ta
**Mục đích.** Tải tệp xuất báo cáo.

**Phương thức, đường dẫn.** `GET /reports/{reportCode}/exports/{exportId}`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-055.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ExportRequest`; tiêu đề `ETag`.

**Lỗi.** `404` Không tìm thấy.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/reports/{reportCode}/exports/{exportId}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"exportId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "format": "XLSX", "status": "READY",
 "containsRestricted": false, "version": 3, "kind": "FINDINGS", "assetCode": "mdm-cong-dan"}
```

#### API-08-118 · Ký số báo cáo

::: dac-ta
**Mục đích.** Ký số báo cáo.

**Phương thức, đường dẫn.** `POST /reports/{reportCode}:sign`.

**Quyền.** `PERM-08-approve`.

**FR hiện thực.** FR-08-055.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `ReportSignRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Report`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `404`, `409`, `422`; mã lỗi của thao tác: ERR-08-048 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/reports/{reportCode}:sign

{"certificateRef": "chung-thu-co-quan-so-tttt", "comment": "Ký xác nhận báo cáo năm 2026."}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"reportCode": "BC-DQ-2026-11-T68", "reportType": "PERIODIC", "periodCode": "2026-11",
 "title": "Báo cáo chất lượng dữ liệu tháng 11/2026", "status": "DRAFT", "version": 3,
 "scope": {"domainCodes": ["HO_TICH"]}}
```

#### API-08-119 · Danh sách đăng ký nhận báo cáo

::: dac-ta
**Mục đích.** Danh sách đăng ký nhận báo cáo.

**Phương thức, đường dẫn.** `GET /report-subscriptions`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-056.

**Tham số.** `reportType` (query, ReportType, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SubscriptionPage`.

**Lỗi.** HTTP `422`; mã lỗi của thao tác: ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/report-subscriptions
```

```http
HTTP/1.1 200 OK

{"items": [{"subscriptionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "reportType": "PERIODIC",
   "recipientType": "USER", "recipientRef": "tran.van.nam", "format": "PDF"}], "page": 0,
 "size": 20, "totalElements": 1}
```

#### API-08-120 · Đăng ký nhận báo cáo

::: dac-ta
**Mục đích.** Đăng ký nhận báo cáo.

**Phương thức, đường dẫn.** `POST /report-subscriptions`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-056.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SubscriptionCreate`; trường bắt buộc: `reportType`, `recipientType`, `recipientRef`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Subscription`; tiêu đề `ETag`, `Location`.

**Lỗi.** HTTP `400`, `409`; mã lỗi của thao tác: ERR-08-032, ERR-08-055 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/report-subscriptions
Idempotency-Key: 0193b1d4-0000-7000-8000-0000000000a1

{"reportType": "PERIODIC", "recipientType": "USER", "recipientRef": "tran.van.nam",
 "format": "PDF", "domainCode": "HO_TICH"}
```

```http
HTTP/1.1 201 Created
ETag: W/"3"
Location: /api/dq/v1/report-subscriptions/ma-moi

{"subscriptionId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "reportType": "PERIODIC",
 "recipientType": "USER", "recipientRef": "tran.van.nam", "format": "PDF", "enabled": true,
 "version": 3}
```

#### API-08-121 · Hủy đăng ký nhận báo cáo

::: dac-ta
**Mục đích.** Hủy đăng ký nhận báo cáo.

**Phương thức, đường dẫn.** `DELETE /report-subscriptions/{subscriptionId}`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-056.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** HTTP `404`, `409`; mã lỗi của thao tác: ERR-08-032 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
DELETE /api/dq/v1/report-subscriptions/{subscriptionId}
```

```http
HTTP/1.1 204 No Content
```

### Quản trị

#### API-08-123 · Xem tham số chất lượng của tenant

::: dac-ta
**Mục đích.** Xem tham số chất lượng của tenant.

**Phương thức, đường dẫn.** `GET /settings`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-058.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantSettings`; tiêu đề `ETag`.

**Lỗi.** Không.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/settings
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"values": {"08.scan.default-cron": "0 0 2 1 * ?", "08.inline.timeout-ms": 40},
 "version": 5, "ceilings": {"08.inline.timeout-ms": {"min": 10, "max": 50}},
 "updatedAt": "2026-11-20T08:00:00+07:00", "updatedBy": "le.van.tuan"}
```

#### API-08-124 · Sửa tham số chất lượng của tenant

::: dac-ta
**Mục đích.** Sửa tham số chất lượng của tenant.

**Phương thức, đường dẫn.** `PUT /settings`.

**Quyền.** `PERM-08-config`.

**FR hiện thực.** FR-08-058.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `TenantSettingsPut`; trường bắt buộc: `values`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TenantSettings`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `409`, `422`; mã lỗi của thao tác: ERR-08-042 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Giá trị ngoài miền hoặc vượt trần của PA trả ERR-08-042, lưu giữ dưới sàn ERR-08-043.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
PUT /api/dq/v1/settings

{"values": {"08.inline.timeout-ms": 45}}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"values": {"08.scan.default-cron": "0 0 2 1 * ?", "08.inline.timeout-ms": 40},
 "version": 5, "ceilings": {"08.inline.timeout-ms": {"min": 10, "max": 50}},
 "updatedAt": "2026-11-20T08:00:00+07:00", "updatedBy": "le.van.tuan"}
```

#### API-08-125 · Lịch sử chạy dọn dữ liệu

::: dac-ta
**Mục đích.** Lịch sử chạy dọn dữ liệu.

**Phương thức, đường dẫn.** `GET /retention-runs`.

**Quyền.** `PERM-08-config`.

**FR hiện thực.** FR-08-059.

**Tham số.** `status` (query, RetentionRunStatus, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RetentionRunPage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/retention-runs
```

```http
HTTP/1.1 200 OK

{"items": [{"runId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01", "status": "SUCCEEDED",
   "startedAt": "2026-11-20T08:00:00+07:00", "finishedAt": "2026-11-20T08:00:00+07:00",
   "droppedPartitions": 1}], "page": 0, "size": 20, "totalElements": 1}
```

#### API-08-126 · Xem trước dọn dữ liệu

::: dac-ta
**Mục đích.** Xem trước dọn dữ liệu.

**Phương thức, đường dẫn.** `POST /retention-runs:preview`.

**Quyền.** `PERM-08-config`.

**FR hiện thực.** FR-08-059.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `RetentionPreviewRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `RetentionPreview`; tiêu đề `ETag`.

**Lỗi.** HTTP `400`, `422`; mã lỗi của thao tác: ERR-08-043 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
POST /api/dq/v1/retention-runs:preview

{"objectTypes": ["dq_finding"], "asOf": "2026-11-20T08:00:00+07:00"}
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"items": [{"objectType": "dq_finding", "retentionDays": 395, "action": "DROP_PARTITION",
   "partitions": 1, "rowsAffected": 2400000}]}
```

#### API-08-127 · Nhật ký kiểm toán PH-08

::: dac-ta
**Mục đích.** Nhật ký kiểm toán PH-08.

**Phương thức, đường dẫn.** `GET /audit-events`.

**Quyền.** `PERM-08-audit-read`.

**FR hiện thực.** FR-08-060.

**Tham số.** `objectType` (query, string, tùy chọn); `objectCode` (query, string, tùy chọn); `actor` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AuditEventPage`.

**Lỗi.** `422` Không xử lý được.

**Ghi chú.** Không.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/audit-events
```

```http
HTTP/1.1 200 OK

{"items": [{"eventId": "0193b1d4-7c2a-7b10-9f3e-5a6c8d2e4f01",
   "occurredAt": "2026-11-20T08:00:00+07:00", "actor": "nguyen.thi.lan",
   "action": "RULESET_SUBMIT", "objectType": "RULE_SET_VERSION"}], "page": 0, "size": 20,
 "totalElements": 1}
```

#### API-08-128 · So sánh liên tenant ẩn danh

::: dac-ta
**Mục đích.** So sánh liên tenant ẩn danh.

**Phương thức, đường dẫn.** `GET /platform/benchmarks`.

**Quyền.** `PERM-08-read`.

**FR hiện thực.** FR-08-061.

**Tham số.** `periodCode` (query, string, tùy chọn); `domainCode` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `BenchmarkResult`; tiêu đề `ETag`.

**Lỗi.** HTTP `422`; mã lỗi của thao tác: ERR-08-044 (ý nghĩa ở chương mã lỗi).

**Ghi chú.** Chỉ PLATFORM (PA) và TA của tenant bật `08.benchmark.opt-in`; nhóm nhỏ hơn ngưỡng ẩn danh trả ERR-08-044.
:::

**Ví dụ yêu cầu và phản hồi.**

```http
GET /api/dq/v1/platform/benchmarks
```

```http
HTTP/1.1 200 OK
ETag: W/"3"

{"periodCode": "2026-11", "minGroup": 5,
 "items": [{"groupSize": 7, "domainCode": "HO_TICH", "p25": 78.4, "median": 84.0, "p75": 90.2}]}
```
<!-- gen:dac-ta-api:end -->

## Phụ lục A. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Bản 0.2 đã đồng bộ với FRS 0.2 (nhật ký hấp thụ mục 15): mã API-08-129…132, ERR-08-055, ERR-08-056, 43 tham số, enum Phụ lục A, `valueMode`, mã phiếu `DQ-yyyy-nnnnnn` và báo cáo `BC-DQ-yyyy-kỳ-Ttt`. Tập này không sửa tài liệu khác; các điểm còn lại cần chủ tài liệu hấp thụ ở đợt đồng bộ cuối.

| Tài liệu | Đề nghị |
|---|---|
| D02-08 §3.2, §4 | `PERM-08-export` cấp thêm cho DO (○) chỉ để chấp thuận xuất có trường Nhạy cảm (API-08-076); xác nhận cảnh báo (API-08-102, 103) dùng `PERM-08-run` hoặc `PERM-08-rule-admin`; thêm scope máy `dq.ingest` cho PH-05 |
| CSDL D03-03-PH08 | Tên logic khác cột: `isCde` là `cde`; `valueMode` là `value_mode`; `schedule.status` suy từ `enabled`; `degradedCount` là `fail_open_count` cộng `fail_closed_count`; `passThreshold`, `warnThreshold` là `pass_min`, `warn_min`; `content` của báo cáo là `summary`; nhật ký kiểm toán API-08-127 đọc từ kho kiểm toán chung, không có bảng riêng |
| D03-04-PH06 | API nội bộ nhận mục hàng đợi lý do `DQ_FINDING` (API-08-095); khung nhìn hợp đồng `v_dq_{domain}`; gọi API-08-068 làm cổng đầu vào (Q08-08) |
| D03-04-PH05, PH04, PH10 | PH-05: Kamelet `dh-dq-check`, API khám phá lược đồ, đẩy chỉ số vào API-08-024. PH-04: lý do DLQ `DQ_FAIL`, tiêu đề `dh-dq-verdict`. PH-10: đăng ký 14 topic `{tenant}.dq.*` theo FR-10-067 |
| D03-04 khung lỗi chung | Cấp ERR-00-401, ERR-00-403, ERR-00-428 mà PH-08 dẫn |

: Đề nghị đồng bộ với tài liệu khác

Trường chỉ có ở API (kết quả tính, gộp hoặc tham chiếu, không có cột DDL tương ứng): `accuracy`, `completeness`, `consistency`, `timeliness`, `uniqueness`, `validity`, `activeVersionNo`, `activityId`, `added`, `removed`, `annualMethod`, `attributeCount`, `basedOnSnapshotAt`, `basedOnVersionNo`, `blockers`, `breach`, `breaking`, `bySeverity`, `ceilings`, `changedAttributes`, `changedVerdictCount`, `collectedAt`, `columnCount`, `costEstimate`, `count`, `currentVerdict`, `dimensionsPrev`, `projectedScore`, `projectedVerdict`, `deletedRows`, `domainScores`, `downloadUrl`, `droppedPartitions`, `estimatedScore`, `failedRules`, `fieldNames`, `firingAlerts`, `firstScanId`, `forwardedAt`, `fromVersionNo`, `toVersionNo`, `gateEnabled`, `goldenIds`, `mergedIds`, `toGoldenIds`, `survivorId`, `goldenRecord`, `groupSize`, `hasContractView`, `hasPdf`, `hasXlsx`, `itemCount`, `lastScanId`, `lastScore`, `lastVerdict`, `line`, `minGroup`, `namePattern`, `schemaName`, `newFindings`, `newRuleSetCode`, `note`, `objectCode`, `objectTypes`, `objects`, `openFindingsBySeverity`, `openIssueCode`, `openIssues`, `outcome`, `ownScore`, `previousScore`, `publishedVersion`, `rationale`, `referencedFields`, `replacementCatalogCode`, `retireDate`, `resolutionReason`, `rowsAffected`, `scoreAfter`, `scoreBefore`, `seenAt`, `targetAssetCode`, `taskId`, `toLevel`, `trendSeries`, `unconfirmed`, `valid`, `verifyIssueCode`, `versionStatus`. Giá trị enum chỉ có ở API: `BELOW_WARN`, `DENIED`, `ISSUE_DAILY`, `OVERDUE`, `SCAN`, `SCAN_SNAPSHOT`, `SUCCESS`, `TABLE`, `VERDICT_FAIL`, `VIEW`.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 2026-11-26 | Nhóm PH-08 | Bản đầu: 129 operation, 14 sự kiện phát, 8 sự kiện nhận, bảng mã lỗi và thông báo, 5 câu hỏi mở Q08-55…59, phụ lục đề nghị đồng bộ |
| 0.2 | 2026-11-26 | Nhóm PH-08 | Đồng bộ với FRS 0.2: 132 operation (thêm API-08-129 `POST /findings:search` theo FRS, API-08-130, 131 bật, tắt đo tăng dần, API-08-132 `POST /weight-configs:preview` xem trước điểm theo trọng số), ERR-08-056 không có lần đo trong kỳ, ERR-08-101 cho lô quá 100 bản ghi, `etaSeconds` ở lần đo, `facets` ở danh sách phiếu, `dimensionsPrev` ở bảng điều khiển, ERR-08-055 cho `Idempotency-Key` dùng lại với thân khác, enum theo Phụ lục A, `updatedAtField` và cấu hình trực tuyến ở đối tượng đo, `scanTrigger` chỉ `MANUAL`, `ANNUAL`, mã phiếu `DQ-`, mã báo cáo `BC-DQ-`, 43 tham số; chương 11 in ví dụ cho mọi endpoint; giới hạn tập 240 KB |
| 0.3 | 2026-11-27 | Nhóm PH-08 | Đồng bộ chéo cuối: mẫu `type` lỗi RFC 9457 thành `https://datahub.gov.vn/errors/ERR-{PH}-{nnn}`; EVT-08-14 có `snapshotId` |
