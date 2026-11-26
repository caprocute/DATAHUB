---
ma_tai_lieu: D03-04-PH07
ten: Đặc tả API và sự kiện phân hệ PH-07 Danh mục dùng chung
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kiến trúc sư, lập trình viên L-DATA, đội phát triển HTTT thành viên, kiểm thử viên
phan_he: PH-07
nguoi_lap: Nhóm phân hệ PH-07
mo_ta: Đặc tả 76 endpoint REST, 10 sự kiện Kafka và mã lỗi ERR-07 của phân hệ Danh mục dùng chung, sinh từ OpenAPI và AsyncAPI đã kiểm tra trong CI.
tai_lieu_lien_quan: D02-03-PH07 FRS; D03-02-PH07 SDD; D03-03-PH07 CSDL; D03-06-PH07 Màn hình; D05-02-PH07 Test case; D04-01 Quy ước mã
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

: Tóm tắt cho hội đồng thẩm định

Mọi tên miền, máy chủ, định danh và dữ liệu trong hợp đồng là giả lập.

## 0. Giới thiệu

Tài liệu đặc tả giao diện lập trình của PH-07: 76 endpoint REST cho tra cứu, quản trị, nhập xuất và đồng bộ danh mục, 10 sự kiện Kafka, hợp đồng với phân hệ khác và bảng mã lỗi ERR-07. Nguồn chuẩn là hai tệp máy đọc nêu ở phần Tóm tắt. Chương 9 đặc tả từng endpoint theo 10 mục, sinh tự động từ OpenAPI nên luôn khớp hợp đồng.

| Người đọc | Phần cần đọc |
|---|---|
| Lập trình viên L-DATA, giao diện | Chương 1, 2, 3, 9 |
| Đội phát triển HTTT thành viên | Chương 1, 2, 4, 9 |
| Kiểm thử viên | Chương 6, 7, 9 |
| ATTT, hội đồng thẩm định | Tóm tắt, chương 2, 5 |

: Người đọc và phần cần đọc

Thuật ngữ dùng chung với [D02-03-PH07](../../02-yeu-cau/frs/D02-03-PH07-frs-danh-muc.md) §1.4 và D00-01. Câu thông báo người dùng thấy theo từng mã lỗi ở FRS §9.2 và D03-06-PH07 §5.3. Tài liệu tham chiếu: D02-03-PH07 (FRS), D03-02-PH07 (SDD), D03-03-PH07 (CSDL), D03-06-PH07 (Màn hình), D05-02-PH07 (Test case).

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

: Quy ước chung

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

: Danh mục endpoint

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

: Danh mục sự kiện

Chính sách tương thích: trong cùng hậu tố `v1` chỉ được thêm trường tùy chọn; lược đồ được đăng ký ở Apicurio với chế độ kiểm tra BACKWARD, CI chặn thay đổi không tương thích. Topic giữ dữ liệu 7 ngày (6 phân vùng, 3 bản sao); consumer chậm hơn 7 ngày phải đồng bộ lại bằng API delta (API-07-046). Mã EVT-07-11 được giữ chỗ cho sự kiện "phiên bản đã duyệt" (Q07-05 của FRS).

## 5. Hợp đồng với bên ngoài

PH-07 không gọi trực tiếp hệ thống bên ngoài nào. Kết nối Nền tảng chia sẻ, điều phối dữ liệu quốc gia (NDXP, theo Nghị định 278/2025/NĐ-CP) đi qua adapter `NDXP_DMDC` của PH-14 (ADR-057). PH-14 công bố cho PH-07 bốn thao tác REST nội bộ qua mesh mTLS với token dịch vụ; hợp đồng chi tiết thuộc tài liệu D03-04 của PH-14, PH-07 dùng client sinh từ hợp đồng đó.

| Thao tác PH-14 | PH-07 dùng ở | Thời gian chờ, thử lại | Khi lỗi |
|---|---|---|---|
| Liệt kê danh mục quốc gia | FR-07-038, API-07-063 | 10 giây; thử lại 2 lần, giãn cách lũy thừa | ERR-07-028 (502) |
| Lấy cấu trúc một danh mục | FR-07-035 (kiểm tra `remoteCode`), FR-07-036 | 10 giây; 2 lần | Lần chạy `FAILED`, thử lại theo lịch |
| Lấy dữ liệu một danh mục (phân trang) | FR-07-036 | 30 giây mỗi trang; 3 lần | Lần chạy `FAILED`, giữ nguyên phiên bản hiện hành |
| Gửi đề xuất bổ sung | FR-07-039 | 30 giây; không tự thử lại (tránh gửi trùng), dùng `Idempotency-Key` | Đề xuất `UNKNOWN`, làm mới ở lần đồng bộ sau |

: Hợp đồng với bên ngoài

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

: Bảng mã lỗi ERR-07

Bản nháp trước của bộ tài liệu từng dùng ERR-07-040 cho "tệp nhiễm mã độc" và ERR-07-041 cho "nhóm danh mục trùng, vòng"; hai nghĩa đó nay là ERR-07-038 và ERR-07-039, vì ERR-07-040…047 đã được cấp cho lỗi giao thức trong hợp đồng.

## 7. Kiểm tra hợp đồng trong CI

Hai tệp hợp đồng được kiểm tra ở cổng CI của D04-02: lint OpenAPI và AsyncAPI bằng Spectral với bộ luật dự án; mọi ví dụ phải khớp lược đồ; mọi `$ref` phân giải được; mỗi operation có `x-datahub-id`, `x-datahub-fr`, `x-datahub-permission`; kiểm thử contract phía máy chủ (sinh từ hợp đồng) chạy trên `dh-data`; lược đồ sự kiện được kiểm tra tương thích ngược với bản đã đăng ký ở Apicurio. Tại thời điểm viết, hai tệp đã qua kiểm tra cú pháp, phân giải tham chiếu và kiểm tra ví dụ khớp lược đồ bằng JSON Schema 2020-12; lint Spectral sẽ chạy khi bộ luật dự án được đưa vào repo.

## 8. Câu hỏi mở

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q07-100 | Tên miền chính thức cho `type` của ProblemDetails (`https://datahub.gov.vn/problems/rdm/…` là giả định) | Chốt cùng D03-09 |
| Q07-101 | Thời gian giữ topic 7 ngày có đủ cho HTTT ngừng dài ngày (ví dụ bảo trì cuối tuần dài) | Giữ 7 ngày, HTTT dùng delta khi chậm hơn |
| Q07-102 | Hợp đồng chính thức của bốn thao tác PH-14 cho NDXP, nhất là có tham số phiên bản để bỏ qua khi không đổi (Q07-40 của SDD) | Chờ D03-04 của PH-14 |

: Câu hỏi mở

## 9. Đặc tả từng endpoint

Mỗi endpoint một khối 10 mục, sinh từ `ph07/openapi-rdm.yaml` bằng `build/tools/sinh_dac_ta_api.py`. Sửa hợp đồng rồi chạy lại công cụ, không sửa tay phần sinh.

<!-- gen:dac-ta-api:start -->

### Danh mục

#### API-07-001 · Danh sách danh mục

::: dac-ta
**Mục đích.** Danh sách danh mục.

**Phương thức, đường dẫn.** `GET /catalogs`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-001, FR-07-033.

**Tham số.** `q` (query, string, tùy chọn); `groupId` (query, string, tùy chọn); `sourceType` (query, array, tùy chọn); `status` (query, array, tùy chọn); `classification` (query, array, tùy chọn); `scope` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `429` Vượt giới hạn tần suất (ERR-07-044), do APISIX hoặc `dh-data` trả.

**Ghi chú.** Trả danh sách danh mục mà người gọi được thấy: danh mục của tenant hiện tại cộng danh mục COMMON (RLS `tenant_id IN (current, 'COMMON')`). Lọc theo nhóm, nguồn, trạng thái, phân loại; tìm từ khóa không dấu trên mã và tên. Kèm số đếm theo trạng thái trong `facets` để giao diện UI-07-01 hiển thị huy hiệu. HTTT có scope `rdm.read` cũng gọi được để khám phá danh mục (FR-07-033); khi đó danh mục RESTRICTED chỉ hiện nếu HTTT được cấp quyền.
:::

#### API-07-002 · Tạo danh mục kèm bản nháp phiên bản 1

::: dac-ta
**Mục đích.** Tạo danh mục kèm bản nháp phiên bản 1.

**Phương thức, đường dẫn.** `POST /catalogs`.

**Quyền.** `PERM-07-create`.

**FR hiện thực.** FR-07-003, FR-07-005, FR-07-007, FR-07-008.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `CatalogCreateRequest`; trường bắt buộc: `code`, `name`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Catalog`; tiêu đề `Location`, `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `415` Kiểu nội dung không hỗ trợ (ERR-07-043); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036); `429` Vượt giới hạn tần suất (ERR-07-044), do APISIX hoặc `dh-data` trả.

**Ghi chú.** Tạo danh mục mới ở trạng thái `DRAFT` cùng phiên bản nháp số 1 và các thuộc tính ban đầu trong một giao dịch. Mã danh mục được chuẩn hóa chữ hoa, phải duy nhất trong tenant và không trùng mã danh mục COMMON đang ACTIVE (BR-07-001). Danh mục `NATIONAL` không tạo được qua API này mà qua API-07-056 (nguồn đồng bộ). Danh mục `HYBRID` bắt buộc `extendsCatalogCode` trỏ tới danh mục COMMON/NATIONAL và `localCodePattern`. Thuộc tính có tên gợi ý dữ liệu cá nhân hoặc mức Nhạy cảm bị từ chối (BR-07-025). Phát sự kiện EVT-07-01 qua outbox.
:::

#### API-07-003 · Chi tiết danh mục

::: dac-ta
**Mục đích.** Chi tiết danh mục.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-002.

