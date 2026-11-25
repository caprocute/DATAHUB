---
ma_tai_lieu: D03-04-PH04
ten: Đặc tả API và sự kiện phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kiến trúc sư, lập trình viên L-INT và frontend console, kiểm thử viên, vận hành
phan_he: PH-04
nguoi_lap: Nhóm phân hệ PH-04
---

# D03-04-PH04 · Đặc tả API và sự kiện phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng

## Tóm tắt cho hội đồng thẩm định

PH-04 có hai loại giao diện lập trình, phục vụ hai đối tượng khác nhau:

1. **API điều khiển** của `dh-integration` (module `flow`). Chỉ giao diện Datahub gọi API này, cho người thiết kế, người duyệt và người vận hành luồng. Nó bao gồm không gian làm việc, luồng, phiên bản, kiểm tra hợp lệ, chạy thử, duyệt bốn mắt, triển khai GitOps, lệnh tạm dừng và dừng khẩn, catalog thành phần, khuôn mẫu.
2. **Sự kiện Kafka** báo các mốc vòng đời luồng cho phân hệ khác (PH-02, PH-13, PH-18). Ngoài ra có ba topic hệ thống giữa control plane và runtime: lệnh có ký, nhịp tim, xác nhận lệnh.

HTTT thành viên **không** gọi API điều khiển. Chúng gọi chính các luồng đã phát hành qua APISIX. Hợp đồng của từng luồng đối ngoại được công bố ở PH-02. Lỗi do runtime trả cho bên gọi luồng (ERR-04-101…112) được chuẩn hóa ở §6.2.

So với Bus cũ, API mới bỏ hẳn các điểm yếu sau:

- Không còn thao tác Start/Stop qua JMX-Jolokia. Thay bằng lệnh có ký, hạn 60 giây, xác nhận theo từng bản sao.
- Không còn sửa XML trực tiếp trên máy chủ chạy. Mọi thay đổi đi qua phiên bản bất biến, chạy thử đạt, duyệt bốn mắt, rồi mới vào Git.
- Mọi thao tác có lý do, có kiểm toán và có mã lỗi tiếng Việt.

Tài liệu này là văn xuôi giải thích hai tệp hợp đồng. Khi văn xuôi và tệp hợp đồng khác nhau, **tệp hợp đồng là nguồn sự thật**:

| Tệp | Nội dung | Quy mô |
|---|---|---|
| [`ph04/openapi-integration.yaml`](ph04/openapi-integration.yaml) | API REST điều khiển (OpenAPI 3.1) | 70 operation, 51 mã API-04, 105 lược đồ |
| [`ph04/asyncapi-integration.yaml`](ph04/asyncapi-integration.yaml) | Sự kiện Kafka (AsyncAPI 3.0) | 14 kênh EVT-04-01…14 |
| [`ph04/tools/`](ph04/tools/) | `gen_openapi.py`, `gen_asyncapi.py` sinh hai tệp trên; `gen_md.py` sinh bảng §3 | — |

Hai tệp YAML do script sinh ra, không sửa tay. Mọi tên miền, máy chủ, định danh và dữ liệu trong hợp đồng là giả lập. Tenant ví dụ là `T68` (giả lập), topic dùng chữ thường `t68`.

Căn cứ: FRS [D02-03-PH04](../../02-yeu-cau/frs/D02-03-PH04-frs-tich-hop.md) §8, SDD [D03-02-PH04](../sdd/D03-02-PH04-sdd-tich-hop.md) §3, §10, §12, CSDL [D03-03-PH04](../csdl/D03-03-PH04-csdl-tich-hop.md), màn hình [D03-06-PH04](../uiux/D03-06-PH04-man-hinh-tich-hop.md) §2.4, §5.3.

## 1. Quy ước chung

Các quy ước dưới đây áp dụng cho mọi endpoint của PH-04, kế thừa SAD §7.2 và mẫu D03-04-PH07 §1. Mỗi quy ước có chỗ thể hiện trong hợp đồng để lập trình viên tra.

