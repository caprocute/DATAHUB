---
ma_tai_lieu: D03-03-PH18
ten: Thiết kế cơ sở dữ liệu phân hệ PH-18 Vận hành và xử lý lỗi
phien_ban: 0.3
ngay: 2026-11-27
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, DBA, ATTT, hội đồng thẩm định
phan_he: PH-18
mo_ta: Thiết kế 57 bảng của schema ph18_ops trên cụm pg-core gồm kho tham số theo tenant có phiên bản và bốn mắt, DLQ hợp nhất với phát lại lũy đẳng, thông báo, Việc của tôi và lịch làm việc, sự cố vận hành, sao lưu và khôi phục tenant, sáp nhập tenant, di trú hệ cũ và chạy song song, báo cáo vận hành, kèm DDL chạy thử, kiểm cô lập tenant mọi bảng và changelog Liquibase.
tai_lieu_lien_quan: D02-03-PH18 FRS; D03-02-PH18 SDD; D03-04-PH18 API; D02-07 Từ điển dữ liệu; D03-09 Hạ tầng và DR; D03-10 Thiết kế đa tenant
---

# D03-03-PH18 · Thiết kế CSDL Vận hành và xử lý lỗi

## Tóm tắt cho hội đồng thẩm định

Schema `ph18_ops` trên cụm `pg-core` có 57 bảng: 55 bảng hiện thực 55 thực thể EN-18-01…55 (EN-18-01…54 theo brief chung PH-18 §5, EN-18-55 `merge_transfer` theo hợp đồng với PH-20) và hai bảng kỹ thuật `outbox_event`, `inbox_event`. Bốn bảng lớn (`dlq_message`, `dlq_audit`, `notification_delivery`, `shadow_comparison_sample`) phân vùng theo tháng, 16 phân vùng tạo sẵn. Mọi bảng có bảy cột ngữ cảnh (`id`, `tenant_id`, `created_*`, `updated_*`, `version`) và bật `FORCE ROW LEVEL SECURITY` theo `current_setting('app.tenant_id')`. DDL chạy sạch trên PostgreSQL 16.15; bài kiểm cô lập tenant đạt 520 khối PASS, phủ cả 57 bảng; công cụ CI `chay_ddl.py` chạy sạch cả bước riêng của PH-18 lẫn bước chung với 18 phân hệ khác trên một CSDL.

Năm quyết định thiết kế hội đồng cần lưu ý.

1. **Kho tham số là nguồn chuẩn DD-14, giữ tương thích tên.** Lược đồ khóa (`param_definition`) chỉ có ở dòng `COMMON`, giá trị theo tenant ở `param_value`, lịch sử ở `param_value_version`. Tên `ph18_ops.config_param` mà D02-07 và FRS PH-07 đã dùng được giữ bằng một khung nhìn `security_invoker` trả đúng năm thuộc tính DD-14 (`key`, `value`, `schema`, `scope`, `effective_from`), nên PH khác không phải đổi tài liệu. Trigger kiểm kiểu, miền, danh sách cho phép, trần nền tảng và mức `PLATFORM` ngay ở CSDL, lớp chặn thứ hai sau dịch vụ.
2. **DLQ hợp nhất, payload gốc không sửa.** Payload đến 256 KB giữ ở `payload_inline` (trường nhạy cảm đã mã hóa ở PH-04), lớn hơn ở Garage bucket `dh-{tenant}-ops`, mục liên thông từ PH-10 không chép nội dung. Trigger chặn sửa payload gốc; sửa tạo `dlq_revision`, có dữ liệu mức Hạn chế thì bốn mắt. Phát lại dùng khóa lũy đẳng `dlqId:revision` kiểm bằng CHECK.
3. **Bốn mắt và máy trạng thái chốt ở CSDL.** 20 trigger máy trạng thái theo đúng brief §4 (DLQ, lượt phát lại, phiên bản tham số, mẫu thông báo, lần gửi, việc, sự cố, khôi phục tenant, lần di trú, cắt chuyển); CHECK người duyệt khác người đề nghị ở mười bảng.
4. **Sáu bảng chỉ thêm, bốn vai tách bạch.** Nhật ký thao tác DLQ, mốc sự cố, sổ cắt chuyển, mẫu so sánh, báo cáo đối chiếu, kết quả kiểm tra khôi phục chặn UPDATE và DELETE kể cả với chủ đối tượng. Vai `ph18_worker` của Job K8s chỉ chạm bảng di trú, khôi phục, xuất, sáp nhập; vai `ph18_readonly` không đọc payload DLQ, biến mẫu thông báo, ảnh chụp bản ghi lỗi di trú. Phân vùng không cấp quyền trực tiếp cho vai nào.
5. **Không lưu bí mật, không cần extension.** Nguồn hệ cũ chỉ lưu tham chiếu OpenBao `kv/dh/{tenant}/...` và URL JDBC không kèm thông tin đăng nhập (CHECK); thông báo chỉ lưu địa chỉ dạng che và băm. Schema không cài extension nào (`gen_random_uuid`, `sha256` có sẵn ở PostgreSQL 16).

Bản 0.2 đã đồng bộ với FRS PH-18 0.2: tên khóa `18.*`, enum và tên cột theo FRS và OpenAPI, mã phân hệ dạng `PH-nn`, bộ đếm lần gặp của mục DLQ, kho lần chạy Spring Batch ở schema `ph18_batch` (mục 4.4, 10.1). Rủi ro chính: cách khử trùng `dlqKey` qua `inbox_event` có cửa sổ 7 ngày (`18.dlq.dedup-window-days`) cộng với tra mục chưa đóng cùng khóa, thay cho ràng buộc duy nhất trên bảng phân vùng (Q18-50); dọn phân vùng `dlq_message` phụ thuộc mục mở lâu (Q18-51).

## 0. Giới thiệu

Chương này nêu mục đích, phạm vi, thuật ngữ và tài liệu căn cứ của tập thiết kế CSDL PH-18, để người đọc biết tập này trả lời câu hỏi gì và đọc phần nào trước.

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả mô hình dữ liệu vật lý của PH-18 "Vận hành và xử lý lỗi" (DU `dh-platform`, package `vn.datahub.platform.ops`), gồm schema, vai trò, cách ly tenant, sơ đồ thực thể quan hệ, đặc tả từng bảng, DDL và changelog Liquibase, dữ liệu khởi tạo, lưu giữ và ánh xạ từ mô hình cũ. Phạm vi gồm mười khối chức năng A đến J của brief chung PH-18 §3: kho tham số và cờ tính năng, tiếp nhận DLQ, phân loại và xử lý, phát lại và lưu giữ, thông báo, Việc của tôi và lịch, sự cố vận hành, sao lưu và khôi phục (gồm sáp nhập tenant), di trú hệ cũ và chạy song song, quản trị và báo cáo.

Ngoài phạm vi: DLQ tầng sự kiện (PH-10 giữ ở `ph10_event`, PH-18 chỉ liên thông siêu dữ liệu), luật cảnh báo và kiểm toán WORM (PH-13), tham số `19.*` (PH-19), quyền và vai trò (PH-12), đồng hồ 72 giờ DLCN (PH-09), lịch job nội bộ của PH-08 và PH-16.

### 0.2. Thuật ngữ và chữ viết tắt

Bảng dưới giải thích các thuật ngữ dùng nhiều trong tài liệu.

| Thuật ngữ | Giải thích |
|---|---|
| DLQ (Dead Letter Queue) | Hàng đợi bản tin lỗi: bản tin không xử lý được sau số lần thử, được giữ lại để xem, sửa, phát lại hoặc bỏ qua |
| Phát lại (replay) | Gửi lại bản tin qua lối vào của nguồn (PH-04 runtime, PH-10, cổng `ReplayPort` của PH khác) |
| Lũy đẳng (idempotent) | Thực hiện nhiều lần cho cùng kết quả như một lần; khóa lũy đẳng phát lại là `dlqId:revision` |
| Bốn mắt | Thao tác cần người thứ hai khác người đề nghị duyệt (FR-00-071) |
| RLS (Row Level Security) | Bảo mật mức dòng của PostgreSQL; `FORCE` áp cả cho chủ bảng |
| `COMMON` | Tenant toàn quốc chứa dữ liệu mức nền tảng: lược đồ khóa, mẫu mặc định, lịch quốc gia, đối tượng sao lưu cụm |
| Outbox, inbox | Bảng ghi sự kiện cùng giao dịch để Debezium phát (outbox) và bảng khử trùng sự kiện nhận (inbox) |
| Garage | Kho đối tượng tương thích S3 của nền tảng; bucket PH-18 là `dh-{tenant}-ops` |
| Chạy bóng (shadow) | APISIX nhân bản lưu lượng thật sang Datahub để so phản hồi với hệ cũ, không trả kết quả cho người dùng |
| Cắt chuyển (cutover) | Chuyển lưu lượng thật của một nhóm dịch vụ từ hệ cũ sang Datahub, có cửa sổ quay lui |
| PITR | Khôi phục về một thời điểm (Point In Time Recovery) |
| PA, PO, TA, TO, SO, IE, AU | Quản trị nền tảng, vận hành nền tảng, quản trị tỉnh, vận hành tỉnh, cán bộ ATTT, kỹ sư tích hợp, kiểm toán |

: Thuật ngữ và chữ viết tắt dùng trong D03-03-PH18

### 0.3. Tài liệu tham chiếu

Các tài liệu sau là căn cứ thiết kế; khi lệch, tài liệu này ghi đề nghị đồng bộ ở mục 10.

| Tài liệu | Nội dung dùng |
|---|---|
| Brief chung PH-18 (27/11/2026) | Mã, trạng thái chuẩn §4, thực thể EN-18-01…54 §5, hợp đồng PH-20 §7 |
| Hợp đồng kỳ vọng ở PH-18 (tổng hợp 906 dòng nhắc PH-18) | Điều các PH khác cần ở PH-18: tham số, DLQ, sự kiện, thông báo, việc, lịch, sao lưu, di trú |
| [D02-03-PH18](../../02-yeu-cau/frs/D02-03-PH18-frs-van-hanh.md) FRS 0.2 | Chức năng, quy tắc, 61 tham số `18.*` §8.2 (nguồn chuẩn, CSDL đọc trực tiếp để sinh dữ liệu khởi tạo), số FR của mục "FR phục vụ" |
| [D02-07](../../02-yeu-cau/D02-07-tu-dien-du-lieu.md) Từ điển dữ liệu | DD-13 Thông báo, DD-14 Tham số cấu hình |
| [D03-09](../ha-tang/D03-09-ha-tang-trien-khai-dr.md) Hạ tầng và DR | §8.2 đối tượng sao lưu, §8.5 khôi phục một tenant (RBK-04) |
| D03-10 Thiết kế đa tenant | RLS theo `tenant_id`, tenant `COMMON`, sáp nhập tenant |
| `docs/07-srs/SRS-PH-18-ops.md` (SRS cũ của repo) | Mô hình DLQ cũ M4, ánh xạ ở mục 8.3 |
| [D03-03-PH17](D03-03-PH17-csdl-tro-ly-ai.md) | Mẫu cấu trúc tập CSDL và công cụ sinh |

: Tài liệu tham chiếu của D03-03-PH18

### 0.4. Người đọc

Kỹ sư backend đọc chương 1, 3 và 5 để viết repository và migration; DBA đọc chương 1, 4, 7 để triển khai, phân vùng, sao lưu; cán bộ ATTT đọc mục 1.2, 1.4 và 7; kiểm thử viên dùng tệp kiểm cô lập ở mục 4.2; hội đồng thẩm định đọc phần tóm tắt, chương 2 và chương 9.

### 0.5. Cấu trúc tài liệu

Chương 1 nêu chiến lược lưu trữ; chương 2 vẽ ERD theo khối; chương 3 đặc tả 57 bảng, mỗi bảng một khối 10 mục trích từ DDL; chương 4 mô tả DDL, changelog và kết quả chạy thử; chương 5 dữ liệu khởi tạo; chương 6 kho ngoài PostgreSQL; chương 7 sao lưu, mã hóa, lưu giữ; chương 8 ánh xạ thực thể, chức năng và mô hình cũ; chương 9 câu hỏi mở; chương 10 đề nghị đồng bộ.

## 1. Chiến lược lưu trữ

PH-18 là phân hệ control plane nên dữ liệu nằm cùng cụm `pg-core` với các phân hệ khác, tách schema và vai trò. Chương này nêu cách tổ chức schema, cách ly tenant, quy ước bảng và các quy tắc nghiệp vụ được chốt ngay ở CSDL.

### 1.1. Schema, vai trò và kết nối

Schema `ph18_ops` do vai `ph18_owner` sở hữu. Bốn vai đều `NOBYPASSRLS`; ứng dụng và Job kết nối bằng tài khoản LOGIN là thành viên của vai tương ứng, mật khẩu do OpenBao cấp động.

| Vai | Kiểu | Dùng cho | Quyền chính |
|---|---|---|---|
| `ph18_owner` | NOLOGIN, NOINHERIT | Chủ đối tượng; tài khoản `dh_data_migrator` chạy Liquibase với vai này | Tạo, sửa cấu trúc; chạy thủ tục phân vùng (SECURITY DEFINER) |
| `ph18_app` | NOLOGIN | `dh-platform` module `ops` (REST `/api/ops/v1`, nội bộ `/ops/internal/v1`, consumer Kafka) | SELECT, INSERT, UPDATE bảng cha; chỉ SELECT, INSERT bảng chỉ thêm; DELETE chỉ bảng kỹ thuật, tùy chọn, liên kết và mục DLQ hết hạn |
| `ph18_readonly` | NOLOGIN | Báo cáo, PH-16, truy vấn hỗ trợ | SELECT mọi bảng cha, trừ cột payload DLQ, header ngữ cảnh, payload bản sửa, biến mẫu và người nhận thông báo, ảnh chụp bản ghi lỗi di trú |
| `ph18_worker` | NOLOGIN | Job K8s `dh-ops-worker` ở namespace `dh-batch` (`dh-migrate`, `dh-tenant-restore`, `dh-tenant-export`) | Đọc nguồn, kế hoạch, đối tượng sao lưu, lược đồ khóa; đọc ghi lần chạy, kết quả, bản ghi lỗi, bước khôi phục, lần xuất, sáp nhập; chỉ thêm đối chiếu, mẫu so sánh, kết quả kiểm tra khôi phục |

: Bốn vai của schema ph18_ops

Không vai nào có quyền trực tiếp trên phân vùng; mọi truy cập đi qua bảng cha để RLS luôn áp. Thủ tục `p_ensure_partitions` và `p_drop_partitions_before` là `SECURITY DEFINER` của `ph18_owner`, chỉ nhận bảng của `ph18_ops`, cấp EXECUTE cho `ph18_app` để `PartitionMaintenanceJob` gọi hằng ngày.

### 1.2. Cách ly tenant và dòng COMMON

Mỗi bảng bật `ENABLE` và `FORCE ROW LEVEL SECURITY` với bốn chính sách đọc, chèn, sửa, xóa (thủ tục `p_enable_rls`). Biến phiên `app.tenant_id` bắt buộc: thiếu biến thì truy vấn lỗi, không trả rỗng (đóng khi lỗi). Có ba kiểu bảng theo cách dùng dòng `COMMON`.

| Kiểu | Đọc | Ghi | Bảng |
|---|---|---|---|
| Theo tenant | Dòng của tenant phiên | Dòng của tenant phiên; CHECK `^T[0-9]{2}$` | DLQ, thông báo, việc, khôi phục, di trú, tùy chọn người dùng |
| Theo tenant, nhận dòng nền tảng | Dòng của tenant phiên (phiên `COMMON` thấy dòng `COMMON`) | Như trên, CHECK nhận thêm `COMMON` | `incident`, `backup_object`, `backup_run`, `restore_verification`, `dr_drill`, `ops_report`, `outbox_event`, `inbox_event` |
| Dùng chung | Dòng của tenant phiên và dòng `COMMON` | Dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` (PA) ghi | Lược đồ và giá trị tham số, cờ tính năng, nguồn DLQ, sổ tay lỗi, mẫu và quy tắc thông báo, loại việc, lịch, cửa sổ bảo trì |
| Chỉ `COMMON` | Mọi tenant | Chỉ phiên `COMMON`; CHECK `tenant_id = 'COMMON'` | `param_namespace`, `param_definition` |

: Kiểu cách ly tenant của bảng ph18_ops

Khóa ngoại trong cùng tenant dùng cặp (`tenant_id`, cột) để dòng con không trỏ sang tenant khác; khóa ngoại tới bảng dùng chung (lược đồ khóa, loại việc, quy tắc thông báo, sổ tay lỗi) dùng một cột vì dòng cha có thể là `COMMON`. Dòng `merge_transfer` thuộc tenant đích (CHECK `target_tenant = tenant_id`), tenant nguồn chỉ là thuộc tính, nên PH-20 và worker đặt phiên theo tenant đích.

### 1.3. Quy ước bảng và ngoại lệ

Mọi bảng có `id uuid` (UUID v7 do ứng dụng sinh), `tenant_id varchar(16)`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version integer` (trigger `tg_touch` tăng `version` khi sửa, dùng làm ETag cho `If-Match`). Hai bảng kỹ thuật `outbox_event`, `inbox_event` cũng theo quy ước này (`id` của outbox là mã sự kiện). Bảng phân vùng có khóa chính (`id`, cột phân vùng) và khóa duy nhất (`tenant_id`, `id`, cột phân vùng) để bảng con tham chiếu kèm cột phân vùng. Mã trạng thái là `varchar` có CHECK liệt kê giá trị, không dùng kiểu enum của PostgreSQL để thêm giá trị không cần khóa bảng.

### 1.4. Quy tắc nghiệp vụ chốt ở CSDL

Các quy tắc dưới đây được cưỡng chế bằng CHECK, chỉ mục duy nhất có điều kiện hoặc trigger, là lớp chặn thứ hai sau dịch vụ; vi phạm trả SQLSTATE để dịch vụ ánh xạ sang mã ERR-18 của FRS.

| Quy tắc | Cơ chế | SQLSTATE |
|---|---|---|
| Giá trị tham số đúng kiểu, trong miền, trong trần nền tảng; tham số mức `PLATFORM` tenant không ghi; mặc định của lược đồ hợp lệ | `tg_param_value_check`, `tg_param_definition_check`, `fn_param_check` | 23514 |
| Mỗi khóa một đề nghị chờ duyệt, một phiên bản `ACTIVE`; nội dung phiên bản bất biến; lịch sử không xóa | `uq_param_change_request_pending`, `uq_param_value_version_active`, `tg_immutable`, `tg_no_delete` | 23505, 55000 |
| Không gian tên `19` không đăng ký ở PH-18; khóa mang tiền tố không gian tên; cờ tính năng dạng `ff.{module}.{tính-năng}` | `ck_param_namespace_code`, `ck_param_definition_key`, `ck_feature_flag_key` | 23514 |
| Payload DLQ gốc không sửa; inline ≤ 256 KB; `POISON` ghi header thiếu; bỏ qua cần lý do ≥ 10 ký tự; header không giữ `authorization`, `cookie` | `tg_dlq_payload_guard`, `ck_dlq_message_*` | 55000, 23514 |
| Payload lớn chỉ ở bucket `dh-{tenant}-ops` của chính tenant, luôn mã hóa | `ck_dlq_payload_ref_bucket`, `ck_dlq_payload_ref_encrypted` | 23514 |
| Khóa lũy đẳng phát lại `dlqId:revision`; loạt vượt ngưỡng chỉ chạy khi đã duyệt; bộ đếm không vượt tổng | `ck_replay_item_idem`, `ck_replay_job_approved`, `ck_replay_job_counts` | 23514 |
| Bốn mắt: đề nghị tham số, egress, gói tham số, bản sửa payload Hạn chế, lượt phát lại, mẫu thông báo, cửa sổ bảo trì, việc bốn mắt, khôi phục tenant, lần chạy di trú thật, sổ cắt chuyển | `ck_*_four_eyes` | 23514 |
| Mẫu Mustache không logic; kích hoạt mẫu chỉ khi kiểm tra cấm trường đạt; biến mẫu không chứa số định danh; liên kết chỉ là đường dẫn nội bộ | `ck_notification_template_version_no_logic`, `_active`, `ck_notification_message_params`, `_link` | 23514 |
| Không khôi phục schema kiểm toán; số bước khớp mã bước của `dh-tenant-restore` | `ck_tenant_restore_request_schema_names`, `ck_tenant_restore_step_code` | 23514 |
| URL JDBC không kèm thông tin đăng nhập; bí mật chỉ là tham chiếu OpenBao trong nhánh tenant | `ck_legacy_source_jdbc`, `ck_legacy_source_vault` | 23514 |
| Đối tượng di trú đúng PH đích; chạy thật cần duyệt trước khi xếp hàng; đối chiếu chỉ ghi khớp khi số lượng và tổng kiểm tra khớp | `ck_migration_plan_item_target`, `ck_migration_run_real`, `ck_migration_reconciliation_matched` | 23514 |
| Bóng đạt cần tỷ lệ khớp ≥ ngưỡng; cắt chuyển cần mốc và hạn quay lui | `ck_parallel_run_group_shadow_ok`, `_cutover` | 23514 |
| Chuyển trạng thái theo brief §4 | 20 trigger `tg_*_fsm_status` | 55000 |
| Sự kiện outbox không mang payload DLQ, giá trị tham số, địa chỉ | `ck_outbox_event_no_content` | 23514 |

: Quy tắc nghiệp vụ chốt ở CSDL và cơ chế cưỡng chế

### 1.5. Tương thích DD-13 và DD-14

D02-07 đặt tên DD-13 là `ph18_ops.notification` và DD-14 là `ph18_ops.config_param`; FRS PH-07 cũng viện dẫn `ph18_ops.config_param`. Thiết kế này tách DD-14 thành lược đồ, giá trị, phiên bản, đề nghị để có bốn mắt và lịch sử, và tách DD-13 thành thông báo logic và lần gửi để có nhiều kênh. Để giữ tương thích tên, hai khung nhìn được tạo với `security_invoker = true` (RLS của bảng gốc áp cho người đọc).

