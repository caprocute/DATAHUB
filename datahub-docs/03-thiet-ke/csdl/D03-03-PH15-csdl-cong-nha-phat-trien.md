---
ma_tai_lieu: D03-03-PH15
ten: Thiết kế cơ sở dữ liệu phân hệ PH-15 Cổng nhà phát triển
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kiến trúc sư dữ liệu, DBA, lập trình viên module portal, kiểm thử viên, hội đồng thẩm định
phan_he: PH-15
nguoi_lap: Nhóm phân hệ PH-15
mo_ta: Thiết kế 35 bảng của schema ph15_portal trên cụm pg-core, gồm khóa, ràng buộc theo enum của FRS, RLS theo tenant, phân vùng lượt thử, mã hóa trường nhạy cảm, lưu giữ và ánh xạ nội dung portal Gravitee cũ, trích từ DDL đã chạy thử.
tai_lieu_lien_quan: D02-03-PH15 FRS; D03-02-PH15 SDD; D03-04-PH15 API; D03-10 Thiết kế đa tenant; ADR-003; ADR-032; ADR-047; D05-02-PH15 Test case
---

# D03-03-PH15 · Thiết kế cơ sở dữ liệu phân hệ PH-15 Cổng nhà phát triển

## Tóm tắt cho hội đồng thẩm định

PH-15 là lớp trình bày và tự phục vụ: giữ **bản sao chỉ đọc** của danh mục API từ PH-02, nội dung hướng dẫn do cổng tự quản và dữ liệu của nhà phát triển (tài khoản, nhóm, ứng dụng sandbox, thông tin xác thực sandbox, lượt thử, hỗ trợ), trong schema `ph15_portal` trên cụm `pg-core`, cách ly theo tỉnh bằng RLS (ADR-003). Không có bảng đăng ký sử dụng, bảng duyệt hay cấu hình gateway: các quyết định đó thuộc PH-01, PH-02, PH-03.

Bốn điểm thiết kế chính:

1. **Không có bí mật trong CSDL.** Bí mật sandbox hiện đúng một lần (BR-15-011): `app_credential` chỉ có tiền tố 8 ký tự và băm HMAC có pepper; Mã truy cập kho Git, khóa bọc nằm ở OpenBao, CSDL chỉ giữ đường dẫn. Cột nhạy cảm duy nhất, điện thoại của tài khoản `dh-dev`, mã hóa envelope theo ADR-032. Hộp thư lũy đẳng không lưu thân phản hồi.
2. **Quy tắc nghiệp vụ chốt bằng CHECK.** Enum đúng Phụ lục A của FRS; duyệt nội dung bốn mắt, bật thử production bốn mắt và ≤ 90 ngày, thông tin xác thực ≤ 180 ngày, thử production chỉ `GET`, `HEAD` và không lưu thân, mã định danh bất biến và không dùng lại (§3.36).
3. **Cách ly tỉnh bằng CSDL.** 34 bảng có `tenant_id` và `FORCE ROW LEVEL SECURITY`; bảng duy nhất không có `tenant_id` là `shedlock`. Danh mục liên tỉnh (mức `NATIONAL`) được nạp thành bản sao riêng của từng tenant kèm `origin_tenant_id`, nên không chính sách nào cho đọc chéo. Đã chạy thử ngày 26/11/2026 trên PostgreSQL 16.15: 68 ca của [`ph15/test/ph15_isolation_test.sql`](ph15/test/ph15_isolation_test.sql) đều đạt (§4.2).
4. **Một bảng lớn, phân vùng tháng.** Chỉ `try_run` (tối đa 3.000 lượt mỗi ứng dụng mỗi ngày) phân vùng theo tháng (ADR-047); dữ liệu còn lại nhỏ (500 API, 3.000 phiên bản, 2.000 ứng dụng).

Nguồn duy nhất của DDL là [`ph15/ddl/ph15_portal.sql`](ph15/ddl/ph15_portal.sql). Bảng cột ở §3 sinh bằng [`ph15/tools/gen_tables_md.py`](ph15/tools/gen_tables_md.py), khối đặc tả 10 mục của từng bảng bằng [`ph15/tools/them_dac_ta_bang.py`](ph15/tools/them_dac_ta_bang.py). Tên bảng theo Phụ lục A của SDD D03-02-PH15; các chỗ khác SDD ghi ở §10.

## 0. Giới thiệu

### 0.1. Mục đích, phạm vi và người đọc

Tài liệu mô tả thiết kế vật lý CSDL của PH-15 cho kỹ sư module `portal` (DU `dh-connect`, Z3), DBA `pg-core`, kiểm thử viên và hội đồng thẩm định. Phạm vi là schema `ph15_portal` và kho đi kèm (Kafka, Valkey, Garage, OpenSearch). Ngoài phạm vi: danh mục, phiên bản, đăng ký sử dụng (PH-02), hồ sơ HTTT và định danh production (PH-01), người dùng và mật khẩu (PH-12), nhật ký truy cập và chỉ số (PH-13); PH-15 chỉ giữ bản sao hoặc con trỏ. Hội đồng đọc Tóm tắt, §1, §3.36, §7; kỹ sư đọc §2 đến §4; DBA đọc §1.1, §6, §7.

### 0.2. Thuật ngữ và chữ viết tắt

Các từ dùng xuyên suốt: **RLS** (Row Level Security, chính sách PostgreSQL lọc dòng theo `tenant_id`, ADR-003); **DEK, KEK** (khóa dữ liệu và khóa bọc trong mã hóa envelope, KEK ở OpenBao transit, ADR-032); **HMAC có pepper** (băm HMAC-SHA256 với bí mật chung giữ ở OpenBao); **bản sao danh mục** (dữ liệu API đọc từ PH-02, chỉ đọc, kèm `source_version`); **xóa mềm** (đặt `deleted_at`, `removed_at`, BR-15-034).

### 0.3. Tài liệu tham chiếu

FRS D02-03-PH15 (§4.2, Phụ lục A); SDD D03-02-PH15 (Phụ lục A); D00-01 §5.1; D03-10; ADR-003, 032, 041, 047; mẫu D03-03-PH19.

### 0.4. Cấu trúc tài liệu

§1 chiến lược; §2 ERD; §3 đặc tả 35 bảng; §4 DDL, Liquibase, kiểm thử; §5 khởi tạo; §6 kho ngoài PostgreSQL; §7 sao lưu, mã hóa, lưu giữ; §8 hệ cũ; §9 câu hỏi mở; §10 đồng bộ.

## 1. Chiến lược lưu trữ

### 1.1. Cụm, schema, vai trò và kết nối

Bảng chốt nơi đặt dữ liệu và quyền.

| Thành phần | Giá trị | Căn cứ |
|---|---|---|
| Cụm | `pg-core` dùng chung (CloudNativePG, PostgreSQL 18, 1 primary, 2 standby), dịch vụ đọc `pg-core-ro` | D03-09, giả định cùng cụm với PH-02 vì dữ liệu cổng không thuộc nhóm tách riêng |
| Schema | `ph15_portal`, chủ `ph15_owner` (NOLOGIN, NOBYPASSRLS) | Quy ước `ph{nn}_{miền}` |
| Ứng dụng | `dh_portal_app`, thành viên `ph15_app`: DML theo §1.5, không DDL, không `BYPASSRLS`; các vai trò triển khai `portal`, `portal-sandbox`, `worker` dùng chung tài khoản, khác pool | SDD §3 |
| Migration | `dh_portal_migrator`, thành viên `ph15_owner`, chỉ chạy trong Job Liquibase, kết nối khởi tạo `SET ROLE ph15_owner` (changeset `ph15-0003-session`) | §4 |
| Bảo trì | `dh_portal_maint`, thành viên `ph15_owner`: tạo, tách phân vùng `try_run`, dọn dữ liệu hết hạn trên bảng không cho `DELETE` | §7.3 |
| Đọc báo cáo, kiểm toán | `ph15_readonly`: đọc mọi bảng trừ `app_credential` (thấy mọi cột trừ `key_hash`), `dev_account` (trừ `phone_enc`, `dek_wrapped`, `verification_token_hash`), `idempotency_record`, `shedlock` | D03-07 SEC-30…39 |

: Cụm, schema, vai trò và kết nối

Tiện ích `unaccent` cài ở schema `public` của cụm `pg-core`, dùng chung với các phân hệ khác (cài vào schema riêng sẽ bị bỏ qua khi phân hệ khác đã cài trước), phục vụ tìm kiếm dự phòng PG FTS không dấu (`15.search.engine = PG_FTS`); mặc định tìm ở OpenSearch (§6.4).

### 1.2. Cách ly tenant

Mọi bảng nghiệp vụ có `tenant_id` kiểu miền `ph15_portal.t_tenant` (`varchar(16)`, `CHECK ~ '^T[0-9]{2}$'`, ví dụ `T68`) và bật `FORCE ROW LEVEL SECURITY` qua `ph15_portal.p_enable_rls(bảng)` với một chính sách `FOR ALL` mẫu P (D03-10): đọc và ghi khi `tenant_id = current_setting('app.tenant_id', false)`. PH-15 **không có dữ liệu `COMMON`** và không có bảng định tuyến ngoại lệ như PH-19.

Tenant xác định từ tên miền cổng và token (BR-15-003); module `portal` đặt `app.tenant_id` bằng `SET LOCAL` đầu mỗi giao dịch. Phiên chưa đặt thì lỗi, kết nối cũ thì biến về rỗng và chính sách trả 0 dòng (ca 5). Khách ẩn danh đi cùng cơ chế: tenant từ tên miền, mức hiển thị lọc ở truy vấn (`visibility = PUBLIC`, `data_class = PUBLIC`, BR-15-005).

Danh mục quốc gia (mức `NATIONAL`, hạng `OTHER_TENANT_USER`): tác vụ đồng bộ nạp mục của tenant khác thành dòng thuộc tenant của cổng đang phục vụ, `tenant_id` là tenant của cổng, `origin_tenant_id` là tenant sở hữu API. Nhờ vậy RLS vẫn một điều kiện; đổi lại dữ liệu nhân bản theo số tỉnh xem (giả định ≤ 63 nhân 500 API).

### 1.3. Quy ước bảng