| Chủ đề | Quy ước | Trong hợp đồng |
|---|---|---|
| Đường dẫn gốc | `/api/integration/v1` (GAP-04-13). Không có API nền tảng riêng; chính sách thành phần nền đi cùng API, phân biệt bằng quyền | `servers` |
| Người gọi | Chỉ console qua BFF (token Authorization Code + PKCE). APISIX nội bộ `apisix-int` chặn client máy gọi tới đường dẫn này | `security` |
| Phiên bản API | Số chính trong đường dẫn. Trong `v1` chỉ thêm trường tùy chọn và endpoint mới; thay đổi phá vỡ sang `v2`, chạy song song ≥ 6 tháng | `info.version` |
| Tenant | Lấy từ token, không lấy từ tham số. Đối tượng của tenant khác, hoặc của không gian làm việc người gọi không có quyền xem, trả 404 như không tồn tại | Mô tả từng endpoint |
| Định danh trong đường dẫn | Dùng mã nghiệp vụ `flowCode` và số `versionNo`, không dùng UUID, để URL đọc được và khớp kho Git `flows/{flowCode}/`. Tài nguyên con (lần chạy, triển khai, lệnh) dùng UUID v7 | `FlowCodePath`, `VersionNoPath` |
| Đặt tên | Danh từ số nhiều, chữ thường, gạch nối. Hành động đổi trạng thái dùng hậu tố `:{hành-động}` (`:submit`, `:review`, `:retire`, `:rollback`) | `paths` |
| Phân trang | Con trỏ mờ `cursor`, `limit` ≤ 100 (vượt trả ERR-04-026), trả `page.next`, `page.hasMore`. Danh sách nhỏ có giới hạn tự nhiên (phiên bản, triển khai, ca kiểm thử) trả trọn | `CursorMeta` |
| Chống trùng | `Idempotency-Key` 16…128 ký tự trên mọi lệnh tạo và lệnh có tác dụng ngoài (chạy thử, phát hành, lệnh runtime). Lưu 24 giờ ở Valkey, so băm SHA-256 thân yêu cầu; khác nội dung trả ERR-04-018 | `IdempotencyKey`, `x-datahub-idempotent` |
| Khóa lạc quan | `ETag` dạng `W/"{version}-{contentHash[0..8]}"` (SDD §6.4). Lệnh sửa và đổi trạng thái bắt buộc `If-Match`; thiếu trả ERR-04-007 (428), lệch trả ERR-04-006 (412) kèm `currentEtag`, `savedBy`, `savedAt` để giao diện mở hộp xung đột ba bên | `IfMatch`, `ETag` |
| Hành động được phép | Luồng, phiên bản, triển khai, lần chạy thử trả `allowedActions` và `disabledReasons` (D03-06-PH04 §2.4). Giao diện không tự suy luận quyền và trạng thái | `AllowedActions` |
| Xử lý nền | Thao tác có tác dụng ngoài chưa xong ngay (chạy thử, phát hành, quay lui, nâng môi trường, gỡ luồng, lệnh runtime, chuyển XML cũ) trả `202 Accepted` kèm `Location` | `Location` |
| Tiến trình thời gian thực | SSE (`text/event-stream`) cho một lần chạy thử và một lần triển khai, có nhịp `heartbeat` 15 giây. Mất kết nối thì hỏi lại mỗi 2 giây. Không dùng WebSocket | `streamTestRun`, `streamDeployment` |
| Lỗi | RFC 9457 `application/problem+json`, có `code` (ERR-04-nnn), `traceId`, `errors[]` theo trường, `findings[]` theo quy tắc kiểm tra. `title`, `detail` tiếng Việt và không bao giờ lặp giá trị bí mật | `ProblemDetails`, `Finding` |
| Truy vết | `traceparent` (W3C Trace Context) truyền xuyên suốt tới Git commit message, outbox và lệnh runtime | `Traceparent` |
| Ngôn ngữ | `Accept-Language: vi` (mặc định) hoặc `en` | `AcceptLanguage` |
| Kích thước | Định nghĩa luồng ≤ 512 KiB (ERR-04-033); bản tin mẫu, thân chạy thử ≤ 256 KiB (ERR-04-021); tài liệu mẫu cho trình ánh xạ ≤ 1 MiB; tệp XML cũ ≤ 2 MiB | `maxLength` |
| Kiểu dữ liệu | Theo D00-01 §5: UUID v7, thời điểm ISO 8601 có múi giờ, mã tenant `^T[0-9]{2}$`, băm `sha256:{64 hex}` | `TenantId`, `ContentHash` |

## 2. Xác thực và phân quyền

Người dùng đăng nhập bằng Authorization Code + PKCE tại realm Keycloak `dh-{tenant}` (ví dụ `dh-t68`). BFF của console giữ token và gọi `dh-integration` qua `apisix-int`. APISIX kiểm tra chữ ký, hạn và giới hạn tần suất. `dh-integration` kiểm tra lại tenant, quyền `PERM-04-*` và mức truy cập không gian làm việc. Lớp kiểm tra thứ hai này giữ an toàn kể cả khi cấu hình gateway sai.

Quyền chức năng theo FRS §3.2 và D02-08:

| Quyền | Dùng cho | Vai trò mặc định |
|---|---|---|
| `PERM-04-read` | Mọi API đọc; tạo đề xuất thành phần | PA, PO, TA, TO, SO, IE, IA, VW, AU |
| `PERM-04-create` | Tạo, nhân bản luồng; chuyển XML cũ; kiểm tra YAML chưa lưu | IE |
| `PERM-04-update` | Lưu nháp, nhập YAML, biểu thức, ánh xạ, chạy thử, ca kiểm thử, phiên soạn | IE |
| `PERM-04-submit` | Gửi duyệt, rút lại | IE |
| `PERM-04-publish` | Duyệt, yêu cầu sửa, phát hành, quay lui, hàng đợi duyệt | IA |
| `PERM-04-promote` | Nâng phiên bản lên môi trường kế tiếp | IA, TA |
| `PERM-04-operate` | Tạm dừng, tiếp tục luồng và route; gửi lại lệnh | TA, TO, SO, IA |
| `PERM-04-emergency-stop` | Lệnh `EMERGENCY_STOP` | SO, TA |
| `PERM-04-delete` | Gỡ luồng | IE (bản nháp của mình), TA; luồng đã phát hành cần thêm `PERM-04-publish` |
| `PERM-04-admin` | Không gian làm việc, thành viên, khuôn của tỉnh, biến môi trường, thu hẹp chính sách thành phần cho tỉnh | TA, PA |
| `PERM-04-catalog-admin` | Chính sách thành phần nền, quyết định đề xuất | PA (SO duyệt) |
| `PERM-04-sample-data` | Bỏ qua cảnh báo dữ liệu cá nhân thật trong bản tin mẫu (cờ trong thân yêu cầu, không phải endpoint riêng) | IE được TA cấp theo luồng |

Mức không gian làm việc (`VIEW`, `EDIT`, `MAINTAIN`, FR-04-007) ghi ở `x-datahub-permission.workspaceLevel`. Chỉ áp dụng khi tham số `04.workspace.enforce` bật; TA và PA không bị giới hạn. Người duyệt cần mức `MAINTAIN` khi tham số bật.

Hai kiểm tra đặc biệt:

- **Bốn mắt (BR-04-005).** `:review` từ chối người đã tạo phiên bản, người trong `flow_version_contributor` và người gửi duyệt (ERR-04-015, 403). Kiểm tra ở máy chủ, giao diện chỉ ẩn nút.
- **Xác thực lại khi duyệt.** Khi `04.review.require-reauth` bật thì `:review` cần token có `auth_time` trong 5 phút; phát hành và nâng lên PROD luôn cần, bất kể tham số (FRS §7.1). Nếu không, máy chủ trả 401 kèm `WWW-Authenticate: Bearer error="insufficient_user_authentication", max_age=300` (RFC 9470), giao diện mở cửa sổ đăng nhập lại.

## 3. Danh mục endpoint

Bảng dưới đây sinh từ `ph04/tools/gen_openapi.py` (cùng nguồn với hợp đồng) bằng `gen_md.py`. Cột "FR" ghi số FR-04 được hiện thực, bỏ tiền tố. Mọi operation đều có thể trả 401 (ERR-04-044); mọi lệnh ghi có thể trả 403 (ERR-04-045). Hai mã này không nhắc lại trong bảng.