**Tham số.** `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Catalog`; tiêu đề `ETag`; `304` không đổi; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Trả thông tin danh mục, phiên bản hiện hành, phiên bản đang mở (nếu có), cấu hình phân cấp, nguồn và số liệu tóm tắt. Header `ETag` dùng cho PATCH/DELETE/`:retire` tiếp theo. Danh mục đã xóa mềm trả 404; danh mục RETIRED vẫn trả 200 với `status = RETIRED`.
:::

#### API-07-004 · Cập nhật thông tin danh mục

::: dac-ta
**Mục đích.** Cập nhật thông tin danh mục.

**Phương thức, đường dẫn.** `PATCH /catalogs/{catalogCode}`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-004, FR-07-008.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/merge-patch+json: `CatalogUpdateRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Catalog`; tiêu đề `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `410` Danh mục đã ngừng hiệu lực tại thời điểm tra (ERR-07-031); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Cập nhật một phần theo JSON Merge Patch (RFC 7396): trường vắng mặt giữ nguyên, trường `null` xóa giá trị (chỉ với trường không bắt buộc). Không đổi được `code`, `sourceType` (trừ LOCAL → HYBRID khi chưa phát hành), `extendsCatalogCode` sau khi đã phát hành. Thay đổi `maxDepth` nhỏ hơn độ sâu thực tế của phiên bản hiện hành bị từ chối ERR-07-011. Phát EVT-07-02.
:::

#### API-07-005 · Xóa danh mục chưa phát hành

::: dac-ta
**Mục đích.** Xóa danh mục chưa phát hành.

**Phương thức, đường dẫn.** `DELETE /catalogs/{catalogCode}`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-009.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018).

**Ghi chú.** Xóa mềm (`deleted_at`) danh mục ở trạng thái `DRAFT` (chưa từng có phiên bản phát hành). Danh mục ACTIVE phải dùng `:retire`; gọi xóa trả 409 ERR-07-004. Thao tác yêu cầu xác nhận trên giao diện (FR-00-050) và sinh bản ghi kiểm toán.
:::

#### API-07-006 · Ngừng hiệu lực danh mục

::: dac-ta
**Mục đích.** Ngừng hiệu lực danh mục.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}:retire`.

**Quyền.** `PERM-07-retire`.

**FR hiện thực.** FR-07-009.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `CatalogRetireRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Catalog`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Chuyển danh mục ACTIVE sang RETIRED. Phiên bản hiện hành được đặt `effectiveTo` bằng `effectiveTo` trong yêu cầu (mặc định ngày mai theo giờ Việt Nam); phiên bản đang mở bị hủy. Bị chặn nếu danh mục đang được thuộc tính `CATALOG_REF` của danh mục ACTIVE khác tham chiếu (BR-07-020, ERR-07-032) hoặc đang có nguồn đồng bộ bật. Sau thời điểm ngừng, API khai thác trả 410 ERR-07-031 với truy vấn tại thời điểm sau `effectiveTo`; truy vấn `at` trong quá khứ vẫn trả dữ liệu lịch sử. Phát EVT-07-03.
:::

### Nhóm danh mục

#### API-07-007 · Cây nhóm danh mục

::: dac-ta
**Mục đích.** Cây nhóm danh mục.

**Phương thức, đường dẫn.** `GET /catalog-groups`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-010.

**Tham số.** `flat` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, object.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030).

**Ghi chú.** Trả toàn bộ cây nhóm của tenant cộng nhóm COMMON, kèm số danh mục trong mỗi nhóm (không gồm nhóm con).
:::

#### API-07-008 · Tạo nhóm danh mục

::: dac-ta
**Mục đích.** Tạo nhóm danh mục.

**Phương thức, đường dẫn.** `POST /catalog-groups`.

**Quyền.** `PERM-07-configure`.

**FR hiện thực.** FR-07-010.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `CatalogGroupCreateRequest`; trường bắt buộc: `code`, `name`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `CatalogGroup`; tiêu đề `Location`, `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037).

**Ghi chú.** Không.
:::

#### API-07-009 · Sửa nhóm danh mục

::: dac-ta
**Mục đích.** Sửa nhóm danh mục.

**Phương thức, đường dẫn.** `PATCH /catalog-groups/{groupId}`.

**Quyền.** `PERM-07-configure`.

**FR hiện thực.** FR-07-010.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/merge-patch+json: `CatalogGroupUpdateRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogGroup`; tiêu đề `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Sửa tên, mô tả, thứ tự, nhóm cha. Đổi nhóm cha tạo vòng bị từ chối ERR-07-010.
:::

#### API-07-010 · Xóa nhóm rỗng

::: dac-ta
**Mục đích.** Xóa nhóm rỗng.

**Phương thức, đường dẫn.** `DELETE /catalog-groups/{groupId}`.

**Quyền.** `PERM-07-configure`.

**FR hiện thực.** FR-07-010.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018).

**Ghi chú.** Chỉ xóa được nhóm không còn danh mục và không còn nhóm con (ERR-07-037).
:::

### Phiên bản

#### API-07-011 · Danh sách phiên bản

::: dac-ta
**Mục đích.** Danh sách phiên bản.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/versions`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-002.

**Tham số.** `status` (query, array, tùy chọn); `includeDiscarded` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogVersionPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Liệt kê phiên bản theo `versionNo` giảm dần, gồm phiên bản đã phát hành (kèm nhãn tính `effectiveState`) và phiên bản đang mở. Phiên bản `DISCARDED` chỉ hiện khi `includeDiscarded=true`.
:::

#### API-07-012 · Tạo bản nháp từ phiên bản hiện hành

::: dac-ta
**Mục đích.** Tạo bản nháp từ phiên bản hiện hành.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/versions`.

**Quyền.** `PERM-07-create`.

**FR hiện thực.** FR-07-011.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn); `Prefer` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `VersionCreateRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `CatalogVersion`; tiêu đề `Location`, `ETag`; `202` đã nhận, xử lý bất đồng bộ, `CatalogVersion`; tiêu đề `Location`, `Retry-After`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `410` Danh mục đã ngừng hiệu lực tại thời điểm tra (ERR-07-031); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Tạo phiên bản `DRAFT` mới với `versionNo` = số lớn nhất + 1, sao chép toàn bộ lược đồ thuộc tính và bản ghi của phiên bản gốc (mặc định là phiên bản hiện hành; có thể chọn `baseVersionNo` là một phiên bản đã phát hành khác để khôi phục). Sao chép thực hiện bằng `INSERT … SELECT` trong một giao dịch nên với 200.000 bản ghi vẫn nằm trong vài giây; nếu vượt 3 giây, máy chủ trả 202 kèm `Location` tới phiên bản ở trạng thái đang sao chép (`copying = true`). Bị từ chối nếu danh mục đã có phiên bản mở (BR-07-005, ERR-07-005), là danh mục NATIONAL (ERR-07-003) hoặc RETIRED (ERR-07-031).
:::

#### API-07-013 · Chi tiết phiên bản

::: dac-ta
**Mục đích.** Chi tiết phiên bản.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/versions/{versionRef}`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-002.

**Tham số.** `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogVersion`; tiêu đề `ETag`; `304` không đổi; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** `versionRef` nhận số phiên bản, `current` (phiên bản hiệu lực hôm nay) hoặc `draft` (phiên bản đang mở, dù ở DRAFT, IN_REVIEW hay APPROVED). Kèm lịch sử duyệt `reviews`.
:::

#### API-07-014 · Sửa ngày hiệu lực, căn cứ, ghi chú của bản nháp

::: dac-ta
**Mục đích.** Sửa ngày hiệu lực, căn cứ, ghi chú của bản nháp.

**Phương thức, đường dẫn.** `PATCH /catalogs/{catalogCode}/versions/{versionRef}`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-016.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/merge-patch+json: `VersionUpdateRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogVersion`; tiêu đề `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Chỉ áp dụng cho phiên bản `DRAFT`. `effectiveFrom` phải lớn hơn `effectiveFrom` của phiên bản đã phát hành mới nhất (BR-07-007) và không sớm hơn hôm nay trừ phiên bản có `origin` SYNC/MIGRATION (BR-07-027). ETag của phiên bản đổi khi bất kỳ bản ghi hay thuộc tính nào của bản nháp thay đổi, vì `version` của phiên bản được tăng theo mọi thao tác.
:::

#### API-07-015 · Hủy bản nháp

::: dac-ta
**Mục đích.** Hủy bản nháp.

**Phương thức, đường dẫn.** `DELETE /catalogs/{catalogCode}/versions/{versionRef}`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-017.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018).

**Ghi chú.** Chuyển phiên bản `DRAFT` sang `DISCARDED`; bản ghi và thuộc tính của bản nháp được xóa vật lý bởi tác vụ dọn dẹp sau 7 ngày (giữ dấu vết `version_review` với hành động DISCARD). Phiên bản IN_REVIEW phải bị từ chối về DRAFT trước. Nếu đây là phiên bản 1 của danh mục DRAFT, danh mục vẫn tồn tại và có thể tạo lại bản nháp.
:::

#### API-07-016 · Kiểm tra hợp lệ toàn bản nháp

::: dac-ta
**Mục đích.** Kiểm tra hợp lệ toàn bản nháp.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/versions/{versionRef}:validate`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-013.

