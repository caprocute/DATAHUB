# PH-07 · Danh mục dùng chung (RDM) · Tóm tắt cho tác nhân viết mã

> Gói đặc tả máy đọc theo khuôn K-GOI-DAC-TA. Bản ≤ 300 dòng này THAY cho việc đọc FRS
> (470 KB), SDD (230 KB), API (160 KB). Chỉ mở tài liệu nguồn ở đúng mục được trỏ
> (đường dẫn trong `goi.yaml`, mục `nguon`). Nguồn thắng tóm tắt khi khác nhau, TRỪ các
> quyết định SS-07-nn ở `san-sang.md` (thắng cả nguồn cho tới đợt đồng bộ cuối).

## 1. Vị trí

| Mục | Giá trị |
|---|---|
| Đơn vị triển khai (DU) | `dh-data` (Spring Boot 4, Java 21, Spring Modulith) — mã ở `datahub/services/dh-data` |
| Module | `rdm`, package `vn.datahub.data.rdm.{api,events,internal}` (Q350, D04-01 CC-MOD-01) |
| Schema | `ph07_rdm` (PostgreSQL 18, RLS mọi bảng có `tenant_id`) |
| Tiền tố REST | `/api/rdm/v1` (quản trị và khai thác); `/api/platform/rdm/v1` (liên tenant, chỉ PH-20) |
| Giao diện | `dh-console`, tính năng `features/rdm`, route gốc `/du-lieu/danh-muc` |
| Sự kiện | outbox `ph07_rdm.outbox` → Debezium → Kafka, kiểu `vn.datahub.rdm.{thực thể}.{động từ}.v{n}`, topic `{tenant thường}.rdm.{thực thể}.{động từ}.v{n}` |

## 2. Khái niệm

- **Nhóm danh mục** (`catalog_group`, EN-07-01): cây phân loại, độ sâu ≤ 5. Nhóm `COMMON` dùng chung mọi tỉnh; tỉnh thêm nhóm riêng. Nhóm con cùng tenant với nhóm cha (khóa ngoại `(parent_id, tenant_id)`).
- **Danh mục** (`catalog`, EN-07-02): mã T-CODE duy nhất trong tenant; nguồn `LOCAL` / `NATIONAL` / `COMMON` / `HYBRID`; trạng thái `DRAFT → ACTIVE → RETIRED`; xóa mềm (`deleted_at`) khi còn `DRAFT`.
- **Phiên bản** (`catalog_version`, EN-07-03): `DRAFT → IN_REVIEW → APPROVED → PUBLISHED`, `DRAFT → DISCARDED`; tối đa một phiên bản mở mỗi danh mục (BR-07-005); `PUBLISHED` bất biến (BR-07-006); hiệu lực `[effective_from, effective_to)` không chồng (BR-07-007).
- **Thuộc tính động** (`attribute_def`, EN-07-04): lược đồ theo phiên bản; giá trị ở `catalog_item.attrs` (jsonb).
- **Bản ghi** (`catalog_item`, EN-07-05): copy-on-write theo phiên bản; `ACTIVE` / `DEPRECATED` (+ `replaced_by`); mã chữ hoa, không đổi, không xóa khi đã phát hành (BR-07-002, 003, 040).
- Còn lại: tác vụ nhập xuất (`import_job`, `import_row`, `file_object`), đồng bộ quốc gia (`sync_source/run/change`), hệ thống mã ngoài và ánh xạ (`code_system`, `code_mapping`), ĐVHC (`admin_unit`, `item_succession`), cấp quyền khai thác (`catalog_access_grant`), `idempotency_key`, `outbox`, `shedlock`.

## 3. Đa tenant (D03-10, ADR-003)

1. Token do realm `dh-{tenant thường}` cấp, claim `tenant` = `T68` hoặc `PLATFORM`. APISIX đối chiếu rồi chuyển header `X-DH-Tenant`; `dh-data` vẫn đọc từ JWT đã xác minh (không tin header khi chạy không qua APISIX).
2. Đầu MỖI giao dịch: `select set_config('app.tenant_id', :tenant, true)` (tương đương `SET LOCAL`). Ứng dụng kết nối bằng vai trò đăng nhập thành viên `ph07_app` (không BYPASSRLS, không phải chủ bảng).
3. Mẫu RLS S (bảng dùng chung): SELECT thấy `tenant_id IN (hiện tại, 'COMMON')`; ghi chỉ dòng của tenant `T\d\d` hiện tại, hoặc `COMMON` khi tenant hiện tại là `PLATFORM`. Mẫu P: chỉ tenant hiện tại.
4. Tenant `PLATFORM` ghi vào dòng `tenant_id = 'COMMON'`. Tenant tỉnh ghi dòng có `tenant_id` = mã tỉnh.
5. Đối tượng tenant khác: luôn 404 (không lộ tồn tại, FR-00-011). Đối tượng `COMMON` mà tenant tỉnh muốn sửa: 403 ERR-07-003.
6. Kết nối trong pool đã từng đặt biến mà quên đặt lại thì `app.tenant_id = ''` và chỉ thấy `COMMON` (SS-07-07): không dựa vào lỗi CSDL để phát hiện quên tenant; phải có kiểm thử rò rỉ.

