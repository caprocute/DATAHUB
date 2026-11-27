---
ma_tai_lieu: D02-07
ten: Từ điển dữ liệu dùng chung
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Phân tích nghiệp vụ, Kiến trúc sư, Đội phát triển, Kiểm thử
mo_ta: Định nghĩa một lần duy nhất 14 thực thể dùng chung DD-01 đến DD-14 gồm chủ sở hữu, thuộc tính, ràng buộc, mức phân loại, sơ đồ quan hệ và ánh xạ từ dữ liệu hệ cũ.
tai_lieu_lien_quan: D00-01 Thuật ngữ và quy ước; D02-02 SRS; D02-08 Ma trận phân quyền; D03-01 SAD; D03-03 CSDL các phân hệ; D03-10 Đa tenant; D06-01 Kế hoạch di trú
---

# D02-07 · Từ điển dữ liệu dùng chung

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Định nghĩa một lần duy nhất các thực thể dữ liệu mà nhiều phân hệ cùng dùng (tenant, tổ chức, HTTT thành viên, người dùng, đơn vị hành chính, phân loại dữ liệu, kiểm toán, tệp, thông báo, tham số), để các phân hệ không định nghĩa lệch nhau và dữ liệu của các tỉnh ghép được với nhau.

**Phạm vi.** 14 thực thể dùng chung `DD-01…14`, mỗi thực thể có đúng một phân hệ chủ sở hữu, kèm thuộc tính, kiểu, ràng buộc, mức phân loại dữ liệu và ánh xạ từ bảng hệ cũ. Thực thể riêng của từng phân hệ (`EN-{PH}-nn`) nằm ở FRS và SDD phân hệ, không thuộc tài liệu này.

**Căn cứ pháp lý.** CMP-LAW-01 (Luật Dữ liệu số 60/2024/QH15) về phân loại và quản trị dữ liệu; CMP-LAW-05 và CMP-LAW-04 (Luật BVDLCN 91/2025, NĐ 356/2025) về dữ liệu cá nhân và che dữ liệu nhạy cảm; CMP-LAW-06 và CMP-LAW-08 (NĐ 331/2026, TCVN 14423:2026) về nhật ký và kiểm soát truy cập cấp độ 3.

**Những điểm hội đồng cần lưu ý.** (1) Mỗi thực thể chỉ một phân hệ được ghi; phân hệ khác giữ khóa tham chiếu hoặc bản sao chỉ-đọc cập nhật qua sự kiện. (2) Mọi thuộc tính có mức phân loại (CK, NB, HC, NC) làm căn cứ che dữ liệu và quy định nhật ký. (3) Bản ghi kiểm toán DD-10 chỉ-thêm và có chuỗi băm liên kết theo tenant, là ngoại lệ có chủ đích của cột bắt buộc chung. (4) Định danh ứng dụng DD-05 chỉ lưu tham chiếu tới OpenBao, không lưu bí mật. (5) Tenant `COMMON` giữ dữ liệu dùng chung toàn quốc như đơn vị hành chính.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Thực thể dùng chung | 14 (DD-01…14) |
| Phân hệ chủ sở hữu | 7 phân hệ (PH-01, 07, 09, 12, 13, 18, 20) sở hữu 12 thực thể; DD-11 và DD-12 do từng phân hệ tự sở hữu bản của mình |
| Mức phân loại dữ liệu | 4 (CK, NB, HC, NC) |
| Bảng hệ cũ được ánh xạ | 7 dòng ánh xạ ở chương 5 |

: Con số chính của từ điển dữ liệu

## 1. Mục đích

Một số thực thể được nhiều phân hệ sử dụng: tenant, tổ chức, HTTT thành viên, người dùng, đơn vị hành chính, tệp đính kèm, bản ghi kiểm toán. Nếu mỗi phân hệ tự định nghĩa, các định nghĩa sẽ lệch nhau và dữ liệu không ghép được. Tài liệu này định nghĩa **một lần duy nhất** các thực thể dùng chung (`DD-nn`): ý nghĩa nghiệp vụ, phân hệ chủ sở hữu, thuộc tính, kiểu dữ liệu, ràng buộc và mức phân loại.

Quy tắc sử dụng:

