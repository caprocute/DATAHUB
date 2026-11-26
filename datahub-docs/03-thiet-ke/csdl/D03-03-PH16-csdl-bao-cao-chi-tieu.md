---
ma_tai_lieu: D03-03-PH16
ten: Thiết kế cơ sở dữ liệu phân hệ PH-16 Báo cáo chỉ tiêu và sổ kiến trúc
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, DBA, ATTT, hội đồng thẩm định
phan_he: PH-16
mo_ta: Thiết kế 40 bảng của schema ph16_kpi trên cụm pg-core cho phân hệ báo cáo chỉ tiêu và sổ kiến trúc, gồm chỉ tiêu có phiên bản và công thức CEL, nguồn và quan sát idempotent, kỳ báo cáo, giá trị và truy vết nguồn, báo cáo công bố bất biến có ký số, sổ kiến trúc, đánh giá tuân thủ, gói gửi quốc gia, RLS theo tenant, phân vùng tháng, lưu giữ theo tham số 16 và ánh xạ thực thể, chức năng sang bảng, trích từ DDL đã chạy thử.
tai_lieu_lien_quan: D02-03-PH16 FRS; D03-02-PH16 SDD; D03-04-PH16 API; D03-10 Thiết kế đa tenant; D05-02-PH16 Test case
---

# D03-03-PH16 · Thiết kế CSDL Báo cáo chỉ tiêu và sổ kiến trúc

## Tóm tắt cho hội đồng thẩm định

Schema `ph16_kpi` trên cụm `pg-core` có 40 bảng cho module `kpi` và `arch` của `dh-platform` (package `vn.datahub.platform.kpi`, `vn.datahub.platform.arch`): 38 bảng thực thể ứng với EN-16-01…39 của FRS (EN-16-18, 37 là kết quả tính khi hỏi, không có bảng riêng, xem 8.1) cùng hai bảng kỹ thuật `outbox_event`, `inbox_event`. Phân hệ thu số liệu đã tổng hợp từ các phân hệ nguồn, tính 24 chỉ tiêu theo kỳ, lập báo cáo chính thức có duyệt bốn mắt và ký số, giữ sổ kiến trúc nền tảng kèm đánh giá tuân thủ và chuẩn bị gói gửi quốc gia qua PH-14. Bốn điểm chính của thiết kế:

1. **Công thức, ngưỡng, mẫu gói quốc gia là cấu hình có phiên bản.** Phiên bản chỉ tiêu ACTIVE bất biến, mỗi chỉ tiêu một bản nháp mở, duyệt bốn mắt (CHECK `ck_kpi_indicator_version_four_eyes`); khung quốc gia chưa ban hành nên không viết cứng giá trị nào vào mã.
2. **Số liệu không bịa, không mất dấu.** Quan sát chỉ thêm, khử trùng bằng `(tenant_id, source_id, idempotency_ref, period_start)`; giá trị chỉ tiêu mang `completeness` (`COMPLETE`, `PARTIAL`, `NO_DATA`) và truy vết tới lần tổng hợp, quan sát hoặc số liệu nhập tay; thiếu nguồn thì ra phần đã có, nhãn PARTIAL (fail-soft).
3. **Báo cáo đã công bố và nhật ký gửi quốc gia là bằng chứng.** Phiên bản báo cáo PUBLISHED bất biến bằng trigger (nội dung, mã SHA-256, khóa tệp WORM, hạn giữ); chữ ký và nhật ký gửi quốc gia chỉ thêm; sửa sai bằng phiên bản đính chính.
4. **Cô lập tenant bằng `FORCE ROW LEVEL SECURITY`** trên cả 40 bảng; bảy bảng định nghĩa dùng chung (nhóm, chỉ tiêu, phiên bản, ngưỡng, mẫu báo cáo, tiêu chí tuân thủ, mẫu gói quốc gia) dùng mẫu S để mọi tenant đọc bộ mẫu của tenant `COMMON`.

DDL [`ph16/ddl/ph16_kpi.sql`](ph16/ddl/ph16_kpi.sql) đã chạy thử trên PostgreSQL 16.15 sạch; bài kiểm [`ph16/test/ph16_isolation_test.sql`](ph16/test/ph16_isolation_test.sql) đạt 286 khối PASS (4.2). Mọi enum trong `CHECK` khớp FRS Phụ lục A (bản 0.2), kiểm bằng script ở 4.3. Chương 8 ánh xạ thực thể, chức năng FR-16 và SRS cũ sang bảng; chương 9 nêu năm câu hỏi mở Q16-50…54 và các đề nghị đồng bộ.

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả cơ sở dữ liệu của PH-16 Báo cáo chỉ tiêu và sổ kiến trúc ở mức đủ để DBA dựng schema, kỹ sư `dh-platform` viết tầng truy cập và kiểm thử viên viết ca kiểm thử cô lập tenant, bất biến và idempotent. Phạm vi là 40 bảng của schema `ph16_kpi`, hàm, trigger, changelog Liquibase và bài kiểm cô lập. Ngoài phạm vi: dữ liệu thô của phân hệ nguồn (PH-16 chỉ nhận số đã tổng hợp), tệp báo cáo PDF và tệp xuất (Ceph RGW), khóa ký số (OpenBao, PH-12), giám sát thời gian thực (PH-13), điểm chất lượng dữ liệu (PH-08); các nơi này nêu ở chương 6.

Nguồn chuẩn là [`ph16/ddl/ph16_kpi.sql`](ph16/ddl/ph16_kpi.sql), sinh bằng `ph16/tools/sinh_ddl.py` với enum trùng FRS mục 4 (chỉ được thêm, không đổi tên). Danh mục bảng, chương 3 và chương 8 sinh từ DDL bằng `ph16/tools/dung_md.py`.

### 0.2. Thuật ngữ và chữ viết tắt

Các thuật ngữ dưới đây dùng xuyên suốt tập CSDL.

| Thuật ngữ | Giải thích |
|---|---|
| Chỉ tiêu (indicator) | Đại lượng đo được theo kỳ; 24 chỉ tiêu mẫu của tenant `COMMON`, 18 trong đó mang mã KPI-01…18 của BRD |
| Phiên bản định nghĩa | Công thức CEL, mục tiêu, ngưỡng của chỉ tiêu tại một thời điểm; DRAFT đến ACTIVE, ACTIVE bất biến |
| Quan sát (observation) | Một số liệu đã tổng hợp từ phân hệ nguồn theo `metric_code`, kỳ và chiều; chỉ thêm |
| Kỳ báo cáo | Tháng, quý hoặc năm; OPEN, CLOSED, REOPENED; chốt sau `16.period.close-day` ngày |
| `completeness` | Độ đầy đủ của giá trị: `FULL`, `PARTIAL` (thiếu nguồn, vẫn có số), `NO_DATA` |
| Fail-soft | Thiếu nguồn thì vẫn ra số phần đã có và gắn nhãn PARTIAL, không bịa số; báo cáo chính thức chặn khi thiếu nguồn bắt buộc |
| WORM | Write Once Read Many, kho chỉ ghi một lần (Object Lock của Ceph RGW), ADR-031 |
| Sổ kiến trúc | Danh bạ thành phần nền tảng (HTTT, API, luồng, topic, bộ điều hợp, dịch vụ nền tảng, liên kết quốc gia), vòng đời và phụ thuộc |
| Bốn mắt | Người duyệt khác người lập, ép bằng CHECK hoặc trigger theo tham số `16.*.four-eyes` |
| CEL | Common Expression Language, ngôn ngữ biểu thức của công thức chỉ tiêu (ADR đề xuất dải 160…164) |
| RLS, FORCE RLS | Row Level Security lọc dòng theo `tenant_id = app.tenant_id`; FORCE áp cả với chủ bảng |
| Mẫu RLS P, S | P: chỉ dòng của tenant phiên; S: thêm quyền đọc dòng `COMMON` dùng chung |
| Outbox, inbox | Ghi sự kiện cùng giao dịch để Debezium phát; bảng khử trùng sự kiện nhận |

: Thuật ngữ và chữ viết tắt của tập CSDL PH-16

### 0.3. Tài liệu tham chiếu

Tập này dựa vào các tài liệu sau.

| Tài liệu | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH16 FRS | Thực thể EN-16, FR-16-001…058, máy trạng thái 4.3…4.9, tham số `16.*`, sự kiện EVT-16-01…13 |
| `docs/07-srs/SRS-PH-16-nas-kpi.md` | Sáu thực thể EN-16-01…06 của SRS cũ và bảng lưu giữ (mục 8.4) |
| D03-03-PH08 | Mẫu DDL, vai trò, RLS, phân vùng; đối tượng `dq.kpi.published` cấp điểm chất lượng |
| D03-10 Thiết kế đa tenant; D03-07 Bảo mật; D03-09 Hạ tầng và DR | Mẫu RLS, mã hóa, cụm `pg-core`, sao lưu |
| ADR-003, 012, 031, 042; ADR-160…164 đề xuất | RLS; OpenBao; chuỗi băm và WORM; inbox, outbox; PostgreSQL phân vùng không ClickHouse, công thức CEL, báo cáo bất biến ký số, gói gửi quốc gia theo mẫu cấu hình |
| CMP-LAW-10, CMP-LAW-11 | Khung kiến trúc quốc gia, mẫu báo cáo; dự thảo nên tiêu chí và mẫu là cấu hình (Q16-53) |

: Tài liệu tham chiếu của tập CSDL PH-16

### 0.4. Người đọc

DBA, kỹ sư `dh-platform`, ATTT và kiểm thử viên; hội đồng thẩm định đọc Tóm tắt, chương 1 và chương 8.

### 0.5. Cấu trúc tài liệu

Chương 1 chiến lược lưu trữ, 2 sơ đồ thực thể, 3 đặc tả bảng, 4 DDL và Liquibase, 5 dữ liệu khởi tạo, 6 kho ngoài PostgreSQL, 7 sao lưu, mã hóa, lưu giữ, 8 ánh xạ sang thiết kế, 9 câu hỏi mở và đề nghị đồng bộ.

## 1. Chiến lược lưu trữ

### 1.1. Schema, vai trò và kết nối

Schema `ph16_kpi` do `ph16_owner` (NOLOGIN) sở hữu, nằm trên cụm `pg-core`. Module `kpi` kết nối bằng tài khoản dịch vụ thành viên `ph16_app`: chỉ DML, không `BYPASSRLS`; không `DELETE` trên bảng cấu hình, phiên bản, báo cáo, nhật ký; không `UPDATE`, `DELETE` trên bảng chỉ thêm. Liquibase chạy bằng thành viên `ph16_owner`. Báo cáo và BI dùng `ph16_readonly`, chỉ `SELECT`. Vai `ph16_compare` là ngoại lệ RLS duy nhất: đọc khung nhìn `v_compare_value` (security_invoker) gồm giá trị chỉ tiêu hiện hành đã có số của mọi tenant, chỉ sáu cột cần so sánh; ẩn danh tenant và nhóm tối thiểu `16.compare.min-tenants` do dịch vụ làm trước khi trả (FR-16-041).

PH-16 không có khóa ngoại sang schema khác. Mã tổ chức, mã HTTT, mã danh mục, mã kết nối quốc gia là chuỗi hoặc UUID kiểm ở dịch vụ qua giao diện module (Modulith). Nhật ký kiểm toán dùng kho chung của nền tảng (PH-13), nên không có bảng kiểm toán riêng; sự kiện kiểm toán đi qua `outbox_event` với topic `audit.recorded.v1`.

### 1.2. Cách ly tenant

Mọi bảng có `tenant_id varchar(16)` dạng `Tnn` hoặc `COMMON` và bật `FORCE ROW LEVEL SECURITY` qua `ph16_kpi.p_enable_rls(bảng)` (mẫu P): đọc và ghi chỉ dòng có `tenant_id = current_setting('app.tenant_id')`. Bảy bảng định nghĩa dùng `p_enable_rls_shared` (mẫu S): mọi tenant đọc được dòng `COMMON`, chỉ phiên `PLATFORM` ghi được `COMMON`; CHECK buộc phạm vi `COMMON` đi cùng `tenant_id = 'COMMON'`. Phiên `PLATFORM` không đọc được số liệu của tenant nào.

Biến phiên `app.tenant_id` đặt đầu mỗi giao dịch từ ngữ cảnh xác thực, không từ tham số của bên gọi; quên đặt thì không thấy và không ghi được dòng nào. Tác vụ nền liên tenant (tổng hợp theo lịch, dọn lưu giữ, duy trì phân vùng, outbox) lặp từng tenant. Khóa ngoại luôn kèm `tenant_id`, đích có `UNIQUE (tenant_id, id)`, nên một tenant không trỏ được tới dòng của tenant khác dù biết UUID.

### 1.3. Quy ước bảng và ngoại lệ

