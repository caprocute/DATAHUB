---
ma_tai_lieu: D03-04-PH07
ten: Đặc tả API và sự kiện phân hệ PH-07 Danh mục dùng chung
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kiến trúc sư, lập trình viên L-DATA, đội phát triển HTTT thành viên, kiểm thử viên
phan_he: PH-07
nguoi_lap: Nhóm phân hệ PH-07
---

# D03-04-PH07 · Đặc tả API và sự kiện phân hệ PH-07 Danh mục dùng chung

## Tóm tắt cho hội đồng thẩm định

PH-07 cung cấp danh mục dùng chung cho các hệ thống thông tin (HTTT) của tỉnh qua hai kênh: API REST để tra cứu, quản trị và sự kiện trên Kafka để thông báo thay đổi. Toàn bộ hợp đồng được viết bằng ngôn ngữ máy đọc được theo chuẩn quốc tế (OpenAPI 3.1 cho API, AsyncAPI 3.0 cho sự kiện, RFC 9457 cho định dạng lỗi) và được kiểm tra tự động trong quy trình tích hợp liên tục, nên mã nguồn không thể lệch khỏi tài liệu mà không bị phát hiện.

So với hệ cũ Aita, API mới: không cho gửi câu SQL tự do (thay bằng truy vấn có cấu trúc có giới hạn); tra được mã tại một ngày bất kỳ; có tra lô, lấy phần thay đổi và cây; có quyền khai thác riêng cho danh mục hạn chế; mọi lỗi có mã và thông điệp tiếng Việt. Xác thực theo OAuth 2.1 (Client Credentials cho máy, Authorization Code + PKCE cho người dùng) qua Keycloak và cổng APISIX.

Tài liệu này là văn xuôi giải thích hai tệp hợp đồng. Khi văn xuôi và tệp hợp đồng khác nhau, **tệp hợp đồng là nguồn sự thật**:

| Tệp | Nội dung | Quy mô |
|---|---|---|
| [`ph07/openapi-rdm.yaml`](ph07/openapi-rdm.yaml) | API REST | 76 endpoint, 132 lược đồ, 127 ví dụ |
| [`ph07/asyncapi-rdm.yaml`](ph07/asyncapi-rdm.yaml) | Sự kiện Kafka | 10 sự kiện EVT-07-01…10 |

Mọi tên miền, máy chủ, định danh và dữ liệu trong hợp đồng là giả lập.

## 1. Quy ước chung

Các quy ước dưới đây áp dụng cho mọi endpoint của PH-07 và kế thừa SAD §7.2. Mỗi quy ước có phần thể hiện trong hợp đồng để lập trình viên tra.

| Chủ đề | Quy ước | Trong hợp đồng |
|---|---|---|
| Đường dẫn gốc | `/api/rdm/v1` cho API tenant; `/api/platform/rdm/v1` cho API nền tảng (chỉ PH-20, không mở ra cổng công khai) | `servers` |
| Phiên bản API | Số phiên bản chính nằm trong đường dẫn; trong `v1` chỉ thêm trường tùy chọn và endpoint mới; thay đổi phá vỡ sang `v2` và chạy song song tối thiểu 6 tháng | `info.version` |
| Tenant | Lấy từ token, không bao giờ từ tham số; đối tượng của tenant khác trả 404 | Mô tả từng endpoint |
| Đặt tên | Danh từ số nhiều, chữ thường gạch nối; hành động đổi trạng thái dùng hậu tố `:{hành-động}` (`:publish`, `:approve`, `:retire`) | `paths` |
| Phân trang quản trị | `page` (từ 0), `size` ≤ 200, trả `page.totalElements` | `PageMeta` |
| Phân trang khai thác | Con trỏ mờ `cursor`, `limit` ≤ 1.000, trả `cursor.next`, `hasMore` | `CursorMeta` |
| Thời điểm tra | `at` (ngày, giờ Việt Nam) hoặc `version`; hai tham số loại trừ nhau | `At`, `VersionNoQuery` |
| Chống trùng | `Idempotency-Key` 16…128 ký tự trên lệnh tạo, lưu 24 giờ, so băm SHA-256 thân yêu cầu; khác nội dung trả ERR-07-022 | `IdempotencyKey` |
| Khóa lạc quan | `ETag` sinh từ cột `version`; lệnh sửa và đổi trạng thái bắt buộc `If-Match`; thiếu trả ERR-07-040, lệch trả ERR-07-018 | `IfMatch`, `ETag` |
| Bộ đệm phía client | Phiên bản đã phát hành bất biến nên API khai thác trả `ETag`, `Cache-Control: max-age`, hỗ trợ `If-None-Match` → 304 | `IfNoneMatch`, `NotModified` |
| Xử lý nền | Thao tác dài trả `202 Accepted` kèm `Location` tới tác vụ; client có thể gửi `Prefer: respond-async` | `Prefer`, `Location` |
| Lỗi | RFC 9457 `application/problem+json`, có `code` (ERR-07-nnn), `traceId`, `errors[]` theo trường hoặc dòng; `title`, `detail` tiếng Việt | `ProblemDetails` |
| Truy vết | `traceparent` (W3C Trace Context) truyền xuyên suốt; `traceId` trong lỗi lấy từ đây | `Traceparent` |
| Ngôn ngữ | `Accept-Language: vi` (mặc định) hoặc `en` | `AcceptLanguage` |
| Kiểu dữ liệu | Theo D00-01 §5: UUID v7, ngày `yyyy-MM-dd`, thời điểm ISO 8601 có múi giờ, mã T-CODE chữ hoa | `TId`, `TDate`, `TTs`, `TCode` |