## 4. Quy ước API chung (D03-04-PH07 §2, D04-01 §3.5–3.7)

| Chủ đề | Quy ước |
|---|---|
| Lỗi | RFC 9457 `application/problem+json`: `type`, `title`, `status`, `code` (`ERR-07-nnn`), `detail`, `traceId` (32 hex), `instance`, `timestamp`, `errors[]` (`field`, `code`, `message`). `title`/`detail` tiếng Việt. `type` = `https://datahub.gov.vn/problems/rdm/{slug}` |
| Tạo | `POST`, trả `201` + `Location` + `ETag`; nhận `Idempotency-Key` (16–128 ký tự `[A-Za-z0-9_-]`), lưu 24 giờ ở `idempotency_key` theo (tenant, principal, `API-07-nnn`, key) với SHA-256 thân; gửi lại cùng thân trả phản hồi đã lưu + `Idempotent-Replayed: true`; khác thân 409 ERR-07-022 |
| Sửa | `PATCH` (`application/merge-patch+json` hoặc `application/json`), bắt buộc `If-Match`; ETag `W/"{version}"`; thiếu 400 ERR-07-040; lệch 412 ERR-07-018 |
| Xóa | `DELETE` bắt buộc `If-Match`, trả `204` |
| Hành động | hậu tố `:{hành-động}` (`/catalogs/{code}:retire`) |
| Phân trang | quản trị: `page` (từ 0), `size` ≤ 200; khai thác: `cursor`, `limit` ≤ 1000 |
| Trace | nhận `traceparent` W3C; thiếu thì sinh; `traceId` của lỗi và outbox lấy từ đây |
| Chuỗi vào | `name` chuẩn hóa NFC; mã T-CODE chuẩn hóa chữ hoa rồi mới kiểm `^[A-Z0-9][A-Z0-9_.-]{0,63}$` |
| Trường lạ | thân có trường không khai trong lược đồ → 422 ERR-07-009 (chống gán hàng loạt, CC-SEC-21) |
| Kiểm toán | mọi lệnh ghi thành công ghi MỘT dòng outbox kiểm toán trong cùng giao dịch (SS-07-08) |

## 5. Quyền (D02-08, FRS §3.2)

| Quyền | PA (tenant PLATFORM, ghi COMMON) | TA | DS | DA | IE, VW, AU |
|---|---|---|---|---|---|
| `PERM-07-read` | ● | ● | ● | ● | ● |
| `PERM-07-create`, `PERM-07-update` | ● | ● | ○ tổ chức mình | — | — |
| `PERM-07-submit` | ● | ● | ○ | — | — |
| `PERM-07-publish` | ● | — | — | ● | — |
| `PERM-07-export` | ● | ● | ● | ● | ● |
| `PERM-07-sync` | ● | ● | — | ● | — |

Nhóm danh mục: DS không quản lý nhóm (FR-07-010) dù có `PERM-07-create`; chỉ TA, PA. Lát cắt mẫu đọc quyền từ claim `perms` (mảng chuỗi `PERM-*`) của JWT; nguồn quyền thật (Keycloak + OPA, ADR-006) nối ở lát cắt sau. Thiếu quyền: 403 ERR-07-046. Không token hoặc token hỏng: 401 ERR-07-041.

## 6. Mã lỗi hay dùng (bảng đầy đủ: D03-04-PH07 §6)

| Mã | HTTP | Nghĩa |
|---|---|---|
| ERR-07-001 | 404 | Không thấy danh mục (hoặc thuộc tenant khác) |
| ERR-07-002 | 409 | Mã đã dùng (danh mục, hệ thống mã, nguồn) |
| ERR-07-003 | 403 | Đối tượng chỉ đọc với chủ thể (NATIONAL; COMMON với tenant tỉnh) |
| ERR-07-004 | 409 | Trạng thái không cho phép thao tác |
| ERR-07-005 | 409 | Đã có phiên bản mở |
| ERR-07-009 | 422 | Dữ liệu không hợp lệ theo lược đồ/ràng buộc, kèm `errors[]` |
| ERR-07-018 | 412 | ETag không khớp |
| ERR-07-022 | 409 | `Idempotency-Key` đã dùng với nội dung khác |
| ERR-07-037 | 409 | Nhóm còn danh mục hoặc nhóm con |
| ERR-07-039 | 409 | Mã nhóm trùng, nhóm cha tạo vòng, vượt độ sâu 5 |
| ERR-07-040 | 400 | Thiếu `If-Match` |
| ERR-07-041 | 401 | Thiếu hoặc sai token |
| ERR-07-042 | 413 | Thân quá lớn |
| ERR-07-043 | 415 | Kiểu nội dung không hỗ trợ |
| ERR-07-045 | 404 | Không thấy tài nguyên khác (nhóm, tác vụ, nguồn…) |
| ERR-07-046 | 403 | Không đủ quyền |
| ERR-07-047 | 503 | Phụ thuộc chưa sẵn sàng |

