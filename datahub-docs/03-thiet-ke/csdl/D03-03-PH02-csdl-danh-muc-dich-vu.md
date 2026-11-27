---
ma_tai_lieu: D03-03-PH02
ten: Thiết kế cơ sở dữ liệu phân hệ PH-02 Danh mục dịch vụ
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-connect, DBA, cán bộ ATTT, hội đồng thẩm định
phan_he: PH-02
mo_ta: Thiết kế cơ sở dữ liệu của phân hệ Danh mục dịch vụ gồm 45 bảng cho danh mục API, phiên bản, đặc tả, gói, đăng ký sử dụng, duyệt bốn mắt, SLA và đồng bộ quốc gia, kèm ràng buộc, RLS theo tenant, DDL đã chạy thử, sao lưu và ánh xạ dữ liệu hệ cũ.
tai_lieu_lien_quan: D02-03-PH02 FRS; D02-04-PH02 Use case; D03-02-PH02 SDD; D03-10 Đa tenant; D02-07 Từ điển dữ liệu
---

# D03-03-PH02 · Thiết kế CSDL Danh mục dịch vụ

## Tóm tắt cho hội đồng thẩm định

PH-02 là nơi giữ **hợp đồng** giữa bên cung cấp và bên khai thác dữ liệu: API nào được công bố, theo đặc tả nào, ai được gọi, theo điều kiện nào. Vì vậy cơ sở dữ liệu của phân hệ phải làm được hai việc mà một bảng danh sách thông thường không làm: **giữ bằng chứng không sửa được** (đặc tả đã duyệt, ai đã duyệt, ai đã đăng ký dùng gì, mã nào đã từng dùng) và **chặn ngay ở tầng dữ liệu** những thao tác mà quy tắc nghiệp vụ cấm, để một lỗi ở tầng dịch vụ không thể làm hỏng hợp đồng.

Schema `ph02_catalog` trên cụm `pg-core` gồm **45 bảng** cho 13 thực thể của [D02-03-PH02](../../02-yeu-cau/frs/D02-03-PH02-frs-danh-muc-dich-vu.md) §4.2. Bốn điểm chính:

1. **Nội dung đặc tả không nằm trong CSDL.** Đặc tả OpenAPI nằm ở kho đối tượng, CSDL chỉ giữ khóa đối tượng và băm SHA-256; bảng đặc tả chỉ cho thêm, không sửa, không xóa (BR-02-014). Kết quả quét bí mật chỉ giữ dấu vân tay 16 ký tự, không giữ chuỗi khớp (NFR-02-012), và các bảng sự kiện, lệnh chờ đều có ràng buộc chặn khóa tên bí mật.
2. **Quy tắc nghiệp vụ trọng yếu được khóa ở CSDL.** Kiểu xác thực của gói không yếu hơn mức phân loại dữ liệu (SEC-24); người duyệt khác người gửi và khác người sửa đặc tả, SV không duyệt công bố, API Nhạy cảm cần hai chữ ký (BR-02-008); mỗi HTTT chỉ một đăng ký hiệu lực cho một phiên bản (BR-02-027); mỗi số chính chỉ một phiên bản đang chạy (BR-02-035); mã API, mã gói, số hiệu phiên bản không dùng lại (BR-02-021); backend không có trường địa chỉ tự do (BR-02-023).
3. **Cách ly tenant bằng `FORCE ROW LEVEL SECURITY`** trên 44 trong 45 bảng (bảng còn lại là khóa tác vụ định kỳ, không có dữ liệu nghiệp vụ). Mọi khóa ngoại đều kèm `tenant_id` nên không thể trỏ chéo tenant dù biết mã định danh; bảng phân vùng chỉ truy cập qua bảng cha. Bộ luật kiểm tra đặc tả dùng chung toàn nền tảng ở tenant `COMMON`, tỉnh đọc được nhưng không ghi được.
4. **Lưu giữ khớp NFR-02-017.** Đặc tả, phiên bản, đăng ký, lịch sử vòng đời, cam kết SLA giữ vĩnh viễn; kỳ SLA 3 năm; bản ghi đồng bộ quốc gia 5 năm; thông báo 2 năm; kết quả kiểm tra đặc tả 1 năm (phân vùng tháng, bỏ phân vùng để dọn).

Căn cứ pháp lý của việc giữ bằng chứng: CMP-LAW-03 và CMP-LAW-19 (công bố, đăng ký danh mục dịch vụ chia sẻ dữ liệu), CMP-LAW-08 (TCVN 14423:2026: nhật ký, tách nhiệm vụ), CMP-LAW-05 (khai báo mục đích và căn cứ khi khai thác dữ liệu cá nhân, bảng `subscription`).

DDL [`ph02/ddl/ph02_all.sql`](ph02/ddl/ph02_all.sql) đã chạy thử trên PostgreSQL 16.16 sạch; bài kiểm [`ph02/test/ph02_isolation_test.sql`](ph02/test/ph02_isolation_test.sql) đạt 77/77 điểm kiểm (§4.2). Dữ liệu cũ của bản W1 (`ph02.api_service`) có changeset di trú riêng đã chạy thử (§8.2).

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả lược đồ dữ liệu của PH-02 trong schema `ph02_catalog` của `pg-core`: chiến lược lưu trữ và cách ly tenant, sơ đồ thực thể – quan hệ, 45 bảng, DDL và changelog, dữ liệu khởi tạo, kho ngoài PostgreSQL, sao lưu và lưu giữ, ánh xạ dữ liệu hệ cũ. Nội dung đặc tả (OpenAPI) nằm ở kho đối tượng, không nằm trong CSDL; sự kiện và lệnh chờ chỉ lưu ở các bảng hộp gửi, hộp nhận.

### 0.2. Người đọc

