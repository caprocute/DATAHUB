---
ma_tai_lieu: D03-03-PH06
ten: Thiết kế cơ sở dữ liệu phân hệ PH-06 Dữ liệu chủ
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, DBA, ATTT, hội đồng thẩm định
phan_he: PH-06
mo_ta: Thiết kế 43 bảng của schema ph06_mdm trên cụm pg-core cho dữ liệu chủ (công dân, tổ chức, địa chỉ), gồm khóa, ràng buộc nghiệp vụ, RLS theo tenant, mã hóa envelope và băm HMAC cho số định danh, phân vùng tháng, lưu giữ và ánh xạ thực thể, chức năng sang bảng, trích từ DDL đã chạy thử.
tai_lieu_lien_quan: D02-03-PH06 FRS; D03-02-PH06 SDD; D03-04-PH06 API; D03-10 Thiết kế đa tenant; D05-02-PH06 Test case
---

# D03-03-PH06 · Thiết kế CSDL Dữ liệu chủ

## Tóm tắt cho hội đồng thẩm định

Schema `ph06_mdm` trên cụm `pg-core` có 43 bảng cho 21 thực thể của [D02-03-PH06](../../02-yeu-cau/frs/D02-03-PH06-frs-du-lieu-chu.md) §4.2 và 13 thực thể bổ sung EN-06-22…34 (FRS 0.2), cộng các bảng con và hạ tầng, phục vụ module `mdm` của `dh-data`. Phân hệ giữ bản ghi vàng (golden record) của công dân, tổ chức, địa chỉ cùng liên kết chéo tới bản ghi của từng hệ thống nguồn; đây là dữ liệu cá nhân nên thiết kế đặt an toàn lên trước. Bốn điểm chính:

1. **Số định danh không bao giờ lưu dạng rõ.** CCCD, mã số thuế và mọi thuộc tính `SENSITIVE` chỉ nằm ở cột `*_enc` (mã hóa envelope bằng OpenBao transit, ADR-032), kèm cột `*_hash` (HMAC-SHA256 theo khóa riêng từng tenant) để đối sánh bằng nhau mà không giải mã. `CHECK` buộc giá trị `SENSITIVE` không được vào cột rõ (NFR-06-016); lịch sử, ứng viên và nhật ký cũng theo quy tắc này.
2. **Quy tắc nghiệp vụ khóa ở CSDL**, không chỉ ở dịch vụ: một số định danh hiệu lực chỉ thuộc một bản ghi vàng (BR-06-001, 006), một bản ghi nguồn chỉ liên kết hiệu lực một lần (BR-06-018), ngưỡng đối sánh ≥ 0,90 và cách ≥ 0,10 (BR-06-020), bộ quy tắc ACTIVE phải có đánh giá đạt (BR-06-021), phiên bản ACTIVE bất biến (BR-06-017), lý do ≥ 20 ký tự (BR-06-008), bốn mắt, bản ghi vàng không bị xóa (BR-06-007).
3. **Cô lập tenant bằng `FORCE ROW LEVEL SECURITY`** trên 42 bảng (bảng kỹ thuật `shedlock` không có `tenant_id`), kể cả sáu bảng phân vùng theo tháng; khóa ngoại luôn kèm `tenant_id`. Nhật ký truy cập, lịch sử, truy nguồn gốc chỉ thêm, không sửa (trigger và quyền).
4. **Đối sánh dùng chính PostgreSQL.** Tra gần đúng bằng `pg_trgm` trên tên chuẩn hóa; đối sánh theo lô do Job Splink đọc bảng `match_staging`, không đọc thẳng bảng nghiệp vụ.

DDL [`ph06/ddl/ph06_mdm.sql`](ph06/ddl/ph06_mdm.sql) đã chạy thử trên PostgreSQL 16.15 sạch; bài kiểm [`ph06/test/ph06_isolation_test.sql`](ph06/test/ph06_isolation_test.sql) đạt 95 khối PASS (§4.2); đối chiếu Phụ lục A của FRS sạch (§4.3). Mục 8 ánh xạ thực thể và chức năng sang bảng; mục 9 nêu năm câu hỏi mở Q06-50…54 và đề nghị bổ sung cho FRS.

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả cơ sở dữ liệu của PH-06 Dữ liệu chủ ở mức đủ để DBA dựng schema, kỹ sư `dh-data` viết tầng truy cập và kiểm thử viên viết ca kiểm thử cô lập tenant, bất biến, mã hóa. Phạm vi là 43 bảng của schema `ph06_mdm`, thủ tục, trigger, changelog Liquibase và bài kiểm cô lập. Ngoài phạm vi: nội dung tệp lô và tệp xuất (Ceph RGW), cặp kết quả của Job Splink (Parquet trên Ceph RGW), khóa mã hóa (OpenBao); các nơi này nêu ở chương 6.

Nguồn chuẩn là [`ph06/ddl/ph06_mdm.sql`](ph06/ddl/ph06_mdm.sql), sinh bằng `ph06/tools/sinh_ddl.py` từ danh mục bảng và Phụ lục A của FRS (nên enum không lệch FRS). Chương 3, bảng 1.6 và chương 8 sinh từ DDL bằng `gen_tables_md.py`, `them_dac_ta_bang.py`, `gen_anh_xa.py`.

### 0.2. Thuật ngữ và chữ viết tắt

Các thuật ngữ dưới đây dùng xuyên suốt tập CSDL.

| Thuật ngữ | Giải thích |
|---|---|
| Bản ghi vàng (golden record) | Bản ghi hợp nhất đại diện duy nhất cho một thực thể, có `goldenId` ổn định (bảng `golden_record`) |
| Liên kết chéo nguồn (xref) | Cặp `(sourceCode, sourceKey)` ↔ `goldenId` (bảng `source_xref`) |
| Mã hóa envelope | Dữ liệu mã hóa bằng khóa dữ liệu, khóa dữ liệu mã hóa bằng khóa trong OpenBao transit; cột `*_enc` giữ bản mã, `*_kid` giữ mã khóa (ADR-032) |
| HMAC, cột `*_hash` | Băm có khóa (HMAC-SHA256, 32 byte) của giá trị đã chuẩn hóa; so bằng nhau mà không giải mã; khóa riêng từng tenant |
| RLS, FORCE RLS | Row Level Security lọc dòng theo `tenant_id = app.tenant_id`; FORCE áp cả với chủ bảng |
| Phân vùng RANGE | Chia bảng lớn thành bảng con theo tháng |
| `pg_trgm` | Tiện ích PostgreSQL so khớp gần đúng theo tam ký tự (ADR đề xuất ở FRS 12.3) |
| Splink | Thư viện đối sánh xác suất chạy Job K8s trên DuckDB, đọc bảng `match_staging` (ADR đề xuất ở FRS 12.3) |
| Outbox, inbox | Bảng ghi sự kiện cùng giao dịch để Debezium phát; bảng khử trùng sự kiện nhận |
| DLCN | Dữ liệu cá nhân |

: Thuật ngữ và chữ viết tắt của tập CSDL PH-06

### 0.3. Tài liệu tham chiếu

Tập này dựa vào các tài liệu sau.

| Tài liệu | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH06 FRS §4.2, §5, §7, §9, Phụ lục A | Thực thể EN-06-01…21, FR-06-001…060, BR-06, ERR-06, enum |
| D03-04-PH06 API | Ánh xạ trường JSON camelCase với cột snake_case |
| D03-10 Thiết kế đa tenant | Mẫu RLS, khóa ngoại kèm `tenant_id` |
| D03-07 Bảo mật, D03-09 Hạ tầng và DR | Mã hóa, cụm `pg-core`, sao lưu |
| ADR-003, 031, 032, 034 | RLS, nhật ký WORM, mã hóa envelope, DR; ADR đề xuất ở FRS 12.3 |
| `docs/07-srs/SRS-PH-06-mdm.md` §4 | Sáu thực thể của SRS cũ (mục 8.3) |

: Tài liệu tham chiếu của tập CSDL PH-06

### 0.4. Người đọc

DBA, kỹ sư `dh-data`, ATTT và kiểm thử viên.

### 0.5. Cấu trúc tài liệu

Chương 1 chiến lược, 2 sơ đồ, 3 đặc tả bảng, 4 DDL, 5 dữ liệu khởi tạo, 6 kho ngoài, 7 sao lưu và lưu giữ, 8 ánh xạ, 9 câu hỏi mở.

## 1. Chiến lược lưu trữ

### 1.1. Schema, vai trò và kết nối

Schema `ph06_mdm` do `ph06_owner` (NOLOGIN) sở hữu. Module `mdm` của `dh-data` (package `vn.datahub.data.mdm`) kết nối bằng `dh_data_app`, thành viên `ph06_app`: chỉ DML, không `BYPASSRLS`, không `DELETE` trên bảng nghiệp vụ (BR-06-007), không `UPDATE`, `DELETE` trên bốn bảng chỉ thêm. Liquibase chạy bằng `dh_data_migrator` (thành viên `ph06_owner`). Báo cáo đọc bằng `ph06_readonly`, bị thu hồi quyền đọc `access_log` (trừ cột an toàn), `golden_history`, `subject_request`, `golden_identifier`. Job Splink chạy bằng vai riêng `ph06_splink` (FRS 0.2, FR-06-022): chỉ `SELECT` bảng `match_staging`, chỉ `INSERT` bảng `match_result`, không đọc bảng nào khác.

`dh-data` không có khóa ngoại sang schema khác. Mã HTTT (`system_code`, PH-01), mã ĐVHC (`admin_unit_code`, PH-07), mã mục đích (`purpose_code`, PH-09) là chuỗi kiểm ở dịch vụ qua giao diện module (Modulith), bộ đệm 5 phút khi phân hệ kia ngừng (FRS 12.1). Job Splink không ghi vào PostgreSQL: nó đọc `match_staging` rồi ghi cặp kết quả ra Parquet trên Ceph RGW; bước `APPLYING` của `dh-data` đọc tệp đó, ghi `match_result` và áp từng cặp trong giao dịch riêng (FRS 4.5).

### 1.2. Cách ly tenant

Mọi bảng nghiệp vụ có `tenant_id varchar(16)` dạng `Tnn` và bật `FORCE ROW LEVEL SECURITY` qua `ph06_mdm.p_enable_rls(bảng)`: một mẫu duy nhất, đọc và ghi chỉ dòng có `tenant_id = current_setting('app.tenant_id')`. Khác PH-10, PH-06 không có dòng dùng chung `COMMON`: mỗi tenant tự cài gói domain nền (FR-06-007), nên không cần mẫu dùng chung.

Biến phiên `app.tenant_id` đặt đầu mỗi giao dịch từ ngữ cảnh xác thực (FR-00-010), không từ tham số của bên gọi. Tác vụ nền liên tenant (dọn lưu giữ, dọn phân vùng, outbox) lặp từng tenant. Ba lớp chặn chéo tenant ngoài RLS: (a) khóa ngoại luôn kèm `tenant_id` (`FOREIGN KEY (tenant_id, golden_id)`), đích có `UNIQUE (tenant_id, id)`; (b) mọi cột `*_hash` là HMAC theo khóa riêng từng tenant (`dh-{tenant}-mdm-hmac`), nên cùng một CCCD ở hai tỉnh cho hai giá trị băm khác nhau và không thể đối chiếu chéo tenant dù lộ bảng; (c) tiền tố topic của `outbox_event` phải bằng `lower(tenant_id)`.

### 1.3. Quy ước bảng và ngoại lệ

