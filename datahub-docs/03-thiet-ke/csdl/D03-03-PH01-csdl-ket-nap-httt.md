---
ma_tai_lieu: D03-03-PH01
ten: Thiết kế cơ sở dữ liệu phân hệ PH-01 Kết nạp hệ thống thông tin
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-connect, DBA, ATTT, kiểm thử viên, hội đồng thẩm định
phan_he: PH-01
mo_ta: Thiết kế cơ sở dữ liệu của phân hệ Kết nạp hệ thống thông tin gồm 26 bảng ở schema ph01_onboarding, ràng buộc bốn mắt và máy trạng thái khóa ở CSDL, không lưu bí mật, RLS theo tenant, DDL đã chạy thử, sao lưu, lưu giữ và ánh xạ dữ liệu hệ cũ.
tai_lieu_lien_quan: D02-03-PH01 FRS; D02-04-PH01 Use case; D03-02-PH01 SDD; D03-04-PH01 API; D03-10 Đa tenant; D02-07 Từ điển dữ liệu; D03-07 ATTT
---

# D03-03-PH01 · Thiết kế CSDL Kết nạp hệ thống thông tin

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu thiết kế nơi lưu dữ liệu của PH-01, cửa vào duy nhất để một hệ thống thông tin (HTTT) trở thành thành viên của Datahub: hồ sơ kết nạp, ý kiến thẩm định, trần phạm vi được duyệt, định danh ứng dụng, bàn giao thông tin xác thực, việc cấp định danh và cắt quyền, rà soát quyền định kỳ. Thiết kế đặt mục tiêu để những điều quan trọng nhất của FRS (bốn mắt, mã bất biến, không lộ bí mật, quyền không rộng hơn phạm vi đã duyệt) đúng ngay cả khi mã dịch vụ có lỗi, vì đã bị khóa ở lớp CSDL.

**Phạm vi.** Schema `ph01_onboarding` trên cụm `pg-core` gồm 26 bảng cho 18 thực thể của [D02-03-PH01](../../02-yeu-cau/frs/D02-03-PH01-frs-ket-nap-httt.md) §4.2 và các bảng kỹ thuật của saga, cắt quyền, outbox, hộp nhận, hàng đợi thông báo và lũy đẳng. Tài liệu không thiết kế dữ liệu của phân hệ khác: tổ chức (PH-20), tài khoản và client (PH-12), consumer và hạn mức (PH-03), đăng ký sử dụng API (PH-02) chỉ được tham chiếu bằng mã, không bằng khóa ngoại.

**Căn cứ pháp lý.** CMP-LAW-03 (NĐ 278/2025: đầu mối, căn cứ khai thác dữ liệu, kế thừa NĐ 47/2020); CMP-LAW-05 (Luật BVDLCN 91/2025: dữ liệu liên hệ đầu mối là dữ liệu cá nhân mức Hạn chế); CMP-LAW-06 và CMP-LAW-08 (NĐ 331/2026, TCVN 14423:2026 cấp độ 3: quản lý tài khoản, bí mật, rà soát quyền, nhật ký); CMP-LAW-09 (Công văn 631/THH-THHT: chỉ HTTT đã kết nạp mới có định danh); CMP-LAW-01 (Luật Dữ liệu số: chia sẻ dữ liệu có căn cứ).

**Những điểm hội đồng cần lưu ý.** (1) **Không có giá trị bí mật trong CSDL**: bảng chỉ có đường dẫn OpenBao `secret_ref` (bị ràng buộc khớp mẫu đường dẫn của đúng tenant nên không nhét được giá trị bí mật vào), số phiên bản, dấu vân tay và giá trị băm; bài kiểm quét toàn schema xác nhận không có cột nào khác tên giống bí mật (BR-01-007, NFR-01-009). (2) **Bàn giao một lần ở cấp CSDL**: liên kết chỉ lưu SHA-256, mã bọc OpenBao lưu mã hóa bằng khóa transit và bị xóa ngay khi bàn giao rời trạng thái chờ, trạng thái đã mở không quay lại được. (3) **Bốn mắt và máy trạng thái khóa ở CSDL**: người lập, người nộp, người thẩm định không phê duyệt cùng hồ sơ, người nộp không kích hoạt, chuyển trạng thái chỉ theo bảng chuyển; mã HTTT bất biến; hồ sơ đã nộp không xóa cứng được. (4) **Cô lập tenant bằng `FORCE ROW LEVEL SECURITY`** trên cả 25 bảng có `tenant_id`; khóa ngoại luôn kèm `tenant_id` nên không thể trỏ chéo tenant; vai trò chỉ đọc bị chặn đọc dữ liệu cá nhân, mã bàn giao, đường dẫn bí mật theo từng cột. (5) Việc cắt quyền trong 60 giây được hỗ trợ bằng bảng việc có thứ tự và khóa lũy đẳng, trạng thái đặt trước và không hoàn tác khi lỗi (BR-01-023).

DDL [`ph01/ddl`](ph01/ddl/ph01_00_bootstrap.sql) đã chạy thử trên PostgreSQL 16.16 sạch; bài kiểm [`ph01_isolation_test.sql`](ph01/test/ph01_isolation_test.sql) đạt 207 khối và bài kiểm di trú [`ph01_migrate_test.sql`](ph01/test/ph01_migrate_test.sql) đạt 19 khối (§4.2).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Bảng ở schema `ph01_onboarding` | 26 (24 mẫu P, 1 mẫu S là `template`, 1 bảng kỹ thuật `shedlock`) |
| Cột, khóa ngoại, ràng buộc CHECK | 522 cột, 30 khóa ngoại (đều kèm `tenant_id`), 234 ràng buộc CHECK |
| Chỉ mục | 118 (52 do khóa chính, duy nhất; 66 tạo riêng, trong đó 41 chỉ mục từng phần) |
| Chính sách RLS | 100 (25 bảng nhân bốn lệnh) |
| Hàm, thủ tục, trigger | 19 hàm và thủ tục; 31 trigger (12 trigger bảo vệ, 19 trigger cập nhật khóa lạc quan) |
| Bài kiểm đã chạy | 207 khối cô lập và nghiệp vụ, 19 khối di trú, đều PASS |
| Dữ liệu khởi tạo | 3 mẫu văn bản mặc định ở tenant `COMMON` |
| Câu hỏi mở | 5 (Q01-50…Q01-54) |

: Con số chính của thiết kế CSDL PH-01

## 0. Giới thiệu

### 0.1. Mục đích

Tài liệu đặc tả lược đồ dữ liệu của PH-01 để kỹ sư `dh-connect` viết mã truy cập dữ liệu, DBA vận hành, ATTT kiểm tra cách ly và bảo vệ bí mật, kiểm thử viên viết ca kiểm thử ràng buộc, và hội đồng thẩm định thấy các quy tắc nghiệp vụ trọng yếu được bảo đảm ở lớp dữ liệu.

### 0.2. Phạm vi

Tài liệu bao quát schema `ph01_onboarding`: chiến lược lưu trữ và cách ly tenant (chương 1), sơ đồ thực thể – quan hệ (chương 2), đặc tả 26 bảng (chương 3), DDL và changelog (chương 4), dữ liệu khởi tạo (chương 5), kho ngoài PostgreSQL (chương 6), sao lưu và lưu giữ (chương 7), ánh xạ dữ liệu hệ cũ (chương 8), câu hỏi mở (chương 9). Không bao gồm API (D03-04-PH01), màn hình (D03-06-PH01), tham số theo tenant (nằm ở PH-18, `onboarding.*`, DD-14) và thống kê kết nạp (FR-01-051, Đợt 2, tính từ các bảng ở đây).

### 0.3. Người đọc

Tài liệu phục vụ năm nhóm người đọc; bảng sau chỉ ra mỗi nhóm nên đọc chương nào để khỏi phải đọc toàn bộ.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-connect` | Chương 1, 3, 4 |
| DBA, vận hành | Chương 1, 4, 6, 7 |
| ATTT | Chương 1.2, 1.4, 3.3, 3.12, 3.13, 3.22, 7 |
| Kiểm thử viên | Chương 1.4, 3, 4.2 |
| Hội đồng thẩm định | Tóm tắt, chương 1.4, 2, 8 |

: Người đọc và phần cần đọc

### 0.4. Thuật ngữ và chữ viết tắt

Thuật ngữ nghiệp vụ dùng chung với [D02-03-PH01](../../02-yeu-cau/frs/D02-03-PH01-frs-ket-nap-httt.md) §1.4 và D00-01. Một số từ kỹ thuật dùng trong tài liệu:

| Thuật ngữ | Nghĩa |
|---|---|
| RLS (row level security) | Chính sách bảo mật mức dòng của PostgreSQL; `FORCE` buộc cả chủ bảng cũng chịu chính sách |
| Mẫu P, mẫu S | Hai mẫu RLS của D03-10: P là dữ liệu riêng tenant; S là dữ liệu dùng chung có dòng `COMMON` |
| Bốn mắt | Nguyên tắc người này không duyệt việc của người kia (BR-01-017) |
| Lũy đẳng (idempotent) | Thực hiện lặp lại cho cùng kết quả, không tạo trùng |
| Outbox | Bảng ghi sự kiện trong cùng giao dịch với thay đổi dữ liệu, được Debezium hoặc bộ chuyển phát sang Kafka (ADR-042) |
| Saga | Chuỗi bước có bù trừ cấp định danh, lưu bền trong CSDL |
| Bọc phản hồi (response wrapping) | Cơ chế OpenBao trả mã dùng một lần thay cho giá trị bí mật |
| HC | Mức phân loại dữ liệu Hạn chế (dữ liệu cá nhân của đầu mối) |

: Thuật ngữ và chữ viết tắt dùng trong tài liệu

### 0.5. Tài liệu tham chiếu

D02-03-PH01 (FRS, thực thể §4.2, quy tắc §7); D02-04-PH01 (use case); D03-02-PH01 (SDD, mô hình miền §4.1, saga §4.6, bàn giao §4.7, cắt quyền §4.10); D03-10 (mẫu RLS P và S, sáp nhập tenant §5.4); D02-07 (thực thể DD-03, 04, 05, 11, 12); D03-07 (SEC-24, 26, 27, 30, 31, 33, 45, 60, 62, 71, 80, 81, 82); ADR-003 (PostgreSQL và RLS), ADR-008 (Garage), ADR-031 (kiểm toán), ADR-042 (outbox), ADR-058 (máy trạng thái nội bộ).

### 0.6. Cấu trúc tài liệu

Mỗi bảng ở chương 3 mở đầu bằng khối đặc tả 10 mục (Mục đích, FR phục vụ, Khóa chính, Duy nhất, Khóa ngoại, Ràng buộc CHECK, Chỉ mục, Cách ly tenant, Phân vùng và chỉ thêm, Ghi chú) trích từ DDL đã chạy thử bằng công cụ [`them_dac_ta_bang.py`](ph01/tools/them_dac_ta_bang.py), rồi đến danh sách cột sinh bằng [`gen_tables_md.py`](ph01/tools/gen_tables_md.py). Sửa ở DDL rồi sinh lại, không sửa tay phần sinh.

## 1. Chiến lược lưu trữ

### 1.1. Schema, vai trò và kết nối

PH-01 là module `onboarding` của `dh-connect` (Java 21, Spring Boot 4, Spring Modulith, vùng Z3). Dữ liệu nằm ở schema `ph01_onboarding` của cụm `pg-core` (Z5, 3 instance, ADR-003), do `ph01_owner` (NOLOGIN) sở hữu. Tên schema theo quy ước `ph{nn}_{tên ngắn}` của D00-04 §4; D02-07 đã dùng đúng tên này cho DD-03, DD-04, DD-05.

| Vai trò | Quyền | Dùng bởi |
|---|---|---|
| `ph01_owner` | Chủ schema và bảng, NOLOGIN, không `BYPASSRLS`; vẫn chịu RLS vì `FORCE` | Liquibase, DBA |
| `ph01_app` (nhóm) | DML cần thiết; không xóa bảng giữ vĩnh viễn; không sửa bảng chỉ thêm; không `BYPASSRLS` | `dh_connect_app` (tài khoản kết nối của `dh-connect`) |
| `ph01_readonly` | Chỉ đọc theo cột; không đọc dữ liệu cá nhân, mã bàn giao, đường dẫn bí mật, tệp xuất, `outbox`, `inbox`, hàng đợi thông báo | Báo cáo, kiểm toán, đối soát |
| `dh_connect_migrator` | Thành viên `ph01_owner`, chỉ chạy Liquibase | CI/CD |

: Vai trò cơ sở dữ liệu của schema ph01_onboarding

Hai tài khoản đăng nhập `dh_connect_app` và `dh_connect_migrator` do hạ tầng tạo và gán thành viên (D03-09), DDL chỉ tạo ba vai trò NOLOGIN; bài kiểm tạo `dh_connect_app` giả để chạy. `dh-connect` kết nối bằng `dh_connect_app` qua `TenantAwareDataSource`, đặt `SET LOCAL app.tenant_id` ở đầu mỗi giao dịch từ token đã xác minh (SEC-80, SEC-81). Các đơn vị triển khai khác (`dh-runtime`, `dh-integration`, Kafka Connect) không kết nối schema này; phân hệ khác lấy trạng thái HTTT qua `MemberSystemQueryApi`, API đọc bản sao (FR-01-038) và sự kiện (D03-01 §7.3). Debezium đọc WAL của `outbox` bằng tài khoản sao chép riêng, không dùng `dh_connect_app`.

Schema cũ `ph01` của `apps/control` (W1: `application`, `application_audit`, `application_attachment`, `outbox_event`) được di trú bằng changeset `ph01-9000` rồi đổi tên `*_legacy_w1` (chương 8).

### 1.2. Cách ly tenant

Mọi bảng nghiệp vụ có `tenant_id varchar(16)` và bật `FORCE ROW LEVEL SECURITY` qua thủ tục `ph01_onboarding.p_enable_rls(bảng, mẫu)` với bốn chính sách `select`, `insert`, `update`, `delete` mỗi bảng.

| Mẫu | Đọc | Ghi | Bảng |
|---|---|---|---|
| P (riêng) | Dòng có `tenant_id` bằng tenant của phiên | Cùng điều kiện; `tenant_id` phải dạng `T{nn}` | 24 bảng nghiệp vụ và hạ tầng |
| S (dùng chung) | Dòng của tenant phiên và `COMMON` | Dòng tỉnh khi phiên là tỉnh; dòng `COMMON` chỉ khi phiên là `PLATFORM` | `template` |
| Không áp dụng | — | — | `shedlock` (bảng kỹ thuật của thư viện ShedLock, không có `tenant_id`) |

: Cách ly tenant theo mẫu RLS

Ba điểm riêng của PH-01. Một là tenant `COMMON` không có HTTT thành viên (SDD §6): nhu cầu của HTTT cấp bộ, ngành do TA nhập hộ vào tenant của mình, nên các bảng nghiệp vụ dùng mẫu P và ràng buộc `tenant_id ~ '^T[0-9]{2}$'`, phiên `PLATFORM` không đọc, không ghi bảng nào ngoài `template`. Hai là khóa ngoại luôn là `FOREIGN KEY (x_id, tenant_id)` trỏ tới `UNIQUE (id, tenant_id)` của bảng cha nên một dòng không thể gắn với cha của tenant khác kể cả khi kẻ tấn công biết `id`. Ba là biến phiên `app.tenant_id` được đọc bằng `current_setting(…, false)` nên quên đặt biến thì truy vấn lỗi thay vì trả rỗng im lặng; phiên `PLATFORM` hay phiên rỗng đều không thấy dòng nào của tenant.

Tác vụ nền liên tenant (bộ chạy saga, cắt quyền, nhắc hạn, rà soát) lặp từng tenant qua `TenantJobRunner` và đặt biến phiên cho mỗi lần (SDD §6). Khi sáp nhập tenant (D03-10 §5.4), công cụ của PH-18 sao chép bản ghi sang tenant đích, giữ `id` gốc và ghi `member_system.origin_tenant_id` để truy vết; định danh ứng dụng được cấp mới nên `app_credential` không sao chép (Q01-54).

### 1.3. Quy ước bảng

Theo D00-01 §5.1 mọi bảng nghiệp vụ có `id uuid` (UUID v7 sinh ở ứng dụng), `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (trigger `tg_touch` tăng `version` và đặt `updated_at`, `version` là khóa lạc quan, thành phần của `ETag`). Trạng thái dùng `varchar` kèm `CHECK` liệt kê đúng FRS §4.3, §4.4; thêm giá trị là một changeset mới. Mã dạng chuỗi có `CHECK` theo mẫu của FRS (ví dụ `code ~ '^[A-Z][A-Z0-9-]{2,63}$'`). Ngoại lệ có chủ đích:

| Bảng | Ngoại lệ | Lý do |
|---|---|---|
| `state_history` | Không có `version`, `updated_*`, `created_*`; có `occurred_at`, `actor`; chỉ thêm | Nhật ký bất biến (BR-01-011, BR-01-031) |
| `sandbox_test` | Không có `version`, `updated_*`, `created_by`; có `received_at`; chỉ thêm | Dữ liệu đo nhận từ PH-03, PH-13 |
| `saga_step` | Không có `created_by`, `updated_by` | Bảng kỹ thuật do bộ chạy ghi |
| `notify_outbox` | Chỉ có `created_*`, không có `version`, `updated_*` | Hàng đợi, đổi trạng thái bằng cột riêng |
| `outbox` | Khóa `event_id`; không có cột sửa ngoài `relayed_at` | DD-11, Debezium đọc WAL |
| `inbox`, `idempotency_record` | Khóa tự nhiên `(tenant_id, event_id)` và khóa lũy đẳng; không có `id`, `version` | Bản ghi lũy đẳng, hết hạn tự dọn |
| `shedlock` | Cấu trúc cố định của ShedLock | Thư viện bên thứ ba |

: Ngoại lệ so với quy ước bảng

Tên bảng khớp D02-07 (`member_system`, `contact`, `app_credential`) và danh sách SDD §14 mục 1; tệp đính kèm giữ tên `attachment` của SDD thay cho `file_object` của DD-12 (đề nghị đồng bộ ở cuối tài liệu). Cột `contact.job_title` thay cho `position` của FRS để tránh trùng từ khóa SQL.

### 1.4. Quy tắc nghiệp vụ chốt ở CSDL

Quy tắc nào cũng được dịch vụ kiểm trước (để trả đúng mã lỗi `ERR-01-*` và thông báo cho người dùng) và được CSDL kiểm lại như lớp phòng thủ thứ hai. Bảng sau liệt kê những ràng buộc đáng kể nhất; bài kiểm [`ph01_isolation_test.sql`](ph01/test/ph01_isolation_test.sql) có ít nhất một ca cho mỗi dòng.

