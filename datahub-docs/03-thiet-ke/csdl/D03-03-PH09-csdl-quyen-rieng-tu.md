---
ma_tai_lieu: D03-03-PH09
ten: Thiết kế cơ sở dữ liệu phân hệ PH-09 Quyền riêng tư
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, DBA, ATTT, hội đồng thẩm định
phan_he: PH-09
mo_ta: Thiết kế 55 bảng của schema ph09_privacy trên cụm pg-core cho phân loại dữ liệu, sổ hoạt động xử lý, mục đích và chấp thuận, chính sách che, giả danh hóa, ẩn danh hóa, lưu giữ, quyền chủ thể, đồng ý, DPIA và vi phạm dữ liệu cá nhân, gồm khóa, ràng buộc, RLS theo tenant, mã hóa envelope và băm HMAC, lưu giữ và ánh xạ thực thể, chức năng sang bảng, trích từ DDL đã chạy thử.
tai_lieu_lien_quan: D02-03-PH09 FRS; D03-02-PH09 SDD; D03-04-PH09 API; D03-10 Thiết kế đa tenant; D05-02-PH09 Test case
---

# D03-03-PH09 · Thiết kế CSDL Quyền riêng tư

## Tóm tắt cho hội đồng thẩm định

Schema `ph09_privacy` trên cụm `pg-core` có 55 bảng cho 51 thực thể EN-09-01…51 của [D02-03-PH09](../../02-yeu-cau/frs/D02-03-PH09-frs-quyen-rieng-tu.md) §4.2, cộng ba bảng con cần cho khóa ngoại (`purpose_element`, `retention_schedule_line`) và hai bảng thông điệp (`outbox_event`, `inbox_event`). PH-09 là nơi quản lý và nguồn thông tin chính sách (PAP, PIP) về dữ liệu cá nhân (DLCN): danh mục phân loại, sổ xử lý, mục đích và chấp thuận, chính sách che, miền giả danh, lịch lưu giữ, quyền chủ thể, đồng ý, đánh giá tác động, vi phạm. Vì chính nó là phân hệ bảo vệ dữ liệu nên thiết kế đặt hai nguyên tắc lên trước.

1. **Không lưu giá trị DLCN rõ, không có bảng ánh xạ bí danh.** Định danh chủ thể chỉ ở `*_enc` (mã hóa envelope bằng OpenBao transit, ADR-032) kèm `*_hash` (HMAC-SHA256 khóa theo tenant) để tra mà không giải mã; sổ vi phạm, đồng ý, giữ pháp lý chỉ giữ băm và số lượng; token hóa dùng giải mã transit nên không cần bảng (BR-09-030). Bài kiểm quét toàn schema và không thấy cột hay bảng tên giá trị rõ (§4.2).
2. **Cách ly tenant bằng `FORCE ROW LEVEL SECURITY` trên mọi bảng** kể cả hai bảng phân vùng tháng; vai `ph09_decide` của data plane `/privacy/v1` chỉ đọc chính sách và chỉ mục, không đọc định danh mã hóa, hồ sơ vi phạm, đề nghị khôi phục (NFR-09-019).

Hai điểm còn lại. Quy tắc nghiệp vụ trọng yếu khóa ngay ở CSDL: bốn mắt khi hạ mức phân loại, duyệt chính sách che, khôi phục giá trị gốc ba người, hủy khóa, xóa mật mã tenant; k ≥ 10; phiếu xem đầy đủ ≤ 60 giây; đồng hồ vi phạm đúng 72 giờ; phiên bản `ACTIVE` bất biến; nhật ký kiểm toán chỉ thêm (mục 1.4). DDL [`ph09/ddl/ph09_privacy.sql`](ph09/ddl/ph09_privacy.sql) chạy sạch trên PostgreSQL 16.15, bài kiểm [`ph09/test/ph09_isolation_test.sql`](ph09/test/ph09_isolation_test.sql) đạt 160 khối PASS (§4.2). Mục 8 ánh xạ thực thể và chức năng sang bảng; mục 9 nêu năm câu hỏi mở Q09-50…54 và đề nghị cho FRS.

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả CSDL của PH-09 ở mức đủ để DBA dựng schema, kỹ sư `dh-data` (package `vn.datahub.data.privacy`) viết tầng truy cập và kiểm thử viên viết ca cô lập tenant, bất biến, mã hóa. Phạm vi gồm 55 bảng của schema `ph09_privacy`, thủ tục, trigger, changelog Liquibase và bài kiểm cô lập. Ngoài phạm vi: nội dung bản tin đi qua (PH-09 không lưu), bundle và tệp mô phỏng, tập đã ẩn danh, bằng chứng gửi thông báo (Garage), khóa mật mã (OpenBao), nhật ký kiểm toán gốc (PH-13); các nơi này nêu ở chương 6.

Nguồn chuẩn là [`ph09/ddl/ph09_privacy.sql`](ph09/ddl/ph09_privacy.sql), sinh bằng `ph09/tools/sinh_ddl.py` từ danh mục bảng và Phụ lục A của FRS (nên enum không lệch FRS). Chương 2, 3, 8 sinh từ DDL bằng `gen_erd.py`, `gen_tables_md.py`, `them_dac_ta_bang.py`, `gen_anh_xa.py`.

### 0.2. Thuật ngữ và chữ viết tắt

Các thuật ngữ dưới đây dùng xuyên suốt tập.

| Thuật ngữ | Giải thích |
|---|---|
| PAP, PIP, PDP, PEP | Điểm quản lý chính sách, nguồn thông tin chính sách, điểm quyết định (OPA ở PH-12), điểm thực thi (APISIX, PH-04, PH-06, PH-14, PH-19); PH-09 là PAP và PIP |
| Mã hóa envelope | Dữ liệu mã hóa bằng khóa dữ liệu, khóa dữ liệu mã hóa bằng khóa trong OpenBao transit; `*_enc` giữ bản mã, `*_kid` giữ mã khóa (ADR-032) |
| `*_hash`, `subject_hash` | HMAC-SHA256 32 byte của giá trị đã chuẩn hóa, khóa riêng từng tenant; so bằng nhau mà không giải mã (BR-09-045) |
| Giả danh hóa, ẩn danh hóa | Thay định danh bằng bí danh (HMAC hoặc token) còn là DLCN; ẩn danh hóa đạt k ≥ 10 thì thôi là DLCN (FRS 4.1) |
| Bundle | Gói `purpose_grants`, `mask_policies`, `classification_index` đã ký cho OPA (FR-09-018) |
| FORCE RLS | Row Level Security lọc dòng theo `tenant_id = app.tenant_id`, áp cả với chủ bảng |
| DLCN, DSR | Dữ liệu cá nhân; yêu cầu của chủ thể dữ liệu (Data Subject Request) |

: Thuật ngữ và chữ viết tắt của tập CSDL PH-09

### 0.3. Tài liệu tham chiếu

Tập này dựa vào các tài liệu sau.

| Tài liệu | Nội dung dùng ở tập này |
|---|---|
| D02-03-PH09 FRS §4.2, §5, §7, §8.2, §9.1, §9.3, Phụ lục A | Thực thể EN-09-01…51, FR-09-001…064, BR-09, tham số `09.*`, ERR, EVT, enum |
| D03-04-PH09 API | Trường JSON camelCase ứng với cột snake_case |
| D03-07 ATTT §3.2, §6 | Bốn mức phân loại, vai trò kiểm soát, giả danh hóa HMAC, quyền chủ thể, vi phạm 72 giờ |
| D03-10 Thiết kế đa tenant; D00-01 §5.1 | Mẫu RLS, khóa ngoại kèm `tenant_id`, cột ngữ cảnh |
| ADR-003, 032, 034, 042, 046 | RLS, mã hóa trường, DR, outbox, bốn mắt; ADR 090…093 đề xuất ở FRS Phụ lục B |
| `docs/07-srs/SRS-PH-09-privacy.md` §4 | Sáu thực thể của SRS cũ (mục 8.3) |

: Tài liệu tham chiếu của tập CSDL PH-09

### 0.4. Người đọc

DBA, kỹ sư `dh-data`, ATTT và kiểm thử viên; hội đồng thẩm định đọc Tóm tắt, chương 1 và chương 9.

### 0.5. Cấu trúc tài liệu

Chương 1 chiến lược, 2 sơ đồ, 3 đặc tả bảng, 4 DDL, 5 dữ liệu khởi tạo, 6 kho ngoài, 7 sao lưu và lưu giữ, 8 ánh xạ, 9 câu hỏi mở.

## 1. Chiến lược lưu trữ

### 1.1. Schema, vai trò và kết nối

Schema `ph09_privacy` do `ph09_owner` (NOLOGIN) sở hữu. Control plane `/api/privacy/v1` kết nối bằng `dh_data_app`, thành viên `ph09_app`: chỉ DML, không `BYPASSRLS`, không `DELETE` trên đối tượng nghiệp vụ, không `UPDATE`, `DELETE` trên nhật ký kiểm toán. Data plane `/privacy/v1` (3 bản sao, mTLS) kết nối bằng `dh_decide_app`, thành viên `ph09_decide` (giả định GĐ-09-05: tách Deployment để quyết định không phụ thuộc tải của giao diện): đọc chính sách, chỉ mục phân loại, chấp thuận; đọc ba cột `subject_hash`, `restriction_active`; ghi `usage_counter` và chỉ thêm kiểm toán. Báo cáo dùng `ph09_readonly`, bị thu hồi quyền đọc nội dung thông báo vi phạm, phiếu xem đầy đủ và các cột mã hóa của phiếu chủ thể. Liquibase chạy bằng `dh_data_migrator` (thành viên `ph09_owner`).

`dh-data` không có khóa ngoại sang schema khác. Mã HTTT (`httt_id`, PH-01), tổ chức (`owner_org_id`), đăng ký sử dụng (`registration_ref`, PH-02) là chuỗi kiểm ở dịch vụ qua giao diện module; mã hợp đồng API, topic, luồng (`contract_id`) tham chiếu PH-02, PH-04, PH-10 theo cùng cách.

### 1.2. Cách ly tenant

Mọi bảng có `tenant_id varchar(16)` dạng `Tnn` và bật `FORCE ROW LEVEL SECURITY` qua `ph09_privacy.p_enable_rls(bảng)`: bốn chính sách đọc, chèn, sửa, xóa chỉ dòng có `tenant_id = current_setting('app.tenant_id')`. Không có dòng dùng chung `COMMON`: mỗi tenant được nạp bốn mức, 18 loại DLCN, mẫu phát hiện, cơ sở pháp lý, kiểu che và tham số bằng `p_seed_tenant` (chương 5). Chưa đặt `app.tenant_id` thì mọi truy vấn thấy 0 dòng.

Biến phiên `app.tenant_id` đặt đầu mỗi giao dịch từ ngữ cảnh xác thực, không từ tham số bên gọi (FR-00-010). Ba lớp chặn chéo tenant ngoài RLS: khóa ngoại luôn kèm `tenant_id` (đích có `UNIQUE (tenant_id, id)` hoặc `(tenant_id, code)`); mọi `*_hash` là HMAC theo khóa riêng từng tenant nên cùng một số định danh ở hai tỉnh cho hai băm khác nhau; xóa mật mã tenant (FR-09-043) hủy KEK `dh-{tenant}-pii` làm bản mã không đọc được dù còn dòng.

### 1.3. Quy ước bảng và ngoại lệ

