---
ma_tai_lieu: D02-07
ten: Từ điển dữ liệu dùng chung
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Dự thảo
nguoi_doc: Phân tích nghiệp vụ, Kiến trúc sư, Đội phát triển, Kiểm thử
---

# D02-07 · Từ điển dữ liệu dùng chung

## 1. Mục đích

Một số thực thể được nhiều phân hệ sử dụng: tenant, tổ chức, HTTT thành viên, người dùng, đơn vị hành chính, tệp đính kèm, bản ghi kiểm toán. Nếu mỗi phân hệ tự định nghĩa, các định nghĩa sẽ lệch nhau và dữ liệu không ghép được. Tài liệu này định nghĩa **một lần duy nhất** các thực thể dùng chung (`DD-nn`): ý nghĩa nghiệp vụ, phân hệ chủ sở hữu, thuộc tính, kiểu dữ liệu, ràng buộc và mức phân loại.

Quy tắc sử dụng:

1. Mỗi thực thể dùng chung có **đúng một phân hệ chủ sở hữu**. Chỉ phân hệ đó được ghi. Phân hệ khác giữ khóa tham chiếu (`*_id`) và, nếu cần hiển thị, giữ bản sao chỉ-đọc cập nhật qua sự kiện.
2. Phân hệ không được định nghĩa lại thực thể có trong tài liệu này. Thực thể riêng của phân hệ dùng mã `EN-{PH}-nn` trong FRS và SDD của phân hệ.
3. Kiểu dữ liệu dùng kiểu chuẩn của D00-01 §5. Mọi thực thể có các cột bắt buộc ở D00-01 §5.1 (`id`, `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version`, `deleted_at`); bảng dưới không liệt kê lại các cột này.
4. Cột **PL** là mức phân loại dữ liệu: CK (Công khai), NB (Nội bộ), HC (Hạn chế), NC (Nhạy cảm), theo D03-01 §8.2.

## 2. Tổng quan

Sơ đồ dưới đây cho thấy quan hệ giữa các thực thể dùng chung. Thực thể tô đậm trong lời dẫn là thực thể gốc mà hầu hết dữ liệu nghiệp vụ tham chiếu tới.

```{.mermaid caption="Tổng quan"}
erDiagram
  TENANT ||--o{ ORGANIZATION : "có"
  TENANT ||--o{ MEMBER_SYSTEM : "có"
  TENANT ||--o{ USER_ACCOUNT : "có"
  ORGANIZATION ||--o{ ORGANIZATION : "trực thuộc"
  ORGANIZATION ||--o{ MEMBER_SYSTEM : "chủ quản"
  ORGANIZATION }o--|| ADMIN_UNIT : "đặt tại"
  ORGANIZATION ||--o{ USER_ACCOUNT : "công tác tại"
  MEMBER_SYSTEM ||--o{ CONTACT : "đầu mối"
  MEMBER_SYSTEM ||--o{ APP_CREDENTIAL : "định danh"
  ADMIN_UNIT ||--o{ ADMIN_UNIT : "cấp trên / kế thừa"
  DATA_CLASS ||--o{ FIELD_CLASSIFICATION : "áp cho"
  TENANT ||--o{ AUDIT_RECORD : "ghi"
  TENANT ||--o{ FILE_OBJECT : "lưu"
```

Thực thể gốc là **Tenant** (DD-01), **Tổ chức** (DD-02) và **HTTT thành viên** (DD-03): hầu hết bản ghi nghiệp vụ trả lời được câu hỏi "thuộc tỉnh nào, của cơ quan nào, do hệ thống nào tạo".

## 3. Danh sách thực thể dùng chung