<!-- gen:endpoints:start -->
**Không gian làm việc**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-001 | `GET /workspaces` | Danh sách không gian làm việc | 007 | `PERM-04-read` |  | 200 |
| API-04-002 | `POST /workspaces` | Tạo không gian làm việc | 007 | `PERM-04-admin` | có | 201 |
| API-04-002 | `PATCH /workspaces/{workspaceCode}` | Sửa không gian làm việc | 007 | `PERM-04-admin` (MAINTAIN) |  | 200 |
| API-04-003 | `POST /workspaces/{workspaceCode}:archive` | Lưu trữ không gian làm việc | 007 | `PERM-04-admin` |  | 200 |
| API-04-004 | `GET /workspaces/{workspaceCode}/members` | Danh sách thành viên | 007 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-004 | `PUT /workspaces/{workspaceCode}/members` | Thay danh sách thành viên | 007 | `PERM-04-admin` (MAINTAIN) |  | 200 |

**Luồng**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-010 | `GET /flows` | Danh sách luồng | 001 | `PERM-04-read` |  | 200 |
| API-04-011 | `POST /flows` | Tạo luồng và phiên bản 1 | 003, 025 | `PERM-04-create` (EDIT) | có | 201 |
| API-04-012 | `GET /flows/{flowCode}` | Chi tiết luồng | 002 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-013 | `PATCH /flows/{flowCode}` | Sửa thông tin luồng | 004 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-014 | `POST /flows/{flowCode}:clone` | Nhân bản luồng | 005 | `PERM-04-create` (EDIT) | có | 201 |
| API-04-015 | `POST /flows/{flowCode}:retire` | Gỡ luồng | 006 | `PERM-04-delete` |  | 202 |
| API-04-016 | `GET /flows/{flowCode}/dependencies` | Phụ thuộc của luồng | 006, 002 | `PERM-04-read` (VIEW) |  | 200 |

**Phiên bản**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-024 | `GET /flows/{flowCode}/versions` | Danh sách phiên bản | 011 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-021 | `POST /flows/{flowCode}/versions` | Tạo phiên bản mới từ phiên bản có sẵn | 011 | `PERM-04-update` (EDIT) | có | 201 |
| API-04-020 | `GET /flows/{flowCode}/versions/{versionNo}` | Lấy phiên bản (định nghĩa, bố cục, bản tin mẫu) | 010 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-022 | `PUT /flows/{flowCode}/versions/{versionNo}/draft` | Lưu nháp | 024, 010, 022 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-023 | `POST /flows/{flowCode}/versions/{versionNo}:discard` | Hủy bản nháp | 006 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-025 | `GET /flows/{flowCode}/versions/{versionNo}/diff` | So sánh với phiên bản khác | 043 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-026 | `GET /flows/{flowCode}/versions/{versionNo}/download` | Tải định nghĩa | 027 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-027 | `POST /flows/{flowCode}/versions/{versionNo}:import-yaml` | Nhập YAML thay định nghĩa | 027 | `PERM-04-update` (EDIT) |  | 200 |

**Di trú**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-028 | `POST /legacy-imports` | Chuyển Camel XML của Bus cũ | 082 | `PERM-04-create` (EDIT) | có | 202 |
| API-04-028 | `GET /legacy-imports/{jobId}` | Kết quả chuyển đổi | 082 | `PERM-04-read` |  | 200 |

**Phiên bản**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-034 | `PUT /flows/{flowCode}/versions/{versionNo}/session` | Nhịp phiên soạn | 024 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-034 | `DELETE /flows/{flowCode}/versions/{versionNo}/session` | Kết thúc phiên soạn | 024 | `PERM-04-update` |  | 204 |

**Kiểm tra hợp lệ**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-030 | `POST /flows/{flowCode}/versions/{versionNo}:validate` | Kiểm tra hợp lệ phiên bản | 023 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-031 | `POST /validation:check` | Kiểm tra YAML chưa lưu | 023, 003 | `PERM-04-create` |  | 200 |
| API-04-032 | `POST /expressions:check` | Biên dịch, xem trước biểu thức | 015 | `PERM-04-update` |  | 200 |
| API-04-033 | `POST /mappings:preview` | Xem trước ánh xạ (JQ) trên bản tin mẫu | 020 | `PERM-04-update` |  | 200 |

**Chạy thử**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-040 | `POST /flows/{flowCode}/versions/{versionNo}/test-runs` | Bắt đầu chạy thử | 030, 032 | `PERM-04-update` (EDIT) | có | 202 |
| API-04-041 | `GET /flows/{flowCode}/test-runs` | Lịch sử chạy thử | 030 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-042 | `GET /flows/{flowCode}/test-runs/{runId}` | Kết quả lần chạy thử | 030 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-042 | `GET /flows/{flowCode}/test-runs/{runId}/events` | Luồng sự kiện lần chạy thử (SSE) | 030 | `PERM-04-read` (VIEW) |  | 200 SSE |
| API-04-042 | `GET /flows/{flowCode}/test-runs/{runId}/steps/{seqNo}/body` | Thân bản tin đầy đủ của một chặng | 030 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-043 | `POST /flows/{flowCode}/test-runs/{runId}:cancel` | Hủy lần chạy thử | 030 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-044 | `GET /flows/{flowCode}/test-cases` | Danh sách ca kiểm thử | 031 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-044 | `POST /flows/{flowCode}/test-cases` | Tạo ca kiểm thử | 031 | `PERM-04-update` (EDIT) | có | 201 |
| API-04-044 | `PUT /flows/{flowCode}/test-cases/{caseId}` | Sửa ca kiểm thử | 031 | `PERM-04-update` (EDIT) |  | 200 |
| API-04-044 | `DELETE /flows/{flowCode}/test-cases/{caseId}` | Xóa (ngừng dùng) ca kiểm thử | 031 | `PERM-04-update` (EDIT) |  | 204 |

**Duyệt**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-050 | `POST /flows/{flowCode}/versions/{versionNo}:submit` | Gửi duyệt | 040 | `PERM-04-submit` (EDIT) |  | 200 |
| API-04-051 | `POST /flows/{flowCode}/versions/{versionNo}:withdraw` | Rút lại yêu cầu duyệt | 040 | `PERM-04-submit` (EDIT) |  | 200 |
| API-04-052 | `POST /flows/{flowCode}/versions/{versionNo}:review` | Quyết định duyệt | 041, 043 | `PERM-04-publish` (VIEW) |  | 200 |
| API-04-053 | `GET /reviews` | Hàng đợi duyệt | 041 | `PERM-04-publish` |  | 200 |

