---
ma_tai_lieu: D03-03-PH11
ten: Thiết kế cơ sở dữ liệu phân hệ PH-11 Quy trình liên thông
phien_ban: 0.4
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, DBA, ATTT, hội đồng thẩm định
phan_he: PH-11
mo_ta: Thiết kế 32 bảng của schema ph11_bpm trên cụm pg-core cho điều phối quy trình liên thông (mô hình BPMN, chạy thử, phiên, can thiệp phiên, việc, hạn theo ngày làm việc, Saga bù trừ, đề nghị bỏ qua bù trừ, giữ pháp lý, lần chạy mẫu tuân thủ, sự cố, outbox), đồng bộ với FRS Phụ lục A, cách đặt engine Flowable ở schema riêng ph11_flowable, RLS theo tenant, phân vùng tháng, lưu giữ, ánh xạ thực thể sang bảng, trích từ DDL đã chạy thử.
tai_lieu_lien_quan: D02-03-PH11 FRS; D03-02-PH11 SDD; D03-04-PH11 API; D03-10 Thiết kế đa tenant; D05-02-PH11 Test case
---

# D03-03-PH11 · Thiết kế CSDL Quy trình liên thông

## Tóm tắt cho hội đồng thẩm định

PH-11 điều phối quy trình nghiệp vụ liên thông giữa nhiều hệ thống thông tin (HTTT), ví dụ "Đăng ký khai sinh, đăng ký thường trú, cấp thẻ BHYT cho trẻ dưới 6 tuổi". Dữ liệu của phân hệ chia hai schema trên cụm `pg-core`: `ph11_flowable` do engine Flowable 7.x nhúng tự tạo và quản (không viết DDL, ADR 110), và `ph11_bpm` gồm 32 bảng của lớp nghiệp vụ LGSP do tài liệu này đặc tả. Lớp nghiệp vụ giữ những gì engine không làm tốt: mô hình và phiên bản có duyệt bốn mắt, bản chiếu phiên và việc để truy vấn có cô lập tenant, hạn xử lý theo ngày làm việc, nhật ký Saga bù trừ làm bằng chứng đối soát, sự cố, và outbox phát sự kiện. Bốn điểm chính:

1. **Hai schema, hai tài khoản, một nguồn sự thật.** Trạng thái thực thi nằm ở engine; `instance_index`, `task_index`, `instance_step` là bản chiếu có RLS để liệt kê, tra tiến độ cho kênh DVC và báo cáo. Bản chiếu không giữ giá trị biến quy trình: biến hạn chế che, biến nhạy cảm mã hóa envelope trước khi vào engine (CHECK ở `variable_definition`).
2. **Quy tắc nghiệp vụ khóa ở CSDL**: phiên bản mô hình đã gửi duyệt bất biến, mỗi mô hình đúng một phiên bản `PUBLISHED`, duyệt phát hành, di trú phiên bốn mắt, khởi tạo lũy đẳng theo `idempotency_key`, một mã hồ sơ chỉ một phiên đang sống mỗi mô hình, lý do từ 20 ký tự khi từ chối, bỏ qua sự cố, bỏ qua bước bù trừ, nhật ký Saga và bước Saga không bị xóa.
3. **Cô lập tenant bằng `FORCE ROW LEVEL SECURITY`** trên 31 bảng có `tenant_id` (mẫu P riêng tenant; mẫu S cho `process_template`, `business_calendar`, `calendar_day`, `tenant_setting`: tenant đọc thêm dòng nền tảng `COMMON`); `shedlock` là bảng kỹ thuật. Khóa ngoại luôn kèm `tenant_id`.
4. **Lịch sử đủ dài cho kiểm toán, engine gọn.** Lịch sử bước giữ ở `instance_step` (phân vùng tháng, 5 năm sau khi phiên kết thúc); lịch sử `ACT_HI_*` của engine ở mức `audit` và dọn sớm hơn (mục 6.1), nên engine không phình mà bằng chứng BPMN 2.0 (CV 631) vẫn còn.

DDL [`ph11/ddl/ph11_bpm.sql`](ph11/ddl/ph11_bpm.sql) đã chạy thử trên PostgreSQL 16.15 sạch; bài kiểm [`ph11/test/ph11_isolation_test.sql`](ph11/test/ph11_isolation_test.sql) đạt 297 khối PASS (mục 4.2). Mục 8 ánh xạ thực thể và chức năng sang bảng; mục 9 nêu năm câu hỏi mở Q11-50…54 và những điểm FRS cần bổ sung. Bản 0.4 thêm ba bảng cho giữ pháp lý, đề nghị bỏ qua bù trừ bốn mắt và lần chạy mẫu tuân thủ (EN-11-29…31, đề nghị FRS).

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả cơ sở dữ liệu của PH-11 ở mức đủ để DBA dựng schema, kỹ sư `dh-platform` (module `bpm`, package `vn.datahub.platform.bpm`) viết tầng truy cập và kiểm thử viên viết ca cô lập tenant, bất biến, bốn mắt. Phạm vi là 32 bảng của `ph11_bpm`, thủ tục, trigger, changelog Liquibase và bài kiểm cô lập. Với `ph11_flowable` tài liệu chỉ nêu cách đặt, cấu hình và dọn (mục 6.1). Ngoài phạm vi: nội dung tệp đính kèm và gói bằng chứng (Ceph RGW), khóa mã hóa (OpenBao), mô hình dữ liệu của PH-04 (luồng thực thi service task).

### 0.2. Thuật ngữ và chữ viết tắt

Thuật ngữ chung theo D00-01 §2; các thuật ngữ sau xuất hiện nhiều nhất.

| Thuật ngữ | Nghĩa |
|---|---|
| BPMN 2.0 | Ngôn ngữ mô hình hóa quy trình nghiệp vụ (CV 631 yêu cầu dùng) |
| Flowable | Engine BPM mã nguồn mở (Apache 2.0) chạy nhúng trong `dh-platform` |
| Phiên | Một lần chạy của quy trình (process instance); mã hồ sơ là `businessKey` |
| Service task | Bước tự động; PH-11 chỉ gửi lệnh `service.requested`, PH-04 thực thi (ADR 112) |
| Saga | Chuỗi bước bù trừ khi một bước thất bại hoặc phiên bị hủy, không dùng giao dịch hai pha (ADR 113) |
| Bản chiếu | Bảng `ph11_bpm` phản ánh trạng thái từ engine để truy vấn có RLS |
| HC, NC | Dữ liệu hạn chế (`RESTRICTED`), nhạy cảm (`SENSITIVE`) theo PH-09 |
| RLS | Row Level Security, cô lập theo `tenant_id` (ADR-003) |

: Thuật ngữ và chữ viết tắt của tập CSDL PH-11

### 0.3. Tài liệu tham chiếu

Tập này dựa vào các tài liệu sau, theo thứ tự ưu tiên khi có lệch.

| Tài liệu | Dùng để |
|---|---|
| D02-03-PH11 FRS (Phụ lục A, mục 7, mục 8.2) | Nguồn sự thật: mã FR, BR, EN, enum, tham số `11.*`; điểm FRS còn thiếu ở mục 9.2 |
| D00-01 §5.1 | Cột ngữ cảnh chuẩn `id`, `tenant_id`, `created_*`, `updated_*`, `version` |
| D03-10 §4 | Mẫu RLS P và S |
| D03-03-PH06, PH10 | Mẫu thiết kế, công cụ sinh tài liệu, changelog |
| `datahub-docs/03-thiet-ke/api/ph11/openapi-bpm.yaml` | Tên trường API; tên cột là snake_case của trường đó |
| `docs/07-srs/SRS-PH-11-bpm.md` M4 | Mô hình dữ liệu SRS cũ (ánh xạ ở mục 8.3) |
| ADR 110…114 (đề xuất) | Engine nhúng, bpmn-js, service task bất đồng bộ, Saga, lịch làm việc |

: Tài liệu tham chiếu của tập CSDL PH-11

### 0.4. Người đọc

DBA, kỹ sư nền tảng và kiểm thử viên đọc mục 1 đến 7; hội đồng thẩm định đọc Tóm tắt, mục 1.4, 7 và 9.

### 0.5. Cấu trúc tài liệu

Mục 1 nêu chiến lược lưu trữ và quy tắc chốt ở CSDL; mục 2 là ERD; mục 3 đặc tả 32 bảng; mục 4 DDL và Liquibase; mục 5 dữ liệu khởi tạo; mục 6 kho ngoài PostgreSQL gồm engine Flowable; mục 7 lưu giữ và sao lưu; mục 8 ánh xạ; mục 9 câu hỏi mở.

## 1. Chiến lược lưu trữ

### 1.1. Schema, vai trò và kết nối

Hai schema cùng nằm ở cụm `pg-core`, cơ sở dữ liệu của `dh-platform`, tách bằng vai trò và nguồn kết nối riêng.

| Schema | Chủ sở hữu | Tài khoản dịch vụ | Nội dung |
|---|---|---|---|
| `ph11_bpm` | `ph11_owner` (NOLOGIN) | `dh_platform_app` (thành viên `ph11_app`): chỉ DML, không `BYPASSRLS`; Liquibase chạy bằng `dh_platform_migrator` (thành viên `ph11_owner`); báo cáo bằng `ph11_readonly` | 32 bảng (31 nghiệp vụ, `shedlock`), thủ tục, trigger |
| `ph11_flowable` | `ph11_engine` (NOLOGIN) | Nguồn kết nối riêng của Flowable (thành viên `ph11_engine`) | Bảng `ACT_*`, `FLW_*` do Flowable tự tạo; không RLS |

: Schema, vai trò và kết nối của PH-11

`ph11_app` và `ph11_readonly` không có quyền trên `ph11_flowable`; ngược lại tài khoản engine không đọc `ph11_bpm`. Hai nguồn kết nối nghĩa là cập nhật engine và bản chiếu không chung giao dịch; bản chiếu cập nhật sau commit của engine, lũy đẳng theo `engine_instance_id` hoặc `engine_task_id`, kèm đối soát định kỳ (Q11-54). Không có khóa ngoại sang schema khác: mã người dùng, nhóm, đơn vị (PH-12), mã HTTT (PH-01), mã luồng PH-04 là chuỗi kiểm ở dịch vụ.

### 1.2. Cách ly tenant

Mọi bảng nghiệp vụ có `tenant_id varchar(16)` dạng `Tnn` (bốn bảng mẫu S còn nhận `COMMON`) và bật `FORCE ROW LEVEL SECURITY` qua `ph11_bpm.p_enable_rls(bảng, mẫu)`. Mẫu P: chỉ thấy, ghi dòng có `tenant_id = current_setting('app.tenant_id')`, dòng `COMMON` chỉ phiên `PLATFORM` đọc, ghi. Mẫu S (`process_template`, `business_calendar`, `calendar_day`, `tenant_setting`): mọi tenant đọc được thêm dòng `COMMON`, chỉ phiên `PLATFORM` ghi `COMMON`, để PA phát hành mẫu quy trình, lịch nền quốc gia và trần tham số mà không sao chép vào từng tenant.

Biến phiên `app.tenant_id` đặt đầu mỗi giao dịch từ ngữ cảnh xác thực (FR-00-010), không từ tham số của bên gọi. Tác vụ nền liên tenant (quét hạn, dọn lưu giữ, dọn outbox) lặp từng tenant. Khóa ngoại luôn kèm `tenant_id`. Engine Flowable không có RLS: mọi triển khai, phiên, việc mang `tenantId` của Flowable, và chỉ lớp dịch vụ PH-11 chạm vào `ph11_flowable` (Q11-51).

### 1.3. Quy ước bảng và ngoại lệ