| Mã | Thực thể | Tên bảng | PH chủ sở hữu | Ghi chú |
|---|---|---|---|---|
| DD-01 | Tenant | `ph20_tenant.tenant` | PH-20 | Không có cột `tenant_id` (chính nó là tenant) |
| DD-02 | Tổ chức | `ph20_tenant.organization` | PH-20 | Cơ quan, đơn vị trong tỉnh |
| DD-03 | HTTT thành viên | `ph01_onboarding.member_system` | PH-01 | Thay "Application" của APIM và publisher/subscriber của Hub cũ |
| DD-04 | Đầu mối liên hệ | `ph01_onboarding.contact` | PH-01 | |
| DD-05 | Định danh ứng dụng | `ph01_onboarding.app_credential` | PH-01 | Chỉ lưu tham chiếu, không lưu bí mật |
| DD-06 | Tài khoản người dùng | `ph12_iam.user_account` | PH-12 | Bản chiếu từ Keycloak, bổ sung thuộc tính nghiệp vụ |
| DD-07 | Đơn vị hành chính | `ph07_rdm.admin_unit` | PH-07 | `tenant_id = 'COMMON'` |
| DD-08 | Mức phân loại dữ liệu | `ph09_privacy.data_class` | PH-09 | Bốn mức cố định, mở rộng được |
| DD-09 | Phân loại trường dữ liệu | `ph09_privacy.field_classification` | PH-09 | Trong MVP do mã nguồn khai báo; PH-09 quản lý từ đợt 2 |
| DD-10 | Bản ghi kiểm toán | `ph13_audit.audit_record` | PH-13 | Chỉ-thêm |
| DD-11 | Sự kiện outbox | `ph{nn}_*.outbox` | Mỗi phân hệ | Cấu trúc thống nhất |
| DD-12 | Tệp | `ph{nn}_*.file_object` | Mỗi phân hệ | Siêu dữ liệu; nội dung ở kho đối tượng |
| DD-13 | Thông báo | `ph18_ops.notification` | PH-18 | |
| DD-14 | Tham số cấu hình | `ph18_ops.config_param` | PH-18 | Theo tenant, có phiên bản |

: Danh sách thực thể dùng chung

## 4. Đặc tả thực thể

### DD-01 · Tenant

Đại diện cho một tỉnh hoặc thành phố trực thuộc trung ương sử dụng Datahub, cộng thêm hai tenant đặc biệt `PLATFORM` và `COMMON`. Vòng đời theo D03-10 §5.

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `code` | T-TENANT | Có | Duy nhất; `^T\d{2}$` hoặc `PLATFORM`, `COMMON` | CK | Mã tenant, dùng làm khóa nghiệp vụ |
| `name` | T-NAME | Có | | CK | Tên tỉnh, ví dụ "Tỉnh Lâm Đồng" |
| `admin_unit_id` | T-ID | Có với tenant tỉnh | FK DD-07, cấp tỉnh | CK | Đơn vị hành chính tương ứng |
| `status` | T-ENUM | Có | `PROVISIONING`, `ACTIVE`, `SUSPENDED`, `MERGING`, `MERGED`, `DECOMMISSIONED`, `FAILED` | NB | |
| `isolation_mode` | T-ENUM | Có | `SHARED`, `DEDICATED_DB`, `DEDICATED_CLUSTER` | NB | D03-10 §2 |
| `merged_into_id` | T-ID | Khi `MERGED` | FK DD-01 | NB | Tenant đích của sáp nhập |
| `quota` | T-JSON | Có | Theo schema hạn mức D03-10 §5.3 | NB | |
| `realm` | T-CODE | Có | `dh-{code thường}` | NB | Realm Keycloak |
| `activated_at` | T-TS | Không | | NB | |

: DD-01 · Tenant

### DD-02 · Tổ chức

Cơ quan, đơn vị trong tỉnh: UBND tỉnh, sở, ban, ngành, UBND cấp xã, đơn vị sự nghiệp. Tổ chức là chủ quản của HTTT, là nơi công tác của người dùng, là chủ quản dữ liệu.

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `code` | T-CODE | Có | Duy nhất trong tenant | CK | Ưu tiên mã định danh điện tử của cơ quan theo quy định hiện hành |
| `name` | T-NAME | Có | | CK | |
| `short_name` | T-NAME | Không | | CK | |
| `parent_id` | T-ID | Không | FK DD-02, không tạo chu trình | CK | Cơ quan cấp trên |
| `org_type` | T-ENUM | Có | `PROVINCE_PC`, `DEPARTMENT`, `COMMUNE_PC`, `PUBLIC_UNIT`, `OTHER` | CK | |
| `admin_unit_id` | T-ID | Có | FK DD-07 | CK | Địa bàn |
| `is_data_owner` | T-BOOL | Có | Mặc định `false` | NB | Có là chủ quản dữ liệu (SH-08) |
| `effective_from` / `effective_to` | T-DATE | `from` bắt buộc | `to` ≥ `from` | CK | Hiệu lực, phục vụ sắp xếp bộ máy |
| `successor_id` | T-ID | Không | FK DD-02 | CK | Tổ chức kế thừa khi giải thể, sáp nhập |

: DD-02 · Tổ chức

### DD-03 · HTTT thành viên

