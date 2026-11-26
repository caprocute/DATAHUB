---
ma_tai_lieu: D03-03-PH08
ten: Thiết kế cơ sở dữ liệu phân hệ PH-08 Chất lượng dữ liệu
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, DBA, ATTT, hội đồng thẩm định
phan_he: PH-08
mo_ta: Thiết kế 35 bảng của schema ph08_dq trên cụm pg-core cho phân hệ chất lượng dữ liệu, gồm đối tượng đo, bộ quy tắc có phiên bản, lần đo, điểm sáu chiều, bản ghi lỗi có dấu vân tay và không lưu giá trị gốc trường Nhạy cảm, phiếu khắc phục, báo cáo, RLS theo tenant, phân vùng tháng, lưu giữ 13 tháng và ánh xạ chức năng sang bảng, trích từ DDL đã chạy thử.
tai_lieu_lien_quan: D02-03-PH08 FRS; D03-02-PH08 SDD; D03-04-PH08 API; D03-10 Thiết kế đa tenant; D05-02-PH08 Test case
---

# D03-03-PH08 · Thiết kế CSDL Chất lượng dữ liệu

## Tóm tắt cho hội đồng thẩm định

Schema `ph08_dq` trên cụm `pg-core` có 35 bảng cho module `dq` của `dh-data` (package `vn.datahub.data.dq`): 34 bảng thực thể ứng với EN-08-01…33 của FRS 0.2 (EN-08-30 gồm bảng chính sách và bảng lịch sử dọn) cùng bảng kỹ thuật `shedlock`. Phân hệ cho sở ngành tự đo và cải thiện chất lượng dữ liệu theo sáu chiều (đầy đủ, chính xác, nhất quán, kịp thời, duy nhất, hợp lệ), phục vụ báo cáo chất lượng định kỳ và báo cáo chính thức hằng năm theo Luật Dữ liệu và NĐ 278/2025. Bốn điểm chính của thiết kế:

1. **Không lưu giá trị gốc của trường Nhạy cảm.** Bản ghi lỗi `dq_finding` chỉ có `masked_value` (đã che theo chính sách PH-09) và `value_hash` (băm có khóa). Ràng buộc `ck_dq_finding_no_raw` buộc trường `SENSITIVE` chỉ được `HASH_ONLY` và không có giá trị che, trường `RESTRICTED` không được lưu rõ; hồ sơ dữ liệu cột Nhạy cảm không có giá trị mẫu.
2. **Dấu vân tay cho bản ghi lỗi.** Mỗi lỗi nhận một `fingerprint` (HMAC của đối tượng, quy tắc, khóa bản ghi) nên biết lỗi mới, còn hay đã hết qua các kỳ mà không nhân bản dòng; bảng phân vùng theo tháng của `last_seen_at`, lưu giữ mặc định 13 tháng (tham số), dọn bằng `DROP` phân vùng.
3. **Quy tắc nghiệp vụ khóa ở CSDL:** phiên bản bộ quy tắc ACTIVE bất biến và chỉ một mỗi bộ, duyệt bốn mắt, tổng trọng số 1,000 (dung sai 0,001), đo chính thức hằng năm bắt buộc FULL, snapshot chính thức không được thiếu chiều, mỗi đối tượng một lần đo đang chạy, mỗi nhóm lỗi một phiếu đang mở, ngoại lệ có hạn và lý do từ 20 ký tự.
4. **Cô lập tenant bằng `FORCE ROW LEVEL SECURITY`** trên 34 bảng (trừ `shedlock`); riêng `dq_rule_template` dùng mẫu S để mọi tenant đọc được bộ quy tắc mẫu dùng chung của tenant `COMMON`.

DDL [`ph08/ddl/ph08_dq.sql`](ph08/ddl/ph08_dq.sql) đã chạy thử trên PostgreSQL 16.15 sạch; bài kiểm [`ph08/test/ph08_isolation_test.sql`](ph08/test/ph08_isolation_test.sql) đạt 211 khối PASS (§4.2). Chương 8 ánh xạ thực thể, chức năng FR-08 và mô hình SRS cũ sang bảng; chương 9 nêu năm câu hỏi mở Q08-50…54 và các đề nghị đồng bộ.

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả cơ sở dữ liệu của PH-08 Chất lượng dữ liệu ở mức đủ để DBA dựng schema, kỹ sư `dh-data` viết tầng truy cập và kiểm thử viên viết ca kiểm thử cô lập tenant, bất biến, không lộ giá trị gốc. Phạm vi là 31 bảng của schema `ph08_dq`, thủ tục, trigger, changelog Liquibase và bài kiểm cô lập. Ngoài phạm vi: bản ghi vàng (PH-06), bảng mã (PH-07), nội dung tệp báo cáo và tệp xuất lỗi (Ceph RGW), bộ đệm quy tắc trực tuyến (Valkey), khóa mã hóa và HMAC (OpenBao); các nơi này nêu ở chương 6.

Nguồn chuẩn là [`ph08/ddl/ph08_dq.sql`](ph08/ddl/ph08_dq.sql), sinh bằng `ph08/tools/sinh_ddl.py` với enum trùng Phụ lục A của FRS (chỉ được thêm, không đổi tên). Danh mục bảng, chương 3 và chương 8 sinh từ DDL bằng `ph08/tools/dung_md.py`.

### 0.2. Thuật ngữ và chữ viết tắt

Các thuật ngữ dưới đây dùng xuyên suốt tập CSDL.

| Thuật ngữ | Giải thích |
|---|---|
| Đối tượng đo (asset) | Thứ được đo chất lượng, bốn loại: `MDM_DOMAIN` (miền PH-06), `RDM_CATALOG` (danh mục PH-07), `SOURCE_DATASET` (bảng nguồn qua PH-05), `FLOW_MESSAGE` (bản tin luồng PH-04) |
| Sáu chiều | `COMPLETENESS`, `ACCURACY`, `CONSISTENCY`, `TIMELINESS`, `UNIQUENESS`, `VALIDITY`; khung bắt buộc, không bỏ chiều |
| CDE | Phần tử dữ liệu trọng yếu (Critical Data Element), cột `dq_asset_field.cde` |
| Dấu vân tay (`fingerprint`) | Băm có khóa của (đối tượng, quy tắc, khóa bản ghi), nhận dạng một lỗi qua các kỳ đo |
| Pushdown | Dịch quy tắc tập hợp thành SQL chạy ngay trên bản sao chỉ đọc của nguồn, không kéo dữ liệu về |
| CEL | Common Expression Language, ngôn ngữ biểu thức cho quy tắc mức bản ghi (thư viện cel-java) |
| FAIL_OPEN, FAIL_CLOSED | Khi dịch vụ phụ thuộc lỗi lúc kiểm tra trực tuyến, cho bản ghi đi tiếp hoặc chặn lại, đặt theo miền |
| RLS, FORCE RLS | Row Level Security lọc dòng theo `tenant_id = app.tenant_id`; FORCE áp cả với chủ bảng |
| Mẫu RLS P, S | P: chỉ dòng của tenant phiên; S: thêm quyền đọc dòng `COMMON` dùng chung (cách PH-07) |
| Phân vùng RANGE | Chia bảng lớn thành bảng con theo tháng, dọn bằng `DETACH` và `DROP` |
| Outbox, inbox | Bảng ghi sự kiện cùng giao dịch để Debezium phát; bảng khử trùng sự kiện nhận |
| DO, DS, DA | Tổ chức chủ quản dữ liệu; cán bộ dữ liệu (Data Steward); người duyệt dữ liệu (Data Approver) |

: Thuật ngữ và chữ viết tắt của tập CSDL PH-08

### 0.3. Tài liệu tham chiếu

Tập này dựa vào các tài liệu sau.

| Tài liệu | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH08 FRS (đang soạn song song) | Thực thể EN-08, FR-08-001…061, enum Phụ lục A |
| `docs/07-srs/SRS-PH-08-dq.md` M4 | Sáu thực thể EN-08-01…06 của SRS cũ và chính sách lưu giữ (mục 8.4) |
| D03-06-PH06, D03-03-PH06 | Cách ly tenant, view hợp đồng chỉ đọc cho đối tượng đo MDM |
| D03-03-PH07 | Mẫu RLS S cho dòng `COMMON`, bộ đệm mã Valkey |
| D03-10 Thiết kế đa tenant; D03-07 Bảo mật; D03-09 Hạ tầng và DR | Mẫu RLS, mã hóa, cụm `pg-core`, sao lưu |
| ADR-003, 032, 034, 067; ADR-085…087 đề xuất | RLS, mã hóa envelope, DR, kết nối nguồn chỉ đọc; pushdown với CEL, dấu vân tay và che, truy cập qua view hợp đồng |
| Luật Dữ liệu 60/2024 (CMP-LAW-01), NĐ 165/2025 (CMP-LAW-02), NĐ 278/2025 (CMP-LAW-03) | Căn cứ chuẩn hóa dữ liệu và báo cáo chất lượng; điều khoản cụ thể chưa xác minh, xem Q08-50 |

: Tài liệu tham chiếu của tập CSDL PH-08

### 0.4. Người đọc

DBA, kỹ sư `dh-data`, ATTT và kiểm thử viên; hội đồng thẩm định đọc Tóm tắt, chương 1 và chương 8.

### 0.5. Cấu trúc tài liệu

Chương 1 chiến lược lưu trữ, 2 sơ đồ thực thể, 3 đặc tả bảng, 4 DDL và Liquibase, 5 dữ liệu khởi tạo, 6 kho ngoài PostgreSQL, 7 sao lưu, mã hóa, lưu giữ, 8 ánh xạ sang thiết kế, 9 câu hỏi mở và đề nghị đồng bộ.

## 1. Chiến lược lưu trữ

### 1.1. Schema, vai trò và kết nối

Schema `ph08_dq` do `ph08_owner` (NOLOGIN) sở hữu, nằm trên cụm `pg-core` cùng các schema của DU `dh-data`. Module `dq` kết nối bằng `dh_data_app`, thành viên `ph08_app`: chỉ DML, không `BYPASSRLS`, không `DELETE` trên bảng nghiệp vụ (đối tượng đo chỉ ngừng, không xóa), không `UPDATE`, `DELETE` trên hai bảng chỉ thêm `dq_rule_result` và `dq_issue_activity`. Liquibase chạy bằng `dh_data_migrator` (thành viên `ph08_owner`). Báo cáo và BI dùng `dh_report_ro`, thành viên `ph08_readonly`, chỉ `SELECT`; riêng `dq_finding` vai này chỉ đọc cột không nhạy cảm, không đọc `masked_value`, `value_hash`, `record_key_masked`. Hai vai bổ sung ở bản 0.2: `ph08_benchmark` chỉ đọc điểm chiều của ảnh chụp chính thức qua khung nhìn `v_benchmark_dimension` (ngoại lệ RLS duy nhất, so sánh liên tenant FR-08-061) và `dq_reader` (bộ thực thi đo, chỉ `SELECT` khung nhìn hợp đồng của PH-06, không có quyền trên `ph08_dq`).

`dh-data` không có khóa ngoại sang schema khác. Mã tổ chức (`owner_org_code`, PH-01), kết nối nguồn (`connection_id`, PH-05), mã domain PH-06 và mã danh mục PH-07 là chuỗi hoặc UUID kiểm ở dịch vụ qua giao diện module (Modulith). Đối tượng đo MDM đọc qua view hợp đồng chỉ đọc do PH-06 cấp; đối tượng nguồn đọc bằng tài khoản chỉ đọc theo Q359 và ADR-067, không bao giờ đọc CSDL control.

### 1.2. Cách ly tenant

Mọi bảng nghiệp vụ có `tenant_id varchar(16)` dạng `Tnn` và bật `FORCE ROW LEVEL SECURITY` qua `ph08_dq.p_enable_rls(bảng)`: đọc và ghi chỉ dòng có `tenant_id = current_setting('app.tenant_id')`. Bảng `dq_rule_template` dùng `p_enable_rls_shared`: mọi tenant đọc được dòng `COMMON`, chỉ phiên `PLATFORM` được ghi `COMMON`. Phiên `PLATFORM` không đọc được dữ liệu đo của tenant nào; so sánh liên tenant (FR-08-061) chỉ là tổng hợp ẩn danh do dịch vụ tính từ `dq_score_snapshot` rồi chuyển cho PLATFORM, không mở RLS.

Biến phiên `app.tenant_id` đặt đầu mỗi giao dịch từ ngữ cảnh xác thực (FR-00-010), không từ tham số của bên gọi; quên đặt thì không thấy và không ghi được dòng nào. Tác vụ nền liên tenant (dọn lưu giữ, duy trì phân vùng, outbox) lặp từng tenant. Khóa ngoại luôn kèm `tenant_id` (`FOREIGN KEY (tenant_id, asset_id)`), đích có `UNIQUE (tenant_id, id)`, nên một tenant không thể trỏ tới dòng của tenant khác ngay cả khi biết UUID.

### 1.3. Quy ước bảng và ngoại lệ