1. Mỗi thực thể dùng chung có **đúng một phân hệ chủ sở hữu**. Chỉ phân hệ đó được ghi. Phân hệ khác giữ khóa tham chiếu (`*_id`) và, nếu cần hiển thị, giữ bản sao chỉ-đọc cập nhật qua sự kiện.
2. Phân hệ không được định nghĩa lại thực thể có trong tài liệu này. Thực thể riêng của phân hệ dùng mã `EN-{PH}-nn` trong FRS và SDD của phân hệ.
3. Kiểu dữ liệu dùng kiểu chuẩn của D00-01 §5. Mọi thực thể có các cột bắt buộc ở D00-01 §5.1 (`id`, `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version`, `deleted_at`); bảng dưới không liệt kê lại các cột này.
4. Cột **PL** là mức phân loại dữ liệu: CK (Công khai), NB (Nội bộ), HC (Hạn chế), NC (Nhạy cảm), theo D03-01 §8.2.

### 1.1. Phạm vi

Tài liệu bao phủ 14 thực thể dùng chung `DD-01…14` ở chương 3 và 4, và ánh xạ từ bảng hệ cũ ở chương 5. Tài liệu không bao phủ thực thể riêng của phân hệ (danh mục, giao dịch thanh toán, topic, luồng) vì các thực thể đó thuộc FRS và SDD của phân hệ tương ứng.

### 1.2. Người đọc và cách đọc

Bảng dưới gợi ý phần nên đọc theo từng nhóm người đọc.

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, chương 2, chương 3 | Đánh giá tính thống nhất dữ liệu và việc phân loại dữ liệu |
| Phân tích nghiệp vụ | Chương 2, chương 3, chương 4 | Hiểu ý nghĩa nghiệp vụ và quan hệ của từng thực thể |
| Kiến trúc sư | Chương 2, chương 3, chương 4 | Xác định chủ sở hữu và ranh giới giữa các phân hệ |
| Đội phát triển | Chương 4, chương 5 | Dựng bảng, kiểu, ràng buộc và di trú dữ liệu |
| Kiểm thử viên | Chương 4 | Sinh ca kiểm thử giá trị biên, ràng buộc, phân loại |

: Người đọc và phần cần đọc của từ điển dữ liệu

### 1.3. Thuật ngữ và chữ viết tắt

Thuật ngữ chung theo D00-01. Bảng dưới chỉ giải thích ký hiệu riêng của tài liệu này.

| Thuật ngữ, viết tắt | Giải thích |
|---|---|
| DD-nn | Mã thực thể dùng chung |
| EN-{PH}-nn | Mã thực thể riêng của một phân hệ |
| PL | Mức phân loại dữ liệu: CK, NB, HC, NC |
| FK | Khóa ngoại, tham chiếu tới thực thể khác |
| `T-ID`, `T-CODE`, `T-ENUM`, `T-JSON`… | Kiểu dữ liệu chuẩn của D00-01 §5 |
| Tenant `COMMON` | Tenant giữ dữ liệu dùng chung toàn quốc (ví dụ đơn vị hành chính) |
| Outbox | Bảng lưu sự kiện cùng giao dịch, rồi mới phát lên Kafka |

: Thuật ngữ và chữ viết tắt của từ điển dữ liệu

### 1.4. Tài liệu tham chiếu

Bảng dưới liệt kê tài liệu cung cấp kiểu dữ liệu, quy ước và căn cứ cho từ điển này.

| Mã | Tên | Vai trò với tài liệu này |
|---|---|---|
| D00-01 | Thuật ngữ và quy ước | Kiểu dữ liệu chuẩn (§5), cột bắt buộc (§5.1), quy ước đặt tên |
| D02-02 | Đặc tả yêu cầu phần mềm | Nhóm FR-00 dùng chung (kiểm toán, thông báo) |
| D03-01 | Kiến trúc tổng thể | Mức phân loại dữ liệu (§8.2), outbox (§7.3) |
| D03-10 | Thiết kế đa tenant | Vòng đời tenant, hạn mức, chế độ cách ly |
| D03-03 | CSDL các phân hệ | Nơi hiện thực bảng theo từ điển này |
| D06-01 | Kế hoạch di trú (dự kiến, Đợt 5) | Dùng bảng ánh xạ chương 5 |

: Tài liệu tham chiếu của từ điển dữ liệu

### 1.5. Cấu trúc tài liệu