**Triển khai**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-054 | `GET /flows/{flowCode}/deployments` | Lịch sử triển khai | 042 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-054 | `POST /flows/{flowCode}/deployments` | Phát hành phiên bản lên môi trường | 042, 075 | `PERM-04-publish` (VIEW) | có | 202 |
| API-04-054 | `GET /flows/{flowCode}/deployments/{deploymentId}` | Chi tiết triển khai | 042 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-054 | `GET /flows/{flowCode}/deployments/{deploymentId}/events` | Tiến trình triển khai (SSE) | 042 | `PERM-04-read` (VIEW) |  | 200 SSE |
| API-04-055 | `POST /flows/{flowCode}/deployments:rollback` | Quay lui về phiên bản đã duyệt trước | 044 | `PERM-04-publish` | có | 202 |
| API-04-056 | `POST /flows/{flowCode}/deployments:promote` | Nâng phiên bản lên môi trường kế tiếp | 045 | `PERM-04-promote` | có | 202 |

**Vận hành**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-060 | `GET /flows/{flowCode}/runtime` | Tình trạng runtime theo môi trường | 051 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-061 | `POST /flows/{flowCode}/runtime/commands` | Tạm dừng, tiếp tục, dừng khẩn | 050 | `PERM-04-operate` | có | 202 |
| API-04-061 | `GET /flows/{flowCode}/runtime/commands/{commandId}` | Trạng thái lệnh | 050 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-061 | `POST /flows/{flowCode}/runtime/commands/{commandId}:resend` | Gửi lại lệnh chưa đủ xác nhận | 050 | `PERM-04-operate` |  | 202 |
| API-04-062 | `GET /flows/{flowCode}/endpoints` | Điểm kết nối và số liệu | 052 | `PERM-04-read` (VIEW) |  | 200 |
| API-04-063 | `GET /flows/{flowCode}/metrics` | Số liệu theo luồng (từ PH-13) | 053 | `PERM-04-read` (VIEW) |  | 200 |

**Danh mục thành phần**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-070 | `GET /catalog` | Chỉ mục catalog đã lọc chính sách | 012, 080 | `PERM-04-read` |  | 200 |
| API-04-071 | `GET /catalog/{kind}/{name}` | Lược đồ thuộc tính của thành phần | 014, 080 | `PERM-04-read` |  | 200 |
| API-04-072 | `GET /catalog/policies` | Chính sách thành phần (nền + tỉnh) | 080 | `PERM-04-read` |  | 200 |
| API-04-072 | `PATCH /catalog/policies` | Sửa chính sách thành phần | 080 | `PERM-04-catalog-admin` |  | 200 |
| API-04-073 | `GET /catalog/versions` | Phiên bản catalog và hồ sơ runtime | 081, 075 | `PERM-04-read` |  | 200 |
| API-04-074 | `GET /catalog/proposals` | Đề xuất thành phần | 080 | `PERM-04-read` |  | 200 |
| API-04-074 | `POST /catalog/proposals` | Đề xuất cho phép hoặc bổ sung thành phần | 080 | `PERM-04-read` | có | 201 |
| API-04-074 | `POST /catalog/proposals/{proposalId}:decide` | Quyết định đề xuất | 080 | `PERM-04-catalog-admin` |  | 200 |

**Khuôn mẫu**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-080 | `GET /templates` | Danh sách khuôn mẫu | 025 | `PERM-04-read` |  | 200 |
| API-04-081 | `GET /templates/{templateCode}` | Chi tiết khuôn và lược đồ tham số | 025 | `PERM-04-read` |  | 200 |
| API-04-082 | `POST /templates` | Tạo khuôn của tỉnh từ phiên bản đã duyệt | 025 | `PERM-04-admin` | có | 201 |
| API-04-082 | `POST /templates/{templateCode}:deprecate` | Ngừng dùng khuôn của tỉnh | 025 | `PERM-04-admin` |  | 200 |

**Tham số**

| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |
|---|---|---|---|---|---|---|
| API-04-090 | `GET /settings` | Tham số 04.*, khoảng đóng băng, biến môi trường | 084 | `PERM-04-read` |  | 200 |
| API-04-090 | `PUT /settings/env-vars` | Thay biến môi trường {{dh.env.*}} | 084 | `PERM-04-admin` |  | 200 |
| API-04-091 | `GET /flows/{flowCode}/history` | Lịch sử thao tác của luồng (từ PH-13) | 083 | `PERM-04-read` (VIEW) |  | 200 |
<!-- gen:endpoints:end -->

Ghi chú cho lập trình viên:

1. **Lưu nháp (API-04-022)** là endpoint gọi nhiều nhất. Giao diện tự lưu sau 2 giây ngừng gõ (D03-06-PH04 §10.16). Máy chủ ghi `definitionYaml`, `canvasLayout`, `samples`, `mappings` trong một giao dịch, tính lại `contentHash` trên YAML chuẩn hóa (SDD §6.2), dựng lại chỉ mục route và endpoint, chạy kiểm tra mức `DESIGN`. Kết quả kiểm tra trả kèm và không chặn lưu, trừ hai trường hợp: cú pháp YAML (ERR-04-008) và giá trị giống bí mật (ERR-04-010). Bí mật không bao giờ được ghi xuống, kể cả ở bản nháp.
2. **Bản tin mẫu và bố cục** (`samples`, `canvasLayout`) lưu cột riêng và không vào YAML triển khai (BR-04-007). `contentHash` chỉ tính trên YAML, nên kéo chặng trên canvas không làm mất kết quả chạy thử đạt.
3. **Gửi duyệt (API-04-050)** kiểm tra theo thứ tự rẻ đến đắt và trả lỗi đầu tiên gặp:
   - trạng thái (ERR-04-005);
   - ghi chú thay đổi (ERR-04-025);
   - catalog hiện hành (ERR-04-042);
   - kiểm tra mức `SUBMIT` (ERR-04-009, kèm `findings`);
   - lần chạy thử không mô phỏng đạt trên đúng `contentHash` và mọi ca kiểm thử đang dùng đều đạt (ERR-04-014, BR-04-004).