**Tham số.** `Prefer` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ValidationReport`; trường bắt buộc: `valid`, `errorCount`, `warningCount`; `202` đã nhận, xử lý bất đồng bộ; tiêu đề `Location`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037).

**Ghi chú.** Chạy toàn bộ quy tắc trên bản nháp: kiểu và ràng buộc thuộc tính (JSON Schema sinh từ lược đồ), duy nhất, mã cha tồn tại, không vòng, độ sâu (BR-07-014), dải mã địa phương (BR-07-010), khoảng hiệu lực, và tính phân loại thay đổi so với phiên bản hiện hành để trả `requiresApproval`. Không đổi trạng thái; idempotent. Với danh mục > 50.000 bản ghi và `Prefer: respond-async`, trả 202 và kết quả sẽ nằm ở `GET …/versions/{v}` trường `lastValidation`.
:::

#### API-07-017 · Trình duyệt phiên bản

::: dac-ta
**Mục đích.** Trình duyệt phiên bản.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/versions/{versionRef}:submit`.

**Quyền.** `PERM-07-submit`.

**FR hiện thực.** FR-07-015.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `VersionActionRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogVersion`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Chuyển `DRAFT` → `IN_REVIEW` sau khi chạy lại kiểm tra hợp lệ; bản nháp có lỗi trả 422 ERR-07-009 kèm `errors[]`. Ghi `version_review` (SUBMIT) với `diffStats`, đặt `submittedBy/At`, phát EVT-07-04 để hộp "Việc của tôi" (FR-00-070) tạo việc cho người có `PERM-07-publish`. Trong IN_REVIEW, bản nháp bị khóa sửa.
:::

#### API-07-018 · Duyệt phiên bản

::: dac-ta
**Mục đích.** Duyệt phiên bản.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/versions/{versionRef}:approve`.

**Quyền.** `PERM-07-publish`.

**FR hiện thực.** FR-07-015.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: .

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogVersion`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018).

**Ghi chú.** Chuyển `IN_REVIEW` → `APPROVED`. Bốn mắt: người trình hoặc người sửa bản nháp lần cuối không được duyệt (BR-07-011, ERR-07-015). Ý kiến duyệt là bắt buộc (FR-00-072).
:::

#### API-07-019 · Từ chối phiên bản

::: dac-ta
**Mục đích.** Từ chối phiên bản.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/versions/{versionRef}:reject`.

**Quyền.** `PERM-07-publish`.

**FR hiện thực.** FR-07-015.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogVersion`; tiêu đề `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018).

**Ghi chú.** Chuyển `IN_REVIEW` (hoặc `APPROVED` chưa phát hành) về `DRAFT`, bắt buộc lý do. Ghi `version_review` (REJECT), phát EVT-07-06 để thông báo cho người trình.
:::

#### API-07-020 · Phát hành phiên bản

::: dac-ta
**Mục đích.** Phát hành phiên bản.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/versions/{versionRef}:publish`.

**Quyền.** `PERM-07-publish`.

**FR hiện thực.** FR-07-016.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `PublishRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogVersion`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Phát hành phiên bản `APPROVED`, hoặc phát hành thẳng từ `DRAFT` khi danh mục có `requireApproval = false` và thay đổi không vượt ngưỡng, không phá vỡ (BR-07-012, BR-07-026; nếu vi phạm trả 409 ERR-07-016). Trong một giao dịch: chốt `effectiveFrom`, đặt `effectiveTo` của phiên bản trước bằng `effectiveFrom` mới (BR-07-007), cập nhật `catalog.currentVersionId` nếu `effectiveFrom` ≤ hôm nay, chuyển danh mục DRAFT → ACTIVE, làm mới bảng chiếu `admin_unit` nếu là danh mục DVHC, ghi outbox EVT-07-05 (và EVT-07-10 nếu có sự kiện sắp xếp ĐVHC). Sau commit, tác vụ nền sinh ảnh chụp JSON.gz/CSV lên Garage; `snapshotUri` được điền khi xong (NFR-07-007). Bốn mắt áp dụng như `:approve`.
:::

#### API-07-021 · So sánh hai phiên bản

::: dac-ta
**Mục đích.** So sánh hai phiên bản.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/versions/{versionRef}/diff`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-014.

**Tham số.** `against` (query, string, tùy chọn); `changeType` (query, array, tùy chọn); `breakingOnly` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Diff`; trường bắt buộc: `catalogCode`, `fromVersionNo`, `toVersion`, `summary`, `changes`, `page`; tiêu đề `ETag`, `Cache-Control`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** So sánh phiên bản `versionRef` với `against` (mặc định: phiên bản đã phát hành ngay trước, hoặc phiên bản hiện hành nếu `versionRef` là bản nháp). `summary` luôn tính trên toàn bộ; `changes` phân trang theo trang. Mỗi thay đổi có cờ `breaking` theo quy tắc §3 mục 18 của khung (ngừng dùng/xóa mã, đổi mã cha, xóa thuộc tính, đổi kiểu, thu hẹp ràng buộc).
:::

### Thuộc tính

#### API-07-022 · Danh sách thuộc tính của phiên bản

::: dac-ta
**Mục đích.** Danh sách thuộc tính của phiên bản.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/versions/{versionRef}/attributes`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-005.

**Tham số.** `includeHidden` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, object; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Trả thuộc tính theo `sortOrder`. Thuộc tính `HIDDEN` chỉ trả cho người dùng quản trị khi `includeHidden=true`.
:::

#### API-07-023 · Thêm thuộc tính vào bản nháp

::: dac-ta
**Mục đích.** Thêm thuộc tính vào bản nháp.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/versions/{versionRef}/attributes`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-005.

**Tham số.** `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `AttributeDefCreateRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `AttributeDef`; tiêu đề `Location`, `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Thêm thuộc tính mới. Thuộc tính bắt buộc chỉ thêm được khi kèm `defaultValue` hoặc bản nháp chưa có bản ghi (nếu không, mọi bản ghi hiện có sẽ vi phạm, ERR-07-014). Mã thuộc tính không trùng mã cột cố định (`code`, `name`, `parentCode`…). Từ khóa gợi ý dữ liệu cá nhân (`cccd`, `so_dinh_danh`, `ho_ten`, `ngay_sinh`, `so_dien_thoai`…) bị chặn ERR-07-036.
:::

#### API-07-024 · Sửa thuộc tính trên bản nháp

::: dac-ta
**Mục đích.** Sửa thuộc tính trên bản nháp.

**Phương thức, đường dẫn.** `PATCH /catalogs/{catalogCode}/versions/{versionRef}/attributes/{attrCode}`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-006.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/merge-patch+json: `AttributeDefUpdateRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AttributeDef`; tiêu đề `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Sửa nhãn, ràng buộc, thứ tự, trạng thái (`ACTIVE`/`HIDDEN`), cờ `queryable`/`searchable` hoặc đổi `dataType`. Đổi kiểu chỉ được khi mọi giá trị hiện có chuyển đổi được (BR-07-013); nếu không trả 422 ERR-07-014 kèm tối đa 100 phần tử `errors[]` chỉ rõ mã bản ghi vi phạm. Thu hẹp ràng buộc được phép nhưng bị đánh dấu thay đổi phá vỡ khi phát hành.
:::

#### API-07-025 · Xóa thuộc tính khỏi bản nháp

::: dac-ta
**Mục đích.** Xóa thuộc tính khỏi bản nháp.

**Phương thức, đường dẫn.** `DELETE /catalogs/{catalogCode}/versions/{versionRef}/attributes/{attrCode}`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-006.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018).

**Ghi chú.** Xóa định nghĩa và gỡ khóa tương ứng khỏi `attrs` của mọi bản ghi trong bản nháp. Nếu thuộc tính tồn tại ở phiên bản đã phát hành, thao tác là thay đổi phá vỡ (bắt buộc duyệt). Không xóa được thuộc tính đang là đích của ánh xạ trường đồng bộ (`fieldMapping`).
:::

### Bản ghi (quản trị)

#### API-07-026 · Bản ghi của một phiên bản (quản trị)

::: dac-ta
**Mục đích.** Bản ghi của một phiên bản (quản trị).

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/versions/{versionRef}/items`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-002, FR-07-018.

**Tham số.** `q` (query, string, tùy chọn); `status` (query, ItemStatus, tùy chọn); `parentCode` (query, string, tùy chọn); `changeState` (query, array, tùy chọn); `hasErrors` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn); `sort` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogItemPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Phục vụ UI-07-02/05: phân trang theo trang, lọc theo trạng thái, mã cha, trạng thái thay đổi so với phiên bản hiện hành (`changeState`, chỉ có nghĩa với bản nháp), tìm không dấu. Khác API-07-041 ở chỗ xem được bản nháp, có `changeState` và không có bộ đệm HTTP.
:::

#### API-07-027 · Thêm bản ghi vào bản nháp

::: dac-ta
**Mục đích.** Thêm bản ghi vào bản nháp.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/versions/{versionRef}/items`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-012.

**Tham số.** `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `ItemCreateRequest`; trường bắt buộc: `code`, `name`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `CatalogItem`; trường bắt buộc: `code`, `name`, `status`; tiêu đề `Location`, `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Thêm một bản ghi. Mã được chuẩn hóa chữ hoa, duy nhất trong phiên bản (BR-07-002, ERR-07-008). `attrs` được kiểm tra theo JSON Schema của phiên bản (ERR-07-009). Với danh mục phân cấp, `parentCode` phải tồn tại và độ sâu ≤ `maxDepth` (ERR-07-010, 011). Với danh mục HYBRID, mã phải khớp `localCodePattern` và không trùng mã danh mục gốc (ERR-07-012). `depth`, `path`, `levelName` do máy chủ tính. ETag trả về là ETag mới của phiên bản để client tiếp tục gửi `If-Match` cho thao tác sau.
:::

#### API-07-028 · Sửa bản ghi trên bản nháp

::: dac-ta
**Mục đích.** Sửa bản ghi trên bản nháp.