Một hệ thống thông tin được kết nạp vào Datahub. Đây là chủ thể của mọi lượt gọi API, mọi publisher và subscriber. Thực thể này hợp nhất ba khái niệm rời rạc của hệ cũ: Application (APIM), Publisher và Subscriber (Hub).

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `code` | T-CODE | Có | Duy nhất trong tenant | NB | |
| `name` | T-NAME | Có | | CK | |
| `description` | T-TEXT | Không | ≤ 2.000 ký tự | CK | |
| `owner_org_id` | T-ID | Có | FK DD-02 | CK | Cơ quan chủ quản |
| `operator_name` | T-NAME | Không | | NB | Đơn vị vận hành, phát triển |
| `security_level` | T-ENUM | Có | `L1`…`L5` | NB | Cấp độ ATTT được phê duyệt của HTTT |
| `security_approval_ref` | T-TEXT | Khi `L3` trở lên | | NB | Số quyết định phê duyệt cấp độ |
| `system_type` | T-ENUM | Có | `PROVINCIAL`, `NATIONAL`, `MINISTRY`, `LEGACY`, `EXTERNAL` | CK | |
| `roles` | T-ENUM[] | Có | ≥ 1 trong `CONSUMER`, `PROVIDER`, `PUBLISHER`, `SUBSCRIBER` | NB | |
| `status` | T-ENUM | Có | `DRAFT`, `SUBMITTED`, `APPROVED`, `ACTIVE`, `SUSPENDED`, `TERMINATED`, `REJECTED` | NB | Chi tiết máy trạng thái ở FRS PH-01 |
| `base_urls` | T-JSON | Không | Mảng T-URI, chỉ `https` | NB | Địa chỉ backend khi là `PROVIDER` hoặc nhận webhook |
| `ip_allowlist` | T-JSON | Không | Mảng CIDR | HC | |
| `legacy_ref` | T-TEXT | Không | | NB | Mã ở hệ cũ, phục vụ di trú |

: DD-03 · HTTT thành viên

### DD-04 · Đầu mối liên hệ

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `member_system_id` | T-ID | Có | FK DD-03 | NB | |
| `contact_type` | T-ENUM | Có | `BUSINESS`, `TECHNICAL`, `SECURITY` | NB | Mỗi HTTT bắt buộc có ít nhất một đầu mối `TECHNICAL` |
| `full_name` | T-NAME | Có | | HC | |
| `email` | T-EMAIL | Có | | HC | |
| `phone` | T-PHONE | Không | | HC | |
| `user_account_id` | T-ID | Không | FK DD-06 | NB | Liên kết tài khoản nếu đầu mối có tài khoản |

: DD-04 · Đầu mối liên hệ

### DD-05 · Định danh ứng dụng

Thông tin xác thực mà HTTT dùng để gọi Datahub. Bí mật (client secret, khóa riêng) không lưu ở đây.

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `member_system_id` | T-ID | Có | FK DD-03 | NB | |
| `environment` | T-ENUM | Có | `SANDBOX`, `PRODUCTION` | NB | |
| `auth_method` | T-ENUM | Có | `CLIENT_SECRET`, `PRIVATE_KEY_JWT`, `MTLS`, `API_KEY` | NB | `API_KEY` chỉ cho API dữ liệu mở |
| `client_id` | T-CODE | Có | Duy nhất trong realm | NB | Client ID Keycloak hoặc consumer APISIX |
| `secret_ref` | T-SECRET-REF | Khi có bí mật | | NB | Đường dẫn OpenBao |
| `cert_fingerprint` | T-TEXT | Khi `MTLS` | SHA-256 | NB | |
| `status` | T-ENUM | Có | `ACTIVE`, `ROTATING`, `REVOKED`, `EXPIRED` | NB | |
| `expires_at` | T-TS | Có | Tối đa 12 tháng từ khi cấp | NB | |
| `last_used_at` | T-TS | Không | | NB | |

: DD-05 · Định danh ứng dụng

### DD-06 · Tài khoản người dùng

Keycloak là nguồn sự thật cho xác thực. Bảng này là bản chiếu đồng bộ từ Keycloak cộng các thuộc tính nghiệp vụ mà Keycloak không quản lý tốt.

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `keycloak_id` | T-ID | Có | Duy nhất trong realm | NB | |
| `username` | T-CODE | Có | | NB | |
| `full_name` | T-NAME | Có | | HC | |
| `email` | T-EMAIL | Có | | HC | |
| `phone` | T-PHONE | Không | | HC | |
| `organization_id` | T-ID | Có | FK DD-02 | NB | |
| `position` | T-NAME | Không | | NB | Chức vụ |
| `status` | T-ENUM | Có | `ACTIVE`, `LOCKED`, `DISABLED` | NB | |
| `mfa_enrolled` | T-BOOL | Có | | NB | |
| `last_login_at` | T-TS | Không | | NB | |