4. **Phát hành (API-04-054)** ghi bản ghi `deployment` và outbox trong giao dịch, rồi `GitOpsWriter` commit vào `env/{environment}` của kho `dh-flows-{tenant}` (với PROD là merge request, ADR-068). Lỗi Git đưa triển khai sang `FAILED` với ERR-04-022, không cuộn lại phiên bản. Trạng thái `SYNCED` đến khi mọi bản sao báo đúng `contentHash` qua nhịp tim EVT-04-12.
5. **Lệnh runtime (API-04-061)** trả 202 ngay khi đã ký và gửi. Giao diện theo dõi `GET .../commands/{id}`: `ACKNOWLEDGED` khi đủ bản sao, `PARTIAL` sau 30 giây, `REJECTED` khi có bản sao từ chối (ERR-04-024 nằm trong `acks[].reason`, không phải mã HTTP). `EMERGENCY_STOP` đi trước Git; tiến trình đối soát đưa trạng thái mong muốn vào Git trong 5 phút (ADR-065, BR-04-018).
6. **Catalog (API-04-070)** trả chỉ mục đã lọc theo chính sách nền và chính sách tỉnh, kèm nhóm bảng thành phần. ETag ghép `catalogVersion`, `policyVersion`, `paletteRulesVersion`; trình duyệt giữ bản đệm và gửi `If-None-Match`.
7. **Đọc lịch sử, số liệu** (API-04-063, 091) chỉ là lớp chuyển tiếp tới PH-13, lọc sẵn theo tenant và luồng. PH-13 không sẵn sàng thì trả 503 ERR-04-047; các màn hình khác vẫn dùng được.

## 4. Danh mục sự kiện

Hợp đồng ở `ph04/asyncapi-integration.yaml`. Có ba nhóm sự kiện:

- **EVT-04-01…10** ghi vào `ph04.outbox` trong cùng giao dịch với thay đổi, Debezium đưa lên Kafka. Theo CloudEvents 1.0 chế độ nhị phân (tiêu đề `ce_*`). Khóa bản tin `{tenant}:{flowId}` giữ thứ tự theo luồng.
- **EVT-04-11…13** là topic hệ thống `dh.*`. ACL chỉ cho `dh-integration` và `dh-runtime` (theo CN chứng thư mTLS). EVT-04-11 không qua outbox: `dh-integration` ghi `runtime_command` rồi gửi trực tiếp, vì độ trễ lệnh khẩn phải dưới 5 giây (NFR-04-010).
- **EVT-04-14** do chặng `audit` của runtime phát. Chủ quản topic là PH-13.

Sự kiện không mang định nghĩa luồng, bản tin mẫu hay thân bản tin nghiệp vụ.

| Mã | Topic | Bên phát → bên nhận chính | Khóa | Giữ |
|---|---|---|---|---|
| EVT-04-01 | `{tenant}.integration.flow.created.v1` | dh-integration → PH-13, PH-18 | `{tenant}:{flowId}` | 7 ngày |
| EVT-04-02 | `{tenant}.integration.flow.updated.v1` | dh-integration → PH-02 (đồng bộ nhãn, chủ quản) | 〃 | 7 ngày |
| EVT-04-03 | `{tenant}.integration.version.submitted.v1` | dh-integration → PH-18 (thông báo người duyệt) | 〃 | 7 ngày |
| EVT-04-04 | `{tenant}.integration.version.approved.v1` | dh-integration → PH-18, PH-02 | 〃 | 7 ngày |
| EVT-04-05 | `{tenant}.integration.version.changes-requested.v1` | dh-integration → PH-18 (thông báo người soạn) | 〃 | 7 ngày |
| EVT-04-06 | `{tenant}.integration.deployment.requested.v1` | dh-integration → PH-13 | 〃 | 7 ngày |
| EVT-04-07 | `{tenant}.integration.deployment.status-changed.v1` | dh-integration → PH-02 (bật, tắt API công bố), PH-13, PH-18 | 〃 | 7 ngày |
| EVT-04-08 | `{tenant}.integration.flow.runtime-state-changed.v1` | dh-integration → PH-02, PH-13 | 〃 | 7 ngày |
| EVT-04-09 | `{tenant}.integration.flow.retired.v1` | dh-integration → PH-02, PH-10 (thu hồi nhóm tiêu thụ) | 〃 | 7 ngày |
| EVT-04-10 | `{tenant}.integration.testrun.completed.v1` | dh-integration → PH-18 (thông báo người chạy khi rời trang) | 〃 | 7 ngày |
| EVT-04-11 | `dh.integration.runtime.command.v1` | dh-integration → dh-runtime | `{tenant}:{environment}` | 1 ngày |
| EVT-04-12 | `dh.integration.runtime.heartbeat.v1` | dh-runtime → dh-integration | `{replica}` | 1 ngày |
| EVT-04-13 | `dh.integration.runtime.command-ack.v1` | dh-runtime → dh-integration | `{commandId}` | 1 ngày |
| EVT-04-14 | `{tenant}.audit.connection-log.v1` | dh-runtime → PH-13 | `{tenant}:{flowCode}` | 30 ngày trên Kafka; PH-13 giữ online 12 tháng, WORM 5 năm |

Lệnh EVT-04-11 có chữ ký Ed25519 qua OpenBao transit, ký trên JCS (RFC 8785) của mọi trường trừ `signature`. Runtime từ chối lệnh trong năm trường hợp: chữ ký sai, quá `expiresAt` (60 giây), `tenantId` khác tenant của namespace, luồng hoặc route không có, `commandId` đã xử lý. Mỗi lần từ chối có xác nhận `REJECTED` với lý do tương ứng (SDD §10).

Tham số PH-04 đổi (FR-04-084) dùng sự kiện tham số chung của PH-18, không tạo EVT-04-15 (SDD §5.6).

Chính sách tương thích giống PH-07: trong `v1` chỉ thêm trường tùy chọn; lược đồ đăng ký ở Apicurio, chế độ BACKWARD; CI chặn thay đổi không tương thích.

## 5. Hợp đồng với phân hệ khác và bên ngoài