Bảng dưới nêu nội dung từng chương và người đọc chính.

| Chương | Nội dung | Người đọc chính |
|---|---|---|
| 1 | Mục đích, quy tắc sử dụng, giới thiệu | Mọi người đọc |
| 2 | Sơ đồ quan hệ giữa các thực thể gốc | Kiến trúc sư, phân tích nghiệp vụ |
| 3 | Danh sách 14 thực thể, sơ đồ ERD đầy đủ | Kiến trúc sư, đội phát triển |
| 4 | Đặc tả thuộc tính từng thực thể | Đội phát triển, kiểm thử |
| 5 | Ánh xạ từ dữ liệu hệ cũ | Đội phát triển, di trú |

: Cấu trúc tài liệu của từ điển dữ liệu

## 2. Tổng quan

Sơ đồ dưới đây cho thấy quan hệ giữa các thực thể dùng chung. Thực thể tô đậm trong lời dẫn là thực thể gốc mà hầu hết dữ liệu nghiệp vụ tham chiếu tới.

```{.mermaid caption="Quan hệ giữa các thực thể gốc dùng chung"}
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

Bảng dưới liệt kê 14 thực thể cùng tên bảng và phân hệ chủ sở hữu; ngay sau bảng là sơ đồ ERD đầy đủ của cả 14 thực thể.

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
| DD-11 | Sự kiện outbox | `ph{nn}_*.outbox` | Mỗi phân hệ | Cấu trúc thống nhất; PH-02 đặt tên bảng `outbox_event` |
| DD-12 | Tệp | `ph{nn}_*.file_object` | Mỗi phân hệ | Siêu dữ liệu; nội dung ở kho đối tượng; PH-01 đặt tên bảng `attachment` |
| DD-13 | Thông báo | `ph18_ops.notification` | PH-18 | |
| DD-14 | Tham số cấu hình | `ph18_ops.config_param` | PH-18 | Theo tenant, có phiên bản |

: Danh sách 14 thực thể dùng chung DD-01…14 và phân hệ chủ sở hữu

Sơ đồ dưới đây vẽ đủ 14 thực thể cùng các thuộc tính khóa và khóa ngoại. Sơ đồ ở chương 2 chỉ nêu các thực thể gốc; sơ đồ này bổ sung ba thực thể hạ tầng (outbox, thông báo, tham số) và các khóa tham chiếu tới phân loại dữ liệu.

```{.mermaid caption="Sơ đồ quan hệ thực thể ERD của 14 thực thể dùng chung DD-01…14"}
erDiagram
  TENANT {
    string code PK "DD-01"
    string status
    string isolation_mode
    string admin_unit_id FK
    string merged_into_id FK
  }
  ORGANIZATION {
    string id PK "DD-02"
    string code
    string parent_id FK
    string admin_unit_id FK
    string successor_id FK
  }
  MEMBER_SYSTEM {
    string id PK "DD-03"
    string code
    string owner_org_id FK
    string security_level
    string status
  }
  CONTACT {
    string id PK "DD-04"
    string member_system_id FK
    string contact_type
    string user_account_id FK
  }
  APP_CREDENTIAL {
    string id PK "DD-05"
    string member_system_id FK
    string client_id
    string secret_ref
    string status
  }
  USER_ACCOUNT {
    string id PK "DD-06"
    string keycloak_id
    string organization_id FK
    string status
  }
  ADMIN_UNIT {
    string id PK "DD-07"
    string code
    string level
    string parent_id FK
  }
  DATA_CLASS {
    string id PK "DD-08"
    string code
    int rank
  }
  FIELD_CLASSIFICATION {
    string id PK "DD-09"
    string target
    string data_class_id FK
  }
  AUDIT_RECORD {
    string id PK "DD-10"
    string action
    string object_id
    string hash
  }
  OUTBOX_EVENT {
    string event_id PK "DD-11"
    string event_type
    string topic
  }
  FILE_OBJECT {
    string id PK "DD-12"
    string object_key
    string scan_status
    string data_class_id FK
  }
  NOTIFICATION {
    string id PK "DD-13"
    string recipient_user_id FK
    string category
  }
  CONFIG_PARAM {
    string id PK "DD-14"
    string key
    string scope
  }
  TENANT ||--o{ ORGANIZATION : "có"
  TENANT ||--o{ MEMBER_SYSTEM : "có"
  TENANT ||--o{ USER_ACCOUNT : "có"
  TENANT ||--o{ AUDIT_RECORD : "ghi"
  TENANT ||--o{ OUTBOX_EVENT : "phát"
  TENANT ||--o{ FILE_OBJECT : "lưu"
  TENANT ||--o{ NOTIFICATION : "gửi"
  TENANT ||--o{ CONFIG_PARAM : "ghi đè"
  TENANT |o--o| TENANT : "sáp nhập vào"
  ADMIN_UNIT ||--o{ TENANT : "tương ứng"
  ADMIN_UNIT ||--o{ ADMIN_UNIT : "cấp trên"
  ADMIN_UNIT ||--o{ ORGANIZATION : "đặt tại"
  ORGANIZATION ||--o{ ORGANIZATION : "trực thuộc"
  ORGANIZATION ||--o{ MEMBER_SYSTEM : "chủ quản"
  ORGANIZATION ||--o{ USER_ACCOUNT : "công tác tại"
  MEMBER_SYSTEM ||--o{ CONTACT : "đầu mối"
  MEMBER_SYSTEM ||--o{ APP_CREDENTIAL : "định danh"
  USER_ACCOUNT |o--o{ CONTACT : "liên kết"
  USER_ACCOUNT ||--o{ NOTIFICATION : "nhận"
  DATA_CLASS ||--o{ FIELD_CLASSIFICATION : "áp cho"
  DATA_CLASS ||--o{ FILE_OBJECT : "phân loại"
```

Hình cho thấy Tenant ở trung tâm: tám thực thể gắn trực tiếp vào tenant, riêng tenant tự tham chiếu khi sáp nhập. Tổ chức và HTTT thành viên là trục nghiệp vụ, đầu mối và định danh ứng dụng treo vào HTTT, người dùng treo vào tổ chức. Đơn vị hành chính thuộc tenant `COMMON` được cả tenant lẫn tổ chức tham chiếu. Phân loại dữ liệu DD-08 là danh mục tra cứu cho phân loại trường và tệp; outbox, thông báo và tham số là hạ tầng dùng chung của mọi phân hệ.

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
| `kind` | T-ENUM | Có | `PROVINCE`, `PLATFORM`, `COMMON`; bất biến | CK | Loại tenant (cột vật lý `kind`) |
| `short_name` | T-NAME | Không | | CK | Tên ngắn hiển thị |
| `scale_profile` | T-CODE | Không | `^QM-[A-Z0-9]{2,12}$` | NB | Hồ sơ quy mô (D03-09) |
| `deployment_profile` | T-ENUM | Có | `HT-A`, `HT-B` | NB | Hồ sơ triển khai |
| `template_id` | T-ID | Không | | NB | Khuôn mẫu khởi tạo đã dùng |
| `config_path` | T-TEXT | Không | | NB | Đường dẫn cấu hình của tenant trong kho `dh-tenant-config` |
| `declared_at` | T-TS | Không | | NB | Thời điểm khai báo |
| `realm` | T-CODE | Có | `dh-{code thường}` | NB | Realm Keycloak |
| `activated_at` | T-TS | Không | | NB | |
| `suspended_at`, `merged_at`, `decommissioned_at` | T-TS | Không | | NB | Các mốc thời gian của trạng thái tương ứng |

: Thuộc tính thực thể DD-01 Tenant

Hạn mức không còn là thuộc tính `quota` dạng JSON của DD-01 mà nằm ở bảng riêng `ph20_tenant.tenant_quota` của PH-20 (theo schema hạn mức D03-10 §5.3), vì hạn mức có lịch sử đổi, đề nghị đổi và ghi đè tạm thời.

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
| `status` | T-ENUM | Có | `ACTIVE`, `INACTIVE`, `DISSOLVED`, `MERGED`; `DISSOLVED`, `MERGED` cần `effective_to`, `MERGED` cần `successor_id` | CK | Trạng thái của tổ chức |
| `external_code` | T-CODE | Không | | CK | Mã định danh điện tử theo quy định hiện hành khi khác `code` |

: Thuộc tính thực thể DD-02 Tổ chức

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
| `status` | T-ENUM | Có | `DRAFT`, `SUBMITTED`, `APPROVED`, `ACTIVE`, `SUSPENDED`, `TERMINATED`, `REJECTED` | NB | Máy trạng thái ở mục 4.3 của FRS PH-01 (D02-03-PH01) |
| `review_stage` | T-ENUM | Khi `SUBMITTED` | `WAITING_ASSIGN`, `IN_REVIEW`, `CONSULTING`, `WAITING_APPROVAL`; rỗng ở trạng thái khác | NB | Giai đoạn thẩm định |
| `provision_stage` | T-ENUM | Khi `APPROVED` | `PROVISIONING`, `AWAITING_KEY`, `SANDBOX_READY`, `PROVISION_FAILED`; rỗng ở trạng thái khác | NB | Giai đoạn cấp định danh sau phê duyệt |
| `enforcement` | T-ENUM | Có | `NONE`, `PENDING`, `DONE` | NB | Tiến độ cắt quyền khi tạm ngừng hoặc chấm dứt |
| `revision_no` | Số nguyên | Có | ≥ 0; nộp lại tăng 1 | NB | Số lần đã nộp hồ sơ |
| `origin_tenant_id` | T-ID | Không | | NB | Tenant nguồn khi hồ sơ chuyển vào do sáp nhập tenant (D03-10 §5.4) |
| `activated_at` | T-TS | Không | | NB | Thời điểm kích hoạt |
| `last_access_review_at` | T-TS | Không | | NB | Lần rà soát quyền gần nhất |
| `base_urls` | T-JSON | Không | Mảng T-URI, chỉ `https` | NB | Địa chỉ backend khi là `PROVIDER` hoặc nhận webhook |
| `ip_allowlist` | T-JSON | Không | Mảng CIDR | HC | |
| `legacy_ref` | T-TEXT | Không | | NB | Mã ở hệ cũ, phục vụ di trú |

: Thuộc tính thực thể DD-03 HTTT thành viên

### DD-04 · Đầu mối liên hệ

Người của cơ quan chủ quản được liên hệ khi có việc về một HTTT. Dữ liệu liên hệ cá nhân được xếp mức hạn chế (HC).

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `member_system_id` | T-ID | Có | FK DD-03 | NB | |
| `contact_type` | T-ENUM | Có | `BUSINESS`, `TECHNICAL`, `SECURITY` | NB | Mỗi HTTT bắt buộc có ít nhất một đầu mối `TECHNICAL` |
| `full_name` | T-NAME | Có | | HC | |
| `email` | T-EMAIL | Có | | HC | |
| `phone` | T-PHONE | Không | | HC | |
| `job_title` | T-NAME | Có | | HC | Chức vụ (cột vật lý `job_title`) |
| `user_account_id` | T-ID | Không | FK DD-06 | NB | Liên kết tài khoản nếu đầu mối có tài khoản |
| `is_public` | T-BOOL | Có | Mặc định `true` | NB | Hiển thị đầu mối cho người dùng trong tenant |
| `status` | T-ENUM | Có | `ACTIVE`, `INACTIVE` | NB | Đầu mối thôi liên hệ chuyển `INACTIVE` |
| `last_confirmed_at` | T-TS | Không | | NB | Lần gần nhất đầu mối xác nhận thông tin còn đúng |

: Thuộc tính thực thể DD-04 Đầu mối liên hệ

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
| `jwks_ref` | T-TEXT | Khi `PRIVATE_KEY_JWT` | | NB | Tham chiếu tập khóa công khai |
| `status` | T-ENUM | Có | `PENDING`, `ACTIVE`, `ROTATING`, `REVOKED`, `EXPIRED` | NB | `PENDING` là trạng thái kỹ thuật của bước `RECORD` trong saga cấp định danh |
| `expires_at` | T-TS | Có | Tối đa 12 tháng từ khi cấp | NB | |
| `rotation_ends_at` | T-TS | Khi `ROTATING` | | NB | Hết thời hạn cấp song song khi xoay vòng |
| `revoked_at`, `revoked_reason` | T-TS, T-TEXT | Khi `REVOKED` | | NB | Thu hồi định danh, kèm lý do |
| `last_used_at` | T-TS | Không | | NB | |

: Thuộc tính thực thể DD-05 Định danh ứng dụng

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

: Thuộc tính thực thể DD-06 Tài khoản người dùng

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

: Thuộc tính thực thể DD-07 Đơn vị hành chính

### DD-08 · Mức phân loại dữ liệu

Danh mục bốn mức phân loại dữ liệu cùng chính sách ghi nhật ký, hiển thị và mã hóa tương ứng; là nền để PH-09 và PH-13 che dữ liệu.

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `code` | T-CODE | Có | `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE` và mã mở rộng | CK | |
| `name` | T-NAME | Có | | CK | |
| `rank` | Số nguyên | Có | 1–9, càng cao càng nhạy cảm | CK | |
| `log_policy` | T-ENUM | Có | `FULL`, `PARTIAL_MASK`, `NO_VALUE` | NB | |
| `display_policy` | T-ENUM | Có | `FULL`, `MASK_BY_ROLE`, `MASK_DEFAULT` | NB | |
| `encrypt_at_app` | T-BOOL | Có | | NB | |

: Thuộc tính thực thể DD-08 Mức phân loại dữ liệu

### DD-09 · Phân loại trường dữ liệu

Gán mức phân loại cho từng trường dữ liệu của thực thể, lược đồ API hoặc lược đồ sự kiện để hệ thống biết trường nào phải che.

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `scope` | T-ENUM | Có | `INTERNAL_ENTITY`, `API_SCHEMA`, `EVENT_SCHEMA` | NB | |
| `target` | T-TEXT | Có | Ví dụ `ph01_onboarding.contact.phone` hoặc JSON Pointer trong schema | NB | |
| `data_class_id` | T-ID | Có | FK DD-08 | NB | |
| `personal_data_type` | T-ENUM | Có | `NONE`, `BASIC`, `SENSITIVE` theo pháp luật về dữ liệu cá nhân; mặc định `NONE` (trường không chứa dữ liệu cá nhân) | NB | |
| `mask_pattern` | T-TEXT | Không | Ví dụ `keep-last-3` | NB | |

: Thuộc tính thực thể DD-09 Phân loại trường dữ liệu

### DD-10 · Bản ghi kiểm toán

Đáp ứng FR-00-040 đến FR-00-043. Ghi chỉ-thêm; trường `prev_hash` và `hash` tạo chuỗi băm liên kết theo tenant.

| Thuộc tính | Kiểu | Bắt buộc | Ràng buộc | PL | Mô tả |
|---|---|---|---|---|---|
| `occurred_at` | T-TS | Có | | NB | |
| `actor_type` | T-ENUM | Có | `USER`, `SYSTEM`, `MEMBER_SYSTEM` | NB | |
| `actor_id` | T-ID | Có | | NB | |
| `actor_name` | T-NAME | Có | | HC | Tên hiển thị tại thời điểm ghi |
| `actor_home_tenant` | T-TENANT | Không | | NB | Tenant gốc của người thao tác khi vai trò nền tảng truy cập liên tenant |
| `source_ip` | T-TEXT | Không | | HC | |
| `user_agent`, `session_hash` | T-TEXT | Không | `session_hash` là băm của mã phiên | HC | Ngữ cảnh thiết bị, phiên |
| `source_du` | T-CODE | Có | | NB | Đơn vị triển khai sinh bản ghi |
| `action` | T-CODE | Có | `{PH}.{đối tượng}.{động từ}`, ví dụ `07.category.publish` | NB | |
| `object_type` | T-CODE | Có | | NB | |
| `object_id` | T-TEXT | Có | | NB | |
| `object_key_hmac` | T-TEXT | Không | HMAC theo khóa tenant | NB | Băm có khóa của số định danh chủ thể dữ liệu, không lưu số định danh (BR-13-005) |
| `before` / `after` | T-JSON | Không | Đã che theo DD-09 | HC | |
| `outcome` | T-ENUM | Có | `SUCCESS`, `DENIED`, `FAILED` | NB | Kết quả thao tác |
| `purpose` | T-CODE | Không | | NB | Mục đích khai thác khi có |
| `reason` | T-TEXT | Khi thao tác yêu cầu lý do | | NB | |
| `trace_id` | T-TRACE | Có | | NB | |
| `seq`, `recorded_at` | Số nguyên lớn, T-TS | Có | `seq` liên tục theo tenant; `recorded_at` do PH-13 gán | NB | Số thứ tự trong chuỗi và thời điểm ghi |
| `prev_hash` / `hash` | T-TEXT | Có | SHA-256, hex | NB | |

: Thuộc tính thực thể DD-10 Bản ghi kiểm toán

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

: Thuộc tính thực thể DD-11 Sự kiện outbox

Các bảng hạ tầng `inbox`, `idempotency_record`, `shedlock` của từng phân hệ không phải thực thể dùng chung; mỗi phân hệ khai báo ở D03-03 của mình. Riêng bảng outbox của PH-02 đặt tên `outbox_event`.

### DD-12 · Tệp

Siêu dữ liệu của tệp đính kèm hoặc tệp xuất; nội dung tệp nằm ở kho đối tượng.

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

: Thuộc tính thực thể DD-12 Tệp

Ở bản vật lý, PH-20 đổi tên thuộc tính `object_key` thành `object_path` (tránh trùng tên với dạng cột bí mật mà công cụ quét hay báo nhầm) và PH-01 đặt tên bảng `attachment` thay `file_object`. Tên cột của các phân hệ khác theo D03-03 của phân hệ đó.

### DD-13 · Thông báo

Thông báo gửi tới người dùng qua hộp thông báo và các kênh khác, dùng chung cho mọi phân hệ.

| Thuộc tính | Kiểu | Bắt buộc | Mô tả |
|---|---|---|---|
| `recipient_user_id` | T-ID | Có | FK DD-06 |
| `category` | T-ENUM | Có | `TASK`, `JOB_RESULT`, `ALERT`, `INFO` |
| `title` | T-NAME | Có | Không chứa dữ liệu HC/NC (FR-00-062) |
| `link` | T-URI | Không | Đường dẫn nội bộ ứng dụng |
| `read_at` | T-TS | Không | |
| `channels_sent` | T-JSON | Có | Kênh đã gửi |

: Thuộc tính thực thể DD-13 Thông báo

PH-18 hiện thực DD-13 bằng hai bảng `notification_message` và `notification_delivery`; khung nhìn `ph18_ops.notification` giữ tên cũ của DD-13, trong đó `channels_sent` là mảng các kênh đã gửi.

### DD-14 · Tham số cấu hình

Tham số vận hành theo phiên bản, mặc định toàn nền tảng và có thể ghi đè theo tenant.

| Thuộc tính | Kiểu | Bắt buộc | Mô tả |
|---|---|---|---|
| `key` | T-CODE | Có | `{PH}.{nhóm}.{tên}`, ví dụ `00.session.idle-timeout-minutes` |
| `value` | T-JSON | Có | Kiểm tra theo `schema` |
| `schema` | T-JSON | Có | JSON Schema của giá trị |
| `scope` | T-ENUM | Có | `PLATFORM` (mặc định toàn nền tảng) hoặc `TENANT` (ghi đè) |
| `effective_from` | T-TS | Có | |

: Thuộc tính thực thể DD-14 Tham số cấu hình

PH-18 hiện thực DD-14 bằng bốn bảng `param_definition`, `param_value`, `param_value_version`, `param_change_request` và khung nhìn `ph18_ops.config_param` giữ tên cũ; `scope` nhận `PLATFORM` hoặc `TENANT`, `schema` là `json_schema` của lược đồ khóa. Ví dụ khóa `00.session.idle-timeout-minutes` dùng không gian tên `00` do PH-00 (nền tảng chung) sở hữu, đã khởi tạo trong dữ liệu nền của PH-18.

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

: Ánh xạ bảng hệ cũ sang thực thể dùng chung DD-nn

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 21/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Áp chuẩn trình bày kết hợp: thêm tóm tắt cho hội đồng thẩm định, năm mục giới thiệu, sơ đồ ERD đầy đủ 14 thực thể kèm thuyết minh, đoạn mở cho các mục còn thiếu, chú thích bảng theo tên thực thể. Giữ nguyên toàn bộ thuộc tính và ràng buộc cũ |
| 0.3 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: DD-01, DD-02, DD-03, DD-04, DD-05, DD-10 thêm hoặc đổi thuộc tính theo D03-03 của PH-01, PH-13, PH-20; DD-09 thêm giá trị `NONE`; ghi tên bảng vật lý khác chuẩn ở DD-11, DD-12, DD-13, DD-14 |