**Phương thức, đường dẫn.** `PATCH /catalogs/{catalogCode}/versions/{versionRef}/items/{itemCode}`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-012.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/merge-patch+json: `ItemUpdateRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogItem`; trường bắt buộc: `code`, `name`, `status`; tiêu đề `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** JSON Merge Patch. Riêng `attrs` được gộp theo khóa: khóa có giá trị `null` bị gỡ (nếu thuộc tính không bắt buộc), khóa vắng mặt giữ nguyên. Đổi `parentCode` của bản ghi đã từng phát hành là thay đổi phá vỡ. Không đổi được `code` (muốn đổi mã thì ngừng dùng mã cũ với `replacedBy` trỏ mã mới — BR-07-003).
:::

#### API-07-029 · Ngừng dùng bản ghi, ghi mã thay thế

::: dac-ta
**Mục đích.** Ngừng dùng bản ghi, ghi mã thay thế.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/versions/{versionRef}/items/{itemCode}:deprecate`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-012, FR-07-019.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ItemDeprecateRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogItem`; trường bắt buộc: `code`, `name`, `status`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Đặt `status = DEPRECATED`, ghi `replacedBy` (mỗi mã phải tồn tại và ACTIVE trong cùng bản nháp) và `validTo` (mặc định bằng `effectiveFrom` của bản nháp). Bản ghi con còn ACTIVE làm thao tác thất bại 422 ERR-07-010 trừ khi `cascade = true` (ngừng dùng cả nhánh). Gọi lại với `reactivate = true` để khôi phục ACTIVE trong cùng bản nháp.
:::

#### API-07-030 · Xóa bản ghi mới thêm trong bản nháp

::: dac-ta
**Mục đích.** Xóa bản ghi mới thêm trong bản nháp.

**Phương thức, đường dẫn.** `DELETE /catalogs/{catalogCode}/versions/{versionRef}/items/{itemCode}`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-012.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Chỉ xóa được bản ghi chưa từng xuất hiện ở phiên bản đã phát hành nào (`changeState = ADDED`). Bản ghi đã từng phát hành trả 409 ERR-07-013, client phải dùng `:deprecate`. Bản ghi còn con trong bản nháp trả 422 ERR-07-010.
:::

#### API-07-031 · Nhập lô bản ghi vào bản nháp (≤ 5.000 thao tác)

::: dac-ta
**Mục đích.** Nhập lô bản ghi vào bản nháp (≤ 5.000 thao tác).

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/versions/{versionRef}/items:batch`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-023.

**Tham số.** `Idempotency-Key` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `BatchItemsRequest`; trường bắt buộc: `ops`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `BatchResult`; trường bắt buộc: `total`, `succeeded`, `failed`, `results`; tiêu đề `ETag`, `Idempotent-Replayed`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `413` Thân yêu cầu hoặc tệp vượt kích thước tối đa (ERR-07-042); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036); `429` Vượt giới hạn tần suất (ERR-07-044), do APISIX hoặc `dh-data` trả.

**Ghi chú.** Áp dụng tối đa 5.000 thao tác `upsert`, `deprecate`, `delete` trong một giao dịch (`atomic = true`, mặc định: một thao tác lỗi thì không thao tác nào được ghi, trả 422 với `errors[].row` là chỉ số thao tác) hoặc từng phần (`atomic = false`: thao tác hợp lệ được ghi, trả 200 với `results[].status = FAILED` cho thao tác lỗi). `versionRef` thường là `draft`; nếu chưa có bản nháp và `createDraftIfMissing = true` thì máy chủ tạo bản nháp từ phiên bản hiện hành trước. Bắt buộc `Idempotency-Key` để HTTT gửi lại an toàn khi mất kết nối: cùng khóa và cùng băm thân trong 24 giờ trả lại đúng kết quả cũ với header `Idempotent-Replayed: true`; cùng khóa khác thân trả 409 ERR-07-022. Giới hạn 5.000 là tham số `07.rdm.batch-max-ops` (PH-18), vượt trả 400 ERR-07-026. Không yêu cầu `If-Match` vì lô thường do máy gửi; xung đột với người sửa song song được xử lý bằng khóa hàng.
:::

### Nhập xuất

#### API-07-032 · Tải tệp mẫu nhập theo lược đồ

::: dac-ta
**Mục đích.** Tải tệp mẫu nhập theo lược đồ.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/import-template`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-020.

**Tham số.** `format` (query, string, tùy chọn); `withData` (query, boolean, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, string; tiêu đề `Content-Disposition`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Sinh tệp mẫu theo lược đồ của bản nháp (nếu có) hoặc phiên bản hiện hành. Xlsx gồm sheet `HuongDan`, `DuLieu` (dòng 1 nhãn tiếng Việt, dòng 2 mã cột ẩn và khóa, dữ liệu từ dòng 3; cột cố định `MA`, `TEN`, `MA_CHA`, `THU_TU`, `TRANG_THAI`, `MA_THAY_THE`, `HIEU_LUC_TU`, `HIEU_LUC_DEN` rồi thuộc tính động theo `sortOrder`) và `GiaTriHopLe` (giá trị ENUM, có data validation). CSV: RFC 4180, UTF-8 có BOM, dòng tiêu đề là mã cột. `withData = true` điền sẵn bản ghi hiện có để sửa rồi nhập lại (chế độ UPSERT).
:::

#### API-07-033 · Tải tệp và tạo tác vụ nhập (pha 1)

::: dac-ta
**Mục đích.** Tải tệp và tạo tác vụ nhập (pha 1).

**Phương thức, đường dẫn.** `POST /import-jobs`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-021, FR-07-022.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** multipart/form-data: `ImportJobCreateForm`; trường bắt buộc: `file`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `ImportJob`; tiêu đề `Location`, `Retry-After`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `413` Thân yêu cầu hoặc tệp vượt kích thước tối đa (ERR-07-042); `415` Kiểu nội dung không hỗ trợ (ERR-07-043); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Nhận tệp multipart, lưu vào kho đối tượng (DD-12 `file_object`, `scan_status = PENDING`), tạo `import_job` trạng thái `SCANNING` và trả 202 ngay. Tác vụ nền quét mã độc, nhận dạng định dạng theo nội dung (không tin phần mở rộng), tự nhận mã hóa (UTF-8, UTF-8 BOM, UTF-16 LE/BE) nếu không chỉ định, phân tích luồng ghi vào `import_row`, kiểm tra hợp lệ và chuyển `VALIDATED` (hoặc `FAILED`). Client theo dõi qua `Location` hoặc sự kiện EVT-07-07. Kiểm tra đồng bộ trước khi nhận: kích thước ≤ 50 MB (413), kiểu nội dung (415), danh mục và bản nháp tồn tại, quyền ghi. Với `mode = CREATE_CATALOG` không cần `catalogCode` có sẵn mà dùng `newCatalog`. Với `template = LEGACY_AITA`, ô A2 là tên danh mục, dòng 4 là tên thuộc tính, dữ liệu từ dòng 5 (ADR-056).
:::

#### API-07-034 · Trạng thái, tóm tắt và xem trước tác vụ nhập

::: dac-ta
**Mục đích.** Trạng thái, tóm tắt và xem trước tác vụ nhập.

**Phương thức, đường dẫn.** `GET /import-jobs/{jobId}`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-021.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ImportJob`; tiêu đề `ETag`, `Retry-After`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Trả trạng thái, tiến độ, số dòng hợp lệ/lỗi, tóm tắt hành động (INSERT/UPDATE/DEPRECATE/ UNCHANGED), 20 dòng xem trước đầu tiên và thời điểm hết hạn xem trước (24 giờ, BR-07-016). ETag của tác vụ dùng làm `If-Match` cho `:commit`.
:::

#### API-07-035 · Dòng xem trước hoặc báo cáo lỗi

::: dac-ta
**Mục đích.** Dòng xem trước hoặc báo cáo lỗi.

**Phương thức, đường dẫn.** `GET /import-jobs/{jobId}/rows`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-021, FR-07-025.

**Tham số.** `valid` (query, boolean, tùy chọn); `action` (query, ImportRowAction, tùy chọn); `format` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ImportRowPage`; trường bắt buộc: `jobId`, `items`, `page`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037).

**Ghi chú.** Mặc định trả JSON phân trang. `valid=false` chỉ lấy dòng lỗi. `format=xlsx` (hoặc `Accept: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`) trả báo cáo lỗi là chính tệp người dùng tải lên có thêm cột `LOI` mô tả lỗi từng dòng và tô đỏ ô lỗi, để người dùng sửa và tải lên lại.
:::

#### API-07-036 · Ghi kết quả nhập vào bản nháp (pha 2)

::: dac-ta
**Mục đích.** Ghi kết quả nhập vào bản nháp (pha 2).

**Phương thức, đường dẫn.** `POST /import-jobs/{jobId}:commit`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-021, FR-07-022.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `ImportCommitRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ImportJob`; `202` đã nhận, xử lý bất đồng bộ, `ImportJob`; tiêu đề `Location`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Chỉ khi tác vụ `VALIDATED`, chưa hết hạn và bản nháp chưa bị sửa kể từ lúc phân tích (so `version` phiên bản lưu trong tác vụ; nếu khác trả 409 ERR-07-020 và client phải chạy lại tác vụ). Có dòng lỗi mà `skipInvalidRows = false` trả 422 ERR-07-021. Ghi trong một giao dịch bằng `COPY` vào bảng tạm rồi `INSERT … ON CONFLICT`, mục tiêu ≤ 60 giây cho 100.000 dòng (NFR-07-005). Với ≤ 5.000 dòng trả 200 đồng bộ; lớn hơn trả 202 và trạng thái `COMMITTING`. Với `CREATE_CATALOG`, tạo danh mục, phiên bản 1 và thuộc tính trong cùng giao dịch.
:::

#### API-07-037 · Hủy tác vụ nhập

::: dac-ta
**Mục đích.** Hủy tác vụ nhập.

**Phương thức, đường dẫn.** `POST /import-jobs/{jobId}:cancel`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-021.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ImportJob`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037).