Theo D00-01 §5.1: khóa chính `id uuid` (UUID v7 sinh ở ứng dụng), `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (khóa lạc quan, thành phần của ETag; trigger `tg_touch` tăng khi ứng dụng không tăng). Thời điểm `timestamptz` UTC; mã vết `trace_id char(32)`; mã người dùng `varchar(64)` (chủ thể Keycloak hoặc `system:*`). Khóa ngoại luôn kép `(cột, tenant_id)` trỏ vào khóa duy nhất `(id, tenant_id)` để một dòng không trỏ được sang tenant khác. Xóa mềm bằng `deleted_at`, `removed_at`.

Ngoại lệ so với cột ngữ cảnh: `try_run` khóa chính `(id, executed_at)` (PostgreSQL yêu cầu khóa chính chứa khóa phân vùng) và không có `updated_*`, `version`; `dev_terms_acceptance`, `support_message`, `inbox_message`, `outbox_event` chỉ thêm nên bỏ `updated_*`, `version` (riêng `inbox_message` đổi cờ đọc); `sync_state`, `legacy_mapping`, `ticket_counter`, `inbox_event`, `idempotency_record` dùng khóa tự nhiên; `shedlock` không `tenant_id`, không RLS.

Giá trị `CHECK` của enum đúng Phụ lục A của FRS; thêm giá trị là một changeset mới và một đề nghị sửa FRS.

### 1.4. Danh mục bảng

Mỗi thực thể EN-15 có bảng.

| Mã | Bảng | Loại |
|---|---|---|
| EN-15-01 | `catalog_api`, `catalog_api_version` | Bản sao danh mục, xóa mềm |
| EN-15-02 | `catalog_spec` | Bản sao đặc tả |
| EN-15-03 | `sandbox_profile` | Cấu hình theo phiên bản |
| EN-15-13 | `try_prod_grant` | Cấu hình có hạn, bốn mắt |
| EN-15-04 | `content_page`, `content_attachment`, `content_git_source`, `content_migration` | Nội dung, tệp, nguồn Git, lô di trú |
| EN-15-05 | `content_page_version` | Phiên bản trang, bốn mắt |
| EN-15-06 | `dev_account` | Tài khoản, ẩn danh tại chỗ |
| EN-15-07 | `dev_team`, `dev_team_member` | Nhóm và lời mời |
| EN-15-16 | `dev_terms`, `dev_terms_acceptance` | Điều khoản và bằng chứng chấp nhận |
| EN-15-08 | `app`, `app_member` | Ứng dụng sandbox, xóa mềm |
| EN-15-09 | `app_credential` | Thông tin xác thực sandbox, không bí mật |
| EN-15-10 | `prod_credential_ref` | Bản sao tham chiếu từ PH-01 |
| EN-15-11 | `try_run` | Lượt thử, phân vùng tháng |
| EN-15-12 | `try_collection`, `try_collection_item` | Bộ sưu tập yêu cầu |
| EN-15-14 | `notification_subscription`, `inbox_message` | Theo dõi và hộp thông báo |
| EN-15-15 | `support_ticket`, `support_message`, `ticket_counter` | Phiếu hỗ trợ |
| EN-15-17 | `portal_setting` | Nhận diện cổng, một dòng mỗi tenant |
| EN-15-18 | `sync_state`, `sync_run` | Trạng thái và lần đồng bộ, đối soát |
| Kỹ thuật | `legacy_mapping` | Ánh xạ khóa hệ cũ |
| Kỹ thuật | `inbox_event`, `outbox_event`, `idempotency_record`, `shedlock` | Hộp thư, lũy đẳng, khóa tác vụ |

: Danh mục 35 bảng của schema ph15_portal

Tổng 35 bảng: 18 thực thể EN-15-01…18 trải trên 27 bảng, 8 bảng kỹ thuật. FR phục vụ từng bảng ở khối đặc tả §3.

### 1.5. Quyền của vai trò ứng dụng

Quyền của `ph15_app`: chỉ `SELECT`, `INSERT` trên `dev_terms_acceptance`, `support_message`; không `DELETE` trên `catalog_api`, `content_page`, `content_page_version`, `dev_account`, `dev_team`, `app`, `app_credential`, `support_ticket`, `dev_terms`, `portal_setting`, `legacy_mapping`, `content_migration`, `try_prod_grant`; đủ DML trên bảng còn lại (vẫn chịu CHECK và trigger). `try_run` bị xóa theo lô khi hết hạn hoặc khi người dùng xóa lịch sử của mình (FR-15-040).

Hai lớp chặn độc lập: thu hồi quyền (`insufficient_privilege`) và trigger. Dọn dữ liệu hết hạn của bảng không cho `DELETE` dùng `dh_portal_maint` (§7.3).

## 2. Sơ đồ thực thể – quan hệ

Ba sơ đồ theo miền; khóa ngoại đều kèm `tenant_id` (không vẽ); bảng kỹ thuật không vẽ.

### 2.1. Danh mục, nội dung, điều khoản

Miền gồm bản sao danh mục và nội dung.

```{.mermaid caption="ERD miền danh mục và nội dung"}
erDiagram
  catalog_api ||--o{ catalog_api_version : "có"
  catalog_api_version ||--o{ catalog_spec : "đặc tả"
  catalog_api_version ||--o| sandbox_profile : "hồ sơ thử"
  catalog_api ||--o| try_prod_grant : "cho phép thử thật"
  catalog_api ||--o{ content_page : "trang gắn API"
  content_page ||--o{ content_page_version : "phiên bản"
  content_page ||--o{ content_attachment : "ảnh"
  content_page_version ||--o| dev_terms : "bản điều khoản"
  content_migration ||--o{ legacy_mapping : "ánh xạ"
  content_migration }o--|| content_attachment : "gói ZIP"
```

Hình cho thấy `catalog_api` và các bảng con là bản sao từ PH-02 (chỉ tác vụ đồng bộ ghi), vòng đời nội dung nằm ở `content_page_version`, và `try_prod_grant` buộc theo API (một bản ghi mỗi API).

### 2.2. Tài khoản, ứng dụng, thử API

Miền gồm người, nhóm, ứng dụng và lượt thử.

```{.mermaid caption="ERD miền tài khoản, ứng dụng và lượt thử"}
erDiagram
  dev_account ||--o{ dev_team_member : "thành viên"
  dev_team ||--o{ dev_team_member : "gồm"
  dev_account ||--o{ dev_terms_acceptance : "chấp nhận"
  dev_terms ||--o{ dev_terms_acceptance : "bản"
  dev_account ||--o{ app : "sở hữu (USER)"
  dev_team ||--o{ app : "sở hữu (TEAM)"
  app ||--o{ app_member : "giao"
  dev_account ||--o{ app_member : "vai trò"
  app ||--o{ app_credential : "xác thực"
  app ||--o{ try_run : "thử"
  dev_account ||--o{ try_run : "người thử"
  dev_account ||--o{ try_collection : "bộ sưu tập"
  try_collection ||--o{ try_collection_item : "yêu cầu"
  dev_account ||--o{ notification_subscription : "theo dõi"
  dev_account ||--o{ inbox_message : "nhận"
```

Hình cho thấy ứng dụng thuộc đúng một chủ (`ck_app_owner`) và mọi lượt thử truy được về ứng dụng lẫn người thử.

### 2.3. Hỗ trợ, đồng bộ, di trú

Miền gồm phiếu hỗ trợ và các tác vụ nền.

```{.mermaid caption="ERD miền hỗ trợ, đồng bộ và di trú"}
erDiagram
  dev_account ||--o{ support_ticket : "gửi"
  support_ticket ||--o{ support_message : "tin nhắn"
  catalog_api ||--o{ support_ticket : "về API"
  content_page ||--o{ support_ticket : "về trang"
  content_git_source ||--o{ sync_run : "nhập Git"
  content_migration ||--o{ legacy_mapping : "lô"
  portal_setting }o--o| content_attachment : "logo"
```

Hình cho thấy phiếu hỗ trợ trỏ được tới API hoặc trang tài liệu, và đồng bộ Git, di trú đều để lại dấu vết chạy lại được.

## 3. Đặc tả bảng

Bảng cột sinh từ DDL; "Giá trị" là enum của Phụ lục A FRS lấy từ `CHECK`. Tên ràng buộc ở khối đặc tả bỏ tiền tố `ck_{bảng}_`. Quy tắc chốt ở CSDL ở §3.36; chỉ mục theo truy vấn chính (danh mục theo mức hiển thị, tìm không dấu bằng GIN, hàng đợi duyệt, lịch sử thử) nằm ở khối từng bảng.

<!-- gen:tables:start -->
### 3.1. `catalog_api`

::: dac-ta
**Mục đích.** EN-15-01 Mục danh mục: bản sao chỉ đọc của API và dịch vụ sự kiện từ PH-02.

**FR phục vụ.** FR-15-001…008, 013, 061.

**Khóa chính.** (id).

**Duy nhất.** `uq_catalog_api_code` (tenant_id, origin_tenant_id, api_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `code`, `kind`, `class`, `visibility`, `status`, `removed`, `sla`, `srcver`.

**Chỉ mục.** `ix_catalog_api_list`, `ix_catalog_api_domain`, `ix_catalog_api_tags`, `ix_catalog_api_tsv`, `ix_catalog_api_synced`.

**Cách ly tenant.** RLS FORCE, `rls_catalog_api_all`.

**Phân vùng, chỉ thêm, trigger.** Trigger: `tg_catalog_api_immutable` (tg_immutable_cols), `tg_catalog_api_tsv` (tg_catalog_api_tsv).
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `origin_tenant_id` | `varchar(16)` | x | Tenant sở hữu API; khác tenant_id khi mục đến từ danh mục quốc gia. |
| `api_code` | `varchar(64)` | x |  |
| `name` | `varchar(255)` | x |  |
| `summary` | `varchar(1000)` |  |  |
| `kind` | `varchar(8)` | x `'API'` | Giá trị: API, EVENT. |
| `owner_org_code` | `varchar(64)` |  |  |
| `provider_system_code` | `varchar(64)` |  |  |
| `field_domain` | `varchar(64)` |  |  |
| `auth_method` | `varchar(32)` |  |  |
| `data_class` | `varchar(12)` | x | Giá trị: PUBLIC, INTERNAL, RESTRICTED, SENSITIVE. |
| `visibility` | `varchar(12)` | x | Giá trị: TENANT, NATIONAL, PUBLIC. |
| `portal_published` | `boolean` | x `false` | Bản sao cờ portalPublished của PH-02 (FR-02-041). |
| `status` | `varchar(12)` | x `'PUBLISHED'` | Giá trị: PUBLISHED, DEPRECATED, SUSPENDED, RETIRED. |
| `tags` | `text[]` | x `'{}'` |  |
| `usage_path` | `varchar(512)` |  | Đường dẫn sử dụng gateway + context path. |
| `sla` | `jsonb` | x `'{}'` |  |
| `latest_version_no` | `varchar(32)` |  |  |
| `source_version` | `bigint` | x | sourceVersion của PH-02. |
| `synced_at` | `timestamptz` | x |  |
| `removed_at` | `timestamptz` |  | Đánh dấu mục thuộc removed[] của PH-02 (xóa mềm). |
| `search_tsv` | `tsvector` |  | tsvector không dấu. |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `catalog_api`

### 3.2. `catalog_api_version`

::: dac-ta
**Mục đích.** EN-15-01 Phiên bản API của bản sao danh mục: trạng thái PUBLISHED, DEPRECATED, SUSPENDED, RETIRED, kế nhiệm, hạn ngừng, thay đổi phá vỡ.

**FR phục vụ.** FR-15-006, 011, 013, 061.

**Khóa chính.** (id).

**Duy nhất.** `uq_catalog_api_version_no` (tenant_id, api_id, version_no).

**Khóa ngoại.** api_id → `catalog_api`.

**Ràng buộc CHECK.** `no`, `status`, `hash`, `sunset`.

**Chỉ mục.** `ix_catalog_api_version_api`.

**Cách ly tenant.** RLS FORCE, `rls_catalog_api_version_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `api_id` | `uuid` | x |  |
| `version_no` | `varchar(32)` | x |  |
| `status` | `varchar(12)` | x `'PUBLISHED'` | Giá trị: PUBLISHED, DEPRECATED, SUSPENDED, RETIRED. |
| `spec_hash` | `char(64)` |  | Băm nội dung đặc tả hiện hành của phiên bản. |
| `successor_version_no` | `varchar(32)` |  | Phiên bản kế nhiệm của PH-02. |
| `sunset_at` | `timestamptz` |  |  |
| `breaking` | `boolean` | x `false` |  |
| `changelog_md` | `text` |  |  |
| `source_version` | `bigint` | x |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `catalog_api_version`

### 3.3. `catalog_spec`

::: dac-ta
**Mục đích.** EN-15-02 Đặc tả đã nạp: một dòng cho mỗi phiên bản API và loại đặc tả OPENAPI, ASYNCAPI.

**FR phục vụ.** FR-15-009…012.

**Khóa chính.** (id).

**Duy nhất.** `uq_catalog_spec_kind` (tenant_id, version_id, spec_kind).

**Khóa ngoại.** version_id → `catalog_api_version`.

**Ràng buộc CHECK.** `kind`, `hash`, `size`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, `rls_catalog_spec_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `version_id` | `uuid` | x |  |
| `spec_kind` | `varchar(10)` | x | Giá trị: OPENAPI, ASYNCAPI. |
| `content_hash` | `char(64)` | x |  |
| `model_json` | `jsonb` |  | Mô hình đã phân tích. |
| `size_bytes` | `integer` | x |  |
| `object_key` | `varchar(512)` |  | Khóa đối tượng của bản đặc tả đã kết xuất. |
| `loaded_at` | `timestamptz` | x `now()` |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `catalog_spec`

### 3.4. `sandbox_profile`

::: dac-ta
**Mục đích.** EN-15-03 Hồ sơ sandbox của dịch vụ: chế độ MOCK, BACKEND hoặc OFF theo từng phiên bản API.

**FR phục vụ.** FR-15-034, 036, 037.

**Khóa chính.** (id).

**Duy nhất.** `uq_sandbox_profile_version` (tenant_id, version_id).

**Khóa ngoại.** version_id → `catalog_api_version`.

**Ràng buộc CHECK.** `mode`, `policy`, `backend`, `url`, `overrides`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, `rls_sandbox_profile_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `version_id` | `uuid` | x |  |
| `mode` | `varchar(8)` | x `'OFF'` | Giá trị: MOCK, BACKEND, OFF. |
| `backend_url` | `varchar(2048)` |  | Backend thử do chủ dịch vụ khai báo. |
| `example_policy` | `varchar(8)` | x `'FIRST'` | Giá trị: FIRST, RANDOM. |
| `mock_overrides` | `jsonb` | x `'{}'` |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `sandbox_profile`

### 3.5. `try_prod_grant`

::: dac-ta
**Mục đích.** EN-15-13 Cho phép thử production theo dịch vụ, mặc định OFF, bốn mắt, tối đa 90 ngày.

**FR phục vụ.** FR-15-042, 043.

**Khóa chính.** (id).

**Duy nhất.** `uq_try_prod_grant_entry` (tenant_id, api_id).

**Khóa ngoại.** api_id → `catalog_api`.

**Ràng buộc CHECK.** `status`, `pending`, `four_eyes`, `ttl`.

**Chỉ mục.** `ix_try_prod_grant_expiry`.

**Cách ly tenant.** RLS FORCE, `rls_try_prod_grant_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `api_id` | `uuid` | x |  |
| `status` | `varchar(8)` | x `'OFF'` | Giá trị: OFF, PENDING, ENABLED, EXPIRED. |
| `allow_write` | `boolean` | x `false` | Luôn false ở Đợt 2 (BR-15-020: chỉ GET, HEAD). |
| `proposed_by` | `varchar(64)` |  |  |
| `proposed_at` | `timestamptz` |  |  |
| `approved_by` | `varchar(64)` |  |  |
| `approved_at` | `timestamptz` |  |  |
| `valid_until` | `timestamptz` |  |  |
| `reason` | `varchar(1000)` |  |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `try_prod_grant`

### 3.6. `content_page`

::: dac-ta
**Mục đích.** EN-15-04 Trang nội dung Markdown: hướng dẫn, bắt đầu nhanh, hỏi đáp, thông báo, điều khoản.

**FR phục vụ.** FR-15-014…018, 062.

**Khóa chính.** (id).

**Duy nhất.** `uq_content_page_code` (tenant_id, page_code, lang).

**Khóa ngoại.** api_id → `catalog_api`.

**Ràng buộc CHECK.** `code`, `lang`, `type`, `audience`, `status`, `source`, `published`.

**Chỉ mục.** `ix_content_page_list`, `ix_content_page_entry`, `ix_content_page_tsv`.

**Cách ly tenant.** RLS FORCE, `rls_content_page_all`.

**Phân vùng, chỉ thêm, trigger.** Trigger: `tg_content_page_immutable` (tg_immutable_cols), `tg_content_page_tsv` (tg_content_page_tsv).
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `page_code` | `varchar(63)` | x |  |
| `lang` | `varchar(2)` | x `'vi'` | Giá trị: vi, en. |
| `type` | `varchar(12)` | x | Giá trị: GUIDE, QUICKSTART, FAQ, ANNOUNCEMENT, TERMS. |
| `audience` | `varchar(10)` | x `'LOGGED_IN'` | Giá trị: PUBLIC, LOGGED_IN, TENANT. |
| `title` | `varchar(255)` | x |  |
| `status` | `varchar(12)` | x `'DRAFT'` | Giá trị: DRAFT, PUBLISHED, UNPUBLISHED, ARCHIVED. |
| `published_version_id` | `uuid` |  | Phiên bản đang hiển thị. |
| `api_id` | `uuid` |  |  |
| `tags` | `text[]` | x `'{}'` |  |
| `source` | `varchar(10)` | x `'MANUAL'` | Giá trị: MANUAL, GIT, MIGRATION. |
| `source_ref` | `varchar(512)` |  | Với source = GIT: đường dẫn tệp trong kho. |
| `search_tsv` | `tsvector` |  |  |
| `deleted_at` | `timestamptz` |  |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `content_page`

### 3.7. `content_page_version`

::: dac-ta
**Mục đích.** EN-15-05 Phiên bản trang: nội dung Markdown, vòng đời soạn, duyệt, đăng bốn mắt.

**FR phục vụ.** FR-15-014…016, 018, 062.

**Khóa chính.** (id).

**Duy nhất.** `uq_content_page_version_no` (tenant_id, page_id, version_no), `uq_content_page_version_published` (tenant_id, page_id).

**Khóa ngoại.** page_id → `content_page`.

**Ràng buộc CHECK.** `no`, `size`, `hash`, `status`, `submit`, `four_eyes`.

**Chỉ mục.** `ix_content_page_version_queue`, `ix_content_page_version_migration`.

**Cách ly tenant.** RLS FORCE, `rls_content_page_version_all`.

**Phân vùng, chỉ thêm, trigger.** Trigger: `tg_content_page_version_body` (tg_version_body_guard).
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `page_id` | `uuid` | x |  |
| `version_no` | `integer` | x |  |
| `body_md` | `text` | x | Markdown đã qua bộ lọc BR-15-013 ở ứng dụng. |
| `content_hash` | `char(64)` | x |  |
| `status` | `varchar(12)` | x `'DRAFT'` | Giá trị: DRAFT, IN_REVIEW, REJECTED, PUBLISHED, SUPERSEDED, UNPUBLISHED. |
| `last_edited_by` | `varchar(64)` | x | Người sửa gần nhất. |
| `submitted_by` | `varchar(64)` |  |  |
| `submitted_at` | `timestamptz` |  |  |
| `reviewed_by` | `varchar(64)` |  |  |
| `reviewed_at` | `timestamptz` |  |  |
| `review_note` | `varchar(1000)` |  |  |
| `published_at` | `timestamptz` |  |  |
| `source_commit` | `varchar(64)` |  |  |
| `migration_id` | `uuid` |  |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `content_page_version`

### 3.8. `content_attachment`

::: dac-ta
**Mục đích.** Siêu dữ liệu đối tượng trong kho Garage: ảnh trang, logo, gói di trú, bản gốc đặc tả.

**FR phục vụ.** FR-15-014, 017, 018, 056, 062.

**Khóa chính.** (id).

**Duy nhất.** `uq_content_attachment_object` (bucket, object_key).

**Khóa ngoại.** page_id → `content_page`.

**Ràng buộc CHECK.** `purpose`, `scan`, `hash`, `bucket`, `image`, `logo`, `package`.

**Chỉ mục.** `ix_content_attachment_page`, `ix_content_attachment_expiry`.

**Cách ly tenant.** RLS FORCE, `rls_content_attachment_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `purpose` | `varchar(20)` | x | Giá trị: PAGE_IMAGE, LOGO, MIGRATION_PACKAGE. |
| `bucket` | `varchar(63)` | x |  |
| `object_key` | `varchar(512)` | x |  |
| `file_name` | `varchar(255)` | x |  |
| `mime_type` | `varchar(64)` | x | Giá trị: image/png, image/jpeg, image/webp. |
| `size_bytes` | `bigint` | x |  |
| `sha256` | `char(64)` | x |  |
| `scan_status` | `varchar(10)` | x `'PENDING'` | Kết quả quét mã độc. Giá trị: PENDING, CLEAN, INFECTED. |
| `page_id` | `uuid` |  |  |
| `migration_id` | `uuid` |  |  |
| `expires_at` | `timestamptz` |  |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `content_attachment`

### 3.9. `content_git_source`

::: dac-ta
**Mục đích.** Nguồn Git cho tài liệu tích hợp: chỉ tham chiếu mã truy cập đã ghi một chiều vào OpenBao, không lưu bí mật.

**FR phục vụ.** FR-15-018.

**Khóa chính.** (id).

**Duy nhất.** `uq_content_git_source_repo` (tenant_id, repo_url, branch, path).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `url`, `secret`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, `rls_content_git_source_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `name` | `varchar(128)` | x |  |
| `repo_url` | `varchar(512)` | x |  |
| `branch` | `varchar(128)` | x `'main'` |  |
| `path` | `varchar(255)` | x `'docs/'` |  |
| `secret_ref` | `varchar(512)` |  | Đường dẫn OpenBao của mã truy cập chỉ đọc. |
| `enabled` | `boolean` | x `true` |  |
| `last_commit` | `varchar(64)` |  |  |
| `last_synced_at` | `timestamptz` |  |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `content_git_source`

### 3.10. `dev_account`

::: dac-ta
**Mục đích.** EN-15-06 Tài khoản nhà phát triển: dh-dev (vòng đời đầy đủ) và bản ghi tạo khi cán bộ SSO đăng nhập lần đầu.

**FR phục vụ.** FR-15-019…021, 024, 058, 059.

**Khóa chính.** (id).

**Duy nhất.** `uq_dev_account_user` (tenant_id, user_id), `uq_dev_account_email` (tenant_id, source, email).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `source`, `status`, `sso_state`, `email_case`, `email_erased`, `approved`, `phone`, `token`, `erased`.

**Chỉ mục.** `ix_dev_account_queue`, `ix_dev_account_idle`.

**Cách ly tenant.** RLS FORCE, `rls_dev_account_all`.

**Phân vùng, chỉ thêm, trigger.** Không.

**Ghi chú.** Cột `phone_enc` mã hóa envelope (ADR-032); vai trò chỉ đọc không thấy `phone_enc`, `dek_wrapped`, `verification_token_hash`.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `user_id` | `varchar(64)` | x | Chủ thể. |
| `source` | `varchar(12)` | x | Giá trị: TENANT_SSO, DH_DEV. |
| `status` | `varchar(16)` | x | Giá trị: PENDING_EMAIL, PENDING_APPROVAL, ACTIVE, REJECTED, LOCKED, DISABLED, EXPIRED, ERASED. |
| `email` | `varchar(254)` |  |  |
| `full_name` | `varchar(255)` | x |  |
| `organization` | `varchar(255)` |  |  |
| `contract_no` | `varchar(64)` |  |  |
| `sponsor_unit` | `varchar(255)` |  |  |
| `phone_enc` | `bytea` |  | Điện thoại. |
| `dek_wrapped` | `bytea` |  |  |
| `verification_token_hash` | `char(64)` |  | SHA-256 của mã xác minh thư. |
| `verification_expires_at` | `timestamptz` |  |  |
| `email_verified_at` | `timestamptz` |  |  |
| `approved_by` | `varchar(64)` |  |  |
| `approved_at` | `timestamptz` |  |  |
| `decision_reason` | `varchar(1000)` |  |  |
| `last_active_at` | `timestamptz` |  |  |
| `anonymized_at` | `timestamptz` |  | Thời điểm ẩn danh. |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `dev_account`

### 3.11. `dev_team`

::: dac-ta
**Mục đích.** EN-15-07 Nhóm phát triển.

**FR phục vụ.** FR-15-022.

**Khóa chính.** (id).

**Duy nhất.** `uq_dev_team_code` (tenant_id, team_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `code`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, `rls_dev_team_all`.

**Phân vùng, chỉ thêm, trigger.** Trigger: `tg_dev_team_immutable` (tg_immutable_cols).
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `team_code` | `varchar(41)` | x |  |
| `name` | `varchar(255)` | x |  |
| `description` | `varchar(1000)` |  |  |
| `deleted_at` | `timestamptz` |  |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `dev_team`

### 3.12. `dev_team_member`

::: dac-ta
**Mục đích.** EN-15-07 Thành viên nhóm và lời mời (PENDING, ACCEPTED, DECLINED, EXPIRED) với vai trò OWNER, DEVELOPER, VIEWER.

**FR phục vụ.** FR-15-022, 033.

**Khóa chính.** (id).

**Duy nhất.** `uq_dev_team_member` (team_id, account_id).

**Khóa ngoại.** team_id → `dev_team`, account_id → `dev_account`.

**Ràng buộc CHECK.** `role`, `invite`, `owner`.

**Chỉ mục.** `ix_dev_team_member_account`.

**Cách ly tenant.** RLS FORCE, `rls_dev_team_member_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `team_id` | `uuid` | x |  |
| `account_id` | `uuid` | x |  |
| `role` | `varchar(10)` | x `'DEVELOPER'` | Giá trị: OWNER, DEVELOPER, VIEWER. |
| `invite_status` | `varchar(10)` | x `'PENDING'` | Giá trị: PENDING, ACCEPTED, DECLINED, EXPIRED. |
| `invited_by` | `varchar(64)` |  |  |
| `invite_expires_at` | `timestamptz` |  |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `dev_team_member`

### 3.13. `dev_terms`

::: dac-ta
**Mục đích.** EN-15-16 Điều khoản sử dụng có phiên bản: tham chiếu phiên bản trang loại TERMS đã đăng; băm nội dung để chứng minh người dùng chấp nhận đúng văn bản.

**FR phục vụ.** FR-15-023.

**Khóa chính.** (id).

**Duy nhất.** `uq_dev_terms_label` (tenant_id, version_label).

**Khóa ngoại.** page_version_id → `content_page_version`.

**Ràng buộc CHECK.** `hash`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, `rls_dev_terms_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `version_label` | `varchar(32)` | x |  |
| `page_version_id` | `uuid` | x |  |
| `content_hash` | `char(64)` | x |  |
| `effective_from` | `timestamptz` | x |  |
| `retired_at` | `timestamptz` |  |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `dev_terms`

### 3.14. `dev_terms_acceptance`

::: dac-ta
**Mục đích.** EN-15-16 Bằng chứng chấp nhận điều khoản theo người dùng; chỉ thêm, không sửa.

**FR phục vụ.** FR-15-023, 025, 035.

**Khóa chính.** (id).

**Duy nhất.** `uq_dev_terms_acceptance` (account_id, terms_id).

**Khóa ngoại.** account_id → `dev_account`, terms_id → `dev_terms`.

**Ràng buộc CHECK.** `ip`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, `rls_dev_terms_acceptance_all`.

**Phân vùng, chỉ thêm, trigger.** Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_dev_terms_acceptance_ro`).

**Ghi chú.** Bằng chứng pháp lý nên bất biến: cả quyền UPDATE, DELETE bị thu hồi lẫn trigger chặn.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `account_id` | `uuid` | x |  |
| `terms_id` | `uuid` | x |  |
| `accepted_at` | `timestamptz` | x `now()` |  |
| `client_ip_hash` | `char(64)` |  |  |
| `created_at` | `timestamptz` | x `now()` |  |
| `created_by` | `varchar(64)` | x |  |

: Cột của bảng `dev_terms_acceptance`

### 3.15. `app`

::: dac-ta
**Mục đích.** EN-15-08 Ứng dụng sandbox của một người hoặc một nhóm.

**FR phục vụ.** FR-15-025, 026, 033, 059.

**Khóa chính.** (id).

**Duy nhất.** `uq_app_code` (tenant_id, app_code).

**Khóa ngoại.** owner_account_id → `dev_account`, owner_team_id → `dev_team`.

**Ràng buộc CHECK.** `code`, `owner_type`, `owner`, `status`, `archived`, `quota`.

**Chỉ mục.** `ix_app_owner_user`, `ix_app_owner_team`, `ix_app_idle`, `ix_app_purge`.

**Cách ly tenant.** RLS FORCE, `rls_app_all`.

**Phân vùng, chỉ thêm, trigger.** Trigger: `tg_app_immutable` (tg_immutable_cols).
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `app_code` | `varchar(41)` | x |  |
| `name` | `varchar(255)` | x |  |
| `description` | `varchar(1000)` |  |  |
| `owner_type` | `varchar(4)` | x | Giá trị: USER, TEAM. |
| `owner_account_id` | `uuid` |  |  |
| `owner_team_id` | `uuid` |  |  |
| `status` | `varchar(10)` | x `'ACTIVE'` | Giá trị: ACTIVE, SUSPENDED, ARCHIVED. |
| `status_reason` | `varchar(1000)` |  |  |
| `linked_system_code` | `varchar(64)` |  | Mã HTTT. |
| `daily_quota_override` | `integer` |  | Hạn mức lượt thử mỗi ngày riêng của ứng dụng. |
| `last_used_at` | `timestamptz` |  |  |
| `archived_at` | `timestamptz` |  |  |
| `deleted_at` | `timestamptz` |  |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `app`

### 3.16. `app_member`

::: dac-ta
**Mục đích.** Giao ứng dụng cho thành viên với vai trò OWNER, DEVELOPER, VIEWER; PERM-15-app và PERM-15-try chỉ áp trên ứng dụng mà người dùng là thành viên.

**FR phục vụ.** FR-15-033, 048…050.

**Khóa chính.** (id).

**Duy nhất.** `uq_app_member` (app_id, account_id).

**Khóa ngoại.** app_id → `app`, account_id → `dev_account`.

**Ràng buộc CHECK.** `role`.

**Chỉ mục.** `ix_app_member_account`.

**Cách ly tenant.** RLS FORCE, `rls_app_member_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `app_id` | `uuid` | x |  |
| `account_id` | `uuid` | x |  |
| `role` | `varchar(10)` | x `'DEVELOPER'` | Giá trị: OWNER, DEVELOPER, VIEWER. |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `app_member`

### 3.17. `app_credential`

::: dac-ta
**Mục đích.** EN-15-09 Thông tin xác thực sandbox: client_credentials ở realm dh-dev hoặc API key sandbox.

**FR phục vụ.** FR-15-027…031.

**Khóa chính.** (id).

**Duy nhất.** `uq_app_credential_client` (client_id), `uq_app_credential_prefix` (tenant_id, key_prefix).

**Khóa ngoại.** app_id → `app`, rotated_from_id → `app_credential`.

**Ràng buộc CHECK.** `prov`, `kind`, `status`, `client`, `ttl`, `revoked`, `grace`, `prefix`, `active`.

**Chỉ mục.** `ix_app_credential_app`, `ix_app_credential_expiry`.

**Cách ly tenant.** RLS FORCE, `rls_app_credential_all`.

**Phân vùng, chỉ thêm, trigger.** Không.

**Ghi chú.** Không có cột bí mật: chỉ tiền tố 8 ký tự và băm (BR-15-011); vai trò chỉ đọc không thấy `key_hash`.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `app_id` | `uuid` | x |  |
| `kind` | `varchar(20)` | x | Giá trị: CLIENT_CREDENTIALS, API_KEY. |
| `status` | `varchar(8)` | x `'ACTIVE'` | Giá trị: ACTIVE, ROTATING, REVOKED, EXPIRED. |
| `provisioning_state` | `varchar(14)` | x `'PENDING'` | Trạng thái saga cấp phát ở Keycloak realm dh-dev hoặc kho khóa: PENDING. Giá trị: PENDING, PROVISIONED, FAILED, DEPROVISIONING. |
| `client_id` | `varchar(128)` |  |  |
| `keycloak_client_uuid` | `varchar(64)` |  |  |
| `key_prefix` | `char(8)` | x |  |
| `key_hash` | `char(64)` |  | HMAC-SHA256. |
| `expires_at` | `timestamptz` | x | Tối đa 180 ngày kể từ lúc cấp (SEC-24). |
| `rotated_from_id` | `uuid` |  |  |
| `grace_until` | `timestamptz` |  | Hết thời gian chuyển tiếp khi xoay vòng. |
| `revoked_at` | `timestamptz` |  |  |
| `revoke_reason` | `varchar(200)` |  |  |
| `last_used_at` | `timestamptz` |  |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `app_credential`

### 3.18. `prod_credential_ref`

::: dac-ta
**Mục đích.** EN-15-10 Tham chiếu thông tin xác thực production, bản sao chỉ đọc từ PH-01: không có cột bí mật; dấu vân tay chỉ 16 ký tự đầu.

**FR phục vụ.** FR-15-032.

**Khóa chính.** (id).

**Duy nhất.** `uq_prod_credential_ref` (tenant_id, system_code, client_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `method`, `status`, `fp`.

**Chỉ mục.** `ix_prod_credential_ref_system`.

**Cách ly tenant.** RLS FORCE, `rls_prod_credential_ref_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `system_code` | `varchar(64)` | x |  |
| `client_id` | `varchar(128)` | x |  |
| `auth_method` | `varchar(24)` | x | Giá trị: tls_client_auth, private_key_jwt, client_secret_basic. |
| `fingerprint_prefix` | `char(16)` |  |  |
| `expires_at` | `timestamptz` |  |  |
| `status` | `varchar(8)` | x `'ACTIVE'` | Giá trị: ACTIVE, EXPIRING, REVOKED. |
| `source_version` | `bigint` | x `0` |  |
| `synced_at` | `timestamptz` | x |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `prod_credential_ref`

### 3.19. `try_run`

::: dac-ta
**Mục đích.** EN-15-11 Lượt thử API: siêu dữ liệu và, với SANDBOX, bản yêu cầu đã quét PII-15 để gửi lại. Không thân phản hồi, không tiêu đề xác thực.

**FR phục vụ.** FR-15-035…043, 049, 060.

**Khóa chính.** (id, executed_at).

**Duy nhất.** Không.

**Khóa ngoại.** app_id → `app`, account_id → `dev_account`, api_id → `catalog_api`.

**Ràng buộc CHECK.** `method`, `env`, `mode`, `result`, `trace`, `latency`, `prod`, `sandbox`, `snapshot`.

**Chỉ mục.** `ix_try_run_account`, `ix_try_run_app`, `ix_try_run_entry`, `ix_try_run_trace`.

**Cách ly tenant.** RLS FORCE, `rls_try_run_all`.

**Phân vùng, chỉ thêm, trigger.** Phân vùng RANGE theo tháng trên `executed_at` (thủ tục `p_ensure_month_partitions`), dọn bằng DETACH PARTITION.

**Ghi chú.** Dọn theo tham số `15.try.history-days` bằng DELETE theo lô; phân vùng quá 90 ngày thì DETACH rồi DROP.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `app_id` | `uuid` | x |  |
| `account_id` | `uuid` | x |  |
| `api_id` | `uuid` | x |  |
| `version_no` | `varchar(32)` | x |  |
| `method` | `varchar(7)` | x | Giá trị: GET, HEAD, POST, PUT, PATCH, DELETE. |
| `path_template` | `varchar(512)` | x | Đường dẫn dạng mẫu /ho-tich/{id}. |
| `environment` | `varchar(10)` | x | Giá trị: SANDBOX, PRODUCTION. |
| `sandbox_mode` | `varchar(8)` |  |  |
| `result` | `varchar(14)` | x | Giá trị: OK, UPSTREAM_ERROR, DENIED, THROTTLED, TIMEOUT. |
| `http_status` | `smallint` |  |  |
| `latency_ms` | `integer` |  |  |
| `trace_id` | `char(32)` | x |  |
| `request_snapshot` | `jsonb` |  | Chỉ lượt SANDBOX: phương thức. |
| `executed_at` | `timestamptz` | x `now()` |  |

: Cột của bảng `try_run`

### 3.20. `try_collection`

::: dac-ta
**Mục đích.** EN-15-12 Bộ sưu tập yêu cầu của người dùng, tối đa 50 bộ (trigger tg_collection_limit; ERR-15-003). Chia sẻ cho nhóm là Đợt 3 (Q15-12).

**FR phục vụ.** FR-15-040, 041.

**Khóa chính.** (id).

**Duy nhất.** `uq_try_collection_name` (account_id, name).

**Khóa ngoại.** account_id → `dev_account`.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, `rls_try_collection_all`.

**Phân vùng, chỉ thêm, trigger.** Trigger: `tg_try_collection_limit` (tg_collection_limit).
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `account_id` | `uuid` | x |  |
| `name` | `varchar(128)` | x |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `try_collection`

### 3.21. `try_collection_item`

::: dac-ta
**Mục đích.** Yêu cầu mẫu trong bộ sưu tập, tối đa 100 mỗi bộ và 16 KB mỗi yêu cầu; chỉ nội dung tổng hợp đã quét PII-15.

**FR phục vụ.** FR-15-040, 041.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** collection_id → `try_collection` xóa theo, api_id → `catalog_api`.

**Ràng buộc CHECK.** `spec`.

**Chỉ mục.** `ix_try_collection_item_collection`.

**Cách ly tenant.** RLS FORCE, `rls_try_collection_item_all`.

**Phân vùng, chỉ thêm, trigger.** Trigger: `tg_try_collection_item_limit` (tg_collection_limit).
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `collection_id` | `uuid` | x |  |
| `api_id` | `uuid` |  |  |
| `position` | `integer` | x `0` |  |
| `name` | `varchar(128)` | x |  |
| `request_spec` | `jsonb` | x |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `try_collection_item`

### 3.22. `notification_subscription`

::: dac-ta
**Mục đích.** EN-15-14 Theo dõi thay đổi API: INFO do người dùng bật tắt; MANDATORY (ngừng khuyến nghị, tạm ngừng, ngừng hẳn, SLA kém đi, thay đổi phá vỡ) hệ thống tạo và không xóa được.

**FR phục vụ.** FR-15-051.

**Khóa chính.** (id).

**Duy nhất.** `uq_notification_subscription` (account_id, api_id, channel, kind).

**Khóa ngoại.** account_id → `dev_account`, api_id → `catalog_api`.

**Ràng buộc CHECK.** `channel`, `kind`.

**Chỉ mục.** `ix_notification_subscription_entry`.

**Cách ly tenant.** RLS FORCE, `rls_notification_subscription_all`.

**Phân vùng, chỉ thêm, trigger.** Trigger: `tg_notification_subscription_mandatory` (tg_mandatory_watch_guard).
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `account_id` | `uuid` | x |  |
| `api_id` | `uuid` | x |  |
| `channel` | `varchar(6)` | x | Giá trị: IN_APP, EMAIL. |
| `kind` | `varchar(9)` | x `'INFO'` | Giá trị: MANDATORY, INFO. |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `notification_subscription`

### 3.23. `inbox_message`

::: dac-ta
**Mục đích.** Hộp thông báo: một dòng cho mỗi người nhận và kênh; chống gửi trùng nhờ khóa duy nhất theo sự kiện nguồn (EVT-02-12).

**FR phục vụ.** FR-15-051, 052.

**Khóa chính.** (id).

**Duy nhất.** `uq_inbox_message_event` (account_id, source_event_id, channel).

**Khóa ngoại.** account_id → `dev_account`, api_id → `catalog_api`.

**Ràng buộc CHECK.** `channel`, `kind`.

**Chỉ mục.** `ix_inbox_message_unread`.

**Cách ly tenant.** RLS FORCE, `rls_inbox_message_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `account_id` | `uuid` | x |  |
| `channel` | `varchar(6)` | x `'IN_APP'` | Giá trị: IN_APP, EMAIL. |
| `kind` | `varchar(9)` | x `'INFO'` | Giá trị: MANDATORY, INFO. |
| `api_id` | `uuid` |  |  |
| `title` | `varchar(255)` | x |  |
| `body` | `varchar(2000)` |  |  |
| `link_path` | `varchar(512)` |  |  |
| `source_event_id` | `uuid` |  |  |
| `delivered_at` | `timestamptz` |  |  |
| `read_at` | `timestamptz` |  |  |
| `created_at` | `timestamptz` | x `now()` |  |
| `created_by` | `varchar(64)` | x |  |

: Cột của bảng `inbox_message`

### 3.24. `support_ticket`

::: dac-ta
**Mục đích.** EN-15-15 Phiếu hỗ trợ: hỏi đáp theo API, báo lỗi tài liệu, yêu cầu hỗ trợ, yêu cầu truy cập, đánh giá.

**FR phục vụ.** FR-15-053…055.

**Khóa chính.** (id).

**Duy nhất.** `uq_support_ticket_code` (tenant_id, ticket_code).

**Khóa ngoại.** api_id → `catalog_api`, page_id → `content_page`, requester_id → `dev_account`.

**Ràng buộc CHECK.** `code`, `kind`, `status`, `rating`, `resolved`.

**Chỉ mục.** `ix_support_ticket_inbox`, `ix_support_ticket_requester`, `ix_support_ticket_sla`.

**Cách ly tenant.** RLS FORCE, `rls_support_ticket_all`.

**Phân vùng, chỉ thêm, trigger.** Trigger: `tg_support_ticket_immutable` (tg_immutable_cols).
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `ticket_code` | `varchar(16)` | x |  |
| `kind` | `varchar(16)` | x | Giá trị: QUESTION, DOC_ERROR, SUPPORT_REQUEST, ACCESS_REQUEST, FEEDBACK. |
| `status` | `varchar(8)` | x `'OPEN'` | Giá trị: OPEN, ANSWERED, RESOLVED, CLOSED. |
| `api_id` | `uuid` |  |  |
| `page_id` | `uuid` |  |  |
| `requester_id` | `uuid` | x |  |
| `assignee_org_code` | `varchar(64)` |  | Đầu mối của chủ dịch vụ (owner_org_code của API). |
| `assignee_user_id` | `varchar(64)` |  |  |
| `subject` | `varchar(255)` | x |  |
| `body` | `varchar(4000)` | x |  |
| `rating` | `smallint` |  |  |
| `first_response_due_at` | `timestamptz` |  | Hạn phản hồi đầu = tạo + 15.support.sla-hours. |
| `first_responded_at` | `timestamptz` |  |  |
| `resolved_at` | `timestamptz` |  |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `support_ticket`

### 3.25. `support_message`

::: dac-ta
**Mục đích.** Chuỗi tin trong phiếu hỗ trợ; chỉ thêm, giữ nguyên lịch sử xử lý.

**FR phục vụ.** FR-15-054, 055.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** ticket_id → `support_ticket`.

**Ràng buộc CHECK.** `side`.

**Chỉ mục.** `ix_support_message_ticket`.

**Cách ly tenant.** RLS FORCE, `rls_support_message_all`.

**Phân vùng, chỉ thêm, trigger.** Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_support_message_ro`).

**Ghi chú.** Lịch sử xử lý phiếu chỉ được nối thêm; sửa nội dung bằng tin nhắn mới.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `ticket_id` | `uuid` | x |  |
| `author_id` | `varchar(64)` | x |  |
| `author_side` | `varchar(9)` | x | Giá trị: REQUESTER, HANDLER. |
| `body` | `varchar(4000)` | x |  |
| `created_at` | `timestamptz` | x `now()` |  |
| `created_by` | `varchar(64)` | x |  |

: Cột của bảng `support_message`

### 3.26. `ticket_counter`

::: dac-ta
**Mục đích.** Bộ đếm số phiếu theo tenant và năm cho ticketCode HT-{năm}-{số}; tăng trong cùng giao dịch tạo phiếu.

**FR phục vụ.** FR-15-054.

**Khóa chính.** (tenant_id, year).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `no`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, `rls_ticket_counter_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `tenant_id` | `varchar(16)` | x | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `year` | `smallint` | x |  |
| `last_no` | `integer` | x `0` |  |

: Cột của bảng `ticket_counter`

### 3.27. `portal_setting`

::: dac-ta
**Mục đích.** EN-15-17 Nhận diện cổng theo tenant, một dòng mỗi tenant: tên, lời chào, logo, liên kết, chân trang.

**FR phục vụ.** FR-15-056, 057.

**Khóa chính.** (id).

**Duy nhất.** `uq_portal_setting_tenant` (tenant_id).

**Khóa ngoại.** logo_file_id → `content_attachment`.

**Ràng buộc CHECK.** `links`, `params`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, `rls_portal_setting_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `portal_name` | `varchar(255)` | x |  |
| `greeting` | `varchar(500)` |  |  |
| `logo_file_id` | `uuid` |  |  |
| `links` | `jsonb` | x `'[]'` |  |
| `footer_md` | `varchar(2000)` |  |  |
| `param_cache` | `jsonb` | x `'{}'` | Bản sao các tham số 15.* đọc từ PH-18. |
| `param_synced_at` | `timestamptz` |  |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `portal_setting`

### 3.28. `sync_state`

::: dac-ta
**Mục đích.** Trạng thái đồng bộ danh mục của tenant (IDLE, RUNNING, FAILED, STALE) và con trỏ updatedSince; phát EVT-15-14 khi đổi.

**FR phục vụ.** FR-15-001, 061.

**Khóa chính.** (tenant_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `state`, `lag`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, `rls_sync_state_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `tenant_id` | `varchar(16)` | x | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `state` | `varchar(8)` | x `'IDLE'` | Giá trị: IDLE, RUNNING, FAILED, STALE. |
| `updated_since` | `timestamptz` |  |  |
| `last_success_at` | `timestamptz` |  |  |
| `last_event_at` | `timestamptz` |  |  |
| `lag_seconds` | `integer` | x `0` |  |
| `last_error` | `varchar(1000)` |  |  |
| `updated_at` | `timestamptz` | x `now()` |  |

: Cột của bảng `sync_state`

### 3.29. `sync_run`

::: dac-ta
**Mục đích.** EN-15-18 Lần đồng bộ: gia tăng, đầy đủ, đối soát với PH-02, nhập Git.

**FR phục vụ.** FR-15-001, 018, 061.

**Khóa chính.** (id).

**Duy nhất.** `uq_sync_run_running` (tenant_id, kind).

**Khóa ngoại.** content_git_source_id → `content_git_source`.

**Ràng buộc CHECK.** `report`, `kind`, `status`, `error`, `done`, `git`.

**Chỉ mục.** `ix_sync_run_recent`.

**Cách ly tenant.** RLS FORCE, `rls_sync_run_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `kind` | `varchar(12)` | x | Giá trị: INCREMENTAL, FULL, RECONCILE, GIT. |
| `status` | `varchar(10)` | x `'RUNNING'` | Giá trị: RUNNING, SUCCEEDED, FAILED. |
| `started_at` | `timestamptz` | x `now()` |  |
| `finished_at` | `timestamptz` |  |  |
| `items_upserted` | `integer` | x `0` |  |
| `items_removed` | `integer` | x `0` |  |
| `items_failed` | `integer` | x `0` |  |
| `mismatch_count` | `integer` | x `0` |  |
| `content_git_source_id` | `uuid` |  |  |
| `error_code` | `varchar(10)` |  |  |
| `error_detail` | `varchar(1000)` |  |  |
| `report` | `jsonb` | x `'{}'` | Chi tiết lệch khi kind = RECONCILE. |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `sync_run`

### 3.30. `content_migration`

::: dac-ta
**Mục đích.** Lô di trú nội dung portal Gravitee cũ: id là migrationId; chỉ một lô RUNNING mỗi tenant (ERR-15-035).

**FR phục vụ.** FR-15-062.

**Khóa chính.** (id).

**Duy nhất.** `uq_content_migration_running` (tenant_id).

**Khóa ngoại.** package_file_id → `content_attachment`.

**Ràng buộc CHECK.** `status`, `counts`, `report`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, `rls_content_migration_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `package_file_id` | `uuid` | x |  |
| `status` | `varchar(8)` | x `'RUNNING'` | Giá trị: RUNNING, PREVIEW, APPLIED, FAILED. |
| `pages_total` | `integer` | x `0` |  |
| `pages_imported` | `integer` | x `0` |  |
| `pages_skipped` | `integer` | x `0` |  |
| `report` | `jsonb` | x `'{}'` |  |
| `created_at` … `version` | | x | Cột ngữ cảnh D00-01 §5.1; `version` là khóa lạc quan. |

: Cột của bảng `content_migration`

### 3.31. `legacy_mapping`

::: dac-ta
**Mục đích.** Ánh xạ khóa trang, tài liệu của portal hệ cũ sang đối tượng mới; chạy lại cùng migrationId không tạo trùng, băm khác thì cập nhật.

**FR phục vụ.** FR-15-062.

**Khóa chính.** (tenant_id, legacy_system, legacy_key).

**Duy nhất.** Không.

**Khóa ngoại.** migration_id → `content_migration`.

**Ràng buộc CHECK.** `system`, `type`, `hash`.

**Chỉ mục.** `ix_legacy_mapping_target`, `ix_legacy_mapping_batch`.

**Cách ly tenant.** RLS FORCE, `rls_legacy_mapping_all`.

**Phân vùng, chỉ thêm, trigger.** Trigger: `tg_legacy_mapping_guard` (tg_legacy_mapping_guard).
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `tenant_id` | `varchar(16)` | x | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `legacy_system` | `varchar(24)` | x `'GRAVITEE_PORTAL'` | Giá trị: GRAVITEE_PORTAL, BACKSTAGE. |
| `legacy_key` | `varchar(255)` | x |  |
| `target_type` | `varchar(12)` | x | Giá trị: PAGE, PAGE_VERSION, FILE. |
| `target_id` | `uuid` | x |  |
| `source_hash` | `char(64)` | x |  |
| `migration_id` | `uuid` | x |  |
| `mapped_at` | `timestamptz` | x `now()` |  |

: Cột của bảng `legacy_mapping`

### 3.32. `inbox_event`

::: dac-ta
**Mục đích.** Hộp thư đến: ghi nhận sự kiện EVT-02-* của PH-02 đã xử lý để loại trùng (xử lý at-least-once, ADR-041). Giữ 7 ngày.

**FR phục vụ.** FR-15-001, 007, 051.

**Khóa chính.** (tenant_id, event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `code`.

**Chỉ mục.** `ix_inbox_event_received`.

**Cách ly tenant.** RLS FORCE, `rls_inbox_event_all`.

**Phân vùng, chỉ thêm, trigger.** Không.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `tenant_id` | `varchar(16)` | x | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `event_id` | `uuid` | x |  |
| `event_code` | `varchar(10)` | x |  |
| `topic` | `varchar(160)` | x |  |
| `received_at` | `timestamptz` | x `now()` |  |
| `processed_at` | `timestamptz` |  |  |

: Cột của bảng `inbox_event`

### 3.33. `outbox_event`

::: dac-ta
**Mục đích.** Hộp thư đi (outbox) cho EVT-15-01…14; Debezium EventRouter đọc WAL phát lên Kafka. Payload không chứa bí mật, thân yêu cầu hay dữ liệu cá nhân. Kiểm toán PH-13 cũng đi qua đây.

**FR phục vụ.** Mọi FR phát EVT-15-01…14 (FRS §9.2).

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `code`, `topic`, `payload`, `trace`.

**Chỉ mục.** `ix_outbox_event_pending`, `ix_outbox_event_published`.

**Cách ly tenant.** RLS FORCE, `rls_outbox_event_all`.

**Phân vùng, chỉ thêm, trigger.** Không.

**Ghi chú.** Debezium EventRouter đọc WAL và phát lên Kafka; payload không có bí mật, thân yêu cầu hay dữ liệu cá nhân.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `id`, `tenant_id` | `uuid`, `varchar(16)` | x | Khóa chính UUID v7; mã tenant `T{nn}` (khóa RLS, khóa ngoại kép). |
| `event_code` | `varchar(10)` | x |  |
| `topic` | `varchar(160)` | x |  |
| `message_key` | `varchar(128)` | x |  |
| `aggregate_id` | `uuid` |  |  |
| `payload` | `jsonb` | x |  |
| `trace_id` | `char(32)` |  |  |
| `created_at` | `timestamptz` | x `now()` |  |
| `published_at` | `timestamptz` |  |  |

: Cột của bảng `outbox_event`

### 3.34. `idempotency_record`

::: dac-ta
**Mục đích.** Lũy đẳng tầng bền cho thao tác ghi (ADR-041, BR-15-034). Cố ý không lưu thân phản hồi để bí mật sandbox vừa cấp không nằm lại ở CSDL; lặp lại thì trả trạng thái và tham chiếu tài nguyên.

**FR phục vụ.** BR-15-034, mọi FR ghi.

**Khóa chính.** (tenant_id, actor_id, key_hash).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `hash`, `ttl`.

**Chỉ mục.** `ix_idempotency_record_expiry`.

**Cách ly tenant.** RLS FORCE, `rls_idempotency_record_all`.

**Phân vùng, chỉ thêm, trigger.** Không.

**Ghi chú.** Không lưu thân phản hồi để bí mật sandbox vừa cấp không nằm lại trong CSDL.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `tenant_id` | `varchar(16)` | x | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `key_hash` | `char(64)` | x |  |
| `actor_id` | `varchar(64)` | x |  |
| `request_hash` | `char(64)` | x |  |
| `response_status` | `smallint` | x |  |
| `resource_type` | `varchar(32)` |  |  |
| `resource_id` | `uuid` |  |  |
| `created_at` | `timestamptz` | x `now()` |  |
| `expires_at` | `timestamptz` | x |  |

: Cột của bảng `idempotency_record`

### 3.35. `shedlock`

::: dac-ta
**Mục đích.** Bảng kỹ thuật của ShedLock cho tác vụ định kỳ (kéo bù danh mục, đồng bộ Git, hết hạn thông tin xác thực, dọn dữ liệu); không RLS, không dữ liệu nghiệp vụ; tên khóa chứa mã tenant.

**FR phục vụ.** FR-15-001, 018, 024, 026, 031 (tác vụ định kỳ).

**Khóa chính.** (name).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không bật RLS. Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ; tên khóa chứa mã tenant.

**Phân vùng, chỉ thêm, trigger.** Không.

**Ghi chú.** Xem mục Cách ly tenant.
:::

| Cột | Kiểu | Bắt buộc (x), mặc định | Ghi chú |
|---|---|---|---|
| `name` | `varchar(64)` | x |  |
| `lock_until` | `timestamptz` | x |  |
| `locked_at` | `timestamptz` | x |  |
| `locked_by` | `varchar(255)` | x |  |

: Cột của bảng `shedlock`

<!-- gen:tables:end -->

### 3.36. Quy tắc nghiệp vụ chốt ở CSDL

CSDL tự chặn các vi phạm sau dù ứng dụng có lỗi; ca kiểm thử tương ứng ở §4.2 (nhóm 1–22).

| Quy tắc | Cơ chế |
|---|---|
| BR-15-003, NFR-15-017 không rò chéo tenant | RLS FORCE, khóa ngoại kép |
| BR-15-007 mã bất biến, không dùng lại | `tg_immutable_cols`, không cấp `DELETE`, `UNIQUE` theo tenant |
| BR-15-009 ứng dụng có đúng một chủ | `ck_app_owner` |
| BR-15-011 bí mật không lưu, sống ≤ 180 ngày | Không có cột bí mật; `ck_app_credential_ttl`; `key_hash` bắt buộc cho `API_KEY`; vai trò chỉ đọc không thấy `key_hash` |
| BR-15-012 duyệt bốn mắt nội dung | `ck_content_page_version_four_eyes`; một bản `PUBLISHED` mỗi trang; nội dung đã đăng bất biến |
| BR-15-013 trang ≤ 200 KB, ảnh ≤ 5 MB không SVG, logo ≤ 512 KB | `ck_content_page_version_size`, `ck_content_attachment_*` |
| BR-15-019…021 thử production bốn mắt, có hạn | `ck_try_prod_grant_four_eyes`, `ck_try_prod_grant_ttl` (≤ 90 ngày), một bản ghi mỗi API |
| BR-15-020, BR-15-024 thử production chỉ `GET`, `HEAD`, không lưu thân | `ck_try_run_prod` |
| BR-15-027 thông báo bắt buộc không tắt được | `tg_mandatory_watch_guard` |
| BR-15-028, 029 tài khoản `dh-dev` phải xác minh và duyệt; ẩn danh xóa dữ liệu nhận diện | `ck_dev_account_approved`, `ck_dev_account_sso_state`, `ck_dev_account_erased` |
| FR-15-040 ≤ 50 bộ, ≤ 100 yêu cầu, ≤ 16 KB | `tg_collection_limit`, `ck_try_collection_item_spec` |
| FR-15-062 chạy lại không tạo trùng; một lô, một lần đồng bộ mỗi lúc | `PK` `legacy_mapping`; `uq_content_migration_running`; `uq_sync_run_running` |
| BR-15-001 cổng không tự đặt mức hiển thị; gỡ khỏi danh mục thì ẩn | `ck_catalog_api_removed` |

: Quy tắc nghiệp vụ chốt ở CSDL

## 4. DDL, changelog Liquibase và kiểm thử

### 4.1. Tệp và thứ tự changeset

[`ph15/ddl/ph15_portal.sql`](ph15/ddl/ph15_portal.sql) là nguồn duy nhất, chia tệp bằng dấu `-- @file`, `-- @changeset`, `-- @rollback`. Changelog Liquibase ở [`ph15/liquibase/`](ph15/liquibase/db.changelog-ph15.yaml) sinh bằng [`ph15/tools/gen_liquibase.py`](ph15/tools/gen_liquibase.py) (không sửa tay). Changeset `ph15-0003-session` (`runAlways`) đặt `SET ROLE ph15_owner` và giá trị giữ chỗ `app.tenant_id` vì FORCE RLS áp cả chủ bảng khi thêm khóa ngoại.

| Tệp | Nội dung |
|---|---|
| `15-0000-bootstrap.sql` | Vai trò, schema, extension `unaccent`, phiên migration |
| `15-0001-functions.sql` | Miền `t_tenant`; `tg_touch`, `tg_append_only`, `tg_immutable_cols`, `p_enable_rls`, `p_ensure_month_partitions`, `f_unaccent` |
| `15-0010-catalog.sql` | `catalog_api`, `catalog_api_version`, `catalog_spec`, `sandbox_profile`, `try_prod_grant` |
| `15-0020-content.sql` | `content_page`, `content_page_version`, `content_attachment`, `content_git_source` |
| `15-0030-account.sql` | `dev_account`, `dev_team`, `dev_team_member`, `dev_terms`, `dev_terms_acceptance` |
| `15-0040-app.sql` | `app`, `app_member`, `app_credential`, `prod_credential_ref` |
| `15-0050-try.sql` | `try_run` + 6 phân vùng, `try_collection`, `try_collection_item`, trigger giới hạn |
| `15-0060-notify-support.sql` | `notification_subscription`, `inbox_message`, `support_ticket`, `support_message`, `ticket_counter`, `next_ticket_code` |
| `15-0070-admin-sync.sql` | `portal_setting`, `sync_state`, `sync_run`, `content_migration`, `legacy_mapping` |
| `15-0080-messaging.sql` | `inbox_event`, `outbox_event`, `idempotency_record`, `shedlock` |
| `15-0090-seed.sql` | Hàm `seed_tenant` |
| `15-0100-grants.sql` | Quyền (`runOnChange`) |

: Tệp và thứ tự changeset

Phân vùng ban đầu của `try_run`: 11/2026 tới 04/2027; `PartitionMaintenanceJob` chạy 01:00 hằng ngày, giữ 3 tháng tới; không có phân vùng `DEFAULT`.

### 4.2. Kết quả chạy thử

Ngày 26/11/2026, PostgreSQL 16.15, CSDL trống: chạy trực tiếp `ph15_portal.sql` (bằng `psql`) và chạy các tệp changeset sinh ra theo thứ tự đều không lỗi, tạo 35 bảng gốc và 6 phân vùng; sau đó [`ph15/test/ph15_isolation_test.sql`](ph15/test/ph15_isolation_test.sql) chạy dưới `dh_portal_app` (thành viên `ph15_app`, không `BYPASSRLS`) và `dh_portal_ro`: 68 ca trong 22 nhóm đều đạt trên cả hai đường. Tổng hợp theo nhóm:

| Nhóm | Kiểm | Kết quả |
|---|---|---|
| 1–5 | Đọc chéo 0 dòng (kể cả `try_run` phân vùng); ghi chéo bị chặn; sửa chéo 0 dòng; khóa ngoại kép; tenant rỗng 0 dòng | Đạt |
| 6–9 | Mã bất biến, không xóa vật lý; ứng dụng hai chủ; thông tin xác thực quá 180 ngày, thiếu băm, sai mẫu, trùng; tài khoản `dh-dev` chưa duyệt, `ERASED` còn dữ liệu | Bị chặn |
| 10–11 | Duyệt nội dung trùng người gửi hoặc người sửa, trang > 200 KB, sửa bản đã đăng, hai bản `PUBLISHED`; thử production tự duyệt, > 90 ngày, `POST`, có lưu thân, ngoài phân vùng | Bị chặn |
| 12–18 | Bộ sưu tập 51, yêu cầu 101, > 16 KB; xóa đăng ký bắt buộc; sửa tin nhắn; mã phiếu `HT-{năm}-0001`; ảnh SVG, logo quá cỡ; hai lô di trú, đổi `target_id`; hai lần kéo bù | Đạt, bị chặn |
| 19–22 | Mục gỡ còn `portalPublished`; tìm không dấu; chủ đề outbox sai mẫu; seed lũy đẳng; mọi bảng FORCE RLS; vai trò chỉ đọc không thấy `key_hash`, `phone_enc` | Đạt |

: Kết quả chạy thử DDL và ca cách ly trên PostgreSQL 16

`TenantIsolationIT` (SDD) chạy lại các ca này trên Testcontainers PostgreSQL 18 mỗi lần build, cộng ca sinh tự động đọc chéo từng bảng. Cách chạy: `psql -v ON_ERROR_STOP=1 -d datahub -f ddl/ph15_portal.sql` rồi `-f test/ph15_isolation_test.sql`, bằng siêu người dùng trên CSDL trống (tệp test tự chuyển sang `dh_portal_app`).

## 5. Dữ liệu khởi tạo

Dữ liệu nền chỉ gồm cấu hình theo tenant, không có dữ liệu dùng chung.

- **Nhận diện cổng và trạng thái đồng bộ** (FR-15-056, 057, 001): khi PH-20 phát `tenant.provisioned`, gọi `seed_tenant(tenant, actor)` tạo `portal_setting` (tên "Cổng nhà phát triển {tenant}", lời chào; tham số `15.*` mặc định áp ở ứng dụng) và `sync_state` ở `IDLE`; lần kéo `FULL` đầu tiên sinh `sync_run`.
- **Trang bắt đầu nhanh, mẫu mTLS, lấy token, lỗi RFC 9457** (FR-15-014, 018): nhập Git hoặc soạn tay thành `DRAFT` chờ duyệt bốn mắt; không seed SQL vì nội dung phải qua duyệt.
- **Điều khoản sử dụng** (FR-15-023): pháp chế soạn (Q15-01), trang `TERMS` rồi bản ghi `dev_terms`; chưa có bản hiệu lực thì chưa tạo được ứng dụng (BR-15-008).

Seed chạy dưới `app.tenant_id` của tenant đích, lũy đẳng (`ON CONFLICT DO NOTHING`, ca 20). Không có dữ liệu dùng chung nên không cần context `seed-common` của Liquibase.

## 6. Kho lưu trữ ngoài PostgreSQL

### 6.1. Kafka

Topic do PH-10 cấp theo mẫu `{tenant}.portal.{thực-thể}.{sự-kiện}.v1`, viết thường (`t68.portal.app.created.v1`), lược đồ Avro ở Apicurio chế độ BACKWARD; module `portal` chỉ ghi qua `outbox_event` (Debezium EventRouter, `message_key` làm khóa). `ck_outbox_event_topic`, `ck_outbox_event_code` chặn topic và mã sai ngay ở CSDL. Payload không có bí mật hay dữ liệu cá nhân; số phân vùng và thời hạn giữ là giả định.

| Hậu tố topic | Sự kiện | Phân vùng, giữ | Khóa | Bên nhận |
|---|---|---|---|---|
| `app.created`, `app.state-changed` | EVT-15-01, 02 | 3, 30 ngày | `appCode` | PH-13, PH-03 |
| `credential.issued`, `credential.rotated`, `credential.revoked` | EVT-15-03…05 | 3, 30 ngày | `credentialId` | PH-13, PH-03 |
| `devaccount.registered`, `devaccount.state-changed` | EVT-15-06, 07 | 3, 30 ngày | `userId` | PH-13 |
| `content.published`, `content.unpublished` | EVT-15-08, 09 | 3, 30 ngày | `pageCode` | PH-13 |
| `try.production-state-changed` | EVT-15-10 | 3, 30 ngày | `apiCode` | PH-13 |
| `try.executed` | EVT-15-11 | 6, 7 ngày | `tryId` | PH-13 |
| `support.ticket-opened` | EVT-15-12 | 3, 30 ngày | `ticketCode` | PH-13, PH-10 |
| `team.member-changed`, `sync.state-changed` | EVT-15-13, 14 | 3, 30 ngày | `teamCode`, `tenant` | PH-13 |

: Topic Kafka PH-15 phát

Cổng tiêu thụ topic của PH-02 (`{tenant}.catalog.*`: EVT-02-01, 02, 03, 05, 06, 08, 09, 10, 11, 12); mỗi sự kiện ghi `inbox_event (tenant_id, event_id)` trước khi xử lý để loại trùng (xử lý at-least-once). Mất sự kiện được bù bằng kéo gia tăng `updatedSince`.

### 6.2. Valkey

Tiền tố `{tenant}:portal:`; Valkey không chứa bí mật, dữ liệu cá nhân hay thân yêu cầu.

| Khóa | Kiểu | TTL | Dùng cho | Mất dữ liệu thì |
|---|---|---|---|---|
| `{tenant}:portal:rl:try:user:{userId}` | Bộ đếm cửa sổ trượt | 60 giây | `15.try.rate-per-user-min` | Đếm lại, nới trong một phút |
| `{tenant}:portal:rl:try:app:{appId}:{yyyyMMdd}` | Số nguyên | 48 giờ | `15.try.rate-per-app-day` | Dựng lại từ `try_run` trong ngày |
| `{tenant}:portal:cb:backend:{versionId}` | Hash | 30 giây | Ngắt mạch backend thử: 5 lỗi trong 30 giây (BR-15-018) | Mở lại |
| `{tenant}:portal:cache:catalog:{viewerClass}:{hash}` | String JSON | 60 giây | Bộ đệm danh mục (300 lượt/giây ẩn danh, NFR-15-018) | Đọc PostgreSQL |
| `{tenant}:portal:sync-leader` | String | 30 giây | Khóa lãnh đạo tác vụ đồng bộ | Hai pod cùng chạy, `uq_sync_run_running` chặn |
| `{tenant}:portal:bff:sess:{sid}` | Hash | 30 phút nhàn rỗi, 8 giờ tuyệt đối (giả định) | Phiên BFF (token ở máy chủ, không ở trình duyệt, NFR-15-010) | Đăng nhập lại |

: Khóa Valkey của PH-15

### 6.3. Kho đối tượng

Garage giữ tệp của nội dung và đặc tả đã kết xuất.

| Bucket | Hệ | Khóa đối tượng | Nội dung | Giữ |
|---|---|---|---|---|
| `dh-t68-portal` | Garage | `page-image/{yyyy}/{MM}/{id}`, `logo/{id}`, `migration/{migrationId}/package.zip` | Ảnh trang (≤ 5 MB), logo (≤ 512 KB), gói di trú (ZIP ≤ 50 MB) | Ảnh, logo theo trang; gói di trú 30 ngày sau `APPLIED` (giả định) |
| `dh-t68-portal-render` | Garage | `spec/{apiId}/{versionNo}/{kind}/{contentHash}.json` | Đặc tả đã kết xuất (gộp `$ref`); `catalog_spec.object_key` trỏ tới | Sinh lại được; dọn 30 ngày sau `RETIRED` |

: Bucket kho đối tượng của PH-15

Tải lên ghi `content_attachment` sau khi đối tượng đã lưu và băm SHA-256 khớp; chỉ `scan_status = CLEAN` được phục vụ (SEC-45); SVG bị từ chối (BR-15-013). Không có kho WORM: kiểm toán ở PH-13.

### 6.4. OpenSearch

Chỉ mục `{tenant}-portal-catalog-v1` (API) và `{tenant}-portal-pages-v1` (nội dung đã đăng), bộ phân tích tiếng Việt bỏ dấu, dựng lại hoàn toàn từ PostgreSQL bằng tác vụ `reindex`. Tài liệu chỉ vào chỉ mục khi `portal_published` và đúng mức hiển thị; gỡ đăng hoặc `removed_at` thì xóa khỏi chỉ mục trong cùng lần xử lý (BR-15-002). Không dùng ClickHouse; thống kê lượt gọi đọc từ PH-13.

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

### 7.1. Sao lưu và khôi phục

`pg-core`: WAL liên tục và base backup hằng ngày lên Ceph RGW (bucket riêng, mã hóa phía máy chủ); RPO ≤ 5 phút, RTO ≤ 1 giờ (D03-09, giả định); DR theo ADR-034; diễn tập khôi phục mỗi quý. Sau khôi phục, dữ liệu cổng tự lành: bản sao danh mục kéo lại bằng `FULL` sync (idempotent theo `source_version`); `try_run` mất tối đa 5 phút; thông tin xác thực lệch với Keycloak được tác vụ đối soát đặt `provisioning_state = FAILED` rồi cấp lại. Garage nhân bản 3 bản và sao chép sang DR; `portal-render`, Valkey, OpenSearch không sao lưu vì dựng lại được.

### 7.2. Mã hóa và dữ liệu cá nhân

Phân loại là giả định chờ Q15-50: chỉ một cột đạt mức Nhạy cảm cần mã hóa trường (ADR-032); các cột khác bảo vệ bằng RLS, mã hóa ổ đĩa (SEC-30) và che trong log (SEC-32).

| Dữ liệu | Lưu ở | Cách bảo vệ | Ai đọc được bản rõ |
|---|---|---|---|
| Điện thoại tùy chọn của `dh-dev` | `dev_account.phone_enc`, `dek_wrapped` | AES-256-GCM, DEK riêng từng tài khoản, bọc bằng KEK `transit/dh/{tenant}/portal/dev-kek` (ADR-032) | Module `portal` khi người có `PERM-15-dev-approve` mở hồ sơ, có kiểm toán |
| Thư, họ tên, tổ chức, số hợp đồng (Hạn chế) | `dev_account` | RLS, ổ đĩa mã hóa, log che (SEC-32); thư lưu chữ thường | Quản trị cổng, chính chủ |
| Khóa API sandbox; mã xác minh thư (SHA-256, 24 giờ); IP chấp nhận điều khoản (SHA-256) | `app_credential.key_hash`, `verification_token_hash`, `client_ip_hash` | Không lưu bản rõ: HMAC-SHA256 với pepper ở OpenBao; chỉ tiền tố 8 ký tự để người dùng nhận biết | Không ai (một chiều) |
| Bí mật `client_credentials` sandbox | Keycloak realm `dh-dev` | CSDL cổng không giữ | Chỉ lúc cấp, một lần (BR-15-011) |
| Mã truy cập kho Git | OpenBao `kv/dh/{tenant}/portal/git/{id}` | `content_git_source.secret_ref` chỉ là đường dẫn, ghi một chiều | Tác vụ nhập Git |
| Yêu cầu thử, bộ sưu tập | `try_run.request_snapshot`, `try_collection_item.request_spec` | Không mã hóa: chỉ dữ liệu tổng hợp đã qua bộ luật PII-15, ≤ 16 KB; không có tiêu đề xác thực (Q15-51) | Chủ lượt thử |

: Mã hóa và dữ liệu cá nhân

Xóa theo yêu cầu chủ thể (BR-15-029): đặt `status = ERASED`, `anonymized_at`, xóa `email`, `phone_enc`, `dek_wrapped`, thay `full_name` bằng "Đã ẩn danh", xóa bộ sưu tập và lịch sử thử; dòng `dev_account` giữ làm điểm neo khóa ngoại (điều khoản, `app`); `ck_dev_account_erased` bảo đảm không còn dữ liệu nhận diện. Ẩn danh tự động sau `15.dev.anonymize-after-months` (24) tháng không hoạt động.

### 7.3. Lưu giữ

Bảng chốt thời hạn từng nhóm dữ liệu.

| Bảng | Thời hạn | Cơ chế |
|---|---|---|
| `try_run` | `15.try.history-days` ngày (mặc định 30, tối đa 90); phân vùng quá 90 ngày | `RetentionCleanupJob` xóa theo lô mỗi ngày; `PartitionMaintenanceJob` `DETACH` rồi `DROP` (NFR-15-016) |
| `inbox_message` 90 ngày (NFR-15-016); `inbox_event`, `outbox_event` đã phát 7 ngày; `idempotency_record` 24 giờ | Hết hạn | `RetentionCleanupJob` |
| `content_page`, `content_page_version` | Vĩnh viễn, gồm `SUPERSEDED`, `REJECTED` (FR-15-016) | Không xóa |
| `dev_terms`, `dev_terms_acceptance` | Vĩnh viễn trong vòng đời tenant (bằng chứng) | Không xóa |
| `app`, `dev_team` | Dòng giữ vĩnh viễn để mã không dùng lại; `deleted_at` sau 30 ngày `ARCHIVED` | Tác vụ lưu trữ |
| `app_credential` | `REVOKED`, `EXPIRED` giữ 12 tháng (giả định, phục vụ kiểm toán) | `dh_portal_maint` xóa theo lô |
| `catalog_api` và bảng con | Theo PH-02; mục `removed_at` quá 180 ngày (giả định) | `dh_portal_maint` xóa theo lô, ghi kiểm toán |
| `prod_credential_ref` | Theo PH-01; `REVOKED` giữ 90 ngày | `dh_portal_maint` |
| `support_ticket`, `support_message` | 3 năm (giả định), sau đó ẩn danh người gửi | Tác vụ lưu giữ |
| `sync_run` 12 tháng, `content_migration` 24 tháng, `legacy_mapping` tới khi tắt portal cũ + 12 tháng; bộ sưu tập, lịch sử thử theo vòng đời tài khoản | `dh_portal_maint`, tác vụ `ERASED` |
| Nhật ký truy cập cổng | Không ở PH-15: PH-13 giữ 12 tháng trực tuyến, WORM 5 năm (NFR-15-016) | Kiểm toán qua outbox |

: Thời hạn lưu giữ dữ liệu PH-15

## 8. Ánh xạ CSDL hệ cũ sang thiết kế mới

### 8.1. Phạm vi và giả định

Cổng hệ cũ là portal của Gravitee APIM (LGC-APIM-006, 007, 017; phần nhà phát triển của LGC-APIM-022 nay đọc từ PH-13 nên không có CSDL để di trú). Theo FR-15-062, chỉ **trang giới thiệu, tài liệu hướng dẫn và ảnh** được di trú; API, gói, đăng ký, khóa đi theo FR-02-061 (PH-02) và khóa cũ không mang sang. Tên bảng, cột Gravitee dưới đây là **giả định** theo mô hình kho quản lý của Gravitee APIM 3.x và 4.x, chưa đối chiếu bản xuất của tỉnh (Q15-53). Đầu vào là gói ZIP xuất từ portal, không đọc trực tiếp CSDL cũ; bảng này là đầu vào cho D06-01.

### 8.2. Bảng hệ cũ sang bảng mới

Mỗi dòng nêu cách chuyển một bảng của Gravitee.

| Bảng, cột Gravitee (giả định) | Đích | Cách chuyển | Chuyển đổi kiểu |
|---|---|---|---|
| `pages` loại `MARKDOWN` (trang cổng và trang của API) | `content_page` + `content_page_version` (`DRAFT`, `source = MIGRATION`) | Một trang một phiên bản 1; `type = GUIDE`; `pageCode` đề xuất từ `name` bỏ dấu, gạch nối, thêm hậu tố `-2` nếu trùng; `lang = vi`; không đăng tự động | `longtext` UTF-8 → `text` (chuẩn hóa NFC, > 200 KB thì bỏ qua và báo cáo) |
| `pages.type` `ASCIIDOC`, nội dung HTML | Như trên | Chuyển sang Markdown, lọc theo BR-15-013 (bỏ HTML thô, script, iframe); cảnh báo trong báo cáo xem trước | — |
| `pages.type` `SWAGGER`, `ASYNCAPI` | Không di trú | Cổng mới sinh từ đặc tả của PH-02 (FR-15-062 bước 2) | — |
| `pages.type` `FOLDER`, `ROOT`, `LINK`, `SYSTEM_FOLDER` | Không di trú | Tên thư mục chuyển thành thẻ `tags` của các trang con | — |
| `pages.visibility` (`PUBLIC`, `PRIVATE`) | `content_page.audience` | `PUBLIC` → `PUBLIC` nếu tenant bật `15.public.enabled`, ngược lại `LOGGED_IN`; `PRIVATE` → `TENANT` | `varchar` → enum |
| `pages.reference_id`, `reference_type = API` | `content_page.api_id` | Tra `catalog_api` theo context path đã nhập ở PH-02; không tra được thì để trống và báo cáo | `varchar` → `uuid` |
| `pages.published` | Không | Mọi trang vào `DRAFT` rồi duyệt bốn mắt (BR-15-012) | `boolean` bỏ |
| `pages.order`, `parent_id` | Không có cột | Thứ tự hiển thị theo thẻ và tiêu đề; chốt ở Q15-53 | — |
| `pages.last_contributor`, `created_at`, `updated_at` | `created_by` = `legacy:{contributor}`, `created_at`, `updated_at` | Giữ thời điểm gốc | `timestamp`, epoch mili giây → `timestamptz` UTC |
| `page_revisions` | Không di trú | Chỉ phiên bản mới nhất; bản cũ không qua duyệt nên không thể thành `SUPERSEDED` hợp lệ | — |
| `media`, `page_attached_media` | `content_attachment` (`PAGE_IMAGE`) + đối tượng ở `dh-{tenant}-portal` | Quét mã độc, kiểm PNG, JPEG, WebP ≤ 5 MB; SVG bỏ; liên kết ảnh trong Markdown viết lại sang khóa kho | `bytea` hoặc đường dẫn → đối tượng Garage, băm SHA-256 |
| Cấu hình portal (tiêu đề, logo, liên kết) | `portal_setting` | Nhập tay ở UI-15-25 (FR-15-056), không đọc tự động | — |
| `applications`, `application_metadata` | Không di trú sang PH-15 | Ứng dụng cũ là bên đăng ký production: nằm ở PH-01 (HTTT) và PH-02 (FR-02-061). Báo cáo di trú liệt kê tên ứng dụng và chủ để người dùng tự tạo `app` sandbox mới | — |
| `subscriptions`, `keys` | Không di trú | Khóa không mang sang (FR-02-061); HTTT cấp lại định danh | — |
| `users`, `ratings`, comments của portal | Không di trú | Nhà phát triển đăng nhập SSO hoặc tự đăng ký `dh-dev` (FR-15-019, 020); đánh giá là Đợt 3 (FR-15-053) | — |

: Ánh xạ CSDL portal Gravitee cũ sang schema ph15_portal

### 8.3. Chạy lại và đối chiếu

Mỗi lô là một `content_migration` (`id` là `migrationId`); mỗi trang, ảnh nguồn tính `source_hash` và ghi `legacy_mapping (tenant_id, legacy_system, legacy_key)`. Chạy lại cùng gói: băm trùng thì bỏ qua, băm khác thì tạo **phiên bản `DRAFT` mới** của trang đã ánh xạ (không sửa bản đã duyệt); `target_id` không đổi (trigger `tg_legacy_mapping_guard`). Mỗi tenant một lô `RUNNING` (ERR-15-035). Tắt portal cũ khi mọi trang nguồn đã có `legacy_mapping` và phiên bản `PUBLISHED` hoặc được người có `PERM-15-content-publish` đánh dấu bỏ.

## 9. Câu hỏi mở

> **Câu hỏi mở Q15-50:** Thư, họ tên, tổ chức, số hợp đồng của tài khoản `dh-dev` được phân loại Nhạy cảm (mã hóa trường ADR-032 và tìm bằng HMAC theo SEC-88, như SDD gợi ý) hay Hạn chế? Ngầm định: Hạn chế; chỉ điện thoại mã hóa; thư lưu chữ thường, đối sánh trực tiếp.

> **Câu hỏi mở Q15-51:** Có phải mã hóa trường `try_run.request_snapshot` và `try_collection_item.request_spec` không, dù chỉ chứa dữ liệu tổng hợp đã quét PII-15? Ngầm định: không; chặn ở bộ luật PII-15 và kích thước ≤ 16 KB.

> **Câu hỏi mở Q15-52:** Ứng dụng sandbox được "giao" cho HTTT nào để xem tham chiếu thông tin xác thực production (FR-15-032) do ai quyết, người tạo ứng dụng hay PH-01? Ngầm định: cột `app.linked_system_code` do PH-01 xác nhận qua cán bộ đầu mối của tổ chức; NULL là không giao.

> **Câu hỏi mở Q15-53:** Cấu trúc thật của gói xuất portal Gravitee (tên bảng, cột, định dạng `order`, `parent_id`, ảnh) ở từng tỉnh, và có cần giữ thứ tự mục lục? Ngầm định: theo §8.2; thứ tự theo thẻ và tiêu đề.

> **Câu hỏi mở Q15-54:** `try_run` phân vùng theo tháng (DDL) hay theo ngày (SDD Phụ lục A) và nhật ký truy cập, thử có cần bản sao cục bộ ngoài PH-13? Ngầm định: theo tháng vì xóa theo lô đủ cho 30 ngày; nhật ký chỉ ở PH-13.

## 10. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Không sửa tài liệu ngoài tập PH-15; chủ tài liệu liên quan quyết định.

| Tài liệu | Đề nghị | Lý do |
|---|---|---|
| D03-02-PH15 SDD Phụ lục A | Bỏ hoặc gộp các bảng không có ở DDL: `catalog_topic` (dịch vụ sự kiện là `catalog_api.kind = EVENT`), `catalog_change_notice` (đã có `inbox_event` + `inbox_message`), `search_index_task` (chỉ mục dựng lại từ PostgreSQL), `reconciliation_report` (là `sync_run.report`), `dev_registration` (gộp vào `dev_account`: `verification_token_hash`, `verification_expires_at`), `dev_team_invitation` (gộp vào `dev_team_member.invite_status`), `delegation_ref` (ủy thác lưu ở PH-01, PH-02, cổng đọc trực tiếp), `support_feedback` (là `support_ticket.kind = FEEDBACK` với `rating`); đổi `try_prod_grant.status` thay `try_production` của `sandbox_profile` | Khớp DDL; tránh bảng chưa có FR nuôi |
| D03-02-PH15 SDD | `try_run` phân vùng tháng; `app_credential.provisioning_state` có giá trị `PENDING`, `PROVISIONED`, `FAILED`, `DEPROVISIONING`; `key_hash` là HMAC-SHA256 có pepper; thêm các bảng kỹ thuật `sync_state`, `legacy_mapping`, `ticket_counter` | Khớp DDL |
| D02-03-PH15 FRS A.3 | Thêm enum cho lần đồng bộ (`kind`: `INCREMENTAL`, `FULL`, `RECONCILE`, `GIT`; `status`: `RUNNING`, `SUCCEEDED`, `FAILED`), lô di trú (`RUNNING`, `PREVIEW`, `APPLIED`, `FAILED`), tệp đính kèm (`purpose`, `scan_status`), `app_credential.provisioning_state`, `notification_subscription.kind` (`MANDATORY`, `INFO`), `author_side` của tin nhắn hỗ trợ; DDL đang dùng các giá trị này | Phụ lục A chưa liệt kê; FRS là nguồn chuẩn |
| D02-03-PH15 FRS §4.2 | Ghi `linked_system_code` của ứng dụng (EN-15-08) và `origin_tenant_id` của mục danh mục (EN-15-01) | Hai thuộc tính DDL cần để phục vụ FR-15-032 và mức `NATIONAL` |
| D03-10, D03-09, D00-04 | Ghi nhận mẫu bản sao danh mục liên tỉnh kèm `origin_tenant_id` (biến thể mẫu P), PH-15 dùng `pg-core` chung có `unaccent`, dải `Q15-50…54`, bucket `dh-{tenant}-portal[-render]` | Tránh trùng, giải thích thiết kế |

: Đề nghị đồng bộ của tập CSDL PH-15

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm phân hệ PH-15 | Bản đầu: 35 bảng, RLS, CHECK theo Phụ lục A FRS, phân vùng `try_run`, mã hóa điện thoại `dh-dev`, ánh xạ portal Gravitee, đã chạy thử 68 ca trên PostgreSQL 16 |