Bảng dưới nêu từng nhóm người đọc cần đọc phần nào của tập API.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-connect` | Chương 1, 3, 4 |
| DBA, vận hành | Chương 1, 4, 6, 7 |
| Cán bộ ATTT | Mục 1.2, 1.4, các bảng `lint_finding`, `subscription`, `review_decision`, `outbox_event`, chương 7 |
| Hội đồng thẩm định | Tóm tắt, chương 2, mục 1.4, chương 8 |

: Người đọc và phần cần đọc

### 0.3. Thuật ngữ và chữ viết tắt

Thuật ngữ dùng chung với [D02-03-PH02](../../02-yeu-cau/frs/D02-03-PH02-frs-danh-muc-dich-vu.md) §1.4; kiểu dữ liệu chuẩn theo D00-01 §5 (`T-ID` là `uuid`, `T-TS` là `timestamptz`, `T-MONEY` là `numeric(19,0)`, `T-ENUM` là `varchar` kèm `CHECK`). Hai thuật ngữ riêng của tài liệu này: **chỉ thêm** (append-only) là bảng bị chặn UPDATE, DELETE bằng trigger và thu quyền; **khóa ngoại kép** là khóa ngoại có cột `tenant_id` đi kèm khóa chính của bảng cha.

### 0.4. Tài liệu tham chiếu

D02-03-PH02 (FRS), D02-04-PH02 (use case), D03-02-PH02 (SDD, các mục 4.1, 8, 9), D03-10 (thiết kế đa tenant, mẫu RLS P và S), D02-07 (từ điển dữ liệu), ADR-003 (PostgreSQL và RLS), ADR-042 (hộp gửi, hộp nhận), ADR-046 (phê duyệt bốn mắt).

### 0.5. Cấu trúc tài liệu

Chương 1 nêu chiến lược lưu trữ và cách ly tenant; chương 2 là sơ đồ thực thể – quan hệ; chương 3 đặc tả 45 bảng, mỗi bảng mở đầu bằng bảng đặc tả 10 mục (Mục đích, FR phục vụ, Khóa chính, Duy nhất, Khóa ngoại, Ràng buộc CHECK, Chỉ mục, Cách ly tenant, Phân vùng và chỉ thêm, Ghi chú) trích từ DDL đã chạy thử, rồi đến danh sách cột; chương 4 là DDL và changelog; chương 5 dữ liệu khởi tạo; chương 6 kho ngoài PostgreSQL; chương 7 sao lưu và lưu giữ; chương 8 ánh xạ dữ liệu hệ cũ; chương 9 câu hỏi mở.

## 1. Chiến lược lưu trữ

Chương này nói dữ liệu của PH-02 nằm ở đâu, ai được đọc ghi, cách ly tenant ra sao và những quy tắc nghiệp vụ nào được khóa ngay ở CSDL. Nguyên tắc xuyên suốt: CSDL là chốt chặn thứ hai sau dịch vụ; kiểm tra ở dịch vụ cho thông báo lỗi thân thiện, ràng buộc ở CSDL bảo đảm không có đường vòng.

### 1.1. Schema, vai trò và kết nối

Schema `ph02_catalog` (quy ước `ph{nn}_{miền}`) do `ph02_owner` (NOLOGIN) sở hữu và nằm trên cụm `pg-core` của mặt phẳng điều khiển (vùng Z5), cùng cụm với PH-01 và PH-03 vì cùng đơn vị triển khai `dh-connect`. Mỗi module chỉ đọc ghi schema của mình: PH-02 lấy thông tin HTTT qua `SystemDirectoryApi` (trong tiến trình, dùng bản sao đệm của PH-01) và không truy vấn schema của PH-01 hay PH-03.

| Vai trò | Loại | Quyền | Dùng bởi |
|---|---|---|---|
| `ph02_owner` | NOLOGIN, chủ schema | Sở hữu bảng, hàm; chịu `FORCE RLS` như mọi vai trò | Chỉ dùng qua `SET ROLE` của migrator |
| `dh_connect_migrator` | LOGIN, thành viên `ph02_owner` | DDL, dọn và tạo phân vùng, di trú W1 | Liquibase, `PartitionMaintenanceJob` |
| `ph02_app` | NOLOGIN, `NOBYPASSRLS` | DML trên bảng; **không** UPDATE, DELETE trên 8 bảng bằng chứng; outbox chỉ UPDATE cột `published_at`; không quyền trên phân vùng | Nhóm quyền của `dh_connect_app` |
| `dh_connect_app` | LOGIN, thành viên `ph02_app` | Như `ph02_app` | Vai trò `api` và `worker` của `dh-connect` |
| `ph02_readonly` | NOLOGIN, `NOBYPASSRLS` | SELECT; không đọc `idempotency_record`, `pending_command`, `import_session` | Báo cáo, kiểm toán, PH-16 qua đọc sao |

: Vai trò CSDL của PH-02

Vai trò `lint-worker` của `dh-connect` (chạy kiểm tra đặc tả lớn ở hồ sơ `QM-LON`, `QM-CHUNG`) **không** kết nối CSDL: nó nhận đặc tả qua URL ký sẵn của kho đối tượng và trả kết quả qua API nội bộ (SDD 4.4). `dh-runtime` và APISIX cũng không kết nối `ph02_catalog`; PH-03 chỉ đọc dữ liệu công bố qua giao diện nội bộ API-02-080…084. Dịch vụ tự kiểm khi khởi động (D03-10 §3): từ chối chạy nếu vai trò kết nối có `BYPASSRLS` hoặc bảng nào của schema thiếu chính sách.

Bản W1 của `apps/control` có schema `ph02` với bảng `api_service`; schema mới đặt tên `ph02_catalog` để cùng tồn tại trong giai đoạn chuyển, rồi bảng cũ được đổi tên `api_service_legacy_w1` sau di trú (§8.2).

### 1.2. Cách ly tenant

Mọi bảng nghiệp vụ có `tenant_id varchar(16)` kèm `CHECK (tenant_id ~ '^T[0-9]{2}$')` (riêng `lint_rule` là `COMMON`) và bật `FORCE ROW LEVEL SECURITY` qua thủ tục `ph02_catalog.p_enable_rls(bảng, mẫu)`, cùng hai mẫu với PH-04, PH-05:

| Mẫu | Đọc | Ghi | Bảng |
|---|---|---|---|
| P (riêng) | Dòng của tenant phiên | Dòng của tenant phiên; dòng `COMMON` chỉ khi phiên là `PLATFORM` | 43 bảng tác nghiệp |
| S (dùng chung) | Dòng của tenant phiên và `COMMON` | Như mẫu P | `lint_rule` (bộ luật kiểm tra dùng chung) |
| Không RLS | Không có `tenant_id` | Không chứa dữ liệu nghiệp vụ | `job_lease` (khóa tác vụ định kỳ của ShedLock) |

: Cách ly tenant

Biến phiên `app.tenant_id` được đặt bằng `SET LOCAL` ở đầu mỗi giao dịch do `TenantContextFilter` lấy từ token đã xác thực, không từ tham số hay thân yêu cầu (SEC-80, SDD 6); bộ kiểm tra khi lấy kết nối từ pool từ chối biến rỗng. Chính sách đọc biến bằng `current_setting('app.tenant_id', false)` nên khi chưa đặt biến, truy vấn báo lỗi chứ không trả dòng nào. Tác vụ nền liên tenant (nhắc ngừng dùng, chốt kỳ SLA, đồng bộ quốc gia) lặp từng tenant và đặt biến trước mỗi vòng. Ba lớp bổ sung ngoài RLS:

1. **Khóa ngoại kép.** Khóa ngoại giữa các bảng nghiệp vụ luôn có dạng `(x_id, tenant_id)`, trỏ tới khóa duy nhất `(id, tenant_id)` của bảng cha. Kiểm tra khóa ngoại không bị RLS lọc, nên một dòng của tenant A không thể trỏ tới dòng của tenant B dù biết `id` (bài kiểm số 4).
2. **Phân vùng chỉ qua bảng cha.** `lint_finding`, `usage_daily`, `config_change_log` là bảng phân vùng theo tháng; RLS đặt ở bảng cha và vai trò ứng dụng không có quyền trên từng phân vùng, nên không có đường đọc thẳng phân vùng để vòng qua chính sách (bài kiểm số 6).
3. **Bộ luật dùng chung.** Bảng `lint_rule` có `CHECK (tenant_id = 'COMMON')`; tỉnh đọc 24 luật nhưng chính sách ghi chỉ cho phiên `PLATFORM`. Tỉnh chỉnh mức luật ở `lint_rule_override` của riêng mình, và trigger chỉ cho chỉnh theo đúng chính sách của từng luật (FR-02-021).

### 1.3. Quy ước bảng

Theo D00-01 §5.1: `id uuid` (UUID v7 sinh ở ứng dụng), `created_*`, `updated_*`, `version` (trigger `tg_touch` tăng `version` và đặt `updated_at`). Bảng chỉ thêm hoặc dẫn xuất có ngoại lệ có chủ đích, ghi trong bảng dưới.

| Nhóm bảng | Ngoại lệ so với cột ngữ cảnh | Lý do |
|---|---|---|
| Bảng bằng chứng: `api_spec`, `code_registry`, `api_owner_transfer`, `subscription_state_history`, `version_state_history`, `review_decision`, `sla_commitment`, `legacy_id_map` | Chỉ có `created_at`, `created_by`; không có `updated_*`, `version` | Không bao giờ sửa; thêm dòng mới thay cho sửa |
| Bảng liên kết và dẫn xuất: `api_tag`, `api_operation`, `plan_operation_scope`, `diff_result`, `idempotency_record` | Chỉ có `created_at`, `created_by` | Dựng lại khi nguồn đổi hoặc hết hạn thì xóa |
| `lint_finding`, `config_change_log` | Khóa chính `(id, thời điểm)`; không có `updated_*`, `version` | Phân vùng theo thời gian; kết quả kiểm tra chỉ đổi cột trạng thái xử lý |
| `usage_daily` | Khóa tự nhiên `(tenant, phiên bản, ngày, thao tác, HTTT)`; không có `id` | Số đo tính lại mỗi giờ |
| `inbox_event`, `outbox_event` | Khóa là `event_id`; không có cột sửa | DD-11, ADR-042 |
| `job_lease` | Không có `tenant_id`, cột theo ShedLock | Bảng kỹ thuật |

: Ngoại lệ có chủ đích so với cột ngữ cảnh

Trạng thái dùng `varchar` kèm `CHECK` liệt kê đúng FRS §4.3 đến §4.5 và SDD 8.1; thêm giá trị là một changeset mới. Mã nghiệp vụ (`api_code`, `plan_code`, `category_code`) là chữ thường, khớp mẫu `^[a-z][a-z0-9-]{n,m}$` của SDD và khác kiểu `T-CODE` chữ hoa của D00-01 §5, vì mã API là một phần của đường dẫn công bố; ghi nhận là ngoại lệ có lý do (xem đề nghị đồng bộ). Tiền chỉ có một cột, `plan.unit_price_vnd`, kiểu `T-MONEY` và chỉ là thông tin (BR-02-040).

### 1.4. Quy tắc nghiệp vụ chốt ở CSDL

Bảng dưới liệt kê ràng buộc hoặc trigger khóa từng quy tắc. Mỗi dòng có ít nhất một điểm kiểm trong bài kiểm ở §4.2. Quy tắc cần ngữ cảnh ngoài CSDL (ví dụ "đặc tả đã qua lớp 1, lớp 2", "HTTT còn ACTIVE ở PH-01") vẫn do dịch vụ kiểm, không liệt kê ở đây.

| Ràng buộc, trigger | Quy tắc | BR, FR |
|---|---|---|
| `ck_api_visibility_class` | `PUBLIC` chỉ với dữ liệu `PUBLIC`; `NATIONAL` không với `SENSITIVE` | BR-02-037; FR-02-007, 041 |
| `tg_plan_auth_policy`, `ck_plan_auth` | Kiểu xác thực tối thiểu theo mức phân loại: `INTERNAL` từ `API_KEY`; `RESTRICTED` chỉ `OAUTH2_PKJWT`, `OAUTH2_MTLS`; `SENSITIVE` chỉ `OAUTH2_MTLS`; `KEYLESS` chỉ khi API có mức hiển thị `PUBLIC`; gói đánh dấu `needs_auth_upgrade` được miễn để nhập hệ cũ | BR-02-016, SEC-24; FR-02-028 |
| `tg_api_version_guard` | Chỉ các cạnh của FRS 4.3 (gồm `PUBLISHED → RETIRED` do thay thế cùng số chính); mã API, số hiệu, số chính bất biến; đặc tả bất biến từ `PENDING` | BR-02-014, 021; FR-02-034…039 |
| `ex_api_version_one_live_per_major` | Một phiên bản `PUBLISHED`, `SUSPENDED` hoặc `DEPRECATED` mỗi (API, số chính); hoãn tới cuối giao dịch để thay thế trong một giao dịch | BR-02-035; FR-02-036, 042 |
| `ck_api_version_deprecated`, `_suspended`, `_retired`, `_published`, `_spec` | `DEPRECATED` có hạn `sunset_at`; `SUSPENDED` có thời điểm tạm ngừng; `RETIRED` có `retired_at`; phiên bản đã gửi duyệt phải có đặc tả hiện hành | BR-02-004, 034; FR-02-037…039 |
| `tg_api_spec_append_only`, thu quyền, `ck_api_spec_size`, `ck_api_spec_ops` | Đặc tả chỉ thêm; không quá 50 MiB và 5.000 thao tác | BR-02-014; NFR-02-011 |
| `uq_code_registry` (chỉ thêm) | Mã API, số hiệu phiên bản, mã gói, mã nhóm không dùng lại | BR-02-021; FR-02-010, 027, 042 |
| `uq_context_path`, `ck_context_path_format`, `ck_context_path_major_suffix`, `released_after` | Context-path duy nhất trong tenant, đúng `/{nhóm}/{mã API}/v{số chính}`, giữ chỗ 12 tháng sau `RETIRED` | BR-02-022; FR-02-024 |
| `ck_backend_target_shape`, `ck_backend_no_free_url` | Backend chỉ trỏ kết nối PH-05 hoặc luồng PH-04, không có địa chỉ tự do | BR-02-023; FR-02-022 |
| `uq_subscription_one_effective`, `fk_subscription_plan` | Mỗi HTTT một đăng ký hiệu lực cho một phiên bản; đăng ký khớp phiên bản của gói | BR-02-027; FR-02-046 |
| `ck_subscription_legal_basis` | Dữ liệu cá nhân hoặc từ mức Hạn chế phải nêu căn cứ pháp lý | BR-02-012; FR-02-046 |
| `ck_subscription_four_eyes`, `ck_review_decision_four_eyes`, `tg_review_decision_independent`, `tg_review_request_approve_gate` | Người duyệt khác người gửi và người sửa gần nhất; SV không duyệt công bố; API `SENSITIVE` cần CA và TA là hai người | BR-02-008, 026; FR-02-035, 047 |
| `uq_review_request_one_open` | Một yêu cầu duyệt `OPEN` mỗi đối tượng | BR-02-008; FR-02-034 |
| `ck_*_state_history_reason`, `tg_*_append_only` | Mọi chuyển trạng thái có lý do và lưu lịch sử không sửa được | BR-02-028 |
| `ck_change_notice_mandatory` | Chỉ thông báo tay `ANNOUNCEMENT` là không bắt buộc | BR-02-029; FR-02-057 |
| `ck_sla_commitment_worsen`, `ck_sla_period_met`, `uq_sla_period_current` | Cam kết kém đi báo trước tối thiểu 7 ngày; kỳ thiếu dữ liệu là `INSUFFICIENT` và không có `met`; mỗi kỳ một kết quả hiện hành | BR-02-013, 029, 031; FR-02-055, 056 |
| `uq_national_sync_record_pending`, `ck_national_sync_record_acked`, `_rejected` | Xếp hàng lặp vô hại; `ACKED` có mã quốc gia; `REJECTED` có lý do | BR-02-009; FR-02-053, 054 |
| `ck_lint_finding_secret`, `ck_outbox_event_no_secret`, `ck_pending_command_payload` | Không lưu chuỗi bí mật hay nội dung đặc tả ở kết quả, sự kiện, lệnh chờ | BR-02-015; NFR-02-012; FR-02-018 |
| `tg_lint_rule_override_policy`, `ck_lint_rule_secret_fixed` | Luật cấu trúc không hạ mức; mẫu quét bí mật cố định `ERROR` | FR-02-021 |
| `ck_api_flow_ref`, `ck_api_legacy` | API từ luồng có tham chiếu luồng; API hệ cũ có mã cũ | BR-02-030, 036; FR-02-013, 061 |
| `ck_outbox_event_topic_tenant` | Topic mang đúng mã tenant | D03-10; EVT-02-01…16 |
| `tg_config_epoch_monotonic` | `source_version` chỉ tăng | NFR-02-005; FR-02-059 |
| `ck_plan_price` | Đơn giá không âm và chỉ là thông tin | BR-02-040 |

: Quy tắc nghiệp vụ chốt ở CSDL

Hai quy tắc của SDD 4.1 **không** thể chốt ở CSDL và do dịch vụ giữ, có kiểm thử đua: "không `RETIRED` khi còn đăng ký hiệu lực" (BR-02-006, tuần tự hóa bằng `FOR UPDATE` dòng phiên bản và `FOR SHARE` ở đăng ký) và "phiên bản chỉ sang `PENDING` khi có backend `ACTIVE` và gói" (BR-02-024, do `SubmissionGate`), vì cả hai cần đếm dòng ở bảng khác trong cùng khoảnh khắc và `CHECK` không làm được.

### 1.5. Định cỡ

Định cỡ theo giả định GĐ-02-01 của FRS (tỉnh vừa sau năm đầu: 180 API, 400 phiên bản, 360 gói, 640 đăng ký) và trần NFR-02-010 (2.000 API, 20.000 đăng ký). Số dòng của bảng còn lại là **giả định** từ nhịp thao tác dự kiến (SDD 11), thay bằng số đo ở môi trường thử khi có.

| Bảng | Tỉnh vừa (sau năm đầu) | Trần thiết kế | Cơ sở |
|---|---|---|---|
| `api`, `api_search_doc` | 180 | 2.000 | GĐ-02-01; NFR-02-010 |
| `api_version`, `api_spec`, `backend` | 400, 400, 800 | 4.000, 8.000, 8.000 | GĐ-02-01; hai backend mỗi phiên bản (giả định); đặc tả chỉ thêm: tối đa 2 bản mỗi phiên bản trước khi gửi duyệt |
| `plan` | 360 | 3.600 | GĐ-02-01 |
| `subscription` | 640 | 20.000 | GĐ-02-01; NFR-02-010 |
| `api_operation` | 10.000 | 100.000 | 25 thao tác mỗi phiên bản (SDD 11) |
| `lint_finding` | 36.000 mỗi năm | 360.000 mỗi năm | 3 lần kiểm tra lưu mỗi phiên bản, 30 phát hiện mỗi lần (giả định, GĐ-02-03); giữ 1 năm |
| `version_state_history`, `subscription_state_history` | 2.400; 2.000 | 24.000; 60.000 | 6 chuyển trạng thái mỗi phiên bản; 3 mỗi đăng ký |
| `usage_daily` | 1,2 triệu mỗi năm | 12 triệu mỗi năm | 640 đăng ký × 5 thao tác × 365 ngày; giữ 2 năm (giả định, Q02-50) |
| `config_change_log` | 3.000 | 30.000 | 100 thay đổi mỗi ngày × 30 ngày (SDD 4.10, nhịp vài lần mỗi phút lúc cao điểm) |
| `outbox_event` | 6.000 | 60.000 | 2.000 sự kiện mỗi ngày × 3 ngày giữ |
| Các bảng còn lại | Dưới 10.000 dòng mỗi bảng | Dưới 100.000 dòng mỗi bảng | Số đối tượng tương ứng |

: Định cỡ số dòng (giả định)

Với kích thước dòng trung bình 1 KiB (giả định), schema dưới 1 GiB ở tỉnh vừa và khoảng 10 GiB ở trần, trong đó `usage_daily` chiếm phần lớn khi giữ đủ hai năm. Con số này khớp SDD 11 và nhỏ so với dung lượng một ô CSDL (mỗi ô khoảng 8 đến 10 tenant ở hồ sơ `HT-B`, D03-09), nên PH-02 không cần cụm riêng.

## 2. Sơ đồ thực thể – quan hệ

Quan hệ được vẽ thành ba sơ đồ theo vùng nghiệp vụ để chữ đủ lớn trên trang A4: danh mục và đặc tả, gói và đăng ký và duyệt, công bố và SLA và đồng bộ. Sơ đồ chỉ vẽ khóa ngoại thật và vài liên kết theo mã (đường chấm); cột và ràng buộc ở chương 3. Cả ba sơ đồ có chung nút `api_version`, vì phiên bản là gốc của vòng đời (FRS 4.3).

```{.mermaid caption="Sơ đồ thực thể – quan hệ: danh mục và đặc tả"}
erDiagram
  category ||--o{ category : "cha - con"
  category ||--o{ api : "phân loại"
  api ||--o{ api_tag : "thẻ"
  api ||--|| api_search_doc : "chỉ mục tìm kiếm"
  api ||--o{ api_owner_transfer : "chuyển chủ quản"
  api ||--o{ context_path_reservation : "đường dẫn theo số chính"
  api ||--o{ api_version : "phiên bản"
  api_version ||--o{ api_spec : "đặc tả (chỉ thêm)"
  api_version }o--o| api_spec : "đặc tả hiện hành"
  api_version }o--o| api_version : "kế nhiệm"
  api_version ||--o{ backend : "backend"
  api_spec ||--o{ api_operation : "thao tác"
  api_spec ||--o{ lint_finding : "phát hiện"
  lint_rule ||--o{ lint_rule_override : "mức theo tenant"
  lint_finding }o..o| lint_rule : "mã luật"
  diff_result }o..o{ api_spec : "cặp băm"
```

Sơ đồ cho thấy API chỉ giữ nhận diện và phân loại, còn đặc tả, backend và trạng thái nằm ở phiên bản. Hai đường giữa `api_version` và `api_spec` khác nhau về ý nghĩa: một-nhiều là mọi đặc tả từng nạp (không xóa), còn đường tới đặc tả hiện hành là khóa ngoại hoãn, chỉ đổi khi còn `DRAFT`. `diff_result` không có khóa ngoại mà khóa theo cặp băm của đặc tả đã gộp, nên một kết quả dùng lại cho mọi cặp phiên bản có cùng nội dung. `lint_rule` là bảng dùng chung (`COMMON`); `lint_finding` ghi mã luật dạng chuỗi chứ không khóa ngoại để kết quả cũ còn nguyên khi bộ luật đổi.

```{.mermaid caption="Sơ đồ thực thể – quan hệ: gói, đăng ký, duyệt và lịch sử"}
erDiagram
  api_version ||--o{ plan : "gói sử dụng"
  plan ||--o{ plan_operation_scope : "thao tác cho phép"
  plan ||--o{ subscription : "đăng ký"
  api_version ||--o{ subscription : "khóa ngoại ba cột"
  subscription ||--o{ subscription_state_history : "lịch sử"
  subscription ||--o{ grant_job : "cấp, thu hồi quyền"
  api_version ||--o{ version_state_history : "lịch sử"
  api_version ||--o{ version_contributor : "người tạo, sửa, gửi"
  api_version ||--o{ review_request : "yêu cầu duyệt"
  review_request ||--o{ review_decision : "quyết định từng người"
  api_version ||--o{ deprecation_reminder : "mốc nhắc ngừng dùng"
  plan }o--o| plan : "sao chép từ"
```

Bốn nhóm quan hệ cần chú ý. Khóa ngoại ba cột `(plan_id, api_version_id, tenant_id)` của `subscription` bảo đảm đăng ký luôn cùng phiên bản với gói của nó, nhờ đó chỉ mục duy nhất từng phần "một đăng ký hiệu lực mỗi HTTT mỗi phiên bản" đặt được trên cột `api_version_id` mà không cần nối bảng. `review_decision` mang cả `requested_by` qua khóa ngoại ba cột tới `review_request` để `CHECK` bốn mắt so sánh trong một bảng. `version_contributor` là bảng phụ trợ cho trigger bốn mắt. Hai bảng lịch sử chỉ thêm, giữ vĩnh viễn.

```{.mermaid caption="Sơ đồ thực thể – quan hệ: công bố, SLA, đồng bộ và thông báo"}
erDiagram
  api_version ||--o{ sla_commitment : "cam kết (chỉ thêm)"
  api_version ||--o{ sla_maintenance_window : "cửa sổ bảo trì"
  api_version ||--o{ sla_period : "kỳ tháng"
  sla_commitment ||--o{ sla_period : "cam kết áp dụng"
  change_notice ||--o{ sla_commitment : "thông báo kém đi"
  api_version ||--o{ usage_daily : "thống kê ngày"
  api_version ||--o{ national_sync_record : "hàng đợi quốc gia"
  national_sync_run }o..o{ national_sync_record : "lần đối chiếu"
  api_version ||--o{ change_notice : "thông báo thay đổi"
  change_notice ||--o{ change_notice_recipient : "người nhận, kênh"
  api_version ||--o{ gateway_drift : "lệch cấu hình"
  config_epoch ||..o{ config_change_log : "theo (tenant, env)"
  config_epoch ||..o{ publish_job : "mục tiêu sourceVersion"
  import_session ||--o{ legacy_id_map : "ánh xạ mã cũ"
```

Nhóm này gồm ba mạch. Mạch **công bố cho gateway**: `config_epoch` là bộ đếm `source_version` theo môi trường, `config_change_log` ghi từng lần đổi để PH-03 hỏi `changesSince`, `publish_job` theo dõi việc APISIX đã nạp đúng số phiên bản, `gateway_drift` ghi chỗ lệch tìm được; ba bảng này liên kết theo `(tenant, env)` chứ không bằng khóa ngoại vì `config_epoch` là bộ đếm. Mạch **tuân thủ**: SLA, thống kê và hàng đợi đồng bộ quốc gia cùng gắn với phiên bản. Mạch **thông báo**: `change_notice` có danh sách người nhận theo kênh, và cam kết SLA kém đi trỏ tới thông báo đã phát để chứng minh đã báo trước.

Sáu bảng độc lập, không quan hệ với bảng khác, không vẽ ở trên: `async_operation`, `pending_command`, `inbox_event`, `outbox_event`, `idempotency_record`, `job_lease`. Chúng là hạ tầng chung của mọi chức năng (tiến độ tác vụ nền, lệnh chờ thử lại, hộp nhận, hộp gửi, lũy đẳng, khóa tác vụ định kỳ).

## 3. Đặc tả bảng

Chương này đặc tả từng bảng của schema, theo thứ tự các tệp DDL: danh mục (3.1 đến 3.11), kiểm tra, backend và gói (3.12 đến 3.17), vòng đời, duyệt và đăng ký (3.18 đến 3.25), công bố, SLA và đồng bộ (3.26 đến 3.37), nền tảng và di trú (3.38 đến 3.45). Bảng sau là danh sách bảng với nhóm, thực thể mức logic (EN-02-nn ở FRS §4.2), kiểu cách ly tenant và đặc điểm lưu trữ.

Phần danh sách và các mục 3.1 đến 3.45 sinh bằng [`ph02/tools/gen_tables_md.py`](ph02/tools/gen_tables_md.py) rồi [`ph02/tools/them_dac_ta_bang.py`](ph02/tools/them_dac_ta_bang.py) từ DDL (`COMMENT ON`, ràng buộc, chỉ mục, trigger); sửa ở DDL rồi sinh lại, không sửa tay.

<!-- gen:list:start -->
| STT | Bảng | Nhóm | Thực thể | RLS | Số cột | Ghi chú |
|---|---|---|---|---|---|---|
| 1 | `category` | Danh mục | EN-02-12 | mẫu P | 14 | — |
| 2 | `code_registry` | Danh mục | — | mẫu P | 7 | chỉ thêm |
| 3 | `api` | Danh mục | EN-02-01 | mẫu P | 22 | — |
| 4 | `api_tag` | Danh mục | EN-02-12 | mẫu P | 6 | — |
| 5 | `api_version` | Danh mục | EN-02-02 | mẫu P | 33 | — |
| 6 | `api_spec` | Danh mục | EN-02-03 | mẫu P | 14 | chỉ thêm |
| 7 | `api_operation` | Danh mục | — | mẫu P | 15 | — |
| 8 | `api_search_doc` | Danh mục | — | mẫu P | 11 | — |
| 9 | `context_path_reservation` | Danh mục | — | mẫu P | 12 | — |
| 10 | `api_owner_transfer` | Danh mục | — | mẫu P | 12 | chỉ thêm |
| 11 | `diff_result` | Danh mục | — | mẫu P | 13 | — |
| 12 | `lint_rule` | Kiểm tra, backend, gói | EN-02-13 | mẫu S | 16 | — |
| 13 | `lint_rule_override` | Kiểm tra, backend, gói | EN-02-13 | mẫu P | 10 | — |
| 14 | `lint_finding` | Kiểm tra, backend, gói | EN-02-04 | mẫu P | 18 | phân vùng tháng |
| 15 | `backend` | Kiểm tra, backend, gói | EN-02-05 | mẫu P | 17 | — |
| 16 | `plan` | Kiểm tra, backend, gói | EN-02-06 | mẫu P | 22 | — |
| 17 | `plan_operation_scope` | Kiểm tra, backend, gói | — | mẫu P | 7 | — |
| 18 | `subscription` | Vòng đời, duyệt, đăng ký | EN-02-07 | mẫu P | 30 | — |
| 19 | `subscription_state_history` | Vòng đời, duyệt, đăng ký | — | mẫu P | 11 | chỉ thêm |
| 20 | `version_state_history` | Vòng đời, duyệt, đăng ký | — | mẫu P | 11 | chỉ thêm |
| 21 | `grant_job` | Vòng đời, duyệt, đăng ký | — | mẫu P | 17 | — |
| 22 | `review_request` | Vòng đời, duyệt, đăng ký | EN-02-09 | mẫu P | 21 | — |
| 23 | `version_contributor` | Vòng đời, duyệt, đăng ký | — | mẫu P | 11 | — |
| 24 | `review_decision` | Vòng đời, duyệt, đăng ký | — | mẫu P | 10 | chỉ thêm |
| 25 | `deprecation_reminder` | Vòng đời, duyệt, đăng ký | — | mẫu P | 13 | — |
| 26 | `change_notice` | Công bố, SLA, đồng bộ | EN-02-11 | mẫu P | 18 | — |
| 27 | `change_notice_recipient` | Công bố, SLA, đồng bộ | — | mẫu P | 15 | — |
| 28 | `sla_commitment` | Công bố, SLA, đồng bộ | EN-02-08 | mẫu P | 12 | chỉ thêm |
| 29 | `sla_maintenance_window` | Công bố, SLA, đồng bộ | — | mẫu P | 11 | — |
| 30 | `sla_period` | Công bố, SLA, đồng bộ | EN-02-08 | mẫu P | 16 | — |
| 31 | `usage_daily` | Công bố, SLA, đồng bộ | — | mẫu P | 9 | phân vùng tháng |
| 32 | `national_sync_record` | Công bố, SLA, đồng bộ | EN-02-10 | mẫu P | 18 | — |
| 33 | `national_sync_run` | Công bố, SLA, đồng bộ | — | mẫu P | 15 | — |
| 34 | `config_epoch` | Công bố, SLA, đồng bộ | — | mẫu P | 9 | — |
| 35 | `config_change_log` | Công bố, SLA, đồng bộ | — | mẫu P | 11 | phân vùng tháng |
| 36 | `publish_job` | Công bố, SLA, đồng bộ | — | mẫu P | 19 | — |
| 37 | `gateway_drift` | Công bố, SLA, đồng bộ | — | mẫu P | 18 | — |
| 38 | `async_operation` | Nền tảng | — | mẫu P | 17 | — |
| 39 | `pending_command` | Nền tảng | — | mẫu P | 15 | — |
| 40 | `inbox_event` | Nền tảng | — | mẫu P | 6 | — |
| 41 | `outbox_event` | Nền tảng | — | mẫu P | 11 | — |
| 42 | `idempotency_record` | Nền tảng | — | mẫu P | 10 | — |
| 43 | `job_lease` | Nền tảng | — | không | 4 | — |
| 44 | `import_session` | Nền tảng | — | mẫu P | 18 | — |
| 45 | `legacy_id_map` | Nền tảng | — | mẫu P | 10 | chỉ thêm |

: Danh sách bảng của schema ph02_catalog

<!-- gen:list:end -->

<!-- gen:tables:start -->
### 3.1. `category`

::: dac-ta
**Mục đích.** EN-02-12 Cây phân loại API (FR-02-007, 008). Mã nhóm bất biến, không dùng lại (BR-02-021); gộp nhóm đặt MERGED kèm nhóm đích, API được dời trong một giao dịch.

**FR phục vụ.** FR-02-007, 008.

**Khóa chính.** (id).

**Duy nhất.** `uq_category_code` (tenant_id, category_code).

**Khóa ngoại.** (parent_id, tenant_id) → `category`, (merged_into_id, tenant_id) → `category`.

**Ràng buộc CHECK.** `ck_category_tenant`, `ck_category_code`, `ck_category_status`, `ck_category_merged`, `ck_category_self`.

**Chỉ mục.** `ix_category_parent`, `ix_category_path`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_category_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `category_code` | `varchar(32)` | x |  |  |
| `name` | `varchar(255)` | x |  |  |
| `parent_id` | `uuid` |  |  |  |
| `path` | `varchar(255)` | x |  | Đường dẫn vật hóa từ gốc, ví dụ dat-dai/ban-do; dùng cho truy vấn cây bằng tiền tố. |
| `sort_order` | `integer` | x | `0` |  |
| `status` | `varchar(8)` | x | `'ACTIVE'` |  |
| `merged_into_id` | `uuid` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `category`

### 3.2. `code_registry`

::: dac-ta
**Mục đích.** Sổ mã đã dùng: mã API, số hiệu phiên bản, mã gói, mã nhóm không bao giờ dùng lại kể cả đối tượng đã xóa hay ngừng (BR-02-021). Chỉ thêm, giữ chỗ bằng khóa duy nhất (ERR-02-002).

**FR phục vụ.** FR-02-010, 024, 027, 033, 042 (BR-02-021).

**Khóa chính.** (id).

**Duy nhất.** `uq_code_registry` (tenant_id, kind, code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_code_registry_tenant`, `ck_code_registry_kind`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_code_registry_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_code_registry_append_only`); Thu quyền UPDATE, DELETE của `ph02_app` (lớp thứ hai).

**Ghi chú.** Bảng bằng chứng chỉ thêm, không có cột sửa nên không có `updated_*` và `version`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `kind` | `varchar(12)` | x |  |  |
| `code` | `varchar(160)` | x |  | API: apiCode; CATEGORY: categoryCode; VERSION: {apiCode}@{versionNo}; PLAN: {apiCode}@{versionNo}:{planCode}. |
| `subject_id` | `uuid` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `code_registry`

### 3.3. `api`

::: dac-ta
**Mục đích.** EN-02-01 API: nhận diện, phân loại dữ liệu, mức hiển thị, chủ quản (FR-02-001, 002, 010, 013, 014, 040, 041, 045). Vòng đời nằm ở api_version. Xóa mềm bằng deleted_at (BR-02-020); mã không dùng lại (BR-02-021).

**FR phục vụ.** FR-02-001…005, 010, 013, 014, 040, 041, 045.

**Khóa chính.** (id).

**Duy nhất.** `uq_api_code` (tenant_id, api_code), `uq_api_legacy_id` (tenant_id, legacy_id) từng phần WHERE legacy_id IS NOT NULL.

**Khóa ngoại.** (category_id, tenant_id) → `category`.

**Ràng buộc CHECK.** `ck_api_tenant`, `ck_api_code`, `ck_api_data_class`, `ck_api_visibility`, `ck_api_visibility_class`, `ck_api_base_path`, `ck_api_origin`, `ck_api_flow_ref`, `ck_api_flow_ref_shape`, `ck_api_legacy`, `ck_api_deleted`.

**Chỉ mục.** `ix_api_system`, `ix_api_owner`, `ix_api_category`, `ix_api_visibility`, `ix_api_name_trgm`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_api_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_code` | `varchar(63)` | x |  |  |
| `name` | `varchar(255)` | x |  |  |
| `description` | `varchar(4000)` |  |  |  |
| `system_code` | `varchar(64)` | x |  | Mã HTTT cung cấp ở PH-01 (bản sao system_replica); không khóa ngoại vì khác schema, kiểm ở dịch vụ (ERR-02-004). |
| `owner_org_code` | `varchar(64)` | x |  | Đơn vị chủ quản API; phải là đơn vị của HTTT cung cấp trừ khi TA chuyển chủ quản (BR-02-032). |
| `data_class` | `varchar(10)` | x |  | PUBLIC, INTERNAL, RESTRICTED, SENSITIVE theo SAD §8.2; quyết định kiểu xác thực tối thiểu của gói (BR-02-016). |
| `data_class_rank` | `smallint` |  |  | Hạng số của data_class (0…3), cột sinh tự động; so với plan.auth_rank ở trigger tg_plan_auth_policy. |
| `visibility` | `varchar(8)` | x | `'TENANT'` | TENANT, NATIONAL, PUBLIC; PUBLIC chỉ với dữ liệu PUBLIC, NATIONAL không với SENSITIVE (BR-02-037, CHECK ck_api_visibility_class). |
| `category_id` | `uuid` |  |  |  |
| `base_path` | `varchar(120)` | x |  | Tiền tố công bố /{nhóm}/{apiCode}; context-path đầy đủ thêm /v{major} ở context_path_reservation. |
| `origin` | `varchar(8)` | x | `'MANUAL'` |  |
| `flow_ref` | `jsonb` |  |  | Với origin = FLOW: {workspaceCode, flowCode} của luồng PH-04; phần hợp đồng không sửa tay (BR-02-030). |
| `legacy_id` | `varchar(128)` |  |  | Mã API ở APIM cũ khi origin = LEGACY; khóa duy nhất làm cho nhập lại lũy đẳng (FR-02-061). |
| `deleted_at` | `timestamptz` |  |  |  |
| `delete_reason` | `varchar(1000)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `api`

### 3.4. `api_tag`

::: dac-ta
**Mục đích.** EN-02-12 Thẻ tự do gắn với API (FR-02-007). Tối đa 10 thẻ mỗi API kiểm ở dịch vụ.

**FR phục vụ.** FR-02-007.

**Khóa chính.** (id).

**Duy nhất.** `uq_api_tag` (tenant_id, api_id, tag).

**Khóa ngoại.** (api_id, tenant_id) → `api` xóa theo.

**Ràng buộc CHECK.** `ck_api_tag_tenant`, `ck_api_tag_format`.

**Chỉ mục.** `ix_api_tag_tag`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_api_tag_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_id` | `uuid` | x |  |  |
| `tag` | `varchar(40)` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `api_tag`

### 3.5. `api_version`

::: dac-ta
**Mục đích.** EN-02-02 Phiên bản API, đơn vị của vòng đời (FRS §4.3; FR-02-034…045). Chuyển trạng thái chỉ qua máy trạng thái ở dịch vụ; CSDL giữ chốt chặn: cạnh hợp lệ (tg_api_version_guard), một phiên bản đang chạy mỗi số chính (ex_api_version_one_live_per_major, BR-02-035), đặc tả bất biến từ PENDING (BR-02-014).

**FR phục vụ.** FR-02-034…042, 045.

**Khóa chính.** (id).

**Duy nhất.** `uq_api_version_no` (tenant_id, api_id, version_no).

**Khóa ngoại.** (api_id, tenant_id) → `api`, (successor_version_id, tenant_id) → `api_version`.

**Ràng buộc CHECK.** `ck_api_version_tenant`, `ck_api_version_no`, `ck_api_version_major`, `ck_api_version_status`, `ck_api_version_activating`, `ck_api_version_spec`, `ck_api_version_published`, `ck_api_version_deprecated`, `ck_api_version_suspended`, `ck_api_version_suspend_kind`, `ck_api_version_retired`, `ck_api_version_gateway`, `ck_api_version_successor_self`.

**Chỉ mục.** `ix_api_version_api`, `ix_api_version_status`, `ix_api_version_sunset`, `ix_api_version_suspended`, `ix_api_version_pending`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_api_version_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger chốt chặn `tg_api_version_guard`: Chốt chặn thứ hai của máy trạng thái phiên bản.

**Ghi chú.** Ràng buộc loại trừ hoãn tới cuối giao dịch cho phép thay thế phiên bản cùng số chính trong một giao dịch (BR-02-035). Ràng buộc loại trừ: `ex_api_version_one_live_per_major`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_id` | `uuid` | x |  |  |
| `version_no` | `varchar(16)` | x |  |  |
| `major` | `integer` | x |  |  |
| `status` | `varchar(10)` | x | `'DRAFT'` |  |
| `activating` | `boolean` | x | `false` | Đã duyệt (quyết định cuối) nhưng chờ gateway xác nhận nạp cấu hình; trạng thái vẫn PENDING cho tới khi có xác nhận (SDD 4.10). |
| `current_spec_id` | `uuid` |  |  | Đặc tả hiện hành; chỉ đổi khi DRAFT. FK hoãn tới cuối giao dịch vì api_spec trỏ ngược về phiên bản. |
| `successor_version_id` | `uuid` |  |  |  |
| `sunset_at` | `timestamptz` |  |  | Hạn ngừng hẳn (tiêu đề Sunset, RFC 8594); bắt buộc khi DEPRECATED; hạn tối thiểu 02.deprecation.min-days kiểm ở dịch vụ (BR-02-004). |
| `urgent_reason` | `varchar(1000)` |  |  |  |
| `breaking` | `boolean` | x | `false` |  |
| `version_violation` | `boolean` | x | `false` | Có thay đổi BREAKING mà số chính không tăng; chặn gửi duyệt (ERR-02-017, BR-02-003). |
| `release_notes` | `varchar(2000)` |  |  |  |
| `submitted_at` | `timestamptz` |  |  |  |
| `submitted_by` | `varchar(64)` |  |  |  |
| `approved_at` | `timestamptz` |  |  |  |
| `published_at` | `timestamptz` |  |  |  |
| `suspended_at` | `timestamptz` |  |  |  |
| `suspended_by_role` | `varchar(4)` |  |  | SO khi SO tạm ngừng vì an ninh: chỉ SO hoặc TA được tiếp tục (BR-02-034). |
| `suspend_kind` | `varchar(12)` |  |  |  |
| `retired_at` | `timestamptz` |  |  |  |
| `gateway_state` | `varchar(8)` | x | `'NONE'` | NONE, APPLYING, SYNCED, FAILED: trạng thái gỡ route sau lệnh hạn chế (SDD 4.10). |
| `last_test_spec_sha256` | `char(64)` |  |  | Băm đặc tả đã triển khai thử TEST thành công; so với băm hiện hành khi gửi duyệt (02.submit.require-test-deploy). |
| `last_test_config_hash` | `char(64)` |  |  |  |
| `last_test_at` | `timestamptz` |  |  |  |
| `minhash` | `bytea` |  |  | Chữ ký MinHash của tập (phương thức, đường dẫn) phục vụ phát hiện API trùng chức năng (FR-02-020). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |
| `WHERE` | `(status` |  |  |  |

: Cột của bảng `api_version`

### 3.6. `api_spec`

::: dac-ta
**Mục đích.** EN-02-03 Đặc tả OpenAPI của phiên bản: chỉ thêm, giữ vĩnh viễn làm bằng chứng hợp đồng (BR-02-014, NFR-02-017). Nội dung ở kho đối tượng Garage; CSDL chỉ giữ khóa đối tượng và băm. Đặc tả mới là dòng mới (seq tăng).

**FR phục vụ.** FR-02-006, 011, 012, 014.

**Khóa chính.** (id).

**Duy nhất.** `uq_api_spec_seq` (api_version_id, seq).

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`.

**Ràng buộc CHECK.** `ck_api_spec_tenant`, `ck_api_spec_format`, `ck_api_spec_source`, `ck_api_spec_url`, `ck_api_spec_sha`, `ck_api_spec_size`, `ck_api_spec_ops`, `ck_api_spec_flow_format`.

**Chỉ mục.** `ix_api_spec_sha`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_api_spec_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_api_spec_append_only`); Thu quyền UPDATE, DELETE của `ph02_app` (lớp thứ hai).

**Ghi chú.** Nội dung đặc tả ở kho đối tượng Garage, không ở CSDL (BR-02-014, NFR-02-017); chỉ giữ khóa đối tượng và băm SHA-256.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `seq` | `integer` | x |  |  |
| `format` | `varchar(10)` | x |  |  |
| `source` | `varchar(8)` | x |  |  |
| `source_url` | `varchar(2048)` |  |  |  |
| `sha256` | `char(64)` | x |  |  |
| `merged_sha256` | `char(64)` |  |  | Băm của đặc tả đã gộp tham chiếu và chuẩn hóa về OpenAPI 3.1; dùng làm khóa của diff_result. |
| `size_bytes` | `integer` | x |  | Trần cứng 50 MiB; trần theo tenant 02.spec.max-size-mib (mặc định 10 MiB) kiểm ở dịch vụ (ERR-02-009). |
| `operation_count` | `integer` | x | `0` | Không quá 5.000 thao tác (NFR-02-011). |
| `object_key` | `varchar(512)` | x |  | Khóa đối tượng specs/{apiCode}/{versionNo}/{sha256} ở bucket dh-{tenant}-catalog, dựng bằng ObjectKeys.of(tenant, …). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `api_spec`

### 3.7. `api_operation`

::: dac-ta
**Mục đích.** Thao tác rút từ đặc tả (FR-02-002, 005, 029, 043). Dữ liệu dẫn xuất từ api_spec, dựng lại khi nạp đặc tả mới ở DRAFT; là nguồn cho danh sách thao tác của dữ liệu công bố (SEC-43).

**FR phục vụ.** FR-02-002, 005, 029, 043.

**Khóa chính.** (id).

**Duy nhất.** `uq_api_operation_id` (spec_id, operation_id), `uq_api_operation_route` (spec_id, method, path_template).

**Khóa ngoại.** (spec_id, tenant_id) → `api_spec`, (api_version_id, tenant_id) → `api_version`.

**Ràng buộc CHECK.** `ck_api_operation_tenant`, `ck_api_operation_method`, `ck_api_operation_path`, `ck_api_operation_tags`.

**Chỉ mục.** `ix_api_operation_version`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_api_operation_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `spec_id` | `uuid` | x |  |  |
| `operation_id` | `varchar(128)` | x |  |  |
| `method` | `varchar(7)` | x |  |  |
| `path_template` | `varchar(512)` | x |  |  |
| `summary` | `varchar(500)` |  |  |  |
| `tags` | `varchar(40)[]` | x | `'{}'` |  |
| `required_scope` | `varchar(200)` |  |  | Phạm vi cần có theo khai báo security của thao tác; PH-03 dùng để dựng luật kiểm tra. |
| `idempotent` | `boolean` | x | `false` |  |
| `deprecated` | `boolean` | x | `false` |  |
| `schema_ptr` | `varchar(512)` |  |  | Con trỏ JSON tới lược đồ yêu cầu trong đặc tả đã gộp, để PH-03 sinh lược đồ kiểm tra thân yêu cầu (SEC-43). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `api_operation`

### 3.8. `api_search_doc`

::: dac-ta
**Mục đích.** Chỉ mục tìm kiếm toàn văn một dòng mỗi API (FR-02-003, NFR-02-002). tsv có bốn trọng số: tên và apiCode (A), mô tả (B), thẻ và phân loại (C), summary thao tác (D) theo cấu hình vn_unaccent. SearchDocumentWriter cập nhật cùng giao dịch với thay đổi. Dùng khi 02.search.engine = POSTGRES (Q02-02).

**FR phục vụ.** FR-02-003.

**Khóa chính.** (id).

**Duy nhất.** `uq_api_search_doc_api` (tenant_id, api_id).

**Khóa ngoại.** (api_id, tenant_id) → `api` xóa theo.

**Ràng buộc CHECK.** `ck_api_search_doc_tenant`.

**Chỉ mục.** `ix_api_search_doc_tsv`, `ix_api_search_doc_code`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_api_search_doc_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_id` | `uuid` | x |  |  |
| `api_code` | `varchar(63)` | x |  |  |
| `has_published` | `boolean` | x | `false` | API có ít nhất một phiên bản từ PUBLISHED trở đi; người ngoài tổ chức chủ quản chỉ thấy các dòng này (BR-02-039). |
| `tsv` | `tsvector` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `api_search_doc`

### 3.9. `context_path_reservation`

::: dac-ta
**Mục đích.** Giữ chỗ context-path /{nhóm}/{apiCode}/v{major} (FR-02-024, BR-02-022): duy nhất trong tenant, bất biến sau PUBLISHED, giữ chỗ 12 tháng sau RETIRED (released_after). Khóa theo (API, số chính) nên phiên bản cùng số chính thay thế dùng lại đúng đường dẫn (BR-02-035). Bí danh đường dẫn hệ cũ (LEGACY_ALIAS) dùng chung bảng để kiểm xung đột một chỗ. Xung đột tiền tố kiểm ở ContextPathService dưới pg_advisory_xact_lock; khóa duy nhất là chốt chặn.

**FR phục vụ.** FR-02-024.

**Khóa chính.** (id).

**Duy nhất.** `uq_context_path` (tenant_id, path), `uq_context_path_api` (tenant_id, api_id, major, kind).

**Khóa ngoại.** (api_id, tenant_id) → `api`.

**Ràng buộc CHECK.** `ck_context_path_tenant`, `ck_context_path_kind`, `ck_context_path_major`, `ck_context_path_format`, `ck_context_path_major_suffix`, `ck_context_path_alias`.

**Chỉ mục.** `ix_context_path_release`, `ix_context_path_prefix`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_context_path_reservation_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_id` | `uuid` | x |  |  |
| `major` | `integer` | x |  |  |
| `kind` | `varchar(12)` | x | `'PRIMARY'` |  |
| `path` | `varchar(255)` | x |  |  |
| `released_after` | `timestamptz` |  |  | retired_at + 12 tháng khi phiên bản cuối của (API, số chính) RETIRED; sau mốc này mới cho dùng lại. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `context_path_reservation`

### 3.10. `api_owner_transfer`

::: dac-ta
**Mục đích.** Lịch sử chuyển chủ quản API (FR-02-045): chỉ TA thực hiện, ghi số và ngày văn bản giao nhận (Q02-07), không lưu tệp ký số ở bản 0.1. Chỉ thêm.

**FR phục vụ.** FR-02-045.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (api_id, tenant_id) → `api`.

**Ràng buộc CHECK.** `ck_api_owner_transfer_tenant`, `ck_api_owner_transfer_change`.

**Chỉ mục.** `ix_api_owner_transfer_api`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_api_owner_transfer_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_api_owner_transfer_append_only`); Thu quyền UPDATE, DELETE của `ph02_app` (lớp thứ hai).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_id` | `uuid` | x |  |  |
| `from_org_code` | `varchar(64)` | x |  |  |
| `to_org_code` | `varchar(64)` | x |  |  |
| `from_system_code` | `varchar(64)` | x |  |  |
| `to_system_code` | `varchar(64)` | x |  |  |
| `document_no` | `varchar(64)` | x |  |  |
| `document_date` | `date` | x |  |  |
| `reason` | `varchar(1000)` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `api_owner_transfer`

### 3.11. `diff_result`

::: dac-ta
**Mục đích.** Bộ đệm kết quả so sánh hai đặc tả theo cặp băm đã gộp (FR-02-043, NFR-02-004). Hai đặc tả bất biến nên kết quả đúng vĩnh viễn với cùng classifier_version; khi đổi bảng luật phân loại thì có dòng mới, dòng cũ có thể xóa. Không chứa danh sách bên bị ảnh hưởng (tính lại từ đăng ký khi xem).

**FR phục vụ.** FR-02-043, 044.

**Khóa chính.** (id).

**Duy nhất.** `uq_diff_result` (tenant_id, from_sha256, to_sha256, classifier_version).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_diff_result_tenant`, `ck_diff_result_sha`, `ck_diff_result_counts`, `ck_diff_result_summary`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_diff_result_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Chặn UPDATE (trigger `tg_diff_result_append_only`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `from_sha256` | `char(64)` | x |  |  |
| `to_sha256` | `char(64)` | x |  |  |
| `classifier_version` | `varchar(16)` | x |  |  |
| `breaking_count` | `integer` | x | `0` |  |
| `compatible_count` | `integer` | x | `0` |  |
| `uncertain_count` | `integer` | x | `0` |  |
| `summary` | `jsonb` | x |  |  |
| `detail_object_key` | `varchar(512)` |  |  | Danh sách thay đổi đầy đủ ở kho đối tượng khi vượt 5.000 thay đổi hoặc 256 KiB; summary chỉ giữ số đếm và nhóm đầu. |
| `computed_ms` | `integer` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `diff_result`

### 3.12. `lint_rule`

::: dac-ta
**Mục đích.** EN-02-13 Bộ luật kiểm tra đặc tả: 15 luật quy ước LINT-02-01…15 (lớp 2) và 9 mẫu quét bí mật SCAN-02-01…09 (FR-02-017, 018, 021). Dùng chung toàn nền tảng (tenant COMMON, mẫu S): tỉnh đọc, không ghi; PA ghi phiên PLATFORM. Mẫu quét bí mật chỉ đọc và không hạ mức (UI-02-15).

**FR phục vụ.** FR-02-017, 018, 021.

**Khóa chính.** (id).

**Duy nhất.** `uq_lint_rule_id` (rule_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_lint_rule_common`, `ck_lint_rule_code`, `ck_lint_rule_layer`, `ck_lint_rule_layer_code`, `ck_lint_rule_severity`, `ck_lint_rule_policy`, `ck_lint_rule_secret_fixed`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu S (FORCE): đọc dòng của tenant phiên và `COMMON`; ghi dòng `COMMON` chỉ khi phiên là `PLATFORM` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Bộ luật dùng chung toàn nền tảng: mọi dòng mang `tenant_id = COMMON` (`ck_lint_rule_common`); tỉnh đọc, PA ghi bằng phiên `PLATFORM`. Mẫu quét bí mật cố định mức `ERROR`, không chỉnh (`ck_lint_rule_secret_fixed`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x | `'COMMON'` | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `rule_id` | `varchar(16)` | x |  |  |
| `layer` | `varchar(10)` | x |  |  |
| `default_severity` | `varchar(7)` | x |  |  |
| `adjust_policy` | `varchar(10)` | x | `'NONE'` | NONE: luật cấu trúc, không chỉnh ở tenant; RAISE: tenant chỉ nâng WARNING thành ERROR; LOWER_LANG: riêng LINT-02-02, tenant hạ phần cảnh báo ngôn ngữ (FRS ghi chú FR-02-021). |
| `adjustable` | `boolean` |  |  | Cột sinh tự động (GENERATED … STORED). |
| `title` | `varchar(500)` | x |  |  |
| `hint` | `varchar(1000)` |  |  |  |
| `pattern` | `text` |  |  | Biểu thức quét của mẫu SCAN; bắt buộc cho lớp SECRET. Chỉ đọc qua giao diện, thay đổi qua bản phát hành sau duyệt của Cán bộ ATTT (Q02-11). |
| `enabled` | `boolean` | x | `true` |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `lint_rule`

### 3.13. `lint_rule_override`

::: dac-ta
**Mục đích.** Mức hiệu lực của luật theo tenant (FR-02-021). Chỉ ghi được cho luật có adjust_policy khác NONE và đúng chiều cho phép (trigger tg_lint_rule_override_policy); ghi kiểm toán giá trị trước, sau ở dịch vụ.

**FR phục vụ.** FR-02-021.

**Khóa chính.** (id).

**Duy nhất.** `uq_lint_rule_override` (tenant_id, rule_id).

**Khóa ngoại.** (rule_id) → `lint_rule`.

**Ràng buộc CHECK.** `ck_lint_rule_override_tenant`, `ck_lint_rule_override_severity`, `ck_lint_rule_override_reason`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_lint_rule_override_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger chốt chặn `tg_lint_rule_override_policy`: tg_lint_rule_override_policy.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `rule_id` | `varchar(16)` | x |  |  |
| `severity` | `varchar(7)` | x |  |  |
| `reason` | `varchar(1000)` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `lint_rule_override`

### 3.14. `lint_finding`

::: dac-ta
**Mục đích.** EN-02-04 Phát hiện của một lần kiểm tra đặc tả persist: lớp, mức, mã luật, vị trí, hướng dẫn (FR-02-016…018). KHÔNG lưu chuỗi khớp của bộ quét bí mật, chỉ dấu vân tay 16 ký tự hex của băm có muối (NFR-02-012, FR-02-018). Phân vùng tháng theo checked_at, giữ 1 năm (NFR-02-017). Chế độ PREVIEW không ghi gì.

**FR phục vụ.** FR-02-016…020.

**Khóa chính.** (id, checked_at).

**Duy nhất.** Không.

**Khóa ngoại.** (spec_id, tenant_id) → `api_spec`.

**Ràng buộc CHECK.** `ck_lint_finding_tenant`, `ck_lint_finding_layer`, `ck_lint_finding_severity`, `ck_lint_finding_status`, `ck_lint_finding_secret`, `ck_lint_finding_ack`, `ck_lint_finding_fingerprint`.

**Chỉ mục.** `ix_lint_finding_spec`, `ix_lint_finding_version`, `ix_lint_finding_run`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_lint_finding_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Phân vùng RANGE theo tháng trên `checked_at` (thủ tục `p_ensure_month_partitions`); không cấp quyền trực tiếp lên phân vùng, dọn dữ liệu hết hạn bằng DETACH PARTITION.

**Ghi chú.** Không lưu chuỗi khớp của bộ quét bí mật, chỉ dấu vân tay `fingerprint`; chế độ `PREVIEW` không ghi gì (FR-02-019).
:::

Phân vùng: `RANGE (checked_at)` theo tháng, tên phân vùng `lint_finding_YYYYMM`.

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `spec_id` | `uuid` | x |  |  |
| `run_id` | `uuid` | x |  |  |
| `layer` | `varchar(10)` | x |  |  |
| `severity` | `varchar(7)` | x |  |  |
| `rule_id` | `varchar(16)` | x |  |  |
| `location` | `varchar(512)` |  |  |  |
| `message` | `varchar(1000)` | x |  |  |
| `hint` | `varchar(1000)` |  |  |  |
| `fingerprint` | `char(16)` |  |  | Dấu vân tay (16 ký tự đầu của HMAC-SHA256 có muối theo tenant) của chuỗi khớp, để nhận ra cùng một bí mật ở lần quét sau mà không giữ giá trị. |
| `status` | `varchar(12)` | x | `'OPEN'` | OPEN, RESOLVED (lần quét sau không còn), ACKNOWLEDGED (người dùng xác nhận không phải bí mật, ghi người và lý do; SECRET cần TA, kiểm ở dịch vụ). |
| `acknowledged_by` | `varchar(64)` |  |  |  |
| `acknowledged_at` | `timestamptz` |  |  |  |
| `acknowledge_reason` | `varchar(1000)` |  |  |  |
| `checked_at` | `timestamptz` | x | `now()` |  |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `lint_finding`

### 3.15. `backend`

::: dac-ta
**Mục đích.** EN-02-05 Backend của phiên bản (FR-02-022…025). Không có trường URL tự do: SYSTEM trỏ kết nối PH-05 {connectionCode, basePath}, FLOW trỏ luồng PH-04 {flowCode, environment}; nhờ vậy BR-02-023 (đích trong danh sách cho phép, TLS ≥ 1.2, không địa chỉ nội bộ) đúng theo cấu trúc (CHECK ck_backend_no_free_url). Tổng trọng số > 0 và tối thiểu một backend ACTIVE kiểm ở SubmissionGate (BR-02-024).

**FR phục vụ.** FR-02-022, 023, 025, 026.

**Khóa chính.** (id).

**Duy nhất.** `uq_backend_code` (api_version_id, backend_code).

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`.

**Ràng buộc CHECK.** `ck_backend_tenant`, `ck_backend_code`, `ck_backend_kind`, `ck_backend_target_shape`, `ck_backend_no_free_url`, `ck_backend_weight`, `ck_backend_timeout`, `ck_backend_retries`, `ck_backend_lb`, `ck_backend_status`, `ck_backend_placeholder`, `ck_backend_health`.

**Chỉ mục.** `ix_backend_version`, `ix_backend_flow`, `ix_backend_connection`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_backend_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `backend_code` | `varchar(32)` | x |  |  |
| `kind` | `varchar(6)` | x |  |  |
| `target_ref` | `jsonb` | x |  |  |
| `weight` | `smallint` | x | `100` |  |
| `timeout_ms` | `integer` | x | `10000` | Trần cứng 120.000 ms; trần theo tenant 02.backend.max-timeout-ms (mặc định 60.000) kiểm ở TargetPolicy. |
| `retries` | `smallint` | x | `0` |  |
| `lb_type` | `varchar(12)` | x | `'roundrobin'` |  |
| `health_check` | `jsonb` | x | `'{}'` | Kiểm tra sức khỏe chủ động và ngắt thụ động: {path, intervalSeconds, healthy, unhealthy}; PH-03 dịch sang cấu hình APISIX. |
| `status` | `varchar(11)` | x | `'ACTIVE'` | PLACEHOLDER: khung luồng đã sinh ở PH-04 nhưng luồng chưa phát hành, chưa tính ACTIVE; chuyển ACTIVE khi nhận EVT-04-07 (FR-02-026). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `backend`

### 3.16. `plan`

::: dac-ta
**Mục đích.** EN-02-06 Gói sử dụng (Plan) của phiên bản: kiểu xác thực, hạn mức, đối tượng được xin, tự duyệt (FR-02-027…033). Bốn trạng thái STAGING, PUBLISHED, DEPRECATED, CLOSED giữ từ hệ cũ (LGC-APIM-009). Kiểu xác thực tối thiểu theo mức phân loại được chốt ở trigger tg_plan_auth_policy (BR-02-016, SEC-24).

**FR phục vụ.** FR-02-027…033.

**Khóa chính.** (id).

**Duy nhất.** `uq_plan_code` (api_version_id, plan_code).

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`, (cloned_from_plan_id, tenant_id) → `plan`.

**Ràng buộc CHECK.** `ck_plan_tenant`, `ck_plan_code`, `ck_plan_status`, `ck_plan_auth`, `ck_plan_audience`, `ck_plan_limits`, `ck_plan_price`, `ck_plan_published`, `ck_plan_closed`.

**Chỉ mục.** `ix_plan_version`, `ix_plan_needs_upgrade`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_plan_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger chốt chặn `tg_plan_auth_policy`: Chốt chặn BR-02-016: so hạng của auth_type (cùng công thức với cột sinh plan.auth_rank) với hạng tối thiểu theo api.data_class_rank (0→KEYLESS, 1→API_KEY, 2→PKJWT, 3→MTLS).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `plan_code` | `varchar(32)` | x |  |  |
| `name` | `varchar(255)` | x |  |  |
| `description` | `varchar(2000)` |  |  |  |
| `status` | `varchar(10)` | x | `'STAGING'` |  |
| `auth_type` | `varchar(14)` | x |  | KEYLESS, API_KEY, OAUTH2_SECRET, OAUTH2_PKJWT, OAUTH2_MTLS. KEYLESS chỉ với dữ liệu và mức hiển thị PUBLIC; RESTRICTED chỉ PKJWT hoặc MTLS; SENSITIVE chỉ MTLS. |
| `auth_rank` | `smallint` |  |  | Hạng số của auth_type (0…4), cột sinh tự động, so với hạng yêu cầu tối thiểu của api.data_class_rank. |
| `needs_auth_upgrade` | `boolean` | x | `false` | Gói không còn hợp lệ sau khi API nâng mức phân loại, hoặc gói nhập từ hệ cũ vi phạm: đánh dấu "Cần nâng xác thực" thay vì chặn nhập; chặn gửi duyệt cho tới khi sửa (SDD 4.6). |
| `auto_approve` | `boolean` | x | `false` |  |
| `audience` | `jsonb` | x | `'{"mode":"ALL"}'` | Điều kiện đăng ký: {"mode":"ALL"} hoặc {"mode":"GROUPS","groups":[mã nhóm HTTT ở PH-01]} (ERR-02-028). |
| `limits` | `jsonb` | x | `'{}'` | Hạn mức: {perSecond, perMinute, perHour, perDay, burst, concurrent}; PH-03 thực thi. Hạ hạn mức ở gói PUBLISHED là thay đổi không tương thích (BR-02-017). |
| `unit_price_vnd` | `numeric(19,0)` | x | `0` | T-MONEY, chỉ là thông tin hiển thị, mặc định 0; mọi việc thu phí thuộc PH-19 (BR-02-040, Q02-09). |
| `cloned_from_plan_id` | `uuid` |  |  | Gói nguồn khi sao chép sang phiên bản mới (FR-02-033); mã gói giữ nguyên để BR-02-035 kiểm được bằng mã. |
| `published_at` | `timestamptz` |  |  |  |
| `closed_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `plan`

### 3.17. `plan_operation_scope`

::: dac-ta
**Mục đích.** Thao tác cho phép của gói và hạn mức riêng từng thao tác (FR-02-029). Không có dòng thì gói cho phép mọi thao tác. operation_id là khóa chuỗi, không khóa ngoại, vì đặc tả đổi khi DRAFT; thao tác không có trong đặc tả bị từ chối ở dịch vụ (ERR-02-037).

**FR phục vụ.** FR-02-029.

**Khóa chính.** (id).

**Duy nhất.** `uq_plan_operation_scope` (plan_id, operation_id).

**Khóa ngoại.** (plan_id, tenant_id) → `plan` xóa theo.

**Ràng buộc CHECK.** `ck_plan_operation_scope_tenant`, `ck_plan_operation_scope_limits`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_plan_operation_scope_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `plan_id` | `uuid` | x |  |  |
| `operation_id` | `varchar(128)` | x |  |  |
| `limits` | `jsonb` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `plan_operation_scope`

### 3.18. `subscription`

::: dac-ta
**Mục đích.** EN-02-07 Đăng ký sử dụng của HTTT cho một gói (FR-02-046…052). Mỗi HTTT chỉ một đăng ký hiệu lực (PENDING, ACTIVE, SUSPENDED) cho một phiên bản (uq_subscription_one_effective, BR-02-027). Khóa ngoại ba cột (plan_id, api_version_id, tenant_id) bảo đảm đăng ký khớp phiên bản của gói. Phạm vi truy cập sinh tự động, không có đường cấp tay (BR-02-025).

**FR phục vụ.** FR-02-046…052.

**Khóa chính.** (id).

**Duy nhất.** `uq_subscription_one_effective` (tenant_id, system_code, api_version_id) từng phần WHERE status IN ('PENDING', 'ACTIVE', 'SUSPENDED'), `uq_subscription_legacy_id` (tenant_id, legacy_id) từng phần WHERE legacy_id IS NOT NULL.

**Khóa ngoại.** (plan_id, api_version_id, tenant_id) → `plan`.

**Ràng buộc CHECK.** `ck_subscription_tenant`, `ck_subscription_data_class`, `ck_subscription_status`, `ck_subscription_grant`, `ck_subscription_grant_pending`, `ck_subscription_purpose`, `ck_subscription_legal_basis`, `ck_subscription_scopes`, `ck_subscription_scope_ops`, `ck_subscription_decided`, `ck_subscription_four_eyes`, `ck_subscription_reject_reason`.

**Chỉ mục.** `ix_subscription_plan`, `ix_subscription_system`, `ix_subscription_version`, `ix_subscription_expiry`, `ix_subscription_review`, `ix_subscription_awaiting`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_subscription_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Khóa ngoại ba cột `(plan_id, api_version_id, tenant_id)` bảo đảm đăng ký khớp phiên bản của gói.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `plan_id` | `uuid` | x |  |  |
| `api_version_id` | `uuid` | x |  |  |
| `system_code` | `varchar(64)` | x |  | Mã HTTT khai thác ở PH-01 (bản sao); kiểm ACTIVE, thuộc tổ chức người gửi, thuộc nhóm của gói ở dịch vụ (ERR-02-026, 028). |
| `requester_org_code` | `varchar(64)` | x |  |  |
| `purpose` | `varchar(1000)` | x |  |  |
| `expected_volume` | `varchar(500)` | x |  |  |
| `data_class` | `varchar(10)` | x |  | Bản chụp mức phân loại của API lúc gửi đăng ký, để quy tắc duyệt và căn cứ pháp lý không đổi theo thay đổi sau. |
| `personal_data` | `boolean` | x | `false` |  |
| `legal_basis` | `varchar(1000)` |  |  | Căn cứ pháp lý khi dữ liệu cá nhân hoặc từ mức Hạn chế (BR-02-012, CMP-LAW-05); CHECK ck_subscription_legal_basis. |
| `status` | `varchar(10)` | x | `'PENDING'` |  |
| `reason_code` | `varchar(40)` |  |  | Mã lý do máy đọc được của trạng thái hiện tại, ví dụ MIGRATED_AWAITING_CREDENTIAL (BR-02-036), SYSTEM_SUSPENDED, SYSTEM_REVOKED, EXPIRED_REVIEW. |
| `status_reason` | `varchar(1000)` |  |  |  |
| `grant_status` | `varchar(20)` | x | `'NONE'` | Tiến độ cấp quyền thật (saga ở grant_job): AWAITING_CREDENTIAL là chờ định danh máy ở PH-01, không phải lỗi; DETACH_PENDING là đã thu hồi nhưng PH-12 chưa gỡ phạm vi. |
| `scopes` | `varchar(200)[]` | x | `'{}'` | Phạm vi api:{apiCode}:{planCode} và api:{apiCode}:{planCode}:{operationId}; tối đa 50 (Q02-24). |
| `scope_operations` | `varchar(128)[]` | x | `'{}'` |  |
| `requested_by` | `varchar(64)` | x |  |  |
| `requested_at` | `timestamptz` | x | `now()` |  |
| `decided_by` | `varchar(64)` |  |  | Người duyệt hoặc system:auto-approve khi tự duyệt (BR-02-026); phải khác requested_by (bốn mắt, ck_subscription_four_eyes). |
| `decided_at` | `timestamptz` |  |  |  |
| `granted_at` | `timestamptz` |  |  |  |
| `expires_at` | `timestamptz` |  |  |  |
| `next_review_at` | `timestamptz` |  |  |  |
| `legacy_id` | `varchar(128)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `subscription`

### 3.19. `subscription_state_history`

::: dac-ta
**Mục đích.** Lịch sử chuyển trạng thái đăng ký: trước, sau, người, lý do bắt buộc (BR-02-028). Chỉ thêm, giữ vĩnh viễn làm bằng chứng ai đã dùng API nào (FRS §4.5, NFR-02-017). Hiển thị ở tab Lịch sử.

**FR phục vụ.** FR-02-051, 052.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (subscription_id, tenant_id) → `subscription`.

**Ràng buộc CHECK.** `ck_subscription_state_history_tenant`, `ck_subscription_state_history_reason`, `ck_subscription_state_history_trace`.

**Chỉ mục.** `ix_subscription_state_history_sub`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_subscription_state_history_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_subscription_state_history_append_only`); Thu quyền UPDATE, DELETE của `ph02_app` (lớp thứ hai).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `subscription_id` | `uuid` | x |  |  |
| `from_status` | `varchar(10)` |  |  |  |
| `to_status` | `varchar(10)` | x |  |  |
| `command` | `varchar(24)` | x |  |  |
| `reason_code` | `varchar(40)` |  |  |  |
| `reason` | `varchar(1000)` | x |  |  |
| `trace_id` | `char(32)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `subscription_state_history`

### 3.20. `version_state_history`

::: dac-ta
**Mục đích.** Lịch sử chuyển trạng thái phiên bản API: trước, sau, người, lý do bắt buộc (BR-02-028). Chỉ thêm, giữ vĩnh viễn (NFR-02-017). SLA đọc bảng này để trừ các khoảng SUSPENDED do quyết định quản lý (SDD 4.12).

**FR phục vụ.** FR-02-034…039, 056.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`.

**Ràng buộc CHECK.** `ck_version_state_history_tenant`, `ck_version_state_history_reason`, `ck_version_state_history_trace`.

**Chỉ mục.** `ix_version_state_history_version`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_version_state_history_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_version_state_history_append_only`); Thu quyền UPDATE, DELETE của `ph02_app` (lớp thứ hai).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `from_status` | `varchar(10)` |  |  |  |
| `to_status` | `varchar(10)` | x |  |  |
| `command` | `varchar(24)` | x |  | register, submit, withdraw, reject, approve, publish, suspend, resume, deprecate, retire, supersede, discard. |
| `reason_code` | `varchar(40)` |  |  |  |
| `reason` | `varchar(1000)` | x |  |  |
| `trace_id` | `char(32)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `version_state_history`

### 3.21. `grant_job`

::: dac-ta
**Mục đích.** Saga bền cấp phạm vi và thu hồi (SDD 4.9): CREDENTIAL_CHECK → SCOPE_ATTACH (PH-12) → GATEWAY_APPLY (PH-03) → GRANTED. Mỗi bước lũy đẳng theo khóa grant:{subscriptionId}:{generation}:{bước}; thử lại lùi dần tối đa 5 lần trong 15 phút (attempts ≤ 5). Worker lấy việc bằng FOR UPDATE SKIP LOCKED.

**FR phục vụ.** FR-02-048, 051.

**Khóa chính.** (id).

**Duy nhất.** `uq_grant_job_generation` (subscription_id, kind, generation).

**Khóa ngoại.** (subscription_id, tenant_id) → `subscription`.

**Ràng buộc CHECK.** `ck_grant_job_tenant`, `ck_grant_job_kind`, `ck_grant_job_step`, `ck_grant_job_status`, `ck_grant_job_attempts`, `ck_grant_job_finished`.

**Chỉ mục.** `ix_grant_job_due`, `ix_grant_job_awaiting`, `ix_grant_job_cleanup`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_grant_job_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `subscription_id` | `uuid` | x |  |  |
| `kind` | `varchar(6)` | x | `'ATTACH'` |  |
| `generation` | `integer` | x | `1` | Số lần cấp lại; mỗi lần "Cấp lại" tạo dòng mới thay vì sửa dòng đã FAILED. |
| `step` | `varchar(16)` | x | `'CREDENTIAL_CHECK'` |  |
| `status` | `varchar(20)` | x | `'NEW'` |  |
| `attempts` | `smallint` | x | `0` |  |
| `next_attempt_at` | `timestamptz` | x | `now()` |  |
| `last_error_code` | `varchar(16)` |  |  |  |
| `cleanup_mark` | `boolean` | x | `false` | Phần đã gắn thành công của saga thất bại, không tự gỡ; GrantJanitor dọn khi TO chọn Cấp lại hoặc Hủy cấp. |
| `finished_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `grant_job`

### 3.22. `review_request`

::: dac-ta
**Mục đích.** EN-02-09 Yêu cầu duyệt: công bố, ngừng khuyến nghị, ngừng hẳn, công bố và ngừng gói, nâng mức hiển thị, đăng ký sử dụng (FR-02-030, 034, 035, 038, 039, 041, 047). Một yêu cầu OPEN mỗi đối tượng (uq_review_request_one_open). Chuyển sang APPROVED chỉ khi đủ chữ ký (tg_review_request_approve_gate): API SENSITIVE cần hai người CA và TA khác nhau (BR-02-008).

**FR phục vụ.** FR-02-030, 034, 035, 038, 039, 041, 047.

**Khóa chính.** (id).

**Duy nhất.** `uq_review_request_requester` (id, requested_by, tenant_id), `uq_review_request_one_open` (tenant_id, subject_kind, subject_id) từng phần WHERE status = 'OPEN'.

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`.

**Ràng buộc CHECK.** `ck_review_request_tenant`, `ck_review_request_kind`, `ck_review_request_subject`, `ck_review_request_version`, `ck_review_request_status`, `ck_review_request_approvals`, `ck_review_request_decided`, `ck_review_request_payload`, `ck_review_request_spec`.

**Chỉ mục.** `ix_review_request_inbox`, `ix_review_request_overdue`, `ix_review_request_version`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_review_request_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger chốt chặn `tg_review_request_approve_gate`: tg_review_request_approve_gate.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `kind` | `varchar(14)` | x |  | `PUBLISH`, `DEPRECATE`, `RETIRE`, `PLAN_PUBLISH`, `PLAN_DEPRECATE`, `VISIBILITY`, `SUBSCRIBE`. API trả `VERSION_PUBLISH`, `VERSION_DEPRECATE`, `VERSION_RETIRE`, `VISIBILITY_RAISE`, `SUBSCRIPTION` (ánh xạ ở dịch vụ); `PLAN_CLOSE`, `BACKEND_CHANGE`, `SUBSCRIPTION_RENEW` của API chưa có ở DDL (Q02-61). |
| `subject_kind` | `varchar(12)` | x |  | `API_VERSION`, `PLAN`, `SUBSCRIPTION`, `API`, khớp `kind` theo `ck_review_request_subject`. |
| `subject_id` | `uuid` | x |  | Khóa của đối tượng được duyệt theo `subject_kind`. |
| `api_version_id` | `uuid` |  |  | Phiên bản liên quan; bắt buộc trừ `kind = VISIBILITY`. |
| `status` | `varchar(9)` | x | `'OPEN'` | `OPEN`, `APPROVED`, `REJECTED`, `WITHDRAWN`. API và FRS gọi `OPEN` là `PENDING` (ánh xạ ở dịch vụ, Q02-61). |
| `requested_by` | `varchar(64)` | x |  |  |
| `requested_at` | `timestamptz` | x | `now()` |  |
| `required_approvals` | `smallint` | x | `1` | 1, hoặc 2 với API SENSITIVE (xác nhận của CA và TA là hai người khác nhau). |
| `spec_sha256` | `char(64)` |  |  | Băm đặc tả lúc gửi duyệt; lệch lúc duyệt thì đưa về DRAFT (ERR-02-015). |
| `payload` | `jsonb` | x | `'{}'` | Tham số của yêu cầu: sunsetAt, successorVersionId, urgentReason (DEPRECATE); visibility đích (VISIBILITY). |
| `comment` | `varchar(1000)` |  |  |  |
| `due_at` | `timestamptz` |  |  |  |
| `overdue_notified_at` | `timestamptz` |  |  |  |
| `decided_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `review_request`

### 3.23. `version_contributor`

::: dac-ta
**Mục đích.** Người tạo, người sửa gần nhất đặc tả, người sửa gần nhất gói và người gửi duyệt của phiên bản, để ReviewPolicy so theo định danh người dùng, không theo vai trò (BR-02-008, ADR-046). Mỗi vai trò một dòng được ghi đè khi có người sửa mới.

**FR phục vụ.** FR-02-034, 035.

**Khóa chính.** (id).

**Duy nhất.** `uq_version_contributor` (api_version_id, contributor_role).

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`.

**Ràng buộc CHECK.** `ck_version_contributor_tenant`, `ck_version_contributor_role`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_version_contributor_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `contributor_role` | `varchar(12)` | x |  |  |
| `user_id` | `varchar(64)` | x |  |  |
| `acted_at` | `timestamptz` | x | `now()` |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `version_contributor`

### 3.24. `review_decision`

::: dac-ta
**Mục đích.** Quyết định của từng người trên yêu cầu duyệt, mỗi người một quyết định (uq_review_decision_person). Bốn mắt chốt ở CSDL: người duyệt khác người gửi (khóa ngoại ba cột kèm ck_review_decision_four_eyes), khác người sửa đặc tả hoặc gói gần nhất, SV không duyệt công bố hay vòng đời (trigger tg_review_decision_independent, BR-02-008). Chỉ thêm.

**FR phục vụ.** FR-02-035, 047.

**Khóa chính.** (id).

**Duy nhất.** `uq_review_decision_person` (review_request_id, decided_by).

**Khóa ngoại.** (review_request_id, requested_by, tenant_id) → `review_request`.

**Ràng buộc CHECK.** `ck_review_decision_tenant`, `ck_review_decision_value`, `ck_review_decision_role`, `ck_review_decision_four_eyes`, `ck_review_decision_reject_comment`.

**Chỉ mục.** `ix_review_decision_request`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_review_decision_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_review_decision_append_only`); Thu quyền UPDATE, DELETE của `ph02_app` (lớp thứ hai); Trigger chốt chặn `tg_review_decision_independent`: tg_review_decision_independent.

**Ghi chú.** Cột `requested_by` sao từ yêu cầu duyệt để CHECK bốn mắt thực hiện được trong một bảng.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `review_request_id` | `uuid` | x |  |  |
| `requested_by` | `varchar(64)` | x |  | Sao từ review_request.requested_by qua khóa ngoại ba cột; làm cho CHECK so sánh người duyệt với người gửi thực hiện được trong một bảng. |
| `decision` | `varchar(7)` | x |  |  |
| `decided_by` | `varchar(64)` | x |  |  |
| `decider_role` | `varchar(2)` | x |  | Vai trò người duyệt lúc quyết định: CA người duyệt dịch vụ, TA quản trị tenant, SV chủ dịch vụ (chỉ được duyệt đăng ký dưới mức Hạn chế). |
| `comment` | `varchar(1000)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `review_decision`

### 3.25. `deprecation_reminder`

::: dac-ta
**Mục đích.** Mốc nhắc trước hạn ngừng hẳn theo 02.deprecation.reminders (mặc định 90, 30, 7 ngày; BR-02-004, FR-02-038, 057). Tạo khi phiên bản sang DEPRECATED; mốc đã qua lúc tạo ghi SKIPPED.

**FR phục vụ.** FR-02-038, 057.

**Khóa chính.** (id).

**Duy nhất.** `uq_deprecation_reminder` (api_version_id, days_before).

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`.

**Ràng buộc CHECK.** `ck_deprecation_reminder_tenant`, `ck_deprecation_reminder_days`, `ck_deprecation_reminder_status`, `ck_deprecation_reminder_sent`.

**Chỉ mục.** `ix_deprecation_reminder_due`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_deprecation_reminder_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `days_before` | `smallint` | x |  |  |
| `due_at` | `timestamptz` | x |  |  |
| `status` | `varchar(9)` | x | `'SCHEDULED'` |  |
| `sent_at` | `timestamptz` |  |  |  |
| `notice_id` | `uuid` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `deprecation_reminder`

### 3.26. `change_notice`

::: dac-ta
**Mục đích.** EN-02-11 Thông báo thay đổi gửi bên khai thác (FR-02-057). Loại bắt buộc (phiên bản phá vỡ, ngừng khuyến nghị, tạm ngừng, tiếp tục, ngừng hẳn, SLA kém đi, hạ mức hiển thị, quyết định đăng ký) bên nhận không tắt được (BR-02-029, ck_change_notice_mandatory); chỉ ANNOUNCEMENT (thông báo tay của SV) là không bắt buộc, giới hạn 02.notice.announcement-max-per-day. Giữ 2 năm (NFR-02-017).

**FR phục vụ.** FR-02-057.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`.

**Ràng buộc CHECK.** `ck_change_notice_tenant`, `ck_change_notice_kind`, `ck_change_notice_mandatory`, `ck_change_notice_status`, `ck_change_notice_recipients`.

**Chỉ mục.** `ix_change_notice_version`, `ix_change_notice_open`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_change_notice_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `kind` | `varchar(22)` | x |  |  |
| `mandatory` | `boolean` | x | `true` |  |
| `subject` | `varchar(255)` | x |  |  |
| `body` | `varchar(4000)` | x |  | Nội dung đã qua mẫu NoticeTemplates, giá trị chèn đã thoát ký tự và cắt độ dài; không liệt kê các bên khai thác khác. |
| `template_code` | `varchar(32)` |  |  |  |
| `template_version` | `smallint` |  |  |  |
| `recipient_count` | `integer` | x | `0` |  |
| `status` | `varchar(7)` | x | `'QUEUED'` |  |
| `issued_by` | `varchar(64)` | x |  |  |
| `issued_at` | `timestamptz` | x | `now()` |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `change_notice`

### 3.27. `change_notice_recipient`

::: dac-ta
**Mục đích.** Người nhận và kết quả gửi theo từng kênh (FR-02-057, NFR-02-015). recipient_ref là mã người dùng hoặc đầu mối ở PH-01, không lưu địa chỉ thư; PH-18 phân giải khi gửi. Khóa duy nhất (notice, recipient, channel) tương ứng khóa lũy đẳng {noticeId}:{recipient}:{channel} gọi PH-18, nên gửi lại sau sự cố không tạo thư trùng.

**FR phục vụ.** FR-02-057.

**Khóa chính.** (id).

**Duy nhất.** `uq_change_notice_recipient` (notice_id, recipient_ref, channel).

**Khóa ngoại.** (notice_id, tenant_id) → `change_notice` xóa theo.

**Ràng buộc CHECK.** `ck_change_notice_recipient_tenant`, `ck_change_notice_recipient_channel`, `ck_change_notice_recipient_status`, `ck_change_notice_recipient_delivered`.

**Chỉ mục.** `ix_change_notice_recipient_pending`, `ix_change_notice_recipient_system`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_change_notice_recipient_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `notice_id` | `uuid` | x |  |  |
| `recipient_ref` | `varchar(128)` | x |  |  |
| `system_code` | `varchar(64)` | x |  |  |
| `channel` | `varchar(6)` | x |  |  |
| `status` | `varchar(9)` | x | `'PENDING'` |  |
| `attempts` | `smallint` | x | `0` |  |
| `error_code` | `varchar(16)` |  |  |  |
| `delivered_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `change_notice_recipient`

### 3.28. `sla_commitment`

::: dac-ta
**Mục đích.** EN-02-08 Cam kết SLA của phiên bản (FR-02-055): độ trễ p99, tỷ lệ sẵn sàng, hạn mức giờ, giờ phục vụ. Chỉ thêm; mỗi lần khai báo là một dòng có effective_from, giữ vĩnh viễn (NFR-02-017). Cam kết kém đi chỉ có hiệu lực sau ít nhất 7 ngày kể từ lúc phát thông báo bắt buộc (worsening, notice_id; 02.sla.worsen-notice-days từ 7 đến 180 kiểm ở dịch vụ, BR-02-029).

**FR phục vụ.** FR-02-055.

**Khóa chính.** (id).

**Duy nhất.** `uq_sla_commitment_effective` (api_version_id, effective_from).

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`, (notice_id, tenant_id) → `change_notice`.

**Ràng buộc CHECK.** `ck_sla_commitment_tenant`, `ck_sla_commitment_latency`, `ck_sla_commitment_availability`, `ck_sla_commitment_hourly`, `ck_sla_commitment_hours`, `ck_sla_commitment_worsen`.

**Chỉ mục.** `ix_sla_commitment_version`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_sla_commitment_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_sla_commitment_append_only`); Thu quyền UPDATE, DELETE của `ph02_app` (lớp thứ hai).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `latency_p99_ms` | `integer` | x |  |  |
| `availability_pct` | `numeric(6,3)` | x |  | Tỷ lệ sẵn sàng cam kết theo phần trăm, ví dụ 99.500; đo bằng 1 − lượt lỗi hệ thống / tổng lượt gọi (Q02-13). |
| `hourly_limit` | `integer` |  |  |  |
| `service_hours` | `jsonb` | x | `'{"mode":"24x7"}'` | {"mode":"24x7"} hoặc {"mode":"WINDOW","days":[1,2,3,4,5],"from":"07:30","to":"17:00","tz":"Asia/Ho_Chi_Minh"}. |
| `worsening` | `boolean` | x | `false` |  |
| `notice_id` | `uuid` |  |  |  |
| `effective_from` | `timestamptz` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `sla_commitment`

### 3.29. `sla_maintenance_window`

::: dac-ta
**Mục đích.** Cửa sổ bảo trì đã khai báo; SlaEvaluator trừ khoảng này khi tính tỷ lệ sẵn sàng (FR-02-056). Mỗi cửa sổ không quá 24 giờ và không chồng nhau trong một phiên bản (ex_sla_maintenance_window_overlap).

**FR phục vụ.** FR-02-056.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`.

**Ràng buộc CHECK.** `ck_sla_maintenance_window_tenant`, `ck_sla_maintenance_window_range`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_sla_maintenance_window_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Ràng buộc loại trừ: `ex_sla_maintenance_window_overlap`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `starts_at` | `timestamptz` | x |  |  |
| `ends_at` | `timestamptz` | x |  |  |
| `reason` | `varchar(1000)` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `sla_maintenance_window`

### 3.30. `sla_period`

::: dac-ta
**Mục đích.** Kết quả đối chiếu SLA theo kỳ tháng YYYY-MM (FR-02-056). INSUFFICIENT là "Chưa đủ dữ liệu", không tính vào chuỗi không đạt (BR-02-031). "Chốt lại kỳ" tạo dòng result_version mới và hạ is_current của dòng cũ, không xóa kết quả cũ. Giữ 3 năm (NFR-02-017).

**FR phục vụ.** FR-02-056.

**Khóa chính.** (id).

**Duy nhất.** `uq_sla_period_result` (api_version_id, period, result_version), `uq_sla_period_current` (api_version_id, period) từng phần WHERE is_current.

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`, (commitment_id, tenant_id) → `sla_commitment`.

**Ràng buộc CHECK.** `ck_sla_period_tenant`, `ck_sla_period_format`, `ck_sla_period_status`, `ck_sla_period_met`, `ck_sla_period_actual`, `ck_sla_period_result`.

**Chỉ mục.** `ix_sla_period_pending`, `ix_sla_period_breach`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_sla_period_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `period` | `char(7)` | x |  |  |
| `result_version` | `integer` | x | `1` |  |
| `is_current` | `boolean` | x | `true` |  |
| `commitment_id` | `uuid` |  |  |  |
| `status` | `varchar(12)` | x | `'PENDING'` |  |
| `met` | `boolean` |  |  |  |
| `actual` | `jsonb` | x | `'{}'` | Số đo từ PH-13: {p99Ms, calls, systemErrors, daysWithData, peakHourly, availabilityPct, excludedMinutes}. |
| `recalculated_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `sla_period`

### 3.31. `usage_daily`

::: dac-ta
**Mục đích.** Thống kê sử dụng theo ngày, thao tác, HTTT khai thác, kéo từ PH-13 mỗi giờ cho ngày hiện tại (FR-02-058, Đợt 2). Khóa tự nhiên, không có id; phân vùng tháng theo usage_date, giữ 2 năm (giả định, Q02-50). SV, CA, TA thấy chi tiết theo HTTT; VW chỉ thấy tổng hợp không tên bên khai thác (tính ở dịch vụ). Không chứa nội dung bản tin.

**FR phục vụ.** FR-02-058.

**Khóa chính.** (tenant_id, api_version_id, usage_date, operation_id, consumer_system_code).

**Duy nhất.** Không.

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`.

**Ràng buộc CHECK.** `ck_usage_daily_tenant`, `ck_usage_daily_counts`, `ck_usage_daily_p95`.

**Chỉ mục.** `ix_usage_daily_consumer`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_usage_daily_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Phân vùng RANGE theo tháng trên `usage_date` (thủ tục `p_ensure_month_partitions`); không cấp quyền trực tiếp lên phân vùng, dọn dữ liệu hết hạn bằng DETACH PARTITION.

**Ghi chú.** Khóa tự nhiên (tenant, phiên bản, ngày, thao tác, HTTT khai thác), không có `id` và cột sửa; làm mới theo giờ từ PH-13.
:::

Phân vùng: `RANGE (usage_date)` theo tháng, tên phân vùng `usage_daily_YYYYMM`.

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `usage_date` | `date` | x |  |  |
| `operation_id` | `varchar(128)` | x |  |  |
| `consumer_system_code` | `varchar(64)` | x |  |  |
| `calls` | `bigint` | x | `0` |  |
| `errors` | `bigint` | x | `0` |  |
| `p95_ms` | `integer` |  |  |  |
| `refreshed_at` | `timestamptz` | x | `now()` |  |

: Cột của bảng `usage_daily`

### 3.32. `national_sync_record`

::: dac-ta
**Mục đích.** EN-02-10 Hàng đợi bền đồng bộ danh mục lên Nền tảng quốc gia qua PH-14 (FR-02-053, 054; BR-02-009). Xếp hàng trong cùng giao dịch với thay đổi gốc (ADR-042, ADR-057). Khóa duy nhất từng phần (version, payload_hash) khi chưa kết thúc làm cho xếp hàng lặp lại vô hại; sau ACKED hoặc REJECTED cho phép bản ghi mới cùng băm (lệch so với SDD 4.11, ghi ở 3.x của tài liệu). Giữ 5 năm (NFR-02-017). Giao thức còn chờ đặc tả (Q02-08).

**FR phục vụ.** FR-02-053, 054.

**Khóa chính.** (id).

**Duy nhất.** `uq_national_sync_record_pending` (tenant_id, api_version_id, payload_hash) từng phần WHERE status IN ('QUEUED', 'SENT', 'FAILED').

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`.

**Ràng buộc CHECK.** `ck_national_sync_record_tenant`, `ck_national_sync_record_action`, `ck_national_sync_record_status`, `ck_national_sync_record_hash`, `ck_national_sync_record_acked`, `ck_national_sync_record_rejected`, `ck_national_sync_record_sent`.

**Chỉ mục.** `ix_national_sync_record_due`, `ix_national_sync_record_version`, `ix_national_sync_record_acked`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_national_sync_record_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `api_version_id` | `uuid` | x |  |  |
| `action` | `varchar(8)` | x |  |  |
| `status` | `varchar(8)` | x | `'QUEUED'` | QUEUED, SENT, ACKED, REJECTED, FAILED; lỗi tạm thời FAILED lùi dần 1, 5, 15, 60 phút rồi mỗi 6 giờ; REJECTED không tự gửi lại khi nội dung không đổi. |
| `payload_hash` | `char(64)` | x |  | Băm chuẩn của NationalServicePayload (mã dịch vụ, tên, mô tả, đơn vị, mức phân loại, địa chỉ công khai, SLA, trạng thái, đầu mối); đồng thời là Idempotency-Key gọi PH-14. Gói không có backend, địa chỉ nội bộ, danh sách bên đăng ký hay dữ liệu cá nhân. |
| `national_ref` | `varchar(128)` |  |  |  |
| `reject_code` | `varchar(32)` |  |  |  |
| `reject_reason` | `varchar(1000)` |  |  |  |
| `attempts` | `smallint` | x | `0` |  |
| `next_attempt_at` | `timestamptz` | x | `now()` |  |
| `sent_at` | `timestamptz` |  |  |  |
| `acked_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `national_sync_record`

### 3.33. `national_sync_run`

::: dac-ta
**Mục đích.** Lần chạy đối chiếu danh mục quốc gia theo 02.sync.cron hoặc lệnh "Đồng bộ ngay" (FR-02-054): số phiên bản đủ điều kiện, số đã xếp hàng, số quá hạn (căn cứ chỉ số catalog_national_sync_overdue_total). Giữ 5 năm cùng national_sync_record.

**FR phục vụ.** FR-02-054.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_national_sync_run_tenant`, `ck_national_sync_run_trigger`, `ck_national_sync_run_status`, `ck_national_sync_run_finished`, `ck_national_sync_run_counts`.

**Chỉ mục.** `ix_national_sync_run_started`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_national_sync_run_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `trigger_kind` | `varchar(6)` | x |  |  |
| `status` | `varchar(7)` | x | `'RUNNING'` |  |
| `started_at` | `timestamptz` | x | `now()` |  |
| `finished_at` | `timestamptz` |  |  |  |
| `eligible_count` | `integer` | x | `0` |  |
| `queued_count` | `integer` | x | `0` |  |
| `overdue_count` | `integer` | x | `0` |  |
| `error_code` | `varchar(16)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `national_sync_run`

### 3.34. `config_epoch`

::: dac-ta
**Mục đích.** Bộ đếm source_version theo (tenant, môi trường): thay đổi dữ liệu mà gateway cần biết gọi UPDATE … SET source_version = source_version + 1 RETURNING ở câu lệnh cuối của giao dịch, khóa dòng này tuần tự hóa các giao dịch cùng môi trường trong khoảng ngắn nhất (SDD 4.10). Là ETag của giao diện nội bộ API-02-080 (FR-02-059). source_version chỉ tăng (tg_config_epoch_monotonic). Dòng được tạo khi cấp phát tenant.

**FR phục vụ.** FR-02-036, 059.

**Khóa chính.** (id).

**Duy nhất.** `uq_config_epoch` (tenant_id, env).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_config_epoch_tenant`, `ck_config_epoch_env`, `ck_config_epoch_source`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_config_epoch_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Trigger chốt chặn `tg_config_epoch_monotonic`: tg_config_epoch_monotonic.

**Ghi chú.** Bộ đếm cấu hình, dòng bị khóa ở câu lệnh cuối của mọi giao dịch đổi dữ liệu gateway cần biết; tạo khi cấp phát tenant.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `env` | `varchar(8)` | x |  |  |
| `source_version` | `bigint` | x | `0` |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `config_epoch`

### 3.35. `config_change_log`

::: dac-ta
**Mục đích.** Nhật ký thay đổi theo source_version để PH-03 gọi changesSince(sourceVersion) (FR-02-059). Giữ 30 ngày (dh.catalog.config.change-log-retention); hỏi quá cũ thì phản hồi gap = true để PH-03 lấy toàn bộ. Phân vùng tháng theo created_at, dọn bằng DETACH PARTITION. Tính duy nhất của (tenant, env, source_version) do khóa dòng config_epoch bảo đảm.

**FR phục vụ.** FR-02-059.

**Khóa chính.** (id, created_at).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_config_change_log_tenant`, `ck_config_change_log_env`, `ck_config_change_log_subject`, `ck_config_change_log_trace`.

**Chỉ mục.** `ix_config_change_log_epoch`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_config_change_log_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Phân vùng RANGE theo tháng trên `created_at` (thủ tục `p_ensure_month_partitions`); không cấp quyền trực tiếp lên phân vùng, dọn dữ liệu hết hạn bằng DETACH PARTITION.

**Ghi chú.** Chỉ thêm; tính duy nhất của `(tenant, env, source_version)` do khóa dòng `config_epoch` bảo đảm.
:::

Phân vùng: `RANGE (created_at)` theo tháng, tên phân vùng `config_change_log_YYYYMM`.

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `env` | `varchar(8)` | x |  |  |
| `source_version` | `bigint` | x |  |  |
| `change_kind` | `varchar(24)` | x |  |  |
| `subject_kind` | `varchar(14)` | x |  |  |
| `subject_id` | `uuid` | x |  |  |
| `api_code` | `varchar(63)` |  |  |  |
| `trace_id` | `char(32)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `config_change_log`

### 3.36. `publish_job`

::: dac-ta
**Mục đích.** Việc công bố có xác nhận (FR-02-036, 037, 048): tạo cùng giao dịch với quyết định; PublishJobWorker lấy bằng FOR UPDATE SKIP LOCKED, gọi GatewayApplyPort lũy đẳng theo (env, sourceVersion), chờ APISIX báo sourceVersion ≥ mục tiêu. Loại CONFIRM_THEN_WRITE (công bố, tiếp tục, cấp phạm vi) chỉ ghi trạng thái sau khi có xác nhận; WRITE_THEN_CONFIRM (tạm ngừng, ngừng, thu hồi) ghi ngay rồi xác nhận sau. Hết 5 lần thử trong khoảng 15 phút thì FAILED, phiên bản giữ PENDING (ERR-02-033).

**FR phục vụ.** FR-02-036, 037, 048.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_publish_job_tenant`, `ck_publish_job_env`, `ck_publish_job_subject`, `ck_publish_job_policy`, `ck_publish_job_status`, `ck_publish_job_attempts`, `ck_publish_job_confirmed`.

**Chỉ mục.** `ix_publish_job_due`, `ix_publish_job_wait`, `ix_publish_job_subject`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_publish_job_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `env` | `varchar(8)` | x |  |  |
| `subject_kind` | `varchar(12)` | x |  |  |
| `subject_id` | `uuid` | x |  |  |
| `transition` | `varchar(24)` | x |  |  |
| `policy` | `varchar(18)` | x |  |  |
| `target_source_version` | `bigint` | x |  | source_version của config_epoch tại thời điểm quyết định; gom nhiều việc cùng môi trường vào một xác nhận khi ack.sourceVersion ≥ giá trị này. |
| `status` | `varchar(12)` | x | `'QUEUED'` |  |
| `attempts` | `smallint` | x | `0` |  |
| `next_attempt_at` | `timestamptz` | x | `now()` |  |
| `ticket` | `varchar(64)` |  |  |  |
| `last_error_code` | `varchar(16)` |  |  |  |
| `confirmed_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `publish_job`

### 3.37. `gateway_drift`

::: dac-ta
**Mục đích.** Lệch cấu hình gateway so với dữ liệu công bố (FR-02-060, Đợt 2, NFR-02-020): DriftReconciler chạy 5 phút một lần, so băm nguồn của từng route. Route thừa (EXTRA_ROUTE) không tự gỡ mà cảnh báo SO vì có thể là tấn công hoặc sửa tay (SEC-65). Mỗi (môi trường, loại, route) chỉ một dòng OPEN.

**FR phục vụ.** FR-02-060.

**Khóa chính.** (id).

**Duy nhất.** `uq_gateway_drift_open` (tenant_id, env, kind, route_ref) từng phần WHERE status = 'OPEN'.

**Khóa ngoại.** (api_version_id, tenant_id) → `api_version`.

**Ràng buộc CHECK.** `ck_gateway_drift_tenant`, `ck_gateway_drift_env`, `ck_gateway_drift_kind`, `ck_gateway_drift_status`, `ck_gateway_drift_resolved`.

**Chỉ mục.** `ix_gateway_drift_detected`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_gateway_drift_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `env` | `varchar(8)` | x |  |  |
| `kind` | `varchar(18)` | x |  |  |
| `route_ref` | `varchar(255)` | x |  |  |
| `api_version_id` | `uuid` |  |  |  |
| `expected_hash` | `char(64)` |  |  |  |
| `actual_hash` | `char(64)` |  |  |  |
| `pod` | `varchar(64)` |  |  |  |
| `status` | `varchar(12)` | x | `'OPEN'` |  |
| `detected_at` | `timestamptz` | x | `now()` |  |
| `resolved_at` | `timestamptz` |  |  |  |
| `resolved_by` | `varchar(64)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `gateway_drift`

### 3.38. `async_operation`

::: dac-ta
**Mục đích.** Thao tác bất đồng bộ có tiến độ theo FR-00-054: sinh khung route (FR-02-026), so sánh đặc tả lớn (FR-02-043), nhập hệ cũ (FR-02-061), đồng bộ lại đặc tả từ URL (FR-02-012). Giữ 30 ngày, dọn bằng tác vụ định kỳ (giả định).

**FR phục vụ.** FR-02-012, 026, 043, 061.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_async_operation_tenant`, `ck_async_operation_kind`, `ck_async_operation_status`, `ck_async_operation_progress`, `ck_async_operation_finished`, `ck_async_operation_error`.

**Chỉ mục.** `ix_async_operation_user`, `ix_async_operation_open`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_async_operation_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `kind` | `varchar(22)` | x |  |  |
| `subject_kind` | `varchar(12)` |  |  |  |
| `subject_id` | `uuid` |  |  |  |
| `status` | `varchar(9)` | x | `'QUEUED'` |  |
| `progress` | `smallint` | x | `0` |  |
| `result` | `jsonb` |  |  |  |
| `error_code` | `varchar(16)` |  |  |  |
| `requested_by` | `varchar(64)` | x |  |  |
| `started_at` | `timestamptz` |  |  |  |
| `finished_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `async_operation`

### 3.39. `pending_command`

::: dac-ta
**Mục đích.** Lệnh gọi phân hệ ngoài chờ thử lại lùi dần khi đích ngừng (SDD 4.15, ERR-02-034): tạo khung luồng ở PH-04, gắn phạm vi ở PH-12, thông báo PH-18. Khóa lũy đẳng duy nhất theo (đích, khóa) nên xếp hàng lặp lại vô hại. Không chứa bí mật (ck_pending_command_payload). Dòng DONE dọn sau 7 ngày, DEAD giữ 90 ngày để điều tra (giả định).

**FR phục vụ.** FR-02-013, 026, 048, 057.

**Khóa chính.** (id).

**Duy nhất.** `uq_pending_command` (tenant_id, target, idempotency_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_pending_command_tenant`, `ck_pending_command_target`, `ck_pending_command_status`, `ck_pending_command_payload`.

**Chỉ mục.** `ix_pending_command_due`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_pending_command_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `target` | `varchar(14)` | x |  |  |
| `command` | `varchar(48)` | x |  |  |
| `payload` | `jsonb` | x |  |  |
| `idempotency_key` | `varchar(128)` | x |  |  |
| `status` | `varchar(7)` | x | `'PENDING'` |  |
| `attempts` | `smallint` | x | `0` |  |
| `next_attempt_at` | `timestamptz` | x | `now()` |  |
| `last_error_code` | `varchar(16)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `pending_command`

### 3.40. `inbox_event`

::: dac-ta
**Mục đích.** Hộp nhận: ghi event_id trước khi xử lý sự kiện của PH-01, PH-04, PH-10 để sự kiện phát lại không tạo hiệu ứng thứ hai (SDD 8.2). Khóa là mã sự kiện, không có id riêng. Dọn sau 7 ngày (giả định, dài hơn thời gian giữ topic).

**FR phục vụ.** FR-02-009, 013, 051.

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_inbox_event_tenant`, `ck_inbox_event_source`.

**Chỉ mục.** `ix_inbox_event_received`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_inbox_event_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Ghi `event_id` trước khi xử lý để sự kiện phát lại không tạo hiệu ứng thứ hai; khóa là mã sự kiện nên không có `id` riêng.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `event_id` | `uuid` | x |  |  |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `source` | `varchar(8)` | x |  |  |
| `event_type` | `varchar(128)` | x |  |  |
| `received_at` | `timestamptz` | x | `now()` |  |
| `processed_at` | `timestamptz` |  |  |  |

: Cột của bảng `inbox_event`

### 3.41. `outbox_event`

::: dac-ta
**Mục đích.** Hộp gửi (DD-11, ADR-042) cho EVT-02-01…16: ghi cùng giao dịch với thay đổi gốc, Debezium outbox router hoặc OutboxPublisher quét 500 ms đưa lên Kafka kèm tiêu đề CloudEvents. Topic {tenant}.catalog.{thực-thể}.{sự-kiện}.v1 đúng tenant; khóa phân vùng là apiCode để sự kiện của một API đến theo thứ tự. Không chứa nội dung đặc tả, dữ liệu cá nhân hay bí mật, chỉ mã định danh và trường thay đổi. Dọn dòng đã phát sau 3 ngày; cảnh báo khi dòng chưa phát cũ nhất quá 5 phút.

**FR phục vụ.** Mọi FR phát sự kiện EVT-02-01…16.

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_event_tenant`, `ck_outbox_event_type`, `ck_outbox_event_topic`, `ck_outbox_event_topic_tenant`, `ck_outbox_event_trace`, `ck_outbox_event_payload`, `ck_outbox_event_no_secret`.

**Chỉ mục.** `ix_outbox_event_unpublished`, `ix_outbox_event_published`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_outbox_event_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** `ph02_app` chỉ được UPDATE cột `published_at`.

**Ghi chú.** Debezium outbox router đọc WAL (hoặc `OutboxPublisher` quét 500 ms) rồi phát lên Kafka kèm tiêu đề CloudEvents; ghi cùng giao dịch với thay đổi gốc (ADR-042). Ứng dụng chỉ được cập nhật `published_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `event_id` | `uuid` | x |  |  |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `event_type` | `varchar(128)` | x |  |  |
| `topic` | `varchar(249)` | x |  |  |
| `aggregate_type` | `varchar(32)` | x |  |  |
| `aggregate_id` | `varchar(128)` | x |  |  |
| `partition_key` | `varchar(128)` | x |  | apiCode (hoặc mã đối tượng) làm khóa phân vùng Kafka. |
| `payload` | `jsonb` | x |  |  |
| `trace_id` | `char(32)` | x |  |  |
| `occurred_at` | `timestamptz` | x | `now()` |  |
| `published_at` | `timestamptz` |  |  |  |

: Cột của bảng `outbox_event`

### 3.42. `idempotency_record`

::: dac-ta
**Mục đích.** Lũy đẳng của lệnh POST đổi trạng thái (SDD 8.5): ghi (tenant, người, khóa) kèm băm yêu cầu và phản hồi trong 24 giờ ở cùng giao dịch với tác dụng. Cùng khóa cùng thân trả lại phản hồi cũ; cùng khóa khác băm thì ERR-02-042 (422). Chỉ dùng PostgreSQL, không cần Valkey vì tần suất lệnh thấp. Dọn khi quá expires_at.

**FR phục vụ.** Mọi lệnh POST đổi trạng thái (FR-00).

**Khóa chính.** (id).

**Duy nhất.** `uq_idempotency_record` (tenant_id, principal, idem_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_idempotency_record_tenant`, `ck_idempotency_record_hash`, `ck_idempotency_record_status`, `ck_idempotency_record_ttl`.

**Chỉ mục.** `ix_idempotency_record_expiry`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_idempotency_record_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Không có `updated_*` và `version`; hết hạn sau tối đa 48 giờ, dọn theo `expires_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `principal` | `varchar(64)` | x |  |  |
| `idem_key` | `varchar(128)` | x |  |  |
| `request_hash` | `char(64)` | x |  |  |
| `response_status` | `smallint` |  |  |  |
| `response_body` | `jsonb` |  |  |  |
| `expires_at` | `timestamptz` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `idempotency_record`

### 3.43. `job_lease`

::: dac-ta
**Mục đích.** Bảng kỹ thuật của ShedLock cho tác vụ định kỳ của vai trò worker (RetireWatcher, SuspensionWatcher, SyncScheduler, OverdueWatcher, SlaEvaluator, DriftReconciler, RenewalScheduler, dọn dữ liệu). Không có tenant_id, không chứa dữ liệu nghiệp vụ; tác vụ liên tenant lặp từng tenant bên trong khóa. Tên cột theo cấu hình ShedLock JDBC.

**FR phục vụ.** FR-02-038, 039, 052, 054, 056, 060 (tác vụ định kỳ).

**Khóa chính.** (name).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không bật RLS. Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ và không có `tenant_id`; tác vụ liên tenant lặp từng tenant bên trong khóa.

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Xem mục Cách ly tenant.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `name` | `varchar(64)` | x |  |  |
| `lock_until` | `timestamptz` | x |  |  |
| `locked_at` | `timestamptz` | x |  |  |
| `locked_by` | `varchar(255)` | x |  |  |

: Cột của bảng `job_lease`

### 3.44. `import_session`

::: dac-ta
**Mục đích.** Phiên nhập từ APIM cũ (FR-02-061, API-02-085…087): tệp xuất tải lên được quét mã độc, giới hạn 50 MiB, xử lý như đầu vào không tin cậy; kế hoạch ánh xạ ở kho đối tượng legacy/, hạn 24 giờ; khóa và bí mật của hệ cũ không bao giờ được đọc vào mô hình (BR-02-036). Mỗi tenant chỉ một lần nhập đang ghi (ERR-02-035). checksum là SHA-256 danh sách (legacyId, kết quả) đã sắp xếp, hai lần nhập cùng dữ liệu cho cùng tổng kiểm tra (FR-00-092).

**FR phục vụ.** FR-02-061.

**Khóa chính.** (id).

**Duy nhất.** `uq_import_session_one_committing` (tenant_id) từng phần WHERE status = 'COMMITTING'.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_import_session_tenant`, `ck_import_session_sha`, `ck_import_session_size`, `ck_import_session_status`, `ck_import_session_json`, `ck_import_session_report`.

**Chỉ mục.** `ix_import_session_user`, `ix_import_session_expiry`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_import_session_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `file_name` | `varchar(255)` | x |  |  |
| `file_sha256` | `char(64)` | x |  |  |
| `size_bytes` | `integer` | x |  |  |
| `plan_object_key` | `varchar(512)` |  |  |  |
| `report_object_key` | `varchar(512)` |  |  |  |
| `application_map` | `jsonb` | x | `'{}'` | Ánh xạ Application của APIM cũ sang mã HTTT ở PH-01: {"app-id-cu":"MA_HTTT"}; HTTT không ACTIVE bị từ chối (ERR-02-004). |
| `counts` | `jsonb` | x | `'{}'` | Số lượng ở nguồn và đã nhập theo loại: {"api":{"source":n,"imported":n},"plan":{…},"subscription":{…},"secretRemoved":n}. |
| `checksum` | `char(64)` |  |  |  |
| `status` | `varchar(10)` | x | `'UPLOADED'` |  |
| `expires_at` | `timestamptz` | x |  |  |
| `started_by` | `varchar(64)` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `import_session`

### 3.45. `legacy_id_map`

::: dac-ta
**Mục đích.** Ánh xạ định danh APIM cũ sang đối tượng mới, theo từng lần nhập (FR-02-061, FR-00-092). Khóa duy nhất từng phần (tenant, loại, mã cũ) cho kết quả IMPORTED làm cho nhập lại lũy đẳng, một API lỗi không kéo cả đợt (mỗi API một giao dịch); kết quả SKIPPED, FAILED kèm lý do để báo cáo đối chiếu. Giữ vĩnh viễn làm bằng chứng di trú, đầu vào của đối soát D06-01. Chỉ thêm.

**FR phục vụ.** FR-02-061.

**Khóa chính.** (id).

**Duy nhất.** `uq_legacy_id_map_imported` (tenant_id, entity_kind, legacy_id) từng phần WHERE result = 'IMPORTED'.

**Khóa ngoại.** (session_id) → `import_session`.

**Ràng buộc CHECK.** `ck_legacy_id_map_tenant`, `ck_legacy_id_map_kind`, `ck_legacy_id_map_result`, `ck_legacy_id_map_new`.

**Chỉ mục.** `ix_legacy_id_map_session`, `ix_legacy_id_map_new`.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; bốn chính sách `rls_legacy_id_map_select`, `_insert`, `_update`, `_delete` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_legacy_id_map_append_only`); Thu quyền UPDATE, DELETE của `ph02_app` (lớp thứ hai).

**Ghi chú.** Giữ vĩnh viễn làm bằng chứng di trú, đầu vào của đối soát D06-01.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép. |
| `session_id` | `uuid` | x |  |  |
| `entity_kind` | `varchar(12)` | x |  |  |
| `legacy_id` | `varchar(128)` | x |  |  |
| `new_id` | `uuid` |  |  |  |
| `result` | `varchar(8)` | x |  |  |
| `note` | `varchar(500)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `legacy_id_map`

<!-- gen:tables:end -->

### 3.46. Truy vấn chính và chỉ mục phục vụ

Bảng dưới nối các truy vấn nóng của dịch vụ và tác vụ nền với chỉ mục đã tạo. Phần lớn chỉ mục là chỉ mục từng phần (`WHERE`) để nhỏ và chỉ chứa dòng còn việc phải làm, đúng với các bảng việc như `grant_job`, `publish_job`, `national_sync_record`, `review_request`.

| Truy vấn | API, tác vụ | Chỉ mục |
|---|---|---|
| Danh sách API lọc theo HTTT, chủ quản, phân loại, mức hiển thị; tìm theo tên | API-02-001; FR-02-001 | `ix_api_system`, `ix_api_owner`, `ix_api_category`, `ix_api_visibility`, `ix_api_name_trgm` |
| Tìm kiếm toàn văn danh mục, khớp tiền tố mã API | FR-02-003; NFR-02-002 | `ix_api_search_doc_tsv` (GIN), `ix_api_search_doc_code` (trigram) |
| Phiên bản của một API theo trạng thái | Chi tiết API, FR-02-002 | `ix_api_version_api` |
| Thao tác của một phiên bản | FR-02-005, 029; dữ liệu công bố | `ix_api_operation_version` |
| Hộp "Việc của tôi": yêu cầu duyệt đang mở theo loại; yêu cầu quá hạn chưa nhắc | `ReviewOverdueWatcher` mỗi giờ | `ix_review_request_inbox`, `ix_review_request_overdue` |
| Phiên bản `DEPRECATED` tới hạn ngừng hẳn; phiên bản `SUSPENDED` sắp hết hạn tạm ngừng | `RetireWatcher`, `SuspensionWatcher` hằng ngày | `ix_api_version_sunset`, `ix_api_version_suspended` |
| Phiên bản chờ duyệt lâu nhất | Chỉ số `catalog_review_pending_age_seconds` | `ix_api_version_pending` |
| Đăng ký theo gói, theo HTTT, theo phiên bản | API-02-058…068; FR-02-049, 050 | `ix_subscription_plan`, `ix_subscription_system`, `ix_subscription_version` |
| Đăng ký tới hạn hết hiệu lực hoặc rà soát; đăng ký chờ định danh máy | `RenewalScheduler`; `SystemEventHandler` | `ix_subscription_expiry`, `ix_subscription_review`, `ix_subscription_awaiting` |
| Việc cấp quyền đến hạn thử lại (`SKIP LOCKED`) | `GrantOrchestrator` | `ix_grant_job_due`, `ix_grant_job_awaiting`, `ix_grant_job_cleanup` |
| Việc công bố đến hạn; việc chờ xác nhận của một môi trường | `PublishJobWorker` | `ix_publish_job_due`, `ix_publish_job_wait` |
| Hàng đợi đồng bộ quốc gia đến hạn; lần `ACKED` gần nhất của phiên bản | `SyncDispatcher`, `OverdueWatcher` | `ix_national_sync_record_due`, `ix_national_sync_record_acked`, `uq_national_sync_record_pending` |
| Kỳ SLA chờ chốt; chuỗi kỳ không đạt liên tiếp | `SlaEvaluator`; BR-02-031 | `ix_sla_period_pending`, `ix_sla_period_breach` |
| Cam kết SLA hiện hành của phiên bản | FR-02-055, 056 | `ix_sla_commitment_version` |
| Thay đổi cấu hình từ một `sourceVersion` | API-02-080 `changesSince` | `ix_config_change_log_epoch` |
| Người nhận thông báo chưa gửi hoặc gửi lỗi | `NoticeService` | `ix_change_notice_recipient_pending`, `ix_change_notice_open` |
| Sự kiện chưa phát | `OutboxPublisher` quét 500 ms | `ix_outbox_event_unpublished` |
| Giữ chỗ context-path hết hạn; kiểm xung đột tiền tố | `ContextPathService` | `ix_context_path_release`, `ix_context_path_prefix` |
| Phát hiện còn mở của một đặc tả | `SubmissionGate` | `ix_lint_finding_spec` |
| Lệch cấu hình đang mở | `DriftReconciler`; FR-02-060 | `uq_gateway_drift_open` |
| Thống kê theo HTTT khai thác | FR-02-058 | `ix_usage_daily_consumer` |
| Dọn bản ghi lũy đẳng hết hạn | Tác vụ dọn hằng ngày | `ix_idempotency_record_expiry` |

: Truy vấn chính và chỉ mục phục vụ

## 4. DDL và changelog Liquibase

### 4.1. Tệp

[`ph02/ddl/`](ph02/ddl/ph02_all.sql) chứa DDL chia theo vùng nghiệp vụ. Mỗi tệp có dấu `-- @file`, `-- @changeset`, `-- @rollback` như PH-04, PH-05, PH-07 để công cụ [`ph07/tools/gen_liquibase.py`](ph07/tools/gen_liquibase.py) sinh changelog sau khi tham số hóa tên phân hệ; tệp `ph02_all.sql` chỉ nạp các tệp còn lại theo thứ tự để chạy độc lập khi phát triển.

| Tệp | Tệp Liquibase | Nội dung |
|---|---|---|
| `ph02_00_bootstrap.sql` | `02-0000-bootstrap.sql`, `02-0001-functions.sql` | Vai trò, extension `pg_trgm`, `unaccent`, `btree_gist`, schema, biến phiên; hàm `tg_touch`, `p_enable_rls`, `p_ensure_month_partitions`, `tg_append_only`; cấu hình tìm kiếm `vn_unaccent` |
| `ph02_10_catalog.sql` | `02-0010-catalog.sql` | `category`, `code_registry`, `api`, `api_tag`, `api_version` (+ `tg_api_version_guard`), `api_spec`, `api_operation`, `api_search_doc`, `context_path_reservation`, `api_owner_transfer`, `diff_result` |
| `ph02_20_lint_backend_plan.sql` | `02-0020-lint-backend-plan.sql` | `lint_rule`, `lint_rule_override` (+ trigger chính sách), `lint_finding` (phân vùng), `backend`, `plan` (+ `tg_plan_auth_policy`), `plan_operation_scope` |
| `ph02_30_lifecycle.sql` | `02-0030-lifecycle.sql` | `subscription`, `subscription_state_history`, `version_state_history`, `grant_job`, `review_request`, `version_contributor`, `review_decision` (+ hai trigger bốn mắt), `deprecation_reminder` |
| `ph02_40_publish_sla_sync.sql` | `02-0040-publish-sla-sync.sql` | `change_notice`, `change_notice_recipient`, `sla_commitment`, `sla_maintenance_window`, `sla_period`, `usage_daily` (phân vùng), `national_sync_record`, `national_sync_run`, `config_epoch`, `config_change_log` (phân vùng), `publish_job`, `gateway_drift` |
| `ph02_50_platform.sql` | `02-0050-platform.sql` | `async_operation`, `pending_command`, `inbox_event`, `outbox_event`, `idempotency_record`, `job_lease`, `import_session`, `legacy_id_map` |
| `ph02_60_seed_grants.sql` | `02-0800-seed.sql`, `02-0900-grants.sql` | 24 luật kiểm tra; quyền (chạy lại mỗi lần, `runAlways`) |
| `ph02_90_migrate_w1.sql` | `02-9000-migrate-w1.sql` (context `migrate-w1`) | Di trú bảng W1 `ph02.api_service`; **không** nằm trong `ph02_all.sql`, chạy riêng |

: Tệp DDL của PH-02

Lệnh chạy:

```bash
psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -f 03-thiet-ke/csdl/ph02/ddl/ph02_all.sql            # DDL, dữ liệu khởi tạo, quyền
psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -f 03-thiet-ke/csdl/ph02/test/ph02_isolation_test.sql # bài kiểm cô lập và ràng buộc
psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -v tenant=T01 -f 03-thiet-ke/csdl/ph02/ddl/ph02_90_migrate_w1.sql  # chỉ khi còn bảng W1
```

Lần chạy đầu cần người dùng có quyền tạo vai trò và extension; Liquibase ở môi trường thật dùng `dh_connect_migrator` sau khi bootstrap. Tệp seed và quyền chạy lại được, các changeset còn lại chạy một lần.

### 4.2. Kết quả chạy thử

Chạy ngày 26/11/2026 trên PostgreSQL 16.16 (bản Debian) cài sạch, dữ liệu giả:

- `ph02_all.sql` chạy không lỗi trên CSDL trống: 45 bảng ở schema `ph02_catalog`, trong đó 44 bảng bật `ENABLE` và `FORCE ROW LEVEL SECURITY` (chỉ `job_lease` không có), 232 ràng buộc `CHECK`, 41 trigger (gồm `tg_touch`), 167 chỉ mục (kể cả khóa chính và khóa duy nhất), 3 bảng phân vùng tháng với 4 phân vùng mỗi bảng được tạo sẵn. Chạy lại `ph02_60_seed_grants.sql` không lỗi và không nhân đôi 24 luật.
- [`ph02_isolation_test.sql`](ph02/test/ph02_isolation_test.sql) chạy dưới tài khoản `dh_connect_app` (thành viên `ph02_app`, `NOBYPASSRLS`) đạt **77 điểm kiểm** trong 27 nhóm, bảng dưới. Mỗi điểm kiểm xác nhận cả mã SQLSTATE lẫn tên ràng buộc hay đoạn thông báo, nên một ca "bị chặn" nhưng chặn sai lý do sẽ làm tệp dừng.
- `ph02_90_migrate_w1.sql` chạy trên CSDL có bảng W1 giả 3 dòng: tạo 3 API `DRAFT` mang `origin = LEGACY`, 3 phiên bản `1.0.0`, 6 dòng sổ mã, bảng cũ đổi tên `api_service_legacy_w1`; chạy lần hai báo "không có bảng W1, bỏ qua".

| Nhóm | Điểm kiểm | Nội dung |
|---|---|---|
| Cô lập tenant | 1 đến 6, 27 | T01 không đọc 12 bảng (kể cả 3 bảng phân vùng và `api_search_doc`) của T68; không chèn, sửa, xóa dòng T68; khóa ngoại kép chặn trỏ chéo; biến phiên rỗng không thấy dòng nào; không đọc thẳng phân vùng; `ph02_readonly` không đọc bảng nhạy cảm |
| Bộ luật kiểm tra | 7, 8 | Tỉnh đọc 24 luật, không sửa hay thêm luật `COMMON`; luật cấu trúc không hạ mức, luật `RAISE` chỉ nâng, `LOWER_LANG` đúng chiều |
| Phân loại và hiển thị | 9 | `PUBLIC` chỉ với dữ liệu `PUBLIC`; `NATIONAL` không với `SENSITIVE`; API từ luồng phải có tham chiếu luồng |
| Máy trạng thái phiên bản | 10, 11 | `DRAFT` không sang `PUBLISHED` thẳng; đặc tả và số hiệu bất biến; `DEPRECATED` cần hạn; hai bản đang chạy cùng số chính bị chặn nhưng thay thế trong một giao dịch được; `RETIRED` là trạng thái cuối |
| Đường dẫn, bất biến, sổ mã | 12, 13 | Context-path duy nhất, đúng quy ước và khớp số chính; đặc tả không sửa, không xóa, không quá 50 MiB; mã API không dùng lại và sổ mã không xóa được |
| Backend | 14 | Không URL tự do; `SYSTEM` phải trỏ kết nối PH-05; `PLACEHOLDER` chỉ cho `FLOW` |
| Gói | 15 | `INTERNAL` không `KEYLESS`; `RESTRICTED` cấm `client_secret`; `KEYLESS` cần mức hiển thị `PUBLIC`; gói nhập từ hệ cũ được đánh dấu thay vì chặn; đơn giá không âm |
| Đăng ký sử dụng | 16 | Một đăng ký hiệu lực mỗi HTTT mỗi phiên bản, đăng ký lại sau thu hồi; gói và phiên bản phải khớp; căn cứ pháp lý; người gửi không tự duyệt |
| Duyệt bốn mắt | 17 | Một yêu cầu `OPEN` mỗi đối tượng; người gửi, người sửa đặc tả, SV đều không duyệt công bố; không đủ chữ ký thì không `APPROVED`; API `SENSITIVE` cần CA và TA; quyết định chỉ thêm |
| Lịch sử, SLA, thông báo | 18, 19 | Lý do bắt buộc, lịch sử không sửa; SLA kém đi cần thông báo và báo trước 7 ngày; kết luận `met` khớp trạng thái; một kết quả hiện hành mỗi kỳ; cửa sổ bảo trì không chồng; thông báo bắt buộc |
| Đồng bộ quốc gia | 20 | Xếp hàng lặp vô hại; `ACKED` có mã quốc gia; `REJECTED` có lý do |
| Hộp gửi, cấu hình | 21, 22 | Topic đúng tenant; không nội dung đặc tả trong sự kiện; chỉ đánh dấu `published_at`; `source_version` chỉ tăng |
| Còn lại | 23 đến 26 | Nhóm không là cha chính nó; API hệ cũ cần mã cũ; tìm kiếm không dấu "ho so dat dai" khớp "Hồ sơ đất đai"; hạn lũy đẳng ≤ 48 giờ; phát hiện bí mật phải có dấu vân tay, xác nhận cần người và lý do |

: Nhóm điểm kiểm của bài kiểm cô lập và ràng buộc

Ba điều học được khi chạy thử, đã sửa trong DDL và đáng ghi để kỹ sư không vấp lại. Một: cột sinh tự động (`GENERATED … STORED`) **chưa có giá trị** trong trigger `BEFORE` của chính dòng đó; `tg_plan_auth_policy` vì vậy tính hạng xác thực từ `auth_type` thay vì đọc `NEW.auth_rank` (nếu đọc, phép so sánh ra `NULL` và gói yếu lọt qua). Hai: trong `pg_inherits` có cả chỉ mục của phân vùng, nên vòng thu quyền trên phân vùng phải lọc `relkind IN ('r','p')`. Ba: hàm `to_regconfig` không tồn tại, kiểm cấu hình tìm kiếm bằng danh mục `pg_ts_config`.

Bài kiểm thử `TenantIsolationIT` (D03-02-PH02 §12) tự động hóa các ca này trong CI bằng Testcontainers; tệp SQL là bản đặc tả chạy được và là khung cho D05-02-PH02.

### 4.3. Đối chiếu với bảng dự kiến ở SDD

SDD (D03-02-PH02 mục "Đề nghị đồng bộ") dự kiến 44 bảng. DDL giữ cả 44 tên và có 10 điểm lệch; ghi ở đây để đồng bộ SDD ở đợt sau.

| # | SDD dự kiến | DDL | Lý do |
|---|---|---|---|
| 1 | Không có bảng chuyển chủ quản | Thêm `api_owner_transfer` (45 bảng) | FR-02-045 và Q02-07 cần lưu số, ngày văn bản và đơn vị trước, sau; chỉ thêm |
| 2 | Bí danh `legacyPath` ở "bảng riêng" (SDD 4.5) | Gộp vào `context_path_reservation` với `kind = LEGACY_ALIAS` | Kiểm xung đột đường dẫn ở một chỗ, một khóa duy nhất |
| 3 | Giữ chỗ đường dẫn theo phiên bản | Khóa theo (API, số chính) | Phiên bản cùng số chính thay thế dùng lại đúng đường dẫn (BR-02-035) |
| 4 | `national_sync_record` duy nhất `(version_id, payload_hash)` | Duy nhất từng phần khi chưa kết thúc | Nếu nội dung quay lại giá trị cũ sau khi đã `ACKED` thì vẫn xếp hàng được |
| 5 | `lint_rule.adjustable` kiểu logic | `adjust_policy` ba mức (`NONE`, `RAISE`, `LOWER_LANG`); `adjustable` là cột sinh | FRS ghi chú FR-02-021: chỉ nâng, riêng LINT-02-02 được hạ phần ngôn ngữ |
| 6 | Cột chắn `plan.min_auth_rank` so với `api.data_class_rank` | `plan.auth_rank` và `api.data_class_rank` là cột sinh; trigger `tg_plan_auth_policy` so sánh khi ghi | Chốt chặn tức thời thay vì chỉ tác vụ đêm; tác vụ đêm vẫn cần khi API đổi mức phân loại (trigger chỉ chạy khi ghi gói) |
| 7 | `CHECK (decided_by <> requested_by)` | `review_decision` mang thêm `requested_by` qua khóa ngoại ba cột | `CHECK` chỉ so sánh được cột cùng bảng |
| 8 | `legacy_id_map` duy nhất toàn phần | Duy nhất từng phần cho kết quả `IMPORTED` | Mã cũ `FAILED`, `SKIPPED` nhập lại được |
| 9 | Cạnh `PUBLISHED → RETIRED` chưa có ở FRS 4.3 | Có trong `tg_api_version_guard` (lý do `SUPERSEDED`) | Đã nêu ở SDD 8.1 và đề nghị đồng bộ FRS |
| 10 | Định dạng đặc tả `OpenAPI 3.1` | `api_spec.format` thêm `OPENAPI30`, `SWAGGER2` | LGC-APIM-003 nạp Swagger; bản đã gộp chuẩn hóa về 3.1 ở `merged_sha256` |

: Điểm lệch giữa SDD và DDL

## 5. Dữ liệu khởi tạo

Bảng dưới liệt kê dữ liệu nạp sẵn khi cấp tenant hoặc khi cài đặt, kèm nguồn; dữ liệu này chạy lại được mà không nhân đôi.

| Dữ liệu | Tenant | Nội dung | Nguồn |
|---|---|---|---|
| Bộ luật kiểm tra | `COMMON` | 24 dòng `lint_rule`: 15 luật quy ước `LINT-02-01…15` (9 luật cấu trúc không chỉnh, `LINT-02-02` hạ được phần ngôn ngữ, 5 luật chỉ nâng) và 9 mẫu quét bí mật `SCAN-02-01…09` cố định mức `ERROR`; id tất định `md5('ph02:lint:' ‖ rule_id)` | FRS FR-02-017, 018, 021 |
| Cấu hình tìm kiếm | Schema | `ph02_catalog.vn_unaccent` (sao `simple`, thêm `unaccent` cho `word`, `hword`, `hword_part`), tạo ở bootstrap | SDD 4.2 |
| Bộ đếm cấu hình | Mỗi tenant | 3 dòng `config_epoch` (`TEST`, `STAGING`, `PROD`) với `source_version = 0`; tạo khi cấp phát tenant (đề nghị cho PH-20, mục "Đề nghị đồng bộ") | SDD 4.10 |
| Phân loại mặc định | Mỗi tenant | **Giả định**: 8 nhóm `dat-dai`, `dan-cu`, `doanh-nghiep`, `giao-duc`, `y-te`, `giao-thong`, `tai-chinh`, `dung-chung`; tenant sửa được (FR-02-008). Cơ sở: các lĩnh vực chia sẻ dữ liệu phổ biến ở hệ cũ; thay bằng bộ do tỉnh chốt khi khảo sát | FR-02-008 |
| Tham số `02.*` | PH-18 | 28 tham số theo FRS §8.2, bộ đệm 60 giây; không lưu ở CSDL của PH-02 | FR-02-062 |
| Bucket kho đối tượng | Mỗi tenant | `dh-{tenant}-catalog` với tiền tố `specs/`, `exports/`, `legacy/`; tạo khi cấp phát tenant | SDD 2.1 |

: Dữ liệu khởi tạo

Seed chạy dưới `app.tenant_id = 'PLATFORM'` và lũy đẳng (`ON CONFLICT DO UPDATE`), nên đổi nội dung luật là sửa tệp seed rồi chạy lại. Luật mới hoặc đổi mẫu quét bí mật đi qua bản phát hành có duyệt của Cán bộ ATTT (Q02-11), không sửa trực tiếp ở môi trường chạy.

## 6. Kho lưu trữ ngoài PostgreSQL

PH-02 dùng ba kho ngoài PostgreSQL: kho đối tượng cho đặc tả, Kafka cho sự kiện, và Valkey cho một bộ đếm. Phần nào của dữ liệu ở đâu được chọn theo hai tiêu chí: nội dung lớn hoặc cần giữ nguyên văn thì ra kho đối tượng, còn mọi thứ cần ràng buộc và truy vấn quan hệ ở lại PostgreSQL.

### 6.1. Kho đối tượng

Bucket `dh-{tenant}-catalog` trên Garage (ADR-008; không WORM, bằng chứng WORM của kiểm toán do PH-13 giữ ở Ceph RGW). Mỗi tenant một bucket, khóa truy cập theo tenant (SEC-82), mã hóa phía máy chủ; mọi khóa đối tượng dựng bằng `ObjectKeys.of(tenant, …)`, không ghép chuỗi tay.

| Tiền tố, khóa | Nội dung | Cột tham chiếu | Giữ |
|---|---|---|---|
| `specs/{apiCode}/{versionNo}/{sha256}` | Đặc tả OpenAPI nguyên văn đã nạp | `api_spec.object_key` | Vĩnh viễn (BR-02-014) |
| `specs/{apiCode}/{versionNo}/merged/{sha256}` | Đặc tả đã gộp tham chiếu, chuẩn hóa 3.1 | `api_spec.merged_sha256` | Vĩnh viễn |
| `exports/diff/{fromSha}-{toSha}` | Danh sách thay đổi đầy đủ khi vượt 5.000 thay đổi | `diff_result.detail_object_key` | Cùng dòng `diff_result` |
| `exports/` | Tệp xuất Excel, CSV của danh sách (FR-00) | Không | 7 ngày (giả định) |
| `legacy/plan/{sessionId}` | Kế hoạch ánh xạ nhập từ APIM cũ | `import_session.plan_object_key` | 24 giờ (`expires_at`) |
| `legacy/report/{sessionId}` | Báo cáo đối chiếu số lượng | `import_session.report_object_key` | Vĩnh viễn, cùng `import_session` |

: Kho đối tượng của PH-02

Đặc tả luôn đi qua CSDL trước, kho sau: dòng `api_spec` chỉ được ghi sau khi đối tượng đã lên kho và băm khớp, nên không có dòng trỏ vào đối tượng chưa tồn tại. Chiều ngược lại (đối tượng mồ côi do giao dịch CSDL hủy) được dọn bằng tác vụ `SpecObjectAudit` hằng ngày so khóa đối tượng với `api_spec`, chỉ xóa đối tượng không dòng nào trỏ tới và tuổi trên 24 giờ.

### 6.2. Kafka

Sự kiện ghi vào `outbox_event` cùng giao dịch rồi lên topic `{tenant}.catalog.{thực-thể}.{sự-kiện}.v1` (chữ thường). Khóa phân vùng là `apiCode` để sự kiện của một API đến theo thứ tự "công bố trước, ngừng dùng sau"; 3 phân vùng, giữ 7 ngày (giả định, đủ để bên tiêu thụ phục hồi sau sự cố cuối tuần). Sự kiện chỉ có mã định danh và trường thay đổi, không có nội dung đặc tả, bí mật hay dữ liệu cá nhân (`ck_outbox_event_no_secret`). Lược đồ ở Apicurio, chế độ BACKWARD (NFR-02-018).

| Mã | Topic | Phát khi (bảng nguồn) |
|---|---|---|
| EVT-02-01 | `{tenant}.catalog.api.registered.v1` | Đăng ký API (`api`) |
| EVT-02-02 | `{tenant}.catalog.api.updated.v1` | Đổi thông tin, phân loại, hiển thị, chủ quản, backend, SLA (`api`, `backend`) |
| EVT-02-03 | `{tenant}.catalog.api.deleted.v1` | Xóa mềm (`api.deleted_at`) |
| EVT-02-04 | `{tenant}.catalog.version.submitted.v1` | Gửi duyệt (`review_request`) |
| EVT-02-05 | `{tenant}.catalog.version.published.v1` | Sang `PUBLISHED` (`api_version`) |
| EVT-02-06 | `{tenant}.catalog.version.state-changed.v1` | Tạm ngừng, tiếp tục, ngừng khuyến nghị, ngừng hẳn (`version_state_history`) |
| EVT-02-07 | `{tenant}.catalog.version.spec-source-changed.v1` | Đặc tả nguồn URL đổi (`api_spec`) |
| EVT-02-08 | `{tenant}.catalog.plan.state-changed.v1` | Gói đổi trạng thái (`plan`) |
| EVT-02-09 | `{tenant}.catalog.subscription.requested.v1` | Đăng ký chờ duyệt (`subscription`) |
| EVT-02-10 | `{tenant}.catalog.subscription.activated.v1` | Đã cấp phạm vi (`grant_job`) |
| EVT-02-11 | `{tenant}.catalog.subscription.state-changed.v1` | Từ chối, tạm ngừng, thu hồi, hủy, hết hạn (`subscription_state_history`) |
| EVT-02-12 | `{tenant}.catalog.change.notice-issued.v1` | Thông báo đã phát (`change_notice`) |
| EVT-02-13 | `{tenant}.catalog.sla.period-closed.v1` | Chốt kỳ SLA (`sla_period`) |
| EVT-02-14 | `{tenant}.catalog.national-sync.state-changed.v1` | Trạng thái đồng bộ quốc gia đổi (`national_sync_record`) |
| EVT-02-15 | `{tenant}.catalog.gateway.drift-detected.v1` | Lệch cấu hình (`gateway_drift`) |
| EVT-02-16 | `{tenant}.catalog.review.overdue.v1` | Yêu cầu duyệt quá hạn (`review_request`) |

: Sự kiện ghi qua hộp gửi

PH-02 còn tiêu thụ sự kiện của PH-01, PH-04, PH-10 qua `inbox_event` (EVT-04-02, 04, 07; EVT-10-01, 03, 04; sự kiện tạm ngừng, thu hồi HTTT và cấp định danh máy). Khi Kafka ngừng, sự kiện tồn ở `outbox_event` và được phát bù; cảnh báo khi dòng chưa phát cũ nhất quá 5 phút.

### 6.3. Valkey và OpenSearch

Valkey chỉ giữ một khóa: bộ đếm số lần kiểm tra đặc tả của mỗi người mỗi giờ (`02.lint.max-per-hour`), dựng bằng hàm tạo tên có tenant (`dh:{tenant}:catalog:lint:{userId}`, hết hạn sau 1 giờ). Mất Valkey thì dùng bộ đếm cục bộ của từng pod, chấp nhận sai số vì đây chỉ là rào chống lạm dụng; không có dữ liệu nào chỉ tồn tại ở Valkey. Lũy đẳng của lệnh POST dùng PostgreSQL (`idempotency_record`) chứ không dùng Valkey, vì tần suất lệnh thấp (SDD 8.5).

OpenSearch là tùy chọn (`02.search.engine = OPENSEARCH`, Q02-02): alias `catalog-{tenant}`, lập chỉ mục bất đồng bộ từ `outbox_event`, độ trễ vài giây. Khi bật, `api_search_doc` vẫn được giữ cập nhật làm đường lùi khi OpenSearch ngừng (Q02-54). PH-02 không giữ bí mật ở OpenBao: khóa API và chứng thư do PH-01 cấp, PH-03 giữ băm.

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

Sao lưu dùng chung cơ chế của `pg-core` (ADR-035): CloudNativePG với plugin Barman Cloud, bản cơ sở hằng ngày cộng WAL liên tục ra kho S3 có khóa đối tượng chế độ tuân thủ (Ceph RGW) ngoài site, mã hóa phía máy khách bằng khóa OpenBao; PITR trong 30 ngày, giữ 35 ngày bản ngày và WAL, 12 tháng bản tháng. Mục tiêu của PH-02 là RPO ≤ 15 phút và RTO ≤ 4 giờ (NFR-02-009, NFR-00-014). Khôi phục một tenant riêng lẻ dùng bản xuất logic theo tenant hằng ngày (RBK-04). Bảng dưới là chính sách lưu giữ theo bảng, nguồn NFR-02-017.

| Đối tượng | Lưu giữ | Cơ chế dọn |
|---|---|---|
| `api`, `api_version`, `api_spec`, `api_operation`, `backend`, `plan`, `category`, `code_registry`, `context_path_reservation` (dòng chưa hết giữ chỗ), `api_owner_transfer` | Vĩnh viễn | Không có tác vụ xóa; API xóa mềm bằng `deleted_at` |
| `subscription`, `subscription_state_history`, `version_state_history`, `review_request`, `review_decision`, `version_contributor`, `deprecation_reminder`, `sla_commitment` | Vĩnh viễn | Không có tác vụ xóa (bằng chứng ai đã dùng API nào, ai đã duyệt) |
| `grant_job`, `publish_job` | 90 ngày sau khi kết thúc (giả định) | Tác vụ dọn hằng ngày dưới `ph02_owner` |
| `sla_period`, `sla_maintenance_window` | 3 năm | `SlaRetentionJob` 03:10 theo kỳ |
| `national_sync_record`, `national_sync_run` | 5 năm | Tác vụ dọn hằng ngày |
| `change_notice`, `change_notice_recipient` | 2 năm | Tác vụ dọn hằng ngày |
| `lint_finding` | 1 năm | `DETACH` rồi `DROP` phân vùng tháng quá hạn |
| `usage_daily` | 2 năm (giả định, Q02-50) | `DETACH` rồi `DROP` phân vùng tháng |
| `config_change_log` | 30 ngày | Xóa dòng cũ hơn 30 ngày hằng ngày; `DROP` phân vùng khi cả tháng đã quá hạn |
| `diff_result` | Vĩnh viễn với `classifier_version` hiện hành; bản cũ hơn 1 năm xóa được | Tác vụ dọn hằng ngày |
| `gateway_drift` | 1 năm | Tác vụ dọn hằng ngày (giả định) |
| `outbox_event` | 3 ngày sau khi phát | Tác vụ dọn 15 phút một lần |
| `inbox_event` | 7 ngày (giả định) | Tác vụ dọn hằng ngày |
| `idempotency_record` | Tối đa 48 giờ (`expires_at`) | Tác vụ dọn giờ |
| `async_operation`, `pending_command` | 30 ngày; `pending_command` trạng thái `DONE` 7 ngày, `DEAD` 90 ngày (giả định) | Tác vụ dọn hằng ngày |
| `import_session`, `legacy_id_map` | `import_session` chưa ghi hết hạn sau 24 giờ rồi `EXPIRED`; kết quả giữ vĩnh viễn | `ImportSessionJanitor`; `legacy_id_map` không xóa |
| Bucket `dh-{tenant}-catalog` | Đặc tả vĩnh viễn; xem 6.1 | Sao chép theo chính sách kho đối tượng (ADR-008) |
| Kiểm toán thao tác | 12 tháng trực tuyến, WORM 5 năm ở PH-13 | `dh-audit` ghi cùng giao dịch qua hộp gửi (SEC-60) |

: Sao lưu, khôi phục, mã hóa và lưu giữ

**Mã hóa.** Dữ liệu mã hóa khi lưu ở tầng lưu trữ của cụm (D03-09) và khi truyền bằng TLS (mTLS trong mesh). PH-02 không có cột mã hóa theo trường vì không lưu dữ liệu cá nhân: `requested_by`, `decided_by` là mã định danh người dùng chứ không phải họ tên, đầu mối liên hệ ở PH-01, và `change_notice_recipient` chỉ giữ tham chiếu người nhận, không giữ địa chỉ thư.

**Khôi phục lệch giữa các kho.** Có ba tình huống cần biết. (1) CSDL khôi phục về thời điểm cũ hơn kho đối tượng: không có vấn đề vì kho chỉ thêm, `api_spec` chỉ trỏ tới đối tượng đã tồn tại, đối tượng thừa được `SpecObjectAudit` dọn. (2) Kho đối tượng khôi phục cũ hơn CSDL: `api_spec.object_key` có thể trỏ tới đối tượng thiếu; `SpecObjectAudit` so khóa và băm hằng ngày, phát cảnh báo; đặc tả của phiên bản `DRAFT` nạp lại, đặc tả của phiên bản đã `PUBLISHED` khôi phục từ bản sao lưu bất biến của kho. (3) CSDL khôi phục cũ hơn gateway: `config_epoch.source_version` có thể thấp hơn số APISIX đã nạp; PH-03 thấy số nhỏ hơn thì lấy lại toàn bộ cấu hình (`gap = true`), `DriftReconciler` đối soát trong 10 phút (NFR-02-020), và sự kiện phát lại là lũy đẳng theo `(apiCode, versionNo, sourceVersion)`. Mọi trường hợp đều chạy diễn tập DR theo D03-09 §8.2 và sổ tay RBK.

## 8. Ánh xạ dữ liệu hệ cũ sang thiết kế mới

PH-02 phủ 15 mục `LGC` của hệ cũ (14 mục APIM, 1 mục Bus; FRS 11.1). Dữ liệu cũ có hai nguồn: bảng của mã W1 hiện tại (chắc chắn, đã đọc được mã) và CSDL của APIM cũ (chưa có lược đồ chi tiết trong tài liệu được cung cấp). Nguyên tắc chung của di trú: **không nhập khóa hay bí mật** (BR-02-036); mọi API nhập vào đều là bản nháp `DRAFT` phải qua kiểm tra đặc tả và duyệt bốn mắt; đăng ký nhập vào ở `SUSPENDED` cho tới khi HTTT mới có định danh máy ở PH-01.

### 8.1. APIM cũ

Lược đồ CSDL của APIM cũ chưa có trong tài liệu được cung cấp. Bảng dưới dựa trên mô hình khái niệm mà D00-03 phần A mô tả (API, Plan bốn trạng thái, Subscription, Application, endpoint backend) và là **giả định** cần đối chiếu với bản xuất của tỉnh (Q02-53). Việc nhập là trích xuất có xem trước từ gói xuất của hệ cũ (FR-02-061, API-02-085…087), không phải chép bảng.

| Khái niệm hệ cũ | Đích | Cách chuyển |
|---|---|---|
| API: tên, mô tả | `api.name`, `api.description` | Chép; `origin = LEGACY`, `legacy_id` = mã cũ, trạng thái `DRAFT`; mã API đề xuất theo quy ước `^[a-z][a-z0-9-]{2,62}$` |
| API: số phiên bản | `api_version.version_no` | Chuẩn hóa thành `MAJOR.MINOR.PATCH` (ví dụ `v1` thành `1.0.0`, `1.2` thành `1.2.0`) |
| API: context-path cũ | `context_path_reservation` (`LEGACY_ALIAS`) và đường dẫn chuẩn mới (`PRIMARY`) | Giữ bí danh cho giai đoạn chạy song song, mang `Deprecation` từ đầu (SDD 4.5); đường dẫn mới theo quy ước |
| API: công khai hay riêng | `api.visibility` | `PUBLIC` cũ thành `TENANT`, không tự nâng; nâng cần CA duyệt (BR-02-037) |
| API: trạng thái chạy, vòng đời | `api_version.status` | Không giữ; luôn `DRAFT` (BR-02-001); trạng thái cũ ghi vào ghi chú phát hành |
| API: mức phân loại dữ liệu | `api.data_class` | Hệ cũ không có; đặt `INTERNAL` làm mức khởi đầu, SV xác nhận trước khi gửi duyệt |
| Tài liệu Swagger đính kèm | `api_spec` + kho đối tượng | Qua `SpecIngestService` (kiểm tra, quét bí mật); không có thì tạo đặc tả khung "Cần bổ sung" không gửi duyệt được |
| Endpoint backend, nhóm endpoint | `backend` (`SYSTEM`, `DISABLED`) | Địa chỉ cũ giữ làm gợi ý văn bản, đã che thông tin xác thực; kỹ sư tạo kết nối ở PH-05 rồi chọn lại (BR-02-023) |
| Plan: tên, nhóm được phép | `plan.name`, `plan.audience` | Chép (LGC-APIM-010) |
| Plan: bốn trạng thái | `plan.status` | Ánh xạ thẳng `STAGING`, `PUBLISHED`, `DEPRECATED`, `CLOSED` (LGC-APIM-009) |
| Plan: Keyless, API key | `plan.auth_type` | `KEYLESS`, `API_KEY`; gói vi phạm ma trận mức phân loại được đánh dấu `needs_auth_upgrade` thay vì chặn nhập |
| Subscription | `subscription` (`SUSPENDED`, `reason_code = MIGRATED_AWAITING_CREDENTIAL`) | Theo `applicationMap`; mục đích và khối lượng ghi "chưa khai (nhập từ hệ cũ)" để SV bổ sung khi xác nhận; đăng ký `CLOSED`, `REJECTED` cũ ghi `legacy_id_map` kết quả `SKIPPED` |
| Application | HTTT ở PH-01 | Không có bảng; ánh xạ do người dùng khai trong `import_session.application_map`; HTTT không `ACTIVE` bị từ chối (ERR-02-004) |
| Khóa API, bí mật | Không chuyển | Không bao giờ đọc vào mô hình (BR-02-036) |
| Nhóm, thành viên, thông báo | Không chuyển | Quản trị người dùng ở PH-12; thông báo ở PH-18 |

: Ánh xạ khái niệm APIM cũ

### 8.2. Bảng của mã hiện tại (`apps/control`, W1)

Mã W1 có module `catalog` với bảng `ph02.api_service` (changelog `002-w1-onboarding-catalog.yaml`, 10 cột). Changeset `ph02-9000-migrate-w1` ([`ph02_90_migrate_w1.sql`](ph02/ddl/ph02_90_migrate_w1.sql)) chuyển phần nhận diện; đặc tả cần bước ứng dụng vì nằm ở cột `TEXT`.

| Cột hiện tại | Đích | Ghi chú |
|---|---|---|
| `id` | `api.id = md5('w1:api:' ‖ id)`, `api_version.id = md5('w1:ver:' ‖ id)` | Tất định, chạy lại không nhân đôi; `api.legacy_id = 'w1:ph02.api_service/' ‖ id` |
| `service_code` | `api.api_code` | Chữ thường, ký tự lạ thành `-`, tối đa 63; mã không khớp mẫu thành `w1-{12 ký tự đầu của md5}`; SV đổi mã trước khi gửi duyệt nếu cần (mã bất biến sau `PUBLISHED`) |
| `title` | `api.name` | Cắt 255 ký tự |
| `openapi_yaml` | Không chuyển bằng SQL | `W1SpecMigrator` đọc `ph02.api_service_legacy_w1`, ghi đặc tả lên kho đối tượng, tạo `api_spec`, chạy kiểm tra; chưa đạt lớp 1, lớp 2 thì để ở `DRAFT` |
| `status` | Luôn `api_version.status = 'DRAFT'` | `PUBLISHED` cũ không tương đương vì W1 công bố không duyệt, không kiểm tra; trạng thái cũ ghi vào `api.description` |
| `public_path`, `route_file` | `api_version.release_notes` | Ghi để đối chiếu, không dùng làm context-path; đường dẫn mới `/w1/{mã}` đặt ở `api.base_path`, kỹ sư đổi sang nhóm thật |
| `upstream_url` | Không chuyển | Backend phải trỏ kết nối PH-05 (BR-02-023); URL cũ có thể là địa chỉ nội bộ |
| `created_at`, `updated_at` | Không chuyển | Dòng mới mang thời điểm di trú |
| (không có) | `system_code = 'CHUA-GAN'`, `owner_org_code = 'CHUA-GAN'`, `data_class = 'INTERNAL'`, `visibility = 'TENANT'` | Giá trị tạm, SV gán HTTT và phân loại thật trước khi gửi duyệt |

: Bảng của mã hiện tại (apps/control, W1)

Changeset ghi thêm `code_registry` cho mã API và số hiệu `{mã}@1.0.0` (để mã không bị dùng lại), đặt `app.tenant_id` theo tham số `tenant` (mặc định `T01`), rồi đổi tên bảng cũ thành `api_service_legacy_w1`; rollback đổi tên lại. Môi trường thật không có dữ liệu W1 (W1 chỉ là bản thử nghiệm), nên changeset chủ yếu phục vụ môi trường phát triển và thử (Q02-52).

### 8.3. Đối soát sau di trú

`ImportReportBuilder` của PH-02 đếm API, gói, đăng ký ở nguồn và đã nhập, liệt kê phần chưa nhập kèm lý do và tính `import_session.checksum` là SHA-256 danh sách `(legacyId, kết quả)` đã sắp xếp, để hai lần nhập cùng dữ liệu cho cùng tổng kiểm tra (FR-00-092). Đối soát lấy từ chính CSDL:

```sql
-- Số lượng theo loại và kết quả của một phiên nhập
SELECT entity_kind, result, count(*) FROM ph02_catalog.legacy_id_map WHERE session_id = :sessionId GROUP BY 1, 2;
-- API nhập còn thiếu để gửi duyệt: chưa gán HTTT, chưa có đặc tả, backend chưa có kết nối
SELECT a.api_code, a.system_code, v.current_spec_id IS NULL AS thieu_dac_ta
  FROM ph02_catalog.api a JOIN ph02_catalog.api_version v ON v.api_id = a.id AND v.tenant_id = a.tenant_id
 WHERE a.origin = 'LEGACY' AND (a.system_code = 'CHUA-GAN' OR v.current_spec_id IS NULL);
-- Đăng ký đang chờ định danh máy
SELECT count(*) FROM ph02_catalog.subscription WHERE reason_code = 'MIGRATED_AWAITING_CREDENTIAL' AND status = 'SUSPENDED';
```

Tiêu chí chấp nhận 10 của FRS (nhập thử một gói xuất APIM cũ: số lượng khớp, không khóa nào được nhập, đăng ký ở `SUSPENDED` chờ định danh) lấy ba truy vấn này làm bằng chứng. Báo cáo là đầu vào nghiệm thu bước di trú của SDD 13.1 và của D06-01.

## 9. Câu hỏi mở

> **Câu hỏi mở Q02-50:** Thời gian giữ `usage_daily` (2 năm là giả định) và việc có chuyển thống kê sử dụng dài hạn sang ClickHouse của PH-13 khi vượt 12 triệu dòng mỗi năm ở hồ sơ trần. Đề xuất tạm: giữ 2 năm ở `pg-core` theo phân vùng tháng; chốt cùng PH-16 khi có yêu cầu báo cáo chỉ tiêu nhiều năm.

> **Câu hỏi mở Q02-51:** Muối của dấu vân tay bí mật (`lint_finding.fingerprint`, HMAC-SHA256 cắt 16 ký tự hex) lấy từ OpenBao theo tenant và xoay vòng thế nào. Mất muối thì mất khả năng nhận ra cùng một bí mật ở lần quét sau nhưng không lộ giá trị. Đề xuất tạm: một muối mỗi tenant ở `kv/dh/{tenant}/catalog/lint-salt`, không xoay vòng; cần Cán bộ ATTT xác nhận.

> **Câu hỏi mở Q02-52:** Dữ liệu W1 `ph02.api_service` chuyển vào tenant nào và môi trường thật có dữ liệu W1 không. Đề xuất tạm: tenant `T01` (tham số `tenant`), chỉ ở môi trường phát triển và thử, môi trường thật bắt đầu từ lược đồ mới; xác nhận với đội W1.

> **Câu hỏi mở Q02-53:** Lược đồ CSDL của APIM cũ (tên bảng, cột, trạng thái) chưa có trong tài liệu được cung cấp; bảng ánh xạ 8.1 dựa trên mô hình khái niệm. Đề xuất tạm: giả định mô hình tương tự Gravitee như D00-03 mô tả; đối chiếu khi có bản xuất của một tỉnh và điều chỉnh `ApimExportParser` (FR-02-061), không đổi lược đồ đích.

> **Câu hỏi mở Q02-54:** Khi `02.search.engine = OPENSEARCH`, có tiếp tục cập nhật `api_search_doc` trong cùng giao dịch làm đường lùi không, hay bỏ để giảm ghi. Đề xuất tạm: vẫn cập nhật, vì chi phí nhỏ (một dòng mỗi API, 2.000 dòng ở trần) và cho phép tắt OpenSearch không mất tìm kiếm; chốt cùng Q02-02 sau khi đo với 10.000 phiên bản (NFR-02-002).

> **Câu hỏi mở Q02-61:** DDL đã chạy thử lệch bốn chỗ so với FRS, API-02-092…098 và API-02-095, phát hiện khi rà soát chéo: (1) `review_request.kind` chỉ có bảy giá trị ngắn (`PUBLISH`…`SUBSCRIBE`, tối đa 14 ký tự) trong khi FRS FR-02-035 và OpenAPI `ReviewKind` có mười (`VERSION_PUBLISH`, `VERSION_DEPRECATE`, `VERSION_RETIRE`, `PLAN_PUBLISH`, `PLAN_DEPRECATE`, `PLAN_CLOSE`, `BACKEND_CHANGE`, `VISIBILITY_RAISE`, `SUBSCRIPTION`, `SUBSCRIPTION_RENEW`, tối đa 18 ký tự); (2) `review_request.status = 'OPEN'` trong khi FRS và API dùng `PENDING`; (3) `lint_finding` chưa có cột cho API-02-093, 094 (`dispute_requested`, `dispute_reason`, `dispute_requested_by`); (4) `async_operation.kind` chưa có loại cho đồng bộ quốc gia (API-02-069) và đối soát gateway (API-02-084). Đề xuất tạm: giữ DDL hiện tại làm nguồn, ánh xạ giá trị ở `ReviewMapper` của dịch vụ; ở lần sửa DDL kế tiếp đổi `kind` thành `varchar(20)` với đủ mười giá trị theo tên API, đổi `OPEN` thành `PENDING`, thêm ba cột cho `lint_finding`, thêm `NATIONAL_SYNC_RUN` và `GATEWAY_RECONCILE` vào `ck_async_operation_kind`, rồi chạy lại 77 điểm kiểm cô lập. Chưa sửa DDL trong lượt rà soát vì môi trường rà soát không có PostgreSQL kèm `pg_trgm`, `unaccent`, `btree_gist` để chạy lại.

## Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới đây nằm ngoài quyền sửa của tập này (tài liệu dùng chung hoặc tập khác); chuyển cho luồng hoặc đợt đồng bộ phụ trách.

| Tài liệu | Đề nghị |
|---|---|
| D03-02-PH02 (SDD) mục "Đề nghị đồng bộ", 4.1, 4.5, 4.9, 4.11 | Cập nhật theo 10 điểm lệch ở §4.3: thêm bảng `api_owner_transfer`; gộp bí danh đường dẫn vào `context_path_reservation`; khóa giữ chỗ đường dẫn theo (API, số chính); khóa duy nhất từng phần của `national_sync_record` và `legacy_id_map`; `lint_rule.adjust_policy`; `review_decision.requested_by`; cột sinh `plan.auth_rank`, `api.data_class_rank` thay `min_auth_rank`; ghi thêm các tác vụ dọn dữ liệu của chương 7 và `SpecObjectAudit` vào danh sách tác vụ nền của `worker` (SDD 8.3) |
| D00-01 §5 | Ghi ngoại lệ cho `T-CODE`: mã API, mã gói, mã nhóm của PH-02 là chữ thường khớp `^[a-z][a-z0-9-]{n,m}$` vì là thành phần của đường dẫn công bố; hoặc thêm kiểu chuẩn `T-SLUG` |
| D03-10 §3 | Thêm `ph02_catalog` vào danh sách schema mà DU kiểm khi khởi động (mọi bảng có chính sách RLS, vai trò không `BYPASSRLS`); nêu rõ bảng phân vùng chỉ cấp quyền ở bảng cha và `lint_rule` là bảng mẫu S duy nhất của PH-02 |
| D03-09 §5.3, §8 | Ghi định cỡ `ph02_catalog` (dưới 1 GiB ở tỉnh vừa, khoảng 10 GiB ở trần) vào dòng `pg-core`; ghi chính sách lưu giữ phân vùng của `lint_finding`, `usage_daily`, `config_change_log` vào lịch tác vụ dọn |
| PH-20 FRS (khi viết) | Bước cấp phát tenant tạo ba dòng `config_epoch`, bộ phân loại mặc định và bucket `dh-{tenant}-catalog`; đề xuất giao diện khởi tạo của `catalog` cho PH-20 gọi |
| D02-07 (từ điển dữ liệu) | Đăng ký các bảng hạ tầng chung của PH-02 theo DD đã có: `outbox_event` (DD-11), `idempotency_record`; ghi danh sách 13 thực thể EN-02-01…13 ánh xạ 45 bảng |
| D05-02-PH02 | Lấy 77 điểm kiểm của `ph02_isolation_test.sql` làm khung `TenantIsolationIT` và ca rò rỉ chéo tenant (NFR-02-013); thêm ca đua "`RETIRED` khi vừa có đăng ký mới" (BR-02-006) vì CSDL không chốt được |
| Bộ công cụ csdl | Hợp nhất `gen_tables_md.py`, `them_dac_ta_bang.py` của PH-05, PH-19, PH-02 thành một công cụ tham số hóa theo schema; hiện mỗi phân hệ giữ một bản |
| Đề xuất ADR | Chưa tạo ADR trong tập này. Nếu hội đồng muốn ghi thành quyết định: "Bằng chứng hợp đồng chỉ thêm (đặc tả, lịch sử, sổ mã, cam kết SLA) và quy tắc bốn mắt, vòng đời, kiểu xác thực khóa ở CSDL bằng ràng buộc loại trừ hoãn và trigger, như lớp phòng thủ thứ hai sau dịch vụ" |

: Đề nghị đồng bộ

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-CSDL và quy chuẩn K-TRINH-BAY: 45 bảng (44 bảng của SDD cộng `api_owner_transfer`), 3 sơ đồ ER, bảng đặc tả 10 mục sinh từ DDL, DDL 8 tệp đã chạy thử trên PostgreSQL 16.16, bài kiểm cô lập tenant và ràng buộc 77/77 điểm, changeset di trú W1 đã chạy thử, chính sách lưu giữ và sao lưu, ánh xạ hệ cũ, 5 câu hỏi mở (Q02-50…54) |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà soát chéo: Giới thiệu theo khuôn; ghi chú cột `kind`, `status` của `review_request` kèm ánh xạ sang API; thêm Q02-61 về bốn chỗ DDL lệch FRS và API; bỏ đề nghị đồng bộ đã thực hiện |