**Ghi chú.** Hủy tác vụ chưa commit (SCANNING, PARSING, VALIDATED). Dòng tạm bị xóa ngay; tệp gốc giữ 7 ngày để tra soát.
:::

#### API-07-038 · Xuất phiên bản danh mục

::: dac-ta
**Mục đích.** Xuất phiên bản danh mục.

**Phương thức, đường dẫn.** `POST /export-jobs`.

**Quyền.** `PERM-07-export`.

**FR hiện thực.** FR-07-024.

**Tham số.** `Prefer` (header, string, tùy chọn); `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `ExportJobRequest`; trường bắt buộc: `catalogCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, string; tiêu đề `Content-Disposition`; `202` đã nhận, xử lý bất đồng bộ, `ExportJob`; tiêu đề `Location`, `Retry-After`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `429` Vượt giới hạn tần suất (ERR-07-044), do APISIX hoặc `dh-data` trả.

**Ghi chú.** Nếu số dòng ước tính ≤ 10.000 và không có `Prefer: respond-async`, trả 200 kèm nội dung tệp trực tiếp (đồng bộ). Ngược lại tạo tác vụ nền, trả 202 kèm `Location` tới API-07-039; khi xong phát EVT-07-08 và thông báo người dùng (FR-00-031). Tệp xuất có hạn tải 24 giờ. Định dạng XLSX dùng đúng khuôn mẫu nhập nên tệp xuất nhập lại được.
:::

#### API-07-039 · Trạng thái tác vụ xuất và URL tải

::: dac-ta
**Mục đích.** Trạng thái tác vụ xuất và URL tải.

**Phương thức, đường dẫn.** `GET /export-jobs/{jobId}`.

**Quyền.** `PERM-07-export`.

**FR hiện thực.** FR-07-024.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ExportJob`; tiêu đề `Retry-After`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Khi `COMPLETED`, `downloadUrl` là URL ký sẵn của Garage có hạn bằng `downloadExpiresAt` (tối đa 24 giờ kể từ khi xong); sau hạn trạng thái thành `EXPIRED` và tệp bị xóa.
:::

#### API-07-040 · Lịch sử tác vụ nhập xuất

::: dac-ta
**Mục đích.** Lịch sử tác vụ nhập xuất.

**Phương thức, đường dẫn.** `GET /jobs`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-025.

**Tham số.** `jobType` (query, string, tùy chọn); `catalogCode` (query, TCode, tùy chọn); `status` (query, array, tùy chọn); `mine` (query, boolean, tùy chọn); `createdFrom` (query, string, tùy chọn); `createdTo` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `JobSummaryPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030).

**Ghi chú.** Liệt kê tác vụ nhập và xuất của tenant, mặc định của chính người gọi; người có PERM-07-update thấy mọi tác vụ trên danh mục mình quản lý.
:::

### Khai thác

#### API-07-041 · Lấy toàn bộ bản ghi hiệu lực (con trỏ)

::: dac-ta
**Mục đích.** Lấy toàn bộ bản ghi hiệu lực (con trỏ).

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/items`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-028.

**Tham số.** `at` (query, string, tùy chọn); `versionNo` (query, integer, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn); `fields` (query, array, tùy chọn); `includeDeprecated` (query, boolean, tùy chọn); `parentCode` (query, string, tùy chọn); `level` (query, string, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CatalogItemCursorPage`; trường bắt buộc: `catalogCode`, `versionNo`, `items`, `cursor`; tiêu đề `ETag`, `Cache-Control`, `Datahub-Version-No`, `RateLimit-Limit`, `RateLimit-Remaining`; `304` không đổi; tiêu đề `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `410` Danh mục đã ngừng hiệu lực tại thời điểm tra (ERR-07-031); `429` Vượt giới hạn tần suất (ERR-07-044), do APISIX hoặc `dh-data` trả.

**Ghi chú.** Trả bản ghi của phiên bản hiệu lực tại `at` (mặc định hôm nay theo giờ Việt Nam, BR-07-008) hoặc của phiên bản chỉ định bằng `versionNo`, sắp theo (`sortOrder`, `code`), phân trang con trỏ. Con trỏ mờ gắn với `versionId` nên toàn bộ các trang luôn thuộc cùng một phiên bản dù giữa chừng có phiên bản mới được phát hành. Danh mục HYBRID trả hợp của bản COMMON hiệu lực và bản ghi bổ sung (`isLocalExtension = true`). Phản hồi có `ETag` dạng `"v{versionId}-{hash tham số}"` và `Cache-Control: public, max-age=300` (trang của phiên bản bất biến không bao giờ đổi), cộng header `Datahub-Version-No`. Với danh mục lớn, client nên dùng ảnh chụp (API-07-049) để nạp ban đầu rồi delta (API-07-046).
:::

#### API-07-042 · Tra một mã tại thời điểm

::: dac-ta
**Mục đích.** Tra một mã tại thời điểm.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/items/{itemCode}`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-026.