Câu hiển thị cho người dùng theo mã: D03-06-PH07 §5.3 (khóa i18n `rdm.err.{nnn}`).

## 7. Sự kiện EVT-07 (asyncapi-rdm.yaml)

| Mã | Sự kiện |
|---|---|
| EVT-07-01 | Danh mục được tạo |
| EVT-07-02 | Thông tin danh mục thay đổi |
| EVT-07-03 | Danh mục ngừng hiệu lực |
| EVT-07-04 | Bản nháp được trình duyệt |
| EVT-07-05 | Phiên bản được phát hành |
| EVT-07-06 | Bản nháp bị từ chối, rút lại hoặc thu hồi |
| EVT-07-07 | Tác vụ nhập kết thúc |
| EVT-07-08 | Tác vụ xuất kết thúc |
| EVT-07-09 | Lần đồng bộ quốc gia kết thúc (trừ NO_CHANGE) |
| EVT-07-10 | Danh mục ĐVHC phát hành kèm sự kiện sắp xếp |

Nhóm danh mục (F-07-010) không phát sự kiện nghiệp vụ, chỉ kiểm toán.

## 8. Quy tắc nghiệp vụ chính (FRS §7, đủ 29 quy tắc ở nguồn)

| Mã | Tóm tắt |
|---|---|
| BR-07-001 | Mã danh mục duy nhất trong tenant, không trùng mã COMMON đang DRAFT/ACTIVE |
| BR-07-002 | Mã bản ghi duy nhất trong phiên bản, không phân biệt hoa thường, lưu chữ hoa |
| BR-07-003 | Bản ghi đã phát hành không xóa, chỉ DEPRECATED |
| BR-07-005 | Tối đa một phiên bản mở mỗi danh mục |
| BR-07-006 | PUBLISHED bất biến |
| BR-07-009 | NATIONAL chỉ qua đồng bộ; COMMON chỉ PLATFORM ghi |
| BR-07-011 | Bốn mắt: người duyệt khác người trình và người sửa |
| BR-07-014 | Phân cấp: cha tồn tại, không vòng, độ sâu ≤ `max_depth` |
| BR-07-018 | Truy vấn có cấu trúc không bao giờ chạy SQL của client |
| BR-07-019 | RESTRICTED chỉ HTTT được cấp quyền mới khai thác |
| BR-07-025 | Danh mục không chứa dữ liệu cá nhân |
| BR-07-040 | Mã danh mục không đổi sau phát hành; mã bản ghi không tái dùng |

## 9. Bản đồ tính năng

`features.json` liệt kê 53 tính năng F-07-001…053 (một FR một tính năng), mỗi tính năng kèm API (operationId), bảng, màn hình, mã lỗi, TC và cờ `passes`. Tính năng có `lat_cat` đã có lát cắt OpenAPI và Gherkin chạy được; tính năng chưa có thì phiên khởi tạo phải cắt lát trước (K-GOI-DAC-TA §6).

| Nhóm | FR | Ghi chú |
|---|---|---|
| A Danh mục, lược đồ | 001–010 | 010 = nhóm danh mục (lát cắt mẫu) |
| B Phiên bản, bản ghi | 011–019 | máy trạng thái phiên bản |
| C Nhập xuất | 020–025 | tác vụ nền, Garage |
| D Khai thác | 026–034 | bộ đệm hai tầng, ETag |
| E Đồng bộ quốc gia | 035–039 | qua PH-14 |
| F Mã ngoài, ánh xạ | 040–043 | |
| G ĐVHC | 044–047 | |
| H Tenant, nền tảng | 048–053 | 053 chuyển tham số sang PH-18 |

## 10. Khi cần chi tiết

| Cần | Mở |
|---|---|
| Luồng, ngoại lệ của một FR | FRS, tìm `#### FR-07-nnn` |
| Lớp, thuật toán | SDD §4.x (bảng §4 "thành phần") |
| Cột, ràng buộc, RLS | `ph07_rdm.sql`, tìm `CREATE TABLE ph07_rdm.{bảng}` |
| Màn hình | D03-06-PH07 §7–§19 theo UI-07-nn; ảnh `hifi/ui-07-nn.png` |
| TC | D05-02-PH07, tìm `#### TC-07-nnn` |