| Ràng buộc hoặc đối tượng | Quy tắc | BR, FR, SEC |
|---|---|---|
| `uq_member_system_code`, `tg_member_system_guard` | Mã HTTT duy nhất trong tenant kể cả `REJECTED`, `TERMINATED` và bất biến | BR-01-018 · ERR-01-002 |
| `tg_member_system_guard`, `fn_member_transition_ok` | Chuyển trạng thái chỉ theo 10 cặp hợp lệ; `REJECTED`, `TERMINATED` đóng băng (chỉ cột `enforcement` và cột cập nhật đổi được) | ERR-01-005 |
| `fn_assert_submittable` | Nộp chỉ khi hồ sơ kỹ thuật đủ, có đầu mối kỹ thuật hoạt động, mọi dòng `CONSUME` đủ số, ngày, cơ quan, tệp căn cứ, tổ chức không còn HTTT `ACTIVE` thiếu đầu mối kỹ thuật; nộp phải tăng `revision_no` thêm 1 | BR-01-001, 013, 032 · ERR-01-008, 010, 015 |
| `ck_member_system_four_eyes`, `fn_assert_approvable`, `tg_review_step_guard`, `ck_change_request_four_eyes`, `ck_emergency_action_four_eyes` | Người lập, người nộp, người đã thẩm định không phê duyệt cùng hồ sơ; người nộp không kích hoạt; người đề nghị thay đổi không duyệt; người xác nhận khác người thực hiện thao tác khẩn | BR-01-010, 017 · ERR-01-017, 036 |
| `fn_assert_approvable` | Duyệt chỉ khi đủ ba bước của vòng nộp, mọi nhu cầu có kết luận, nhóm HTTT đã xác nhận | ERR-01-018, 019, 020 |
| `fn_assert_activatable`, `tg_app_credential_guard` | Kích hoạt và cấp định danh `PRODUCTION` chỉ khi đã qua kiểm thử SANDBOX (`sandbox_passed_at`) | BR-01-008 · ERR-01-031 |
| `tg_scope_ceiling_guard`, `ck_scope_ceiling_*` | Trần tạo ra bằng đúng phạm vi được chấp thuận hoặc thu hẹp; danh tính bất biến; không tự nâng mức phân loại; `REVOKED` là cuối | BR-01-003, 012 · ERR-01-037 |
| `ck_data_demand_scope`, `ck_data_demand_opinion` | Chấp thuận và thu hẹp có phạm vi được duyệt; thu hẹp, từ chối có ý kiến | BR-01-003 · ERR-01-019 |
| `ck_app_credential_secret_ref`, `ck_app_credential_secret_method` | Chỉ đường dẫn OpenBao đúng mẫu `kv/dh/{tenant}/clients/{mã}/{môi trường}` của đúng tenant; định danh `PRIVATE_KEY_JWT`, `MTLS` không có đường dẫn bí mật | BR-01-007 · SEC-33, SEC-82 |
| `ck_app_credential_expiry`, `ck_app_credential_secret_ttl`, `ck_app_credential_rotation` | Định danh ≤ 12 tháng; chuỗi bí mật ≤ 180 ngày; chuyển tiếp xoay vòng ≤ 14 ngày | BR-01-020, 021 · SEC-24 |
| `ck_app_credential_scopes_new`, `uq_app_credential_live` | Định danh mới cấp không có scope dữ liệu; mỗi (HTTT, môi trường) tối đa một định danh đang sống | BR-01-003 |
| `ck_handover_hash`, `ck_handover_ttl`, `ck_handover_sealed`, `ck_handover_opened`, `tg_handover_guard`, `uq_handover_pending` | Chỉ lưu SHA-256 của liên kết; hạn ≤ 72 giờ; mã bọc chỉ tồn tại khi chờ hoặc đang mở; mở là một chiều; người nhận là đầu mối kỹ thuật có tài khoản; mỗi định danh một bàn giao chờ | BR-01-005, 006 · NFR-01-010 · ERR-01-003, 024, 048 |
| `uq_provisioning_saga_running`, `ck_saga_step_idem`, `ck_saga_step_name` | Mỗi (HTTT, môi trường) tối đa một saga đang chạy; khóa lũy đẳng `sagaId:bước` | FR-01-020 · SDD §8.2 |
| `ck_enforcement_task_order`, `ck_enforcement_task_idem` | Thứ tự việc cắt quyền cố định theo chế độ; khóa lũy đẳng `enforcementId:loại` | BR-01-023 |
| `uq_access_review_cycle_open`, `tg_access_review_cycle_guard`, `ck_access_review_item_legal` | Mỗi tenant tối đa một kỳ chưa đóng; kỳ đi một chiều và chỉ đóng khi mọi mục có quyết định; không giữ mục có căn cứ hết hiệu lực | BR-01-014, 015 · ERR-01-039, 041 |
| `ck_member_system_reason`, `ck_app_credential_revoked`, `ck_change_request_reason`, `ck_emergency_action_reason` | Tạm ngừng, chấm dứt, từ chối, thu hồi, thao tác khẩn bắt buộc có lý do ≥ 10 ký tự | BR-01-009 · ERR-01-033 |
| `tg_member_system_no_delete`, `tg_draft_only_delete`, `tg_state_history_guard`, `REVOKE DELETE` | Hồ sơ đã nộp, thẩm định, lịch sử, trần, định danh giữ vĩnh viễn; chỉ nháp chưa từng nộp xóa mềm rồi xóa cứng sau 30 ngày | BR-01-011, 024 |
| `ck_contact_security_private`, `ck_contact_phone`, `uq_contact_active_email` | Đầu mối ATTT không công khai; số điện thoại E.164; không trùng thư điện tử đang hoạt động | BR-01-027 |
| `ck_outbox_*`, `ck_notify_outbox_no_link`, `ck_idempotency_record_no_open`, `ck_legacy_import_job_no_secret`, `ck_sandbox_test_error` | Không bí mật, không `secret_ref`, không dữ liệu liên hệ cá nhân trong sự kiện; không liên kết có mã trong thông báo; không lưu kết quả lũy đẳng của tuyến mở bàn giao; không khóa bí mật trong xem trước nhập hệ cũ | BR-01-007, 033 · SEC-32 · NFR-01-009 |
| `ck_outbox_topic_tenant`, `ck_member_system_base_urls`, `ck_member_system_ip_allowlist` | Topic mang đúng mã tenant; địa chỉ chỉ `https`; danh sách IP là CIDR hợp lệ | SEC-82, SEC-43 |

: Quy tắc nghiệp vụ chốt ở CSDL

Giới hạn cần nói rõ: CSDL không kiểm được những điều cần dữ liệu ngoài schema (tổ chức còn hoạt động ở PH-20, `dataType` thuộc danh mục bí mật nhà nước, phạm vi `NARROWED` là tập con của phạm vi đề nghị, scope của định danh nằm trong giao của trần và đăng ký đã duyệt ở PH-02, thời hạn xác thực hai yếu tố). Các kiểm tra này ở dịch vụ (ERR-01-006, 016, 018, 035, 037) và được ghi ở cột "Ghi chú" của bảng liên quan.

### 1.5. Định cỡ và tăng trưởng

Hồ sơ đo là "tỉnh vừa" (GĐ-01-01, GĐ-07: 200 HTTT, 80 HTTT kết nạp năm đầu); các dòng "giả định" lấy cơ sở từ SDD §11.1. Trần thiết kế theo NFR-01-017 áp mỗi tenant.

| Bảng | Tỉnh vừa (giả định) | Trần thiết kế | Cơ sở |
|---|---|---|---|
| `member_system` | 200 | 1.000 | GĐ-01-01; NFR-01-017 |
| `technical_profile` | 200 | 1.000 | Một dòng mỗi HTTT |
| `data_demand` | 1.200 | 6.000 | Giả định 6 mục mỗi HTTT (GĐ-01-02) |
| `scope_ceiling` | 1.000 | 50.000 | Mục được duyệt; NFR-01-017 |
| `contact` | 500 | 20.000 | Giả định 2,5 đầu mối mỗi HTTT; NFR-01-017 |
| `app_credential` | 260 | 5.000 | 1,3 định danh mỗi môi trường mỗi HTTT; NFR-01-017 |
| `review_step` | 300 mỗi năm | 6.000 | Ba bước mỗi vòng nộp, 80 hồ sơ, nộp lại ≤ 25% (giả định) |
| `state_history` | 8.000 mỗi năm | 40.000 | 200 HTTT nhân 40 chuyển (giả định, SDD §11.1) |
| `access_review_item` | 2.000 mỗi kỳ | 50.000 mỗi kỳ | Một mục mỗi cặp (HTTT, mục trần) |
| `sandbox_test` | 1 triệu mỗi năm | 5 triệu mỗi năm | 10 HTTT cùng ở SANDBOX, mỗi 5 phút một dòng (giả định, SDD §11.1) |
| `outbox` ổn định | < 40.000 | — | Ảnh chụp đối chiếu 200 dòng mỗi giờ, giữ 7 ngày |
| Cả schema, không kể tệp | < 1 GiB mỗi năm | < 5 GiB mỗi năm | Cộng các dòng trên; tệp đính kèm ở Garage khoảng 4 GiB mỗi năm |

: Định cỡ bảng PH-01

Không bảng nào cần phân vùng ở MVP: bảng lớn nhất là `sandbox_test` (khoảng 1 triệu dòng mỗi năm) được dọn theo lô sau một năm. Khi vượt khoảng 10 triệu dòng thì chuyển `sandbox_test` và `state_history` sang phân vùng tháng như PH-05 (`p_ensure_month_partitions`), không đổi mã nghiệp vụ; `tenant_id` đứng đầu mọi chỉ mục nên cùng chiến lược với phân hệ khác (SDD §11.3). Tách CSDL vật lý theo tenant ở cấp độ 4 (SEC-92) chỉ đổi lớp `DataSource` định tuyến.

## 2. Sơ đồ thực thể – quan hệ

Sơ đồ chia làm hai hình theo hai nhóm bảng có khóa ngoại với nhau; các bảng hạ tầng (`outbox`, `inbox`, `notify_outbox`, `idempotency_record`, `shedlock`), `legacy_import_job` và `template` không có khóa ngoại nên không vẽ. Hình 1 là phần hồ sơ: HTTT thành viên ở giữa, cùng hồ sơ kỹ thuật, đầu mối, tài liệu, nhu cầu khai thác, trần phạm vi, thẩm định, thay đổi, thao tác khẩn và lịch sử.

```{.mermaid caption="Sơ đồ thực thể – quan hệ: hồ sơ, nhu cầu khai thác, thẩm định"}
erDiagram
  member_system ||--o| technical_profile : "hồ sơ kỹ thuật"
  member_system ||--o{ contact : "đầu mối"
  member_system ||--o{ attachment : "tài liệu"
  member_system ||--o{ data_demand : "nhu cầu khai thác"
  member_system ||--o{ scope_ceiling : "trần phạm vi"
  member_system ||--o{ review_step : "bước thẩm định"
  member_system ||--o{ change_request : "yêu cầu thay đổi"
  member_system ||--o{ emergency_action : "thao tác khẩn"
  member_system ||--o{ state_history : "lịch sử trạng thái"
  attachment |o--o{ data_demand : "căn cứ pháp lý"
  attachment |o--o{ scope_ceiling : "căn cứ pháp lý"
  change_request |o--o{ data_demand : "đề nghị mở rộng"
  data_demand |o--o| scope_ceiling : "sinh trần khi duyệt"
  review_step |o--o| review_step : "sao chép kết luận"
  contact |o--o| contact : "đầu mối thay thế"
```

Hình 1 cho thấy `member_system` là gốc của mọi thứ còn lại. Mỗi đường là khóa ngoại thật kèm `tenant_id`. Đường từ `data_demand` tới `scope_ceiling` là điểm mấu chốt của BR-01-003: trần chỉ được tạo từ nhu cầu có kết luận chấp thuận hoặc thu hẹp và mang đúng phạm vi đã duyệt. `review_step` tự tham chiếu để sao chép kết luận sang vòng nộp mới khi dữ liệu liên quan không đổi (BR-01-032). Các bảng con của hồ sơ xóa theo tầng khi nháp chưa từng nộp bị xóa cứng; bảng bằng chứng (`review_step`, `scope_ceiling`, `change_request`, `emergency_action`) không có xóa theo tầng.

```{.mermaid caption="Sơ đồ thực thể – quan hệ: định danh, bàn giao, saga, cắt quyền, rà soát"}
erDiagram
  member_system ||--o{ app_credential : "định danh ứng dụng"
  app_credential ||--o{ handover : "bàn giao"
  contact ||--o{ handover : "người nhận"
  member_system ||--o{ sandbox_test : "kiểm thử SANDBOX"
  app_credential |o--o{ sandbox_test : "định danh được thử"
  member_system ||--o{ provisioning_saga : "saga cấp định danh"
  provisioning_saga ||--o{ saga_step : "bước"
  app_credential |o--o{ provisioning_saga : "định danh tạo ra"
  member_system ||--o{ enforcement_task : "việc cắt quyền"
  access_review_cycle ||--o{ review_confirmation : "phiếu xác nhận"
  access_review_cycle ||--o{ access_review_item : "mục rà soát"
  member_system ||--o{ access_review_item : "HTTT được rà soát"
  scope_ceiling ||--o{ access_review_item : "mục trần được rà soát"
  review_confirmation |o--o{ access_review_item : "phản hồi của đơn vị"
```

Hình 2 gom ba vòng đời tách biệt. Vòng đời định danh (định danh, bàn giao, kiểm thử) bắt đầu từ saga; saga và việc cắt quyền là hàng đợi bền để dịch vụ khởi động lại giữa chừng không mất tiến trình. Vòng đời rà soát quyền (kỳ, phiếu, mục) tham chiếu trần phạm vi nên thu hẹp hoặc thu hồi phạm vi sau rà soát là sửa `scope_ceiling` rồi phát sự kiện, không sửa hồ sơ gốc. Liên kết sang phân hệ khác (`owner_org_id` của PH-20, `user_account_id` của PH-12, `client_id` của PH-12 và PH-03) là theo mã, không có khóa ngoại, vì khác schema và khác đơn vị triển khai; tính hợp lệ được dịch vụ kiểm qua `Ph20Port`, `Ph12Port`, `Ph03Port` và đối soát hằng giờ.

## 3. Đặc tả bảng

Bảng sau liệt kê 26 bảng, cho biết bảng nào thuộc thực thể nào của FRS, bảng phục vụ nhóm chức năng nào, mẫu RLS và thời hạn lưu giữ; từng bảng được đặc tả ở các mục 3.1 đến 3.26, rồi truy vấn chính (3.27) và hàm, trigger dùng chung (3.28). Phần mục 3.1 đến 3.26 sinh từ DDL, sửa ở DDL rồi sinh lại.

| Mục | Bảng | Thực thể FRS | Nhóm FR | Mẫu RLS | Lưu giữ |
|---|---|---|---|---|---|
| 3.1 | `member_system` | EN-01-01 (DD-03) | A, B, C, D | P | Vĩnh viễn; nháp chưa từng nộp xóa sau 30 ngày kể từ xóa mềm |
| 3.2 | `technical_profile` | EN-01-02 | A, B | P | Vĩnh viễn |
| 3.3 | `contact` | EN-01-05 (DD-04) | A, F | P | Vĩnh viễn (Q01-51) |
| 3.4 | `attachment` | EN-01-06 (DD-12) | A | P | Vĩnh viễn |
| 3.5 | `template` | EN-01-18 | A | S | Theo phiên bản |
| 3.6 | `state_history` | EN-01-11 | B, C, D | P | Vĩnh viễn |
| 3.7 | `emergency_action` | EN-01-12 | D | P | Vĩnh viễn |
| 3.8 | `change_request` | EN-01-13 | D | P | Vĩnh viễn |
| 3.9 | `data_demand` | EN-01-03 | A, B, D | P | Vĩnh viễn |
| 3.10 | `scope_ceiling` | EN-01-04 | B, D, E | P | Vĩnh viễn |
| 3.11 | `review_step` | EN-01-07 | B | P | Vĩnh viễn |
| 3.12 | `app_credential` | EN-01-08 (DD-05) | C | P | Vĩnh viễn (siêu dữ liệu, không bí mật) |
| 3.13 | `handover` | EN-01-09 | C | P | 3 năm |
| 3.14 | `sandbox_test` | EN-01-10 | C | P | 1 năm |
| 3.15 | `provisioning_saga` | Bảng kỹ thuật (SDD §4.6) | C | P | 12 tháng sau khi kết thúc (giả định) |
| 3.16 | `saga_step` | Bảng kỹ thuật | C | P | Theo saga cha |
| 3.17 | `enforcement_task` | Bảng kỹ thuật (SDD §4.10) | D | P | 12 tháng sau khi xong (giả định) |
| 3.18 | `access_review_cycle` | EN-01-14 | E | P | 5 năm |
| 3.19 | `review_confirmation` | EN-01-16 | E | P | 5 năm |
| 3.20 | `access_review_item` | EN-01-15 | E | P | 5 năm |
| 3.21 | `legacy_import_job` | EN-01-17 | G | P | 12 tháng (giả định); tệp gốc 7 ngày |
| 3.22 | `outbox` | DD-11 | D (mọi FR phát sự kiện) | P | 7 ngày |
| 3.23 | `inbox` | Bảng kỹ thuật (SDD §4.11) | A, F | P | 30 ngày |
| 3.24 | `notify_outbox` | Bảng kỹ thuật (SDD §8.2) | B, C, E, F | P | 30 ngày (giả định) |
| 3.25 | `idempotency_record` | Bảng kỹ thuật (ADR-041) | Mọi FR ghi | P | 24 giờ |
| 3.26 | `shedlock` | Bảng kỹ thuật | Tác vụ định kỳ | Không | Không áp dụng |

: Danh sách bảng của schema ph01_onboarding

Thực thể EN-01-01 đến EN-01-18 của FRS được phủ đủ, mỗi thực thể một bảng (18 bảng); cộng 3 bảng kỹ thuật của saga và cắt quyền (`provisioning_saga`, `saga_step`, `enforcement_task`) và 5 bảng hạ tầng (`outbox`, `inbox`, `notify_outbox`, `idempotency_record`, `shedlock`), thành 26 bảng. `state_history` ghi lịch sử cho cả HTTT, định danh và trần phạm vi. Tham số theo tenant (FR-01-049) không có bảng riêng vì nằm ở DD-14 do PH-18 sở hữu; thống kê (FR-01-051, Đợt 2) tính từ `member_system`, `state_history`, `review_step`.

<!-- gen:tables:start -->
### 3.1. `member_system`

::: dac-ta
**Mục đích.** EN-01-01 HTTT thành viên (DD-03), cũng là hồ sơ kết nạp ở giai đoạn đầu đời (FR-01-003). Mã bất biến, không dùng lại (BR-01-018); trạng thái chuyển theo bảng chuyển, bốn mắt khóa ở CSDL (BR-01-017).

**FR phục vụ.** FR-01-001…004, 009, 012, 018, 019, 024, 029…034, 037, 038, 050.

**Khóa chính.** (id).

**Duy nhất.** `uq_member_system_code` (tenant_id, code), `uq_member_system_legacy_ref` (tenant_id, legacy_ref).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_member_system_tenant`, `ck_member_system_code`, `ck_member_system_name`, `ck_member_system_level`, `ck_member_system_type`, `ck_member_system_roles`, `ck_member_system_status`, `ck_member_system_review_stage`, `ck_member_system_provision_stage`, `ck_member_system_enforcement`, `ck_member_system_revision`, `ck_member_system_security_ref`, `ck_member_system_base_urls`, `ck_member_system_ip_allowlist`, `ck_member_system_submitted`, `ck_member_system_approved`, `ck_member_system_activated`, `ck_member_system_four_eyes`, `ck_member_system_reason`, `ck_member_system_suspend_code`, `ck_member_system_suspended`, `ck_member_system_terminated`, `ck_member_system_deleted`, `ck_member_system_archived`, `ck_member_system_origin`.

**Chỉ mục.** `ix_member_system_status_org`, `ix_member_system_updated`, `ix_member_system_name_trgm`, `ix_member_system_review_due`, `ix_member_system_draft_stale`, `ix_member_system_enforcement`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_member_system_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger bảo vệ: `tg_member_system_guard`, `tg_member_system_no_delete` (bất biến, bốn mắt, chỉ thêm hoặc xóa có điều kiện).

**Ghi chú.** Ba trigger: `tg_member_system_guard` (mã bất biến, bảng chuyển trạng thái, điều kiện nộp, duyệt, kích hoạt, trạng thái cuối đóng băng), `tg_member_system_touch`, `tg_member_system_no_delete` (chỉ xóa cứng nháp chưa từng nộp đã xóa mềm quá 30 ngày). Thêm đối tượng phụ thuộc: `fn_assert_submittable`, `fn_assert_approvable`, `fn_assert_activatable`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `code` | `varchar(64)` | x |  | Mã HTTT, duy nhất trong tenant kể cả REJECTED, TERMINATED; bất biến (BR-01-018). |
| `name` | `varchar(255)` | x |  |  |
| `description` | `varchar(2000)` |  |  |  |
| `owner_org_id` | `varchar(64)` | x |  | Mã tổ chức chủ quản ở PH-20 (DD-02); không khóa ngoại vì khác schema, kiểm ở dịch vụ qua Ph20Port. |
| `operator_name` | `varchar(255)` |  |  |  |
| `security_level` | `varchar(2)` | x |  | Cấp độ ATTT được phê duyệt L1…L5; từ L3 trở lên phải có security_approval_ref khi nộp (FR-01-003). |
| `security_approval_ref` | `varchar(255)` |  |  |  |
| `system_type` | `varchar(10)` | x |  |  |
| `roles` | `varchar(10)[]` | x |  | Vai trò: CONSUMER, PROVIDER, PUBLISHER, SUBSCRIBER; hợp nhất Application của APIM và publisher, subscriber của Hub cũ. |
| `status` | `varchar(10)` | x | `'DRAFT'` |  |
| `review_stage` | `varchar(18)` |  |  | Giai đoạn khi SUBMITTED: WAITING_ASSIGN, IN_REVIEW, CONSULTING, WAITING_APPROVAL; NULL ở trạng thái khác. |
| `provision_stage` | `varchar(18)` |  |  | Giai đoạn khi APPROVED: PROVISIONING, AWAITING_KEY, SANDBOX_READY, PROVISION_FAILED; NULL ở trạng thái khác. |
| `enforcement` | `varchar(7)` | x | `'NONE'` | Tiến độ cắt quyền: NONE, PENDING (còn việc enforcement_task chưa xong), DONE (BR-01-023). |
| `revision_no` | `integer` | x | `0` | Số lần đã nộp; nộp lại tăng 1 (BR-01-032). 0 là chưa từng nộp, cho phép xóa nháp. |
| `return_reason` | `varchar(1000)` |  |  |  |
| `status_reason` | `varchar(1000)` |  |  |  |
| `suspend_reason_code` | `varchar(16)` |  |  |  |
| `base_urls` | `jsonb` | x | `'[]'` | Mảng địa chỉ backend, chỉ https (SEC-43). |
| `ip_allowlist` | `jsonb` | x | `'[]'` | Mảng CIDR được phép gọi; dữ liệu mức Hạn chế (HC). |
| `legacy_ref` | `varchar(255)` |  |  | Mã ở hệ cũ (ví dụ APIM-APP-0042, w1:ph01.application/{id}); chỉ mục duy nhất trong tenant để nhập lại không nhân đôi. |
| `origin_tenant_id` | `varchar(16)` |  |  | Tenant nguồn khi hồ sơ được chuyển vào tenant đích do sáp nhập tenant, giữ id gốc để truy vết (D03-10 §5.4); NULL với hồ sơ tạo tại chỗ. |
| `submitted_by` | `varchar(64)` |  |  |  |
| `submitted_at` | `timestamptz` |  |  |  |
| `approved_by` | `varchar(64)` |  |  |  |
| `approved_at` | `timestamptz` |  |  |  |
| `sandbox_passed_at` | `timestamptz` |  |  | Thời điểm kiểm thử SANDBOX đạt tiêu chí; điều kiện của APPROVED → ACTIVE (BR-01-008). |
| `activated_by` | `varchar(64)` |  |  |  |
| `activated_at` | `timestamptz` |  |  |  |
| `terminated_at` | `timestamptz` |  |  |  |
| `last_access_review_at` | `timestamptz` |  |  |  |
| `deleted_at` | `timestamptz` |  |  | Xóa mềm nháp chưa từng nộp; giữ 30 ngày để khôi phục rồi xóa cứng, giải phóng mã (FR-01-009). |
| `archived_at` | `timestamptz` |  |  | Ẩn khỏi danh sách mặc định với nháp đã từng nộp không hoạt động 90 ngày; không xóa (BR-01-011). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `member_system`

### 3.2. `technical_profile`

::: dac-ta
**Mục đích.** EN-01-02 Hồ sơ năng lực kỹ thuật, một dòng mỗi HTTT (FR-01-006, FR-01-013, FR-01-015). Cột có thể NULL khi còn nháp; điều kiện đủ kiểm ở fn_assert_submittable.

**FR phục vụ.** FR-01-006, 013, 015.

**Khóa chính.** (id).

**Duy nhất.** `uq_technical_profile_system` (tenant_id, member_system_id).

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system` xóa theo.