| Khung nhìn | Trường | Nguồn |
|---|---|---|
| `config_param` | `key`, `value`, `schema`, `scope`, `effective_from`, `tenant_id`, `namespace_code`, `value_type`, `level`, `secure`, `display_group`, `version_no` | `param_definition` nối `param_value` dòng `COMMON` và dòng tenant phiên; giá trị hiệu lực là ghi đè tenant, nếu không thì giá trị nền tảng, nếu không thì mặc định |
| `notification` | `id`, `tenant_id`, `recipient_user_id`, `category`, `title`, `link`, `read_at`, `channels_sent`, `status`, `created_at` | `notification_delivery` kênh `IN_APP` nối `notification_message` |

: Khung nhìn tương thích DD-13 và DD-14

### 1.6. Ước lượng khối lượng (giả định)

Ước lượng dưới đây dựa trên giả định GĐ-01 (tỉnh T01 quy mô vừa, 200 HTTT) và tỷ lệ lỗi 0,1% của 2 triệu bản tin mỗi ngày qua PH-04; dùng để chọn phân vùng và hạn giữ, cần đo lại ở thí điểm.

| Bảng | Dòng mới mỗi tháng một tenant (giả định) | Kích thước mỗi tháng | Ghi chú |
|---|---|---|---|
| `dlq_message` | 60.000 | 1,5 đến 4 GB (payload inline trung bình 20 KB) | Payload > 256 KB ra Garage |
| `dlq_audit` | 200.000 | 0,1 GB | Giữ 60 tháng |
| `notification_delivery` | 300.000 | 0,15 GB | Giữ 180 ngày |
| `shadow_comparison_sample` | 3.000.000 trong giai đoạn chạy song song | 1,2 GB | Giữ 90 ngày, chỉ khi có nhóm chạy song song |
| `param_value_version` | 200 | không đáng kể | Giữ 5 năm |

: Ước lượng khối lượng các bảng lớn của ph18_ops

## 2. Sơ đồ thực thể quan hệ

Chương này vẽ ERD theo bảy khối chức năng có quan hệ (hai bảng kỹ thuật outbox, inbox và bảng báo cáo `ops_report` không có khóa ngoại nên không vẽ). Sơ đồ sinh bằng `tools/gen_erd.py` từ khóa ngoại thật trong DDL; tham chiếu logic theo mã vẽ nét đứt. Hình tổng quan dưới cho thấy các khối liên hệ với nhau qua đâu.

```{.mermaid caption="Tổng quan các khối dữ liệu của ph18_ops"}
flowchart TB
  A["Khối A · Kho tham số<br/>param_*, feature_flag, egress"]
  B["Khối B, C, D · DLQ và phát lại<br/>dlq_*, replay_*"]
  E["Khối E · Thông báo<br/>notification_*"]
  F["Khối F · Việc và lịch<br/>task_*, work_calendar"]
  G["Khối G · Sự cố<br/>incident_*"]
  H["Khối H · Sao lưu, khôi phục, sáp nhập<br/>backup_*, tenant_*, merge_transfer"]
  I["Khối I · Di trú, chạy song song<br/>migration_*, parallel_run_group"]
  J["Khối J · Báo cáo<br/>ops_report"]
  A -->|"18.* ngưỡng, hạn giữ"| B
  B -->|"vượt ngưỡng mở sự cố"| G
  B -->|"thông báo người xử lý"| E
  F -->|"nhắc việc"| E
  H -->|"sao lưu lỗi"| G
  I -->|"DLQ rỗng là điều kiện cắt chuyển"| B
  H -->|"xuất tenant cho sáp nhập"| H
  B --> J
  H --> J
  I --> J
```

Hình cho thấy kho tham số cấp ngưỡng và hạn giữ cho mọi khối, DLQ là nguồn mở sự cố và thông báo, khối di trú đọc trạng thái DLQ làm điều kiện cắt chuyển, và ba khối DLQ, sao lưu, di trú cấp số liệu cho báo cáo vận hành. Các mũi tên giữa khối là tham chiếu logic qua dịch vụ, không phải khóa ngoại.