**Tham số.** `at` (query, string, tùy chọn); `versionNo` (query, integer, tùy chọn); `fields` (query, array, tùy chọn); `followReplacement` (query, boolean, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ItemLookupResult`; tiêu đề `ETag`, `Cache-Control`, `Datahub-Version-No`; `304` không đổi; tiêu đề `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `410` Danh mục đã ngừng hiệu lực tại thời điểm tra (ERR-07-031); `429` Vượt giới hạn tần suất (ERR-07-044), do APISIX hoặc `dh-data` trả.

**Ghi chú.** Tra một mã trong phiên bản hiệu lực tại `at`. So khớp mã không phân biệt hoa thường. Bản ghi ngừng dùng vẫn trả 200 với `status = DEPRECATED` và `replacedBy` (BR-07-004); `followReplacement = true` trả kèm bản ghi thay thế trong `replacements`. Mã không có trong phiên bản trả 404 ERR-07-007 (khác với ERR-07-001 khi chính danh mục không tồn tại, để client phân biệt lỗi cấu hình và lỗi dữ liệu). Mục tiêu p95 ≤ 20 ms (NFR-07-001): đường đi không chạm CSDL khi trúng bộ đệm L1/L2.
:::

#### API-07-043 · Tra lô tối đa 500 mã

::: dac-ta
**Mục đích.** Tra lô tối đa 500 mã.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/items:lookup`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-027.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `LookupRequest`; trường bắt buộc: `codes`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `LookupResponse`; trường bắt buộc: `catalogCode`, `versionNo`, `found`, `notFound`; tiêu đề `Datahub-Version-No`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `410` Danh mục đã ngừng hiệu lực tại thời điểm tra (ERR-07-031); `429` Vượt giới hạn tần suất (ERR-07-044), do APISIX hoặc `dh-data` trả.

**Ghi chú.** Tra nhiều mã trong một lượt, dùng POST vì danh sách mã có thể dài hơn giới hạn URL. Thao tác an toàn và idempotent về ngữ nghĩa (không ghi gì) nên không cần `Idempotency-Key`. Mã trùng trong yêu cầu được gộp; thứ tự `items` theo thứ tự xuất hiện đầu tiên trong `codes`. Mã không tìm thấy nằm trong `notFound` thay vì làm cả lô lỗi. Vượt 500 mã trả 400 ERR-07-026. Mục tiêu p95 ≤ 150 ms (NFR-07-002).
:::

#### API-07-044 · Lấy cây hoặc nhánh con

::: dac-ta
**Mục đích.** Lấy cây hoặc nhánh con.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/tree`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-029.

**Tham số.** `root` (query, string, tùy chọn); `depth` (query, integer, tùy chọn); `at` (query, string, tùy chọn); `versionNo` (query, integer, tùy chọn); `includeDeprecated` (query, boolean, tùy chọn); `withAttrs` (query, boolean, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TreeResponse`; trường bắt buộc: `catalogCode`, `versionNo`, `nodes`; tiêu đề `ETag`, `Cache-Control`, `Datahub-Version-No`; `304` không đổi; tiêu đề `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `410` Danh mục đã ngừng hiệu lực tại thời điểm tra (ERR-07-031); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Trả cây lồng từ `root` (bỏ trống: các nút gốc) xuống `depth` cấp (mặc định 1, tối đa 10). Mỗi nút có `childCount` để giao diện tải lười nhánh con. Giới hạn 5.000 nút mỗi phản hồi; vượt thì `truncated = true` và client gọi tiếp cho từng nhánh. Danh mục không phân cấp trả 422 ERR-07-011.
:::

#### API-07-045 · Tìm kiếm không dấu trong danh mục

::: dac-ta
**Mục đích.** Tìm kiếm không dấu trong danh mục.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/items:search`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-030.

**Tham số.** `q` (query, string, bắt buộc); `limit` (query, integer, tùy chọn); `at` (query, string, tùy chọn); `includeDeprecated` (query, boolean, tùy chọn); `level` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SearchResponse`; trường bắt buộc: `catalogCode`, `versionNo`, `items`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `429` Vượt giới hạn tần suất (ERR-07-044), do APISIX hoặc `dh-data` trả.

**Ghi chú.** Tìm theo mã (tiền tố) và tên (chứa, không phân biệt hoa thường và dấu: "da lat" ra "Đà Lạt", FR-00-020) cộng thuộc tính `searchable`. Xếp hạng: khớp mã chính xác, tiền tố mã, tiền tố tên, chứa trong tên, rồi theo độ tương tự trigram. `q` tối thiểu 2 ký tự.
:::

#### API-07-046 · Lấy thay đổi kể từ một phiên bản (delta)

::: dac-ta
**Mục đích.** Lấy thay đổi kể từ một phiên bản (delta).

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/changes`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-031.

**Tham số.** `sinceVersion` (query, integer, bắt buộc); `toVersion` (query, integer, tùy chọn); `includeUpcoming` (query, boolean, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `ChangesResponse`; trường bắt buộc: `catalogCode`, `fromVersion`, `toVersion`, `schemaChanged`, `changes`, `cursor`; tiêu đề `ETag`, `Cache-Control`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `429` Vượt giới hạn tần suất (ERR-07-044), do APISIX hoặc `dh-data` trả.

**Ghi chú.** Trả danh sách thay đổi cộng dồn từ phiên bản `sinceVersion` (không gồm) tới `toVersion` (mặc định phiên bản đã phát hành mới nhất, kể cả phiên bản sắp hiệu lực nếu `includeUpcoming = true`). Mỗi mã chỉ xuất hiện một lần với trạng thái cuối cùng. Nếu `sinceVersion` cũ hơn cửa sổ giữ delta (mặc định 20 phiên bản) hoặc giữa hai phiên bản có thay đổi lược đồ phá vỡ, trả `fullResyncRequired = true` và `changes` rỗng: client phải nạp lại từ ảnh chụp. Nếu `sinceVersion` đã là mới nhất, trả 200 với `changes` rỗng (không trả 304, để client luôn nhận `toVersionNo`).
:::

#### API-07-048 · Lược đồ danh mục và JSON Schema

::: dac-ta
**Mục đích.** Lược đồ danh mục và JSON Schema.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/schema`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-033.

**Tham số.** `version` (query, string, tùy chọn); `If-None-Match` (header, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SchemaMetadata`; trường bắt buộc: `catalog`, `version`, `attributes`, `jsonSchema`; tiêu đề `ETag`, `Cache-Control`; `304` không đổi; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Trả metadata danh mục, cấu hình phân cấp, danh sách thuộc tính và JSON Schema (draft 2020-12) mô tả một bản ghi của phiên bản yêu cầu, để HTTT sinh mã kiểm tra dữ liệu phía mình. `schemaHash` đổi khi và chỉ khi lược đồ đổi, nên client có thể so để biết có cần sinh lại mã hay không. Mặc định phiên bản hiện hành; `version` nhận số hoặc `current`.
:::

#### API-07-049 · Tải ảnh chụp phiên bản (chuyển hướng tới URL ký sẵn)

::: dac-ta
**Mục đích.** Tải ảnh chụp phiên bản (chuyển hướng tới URL ký sẵn).

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/snapshots/{versionRef}`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-028.

**Tham số.** `format` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `302`; tiêu đề `Location`, `ETag`, `Datahub-Snapshot-Sha256`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `503` Tài nguyên tạm chưa sẵn sàng (ảnh chụp đang sinh) hoặc phân hệ phụ thuộc không sẵn sàng (ERR-07-047).

**Ghi chú.** Trả 302 với `Location` là URL ký sẵn (hạn 15 phút) tới tệp ảnh chụp trên Garage. `versionRef = draft` không được hỗ trợ (ảnh chụp chỉ có với phiên bản đã phát hành). Nếu ảnh chụp đang được sinh (ngay sau phát hành), trả 503 kèm `Retry-After`. Tệp JSON nén gzip theo cấu trúc `ExportJsonDocument` (một dòng một bản ghi nếu `format=ndjson`).
:::

### Truy vấn

#### API-07-047 · Truy vấn có cấu trúc bằng DSL JSON

::: dac-ta
**Mục đích.** Truy vấn có cấu trúc bằng DSL JSON.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/items:query`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-032.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `QueryRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `QueryResponse`; trường bắt buộc: `items`, `catalogVersion`, `took`; tiêu đề `Datahub-Version-No`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `410` Danh mục đã ngừng hiệu lực tại thời điểm tra (ERR-07-031); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036); `429` Vượt giới hạn tần suất (ERR-07-044), do APISIX hoặc `dh-data` trả.

**Ghi chú.** Lọc theo biểu thức AND/OR lồng ≤ 3 cấp, ≤ 20 điều kiện, trên trường hệ thống và thuộc tính `queryable` (BR-07-018); chọn trường (`select`), sắp xếp (≤ 3 khóa), phân trang con trỏ. Máy chủ dịch sang SQL tham số hóa trên `attrs jsonb` với `statement_timeout = 2s` (ADR-054). Lỗi cú pháp trả 400 ERR-07-023, thuộc tính không cho truy vấn 400 ERR-07-025, vượt giới hạn 422 ERR-07-024. Ngữ pháp đầy đủ ở D03-04-PH07 §5.
:::

### Đơn vị hành chính

#### API-07-050 · Dòng lịch sử của một bản ghi

::: dac-ta
**Mục đích.** Dòng lịch sử của một bản ghi.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/items/{itemCode}/lineage`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-047.

**Tham số.** `depth` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Lineage`; trường bắt buộc: `catalogCode`, `code`, `segments`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Trả dòng thời gian các phiên bản mà mã xuất hiện (tên, mã cha, trạng thái, thuộc tính thay đổi) cùng đồ thị kế thừa từ `item_succession` và `replacedBy`: tiền thân (`predecessors`) và kế thừa (`successors`) đến độ sâu `depth`. Áp dụng cho mọi danh mục; với DVHC đây là nguồn cho màn dòng thời gian sắp xếp UI-07-11.
:::

#### API-07-051 · Chuyển mã ĐVHC cũ sang mới (lô ≤ 1.000)

::: dac-ta
**Mục đích.** Chuyển mã ĐVHC cũ sang mới (lô ≤ 1.000).

**Phương thức, đường dẫn.** `POST /admin-units:convert`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-046.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `AdminUnitConvertRequest`; trường bắt buộc: `codes`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AdminUnitConvertResponse`; trường bắt buộc: `results`, `stats`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `429` Vượt giới hạn tần suất (ERR-07-044), do APISIX hoặc `dh-data` trả.

**Ghi chú.** Với mỗi mã đầu vào (có thể kèm ngày của hồ sơ `asOf`), xác định đơn vị tại ngày đó rồi đi theo chuỗi sự kiện sắp xếp (`item_succession`) tới `targetDate` (mặc định hôm nay). Kết quả: `EXACT` (đúng một đơn vị đích), `UNCHANGED` (đơn vị không bị sắp xếp), `AMBIGUOUS` (đơn vị bị chia về nhiều đơn vị, trả `candidates` và không tự chọn — BR-07-022), `NOT_FOUND` (mã không tồn tại tại `asOf`). `direction = NEW_TO_OLD` tra ngược: từ mã mới trả các mã tiền thân tại `targetDate` trong quá khứ. Chuyển mã tệp (FR-07-046) do UI-07-11 đọc tệp phía trình duyệt và gọi API này theo lô 1.000.
:::

#### API-07-052 · Sự kiện sắp xếp ghi nhận trong phiên bản

::: dac-ta
**Mục đích.** Sự kiện sắp xếp ghi nhận trong phiên bản.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/versions/{versionRef}/successions`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-045.

**Tham số.** `eventType` (query, SuccessionEventType, tùy chọn); `code` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SuccessionPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Không.
:::

#### API-07-053 · Ghi sự kiện sắp xếp vào bản nháp

::: dac-ta
**Mục đích.** Ghi sự kiện sắp xếp vào bản nháp.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/versions/{versionRef}/successions`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-045.

**Tham số.** `If-Match` (header, string, bắt buộc); `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `SuccessionCreateRequest`; trường bắt buộc: `eventType`, `effectiveDate`, `legalBasis`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Succession`; tiêu đề `Location`, `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Ghi một sự kiện `MERGE`, `SPLIT`, `RENAME`, `ABOLISH`, `ESTABLISH`, `RECODE`. Kiểm tra: `fromCodes` tồn tại trong phiên bản hiện hành, `toCodes` tồn tại trong bản nháp, số phần tử phù hợp loại sự kiện (MERGE n→1, SPLIT 1→n, RENAME/RECODE 1→1, ABOLISH n→0, ESTABLISH 0→n), có `legalBasis`, `effectiveDate` bằng `effectiveFrom` của bản nháp hoặc nằm trong khoảng của nó (BR-07-021, ERR-07-035). Tùy chọn `applyToItems = true` tự ngừng dùng mã nguồn và điền `replacedBy`.
:::

#### API-07-054 · Xóa sự kiện sắp xếp trong bản nháp

::: dac-ta
**Mục đích.** Xóa sự kiện sắp xếp trong bản nháp.

**Phương thức, đường dẫn.** `DELETE /catalogs/{catalogCode}/versions/{versionRef}/successions/{successionId}`.

**Quyền.** `PERM-07-update`.

**FR hiện thực.** FR-07-045.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018).

**Ghi chú.** Chỉ với phiên bản DRAFT. Không tự khôi phục trạng thái bản ghi đã bị ngừng dùng bởi `applyToItems`.
:::

### Đồng bộ quốc gia

#### API-07-055 · Danh sách nguồn đồng bộ

::: dac-ta
**Mục đích.** Danh sách nguồn đồng bộ.

**Phương thức, đường dẫn.** `GET /sync-sources`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-035.

**Tham số.** `catalogCode` (query, TCode, tùy chọn); `enabled` (query, boolean, tùy chọn); `lastRunStatus` (query, SyncRunStatus, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncSourcePage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030).

**Ghi chú.** Không.
:::

#### API-07-056 · Tạo nguồn đồng bộ (đăng ký đồng bộ danh mục quốc gia)

::: dac-ta
**Mục đích.** Tạo nguồn đồng bộ (đăng ký đồng bộ danh mục quốc gia).

**Phương thức, đường dẫn.** `POST /sync-sources`.

**Quyền.** `PERM-07-sync`.

**FR hiện thực.** FR-07-035, FR-07-038.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `SyncSourceCreateRequest`; trường bắt buộc: `catalogCode`, `remoteCode`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `SyncSource`; tiêu đề `Location`, `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036); `502` Nguồn quốc gia NDXP (qua PH-14) không phản hồi hoặc trả lỗi (ERR-07-028).

**Ghi chú.** Gắn một danh mục với danh mục từ xa trên NDXP (qua PH-14). Hoặc chỉ định `catalogCode` có sẵn (sẽ chuyển `sourceType` thành NATIONAL nếu đang LOCAL và chưa phát hành), hoặc truyền `createCatalog` để tạo danh mục NATIONAL mới với lược đồ suy ra từ metadata từ xa. Danh mục COMMON chỉ PLATFORM_ADMIN đăng ký. `runNow = true` kích hoạt lần chạy đầu ngay.
:::

#### API-07-057 · Sửa nguồn đồng bộ

::: dac-ta
**Mục đích.** Sửa nguồn đồng bộ.

**Phương thức, đường dẫn.** `PATCH /sync-sources/{sourceId}`.

**Quyền.** `PERM-07-sync`.

**FR hiện thực.** FR-07-035.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/merge-patch+json: `SyncSourceUpdateRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncSource`; tiêu đề `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018).