## 2. Xác thực và phân quyền

API có hai kiểu chủ thể. HTTT thành viên lấy token bằng OAuth 2.1 Client Credentials tại realm Keycloak của tenant, với scope sinh từ đăng ký sử dụng đã duyệt ở PH-02: `rdm.read` (tra cứu), `rdm.query` (truy vấn có cấu trúc), `rdm.write` (ghi lô vào bản nháp). Theo D03-07, client máy dùng `private_key_jwt` hoặc mTLS thay cho bí mật dùng chung. Người dùng đăng nhập bằng Authorization Code + PKCE; quyền chi tiết `PERM-07-*` lấy từ vai trò và được OPA đánh giá theo D02-08, kể cả phạm vi tổ chức theo `catalog.ownerOrgId`.

APISIX kiểm tra chữ ký token, scope và giới hạn tần suất trước khi chuyển tới `dh-data`. `dh-data` kiểm tra lại tenant, quyền `PERM-07-*` và quyền khai thác danh mục `RESTRICTED` (BR-07-019, FR-07-052); lớp kiểm tra thứ hai này bảo đảm an toàn kể cả khi cấu hình gateway sai. Mỗi endpoint ghi quyền yêu cầu trong mở rộng `x-datahub-permission`.

## 3. Danh mục endpoint

Bảng dưới đây liệt kê toàn bộ endpoint, sinh từ `openapi-rdm.yaml`. Cột "FR" ghi số FR-07 được hiện thực; cột "Ví dụ" là số ví dụ yêu cầu và phản hồi thành công có trong hợp đồng (ví dụ lỗi dùng chung ở `components/responses`). Mọi ví dụ đã được kiểm tra tự động khớp lược đồ.