Theo D00-01 §5.1: `id uuid` (UUIDv7 sinh ở ứng dụng), `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (trigger `tg_touch`, khóa lạc quan, ETag). Mã nghiệp vụ có `CHECK` theo mẫu: mô hình `^[A-Z][A-Z0-9_]{2,63}$` (ví dụ `LT_KHAI_SINH`), ý định camelCase (ví dụ `guiTuPhap`), mã biểu mẫu `form_key` chữ thường, số, gạch ngang. Tên cột là snake_case của trường API (`failedElementId` của API ở cột `failed_element` theo FRS A.2). Trạng thái và loại là `varchar` kèm `CHECK` liệt kê đúng giá trị. Mã người dùng (`assignee`, `from_user`, `requested_by`) là `varchar(64)` của PH-12, không khóa ngoại. Mọi bảng có `tenant_id` đều có `uq_{bảng}_tid` UNIQUE (tenant_id, id) làm đích khóa ngoại, `ck_{bảng}_tenant` kiểm dạng `Tnn` và trigger `tg_{bảng}_touch`; bảng có `version` dùng làm ETag. Chương 3 không nhắc lại các mục này.

| Bảng, cột | Ngoại lệ | Lý do |
|---|---|---|
| `instance_step` | Khóa chính `(id, started_at)`, không `version`, không `updated_*`; EN-11-28 | Phân vùng tháng; chỉ cập nhật khi bước kết thúc; giữ 5 năm |
| `task_comment` | Không `version`, không `updated_*` | Chỉ thêm |
| `process_template`, `business_calendar`, `calendar_day`, `tenant_setting` | `tenant_id` nhận `COMMON` (mẫu S) | Mẫu, lịch nền, trần tham số dùng chung |
| `outbox_event`, `inbox_message`, `shedlock` | Không `version` (`shedlock` không `tenant_id`) | Bảng kỹ thuật |
| Cột `*_sha256` | `bytea` đúng 32 byte | Chống sai lệch nội dung BPMN, biểu mẫu, DMN, tệp |
| Cột `*_enc` | `bytea` 29 byte đến 1 MiB kèm `*_kid` | Bản mã envelope (OpenBao transit, ADR-032) |

: Quy ước bảng và ngoại lệ

### 1.4. Quy tắc nghiệp vụ chốt ở CSDL

Các quy tắc sau do CSDL tự bảo đảm, bằng ràng buộc, chỉ mục duy nhất, trigger hoặc quyền. Mã BR chính thức do FRS cấp; cột cuối ghi FR liên quan.

| Ràng buộc | Quy tắc | FR |
|---|---|---|
| `uq_process_version_published` | Mỗi mô hình đúng một phiên bản `PUBLISHED`; phiên bản mới thay thì bản cũ chuyển `DEPRECATED` | 008, 009 |
| `tg_process_version_frozen`, `tg_*_child` | Phiên bản từ `IN_REVIEW` không đổi BPMN XML; biến và hành động bù trừ chỉ sửa khi phiên bản cha còn `DRAFT` | 006, 007, 014, 016 |
| `ck_process_version_review`, `ck_process_version_published` | Gửi duyệt phải qua kiểm tra tĩnh `PASSED`; `PUBLISHED` có `deployment_id` | 005, 007, 008 |
| `ck_publish_request_four_eyes`, `ck_migration_plan_four_eyes` | Người duyệt khác người gửi, người duyệt di trú khác người lập | 008, 009, 026 |
| `ck_publish_request_reject`, `ck_incident_reason`, `ck_saga_step_manual`, `ck_compensation_action_note`, `ck_migration_plan_rejected`, `ck_migration_plan_reason` | Lý do từ 20 ký tự (từ chối duyệt, bỏ qua sự cố, xử lý tay Saga, ghi chú bù trừ, từ chối di trú, di trú); thu hồi phiên bản từ 10 ký tự | 008, 009, 014, 026, 053, 060 |
| `uq_instance_index_idempotency` | Khởi tạo lũy đẳng: một `idempotency_key` chỉ một phiên (BR-11-007) | 018 |
| `uq_instance_index_live_key` | Một mã hồ sơ chỉ một phiên đang sống (`RUNNING`, `SUSPENDED`, `COMPENSATING`) mỗi mô hình, trừ phiên chạy thử | 018 |
| `ck_instance_index_ended`, `ck_instance_index_reason` | Phiên kết thúc có `ended_at`; hủy, thất bại có lý do | 023, 024 |
| `ck_task_index_*` | Máy trạng thái việc: `ASSIGNED` có người nhận, `DELEGATED` có `delegated_from` khác người nhận, `COMPLETED` có quyết định và `completed_by`, trả về cần ý kiến từ 20 ký tự | 034…044 |
| `ex_delegation_overlap`, `ck_delegation_period` | Ủy quyền cùng người, cùng phạm vi (`scope_key`) không chồng thời gian; tối đa 90 ngày (trần của `11.delegation.maxDays`) | 041 |
| `uq_due_tracking_subject`, `ck_due_tracking_pause` | Mỗi phiên, mỗi việc một dòng hạn (`subject`, `subject_id`); tạm dừng có thời điểm và lý do `WAITING_SUPPLEMENT`, `LEGAL_SUSPENSION` | 046…049 |
| `uq_saga_log_running`, `uq_saga_step_command`, quyền `REVOKE DELETE` | Mỗi phiên một Saga đang chạy; mã lệnh bù trừ duy nhất; nhật ký Saga không xóa | 051…054 |
| `ck_variable_definition_sensitive`, `_restricted`, `_personal` | Biến NC phải mã hóa và không lộ ra tiến độ; biến HC bị che; biến cá nhân ghi căn cứ pháp lý | 016, 055 |
| `ck_saga_skip_request_four_eyes`, `_decided`, `_reject`, `uq_saga_skip_request_pending` | Người duyệt khác người đề nghị (ERR-11-005), mỗi bước một đề nghị chờ, từ chối kèm ý kiến từ 20 ký tự | 053 |
| `uq_legal_hold_active`, `ck_legal_hold_release` | Mỗi mã hồ sơ một giữ đang hiệu lực; gỡ ghi đủ thời điểm, người, lý do (từ 10 ký tự) | 054, 063 |
| `ck_compliance_sample_run_pack`, `_period` | Kết thúc `PASSED`, `FAILED` phải có băm 32 byte và vị trí gói; khoảng thống kê tối đa 366 ngày | 064 |
| `uq_service_call_command` | Mỗi mã lệnh một lần gửi, khóa tương quan kết quả từ PH-04 | 028, 029 |
| `ck_outbox_event_topic`, `_no_value`, `ck_inbox_message_no_value` | Đúng 19 topic EVT-11 (EVT-11-01…17, 20, 21; EVT-11-18, 19 là đầu vào); sự kiện, thông điệp không chứa khóa biến, biểu mẫu, định danh | 028, 056 |
| `tg_task_comment_append_only`, `REVOKE UPDATE, DELETE` | Ý kiến trên việc chỉ thêm | 043 |
| `ck_business_calendar_hours`, `_break`, `_week` | Giờ làm việc HH:MM, nghỉ trưa nằm trong giờ làm việc (ERR-11-028); thứ làm việc MON…SUN. Múi giờ cố định `Asia/Ho_Chi_Minh` (BR-11-017) | 045 |
| `ck_instance_change_four_eyes`, `_reason` | Can thiệp phiên: người duyệt khác người đề nghị; chuyển token cần lý do từ 30 ký tự (ERR-11-025) | 058 |
| `ck_tenant_setting_value` (hàm `f_setting_valid`) | 36 khóa `11.*` đúng kiểu và miền giá trị FRS 8.2; khóa ngoài danh sách bị từ chối | 062, 063 |

: Quy tắc nghiệp vụ chốt ở CSDL

Quy tắc cần dữ liệu ngoài schema hoặc tính toán (HTTT `ACTIVE` ở PH-01, quy tắc kiểm tra tĩnh BPMN, mọi ý định của mô hình đều `ACTIVE` khi phát hành, hạn tính theo ngày làm việc, hạn ủy quyền theo `11.delegation.maxDays`, ngưỡng tham số) kiểm ở dịch vụ, ghi ở D03-02-PH11.

### 1.5. Ước lượng khối lượng (giả định)

Giả định theo GĐ-01 (D02-01): tỉnh T01 quy mô `QM-VUA`, 200 HTTT; 300.000 phiên mỗi năm (khoảng 1.000 mỗi ngày làm việc), mỗi phiên trung bình 8 bước, 4 việc, 2 ý kiến, 5 lệnh service task, 20 sự kiện outbox. Không có số thật nên đây là giả định.

| Bảng | Dòng mỗi năm | Dung lượng mỗi năm | Giữ trực tuyến |
|---|---|---|---|
| `instance_index`, `instance_step` | 0,3 và 2,4 triệu | khoảng 1,9 GB | 5 năm sau khi phiên kết thúc; `instance_step` phân vùng tháng |
| `task_index`, `task_comment`, `task_attachment` | 1,2; 0,6; 0,45 triệu | khoảng 3 GB | 5 năm |
| `service_call`, `due_tracking` | 1,5 triệu mỗi bảng | khoảng 1,8 GB | 5 năm |
| `saga_log`, `saga_step`, `incident`, mô hình, cấu hình | dưới 0,1 triệu | dưới 0,2 GB | Saga 5 năm; mô hình, cấu hình vĩnh viễn |
| `outbox_event` | 6 triệu, tồn tại khoảng 50.000 dòng | dưới 0,1 GB | 3 ngày |
| `ph11_flowable` (`ACT_*`, history `audit`) | khoảng 12 KB mỗi phiên | khoảng 4 GB | 12 tháng (Q11-52) |

: Ước lượng khối lượng (giả định)

Tổng lớp nghiệp vụ khoảng 7 GB mỗi năm, khoảng 35 GB sau 5 năm cộng engine khoảng 4 GB: nhỏ so với `pg-core` của QM-VUA, không cần tách cụm. Cần theo dõi `instance_step` và `service_call` nếu số phiên tăng 10 lần (Q11-53).

### 1.6. Danh mục bảng

Danh mục dưới liệt kê 32 bảng theo thứ tự đặc tả ở chương 3, kèm thực thể, phân vùng và FR chính; sinh từ DDL nên khớp tuyệt đối với tệp.

<!-- gen:danh-muc:start -->
| Mục | Bảng | Thực thể | Phân vùng | FR chính |
|---|---|---|---|---|
| 3.1 | `process_model` | EN-11-01 | Không | 001, 002, 009 |
| 3.2 | `process_version` | EN-11-02 | Không | 003, 004, 005, 006, 007… |
| 3.3 | `form_definition` | EN-11-03 | Không | 012 |
| 3.4 | `service_intent` | EN-11-04 | Không | 013, 028 |
| 3.5 | `compensation_action` | EN-11-05 | Không | 014, 051 |
| 3.6 | `process_template` | EN-11-06 | Không | 015 |
| 3.7 | `variable_definition` | EN-11-07 | Không | 016 |
| 3.8 | `decision_table` | EN-11-24 | Không | 017 |
| 3.9 | `publish_request` | EN-11-20 | Không | 007, 008 |
| 3.10 | `test_run` | EN-11-26 | Không | 011 |
| 3.11 | `instance_index` | EN-11-08 | Không | 018, 019, 020, 021, 022… |
| 3.12 | `instance_step` | EN-11-28 | Tháng, started_at | 022, 031, 033, 056, 057… |
| 3.13 | `service_call` | EN-11-25 | Không | 028, 029, 060 |
| 3.14 | `instance_change` | EN-11-27 | Không | 025, 027 |
| 3.15 | `task_index` | EN-11-09 | Không | 034, 035, 036, 037, 038… |
| 3.16 | `task_comment` | EN-11-10 | Không | 038, 043, 066 |
| 3.17 | `task_attachment` | EN-11-11 | Không | 043 |
| 3.18 | `delegation` | EN-11-12 | Không | 041 |
| 3.19 | `business_calendar` | EN-11-13 | Không | 045 |
| 3.20 | `calendar_day` | EN-11-14 | Không | 045 |
| 3.21 | `due_tracking` | EN-11-15 | Không | 031, 046, 047, 048, 049… |
| 3.22 | `saga_log` | EN-11-16 | Không | 051, 052, 053, 054, 058 |
| 3.23 | `saga_step` | EN-11-17 | Không | 051, 052, 053 |
| 3.24 | `incident` | EN-11-18 | Không | 031, 058, 060, 061 |
| 3.25 | `migration_plan` | EN-11-19 | Không | 026 |
| 3.26 | `tenant_setting` | EN-11-23 | Không | 062, 063 |
| 3.27 | `outbox_event` | EN-11-21 | Không | 028, 032, 056, 065 |
| 3.28 | `inbox_message` | EN-11-22 | Không | 019, 029, 030 |
| 3.29 | `shedlock` | Ngoài FRS | Không | Hạ tầng |
| 3.30 | `saga_skip_request` | EN-11-29 | Không | 053 |
| 3.31 | `legal_hold` | EN-11-30 | Không | 054, 063 |
| 3.32 | `compliance_sample_run` | EN-11-31 | Không | 064 |

: Danh mục bảng của schema ph11_bpm

<!-- gen:danh-muc:end -->

## 2. Sơ đồ thực thể – quan hệ

Sơ đồ chia bốn nhóm để đọc được trên trang A4; khóa ngoại đều kèm `tenant_id` nên không vẽ. Tham chiếu logic (không có khóa ngoại) nêu ở thuyết minh.

```{.mermaid caption="ERD nhóm mô hình quy trình, phiên bản và tài nguyên"}
erDiagram
  process_model ||--o{ process_version : "phiên bản"
  process_version ||--o{ variable_definition : "biến"
  process_version ||--o{ compensation_action : "bù trừ theo bước"
  service_intent ||--o{ compensation_action : "ý định bù trừ"
  process_version ||--o{ publish_request : "duyệt phát hành"
  process_version ||--o{ migration_plan : "di trú từ, tới"
  process_version ||--o{ test_run : "chạy thử"
```

Mô hình là khung ổn định (mã `LT_KHAI_SINH`), mỗi lần sửa tạo một phiên bản; chỉ phiên bản `DRAFT` mới sửa được biến, bù trừ. `form_definition`, `service_intent`, `decision_table` là tài nguyên có phiên bản hoặc trạng thái riêng, BPMN chỉ tham chiếu theo mã (logic, kiểm ở bước kiểm tra tĩnh). `process_template` ở tenant `COMMON` là nguồn sao chép khi tạo mô hình.

```{.mermaid caption="ERD nhóm phiên, bước, việc và dịch vụ"}
erDiagram
  process_version ||--o{ instance_index : "chạy trên"
  instance_index ||--o{ instance_index : "phiên con"
  instance_index ||--o{ instance_step : "lịch sử bước"
  instance_index ||--o{ task_index : "việc"
  instance_index ||--o{ service_call : "lệnh PH-04"
  instance_index ||--o{ instance_change : "can thiệp phiên"
  service_intent ||--o{ service_call : "ý định"
  task_index ||--o{ task_comment : "ý kiến"
  task_index ||--o{ task_attachment : "tệp"
```

`instance_index` là trung tâm: mọi bảng vận hành đều trỏ về phiên. Phiên con (call activity, FR-11-033) trỏ về phiên cha. `test_run` gắn phiên bản nháp; phiên chạy thử là dòng `instance_index` có `is_test`, nối với `test_run` qua `engine_instance_id` (tham chiếu logic).

```{.mermaid caption="ERD nhóm hạn xử lý, lịch làm việc và ủy quyền"}
erDiagram
  business_calendar ||--o{ calendar_day : "ngày nghỉ, làm bù"
  instance_index ||--o{ due_tracking : "hạn phiên"
  task_index ||--o{ due_tracking : "hạn việc"
```

Hạn của phiên và của việc cùng một bảng, phân biệt bằng `subject`; `task_id` là cột sinh từ `subject_id` để có khóa ngoại tới `task_index`. `delegation` không có khóa ngoại: người ủy quyền và người nhận là mã người dùng PH-12, phạm vi `scope` là JSON `{"all": true}` hoặc `{"processKeys": [...]}`.

```{.mermaid caption="ERD nhóm Saga, sự cố và thông điệp"}
erDiagram
  instance_index ||--o{ saga_log : "bù trừ"
  saga_log ||--o{ saga_step : "bước bù trừ"
  saga_step ||--o{ saga_skip_request : "đề nghị bỏ qua"
  task_index ||--o{ saga_skip_request : "việc duyệt"
  instance_index ||--o{ incident : "sự cố"
  tenant_setting
  outbox_event
  inbox_message
  legal_hold
  compliance_sample_run
  shedlock
```

Saga gồm nhật ký và các bước chạy ngược; bước thủ công sinh việc `MANUAL_COMPENSATION` ở `task_index`. Mỗi đề nghị bỏ qua gắn một bước và một việc duyệt `MANUAL_COMPENSATION`. Sáu bảng cuối không có khóa ngoại: `legal_hold` (khóa theo `business_key`, giữ có thể đặt trước phiên), `compliance_sample_run`, tham số, outbox, inbox, khóa tác vụ nền.

## 3. Đặc tả bảng

Mỗi bảng có khối đặc tả trích từ DDL (mục đích kèm FR, EN; khóa, ràng buộc, chỉ mục, cách ly tenant, phân vùng, bất biến; mục 1.3 nêu phần chung) và bảng cột có ghi chú; cột chỉ có kiểu và tên gộp ở dòng "Cột khác" (cột chỉ ghi tên có kiểu `timestamptz`, `uuid` hoặc `boolean`), bảy cột ngữ cảnh chuẩn không nhắc lại.

<!-- gen:tables:start -->
### 3.1. `process_model`

::: dac-ta
**Mục đích.** EN-11-01 Mô hình quy trình (FR-11-001, 002, 009). Khóa nghiệp vụ process_key ổn định qua các phiên bản (ví dụ LT_KHAI_SINH, DUYET_KET_NAP_HTTT); không xóa, chỉ archived kèm lý do. Giữ vĩnh viễn.

**Khóa chính.** (id).

**Duy nhất.** `uq_process_model_key` (tenant_id, process_key), `uq_process_model_tid_key` (tenant_id, id, process_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_process_model_` + `key`, `name`, `due`, `archive`, `latest`.

**Chỉ mục.** `ix_process_model_name`, `ix_process_model_group`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `process_key`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `process_key` | `varchar(64)` | Khóa quy trình, duy nhất trong tenant; cũng là khóa định nghĩa quy trình khi triển khai lên Flowable. |
| `group_code` | `varchar(32), mặc định 'KHAC'` | Nhóm nghiệp vụ tự do để lọc (API: group), ví dụ TTHC_LIEN_THONG, DUYET_NOI_BO. |
| `default_due_value` | `integer, NULL` | Hạn mặc định của phiên, kiểu T-DUE: giá trị (API defaultDue.value); đi cùng default_due_unit, cùng rỗng hoặc cùng có. |
| `default_due_unit` | `varchar(16), NULL` | Đơn vị hạn mặc định (DueUnit): WORKING_DAY, WORKING_HOUR, CALENDAR_DAY, CALENDAR_HOUR (API defaultDue.unit). |
| `allowed_starters` | `varchar(100)[], mặc định '{}'` | Mã client hoặc HTTT được khởi tạo phiên qua API (FR-11-018); rỗng là chỉ vai trò có quyền PERM-11-instance. |
| `allow_manual_start` | `boolean, mặc định false` | Cho khởi tạo thủ công trên giao diện (FR-11-020). |
| `template_code` | `varchar(64), NULL` | Mẫu dùng chung đã dùng để tạo (tham chiếu logic tới process_template, không khóa ngoại vì mẫu có thể ở tenant COMMON). |
| `archive_reason` | `varchar(2000), NULL` | Bắt buộc khi archived. |
| `latest_version` | `integer, mặc định 0` | Số phiên bản lớn nhất đã tạo (0 khi chưa có); dịch vụ tăng khi tạo phiên bản mới. |

: Cột của bảng `process_model`

Cột khác: `name` v(200); `description` v(2000); `owner_org_code` v(32); `archived`.

### 3.2. `process_version`

::: dac-ta
**Mục đích.** EN-11-02 Phiên bản mô hình, chứa BPMN 2.0 XML và checksum (FR-11-003…010). Vòng đời DRAFT, IN_REVIEW, PUBLISHED, DEPRECATED, RETIRED; từ chối duyệt về DRAFT. Mỗi mô hình đúng một phiên bản PUBLISHED (phiên bản mới thay thì bản cũ thành DEPRECATED, phiên đang chạy vẫn chạy). Nội dung bất biến từ IN_REVIEW (BR-11-005). Chỉ PUBLISHED, DEPRECATED có deployment_id Flowable. Giữ vĩnh viễn (CV 631: truy vết phiên bản quy trình).

**Khóa chính.** (id).

**Duy nhất.** `uq_process_version_no` (tenant_id, process_key, version_no), `uq_process_version_published` (tenant_id, model_id) có điều kiện, `uq_process_version_deployment` (tenant_id, deployment_id) có điều kiện, `uq_process_version_definition` (tenant_id, process_definition_id) có điều kiện.

**Khóa ngoại.** (tenant_id, model_id, process_key) → `process_model`.

**Ràng buộc CHECK.** `ck_process_version_` + `no`, `based`, `status`, `checksum`, `size`, `validation`, `review`, `lock`, `published`, `retired`.

**Chỉ mục.** `ix_process_version_status`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `model_id`, `process_key`, `version_no`; Trigger: `tg_process_version_frozen`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `model_id` | `uuid` | Mô hình cha; khóa ngoại kèm process_key để hai cột luôn khớp nhau. |
| `process_key` | `varchar(64)` | Khử chuẩn từ process_model (ngoài FRS Phụ lục A), làm đích khóa ngoại của instance_index, migration_plan theo cặp (process_key, version_no). |
| `status` | `varchar(16), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `IN_REVIEW`, `PUBLISHED`, `DEPRECATED`, `RETIRED`. |
| `bpmn_xml` | `text` | Nội dung BPMN 2.0 XML, tối đa 8 MiB (trần của tham số 11.model.maxXmlKb); đã qua kiểm tra tĩnh phía máy chủ (FR-11-005, ADR 111). |
| `checksum` | `bytea` | SHA-256 của bpmn_xml (32 byte), dùng so sánh, xuất bằng chứng (BR-11-005, FR-11-064). |
| `based_on` | `integer, NULL` | Số phiên bản làm gốc khi tạo nháp từ bản có sẵn. |
| `validation_summary` | `jsonb, NULL` | Tóm tắt kiểm tra tĩnh gần nhất: blocking, errorCount, warningCount, checkedAt (API ValidationSummary); phải blocking = false trước khi gửi duyệt (FR-11-007). |
| `lock_owner` | `varchar(64), NULL` | Người đang giữ khóa soạn thảo (FR-11-003); chỉ bản DRAFT; hết hạn sau 11.designer.lockMinutes (lock_until). |
| `deployment_id` | `varchar(64), NULL` | Mã triển khai Flowable, ghi khi duyệt phát hành (FR-11-008). |
| `process_definition_id` | `varchar(128), NULL` | Mã định nghĩa quy trình Flowable (ACT_RE_PROCDEF.ID_) do lần triển khai tạo ra. |

: Cột của bảng `process_version`

Cột khác: `version_no` int; `change_summary` v(2000); `lock_until`; `published_at`; `deprecated_at`; `retired_at`; `retire_reason` v(2000).

### 3.3. `form_definition`

::: dac-ta
**Mục đích.** EN-11-03 Biểu mẫu việc người dùng bằng JSON Schema (FR-11-012). Có phiên bản; mỗi form_key đúng một phiên bản PUBLISHED; PUBLISHED không đổi nội dung (BR-11-005; việc đang mở vẫn hiển thị đúng bản đã gắn). Giữ vĩnh viễn.

**Khóa chính.** (id).

**Duy nhất.** `uq_form_definition_no` (tenant_id, form_key, version_no), `uq_form_definition_published` (tenant_id, form_key) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_form_definition_` + `key`, `no`, `status`, `schema`, `decisions`, `classification`, `checksum`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `form_key`, `version_no`; Trigger: `tg_form_definition_frozen`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(16), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `PUBLISHED`, `RETIRED`. |
| `schema` | `jsonb` | JSON Schema (draft 2020-12) mô tả trường nhập; việc kiểm dữ liệu theo schema này khi hoàn thành việc (FR-11-038). |
| `ui_schema` | `jsonb, mặc định '{}'` | Gợi ý bố cục, nhãn, thứ tự trường cho giao diện. |
| `decisions` | `varchar(24)[], mặc định '{COMPLETE}'` | Các quyết định cho phép khi hoàn thành việc (Decision): APPROVE, REJECT, RETURN, REQUEST_SUPPLEMENT, COMPLETE. |
| `field_classification` | `jsonb, mặc định '{}'` | Phân loại dữ liệu từng trường (DataClass); trường SENSITIVE mã hóa khi lưu kết quả (BR-11-014). |
| `checksum` | `bytea` | SHA-256 của schema, ui_schema, decisions (32 byte), chống sai lệch nội dung. |

: Cột của bảng `form_definition`

Cột khác: `form_key` v(64); `version_no` int; `name` v(200); `description` v(2000).

### 3.4. `service_intent`

::: dac-ta
**Mục đích.** EN-11-04 Ý định nghiệp vụ ánh xạ sang luồng PH-04 (FR-11-013, 028). Service task trong BPMN chỉ khai ý định (ví dụ guiTuPhap, BR-11-002); PH-11 gửi lệnh {tenant}.bpm.service.requested.v1, PH-04 thực thi (ADR 112). Phát hành mô hình yêu cầu mọi ý định được dùng đều ACTIVE có ánh xạ luồng ở môi trường đích (BR-11-003). Không xóa. Giữ vĩnh viễn.

**Khóa chính.** (id).

**Duy nhất.** `uq_service_intent_code` (tenant_id, intent_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_service_intent_` + `code`, `status`, `errors`, `bindings`, `timeout`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `intent_code`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(16), mặc định 'ACTIVE'` | Giá trị: `ACTIVE`, `DEPRECATED`. |
| `input_schema` | `jsonb, NULL` | JSON Schema của dữ liệu vào (API inputSchema); kiểm khi dựng lệnh (FR-11-028). |
| `output_schema` | `jsonb, NULL` | JSON Schema của kết quả (API outputSchema); kiểm khi nhận kết quả (FR-11-029). |
| `writes_external` | `boolean, mặc định false` | Ý định ghi dữ liệu ra HTTT ngoài: bước dùng nó phải có bù trừ hoặc miễn đã duyệt (BR-11-008). |
| `business_errors` | `jsonb, mặc định '[]'` | Mảng mã lỗi nghiệp vụ mà bước có thể ném BpmnError (API businessErrors). |
| `bindings` | `jsonb, mặc định '[]'` | Mảng ánh xạ môi trường sang luồng PH-04: {environment (TEST, STAGING, PROD), flowCode, flowVersion}; mã luồng là tham chiếu logic liên phân hệ, kiểm ở dịch vụ, không khóa ngoại. |
| `timeout_seconds` | `integer, NULL` | Thời gian chờ kết quả riêng của ý định (API timeoutSeconds); rỗng thì dùng tham số 11.service.defaultTimeoutMinutes; quá hạn mở sự cố SERVICE_TIMEOUT (FR-11-029). |

: Cột của bảng `service_intent`

Cột khác: `intent_code` v(64); `name` v(200); `description` v(2000).

### 3.5. `compensation_action`

::: dac-ta
**Mục đích.** EN-11-05 Hành động bù trừ theo bước của một phiên bản mô hình (FR-11-014, 051). Mỗi bước xuôi có tối đa một dòng; policy AUTO gọi ý định bù trừ, MANUAL chuyển việc xử lý thủ công, NONE_APPROVED là không bù trừ có miễn đã duyệt (BR-11-008, ví dụ không xóa khai sinh). Mọi dòng phải có ghi chú nghiệp vụ từ 20 ký tự (BR-11-009).

**Khóa chính.** (id).

**Duy nhất.** `uq_compensation_action_step` (tenant_id, version_id, element_id).

**Khóa ngoại.** (tenant_id, version_id) → `process_version`, (tenant_id, compensation_intent_code) → `service_intent`, (tenant_id, verify_intent_code) → `service_intent`.

**Ràng buộc CHECK.** `ck_compensation_action_` + `policy`, `intent`, `note`, `waiver`, `mapping`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `version_id`, `element_id`; Trigger: `tg_compensation_action_child`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `element_id` | `varchar(100)` | Id phần tử BPMN của bước xuôi cần bù trừ. |
| `policy` | `varchar(16), mặc định 'AUTO'` | Giá trị: `AUTO`, `MANUAL`, `NONE_APPROVED`. |
| `compensation_intent_code` | `varchar(64), NULL` | Ý định bù trừ gửi PH-04; bắt buộc khi AUTO. |
| `input_mapping` | `jsonb, mặc định '{}'` | Ánh xạ dữ liệu vào cho lệnh bù trừ (API inputMapping). |
| `verify_intent_code` | `varchar(64), NULL` | Ý định kiểm tra hiệu lực bù trừ ở hệ thống đích, dùng khi đối soát (FR-11-054). |
| `waiver_approved_by` | `varchar(64), NULL` | Người có quyền duyệt miễn bù trừ; bắt buộc khi NONE_APPROVED (BR-11-008). |

: Cột của bảng `compensation_action`

Cột khác: `version_id`; `business_note` v(2000).

### 3.6. `process_template`

::: dac-ta
**Mục đích.** EN-11-06 Mẫu quy trình dùng chung (FR-11-015). Mẫu nền tảng ở tenant COMMON chỉ PA ghi (phiên PLATFORM, BR-11-027); mọi tenant đọc được (mẫu S) và tự tạo mẫu riêng. Tạo mô hình từ mẫu là sao chép source_xml, mô hình chỉ lưu template_code. PUBLISHED không đổi nội dung (BR-11-005). Giữ vĩnh viễn.

**Khóa chính.** (id).

**Duy nhất.** `uq_process_template_no` (tenant_id, template_code, version_no), `uq_process_template_published` (tenant_id, template_code) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_process_template_` + `code`, `no`, `status`, `placeholders`, `checksum`, `size`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu S (mục 1.2): tenant đọc thêm dòng COMMON.

**Phân vùng, bất biến.** Bất biến: `template_code`, `version_no`; Trigger: `tg_process_template_frozen`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(16), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `PUBLISHED`, `RETIRED`. |
| `placeholders` | `jsonb, mặc định '[]'` | Mảng tên chỗ giữ chỗ (ví dụ mã ý định, nhóm xử lý) người dùng phải điền khi tạo mô hình từ mẫu. |

: Cột của bảng `process_template`

Cột khác: `template_code` v(64); `version_no` int; `name` v(200); `description` v(2000); `group_code` v(32); `source_xml` text; `checksum` bytea.

### 3.7. `variable_definition`

::: dac-ta
**Mục đích.** EN-11-07 Khai báo biến quy trình và phân loại dữ liệu (FR-11-016). RESTRICTED (hạn chế) phải che ở tiến độ và bản chiếu; SENSITIVE (nhạy cảm) phải mã hóa envelope trước khi vào engine và che, không bao giờ lộ ra tiến độ, sự kiện, nhật ký (BR-11-014, 015; CMP-LAW-04, 05).

**Khóa chính.** (id).

**Duy nhất.** `uq_variable_definition_name` (tenant_id, version_id, name).

**Khóa ngoại.** (tenant_id, version_id) → `process_version`.

**Ràng buộc CHECK.** `ck_variable_definition_` + `name`, `type`, `class`, `editable`, `sensitive`, `restricted`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `version_id`, `name`; Trigger: `tg_variable_definition_child`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `type` | `varchar(12), mặc định 'STRING'` | Kiểu biến (VariableType): STRING, NUMBER, BOOLEAN, DATE, DATETIME, JSON, CODE_REF, FILE_REF. |
| `data_class` | `varchar(16), mặc định 'INTERNAL'` | Phân loại theo PH-09 (DataClass): PUBLIC, INTERNAL, RESTRICTED (HC), SENSITIVE (NC). |
| `encrypt` | `boolean, mặc định false` | Giá trị mã hóa envelope (OpenBao transit, ADR-032) và lưu ở engine dưới dạng tham chiếu bpm-secret; bắt buộc với SENSITIVE. |
| `mask` | `boolean, mặc định false` | Che giá trị khi hiển thị cho người không có quyền xem rõ; bắt buộc với RESTRICTED, SENSITIVE. |
| `editable_by` | `varchar(16), mặc định 'NONE'` | Ai được sửa giá trị khi phiên chạy: NONE, TASK (qua việc), ADMIN_CHANGE (qua đề nghị instance_change, FR-11-025). |

: Cột của bảng `variable_definition`

Cột khác: `version_id`; `name` v(64); `required_at_start`.

### 3.8. `decision_table`

::: dac-ta
**Mục đích.** EN-11-24 Bảng quyết định DMN đơn giản cho rẽ nhánh (FR-11-017, mức C). Chính sách trúng UNIQUE hoặc FIRST; lưu dạng inputs, outputs, rules, dịch vụ sinh DMN XML khi triển khai cùng phiên bản mô hình. PUBLISHED không đổi nội dung (BR-11-005). Giữ vĩnh viễn theo phiên bản.

**Khóa chính.** (id).

**Duy nhất.** `uq_decision_table_no` (tenant_id, code, version_no), `uq_decision_table_published` (tenant_id, code) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_decision_table_` + `code`, `no`, `status`, `hit`, `shape`, `checksum`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `code`, `version_no`; Trigger: `tg_decision_table_frozen`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(16), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `PUBLISHED`, `RETIRED`. |
| `hit_policy` | `varchar(8), mặc định 'UNIQUE'` | Giá trị: `UNIQUE`, `FIRST`. |
| `inputs` | `jsonb` | Mảng biến đầu vào của bảng (tên biến, kiểu). |
| `outputs` | `jsonb` | Mảng biến đầu ra của bảng. |
| `rules` | `jsonb, mặc định '[]'` | Mảng dòng quy tắc: điều kiện FEEL đơn giản theo từng đầu vào và giá trị đầu ra. |
| `checksum` | `bytea` | SHA-256 của inputs, outputs, rules, hit_policy (32 byte). |

: Cột của bảng `decision_table`

Cột khác: `code` v(64); `version_no` int; `name` v(200).

### 3.9. `publish_request`

::: dac-ta
**Mục đích.** EN-11-20 Yêu cầu duyệt phát hành, khôi phục hoặc đưa mẫu lên dùng chung (FR-11-007, 008), bốn mắt: người duyệt khác người gửi (BR-11-004, PERM-11-publish). Ghi chú thay đổi từ 10 ký tự; duyệt cần ý kiến, từ chối cần lý do từ 20 ký tự (BR-11-033). DEPLOY_FAILED khi duyệt xong nhưng triển khai lên engine lỗi. Mỗi phiên bản, mỗi loại yêu cầu chỉ một yêu cầu PENDING.

**Khóa chính.** (id).

**Duy nhất.** `uq_publish_request_pending` (tenant_id, version_id, kind) có điều kiện.

**Khóa ngoại.** (tenant_id, version_id) → `process_version`.

**Ràng buộc CHECK.** `ck_publish_request_` + `kind`, `status`, `note`, `checksum`, `four_eyes`, `decided`, `reject`.

**Chỉ mục.** `ix_publish_request_status`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `version_id`, `kind`, `release_note`, `checksum`, `requested_by`, `requested_at`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `kind` | `varchar(12), mặc định 'PUBLISH'` | Loại yêu cầu (API kind): PUBLISH phát hành bản mới, RESTORE khôi phục bản đã ngừng dùng, TEMPLATE đưa lên mẫu dùng chung. |
| `checksum` | `bytea` | SHA-256 BPMN XML tại lúc gửi; người duyệt xem đúng bản đã kiểm, nội dung đổi thì không còn khớp. |
| `status` | `varchar(16), mặc định 'PENDING'` | Giá trị: `PENDING`, `APPROVED`, `REJECTED`, `WITHDRAWN`, `DEPLOY_FAILED`. |
| `comment` | `varchar(2000), NULL` | Ý kiến của người duyệt (bắt buộc khi quyết định); lý do từ 20 ký tự khi từ chối. |
| `task_id` | `uuid, NULL` | Việc duyệt trong hộp việc (task_index.id, task_kind PUBLISH_REVIEW), tham chiếu logic. |

: Cột của bảng `publish_request`

Cột khác: `version_id`; `release_note` v(2000); `requested_by` v(64); `requested_at`; `decided_by` v(64); `decided_at`.

### 3.10. `test_run`

::: dac-ta
**Mục đích.** EN-11-26 Lần chạy thử một phiên bản nháp với service task giả lập (FR-11-011, API-11-025…027). Phiên chạy thử là dòng instance_index có start_channel TEST; không ghi outbox, không gửi lệnh PH-04, triển khai vào tenantId Flowable thử (BR-11-036). Kết quả (dòng thời gian, biến đã che, việc, Saga) ở result, đính kèm yêu cầu duyệt. Dọn sau 11.test.retentionDays ngày.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, version_id) → `process_version`.

**Ràng buộc CHECK.** `ck_test_run_` + `status`, `scenario`, `ended`, `result`.

**Chỉ mục.** `ix_test_run_version`, `ix_test_run_cleanup`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `version_id`, `scenario`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `scenario` | `jsonb, mặc định '{}'` | Kịch bản giả lập: kết quả cho từng service task (COMPLETE, BUSINESS_ERROR, TECHNICAL_ERROR, TIMEOUT), đồng hồ REAL hoặc ACCELERATED, tự hoàn thành việc. |
| `status` | `varchar(8), mặc định 'RUNNING'` | Giá trị: `RUNNING`, `PASSED`, `FAILED`, `ABORTED`. |
| `engine_instance_id` | `varchar(64), NULL` | Mã phiên chạy thử trong Flowable. |
| `result` | `jsonb, NULL` | Kết quả chạy: timeline, variables (đã che), tasks, saga (API TestRun); không chứa giá trị SENSITIVE. |

: Cột của bảng `test_run`

Cột khác: `version_id`; `ended_at`.

### 3.11. `instance_index`

::: dac-ta
**Mục đích.** EN-11-08 Bản chiếu phiên quy trình để liệt kê, tìm kiếm, tra tiến độ có RLS (FR-11-018…027, 055). Nguồn sự thật là engine (engine_instance_id). Một business_key (mã hồ sơ) chỉ một phiên đang sống mỗi mô hình, trừ phiên chạy thử (BR-11-007); idempotency_key chỉ một phiên. Không lưu giá trị biến; progress_public chỉ chứa dữ liệu đã che (BR-11-015).

**Khóa chính.** (id).

**Duy nhất.** `uq_instance_index_engine` (tenant_id, engine_instance_id), `uq_instance_index_idempotency` (tenant_id, idempotency_key), `uq_instance_index_live_key` (tenant_id, process_key, business_key) có điều kiện.

**Khóa ngoại.** (tenant_id, process_key, version_no) → `process_version`, (tenant_id, parent_instance_id) → `instance_index`.

**Ràng buộc CHECK.** `ck_instance_index_` + `status`, `wait`, `channel`, `test`, `call`, `ended`, `suspended`, `reason`, `progress`, `elements`, `trace`, `migrated`.

**Chỉ mục.** `ix_instance_index_list`, `ix_instance_index_model`, `ix_instance_index_bkey`, `ix_instance_index_parent`, `ix_instance_index_ended`, `ix_instance_index_test`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `engine_instance_id`, `process_key`, `business_key`, `start_channel`, `initiator`, `started_at`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `engine_instance_id` | `varchar(64)` | Mã phiên trong Flowable (ACT_RU_EXECUTION.PROC_INST_ID_). |
| `process_key` | `varchar(64)` | Khóa mô hình, cùng version_no tạo khóa ngoại tới process_version. |
| `business_key` | `varchar(100)` | Mã hồ sơ do bên gọi cung cấp, 3…100 ký tự, không chứa dữ liệu cá nhân; API tiến độ tra theo khóa này (kênh DVC). |
| `idempotency_key` | `varchar(120), NULL` | Idempotency-Key khi khởi tạo, hiệu lực 24 giờ (BR-11-007): dịch vụ đặt NULL sau 24 giờ; trong cửa sổ, gọi lại trả phiên cũ (FR-11-018). |
| `status` | `varchar(16), mặc định 'RUNNING'` | Giá trị: `RUNNING`, `SUSPENDED`, `COMPENSATING`, `COMPLETED`, `CANCELLED`, `COMPENSATED`, `FAILED`. |
| `wait_state` | `varchar(16), mặc định 'NONE'` | Trạng thái chờ (WaitState): NONE, WAITING_USER, WAITING_SERVICE, WAITING_MESSAGE, WAITING_TIMER. |
| `current_elements` | `jsonb, mặc định '[]'` | Mảng id các phần tử BPMN đang chờ (API currentElements); cập nhật theo sự kiện của engine. |
| `start_channel` | `varchar(16), mặc định 'API'` | Kênh khởi tạo (StartChannel): API, EVENT, MANUAL, CALL_ACTIVITY (có parent_instance_id), TIMER, TEST (phiên chạy thử, is_test). |
| `initiator` | `varchar(64)` | Người hoặc tài khoản máy khởi tạo (PH-12). |
| `client_id` | `varchar(64), NULL` | client_id OAuth của HTTT gọi khởi tạo (PH-01, PH-12), rỗng khi khởi tạo thủ công; dùng cho hạn mức 11.instance.startRatePerClient. |
| `due_at` | `timestamptz, NULL` | Hạn của phiên, chép từ due_tracking để lọc và sắp xếp danh sách (FR-11-021). |
| `status_reason` | `varchar(2000), NULL` | Lý do hủy, tạm dừng hoặc thất bại; bắt buộc từ 10 ký tự khi CANCELLED, FAILED. |
| `progress_percent` | `smallint, mặc định 0` | Ước lượng phần trăm tiến độ cho kênh DVC (API percentEstimate). |
| `progress_public` | `jsonb, mặc định '{}'` | Tiến độ hiển thị cho kênh DVC (publicName, trạng thái công khai), đã che dữ liệu RESTRICTED, SENSITIVE (BR-11-015, FR-11-055). |
| `migrated_from_version` | `integer, NULL` | Số phiên bản mô hình trước khi di trú (FR-11-026); rỗng nếu chưa di trú. |

: Cột của bảng `instance_index`

Cột khác: `version_no` int; `parent_instance_id`; `trace_id` char(32); `started_at`; `ended_at`; `is_test`; `suspended_at`.

### 3.12. `instance_step`

::: dac-ta
**Mục đích.** EN-11-28 Lịch sử bước của phiên (FR-11-022, 056, 057, 059, 064), giữ 5 năm, phân vùng tháng. Mỗi lần vào một phần tử BPMN một dòng, cập nhật khi ra. Là bằng chứng kiểm toán, nguồn dòng thời gian và tiến độ. Không chứa giá trị biến (summary đã che).

**Khóa chính.** (id, started_at).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, instance_id) → `instance_index`.

**Ràng buộc CHECK.** `ck_instance_step_` + `type`, `status`, `ended`, `duration`, `trace`.

**Chỉ mục.** `ix_instance_step_instance`, `ix_instance_step_element`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Phân vùng tháng theo `started_at`; Bất biến: `instance_id`, `element_id`, `step_type`, `started_at`.

**Ghi chú.** Không có `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `element_id` | `varchar(100)` | Id phần tử trong BPMN. |
| `step_type` | `varchar(24)` | Loại phần tử BPMN (StepType, bảng 6.2-a của FRS). Giá trị: `START_EVENT`, `END_EVENT`, `USER_TASK`, `SERVICE_TASK`, `SEND_TASK`, `BUSINESS_RULE_TASK`, `EXCLUSIVE_GATEWAY`, `PARALLEL_GATEWAY`, `INCLUSIVE_GATEWAY`, `EVENT_BASED_GATEWAY`, `TIMER_EVENT`, `MESSAGE_EVENT`, `COMPENSATION_THROW`, `TIMER_BOUNDARY`, `ERROR_BOUNDARY`, `COMPENSATION_BOUNDARY`, `MESSAGE_BOUNDARY`, `SUB_PROCESS`, `CALL_ACTIVITY`. |
| `status` | `varchar(12), mặc định 'ACTIVE'` | Giá trị: `ACTIVE`, `COMPLETED`, `FAILED`, `CANCELLED`, `COMPENSATED`. |
| `actor` | `varchar(64), NULL` | Người xử lý với bước việc, rỗng với bước hệ thống. |
| `result_code` | `varchar(32), NULL` | Kết quả ngắn: quyết định của việc (Decision), mã lỗi của service task. |
| `summary` | `jsonb, mặc định '{}'` | Tóm tắt đã che dữ liệu cá nhân (không chứa giá trị biến RESTRICTED, SENSITIVE). |

: Cột của bảng `instance_step`

Cột khác: `id`; `tenant_id` v(16); `started_at`; `instance_id`; `element_name` v(255); `ended_at`; `duration_ms` bigint; `trace_id` char(32), phân vùng `RANGE (started_at)`.

### 3.13. `service_call`

::: dac-ta
**Mục đích.** EN-11-25 Lệnh service task đã gửi tới PH-04 và kết quả nhận về (FR-11-028, 029, 060). Mỗi lệnh một dòng theo command_id (UUID v5 xác định theo tenant, processInstanceId, executionId, activityId, lần giao lệnh; BR-11-022); gửi lại cùng command_id thì tăng attempt, PH-04 chống trùng theo command_id. Kết quả từ {tenant}.bpm.service.completed.v1 hoặc .failed.v1 (EVT-11-18, 19) tương quan theo command_id; quá timeout_at thì tác vụ nền chuyển TIMED_OUT và mở sự cố SERVICE_TIMEOUT (ADR 112).

**Khóa chính.** (id).

**Duy nhất.** `uq_service_call_command` (tenant_id, command_id).

**Khóa ngoại.** (tenant_id, instance_id) → `instance_index`, (tenant_id, intent_code) → `service_intent`.

**Ràng buộc CHECK.** `ck_service_call_` + `status`, `kind`, `attempt`, `done`, `error`, `timeout`, `trace`.

**Chỉ mục.** `ix_service_call_instance`, `ix_service_call_timeout`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `instance_id`, `element_id`, `intent_code`, `command_id`, `requested_at`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `command_id` | `uuid` | Mã lệnh (UUID) mang trong sự kiện service.requested và kết quả trả về; khóa tương quan, bảo đảm xử lý kết quả một lần. |
| `status` | `varchar(12), mặc định 'REQUESTED'` | ServiceCallStatus: REQUESTED, COMPLETED, FAILED (lỗi nghiệp vụ hoặc kỹ thuật), TIMED_OUT, CANCELLED. |
| `attempt` | `smallint, mặc định 1` | Số lần gửi cùng command_id; tăng khi vận hành bấm gửi lại (FR-11-028). |
| `timeout_at` | `timestamptz` | Hạn chờ kết quả = requested_at + thời gian chờ của ý định hoặc 11.service.defaultTimeoutMinutes. |
| `output_ref` | `varchar(255), NULL` | Tham chiếu tới kết quả đã ghi vào biến phiên (tên biến hoặc bpm-secret); không chứa giá trị. Kết quả đầy đủ chỉ nằm ở biến quy trình trong engine. |
| `error_kind` | `varchar(12), NULL` | ErrorKind: BUSINESS (đi nhánh lỗi, Saga) hoặc TECHNICAL (thử lại, mở sự cố); bắt buộc khi FAILED. |
| `error_message` | `varchar(2000), NULL` | Thông điệp lỗi đã lược dữ liệu cá nhân. |

: Cột của bảng `service_call`

Cột khác: `instance_id`; `element_id` v(100); `intent_code` v(64); `requested_at`; `completed_at`; `error_code` v(64); `trace_id` char(32).

### 3.14. `instance_change`

::: dac-ta
**Mục đích.** EN-11-27 Đề nghị can thiệp phiên đang chạy: sửa biến (VARIABLE_UPDATE, FR-11-025) hoặc chuyển bước (MOVE_TOKEN, FR-11-027), API-11-059…062. Bốn mắt (BR-11-021): người duyệt khác người đề nghị; lý do từ 20 ký tự, chuyển bước từ 30. approved_by ghi người quyết định, kể cả khi REJECTED. Là bằng chứng kiểm toán: không xóa (quyền), giữ 5 năm sau khi phiên kết thúc.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, instance_id) → `instance_index`.

**Ràng buộc CHECK.** `ck_instance_change_` + `type`, `status`, `payload`, `reason`, `four_eyes`, `decided`, `applied`.

**Chỉ mục.** `ix_instance_change_instance`, `ix_instance_change_pending`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `instance_id`, `type`, `payload`, `reason`, `requested_by`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `type` | `varchar(16)` | ChangeType: VARIABLE_UPDATE hoặc MOVE_TOKEN. |
| `payload` | `jsonb, mặc định '{}'` | VARIABLE_UPDATE: danh sách {name, giá trị mới}, biến SENSITIVE chỉ ghi tham chiếu bpm-secret, không ghi giá trị rõ (BR-11-014); MOVE_TOKEN: fromElementIds, toElementId, skipCompensation. |
| `status` | `varchar(8), mặc định 'PENDING'` | ChangeStatus: PENDING chờ duyệt, APPLIED đã áp dụng vào engine, REJECTED bị từ chối. |
| `approved_by` | `varchar(64), NULL` | Người quyết định (duyệt hoặc từ chối), khác requested_by. |

: Cột của bảng `instance_change`

Cột khác: `instance_id`; `reason` v(2000); `requested_by` v(64); `applied_at`.

### 3.15. `task_index`

::: dac-ta
**Mục đích.** EN-11-09 Bản chiếu việc người dùng cho hộp "Việc của tôi" (FR-11-034…044, FR-00-070). Nguồn sự thật là engine (engine_task_id). Việc giao qua ủy quyền giữ người gốc ở delegated_from. Từ chối, trả về, yêu cầu bổ sung bắt buộc ý kiến từ 20 ký tự (BR-11-033). Kết quả biểu mẫu: phần không nhạy cảm ở result_data, phần SENSITIVE chỉ ở result_enc (mã hóa envelope).

**Khóa chính.** (id).

**Duy nhất.** `uq_task_index_engine` (tenant_id, engine_task_id).

**Khóa ngoại.** (tenant_id, instance_id) → `instance_index`.

**Ràng buộc CHECK.** `ck_task_index_` + `kind`, `status`, `assignee`, `candidates`, `delegated`, `closed`, `decision`, `completed`, `comment`, `priority`, `form`, `enc`, `trace`.

**Chỉ mục.** `ix_task_index_assignee`, `ix_task_index_candidates`, `ix_task_index_instance`, `ix_task_index_due`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `engine_task_id`, `instance_id`, `element_id`, `task_kind`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `task_kind` | `varchar(24), mặc định 'STANDARD'` | TaskKind: STANDARD, APPROVAL, PUBLISH_REVIEW (duyệt phát hành, publish_request), MANUAL_COMPENSATION (xử lý bù trừ thủ công, saga_step), INCIDENT_HANDLING (xử lý sự cố). |
| `status` | `varchar(12), mặc định 'UNASSIGNED'` | Giá trị: `UNASSIGNED`, `ASSIGNED`, `DELEGATED`, `COMPLETED`, `CANCELLED`. |
| `candidates` | `varchar(100)[], mặc định '{}'` | Ứng viên nhận việc: mã người dùng, hoặc nhóm dạng group:{mã nhóm}; đơn vị được khai triển thành thành viên tại lúc tạo việc và chỉ chụp lại một lần (BR-11-037). Việc UNASSIGNED hiện cho các ứng viên; GIN phục vụ hộp việc. |
| `delegated_from` | `varchar(64), NULL` | Người được giao gốc khi việc DELEGATED (ủy quyền, FR-11-041); assignee là người đang xử lý. |
| `form_version` | `integer, NULL` | Phiên bản biểu mẫu đã gắn lúc tạo việc, để hiển thị đúng bản dù biểu mẫu có phiên bản mới. |
| `draft` | `jsonb, NULL` | Bản nháp kết quả (FR-11-039), chỉ trường không nhạy cảm; trường SENSITIVE không lưu nháp. |
| `decision` | `varchar(24), NULL` | Quyết định khi hoàn thành (Decision): APPROVE, REJECT, RETURN, REQUEST_SUPPLEMENT, COMPLETE. |
| `completed_by` | `varchar(64), NULL` | Người hoàn thành thực tế (người nhận hoặc người được ủy quyền, BR-11-016). |
| `ai_assisted` | `boolean, mặc định false` | Có dùng gợi ý AI của PH-17 khi xử lý (BR-11-029, FR-11-066). |
| `result_enc` | `bytea, NULL` | Phần SENSITIVE của kết quả, mã hóa envelope (OpenBao transit); result_kid ghi khóa. |
| `inbox_item_id` | `uuid, NULL` | Mã mục trong hộp việc chung (FR-00-070), tham chiếu logic. |

: Cột của bảng `task_index`

Cột khác: `engine_task_id` v(64); `instance_id`; `element_id` v(100); `name` v(255); `assignee` v(64); `form_key` v(64); `priority` smallint; `due_at`; `claimed_at`; `closed_at`; `decision_comment` v(4000); `result_data` jsonb; `result_kid` v(64); `trace_id` char(32).

### 3.16. `task_comment`

::: dac-ta
**Mục đích.** EN-11-10 Ý kiến, trao đổi trên việc (FR-11-043, 038). Chỉ thêm, không sửa, xóa (trigger, quyền): ý kiến là một phần của hồ sơ xử lý. kind OPINION là ý kiến chính thức khi hoàn thành việc, SYSTEM là ghi chú tự sinh (giao lại, trả về).

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, task_id) → `task_index`, (tenant_id, instance_id) → `instance_index`.

**Ràng buộc CHECK.** `ck_task_comment_` + `kind`, `text`.

**Chỉ mục.** `ix_task_comment_task`, `ix_task_comment_instance`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Trigger: `tg_task_comment_append_only`.

**Ghi chú.** Không có `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `instance_id` | `uuid` | Phiên của việc (khử chuẩn để xem toàn bộ trao đổi theo hồ sơ). |
| `kind` | `varchar(8), mặc định 'COMMENT'` | Giá trị: `COMMENT`, `OPINION`, `SYSTEM`. |
| `text` | `varchar(4000)` | Nội dung ý kiến, 1…4.000 ký tự (FR-11-043); không chứa giá trị biến SENSITIVE. |
| `mentions` | `varchar(64)[], mặc định '{}'` | Mã người dùng được nhắc tên (API mentions). |

: Cột của bảng `task_comment`

Cột khác: `id`; `tenant_id` v(16); `task_id`; `author` v(64); `created_at`; `created_by` v(64).

### 3.17. `task_attachment`

::: dac-ta
**Mục đích.** EN-11-11 Tệp đính kèm việc (FR-11-043). Nội dung tệp ở Ceph RGW (object_ref, mã hóa phía máy chủ), bảng chỉ giữ siêu dữ liệu và SHA-256; tối đa 50 MiB mỗi tệp (trần của 11.task.attachmentMaxMb); chỉ tệp CLEAN sau quét mới tải được. Gỡ tệp là đánh dấu removed_at, không xóa dòng.

**Khóa chính.** (id).

**Duy nhất.** `uq_task_attachment_ref` (tenant_id, object_ref).

**Khóa ngoại.** (tenant_id, task_id) → `task_index`, (tenant_id, instance_id) → `instance_index`.

**Ràng buộc CHECK.** `ck_task_attachment_` + `size`, `checksum`, `class`, `scan`, `removed`.

**Chỉ mục.** `ix_task_attachment_task`, `ix_task_attachment_instance`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `task_id`, `file_name`, `size`, `checksum`, `object_ref`, `data_class`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `size` | `bigint` | Kích thước tệp tính bằng byte (API size). |
| `checksum` | `bytea` | SHA-256 nội dung tệp (32 byte). |
| `object_ref` | `varchar(512)` | Khóa đối tượng trên Ceph RGW: bpm/{tenant}/{instanceId}/{attachmentId}. |
| `data_class` | `varchar(16), mặc định 'INTERNAL'` | Phân loại dữ liệu do người tải khai (DataClass); tệp SENSITIVE chỉ người có quyền xem rõ mới tải được. Giá trị: `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE`. |
| `scan_status` | `varchar(8), mặc định 'PENDING'` | Kết quả quét mã độc: PENDING, CLEAN, INFECTED (INFECTED bị chặn tải, báo người dùng). |

: Cột của bảng `task_attachment`

Cột khác: `task_id`; `instance_id`; `file_name` v(255); `content_type` v(127); `removed_at`; `removed_by` v(64).

### 3.18. `delegation`

::: dac-ta
**Mục đích.** EN-11-12 Ủy quyền xử lý việc khi vắng mặt (FR-11-041). Người ủy quyền giao toàn bộ việc (scope {"all": true}) hoặc việc của một số mô hình (scope {"processKeys": [...]}) cho người nhận trong khoảng thời gian tối đa 90 ngày (trần của 11.delegation.maxDays); hai ủy quyền SCHEDULED hoặc ACTIVE của cùng người, cùng phạm vi không chồng thời gian (EXCLUDE). Hết hạn do tác vụ nền; thu hồi sớm ghi revoked_*.

**Khóa chính.** (id).

**Duy nhất.** `ex_delegation_overlap` loại trừ chồng USING gist (tenant_id WITH =, from_user WITH =, scope_key WITH =, tstzrange(valid_from, va.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_delegation_` + `status`, `distinct`, `period`, `scope`, `revoked`.

**Chỉ mục.** `ix_delegation_to_user`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `from_user`, `to_user`, `scope`, `valid_from`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `from_user` | `varchar(64)` | Mã người dùng ủy quyền (PH-12). |
| `to_user` | `varchar(64)` | Mã người dùng nhận ủy quyền, cùng tenant (BR-11-020). |
| `valid_to` | `timestamptz` | Hết hiệu lực; không quá 90 ngày sau valid_from. Tham số 11.delegation.maxDays của tenant có thể chặt hơn, kiểm ở dịch vụ. |
| `scope` | `jsonb, mặc định '{"all": true}'` | Phạm vi (API scope): {"all": true} mọi mô hình, hoặc {"processKeys": [mã mô hình...]}. |
| `scope_key` | `varchar(512) GENERATED ALWAYS AS (CASE WHEN scope ? 'processKeys' THEN scope ->> 'processKeys' ELSE '*' END) STORED, NULL` | Cột sinh từ scope để so phạm vi trong ràng buộc loại trừ chồng thời gian: * hoặc chuỗi processKeys. |
| `include_existing` | `boolean, mặc định false` | Chuyển cả việc đang giữ sang người nhận khi ủy quyền có hiệu lực. |
| `status` | `varchar(12), mặc định 'SCHEDULED'` | Giá trị: `SCHEDULED`, `ACTIVE`, `EXPIRED`, `REVOKED`. |

: Cột của bảng `delegation`

Cột khác: `valid_from`; `reason` v(2000); `revoked_at`; `revoked_by` v(64).

### 3.19. `business_calendar`

::: dac-ta
**Mục đích.** EN-11-13 Lịch làm việc của tenant theo năm (FR-11-045, ADR 114): thứ làm việc trong tuần, giờ làm việc, nghỉ trưa, múi giờ cố định Asia/Ho_Chi_Minh (BR-11-017). Mỗi tenant một dòng mỗi năm; PA khai lịch nền quốc gia ở tenant COMMON (mẫu S: tenant đọc được), tenant chưa khai năm nào thì dịch vụ dùng lịch COMMON hoặc lịch mặc định và ghi ERR-11-116. Không xóa (due_tracking tính theo lịch).

**Khóa chính.** (id).

**Duy nhất.** `uq_business_calendar_year` (tenant_id, year).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_business_calendar_` + `year`, `week`, `hours`, `break`, `inherited`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu S (mục 1.2): tenant đọc thêm dòng COMMON.

**Phân vùng, bất biến.** Bất biến: `year`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `year` | `smallint` | Năm dương lịch của lịch. |
| `work_week` | `varchar(3)[], mặc định '{MON,TUE,WED,THU,FRI}'` | Các thứ làm việc trong tuần (API workDays): MON, TUE, WED, THU, FRI, SAT, SUN; mặc định thứ Hai đến thứ Sáu. |
| `work_hours` | `jsonb, mặc định '{"start": "07:30", "end": "17:00", "breakStart": "11:30", "breakEnd": "13:30"}'` | Giờ làm việc (API workHours): start, end, breakStart, breakEnd dạng HH:MM; breakStart và breakEnd cùng có hoặc cùng không, nằm trong khoảng start đến end. Mặc định 07:30 đến 17:00, nghỉ trưa 11:30 đến 13:30. |
| `inherited_from` | `varchar(16), NULL` | COMMON khi lịch năm này sao chép từ lịch nền quốc gia ("Nhập từ lịch quốc gia"); rỗng khi tenant tự khai. |

: Cột của bảng `business_calendar`


### 3.20. `calendar_day`

::: dac-ta
**Mục đích.** EN-11-14 Ngày nghỉ lễ (HOLIDAY), ngày làm bù (MAKEUP_WORKDAY, rơi vào ngày không làm việc trong tuần) và ngày nghỉ đột xuất (SPECIAL_OFF) của một lịch năm (FR-11-045, CalendarDayType). Mỗi ngày một dòng trong một lịch; ngày phải thuộc năm của lịch (dịch vụ kiểm, ERR-11-028). legal_ref ghi văn bản (ví dụ quyết định nghỉ Tết của Thủ tướng). Cùng mẫu S với business_calendar: ngày lễ nền quốc gia ở COMMON. Sửa, xóa ngày có kiểm toán.

**Khóa chính.** (id).

**Duy nhất.** `uq_calendar_day_date` (tenant_id, calendar_id, date).

**Khóa ngoại.** (tenant_id, calendar_id) → `business_calendar`.

**Ràng buộc CHECK.** `ck_calendar_day_` + `type`.

**Chỉ mục.** `ix_calendar_day_date`.

**Cách ly tenant.** RLS FORCE, mẫu S (mục 1.2): tenant đọc thêm dòng COMMON.

**Phân vùng, bất biến.** Bất biến: `calendar_id`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `date` | `date` | Ngày dương lịch (API date). |
| `type` | `varchar(16)` | CalendarDayType: HOLIDAY, MAKEUP_WORKDAY, SPECIAL_OFF. |
| `legal_ref` | `varchar(255), NULL` | Số, ngày văn bản quy định nghỉ hoặc làm bù. |

: Cột của bảng `calendar_day`

Cột khác: `calendar_id`; `name` v(255).

### 3.21. `due_tracking`

::: dac-ta
**Mục đích.** EN-11-15 Theo dõi hạn xử lý của phiên và của việc (FR-11-046…050, ADR 114). Hạn due_at tính theo lịch làm việc của tenant (BR-11-017); PAUSED khi chờ bổ sung hoặc tạm dừng pháp lý, cộng dồn paused_duration và dời due_at khi tiếp tục (BR-11-018). Tác vụ nền quét theo due_at, ghi mốc nhắc và mức leo thang một lần (BR-11-019). Khi đóng ghi closed_at và result (MET, MISSED) để báo cáo đúng hạn, trễ hạn.

**Khóa chính.** (id).

**Duy nhất.** `uq_due_tracking_subject` (tenant_id, subject, subject_id).

**Khóa ngoại.** (tenant_id, instance_id) → `instance_index`, (tenant_id, task_id) → `task_index`.

**Ràng buộc CHECK.** `ck_due_tracking_` + `subject`, `unit`, `status`, `pause`, `reason`, `due`, `paused_duration`, `level`, `result`, `closed`.

**Chỉ mục.** `ix_due_tracking_instance`, `ix_due_tracking_scan`, `ix_due_tracking_report`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `subject`, `subject_id`, `instance_id`, `start_at`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `subject` | `varchar(8)` | DueSubject: INSTANCE hạn cả phiên (subject_id là mã phiên), TASK hạn một việc (subject_id là mã việc). |
| `subject_id` | `uuid` | Mã phiên (instance_index.id) hoặc mã việc (task_index.id) theo subject. |
| `instance_id` | `uuid` | Phiên chứa đối tượng bị theo dõi (với INSTANCE bằng subject_id), giữ khóa ngoại và lọc theo phiên. |
| `task_id` | `uuid GENERATED ALWAYS AS (CASE WHEN subject = 'TASK' THEN subject_id END) STORED, NULL` | Cột sinh: bằng subject_id khi subject = TASK, để có khóa ngoại tới task_index. |
| `due_value` | `integer` | Số lượng của hạn (T-DUE, 1…3.650), lưu để tính lại hạn khi lịch đổi (FR-11-045). |
| `due_unit` | `varchar(16)` | DueUnit: WORKING_DAY, WORKING_HOUR, CALENDAR_DAY, CALENDAR_HOUR. |
| `status` | `varchar(8), mặc định 'ON_TIME'` | Giá trị: `ON_TIME`, `DUE_SOON`, `OVERDUE`, `PAUSED`. |
| `pause_reason` | `varchar(24), NULL` | PauseReason: WAITING_SUPPLEMENT (chờ bổ sung hồ sơ), LEGAL_SUSPENSION (tạm dừng theo quy định). |
| `paused_duration` | `interval, mặc định '0'` | Tổng thời gian đã tạm dừng tính hạn, quy theo giờ làm việc (API pausedDuration). |
| `escalation_level` | `smallint, mặc định 0` | Mức leo thang đã gửi: 0 chưa, 1 người quản lý trực tiếp, 2 lãnh đạo đơn vị, 3 quản trị tenant (EscalationAction ghi ở chính sách bước). |
| `result` | `varchar(8), NULL` | DueResult khi đóng: MET hoàn thành trong hạn, MISSED sau hạn; rỗng khi còn mở. |

: Cột của bảng `due_tracking`

Cột khác: `start_at`; `due_at`; `due_soon_at`; `paused_at`; `due_soon_notified_at`; `overdue_notified_at`; `closed_at`.

### 3.22. `saga_log`

::: dac-ta
**Mục đích.** EN-11-16 Nhật ký Saga bù trừ của một phiên (FR-11-051…054, ADR 113). Mỗi lần kích hoạt bù trừ (lỗi bước, hủy phiên, thủ công) một dòng; mỗi phiên tối đa một Saga RUNNING. PARTIAL là còn bước xử lý thủ công. Là bằng chứng đối soát khi cơ quan đã ghi nhận giao dịch: không xóa (quyền), giữ tối thiểu 5 năm (BR-11-025). Đối soát định kỳ đặt reconcile_state.

**Khóa chính.** (id).

**Duy nhất.** `uq_saga_log_running` (tenant_id, instance_id) có điều kiện.

**Khóa ngoại.** (tenant_id, instance_id) → `instance_index`.

**Ràng buộc CHECK.** `ck_saga_log_` + `trigger`, `status`, `ended`, `counts`, `reconcile`, `reconciled`, `trace`.

**Chỉ mục.** `ix_saga_log_instance`, `ix_saga_log_status`, `ix_saga_log_reconcile`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `instance_id`, `trigger`, `failed_element`, `started_at`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `trigger` | `varchar(16), mặc định 'STEP_FAILURE'` | CompensationTrigger: STEP_FAILURE bước lỗi không thử lại được; INSTANCE_CANCEL hủy phiên kèm bù trừ (FR-11-024); MANUAL do TA, TO kích hoạt (PERM-11-compensate). |
| `failed_element` | `varchar(100), NULL` | Id phần tử BPMN gây lỗi (API failedElementId); rỗng với INSTANCE_CANCEL, MANUAL. |
| `error_code` | `varchar(32), NULL` | Mã lỗi của bước gây Saga (ERR-11-xxx hoặc mã lỗi nghiệp vụ của ý định). |
| `status` | `varchar(10), mặc định 'RUNNING'` | Giá trị: `RUNNING`, `SUCCEEDED`, `PARTIAL`, `FAILED`. |
| `reconcile_state` | `varchar(8), mặc định 'NONE'` | Đối soát với hệ thống đích (FR-11-054): NONE chưa cần, PENDING chờ, MATCHED khớp, MISMATCH lệch cần xử lý. |

: Cột của bảng `saga_log`

Cột khác: `instance_id`; `total_steps` smallint; `done_steps` smallint; `failed_steps` smallint; `started_at`; `ended_at`; `reconciled_at`; `reconcile_note` v(2000); `trace_id` char(32).

### 3.23. `saga_step`

::: dac-ta
**Mục đích.** EN-11-17 Bước bù trừ của một Saga, chạy ngược thứ tự hoàn thành (FR-11-051…053, BR-11-011). DONE chỉ sau khi ghi nhật ký (BR-11-013); MANUAL chờ xử lý tay và tạo việc MANUAL_COMPENSATION. Bước thủ công hoàn tất hoặc bỏ qua cần người xử lý và bằng chứng từ 20 ký tự, trừ policy NONE_APPROVED (đã được duyệt khi phát hành). Là bằng chứng đối soát: không xóa (quyền), giữ tối thiểu 5 năm.

**Khóa chính.** (id).

**Duy nhất.** `uq_saga_step_seq` (tenant_id, saga_id, seq), `uq_saga_step_command` (tenant_id, command_id) có điều kiện.

**Khóa ngoại.** (tenant_id, saga_id) → `saga_log`.

**Ràng buộc CHECK.** `ck_saga_step_` + `policy`, `status`, `seq`, `attempt`, `ended`, `failed`, `manual`, `skipped`, `auto`.

**Chỉ mục.** `ix_saga_step_saga`, `ix_saga_step_open`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `saga_id`, `seq`, `forward_element_id`, `policy`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `seq` | `smallint` | Thứ tự thực hiện bù trừ, 1 là bước đầu tiên được bù trừ (bước xuôi hoàn thành gần nhất). |
| `policy` | `varchar(16)` | CompensationPolicy chụp từ compensation_action lúc kích hoạt Saga, để nhật ký không đổi dù cấu hình sau này đổi. Giá trị: `AUTO`, `MANUAL`, `NONE_APPROVED`. |
| `command_id` | `uuid, NULL` | Mã lệnh bù trừ gửi PH-04 (service.requested); kết quả tương quan theo mã này. |
| `attempt` | `smallint, mặc định 0` | Số lượt thử bù trừ đã chạy (tối đa 11.saga.maxRetries cộng lượt đầu). |
| `status` | `varchar(8), mặc định 'PENDING'` | Giá trị: `PENDING`, `RUNNING`, `DONE`, `FAILED`, `MANUAL`, `SKIPPED`. |
| `response_code` | `varchar(32), NULL` | Mã phản hồi của hệ thống đích cho lệnh bù trừ. |
| `evidence` | `varchar(2000), NULL` | Bằng chứng bù trừ: mô tả, số văn bản, tham chiếu tệp; với xử lý tay hoặc bỏ qua là lý do và bằng chứng từ 20 ký tự (API-11-… ManualResolveBody, SkipBody). |
| `resolved_by` | `varchar(64), NULL` | Người xử lý tay hoặc bỏ qua bước. |
| `last_error` | `varchar(2000), NULL` | Lỗi gần nhất của lượt thử (đã lược dữ liệu cá nhân); bắt buộc khi FAILED. |

: Cột của bảng `saga_step`

Cột khác: `saga_id`; `forward_element_id` v(100); `compensation_intent_code` v(64); `started_at`; `ended_at`.

### 3.24. `incident`

::: dac-ta
**Mục đích.** EN-11-18 Sự cố engine và việc lỗi (FR-11-060, 061): job Flowable hết lần thử, service task hết hạn, thông điệp không tương quan được, hẹn giờ lỗi, bù trừ thất bại, phiên tắc, lỗi engine (IncidentType). Trạng thái IncidentStatus OPEN, RETRYING, RESOLVED, IGNORED; bỏ qua phải ghi lý do từ 20 ký tự. Một job lỗi chỉ một sự cố đang mở. Đẩy sự kiện EVT-11-16 khi mở.

**Khóa chính.** (id).

**Duy nhất.** `uq_incident_open_job` (tenant_id, job_id) có điều kiện.

**Khóa ngoại.** (tenant_id, instance_id) → `instance_index`.

**Ràng buộc CHECK.** `ck_incident_` + `type`, `status`, `resolved`, `reason`, `retries`, `trace`.

**Chỉ mục.** `ix_incident_status`, `ix_incident_instance`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `instance_id`, `type`, `job_id`, `opened_at`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `type` | `varchar(24)` | IncidentType: JOB_FAILED, SERVICE_TIMEOUT, CORRELATION_FAILED, TIMER_FAILED, COMPENSATION_FAILED, STUCK_INSTANCE, ENGINE_ERROR, SUPPLEMENT_EXPIRED (hết hạn bổ sung hồ sơ, FR-11-049, ERR-11-125). |
| `job_id` | `varchar(64), NULL` | Mã job lỗi trong engine (ACT_RU_DEADLETTER_JOB.ID_); rỗng với sự cố không do job. |
| `message` | `varchar(2000), NULL` | Thông điệp lỗi đã lược dữ liệu cá nhân; không ghi giá trị biến. |
| `retries_done` | `smallint, mặc định 0` | Số lần thử lại thủ công và tự động đã thực hiện. |
| `status` | `varchar(8), mặc định 'OPEN'` | Giá trị: `OPEN`, `RETRYING`, `RESOLVED`, `IGNORED`. |
| `handled_by` | `varchar(64), NULL` | Người xử lý (thử lại thành công, giải quyết hoặc bỏ qua). |
| `reason` | `varchar(2000), NULL` | Lý do xử lý; bắt buộc từ 20 ký tự khi IGNORED. |

: Cột của bảng `incident`

Cột khác: `instance_id`; `element_id` v(100); `error_code` v(32); `trace_id` char(32); `opened_at`; `resolved_at`.

### 3.25. `migration_plan`

::: dac-ta
**Mục đích.** EN-11-19 Kế hoạch di trú phiên sang phiên bản mô hình mới (FR-11-026, PERM-11-instance-admin). Bốn mắt (BR-11-021): người duyệt khác người lập; ánh xạ bước cũ sang bước mới (mappings), kiểm tra trước khi chạy (dry_run_report); mỗi mô hình chỉ một kế hoạch RUNNING; chạy theo lô 11.migration.batchSize. PARTIAL là còn phiên lỗi; từ chối cần ý kiến từ 20 ký tự. Lý do từ 20 ký tự.

**Khóa chính.** (id).

**Duy nhất.** `uq_migration_plan_running` (tenant_id, process_key) có điều kiện.

**Khóa ngoại.** (tenant_id, process_key, from_version) → `process_version`, (tenant_id, process_key, to_version) → `process_version`.

**Ràng buộc CHECK.** `ck_migration_plan_` + `versions`, `status`, `four_eyes`, `approved`, `rejected`, `reason`, `mappings`, `summary`, `finished`.

**Chỉ mục.** `ix_migration_plan_model`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `process_key`, `from_version`, `to_version`, `requested_by`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `process_key` | `varchar(64)` | Khóa mô hình; cùng from_version, to_version tạo khóa ngoại tới process_version. |
| `filter` | `jsonb, mặc định '{}'` | Điều kiện chọn phiên (API instanceFilter: trạng thái, bước hiện tại); rỗng là mọi phiên đang chạy của phiên bản nguồn. |
| `mappings` | `jsonb, mặc định '[]'` | Mảng ánh xạ bước, mỗi phần tử {fromElementId, toElementId} (API MappingItem). |
| `status` | `varchar(16), mặc định 'DRAFT'` | Giá trị: `DRAFT`, `VALIDATED`, `PENDING_APPROVAL`, `RUNNING`, `COMPLETED`, `PARTIAL`, `REJECTED`. |
| `approved_by` | `varchar(64), NULL` | Người quyết định (duyệt hoặc từ chối), khác requested_by. |
| `decision_comment` | `varchar(2000), NULL` | Ý kiến của người quyết định; từ chối cần từ 20 ký tự. |
| `summary` | `jsonb, mặc định '{"total": 0, "migrated": 0, "failed": 0}'` | Kết quả chạy: {total, migrated, failed} (API MigrationSummary); migrated cộng failed không vượt total. |
| `dry_run_report` | `jsonb, NULL` | Kết quả bước kiểm tra: số phiên hợp lệ, danh sách phiên không di trú được và lý do. |

: Cột của bảng `migration_plan`

Cột khác: `from_version` int; `to_version` int; `reason` v(2000); `requested_by` v(64); `approved_at`; `started_at`; `finished_at`.

### 3.26. `tenant_setting`

::: dac-ta
**Mục đích.** EN-11-23 Tham số phân hệ theo tenant, 36 khóa 11.* của FRS 8.2 (FR-11-062, 063), PERM-11-config. Giá trị jsonb đúng kiểu và đơn vị của FRS (ví dụ 11.service.defaultTimeoutMinutes là phút), miền giá trị kiểm bằng ph11_bpm.f_setting_valid. Dòng tenant COMMON là trần nền tảng do PA đặt (mẫu S: tenant đọc được); tham số tenant không vượt trần (BR-11-024, dịch vụ so khi lưu). Không xóa (quyền).

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_setting_key` (tenant_id, key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_tenant_setting_` + `key`, `value`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE, mẫu S (mục 1.2): tenant đọc thêm dòng COMMON.

**Phân vùng, bất biến.** Bất biến: `key`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `key` | `varchar(64)` | Khóa dạng 11.{nhóm}.{tên}, ví dụ 11.task.dueSoonHours (API Setting.key). |
| `value` | `jsonb` | Giá trị JSON: số, chuỗi hoặc logic tùy khóa (API Setting.value). |

: Cột của bảng `tenant_setting`


### 3.27. `outbox_event`

::: dac-ta
**Mục đích.** EN-11-21 Outbox (ADR-042, SAD 7.3; FR-11-028, 032, 056, 065) cho EVT-11-01…17, EVT-11-20, EVT-11-21 (bản ghi kiểm toán gửi PH-13). Ghi cùng giao dịch với thay đổi trạng thái (BR-11-023); bộ chuyển outbox đẩy lên Kafka, định tuyến theo topic, cập nhật status và attempts; quá 11.outbox.maxAttempts thì mở sự cố (ERR-11-101). Gồm cả lệnh service.requested tới PH-04 (ADR 112). Nội dung sự kiện bất biến sau khi ghi; không chứa giá trị biến, dữ liệu biểu mẫu hay định danh cá nhân: CHECK chặn các khóa đó ở cấp cao nhất.

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_event_` + `prefix`, `topic`, `status`, `attempts`, `sent`, `trace`, `no_value`.

**Chỉ mục.** `ix_outbox_event_pending`, `ix_outbox_event_occurred`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `event_id`, `event_type`, `topic`, `aggregate_type`, `aggregate_id`, `partition_key`, `payload`, `occurred_at`.

**Ghi chú.** Debezium Outbox Event Router đọc WAL và phát lên Kafka; ghi cùng giao dịch với thay đổi (ADR-073, SAD 7.3).
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `partition_key` | `varchar(255)` | Khóa phân vùng Kafka: businessKey (mọi sự kiện tiến độ) hoặc processKey (EVT-11-01, 02). |
| `status` | `varchar(8), mặc định 'PENDING'` | Trạng thái đẩy: PENDING chờ đẩy, SENT đã đẩy, FAILED quá lượt thử; OutboxStatus của FRS Phụ lục A. |
| `attempts` | `smallint, mặc định 0` | Số lần đã đẩy lên Kafka. |

: Cột của bảng `outbox_event`

Cột khác: `event_id`; `tenant_id` v(16); `event_type` v(128); `topic` v(249); `aggregate_type` v(64); `aggregate_id` v(255); `payload` jsonb; `sent_at`; `last_error` v(1000); `trace_id` char(32); `occurred_at`.

### 3.28. `inbox_message`

::: dac-ta
**Mục đích.** EN-11-22 Inbox chống xử lý trùng và giữ thông điệp chưa tương quan (at-least-once): kết quả service task từ PH-04 (EVT-11-18, 19), sự kiện khởi tạo, thông điệp từ PH-10 cho message catch (FR-11-019, 029, 030; BR-11-022). Khóa (consumer, message_id). Thông điệp đến trước khi phiên tới bước chờ giữ ở UNCORRELATED đến expires_at (11.message.bufferMinutes) rồi mở sự cố CORRELATION_FAILED.

**Khóa chính.** (tenant_id, consumer, message_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_inbox_message_` + `consumer`, `prefix`, `status`, `processed`, `attempts`, `no_value`.

**Chỉ mục.** `ix_inbox_message_received`, `ix_inbox_message_waiting`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Không.

**Ghi chú.** Khử trùng thông điệp nhận từ PH-04, PH-10 theo (`consumer`, `message_id`) và giữ thông điệp chưa tương quan (tiêu thụ lũy đẳng).
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `source` | `varchar(249)` | Topic Kafka nguồn của thông điệp, tiền tố là tenant viết thường (FRS: source). |
| `payload` | `jsonb, NULL` | Nội dung đã lược; không chứa khóa biến, biểu mẫu, định danh cá nhân (CHECK). Dữ liệu cá nhân của thông điệp không được giữ ở đây. |
| `status` | `varchar(12), mặc định 'RECEIVED'` | Trạng thái xử lý: RECEIVED, PROCESSED, UNCORRELATED (chờ phiên), FAILED; InboxStatus của FRS Phụ lục A. |
| `expires_at` | `timestamptz, NULL` | Hạn giữ khi UNCORRELATED; quá hạn không tương quan được thì mở sự cố. |

: Cột của bảng `inbox_message`

Cột khác: `tenant_id` v(16); `consumer` v(64); `message_id` v(255); `event_type` v(255); `correlation_key` v(120); `business_key` v(100); `attempts` smallint; `received_at`; `processed_at`; `outcome` v(2000).

### 3.29. `shedlock`

::: dac-ta
**Mục đích.** Khóa tác vụ nền (DueScanner, TimerCatchUp, InboxReaper, OutboxCleaner, SagaReconciler, RetentionPurgeJob, PartitionMaintenanceJob, DelegationExpirer); bảng kỹ thuật của ShedLock, không có tenant_id. Bảng ngoài FRS Phụ lục A, hạ tầng.

**Khóa chính.** (name).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không bật RLS. Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.

**Phân vùng, bất biến.** Không.

**Ghi chú.** Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.
:::

Cột khác: `name` v(64); `lock_until`; `locked_at`; `locked_by` v(255).

### 3.30. `saga_skip_request`

::: dac-ta
**Mục đích.** EN-11-29. Đề nghị bỏ qua một bước bù trừ thủ công (FR-11-053, API-11-101, 132, 133). Bốn mắt (ERR-11-005): người duyệt hoặc từ chối khác người đề nghị. Bước saga_step vẫn MANUAL đến khi được duyệt (thành SKIPPED, resolved_by là người duyệt); từ chối đưa bước về MANUAL. Mỗi bước tối đa một đề nghị PENDING; đề nghị bị từ chối giữ lại làm bằng chứng. Không xóa (quyền).

**Khóa chính.** (id).

**Duy nhất.** `uq_saga_skip_request_pending` (tenant_id, step_id) có điều kiện.

**Khóa ngoại.** (tenant_id, saga_id) → `saga_log`, (tenant_id, step_id) → `saga_step`, (tenant_id, task_id) → `task_index`.

**Ràng buộc CHECK.** `ck_saga_skip_request_` + `status`, `reason`, `evidence`, `four_eyes`, `decided`, `reject`.

**Chỉ mục.** `ix_saga_skip_request_step`, `ix_saga_skip_request_open`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `saga_id`, `step_id`, `reason`, `evidence`, `requested_by`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `step_id` | `uuid` | Bước bù trừ được đề nghị bỏ qua; cùng saga_id tạo khóa ngoại tới saga_step, saga_log. |
| `reason` | `varchar(2000)` | Lý do đề nghị (API SkipBody.reason), từ 20 ký tự. |
| `evidence` | `jsonb, mặc định '[]'` | Mảng bằng chứng, mỗi phần tử {note, docNumber, objectRef, confirmedBy} (API ManualEvidence); tệp ở Ceph RGW, chỉ lưu tham chiếu. |
| `requested_by` | `varchar(64)` | Người đề nghị (TA hoặc TO có PERM-11-compensate); không được tự duyệt. |
| `status` | `varchar(8), mặc định 'PENDING'` | SkipRequestStatus: PENDING chờ duyệt, APPROVED đã duyệt (bước SKIPPED), REJECTED bị từ chối (bước về MANUAL). |
| `task_id` | `uuid, NULL` | Việc MANUAL_COMPENSATION giao cho TA khác để duyệt (API SkipRequested.taskId). |
| `decided_by` | `varchar(64), NULL` | Người duyệt hoặc từ chối, khác requested_by. |
| `decision_comment` | `varchar(2000), NULL` | Ý kiến người quyết định (API CommentBody, RejectBody); từ chối cần từ 20 ký tự (ERR-11-007). |

: Cột của bảng `saga_skip_request`

Cột khác: `saga_id`; `decided_at`.

### 3.31. `legal_hold`

::: dac-ta
**Mục đích.** EN-11-30. Giữ pháp lý theo mã hồ sơ (FR-11-054, 063, API-11-120, 134, 135, PERM-11-config): hồ sơ đang giữ không bị dọn lịch sử engine hay bản nghiệp vụ (ERR-11-047, BR-11-025) đến khi gỡ hoặc hết hold_until. Mỗi business_key tối đa một giữ đang hiệu lực; giữ đã gỡ giữ lại làm bằng chứng, không xóa (quyền). Không khóa ngoại tới instance_index vì giữ có thể đặt trước phiên.

**Khóa chính.** (id).

**Duy nhất.** `uq_legal_hold_active` (tenant_id, business_key) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_legal_hold_` + `key`, `reason`, `until`, `release`, `release_reason`.

**Chỉ mục.** `ix_legal_hold_key`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `business_key`, `reason`, `hold_until`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `business_key` | `varchar(100)` | Mã hồ sơ cần giữ (API businessKey, 3…100 ký tự), khớp instance_index.business_key; không chứa dữ liệu cá nhân. |
| `reason` | `varchar(2000)` | Căn cứ pháp lý (API reason), từ 20 ký tự. |
| `hold_until` | `timestamptz, NULL` | Hạn giữ (API holdUntil); rỗng là giữ đến khi gỡ. |
| `released_at` | `timestamptz, NULL` | Thời điểm gỡ giữ (API releasedAt); rỗng là còn hiệu lực. Cùng released_by, release_reason: cả ba có hoặc cả ba rỗng. |
| `released_by` | `varchar(64), NULL` | Người gỡ giữ (API releasedBy). |
| `release_reason` | `varchar(2000), NULL` | Lý do gỡ (API releaseReason, ReasonBody), từ 10 ký tự. |

: Cột của bảng `legal_hold`


### 3.32. `compliance_sample_run`

::: dac-ta
**Mục đích.** EN-11-31. Lần chạy mẫu tuân thủ BPMN 2.0 và gói bằng chứng (FR-11-064, API-11-121, 122, 137): mô hình MAU_TUAN_THU_BPMN chạy trên TEST hoặc STAGING, gói PDF và JSON có băm lưu ở Ceph RGW. Khác test_run (chạy thử mô hình nháp). Khoảng thống kê tối đa 366 ngày (ERR-11-039). Không xóa (quyền).

**Khóa chính.** (id).

**Duy nhất.** `uq_compliance_sample_run_pack` (tenant_id, evidence_pack_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_compliance_sample_run_` + `env`, `status`, `models`, `period`, `ended`, `checksum`, `pack`, `result`.

**Chỉ mục.** `ix_compliance_sample_run_list`.

**Cách ly tenant.** RLS FORCE, mẫu P (mục 1.2).

**Phân vùng, bất biến.** Bất biến: `evidence_pack_id`, `environment`, `requested_by`, `include_models`, `started_at`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `evidence_pack_id` | `uuid` | Mã gói bằng chứng (API evidencePackId) dùng tải gói qua API-11-122; duy nhất trong tenant. |
| `environment` | `varchar(8)` | Môi trường chạy mẫu (API environment). FR-11-064 chỉ nhận TEST, STAGING (Environment của FRS có thêm PROD). |
| `status` | `varchar(8), mặc định 'RUNNING'` | TestRunStatus: RUNNING đang chạy, PASSED đạt, FAILED chưa đạt, ABORTED dừng giữa chừng. |
| `include_models` | `jsonb, mặc định '[]'` | Mảng khóa mô hình thật đính kèm thống kê (API includeModels), mỗi phần tử theo mẫu process_key. |
| `period_from` | `timestamptz, NULL` | Đầu khoảng thống kê (API from); cùng period_to hoặc cả hai rỗng. |
| `engine_instance_id` | `varchar(64), NULL` | Mã phiên mẫu trong Flowable. |
| `checksum` | `bytea, NULL` | SHA-256 gói bằng chứng, đúng 32 byte (API checksum, dạng hex); bắt buộc khi PASSED, FAILED. |
| `pack_ref` | `varchar(500), NULL` | Khóa đối tượng của gói ở Ceph RGW; bắt buộc khi PASSED, FAILED. |
| `result` | `jsonb, NULL` | Biên bản chạy: phần tử BPMN 2.0 đã thực thi, phiên bản Flowable, lỗi khi FAILED. |

: Cột của bảng `compliance_sample_run`

Cột khác: `requested_by` v(64); `period_to`; `started_at`; `finished_at`.
<!-- gen:tables:end -->

### 3.33. Truy vấn chính và chỉ mục phục vụ

Truy vấn nóng của giao diện, API tiến độ và tác vụ nền cùng chỉ mục phục vụ.

| Truy vấn | Tác vụ, FR | Chỉ mục |
|---|---|---|
| Hộp "Việc của tôi": việc giao cho tôi | FR-11-035, FR-00-070 | `ix_task_index_assignee` (từng phần theo trạng thái) |
| Việc còn ở nhóm, đơn vị, danh sách ứng viên | FR-11-034, 036 | `ix_task_index_candidates` (GIN, từng phần `UNASSIGNED`) |
| Tra tiến độ theo mã hồ sơ cho kênh DVC | FR-11-055 | `ix_instance_index_bkey`, `uq_instance_index_live_key` |
| Danh sách phiên theo trạng thái, mô hình | FR-11-021 | `ix_instance_index_list`, `ix_instance_index_model` |
| Dòng thời gian bước của phiên | FR-11-022, 057 | `ix_instance_step_instance` |
| Quét sắp đến hạn, quá hạn | FR-11-047, 048 | `ix_due_tracking_scan` (chỉ dòng còn mở, không tạm dừng) |
| Báo cáo đúng hạn, trễ hạn | FR-11-050 | `ix_due_tracking_report` |
| Lệnh service task quá hạn chờ kết quả | FR-11-029 | `ix_service_call_timeout` |
| Thông điệp chưa tương quan chờ phiên | FR-11-030 | `ix_inbox_message_waiting` |
| Sự cố đang mở theo mức độ | FR-11-060 | `ix_incident_status`, `uq_incident_open_job` |
| Tìm mô hình theo tên | FR-11-001 | `ix_process_model_name` (GIN `pg_trgm`) |
| Saga cần đối soát | FR-11-054 | `ix_saga_log_reconcile` |

: Truy vấn chính và chỉ mục phục vụ

### 3.34. Phân vùng và bảo trì

Chỉ `instance_step` phân vùng, theo tháng, vì là bảng tăng nhanh nhất (mỗi phiên nhiều dòng) và có thời hạn giữ dài. `outbox_event`, `inbox_message` không phân vùng: dữ liệu sống 3 đến 7 ngày, dọn bằng `DELETE` theo lô nhỏ, và khóa duy nhất của inbox phải phủ toàn bảng nên không thể đặt trên bảng phân vùng theo thời gian.

| Bảng | Khóa phân vùng | Tạo trước | Dọn |
|---|---|---|---|
| `instance_step` | `started_at` | 3 tháng tới | `DETACH`, `DROP` khi mọi phiên có bước trong tháng đã kết thúc quá 5 năm |

: Phân vùng và bảo trì

`PartitionMaintenanceJob` (khóa `shedlock`) gọi `p_ensure_partitions` mỗi ngày lúc 00:05; DDL tạo sẵn ba phân vùng từ tháng triển khai. Dọn theo thời hạn do `RetentionPurgeJob` (FR-11-063): xóa theo lô bản chiếu và bảng vận hành đã quá hạn theo thứ tự con trước cha, rồi `DROP` phân vùng đủ điều kiện.

## 4. DDL và changelog Liquibase

### 4.1. Tệp

[`ph11/ddl/ph11_bpm.sql`](ph11/ddl/ph11_bpm.sql) là nguồn duy nhất, chia changeset bằng `-- @file`, `-- @changeset`, `-- @rollback` như PH-06, PH-10. Changelog [`ph11/liquibase/db.changelog-ph11.yaml`](ph11/liquibase/db.changelog-ph11.yaml) và 12 tệp `ph11/liquibase/changes/*.sql` (formatted SQL, tác giả `ph11`) sinh bằng [`gen_liquibase.py`](ph11/tools/gen_liquibase.py), không sửa tay. Các tệp công cụ khác: [`gen_tables_md.py`](ph11/tools/gen_tables_md.py), [`gen_anh_xa.py`](ph11/tools/gen_anh_xa.py), [`them_dac_ta_bang.py`](ph11/tools/them_dac_ta_bang.py) sinh phần bảng của tài liệu này từ DDL.

| Tệp | Nội dung |
|---|---|
| `11-0000-bootstrap.sql` | Vai trò `ph11_owner`, `ph11_app`, `ph11_readonly`, `ph11_engine`; `btree_gist`, `pg_trgm`; schema `ph11_bpm` và `ph11_flowable` (rỗng); biến phiên |
| `11-0001-functions.sql` | `tg_touch`, `tg_immutable`, `tg_append_only`, `tg_frozen`, `tg_child_frozen`, `p_enable_rls`, `p_ensure_partitions` |
| `11-0010-model.sql` | `process_model`, `process_version`, `form_definition`, `service_intent`, `compensation_action`, `process_template`, `variable_definition`, `decision_table`, `publish_request`, `test_run` |
| `11-0020-instance.sql` | `instance_index`, `instance_step`, `service_call`, `instance_change` |
| `11-0030-task.sql` | `task_index`, `task_comment`, `task_attachment`, `delegation` |
| `11-0040-sla.sql` | `business_calendar`, `calendar_day`, `due_tracking` |
| `11-0050-saga.sql` | `saga_log`, `saga_step` |
| `11-0060-ops.sql` | `incident`, `migration_plan`, `tenant_setting` |
| `11-0070-messaging.sql` | `outbox_event`, `inbox_message`, `shedlock` |
| `11-0075-compliance.sql` | `saga_skip_request`, `legal_hold`, `compliance_sample_run` |
| `11-0800-seed.sql` | `p_seed_tenant`, mẫu quy trình `COMMON` |
| `11-0900-grants.sql` | Quyền theo vai trò, `runAlways` |

: Tệp DDL và changelog Liquibase của PH-11

Không có changeset di trú dữ liệu: SRS cũ chỉ là mô hình trên giấy, hệ cũ không có BPM (mục 8.4).

### 4.2. Kết quả chạy thử

Chạy ngày 26/11/2026 trên PostgreSQL 16.15 (Ubuntu 24.04) cài sạch, cụm tạm cổng 55452, dữ liệu giả, tenant kiểm thử T90, T91:

- DDL chạy không lỗi trên CSDL trống với `ON_ERROR_STOP`: 32 bảng gốc (31 có RLS, thêm `shedlock`), 3 phân vùng `instance_step`, 247 `CHECK`, 29 khóa ngoại, 1 ràng buộc loại trừ, 63 trigger, 124 chính sách RLS (31 bảng × 4).
- Ghép 12 tệp changelog sinh ra (46 changeset) rồi chạy bằng psql theo thứ tự trên CSDL trống khác: không lỗi, cùng 32 bảng, chạy lại đủ 297 khối PASS. Chưa chạy bằng Liquibase CLI; CI chạy `liquibase update` trên Testcontainers.
- [`ph11_isolation_test.sql`](ph11/test/ph11_isolation_test.sql) dưới `dh_platform_app` (nhóm 9 dưới vai trò báo cáo `dh_report_ro`) đạt 297 khối PASS, chia chín nhóm: khởi tạo tenant; cô lập tenant (T91 không đọc, sửa, xóa, chèn dòng T90 trên 31 bảng kể cả phân vùng; mẫu P và S với `COMMON`); mô hình, phiên bản, bốn mắt; biến, bù trừ, biểu mẫu, ý định; phiên lũy đẳng, bảng phân vùng; việc, ý kiến, tệp; ủy quyền, lịch, hạn; chạy thử, can thiệp phiên, lệnh service; Saga, đề nghị bỏ qua bốn mắt, giữ pháp lý, lần chạy mẫu (31 khối), sự cố, di trú, outbox, inbox, tham số, quyền vai trò, tách schema engine.

Bài kiểm `TenantIsolationIT` (D03-02-PH11) tự động hóa các khối này trong CI bằng Testcontainers PostgreSQL 16.

### 4.3. Đối chiếu với FRS phụ lục A

Bản 0.4 theo FRS 0.2 Phụ lục A: enum, thuộc tính EN-11-01…28 (A.2), tham số `11.*` (8.2), quy tắc BR (mục 7). Tên cột là snake_case của trường API trong `openapi-bpm.yaml`. Ba bảng mới (EN-11-29…31), `shedlock` và cột phụ trợ ghi ở mục 9.2; `Environment` của lần chạy mẫu thu hẹp còn `TEST`, `STAGING` theo FR-11-064; ngoài ra không enum nào của DDL khác Phụ lục A, trừ `SkipRequestStatus` (đề nghị).

## 5. Dữ liệu khởi tạo

Khi PH-20 khởi tạo tenant, `dh-platform` gọi `ph11_bpm.p_seed_tenant('Tnn')`. Dữ liệu dùng chung nạp một lần bằng phiên `PLATFORM`.

| Dữ liệu | Nội dung | Nguồn |
|---|---|---|
| Tham số `11.*` | 36 dòng `tenant_setting` theo FRS 8.2, ví dụ `11.task.dueSoonHours` 8, `11.task.bulkMax` 500, `11.delegation.maxDays` 30, `11.service.defaultTimeoutMinutes` 2.880, `11.saga.maxRetries` 3, `11.retention.instanceYears` 5; dòng `COMMON` giữ trần, tenant chỉ chỉnh trong miền (`f_setting_valid`) | FRS 8.2 |
| Lịch làm việc | 2 dòng `business_calendar` mỗi tenant (năm hiện tại và năm sau): thứ Hai đến thứ Sáu, 07:30 đến 17:00, nghỉ trưa 11:30 đến 13:30 | FR-11-045 |
| Ngày nghỉ lễ | Không seed theo tenant; PA khai lịch nền quốc gia ở `COMMON` (mẫu S), TA nhập thêm hoặc nhập từ lịch quốc gia | FR-11-045 |
| Mẫu quy trình nền tảng | 1 dòng `process_template` ở tenant `COMMON`, trạng thái `PUBLISHED`: `DUYET_MOT_CAP` (bắt đầu, một việc duyệt, kết thúc); `DUYET_HAI_CAP` do PA bổ sung theo FR-11-015 | FR-11-015 |

: Dữ liệu khởi tạo

Thủ tục chạy lại không nhân bản (`ON CONFLICT DO NOTHING`, `id` tất định theo `md5`). Mô hình mẫu `LT_KHAI_SINH` và `DUYET_KET_NAP_HTTT` không seed: tạo bằng giao diện hoặc gói nhập (FR-11-010), `DUYET_KET_NAP_HTTT` do PH-01 khởi tạo qua API.

## 6. Kho lưu trữ ngoài PostgreSQL

### 6.1. Engine Flowable và schema `ph11_flowable`

Flowable 7.x nhúng trong `dh-platform`, một engine dùng chung mọi tenant (ADR 110). DDL của tập này không tạo bảng `ACT_*`, chỉ tạo schema rỗng `ph11_flowable` cho vai trò `ph11_engine`; Flowable tự tạo và nâng cấp bảng khi khởi động. Cấu hình đề xuất:

| Hạng mục | Giá trị | Lý do |
|---|---|---|
| Nguồn kết nối | Riêng, tài khoản thuộc `ph11_engine`, `databaseSchema=ph11_flowable`; `databaseSchemaUpdate=true` ở phát triển, sản xuất nâng cấp trong cửa sổ triển khai | Cô lập quyền với `ph11_bpm` |
| Đa tenant | Một engine, `tenantId` của Flowable ở mọi triển khai, phiên, việc, job | Tránh một engine mỗi tenant (Q11-51) |
| Lịch sử | `history=audit`, không ghi mọi thay đổi biến | Giảm dung lượng; chi tiết bước ở `instance_step` |
| Dọn lịch sử | Bật dọn lịch sử định kỳ của Flowable (`historyCleaningTimeCycleConfig`) cho phiên đã kết thúc quá `11.retention.engineHistoryMonths` (12 tháng, Q11-52); `11.retention.instanceYears` (5 năm) điều khiển `instance_step` và bản chiếu | `ACT_HI_*` gọn, bằng chứng ở `instance_step` |
| Bộ thực thi bất đồng bộ | Bật; job thử lại tối đa 3 lần rồi vào dead letter; mỗi job lỗi sinh một `incident` (FR-11-060) | Không mất job lặng lẽ |
| Biến quy trình | Biến NC mã hóa envelope trước khi đặt; biến HC chỉ lưu ở engine, che khi đưa ra tiến độ | Q11-50 |
| Sao lưu | Cùng cụm `pg-core` (mục 7) | Khôi phục đồng bộ với `ph11_bpm` |

: Cấu hình engine Flowable cho PH-11

### 6.2. Kafka

Mười bảy topic `{tenant}.bpm.{thực-thể}.{sự-kiện}.v1` của EVT-11-01…17 do Debezium Outbox Event Router đọc từ `outbox_event`, khóa phân vùng là mã hồ sơ hoặc mã đối tượng; sự kiện không chứa giá trị biến. Phiên tiêu thụ `{tenant}.bpm.service.completed.v1`, `.failed.v1` (kết quả service task từ PH-04) và sự kiện, thông điệp PH-10 cho khởi tạo và message catch; khử trùng bằng `inbox_message`.

### 6.3. Ceph RGW

Tệp đính kèm việc (`task_attachment.object_ref`, quét mã độc trước khi cho tải); gói quy trình nhập, xuất (FR-11-010); gói bằng chứng BPMN 2.0 (FR-11-064).

### 6.4. Valkey

`dh:{tenant}:bpm:idem:{khóa}` giữ `Idempotency-Key` khởi tạo phiên 24 giờ (lớp nhanh phía trước `uq_instance_index_idempotency`); `dh:{tenant}:bpm:progress:{businessKey}` đệm tiến độ 30 giây (`11.progress.cacheSeconds`); `dh:{tenant}:bpm:claim:{taskId}` khóa ngắn khi nhận việc. Mất Valkey chỉ mất đệm và khóa tạm, không mất dữ liệu.

### 6.5. OpenBao và ClickHouse

Khóa `dh-{tenant}-bpm-pii` (transit) mã hóa biến NC và `result_enc`; `*_kid` ghi phiên bản khóa. PH-11 không có ClickHouse: số liệu vận hành đi qua sự kiện sang PH-13.

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

Thời hạn lưu giữ theo SRS cũ M4 4.3, điều chỉnh vì outbox thay bảng sự kiện tiến độ; việc dọn do `RetentionPurgeJob` thực hiện theo `11.retention.instanceYears`, `11.retention.sagaYears` và `11.retention.engineHistoryMonths` (FRS 8.2).

| Đối tượng | Lưu giữ | Cơ chế dọn, sao lưu |
|---|---|---|
| Schema `ph11_bpm`, `ph11_flowable` | Theo `pg-core`: WAL liên tục, base backup hằng ngày lên Ceph RGW, RPO ≤ 15 phút, RTO ≤ 30 phút (ADR-034) | Diễn tập DR theo D03-09 |
| Mô hình, phiên bản, biểu mẫu, ý định, bù trừ, biến, mẫu, bảng quyết định, yêu cầu duyệt, chạy thử, can thiệp phiên, lịch, ngày lễ, tham số | Vĩnh viễn, không xóa (chạy thử dọn theo `11.test.retentionDays`) | Quyền `REVOKE DELETE` |
| `instance_index` và `task_index`, `task_comment`, `task_attachment`, `service_call`, `due_tracking`, `incident`, `delegation` | 5 năm sau khi phiên kết thúc (Q11-53 về thời hạn lưu trữ hồ sơ) | `RetentionPurgeJob` xóa theo lô, con trước cha |
| `instance_step` | 5 năm sau khi phiên kết thúc | `DETACH`, `DROP` phân vùng tháng |
| `saga_log`, `saga_step`, `saga_skip_request` | Tối thiểu 5 năm (`11.retention.sagaYears`) | Không xóa bằng ứng dụng (đối soát liên cơ quan) |
| `legal_hold`, `compliance_sample_run` | Vĩnh viễn, không xóa (bằng chứng giữ pháp lý, hồ sơ thẩm định); hồ sơ có giữ còn hiệu lực bị `RetentionPurgeJob` bỏ qua (ERR-11-047) | Quyền `REVOKE DELETE` |
| `outbox_event`, `inbox_message` | 3 ngày; 7 ngày sau khi xử lý | `OutboxCleaner`, `InboxReaper` mỗi giờ |
| `ACT_*` của Flowable | Runtime theo phiên; history `audit` giữ 12 tháng | Dọn lịch sử của Flowable (mục 6.1) |
| Kafka, OpenBao, Ceph RGW | Theo D03-09: bản sao 3; snapshot Raft hằng giờ; đối tượng bản sao hai site | |

: Sao lưu, khôi phục, mã hóa và lưu giữ

**Mã hóa.** Kết nối `pg-core` bắt buộc TLS; dữ liệu tĩnh mã hóa mức đĩa (D03-07). Lớp thứ hai ở ứng dụng: biến NC và `task_index.result_enc` mã hóa envelope trước khi ghi; `ph11_flowable` có biến HC rõ nên bản sao lưu giới hạn quyền đọc như dữ liệu `RESTRICTED`.

**Thứ tự khôi phục.** OpenBao trước, `pg-core` sau; sau khi khôi phục chạy đối soát bản chiếu với engine, rồi mở lại tác vụ nền.

## 8. Ánh xạ thực thể, chức năng và CSDL cũ sang thiết kế mới

### 8.1. Thực thể EN-11 → bảng

Thực thể EN-11-01…28 theo FRS Phụ lục A; `shedlock` không có mã EN; EN-11-29…31 đã vào FRS Phụ lục A.2 (bản 0.2).

<!-- gen:en:start -->
| Thực thể | Tên | Bảng hiện thực |
|---|---|---|
| EN-11-01 | `process_model` | `process_model` |
| EN-11-02 | `process_version` | `process_version` |
| EN-11-03 | `form_definition` | `form_definition` |
| EN-11-04 | `service_intent` | `service_intent` |
| EN-11-05 | `compensation_action` | `compensation_action` |
| EN-11-06 | `process_template` | `process_template` |
| EN-11-07 | `variable_definition` | `variable_definition` |
| EN-11-08 | `instance_index` | `instance_index` |
| EN-11-09 | `task_index` | `task_index` |
| EN-11-10 | `task_comment` | `task_comment` |
| EN-11-11 | `task_attachment` | `task_attachment` |
| EN-11-12 | `delegation` | `delegation` |
| EN-11-13 | `business_calendar` | `business_calendar` |
| EN-11-14 | `calendar_day` | `calendar_day` |
| EN-11-15 | `due_tracking` | `due_tracking` |
| EN-11-16 | `saga_log` | `saga_log` |
| EN-11-17 | `saga_step` | `saga_step` |
| EN-11-18 | `incident` | `incident` |
| EN-11-19 | `migration_plan` | `migration_plan` |
| EN-11-20 | `publish_request` | `publish_request` |
| EN-11-21 | `outbox_event` | `outbox_event` |
| EN-11-22 | `inbox_message` | `inbox_message` |
| EN-11-23 | `tenant_setting` | `tenant_setting` |
| EN-11-24 | `decision_table` | `decision_table` |
| EN-11-25 | `service_call` | `service_call` |
| EN-11-26 | `test_run` | `test_run` |
| EN-11-27 | `instance_change` | `instance_change` |
| EN-11-28 | `instance_step` | `instance_step` |

: Ánh xạ thực thể EN-11 sang bảng

Bảng ngoài danh mục EN của FRS (đề nghị bổ sung, mục 9.2): `shedlock`, đã được FRS nhận thành EN-11-29…31.
<!-- gen:en:end -->

### 8.2. Chức năng FR-11 → bảng

Bảng liệt kê 66 chức năng theo khung FR-11-001…066; chức năng không có bảng riêng ghi các bảng phục vụ (ví dụ chạy thử dùng phiên `TEST`).

<!-- gen:fr:start -->
| Nhóm | FR | Bảng hiện thực |
|---|---|---|
| A | FR-11-001…002 | `process_model` |
| A | FR-11-003…006 | `process_version` |
| A | FR-11-007…008 | `process_version`, `publish_request` |
| A | FR-11-009 | `process_model`, `process_version` |
| A | FR-11-010 | `process_version` |
| A | FR-11-011 | `test_run` |
| B | FR-11-012 | `form_definition` |
| B | FR-11-013 | `service_intent` |
| B | FR-11-014 | `compensation_action` |
| B | FR-11-015 | `process_template` |
| B | FR-11-016 | `variable_definition` |
| B | FR-11-017 | `decision_table` |
| C | FR-11-018 | `instance_index` |
| C | FR-11-019 | `instance_index`, `inbox_message` |
| C | FR-11-020…021 | `instance_index` |
| C | FR-11-022 | `instance_index`, `instance_step` |
| C | FR-11-023…024 | `instance_index` |
| C | FR-11-025 | `instance_index`, `instance_change` |
| C | FR-11-026 | `instance_index`, `migration_plan` |
| C | FR-11-027 | `instance_index`, `instance_change` |
| D | FR-11-028 | `service_intent`, `service_call`, `outbox_event` |
| D | FR-11-029 | `service_call`, `inbox_message` |
| D | FR-11-030 | `inbox_message` |
| D | FR-11-031 | `instance_step`, `due_tracking`, `incident` |
| D | FR-11-032 | `outbox_event` |
| D | FR-11-033 | `instance_index`, `instance_step` |
| E | FR-11-034…037 | `task_index` |
| E | FR-11-038 | `task_index`, `task_comment` |
| E | FR-11-039…040 | `task_index` |
| E | FR-11-041 | `task_index`, `delegation` |
| E | FR-11-042 | `task_index` |
| E | FR-11-043 | `task_index`, `task_comment`, `task_attachment` |
| E | FR-11-044 | `task_index` |
| F | FR-11-045 | `business_calendar`, `calendar_day` |
| F | FR-11-046…050 | `due_tracking` |
| G | FR-11-051 | `compensation_action`, `saga_log`, `saga_step` |
| G | FR-11-052 | `saga_log`, `saga_step` |
| G | FR-11-053 | `saga_log`, `saga_step`, `saga_skip_request` |
| G | FR-11-054 | `saga_log`, `legal_hold` |
| H | FR-11-055 | `instance_index` |
| H | FR-11-056 | `instance_step`, `outbox_event` |
| H | FR-11-057 | `instance_step` |
| I | FR-11-058 | `instance_index`, `task_index`, `due_tracking`, `saga_log`, `incident` |
| I | FR-11-059 | `instance_step` |
| I | FR-11-060 | `service_call`, `incident` |
| I | FR-11-061 | `incident` |
| J | FR-11-062 | `tenant_setting` |
| J | FR-11-063 | `tenant_setting`, `legal_hold` |
| J | FR-11-064 | `instance_step`, `compliance_sample_run` |
| J | FR-11-065 | `outbox_event` |
| J | FR-11-066 | `task_index`, `task_comment`, `instance_step` |

: Ánh xạ FR-11 sang bảng

<!-- gen:fr:end -->

### 8.3. Mô hình SRS cũ của repo (`docs/07-srs/SRS-PH-11-bpm.md` M4)

SRS cũ có sáu thực thể trên giấy, chưa có bảng nào chạy; bảng dưới chuyển thể sang thiết kế mới.

| SRS cũ | Bảng mới | Chuyển đổi |
|---|---|---|
| `DINH_NGHIA_QT` | `process_model` | `process_key` giữ tên, mẫu chữ hoa, gạch dưới; `trang_thai` DRAFT, ACTIVE, RETIRED → cờ `archived` kèm `archive_reason` (vòng đời chuyển sang phiên bản) |
| `PHIEN_BAN_QT` | `process_version` | `bpmn_xml` TEXT → `text` kèm CHECK 8 MiB (trần `11.model.maxXmlKb`); `checksum varchar(64)` → `checksum bytea(32)`; DRAFT, READY, ACTIVE, SUSPENDED → DRAFT, IN_REVIEW, PUBLISHED, DEPRECATED, RETIRED |
| `TRIEN_KHAI_QT` | Gộp vào `process_version` | `deployment_id` ở phiên bản; không có bảng riêng vì chỉ một môi trường thật, chạy thử ghi ở `test_run` và phiên `TEST` |
| `ANH_XA_SERVICE_TASK` | `service_intent` | `camel_route_id` → `bindings` (môi trường sang luồng PH-04); ánh xạ thành đối tượng của tenant, không theo từng phiên bản |
| `DANG_KY_BU_TRU` | `compensation_action` | `chinh_sach` AUTO, MANUAL, NONE_APPROVED giữ nguyên; `ghi_chu_nghiep_vu` bắt buộc → `business_note` từ 20 ký tự khi `NONE_APPROVED` |
| `INSTANCE_QT` | `instance_index` | `bien_quy_trinh` JSONB không chuyển: biến ở engine, bản chiếu chỉ giữ `progress_public` đã che; khởi tạo lũy đẳng bằng `idempotency_key` UNIQUE; thêm `start_channel`, `parent_instance_id` |
| `BUOC_INSTANCE` | `instance_step` | Thêm phân vùng tháng; `ket_qua` JSONB → `result_code` và `summary` đã che |
| `USER_TASK` | `task_index` | READY, CLAIMED, COMPLETED, OVERDUE, CANCELLED → UNASSIGNED, ASSIGNED, DELEGATED, COMPLETED, CANCELLED; OVERDUE chuyển thành `due_tracking.status`; `candidate_groups` JSONB → `candidates varchar(100)[]` (người hoặc `group:{mã}`) |
| `TASK_HANH_DONG` | `task_comment`, `instance_change`, `instance_step` | Ý kiến, can thiệp phiên, thao tác hệ thống (kiểm toán PH-13) |
| `SAGA_NHAT_KY` | `saga_log`, `saga_step` | `chi_tiet_buoc` JSONB tách thành bảng `saga_step`; thêm đối soát (`reconcile_state`) |
| `SU_KIEN_TIEN_DO` | `outbox_event` | Sự kiện sống 3 ngày; tiến độ lịch sử qua `instance_step` |

: Ánh xạ mô hình SRS cũ sang bảng PH-11

### 8.4. Hệ cũ Viettel 2021

Hệ cũ không có BPM (BRD ghi REQ-11 là năng lực mới) nên không có bảng hay cột cũ cần chuyển đổi cho D06-01 và không có changeset di trú. Truy vết gián tiếp qua LGC-NGSP-002, LGC-NGSP-004, LGC-BUS-037; dữ liệu liên quan do các HTTT khởi tạo qua API, không nhập từ hệ cũ.

## 9. Câu hỏi mở và đề nghị đồng bộ cho FRS

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

### 9.1. Câu hỏi mở

Các câu hỏi chưa có quyết định, kèm đề xuất tạm.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q11-50 | Biến NC: mã hóa envelope ở ứng dụng rồi đặt vào `ACT_RU_VARIABLE`, hay giữ ngoài engine (kho riêng, engine chỉ giữ tham chiếu) | Mã hóa ở ứng dụng bằng bộ tuần tự hóa tùy biến, khóa `dh-{tenant}-bpm-pii`; biến HC để rõ ở engine |
| Q11-51 | Một engine đa tenant bằng `tenantId` hay tách engine hoặc schema mỗi tenant (cô lập mạnh hơn, tốn tài nguyên) | Một engine, `tenantId`; tách khi tenant cấp độ cao hoặc khối lượng đòi hỏi |
| Q11-52 | Thời hạn giữ lịch sử `ACT_HI_*`: 12 tháng (kiểm toán dựa `instance_step`) hay 5 năm; và ai nạp ngày nghỉ lễ quốc gia hằng năm | 12 tháng cho engine, 5 năm cho `instance_step`; ngày lễ do TA nhập hoặc nhập từ lịch nền quốc gia ở `COMMON` (đã có ở mẫu S) |
| Q11-53 | Thời hạn lưu hồ sơ thủ tục theo Luật Lưu trữ có thể dài hơn 5 năm; lưu trữ lạnh bản chiếu và `instance_step` sau 5 năm ở định dạng nào, đọc lại ra sao | Giữ 5 năm trực tuyến; lưu trữ lạnh Parquet mã hóa trên Ceph RGW kèm chỉ mục `business_key` |
| Q11-54 | Đồng bộ bản chiếu với engine khi hai nguồn kết nối không chung giao dịch: cơ chế và xử lý lệch | Bộ nghe sự kiện Flowable cập nhật bản chiếu sau commit, upsert lũy đẳng theo mã engine; `InstanceReconciler` quét mỗi giờ, sửa lệch và mở sự cố khi quá 5 phút |

: Câu hỏi mở của tập CSDL PH-11

### 9.2. Đề nghị đồng bộ FRS

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

FRS 0.2 (Phụ lục C) đã hấp thụ các đề nghị của bản 0.2: EN-11-28 `instance_step`, `OutboxStatus`, `InboxStatus`, dạng JSON, `failed_element`, `audit.recorded.v1` (nay `bpm.audit.recorded.v1`, EVT-11-21), `COMMON` ở FRS 8.2. Còn lại:

| Số | Nội dung | Nơi ở DDL |
|---|---|---|
| 1 | Cột phụ trợ không liệt kê ở FRS A.2 (FRS: danh sách đủ ở DDL): `process_version.process_key`; `instance_index.idempotency_key`, `progress_percent`, `suspended_at`; `due_tracking.due_value`, `due_unit`; `saga_log.reconcile_*`; `incident.retries_done`; `service_call.error_message` | Cột tương ứng |
| 2 | Đề nghị EN-11-29 `saga_skip_request` (FR-11-053), EN-11-30 `legal_hold` (FR-11-054, 063), EN-11-31 `compliance_sample_run` (FR-11-064); thuộc tính theo cột ở mục 3.30…3.32; thêm enum `SkipRequestStatus` (`PENDING`, `APPROVED`, `REJECTED`) vào Phụ lục A.1 | `saga_skip_request`, `legal_hold`, `compliance_sample_run` |
| 3 | Bảng hạ tầng `shedlock` không cần EN | `shedlock` |

: Điểm còn lại cho FRS và CSDL

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ FRS Phụ lục A: enum, tên cột snake_case theo API, 32 tham số `11.*`, EN-11-25 `service_call`, thêm `test_run` (EN-11-26) và `instance_change` (EN-11-27); lịch nền, mẫu S cho lịch và tham số; ủy quyền tối đa 90 ngày; 29 bảng, kiểm cô lập 257 khối PASS; mục 9.2 chỉ nêu điều FRS cần thêm |
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-CSDL và K-TRINH-BAY: 27 bảng `ph11_bpm`, cách đặt schema `ph11_flowable`, DDL và changelog chạy thử trên PostgreSQL 16.15, kiểm cô lập 151 khối PASS; ERD bốn nhóm; mô hình mẫu S cho mẫu quy trình `COMMON`; phân vùng tháng `instance_step`; ánh xạ EN, FR, SRS cũ; câu hỏi mở Q11-50…54 |
| 0.3 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ FRS 0.2: EN-11-28 `instance_step`, 36 tham số `11.*` (thêm `11.designer.autosaveSeconds`, `11.task.draftDebounceSeconds`, `11.task.unmaskSeconds`, `11.escalation.nextLevelHours`), `IncidentType` thêm `SUPPLEMENT_EXPIRED`, topic outbox `bpm.audit.recorded.v1` (EVT-11-21), `commandId` UUID v5; kiểm cô lập 266 khối PASS; mục 9.2 thu gọn |
| 0.4 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Đóng Q11-55 bằng ba bảng: `saga_skip_request` (API-11-101, 132, 133), `legal_hold` (API-11-120, 134, 135), `compliance_sample_run` (API-11-137); thêm `uq_saga_step_tid`; 32 bảng, 297 khối PASS