Theo D00-01 §5.1 mọi bảng nghiệp vụ có `id uuid` (UUIDv7 sinh ở ứng dụng), `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (trigger `tg_touch`, khóa lạc quan, ETag). Mã nghiệp vụ có `CHECK` theo mẫu; enum lưu `varchar` kèm `CHECK ... IN (...)` đúng giá trị Phụ lục A. Kiểu thời gian `timestamptz`, chuỗi chuẩn NFC.

| Bảng | Ngoại lệ | Lý do |
|---|---|---|
| `dq_finding`, `dq_rule_result`, `dq_inline_stat` | Khóa chính `(id, cột thời gian)`; không là đích khóa ngoại | Phân vùng tháng; tham chiếu tới chúng là logic, dịch vụ kiểm |
| `dq_rule_result`, `dq_issue_activity` | Trigger chặn sửa, xóa (có đủ cột ngữ cảnh) | Chỉ thêm, ghi một lần |
| `outbox_event`, `inbox_event` | Không `id`, `version`, `created_*`, `updated_*` | Bảng kỹ thuật, khóa chính là `event_id` |
| `shedlock` | Không `tenant_id`, không RLS | Khóa job của thư viện ShedLock |
| `dq_rule_template` | `tenant_id` nhận thêm `COMMON` | Bộ quy tắc mẫu dùng chung |

: Quy ước bảng và ngoại lệ

### 1.4. Quy tắc nghiệp vụ chốt ở CSDL

Các quy tắc sau do CSDL tự bảo đảm, bằng ràng buộc, chỉ mục duy nhất một phần, trigger hoặc quyền, nên một lỗi ở dịch vụ không phá được tính toàn vẹn.

| Ràng buộc | Quy tắc | FR |
|---|---|---|
| `ck_dq_finding_no_raw`, `ck_dq_asset_field_mode_class`, `ck_dq_profile_column_sensitive` | Trường `SENSITIVE` chỉ `HASH_ONLY`, không giá trị che, không giá trị mẫu; trường `RESTRICTED` không lưu rõ | 005, 009, 036 |
| `ck_dq_asset_ref`, `ck_dq_rule_operator_dimension`, `ck_dq_rule_expression` | Tham chiếu đúng theo loại đối tượng; toán tử đúng chiều; CEL, SQL có biểu thức; vị từ SQL chỉ chạy lô | 002…004, 013, 014 |
| `uq_dq_rule_set_version_active`, `tg_dq_rule_set_version_frozen`, `tg_dq_rule_child_frozen` | Mỗi bộ một phiên bản ACTIVE; ACTIVE, SUPERSEDED bất biến; quy tắc chỉ sửa khi phiên bản là DRAFT | 017, 018 |
| `ck_dq_*_four_eyes` | Người duyệt khác người gửi (bộ quy tắc, trọng số, ngoại lệ, báo cáo, xuất lỗi) | 017, 021, 040, 053, 039 |
| `ck_dq_weight_config_sum`, `uq_dq_weight_config_active` | Tổng sáu trọng số bằng 1,000 dung sai 0,001; mỗi phạm vi một cấu hình ACTIVE | 021 |
| `ck_dq_scan_job_annual_full`, `uq_dq_scan_job_running`, `uq_dq_scan_job_idem` | Đo hằng năm bắt buộc FULL; một lần đo RUNNING mỗi đối tượng; `Idempotency-Key` không tạo hai lần đo | 023, 024, 054 |
| `ck_dq_score_snapshot_official`, `ck_dq_report_annual_full` | Snapshot chính thức phải đo FULL và không thiếu chiều; báo cáo ANNUAL không dựa snapshot thiếu chiều | 031, 054 |
| `ck_dq_rule_result_skipped`, `tg_dq_rule_result_append_only` | Kết quả SKIPPED phải có lý do; ghi một lần | 026, 031 |
| `uq_dq_issue_open_group`, `ck_dq_issue_verified` | Mỗi nhóm lỗi một phiếu đang mở; VERIFIED phải có lần đo lại | 041, 044 |
| `ck_dq_waiver_period`, `ck_dq_waiver_reason` | Ngoại lệ có hạn không quá 366 ngày, lý do từ 20 ký tự | 040 |
| `tg_dq_report_frozen`, `ck_dq_report_published` | Báo cáo đã công bố bất biến, có người duyệt, mã SHA-256 và tệp PDF | 053, 055 |
| `ck_outbox_event_topic`, `ck_outbox_event_no_value` | Chỉ 14 topic EVT-08 và kiểm toán; sự kiện không chứa giá trị bản ghi lỗi | 057, 060 |
| `ck_dq_rule_set_version_dry_run`, `ck_dq_scan_job_idem`, `ck_dq_scan_task_running` | Gửi duyệt phải có dấu chạy thử; khóa chống trùng đi kèm băm thân yêu cầu (ERR-08-055); tác vụ chạy phải có worker và nhịp | 016, 017, 024, 026 |
| `ck_dq_asset_inline_on`, `ck_dq_asset_gate`, `ck_dq_asset_incremental` | Bật trực tuyến phải có chế độ; cổng chỉ cho `MDM_DOMAIN`; đo tăng dần không cho `FLOW_MESSAGE`, nguồn HTTT cần `updated_at_field` | 025, 032, 035 |
| `uq_dq_alert_unresolved`, `uq_dq_incremental_buffer_open`, `ck_dq_incremental_buffer_keys` | Một cảnh báo chưa RESOLVED mỗi (quy tắc, đối tượng); một bộ đệm gom khóa mỗi đối tượng, tối đa 100.000 khóa | 025, 048 |
| `ck_dq_tenant_setting_key`, `ck_dq_retention_policy_days` | Chỉ 43 khóa tham số 08.* của FRS 8.2; báo cáo, snapshot giữ tối thiểu 3 năm | 058, 059 |

: Quy tắc nghiệp vụ chốt ở CSDL

Quy tắc cần dữ liệu ngoài schema hoặc tính toán (HTTT `ACTIVE` ở PH-01, mã danh mục có ở PH-07, thời hạn ngoại lệ theo tham số `08.waiver.max-days`, tính điểm từ kết quả quy tắc, SLA theo ngày làm việc) kiểm ở dịch vụ, ghi ở D03-02-PH08.

### 1.5. Ước lượng khối lượng (giả định)

Giả định theo GĐ-01: tỉnh T01 quy mô vừa, 200 HTTT, khoảng 600 đối tượng đo, 8.000 quy tắc; đo FULL hằng tháng và đo tăng dần theo sự kiện, tỷ lệ bản ghi lỗi khoảng 2% có trần 10.000 lỗi lưu mỗi quy tắc.

| Bảng | Dòng ước tính | Dung lượng |
|---|---|---|
| `dq_finding` (13 tháng) | khoảng 5 triệu lỗi đang tồn tại | khoảng 5 GB gồm chỉ mục |
| `dq_rule_result` (13 tháng) | khoảng 3 triệu | khoảng 1 GB |
| `dq_inline_stat` (90 ngày) | khoảng 6,5 triệu (50 cặp đối tượng và bên gọi, mỗi phút một dòng) | khoảng 1,3 GB |
| `dq_score_snapshot`, `dq_score_dimension` (5 năm) | khoảng 0,4 triệu; 2,4 triệu | khoảng 0,6 GB |
| `dq_scan_task` (90 ngày), `dq_issue`, `dq_issue_activity` | dưới 2 triệu mỗi bảng | dưới 1 GB |
| Còn lại | dưới 0,1 triệu | dưới 0,2 GB |

: Ước lượng khối lượng (giả định)

`dq_finding` cập nhật `last_seen_at` mỗi lần đo thấy lại lỗi, nên mỗi kỳ ghi lại tới 5 triệu dòng (kèm chuyển phân vùng); cách giảm tải nêu ở Q08-52.

### 1.6. Danh mục bảng

Bảng dưới liệt kê 35 bảng theo thứ tự đặc tả ở chương 3, kèm thực thể, phân vùng và FR chính; sinh từ DDL nên khớp tuyệt đối.

<!-- gen:danh-muc:start -->
| Mục | Bảng | Thực thể | Phân vùng | FR chính |
|---|---|---|---|---|
| 3.1 | `dq_domain` | EN-08-01 | Không | 001, 035 |
| 3.2 | `dq_asset` | EN-08-02 | Không | 002, 003, 004, 006, 007 |
| 3.3 | `dq_asset_field` | EN-08-03 | Không | 005, 006, 009 |
| 3.4 | `dq_profile_run` | EN-08-04 | Không | 008, 011 |
| 3.5 | `dq_profile_column` | EN-08-05 | Không | 009, 010, 011 |
| 3.6 | `dq_rule_template` | EN-08-09 | Không | 010, 015 |
| 3.7 | `dq_weight_config` | EN-08-10 | Không | 021, 028 |
| 3.8 | `dq_rule_set` | EN-08-06 | Không | 012, 018, 020, 022 |
| 3.9 | `dq_rule_set_version` | EN-08-07 | Không | 012, 017, 018, 019, 020 |
| 3.10 | `dq_rule` | EN-08-08 | Không | 010, 013, 014, 016, 019… |
| 3.11 | `dq_schedule` | EN-08-11 | Không | 023 |
| 3.12 | `dq_scan_job` | EN-08-12 | Không | 023, 024, 025, 026, 030… |
| 3.13 | `dq_scan_task` | EN-08-13 | Không | 026, 030 |
| 3.14 | `dq_rule_result` | EN-08-14 | Tháng, executed_at | 026, 027, 028, 031 |
| 3.15 | `dq_score_snapshot` | EN-08-15 | Không | 028, 029, 031, 050, 051… |
| 3.16 | `dq_score_dimension` | EN-08-16 | Không | 028, 029 |
| 3.17 | `dq_incremental_buffer` | EN-08-31 | Không | 025 |
| 3.18 | `dq_score_current` | EN-08-32 | Không | 025, 050, 051 |
| 3.19 | `dq_inline_stat` | EN-08-25 | Tháng, bucket_at | 032, 033, 034, 035 |
| 3.20 | `dq_finding` | EN-08-17 | Tháng, last_seen_at | 036, 037, 038, 039 |
| 3.21 | `dq_waiver` | EN-08-18 | Không | 040 |
| 3.22 | `dq_waiver_item` | EN-08-33 | Không | 040 |
| 3.23 | `dq_issue` | EN-08-19 | Không | 041, 042, 043, 044, 045… |
| 3.24 | `dq_issue_activity` | EN-08-20 | Không | 043, 045, 046, 060 |
| 3.25 | `dq_alert_rule` | EN-08-21 | Không | 047, 048 |
| 3.26 | `dq_alert` | EN-08-22 | Không | 048, 049, 050 |
| 3.27 | `dq_report` | EN-08-23 | Không | 052, 053, 054, 055, 056 |
| 3.28 | `dq_report_subscription` | EN-08-24 | Không | 056 |
| 3.29 | `dq_export_request` | EN-08-29 | Không | 039 |
| 3.30 | `dq_tenant_setting` | EN-08-26 | Không | 058 |
| 3.31 | `dq_retention_policy` | EN-08-30 | Không | 059 |
| 3.32 | `dq_retention_run` | EN-08-30 | Không | 059 |
| 3.33 | `outbox_event` | EN-08-27 | Không | 057, 060 |
| 3.34 | `inbox_event` | EN-08-28 | Không | 025 |
| 3.35 | `shedlock` | Hạ tầng | Không | Hạ tầng |

: Danh mục bảng của schema ph08_dq

<!-- gen:danh-muc:end -->

### 1.7. Truy vấn chính và chỉ mục

Các truy vấn sau quyết định chỉ mục của `dq_finding` và `dq_score_snapshot`; kế hoạch thực thi đã kiểm trên 300.000 dòng giả (EXPLAIN dùng đúng chỉ mục, mục 4.2).

| Truy vấn | Chỉ mục | FR |
|---|---|---|
| Lỗi của một đối tượng theo trạng thái, mới nhất trước | `ix_dq_finding_asset (tenant_id, asset_id, status, last_seen_at DESC)` | 037 |
| Lỗi theo quy tắc | `ix_dq_finding_rule (tenant_id, rule_id, status)` | 037 |
| Hộp lỗi đang mở theo mức nghiêm trọng | `ix_dq_finding_open` (một phần, `status IN ('OPEN', 'IN_REMEDIATION')`) | 037, 050 |
| Lỗi theo dấu vân tay (biết mới, còn, hết) | `ix_dq_finding_fp (tenant_id, fingerprint)` | 036 |
| Lỗi theo bản ghi nguồn (băm khóa) | `ix_dq_finding_key (tenant_id, asset_id, record_key_hash)` | 038 |
| Lỗi theo phiếu, theo tổ chức chủ quản | `ix_dq_finding_issue`, `ix_dq_finding_owner` | 041, 042 |
| Điểm của đối tượng theo kỳ | `ix_dq_score_snapshot_asset (tenant_id, asset_id, period_code, measured_at DESC)` | 029, 051 |
| Điểm theo miền, theo tổ chức, báo cáo chính thức | `ix_dq_score_snapshot_domain`, `_org`, `_official` | 051, 054 |
| Hộp việc phiếu khắc phục, phiếu quá hạn SLA | `ix_dq_issue_inbox`, `ix_dq_issue_sla` | 042, 045 |

: Truy vấn chính và chỉ mục

## 2. Sơ đồ thực thể – quan hệ

Sơ đồ chia bốn nhóm để đọc được trên trang A4; khóa ngoại đều kèm `tenant_id` nên không vẽ. Đường nét liền là khóa ngoại thật, ghi chú "logic" là tham chiếu không có khóa ngoại.

```{.mermaid caption="ERD nhóm miền, đối tượng đo và hồ sơ dữ liệu"}
erDiagram
  dq_domain ||--o{ dq_asset : "thuộc miền"
  dq_asset ||--o{ dq_asset_field : "trường, CDE"
  dq_asset ||--o{ dq_profile_run : "lần hồ sơ"
  dq_profile_run ||--o{ dq_profile_column : "thống kê cột"
  dq_domain ||--o{ dq_weight_config : "trọng số theo miền"
  dq_asset ||--o{ dq_weight_config : "trọng số theo đối tượng"
```

Nhóm này là danh mục đối tượng đo: miền gom đối tượng theo lĩnh vực và mang tổ chức chủ quản, đối tượng có bốn loại, mỗi trường có cờ CDE và cách lưu giá trị lỗi (`value_mode`) theo phân loại PH-09. Hồ sơ dữ liệu là kết quả phụ, tách khỏi quy tắc.

```{.mermaid caption="ERD nhóm bộ quy tắc, phiên bản và quy tắc"}
erDiagram
  dq_asset ||--o{ dq_rule_set : "bộ quy tắc"
  dq_rule_set ||--o{ dq_rule_set_version : "phiên bản"
  dq_rule_set_version ||--o{ dq_rule : "quy tắc con"
  dq_weight_config ||--o{ dq_rule_set_version : "trọng số áp"
  dq_rule_template }o--o{ dq_rule : "logic, template_code"
```

Phiên bản bộ quy tắc có vòng đời DRAFT đến ACTIVE; quy tắc chỉ sửa được khi phiên bản là DRAFT. Quy tắc mẫu (kể cả dòng `COMMON`) được sao chép vào quy tắc của tenant chứ không tham chiếu cứng, nên đổi mẫu không làm đổi phiên bản đã kích hoạt.

```{.mermaid caption="ERD nhóm lần đo, kết quả, điểm và kiểm tra trực tuyến"}
erDiagram
  dq_schedule ||--o{ dq_scan_job : "kích hoạt theo lịch"
  dq_asset ||--o{ dq_scan_job : "được đo"
  dq_rule_set_version ||--o{ dq_scan_job : "bộ quy tắc dùng"
  dq_scan_job ||--o{ dq_scan_task : "mảnh"
  dq_scan_job ||--o{ dq_rule_result : "kết quả quy tắc"
  dq_rule ||--o{ dq_rule_result : "của quy tắc"
  dq_scan_job ||--|| dq_score_snapshot : "điểm"
  dq_score_snapshot ||--o{ dq_score_dimension : "sáu chiều"
  dq_asset ||--o{ dq_inline_stat : "logic, theo phút"
  dq_asset ||--o{ dq_incremental_buffer : "gom khóa đổi"
  dq_score_snapshot ||--o| dq_score_current : "điểm hiện hành"
```

Mỗi lần đo cho đúng một snapshot điểm và tối đa sáu dòng điểm chiều; bộ đệm gom khóa và điểm hiện hành phục vụ đo tăng dần; kết quả quy tắc và thống kê trực tuyến là bảng phân vùng nên các liên kết tới chúng là logic hoặc một chiều.

```{.mermaid caption="ERD nhóm bản ghi lỗi, khắc phục, cảnh báo và báo cáo"}
erDiagram
  dq_asset ||--o{ dq_finding : "lỗi của đối tượng"
  dq_rule ||--o{ dq_finding : "lỗi của quy tắc"
  dq_issue ||--o{ dq_finding : "logic, issue_id"
  dq_waiver ||--o{ dq_finding : "logic, waiver_id"
  dq_waiver ||--o{ dq_waiver_item : "dấu vân tay"
  dq_retention_policy ||--o{ dq_retention_run : "logic, object_type"
  dq_issue ||--o{ dq_issue_activity : "hoạt động"
  dq_scan_job ||--o| dq_issue : "đo lại kiểm chứng"
  dq_alert_rule ||--o{ dq_alert : "cảnh báo phát"
  dq_report ||--o{ dq_export_request : "logic, cùng bộ lọc"
  dq_domain ||--o{ dq_report_subscription : "đăng ký nhận"
```

Ngoại lệ phạm vi `FINDINGS` giữ danh sách dấu vân tay ở `dq_waiver_item`; lịch sử dọn ở `dq_retention_run`. Bản ghi lỗi gắn phiếu khắc phục và ngoại lệ bằng `issue_id`, `waiver_id` (không khóa ngoại vì bảng phân vùng, dịch vụ kiểm). Phiếu VERIFIED trỏ về lần đo lại kiểm chứng; cảnh báo và báo cáo là đầu ra của điểm.

## 3. Đặc tả bảng

Phần dưới sinh bằng `ph08/tools/dung_md.py` từ DDL; sửa ở DDL rồi sinh lại, không sửa tay. Mỗi bảng có khối đặc tả 10 mục trích từ DDL, bảng cột nổi bật (có ghi chú hoặc enum) và một dòng liệt kê cột còn lại; bảy cột ngữ cảnh chuẩn (`id`, `tenant_id`, `created_*`, `updated_*`, `version`) không nhắc lại. Các enum `dimension`, `severity` giống nhau ở mọi bảng nên chỉ nêu ở chương 8.1.

<!-- gen:tables:start -->
### 3.1. `dq_domain`

::: dac-ta
**Mục đích.** EN-08-01 Miền chất lượng dữ liệu: nhóm đối tượng đo theo lĩnh vực quản lý, gắn tổ chức chủ quản (DO) và cán bộ phụ trách (FR-08-001). Mang chế độ xử lý khi dịch vụ phụ thuộc lỗi lúc kiểm tra trực tuyến (FAIL_OPEN, FAIL_CLOSED). Không xóa, chỉ chuyển INACTIVE.

**FR phục vụ.** FR-08-001, 035; EN-08-01.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_domain_tid` (tenant_id, id), `uq_dq_domain_code` (tenant_id, domain_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_dq_domain_` + `tenant`, `code`, `owner`, `status`, `failure`, `reason`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `domain_code` (`tg_dq_domain_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `owner_org_code` | `varchar(63)` | Mã tổ chức chủ quản (DO) ở PH-01; kiểm ở dịch vụ, không khóa ngoại liên schema. |
| `status` | `varchar(16), mặc định 'ACTIVE'` | Giá trị: `ACTIVE`, `INACTIVE`. |
| `on_dependency_failure` | `varchar(16), mặc định 'FAIL_OPEN'` | FAIL_OPEN cho phép bản ghi đi tiếp khi PH-07, PH-05 không khả dụng; FAIL_CLOSED chặn (FR-08-031, 032). Giá trị: `FAIL_OPEN`, `FAIL_CLOSED`. |

: Cột nổi bật của bảng `dq_domain`

Cột khác: `domain_code` v(32); `name` v(255); `description` v(2000); `steward_user` v(64); `status_reason` v(2000).

### 3.2. `dq_asset`

::: dac-ta
**Mục đích.** EN-08-02 Đối tượng đo chất lượng, bốn loại: miền dữ liệu chủ PH-06, danh mục PH-07, bảng hoặc khung nhìn nguồn qua kết nối PH-05 chỉ đọc, bản tin luồng PH-04 (FR-08-002, 003, 004, 006, 007). Cột tham chiếu bắt buộc đúng theo loại. Không xóa, chỉ ngừng hoặc khôi phục.

**FR phục vụ.** FR-08-002, 003, 004, 006, 007; EN-08-02.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_asset_tid` (tenant_id, id), `uq_dq_asset_code` (tenant_id, asset_code).

**Khóa ngoại.** (tenant_id, domain_code) → `dq_domain`.

**Ràng buộc CHECK.** `ck_dq_asset_` + `tenant`, `code`, `type`, `status`, `scan_mode`, `class`, `ref`, `inline_mode`, `inline_on`, `failure`, `timeout`, `gate`, `incremental`, `updated_field`, `sample`, `reason`.

**Chỉ mục.** `ix_dq_asset_domain`, `ix_dq_asset_owner`, `ix_dq_asset_mdm`, `ix_dq_asset_rdm`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `asset_code`, `asset_type` (`tg_dq_asset_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `asset_type` | `varchar(16)` | Giá trị: `MDM_DOMAIN`, `RDM_CATALOG`, `SOURCE_DATASET`, `FLOW_MESSAGE`. |
| `status` | `varchar(16), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `ACTIVE`, `SUSPENDED`, `RETIRED`. |
| `mdm_domain_code` | `varchar(32), NULL` | Domain PH-06; đọc qua view hợp đồng chỉ đọc do PH-06 cấp, không đọc bảng nghiệp vụ. |
| `connection_id` | `uuid, NULL` | Mã kết nối PH-05 (tài khoản chỉ đọc, Q359, ADR-067); kiểm ở dịch vụ, không khóa ngoại. |
| `default_scan_mode` | `varchar(16), mặc định 'FULL'` | Giá trị: `FULL`, `SAMPLE`, `INCREMENTAL`. |
| `highest_data_class` | `varchar(16), mặc định 'INTERNAL'` | Phân loại cao nhất trong các trường, lấy từ PH-09; điều khiển cách lưu giá trị lỗi. Giá trị: `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE`. |
| `incremental_enabled` | `boolean, mặc định false` | Bật đo tăng dần theo sự kiện PH-06, PH-07 (FR-08-025, API-08-130, 131); không áp cho FLOW_MESSAGE, SOURCE_DATASET cần updated_at_field. |
| `inline_enabled` | `boolean, mặc định false` | Cấu hình kiểm tra trực tuyến của đối tượng (FR-08-032, 035): bật, chế độ STRICT hay ADVISORY, hành vi khi phụ thuộc lỗi (rỗng thì theo miền), ngân sách ms, cổng chất lượng cho PH-06. |
| `inline_mode` | `varchar(10), NULL` | Giá trị: `STRICT`, `ADVISORY`. |
| `on_dependency_failure` | `varchar(16), NULL` | Giá trị: `FAIL_OPEN`, `FAIL_CLOSED`. |
| `gate_enabled` | `boolean, mặc định false` | Cổng chất lượng đầu vào cho PH-06, chỉ MDM_DOMAIN đã bật trực tuyến (FR-08-035). |

: Cột nổi bật của bảng `dq_asset`

Cột khác: `domain_code` v(32); `asset_code` v(63); `name` v(255); `status_reason` v(2000); `owner_org_code` v(63); `rdm_catalog_code` v(64); `object_name` v(255); `flow_code` v(63); `key_columns` v(63)[]; `sample_ratio` num(5,4); `description` v(2000); `updated_at_field` v(63); `inline_timeout_ms` smallint.

### 3.3. `dq_asset_field`

::: dac-ta
**Mục đích.** EN-08-03 Trường của đối tượng đo, kèm cờ phần tử dữ liệu trọng yếu (CDE) và phân loại PH-09 (FR-08-005, 006, 009). Cột value_mode quyết định cách lưu giá trị lỗi: trường Nhạy cảm chỉ được băm, trường Hạn chế phải che.

**FR phục vụ.** FR-08-005, 006, 009; EN-08-03.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_asset_field_name` (tenant_id, asset_id, field_name).

**Khóa ngoại.** (tenant_id, asset_id) → `dq_asset`.

**Ràng buộc CHECK.** `ck_dq_asset_field_` + `tenant`, `name`, `type`, `class`, `classification`, `mode`, `mode_class`.

**Chỉ mục.** `ix_dq_asset_field_cde`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `field_type` | `varchar(16), mặc định 'STRING'` | Giá trị: `STRING`, `INTEGER`, `DECIMAL`, `DATE`, `TIMESTAMP`, `BOOLEAN`, `CODE`, `JSON`. |
| `cde` | `boolean, mặc định false` | Phần tử dữ liệu trọng yếu: lỗi CRITICAL bắt buộc ở CDE theo cấu hình (FR-08-005). |
| `data_class` | `varchar(16), mặc định 'INTERNAL'` | Giá trị: `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE`. |
| `classification_status` | `varchar(16), mặc định 'PROPOSED'` | Giá trị: `PROPOSED`, `CONFIRMED`. |
| `value_mode` | `varchar(16), mặc định 'MASKED'` | MASKED lưu giá trị đã che, HASH_ONLY chỉ lưu băm, PLAIN chỉ cho PUBLIC, INTERNAL. SENSITIVE bắt buộc HASH_ONLY, RESTRICTED không được PLAIN (BR giá trị lỗi, FR-08-036). Giá trị: `MASKED`, `HASH_ONLY`, `PLAIN`. |

: Cột nổi bật của bảng `dq_asset_field`

Cột khác: `asset_id` uuid; `field_name` v(63); `label` v(255); `rdm_catalog_code` v(64); `sort_order` smallint.

### 3.4. `dq_profile_run`

::: dac-ta
**Mục đích.** EN-08-04 Lần chạy hồ sơ dữ liệu (profiling) cho một đối tượng đo, theo mẫu hoặc toàn bộ (FR-08-008, 011). Kết quả theo cột ở dq_profile_column.

**FR phục vụ.** FR-08-008, 011; EN-08-04.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_profile_run_tid` (tenant_id, id).

**Khóa ngoại.** (tenant_id, asset_id) → `dq_asset`.

**Ràng buộc CHECK.** `ck_dq_profile_run_` + `tenant`, `status`, `mode`, `done`, `error`.

**Chỉ mục.** `ix_dq_profile_run_asset`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(16), mặc định 'QUEUED'` | Giá trị: `QUEUED`, `RUNNING`, `SUCCEEDED`, `FAILED`. |
| `scan_mode` | `varchar(16), mặc định 'SAMPLE'` | Giá trị: `FULL`, `SAMPLE`, `EXTERNAL`. |

: Cột nổi bật của bảng `dq_profile_run`

Cột khác: `asset_id` uuid; `sample_rows` bigint; `row_count` bigint; `requested_by` v(64); `started_at` tstz; `finished_at` tstz; `source_snapshot_at` tstz; `error_code` v(16); `error_message` v(2000).

### 3.5. `dq_profile_column`

::: dac-ta
**Mục đích.** EN-08-05 Thống kê hồ sơ theo cột: số rỗng, số giá trị khác nhau ước lượng bằng HyperLogLog, phân vị (Apache DataSketches), mẫu định dạng thường gặp (FR-08-009, 010). Cột Nhạy cảm không lưu giá trị mẫu, nhỏ nhất, lớn nhất.

**FR phục vụ.** FR-08-009, 010, 011; EN-08-05.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_profile_column` (tenant_id, profile_run_id, field_name).

**Khóa ngoại.** (tenant_id, profile_run_id) → `dq_profile_run`.

**Ràng buộc CHECK.** `ck_dq_profile_column_` + `tenant`, `name`, `counts`, `sensitive`.

**Chỉ mục.** `ix_dq_profile_column_asset`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `sensitive` | `boolean, mặc định false` | Sao chép từ dq_asset_field.value_mode = HASH_ONLY; khi true, CHECK cấm lưu giá trị mẫu. |

: Cột nổi bật của bảng `dq_profile_column`

Cột khác: `profile_run_id` uuid; `asset_id` uuid; `field_name` v(63); `inferred_type` v(16); `row_count` bigint; `null_count` bigint; `empty_count` bigint; `distinct_estimate` bigint; `min_masked` v(255); `max_masked` v(255); `quantiles` jsonb; `top_values` jsonb; `pattern_stats` jsonb.

### 3.6. `dq_rule_template`

::: dac-ta
**Mục đích.** EN-08-09 Quy tắc mẫu dùng lại: CCCD, mã số thuế, số điện thoại, email, đơn vị hành chính (FR-08-015). Dòng tenant COMMON do PLATFORM quản, mọi tenant đọc được (mẫu RLS S, cách PH-07); tenant có thể thêm mẫu riêng.

**FR phục vụ.** FR-08-010, 015; EN-08-09.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_rule_template_code` (tenant_id, template_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_dq_rule_template_` + `tenant`, `code`, `dimension`, `operator`, `severity`, `status`, `expr`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu S: mọi tenant đọc được dòng `COMMON`, chỉ phiên PLATFORM ghi `COMMON`.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `operator` | `varchar(24)` | Giá trị: `NOT_NULL`, `NOT_EMPTY`, `REQUIRED_IF`, `REGEX`, `LENGTH`, `RANGE`, `CHECKSUM`, `TYPE`, `EQ_SOURCE`, `EQ_FIELDS`, `CROSS_ENTITY`, `MAX_AGE_DAYS`, `UPDATED_AFTER`, `UNIQUE_IN_ASSET`, `UNIQUE_COMPOSITE`, `IN_RDM`, `IN_RDM_VERSION`, `CEL_EXPRESSION`, `SQL_PREDICATE`. |
| `default_severity` | `varchar(8), mặc định 'MAJOR'` | Giá trị: `CRITICAL`, `MAJOR`, `MINOR`. |
| `status` | `varchar(16), mặc định 'ACTIVE'` | Giá trị: `ACTIVE`, `RETIRED`. |

: Cột nổi bật của bảng `dq_rule_template`

Cột khác: `template_code` v(64); `name` v(255); `dimension` v(16); `params` jsonb; `expression_template` text; `description` v(2000).

### 3.7. `dq_weight_config`

::: dac-ta
**Mục đích.** EN-08-10 Cấu hình trọng số sáu chiều và ngưỡng điểm, có phiên bản và duyệt bốn mắt (FR-08-021, 028). Phạm vi tenant, miền hoặc đối tượng đo; mặc định 0,20/0,20/0,15/0,10/0,15/0,20. Tổng trọng số bằng 1,000 với dung sai 0,001.

**FR phục vụ.** FR-08-021, 028; EN-08-10.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_weight_config_tid` (tenant_id, id), `uq_dq_weight_config_version` (tenant_id, config_code, version_no), `uq_dq_weight_config_active` (tenant_id, COALESCE(domain_code, ''), COALESCE(asset_id, '00000000-0000-0000-0000-000000000000'::uuid)) có điều kiện.

**Khóa ngoại.** (tenant_id, asset_id) → `dq_asset`, (tenant_id, domain_code) → `dq_domain`.

**Ràng buộc CHECK.** `ck_dq_weight_config_` + `tenant`, `status`, `sum`, `range`, `threshold`, `scope`, `four_eyes`, `active`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `config_code`, `version_no` (`tg_dq_weight_config_immutable`); Trigger: `tg_dq_weight_config_frozen`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(20), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `PENDING_APPROVAL`, `ACTIVE`, `SUPERSEDED`, `RETIRED`. |
| `w_completeness` | `numeric(5,4), mặc định 0.20` | Cột w_* theo thứ tự COMPLETENESS, ACCURACY, CONSISTENCY, TIMELINESS, UNIQUENESS, VALIDITY. |
| `pass_min` | `numeric(5,2), mặc định 80` | Điểm từ ngưỡng này trở lên: PASS; từ warn_min: WARN; dưới: FAIL (mặc định 80 và 70, FR-08-021). |
| `effective_from` | `timestamptz, NULL` | Thời điểm cấu hình có hiệu lực khi được duyệt; lần đo sau thời điểm này chấm theo cấu hình mới (FR-08-021). |

: Cột nổi bật của bảng `dq_weight_config`

Cột khác: `config_code` v(63); `version_no` int; `domain_code` v(32); `asset_id` uuid; `w_accuracy` num(5,4); `w_consistency` num(5,4); `w_timeliness` num(5,4); `w_uniqueness` num(5,4); `w_validity` num(5,4); `warn_min` num(5,2); `submitted_by` v(64); `submitted_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `activated_at` tstz; `superseded_at` tstz; `change_note` v(2000).

### 3.8. `dq_rule_set`

::: dac-ta
**Mục đích.** EN-08-06 Bộ quy tắc của một đối tượng đo (FR-08-012, 018, 020, 022). Nội dung nằm ở các phiên bản dq_rule_set_version; mỗi bộ có đúng một phiên bản ACTIVE.

**FR phục vụ.** FR-08-012, 018, 020, 022; EN-08-06.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_rule_set_tid` (tenant_id, id), `uq_dq_rule_set_code` (tenant_id, set_code).

**Khóa ngoại.** (tenant_id, asset_id) → `dq_asset`.

**Ràng buộc CHECK.** `ck_dq_rule_set_` + `tenant`, `code`, `current`.

**Chỉ mục.** `ix_dq_rule_set_asset`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `set_code`, `asset_id` (`tg_dq_rule_set_immutable`).

**Ghi chú.** ETag là `version`.
:::

Cột khác: `set_code` v(63); `name` v(255); `asset_id` uuid; `description` v(2000); `current_version_no` int.

### 3.9. `dq_rule_set_version`

::: dac-ta
**Mục đích.** EN-08-07 Phiên bản bộ quy tắc, vòng đời DRAFT, PENDING_APPROVAL, ACTIVE, SUPERSEDED, RETIRED, duyệt bốn mắt (FR-08-012, 017, 018, 019). Phiên bản ACTIVE hoặc SUPERSEDED bất biến; quy tắc con chỉ sửa khi phiên bản là DRAFT.

**FR phục vụ.** FR-08-012, 017, 018, 019, 020; EN-08-07.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_rule_set_version_tid` (tenant_id, id), `uq_dq_rule_set_version_no` (tenant_id, rule_set_id, version_no), `uq_dq_rule_set_version_active` (tenant_id, rule_set_id) có điều kiện.

**Khóa ngoại.** (tenant_id, rule_set_id) → `dq_rule_set`, (tenant_id, weight_config_id) → `dq_weight_config`.

**Ràng buộc CHECK.** `ck_dq_rule_set_version_` + `tenant`, `no`, `status`, `hash`, `dry_hash`, `dry_run`, `approved`, `decision`, `four_eyes`, `active`, `reject`.

**Chỉ mục.** `ix_dq_rule_set_version_status`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `rule_set_id`, `version_no` (`tg_dq_rule_set_version_immutable`); Trigger: `tg_dq_rule_set_version_frozen`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(20), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `ACTIVE`, `SUPERSEDED`, `RETIRED`. |
| `content_hash` | `bytea, NULL` | SHA-256 nội dung quy tắc tại lúc gửi duyệt; ACTIVE bắt buộc có (bất biến, FR-08-018, 019). |
| `rule_count` | `integer, mặc định 0` | Số quy tắc; ACTIVE phải lớn hơn 0. |
| `decision` | `varchar(8), NULL` | Giá trị: `APPROVE`, `REJECT`. |
| `effective_from` | `timestamptz, NULL` | Giờ hiệu lực khi duyệt; tương lai thì APPROVED chờ kích hoạt, hiện tại thì ACTIVE ngay (FR-08-017, 018). |
| `dry_run_content_hash` | `bytea, NULL` | Băm phần nội dung ảnh hưởng kết quả đo tại lần chạy thử cuối (FR-08-016); gửi duyệt cần bằng content_hash. Sửa tên, mô tả, thông điệp quy tắc không đổi băm này. |

: Cột nổi bật của bảng `dq_rule_set_version`

Cột khác: `rule_set_id` uuid; `version_no` int; `weight_config_id` uuid; `change_note` v(2000); `submitted_by` v(64); `submitted_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `activated_at` tstz; `superseded_at` tstz; `last_dry_run_id` uuid; `dry_run_at` tstz.

### 3.10. `dq_rule`

::: dac-ta
**Mục đích.** EN-08-08 Quy tắc chất lượng: chiều, toán tử, mức nghiêm trọng, chế độ chạy (lô, trực tuyến, cả hai) và tham số (FR-08-013, 014, 016, 022). Biểu thức CEL hoặc vị từ SQL có kiểm soát nằm ở cột expression; vị từ SQL chỉ chạy theo lô.

**FR phục vụ.** FR-08-010, 013, 014, 016, 019, 020, 022, 033, 035; EN-08-08.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_rule_tid` (tenant_id, id), `uq_dq_rule_code` (tenant_id, rule_set_version_id, rule_code).

**Khóa ngoại.** (tenant_id, rule_set_version_id) → `dq_rule_set_version`.

**Ràng buộc CHECK.** `ck_dq_rule_` + `tenant`, `code`, `dimension`, `operator`, `severity`, `exec`, `inline`, `operator_dimension`, `expression`, `sql_batch`, `rdm`, `weight`, `source`.

**Chỉ mục.** `ix_dq_rule_version`, `ix_dq_rule_inline`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Trigger: `tg_dq_rule_child_frozen`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `operator` | `varchar(24)` | 19 toán tử theo FRS; ràng buộc operator_dimension khóa quan hệ toán tử với chiều (ví dụ IN_RDM chỉ thuộc VALIDITY). Giá trị: `NOT_NULL`, `NOT_EMPTY`, `REQUIRED_IF`, `REGEX`, `LENGTH`, `RANGE`, `CHECKSUM`, `TYPE`, `EQ_SOURCE`, `EQ_FIELDS`, `CROSS_ENTITY`, `MAX_AGE_DAYS`, `UPDATED_AFTER`, `UNIQUE_IN_ASSET`, `UNIQUE_COMPOSITE`, `IN_RDM`, `IN_RDM_VERSION`, `CEL_EXPRESSION`, `SQL_PREDICATE`. |
| `exec_mode` | `varchar(8), mặc định 'BATCH'` | Giá trị: `BATCH`, `INLINE`, `BOTH`. |
| `inline_mode` | `varchar(10), NULL` | STRICT chặn bản ghi lỗi, ADVISORY chỉ cảnh báo; rỗng khi exec_mode = BATCH (FR-08-032, 033). |
| `expression` | `text, NULL` | CEL (cel-java) hoặc vị từ SQL có kiểm soát; chỉ khi operator là CEL_EXPRESSION hoặc SQL_PREDICATE (FR-08-014). |
| `message` | `varchar(500), NULL` | Thông điệp hiển thị ở bản ghi lỗi khi quy tắc không đạt (thay cột thong_diep của SRS cũ). |
| `source` | `varchar(12), mặc định 'MANUAL'` | Nguồn gốc quy tắc: nhập tay, từ quy tắc mẫu, gợi ý từ hồ sơ, nhập tệp, sao chép (FR-08-010, 015, 020). Giá trị: `MANUAL`, `TEMPLATE`, `SUGGESTED`, `IMPORTED`, `COPIED`. |

: Cột nổi bật của bảng `dq_rule`

Cột khác: `rule_set_version_id` uuid; `rule_code` v(63); `name` v(255); `description` v(2000); `dimension` v(16); `severity` v(8); `field_name` v(63); `params` jsonb; `weight` num(6,3); `template_code` v(64); `enabled` bool.

### 3.11. `dq_schedule`

::: dac-ta
**Mục đích.** EN-08-11 Lịch đo theo lô bằng biểu thức cron (FR-08-023). Phạm vi là một đối tượng, một miền hoặc cả tenant; mặc định ngày 1 hằng tháng lúc 02:00. Lập lịch chạy bằng Quartz có ShedLock.

**FR phục vụ.** FR-08-023; EN-08-11.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_schedule_tid` (tenant_id, id), `uq_dq_schedule_code` (tenant_id, schedule_code).

**Khóa ngoại.** (tenant_id, asset_id) → `dq_asset`, (tenant_id, domain_code) → `dq_domain`.

**Ràng buộc CHECK.** `ck_dq_schedule_` + `tenant`, `code`, `scope`, `mode`, `cron`.

**Chỉ mục.** `ix_dq_schedule_next`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `scan_mode` | `varchar(16), mặc định 'FULL'` | Giá trị: `FULL`, `SAMPLE`, `INCREMENTAL`. |

: Cột nổi bật của bảng `dq_schedule`

Cột khác: `schedule_code` v(63); `domain_code` v(32); `asset_id` uuid; `cron` v(64); `timezone` v(40); `enabled` bool; `next_run_at` tstz; `last_run_at` tstz; `last_job_id` uuid.

### 3.12. `dq_scan_job`

::: dac-ta
**Mục đích.** EN-08-12 Lần đo chất lượng của một đối tượng đo với một phiên bản bộ quy tắc (FR-08-023…026, 030, 031). Kích hoạt theo lịch, thủ công, sự kiện, hằng năm (bắt buộc đo đủ) hoặc đo lại kiểm chứng phiếu khắc phục. Mỗi đối tượng chỉ một lần đo đang chạy.

**FR phục vụ.** FR-08-023, 024, 025, 026, 030, 031, 050; EN-08-12.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_scan_job_tid` (tenant_id, id), `uq_dq_scan_job_running` (tenant_id, asset_id) có điều kiện, `uq_dq_scan_job_idem` (tenant_id, idempotency_key) có điều kiện.

**Khóa ngoại.** (tenant_id, asset_id) → `dq_asset`, (tenant_id, rule_set_version_id) → `dq_rule_set_version`, (tenant_id, weight_config_id) → `dq_weight_config`, (tenant_id, schedule_id) → `dq_schedule`, (tenant_id, rerun_of) → `dq_scan_job`.

**Ràng buộc CHECK.** `ck_dq_scan_job_` + `tenant`, `trigger`, `mode`, `status`, `period`, `annual_full`, `verify`, `event`, `done`, `cancel`, `progress`, `sample`, `error`, `flags`, `idem`.

**Chỉ mục.** `ix_dq_scan_job_asset`, `ix_dq_scan_job_period`, `ix_dq_scan_job_queue`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `asset_id`, `rule_set_version_id`, `scan_trigger`, `scan_mode`, `period_code` (`tg_dq_scan_job_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `scan_trigger` | `varchar(12)` | Giá trị: `SCHEDULE`, `MANUAL`, `EVENT`, `ANNUAL`, `VERIFY`. |
| `scan_mode` | `varchar(16)` | Giá trị: `FULL`, `SAMPLE`, `INCREMENTAL`. |
| `status` | `varchar(12), mặc định 'QUEUED'` | Giá trị: `QUEUED`, `RUNNING`, `SUCCEEDED`, `PARTIAL`, `FAILED`, `CANCELLED`. |
| `period_code` | `varchar(7)` | Kỳ đo: YYYY-MM (tháng) hoặc YYYY (đo chính thức hằng năm, FR-08-054). |
| `verify_issue_id` | `uuid, NULL` | Phiếu khắc phục cần kiểm chứng (trigger VERIFY, FR-08-044); khóa ngoại nằm ở dq_issue.verify_scan_job_id. |
| `sample_seed` | `bigint, NULL` | Hạt giống lấy mẫu để tái lập kết quả khi đo SAMPLE (SRS cũ EN-08-04). |
| `flags` | `varchar(32)[], mặc định '{}'` | Cờ lần đo: TRUNCATED (vượt trần bản ghi lỗi), INCREMENTAL, INCOMPLETE_DIMENSIONS, WEIGHTS_CHANGED; sao sang ảnh chụp điểm (FR-08-026, 031). |
| `idempotency_hash` | `bytea, NULL` | SHA-256 thân yêu cầu; cùng Idempotency-Key mà băm khác thì trả ERR-08-055 (409), cùng băm thì trả lại lần đo cũ. |

: Cột nổi bật của bảng `dq_scan_job`

Cột khác: `asset_id` uuid; `rule_set_version_id` uuid; `weight_config_id` uuid; `schedule_id` uuid; `requested_by` v(64); `idempotency_key` v(64); `source_event_id` uuid; `rerun_of` uuid; `source_snapshot_at` tstz; `started_at` tstz; `finished_at` tstz; `task_total` int; `task_done` int; `rows_scanned` bigint; `rows_failed` bigint; `skipped_rules` int; `sample_size` int; `error_code` v(16); `error_message` v(2000); `cancel_reason` v(2000).

### 3.13. `dq_scan_task`

::: dac-ta
**Mục đích.** EN-08-13 Tác vụ phân mảnh của lần đo: mỗi mảnh là một khoảng khóa của đối tượng, chạy độc lập, thử lại được (FR-08-026, 030). Dọn sau 90 ngày.

**FR phục vụ.** FR-08-026, 030; EN-08-13.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_scan_task_tid` (tenant_id, id), `uq_dq_scan_task_shard` (tenant_id, scan_job_id, shard_no).

**Khóa ngoại.** (tenant_id, scan_job_id) → `dq_scan_job`.

**Ràng buộc CHECK.** `ck_dq_scan_task_` + `tenant`, `shard`, `status`, `attempt`, `error`, `running`.

**Chỉ mục.** `ix_dq_scan_task_job`, `ix_dq_scan_task_heartbeat`, `ix_dq_scan_task_queue`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(12), mặc định 'QUEUED'` | Giá trị: `QUEUED`, `RUNNING`, `SUCCEEDED`, `FAILED`, `CANCELLED`. |
| `heartbeat_at` | `timestamptz, NULL` | Nhịp cuối của bộ thực thi; quá 08.scan.heartbeat-timeout-seconds thì ScanWatchdog thu hồi tác vụ. |
| `not_before` | `timestamptz, NULL` | Không giao tác vụ trước thời điểm này (lùi thử lại, cửa sổ giờ đo). |

: Cột nổi bật của bảng `dq_scan_task`

Cột khác: `scan_job_id` uuid; `shard_no` int; `shard_count` int; `key_from` v(255); `key_to` v(255); `attempt` smallint; `worker_id` v(64); `rows_scanned` bigint; `rows_failed` bigint; `started_at` tstz; `finished_at` tstz; `error_code` v(16).

### 3.14. `dq_rule_result`

::: dac-ta
**Mục đích.** EN-08-14 Kết quả từng quy tắc trong một lần đo: số dòng xét, số dòng lỗi, tỷ lệ đạt, trạng thái PASSED, FAILED, SKIPPED, ERROR (FR-08-026, 027, 028, 031). Ghi một lần, không sửa. Phân vùng tháng theo executed_at.

**FR phục vụ.** FR-08-026, 027, 028, 031; EN-08-14.

**Khóa chính.** (id, executed_at).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, scan_job_id) → `dq_scan_job`, (tenant_id, rule_id) → `dq_rule`.

**Ràng buộc CHECK.** `ck_dq_rule_result_` + `tenant`, `dimension`, `severity`, `status`, `counts`, `rate`, `skipped`, `skip_reason`, `error`.

**Chỉ mục.** `ix_dq_rule_result_job`, `ix_dq_rule_result_rule`, `ix_dq_rule_result_asset`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Phân vùng tháng theo `executed_at`; Trigger: `tg_dq_rule_result_append_only`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(8)` | Giá trị: `PASSED`, `FAILED`, `SKIPPED`, `ERROR`. |
| `pass_rate` | `numeric(7,6), NULL` | 1 - rows_failed / rows_evaluated; rỗng khi SKIPPED hoặc ERROR. |
| `skip_reason` | `varchar(32), NULL` | Giá trị: `DEPENDENCY_UNAVAILABLE`, `RDM_UNAVAILABLE`, `SOURCE_UNREACHABLE`, `NO_DATA`, `TIMEOUT`. |

: Cột nổi bật của bảng `dq_rule_result`

Cột khác: `executed_at` tstz; `scan_job_id` uuid; `scan_task_id` uuid; `asset_id` uuid; `rule_id` uuid; `dimension` v(16); `severity` v(8); `rows_evaluated` bigint; `rows_failed` bigint; `error_code` v(16); `duration_ms` int.

### 3.15. `dq_score_snapshot`

::: dac-ta
**Mục đích.** EN-08-15 Snapshot điểm chất lượng của một đối tượng trong một kỳ: điểm có trọng số, kết luận PASS, WARN, FAIL, xu hướng so kỳ trước, cờ thiếu chiều hoặc đổi trọng số (FR-08-028, 029, 031, 051). Snapshot chính thức (official) phải từ lần đo đủ và không thiếu chiều.

**FR phục vụ.** FR-08-028, 029, 031, 050, 051, 057, 061; EN-08-15.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_score_snapshot_tid` (tenant_id, id), `uq_dq_score_snapshot_job` (tenant_id, scan_job_id).

**Khóa ngoại.** (tenant_id, scan_job_id) → `dq_scan_job`, (tenant_id, asset_id) → `dq_asset`, (tenant_id, prev_snapshot_id) → `dq_score_snapshot`.

**Ràng buộc CHECK.** `ck_dq_score_snapshot_` + `tenant`, `score`, `verdict`, `trend`, `mode`, `flags`, `period`, `baseline`, `official`.

**Chỉ mục.** `ix_dq_score_snapshot_asset`, `ix_dq_score_snapshot_domain`, `ix_dq_score_snapshot_org`, `ix_dq_score_snapshot_official`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `scan_job_id`, `asset_id`, `period_code`, `score`, `verdict`, `flags`, `official` (`tg_dq_score_snapshot_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `scan_mode` | `varchar(16)` | Giá trị: `FULL`, `SAMPLE`, `INCREMENTAL`. |
| `verdict` | `varchar(4)` | Giá trị: `PASS`, `WARN`, `FAIL`. |
| `trend` | `varchar(10), mặc định 'BASELINE'` | Giá trị: `BASELINE`, `IMPROVED`, `STABLE`, `DEGRADED`. |
| `flags` | `varchar(32)[], mặc định '{}'` | INCOMPLETE_DIMENSIONS: thiếu chiều do SKIPPED; WEIGHTS_CHANGED: trọng số đổi so với kỳ trước. |
| `official` | `boolean, mặc định false` | Dùng cho báo cáo chính thức hằng năm (FR-08-054): chỉ khi đo FULL và không có cờ INCOMPLETE_DIMENSIONS. |

: Cột nổi bật của bảng `dq_score_snapshot`

Cột khác: `scan_job_id` uuid; `asset_id` uuid; `domain_code` v(32); `owner_org_code` v(63); `period_code` v(7); `score` num(5,2); `prev_snapshot_id` uuid; `prev_score` num(5,2); `delta` num(6,2); `weight_config_id` uuid; `rule_set_version_id` uuid; `row_count` bigint; `measured_at` tstz.

### 3.16. `dq_score_dimension`

::: dac-ta
**Mục đích.** EN-08-16 Điểm theo từng chiều trong snapshot, kèm trọng số đã áp và số quy tắc đạt, lỗi, bỏ qua (FR-08-028, 029). Chiều bị bỏ qua có điểm rỗng.

**FR phục vụ.** FR-08-028, 029; EN-08-16.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_score_dimension_tid` (tenant_id, id), `uq_dq_score_dimension` (tenant_id, snapshot_id, dimension).

**Khóa ngoại.** (tenant_id, snapshot_id) → `dq_score_snapshot`.

**Ràng buộc CHECK.** `ck_dq_score_dimension_` + `tenant`, `dimension`, `status`, `score`, `weight`, `counts`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `snapshot_id`, `dimension`, `score`, `status` (`tg_dq_score_dimension_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(10), mặc định 'MEASURED'` | Giá trị: `MEASURED`, `SKIPPED`. |

: Cột nổi bật của bảng `dq_score_dimension`

Cột khác: `snapshot_id` uuid; `dimension` v(16); `score` num(5,2); `weight` num(5,4); `rules_total` int; `rules_passed` int; `rules_failed` int; `rules_skipped` int; `rows_failed` bigint.

### 3.17. `dq_incremental_buffer`

::: dac-ta
**Mục đích.** EN-08-31 Bộ đệm gom khóa bản ghi đổi theo cửa sổ để đo tăng dần theo sự kiện PH-06, PH-07 (FR-08-025). Mỗi đối tượng đúng một bộ đệm COLLECTING; vượt 100.000 khóa thì OVERFLOW và chờ lần đo FULL.

**FR phục vụ.** FR-08-025; EN-08-31.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_incremental_buffer_tid` (tenant_id, id), `uq_dq_incremental_buffer_open` (tenant_id, asset_id) có điều kiện.

**Khóa ngoại.** (tenant_id, asset_id) → `dq_asset`, (tenant_id, scan_job_id) → `dq_scan_job`.

**Ràng buộc CHECK.** `ck_dq_incremental_buffer_` + `tenant`, `status`, `window`, `keys`, `scheduled`.

**Chỉ mục.** `ix_dq_incremental_buffer_due`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(12), mặc định 'COLLECTING'` | Giá trị: `COLLECTING`, `OVERFLOW`, `SCHEDULED`, `DONE`. |
| `keys` | `text[], mặc định '{}'` | Khóa bản ghi đổi đã khử trùng (text, tối đa 100.000 mỗi cửa sổ, BR-08-033); đo xong thì xóa khóa, giữ dòng để kiểm toán. |

: Cột nổi bật của bảng `dq_incremental_buffer`

Cột khác: `asset_id` uuid; `window_start` tstz; `window_end` tstz; `event_count` int; `scan_job_id` uuid.

### 3.18. `dq_score_current`

::: dac-ta
**Mục đích.** EN-08-32 Điểm hiện hành của một đối tượng: ảnh chụp đầy đủ gần nhất gộp với các lần đo tăng dần sau đó, nhãn INCREMENTAL, không dùng cho báo cáo năm (FR-08-025, 050, 051). Một dòng mỗi đối tượng.

**FR phục vụ.** FR-08-025, 050, 051; EN-08-32.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_score_current_tid` (tenant_id, id), `uq_dq_score_current_asset` (tenant_id, asset_id).

**Khóa ngoại.** (tenant_id, asset_id) → `dq_asset`, (tenant_id, full_snapshot_id) → `dq_score_snapshot`, (tenant_id, incremental_scan_job_id) → `dq_scan_job`.

**Ràng buộc CHECK.** `ck_dq_score_current_` + `tenant`, `score`, `verdict`, `flags`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `current_score` | `numeric(5,2)` | Điểm hiển thị ở bảng điều khiển; ảnh chụp đầy đủ vẫn là nguồn cho báo cáo (BR-08-033). |
| `verdict` | `varchar(4)` | Giá trị: `PASS`, `WARN`, `FAIL`. |

: Cột nổi bật của bảng `dq_score_current`

Cột khác: `asset_id` uuid; `full_snapshot_id` uuid; `incremental_scan_job_id` uuid; `flags` v(32)[]; `as_of` tstz.

### 3.19. `dq_inline_stat`

::: dac-ta
**Mục đích.** EN-08-25 Thống kê kiểm tra trực tuyến gộp theo phút, theo đối tượng và bên gọi: số lượt, đạt, lỗi, thời gian p50, p95, số lần mở hoặc đóng khi phụ thuộc lỗi (FR-08-032, 034). Không lưu nội dung bản ghi. Phân vùng tháng theo bucket_at; dọn sau 90 ngày.

**FR phục vụ.** FR-08-032, 033, 034, 035; EN-08-25.

**Khóa chính.** (id, bucket_at).

**Duy nhất.** `uq_dq_inline_stat_bucket` (tenant_id, asset_id, caller_code, mode, bucket_at).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_dq_inline_stat_` + `tenant`, `bucket`, `mode`, `counts`, `warn`, `blocked`, `latency`.

**Chỉ mục.** `ix_dq_inline_stat_asset`, `ix_dq_inline_stat_caller`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Phân vùng tháng theo `bucket_at`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `mode` | `varchar(10), mặc định 'ADVISORY'` | Giá trị: `STRICT`, `ADVISORY`. |
| `warn_count` | `integer, mặc định 0` | Số lượt lỗi ở chế độ ADVISORY (chỉ cảnh báo, không chặn); chế độ STRICT dùng blocked_count. |
| `fail_open_count` | `integer, mặc định 0` | Số lượt phụ thuộc lỗi mà bản ghi vẫn đi tiếp; cộng với fail_closed_count là số lượt suy giảm (degraded). |

: Cột nổi bật của bảng `dq_inline_stat`

Cột khác: `bucket_at` tstz; `asset_id` uuid; `caller_code` v(63); `check_count` int; `pass_count` int; `fail_count` int; `blocked_count` int; `error_count` int; `fail_closed_count` int; `p50_ms` int; `p95_ms` int; `max_ms` int; `by_rule` jsonb.

### 3.20. `dq_finding`

::: dac-ta
**Mục đích.** EN-08-17 Bản ghi lỗi: một dòng cho mỗi lỗi còn tồn tại, nhận dạng bằng dấu vân tay fingerprint (băm khóa bản ghi và mã quy tắc) để biết mới, còn, hết qua các kỳ (FR-08-036, 037, 038, 039). Không lưu giá trị gốc: chỉ masked_value (đã che) và value_hash (băm có khóa); trường Nhạy cảm chỉ có băm. Phân vùng tháng theo last_seen_at, mỗi lần thấy lại dòng chuyển sang phân vùng mới.

**FR phục vụ.** FR-08-036, 037, 038, 039; EN-08-17.

**Khóa chính.** (id, last_seen_at).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, asset_id) → `dq_asset`, (tenant_id, rule_id) → `dq_rule`.

**Ràng buộc CHECK.** `ck_dq_finding_` + `tenant`, `dimension`, `severity`, `status`, `class`, `mode`, `fingerprint`, `key_hash`, `value_hash`, `no_raw`, `seen`, `resolved`, `reason`, `remediation`, `waived`.

**Chỉ mục.** `ix_dq_finding_asset`, `ix_dq_finding_rule`, `ix_dq_finding_open`, `ix_dq_finding_fp`, `ix_dq_finding_key`, `ix_dq_finding_issue`, `ix_dq_finding_owner`, `ix_dq_finding_scan`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Phân vùng tháng theo `last_seen_at`; Bất biến: `tenant_id`, `asset_id`, `rule_id`, `fingerprint`, `record_key_hash`, `first_seen_at`, `first_scan_job_id`, `data_class` (`tg_dq_finding_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `last_seen_at` | `timestamptz, mặc định now()` | Khóa phân vùng; cập nhật mỗi lần lỗi được thấy lại nên dòng có thể chuyển phân vùng (row movement). |
| `fingerprint` | `bytea` | HMAC-SHA256 (khóa riêng từng tenant) của asset, mã quy tắc, khóa bản ghi; ổn định qua các kỳ (ADR đề xuất dải 085-089). |
| `record_key_hash` | `bytea` | Băm có khóa của khóa bản ghi nguồn; tra theo đối tượng mà không lộ khóa. |
| `data_class` | `varchar(16), mặc định 'INTERNAL'` | Giá trị: `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE`. |
| `value_mode` | `varchar(16), mặc định 'MASKED'` | Giá trị: `MASKED`, `HASH_ONLY`, `PLAIN`. |
| `masked_value` | `varchar(255), NULL` | Giá trị đã che theo chính sách PH-09, tối đa 255 ký tự; luôn rỗng với trường SENSITIVE. Không bao giờ chứa giá trị gốc. |
| `value_hash` | `bytea, NULL` | Băm có khóa của giá trị gốc để biết giá trị có đổi giữa hai kỳ mà không lưu bản rõ. |
| `status` | `varchar(16), mặc định 'OPEN'` | Giá trị: `OPEN`, `IN_REMEDIATION`, `RESOLVED`, `WAIVED`. |
| `resolution_reason` | `varchar(16), NULL` | Giá trị: `CLEARED`, `RECORD_REMOVED`, `RULE_RETIRED`, `MANUAL_CONFIRMED`. |

: Cột nổi bật của bảng `dq_finding`

Cột khác: `asset_id` uuid; `rule_id` uuid; `dimension` v(16); `severity` v(8); `record_key_masked` v(255); `field_name` v(63); `expected_hint` v(255); `owner_org_code` v(63); `first_seen_at` tstz; `first_scan_job_id` uuid; `last_scan_job_id` uuid; `seen_count` int; `resolved_at` tstz; `resolved_scan_job_id` uuid; `issue_id` uuid; `waiver_id` uuid.

### 3.21. `dq_waiver`

::: dac-ta
**Mục đích.** EN-08-18 Ngoại lệ chấp nhận (waiver): cho phép bỏ qua một lỗi hoặc một quy tắc có thời hạn, DA duyệt, lý do tối thiểu 20 ký tự (FR-08-040). Hết hạn thì lỗi mở lại.

**FR phục vụ.** FR-08-040; EN-08-18.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_waiver_tid` (tenant_id, id).

**Khóa ngoại.** (tenant_id, asset_id) → `dq_asset`, (tenant_id, rule_id) → `dq_rule`.

**Ràng buộc CHECK.** `ck_dq_waiver_` + `tenant`, `status`, `reason`, `fingerprint`, `scope`, `four_eyes`, `period`, `active`, `reject`, `revoke`.

**Chỉ mục.** `ix_dq_waiver_asset`, `ix_dq_waiver_expiry`, `ix_dq_waiver_fp`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `asset_id`, `rule_id`, `fingerprint`, `reason`, `requested_by`, `scope` (`tg_dq_waiver_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(20), mặc định 'PENDING_APPROVAL'` | Giá trị: `PENDING_APPROVAL`, `ACTIVE`, `EXPIRED`, `REVOKED`, `REJECTED`. |
| `valid_to` | `date, NULL` | Tối đa 366 ngày sau valid_from; thời hạn tối đa theo tham số 08.waiver.max-days kiểm ở dịch vụ. |
| `scope` | `varchar(12), mặc định 'FINDINGS'` | FINDINGS: nhóm dấu vân tay (một dấu ở cột fingerprint, nhiều dấu ở dq_waiver_item); RULE_FILTER: một quy tắc kèm điều kiện lọc CEL ở filter (FR-08-040). Giá trị: `FINDINGS`, `RULE_FILTER`. |

: Cột nổi bật của bảng `dq_waiver`

Cột khác: `asset_id` uuid; `rule_id` uuid; `fingerprint` bytea; `reason` v(2000); `requested_by` v(64); `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `valid_from` date; `revoked_by` v(64); `revoked_at` tstz; `revoke_reason` v(2000); `expired_at` tstz; `filter` jsonb.

### 3.22. `dq_waiver_item`

::: dac-ta
**Mục đích.** EN-08-33 Dấu vân tay thuộc một ngoại lệ phạm vi FINDINGS (tối đa 100.000 mỗi ngoại lệ, FR-08-040). Không sửa sau khi tạo.

**FR phục vụ.** FR-08-040; EN-08-33.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_waiver_item` (tenant_id, waiver_id, fingerprint).

**Khóa ngoại.** (tenant_id, waiver_id) → `dq_waiver`.

**Ràng buộc CHECK.** `ck_dq_waiver_item_` + `tenant`, `fingerprint`.

**Chỉ mục.** `ix_dq_waiver_item_fp`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `waiver_id`, `fingerprint` (`tg_dq_waiver_item_immutable`).

**Ghi chú.** ETag là `version`.
:::

Cột khác: `waiver_id` uuid; `fingerprint` bytea.

### 3.23. `dq_issue`

::: dac-ta
**Mục đích.** EN-08-19 Phiếu khắc phục: nhóm lỗi của một đối tượng và quy tắc giao cho tổ chức chủ quản, hạn xử lý theo mức nghiêm trọng (CRITICAL 5 ngày làm việc, MAJOR 15, MINOR 30, giả định), vòng đời OPEN đến VERIFIED (FR-08-041…046). PH-08 không sửa dữ liệu nguồn; lỗi bản ghi vàng chuyển sang hàng đợi steward PH-06.

**FR phục vụ.** FR-08-041, 042, 043, 044, 045, 046, 050; EN-08-19.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_issue_tid` (tenant_id, id), `uq_dq_issue_code` (tenant_id, issue_code), `uq_dq_issue_open_group` (tenant_id, group_key) có điều kiện.

**Khóa ngoại.** (tenant_id, asset_id) → `dq_asset`, (tenant_id, rule_id) → `dq_rule`, (tenant_id, verify_scan_job_id) → `dq_scan_job`.

**Ràng buộc CHECK.** `ck_dq_issue_` + `tenant`, `code`, `severity`, `status`, `sla`, `assigned`, `fixed`, `verified`, `reject`, `reject_type`, `cancel`, `count`.

**Chỉ mục.** `ix_dq_issue_inbox`, `ix_dq_issue_assignee`, `ix_dq_issue_sla`, `ix_dq_issue_asset`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `issue_code`, `asset_id`, `rule_id`, `group_key`, `severity`, `owner_org_code` (`tg_dq_issue_immutable`).

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `group_key` | `varchar(160)` | asset_code \| rule_code \| owner_org_code; mỗi nhóm một phiếu đang mở (chỉ mục duy nhất một phần). |
| `status` | `varchar(12), mặc định 'OPEN'` | Giá trị: `OPEN`, `ASSIGNED`, `IN_PROGRESS`, `FIXED`, `VERIFIED`, `REOPENED`, `REJECTED`, `CANCELLED`. |
| `verify_scan_job_id` | `uuid, NULL` | Lần đo lại kiểm chứng (trigger VERIFY); phiếu VERIFIED bắt buộc có (FR-08-044). |
| `reject_type` | `varchar(16), NULL` | Lý do từ chối của DO: sai chủ quản, không phải lỗi, không sửa được (FR-08-045). Giá trị: `WRONG_OWNER`, `NOT_A_DEFECT`, `CANNOT_FIX`. |
| `steward_item_ref` | `uuid, NULL` | Mã mục hàng đợi steward PH-06 khi lỗi ở bản ghi vàng (FR-08-046); kiểm ở dịch vụ, không khóa ngoại. |

: Cột nổi bật của bảng `dq_issue`

Cột khác: `issue_code` v(24); `asset_id` uuid; `rule_id` uuid; `title` v(255); `description` v(4000); `severity` v(8); `finding_count` int; `owner_org_code` v(63); `assignee` v(64); `sla_days` smallint; `sla_due_at` tstz; `escalation_level` smallint; `escalated_at` tstz; `assigned_at` tstz; `fixed_at` tstz; `fix_note` v(2000); `verified_at` tstz; `reopen_count` smallint; `reject_reason` v(2000); `forwarded_to_steward_at` tstz; `cancel_reason` v(2000).

### 3.24. `dq_issue_activity`

::: dac-ta
**Mục đích.** EN-08-20 Hoạt động trên phiếu khắc phục: tạo, phân công, bình luận, đổi trạng thái, leo thang, chuyển steward, xác nhận (FR-08-043, 045). Chỉ thêm, không sửa, không xóa.

**FR phục vụ.** FR-08-043, 045, 046, 060; EN-08-20.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, issue_id) → `dq_issue`.

**Ràng buộc CHECK.** `ck_dq_issue_activity_` + `tenant`, `type`, `status`, `change`.

**Chỉ mục.** `ix_dq_issue_activity_issue`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Trigger: `tg_dq_issue_activity_append_only`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `activity_type` | `varchar(24)` | Giá trị: `COMMENT`, `ATTACHMENT`, `STATUS_CHANGE`, `ASSIGNMENT`, `ESCALATION`, `VERIFY_RESULT`, `CREATED`, `TRANSFER`, `STEWARD_FORWARD`. |

: Cột nổi bật của bảng `dq_issue_activity`

Cột khác: `issue_id` uuid; `actor` v(64); `from_status` v(12); `to_status` v(12); `comment` v(4000); `payload` jsonb; `occurred_at` tstz.

### 3.25. `dq_alert_rule`

::: dac-ta
**Mục đích.** EN-08-21 Quy tắc cảnh báo: điều kiện điểm thấp, điểm giảm, lần đo thất bại, thiếu chiều, phiếu quá hạn, tỷ lệ lỗi trực tuyến, lỗi CRITICAL mới; kênh gửi qua PH-13 (FR-08-047, 048).

**FR phục vụ.** FR-08-047, 048; EN-08-21.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_alert_rule_tid` (tenant_id, id), `uq_dq_alert_rule_code` (tenant_id, alert_rule_code).

**Khóa ngoại.** (tenant_id, asset_id) → `dq_asset`, (tenant_id, domain_code) → `dq_domain`.

**Ràng buộc CHECK.** `ck_dq_alert_rule_` + `tenant`, `code`, `scope`, `condition`, `dimension`, `severity`, `threshold`, `cooldown`.

**Chỉ mục.** `ix_dq_alert_rule_scope`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `condition_type` | `varchar(24)` | Giá trị: `SCORE_BELOW`, `SCORE_DROP`, `SCAN_FAILED`, `INCOMPLETE_DIMENSIONS`, `ISSUE_OVERDUE`, `INLINE_FAIL_RATE`, `NEW_CRITICAL_FINDINGS`. |

: Cột nổi bật của bảng `dq_alert_rule`

Cột khác: `alert_rule_code` v(63); `name` v(255); `domain_code` v(32); `asset_id` uuid; `dimension` v(16); `threshold` num(8,3); `severity` v(8); `channels` jsonb; `recipients` jsonb; `cooldown_minutes` int; `enabled` bool.

### 3.26. `dq_alert`

::: dac-ta
**Mục đích.** EN-08-22 Cảnh báo đã phát: trạng thái FIRING, ACKNOWLEDGED, RESOLVED, SILENCED, khóa chống trùng, tham chiếu thông báo PH-13 (FR-08-048, 049).

**FR phục vụ.** FR-08-048, 049, 050; EN-08-22.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_alert_tid` (tenant_id, id), `uq_dq_alert_open` (tenant_id, dedup_key) có điều kiện, `uq_dq_alert_unresolved` (tenant_id, alert_rule_id, COALESCE(asset_id, '00000000-0000-0000-0000-000000000000'::uuid)) có điều kiện.

**Khóa ngoại.** (tenant_id, alert_rule_id) → `dq_alert_rule`, (tenant_id, asset_id) → `dq_asset`.

**Ràng buộc CHECK.** `ck_dq_alert_` + `tenant`, `severity`, `status`, `ack`, `silence`, `resolved`.

**Chỉ mục.** `ix_dq_alert_status`, `ix_dq_alert_asset`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(14), mặc định 'FIRING'` | Giá trị: `FIRING`, `ACKNOWLEDGED`, `RESOLVED`, `SILENCED`. |

: Cột nổi bật của bảng `dq_alert`

Cột khác: `alert_rule_id` uuid; `asset_id` uuid; `scan_job_id` uuid; `snapshot_id` uuid; `severity` v(8); `dedup_key` v(160); `message` v(1000); `fired_at` tstz; `notified_at` tstz; `notification_ref` v(64); `acknowledged_by` v(64); `acknowledged_at` tstz; `silenced_until` tstz; `silence_reason` v(500); `resolved_at` tstz.

### 3.27. `dq_report`

::: dac-ta
**Mục đích.** EN-08-23 Báo cáo chất lượng: kỳ (tháng), chính thức hằng năm, theo yêu cầu; soạn, duyệt bốn mắt, công bố; tệp PDF, XLSX trên Ceph RGW kèm SHA-256, ký số tùy chọn (FR-08-052…056). Báo cáo ANNUAL không được dựa trên snapshot thiếu chiều. Đã công bố thì bất biến.

**FR phục vụ.** FR-08-052, 053, 054, 055, 056; EN-08-23.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_report_tid` (tenant_id, id), `uq_dq_report_code` (tenant_id, report_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_dq_report_` + `tenant`, `code`, `type`, `status`, `period`, `hash`, `annual_full`, `four_eyes`, `publisher`, `published`, `withdrawn`, `signed`, `counts`.

**Chỉ mục.** `ix_dq_report_period`, `ix_dq_report_published`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `report_code`, `report_type`, `period_code` (`tg_dq_report_immutable`); Trigger: `tg_dq_report_frozen`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `report_type` | `varchar(10)` | Giá trị: `PERIODIC`, `ANNUAL`, `AD_HOC`. |
| `status` | `varchar(10), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `IN_REVIEW`, `PUBLISHED`, `WITHDRAWN`. |
| `summary` | `jsonb, mặc định '{}'` | Số liệu tổng hợp (điểm theo miền, theo tổ chức, xu hướng); không chứa giá trị bản ghi. |
| `pdf_object_key` | `varchar(512), NULL` | Khóa đối tượng trên Ceph RGW, bucket dq-reports; không lưu tệp trong PostgreSQL. |

: Cột nổi bật của bảng `dq_report`

Cột khác: `report_code` v(24); `period_code` v(7); `title` v(255); `scope` jsonb; `snapshot_count` int; `incomplete_snapshot_count` int; `generated_at` tstz; `submitted_by` v(64); `submitted_at` tstz; `reviewed_by` v(64); `reviewed_at` tstz; `review_comment` v(2000); `published_by` v(64); `published_at` tstz; `withdrawn_reason` v(2000); `xlsx_object_key` v(512); `content_sha256` bytea; `signed` bool; `signature_ref` v(255).

### 3.28. `dq_report_subscription`

::: dac-ta
**Mục đích.** EN-08-24 Đăng ký nhận báo cáo: người dùng, vai trò hoặc tổ chức nhận báo cáo công bố qua PH-13 (FR-08-056).

**FR phục vụ.** FR-08-056; EN-08-24.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_report_subscription` (tenant_id, report_type, COALESCE(domain_code, ''), recipient_type, recipient_ref, format).

**Khóa ngoại.** (tenant_id, domain_code) → `dq_domain`.

**Ràng buộc CHECK.** `ck_dq_report_subscription_` + `tenant`, `type`, `recipient`, `format`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `report_type` | `varchar(10)` | Giá trị: `PERIODIC`, `ANNUAL`, `AD_HOC`. |
| `recipient_type` | `varchar(8)` | Giá trị: `USER`, `ROLE`, `ORG`. |
| `format` | `varchar(4), mặc định 'PDF'` | Giá trị: `PDF`, `XLSX`. |

: Cột nổi bật của bảng `dq_report_subscription`

Cột khác: `domain_code` v(32); `recipient_ref` v(128); `enabled` bool.

### 3.29. `dq_export_request`

::: dac-ta
**Mục đích.** EN-08-29 Yêu cầu xuất bản ghi lỗi ra CSV hoặc XLSX trên Ceph RGW; khi có trường Nhạy cảm hoặc Hạn chế cần DO chấp thuận khác người yêu cầu (FR-08-039). Tệp có hạn tải và thủy vân.

**FR phục vụ.** FR-08-039; EN-08-29.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_export_request_tid` (tenant_id, id).

**Khóa ngoại.** (tenant_id, asset_id) → `dq_asset`, (tenant_id, report_code) → `dq_report`.

**Ràng buộc CHECK.** `ck_dq_export_request_` + `tenant`, `format`, `kind`, `status`, `four_eyes`, `approval`, `ready`, `hash`, `error`.

**Chỉ mục.** `ix_dq_export_request_status`, `ix_dq_export_request_expiry`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `kind` | `varchar(10), mặc định 'FINDINGS'` | FINDINGS: xuất bản ghi lỗi (FR-08-039, cần DO chấp thuận khi có trường Hạn chế, Nhạy cảm); REPORT: xuất báo cáo PDF, XLSX (FR-08-055, API-08-116). Giá trị: `FINDINGS`, `REPORT`. |
| `format` | `varchar(4), mặc định 'CSV'` | Giá trị: `CSV`, `XLSX`, `PDF`. |
| `status` | `varchar(20), mặc định 'PENDING_APPROVAL'` | Giá trị: `PENDING_APPROVAL`, `APPROVED`, `RUNNING`, `READY`, `FAILED`, `EXPIRED`, `REJECTED`. |

: Cột nổi bật của bảng `dq_export_request`

Cột khác: `report_code` v(24); `asset_id` uuid; `filter` jsonb; `contains_restricted` bool; `requested_by` v(64); `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `row_count` bigint; `object_key` v(512); `content_sha256` bytea; `watermark_id` v(64); `expires_at` tstz; `download_count` int; `error_code` v(16).

### 3.30. `dq_tenant_setting`

::: dac-ta
**Mục đích.** EN-08-26 Tham số chất lượng theo tenant: 43 khóa 08.* của FRS mục 8.2 (lịch đo, cửa sổ, mẫu, kích thước tác vụ, thời gian chờ, hạn SLA, hạn ngoại lệ, chế độ kiểm tra trực tuyến) (FR-08-058). Chỉ nhận các khóa đã khai báo; ngưỡng điểm và trọng số nằm ở dq_weight_config.

**FR phục vụ.** FR-08-058; EN-08-26.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_tenant_setting_key` (tenant_id, setting_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_dq_tenant_setting_` + `tenant`, `key`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `setting_key` | `varchar(64)` | Giá trị: . |

: Cột nổi bật của bảng `dq_tenant_setting`

Cột khác: `value` jsonb; `description` v(500).

### 3.31. `dq_retention_policy`

::: dac-ta
**Mục đích.** EN-08-30 Chính sách lưu giữ và dọn dữ liệu đo theo loại đối tượng: số ngày giữ và hành động (xóa phân vùng, xóa dòng, lưu lạnh) (FR-08-059). Bản ghi lỗi giữ mặc định 13 tháng (395 ngày), có thể đổi theo tenant.

**FR phục vụ.** FR-08-059; EN-08-30.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_retention_policy` (tenant_id, object_type).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_dq_retention_policy_` + `tenant`, `object`, `action`, `days`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `object_type` | `varchar(40)` | Giá trị: . |
| `action` | `varchar(16)` | Giá trị: `DROP_PARTITION`, `DELETE`, `ARCHIVE_COLD`, `ANONYMIZE`. |

: Cột nổi bật của bảng `dq_retention_policy`

Cột khác: `retention_days` int.

### 3.32. `dq_retention_run`

::: dac-ta
**Mục đích.** EN-08-30 Lịch sử chạy dọn dữ liệu đo theo chính sách lưu giữ: loại dữ liệu, hành động, số dòng và phân vùng đã dọn, chạy xem trước hay chạy thật (FR-08-059, API-08-125, 126).

**FR phục vụ.** FR-08-059; EN-08-30.

**Khóa chính.** (id).

**Duy nhất.** `uq_dq_retention_run_tid` (tenant_id, id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_dq_retention_run_` + `tenant`, `object`, `action`, `status`, `done`, `counts`, `error`.

**Chỉ mục.** `ix_dq_retention_run_started`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `object_type` | `varchar(40)` | Giá trị: . |
| `action` | `varchar(16)` | Giá trị: `DROP_PARTITION`, `DELETE`, `ARCHIVE_COLD`, `ANONYMIZE`. |
| `status` | `varchar(10), mặc định 'RUNNING'` | Giá trị: `RUNNING`, `SUCCEEDED`, `FAILED`. |

: Cột nổi bật của bảng `dq_retention_run`

Cột khác: `dry_run` bool; `requested_by` v(64); `cutoff_at` tstz; `started_at` tstz; `finished_at` tstz; `rows_affected` bigint; `partitions_dropped` int; `error_code` v(16); `error_message` v(2000).

### 3.33. `outbox_event`

::: dac-ta
**Mục đích.** EN-08-27 Outbox (SAD 7.3) cho EVT-08-01…14 và bản ghi kiểm toán gửi PH-13 (FR-08-057, 060). Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL và định tuyến theo topic. Sự kiện không chứa giá trị bản ghi lỗi: CHECK chặn các khóa value, maskedValue, record. Dọn sau 3 ngày.

**FR phục vụ.** FR-08-057, 060; EN-08-27.

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_event_` + `tenant`, `prefix`, `topic`, `trace`, `no_value`.

**Chỉ mục.** `ix_outbox_event_occurred`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** Debezium Outbox Event Router đọc WAL và phát lên Kafka; ghi cùng giao dịch với thay đổi (SAD 7.3).
:::

Cột khác: `tenant_id` v(16); `event_id` uuid; `topic` v(128); `aggregate_type` v(32); `aggregate_id` uuid; `payload` jsonb; `trace_id` char(32); `occurred_at` tstz; `published_at` tstz.

### 3.34. `inbox_event`

::: dac-ta
**Mục đích.** EN-08-28 Khử trùng sự kiện nhận: EVT-06-01, 02, 03, 04, 10 của PH-06 và sự kiện phát hành danh mục của PH-07, tiêu thụ lũy đẳng theo event_id (FR-08-025). Dọn sau 30 ngày.

**FR phục vụ.** FR-08-025; EN-08-28.

**Khóa chính.** (tenant_id, consumer, event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_inbox_event_` + `tenant`, `consumer`, `prefix`.

**Chỉ mục.** `ix_inbox_event_received`.

**Cách ly tenant.** RLS FORCE, mẫu P: chỉ thấy và ghi dòng của tenant phiên.

**Phân vùng, bất biến.** Không.

**Ghi chú.** Khử trùng sự kiện nhận từ phân hệ khác theo `event_id` (tiêu thụ lũy đẳng).
:::

Cột khác: `tenant_id` v(16); `consumer` v(64); `event_id` uuid; `source_topic` v(128); `received_at` tstz; `processed_at` tstz.

### 3.35. `shedlock`

::: dac-ta
**Mục đích.** Bảng kỹ thuật của thư viện ShedLock cho các job Quartz (lập lịch đo, dọn, duy trì phân vùng); không chứa dữ liệu nghiệp vụ.

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

## 4. DDL và changelog Liquibase

### 4.1. Tệp

[`ph08/ddl/ph08_dq.sql`](ph08/ddl/ph08_dq.sql) là nguồn duy nhất, chia changeset bằng `-- @file`, `-- @changeset`, `-- @rollback` như PH-04…07, 10. Changelog [`ph08/liquibase/db.changelog-ph08.yaml`](ph08/liquibase/db.changelog-ph08.yaml) và 11 tệp `ph08/liquibase/changes/*.sql` (formatted SQL, tác giả `ph08`) sinh bằng [`gen_liquibase.py`](ph08/tools/gen_liquibase.py), không sửa tay.

| Tệp | Nội dung |
|---|---|
| `08-0000-bootstrap.sql` | Vai trò `ph08_owner`, `ph08_app`, `ph08_readonly`, `ph08_benchmark`, `dq_reader`; schema; biến phiên |
| `08-0001-functions.sql` | `tg_touch`, `tg_immutable`, `tg_append_only`, `tg_frozen`, `tg_child_frozen`, `p_enable_rls`, `p_enable_rls_shared`, `p_ensure_partitions` |
| `08-0010-asset.sql` | `dq_domain`, `dq_asset`, `dq_asset_field`, `dq_profile_run`, `dq_profile_column` |
| `08-0020-rule.sql` | `dq_rule_template`, `dq_weight_config`, `dq_rule_set`, `dq_rule_set_version`, `dq_rule` |
| `08-0030-scan.sql` | `dq_schedule`, `dq_scan_job`, `dq_scan_task`, `dq_rule_result`, `dq_score_snapshot`, `dq_score_dimension`, `dq_incremental_buffer`, `dq_score_current`, `dq_inline_stat` |
| `08-0040-finding.sql` | `dq_finding`, `dq_waiver`, `dq_waiver_item` |
| `08-0050-issue.sql` | `dq_issue`, `dq_issue_activity` |
| `08-0060-alert-report.sql` | `dq_alert_rule`, `dq_alert`, `dq_report`, `dq_report_subscription` |
| `08-0070-ops.sql` | `dq_export_request`, `dq_tenant_setting`, `dq_retention_policy`, `dq_retention_run`, `outbox_event`, `inbox_event`, `shedlock` |
| `08-0090-seed.sql` | `p_seed_tenant`, `p_seed_common`; nạp 12 quy tắc mẫu `COMMON` |
| `08-0900-grants.sql` | Quyền theo vai trò, `runAlways`; chính sách và khung nhìn so sánh liên tenant |

: Tệp DDL và changelog Liquibase của PH-08

Không có changeset di trú dữ liệu: hệ cũ không có chức năng chất lượng dữ liệu và repo chưa có bảng PH-08 nào chạy (mục 8.3).

### 4.2. Kết quả chạy thử

Chạy ngày 26/11/2026 trên PostgreSQL 16.15 (Ubuntu 24.04) cài sạch, dữ liệu giả, tenant kiểm thử T90, T91:

- DDL chạy không lỗi trên CSDL trống với `ON_ERROR_STOP`: 35 bảng gốc, 9 phân vùng tháng đầu (3 bảng × 3 tháng), 250 `CHECK`, 45 khóa ngoại, 42 ràng buộc `UNIQUE`, 51 trigger, 138 chính sách RLS (34 bảng × 4 cộng 2 chính sách của vai so sánh), 64 chỉ mục ngoài khóa chính và `UNIQUE`.
- Ghép 11 tệp changelog sinh ra rồi chạy bằng psql theo thứ tự trên CSDL trống khác (tệp bootstrap bằng tài khoản quản trị, các tệp còn lại với vai `ph08_owner`): cùng số bảng và cùng 211 khối PASS. Chưa chạy bằng Liquibase CLI (không có trong máy); CI chạy `liquibase update` trên Testcontainers.
- [`ph08_isolation_test.sql`](ph08/test/ph08_isolation_test.sql) dưới `dh_data_app` (nhóm 9 dưới `dh_report_ro`, nhóm 10 dưới `ph08_owner`, vai so sánh ở nhóm 8b) đạt 211 khối PASS, chia mười hai nhóm: khởi tạo tenant bằng thủ tục (43 tham số, 12 chính sách lưu giữ, chạy lại không nhân bản); cô lập tenant (T91 không đọc, không sửa, không ghi dòng của T90 kể cả phân vùng; khóa ngoại không vượt tenant; quên đặt `app.tenant_id` thì không thấy dòng nào); mẫu RLS S của `COMMON`; enum và ràng buộc nghiệp vụ; bất biến phiên bản, trọng số, snapshot, báo cáo; một lần đo đang chạy, một phiếu mở mỗi nhóm; không lưu giá trị gốc trường Nhạy cảm; chuyển phân vùng của `dq_finding`; bảng chỉ thêm; outbox và inbox; quyền vai trò kể cả cột bị thu hồi; chủ schema vẫn chịu RLS; nhóm 8b của bản 0.2 (cấu hình trực tuyến và đo tăng dần của đối tượng, dấu chạy thử, `Idempotency-Key` kèm băm, heartbeat tác vụ, bộ đệm gom khóa, điểm hiện hành, mục ngoại lệ, xuất báo cáo, lịch sử dọn, vai so sánh liên tenant).
- Kế hoạch thực thi năm truy vấn chính trên 300.000 dòng `dq_finding` (đo ở bản 0.1, DDL các bảng này không đổi): tra theo dấu vân tay, theo đối tượng và trạng thái, theo khóa bản ghi và điểm theo kỳ đều dùng đúng chỉ mục (Index Scan); hộp lỗi mở theo mức nghiêm trọng quét tuần tự song song vì chọn khoảng một phần ba bảng.

Bài kiểm `TenantIsolationIT` (D03-02-PH08) tự động hóa các khối này trong CI bằng Testcontainers PostgreSQL 16.

### 4.3. Đối chiếu với FRS phụ lục A

Bản 0.2 đối chiếu từng enum với Phụ lục A của FRS 0.2; mọi giá trị `CHECK` dạng chữ hoa nằm ở một từ điển duy nhất trong `sinh_ddl.py`. Chỗ bản 0.1 lệch FRS đã sửa theo FRS: `dq_domain.status` là `ACTIVE`, `INACTIVE` (trước là `DRAFT…RETIRED`); `dq_rule_set_version.status` thêm `APPROVED` kèm cột `effective_from`; `dq_weight_config.status` giữ `RETIRED` (FRS thêm); điều kiện cảnh báo dùng bảy giá trị `alert.condition`; loại hoạt động phiếu dùng chín giá trị (sáu của FRS cộng `CREATED`, `TRANSFER`, `STEWARD_FORWARD`); cờ ảnh chụp và lần đo thêm `TRUNCATED`, `INCREMENTAL`; `dq_profile_run.scan_mode` thêm `EXTERNAL`; mã báo cáo theo `BC-DQ-yyyy-kỳ-Ttt`; ngưỡng mặc định 80 và 70; 43 khóa tham số của FRS 8.2. Tên `value_mode` (`MASKED`, `HASH_ONLY`, `PLAIN`) được FRS nhận thay `masking_mode`.

## 5. Dữ liệu khởi tạo

Hai thủ tục khởi tạo, chạy lại không nhân bản.

- `ph08_dq.p_seed_common()` nạp 12 quy tắc mẫu vào tenant `COMMON` dưới phiên `PLATFORM` (changeset `ph08-0930`): số CCCD 12 chữ số, mã số thuế (định dạng và chữ số kiểm tra), số điện thoại, email, mã đơn vị hành chính có trong danh mục PH-07, CDE không rỗng, chuỗi không rỗng, khóa không trùng, độ tươi 30 ngày, ngày sinh hợp lệ, thứ tự ngày (CEL).
- `ph08_dq.p_seed_tenant('Tnn')` do PH-20 gọi khi khởi tạo tenant: 43 tham số `08.*` đúng bảng 8.2 của FRS (lịch đo mặc định `0 0 2 1 * ?`, cửa sổ 22:00-05:00, tác vụ 200.000 bản ghi, heartbeat 180 giây, SLA 5, 15, 30 ngày, hạn ngoại lệ 180 ngày, ngân sách trực tuyến 40 ms, chế độ mặc định ADVISORY, FAIL_OPEN), 12 chính sách lưu giữ (mục 7), cấu hình trọng số `DEFAULT` đã ACTIVE (0,20/0,20/0,15/0,10/0,15/0,20, ngưỡng 80 và 70) và lịch đo `MONTHLY-ALL` cho cả tenant.

Miền, đối tượng đo và bộ quy tắc của tenant do người dùng khai báo qua FR-08-001…022, không seed.

## 6. Kho lưu trữ ngoài PostgreSQL

### 6.1. OpenBao

Hai khóa theo tenant: `dh-{tenant}-dq-hmac` (HMAC-SHA256 cho `fingerprint`, `record_key_hash`, `value_hash`) và `dh-{tenant}-dq-sign` (ký số báo cáo tùy chọn, FR-08-055). Khóa không nằm ở CSDL hay tệp cấu hình. OpenBao ngừng thì lần đo vẫn chạy nhưng không ghi được bản ghi lỗi mới (không có băm), lần đo chuyển PARTIAL; xem Q08-51 về quay khóa.

### 6.2. Valkey

Valkey là bộ đệm tầng hai, mọi khóa có hash tag tenant để các khóa của một tenant nằm cùng slot; mất toàn bộ Valkey chỉ làm tăng tải đọc PostgreSQL và PH-07, không mất dữ liệu.

| Khóa | Giá trị | Thời gian sống |
|---|---|---|
| `{t68}:dq:rules:{assetCode}` | Bộ quy tắc ACTIVE dạng biên dịch sẵn cho kiểm tra trực tuyến: `ruleSetVersionId`, `contentHash`, quy tắc `INLINE` và `BOTH` (CEL, tham số, `inline_mode`), `on_dependency_failure` của miền | 60 giây (`08.inline.cache-ttl-seconds`), xóa ngay khi nhận EVT-08-01 |
| `{t68}:dq:rdm:{catalogCode}:{versionId}` | Tập mã hợp lệ của danh mục PH-07 để kiểm `IN_RDM` trực tuyến (nén; danh mục lớn dùng Bloom filter) | 300 giây, xóa khi nhận sự kiện phát hành danh mục PH-07 |
| `{t68}:dq:agg:{assetId}:{caller}:{yyyyMMddHHmm}` | Bộ đếm gộp theo phút (lượt, đạt, lỗi, độ trễ) trước khi ghi `dq_inline_stat` | 10 phút |
| `{t68}:dq:cb:{dependency}` | Trạng thái cầu dao của PH-07, PH-05 để chọn FAIL_OPEN hoặc FAIL_CLOSED | 30 giây |
| `{t68}:dq:idem:{chủ thể}:{khóa}` | `Idempotency-Key` của API ghi | 24 giờ |
| `{t68}:dq:scan:{assetId}` | Khóa mềm một lần đo mỗi đối tượng, bổ sung cho chỉ mục `uq_dq_scan_job_running` | Theo hạn lần đo |
| `{t68}:dq:cool:{dedupKey}` | Cooldown cảnh báo | Theo `cooldown_minutes` |

: Khóa Valkey của PH-08

Kiểm tra trực tuyến (p95 không quá 50 ms) không bao giờ đọc PostgreSQL trên đường nóng: khi hụt bộ đệm quy tắc thì nạp từ `dq_rule` theo `uq_dq_rule_set_version_active` rồi ghi lại; nếu vượt hạn chờ thì áp `on_dependency_failure` của miền.

### 6.3. Kafka

Mười bốn topic phát `{tenant}.dq.*.v1` của EVT-08-01…14 do Debezium Outbox Event Router đọc từ `outbox_event`; khóa phân vùng là mã đối tượng hoặc mã phiếu. Sự kiện không chứa giá trị bản ghi lỗi (CHECK `ck_outbox_event_no_value`): bản ghi lỗi chỉ có số lượng và liên kết tra cứu. Tiêu thụ: EVT-06-01, 02, 03, 04 (bản ghi vàng đổi, kích hoạt đo tăng dần), EVT-06-10 (`{tenant}.mdm.model.activated.v1`, mô hình domain đổi) và `{tenant}.rdm.catalog.published.v1` của PH-07 (vô hiệu bộ đệm mã, kích hoạt đo lại danh mục), khử trùng bằng `inbox_event`.

| Topic | Sự kiện | Ghi chú |
|---|---|---|
| `t68.dq.ruleset.activated.v1` | EVT-08-01 | Vô hiệu bộ đệm quy tắc |
| `t68.dq.scan.completed.v1`, `scan.failed.v1` | EVT-08-02, 03 | Mỗi lần đo |
| `t68.dq.score.degraded.v1`, `score.threshold-breached.v1` | EVT-08-04, 05 | Điểm giảm hoặc vượt ngưỡng |
| `t68.dq.finding.opened.v1` | EVT-08-06 | Tổng hợp theo lần đo |
| `t68.dq.issue.created.v1`, `issue.status-changed.v1`, `issue.verified.v1` | EVT-08-07, 08, 09 | Vòng khắc phục |
| `t68.dq.waiver.approved.v1`, `report.published.v1`, `alert.fired.v1` | EVT-08-10, 11, 12 | Ngoại lệ, báo cáo, cảnh báo |
| `t68.dq.check.failed.v1` | EVT-08-13 | Tổng hợp theo phút |
| `t68.dq.kpi.published.v1` | EVT-08-14 | Cho PH-16 |

: Topic Kafka phát của PH-08

### 6.4. Ceph RGW

Bucket `dq-reports` giữ báo cáo PDF, XLSX (`dq_report.pdf_object_key`, `xlsx_object_key`, kèm SHA-256 ở `content_sha256`, bản ký số nếu bật); bucket `dq-exports` giữ tệp xuất lỗi CSV, XLSX (`dq_export_request.object_key`, thủy vân, hạn tải 24 giờ, xóa theo `expires_at`); bucket `dq-archive` giữ phân vùng `dq_finding` đã `DETACH` sang Parquet nếu tenant bật lưu lạnh (Q08-50). Mọi bucket mã hóa phía máy chủ; bucket báo cáo chính thức bật khóa đối tượng (Object Lock) để không xóa trong thời hạn lưu giữ.

### 6.5. ClickHouse

Không dùng ClickHouse trong bản này: khối lượng ở mục 1.5 nằm trong khả năng của `pg-core`. Nếu thống kê trực tuyến vượt 50 triệu dòng mỗi tháng thì chuyển `dq_inline_stat` sang ClickHouse (Q08-54).

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

Bảng nêu thời hạn lưu giữ và cách dọn từng nhóm dữ liệu; hai phần sau bàn về mã hóa và khôi phục. Mọi giá trị là mặc định do `p_seed_tenant` seed vào `dq_retention_policy`, tenant đổi được (FR-08-059) nhưng không dưới mức sàn `CHECK`.

| Đối tượng | Lưu giữ mặc định | Cơ chế dọn, sao lưu |
|---|---|---|
| Schema `ph08_dq` | Theo `pg-core`: WAL liên tục, base backup hằng ngày lên Ceph RGW, RPO ≤ 15 phút, RTO ≤ 30 phút (ADR-034) | Diễn tập DR theo D03-09 |
| `dq_finding` | 395 ngày (13 tháng) từ lần thấy cuối | `DROP_PARTITION` hằng tháng; tùy chọn xuất Parquet sang `dq-archive` trước khi `DROP` (Q08-50) |
| `dq_rule_result` | 395 ngày | `DROP_PARTITION` |
| `dq_inline_stat` | 90 ngày | `DROP_PARTITION` |
| `dq_scan_task`, `dq_profile_column` | 90 ngày; 395 ngày | `DELETE` theo lô |
| `dq_score_snapshot`, `dq_score_dimension` | 1.825 ngày (5 năm), sàn 3 năm | `ARCHIVE_COLD` |
| `dq_issue`, `dq_issue_activity` | 1.825 ngày | `ARCHIVE_COLD` |
| `dq_report` | 3.650 ngày (10 năm, khuyến nghị cho báo cáo chính thức), sàn 3 năm | `ARCHIVE_COLD`; tệp có Object Lock |
| `dq_alert`, `dq_export_request` | 395 ngày; 30 ngày | `DELETE` |
| `outbox_event`, `inbox_event` | 3 ngày; 30 ngày | `OutboxCleanupJob`, `InboxCleanupJob` mỗi giờ |
| Cấu hình (`dq_domain`, `dq_asset`, `dq_rule*`, `dq_weight_config`, `dq_waiver`) | Vĩnh viễn, không xóa | `REVOKE DELETE` |
| Kafka, OpenBao, Ceph RGW | Theo D03-09: bản sao 3; snapshot Raft hằng giờ; đối tượng bản sao hai site | |

: Sao lưu, khôi phục, mã hóa và lưu giữ

**Dọn bằng phân vùng.** `PartitionMaintenanceJob` chạy hằng ngày, gọi `p_ensure_partitions` tạo trước ba tháng cho `dq_finding`, `dq_rule_result`, `dq_inline_stat` (nếu thiếu phân vùng đích thì cập nhật `last_seen_at` báo lỗi, nên job phải chạy trước đầu tháng). Dọn bằng `DETACH` rồi `DROP` dưới `ph08_owner`; ứng dụng không có quyền `DELETE` trên ba bảng này.

**Mã hóa.** Kết nối `pg-core` bắt buộc TLS; dữ liệu tĩnh mã hóa mức đĩa (D03-07). Lớp thứ hai: PH-08 không lưu giá trị gốc của trường Nhạy cảm nên không cần cột mã hóa; ba cột băm `fingerprint`, `record_key_hash`, `value_hash` dùng HMAC-SHA256 với khóa riêng từng tenant ở OpenBao, nên bản sao lưu rời cụm không đối chiếu được nếu không có khóa. `masked_value` đã che theo PH-09 và không bao giờ là giá trị gốc. Quét NFR bảo mật tìm giá trị đánh dấu ở CSDL, log, topic, tệp xuất.

**Thứ tự khôi phục.** OpenBao trước, `pg-core` sau. Nếu CSDL cũ hơn Kafka thì bên nhận tra lại điểm theo mã lần đo, không dựa vào nội dung sự kiện. Sau khôi phục, đo lại FULL cho các đối tượng có `last_seen_at` sau thời điểm sao lưu để dựng lại bản ghi lỗi.

## 8. Ánh xạ sang thiết kế mới

### 8.1. Thực thể EN-08 → bảng

Mã EN-08-01…33 theo bảng thực thể ở FRS 0.2 mục 4.2; EN-08-30 gồm hai bảng (chính sách và lịch sử dọn). Chỉ `shedlock` là bảng hạ tầng không mang mã EN. Tên logic của FRS và API khác tên cột ở các điểm sau, API ánh xạ khi phát hành: `isCde` là `cde`; `valueMode` là `value_mode`; `schedule.status` là `enabled`; `degradedCount` là `fail_open_count` cộng `fail_closed_count`; `passThreshold`, `warnThreshold` là `pass_min`, `warn_min`; `content`, `contentHash` của báo cáo là `summary`, `content_sha256`; `containsSensitive` của yêu cầu xuất là `contains_restricted` (cả Hạn chế và Nhạy cảm).

<!-- gen:en:start -->
| Thực thể | Bảng hiện thực |
|---|---|
| EN-08-01 | `dq_domain` |
| EN-08-02 | `dq_asset` |
| EN-08-03 | `dq_asset_field` |
| EN-08-04 | `dq_profile_run` |
| EN-08-05 | `dq_profile_column` |
| EN-08-06 | `dq_rule_set` |
| EN-08-07 | `dq_rule_set_version` |
| EN-08-08 | `dq_rule` |
| EN-08-09 | `dq_rule_template` |
| EN-08-10 | `dq_weight_config` |
| EN-08-11 | `dq_schedule` |
| EN-08-12 | `dq_scan_job` |
| EN-08-13 | `dq_scan_task` |
| EN-08-14 | `dq_rule_result` |
| EN-08-15 | `dq_score_snapshot` |
| EN-08-16 | `dq_score_dimension` |
| EN-08-17 | `dq_finding` |
| EN-08-18 | `dq_waiver` |
| EN-08-19 | `dq_issue` |
| EN-08-20 | `dq_issue_activity` |
| EN-08-21 | `dq_alert_rule` |
| EN-08-22 | `dq_alert` |
| EN-08-23 | `dq_report` |
| EN-08-24 | `dq_report_subscription` |
| EN-08-25 | `dq_inline_stat` |
| EN-08-26 | `dq_tenant_setting` |
| EN-08-27 | `outbox_event` |
| EN-08-28 | `inbox_event` |
| EN-08-29 | `dq_export_request` |
| EN-08-30 | `dq_retention_policy`, `dq_retention_run` |
| EN-08-31 | `dq_incremental_buffer` |
| EN-08-32 | `dq_score_current` |
| EN-08-33 | `dq_waiver_item` |

: Ánh xạ thực thể EN-08 sang bảng

Bảng hạ tầng không mang mã EN: `shedlock`.
<!-- gen:en:end -->

Giá trị enum dùng chung, trùng Phụ lục A: `dimension` (`COMPLETENESS`, `ACCURACY`, `CONSISTENCY`, `TIMELINESS`, `UNIQUENESS`, `VALIDITY`) và `severity` (`CRITICAL`, `MAJOR`, `MINOR`) áp cho `dq_rule`, `dq_rule_template`, `dq_rule_result`, `dq_score_dimension`, `dq_finding`; `operator` có 19 giá trị ở `dq_rule`, `dq_rule_template`.

### 8.2. Chức năng FR-08 → bảng

Mỗi FR trong khung chức năng chuẩn (FRS) trỏ tới ít nhất một bảng; mã FR theo FRS, nhóm A đến J.

<!-- gen:fr:start -->
| Nhóm | FR | Bảng hiện thực |
|---|---|---|
| A | FR-08-001 | `dq_domain` |
| A | FR-08-002 | `dq_asset` |
| A | FR-08-003 | `dq_asset` |
| A | FR-08-004 | `dq_asset` |
| A | FR-08-005 | `dq_asset_field` |
| A | FR-08-006 | `dq_asset`, `dq_asset_field` |
| A | FR-08-007 | `dq_asset` |
| B | FR-08-008 | `dq_profile_run` |
| B | FR-08-009 | `dq_asset_field`, `dq_profile_column` |
| B | FR-08-010 | `dq_profile_column`, `dq_rule`, `dq_rule_template` |
| B | FR-08-011 | `dq_profile_run`, `dq_profile_column` |
| C | FR-08-012 | `dq_rule_set`, `dq_rule_set_version` |
| C | FR-08-013 | `dq_rule` |
| C | FR-08-014 | `dq_rule` |
| C | FR-08-015 | `dq_rule_template` |
| C | FR-08-016 | `dq_rule` |
| C | FR-08-017 | `dq_rule_set_version` |
| C | FR-08-018 | `dq_rule_set`, `dq_rule_set_version` |
| C | FR-08-019 | `dq_rule_set_version`, `dq_rule` |
| C | FR-08-020 | `dq_rule_set`, `dq_rule_set_version`, `dq_rule` |
| C | FR-08-021 | `dq_weight_config` |
| C | FR-08-022 | `dq_rule_set`, `dq_rule` |
| D | FR-08-023 | `dq_schedule`, `dq_scan_job` |
| D | FR-08-024 | `dq_scan_job` |
| D | FR-08-025 | `dq_scan_job`, `dq_incremental_buffer`, `dq_score_current`, `inbox_event` |
| D | FR-08-026 | `dq_scan_job`, `dq_scan_task`, `dq_rule_result` |
| D | FR-08-027 | `dq_rule_result` |
| D | FR-08-028 | `dq_weight_config`, `dq_rule_result`, `dq_score_snapshot`, `dq_score_dimension` |
| D | FR-08-029 | `dq_score_snapshot`, `dq_score_dimension` |
| D | FR-08-030 | `dq_scan_job`, `dq_scan_task` |
| D | FR-08-031 | `dq_scan_job`, `dq_rule_result`, `dq_score_snapshot` |
| E | FR-08-032 | `dq_inline_stat` |
| E | FR-08-033 | `dq_rule`, `dq_inline_stat` |
| E | FR-08-034 | `dq_inline_stat` |
| E | FR-08-035 | `dq_rule`, `dq_inline_stat`, `dq_domain` |
| F | FR-08-036 | `dq_finding` |
| F | FR-08-037 | `dq_finding` |
| F | FR-08-038 | `dq_finding` |
| F | FR-08-039 | `dq_finding`, `dq_export_request` |
| F | FR-08-040 | `dq_waiver`, `dq_waiver_item` |
| G | FR-08-041 | `dq_issue` |
| G | FR-08-042 | `dq_issue` |
| G | FR-08-043 | `dq_issue`, `dq_issue_activity` |
| G | FR-08-044 | `dq_issue` |
| G | FR-08-045 | `dq_issue`, `dq_issue_activity` |
| G | FR-08-046 | `dq_issue`, `dq_issue_activity` |
| H | FR-08-047 | `dq_alert_rule` |
| H | FR-08-048 | `dq_alert_rule`, `dq_alert` |
| H | FR-08-049 | `dq_alert` |
| I | FR-08-050 | `dq_score_current`, `dq_score_snapshot`, `dq_scan_job`, `dq_alert`, `dq_issue` |
| I | FR-08-051 | `dq_score_snapshot`, `dq_score_current` |
| I | FR-08-052 | `dq_report` |
| I | FR-08-053 | `dq_report` |
| I | FR-08-054 | `dq_report` |
| I | FR-08-055 | `dq_report` |
| I | FR-08-056 | `dq_report`, `dq_report_subscription` |
| I | FR-08-057 | `outbox_event`, `dq_score_snapshot` |
| J | FR-08-058 | `dq_tenant_setting` |
| J | FR-08-059 | `dq_retention_policy`, `dq_retention_run` |
| J | FR-08-060 | `outbox_event`, `dq_issue_activity` |
| J | FR-08-061 | `dq_score_snapshot` |

: Ma trận FR-08 sang bảng

<!-- gen:fr:end -->

### 8.3. Hệ cũ Viettel 2021

Hệ cũ không có chức năng chất lượng dữ liệu và không có bảng hay cột nào thuộc PH-08; REQ-08 là năng lực mới theo BRD. Vì vậy không có phép chuyển kiểu cột hay di trú dữ liệu cho D06-01. Truy vết gián tiếp: LGC-DMDC-006, 007, 008 (kiểm tra khi nhập danh mục ở hệ cũ, nay PH-08 đo chất lượng danh mục sau nhập qua đối tượng `RDM_CATALOG`), LGC-BUS-027 (thống kê lỗi theo endpoint, nay ở `dq_inline_stat` cho kiểm tra trực tuyến), LGC-NGSP-003, 005 (dữ liệu BHXH, ĐKKD làm nguồn đối chiếu nhất quán, nay là đối tượng `SOURCE_DATASET` và toán tử `EQ_SOURCE`, `CROSS_ENTITY`).

### 8.4. Mô hình SRS cũ của repo (`docs/07-srs/SRS-PH-08-dq.md` §4)

SRS cũ mô tả sáu thực thể trên giấy, chưa có bảng nào chạy. Bảng dưới ánh xạ từng thực thể và thuộc tính chính sang bảng mới; các khác biệt có chủ ý nằm ở cột cuối.

| SRS cũ | Bảng mới | Khác biệt |
|---|---|---|
| EN-08-01 `dq_domain` (`ma_mien`, `thuc_the_cdm`, `chu_quan_don_vi`, `inline_che_do` OFF, ADVISORY, STRICT) | `dq_domain` + `dq_asset` | `thuc_the_cdm` thành đối tượng đo có bốn loại; chủ quản thành `owner_org_code` (mã PH-01, không phải email); chế độ trực tuyến chuyển xuống từng quy tắc (`dq_rule.inline_mode`, OFF nghĩa là không có quy tắc INLINE); thêm `on_dependency_failure` |
| EN-08-02 `dq_rule_set` / `dq_rule` (`phien_ban`, `truong_dich`, `toan_tu`, `tham_so`, `muc_nghiem_trong`, `thong_diep`, `cho_phep_inline`) | `dq_rule_set` + `dq_rule_set_version` + `dq_rule` | Phiên bản tách thành bảng riêng có duyệt bốn mắt, 5 trạng thái; `truong_dich` thành `field_name` hoặc `expression`; `toan_tu` thành `operator` (19 giá trị); `thong_diep` thành `message`; `cho_phep_inline` thành `exec_mode` |
| EN-08-03 `dq_weight_config` (`nguong_dat`, `nguong_canh_bao`, `hieu_luc_tu`, `nguoi_phe_duyet`) | `dq_weight_config` | `nguong_dat` thành `pass_min`; `nguong_canh_bao` thành `warn_min`; `hieu_luc_tu` thành `activated_at`; `nguoi_phe_duyet` thành `decided_by` kèm bốn mắt và phạm vi tenant, miền hoặc đối tượng |
| EN-08-04 `dq_scan_job` (`che_do` FULL, SAMPLE, RECHECK; `kich_hoat_boi` CRON, MANUAL, REMEDIATION, ANNUAL; `sample_size`, `sample_seed`, `co_incomplete_dimensions`) | `dq_scan_job` + `dq_scan_task` | `RECHECK` thành `scan_trigger = VERIFY` gắn phiếu; `CRON` thành `SCHEDULE`; thêm `INCREMENTAL` và trigger `EVENT`; cờ thiếu chiều chuyển sang `dq_score_snapshot.flags`; thêm tác vụ phân mảnh |
| EN-08-05 `dq_score_snapshot` (`diem_tong` NULL, `ket_luan` N_A), `dq_score_dimension`, `dq_finding` (`record_id`, `gia_tri_tom_tat`, `trang_thai` OPEN, CLEARED, OBSOLETE) | `dq_score_snapshot`, `dq_score_dimension`, `dq_finding`, `dq_rule_result` | Điểm không NULL: lần đo thiếu hẳn chiều ghi cờ `INCOMPLETE_DIMENSIONS`, lần đo hỏng hoàn toàn không có snapshot (không có `N_A`); `record_id` thành `record_key_hash` và `record_key_masked`; `gia_tri_tom_tat` thành `masked_value` và `value_hash`; `CLEARED` thành `RESOLVED`, `OBSOLETE` đóng thành `RESOLVED` ở lần đo kế; thêm `IN_REMEDIATION`, `WAIVED`; thêm `fingerprint` và kết quả từng quy tắc |
| EN-08-06 `dq_remediation_ticket` (`ma_ticket` `DQ-2026-000142`, `uu_tien`, `han_xu_ly`) | `dq_issue` + `dq_issue_activity` | Giữ khuôn mã `DQ-yyyy-nnnnnn`; `uu_tien` thành `severity`; `han_xu_ly` thành `sla_due_at` theo mức nghiêm trọng; `ghi_chu` thành bảng hoạt động chỉ thêm; giao cho `owner_org_code` |
| EN-08-06 `dq_report` (`loai`, `nam`, `trang_thai` OFFICIAL, `noi_dung`, `ma_bao_cao`) | `dq_report` | `loai` thành `report_type` (thêm AD_HOC); `nam` thành `period_code`; `OFFICIAL` tương ứng ANNUAL ở `PUBLISHED`; `noi_dung` thành `summary`; tệp PDF, XLSX ở Ceph RGW |

: Ánh xạ mô hình SRS cũ sang bảng mới

Chính sách lưu giữ ở SRS cũ (snapshot ≥ 5 năm, lỗi ≥ 24 tháng sau xử lý và CRITICAL ≥ 5 năm, báo cáo chính thức ≥ 10 năm, phiếu ≥ 5 năm) khác mặc định 13 tháng của thiết kế này đối với bản ghi lỗi; xem Q08-50.

## 9. Câu hỏi mở và đề nghị đồng bộ

### 9.1. Câu hỏi mở

Các câu hỏi chưa có quyết định, kèm đề xuất tạm.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q08-50 | Bản ghi lỗi giữ mặc định 13 tháng, trong khi SRS cũ giữ lỗi chi tiết 24 tháng sau xử lý và CRITICAL 5 năm; điều khoản cụ thể của Luật Dữ liệu 60/2024, NĐ 165/2025, NĐ 278/2025 về lưu giữ chưa xác minh | Giữ 13 tháng trực tuyến; thêm tùy chọn xuất Parquet sang `dq-archive` trước khi `DROP` cho lỗi CRITICAL và lỗi gắn phiếu hoặc ngoại lệ; pháp chế xác minh điều khoản |
| Q08-51 | Quay khóa HMAC (`dh-{tenant}-dq-hmac`) làm đổi mọi `fingerprint`, đứt chuỗi mới, còn, hết qua các kỳ | Quay 12 tháng hoặc khi nghi lộ; hai pha: ghi thêm cột `fingerprint_v2` (bổ sung ở bản sau), đối sánh cả hai ở hai kỳ rồi bỏ cột cũ; ATTT xác nhận |
| Q08-52 | `dq_finding` phân vùng theo `last_seen_at` nên mỗi kỳ đo mọi lỗi còn tồn tại bị cập nhật và chuyển phân vùng, tới 5 triệu dòng ghi lại mỗi tháng ở T01 | Chấp nhận ở quy mô giả định, đo ở TC hiệu năng; nếu quá tải thì tách bảng `dq_finding_seen` chỉ thêm theo lần đo và để `dq_finding` phân vùng theo `first_seen_at` |
| Q08-53 | Ngoại lệ chấp nhận: hạn tối đa (đang CHECK 366 ngày, tham số 180 ngày) và có cho gia hạn nhiều lần hay buộc tạo ngoại lệ mới | Gia hạn tối đa hai lần, mỗi lần cần DA duyệt lại; tham số `08.waiver.max-days` điều chỉnh theo tenant |
| Q08-54 | Khi `dq_inline_stat` vượt 50 triệu dòng mỗi tháng hoặc cần so liên tenant (FR-08-061) trên dữ liệu lớn, có chuyển thống kê sang ClickHouse | Giữ `pg-core` cho T01; ClickHouse chỉ khi vượt ngưỡng, nạp bằng CDC từ Kafka, không đổi API |

: Câu hỏi mở của tập CSDL PH-08

### 9.2. Phụ lục đề nghị đồng bộ

Bản 0.2 đã đồng bộ với FRS 0.2 (nhật ký hấp thụ FRS mục 15): thực thể EN-08-30…33, enum Phụ lục A, 43 tham số, mã phiếu và mã báo cáo. Tập này không sửa tài liệu chung hay tập khác; các điểm còn lại cần chủ tài liệu tương ứng nhận.

| Số | Gửi tới | Nội dung đề nghị |
|---|---|---|
| 1 | D02-08 (quyền) | Thêm PERM-08-read, asset, approve, run, finding-read, remediate, report, export, config, audit-read theo brief; thêm các scope máy `dq.check`, `dq.read`, `dq.ingest` |
| 2 | D03-10 (đa tenant), D03-09 | Ghi schema `ph08_dq` vào danh mục schema `pg-core`; vai trò `ph08_owner`, `ph08_app`, `ph08_readonly`, `ph08_benchmark`, `dq_reader`; mẫu RLS S cho `dq_rule_template`; bucket `dq-reports`, `dq-exports`, `dq-archive` |
| 3 | D00-04 sổ tra cứu | Tiền tố khóa Valkey `{tenant}:dq:*` và khóa OpenBao `dh-{tenant}-dq-hmac`, `dh-{tenant}-dq-sign` |
| 4 | SDD PH-08, ADR | ADR đề xuất (dải 085–089) ghi dấu vân tay bằng HMAC-SHA256 và quyết định phân vùng `last_seen_at` (Q08-52); SDD mô tả `PartitionMaintenanceJob` chạy trước đầu tháng |
| 5 | API PH-08 | Quyền đọc bản ghi lỗi trả `maskedValue`, không bao giờ trả giá trị gốc; cột `masked_value`, `value_hash`, `record_key_masked` bị thu hồi với vai chỉ đọc |
| 6 | FRS PH-08 (mục 12) | Nhật ký kiểm toán dùng kho chung của nền tảng, PH-08 không có bảng riêng; FRS ghi rõ để TC không tìm bảng audit |


: Đề nghị đồng bộ của tập CSDL PH-08

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-CSDL và K-TRINH-BAY: 31 bảng, DDL và changelog chạy thử trên PostgreSQL 16.15, kiểm cô lập 172 khối PASS; ERD bốn nhóm; bản ghi lỗi có dấu vân tay và không lưu giá trị gốc; ánh xạ EN, FR và mô hình SRS cũ sang bảng; năm câu hỏi mở Q08-50…54 |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ đợt đầu với FRS 0.2: 35 bảng (thêm `dq_retention_run`, `dq_incremental_buffer`, `dq_score_current`, `dq_waiver_item`); enum theo FRS Phụ lục A (`value_mode`, trạng thái miền, phiên bản bộ quy tắc APPROVED, loại hoạt động phiếu); cấu hình trực tuyến, đo tăng dần, dấu chạy thử, khóa chống trùng, heartbeat tác vụ; 43 tham số; vai trò so sánh liên tenant; mã báo cáo `BC-DQ`; DDL, Liquibase chạy lại, kiểm cô lập 211 khối PASS; rút còn sáu đề nghị đồng bộ |