| API | Phương thức | Đường dẫn | Chức năng | FR | Quyền | Ví dụ (yêu cầu/phản hồi) |
|---|---|---|---|---|---|---|
| API-07-001 | GET | `/catalogs` | Danh sách danh mục | 001, 033 | PERM-07-read | 0/1 |
| API-07-002 | POST | `/catalogs` | Tạo danh mục kèm bản nháp phiên bản 1 | 003, 005, 007, 008 | PERM-07-create | 2/1 |
| API-07-003 | GET | `/catalogs/{catalogCode}` | Chi tiết danh mục | 002 | PERM-07-read | 0/1 |
| API-07-004 | PATCH | `/catalogs/{catalogCode}` | Cập nhật thông tin danh mục | 004, 008 | PERM-07-update | 2/1 |
| API-07-005 | DELETE | `/catalogs/{catalogCode}` | Xóa danh mục chưa phát hành | 009 | PERM-07-update | 0/0 |
| API-07-006 | POST | `/catalogs/{catalogCode}:retire` | Ngừng hiệu lực danh mục | 009 | PERM-07-retire | 0/1 |
| API-07-007 | GET | `/catalog-groups` | Cây nhóm danh mục | 010 | PERM-07-read | 0/1 |
| API-07-008 | POST | `/catalog-groups` | Tạo nhóm danh mục | 010 | PERM-07-configure | 0/1 |
| API-07-009 | PATCH | `/catalog-groups/{groupId}` | Sửa nhóm danh mục | 010 | PERM-07-configure | 1/1 |
| API-07-010 | DELETE | `/catalog-groups/{groupId}` | Xóa nhóm rỗng | 010 | PERM-07-configure | 0/0 |
| API-07-011 | GET | `/catalogs/{catalogCode}/versions` | Danh sách phiên bản | 002 | PERM-07-read | 0/1 |
| API-07-012 | POST | `/catalogs/{catalogCode}/versions` | Tạo bản nháp từ phiên bản hiện hành | 011 | PERM-07-create | 1/2 |
| API-07-013 | GET | `/catalogs/{catalogCode}/versions/{versionRef}` | Chi tiết phiên bản | 002 | PERM-07-read | 0/1 |
| API-07-014 | PATCH | `/catalogs/{catalogCode}/versions/{versionRef}` | Sửa ngày hiệu lực, căn cứ, ghi chú của bản nháp | 016 | PERM-07-update | 1/1 |
| API-07-015 | DELETE | `/catalogs/{catalogCode}/versions/{versionRef}` | Hủy bản nháp | 017 | PERM-07-update | 0/0 |
| API-07-016 | POST | `/catalogs/{catalogCode}/versions/{versionRef}:validate` | Kiểm tra hợp lệ toàn bản nháp | 013 | PERM-07-update | 0/1 |
| API-07-017 | POST | `/catalogs/{catalogCode}/versions/{versionRef}:submit` | Trình duyệt phiên bản | 015 | PERM-07-submit | 0/1 |
| API-07-018 | POST | `/catalogs/{catalogCode}/versions/{versionRef}:approve` | Duyệt phiên bản | 015 | PERM-07-publish | 0/1 |
| API-07-019 | POST | `/catalogs/{catalogCode}/versions/{versionRef}:reject` | Từ chối phiên bản | 015 | PERM-07-publish | 0/1 |
| API-07-020 | POST | `/catalogs/{catalogCode}/versions/{versionRef}:publish` | Phát hành phiên bản | 016 | PERM-07-publish | 1/1 |
| API-07-021 | GET | `/catalogs/{catalogCode}/versions/{versionRef}/diff` | So sánh hai phiên bản | 014 | PERM-07-read | 0/1 |
| API-07-022 | GET | `/catalogs/{catalogCode}/versions/{versionRef}/attributes` | Danh sách thuộc tính của phiên bản | 005 | PERM-07-read | 0/1 |
| API-07-023 | POST | `/catalogs/{catalogCode}/versions/{versionRef}/attributes` | Thêm thuộc tính vào bản nháp | 005 | PERM-07-update | 2/1 |
| API-07-024 | PATCH | `/catalogs/{catalogCode}/versions/{versionRef}/attributes/{attrCode}` | Sửa thuộc tính trên bản nháp | 006 | PERM-07-update | 1/1 |
| API-07-025 | DELETE | `/catalogs/{catalogCode}/versions/{versionRef}/attributes/{attrCode}` | Xóa thuộc tính khỏi bản nháp | 006 | PERM-07-update | 0/0 |
| API-07-026 | GET | `/catalogs/{catalogCode}/versions/{versionRef}/items` | Bản ghi của một phiên bản (quản trị) | 002, 018 | PERM-07-read | 0/1 |
| API-07-027 | POST | `/catalogs/{catalogCode}/versions/{versionRef}/items` | Thêm bản ghi vào bản nháp | 012 | PERM-07-update | 1/1 |
| API-07-028 | PATCH | `/catalogs/{catalogCode}/versions/{versionRef}/items/{itemCode}` | Sửa bản ghi trên bản nháp | 012 | PERM-07-update | 1/1 |
| API-07-029 | POST | `/catalogs/{catalogCode}/versions/{versionRef}/items/{itemCode}:deprecate` | Ngừng dùng bản ghi, ghi mã thay thế | 012, 019 | PERM-07-update | 0/1 |
| API-07-030 | DELETE | `/catalogs/{catalogCode}/versions/{versionRef}/items/{itemCode}` | Xóa bản ghi mới thêm trong bản nháp | 012 | PERM-07-update | 0/0 |
| API-07-031 | POST | `/catalogs/{catalogCode}/versions/{versionRef}/items:batch` | Nhập lô bản ghi vào bản nháp (≤ 5.000 thao tác) | 023 | PERM-07-update | 1/1 |
| API-07-032 | GET | `/catalogs/{catalogCode}/import-template` | Tải tệp mẫu nhập theo lược đồ | 020 | PERM-07-read | 0/1 |
| API-07-033 | POST | `/import-jobs` | Tải tệp và tạo tác vụ nhập (pha 1) | 021, 022 | PERM-07-update | 0/1 |
| API-07-034 | GET | `/import-jobs/{jobId}` | Trạng thái, tóm tắt và xem trước tác vụ nhập | 021 | PERM-07-update | 0/1 |
| API-07-035 | GET | `/import-jobs/{jobId}/rows` | Dòng xem trước hoặc báo cáo lỗi | 021, 025 | PERM-07-update | 0/1 |
| API-07-036 | POST | `/import-jobs/{jobId}:commit` | Ghi kết quả nhập vào bản nháp (pha 2) | 021, 022 | PERM-07-update | 0/2 |
| API-07-037 | POST | `/import-jobs/{jobId}:cancel` | Hủy tác vụ nhập | 021 | PERM-07-update | 0/1 |
| API-07-038 | POST | `/export-jobs` | Xuất phiên bản danh mục | 024 | PERM-07-export | 1/3 |
| API-07-039 | GET | `/export-jobs/{jobId}` | Trạng thái tác vụ xuất và URL tải | 024 | PERM-07-export | 0/1 |
| API-07-040 | GET | `/jobs` | Lịch sử tác vụ nhập xuất | 025 | PERM-07-read | 0/1 |
| API-07-041 | GET | `/catalogs/{catalogCode}/items` | Lấy toàn bộ bản ghi hiệu lực (con trỏ) | 028 | PERM-07-read | 0/1 |
| API-07-042 | GET | `/catalogs/{catalogCode}/items/{itemCode}` | Tra một mã tại thời điểm | 026 | PERM-07-read | 0/2 |
| API-07-043 | POST | `/catalogs/{catalogCode}/items:lookup` | Tra lô tối đa 500 mã | 027 | PERM-07-read | 1/1 |
| API-07-044 | GET | `/catalogs/{catalogCode}/tree` | Lấy cây hoặc nhánh con | 029 | PERM-07-read | 0/1 |
| API-07-045 | GET | `/catalogs/{catalogCode}/items:search` | Tìm kiếm không dấu trong danh mục | 030 | PERM-07-read | 0/1 |
| API-07-046 | GET | `/catalogs/{catalogCode}/changes` | Lấy thay đổi kể từ một phiên bản (delta) | 031 | PERM-07-read | 0/1 |
| API-07-047 | POST | `/catalogs/{catalogCode}/items:query` | Truy vấn có cấu trúc bằng DSL JSON | 032 | PERM-07-read | 2/1 |
| API-07-048 | GET | `/catalogs/{catalogCode}/schema` | Lược đồ danh mục và JSON Schema | 033 | PERM-07-read | 0/1 |
| API-07-049 | GET | `/catalogs/{catalogCode}/snapshots/{versionRef}` | Tải ảnh chụp phiên bản (chuyển hướng tới URL ký sẵn) | 028 | PERM-07-read | 0/0 |
| API-07-050 | GET | `/catalogs/{catalogCode}/items/{itemCode}/lineage` | Dòng lịch sử của một bản ghi | 047 | PERM-07-read | 0/1 |
| API-07-051 | POST | `/admin-units:convert` | Chuyển mã ĐVHC cũ sang mới (lô ≤ 1.000) | 046 | PERM-07-read | 1/1 |
| API-07-052 | GET | `/catalogs/{catalogCode}/versions/{versionRef}/successions` | Sự kiện sắp xếp ghi nhận trong phiên bản | 045 | PERM-07-read | 0/1 |
| API-07-053 | POST | `/catalogs/{catalogCode}/versions/{versionRef}/successions` | Ghi sự kiện sắp xếp vào bản nháp | 045 | PERM-07-update | 1/1 |
| API-07-054 | DELETE | `/catalogs/{catalogCode}/versions/{versionRef}/successions/{successionId}` | Xóa sự kiện sắp xếp trong bản nháp | 045 | PERM-07-update | 0/0 |
| API-07-055 | GET | `/sync-sources` | Danh sách nguồn đồng bộ | 035 | PERM-07-read | 0/1 |
| API-07-056 | POST | `/sync-sources` | Tạo nguồn đồng bộ (đăng ký đồng bộ danh mục quốc gia) | 035, 038 | PERM-07-sync | 1/1 |
| API-07-057 | PATCH | `/sync-sources/{sourceId}` | Sửa nguồn đồng bộ | 035 | PERM-07-sync | 1/1 |
| API-07-058 | POST | `/sync-sources/{sourceId}:run` | Chạy đồng bộ ngay | 036 | PERM-07-sync | 0/1 |
| API-07-059 | GET | `/sync-runs` | Lịch sử lần chạy đồng bộ | 036 | PERM-07-read | 0/1 |
| API-07-060 | GET | `/sync-runs/{runId}` | Chi tiết lần chạy và danh sách thay đổi | 036, 037 | PERM-07-read | 0/1 |
| API-07-061 | POST | `/sync-runs/{runId}:accept` | Xác nhận áp dụng thay đổi phá vỡ | 037 | PERM-07-sync | 1/1 |
| API-07-062 | POST | `/sync-runs/{runId}:reject` | Từ chối thay đổi từ nguồn quốc gia | 037 | PERM-07-sync | 0/1 |
| API-07-063 | GET | `/national-catalogs` | Khám phá danh mục quốc gia trên NDXP | 038 | PERM-07-sync | 0/1 |
| API-07-064 | GET | `/code-systems` | Danh sách hệ thống mã ngoài | 040 | PERM-07-read | 0/1 |
| API-07-065 | POST | `/code-systems` | Tạo hệ thống mã ngoài | 040 | PERM-07-mapping | 0/1 |
| API-07-066 | PATCH | `/code-systems/{csCode}` | Sửa hệ thống mã ngoài | 040 | PERM-07-mapping | 1/1 |
| API-07-067 | GET | `/catalogs/{catalogCode}/mappings` | Bảng ánh xạ mã của danh mục | 041 | PERM-07-read | 0/1 |
| API-07-068 | PUT | `/catalogs/{catalogCode}/mappings/{csCode}` | Ghi lô ánh xạ (upsert) | 041 | PERM-07-mapping | 1/1 |
| API-07-069 | DELETE | `/catalogs/{catalogCode}/mappings/{csCode}/{mappingId}` | Xóa ánh xạ | 041 | PERM-07-mapping | 0/0 |
| API-07-070 | POST | `/mappings:translate` | Chuyển mã qua bảng ánh xạ (lô ≤ 500) | 042 | PERM-07-read | 1/1 |
| API-07-071 | GET | `/catalogs/{catalogCode}/mappings/{csCode}/coverage` | Độ phủ ánh xạ | 043 | PERM-07-read | 0/1 |
| API-07-072 | GET | `/catalogs/{catalogCode}/history` | Lịch sử kiểm toán của danh mục | 050 | PERM-07-read | 0/1 |
| API-07-073 | POST | `/tenants/{tenantId}:seed` | Nạp gói danh mục nền cho tenant mới | 049 | PLATFORM | 1/1 |
| API-07-074 | POST | `/catalogs/{catalogCode}/proposals` | Đề xuất bổ sung bản ghi lên danh mục quốc gia | 039 | PERM-07-sync | 1/1 |
| API-07-075 | GET | `/catalogs/{catalogCode}/access-grants` | Danh sách HTTT được cấp quyền khai thác | 052 | PERM-07-read | 0/1 |
| API-07-075 | PUT | `/catalogs/{catalogCode}/access-grants` | Thay toàn bộ danh sách cấp quyền khai thác | 052 | PERM-07-grant | 1/1 |