: DD-06 · Tài khoản người dùng

### DD-07 · Đơn vị hành chính

Danh mục đơn vị hành chính cấp tỉnh và cấp xã, có lịch sử hiệu lực để xử lý sáp nhập. Dữ liệu thuộc tenant `COMMON`, đồng bộ từ danh mục quốc gia qua PH-07 và PH-14.

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `code` | T-CODE | Có | Theo mã danh mục quốc gia | CK | |
| `name` | T-NAME | Có | | CK | |
| `level` | T-ENUM | Có | `PROVINCE`, `COMMUNE` (và `DISTRICT` cho dữ liệu lịch sử trước cải cách) | CK | |
| `unit_type` | T-ENUM | Có | Tỉnh, thành phố, xã, phường, đặc khu | CK | |
| `parent_id` | T-ID | Không | FK DD-07 | CK | |
| `effective_from` / `effective_to` | T-DATE | `from` bắt buộc | | CK | |
| `successor_ids` | T-JSON | Không | Mảng T-ID | CK | Đơn vị kế thừa khi sáp nhập, chia tách |
| `source_version` | T-TEXT | Có | | CK | Phiên bản danh mục quốc gia |

: DD-07 · Đơn vị hành chính

### DD-08 · Mức phân loại dữ liệu

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `code` | T-CODE | Có | `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE` và mã mở rộng | CK | |
| `name` | T-NAME | Có | | CK | |
| `rank` | Số nguyên | Có | 1–9, càng cao càng nhạy cảm | CK | |
| `log_policy` | T-ENUM | Có | `FULL`, `PARTIAL_MASK`, `NO_VALUE` | NB | |
| `display_policy` | T-ENUM | Có | `FULL`, `MASK_BY_ROLE`, `MASK_DEFAULT` | NB | |
| `encrypt_at_app` | T-BOOL | Có | | NB | |

: DD-08 · Mức phân loại dữ liệu

### DD-09 · Phân loại trường dữ liệu

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `scope` | T-ENUM | Có | `INTERNAL_ENTITY`, `API_SCHEMA`, `EVENT_SCHEMA` | NB | |
| `target` | T-TEXT | Có | Ví dụ `ph01_onboarding.contact.phone` hoặc JSON Pointer trong schema | NB | |
| `data_class_id` | T-ID | Có | FK DD-08 | NB | |
| `personal_data_type` | T-ENUM | Không | `BASIC`, `SENSITIVE` theo pháp luật về dữ liệu cá nhân | NB | |
| `mask_pattern` | T-TEXT | Không | Ví dụ `keep-last-3` | NB | |

: DD-09 · Phân loại trường dữ liệu

### DD-10 · Bản ghi kiểm toán

Đáp ứng FR-00-040 đến FR-00-043. Ghi chỉ-thêm; trường `prev_hash` và `hash` tạo chuỗi băm liên kết theo tenant.

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `occurred_at` | T-TS | Có | | NB | |
| `actor_type` | T-ENUM | Có | `USER`, `SYSTEM`, `MEMBER_SYSTEM` | NB | |
| `actor_id` | T-ID | Có | | NB | |
| `actor_display` | T-NAME | Có | | HC | Tên hiển thị tại thời điểm ghi |
| `on_behalf_of_tenant` | T-TENANT | Không | | NB | Khi vai trò nền tảng truy cập liên tenant |
| `source_ip` | T-TEXT | Không | | HC | |
| `action` | T-CODE | Có | `{PH}.{đối tượng}.{động từ}`, ví dụ `07.category.publish` | NB | |
| `object_type` | T-CODE | Có | | NB | |
| `object_id` | T-TEXT | Có | | NB | |
| `before` / `after` | T-JSON | Không | Đã che theo DD-09 | HC | |
| `result` | T-ENUM | Có | `SUCCESS`, `DENIED`, `FAILED` | NB | |
| `reason` | T-TEXT | Khi thao tác yêu cầu lý do | | NB | |
| `trace_id` | T-TRACE | Có | | NB | |
| `prev_hash` / `hash` | T-TEXT | Có | SHA-256, hex | NB | |

: DD-10 · Bản ghi kiểm toán

Bản ghi kiểm toán không có `updated_at`, `updated_by`, `version`, `deleted_at` (ngoại lệ có chủ đích với D00-01 §5.1).

### DD-11 · Sự kiện outbox