`dh-integration` gọi đồng bộ các phân hệ sau. Mọi lệnh gọi qua mesh mTLS với token dịch vụ, client sinh từ hợp đồng của phân hệ chủ quản.

| Bên được gọi | Thao tác | PH-04 dùng ở | Thời gian chờ, thử lại | Khi lỗi |
|---|---|---|---|---|
| PH-05 Kết nối | Kiểm tra mã kết nối tồn tại, loại, đã cấp cho không gian, có giá trị cho môi trường | VR-07 khi lưu, gửi duyệt, phát hành | 2 giây; 1 lần | Kiểm tra trả cảnh báo "chưa xác minh" ở `DESIGN`; chặn ở `SUBMIT` với ERR-04-047 |
| PH-02 API | Lấy OpenAPI của API công bố khi tạo luồng `OPENAPI`; liệt kê API dùng luồng (phụ thuộc cứng) | API-04-011, 016 | 5 giây; 2 lần | ERR-04-047 (503) |
| PH-10 Hub | Kiểm tra topic đã đăng ký (BR-04-009) | VR-08 | 2 giây; 1 lần | Như PH-05 |
| PH-01 HTTT | Bản sao đọc HTTT đã kết nạp (EN-04-22), qua sự kiện, không gọi đồng bộ | VR-10, ERR-04-043 | — | Dùng bản sao gần nhất |
| PH-13 Giám sát | Số liệu theo luồng, lịch sử kiểm toán | API-04-063, 091 | 5 giây; không thử lại | ERR-04-047 |
| PH-18 Tham số | Đọc `04.*`, khoảng đóng băng | Mọi lệnh ghi | Bản đệm 60 giây | Dùng bản đệm; hết bản đệm thì giá trị mặc định an toàn (đóng băng = không) |
| Git (GitHub khi phát triển, GitLab on-prem khi bàn giao, Q353) | Commit `env/test`, `env/staging`; merge request `env/prod` | API-04-054, 055, 056, 015 | 15 giây; 3 lần giãn cách lũy thừa | ERR-04-022 (502), triển khai `FAILED` |
| OpenBao transit | Ký lệnh | API-04-061 | 1 giây; 2 lần | ERR-04-047; lệnh không được gửi |
| Sandbox `dh-runtime-sandbox` | Chạy thử, biên dịch biểu thức, chạy JQ ánh xạ (Valkey Stream `dh:int:testrun:queue`) | API-04-032, 033, 040 | Theo `timeoutSeconds`, ≤ 120 giây | ERR-04-019 (503), hoặc ERR-04-020 khi quá giờ |

Trong giai đoạn chạy song song với Bus cũ (D06-01), PH-04 không gọi Bus. Chuyển luồng cũ dùng tệp XML do người vận hành xuất từ Bus và tải lên (API-04-028).

## 6. Bảng mã lỗi ERR-04

Đây là bảng chính thức mà FRS §8.1 dẫn tới. Câu hiển thị trên giao diện cho từng mã ở D03-06-PH04 §5.3. Mã không có câu riêng thì hiển thị `title`. Mỗi mã có một nghĩa duy nhất. Một tình huống có thể trả mã HTTP khác tùy ngữ cảnh: ERR-04-019 là 429 khi hết hạn mức và 503 khi sandbox không sẵn sàng.

### 6.1. Lỗi API điều khiển (ERR-04-001…049)