<!-- gen:erd:start -->
Nhóm kho tham số và cờ tính năng (khối A) gồm 8 bảng (`param_namespace`, `param_definition`, `param_change_request`, `param_value`, `param_value_version`, `feature_flag`, `egress_allowlist_entry`, `param_bundle`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic theo mã.

```{.mermaid caption="ERD nhóm kho tham số và cờ tính năng (khối A)"}
erDiagram
  param_namespace ||--o{ param_definition : "namespace_code"
  param_definition ||--o{ param_change_request : "definition_id"
  param_definition ||--o{ param_value : "definition_id"
  param_definition ||--o{ param_value_version : "definition_id"
  param_change_request |o--o{ param_value_version : "change_request_id"
  feature_flag {
    uuid id PK
    varchar tenant_id
  }
  egress_allowlist_entry {
    uuid id PK
    varchar tenant_id
  }
  param_bundle {
    uuid id PK
    varchar tenant_id
  }
```

Hình cho thấy lược đồ khóa (`param_definition`) chỉ có ở dòng `COMMON` và là gốc của mọi giá trị, phiên bản, đề nghị duyệt; giá trị của tenant tham chiếu lược đồ bằng khóa ngoại một cột nên tenant không cần chép lược đồ. Cờ tính năng, danh sách egress và gói tham số đứng riêng vì chỉ liên hệ với lược đồ qua mã khóa.

Nhóm DLQ, phân loại và phát lại (khối B, C, D) gồm 10 bảng (`dlq_source`, `error_guide`, `dlq_group`, `dlq_message`, `dlq_payload_ref`, `dlq_revision`, `dlq_assignment`, `replay_job`, `replay_item`, `dlq_audit`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic theo mã.

```{.mermaid caption="ERD nhóm DLQ, phân loại và phát lại (khối B, C, D)"}
erDiagram
  error_guide |o--o{ dlq_group : "guide_id"
  dlq_group |o--o{ dlq_message : "group_id"
  dlq_message ||--o{ dlq_payload_ref : "dlq_id"
  dlq_message ||--o{ dlq_revision : "dlq_id"
  dlq_message ||--o{ dlq_assignment : "dlq_id"
  replay_job ||--o{ replay_item : "job_id"
  dlq_message ||--o{ replay_item : "dlq_id"
  dlq_message ||..o{ dlq_audit : "logic, dlq_id"
  replay_job ||..o{ dlq_audit : "logic, replay_job_id"
  dlq_source ||..o{ dlq_message : "logic, source_code"
  error_guide ||..o{ dlq_message : "logic, error_code"
```

Hình cho thấy `dlq_message` là tâm của khối: bản sửa, tham chiếu payload Garage, gán người và mục phát lại đều khóa ngoại kèm `received_at` (cột phân vùng) và xóa theo khi mục hết hạn, còn nhật ký `dlq_audit` chỉ tham chiếu logic để sống lâu hơn mục. Đăng ký nguồn và sổ tay lỗi là bảng dùng chung, liên hệ theo mã.

Nhóm thông báo (khối E) gồm 7 bảng (`notification_template`, `notification_template_version`, `notification_rule`, `notification_message`, `notification_delivery`, `user_notification_pref`, `suppression_entry`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic theo mã.

```{.mermaid caption="ERD nhóm thông báo (khối E)"}
erDiagram
  notification_template ||--o{ notification_template_version : "template_id"
  notification_rule |o--o{ notification_message : "rule_id"
  notification_message ||--o{ notification_delivery : "message_id"
  notification_template ||..o{ notification_rule : "logic, template_code"
  notification_template ||..o{ notification_message : "logic, template_code"
  task_type ||..o{ notification_rule : "logic, create_task_type"
  user_notification_pref {
    uuid id PK
    varchar tenant_id
  }
  suppression_entry {
    uuid id PK
    varchar tenant_id
  }
```

Hình cho thấy mẫu có phiên bản, quy tắc và thông báo trỏ tới mẫu theo mã (không khóa ngoại để mẫu `COMMON` và mẫu tenant cùng mã dùng được), lần gửi là con của thông báo và xóa theo khi thông báo hết hạn giữ. Tùy chọn người dùng và danh sách chặn đứng riêng, được đọc khi phân giải người nhận.

Nhóm Việc của tôi và lịch (khối F) gồm 6 bảng (`task_type`, `task_item`, `task_reminder`, `work_calendar`, `calendar_holiday`, `maintenance_window`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic theo mã.

```{.mermaid caption="ERD nhóm Việc của tôi và lịch (khối F)"}
erDiagram
  task_type ||--o{ task_item : "type_id"
  task_item ||--o{ task_reminder : "task_id"
  notification_message |o--o{ task_reminder : "notification_message_id"
  work_calendar ||--o{ calendar_holiday : "calendar_id"
  maintenance_window {
    uuid id PK
    varchar tenant_id
  }
```

Hình cho thấy việc tham chiếu loại việc dùng chung bằng khóa ngoại một cột, lịch nhắc là con của việc và có thể trỏ tới thông báo đã tạo; lịch làm việc là cha của ngày lễ, cửa sổ bảo trì đứng riêng.

Nhóm sự cố vận hành (khối G) gồm 3 bảng (`incident`, `incident_timeline`, `incident_link`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic theo mã.

```{.mermaid caption="ERD nhóm sự cố vận hành (khối G)"}
erDiagram
  incident ||--o{ incident_timeline : "incident_id"
  incident ||--o{ incident_link : "incident_id"
```

Hình cho thấy hồ sơ sự cố có mốc thời gian chỉ thêm và các liên kết tới đối tượng ở khối khác (mục DLQ, bản sao lưu, lần di trú) bằng mã tham chiếu.

Nhóm sao lưu, khôi phục, xuất và sáp nhập tenant (khối H) gồm 8 bảng (`backup_object`, `backup_run`, `restore_verification`, `tenant_restore_request`, `tenant_restore_step`, `tenant_export_job`, `dr_drill`, `merge_transfer`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic theo mã.

```{.mermaid caption="ERD nhóm sao lưu, khôi phục, xuất và sáp nhập tenant (khối H)"}
erDiagram
  backup_object ||--o{ backup_run : "object_id"
  backup_object ||--o{ restore_verification : "object_id"
  backup_run |o--o{ restore_verification : "backup_run_id"
  tenant_restore_request ||--o{ tenant_restore_step : "request_id"
  tenant_export_job |o--o{ merge_transfer : "export_job_id"
  dr_drill {
    uuid id PK
    varchar tenant_id
  }
```

Hình cho thấy đối tượng sao lưu là cha của bản sao lưu và kết quả kiểm tra khôi phục; yêu cầu khôi phục tenant có tám bước con; lần sáp nhập có thể trỏ tới lần xuất tenant đã dùng.

Nhóm di trú hệ cũ và chạy song song (khối I) gồm 12 bảng (`legacy_source`, `migration_plan`, `migration_plan_item`, `migration_run`, `migration_run_item_result`, `migration_error_record`, `migration_reconciliation`, `credential_reissue_marker`, `parallel_run_group`, `shadow_comparison_sample`, `cutover_checklist`, `cutover_log`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic theo mã.

```{.mermaid caption="ERD nhóm di trú hệ cũ và chạy song song (khối I)"}
erDiagram
  legacy_source ||--o{ migration_plan : "legacy_source_id"
  migration_plan ||--o{ migration_plan_item : "plan_id"
  migration_plan ||--o{ migration_run : "plan_id"
  migration_run |o--o{ migration_run : "rerun_of_run_id"
  migration_run ||--o{ migration_run_item_result : "run_id"
  migration_plan_item ||--o{ migration_run_item_result : "plan_item_id"
  migration_run ||--o{ migration_error_record : "run_id"
  migration_plan_item ||--o{ migration_error_record : "plan_item_id"
  migration_run ||--o{ migration_reconciliation : "run_id"
  migration_plan_item ||--o{ migration_reconciliation : "plan_item_id"
  migration_run |o--o{ credential_reissue_marker : "run_id"
  migration_plan |o--o{ parallel_run_group : "plan_id"
  parallel_run_group ||--o{ shadow_comparison_sample : "group_id"
  parallel_run_group ||--o{ cutover_checklist : "group_id"
  parallel_run_group ||--o{ cutover_log : "group_id"
```

Hình cho thấy chuỗi nguồn hệ cũ, kế hoạch, mục kế hoạch, lần chạy, kết quả, bản ghi lỗi, đối chiếu; nhóm chạy song song có mẫu so sánh phân vùng tháng, danh sách kiểm tra và sổ cắt chuyển.

<!-- gen:erd:end -->

## 3. Đặc tả bảng

Chương này đặc tả 57 bảng theo thứ tự trong DDL (nhóm theo khối). Bảng danh sách dưới đây cho cái nhìn chung trước; mỗi bảng sau đó có khối đặc tả 10 mục (mục đích, FR phục vụ, khóa chính, duy nhất, khóa ngoại, CHECK, chỉ mục, cách ly tenant, phân vùng và bất biến, ghi chú) trích trực tiếp từ DDL bằng `tools/them_dac_ta_bang.py`, kèm bảng cột có ghi chú. Bảy cột ngữ cảnh không lặp lại ở từng bảng.

<!-- gen:list:start -->
| STT | Bảng | Khối | EN | Phân vùng | Chỉ thêm | Dùng chung `COMMON` | Nội dung |
|---|---|---|---|---|---|---|---|
| 1 | `outbox_event` | Kỹ thuật | Kỹ thuật | Không | Không | Dòng nền tảng | Outbox (DD-11, ADR-042) cho sự kiện {tenant}.ops.*.v1 của PH-18 |
| 2 | `inbox_event` | Kỹ thuật | Kỹ thuật | Không | Không | Dòng nền tảng | Inbox khử trùng sự kiện PH-18 tiêu thụ (at-least-once) |
| 3 | `param_namespace` | A | EN-18-01 | Không | Không | Chỉ `COMMON` | Không gian tên tham số do từng PH đăng ký khi khởi động |
| 4 | `param_definition` | A | EN-18-02 | Không | Không | Chỉ `COMMON` | Lược đồ một khóa tham số (DD-14 schema) |
| 5 | `param_change_request` | A | EN-18-05 | Không | Không | Đọc chung | Đề nghị đổi tham số ★ chờ duyệt bốn mắt |
| 6 | `param_value` | A | EN-18-03 | Không | Không | Đọc chung | Giá trị hiện hành của một khóa theo tenant (DD-14 value, scope) |
| 7 | `param_value_version` | A | EN-18-04 | Không | Không | Đọc chung | Lịch sử phiên bản giá trị tham số (DD-14 có phiên bản) |
| 8 | `feature_flag` | A | EN-18-06 | Không | Không | Đọc chung | Cờ tính năng ff.{module}.{tính-năng} theo tenant (QT-BR-03, CC-CFG-04) |
| 9 | `egress_allowlist_entry` | A | EN-18-07 | Không | Không | Không | Danh sách đích egress cho phép theo tenant (kiểu LIST<HOST>, giải Q15-10) |
| 10 | `param_bundle` | A | EN-18-08 | Không | Không | Không | Gói tham số xuất nhập giữa môi trường (DEV, TEST, STAGING, PROD) |
| 11 | `dlq_source` | B, C, D | EN-18-18 | Không | Không | Đọc chung | Đăng ký nguồn DLQ |
| 12 | `error_guide` | B, C, D | EN-18-15 | Không | Không | Đọc chung | Sổ tay xử lý theo mã lỗi ERR (nguồn tri thức loại ERROR_CODE, GUIDE cho PH-17) |
| 13 | `dlq_group` | B, C, D | EN-18-13 | Không | Không | Không | Nhóm dấu hiệu lỗi |
| 14 | `dlq_message` | B, C, D | EN-18-09 | `received_at` | Không | Không | Chỉ mục mục DLQ hợp nhất |
| 15 | `dlq_payload_ref` | B, C, D | EN-18-10 | Không | Không | Không | Tham chiếu payload lớn hơn 256 KB ở Garage bucket dh-{tenant}-ops (không phải MinIO) |
| 16 | `dlq_revision` | B, C, D | EN-18-11 | Không | Không | Không | Bản sửa payload có kiểm soát |
| 17 | `dlq_assignment` | B, C, D | EN-18-14 | Không | Không | Không | Gán người xử lý mục DLQ |
| 18 | `replay_job` | B, C, D | EN-18-16 | Không | Không | Không | Lượt phát lại đơn hoặc loạt |
| 19 | `replay_item` | B, C, D | EN-18-17 | Không | Không | Không | Một mục trong lượt phát lại |
| 20 | `dlq_audit` | B, C, D | EN-18-12 | `occurred_at` | Có | Không | Nhật ký thao tác trên DLQ |
| 21 | `notification_template` | E | EN-18-19 | Không | Không | Đọc chung | Mẫu thông báo (thư, SMS, trong ứng dụng) của các PH |
| 22 | `notification_template_version` | E | EN-18-20 | Không | Không | Đọc chung | Phiên bản nội dung mẫu Mustache không logic |
| 23 | `notification_rule` | E | EN-18-21 | Không | Không | Đọc chung | Quy tắc thông báo theo sự kiện của các PH (hợp đồng §1.3) |
| 24 | `notification_message` | E | EN-18-22 | Không | Không | Không | Thông báo logic (outbox của NotificationApi, DD-13) |
| 25 | `notification_delivery` | E | EN-18-23 | `queued_at` | Không | Không | Lần gửi theo người nhận và kênh (nhật ký gửi) |
| 26 | `user_notification_pref` | E | EN-18-24 | Không | Không | Không | Tùy chọn nhận thông báo của người dùng |
| 27 | `suppression_entry` | E | EN-18-25 | Không | Không | Không | Danh sách chặn gửi do thư trả lại cứng, khiếu nại, địa chỉ sai hoặc chặn tay |
| 28 | `task_type` | F | EN-18-26 | Không | Không | Đọc chung | Loại việc do PH đăng ký qua TaskInboxApi |
| 29 | `task_item` | F | EN-18-27 | Không | Không | Không | Việc trong "Việc của tôi" (FR-00-070…072) |
| 30 | `task_reminder` | F | EN-18-28 | Không | Không | Không | Lịch nhắc việc: trước hạn, quá hạn, leo thang; thời điểm gửi và thông báo đã tạo |
| 31 | `work_calendar` | F | EN-18-29 | Không | Không | Đọc chung | Lịch ngày làm việc theo tenant (WorkingCalendarApi, khóa 18.calendar.*) |
| 32 | `calendar_holiday` | F | EN-18-30 | Không | Không | Đọc chung | Ngày lễ, ngày nghỉ bù, ngày làm bù của một lịch; căn cứ pháp lý (thông báo nghỉ lễ) |
| 33 | `maintenance_window` | F | EN-18-31 | Không | Không | Đọc chung | Cửa sổ bảo trì và cửa sổ đóng băng thay đổi |
| 34 | `incident` | G | EN-18-32 | Không | Không | Dòng nền tảng | Hồ sơ sự cố vận hành mở từ sự kiện (EVT-13-04, 05, DLQ vượt ngưỡng, sao lưu lỗi) hoặc tạo tay |
| 35 | `incident_timeline` | G | EN-18-33 | Không | Có | Dòng nền tảng | Mốc thời gian của sự cố |
| 36 | `incident_link` | G | EN-18-34 | Không | Không | Dòng nền tảng | Liên kết sự cố với đối tượng |
| 37 | `backup_object` | H | EN-18-35 | Không | Không | Dòng nền tảng | Đối tượng sao lưu theo D03-09 §8.2 |
| 38 | `backup_run` | H | EN-18-36 | Không | Không | Dòng nền tảng | Bản sao lưu thu từ nguồn |
| 39 | `restore_verification` | H | EN-18-37 | Không | Có | Dòng nền tảng | Kết quả kiểm tra khôi phục tự động (điều kiện 0 lỗi của 3-2-1-1-0) |
| 40 | `tenant_restore_request` | H | EN-18-38 | Không | Không | Không | Yêu cầu khôi phục một tenant (RBK-04, D03-09 §8.5) |
| 41 | `tenant_restore_step` | H | EN-18-39 | Không | Không | Không | Một trong tám bước của dh-tenant-restore (D03-09 §8.5) |
| 42 | `tenant_export_job` | H | EN-18-40 | Không | Không | Không | Lần xuất dữ liệu tenant bằng dh-tenant-export |
| 43 | `dr_drill` | H | EN-18-41 | Không | Không | Dòng nền tảng | Ghi nhận diễn tập DR và PITR toàn cụm (PA thực hiện ngoài ứng dụng, PH-18 chỉ ghi nhận) |
| 44 | `merge_transfer` | H | EN-18-55 | Không | Không | Không | Chuyển dữ liệu một phân hệ khi sáp nhập tenant (hợp đồng PH-20, BRIEF §7) |
| 45 | `legacy_source` | I | EN-18-42 | Không | Không | Không | Nguồn hệ cũ (IF-07) |
| 46 | `migration_plan` | I | EN-18-43 | Không | Không | Không | Kế hoạch di trú một nguồn |
| 47 | `migration_plan_item` | I | EN-18-44 | Không | Không | Không | Mục kế hoạch theo loại đối tượng |
| 48 | `migration_run` | I | EN-18-45 | Không | Không | Không | Lần chạy di trú |
| 49 | `migration_run_item_result` | I | EN-18-46 | Không | Không | Không | Kết quả một mục kế hoạch trong lần chạy |
| 50 | `migration_error_record` | I | EN-18-47 | Không | Không | Không | Bản ghi không chuyển được kèm lý do (FR-00-091, 092) |
| 51 | `migration_reconciliation` | I | EN-18-48 | Không | Có | Không | Báo cáo đối chiếu số lượng và tổng kiểm tra theo loại đối tượng sau lần chạy (FR-00-092) |
| 52 | `credential_reissue_marker` | I | EN-18-49 | Không | Không | Không | Đánh dấu đối tượng đã di trú cần cấp lại thông tin xác thực ở PH đích (FR-00-093 |
| 53 | `parallel_run_group` | I | EN-18-50 | Không | Không | Không | Nhóm dịch vụ chạy song song và cắt chuyển |
| 54 | `shadow_comparison_sample` | I | EN-18-51 | `sampled_at` | Có | Không | Mẫu so sánh phản hồi cũ và mới khi APISIX nhân bản lưu lượng sang Datahub |
| 55 | `cutover_checklist` | I | EN-18-52 | Không | Không | Không | Danh sách kiểm tra cắt chuyển của nhóm dịch vụ |
| 56 | `cutover_log` | I | EN-18-53 | Không | Có | Không | Sổ cắt chuyển |
| 57 | `ops_report` | J | EN-18-54 | Không | Không | Dòng nền tảng | Báo cáo vận hành định kỳ (DLQ, sao lưu, di trú, sự cố, tham số, tổng hợp) gửi PH-16 qua sự kiện |

: Danh sách 57 bảng của schema `ph18_ops` theo khối chức năng
<!-- gen:list:end -->

<!-- gen:tables:start -->
### 3.1. `outbox_event`

::: dac-ta
**Mục đích.** Bảng kỹ thuật (không có mã EN).

**FR phục vụ.** Hạ tầng dùng chung (outbox, inbox).

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_event_` + prefix, topic, trace, no_content.

**Chỉ mục.** `ix_outbox_event_occurred`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa); nhận dòng `COMMON` mức nền tảng, chỉ phiên `COMMON` đọc và ghi. Quyền thêm: vai `ph18_worker` đọc, thêm.

**Phân vùng, bất biến.** Không.

**Ghi chú.** Debezium Outbox Event Router đọc WAL và phát lên Kafka; ghi cùng giao dịch với thay đổi (ADR-042). Vai ứng dụng không sửa dòng outbox.
:::

Cột: `event_type` v(128); `topic` v(249); `aggregate_type` v(64); `aggregate_id` v(255); `partition_key` v(255); `payload` jsonb; `trace_id` char(32); `occurred_at` tstz; `published_at` tstz.

### 3.2. `inbox_event`

::: dac-ta
**Mục đích.** Bảng kỹ thuật (không có mã EN).

**FR phục vụ.** Hạ tầng dùng chung (outbox, inbox).

**Khóa chính.** `id`.

**Duy nhất.** `uq_inbox_event_consumer` (tenant_id, consumer, event_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_inbox_event_` + consumer, prefix.

**Chỉ mục.** `ix_inbox_event_received`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa); nhận dòng `COMMON` mức nền tảng, chỉ phiên `COMMON` đọc và ghi.

**Phân vùng, bất biến.** Không.

**Ghi chú.** Khử trùng sự kiện nhận theo (`consumer`, `event_id`); tiêu thụ lũy đẳng; dọn theo `18.dlq.dedup-window-days` với consumer DLQ và 7 ngày với consumer khác.
:::

Cột: `consumer` v(64); `event_id` v(255); `source_topic` v(249); `event_type` v(255); `received_at` tstz; `processed_at` tstz; `outcome` v(2000).

### 3.3. `param_namespace`

::: dac-ta
**Mục đích.** EN-18-01 Không gian tên tham số do từng PH đăng ký khi khởi động (onboarding, 00, 02, 04, 05, 07.rdm, 10, 12, 14, 15, 17, 18, 20, ff; mở cho 06, 08, 09, 11, 13, 16; 19 do PH-19 tự giữ).

**FR phục vụ.** FR-18-001; EN-18-01.

**Khóa chính.** `id`.

**Duy nhất.** `uq_param_namespace_code` (tenant_id, code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_param_namespace_` + code, owner, approval, ttl, status.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS; chỉ dòng `COMMON` (CHECK), mọi tenant đọc, chỉ phiên `COMMON` (PA) ghi.

**Phân vùng, bất biến.** Bất biến: `code`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `approval_owner` | `varchar(8), mặc định 'PH-18'` | PH giữ quy trình bốn mắt cho tham số ★ của không gian tên này; mặc định PH-18. |
| `cache_ttl_seconds` | `integer, mặc định 60` | Thời gian đệm tối đa ở PH đọc; trần 60 giây theo NFR-00-052 và CC-CFG-04. |

: Cột của bảng `param_namespace`

Cột khác: `code` v(32); `owner_module` v(8); `title` v(255); `description` text; `status` v(12) {ACTIVE, RETIRED}.

### 3.4. `param_definition`

::: dac-ta
**Mục đích.** EN-18-02 Lược đồ một khóa tham số (DD-14 schema): kiểu, mặc định, miền, trần nền tảng, mức PLATFORM hay TENANT, cờ bảo mật ★, nhóm hiển thị.

**FR phục vụ.** FR-18-001; EN-18-02.

**Khóa chính.** `id`.

**Duy nhất.** `uq_param_definition_key` (tenant_id, param_key).

**Khóa ngoại.** (tenant_id, namespace_code) → `param_namespace`.

**Ràng buộc CHECK.** `ck_param_definition_` + key, type, level, range, allowed, enum, removal.

**Chỉ mục.** `ix_param_definition_group`.

**Cách ly tenant.** FORCE RLS; chỉ dòng `COMMON` (CHECK), mọi tenant đọc, chỉ phiên `COMMON` (PA) ghi.

**Phân vùng, bất biến.** Bất biến: `param_key`, `namespace_code`, `value_type`; Trigger: `tg_param_definition_validate`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `value_type` | `varchar(16)` | Trường type của FRS và OpenAPI (tên cột tránh từ khóa SQL). |
| `default_value` | `jsonb` | Trường default của FRS và OpenAPI (tên cột tránh từ khóa SQL). |
| `platform_ceiling` | `jsonb, NULL` | Trần nền tảng: giá trị tenant không vượt (số: không lớn hơn; danh sách: là tập con). |
| `level` | `varchar(8), mặc định 'TENANT'` | PLATFORM: chỉ PA ghi giá trị (dòng COMMON), tenant chỉ đọc; TENANT: tenant ghi đè trong miền và trần. |
| `secure` | `boolean, mặc định false` | Trường secure của FRS (lược đồ khóa). Tham số ★ bảo mật: đổi cần bốn mắt (param_change_request) do approval_owner của không gian tên giữ. |
| `display_group` | `varchar(64), NULL` | Trường group của FRS và OpenAPI (tên cột tránh từ khóa SQL). |

: Cột của bảng `param_definition`

Cột khác: `namespace_code` v(32); `param_key` v(128); `json_schema` jsonb; `min_value` numeric; `max_value` numeric; `allowed_values` jsonb; `unit` v(16); `display_order` int; `label` v(255); `description` text; `deprecated_at` tstz; `removal_date` date.

### 3.5. `param_change_request`

::: dac-ta
**Mục đích.** EN-18-05 Đề nghị đổi tham số ★ chờ duyệt bốn mắt: giá trị đề xuất, giá trị hiện tại, lý do; người duyệt khác người đề nghị.

**FR phục vụ.** FR-18-004; EN-18-05.

**Khóa chính.** `id`.

**Duy nhất.** `uq_param_change_request_pending` (tenant_id, param_key) có điều kiện.

**Khóa ngoại.** (definition_id) → `param_definition`.

**Ràng buộc CHECK.** `ck_param_change_request_` + status, reason, four_eyes, decided, owner.

**Chỉ mục.** `ix_param_change_request_status`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.

**Phân vùng, bất biến.** Bất biến: `definition_id`, `param_key`, `proposed_value`, `requested_by`, `reason`; Trigger: `tg_param_change_request_fsm_status`, `tg_param_change_request_value`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `definition_id` uuid; `param_key` v(128); `proposed_value` jsonb; `current_value` jsonb; `reason` text; `status` v(20) {PENDING_APPROVAL, APPROVED, REJECTED, CANCELLED, EXPIRED}; `requested_by` v(64); `requested_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_note` v(1000); `expires_at` tstz; `approval_owner` v(8); `external_approval_ref` v(128).

### 3.6. `param_value`

::: dac-ta
**Mục đích.** EN-18-03 Giá trị hiện hành của một khóa theo tenant (DD-14 value, scope).

**FR phục vụ.** FR-18-003; EN-18-03.

**Khóa chính.** `id`.

**Duy nhất.** `uq_param_value_key` (tenant_id, param_key).

**Khóa ngoại.** (definition_id) → `param_definition`.

**Ràng buộc CHECK.** `ck_param_value_` + scope, version_no, source.

**Chỉ mục.** `ix_param_value_definition`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.

**Phân vùng, bất biến.** Bất biến: `definition_id`, `param_key`, `scope`; Trigger: `tg_param_value_validate`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `source` | `varchar(16), mặc định 'UI'` | SEED_TENANT: PH-20 ghi mặc định khi khởi tạo tenant (chỉ khóa chưa có); BUNDLE: nhập gói tham số; ROLLBACK: khôi phục phiên bản cũ. |

: Cột của bảng `param_value`

Cột khác: `definition_id` uuid; `param_key` v(128); `value` jsonb; `scope` v(8) {PLATFORM, TENANT}; `current_version_no` int; `effective_from` tstz; `changed_reason` v(1000).

### 3.7. `param_value_version`

::: dac-ta
**Mục đích.** EN-18-04 Lịch sử phiên bản giá trị tham số (DD-14 có phiên bản): mỗi lần ghi thêm một dòng; nội dung bất biến, chỉ trạng thái chuyển PENDING_APPROVAL sang ACTIVE hoặc REJECTED, ACTIVE sang SUPERSEDED.

**FR phục vụ.** FR-18-003, FR-18-004; EN-18-04.

**Khóa chính.** `id`.

**Duy nhất.** `uq_param_value_version_no` (tenant_id, param_key, version_no), `uq_param_value_version_active` (tenant_id, param_key) có điều kiện.

**Khóa ngoại.** (definition_id) → `param_definition`, (tenant_id, change_request_id) → `param_change_request`.

**Ràng buộc CHECK.** `ck_param_value_version_` + status, version_no, superseded.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.

**Phân vùng, bất biến.** Bất biến: `definition_id`, `param_key`, `version_no`, `value`, `previous_value`, `change_request_id`, `effective_from`; Trigger: `tg_param_value_version_fsm_status`, `tg_param_value_version_no_delete`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `definition_id` uuid; `param_key` v(128); `version_no` int; `value` jsonb; `previous_value` jsonb; `status` v(20) {PENDING_APPROVAL, ACTIVE, SUPERSEDED, REJECTED}; `reason` v(1000); `change_request_id` uuid; `rollback_of_version_no` int; `effective_from` tstz; `superseded_at` tstz.

### 3.8. `feature_flag`

::: dac-ta
**Mục đích.** EN-18-06 Cờ tính năng ff.{module}.{tính-năng} theo tenant (QT-BR-03, CC-CFG-04): chủ sở hữu, ngày gỡ bắt buộc.

**FR phục vụ.** FR-18-009; EN-18-06.

**Khóa chính.** `id`.

**Duy nhất.** `uq_feature_flag_key` (tenant_id, flag_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_feature_flag_` + key, module, rollout, status.

**Chỉ mục.** `ix_feature_flag_retire`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.

**Phân vùng, bất biến.** Bất biến: `flag_key`, `owner_ph`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `flag_key` v(128); `owner_ph` v(8); `owner_user` v(64); `description` text; `enabled` bool; `rollout_percent` smallint; `retire_by` date; `status` v(12) {ACTIVE, RETIRED}.

### 3.9. `egress_allowlist_entry`

::: dac-ta
**Mục đích.** EN-18-07 Danh sách đích egress cho phép theo tenant (kiểu LIST<HOST>, giải Q15-10): máy đích HTTPS, cổng, PH dùng (PH-15 backend thử và kho Git, PH-13 webhook).

**FR phục vụ.** FR-18-010; EN-18-07.

**Khóa chính.** `id`.

**Duy nhất.** `uq_egress_allowlist_entry_host` (tenant_id, host, port, used_by).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_egress_allowlist_entry_` + host, port, scheme, module, purpose, four_eyes, enabled.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `host`, `port`, `used_by`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `host` v(253); `port` int; `scheme` v(8); `used_by` v(8); `purpose` v(24) {DEV_PORTAL_BACKEND, GIT_REPO, WEBHOOK, MODEL_PROVIDER, OTHER}; `reason` v(500); `enabled` bool; `approved_by` v(64); `approved_at` tstz; `expires_at` tstz; `revoked_at` tstz; `revoked_by` v(64).

### 3.10. `param_bundle`

::: dac-ta
**Mục đích.** EN-18-08 Gói tham số xuất nhập giữa môi trường (DEV, TEST, STAGING, PROD): danh sách không gian tên, số khóa, tổng kiểm tra, khác biệt so với đích.

**FR phục vụ.** FR-18-008; EN-18-08.

**Khóa chính.** `id`.

**Duy nhất.** `uq_param_bundle_code` (tenant_id, bundle_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_param_bundle_` + direction, env, status, count, sha, bucket, four_eyes, applied.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `bundle_code`, `direction`; Trigger: `tg_param_bundle_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `bundle_code` v(64); `direction` v(8) {EXPORT, IMPORT}; `source_env` v(8) {DEV, TEST, STAGING, PROD}; `target_env` v(8); `namespaces` v(32)[]; `item_count` int; `sha256` char(64); `bucket` v(63); `object_key` text; `diff_summary` jsonb; `status` v(20) {DRAFT, VALIDATED, PENDING_APPROVAL, APPLIED, FAILED, REJECTED}; `approved_by` v(64); `approved_at` tstz; `applied_at` tstz; `error_message` v(2000).

### 3.11. `dlq_source`

::: dac-ta
**Mục đích.** EN-18-18 Đăng ký nguồn DLQ: PH nguồn, kênh vào (KAFKA topic {tenant}.ops.dlq.v1, API ops:dlq-write, FEDERATED liên thông DLQ tầng sự kiện PH-10 qua API-10-060, 061 không sao chép nội dung), chế độ phát lại replayMode của FRS (KAFKA_TOPIC nghe EVT-18-09, HTTP_PORT gọi cổng ReplayPort của nguồn, EVENT_LAYER đề nghị PH-10 qua API-10-064, NONE).

**FR phục vụ.** FR-18-012; EN-18-18.

**Khóa chính.** `id`.

**Duy nhất.** `uq_dlq_source_code` (tenant_id, source_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_dlq_source_` + code, module, channel, mode, event_layer, endpoint, federated.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.

**Phân vùng, bất biến.** Bất biến: `source_code`, `source_module`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `replay_endpoint` | `varchar(255), NULL` | Đường dẫn nội bộ (mTLS) của cổng phát lại ở PH nguồn; phát lại luôn qua lối vào của nguồn. |

: Cột của bảng `dlq_source`

Cột khác: `source_code` v(32); `source_module` v(8); `ingest_channel` v(12) {KAFKA, API, FEDERATED}; `replay_mode` v(16) {KAFKA_TOPIC, HTTP_PORT, EVENT_LAYER, NONE}; `callback_scope` v(64); `payload_viewable` bool; `enabled` bool; `description` v(500).

### 3.12. `error_guide`

::: dac-ta
**Mục đích.** EN-18-15 Sổ tay xử lý theo mã lỗi ERR (nguồn tri thức loại ERROR_CODE, GUIDE cho PH-17): nguyên nhân (causes), các bước xử lý (steps), khả năng phát lại replayable (YES, AFTER_FIX, NO), lớp lỗi mặc định, liên kết; tên trường theo FRS FR-18-025.

**FR phục vụ.** FR-18-025; EN-18-15.

**Khóa chính.** `id`.

**Duy nhất.** `uq_error_guide_code` (tenant_id, error_code, locale).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_error_guide_` + code, replayable, class, owner, content, status, published, runbook.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.

**Phân vùng, bất biến.** Bất biến: `error_code`, `locale`; Trigger: `tg_error_guide_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `error_code` v(16); `locale` v(8); `title` v(255); `owner_ph` v(8); `causes` text[]; `steps` text[]; `replayable` v(10) {YES, AFTER_FIX, NO}; `default_class` v(12) {TRANSIENT, BUSINESS, CONTRACT, POISON, UNKNOWN}; `links` text[]; `runbook_path` v(500); `status` v(12) {DRAFT, PUBLISHED, RETIRED}; `published_at` tstz; `published_by` v(64).

### 3.13. `dlq_group`

::: dac-ta
**Mục đích.** EN-18-13 Nhóm dấu hiệu lỗi: băm SHA-256 của (nguồn, luồng, mã lỗi, thông điệp đã chuẩn hóa) để gom mục DLQ giống nhau, đếm mục mở, tổng, lần đầu, lần cuối; gắn hướng dẫn xử lý.

**FR phục vụ.** FR-18-020; EN-18-13.

**Khóa chính.** `id`.

**Duy nhất.** `uq_dlq_group_signature` (tenant_id, signature).

**Khóa ngoại.** (guide_id) → `error_guide`.

**Ràng buộc CHECK.** `ck_dlq_group_` + signature, class, counts, seen.

**Chỉ mục.** `ix_dlq_group_open`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `signature`, `source_code`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `signature` char(64); `source_code` v(32); `flow_code` v(128); `error_code` v(16); `error_class` v(12) {TRANSIENT, BUSINESS, CONTRACT, POISON, UNKNOWN}; `sample_message` v(500); `first_seen_at` tstz; `last_seen_at` tstz; `open_count` int; `total_count` int; `guide_id` uuid.

### 3.14. `dlq_message`

::: dac-ta
**Mục đích.** EN-18-09 Chỉ mục mục DLQ hợp nhất: hợp đồng ngữ cảnh chuẩn (dh-dlq-reason, dh-dlq-attempts, dh-dlq-stage, dh-dlq-error-code, dh-flow, dh-version, traceparent, dh-tenant, dh-source-ph), lớp lỗi, trạng thái, ưu tiên, nhóm.

**FR phục vụ.** FR-18-013; EN-18-09.

**Khóa chính.** (id, received_at).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, group_id) → `dlq_group`.

**Ràng buộc CHECK.** `ck_dlq_message_` + status, class, priority, module, attempts, occurrence, trace, location, inline, inline_size, sha, federated, poison, discard, closed, expired, headers.

**Chỉ mục.** `ix_dlq_message_status`, `ix_dlq_message_key`, `ix_dlq_message_source`, `ix_dlq_message_group`, `ix_dlq_message_trace`, `ix_dlq_message_retention`, `ix_dlq_message_assignee`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Vai `ph18_readonly` không đọc cột `payload_inline`, `context_headers`.

**Phân vùng, bất biến.** Phân vùng tháng theo `received_at`, tạo trước 4 tháng; Bất biến: `dlq_key`, `source_code`, `source_module`, `flow_code`, `reason_code`, `first_failed_at`, `received_at`, `origin_topic`, `origin_offset`, `payload_sha256`; Trigger: `tg_dlq_message_fsm_status`, `tg_dlq_message_payload`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `missing_context` | `varchar(32)[], mặc định '{}'` | Tên header ngữ cảnh bị thiếu khi tiếp nhận; khác rỗng thì mục vào POISON. |
| `payload_location` | `varchar(10)` | INLINE chỉ cho payload JSON ≤ 18.dlq.payload.inline-max-kb; payload không phải JSON (ERR-18-101) luôn ở GARAGE dạng nhị phân, dù nhỏ. |
| `payload_inline` | `jsonb, NULL` | Payload gốc ≤ 256 KB (18.dlq.payload.inline-max-kb), trường nhạy cảm đã mã hóa ở PH-04; chỉ được đặt NULL khi dọn (PURGED). Vai readonly không đọc. |
| `occurrence_count` | `integer, mặc định 1` | Số lần gặp (BR-18-015): bản tin cùng dlqKey đến khi mục chưa đóng chỉ tăng bộ đếm, không tạo mục mới (ERR-18-105); cập nhật được, không thuộc tg_immutable. |
| `last_seen_at` | `timestamptz, mặc định now()` | Lần gặp cuối của dlqKey; cập nhật cùng occurrence_count. |
| `retention_until` | `timestamptz, NULL` | Hạn giữ: đóng + 18.dlq.retention.closed-days; mục mở không có hạn. |

: Cột của bảng `dlq_message`

Cột khác: `dlq_key` v(255); `source_code` v(32); `source_module` v(8); `flow_code` v(128); `flow_version` v(32); `stage` v(64); `reason_code` v(64); `error_code` v(16); `error_class` v(12) {TRANSIENT, BUSINESS, CONTRACT, POISON, UNKNOWN}; `error_message` v(2000); `attempts` int; `trace_id` char(32); `origin_topic` v(249); `origin_partition` int; `origin_offset` bigint; `dlq_partition` int; `dlq_offset` bigint; `external_ref` v(128); `first_failed_at` tstz; `received_at` tstz; `status` v(16) {NEW, TRIAGED, REPLAY_PENDING, REPLAYING, RESOLVED, REPLAY_FAILED, DISCARDED, POISON, EXPIRED}; `priority` v(2) {P1, P2, P3, P4}; `group_id` uuid; `assignee` v(64); `context_headers` jsonb; `schema_ref` v(255); `payload_content_type` v(127); `payload_size_bytes` int; `payload_sha256` char(64); `current_revision_no` int; `discard_reason` v(2000); `resolved_at` tstz; `closed_at` tstz, phân vùng `RANGE (received_at)`.

### 3.15. `dlq_payload_ref`

::: dac-ta
**Mục đích.** EN-18-10 Tham chiếu payload lớn hơn 256 KB ở Garage bucket dh-{tenant}-ops (không phải MinIO): bản gốc hoặc bản sửa, kích thước, SHA-256, mã hóa phía máy chủ.

**FR phục vụ.** FR-18-013, FR-18-016; EN-18-10.

**Khóa chính.** `id`.

**Duy nhất.** `uq_dlq_payload_ref_kind` (tenant_id, dlq_id, kind, revision_no).

**Khóa ngoại.** (tenant_id, dlq_id, dlq_received_at) → `dlq_message` xóa theo.

**Ràng buộc CHECK.** `ck_dlq_payload_ref_` + kind, revision, bucket, size, sha, encrypted.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `dlq_id`, `kind`, `revision_no`, `bucket`, `object_key`, `sha256`, `size_bytes`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `dlq_id` uuid; `dlq_received_at` tstz; `kind` v(10) {ORIGINAL, REVISION}; `revision_no` int; `bucket` v(63); `object_key` text; `size_bytes` bigint; `sha256` char(64); `content_type` v(127); `encrypted` bool; `purged_at` tstz.

### 3.16. `dlq_revision`

::: dac-ta
**Mục đích.** EN-18-11 Bản sửa payload có kiểm soát: payload mới (inline hoặc Garage), khác biệt JSON Patch so với bản trước, lý do; có dữ liệu mức Hạn chế thì bốn mắt.

**FR phục vụ.** FR-18-024; EN-18-11.

**Khóa chính.** `id`.

**Duy nhất.** `uq_dlq_revision_no` (tenant_id, dlq_id, revision_no).

**Khóa ngoại.** (tenant_id, dlq_id, dlq_received_at) → `dlq_message` xóa theo.

**Ràng buộc CHECK.** `ck_dlq_revision_` + no, location, inline, sha, diff, reason, status, four_eyes, restricted.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Vai `ph18_readonly` không đọc cột `payload`.

**Phân vùng, bất biến.** Bất biến: `dlq_id`, `revision_no`; Trigger: `tg_dlq_revision_frozen`, `tg_dlq_revision_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `dlq_id` uuid; `dlq_received_at` tstz; `revision_no` int; `payload_location` v(10) {INLINE, GARAGE}; `payload` jsonb; `payload_sha256` char(64); `diff` jsonb; `reason` text; `contains_restricted` bool; `status` v(20) {DRAFT, PENDING_APPROVAL, APPROVED, REJECTED, CANCELLED}; `approved_by` v(64); `approved_at` tstz; `rejected_reason` v(1000).

### 3.17. `dlq_assignment`

::: dac-ta
**Mục đích.** EN-18-14 Gán người xử lý mục DLQ: người được gán, người gán, ưu tiên, ghi chú; mỗi mục chỉ một lần gán đang hiệu lực (unassigned_at rỗng).

**FR phục vụ.** FR-18-023; EN-18-14.

**Khóa chính.** `id`.

**Duy nhất.** `uq_dlq_assignment_active` (tenant_id, dlq_id) có điều kiện.

**Khóa ngoại.** (tenant_id, dlq_id, dlq_received_at) → `dlq_message` xóa theo.

**Ràng buộc CHECK.** `ck_dlq_assignment_` + priority, period.

**Chỉ mục.** `ix_dlq_assignment_assignee`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `dlq_id`, `assignee`, `assigned_by`, `assigned_at`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `dlq_id` uuid; `dlq_received_at` tstz; `assignee` v(64); `assigned_by` v(64); `assigned_at` tstz; `unassigned_at` tstz; `priority` v(2) {P1, P2, P3, P4}; `note` v(500).

### 3.18. `replay_job`

::: dac-ta
**Mục đích.** EN-18-16 Lượt phát lại đơn hoặc loạt (theo bộ lọc hay danh sách, ≤ 18.dlq.replay.batch-max); vượt 18.dlq.replay.approval-threshold thì bốn mắt; tốc độ giới hạn; tạm dừng, hủy; bộ đếm kết quả.

**FR phục vụ.** FR-18-027, FR-18-028, FR-18-029; EN-18-16.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_replay_job_` + mode, single, filter, reason, rate, counts, status, four_eyes, approved.

**Chỉ mục.** `ix_replay_job_status`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `mode`, `filter`, `total_items`, `approval_required`; Trigger: `tg_replay_job_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `mode` v(12) {SINGLE, BATCH_FILTER, BATCH_LIST}; `filter` jsonb; `reason` text; `total_items` int; `succeeded` int; `failed` int; `skipped` int; `rate_per_second` int; `approval_required` bool; `status` v(20) {DRAFT, PENDING_APPROVAL, APPROVED, RUNNING, PAUSED, COMPLETED, PARTIAL, FAILED, CANCELLED, REJECTED}; `approved_by` v(64); `approved_at` tstz; `rejected_reason` v(1000); `started_at` tstz; `paused_at` tstz; `finished_at` tstz; `cancelled_by` v(64).

### 3.19. `replay_item`

::: dac-ta
**Mục đích.** EN-18-17 Một mục trong lượt phát lại: mục DLQ, số bản sửa, khóa lũy đẳng dlqId:revision gửi cho nguồn, trạng thái, trace phát lại, kết quả do nguồn báo (callback ops:replay-callback hoặc EVT-10-12).

**FR phục vụ.** FR-18-028, FR-18-030; EN-18-17.

**Khóa chính.** `id`.

**Duy nhất.** `uq_replay_item_dlq` (tenant_id, job_id, dlq_id).

**Khóa ngoại.** (tenant_id, job_id) → `replay_job` xóa theo, (tenant_id, dlq_id, dlq_received_at) → `dlq_message` xóa theo.

**Ràng buộc CHECK.** `ck_replay_item_` + idem, status, trace.

**Chỉ mục.** `ix_replay_item_pending`, `ix_replay_item_idem`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `job_id`, `dlq_id`, `revision_no`, `idempotency_key`; Trigger: `tg_replay_item_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `job_id` uuid; `dlq_id` uuid; `dlq_received_at` tstz; `revision_no` int; `idempotency_key` v(80); `status` v(20) {PENDING, SENT, SUCCEEDED, FAILED, SKIPPED, SKIPPED_DUPLICATE, CANCELLED}; `replay_trace_id` char(32); `dispatched_at` tstz; `result_at` tstz; `result_error_code` v(16); `result_message` v(2000).

### 3.20. `dlq_audit`

::: dac-ta
**Mục đích.** EN-18-12 Nhật ký thao tác trên DLQ (xem payload có lý do, phân loại, gán, sửa, duyệt, phát lại, bỏ qua, mở lại, hết hạn, dọn): chỉ thêm, đồng thời gửi PH-13 kiểm toán.

**FR phục vụ.** FR-18-023, FR-18-027, FR-18-030, FR-18-031, FR-18-032, FR-18-070; EN-18-12.

**Khóa chính.** (id, occurred_at).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_dlq_audit_` + action, actor_kind, reason, target, no_payload.

**Chỉ mục.** `ix_dlq_audit_dlq`, `ix_dlq_audit_actor`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Phân vùng tháng theo `occurred_at`, tạo trước 4 tháng; Chỉ thêm (`tg_dlq_audit_append_only`, vai ứng dụng chỉ SELECT, INSERT).

**Ghi chú.** Dòng không sửa sau khi thêm; `version` luôn 0.
:::

Cột: `dlq_id` uuid; `replay_job_id` uuid; `action` v(20) {INGEST, VIEW_PAYLOAD, TRIAGE, ASSIGN, REVISE, APPROVE_REVISION, REPLAY_REQUEST, REPLAY_APPROVE, REPLAY_RESULT, DISCARD, REOPEN, EXPIRE, PURGE, EXPORT}; `actor` v(64); `actor_kind` v(8) {USER, SERVICE}; `reason` text; `before_status` v(16); `after_status` v(16); `details` jsonb; `trace_id` char(32); `occurred_at` tstz, phân vùng `RANGE (occurred_at)`.

### 3.21. `notification_template`

::: dac-ta
**Mục đích.** EN-18-19 Mẫu thông báo (thư, SMS, trong ứng dụng) của các PH: mã mẫu, PH sở hữu, nhóm DD-13, thông báo bắt buộc (không tắt bằng tùy chọn), khẩn (bỏ qua giờ yên lặng).

**FR phục vụ.** FR-18-035; EN-18-19.

**Khóa chính.** `id`.

**Duy nhất.** `uq_notification_template_code` (tenant_id, template_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_notification_template_` + code, module, category, channels.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.

**Phân vùng, bất biến.** Bất biến: `template_code`, `owner_module`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `template_code` v(64); `owner_module` v(8); `title` v(255); `description` v(1000); `category` v(12) {TASK, JOB_RESULT, ALERT, INFO}; `channels` v(8)[]; `mandatory` bool; `urgent` bool; `active_version_no` int; `retired_at` tstz.

### 3.22. `notification_template_version`

::: dac-ta
**Mục đích.** EN-18-20 Phiên bản nội dung mẫu Mustache không logic: tiêu đề thư, thân, SMS, tiêu đề và liên kết trong ứng dụng, danh sách biến cho phép.

**FR phục vụ.** FR-18-035; EN-18-20.

**Khóa chính.** `id`.

**Duy nhất.** `uq_notification_template_version_no` (tenant_id, template_id, version_no, locale), `uq_notification_template_version_active` (tenant_id, template_id, locale) có điều kiện.

**Khóa ngoại.** (tenant_id, template_id) → `notification_template`.

**Ràng buộc CHECK.** `ck_notification_template_version_` + no, status, content, link, four_eyes, active, no_logic.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.

**Phân vùng, bất biến.** Bất biến: `template_id`, `version_no`, `locale`; Trigger: `tg_notification_template_version_frozen`, `tg_notification_template_version_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `body_text` | `text, NULL` | Mustache không logic: chỉ biến {{ten}} trong allowed_fields; CHECK chặn khối {{#}}, {{^}}, partial {{>}}. |
| `field_check_report` | `jsonb, NULL` | Kết quả kiểm tra cấm trường mức Hạn chế, Nhạy cảm theo PH-09 (FR-00-062). |

: Cột của bảng `notification_template_version`

Cột khác: `template_id` uuid; `version_no` int; `locale` v(8); `email_subject` v(255); `body_html` text; `sms_text` v(480); `in_app_title` v(255); `in_app_link` v(500); `allowed_fields` v(64)[]; `field_check_passed` bool; `status` v(12) {DRAFT, IN_REVIEW, ACTIVE, RETIRED}; `submitted_at` tstz; `reviewed_by` v(64); `reviewed_at` tstz; `activated_at` tstz; `retired_at` tstz.

### 3.23. `notification_rule`

::: dac-ta
**Mục đích.** EN-18-21 Quy tắc thông báo theo sự kiện của các PH (hợp đồng §1.3): loại sự kiện, điều kiện lọc, mẫu, cách phân giải người nhận, kênh, loại việc tạo kèm.

**FR phục vụ.** FR-18-039; EN-18-21.

**Khóa chính.** `id`.

**Duy nhất.** `uq_notification_rule_code` (tenant_id, rule_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_notification_rule_` + module, event, recipient, channels, priority.

**Chỉ mục.** `ix_notification_rule_event`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.

**Phân vùng, bất biến.** Bất biến: `rule_code`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `rule_code` v(64); `source_module` v(8); `event_type` v(255); `condition` jsonb; `template_code` v(64); `recipient_kind` v(16) {USER, GROUP, ROLE, SYSTEM_CONTACT, EVENT_FIELD, ON_CALL}; `recipient_expr` v(255); `channels` v(8)[]; `create_task_type` v(64); `priority` v(8) {NORMAL, URGENT}; `enabled` bool.

### 3.24. `notification_message`

::: dac-ta
**Mục đích.** EN-18-22 Thông báo logic (outbox của NotificationApi, DD-13): khóa lũy đẳng của bên gọi, mẫu và phiên bản, người nhận recipient_ref (người, nhóm, vai trò, đầu mối HTTT; PH-18 tự phân giải địa chỉ), biến mẫu (CHECK chặn trường định danh), chế độ ASYNC hoặc SYNC (thư mang liên kết, Q01-52), trạng thái tổng hợp từ các lần gửi.

**FR phục vụ.** FR-18-036; EN-18-22.

**Khóa chính.** `id`.

**Duy nhất.** `uq_notification_message_key` (tenant_id, caller_module, message_key).

**Khóa ngoại.** (rule_id) → `notification_rule`.

**Ràng buộc CHECK.** `ck_notification_message_` + module, recipient, category, channels, params, link, mode, priority, status.

**Chỉ mục.** `ix_notification_message_status`, `ix_notification_message_requested`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Vai `ph18_readonly` không đọc cột `params`, `recipient_ref`.

**Phân vùng, bất biến.** Bất biến: `caller_module`, `message_key`, `template_code`, `recipient_ref`, `params`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `caller_module` v(8); `message_key` v(128); `template_code` v(64); `template_version_no` int; `rule_id` uuid; `source_event_id` v(255); `recipient_ref` jsonb; `category` v(12) {TASK, JOB_RESULT, ALERT, INFO}; `channels` v(8)[]; `params` jsonb; `link` v(500); `mode` v(8) {ASYNC, SYNC}; `priority` v(8) {NORMAL, URGENT}; `status` v(12) {QUEUED, SENT, DELIVERED, BOUNCED, FAILED, SUPPRESSED}; `requested_at` tstz; `dispatched_at` tstz; `expires_at` tstz.

### 3.25. `notification_delivery`

::: dac-ta
**Mục đích.** EN-18-23 Lần gửi theo người nhận và kênh (nhật ký gửi): địa chỉ chỉ lưu dạng che và băm, trạng thái QUEUED sang SENT sang DELIVERED, BOUNCED hoặc FAILED; SUPPRESSED khi tùy chọn người dùng, giờ yên lặng, danh sách chặn.

**FR phục vụ.** FR-18-036, FR-18-040; EN-18-23.

**Khóa chính.** (id, queued_at).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, message_id) → `notification_message` xóa theo.

**Ràng buộc CHECK.** `ck_notification_delivery_` + channel, status, attempts, recipient, hash, in_app, read, suppressed.

**Chỉ mục.** `ix_notification_delivery_message`, `ix_notification_delivery_inbox`, `ix_notification_delivery_pending`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Phân vùng tháng theo `queued_at`, tạo trước 4 tháng; Bất biến: `message_id`, `channel`, `recipient_user_id`, `recipient_hash`; Trigger: `tg_notification_delivery_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `message_id` uuid; `channel` v(8) {EMAIL, SMS, IN_APP}; `recipient_user_id` v(64); `recipient_masked` v(64); `recipient_hash` char(64); `status` v(12) {QUEUED, SENT, DELIVERED, BOUNCED, FAILED, SUPPRESSED}; `attempts` int; `provider_message_id` v(255); `rendered_title` v(255); `last_error` v(1000); `suppressed_reason` v(20); `queued_at` tstz; `sent_at` tstz; `delivered_at` tstz; `bounced_at` tstz; `read_at` tstz, phân vùng `RANGE (queued_at)`.

### 3.26. `user_notification_pref`

::: dac-ta
**Mục đích.** EN-18-24 Tùy chọn nhận thông báo của người dùng (FR-00-061) theo nhóm và kênh, giờ yên lặng; thông báo bắt buộc và khẩn không bị tắt bằng tùy chọn.

**FR phục vụ.** FR-18-038; EN-18-24.

**Khóa chính.** `id`.

**Duy nhất.** `uq_user_notification_pref` (tenant_id, user_id, category, channel).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_user_notification_pref_` + category, channel, quiet.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `user_id` v(64); `category` v(12) {TASK, JOB_RESULT, ALERT, INFO}; `channel` v(8) {EMAIL, SMS, IN_APP}; `enabled` bool; `quiet_from` time; `quiet_to` time.

### 3.27. `suppression_entry`

::: dac-ta
**Mục đích.** EN-18-25 Danh sách chặn gửi do thư trả lại cứng, khiếu nại, địa chỉ sai hoặc chặn tay: địa chỉ che và băm, số lần trả lại; thư trả lại phát ops.notification.bounced để PH-01 cập nhật đầu mối.

**FR phục vụ.** FR-18-040; EN-18-25.

**Khóa chính.** `id`.

**Duy nhất.** `uq_suppression_entry_active` (tenant_id, channel, address_hash) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_suppression_entry_` + channel, hash, reason, count, released.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `channel`, `address_hash`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `channel` v(8) {EMAIL, SMS}; `address_hash` char(64); `address_masked` v(64); `reason` v(12) {HARD_BOUNCE, COMPLAINT, INVALID, MANUAL}; `bounce_count` int; `first_bounced_at` tstz; `last_bounced_at` tstz; `released_at` tstz; `released_by` v(64); `released_reason` v(500).

### 3.28. `task_type`

::: dac-ta
**Mục đích.** EN-18-26 Loại việc do PH đăng ký qua TaskInboxApi (ph01.approve-onboarding, ph02.review-subscription, ph16.approve-report…): tiêu đề, hạn mặc định, mốc nhắc, quyền cần có, mẫu liên kết sâu, cờ bốn mắt.

**FR phục vụ.** FR-18-042; EN-18-26.

**Khóa chính.** `id`.

**Duy nhất.** `uq_task_type_code` (tenant_id, type_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_task_type_` + code, module, perm, link, due.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.

**Phân vùng, bất biến.** Bất biến: `type_code`, `owner_module`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `type_code` v(64); `owner_module` v(8); `title` v(255); `description` v(1000); `default_due_hours` int; `reminder_offsets_hours` int[]; `required_permission` v(64); `deep_link_pattern` v(500); `four_eyes` bool; `enabled` bool.

### 3.29. `task_item`

::: dac-ta
**Mục đích.** EN-18-27 Việc trong "Việc của tôi" (FR-00-070…072): loại việc, khóa lũy đẳng của PH tạo việc, tiêu đề không chứa dữ liệu Hạn chế, đối tượng, người hoặc vai trò được giao, hạn, trạng thái; việc bốn mắt thì người đóng khác người đề nghị.

**FR phục vụ.** FR-18-043; EN-18-27.

**Khóa chính.** `id`.

**Duy nhất.** `uq_task_item_key` (tenant_id, type_code, task_key).

**Khóa ngoại.** (type_id) → `task_type`.

**Ràng buộc CHECK.** `ck_task_item_` + assignee, priority, status, closed, four_eyes, link.

**Chỉ mục.** `ix_task_item_inbox`, `ix_task_item_due`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `type_id`, `type_code`, `task_key`, `requested_by`; Trigger: `tg_task_item_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `type_id` uuid; `type_code` v(64); `task_key` v(128); `title` v(255); `subject_ref` v(255); `assignee_kind` v(8) {USER, ROLE, GROUP}; `assignee_ref` v(128); `required_permission` v(64); `requested_by` v(64); `four_eyes` bool; `priority` v(8) {NORMAL, HIGH, URGENT}; `status` v(12) {OPEN, IN_PROGRESS, DONE, CANCELLED, EXPIRED}; `due_at` tstz; `claimed_by` v(64); `started_at` tstz; `closed_at` tstz; `closed_by` v(64); `outcome` v(32); `link` v(500).

### 3.30. `task_reminder`

::: dac-ta
**Mục đích.** EN-18-28 Lịch nhắc việc: trước hạn, quá hạn, leo thang; thời điểm gửi và thông báo đã tạo. Mỗi việc, loại nhắc, thời điểm một dòng.

**FR phục vụ.** FR-18-044; EN-18-28.

**Khóa chính.** `id`.

**Duy nhất.** `uq_task_reminder` (tenant_id, task_id, kind, remind_at).

**Khóa ngoại.** (tenant_id, task_id) → `task_item` xóa theo, (tenant_id, notification_message_id) → `notification_message`.

**Ràng buộc CHECK.** `ck_task_reminder_` + kind.

**Chỉ mục.** `ix_task_reminder_due`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `task_id` uuid; `kind` v(12) {BEFORE_DUE, OVERDUE, ESCALATION}; `remind_at` tstz; `sent_at` tstz; `notification_message_id` uuid.

### 3.31. `work_calendar`

::: dac-ta
**Mục đích.** EN-18-29 Lịch ngày làm việc theo tenant (WorkingCalendarApi, khóa 18.calendar.*): múi giờ, ngày làm việc trong tuần, giờ làm việc; dòng COMMON là lịch quốc gia, tenant kế thừa và bổ sung.

**FR phục vụ.** FR-18-045; EN-18-29.

**Khóa chính.** `id`.

**Duy nhất.** `uq_work_calendar_code` (tenant_id, calendar_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_work_calendar_` + days, hours, code.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.

**Phân vùng, bất biến.** Bất biến: `calendar_code`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `calendar_code` v(32); `name` v(255); `timezone` v(64); `working_days` smallint[]; `work_start` time; `work_end` time; `inherit_common` bool.

### 3.32. `calendar_holiday`

::: dac-ta
**Mục đích.** EN-18-30 Ngày lễ, ngày nghỉ bù, ngày làm bù của một lịch; căn cứ pháp lý (thông báo nghỉ lễ). Dòng COMMON cho lịch quốc gia.

**FR phục vụ.** FR-18-045; EN-18-30.

**Khóa chính.** `id`.

**Duy nhất.** `uq_calendar_holiday_date` (tenant_id, calendar_id, holiday_date).

**Khóa ngoại.** (tenant_id, calendar_id) → `work_calendar` xóa theo.

**Ràng buộc CHECK.** `ck_calendar_holiday_` + kind.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `calendar_id` uuid; `holiday_date` date; `name` v(255); `kind` v(16) {HOLIDAY, COMPENSATORY_OFF, WORKING_SWAP}; `legal_basis` v(255).

### 3.33. `maintenance_window`

::: dac-ta
**Mục đích.** EN-18-31 Cửa sổ bảo trì và cửa sổ đóng băng thay đổi (PH-02 đọc cờ đóng băng môi trường thật; PH-04 giữ 04.freeze.windows riêng, đề nghị hợp nhất): phạm vi PH, môi trường, thời gian, lý do, mẫu thông báo, duyệt bốn mắt.

**FR phục vụ.** FR-18-046; EN-18-31.

**Khóa chính.** `id`.

**Duy nhất.** `uq_maintenance_window_code` (tenant_id, window_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_maintenance_window_` + kind, module, env, period, reason, status, four_eyes, approved.

**Chỉ mục.** `ix_maintenance_window_time`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant phiên và dòng `COMMON` dùng chung, ghi chỉ dòng của tenant phiên; dòng `COMMON` chỉ phiên `COMMON` ghi.

**Phân vùng, bất biến.** Bất biến: `window_code`, `kind`; Trigger: `tg_maintenance_window_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `window_code` v(64); `kind` v(12) {MAINTENANCE, FREEZE}; `scope_module` v(8); `environment` v(8) {PROD, STAGING, TEST, ALL}; `starts_at` tstz; `ends_at` tstz; `reason` text; `announce_template_code` v(64); `release_ref` v(64); `status` v(12) {PLANNED, ACTIVE, COMPLETED, CANCELLED}; `approved_by` v(64); `approved_at` tstz.

### 3.34. `incident`

::: dac-ta
**Mục đích.** EN-18-32 Hồ sơ sự cố vận hành mở từ sự kiện (EVT-13-04, 05, DLQ vượt ngưỡng, sao lưu lỗi) hoặc tạo tay: mức độ, nhóm, chỉ huy, người xử lý, mốc thời gian, cờ dữ liệu cá nhân và tham chiếu PH-09 (INCIDENT_PH18, PH-09 giữ đồng hồ 72 giờ), nguyên nhân gốc và bài học khi đóng.

**FR phục vụ.** FR-18-047, FR-18-069; EN-18-32.

**Khóa chính.** `id`.

**Duy nhất.** `uq_incident_no` (tenant_id, incident_no).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_incident_` + no, severity, category, origin, event, status, closed, resolved, ph09.

**Chỉ mục.** `ix_incident_open`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa); nhận dòng `COMMON` mức nền tảng, chỉ phiên `COMMON` đọc và ghi.

**Phân vùng, bất biến.** Bất biến: `incident_no`, `origin`, `detected_at`; Trigger: `tg_incident_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `incident_no` v(20); `title` v(255); `severity` v(4) {SEV1, SEV2, SEV3, SEV4}; `category` v(16) {AVAILABILITY, DATA_INTEGRITY, SECURITY, PERFORMANCE, OTHER}; `origin` v(8) {EVENT, MANUAL}; `source_event_ref` v(255); `status` v(16) {OPEN, INVESTIGATING, MITIGATED, RESOLVED, CLOSED}; `commander` v(64); `assignee` v(64); `detected_at` tstz; `acknowledged_at` tstz; `mitigated_at` tstz; `resolved_at` tstz; `closed_at` tstz; `has_personal_data` bool; `ph09_breach_ref` v(64); `ph09_reported_at` tstz; `impact_summary` text; `root_cause` text; `lessons_learned` text.

### 3.35. `incident_timeline`

::: dac-ta
**Mục đích.** EN-18-33 Mốc thời gian của sự cố: đổi trạng thái, ghi chú, gán, thông báo, chuyển PH-09, liên kết, hành động. Chỉ thêm.

**FR phục vụ.** FR-18-049; EN-18-33.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, incident_id) → `incident`.

**Ràng buộc CHECK.** `ck_incident_timeline_` + kind, status_change.

**Chỉ mục.** `ix_incident_timeline_incident`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa); nhận dòng `COMMON` mức nền tảng, chỉ phiên `COMMON` đọc và ghi.

**Phân vùng, bất biến.** Chỉ thêm (`tg_incident_timeline_append_only`, vai ứng dụng chỉ SELECT, INSERT).

**Ghi chú.** Dòng không sửa sau khi thêm; `version` luôn 0.
:::

Cột: `incident_id` uuid; `occurred_at` tstz; `entry_kind` v(16) {STATUS_CHANGE, NOTE, ASSIGNMENT, NOTIFICATION, ESCALATION_PH09, LINK, ACTION}; `actor` v(64); `from_status` v(16); `to_status` v(16); `note` text.

### 3.36. `incident_link`

::: dac-ta
**Mục đích.** EN-18-34 Liên kết sự cố với đối tượng: mục DLQ, nhóm lỗi, cảnh báo PH-13, bản sao lưu, lần di trú, trace, hồ sơ vi phạm PH-09, tham chiếu ngoài.

**FR phục vụ.** FR-18-049; EN-18-34.

**Khóa chính.** `id`.

**Duy nhất.** `uq_incident_link` (tenant_id, incident_id, link_kind, target_ref).

**Khóa ngoại.** (tenant_id, incident_id) → `incident` xóa theo.

**Ràng buộc CHECK.** `ck_incident_link_` + kind, module.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa); nhận dòng `COMMON` mức nền tảng, chỉ phiên `COMMON` đọc và ghi.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `incident_id` uuid; `link_kind` v(16) {DLQ_MESSAGE, DLQ_GROUP, ALERT, BACKUP_RUN, MIGRATION_RUN, TRACE, PH09_BREACH, EXTERNAL}; `target_module` v(8); `target_ref` v(255); `note` v(500).

### 3.37. `backup_object`

::: dac-ta
**Mục đích.** EN-18-35 Đối tượng sao lưu theo D03-09 §8.2 (PostgreSQL cơ sở và WAL qua CNPG Barman Cloud, xuất logic theo tenant dh-tenant-export, Garage rclone, OpenBao Raft, Velero, ClickHouse, WORM kiểm toán…): công cụ, lịch, RPO, RTO, thời gian giữ, nơi lưu (chỉ tên kho, không thông tin xác thực), tầng phục hồi.

**FR phục vụ.** FR-18-052; EN-18-35.

**Khóa chính.** `id`.

**Duy nhất.** `uq_backup_object_code` (tenant_id, object_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_backup_object_` + code, kind, tool, numbers, tier, location.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa); nhận dòng `COMMON` mức nền tảng, chỉ phiên `COMMON` đọc và ghi. Quyền thêm: vai `ph18_worker` đọc.

**Phân vùng, bất biến.** Bất biến: `object_code`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `object_code` v(64); `name` v(255); `object_kind` v(20) {POSTGRES_BASE, POSTGRES_WAL, TENANT_EXPORT, OBJECT_STORE, SECRET_STORE, K8S_RESOURCES, VOLUME, GIT, REGISTRY, CLICKHOUSE, KAFKA_CONFIG, AUDIT_WORM, OFFLINE_SHARES}; `tool` v(20) {CNPG_BARMAN, DH_TENANT_EXPORT, RCLONE, OPENBAO_RAFT, VELERO, VELERO_KOPIA, GIT_MIRROR, HARBOR_REPLICATION, CLICKHOUSE_BACKUP, PH13_WORM, SHAMIR_OFFLINE}; `schedule` v(64); `rpo_minutes` int; `rto_minutes` int; `retention_days` int; `target_location` v(255); `recovery_tier` v(8); `verification_interval_days` int; `enabled` bool.

### 3.38. `backup_run`

::: dac-ta
**Mục đích.** EN-18-36 Bản sao lưu thu từ nguồn (CNPG Backup CR, Velero Backup, nhật ký rclone, snapshot OpenBao, kết quả dh-tenant-export): mã bản ở nguồn, thời gian, trạng thái, kích thước, vị trí, tổng kiểm tra, lỗi.

**FR phục vụ.** FR-18-052; EN-18-36.

**Khóa chính.** `id`.

**Duy nhất.** `uq_backup_run_ref` (tenant_id, object_id, run_ref).

**Khóa ngoại.** (tenant_id, object_id) → `backup_object`.

**Ràng buộc CHECK.** `ck_backup_run_` + status, finished, period, failed, sha, collector.

**Chỉ mục.** `ix_backup_run_object`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa); nhận dòng `COMMON` mức nền tảng, chỉ phiên `COMMON` đọc và ghi. Quyền thêm: vai `ph18_worker` đọc, thêm, sửa.

**Phân vùng, bất biến.** Bất biến: `object_id`, `run_ref`, `started_at`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `object_id` uuid; `run_ref` v(255); `started_at` tstz; `finished_at` tstz; `status` v(12) {RUNNING, SUCCEEDED, PARTIAL, FAILED, EXPIRED}; `size_bytes` bigint; `location` v(500); `checksum` char(64); `error_message` v(2000); `collector` v(32) {CNPG, VELERO, RCLONE, OPENBAO, DH_TENANT_EXPORT, CLICKHOUSE, MANUAL}; `collected_at` tstz.

### 3.39. `restore_verification`

::: dac-ta
**Mục đích.** EN-18-37 Kết quả kiểm tra khôi phục tự động (điều kiện 0 lỗi của 3-2-1-1-0): đối tượng, bản sao lưu, phương pháp, kết quả, thời lượng, đạt RTO, số dòng kiểm.

**FR phục vụ.** FR-18-053; EN-18-37.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, object_id) → `backup_object`, (tenant_id, backup_run_id) → `backup_run`.

**Ràng buộc CHECK.** `ck_restore_verification_` + method, outcome, duration.

**Chỉ mục.** `ix_restore_verification_object`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa); nhận dòng `COMMON` mức nền tảng, chỉ phiên `COMMON` đọc và ghi. Quyền thêm: vai `ph18_worker` đọc, thêm.

**Phân vùng, bất biến.** Chỉ thêm (`tg_restore_verification_append_only`, vai ứng dụng chỉ SELECT, INSERT).

**Ghi chú.** Dòng không sửa sau khi thêm; `version` luôn 0.
:::

Cột: `object_id` uuid; `backup_run_id` uuid; `verified_at` tstz; `method` v(20) {RESTORE_LATEST, PITR_RANDOM, TENANT_IMPORT, SAMPLE_FILES, HASH_CHAIN}; `outcome` v(8) {PASSED, FAILED}; `duration_seconds` int; `rto_met` bool; `rows_checked` bigint; `details` jsonb; `job_ref` v(128).

### 3.40. `tenant_restore_request`

::: dac-ta
**Mục đích.** EN-18-38 Yêu cầu khôi phục một tenant (RBK-04, D03-09 §8.5): thời điểm đích, phạm vi (toàn tenant hay một số schema), lý do; TA tạo, PA duyệt bốn mắt; dh-tenant-restore chạy tám bước, tenant SUSPENDED khi thay, phát ops.tenant.restored; mục tiêu ≤ 4 giờ cho tenant ≤ 200 GB.

**FR phục vụ.** FR-18-054, FR-18-055; EN-18-38.

**Khóa chính.** `id`.

**Duy nhất.** `uq_tenant_restore_request_no` (tenant_id, request_no), `uq_tenant_restore_request_active` (tenant_id) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_tenant_restore_request_` + scope, schemas, schema_names, reason, status, four_eyes, approved, step, point.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc, thêm, sửa.

**Phân vùng, bất biến.** Bất biến: `request_no`, `restore_point`, `scope`, `schemas`, `requested_by`; Trigger: `tg_tenant_restore_request_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `schemas` | `varchar(32)[], mặc định '{}'` | Schema thuộc phạm vi khi scope = SCHEMAS; không gồm schema kiểm toán ph13 (kiểm toán không khôi phục về quá khứ, D03-09 §8.5 bước 7). |

: Cột của bảng `tenant_restore_request`

Cột khác: `request_no` v(24); `restore_point` tstz; `scope` v(12) {FULL_TENANT, SCHEMAS}; `reason` text; `status` v(20) {DRAFT, PENDING_APPROVAL, APPROVED, RUNNING, SUCCEEDED, FAILED, ROLLED_BACK, REJECTED, CANCELLED}; `requested_by` v(64); `approved_by` v(64); `approved_at` tstz; `rejected_reason` v(1000); `current_step` smallint; `estimated_size_gb` numeric(10,2); `job_name` v(128); `heartbeat_at` tstz; `checkpoint` jsonb; `tenant_suspended_at` tstz; `tenant_resumed_at` tstz; `started_at` tstz; `finished_at` tstz; `rows_replaced` bigint.

### 3.41. `tenant_restore_step`

::: dac-ta
**Mục đích.** EN-18-39 Một trong tám bước của dh-tenant-restore (D03-09 §8.5): phê duyệt, dựng cụm tạm, trích dữ liệu, đặt tenant bảo trì, thay thế, kho khác, ghi kiểm toán, kiểm tra và mở lại; trạng thái, thời gian, số dòng.

**FR phục vụ.** FR-18-055; EN-18-39.

**Khóa chính.** `id`.

**Duy nhất.** `uq_tenant_restore_step_no` (tenant_id, request_id, step_no).

**Khóa ngoại.** (tenant_id, request_id) → `tenant_restore_request` xóa theo.

**Ràng buộc CHECK.** `ck_tenant_restore_step_` + code, status, period.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc, thêm, sửa.

**Phân vùng, bất biến.** Bất biến: `request_id`, `step_no`, `step_code`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `request_id` uuid; `step_no` smallint; `step_code` v(24); `status` v(12) {PENDING, RUNNING, SUCCEEDED, FAILED, SKIPPED, ROLLED_BACK}; `started_at` tstz; `finished_at` tstz; `rows_affected` bigint; `message` v(2000).

### 3.42. `tenant_export_job`

::: dac-ta
**Mục đích.** EN-18-40 Lần xuất dữ liệu tenant bằng dh-tenant-export: bàn giao khi DECOMMISSIONED, chuyển ô CSDL, SHARED sang DEDICATED_DB, sáp nhập (PH-20 gọi) hoặc theo yêu cầu; định dạng, phân hệ, tệp ra ở kho sao lưu, tổng kiểm tra, hạn tải.

**FR phục vụ.** FR-18-056; EN-18-40.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_tenant_export_job_` + purpose, module, format, status, sha, done.

**Chỉ mục.** `ix_tenant_export_job_status`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc, thêm, sửa.

**Phân vùng, bất biến.** Bất biến: `purpose`, `export_format`; Trigger: `tg_tenant_export_job_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `purpose` v(24) {HANDOVER, CELL_MOVE, DEDICATED_DB, ARCHIVE}; `requested_by_module` v(8); `ph20_request_ref` v(64); `export_format` v(8) {PG_COPY, PG_DUMP}; `modules` v(8)[]; `status` v(24) {QUEUED, RUNNING, SUCCEEDED, SUCCEEDED_WITH_ERRORS, FAILED, CANCELLED}; `output_location` v(500); `sha256` char(64); `size_bytes` bigint; `expires_at` tstz; `started_at` tstz; `finished_at` tstz; `job_name` v(128); `heartbeat_at` tstz; `checkpoint` jsonb; `error_message` v(2000).

### 3.43. `dr_drill`

::: dac-ta
**Mục đích.** EN-18-41 Ghi nhận diễn tập DR và PITR toàn cụm (PA thực hiện ngoài ứng dụng, PH-18 chỉ ghi nhận): loại, thời điểm, kết quả, RPO và RTO đạt được, phát hiện, hành động khắc phục, biên bản ở kho tài liệu.

**FR phục vụ.** FR-18-058; EN-18-41.

**Khóa chính.** `id`.

**Duy nhất.** `uq_dr_drill_code` (tenant_id, drill_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_dr_drill_` + kind, outcome, findings.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa); nhận dòng `COMMON` mức nền tảng, chỉ phiên `COMMON` đọc và ghi.

**Phân vùng, bất biến.** Bất biến: `drill_code`, `drill_kind`, `performed_at`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `drill_code` v(32); `drill_kind` v(20) {DR_SWITCHOVER, RBK_03, PITR_CLUSTER, TABLETOP}; `scheduled_at` tstz; `performed_at` tstz; `performed_by` v(64); `outcome` v(8) {PASSED, PASSED_WITH_ISSUES, FAILED}; `rpo_achieved_minutes` int; `rto_achieved_minutes` int; `findings` text; `actions` text; `report_ref` v(255).

### 3.44. `merge_transfer`

::: dac-ta
**Mục đích.** EN-18-55 Chuyển dữ liệu một phân hệ khi sáp nhập tenant (hợp đồng PH-20, BRIEF §7): PH-20 gọi POST /api/ops/v1/merge-transfers với mergePlanId, module, sourceTenant, targetTenant, mappingRef, dryRun; worker dh-tenant-export và nạp giữ id gốc, ghi origin_tenant_id ở PH đích; thêm mode (FULL hoặc DELTA, lượt bù cuối) và since cho lượt bù; PH-18 báo tiến độ về PH-20 (participants/{module}:report).

**FR phục vụ.** FR-18-057; EN-18-55.

**Khóa chính.** `id`.

**Duy nhất.** `uq_merge_transfer_real` (tenant_id, merge_plan_id, module, transfer_mode) có điều kiện.

**Khóa ngoại.** (tenant_id, export_job_id) → `tenant_export_job`.

**Ràng buộc CHECK.** `ck_merge_transfer_` + module, mode, tenants, status, progress, rows, report, done.

**Chỉ mục.** `ix_merge_transfer_plan`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc, thêm, sửa.

**Phân vùng, bất biến.** Bất biến: `merge_plan_id`, `module`, `source_tenant`, `target_tenant`, `mapping_ref`, `dry_run`, `transfer_mode`, `delta_since`; Trigger: `tg_merge_transfer_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `mapping_ref` | `varchar(255)` | Tham chiếu bảng ánh xạ mã của kế hoạch sáp nhập do PH-20 giữ (không chép nội dung). |
| `transfer_mode` | `varchar(5), mặc định 'FULL'` | FULL chuyển toàn bộ dòng của phân hệ; DELTA là lượt bù cuối trước cutover, chỉ chuyển dòng có updated_at từ delta_since (PH-20 gọi sau khi nguồn chỉ đọc). |
| `delta_since` | `timestamptz, NULL` | Mốc updated_at bắt đầu của lượt bù; chỉ có khi transfer_mode = DELTA, mặc định là finished_at của lượt FULL thật gần nhất. |

: Cột của bảng `merge_transfer`

Cột khác: `merge_plan_id` v(64); `module` v(8); `source_tenant` v(16); `target_tenant` v(16); `dry_run` bool; `status` v(24) {QUEUED, RUNNING, SUCCEEDED, SUCCEEDED_WITH_ERRORS, FAILED, CANCELLED}; `progress_percent` numeric(5,2); `rows_total` bigint; `rows_copied` bigint; `rows_skipped` bigint; `rows_failed` bigint; `export_job_id` uuid; `job_name` v(128); `heartbeat_at` tstz; `checkpoint` jsonb; `started_at` tstz; `finished_at` tstz; `last_reported_at` tstz; `report_status` v(16) {PENDING, REPORTED, REPORT_FAILED}; `error_message` v(2000).

### 3.45. `legacy_source`

::: dac-ta
**Mục đích.** EN-18-42 Nguồn hệ cũ (IF-07): loại hệ (Bus, Tooling, Hub, APIM, Danh mục Aita, PayGov, NGSP), URL JDBC không kèm thông tin đăng nhập, tham chiếu bí mật OpenBao kv/dh/{tenant}/..., xác nhận kết nối chỉ đọc.

**FR phục vụ.** FR-18-059; EN-18-42.

**Khóa chính.** `id`.

**Duy nhất.** `uq_legacy_source_code` (tenant_id, source_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_legacy_source_` + kind, jdbc, vault, status, verified.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc.

**Phân vùng, bất biến.** Bất biến: `source_code`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `credential_ref` | `varchar(255)` | Đường dẫn OpenBao kv/dh/{tenant}/migration/{nguồn}; PH-18 không lưu giá trị. |

: Cột của bảng `legacy_source`

Cột khác: `source_code` v(32); `name` v(255); `system_kind` v(12) {BUS, TOOLING, HUB, APIM, AITA, PAYGOV, NGSP, OTHER}; `jdbc_url` v(500); `read_only_verified` bool; `verified_at` tstz; `status` v(12) {DRAFT, VERIFIED, DISABLED}; `owner` v(64).

### 3.46. `migration_plan`

::: dac-ta
**Mục đích.** EN-18-43 Kế hoạch di trú một nguồn: các loại đối tượng theo thứ tự phụ thuộc (danh mục, HTTT, API, gói, đăng ký, topic, luồng, giao dịch), ngày cắt chuyển dự kiến.

**FR phục vụ.** FR-18-060; EN-18-43.

**Khóa chính.** `id`.

**Duy nhất.** `uq_migration_plan_code` (tenant_id, plan_code).

**Khóa ngoại.** (tenant_id, legacy_source_id) → `legacy_source`.

**Ràng buộc CHECK.** `ck_migration_plan_` + status, ready.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc.

**Phân vùng, bất biến.** Bất biến: `plan_code`, `legacy_source_id`; Trigger: `tg_migration_plan_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `plan_code` v(32); `legacy_source_id` uuid; `title` v(255); `description` text; `status` v(8) {DRAFT, READY}; `ready_at` tstz; `ready_by` v(64); `target_cutover_date` date.

### 3.47. `migration_plan_item`

::: dac-ta
**Mục đích.** EN-18-44 Mục kế hoạch theo loại đối tượng: PH đích đúng cặp (CATALOG sang PH-07, SYSTEM sang PH-01, API, PLAN, SUBSCRIPTION sang PH-02 hoặc PH-03, TOPIC, PUBLISHER, SUBSCRIBER sang PH-10, FLOW sang PH-04 nháp, TRANSACTION sang PH-19 API nhập), bộ chuyển, truy vấn nguồn đóng gói, API nhập của PH đích, phụ thuộc, cỡ lô.

**FR phục vụ.** FR-18-060; EN-18-44.

**Khóa chính.** `id`.

**Duy nhất.** `uq_migration_plan_item_seq` (tenant_id, plan_id, seq_no), `uq_migration_plan_item_kind` (tenant_id, plan_id, object_kind).

**Khóa ngoại.** (tenant_id, plan_id) → `migration_plan`.

**Ràng buộc CHECK.** `ck_migration_plan_item_` + kind, target, api, depends, batch.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc.

**Phân vùng, bất biến.** Bất biến: `plan_id`, `object_kind`, `target_module`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `plan_id` uuid; `seq_no` int; `object_kind` v(12) {CATALOG, SYSTEM, API, PLAN, SUBSCRIPTION, TOPIC, PUBLISHER, SUBSCRIBER, FLOW, TRANSACTION}; `target_module` v(8); `converter_code` v(64); `source_query_ref` v(255); `target_api` v(16); `depends_on` v(12)[]; `batch_size` int; `enabled` bool.

### 3.48. `migration_run`

::: dac-ta
**Mục đích.** EN-18-45 Lần chạy di trú: DRY_RUN không ghi, REAL ghi qua API nhập của PH đích và cần bốn mắt (PENDING_APPROVAL trước QUEUED); idempotent nên chạy lại không tạo bản trùng; worker dh-migrate là Job K8s ở dh-batch; bộ đếm mục.

**FR phục vụ.** FR-18-061; EN-18-45.

**Khóa chính.** `id`.

**Duy nhất.** `uq_migration_run_no` (tenant_id, plan_id, run_no), `uq_migration_run_active` (tenant_id, plan_id) có điều kiện.

**Khóa ngoại.** (tenant_id, plan_id) → `migration_plan`, (tenant_id, rerun_of_run_id) → `migration_run`.

**Ràng buộc CHECK.** `ck_migration_run_` + mode, status, dry, real, four_eyes, counts.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc, thêm, sửa.

**Phân vùng, bất biến.** Bất biến: `plan_id`, `run_no`, `run_mode`, `requested_by`; Trigger: `tg_migration_run_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `plan_id` uuid; `run_no` int; `run_mode` v(8) {DRY_RUN, REAL}; `status` v(24) {PENDING_APPROVAL, QUEUED, RUNNING, SUCCEEDED, SUCCEEDED_WITH_ERRORS, FAILED, CANCELLED}; `requested_by` v(64); `approved_by` v(64); `approved_at` tstz; `rerun_of_run_id` uuid; `job_name` v(128); `heartbeat_at` tstz; `checkpoint` jsonb; `started_at` tstz; `finished_at` tstz; `items_total` int; `items_succeeded` int; `items_failed` int; `items_skipped` int.

### 3.49. `migration_run_item_result`

::: dac-ta
**Mục đích.** EN-18-46 Kết quả một mục kế hoạch trong lần chạy: số bản ghi nguồn, đã chuyển, bỏ qua, lỗi, không đổi (chạy lại), tổng kiểm tra nguồn và đích.

**FR phục vụ.** FR-18-061, FR-18-062, FR-18-064; EN-18-46.

**Khóa chính.** `id`.

**Duy nhất.** `uq_migration_run_item_result` (tenant_id, run_id, plan_item_id).

**Khóa ngoại.** (tenant_id, run_id) → `migration_run` xóa theo, (tenant_id, plan_item_id) → `migration_plan_item`.

**Ràng buộc CHECK.** `ck_migration_run_item_result_` + status, counts, sha.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc, thêm, sửa.

**Phân vùng, bất biến.** Bất biến: `run_id`, `plan_item_id`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `run_id` uuid; `plan_item_id` uuid; `status` v(24) {QUEUED, RUNNING, SUCCEEDED, SUCCEEDED_WITH_ERRORS, FAILED, CANCELLED}; `source_count` bigint; `migrated_count` bigint; `unchanged_count` bigint; `skipped_count` bigint; `error_count` bigint; `source_checksum` char(64); `target_checksum` char(64); `started_at` tstz; `finished_at` tstz.

### 3.50. `migration_error_record`

::: dac-ta
**Mục đích.** EN-18-47 Bản ghi không chuyển được kèm lý do (FR-00-091, 092): mã bản ghi nguồn, mã lỗi, trường lỗi, ảnh chụp nguồn đã che (không thông tin xác thực), trạng thái sửa (OPEN, FIXED_AT_SOURCE sửa ở nguồn, RULE_ADDED thêm quy tắc, WONT_MIGRATE không di trú kèm lý do; theo FRS FR-18-063, ghi qua API-18-182).

**FR phục vụ.** FR-18-063; EN-18-47.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, run_id) → `migration_run` xóa theo, (tenant_id, plan_item_id) → `migration_plan_item`.

**Ràng buộc CHECK.** `ck_migration_error_record_` + code, fix, fixed, wont, snapshot.

**Chỉ mục.** `ix_migration_error_record_run`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc, thêm, sửa. Vai `ph18_readonly` không đọc cột `source_snapshot`.

**Phân vùng, bất biến.** Bất biến: `run_id`, `plan_item_id`, `source_record_ref`, `error_code`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `run_id` uuid; `plan_item_id` uuid; `source_record_ref` v(255); `error_code` v(16); `error_message` v(2000); `field_path` v(255); `source_snapshot` jsonb; `fix_status` v(16) {OPEN, FIXED_AT_SOURCE, RULE_ADDED, WONT_MIGRATE}; `fixed_by` v(64); `fixed_at` tstz; `fix_note` v(1000).

### 3.51. `migration_reconciliation`

::: dac-ta
**Mục đích.** EN-18-48 Báo cáo đối chiếu số lượng và tổng kiểm tra theo loại đối tượng sau lần chạy (FR-00-092): số nguồn, số đích, thiếu, thừa, lệch, tổng kiểm tra hai phía, khớp hay không.

**FR phục vụ.** FR-18-064; EN-18-48.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, run_id) → `migration_run`, (tenant_id, plan_item_id) → `migration_plan_item`.

**Ràng buộc CHECK.** `ck_migration_reconciliation_` + kind, counts, matched, sha.

**Chỉ mục.** `ix_migration_reconciliation_run`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc, thêm.

**Phân vùng, bất biến.** Chỉ thêm (`tg_migration_reconciliation_append_only`, vai ứng dụng chỉ SELECT, INSERT).

**Ghi chú.** Dòng không sửa sau khi thêm; `version` luôn 0.
:::

Cột: `run_id` uuid; `plan_item_id` uuid; `object_kind` v(12) {CATALOG, SYSTEM, API, PLAN, SUBSCRIPTION, TOPIC, PUBLISHER, SUBSCRIBER, FLOW, TRANSACTION}; `source_count` bigint; `target_count` bigint; `missing_count` bigint; `extra_count` bigint; `mismatch_count` bigint; `source_checksum` char(64); `target_checksum` char(64); `checksum_algo` v(16); `matched` bool; `computed_at` tstz; `report_location` v(500).

### 3.52. `credential_reissue_marker`

::: dac-ta
**Mục đích.** EN-18-49 Đánh dấu đối tượng đã di trú cần cấp lại thông tin xác thực ở PH đích (FR-00-093: không di trú bí mật): PH-01 (HTTT), PH-03 (đăng ký cổng), PH-02, PH-04, PH-07, PH-10, PH-19 (targetPh dạng PH-nn của FRS); trạng thái chờ, đã báo, đã cấp lại, miễn (WAIVED qua API-18-183 kèm lý do).

**FR phục vụ.** FR-18-065; EN-18-49.

**Khóa chính.** `id`.

**Duy nhất.** `uq_credential_reissue_marker` (tenant_id, target_module, target_ref, credential_kind).

**Khóa ngoại.** (tenant_id, run_id) → `migration_run`.

**Ràng buộc CHECK.** `ck_credential_reissue_marker_` + kind, module, credential, status, reissued, waived.

**Chỉ mục.** `ix_credential_reissue_marker_open`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc, thêm, sửa.

**Phân vùng, bất biến.** Bất biến: `target_module`, `target_ref`, `credential_kind`, `legacy_ref`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `run_id` uuid; `object_kind` v(12) {CATALOG, SYSTEM, API, PLAN, SUBSCRIPTION, TOPIC, PUBLISHER, SUBSCRIBER, FLOW, TRANSACTION}; `target_module` v(8) {}; `target_ref` v(255); `legacy_ref` v(255); `credential_kind` v(20) {OAUTH_CLIENT, CLIENT_CERT, API_KEY_LEGACY, PASSWORD}; `status` v(12) {PENDING, NOTIFIED, REISSUED, WAIVED}; `notified_at` tstz; `reissued_at` tstz; `reissued_ref` v(255); `waived_reason` v(1000).

### 3.53. `parallel_run_group`

::: dac-ta
**Mục đích.** EN-18-50 Nhóm dịch vụ chạy song song và cắt chuyển: phạm vi route, điểm cuối cũ và mới (tên, không thông tin xác thực), tỷ lệ nhân bản lưu lượng APISIX, ngưỡng khớp (18.migration.parallel.match-threshold-percent), tỷ lệ khớp, cầu nối PH-10 (EVT-10-15, 16), mốc cắt chuyển và hạn quay lui 15 phút (18.migration.rollback-window-minutes).

**FR phục vụ.** FR-18-066; EN-18-50.

**Khóa chính.** `id`.

**Duy nhất.** `uq_parallel_run_group_code` (tenant_id, group_code).

**Khóa ngoại.** (tenant_id, plan_id) → `migration_plan`.

**Ràng buộc CHECK.** `ck_parallel_run_group_` + ratio, status, samples, shadow_ok, cutover, rollback.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc.

**Phân vùng, bất biến.** Bất biến: `group_code`; Trigger: `tg_parallel_run_group_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `group_code` v(32); `plan_id` uuid; `title` v(255); `service_scope` v(500); `legacy_endpoint_ref` v(255); `datahub_endpoint_ref` v(255); `mirror_ratio_percent` numeric(5,2); `match_threshold_percent` numeric(6,3); `status` v(16) {PARALLEL, SHADOW_OK, PARTIAL_CUTOVER, CUT_OVER, ROLLED_BACK}; `samples_total` bigint; `samples_matched` bigint; `match_rate` numeric(6,3); `bridge_ref` v(128); `ph10_cutover_event_id` v(255); `cutover_at` tstz; `rollback_deadline_at` tstz; `rolled_back_at` tstz.

### 3.54. `shadow_comparison_sample`

::: dac-ta
**Mục đích.** EN-18-51 Mẫu so sánh phản hồi cũ và mới khi APISIX nhân bản lưu lượng sang Datahub: dấu vân tay yêu cầu, mã trạng thái, độ trễ, băm thân hai phía, khớp hay không, loại lệch và đường dẫn trường lệch (không lưu giá trị).

**FR phục vụ.** FR-18-067; EN-18-51.

**Khóa chính.** (id, sampled_at).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, group_id) → `parallel_run_group`.

**Ràng buộc CHECK.** `ck_shadow_comparison_sample_` + fingerprint, diff, status_code.

**Chỉ mục.** `ix_shadow_comparison_sample_group`, `ix_shadow_comparison_sample_miss`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa). Quyền thêm: vai `ph18_worker` đọc, thêm.

**Phân vùng, bất biến.** Phân vùng tháng theo `sampled_at`, tạo trước 4 tháng; Chỉ thêm (`tg_shadow_comparison_sample_append_only`, vai ứng dụng chỉ SELECT, INSERT).

**Ghi chú.** Dòng không sửa sau khi thêm; `version` luôn 0.
:::

Cột: `group_id` uuid; `sampled_at` tstz; `route` v(255); `request_fingerprint` char(64); `legacy_status` int; `datahub_status` int; `legacy_latency_ms` int; `datahub_latency_ms` int; `legacy_body_sha256` char(64); `datahub_body_sha256` char(64); `matched` bool; `diff_kind` v(8) {NONE, STATUS, BODY, LATENCY, ERROR}; `diff_paths` v(255)[]; `trace_id` char(32), phân vùng `RANGE (sampled_at)`.

### 3.55. `cutover_checklist`

::: dac-ta
**Mục đích.** EN-18-52 Danh sách kiểm tra cắt chuyển của nhóm dịch vụ: DLQ rỗng, tỷ lệ khớp ≥ ngưỡng, đối chiếu khớp, thông tin xác thực đã cấp lại, sao lưu đã kiểm, sẵn sàng quay lui, xác nhận các bên, cửa sổ đóng băng; tự động hay thủ công, bằng chứng, người kiểm.

**FR phục vụ.** FR-18-068; EN-18-52.

**Khóa chính.** `id`.

**Duy nhất.** `uq_cutover_checklist_item` (tenant_id, group_id, item_code).

**Khóa ngoại.** (tenant_id, group_id) → `parallel_run_group` xóa theo.

**Ràng buộc CHECK.** `ck_cutover_checklist_` + item, kind, status, checked, waived.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `group_id`, `item_code`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `group_id` uuid; `item_code` v(24) {DLQ_EMPTY, MATCH_RATE, RECONCILIATION_MATCHED, CREDENTIALS_REISSUED, BACKUP_VERIFIED, ROLLBACK_READY, STAKEHOLDER_SIGNOFF, FREEZE_WINDOW}; `description` v(500); `check_kind` v(8) {AUTO, MANUAL}; `status` v(8) {PENDING, PASSED, FAILED, WAIVED}; `evidence` jsonb; `checked_by` v(64); `checked_at` tstz; `waived_reason` v(1000).

### 3.56. `cutover_log`

::: dac-ta
**Mục đích.** EN-18-53 Sổ cắt chuyển: bắt đầu chạy song song, xác nhận bóng đạt, cắt chuyển một phần, cắt chuyển, quay lui, ký danh sách kiểm tra, ghi chú; cắt chuyển và quay lui cần người duyệt khác người thực hiện.

**FR phục vụ.** FR-18-068; EN-18-53.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, group_id) → `parallel_run_group`.

**Ràng buộc CHECK.** `ck_cutover_log_` + action, four_eyes.

**Chỉ mục.** `ix_cutover_log_group`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Chỉ thêm (`tg_cutover_log_append_only`, vai ứng dụng chỉ SELECT, INSERT).

**Ghi chú.** Dòng không sửa sau khi thêm; `version` luôn 0.
:::

Cột: `group_id` uuid; `action` v(20) {START_PARALLEL, SHADOW_CONFIRMED, PARTIAL_CUTOVER, CUTOVER, ROLLBACK, CHECKLIST_SIGNED, NOTE}; `actor` v(64); `approved_by` v(64); `occurred_at` tstz; `from_status` v(16); `to_status` v(16); `note` text.

### 3.57. `ops_report`

::: dac-ta
**Mục đích.** EN-18-54 Báo cáo vận hành định kỳ (DLQ, sao lưu, di trú, sự cố, tham số, tổng hợp) gửi PH-16 qua sự kiện: kỳ, chỉ số tổng hợp, tệp ở Garage bucket dh-{tenant}-ops, tổng kiểm tra.

**FR phục vụ.** FR-18-071; EN-18-54.

**Khóa chính.** `id`.

**Duy nhất.** `uq_ops_report_period` (tenant_id, report_kind, period_kind, period_from).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_ops_report_` + kind, period, status, bucket, sha, done.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa); nhận dòng `COMMON` mức nền tảng, chỉ phiên `COMMON` đọc và ghi.

**Phân vùng, bất biến.** Bất biến: `report_kind`, `period_kind`, `period_from`, `period_to`; Trigger: `tg_ops_report_fsm_status`.

**Ghi chú.** ETag là `version`; ghi có `If-Match`.
:::

Cột: `report_kind` v(12) {DLQ, BACKUP, MIGRATION, INCIDENT, PARAMETER, SUMMARY}; `period_kind` v(8) {DAY, WEEK, MONTH, QUARTER}; `period_from` date; `period_to` date; `status` v(24) {QUEUED, RUNNING, SUCCEEDED, SUCCEEDED_WITH_ERRORS, FAILED, CANCELLED}; `metrics` jsonb; `bucket` v(63); `object_key` text; `sha256` char(64); `generated_at` tstz; `published_event_id` uuid.
<!-- gen:tables:end -->

### 3.58. Phân vùng và bảo trì

Bốn bảng phân vùng theo tháng bằng `PARTITION BY RANGE`; DDL tạo sẵn bốn tháng (tháng trước, tháng hiện tại và hai tháng sau) để nhận bản ghi đến muộn. `PartitionMaintenanceJob` của `dh-platform` (ShedLock, 01:30 hằng ngày) gọi `p_ensure_partitions` để luôn có hai tháng phía trước và `p_drop_partitions_before` theo hạn giữ.

| Bảng | Cột phân vùng | Hạn giữ (tham số) | Cách dọn |
|---|---|---|---|
| `dlq_message` | `received_at` | Mục mở: đến khi đóng; đã đóng: `18.dlq.retention.closed-days` (90) rồi chỉ siêu dữ liệu tới `18.dlq.retention.metadata-days` (365) | Tác vụ lưu giữ chuyển `EXPIRED`, đặt payload `PURGED`, xóa đối tượng Garage; khi phân vùng không còn mục mở và quá hạn siêu dữ liệu thì xóa dòng (xóa theo bản sửa, tham chiếu, gán, mục phát lại) rồi DETACH, DROP |
| `dlq_audit` | `occurred_at` | `18.dlq.audit.retention-months` (60) | DETACH, DROP phân vùng quá hạn; bản chính thức đã ở PH-13 |
| `notification_delivery` | `queued_at` | `18.notify.log-retention-days` (180) | DETACH, DROP; `notification_message` xóa theo hạn cùng tham số |
| `shadow_comparison_sample` | `sampled_at` | `18.migration.shadow.sample-retention-days` (90) | DETACH, DROP |

: Phân vùng và cách dọn theo hạn giữ

Mục DLQ mở lâu làm phân vùng cũ không dọn được; tác vụ báo số mục mở theo tuổi qua chỉ số `dh_ops_dlq_open_oldest_seconds` để PH-13 cảnh báo (Q18-51).

## 4. DDL và changelog Liquibase

Chương này liệt kê tệp, cách sinh và kết quả chạy thật. DDL là nguồn chuẩn duy nhất: changelog Liquibase, chương 3 và bài kiểm thử đều sinh từ danh mục bảng, không sửa tay.

### 4.1. Tệp

Toàn bộ tệp nằm ở `03-thiet-ke/csdl/ph18/`.

| Tệp | Nội dung | Cách tạo |
|---|---|---|
| `ddl/ph18_ops.sql` | 2.790 dòng: vai trò, schema `ph18_ops` và `ph18_batch`, hàm và thủ tục, 57 bảng, 50 chỉ mục, 354 CHECK, 41 khóa ngoại, 135 trigger, 2 khung nhìn, sáu bảng JobRepository của Spring Batch, dữ liệu `COMMON`, quyền; 75 changeset | `python3 tools/sinh_ddl.py` từ `tools/sinh_ddl_core.py`, `sinh_ddl_bang_a.py`, `sinh_ddl_bang_b.py` |
| `test/ph18_isolation_test.sql` | 525 khối kiểm: danh mục hệ thống, cô lập từng bảng, quy tắc chốt, bảng chỉ thêm, vai, lưu giữ | `python3 tools/sinh_test.py` |
| `liquibase/db.changelog-ph18.yaml`, `liquibase/changes/*.sql` | 15 tệp formatted SQL, mỗi tệp một nhóm changeset | `python3 tools/gen_liquibase.py` |
| `tools/gen_tables_md.py`, `tools/them_dac_ta_bang.py`, `tools/gen_erd.py`, `tools/gen_anh_xa.py` | Sinh chương 3, ERD, danh sách bảng, ánh xạ EN (chép từ PH-17, sửa cho PH-18) | Chạy theo thứ tự ở mục 4.3 |

: Tệp DDL, kiểm thử, changelog và công cụ của PH-18

Nhóm changeset theo tệp: `18-0000-bootstrap` (vai, schema, context `bootstrap`), `18-0001-functions`, `18-0010-core` (outbox, inbox), `18-0020-param`, `18-0030-dlq`, `18-0040-notify`, `18-0050-task`, `18-0060-incident`, `18-0070-backup`, `18-0080-migration`, `18-0085-batch` (schema `ph18_batch`), `18-0090-report`, `18-0091-views`, `18-0095-seed` (context `seed`), `18-0900-grants` (`runAlways`).

### 4.2. Kết quả chạy thử

DDL và bài kiểm được chạy thật lại ngày 27/11/2026 (bản 0.2) trên PostgreSQL 16.15 (Ubuntu 24.04) bằng công cụ CI `build/tools/chay_ddl.py`.

| Bước | Kết quả |
|---|---|
| `ddl` trên CSDL rỗng `ci_ph18` | Sạch; 57 bảng cha, 16 phân vùng, 20 không gian tên, 61 khóa `18.*`, 6 nguồn DLQ, 12 đối tượng sao lưu, schema `ph18_batch` sáu bảng |
| `test` (`ph18_isolation_test.sql`) | 525 khối PASS: 9 kiểm danh mục, 343 kiểm cô lập (6 kiểm mỗi bảng cho 57 bảng và 1 kiểm phân vùng), 138 quy tắc chốt (thêm bộ đếm lần gặp), 13 bảng chỉ thêm, 19 vai readonly và worker (thêm quyền trên `ph18_batch`, nhịp sống và điểm dừng), 3 lưu giữ |
| `liquibase` (15 tệp trên CSDL rỗng `ci_ph18_lb`) | Sạch |
| `chung` (DDL và kiểm thử của 19 phân hệ trên một CSDL) | Sạch, không xung đột tên vai, schema, extension |

: Kết quả chạy thử DDL ph18_ops

Sáu kiểm cô lập của mỗi bảng: (a) chèn dòng mẫu của T90 (hoặc `COMMON` với bảng chỉ `COMMON`), (b) phiên T91 không đọc được dòng đó (bảng chỉ `COMMON` thì đọc được), (c) T91 không chèn được dòng mang `tenant_id` của T90 (42501), (d) T91 sửa không được dòng nào, hoặc vai ứng dụng không có quyền sửa với bảng chỉ thêm, (e) T91 xóa không được dòng nào, hoặc vai ứng dụng không có quyền xóa, (f) quay lại T90 vẫn thấy đúng một dòng chưa bị sửa.

### 4.3. Di trú Liquibase và quy trình sinh

Môi trường thật chạy Liquibase bằng tài khoản `dh_data_migrator` (thành viên `ph18_owner`) với `defaultSchemaName=ph18_ops`, context `bootstrap` ở lần đầu và `seed` khi khởi tạo môi trường. Mỗi thay đổi cấu trúc về sau là changeset mới có mã tăng dần trong dải `ph18-NNNN`, không sửa changeset đã chạy; thêm giá trị CHECK thì `DROP CONSTRAINT` rồi `ADD CONSTRAINT ... NOT VALID` và `VALIDATE CONSTRAINT` để tránh khóa lâu bảng phân vùng.

Quy trình sinh khi sửa danh mục bảng (từ thư mục `csdl/ph18`):

1. `python3 tools/sinh_ddl.py` sinh `ddl/ph18_ops.sql`.
2. `python3 tools/sinh_test.py` sinh `test/ph18_isolation_test.sql`.
3. `python3 tools/gen_liquibase.py` sinh `liquibase/`.
4. `python3 tools/gen_tables_md.py --write`, `python3 tools/them_dac_ta_bang.py ../D03-03-PH18-csdl-van-hanh.md`, `python3 tools/gen_erd.py --write`, `python3 tools/gen_anh_xa.py --write` cập nhật tài liệu.
5. `python3 ../../../build/tools/chay_ddl.py ph18` chạy thật.

### 4.4. Kho lần chạy Spring Batch

Worker `dh-migrate`, `dh-tenant-restore`, `dh-tenant-export` dùng Spring Batch (ADR-183) và cần `JobRepository` để khởi động lại Job từ bước dừng (SDD §13.5 điểm 9). Kho này đặt ở schema riêng `ph18_batch` (tệp `18-0085-batch.sql`), theo đúng lược đồ chuẩn `schema-postgresql.sql` của Spring Batch 5: `batch_job_instance`, `batch_job_execution`, `batch_job_execution_params`, `batch_step_execution`, `batch_step_execution_context`, `batch_job_execution_context` và ba sequence. Schema riêng giữ cho `ph18_ops` chỉ có bảng nghiệp vụ theo tenant có RLS; bảng Spring Batch không có `tenant_id` (mã tenant nằm trong tham số Job), không RLS, chỉ `ph18_worker` đọc ghi, `ph18_app` và `ph18_readonly` không có quyền (kiểm ở khối 4.17, 4.18). Trạng thái nghiệp vụ của lần chạy vẫn ở `migration_run`, `tenant_restore_request`, `tenant_export_job`, `merge_transfer`.

## 5. Dữ liệu khởi tạo

Changeset `ph18-0950-seed-common` (context `seed`) nạp dữ liệu nền tảng ở tenant `COMMON`, chạy lại không nhân bản (`ON CONFLICT DO NOTHING`, `id` băm từ mã). Thủ tục `p_seed_tenant` được gọi khi tiêu thụ `platform.tenant.created.v1` của PH-20.

| Dữ liệu | Số dòng | Nội dung |
|---|---|---|
| `param_namespace` | 20 | `00`, `onboarding`, `02`, `04`, `05`, `06`, `07.rdm`, `08`, `09`, `10`, `11`, `12`, `13`, `14`, `15`, `16`, `17`, `18`, `20`, `ff`; `14` và `17` có `approval_owner` là PH-14, PH-17 |
| `param_definition` | 61 | Khóa `18.*` của PH-18 đọc từ FRS §8.2 (bảng dưới) |
| `dlq_source` | 6 | `ph04-runtime` (Kafka, `KAFKA_TOPIC`), `ph10-event` (liên thông, `EVENT_LAYER`, không xem payload), `ph01-inbox`, `ph06-mdm-job`, `ph08-dq`, `ph19-inbox` (API, `HTTP_PORT`) |
| `backup_object` | 12 | Đối tượng D03-09 §8.2: bản sao cơ sở và WAL PostgreSQL, xuất logic tenant, Garage, OpenBao, mảnh khóa niêm phong ngoại tuyến, Velero, Kopia, Git, Harbor, ClickHouse, WORM kiểm toán |
| `work_calendar` | 1 | Lịch quốc gia `DEFAULT` (thứ Hai đến thứ Sáu, 07:30 đến 17:00, Asia/Ho_Chi_Minh) |
| `p_seed_tenant(Tnn)` | 1 mỗi tenant | Lịch `DEFAULT` của tenant kế thừa lịch quốc gia; tham số không chép vì đọc mặc định từ lược đồ |

: Dữ liệu khởi tạo của ph18_ops

Khóa `18.*` khởi tạo dưới đây sinh tự động từ bảng §8.2 của FRS PH-18 0.2 (`tools/sinh_ddl.py` đọc thẳng FRS), nên tên, kiểu, mặc định, miền, mức và cờ ★ luôn khớp FRS. Bản 0.1 dùng 30 khóa theo brief, trong đó 11 tên lệch FRS và khóa `18.dlq.discard.reason-min-chars` thừa (BR-18-023 cố định 10 ký tự); bản này bỏ các tên cũ.

| Khóa | Kiểu | Mặc định | Miền | Mức | ★ |
|---|---|---|---|---|---|
| `18.param.cache-ttl-seconds` | INT | 60 | 10 đến 60 | PLATFORM |  |
| `18.param.reason-min-length` | INT | 10 | 10 đến 200 | TENANT |  |
| `18.param.history-retention-days` | INT | 1825 | 365 đến 3650 | PLATFORM |  |
| `18.param.change-request-ttl-hours` | INT | 72 | 1 đến 720 | TENANT |  |
| `18.ff.retire-warning-days` | INT | 14 | 1 đến 90 | TENANT |  |
| `18.egress.allowlist` | LIST<HOST> | [] |  | TENANT |  |
| `18.egress.max-entries` | INT | 200 | 1 đến 1000 | PLATFORM |  |
| `18.dlq.payload.inline-max-kb` | INT | 256 | 64 đến 256 | PLATFORM |  |
| `18.dlq.payload.max-mb` | INT | 20 | 1 đến 100 | PLATFORM |  |
| `18.dlq.retention.closed-days` | INT | 90 | 30 đến 365 | TENANT |  |
| `18.dlq.retention.metadata-days` | INT | 365 | 90 đến 1825 | TENANT |  |
| `18.dlq.audit.retention-months` | INT | 60 | 12 đến 120 | PLATFORM |  |
| `18.dlq.dedup-window-days` | INT | 7 | 1 đến 30 | PLATFORM |  |
| `18.dlq.retention.open-max-days` | INT | 365 | 90 đến 1825 | TENANT |  |
| `18.dlq.reveal.ttl-minutes` | INT | 15 | 5 đến 60 | TENANT | ★ |
| `18.dlq.replay.batch-max` | INT | 10000 | 100 đến 50000 | TENANT |  |
| `18.dlq.replay.approval-threshold` | INT | 500 | 10 đến 10000 | TENANT | ★ |
| `18.dlq.replay.rate-per-second` | INT | 10 | 1 đến 100 | TENANT |  |
| `18.dlq.replay.result-timeout-minutes` | INT | 30 | 1 đến 1440 | TENANT |  |
| `18.dlq.threshold.depth` | INT | 1000 | 10 đến 1000000 | TENANT |  |
| `18.dlq.threshold.age-hours` | INT | 24 | 1 đến 720 | TENANT |  |
| `18.dlq.threshold.poison-per-hour` | INT | 10 | 1 đến 10000 | TENANT |  |
| `18.dlq.threshold.replay-failure-percent` | INT | 20 | 1 đến 100 | TENANT |  |
| `18.dlq.group.window-hours` | INT | 24 | 1 đến 168 | TENANT |  |
| `18.dlq.reconcile.cron` | CRON | 0 30 2 * * * |  | PLATFORM |  |
| `18.dlq.diagnostics.timeout-ms` | INT | 3000 | 500 đến 5000 | PLATFORM |  |
| `18.notify.quiet-hours` | STRING | 22:00-06:00 |  | TENANT |  |
| `18.notify.retry.max-attempts` | INT | 5 | 1 đến 10 | PLATFORM |  |
| `18.notify.retry.window-hours` | INT | 24 | 1 đến 72 | PLATFORM |  |
| `18.notify.sync.timeout-ms` | INT | 3000 | 1000 đến 10000 | PLATFORM |  |
| `18.notify.bounce.soft-limit` | INT | 3 | 1 đến 10 | TENANT |  |
| `18.notify.log-retention-days` | INT | 180 | 30 đến 730 | TENANT |  |
| `18.notify.sms.enabled` | BOOL | false |  | TENANT |  |
| `18.notify.sender-name` | STRING | Datahub {tỉnh} |  | TENANT |  |
| `18.task.reminder.before-hours` | INT | 24 | 1 đến 168 | TENANT |  |
| `18.task.overdue.escalate-hours` | INT | 48 | 1 đến 336 | TENANT |  |
| `18.task.retention-days` | INT | 365 | 30 đến 1825 | TENANT |  |
| `18.calendar.weekend-days` | LIST<STRING> | [SAT, SUN] |  | TENANT |  |
| `18.calendar.timezone` | STRING | Asia/Ho_Chi_Minh |  | PLATFORM |  |
| `18.maintenance.notice-hours` | INT | 72 | 1 đến 336 | TENANT |  |
| `18.freeze.default-envs` | LIST<STRING> | [PROD] | [DEV, TEST, STAGING, PROD] | TENANT |  |
| `18.incident.sev1-ack-minutes` | INT | 15 | 5 đến 60 | TENANT |  |
| `18.incident.sev2-ack-minutes` | INT | 60 | 15 đến 240 | TENANT |  |
| `18.incident.retention-years` | INT | 5 | 3 đến 10 | PLATFORM |  |
| `18.backup.stale-hours` | INT | 26 | 2 đến 72 | PLATFORM |  |
| `18.backup.freshness-max-minutes` | INT | 15 | 5 đến 60 | PLATFORM |  |
| `18.backup.verification-interval-days` | INT | 1 | 1 đến 90 | PLATFORM |  |
| `18.restore.max-duration-hours` | INT | 4 | 1 đến 24 | PLATFORM |  |
| `18.restore.approval-required` | BOOL | true | [true] | PLATFORM | ★ |
| `18.export.link-ttl-hours` | INT | 24 | 1 đến 72 | PLATFORM |  |
| `18.export.retention-days` | INT | 30 | 7 đến 90 | PLATFORM |  |
| `18.migration.dry-run-valid-days` | INT | 7 | 1 đến 30 | TENANT |  |
| `18.migration.batch-size` | INT | 500 | 50 đến 5000 | TENANT |  |
| `18.migration.parallel.match-threshold-percent` | DECIMAL | 99.5 | 90 đến 100 | TENANT |  |
| `18.migration.shadow.sample-percent` | INT | 5 | 1 đến 100 | TENANT |  |
| `18.migration.shadow.sample-retention-days` | INT | 90 | 7 đến 365 | TENANT |  |
| `18.migration.rollback-window-minutes` | INT | 15 | 5 đến 120 | PLATFORM |  |
| `18.report.schedule` | ENUM | MONTHLY | [MONTHLY, QUARTERLY] | TENANT |  |
| `18.report.retention-months` | INT | 24 | 12 đến 120 | TENANT |  |
| `18.degraded.read-only` | BOOL | false |  | PLATFORM |  |
| `18.outbox.retention-days` | INT | 3 | 1 đến 30 | PLATFORM |  |

: Khóa tham số 18.* khởi tạo ở param_definition

## 6. Kho lưu trữ ngoài PostgreSQL

PostgreSQL giữ chỉ mục, trạng thái và lịch sử; phần lớn nội dung nặng và bí mật nằm ở kho khác, PH-18 chỉ lưu tham chiếu.

### 6.1. Garage

Bucket `dh-{tenant}-ops` (chữ thường, ví dụ `dh-t68-ops`) giữ payload DLQ lớn hơn 256 KB và bản sửa lớn (`dlq/{yyyy}/{mm}/{dlqId}/{revision}.bin`), tệp gói tham số (`param-bundle/`), tệp báo cáo vận hành (`report/`). Bucket nền tảng `dh-common-ops` cho báo cáo `COMMON`. Mã hóa phía máy chủ bắt buộc, vòng đời đối tượng khớp hạn giữ của dòng tham chiếu; tác vụ lưu giữ xóa đối tượng rồi ghi `purged_at`. Tệp xuất tenant và kết quả khôi phục nằm ở kho sao lưu bất biến (Ceph RGW, Q341), không ở bucket `ops`.

### 6.2. Kafka

PH-18 là chủ topic `{tenant}.ops.dlq.v1` (tiêu thụ) và phát các topic `{tenant}.ops.*.v1` qua outbox (ví dụ `t68.ops.param.changed.v1`, `t68.ops.dlq.threshold-crossed.v1`, `t68.ops.notification.bounced.v1`, `t68.ops.tenant.restored.v1`). PH-18 tiêu thụ sự kiện các PH ở hợp đồng §1.3 và `platform.tenant.*.v1`, `platform.release.published.v1` của PH-20; khử trùng qua `inbox_event`. Topic DLQ giữ 7 ngày (đủ để đối soát độ lệch chỉ mục và Kafka), nguồn sự thật sau tiếp nhận là `dlq_message`.

### 6.3. OpenBao

Thông tin kết nối hệ cũ ở `kv/dh/{tenant}/migration/{nguồn}`, chỉ worker `dh-migrate` đọc. Khóa DEK của tenant (transit `dh-{tenant}-pii`) do PH-04 dùng để mã hóa trường nhạy cảm trước khi vào DLQ; PH-18 không giải mã. Thông tin SMTP và SMS gateway ở `kv/dh/common/notify/`.

### 6.4. Valkey

Bộ đệm đọc tham số (Caffeine ≤ 60 giây ở từng DU) không cần Valkey; PH-18 dùng Valkey cho bộ đếm tốc độ phát lại (`ops:replay:{jobId}:rate`) và khóa phân tán loạt phát lại, có thể mất mà không mất dữ liệu.

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

Schema `ph18_ops` nằm trong cụm `pg-core` nên được sao lưu cùng cụm (CNPG Barman Cloud, PITR 30 ngày) và xuất logic theo tenant bằng `dh-tenant-export`. Khi khôi phục một tenant bằng `dh-tenant-restore`, dữ liệu của chính PH-18 (yêu cầu khôi phục, bước) không bị thay vì là nhật ký vận hành của lần khôi phục; công cụ loại `tenant_restore_request`, `tenant_restore_step`, `dlq_audit`, `incident_timeline`, `cutover_log` khỏi phạm vi thay (giống nguyên tắc kiểm toán không khôi phục về quá khứ, D03-09 §8.5 bước 7).

Mã hóa: đĩa và bản sao lưu mã hóa theo D03-09; payload DLQ đã mã hóa trường nhạy cảm từ nguồn; cột không lưu địa chỉ thư, số điện thoại rõ (chỉ dạng che và băm SHA-256 có muối theo tenant). Lưu giữ theo bảng dưới, mọi hạn là tham số `18.*`.

| Bảng | Hạn giữ | Tham số | Cách dọn |
|---|---|---|---|
| `dlq_message` mở | Đến khi đóng | | Không dọn |
| `dlq_message` đã đóng, `dlq_payload_ref`, `dlq_revision` | 90 ngày rồi chỉ siêu dữ liệu tới 365 ngày | `18.dlq.retention.closed-days`, `18.dlq.retention.metadata-days` | `EXPIRED`, payload `PURGED`, xóa Garage, sau đó xóa dòng |
| `dlq_audit` | 60 tháng | `18.dlq.audit.retention-months` | DROP phân vùng |
| `ph18_batch.*` (Spring Batch) | Theo lần chạy nghiệp vụ | (cùng hạn di trú, khôi phục) | Vai chủ, xóa theo `job_instance_id` |
| `replay_job`, `replay_item`, `dlq_assignment` | Theo mục DLQ | | Xóa theo |
| `inbox_event` | 7 ngày | `18.dlq.dedup-window-days` | DELETE theo lô |
| `outbox_event` | 3 ngày sau phát | `18.outbox.retention-days` | DELETE theo lô |
| `notification_message`, `notification_delivery` | 180 ngày | `18.notify.log-retention-days` | DROP phân vùng, DELETE |
| `task_item`, `task_reminder` đã đóng | 365 ngày | `18.task.retention-days` | DELETE (vai chủ) |
| `param_value_version`, `param_change_request` | 1.825 ngày | `18.param.history-retention-days` | Vai chủ, có kiểm toán |
| `incident`, `incident_timeline`, `incident_link` | 5 năm | `18.incident.retention-years` | Vai chủ |
| `shadow_comparison_sample` | 90 ngày | `18.migration.shadow.sample-retention-days` | DROP phân vùng |
| `ops_report` và tệp | 24 tháng | `18.report.retention-months` | DELETE, xóa Garage |
| Di trú, khôi phục, sao lưu, xuất, sáp nhập | Suốt dự án, tối thiểu 5 năm sau cắt chuyển | (giả định, Q18-53) | Vai chủ |

: Hạn giữ dữ liệu của ph18_ops theo tham số 18.*

## 8. Ánh xạ thực thể, chức năng và CSDL cũ sang thiết kế mới

Chương này nối thiết kế với yêu cầu: thực thể logic EN-18 sang bảng, nhóm chức năng sang bảng, và mô hình DLQ của SRS cũ sang mô hình mới làm đầu vào cho D06-01.

### 8.1. Thực thể EN-18 sang bảng

Mỗi thực thể EN-18 ứng với đúng một bảng cùng tên; hai bảng kỹ thuật không có mã EN.

<!-- gen:en:start -->
| EN | Thực thể | Bảng | Ghi chú thiết kế |
|---|---|---|---|
| EN-18-01 | Không gian tên tham số do từng PH đăng ký khi khởi động | `param_namespace` | chỉ dòng `COMMON` |
| EN-18-02 | Lược đồ một khóa tham số (DD-14 schema) | `param_definition` | chỉ dòng `COMMON` |
| EN-18-03 | Giá trị hiện hành của một khóa theo tenant (DD-14 value, scope) | `param_value` | đọc thêm dòng `COMMON` |
| EN-18-04 | Lịch sử phiên bản giá trị tham số (DD-14 có phiên bản) | `param_value_version` | đọc thêm dòng `COMMON` |
| EN-18-05 | Đề nghị đổi tham số ★ chờ duyệt bốn mắt | `param_change_request` | đọc thêm dòng `COMMON` |
| EN-18-06 | Cờ tính năng ff.{module}.{tính-năng} theo tenant (QT-BR-03, CC-CFG-04) | `feature_flag` | đọc thêm dòng `COMMON` |
| EN-18-07 | Danh sách đích egress cho phép theo tenant (kiểu LIST<HOST>, giải Q15-10) | `egress_allowlist_entry` | Bảng theo tenant |
| EN-18-08 | Gói tham số xuất nhập giữa môi trường (DEV, TEST, STAGING, PROD) | `param_bundle` | Bảng theo tenant |
| EN-18-09 | Chỉ mục mục DLQ hợp nhất | `dlq_message` | phân vùng tháng `received_at` |
| EN-18-10 | Tham chiếu payload lớn hơn 256 KB ở Garage bucket dh-{tenant}-ops (không phải MinIO) | `dlq_payload_ref` | Bảng theo tenant |
| EN-18-11 | Bản sửa payload có kiểm soát | `dlq_revision` | Bảng theo tenant |
| EN-18-12 | Nhật ký thao tác trên DLQ | `dlq_audit` | phân vùng tháng `occurred_at`, chỉ thêm |
| EN-18-13 | Nhóm dấu hiệu lỗi | `dlq_group` | Bảng theo tenant |
| EN-18-14 | Gán người xử lý mục DLQ | `dlq_assignment` | Bảng theo tenant |
| EN-18-15 | Sổ tay xử lý theo mã lỗi ERR (nguồn tri thức loại ERROR_CODE, GUIDE cho PH-17) | `error_guide` | đọc thêm dòng `COMMON` |
| EN-18-16 | Lượt phát lại đơn hoặc loạt | `replay_job` | Bảng theo tenant |
| EN-18-17 | Một mục trong lượt phát lại | `replay_item` | Bảng theo tenant |
| EN-18-18 | Đăng ký nguồn DLQ | `dlq_source` | đọc thêm dòng `COMMON` |
| EN-18-19 | Mẫu thông báo (thư, SMS, trong ứng dụng) của các PH | `notification_template` | đọc thêm dòng `COMMON` |
| EN-18-20 | Phiên bản nội dung mẫu Mustache không logic | `notification_template_version` | đọc thêm dòng `COMMON` |
| EN-18-21 | Quy tắc thông báo theo sự kiện của các PH (hợp đồng §1.3) | `notification_rule` | đọc thêm dòng `COMMON` |
| EN-18-22 | Thông báo logic (outbox của NotificationApi, DD-13) | `notification_message` | Bảng theo tenant |
| EN-18-23 | Lần gửi theo người nhận và kênh (nhật ký gửi) | `notification_delivery` | phân vùng tháng `queued_at` |
| EN-18-24 | Tùy chọn nhận thông báo của người dùng | `user_notification_pref` | Bảng theo tenant |
| EN-18-25 | Danh sách chặn gửi do thư trả lại cứng, khiếu nại, địa chỉ sai hoặc chặn tay | `suppression_entry` | Bảng theo tenant |
| EN-18-26 | Loại việc do PH đăng ký qua TaskInboxApi | `task_type` | đọc thêm dòng `COMMON` |
| EN-18-27 | Việc trong "Việc của tôi" (FR-00-070…072) | `task_item` | Bảng theo tenant |
| EN-18-28 | Lịch nhắc việc: trước hạn, quá hạn, leo thang; thời điểm gửi và thông báo đã tạo | `task_reminder` | Bảng theo tenant |
| EN-18-29 | Lịch ngày làm việc theo tenant (WorkingCalendarApi, khóa 18.calendar.*) | `work_calendar` | đọc thêm dòng `COMMON` |
| EN-18-30 | Ngày lễ, ngày nghỉ bù, ngày làm bù của một lịch; căn cứ pháp lý (thông báo nghỉ lễ) | `calendar_holiday` | đọc thêm dòng `COMMON` |
| EN-18-31 | Cửa sổ bảo trì và cửa sổ đóng băng thay đổi | `maintenance_window` | đọc thêm dòng `COMMON` |
| EN-18-32 | Hồ sơ sự cố vận hành mở từ sự kiện (EVT-13-04, 05, DLQ vượt ngưỡng, sao lưu lỗi) hoặc tạo tay | `incident` | Bảng theo tenant |
| EN-18-33 | Mốc thời gian của sự cố | `incident_timeline` | chỉ thêm |
| EN-18-34 | Liên kết sự cố với đối tượng | `incident_link` | Bảng theo tenant |
| EN-18-35 | Đối tượng sao lưu theo D03-09 §8.2 | `backup_object` | Bảng theo tenant |
| EN-18-36 | Bản sao lưu thu từ nguồn | `backup_run` | Bảng theo tenant |
| EN-18-37 | Kết quả kiểm tra khôi phục tự động (điều kiện 0 lỗi của 3-2-1-1-0) | `restore_verification` | chỉ thêm |
| EN-18-38 | Yêu cầu khôi phục một tenant (RBK-04, D03-09 §8.5) | `tenant_restore_request` | Bảng theo tenant |
| EN-18-39 | Một trong tám bước của dh-tenant-restore (D03-09 §8.5) | `tenant_restore_step` | Bảng theo tenant |
| EN-18-40 | Lần xuất dữ liệu tenant bằng dh-tenant-export | `tenant_export_job` | Bảng theo tenant |
| EN-18-41 | Ghi nhận diễn tập DR và PITR toàn cụm (PA thực hiện ngoài ứng dụng, PH-18 chỉ ghi nhận) | `dr_drill` | Bảng theo tenant |
| EN-18-42 | Nguồn hệ cũ (IF-07) | `legacy_source` | Bảng theo tenant |
| EN-18-43 | Kế hoạch di trú một nguồn | `migration_plan` | Bảng theo tenant |
| EN-18-44 | Mục kế hoạch theo loại đối tượng | `migration_plan_item` | Bảng theo tenant |
| EN-18-45 | Lần chạy di trú | `migration_run` | Bảng theo tenant |
| EN-18-46 | Kết quả một mục kế hoạch trong lần chạy | `migration_run_item_result` | Bảng theo tenant |
| EN-18-47 | Bản ghi không chuyển được kèm lý do (FR-00-091, 092) | `migration_error_record` | Bảng theo tenant |
| EN-18-48 | Báo cáo đối chiếu số lượng và tổng kiểm tra theo loại đối tượng sau lần chạy (FR-00-092) | `migration_reconciliation` | chỉ thêm |
| EN-18-49 | Đánh dấu đối tượng đã di trú cần cấp lại thông tin xác thực ở PH đích (FR-00-093 | `credential_reissue_marker` | Bảng theo tenant |
| EN-18-50 | Nhóm dịch vụ chạy song song và cắt chuyển | `parallel_run_group` | Bảng theo tenant |
| EN-18-51 | Mẫu so sánh phản hồi cũ và mới khi APISIX nhân bản lưu lượng sang Datahub | `shadow_comparison_sample` | phân vùng tháng `sampled_at`, chỉ thêm |
| EN-18-52 | Danh sách kiểm tra cắt chuyển của nhóm dịch vụ | `cutover_checklist` | Bảng theo tenant |
| EN-18-53 | Sổ cắt chuyển | `cutover_log` | chỉ thêm |
| EN-18-54 | Báo cáo vận hành định kỳ (DLQ, sao lưu, di trú, sự cố, tham số, tổng hợp) gửi PH-16 qua sự kiện | `ops_report` | Bảng theo tenant |
| EN-18-55 | Chuyển dữ liệu một phân hệ khi sáp nhập tenant (hợp đồng PH-20, BRIEF §7) | `merge_transfer` | thêm theo BRIEF §7, hợp đồng PH-20 |

: Ánh xạ 55 thực thể EN-18 sang bảng của `ph18_ops`
<!-- gen:en:end -->

### 8.2. Chức năng sang bảng

Bảng dưới ánh xạ ở mức khối chức năng kèm FR-00 dùng chung. Từ bản 0.2, mục "FR phục vụ" của từng bảng ở chương 3 ghi số FR-18 lấy từ `tools/fr_bang.json`; tệp này lập bằng cách dò tên bảng trong khối đặc tả FR của FRS 0.2 chương 6, bổ sung tay cho mười một bảng mà khối FR không nêu tên (ĐN-CSDL18-06 đã hấp thụ).

| Khối (brief §3) | FR dùng chung | Bảng ghi chính | Bảng đọc |
|---|---|---|---|
| A · Kho tham số và cờ tính năng (khoảng 11 FR) | NFR-00-052 | `param_namespace`, `param_definition`, `param_value`, `param_value_version`, `param_change_request`, `feature_flag`, `egress_allowlist_entry`, `param_bundle` | `config_param` |
| B · Tiếp nhận DLQ (khoảng 7 FR) | | `dlq_message`, `dlq_payload_ref`, `dlq_group`, `inbox_event` | `dlq_source` |
| C · Phân loại và xử lý (khoảng 8 FR) | | `dlq_message`, `dlq_assignment`, `dlq_revision`, `dlq_audit` | `error_guide`, `dlq_group` |
| D · Phát lại, bỏ qua, lưu giữ (khoảng 8 FR) | FR-00-050…054 | `replay_job`, `replay_item`, `dlq_message`, `dlq_audit`, `outbox_event` | `config_param` |
| E · Thông báo (khoảng 8 FR) | FR-00-061, 062 | `notification_template`, `notification_template_version`, `notification_rule`, `notification_message`, `notification_delivery`, `user_notification_pref`, `suppression_entry` | `notification` |
| F · Việc của tôi và lịch (khoảng 6 FR) | FR-00-070…072 | `task_type`, `task_item`, `task_reminder`, `work_calendar`, `calendar_holiday`, `maintenance_window` | |
| G · Sự cố vận hành (khoảng 5 FR) | | `incident`, `incident_timeline`, `incident_link` | `dlq_group`, `backup_run` |
| H · Sao lưu và khôi phục (khoảng 8 FR, thêm sáp nhập) | FR-00-071 | `backup_object`, `backup_run`, `restore_verification`, `tenant_restore_request`, `tenant_restore_step`, `tenant_export_job`, `dr_drill`, `merge_transfer` | |
| I · Di trú hệ cũ và chạy song song (khoảng 10 FR) | FR-00-090…093 | `legacy_source`, `migration_plan`, `migration_plan_item`, `migration_run`, `migration_run_item_result`, `migration_error_record`, `migration_reconciliation`, `credential_reissue_marker`, `parallel_run_group`, `shadow_comparison_sample`, `cutover_checklist`, `cutover_log` | `dlq_message` |
| J · Quản trị, kiểm toán, báo cáo (khoảng 4 FR) | | `ops_report`, `outbox_event` | mọi bảng (vai readonly) |

: Ánh xạ khối chức năng PH-18 sang bảng

### 8.3. Mô hình SRS cũ của repo

SRS cũ `docs/07-srs/SRS-PH-18-ops.md` §M4 chỉ có sáu thực thể DLQ với trạng thái tiếng Việt không dấu. Bảng dưới ánh xạ sang thiết kế mới.

| Thực thể cũ | Bảng mới | Thay đổi chính |
|---|---|---|
| EN-18-01 cũ `DLQ_MESSAGE` | `dlq_message` | `dlq_id` thành `id` kèm `dlq_key` khử trùng; trạng thái `MOI`, `DANG_TRIAGE`, `CHO_PHAT_LAI`, `DANG_PHAT_LAI`, `THANH_CONG`, `THAT_BAI_PHAT_LAI`, `BO_QUA` thành `NEW`, `TRIAGED`, `REPLAY_PENDING`, `REPLAYING`, `RESOLVED`, `REPLAY_FAILED`, `DISCARDED`, thêm `POISON`, `EXPIRED`; `current_payload` bỏ, sửa payload sang `dlq_revision`; `payload_uri` MinIO sang `dlq_payload_ref` Garage; `stack_trace_hash` sang `dlq_group.signature`; UNIQUE (`topic`, `partition`, `offset`) thay bằng khử trùng `dlqKey` qua inbox vì bảng phân vùng |
| EN-18-02 cũ `DLQ_AUDIT` | `dlq_audit` | Giữ chỉ thêm, thêm `actor_kind`, `trace_id`; phân vùng tháng, giữ 60 tháng thay cho "≥ 5 năm" |
| EN-18-03 cũ `REPLAY_JOB` | `replay_job` | Trạng thái `QUEUED`, `RUNNING`, `COMPLETED`, `CANCELLED`, `ABORTED` thành bộ brief §4 có `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `PAUSED`, `PARTIAL`, `FAILED`, `REJECTED`; thêm bốn mắt |
| EN-18-04 cũ `REPLAY_ITEM` | `replay_item` | `SKIPPED_DUP` thành `SKIPPED_DUPLICATE`, thêm `PENDING`, `CANCELLED`; khóa lũy đẳng chuẩn `dlqId:revision` |
| EN-18-05 cũ `PAYLOAD_OBJECT` | `dlq_payload_ref` | `minio_uri` thành `bucket`, `object_key` ở Garage; `loai` thành `kind` |
| EN-18-06 cũ `DLQ_ALERT_RULE`, `DLQ_ALERT_EVENT` | Không có bảng | PH-18 không làm luật cảnh báo (PH-13 giữ); ngưỡng là tham số `18.dlq.threshold.depth`, sự kiện vượt ngưỡng qua outbox |

: Ánh xạ mô hình DLQ của SRS cũ sang ph18_ops

Mã EN-18-01…06 của SRS cũ trùng số với EN-18 mới nhưng khác nghĩa; tài liệu mới chỉ dùng dải EN-18-01…55 của brief, mã cũ chỉ nhắc kèm chữ "cũ".

### 8.4. Hệ cũ Viettel 2021

Hệ LGSP cũ (Bus, Tooling, Hub, APIM, Danh mục Aita) không có mô-đun vận hành và DLQ tập trung (LGC-NFR-004 để trống phần sự cố); bản tin lỗi nằm rải ở hàng đợi Pulsar và log ứng dụng, không di trú sang `dlq_message`. Bảng hệ cũ chỉ là nguồn đọc của công cụ di trú qua `legacy_source` và `migration_plan_item.source_query_ref`; ánh xạ bảng, cột hệ cũ sang PH đích thuộc tập CSDL của PH đích (PH-01, PH-02, PH-03, PH-04, PH-07, PH-10, PH-19) và D06-01.

## 9. Câu hỏi mở

Các câu hỏi dưới đây theo dải Q18-50…54 của tập CSDL; mỗi câu có giả định đang dùng để thiết kế không bị chặn.

| Mã | Câu hỏi | Giả định đang dùng | Cần ai trả lời |
|---|---|---|---|
| Q18-50 | Khử trùng `dlqKey` trên bảng phân vùng: chấp nhận cửa sổ khử trùng qua `inbox_event` (7 ngày theo FRS, `18.dlq.dedup-window-days`) hay cần bảng khóa riêng không phân vùng để khử trùng vĩnh viễn | Cửa sổ 7 ngày đủ vì nguồn chỉ gửi lại trong vài giờ (PH-04 thử lại, PH-19 tối đa 5 lần); mục chưa đóng cùng `dlq_key` vẫn được khử trùng ngoài cửa sổ bằng cách tăng `occurrence_count` | Luồng PH-04, PH-19, DBA |
| Q18-51 | Mục DLQ mở rất lâu giữ phân vùng cũ không dọn được: có cần hạn tối đa cho mục mở (tự chuyển `EXPIRED` sau N ngày có cảnh báo) không | Không có hạn; cảnh báo theo tuổi mục mở qua PH-13 | Chủ đầu tư, PO |
| Q18-52 | Kho tham số: các PH chưa nói dùng DD-14 (`06.*`, `08.*`, `09.*`, `11.*`, `13.*`, `16.*`) có đăng ký vào `param_namespace` không, và PH-07 có bỏ hẳn tiền tố cờ `07.rdm.feature.*` sang `ff.rdm.*` không | Đã khởi tạo không gian tên cho mọi PH trừ `19`; cờ PH-07 giữ dạng tham số BOOLEAN cho tới khi PH-07 đồng bộ | Luồng PH-06, 08, 09, 11, 13, 16, 07 |
| Q18-53 | Hạn giữ dữ liệu di trú, khôi phục, sao lưu, sáp nhập sau cắt chuyển | Tối thiểu 5 năm sau cắt chuyển, chưa có tham số | Chủ đầu tư, pháp chế |
| Q18-54 | `dh-tenant-restore` thay dữ liệu PH-18 của tenant: loại bảng nào khỏi phạm vi ngoài nhật ký (ví dụ `dlq_message` mở có nên giữ bản hiện tại thay vì quay về quá khứ) | Loại yêu cầu khôi phục, bước, nhật ký DLQ, mốc sự cố, sổ cắt chuyển; còn lại thay như mọi schema | Luồng PH-20, D03-09 (Q342) |

: Câu hỏi mở của D03-03-PH18

## 10. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các điểm dưới đây lệch hoặc bổ sung so với brief, FRS và tài liệu chung; người điều phối quyết định đồng bộ ở đợt cuối.

### 10.1. Đồng bộ với brief và FRS PH-18

Bảng dưới gom các giá trị và thực thể CSDL đã dùng nhưng brief §4, §5 và FRS PH-18 0.1 chưa ghi. Cả bảy mục là đồng bộ nội bộ PH-18 và đã hấp thụ ở 0.2 (FRS 0.2 §4.2, §4.5, §8.2 và tập này); cột cuối ghi chỗ hấp thụ. Ngược lại, tập này đã nhận các đề nghị nội bộ của SDD §13.6, API §11.1 và FRS §12.4 dành cho CSDL (bảng 10.1b).

| Mã | Nội dung đề nghị | Lý do |
|---|---|---|
| ĐN-CSDL18-01 | FRS §4.2 bổ sung EN-18-55 `merge_transfer` (sáp nhập tenant, hợp đồng PH-20) | Brief §7 đã thêm, cần có trong FRS và nhóm FR khối H. Đã hấp thụ ở 0.2: FRS §4.2 có EN-18-55, khối H có FR-18-057 |
| ĐN-CSDL18-02 | FRS dùng trạng thái của bảng ngoài brief §4: đề nghị tham số `PENDING_APPROVAL`, `APPROVED`, `REJECTED`, `CANCELLED`, `EXPIRED`; bản sửa payload `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `REJECTED`, `CANCELLED`; mục phát lại `PENDING`, `SENT`, `SUCCEEDED`, `FAILED`, `SKIPPED_DUPLICATE`, `CANCELLED`; gói tham số `DRAFT`, `VALIDATED`, `PENDING_APPROVAL`, `APPLIED`, `FAILED`, `REJECTED`; cửa sổ bảo trì `PLANNED`, `ACTIVE`, `COMPLETED`, `CANCELLED`; bước khôi phục `PENDING`, `RUNNING`, `SUCCEEDED`, `FAILED`, `SKIPPED`, `ROLLED_BACK`; sổ tay lỗi `DRAFT`, `PUBLISHED`, `RETIRED`; bản sao lưu `RUNNING`, `SUCCEEDED`, `PARTIAL`, `FAILED`, `EXPIRED`; nguồn hệ cũ `DRAFT`, `VERIFIED`, `DISABLED`; mục danh sách cắt chuyển `PENDING`, `PASSED`, `FAILED`, `WAIVED`; dấu cấp lại `PENDING`, `NOTIFIED`, `REISSUED`, `WAIVED` | Brief §4 chưa có máy trạng thái cho các đối tượng này. Đã hấp thụ ở 0.2: FRS §4.5 bảng trạng thái đối tượng phụ |
| ĐN-CSDL18-03 | Lần xuất tenant, kết quả mục di trú, lần sáp nhập, báo cáo vận hành dùng bộ trạng thái lần chạy (`QUEUED`, `RUNNING`, `SUCCEEDED`, `SUCCEEDED_WITH_ERRORS`, `FAILED`, `CANCELLED`) của brief §4 | Thống nhất một bộ cho mọi tác vụ nền. Đã hấp thụ ở 0.2: FRS §4.5 |
| ĐN-CSDL18-04 | Thông báo logic (`notification_message.status`) dùng chung bộ trạng thái lần gửi brief §4, là trạng thái tổng hợp | Tránh thêm bộ trạng thái mới. Đã hấp thụ ở 0.2: FRS §4.5 |
| ĐN-CSDL18-05 | Tên khóa `18.*` ở mục 5 do CSDL đặt theo brief; FRS §8.2 chốt tên chính thức, CSDL đổi dữ liệu khởi tạo theo | FRS chưa có §8.2 khi viết. Đã hấp thụ ở 0.2: mục 5 sinh từ FRS §8.2 |
| ĐN-CSDL18-06 | FRS cấp số FR-18 rồi điền `tools/fr_bang.json` (bảng sang danh sách FR) để sinh lại mục "FR phục vụ" | Ánh xạ FR ở mục 8.2 mới ở mức khối. Đã hấp thụ ở 0.2: `tools/fr_bang.json`, mục 8.2 |
| ĐN-CSDL18-07 | Lớp lỗi `error_class` thêm giá trị mặc định `UNKNOWN` khi chưa phân loại; header ngữ cảnh thiếu ghi ở `missing_context` | Theo brief §3 B, C. Đã hấp thụ ở 0.2: FRS `ErrorClass` có `UNKNOWN`, `missingFields` ứng `missing_context` |

: Đề nghị đồng bộ với brief và FRS PH-18

Bảng 10.1b ghi các đề nghị nội bộ mà tập khác của PH-18 gửi cho CSDL và cách bản 0.2 đã hấp thụ.

| Nguồn đề nghị | Nội dung | Đã hấp thụ ở 0.2 |
|---|---|---|
| FRS §12.4, SDD §13.5 điểm 4, MH LC-09 | Mười một tên khóa `18.*` lệch FRS, khóa `18.dlq.discard.reason-min-chars` thừa | Mục 5 sinh từ FRS §8.2 (61 khóa); không còn tên cũ |
| SDD điểm 1, API §11.1 số 3 | `dlq_source.replay_port` có giá trị riêng | Cột `replay_mode` ∈ `KAFKA_TOPIC`, `HTTP_PORT`, `EVENT_LAYER`, `NONE`; CHECK `EVENT_LAYER` khi và chỉ khi `FEDERATED` |
| SDD điểm 2, BR-18-015 | Thiếu bộ đếm lần gặp | `dlq_message.occurrence_count`, `last_seen_at`, cập nhật được, ngoài `tg_immutable` |
| SDD điểm 3 | Payload không phải JSON | Ghi chú cột `payload_location`: luôn ở Garage dạng nhị phân |
| SDD điểm 5, ADR-181 | Cửa sổ khử trùng 30 ngày | Theo FRS `18.dlq.dedup-window-days` = 7, miền 1…30 |
| SDD điểm 9 | Kho lần chạy Spring Batch | Schema `ph18_batch` (mục 4.4) |
| SDD §13.6 CSDL (7) | `ph18_worker` cập nhật nhịp sống và điểm dừng | Cột `heartbeat_at`, `checkpoint` ở `migration_run`, `tenant_restore_request`, `tenant_export_job`, `merge_transfer` (vai worker đã có quyền ghi) |
| API §11.1 số 2 | Lược đồ khóa: `type`, `default`, `secure`, `group` | `secure` đổi tên; `value_type`, `default_value`, `display_group` giữ vì `type`, `default`, `group` là từ khóa SQL, ánh xạ ghi ở chú thích cột; enum kiểu theo `ParamType` (`INT`, `BOOL`, `LIST<HOST>`…) |
| API §11.1 số 4 đến 9 | Cờ tính năng, sổ tay ERR, tốc độ phát lại, sự cố, bản ghi lỗi di trú, loại xác thực, phương pháp kiểm tra khôi phục, loại diễn tập, mục đích egress và xuất, môi trường | `owner_ph`, `owner_user`, `retire_by`; `causes`, `steps`, `replayable`, `default_class`, `links`; `rate_per_second`; `has_personal_data`, `category` theo `IncidentCategory`; `RULE_ADDED`, `WONT_MIGRATE`; `CredentialKind`, `VerifyMethod`, `DrillKind` (kết quả `PASSED_WITH_ISSUES`), `EgressPurpose` (cột `used_by`, `reason`), `ExportPurpose`, định dạng `PG_COPY`, `PG_DUMP`; cửa sổ bảo trì nhận `TEST` |
| API §11.1 số 10 | `targetPh` dạng `PH-nn`, thiếu PH-04, PH-07 | Mọi cột mã phân hệ theo mẫu `^PH-[0-9]{2}$`; `credential_reissue_marker.target_module` gồm PH-01, 02, 03, 04, 07, 10, 19; mã nguồn DLQ viết thường như `SourceCode` |
| TC ĐN-TC-08, FRS §4.5 | Mục phát lại bị loại khi duyệt | `replay_item.status` thêm `SKIPPED` |

: Đề nghị nội bộ PH-18 gửi CSDL và cách hấp thụ ở 0.2

### 10.2. Đồng bộ tài liệu chung và phân hệ khác

Bảng dưới gom các điểm cần tài liệu chung hoặc phân hệ khác ghi lại để khớp với tên bảng, khung nhìn và mã của `ph18_ops`.

| Mã | Tài liệu | Nội dung đề nghị |
|---|---|---|
| ĐN-CSDL18-08 | D02-07 DD-14 | Ghi DD-14 hiện thực bằng bốn bảng `param_definition`, `param_value`, `param_value_version`, `param_change_request` và khung nhìn `ph18_ops.config_param` giữ tên cũ; `scope` lấy giá trị `PLATFORM`, `TENANT` như DD-14; `schema` là `json_schema` của lược đồ khóa |
| ĐN-CSDL18-09 | D02-07 DD-13 | Ghi DD-13 hiện thực bằng `notification_message` và `notification_delivery`, khung nhìn `ph18_ops.notification` giữ tên cũ; `channels_sent` là mảng kênh |
| ĐN-CSDL18-10 | D02-07 DD-14 ví dụ khóa | Ví dụ `00.session.idle-timeout-minutes` dùng không gian tên `00`; CSDL đã khởi tạo `00` do PH-00 (nền tảng chung) sở hữu |
| ĐN-CSDL18-11 | FRS PH-01 | Tiền tố `onboarding.*` được giữ làm không gian tên riêng; khóa có chữ hoa kiểu `review.slaWorkingDays` được nhận (regex khóa cho phép chữ hoa sau dấu chấm) |
| ĐN-CSDL18-12 | FRS PH-07 | Cờ `07.rdm.feature.*` không qua bảng `feature_flag` (sai mẫu `ff.{module}.{tính-năng}`); đề nghị PH-07 đổi sang `ff.rdm.*` hoặc giữ như tham số BOOLEAN (Q18-52) |
| ĐN-CSDL18-13 | D03-09 §8.2 | Bảng đối tượng sao lưu dùng mã `object_code` ở mục 5 để PH-18 thu trạng thái; đề nghị D03-09 ghi mã này |
| ĐN-CSDL18-14 | D03-09 §8.5, D03-10 | `dh-tenant-restore` loại năm bảng nhật ký của `ph18_ops` khỏi phạm vi thay (Q18-54) |
| ĐN-CSDL18-15 | API PH-20 | Thân `POST /api/ops/v1/merge-transfers` ánh xạ `mergePlanId` sang `merge_plan_id varchar(64)`, `mappingRef` sang `mapping_ref`; PH-20 xác nhận kiểu mã kế hoạch |

: Đề nghị đồng bộ tài liệu chung và phân hệ khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.3 | 2026-11-27 | Luồng CSDL PH-18 | Đồng bộ chéo cuối: `merge_transfer` thêm `transfer_mode`, `delta_since` cho lượt bù cuối, chỉ mục duy nhất theo chế độ |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ nội bộ PH-18 theo FRS 0.2: 61 khóa `18.*` sinh từ FRS §8.2, `replay_mode`, bộ đếm lần gặp, enum và tên cột theo FRS và OpenAPI, mã phân hệ `PH-nn`, cửa sổ khử trùng 7 ngày, schema `ph18_batch` cho Spring Batch, FR phục vụ theo số FR-18; kiểm cô lập 525 khối PASS, changelog 15 tệp; đánh dấu mục đề nghị nội bộ đã hấp thụ |
| 0.1 | 2026-11-27 | Luồng CSDL PH-18 | Bản đầu: 57 bảng (EN-18-01…55 và outbox, inbox), RLS FORCE, bốn vai, bốn bảng phân vùng tháng, dữ liệu `COMMON`, khung nhìn DD-13, DD-14, kiểm cô lập 520 khối PASS, changelog Liquibase 14 tệp |

: Lịch sử phiên bản D03-03-PH18
