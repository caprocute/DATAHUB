---
ma_tai_lieu: D03-03-PH17
ten: Thiết kế cơ sở dữ liệu phân hệ PH-17 Trợ lý AI và quản trị AI
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, DBA, ATTT, hội đồng thẩm định
phan_he: PH-17
mo_ta: Thiết kế 50 bảng của schema ph17_assist trên cụm pg-core có pgvector cho chính sách bật tắt trợ lý theo tenant, sổ mô hình và tuyến egress, kho tri thức và vector, hội thoại đã che, công cụ chỉ đọc, chặn an toàn, đánh giá và ca đỏ, phiếu truy cập nhật ký và gói bằng chứng, kèm DDL chạy thử, kiểm cô lập tenant và changelog Liquibase.
tai_lieu_lien_quan: D02-03-PH17 FRS; D03-02-PH17 SDD; D03-04-PH17 API; D03-10 Thiết kế đa tenant; D05-02-PH17 Test case
---

# D03-03-PH17 · Thiết kế CSDL Trợ lý AI và quản trị AI

## Tóm tắt cho hội đồng thẩm định

Schema `ph17_assist` trên cụm `pg-core` có 50 bảng, hiện thực 48 thực thể EN-17-01…48 của [D02-03-PH17](../../02-yeu-cau/frs/D02-03-PH17-frs-tro-ly-ai.md) §4.2 trong đó EN-17-40…48 là chín thực thể bổ sung ở FRS 0.2 (mục 8.1). Hai bảng (`invocation_log`, `model_health_probe`) phân vùng theo tháng, tổng cộng 24 phân vùng tạo sẵn. DDL chạy sạch trên PostgreSQL 16.15, bài kiểm cô lập tenant đạt 182 khối PASS, đối chiếu Phụ lục A của FRS không lệch.

Năm quyết định thiết kế hội đồng cần lưu ý.

1. **Tắt mặc định, bật phải qua đề nghị bốn mắt.** Tenant mới nạp bằng `p_seed_tenant` ở trạng thái `DISABLED`, ba năng lực tắt, mô hình ngoài tắt. Chuyển trạng thái chỉ đi qua `policy_change` có người đề nghị khác người duyệt; nút tắt khẩn ghi `kill_switch_record` và không cần bốn mắt (SEC-49, BR-17-001, 004).
2. **Cách ly tenant bằng `FORCE ROW LEVEL SECURITY` trên mọi bảng, thêm lớp cách ly theo người dùng cho hội thoại.** Dữ liệu dùng chung do PA khai báo (nhà cung cấp, mô hình, ca đỏ, nguồn tri thức chung) mang `tenant_id = 'COMMON'`, tenant chỉ đọc, chỉ vai `ph17_platform` ghi. Hội thoại và tin nhắn chỉ chủ đọc được; SO hoặc AUDITOR đọc khi có phiếu truy cập ≤ 60 phút, có lý do ≥ 20 ký tự, tự hết hiệu lực (BR-17-033, 074, 075).
3. **Không có chỗ cho bí mật và nội dung chưa che.** Không có cột `secret`, `api_key`, `password`; nhà cung cấp chỉ có `secret_ref` dạng đường dẫn OpenBao. Nội dung hội thoại chỉ ở `content_masked`, `CHECK` chặn chuỗi giống bí mật; hộp thư đi chặn khóa `content`, `prompt`, `answer`, `embedding` (BR-17-022, 073).
4. **Chỉ PUBLIC và INTERNAL vào chỉ mục, xóa lan truyền ngay trong giao dịch.** Trigger chặn đoạn tri thức mức khác hoặc không khớp mức tài liệu; đổi mức hoặc thu hồi nguồn thì xóa vật lý đoạn và ghi `knowledge_deletion` (BR-17-026, 029).
5. **Cổng phát hành đặt ở CSDL.** Phiên bản mô hình chỉ thành `APPROVED`, chỉ dẫn hệ thống chỉ thành `ACTIVE` khi lượt đánh giá chuẩn đạt ngưỡng, lượt ca đỏ chặn 100% và bộ ca đỏ có tối thiểu 50 ca đang hoạt động; người duyệt khác người đề nghị và người soạn (BR-17-015, 064, 066 đến 068).

Điểm cần quyết định: cột vector. Production dùng `vector(1024)` kèm chỉ mục HNSW (ADR-170); CI chưa có extension nên giữ `real[]`. Tập này làm cả hai bằng một changeset có điều kiện (mục 1.4) và đề nghị D02-07 ghi nhận (mục 12.2).

: Tóm tắt thiết kế CSDL PH-17

| Chỉ số | Giá trị |
|---|---|
| Bảng gốc, phân vùng | 50 bảng, 24 phân vùng tháng (2 bảng) |
| Ràng buộc | 350 `CHECK`, 29 khóa ngoại kèm `tenant_id`, 104 trigger, 226 chính sách RLS |
| Chỉ mục | 181 (gồm HNSW cosine và GIN `tsvector` cho truy hồi lai) |
| Vai trò | 6 (`ph17_owner`, `ph17_app`, `ph17_platform`, `ph17_infer`, `ph17_job`, `ph17_readonly`) |
| Changelog Liquibase | 12 tệp trong `ph17/liquibase/changes` |
| Kiểm cô lập | 182 khối PASS trên PostgreSQL 16.15 |
| Câu hỏi mở của tập | 7 (Q17-50…56) |

: Con số chính của tập CSDL PH-17

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả CSDL của PH-17 ở mức đủ để DBA dựng schema, kỹ sư `dh-assist` (package `vn.datahub.assist`) viết tầng truy cập, kiểm thử viên viết ca cô lập tenant, bất biến và cổng phát hành. Phạm vi gồm 50 bảng của schema `ph17_assist`, hàm, thủ tục, trigger, changelog Liquibase và bài kiểm cô lập. Ngoài phạm vi: trọng số mô hình, nội dung nguồn tri thức gốc (nằm ở phân hệ chủ), cấu hình APISIX (PH-03).

Nguồn chuẩn là [`ph17/ddl/ph17_assist.sql`](ph17/ddl/ph17_assist.sql), sinh bằng `ph17/tools/sinh_ddl.py` từ danh mục bảng và Phụ lục A của FRS (nên enum không lệch FRS). Chương 2, 3, 8 sinh từ DDL bằng `gen_erd.py`, `gen_tables_md.py`, `them_dac_ta_bang.py`, `gen_anh_xa.py`.

### 0.2. Thuật ngữ và chữ viết tắt

| Thuật ngữ | Giải thích |
|---|---|
| RAG, truy hồi lai | Truy hồi đoạn tri thức rồi đưa vào prompt; lai là kết hợp tìm vector (cosine) và từ khóa không dấu (`tsvector`), hợp nhất bằng RRF (ADR-171) |
| pgvector, HNSW | Extension vector của PostgreSQL; chỉ mục đồ thị gần đúng theo cosine |
| COMMON | Giá trị `tenant_id` của dòng dùng chung do PA khai báo; mọi tenant đọc, chỉ vai nền tảng ghi |
| Cổng phát hành | Điều kiện đánh giá chuẩn, ca đỏ, số ca tối thiểu mà trigger kiểm trước khi duyệt phiên bản (BR-17-066 đến 068) |
| Ca đỏ | Ca tấn công kiểm thử (tiêm lệnh, lộ dữ liệu) mà hệ thống phải chặn 100% |
| Phiếu truy cập nhật ký | `log_access_grant`: quyền đọc có thời hạn, có lý do, mở khóa hội thoại cho SO, AUDITOR |
| `secret_ref` | Đường dẫn OpenBao tới bí mật nhà cung cấp, không phải bí mật |
| Bốn mắt | Người đề nghị khác người duyệt, ép bằng `CHECK` và trigger |
| DU | Đơn vị triển khai (`dh-assist` là một DU, Control plane và data plane `/assist/v1`) |

: Thuật ngữ và chữ viết tắt của tập CSDL PH-17

### 0.3. Tài liệu tham chiếu

| Tài liệu | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH17 FRS §4.2, §5, §7, §8.2, §9, Phụ lục A | EN-17-01…48, FR-17-001…062, BR-17, 49 khóa `17.*`, ERR, EVT-17-01…28, enum |
| D03-04-PH17 API | Trường JSON camelCase ứng với cột snake_case |
| D02-07 (quy ước dữ liệu) §5 | Bảy cột chuẩn, DD-11 outbox, DD-12 đối tượng tệp |
| D03-10 Thiết kế đa tenant | Mẫu RLS, khóa ngoại kèm `tenant_id` |
| ADR-003, 034, 042; ADR-170 đến 174 (đề xuất ở FRS Phụ lục B) | RLS, DR, outbox, pgvector, truy hồi lai, công cụ chỉ đọc, cổng phát hành, xóa lan truyền |
| `docs/07-srs/SRS-PH-17-ai.md` §4 | Mô hình dữ liệu SRS cũ (mục 8.3) |

: Tài liệu tham chiếu của tập CSDL PH-17

Căn cứ pháp lý của các ràng buộc: Luật An ninh mạng 116/2025 (dữ liệu và nhật ký trong nước, chặn đường ra ngoài), Luật Bảo vệ dữ liệu cá nhân 91/2025 và Nghị định 356/2025 (che trước khi xử lý, không lưu nội dung chưa che), Luật Dữ liệu 60/2024 (chỉ lập chỉ mục dữ liệu Công khai và Nội bộ), Nghị định 331/2026 và TCVN 14423:2026 (nhật ký, quản trị truy cập). Luật Công nghiệp công nghệ số 2025 là căn cứ định hướng cho nhãn nội dung AI, chờ đối chiếu (Q17-03).

### 0.4. Người đọc

DBA, kỹ sư `dh-assist`, ATTT, kiểm thử viên; hội đồng thẩm định đọc Tóm tắt, chương 1 và chương 9.

### 0.5. Cấu trúc tài liệu

Chương 1 chiến lược lưu trữ, 2 sơ đồ, 3 đặc tả bảng, 4 DDL, 5 dữ liệu khởi tạo, 6 kho ngoài, 7 sao lưu và lưu giữ, 8 ánh xạ, 9 câu hỏi mở, 10 đề nghị đồng bộ, rồi lịch sử phiên bản.

## 1. Chiến lược lưu trữ

### 1.1. Schema, vai trò và kết nối

Schema `ph17_assist` do `ph17_owner` (NOLOGIN) sở hữu, nằm trên cụm `pg-core` (PostgreSQL 18 có pgvector 0.8, ADR-170) cùng các schema khác, không có khóa ngoại sang schema khác. Năm vai ứng dụng đều `NOBYPASSRLS`:

| Vai | Dùng bởi | Quyền |
|---|---|---|
| `ph17_app` | Control plane `/api/assist/v1` (kết nối giả định `dh_assist_app`) | DML trên bảng nghiệp vụ; không `DELETE` đối tượng nghiệp vụ; không `UPDATE`, `DELETE` nhật ký, vết, xác nhận |
| `ph17_platform` | Thao tác của PA trên dòng `COMMON` | `SELECT`, `INSERT`, `UPDATE` bảng dùng chung; xóa đoạn tri thức, tài liệu, kết quả đánh giá của nguồn chung |
| `ph17_infer` | Data plane `/assist/v1` (3 bản sao, mTLS) | Đọc cấu hình, ghi `invocation_log`, `quota_usage`, `suggestion`, `outbox_event`; không đọc hội thoại, đoạn tri thức |
| `ph17_job` | Tác vụ lưu giữ, thành viên `ph17_app` | Xóa hội thoại và dòng con hết hạn, dọn bộ đếm, thăm dò |
| `ph17_readonly` | Báo cáo, hỗ trợ | `SELECT` toàn schema; cột nhạy cảm của `feedback`, `knowledge_chunk` chỉ cấp cột danh sách |

: Vai trò của schema ph17_assist

### 1.2. Cách ly tenant

Mọi bảng có `tenant_id varchar(16)` và bật `FORCE ROW LEVEL SECURITY` qua ba thủ tục trong schema, bài kiểm quét lược đồ khẳng định không bảng nào thiếu:

- `p_enable_rls`: bốn chính sách (đọc, chèn, sửa, xóa) chỉ dòng có `tenant_id = current_setting('app.tenant_id')`. Dùng cho dữ liệu riêng của tenant (24 bảng).
- `p_enable_rls_common`: thêm quyền đọc dòng `COMMON` cho mọi tenant và chính sách ghi `COMMON` riêng cho `ph17_platform` (20 bảng: nhà cung cấp, mô hình, phiên bản, tuyến, ca đỏ, bộ đánh giá, nguồn và đoạn tri thức dùng chung, quy tắc lọc, bản chụp tham số chung).
- `p_enable_rls_user`: thêm điều kiện `user_id = current_setting('app.user_id')` cho `conversation`, `message`, `citation`, `tool_call`, `explanation`, `feedback`; mở thêm khi có `log_access_grant` còn hiệu lực (hàm `fn_log_grant_ok`), và cho `ph17_job` xóa dòng hết hạn.

Biến phiên `app.tenant_id` và `app.user_id` đặt đầu mỗi giao dịch từ ngữ cảnh xác thực, không từ tham số bên gọi (FR-00-010). Khóa ngoại luôn kèm `tenant_id`; đích có `UNIQUE (tenant_id, id)`. Mẫu `tenant_id` là `^T[0-9]{2}$`, riêng bảng dùng chung là `^(T[0-9]{2}|COMMON)$`.

### 1.3. Quy ước bảng và ngoại lệ

Theo D02-07 mọi bảng có `id uuid` (UUIDv7 sinh ở ứng dụng), `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (trigger `tg_touch`, khóa lạc quan, ETag). Trạng thái và loại là `varchar` kèm `CHECK` liệt kê đúng giá trị Phụ lục A của FRS; chuyển trạng thái do trigger `tg_<bảng>_fsm_<cột>` ép theo máy trạng thái của FRS. Đơn vị tiền là `numeric`, thời điểm là `timestamptz`.

| Bảng, cột | Ngoại lệ | Lý do |
|---|---|---|
| `invocation_log`, `model_health_probe` | Khóa chính `(id, cột thời gian)`, không `version`, không `updated_by` | Phân vùng tháng, chỉ thêm |
| `outbox_event`, `inbox_event` | Khóa chính `event_id` hoặc `(consumer, event_id)`, không `version` | Bảng thông điệp (DD-11) |
| `knowledge_chunk.embedding` | `real[]` trên CI, `vector(1024)` khi có pgvector | CI dùng `postgres:16` không có extension (mục 1.4) |
| `model_provider.secret_ref` | Đường dẫn OpenBao, kiểm mẫu `openbao://kv/...` | Không lưu bí mật (SEC-49) |
| `eval_set`, `eval_case`, `redteam_case`, `model`, `model_provider` | `tenant_id` có thể là `COMMON` | Dữ liệu dùng chung do PA khai báo |

: Quy ước bảng và ngoại lệ

### 1.4. Cột vector có điều kiện

ADR-170 chọn pgvector trên `pg-core`, vector 1024 chiều. Môi trường CI dùng PostgreSQL 16 không cài extension, nên:

- `17-0001` (changeset `ph17-0001-schema`) chạy `CREATE EXTENSION vector` chỉ khi `pg_available_extensions` có nó.
- `17-0040` tạo `knowledge_chunk.embedding` kiểu `real[]` kèm `CHECK` độ dài 1024 khi chưa có extension.
- `17-0045-pgvector.sql` (changeset `ph17-0350-pgvector`) khi có extension thì đổi cột sang `vector(1024)` và tạo `ix_knowledge_chunk_embedding` bằng `hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64)`; không có thì ghi NOTICE và bỏ qua.
- Bài kiểm số 182 khẳng định kiểu cột khớp việc có extension hay không.

Truy hồi từ khóa dùng `content_tsv` (cột sinh `to_tsvector('simple', content_norm)`, chỉ mục GIN) trên văn bản đã bỏ dấu ở ứng dụng, thay cho `unaccent` (Q17-18 và Q17-53).

### 1.5. Quy tắc nghiệp vụ chốt ở CSDL

Các quy tắc sau do CSDL tự bảo đảm bằng ràng buộc, chỉ mục duy nhất, trigger hoặc quyền, để dù ứng dụng sai vẫn không ghi được dữ liệu vi phạm.

| Ràng buộc | Quy tắc | BR, FR |
|---|---|---|
| `tg_tenant_policy_fsm_assist_state`, `ck_policy_change_four_eyes`, `uq_policy_change_pending` | Trạng thái trợ lý chỉ `DISABLED`, `ENABLED`, `KILLED` theo máy trạng thái; đề nghị đổi cần người duyệt khác người đề nghị; một đề nghị chờ mỗi loại | BR-17-001, 002; FR-17-001 |
| `ck_policy_change_reason`, `ck_policy_change_enable` | Bật cần số quyết định và lý do, đề nghị không có số quyết định bị chặn | BR-17-001; FR-17-001 |
| `ck_kill_switch_record_scope`, `uq_kill_switch_active` | Phạm vi tenant hoặc nền tảng; mỗi phạm vi một bản ghi đang hiệu lực; gỡ cần hai người | BR-17-003; FR-17-006 |
| `ck_provider_grant_period`, `uq_provider_grant_active`, `tg_provider_grant_immutable` | Danh sách trắng gắn đề nghị EXTERNAL_ON có thật; mỗi nhà cung cấp một dòng còn hiệu lực | BR-17-004, 007; FR-17-003 |
| `tg_tenant_model_rules`, `uq_tenant_model_default` | Mô hình ngoài chỉ bật khi tenant cho phép, nhà cung cấp trong danh sách trắng, có cam kết, nhà cung cấp `ACTIVE` và phiên bản `APPROVED`; một mô hình mặc định mỗi loại; dự phòng cùng loại, không từ nội bộ ra ngoài | BR-17-004, 017, 018; FR-17-007, 009 |
| `ck_model_route_host`, `tg_model_route_fsm_status` | Đích egress là tên miền hoặc tên dịch vụ, không IP trần; tuyến chưa `SYNCED` thì chưa gọi được | BR-17-012, 019; FR-17-010, 011 |
| `tg_model_version_gate`, `ck_model_version_four_eyes` | `APPROVED` cần đánh giá chuẩn đạt ngưỡng, ca đỏ không lọt, đủ 50 ca; người duyệt khác người đề nghị | BR-17-015, 066 đến 068; FR-17-008, 050, 051 |
| `tg_prompt_version_gate`, `uq_prompt_version_active`, `ck_prompt_version_content` | Chỉ dẫn `ACTIVE` qua cổng như trên; một phiên bản `ACTIVE` mỗi mẫu; nội dung không chứa địa chỉ IP hay bí mật | BR-17-064, 065; FR-17-049 |
| `ck_redteam_case_expected`, `tg_redteam_case_immutable` | Hành vi mong đợi luôn `BLOCK`, bất biến; ca nghỉ hưu phải có lý do | BR-17-067; FR-17-051 |
| `ck_eval_run_passed_eval`, `ck_eval_run_passed_redteam`, `uq_eval_run_running` | Đánh giá chuẩn ≥ 30 ca; lượt ca đỏ ≥ 50 ca, 0 ca lọt, tỷ lệ 100; một lượt chạy mỗi đối tượng | BR-17-066, 067; FR-17-050 |
| `tg_knowledge_chunk_gate`, `ck_knowledge_chunk_class`, `ck_knowledge_chunk_acl` | Đoạn chỉ PUBLIC, INTERNAL và khớp mức tài liệu; `acl.visibility` là `TENANT`, `ORG` hoặc `ROLE` | BR-17-026, 027; FR-17-016, 018 |
| `tg_knowledge_document_purge`, `knowledge_deletion` (chỉ thêm) | Đổi mức, xóa tài liệu hoặc thu hồi nguồn thì xóa vật lý đoạn trong cùng giao dịch và ghi nhật ký | BR-17-029; FR-17-019 |
| `tg_knowledge_document_fsm_index_status`, `ck_knowledge_document_failed`, `ck_knowledge_document_upload_gate` | Máy trạng thái chỉ mục; `FAILED` sau ba lần thử; tài liệu tải lên chỉ vào chỉ mục sau khi người khác duyệt | BR-17-028, 030; FR-17-020, 021 |
| `ck_conversation_retention`, `ck_conversation_ctx`, `tg_conversation_fsm_state` | Hạn lưu ≥ 90 ngày; ngữ cảnh màn hình chỉ có route, mã đối tượng, mã lỗi; xóa bởi người dùng thì chỉ đổi trạng thái | BR-17-032, 039; FR-17-022, 027 |
| `ck_message_masked`, `ck_message_no_secret`, `uq_message_dedup`, `tg_message_immutable` | Chỉ lưu nội dung đã che; chặn chuỗi giống bí mật; chống gửi trùng; tin nhắn bất biến | BR-17-073, 087; FR-17-022, 041 |
| `ck_citation_route`, `ck_tool_call_depth`, `ck_tool_call_act`, `ck_tool_call_no_token`, `ck_tool_definition_read_only` | Trích dẫn chỉ route nội bộ; chuỗi công cụ ≤ 5; chủ thể hành động `dh-assist`; không lưu token; công cụ luôn chỉ đọc, phạm vi `:read` | BR-17-037, 056, 057, 061; FR-17-042, 043, 046 |
| `ck_guardrail_rule_secret_blocks`, `ck_guardrail_rule_inject_blocks` | Quy tắc bí mật, tiêm lệnh luôn `BLOCK`; quy tắc dựng sẵn không đổi cờ | BR-17-062, 063; FR-17-044, 045 |
| `ck_log_access_grant_role`, `_reason`, `_ttl`, `_scope`, `tg_log_access_grant_fsm_state` | Chỉ SO, AUDITOR; lý do ≥ 20 ký tự; hiệu lực ≤ 60 phút; khoảng xem ≤ 92 ngày; thu hồi là khóa lại ngay | BR-17-074, 075; FR-17-055, 056 |
| `tg_invocation_log_append_only`, `ck_invocation_log_counts` | Nhật ký gọi mô hình chỉ thêm, không cột nội dung | BR-17-022, 024; FR-17-013 |
| `ck_outbox_event_no_content`, `ck_outbox_event_prefix` | Sự kiện không mang khóa nội dung; tiền tố chủ đề trùng tenant | BR-17-022, 073; DD-11 |
| `ck_tenant_setting_key`, `_bounds`, `_retention_floor`, `_redteam_floor`, `tg_tenant_setting_immutable` | Chỉ 49 khóa `17.*`; giá trị trong sàn và trần; hạn lưu nhật ký ≥ 90; tỷ lệ ca đỏ phải chặn 100 | BR-17-078; FR-17-059 |
| `ck_compliance_export_no_content`, `ck_ai_system_record_measures` | Gói bằng chứng không nội dung hội thoại; hồ sơ hệ thống AI có biện pháp và người chịu trách nhiệm | BR-17-079, 080; FR-17-054, 057 |

: Quy tắc nghiệp vụ chốt ở CSDL

Quy tắc cần dữ liệu ngoài schema hoặc tính toán (số quyết định bật có thật, mức phân loại do PH-09 trả, mô hình đang có sức khỏe `UP` khi định tuyến, chữ ký gói bằng chứng) kiểm ở dịch vụ, ghi ở D03-02-PH17.

### 1.6. Ước lượng khối lượng (giả định)

Giả định theo GĐ-17-04 (tỉnh vừa): 2.000 người dùng, 150.000 lời gọi mô hình mỗi ngày, 60.000 tin nhắn mỗi ngày, 200.000 đoạn tri thức. Bảng lớn nhất là `invocation_log` (13 tháng, khoảng 60 triệu dòng, 12 GB), kế đó `message` (90 ngày, khoảng 5,4 triệu dòng, 11 GB) và `knowledge_chunk` (200.000 đoạn, mỗi đoạn một vector 4 KB cộng văn bản, khoảng 1,2 GB, chỉ mục HNSW thêm khoảng 0,5 GB). Phần còn lại dưới 1 GB. Con số là giả định, đo lại ở đợt 3 (Q17-01).

## 2. Sơ đồ thực thể – quan hệ

Sơ đồ chia sáu nhóm để đọc được trên trang A4; khóa ngoại đều kèm `tenant_id` nên không vẽ cột. Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic (mục 1.3). Sơ đồ sinh từ DDL bằng [`gen_erd.py`](ph17/tools/gen_erd.py).