Ba endpoint trả tệp nhị phân (khuôn nhập xlsx của API-07-032, báo cáo lỗi xlsx của API-07-035, tệp xlsx của API-07-038) không có ví dụ thân trong hợp đồng; mẫu tệp nằm ở D03-06-PH07 và ở bộ dữ liệu kiểm thử D05-02-PH07 §2.

Endpoint API-07-076 (tham số PH-07) được bỏ; tham số `07.rdm.*` đọc, ghi qua API tham số chung của PH-18 (FR-07-053).

## 4. Danh mục sự kiện

Sự kiện được ghi vào bảng outbox trong cùng giao dịch với thay đổi (DD-11), Debezium đọc WAL và đưa lên Kafka trong ≤ 5 giây (NFR-07-007). Bản tin theo CloudEvents 1.0 chế độ nhị phân: thuộc tính `ce_*` ở tiêu đề Kafka, thân JSON là `data`. Khóa bản tin là `{tenant}:{catalogCode}` để giữ thứ tự theo danh mục; consumer chống trùng bằng `ce_id`. Sự kiện chỉ mang siêu dữ liệu và `snapshotUri`, không mang dữ liệu bản ghi, để HTTT lấy dữ liệu qua API có kiểm soát quyền. HTTT đăng ký nhận qua PH-10.