| Mã | HTTP | Nghĩa | Trả ở |
|---|---|---|---|
| ERR-04-001 | 404 | Không tìm thấy luồng, hoặc không có quyền xem (không phân biệt hai trường hợp) | Mọi `/flows/{flowCode}…` |
| ERR-04-002 | 409 | Mã luồng đã dùng trong tenant, kể cả mã của luồng gỡ chưa quá 30 ngày (BR-04-001) | API-04-011, 014 |
| ERR-04-003 | 403 | Không có mức `EDIT` (hoặc `MAINTAIN` khi duyệt) trên không gian làm việc | Lệnh ghi theo luồng |
| ERR-04-004 | 404 | Không tìm thấy phiên bản | `/versions/{versionNo}…` |
| ERR-04-005 | 409 | Trạng thái hiện tại không cho phép thao tác (gồm duyệt khi chưa xem so sánh, gỡ khi đang có lần chạy thử) | Lệnh đổi trạng thái |
| ERR-04-006 | 412 | ETag không khớp; kèm `currentEtag`, `savedBy`, `savedAt` | Lệnh có `If-Match` |
| ERR-04-007 | 428 | Thiếu `If-Match` | Lệnh có `If-Match` |
| ERR-04-008 | 422 | YAML không phân tích được; `errors[]` có dòng, cột | API-04-011, 022, 027, 031 |
| ERR-04-009 | 422 | Định nghĩa còn lỗi kiểm tra ở mức yêu cầu, hoặc loại tài nguyên không khớp nội dung; kèm `findings[]` | API-04-011, 040, 050, 054, 055, 056 |
| ERR-04-010 | 422 | Phát hiện giá trị giống bí mật (BR-04-003); `findings[]` chỉ có đường dẫn và loại, không lặp giá trị | API-04-022, 027, 090 |
| ERR-04-011 | 422 | Thành phần, EIP, dataformat, ngôn ngữ hoặc lớp bean không được phép (BR-04-014) | Kiểm tra `SUBMIT`, `PUBLISH` |
| ERR-04-012 | 422 | Luồng đối ngoại thiếu chặng chuẩn (BR-04-002); `findings[].args.stages` | Kiểm tra `SUBMIT` |
| ERR-04-013 | 422 | Kết nối không tồn tại, sai loại, chưa cấp cho không gian, thiếu giá trị cho môi trường, hoặc không phải loại chỉ đọc cho chặng SQL | Kiểm tra; API-04-040 `SANDBOX_LIVE` |
| ERR-04-014 | 409 | Chưa có lần chạy thử không mô phỏng đạt trên đúng `contentHash`, hoặc còn ca kiểm thử chưa đạt (BR-04-004) | API-04-050 |
| ERR-04-015 | 403 | Người duyệt là người tạo, người đóng góp hoặc người gửi (BR-04-005) | API-04-052 |
| ERR-04-016 | 409 | Luồng đã có phiên bản mở (BR-04-016); kèm `versionNo`, người tạo | API-04-021 |
| ERR-04-017 | 409 | Còn phụ thuộc cứng; kèm `dependencies[]` | API-04-015; xóa không gian còn luồng |
| ERR-04-018 | 409 | `Idempotency-Key` đã dùng với nội dung khác | Lệnh có chống trùng |
| ERR-04-019 | 429 / 503 | Hết hạn mức chạy thử đồng thời của tenant (429, kèm `retryAfterSeconds`), hoặc sandbox không sẵn sàng (503) | API-04-032, 033, 040 |
| ERR-04-020 | — | Lần chạy thử quá thời gian; không phải mã HTTP mà là `errorCode` của `TestRun` ở trạng thái `TIMED_OUT`, kèm `hungNodeId` | API-04-042 |
| ERR-04-021 | 413 | Bản tin mẫu, thân chạy thử hoặc tài liệu mẫu ánh xạ vượt giới hạn | API-04-022, 033, 040, 044 |
| ERR-04-022 | 502 | Không ghi được kho cấu hình Git; triển khai `FAILED` | API-04-015, 054, 055, 056 |
| ERR-04-023 | 409 | Sai thứ tự môi trường, môi trường trước chưa `SYNCED`/`HEALTHY`/đủ thời gian ổn định (BR-04-019), hoặc luồng chưa triển khai ở môi trường của lệnh | API-04-054, 056, 061 |
| ERR-04-024 | — | Runtime từ chối hoặc không xác nhận lệnh; là trạng thái `REJECTED`, `PARTIAL` của `Command`, không phải mã HTTP | API-04-061 |
| ERR-04-025 | 400 | Thiếu hoặc quá ngắn: lý do, ghi chú thay đổi, ý kiến duyệt, mục checklist bắt buộc (BR-04-017) | API-04-015, 050, 051, 052, 055, 061 |
| ERR-04-026 | 400 | `limit` vượt 100 | Danh sách có phân trang |
| ERR-04-027 | 404 | Không tìm thấy không gian làm việc | API-04-002…004, 011, 013 |
| ERR-04-028 | 409 | Mã không gian làm việc đã dùng | API-04-002 |
| ERR-04-029 | 422 | Không hồ sơ runtime nào có đủ thành phần luồng dùng, hoặc hồ sơ JVM không được phép cho tenant | Kiểm tra `PUBLISH`; API-04-054 |
| ERR-04-030 | 404 | Không tìm thấy lần chạy thử, ca kiểm thử, triển khai, lệnh, đề xuất hoặc tác vụ chuyển đổi | Tài nguyên con |
| ERR-04-031 | 422 | Câu SQL vi phạm chính sách Q359 (không phải `SELECT` một câu, dùng hàm bị cấm, thiếu tham số hóa) | Kiểm tra mọi mức |
| ERR-04-032 | 422 | Tệp không phải Camel XML hợp lệ của Bus cũ | API-04-028 |
| ERR-04-033 | 413 | Định nghĩa luồng vượt 512 KiB | API-04-011, 022, 027, 031 |
| ERR-04-034 | 409 | Luồng đã gỡ, chỉ đọc | Lệnh ghi theo luồng |
| ERR-04-035 | 404 | Thành phần không có trong catalog của phiên bản yêu cầu | API-04-071 |
| ERR-04-036 | 409 | Tên Kamelet trùng Kamelet nền hoặc Kamelet khác trong tenant | API-04-011, 022 với `resourceKind = KAMELET` |
| ERR-04-037 | 422 | Biểu thức không biên dịch được (chế độ chặt); chế độ thường trả 200 `valid = false` | API-04-032; kiểm tra `SUBMIT` |
| ERR-04-038 | 422 | Ánh xạ tới trường đích không tồn tại, vòng tham chiếu, hàm không hỗ trợ | API-04-033; kiểm tra `SUBMIT` |
| ERR-04-039 | 404 | Khuôn mẫu không tồn tại hoặc không được phép | API-04-011, 081 |
| ERR-04-040 | 409 | Phiên bản đích của quay lui dùng thành phần nay bị cấm | API-04-055 |
| ERR-04-041 | 423 | Đang trong khoảng đóng băng thay đổi (BR-04-022); chỉ quay lui và tạm dừng khẩn được phép | API-04-054, 056; API-04-022 khi tỉnh đóng băng cả việc soạn |
| ERR-04-042 | 409 | Phiên bản soạn trên catalog cũ hơn catalog hiện hành của tenant; cần mở lại để nâng | API-04-050, 054 |
| ERR-04-043 | 422 | HTTT nguồn hoặc đích chưa kết nạp ở PH-01 (luồng đối ngoại) | Kiểm tra `SUBMIT` |
| ERR-04-044 | 401 | Thiếu token, token hết hạn, hoặc cần xác thực lại | Mọi API |
| ERR-04-045 | 403 | Thiếu quyền chức năng `PERM-04-*` | Mọi API |
| ERR-04-046 | 415 | Kiểu nội dung không hỗ trợ | Lệnh có thân |
| ERR-04-047 | 503 | Phân hệ phụ thuộc chưa sẵn sàng (PH-05, PH-02, PH-13, OpenBao) | Xem §5 |
| ERR-04-048 | 429 | Vượt giới hạn tần suất của người dùng | Mọi API |
| ERR-04-049 | 400 | Tham số truy vấn hoặc thân yêu cầu sai lược đồ | Mọi API |

### 6.2. Lỗi runtime trả cho bên gọi luồng (ERR-04-101…112)

`dh-runtime` trả các lỗi này cho HTTT gọi luồng đồng bộ, theo RFC 9457, qua APISIX. Với luồng bất đồng bộ, mã lỗi ghi vào tiêu đề `dh-error-code` của bản tin DLQ (BR-04-008). Cả hai trường hợp đều ghi vào nhật ký kết nối EVT-04-14. Thân lỗi không chứa dữ liệu nghiệp vụ, chi tiết hệ đích hay stack trace. Dải ERR-04-113…120 để dành.