**Ghi chú.** Sửa lịch (`scheduleCron`, biểu thức cron 6 trường của Spring, giờ Việt Nam), `autoApply`, `enabled`, `fieldMapping`.
:::

#### API-07-058 · Chạy đồng bộ ngay

::: dac-ta
**Mục đích.** Chạy đồng bộ ngay.

**Phương thức, đường dẫn.** `POST /sync-sources/{sourceId}:run`.

**Quyền.** `PERM-07-sync`.

**FR hiện thực.** FR-07-036.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `SyncRunRequest`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `202` đã nhận, xử lý bất đồng bộ, `SyncRun`; trường bắt buộc: `id`, `sourceId`, `catalogCode`, `status`, `trigger`, `startedAt`; tiêu đề `Location`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037).

**Ghi chú.** Tạo `sync_run` với `trigger = MANUAL`, trả 202 kèm `Location` tới lần chạy. Nếu nguồn đang có lần chạy `RUNNING` hoặc `PENDING_CONFIRMATION` thì trả 409 ERR-07-029 kèm id lần chạy đó (khóa bằng advisory lock theo `sourceId`). Kết quả cuối phát EVT-07-09.
:::

#### API-07-059 · Lịch sử lần chạy đồng bộ

::: dac-ta
**Mục đích.** Lịch sử lần chạy đồng bộ.

**Phương thức, đường dẫn.** `GET /sync-runs`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-036.

**Tham số.** `sourceId` (query, string, tùy chọn); `catalogCode` (query, TCode, tùy chọn); `status` (query, array, tùy chọn); `startedFrom` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncRunPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030).

**Ghi chú.** Không.
:::

#### API-07-060 · Chi tiết lần chạy và danh sách thay đổi

::: dac-ta
**Mục đích.** Chi tiết lần chạy và danh sách thay đổi.

**Phương thức, đường dẫn.** `GET /sync-runs/{runId}`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-036, FR-07-037.

**Tham số.** `changeType` (query, SyncChangeType, tùy chọn); `breaking` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncRunDetail`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Kèm trang thay đổi (`sync_change`) lọc được theo `changeType`, `breaking`.
:::

#### API-07-061 · Xác nhận áp dụng thay đổi phá vỡ

::: dac-ta
**Mục đích.** Xác nhận áp dụng thay đổi phá vỡ.

**Phương thức, đường dẫn.** `POST /sync-runs/{runId}:accept`.

**Quyền.** `PERM-07-sync`.

**FR hiện thực.** FR-07-037.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `SyncRunAcceptRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncRun`; trường bắt buộc: `id`, `sourceId`, `catalogCode`, `status`, `trigger`, `startedAt`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Chỉ khi `PENDING_CONFIRMATION`. Tạo phiên bản (`origin = SYNC`) từ dữ liệu đã tải, gồm cả thay đổi phá vỡ, rồi đi theo chính sách duyệt của danh mục: nếu `requireApproval = true` phiên bản ở `IN_REVIEW` chờ người có PERM-07-publish; ngược lại phát hành ngay (người xác nhận cần PERM-07-publish). Cho phép `effectiveFrom` hồi tố theo ngày hiệu lực ở nguồn (BR-07-027). Trạng thái lần chạy chuyển `APPLIED`.
:::

#### API-07-062 · Từ chối thay đổi từ nguồn quốc gia

::: dac-ta
**Mục đích.** Từ chối thay đổi từ nguồn quốc gia.

**Phương thức, đường dẫn.** `POST /sync-runs/{runId}:reject`.

**Quyền.** `PERM-07-sync`.

**FR hiện thực.** FR-07-037.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `RejectRequest`; trường bắt buộc: `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `SyncRun`; trường bắt buộc: `id`, `sourceId`, `catalogCode`, `status`, `trigger`, `startedAt`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018).

**Ghi chú.** Chuyển `PENDING_CONFIRMATION` → `REJECTED`, bắt buộc lý do. Lần chạy kế tiếp vẫn tính khác biệt so với phiên bản cục bộ nên thay đổi bị từ chối sẽ xuất hiện lại nếu nguồn chưa đổi.
:::

#### API-07-063 · Khám phá danh mục quốc gia trên NDXP

::: dac-ta
**Mục đích.** Khám phá danh mục quốc gia trên NDXP.

**Phương thức, đường dẫn.** `GET /national-catalogs`.

**Quyền.** `PERM-07-sync`.

**FR hiện thực.** FR-07-038.

**Tham số.** `q` (query, string, tùy chọn); `withAttributes` (query, boolean, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `NationalCatalogPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `502` Nguồn quốc gia NDXP (qua PH-14) không phản hồi hoặc trả lỗi (ERR-07-028).

**Ghi chú.** Gọi PH-14 (adapter NDXP DMDC) lấy danh sách danh mục quốc gia, đánh dấu danh mục nào đã được tenant (hoặc COMMON) đăng ký đồng bộ. Kết quả được đệm 1 giờ ở L2. NDXP không phản hồi trả 502 ERR-07-028; khi có bộ đệm cũ thì trả bộ đệm cũ với `stale = true`.
:::

#### API-07-074 · Đề xuất bổ sung bản ghi lên danh mục quốc gia

::: dac-ta
**Mục đích.** Đề xuất bổ sung bản ghi lên danh mục quốc gia.

**Phương thức, đường dẫn.** `POST /catalogs/{catalogCode}/proposals`.

**Quyền.** `PERM-07-sync`.

**FR hiện thực.** FR-07-039.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `ProposalCreateRequest`; trường bắt buộc: `itemCodes`, `justification`, `contact`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `Proposal`; trường bắt buộc: `proposalId`, `status`, `itemCodes`; tiêu đề `Location`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036); `502` Nguồn quốc gia NDXP (qua PH-14) không phản hồi hoặc trả lỗi (ERR-07-028).

**Ghi chú.** Chỉ với danh mục NATIONAL hoặc HYBRID mở rộng danh mục quốc gia. Gửi đề xuất qua PH-14 tới NDXP (dịch vụ "đề xuất bổ sung danh mục"); lưu đề xuất và mã tham chiếu phía quốc gia. Nếu NDXP chưa hỗ trợ trả 502 ERR-07-028 và đề xuất được lưu `status = FAILED` để gửi lại.
:::

### Ánh xạ mã

#### API-07-064 · Danh sách hệ thống mã ngoài

::: dac-ta
**Mục đích.** Danh sách hệ thống mã ngoài.

**Phương thức, đường dẫn.** `GET /code-systems`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-040.

**Tham số.** `q` (query, string, tùy chọn); `status` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CodeSystemPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030).

**Ghi chú.** Không.
:::

#### API-07-065 · Tạo hệ thống mã ngoài

::: dac-ta
**Mục đích.** Tạo hệ thống mã ngoài.

**Phương thức, đường dẫn.** `POST /code-systems`.

**Quyền.** `PERM-07-mapping`.

**FR hiện thực.** FR-07-040.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `CodeSystemCreateRequest`; trường bắt buộc: `code`, `name`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `201` đã tạo, `CodeSystem`; tiêu đề `Location`, `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037).

**Ghi chú.** Khai báo một hệ thống mã (thường gắn với một HTTT thành viên ở PH-01 qua `memberSystemId`, kiểm tra tồn tại qua API module của PH-01).
:::

#### API-07-066 · Sửa hệ thống mã ngoài

::: dac-ta
**Mục đích.** Sửa hệ thống mã ngoài.

**Phương thức, đường dẫn.** `PATCH /code-systems/{csCode}`.

**Quyền.** `PERM-07-mapping`.

**FR hiện thực.** FR-07-040.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/merge-patch+json: `CodeSystemUpdateRequest`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CodeSystem`; tiêu đề `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018).

**Ghi chú.** Không.
:::

#### API-07-067 · Bảng ánh xạ mã của danh mục