| Sự kiện | Topic | Phát khi | Trường `data` bắt buộc |
|---|---|---|---|
| EVT-07-01 | `{tenant}.rdm.catalog.created.v1` | FR-07-003, FR-07-022, FR-07-038 | `catalogCode`, `name`, `sourceType`, `classification` |
| EVT-07-02 | `{tenant}.rdm.catalog.updated.v1` | FR-07-004, FR-07-008 | `catalogCode`, `changedFields` |
| EVT-07-03 | `{tenant}.rdm.catalog.retired.v1` | FR-07-009 | `catalogCode`, `retireDate`, `reason` |
| EVT-07-04 | `{tenant}.rdm.catalog.submitted.v1` | FR-07-015 | `catalogCode`, `versionNo`, `submittedBy`, `diffSummary` |
| EVT-07-05 | `{tenant}.rdm.catalog.published.v1` | FR-07-016, FR-07-037, FR-07-049 | `catalogCode`, `versionNo`, `effectiveFrom`, `breaking`, `schemaHash` |
| EVT-07-06 | `{tenant}.rdm.catalog.rejected.v1` | FR-07-015 | `catalogCode`, `versionNo`, `action`, `rejectedBy` |
| EVT-07-07 | `{tenant}.rdm.import.completed.v1` | FR-07-021, FR-07-022 | `jobId`, `status` |
| EVT-07-08 | `{tenant}.rdm.export.completed.v1` | FR-07-024 | `jobId`, `catalogCode`, `status` |
| EVT-07-09 | `{tenant}.rdm.sync.completed.v1` | FR-07-036, FR-07-037 | `runId`, `catalogCode`, `status`, `hasBreaking` |
| EVT-07-10 | `common.rdm.adminunit.reorganized.v1` | FR-07-016 (danh mục DVHC), FR-07-045 | `versionNo`, `effectiveFrom`, `events` |