Theo D00-01 §5.1 mọi bảng có `id uuid` (UUIDv7 sinh ở ứng dụng), `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (trigger `tg_touch`, khóa lạc quan, ETag). Mã nghiệp vụ có `CHECK` theo mẫu: mục đích, hoạt động, miền `^[A-Z][A-Z0-9-]{2,40}$`; loại DLCN, cơ sở pháp lý `^[A-Z][A-Z0-9_]{1,31}$`. Trạng thái và loại là `varchar` kèm `CHECK` liệt kê đúng giá trị Phụ lục A; thêm giá trị là một changeset mới sau khi sửa FRS. Đối tượng có phiên bản (`processing_activity`, `mask_policy`, `retention_schedule`, `consent_template`, `dpia_record`, `anonymization_config`) dùng chung chín cột vòng đời `version_no`, `status` (`VersionStatus`), `submitted_*`, `decided_*`, `activated_at`, `superseded_at`, một dòng `ACTIVE` mỗi mã, người duyệt khác người soạn. Cột `version` (ETag) và `version_no` (số phiên bản nghiệp vụ) là hai khái niệm khác nhau.

**Cột mã hóa và băm.** Định danh chủ thể, nội dung yêu cầu chỉ ở `x_enc bytea` (bản mã envelope, `CHECK` tối thiểu 29 byte) kèm `x_kid` (mã khóa OpenBao, để quay khóa); giá trị cần tra bằng nhau là `x_hash bytea` (32 byte, `CHECK`). Phiếu xem đầy đủ chỉ giữ `token_hash`; đề nghị khôi phục giữ `tokens_digest` của danh sách token chứ không giữ token.

| Bảng, cột | Ngoại lệ | Lý do |
|---|---|---|
| `usage_counter`, `privacy_audit_event` | Khóa chính `(id, cột thời gian)`, không `version`, không `updated_by`; kiểm toán không `created_*` | Phân vùng tháng; bộ đếm cộng dồn, nhật ký chỉ thêm |
| `outbox_event`, `inbox_event` | Khóa chính `event_id` hoặc `(tenant_id, consumer, event_id)`, không `version` | Bảng thông điệp |
| `risk_report.job_id`, `mask_policy.passed_simulation_id` | Cột cho phép rỗng; khóa ngoại thêm bằng `ALTER TABLE` ở bảng sau | Rủi ro có thể đo tập ngoài job; vòng chính sách và mô phỏng |
| `categories`, `legal_doc_ids`, `fields`, `allowed_categories` | Mảng, không khóa ngoại | Danh sách ngắn kiểm ở dịch vụ khi gửi duyệt (Q09-54) |

: Quy ước bảng và ngoại lệ

### 1.4. Quy tắc nghiệp vụ chốt ở CSDL

Các quy tắc sau do CSDL tự bảo đảm bằng ràng buộc, chỉ mục duy nhất, trigger hoặc quyền, để dù ứng dụng sai vẫn không ghi được dữ liệu vi phạm.

| Ràng buộc | Quy tắc | BR, FR |
|---|---|---|
| `ck_classification_change_four_eyes`, `_downgrade`, `_type_down` | Người đề xuất không tự xác nhận; hạ mức hoặc hạ loại DLCN từ SENSITIVE cần căn cứ và người xác nhận thứ hai khác hai người kia | BR-09-002, 003; FR-09-004 |
| `ck_element_classification_sensitive`, `_category`, `_direct` | Loại SENSITIVE kéo theo mức SENSITIVE; loại DLCN khác NONE phải có `category_code` | BR-09-001; FR-09-004 |
| `uq_block_label_active`, `ck_block_label_released` | Một nhãn STATE_SECRET hiệu lực mỗi đối tượng; gỡ cần văn bản giải mật và người khác | BR-09-005; FR-09-007 |
| `uq_processing_activity_active`, `tg_processing_activity_frozen`, `tg_activity_link_child_frozen`, `ck_processing_activity_retention` | Một phiên bản ACTIVE; không sửa tại chỗ, kể cả liên kết; phải có thời hạn lưu và hành động | BR-09-008, 011, 012; FR-09-009…011 |
| `uq_purpose_grant_live`, `ck_purpose_grant_period`, `_revoked`, `tg_purpose_grant_immutable` | Một chấp thuận hiệu lực mỗi bộ ba, không chuyển nhượng, tối đa 730 ngày, thu hồi cần lý do 20 ký tự | BR-09-013, 015; FR-09-016, 017 |
| `ck_access_request_four_eyes`, `_outcome` | Người lập không duyệt yêu cầu của mình; từ chối cần lý do 20 ký tự | BR-09-014; FR-09-016 |
| `ck_policy_bundle_published`, `_valid`, `_size` | Chỉ phát hành khi kiểm thử đạt, đã ký, `validUntil` ≤ 240 phút, ≤ 5 MB | BR-09-018; NFR-09-020 |
| `ck_mask_policy_simulated`, `_four_eyes`, `ck_mask_rule_sensitive` | Chính sách chỉ gửi duyệt khi mô phỏng đạt; duyệt bốn mắt; mức SENSITIVE không được kiểu NONE | BR-09-021, 023; FR-09-024…026 |
| `ck_reveal_grant_ttl`, `_reason`, `tg_reveal_grant_immutable` | Phiếu hết hạn ≤ 60 giây, không gia hạn; lý do ≥ 20 ký tự | BR-09-026; FR-09-029 |
| `ck_pseudonym_key_destroyed`, `uq_pseudonym_key_active`, `ck_reidentification_request_l1`, `_l2`, `_approved` | Hủy khóa hai người và chờ ≥ 7 ngày; mỗi miền một khóa ACTIVE; khôi phục ≤ 100 giá trị, ba người khác nhau, có MFA | BR-09-032, 033; FR-09-033, 034 |
| `ck_anonymization_config_k`, `ck_anonymization_job_done`, `ck_anonymized_dataset_published` | k ≥ 10; hoàn tất khi k thực tế ≥ 10; phát hành không HIGH, MEDIUM cần SO duyệt | BR-09-035; FR-09-035…039 |
| `ck_tenant_shred_request_approved`, `uq_tenant_shred_request_open` | Đã bàn giao dữ liệu, hai người duyệt, chờ ≥ 7 ngày; một đề nghị mở mỗi tenant | BR-09-041; FR-09-043 |
| `ck_subject_request_verified`, `uq_subject_request_idem`, `ck_subject_request_enc` | Chưa xác minh thì không xử lý; `Idempotency-Key` duy nhất; định danh chỉ ở bản mã | BR-09-042, 045, 061; FR-09-045 |
| `uq_consent_record_given`, `tg_consent_template_frozen` | Một đồng ý GIVEN mỗi (chủ thể, mẫu); nội dung mẫu ACTIVE bất biến | BR-09-050; FR-09-052, 053 |
| `ck_breach_case_clock`, `_notified`, `_not_breach` | Hạn đúng `detected_at` cộng 72 giờ, không đổi; NOTIFIED cần thông báo hoặc căn cứ miễn trừ | BR-09-054, 055; FR-09-058, 059 |
| `ck_outbox_event_no_value`, `ck_privacy_audit_event_no_value`, `tg_privacy_audit_event_append_only` | Sự kiện, kiểm toán không mang khóa giá trị; kiểm toán chỉ thêm | BR-09-025, 058; FR-09-061 |
| `ck_tenant_setting_key`, `_bounds` | Chỉ 36 khóa `09.*`; giá trị số trong sàn và trần của PA | BR-09-059; FR-09-064 |

: Quy tắc nghiệp vụ chốt ở CSDL

Quy tắc cần dữ liệu ngoài schema hoặc tính toán (mức hợp đồng từ RESTRICTED, HTTT ACTIVE ở PH-01, mỗi trường DLCN CONFIRMED thuộc một hoạt động ACTIVE, miền của tham số, giá trị `AnonTransform` trong `rules`) kiểm ở dịch vụ, ghi ở D03-02-PH09.

### 1.5. Ước lượng khối lượng (giả định)

Giả định theo GĐ-09-04 (tỉnh vừa, NFR-09-020): 200 HTTT, 3.000 chấp thuận hiệu lực, 50.000 phần tử dữ liệu, 2 triệu bản ghi kiểm toán mỗi tháng. Bảng lớn nhất là `usage_counter` (400 ngày, khoảng 100 triệu dòng, 18 GB), kế đó `privacy_audit_event` (13 tháng, khoảng 26 triệu dòng, 9 GB; Q09-51); nhóm phân loại 0,15 GB; `consent_record`, `subject_request` khoảng 0,3 GB; còn lại dưới 0,5 GB. Tổng khoảng 28 GB trực tuyến.

## 2. Sơ đồ thực thể – quan hệ

Sơ đồ chia sáu nhóm để đọc được trên trang A4; khóa ngoại đều kèm `tenant_id` nên không vẽ cột. Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic (§1.3). Sơ đồ sinh từ DDL bằng [`gen_erd.py`](ph09/tools/gen_erd.py).

<!-- gen:erd:start -->
Nhóm phân loại dữ liệu và quét phát hiện gồm 10 bảng (`data_class`, `block_label`, `personal_data_category`, `data_element`, `element_classification`, `classification_change`, `detector_rule`, `scan_run`, `scan_finding`, `contract_level`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic.

```{.mermaid caption="ERD nhóm phân loại dữ liệu và quét phát hiện"}
erDiagram
  data_element ||--o{ element_classification : "element_id"
  personal_data_category |o--o{ element_classification : "category_code"
  data_element ||--o{ classification_change : "element_id"
  scan_run ||--o{ scan_finding : "scan_id"
  data_element |o--o{ scan_finding : "element_id"
  data_element ||..o{ contract_level : "logic, contract_id"
  data_element ||..o{ block_label : "logic, target_id"
  data_class {
    uuid id PK
    varchar tenant_id
  }
  detector_rule {
    uuid id PK
    varchar tenant_id
  }
```

Nhóm sổ hoạt động xử lý, mục đích và chấp thuận gồm 12 bảng (`legal_document`, `legal_basis`, `processing_activity`, `activity_link`, `purpose`, `purpose_element`, `access_request`, `purpose_grant`, `grant_condition`, `policy_bundle`, `usage_counter`, `usage_anomaly`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic.

```{.mermaid caption="ERD nhóm sổ hoạt động xử lý, mục đích và chấp thuận"}
erDiagram
  legal_basis ||--o{ processing_activity : "legal_basis_code"
  processing_activity ||--o{ activity_link : "activity_id"
  legal_basis ||--o{ purpose : "legal_basis_code"
  purpose ||--o{ purpose_element : "purpose_id"
  data_element ||--o{ purpose_element : "element_id"
  purpose ||--o{ access_request : "purpose_code"
  access_request ||--o{ purpose_grant : "request_id"
  purpose ||--o{ purpose_grant : "purpose_code"
  purpose_grant ||--o{ grant_condition : "grant_id"
  purpose_grant |o--o{ usage_anomaly : "grant_id"
  data_element ||..o{ activity_link : "logic, target_id"
  purpose_grant ||..o{ usage_counter : "logic, bộ ba HTTT, mục đích, hợp đồng"
  purpose ||..o{ usage_counter : "logic, purpose_code"
  policy_bundle ||..o{ purpose_grant : "logic, bundle chứa chấp thuận"
  legal_document {
    uuid id PK
    varchar tenant_id
  }
```

Nhóm chính sách che, xem đầy đủ, log gồm 7 bảng (`mask_type`, `mask_policy`, `mask_rule`, `mask_simulation`, `reveal_grant`, `log_mask_config`, `leak_finding`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic.

```{.mermaid caption="ERD nhóm chính sách che, xem đầy đủ, log"}
erDiagram
  mask_policy ||--o{ mask_rule : "policy_id"
  mask_policy ||--o{ mask_simulation : "policy_id"
  mask_simulation |o--o{ mask_policy : "passed_simulation_id"
  mask_type {
    uuid id PK
    varchar tenant_id
  }
  reveal_grant {
    uuid id PK
    varchar tenant_id
  }
  log_mask_config {
    uuid id PK
    varchar tenant_id
  }
  leak_finding {
    uuid id PK
    varchar tenant_id
  }
```

Nhóm giả danh hóa và ẩn danh hóa gồm 7 bảng (`pseudonym_domain`, `pseudonym_key`, `reidentification_request`, `anonymization_config`, `anonymization_job`, `risk_report`, `anonymized_dataset`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic.

```{.mermaid caption="ERD nhóm giả danh hóa và ẩn danh hóa"}
erDiagram
  purpose ||--o{ pseudonym_domain : "purpose_code"
  pseudonym_domain ||--o{ pseudonym_key : "domain_id"
  pseudonym_domain ||--o{ reidentification_request : "domain_id"
  purpose ||--o{ reidentification_request : "purpose_code"
  purpose ||--o{ anonymization_config : "purpose_code"
  anonymization_config ||--o{ anonymization_job : "config_id"
  purpose ||--o{ anonymization_job : "purpose_code"
  anonymization_job |o--o{ risk_report : "job_id"
  anonymization_job ||--o{ anonymized_dataset : "job_id"
  risk_report ||--o{ anonymized_dataset : "risk_report_id"
  purpose ||--o{ anonymized_dataset : "purpose_code"
```

Nhóm lưu giữ, quyền chủ thể, đồng ý gồm 10 bảng (`retention_schedule`, `retention_schedule_line`, `retention_task`, `legal_hold`, `tenant_shred_request`, `subject_request`, `subject_verification`, `subject_task`, `consent_template`, `consent_record`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic.

```{.mermaid caption="ERD nhóm lưu giữ, quyền chủ thể, đồng ý"}
erDiagram
  retention_schedule ||--o{ retention_schedule_line : "schedule_id"
  retention_schedule ||--o{ retention_task : "schedule_id"
  retention_schedule_line |o--o{ retention_task : "line_id"
  subject_request ||--o{ subject_verification : "request_id"
  subject_request ||--o{ subject_task : "request_id"
  purpose ||--o{ consent_template : "purpose_code"
  consent_template ||--o{ consent_record : "template_id"
  legal_hold ||..o{ retention_task : "logic, hold_ids"
  subject_request ||..o{ legal_hold : "logic, băm chủ thể"
  subject_request ||..o{ consent_record : "logic, subject_hash"
  tenant_shred_request {
    uuid id PK
    varchar tenant_id
  }
```

Nhóm đánh giá tác động, vi phạm, giám sát gồm 9 bảng (`dpia_record`, `breach_case`, `breach_notification`, `breach_action`, `privacy_audit_event`, `compliance_report`, `tenant_setting`, `outbox_event`, `inbox_event`). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic.

```{.mermaid caption="ERD nhóm đánh giá tác động, vi phạm, giám sát"}
erDiagram
  processing_activity ||--o{ dpia_record : "activity_id"
  breach_case ||--o{ breach_notification : "case_id"
  breach_case ||--o{ breach_action : "case_id"
  breach_case ||..o{ privacy_audit_event : "logic, target_id"
  compliance_report {
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

<!-- gen:erd:end -->

Nhóm chính sách che và nhóm giả danh hóa gắn vào mục đích (`purpose`) chứ không gắn vào hoạt động xử lý: mỗi miền giả danh, cấu hình ẩn danh và mẫu đồng ý phải có một mục đích được duyệt, để hai tập xuất cho hai mục đích không nối được với nhau (BR-09-028). Nhóm quyền chủ thể tham chiếu bản ghi nơi khác (PH-06, PH-19) bằng `external_ref` và băm chủ thể, không bằng khóa ngoại.

## 3. Đặc tả bảng

Phần dưới sinh bằng [`gen_tables_md.py`](ph09/tools/gen_tables_md.py) và [`them_dac_ta_bang.py`](ph09/tools/them_dac_ta_bang.py) từ DDL; sửa ở DDL rồi sinh lại, không sửa tay. Mỗi bảng có khối đặc tả 10 mục và dòng cột (`v` là `varchar`, `tstz` là `timestamptz`, tên sau kiểu là enum Phụ lục A của FRS); chín cột ngữ cảnh chuẩn (§1.3) không liệt kê lại, hai bảng phân vùng không có cột sửa.

<!-- gen:tables:start -->
### 3.1. `data_class`

::: dac-ta
**Mục đích.** EN-09-01 Mức phân loại DD-08 (FR-09-001): PUBLIC, INTERNAL, RESTRICTED, SENSITIVE, thứ hạng 1 đến 4 theo bảng D03-07 3.2.

**FR phục vụ.** FR-09-001; EN-09-01.

**Khóa chính.** `id`.

**Duy nhất.** `uq_data_class_code` (tenant_id, code), `uq_data_class_rank` (tenant_id, rank).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_data_class_` + code, rank, log, display, sensitive.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `code`, `rank`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `log_policy` | `varchar(16)` | Cách ghi giá trị vào log vận hành (D03-07 3.2). |
| `encrypt_at_app` | `boolean, mặc định false` | Mã hóa envelope ở tầng ứng dụng (ADR-032). |

: Cột của bảng `data_class`

Cột khác: `code` v(16) DataClass; `rank` smallint; `name` v(100); `display_policy` v(16) {FULL, MASK_BY_ROLE, MASK_DEFAULT}.

### 3.2. `block_label`

::: dac-ta
**Mục đích.** EN-09-02 Nhãn chặn STATE_SECRET gắn vào phần tử hoặc hợp đồng (FR-09-007, BR-09-005).

**FR phục vụ.** FR-09-007; EN-09-02.

**Khóa chính.** `id`.

**Duy nhất.** `uq_block_label_active` (tenant_id, target_kind, target_id) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_block_label_` + label, target, release_req, released.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `target_kind`, `target_id`, `legal_doc`, `assigned_by`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `released_by` | `varchar(64), NULL` | Người duyệt gỡ, khác người đề nghị gỡ (BR-09-005). |

: Cột của bảng `block_label`

Cột khác: `label` v(16) BlockLabel; `target_kind` v(16) {ELEMENT, API, TOPIC, FLOW}; `target_id` v(128); `legal_doc` v(255); `assigned_by` v(64); `release_requested_by` v(64); `release_requested_at` tstz; `release_doc` v(255); `released_at` tstz.

### 3.3. `personal_data_category`

::: dac-ta
**Mục đích.** EN-09-03 Loại dữ liệu cá nhân (FR-09-002): 9 loại cơ bản và 9 loại nhạy cảm của Luật 91/2025, NĐ 356/2025, nạp sẵn; tenant thêm loại mới.

**FR phục vụ.** FR-09-002; EN-09-03.

**Khóa chính.** `id`.

**Duy nhất.** `uq_personal_data_category_code` (tenant_id, code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_personal_data_category_` + code, type, legal, class, pattern, ident, sensitive.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `code`, `builtin`.

**Ghi chú.** ETag là `version`.
:::

Cột: `code` v(32); `name` v(255); `personal_data_type` v(16) {BASIC, SENSITIVE}; `legal_ref` v(16); `default_class` v(16) DataClass; `default_mask_pattern` v(24) MaskPatternKind; `identifiability` v(16) IdentifiabilityType; `builtin` bool; `retired_at` tstz.

### 3.4. `data_element`

::: dac-ta
**Mục đích.** EN-09-04 Phần tử dữ liệu (trường) đăng ký từ phân hệ, lược đồ API, topic, khai báo MVP (FR-09-003, BR-09-007). target là tên đầy đủ (ph06_mdm.CITIZEN.nationalId) hoặc JSON Pointer.

**FR phục vụ.** FR-09-003; EN-09-04.

**Khóa chính.** `id`.

**Duy nhất.** `uq_data_element_target` (tenant_id, scope, target).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_data_element_` + scope, declared, source, status, retired.

**Chỉ mục.** `ix_data_element_owner`, `ix_data_element_contract`, `ix_data_element_target_trgm`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `scope`, `target`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `owner_org_id` | `varchar(63)` | Mã tổ chức ở PH-01 (không khóa ngoại, khác schema); chỉ TA, SO, DO của tổ chức này xác nhận (BR-09-003). |
| `declared_class` | `varchar(16), NULL` | Mức khai báo trong mã (@Classified, x-dh-classification) khi nhập MVP (FR-09-003). Enum `DataClass`. |

: Cột của bảng `data_element`

Cột khác: `scope` v(16) ElementScope; `target` v(512); `contract_ref` v(255); `source` v(16) ClassificationSource; `element_status` v(12) ElementStatus; `retired_at` tstz.

### 3.5. `element_classification`

::: dac-ta
**Mục đích.** EN-09-05 Phân loại hiện hành của phần tử, một dòng mỗi phần tử (DD-09, FR-09-004). Chưa CONFIRMED thì xử lý như SENSITIVE (BR-09-001).

**FR phục vụ.** FR-09-004; EN-09-05.

**Khóa chính.** `id`.

**Duy nhất.** `uq_element_classification_element` (tenant_id, element_id).

**Khóa ngoại.** (tenant_id, element_id) → `data_element`, (tenant_id, category_code) → `personal_data_category`.

**Ràng buộc CHECK.** `ck_element_classification_` + class, type, ident, pattern, status, source, category, sensitive, direct, confirmed.

**Chỉ mục.** `ix_element_classification_class`, `ix_element_classification_category`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `element_id`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `mask_pattern` | `varchar(24), NULL` | Mẫu che mặc định của trường (MaskPatternKind). Enum `MaskPatternKind`. |
| `never_reveal` | `boolean, mặc định false` | Trường không có đường xem đầy đủ (BR-09-026). |
| `basis` | `varchar(255), NULL` | Số văn bản căn cứ của phân loại. |

: Cột của bảng `element_classification`

Cột khác: `element_id` uuid; `data_class` v(16) DataClass; `personal_data_type` v(16) PersonalDataType; `category_code` v(32); `identifiability` v(16) IdentifiabilityType; `status` v(12) ClassificationStatus; `source` v(16) ClassificationSource; `confirmed_by` v(64); `confirmed_at` tstz.

### 3.6. `classification_change`

::: dac-ta
**Mục đích.** EN-09-06 Đề xuất, thay đổi phân loại (FR-09-004, 005, BR-09-002, 003, 007). Người xác nhận khác người đề xuất.

**FR phục vụ.** FR-09-004, 005; EN-09-06.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, element_id) → `data_element`.

**Ràng buộc CHECK.** `ck_classification_change_` + class, type, status, source, reason, four_eyes, confirmed, downgrade, type_down, rejected.

**Chỉ mục.** `ix_classification_change_element`, `ix_classification_change_open`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `element_id`, `from_class`, `to_class`, `proposed`, `proposed_by`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `proposed` | `jsonb` | Trạng thái phân loại đề xuất (dataClass, personalDataType, categoryCode, identifiability, maskPattern, neverReveal). |
| `confirmed_by_2` | `varchar(64), NULL` | Người xác nhận thứ hai khi hạ mức (BR-09-002). |

: Cột của bảng `classification_change`

Cột khác: `element_id` uuid; `from_class` v(16); `to_class` v(16) DataClass; `from_personal_data_type` v(16); `to_personal_data_type` v(16) PersonalDataType; `status` v(12) ClassificationStatus; `basis` v(255); `reason` v(2000); `proposed_by` v(64); `confirmed_by` v(64); `confirmed_at` tstz; `confirmed_at_2` tstz; `reject_comment` v(2000); `source` v(16) ClassificationSource.

### 3.7. `detector_rule`

::: dac-ta
**Mục đích.** EN-09-07 Mẫu phát hiện DLCN (FR-09-005, ADR đề xuất 093): số định danh 12 chữ số, mã số thuế, thẻ (Luhn), điện thoại, thư điện tử, mã BHXH, gợi ý theo tên trường.

**FR phục vụ.** FR-09-005; EN-09-07.

**Khóa chính.** `id`.

**Duy nhất.** `uq_detector_rule_code` (tenant_id, detector_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_detector_rule_` + code, threshold.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `detector_code`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `pattern` | `varchar(500)` | Biểu thức chính quy hoặc danh sách gợi ý tên trường; kiểm tổng (Luhn, mod 11) ở mã. |

: Cột của bảng `detector_rule`

Cột khác: `detector_code` v(24) DetectorType; `name` v(255); `has_checksum` bool; `confidence_threshold` numeric(3,2); `enabled` bool; `builtin` bool.

### 3.8. `scan_run`

::: dac-ta
**Mục đích.** EN-09-08 Lượt quét phát hiện trường nghi DLCN (FR-09-005, NFR-09-009): phạm vi, số dòng mẫu, mẫu phát hiện, trạng thái ScanStatus.

**FR phục vụ.** FR-09-005; EN-09-08.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_scan_run_` + rows, detectors, status, finished, error, failed, suspect.

**Chỉ mục.** `ix_scan_run_list`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `scope` | `jsonb` | Hệ thống, hợp đồng cần quét (FR-09-005). |

: Cột của bảng `scan_run`

Cột khác: `sample_rows` int; `detectors` v(24)[]; `status` v(12) ScanStatus; `requested_by` v(64); `started_at` tstz; `finished_at` tstz; `suspect_count` int; `error_code` v(10).

### 3.9. `scan_finding`

::: dac-ta
**Mục đích.** EN-09-09 Kết quả phát hiện một cột hoặc trường (FR-09-005, BR-09-006): mẫu khớp, độ tin cậy, trạng thái FindingStatus.

**FR phục vụ.** FR-09-005; EN-09-09.

**Khóa chính.** `id`.

**Duy nhất.** `uq_scan_finding_target` (tenant_id, scan_id, target, detector_code).

**Khóa ngoại.** (tenant_id, scan_id) → `scan_run`, (tenant_id, element_id) → `data_element`.

**Ràng buộc CHECK.** `ck_scan_finding_` + detector, confidence, status, resolved.

**Chỉ mục.** `ix_scan_finding_open`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `scan_id` uuid; `element_id` uuid; `target` v(512); `detector_code` v(24) DetectorType; `confidence` numeric(4,3); `hit_count` int; `status` v(16) FindingStatus; `resolved_by` v(64); `resolved_at` tstz; `resolution_note` v(2000).

### 3.10. `contract_level`

::: dac-ta
**Mục đích.** EN-09-10 Mức phân loại tính được của hợp đồng API, topic, luồng (FR-09-006, BR-09-001, 004): mức cao nhất của các trường; provisional khi còn phần tử chưa CONFIRMED (tạm SENSITIVE); blocked khi có nhãn STATE_SECRET.

**FR phục vụ.** FR-09-006; EN-09-10.

**Khóa chính.** `id`.

**Duy nhất.** `uq_contract_level_contract` (tenant_id, contract_kind, contract_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_contract_level_` + kind, class, count, provisional.

**Chỉ mục.** `ix_contract_level_class`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `basis` | `jsonb, NULL` | Phần tử quyết định mức (mã phần tử, không giá trị). |

: Cột của bảng `contract_level`

Cột khác: `contract_kind` v(8) ContractKind; `contract_id` v(128); `data_class` v(16) DataClass; `provisional` bool; `blocked` bool; `element_count` int; `computed_at` tstz.

### 3.11. `legal_document`

::: dac-ta
**Mục đích.** EN-09-14 Văn bản căn cứ (FR-09-012): loại, số, ngày ban hành, hiệu lực, liên kết CMP-LAW.

**FR phục vụ.** FR-09-012; EN-09-14.

**Khóa chính.** `id`.

**Duy nhất.** `uq_legal_document_number` (tenant_id, doc_type, number).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_legal_document_` + type, period, law.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `doc_type`, `number`.

**Ghi chú.** ETag là `version`.
:::

Cột: `doc_type` v(32); `number` v(64); `title` v(500); `issued_on` date; `effective_from` date; `effective_to` date; `cmp_law_code` v(16).

### 3.12. `legal_basis`

::: dac-ta
**Mục đích.** EN-09-13 Cơ sở pháp lý (FR-09-012, BR-09-009): bảy LegalBasisType nạp sẵn kèm quy tắc áp dụng.

**FR phục vụ.** FR-09-012; EN-09-13.

**Khóa chính.** `id`.

**Duy nhất.** `uq_legal_basis_code` (tenant_id, code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_legal_basis_` + code, type.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `code`, `basis_type`.

**Ghi chú.** ETag là `version`.
:::

Cột: `code` v(32); `basis_type` v(32) LegalBasisType; `name` v(255); `mandatory` bool; `rule` v(2000); `retired_at` tstz.

### 3.13. `processing_activity`

::: dac-ta
**Mục đích.** EN-09-11 Hoạt động xử lý DLCN theo phiên bản (FR-09-009, 010, BR-09-009…012): mục đích, cơ sở pháp lý chính, loại dữ liệu, nhóm chủ thể, bên nhận, thời hạn lưu (số tháng hoặc điều kiện kết thúc cùng hành động), vai trò, biện pháp.

**FR phục vụ.** FR-09-009, 010; EN-09-11.

**Khóa chính.** `id`.

**Duy nhất.** `uq_processing_activity_version` (tenant_id, code, version_no), `uq_processing_activity_active` (tenant_id, code) có điều kiện.

**Khóa ngoại.** (tenant_id, legal_basis_code) → `legal_basis`.

**Ràng buộc CHECK.** `ck_processing_activity_` + code, purpose, role, retention, lists, version, status, four_eyes, active, reject.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `code`, `version_no`; Trigger: `tg_processing_activity_frozen`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `legal_doc_ids` | `uuid[], mặc định '{}'` | Mã legal_document; mảng nên kiểm ở dịch vụ. |
| `categories` | `varchar(32)[]` | Mã loại DLCN (personal_data_category.code); kiểm tồn tại ở dịch vụ khi gửi duyệt. |
| `retention` | `jsonb` | {months, endCondition, action}, action là RetentionAction (BR-09-012). |

: Cột của bảng `processing_activity`

Cột khác: `code` v(41); `version_no` int; `status` v(20) VersionStatus; `submitted_by` v(64); `submitted_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `activated_at` tstz; `superseded_at` tstz; `purpose_text` v(1000); `legal_basis_code` v(32); `subject_groups` v(255)[]; `recipients` v(255)[]; `controller_role` v(20) ControllerRole; `measures` v(500)[].

### 3.14. `activity_link`

::: dac-ta
**Mục đích.** EN-09-12 Liên kết hoạt động xử lý với phần tử, API, topic hoặc luồng (FR-09-011, BR-09-008). Chỉ sửa khi hoạt động ở DRAFT hoặc REJECTED (trigger).

**FR phục vụ.** FR-09-011; EN-09-12.

**Khóa chính.** `id`.

**Duy nhất.** `uq_activity_link_target` (tenant_id, activity_id, target_kind, target_id).

**Khóa ngoại.** (tenant_id, activity_id) → `processing_activity`.

**Ràng buộc CHECK.** `ck_activity_link_` + kind.

**Chỉ mục.** `ix_activity_link_target`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Trigger: `tg_activity_link_child_frozen`.

**Ghi chú.** ETag là `version`.
:::

Cột: `activity_id` uuid; `target_kind` v(8) {ELEMENT, API, TOPIC, FLOW}; `target_id` v(128).

### 3.15. `purpose`

::: dac-ta
**Mục đích.** EN-09-15 Mục đích khai thác (FR-09-014, BR-09-015, 047): mã dạng TTHC-HO-TICH, THONG-KE, cơ sở pháp lý, loại DLCN được phép, cờ statutory (mục đích bắt buộc theo luật vẫn truy cập được khi chủ thể bị hạn chế), thời hạn tối đa.

**FR phục vụ.** FR-09-014; EN-09-15.

**Khóa chính.** `id`.

**Duy nhất.** `uq_purpose_code` (tenant_id, code).

**Khóa ngoại.** (tenant_id, legal_basis_code) → `legal_basis`.

**Ràng buộc CHECK.** `ck_purpose_` + code, days, status.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `code`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `max_days` | `integer, mặc định 365` | Trần cứng 730 ngày; trần tenant 09.grant.max-days mặc định 365 (BR-09-015). |

: Cột của bảng `purpose`

Cột khác: `code` v(41); `name` v(255); `description` v(2000); `legal_basis_code` v(32); `allowed_categories` v(32)[]; `statutory` bool; `status` v(8) ElementStatus.

### 3.16. `purpose_element`

::: dac-ta
**Mục đích.** EN-09-15 Trường được phép theo mục đích (FR-09-014, BR-09-016): phạm vi tối đa mà một chấp thuận của mục đích đó được bao.

**FR phục vụ.** FR-09-014; EN-09-15.

**Khóa chính.** `id`.

**Duy nhất.** `uq_purpose_element` (tenant_id, purpose_id, element_id).

**Khóa ngoại.** (tenant_id, purpose_id) → `purpose`, (tenant_id, element_id) → `data_element`.

**Ràng buộc CHECK.** Chỉ `ck_purpose_element_tenant`.

**Chỉ mục.** `ix_purpose_element_element`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `purpose_id` uuid; `element_id` uuid.

### 3.17. `access_request`

::: dac-ta
**Mục đích.** EN-09-16 Yêu cầu khai thác của HTTT cho một mục đích (FR-09-015, 016, BR-09-013, 014, 016).

**FR phục vụ.** FR-09-015, 016; EN-09-16.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, purpose_code) → `purpose`.

**Ràng buộc CHECK.** `ck_access_request_` + kind, fields, volume, justification, status, decision, four_eyes, decided, outcome, submitted.

**Chỉ mục.** `ix_access_request_inbox`, `ix_access_request_httt`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `httt_id`, `purpose_code`, `contract_kind`, `contract_id`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `httt_id` | `varchar(63)` | Mã HTTT ở PH-01 (không khóa ngoại). |
| `registration_ref` | `varchar(63), NULL` | Đăng ký sử dụng ở PH-02. |
| `owner_org_id` | `varchar(63)` | Tổ chức chủ quản dữ liệu, đích hộp việc của DO. |

: Cột của bảng `access_request`

Cột khác: `purpose_code` v(41); `contract_kind` v(8) ContractKind; `contract_id` v(128); `fields` v(63)[]; `expected_volume` int; `requested_days` int; `justification` v(2000); `status` v(16) AccessRequestStatus; `submitted_at` tstz; `reviewer` v(64); `decision` v(24) AccessDecision; `decision_reason` v(2000); `decided_by` v(64); `decided_at` tstz; `due_at` tstz.

### 3.18. `purpose_grant`

::: dac-ta
**Mục đích.** EN-09-17 Chấp thuận khai thác: bộ ba (HTTT, mục đích, hợp đồng), không chuyển nhượng (BR-09-013, FR-09-016, 017).

**FR phục vụ.** FR-09-016, 017; EN-09-17.

**Khóa chính.** `id`.

**Duy nhất.** `uq_purpose_grant_live` (tenant_id, httt_id, purpose_code, contract_kind, contract_id) có điều kiện.

**Khóa ngoại.** (tenant_id, request_id) → `access_request`, (tenant_id, purpose_code) → `purpose`.

**Ràng buộc CHECK.** `ck_purpose_grant_` + kind, period, status, fields, quota, renew, suspended, revoked, expired.

**Chỉ mục.** `ix_purpose_grant_expiry`, `ix_purpose_grant_httt`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `request_id`, `httt_id`, `purpose_code`, `contract_kind`, `contract_id`, `approved_by`.

**Ghi chú.** ETag là `version`.
:::

Cột: `request_id` uuid; `httt_id` v(63); `purpose_code` v(41); `contract_kind` v(8) ContractKind; `contract_id` v(128); `valid_from` tstz; `valid_to` tstz; `status` v(12) GrantStatus; `fields` v(63)[]; `quota_per_day` int; `renew_count` smallint; `approved_by` v(64); `approved_at` tstz; `suspended_at` tstz; `suspend_reason` v(2000); `revoked_by` v(64); `revoked_at` tstz; `revoke_reason` v(2000); `expired_at` tstz; `expiry_notified_at` tstz.

### 3.19. `grant_condition`

::: dac-ta
**Mục đích.** EN-09-18 Điều kiện của chấp thuận (FR-09-016, BR-09-016): FIELD_SUBSET, DAILY_QUOTA, TIME_WINDOW, NO_EXPORT, MASK_REQUIRED, tham số jsonb.

**FR phục vụ.** FR-09-016; EN-09-18.

**Khóa chính.** `id`.

**Duy nhất.** `uq_grant_condition_type` (tenant_id, grant_id, condition_type).

**Khóa ngoại.** (tenant_id, grant_id) → `purpose_grant`.

**Ràng buộc CHECK.** `ck_grant_condition_` + type, params.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `grant_id` uuid; `condition_type` v(16) ConditionType; `params` jsonb.

### 3.20. `policy_bundle`

::: dac-ta
**Mục đích.** EN-09-19 Bundle purpose_grants, mask_policies, classification_index đã ký (FR-09-018, BR-09-018): băm nội dung, chữ ký bằng khóa transit không xuất được, validUntil = phát hành cộng 60 phút mặc định, kết quả kiểm thử.

**FR phục vụ.** FR-09-018; EN-09-19.

**Khóa chính.** `id`.

**Duy nhất.** `uq_policy_bundle_no` (tenant_id, bundle_no).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_policy_bundle_` + hash, size, published, valid.

**Chỉ mục.** `ix_policy_bundle_published`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `bundle_no`, `content_hash`, `object_ref`.

**Ghi chú.** ETag là `version`.
:::

Cột: `bundle_no` bigint; `content_hash` bytea; `signature` bytea; `signing_key_ref` v(128); `object_ref` v(512); `size_bytes` int; `counts` jsonb; `test_passed` bool; `test_result` jsonb; `published_at` tstz; `valid_until` tstz.

### 3.21. `usage_counter`

::: dac-ta
**Mục đích.** EN-09-20 Bộ đếm khai thác theo (HTTT, mục đích, hợp đồng, phút) do điểm thực thi báo (FR-09-019, 020, BR-09-020).

**FR phục vụ.** FR-09-019, 020; EN-09-20.

**Khóa chính.** (id, bucket_at).

**Duy nhất.** `uq_usage_counter_key` (tenant_id, httt_id, purpose_code, contract_kind, contract_id, reporter, bucket_at).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_usage_counter_` + kind, minute, counts.

**Chỉ mục.** `ix_usage_counter_purpose`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Phân vùng tháng theo `bucket_at`.

**Ghi chú.** Không có `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `reporter` | `varchar(64)` | Điểm thực thi báo số đếm (APISIX, PH-04, PH-06, PH-14, PH-19). |

: Cột của bảng `usage_counter`

Cột khác: `id` uuid; `tenant_id` v(16); `bucket_at` tstz; `httt_id` v(63); `purpose_code` v(41); `contract_kind` v(8) ContractKind; `contract_id` v(128); `allowed_count` int; `denied_count` int; `off_purpose_count` int; `updated_at` tstz, phân vùng `RANGE (bucket_at)`.

### 3.22. `usage_anomaly`

::: dac-ta
**Mục đích.** EN-09-21 Cảnh báo khai thác bất thường (FR-09-020, THR-51): AnomalyType, mức RiskLevel, trạng thái AnomalyStatus; phát hiện trong 5 phút (BR-09-020).

**FR phục vụ.** FR-09-020; EN-09-21.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, grant_id) → `purpose_grant`.

**Ràng buộc CHECK.** `ck_usage_anomaly_` + type, severity, status, kind, window, handled.

**Chỉ mục.** `ix_usage_anomaly_open`, `ix_usage_anomaly_httt`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `anomaly_type` v(16) AnomalyType; `severity` v(8) RiskLevel; `status` v(16) AnomalyStatus; `httt_id` v(63); `purpose_code` v(41); `contract_kind` v(8) ContractKind; `contract_id` v(128); `grant_id` uuid; `detected_at` tstz; `window_from` tstz; `window_to` tstz; `observed` bigint; `threshold` bigint; `handled_by` v(64); `handled_at` tstz; `handle_note` v(2000).

### 3.23. `mask_type`

::: dac-ta
**Mục đích.** EN-09-22 Kiểu che MaskType và mẫu che MaskPatternKind có tham số (FR-09-023, BR-09-021, 024): NONE, PARTIAL (KEEP_*), REPLACE, KEYED_HASH, TOKENIZE, GENERALIZE (YEAR_ONLY, ADMIN_LEVEL), DROP.

**FR phục vụ.** FR-09-023; EN-09-22.

**Khóa chính.** `id`.

**Duy nhất.** `uq_mask_type_code` (tenant_id, code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_mask_type_` + type, pattern, pairing, reversible.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `code`, `mask_type`, `pattern_kind`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `default_params` | `jsonb, mặc định '{}'` | Tham số mặc định n, m, char, level (FR-09-023). |

: Cột của bảng `mask_type`

Cột khác: `code` v(48); `mask_type` v(12) MaskType; `pattern_kind` v(24) MaskPatternKind; `name` v(255); `reversible` bool; `builtin` bool.

### 3.24. `mask_policy`

::: dac-ta
**Mục đích.** EN-09-23 Chính sách che theo phiên bản (FR-09-024, 026, BR-09-022, 023): phạm vi TENANT hoặc CONTRACT.

**FR phục vụ.** FR-09-024, 026; EN-09-23.

**Khóa chính.** `id`.

**Duy nhất.** `uq_mask_policy_version` (tenant_id, policy_code, version_no), `uq_mask_policy_active` (tenant_id, policy_code) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_mask_policy_` + code, scope, kind, simulated, version, status, four_eyes, active, reject.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `policy_code`, `version_no`, `scope`, `contract_id`; Trigger: `tg_mask_policy_frozen`.

**Ghi chú.** ETag là `version`.
:::

Cột: `policy_code` v(63); `version_no` int; `status` v(20) VersionStatus; `submitted_by` v(64); `submitted_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `activated_at` tstz; `superseded_at` tstz; `scope` v(8) {TENANT, CONTRACT}; `contract_kind` v(8) ContractKind; `contract_id` v(128); `description` v(2000); `passed_simulation_id` uuid.

### 3.25. `mask_rule`

::: dac-ta
**Mục đích.** EN-09-24 Quy tắc che trong chính sách (FR-09-024, BR-09-021, 022): điều kiện (mức, loại DLCN, vai trò, mục đích, kênh), kiểu che, tham số, độ ưu tiên; quy tắc cụ thể hơn thắng, trùng thì kiểu chặt hơn thắng.

**FR phục vụ.** FR-09-024; EN-09-24.

**Khóa chính.** `id`.

**Duy nhất.** `uq_mask_rule_seq` (tenant_id, policy_id, seq).

**Khóa ngoại.** (tenant_id, policy_id) → `mask_policy`.

**Ràng buộc CHECK.** `ck_mask_rule_` + priority, class, channel, type, pattern, pairing, sensitive.

**Chỉ mục.** `ix_mask_rule_policy`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Trigger: `tg_mask_rule_child_frozen`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `cond_roles` | `varchar(16)[], NULL` | Mã vai trò viết tắt (PA, TA, DS, VW...); rỗng là mọi vai trò. |

: Cột của bảng `mask_rule`

Cột khác: `policy_id` uuid; `seq` smallint; `priority` smallint; `cond_class` v(16) DataClass; `cond_category` v(32); `cond_purpose` v(41); `cond_channel` v(8) MaskChannel; `mask_type` v(12) MaskType; `pattern_kind` v(24) MaskPatternKind; `params` jsonb.

### 3.26. `mask_simulation`

::: dac-ta
**Mục đích.** EN-09-25 Lần mô phỏng chính sách che trên bộ mẫu dữ liệu giả ≤ 1.000 dòng (FR-09-025, NFR-09-023): bộ mẫu ở Garage, kết quả tóm tắt, passed.

**FR phục vụ.** FR-09-025; EN-09-25.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, policy_id) → `mask_policy`.

**Ràng buộc CHECK.** `ck_mask_simulation_` + rows, channel.

**Chỉ mục.** `ix_mask_simulation_policy`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `policy_id`, `policy_version`, `sample_ref`, `passed`.

**Ghi chú.** ETag là `version`.
:::

Cột: `policy_id` uuid; `policy_version` int; `sample_ref` v(512); `sample_rows` int; `role` v(16); `purpose_code` v(41); `channel` v(8) MaskChannel; `result` jsonb; `passed` bool; `run_by` v(64); `run_at` tstz.

### 3.27. `reveal_grant`

::: dac-ta
**Mục đích.** EN-09-26 Phiếu xem giá trị đầy đủ (FR-09-029, BR-09-026): người xin, đối tượng, trường, lý do ≥ 20 ký tự, hết hạn đúng ≤ 60 giây, tối đa 20 lần mỗi giờ.

**FR phục vụ.** FR-09-029; EN-09-26.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_reveal_grant_` + reason, status, ttl, fields, hash, verified.

**Chỉ mục.** `ix_reveal_grant_user`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `requested_by`, `target_ref`, `fields`, `reason`, `issued_at`, `expires_at`, `token_hash`.

**Ghi chú.** ETag là `version`.
:::

Cột: `requested_by` v(64); `target_ref` v(255); `fields` v(63)[]; `reason` v(2000); `status` v(8) RevealStatus; `issued_at` tstz; `expires_at` tstz; `verified_at` tstz; `token_hash` bytea.

### 3.28. `log_mask_config`

::: dac-ta
**Mục đích.** EN-09-27 Cấu hình che log, trace (FR-09-030, SEC-32): danh sách thuộc tính được phép, mẫu quét, cửa sổ quét. Một dòng mỗi tenant.

**FR phục vụ.** FR-09-030; EN-09-27.

**Khóa chính.** `id`.

**Duy nhất.** `uq_log_mask_config_tenant` (tenant_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_log_mask_config_` + patterns, window.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `allow_attributes` v(63)[]; `patterns` v(24)[]; `scan_window_hours` smallint.

### 3.29. `leak_finding`

::: dac-ta
**Mục đích.** EN-09-28 Kết quả quét rò rỉ DLCN trong log, trace (FR-09-030, NFR-09-014): nguồn, mẫu khớp, số lần, dấu vân HMAC của vị trí. Không lưu đoạn log khớp.

**FR phục vụ.** FR-09-030; EN-09-28.

**Khóa chính.** `id`.

**Duy nhất.** `uq_leak_finding_fp` (tenant_id, source, detector_code, fingerprint).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_leak_finding_` + detector, status, count, resolved.

**Chỉ mục.** `ix_leak_finding_open`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `source` v(128); `detector_code` v(24) DetectorType; `match_count` int; `fingerprint` bytea; `first_seen_at` tstz; `last_seen_at` tstz; `status` v(16) FindingStatus; `resolved_by` v(64); `resolved_at` tstz.

### 3.30. `pseudonym_domain`

::: dac-ta
**Mục đích.** EN-09-29 Miền giả danh hóa theo tenant và mục đích (FR-09-031, BR-09-028, 031): phương pháp PseudonymMethod, chu kỳ xoay 90 đến 730 ngày, trạng thái.

**FR phục vụ.** FR-09-031; EN-09-29.

**Khóa chính.** `id`.

**Duy nhất.** `uq_pseudonym_domain_code` (tenant_id, domain_code).

**Khóa ngoại.** (tenant_id, purpose_code) → `purpose`.

**Ràng buộc CHECK.** `ck_pseudonym_domain_` + code, method, rotate, status, version.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_code`, `purpose_code`, `method`, `key_name`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `key_name` | `varchar(128)` | Tên khóa transit OpenBao dh-{tenant}-pseudo-{miền}; không chứa vật liệu khóa. |

: Cột của bảng `pseudonym_domain`

Cột khác: `domain_code` v(41); `purpose_code` v(41); `method` v(16) PseudonymMethod; `rotate_days` smallint; `description` v(2000); `status` v(12) PseudonymDomainStatus; `current_key_version` int; `last_rotated_at` tstz.

### 3.31. `pseudonym_key`

::: dac-ta
**Mục đích.** EN-09-30 Siêu dữ liệu phiên bản khóa giả danh hóa (FR-09-034, BR-09-029, 033): ACTIVE, DECRYPT_ONLY, DISABLED, DESTROYED. Không chứa vật liệu khóa.

**FR phục vụ.** FR-09-034; EN-09-30.

**Khóa chính.** `id`.

**Duy nhất.** `uq_pseudonym_key_version` (tenant_id, domain_id, key_version), `uq_pseudonym_key_active` (tenant_id, domain_id) có điều kiện.

**Khóa ngoại.** (tenant_id, domain_id) → `pseudonym_domain`.

**Ràng buộc CHECK.** `ck_pseudonym_key_` + version, status, ref, destroyed, disabled.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_id`, `key_version`, `openbao_ref`.

**Ghi chú.** ETag là `version`.
:::

Cột: `domain_id` uuid; `key_version` int; `status` v(12) KeyVersionStatus; `openbao_ref` v(255); `activated_at` tstz; `disabled_at` tstz; `destroy_requested_by` v(64); `destroy_approved_by` v(64); `destroy_not_before` tstz; `destroyed_at` tstz; `reason` v(2000).

### 3.32. `reidentification_request`

::: dac-ta
**Mục đích.** EN-09-31 Đề nghị khôi phục giá trị gốc từ token (FR-09-033, BR-09-032, 057): ≤ 100 giá trị, mục đích, căn cứ, MFA, hai cấp duyệt khác nhau và khác người đề nghị, hạn duyệt 24 giờ, cửa sổ thực hiện 30 phút.

**FR phục vụ.** FR-09-033; EN-09-31.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, domain_id) → `pseudonym_domain`, (tenant_id, purpose_code) → `purpose`.

**Ràng buộc CHECK.** `ck_reidentification_request_` + count, reason, status, l1, l2, approved, executed, rejected.

**Chỉ mục.** `ix_reidentification_request_open`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `domain_id`, `token_count`, `tokens_digest`, `purpose_code`, `basis`, `requested_by`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `tokens_digest` | `bytea` | Băm SHA-256 danh sách token để đối chiếu khi thực hiện; không lưu token. |

: Cột của bảng `reidentification_request`

Cột khác: `domain_id` uuid; `token_count` smallint; `purpose_code` v(41); `basis` v(500); `reason` v(2000); `status` v(12) ReidStatus; `requested_by` v(64); `mfa_verified` bool; `l1_by` v(64); `l1_at` tstz; `l2_by` v(64); `l2_at` tstz; `approval_expires_at` tstz; `exec_deadline_at` tstz; `executed_by` v(64); `executed_at` tstz; `reject_reason` v(2000).

### 3.33. `anonymization_config`

::: dac-ta
**Mục đích.** EN-09-32 Cấu hình ẩn danh hóa theo phiên bản (FR-09-035, BR-09-035, 036): k ≥ 10 (sàn 09.anon.k-min, SEC-38), l-đa dạng tùy chọn, quy tắc theo trường với AnonTransform, phân cấp tổng quát hóa, mục đích.

**FR phục vụ.** FR-09-035; EN-09-32.

**Khóa chính.** `id`.

**Duy nhất.** `uq_anonymization_config_version` (tenant_id, config_code, version_no), `uq_anonymization_config_active` (tenant_id, config_code) có điều kiện.

**Khóa ngoại.** (tenant_id, purpose_code) → `purpose`.

**Ràng buộc CHECK.** `ck_anonymization_config_` + code, model, k, l, rules, version, status, four_eyes, active, reject.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `config_code`, `version_no`; Trigger: `tg_anonymization_config_frozen`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `rules` | `jsonb` | Mảng {field, transform, params}; transform là AnonTransform (kiểm ở dịch vụ khi gửi duyệt). |

: Cột của bảng `anonymization_config`

Cột khác: `config_code` v(41); `version_no` int; `status` v(20) VersionStatus; `submitted_by` v(64); `submitted_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `activated_at` tstz; `superseded_at` tstz; `privacy_model` v(16) PrivacyModel; `k` smallint; `l` smallint; `hierarchies` jsonb; `purpose_code` v(41).

### 3.34. `anonymization_job`

::: dac-ta
**Mục đích.** EN-09-33 Job ẩn danh hóa (FR-09-036, 038, BR-09-034, 035): tập nguồn, cấu hình, trạng thái AnonJobStatus, số bản ghi trước và sau (còn ≥ 30%), k thực tế, tối đa 3 vòng tổng quát hóa.

**FR phục vụ.** FR-09-036, 038; EN-09-33.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, config_id) → `anonymization_config`, (tenant_id, purpose_code) → `purpose`.

**Ràng buộc CHECK.** `ck_anonymization_job_` + target, status, rows, keep, rounds, k, done, error.

**Chỉ mục.** `ix_anonymization_job_status`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `config_id` uuid; `source_ref` v(512); `purpose_code` v(41); `target` v(16) DataPrepTarget; `status` v(24) AnonJobStatus; `requested_by` v(64); `rows_before` bigint; `rows_after` bigint; `k_actual` smallint; `generalization_rounds` smallint; `output_ref` v(512); `started_at` tstz; `finished_at` tstz; `error_code` v(10).

### 3.35. `risk_report`

::: dac-ta
**Mục đích.** EN-09-34 Báo cáo rủi ro tái định danh (FR-09-037, BR-09-035): mô hình RiskModel, kActual, tỷ lệ nhóm nhỏ, mức RiskLevel (MEDIUM từ 0,05, HIGH từ 0,10 mặc định), trường gây rủi ro, khuyến nghị.

**FR phục vụ.** FR-09-037; EN-09-34.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, job_id) → `anonymization_job`.

**Ràng buộc CHECK.** `ck_risk_report_` + model, level, ratio, approval.

**Chỉ mục.** `ix_risk_report_job`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `job_id` uuid; `dataset_ref` v(512); `risk_model` v(12) RiskModel; `quasi_identifiers` v(63)[]; `k_actual` smallint; `small_group_ratio` numeric(6,5); `risk_value` numeric(6,5); `level` v(8) RiskLevel; `risk_fields` v(63)[]; `recommendation` v(2000); `computed_at` tstz; `approved_by` v(64); `approved_at` tstz.

### 3.36. `anonymized_dataset`

::: dac-ta
**Mục đích.** EN-09-35 Tập đã ẩn danh (FR-09-038, 039, BR-09-034, 035, 037): vị trí lưu, mục đích, điều kiện sử dụng (mục đích được phép, bên nhận, cấm tái định danh), hạn dùng, DatasetStatus.

**FR phục vụ.** FR-09-038, 039; EN-09-35.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, job_id) → `anonymization_job`, (tenant_id, risk_report_id) → `risk_report`, (tenant_id, purpose_code) → `purpose`.

**Ràng buộc CHECK.** `ck_anonymized_dataset_` + target, status, risk, terms, published, withdrawn.

**Chỉ mục.** `ix_anonymized_dataset_status`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `job_id`, `storage_ref`, `k_actual`.

**Ghi chú.** ETag là `version`.
:::

Cột: `job_id` uuid; `risk_report_id` uuid; `name` v(255); `storage_ref` v(512); `purpose_code` v(41); `target` v(16) DataPrepTarget; `terms` jsonb; `k_actual` smallint; `risk_level` v(8) RiskLevel; `approved_by` v(64); `status` v(10) DatasetStatus; `expires_on` date; `published_at` tstz; `withdrawn_at` tstz; `withdraw_reason` v(2000).

### 3.37. `retention_schedule`

::: dac-ta
**Mục đích.** EN-09-36 Lịch lưu giữ theo phiên bản (FR-09-040, BR-09-038): mỗi dòng ở retention_schedule_line. ACTIVE không sửa; duyệt bốn mắt.

**FR phục vụ.** FR-09-040; EN-09-36.

**Khóa chính.** `id`.

**Duy nhất.** `uq_retention_schedule_version` (tenant_id, schedule_code, version_no), `uq_retention_schedule_active` (tenant_id, schedule_code) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_retention_schedule_` + code, version, status, four_eyes, active, reject.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `schedule_code`, `version_no`.

**Ghi chú.** ETag là `version`.
:::

Cột: `schedule_code` v(41); `version_no` int; `status` v(20) VersionStatus; `submitted_by` v(64); `submitted_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `activated_at` tstz; `superseded_at` tstz; `description` v(2000).

### 3.38. `retention_schedule_line`

::: dac-ta
**Mục đích.** EN-09-36 Dòng lịch lưu giữ (FR-09-040): bảng hoặc loại dữ liệu, loại DLCN, số ngày lưu, hành động RetentionAction, người chịu trách nhiệm.

**FR phục vụ.** FR-09-040; EN-09-36.

**Khóa chính.** `id`.

**Duy nhất.** `uq_retention_schedule_line` (tenant_id, schedule_id, entity, COALESCE(category, '*')).

**Khóa ngoại.** (tenant_id, schedule_id) → `retention_schedule`.

**Ràng buộc CHECK.** `ck_retention_schedule_line_` + days, action.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Trigger: `tg_retention_schedule_line_child_frozen`.

**Ghi chú.** ETag là `version`.
:::

Cột: `schedule_id` uuid; `entity` v(128); `category` v(32); `retain_days` int; `action` v(12) RetentionAction; `owner` v(64).

### 3.39. `retention_task`

::: dac-ta
**Mục đích.** EN-09-37 Tác vụ xóa hoặc giả danh hóa khi hết hạn (FR-09-041, 044, NFR-09-018): phạm vi, số bản ghi quét, xử lý, bỏ qua do giữ pháp lý (kèm hold_ids), kết quả.

**FR phục vụ.** FR-09-041, 044; EN-09-37.

**Khóa chính.** `id`.

**Duy nhất.** `uq_retention_task_run` (tenant_id, schedule_id, COALESCE(line_id, '00000000-0000-0000-0000-000000000000'::uuid), run_date) có điều kiện.

**Khóa ngoại.** (tenant_id, schedule_id) → `retention_schedule`, (tenant_id, line_id) → `retention_schedule_line`.

**Ràng buộc CHECK.** `ck_retention_task_` + status, rows, hold, finished, error.

**Chỉ mục.** `ix_retention_task_status`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `schedule_id` uuid; `line_id` uuid; `entity` v(128); `run_date` date; `dry_run` bool; `status` v(12) ScanStatus; `requested_by` v(64); `started_at` tstz; `finished_at` tstz; `rows_scanned` bigint; `rows_affected` bigint; `rows_skipped_hold` bigint; `hold_ids` uuid[]; `skipped_reason` v(2000); `error_code` v(10).

### 3.40. `legal_hold`

::: dac-ta
**Mục đích.** EN-09-38 Giữ pháp lý, tạm hoãn xóa (FR-09-042, BR-09-039): phạm vi (băm chủ thể, bảng, khoảng thời gian), số văn bản, cơ quan, ngày rà soát, LegalHoldStatus.

**FR phục vụ.** FR-09-042; EN-09-38.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_legal_hold_` + scope, status, review, released.

**Chỉ mục.** `ix_legal_hold_active`, `ix_legal_hold_scope`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `scope`, `basis_doc`, `basis_date`, `authority`, `placed_by`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `scope` | `jsonb` | {subjectHashes[], entities[], from, to}; chỉ băm chủ thể, không định danh rõ. |

: Cột của bảng `legal_hold`

Cột khác: `basis_doc` v(255); `basis_date` date; `authority` v(255); `review_on` date; `status` v(8) LegalHoldStatus; `placed_by` v(64); `released_by` v(64); `released_at` tstz; `release_reason` v(2000).

### 3.41. `tenant_shred_request`

::: dac-ta
**Mục đích.** EN-09-39 Đề nghị xóa mật mã tenant, hủy KEK dh-{tenant}-pii (FR-09-043, BR-09-041, 033): chỉ sau bàn giao dữ liệu theo PH-20, hai người duyệt khác nhau và khác người đề nghị, chờ ≥ 7 ngày, không hoàn tác.

**FR phục vụ.** FR-09-043; EN-09-39.

**Khóa chính.** `id`.

**Duy nhất.** `uq_tenant_shred_request_open` (tenant_id) có điều kiện.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_tenant_shred_request_` + status, reason, approvers, approved, executed, cancelled.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `requested_by`, `reason`.

**Ghi chú.** ETag là `version`.
:::

Cột: `status` v(10) CryptoShredStatus; `export_confirmed` bool; `reason` v(2000); `requested_by` v(64); `approver_1` v(64); `approver_2` v(64); `approved_at` tstz; `wait_until` tstz; `executed_at` tstz; `kek_destroy_ref` v(255); `cancelled_by` v(64); `cancelled_at` tstz.

### 3.42. `subject_request`

::: dac-ta
**Mục đích.** EN-09-40 Yêu cầu của chủ thể dữ liệu (FR-09-045…050, BR-09-042…048, 061): loại DsrType, băm chủ thể HMAC theo khóa tenant, định danh và nội dung mã hóa envelope.

**FR phục vụ.** FR-09-045, 046, 047, 048, 049, 050; EN-09-40.

**Khóa chính.** `id`.

**Duy nhất.** `uq_subject_request_idem` (tenant_id, idempotency_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_subject_request_` + type, status, channel, idtype, hash, enc, due, verified, outcome, responded, refused, closed, rejected, restriction.

**Chỉ mục.** `ix_subject_request_inbox`, `ix_subject_request_subject`, `ix_subject_request_restricted`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `request_type`, `subject_hash`, `received_at`, `idempotency_key`, `identifier_enc`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `subject_hash` | `bytea` | HMAC-SHA256 số định danh đã chuẩn hóa, khóa theo tenant (BR-09-045); tra bản ghi của chủ thể ở PH-06, PH-19, PH-13, PH-14. |
| `identifier_enc` | `bytea` | Định danh rõ chỉ ở đây, mã hóa envelope (ADR-032). |
| `content_enc` | `bytea` | Nội dung yêu cầu ≤ 4.000 ký tự, mã hóa envelope. |
| `due_at` | `timestamptz` | Ngày làm việc theo 09.dsr.sla-days (Q09-02). |
| `overdue` | `boolean, mặc định false` | Cờ, không phải trạng thái (FRS 4.5). |

: Cột của bảng `subject_request`

Cột khác: `request_type` v(20) DsrType; `status` v(12) DsrStatus; `channel` v(16) DsrChannel; `identifier_type` v(24) SubjectIdentifierType; `identifier_kid` v(64); `content_kid` v(64); `idempotency_key` v(64); `received_at` tstz; `verified_at` tstz; `assigned_to` v(64); `outcome` v(10) DsrOutcome; `refusal_basis` v(500); `response_ref` v(512); `responded_at` tstz; `closed_at` tstz; `reject_reason` v(2000); `restriction_active` bool; `restriction_lifted_at` tstz.

### 3.43. `subject_verification`

::: dac-ta
**Mục đích.** EN-09-41 Kết quả xác minh danh tính chủ thể (FR-09-046, BR-09-042): phương pháp VerificationMethod, đạt hoặc không, bằng chứng chỉ lưu băm và tham chiếu Garage mã hóa.

**FR phục vụ.** FR-09-046; EN-09-41.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, request_id) → `subject_request`.

**Ràng buộc CHECK.** `ck_subject_verification_` + method, hash, evidence.

**Chỉ mục.** `ix_subject_verification_request`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `request_id`, `method`, `passed`.

**Ghi chú.** ETag là `version`.
:::

Cột: `request_id` uuid; `method` v(20) VerificationMethod; `passed` bool; `evidence_hash` bytea; `evidence_ref` v(512); `verified_by` v(64); `verified_at` tstz.

### 3.44. `subject_task`

::: dac-ta
**Mục đích.** EN-09-42 Tác vụ chuyển cho PH-06, PH-19, PH-13, PH-14 hoặc bên kiểm soát (FR-09-047, 048, BR-09-044, 046): đích DsrTarget, hành động theo DsrType, DsrTaskStatus.

**FR phục vụ.** FR-09-047, 048; EN-09-42.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, request_id) → `subject_request`.

**Ràng buộc CHECK.** `ck_subject_task_` + target, action, status, refused, done.

**Chỉ mục.** `ix_subject_task_request`, `ix_subject_task_open`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `request_id` uuid; `target` v(16) DsrTarget; `action` v(20) DsrType; `status` v(10) DsrTaskStatus; `assignee` v(64); `external_ref` v(255); `result` jsonb; `refusal_reason` v(2000); `done_at` tstz.

### 3.45. `consent_template`

::: dac-ta
**Mục đích.** EN-09-43 Mẫu sự đồng ý theo phiên bản (FR-09-052, BR-09-049): nội dung, mục đích, dữ liệu xử lý, hạn hiệu lực, cách rút. Nội dung bất biến khi ACTIVE.

**FR phục vụ.** FR-09-052; EN-09-43.

**Khóa chính.** `id`.

**Duy nhất.** `uq_consent_template_version` (tenant_id, template_code, version_no), `uq_consent_template_active` (tenant_id, template_code) có điều kiện.

**Khóa ngoại.** (tenant_id, purpose_code) → `purpose`.

**Ràng buộc CHECK.** `ck_consent_template_` + code, valid, body, version, status, four_eyes, active, reject.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `template_code`, `version_no`; Trigger: `tg_consent_template_frozen`.

**Ghi chú.** ETag là `version`.
:::

Cột: `template_code` v(41); `version_no` int; `status` v(20) VersionStatus; `submitted_by` v(64); `submitted_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `activated_at` tstz; `superseded_at` tstz; `purpose_code` v(41); `data_scope` v(2000); `body_text` v(20000); `valid_days` int; `withdrawal_guide` v(2000).

### 3.46. `consent_record`

::: dac-ta
**Mục đích.** EN-09-44 Bản ghi đồng ý hoặc rút (FR-09-053, 054, BR-09-050, 051): băm chủ thể, mẫu và phiên bản, băm nội dung đã hiển thị, kênh, thời điểm, bằng chứng; rút ghi trên cùng dòng (withdrawn_*) và có hiệu lực trong 60 giây.

**FR phục vụ.** FR-09-053, 054; EN-09-44.

**Khóa chính.** `id`.

**Duy nhất.** `uq_consent_record_given` (tenant_id, template_code, subject_hash) có điều kiện.

**Khóa ngoại.** (tenant_id, template_id) → `consent_template`.

**Ràng buộc CHECK.** `ck_consent_record_` + status, channel, hash, withdrawn, expired.

**Chỉ mục.** `ix_consent_record_subject`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `template_id`, `template_code`, `template_version`, `subject_hash`, `text_hash`, `given_at`, `channel`, `recorded_by`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `text_hash` | `bytea` | Băm nội dung mẫu đã hiển thị cho chủ thể (bằng chứng, BR-09-050). |

: Cột của bảng `consent_record`

Cột khác: `template_id` uuid; `template_code` v(41); `template_version` int; `subject_hash` bytea; `status` v(10) ConsentStatus; `channel` v(10) ConsentChannel; `given_at` tstz; `evidence` jsonb; `recorded_by` v(64); `expires_at` tstz; `withdrawn_at` tstz; `withdrawn_channel` v(10); `withdrawn_by` v(64); `withdraw_evidence` jsonb.

### 3.47. `dpia_record`

::: dac-ta
**Mục đích.** EN-09-45 Hồ sơ đánh giá tác động xử lý DLCN theo phiên bản (FR-09-055…057, BR-09-052, 053): DpiaKind, hoạt động liên kết, rủi ro, biện pháp, hạn rà soát ≤ 12 tháng; trạng thái DpiaStatus gồm SUBMITTED_A05 khi đã gửi Cục A05.

**FR phục vụ.** FR-09-055, 056, 057; EN-09-45.

**Khóa chính.** `id`.

**Duy nhất.** `uq_dpia_record_version` (tenant_id, dpia_code, version_no), `uq_dpia_record_active` (tenant_id, dpia_code) có điều kiện.

**Khóa ngoại.** (tenant_id, activity_id) → `processing_activity`.

**Ràng buộc CHECK.** `ck_dpia_record_` + code, kind, risks, a05, version, status, four_eyes, active, reject.

**Chỉ mục.** `ix_dpia_record_review`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `dpia_code`, `version_no`, `activity_id`; Trigger: `tg_dpia_record_frozen`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `status` | `varchar(20), mặc định 'DRAFT'` | VersionStatus cộng SUBMITTED_A05 (Phụ lục A, DpiaStatus). Enum `DpiaStatus`. |

: Cột của bảng `dpia_record`

Cột khác: `dpia_code` v(41); `version_no` int; `submitted_by` v(64); `submitted_at` tstz; `decided_by` v(64); `decided_at` tstz; `decision_comment` v(2000); `activated_at` tstz; `superseded_at` tstz; `activity_id` uuid; `dpia_kind` v(16) DpiaKind; `description` v(4000); `risks` jsonb; `measures` jsonb; `review_on` date; `submitted_a05_at` tstz; `a05_ref` v(128).

### 3.48. `breach_case`

::: dac-ta
**Mục đích.** EN-09-46 Vụ việc vi phạm DLCN (FR-09-058…060, BR-09-054…056): BreachSource, BreachStatus, BreachSeverity, đồng hồ 72 giờ từ detected_at không dừng, hạn deadline_at cố định.

**FR phục vụ.** FR-09-058, 059, 060; EN-09-46.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_breach_case_` + source, status, severity, types, clock, counts, assessed, notified, not_breach, closed.

**Chỉ mục.** `ix_breach_case_open`, `ix_breach_case_detected`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `detected_at`, `deadline_at`, `reported_by`, `source`.

**Ghi chú.** ETag là `version`.
:::

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `affected_ref` | `varchar(512), NULL` | Danh sách băm chủ thể bị ảnh hưởng, tệp mã hóa ở Garage; không giữ định danh rõ (BR-09-056). |

: Cột của bảng `breach_case`

Cột khác: `detected_at` tstz; `deadline_at` tstz; `source` v(16) BreachSource; `description` v(4000); `data_types` v(32)[]; `estimated_subjects` int; `incident_ref` v(64); `status` v(12) BreachStatus; `severity` v(8) RiskLevel; `reported_by` v(64); `assessed_by` v(64); `assessed_at` tstz; `notified_a05_at` tstz; `exempt_basis` v(2000); `not_breach_reason` v(2000); `not_breach_approved_by` v(64); `affected_count` int; `lessons` v(4000); `closed_at` tstz.

### 3.49. `breach_notification`

::: dac-ta
**Mục đích.** EN-09-47 Thông báo vi phạm cho Cục A05, chủ thể hoặc bên kiểm soát (FR-09-059, BR-09-055): NotificationRecipient, nội dung không chứa DLCN, trạng thái NotificationStatus, bằng chứng gửi (băm và tham chiếu).

**FR phục vụ.** FR-09-059; EN-09-47.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, case_id) → `breach_case`.

**Ràng buộc CHECK.** `ck_breach_notification_` + recipient, status, sent, hash.

**Chỉ mục.** `ix_breach_notification_case`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `case_id` uuid; `recipient` v(12) NotificationRecipient; `status` v(6) NotificationStatus; `content` v(20000); `sent_at` tstz; `sent_by` v(64); `evidence_ref` v(512); `evidence_hash` bytea.

### 3.50. `breach_action`

::: dac-ta
**Mục đích.** EN-09-48 Biện pháp khắc phục và bài học của vụ việc (FR-09-060): người phụ trách, hạn, kết quả; is_lesson phân biệt bài học với biện pháp.

**FR phục vụ.** FR-09-060; EN-09-48.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, case_id) → `breach_case`.

**Ràng buộc CHECK.** `ck_breach_action_` + lesson.

**Chỉ mục.** `ix_breach_action_case`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `case_id` uuid; `is_lesson` bool; `description` v(2000); `owner` v(64); `due_on` date; `done_at` tstz; `result` v(2000).

### 3.51. `privacy_audit_event`

::: dac-ta
**Mục đích.** EN-09-49 Chỉ mục kiểm toán thao tác bảo vệ dữ liệu (FR-09-061, BR-09-057, 058, NFR-09-013): ai, thao tác, đối tượng, API-09, kết quả; chuyển bản ghi đầy đủ sang PH-13 (forwarded_at).

**FR phục vụ.** FR-09-061; EN-09-49.

**Khóa chính.** (id, occurred_at).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_privacy_audit_event_` + api, trace, no_value, forwarded.

**Chỉ mục.** `ix_privacy_audit_event_actor`, `ix_privacy_audit_event_target`, `ix_privacy_audit_event_pending`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Phân vùng tháng theo `occurred_at`; Trigger: `tg_privacy_audit_event_append_only`.

**Ghi chú.** Không có `version`.
:::

Cột: `id` uuid; `tenant_id` v(16); `occurred_at` tstz; `actor` v(64); `action` v(64); `target_kind` v(32); `target_id` v(128); `api_code` v(10); `success` bool; `privileged` bool; `details` jsonb; `trace_id` char(32); `audit_ref` v(64); `forwarded_at` tstz, phân vùng `RANGE (occurred_at)`.

### 3.52. `compliance_report`

::: dac-ta
**Mục đích.** EN-09-50 Báo cáo tuân thủ theo kỳ (FR-09-062, 063): kỳ, các mục, chỉ số, tệp (Garage) và băm.

**FR phục vụ.** FR-09-062, 063; EN-09-50.

**Khóa chính.** `id`.

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_compliance_report_` + period, format, sections, sha, file.

**Chỉ mục.** `ix_compliance_report_period`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** ETag là `version`.
:::

Cột: `period_from` date; `period_to` date; `sections` v(32)[]; `report_format` v(8) {PDF, XLSX, DOCX}; `metrics` jsonb; `file_ref` v(512); `file_sha256` char(64); `generated_by` v(64).

### 3.53. `tenant_setting`

::: dac-ta
**Mục đích.** EN-09-51 Tham số 09.* của tenant (FR-09-064, FRS 8.2, BR-09-059): khóa, giá trị jsonb, sàn và trần do PA đặt, người sửa là updated_by.

**FR phục vụ.** FR-09-064; EN-09-51.

**Khóa chính.** `id`.

**Duy nhất.** `uq_tenant_setting_key` (tenant_id, setting_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_tenant_setting_` + key, bounds.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Bất biến: `setting_key`.

**Ghi chú.** ETag là `version`.
:::

Cột: `setting_key` v(48) {}; `value` jsonb; `floor_value` jsonb; `ceiling_value` jsonb.

### 3.54. `outbox_event`

::: dac-ta
**Mục đích.** Outbox (DD-11, ADR-042) cho EVT-09-01…32 và bản ghi kiểm toán gửi PH-13. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL.

**FR phục vụ.** Hạ tầng dùng chung.

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_event_` + prefix, topic, trace, no_value.

**Chỉ mục.** `ix_outbox_event_occurred`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** Debezium Outbox Event Router đọc WAL và phát lên Kafka; ghi cùng giao dịch với thay đổi (ADR-042, SAD 7.3). Không có `version`.
:::

Cột: `event_id` uuid; `tenant_id` v(16); `event_type` v(128); `topic` v(249); `aggregate_type` v(64); `aggregate_id` v(255); `partition_key` v(255); `payload` jsonb; `trace_id` char(32); `occurred_at` tstz.

### 3.55. `inbox_event`

::: dac-ta
**Mục đích.** Inbox chống xử lý trùng cho sự kiện PH-09 tiêu thụ (at-least-once): đổi phân loại từ PH-06 (FR-06-004), sự kiện đăng ký HTTT PH-02, báo lượt khai thác PH-14, sự cố PH-18.

**FR phục vụ.** Hạ tầng dùng chung.

**Khóa chính.** (tenant_id, consumer, event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_inbox_event_` + consumer, prefix.

**Chỉ mục.** `ix_inbox_event_received`.

**Cách ly tenant.** RLS FORCE.

**Phân vùng, bất biến.** Không.

**Ghi chú.** Khử trùng sự kiện nhận theo (`consumer`, `event_id`); tiêu thụ lũy đẳng. Không có `version`.
:::

Cột: `tenant_id` v(16); `consumer` v(64); `event_id` v(255); `source_topic` v(249); `event_type` v(255); `received_at` tstz; `processed_at` tstz; `outcome` v(2000).
<!-- gen:tables:end -->

### 3.56. Phân vùng và bảo trì

Hai bảng phân vùng theo tháng, bảo trì bằng tác vụ định kỳ; DDL tạo sẵn ba phân vùng từ tháng triển khai.

| Bảng | Khóa phân vùng | Tạo trước | Dọn |
|---|---|---|---|
| `usage_counter` | `bucket_at` | 3 tháng tới | `DROP` phân vùng sau 13 tháng (lịch lưu giữ 400 ngày) |
| `privacy_audit_event` | `occurred_at` | 3 tháng tới | `DETACH` sau 13 tháng; bản gốc đã ở WORM của PH-13, chỉ mục này chỉ để tra nhanh |

: Phân vùng và bảo trì

`PartitionMaintenanceJob` gọi `p_ensure_partitions` mỗi ngày lúc 00:05 (khóa tác vụ bằng `pg_try_advisory_lock`, không cần bảng `shedlock`). Dọn lưu giữ do `RetentionTaskJob` (FR-09-041) theo lịch `PH09-OWN` ở chương 7, bỏ qua đối tượng bị giữ pháp lý (ERR-09-058).

## 4. DDL và changelog Liquibase

### 4.1. Tệp

[`ph09/ddl/ph09_privacy.sql`](ph09/ddl/ph09_privacy.sql) là nguồn duy nhất, chia changeset bằng `-- @file`, `-- @changeset`, `-- @rollback` như PH-04, 06, 07, 10. Changelog [`ph09/liquibase/db.changelog-ph09.yaml`](ph09/liquibase/db.changelog-ph09.yaml) và 12 tệp `ph09/liquibase/changes/*.sql` (formatted SQL, tác giả `ph09`) sinh bằng [`gen_liquibase.py`](ph09/tools/gen_liquibase.py), không sửa tay.

| Tệp | Nội dung |
|---|---|
| `09-0000-bootstrap.sql` | Vai trò `ph09_owner`, `ph09_app`, `ph09_readonly`, `ph09_decide`; `pg_trgm`; schema; biến phiên |
| `09-0001-functions.sql` | `tg_touch`, `tg_immutable`, `tg_append_only`, `tg_frozen`, `tg_child_frozen`, `class_rank`, `p_enable_rls`, `p_ensure_partitions`, `p_seed_tenant` |
| `09-0010-classification.sql` | `data_class`, `block_label`, `personal_data_category`, `data_element`, `element_classification`, `classification_change`, `detector_rule`, `scan_run`, `scan_finding`, `contract_level` |
| `09-0020-ropa.sql` | `legal_document`, `legal_basis`, `processing_activity`, `activity_link` |
| `09-0030-purpose.sql` | `purpose`, `purpose_element`, `access_request`, `purpose_grant`, `grant_condition`, `policy_bundle`, `usage_counter`, `usage_anomaly` |
| `09-0040-masking.sql` | `mask_type`, `mask_policy`, `mask_rule`, `mask_simulation`, `reveal_grant`, `log_mask_config`, `leak_finding` |
| `09-0050-pseudonym.sql` | `pseudonym_domain`, `pseudonym_key`, `reidentification_request`, `anonymization_config`, `anonymization_job`, `risk_report`, `anonymized_dataset` |
| `09-0060-retention.sql` | `retention_schedule`, `retention_schedule_line`, `retention_task`, `legal_hold`, `tenant_shred_request` |
| `09-0070-dsr-consent.sql` | `subject_request`, `subject_verification`, `subject_task`, `consent_template`, `consent_record` |
| `09-0080-dpia-breach.sql` | `dpia_record`, `breach_case`, `breach_notification`, `breach_action` |
| `09-0090-ops.sql` | `privacy_audit_event`, `compliance_report`, `tenant_setting`, `outbox_event`, `inbox_event` |
| `09-0900-grants.sql` | Quyền theo vai trò, `runAlways` |

: Tệp DDL và changelog Liquibase của PH-09

Không có changeset di trú dữ liệu: repo chưa có bảng PH-09 nào chạy (SRS cũ chỉ là mô hình trên giấy) và MVP khai báo phân loại trong mã (`@Classified`, `x-dh-classification`); khai báo này được nhập vào `data_element`, `element_classification` ở trạng thái `PROPOSED` bằng FR-09-003, không bằng changeset.

### 4.2. Kết quả chạy thử

Chạy ngày 26/11/2026 trên PostgreSQL 16.15 (Ubuntu 24.04) cài sạch, dữ liệu giả, tenant kiểm thử T90, T91:

- DDL chạy không lỗi trên CSDL `ph09_test` trống với `ON_ERROR_STOP`: 55 bảng gốc, 6 phân vùng, 372 `CHECK`, 39 khóa ngoại, 93 trigger, 220 chính sách RLS (55 bảng × 4).
- Ghép 12 tệp changelog theo thứ tự trong `db.changelog-ph09.yaml` rồi chạy bằng psql trên CSDL trống khác: không lỗi, cùng 55 bảng. Chưa chạy bằng Liquibase CLI (không có trong máy); CI chạy `liquibase update` trên Testcontainers.
- [`ph09_isolation_test.sql`](ph09/test/ph09_isolation_test.sql) đạt 160 khối PASS, chia 15 nhóm: nạp tenant (4, 18, 7, 7, 12 và 36 dòng, chạy lại không nhân bản); cô lập tenant (T91 đọc 0 dòng nghiệp vụ T90 trên mọi bảng kể cả phân vùng, không chèn, sửa, xóa; không có dòng `COMMON`; chưa đặt tenant thì thấy 0 dòng); phân loại và hạ mức; nhãn STATE_SECRET; hoạt động xử lý, DPIA; chấp thuận, yêu cầu, bundle; chính sách che, phiếu xem đầy đủ; giả danh hóa, khôi phục, ẩn danh hóa; lưu giữ, giữ pháp lý, xóa mật mã; yêu cầu chủ thể, đồng ý; vi phạm 72 giờ; kiểm toán chỉ thêm, outbox, tham số; quyền ba vai `ph09_app`, `ph09_readonly`, `ph09_decide`; không cột hay bảng nào lưu giá trị DLCN rõ.

Bài kiểm `TenantIsolationIT` (D03-02-PH09) tự động hóa các khối này trong CI bằng Testcontainers PostgreSQL 16.

### 4.3. Đối chiếu với FRS phụ lục A

[`ph09/tools/check_frs.py`](ph09/tools/check_frs.py) đọc FRS và DDL, kiểm: (1) 96 cột có `CHECK` liệt kê giá trị đều khớp đúng một enum Phụ lục A, hoặc là tập con có chủ ý (`personal_data_type` của loại DLCN không có `NONE`); (2) không có giá trị `CHECK` dạng chữ hoa nào mà FRS không có; (3) mọi mã ERR, BR, EN, FR nhắc ở DDL và tài liệu có ở FRS, đủ 51 EN và 64 FR; (4) mọi bảng bật RLS và có `COMMENT`. Kết quả: khớp. Sáu cột có tập giá trị nằm ở mô tả chức năng chứ chưa ở Phụ lục A (`log_policy`, `display_policy`, `target_kind` hai bảng, `mask_policy.scope`, `report_format`) và bốn enum (`AnonTransform`, `ConsentChannel`, `FailMode`, `IdentifierKind`) chỉ dùng ở dịch vụ hoặc trong `jsonb`; đề nghị ở mục 9.2.

## 5. Dữ liệu khởi tạo

Không có dữ liệu dùng chung giữa tenant. Khi PH-20 khởi tạo tenant, `dh-data` gọi `ph09_privacy.p_seed_tenant('Tnn')`; thủ tục chạy lại không nhân bản (`ON CONFLICT DO NOTHING`, `id` tất định theo `md5`).

| Dữ liệu | Nội dung | Nguồn |
|---|---|---|
| `data_class` | 4 dòng: PUBLIC 1, INTERNAL 2, RESTRICTED 3 (log che một phần, hiển thị theo vai trò), SENSITIVE 4 (log không giá trị, che mặc định, mã hóa ở ứng dụng) | FR-09-001; D03-07 3.2 |
| `personal_data_category` | 18 dòng: 9 cơ bản, 9 nhạy cảm, kèm mức mặc định, mẫu che, loại định danh | FR-09-002 |
| `detector_rule` | 7 mẫu: số định danh 12, mã số thuế, thẻ Luhn, điện thoại, thư điện tử, BHXH 10, gợi ý tên trường | FR-09-005 |
| `legal_basis` | 7 `LegalBasisType` kèm quy tắc áp dụng | FR-09-012 |
| `mask_type` | 12 dòng: NONE, 5 mẫu PARTIAL, REPLACE, KEYED_HASH, TOKENIZE, 2 mẫu GENERALIZE, DROP | FR-09-023 |
| `tenant_setting` | 36 dòng theo FRS 8.2 kèm sàn, trần số học (`09.grant.max-days` 365, `09.plan.cache-seconds` 300, `09.mask.reveal-seconds` 60, `09.anon.k-min` 10…) | FR-09-064 |
| `log_mask_config` | 1 dòng: số định danh 12, điện thoại, thẻ, thư điện tử; cửa sổ 24 giờ | FR-09-030 |
| `retention_schedule` | Lịch `PH09-OWN` ACTIVE với 17 dòng (chương 7) | FR-09-040 |

: Dữ liệu khởi tạo mỗi tenant

Không nạp sẵn `mask_policy`, mục đích, hoạt động xử lý: chúng cần mô phỏng đạt hoặc người duyệt thật. Đợt 2 nhập khai báo MVP bằng FR-09-003 (§4.1).

## 6. Kho lưu trữ ngoài PostgreSQL

### 6.1. OpenBao

Ba nhóm khóa theo tenant. `dh-{tenant}-pii` (transit, mã hóa envelope các cột `*_enc`; KEK này bị hủy khi xóa mật mã tenant, BR-09-041). `dh-{tenant}-privacy-hmac` (HMAC-SHA256 cho `subject_hash`, `consent_record.subject_hash`; tên là giả định, Q09-52). `dh-{tenant}-pseudo-{miền}` (một khóa mỗi `pseudonym_domain`, phiên bản ở `pseudonym_key`, không xuất được) và `dh-{tenant}-bundle-sign` (ký bundle, SEC-36). `*_kid` ghi phiên bản khóa mã hóa. Không có khóa nào ở CSDL hay tệp cấu hình. OpenBao ngừng thì không băm có khóa hay token hóa được (ERR-09-108) và đường quyết định chỉ dùng bundle đã đệm.

### 6.2. Kafka

Ba mươi hai topic `{tenant}.privacy.*.v1` của EVT-09-01…32 (ví dụ `t68.privacy.purpose-grant.revoked.v1`) cộng `audit.recorded.v1` do Debezium Outbox Event Router đọc từ `outbox_event`, khóa phân vùng là `tenantId`; sự kiện không mang giá trị DLCN (BR-09-025), `CHECK` chặn các khóa giá trị và định danh. Sự kiện vào (đổi phân loại từ PH-06, báo lượt khai thác PH-14, sự cố PH-18) khử trùng bằng `inbox_event`. Đăng ký topic qua FR-10-067.

### 6.3. Garage

Garage (kho đối tượng giao diện S3, theo SAD) giữ: bundle chính sách (`policy_bundle.object_ref`, ≤ 5 MB); bộ mẫu mô phỏng ≤ 1.000 dòng dữ liệu giả; tệp kết quả quét; báo cáo tuân thủ và hồ sơ DPIA xuất; câu trả lời, bằng chứng xác minh và bằng chứng gửi thông báo vi phạm (mã hóa SSE-C); danh sách băm chủ thể bị ảnh hưởng (`breach_case.affected_ref`); tập đã ẩn danh (SSE-C). Nhật ký kiểm toán gốc và bản ghi khôi phục giá trị gốc ở WORM của PH-13 (Ceph RGW), PH-09 chỉ giữ chỉ mục.

### 6.4. Valkey

`dh:{tenant}:privacy:plan:{băm khóa}` giữ kế hoạch che 300 giây (`09.plan.cache-seconds`); `dh:{tenant}:privacy:consent:{mẫu}:{băm}` giữ kết quả tra đồng ý 60 giây; `dh:{tenant}:privacy:reveal:{người}:{giờ}` đếm phiếu xem đầy đủ (tối đa 20 mỗi giờ); `dh:{tenant}:privacy:idem:{khóa}` giữ `Idempotency-Key` 24 giờ; `dh:{tenant}:privacy:bundle-debounce` gom thay đổi 10 giây. Không có giá trị rõ trong Valkey (D03-07 3.2). Mất Valkey chỉ mất bộ đệm và bộ đếm giờ.

### 6.5. Job ẩn danh hóa và ClickHouse

Job ẩn danh hóa (thư viện ARX, Java, ADR 092 đề xuất) chạy trong namespace riêng trên Kubernetes, đọc tập nguồn từ Garage hoặc view có tenant, ghi tập ra Garage mã hóa SSE-C, cập nhật `anonymization_job` qua `dh-data`; job không ghi thẳng PostgreSQL. Không có ClickHouse cho PH-09: báo cáo khai thác theo mục đích đọc `usage_counter`; truy vấn nhật ký kiểm toán dài hạn đi qua PH-13.

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

Bảng nêu thời hạn lưu giữ từng nhóm dữ liệu của chính PH-09. Các dòng có lịch `PH09-OWN` được `p_seed_tenant` nạp (17 dòng); nhóm lưu vĩnh viễn không có dòng vì không xóa.

| Đối tượng | Lưu giữ | Cơ chế dọn, sao lưu |
|---|---|---|
| Schema `ph09_privacy` | WAL liên tục, base backup hằng ngày lên Garage, RPO ≤ 5 phút, RTO ≤ 30 phút (NFR-09-021, ADR-034) | Diễn tập DR theo D03-09; bản sao lưu bất biến hết hạn tự nhiên tối đa 35 ngày, khôi phục áp lại danh sách xóa trước khi phục vụ (BR-09-040, SEC-39) |
| Danh mục, phân loại, hoạt động xử lý, mục đích, chấp thuận, chính sách che, khóa, cấu hình, DPIA, `reidentification_request`, `legal_hold` | Vĩnh viễn, không xóa cứng | `REVOKE DELETE`; khôi phục giá trị gốc lưu vĩnh viễn (BR-09-032) |
| `subject_request`, `subject_verification`, `subject_task`, `consent_record` | 5 năm | `ARCHIVE` sang lưu trữ lạnh (BR-09-048) |
| `breach_case`, `breach_notification` | 10 năm (giả định Q09-51) | `ARCHIVE`; hồ sơ vi phạm là bằng chứng thanh tra |
| `usage_anomaly` | 2 năm | `ARCHIVE` |
| `usage_counter` | 400 ngày | `DROP` phân vùng |
| `privacy_audit_event` | 395 ngày trực tuyến | `DETACH`; gốc ở WORM PH-13 |
| `reveal_grant`, `scan_run`, `scan_finding`, `leak_finding` | 365 ngày | `DELETE` theo lịch |
| `mask_simulation`, `policy_bundle` | 180 ngày; 90 ngày | `DELETE`; bundle cũ quá `validUntil` vô dụng |
| `outbox_event`, `inbox_event` | 3 ngày; 7 ngày | `OutboxCleanupJob`, `InboxCleanupJob` mỗi giờ |

: Sao lưu, khôi phục và lưu giữ của PH-09

Lịch `PH09-OWN` chính là chính sách lưu giữ của PH-09: nó tuân theo BR-09-038 (mỗi bảng chứa DLCN có thời hạn tường minh, hành động khi hết hạn), tenant sửa bằng FR-09-040 (phiên bản mới, duyệt bốn mắt). Giữ pháp lý chặn xóa đối tượng liên quan (ERR-09-058).

**Mã hóa.** Kết nối `pg-core` bắt buộc TLS; dữ liệu tĩnh mã hóa mức đĩa (D03-07). Lớp thứ hai ở ứng dụng: định danh và nội dung phiếu chủ thể mã hóa envelope trước khi vào bảng, nên bản sao lưu rời cụm vẫn không có dữ liệu rõ. Quay khóa `dh-{tenant}-pii` giải mã và mã hóa lại theo lô, cập nhật `*_kid`; đổi khóa HMAC cần tính lại mọi `subject_hash` (Q09-52).

**Thứ tự khôi phục.** OpenBao trước, `pg-core` sau; nếu `*_kid` trỏ phiên bản khóa chưa có thì đọc phiếu chủ thể trả lỗi cho tới khi khôi phục khóa, còn đường quyết định vẫn chạy bằng bundle đã đệm tối đa 5 phút rồi đóng an toàn (BR-09-027, NFR-09-007).

## 8. Ánh xạ thực thể, chức năng và CSDL cũ sang thiết kế mới

### 8.1. Thực thể EN-09 → bảng

Bảng ánh xạ 51 thực thể của FRS 4.2 sang bảng; bốn bảng không có mã EN là `purpose_element`, `retention_schedule_line` (bảng con của EN-09-15, EN-09-36), `outbox_event`, `inbox_event` (hạ tầng).

<!-- gen:en:start -->
| Thực thể | Tên ở FRS 4.2 | Bảng hiện thực |
|---|---|---|
| EN-09-01 | `DataClass` | `data_class` |
| EN-09-02 | `BlockLabel` | `block_label` |
| EN-09-03 | `PersonalDataCategory` | `personal_data_category` |
| EN-09-04 | `DataElement` | `data_element` |
| EN-09-05 | `ElementClassification` | `element_classification` |
| EN-09-06 | `ClassificationChange` | `classification_change` |
| EN-09-07 | `DetectorRule` | `detector_rule` |
| EN-09-08 | `ScanRun` | `scan_run` |
| EN-09-09 | `ScanFinding` | `scan_finding` |
| EN-09-10 | `ContractLevel` | `contract_level` |
| EN-09-11 | `ProcessingActivity` | `processing_activity` |
| EN-09-12 | `ActivityLink` | `activity_link` |
| EN-09-13 | `LegalBasis` | `legal_basis` |
| EN-09-14 | `LegalDocument` | `legal_document` |
| EN-09-15 | `Purpose` | `purpose`, `purpose_element` |
| EN-09-16 | `AccessRequest` | `access_request` |
| EN-09-17 | `PurposeGrant` | `purpose_grant` |
| EN-09-18 | `GrantCondition` | `grant_condition` |
| EN-09-19 | `PolicyBundle` | `policy_bundle` |
| EN-09-20 | `UsageCounter` | `usage_counter` |
| EN-09-21 | `UsageAnomaly` | `usage_anomaly` |
| EN-09-22 | `MaskType` | `mask_type` |
| EN-09-23 | `MaskPolicy` | `mask_policy` |
| EN-09-24 | `MaskRule` | `mask_rule` |
| EN-09-25 | `MaskSimulation` | `mask_simulation` |
| EN-09-26 | `RevealGrant` | `reveal_grant` |
| EN-09-27 | `LogMaskConfig` | `log_mask_config` |
| EN-09-28 | `LeakFinding` | `leak_finding` |
| EN-09-29 | `PseudonymDomain` | `pseudonym_domain` |
| EN-09-30 | `PseudonymKey` | `pseudonym_key` |
| EN-09-31 | `ReidentificationRequest` | `reidentification_request` |
| EN-09-32 | `AnonymizationConfig` | `anonymization_config` |
| EN-09-33 | `AnonymizationJob` | `anonymization_job` |
| EN-09-34 | `RiskReport` | `risk_report` |
| EN-09-35 | `AnonymizedDataset` | `anonymized_dataset` |
| EN-09-36 | `RetentionSchedule` | `retention_schedule`, `retention_schedule_line` |
| EN-09-37 | `RetentionTask` | `retention_task` |
| EN-09-38 | `LegalHold` | `legal_hold` |
| EN-09-39 | `TenantShredRequest` | `tenant_shred_request` |
| EN-09-40 | `SubjectRequest` | `subject_request` |
| EN-09-41 | `SubjectVerification` | `subject_verification` |
| EN-09-42 | `SubjectTask` | `subject_task` |
| EN-09-43 | `ConsentTemplate` | `consent_template` |
| EN-09-44 | `ConsentRecord` | `consent_record` |
| EN-09-45 | `DpiaRecord` | `dpia_record` |
| EN-09-46 | `BreachCase` | `breach_case` |
| EN-09-47 | `BreachNotification` | `breach_notification` |
| EN-09-48 | `BreachAction` | `breach_action` |
| EN-09-49 | `PrivacyAuditEvent` | `privacy_audit_event` |
| EN-09-50 | `ComplianceReport` | `compliance_report` |
| EN-09-51 | `TenantSetting` | `tenant_setting` |

: Ánh xạ thực thể EN-09 sang bảng

Bảng không có mã EN ở FRS 4.2 (bổ sung để hiện thực chức năng): `outbox_event`, `inbox_event`.
<!-- gen:en:end -->

### 8.2. Chức năng FR-09 → bảng

Bảng cho biết mỗi chức năng đọc hoặc ghi bảng nào, lấy từ mã FR trong `COMMENT ON TABLE` cộng bảng ghi tay cho chức năng không có bảng riêng (FR-09-008, 013, 021, 022, 027, 028, 032, 051).

<!-- gen:fr:start -->
| FR-09 | Bảng hiện thực | FR-09 | Bảng hiện thực |
|---|---|---|---|
| 001 | `data_class` | 033 | `reidentification_request`, `pseudonym_domain`, `pseudonym_key`, `privacy_audit_event` |
| 002 | `personal_data_category` | 034 | `pseudonym_key`, `pseudonym_domain` |
| 003 | `data_element` | 035 | `anonymization_config` |
| 004 | `element_classification`, `classification_change` | 036 | `anonymization_job`, `anonymization_config` |
| 005 | `classification_change`, `detector_rule`, `scan_run`, `scan_finding` | 037 | `risk_report`, `anonymization_job` |
| 006 | `contract_level`, `data_element`, `element_classification`, `block_label` | 038 | `anonymization_job`, `anonymized_dataset` |
| 007 | `block_label` | 039 | `anonymized_dataset` |
| 008 | `data_element`, `element_classification`, `classification_change` | 040 | `retention_schedule`, `retention_schedule_line` |
| 009 | `processing_activity` | 041 | `retention_task`, `retention_schedule_line`, `legal_hold` |
| 010 | `processing_activity`, `dpia_record` | 042 | `legal_hold` |
| 011 | `activity_link` | 043 | `tenant_shred_request` |
| 012 | `legal_document`, `legal_basis` | 044 | `retention_task`, `retention_schedule` |
| 013 | `processing_activity`, `activity_link`, `legal_basis`, `legal_document` | 045 | `subject_request` |
| 014 | `purpose`, `purpose_element` | 046 | `subject_request`, `subject_verification` |
| 015 | `access_request` | 047 | `subject_request`, `subject_task`, `privacy_audit_event` |
| 016 | `access_request`, `purpose_grant`, `grant_condition` | 048 | `subject_request`, `subject_task` |
| 017 | `purpose_grant` | 049 | `subject_request` |
| 018 | `purpose_grant`, `policy_bundle` | 050 | `subject_request` |
| 019 | `usage_counter`, `purpose`, `purpose_grant`, `grant_condition`, `subject_request` | 051 | `subject_request`, `subject_task`, `privacy_audit_event` |
| 020 | `usage_counter`, `usage_anomaly`, `purpose_grant` | 052 | `consent_template` |
| 021 | `usage_counter`, `purpose_grant`, `usage_anomaly` | 053 | `consent_record` |
| 022 | `contract_level`, `purpose_grant`, `processing_activity` | 054 | `consent_record`, `consent_template` |
| 023 | `mask_type` | 055 | `dpia_record` |
| 024 | `mask_policy`, `mask_rule`, `mask_type`, `personal_data_category` | 056 | `dpia_record` |
| 025 | `mask_simulation` | 057 | `dpia_record` |
| 026 | `mask_policy` | 058 | `breach_case` |
| 027 | `mask_policy`, `mask_rule`, `mask_type`, `element_classification`, `policy_bundle` | 059 | `breach_case`, `breach_notification` |
| 028 | `mask_policy`, `mask_rule`, `mask_type` | 060 | `breach_case`, `breach_action` |
| 029 | `reveal_grant`, `element_classification`, `privacy_audit_event` | 061 | `privacy_audit_event` |
| 030 | `log_mask_config`, `leak_finding` | 062 | `compliance_report` |
| 031 | `pseudonym_domain`, `purpose` | 063 | `compliance_report` |
| 032 | `pseudonym_domain`, `pseudonym_key` | 064 | `tenant_setting` |

: Ánh xạ FR-09-001…064 sang bảng (hai cột song song: 001 đến 032 và 033 đến 064)

<!-- gen:fr:end -->

### 8.3. Mô hình SRS cũ của repo (`docs/07-srs/SRS-PH-09-privacy.md` §4)

SRS cũ có sáu thực thể tiếng Việt không dấu; FRS mới đổi tên sang tiếng Anh `snake_case` và tách thêm bảng. Cột "Chuyển đổi" nêu thay đổi kiểu và quy tắc.

| Thực thể cũ | Bảng mới | Chuyển đổi |
|---|---|---|
| `PHAN_LOAI_TRUONG` (EN-09-01 cũ) | `data_element`, `element_classification`, `classification_change` | `muc_nhay_cam` 0…3 → `data_class` bốn giá trị tên (rank 1…4, DD-08); `loai_dinh_danh` `SENSITIVE` → `SENSITIVE_ATTR`; `la_du_lieu_ca_nhan boolean` → `personal_data_type` (`NONE`, `BASIC`, `SENSITIVE`) cộng `category_code`; `can_cu_phan_loai` → `basis`; `nguoi_phe_duyet` → `confirmed_by`; `ma_thuc_the` + `ten_truong` → `data_element.target` |
| `MIEN_GIA_DANH`, `KHOA_GIA_DANH` (EN-09-02 cũ) | `pseudonym_domain`, `pseudonym_key` | `chu_ky_xoay_khoa_ngay` → `rotate_days` (90…730); `so_phien_ban` → `key_version`; `vault_key_ref` → `openbao_ref` (chỉ tham chiếu transit); `het_hieu_luc`, `con_dung_de_khoi_phuc` → `status` (`DECRYPT_ONLY`, `DISABLED`, `DESTROYED`) |
| `CAU_HINH_AN_DANH`, `QUY_TAC_TONG_QUAT` (EN-09-03, 04 cũ) | `anonymization_config` | `nguong_k ≥ 5` → `k` từ 10 (SEC-38); `cho_phep_ai` → `anonymization_job.target = AI_TRAINING`; quy tắc con thành `rules jsonb`; `SHIFT` → `DATE_SHIFT` |
| `DANH_GIA_RUI_RO` (EN-09-05 cũ) | `risk_report` | `muc_rui_ro` `THAP`, `TRUNG_BINH`, `CAO` → `LOW`, `MEDIUM`, `HIGH`; `ty_le_nhom_nho decimal(5,4)` → `numeric(6,5)`; `nguoi_phe_duyet` → `approved_by` (SO, khi MEDIUM) |
| `NHAT_KY_KHOI_PHUC` (EN-09-06 cũ) | `reidentification_request` và `privacy_audit_event` | Không còn lưu `bi_danh` (cột `bi_danh` cũ bị bỏ vì là giá trị liên kết được); `hang_loat > 10` → luôn hai cấp duyệt, tối đa 100 giá trị; `muc_dich`, `can_cu` → `purpose_code`, `basis`; lưu vĩnh viễn ở WORM PH-13 |

: Ánh xạ thực thể SRS cũ sang bảng mới

### 8.4. Hệ cũ Viettel 2021 và CSDL quốc gia

Hệ cũ (Viettel 2021) không có phân hệ quyền riêng tư tương ứng nên không có bảng hay cột cũ cần chuyển đổi cho D06-01 và không có changeset di trú. LGC-TOOL-012 (nhóm bảo mật, mã hóa gói tin) chỉ liên quan chặng che ở PH-04 qua `mask_policy`; LGC-NGSP-003 (BHXH tra cứu hộ gia đình) là hợp đồng PH-14 chịu kiểm soát mục đích bằng `purpose_grant`. Không có đồng bộ dữ liệu sang CSDL quốc gia từ PH-09.

## 9. Câu hỏi mở và đề nghị cho FRS

### 9.1. Câu hỏi mở

Các câu hỏi chưa có quyết định, kèm đề xuất tạm.

| Mã | Câu hỏi | Đề xuất tạm |
|---|---|---|
| Q09-50 | Sáu cột có tập giá trị cố định nhưng chưa ở Phụ lục A (`log_policy`, `display_policy`, `target_kind`, `mask_policy.scope`, `report_format`) nên đưa thành enum Phụ lục A hay giữ ở mô tả chức năng | Đưa vào Phụ lục A (`LogPolicy`, `DisplayPolicy`, `TargetKind`, `MaskPolicyScope`, `ReportFormat`) để UC, API, TC dùng chung tên; DDL đã khớp giá trị ở FR-09-001, 007, 011, 024, 063 |
| Q09-51 | Thời hạn trực tuyến của `privacy_audit_event` (395 ngày), `usage_counter` (400 ngày) và hồ sơ vi phạm (10 năm) so với quy định bảo quản; `usage_counter` khoảng 100 triệu dòng ở tỉnh vừa | Giữ giả định; nếu pháp chế yêu cầu dài hơn thì `ARCHIVE` sang Garage dạng Parquet; chuyển `usage_counter` sang ClickHouse của PH-13 nếu ghi vượt 500 dòng mỗi giây |
| Q09-52 | Khóa HMAC của `subject_hash` dùng chung với `dh-{tenant}-mdm-hmac` của PH-06 (tra chéo được, một lần quay khóa) hay khóa riêng `dh-{tenant}-privacy-hmac` (tách rủi ro, phải chuyển băm khi tra PH-06); chu kỳ quay | Khóa riêng; PH-09 tính băm theo khóa của PH-06 khi chuyển tác vụ qua giao diện module, không lưu; quay 12 tháng, hai pha (ghi cả hai băm, bỏ băm cũ); cần ATTT và PH-06 xác nhận (liên quan Q09-16) |
| Q09-53 | `consent_record` có cần phân vùng khi tenant lớn (hàng chục triệu đồng ý, các tiện ích thông báo) | Chưa phân vùng ở tỉnh vừa (300.000 dòng); chỉ mục `uq_consent_record_given` đủ cho tra 60 giây; nếu vượt 20 triệu dòng thì phân vùng băm theo `subject_hash` |
| Q09-54 | Danh sách nhỏ (`categories`, `legal_doc_ids`, `fields`, `allowed_categories`) và `rules` của cấu hình ẩn danh lưu dạng mảng, `jsonb` nên không có khóa ngoại; có cần bảng con để toàn vẹn tham chiếu | Giữ mảng, kiểm ở dịch vụ khi gửi duyệt (phiên bản đã duyệt bất biến nên không lệch về sau); chuyển bảng con nếu kiểm thử thấy lệch tham chiếu sau khi xóa mềm loại DLCN |

: Câu hỏi mở của tập CSDL PH-09

### 9.2. Đề nghị cho FRS

Lệch và thiếu phát hiện khi thiết kế bảng; PH-09 không tự sửa FRS.

| Số | Nội dung | Gợi ý xử lý |
|---|---|---|
| 1 | Enum ngoài Phụ lục A (Q09-50) | Thêm năm enum vào Phụ lục A |
| 2 | FR-09-001 ghi `rank` 1 đến 9 còn Phụ lục A cố định bốn mức thứ hạng 1 đến 4 | DDL chặn 1…4 và đúng thứ hạng theo mã; sửa FR-09-001 hoặc cho phép mức tenant tự thêm (ngoài `DataClass`) |
| 3 | BR-09-002 "hai người khác nhau" mơ hồ khi tính cả người đề xuất | DDL hiểu: người đề xuất, người xác nhận thứ nhất, người xác nhận thứ hai đôi một khác nhau; xin ghi rõ ở BR |
| 4 | Nhãn STATE_SECRET (EN-09-02) chưa có enum trạng thái; gỡ nhãn nêu "hai người" nhưng chưa nói trạng thái trung gian | DDL dùng cột `release_requested_*`, `released_*` thay trạng thái; nếu cần thì thêm `BlockLabelStatus` |
| 5 | `PolicyBundle` (EN-09-19) chưa có trạng thái dựng, ký, phát hành | DDL dùng `test_passed`, `published_at`; thêm trạng thái nếu UI-09-01 cần hiển thị |
| 6 | FR-09-011 và BR-09-011 chưa nói liên kết hoạt động với trường có thuộc nội dung phiên bản không | DDL coi liên kết là nội dung (không thêm vào hoạt động ACTIVE, `tg_child_frozen`); nếu cần thêm liên kết không đổi phiên bản thì bỏ trigger |
| 7 | `ConsentStatus.EXPIRED` chưa có tác vụ sinh | DDL cho phép giá trị khi `expires_at` qua hạn; FRS nên nêu tác vụ hoặc bỏ giá trị |
| 8 | Phụ lục A chưa có chuỗi thời hạn `legal_doc` cho nhãn, loại văn bản `docType` | DDL chỉ ràng buộc dạng `^[A-Z][A-Z0-9_]{1,31}$`; thêm enum `LegalDocType` nếu cần |
| 9 | SRS cũ cho k ≥ 5 và bí danh khôi phục lưu rõ; FRS mới k ≥ 10, không lưu | Đã áp ở DDL; ghi vào bảng chuyển đổi 8.3 |

: Đề nghị cho FRS

### 9.3. Đề nghị đồng bộ tài liệu chung

Người điều phối cần chạy lại `kiem_tra_ma.py --cap-nhat-so-tra-cuu` để D00-04 có Q09-50…54 và bảng `ph09_privacy`; thêm RPO 5 phút, RTO 30 phút và vai `ph09_decide` vào D03-09; ghi `ph09_privacy` vào D03-10 là schema dùng mẫu `p_enable_rls` không có dòng `COMMON`.

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo K-CSDL và K-TRINH-BAY: 55 bảng cho 51 thực thể, DDL và changelog chạy thử trên PostgreSQL 16.15, kiểm cô lập 160 khối PASS, đối chiếu Phụ lục A sạch; ERD sáu nhóm; mã hóa envelope và HMAC, không bảng ánh xạ bí danh; lịch lưu giữ của PH-09; ánh xạ EN, FR sang bảng; năm câu hỏi mở Q09-50…54 |