**Ràng buộc CHECK.** `ck_technical_profile_tenant`, `ck_technical_profile_kind`, `ck_technical_profile_spec`, `ck_technical_profile_protocols`, `ck_technical_profile_db`, `ck_technical_profile_cdc`, `ck_technical_profile_replacement`, `ck_technical_profile_criticality`, `ck_technical_profile_conn`, `ck_technical_profile_calls`, `ck_technical_profile_groups`, `ck_technical_profile_confirmed`, `ck_technical_profile_quota`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_technical_profile_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger bảo vệ: `tg_technical_profile_draft_delete` (bất biến, bốn mắt, chỉ thêm hoặc xóa có điều kiện).

**Ghi chú.** Cột có thể NULL khi còn nháp; đủ điều kiện nộp kiểm ở `fn_assert_submittable`. `confirmed_group` là điều kiện phê duyệt (`fn_assert_approvable`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `system_kind` | `varchar(14)` |  |  |  |
| `technology` | `varchar(255)` |  |  |  |
| `has_api` | `boolean` |  |  | Yếu tố chính xác định nhóm HTTT; true thì cần api_spec_kind, false thì cần db_type; kiểm khi nộp ở fn_assert_submittable. |
| `api_spec_kind` | `varchar(8)` |  |  |  |
| `protocols` | `varchar(8)[]` | x | `'{}'` |  |
| `db_type` | `varchar(10)` |  |  |  |
| `cdc_log_enabled` | `varchar(7)` |  |  |  |
| `under_maintenance` | `boolean` |  |  |  |
| `replacement_planned` | `boolean` |  |  |  |
| `replacement_date` | `date` |  |  |  |
| `criticality` | `varchar(8)` | x | `'NORMAL'` | CRITICAL: HTTT thiết yếu, bắt buộc xác nhận tác động khi tạm ngừng, chấm dứt (ERR-01-034). |
| `max_concurrent_connections` | `integer` | x | `10` | Dùng cấu hình nhóm kết nối ở PH-05. |
| `expected_daily_calls` | `bigint` | x | `0` |  |
| `operating_hours` | `varchar(255)` |  |  |  |
| `proposed_group` | `smallint` |  |  | Nhóm HTTT 1…4 do hệ thống tính từ hồ sơ; người dùng không sửa. |
| `confirmed_group` | `smallint` |  |  | Nhóm do người thẩm định kỹ thuật xác nhận; điều kiện của phê duyệt (ERR-01-019). |
| `confirmed_by` | `varchar(64)` |  |  |  |
| `confirmed_at` | `timestamptz` |  |  |  |
| `quota_impact` | `varchar(10)` | x | `'UNASSESSED'` | Kết quả QuotaImpactEvaluator theo quotaImpact.mediumPct, highPct (FR-01-015); UNASSESSED khi PH-14 không khả dụng. |
| `quota_impact_note` | `varchar(1000)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `technical_profile`

### 3.3. `contact`

::: dac-ta
**Mục đích.** EN-01-05 Đầu mối liên hệ (DD-04), dữ liệu cá nhân mức Hạn chế (FR-01-008, BR-01-027). Đầu mối SECURITY luôn không công khai. Không đưa họ tên, thư, điện thoại vào sự kiện (EVT-01-13).

**FR phục vụ.** FR-01-008, 022, 045, 046, 047.

**Khóa chính.** (id).

**Duy nhất.** `uq_contact_active_email` (tenant_id, member_system_id, contact_type, lower(email)).

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system` xóa theo, (replaced_by_id, tenant_id) → `contact`.

**Ràng buộc CHECK.** `ck_contact_tenant`, `ck_contact_type`, `ck_contact_email`, `ck_contact_phone`, `ck_contact_security_private`, `ck_contact_status`, `ck_contact_inactive`.

**Chỉ mục.** `ix_contact_system`, `ix_contact_user`, `ix_contact_search_trgm`, `ix_contact_stale`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_contact_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger bảo vệ: `tg_contact_draft_delete` (bất biến, bốn mắt, chỉ thêm hoặc xóa có điều kiện).

**Ghi chú.** Dữ liệu cá nhân mức Hạn chế (HC): vai trò chỉ đọc `ph01_readonly` không đọc họ tên, chức vụ, thư, điện thoại, tài khoản, `search_text`; không đưa vào sự kiện (EVT-01-13). Cột sinh `search_text` bỏ dấu để tìm danh bạ.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `contact_type` | `varchar(9)` | x |  |  |
| `full_name` | `varchar(255)` | x |  |  |
| `job_title` | `varchar(255)` | x |  | Chức vụ (trường position của FRS; tránh trùng từ khóa POSITION). |
| `email` | `varchar(255)` | x |  |  |
| `phone` | `varchar(16)` |  |  |  |
| `user_account_id` | `varchar(64)` |  |  | Tài khoản Keycloak ở PH-12 (DD-06) nếu đầu mối có tài khoản; điều kiện nhận bàn giao (FR-01-022); không khóa ngoại. |
| `is_public` | `boolean` | x | `true` | Công khai trong danh bạ phạm vi tenant; mặc định true với BUSINESS, TECHNICAL. |
| `status` | `varchar(8)` | x | `'ACTIVE'` |  |
| `inactive_reason` | `varchar(16)` |  |  | Lý do không hoạt động; MAIL_BOUNCED theo BR-01-028, ACCOUNT_DISABLED, ORG_CHANGED theo sự kiện của PH-12. |
| `replaced_by_id` | `uuid` |  |  |  |
| `last_confirmed_at` | `timestamptz` |  |  |  |
| `search_text` | `text` |  | cột sinh | Cột sinh: họ tên, chức vụ, thư điện tử bỏ dấu, hạ chữ thường; chỉ mục GIN pg_trgm cho tra danh bạ (FR-01-045). Chứa dữ liệu cá nhân, cùng mức bảo vệ với cột nguồn (Q01-29). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `contact`

### 3.4. `attachment`

::: dac-ta
**Mục đích.** EN-01-06 Tài liệu đính kèm (DD-12), chỉ siêu dữ liệu; nội dung ở bucket dh-{tenant}-onboarding, mã hóa SSE-C (FR-01-005, NFR-01-011). Sau nộp không xóa (BR-01-011).

**FR phục vụ.** FR-01-005, 007, 011.

**Khóa chính.** (id).

**Duy nhất.** `uq_attachment_object_key` (tenant_id, object_key).

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system` xóa theo.

**Ràng buộc CHECK.** `ck_attachment_tenant`, `ck_attachment_kind`, `ck_attachment_size`, `ck_attachment_sha`, `ck_attachment_key`, `ck_attachment_scan`, `ck_attachment_scanned`, `ck_attachment_class`.

**Chỉ mục.** `ix_attachment_system`, `ix_attachment_pending`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_attachment_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger bảo vệ: `tg_attachment_draft_delete` (bất biến, bốn mắt, chỉ thêm hoặc xóa có điều kiện).

**Ghi chú.** Chỉ siêu dữ liệu; nội dung ở bucket `dh-{tenant}-onboarding` (SSE-C). Mỗi tệp một khóa đối tượng duy nhất trong tenant.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `kind` | `varchar(18)` | x |  |  |
| `title` | `varchar(255)` |  |  |  |
| `file_name` | `varchar(255)` | x |  |  |
| `content_type` | `varchar(128)` | x |  |  |
| `size_bytes` | `bigint` | x |  | Trần cứng 50 MB theo SEC-45; trần mềm theo tham số attachment.maxSizeMb (mặc định 20 MB) kiểm ở dịch vụ. |
| `object_key` | `varchar(512)` | x |  | Khóa đối tượng {systemCode}/{attachmentId}; khóa tạm staging/ không lưu ở bảng này. |
| `sha256` | `char(64)` | x |  |  |
| `scan_status` | `varchar(8)` | x | `'PENDING'` | PENDING (đang quét hoặc quá hạn quét đồng bộ) hoặc CLEAN; tệp nhiễm mã độc bị xóa và không có dòng (ERR-01-014). |
| `scanned_at` | `timestamptz` |  |  |  |
| `classification` | `varchar(10)` | x | `'INTERNAL'` |  |
| `uploaded_by` | `varchar(64)` | x |  |  |
| `deleted_at` | `timestamptz` |  |  | Xóa mềm cùng nháp chưa từng nộp (FR-01-009). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `attachment`

### 3.5. `template`

::: dac-ta
**Mục đích.** EN-01-18 Mẫu văn bản đề nghị và hướng dẫn kết nối (FR-01-010). Mẫu mặc định ở tenant COMMON (chỉ phiên PLATFORM ghi); tenant đặt mẫu riêng thì mẫu tenant được dùng trước.

**FR phục vụ.** FR-01-010.

**Khóa chính.** (id).

**Duy nhất.** `uq_template_version` (tenant_id, template_code, content_version), `uq_template_published` (tenant_id, template_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_template_tenant`, `ck_template_code`, `ck_template_status`, `ck_template_published`, `ck_template_sha`, `ck_template_guide`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu S (FORCE, dùng chung): đọc dòng của tenant phiên và `COMMON`; ghi dòng `COMMON` chỉ khi phiên là `PLATFORM`; bốn chính sách `rls_template_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Mẫu S (dùng chung): tỉnh đọc thêm mẫu `COMMON`, chỉ phiên `PLATFORM` ghi `COMMON`. Mẫu của tenant được dùng trước mẫu mặc định.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `template_code` | `varchar(64)` | x |  |  |
| `title` | `varchar(255)` | x |  |  |
| `content_version` | `varchar(16)` | x |  | Phiên bản nội dung mẫu, ví dụ 1.0 (khác cột version là khóa lạc quan). |
| `status` | `varchar(9)` | x | `'DRAFT'` |  |
| `file_name` | `varchar(255)` | x |  |  |
| `content_type` | `varchar(128)` | x |  |  |
| `file_ref` | `varchar(512)` | x |  | Khóa tệp mẫu ở kho đối tượng (bucket nền tảng cho COMMON, bucket tenant cho mẫu riêng); tải qua liên kết ký ngắn hạn. |
| `file_sha256` | `char(64)` | x |  |  |
| `guide_md` | `text` |  |  |  |
| `published_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `template`

### 3.6. `state_history`

::: dac-ta
**Mục đích.** EN-01-11 Lịch sử trạng thái của HTTT, định danh và trần phạm vi, chỉ thêm, giữ vĩnh viễn (BR-01-011, BR-01-031, NFR-01-022). Ghi cùng giao dịch với thay đổi trạng thái.

**FR phục vụ.** FR-01-012, 017, 018, 024, 029…032, 037.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system` xóa theo.

**Ràng buộc CHECK.** `ck_state_history_tenant`, `ck_state_history_subject`, `ck_state_history_change`, `ck_state_history_trace`.

**Chỉ mục.** `ix_state_history_system`, `ix_state_history_subject`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_state_history_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger bảo vệ: `tg_state_history_ro` (bất biến, bốn mắt, chỉ thêm hoặc xóa có điều kiện).

**Ghi chú.** Chỉ thêm: vai trò ứng dụng không có quyền UPDATE, DELETE; trigger `tg_state_history_ro` chặn cả chủ bảng, chỉ cho xóa theo tầng khi hồ sơ cha đã bị xóa cứng. Ghi cùng giao dịch với đổi trạng thái (BR-01-031).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `subject_type` | `varchar(10)` | x | `'MEMBER'` | MEMBER (HTTT), CREDENTIAL (định danh), CEILING (trần phạm vi); subject_id là id của đối tượng. |
| `subject_id` | `uuid` | x |  |  |
| `from_status` | `varchar(20)` |  |  |  |
| `to_status` | `varchar(20)` | x |  |  |
| `revision_no` | `integer` | x | `0` |  |
| `reason` | `varchar(1000)` |  |  |  |
| `actor` | `varchar(64)` | x |  |  |
| `emergency` | `boolean` | x | `false` | true khi chuyển do thao tác khẩn của Cán bộ ATTT (BR-01-010). |
| `occurred_at` | `timestamptz` | x | `now()` |  |
| `trace_id` | `char(32)` | x |  |  |

: Cột của bảng `state_history`

### 3.7. `emergency_action`

::: dac-ta
**Mục đích.** EN-01-12 Thao tác khẩn của Cán bộ ATTT: tạm ngừng hoặc thu hồi ngay, TA xác nhận bổ sung trong emergency.confirmHours; quá hạn thì OVERDUE, không tự hoàn tác (FR-01-032, BR-01-010).

**FR phục vụ.** FR-01-030, 032.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system`.

**Ràng buộc CHECK.** `ck_emergency_action_tenant`, `ck_emergency_action_type`, `ck_emergency_action_reason`, `ck_emergency_action_status`, `ck_emergency_action_deadline`, `ck_emergency_action_confirmed`, `ck_emergency_action_four_eyes`, `ck_emergency_action_overdue`, `ck_emergency_action_consent`.

**Chỉ mục.** `ix_emergency_action_system`, `ix_emergency_action_due`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_emergency_action_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Quá hạn xác nhận chỉ đánh dấu `OVERDUE`, không tự hoàn tác (BR-01-010). Người xác nhận khác người thực hiện (BR-01-017).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `action_type` | `varchar(8)` | x |  |  |
| `reason` | `varchar(1000)` | x |  |  |
| `credential_ids` | `uuid[]` | x | `'{}'` | Định danh bị thu hồi khi action_type = REVOKE; rỗng nghĩa là mọi định danh của HTTT. |
| `performed_by` | `varchar(64)` | x |  |  |
| `performed_at` | `timestamptz` | x | `now()` |  |
| `confirm_by` | `timestamptz` | x |  |  |
| `confirmed_by` | `varchar(64)` |  |  | Người xác nhận bổ sung; phải khác performed_by (BR-01-017, ERR-01-036). |
| `confirmed_at` | `timestamptz` |  |  |  |
| `status` | `varchar(15)` | x | `'PENDING_CONFIRM'` |  |
| `overdue_at` | `timestamptz` |  |  |  |
| `resume_consent_by` | `varchar(64)` |  |  | SO đồng ý khôi phục HTTT bị tạm ngừng vì nghi lộ bí mật; điều kiện của FR-01-030 (BR-01-010). |
| `resume_consent_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `emergency_action`

### 3.8. `change_request`

::: dac-ta
**Mục đích.** EN-01-13 Yêu cầu thay đổi hồ sơ HTTT đã kết nạp theo mức duyệt: TECHNICAL, OWNER_CHANGE, FULL (mở rộng phạm vi), TERMINATE (chấm dứt). Mỗi HTTT tối đa một yêu cầu PENDING (FR-01-034, 035, 031; BR-01-012, 025, 029).

**FR phục vụ.** FR-01-031, 033…035.

**Khóa chính.** (id).

**Duy nhất.** `uq_change_request_pending` (tenant_id, member_system_id).

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system`.

**Ràng buộc CHECK.** `ck_change_request_tenant`, `ck_change_request_class`, `ck_change_request_reason`, `ck_change_request_diff`, `ck_change_request_status`, `ck_change_request_decided`, `ck_change_request_four_eyes`, `ck_change_request_owner`, `ck_change_request_owner_confirm`, `ck_change_request_terminate_impact`.

**Chỉ mục.** `ix_change_request_system`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_change_request_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Mỗi HTTT tối đa một yêu cầu `PENDING` (chỉ mục duy nhất từng phần). Duyệt chấm dứt bắt buộc có báo cáo tác động (FR-01-033).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `change_class` | `varchar(12)` | x |  |  |
| `reason` | `varchar(1000)` | x |  |  |
| `diff` | `jsonb` | x | `'{}'` | Phần thay đổi dạng JSON đối tượng; áp vào hồ sơ khi duyệt, trong một giao dịch (EVT-01-04). |
| `new_owner_org_id` | `varchar(64)` |  |  |  |
| `owner_confirmed_by` | `varchar(64)` |  |  | Người của tổ chức mới xác nhận nhận chủ quản; điều kiện duyệt OWNER_CHANGE (BR-01-029). |
| `owner_confirmed_at` | `timestamptz` |  |  |  |
| `impact_report` | `jsonb` |  |  | Báo cáo phân tích tác động (FR-01-033) lưu kèm để chứng minh người quyết định đã thấy tác động; bắt buộc khi duyệt TERMINATE. |
| `impact_confirmed` | `boolean` | x | `false` |  |
| `status` | `varchar(9)` | x | `'PENDING'` |  |
| `requested_by` | `varchar(64)` | x |  |  |
| `requested_at` | `timestamptz` | x | `now()` |  |
| `decided_by` | `varchar(64)` |  |  | Người duyệt; phải khác người đề nghị (BR-01-017). |
| `decided_at` | `timestamptz` |  |  |  |
| `decision_note` | `varchar(1000)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `change_request`

### 3.9. `data_demand`

::: dac-ta
**Mục đích.** EN-01-03 Nhu cầu khai thác: mỗi dòng một loại dữ liệu và chiều CONSUME hoặc PROVIDE kèm căn cứ pháp lý và kết luận thẩm định riêng; quyền theo dòng, không theo hồ sơ (FR-01-007, FR-01-014, FR-01-035; BR-01-001, 003, 004).

**FR phục vụ.** FR-01-007, 014, 035.

**Khóa chính.** (id).

**Duy nhất.** `uq_data_demand_type` (tenant_id, member_system_id, direction, data_type, coalesce(change_request_id, '00000000-0000-0000-0000-000000000000'::uuid)).

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system` xóa theo, (change_request_id, tenant_id) → `change_request`, (legal_attachment_id, tenant_id) → `attachment`.

**Ràng buộc CHECK.** `ck_data_demand_tenant`, `ck_data_demand_origin`, `ck_data_demand_direction`, `ck_data_demand_type`, `ck_data_demand_class`, `ck_data_demand_legal_issued`, `ck_data_demand_legal_valid`, `ck_data_demand_verdict`, `ck_data_demand_verdict_who`, `ck_data_demand_scope`, `ck_data_demand_opinion`.

**Chỉ mục.** `ix_data_demand_system`, `ix_data_demand_pending`, `ix_data_demand_attachment`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_data_demand_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger bảo vệ: `tg_data_demand_draft_delete` (bất biến, bốn mắt, chỉ thêm hoặc xóa có điều kiện).

**Ghi chú.** Quyền theo dòng, không theo hồ sơ. Chỉ mục duy nhất cho phép nhiều dòng cùng loại dữ liệu khi thuộc các yêu cầu mở rộng khác nhau. Xóa dòng chỉ khi hồ sơ còn nháp chưa từng nộp.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `origin` | `varchar(10)` | x | `'ONBOARDING'` | ONBOARDING (khi kết nạp) hoặc EXPANSION (đề nghị mở rộng trần sau kết nạp, kèm change_request_id loại FULL). |
| `change_request_id` | `uuid` |  |  |  |
| `direction` | `varchar(7)` | x |  |  |
| `data_type` | `varchar(64)` | x |  | Mã loại dữ liệu trong danh mục của tenant (PH-07, Q01-16); dữ liệu thuộc danh mục bí mật nhà nước bị chặn ở dịch vụ trước khi ghi (BR-01-004), mức phân loại không có giá trị bí mật nhà nước. |
| `scope_requested` | `varchar(200)` | x |  |  |
| `classification` | `varchar(10)` | x |  |  |
| `purpose` | `varchar(500)` | x |  |  |
| `legal_doc_no` | `varchar(120)` |  |  | Số, ký hiệu văn bản căn cứ; bắt buộc đủ bốn thông tin căn cứ cho dòng CONSUME khi nộp (BR-01-001, kiểm ở fn_assert_submittable). |
| `legal_issued_on` | `date` |  |  |  |
| `legal_issuer` | `varchar(255)` |  |  |  |
| `legal_valid_until` | `date` |  |  | Hiệu lực căn cứ đến ngày; NULL là không thời hạn; LegalValidityChecker dùng (FR-01-043, BR-01-015). |
| `legal_attachment_id` | `uuid` |  |  | Tài liệu loại LEGAL_BASIS cùng hồ sơ (khóa ngoại kèm tenant). |
| `verdict` | `varchar(8)` |  |  | Kết luận mục: APPROVED, NARROWED (kèm scope_approved), REJECTED (kèm ý kiến); NARROWED phải là tập con của scope_requested, kiểm ở dịch vụ (ERR-01-018, 019, Q01-50). |
| `scope_approved` | `varchar(200)` |  |  |  |
| `opinion` | `varchar(2000)` |  |  |  |
| `reviewer_id` | `varchar(64)` |  |  |  |
| `reviewed_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `data_demand`

### 3.10. `scope_ceiling`

::: dac-ta
**Mục đích.** EN-01-04 Trần phạm vi: giới hạn trên cho đăng ký sử dụng ở PH-02 và scope của định danh; sinh từ nhu cầu được duyệt, chỉ thu hẹp hoặc đóng (FR-01-018, 035, 042, 043; BR-01-003, 012, 015). Thay PHAM_VI_DUOC_CAP của hệ cũ.

**FR phục vụ.** FR-01-018, 035, 042, 043.

**Khóa chính.** (id).

**Duy nhất.** `uq_scope_ceiling_open` (tenant_id, member_system_id, direction, data_type).

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system`, (source_demand_id, tenant_id) → `data_demand`, (legal_attachment_id, tenant_id) → `attachment`.

**Ràng buộc CHECK.** `ck_scope_ceiling_tenant`, `ck_scope_ceiling_direction`, `ck_scope_ceiling_class`, `ck_scope_ceiling_legal`, `ck_scope_ceiling_status`, `ck_scope_ceiling_suspend`, `ck_scope_ceiling_revoked`.

**Chỉ mục.** `ix_scope_ceiling_system`, `ix_scope_ceiling_legal`, `ix_scope_ceiling_unused`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_scope_ceiling_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger bảo vệ: `tg_scope_ceiling_guard` (bất biến, bốn mắt, chỉ thêm hoặc xóa có điều kiện).

**Ghi chú.** Trần sinh đúng từ nhu cầu được duyệt (`tg_scope_ceiling_guard`); chỉ thu hẹp hoặc đóng. Việc kiểm "tập con" của phạm vi dạng văn bản ở dịch vụ (Q01-50). Giữ vĩnh viễn, không cho vai trò ứng dụng xóa.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `source_demand_id` | `uuid` |  |  |  |
| `direction` | `varchar(7)` | x |  |  |
| `data_type` | `varchar(64)` | x |  |  |
| `scope_approved` | `varchar(200)` | x |  | Phạm vi được duyệt (văn bản ≤ 200 ký tự); bằng scope_approved của nhu cầu nguồn khi tạo (tg_scope_ceiling_guard); thu hẹp là sửa cột này ở dịch vụ (Q01-50). |
| `classification` | `varchar(10)` | x |  |  |
| `legal_doc_no` | `varchar(120)` |  |  |  |
| `legal_issued_on` | `date` |  |  |  |
| `legal_issuer` | `varchar(255)` |  |  |  |
| `legal_valid_until` | `date` |  |  |  |
| `legal_attachment_id` | `uuid` |  |  |  |
| `status` | `varchar(9)` | x | `'ACTIVE'` |  |
| `suspend_reason` | `varchar(16)` |  |  | LEGAL_EXPIRED (căn cứ hết hiệu lực, BR-01-015), ACCESS_REVIEW, MEMBER_SUSPENDED, MANUAL; khác NULL khi và chỉ khi SUSPENDED. |
| `revoked_at` | `timestamptz` |  |  |  |
| `revoked_reason` | `varchar(1000)` |  |  |  |
| `in_use` | `boolean` | x | `false` | Có đăng ký sử dụng đang hoạt động ở PH-02; do tổng hợp mức dùng cập nhật (FR-01-040). |
| `last_used_at` | `timestamptz` |  |  | Lần dùng gần nhất theo PH-13; căn cứ đề xuất thu hồi khi không dùng quá accessReview.unusedDays. |
| `usage_checked_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `scope_ceiling`

### 3.11. `review_step`

::: dac-ta
**Mục đích.** EN-01-07 Bước thẩm định song song TECHNICAL, LEGAL, SECURITY mỗi vòng nộp; kết luận một lần, giữ vĩnh viễn (FR-01-013, 014, 016, 017; BR-01-017, 032).

**FR phục vụ.** FR-01-013, 014, 016…018.

**Khóa chính.** (id).

**Duy nhất.** `uq_review_step_round` (tenant_id, member_system_id, revision_no, step_type).

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system`, (carried_from_id, tenant_id) → `review_step`.

**Ràng buộc CHECK.** `ck_review_step_tenant`, `ck_review_step_revision`, `ck_review_step_type`, `ck_review_step_status`, `ck_review_step_result`, `ck_review_step_fail_opinion`, `ck_review_step_finished`, `ck_review_step_finisher`, `ck_review_step_carried`, `ck_review_step_assign`, `ck_review_step_paused`, `ck_review_step_due`, `ck_review_step_hash`.

**Chỉ mục.** `ix_review_step_assignee`, `ix_review_step_due`, `ix_review_step_system`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_review_step_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger bảo vệ: `tg_review_step_guard` (bất biến, bốn mắt, chỉ thêm hoặc xóa có điều kiện).

**Ghi chú.** Bốn mắt ở CSDL: người lập, người nộp không được phân công (`tg_review_step_guard`); người kết luận là người được phân công; bước đã xong bất biến. Giữ vĩnh viễn.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `revision_no` | `integer` | x |  | Vòng nộp (member_system.revision_no lúc tạo bước); nộp lại tạo ba bước mới, bước có input_hash trùng được sao chép kết luận (CARRIED). |
| `step_type` | `varchar(9)` | x |  |  |
| `status` | `varchar(9)` | x | `'OPEN'` | OPEN (chờ phân công hoặc đang làm), CONSULTING (tham vấn, đồng hồ dừng), DONE, RETURNED (trả bổ sung), WITHDRAWN (đơn vị rút hồ sơ), CARRIED (sao chép kết luận từ vòng trước). |
| `assignee_id` | `varchar(64)` |  |  | Người được phân công (NULL là chờ phân công); khác người lập và người nộp hồ sơ (tg_review_step_guard). |
| `assigned_by` | `varchar(64)` |  |  |  |
| `assigned_at` | `timestamptz` |  |  |  |
| `result` | `varchar(4)` |  |  |  |
| `opinion` | `varchar(4000)` |  |  |  |
| `input_hash` | `char(64)` |  |  | SHA-256 của lát dữ liệu liên quan tới bước, để quyết định sao chép kết luận khi nộp lại (BR-01-032). |
| `carried_from_id` | `uuid` |  |  |  |
| `started_at` | `timestamptz` | x | `now()` |  |
| `due_at` | `timestamptz` | x |  |  |
| `paused_millis` | `bigint` | x | `0` | Thời gian đồng hồ hạn bị dừng cộng dồn (tham vấn, chờ đơn vị bổ sung); dueAt được dời tương ứng. |
| `paused_at` | `timestamptz` |  |  |  |
| `consulting_with` | `varchar(64)` |  |  |  |
| `consult_question` | `varchar(2000)` |  |  |  |
| `escalated_at` | `timestamptz` |  |  |  |
| `finished_at` | `timestamptz` |  |  |  |
| `finished_by` | `varchar(64)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `review_step`

### 3.12. `app_credential`

::: dac-ta
**Mục đích.** EN-01-08 Định danh ứng dụng (DD-05) theo môi trường SANDBOX hoặc PRODUCTION. KHÔNG lưu bí mật, khóa riêng (BR-01-007): chỉ secret_ref (đường dẫn OpenBao), số phiên bản, dấu vân tay chứng thư (FR-01-020…028).

**FR phục vụ.** FR-01-020…028, 036.

**Khóa chính.** (id).

**Duy nhất.** `uq_app_credential_client` (tenant_id, client_id), `uq_app_credential_live` (tenant_id, member_system_id, environment).

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system`.

**Ràng buộc CHECK.** `ck_app_credential_tenant`, `ck_app_credential_env`, `ck_app_credential_method`, `ck_app_credential_client_id`, `ck_app_credential_secret_ref`, `ck_app_credential_secret_method`, `ck_app_credential_secret_live`, `ck_app_credential_secret_ttl`, `ck_app_credential_cert`, `ck_app_credential_jwks`, `ck_app_credential_status`, `ck_app_credential_expiry`, `ck_app_credential_rotation`, `ck_app_credential_revoked`, `ck_app_credential_reversible`, `ck_app_credential_scopes_new`.

**Chỉ mục.** `ix_app_credential_system`, `ix_app_credential_expiry`, `ix_app_credential_secret_expiry`, `ix_app_credential_rotation`, `ix_app_credential_inactive`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_app_credential_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger bảo vệ: `tg_app_credential_guard` (bất biến, bốn mắt, chỉ thêm hoặc xóa có điều kiện).

**Ghi chú.** KHÔNG có cột bí mật; `secret_ref` bị ràng buộc khớp mẫu đường dẫn OpenBao của đúng tenant và môi trường nên không thể ghi giá trị bí mật vào. Cấp PRODUCTION chỉ khi `sandbox_passed_at` có giá trị.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `environment` | `varchar(10)` | x |  |  |
| `auth_method` | `varchar(15)` | x |  |  |
| `client_id` | `varchar(128)` | x |  | Client ID Keycloak, tên {tenant}-{systemCode}-sbx hoặc -prd chữ thường; duy nhất trong tenant (realm), phải mở đầu bằng mã tenant (SEC-82). |
| `secret_ref` | `varchar(255)` |  |  | Đường dẫn OpenBao kv/dh/{tenant}/clients/{systemCode}/{env}; ràng buộc khớp mẫu nên không thể ghi giá trị bí mật vào cột này (BR-01-007). |
| `secret_version` | `integer` |  |  | Số phiên bản bí mật hiện hành ở OpenBao; previous_secret_version là phiên bản cũ trong thời gian chuyển tiếp xoay vòng (BR-01-021). |
| `previous_secret_version` | `integer` |  |  |  |
| `cert_fingerprint` | `char(64)` |  |  | SHA-256 chứng thư máy khách (hex thường), chỉ với MTLS. |
| `jwks_ref` | `varchar(255)` |  |  | Tham chiếu tập khóa công khai đã đăng ký ở PH-12, chỉ với PRIVATE_KEY_JWT. |
| `granted_scopes` | `varchar(100)[]` | x | `'{}'` | Scope dữ liệu đã gán; rỗng khi mới cấp (BR-01-003), nằm trong trần phạm vi và đăng ký đã duyệt ở PH-02 (kiểm ở dịch vụ). |
| `status` | `varchar(8)` | x | `'PENDING'` | PENDING (trạng thái kỹ thuật của bước RECORD trong saga, thêm so với D02-07), ACTIVE, ROTATING, REVOKED, EXPIRED. |
| `saga_id` | `uuid` |  |  | Saga cấp định danh (provisioning_saga.id) tạo ra bản ghi; không khóa ngoại để tránh vòng phụ thuộc. |
| `issued_at` | `timestamptz` | x | `now()` |  |
| `expires_at` | `timestamptz` | x |  | Hạn định danh tối đa 12 tháng từ lúc cấp (DD-05, BR-01-020); secret_expires_at tối đa 180 ngày từ secret_issued_at (SEC-24). |
| `secret_issued_at` | `timestamptz` |  |  |  |
| `secret_expires_at` | `timestamptz` |  |  |  |
| `last_used_at` | `timestamptz` |  |  |  |
| `rotation_started_at` | `timestamptz` |  |  |  |
| `rotation_ends_at` | `timestamptz` |  |  |  |
| `revoked_at` | `timestamptz` |  |  |  |
| `revoked_by` | `varchar(64)` |  |  |  |
| `revoked_reason` | `varchar(1000)` |  |  |  |
| `revoke_reversible` | `boolean` | x | `false` | true khi bị vô hiệu vì không hoạt động 90 ngày và bật lại được (BR-01-022); các lý do khác không hoàn tác. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `app_credential`

### 3.13. `handover`

::: dac-ta
**Mục đích.** EN-01-09 Bàn giao thông tin xác thực một lần qua bọc phản hồi OpenBao (FR-01-022; BR-01-005, 006). Không lưu liên kết gốc: chỉ SHA-256 của liên kết, accessor và mã bọc đã mã hóa bằng khóa transit dh-{tenant}-handover. Giữ 3 năm.

**FR phục vụ.** FR-01-022, 025.

**Khóa chính.** (id).

**Duy nhất.** `uq_handover_link` (link_hash), `uq_handover_pending` (tenant_id, credential_id).

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system`, (credential_id, tenant_id) → `app_credential`, (recipient_contact_id, tenant_id) → `contact`.

**Ràng buộc CHECK.** `ck_handover_tenant`, `ck_handover_hash`, `ck_handover_status`, `ck_handover_ttl`, `ck_handover_attempts`, `ck_handover_cancel`, `ck_handover_opened`, `ck_handover_sealed`, `ck_handover_wrap_pair`.

**Chỉ mục.** `ix_handover_due`, `ix_handover_opening`, `ix_handover_system`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_handover_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger bảo vệ: `tg_handover_guard` (bất biến, bốn mắt, chỉ thêm hoặc xóa có điều kiện).

**Ghi chú.** Không lưu liên kết gốc: chỉ SHA-256 (`link_hash`), accessor và mã bọc đã mã hóa bằng transit, mã bọc bị đặt NULL khi rời `PENDING`, `OPENING`. Trạng thái `OPENING` chặn hai người mở đồng thời. Giữ 3 năm.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `credential_id` | `uuid` | x |  |  |
| `recipient_contact_id` | `uuid` | x |  |  |
| `link_hash` | `char(64)` | x |  | SHA-256 (hex) của mã liên kết 256 bit; duy nhất toàn bảng; không có cột chứa liên kết gốc (NFR-01-010). |
| `wrap_accessor` | `varchar(128)` |  |  |  |
| `wrap_token_sealed` | `text` |  |  | Mã bọc OpenBao mã hóa bằng transit (AAD gồm tenant_id và id), chỉ tồn tại khi PENDING hoặc OPENING, đặt NULL ngay khi rời hai trạng thái đó (ck_handover_sealed). Cột thêm so với EN-01-09 (Q01-21). |
| `status` | `varchar(9)` | x | `'PENDING'` | PENDING, OPENING (trạng thái kỹ thuật chiếm chỗ bằng UPDATE có điều kiện, chặn hai người mở đồng thời), OPENED, EXPIRED, CANCELLED. |
| `cancel_reason` | `varchar(16)` |  |  | REPLACED (tạo lại), ROTATED, REVOKED, SUSPENDED, LOCKED, OPEN_INTERRUPTED (tiến trình chết lúc mở, phải xoay vòng), LINK_LEAKED (mã bọc đã bị dùng), OTHER. |
| `failed_attempts` | `smallint` | x | `0` | Số lần mở sai người; chạm handover.maxFailedOpens (mặc định 5, trần 10) thì CANCELLED với LOCKED (ERR-01-026). |
| `expires_at` | `timestamptz` | x |  | Hạn liên kết, mặc định created_at cộng handover.ttlHours (24 giờ); trần cứng 72 giờ (NFR-01-010). |
| `opened_at` | `timestamptz` |  |  |  |
| `opened_by` | `varchar(64)` |  |  |  |
| `opened_ip` | `inet` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `handover`

### 3.14. `sandbox_test`

::: dac-ta
**Mục đích.** EN-01-10 Kết quả kiểm thử SANDBOX nhận từ PH-03, PH-13, chỉ thêm; giữ 1 năm rồi dọn theo lô (FR-01-023, NFR-01-022). Ước 1 triệu dòng mỗi năm ở tỉnh vừa, chưa phân vùng (SDD §11.3).

**FR phục vụ.** FR-01-023, 024.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system`, (credential_id, tenant_id) → `app_credential`.

**Ràng buộc CHECK.** `ck_sandbox_test_tenant`, `ck_sandbox_test_source`, `ck_sandbox_test_counts`, `ck_sandbox_test_error`.

**Chỉ mục.** `ix_sandbox_test_system`, `ix_sandbox_test_retention`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_sandbox_test_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Chỉ thêm, dọn theo lô sau 1 năm; chưa phân vùng ở tỉnh vừa (khoảng 1 triệu dòng mỗi năm), phân vùng tháng khi vượt khoảng 10 triệu dòng (SDD §11.3).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `credential_id` | `uuid` |  |  |  |
| `source` | `varchar(8)` | x |  |  |
| `observed_at` | `timestamptz` | x |  |  |
| `auth_ok` | `boolean` | x |  |  |
| `api_ok` | `boolean` | x |  |  |
| `call_count` | `integer` | x | `0` |  |
| `success_count` | `integer` | x | `0` | Số lượt gọi API thành công trong khoảng quan sát; so với sandbox.requiredSuccessfulCalls để quyết định đạt (FR-01-023). |
| `error_detail` | `varchar(2000)` |  |  | Chi tiết lỗi đã che; ràng buộc chặn từ khóa bí mật như lớp phòng thủ thứ hai (NFR-01-009). |
| `received_at` | `timestamptz` | x | `now()` |  |

: Cột của bảng `sandbox_test`

### 3.15. `provisioning_saga`

::: dac-ta
**Mục đích.** Saga cấp định danh bền trong CSDL (FR-01-020, 024; NFR-01-004): bộ chạy lấy việc bằng FOR UPDATE SKIP LOCKED, id là sagaId bất biến dùng làm khóa lũy đẳng cho PH-12, PH-03. Chèn cùng giao dịch với phê duyệt. Mỗi (HTTT, môi trường) tối đa một saga đang chạy.

**FR phục vụ.** FR-01-020, 024.

**Khóa chính.** (id).

**Duy nhất.** `uq_provisioning_saga_running` (tenant_id, member_system_id, environment)
  WHERE state IN ('PENDING', 'RUNNING', 'WAITING_RETRY', 'COMPENSATING').

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system`, (credential_id, tenant_id) → `app_credential`.

**Ràng buộc CHECK.** `ck_provisioning_saga_tenant`, `ck_provisioning_saga_env`, `ck_provisioning_saga_complete`, `ck_provisioning_saga_state`, `ck_provisioning_saga_attempt`, `ck_provisioning_saga_deadline`, `ck_provisioning_saga_finished`, `ck_provisioning_saga_trace`, `ck_provisioning_saga_error`.

**Chỉ mục.** `ix_provisioning_saga_due`, `ix_provisioning_saga_system`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_provisioning_saga_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Chèn cùng giao dịch với phê duyệt; bộ chạy lấy việc bằng `FOR UPDATE SKIP LOCKED` trên chỉ mục `ix_provisioning_saga_due`; `id` là `sagaId` bất biến làm khóa lũy đẳng với PH-12, PH-03.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `environment` | `varchar(10)` | x |  |  |
| `complete_with` | `varchar(8)` | x | `'NONE'` | ACTIVATE: bước FINALIZE của saga PRODUCTION chuyển HTTT APPROVED → ACTIVE trong cùng giao dịch cục bộ (SDD §4.6). |
| `state` | `varchar(12)` | x | `'PENDING'` | PENDING, RUNNING, WAITING_RETRY, COMPENSATING, SUCCEEDED, FAILED (quá hạn hoặc lỗi nghiệp vụ không tự khỏi, đặt provision_stage = PROVISION_FAILED), CANCELLED. |
| `attempt` | `integer` | x | `0` |  |
| `next_run_at` | `timestamptz` | x | `now()` | Lịch thử lại lùi 1, 2, 4, 8, 15 phút rồi mỗi 15 phút tới deadline_at (started_at cộng 24 giờ). |
| `started_at` | `timestamptz` | x | `now()` |  |
| `deadline_at` | `timestamptz` | x |  |  |
| `finished_at` | `timestamptz` |  |  |  |
| `credential_id` | `uuid` |  |  |  |
| `async_callback` | `boolean` | x | `false` |  |
| `last_error_code` | `varchar(16)` |  |  |  |
| `last_error_detail` | `varchar(1000)` |  |  | Mô tả lỗi đã che; không chứa bí mật (ràng buộc chặn từ khóa). |
| `requested_by` | `varchar(64)` | x |  |  |
| `trace_id` | `char(32)` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `provisioning_saga`

### 3.16. `saga_step`

::: dac-ta
**Mục đích.** Bước của saga: RECORD, CLIENT, CONSUMER, FINALIZE, HANDOVER, mỗi bước một dòng, lũy đẳng bằng idempotency_key = sagaId:bước (FR-01-020). Bước RUNNING quá 60 giây được bộ chạy gọi lại với cùng khóa; ACCEPTED chờ callback tối đa 5 phút (giả định).

**FR phục vụ.** FR-01-020, 021, 024.

**Khóa chính.** (id).

**Duy nhất.** `uq_saga_step` (tenant_id, saga_id, step_name).

**Khóa ngoại.** (saga_id, tenant_id) → `provisioning_saga` xóa theo.

**Ràng buộc CHECK.** `ck_saga_step_tenant`, `ck_saga_step_name`, `ck_saga_step_status`, `ck_saga_step_idem`, `ck_saga_step_running`, `ck_saga_step_accepted`, `ck_saga_step_compensated`, `ck_saga_step_error`.

**Chỉ mục.** `ix_saga_step_stale`, `ix_saga_step_accepted`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_saga_step_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Bước `RUNNING` quá 60 giây được gọi lại với cùng khóa lũy đẳng (`ix_saga_step_stale`). Xóa theo saga cha.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `saga_id` | `uuid` | x |  |  |
| `step_name` | `varchar(8)` | x |  |  |
| `step_no` | `smallint` | x |  |  |
| `status` | `varchar(11)` | x | `'PENDING'` | PENDING, RUNNING, ACCEPTED (chờ callback), DONE, FAILED, COMPENSATED (đã bù trừ), SKIPPED (bước chưa tạo gì nên bù trừ bỏ qua). |
| `attempt` | `integer` | x | `0` |  |
| `idempotency_key` | `varchar(80)` | x |  |  |
| `external_ref` | `varchar(255)` |  |  | Mã đối tượng đã tạo ở hệ ngoài (clientId của PH-12, consumerId của PH-03); không phải bí mật, dùng để bù trừ. |
| `started_at` | `timestamptz` |  |  |  |
| `accepted_until` | `timestamptz` |  |  |  |
| `finished_at` | `timestamptz` |  |  |  |
| `compensated_at` | `timestamptz` |  |  |  |
| `error_code` | `varchar(16)` |  |  |  |
| `error_detail` | `varchar(1000)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `saga_step`

### 3.17. `enforcement_task`

::: dac-ta
**Mục đích.** Việc cắt quyền có thứ tự: chặn cổng, vô hiệu client, thu hồi token, vô hiệu consumer; chiều khôi phục đi ngược (FR-01-029…032, 037; BR-01-023; NFR-01-008 ≤ 60 giây). Lập cùng giao dịch với lệnh đặt trạng thái; thử lại tới khi xong, không hoàn tác trạng thái.

**FR phục vụ.** FR-01-026, 029…032, 037.

**Khóa chính.** (id).

**Duy nhất.** `uq_enforcement_task` (tenant_id, enforcement_id, task_type).

**Khóa ngoại.** (member_system_id, tenant_id) → `member_system`.

**Ràng buộc CHECK.** `ck_enforcement_task_tenant`, `ck_enforcement_task_mode`, `ck_enforcement_task_source`, `ck_enforcement_task_order`, `ck_enforcement_task_clients`, `ck_enforcement_task_status`, `ck_enforcement_task_attempt`, `ck_enforcement_task_idem`, `ck_enforcement_task_done`, `ck_enforcement_task_error`.

**Chỉ mục.** `ix_enforcement_task_due`, `ix_enforcement_task_system`, `ix_enforcement_task_group`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_enforcement_task_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Chặn cổng trước, đặt trạng thái trước, thử lại tới khi xong, không hoàn tác trạng thái (BR-01-023). `client_ids` cố định khi lập việc.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `member_system_id` | `uuid` | x |  |  |
| `enforcement_id` | `uuid` | x |  | Mã nhóm bốn (hoặc ba) việc của một lệnh; cùng nhóm cùng mode. |
| `mode` | `varchar(9)` | x |  |  |
| `trigger_source` | `varchar(16)` | x |  |  |
| `seq` | `smallint` | x |  | Thứ tự thực hiện: mode khác RESUME gồm 1 BLOCK_GATEWAY, 2 DISABLE_CLIENTS, 3 REVOKE_TOKENS, 4 DISABLE_CONSUMER; RESUME gồm 1 ENABLE_CONSUMER, 2 ENABLE_CLIENTS, 3 UNBLOCK_GATEWAY (ck_enforcement_task_order). |
| `task_type` | `varchar(16)` | x |  |  |
| `client_ids` | `varchar(128)[]` | x |  | Tập client cố định tại thời điểm lập việc, để lũy đẳng và không đổi khi đang chạy (SDD §4.10). |
| `status` | `varchar(7)` | x | `'PENDING'` |  |
| `attempt` | `integer` | x | `0` |  |
| `next_run_at` | `timestamptz` | x | `now()` | Lịch thử lại 10, 20, 40, 60 giây rồi giữ 60 giây; quá 60 giây còn PENDING thì cảnh báo SO. |
| `idempotency_key` | `varchar(80)` | x |  |  |
| `started_at` | `timestamptz` |  |  |  |
| `finished_at` | `timestamptz` |  |  |  |
| `last_error_code` | `varchar(16)` |  |  |  |
| `last_error_detail` | `varchar(1000)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `enforcement_task`

### 3.18. `access_review_cycle`

::: dac-ta
**Mục đích.** EN-01-14 Kỳ rà soát quyền định kỳ (mỗi 6 tháng) hoặc theo chuyên đề; mỗi tenant tối đa một kỳ chưa CLOSED; giữ 5 năm (FR-01-039…044; BR-01-014; ERR-01-039).

**FR phục vụ.** FR-01-039, 042, 044.

**Khóa chính.** (id).

**Duy nhất.** `uq_access_review_cycle_code` (tenant_id, cycle_code), `uq_access_review_cycle_open` (tenant_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_access_review_cycle_tenant`, `ck_access_review_cycle_code`, `ck_access_review_cycle_kind`, `ck_access_review_cycle_period`, `ck_access_review_cycle_status`, `ck_access_review_cycle_closed`, `ck_access_review_cycle_hash`, `ck_access_review_cycle_items`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_access_review_cycle_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger bảo vệ: `tg_access_review_cycle_guard` (bất biến, bốn mắt, chỉ thêm hoặc xóa có điều kiện).

**Ghi chú.** Mỗi tenant tối đa một kỳ chưa `CLOSED`; kỳ đi một chiều; đóng kỳ khi mọi mục có quyết định; kỳ đã đóng bất biến (bằng chứng giữ 5 năm).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `cycle_code` | `varchar(16)` | x |  | RS-{năm}-{nn}, duy nhất trong tenant. |
| `kind` | `varchar(8)` | x | `'PERIODIC'` | PERIODIC (toàn tenant, cập nhật last_access_review_at) hoặc TOPIC (theo danh sách tổ chức scope_org_ids, không cập nhật mốc toàn tenant). |
| `period_from` | `date` | x |  |  |
| `period_to` | `date` | x |  |  |
| `status` | `varchar(8)` | x | `'OPEN'` |  |
| `scope_org_ids` | `varchar(64)[]` |  |  |  |
| `opened_by` | `varchar(64)` | x |  |  |
| `opened_at` | `timestamptz` | x | `now()` |  |
| `item_count` | `integer` | x | `0` |  |
| `closed_by` | `varchar(64)` |  |  |  |
| `closed_at` | `timestamptz` |  |  |  |
| `evidence_hash` | `char(64)` |  |  | SHA-256 của bằng chứng đóng kỳ (danh sách quyết định), bắt buộc khi CLOSED. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `access_review_cycle`

### 3.19. `review_confirmation`

::: dac-ta
**Mục đích.** EN-01-16 Phiếu xác nhận gửi đơn vị chủ quản mỗi kỳ rà soát, mỗi tổ chức một phiếu; chỉ lưu SHA-256 của liên kết, trang xác nhận bắt đăng nhập đúng tổ chức (FR-01-041; BR-01-014).

**FR phục vụ.** FR-01-041.

**Khóa chính.** (id).

**Duy nhất.** `uq_review_confirmation_org` (tenant_id, cycle_id, org_id), `uq_review_confirmation_link` (link_hash).

**Khóa ngoại.** (cycle_id, tenant_id) → `access_review_cycle`.

**Ràng buộc CHECK.** `ck_review_confirmation_tenant`, `ck_review_confirmation_hash`, `ck_review_confirmation_status`, `ck_review_confirmation_ttl`, `ck_review_confirmation_responded`.

**Chỉ mục.** `ix_review_confirmation_due`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_review_confirmation_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Chỉ lưu SHA-256 của liên kết; trang xác nhận bắt đăng nhập đúng tổ chức. Hạn tối đa 60 ngày.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `cycle_id` | `uuid` | x |  |  |
| `org_id` | `varchar(64)` | x |  | Mã tổ chức ở PH-20 được hỏi; người mở phải thuộc tổ chức này (ERR-01-025). |
| `link_hash` | `char(64)` | x |  |  |
| `status` | `varchar(9)` | x | `'PENDING'` |  |
| `sent_at` | `timestamptz` | x | `now()` |  |
| `expires_at` | `timestamptz` | x |  | Hạn phiếu = sent_at cộng accessReview.confirmLinkTtlDays (mặc định 30 ngày); trần cứng 60 ngày. |
| `reminder_sent_at` | `timestamptz` |  |  |  |
| `responded_at` | `timestamptz` |  |  |  |
| `responder_id` | `varchar(64)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `review_confirmation`

### 3.20. `access_review_item`

::: dac-ta
**Mục đích.** EN-01-15 Mục rà soát: một dòng cho mỗi cặp (HTTT, mục trần) của kỳ, ghi mức dùng thực tế, phản hồi của đơn vị và quyết định; giữ 5 năm (FR-01-040…043; BR-01-014, 015).

**FR phục vụ.** FR-01-040…043.

**Khóa chính.** (id).

**Duy nhất.** `uq_access_review_item` (tenant_id, cycle_id, scope_ceiling_id).

**Khóa ngoại.** (cycle_id, tenant_id) → `access_review_cycle`, (member_system_id, tenant_id) → `member_system`, (scope_ceiling_id, tenant_id) → `scope_ceiling`, (confirmation_id, tenant_id) → `review_confirmation`.

**Ràng buộc CHECK.** `ck_access_review_item_tenant`, `ck_access_review_item_usage`, `ck_access_review_item_flags`, `ck_access_review_item_proposal`, `ck_access_review_item_response`, `ck_access_review_item_response_who`, `ck_access_review_item_reduce`, `ck_access_review_item_decision`, `ck_access_review_item_decision_who`, `ck_access_review_item_scope_after`, `ck_access_review_item_legal`.

**Chỉ mục.** `ix_access_review_item_cycle`, `ix_access_review_item_open`, `ix_access_review_item_system`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_access_review_item_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Một dòng cho mỗi cặp (HTTT, mục trần) của kỳ; không giữ được mục có căn cứ hết hiệu lực (`ck_access_review_item_legal`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `cycle_id` | `uuid` | x |  |  |
| `member_system_id` | `uuid` | x |  |  |
| `scope_ceiling_id` | `uuid` | x |  |  |
| `org_id` | `varchar(64)` | x |  |  |
| `data_type` | `varchar(64)` | x |  |  |
| `scope_snapshot` | `varchar(200)` | x |  | Phạm vi của trần tại lúc mở kỳ, để so với scope_after và làm bằng chứng. |
| `usage_in_period` | `bigint` |  |  | Số lượt gọi thành công trong kỳ theo PH-13; NULL khi chưa có số liệu (cờ NO_USAGE_DATA, ERR-01-046). |
| `unused_days` | `integer` |  |  |  |
| `flags` | `varchar(20)[]` | x | `'{}'` | Cờ cảnh báo: UNUSED_IN_PERIOD, UNUSED_OVER_12M (theo accessReview.unusedDays), CREDENTIAL_EXPIRING, LEGAL_EXPIRED, NO_USAGE_DATA. |
| `legal_expired` | `boolean` | x | `false` |  |
| `proposal` | `varchar(12)` |  |  |  |
| `proposal_reason` | `varchar(500)` |  |  |  |
| `confirmation_id` | `uuid` |  |  |  |
| `owner_response` | `varchar(7)` |  |  |  |
| `owner_scope_proposed` | `varchar(200)` |  |  |  |
| `owner_responded_at` | `timestamptz` |  |  |  |
| `responder_id` | `varchar(64)` |  |  |  |
| `decision` | `varchar(12)` |  |  | Quyết định KEEP, REDUCE (kèm scope_after), REVOKE_SCOPE; không được KEEP khi legal_expired (ERR-01-041); bắt buộc lý do và người quyết định. |
| `decision_reason` | `varchar(1000)` |  |  |  |
| `scope_after` | `varchar(200)` |  |  |  |
| `decided_by` | `varchar(64)` |  |  |  |
| `decided_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `access_review_item`

### 3.21. `legacy_import_job`

::: dac-ta
**Mục đích.** EN-01-17 Tác vụ nhập HTTT từ hệ cũ hai pha: tải và xem trước, rồi xác nhận một giao dịch (FR-01-048, BR-01-033). Không mang thông tin xác thực: cột thông tin xác thực không bao giờ đọc, chỉ đếm; tệp gốc xóa sau 7 ngày, chỉ giữ băm.

**FR phục vụ.** FR-01-048.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_legacy_import_job_tenant`, `ck_legacy_import_job_kind`, `ck_legacy_import_job_sha`, `ck_legacy_import_job_status`, `ck_legacy_import_job_rows`, `ck_legacy_import_job_confirmed`, `ck_legacy_import_job_finished`, `ck_legacy_import_job_file`, `ck_legacy_import_job_json`, `ck_legacy_import_job_no_secret`.

**Chỉ mục.** `ix_legacy_import_job_status`, `ix_legacy_import_job_file`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_legacy_import_job_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Không mang thông tin xác thực (BR-01-033): `preview` bị ràng buộc không có khóa tên bí mật; tệp gốc xóa sau 7 ngày, chỉ giữ băm.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `source_kind` | `varchar(4)` | x |  |  |
| `file_name` | `varchar(255)` | x |  |  |
| `file_sha256` | `char(64)` | x |  |  |
| `file_object_key` | `varchar(512)` |  |  | Khóa tệp gốc ở kho tạm; đặt NULL cùng file_deleted_at khi xóa sau 7 ngày. |
| `file_deleted_at` | `timestamptz` |  |  |  |
| `status` | `varchar(9)` | x | `'UPLOADED'` |  |
| `row_count` | `integer` | x | `0` | Số dòng đọc được, tối đa legacyImport.maxRows (trần cứng 20.000); nhập lại cùng tệp bỏ qua HTTT trùng (tenant_id, legacy_ref). |
| `created_count` | `integer` | x | `0` |  |
| `duplicate_count` | `integer` | x | `0` |  |
| `warning_count` | `integer` | x | `0` |  |
| `dropped_columns` | `integer` | x | `0` |  |
| `secrets_dropped` | `integer` | x | `0` | Số giá trị giống bí mật (độ dài ≥ 20 và entropy ≥ 3,5 bit mỗi ký tự, hoặc khớp mẫu khóa API) đã bỏ ở các cột không khai báo (SecretLikeDetector). |
| `preview` | `jsonb` |  |  | Kết quả xem trước (hồ sơ sẽ tạo, tổ chức đã ghép); ràng buộc chặn khóa có tên bí mật như lớp phòng thủ thứ hai. |
| `warnings` | `jsonb` | x | `'[]'` |  |
| `requested_by` | `varchar(64)` | x |  |  |
| `confirmed_by` | `varchar(64)` |  |  |  |
| `confirmed_at` | `timestamptz` |  |  |  |
| `finished_at` | `timestamptz` |  |  |  |
| `error_code` | `varchar(16)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `legacy_import_job`

### 3.22. `outbox`

::: dac-ta
**Mục đích.** Outbox (DD-11) cho EVT-01-01…15 và bản ghi kiểm toán gửi PH-13, ghi cùng giao dịch với thay đổi (BR-01-031, ADR-042). Debezium Outbox Event Router đọc WAL (QM-VUA, QM-LON); OutboxRelay dự phòng đánh dấu relayed_at (QM-NHO). Dọn sau 7 ngày. Không bí mật, không secret_ref, không dữ liệu liên hệ cá nhân.

**FR phục vụ.** FR-01-037, 038 (mọi FR phát sự kiện).

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_tenant`, `ck_outbox_type`, `ck_outbox_topic`, `ck_outbox_topic_tenant`, `ck_outbox_trace`, `ck_outbox_payload`, `ck_outbox_no_secret`, `ck_outbox_no_pii`.

**Chỉ mục.** `ix_outbox_pending`, `ix_outbox_occurred`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_outbox_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Debezium Outbox Event Router đọc WAL (QM-VUA, QM-LON); `OutboxRelay` dự phòng dùng `relayed_at` (QM-NHO). Cũng là nơi ghi bản ghi kiểm toán cùng giao dịch (BR-01-031). Không bí mật, không `secret_ref`, không dữ liệu liên hệ cá nhân.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `event_id` | `uuid` | x |  | UUID v7 (thứ tự theo thời gian, tương đương vai trò ULID của SDD §4.11). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `event_type` | `varchar(128)` | x |  |  |
| `topic` | `varchar(249)` | x |  | Dạng t{nn}.connect.{thực-thể}.{sự-kiện}.v{n}, chữ thường, tiền tố bằng mã tenant (D00-04 §4, SEC-82); kiểm toán dùng miền audit. |
| `aggregate_type` | `varchar(64)` | x |  |  |
| `aggregate_id` | `varchar(64)` | x |  | Khóa bản ghi Kafka: mã HTTT (systemCode) để giữ thứ tự theo HTTT (NFR-01-021); với sự kiện cấp kỳ rà soát là mã kỳ. |
| `payload` | `jsonb` | x |  |  |
| `trace_id` | `char(32)` | x |  |  |
| `occurred_at` | `timestamptz` | x | `now()` |  |
| `relayed_at` | `timestamptz` |  |  | Thời điểm OutboxRelay đã phát (chỉ dùng ở đường dự phòng); NULL với Debezium vì WAL không cần cờ. |

: Cột của bảng `outbox`

### 3.23. `inbox`

::: dac-ta
**Mục đích.** Hộp nhận: sự kiện vào từ PH-12 (tài khoản đầu mối bị vô hiệu hoặc đổi tổ chức), PH-18 (thư bị trả lại), PH-20 (tenant tạm ngừng) xử lý lũy đẳng theo event_id; lỗi ba lần thì DEAD, chuyển hàng đợi lỗi của PH-18. Giữ 30 ngày.

**FR phục vụ.** FR-01-008, 046.

**Khóa chính.** (tenant_id, event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_inbox_tenant`, `ck_inbox_source`, `ck_inbox_status`, `ck_inbox_processed`, `ck_inbox_attempts`.

**Chỉ mục.** `ix_inbox_retention`, `ix_inbox_failed`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_inbox_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Lũy đẳng theo `(tenant_id, event_id)`; lỗi ba lần thì `DEAD` chuyển hàng đợi lỗi của PH-18. Giữ 30 ngày.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `event_id` | `varchar(64)` | x |  | Mã sự kiện do bên phát đặt (ULID hoặc UUID), duy nhất trong tenant. |
| `source` | `varchar(8)` | x |  |  |
| `event_type` | `varchar(128)` | x |  |  |
| `status` | `varchar(9)` | x | `'RECEIVED'` |  |
| `attempts` | `smallint` | x | `0` |  |
| `last_error` | `varchar(1000)` |  |  |  |
| `received_at` | `timestamptz` | x | `now()` |  |
| `processed_at` | `timestamptz` |  |  |  |

: Cột của bảng `inbox`

### 3.24. `notify_outbox`

::: dac-ta
**Mục đích.** Hàng đợi thông báo và việc cho hộp việc của PH-18, thử lại tới 24 giờ để lỗi PH-18 không làm hỏng giao dịch nghiệp vụ (SDD §8.2). Không chứa liên kết bàn giao hay phiếu xác nhận: thư mang liên kết gửi trực tiếp qua NotifyPort, lỗi thì tạo lại liên kết (Q01-52).

**FR phục vụ.** FR-01-016, 027, 041, 046.

**Khóa chính.** (id).

**Duy nhất.** `uq_notify_outbox_dedupe` (tenant_id, dedupe_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_notify_outbox_tenant`, `ck_notify_outbox_kind`, `ck_notify_outbox_recipient`, `ck_notify_outbox_status`, `ck_notify_outbox_sent`, `ck_notify_outbox_deadline`, `ck_notify_outbox_payload`, `ck_notify_outbox_no_secret`, `ck_notify_outbox_no_link`.

**Chỉ mục.** `ix_notify_outbox_due`, `ix_notify_outbox_retention`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_notify_outbox_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Thử lại tới 24 giờ; không chứa liên kết bàn giao hay phiếu xác nhận (Q01-52).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `kind` | `varchar(6)` | x |  |  |
| `template_code` | `varchar(64)` | x |  |  |
| `recipient_type` | `varchar(8)` | x |  |  |
| `recipient_ref` | `varchar(128)` | x |  | Mã người dùng, mã vai trò, hoặc id đầu mối (CONTACT) để PH-18 tự tra thư điện tử; không sao chép thư, số điện thoại vào bảng này. |
| `payload` | `jsonb` | x | `'{}'` | Tham số điền mẫu thông báo; ràng buộc chặn khóa bí mật, liên kết và đường dẫn chứa mã (ck_notify_outbox_no_secret, ck_notify_outbox_no_link; giả định đường dẫn dạng /ban-giao/{mã}, /xac-nhan/{mã}). |
| `dedupe_key` | `varchar(128)` |  |  | Khóa chống gửi trùng nhắc việc, ví dụ expiring:{credentialId}:30; duy nhất trong tenant khi khác NULL. |
| `status` | `varchar(7)` | x | `'PENDING'` |  |
| `attempt` | `integer` | x | `0` |  |
| `next_run_at` | `timestamptz` | x | `now()` |  |
| `deadline_at` | `timestamptz` | x |  |  |
| `sent_at` | `timestamptz` |  |  |  |
| `last_error` | `varchar(1000)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `notify_outbox`

### 3.25. `idempotency_record`

::: dac-ta
**Mục đích.** Kết quả yêu cầu ghi có Idempotency-Key bắt buộc; cùng khóa cùng thân trả lại phản hồi đã lưu, khác thân thì ERR-01-051 (type idempotency-mismatch), đang xử lý thì ERR-01-054; giữ 24 giờ (ADR-041, SDD §8.2). Không bao giờ lưu phản hồi mở bàn giao có chứa bí mật.

**FR phục vụ.** FR-01-003, 009, 012, 018, 020, 024, 029…035 (mọi lệnh POST có tác dụng phụ).

**Khóa chính.** (tenant_id, client_id, request_method, request_path, idempotency_key).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_idempotency_record_tenant`, `ck_idempotency_record_method`, `ck_idempotency_record_key`, `ck_idempotency_record_hash`, `ck_idempotency_record_state`, `ck_idempotency_record_done`, `ck_idempotency_record_ttl`, `ck_idempotency_record_no_open`, `ck_idempotency_record_no_secret`.

**Chỉ mục.** `ix_idempotency_record_expiry`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên, tenant dạng `T{nn}`; bốn chính sách `rls_idempotency_record_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Giữ 24 giờ (ADR-041); chặn lưu tuyến mở bàn giao vì phản hồi chứa bí mật.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS. |
| `client_id` | `varchar(255)` | x |  |  |
| `request_method` | `varchar(8)` | x |  |  |
| `request_path` | `varchar(512)` | x |  | Đường dẫn đã chuẩn hóa; ck_idempotency_record_no_open chặn lưu tuyến handovers:open vì phản hồi chứa bí mật (BR-01-007, NFR-01-009). |
| `idempotency_key` | `varchar(64)` | x |  |  |
| `request_hash` | `char(64)` | x |  | SHA-256 thân yêu cầu chuẩn hóa JCS (RFC 8785). |
| `state` | `varchar(12)` | x | `'IN_PROGRESS'` |  |
| `resource_id` | `uuid` |  |  |  |
| `response_status` | `smallint` |  |  |  |
| `response_body` | `jsonb` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `completed_at` | `timestamptz` |  |  |  |
| `expires_at` | `timestamptz` | x |  |  |

: Cột của bảng `idempotency_record`

### 3.26. `shedlock`

::: dac-ta
**Mục đích.** Khóa tác vụ định kỳ (DraftCleaner, EscalationJob, EmergencyConfirmationJob, ExpiryJob, InactivityJob, AccessReviewScheduler, LegalValidityChecker, GapDetector, SnapshotPublisher, retention); bảng kỹ thuật của ShedLock, không có tenant_id. Bộ chạy saga và cắt quyền dùng SKIP LOCKED nên không cần khóa này.

**FR phục vụ.** FR-01-009, 016, 027, 036, 039, 041, 043, 046 (tác vụ định kỳ).

**Khóa chính.** (name).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không bật RLS (không có `tenant_id`). Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ, không bật RLS, vai trò chỉ đọc không đọc được.

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Xem mục Cách ly tenant.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `name` | `varchar(64)` | x |  |  |
| `lock_until` | `timestamptz` | x |  |  |
| `locked_at` | `timestamptz` | x |  |  |
| `locked_by` | `varchar(255)` | x |  |  |

: Cột của bảng `shedlock`

<!-- gen:tables:end -->

### 3.27. Truy vấn chính và chỉ mục phục vụ

Bảng liệt kê những truy vấn nóng và tác vụ định kỳ của SDD cùng chỉ mục phục vụ; chỉ mục từng phần (có `WHERE`) giữ kích thước nhỏ vì phần lớn dòng đã ở trạng thái cuối.

| Truy vấn hoặc tác vụ | FR, NFR | Chỉ mục |
|---|---|---|
| Danh sách HTTT lọc trạng thái, tổ chức, tìm tên | FR-01-001, NFR-01-003 | `ix_member_system_status_org`, `ix_member_system_name_trgm` (pg_trgm) |
| API đọc bản sao theo con trỏ `(updated_at, id)` | FR-01-038 | `ix_member_system_updated` |
| Bộ chạy saga lấy việc, `FOR UPDATE SKIP LOCKED`, mỗi 2 giây | FR-01-020, NFR-01-004 | `ix_provisioning_saga_due` (từng phần) |
| Bước saga `RUNNING` quá 60 giây; bước `ACCEPTED` quá hạn callback | FR-01-020 | `ix_saga_step_stale`, `ix_saga_step_accepted` (từng phần) |
| Việc cắt quyền chưa xong, thử lại mỗi 10 giây | FR-01-029, NFR-01-008 | `ix_enforcement_task_due`; HTTT còn việc: `ix_member_system_enforcement` (từng phần) |
| Mở bàn giao theo băm liên kết | FR-01-022 | `uq_handover_link` |
| Bàn giao hết hạn mỗi phút; bàn giao `OPENING` treo quá 2 phút | FR-01-022 | `ix_handover_due`, `ix_handover_opening` (từng phần) |
| Định danh sắp hết hạn 30, 14, 7 ngày; chuỗi bí mật hết hạn; kết thúc xoay vòng | FR-01-025, 027 | `ix_app_credential_expiry`, `ix_app_credential_secret_expiry`, `ix_app_credential_rotation` |
| Định danh PRODUCTION không dùng 90 ngày | FR-01-036 | `ix_app_credential_inactive` |
| Căn cứ pháp lý hết hiệu lực lúc 05:30; mục trần không dùng | FR-01-043, 040 | `ix_scope_ceiling_legal`, `ix_scope_ceiling_unused` |
| Dọn nháp bỏ quên (nhắc 14 ngày trước, xóa mềm sau 90 ngày) | FR-01-009 | `ix_member_system_draft_stale` |
| HTTT đến hạn rà soát 6 tháng; kỳ chưa đóng của tenant | FR-01-039 | `ix_member_system_review_due`, `uq_access_review_cycle_open` |
| Mục rà soát chưa quyết định; phiếu xác nhận quá hạn | FR-01-041, 042 | `ix_access_review_item_open`, `ix_review_confirmation_due` |
| Tra danh bạ theo từ khóa; đầu mối lâu không xác nhận; tổ chức thiếu đầu mối kỹ thuật | FR-01-045, 046 | `ix_contact_search_trgm`, `ix_contact_stale`, `ix_contact_system` |
| Việc thẩm định của một người; bước quá hạn để leo thang mỗi 15 phút | FR-01-016 | `ix_review_step_assignee`, `ix_review_step_due` |
| Thao tác khẩn quá hạn xác nhận mỗi 5 phút | FR-01-032 | `ix_emergency_action_due` |
| Phát bù sự kiện (đường dự phòng QM-NHO); dọn `outbox` sau 7 ngày | FR-01-037 | `ix_outbox_pending`, `ix_outbox_occurred` |
| Dọn kết quả SANDBOX sau 1 năm | NFR-01-022 | `ix_sandbox_test_retention` |
| Tệp chờ quét quá 5 phút | FR-01-005 | `ix_attachment_pending` |
| Xóa tệp nhập hệ cũ sau 7 ngày | FR-01-048 | `ix_legacy_import_job_file` |
| Lũy đẳng: tra khóa; dọn bản ghi hết hạn | ADR-041 | `pk_idempotency_record`, `ix_idempotency_record_expiry` |

: Truy vấn chính và chỉ mục phục vụ

### 3.28. Hàm và trigger dùng chung

Bảng liệt kê 19 hàm và thủ tục của schema. Nhóm `tg_*` là hàm trigger; nhóm `fn_*` là hàm kiểm tra dùng trong CHECK hoặc trigger. Mỗi hàm có `COMMENT ON FUNCTION` trong DDL.

| Hàm | Loại | Việc làm |
|---|---|---|
| `tg_touch` | Trigger | Đặt `updated_at`, tăng `version` ở mọi bảng có cột sửa (19 trigger) |
| `p_enable_rls(bảng, mẫu)` | Thủ tục | Bật `FORCE RLS` và bốn chính sách theo mẫu P hoặc S |
| `tg_draft_only_delete(cột)` | Trigger | Chặn xóa dòng con của hồ sơ đã nộp; dùng cho `technical_profile`, `contact`, `attachment`, `data_demand` |
| `tg_member_system_guard` | Trigger | Mã bất biến, trạng thái cuối đóng băng, bảng chuyển, gọi ba hàm kiểm điều kiện |
| `tg_member_system_no_delete` | Trigger | Chỉ xóa cứng nháp chưa từng nộp đã xóa mềm quá 30 ngày |
| `tg_state_history_guard` | Trigger | Chặn sửa, chỉ cho xóa theo tầng khi hồ sơ cha đã bị xóa cứng |
| `tg_scope_ceiling_guard` | Trigger | Trần sinh đúng từ nhu cầu được duyệt, danh tính bất biến, không nâng phân loại |
| `tg_review_step_guard` | Trigger | Bốn mắt giữa người lập, người nộp và người thẩm định; bước đã xong bất biến |
| `tg_app_credential_guard` | Trigger | Điều kiện cấp định danh, danh tính bất biến, bảng chuyển trạng thái |
| `tg_handover_guard` | Trigger | Người nhận hợp lệ, liên kết và hạn bất biến, bảng chuyển trạng thái |
| `tg_access_review_cycle_guard` | Trigger | Kỳ đi một chiều, chỉ đóng khi mọi mục đã quyết định, kỳ đóng bất biến |
| `fn_member_transition_ok` | Hàm | Mười cặp trạng thái HTTT hợp lệ |
| `fn_assert_submittable`, `fn_assert_approvable`, `fn_assert_activatable` | Hàm | Điều kiện nộp, duyệt, kích hoạt (mục 1.4) |
| `fn_urls_https`, `fn_cidr_array` | Hàm | Kiểm danh sách địa chỉ https và CIDR trong CHECK |
| `fn_unaccent`, `fn_rank` | Hàm | Bỏ dấu cho `search_text`; thứ hạng mức phân loại dữ liệu |

: Hàm và trigger dùng chung của schema

## 4. DDL và changelog Liquibase

### 4.1. Tệp

DDL nằm ở thư mục [`ph01/ddl`](ph01/ddl/ph01_00_bootstrap.sql), chia thành chín tệp chạy theo thứ tự tên. Mỗi tệp tự đặt `SET ROLE ph01_owner` và biến phiên `app.tenant_id = 'PLATFORM'` để chạy độc lập bằng `psql`. Trong tệp, các dấu `-- @file`, `-- @changeset`, `-- @rollback` cho phép sinh changelog Liquibase theo cách của [`ph07/tools/gen_liquibase.py`](ph07/tools/gen_liquibase.py); công cụ này hiện gắn cứng với PH-07 nên changelog của PH-01 chưa sinh ở bản 0.1 (đề nghị tham số hóa ở mục Đề nghị đồng bộ). Có 37 changeset, tên dạng `ph01-{số}-{tên}`; changeset nào có thể chạy lại đánh dấu `runAlways:true`; changeset có hàm hoặc khối `DO` đặt `splitStatements:false`.

| Tệp | Tệp Liquibase dự kiến | Nội dung |
|---|---|---|
| `ph01_00_bootstrap.sql` | `01-0000-bootstrap.sql`, `01-0001-functions.sql` | Vai trò, `pg_trgm`, `unaccent`, schema; `tg_touch`, `p_enable_rls`, hàm kiểm tra, `tg_draft_only_delete` |
| `ph01_10_member.sql` | `01-0010-member.sql` | Hàm điều kiện nộp, duyệt, kích hoạt; `member_system`, `technical_profile`, `contact`, `attachment`, `template`, `state_history`, `emergency_action`, `change_request` |
| `ph01_20_demand_review.sql` | `01-0020-demand-review.sql` | `data_demand`, `scope_ceiling`, `review_step` |
| `ph01_30_credential.sql` | `01-0030-credential.sql`, `01-0031-saga.sql` | `app_credential`, `handover`, `sandbox_test`; `provisioning_saga`, `saga_step`, `enforcement_task` |
| `ph01_40_review_cycle.sql` | `01-0040-review-cycle.sql` | `access_review_cycle`, `review_confirmation`, `access_review_item`, `legacy_import_job` |
| `ph01_50_infra.sql` | `01-0050-infra.sql` | `outbox`, `inbox`, `notify_outbox`, `idempotency_record`, `shedlock` |
| `ph01_80_seed.sql` | `01-0800-seed.sql` | 3 mẫu văn bản mặc định (chương 5) |
| `ph01_90_grants.sql` | `01-0900-grants.sql` | Quyền theo vai trò, chạy lại mỗi lần (`runAlways`) |
| `ph01_99_migrate_legacy.sql` | `01-9000-migrate-w1.sql` | Di trú schema `ph01` cũ, context `migrate-w1` (chương 8) |

: Tệp DDL và tệp Liquibase tương ứng

Thứ tự tạo bảng theo phụ thuộc khóa ngoại: `member_system` trước, rồi bảng con của hồ sơ, `data_demand` sau `attachment` và `change_request`, `scope_ceiling` sau `data_demand`, `handover` sau `app_credential` và `contact`, `access_review_item` sau `access_review_cycle`, `review_confirmation` và `scope_ceiling`. Các hàm điều kiện (`fn_assert_*`) tham chiếu bảng tạo ở tệp sau; PL/pgSQL chỉ phân giải khi chạy nên thứ tự này hợp lệ.

### 4.2. Kết quả chạy thử

Chạy ngày 26/11/2026 trên PostgreSQL 16.16 cài sạch, mỗi lần dựng một CSDL trống, dữ liệu giả, bằng [`chay_tat_ca.sh`](ph01/test/chay_tat_ca.sh): `psql -v ON_ERROR_STOP=1 -f` lần lượt từng tệp, rồi chạy lại tệp quyền, rồi hai bài kiểm.

- DDL chạy không lỗi trên CSDL trống: 26 bảng, 522 cột, 30 khóa ngoại, 234 ràng buộc CHECK, 118 chỉ mục, 31 trigger, 19 hàm và thủ tục, 100 chính sách RLS. Chạy lại tệp quyền (`runAlways`) không lỗi.
- [`ph01_isolation_test.sql`](ph01/test/ph01_isolation_test.sql) chạy dưới tài khoản `dh_connect_app` (thành viên `ph01_app`, không `BYPASSRLS`) đạt 207 khối PASS, gồm các nhóm trong bảng dưới.
- [`ph01_migrate_test.sql`](ph01/test/ph01_migrate_test.sql) dựng lại schema `ph01` của `apps/control` với dữ liệu giả phủ mọi trạng thái cũ, chạy changeset `ph01-9000` và đạt 19 khối PASS: ánh xạ trạng thái, bốn mắt bị vi phạm ở dữ liệu cũ không làm dừng di trú, cột bí mật bị xóa và quét xác nhận, bảng cũ đổi tên, chạy lại không nhân đôi, tenant khác không thấy dữ liệu di trú.

| Nhóm kiểm | Số khối | Điều được kiểm |
|---|---|---|
| Cô lập tenant (1 đến 5) | 15 | T01 không đọc, không chèn, không sửa, không xóa dòng T68; khóa ngoại không trỏ chéo tenant; biến phiên rỗng và phiên `PLATFORM` không thấy dòng; mã HTTT duy nhất theo tenant; mã sai mẫu; `https`, CIDR |
| Điều kiện nộp và xóa (6 đến 8) | 12 | Thiếu đầu mối kỹ thuật, thiếu tệp căn cứ, `revision_no`, thiếu số quyết định cấp độ; không xóa hồ sơ, đầu mối, nhu cầu, tài liệu đã nộp |
| Thẩm định và bốn mắt (9 đến 12) | 19 | Người lập, nộp không thẩm định; kết luận một lần; không duyệt khi thiếu bước, kết luận, nhóm; người thẩm định, lập, nộp không duyệt |
| Trần phạm vi (13) | 8 | Trần bằng đúng phạm vi đã duyệt; không nâng phân loại; danh tính bất biến; tạm ngừng, khôi phục |
| Định danh, không bí mật (14, 15) | 17 | Không cấp PRODUCTION khi chưa qua SANDBOX; `secret_ref` không nhận giá trị bí mật, không trỏ tenant khác; hạn 12 tháng, 180 ngày, 14 ngày; một định danh sống mỗi môi trường; bất biến |
| Bàn giao một lần (16) | 11 | Liên kết chỉ dạng băm; hạn ≤ 72 giờ; một bàn giao chờ; mở là một chiều, mã bọc bị xóa; người nhận phải có tài khoản |
| Saga và cắt quyền (17, 18) | 12 | Một saga đang chạy; khóa lũy đẳng; thứ tự việc cắt quyền; lỗi không chứa bí mật |
| Vòng đời (19, 20) | 11 | Kích hoạt cần SANDBOX và người khác người nộp; không quay lại trạng thái cũ; tạm ngừng cần lý do; không bàn giao khi đang tạm ngừng |
| Thao tác khẩn, thay đổi (21, 22) | 13 | Người xác nhận khác người thực hiện; một yêu cầu chờ; chấm dứt cần báo cáo tác động |
| Rà soát quyền (23 đến 25) | 18 | Một kỳ mở; kỳ đi một chiều; không đóng khi còn mục chưa quyết định; không giữ mục hết hiệu lực; kỳ đóng bất biến |
| Đầu mối, tài liệu, nhập hệ cũ (26 đến 29) | 18 | Đầu mối ATTT không công khai; thư, điện thoại; tìm không dấu; 50 MB; không `staging/`; xem trước không có khóa bí mật; xóa cứng nháp sau 30 ngày |
| Lịch sử, outbox, thông báo, lũy đẳng, hộp nhận (30 đến 33) | 21 | Chỉ thêm; topic đúng tenant; không bí mật, không dữ liệu cá nhân; không liên kết trong thông báo; không lưu tuyến mở bàn giao; lũy đẳng 24 giờ |
| Mẫu dùng chung, quyền vai trò, cấu trúc (34 đến 40) | 32 | Mẫu S: tỉnh đọc `COMMON`, không ghi; vai trò ứng dụng không xóa bảng bằng chứng; vai trò chỉ đọc bị chặn cột; mọi bảng có `FORCE RLS` và bốn chính sách; không cột bí mật |

: Nhóm bài kiểm trong ph01_isolation_test.sql

Bài kiểm `TenantIsolationIT` của D03-02-PH01 §12 tự động hóa các ca này trong CI bằng Testcontainers; ca canary `DH-CANARY-…` (NFR-01-009) quét thêm nhật ký, vết, phản hồi, tệp xuất và thư, ngoài phạm vi CSDL.

## 5. Dữ liệu khởi tạo

Schema chỉ có một loại dữ liệu khởi tạo ở CSDL là mẫu văn bản mặc định của nền tảng (tenant `COMMON`); mọi thứ còn lại theo tenant do quy trình kết nạp, PH-18 hoặc PH-20 tạo khi khởi tạo tenant. Bảng sau liệt kê dữ liệu khởi tạo và nơi lưu của từng loại.

| Dữ liệu | Tenant | Nội dung | Nguồn |
|---|---|---|---|
| Mẫu văn bản mặc định | `COMMON` | 3 dòng `template` đang `PUBLISHED`, phiên bản 1.0: `mau-van-ban-de-nghi-ket-noi`, `mau-ban-khai-can-cu-phap-ly`, `huong-dan-ket-noi-chuan`; `id` tất định theo mã và phiên bản; `file_sha256` là băm giữ chỗ cho tới khi tác vụ nạp mẫu ghi băm của tệp thật | FR-01-010 |
| Tham số `onboarding.*` | PH-18 (DD-14) | 30 khóa với mặc định và miền ở FRS §8.2 (ví dụ `review.slaWorkingDays` = 2, `handover.ttlHours` = 24); không lưu ở schema này | FR-01-049 |
| Tài nguyên theo tenant | Khi PH-20 khởi tạo tenant | Bucket `dh-{tenant}-onboarding`, khóa transit `dh-{tenant}-handover`, chính sách OpenBao `kv/dh/{tenant}/clients/*`, ACL Kafka tiền tố `{tenant}.connect.` | SDD §14 mục 5 |
| Lược đồ sự kiện | Apicurio | Lược đồ EVT-01-01…15 chế độ BACKWARD | NFR-01-019 |

: Dữ liệu khởi tạo

Seed chạy dưới `app.tenant_id = 'PLATFORM'`, lũy đẳng (`ON CONFLICT … DO UPDATE`), nên chạy lại khi nâng cấp mẫu không nhân bản. Tenant đặt mẫu riêng cùng mã thì mẫu của tenant được dùng trước mẫu mặc định (FR-01-010). Bảng nghiệp vụ không có dữ liệu khởi tạo: HTTT đầu tiên của tenant được tạo qua quy trình kết nạp hoặc nhập hệ cũ.

## 6. Kho lưu trữ ngoài PostgreSQL

PH-01 chủ yếu dùng PostgreSQL; các kho ngoài chỉ giữ thứ không nên nằm trong bảng: bí mật, nội dung tệp, sự kiện và bộ đếm giới hạn tốc độ. Không dùng ClickHouse.

### 6.1. OpenBao

Bí mật của HTTT (khác với đường dẫn tới bí mật) chỉ nằm ở OpenBao, PH-01 chỉ giữ đường dẫn, số phiên bản và mã bọc đã mã hóa. Bảng sau liệt kê bốn nhóm đường dẫn PH-01 dùng và quyền của `dh-connect` trên từng nhóm.

| Đường dẫn | Nội dung | Ai ghi, ai đọc |
|---|---|---|
| `kv/dh/{tenant}/clients/{systemCode}/{env}` (KV v2) | Bí mật client (`CLIENT_SECRET`, `API_KEY`); `env` là `sandbox` hoặc `production` | PH-12 ghi khi tạo client (saga); `dh-connect` chỉ đọc kèm bọc bắt buộc (`min_wrapping_ttl` = 60 giây, `max_wrapping_ttl` = 72 giờ), hủy phiên bản sau khi mở bàn giao |
| `kv/metadata/dh/{tenant}/clients/*` | Số phiên bản, thời điểm; không có giá trị | `dh-connect` đọc để ghi `secret_version` |
| `transit/keys/dh-{tenant}-handover` | Khóa mã hóa mã bọc, AAD là `tenant_id` và `handover.id` | `dh-connect` mã hóa khi tạo bàn giao, giải mã khi mở; kết quả ở `handover.wrap_token_sealed` |
| `pki-clients/sign/http-clients-{tenant}` | Ký CSR của HTTT dùng `MTLS` | `dh-connect` ký; chỉ lưu `cert_fingerprint` ở `app_credential` (FR-01-021) |

: OpenBao

Chính sách OpenBao sinh theo tenant lúc khởi tạo nên lỗi mã không đọc nhầm bí mật của tỉnh khác (SEC-82); `app_credential.secret_ref` bị ràng buộc khớp đúng mẫu đường dẫn, tenant và môi trường ở bảng trên. Khóa `transit/keys/dh-{tenant}-pii` (SEC-31) chỉ dùng nếu quyết định mã hóa trường dữ liệu liên hệ (Q01-51).

### 6.2. Kafka

Sự kiện ghi vào `outbox` cùng giao dịch, rồi Debezium Outbox Event Router đọc WAL (hồ sơ `QM-VUA`, `QM-LON`) hoặc `OutboxRelay` quét lô mỗi 500 ms (`QM-NHO`, đánh dấu `relayed_at`) và phát lên Kafka; khóa bản ghi là `systemCode` để giữ thứ tự theo HTTT (NFR-01-021). Topic dạng `{tenant}.connect.{thực-thể}.{sự-kiện}.v{n}`, chữ thường, tiền tố tenant; CHECK `ck_outbox_topic`, `ck_outbox_topic_tenant`, `ck_outbox_type` chặn topic sai dạng hoặc sai tenant. Số phân vùng và thời hạn giữ là giả định theo mẫu PH-05, chốt ở D03-09.

| Mã | Topic (tiền tố `{tenant}.connect.`) | Phân vùng, giữ | Khóa |
|---|---|---|---|
| EVT-01-01 | `system.submitted.v1` | 3, 7 ngày | `systemCode` |
| EVT-01-02 | `review.decided.v1` | 3, 7 ngày | `systemCode` |
| EVT-01-03 | `system.state-changed.v1` (kèm ảnh chụp đối chiếu hằng giờ `snapshot = true`) | 3, 7 ngày | `systemCode` |
| EVT-01-04 | `system.updated.v1` | 3, 7 ngày | `systemCode` |
| EVT-01-05 | `credential.issued.v1` | 3, 7 ngày | `systemCode` |
| EVT-01-06 | `credential.rotated.v1` | 3, 7 ngày | `systemCode` |
| EVT-01-07 | `credential.revoked.v1` | 3, 7 ngày | `systemCode` |
| EVT-01-08 | `credential.expiring.v1` | 3, 7 ngày | `systemCode` |
| EVT-01-09 | `handover.opened.v1` | 3, 7 ngày | `systemCode` |
| EVT-01-10 | `handover.security-alert.v1` | 3, 7 ngày | `systemCode` |
| EVT-01-11 | `scope-ceiling.changed.v1` | 3, 7 ngày | `systemCode` |
| EVT-01-12 | `access-review.completed.v1` | 3, 7 ngày | Mã kỳ `RS-…` |
| EVT-01-13 | `contact.changed.v1` (không kèm dữ liệu liên hệ, chỉ mã HTTT và loại) | 3, 7 ngày | `systemCode` |
| EVT-01-14 | `directory.gap-detected.v1` | 3, 7 ngày | Mã tổ chức |
| EVT-01-15 | `emergency-action.recorded.v1` | 3, 7 ngày | `systemCode` |

: Topic Kafka của PH-01 (EVT-01-01…15)

PH-01 tiêu thụ ba loại sự kiện của phân hệ khác (tài khoản đầu mối bị vô hiệu hoặc đổi tổ chức của PH-12, thư bị trả lại của PH-18, tenant tạm ngừng của PH-20), xử lý lũy đẳng nhờ `inbox`; tên topic của ba loại này chốt ở D03-04 của phân hệ phát (Q01-13 của FRS). Bản ghi kiểm toán đi theo cùng `outbox` với miền `audit` (SEC-60, SEC-62), PH-13 nhận và ghi WORM; PH-01 không ghi WORM.

### 6.3. Kho đối tượng và bộ đệm

Nội dung tệp đính kèm ở Garage (ADR-008), còn bộ đếm giới hạn tốc độ tra danh bạ ở Valkey; bảng dưới nêu khóa, nội dung và vòng đời từng loại.

| Kho | Khóa hoặc tên | Nội dung | Vòng đời |
|---|---|---|---|
| Garage, bucket `dh-{tenant}-onboarding` | `{systemCode}/{attachmentId}` | Tệp đính kèm hồ sơ, mã hóa phía máy chủ bằng khóa SSE-C lấy từ OpenBao (SEC-30); tên khóa ghi ở `attachment.object_key` | Vĩnh viễn cùng hồ sơ; chỉ xóa khi nháp chưa từng nộp bị xóa cứng; đối soát đêm báo tệp mồ côi |
| Garage, cùng bucket | `staging/{uuid}` | Khóa tạm trong lúc quét mã độc (ADR-008); không ghi vào `attachment` | Xóa ngay sau khi quét xong; đối soát đêm báo khóa tạm còn sót |
| Garage, cùng bucket | `import/{jobId}` (giả định) | Tệp xuất từ hệ cũ chờ nhập; ghi ở `legacy_import_job.file_object_key` | Xóa sau 7 ngày, chỉ giữ băm (`file_deleted_at`) |
| Garage, bucket nền tảng | `platform/onboarding/templates/{mã}/{phiên bản}/{tệp}` | Tệp mẫu văn bản mặc định, ghi ở `template.file_ref` | Theo phiên bản |
| Valkey | `dir:{tenant}:{userId}` | Cửa sổ trượt giới hạn tra danh bạ, mặc định 60 lượt mỗi phút (`directory.rateLimitPerMinute`) | Hết cửa sổ; Valkey ngừng thì dùng bộ đếm cục bộ, nới hơn nhưng không mở không giới hạn |

: Kho đối tượng và bộ đệm

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

Bảng dưới nêu thời hạn lưu giữ từng nhóm dữ liệu theo NFR-01-022, BR-01-011 và các giả định ghi rõ. Dọn dữ liệu hết hạn do tác vụ định kỳ của `dh-connect` chạy qua `TenantJobRunner` (một bản sao chạy nhờ ShedLock). Bảng giữ vĩnh viễn và bằng chứng không cấp quyền `DELETE` cho `ph01_app` nên việc xóa quá thời hạn (ví dụ kỳ rà soát sau 5 năm) do DBA làm bằng `ph01_owner` theo quy trình có duyệt.

| Đối tượng | Lưu giữ | Cơ chế dọn |
|---|---|---|
| Schema `ph01_onboarding` | Sao lưu theo `pg-core` (D03-09): WAL liên tục và sao lưu đầy hằng ngày lên kho sao lưu bất biến; mục tiêu PH-01 RPO ≤ 1 giờ, RTO ≤ 4 giờ (NFR-01-006, SEC-71) | Theo D03-09 |
| `member_system`, `technical_profile`, `data_demand`, `attachment`, `review_step`, `change_request`, `emergency_action`, `state_history`, `scope_ceiling` | Vĩnh viễn, kể cả HTTT đã chấm dứt hoặc bị từ chối (BR-01-011, NFR-01-022) | Không dọn; chỉ nháp chưa từng nộp: xóa mềm rồi xóa cứng sau 30 ngày (`tg_member_system_no_delete`) |
| `contact` | Vĩnh viễn cùng hồ sơ; đầu mối thay hoặc vô hiệu chuyển `INACTIVE`, không xóa | Không dọn; chính sách ẩn danh khi hết nghĩa vụ lưu ở Q01-51 |
| `app_credential` | Vĩnh viễn (siêu dữ liệu, không bí mật; giả định cùng thời hạn với hồ sơ để kiểm toán truy được định danh nào đã cấp) | Không dọn |
| `handover` | 3 năm (NFR-01-022) | Tác vụ dọn lưu giữ hằng đêm xóa dòng quá 3 năm kể từ `created_at` |
| `sandbox_test` | 1 năm (NFR-01-022) | Tác vụ dọn xóa theo lô 10.000 dòng theo `ix_sandbox_test_retention` |
| `access_review_cycle`, `review_confirmation`, `access_review_item` | 5 năm (NFR-01-022) | DBA xóa sau 5 năm; kỳ `CLOSED` bất biến |
| `provisioning_saga`, `saga_step`, `enforcement_task` | 12 tháng sau khi kết thúc (giả định, bằng thời hạn kiểm toán trực tuyến, ADR-031); bằng chứng quyết định đã nằm ở `state_history` và kiểm toán | Tác vụ dọn xóa theo saga cha (bước xóa theo tầng) |
| `legacy_import_job` | 12 tháng (giả định); tệp gốc xóa sau 7 ngày | Tác vụ dọn đặt `file_deleted_at`, `file_object_key = NULL` sau 7 ngày, xóa dòng sau 12 tháng |
| `outbox` | 7 ngày sau khi đã phát (SDD §4.11) | Tác vụ dọn; `autovacuum` chỉnh riêng cho bảng nhiều ghi xóa |
| `inbox` | 30 ngày (SDD §8.2) | Tác vụ dọn theo `ix_inbox_retention` |
| `notify_outbox` | 30 ngày (giả định) | Tác vụ dọn theo `ix_notify_outbox_retention` |
| `idempotency_record` | 24 giờ (ADR-041) | Tác vụ dọn theo `ix_idempotency_record_expiry` |
| `template` | Theo phiên bản; bản `RETIRED` giữ | Không dọn |
| Garage, `dh-{tenant}-onboarding` | Cùng hồ sơ; sao lưu bucket theo D03-09 | Theo mục 6.3 |
| OpenBao | Snapshot Raft hằng giờ, sang site DR (D03-09); phiên bản bí mật client bị hủy sau khi mở bàn giao, hủy sau thu hồi theo chính sách PH-12 | Theo PH-12 |
| Bản ghi kiểm toán | Trực tuyến 12 tháng, WORM 5 năm ở PH-13 (ADR-031, SEC-62) | Do PH-13 |

: Sao lưu, khôi phục, mã hóa và lưu giữ

**Mã hóa khi lưu.** Volume nút CSDL mã hóa ở tầng khối (SEC-30). Dữ liệu liên hệ đầu mối (mức HC) dùng ba lớp: RLS theo tenant, quyền cột (`ph01_readonly` không đọc họ tên, chức vụ, thư, điện thoại, tài khoản, `search_text`), che trong log theo `@Classified` (SEC-32); không đưa vào sự kiện. Mã hóa trường (SEC-31) chưa áp dụng vì làm hỏng tìm kiếm danh bạ bằng `pg_trgm`; nếu hội đồng hoặc ATTT yêu cầu thì `search_text` đổi sang chỉ mục băm theo token (Q01-29 của SDD, Q01-51). Mã bọc OpenBao ở `handover.wrap_token_sealed` được mã hóa bằng khóa transit riêng của tenant.

**Khôi phục.** Sau khôi phục từ bản sao lưu, việc đầu tiên là kiểm các HTTT có `enforcement = 'PENDING'` rồi để `EnforcementRetryJob` chạy tiếp; saga ở `RUNNING`, `WAITING_RETRY` tiếp tục từ CSDL vì mọi lời gọi ngoài lũy đẳng bằng `sagaId:bước`; tác vụ đối soát hằng giờ (`SnapshotPublisher`) đưa PH-02, PH-03, PH-10 về đúng trạng thái. Bàn giao `OPENING` quá 2 phút chuyển `CANCELLED` với `OPEN_INTERRUPTED` và báo TA xoay vòng định danh, vì có thể bí mật đã được mở mà chưa tới người nhận. Khôi phục CSDL về thời điểm cũ hơn OpenBao: `secret_version` có thể thấp hơn phiên bản thật, tác vụ đối soát đọc metadata OpenBao và sửa; khôi phục OpenBao về thời điểm cũ hơn CSDL: phiên bản ở CSDL không tồn tại, định danh bị đánh dấu cần xoay. Sổ tay DR ghi rõ thứ tự khôi phục OpenBao trước, CSDL sau.

## 8. Ánh xạ dữ liệu hệ cũ sang thiết kế mới

Có ba nguồn dữ liệu cũ: schema `ph01` của mã hiện tại trong `apps/control` (W1, di trú bằng changeset `ph01-9000`, đã chạy thử), mô hình dữ liệu của SRS cũ trong repo `docs/07-srs/SRS-PH-01-onboarding.md` (không có bảng thật, ánh xạ để người dùng cũ đối chiếu khái niệm), và dữ liệu của hệ cũ đang chạy (Application của APIM, publisher và subscriber của Hub) đi vào bằng chức năng nhập FR-01-048. Bảng ánh xạ là đầu vào cho kế hoạch di trú D06-01.

### 8.1. Bảng của mã hiện tại (`apps/control`, W1)

Changeset `ph01-9000` ([`ph01_99_migrate_legacy.sql`](ph01/ddl/ph01_99_migrate_legacy.sql)) chạy khi có bảng `ph01.application`, vào tenant `app.migrate_tenant` (mặc định `T01`), lũy đẳng theo `id`. Dữ liệu W1 là dữ liệu thử nghiệm; hồ sơ cũ thiếu hồ sơ kỹ thuật có cấu trúc, nhu cầu khai thác có căn cứ và đầu mối đủ nên không qua được bộ kiểm nộp mới (Q01-53).

| Bảng, cột cũ | Đích | Chuyển đổi và ghi chú |
|---|---|---|
| `application.id` | `member_system.id` | Giữ nguyên UUID |
| `system_code` | `code` | Chữ hoa, ký tự lạ thành `-`; sai mẫu `^[A-Z][A-Z0-9-]{2,63}$` thì sinh `HT-` cộng 8 ký tự băm của `id` |
| `system_name` | `name` | Cắt 255; dưới 3 ký tự thì thêm " (HTTT)" |
| `owner_org` (tên chữ) | `description` ("Chủ quản (hệ cũ): …"), `owner_org_id = 'CHUA-GAN'` | TA ghép tổ chức ở PH-20 rồi mới sửa tiếp |
| `status` `SUBMITTED`, `REVIEWED` | `DRAFT` kèm `revision_no = 1`, `return_reason` | Lệch SDD §2.4 (REVIEWED vào `SUBMITTED` kèm `reviewStage`) vì thiếu dữ liệu để duyệt tiếp; đơn vị khai lại rồi nộp lại (Q01-53) |
| `status` `APPROVED` | `APPROVED`, `provision_stage = PROVISION_FAILED` | TA bấm "Thử lại" cấp định danh qua saga mới |
| `status` `ACTIVE`, `SUSPENDED`, `REJECTED` | Giữ nguyên | `SUSPENDED` có `suspend_reason_code = OTHER` |
| `status` `REVOKED` | `TERMINATED`, `terminated_at = updated_at` | SDD §2.4 |
| `status_reason` | `status_reason` | Thêm hậu tố "[di trú từ ph01 cũ]" để đủ 10 ký tự khi `SUSPENDED`, `TERMINATED`, `REJECTED` |
| `client_id` | Không chuyển | Định danh cấp lại qua saga; D02-07 §5 |
| `client_secret_sealed` | Xóa | Đặt `NULL` rồi `DROP COLUMN`, quét `information_schema` xác nhận không còn cột tên bí mật; sai thì dừng di trú (GAP-01-03, BR-01-007) |
| `submitted_by`, `created_at` | `submitted_by`, `submitted_at` | `submitted_by` trống thì `legacy:unknown` |
| `approved_by` | `approved_by`, `approved_at = updated_at` | Trùng người nộp (vi phạm bốn mắt ở dữ liệu cũ) thì thêm tiền tố `legacy:` để không dừng di trú |
| Dòng `ACTIVATE` của `application_audit` | `activated_by`, `activated_at`, `sandbox_passed_at` | Lấy dòng gần nhất; HTTT đang chạy được miễn kiểm thử SANDBOX (`sandbox_passed_at = activated_at`) |
| `legal_basis` (văn bản tự do) | Tóm tắt trong `state_history.reason` và bảng `application_legacy_w1` | Không có số, ngày, cơ quan, tệp nên không thành `data_demand`; đơn vị khai lại |
| `tech_profile` (văn bản tự do) | Không chuyển cấu trúc | Bảng cũ giữ; đơn vị khai lại hồ sơ kỹ thuật |
| `contact_name`, `contact_email`, `contact_phone` | `contact` loại `TECHNICAL` | Chỉ tạo khi thư điện tử hợp lệ; `job_title = 'Chưa khai (di trú)'`; điện thoại chỉ giữ khi đúng E.164 |
| `legal_review_*`, `tech_review_*` | Tóm tắt trong `state_history.reason` | Không tạo `review_step` vì thiếu phân công và vòng nộp |
| `last_access_review_at` | `last_access_review_at` | `last_access_review_by`, `next_access_review_at` bỏ, tính lại theo `accessReview.intervalMonths` |
| `application_audit` (`action`, `from_status`, `to_status`, `actor`, `note`) | `state_history` | Giữ tên trạng thái cũ làm bằng chứng; bỏ dòng không đổi trạng thái; `trace_id` là `md5(id)` |
| `application_attachment` | `attachment` | `kind = OTHER`, `scan_status = PENDING` (hệ cũ không quét); bỏ tệp rỗng, quá 50 MB, `sha256` sai; tệp phải chép từ kho cũ sang bucket `dh-{tenant}-onboarding` rồi cập nhật `object_key` |
| `outbox_event` | Không chuyển | Sự kiện chưa phát bị bỏ (đếm và báo); sự kiện mới theo EVT-01-* |
| (không có) | `security_level = L1`, `system_type = PROVINCIAL`, `roles = {CONSUMER}` | Giá trị chờ khai lại; L1 thấp nhất để không nới quyền khi chưa biết cấp độ thật |

: Ánh xạ bảng schema ph01 cũ của apps/control

Sau khi chạy, bốn bảng cũ đổi tên `application_legacy_w1`, `application_audit_legacy_w1`, `application_attachment_legacy_w1`, `outbox_event_legacy_w1` để giữ bằng chứng; cột `client_secret_sealed` không còn. Thông báo đối soát của changeset nêu số HTTT, đầu mối, tệp, dòng lịch sử, bí mật đã xóa, sự kiện chưa phát bị bỏ và số HTTT `ACTIVE` chưa có định danh mới.

### 8.2. Mô hình dữ liệu của SRS cũ trong repo

SRS cũ ([`docs/07-srs/SRS-PH-01-onboarding.md`](../../../docs/07-srs/SRS-PH-01-onboarding.md) M4) vẽ 13 thực thể bằng tên tiếng Việt; chưa có bảng vật lý tương ứng ngoài W1. Bảng sau cho biết mỗi thực thể cũ nằm ở đâu trong thiết kế mới.

| Thực thể cũ | Bảng mới | Chuyển đổi chính |
|---|---|---|
| `HO_SO_KET_NAP` | `member_system` (giai đoạn `DRAFT` đến `APPROVED`) | Không tách bảng để một HTTT có một danh tính xuyên suốt; `ma_he_thong_de_xuat` thành `code`; `nguoi_nop`, `nop_luc` thành `submitted_by`, `submitted_at`; `hoan_tat_luc` thành `approved_at` |
| `DU_LIEU_DE_NGHI` | `data_demand` | `can_cu_phap_ly` (văn bản) tách thành `legal_doc_no`, `legal_issued_on`, `legal_issuer`, `legal_attachment_id`; `ket_luan_tham_dinh` thành `verdict`; `pham_vi_duoc_duyet` thành `scope_approved`; `y_kien_tham_dinh` thành `opinion` |
| `HO_SO_KY_THUAT` | `technical_profile` | `nhom_de_xuat`, `nhom_xac_nhan` thành `proposed_group`, `confirmed_group`; `khoi_luong_du_kien` thành `expected_daily_calls`; `giao_thuc_ho_tro` (jsonb) thành `protocols` (mảng); `max_ket_noi_dong_thoi` thành `max_concurrent_connections` |
| `BUOC_THAM_DINH` | `review_step` | Bỏ `thu_tu`; thêm `revision_no`, `due_at`, `paused_millis`, `input_hash`; `nguoi_xu_ly` thành `assignee_id`, `finished_by` |
| `TAI_LIEU_DINH_KEM` | `attachment` | `minio_uri` thành `object_key` ở Garage (ADR-008); `kich_thuoc` thành `size_bytes`; thêm `sha256`, `scan_status` |
| `HE_THONG_THANH_VIEN` | `member_system` | `nhom_he_thong` thành `technical_profile.confirmed_group`; `bat_buoc_mtls` không lưu, suy ra từ mức phân loại cao nhất trong trần (BR-01-019); `client_id_ph12` thành `app_credential.client_id`; `ra_soat_gan_nhat` thành `last_access_review_at` |
| `PHAM_VI_DUOC_CAP` | `scope_ceiling` | `ma_pham_vi` thành `data_type` và `scope_approved`; `hieu_luc_den` thành `legal_valid_until`; `dang_su_dung` thành `in_use`; `so_lan_dung_ky_nay` thành `access_review_item.usage_in_period` |
| `LICH_SU_TRANG_THAI` | `state_history` | Thêm `subject_type` để ghi cả định danh và trần |
| `BAN_GIAO` | `handover` | `token_mot_lan` thành `link_hash` (chỉ băm, không lưu mã); `het_han`, `da_mo_luc`, `nguoi_mo`, `dia_chi_ip` thành `expires_at`, `opened_at`, `opened_by`, `opened_ip` (kiểu `inet`); thêm `wrap_token_sealed`, `failed_attempts` |
| `KET_QUA_KIEM_THU` | `sandbox_test` | `xac_thuc_ok`, `goi_api_ok` thành `auth_ok`, `api_ok`; thêm `call_count`, `success_count`, `source` |
| `DON_VI` | Không lưu | Tổ chức do PH-20 sở hữu (DD-02); PH-01 giữ `owner_org_id` |
| `DAU_MOI` | `contact` | Gắn với HTTT thay vì đơn vị; `cong_khai` thành `is_public`; `la_chinh` bỏ (mỗi HTTT cần ít nhất một đầu mối kỹ thuật đang hoạt động, kiểm khi nộp và kích hoạt) |
| `RA_SOAT_QUYEN` | `access_review_item` và `access_review_cycle` | `ky_ra_soat` thành `cycle_code`; `phan_hoi_don_vi` thành `owner_response`; `ket_luan` thành `decision` |

: Ánh xạ mô hình dữ liệu SRS cũ

### 8.3. Application của APIM, publisher và subscriber của Hub

Các mục `LGC-APIM-019` (danh sách Application), `LGC-APIM-020` (tạo Application), `LGC-HUB-010` (publisher), `LGC-HUB-011` (subscriber) của D00-03 nâng cấp thành HTTT thành viên có hồ sơ kết nạp. Lược đồ CSDL chi tiết của APIM và Hub chưa có trong tài liệu được cấp (giả định: tỉnh xuất danh sách ra CSV, XLSX hoặc JSON theo ADR-056), nên di trú là nhập có xem trước qua `legacy_import_job` (FR-01-048), không chép bảng; không thông tin xác thực nào được mang sang.

| Nguồn hệ cũ | Cột hệ cũ | Đích | Ghi chú |
|---|---|---|---|
| Application (APIM) | Tên, mô tả | `member_system.name`, `description` | `code` đề xuất từ tên chuẩn hóa, người dùng sửa được |
| Application (APIM) | Loại | `system_type`, `roles = {CONSUMER}` | |
| Application (APIM) | Client ID | `member_system.legacy_ref` | Chỉ để đối chiếu, không làm `client_id` mới; chỉ mục duy nhất `(tenant_id, legacy_ref)` chặn nhập trùng |
| Application (APIM) | Consumer Key, Secret, khóa | Bỏ qua | Không di trú bí mật (BR-01-033); chỉ đếm vào `legacy_import_job.dropped_columns` |
| Publisher (Hub) | Tên, kiểu giao tiếp | `name`, `roles = {PUBLISHER}` | Kiểu giao tiếp chuyển PH-10; khóa tham chiếu bỏ qua |
| Subscriber (Hub) | Tên, đánh dấu "là luồng" | `name`, `roles = {SUBSCRIBER}` | Subscriber là luồng ghi chú để PH-04, PH-10 xử lý (D02-07 §5) |
| Chung | Đơn vị, người liên hệ | `owner_org_id` đề xuất, `contact` đề xuất | Người liên hệ thành đầu mối `TECHNICAL` nếu thư công vụ hợp lệ |

: Ánh xạ cột hệ cũ APIM và Hub sang HTTT thành viên

Bản ghi trùng giữa ba nguồn được gộp thành một HTTT nhiều vai trò theo `legacy_ref` hoặc tên chuẩn hóa. Xem trước lưu ở `legacy_import_job.preview` (có CHECK chặn khóa tên bí mật); xác nhận tạo mọi hồ sơ `DRAFT` trong một giao dịch hoặc không tạo gì.

### 8.4. Đối soát sau di trú

Báo cáo đối soát nghiệm thu bước di trú của SDD §13.1 liệt kê:

- Số bản ghi hệ cũ đọc được, số `member_system` đã tạo (`legacy_ref IS NOT NULL`), số trùng bỏ qua, số cảnh báo, số giá trị giống bí mật đã bỏ (`legacy_import_job`).
- Số HTTT `ACTIVE` chưa có `app_credential` (cần cấp lại định danh qua kết nạp): `SELECT … FROM member_system m WHERE status = 'ACTIVE' AND NOT EXISTS (SELECT 1 FROM app_credential c WHERE c.member_system_id = m.id)`.
- Số HTTT còn `owner_org_id = 'CHUA-GAN'` hoặc `security_level = 'L1'` chờ khai lại.
- Số tệp `scan_status = 'PENDING'` chờ quét lại sau khi chép sang bucket mới.
- Xác nhận không còn cột tên bí mật ở schema `ph01` cũ và `ph01_onboarding` (bài kiểm M16 và khối 40).

## 9. Câu hỏi mở

> **Câu hỏi mở Q01-50:** Trần phạm vi (`scope_ceiling.scope_approved`) và phạm vi đề nghị (`data_demand.scope_requested`) là văn bản tự do tối đa 200 ký tự theo FRS, nên CSDL chỉ bảo đảm trần bằng đúng phạm vi đã duyệt khi tạo; việc thu hẹp ("tập con", ERR-01-037) và so với scope của định danh, đăng ký ở PH-02 phải so chuỗi ở dịch vụ, dễ sai. Đề xuất: PH-02 hoặc PH-07 cấp mã phạm vi có cấu trúc (danh sách mã scope), `scope_approved` đổi sang mảng mã, kiểm tập con bằng toán tử mảng `<@` ở CSDL. Cần chốt với PH-02, PH-12 (tên scope) trước khi chốt D03-04-PH01.

> **Câu hỏi mở Q01-51:** Dữ liệu liên hệ cá nhân của đầu mối (mức Hạn chế) đang giữ vĩnh viễn cùng hồ sơ theo BR-01-011, kể cả HTTT đã chấm dứt. Luật BVDLCN 91/2025 yêu cầu xóa hoặc ẩn danh khi hết mục đích. Đề xuất giả định: giữ 5 năm sau `terminated_at` (cùng thời hạn WORM kiểm toán) rồi ẩn danh `full_name`, `email`, `phone`, `search_text` bằng tác vụ của `ph01_owner`, giữ `contact_type`, `id`, thời điểm; cần Cán bộ ATTT và pháp chế xác nhận thời hạn và có áp dụng mã hóa trường (SEC-31) cho các cột này không (liên quan Q01-29 của SDD).

> **Câu hỏi mở Q01-52:** Thư mang liên kết (bàn giao, phiếu xác nhận) không được đi qua `notify_outbox` vì liên kết gốc không lưu ở bất kỳ bảng nào (`ck_notify_outbox_no_link`); thiết kế hiện gửi thẳng qua `NotifyPort` đồng bộ và nếu PH-18 lỗi thì người dùng bấm "Tạo lại liên kết". Cần PH-18 xác nhận `NotifyPort` có chế độ gửi đồng bộ trả lỗi tức thì cho loại thư này, hoặc chấp nhận để PH-18 giữ liên kết ngắn hạn; nếu không, `notify_outbox` phải có cột mã hóa chứa liên kết và quy tắc xóa sau khi gửi.

> **Câu hỏi mở Q01-53:** Chính sách di trú dữ liệu W1 (`apps/control`): hồ sơ `SUBMITTED`, `REVIEWED` đưa về `DRAFT` (lệch SDD §2.4), HTTT `ACTIVE` cũ được miễn kiểm thử SANDBOX và giữ `ACTIVE` dù chưa có định danh mới, cấp độ ATTT đặt `L1` chờ khai lại. Cần chủ đầu tư xác nhận dữ liệu W1 chỉ là dữ liệu thử nghiệm (nếu có dữ liệu thật của tỉnh, các hồ sơ `ACTIVE` phải được tạm ngừng cho tới khi cấp lại định danh) và quyết định có giữ hay hủy bảng `*_legacy_w1` sau thời gian chạy song song.

> **Câu hỏi mở Q01-54:** Sáp nhập tenant (D03-10 §5.4): chỉ mục duy nhất `(tenant_id, code)` và quy tắc mã bất biến (BR-01-018) xung đột khi hai tỉnh có cùng mã HTTT, còn D03-10 yêu cầu ghi `origin_tenant_id` cho mọi bản ghi được chuyển. Thiết kế hiện chỉ ghi `member_system.origin_tenant_id`; bảng con kế thừa qua khóa ngoại, `app_credential` được cấp mới. Cần PH-18 chốt cách xử lý xung đột mã (đề xuất hậu tố theo mã tenant nguồn, ví dụ `HT-TUPHAP-T68`) và có cần thêm `origin_tenant_id` cho `data_demand`, `scope_ceiling`, `review_step`, `state_history` để truy vết bằng chứng thẩm định không.

Câu hỏi Q01-57 của tập API (bảng `background_job` cho tác vụ nền xuất tệp, API-01-088) cũng cần kết luận trước khi chốt số bảng của phân hệ; tập này chỉ ghi nhận ở đề nghị đồng bộ số 12 chứ không tạo câu hỏi mở thứ hai cho cùng việc.

## Đề nghị đồng bộ

Các việc dưới đây thuộc tài liệu dùng chung hoặc phân hệ khác, nằm ngoài quyền sửa của tập này; ghi lại để đợt đồng bộ cuối thực hiện.

| # | Tài liệu | Đề nghị |
|---|---|---|
| 1 | D02-07 | DD-12: ghi PH-01 dùng tên bảng `attachment` thay `file_object`. DD-05: thêm trạng thái kỹ thuật `PENDING` (bước `RECORD` của saga). DD-03: thêm thuộc tính kỹ thuật `review_stage`, `provision_stage`, `enforcement`, `revision_no`, `origin_tenant_id`; DD-04: đổi `position` thành `job_title` |
| 2 | D02-03-PH01 (FRS) | EN-01-09 thêm `wrap_token_sealed` và trạng thái `OPENING` (trùng đề nghị của SDD); EN-01-10 thêm `source`, `success_count`; EN-01-04 ghi trần là văn bản ≤ 200 ký tự (Q01-50); EN-01-18 thêm `content_version` và mẫu mặc định ở tenant `COMMON` |
| 3 | D03-04-PH01 (API) | **Đã đồng bộ ở bản 0.2 cho phần lũy đẳng:** lỗi lệch thân là ERR-01-051, đang xử lý là ERR-01-054. Còn lại: `ETag` là `version`; `Idempotency-Key` giữ 24 giờ và không áp dụng cho tuyến mở bàn giao; khóa lũy đẳng saga `sagaId:bước`; người nhận bàn giao phải là đầu mối kỹ thuật đang hoạt động có `user_account_id` (ERR-01-003) |
| 4 | D03-09 | Debezium: `publication` chỉ gồm `ph01_onboarding.outbox`, tài khoản sao chép riêng; vai trò `dh_connect_app`, `dh_connect_migrator`; Kafka: số phân vùng, thời hạn giữ của 15 topic `connect` (mục 6.2); bucket `dh-{tenant}-onboarding` và bucket nền tảng chứa mẫu; định cỡ CSDL dưới 1 GiB mỗi năm (mục 1.5) |
| 5 | D03-10 §5.4 | Sáp nhập tenant: quy tắc `origin_tenant_id` của PH-01 và cách xử lý trùng mã HTTT (Q01-54) |
| 6 | D03-07 | SEC-33, SEC-81: ghi các ràng buộc CSDL của PH-01 (`secret_ref` khớp mẫu, không cột bí mật, bàn giao chỉ lưu băm) làm bằng chứng kiểm tra; thêm ca quét cột bí mật ở schema vào kịch bản kiểm thử THR liên quan |
| 7 | D05-02-PH01 (test case) | Chuyển 207 khối cô lập và nghiệp vụ, 19 khối di trú thành ca kiểm thử tự động trong CI (`TenantIsolationIT` đã có tên ở SDD §12; `MigrationIT` là tên đề xuất); thêm ca canary quét CSDL |
| 8 | Tập PH-18 | Công cụ chuyển dữ liệu khi sáp nhập; tác vụ dọn lưu giữ (mục 7); `NotifyPort` đồng bộ cho thư có liên kết (Q01-52); tham số `onboarding.*` ở DD-14 |
| 9 | Tập PH-02, PH-12 | Mã phạm vi có cấu trúc cho trần (Q01-50); tên scope của client |
| 10 | D00-04 §2 | PH-01: cột "Tài liệu" thành "FRS 0.1, UC 0.1, SDD 0.1, CSDL 0.1" |
| 11 | `ph07/tools/gen_liquibase.py` | Tham số hóa tên phân hệ, tên tệp DDL và tác giả changeset để PH-01 (và PH-04, PH-05) sinh changelog Liquibase từ `ddl/ph01_*.sql` |
| 12 | D03-04-PH01 (API), Q01-57 | API-01-088 (`GET /jobs/{jobId}`) tra tác vụ nền xuất tệp cần nơi lưu trạng thái; tập CSDL chưa có bảng nào cho việc này (26 bảng hiện tại không đủ). Nếu hội đồng chọn thêm bảng `background_job` thì lập theo mẫu `legacy_import_job` (mục 3.21): `id`, `tenant_id`, `kind`, `status`, `requested_by`, `object_key`, `row_count`, `expires_at`, cột chuẩn; RLS mẫu P; bucket `dh-{tenant}-onboarding` mã hóa, giữ 7 ngày; thêm vào ERD hình 2, DDL `ph01_20_demand_review.sql` hoặc tệp mới và bài kiểm tra cô lập. Chưa làm ở bản 0.2 vì chờ quyết định Q01-57 (thêm bảng hay xuất đồng bộ giới hạn 20.000 dòng) |
| 13 | Đề xuất ADR (chưa cấp số) | Bổ sung vào ba đề xuất của SDD §14 mục 10 một đề xuất (d): **lớp phòng thủ thứ hai ở CSDL** cho quy tắc bốn mắt, máy trạng thái và không lưu bí mật (CHECK, trigger, quyền cột, bài kiểm thử cấu trúc), dùng làm mẫu cho PH-12, PH-20 |

: Đề nghị đồng bộ với tài liệu dùng chung và phân hệ khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-CSDL và quy chuẩn trình bày: 26 bảng schema `ph01_onboarding`, ràng buộc bốn mắt và máy trạng thái ở CSDL, không lưu bí mật, RLS mẫu P và S, DDL chạy thử trên PostgreSQL 16.16 (207 khối kiểm cô lập, nghiệp vụ và 19 khối kiểm di trú đạt), ánh xạ ba nguồn dữ liệu hệ cũ, 5 câu hỏi mở Q01-50…54 |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà soát chéo: sửa mã lỗi lũy đẳng (ERR-01-051, 054) ở mục 3.25 và DDL; ghi nhận thiếu bảng background_job cho API-01-088 ở đề nghị đồng bộ số 12 |