Chính sách tương thích: trong cùng hậu tố `v1` chỉ được thêm trường tùy chọn; lược đồ được đăng ký ở Apicurio với chế độ kiểm tra BACKWARD, CI chặn thay đổi không tương thích. Topic giữ dữ liệu 7 ngày (6 phân vùng, 3 bản sao); consumer chậm hơn 7 ngày phải đồng bộ lại bằng API delta (API-07-046). Mã EVT-07-11 được giữ chỗ cho sự kiện "phiên bản đã duyệt" (Q07-05 của FRS).

## 5. Hợp đồng với bên ngoài

PH-07 không gọi trực tiếp hệ thống bên ngoài nào. Kết nối Nền tảng chia sẻ, điều phối dữ liệu quốc gia (NDXP, theo Nghị định 278/2025/NĐ-CP) đi qua adapter `NDXP_DMDC` của PH-14 (ADR-057). PH-14 công bố cho PH-07 bốn thao tác REST nội bộ qua mesh mTLS với token dịch vụ; hợp đồng chi tiết thuộc tài liệu D03-04 của PH-14, PH-07 dùng client sinh từ hợp đồng đó.

| Thao tác PH-14 | PH-07 dùng ở | Thời gian chờ, thử lại | Khi lỗi |
|---|---|---|---|
| Liệt kê danh mục quốc gia | FR-07-038, API-07-063 | 10 giây; thử lại 2 lần, giãn cách lũy thừa | ERR-07-028 (502) |
| Lấy cấu trúc một danh mục | FR-07-035 (kiểm tra `remoteCode`), FR-07-036 | 10 giây; 2 lần | Lần chạy `FAILED`, thử lại theo lịch |
| Lấy dữ liệu một danh mục (phân trang) | FR-07-036 | 30 giây mỗi trang; 3 lần | Lần chạy `FAILED`, giữ nguyên phiên bản hiện hành |
| Gửi đề xuất bổ sung | FR-07-039 | 30 giây; không tự thử lại (tránh gửi trùng), dùng `Idempotency-Key` | Đề xuất `UNKNOWN`, làm mới ở lần đồng bộ sau |