::: dac-ta
**Mục đích.** Bảng ánh xạ mã của danh mục.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/mappings`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-041.

**Tham số.** `codeSystem` (query, TCode, tùy chọn); `itemCode` (query, string, tùy chọn); `externalCode` (query, string, tùy chọn); `provisional` (query, boolean, tùy chọn); `at` (query, string, tùy chọn); `page` (query, integer, tùy chọn); `size` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `CodeMappingPage`; trường bắt buộc: `items`, `page`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Không.
:::

#### API-07-068 · Ghi lô ánh xạ (upsert)

::: dac-ta
**Mục đích.** Ghi lô ánh xạ (upsert).

**Phương thức, đường dẫn.** `PUT /catalogs/{catalogCode}/mappings/{csCode}`.

**Quyền.** `PERM-07-mapping`.

**FR hiện thực.** FR-07-041.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `MappingBatchPut`; trường bắt buộc: `mappings`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `MappingBatchResult`; trường bắt buộc: `results`, `stats`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Ghi tối đa 5.000 ánh xạ giữa danh mục và một hệ thống mã trong một giao dịch. Khóa upsert là (`externalCode`, `validFrom`). `mode = MERGE` (mặc định) chỉ thêm/sửa; `mode = REPLACE_ALL` đặt `validTo = hôm nay` cho ánh xạ đang hiệu lực không có trong lô. Kiểm tra: `itemCode` tồn tại trong phiên bản hiện hành (hoặc bất kỳ phiên bản nếu `allowHistoricalItems = true`), mỗi mã ngoài trỏ đúng một mã danh mục trong cùng khoảng hiệu lực (BR-07-023, ERR-07-033), ánh xạ tạm thời có lý do (BR-07-024, ERR-07-034). PUT là idempotent tự nhiên nên không cần `Idempotency-Key`.
:::

#### API-07-069 · Xóa ánh xạ

::: dac-ta
**Mục đích.** Xóa ánh xạ.

**Phương thức, đường dẫn.** `DELETE /catalogs/{catalogCode}/mappings/{csCode}/{mappingId}`.

**Quyền.** `PERM-07-mapping`.

**FR hiện thực.** FR-07-041.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `204` không có nội dung.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018).

**Ghi chú.** Xóa mềm một ánh xạ (giữ kiểm toán). Muốn ngừng ánh xạ từ một ngày thì dùng PUT với `validTo` thay vì xóa.
:::

#### API-07-070 · Chuyển mã qua bảng ánh xạ (lô ≤ 500)

::: dac-ta
**Mục đích.** Chuyển mã qua bảng ánh xạ (lô ≤ 500).

**Phương thức, đường dẫn.** `POST /mappings:translate`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-042.

**Tham số.** Không.

**Thân yêu cầu.** application/json: `TranslateRequest`; trường bắt buộc: `catalog`, `codeSystem`, `direction`, `codes`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `TranslateResponse`; trường bắt buộc: `results`, `stats`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `429` Vượt giới hạn tần suất (ERR-07-044), do APISIX hoặc `dh-data` trả.

**Ghi chú.** Chuyển mã giữa danh mục và hệ thống mã ngoài, hoặc giữa hai hệ thống mã ngoài thông qua mã danh mục làm trung gian (`from` và `to` đều là hệ thống mã). Kết quả từng mã: `MAPPED` (đúng một kết quả), `MULTIPLE` (một mã danh mục có nhiều mã ngoài — trả mọi kết quả, client chọn), `NOT_MAPPED`. Ánh xạ tạm thời chỉ dùng khi `includeProvisional = true` và được đánh dấu trong kết quả. Thao tác chỉ đọc nên không cần `Idempotency-Key`.
:::

#### API-07-071 · Độ phủ ánh xạ

::: dac-ta
**Mục đích.** Độ phủ ánh xạ.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/mappings/{csCode}/coverage`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-043.

**Tham số.** `at` (query, string, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `Coverage`; trường bắt buộc: `catalogCode`, `codeSystem`, `at`, `totalActiveItems`, `mappedItems`, `provisionalItems`, `coverageRatio`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Tỷ lệ bản ghi ACTIVE của phiên bản hiệu lực có ít nhất một ánh xạ chính thức (không tạm thời), chia theo cấp; kèm mẫu tối đa 100 mã chưa ánh xạ. Cũng xuất ra chỉ số `rdm_mapping_coverage_ratio`.
:::

### Kiểm toán và quyền khai thác

#### API-07-072 · Lịch sử kiểm toán của danh mục

::: dac-ta
**Mục đích.** Lịch sử kiểm toán của danh mục.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/history`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-050.

**Tham số.** `action` (query, string, tùy chọn); `actor` (query, string, tùy chọn); `from` (query, string, tùy chọn); `to` (query, string, tùy chọn); `cursor` (query, string, tùy chọn); `limit` (query, integer, tùy chọn).

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `HistoryCursorPage`; trường bắt buộc: `items`, `cursor`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `503` Tài nguyên tạm chưa sẵn sàng (ảnh chụp đang sinh) hoặc phân hệ phụ thuộc không sẵn sàng (ERR-07-047).

**Ghi chú.** Đọc nhật ký kiểm toán từ PH-13 (qua API của PH-13, không đọc chéo CSDL) lọc theo đối tượng danh mục và các đối tượng con (phiên bản, thuộc tính, bản ghi, ánh xạ). Giá trị trước/sau đã được che theo phân loại. PH-13 không sẵn sàng trả 503 ERR-07-047.
:::

#### API-07-075 · Danh sách HTTT được cấp quyền khai thác

::: dac-ta
**Mục đích.** Danh sách HTTT được cấp quyền khai thác.

**Phương thức, đường dẫn.** `GET /catalogs/{catalogCode}/access-grants`.

**Quyền.** `PERM-07-read`.

**FR hiện thực.** FR-07-052.

**Tham số.** Không.

**Thân yêu cầu.** Không.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AccessGrantList`; trường bắt buộc: `catalogCode`, `grants`; tiêu đề `ETag`.

**Lỗi.** `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011).

**Ghi chú.** Áp dụng cho danh mục `RESTRICTED` (bắt buộc để HTTT khai thác) và cho danh mục bất kỳ khi cần cấp scope `rdm.write` cho HTTT làm nguồn cập nhật.
:::

#### API-07-075 · Thay toàn bộ danh sách cấp quyền khai thác

::: dac-ta
**Mục đích.** Thay toàn bộ danh sách cấp quyền khai thác.

**Phương thức, đường dẫn.** `PUT /catalogs/{catalogCode}/access-grants`.

**Quyền.** `PERM-07-grant`.

**FR hiện thực.** FR-07-052.

**Tham số.** `If-Match` (header, string, bắt buộc).

**Thân yêu cầu.** application/json: `AccessGrantPut`; trường bắt buộc: `grants`, `reason`.

**Chống trùng.** Không.

**Phản hồi thành công.** `200` thành công, `AccessGrantList`; trường bắt buộc: `catalogCode`, `grants`; tiêu đề `ETag`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `412` ETag không khớp, đối tượng đã bị người khác sửa (ERR-07-018); `422` Dữ liệu đúng cú pháp nhưng vi phạm quy tắc nghiệp vụ (ERR-07-009…012, 014, 017, 019, 021, 024, 034, 035, 036).

**Ghi chú.** Thay thế toàn bộ danh sách (PUT, cần `If-Match` theo ETag danh sách). HTTT bị gỡ mất quyền ngay ở lượt gọi kế tiếp (bộ đệm quyết định quyền ≤ 60 giây). Mỗi thay đổi ghi kiểm toán.
:::

### Nền tảng

#### API-07-073 · Nạp gói danh mục nền cho tenant mới

::: dac-ta
**Mục đích.** Nạp gói danh mục nền cho tenant mới.

**Phương thức, đường dẫn.** `POST /tenants/{tenantId}:seed`.

**Quyền.** PLATFORM.

**FR hiện thực.** FR-07-049.

**Tham số.** `Idempotency-Key` (header, string, tùy chọn).

**Thân yêu cầu.** application/json: `SeedRequest`; trường bắt buộc: `packageVersion`.

**Chống trùng.** Có, tiêu đề `Idempotency-Key`.

**Phản hồi thành công.** `200` thành công, `SeedResult`; trường bắt buộc: `packageVersion`, `status`, `catalogs`; tiêu đề `Idempotent-Replayed`; `202` đã nhận, xử lý bất đồng bộ; tiêu đề `Location`.

**Lỗi.** `400` Yêu cầu sai cú pháp hoặc vi phạm giới hạn đầu vào (ERR-07-023, 025, 026, 040); `401` Thiếu token hoặc token không hợp lệ, hết hạn (ERR-07-041); `403` Không đủ quyền (ERR-07-046), danh mục chỉ đọc (ERR-07-003), tự duyệt (ERR-07-015), HTTT chưa được cấp quyền danh mục hạn chế (ERR-07-030); `404` Không tìm thấy danh mục (ERR-07-001), phiên bản (ERR-07-006), mã bản ghi tại thời điểm (ERR-07-007), ánh xạ (ERR-07-027) hoặc tài nguyên khác (ERR-07-045). Đối tượng của tenant khác luôn trả 404 để không lộ sự tồn tại (FR-00-011); `409` Xung đột trạng thái (ERR-07-002, 004, 005, 008, 013, 016, 020, 022, 029, 032, 033, 037).

**Ghi chú.** Đường dẫn đầy đủ `POST /api/platform/rdm/v1/tenants/{tenantId}:seed`. PH-20 gọi trong saga khởi tạo tenant (D03-10 §5). Gói nền gồm nhóm danh mục chuẩn và danh mục LOCAL mẫu (rỗng hoặc có dữ liệu mẫu), danh mục HYBRID mở rộng ĐVHC cho tỉnh; danh mục COMMON không sao chép mà chỉ liên kết. Idempotent theo (`tenantId`, `packageVersion`): gọi lại trả kết quả cũ và danh mục đã tồn tại được `SKIPPED_EXISTS`. Thao tác bù trừ của saga là `dryRun = false, rollback = true` (xóa mềm danh mục do lần nạp tạo khi còn DRAFT).
:::

<!-- gen:dac-ta-api:end -->

## Lịch sử phiên bản

| Phiên bản | Ngày | Nội dung |
|---|---|---|
| 0.1 | 2026-11-25 | Bản đầu: quy ước, xác thực, danh mục 76 endpoint, sự kiện, mã lỗi |
| 0.2 | 2026-11-26 | Nâng theo chuẩn kết hợp: thêm Giới thiệu, chương 9 đặc tả từng endpoint 10 mục sinh từ OpenAPI, chú thích bảng |

: Lịch sử phiên bản