| Mã | HTTP | Nghĩa | Chặng | DLQ (bất đồng bộ) |
|---|---|---|---|---|
| ERR-04-101 | 400 | Bản tin sai lược đồ; ≤ 20 lỗi theo đường dẫn trường, không lặp giá trị | `schema` (hoặc `receive` khi không giải tuần tự được) | Ngay |
| ERR-04-102 | 403 | OPA từ chối, hoặc không trả lời trong 200 ms | `authz` | Không (bỏ, ghi nhật ký) |
| ERR-04-103 | 504 | Hệ đích quá thời gian chờ | `deliver` | Sau khi hết lượt thử lại |
| ERR-04-104 | 502 | Hệ đích trả lỗi sau khi hết lượt thử lại | `deliver` | Sau khi hết lượt thử lại |
| ERR-04-105 | 503 | Mạch ngắt đang mở với hệ đích, hoặc luồng không có nhánh dự phòng | `deliver` | Giữ để thử lại theo lịch |
| ERR-04-106 | 409 | Trùng `Idempotency-Key` khi kết quả cũ không còn | `receive` | Không (bỏ trùng) |
| ERR-04-107 | 413 | Thân vượt giới hạn của luồng | `receive` | Ngay |
| ERR-04-108 | 422 | Lỗi chuyển đổi, mã không có trong bảng (cấu hình `FAIL`), SQL quá thời gian hoặc vượt số dòng | `transform`, `enrich` | Ngay |
| ERR-04-109 | 500 | Lỗi nội bộ của luồng không thuộc nhóm trên | Bất kỳ | Ngay |
| ERR-04-110 | 503 | Luồng hoặc route đang tạm dừng | `receive` | Không nhận (consumer dừng) |
| ERR-04-111 | 404 | Đường dẫn không khớp route nào của luồng | `receive` | — |
| ERR-04-112 | 500 | Tiêu đề tenant khác tenant của runtime (`TenantGuard`); cảnh báo an ninh mức cao ở PH-13 | `receive` | Không (bỏ, cảnh báo) |

## 7. Kiểm tra hợp đồng trong CI

Hai tệp hợp đồng được kiểm tra ở cổng CI-5 của D04-02:

- Lint OpenAPI và AsyncAPI bằng Spectral với bộ luật dự án.
- Mọi `$ref` phải phân giải được; mọi ví dụ phải khớp lược đồ.
- Mỗi operation phải có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`.
- Lệnh ghi phải có `If-Match` hoặc `Idempotency-Key`.
- `oasdiff` so với nhánh `main`, chặn thay đổi phá vỡ trong `v1`.
- Lược đồ sự kiện được kiểm tra tương thích ngược ở Apicurio.

Kiểm thử contract phía máy chủ (sinh từ hợp đồng) chạy ở CI-3 trên `dh-integration` với Testcontainers. Client TypeScript của console sinh từ OpenAPI (`openapi-typescript`) ở CI-6. Thêm hai kiểm tra riêng của PH-04:

- Mọi mã `ERR-04-nnn` xuất hiện trong mã nguồn phải có trong §6 và trong bảng câu hiển thị D03-06-PH04 §5.3, nếu không phải mã chỉ dùng `title`.
- Danh sách `allowedActions` mà máy chủ trả phải nằm trong tập hành động giao diện biết.

Tại thời điểm viết, `openapi-integration.yaml` đã qua `openapi-spec-validator` (OpenAPI 3.1), `asyncapi-integration.yaml` đã qua `@asyncapi/parser` 3 không lỗi. Lint Spectral sẽ chạy khi bộ luật dự án được đưa vào repo.

## 8. Ánh xạ từ hệ cũ và mã đang chạy

| Hệ cũ hoặc mã W2 | API mới | Ghi chú |
|---|---|---|
| Bus: danh sách chương trình, tìm theo endpoint, nguồn, tên, host (LGC-BUS-001…005) | API-04-010 | `endpoint` dùng chỉ mục EN-04-04b; host thay bằng `environment` |
| Bus: Start/Stop agent, route qua JMX-Jolokia (LGC-BUS-009, 012) | API-04-061 | Lệnh có ký, xác nhận theo bản sao, có lý do |
| Bus: xóa chương trình (LGC-BUS-010) | API-04-015 | Kiểm tra phụ thuộc, rút theo môi trường qua Git |
| Tooling: lưu XML kéo thả, sinh mã | API-04-022, 027 | YAML DSL; bố cục tách khỏi định nghĩa |
| Tooling: nhập, xuất tệp | API-04-026, 027, 028 | XML cũ qua bộ chuyển đổi, có báo cáo |
| W2 `apps/control` `RoutesController` `/api/routes…` | `/api/integration/v1/flows…` | Đường dẫn cũ giữ một bản phát hành, trả `Deprecation` và `Link` tới đường dẫn mới, sau đó gỡ (SDD §2.5) |
| W2 chạy thử giả lập | API-04-040 `MOCK`, `SANDBOX_LIVE` | Lần chạy cũ chuyển thành `SIMULATED`, không tính cho BR-04-004 |

## 9. Câu hỏi mở

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q04-55 | Tên miền chính thức cho `type` của ProblemDetails (`https://datahub.gov.vn/problems/integration/…` là giả định, cùng kiểu Q07-100) | Chốt cùng D03-09 |
| Q04-56 | Đường dẫn W2 `/api/routes` cần giữ bao lâu, có client nào ngoài console cũ gọi không | Giữ một bản phát hành; kiểm tra log APISIX trước khi gỡ |
| Q04-57 | SSE qua BFF và APISIX có bị cắt ở 60 giây do thời gian chờ mặc định không | Đặt `proxy_read_timeout` 300 giây cho hai đường dẫn SSE; nhịp `heartbeat` 15 giây |
| Q04-58 | Có cần API công khai cho đội HTTT xem trạng thái luồng mình dùng (chỉ đọc) không, hay để PH-02 cung cấp | Để PH-02 cung cấp qua trạng thái API công bố, PH-04 không mở thêm |
| Q04-59 | Giữ topic hệ thống 1 ngày có đủ cho phân tích sự cố lệnh khẩn | Đủ vì `runtime_command`, `command_ack` lưu ở CSDL; PH-13 giữ log |

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung |
|---|---|---|
| 0.1 | 2026-11-25 | Bản đầu: 70 operation, 14 sự kiện, bảng ERR-04 đầy đủ, ánh xạ hệ cũ và W2 |