Trong giai đoạn chạy song song với hệ cũ (D06-01), PH-07 không gọi Aita. Việc cấp dữ liệu ngược cho Aita (nếu cần) dùng xuất tệp khuôn `LEGACY_AITA` (FR-07-024).

## 6. Bảng mã lỗi ERR-07

Đây là nơi định nghĩa duy nhất mã lỗi của PH-07 (D00-01 §3). Câu hiển thị cho người dùng ở D03-06-PH07 §5.3; điều kiện phát sinh chi tiết ở bảng ngoại lệ của từng FR trong D02-03-PH07. Ví dụ bản tin lỗi cho từng nhóm HTTP ở `components/responses` của hợp đồng.

| Mã | HTTP | Điều kiện |
|---|---|---|
| ERR-07-001 | 404 | Không tìm thấy danh mục (hoặc thuộc tenant khác) |
| ERR-07-002 | 409 | Mã đã được dùng: mã danh mục, mã hệ thống mã, nguồn đồng bộ trùng |
| ERR-07-003 | 403 | Danh mục hoặc đối tượng chỉ đọc với chủ thể (`NATIONAL`, `COMMON` với tenant tỉnh, bản ghi gốc qua HYBRID, lược đồ ĐVHC) |
| ERR-07-004 | 409 | Phiên bản hoặc tác vụ không ở trạng thái cho phép thao tác |
| ERR-07-005 | 409 | Đã có phiên bản mở; nguồn đang có lần chạy đồng bộ |
| ERR-07-006 | 404 | Không tìm thấy phiên bản, hoặc không có phiên bản hiệu lực tại thời điểm |
| ERR-07-007 | 404 | Không tìm thấy mã bản ghi tại thời điểm |
| ERR-07-008 | 409 | Mã bản ghi trùng trong phiên bản hoặc trùng mã gốc của HYBRID |
| ERR-07-009 | 422 | Dữ liệu không hợp lệ theo lược đồ hoặc theo ràng buộc của trường, kèm `errors[]` |
| ERR-07-010 | 422 | Mã cha không tồn tại hoặc tạo vòng |
| ERR-07-011 | 422 | Vượt độ sâu tối đa |
| ERR-07-012 | 422 | Mã bổ sung nằm ngoài dải mã địa phương, hoặc dải chồng mã gốc |
| ERR-07-013 | 409 | Xóa bản ghi đã từng phát hành |
| ERR-07-014 | 422 | Thay đổi thuộc tính không tương thích với giá trị hiện có |
| ERR-07-015 | 403 | Vi phạm bốn mắt |
| ERR-07-016 | 409 | Phát hành thẳng nhưng có thay đổi lớn hoặc phá vỡ, phải qua duyệt |
| ERR-07-017 | 422 | Ngày hiệu lực không hợp lệ |
| ERR-07-018 | 412 | ETag không khớp (`If-Match`) |
| ERR-07-019 | 422 | Tệp không hợp lệ: định dạng, mã hóa, kích thước, số dòng, khuôn, gói nền hỏng |
| ERR-07-020 | 409 | Tác vụ nhập không còn ghi được (hết hạn, bản nháp đã đổi, lược đồ chỉnh làm đổi kết quả) |
| ERR-07-021 | 422 | Còn dòng hoặc bản ghi lỗi mà không chọn bỏ qua |
| ERR-07-022 | 409 | `Idempotency-Key` đã dùng với nội dung khác |
| ERR-07-023 | 400 | Biểu thức truy vấn sai cú pháp |
| ERR-07-024 | 422 | Truy vấn hoặc cây vượt giới hạn độ phức tạp, kích thước hoặc thời gian |
| ERR-07-025 | 400 | Thuộc tính không cho phép truy vấn |
| ERR-07-026 | 400 | Số lượng vượt mức tối đa một lần (lô, trang) |
| ERR-07-027 | 404 | Không tìm thấy ánh xạ |
| ERR-07-028 | 502 | Nguồn quốc gia (qua PH-14) không phản hồi hoặc trả lỗi |
| ERR-07-029 | 409 | Lần đồng bộ không còn chờ xác nhận, hoặc phiên bản gốc đã đổi |
| ERR-07-030 | 403 | HTTT chưa được cấp quyền khai thác danh mục hạn chế |
| ERR-07-031 | 410 | Danh mục đã ngừng hiệu lực (tại thời điểm tra) |
| ERR-07-032 | 409 | Danh mục đang bị tham chiếu nên không ngừng hiệu lực được |
| ERR-07-033 | 422 | Mã ngoài đã ánh xạ tới mã khác trong khoảng hiệu lực giao nhau |
| ERR-07-034 | 422 | Ánh xạ tạm thời thiếu lý do |
| ERR-07-035 | 422 | Sự kiện sắp xếp ĐVHC không hợp lệ; nhập tay `replacedBy` cho ĐVHC |
| ERR-07-036 | 422 | Thuộc tính hoặc dữ liệu gợi ý dữ liệu cá nhân, mức Nhạy cảm |
| ERR-07-037 | 409 | Nhóm còn danh mục hoặc nhóm con nên không xóa được |
| ERR-07-038 | 422 | Tệp không vượt qua quét mã độc (`scan_status = INFECTED`) hoặc quét quá hạn (mới; thay ERR-07-040 của bản nháp D02-04-PH07) |
| ERR-07-039 | 409 | Mã nhóm danh mục trùng, nhóm cha tạo vòng hoặc vượt độ sâu 5 (mới; thay ERR-07-041 của bản nháp FR-07-010) |
| ERR-07-040 | 400 | Thiếu tiêu đề `If-Match` trên thao tác bắt buộc (quy ước 428 được quy về 400 cho thống nhất client) |
| ERR-07-041 | 401 | Thiếu token, token không hợp lệ hoặc hết hạn |
| ERR-07-042 | 413 | Thân yêu cầu hoặc tệp vượt kích thước tối đa |
| ERR-07-043 | 415 | Kiểu nội dung không hỗ trợ |
| ERR-07-044 | 429 | Vượt giới hạn tần suất |
| ERR-07-045 | 404 | Không tìm thấy tài nguyên khác: tác vụ, nguồn, lần chạy, hệ thống mã, sự kiện sắp xếp, tenant |
| ERR-07-046 | 403 | Không đủ quyền (khi PH-07 tự trả, ngoài lỗi phân quyền chung của gateway) |
| ERR-07-047 | 503 | Tài nguyên tạm chưa sẵn sàng (ảnh chụp đang sinh) hoặc phân hệ phụ thuộc (PH-13, PH-18) không sẵn sàng |
| ERR-07-048 | 409 | Danh mục hoặc tenant không ở trạng thái cho phép thao tác (xóa danh mục `ACTIVE`, ngừng hiệu lực danh mục `DRAFT`, nạp gói cho tenant không ở trạng thái khởi tạo) (mới; trả lời Q07-76 của D05-02-PH07) |