Theo D00-01 §5.1: `id uuid` (UUIDv7 sinh ở ứng dụng; chính là `goldenId`, `jobId`, `itemId`, `operationId`… của API), `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (trigger `tg_touch`, khóa lạc quan, ETag). Mã nghiệp vụ có `CHECK` theo mẫu: domain `^[A-Z][A-Z0-9_]{1,31}$`, nguồn `^[A-Z][A-Z0-9-]{2,31}$`, thuộc tính camelCase `^[a-z][a-zA-Z0-9]{1,62}$`. Trạng thái và loại là `varchar` kèm `CHECK` liệt kê đúng giá trị Phụ lục A; thêm giá trị là một changeset mới, sau khi sửa FRS Phụ lục A. Bảng con của phiên bản (`model_attribute`, `identifier_rule`, `match_rule`, `survivorship_rule`) tham chiếu cha bằng `(domain_code, version_no)` để tên cột đúng tên trường API.

**Cột mã hóa.** Mỗi giá trị cần mã hóa có cặp `x_enc bytea` (bản mã envelope, `CHECK` độ dài 29 byte đến 1 MiB: byte tiêu đề, nonce 12 byte, thẻ xác thực 16 byte) và `x_kid` (mã khóa OpenBao transit, ghi để quay khóa). Giá trị cần so bằng thêm `x_hash bytea` (32 byte, `CHECK`). Cột rõ `value_json` của `golden_attribute` bị `CHECK` loại ra khi `data_class = 'SENSITIVE'`.

| Bảng, cột | Ngoại lệ | Lý do |
|---|---|---|
| `candidate_record`, `match_result`, `golden_history`, `attribute_lineage`, `access_log`, `processing_log` | Khóa chính `(id, cột thời gian)`, không `version`, không `updated_*` | Phân vùng tháng; chỉ thêm hoặc ghi một lần |
| `candidate_record.golden_id`, `source_record_head.golden_id`, `match_result.*_id`, `steward_item.match_result_id` | Không khóa ngoại | Bảng phân vùng không là đích khóa ngoại tiện lợi; tham chiếu logic, dịch vụ kiểm |
| `outbox_event`, `inbox_event`, `shedlock` | Không `version` (`shedlock` không `tenant_id`) | Bảng kỹ thuật |

: Quy ước bảng và ngoại lệ

### 1.4. Quy tắc nghiệp vụ chốt ở CSDL

Các quy tắc sau do CSDL tự bảo đảm, bằng ràng buộc, chỉ mục duy nhất, trigger hoặc quyền.

| Ràng buộc | Quy tắc | BR, FR |
|---|---|---|
| `uq_golden_identifier_active` | Một giá trị định danh (băm) hiệu lực chỉ thuộc một bản ghi vàng trong domain; hai bản ghi cùng CCCD không tồn tại (ERR-06-112 là lỗi bất biến) | BR-06-001, 006; FR-06-020 |
| `uq_source_xref_active`, `uq_source_record_head` | Một bản ghi nguồn một liên kết `ACTIVE`; một dòng trạng thái mới nhất mỗi bản ghi nguồn | BR-06-018, 028, 029 |
| `ck_match_rule_set_threshold`, `ck_match_rule_set_active`, `ck_evaluation_report_pass` | Ngưỡng tự hợp nhất ≥ 0,90, cách ngưỡng xem xét ≥ 0,10; `ACTIVE` phải có báo cáo đạt (≥ 1.000 cặp, precision ≥ 99,9%, recall ≥ 98%) | BR-06-020, 021; FR-06-026 |
| `tg_domain_model_frozen`, `tg_match_rule_set_frozen`, `tg_child_frozen` | Phiên bản `ACTIVE`, `SUPERSEDED` không đổi nội dung, kể cả dòng con; con chỉ ghi khi cha là `DRAFT`, `REJECTED` | BR-06-017 |
| `uq_domain_model_active`, `uq_match_rule_set_active`, `uq_survivorship_rule_set_active` | Mỗi domain đúng một phiên bản `ACTIVE` | FRS 4.6 |
| `ck_*_four_eyes` | Người duyệt khác người đề nghị (mô hình, bộ quy tắc, sống sót, ưu tiên nguồn, mục hàng đợi, thao tác, xuất, đăng ký nhận) | BR-06-004, 019, 027; ERR-06-005 |
| `ck_golden_operation_reason20`, `ck_steward_item_reason20`, `ck_source_xref_manual` | Lý do ≥ 20 ký tự | BR-06-008; ERR-06-007 |
| `ck_golden_record_merged`, `ck_golden_record_retired`, quyền `REVOKE DELETE` | `MERGED` có `merged_into`; `RETIRED` có lý do; không xóa bản ghi vàng | BR-06-007; FR-06-040 |
| `ck_golden_attribute_sensitive` | `SENSITIVE` chỉ mã hóa kèm băm; ngược lại không có cột mã hóa | BR-06-016; NFR-06-016 |
| `ck_golden_attribute_manual`, `ck_golden_attribute_authority` | Sửa tay có hạn; thuộc tính thẩm quyền quốc gia dùng chiến lược `NATIONAL_AUTHORITY` | BR-06-014, 025 |
| `uq_steward_item_open_pair`, `ix_steward_item_nomatch` | Một mục mở mỗi cặp; cặp `NO_MATCH` đã giải quyết là liên kết âm | BR-06-023; FR-06-027 |
| `uq_match_job_running` | Một job đang chạy mỗi (domain, loại) | ERR-06-025 |
| `ck_match_job_confirm` | DA xác nhận job vượt ngưỡng an toàn khác người yêu cầu | BR-06-022 |
| `uq_golden_operation_undo`, `ck_golden_operation_undo` | Mỗi thao tác hoàn tác một lần; hoàn tác trỏ thao tác gốc | BR-06-024 |
| `tg_*_append_only`, `REVOKE UPDATE, DELETE` | Lịch sử, truy nguồn gốc, nhật ký truy cập, nhật ký xử lý chỉ thêm | BR-06-005, 010; RB-06-04 |
| `ck_export_request_ready`, `ck_export_request_owner` | Tệp xuất `READY` có thủy vân, hạn tải; DO chấp thuận khác người đề nghị | BR-06-027 |
| `ck_outbox_event_no_value`, `ck_outbox_event_topic` | Sự kiện không chứa khóa giá trị thuộc tính; đúng 15 topic EVT-06 và kiểm toán | BR-06-012; FR-06-050 |
| `ck_retention_policy_days`, `ck_tenant_setting_key` | Nhật ký truy cập ≥ 365 ngày; chỉ 22 khóa tham số 06.* | FR-06-059, 060; ERR-06-049 |

: Quy tắc nghiệp vụ chốt ở CSDL

Quy tắc cần dữ liệu ngoài schema hoặc tính toán (tổng trọng số 1,00, miền tham số, HTTT `ACTIVE` ở PH-01, hạn hoàn tác 90 ngày, rủi ro cao theo BR-06-019, ERR-06-029) kiểm ở dịch vụ, ghi ở D03-02-PH06.

### 1.5. Ước lượng khối lượng (giả định)

Giả định theo GĐ-06-01: tỉnh T01 có 1,2 triệu dân, 25.000 tổ chức, 5 triệu bản ghi nguồn từ 20 nguồn, khoảng 5 lượt tra mỗi giây trung bình.

| Bảng | Dòng ước tính | Dung lượng |
|---|---|---|
| `golden_record`, `golden_identifier`, `golden_attribute` | 1,3 triệu; 15 triệu | khoảng 7 GB |
| `source_xref`, `source_record_head` | khoảng 5 triệu mỗi bảng | khoảng 3 GB |
| `candidate_record` (365 ngày) | khoảng 11 triệu | khoảng 25 GB |
| `match_result` (2 năm) | khoảng 16 triệu | khoảng 10 GB |
| `golden_history`, `attribute_lineage` | 3 triệu, 20 triệu mỗi năm | khoảng 12 GB mỗi năm |
| `access_log` (12 tháng; Q06-51) | khoảng 158 triệu | khoảng 35 GB |
| Còn lại | dưới 2 triệu | dưới 2 GB |

: Ước lượng khối lượng (giả định)

### 1.6. Danh mục bảng

Bảng dưới liệt kê 43 bảng theo thứ tự đặc tả ở chương 3, kèm thực thể của FRS 4.2, phân vùng và FR chính; sinh từ DDL nên khớp tuyệt đối.

<!-- gen:danh-muc:start -->
| Mục | Bảng | Thực thể | Phân vùng | FR chính |
|---|---|---|---|---|
| 3.1 | `mdm_domain` | EN-06-07 | Tháng, received_at | 001, 002, 006, 007 |
| 3.2 | `domain_model` | EN-06-07 | Không | 002, 005, 006 |
| 3.3 | `model_attribute` | EN-06-07 | Không | 002, 004, 052 |
| 3.4 | `identifier_rule` | EN-06-07 | Không | 003 |
| 3.5 | `mdm_source` | EN-06-08 | Không | 008 |
| 3.6 | `source_priority_proposal` | EN-06-04, EN-06-22 | Không | 009 |
| 3.7 | `source_priority` | EN-06-04 | Không | 009, 033 |
| 3.8 | `candidate_file` | EN-06-25 | Không | 013 |
| 3.9 | `source_record_head` | EN-06-26 | Không | 016 |
| 3.10 | `candidate_record` | EN-06-09 | Không | 010, 011, 012, 013, 014… |
| 3.11 | `evaluation_report` | EN-06-23 | Tháng, scored_at | 026 |
| 3.12 | `match_rule_set` | EN-06-10 | Không | 018, 019, 023, 024 |
| 3.13 | `match_rule` | EN-06-10 | Không | 018 |
| 3.14 | `match_job` | EN-06-12 | Không | 022, 024, 055, 056 |
| 3.15 | `job_schedule` | EN-06-24 | Không | 056 |
| 3.16 | `match_staging` | EN-06-27 | Không | 022 |
| 3.17 | `match_result` | EN-06-11 | Không | 020, 021, 022, 023, 024… |
| 3.18 | `label_set` | EN-06-15 | Tháng, changed_at | 008, 025 |
| 3.19 | `label_pair` | EN-06-15 | Không | 025, 030 |
| 3.20 | `steward_item` | EN-06-05 | Không | 027, 028, 029, 030, 031… |
| 3.21 | `golden_record` | EN-06-01 | Không | 034, 035, 036, 037, 038… |
| 3.22 | `golden_attribute` | EN-06-02 | Không | 016, 034, 035, 052 |
| 3.23 | `golden_identifier` | EN-06-02, EN-06-28 | Không | 020, 046, 047 |
| 3.24 | `source_xref` | EN-06-03 | Không | 044, 045 |
| 3.25 | `golden_operation` | EN-06-13 | Không | 036, 037, 038, 039, 040… |
| 3.26 | `golden_history` | EN-06-06 | Không | Hạ tầng |
| 3.27 | `attribute_lineage` | EN-06-14 | Tháng, recorded_at | 043 |
| 3.28 | `survivorship_rule_set` | EN-06-17 | Tháng, accessed_at | 033, 042 |
| 3.29 | `survivorship_rule` | EN-06-17 | Không | 033 |
| 3.30 | `update_subscription` | EN-06-18 | Không | 051 |
| 3.31 | `export_request` | EN-06-19 | Không | 049 |
| 3.32 | `national_sync_state` | EN-06-29 | Không | 053, 054 |
| 3.33 | `national_sync_run` | EN-06-16 | Không | 053 |
| 3.34 | `national_discrepancy` | EN-06-30 | Không | 053, 054, 055 |
| 3.35 | `source_correction` | EN-06-31 | Không | 036, 054, 058 |
| 3.36 | `subject_request` | EN-06-20 | Không | 058 |
| 3.37 | `access_log` | EN-06-21 | Không | 015, 047, 048, 052, 055… |
| 3.38 | `processing_log` | EN-06-32 | Tháng, logged_at | 057 |
| 3.39 | `retention_policy` | EN-06-33 | Không | 059 |
| 3.40 | `tenant_setting` | EN-06-34 | Không | 060 |
| 3.41 | `outbox_event` | Bổ sung | Không | 050 |
| 3.42 | `inbox_event` | Bổ sung | Không | 008, 012, 053 |
| 3.43 | `shedlock` | Bổ sung | Không | Hạ tầng |

: Danh mục bảng của schema ph06_mdm

<!-- gen:danh-muc:end -->

## 2. Sơ đồ thực thể – quan hệ

Sơ đồ chia bốn nhóm để đọc được trên trang A4; khóa ngoại đều kèm `tenant_id` nên không vẽ. Đường nét liền là khóa ngoại thật, ghi chú "logic" là tham chiếu không có khóa ngoại (§1.3).

```{.mermaid caption="ERD nhóm mô hình domain, nguồn và ưu tiên nguồn"}
erDiagram
  mdm_domain ||--o{ domain_model : "phiên bản"
  domain_model ||--o{ model_attribute : "thuộc tính"
  domain_model ||--o{ identifier_rule : "khóa định danh"
  mdm_domain ||--o{ source_priority_proposal : "đề nghị"
  source_priority_proposal ||--o{ source_priority : "áp khi duyệt"
  mdm_source ||--o{ source_priority : "mức ưu tiên"
  mdm_source ||--o{ source_record_head : "trạng thái mới nhất"
  mdm_domain ||--o{ survivorship_rule_set : "phiên bản"
  survivorship_rule_set ||--o{ survivorship_rule : "chiến lược"
```

Nhóm này là cấu hình có phiên bản: mô hình và bộ quy tắc sống sót cùng một vòng đời `DRAFT` đến `ACTIVE`, mỗi domain đúng một phiên bản `ACTIVE`; thứ tự ưu tiên nguồn chỉ vào bảng hiện hành sau khi đề nghị được duyệt có căn cứ văn bản.

```{.mermaid caption="ERD nhóm nạp ứng viên và đối sánh"}
erDiagram
  mdm_source ||--o{ candidate_file : "tệp lô"
  mdm_source ||--o{ candidate_record : "logic"
  candidate_record ||--o{ match_result : "logic, điểm cặp"
  match_rule_set ||--o{ match_rule : "quy tắc con"
  evaluation_report ||--o| match_rule_set : "điều kiện ACTIVE"
  label_set ||--o{ label_pair : "cặp có nhãn"
  match_job ||--o{ match_staging : "xuất cho Splink"
  match_job ||--o{ match_result : "logic, job_id"
  match_result ||--o| steward_item : "logic, chuyển người"
```

Ứng viên không ghi thẳng vào bản ghi vàng: nó sinh `match_result`, và chỉ cặp cần người mới thành `steward_item`. Báo cáo đánh giá là điều kiện để bộ quy tắc thành `ACTIVE`; job Splink chỉ thấy `match_staging`.

```{.mermaid caption="ERD nhóm bản ghi vàng, liên kết và thao tác"}
erDiagram
  golden_record ||--o{ golden_attribute : "thuộc tính vàng"
  golden_record ||--o{ golden_identifier : "băm định danh"
  golden_record ||--o{ source_xref : "liên kết nguồn"
  golden_record ||--o{ golden_history : "ảnh chụp"
  golden_record ||--o{ attribute_lineage : "nguồn gốc"
  golden_record ||--o| golden_record : "hợp nhất vào"
  golden_operation ||--o{ golden_history : "logic, operation_id"
  golden_operation ||--o| golden_operation : "hoàn tác undo_of"
  golden_record ||--o{ source_correction : "yêu cầu sửa tại nguồn"
  mdm_domain ||--o{ golden_operation : "thao tác"
  steward_item ||--o| golden_operation : "logic, quyết định MATCH"
```

Mọi thay đổi bản ghi vàng đi qua một `golden_operation` và để lại ảnh chụp `golden_history` cùng giao dịch (BR-06-005). `golden_identifier` là chỉ mục băm bảo đảm không có hai bản ghi vàng cùng định danh hiệu lực.

```{.mermaid caption="ERD nhóm cung cấp, đồng bộ quốc gia và vận hành"}
erDiagram
  mdm_domain ||--o{ update_subscription : "đăng ký nhận"
  mdm_domain ||--o{ export_request : "yêu cầu xuất"
  mdm_domain ||--o| national_sync_state : "trạng thái đồng bộ"
  national_sync_run ||--o{ national_discrepancy : "lệch"
  golden_record ||--o{ national_discrepancy : "lệch của"
  match_job ||--o{ national_sync_run : "logic, job_id"
  subject_request }o--o| golden_record : "logic, golden_id"
  access_log }o--o| golden_record : "logic, golden_id"
  job_schedule ||--o{ match_job : "logic, loại job"
```

Nhóm vận hành không có khóa ngoại tới bảng phân vùng; nhật ký truy cập và yêu cầu chủ thể tham chiếu bản ghi vàng bằng `golden_id` kiểm ở dịch vụ để nhật ký vẫn ghi được khi bản ghi đổi trạng thái.

## 3. Đặc tả bảng

Phần dưới sinh bằng [`gen_tables_md.py`](ph06/tools/gen_tables_md.py) và [`them_dac_ta_bang.py`](ph06/tools/them_dac_ta_bang.py) từ DDL; sửa ở DDL rồi sinh lại, không sửa tay. Mỗi bảng có khối đặc tả, bảng cột nổi bật (có ghi chú hoặc enum) và dòng cột khác (`v` là `varchar`, `tstz` là `timestamptz`). Bảy cột ngữ cảnh chuẩn (§1.3) không liệt kê lại; sáu bảng phân vùng không có cột ngữ cảnh sửa.

<!-- gen:tables:start -->
### 3.1. `mdm_domain`

::: dac-ta
**Mục đích.** EN-06-07 Domain dữ liệu chủ (FR-06-001, 006, 007): CITIZEN, ORGANIZATION, ADDRESS và domain tỉnh tự tạo (FR-06-002). Trạng thái DomainStatus. Không xóa; ngừng cần không còn bản ghi vàng ACTIVE (ERR-06-011). Giữ vĩnh viễn.

**FR phục vụ.** FR-06-001, 002, 006, 007; EN-06-07.

**Khóa chính.** (id).

**Duy nhất.** `uq_mdm_domain_code` (tenant_id, domain_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_mdm_domain_` + `tenant`, `code`, `status`, `reason`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_code`, `tenant_id`, `baseline` (`tg_mdm_domain_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(16), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `ACTIVE`, `SUSPENDED`, `RETIRED`. |
| `baseline` | `boolean, mặc định false` | Có khi cài từ gói domain nền (FR-06-007); gói nền do PA phát hành. |
| `status_reason` | `varchar(2000), NULL` | Bắt buộc khi SUSPENDED hoặc RETIRED. |

: Cột của bảng `mdm_domain`

Cột khác: `domain_code` v(32); `name` v(255); `description` v(2000); `baseline_package` v(32).

### 3.2. `domain_model`

::: dac-ta
**Mục đích.** EN-06-07 Phiên bản mô hình domain (FR-06-002, 005, 006, BR-06-017). Máy trạng thái 4.6 không có TESTING. Mỗi domain đúng một phiên bản ACTIVE; ACTIVE không sửa nội dung, kể cả thuộc tính và khóa con. Duyệt bốn mắt (BR-06-004).

**FR phục vụ.** FR-06-002, 005, 006; EN-06-07.

**Khóa chính.** (id).

**Duy nhất.** `uq_domain_model_tid` (tenant_id, id), `uq_domain_model_version` (tenant_id, domain_code, version_no), `uq_domain_model_active` (tenant_id, domain_code) có điều kiện.

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`.

**Ràng buộc CHECK.** `ck_domain_model_` + `tenant`, `version`, `status`, `compat`, `decision`, `four_eyes`, `active`, `reject`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_code`, `version_no`, `tenant_id` (`tg_domain_model_immutable`); Trigger: `tg_domain_model_frozen`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(20), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `PENDING_APPROVAL`, `ACTIVE`, `SUPERSEDED`, `REJECTED`. |
| `normalization` | `jsonb, mặc định '{}'` | Quy tắc chuẩn hóa theo thuộc tính (FR-06-014, 015), JSON có phiên bản. |
| `compat_level` | `varchar(16), NULL` | Giá trị: `NON_BREAKING`, `BREAKING`. |
| `decision` | `varchar(8), NULL` | Giá trị: `APPROVE`, `REJECT`. |
| `decision_comment` | `varchar(2000), NULL` | Từ chối bắt buộc ≥ 20 ký tự (FR-06-006). |

: Cột của bảng `domain_model`

Cột khác: `domain_code` v(32); `version_no` int; `diff_summary` jsonb; `submitted_by` v(64); `submitted_at` tstz; `submit_comment` v(2000); `decided_by` v(64); `decided_at` tstz; `activated_at` tstz; `superseded_at` tstz.

### 3.3. `model_attribute`

::: dac-ta
**Mục đích.** EN-06-07 Thuộc tính của một phiên bản mô hình (FR-06-002, 004). Giá trị DataClass, ClassificationStatus; thuộc tính DLCN cần phân loại CONFIRMED trước khi kích hoạt (BR-06-016, kiểm ở dịch vụ, ERR-06-010). Phiên bản ACTIVE chặn thêm, sửa, xóa (trigger).

**FR phục vụ.** FR-06-002, 004; EN-06-07.

**Khóa chính.** (id).

**Duy nhất.** `uq_model_attribute_name` (tenant_id, domain_code, version_no, attribute_name).

**Khóa ngoại.** (tenant_id, domain_code, version_no) → `domain_model`.

**Ràng buộc CHECK.** `ck_model_attribute_` + `tenant`, `name`, `type`, `class`, `classification`, `personal`, `coderef`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Trigger: `tg_model_attribute_child_frozen`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `attribute_type` | `varchar(16)` | Giá trị: `STRING`, `NAME_VN`, `DATE`, `INTEGER`, `DECIMAL`, `BOOLEAN`, `CODE_REF`, `ADDRESS_REF`, `IDENTIFIER`, `PHONE`, `EMAIL`. |
| `matchable` | `boolean, mặc định false` | Dùng được trong quy tắc đối sánh (FR-06-018). |
| `data_class` | `varchar(16), mặc định 'INTERNAL'` | Phân loại theo DD-08; SENSITIVE bắt buộc personal_data. Giá trị: `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE`. |
| `classification_status` | `varchar(16), mặc định 'PROPOSED'` | Giá trị: `PROPOSED`, `CONFIRMED`. |

: Cột của bảng `model_attribute`

Cột khác: `domain_code` v(32); `version_no` int; `attribute_name` v(63); `label` v(255); `code_list_ref` v(63); `required` bool; `multi_valued` bool; `critical` bool; `personal_data` bool; `legal_basis` v(2000); `sort_order` smallint.

### 3.4. `identifier_rule`

::: dac-ta
**Mục đích.** EN-06-07 Khóa định danh và bộ kiểm tra của phiên bản mô hình (FR-06-003, BR-06-001). Mỗi domain cần ít nhất một khóa hoặc tổ hợp đối sánh (ERR-06-009, kiểm ở dịch vụ khi gửi duyệt).

**FR phục vụ.** FR-06-003; EN-06-07.

**Khóa chính.** (id).

**Duy nhất.** `uq_identifier_rule` (tenant_id, domain_code, version_no, identifier_type).

**Khóa ngoại.** (tenant_id, domain_code, version_no) → `domain_model`.

**Ràng buộc CHECK.** `ck_identifier_rule_` + `tenant`, `type`, `validator`, `regex`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Trigger: `tg_identifier_rule_child_frozen`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `identifier_type` | `varchar(16)` | Giá trị: `CCCD_12`, `CMND_9`, `MST_10_13`, `MSDN`, `MA_BHXH_10`, `MA_DVQHNS`, `DVHC_CODE`, `PASSPORT`. |
| `validator` | `varchar(16)` | Danh sách ở đầu vào FR-06-003; chữ số kiểm tra theo Q06-09. Giá trị: `CCCD_12`, `CMND_9`, `MST_10_13`, `MSDN`, `MA_BHXH_10`, `DVHC_CODE`, `REGEX`. |

: Cột của bảng `identifier_rule`

Cột khác: `domain_code` v(32); `version_no` int; `attribute_name` v(63); `pattern` v(500); `deterministic` bool; `unique_among_active` bool.

### 3.5. `mdm_source`

::: dac-ta
**Mục đích.** EN-06-08 Nguồn dữ liệu chủ gắn HTTT (FR-06-008, BR-06-032). trust_level 1…5; nguồn NATIONAL_DB chỉ nhận qua PH-14, không kết nối thẳng. Chỉ nguồn ACTIVE cho domain mới được nạp (ERR-06-014).

**FR phục vụ.** FR-06-008; EN-06-08.

**Khóa chính.** (id).

**Duy nhất.** `uq_mdm_source_code` (tenant_id, source_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_mdm_source_` + `tenant`, `code`, `kind`, `status`, `channels`, `domains`, `trust`, `system`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `source_code`, `tenant_id` (`tg_mdm_source_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `system_code` | `varchar(63), NULL` | Mã HTTT ở PH-01 (không khóa ngoại, khác schema); HTTT phải ACTIVE khi đăng ký (ERR-06-012). |
| `source_kind` | `varchar(24)` | Giá trị: `NATIONAL_DB`, `SECTOR_AUTHORITATIVE`, `SECTOR_RELATED`, `SECTOR_OTHER`, `MANUAL_ENTRY`, `FILE_BATCH`. |
| `status` | `varchar(16), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `ACTIVE`, `SUSPENDED`, `RETIRED`. |
| `domains` | `varchar(32)[]` | Mã domain ACTIVE được phép gửi; kiểm ở dịch vụ. |

: Cột của bảng `mdm_source`

Cột khác: `source_code` v(32); `name` v(255); `channels` v(16)[]; `attribute_scope` v(63)[]; `owner_org_code` v(63); `trust_level` smallint; `status_reason` v(2000).

### 3.6. `source_priority_proposal`

::: dac-ta
**Mục đích.** EN-06-04, EN-06-22 Đề nghị thứ tự ưu tiên nguồn chờ duyệt (FR-06-009, BR-06-004). Cần căn cứ văn bản approval_ref; DA duyệt khác người đề nghị (ERR-06-005, 013).

**FR phục vụ.** FR-06-009; EN-06-04, EN-06-22.

**Khóa chính.** (id).

**Duy nhất.** `uq_source_priority_proposal_tid` (tenant_id, id).

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`.

**Ràng buộc CHECK.** `ck_source_priority_proposal_` + `tenant`, `status`, `four_eyes`, `entries`, `decided`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_code`, `entries`, `approval_ref`, `proposed_by` (`tg_source_priority_proposal_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `entries` | `jsonb` | Mảng {sourceCode, attribute, priority} theo FR-06-009; áp vào source_priority khi duyệt. |
| `status` | `varchar(20), mặc định 'PENDING_APPROVAL'` | Giá trị: `PENDING_APPROVAL`, `ACTIVE`, `REJECTED`. |

: Cột của bảng `source_priority_proposal`

Cột khác: `domain_code` v(32); `approval_ref` v(255); `justification` v(2000); `proposed_by` v(64); `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000).

### 3.7. `source_priority`

::: dac-ta
**Mục đích.** EN-06-04 Mức ưu tiên nguồn theo domain và thuộc tính đang hiệu lực (FR-06-009, 033). attribute_name = '*' là mọi thuộc tính. Nguồn quốc gia luôn ưu tiên 1 với thuộc tính thẩm quyền quốc gia (BR-06-003). Bản cũ đóng bằng effective_to.

**FR phục vụ.** FR-06-009, 033; EN-06-04.

**Khóa chính.** (id).

**Duy nhất.** `uq_source_priority_current` (tenant_id, domain_code, source_code, attribute_name) có điều kiện.

**Khóa ngoại.** (tenant_id, source_code) → `mdm_source`, (tenant_id, proposal_id) → `source_priority_proposal`.

**Ràng buộc CHECK.** `ck_source_priority_` + `tenant`, `priority`, `attr`, `period`.

**Chỉ mục.** `ix_source_priority_domain`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `priority` | `smallint` | 1 cao nhất … 99 (FR-06-009). |

: Cột của bảng `source_priority`

Cột khác: `domain_code` v(32); `source_code` v(32); `attribute_name` v(63); `approval_ref` v(255); `proposal_id` uuid; `effective_from` tstz; `effective_to` tstz.

### 3.8. `candidate_file`

::: dac-ta
**Mục đích.** EN-06-25 FR-06-013 Tệp lô nạp ứng viên: tải lên, xem trước, xác nhận. Tệp ≤ 50 MB, ≤ 200.000 dòng (ERR-06-018, 019). Nội dung tệp nằm ở Ceph RGW (object_ref), không trong PostgreSQL; báo cáo xem trước ở preview jsonb, không chứa giá trị SENSITIVE.

**FR phục vụ.** FR-06-013; EN-06-25.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`, (tenant_id, source_code) → `mdm_source`.

**Ràng buộc CHECK.** `ck_candidate_file_` + `tenant`, `size`, `sha`, `confirm`.

**Chỉ mục.** `ix_candidate_file_domain`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_code`, `source_code`, `sha256` (`tg_candidate_file_immutable`).

**Ghi chú.** ETag là `version`.
:::

Cột khác: `domain_code` v(32); `source_code` v(32); `file_name` v(255); `size_bytes` bigint; `row_count` int; `object_ref` v(512); `sha256` char(64); `column_mapping` jsonb; `preview` jsonb; `previewed_at` tstz; `confirmed_by` v(64); `confirmed_at` tstz; `job_id` uuid; `expires_at` tstz.

### 3.9. `source_record_head`

::: dac-ta
**Mục đích.** EN-06-26 FR-06-016 Trạng thái mới nhất của mỗi bản ghi nguồn (sourceCode, sourceKey): phiên bản cao nhất đã nhận, ứng viên cuối, bản ghi vàng đang liên kết. Thực thi BR-06-028 (xử lý một lần theo sourceVersion) và BR-06-029 (bản đến trễ không ghi đè); là bảng nhỏ, khóa duy nhất không phải phân vùng.

**FR phục vụ.** FR-06-016; EN-06-26.

**Khóa chính.** (id).

**Duy nhất.** `uq_source_record_head` (tenant_id, domain_code, source_code, source_key).

**Khóa ngoại.** (tenant_id, source_code) → `mdm_source`.

**Ràng buộc CHECK.** `ck_source_record_head_` + `tenant`, `version`.

**Chỉ mục.** `ix_source_record_head_golden`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `golden_id` | `uuid, NULL` | Bản ghi vàng đang liên kết; tham chiếu logic để không khóa chéo khi hợp nhất. |

: Cột của bảng `source_record_head`

Cột khác: `domain_code` v(32); `source_code` v(32); `source_key` v(120); `last_version` bigint; `last_candidate_id` uuid; `last_source_updated_at` tstz; `deleted` bool.

### 3.10. `candidate_record`

::: dac-ta
**Mục đích.** EN-06-09 Bản ghi ứng viên nhận từ nguồn (FR-06-010…017). Dữ liệu gốc mã hóa envelope ở raw_enc; số định danh chỉ ở dạng HMAC identifier_hash; khóa gom nhóm là HMAC (BR-06-016). Phân vùng tháng theo received_at; giữ 365 ngày sau xử lý (retention_policy, khớp SRS cũ), sau đó ẩn danh hóa raw_enc.

**FR phục vụ.** FR-06-010, 011, 012, 013, 014, 015, 016, 017; EN-06-09.

**Khóa chính.** (id, received_at).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_candidate_record_` + `tenant`, `op`, `channel`, `status`, `idstatus`, `idtype`, `outcome`, `warnings`, `hash`, `raw`, `reject`, `birth`, `key`.

**Chỉ mục.** `ix_candidate_record_queue`, `ix_candidate_record_source`, `ix_candidate_record_idhash`, `ix_candidate_record_blocks`, `ix_candidate_record_name_trgm`, `ix_candidate_record_golden`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Phân vùng tháng theo `received_at`.

**Ghi chú.** Không có `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `operation` | `varchar(8)` | Giá trị: `CREATE`, `UPDATE`, `DELETE`. |
| `channel` | `varchar(16)` | Giá trị: `API`, `FLOW`, `EVENT`, `FILE`, `NATIONAL_SYNC`. |
| `status` | `varchar(24), mặc định 'RECEIVED'` | Giá trị: `RECEIVED`, `REJECTED`, `DUPLICATE`, `SUPERSEDED`, `NORMALIZATION_PENDING`, `NORMALIZED`, `QUEUED`, `LINKED`, `DISCARDED`. |
| `raw_enc` | `bytea, NULL` | Bản ghi gốc, mã hóa envelope (ADR-032); NULL sau khi dọn lưu giữ. |
| `name_norm` | `varchar(255), NULL` | Họ tên không dấu, chữ thường (pg_trgm, FR-06-021). |
| `identifier_type` | `varchar(16), NULL` | Giá trị: `CCCD_12`, `CMND_9`, `MST_10_13`, `MSDN`, `MA_BHXH_10`, `MA_DVQHNS`, `DVHC_CODE`, `PASSPORT`. |
| `identifier_status` | `varchar(20), NULL` | Giá trị: `VALID`, `INVALID_FORMAT`, `INVALID_CHECKSUM`, `PLACEHOLDER`, `MISSING`. |
| `identifier_hash` | `bytea, NULL` | HMAC-SHA256 của số định danh đã chuẩn hóa; dùng đối sánh xác định (FR-06-020). |
| `block_keys` | `varchar(72)[], NULL` | Khóa gom nhóm dạng HMAC có tiền tố tên khóa (FR-06-019). |
| `golden_id` | `uuid, NULL` | Bản ghi vàng liên kết; không khóa ngoại để giữ khi bảng vàng đổi. |
| `match_outcome` | `varchar(16), NULL` | Giá trị: `MATCH`, `POSSIBLE_MATCH`, `NO_MATCH`, `CONFLICT`. |

: Cột của bảng `candidate_record`

Cột khác: `id` uuid; `tenant_id` v(16); `received_at` tstz; `domain_code` v(32); `source_code` v(32); `source_key` v(120); `source_version` bigint; `source_updated_at` tstz; `model_version` int; `raw_kid` v(64); `attrs_norm` jsonb; `birth_year` smallint; `admin_unit_code` v(16); `warnings` v(24)[]; `attribute_count` smallint; `file_id` uuid; `flow_code` v(63); `exchange_id` v(64); `idempotency_key` v(128); `reject_code` v(16); `reject_detail` v(2000); `processed_at` tstz, phân vùng `RANGE (received_at)`.

### 3.11. `evaluation_report`

::: dac-ta
**Mục đích.** EN-06-23 FR-06-026 Báo cáo đánh giá chính xác (precision, recall) của một phiên bản bộ quy tắc trên tập nhãn (BR-06-021). Là căn cứ kích hoạt bộ quy tắc; tham chiếu bộ quy tắc theo (domain_code, rule_set_version) để tránh vòng khóa ngoại.

**FR phục vụ.** FR-06-026; EN-06-23.

**Khóa chính.** (id).

**Duy nhất.** `uq_evaluation_report_tid` (tenant_id, id).

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`.

**Ràng buộc CHECK.** `ck_evaluation_report_` + `tenant`, `verdict`, `pct`, `pass`.

**Chỉ mục.** `ix_evaluation_report_rule`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `verdict` | `varchar(8)` | PASSED chỉ khi ≥ 1.000 cặp, precision ≥ 99,9%, recall ≥ 98% (BR-06-021). Giá trị: `PASSED`, `FAILED`. |

: Cột của bảng `evaluation_report`

Cột khác: `domain_code` v(32); `rule_set_version` int; `label_set_code` v(63); `pair_count` int; `precision_pct` numeric(6,3); `recall_pct` numeric(6,3); `job_id` uuid; `confusion` jsonb; `evaluated_at` tstz.

### 3.12. `match_rule_set`

::: dac-ta
**Mục đích.** EN-06-10 Phiên bản bộ quy tắc đối sánh (FR-06-018, 019, 023). Ngưỡng ba vùng chốt ở CHECK (BR-06-020); ACTIVE phải có báo cáo đánh giá đạt (BR-06-021) và bất biến nội dung (BR-06-017). Duyệt bốn mắt.

**FR phục vụ.** FR-06-018, 019, 023; EN-06-10.

**Khóa chính.** (id).

**Duy nhất.** `uq_match_rule_set_tid` (tenant_id, id), `uq_match_rule_set_version` (tenant_id, domain_code, version_no), `uq_match_rule_set_active` (tenant_id, domain_code) có điều kiện.

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`, (tenant_id, evaluation_report_id) → `evaluation_report`.

**Ràng buộc CHECK.** `ck_match_rule_set_` + `tenant`, `status`, `decision`, `threshold`, `four_eyes`, `active`, `minattr`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_code`, `version_no` (`tg_match_rule_set_immutable`); Trigger: `tg_match_rule_set_frozen`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(20), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `TESTING`, `PENDING_APPROVAL`, `ACTIVE`, `SUPERSEDED`, `REJECTED`. |
| `blocking_keys` | `jsonb, mặc định '[]'` | Biểu thức khóa gom nhóm, ví dụ prefix(nameAscii.given,3)+year(dateOfBirth) (FR-06-019). |
| `splink_params` | `jsonb, NULL` | Tham số m, u của Splink sau huấn luyện (FR-06-022). |
| `decision` | `varchar(8), NULL` | Giá trị: `APPROVE`, `REJECT`. |

: Cột của bảng `match_rule_set`

Cột khác: `domain_code` v(32); `version_no` int; `auto_merge_threshold` numeric(3,2); `review_threshold` numeric(3,2); `auto_merge_enabled` bool; `min_attributes` smallint; `evaluation_report_id` uuid; `submitted_by` v(64); `submitted_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `activated_at` tstz; `superseded_at` tstz.

### 3.13. `match_rule`

::: dac-ta
**Mục đích.** EN-06-10 Quy tắc con của bộ quy tắc: xác định, xác suất, loại trừ (FR-06-018). Quy tắc EXCLUSION cho khóa định danh khác nhau không tắt được (BR-06-006). Tổng trọng số PROBABILISTIC bằng 1,00 kiểm ở dịch vụ khi gửi duyệt.

**FR phục vụ.** FR-06-018; EN-06-10.

**Khóa chính.** (id).

**Duy nhất.** `uq_match_rule_seq` (tenant_id, domain_code, version_no, seq).

**Khóa ngoại.** (tenant_id, domain_code, version_no) → `match_rule_set`.

**Ràng buộc CHECK.** `ck_match_rule_` + `tenant`, `type`, `comparator`, `weight`, `prob`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Trigger: `tg_match_rule_child_frozen`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `rule_type` | `varchar(16)` | Giá trị: `DETERMINISTIC`, `PROBABILISTIC`, `EXCLUSION`. |
| `comparator` | `varchar(16)` | Giá trị: `EXACT`, `TRIGRAM`, `JARO_WINKLER`, `NAME_VN`, `DATE_TOLERANCE`, `ADMIN_UNIT`, `PHONE`. |

: Cột của bảng `match_rule`

Cột khác: `domain_code` v(32); `version_no` int; `seq` smallint; `attribute_name` v(63); `weight` numeric(5,4); `params` jsonb.

### 3.14. `match_job`

::: dac-ta
**Mục đích.** EN-06-12 Job theo lô và job nền (FR-06-022, 056): đối sánh Splink, chạy thử, đánh giá, áp lại sống sót, mã hóa lại, nạp tệp, xuất, đồng bộ quốc gia, dọn lưu giữ. Máy trạng thái 4.5. Một job đang chạy mỗi (domain, loại) (ERR-06-025). Job lô vượt safety-ratio dừng ở AWAITING_CONFIRMATION (BR-06-022).

**FR phục vụ.** FR-06-022, 056; EN-06-12.

**Khóa chính.** (id).

**Duy nhất.** `uq_match_job_tid` (tenant_id, id), `uq_match_job_running` (tenant_id, domain_code, job_type) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_match_job_` + `tenant`, `domain`, `type`, `status`, `scope`, `error`, `failed`, `cancel`, `confirm`, `finished`.

**Chỉ mục.** `ix_match_job_list`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `job_type`, `domain_code`, `requested_by` (`tg_match_job_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `job_type` | `varchar(24)` | Giá trị: `BATCH_MATCH`, `RULE_DRY_RUN`, `ACCURACY_EVAL`, `SURVIVORSHIP_REAPPLY`, `REENCRYPT`, `FILE_INGEST`, `EXPORT`, `NATIONAL_SYNC_DOWN`, `NATIONAL_SYNC_UP`, `NATIONAL_RECONCILE`, `RETENTION_PURGE`. |
| `status` | `varchar(24), mặc định 'QUEUED'` | Giá trị: `QUEUED`, `PREPARING`, `RUNNING`, `AWAITING_CONFIRMATION`, `APPLYING`, `SUCCEEDED`, `PARTIALLY_SUCCEEDED`, `FAILED`, `CANCELLED`. |
| `scope` | `varchar(24), NULL` | Giá trị: `GOLDEN_VS_GOLDEN`, `CANDIDATES_SINCE`, `FULL_INITIAL`. |
| `counts` | `jsonb, mặc định '{}'` | input, pairs, match, possible, noMatch, applied, skipped (FR-06-022). |
| `confirmed_by` | `varchar(64), NULL` | DA xác nhận job vượt ngưỡng an toàn, khác người yêu cầu. |

: Cột của bảng `match_job`

Cột khác: `domain_code` v(32); `since` tstz; `train_only` bool; `dry_run` bool; `rule_set_version` int; `requested_by` v(64); `parent_job_id` uuid; `parameters` jsonb; `k8s_job_name` v(63); `started_at` tstz; `finished_at` tstz; `confirmed_at` tstz; `cancel_reason` v(2000); `error_code` v(16); `error_detail` v(2000).

### 3.15. `job_schedule`

::: dac-ta
**Mục đích.** EN-06-24 FR-06-056 Lịch job tự động theo loại (cron giờ Việt Nam). Mỗi tenant một dòng cho mỗi JobType; ScheduleJob (ShedLock) đọc next_run_at.

**FR phục vụ.** FR-06-056; EN-06-24.

**Khóa chính.** (id).

**Duy nhất.** `uq_job_schedule_type` (tenant_id, job_type).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_job_schedule_` + `tenant`, `type`, `duration`, `cron`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `job_type` (`tg_job_schedule_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `job_type` | `varchar(24)` | Giá trị: `BATCH_MATCH`, `RULE_DRY_RUN`, `ACCURACY_EVAL`, `SURVIVORSHIP_REAPPLY`, `REENCRYPT`, `FILE_INGEST`, `EXPORT`, `NATIONAL_SYNC_DOWN`, `NATIONAL_SYNC_UP`, `NATIONAL_RECONCILE`, `RETENTION_PURGE`. |

: Cột của bảng `job_schedule`

Cột khác: `cron` v(64); `enabled` bool; `params` jsonb; `max_duration_minutes` int; `next_run_at` tstz; `last_run_at` tstz; `last_job_id` uuid.

### 3.16. `match_staging`

::: dac-ta
**Mục đích.** EN-06-27 FR-06-022 Bảng trung gian xuất cho Job K8s Splink đọc (SAD: đối sánh lô qua staging). Chỉ chứa trường chuẩn hóa không SENSITIVE và HMAC; xóa sau job (retention 7 ngày, BR-06-031). Job Splink đọc bằng vai trò ph06_splink (chỉ SELECT match_staging, chỉ INSERT match_result), không ghi thẳng vào bản ghi vàng.

**FR phục vụ.** FR-06-022; EN-06-27.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, job_id) → `match_job` xóa theo.

**Ràng buộc CHECK.** `ck_match_staging_` + `tenant`, `ref`.

**Chỉ mục.** `ix_match_staging_job`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** Không có `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `fields` | `jsonb` | Thuộc tính chuẩn hóa; trường SENSITIVE chỉ dạng HMAC, không bao giờ bản rõ (BR-06-016). |

: Cột của bảng `match_staging`

Cột khác: `id` uuid; `tenant_id` v(16); `job_id` uuid; `candidate_id` uuid; `golden_id` uuid; `source_version` bigint; `block_keys` v(72)[]; `exported_at` tstz.

### 3.17. `match_result`

::: dac-ta
**Mục đích.** EN-06-11 Kết quả đối sánh một cặp (ứng viên hoặc bản ghi vàng với bản ghi vàng) (FR-06-020…023). Lưu điểm từng thuộc tính theo ComparisonLevel để giải thích. Phân vùng tháng theo scored_at; giữ 2 năm để hiệu chỉnh thuật toán (SRS cũ 4.3).

**FR phục vụ.** FR-06-020, 021, 022, 023; EN-06-11.

**Khóa chính.** (id, scored_at).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_match_result_` + `tenant`, `method`, `outcome`, `left`, `score`, `skip`, `deterministic`.

**Chỉ mục.** `ix_match_result_candidate`, `ix_match_result_golden`, `ix_match_result_job`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Phân vùng tháng theo `scored_at`.

**Ghi chú.** Không có `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `method` | `varchar(24)` | Giá trị: `DETERMINISTIC`, `PROBABILISTIC_ONLINE`, `PROBABILISTIC_BATCH`, `MANUAL`, `NATIONAL_SYNC`. |
| `outcome` | `varchar(16)` | Giá trị: `MATCH`, `POSSIBLE_MATCH`, `NO_MATCH`, `CONFLICT`. |

: Cột của bảng `match_result`

Cột khác: `id` uuid; `tenant_id` v(16); `scored_at` tstz; `domain_code` v(32); `left_candidate_id` uuid; `left_golden_id` uuid; `right_golden_id` uuid; `score` numeric(5,4); `attribute_scores` jsonb; `rule_set_version` int; `job_id` uuid; `queue_item_id` uuid; `applied` bool; `applied_operation_id` uuid; `skip_code` v(16), phân vùng `RANGE (scored_at)`.

### 3.18. `label_set`

::: dac-ta
**Mục đích.** EN-06-15 Tập nhãn kiểm chứng (FR-06-025): EVALUATION để đo precision, recall; TRAINING để huấn luyện Splink. Nghiệm thu cần ≥ 10.000 cặp (NFR-06-008).

**FR phục vụ.** FR-06-008, 025; EN-06-15.

**Khóa chính.** (id).

**Duy nhất.** `uq_label_set_tid` (tenant_id, id), `uq_label_set_code` (tenant_id, label_set_code).

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`.

**Ràng buộc CHECK.** `ck_label_set_` + `tenant`, `code`, `purpose`, `count`, `locked`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `label_set_code`, `domain_code`, `purpose` (`tg_label_set_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `purpose` | `varchar(16)` | Giá trị: `EVALUATION`, `TRAINING`. |

: Cột của bảng `label_set`

Cột khác: `label_set_code` v(63); `domain_code` v(32); `description` v(2000); `pair_count` int; `locked` bool; `locked_at` tstz; `locked_by` v(64).

### 3.19. `label_pair`

::: dac-ta
**Mục đích.** EN-06-15 Cặp có nhãn MATCH, NO_MATCH của tập nhãn (FR-06-025, 030 addToLabelSet). Hai đầu theo thứ tự chuẩn left_id < right_id; ảnh chụp thuộc tính hai bên mã hóa để đánh giá lặp lại ổn định.

**FR phục vụ.** FR-06-025, 030; EN-06-15.

**Khóa chính.** (id).

**Duy nhất.** `uq_label_pair` (tenant_id, label_set_id, left_id, right_id).

**Khóa ngoại.** (tenant_id, label_set_id) → `label_set`.

**Ràng buộc CHECK.** `ck_label_pair_` + `tenant`, `label`, `order`, `snapshot`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `label_set_id`, `left_id`, `right_id` (`tg_label_pair_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `label` | `varchar(8)` | Giá trị: `MATCH`, `NO_MATCH`. |

: Cột của bảng `label_pair`

Cột khác: `label_set_id` uuid; `left_id` uuid; `right_id` uuid; `labeled_by` v(64); `source_item_id` uuid; `snapshot_enc` bytea; `snapshot_kid` v(64).

### 3.20. `steward_item`

::: dac-ta
**Mục đích.** EN-06-05 Mục hàng đợi người quản lý dữ liệu (FR-06-027…032). Máy trạng thái 4.4. Quyết định cần lý do ≥ 20 ký tự (BR-06-008); MATCH rủi ro cao chờ DA duyệt khác người quyết định (BR-06-019, ERR-06-005). Mỗi cặp một mục mở.

**FR phục vụ.** FR-06-027, 028, 029, 030, 031, 032; EN-06-05.

**Khóa chính.** (id).

**Duy nhất.** `uq_steward_item_tid` (tenant_id, id), `uq_steward_item_open_pair` (tenant_id, domain_code, COALESCE(left_candidate_id, left_golden_id), right_golden_id) có điều kiện.

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`.

**Ràng buộc CHECK.** `ck_steward_item_` + `tenant`, `reason`, `status`, `risk`, `decision`, `approval`, `priority`, `left`, `reason20`, `four_eyes`, `pending`, `resolved`, `assigned`, `defer`.

**Chỉ mục.** `ix_steward_item_queue`, `ix_steward_item_assignee`, `ix_steward_item_nomatch`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_code`, `left_candidate_id`, `left_golden_id`, `right_golden_id` (`tg_steward_item_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `reason` | `varchar(24)` | Giá trị: `POSSIBLE_MATCH`, `MULTIPLE_CANDIDATES`, `INSUFFICIENT_ATTRIBUTES`, `CRITICAL_CONFLICT`, `IDENTIFIER_CONFLICT`, `ORPHANED`, `TIMEOUT`. |
| `status` | `varchar(20), mặc định 'OPEN'` | Giá trị: `OPEN`, `ASSIGNED`, `DEFERRED`, `PENDING_APPROVAL`, `RESOLVED`, `CANCELLED`. |
| `risk_level` | `varchar(4), mặc định 'LOW'` | Giá trị: `LOW`, `HIGH`. |
| `left_golden_id` | `uuid, NULL` | Cặp NO_MATCH đã RESOLVED là liên kết âm (BR-06-023): không đề xuất lại; chỉ mục ix_steward_item_nomatch. |
| `hold_until` | `timestamptz, NULL` | Hết hạn giữ 30 phút (06.queue.hold-minutes) thì trả OPEN. |
| `decision` | `varchar(8), NULL` | Giá trị: `MATCH`, `NO_MATCH`, `DEFER`. |
| `approval_decision` | `varchar(8), NULL` | Giá trị: `APPROVE`, `REJECT`. |

: Cột của bảng `steward_item`

Cột khác: `domain_code` v(32); `priority` smallint; `left_candidate_id` uuid; `right_golden_id` uuid; `match_result_id` uuid; `score` numeric(5,4); `attribute_scores` jsonb; `source_codes` v(32)[]; `assignee` v(64); `claimed_at` tstz; `due_at` tstz; `escalated_at` tstz; `defer_until` tstz; `decision_reason` v(2000); `decided_by` v(64); `decided_at` tstz; `survivor_id` uuid; `approved_by` v(64); `approved_at` tstz; `approval_comment` v(2000); `operation_id` uuid; `cancel_reason` v(500); `reopen_count` smallint; `reopened_at` tstz; `reopened_by` v(64); `reopen_reason` v(2000); `decision_history` jsonb.

### 3.21. `golden_record`

::: dac-ta
**Mục đích.** EN-06-01 Bản ghi vàng (FR-06-034…042). goldenId là id (UUIDv7); version bắt đầu 1 và tăng mỗi thay đổi, là số phiên bản trong lịch sử. Không xóa (BR-06-007): chỉ MERGED hoặc RETIRED. Cột display_name, name_norm, birth_year, admin_unit_code là bản sao có chỉ mục để tìm nhanh bằng pg_trgm.

**FR phục vụ.** FR-06-034, 035, 036, 037, 038, 039, 040, 041, 042; EN-06-01.

**Khóa chính.** (id).

**Duy nhất.** `uq_golden_record_tid` (tenant_id, id).

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`, (tenant_id, merged_into) → `golden_record`.

**Ràng buộc CHECK.** `ck_golden_record_` + `tenant`, `status`, `merged`, `retired`, `retire`, `locked`, `restricted`, `confidence`, `birth`.

**Chỉ mục.** `ix_golden_record_domain`, `ix_golden_record_name_trgm`, `ix_golden_record_blocks`, `ix_golden_record_area`, `ix_golden_record_merged`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_code` (`tg_golden_record_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `model_version` | `integer` | Phiên bản mô hình domain áp khi tạo hoặc cập nhật gần nhất. |
| `status` | `varchar(8), mặc định 'ACTIVE'` | Giá trị: `ACTIVE`, `LOCKED`, `MERGED`, `RETIRED`. |
| `name_norm` | `varchar(255), NULL` | Họ tên hoặc tên tổ chức không dấu, chữ thường; chỉ mục GIN gin_trgm_ops (cần btree_gin cho domain_code). |
| `retire_reason` | `varchar(16), NULL` | Giá trị: `ORPHANED`, `DISSOLVED`, `DECEASED`, `TEST_DATA`, `OTHER`. |

: Cột của bảng `golden_record`

Cột khác: `domain_code` v(32); `merged_into` uuid; `confidence` numeric(5,4); `display_name` v(255); `birth_year` smallint; `admin_unit_code` v(16); `link_count` int; `block_keys` v(72)[]; `restricted` bool; `lock_reason` v(500); `retire_note` v(2000); `retired_at` tstz; `retired_by` v(64); `national_synced_at` tstz.

### 3.22. `golden_attribute`

::: dac-ta
**Mục đích.** EN-06-02 Giá trị thuộc tính vàng kèm nguồn ở cấp thuộc tính (FR-06-034, 035, BR-06-009). SENSITIVE chỉ ở value_enc kèm value_hash, không ở value_json (CHECK, NFR-06-016). Thuộc tính đa trị dùng seq. Sửa tay tạm thời có hạn manual_valid_until (BR-06-014).

**FR phục vụ.** FR-06-016, 034, 035; EN-06-02.

**Khóa chính.** (id).

**Duy nhất.** `uq_golden_attribute` (tenant_id, golden_id, attribute_name, seq).

**Khóa ngoại.** (tenant_id, golden_id) → `golden_record`.

**Ràng buộc CHECK.** `ck_golden_attribute_` + `tenant`, `class`, `strategy`, `name`, `sensitive`, `hash`, `manual`, `authority`.

**Chỉ mục.** `ix_golden_attribute_hash`, `ix_golden_attribute_source`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `data_class` | `varchar(16)` | Giá trị: `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE`. |
| `value_hash` | `bytea, NULL` | HMAC-SHA256 giá trị đã chuẩn hóa; đối sánh bằng, không giải mã (BR-06-016). |
| `strategy` | `varchar(24)` | Giá trị: `NATIONAL_AUTHORITY`, `MANUAL_OVERRIDE`, `SOURCE_PRIORITY`, `MOST_RECENT`, `MOST_COMPLETE`, `MOST_FREQUENT`, `FIRST_VALUE`. |
| `manual_valid_until` | `timestamptz, NULL` | Sửa tay có hạn ≤ 90 ngày, mặc định 30 (FR-06-036). |
| `national_authority` | `boolean, mặc định false` | Thuộc tính thẩm quyền quốc gia: không sửa tay (BR-06-025). |

: Cột của bảng `golden_attribute`

Cột khác: `golden_id` uuid; `attribute_name` v(63); `seq` smallint; `value_json` jsonb; `value_enc` bytea; `value_kid` v(64); `source_code` v(32); `source_key` v(120); `source_updated_at` tstz; `confidence` numeric(5,4).

### 3.23. `golden_identifier`

::: dac-ta
**Mục đích.** EN-06-02, EN-06-28 Chỉ mục số định danh của bản ghi vàng (FR-06-020, 046, BR-06-001, 006). Một giá trị định danh hiệu lực chỉ thuộc một bản ghi vàng trong domain (chỉ mục duy nhất một phần), nên hai bản ghi vàng cùng CCCD không tồn tại (ERR-06-112 là lỗi bất biến). Giá trị rõ không lưu; value_enc mã hóa envelope, value_hash HMAC.

**FR phục vụ.** FR-06-020, 046; EN-06-02, EN-06-28.

**Khóa chính.** (id).

**Duy nhất.** `uq_golden_identifier_active` (tenant_id, domain_code, identifier_type, value_hash) có điều kiện.

**Khóa ngoại.** (tenant_id, golden_id) → `golden_record`.

**Ràng buộc CHECK.** `ck_golden_identifier_` + `tenant`, `type`, `hash`.

**Chỉ mục.** `ix_golden_identifier_golden`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `golden_id`, `domain_code`, `identifier_type`, `value_hash` (`tg_golden_identifier_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `identifier_type` | `varchar(16)` | Giá trị: `CCCD_12`, `CMND_9`, `MST_10_13`, `MSDN`, `MA_BHXH_10`, `MA_DVQHNS`, `DVHC_CODE`, `PASSPORT`. |

: Cột của bảng `golden_identifier`

Cột khác: `golden_id` uuid; `domain_code` v(32); `value_hash` bytea; `value_enc` bytea; `value_kid` v(64); `active` bool.

### 3.24. `source_xref`

::: dac-ta
**Mục đích.** EN-06-03 Liên kết chéo nguồn (sourceCode, sourceKey) với bản ghi vàng (FR-06-044, 045, BR-06-018). Một bản ghi nguồn chỉ có một liên kết ACTIVE tại một thời điểm (chỉ mục duy nhất một phần). Gỡ ghi lý do; liên kết do người xác nhận không bị tự tách (BR-06-023).

**FR phục vụ.** FR-06-044, 045; EN-06-03.

**Khóa chính.** (id).

**Duy nhất.** `uq_source_xref_tid` (tenant_id, id), `uq_source_xref_active` (tenant_id, domain_code, source_code, source_key) có điều kiện.

**Khóa ngoại.** (tenant_id, golden_id) → `golden_record`, (tenant_id, source_code) → `mdm_source`.

**Ràng buộc CHECK.** `ck_source_xref_` + `tenant`, `status`, `method`, `detach`, `detached`, `moved`, `manual`.

**Chỉ mục.** `ix_source_xref_golden`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_code`, `source_code`, `source_key` (`tg_source_xref_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(8), mặc định 'ACTIVE'` | Giá trị: `ACTIVE`, `DETACHED`, `MOVED`. |
| `match_method` | `varchar(24)` | Giá trị: `DETERMINISTIC`, `PROBABILISTIC_ONLINE`, `PROBABILISTIC_BATCH`, `MANUAL`, `NATIONAL_SYNC`. |
| `detach_reason` | `varchar(16), NULL` | Giá trị: `MANUAL`, `SOURCE_DELETED`, `SPLIT`. |

: Cột của bảng `source_xref`

Cột khác: `domain_code` v(32); `golden_id` uuid; `source_code` v(32); `source_key` v(120); `score` numeric(5,4); `candidate_id` uuid; `confirmed_by_steward` bool; `linked_by` v(64); `linked_at` tstz; `detached_at` tstz; `detached_by` v(64); `detach_note` v(2000); `moved_to_golden_id` uuid.

### 3.25. `golden_operation`

::: dac-ta
**Mục đích.** EN-06-13 Thao tác trên bản ghi vàng: hợp nhất, tách, sửa tay, hoàn tác, ngừng, khôi phục, áp lại sống sót (FR-06-036…042). Mọi thay đổi bản ghi vàng đi qua một thao tác (BR-06-005). Lý do ≥ 20 ký tự (BR-06-008); rủi ro cao chờ DA duyệt khác người yêu cầu (BR-06-019). Hoàn tác là thao tác mới trỏ undo_of, không xóa lịch sử (BR-06-024).

**FR phục vụ.** FR-06-036, 037, 038, 039, 040, 041, 042; EN-06-13.

**Khóa chính.** (id).

**Duy nhất.** `uq_golden_operation_tid` (tenant_id, id), `uq_golden_operation_undo` (tenant_id, undo_of) có điều kiện.

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`, (tenant_id, undo_of) → `golden_operation`.

**Ràng buộc CHECK.** `ck_golden_operation_` + `tenant`, `type`, `status`, `risk`, `decision`, `reason20`, `four_eyes`, `pending`, `applied`, `undo`, `merge`.

**Chỉ mục.** `ix_golden_operation_golden`, `ix_golden_operation_pending`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_code`, `change_type`, `golden_ids`, `reason`, `requested_by`, `requested_at`, `undo_of` (`tg_golden_operation_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `change_type` | `varchar(24)` | Giá trị: `CREATE`, `UPDATE`, `MANUAL_EDIT`, `MERGE`, `SPLIT`, `UNDO`, `RETIRE`, `RESTORE`, `NATIONAL_SYNC`, `SURVIVORSHIP_REAPPLY`, `DSR_CORRECTION`, `XREF_DETACH`. |
| `status` | `varchar(20), mặc định 'APPLIED'` | Giá trị: `PENDING_APPROVAL`, `APPLIED`, `REJECTED`, `UNDONE`. |
| `risk_level` | `varchar(4), mặc định 'LOW'` | Giá trị: `LOW`, `HIGH`. |
| `decision` | `varchar(8), NULL` | Giá trị: `APPROVE`, `REJECT`. |
| `batch_job_id` | `uuid, NULL` | batchOperationId của job lô (NFR, tiêu chí 9). |

: Cột của bảng `golden_operation`

Cột khác: `domain_code` v(32); `golden_ids` uuid[]; `survivor_id` uuid; `result_golden_ids` uuid[]; `reason` v(2000); `evidence_ref` v(255); `payload` jsonb; `requested_by` v(64); `requested_at` tstz; `approved_by` v(64); `approved_at` tstz; `decision_comment` v(2000); `applied_at` tstz; `undo_of` uuid; `source_item_id` uuid.

### 3.26. `golden_history`

::: dac-ta
**Mục đích.** EN-06-06 Ảnh chụp đầy đủ bản ghi vàng (thuộc tính, liên kết) trước mỗi thay đổi, cùng giao dịch (BR-06-005). Phục vụ xem phiên bản, so sánh, hoàn tác. snapshot_enc mã hóa envelope vì chứa DLCN. Chỉ thêm, không sửa (trigger). Phân vùng tháng theo changed_at; chuyển lưu trữ lạnh sau 5 năm, không xóa (BR-06-007, SRS cũ: vĩnh viễn).

**FR phục vụ.** Hạ tầng dùng chung; EN-06-06.

**Khóa chính.** (id, changed_at).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, golden_id) → `golden_record`.

**Ràng buộc CHECK.** `ck_golden_history_` + `tenant`, `type`, `sha`, `version`, `snapshot`.

**Chỉ mục.** `ix_golden_history_golden`, `ix_golden_history_operation`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Phân vùng tháng theo `changed_at`; Trigger: `tg_golden_history_append_only`.

**Ghi chú.** Không có `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `change_type` | `varchar(24)` | Giá trị: `CREATE`, `UPDATE`, `MANUAL_EDIT`, `MERGE`, `SPLIT`, `UNDO`, `RETIRE`, `RESTORE`, `NATIONAL_SYNC`, `SURVIVORSHIP_REAPPLY`, `DSR_CORRECTION`, `XREF_DETACH`. |

: Cột của bảng `golden_history`

Cột khác: `id` uuid; `tenant_id` v(16); `changed_at` tstz; `golden_id` uuid; `version_no` int; `operation_id` uuid; `snapshot_enc` bytea; `snapshot_kid` v(64); `snapshot_sha256` bytea; `changed_attributes` v(63)[]; `changed_by` v(64), phân vùng `RANGE (changed_at)`.

### 3.27. `attribute_lineage`

::: dac-ta
**Mục đích.** EN-06-14 Lịch sử giá trị và nguồn của từng thuộc tính vàng (FR-06-043, BR-06-009): giá trị nào, từ nguồn nào, chiến lược nào chọn, lúc nào. Giá trị mã hóa envelope; value_hash để so khớp. Chỉ thêm. Phân vùng tháng theo recorded_at; chuyển lưu trữ lạnh sau 5 năm, không xóa.

**FR phục vụ.** FR-06-043; EN-06-14.

**Khóa chính.** (id, recorded_at).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, golden_id) → `golden_record`.

**Ràng buộc CHECK.** `ck_attribute_lineage_` + `tenant`, `strategy`, `class`, `hash`, `enc`.

**Chỉ mục.** `ix_attribute_lineage_golden`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Phân vùng tháng theo `recorded_at`; Trigger: `tg_attribute_lineage_append_only`.

**Ghi chú.** Không có `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `strategy` | `varchar(24)` | Giá trị: `NATIONAL_AUTHORITY`, `MANUAL_OVERRIDE`, `SOURCE_PRIORITY`, `MOST_RECENT`, `MOST_COMPLETE`, `MOST_FREQUENT`, `FIRST_VALUE`. |
| `data_class` | `varchar(16)` | Giá trị: `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE`. |

: Cột của bảng `attribute_lineage`

Cột khác: `id` uuid; `tenant_id` v(16); `recorded_at` tstz; `golden_id` uuid; `golden_version` int; `attribute_name` v(63); `seq` smallint; `operation_id` uuid; `source_code` v(32); `source_key` v(120); `source_version` bigint; `source_updated_at` tstz; `selected` bool; `value_enc` bytea; `value_kid` v(64); `value_hash` bytea, phân vùng `RANGE (recorded_at)`.

### 3.28. `survivorship_rule_set`

::: dac-ta
**Mục đích.** EN-06-17 Phiên bản bộ quy tắc sống sót của domain (FR-06-033, 042). Vòng đời 4.6 (không TESTING); một phiên bản ACTIVE mỗi domain; duyệt bốn mắt có căn cứ văn bản (BR-06-004).

**FR phục vụ.** FR-06-033, 042; EN-06-17.

**Khóa chính.** (id).

**Duy nhất.** `uq_survivorship_rule_set_tid` (tenant_id, id), `uq_survivorship_rule_set_version` (tenant_id, domain_code, version_no), `uq_survivorship_rule_set_active` (tenant_id, domain_code) có điều kiện.

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`.

**Ràng buộc CHECK.** `ck_survivorship_rule_set_` + `tenant`, `status`, `decision`, `four_eyes`, `active`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_code`, `version_no` (`tg_survivorship_rule_set_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(20), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `PENDING_APPROVAL`, `ACTIVE`, `SUPERSEDED`, `REJECTED`. |
| `decision` | `varchar(8), NULL` | Giá trị: `APPROVE`, `REJECT`. |

: Cột của bảng `survivorship_rule_set`

Cột khác: `domain_code` v(32); `version_no` int; `comment` v(2000); `approval_ref` v(255); `submitted_by` v(64); `submitted_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `activated_at` tstz.

### 3.29. `survivorship_rule`

::: dac-ta
**Mục đích.** EN-06-17 Chiến lược sống sót theo thuộc tính trong một phiên bản (FR-06-033). strategies là chuỗi SurvivorshipStrategy theo thứ tự áp; thuộc tính thẩm quyền quốc gia bắt đầu bằng NATIONAL_AUTHORITY (BR-06-003, 025).

**FR phục vụ.** FR-06-033; EN-06-17.

**Khóa chính.** (id).

**Duy nhất.** `uq_survivorship_rule_attr` (tenant_id, domain_code, version_no, attribute_name).

**Khóa ngoại.** (tenant_id, domain_code, version_no) → `survivorship_rule_set`.

**Ràng buộc CHECK.** `ck_survivorship_rule_` + `tenant`, `strategies`, `authority`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Trigger: `tg_survivorship_rule_child_frozen`.

**Ghi chú.** ETag là `version`.
:::

Cột khác: `domain_code` v(32); `version_no` int; `attribute_name` v(63); `strategies` v(24)[]; `critical_conflict_to_queue` bool; `national_authority` bool.

### 3.30. `update_subscription`

::: dac-ta
**Mục đích.** EN-06-18 Đăng ký nhận cập nhật bản ghi vàng của HTTT (FR-06-051). Cần mục đích khai thác đã được PH-09 chấp thuận (ERR-06-043). Kênh giao qua đăng ký PH-10 (ph10_subscription_code). Duyệt bốn mắt.

**FR phục vụ.** FR-06-051; EN-06-18.

**Khóa chính.** (id).

**Duy nhất.** `uq_update_subscription_live` (tenant_id, system_code, domain_code, scope) có điều kiện.

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`.

**Ràng buộc CHECK.** `ck_update_subscription_` + `tenant`, `scope`, `status`, `delivery`, `events`, `four_eyes`, `active`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `system_code`, `domain_code`, `requested_by` (`tg_update_subscription_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `scope` | `varchar(16)` | Giá trị: `LINKED_ONLY`, `DOMAIN`. |
| `delivery` | `varchar(4)` | Giá trị: `PUSH`, `PULL`. |
| `status` | `varchar(20), mặc định 'PENDING_APPROVAL'` | Giá trị: `PENDING_APPROVAL`, `ACTIVE`, `SUSPENDED`, `REVOKED`. |

: Cột của bảng `update_subscription`

Cột khác: `system_code` v(63); `domain_code` v(32); `event_types` v(32)[]; `purpose_code` v(63); `ph10_subscription_code` v(63); `requested_by` v(64); `approved_by` v(64); `approved_at` tstz; `status_reason` v(2000).

### 3.31. `export_request`

::: dac-ta
**Mục đích.** EN-06-19 Yêu cầu xuất dữ liệu chủ có duyệt (FR-06-049, BR-06-027): cần chấp thuận của DO các nguồn liên quan và DA; tệp mã hóa, có thủy vân, hạn tải 24 giờ. Tệp ở Ceph RGW (file_ref), không trong PostgreSQL. Giới hạn dòng theo 06.export.max-rows (ERR-06-041).

**FR phục vụ.** FR-06-049; EN-06-19.

**Khóa chính.** (id).

**Duy nhất.** `uq_export_request_tid` (tenant_id, id).

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`.

**Ràng buộc CHECK.** `ck_export_request_` + `tenant`, `format`, `status`, `four_eyes`, `owner`, `approved`, `ready`, `rejected`, `rows`.

**Chỉ mục.** `ix_export_request_status`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_code`, `filter`, `fields`, `format`, `purpose_code`, `requested_by` (`tg_export_request_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `format` | `varchar(8)` | Giá trị: `CSV`, `XLSX`, `JSONL`. |
| `status` | `varchar(20), mặc định 'PENDING_APPROVAL'` | Giá trị: `PENDING_APPROVAL`, `APPROVED`, `REJECTED`, `GENERATING`, `READY`, `EXPIRED`. |
| `expires_at` | `timestamptz, NULL` | ready_at + 24 giờ (BR-06-027); sau đó EXPIRED, ERR-06-042. |

: Cột của bảng `export_request`

Cột khác: `domain_code` v(32); `filter` jsonb; `fields` v(63)[]; `purpose_code` v(63); `legal_basis` v(2000); `recipient` v(255); `pseudonymize` bool; `row_count` int; `requested_by` v(64); `owner_approved_by` v(64); `owner_approved_at` tstz; `approved_by` v(64); `approved_at` tstz; `reject_reason` v(2000); `file_ref` v(512); `file_sha256` char(64); `watermark_id` v(64); `ready_at` tstz; `downloaded_at` tstz.

### 3.32. `national_sync_state`

::: dac-ta
**Mục đích.** EN-06-29 FR-06-053, 054 Trạng thái đồng bộ quốc gia mỗi domain: RUNNING hoặc PAUSED. Lệch > 06.sync.pause-ratio tạm dừng tự động (BR-06-011, ERR-06-107); tiếp tục cần người có PERM-06-sync.

**FR phục vụ.** FR-06-053, 054; EN-06-29.

**Khóa chính.** (id).

**Duy nhất.** `uq_national_sync_state_domain` (tenant_id, domain_code).

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`.

**Ràng buộc CHECK.** `ck_national_sync_state_` + `tenant`, `state`, `paused`, `ratio`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_code` (`tg_national_sync_state_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `state` | `varchar(8), mặc định 'RUNNING'` | Giá trị: `RUNNING`, `PAUSED`. |

: Cột của bảng `national_sync_state`

Cột khác: `domain_code` v(32); `paused_reason` v(2000); `paused_at` tstz; `paused_by` v(64); `last_run_id` uuid; `last_ratio` numeric(6,5).

### 3.33. `national_sync_run`

::: dac-ta
**Mục đích.** EN-06-16 Nhật ký một lượt đồng bộ với CSDL tổng hợp quốc gia qua PH-14 (FR-06-053). Tỷ lệ lệch ratio so với ngưỡng BR-06-011. PH-06 không gọi trực tiếp CSDL quốc gia (BR-06-032); ph14_ref là mã giao dịch PH-14.

**FR phục vụ.** FR-06-053; EN-06-16.

**Khóa chính.** (id).

**Duy nhất.** `uq_national_sync_run_tid` (tenant_id, id).

**Khóa ngoại.** (tenant_id, domain_code) → `mdm_domain`.

**Ràng buộc CHECK.** `ck_national_sync_run_` + `tenant`, `direction`, `counts`, `error`, `ratio`.

**Chỉ mục.** `ix_national_sync_run_domain`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `direction` | `varchar(12)` | Giá trị: `DOWN`, `UP`, `RECONCILE`. |

: Cột của bảng `national_sync_run`

Cột khác: `domain_code` v(32); `job_id` uuid; `scope` jsonb; `checked_count` int; `discrepancy_count` int; `applied_count` int; `ratio` numeric(6,5); `paused` bool; `ph14_ref` v(64); `requested_by` v(64); `started_at` tstz; `finished_at` tstz; `error_code` v(16).

### 3.34. `national_discrepancy`

::: dac-ta
**Mục đích.** EN-06-30 FR-06-053, 054 Lệch giữa bản ghi vàng và CSDL quốc gia trên thuộc tính đồng bộ. Giá trị hai phía mã hóa envelope kèm HMAC. Một lệch OPEN mỗi (bản ghi vàng, thuộc tính). Thuộc tính thẩm quyền quốc gia không giữ giá trị địa phương khi lệch (BR-06-025).

**FR phục vụ.** FR-06-053, 054; EN-06-30.

**Khóa chính.** (id).

**Duy nhất.** `uq_national_discrepancy_open` (tenant_id, golden_id, attribute_name) có điều kiện.

**Khóa ngoại.** (tenant_id, run_id) → `national_sync_run`, (tenant_id, golden_id) → `golden_record`.

**Ràng buộc CHECK.** `ck_national_discrepancy_` + `tenant`, `severity`, `status`, `resolution`, `resolved`, `hash`, `enc`.

**Chỉ mục.** `ix_national_discrepancy_run`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `run_id`, `golden_id`, `attribute_name` (`tg_national_discrepancy_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `severity` | `varchar(8)` | Giá trị: `CRITICAL`, `MAJOR`, `MINOR`. |
| `status` | `varchar(24), mặc định 'OPEN'` | Giá trị: `OPEN`, `ACCEPTED_NATIONAL`, `KEPT_LOCAL`, `REPORTED_TO_NATIONAL`, `IGNORED`. |
| `resolution` | `varchar(24), NULL` | Giá trị: `ACCEPT_NATIONAL`, `KEEP_LOCAL`, `REPORT_TO_NATIONAL`, `IGNORE`. |

: Cột của bảng `national_discrepancy`

Cột khác: `run_id` uuid; `domain_code` v(32); `golden_id` uuid; `attribute_name` v(63); `local_enc` bytea; `national_enc` bytea; `value_kid` v(64); `local_hash` bytea; `national_hash` bytea; `resolved_by` v(64); `resolved_at` tstz; `resolve_reason` v(2000).

### 3.35. `source_correction`

::: dac-ta
**Mục đích.** EN-06-31 BR-06-014, EVT-06-15 Yêu cầu sửa tại nguồn: phát sinh khi sửa tay bản ghi vàng (FR-06-036), yêu cầu sửa của chủ thể (FR-06-058) hoặc lệch quốc gia (FR-06-054). Dữ liệu sai phải sửa ở nguồn; sửa tay ở bản ghi vàng chỉ tạm thời.

**FR phục vụ.** FR-06-036, 054, 058; EN-06-31.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, golden_id) → `golden_record`, (tenant_id, source_code) → `mdm_source`.

**Ràng buộc CHECK.** `ck_source_correction_` + `tenant`, `origin`, `closed`.

**Chỉ mục.** `ix_source_correction_open`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `origin` | `varchar(24)` | Giá trị: `MANUAL_EDIT`, `NATIONAL_SYNC`, `DSR_CORRECTION`. |

: Cột của bảng `source_correction`

Cột khác: `domain_code` v(32); `golden_id` uuid; `attribute_name` v(63); `source_code` v(32); `source_key` v(120); `origin_ref` uuid; `due_at` tstz; `closed_at` tstz; `closed_by` v(64); `close_note` v(2000).

### 3.36. `subject_request`

::: dac-ta
**Mục đích.** EN-06-20 Yêu cầu của chủ thể dữ liệu: biết, sửa, hạn chế (FR-06-058, BR-06-030; Luật BVDLCN, NĐ 356/2025). Số định danh chủ thể mã hóa envelope kèm HMAC để tra bản ghi vàng. Trả lời trong 06.dsr.sla-days (Q06-01); sửa thực hiện tại nguồn (BR-06-014). Yêu cầu hạn chế chuyển bản ghi vàng sang LOCKED.

**FR phục vụ.** FR-06-058; EN-06-20.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_subject_request_` + `tenant`, `type`, `status`, `idtype`, `hash`, `due`, `completed`, `rejected`, `lifted`, `forward`.

**Chỉ mục.** `ix_subject_request_status`, `ix_subject_request_subject`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `request_type`, `subject_hash`, `received_at` (`tg_subject_request_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `request_type` | `varchar(16)` | Giá trị: `ACCESS`, `RECTIFICATION`, `RESTRICTION`. |
| `status` | `varchar(24), mặc định 'RECEIVED'` | Giá trị: `RECEIVED`, `IN_PROGRESS`, `FORWARDED_TO_SOURCE`, `COMPLETED`, `REJECTED`. |
| `identifier_type` | `varchar(16)` | Giá trị: `CCCD_12`, `CMND_9`, `MST_10_13`, `MSDN`, `MA_BHXH_10`, `MA_DVQHNS`, `DVHC_CODE`, `PASSPORT`. |

: Cột của bảng `subject_request`

Cột khác: `subject_enc` bytea; `subject_kid` v(64); `subject_hash` bytea; `verification_ref` v(255); `details_enc` bytea; `channel` v(32); `received_at` tstz; `due_at` tstz; `golden_id` uuid; `forwarded_source_code` v(32); `handled_by` v(64); `completed_at` tstz; `result_ref` v(512); `reject_reason` v(2000); `lifted_at` tstz; `lifted_by` v(64); `lift_reason` v(2000).

### 3.37. `access_log`

::: dac-ta
**Mục đích.** EN-06-21 Nhật ký truy cập dữ liệu chủ: ai, tra bản ghi nào, mục đích gì, trả thuộc tính nào (FR-06-057, BR-06-010, NFR-06-015). Không ghi được thì không trả dữ liệu (ERR-06-039). Chỉ thêm, trigger chặn sửa, xóa (RB-06-04); không chứa giá trị thuộc tính. Phân vùng tháng; 12 tháng trực tuyến, 5 năm WORM (BR-06-031).

**FR phục vụ.** FR-06-015, 057; EN-06-21.

**Khóa chính.** (id, accessed_at).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_access_log_` + `tenant`, `api`, `trace`, `criteria`, `unmask`, `count`.

**Chỉ mục.** `ix_access_log_golden`, `ix_access_log_actor`, `ix_access_log_system`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Phân vùng tháng theo `accessed_at`; Trigger: `tg_access_log_append_only`.

**Ghi chú.** Không có `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `criteria_hash` | `bytea, NULL` | HMAC tiêu chí tìm kiếm; không lưu tiêu chí rõ. |
| `gateway_request_id` | `varchar(64), NULL` | Mã yêu cầu của APISIX để đối chiếu số lượt (NFR-06-015). |

: Cột của bảng `access_log`

Cột khác: `id` uuid; `tenant_id` v(16); `accessed_at` tstz; `actor` v(64); `system_code` v(63); `domain_code` v(32); `golden_id` uuid; `api_code` v(10); `purpose_code` v(63); `attributes` v(63)[]; `unmasked` v(63)[]; `unmask_reason` v(500); `result_count` int; `bulk_flag` bool; `trace_id` char(32), phân vùng `RANGE (accessed_at)`.

### 3.38. `processing_log`

::: dac-ta
**Mục đích.** EN-06-32 FR-06-057 Nhật ký xử lý (job, ứng viên, đồng bộ, dọn lưu giữ) cho vận hành: mức, mã lỗi ERR-06-1nn, thông điệp ngắn, chi tiết đã che DLCN. Chỉ thêm; phân vùng tháng theo logged_at; giữ 90 ngày.

**FR phục vụ.** FR-06-057; EN-06-32.

**Khóa chính.** (id, logged_at).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_processing_log_` + `tenant`, `level`, `code`, `trace`.

**Chỉ mục.** `ix_processing_log_job`, `ix_processing_log_level`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Phân vùng tháng theo `logged_at`; Trigger: `tg_processing_log_append_only`.

**Ghi chú.** Không có `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `level` | `varchar(5)` | Giá trị: `INFO`, `WARN`, `ERROR`. |

: Cột của bảng `processing_log`

Cột khác: `id` uuid; `tenant_id` v(16); `logged_at` tstz; `component` v(32); `job_id` uuid; `candidate_id` uuid; `domain_code` v(32); `code` v(16); `message` v(1000); `details` jsonb; `trace_id` char(32), phân vùng `RANGE (logged_at)`.

### 3.39. `retention_policy`

::: dac-ta
**Mục đích.** EN-06-33 FR-06-059 Chính sách lưu giữ theo loại đối tượng (BR-06-031). Nhật ký truy cập tối thiểu 365 ngày trực tuyến (ERR-06-049); legal_hold chặn dọn (ERR-06-114). retention_days = 0 không cho phép.

**FR phục vụ.** FR-06-059; EN-06-33.

**Khóa chính.** (id).

**Duy nhất.** `uq_retention_policy_type` (tenant_id, object_type).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_retention_policy_` + `tenant`, `type`, `action`, `days`, `hold`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `object_type` (`tg_retention_policy_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `object_type` | `varchar(24)` | Giá trị: . |
| `action` | `varchar(16)` | Giá trị: `DELETE`, `ANONYMIZE`, `ARCHIVE_COLD`. |

: Cột của bảng `retention_policy`

Cột khác: `retention_days` int; `legal_hold` bool; `hold_reason` v(2000); `last_purge_at` tstz.

### 3.40. `tenant_setting`

::: dac-ta
**Mục đích.** EN-06-34 FR-06-060 Tham số phân hệ theo tenant (FRS 8.2, khóa 06.*). Giá trị jsonb; miền kiểm ở dịch vụ (ERR-06-047), CHECK chỉ giữ danh sách khóa hợp lệ. Khóa thiếu thì dùng mặc định của FRS.

**FR phục vụ.** FR-06-060; EN-06-34.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_setting_key` (tenant_id, setting_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_tenant_setting_` + `tenant`, `key`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `setting_key` (`tg_tenant_setting_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `setting_key` | `varchar(48)` | Giá trị: . |

: Cột của bảng `tenant_setting`

Cột khác: `value` jsonb.

### 3.41. `outbox_event`

::: dac-ta
**Mục đích.** Outbox (DD-11, SAD 7.3) cho EVT-06-01…15 và bản ghi kiểm toán gửi PH-13. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL, định tuyến theo topic. Sự kiện không chứa giá trị thuộc tính (BR-06-012): CHECK chặn khóa value, attributes, identifier. Dọn sau 3 ngày.

**FR phục vụ.** Hạ tầng dùng chung.

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_event_` + `tenant`, `prefix`, `topic`, `trace`, `no_value`.

**Chỉ mục.** `ix_outbox_event_occurred`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** Debezium Outbox Event Router đọc WAL và phát lên Kafka; ghi cùng giao dịch với thay đổi (ADR-073, SAD 7.3).
:::

Cột khác: `event_id` uuid; `tenant_id` v(16); `event_type` v(128); `topic` v(249); `aggregate_type` v(64); `aggregate_id` v(255); `partition_key` v(255); `payload` jsonb; `trace_id` char(32); `occurred_at` tstz.

### 3.42. `inbox_event`

::: dac-ta
**Mục đích.** Inbox chống xử lý trùng cho sự kiện PH-06 tiêu thụ (at-least-once): trạng thái HTTT PH-01 (FR-06-008), thay đổi quốc gia từ PH-14 (FR-06-053), sự kiện nguồn PH-10 (FR-06-012). Khóa (consumer, event_id). Dọn sau 7 ngày.

**FR phục vụ.** FR-06-008, 012, 053.

**Khóa chính.** (tenant_id, consumer, event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_inbox_event_` + `tenant`, `consumer`, `prefix`.

**Chỉ mục.** `ix_inbox_event_received`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** Khử trùng sự kiện nhận từ phân hệ khác theo `event_id` (tiêu thụ lũy đẳng).
:::

Cột khác: `tenant_id` v(16); `consumer` v(64); `event_id` v(255); `source_topic` v(249); `event_type` v(255); `received_at` tstz; `processed_at` tstz; `outcome` v(2000).

### 3.43. `shedlock`

::: dac-ta
**Mục đích.** Khóa tác vụ nền (CandidateNormalizer, MatchJobScheduler, SteerQueueEscalator, SyncScheduler, RetentionPurgeJob, PartitionMaintenanceJob, OutboxCleaner, ExportExpiryJob); bảng kỹ thuật của ShedLock, không có tenant_id.

**FR phục vụ.** Hạ tầng dùng chung.

**Khóa chính.** (name).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không bật RLS. Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.

**Phân vùng, bất biến.** Không.

**Ghi chú.** Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.
:::

Cột khác: `name` v(64); `lock_until` tstz; `locked_at` tstz; `locked_by` v(255).
<!-- gen:tables:end -->

### 3.44. Truy vấn chính và chỉ mục phục vụ

Bảng ghi truy vấn nóng và chỉ mục phục vụ chúng.

| Truy vấn | API, tác vụ | Chỉ mục |
|---|---|---|
| Tra bản ghi vàng theo ID hoặc khóa định danh (resolve xác định) | API-06-056, 070, 071; NFR-06-001, 002 | `pk_golden_record`, `uq_golden_identifier_active` (băm) |
| Tra gần đúng theo tên, năm sinh, đơn vị hành chính | API-06-072, FR-06-021, 048 | `ix_golden_record_name_trgm` (GIN `pg_trgm`), `ix_golden_record_area` |
| Gom nhóm khi đối sánh xác suất trực tuyến | FR-06-019, 021; NFR-06-003, 006 | `ix_candidate_record_blocks` (GIN), `ix_candidate_record_name_trgm` |
| Đối sánh xác định ứng viên theo khóa | FR-06-020 | `ix_candidate_record_idhash`, `ix_golden_attribute_hash` |
| Chống trùng, thứ tự phiên bản nguồn | FR-06-016; BR-06-028, 029 | `uq_source_record_head` |
| Liên kết chéo của một bản ghi vàng; tra ID nguồn | API-06-066, 068 | `ix_source_xref_golden`, `uq_source_xref_active` |
| Lịch sử phiên bản, so sánh, hoàn tác | API-06-063, 064, 060 | `ix_golden_history_golden`, `ix_golden_operation_golden` (GIN) |
| Nhật ký truy cập theo bản ghi, người, HTTT; quét bất thường | API-06-089; BR-06-013 | `ix_access_log_golden`, `ix_access_log_actor`, `ix_access_log_system` |
| Lệch quốc gia đang mở | API-06-083 | `uq_national_discrepancy_open`, `ix_national_discrepancy_run` |

: Truy vấn chính và chỉ mục phục vụ

### 3.45. Phân vùng và bảo trì

Sáu bảng phân vùng theo tháng, bảo trì bằng tác vụ định kỳ.

| Bảng | Khóa phân vùng | Tạo trước | Dọn |
|---|---|---|---|
| `candidate_record` | `received_at` | 3 tháng tới | Ẩn danh hóa `raw_enc` sau 365 ngày; `DETACH`, `DROP` khi cả tháng đã ẩn danh |
| `match_result` | `scored_at` | 3 tháng tới | `DROP` sau 2 năm |
| `golden_history`, `attribute_lineage` | `changed_at`, `recorded_at` | 3 tháng tới | `DETACH` sang lưu trữ lạnh sau 5 năm, không xóa |
| `access_log` | `accessed_at` | 3 tháng tới | `DETACH` sau 12 tháng, xuất Parquet có khóa đối tượng WORM 5 năm trên Ceph RGW |
| `processing_log` | `logged_at` | 3 tháng tới | `DROP` sau 90 ngày |

: Phân vùng và bảo trì

`PartitionMaintenanceJob` (khóa `shedlock`) gọi `p_ensure_partitions` mỗi ngày lúc 00:05; DDL tạo sẵn ba phân vùng từ tháng triển khai. Dọn lưu giữ do `RetentionPurgeJob` (FR-06-059) theo `retention_policy`, bỏ qua đối tượng bị giữ pháp lý (ERR-06-114).

## 4. DDL và changelog Liquibase

### 4.1. Tệp

[`ph06/ddl/ph06_mdm.sql`](ph06/ddl/ph06_mdm.sql) là nguồn duy nhất, chia changeset bằng `-- @file`, `-- @changeset`, `-- @rollback` như PH-04, 05, 07, 10. Changelog [`ph06/liquibase/db.changelog-ph06.yaml`](ph06/liquibase/db.changelog-ph06.yaml) và 11 tệp `ph06/liquibase/changes/*.sql` (formatted SQL, tác giả `ph06`) sinh bằng [`gen_liquibase.py`](ph06/tools/gen_liquibase.py), không sửa tay.

| Tệp | Nội dung |
|---|---|
| `06-0000-bootstrap.sql` | Vai trò `ph06_owner`, `ph06_app`, `ph06_readonly`, `ph06_splink`; `pg_trgm`, `btree_gin`; schema; biến phiên |
| `06-0001-functions.sql` | `tg_touch`, `tg_immutable`, `tg_append_only`, `tg_frozen`, `tg_child_frozen`, `p_enable_rls`, `p_ensure_partitions`, `p_seed_tenant` |
| `06-0010-model.sql` | `mdm_domain`, `domain_model`, `model_attribute`, `identifier_rule`, `mdm_source`, `source_priority_proposal`, `source_priority` |
| `06-0020-ingest.sql` | `candidate_file`, `source_record_head`, `candidate_record` |
| `06-0030-match.sql` | `evaluation_report`, `match_rule_set`, `match_rule`, `match_job`, `job_schedule`, `match_staging`, `match_result`, `label_set`, `label_pair` |
| `06-0040-steward.sql` | `steward_item` |
| `06-0050-golden.sql` | `golden_record`, `golden_attribute`, `golden_identifier`, `source_xref`, `golden_operation`, `golden_history`, `attribute_lineage`, `survivorship_rule_set`, `survivorship_rule` |
| `06-0060-serve.sql` | `update_subscription`, `export_request`, `national_sync_state`, `national_sync_run`, `national_discrepancy`, `source_correction` |
| `06-0070-ops.sql` | `subject_request`, `access_log`, `processing_log`, `retention_policy`, `tenant_setting` |
| `06-0080-messaging.sql` | `outbox_event`, `inbox_event`, `shedlock` |
| `06-0900-grants.sql` | Quyền theo vai trò, `runAlways` |

: Tệp DDL và changelog Liquibase của PH-06

Không có changeset di trú dữ liệu: repo chưa có bảng PH-06 nào chạy (SRS cũ chỉ là mô hình trên giấy) và hệ cũ không có MDM (mục 8.4).

### 4.2. Kết quả chạy thử

Chạy ngày 26/11/2026 trên PostgreSQL 16.15 (Ubuntu 24.04) cài sạch, dữ liệu giả, tenant kiểm thử T90, T91:

- DDL chạy không lỗi trên CSDL trống với `ON_ERROR_STOP`: 43 bảng gốc, 18 phân vùng, 247 `CHECK`, 37 khóa ngoại, 66 trigger, 168 chính sách RLS (42 bảng × 4).
- Ghép 11 tệp changelog sinh ra rồi chạy bằng psql theo thứ tự trên CSDL trống khác: không lỗi, cùng số bảng. Chưa chạy bằng Liquibase CLI (không có trong máy); CI chạy `liquibase update` trên Testcontainers.
- [`ph06_isolation_test.sql`](ph06/test/ph06_isolation_test.sql) dưới `dh_data_app` (nhóm 26 dưới vai trò báo cáo `dh_report_ro`) đạt 95 khối PASS, chia bảy nhóm: cô lập tenant (T91 không đọc, chèn, sửa, xóa dòng T90 trên 18 bảng, kể cả phân vùng; không có dòng `COMMON`); bất biến và vòng đời phiên bản; định danh duy nhất, `SENSITIVE` không bản rõ, ngưỡng và đánh giá; bốn mắt và lý do ≥ 20 ký tự; bảng chỉ thêm, không xóa bản ghi vàng, outbox không chứa giá trị, `p_seed_tenant` (21, 10, 5 dòng, chạy lại không nhân bản), `pg_trgm`; vai trò chỉ đọc không đọc định danh mã hóa, ảnh chụp, băm tiêu chí; nhóm 27 của FRS 0.2: cờ `restricted`, khóa tập nhãn, gỡ hạn chế, chỉ mục GIN `block_keys`, quyền `ph06_splink`.

Bài kiểm `TenantIsolationIT` (D03-02-PH06) tự động hóa các khối này trong CI bằng Testcontainers PostgreSQL 16.

### 4.3. Đối chiếu với FRS phụ lục A

[`ph06/tools/check_frs.py`](ph06/tools/check_frs.py) đọc FRS và DDL, kiểm: (1) 69 cặp (bảng, cột) enum có tập giá trị `CHECK` đúng tập Phụ lục A (tập con ghi rõ: `VersionStatus` không `TESTING` ở mô hình và sống sót); (2) không có giá trị `CHECK` dạng chữ hoa nào mà FRS không có; (3) mọi mã ERR-06, BR-06, EN-06, FR-06 nhắc ở DDL và tài liệu có ở FRS, đủ 21 EN và 60 FR; (4) mọi bảng bật RLS và có `COMMENT`. Kết quả: khớp. Ngoại lệ có chủ ý: mức nhật ký `INFO`, `WARN`, `ERROR` của `processing_log` (không phải enum nghiệp vụ, đề nghị 9.2 mục 5).

## 5. Dữ liệu khởi tạo

Không có dữ liệu dùng chung tenant. Khi PH-20 khởi tạo tenant, `dh-data` gọi `ph06_mdm.p_seed_tenant('Tnn')` rồi cài gói domain nền bằng FR-06-007.

| Dữ liệu | Nội dung | Nguồn |
|---|---|---|
| Tham số `06.*` | 21 dòng `tenant_setting` theo FRS 8.2 (13 gốc và 8 tham số mới của bản 0.2; `06.queue.reason-templates` có mặc định ở ứng dụng, không seed) (`06.queue.sla-days` 7, `06.batch.safety-ratio` 0,05, `06.undo.window-days` 90, `06.export.max-rows` 100.000…) | FR-06-060 |
| Chính sách lưu giữ | 10 dòng `retention_policy` (mục 7) | FR-06-059 |
| Lịch job | 5 dòng `job_schedule`: `BATCH_MATCH` 02:00 hằng ngày, `ACCURACY_EVAL` ngày 1 hằng tháng, `NATIONAL_SYNC_DOWN` mỗi 15 phút, `NATIONAL_RECONCILE` Chủ nhật 01:00, `RETENTION_PURGE` 03:30 | FR-06-056 |
| Domain `CITIZEN`, `ORGANIZATION`, `ADDRESS` | Do ứng dụng nạp từ gói nền có phiên bản (mô hình, bộ quy tắc, sống sót mặc định); `baseline = true`, phiên bản `ACTIVE` không có người gửi duyệt (hai cột bốn mắt bỏ trống cho gói của PA) | FR-06-007 |

: Dữ liệu khởi tạo

Thủ tục chạy lại không nhân bản (`ON CONFLICT DO NOTHING`, `id` tất định theo `md5`).

## 6. Kho lưu trữ ngoài PostgreSQL

### 6.1. OpenBao

Hai khóa theo tenant: `dh-{tenant}-mdm-pii` (transit, mã hóa envelope cột `*_enc`) và `dh-{tenant}-mdm-hmac` (HMAC-SHA256 cho cột `*_hash`, khóa gom nhóm `block_keys`). `*_kid` ghi phiên bản khóa mã hóa. Không có khóa nào ở CSDL hay ở tệp cấu hình. OpenBao ngừng thì không nạp được bản ghi có trường nhạy cảm và tra cứu trả dạng che (ERR-06-113; FRS 12.1).

### 6.2. Kafka

Mười lăm topic `{tenant}.mdm.*` của EVT-06-01…15 (ví dụ `t68.mdm.golden.merged.v1`) do Debezium Outbox Event Router đọc từ `outbox_event`, khóa phân vùng là `goldenId` hoặc mã đối tượng; sự kiện không chứa giá trị thuộc tính (BR-06-012). Đăng ký topic qua FR-10-067. Nguồn sự kiện vào (FR-06-012) và thay đổi quốc gia từ PH-14 được khử trùng bằng `inbox_event`.

### 6.3. Ceph RGW

Tệp lô nạp ứng viên (`candidate_file.object_ref`, mã hóa phía máy chủ, xóa sau 7 ngày nếu không xác nhận); tệp xuất (`export_request.file_ref`, mã hóa, thủy vân, hạn tải 24 giờ); cặp kết quả Parquet của Job Splink (xóa cùng `match_staging`); nhật ký truy cập lưu trữ WORM 5 năm (khóa đối tượng); phân vùng `golden_history`, `attribute_lineage` đã `DETACH` sang lưu trữ lạnh.

### 6.4. Valkey

`dh:{tenant}:mdm:idem:{chủ thể}:{khóa}` giữ `Idempotency-Key` 24 giờ (BR-06-028); `dh:{tenant}:mdm:bulk:{chủ thể}` đếm bản ghi khác nhau trong 10 phút (BR-06-013); `dh:{tenant}:mdm:hold:{itemId}` giữ mục hàng đợi 30 phút. Mất Valkey chỉ mất bộ đếm và khóa tạm.

### 6.5. Job Splink trên Kubernetes

Job Python (Splink, DuckDB) chạy trong namespace riêng, dùng vai `ph06_splink` với `app.tenant_id` của job, chỉ thấy `match_staging` của tenant mình (SEC-15). Không có ClickHouse cho PH-06.

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

Bảng nêu thời hạn lưu giữ và cách dọn từng nhóm dữ liệu; phần sau bàn về mã hóa và khôi phục.

| Đối tượng | Lưu giữ | Cơ chế dọn, sao lưu |
|---|---|---|
| Schema `ph06_mdm` | Theo `pg-core`: WAL liên tục, base backup hằng ngày lên Ceph RGW, RPO ≤ 15 phút, RTO ≤ 30 phút (NFR-06-012, ADR-034) | Diễn tập DR theo D03-09 |
| Cấu hình, bản ghi vàng, liên kết, thao tác, hàng đợi, đồng bộ quốc gia | Vĩnh viễn, không xóa | Quyền `REVOKE DELETE` (BR-06-007); hàng đợi `ARCHIVE_COLD` sau 5 năm |
| `candidate_record` | 365 ngày sau xử lý, rồi ẩn danh hóa `raw_enc` | `RetentionPurgeJob` 03:30 (BR-06-031) |
| `match_result` | 2 năm | Cùng tác vụ, `DROP` phân vùng |
| `match_staging` | 7 ngày | Xóa sau job; tác vụ dọn |
| `golden_history`, `attribute_lineage` | 5 năm trực tuyến, sau đó lưu trữ lạnh, không xóa | `DETACH` phân vùng |
| `access_log` | 12 tháng trực tuyến, 5 năm WORM (BR-06-031) | Xuất Parquet khóa đối tượng; tối thiểu 365 ngày bằng `CHECK` |
| `processing_log`, `export_request` | 90 ngày | Dọn theo `retention_policy` |
| `subject_request` | 5 năm | Lưu trữ lạnh |
| `outbox_event`, `inbox_event` | 3 ngày; 7 ngày | `OutboxCleanupJob`, `InboxCleanupJob` mỗi giờ |
| Kafka, OpenBao, Ceph RGW | Theo D03-09: bản sao 3; snapshot Raft hằng giờ; đối tượng bản sao hai site | |

: Sao lưu, khôi phục, mã hóa và lưu giữ

**Mã hóa.** Kết nối `pg-core` bắt buộc TLS; dữ liệu tĩnh mã hóa mức đĩa (D03-07). Lớp thứ hai ở ứng dụng: số định danh và thuộc tính `SENSITIVE` mã hóa envelope trước khi vào bất kỳ bảng nào (`golden_attribute`, `golden_identifier`, `candidate_record.raw_enc`, `golden_history.snapshot_enc`, `attribute_lineage`, `label_pair.snapshot_enc`, `national_discrepancy`, `subject_request`), nên bản sao lưu rời cụm vẫn không có dữ liệu rõ. Quay khóa: job `REENCRYPT` (FR-06-056) giải mã và mã hóa lại theo lô bằng khóa mới, cập nhật `*_kid`; đổi khóa HMAC cần tính lại `*_hash` cùng lúc, thực hiện hai pha (ghi cả hai băm rồi bỏ băm cũ), ghi ở Q06-50. Quét NFR-06-016 tìm giá trị đánh dấu ở CSDL, log, topic, tệp xuất.

**Thứ tự khôi phục.** OpenBao trước, `pg-core` sau; nếu `*_kid` trỏ phiên bản khóa chưa có thì tra cứu trả dạng che (ERR-06-113) cho tới khi khôi phục khóa. CSDL cũ hơn Kafka thì bên nhận tra lại bản ghi vàng theo `goldenId`, không dựa vào nội dung sự kiện.

## 8. Ánh xạ thực thể, chức năng và CSDL cũ sang thiết kế mới

### 8.1. Thực thể EN-06 → bảng

<!-- gen:en:start -->
| Thực thể | Tên ở FRS 4.2 | Bảng hiện thực |
|---|---|---|
| EN-06-01 | `golden_record` | `golden_record` |
| EN-06-02 | `golden_attribute` | `golden_attribute`, `golden_identifier` |
| EN-06-03 | `source_xref` | `source_xref` |
| EN-06-04 | `source_priority` | `source_priority_proposal`, `source_priority` |
| EN-06-05 | `steward_item` | `steward_item` |
| EN-06-06 | `golden_history` | `golden_history` |
| EN-06-07 | `domain_model` | `mdm_domain`, `domain_model`, `model_attribute`, `identifier_rule` |
| EN-06-08 | `mdm_source` | `mdm_source` |
| EN-06-09 | `candidate_record` | `candidate_record` |
| EN-06-10 | `match_rule_set` | `match_rule_set`, `match_rule` |
| EN-06-11 | `match_result` | `match_result` |
| EN-06-12 | `match_job` | `match_job` |
| EN-06-13 | `golden_operation` | `golden_operation` |
| EN-06-14 | `attribute_lineage` | `attribute_lineage` |
| EN-06-15 | `label_pair` | `label_set`, `label_pair` |
| EN-06-16 | `national_sync_record` | `national_sync_run` |
| EN-06-17 | `survivorship_rule` | `survivorship_rule_set`, `survivorship_rule` |
| EN-06-18 | `update_subscription` | `update_subscription` |
| EN-06-19 | `export_request` | `export_request` |
| EN-06-20 | `subject_request` | `subject_request` |
| EN-06-21 | `access_log` | `access_log` |
| EN-06-22 | `source_priority_proposal` | `source_priority_proposal` |
| EN-06-23 | `evaluation_report` | `evaluation_report` |
| EN-06-24 | `job_schedule` | `job_schedule` |
| EN-06-25 | `candidate_file` | `candidate_file` |
| EN-06-26 | `source_record_head` | `source_record_head` |
| EN-06-27 | `match_staging` | `match_staging` |
| EN-06-28 | `golden_identifier` | `golden_identifier` |
| EN-06-29 | `national_sync_state` | `national_sync_state` |
| EN-06-30 | `national_discrepancy` | `national_discrepancy` |
| EN-06-31 | `source_correction` | `source_correction` |
| EN-06-32 | `processing_log` | `processing_log` |
| EN-06-33 | `retention_policy` | `retention_policy` |
| EN-06-34 | `tenant_setting` | `tenant_setting` |

: Ánh xạ thực thể EN-06 sang bảng

Bảng không có mã EN ở FRS 4.2 (bổ sung để hiện thực chức năng): `outbox_event`, `inbox_event`, `shedlock`.
<!-- gen:en:end -->

### 8.2. Chức năng FR-06 → bảng

<!-- gen:fr:start -->
| Nhóm | FR | Bảng hiện thực |
|---|---|---|
| A | FR-06-001 | `mdm_domain` |
| A | FR-06-002 | `mdm_domain`, `domain_model`, `model_attribute` |
| A | FR-06-003 | `identifier_rule` |
| A | FR-06-004 | `model_attribute` |
| A | FR-06-005 | `domain_model` |
| A | FR-06-006 | `mdm_domain`, `domain_model` |
| A | FR-06-007 | `mdm_domain` |
| B | FR-06-008 | `mdm_source`, `label_set`, `inbox_event` |
| B | FR-06-009 | `source_priority_proposal`, `source_priority` |
| B | FR-06-010 | `candidate_record` |
| B | FR-06-011 | `candidate_record` |
| B | FR-06-012 | `candidate_record`, `inbox_event` |
| B | FR-06-013 | `candidate_file`, `candidate_record` |
| B | FR-06-014 | `candidate_record` |
| B | FR-06-015 | `candidate_record`, `access_log` |
| B | FR-06-016 | `source_record_head`, `candidate_record`, `golden_attribute` |
| B | FR-06-017 | `candidate_record` |
| C | FR-06-018 | `match_rule_set`, `match_rule` |
| C | FR-06-019 | `match_rule_set` |
| C | FR-06-020 | `match_result`, `golden_identifier` |
| C | FR-06-021 | `match_result` |
| C | FR-06-022 | `match_job`, `match_staging`, `match_result` |
| C | FR-06-023 | `match_rule_set`, `match_result` |
| C | FR-06-024 | `match_job`, `match_result`, `match_rule_set` |
| C | FR-06-025 | `label_set`, `label_pair` |
| C | FR-06-026 | `evaluation_report` |
| D | FR-06-027 | `steward_item` |
| D | FR-06-028 | `steward_item` |
| D | FR-06-029 | `steward_item` |
| D | FR-06-030 | `label_pair`, `steward_item` |
| D | FR-06-031 | `steward_item` |
| D | FR-06-032 | `steward_item` |
| E | FR-06-033 | `source_priority`, `survivorship_rule_set`, `survivorship_rule` |
| E | FR-06-034 | `golden_record`, `golden_attribute` |
| E | FR-06-035 | `golden_record`, `golden_attribute` |
| E | FR-06-036 | `golden_record`, `golden_operation`, `source_correction` |
| E | FR-06-037 | `golden_record`, `golden_operation` |
| E | FR-06-038 | `golden_record`, `golden_operation` |
| E | FR-06-039 | `golden_record`, `golden_operation` |
| E | FR-06-040 | `golden_record`, `golden_operation` |
| E | FR-06-041 | `golden_record`, `golden_operation` |
| E | FR-06-042 | `golden_record`, `golden_operation`, `survivorship_rule_set` |
| F | FR-06-043 | `attribute_lineage` |
| F | FR-06-044 | `source_xref` |
| F | FR-06-045 | `source_xref` |
| G | FR-06-046 | `golden_identifier` |
| G | FR-06-047 | `golden_identifier`, `golden_record`, `match_result`, `steward_item`, `access_log` |
| G | FR-06-048 | `golden_record`, `access_log` |
| G | FR-06-049 | `export_request` |
| G | FR-06-050 | `outbox_event` |
| G | FR-06-051 | `update_subscription` |
| G | FR-06-052 | `model_attribute`, `golden_attribute`, `access_log` |
| G | FR-06-053 | `national_sync_state`, `national_sync_run`, `national_discrepancy`, `inbox_event` |
| G | FR-06-054 | `national_sync_state`, `national_discrepancy`, `source_correction` |
| H | FR-06-055 | `steward_item`, `match_job`, `match_result`, `national_discrepancy`, `access_log`, `candidate_record` |
| H | FR-06-056 | `match_job`, `job_schedule` |
| H | FR-06-057 | `access_log`, `processing_log` |
| H | FR-06-058 | `source_correction`, `subject_request` |
| H | FR-06-059 | `retention_policy` |
| H | FR-06-060 | `tenant_setting` |

: Ánh xạ FR-06 sang bảng

<!-- gen:fr:end -->

### 8.3. Mô hình SRS cũ của repo (`docs/07-srs/SRS-PH-06-mdm.md` §4)

SRS cũ có sáu thực thể tiếng Việt không dấu; FRS mới đổi tên sang tiếng Anh `snake_case` và tách thêm bảng. Cột "Chuyển đổi" nêu thay đổi kiểu.

| Thực thể cũ | Bảng mới | Chuyển đổi |
|---|---|---|
| `THUC_THE_VANG` (EN-06-01) | `golden_record`, `golden_identifier` | `loai_thuc_the` → `domain_code` (`CONG_DAN` → `CITIZEN`, `TO_CHUC` → `ORGANIZATION`; `CAN_BO`, `THUA_DAT` bỏ, Q06-04); `khoa_dinh_danh` rõ → `golden_identifier.value_enc` + `value_hash`; `SUSPENDED`, `ARCHIVED` → `LOCKED`, `RETIRED`; `hop_nhat_vao` → `merged_into`; `do_tin_cay decimal(3,2)` → `numeric(5,4)`; `so_phien_ban` → `version` |
| `THUOC_TINH_VANG` (EN-06-02) | `golden_attribute` | `gia_tri text` → `value_json jsonb` hoặc `value_enc` + `value_hash` theo `data_class`; `nguon_id` → `source_code`, `source_key`; `quy_tac_ap_dung` → `strategy` (`SurvivorshipStrategy`) |
| `LIEN_KET_NGUON` (EN-06-03) | `source_xref` | `con_hieu_luc boolean` → `status` (`ACTIVE`, `DETACHED`, `MOVED`); `phuong_thuc_khop` → `match_method` (`MatchMethod`); `nguoi_xac_nhan` → `confirmed_by_steward`, `linked_by` |
| `UU_TIEN_NGUON` (EN-06-04) | `source_priority`, `source_priority_proposal` | `can_cu_phe_duyet` → `approval_ref`; `nguoi_phe_duyet` → `decided_by` của đề nghị (bốn mắt); thêm hiệu lực `effective_from`, `effective_to` |
| `HANG_DOI_XU_LY` (EN-06-05) | `steward_item` | `PENDING`, `IN_REVIEW` → `OPEN`, `ASSIGNED`; `SEPARATE` → `NO_MATCH`; thêm `PENDING_APPROVAL`, `CANCELLED`; `ly_do` bắt buộc ≥ 20 ký tự |
| `LICH_SU_THUC_THE` (EN-06-06) | `golden_history` | `trang_thai_truoc jsonb` → `snapshot_enc` (mã hóa envelope, vì chứa DLCN); thêm `snapshot_sha256`; phân vùng tháng |

: Ánh xạ thực thể SRS cũ sang bảng mới

### 8.4. Hệ cũ Viettel 2021 và CSDL quốc gia

Hệ cũ (Viettel 2021) không có MDM nên không có bảng hay cột cũ cần chuyển đổi cho D06-01 và không có changeset di trú. Dữ liệu ban đầu vào bản ghi vàng đi qua nạp ứng viên (FR-06-010…013) từ các HTTT nguồn. LGC-NGSP-003 (BHXH hộ gia đình) và LGC-NGSP-005 (đăng ký doanh nghiệp) chỉ là nguồn dữ liệu qua PH-14 vào `mdm_source` (`source_kind = NATIONAL_DB`); Datahub không ghi đè nguồn gốc (RB-06-01).

## 9. Câu hỏi mở và đề nghị bổ sung cho FRS

### 9.1. Câu hỏi mở

Các câu hỏi chưa có quyết định, kèm đề xuất tạm.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q06-50 | Quay khóa HMAC (`dh-{tenant}-mdm-hmac`) buộc tính lại mọi `*_hash`, khóa gom nhóm; chu kỳ quay và cách ghi hai băm trong giai đoạn chuyển | Quay 12 tháng một lần hoặc khi nghi lộ; hai pha (ghi cả hai băm, đối sánh cả hai, bỏ băm cũ) bằng job `REENCRYPT`; cần ATTT xác nhận |
| Q06-51 | `access_log` khoảng 158 triệu dòng mỗi năm ở T01 (5 lượt mỗi giây trung bình): giữ trên `pg-core` 12 tháng hay chuyển ClickHouse của PH-13 từ tháng thứ ba | Giữ ở `pg-core`, phân vùng tháng; nếu ghi vượt 300 dòng mỗi giây thì ghi qua hàng đợi Kafka rồi nạp lô, vẫn bảo đảm BR-06-010 bằng bộ đệm ghi bền |
| Q06-52 | Lưu trữ lạnh `golden_history`, `attribute_lineage` sau 5 năm: định dạng, nơi đọc lại khi hoàn tác quá hạn (BR-06-024) hoặc yêu cầu chủ thể | Parquet nén mã hóa trên Ceph RGW kèm chỉ mục `golden_id`; đọc lại bằng job nền, không trực tuyến |
| Q06-53 | Họ tên có được PH-09 xếp `SENSITIVE` không: nếu có thì `name_norm`, `display_name` không được ở dạng rõ và mất tra gần đúng bằng `pg_trgm` | Mặc định `RESTRICTED` (rõ, có chỉ mục); nếu `SENSITIVE`, chuyển sang so khớp ngữ âm bằng HMAC và gom nhóm, giảm recall; cần ý kiến pháp chế và PH-09 |
| Q06-54 | Ảnh chụp đầy đủ mỗi lần thay đổi (ADR đề xuất ở FRS 12.3) phình nhanh với bản ghi nhận cập nhật quốc gia liên tục: có giới hạn tần suất hoặc nén theo khác biệt sau N phiên bản không | Ảnh chụp đầy đủ nén `zstd` trước khi mã hóa; cứ 20 phiên bản mới lưu một ảnh đầy đủ, còn lại lưu khác biệt, nếu số đo thực tế vượt 2 KB mỗi ảnh trung bình |

: Câu hỏi mở của tập CSDL PH-06

### 9.2. Đề nghị bổ sung cho FRS

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

FRS 0.2 (D02-03-PH06 §15) đã hấp thụ các đề nghị của bản 0.1; bảng dưới ghi cách tập CSDL đã áp.

| Số | Nội dung | Xử lý ở FRS 0.2 và CSDL 0.2 |
|---|---|---|
| 1 | 13 bảng bổ sung chưa có mã thực thể | Đã áp: EN-06-22…34 ở FRS 4.2; `COMMENT ON TABLE` ghi mã, mục 8.1 ánh xạ đủ 34 EN, chỉ còn `outbox_event`, `inbox_event`, `shedlock` là bảng hạ tầng không có mã EN |
| 2 | Enum `IdentifierValidator` | Đã áp ở Phụ lục A; `check_frs.py` kiểm khớp `CHECK` |
| 3 | Enum `DeliveryMode`, `RetentionObjectType` | Đã áp ở Phụ lục A |
| 4 | Giá trị lưu giữ mặc định | Đã áp: dẫn chiếu ở FRS 8.1 và bảng FR-06-059; `p_seed_tenant` giữ nguyên |
| 5 | Enum mức nhật ký `LogLevel`, pha tệp `FilePhase` | Đã áp ở Phụ lục A |
| 6 | `display_name`, `name_norm` phụ thuộc phân loại họ tên PH-09 | Chuyển câu hỏi mở: Q06-53 của tập này |
| 7 | `golden_record.block_keys` cộng chỉ mục GIN; vai `ph06_splink` | Đã áp ở FR-06-019, 022: cột `block_keys varchar(72)[]`, `ix_golden_record_blocks` (GIN), vai `ph06_splink` |
| 8 | Chín tham số mới ở FRS 8.2 | Đã áp: `ck_tenant_setting_key` có 22 khóa, `p_seed_tenant` seed 21 dòng (trừ `06.queue.reason-templates`) |
| 9 | Khóa tập nhãn (API-06-123), mở lại quyết định (API-06-121), gỡ hạn chế (API-06-125) | Đã áp: `label_set.locked`, `locked_at`, `locked_by`; `steward_item.reopen_count`, `reopened_at`, `reopened_by`, `reopen_reason`, `decision_history`; `golden_record.restricted`; `subject_request.lifted_at`, `lifted_by`, `lift_reason`; ba `CHECK` mới |

: Đề nghị bổ sung cho FRS, trạng thái ở bản 0.2

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-CSDL và K-TRINH-BAY: 43 bảng, DDL và changelog chạy thử trên PostgreSQL 16.15, kiểm cô lập 90 khối PASS, đối chiếu Phụ lục A sạch; ERD bốn nhóm; mã hóa envelope và HMAC; ánh xạ EN, FR sang bảng; năm câu hỏi mở Q06-50…54 |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ FRS 0.2: ánh xạ EN-06-22…34 cho 13 bảng bổ sung; thêm `golden_record.block_keys` cộng GIN và `restricted`, khóa ở `label_set`, mở lại ở `steward_item`, gỡ hạn chế ở `subject_request`; vai `ph06_splink`; chín tham số mới vào `tenant_setting` và `p_seed_tenant`; kiểm cô lập 95 khối PASS trên PostgreSQL 16.15; mục 9.2 ghi các đề nghị đã áp |