Theo D00-01 §5.1 mọi bảng thực thể có `id uuid` (UUIDv7 sinh ở ứng dụng), `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (trigger `tg_touch`, khóa lạc quan, ETag). Enum lưu `varchar` kèm `CHECK ... IN (...)` đúng giá trị FRS; kiểu thời gian `timestamptz`, chuỗi chuẩn NFC. Khóa, bí mật không lưu ở bảng nào: chữ ký chỉ lưu giá trị băm, định danh khóa ký và tham chiếu tệp.

| Bảng | Ngoại lệ | Lý do |
|---|---|---|
| `kpi_observation`, `kpi_ingest_log`, `kpi_indicator_value`, `kpi_value_lineage` | Khóa chính `(id, cột thời gian)`; không là đích khóa ngoại | Phân vùng tháng; tham chiếu tới chúng là logic, dịch vụ kiểm |
| `kpi_report_signature`, `kpi_national_submission_log`, `kpi_observation`, `kpi_ingest_log`, `kpi_value_lineage` | Trigger chặn sửa, xóa | Chỉ thêm, ghi một lần |
| `outbox_event`, `inbox_event` | Không `id`, `version`, `created_*`, `updated_*` | Bảng kỹ thuật, khóa chính là `event_id` hoặc `(tenant_id, consumer, event_id)` |
| Bảy bảng định nghĩa (xem 1.2) | `tenant_id` nhận thêm `COMMON` | Bộ chỉ tiêu và mẫu dùng chung toàn quốc |

: Quy ước bảng và ngoại lệ

### 1.4. Quy tắc nghiệp vụ chốt ở CSDL

Các quy tắc sau do CSDL tự bảo đảm bằng ràng buộc, chỉ mục duy nhất một phần, trigger hoặc quyền, nên một lỗi ở dịch vụ không phá được tính toàn vẹn. Tổng cộng 277 `CHECK`, 44 `UNIQUE`, 17 chỉ mục duy nhất (14 một phần) và 114 trigger (38 `tg_touch`, 32 `tg_immutable`, 18 `tg_transition`, 9 `tg_frozen`, 5 `tg_append_only`, 3 `tg_child_frozen` và các hàm cổng).

| Ràng buộc | Quy tắc | FR |
|---|---|---|
| `ck_kpi_indicator_version_state`, `tg_kpi_indicator_version_frozen`, `uq_kpi_indicator_version_open` | Phiên bản ACTIVE, SUPERSEDED bất biến; mỗi chỉ tiêu một bản nháp mở | 002, 003 |
| `ck_kpi_indicator_version_four_eyes`, `ck_kpi_manual_value_four_eyes`, `ck_kpi_compliance_assessment_four_eyes`, `ck_kpi_compliance_waiver_four_eyes` | Người duyệt khác người gửi (CHECK) | 003, 015, 047 |
| `tg_kpi_indicator_threshold_child_frozen` | Ngưỡng chỉ sửa khi phiên bản là DRAFT | 004 |
| `ck_kpi_observation_idem`, `uq_kpi_observation_idem` | Quan sát idempotent theo `(tenant_id, source_id, idempotency_ref, period_start)`; nhận lại cùng mã không tạo dòng mới | 010, 011 |
| `tg_kpi_observation_append_only`, `f_observation_ref` | Quan sát chỉ thêm; kiểm tham chiếu nguồn cùng tenant | 011, 012 |
| `uq_kpi_manual_value_open`, `tg_kpi_manual_value_gate`, `tg_kpi_manual_evidence_child_frozen` | Mỗi (chỉ tiêu, kỳ, biến) một số liệu tay chưa bị từ chối; bằng chứng bắt buộc theo `16.manual.evidence-required` | 014, 015 |
| `ck_kpi_reporting_period_reopened`, `f_period_open` | Mở lại kỳ cần lý do từ 50 ký tự (BR-16-011), người mở, số lần; kỳ CLOSED không nhận ghi | 017, 024 |
| `ck_kpi_indicator_group_weight` | Trọng số nhóm thang 0…100 (BR-16-016) | 007, 022 |
| `tg_kpi_ingest_log_transition` | `REJECTED` → `REPROCESSED` khi xử lý lại đạt, giữ mã lỗi | 016 |
| `ck_kpi_manual_import_rows`, `_expiry` | Tệp nhập ≤ 2.000 dòng, xem trước giữ ≤ 24 giờ | 014 |
| `uq_kpi_arch_reconciliation_running` | Một lần đối chiếu đang chạy mỗi tenant (ERR-16-056) | 048 |
| `uq_kpi_aggregation_run_active`, `uq_kpi_aggregation_run_idem` | Mỗi kỳ một lần tổng hợp QUEUED hoặc RUNNING; khóa idempotent chống trùng | 018, 020 |
| `ck_kpi_indicator_value_trend`, `ck_kpi_indicator_value_no_data`, `uq_kpi_indicator_value_current` | Xu hướng `UP, DOWN, FLAT`; NO_DATA không có số; mỗi (kỳ, chỉ tiêu) một giá trị hiện hành | 019, 021, 022 |
| `ck_kpi_report_version_published`, `uq_kpi_report_version_published`, `tg_kpi_report_version_frozen` | PUBLISHED, SUPERSEDED phải có người công bố, mã băm, khóa tệp WORM, hạn giữ; bất biến; mỗi báo cáo một phiên bản PUBLISHED | 026…030 |
| `f_report_version_gate`, `tg_kpi_report_approval_gate`, `f_report_sync` | Công bố cần duyệt bốn mắt (theo `16.report.four-eyes`) và chữ ký (theo `16.report.signing`); trạng thái báo cáo đồng bộ phiên bản | 028, 029 |
| `tg_kpi_report_signature_append_only`, `ck_kpi_report_signature_hash` | Chữ ký chỉ thêm, có băm hợp lệ | 029, 036 |
| `tg_kpi_report_version_no_delete` | Phiên bản báo cáo không xóa | 030 |
| `ck_kpi_compliance_*`, `tg_kpi_compliance_item_child_frozen` | Đánh giá CONFIRMED bất biến, mục chấm chỉ sửa khi đánh giá còn nháp; miễn trừ có hạn | 047 |
| `f_submission_gate`, `tg_kpi_national_submission_log_append_only` | Gói quốc gia chỉ chuyển trạng thái khi bật `16.national.enabled`; nhật ký gửi chỉ thêm | 051…054 |
| `ck_kpi_tenant_setting_code`, `ck_kpi_tenant_setting_type` | Chỉ 25 mã `16.*` của FRS §8.2; kiểu giá trị đúng mã (boolean, số, chuỗi) | 055 |
| `ck_outbox_event_prefix`, `ck_outbox_event_topic` | Chỉ 14 topic EVT-16 và `audit.recorded.v1`, tiền tố tenant | 056, 058 |

: Quy tắc nghiệp vụ chốt ở CSDL

Quy tắc cần dữ liệu ngoài schema hoặc tính toán (biên dịch CEL, điểm nhóm, mã tổ chức ở PH-01, ký số ở PH-12) kiểm ở dịch vụ, ghi ở D03-02-PH16.

### 1.5. Ước lượng khối lượng (giả định)

Giả định GĐ-01: tỉnh T01 quy mô vừa, 200 HTTT, 24 chỉ tiêu mẫu cộng khoảng 40 chỉ tiêu riêng của tenant, mỗi chỉ tiêu khoảng 20 chiều (đơn vị, nhóm), nhận quan sát hằng giờ từ 15 nguồn.

| Bảng | Dòng ước tính | Dung lượng |
|---|---|---|
| `kpi_observation` (36 tháng) | khoảng 9 triệu (15 nguồn, mỗi giờ khoảng 30 mẫu) | khoảng 3 GB gồm chỉ mục |
| `kpi_ingest_log` (90 ngày) | khoảng 1 triệu | khoảng 0,3 GB |
| `kpi_indicator_value`, `kpi_value_lineage` (10 năm) | khoảng 0,5 triệu; 2 triệu | khoảng 1 GB |
| `kpi_report*`, `kpi_distribution`, `kpi_delivery`, `kpi_export_job` | dưới 0,1 triệu | dưới 0,2 GB |
| Sổ kiến trúc, đánh giá tuân thủ | dưới 0,1 triệu | dưới 0,2 GB |

: Ước lượng khối lượng (giả định)

Tổng hợp chạy mỗi ngày (cron `0 30 1 * * *`) và khi nhận số liệu trễ nếu `16.late-data.recompute` bật; khối lượng ghi nhỏ, không cần tối ưu đặc biệt (ADR đề xuất dải 160…164).

### 1.6. Danh mục bảng

Bảng dưới liệt kê 36 bảng theo thứ tự đặc tả ở chương 3, kèm thực thể, phân vùng và FR chính; sinh từ DDL nên khớp tuyệt đối.

<!-- gen:danh-muc:start -->
| Mục | Bảng | Thực thể | Phân vùng | FR chính |
|---|---|---|---|---|
| 3.1 | `kpi_indicator_group` | EN-16-01 | Không | 007 |
| 3.2 | `kpi_indicator` | EN-16-02, EN-16-38 | Không | 001, 002, 006, 008 |
| 3.3 | `kpi_indicator_version` | EN-16-03, EN-16-04 | Không | 002, 003, 004, 005, 006 |
| 3.4 | `kpi_indicator_threshold` | EN-16-04 | Không | 004, 021 |
| 3.5 | `kpi_data_source` | EN-16-06 | Không | 009, 013, 042, 058 |
| 3.6 | `kpi_source_contract` | EN-16-05, EN-16-07 | Không | 009 |
| 3.7 | `kpi_observation` | EN-16-08 | Tháng, period_start | 010, 011, 012, 023, 057 |
| 3.8 | `kpi_ingest_log` | EN-16-09, EN-16-10 | Tháng, received_at | 010, 016 |
| 3.9 | `kpi_reporting_period` | EN-16-14 | Không | 017, 024 |
| 3.10 | `kpi_manual_value` | EN-16-11 | Không | 014, 015 |
| 3.11 | `kpi_manual_evidence` | EN-16-12 | Không | 014 |
| 3.12 | `kpi_manual_import` | EN-16-13 | Không | 014 |
| 3.13 | `kpi_manual_import_row` | EN-16-13 | Không | 014 |
| 3.14 | `kpi_aggregation_run` | EN-16-15 | Không | 018, 020, 023, 024, 042… |
| 3.15 | `kpi_indicator_value` | EN-16-16 | Tháng, period_start | 019, 021, 022, 035, 037… |
| 3.16 | `kpi_value_lineage` | EN-16-16 | Tháng, period_start | 019, 039 |
| 3.17 | `kpi_group_score` | EN-16-17 | Không | 007, 022, 037, 038 |
| 3.18 | `kpi_report_template` | EN-16-19 | Không | 025 |
| 3.19 | `kpi_report` | EN-16-20 | Không | 026, 031, 032 |
| 3.20 | `kpi_report_version` | EN-16-21, EN-16-22 | Không | 026, 027, 028, 029, 030… |
| 3.21 | `kpi_report_approval` | EN-16-21 | Không | 028, 029, 030 |
| 3.22 | `kpi_report_signature` | EN-16-21 | Không | 029, 036 |
| 3.23 | `kpi_distribution` | EN-16-24 | Không | 034 |
| 3.24 | `kpi_delivery` | EN-16-25 | Không | 034 |
| 3.25 | `kpi_export_job` | EN-16-23 | Không | 033, 036, 049 |
| 3.26 | `kpi_arch_component` | EN-16-26 | Không | 043, 044, 045, 046, 048… |
| 3.27 | `kpi_arch_component_version` | EN-16-27 | Không | 045, 052 |
| 3.28 | `kpi_arch_dependency` | EN-16-28 | Không | 045, 049 |
| 3.29 | `kpi_arch_reconciliation` | EN-16-33 | Không | 048 |
| 3.30 | `kpi_arch_recon_item` | EN-16-33 | Không | 048 |
| 3.31 | `kpi_compliance_criterion` | EN-16-29, EN-16-30 | Không | 047 |
| 3.32 | `kpi_compliance_assessment` | EN-16-31 | Không | 047 |
| 3.33 | `kpi_compliance_item` | EN-16-31 | Không | 047 |
| 3.34 | `kpi_compliance_waiver` | EN-16-32 | Không | 047 |
| 3.35 | `kpi_national_template` | EN-16-34 | Không | 050 |
| 3.36 | `kpi_national_submission` | EN-16-35 | Không | 051, 052, 054 |
| 3.37 | `kpi_national_submission_log` | EN-16-36 | Không | 053 |
| 3.38 | `kpi_tenant_setting` | EN-16-39 | Không | 055, 057 |
| 3.39 | `outbox_event` | Hạ tầng | Không | 021, 056, 058 |
| 3.40 | `inbox_event` | Hạ tầng | Không | 010, 044, 048 |

: Danh mục bảng của schema ph16_kpi

<!-- gen:danh-muc:end -->

### 1.7. Truy vấn chính và chỉ mục

Các truy vấn sau quyết định chỉ mục của bốn bảng phân vùng và của giá trị chỉ tiêu.

| Truy vấn | Chỉ mục | FR |
|---|---|---|
| Giá trị hiện hành của một chỉ tiêu theo kỳ | `uq_kpi_indicator_value_current` (một phần, `is_current`) | 019, 040 |
| Quan sát của nguồn theo kỳ | `ix_kpi_observation_metric (tenant_id, metric_code, period_start DESC)` | 010, 023 |
| Lần tổng hợp đang chạy của kỳ | `uq_kpi_aggregation_run_active` (một phần) | 018 |
| Phiên bản báo cáo đã công bố của một báo cáo | `uq_kpi_report_version_published` (một phần) | 026, 031 |
| Thành phần kiến trúc theo loại, vòng đời, trạng thái vận hành | `ix_kpi_arch_component_type (tenant_id, component_type, lifecycle)` | 043, 046 |
| Nhật ký gửi quốc gia theo gói, theo thời gian | `ix_kpi_national_submission_log_time (tenant_id, occurred_at DESC)` | 053 |
| Nguồn quá hạn độ tươi | `ix_kpi_data_source_state (tenant_id, state, source_type)` | 013, 042 |

: Truy vấn chính và chỉ mục

Toàn schema có 55 chỉ mục thường và 16 chỉ mục duy nhất một phần; chi tiết ở chương 3.

### 1.8. Phân vùng

Bốn bảng phân vùng RANGE theo tháng: `kpi_observation` (`period_start`), `kpi_ingest_log` (`received_at`), `kpi_indicator_value` và `kpi_value_lineage` (`period_start`). Thủ tục `ph16_kpi.p_ensure_partitions(bảng, tháng đầu, số tháng)` tạo trước phân vùng; DDL tạo sẵn 96 phân vùng (4 bảng x 24 tháng). `PartitionMaintenanceJob` chạy hằng ngày, giữ trước ba tháng; thiếu phân vùng đích thì ghi bị từ chối, nên job phải chạy trước đầu tháng. Quan sát đến trễ của kỳ cũ vào phân vùng của `period_start`, không của thời điểm nhận, nên việc dọn theo tháng dữ liệu (không theo tháng nhận) là chủ ý (Q16-53 bàn đánh đổi của khóa phân vùng với tính duy nhất).

## 2. Sơ đồ thực thể – quan hệ

Sơ đồ chia bốn nhóm cho vừa trang A4; khóa ngoại kèm `tenant_id` nên không vẽ. Đường nét liền là khóa ngoại thật, ghi chú "logic" là tham chiếu không có khóa ngoại.

```{.mermaid caption="ERD nhóm định nghĩa chỉ tiêu, nguồn và quan sát"}
erDiagram
  kpi_indicator_group ||--o{ kpi_indicator : "nhóm"
  kpi_indicator ||--o{ kpi_indicator_version : "phiên bản"
  kpi_indicator_version ||--o{ kpi_indicator_threshold : "ngưỡng"
  kpi_data_source ||--o{ kpi_source_contract : "hợp đồng"
  kpi_data_source ||--o{ kpi_observation : "quan sát"
  kpi_data_source ||--o{ kpi_ingest_log : "nhật ký nạp"
  kpi_indicator }o--o{ kpi_observation : "logic, metric_code"
```

Chỉ tiêu có phiên bản định nghĩa (công thức CEL, mục tiêu, hướng tốt) và ngưỡng chỉ sửa khi phiên bản là DRAFT. Nguồn có bốn kiểu (`EVENT`, `PULL_API`, `PUSH_API`, `MANUAL`) và hợp đồng nguồn giữ lược đồ `metric_code`. Quan sát liên kết chỉ tiêu bằng `metric_code` (logic), không khóa ngoại, vì bảng phân vùng và vì một quan sát có thể phục vụ nhiều chỉ tiêu.

```{.mermaid caption="ERD nhóm kỳ, số liệu tay, tổng hợp và giá trị"}
erDiagram
  kpi_reporting_period ||--o{ kpi_aggregation_run : "lần tổng hợp"
  kpi_reporting_period ||--o{ kpi_manual_value : "số liệu tay"
  kpi_indicator ||--o{ kpi_manual_value : "của chỉ tiêu"
  kpi_manual_value ||--o{ kpi_manual_evidence : "bằng chứng"
  kpi_manual_import ||--o{ kpi_manual_import_row : "dòng xem trước"
  kpi_manual_import_row }o--o| kpi_manual_value : "đã ghi"
  kpi_aggregation_run ||--o{ kpi_indicator_value : "sinh giá trị"
  kpi_indicator_version ||--o{ kpi_indicator_value : "công thức dùng"
  kpi_indicator ||--o{ kpi_indicator_value : "giá trị"
  kpi_indicator_value ||--o{ kpi_value_lineage : "logic, truy vết"
  kpi_manual_value ||--o{ kpi_value_lineage : "nguồn tay"
  kpi_aggregation_run ||--o{ kpi_group_score : "điểm nhóm"
  kpi_indicator_group ||--o{ kpi_group_score : "của nhóm"
```

Kỳ CLOSED không nhận ghi, mở lại cần lý do. Giá trị chỉ tiêu có đúng một dòng hiện hành mỗi kỳ; dòng cũ giữ `is_current = false` để so sánh khi tổng hợp lại. Truy vết nối giá trị với lần tổng hợp, quan sát và số liệu tay đã dùng.

```{.mermaid caption="ERD nhóm báo cáo, ký số, phân phối và xuất"}
erDiagram
  kpi_report_template ||--o{ kpi_report : "mẫu"
  kpi_reporting_period ||--o{ kpi_report : "kỳ"
  kpi_report ||--o{ kpi_report_version : "phiên bản"
  kpi_aggregation_run ||--o{ kpi_report_version : "ảnh chụp từ"
  kpi_report_version ||--o{ kpi_report_approval : "duyệt"
  kpi_report_version ||--o{ kpi_report_signature : "chữ ký"
  kpi_report_version ||--o{ kpi_delivery : "gửi"
  kpi_distribution ||--o{ kpi_delivery : "danh sách nhận"
  kpi_report_version ||--o{ kpi_export_job : "xuất"
  kpi_reporting_period ||--o{ kpi_export_job : "xuất theo kỳ"
```

Báo cáo là đầu mối; mỗi lần sửa là một phiên bản. Phiên bản PUBLISHED bất biến, duyệt và chữ ký ghi thành bảng riêng để có bằng chứng người duyệt, thời điểm, thuật toán và băm. Phân phối giữ danh sách nhận, lần gửi giữ kết quả từng người nhận.

```{.mermaid caption="ERD nhóm sổ kiến trúc, tuân thủ và gửi quốc gia"}
erDiagram
  kpi_arch_component ||--o{ kpi_arch_component_version : "phiên bản"
  kpi_arch_component ||--o{ kpi_arch_dependency : "phụ thuộc"
  kpi_arch_reconciliation ||--o{ kpi_arch_recon_item : "mục lệch"
  kpi_arch_component |o--o{ kpi_arch_recon_item : "thành phần lệch"
  kpi_arch_component ||--o{ kpi_compliance_assessment : "đánh giá"
  kpi_arch_component_version ||--o{ kpi_compliance_assessment : "áp cho phiên bản"
  kpi_compliance_assessment ||--o{ kpi_compliance_item : "mục chấm"
  kpi_compliance_criterion ||--o{ kpi_compliance_item : "tiêu chí"
  kpi_compliance_criterion ||--o{ kpi_compliance_waiver : "miễn trừ"
  kpi_arch_component ||--o{ kpi_compliance_waiver : "của thành phần"
  kpi_national_template ||--o{ kpi_national_submission : "mẫu gói"
  kpi_report_version ||--o{ kpi_national_submission : "báo cáo đính kèm"
  kpi_arch_component_version ||--o{ kpi_national_submission : "phiên bản đăng ký"
  kpi_national_submission ||--o{ kpi_national_submission_log : "nhật ký gửi"
```

Sổ kiến trúc tự đăng ký từ sự kiện của phân hệ khác (qua `inbox_event`) hoặc nhập tay; thành phần không xóa, chỉ ngừng. Tiêu chí tuân thủ là cấu hình dùng chung (mẫu S), đánh giá cần xác nhận bốn mắt, miễn trừ có hạn. Gói quốc gia lập theo mẫu cấu hình, gửi qua PH-14 và chỉ chuyển trạng thái khi tenant bật gửi.

## 3. Đặc tả bảng

Phần dưới sinh bằng `ph16/tools/dung_md.py` từ DDL; sửa ở DDL rồi sinh lại, không sửa tay. Mỗi bảng có khối đặc tả 10 mục trích từ DDL, bảng cột nổi bật (có ghi chú hoặc enum) và một dòng liệt kê cột còn lại.

<!-- gen:tables:start -->
### 3.1. `kpi_indicator_group`

::: dac-ta
**Mục đích.** EN-16-01 Nhóm chỉ tiêu: năm nhóm KET_NOI, CHIA_SE, DU_LIEU, VAN_HANH, KIEN_TRUC kế thừa năm nhóm KPI của SRS cũ, có trọng số tính điểm nhóm (FR-16-007). Dòng tenant COMMON do PLATFORM quản, mọi tenant đọc được (mẫu RLS S); tenant nhận bản sao khi khởi tạo.

**FR phục vụ.** FR-16-007; EN-16-01.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_indicator_group_code` (tenant_id, group_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_kpi_indicator_group_` + `tenant`, `code`, `weight`.

**Chỉ mục.** Không thêm.

**Cách ly tenant.** Mẫu S (1.2): đọc thêm dòng `COMMON`.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `group_code`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `group_code` | `varchar(16)` | Giá trị: `KET_NOI`, `CHIA_SE`, `DU_LIEU`, `VAN_HANH`, `KIEN_TRUC`. |
| `weight` | `numeric(5,2), mặc định 20.00` | Trọng số điểm nhóm thang 0…100; tổng trọng số các nhóm đang bật bằng 100 do dịch vụ kiểm (BR-16-016, ERR-16-012, FR-16-007). |

: Cột nổi bật của bảng `kpi_indicator_group`

Cột khác: `name` v(255); `description` v(2000); `display_order` smallint; `enabled` bool.

### 3.2. `kpi_indicator`

::: dac-ta
**Mục đích.** EN-16-02, EN-16-38 Chỉ tiêu: mã T-CODE, nhóm, loại giá trị, chiều tốt, cách đo, đơn vị, cách gộp qua kỳ, cờ bắt buộc cho báo cáo chính thức (FR-16-001, 002, 006, 008). Phạm vi COMMON là chỉ tiêu mẫu toàn quốc do PLATFORM quản, tenant kế thừa bằng bản sao ghi `template_code` (không khóa ngoại). Không xóa, chỉ ngừng hoặc thay thế.

**FR phục vụ.** FR-16-001, 002, 006, 008; EN-16-02, EN-16-38.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_indicator_code` (tenant_id, indicator_code).

**Khóa ngoại.** (tenant_id, group_code) → `kpi_indicator_group`.

**Ràng buộc CHECK.** `ck_kpi_indicator_` + `tenant`, `code`, `kind`, `direction`, `measurement`, `aggregation`, `scope`, `state`, `brd_ref`, `template`, `replaced`, `reason`.

**Chỉ mục.** `ix_kpi_indicator_group`, `ix_kpi_indicator_measure`.

**Cách ly tenant.** Mẫu S (1.2): đọc thêm dòng `COMMON`.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `indicator_code`, `scope`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `kind` | `varchar(10)` | Giá trị: `RATIO`, `COUNT`, `DURATION`, `SCORE`, `BOOLEAN`. |
| `direction` | `varchar(14)` | Giá trị: `HIGHER_BETTER`, `LOWER_BETTER`, `TARGET_RANGE`. |
| `measurement` | `varchar(8)` | Giá trị: `AUTO`, `MANUAL`, `MIXED`. |
| `aggregation` | `varchar(8), mặc định 'LAST'` | Giá trị: `LAST`, `SUM`, `AVG`, `P95`, `MAX`, `MIN`. |
| `scope` | `varchar(8), mặc định 'TENANT'` | Giá trị: `TENANT`, `COMMON`. |
| `mandatory` | `boolean, mặc định false` | Bắt buộc có số để công bố báo cáo chính thức; thiếu nguồn bắt buộc thì chặn công bố (ERR-16-0xx). |
| `brd_ref` | `varchar(8), NULL` | Mã KPI-01…18 của BRD (D02-01 §3) nếu chỉ tiêu là KPI đo của BO; NULL với chỉ tiêu bổ sung. |
| `template_code` | `varchar(63), NULL` | Mã chỉ tiêu mẫu COMMON đã kế thừa (FR-16-008); phục vụ nhận cập nhật mẫu. |
| `state` | `varchar(8), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `ACTIVE`, `RETIRED`. |
| `template_version_no` | `integer, NULL` | Số phiên bản mẫu COMMON đã nhận; mẫu có phiên bản ACTIVE mới hơn và chưa bị bỏ qua là cập nhật chờ quyết định (FRS EN-16-38). |
| `template_dismissed_version_no` | `integer, NULL` | Số phiên bản mẫu COMMON tenant đã quyết định không nhận (DISMISSED). |

: Cột nổi bật của bảng `kpi_indicator`

Cột khác: `indicator_code` v(63); `group_code` v(16); `name` v(255); `description` v(2000); `unit` v(32); `state_reason` v(2000); `replaced_by_code` v(63); `display_order` smallint.

### 3.3. `kpi_indicator_version`

::: dac-ta
**Mục đích.** EN-16-03, EN-16-04 Phiên bản định nghĩa chỉ tiêu: công thức CEL trên biến quan sát (ví dụ `obs("ph01.httt.connected") / obs("ph01.httt.total") * 100`), danh sách biến, mục tiêu có hạn, làm tròn; vòng đời DRAFT, PENDING_APPROVAL, ACTIVE, SUPERSEDED, RETIRED, CHANGES_REQUESTED; duyệt bốn mắt (FR-16-002, 003, 004, 005, 006). ACTIVE và SUPERSEDED bất biến; mỗi chỉ tiêu một phiên bản ACTIVE và một phiên bản đang soạn hoặc chờ duyệt.

**FR phục vụ.** FR-16-002, 003, 004, 005, 006; EN-16-03, EN-16-04.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_indicator_version_no` (tenant_id, indicator_id, version_no), `uq_kpi_indicator_version_active` (tenant_id, indicator_id) có điều kiện, `uq_kpi_indicator_version_open` (tenant_id, indicator_id) có điều kiện.

**Khóa ngoại.** (tenant_id, indicator_id) → `kpi_indicator`.

**Ràng buộc CHECK.** `ck_kpi_indicator_version_` + `tenant`, `no`, `state`, `variables`, `formula`, `formula_required`, `rounding`, `target_range`, `four_eyes`, `submitted`, `active`, `changes`.

**Chỉ mục.** `ix_kpi_indicator_version_state`.

**Cách ly tenant.** Mẫu S (1.2): đọc thêm dòng `COMMON`.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `indicator_id`, `version_no`; Trigger: `tg_kpi_indicator_version_frozen`, `tg_kpi_indicator_version_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `state` | `varchar(18), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `PENDING_APPROVAL`, `CHANGES_REQUESTED`, `ACTIVE`, `SUPERSEDED`, `RETIRED`. |
| `formula_cel` | `text, NULL` | Biểu thức CEL (ADR đề xuất dải 160…164), chỉ đọc quan sát đã chuẩn hóa; đã thử tính trên dữ liệu kỳ trước trước khi gửi duyệt (FR-16-003). |
| `variables` | `jsonb, mặc định '[]'` | Mảng {name, metricCode, aggregation, required, default}: biến CEL ánh xạ tới `metric_code` của quan sát hoặc tới số liệu nhập tay. |
| `baseline_value` | `numeric(24,6), NULL` | Giá trị nền để so mục tiêu giảm theo tỷ lệ (ví dụ KPI-02, nền 150). |
| `target_due` | `date, NULL` | Hạn đạt mục tiêu (FR-16-004). |

: Cột nổi bật của bảng `kpi_indicator_version`

Cột khác: `indicator_id` uuid; `version_no` int; `rounding_digits` smallint; `target_value` num(24,6); `target_min` num(24,6); `target_max` num(24,6); `effective_from` date; `submitted_by` v(64); `submitted_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `activated_at` tstz; `superseded_at` tstz; `change_note` v(2000).

### 3.4. `kpi_indicator_threshold`

::: dac-ta
**Mục đích.** EN-16-04 Ngưỡng ba mức GREEN, AMBER, RED của một phiên bản định nghĩa: khoảng giá trị ứng với mỗi mức, dùng đánh giá trạng thái ON_TRACK, AT_RISK, OFF_TRACK (FR-16-004, 021). Chỉ sửa khi phiên bản cha là DRAFT hoặc CHANGES_REQUESTED.

**FR phục vụ.** FR-16-004, 021; EN-16-04.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_indicator_threshold_level` (tenant_id, version_id, level).

**Khóa ngoại.** (tenant_id, version_id) → `kpi_indicator_version`.

**Ràng buộc CHECK.** `ck_kpi_indicator_threshold_` + `tenant`, `level`, `bounds`.

**Chỉ mục.** Không thêm.

**Cách ly tenant.** Mẫu S (1.2): đọc thêm dòng `COMMON`.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `version_id`, `level`; Trigger: `tg_kpi_indicator_threshold_child_frozen`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `level` | `varchar(5)` | Giá trị: `GREEN`, `AMBER`, `RED`. |

: Cột nổi bật của bảng `kpi_indicator_threshold`

Cột khác: `version_id` uuid; `lower_bound` num(24,6); `upper_bound` num(24,6); `lower_inclusive` bool; `upper_inclusive` bool.

### 3.5. `kpi_data_source`

::: dac-ta
**Mục đích.** EN-16-06 Nguồn số liệu: phân hệ hoặc kênh cung cấp quan sát, bốn loại EVENT (Kafka), PULL_API (kéo API chỉ số theo lịch), PUSH_API (scope `kpi.ingest`), MANUAL; theo dõi độ tươi và số lần kéo lỗi liên tiếp (FR-16-009, 013). Không xóa, chỉ tạm dừng hoặc ngừng.

**FR phục vụ.** FR-16-009, 013, 042, 058; EN-16-06.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_data_source_code` (tenant_id, source_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_kpi_data_source_` + `tenant`, `code`, `type`, `state`, `phase`, `event`, `topic`, `pull`, `stale`, `failures`, `error`, `reason`.

**Chỉ mục.** `ix_kpi_data_source_state`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `source_code`, `source_type`; Trigger: `tg_kpi_data_source_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `source_type` | `varchar(8)` | Giá trị: `EVENT`, `PULL_API`, `PUSH_API`, `MANUAL`. |
| `state` | `varchar(8), mặc định 'ACTIVE'` | Giá trị: `ACTIVE`, `STALE`, `FAILED`, `PAUSED`, `RETIRED`. |
| `topic_pattern` | `varchar(255), NULL` | Mẫu topic Kafka dạng `{tenant}.dq.kpi.published.v1`. |
| `stale_after_hours` | `smallint, NULL` | NULL thì lấy tham số 16.source.stale-hours (mặc định 26 giờ); quá hạn chuyển STALE. |
| `consecutive_failures` | `integer, mặc định 0` | Số lần kéo lỗi liên tiếp; đạt 16.source.fail-after (mặc định 3) thì chuyển FAILED và phát EVT-16-03. |

: Cột nổi bật của bảng `kpi_data_source`

Cột khác: `source_code` v(63); `name` v(255); `state_reason` v(2000); `owner_phase` v(5); `api_ref` v(255); `schedule_cron` v(64); `last_attempt_at` tstz; `last_success_at` tstz; `last_error_code` v(11); `description` v(2000).

### 3.6. `kpi_source_contract`

::: dac-ta
**Mục đích.** EN-16-05, EN-16-07 Hợp đồng chỉ số của nguồn: mỗi dòng là một `metric_code` dạng `ph{nn}.{đối-tượng}.{chỉ-số}` nguồn cam kết cung cấp, kiểu giá trị, đơn vị, chiều phân tách, phiên bản lược đồ (`kpiSchemaVersion`) và kỳ mong đợi (FR-16-009). Quan sát có `metric_code` ngoài hợp đồng bị loại.

**FR phục vụ.** FR-16-009; EN-16-05, EN-16-07.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_source_contract` (tenant_id, source_id, metric_code, schema_version).

**Khóa ngoại.** (tenant_id, source_id) → `kpi_data_source`.

**Ràng buộc CHECK.** `ck_kpi_source_contract_` + `tenant`, `metric`, `kind`, `schema_version`, `period`, `state`.

**Chỉ mục.** `ix_kpi_source_contract_metric`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `source_id`, `metric_code`, `schema_version`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `kind` | `varchar(10)` | Giá trị: `RATIO`, `COUNT`, `DURATION`, `SCORE`, `BOOLEAN`. |
| `period_type` | `varchar(8), NULL` | Giá trị: `MONTH`, `QUARTER`, `YEAR`. |
| `state` | `varchar(8), mặc định 'ACTIVE'` | Giá trị: `ACTIVE`, `RETIRED`. |

: Cột nổi bật của bảng `kpi_source_contract`

Cột khác: `source_id` uuid; `metric_code` v(128); `unit` v(32); `dimension_schema` jsonb; `schema_version` v(16); `required` bool.

### 3.7. `kpi_observation`

::: dac-ta
**Mục đích.** EN-16-08 Quan sát: số liệu đã tổng hợp nhận từ phân hệ nguồn qua sự kiện, API kéo hoặc API đẩy, đã chuẩn hóa (FR-16-010, 011, 012). Chỉ thêm. Phân vùng tháng theo `period_start` (giờ Việt Nam). Idempotent: `idempotency_ref` (mã sự kiện hoặc `snapshotId`) duy nhất theo tenant và nguồn, nhận lại bản trùng không tạo dòng mới.

**FR phục vụ.** FR-16-010, 011, 012, 023, 057; EN-16-08.

**Khóa chính.** (id, period_start).

**Duy nhất.** `uq_kpi_observation_idem` (tenant_id, source_id, idempotency_ref, period_start).

**Khóa ngoại.** (tenant_id, source_id) → `kpi_data_source`.

**Ràng buộc CHECK.** `ck_kpi_observation_` + `tenant`, `metric`, `period`, `idem`, `channel`, `dimensions`.

**Chỉ mục.** `ix_kpi_observation_metric`, `ix_kpi_observation_source`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Phân vùng tháng theo `period_start`; Trigger: `tg_kpi_observation_append_only`, `tg_kpi_observation_ref`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `period_start` | `timestamptz` | Khóa phân vùng, tháng theo giờ Việt Nam; PartitionMaintenanceJob tạo trước phân vùng. |
| `dimensions` | `jsonb, mặc định '{}'` | Chiều phân tách (tỉnh, loại HTTT…) dạng đối tượng JSON; không chứa dữ liệu cá nhân. |
| `idempotency_ref` | `varchar(128)` | Mã sự kiện (EVT-xx-yy) hoặc `snapshotId`; ERR-16-1xx khi trùng mã nhưng khác kỳ (trigger `tg_kpi_observation_ref`). |
| `channel` | `varchar(8)` | Giá trị: `EVENT`, `PULL_API`, `PUSH_API`. |
| `late` | `boolean, mặc định false` | Quan sát đến sau khi kỳ COLLECTING kết thúc; kích hoạt tính lại LATE_DATA khi 16.late-data.recompute bật. |

: Cột nổi bật của bảng `kpi_observation`

Cột khác: `source_id` uuid; `metric_code` v(128); `value` num(24,6); `unit` v(32); `period_end` tstz; `source_ref` v(255); `schema_version` v(16); `received_at` tstz.

### 3.8. `kpi_ingest_log`

::: dac-ta
**Mục đích.** EN-16-09, EN-16-10 Nhật ký tiếp nhận và loại bỏ: mỗi lần nhận quan sát ghi kết quả ACCEPTED, DUPLICATE hoặc REJECTED kèm mã lỗi ERR-16-101…199 và băm thân yêu cầu; bản tin bị loại xử lý lại đạt thì chuyển REPROCESSED, giữ mã lỗi cũ làm lịch sử (FR-16-010, 016). Phân vùng tháng theo `received_at`.

**FR phục vụ.** FR-16-010, 016; EN-16-09, EN-16-10.

**Khóa chính.** (id, received_at).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, source_id) → `kpi_data_source`.

**Ràng buộc CHECK.** `ck_kpi_ingest_log_` + `tenant`, `channel`, `outcome`, `hash`, `reject`, `rejected`, `payload`, `accepted`, `reprocessed`.

**Chỉ mục.** `ix_kpi_ingest_log_source`, `ix_kpi_ingest_log_rejected`, `ix_kpi_ingest_log_ref`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Phân vùng tháng theo `received_at`; Bất biến: `tenant_id`, `source_id`, `channel`, `metric_code`, `idempotency_ref`, `payload_hash`, `payload`, `reject_code`, `received_at`; Trigger: `tg_kpi_ingest_log_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `channel` | `varchar(8)` | Giá trị: `EVENT`, `PULL_API`, `PUSH_API`. |
| `outcome` | `varchar(11)` | Giá trị: `ACCEPTED`, `DUPLICATE`, `REJECTED`, `REPROCESSED`. |
| `payload_hash` | `bytea, NULL` | SHA-256 của thân yêu cầu (32 byte). |
| `payload` | `jsonb, NULL` | Bản tin quan sát đã tổng hợp, chỉ giữ với dòng REJECTED (tối đa 64 KB) để xử lý lại sau khi sửa hợp đồng; không chứa bản ghi giao dịch hay dữ liệu cá nhân (BR-16-028). |

: Cột nổi bật của bảng `kpi_ingest_log`

Cột khác: `source_id` uuid; `metric_code` v(128); `idempotency_ref` v(128); `reject_code` v(11); `detail` v(2000); `observation_id` uuid; `received_at` tstz; `reprocessed_at` tstz; `reprocessed_by` v(64).

### 3.9. `kpi_reporting_period`

::: dac-ta
**Mục đích.** EN-16-14 Kỳ báo cáo tháng, quý, năm mã `M-2026-10`, `Q-2026-Q3`, `Y-2026`; vòng đời OPEN, COLLECTING, COMPUTED, CLOSED, REOPENED. Kỳ CLOSED không nhận giá trị mới; mở lại phải có lý do và người mở (FR-16-017, 024).

**FR phục vụ.** FR-16-017, 024; EN-16-14.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_reporting_period_code` (tenant_id, period_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_kpi_reporting_period_` + `tenant`, `type`, `code`, `dates`, `state`, `closed`, `reopened`.

**Chỉ mục.** `ix_kpi_reporting_period_start`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `period_code`, `period_type`, `start_date`, `end_date`; Trigger: `tg_kpi_reporting_period_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `period_type` | `varchar(8)` | Giá trị: `MONTH`, `QUARTER`, `YEAR`. |
| `state` | `varchar(10), mặc định 'OPEN'` | Giá trị: `OPEN`, `COLLECTING`, `COMPUTED`, `CLOSED`, `REOPENED`. |
| `close_due_date` | `date, NULL` | Ngày dự kiến chốt, theo tham số 16.period.close-day (mặc định ngày 5 của tháng sau). |
| `reopen_reason` | `varchar(2000), NULL` | Lý do mở lại từ 50 ký tự (BR-16-011, ERR-16-007). |
| `recompute_requested_at` | `timestamptz, NULL` | Mốc yêu cầu tính lại đầu tiên trong cửa sổ 16.late-data.debounce-minutes; bộ quét tạo lần LATE_DATA khi quá cửa sổ rồi đặt về NULL (FR-16-023). |

: Cột nổi bật của bảng `kpi_reporting_period`

Cột khác: `period_code` v(16); `start_date` date; `end_date` date; `closed_by` v(64); `closed_at` tstz; `reopened_by` v(64); `reopened_at` tstz; `reopen_count` smallint.

### 3.10. `kpi_manual_value`

::: dac-ta
**Mục đích.** EN-16-11 Số liệu nhập tay cho chỉ tiêu đo MANUAL hoặc MIXED: DRAFT, SUBMITTED, ACCEPTED, REJECTED; người nhập khác người xác nhận (FR-16-014, 015). Gửi xác nhận cần bằng chứng khi `16.manual.evidence-required` bật. Số liệu đã gửi hoặc đã quyết định không đổi giá trị.

**FR phục vụ.** FR-16-014, 015; EN-16-11.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_manual_value_open` (tenant_id, indicator_id, period_id, variable_name) có điều kiện.

**Khóa ngoại.** (tenant_id, indicator_id) → `kpi_indicator`, (tenant_id, period_id) → `kpi_reporting_period`.

**Ràng buộc CHECK.** `ck_kpi_manual_value_` + `tenant`, `state`, `four_eyes`, `submitted`, `decided`, `rejected`.

**Chỉ mục.** `ix_kpi_manual_value_inbox`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `indicator_id`, `period_id`, `variable_name`, `entered_by`; Trigger: `tg_kpi_manual_value_frozen`, `tg_kpi_manual_value_gate`, `tg_kpi_manual_value_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `variable_name` | `varchar(63), mặc định 'value'` | Tên biến trong công thức CEL mà số liệu tay cung cấp; mặc định `value` cho chỉ tiêu một biến. |
| `state` | `varchar(9), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `SUBMITTED`, `ACCEPTED`, `REJECTED`. |
| `decided_by` | `varchar(64), NULL` | Người xác nhận; CHECK ck_kpi_manual_value_four_eyes buộc khác `entered_by` (cặp loại trừ, PERM-16-manual). |

: Cột nổi bật của bảng `kpi_manual_value`

Cột khác: `indicator_id` uuid; `period_id` uuid; `value` num(24,6); `unit` v(32); `entered_by` v(64); `entered_at` tstz; `submitted_at` tstz; `decided_at` tstz; `decision_comment` v(2000); `note` v(2000).

### 3.11. `kpi_manual_evidence`

::: dac-ta
**Mục đích.** EN-16-12 Bằng chứng của số liệu nhập tay: tệp đính kèm (Ceph RGW, kèm SHA-256) hoặc số và ngày văn bản (FR-16-014). Chỉ thêm, sửa, xóa khi số liệu cha còn DRAFT; sau khi gửi xác nhận là bằng chứng cố định.

**FR phục vụ.** FR-16-014; EN-16-12.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, manual_value_id) → `kpi_manual_value`.

**Ràng buộc CHECK.** `ck_kpi_manual_evidence_` + `tenant`, `type`, `file`, `doc`, `hash`.

**Chỉ mục.** `ix_kpi_manual_evidence_value`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Trigger: `tg_kpi_manual_evidence_child_frozen`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `evidence_type` | `varchar(15)` | Giá trị: `FILE`, `DOCUMENT_NUMBER`. |
| `object_ref` | `varchar(512), NULL` | Đường dẫn đối tượng trên Ceph RGW (bucket kpi-evidence); không lưu tệp trong PostgreSQL. |

: Cột nổi bật của bảng `kpi_manual_evidence`

Cột khác: `manual_value_id` uuid; `file_name` v(255); `content_hash` bytea; `document_no` v(64); `document_date` date; `description` v(2000); `uploaded_by` v(64).

### 3.12. `kpi_manual_import`

::: dac-ta
**Mục đích.** EN-16-13 Lần nhập số liệu tay từ tệp XLSX theo mẫu (≤ 2.000 dòng): tệp gốc, mã băm, số dòng hợp lệ, lỗi, đã ghi; bản xem trước giữ 24 giờ rồi dọn (FR-16-014). Ghi các dòng hợp lệ tạo số liệu tay DRAFT.

**FR phục vụ.** FR-16-014; EN-16-13.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_kpi_manual_import_` + `tenant`, `rows`, `hash`, `expiry`, `committed`.

**Chỉ mục.** `ix_kpi_manual_import_expiry`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `file_name`, `object_ref`, `content_hash`, `row_total`, `uploaded_by`, `expires_at`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `object_ref` | `varchar(512)` | Tệp XLSX gốc trên Ceph RGW (bucket kpi-evidence, tiền tố imports/); xóa cùng bản ghi khi quá expires_at. |

: Cột nổi bật của bảng `kpi_manual_import`

Cột khác: `file_name` v(255); `content_hash` bytea; `row_total` int; `valid_count` int; `invalid_count` int; `imported_count` int; `uploaded_by` v(64); `expires_at` tstz; `committed_by` v(64); `committed_at` tstz.

### 3.13. `kpi_manual_import_row`

::: dac-ta
**Mục đích.** EN-16-13 Dòng của lần nhập tệp: chỉ tiêu, kỳ, giá trị đọc được, kết quả kiểm VALID, INVALID (kèm mã lỗi) hoặc IMPORTED khi đã thành số liệu tay (FR-16-014). Bản xem trước UI-16-07 đọc bảng này.

**FR phục vụ.** FR-16-014; EN-16-13.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_manual_import_row_no` (tenant_id, import_id, row_no).

**Khóa ngoại.** (tenant_id, import_id) → `kpi_manual_import`, (tenant_id, manual_value_id) → `kpi_manual_value`.

**Ràng buộc CHECK.** `ck_kpi_manual_import_row_` + `tenant`, `no`, `status`, `invalid`, `imported`, `error`.

**Chỉ mục.** Không thêm.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `import_id`, `row_no`, `indicator_code`, `period_code`, `value`; Trigger: `tg_kpi_manual_import_row_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `row_status` | `varchar(8)` | Giá trị: `VALID`, `INVALID`, `IMPORTED`. |

: Cột nổi bật của bảng `kpi_manual_import_row`

Cột khác: `import_id` uuid; `row_no` int; `indicator_code` v(63); `period_code` v(16); `value` num(24,6); `error_code` v(11); `detail` v(500); `manual_value_id` uuid.

### 3.14. `kpi_aggregation_run`

::: dac-ta
**Mục đích.** EN-16-15 Lần tổng hợp: một lần tính mọi chỉ tiêu của một kỳ, theo lịch, thủ công, tính lại hoặc do số liệu trễ; ghi độ đầy đủ, cờ thiếu nguồn, số chỉ tiêu có số (FR-16-018, 020, 023, 042). SUCCEEDED, PARTIAL, FAILED, CANCELLED là trạng thái cuối. Mỗi kỳ tối đa một lần đang QUEUED hoặc RUNNING.

**FR phục vụ.** FR-16-018, 020, 023, 024, 042, 058; EN-16-15.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_aggregation_run_no` (tenant_id, period_id, run_no), `uq_kpi_aggregation_run_active` (tenant_id, period_id) có điều kiện, `uq_kpi_aggregation_run_idem` (tenant_id, idempotency_ref) có điều kiện.

**Khóa ngoại.** (tenant_id, period_id) → `kpi_reporting_period`.

**Ràng buộc CHECK.** `ck_kpi_aggregation_run_` + `tenant`, `no`, `trigger`, `state`, `flags`, `completeness`, `counts`, `done`, `result`, `partial`, `failed`, `reason`, `error`.

**Chỉ mục.** `ix_kpi_aggregation_run_state`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `period_id`, `run_no`, `run_trigger`, `requested_by`; Trigger: `tg_kpi_aggregation_run_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `run_trigger` | `varchar(9)` | Giá trị: `SCHEDULE`, `MANUAL`, `RECOMPUTE`, `LATE_DATA`. |
| `state` | `varchar(9), mặc định 'QUEUED'` | Giá trị: `QUEUED`, `RUNNING`, `SUCCEEDED`, `PARTIAL`, `FAILED`, `CANCELLED`. |
| `completeness` | `numeric(5,4), NULL` | Tỷ lệ chỉ tiêu có số trên tổng số chỉ tiêu đang ACTIVE của kỳ (0…1). |
| `flags` | `text[], mặc định '{}'` | Cờ: MISSING_SOURCE, STALE_SOURCE, MANUAL_PENDING, FORMULA_ERROR. |
| `idempotency_ref` | `varchar(128), NULL` | Chống chạy lặp theo lịch, ví dụ `agg:M-2026-10:2026-11-05`; NULL với lần chạy tay. |

: Cột nổi bật của bảng `kpi_aggregation_run`

Cột khác: `period_id` uuid; `run_no` int; `requested_by` v(64); `reason` v(2000); `started_at` tstz; `finished_at` tstz; `indicator_total` smallint; `indicator_computed` smallint; `error_code` v(11); `error_message` v(2000).

### 3.15. `kpi_indicator_value`

::: dac-ta
**Mục đích.** EN-16-16 Giá trị chỉ tiêu theo kỳ và lần tổng hợp: số, trạng thái so mục tiêu và ngưỡng (ON_TRACK, AT_RISK, OFF_TRACK, NO_DATA), độ đầy đủ (COMPLETE, PARTIAL, NO_DATA), chênh lệch so kỳ trước và cùng kỳ năm trước, xu hướng; ghi phiên bản công thức đã dùng (FR-16-019, 021, 022, 035, 037, 039, 040, 041). Phân vùng tháng theo `period_start`. Kỳ CLOSED không nhận giá trị mới.

**FR phục vụ.** FR-16-019, 021, 022, 035, 037, 039, 040, 041; EN-16-16.

**Khóa chính.** (id, period_start).

**Duy nhất.** `uq_kpi_indicator_value_run` (tenant_id, run_id, indicator_id, period_start), `uq_kpi_indicator_value_current` (tenant_id, period_id, indicator_id, period_start) có điều kiện.

**Khóa ngoại.** (tenant_id, period_id) → `kpi_reporting_period`, (tenant_id, run_id) → `kpi_aggregation_run`, (tenant_id, indicator_id) → `kpi_indicator`, (tenant_id, version_id) → `kpi_indicator_version`.

**Ràng buộc CHECK.** `ck_kpi_indicator_value_` + `tenant`, `status`, `completeness`, `trend`, `no_data`, `period_code`, `group`, `missing`.

**Chỉ mục.** `ix_kpi_indicator_value_series`, `ix_kpi_indicator_value_status`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Phân vùng tháng theo `period_start`; Bất biến: `tenant_id`, `period_id`, `period_code`, `period_start`, `run_id`, `indicator_id`, `indicator_code`, `version_id`; Trigger: `tg_kpi_indicator_value_period`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `period_start` | `date` | Khóa phân vùng: ngày bắt đầu của kỳ (kỳ quý, năm nằm ở phân vùng tháng đầu). |
| `group_code` | `varchar(16)` | Giá trị: `KET_NOI`, `CHIA_SE`, `DU_LIEU`, `VAN_HANH`, `KIEN_TRUC`. |
| `version_id` | `uuid` | Phiên bản công thức có hiệu lực lúc tính; cùng `kpi_value_lineage` làm dòng truy nguồn. |
| `status` | `varchar(9)` | Giá trị: `ON_TRACK`, `AT_RISK`, `OFF_TRACK`, `NO_DATA`. |
| `completeness` | `varchar(9)` | Giá trị: `COMPLETE`, `PARTIAL`, `NO_DATA`. |
| `trend` | `varchar(8), NULL` | Giá trị: `UP`, `DOWN`, `FLAT`. |
| `is_current` | `boolean, mặc định true` | Dòng của lần tổng hợp mới nhất cho (kỳ, chỉ tiêu); tính lại đặt dòng cũ về false. Mỗi (kỳ, chỉ tiêu) một dòng hiện hành. |
| `missing_variables` | `text[], mặc định '{}'` | Tên biến thiếu quan sát khi PARTIAL (fail-soft, không bịa số). |

: Cột nổi bật của bảng `kpi_indicator_value`

Cột khác: `period_id` uuid; `period_code` v(16); `run_id` uuid; `indicator_id` uuid; `indicator_code` v(63); `value` num(24,6); `delta` num(24,6); `delta_yoy` num(24,6); `computed_at` tstz.

### 3.16. `kpi_value_lineage`

::: dac-ta
**Mục đích.** EN-16-16 Dòng truy nguồn: mỗi biến công thức dùng cho một giá trị chỉ tiêu trỏ tới quan sát, số liệu nhập tay hoặc chỉ tiêu khác, kèm giá trị đã dùng (FR-16-019, 039). Chỉ thêm; phân vùng tháng theo `period_start`; tham chiếu tới giá trị và quan sát là logic vì bảng đích phân vùng.

**FR phục vụ.** FR-16-019, 039; EN-16-16.

**Khóa chính.** (id, period_start).

**Duy nhất.** `uq_kpi_value_lineage_seq` (tenant_id, value_id, seq, period_start).

**Khóa ngoại.** (tenant_id, run_id) → `kpi_aggregation_run`, (tenant_id, manual_value_id) → `kpi_manual_value`, (tenant_id, ref_indicator_id) → `kpi_indicator`.

**Ràng buộc CHECK.** `ck_kpi_value_lineage_` + `tenant`, `seq`, `kind`, `ref_one`, `metric`.

**Chỉ mục.** `ix_kpi_value_lineage_obs`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Phân vùng tháng theo `period_start`; Trigger: `tg_kpi_value_lineage_append_only`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `value_id` | `uuid` | Giá trị chỉ tiêu `kpi_indicator_value.id` (tham chiếu logic, bảng đích phân vùng). |
| `source_kind` | `varchar(12)` | Giá trị: `OBSERVATION`, `MANUAL_VALUE`, `INDICATOR`, `PERIOD_VALUE`. |
| `observation_id` | `uuid, NULL` | Quan sát `kpi_observation.id` (tham chiếu logic, bảng đích phân vùng). |
| `ref_value_id` | `uuid, NULL` | Giá trị chỉ tiêu của kỳ con (tháng) dùng để gộp lên kỳ quý, năm (tham chiếu logic). |

: Cột nổi bật của bảng `kpi_value_lineage`

Cột khác: `period_start` date; `run_id` uuid; `seq` smallint; `variable_name` v(63); `metric_code` v(128); `manual_value_id` uuid; `ref_indicator_id` uuid; `used_value` num(24,6).

### 3.17. `kpi_group_score`

::: dac-ta
**Mục đích.** EN-16-17 Điểm nhóm theo kỳ và lần tổng hợp: điểm 0…100 từ các chỉ tiêu của nhóm theo trọng số, số chỉ tiêu có số, độ đầy đủ, xu hướng và chênh lệch so kỳ trước (FR-16-007, 022, 038). Kỳ CLOSED không nhận điểm mới.

**FR phục vụ.** FR-16-007, 022, 037, 038; EN-16-17.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_group_score_run` (tenant_id, run_id, group_code), `uq_kpi_group_score_current` (tenant_id, period_id, group_code) có điều kiện.

**Khóa ngoại.** (tenant_id, period_id) → `kpi_reporting_period`, (tenant_id, run_id) → `kpi_aggregation_run`, (tenant_id, group_code) → `kpi_indicator_group`.

**Ràng buộc CHECK.** `ck_kpi_group_score_` + `tenant`, `score`, `weight`, `counts`, `completeness`, `complete`, `trend`.

**Chỉ mục.** `ix_kpi_group_score_series`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `period_id`, `run_id`, `group_code`; Trigger: `tg_kpi_group_score_period`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `completeness` | `varchar(9)` | Giá trị: `COMPLETE`, `PARTIAL`, `NO_DATA`. |
| `trend` | `varchar(8), NULL` | Giá trị: `UP`, `DOWN`, `FLAT`. |

: Cột nổi bật của bảng `kpi_group_score`

Cột khác: `period_id` uuid; `run_id` uuid; `group_code` v(16); `score` num(6,2); `weight` num(5,2); `indicator_total` smallint; `indicator_with_value` smallint; `delta` num(6,2); `is_current` bool.

### 3.18. `kpi_report_template`

::: dac-ta
**Mục đích.** EN-16-19 Mẫu báo cáo có phiên bản: bố cục phần (SUMMARY, GROUP, INDICATOR_TABLE, CHART, NARRATIVE, ANNEX), định dạng xuất (PDF, XLSX, CSV, JSON) và cấu hình bố cục (FR-16-025). Dòng COMMON do PLATFORM quản, mọi tenant đọc được (mẫu RLS S). ACTIVE bất biến, mỗi mã một phiên bản ACTIVE.

**FR phục vụ.** FR-16-025; EN-16-19.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_report_template_version` (tenant_id, template_code, version_no), `uq_kpi_report_template_active` (tenant_id, template_code) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_kpi_report_template_` + `tenant`, `code`, `no`, `state`, `sections`, `formats`, `layout`, `active`.

**Chỉ mục.** Không thêm.

**Cách ly tenant.** Mẫu S (1.2): đọc thêm dòng `COMMON`.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `template_code`, `version_no`; Trigger: `tg_kpi_report_template_frozen`, `tg_kpi_report_template_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `state` | `varchar(8), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `ACTIVE`, `RETIRED`. |

: Cột nổi bật của bảng `kpi_report_template`

Cột khác: `template_code` v(63); `version_no` int; `name` v(255); `sections` text[]; `formats` text[]; `layout` jsonb; `description` v(2000); `activated_at` tstz.

### 3.19. `kpi_report`

::: dac-ta
**Mục đích.** EN-16-20 Báo cáo (phần đầu): mã `bc-thang-2026-10`, loại PERIODIC, AD_HOC, NATIONAL, kỳ hoặc khoảng thời gian, mẫu; phản chiếu trạng thái phiên bản mới nhất và nhớ phiên bản đang công bố (FR-16-026, 031, 032). Nội dung nằm ở `kpi_report_version`; đính chính tạo phiên bản mới, không sửa bản đã công bố.

**FR phục vụ.** FR-16-026, 031, 032; EN-16-20.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_report_code` (tenant_id, report_code).

**Khóa ngoại.** (tenant_id, period_id) → `kpi_reporting_period`, (tenant_id, template_id) → `kpi_report_template`.

**Ràng buộc CHECK.** `ck_kpi_report_` + `tenant`, `code`, `type`, `state`, `scope`, `versions`.

**Chỉ mục.** `ix_kpi_report_period`, `ix_kpi_report_state`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `report_code`, `report_type`, `period_id`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `report_type` | `varchar(8)` | Giá trị: `PERIODIC`, `AD_HOC`, `NATIONAL`. |
| `state` | `varchar(17), mặc định 'DRAFT'` | Bản sao trạng thái của phiên bản mới nhất, do trigger `tg_kpi_report_version_sync` cập nhật; nguồn chuẩn là `kpi_report_version.state`. Giá trị: `DRAFT`, `IN_REVIEW`, `APPROVED`, `PUBLISHED`, `CHANGES_REQUESTED`, `SUPERSEDED`, `WITHDRAWN`. |
| `published_version_no` | `integer, NULL` | Phiên bản đang PUBLISHED (NULL nếu chưa công bố hoặc đã SUPERSEDED, WITHDRAWN). |

: Cột nổi bật của bảng `kpi_report`

Cột khác: `report_code` v(63); `title` v(255); `period_id` uuid; `range_from` date; `range_to` date; `template_id` uuid; `current_version_no` int.

### 3.20. `kpi_report_version`

::: dac-ta
**Mục đích.** EN-16-21, EN-16-22 Phiên bản báo cáo: ảnh chụp giá trị chỉ tiêu, thuyết minh, mẫu, lần tổng hợp nguồn; vòng đời DRAFT, IN_REVIEW, APPROVED, PUBLISHED, CHANGES_REQUESTED, SUPERSEDED, WITHDRAWN (FR-16-026, 027, 028, 029, 030). Khi PUBLISHED bất biến bằng trigger: nội dung, mã băm, tệp PDF ký số (lưu WORM, giữ theo `16.report.retention-years`) không đổi; đính chính bằng phiên bản mới. Người duyệt khác người lập.

**FR phục vụ.** FR-16-026, 027, 028, 029, 030, 035, 036, 054, 057; EN-16-21, EN-16-22.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_report_version_no` (tenant_id, report_id, version_no), `uq_kpi_report_version_published` (tenant_id, report_id) có điều kiện.

**Khóa ngoại.** (tenant_id, report_id) → `kpi_report`, (tenant_id, template_id) → `kpi_report_template`, (tenant_id, run_id) → `kpi_aggregation_run`.

**Ràng buộc CHECK.** `ck_kpi_report_version_` + `tenant`, `no`, `state`, `completeness`, `snapshot`, `hash`, `review`, `approved`, `published`, `mandatory`, `correction`, `correction_reason`, `withdrawn`, `changes`.

**Chỉ mục.** `ix_kpi_report_version_inbox`, `ix_kpi_report_version_published`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `report_id`, `version_no`, `prepared_by`; Trigger: `tg_kpi_report_version_frozen`, `tg_kpi_report_version_frozen_review`, `tg_kpi_report_version_gate`, `tg_kpi_report_version_no_delete`, `tg_kpi_report_version_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `state` | `varchar(17), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `IN_REVIEW`, `APPROVED`, `PUBLISHED`, `CHANGES_REQUESTED`, `SUPERSEDED`, `WITHDRAWN`. |
| `snapshot` | `jsonb, mặc định '{}'` | Ảnh chụp bất biến: giá trị, trạng thái, điểm nhóm, phiên bản công thức của từng chỉ tiêu tại thời điểm gửi duyệt; không đọc lại bảng giá trị khi xem bản đã công bố. |
| `completeness` | `varchar(9), mặc định 'COMPLETE'` | Giá trị: `COMPLETE`, `PARTIAL`, `NO_DATA`. |
| `missing_mandatory` | `boolean, mặc định false` | Còn chỉ tiêu bắt buộc thiếu nguồn: CHECK ck_kpi_report_version_mandatory chặn công bố. |
| `prepared_by` | `varchar(64)` | Người lập; `approved_by` phải khác khi 16.report.four-eyes bật (trigger `tg_kpi_report_version_gate`). |
| `content_hash` | `bytea, NULL` | SHA-256 (32 byte) của tệp PDF công bố; chữ ký số trong `kpi_report_signature.signed_hash` phải trùng. |
| `object_ref` | `varchar(512), NULL` | Đối tượng PDF ký số trên Ceph RGW (WORM, ADR đề xuất dải 160…164); không lưu tệp trong PostgreSQL. |
| `retain_until` | `date, NULL` | Ngày hết hạn giữ = ngày công bố + 16.report.retention-years (mặc định 10 năm). |

: Cột nổi bật của bảng `kpi_report_version`

Cột khác: `report_id` uuid; `version_no` int; `template_id` uuid; `run_id` uuid; `narrative` jsonb; `prepared_at` tstz; `submitted_at` tstz; `approved_by` v(64); `approved_at` tstz; `published_by` v(64); `published_at` tstz; `correction_of_version_no` int; `correction_reason` v(2000); `decision_comment` v(2000); `document_number` v(64); `recipients_note` v(2000); `withdrawn_by` v(64); `withdrawn_at` tstz; `withdraw_reason` v(2000).

### 3.21. `kpi_report_approval`

::: dac-ta
**Mục đích.** EN-16-21 Nhật ký duyệt báo cáo: mỗi hành động SUBMIT, REQUEST_CHANGES, APPROVE, PUBLISH, WITHDRAW, CORRECT của một phiên bản, kèm người làm và ý kiến (FR-16-028, 029, 030). Chỉ thêm. Người lập báo cáo không ghi được APPROVE cho báo cáo của mình khi 16.report.four-eyes bật.

**FR phục vụ.** FR-16-028, 029, 030; EN-16-21.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, report_version_id) → `kpi_report_version`.

**Ràng buộc CHECK.** `ck_kpi_report_approval_` + `tenant`, `action`, `comment`.

**Chỉ mục.** `ix_kpi_report_approval_version`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Trigger: `tg_kpi_report_approval_append_only`, `tg_kpi_report_approval_gate`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `action` | `varchar(15)` | Giá trị: `SUBMIT`, `REQUEST_CHANGES`, `APPROVE`, `PUBLISH`, `WITHDRAW`, `CORRECT`. |

: Cột nổi bật của bảng `kpi_report_approval`

Cột khác: `report_version_id` uuid; `actor` v(64); `acted_at` tstz; `comment` v(2000).

### 3.22. `kpi_report_signature`

::: dac-ta
**Mục đích.** EN-16-21 Chữ ký số của bản công bố: người ký, thời điểm, định dạng, số sê-ri chứng thư, tham chiếu tệp ký và mã băm đã ký (FR-16-029, 036). Chỉ thêm; mã băm đã ký phải trùng `content_hash` của phiên bản khi công bố.

**FR phục vụ.** FR-16-029, 036; EN-16-21.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, report_version_id) → `kpi_report_version`.

**Ràng buộc CHECK.** `ck_kpi_report_signature_` + `tenant`, `format`, `hash`.

**Chỉ mục.** `ix_kpi_report_signature_version`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Trigger: `tg_kpi_report_signature_append_only`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `signature_format` | `varchar(16), mặc định 'PDF_SIGNED'` | Giá trị: `PDF_SIGNED`, `DETACHED`. |
| `certificate_serial` | `varchar(64)` | Số sê-ri chứng thư số của người ký (ký số theo NĐ 30/2020 do PH-12 thực hiện). |
| `signature_ref` | `varchar(512)` | Đối tượng chữ ký hoặc PDF đã ký trên Ceph RGW; khóa ký nằm ở PH-12 (OpenBao), PH-16 không giữ. |

: Cột nổi bật của bảng `kpi_report_signature`

Cột khác: `report_version_id` uuid; `signer` v(64); `signed_at` tstz; `signed_hash` bytea.

### 3.23. `kpi_distribution`

::: dac-ta
**Mục đích.** EN-16-24 Danh sách phân phối báo cáo: người nhận (người dùng, nhóm, thư điện tử công vụ qua kênh thông báo PH-13), định dạng, loại báo cáo và kỳ gửi theo lịch (FR-16-034).

**FR phục vụ.** FR-16-034; EN-16-24.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_distribution_code` (tenant_id, distribution_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_kpi_distribution_` + `tenant`, `code`, `type`, `period`, `formats`, `recipients`.

**Chỉ mục.** Không thêm.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `distribution_code`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `report_type` | `varchar(8), mặc định 'PERIODIC'` | Giá trị: `PERIODIC`, `AD_HOC`, `NATIONAL`. |
| `period_type` | `varchar(8), NULL` | Giá trị: `MONTH`, `QUARTER`, `YEAR`. |
| `recipients` | `jsonb, mặc định '[]'` | Mảng {type: USER\|GROUP\|EMAIL, ref}; thư điện tử chỉ địa chỉ công vụ; gửi qua PH-13, PH-16 không giữ cấu hình thư. |

: Cột nổi bật của bảng `kpi_distribution`

Cột khác: `distribution_code` v(63); `name` v(255); `formats` text[]; `send_on_publish` bool; `enabled` bool.

### 3.24. `kpi_delivery`

::: dac-ta
**Mục đích.** EN-16-25 Lần giao báo cáo: mỗi người nhận, định dạng của một phiên bản đã công bố qua một danh sách phân phối; theo dõi PENDING, SENT, FAILED và số lần thử (FR-16-034).

**FR phục vụ.** FR-16-034; EN-16-25.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_delivery_recipient` (tenant_id, report_version_id, distribution_id, recipient_type, recipient_ref, format).

**Khóa ngoại.** (tenant_id, report_version_id) → `kpi_report_version`, (tenant_id, distribution_id) → `kpi_distribution`.

**Ràng buộc CHECK.** `ck_kpi_delivery_` + `tenant`, `recipient`, `format`, `state`, `attempt`, `sent`, `failed`, `error`.

**Chỉ mục.** `ix_kpi_delivery_pending`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `report_version_id`, `distribution_id`, `recipient_type`, `recipient_ref`, `format`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `recipient_type` | `varchar(5)` | Giá trị: `USER`, `GROUP`, `EMAIL`. |
| `format` | `varchar(4), mặc định 'PDF'` | Giá trị: `PDF`, `XLSX`, `CSV`, `JSON`. |
| `state` | `varchar(7), mặc định 'PENDING'` | Giá trị: `PENDING`, `SENT`, `FAILED`. |

: Cột nổi bật của bảng `kpi_delivery`

Cột khác: `report_version_id` uuid; `distribution_id` uuid; `recipient_ref` v(255); `attempt` smallint; `last_attempt_at` tstz; `sent_at` tstz; `error_code` v(11).

### 3.25. `kpi_export_job`

::: dac-ta
**Mục đích.** EN-16-23 Lệnh xuất: xuất bản báo cáo, bảng chỉ tiêu của kỳ hoặc sổ kiến trúc ra PDF, XLSX, CSV, JSON lên Ceph RGW; QUEUED, RUNNING, SUCCEEDED, FAILED, EXPIRED; liên kết tải hết hạn sau `16.export.link-hours` (FR-16-033, 036, 049).

**FR phục vụ.** FR-16-033, 036, 049; EN-16-23.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, report_version_id) → `kpi_report_version`, (tenant_id, period_id) → `kpi_reporting_period`.

**Ràng buộc CHECK.** `ck_kpi_export_job_` + `tenant`, `subject`, `format`, `state`, `rows`, `hash`, `ready`, `failed`, `downloads`, `error`.

**Chỉ mục.** `ix_kpi_export_job_state`, `ix_kpi_export_job_expiry`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `subject_type`, `report_version_id`, `period_id`, `format`, `requested_by`; Trigger: `tg_kpi_export_job_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `subject_type` | `varchar(16)` | Giá trị: `REPORT`, `INDICATOR_VALUES`, `OBSERVATIONS`, `ARCH_REGISTRY`, `ARCH_GRAPH`. |
| `format` | `varchar(4)` | Giá trị: `PDF`, `XLSX`, `CSV`, `JSON`. |
| `state` | `varchar(9), mặc định 'QUEUED'` | Giá trị: `QUEUED`, `RUNNING`, `SUCCEEDED`, `FAILED`, `EXPIRED`. |
| `row_count` | `bigint, NULL` | Không vượt 16.export.max-rows (mặc định 100000) do dịch vụ kiểm. |

: Cột nổi bật của bảng `kpi_export_job`

Cột khác: `report_version_id` uuid; `period_id` uuid; `filter` jsonb; `requested_by` v(64); `started_at` tstz; `finished_at` tstz; `object_ref` v(512); `content_hash` bytea; `expires_at` tstz; `download_count` int; `error_code` v(11).

### 3.26. `kpi_arch_component`

::: dac-ta
**Mục đích.** EN-16-26 Thành phần kiến trúc của sổ kiến trúc: HTTT, API, luồng, topic, bộ điều hợp, dịch vụ nền tảng, liên kết quốc gia; vòng đời PLANNED, ACTIVE, DEPRECATED, RETIRED, trạng thái vận hành UP, DEGRADED, DOWN, UNKNOWN, nguồn gốc AUTO hoặc MANUAL, mức tuân thủ hiện hành (FR-16-043, 044, 045, 046, 048). Không xóa, chỉ ngừng.

**FR phục vụ.** FR-16-043, 044, 045, 046, 048, 054; EN-16-26.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_arch_component_code` (tenant_id, component_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_kpi_arch_component_` + `tenant`, `code`, `type`, `lifecycle`, `ops`, `origin`, `phase`, `owner`, `compliance`, `retire`.

**Chỉ mục.** `ix_kpi_arch_component_type`, `ix_kpi_arch_component_compliance`, `ix_kpi_arch_component_orphan`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `component_code`, `component_type`; Trigger: `tg_kpi_arch_component_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `component_type` | `varchar(16)` | Giá trị: `HTTT`, `API`, `FLOW`, `TOPIC`, `ADAPTER`, `PLATFORM_SERVICE`, `NATIONAL_LINK`. |
| `lifecycle` | `varchar(10), mặc định 'PLANNED'` | Giá trị: `PLANNED`, `ACTIVE`, `DEPRECATED`, `RETIRED`. |
| `ops_status` | `varchar(8), mặc định 'UNKNOWN'` | Giá trị: `UP`, `DEGRADED`, `DOWN`, `UNKNOWN`. |
| `origin` | `varchar(6), mặc định 'MANUAL'` | AUTO: tự đăng ký từ sự kiện phân hệ nguồn hoặc `arch.register`; MANUAL: khai báo tay (FR-16-045). Giá trị: `AUTO`, `MANUAL`. |
| `compliance_level` | `varchar(13), mặc định 'NOT_ASSESSED'` | Bản sao mức của đánh giá CONFIRMED mới nhất hoặc EXEMPTED khi có miễn trừ hiệu lực; nguồn chuẩn ở `kpi_compliance_assessment`. Giá trị: `NOT_ASSESSED`, `COMPLIANT`, `PARTIAL`, `NON_COMPLIANT`, `EXEMPTED`. |
| `orphaned` | `boolean, mặc định false` | Đối chiếu với phân hệ nguồn thấy thành phần AUTO không còn ở nguồn (FR-16-048). |

: Cột nổi bật của bảng `kpi_arch_component`

Cột khác: `component_code` v(63); `name` v(255); `ops_updated_at` tstz; `owner_org_code` v(63); `source_phase` v(5); `source_ref` v(255); `current_version_label` v(32); `last_synced_at` tstz; `retire_reason` v(2000); `description` v(2000).

### 3.27. `kpi_arch_component_version`

::: dac-ta
**Mục đích.** EN-16-27 Phiên bản thành phần kiến trúc: nhãn phiên bản, trạng thái vòng đời của phiên bản, ngày phát hành, mã băm nội dung mô tả dùng cho gói gửi quốc gia (FR-16-045, 052).

**FR phục vụ.** FR-16-045, 052; EN-16-27.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_arch_component_version` (tenant_id, component_id, version_label).

**Khóa ngoại.** (tenant_id, component_id) → `kpi_arch_component`.

**Ràng buộc CHECK.** `ck_kpi_arch_component_version_` + `tenant`, `label`, `lifecycle`, `origin`, `hash`.

**Chỉ mục.** Không thêm.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `component_id`, `version_label`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `lifecycle` | `varchar(10), mặc định 'PLANNED'` | Giá trị: `PLANNED`, `ACTIVE`, `DEPRECATED`, `RETIRED`. |
| `origin` | `varchar(6), mặc định 'MANUAL'` | Giá trị: `AUTO`, `MANUAL`. |

: Cột nổi bật của bảng `kpi_arch_component_version`

Cột khác: `component_id` uuid; `version_label` v(32); `released_on` date; `spec_ref` v(255); `content_hash` bytea; `change_note` v(2000).

### 3.28. `kpi_arch_dependency`

::: dac-ta
**Mục đích.** EN-16-28 Phụ thuộc giữa hai thành phần: gọi, phát, đăng ký nhận, chạy trên, phụ thuộc; phục vụ sơ đồ phụ thuộc và phân tích ảnh hưởng (FR-16-045, 049). Gỡ phụ thuộc bằng cờ `removed`, không xóa dòng.

**FR phục vụ.** FR-16-045, 049; EN-16-28.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_arch_dependency` (tenant_id, from_component_id, to_component_id, dependency_type).

**Khóa ngoại.** (tenant_id, from_component_id) → `kpi_arch_component`, (tenant_id, to_component_id) → `kpi_arch_component`.

**Ràng buộc CHECK.** `ck_kpi_arch_dependency_` + `tenant`, `self`, `type`, `origin`.

**Chỉ mục.** `ix_kpi_arch_dependency_to`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `from_component_id`, `to_component_id`, `dependency_type`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `dependency_type` | `varchar(10)` | Giá trị: `CALLS`, `PUBLISHES`, `SUBSCRIBES`, `HOSTS`, `DEPENDS_ON`. |
| `origin` | `varchar(6), mặc định 'MANUAL'` | Giá trị: `AUTO`, `MANUAL`. |

: Cột nổi bật của bảng `kpi_arch_dependency`

Cột khác: `from_component_id` uuid; `to_component_id` uuid; `removed` bool; `description` v(2000).

### 3.29. `kpi_arch_reconciliation`

::: dac-ta
**Mục đích.** EN-16-33 Lần đối chiếu sổ kiến trúc với phân hệ nguồn (hằng tuần hoặc chạy tay): RUNNING, SUCCEEDED, PARTIAL (có phân hệ không trả lời), FAILED; mỗi tenant tối đa một lần đang chạy (ERR-16-056) (FR-16-048).

**FR phục vụ.** FR-16-048; EN-16-33.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_arch_reconciliation_running` (tenant_id) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_kpi_arch_reconciliation_` + `tenant`, `state`, `types`, `finished`, `partial`, `count`.

**Chỉ mục.** `ix_kpi_arch_reconciliation_time`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `component_types`, `started_by`, `started_at`; Trigger: `tg_kpi_arch_reconciliation_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `state` | `varchar(9), mặc định 'RUNNING'` | Giá trị: `RUNNING`, `SUCCEEDED`, `PARTIAL`, `FAILED`. |

: Cột nổi bật của bảng `kpi_arch_reconciliation`

Cột khác: `component_types` text[]; `started_by` v(64); `started_at` tstz; `finished_at` tstz; `item_count` int; `skipped_phases` text[].

### 3.30. `kpi_arch_recon_item`

::: dac-ta
**Mục đích.** EN-16-33 Mục lệch của lần đối chiếu: MISSING (nguồn có, sổ không), ORPHAN (sổ có, nguồn không), MISMATCH (vòng đời, phiên bản khác); xử lý OPEN, REGISTERED, RETIRED, UPDATED hoặc IGNORED kèm lý do (FR-16-048, ERR-16-120).

**FR phục vụ.** FR-16-048; EN-16-33.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_arch_recon_item` (tenant_id, recon_id, item_kind, component_code).

**Khóa ngoại.** (tenant_id, recon_id) → `kpi_arch_reconciliation`, (tenant_id, component_id) → `kpi_arch_component`.

**Ràng buộc CHECK.** `ck_kpi_arch_recon_item_` + `tenant`, `kind`, `resolution`, `phase`, `orphan`, `diff`, `resolved`, `ignored`.

**Chỉ mục.** `ix_kpi_arch_recon_item_open`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `recon_id`, `item_kind`, `component_code`, `source_phase`, `source_ref`, `diff`; Trigger: `tg_kpi_arch_recon_item_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `item_kind` | `varchar(8)` | Giá trị: `MISSING`, `ORPHAN`, `MISMATCH`. |
| `resolution` | `varchar(10), mặc định 'OPEN'` | Giá trị: `OPEN`, `REGISTERED`, `RETIRED`, `UPDATED`, `IGNORED`. |

: Cột nổi bật của bảng `kpi_arch_recon_item`

Cột khác: `recon_id` uuid; `component_code` v(63); `component_id` uuid; `source_phase` v(5); `source_ref` v(255); `diff` jsonb; `resolution_reason` v(2000); `resolved_by` v(64); `resolved_at` tstz.

### 3.31. `kpi_compliance_criterion`

::: dac-ta
**Mục đích.** EN-16-29, EN-16-30 Tiêu chí tuân thủ kiến trúc: bộ tiêu chí cấu hình có phiên bản, áp cho loại thành phần, có trọng số và cờ bắt buộc; bộ mẫu COMMON theo Khung kiến trúc CPĐT 3.0 (CMP-LAW-10) và dự thảo Khung kiến trúc tổng thể quốc gia số (CMP-LAW-11) khi ban hành (FR-16-047). ACTIVE bất biến, mỗi mã một phiên bản ACTIVE. Dòng COMMON mọi tenant đọc được (mẫu RLS S).

**FR phục vụ.** FR-16-047; EN-16-29, EN-16-30.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_compliance_criterion_version` (tenant_id, criterion_code, version_no), `uq_kpi_compliance_criterion_active` (tenant_id, criterion_code) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_kpi_compliance_criterion_` + `tenant`, `code`, `no`, `applies`, `weight`, `state`, `active`.

**Chỉ mục.** Không thêm.

**Cách ly tenant.** Mẫu S (1.2): đọc thêm dòng `COMMON`.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `criterion_code`, `version_no`; Trigger: `tg_kpi_compliance_criterion_frozen`, `tg_kpi_compliance_criterion_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `framework_ref` | `varchar(64), NULL` | Mã CMP-LAW hoặc điều khoản khung kiến trúc nếu có; để NULL khi tiêu chí tối thiểu của sổ chưa đối chiếu khung (Q16-53). |
| `state` | `varchar(10), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `ACTIVE`, `SUPERSEDED`. |

: Cột nổi bật của bảng `kpi_compliance_criterion`

Cột khác: `criterion_code` v(32); `version_no` int; `name` v(255); `description` v(2000); `applies_to` text[]; `mandatory` bool; `weight` num(5,4); `activated_at` tstz.

### 3.32. `kpi_compliance_assessment`

::: dac-ta
**Mục đích.** EN-16-31 Đánh giá tuân thủ một thành phần (hoặc một phiên bản) theo bộ tiêu chí: DRAFT, SUBMITTED, CONFIRMED, REJECTED, kết quả COMPLIANT, PARTIAL, NON_COMPLIANT; người xác nhận khác người đánh giá (FR-16-047). CONFIRMED và REJECTED không đổi nội dung.

**FR phục vụ.** FR-16-047; EN-16-31.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, component_id) → `kpi_arch_component`, (tenant_id, component_version_id) → `kpi_arch_component_version`.

**Ràng buộc CHECK.** `ck_kpi_compliance_assessment_` + `tenant`, `state`, `level`, `score`, `four_eyes`, `submitted`, `confirmed`, `rejected`.

**Chỉ mục.** `ix_kpi_compliance_assessment_component`, `ix_kpi_compliance_assessment_inbox`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `component_id`, `assessed_by`; Trigger: `tg_kpi_compliance_assessment_frozen`, `tg_kpi_compliance_assessment_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `state` | `varchar(9), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `SUBMITTED`, `CONFIRMED`, `REJECTED`. |
| `level_result` | `varchar(13), NULL` | Giá trị: `COMPLIANT`, `PARTIAL`, `NON_COMPLIANT`. |

: Cột nổi bật của bảng `kpi_compliance_assessment`

Cột khác: `component_id` uuid; `component_version_id` uuid; `score` num(5,2); `summary` v(4000); `assessed_by` v(64); `assessed_at` tstz; `submitted_at` tstz; `confirmed_by` v(64); `confirmed_at` tstz; `decision_comment` v(2000).

### 3.33. `kpi_compliance_item`

::: dac-ta
**Mục đích.** EN-16-31 Mục đánh giá: kết quả từng tiêu chí của một đánh giá PASS (đạt), FAIL (không đạt), NA (không áp dụng) kèm bằng chứng và ghi chú (FR-16-047). Chỉ sửa khi đánh giá còn DRAFT.

**FR phục vụ.** FR-16-047; EN-16-31.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_compliance_item` (tenant_id, assessment_id, criterion_id).

**Khóa ngoại.** (tenant_id, assessment_id) → `kpi_compliance_assessment`, (tenant_id, criterion_id) → `kpi_compliance_criterion`.

**Ràng buộc CHECK.** `ck_kpi_compliance_item_` + `tenant`, `result`, `score`, `note`.

**Chỉ mục.** Không thêm.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `assessment_id`, `criterion_id`; Trigger: `tg_kpi_compliance_item_child_frozen`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `result` | `varchar(4)` | Giá trị: `PASS`, `FAIL`, `NA`. |

: Cột nổi bật của bảng `kpi_compliance_item`

Cột khác: `assessment_id` uuid; `criterion_id` uuid; `evidence_ref` v(512); `note` v(2000); `item_score` num(5,2).

### 3.34. `kpi_compliance_waiver`

::: dac-ta
**Mục đích.** EN-16-32 Miễn trừ có hạn: miễn một tiêu chí (hoặc toàn bộ) cho một thành phần, lý do từ 50 ký tự, hạn không quá 366 ngày (tham số 16.compliance.waiver-max-days mặc định 180 ngày do dịch vụ kiểm), người duyệt khác người đề nghị (FR-16-047). PENDING_APPROVAL, ACTIVE, EXPIRED, REVOKED, REJECTED.

**FR phục vụ.** FR-16-047; EN-16-32.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, component_id) → `kpi_arch_component`, (tenant_id, criterion_id) → `kpi_compliance_criterion`.

**Ràng buộc CHECK.** `ck_kpi_compliance_waiver_` + `tenant`, `state`, `period`, `reason`, `four_eyes`, `active`, `decision`.

**Chỉ mục.** `ix_kpi_compliance_waiver_component`, `ix_kpi_compliance_waiver_expiry`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `component_id`, `criterion_id`, `requested_by`; Trigger: `tg_kpi_compliance_waiver_frozen`, `tg_kpi_compliance_waiver_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `state` | `varchar(16), mặc định 'PENDING_APPROVAL'` | Giá trị: `PENDING_APPROVAL`, `ACTIVE`, `EXPIRED`, `REVOKED`, `REJECTED`. |

: Cột nổi bật của bảng `kpi_compliance_waiver`

Cột khác: `component_id` uuid; `criterion_id` uuid; `reason` v(2000); `valid_from` date; `valid_to` date; `requested_by` v(64); `approved_by` v(64); `approved_at` tstz; `decision_comment` v(2000).

### 3.35. `kpi_national_template`

::: dac-ta
**Mục đích.** EN-16-34 Mẫu gói quốc gia có phiên bản: cách ánh xạ chỉ tiêu hoặc sổ kiến trúc sang lược đồ của nền tảng quốc gia, là cấu hình ngoài vì khung quốc gia chưa ban hành (CMP-LAW-11 dự thảo, ADR đề xuất dải 160…164); kênh gửi là PH-14 (FR-16-050). ACTIVE bất biến, mỗi mã một phiên bản ACTIVE. Dòng COMMON do PLATFORM quản, mọi tenant đọc được (mẫu RLS S).

**FR phục vụ.** FR-16-050; EN-16-34.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_national_template_version` (tenant_id, template_code, version_no), `uq_kpi_national_template_active` (tenant_id, template_code) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_kpi_national_template_` + `tenant`, `code`, `no`, `type`, `state`, `mapping`, `active`.

**Chỉ mục.** Không thêm.

**Cách ly tenant.** Mẫu S (1.2): đọc thêm dòng `COMMON`.

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `template_code`, `version_no`, `submission_type`; Trigger: `tg_kpi_national_template_frozen`, `tg_kpi_national_template_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `submission_type` | `varchar(13)` | Giá trị: `KPI_REPORT`, `ARCH_REGISTRY`. |
| `state` | `varchar(10), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `ACTIVE`, `SUPERSEDED`. |
| `mapping` | `jsonb, mặc định '{}'` | Ánh xạ trường nội bộ sang lược đồ nền tảng quốc gia; thay đổi khi khung ban hành chỉ cần phiên bản mẫu mới, không đổi mã. |

: Cột nổi bật của bảng `kpi_national_template`

Cột khác: `template_code` v(63); `version_no` int; `name` v(255); `schema_ref` v(255); `channel_ref` v(64); `effective_from` date; `approved_by` v(64); `activated_at` tstz; `description` v(2000).

### 3.36. `kpi_national_submission`

::: dac-ta
**Mục đích.** EN-16-35 Gói gửi quốc gia: báo cáo chỉ tiêu (KPI_REPORT) hoặc sổ kiến trúc (ARCH_REGISTRY) gửi qua PH-14; PENDING, SENDING, SENT, ACKNOWLEDGED, REJECTED, FAILED; idempotent theo `report_code` + `report_version_no` hoặc `component_code` + `version_label` + `content_hash` (FR-16-051, 052, 054). Chỉ tạo khi `16.national.enabled` bật; báo cáo phải PUBLISHED.

**FR phục vụ.** FR-16-051, 052, 054; EN-16-35.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_national_submission_report` (tenant_id, report_code, report_version_no) có điều kiện, `uq_kpi_national_submission_arch` (tenant_id, component_code, version_label, content_hash) có điều kiện.

**Khóa ngoại.** (tenant_id, template_id) → `kpi_national_template`, (tenant_id, report_version_id) → `kpi_report_version`, (tenant_id, component_version_id) → `kpi_arch_component_version`.

**Ràng buộc CHECK.** `ck_kpi_national_submission_` + `tenant`, `type`, `state`, `subject`, `hash`, `attempt`, `sent`, `ack`, `failed`, `error`.

**Chỉ mục.** `ix_kpi_national_submission_state`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `submission_type`, `template_id`, `report_version_id`, `report_code`, `report_version_no`, `component_version_id`, `component_code`, `version_label`, `content_hash`, `submitted_by`; Trigger: `tg_kpi_national_submission_gate`, `tg_kpi_national_submission_transition`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `submission_type` | `varchar(13)` | Giá trị: `KPI_REPORT`, `ARCH_REGISTRY`. |
| `state` | `varchar(12), mặc định 'PENDING'` | Giá trị: `PENDING`, `SENDING`, `SENT`, `ACKNOWLEDGED`, `REJECTED`, `FAILED`. |
| `attempt_count` | `smallint, mặc định 0` | Số lần gửi; không vượt 16.national.retry-max + 1 do dịch vụ kiểm. |
| `channel_ref` | `varchar(128), NULL` | Mã giao dịch của PH-14 (EVT-14-11, 12); PH-16 không giữ thông tin xác thực quốc gia (OpenBao ở PH-14). |

: Cột nổi bật của bảng `kpi_national_submission`

Cột khác: `template_id` uuid; `report_version_id` uuid; `report_code` v(63); `report_version_no` int; `component_version_id` uuid; `component_code` v(63); `version_label` v(32); `content_hash` bytea; `submitted_by` v(64); `sent_at` tstz; `ack_ref` v(128); `ack_at` tstz; `last_error_code` v(11); `last_error_detail` v(2000).

### 3.37. `kpi_national_submission_log`

::: dac-ta
**Mục đích.** EN-16-36 Nhật ký nộp: bằng chứng từng bước gửi quốc gia (tạo, gửi, biên nhận, từ chối, lỗi, gửi lại) kèm băm yêu cầu, băm phản hồi, mã giao dịch PH-14. Chỉ thêm, không sửa, xóa kể cả chủ schema; giữ như báo cáo công bố (FR-16-053).

**FR phục vụ.** FR-16-053; EN-16-36.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_national_submission_log_seq` (tenant_id, submission_id, seq).

**Khóa ngoại.** (tenant_id, submission_id) → `kpi_national_submission`.

**Ràng buộc CHECK.** `ck_kpi_national_submission_log_` + `tenant`, `seq`, `event`, `state`, `req_hash`, `resp_hash`, `error`.

**Chỉ mục.** `ix_kpi_national_submission_log_time`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Trigger: `tg_kpi_national_submission_log_append_only`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `event_type` | `varchar(12)` | Giá trị: `CREATED`, `SENDING`, `SENT`, `ACKNOWLEDGED`, `REJECTED`, `FAILED`, `RETRY`. |
| `state_after` | `varchar(12)` | Giá trị: `PENDING`, `SENDING`, `SENT`, `ACKNOWLEDGED`, `REJECTED`, `FAILED`. |

: Cột nổi bật của bảng `kpi_national_submission_log`

Cột khác: `submission_id` uuid; `seq` int; `actor` v(64); `occurred_at` tstz; `request_hash` bytea; `response_hash` bytea; `channel_ref` v(128); `error_code` v(11); `detail` v(2000).

### 3.38. `kpi_tenant_setting`

::: dac-ta
**Mục đích.** EN-16-39 Tham số phân hệ theo tenant: 25 tham số 16.* của FRS §8.2 (kỳ, lịch tổng hợp, độ tươi nguồn, số liệu trễ, bằng chứng số liệu tay, bốn mắt, ký số, lưu giữ, xuất, gửi quốc gia, so sánh, hạn miễn trừ, ghim Tổng quan) (FR-16-055, 057). Chỉ nhận mã đã khai báo, kiểu giá trị đúng theo mã; trigger của các bảng khác đọc tham số này.

**FR phục vụ.** FR-16-055, 057; EN-16-39.

**Khóa chính.** (id).

**Duy nhất.** `uq_kpi_tenant_setting_code` (tenant_id, param_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_kpi_tenant_setting_` + `tenant`, `code`, `type`.

**Chỉ mục.** Không thêm.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Bất biến: `tenant_id`, `param_code`.

**Ghi chú.** ETag `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `param_code` | `varchar(64)` | Giá trị: . |

: Cột nổi bật của bảng `kpi_tenant_setting`

Cột khác: `value` jsonb; `description` v(500).

### 3.39. `outbox_event`

::: dac-ta
**Mục đích.** Hạ tầng. Outbox (SAD 7.3) cho EVT-16-01…14 và bản ghi kiểm toán gửi PH-13 (FR-16-056, 058). Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL và định tuyến theo topic `{tenant}.kpi.{thực-thể}.{sự-kiện}.v1`. Dọn sau 3 ngày.

**FR phục vụ.** FR-16-021, 056, 058.

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_event_` + `tenant`, `prefix`, `topic`, `trace`, `payload`.

**Chỉ mục.** `ix_outbox_event_occurred`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Không.

**Ghi chú.** Debezium Outbox Event Router đọc WAL và phát lên Kafka; ghi cùng giao dịch với thay đổi (SAD 7.3).
:::

Cột khác: `tenant_id` v(16); `event_id` uuid; `topic` v(128); `aggregate_type` v(32); `aggregate_id` uuid; `payload` jsonb; `trace_id` char(32); `occurred_at` tstz; `published_at` tstz.

### 3.40. `inbox_event`

::: dac-ta
**Mục đích.** Hạ tầng. Khử trùng sự kiện nhận: sự kiện của phân hệ nguồn (EVT-01-03, EVT-02-05, EVT-04-07, EVT-08-14, EVT-10-01, EVT-14-12, EVT-19-07…) tiêu thụ lũy đẳng theo event_id cho tự đăng ký sổ kiến trúc và nhận quan sát (FR-16-010, 044). Dọn sau 30 ngày.

**FR phục vụ.** FR-16-010, 044, 048.

**Khóa chính.** (tenant_id, consumer, event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_inbox_event_` + `tenant`, `consumer`, `prefix`.

**Chỉ mục.** `ix_inbox_event_received`.

**Cách ly tenant.** Mẫu P (1.2).

**Phân vùng, bất biến.** Không.

**Ghi chú.** Khử trùng sự kiện nhận từ phân hệ khác theo `event_id` (tiêu thụ lũy đẳng).
:::

Cột khác: `tenant_id` v(16); `consumer` v(64); `event_id` uuid; `source_topic` v(128); `received_at` tstz; `processed_at` tstz.

<!-- gen:tables:end -->

## 4. DDL và changelog Liquibase

### 4.1. Tệp

[`ph16/ddl/ph16_kpi.sql`](ph16/ddl/ph16_kpi.sql) là nguồn duy nhất, chia changeset bằng `-- @file`, `-- @changeset`, `-- @rollback` như PH-04…10. Changelog [`ph16/liquibase/db.changelog-ph16.yaml`](ph16/liquibase/db.changelog-ph16.yaml) và 11 tệp `ph16/liquibase/changes/*.sql` (formatted SQL, tác giả `ph16`) sinh bằng [`gen_liquibase.py`](ph16/tools/gen_liquibase.py), không sửa tay.

| Tệp | Nội dung |
|---|---|
| `16-0000-bootstrap.sql` | Vai trò `ph16_owner`, `ph16_app`, `ph16_readonly`, `ph16_compare`; schema; biến phiên |
| `16-0001-functions.sql` | `tg_touch`, `tg_immutable`, `tg_append_only`, `tg_frozen`, `tg_transition`, `tg_child_frozen`, `tg_no_delete_state`, `p_enable_rls`, `p_enable_rls_shared`, `p_ensure_partitions`, `f_setting_bool` |
| `16-0010-indicator.sql` | `kpi_indicator_group`, `kpi_indicator`, `kpi_indicator_version`, `kpi_indicator_threshold` |
| `16-0020-source.sql` | `kpi_data_source`, `kpi_source_contract`, `kpi_observation`, `kpi_ingest_log` |
| `16-0030-period.sql` | `kpi_reporting_period`, `kpi_manual_value`, `kpi_manual_evidence`, `kpi_manual_import`, `kpi_manual_import_row`, `kpi_aggregation_run`, `kpi_indicator_value`, `kpi_value_lineage`, `kpi_group_score` |
| `16-0040-report.sql` | `kpi_report_template`, `kpi_report`, `kpi_report_version`, `kpi_report_approval`, `kpi_report_signature`, `kpi_distribution`, `kpi_delivery`, `kpi_export_job` |
| `16-0050-arch.sql` | `kpi_arch_component`, `kpi_arch_component_version`, `kpi_arch_dependency`, `kpi_arch_reconciliation`, `kpi_arch_recon_item`, `kpi_compliance_criterion`, `kpi_compliance_assessment`, `kpi_compliance_item`, `kpi_compliance_waiver` |
| `16-0060-national.sql` | `kpi_national_template`, `kpi_national_submission`, `kpi_national_submission_log` |
| `16-0070-ops.sql` | `kpi_tenant_setting`, `outbox_event`, `inbox_event` |
| `16-0090-seed.sql` | `p_seed_tenant`, `p_seed_common`; nạp 5 nhóm, 24 chỉ tiêu, 6 tiêu chí, mẫu báo cáo `COMMON` |
| `16-0900-grants.sql` | Quyền theo vai trò, `runAlways`; chính sách và khung nhìn so sánh liên tenant |

: Tệp DDL và changelog Liquibase của PH-16

Không có changeset di trú dữ liệu: hệ cũ không có chức năng báo cáo chỉ tiêu và repo chưa có bảng PH-16 nào chạy (mục 8.3).

### 4.2. Kết quả chạy thử

Chạy ngày 26/11/2026 trên PostgreSQL 16.15 (Ubuntu 24.04) cài sạch, dữ liệu giả, tenant kiểm thử T90, T91:

- DDL chạy không lỗi trên CSDL trống với `ON_ERROR_STOP`: 40 bảng gốc, 96 phân vùng tháng, 277 `CHECK`, 48 khóa ngoại, 44 ràng buộc `UNIQUE`, 114 trigger, 161 chính sách RLS (mẫu P hai chính sách mỗi thao tác, mẫu S cho bảy bảng, cộng chính sách của vai so sánh), 59 chỉ mục ngoài khóa chính và `UNIQUE`, 17 chỉ mục duy nhất, 20 hàm và thủ tục.
- Ghép 11 tệp changelog sinh ra rồi chạy bằng psql theo thứ tự trên CSDL trống khác: cùng số bảng và cùng 286 khối PASS. Chưa chạy bằng Liquibase CLI (không có trong máy); CI chạy `liquibase update` trên Testcontainers.
- [`ph16_isolation_test.sql`](ph16/test/ph16_isolation_test.sql) đạt 286 khối PASS, chia 16 nhóm: khởi tạo tenant bằng thủ tục (25 tham số, chạy lại không nhân bản); chỉ tiêu, phiên bản, ngưỡng; nguồn, quan sát idempotent, nhật ký nạp; kỳ, số liệu tay, lần tổng hợp; giá trị, truy vết, chốt kỳ; báo cáo, chữ ký, phiên bản (PUBLISHED bất biến, bốn mắt, chặn xóa); phân phối, xuất; sổ kiến trúc; nhập tệp số liệu tay, đối chiếu sổ kiến trúc, yêu cầu tính lại; gửi quốc gia (nhật ký chỉ thêm, cổng `16.national.enabled`); tham số, outbox, inbox; cô lập tenant (T91 không đọc, không sửa, không ghi dòng của T90 kể cả phân vùng; khóa ngoại không vượt tenant; quên đặt `app.tenant_id` thì không thấy dòng nào); vai so sánh; quyền theo vai; chủ sở hữu và phân vùng; tổng kết.
- Chạy chung `chay_ddl.py` cho 15 phân hệ trên một CSDL: không lỗi mới.

### 4.3. Đối chiếu với FRS

Mọi enum `CHECK` dạng chữ hoa nằm ở từ điển `ENUM` của `sinh_ddl.py`. Bản 0.2 đối chiếu từng danh sách `IN (...)` và `<@ ARRAY[...]` của DDL với FRS Phụ lục A bằng script (đọc hai tệp, so tập giá trị): 73 danh sách trùng đúng một enum của Phụ lục A, 23 danh sách là tập con trong ràng buộc nghiệp vụ (ví dụ `state NOT IN ('PAUSED', 'RETIRED')`), 0 lệch. Thay đổi enum so với 0.1 ghi ở Lịch sử phiên bản.

## 5. Dữ liệu khởi tạo

Hai thủ tục khởi tạo, chạy lại không nhân bản.

- `ph16_kpi.p_seed_common()` nạp vào tenant `COMMON` dưới phiên `PLATFORM`: 5 nhóm chỉ tiêu (`KET_NOI`, `CHIA_SE`, `DU_LIEU`, `VAN_HANH`, `KIEN_TRUC`), 24 chỉ tiêu mẫu (18 mang mã KPI-01…18 của BRD, 6 chỉ tiêu bổ sung từ phân hệ nguồn), 6 tiêu chí tuân thủ kiến trúc `AR-REG-01`, `AR-OWN-01`, `AR-DEP-01`, `AR-OPS-01`, `AR-SEC-01`, `AR-VER-01`, và mẫu báo cáo mặc định (`COMMON`). Chỉ tiêu mẫu có định nghĩa khung (loại, hướng tốt, cách đo, đơn vị, phép gộp, bắt buộc); công thức, mục tiêu, ngưỡng do tenant khai báo vì khung quốc gia chưa ban hành (Q16-51).
- `ph16_kpi.p_seed_tenant('Tnn')` do PH-20 gọi khi khởi tạo tenant: 25 tham số `16.*` đúng FRS §8.2 (kỳ `MONTH,QUARTER,YEAR`, chốt ngày 5, cron tổng hợp `0 30 1 * * *`, hết hạn 15 phút, nguồn quá hạn sau 26 giờ và lỗi sau 3 lần, tính lại khi số liệu đến trễ, bằng chứng số liệu tay, bốn mắt, ký số, lưu báo cáo 10 năm, quan sát 36 tháng, liên kết xuất 24 giờ và tối đa 100.000 dòng, gửi quốc gia tắt, thử lại 5 lần, so sánh tối thiểu 3 tenant, miễn trừ tối đa 180 ngày, ghim Tổng quan rỗng). Trọng số năm nhóm mặc định 20 mỗi nhóm, tổng 100.

Chỉ tiêu riêng, nguồn, báo cáo, thành phần kiến trúc của tenant do người dùng khai báo qua FR-16, không seed.

## 6. Kho lưu trữ ngoài PostgreSQL

### 6.1. OpenBao và PH-12

Khóa ký số báo cáo do PH-12 giữ trong OpenBao (ADR-012); PH-16 chỉ lưu giá trị băm chữ ký, định danh khóa và chứng thư ở `kpi_report_signature`, không lưu khóa. Khi dịch vụ ký ngừng thì không công bố được báo cáo (nếu `16.report.signing` bật), không ảnh hưởng tổng hợp.

### 6.2. Valkey

Valkey là bộ đệm, mọi khóa có hash tag tenant; mất toàn bộ chỉ làm tăng tải đọc PostgreSQL.

| Khóa | Giá trị | Thời gian sống |
|---|---|---|
| `{t68}:kpi:def:{indicatorCode}` | Phiên bản ACTIVE đã biên dịch công thức CEL | 300 giây, xóa khi nhận EVT-16-01 |
| `{t68}:kpi:dash:{periodCode}` | Giá trị chỉ tiêu hiện hành của bảng điều khiển | 60 giây, xóa khi nhận EVT-16-05 |
| `{t68}:kpi:idem:{chủ thể}:{khóa}` | `Idempotency-Key` của API ghi | 24 giờ |
| `{t68}:kpi:agg:{periodId}` | Khóa mềm một lần tổng hợp mỗi kỳ, bổ sung cho `uq_kpi_aggregation_run_active` | Theo hạn lần tổng hợp |

: Khóa Valkey của PH-16

### 6.3. Kafka

Mười ba topic phát `{tenant}.kpi.*.v1` của EVT-16-01…13 và topic kiểm toán `audit.recorded.v1` do Debezium Outbox Event Router đọc từ `outbox_event`. Tiêu thụ: sự kiện chỉ số đã tổng hợp của phân hệ nguồn (`EVT-08-14` điểm chất lượng, `EVT-10-01`, `EVT-14-11`, `EVT-14-12`, `EVT-19-07`…) vào `inbox_event` để tạo quan sát; sự kiện đăng ký của PH-01, 02, 04, 05, 10, 14 để tự đăng ký sổ kiến trúc. Khóa tiêu thụ lũy đẳng theo `event_id`.

| Topic | Sự kiện | Ghi chú |
|---|---|---|
| `t68.kpi.indicator.activated.v1`, `indicator.retired.v1` | EVT-16-01, 02 | Phiên bản định nghĩa ACTIVE, chỉ tiêu ngừng |
| `t68.kpi.source.state-changed.v1` | EVT-16-03 | Nguồn đổi trạng thái |
| `t68.kpi.manual-value.decided.v1` | EVT-16-04 | Số liệu tay duyệt hoặc từ chối |
| `t68.kpi.period.computed.v1`, `indicator.status-changed.v1` | EVT-16-05, 06 | Kết thúc tổng hợp; chỉ tiêu AT_RISK, OFF_TRACK |
| `t68.kpi.report.submitted.v1`, `report.published.v1`, `report.state-changed.v1` | EVT-16-07, 08, 09 | Vòng báo cáo |
| `t68.kpi.arch-component.changed.v1`, `arch-compliance.assessed.v1` | EVT-16-10, 11 | Sổ kiến trúc |
| `t68.kpi.national-submission.state-changed.v1`, `export.completed.v1` | EVT-16-12, 13 | Gói quốc gia; xuất xong |

: Topic Kafka phát của PH-16

### 6.4. Ceph RGW

Bucket `kpi-reports` giữ PDF ký số của báo cáo công bố (`kpi_report_version.object_ref`, mã SHA-256 ở `content_hash`), bật Object Lock chế độ chính tắc, hạn giữ theo `16.report.retention-years`; bucket `kpi-evidence` giữ tệp bằng chứng số liệu tay (`kpi_manual_evidence`); bucket `kpi-exports` giữ tệp xuất (`kpi_export_job`, liên kết ký 24 giờ theo `16.export.link-hours`, xóa theo hạn). Mọi bucket mã hóa phía máy chủ.

### 6.5. ClickHouse

Không dùng ClickHouse trong bản này (ADR đề xuất dải 160…164): khối lượng ở mục 1.5 nằm trong khả năng của `pg-core` nhờ phân vùng tháng.

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

Bảng nêu thời hạn lưu giữ và cách dọn từng nhóm dữ liệu. Giá trị lấy từ tham số `16.*` của tenant (`kpi_tenant_setting`), mặc định do `p_seed_tenant` seed.

| Đối tượng | Lưu giữ mặc định | Cơ chế dọn, sao lưu |
|---|---|---|
| Schema `ph16_kpi` | Theo `pg-core`: WAL liên tục, base backup hằng ngày lên Ceph RGW, RPO ≤ 15 phút, RTO ≤ 30 phút (ADR-034) | Diễn tập DR theo D03-09 |
| `kpi_observation` | 36 tháng, tham số `16.observation.retention-months` | `DETACH` rồi `DROP` phân vùng tháng dưới `ph16_owner` |
| `kpi_ingest_log` | 90 ngày | `DROP` phân vùng |
| `kpi_indicator_value`, `kpi_value_lineage` | Theo thời hạn báo cáo: 10 năm, tham số `16.report.retention-years` | Không dọn sớm hơn báo cáo dựa vào chúng; `DROP` phân vùng sau hạn |
| `kpi_report_version`, `kpi_report_signature`, tệp ở `kpi-reports` | 10 năm kể từ ngày công bố (`retain_until`) | Không xóa; Object Lock bảo vệ tệp |
| `kpi_national_submission_log` | 10 năm | Chỉ thêm, `REVOKE UPDATE, DELETE` |
| `kpi_export_job`, tệp `kpi-exports` | Liên kết 24 giờ (`16.export.link-hours`); dòng 30 ngày | Xóa theo `expires_at`; `DELETE` theo lô |
| `outbox_event`, `inbox_event` | 3 ngày; 30 ngày | Công việc dọn mỗi giờ |
| Cấu hình, phiên bản, sổ kiến trúc, đánh giá, miễn trừ | Vĩnh viễn, không xóa | `REVOKE DELETE`, chỉ ngừng hoặc thay thế |
| Kafka, OpenBao, Ceph RGW | Theo D03-09: bản sao 3; snapshot Raft hằng giờ; đối tượng bản sao hai site | |

: Sao lưu, khôi phục, mã hóa và lưu giữ

**Dọn bằng phân vùng.** `PartitionMaintenanceJob` chạy hằng ngày, gọi `p_ensure_partitions` tạo trước ba tháng; dọn bằng `DETACH` rồi `DROP` dưới `ph16_owner`, ứng dụng không có quyền `DELETE` trên bốn bảng phân vùng.

**Mã hóa.** Kết nối `pg-core` bắt buộc TLS; dữ liệu tĩnh mã hóa mức đĩa (D03-07). PH-16 không lưu bí mật: chữ ký chỉ là băm, khóa ở OpenBao; bằng chứng số liệu tay là tệp ở Ceph RGW mã hóa phía máy chủ.

**Thứ tự khôi phục.** OpenBao trước, `pg-core` sau. Nếu CSDL cũ hơn Kafka thì tổng hợp lại từ quan sát và nhận lại sự kiện (lũy đẳng nhờ `uq_kpi_observation_idem`); báo cáo công bố khôi phục từ tệp WORM và băm `content_hash`.

## 8. Ánh xạ sang thiết kế mới

### 8.1. Thực thể EN-16 → bảng

Mã EN-16-01…39 theo FRS mục 4.2. Bốn thực thể không có bảng riêng: EN-16-13 `manual_import` (kết quả kiểm tệp XLSX là dữ liệu tạm của API, không lưu), EN-16-18 `status_change` (chuyển trạng thái chỉ tiêu phát bằng sự kiện EVT-16-06, giá trị trước nằm ở dòng `is_current = false` của `kpi_indicator_value`), EN-16-33 `arch_reconciliation` và EN-16-37 `national_reconciliation` (đối chiếu tính khi hỏi từ `kpi_arch_component` và `kpi_national_submission`, không lưu kết quả; Q16-54). EN-16-04 gồm ngưỡng ở `kpi_indicator_threshold` và mục tiêu ở phiên bản; một số thực thể (EN-16-07, 10, 12, 22, 30) là tập con nằm cùng bảng với thực thể chính. Chỉ `outbox_event`, `inbox_event` là bảng hạ tầng không mang mã EN.

<!-- gen:en:start -->
| Thực thể | Bảng hiện thực |
|---|---|
| EN-16-01 | `kpi_indicator_group` |
| EN-16-02 | `kpi_indicator` |
| EN-16-03 | `kpi_indicator_version` |
| EN-16-04 | `kpi_indicator_version`, `kpi_indicator_threshold` |
| EN-16-05 | `kpi_source_contract` |
| EN-16-06 | `kpi_data_source` |
| EN-16-07 | `kpi_source_contract` |
| EN-16-08 | `kpi_observation` |
| EN-16-09 | `kpi_ingest_log` |
| EN-16-10 | `kpi_ingest_log` |
| EN-16-11 | `kpi_manual_value` |
| EN-16-12 | `kpi_manual_evidence` |
| EN-16-13 | `kpi_manual_import`, `kpi_manual_import_row` |
| EN-16-14 | `kpi_reporting_period` |
| EN-16-15 | `kpi_aggregation_run` |
| EN-16-16 | `kpi_indicator_value`, `kpi_value_lineage` |
| EN-16-17 | `kpi_group_score` |
| EN-16-19 | `kpi_report_template` |
| EN-16-20 | `kpi_report` |
| EN-16-21 | `kpi_report_version`, `kpi_report_approval`, `kpi_report_signature` |
| EN-16-22 | `kpi_report_version` |
| EN-16-23 | `kpi_export_job` |
| EN-16-24 | `kpi_distribution` |
| EN-16-25 | `kpi_delivery` |
| EN-16-26 | `kpi_arch_component` |
| EN-16-27 | `kpi_arch_component_version` |
| EN-16-28 | `kpi_arch_dependency` |
| EN-16-29 | `kpi_compliance_criterion` |
| EN-16-30 | `kpi_compliance_criterion` |
| EN-16-31 | `kpi_compliance_assessment`, `kpi_compliance_item` |
| EN-16-32 | `kpi_compliance_waiver` |
| EN-16-33 | `kpi_arch_reconciliation`, `kpi_arch_recon_item` |
| EN-16-34 | `kpi_national_template` |
| EN-16-35 | `kpi_national_submission` |
| EN-16-36 | `kpi_national_submission_log` |
| EN-16-38 | `kpi_indicator` |
| EN-16-39 | `kpi_tenant_setting` |

: Ánh xạ thực thể EN-16 sang bảng

Bảng hạ tầng không mang mã EN: `outbox_event`, `inbox_event`.
<!-- gen:en:end -->

### 8.2. Chức năng FR-16 → bảng

Ma trận gom FR-16-001…058 theo nhóm A…I của FRS; mỗi chức năng liệt kê bảng nó đọc hoặc ghi chính.

<!-- gen:fr:start -->
| FR | Bảng hiện thực |
|---|---|
| FR-16-001 (A) | `kpi_indicator` |
| FR-16-002 (A) | `kpi_indicator`, `kpi_indicator_version` |
| FR-16-003 (A) | `kpi_indicator_version` |
| FR-16-004 (A) | `kpi_indicator_version`, `kpi_indicator_threshold` |
| FR-16-005 (A) | `kpi_indicator_version` |
| FR-16-006 (A) | `kpi_indicator`, `kpi_indicator_version` |
| FR-16-007 (A) | `kpi_indicator_group`, `kpi_group_score` |
| FR-16-008 (A) | `kpi_indicator` |
| FR-16-009 (B) | `kpi_data_source`, `kpi_source_contract` |
| FR-16-010 (B) | `kpi_observation`, `kpi_ingest_log`, `inbox_event` |
| FR-16-011 (B) | `kpi_observation` |
| FR-16-012 (B) | `kpi_observation` |
| FR-16-013 (B) | `kpi_data_source` |
| FR-16-014 (B) | `kpi_manual_value`, `kpi_manual_evidence`, `kpi_manual_import`, `kpi_manual_import_row` |
| FR-16-015 (B) | `kpi_manual_value` |
| FR-16-016 (B) | `kpi_ingest_log` |
| FR-16-017 (C) | `kpi_reporting_period` |
| FR-16-018 (C) | `kpi_aggregation_run` |
| FR-16-019 (C) | `kpi_indicator_value`, `kpi_value_lineage` |
| FR-16-020 (C) | `kpi_aggregation_run` |
| FR-16-021 (C) | `kpi_indicator_threshold`, `kpi_indicator_value`, `outbox_event` |
| FR-16-022 (C) | `kpi_indicator_value`, `kpi_group_score` |
| FR-16-023 (C) | `kpi_aggregation_run`, `kpi_observation` |
| FR-16-024 (C) | `kpi_reporting_period`, `kpi_aggregation_run` |
| FR-16-025 (D) | `kpi_report_template` |
| FR-16-026 (D) | `kpi_report`, `kpi_report_version` |
| FR-16-027 (D) | `kpi_report_version` |
| FR-16-028 (D) | `kpi_report_version`, `kpi_report_approval` |
| FR-16-029 (D) | `kpi_report_version`, `kpi_report_approval`, `kpi_report_signature` |
| FR-16-030 (D) | `kpi_report_version`, `kpi_report_approval` |
| FR-16-031 (D) | `kpi_report` |
| FR-16-032 (D) | `kpi_report` |
| FR-16-033 (E) | `kpi_export_job` |
| FR-16-034 (E) | `kpi_distribution`, `kpi_delivery` |
| FR-16-035 (E) | `kpi_indicator_value`, `kpi_report_version` |
| FR-16-036 (E) | `kpi_report_signature`, `kpi_export_job`, `kpi_report_version` |
| FR-16-037 (E) | `kpi_indicator_value`, `kpi_group_score` |
| FR-16-038 (F) | `kpi_group_score` |
| FR-16-039 (F) | `kpi_indicator_value`, `kpi_value_lineage` |
| FR-16-040 (F) | `kpi_indicator_value` |
| FR-16-041 (F) | `kpi_indicator_value` |
| FR-16-042 (F) | `kpi_aggregation_run`, `kpi_data_source` |
| FR-16-043 (G) | `kpi_arch_component` |
| FR-16-044 (G) | `kpi_arch_component`, `inbox_event` |
| FR-16-045 (G) | `kpi_arch_component`, `kpi_arch_component_version`, `kpi_arch_dependency` |
| FR-16-046 (G) | `kpi_arch_component` |
| FR-16-047 (G) | `kpi_compliance_criterion`, `kpi_compliance_assessment`, `kpi_compliance_item`, `kpi_compliance_waiver` |
| FR-16-048 (G) | `kpi_arch_component`, `kpi_arch_reconciliation`, `kpi_arch_recon_item`, `inbox_event` |
| FR-16-049 (G) | `kpi_export_job`, `kpi_arch_dependency` |
| FR-16-050 (H) | `kpi_national_template` |
| FR-16-051 (H) | `kpi_national_submission` |
| FR-16-052 (H) | `kpi_arch_component_version`, `kpi_national_submission` |
| FR-16-053 (H) | `kpi_national_submission_log` |
| FR-16-054 (H) | `kpi_national_submission`, `kpi_arch_component`, `kpi_report_version` |
| FR-16-055 (I) | `kpi_tenant_setting` |
| FR-16-056 (I) | `outbox_event` |
| FR-16-057 (I) | `kpi_tenant_setting`, `kpi_observation`, `kpi_report_version` |
| FR-16-058 (I) | `outbox_event`, `kpi_aggregation_run`, `kpi_data_source` |

: Ma trận FR-16 sang bảng

<!-- gen:fr:end -->

### 8.3. Hệ cũ Viettel 2021

Hệ cũ không có chức năng báo cáo chỉ tiêu định kỳ, sổ kiến trúc hay gói gửi quốc gia (REQ-16 là năng lực mới theo BRD, D00-03 không có LGC do PH-16 làm chủ). Vì vậy không có phép chuyển kiểu cột hay di trú dữ liệu cho D06-01. Truy vết gián tiếp, PH-16 nâng cấp thành chỉ tiêu định kỳ: LGC-APIM-026 (dashboard hoạt động API, chủ PH-13), LGC-PAY-013 và LGC-PAY-020 (dashboard thanh toán, chủ PH-19), LGC-HUB-001…004 (đếm publisher, subscriber, project, topic, chủ PH-10), LGC-BUS-027 (thống kê endpoint, chủ PH-13), LGC-NGSP-004 (tổng hợp kết quả hồ sơ ĐVQHNS, chủ PH-14). Kết luận: "Nâng cấp (gián tiếp)".

### 8.4. Mô hình SRS cũ của repo (`docs/07-srs/SRS-PH-16-nas-kpi.md`)

SRS cũ mô tả sáu thực thể trên giấy, chưa có bảng nào chạy. Bảng dưới ánh xạ sang bảng mới; khác biệt có chủ ý ở cột cuối.

| SRS cũ | Bảng mới | Khác biệt |
|---|---|---|
| EN-16-01 chỉ tiêu | `kpi_indicator`, `kpi_indicator_version`, `kpi_indicator_threshold` | Công thức, mục tiêu, ngưỡng tách thành phiên bản có duyệt bốn mắt, bất biến khi ACTIVE; công thức là CEL |
| EN-16-02 nguồn, quan sát | `kpi_data_source`, `kpi_source_contract`, `kpi_observation`, `kpi_ingest_log` | Quan sát chỉ thêm, idempotent theo mã nguồn; có nhật ký nạp và ghi nhận độ tươi |
| EN-16-03 giá trị theo kỳ | `kpi_reporting_period`, `kpi_aggregation_run`, `kpi_indicator_value`, `kpi_value_lineage`, `kpi_group_score` | Có kỳ chốt và mở lại, lần tổng hợp, truy vết, nhãn PARTIAL thay vì bịa số |
| EN-16-04 báo cáo | `kpi_report`, `kpi_report_version`, `kpi_report_approval`, `kpi_report_signature` | Phiên bản báo cáo, duyệt và chữ ký tách bảng; công bố bất biến, ký số, WORM 10 năm |
| EN-16-05 sổ kiến trúc | `kpi_arch_component`, `_version`, `_dependency`, `kpi_compliance_*` | Thay Backstage bằng sổ tự xây trên PostgreSQL (ADR đề xuất của PH-15); thêm đánh giá tuân thủ và miễn trừ |
| EN-16-06 gửi quốc gia | `kpi_national_template`, `kpi_national_submission`, `kpi_national_submission_log` | Gói theo mẫu cấu hình ngoài, gửi qua PH-14, nhật ký chỉ thêm |

: Ánh xạ mô hình SRS cũ sang bảng mới

Chính sách lưu giữ của SRS cũ (giá trị chỉ tiêu và báo cáo công bố 10 năm) khớp mặc định `16.report.retention-years` = 10; quan sát đầu vào 36 tháng là bổ sung mới của thiết kế này (Q16-50).

### 8.5. Tên trường API ↔ cột

Cột giữ snake_case, trường API camelCase (D03-04-PH16); bảng chỉ liệt kê tên khác nhau ngoài cách viết (đề nghị của tập API).

| Trường API | Cột | Ghi chú |
|---|---|---|
| `version` (phiên bản định nghĩa, báo cáo, mẫu) | `version_no` | `version` của bảng là số khóa lạc quan, trả ở `ETag` |
| `formula` | `kpi_indicator_version.formula_cel` | |
| `target.target` | `target_value` | |
| `thresholds.greenFrom`, `amberFrom`, `range` | `kpi_indicator_threshold.level`, `lower_bound`, `upper_bound` | Mỗi mức một dòng |
| `trigger` | `kpi_aggregation_run.run_trigger` | |
| `completeness` (lần tổng hợp) | `kpi_aggregation_run.completeness` | Tỷ lệ 0…1; của giá trị chỉ tiêu là enum |
| `result` (nhật ký tiếp nhận) | `kpi_ingest_log.outcome` | |
| `subject` (xuất) | `kpi_export_job.subject_type` | |
| `reportTypes`, `periodTypes` (phân phối) | `kpi_distribution.report_type`, `period_type` | API nhận mảng; bảng giữ một giá trị, nhiều giá trị là nhiều dòng |
| `until` (miễn trừ) | `kpi_compliance_waiver.valid_to` | |
| `evidence.sha256` | `content_hash` | `bytea` 32 byte, API trả hex |
| `settings[].key` | `kpi_tenant_setting.param_code` | |
| `comment` (quyết định) | `decision_comment` | |
| `documentNumber`, `recipientsNote` | `kpi_report_version.document_number`, `recipients_note` | FRS 0.2, FR-16-027 |
| `kind` (phụ thuộc), `dependencyType` | `kpi_arch_dependency.origin`, `dependency_type` | |

: Ánh xạ tên trường API sang cột

Nhật ký kiểm toán (API-16-129) đọc từ kho kiểm toán của PH-13, PH-16 không có bảng riêng.

## 9. Câu hỏi mở và đề nghị đồng bộ

### 9.1. Câu hỏi mở

Các câu hỏi chưa có quyết định, kèm đề xuất tạm.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q16-50 | Thời hạn lưu giữ báo cáo công bố (10 năm, theo SRS cũ) và quan sát đầu vào (36 tháng) chưa có căn cứ pháp lý xác minh; WORM chế độ chính tắc không cho rút ngắn | Giữ 10 năm và 36 tháng làm tham số `16.report.retention-years`, `16.observation.retention-months`; pháp chế xác minh điều khoản; dùng chế độ chính tắc từ đầu |
| Q16-51 | 24 chỉ tiêu mẫu `COMMON` mới có định nghĩa khung, chưa có công thức CEL, mục tiêu, ngưỡng, hợp đồng nguồn vì khung quốc gia chưa ban hành và hợp đồng chỉ số của phân hệ nguồn chưa chốt | Giữ khung; tenant khai báo công thức; bổ sung seed khi có hợp đồng nguồn và khung quốc gia |
| Q16-52 | Mức đầy đủ tối thiểu để công bố báo cáo chính thức: chặn khi thiếu nguồn bắt buộc, hay cho công bố PARTIAL kèm thuyết minh | Chặn khi thiếu nguồn bắt buộc (chỉ tiêu `mandatory`), cho PARTIAL đối với chỉ tiêu còn lại kèm thuyết minh bắt buộc |
| Q16-53 | Khóa phân vùng `period_start` của `kpi_observation` buộc tính duy nhất kèm `period_start`: cùng `idempotency_ref` với kỳ khác vẫn thêm được dòng; và tiêu chí tuân thủ CMP-LAW-10, 11 còn dự thảo | Chấp nhận, dịch vụ gắn `period_start` cố định theo `idempotency_ref`; tiêu chí và mẫu là cấu hình có phiên bản, đổi không cần đổi DDL |
| Q16-54 | EN-16-18 (đổi trạng thái chỉ tiêu) và EN-16-37 (đối soát quốc gia) không có bảng, tính khi hỏi | Bản 0.2 đã thêm bảng cho EN-16-13 và EN-16-33 theo FRS; EN-16-18, 37 giữ tính khi hỏi; ClickHouse chỉ xét khi `kpi_observation` vượt 50 triệu dòng mỗi tháng |

: Câu hỏi mở của tập CSDL PH-16

### 9.2. Phụ lục đề nghị đồng bộ

Tập này không sửa tài liệu chung hay tập khác; các điểm sau cần chủ tài liệu tương ứng nhận.

| Số | Gửi tới | Nội dung đề nghị |
|---|---|---|
| 1 | FRS PH-16 (EN-16 ↔ bảng) | Bảng 8.1: EN-16-13, 18, 33, 37 không có bảng; EN-16-04, 07, 10, 12, 22, 30 là tập con cùng bảng; bảng nhóm điểm `kpi_group_score` là thực thể EN-16-17 |
| 2 | FRS PH-16 (enum) | Xu hướng dùng `UP, DOWN, FLAT`; cột thêm so với FRS: `completeness`, `is_current`, `retain_until`, `content_hash`, `object_ref`, `idempotency_ref`; FRS cập nhật tên khi ra bản kế tiếp |
| 3 | D02-08 (quyền) | Thêm 11 quyền PERM-16 gồm đọc chỉ tiêu, quản trị chỉ tiêu, duyệt định nghĩa, nhập số liệu tay, duyệt số liệu tay, lập báo cáo, duyệt báo cáo, công bố, xuất, sổ kiến trúc, gửi quốc gia, và các phạm vi máy `kpi.ingest`, `arch.register` |
| 4 | D03-10, D03-09 | Ghi schema `ph16_kpi` vào danh mục schema `pg-core`; vai `ph16_owner`, `ph16_app`, `ph16_readonly`, `ph16_compare`; mẫu RLS S cho bảy bảng định nghĩa; bucket `kpi-reports` (Object Lock), `kpi-evidence`, `kpi-exports` |
| 5 | D00-04 sổ tra cứu | Tiền tố khóa Valkey `{tenant}:kpi:*`; tham số `16.*` (18 mã) |
| 6 | ADR | Dải ADR-160…164: PostgreSQL phân vùng không ClickHouse; công thức CEL; báo cáo bất biến, ký số, WORM; gói quốc gia theo mẫu cấu hình qua PH-14; sổ kiến trúc tự xây |
| 7 | SDD, API PH-16 | `PartitionMaintenanceJob` chạy trước đầu tháng; API công bố kiểm `completeness` và chữ ký trước khi chuyển PUBLISHED; nhật ký kiểm toán dùng kho chung, PH-16 không có bảng riêng |

: Đề nghị đồng bộ của tập CSDL PH-16

Kết quả ở FRS 0.2 (Phụ lục C): số 1 nhận một phần (HT-19, thêm bảng cho EN-16-13, 33); số 2 không nhận (HT-20, tên cột giữ ở tập này, ánh xạ ở 8.5); số 7 thuộc SDD, API (HT-21). Đề nghị của SDD 0.1 §13.6 và API 0.1 cho tập này đã hấp thụ ở bản 0.2 (xem Lịch sử). Chưa làm: bảng `shedlock` (do thư viện tự tạo ở schema của job, D03-02-PH16 §13.6), `lineage_truncated` và trọng số biến khi gộp quý, năm (chờ Q16-24).

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-CSDL và K-TRINH-BAY: 36 bảng, DDL và changelog chạy thử trên PostgreSQL 16.15, kiểm cô lập 268 khối PASS; ERD bốn nhóm; báo cáo công bố bất biến ký số, nhật ký gửi quốc gia chỉ thêm, quan sát idempotent; ánh xạ EN, FR và mô hình SRS cũ sang bảng; năm câu hỏi mở Q16-50…54 |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ với FRS 0.2: enum khớp Phụ lục A (script 0 lệch): `kpi_compliance_item.result` `PASS`, `FAIL`, `NA`; tiêu chí, mẫu gói quốc gia `DRAFT`, `ACTIVE`, `SUPERSEDED`; `kpi_export_job.subject_type` theo `export_job.subject`; 40 bảng (thêm `kpi_manual_import`, `kpi_manual_import_row` cho EN-16-13, `kpi_arch_reconciliation`, `kpi_arch_recon_item` cho EN-16-33); `kpi_indicator.state` có `DRAFT`; `REPROCESSED`; trọng số nhóm thang 100; lý do 50 ký tự (mở lại kỳ, đính chính, rút, miễn trừ); `recompute_requested_at`; số ký hiệu, nơi nhận của báo cáo; báo cáo `APPROVED` trả về soạn; 25 tham số; topic EVT-16-14; ánh xạ trường API ↔ cột (8.5); kiểm cô lập 286 khối PASS |