<!-- gen:erd:start -->
Nhóm nền tảng, tệp, tham số và hộp thư gồm 4 bảng (`file_object`, `tenant_setting`, `outbox_event`, `inbox_event`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic.

```{.mermaid caption="ERD nhóm nền tảng, tệp, tham số và hộp thư"}
erDiagram
  file_object {
    uuid id PK
    varchar tenant_id
  }
  tenant_setting {
    uuid id PK
    varchar tenant_id
  }
  outbox_event {
    uuid id PK
    varchar tenant_id
  }
  inbox_event {
    uuid id PK
    varchar tenant_id
  }
```

Nhóm chính sách, điều khoản và hạn mức gồm 7 bảng (`ai_notice`, `notice_acceptance`, `policy_change`, `tenant_policy`, `capability_policy`, `quota_usage`, `kill_switch_record`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic.

```{.mermaid caption="ERD nhóm chính sách, điều khoản và hạn mức"}
erDiagram
  ai_notice ||--o{ notice_acceptance : "notice_id"
  policy_change |o--o{ tenant_policy : "enabled_change_id"
  policy_change |o--o{ tenant_policy : "external_change_id"
  ai_notice |o--o{ tenant_policy : "current_notice_id"
  policy_change ||..o{ kill_switch_record : "logic, change_id"
  capability_policy {
    uuid id PK
    varchar tenant_id
  }
  quota_usage {
    uuid id PK
    varchar tenant_id
  }
```

Nhóm nhà cung cấp, mô hình và tuyến gồm 11 bảng (`model_provider`, `provider_commitment`, `model`, `model_version`, `model_route`, `route_sync_run`, `tenant_model`, `provider_grant`, `invocation_log`, `model_health_probe`, `model_breaker`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic.

```{.mermaid caption="ERD nhóm nhà cung cấp, mô hình và tuyến"}
erDiagram
  file_object ||--o{ provider_commitment : "file_id"
  model ||--o{ model_version : "model_id"
  model_version ||--o{ model_route : "version_id"
  policy_change ||--o{ provider_grant : "change_id"
  model_version ||..o{ invocation_log : "logic, model_version_id"
  message ||..o{ invocation_log : "logic, message_id"
  model_version ||..o{ model_health_probe : "logic, version_id"
  model_route ||..o{ model_breaker : "logic, route_id"
  model_provider {
    uuid id PK
    varchar tenant_id
  }
  route_sync_run {
    uuid id PK
    varchar tenant_id
  }
  tenant_model {
    uuid id PK
    varchar tenant_id
  }
```

Nhóm kho tri thức và lập chỉ mục gồm 5 bảng (`knowledge_source`, `knowledge_document`, `knowledge_chunk`, `index_job`, `knowledge_deletion`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic.

```{.mermaid caption="ERD nhóm kho tri thức và lập chỉ mục"}
erDiagram
  knowledge_source ||--o{ knowledge_document : "source_id"
  file_object |o--o{ knowledge_document : "file_id"
  knowledge_document ||--o{ knowledge_chunk : "document_id"
  knowledge_source ||--o{ knowledge_chunk : "source_id"
  knowledge_source |o--o{ index_job : "source_id"
  knowledge_deletion {
    uuid id PK
    varchar tenant_id
  }
```

Nhóm hội thoại, công cụ và gợi ý gồm 8 bảng (`conversation`, `message`, `citation`, `tool_definition`, `tool_call`, `suggestion`, `explanation`, `suggested_question`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic.

```{.mermaid caption="ERD nhóm hội thoại, công cụ và gợi ý"}
erDiagram
  conversation ||--o{ message : "conversation_id"
  message ||--o{ citation : "message_id"
  message ||--o{ tool_call : "message_id"
  model_version ||..o{ message : "logic, model_version_id"
  knowledge_chunk ||..o{ citation : "logic, chunk_id"
  tool_definition ||..o{ tool_call : "logic, tool_code"
  suggestion {
    uuid id PK
    varchar tenant_id
  }
  explanation {
    uuid id PK
    varchar tenant_id
  }
  suggested_question {
    uuid id PK
    varchar tenant_id
  }
```

Nhóm chặn an toàn, prompt, đánh giá và quản trị gồm 15 bảng (`guardrail_rule`, `link_allowlist`, `prompt_template`, `prompt_version`, `eval_set`, `eval_dataset_link`, `eval_case`, `eval_run`, `eval_result`, `redteam_case`, `feedback`, `quality_metric`, `ai_system_record`, `log_access_grant`, `compliance_export`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic.

```{.mermaid caption="ERD nhóm chặn an toàn, prompt, đánh giá và quản trị"}
erDiagram
  prompt_template ||--o{ prompt_version : "template_id"
  eval_set ||--o{ eval_dataset_link : "eval_set_id"
  eval_set ||--o{ eval_case : "eval_set_id"
  eval_dataset_link |o--o{ eval_case : "dataset_link_id"
  eval_set |o--o{ eval_run : "eval_set_id"
  eval_run ||--o{ eval_result : "run_id"
  file_object |o--o{ compliance_export : "file_id"
  prompt_version ||..o{ eval_run : "logic, subject_id"
  model_version ||..o{ eval_run : "logic, subject_id"
  message ||..o{ feedback : "logic, message_id"
  message ||..o{ log_access_grant : "logic, conversation_id"
  guardrail_rule {
    uuid id PK
    varchar tenant_id
  }
  link_allowlist {
    uuid id PK
    varchar tenant_id
  }
  redteam_case {
    uuid id PK
    varchar tenant_id
  }
  quality_metric {
    uuid id PK
    varchar tenant_id
  }
  ai_system_record {
    uuid id PK
    varchar tenant_id
  }
```

<!-- gen:erd:end -->

## 3. Đặc tả bảng

Mỗi bảng có khối đặc tả 10 mục (mục đích, FR phục vụ, khóa chính, duy nhất, khóa ngoại, CHECK, chỉ mục, cách ly tenant, phân vùng và bất biến, ghi chú) trích trực tiếp từ DDL. Cột nào có ghi chú hoặc enum thì thành dòng bảng, cột còn lại gộp một dòng.

<!-- gen:tables:start -->
### 3.1. `file_object`

::: dac-ta
**Mục đích.** EN-17-39 Tham chiếu đối tượng tệp (DD-12) cho tài liệu tải lên (FR-17-020), hồ sơ cam kết nhà cung cấp (FR-17-003, 007) và gói bằng chứng tuân thủ (FR-17-057).

**FR phục vụ.** FR-17-003, 007, 020, 057; EN-17-39.

**Khóa chính.** `id`.

**Duy nhất.** `uq_file_object_key` (bucket, object_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_file_object_` + size, sha, scan, class, purpose, ctype.

**Chỉ mục.** `ix_file_object_expires`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `bucket`, `object_key`, `sha256`, `size_bytes`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `data_class` | `varchar(16), mặc định 'INTERNAL'` | Chỉ PUBLIC hoặc INTERNAL: PH-17 không nhận tệp mức cao hơn (BR-17-026, 030). |
| `purpose` | `varchar(24)` | UPLOAD_SOURCE tài liệu tải lên, COMMITMENT hồ sơ cam kết nhà cung cấp, COMPLIANCE_PACK gói bằng chứng, USAGE_REPORT báo cáo sử dụng. Enum `FilePurpose`. |

: Cột của bảng `file_object`

Cột khác: `bucket` v(64); `object_key` text; `file_name` v(255); `content_type` v(127) {}; `size_bytes` bigint; `sha256` char(64); `scan_status` v(16) ScanStatus; `expires_at` tstz.

### 3.2. `tenant_setting`

::: dac-ta
**Mục đích.** EN-17-40 Bản chụp tham số 17.* của tenant (FRS 8.2, FR-17-059, BR-17-078).

**FR phục vụ.** FR-17-059; EN-17-40.

**Khóa chính.** `id`.

**Duy nhất.** `uq_tenant_setting_key` (tenant_id, setting_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_tenant_setting_` + key, bounds, retention_floor, redteam_floor.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `setting_key`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `synced_at` | `timestamptz, NULL` | Lần đồng bộ cuối từ PH-18 DD-14. |

: Cột của bảng `tenant_setting`

Cột khác: `setting_key` v(48) {}; `value` jsonb; `floor_value` jsonb; `ceiling_value` jsonb; `four_eyes` bool.

### 3.3. `outbox_event`

::: dac-ta
**Mục đích.** EN-17-39 Outbox (DD-11, ADR-042) cho EVT-17-01…28. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL.

**FR phục vụ.** Hạ tầng dùng chung; EN-17-39.

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_event_` + prefix, topic, trace, no_content.

**Chỉ mục.** `ix_outbox_event_occurred`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Không.

**Ghi chú.** Debezium Outbox Event Router đọc WAL và phát lên Kafka; ghi cùng giao dịch với thay đổi (ADR-042, SAD 7.3). Không có `version`.
:::

Cột: `event_id` uuid; `tenant_id` v(16); `event_type` v(128); `topic` v(249); `aggregate_type` v(64); `aggregate_id` v(255); `partition_key` v(255); `payload` jsonb; `trace_id` char(32); `occurred_at` tstz.

### 3.4. `inbox_event`

::: dac-ta
**Mục đích.** EN-17-41 Inbox chống xử lý trùng cho sự kiện PH-17 tiêu thụ (at-least-once): catalog.api.*, rdm.catalog.*, integration.flow.*, event.publication.*, privacy.classification.changed, privacy.contract-level.changed, privacy.dataset.status-changed, gateway.snapshot.* (FRS 9.3b).

**FR phục vụ.** Hạ tầng dùng chung; EN-17-41.

**Khóa chính.** (tenant_id, consumer, event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_inbox_event_` + consumer, prefix.

**Chỉ mục.** `ix_inbox_event_received`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Không.

**Ghi chú.** Khử trùng sự kiện nhận theo (`consumer`, `event_id`); tiêu thụ lũy đẳng. Không có `version`.
:::

Cột: `tenant_id` v(16); `consumer` v(64); `event_id` v(255); `source_topic` v(249); `event_type` v(255); `received_at` tstz; `processed_at` tstz; `outcome` v(2000).

### 3.5. `ai_notice`

::: dac-ta
**Mục đích.** EN-17-05 Phiên bản điều khoản và thông báo minh bạch dùng AI (FR-17-005, BR-17-007).

**FR phục vụ.** FR-17-005; EN-17-05.

**Khóa chính.** `id`.

**Duy nhất.** `uq_ai_notice_version` (tenant_id, version_no), `uq_ai_notice_current` (tenant_id) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_ai_notice_` + version, status, published, retired.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Trigger: `tg_ai_notice_frozen`, `tg_ai_notice_fsm_status`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(12), mặc định 'DRAFT'` | DRAFT, PUBLISHED, RETIRED (NoticeStatus, Phụ lục A). Enum `NoticeStatus`. |

: Cột của bảng `ai_notice`

Cột khác: `version_no` int; `title` v(255); `body_text` text; `locale` v(8); `published_at` tstz; `published_by` v(64); `retired_at` tstz.

### 3.6. `notice_acceptance`

::: dac-ta
**Mục đích.** EN-17-06 Người dùng đã xác nhận phiên bản điều khoản nào, lúc nào (FR-17-005, BR-17-007). Chỉ thêm.

**FR phục vụ.** FR-17-005; EN-17-06.

**Khóa chính.** `id`.

**Duy nhất.** `uq_notice_acceptance_user` (tenant_id, notice_id, user_id).

**Khóa ngoại.** (tenant_id, notice_id) → `ai_notice`.

**Ràng buộc CHECK.** Chỉ `ck_notice_acceptance_tenant`.

**Chỉ mục.** `ix_notice_acceptance_user`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Trigger: `tg_notice_acceptance_append_only`.

**Ghi chú.** ETag là `version`.
:::

Cột: `notice_id` uuid; `user_id` v(64); `accepted_at` tstz.

### 3.7. `policy_change`

::: dac-ta
**Mục đích.** EN-17-02 Đề nghị đổi chính sách cần bốn mắt (FR-17-001, 003, 006, 059; BR-17-002, 004, 008, 010): ENABLE, EXTERNAL_ON, RESUME, SENSITIVE_PARAM.

**FR phục vụ.** FR-17-001, 003, 006, 059; EN-17-02.

**Khóa chính.** `id`.

**Duy nhất.** `uq_policy_change_pending` (tenant_id, change_type) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_policy_change_` + type, state, four_eyes, decided, reject, enable, reason, payload.

**Chỉ mục.** `ix_policy_change_state`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `change_type`, `requested_by`, `reason`; Trigger: `tg_policy_change_fsm_state`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `payload` | `jsonb, mặc định '{}'` | Giá trị đề nghị (ví dụ khóa 17.* và giá trị mới); không bí mật. |
| `decision_no` | `varchar(64), NULL` | Số quyết định của lãnh đạo tỉnh (bắt buộc khi ENABLE, RESUME). |

: Cột của bảng `policy_change`

Cột khác: `change_type` v(16) PolicyChangeType; `state` v(12) PolicyChangeState; `reason` v(2000); `requested_by` v(64); `requested_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `expires_at` tstz.

### 3.8. `tenant_policy`

::: dac-ta
**Mục đích.** EN-17-01 Chính sách của tenant, một dòng mỗi tenant (FR-17-001, 003, 006; BR-17-001, 002, 004, 008). assist_state DISABLED mặc định; ENABLED cần số quyết định; KILLED chỉ gỡ về DISABLED (máy trạng thái FRS 4.7).

**FR phục vụ.** FR-17-001, 003, 006; EN-17-01.

**Khóa chính.** `id`.

**Duy nhất.** `uq_tenant_policy_tenant` (tenant_id).

**Khóa ngoại.** (tenant_id, enabled_change_id) → `policy_change`, (tenant_id, external_change_id) → `policy_change`, (tenant_id, current_notice_id) → `ai_notice`.

**Ràng buộc CHECK.** `ck_tenant_policy_` + state, enabled, killed, external.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Trigger: `tg_tenant_policy_fsm_assist_state`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `enabled_change_id` | `uuid, NULL` | Đề nghị ENABLE đã duyệt bốn mắt (BR-17-002). |
| `external_change_id` | `uuid, NULL` | Đề nghị EXTERNAL_ON đã duyệt bốn mắt (BR-17-004). |

: Cột của bảng `tenant_policy`

Cột khác: `assist_state` v(12) TenantAssistState; `enable_decision_no` v(64); `enable_reason` v(2000); `enabled_at` tstz; `enabled_by` v(64); `disabled_at` tstz; `external_allowed` bool; `current_notice_id` uuid; `killed_at` tstz; `killed_by` v(64); `kill_reason` v(2000).

### 3.9. `capability_policy`

::: dac-ta
**Mục đích.** EN-17-03 Năng lực bật cho từng nhóm vai trò (FR-17-002, BR-17-003): SEARCH, MAPPING, EXPLAIN.

**FR phục vụ.** FR-17-002; EN-17-03.

**Khóa chính.** `id`.

**Duy nhất.** `uq_capability_policy` (tenant_id, capability, role_group).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_capability_policy_` + capability, role_group.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `capability` v(16) Capability; `role_group` v(32); `enabled` bool.

### 3.10. `quota_usage`

::: dac-ta
**Mục đích.** EN-17-07 Số lượt và token đã dùng theo ngày (FR-17-004, 058; BR-17-005, 024): theo người dùng, theo tenant, theo DU gọi data plane. dh-assist cộng dồn trước và sau lời gọi mô hình; vượt hạn mức thì 429 không gọi mô hình.

**FR phục vụ.** FR-17-004, 058; EN-17-07.

**Khóa chính.** `id`.

**Duy nhất.** `uq_quota_usage_bucket` (tenant_id, usage_date, scope_kind, subject_ref, capability, COALESCE(model_version_id, '00000000-0000-0000-0000-000000000000'::uuid)).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_quota_usage_` + scope, counts, capability.

**Chỉ mục.** `ix_quota_usage_date`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `subject_ref` | `varchar(64)` | Mã người dùng (sub), mã tenant hoặc mã DU gọi; không tên người. |
| `est_cost` | `numeric(14,2), mặc định 0` | Ước tính token nhân đơn giá phiên bản (BR-17-024), không dùng thanh toán. |

: Cột của bảng `quota_usage`

Cột khác: `usage_date` date; `scope_kind` v(8) QuotaScope; `capability` v(24); `model_version_id` uuid; `turns` int; `blocked_turns` int; `tokens_in` bigint; `tokens_out` bigint.

### 3.11. `kill_switch_record`

::: dac-ta
**Mục đích.** EN-17-08 Một lần tắt khẩn (FR-17-006, BR-17-008): phạm vi TENANT hoặc PLATFORM (tenant_id COMMON), lý do, người kích hoạt.

**FR phục vụ.** FR-17-006; EN-17-08.

**Khóa chính.** `id`.

**Duy nhất.** `uq_kill_switch_active` (tenant_id, scope) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_kill_switch_record_` + scope, scope_tenant, reason, release_req, released, propagation.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `scope`, `reason`, `activated_by`, `activated_at`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `target_tenants` | `varchar(16)[], NULL` | Nhóm tenant của lần tắt nền tảng; NULL là toàn bộ. |
| `propagated_at` | `timestamptz, NULL` | Thời điểm mọi thành phần xác nhận đã chặn; chỉ tiêu ≤ 60 giây (NFR-17-004). |

: Cột của bảng `kill_switch_record`

Cột khác: `scope` v(8) KillScope; `reason` v(2000); `activated_by` v(64); `activated_at` tstz; `release_requested_by` v(64); `release_requested_at` tstz; `release_reason` v(2000); `released_by` v(64); `released_at` tstz.

### 3.12. `model_provider`

::: dac-ta
**Mục đích.** EN-17-09 Nhà cung cấp mô hình dùng chung do PA khai báo, tenant_id COMMON (FR-17-007; BR-17-011, 012, 013).

**FR phục vụ.** FR-17-007; EN-17-09.

**Khóa chính.** `id`.

**Duy nhất.** `uq_model_provider_code` (tenant_id, provider_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_model_provider_` + common, code, kind, status, protocol, secret_ref, external_https, external_region, external_active, suspended, retired.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `provider_code`, `provider_kind`; Trigger: `tg_model_provider_fsm_status`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `data_region` | `varchar(8), mặc định 'VN'` | Vùng lưu dữ liệu của nhà cung cấp; EXTERNAL phải là VN (SEC-49, Luật An ninh mạng 116/2025). |
| `secret_ref` | `varchar(255), NULL` | Tham chiếu OpenBao dạng openbao://kv/... ; không lưu giá trị bí mật (BR-17-011). |
| `commitment_valid_to` | `date, NULL` | Ngày hết hạn của cam kết hiện hành (bản sao từ provider_commitment); hết hạn thì tự SUSPENDED (BR-17-013). |

: Cột của bảng `model_provider`

Cột khác: `provider_code` v(32); `name` v(255); `provider_kind` v(8) ProviderKind; `protocol` v(24) ProtocolKind; `endpoint_url` v(512); `status` v(12) ProviderStatus; `suspended_reason` v(2000); `retired_at` tstz.

### 3.13. `provider_commitment`

::: dac-ta
**Mục đích.** EN-17-42 (FR-17-003, 007; BR-17-013).

**FR phục vụ.** FR-17-003, 007; EN-17-42.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (provider_id) → `model_provider`, (tenant_id, file_id) → `file_object`.

**Ràng buộc CHECK.** `ck_provider_commitment_` + pledge, period, state.

**Chỉ mục.** `ix_provider_commitment_provider`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `provider_id`, `doc_no`, `file_id`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `state` | `varchar(12), mặc định 'ACTIVE'` | ACTIVE, EXPIRED, SUPERSEDED (CommitmentState, Phụ lục A). Enum `CommitmentState`. |

: Cột của bảng `provider_commitment`

Cột khác: `provider_id` uuid; `doc_no` v(64); `doc_date` date; `valid_from` date; `valid_to` date; `domestic_storage` bool; `no_training` bool; `file_id` uuid.

### 3.14. `model`

::: dac-ta
**Mục đích.** EN-17-10 Mô hình: CHAT, EMBEDDING, RERANK; phạm vi COMMON (PA khai báo, tenant_id COMMON) hoặc TENANT (FR-17-008).

**FR phục vụ.** FR-17-008; EN-17-10.

**Khóa chính.** `id`.

**Duy nhất.** `uq_model_code` (tenant_id, model_code).

**Khóa ngoại.** (provider_id) → `model_provider`.

**Ràng buộc CHECK.** `ck_model_` + code, kind, scope, scope_tenant, caps, kind_caps.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `model_code`, `model_kind`, `scope`, `provider_id`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `capabilities` | `varchar(24)[]` | SEARCH, MAPPING, EXPLAIN (Capability) và CLASSIFY_TEXT, EXTRACT_FIELDS, SUGGEST_STEP (data plane, BR-17-082), EMBED, RERANK (ModelCapability, Phụ lục A). |

: Cột của bảng `model`

Cột khác: `model_code` v(64); `name` v(255); `model_kind` v(12) ModelKind; `scope` v(8) ModelScope; `provider_id` uuid; `description` v(2000); `retired_at` tstz.

### 3.15. `model_version`

::: dac-ta
**Mục đích.** EN-17-11 Phiên bản mô hình, đối tượng được duyệt (FR-17-008, 009; BR-14, 15, 16, 24).

**FR phục vụ.** FR-17-008, 009; EN-17-11.

**Khóa chính.** `id`.

**Duy nhất.** `uq_model_version_no` (tenant_id, model_id, version_no).

**Khóa ngoại.** (tenant_id, model_id) → `model`.

**Ràng buộc CHECK.** `ck_model_version_` + version, status, context, dim, price, params, four_eyes, approved, reject, retired, submitted.

**Chỉ mục.** `ix_model_version_status`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `model_id`, `version_no`; Trigger: `tg_model_version_frozen`, `tg_model_version_fsm_status`, `tg_model_version_gate`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `embedding_dim` | `smallint, NULL` | Số chiều vector của mô hình nhúng (1024 theo mặc định); chỉ EMBEDDING có giá trị. |
| `eval_run_id` | `uuid, NULL` | Lượt đánh giá chuẩn đạt ngưỡng 17.eval.min-score (BR-17-015). |
| `redteam_run_id` | `uuid, NULL` | Lượt bộ ca đỏ không lọt ca nào (BR-17-067). |

: Cột của bảng `model_version`

Cột khác: `model_id` uuid; `version_no` int; `version_label` v(64); `upstream_name` v(128); `status` v(12) ModelVersionStatus; `context_tokens` int; `price_in_per_1k` numeric(12,4); `price_out_per_1k` numeric(12,4); `gen_params` jsonb; `submitted_by` v(64); `submitted_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `approved_at` tstz; `retired_at` tstz.

### 3.16. `model_route`

::: dac-ta
**Mục đích.** EN-17-12 Tuyến từ phiên bản mô hình tới đích egress APISIX ai-proxy (FR-17-010, 011; BR-17-018, 019, 020). priority 0 là tuyến chính, lớn hơn là dự phòng.

**FR phục vụ.** FR-17-010, 011; EN-17-12.

**Khóa chính.** `id`.

**Duy nhất.** `uq_model_route_priority` (tenant_id, version_id, priority), `uq_model_route_ref` (tenant_id, route_ref).

**Khóa ngoại.** (tenant_id, version_id) → `model_version`.

**Ràng buộc CHECK.** `ck_model_route_` + status, priority, host, synced.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Trigger: `tg_model_route_fsm_status`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `egress_host` | `varchar(255)` | Tên miền trong nước đã khai báo (EXTERNAL) hoặc tên dịch vụ trong cụm (INTERNAL); không IP trần (BR-17-012). |
| `drift` | `boolean, mặc định false` | Cấu hình thực ở APISIX lệch cấu hình mong muốn (BR-17-020). |

: Cột của bảng `model_route`

Cột khác: `version_id` uuid; `route_ref` v(128); `priority` smallint; `status` v(10) RouteStatus; `snapshot_ref` v(128); `last_synced_at` tstz; `last_error_code` v(16).

### 3.17. `route_sync_run`

::: dac-ta
**Mục đích.** EN-17-13 Một lượt đồng bộ cấu hình tuyến sang PH-03 và kết quả (FR-17-011): phát EVT-17-08, nhận EVT-17-09 (gateway.snapshot.published hoặc rejected).

**FR phục vụ.** FR-17-011; EN-17-13.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_route_sync_run_` + status, count, finished.

**Chỉ mục.** `ix_route_sync_run_started`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Trigger: `tg_route_sync_run_fsm_status`.

**Ghi chú.** ETag là `version`.
:::

Cột: `requested_by` v(64); `status` v(10) RouteStatus; `route_count` int; `request_event_id` uuid; `result_event_id` uuid; `snapshot_ref` v(128); `started_at` tstz; `finished_at` tstz; `error_code` v(16).

### 3.18. `tenant_model`

::: dac-ta
**Mục đích.** EN-17-43 (FR-17-010; BR-17-004, 017, 018). Phiên bản mô hình tenant đã bật, mô hình mặc định và dự phòng theo loại.

**FR phục vụ.** FR-17-010; EN-17-43.

**Khóa chính.** `id`.

**Duy nhất.** `uq_tenant_model_version` (tenant_id, version_id), `uq_tenant_model_default` (tenant_id, model_kind) có điều kiện.

**Khóa ngoại.** (version_id) → `model_version`, (fallback_version_id) → `model_version`.

**Ràng buộc CHECK.** `ck_tenant_model_` + kind, default, fallback, enabled.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Trigger: `tg_tenant_model_rules`.

**Ghi chú.** ETag là `version`.
:::

Cột: `version_id` uuid; `model_kind` v(12) ModelKind; `enabled` bool; `is_default` bool; `fallback_version_id` uuid; `enabled_by` v(64); `enabled_at` tstz; `disabled_at` tstz.

### 3.19. `provider_grant`

::: dac-ta
**Mục đích.** EN-17-04 Nhà cung cấp ngoài trong danh sách trắng của tenant (FR-17-003; BR-17-004).

**FR phục vụ.** FR-17-003; EN-17-04.

**Khóa chính.** `id`.

**Duy nhất.** `uq_provider_grant_active` (tenant_id, provider_id) có điều kiện.

**Khóa ngoại.** (provider_id) → `model_provider`, (tenant_id, change_id) → `policy_change`.

**Ràng buộc CHECK.** `ck_provider_grant_` + period, revoked.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `provider_id`, `change_id`, `granted_by`.

**Ghi chú.** ETag là `version`.
:::

Cột: `provider_id` uuid; `change_id` uuid; `granted_by` v(64); `effective_from` date; `effective_to` date; `revoked_at` tstz; `revoked_by` v(64).

### 3.20. `invocation_log`

::: dac-ta
**Mục đích.** EN-17-14 Vết một lời gọi mô hình (FR-17-013; BR-17-022, 024, NFR-17-026): mô hình, phiên bản, năng lực, token vào ra, độ trễ, kết quả, người gọi.

**FR phục vụ.** FR-17-013; EN-17-14.

**Khóa chính.** (id, occurred_at).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_invocation_log_` + caller, result, counts, trace, fallback, error.

**Chỉ mục.** `ix_invocation_log_model`, `ix_invocation_log_caller`, `ix_invocation_log_message`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Phân vùng tháng theo `occurred_at`; Trigger: `tg_invocation_log_append_only`.

**Ghi chú.** Không có `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `caller_ref` | `varchar(64)` | Mã người dùng (sub) hoặc mã DU gọi data plane. |
| `message_id` | `uuid, NULL` | Tham chiếu logic tới message (không khóa ngoại: nhật ký tồn tại lâu hơn hội thoại). |

: Cột của bảng `invocation_log`

Cột khác: `id` uuid; `tenant_id` v(16); `occurred_at` tstz; `capability` v(24); `model_version_id` uuid; `route_id` uuid; `caller_kind` v(4) CallerKind; `request_ref` v(64); `tokens_in` int; `tokens_out` int; `latency_ms` int; `first_token_ms` int; `result` v(10) InvocationResult; `error_code` v(16); `fallback_from_id` uuid; `est_cost` numeric(14,4); `trace_id` char(32), phân vùng `RANGE (occurred_at)`.

### 3.21. `model_health_probe`

::: dac-ta
**Mục đích.** EN-17-15 Kết quả thăm dò sức khỏe mô hình (FR-17-014; BR-17-023): ba lần lỗi liên tiếp thì DOWN và mở cầu dao, hai lần đạt liên tiếp mới trở lại.

**FR phục vụ.** FR-17-014; EN-17-15.

**Khóa chính.** (id, probed_at).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_model_health_probe_` + kind, state, counts, down.

**Chỉ mục.** `ix_model_health_probe_version`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Phân vùng tháng theo `probed_at`; Trigger: `tg_model_health_probe_append_only`.

**Ghi chú.** Không có `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `state` | `varchar(14)` | HEALTHY, DEGRADED, DOWN, BREAKER_OPEN theo Phụ lục A; FRS 9.3 và BR-17-023 còn dùng UP (Đề nghị đồng bộ). Enum `HealthState`. |

: Cột của bảng `model_health_probe`

Cột khác: `id` uuid; `tenant_id` v(16); `probed_at` tstz; `version_id` uuid; `probe_kind` v(10) ProbeKind; `latency_ms` int; `consecutive_failures` smallint; `consecutive_ok` smallint; `error_code` v(16), phân vùng `RANGE (probed_at)`.

### 3.22. `model_breaker`

::: dac-ta
**Mục đích.** EN-17-44 (FR-17-012, 014; BR-17-021).

**FR phục vụ.** FR-17-012, 014; EN-17-44.

**Khóa chính.** `id`.

**Duy nhất.** `uq_model_breaker_version` (tenant_id, version_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_model_breaker_` + state, rate, open.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `version_id` uuid; `breaker_state` v(10) BreakerState; `error_rate` numeric(5,2); `opened_at` tstz; `retry_at` tstz; `reset_by` v(64).

### 3.23. `knowledge_source`

::: dac-ta
**Mục đích.** EN-17-16 Nguồn tri thức (FR-17-015, 021; BR-17-025, 031): API_SPEC, RDM_CATALOG, FLOW, TOPIC, ERROR_CODE, GUIDE, UPLOAD.

**FR phục vụ.** FR-17-015, 021; EN-17-16.

**Khóa chính.** `id`.

**Duy nhất.** `uq_knowledge_source_code` (tenant_id, source_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_knowledge_source_` + code, type, state, paused, retired, config.

**Chỉ mục.** `ix_knowledge_source_type`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `source_code`, `source_type`; Trigger: `tg_knowledge_source_fsm_source_state`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `source_type` | `varchar(16)` | Phụ lục A dùng ERROR_CODE và GUIDE; BR-17-025 viết ERR_CATALOG và OPS_GUIDE (Đề nghị đồng bộ). Enum `SourceType`. |
| `source_state` | `varchar(8), mặc định 'ACTIVE'` | ACTIVE, PAUSED, RETIRED (FRS 4.4; SourceState, Phụ lục A). Enum `SourceState`. |

: Cột của bảng `knowledge_source`

Cột khác: `source_code` v(64); `name` v(255); `owner_org_id` v(63); `schedule_cron` v(64); `config` jsonb; `last_indexed_at` tstz; `paused_at` tstz; `retired_at` tstz.

### 3.24. `knowledge_document`

::: dac-ta
**Mục đích.** EN-17-17 Tài liệu hoặc đối tượng trong nguồn tri thức (FR-17-016…021; BR-17-026, 028, 029, 030). index_status theo máy trạng thái FRS 4.4; chỉ INDEXED khi mức PUBLIC hoặc INTERNAL; SKIPPED_CLASS, DELETED xóa hết đoạn ngay trong giao dịch.

**FR phục vụ.** FR-17-016, 017, 018, 019, 020, 021; EN-17-17.

**Khóa chính.** `id`.

**Duy nhất.** `uq_knowledge_document_ref` (tenant_id, source_id, external_ref).

**Khóa ngoại.** (tenant_id, source_id) → `knowledge_source`, (tenant_id, file_id) → `file_object`.

**Ràng buộc CHECK.** `ck_knowledge_document_` + class, status, indexed_class, skipped, failed, chunks, hash, deleted, delete_reason, upload, declared, upload_fields, upload_gate, approved, rejected.

**Chỉ mục.** `ix_knowledge_document_source`, `ix_knowledge_document_skipped`, `ix_knowledge_document_upload`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `source_id`, `external_ref`; Trigger: `tg_knowledge_document_fsm_index_status`, `tg_knowledge_document_fsm_upload_status`, `tg_knowledge_document_purge`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `class_level` | `varchar(16), NULL` | Mức phân loại do PH-09 trả (DD-08); NULL là chưa xác định, xử lý như không được lập chỉ mục (đóng an toàn). Enum `ClassLevel`. |
| `delete_reason` | `varchar(16), NULL` | Lý do xóa vật lý đoạn; DB tự chép sang knowledge_deletion. Enum `DeletionReason`. |
| `upload_status` | `varchar(20), NULL` | UPLOADED, PENDING_APPROVAL, APPROVED, REJECTED, STOPPED theo Phụ lục A; FRS 4.4 còn nêu DRAFT, RETIRED (Đề nghị đồng bộ). Enum `UploadStatus`. |

: Cột của bảng `knowledge_document`

Cột khác: `source_id` uuid; `external_ref` v(512); `title` v(500); `class_checked_at` tstz; `index_status` v(16) DocumentIndexStatus; `content_hash` char(64); `chunk_count` int; `skip_reason` v(255); `failure_count` smallint; `last_error_code` v(16); `indexed_at` tstz; `owner_org_id` v(63); `file_id` uuid; `declared_class` v(16) {PUBLIC, INTERNAL}; `uploaded_by` v(64); `approved_by` v(64); `approved_at` tstz; `reject_reason` v(2000).

### 3.25. `knowledge_chunk`

::: dac-ta
**Mục đích.** EN-17-18 Đoạn tri thức đã nhúng (FR-17-018, 019, 023, 024; BR-17-016, 026, 027, 034).

**FR phục vụ.** FR-17-018, 019, 023, 024; EN-17-18.

**Khóa chính.** `id`.

**Duy nhất.** `uq_knowledge_chunk_no` (tenant_id, document_id, chunk_no, embed_version_id).

**Khóa ngoại.** (tenant_id, document_id) → `knowledge_document` xóa theo, (tenant_id, source_id) → `knowledge_source`, (embed_version_id) → `model_version`.

**Ràng buộc CHECK.** `ck_knowledge_chunk_` + class, no, hash, acl, content.

**Chỉ mục.** `ix_knowledge_chunk_source`, `ix_knowledge_chunk_embed`, `ix_knowledge_chunk_hash`, `ix_knowledge_chunk_tsv`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `document_id`, `embed_version_id`, `content_hash`; Trigger: `tg_knowledge_chunk_gate`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `content_norm` | `text` | Nội dung không dấu, chữ thường, dùng cho tìm từ khóa (tsvector cấu hình simple). |
| `embedding` | `real[]` | vector(1024) khi có pgvector (đổi kiểu và chỉ mục HNSW vector_cosine_ops ở bước 17-0031-pgvector); real[] chỉ để CI trên postgres:16 không có pgvector. |
| `embed_version_id` | `uuid` | Phiên bản mô hình nhúng; không trộn vector của hai phiên bản trong một truy hồi (BR-17-016). |
| `acl` | `jsonb` | Phạm vi quyền đọc: visibility TENANT, ORG (orgIds) hoặc ROLE (roles); truy hồi lọc theo acl rồi xác minh quyền người hỏi (BR-17-035). |

: Cột của bảng `knowledge_chunk`

Cột khác: `source_id` uuid; `document_id` uuid; `chunk_no` int; `content` text; `content_tsv` tsvector GENERATED ALWAYS AS (to_tsvector('simple', content_norm)) STORED; `class_level` v(16) {PUBLIC, INTERNAL}; `content_hash` char(64); `token_count` int; `object_ref` v(512).

### 3.26. `index_job`

::: dac-ta
**Mục đích.** EN-17-19 Lượt lập chỉ mục: theo sự kiện (EVENT), toàn bộ (FULL), xóa (DELETE) (FR-17-017, 021; BR-17-028).

**FR phục vụ.** FR-17-017, 021; EN-17-19.

**Khóa chính.** `id`.

**Duy nhất.** `uq_index_job_full_running` (tenant_id, source_id) có điều kiện.

**Khóa ngoại.** (tenant_id, source_id) → `knowledge_source`.

**Ràng buộc CHECK.** `ck_index_job_` + kind, status, attempt, counts, finished, failed, scope.

**Chỉ mục.** `ix_index_job_source`, `ix_index_job_status`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Trigger: `tg_index_job_fsm_status`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `trigger_ref` | `varchar(128)` | Mã sự kiện nguồn (event_id), CRON hoặc mã người yêu cầu. |

: Cột của bảng `index_job`

Cột khác: `source_id` uuid; `document_id` uuid; `job_kind` v(8) IndexJobKind; `status` v(8) IndexJobStatus; `attempt` smallint; `docs_added` int; `docs_deleted` int; `docs_skipped` int; `docs_failed` int; `chunks_added` int; `chunks_deleted` int; `started_at` tstz; `finished_at` tstz; `error_code` v(16).

### 3.27. `knowledge_deletion`

::: dac-ta
**Mục đích.** EN-17-45 (FR-17-019; BR-17-029).

**FR phục vụ.** FR-17-019; EN-17-45.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_knowledge_deletion_` + reason, count, time.

**Chỉ mục.** `ix_knowledge_deletion_doc`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Trigger: `tg_knowledge_deletion_append_only`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `document_id` | `uuid, NULL` | Tham chiếu logic (tài liệu có thể đã bị xóa vật lý). |

: Cột của bảng `knowledge_deletion`

Cột khác: `source_id` uuid; `reason` v(16) DeletionReason; `chunks_deleted` int; `trigger_ref` v(128); `requested_at` tstz; `completed_at` tstz; `latency_ms` int.

### 3.28. `conversation`

::: dac-ta
**Mục đích.** EN-17-20 Hội thoại của một người dùng (FR-17-022, 027; BR-17-032, 033, 039).

**FR phục vụ.** FR-17-022, 027; EN-17-20.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_conversation_` + state, ctx, retention, deleted, count.

**Chỉ mục.** `ix_conversation_user`, `ix_conversation_expires`.

**Cách ly tenant.** FORCE RLS theo `tenant_id` và `user_id`: chỉ chủ dòng đọc; SO, AUDITOR đọc khi có phiếu truy cập nhật ký còn hiệu lực (`log_access_grant`); vai `ph17_job` xóa dòng hết hạn.

**Phân vùng, bất biến.** Bất biến: `user_id`; Trigger: `tg_conversation_fsm_state`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `screen_context` | `jsonb, mặc định '{}'` | Chỉ khóa route, objectId, errorCode, tab; không giá trị dữ liệu đang hiển thị (BR-17-032, fn_ctx_ok). |
| `expires_at` | `timestamptz` | Hạn xóa vật lý = created_at cộng 17.log.retention-days ngày, sàn 90. |

: Cột của bảng `conversation`

Cột khác: `user_id` v(64); `title` v(200); `state` v(16) ConversationState; `message_count` int; `last_message_at` tstz; `deleted_by_user_at` tstz.

### 3.29. `message`

::: dac-ta
**Mục đích.** EN-17-21 Tin nhắn người dùng, trợ lý, công cụ ĐÃ CHE trước khi lưu (FR-17-022…027, 055; BR-17-073).

**FR phục vụ.** FR-17-022, 023, 024, 025, 026, 027, 055; EN-17-21.

**Khóa chính.** `id`.

**Duy nhất.** `uq_message_seq` (tenant_id, conversation_id, seq), `uq_message_dedup` (tenant_id, conversation_id, dedup_id) có điều kiện.

**Khóa ngoại.** (tenant_id, conversation_id) → `conversation` xóa theo.

**Ràng buộc CHECK.** `ck_message_` + role, outcome, outcome_role, masked, seq, size, capability, counts, trace, no_secret.

**Chỉ mục.** `ix_message_conversation`, `ix_message_outcome`.

**Cách ly tenant.** FORCE RLS theo `tenant_id` và `user_id`: chỉ chủ dòng đọc; SO, AUDITOR đọc khi có phiếu truy cập nhật ký còn hiệu lực (`log_access_grant`); vai `ph17_job` xóa dòng hết hạn.

**Phân vùng, bất biến.** Bất biến: `conversation_id`, `user_id`, `seq`, `role`, `content_masked`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `masked` | `boolean, mặc định true` | Luôn đúng: tầng ứng dụng che DLCN, bí mật trước khi ghi (FR-17-041, 045, 046). |
| `guardrail_codes` | `varchar(48)[], NULL` | Mã quy tắc bộ lọc đã kích hoạt (guardrail_rule.rule_code). |
| `dedup_id` | `uuid, NULL` | Từ tiêu đề Idempotency-Key; hiệu lực chống trùng 5 phút do tầng ứng dụng kiểm. |

: Cột của bảng `message`

Cột khác: `conversation_id` uuid; `user_id` v(64); `seq` int; `role` v(10) MessageRole; `content_masked` text; `redaction_count` int; `outcome` v(16) AnswerOutcome; `capability` v(16) Capability; `model_version_id` uuid; `prompt_version_id` uuid; `tokens_in` int; `tokens_out` int; `truncated` bool; `latency_ms` int; `trace_id` char(32).

### 3.30. `citation`

::: dac-ta
**Mục đích.** EN-17-22 Trích dẫn của một câu trả lời (FR-17-025; BR-17-036, 037): đoạn, đối tượng, liên kết nội bộ, điểm.

**FR phục vụ.** FR-17-025; EN-17-22.

**Khóa chính.** `id`.

**Duy nhất.** `uq_citation_rank` (tenant_id, message_id, rank).

**Khóa ngoại.** (tenant_id, message_id) → `message` xóa theo.

**Ràng buộc CHECK.** `ck_citation_` + rank, route, score.

**Chỉ mục.** `ix_citation_message`.

**Cách ly tenant.** FORCE RLS theo `tenant_id` và `user_id`: chỉ chủ dòng đọc; SO, AUDITOR đọc khi có phiếu truy cập nhật ký còn hiệu lực (`log_access_grant`); vai `ph17_job` xóa dòng hết hạn.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `message_id` uuid; `user_id` v(64); `rank` smallint; `chunk_id` uuid; `source_id` uuid; `object_ref` v(512); `link_route` v(512); `score` numeric(5,4).

### 3.31. `tool_definition`

::: dac-ta
**Mục đích.** EN-17-23 Công cụ của trợ lý (FR-17-042, 047; BR-17-056, 057): danh mục cố định theo mã nguồn, mỗi tenant chỉ bật hoặc tắt. read_only luôn đúng, scope luôn kết thúc :read, không có công cụ ghi; gọi bằng token của người dùng qua token exchange RFC 8693, không quyền riêng của dh-assist.

**FR phục vụ.** FR-17-042, 047; EN-17-23.

**Khóa chính.** `id`.

**Duy nhất.** `uq_tool_definition_code` (tenant_id, tool_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_tool_definition_` + code, module, read_only, scope, caps, timeout, enabled.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `tool_code`, `target_module`, `target_ref`, `scope`, `read_only`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `target_ref` | `varchar(128)` | Tên thao tác đọc của phân hệ đích (ví dụ catalog.search-apis); ánh xạ sang mã API-nn khi phân hệ đích công bố (Q17-51). |

: Cột của bảng `tool_definition`

Cột khác: `tool_code` v(32); `name` v(255); `target_module` v(8); `scope` v(64); `capabilities` v(16)[]; `enabled` bool; `read_only` bool; `timeout_seconds` smallint; `enabled_by` v(64); `enabled_at` tstz.

### 3.32. `tool_call`

::: dac-ta
**Mục đích.** EN-17-24 Một lần gọi công cụ trong lượt (FR-17-043, 047; BR-17-047, 057, 061): tham số đã che, tóm tắt kết quả, thời gian, mã lỗi.

**FR phục vụ.** FR-17-043, 047; EN-17-24.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, message_id) → `message` xóa theo.

**Ràng buộc CHECK.** `ck_tool_call_` + depth, outcome, act, duration, no_token.

**Chỉ mục.** `ix_tool_call_message`, `ix_tool_call_tool`.

**Cách ly tenant.** FORCE RLS theo `tenant_id` và `user_id`: chỉ chủ dòng đọc; SO, AUDITOR đọc khi có phiếu truy cập nhật ký còn hiệu lực (`log_access_grant`); vai `ph17_job` xóa dòng hết hạn.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `message_id` uuid; `user_id` v(64); `tool_code` v(32); `depth` smallint; `args_masked` jsonb; `result_summary` v(4000); `outcome` v(8) ToolOutcome; `duration_ms` int; `error_code` v(16); `act_subject` v(16).

### 3.33. `suggestion`

::: dac-ta
**Mục đích.** EN-17-25 Gợi ý của trợ lý (FR-17-030…035, 061; BR-17-043…049, 083): ánh xạ trường, mã, khắc phục, bước quy trình, tóm tắt.

**FR phục vụ.** FR-17-030, 031, 032, 033, 034, 035, 061; EN-17-25.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_suggestion_` + kind, status, confidence, host, human, decided, edited, applied, no_apply, ttl.

**Chỉ mục.** `ix_suggestion_user`, `ix_suggestion_status`, `ix_suggestion_host`.

**Cách ly tenant.** FORCE RLS theo `tenant_id` và `user_id`: chỉ chủ dòng đọc; SO, AUDITOR đọc khi có phiếu truy cập nhật ký còn hiệu lực (`log_access_grant`); vai `ph17_job` xóa dòng hết hạn.

**Phân vùng, bất biến.** Bất biến: `user_id`, `kind`, `payload`, `confidence`, `host_etag`; Trigger: `tg_suggestion_fsm_status`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `host_etag` | `varchar(128), NULL` | ETag của bản nháp ở phân hệ chủ lúc tạo thẻ; bản nháp đổi thì ERR-17-056 (BR-17-048). |
| `payload` | `jsonb` | Nội dung đề xuất (biểu thức JQ, mã chuẩn, danh sách kiểm); không giá trị dữ liệu thật (BR-17-043). |
| `diff_masked` | `jsonb, NULL` | Phần khác biệt đã che khi người dùng sửa (EDITED), chỉ để đo chất lượng, không huấn luyện (BR-17-049). |

: Cột của bảng `suggestion`

Cột khác: `user_id` v(64); `kind` v(18) SuggestionKind; `status` v(10) SuggestionStatus; `conversation_id` uuid; `message_id` uuid; `host_module` v(8) HostModule; `host_ref` v(255); `confidence` numeric(3,2); `rationale` v(4000); `human_decision_required` bool; `expires_at` tstz; `decided_by` v(64); `decided_at` tstz.

### 3.34. `explanation`

::: dac-ta
**Mục đích.** EN-17-46 (FR-17-036…040, API-17-113…118).

**FR phục vụ.** FR-17-036, 037, 038, 039, 040; EN-17-46.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_explanation_` + kind, masked, ttl.

**Chỉ mục.** `ix_explanation_user`.

**Cách ly tenant.** FORCE RLS theo `tenant_id` và `user_id`: chỉ chủ dòng đọc; SO, AUDITOR đọc khi có phiếu truy cập nhật ký còn hiệu lực (`log_access_grant`); vai `ph17_job` xóa dòng hết hạn.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `kind` | `varchar(16)` | Đề nghị bổ sung ExplanationKind vào Phụ lục A. Enum `ExplanationKind`. |

: Cột của bảng `explanation`

Cột khác: `user_id` v(64); `subject_ref` v(255); `content_masked` text; `masked` bool; `sources` jsonb; `model_version_id` uuid; `prompt_version_id` uuid; `expires_at` tstz.

### 3.35. `suggested_question`

::: dac-ta
**Mục đích.** EN-17-47 (FR-17-028; BR-17-040). Danh mục câu hỏi mẫu theo route và nhóm vai trò, không sinh bằng mô hình; chỉ hiện câu thuộc năng lực đang bật.

**FR phục vụ.** FR-17-028; EN-17-47.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_suggested_question_` + capability, route, text.

**Chỉ mục.** `ix_suggested_question_route`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `question_text` v(300); `route_pattern` v(255); `role_group` v(32); `capability` v(16) Capability; `enabled` bool; `sort_no` smallint.

### 3.36. `guardrail_rule`

::: dac-ta
**Mục đích.** EN-17-38 Quy tắc bộ lọc vào hoặc ra (FR-17-044…046; BR-17-059, 060, 063): loại INPUT hoặc OUTPUT, mẫu (REGEX, KEYWORD hoặc bộ phát hiện), hành động BLOCK, MASK, WARN.

**FR phục vụ.** FR-17-044, 045, 046; EN-17-38.

**Khóa chính.** `id`.

**Duy nhất.** `uq_guardrail_rule_code` (tenant_id, rule_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_guardrail_rule_` + code, kind, action, category, pattern_kind, kind_code, secret_blocks, inject_blocks, pattern.

**Chỉ mục.** `ix_guardrail_rule_kind`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `rule_code`, `guardrail_kind`, `builtin`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `pattern` | `text` | REGEX hoặc từ khóa; với DETECTOR là mã bộ phát hiện (injection-classifier, sensitive-pii). Mẫu bí mật chỉ mô tả dạng, không giá trị thật. |

: Cột của bảng `guardrail_rule`

Cột khác: `rule_code` v(48); `guardrail_kind` v(8) GuardrailKind; `action` v(8) GuardrailAction; `category` v(20) GuardrailCategory; `pattern_kind` v(10) PatternKind; `description` v(1000); `enabled` bool; `builtin` bool.

### 3.37. `link_allowlist`

::: dac-ta
**Mục đích.** EN-17-48 (FR-17-046; BR-17-037).

**FR phục vụ.** FR-17-046; EN-17-48.

**Khóa chính.** `id`.

**Duy nhất.** `uq_link_allowlist_prefix` (tenant_id, route_prefix).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_link_allowlist_` + route.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `route_prefix` v(255); `enabled` bool; `note` v(255).

### 3.38. `prompt_template`

::: dac-ta
**Mục đích.** EN-17-26 Mẫu chỉ dẫn hệ thống (system prompt) theo năng lực (FR-17-049; BR-17-064). Mẫu là vỏ; nội dung nằm ở prompt_version.

**FR phục vụ.** FR-17-049; EN-17-26.

**Khóa chính.** `id`.

**Duy nhất.** `uq_prompt_template_code` (tenant_id, template_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_prompt_template_` + code, capability.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `template_code`, `capability`.

**Ghi chú.** ETag là `version`.
:::

Cột: `template_code` v(48); `capability` v(16) Capability; `name` v(255); `description` v(2000); `retired_at` tstz.

### 3.39. `prompt_version`

::: dac-ta
**Mục đích.** EN-17-27 Phiên bản chỉ dẫn hệ thống (FR-17-049; BR-17-064, 065; FRS 4.6).

**FR phục vụ.** FR-17-049; EN-17-27.

**Khóa chính.** `id`.

**Duy nhất.** `uq_prompt_version_no` (tenant_id, template_id, version_no), `uq_prompt_version_active` (tenant_id, template_id) có điều kiện.

**Khóa ngoại.** (tenant_id, template_id) → `prompt_template`.

**Ràng buộc CHECK.** `ck_prompt_version_` + version, status, hash, content, four_eyes, active, reject, superseded.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `template_id`, `version_no`; Trigger: `tg_prompt_version_frozen`, `tg_prompt_version_fsm_status`, `tg_prompt_version_gate`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `content_text` | `text` | Chỉ dẫn hệ thống; kiểm tĩnh khi lưu (ERR-17-071). Quay lại bản trước là tạo phiên bản mới có nội dung bản cũ (FRS 4.6). |

: Cột của bảng `prompt_version`

Cột khác: `template_id` uuid; `version_no` int; `status` v(16) PromptVersionStatus; `content_hash` char(64); `eval_run_id` uuid; `redteam_run_id` uuid; `submitted_by` v(64); `submitted_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `activated_at` tstz; `superseded_at` tstz.

### 3.40. `eval_set`

::: dac-ta
**Mục đích.** EN-17-28 Bộ đánh giá chuẩn theo năng lực (FR-17-050, 062; BR-17-066): gồm dữ liệu tổng hợp hoặc siêu dữ liệu công khai, tối thiểu 30 ca; tự chạy khi đổi mô hình, mô hình nhúng, prompt, tham số truy hồi.

**FR phục vụ.** FR-17-050, 062; EN-17-28.

**Khóa chính.** `id`.

**Duy nhất.** `uq_eval_set_code` (tenant_id, set_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_eval_set_` + code, capability, min.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `set_code`, `capability`.

**Ghi chú.** ETag là `version`.
:::

Cột: `set_code` v(48); `capability` v(16) Capability; `name` v(255); `description` v(2000); `min_cases` smallint; `retired_at` tstz.

### 3.41. `eval_dataset_link`

::: dac-ta
**Mục đích.** EN-17-28 (EvalDatasetLink) Gắn tập dữ liệu ẩn danh đã phát hành của PH-09 vào bộ đánh giá (FR-17-062; BR-17-084).

**FR phục vụ.** FR-17-062; EN-17-28.

**Khóa chính.** `id`.

**Duy nhất.** `uq_eval_dataset_link` (tenant_id, eval_set_id, dataset_ref).

**Khóa ngoại.** (tenant_id, eval_set_id) → `eval_set` xóa theo.

**Ràng buộc CHECK.** `ck_eval_dataset_link_` + k, expiry.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `eval_set_id`, `dataset_ref`, `k_actual`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `dataset_ref` | `varchar(128)` | Mã tập ẩn danh ở PH-09 (EVT-09-18, API-09-137); không chứa dữ liệu. |

: Cột của bảng `eval_dataset_link`

Cột khác: `eval_set_id` uuid; `k_actual` int; `released_at` tstz; `expires_at` tstz; `linked_by` v(64); `withdrawn_at` tstz.

### 3.42. `eval_case`

::: dac-ta
**Mục đích.** EN-17-29 Ca đánh giá (FR-17-050; BR-17-066): đầu vào tổng hợp hoặc siêu dữ liệu công khai, đáp án mong đợi, tiêu chí chấm.

**FR phục vụ.** FR-17-050; EN-17-29.

**Khóa chính.** `id`.

**Duy nhất.** `uq_eval_case_no` (tenant_id, eval_set_id, case_no).

**Khóa ngoại.** (tenant_id, eval_set_id) → `eval_set` xóa theo, (tenant_id, dataset_link_id) → `eval_dataset_link`.

**Ràng buộc CHECK.** `ck_eval_case_` + origin, dataset, no.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `eval_set_id`, `case_no`.

**Ghi chú.** ETag là `version`.
:::

Cột: `eval_set_id` uuid; `case_no` int; `input_text` text; `expected` jsonb; `criteria` jsonb; `input_origin` v(16) EvalInputOrigin; `dataset_link_id` uuid; `retired_at` tstz.

### 3.43. `eval_run`

::: dac-ta
**Mục đích.** EN-17-30 Một lượt chạy bộ đánh giá hoặc bộ ca đỏ cho một đối tượng (FR-17-050, 051; BR-17-066…068): mô hình, prompt, mô hình nhúng, tham số truy hồi, mã bộ lọc.

**FR phục vụ.** FR-17-050, 051; EN-17-30.

**Khóa chính.** `id`.

**Duy nhất.** `uq_eval_run_running` (tenant_id, run_kind, subject_type, subject_id) có điều kiện.

**Khóa ngoại.** (tenant_id, eval_set_id) → `eval_set`.

**Ràng buộc CHECK.** `ck_eval_run_` + kind, status, subject, trigger, counts, score, rate, set, finished, passed_eval, passed_redteam, error.

**Chỉ mục.** `ix_eval_run_subject`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `run_kind`, `subject_type`, `subject_id`; Trigger: `tg_eval_run_fsm_status`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `subject_id` | `uuid, NULL` | Mã phiên bản mô hình, prompt hoặc nhúng; NULL với tham số truy hồi, mã bộ lọc (ghi subject_type). |
| `ci_ref` | `varchar(255), NULL` | Mã lượt CI đã chạy bộ ca đỏ khi đổi mã bộ lọc, công cụ, prompt (BR-17-068). |

: Cột của bảng `eval_run`

Cột khác: `run_kind` v(8) EvalRunKind; `eval_set_id` uuid; `subject_type` v(16) EvalSubjectType; `status` v(8) EvalRunStatus; `trigger_kind` v(16) EvalTriggerKind; `cases_total` int; `cases_passed` int; `cases_leaked` int; `score` numeric(5,4); `pass_rate` numeric(5,2); `baseline_run_id` uuid; `regression_delta` numeric(5,4); `started_at` tstz; `finished_at` tstz; `error_code` v(16).

### 3.44. `eval_result`

::: dac-ta
**Mục đích.** EN-17-31 Kết quả từng ca của một lượt chạy (FR-17-050, 051): đạt hay không, điểm, nội dung đã che, ca đỏ có bị chặn không.

**FR phục vụ.** FR-17-050, 051; EN-17-31.

**Khóa chính.** `id`.

**Duy nhất.** `uq_eval_result_case` (tenant_id, run_id, case_ref).

**Khóa ngoại.** (tenant_id, run_id) → `eval_run` xóa theo.

**Ràng buộc CHECK.** `ck_eval_result_` + kind, blocked, redteam_pass, score.

**Chỉ mục.** `ix_eval_result_run`, `ix_eval_result_dataset`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `dataset_link_id` | `uuid, NULL` | Có khi ca lấy từ tập ẩn danh PH-09; gỡ tập thì xóa các dòng này (API-17-186). |

: Cột của bảng `eval_result`

Cột khác: `run_id` uuid; `case_kind` v(8) EvalRunKind; `case_ref` uuid; `passed` bool; `score` numeric(5,4); `blocked` bool; `detail_masked` v(4000); `latency_ms` int.

### 3.45. `redteam_case`

::: dac-ta
**Mục đích.** EN-17-32 Ca đỏ tiêm lệnh (FR-17-051; BR-17-063, 067, 068): nhóm tấn công, nội dung tấn công TỔNG HỢP, hành vi mong đợi luôn là chặn.

**FR phục vụ.** FR-17-051; EN-17-32.

**Khóa chính.** `id`.

**Duy nhất.** `uq_redteam_case_code` (tenant_id, case_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_redteam_case_` + code, category, expected, status, origin, retired, attack.

**Chỉ mục.** `ix_redteam_case_status`.

**Cách ly tenant.** FORCE RLS: đọc dòng của tenant và dòng `COMMON`, ghi chỉ dòng của tenant; dòng `COMMON` chỉ vai `ph17_platform` ghi.

**Phân vùng, bất biến.** Bất biến: `case_code`, `category`, `attack_text`, `expected_behavior`; Trigger: `tg_redteam_case_fsm_status`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `attack_text` | `text` | Nội dung tấn công tổng hợp; không dữ liệu thật, không bí mật thật (BR-17-067). |
| `status` | `varchar(8), mặc định 'ACTIVE'` | ACTIVE, RETIRED (trạng thái nội bộ của thiết kế, không phải enum FRS). |

: Cột của bảng `redteam_case`

Cột khác: `case_code` v(32); `category` v(20) RedteamCategory; `expected_behavior` v(8); `origin` v(10) RedteamOrigin; `source_feedback_id` uuid; `retired_at` tstz; `retired_reason` v(1000).

### 3.46. `feedback`

::: dac-ta
**Mục đích.** EN-17-33 Phản hồi của người dùng cho một câu trả lời (FR-17-052; BR-17-069, 070): HELPFUL, NOT_HELPFUL, WRONG, UNSAFE; mỗi người một lần cho mỗi câu trả lời (ERR-17-077).

**FR phục vụ.** FR-17-052; EN-17-33.

**Khóa chính.** `id`.

**Duy nhất.** `uq_feedback_user_message` (tenant_id, message_id, user_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_feedback_` + kind, status, reason, assigned, closed, promoted, due.

**Chỉ mục.** `ix_feedback_queue`, `ix_feedback_message`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `message_id`, `user_id`, `kind`; Trigger: `tg_feedback_fsm_status`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `message_id` | `uuid` | Tham chiếu logic tới message (message bị xóa theo hạn lưu thì phản hồi vẫn còn để đo chất lượng). |
| `due_at` | `timestamptz` | created_at cộng 17.feedback.sla-days ngày làm việc. |

: Cột của bảng `feedback`

Cột khác: `user_id` v(64); `kind` v(12) FeedbackKind; `status` v(20) FeedbackStatus; `reason_masked` v(4000); `redteam_candidate` bool GENERATED ALWAYS AS (kind = 'UNSAFE') STORED; `assigned_to` v(64); `assigned_at` tstz; `closed_at` tstz; `resolution` v(2000); `promoted_case_id` uuid.

### 3.47. `quality_metric`

::: dac-ta
**Mục đích.** EN-17-34 Chỉ số chất lượng theo ngày, tuần, năng lực, mô hình, phiên bản prompt (FR-17-053; BR-17-071): tỷ lệ có trích dẫn, tỷ lệ không tìm thấy, tỷ lệ chấp nhận gợi ý, điểm đánh giá, tỷ lệ hữu ích.

**FR phục vụ.** FR-17-053; EN-17-34.

**Khóa chính.** `id`.

**Duy nhất.** `uq_quality_metric_bucket` (tenant_id, metric_date, period, capability, metric_code, COALESCE(model_version_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(prompt_version_id, '00000000-0000-0000-0000-000000000000'::uuid)).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_quality_metric_` + period, capability, code, sample.

**Chỉ mục.** `ix_quality_metric_alert`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `metric_date` date; `period` v(4) MetricPeriod; `capability` v(16) Capability; `model_version_id` uuid; `prompt_version_id` uuid; `metric_code` v(24) MetricCode; `value` numeric(12,4); `sample_count` int; `baseline_value` numeric(12,4); `alert` bool.

### 3.48. `ai_system_record`

::: dac-ta
**Mục đích.** EN-17-35 Hồ sơ đăng ký hệ thống AI của tenant (FR-17-054; BR-17-072; Luật Công nghiệp công nghệ số 2025, chương trí tuệ nhân tạo, chưa đối chiếu Công báo): mục đích, mô hình, dữ liệu, rủi ro, biện pháp, người chịu trách nhiệm.

**FR phục vụ.** FR-17-054; EN-17-35.

**Khóa chính.** `id`.

**Duy nhất.** `uq_ai_system_record_code` (tenant_id, record_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_ai_system_record_` + risk, status, review, measures, code.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `record_code`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `risk_level` | `varchar(8)` | LOW, MEDIUM, HIGH (RiskLevel, Phụ lục A). Enum `RiskLevel`. |
| `next_review_due` | `date` | Không quá 12 tháng sau lần rà soát cuối (BR-17-072). |

: Cột của bảng `ai_system_record`

Cột khác: `record_code` v(32); `name` v(255); `purpose` text; `model_summary` jsonb; `data_summary` jsonb; `risk_assessment` text; `measures` text[]; `responsible_user` v(64); `status` v(10) AiSystemStatus; `last_review_at` tstz; `legal_refs` v(16)[].

### 3.49. `log_access_grant`

::: dac-ta
**Mục đích.** EN-17-36 Phiếu truy cập nhật ký hội thoại có lý do (FR-17-056; BR-17-074, 075): chỉ SO, AUDITOR; lý do từ 20 ký tự; phạm vi một hội thoại hoặc khoảng không quá 92 ngày; hiệu lực tối đa 60 phút.

**FR phục vụ.** FR-17-056; EN-17-36.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_log_access_grant_` + role, reason, scope, scope_fields, ttl, state, count, revoked.

**Chỉ mục.** `ix_log_access_grant_grantee`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Bất biến: `grantee`, `grantee_role`, `reason`, `scope_kind`, `conversation_id`, `range_from`, `range_to`, `granted_at`, `expires_at`; Trigger: `tg_log_access_grant_fsm_state`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `conversation_id` | `uuid, NULL` | Tham chiếu logic tới conversation (không khóa ngoại: hội thoại có thể bị xóa theo hạn lưu). |

: Cột của bảng `log_access_grant`

Cột khác: `grantee` v(64); `grantee_role` v(10) LogGranteeRole; `reason` v(2000); `scope_kind` v(12) LogScopeKind; `range_from` tstz; `range_to` tstz; `granted_at` tstz; `expires_at` tstz; `state` v(8) LogAccessGrantState; `access_count` int; `revoked_at` tstz; `revoked_by` v(64).

### 3.50. `compliance_export`

::: dac-ta
**Mục đích.** EN-17-37 Gói bằng chứng tuân thủ và báo cáo sử dụng đã tạo (FR-17-057, 058; BR-17-076, 077): cấu hình, mô hình và phiên bản, kết quả đánh giá, ca đỏ, sổ đăng ký; KHÔNG chứa nội dung hội thoại.

**FR phục vụ.** FR-17-057, 058; EN-17-37.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, file_id) → `file_object`.

**Ràng buộc CHECK.** `ck_compliance_export_` + kind, state, no_content, period, ready, sha, failed.

**Chỉ mục.** `ix_compliance_export_state`.

**Cách ly tenant.** FORCE RLS theo `tenant_id`, bốn chính sách (đọc, chèn, sửa, xóa).

**Phân vùng, bất biến.** Trigger: `tg_compliance_export_fsm_state`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `signature_ref` | `varchar(255), NULL` | Tham chiếu chữ ký OpenBao transit; không chứa khóa. |
| `contains_conversation` | `boolean, mặc định false` | Luôn sai: gói không mang nội dung hội thoại. |

: Cột của bảng `compliance_export`

Cột khác: `export_kind` v(16) ExportKind; `state` v(10) ExportState; `requested_by` v(64); `period_from` date; `period_to` date; `file_id` uuid; `sha256` char(64); `expires_at` tstz; `error_code` v(16).
<!-- gen:tables:end -->

### 3.51. Phân vùng và bảo trì

Hai bảng phân vùng theo tháng, bảo trì bằng tác vụ định kỳ; DDL tạo sẵn ba phân vùng từ tháng triển khai và phân vùng mặc định để không mất dòng.

| Bảng | Khóa phân vùng | Tạo trước | Dọn |
|---|---|---|---|
| `invocation_log` | `occurred_at` | 3 tháng tới | `DETACH` rồi `DROP` sau 13 tháng; bản gốc nhật ký kiểm toán ở WORM của PH-13 (Q17-50) |
| `model_health_probe` | `checked_at` | 3 tháng tới | `DROP` phân vùng sau 3 tháng |

: Phân vùng và bảo trì

`PartitionMaintenanceJob` gọi `p_ensure_partitions` mỗi ngày (khóa tác vụ bằng `pg_try_advisory_lock`). Việc dọn do `ph17_owner` thực hiện, vai `ph17_app` không có quyền xóa nhật ký.

## 4. DDL và changelog Liquibase

### 4.1. Tệp

[`ph17/ddl/ph17_assist.sql`](ph17/ddl/ph17_assist.sql) là nguồn duy nhất, chia changeset bằng `-- @file`, `-- @changeset`, `-- @rollback` như PH-09. Changelog [`ph17/liquibase/db.changelog-ph17.yaml`](ph17/liquibase/db.changelog-ph17.yaml) và 12 tệp `ph17/liquibase/changes/*.sql` (formatted SQL, tác giả `ph17`) sinh bằng [`gen_liquibase.py`](ph17/tools/gen_liquibase.py), không sửa tay.

| Tệp | Nội dung |
|---|---|
| `17-0000-bootstrap.sql` | Sáu vai trò, extension `vector` có điều kiện, schema, biến phiên |
| `17-0001-functions.sql` | `tg_touch`, `tg_immutable`, `tg_append_only`, `tg_frozen`, `tg_release_gate`, `fn_setting_num`, `fn_log_grant_ok`, `fn_ctx_ok`, `p_enable_rls`, `p_enable_rls_common`, `p_enable_rls_user`, `p_ensure_partitions`, `p_seed_tenant` |
| `17-0010-core.sql` | `file_object`, `tenant_setting`, `outbox_event`, `inbox_event` |
| `17-0020-policy.sql` | `ai_notice`, `notice_acceptance`, `policy_change`, `tenant_policy`, `capability_policy`, `quota_usage`, `kill_switch_record` |
| `17-0030-model.sql` | `model_provider`, `provider_commitment`, `model`, `model_version`, `model_route`, `route_sync_run`, `tenant_model`, `provider_grant`, `invocation_log`, `model_health_probe`, `model_breaker` |
| `17-0040-knowledge.sql` | `knowledge_source`, `knowledge_document`, `knowledge_chunk`, `index_job`, `knowledge_deletion` |
| `17-0045-pgvector.sql` | Đổi `embedding` sang `vector(1024)` và chỉ mục HNSW khi có extension |
| `17-0050-chat.sql` | `conversation`, `message`, `citation`, `tool_definition`, `tool_call`, `suggestion`, `explanation`, `suggested_question` |
| `17-0060-guard.sql` | `guardrail_rule`, `link_allowlist` |
| `17-0070-eval.sql` | `prompt_template`, `prompt_version`, `eval_set`, `eval_dataset_link`, `eval_case`, `eval_run`, `eval_result`, `redteam_case`, `feedback`, `quality_metric` |
| `17-0080-govern.sql` | `ai_system_record`, `log_access_grant`, `compliance_export` |
| `17-0900-grants.sql` | Quyền theo vai trò |

: Tệp DDL và changelog Liquibase của PH-17

Không có changeset di trú dữ liệu: PH-17 là năng lực mới, hệ cũ không có AI (mục 8.4).

### 4.2. Kết quả chạy thử

Chạy ngày 26/11/2026 bằng `build/tools/chay_ddl.py ph17` trên PostgreSQL 16.15 (Ubuntu 24.04) cài sạch, không có pgvector, dữ liệu giả, tenant kiểm thử T90, T91:

- DDL chạy không lỗi với `ON_ERROR_STOP`: 50 bảng gốc, 24 phân vùng, 350 `CHECK`, 29 khóa ngoại, 104 trigger, 226 chính sách RLS, 181 chỉ mục.
- Ghép 12 tệp changelog theo `db.changelog-ph17.yaml` rồi chạy bằng psql trên CSDL trống khác: không lỗi, cùng 50 bảng. Chưa chạy bằng Liquibase CLI (không có trong máy); CI chạy `liquibase update` trên Testcontainers.
- [`ph17_isolation_test.sql`](ph17/test/ph17_isolation_test.sql) đạt 182 khối PASS, chia 9 nhóm: nạp tenant (1 chính sách, 3 năng lực, 9 công cụ, 10 quy tắc lọc, 49 tham số, 6 câu hỏi, chạy lại không nhân bản); cô lập tenant (T91 đọc 0 dòng của T90, không chèn, sửa, xóa); bật trợ lý bốn mắt và máy trạng thái; điều khoản; nhà cung cấp, mô hình, phiên bản, cổng phát hành và 50 ca đỏ; bật mô hình cho tenant, danh sách trắng, dự phòng; kho tri thức (mức, ACL, xóa lan truyền, bốn mắt tài liệu tải lên, chỉ mục từ khóa); hội thoại (RLS theo người dùng, phiếu SO hết hạn hoặc thu hồi, xóa theo lịch); nhật ký gọi mô hình chỉ thêm, hộp thư đi, quét lược đồ (không cột bí mật, mọi bảng FORCE RLS, kiểu vector khớp extension).
- `chay_ddl.py` không đối số nạp 16 phân hệ lên một CSDL: không xung đột tên vai trò hay schema.

Bài kiểm cổng phát hành cho chỉ dẫn hệ thống, `feedback`, `ai_system_record` và `compliance_export` chưa có khối riêng; ràng buộc đã nằm ở DDL và được `TenantIsolationIT` bổ sung ở D03-02-PH17 (mục 9, Q17-56).

### 4.3. Đối chiếu với FRS Phụ lục A

[`ph17/tools/check_frs.py`](ph17/tools/check_frs.py) đọc FRS và DDL, kiểm: (1) mọi cột có `CHECK` liệt kê giá trị khớp một enum Phụ lục A hoặc là tập con có chủ ý; (2) không có giá trị `CHECK` dạng chữ hoa mà FRS không có; (3) mọi mã ERR, BR, EN, FR nhắc ở DDL và tài liệu có ở FRS, đủ 39 EN và 62 FR có mặt ở tài liệu; (4) mọi bảng có `tenant_id` bật FORCE RLS và có `COMMENT ON TABLE`. Kết quả ghi ở mục 10.

## 5. Dữ liệu khởi tạo

Không có dữ liệu dùng chung ngoài ba nhóm do PA khai báo ở `COMMON` (nhà cung cấp, mô hình, ca đỏ khởi tạo, bộ đánh giá chuẩn), nạp ở bước tạo nền tảng. Khi PH-20 khởi tạo tenant, `dh-assist` gọi `ph17_assist.p_seed_tenant('Tnn')`; thủ tục chạy lại không nhân bản (`ON CONFLICT DO NOTHING`, `id` tất định theo `md5`).

| Dữ liệu | Nội dung | Nguồn |
|---|---|---|
| `tenant_policy` | 1 dòng `DISABLED`, mô hình ngoài tắt | FR-17-001; BR-17-001, 004 |
| `capability_policy` | 3 dòng (`SEARCH`, `MAPPING`, `EXPLAIN`), nhóm `ALL_READERS`, đều tắt | FR-17-002 |
| `tool_definition` | 9 công cụ chỉ đọc, mỗi công cụ một phạm vi `:read` (ví dụ `SEARCH_API` với `catalog:read`) | FR-17-042 |
| `guardrail_rule` | 10 quy tắc dựng sẵn (tiêm lệnh, nội dung cấm, bí mật PEM, DLCN, đường dẫn, ...) | FR-17-044, 045 |
| `link_allowlist` | 1 dòng: mọi route nội bộ của cổng (`/`) | FR-17-046 |
| `tenant_setting` | 49 dòng theo FRS 8.2 kèm sàn, trần, cờ bốn mắt (`17.log.retention-days` 90 sàn 90, `17.rag.min-score` 0,55 trong 0,3 đến 0,9, hạn mức token 2.000.000 trần 50.000.000, `17.redteam.min-pass-rate` 100) | FR-17-059 |
| `suggested_question` | 6 câu hỏi mẫu theo màn hình | FR-17-029 |

: Dữ liệu khởi tạo mỗi tenant

Không nạp sẵn mô hình hay nhà cung cấp cho tenant: mô hình do PA khai báo, tenant phải bật rồi mới dùng (FR-17-009). Tuyến trắng mặc định (một dòng, `PENDING`) chờ PH-03 đồng bộ.

## 6. Kho lưu trữ ngoài PostgreSQL

### 6.1. OpenBao

Bí mật nhà cung cấp mô hình ngoài và khóa HMAC ký gói bằng chứng chỉ nằm ở OpenBao; CSDL giữ `model_provider.secret_ref`, ví dụ `openbao://kv/tenants/T01/assist/provider-x`, và `ck_model_provider_secret_ref` chỉ nhận mẫu đường dẫn. Tên khóa ký gói bằng chứng là `dh-{tenant}-assist-sign` (giả định, Q17-55).

### 6.2. Kafka

Hai mươi tám topic `{tenant}.assist.*.v1` của EVT-17-01…28 do Debezium Outbox Event Router đọc từ `outbox_event`, khóa phân vùng là `tenantId`; sự kiện chỉ mang mã, trạng thái, số đếm, thời điểm. Sự kiện vào (đổi mô tả API ở PH-02, danh mục ở PH-07, luồng ở PH-04, xuất bản ở PH-10, đổi phân loại ở PH-09, ảnh chụp cổng ở PH-03) vào `inbox_event` rồi kích hoạt lập chỉ mục (FRS 9.3b).

### 6.3. Garage

Garage giữ nội dung tệp mà `file_object` tham chiếu: tài liệu tải lên (`dh-assist-upload`), hồ sơ cam kết nhà cung cấp, gói bằng chứng tuân thủ, báo cáo sử dụng. Chỉ tệp `scan_status = CLEAN` được dùng; tệp mức khác `PUBLIC`, `INTERNAL` bị `CHECK` chặn.

### 6.4. Valkey

`dh:{tenant}:assist:quota:{ngày}:{người}` giữ bộ đếm hạn mức nóng, ghi xuống `quota_usage` định kỳ; `dh:{tenant}:assist:breaker:{tuyến}` giữ trạng thái cầu dao (bản bền ở `model_breaker`); `dh:{tenant}:assist:idem:{khóa}` giữ khóa chống trùng 24 giờ; `dh:{tenant}:assist:index-debounce` gom sự kiện lập chỉ mục. Đây là giả định thiết kế, không có dữ liệu nghiệp vụ duy nhất nào chỉ nằm ở Valkey.

### 6.5. APISIX và dịch vụ mô hình

Tuyến egress, danh sách trắng đích và giới hạn token nằm ở APISIX (PH-03), đồng bộ từ `model_route` bằng `route_sync_run`. Mô hình nội bộ chạy ngoài PostgreSQL (GPU, Kubernetes), `model_version.price_*` chỉ ghi đơn giá ước tính. Không có ClickHouse cho PH-17: báo cáo sử dụng đọc `quota_usage` và `invocation_log`.

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

| Đối tượng | Lưu giữ | Cơ chế dọn, sao lưu |
|---|---|---|
| Schema `ph17_assist` | WAL liên tục, base backup hằng ngày lên Garage, RPO ≤ 5 phút, RTO ≤ 30 phút (ADR-034) | Diễn tập DR theo D03-09; khôi phục áp lại danh sách xóa lan truyền trước khi phục vụ |
| Chính sách, mô hình, phiên bản, chỉ dẫn, ca đỏ, hồ sơ hệ thống AI, phiếu truy cập, gói bằng chứng | Vĩnh viễn, không xóa cứng | `REVOKE DELETE` cho `ph17_app` |
| `conversation`, `message`, `citation`, `tool_call`, `explanation` | 90 ngày tối thiểu (`17.log.retention-days`, sàn 90) | `ph17_job` xóa khi `expires_at` qua hạn (xóa dây chuyền tin nhắn con) |
| `feedback`, `quality_metric`, `eval_result` | 365 ngày; chỉ số chất lượng 2 năm | `DELETE` theo lịch; kết quả đánh giá xóa khi tập ẩn danh hết hạn (BR-17-084) |
| `invocation_log` | 13 tháng trực tuyến (Q17-50) | `DETACH` phân vùng; gốc ở WORM PH-13 |
| `model_health_probe` | 3 tháng | `DROP` phân vùng |
| `quota_usage` | 400 ngày | `ph17_job` xóa theo ngày |
| `knowledge_chunk`, `knowledge_document` | Theo nguồn; khi tắt trợ lý giữ 90 ngày rồi xóa nếu không bật lại (Q17-21) | Xóa lan truyền, `knowledge_deletion` chỉ thêm |
| `file_object` | Theo `expires_at`; tài liệu tải lên theo nguồn | Dọn bằng tác vụ, xóa đối tượng ở Garage |
| `outbox_event`, `inbox_event` | 3 ngày; 7 ngày | `OutboxCleanupJob`, `InboxCleanupJob` mỗi giờ |

: Sao lưu, khôi phục và lưu giữ của PH-17

**Mã hóa.** Kết nối `pg-core` bắt buộc TLS; dữ liệu tĩnh mã hóa mức đĩa (D03-07). Nội dung hội thoại đã che trước khi vào bảng nên bản sao lưu rời cụm không có dữ liệu cá nhân rõ. Không có cột chứa bí mật trong schema.

**Thứ tự khôi phục.** OpenBao trước, `pg-core` sau; sau khôi phục, đợt lập chỉ mục chạy lại cho tài liệu có `content_hash` khác nguồn. Nếu sao lưu cũ còn đoạn của tài liệu đã bị xóa lan truyền, job áp lại `knowledge_deletion` rồi mới mở trợ lý (BR-17-029).

## 8. Ánh xạ thực thể, chức năng và CSDL cũ sang thiết kế mới

### 8.1. Thực thể EN-17 → bảng

Bảng ánh xạ 48 thực thể của FRS 4.2 (bản 0.2) sang bảng. EN-17-28 (`EvalSet`) gồm thêm bảng liên kết tập dữ liệu `eval_dataset_link`; EN-17-39 gồm hai bảng hạ tầng dùng chung (`outbox_event`, `file_object`). EN-17-40…48 là chín thực thể FRS 0.2 cấp mã cho các bảng từng ghi "Bổ sung" ở bản 0.1.

<!-- gen:en:start -->
| Thực thể | Tên ở FRS 4.2 | Bảng hiện thực |
|---|---|---|
| EN-17-01 | `TenantPolicy` | `tenant_policy` |
| EN-17-02 | `PolicyChange` | `policy_change` |
| EN-17-03 | `CapabilityPolicy` | `capability_policy` |
| EN-17-04 | `ProviderGrant` | `provider_grant` |
| EN-17-05 | `AiNotice` | `ai_notice` |
| EN-17-06 | `NoticeAcceptance` | `notice_acceptance` |
| EN-17-07 | `QuotaUsage` | `quota_usage` |
| EN-17-08 | `KillSwitchRecord` | `kill_switch_record` |
| EN-17-09 | `ModelProvider` | `model_provider` |
| EN-17-10 | `Model` | `model` |
| EN-17-11 | `ModelVersion` | `model_version` |
| EN-17-12 | `ModelRoute` | `model_route` |
| EN-17-13 | `RouteSyncRun` | `route_sync_run` |
| EN-17-14 | `InvocationLog` | `invocation_log` |
| EN-17-15 | `ModelHealthProbe` | `model_health_probe` |
| EN-17-16 | `KnowledgeSource` | `knowledge_source` |
| EN-17-17 | `KnowledgeDocument` | `knowledge_document` |
| EN-17-18 | `KnowledgeChunk` | `knowledge_chunk` |
| EN-17-19 | `IndexJob` | `index_job` |
| EN-17-20 | `Conversation` | `conversation` |
| EN-17-21 | `Message` | `message` |
| EN-17-22 | `Citation` | `citation` |
| EN-17-23 | `ToolDefinition` | `tool_definition` |
| EN-17-24 | `ToolCall` | `tool_call` |
| EN-17-25 | `Suggestion` | `suggestion` |
| EN-17-26 | `PromptTemplate` | `prompt_template` |
| EN-17-27 | `PromptVersion` | `prompt_version` |
| EN-17-28 | `EvalSet` | `eval_set`, `eval_dataset_link` |
| EN-17-29 | `EvalCase` | `eval_case` |
| EN-17-30 | `EvalRun` | `eval_run` |
| EN-17-31 | `EvalResult` | `eval_result` |
| EN-17-32 | `RedteamCase` | `redteam_case` |
| EN-17-33 | `Feedback` | `feedback` |
| EN-17-34 | `QualityMetric` | `quality_metric` |
| EN-17-35 | `AiSystemRecord` | `ai_system_record` |
| EN-17-36 | `LogAccessGrant` | `log_access_grant` |
| EN-17-37 | `ComplianceExport` | `compliance_export` |
| EN-17-38 | `GuardrailRule` | `guardrail_rule` |
| EN-17-40 | `TenantSetting` | `tenant_setting` |
| EN-17-41 | `InboxEvent` | `inbox_event` |
| EN-17-42 | `ProviderCommitment` | `provider_commitment` |
| EN-17-43 | `TenantModel` | `tenant_model` |
| EN-17-44 | `ModelBreaker` | `model_breaker` |
| EN-17-45 | `KnowledgeDeletion` | `knowledge_deletion` |
| EN-17-46 | `Explanation` | `explanation` |
| EN-17-47 | `SuggestedQuestion` | `suggested_question` |
| EN-17-48 | `LinkAllowlist` | `link_allowlist` |

: Ánh xạ thực thể EN-17 sang bảng
<!-- gen:en:end -->

### 8.2. Chức năng FR-17 → bảng

Mỗi chức năng liệt kê bảng chính nó ghi hoặc đọc; chức năng tổng hợp (FR-17-029, 041, 048, 060) ghi tay.

<!-- gen:fr:start -->
| FR-17 | Bảng hiện thực | FR-17 | Bảng hiện thực |
|---|---|---|---|
| 001 | `policy_change`, `tenant_policy` | 032 | `suggestion` |
| 002 | `capability_policy` | 033 | `suggestion` |
| 003 | `file_object`, `policy_change`, `tenant_policy`, `provider_commitment`, `provider_grant` | 034 | `suggestion` |
| 004 | `quota_usage` | 035 | `suggestion` |
| 005 | `ai_notice`, `notice_acceptance` | 036 | `explanation` |
| 006 | `policy_change`, `tenant_policy`, `kill_switch_record` | 037 | `explanation` |
| 007 | `file_object`, `model_provider`, `provider_commitment` | 038 | `explanation` |
| 008 | `model`, `model_version` | 039 | `explanation` |
| 009 | `model_version` | 040 | `explanation` |
| 010 | `model_route`, `tenant_model` | 041 | `message`, `tool_call`, `guardrail_rule` |
| 011 | `model_route`, `route_sync_run` | 042 | `tool_definition` |
| 012 | `model_breaker` | 043 | `tool_call` |
| 013 | `invocation_log` | 044 | `guardrail_rule` |
| 014 | `model_health_probe`, `model_breaker` | 045 | `guardrail_rule` |
| 015 | `knowledge_source` | 046 | `guardrail_rule`, `link_allowlist` |
| 016 | `knowledge_document` | 047 | `tool_definition`, `tool_call` |
| 017 | `knowledge_document`, `index_job` | 048 | `message`, `citation`, `suggestion`, `explanation` |
| 018 | `knowledge_document`, `knowledge_chunk` | 049 | `prompt_template`, `prompt_version` |
| 019 | `knowledge_document`, `knowledge_chunk`, `knowledge_deletion` | 050 | `eval_set`, `eval_case`, `eval_run`, `eval_result` |
| 020 | `file_object`, `knowledge_document` | 051 | `eval_run`, `eval_result`, `redteam_case` |
| 021 | `knowledge_source`, `knowledge_document`, `index_job` | 052 | `feedback` |
| 022 | `conversation`, `message` | 053 | `quality_metric` |
| 023 | `knowledge_chunk`, `message` | 054 | `ai_system_record` |
| 024 | `knowledge_chunk`, `message` | 055 | `message` |
| 025 | `message`, `citation` | 056 | `log_access_grant` |
| 026 | `message` | 057 | `file_object`, `compliance_export` |
| 027 | `conversation`, `message` | 058 | `quota_usage`, `compliance_export` |
| 028 | `suggested_question` | 059 | `tenant_setting`, `policy_change` |
| 029 | `conversation`, `message`, `suggested_question` | 060 | `invocation_log`, `model_version`, `quota_usage` |
| 030 | `suggestion` | 061 | `suggestion` |
| 031 | `suggestion` | 062 | `eval_set`, `eval_dataset_link` |

: Ánh xạ FR-17-001…062 sang bảng (hai cột song song: 001 đến 031 và 032 đến 062)

<!-- gen:fr:end -->

### 8.3. Mô hình SRS cũ của repo (`docs/07-srs/SRS-PH-17-ai.md` §4)

SRS cũ thiên về cổng AI nền tảng có MLflow và Evidently; FRS mới thu hẹp thành trợ lý và quản trị truy cập AI nên chỉ một phần thực thể có đích.

| Thực thể cũ | Bảng mới | Chuyển đổi |
|---|---|---|
| `MO_HINH_AI` (EN-17-01 cũ) | `model_provider`, `model` | `ma_mo_hinh` → `model.model_code`; `loai_nhiem_vu` → `model_kind` (`CHAT`, `EMBEDDING`, `RERANK`); `muc_rui_ro` chuyển vào `ai_system_record.risk_level`; `trang_thai` → `status` |
| `PHIEN_BAN_MO_HINH` (EN-17-02 cũ) | `model_version`, `model_route` | `giai_doan` `NONE`, `STAGING`, `PRODUCTION`, `ARCHIVED` → `ModelVersionStatus` (`DRAFT`, `EVALUATING`, `APPROVED`, `RETIRED`); `uri_suy_luan` → `model_route.route_ref` và `egress_host`; `mlflow_run_id`, `baseline_drift_id` bỏ (không dùng MLflow, Evidently) |
| `NHAT_KY_QUYET_DINH` (EN-17-03 cũ) | `invocation_log`, `message` | Không lưu `dau_vao_tom_tat`: nội dung đã che ở `message.content_masked`, vết số liệu ở `invocation_log`; bỏ tính WORM nội bộ, bản gốc ở PH-13 |
| `PHIEU_HITL` (EN-17-04 cũ) | `suggestion` | Trợ lý chỉ đề xuất, người dùng bấm áp dụng thì phân hệ chủ ghi nháp; không còn phiếu duyệt quyết định hành chính ở PH-17 |
| `LIEN_KET_DATASET` (EN-17-05 cũ) | `eval_dataset_link` | Chỉ liên kết tập ẩn danh của PH-09 cho đánh giá; không huấn luyện |
| `BAO_CAO_DRIFT`, `DINH_TUYEN_AI`, `ACL_MO_HINH` (EN-17-06 cũ) | `quality_metric`, `model_route`, `tenant_model`, `provider_grant` | Drift thay bằng chỉ số chất lượng; ACL mô hình thành bật mô hình theo tenant và danh sách trắng nhà cung cấp |

: Ánh xạ thực thể SRS cũ sang bảng mới

### 8.4. Hệ cũ Viettel 2021 và CSDL quốc gia

Hệ cũ không có năng lực AI (REQ-17 là năng lực mới) nên không có bảng hay cột cũ cần chuyển đổi cho D06-01 và không có changeset di trú. Các chức năng cũ được hỗ trợ gián tiếp (`LGC-BUS-002`, `003`, `004`, `027`, `029`, `037`, `LGC-TOOL-007`, `028`) qua công cụ chỉ đọc của trợ lý, không có bảng riêng.

## 9. Câu hỏi mở

Các câu hỏi chưa có quyết định, kèm đề xuất tạm. Câu hỏi nghiệp vụ Q17-01…22 ở FRS 13; bảng này chỉ nêu câu hỏi phát sinh khi thiết kế CSDL.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q17-50 | Thời hạn trực tuyến của `invocation_log` (13 tháng) và `model_health_probe` (3 tháng) so với quy định bảo quản nhật ký | Giữ giả định; nếu pháp chế yêu cầu dài hơn thì tăng số phân vùng giữ và cấp thêm dung lượng |
| Q17-51 | `tool_definition.target_ref` ghi tên thao tác đọc (ví dụ `catalog.search-apis`) vì phân hệ đích chưa công bố mã API-nn | Giữ tên thao tác; thêm bảng ánh xạ hoặc đổi sang mã API khi PH-02, 04, 07, 10 công bố (Q17-11) |
| Q17-52 | Tham số HNSW (`m = 16`, `ef_construction = 64`) và `hnsw.ef_search` đủ cho 200.000 đoạn, độ trễ truy hồi ≤ yêu cầu; khi đổi mô hình nhúng thì dựng lại toàn bộ vector | Giữ tham số mặc định; đo ở đợt 3 (Q17-01); đổi mô hình nhúng là phiên bản mới, nhúng lại theo `embed_version_id`, giữ hai bộ vector cho tới khi chuyển xong |
| Q17-53 | Truy hồi từ khóa dùng `tsvector` cấu hình `simple` trên văn bản đã bỏ dấu ở ứng dụng, thay cho `unaccent` | Giữ; nếu Q17-18 chốt `unaccent` thì thêm extension và đổi cột sinh bằng một changeset |
| Q17-54 | Dữ liệu `COMMON` (mô hình, ca đỏ, nguồn chung) có nên ở schema riêng thay cho dòng `tenant_id = 'COMMON'` | Giữ dòng `COMMON` cho khớp mẫu RLS của tập; bảng dùng chung có `p_enable_rls_common` nên tenant không ghi được |
| Q17-55 | Tên khóa ký gói bằng chứng ở OpenBao (`dh-{tenant}-assist-sign`) và chu kỳ quay khóa | Giả định tên; PH-18 xác nhận khi đăng ký khóa |
| Q17-56 | `message`, `invocation_log` có cần phân vùng băm hay tháng cho tenant lớn; và bổ sung khối kiểm cho `prompt_version`, `feedback`, `ai_system_record`, `compliance_export` | `message` chưa phân vùng ở tỉnh vừa (5,4 triệu dòng, xóa theo hạn); nếu vượt 50 triệu dòng thì phân vùng tháng theo `created_at`; bổ sung khối kiểm ở bản 0.2 |

: Câu hỏi mở của tập CSDL PH-17

## 10. Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

### 10.1. Đồng bộ với FRS

Tập này không sửa FRS. Các điểm lệch nhỏ sau là đề nghị cho chủ tài liệu.

| Số | Nội dung | Đề nghị |
|---|---|---|
| 1 | Chín bảng không có mã EN: `tenant_setting`, `inbox_event`, `provider_commitment`, `tenant_model`, `model_breaker`, `knowledge_deletion`, `explanation`, `suggested_question`, `link_allowlist` | FRS 4.2 cấp mã EN mới liền sau EN-17-39 cho chín bảng; `COMMENT ON TABLE` các bảng này hiện ghi "Bổ sung" (đã hấp thụ FRS 0.2)
| 2 | EN-17-28 `EvalSet` gộp bảng liên kết `eval_dataset_link`; EN-17-39 gộp `Outbox`, `FileObject` | Tách EN-17-28 thành hai, EN-17-39 thành hai nếu cần ánh xạ một-một (không nhận ở FRS 0.2, xem Phụ lục C)
| 3 | `23514` (CHECK) và `55000` (trigger bất biến, máy trạng thái) là mã lỗi CSDL; API ánh xạ sang ERR-17 ở D03-04-PH17 | Ghi bảng ánh xạ mã SQLSTATE sang ERR-17 vào FRS 9.1 hoặc D03-02 (không nhận ở FRS 0.2, xem Phụ lục C)
| 4 | Ràng buộc hạ mức đối với khóa tham số `17.redteam.min-pass-rate` (sàn 100) và `17.log.retention-days` (sàn 90) có sàn cứng ở CSDL | FRS 8.2 ghi rõ "sàn không thương lượng" cho hai khóa này (đã có ở FRS 8.2)
| 5 | 31 cột có tập giá trị cố định chưa có enum ở Phụ lục A (ví dụ `file_object.scan_status`, `knowledge_source.source_state`, `eval_run.trigger_kind`, `redteam_case.origin`, `log_access_grant.scope_kind`, `quality_metric.metric_code`); `check_frs.py` liệt kê đủ | Thêm các enum vào Phụ lục A hoặc xác nhận là giá trị nội bộ của thiết kế (đã hấp thụ FRS 0.2)
| 6 | `PromptVersionStatus` ở FRS có `ACTIVE` nhưng `ModelVersionStatus` không; trigger cổng chỉ dẫn `ACTIVE`, cổng mô hình `APPROVED` | Ghi rõ ở FRS 4.3 rằng mô hình `APPROVED` là đã dùng được, không có bước `ACTIVE` (đã hấp thụ FRS 0.2)

: Đồng bộ với FRS

### 10.2. Đồng bộ tài liệu chung

Người điều phối chạy lại `kiem_tra_ma.py --cap-nhat-so-tra-cuu` để D00-04 có Q17-50…56 và bảng `ph17_assist`. D02-07 ghi nhận ngoại lệ cột `vector(1024)` có điều kiện và `real[]` dự phòng cho CI (FRS Phụ lục B). D03-09 thêm RPO 5 phút, RTO 30 phút và vai `ph17_infer`. D03-10 ghi `ph17_assist` là schema dùng ba mẫu RLS (`tenant`, `COMMON`, `user`), có dòng `COMMON`. D02-08 bổ sung `PERM-17-*` theo Phụ lục B của FRS.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-CSDL và K-TRINH-BAY: 50 bảng cho 39 thực thể, DDL và changelog chạy thử trên PostgreSQL 16.15, kiểm cô lập 182 khối PASS; ERD sáu nhóm; cột vector có điều kiện; bảy câu hỏi mở Q17-50…56 |

: Lịch sử phiên bản