Cấu trúc thống nhất cho bảng outbox của mọi phân hệ (D03-01 §7.3). Nội dung theo CloudEvents 1.0.

| Thuộc tính | Kiểu | Bắt buộc | Mô tả |
|---|---|---|---|
| `event_id` | T-ID | Có | Trở thành `id` của CloudEvent; consumer dùng để chống trùng |
| `event_type` | T-CODE | Có | Ví dụ `vn.datahub.rdm.category.published.v1` |
| `topic` | T-CODE | Có | Theo quy ước D00-01 §6 |
| `aggregate_type` / `aggregate_id` | T-CODE / T-TEXT | Có | Dùng làm khóa phân vùng Kafka |
| `payload` | T-JSON | Có | Đúng schema đã đăng ký |
| `trace_id` | T-TRACE | Có | |
| `occurred_at` | T-TS | Có | |

: DD-11 · Sự kiện outbox

### DD-12 · Tệp

| Thuộc tính | Kiểu | Bắt buộc | Mô tả |
|---|---|---|---|
| `bucket` / `object_key` | T-CODE / T-TEXT | Có | Vị trí trong kho đối tượng |
| `file_name` | T-NAME | Có | Tên gốc |
| `content_type` | T-CODE | Có | Kiểm tra theo nội dung, không tin phần mở rộng |
| `size_bytes` | Số nguyên lớn | Có | Giới hạn theo nghiệp vụ |
| `sha256` | T-TEXT | Có | Toàn vẹn |
| `scan_status` | T-ENUM | Có | `PENDING`, `CLEAN`, `INFECTED`; chỉ `CLEAN` mới được xử lý |
| `data_class_id` | T-ID | Có | FK DD-08 |
| `expires_at` | T-TS | Không | Tệp tạm (tệp xuất) |

: DD-12 · Tệp

### DD-13 · Thông báo

| Thuộc tính | Kiểu | Bắt buộc | Mô tả |
|---|---|---|---|
| `recipient_user_id` | T-ID | Có | FK DD-06 |
| `category` | T-ENUM | Có | `TASK`, `JOB_RESULT`, `ALERT`, `INFO` |
| `title` | T-NAME | Có | Không chứa dữ liệu HC/NC (FR-00-062) |
| `link` | T-URI | Không | Đường dẫn nội bộ ứng dụng |
| `read_at` | T-TS | Không | |
| `channels_sent` | T-JSON | Có | Kênh đã gửi |

: DD-13 · Thông báo

### DD-14 · Tham số cấu hình

| Thuộc tính | Kiểu | Bắt buộc | Mô tả |
|---|---|---|---|
| `key` | T-CODE | Có | `{PH}.{nhóm}.{tên}`, ví dụ `00.session.idle-timeout-minutes` |
| `value` | T-JSON | Có | Kiểm tra theo `schema` |
| `schema` | T-JSON | Có | JSON Schema của giá trị |
| `scope` | T-ENUM | Có | `PLATFORM` (mặc định toàn nền tảng) hoặc `TENANT` (ghi đè) |
| `effective_from` | T-TS | Có | |

: DD-14 · Tham số cấu hình

## 5. Ánh xạ từ dữ liệu hệ cũ

Bảng dưới đây ánh xạ các bảng của hệ cũ sang thực thể dùng chung, làm đầu vào cho kế hoạch di trú (D06-01). Ánh xạ của bảng nghiệp vụ riêng (danh mục, giao dịch thanh toán, topic) nằm trong SDD phân hệ tương ứng.

| Bảng hệ cũ | Khối | Thực thể Datahub | Ghi chú |
|---|---|---|---|
| `User` | Bus | DD-06 | Không di trú mật khẩu; người dùng kích hoạt lại tài khoản |
| `Group`, `Project_group` | Bus | Nhóm, vai trò ở PH-12; không gian làm việc ở PH-04 | |
| Application (APIM) | APIM | DD-03 (vai trò `CONSUMER`), DD-05 | Client ID được cấp mới |
| `publisher` | Hub | DD-03 (vai trò `PUBLISHER`) | Ghép với Application nếu cùng hệ thống |
| `subscriber` | Hub | DD-03 (vai trò `SUBSCRIBER`) | `is_integration_flow = true` thì ánh xạ thành luồng PH-04 |
| `payment_partner` | Payment | DD-03 (HTTT gọi thanh toán) | Đối tác là HTTT dịch vụ công |
| Tài khoản Keycloak cũ | Chung | DD-06 | Xuất người dùng, không xuất thông tin xác thực |

: Ánh xạ từ dữ liệu hệ cũ