Bản nháp trước của bộ tài liệu từng dùng ERR-07-040 cho "tệp nhiễm mã độc" và ERR-07-041 cho "nhóm danh mục trùng, vòng"; hai nghĩa đó nay là ERR-07-038 và ERR-07-039, vì ERR-07-040…047 đã được cấp cho lỗi giao thức trong hợp đồng.

## 7. Kiểm tra hợp đồng trong CI

Hai tệp hợp đồng được kiểm tra ở cổng CI của D04-02: lint OpenAPI và AsyncAPI bằng Spectral với bộ luật dự án; mọi ví dụ phải khớp lược đồ; mọi `$ref` phân giải được; mỗi operation có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`; kiểm thử contract phía máy chủ (sinh từ hợp đồng) chạy trên `dh-data`; lược đồ sự kiện được kiểm tra tương thích ngược với bản đã đăng ký ở Apicurio. Tại thời điểm viết, hai tệp đã qua kiểm tra cú pháp, phân giải tham chiếu và kiểm tra ví dụ khớp lược đồ bằng JSON Schema 2020-12; lint Spectral sẽ chạy khi bộ luật dự án được đưa vào repo.

## 8. Câu hỏi mở

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q07-100 | Tên miền chính thức cho `type` của ProblemDetails (`https://datahub.gov.vn/problems/rdm/…` là giả định) | Chốt cùng D03-09 |
| Q07-101 | Thời gian giữ topic 7 ngày có đủ cho HTTT ngừng dài ngày (ví dụ bảo trì cuối tuần dài) | Giữ 7 ngày, HTTT dùng delta khi chậm hơn |
| Q07-102 | Hợp đồng chính thức của bốn thao tác PH-14 cho NDXP, nhất là có tham số phiên bản để bỏ qua khi không đổi (Q07-40 của SDD) | Chờ D03-04 của PH-14 |

