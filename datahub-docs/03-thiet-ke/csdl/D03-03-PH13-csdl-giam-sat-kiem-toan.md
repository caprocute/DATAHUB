---
ma_tai_lieu: D03-03-PH13
ten: Thiết kế cơ sở dữ liệu phân hệ PH-13 Giám sát và kiểm toán
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, DBA, ATTT, kiểm toán viên, hội đồng thẩm định
phan_he: PH-13
mo_ta: Thiết kế cơ sở dữ liệu của phân hệ Giám sát và kiểm toán gồm 33 bảng ở hai schema, chuỗi băm chỉ-thêm theo tenant, RLS, DDL đã chạy thử, sao lưu và ánh xạ dữ liệu hệ cũ.
tai_lieu_lien_quan: D02-03-PH13 FRS; D02-04-PH13 UC; D03-02-PH13 SDD; D03-07 ATTT; D03-09 Hạ tầng; D03-10 Đa tenant; D02-07 Từ điển dữ liệu
---

# D03-03-PH13 · Thiết kế CSDL Giám sát và kiểm toán

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu thiết kế nơi PH-13 lưu nhật ký kiểm toán không sửa được và toàn bộ cấu hình, vòng đời của hệ thống cảnh báo, để bảo đảm hai điều: mọi thao tác nhạy cảm đều có dấu vết đáng tin, và một tỉnh không bao giờ thấy dữ liệu giám sát của tỉnh khác.

**Phạm vi.** Hai schema PostgreSQL trên cụm `pg-core`: `ph13_audit` (14 bảng, nhóm kiểm toán) và `ph13_obs` (19 bảng, nhóm quan sát), tổng 33 bảng cho 22 thực thể EN-13-01…22 của [D02-03-PH13](../../02-yeu-cau/frs/D02-03-PH13-frs-giam-sat-kiem-toan.md) §4.2 (11 bảng hỗ trợ do [D03-02-PH13](../sdd/D03-02-PH13-sdd-giam-sat-kiem-toan.md) yêu cầu). Số liệu quan sát (chỉ số, log, vết, lượt gọi API) không nằm ở PostgreSQL mà ở Mimir, Loki, Tempo và ClickHouse (chương 6).

**Căn cứ.** Nhật ký kiểm toán chỉ-thêm, chuỗi băm, WORM (ADR-031); PostgreSQL với RLS làm cơ chế cách ly tenant (ADR-003, SEC-81); lưu dữ liệu quan sát và kiểm toán trong nước (CMP-LAW-16, Luật An ninh mạng 116/2025); log kiểm toán trực tuyến 12 tháng, WORM 5 năm (NĐ 331/2026, CMP-LAW-06, và TCVN 14423:2026, CMP-LAW-08); thông báo vi phạm dữ liệu cá nhân 72 giờ (CMP-LAW-04).

**Ba điểm chính.**

1. **Nhật ký kiểm toán không ai sửa được, kể cả quản trị cơ sở dữ liệu.** Bảng `audit_event` chỉ cho thêm: vai trò ứng dụng không có quyền `UPDATE`, `DELETE`, `TRUNCATE`, và ngay cả chủ bảng cũng bị trigger chặn. Mỗi tenant có một chuỗi băm riêng; đầu chuỗi chỉ nhích khi các bản ghi mới liền kề, không khoảng trống và nối đúng với bản ghi trước, nên sửa lẻ hay chèn xen đều bị CSDL từ chối ngay (không chờ lượt kiểm tra hằng ngày). Chỉ có một đường duy nhất để bản ghi rời bảng trực tuyến: thủ tục lưu trữ phân vùng, và thủ tục này từ chối nếu bản trên kho WORM chưa được xác minh.
2. **Cách ly tenant bằng `FORCE ROW LEVEL SECURITY` trên 31 bảng.** Mỗi dòng thuộc đúng một tenant (hoặc `PLATFORM`); phiên không đặt tenant thì không thấy dòng nào. Khóa ngoại luôn kèm `tenant_id` nên không thể trỏ chéo tenant. Riêng khóa công khai dùng để xác minh chữ ký neo là dữ liệu của nền tảng, mọi tenant đọc được, chỉ phiên `PLATFORM` ghi.
3. **Quy tắc vận hành được khóa ở CSDL, không chỉ ở dịch vụ.** Luật cảnh báo không có runbook đủ năm mục thì không lưu được; cảnh báo Nghiêm trọng không tạm ẩn quá 24 giờ; đóng cảnh báo an ninh phải có kết luận; gói bằng chứng chưa ký không thể ở trạng thái sẵn sàng; luật chuẩn của nền tảng tenant không sửa được; tham số `13.*` ngoài miền bị chặn.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Schema | 2 (`ph13_audit`, `ph13_obs`) |
| Bảng | 33 (14 kiểm toán, 19 quan sát), 517 cột |
| Ràng buộc | 239 `CHECK`, 12 khóa ngoại, 1 ràng buộc loại trừ, 30 khóa duy nhất, 6 chỉ mục duy nhất (5 một phần) |
| Chính sách RLS | 124 (31 bảng × 4 thao tác) |
| Trigger bảo vệ | 90 (chỉ-thêm, chuỗi băm, bất biến cột, trạng thái, hạn lưu) |
| DDL | 2.083 dòng ở hai tệp |
| Bài kiểm | 171 khối, đạt 171/171 trên PostgreSQL 16 |
| Tốc độ ghi chuỗi đo thử | lô 500 bản ghi trung bình 85 đến 94 ms (p95 135 đến 141 ms), khoảng 5.300 đến 5.900 bản ghi/giây cho một tenant |

: Con số chính của thiết kế CSDL PH-13

**Những điểm hội đồng cần lưu ý.** (1) Dung lượng: một tỉnh quy mô vừa cần khoảng 73 GB mỗi năm cho bảng kiểm toán (giả định, mục 1.5); 34 tenant là khoảng 2,5 TB trực tuyến và có thể gấp đôi nếu tenant đặt giữ 24 tháng, cần đưa vào định cỡ `pg-core` ở D03-09. (2) Chuỗi băm bảo đảm phát hiện can thiệp chứ không ngăn cản người có quyền cao nhất ở tầng hạ tầng; vì vậy neo ký và bản WORM nằm ngoài PostgreSQL (BR-13-013). (3) Năm câu hỏi mở Q13-50…54 ở chương 9, đều đã có giả định làm việc.

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả lược đồ dữ liệu PostgreSQL của PH-13 để kỹ sư viết module `audit` và `observability` của `dh-platform` làm việc ngay, DBA vận hành và hội đồng thẩm định đối chiếu với yêu cầu. Nội dung gồm chiến lược lưu trữ và cách ly tenant (chương 1), sơ đồ thực thể – quan hệ (chương 2), đặc tả 33 bảng (chương 3), DDL và kết quả chạy thử (chương 4), dữ liệu khởi tạo (chương 5), kho ngoài PostgreSQL (chương 6), sao lưu, khôi phục và lưu giữ (chương 7), ánh xạ dữ liệu hệ cũ (chương 8), câu hỏi mở (chương 9) và đề nghị đồng bộ (chương 10). Tài liệu không mô tả thuật toán xử lý (xem SDD) hay giao diện lập trình (xem D03-04-PH13).

### 0.2. Người đọc và phần cần đọc

Tài liệu dành cho năm nhóm người đọc; bảng dưới chỉ ra mỗi nhóm cần đọc chương nào để khỏi đọc toàn bộ hơn hai nghìn dòng đặc tả.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư module `audit`, `observability` | Chương 1, 3, 4 |
| DBA, vận hành | Chương 1, 4, 6, 7 |
| ATTT, kiểm toán viên | Mục 1.2, 1.4, mục 3.1, chương 7 |
| Kiểm thử viên | Mục 1.4, chương 4 |
| Hội đồng thẩm định | Tóm tắt, chương 2, chương 8 |

: Người đọc và phần cần đọc

### 0.3. Thuật ngữ và chữ viết tắt

Thuật ngữ nghiệp vụ dùng chung với [D02-03-PH13](../../02-yeu-cau/frs/D02-03-PH13-frs-giam-sat-kiem-toan.md) §1.4 và D00-01; kiểu dữ liệu chuẩn (`T-ID`, `T-TS`…) theo D00-01 §5.

| Thuật ngữ | Nghĩa trong tài liệu |
|---|---|
| RLS | Row-Level Security: PostgreSQL lọc dòng theo chính sách; `FORCE` áp cả cho chủ bảng |
| Chuỗi băm | Mỗi bản ghi chứa băm của bản ghi trước; sửa một bản ghi làm đứt mọi băm phía sau |
| Neo | Bản tóm tắt đầu chuỗi được ký bằng khóa nền tảng, lưu ngoài bảng kiểm toán |
| WORM | Write Once Read Many: kho đối tượng khóa chống xóa (Ceph RGW Object Lock) |
| Phân vùng | Chia bảng theo tháng của `recorded_at`; tháng cũ lưu trữ bằng cách tách cả phân vùng |
| Mẫu P, mẫu S | Hai mẫu RLS của D03-10: P là riêng tenant, S là dùng chung (đọc dòng `PLATFORM`) |
| EN-13-nn | Thực thể nghiệp vụ của FRS §4.2 |
| Hộp thư đi (outbox) | Bảng ghi sự kiện cùng giao dịch với đổi trạng thái để bộ chuyển đẩy lên Kafka |

: Thuật ngữ và chữ viết tắt

### 0.4. Tài liệu tham chiếu

[D02-03-PH13](../../02-yeu-cau/frs/D02-03-PH13-frs-giam-sat-kiem-toan.md) (FRS: thực thể §4.2, định dạng bản ghi §4.7, lưu giữ §8.2, tham số §8.3), [D02-04-PH13](../../02-yeu-cau/use-case/D02-04-PH13-use-case-giam-sat-kiem-toan.md) (use case), [D03-02-PH13](../sdd/D03-02-PH13-sdd-giam-sat-kiem-toan.md) (SDD: chuỗi băm §4.4, neo §4.5, WORM §4.6, bảng chuyển trạng thái §8.1, vai trò §7), D03-07 (SEC, UC-SEC §7.5), D03-09 (hạ tầng), [D03-10](../D03-10-thiet-ke-da-tenant.md) (mẫu RLS), D02-07 (từ điển dữ liệu DD-05), D00-01 (kiểu dữ liệu, cột ngữ cảnh), mẫu đối chiếu [D03-03-PH05](D03-03-PH05-csdl-bo-dieu-hop.md).

### 0.5. Cấu trúc tài liệu

Tài liệu gồm chương giới thiệu và chín chương nội dung theo khuôn K-CSDL; bảng dưới tóm tắt nội dung từng chương để người đọc tìm đúng chỗ.

| Chương | Nội dung |
|---|---|
| 1 | Chiến lược lưu trữ: schema, vai trò, cách ly tenant, quy ước bảng, bất biến ở CSDL, phân vùng và dung lượng |
| 2 | Sơ đồ thực thể – quan hệ của hai schema |
| 3 | Đặc tả 33 bảng, mỗi bảng một khối 10 mục sinh từ DDL, truy vấn chính và chỉ mục |
| 4 | DDL, changelog Liquibase, kết quả chạy thử và bài kiểm cô lập |
| 5 | Dữ liệu khởi tạo |
| 6 | Kho ngoài PostgreSQL: WORM, Kafka, ClickHouse, Mimir, Loki, Tempo |
| 7 | Sao lưu, khôi phục, mã hóa và lưu giữ |
| 8 | Ánh xạ dữ liệu hệ cũ sang thiết kế mới |
| 9 | Câu hỏi mở |
| 10 | Đề nghị đồng bộ cho tài liệu khác |

: Cấu trúc chương của D03-03-PH13

## 1. Chiến lược lưu trữ

PH-13 tách dữ liệu thành hai miền độc lập đúng với hai đường dữ liệu của phân hệ: đường kiểm toán (bản ghi bất biến, chuỗi băm, neo, WORM) và đường quan sát (luật, cảnh báo, lịch trực, SIEM). Mỗi miền một schema, một module chủ, một nhóm vai trò, để lỗi hay quyền thừa ở miền này không lan sang miền kia. Chương này trình bày vai trò và kết nối, cách ly tenant, quy ước bảng, các quy tắc nghiệp vụ được khóa ở CSDL, và phân vùng cùng dung lượng.

### 1.1. Schema, vai trò và kết nối

Hai schema `ph13_audit` và `ph13_obs` do vai trò `ph13_owner` (không đăng nhập, `NOINHERIT`) sở hữu, trên cụm `pg-core` ở vùng Z5. Module `audit` của `dh-platform` là chủ duy nhất của `ph13_audit`; module `observability` là chủ duy nhất của `ph13_obs`. Hai module không truy vấn schema của nhau: module `audit` đọc tham số `13.audit.*` qua giao diện trong tiến trình, không `SELECT` bảng `tenant_obs_config`. Tài khoản đăng nhập là tài khoản động do OpenBao cấp (thời hạn 1 giờ, SEC-33), không cấp cho người (BR-13-019). `dh-runtime` không có kết nối tới hai schema này; mọi bản ghi kiểm toán của DU đi qua hộp thư đi, Kafka và bộ tiếp nhận.

| Vai trò | Quyền | Dùng bởi |
|---|---|---|
| `ph13_owner` | Chủ schema, bảng, hàm; chỉ chạy di trú Liquibase trong đường ống triển khai (DDL do `pgaudit` ghi lại) | Không cấp cho người |
| `ph13_app` | `INSERT`, `SELECT` trên `audit_event`, `audit_anchor`; `INSERT` và `UPDATE` theo cột trên `audit_chain` (`head_seq`, `head_hash`, `last_recorded_at`, `status`, `integrity` và cột đóng chuỗi); `UPDATE` theo cột trên `audit_worm_batch`; DML trên các bảng trạng thái; `EXECUTE` `p_ensure_month_partitions` | Vai trò `ingest`, `api`, `jobs` của module `audit` |
| `ph13_verify` | Chỉ `SELECT`; kết nối tới bản sao đọc | `VerificationService`, truy vấn kiểm toán nặng |
| `ph13_archive` | Chỉ `EXECUTE` thủ tục `p_archive_partition`; không quyền bảng; TTL 15 phút | `ArchiveService`, chỉ khi `preflight` đạt |
| `ph13_obs_app` | DML trên `ph13_obs`; `DELETE` chỉ ở bảng có hạn lưu (và bị trigger chặn khi chưa hết hạn) | Module `observability` |
| `ph13_readonly` | `SELECT` theo cột, không đọc nguyên văn bản cách ly, đường dẫn bí mật kênh, nội dung báo cáo sự cố | Báo cáo, kiểm toán nội bộ |

: Vai trò PostgreSQL của PH-13

Không vai trò nào có `BYPASSRLS` hay là chủ bảng ngoại trừ `ph13_owner`, và `ph13_owner` bị `FORCE ROW LEVEL SECURITY` giữ lại (di trú phải đặt `app.tenant_id` trước khi ghi). Quyền được cấp theo từng bảng, không dùng `ALL TABLES IN SCHEMA`, để quyền không lọt sang các phân vùng của `audit_event` (phân vùng chỉ truy cập qua bảng cha).

### 1.2. Cách ly tenant

Mọi bảng nghiệp vụ có `tenant_id varchar(16)` và bật `FORCE ROW LEVEL SECURITY` qua thủ tục `p_enable_rls` của từng schema. Có hai mẫu theo D03-10, nhưng PH-13 chỉ cần mẫu S cho một bảng và không dùng tenant `COMMON`: mọi dữ liệu có chủ là một tenant tỉnh hoặc chính nền tảng (`PLATFORM`).

| Mẫu | Đọc | Ghi | Bảng |
|---|---|---|---|
| P (riêng) | Dòng có `tenant_id = app.tenant_id` | Dòng có `tenant_id = app.tenant_id` | 30 bảng |
| S (dùng chung) | Dòng của tenant phiên và dòng `PLATFORM` | Chỉ khi phiên là `PLATFORM` và dòng là `PLATFORM` | `audit_signing_key` |
| Không RLS | Mọi vai trò có quyền bảng | Như quyền bảng | `shedlock` của hai schema (bảng kỹ thuật, không có `tenant_id`) |

: Cách ly tenant

Bảy điểm cần nhớ:

1. **Đóng an toàn.** Chính sách dùng `current_setting('app.tenant_id', false)`: chưa đặt biến thì báo lỗi, đặt rỗng thì không dòng nào khớp. Biến phiên được đặt đầu mỗi giao dịch bằng `TenantAwareTransactionManager` (D03-10 §3).
2. **Tenant `PLATFORM` có chuỗi riêng.** Thao tác của nền tảng (cấu hình PH-13, lưu trữ phân vùng, đóng chuỗi tenant) ghi vào chuỗi `PLATFORM`. Ràng buộc `^(T[0-9]{2}|PLATFORM)$` có ở mọi bảng; `T90…T99` dành cho kiểm thử rò rỉ (SEC-87).
3. **Truy cập liên tenant.** Phiên liên tenant của người dùng nền tảng đặt `app.tenant_id` bằng tenant bị truy cập, nên mọi đọc đều chịu RLS của tenant đó; bản ghi `AUDIT.CROSS_TENANT.OPEN` được ghi vào cả hai chuỗi bằng hai lượt ghi, mỗi lượt trong ngữ cảnh một tenant (BR-13-018).
4. **Khóa ngoại kèm tenant.** Các khóa ngoại giữa hai bảng tenant dùng cặp `(x_id, tenant_id)` trỏ tới khóa duy nhất `(id, tenant_id)`, nên không thể tham chiếu chéo tenant. Kiểm tra khóa ngoại của PostgreSQL bỏ qua RLS nên vẫn đúng với cặp này.
5. **Bảng chung một dòng cho mọi tenant.** `audit_partition` và `audit_signing_key` thuộc về nền tảng (`tenant_id = 'PLATFORM'` bắt buộc bằng `CHECK`).
6. **Phân vùng.** RLS đặt ở bảng cha `audit_event`; ứng dụng không có quyền trên từng phân vùng nên không thể đọc vòng qua RLS (bài kiểm 5e).
7. **Luật và runbook chuẩn của nền tảng** được nhân bản cho từng tenant (`scope = 'PLATFORM'`, mỗi tenant một dòng) thay vì dùng chung một dòng, vì luật phải mang tham số SLO của tenant và vòng đời cảnh báo gắn với luật của tenant. Chỉ giao dịch của `StandardRuleCatalog` (đặt `app.rule_catalog = 'on'`) ghi được dòng này.

### 1.3. Quy ước bảng

Theo D00-01 §5.1: `id uuid` (UUID v7 sinh ở ứng dụng), `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (trigger `tg_touch` tăng `version` và đặt `updated_at`). Trạng thái dùng `varchar` kèm `CHECK` liệt kê đúng giá trị của FRS §4.3…4.7; thêm giá trị mới là một changeset mới. Ngoại lệ có chủ đích:

| Bảng | Ngoại lệ | Lý do |
|---|---|---|
| `audit_event` | Khóa `(tenant_id, seq, recorded_at)`, không `updated_*`, `version`; chỉ thêm | Nhật ký bất biến; khóa phải chứa khóa phân vùng |
| `audit_anchor`, `audit_worm_batch` | Không `updated_*`, `version`; `audit_worm_batch` chỉ cho sửa ba cột theo quyền (`verified_at`, `etag`, `retain_until`) | Neo thuần chỉ-thêm; lô WORM có kết quả đối chiếu đến sau |
| `alert_action`, `pii_finding` | Không `updated_*`, `version` | Chỉ thêm, xóa khi quá hạn lưu |
| `detect_cursor` | Khóa tự nhiên `(tenant_id, rule_code)`, không `id` | Mốc kỹ thuật của bộ phát hiện |
| `outbox` (hai schema) | Khóa `event_id`, không cột sửa | DD-11 |
| `shedlock` (hai schema) | Khóa `name`, không `tenant_id`, không RLS | Thư viện ShedLock |
| `audit_partition`, `audit_signing_key` | `tenant_id = 'PLATFORM'` cố định | Thuộc nền tảng, không thuộc một tenant |

: Quy ước bảng và ngoại lệ

### 1.4. Quy tắc nghiệp vụ chốt ở CSDL

CSDL là lớp phòng thủ thứ hai sau dịch vụ: nếu một lỗi lập trình hay một thao tác trực tiếp qua `psql` vi phạm quy tắc, ràng buộc dưới đây vẫn chặn. Bảng liệt kê cơ chế, quy tắc và nguồn yêu cầu; mã lỗi (ERR) là mã mà dịch vụ trả khi bắt lỗi của CSDL.

| Cơ chế | Quy tắc | BR, FR |
|---|---|---|
| Không quyền `UPDATE`, `DELETE`, `TRUNCATE` cho `ph13_app`; trigger `tg_audit_event_append`, `tg_audit_event_truncate` | Bản ghi kiểm toán không sửa, không xóa, kể cả chủ bảng | BR-13-002, 019; FR-13-011 |
| `tg_audit_chain_guard` (trước `UPDATE` ở `audit_chain`) | Đầu chuỗi chỉ tăng; đoạn mới liền kề không trùng, không thiếu `seq`; bản đầu nối đúng `head_hash` cũ; mỗi bản nối đúng bản trước; bản cuối khớp `head_hash`; chuỗi `CLOSED` không nhận bản ghi, không mở lại | BR-13-002, 033; FR-13-011, 060; ERR-13-043 |
| `tg_audit_event_covered` (constraint trigger hoãn) | Bản ghi chỉ cam kết khi đầu chuỗi đã bao phủ `seq` của nó, nên không có bản ghi mồ côi | BR-13-004; ERR-13-106 |
| `ck_audit_event_no_secret`, `ck_audit_event_json_size` | Khóa `password`, `secret`, `token`… trong `before`, `after` chỉ mang giá trị `***`; mỗi vế tối đa 64 KB | BR-13-035; FR-13-010 |
| `ck_audit_event_action`, `_trace`, `_hashes`, `_system_actor` | `action` dạng `{MIỀN}.{HÀNH_ĐỘNG}`; `trace_id` 32 ký tự thập lục; băm 64 ký tự và `hash` khác `prev_hash`; tác nhân hệ thống bắt đầu `system:` | FRS §4.7 |
| `tg_audit_anchor_guard`, trigger chỉ-thêm | Neo không lùi `seq_last`, không vượt đầu chuỗi, không thêm sau neo `FINAL`; không sửa; khóa phải có ở `audit_signing_key` | BR-13-013; FR-13-012 |
| `tg_audit_worm_batch_guard`, `ex_audit_worm_batch_range` | Lô WORM liền kề không chồng dải, không vượt đầu chuỗi; `retain_until` chỉ kéo dài | BR-13-013, 020; FR-13-013 |
| `ux_audit_verification_running`, `tg_audit_verification_guard` | Mỗi tenant một lượt `RUNNING`; kết quả đã chốt bất biến; `FAILED` phải có vị trí đứt | FR-13-014, 015; ERR-13-032 |
| `ck_audit_export_ready`, `_no_orphan_file`, `ux_audit_export_active`, `tg_audit_export_guard` | `READY` chỉ khi đã ký cả gói và bảng kê; không tệp chưa ký; không hai yêu cầu cùng phạm vi đang chạy; lý do, căn cứ từ 10 ký tự | BR-13-014, 029; FR-13-024 |
| `ck_audit_reconciliation_match`, `_mismatch`, `_surplus` | `MATCH` chỉ khi chênh lệch bằng 0 | BR-13-001; FR-13-017 |
| `tg_audit_partition_guard`, thủ tục `p_archive_partition` | `OPEN → SEALED → ARCHIVED` một chiều; chỉ tách phân vùng đã `SEALED`, đã xác minh WORM, đã đến hạn; chỉ `ph13_archive` gọi được | BR-13-002; FR-13-018; ERR-13-125 |
| `ck_audit_chain_suspect`, `ck_audit_chain_closed` | `SUSPECT` có vị trí nghi vấn; `CLOSED` có thời điểm và lý do | BR-13-012; FR-13-015, 060 |
| `ck_runbook_five_sections`, khóa ngoại `fk_alert_rule_runbook` (không rỗng) | Luật cảnh báo luôn có runbook đủ năm mục | BR-13-008; FR-13-042 |
| `ck_alert_rule_critical_symptom`, `ck_alert_rule_resource_only` | Nghiêm trọng phải có triệu chứng và không dựa thuần vào tài nguyên | BR-13-009 |
| `tg_platform_guard` | Luật và runbook `scope = PLATFORM` tenant không ghi, không tắt | BR-13-032; ERR-13-019 |
| `tg_alert_rule_guard` | Tối đa `13.alert.max-rules` luật riêng; vòng đời luật; mã không dùng lại | BR-13-031; ERR-13-041 |
| `tg_alert_guard` | Bảng chuyển trạng thái cảnh báo; tạm ẩn tối đa `13.alert.silence-max-days` (Nghiêm trọng 24 giờ) kèm lý do; leo thang từng cấp, chỉ Nghiêm trọng | BR-13-021, 022; ERR-13-020, 021 |
| `ux_alert_open`, `ck_alert_labels` | Một cảnh báo mở cho mỗi `(luật, fingerprint)`; nhãn `tenant` khớp `tenant_id` | BR-13-027; FR-13-044 |
| `ck_alert_action_resolve` | Đóng thủ công cần nguyên nhân, hành động, kết quả | BR-13-023; ERR-13-022 |
| `ck_detection_rule_limit`, `_threshold`, `_fixed`, `_tuned` | Ngưỡng nới tối đa 2 lần mặc định; luật không tắt được thì không đổi ngưỡng; đổi ngưỡng ghi người chỉnh | BR-13-025; ERR-13-024 |
| `ck_security_alert_closed`, `_accepted`, `ux_security_alert_open` | Đóng cần kết luận; chấp nhận rủi ro cần ghi chú; gom theo (luật, chủ thể) | BR-13-024; ERR-13-023 |
| `ck_siem_target_authority` | Điểm xuất cho cơ quan chuyên trách chỉ bật khi có số hiệu văn bản | BR-13-034; ERR-13-039 |
| `ck_tenant_obs_config_params` (hàm `fn_params_valid`) | Tham số `13.*` đúng khóa và miền, ví dụ `13.audit.worm-retention-years` từ 3 đến 10 | BR-13-020; ERR-13-040 |
| `ck_notification_channel_*`, `ck_alert_notification_recipient` | Webhook HTTPS kèm đường dẫn bí mật; không lưu số điện thoại, thư cá nhân | FR-13-046, 048; SEC-47 |
| `ck_*_no_secret` của `outbox` | Payload sự kiện không chứa khóa bí mật | BR-13-011 |
| `tg_guard_retention` (10 bảng) | Chỉ xóa dòng quá hạn lưu (2, 3, 5 năm hoặc 12 tháng theo bảng) | FRS §8.2; NFR-13-019 |
| `tg_forbid_delete` (15 bảng) | Mã bất biến, không dùng lại; xóa mềm | BR-13-031 |
| `tg_immutable` (24 bảng) | Mã, tenant, băm khởi đầu và các cột khóa không đổi sau khi tạo | BR-13-031 |

: Quy tắc nghiệp vụ chốt ở CSDL

Hai hạn chế cần biết. Thứ nhất, CSDL không tính lại `hash` vì băm tính trên bản ghi chuẩn tắc JCS do ứng dụng dựng (SDD §4.4); phát hiện băm sai là việc của lượt kiểm tra toàn vẹn. Thứ hai, người có quyền siêu người dùng hay chủ bảng có thể tắt trigger bằng `ALTER TABLE … DISABLE TRIGGER`; thao tác này được `pgaudit` ghi lại và `TamperProbe` đọc `pg_stat_user_tables` mỗi phút để phát UC-SEC-20 (SDD §4.4, §4.7). Neo ký và bản WORM nằm ngoài PostgreSQL chính là để chuỗi vẫn kiểm chứng được trong trường hợp đó.

Chuỗi sự kiện khi một lô bản ghi được ghi như sau.

```{.mermaid caption="Trình tự ghi một lô bản ghi vào chuỗi và các lớp kiểm tra của CSDL"}
sequenceDiagram
  participant CW as ChainWriter
  participant PG as PostgreSQL
  participant TG as tg_audit_chain_guard
  CW->>PG: BEGIN, set_config app.tenant_id, khóa tư vấn theo tenant
  CW->>PG: SELECT đầu chuỗi từ audit_chain
  CW->>PG: INSERT lô vào audit_event
  Note over PG: RLS WITH CHECK, CHECK cột, trigger chỉ-thêm
  CW->>PG: UPDATE audit_chain đặt head_seq, head_hash, last_recorded_at
  PG->>TG: BEFORE UPDATE
  TG->>PG: Đếm bản ghi liền kề, kiểm nối prev_hash, kiểm bản cuối
  alt liền kề và nối đúng
    TG-->>PG: Cho phép
    PG->>PG: COMMIT, kiểm constraint trigger hoãn
    PG-->>CW: Cam kết, ChainWriter xác nhận offset Kafka
  else khoảng trống, trùng hoặc nối sai
    TG-->>PG: Lỗi 23514
    PG-->>CW: Hủy giao dịch, thử lại giãn dần
  end
```

Hình cho thấy việc ghi chuỗi có ba lớp: ứng dụng đặt tenant và khóa theo tenant, CSDL kiểm từng cột và quyền, và trigger đầu chuỗi kiểm tính liền kề trước khi cam kết. Offset Kafka chỉ được xác nhận sau khi cam kết (BR-13-004).

### 1.5. Phân vùng, dung lượng và lưu trữ

`audit_event` phân vùng RANGE theo tháng của `recorded_at`, tên `audit_event_YYYYMM`. Ranh giới tháng tính theo múi giờ `Asia/Ho_Chi_Minh` (giả định, Q13-50) để tháng hiển thị cho người dùng trùng tháng lưu. Thủ tục `p_ensure_month_partitions(từ ngày, số tháng)` là `SECURITY DEFINER` nên vai trò ứng dụng tạo được phân vùng mà không có quyền DDL; `PartitionManager` gọi mỗi ngày để luôn có 3 tháng tới. Phân vùng thuộc `ph13_owner`, không cấp quyền riêng cho ai.

Vòng đời một phân vùng (FRS §4.7): `OPEN` trong tháng; hết tháng và khi mọi lô WORM đã sao, đã đối chiếu đủ thì `SEALED` (đồng thời ký neo `BOUNDARY`); quá thời hạn trực tuyến thì lưu trữ bằng thủ tục `p_archive_partition`.

```{.mermaid caption="Trình tự lưu trữ một phân vùng kiểm toán đã quá hạn trực tuyến"}
sequenceDiagram
  participant AS as ArchiveService
  participant WM as WORM
  participant OB as OpenBao
  participant PG as PostgreSQL
  AS->>WM: Đọc mọi lô của dải seq, so băm với bảng
  AS->>PG: Ghi worm_verified_at và archive_after vào audit_partition
  AS->>OB: Xin vai trò ph13_archive, TTL 15 phút
  AS->>PG: CALL p_archive_partition của tháng cần lưu trữ
  PG->>PG: Kiểm SEALED, worm_verified_at, archive_after đã đến
  alt đủ điều kiện
    PG->>PG: DETACH rồi DROP phân vùng, đặt ARCHIVED
    PG-->>AS: Xong
    AS->>AS: Ghi AUDIT.PARTITION.ARCHIVE và EVT-13-11
  else thiếu điều kiện
    PG-->>AS: Lỗi 23514, giữ SEALED, báo ERR-13-125
  end
```

Hình cho thấy ba điều kiện được kiểm cả ở dịch vụ lẫn ở thủ tục: bản WORM đã xác minh, phân vùng đã chốt và ngày lưu trữ đã đến. Lưu trữ là thao tác duy nhất làm bản ghi rời bảng trực tuyến; đối tượng WORM vẫn giữ bản đầy đủ.

Dung lượng ước tính theo hồ sơ `QM-VUA` (giả định GĐ-13-01: 100.000 bản ghi mỗi ngày, mỗi bản khoảng 1,5 KB), chưa đo thật; cần đo ở tỉnh thí điểm T68 rồi chỉnh định cỡ, không đổi thiết kế.

| Hạng mục | Mỗi tenant mỗi năm | 34 tenant, 12 tháng | Cơ sở |
|---|---|---|---|
| Số bản ghi | 36,5 triệu | khoảng 1,24 tỷ | 100.000 bản ghi mỗi ngày × 365 |
| Dữ liệu bảng | khoảng 55 GB | khoảng 1,9 TB | GĐ-13-01 |
| Chỉ mục (10 chỉ mục kể cả khóa chính) | khoảng 18 GB | khoảng 0,6 TB | Giả định khoảng 0,5 KB mỗi bản ghi theo cỡ khóa; cần đo |
| Tổng | khoảng 73 GB | khoảng 2,5 TB | |
| WAL phát sinh | khoảng 3 KB mỗi bản ghi | khoảng 120 KB/giây trung bình | Cỡ bản ghi cộng chỉ mục |

: Dung lượng ước tính của audit_event

Phân vùng được giữ theo giá trị lớn nhất của `13.audit.online-months` trong các tenant có bản ghi trong tháng đó (SDD §6, rủi ro R-13-07), nên một tenant đặt 24 tháng làm mọi tenant cùng giữ 24 tháng ở bảng trực tuyến; chi phí trong trường hợp xấu nhất khoảng 5 TB. Giải pháp lâu dài (phân vùng con theo nhóm tenant, hoặc cụm `pg-audit` riêng) được ghi ở mục đề nghị đồng bộ, không quyết định ở đây.

Bảng `ph13_obs` nhỏ so với kiểm toán: cảnh báo của một tenant khoảng vài chục nghìn dòng mỗi năm và thao tác xử lý, thông báo tỷ lệ tương ứng (giả định, theo số cảnh báo mục tiêu của KPI-15); không phân vùng.

## 2. Sơ đồ thực thể – quan hệ

Hai sơ đồ dưới đây vẽ riêng từng schema vì hai miền không có khóa ngoại với nhau. Đường liền là khóa ngoại thật (kèm `tenant_id` khi cùng bảng tenant). Đường chấm là liên kết theo giá trị (`tenant_id`, `seq`, mã) không có khóa ngoại, vì bảng đích là bảng phân vùng không nhận khóa ngoại vào, hoặc vì dữ liệu do tiến trình khác ghi.

```{.mermaid caption="Sơ đồ thực thể – quan hệ của schema ph13_audit"}
erDiagram
  audit_signing_key ||--o{ audit_anchor : "khóa ký (key_version)"
  audit_signing_key ||--o{ audit_export : "khóa ký gói"
  audit_anchor ||--o| audit_anchor_publish : "công bố WORM, SIEM"
  audit_chain ||..o{ audit_event : "theo (tenant_id, seq)"
  audit_chain ||..o{ audit_anchor : "neo đầu chuỗi"
  audit_chain ||..o{ audit_worm_batch : "lô theo dải seq"
  audit_chain ||..o{ audit_verification : "xác minh"
  audit_chain ||..o{ audit_export : "xuất bằng chứng"
  audit_partition ||..o{ audit_event : "theo tháng recorded_at"
  audit_source_grant ||..o{ audit_quarantine : "nguồn (DU, tenant)"
  audit_reconciliation }o..|| audit_chain : "đối chiếu theo tenant"
  outbox {
    uuid event_id
  }
  shedlock {
    varchar name
  }
```

Sơ đồ cho thấy `audit_chain` là gốc của miền: mọi bảng còn lại gắn vào chuỗi của một tenant theo `tenant_id`. Chỉ ba quan hệ là khóa ngoại thật (khóa ký tới neo và gói bằng chứng, neo tới nơi công bố); `audit_event` không có khóa ngoại vì phân vùng theo `recorded_at`, thay vào đó trigger của `audit_chain` bảo đảm liền kề và nối đúng.

```{.mermaid caption="Sơ đồ thực thể – quan hệ của schema ph13_obs"}
erDiagram
  runbook ||--o{ alert_rule : "hướng dẫn xử lý"
  alert_rule ||--o{ alert : "sinh ra (tenant, rule_code)"
  alert ||--o{ alert_action : "thao tác xử lý"
  alert ||--o{ alert_notification : "lượt gửi"
  security_alert ||--o{ alert_notification : "lượt gửi (an ninh)"
  notification_channel ||--o{ alert_notification : "kênh gửi"
  oncall_schedule ||..o{ notification_channel : "cấp leo thang dùng kênh"
  detection_rule ||--o{ security_alert : "sinh ra (tenant, rule_code)"
  detection_rule ||--o| detect_cursor : "mốc xử lý"
  security_alert ||--o{ incident_report : "báo cáo sự cố"
  tenant_obs_config {
    uuid tenant_id
  }
  siem_target {
    varchar target_code
  }
  dashboard_set {
    varchar set_code
  }
  saved_query {
    varchar name
  }
  probe_definition {
    varchar probe_code
  }
  pii_finding {
    varchar du_code
  }
  outbox {
    uuid event_id
  }
  shedlock {
    varchar name
  }
```

Sơ đồ cho thấy hai cụm có quan hệ thật: cụm cảnh báo vận hành (runbook, luật, cảnh báo, thao tác, thông báo, kênh) và cụm an ninh (luật phát hiện, cảnh báo an ninh, báo cáo sự cố); `alert_notification` nối hai cụm vì một lượt gửi thuộc đúng một trong hai loại cảnh báo (`CHECK` `ck_alert_notification_subject`). Các bảng còn lại (cấu hình tenant, SIEM, dashboard, truy vấn đã lưu, kiểm tra tổng hợp, kết quả quét) đứng riêng và chỉ gắn với tenant.

## 3. Đặc tả bảng

Chương này đặc tả 33 bảng của hai schema. Bảng tổng hợp ngay dưới cho biết mỗi bảng thuộc thực thể nào, có đặc tính gì và lưu bao lâu; phần chi tiết ở mục 3.1 và 3.2 mở đầu mỗi bảng bằng một khối đặc tả 10 mục (mục đích, FR phục vụ, khóa chính, khóa duy nhất, khóa ngoại, ràng buộc `CHECK`, chỉ mục, cách ly tenant, phân vùng và chỉ thêm, ghi chú) rồi đến danh sách cột. Mục 3.3 liệt kê các truy vấn chính và chỉ mục phục vụ chúng.

Hai mươi hai thực thể EN-13-01…22 của FRS §4.2 ứng với 22 bảng. Mười một bảng còn lại do SDD yêu cầu và không phải thực thể nghiệp vụ: `audit_signing_key` (khóa công khai theo phiên bản, SDD §4.5), `audit_anchor_publish` (tách nơi công bố khỏi neo để neo thuần chỉ-thêm, SDD §4.5), `audit_worm_batch` (lô WORM, SDD §4.6), `audit_quarantine` và `audit_source_grant` (bộ tiếp nhận, SDD §4.3), `pii_finding` (kết quả quét, SDD §4.12), `detect_cursor` (mốc bộ phát hiện, SDD §4.20), hai bảng `outbox` và hai bảng `shedlock` (một bộ cho mỗi module).

| STT | Schema | Bảng | Thực thể | Cột | Đặc tính | Lưu giữ |
|---|---|---|---|---|---|---|
| 1 | `ph13_audit` | `audit_signing_key` | Hỗ trợ | 15 | — | Vĩnh viễn (khóa công khai mọi phiên bản) |
| 2 | `ph13_audit` | `audit_chain` | EN-13-03 | 18 | — | Vĩnh viễn, không xóa |
| 3 | `ph13_audit` | `audit_event` | EN-13-01 | 28 | Phân vùng tháng, chỉ thêm | 12 tháng trực tuyến (tenant đặt 12 đến 24), WORM 5 năm (3 đến 10) |
| 4 | `ph13_audit` | `audit_anchor` | EN-13-02 | 11 | Chỉ thêm | Vĩnh viễn |
| 5 | `ph13_audit` | `audit_anchor_publish` | Hỗ trợ | 13 | — | Vĩnh viễn |
| 6 | `ph13_audit` | `audit_worm_batch` | Hỗ trợ | 15 | — | Vĩnh viễn (siêu dữ liệu), đối tượng theo Object Lock |
| 7 | `ph13_audit` | `audit_verification` | EN-13-04 | 19 | — | 5 năm |
| 8 | `ph13_audit` | `audit_export` | EN-13-05 | 26 | — | 5 năm (tệp 7 ngày) |
| 9 | `ph13_audit` | `audit_reconciliation` | EN-13-06 | 16 | — | 5 năm |
| 10 | `ph13_audit` | `audit_partition` | EN-13-21 | 15 | — | Vĩnh viễn |
| 11 | `ph13_audit` | `audit_quarantine` | Hỗ trợ | 20 | — | 90 ngày sau khi cách ly (giả định, Q13-53) |
| 12 | `ph13_audit` | `audit_source_grant` | Hỗ trợ | 12 | — | Vĩnh viễn (thu hồi bằng trạng thái) |
| 13 | `ph13_audit` | `outbox` | Hỗ trợ | 9 | — | 3 ngày |
| 14 | `ph13_audit` | `shedlock` | Hỗ trợ | 4 | — | Kỹ thuật |
| 15 | `ph13_obs` | `tenant_obs_config` | EN-13-19 | 15 | — | Vĩnh viễn |
| 16 | `ph13_obs` | `runbook` | EN-13-08 | 17 | — | Vĩnh viễn (xóa mềm) |
| 17 | `ph13_obs` | `alert_rule` | EN-13-07 | 27 | — | Vĩnh viễn (xóa mềm) |
| 18 | `ph13_obs` | `notification_channel` | EN-13-13 | 17 | — | Vĩnh viễn (xóa mềm) |
| 19 | `ph13_obs` | `oncall_schedule` | EN-13-12 | 14 | — | Vĩnh viễn (xóa mềm) |
| 20 | `ph13_obs` | `alert` | EN-13-09 | 24 | — | 2 năm |
| 21 | `ph13_obs` | `alert_action` | EN-13-11 | 15 | Chỉ thêm (xóa khi hết hạn lưu) | 2 năm |
| 22 | `ph13_obs` | `detection_rule` | EN-13-14 | 21 | — | Vĩnh viễn |
| 23 | `ph13_obs` | `security_alert` | EN-13-15 | 22 | — | 3 năm sau khi đóng |
| 24 | `ph13_obs` | `incident_report` | EN-13-22 | 17 | — | 5 năm |
| 25 | `ph13_obs` | `alert_notification` | EN-13-10 | 18 | — | 2 năm |
| 26 | `ph13_obs` | `siem_target` | EN-13-16 | 18 | — | Vĩnh viễn (xóa mềm) |
| 27 | `ph13_obs` | `dashboard_set` | EN-13-17 | 15 | — | Vĩnh viễn |
| 28 | `ph13_obs` | `saved_query` | EN-13-18 | 12 | — | Tới khi chủ sở hữu xóa |
| 29 | `ph13_obs` | `probe_definition` | EN-13-20 | 16 | — | Vĩnh viễn (xóa mềm) |
| 30 | `ph13_obs` | `pii_finding` | Hỗ trợ | 11 | — | 12 tháng |
| 31 | `ph13_obs` | `detect_cursor` | Hỗ trợ | 4 | — | Kỹ thuật |
| 32 | `ph13_obs` | `outbox` | Hỗ trợ | 9 | — | 3 ngày |
| 33 | `ph13_obs` | `shedlock` | Hỗ trợ | 4 | — | Kỹ thuật |

: Tổng hợp 33 bảng của PH-13

Phần dưới sinh bằng [`ph13/tools/gen_tables_md.py`](ph13/tools/gen_tables_md.py) từ DDL (`COMMENT ON`, `CHECK`) rồi thêm khối đặc tả bằng [`ph13/tools/them_dac_ta_bang.py`](ph13/tools/them_dac_ta_bang.py); sửa ở DDL rồi sinh lại, không sửa tay.

<!-- gen:tables:start -->
### 3.1. Nhóm kiểm toán (schema `ph13_audit`)

Mười bốn bảng của module `audit`: chuỗi băm và bản ghi chỉ-thêm, neo và nơi công bố, lô WORM, xác minh, xuất bằng chứng, đối chiếu số lượng, vòng đời phân vùng, kho cách ly và bảng kỹ thuật. Mọi bảng có `tenant_id` và `FORCE ROW LEVEL SECURITY`, riêng `audit_signing_key` dùng mẫu S (mọi tenant đọc khóa công khai nền tảng).

#### 3.1.1. `audit_signing_key`

::: dac-ta
**Mục đích.** Khóa công khai của khóa ký neo và gói bằng chứng dh-audit-sign theo phiên bản (SDD §4.5, Q13-13). Vì là khóa của nền tảng, tenant_id luôn là PLATFORM; mọi tenant đọc được để xác minh, chỉ phiên PLATFORM ghi. Khóa riêng ở OpenBao Transit, không xuất.

**FR phục vụ.** FR-13-012, 024.

**Khóa chính.** (id).

**Duy nhất.** `uq_audit_signing_key_version` (key_version), `ux_audit_signing_key_active` (key_name) (một phần).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_audit_signing_key_tenant`, `ck_audit_signing_key_version`, `ck_audit_signing_key_alg`, `ck_audit_signing_key_status`, `ck_audit_signing_key_pem`, `ck_audit_signing_key_retired`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu S (FORCE): mọi tenant đọc dòng `PLATFORM` và dòng của mình; chỉ phiên `PLATFORM` ghi (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_audit_signing_key_nodel`).

**Ghi chú.** Bảng dùng chung mẫu S: mọi tenant đọc khóa công khai để xác minh ngoại tuyến, chỉ phiên PLATFORM ghi; khóa riêng không bao giờ ở CSDL. Cột bất biến sau khi tạo: `id`, `tenant_id`, `key_version`, `algorithm`, `key_name`, `public_key_pem`, `activated_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x | `'PLATFORM'` | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `key_version` | `integer` | x |  | Số phiên bản của khóa ở OpenBao; neo mang key_version để kiểm lại bằng khóa công khai cũ. |
| `algorithm` | `varchar(16)` | x | `'ECDSA-P256'` | Giá trị: `ECDSA-P256`. |
| `key_name` | `varchar(64)` | x | `'dh-audit-sign'` | Tên khóa ở OpenBao Transit; chỉ một phiên bản `ACTIVE` mỗi tên. |
| `public_key_pem` | `text` | x |  | Khóa công khai dạng PEM để xác minh ngoại tuyến. |
| `status` | `varchar(8)` | x | `'ACTIVE'` | Giá trị: `ACTIVE`, `ROTATED`. |
| `activated_at` | `timestamptz` | x | `now()` | Thời điểm phiên bản khóa bắt đầu dùng. |
| `retired_at` | `timestamptz` |  |  | Thời điểm xoay sang phiên bản mới (`ROTATED`). |
| `worm_object` | `varchar(512)` |  |  | Đối tượng keys/dh-audit-sign.json ở WORM chứa khóa công khai, để xác minh không phụ thuộc OpenBao. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_audit.audit_signing_key`

#### 3.1.2. `audit_chain`

::: dac-ta
**Mục đích.** EN-13-03 Chuỗi kiểm toán, mỗi tenant một dòng (tenant PLATFORM cũng có chuỗi riêng). Đầu chuỗi chỉ nhích qua trigger tg_audit_chain_guard (FR-13-011, 059, 060). Không xóa dòng.

**FR phục vụ.** FR-13-011, 014, 015, 059, 060.

**Khóa chính.** (id).

**Duy nhất.** `uq_audit_chain_tenant` (tenant_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_audit_chain_tenant`, `ck_audit_chain_genesis`, `ck_audit_chain_head_hash`, `ck_audit_chain_head`, `ck_audit_chain_last_recorded`, `ck_audit_chain_status`, `ck_audit_chain_integrity`, `ck_audit_chain_suspect`, `ck_audit_chain_closed`, `ck_audit_chain_merged`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_audit_chain_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_audit_chain_nodel`).

**Ghi chú.** Đầu chuỗi chỉ nhích khi các bản ghi mới liền kề, nối đúng và bản cuối khớp `head_hash` (trigger `tg_audit_chain_guard`); không xóa dòng, không đổi `genesis_hash`. Trigger bảo vệ: `tg_audit_chain_guard` (Đầu chuỗi chỉ nhích khi các bản ghi mới liền kề, nối đúng prev_hash, bản cuối khớp head_hash). Cột bất biến sau khi tạo: `id`, `tenant_id`, `genesis_hash`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `genesis_hash` | `char(64)` | x |  | SHA-256("genesis:" ‖ mã tenant ‖ thời điểm ‖ nonce); prev_hash của bản ghi đầu tiên. Mẫu `^[0-9a-f]{64}$`. |
| `head_seq` | `bigint` | x | `0` | seq của bản ghi cuối; 0 khi chuỗi chưa có bản ghi. Chỉ tăng. |
| `head_hash` | `char(64)` | x |  | Mẫu `^[0-9a-f]{64}$`. |
| `last_recorded_at` | `timestamptz` |  |  | recorded_at của bản ghi cuối; không lùi (giữ phân vùng đơn điệu), làm cận cắt phân vùng cho truy vấn. |
| `status` | `varchar(8)` | x | `'OPEN'` | Giá trị: `OPEN`, `CLOSED`. |
| `integrity` | `varchar(8)` | x | `'OK'` | OK hoặc SUSPECT (đứt chuỗi, neo lệch, TamperProbe); tách khỏi status vì chuỗi OPEN vẫn nhận bản ghi khi SUSPECT (FR-13-015). Giá trị: `OK`, `SUSPECT`. |
| `suspect_from_seq` | `bigint` |  |  | `seq` bắt đầu đoạn nghi vấn khi `SUSPECT`. |
| `suspect_since` | `timestamptz` |  |  | Thời điểm đánh dấu `SUSPECT`. |
| `closed_at` | `timestamptz` |  |  | Thời điểm đóng chuỗi (tenant ngừng hoặc sáp nhập). |
| `closed_reason` | `varchar(500)` |  |  | Lý do đóng chuỗi; ghi cả vào bản ghi `CHAIN.CLOSE`. |
| `merged_into` | `varchar(16)` |  |  | Tenant đích khi tenant nguồn sáp nhập; chuỗi nguồn không gộp vật lý (FR-13-060). Mẫu `^T[0-9]{2}$`. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_audit.audit_chain`

#### 3.1.3. `audit_event`

::: dac-ta
**Mục đích.** EN-13-01 Bản ghi kiểm toán, chỉ thêm, phân vùng tháng theo recorded_at; trực tuyến 12 tháng, WORM 5 năm (FR-13-010, 011, 018). seq liên tục theo tenant, hash nối chuỗi; PH-13 gán seq, recorded_at, source_du, prev_hash, hash.

**FR phục vụ.** FR-13-010, 011, 018, 020…023.

**Khóa chính.** (tenant_id, seq, recorded_at).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_audit_event_tenant`, `ck_audit_event_home_tenant`, `ck_audit_event_seq`, `ck_audit_event_actor_type`, `ck_audit_event_system_actor`, `ck_audit_event_action`, `ck_audit_event_outcome`, `ck_audit_event_trace`, `ck_audit_event_hashes`, `ck_audit_event_hmac`, `ck_audit_event_session`, `ck_audit_event_json_shape`, `ck_audit_event_json_size`, `ck_audit_event_no_secret`, `ck_audit_event_reason`.

**Chỉ mục.** `ix_audit_event_time`, `ix_audit_event_object`, `ix_audit_event_actor`, `ix_audit_event_action`, `ix_audit_event_trace`, `ix_audit_event_keyhmac`, `ix_audit_event_id`, `ix_audit_event_source`, `ix_audit_event_session`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_audit_event_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Phân vùng RANGE theo tháng trên `recorded_at` (thủ tục `p_ensure_month_partitions`, cận Asia/Ho_Chi_Minh); lưu trữ bằng `p_archive_partition`; Chỉ thêm, chặn UPDATE, DELETE (trigger `tg_audit_event_append`, BR-13-002); Chỉ thêm, chặn TRUNCATE (trigger `tg_audit_event_truncate`, BR-13-002).

**Ghi chú.** Phân vùng theo `recorded_at` nên khóa chính chỉ duy nhất trong từng phân vùng; khử trùng theo `(tenant_id, id)` ở bộ tiếp nhận (SDD §4.3). Cột `hash` do ChainWriter tính theo JCS (SDD §4.4); CSDL không tính lại mà kiểm tính liền kề và nối `prev_hash` khi đầu chuỗi nhích. Phân vùng không cấp quyền riêng cho ai. Trigger bảo vệ: `tg_audit_event_covered` (Constraint trigger hoãn: bản ghi chỉ cam kết khi audit_chain.head_seq đã bao phủ seq của nó (không có bản ghi mồ côi ngoài chuỗi)).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | UUID v7 do DU sinh; khử trùng theo (tenant_id, id) với cận recorded_at (SDD §4.3), không ràng buộc duy nhất vì bảng phân vùng theo recorded_at. |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `seq` | `bigint` | x |  | Liên tục trong chuỗi tenant, không khoảng trống; trigger tg_audit_chain_guard kiểm khi đầu chuỗi nhích. |
| `occurred_at` | `timestamptz` | x |  | Giờ DU ghi nhận thao tác (đồng hồ nguồn); lệch quá 2 giây về tương lai thì đặt `clock_skew`. |
| `recorded_at` | `timestamptz` | x |  | Giờ ghi vào bảng, quyết định phân vùng; không lùi theo tenant (ChainWriter dùng max(now, last_recorded_at)). |
| `actor_type` | `varchar(6)` | x |  | Giá trị: `USER`, `CLIENT`, `SYSTEM`. |
| `actor_id` | `varchar(128)` | x |  | Mã người dùng hoặc client; `system:{du}` cho tác vụ tự động. |
| `actor_name` | `varchar(255)` | x |  | Tên hiển thị của tác nhân tại thời điểm thao tác. |
| `actor_home_tenant` | `varchar(16)` |  |  | Mẫu `^(T[0-9]{2}\|PLATFORM)$`. |
| `source_ip` | `varchar(45)` | x |  | Địa chỉ nguồn (IPv4 hoặc IPv6) của thao tác. |
| `user_agent` | `varchar(512)` | x |  | Chuỗi định danh trình khách. |
| `session_hash` | `char(64)` |  |  | Mẫu `^[0-9a-f]{64}$`. |
| `action` | `varchar(96)` | x |  | Mẫu `^[A-Z][A-Z0-9_]*(\.[A-Z0-9_]+)+$`. |
| `object_type` | `varchar(64)` | x |  | Loại đối tượng bị tác động; dùng cho tab Lịch sử. |
| `object_id` | `varchar(128)` | x |  | Mã đối tượng bị tác động. |
| `object_key_hmac` | `char(64)` |  |  | HMAC-SHA256 theo khóa tenant dh-{tenant}-audit-hmac của khóa nghiệp vụ nhạy cảm (số định danh); không bao giờ lưu số định danh thật (BR-13-005). Mẫu `^[0-9a-f]{64}$`. |
| `before` | `jsonb` |  |  | Giá trị trước đã che theo D03-07 §3.2; ck_audit_event_no_secret chặn khóa bí mật mang giá trị chưa che (BR-13-035). JSON object. |
| `after` | `jsonb` |  |  | JSON object. |
| `outcome` | `varchar(7)` | x |  | Giá trị: `SUCCESS`, `DENIED`, `FAILED`. |
| `error_code` | `varchar(32)` |  |  | Mã lỗi khi `outcome` là `DENIED` hoặc `FAILED`. |
| `reason` | `varchar(500)` |  |  | Lý do do người thao tác nhập (10 đến 500 ký tự khi bắt buộc, kiểm ở dịch vụ). |
| `purpose` | `varchar(64)` |  |  | Mục đích khai báo của thao tác truy cập dữ liệu. |
| `trace_id` | `char(32)` | x |  | Mẫu `^[0-9a-f]{32}$`. |
| `source_du` | `varchar(32)` | x |  | DU nguồn do PH-13 điền theo chứng thư của bên gửi; dùng đối chiếu số lượng (FR-13-017). |
| `clock_skew` | `boolean` | x | `false` | true khi occurred_at lệch giờ PH-13 quá 2 giây về tương lai (ERR-13-126); vẫn ghi. |
| `hash_version` | `smallint` | x | `1` | Phiên bản thuật toán dựng bản ghi chuẩn tắc (v trong R, SDD §4.4); hiện là 1. |
| `prev_hash` | `char(64)` | x |  | Mẫu `^[0-9a-f]{64}$`. |
| `hash` | `char(64)` | x |  | hash = SHA-256(prev_hash ‖ JCS(R)), R gồm mọi cột trừ hash, kèm hash_version (SDD §4.4). Mẫu `^[0-9a-f]{64}$`. |

: Cột của bảng `ph13_audit.audit_event`

#### 3.1.4. `audit_anchor`

::: dac-ta
**Mục đích.** EN-13-02 Neo toàn vẹn: tóm tắt {tenant, seq cuối, hash cuối, thời điểm} ký bằng dh-audit-sign mỗi giờ; chỉ thêm, giữ vĩnh viễn (FR-13-012). Nơi công bố (WORM, SIEM) ở audit_anchor_publish để bảng này thuần chỉ-thêm.

**FR phục vụ.** FR-13-012, 014, 015.

**Khóa chính.** (id).

**Duy nhất.** `uq_audit_anchor_time` (tenant_id, anchored_at).

**Khóa ngoại.** (key_version) → `audit_signing_key`.

**Ràng buộc CHECK.** `ck_audit_anchor_tenant`, `ck_audit_anchor_seq`, `ck_audit_anchor_hash`, `ck_audit_anchor_kind`, `ck_audit_anchor_signature`.

**Chỉ mục.** `ix_audit_anchor_seq`, `ix_audit_anchor_kind`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_audit_anchor_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ thêm, chặn UPDATE, DELETE (trigger `tg_audit_anchor_append`, BR-13-002); Chỉ thêm, chặn TRUNCATE (trigger `tg_audit_anchor_truncate`, BR-13-002).

**Ghi chú.** Thuần chỉ-thêm; nơi công bố tách sang `audit_anchor_publish` để không phải cập nhật bảng này. `key_version` nối tới khóa công khai ở `audit_signing_key`. Trigger bảo vệ: `tg_audit_anchor_guard` (Neo không lùi, không vượt đầu chuỗi, không thêm sau neo FINAL (BR-13-013, SDD §4.5)).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `seq_last` | `bigint` | x |  | `seq` của bản ghi cuối được neo. |
| `hash_last` | `char(64)` | x |  | Mẫu `^[0-9a-f]{64}$`. |
| `anchored_at` | `timestamptz` | x |  | Thời điểm ký neo; duy nhất theo tenant. |
| `kind` | `varchar(8)` | x | `'PERIODIC'` | PERIODIC (hằng giờ), BOUNDARY (ranh giới phân vùng tháng, điểm xuất phát sau lưu trữ), FINAL (neo cuối khi đóng chuỗi). Giá trị: `PERIODIC`, `BOUNDARY`, `FINAL`. |
| `key_version` | `integer` | x |  | Phiên bản khóa ký, trỏ `audit_signing_key`. |
| `payload_digest` | `char(64)` | x |  | SHA-256("datahub-audit-anchor-v1\n" ‖ tải JCS); tiền tố tên miền để chữ ký neo không dùng lại cho gói bằng chứng. Mẫu `^[0-9a-f]{64}$`. |
| `signature` | `text` | x |  | Chữ ký ASN.1 (base64) từ transit/sign/dh-audit-sign/sha2-256, prehashed. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `ph13_audit.audit_anchor`

#### 3.1.5. `audit_anchor_publish`

::: dac-ta
**Mục đích.** Nơi công bố của neo: đối tượng anchors/{tenant}/{yyyy}/{MM}/{dd}/{HH}.json ở WORM và xác nhận của SIEM (EN-13-02 cột worm_object, siem_ack_at; FR-13-012, BR-13-013). Neo vẫn hợp lệ khi chưa công bố (worm_pending).

**FR phục vụ.** FR-13-012, 013, 054.

**Khóa chính.** (id).

**Duy nhất.** `uq_audit_anchor_publish_anchor` (anchor_id).

**Khóa ngoại.** (anchor_id, tenant_id) → `audit_anchor`.

**Ràng buộc CHECK.** `ck_audit_anchor_publish_tenant`, `ck_audit_anchor_publish_worm`, `ck_audit_anchor_publish_worm_time`, `ck_audit_anchor_publish_siem`.

**Chỉ mục.** `ix_audit_anchor_publish_pending`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_audit_anchor_publish_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_audit_anchor_publish_nodel`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Cột bất biến sau khi tạo: `id`, `tenant_id`, `anchor_id`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `anchor_id` | `uuid` | x |  | Neo được công bố (một nơi công bố cho một neo). |
| `worm_object` | `varchar(512)` |  |  | Khóa đối tượng `anchors/{tenant}/{yyyy}/{MM}/{dd}/{HH}.json` ở WORM. |
| `worm_written_at` | `timestamptz` |  |  | Thời điểm ghi WORM thành công. |
| `worm_pending` | `boolean` | x | `true` | true khi chưa ghi được WORM (ERR-13-108); neo vẫn có ở bảng audit_anchor. |
| `siem_target_code` | `varchar(64)` |  |  | Mục tiêu SIEM đã nhận neo. |
| `siem_ack_at` | `timestamptz` |  |  | Thời điểm SIEM xác nhận đã nhận. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_audit.audit_anchor_publish`

#### 3.1.6. `audit_worm_batch`

::: dac-ta
**Mục đích.** Lô JSON Lines nén zstd đã sao sang WORM (Ceph RGW, Object Lock COMPLIANCE) mỗi 13.audit.worm-batch-minutes (FR-13-013). Dải seq liền kề không chồng; các lô nối nhau bằng prev_batch_sha256 thành chuỗi thứ hai. Siêu dữ liệu giữ cả sau khi đối tượng hết hạn khóa.

**FR phục vụ.** FR-13-013, 014, 018.

**Khóa chính.** (id).

**Duy nhất.** `uq_audit_worm_batch_object` (tenant_id, object_key), `uq_audit_worm_batch_from` (tenant_id, seq_from).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_audit_worm_batch_tenant`, `ck_audit_worm_batch_range`, `ck_audit_worm_batch_count`, `ck_audit_worm_batch_sha`, `ck_audit_worm_batch_first`, `ck_audit_worm_batch_size`, `ck_audit_worm_batch_key`.

**Chỉ mục.** `ix_audit_worm_batch_unverified`, `ix_audit_worm_batch_retain`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_audit_worm_batch_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_audit_worm_batch_nodel`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Trigger bảo vệ: `tg_audit_worm_batch_guard` (Lô WORM liền kề không chồng, không vượt đầu chuỗi). Cột bất biến sau khi tạo: `id`, `tenant_id`, `seq_from`, `seq_to`, `record_count`, `object_key`, `manifest_key`, `sha256`, `prev_batch_sha256`, `size_bytes`, `created_at`. Ràng buộc loại trừ: `ex_audit_worm_batch_range`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `seq_from` | `bigint` | x |  | `seq` đầu của lô; liền sau `seq_to` của lô trước. |
| `seq_to` | `bigint` | x |  | `seq` cuối của lô. |
| `record_count` | `integer` | x |  | Số bản ghi, bằng `seq_to - seq_from + 1`, tối đa 50.000. |
| `object_key` | `varchar(512)` | x |  | Mẫu `^audit/[A-Za-z0-9]+/[0-9]{4}/[0-9]{2}/[0-9]{2}/[0-9]+-[0-9]+\.jsonl\.zst$`. |
| `manifest_key` | `varchar(512)` | x |  | Khóa tệp `manifest.json` đi kèm (đếm, dải `seq`, băm, băm lô trước). |
| `sha256` | `char(64)` | x |  | Băm của tệp lô; trùng manifest.sha256 trên WORM. Mẫu `^[0-9a-f]{64}$`. |
| `prev_batch_sha256` | `char(64)` |  |  | Mẫu `^[0-9a-f]{64}$`. |
| `etag` | `varchar(128)` |  |  | ETag do kho trả; đối chiếu bằng HeadObject trước khi ghi verified_at (Q13-23 nếu RGW mã hóa làm ETag không còn là MD5). |
| `size_bytes` | `bigint` | x |  | Kích thước tệp nén (byte). |
| `retain_until` | `timestamptz` | x |  | Hạn Object Lock = ngày ghi + 13.audit.worm-retention-years; chỉ kéo dài (RetentionExtender). |
| `verified_at` | `timestamptz` |  |  | Thời điểm HeadObject đối chiếu ETag khớp; null thì lô chưa đủ điều kiện cho phân vùng SEALED. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `ph13_audit.audit_worm_batch`

#### 3.1.7. `audit_verification`

::: dac-ta
**Mục đích.** EN-13-04 Lượt xác minh toàn vẹn chuỗi, theo lịch (DAILY) hoặc theo yêu cầu (ON_DEMAND); giữ 5 năm (FR-14, SDD §4.7). Mỗi tenant một lượt RUNNING (ERR-13-032).

**FR phục vụ.** FR-13-014, 015.

**Khóa chính.** (id).

**Duy nhất.** `ux_audit_verification_running` (tenant_id) (một phần).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_audit_verification_tenant`, `ck_audit_verification_scope`, `ck_audit_verification_worm_mode`, `ck_audit_verification_range`, `ck_audit_verification_status`, `ck_audit_verification_break`, `ck_audit_verification_break_kind`, `ck_audit_verification_finished`, `ck_audit_verification_worm_check`, `ck_audit_verification_passed_worm`, `ck_audit_verification_count`.

**Chỉ mục.** `ix_audit_verification_tenant`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_audit_verification_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ xóa dòng quá hạn lưu 5 năm tính từ `started_at` (trigger `tg_audit_verification_ret`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Trigger bảo vệ: `tg_audit_verification_guard` (Lượt xác minh đã PASSED hoặc FAILED là bất biến). Cột bất biến sau khi tạo: `id`, `tenant_id`, `scope`, `from_seq`, `requested_by`, `started_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `scope` | `varchar(10)` | x |  | Giá trị: `DAILY`, `ON_DEMAND`. |
| `worm_mode` | `varchar(6)` | x | `'SAMPLE'` | Cách đối chiếu bản WORM: mẫu 1%, đủ hoặc không. Giá trị: `SAMPLE`, `FULL`, `NONE`. |
| `from_seq` | `bigint` | x |  | `seq` bắt đầu đoạn kiểm tra (neo xuất phát). |
| `to_seq` | `bigint` | x |  | `seq` cuối đoạn kiểm tra. |
| `status` | `varchar(8)` | x | `'RUNNING'` | Giá trị: `RUNNING`, `PASSED`, `FAILED`. |
| `first_break_seq` | `bigint` |  |  | seq nhỏ nhất bị đứt khi FAILED; vị trí đứt đầu tiên (FR-13-014, 015). |
| `break_kind` | `varchar(32)` |  |  | Giá trị: `HASH_MISMATCH`, `SEQ_GAP`, `ANCHOR_SIGNATURE_INVALID`, `ANCHOR_MISMATCH`, `WORM_MISMATCH`. |
| `checked_count` | `bigint` | x | `0` | Số bản ghi đã tính lại băm. |
| `worm_check` | `varchar(12)` |  |  | FULL (so đủ), SAMPLE (so mẫu 1%), NONE, UNAVAILABLE (WORM không đọc được: không báo đạt hoàn toàn). Giá trị: `FULL`, `SAMPLE`, `NONE`, `UNAVAILABLE`. |
| `requested_by` | `varchar(64)` | x |  | Người hoặc tác vụ yêu cầu (mã người dùng hoặc `system:*`). |
| `started_at` | `timestamptz` | x | `now()` | Thời điểm bắt đầu. |
| `finished_at` | `timestamptz` |  |  | Thời điểm kết thúc. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_audit.audit_verification`

#### 3.1.8. `audit_export`

::: dac-ta
**Mục đích.** EN-13-05 Yêu cầu xuất bằng chứng kiểm toán ký số, chạy nền (FR-13-024). Siêu dữ liệu giữ 5 năm, tệp 7 ngày. Không hai yêu cầu cùng scope_hash đang chạy (ux_audit_export_active); READY chỉ khi đã ký.

**FR phục vụ.** FR-13-024.

**Khóa chính.** (id).

**Duy nhất.** `ux_audit_export_active` (tenant_id, scope_hash) (một phần).

**Khóa ngoại.** (key_version) → `audit_signing_key`.

**Ràng buộc CHECK.** `ck_audit_export_tenant`, `ck_audit_export_filter`, `ck_audit_export_scope_hash`, `ck_audit_export_reason`, `ck_audit_export_basis`, `ck_audit_export_status`, `ck_audit_export_count`, `ck_audit_export_file_hash`, `ck_audit_export_ready`, `ck_audit_export_no_orphan_file`, `ck_audit_export_failed`, `ck_audit_export_cancelled`, `ck_audit_export_download`.

**Chỉ mục.** `ix_audit_export_queue`, `ix_audit_export_expiry`, `ix_audit_export_tenant`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_audit_export_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ xóa dòng quá hạn lưu 5 năm tính từ `created_at` (trigger `tg_audit_export_ret`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Trigger bảo vệ: `tg_audit_export_guard` (Bảng chuyển trạng thái yêu cầu xuất bằng chứng (FRS §4.6, SDD §8.1)). Cột bất biến sau khi tạo: `id`, `tenant_id`, `filter`, `scope_hash`, `reason`, `basis`, `reauth_at`, `requested_by`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `filter` | `jsonb` | x |  | JSON object. |
| `scope_hash` | `char(64)` | x |  | SHA-256 của bộ lọc đã chuẩn hóa; khóa lũy đẳng chống chạy trùng. Mẫu `^[0-9a-f]{64}$`. |
| `reason` | `varchar(500)` | x |  | Từ 10 đến 500 ký tự. |
| `basis` | `varchar(500)` | x |  | Căn cứ pháp lý, số hiệu yêu cầu của cơ quan hoặc kế hoạch thanh tra; bắt buộc (BR-13-007). Từ 10 đến 500 ký tự. |
| `reauth_at` | `timestamptz` | x |  | Thời điểm xác thực lại phiên (step-up) trước khi nhận yêu cầu (BR-13-029). |
| `status` | `varchar(10)` | x | `'REQUESTED'` | Giá trị: `REQUESTED`, `RUNNING`, `READY`, `FAILED`, `EXPIRED`, `CANCELLED`. |
| `record_count` | `bigint` |  |  | Số bản ghi trong gói, tối đa 10.000.000. |
| `file_object` | `varchar(512)` |  |  | exports/{tenant}/{exportId}.zip ở bucket tạm; xóa sau 7 ngày, EXPIRED. |
| `file_hash` | `char(64)` |  |  | Mẫu `^[0-9a-f]{64}$`. |
| `signature` | `text` |  |  | Chữ ký số của gói; kèm manifest_signature là hai chữ ký bắt buộc để READY (SDD §8.1). |
| `manifest_signature` | `text` |  |  | Chữ ký số của bảng kê gói (chữ ký thứ hai). |
| `key_version` | `integer` |  |  | Phiên bản khóa ký đã dùng. |
| `expires_at` | `timestamptz` |  |  | Hạn tải của tệp (7 ngày); sau đó `EXPIRED`. |
| `requested_by` | `varchar(64)` | x |  | Người hoặc tác vụ yêu cầu (mã người dùng hoặc `system:*`). |
| `started_at` | `timestamptz` |  |  | Thời điểm bắt đầu. |
| `finished_at` | `timestamptz` |  |  | Thời điểm kết thúc. |
| `cancelled_at` | `timestamptz` |  |  | Thời điểm người yêu cầu hủy. |
| `error_code` | `varchar(16)` |  |  | Mã lỗi khi `FAILED` (ERR-13-025, 026). |
| `download_count` | `integer` | x | `0` | Số lượt tải; mỗi lượt ghi bản ghi kiểm toán riêng. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_audit.audit_export`

#### 3.1.9. `audit_reconciliation`

::: dac-ta
**Mục đích.** EN-13-06 Đối chiếu hằng ngày số bản ghi DU báo phát (dh_audit_emitted_day) với số PH-13 nhận theo (DU, tenant, ngày Asia/Ho_Chi_Minh); giữ 5 năm (FR-13-017). diff = emitted - received - quarantined.

**FR phục vụ.** FR-13-017.

**Khóa chính.** (id).

**Duy nhất.** `uq_audit_reconciliation` (tenant_id, du_code, day).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_audit_reconciliation_tenant`, `ck_audit_reconciliation_du`, `ck_audit_reconciliation_counts`, `ck_audit_reconciliation_status`, `ck_audit_reconciliation_match`, `ck_audit_reconciliation_mismatch`, `ck_audit_reconciliation_surplus`, `ck_audit_reconciliation_nocounter`, `ck_audit_reconciliation_recheck`.

**Chỉ mục.** `ix_audit_reconciliation_bad`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_audit_reconciliation_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ xóa dòng quá hạn lưu 5 năm tính từ `created_at` (trigger `tg_audit_reconciliation_ret`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Cột bất biến sau khi tạo: `id`, `tenant_id`, `du_code`, `day`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `du_code` | `varchar(32)` | x |  | Mẫu `^[a-z][a-z0-9-]{1,31}$`. |
| `day` | `date` | x |  | Ngày đối chiếu theo múi giờ `Asia/Ho_Chi_Minh`. |
| `emitted` | `bigint` |  |  | Bộ đếm của DU; null khi DU không xuất bộ đếm (NO_COUNTER). |
| `received` | `bigint` | x | `0` | Số bản ghi PH-13 đã nhận (`source_du`, `occurred_at` trong ngày). |
| `quarantined` | `bigint` | x | `0` | Số bản ghi cùng điều kiện đang ở audit_quarantine, tính là đã nhận (SDD §4.8). |
| `diff` | `bigint` |  | sinh: `emitted - received - quarantined` | Cột sinh: chênh lệch còn lại; `MATCH` chỉ khi bằng 0, `MISMATCH` khi dương, `SURPLUS` khi âm. |
| `status` | `varchar(10)` | x | `'PENDING'` | Giá trị: `PENDING`, `MATCH`, `MISMATCH`, `SURPLUS`, `NO_COUNTER`. |
| `recheck_count` | `smallint` | x | `0` | Số lần đếm lại sau 2 giờ khi diff > 0 trước khi kết luận MISMATCH. |
| `checked_at` | `timestamptz` |  |  | Lần đối chiếu gần nhất. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_audit.audit_reconciliation`

#### 3.1.10. `audit_partition`

::: dac-ta
**Mục đích.** EN-13-21 Vòng đời phân vùng tháng của audit_event: OPEN, SEALED, ARCHIVED (FR-13-018). Dòng chung cho mọi tenant nên tenant_id = PLATFORM; chỉ phiên PLATFORM (PartitionManager) đọc, ghi.

**FR phục vụ.** FR-13-018.

**Khóa chính.** (id).

**Duy nhất.** `uq_audit_partition_month` (tenant_id, month).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_audit_partition_tenant`, `ck_audit_partition_month`, `ck_audit_partition_name`, `ck_audit_partition_status`, `ck_audit_partition_count`, `ck_audit_partition_sealed`, `ck_audit_partition_archived`, `ck_audit_partition_archived_worm`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_audit_partition_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_audit_partition_nodel`).

**Ghi chú.** Bảng chung cho mọi tenant nên chỉ phiên PLATFORM đọc, ghi. Thủ tục `p_archive_partition` (SECURITY DEFINER, chỉ vai trò `ph13_archive`) kiểm `SEALED`, `worm_verified_at` và `archive_after` rồi mới tách và xóa phân vùng. Trigger bảo vệ: `tg_audit_partition_guard` (OPEN -> SEALED -> ARCHIVED, một chiều (FRS §4.7)). Cột bất biến sau khi tạo: `id`, `tenant_id`, `month`, `partition_name`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x | `'PLATFORM'` | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `month` | `date` | x |  | Ngày đầu tháng của phân vùng. |
| `partition_name` | `varchar(63)` | x |  | `audit_event_YYYYMM`. |
| `status` | `varchar(8)` | x | `'OPEN'` | Giá trị: `OPEN`, `SEALED`, `ARCHIVED`. |
| `record_count` | `bigint` | x | `0` | Số bản ghi lúc chốt. |
| `sealed_at` | `timestamptz` |  |  | Thời điểm chốt `SEALED`. |
| `worm_verified_at` | `timestamptz` |  |  | Thời điểm ArchiveService.preflight xác minh mọi lô WORM của dải seq khớp băm; điều kiện để ARCHIVED. |
| `archive_after` | `date` |  |  | Ngày sớm nhất được lưu trữ = hết tháng + max(13.audit.online-months của mọi tenant có bản ghi) (SDD §6); ứng dụng tính, p_archive_partition kiểm. |
| `archived_at` | `timestamptz` |  |  | Thời điểm tách và xóa phân vùng. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_audit.audit_partition`

#### 3.1.11. `audit_quarantine`

::: dac-ta
**Mục đích.** Kho cách ly bản ghi kiểm toán không đạt kiểm tra tiếp nhận; giữ nguyên văn, không bao giờ bỏ (FR-13-010, SDD §4.3). Có thể chứa giá trị Nhạy cảm (ERR-13-105) nên raw_payload không cấp cho ph13_readonly; xóa khi quá purge_after.

**FR phục vụ.** FR-13-010, 016.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_audit_quarantine_tenant`, `ck_audit_quarantine_reason`, `ck_audit_quarantine_error`, `ck_audit_quarantine_sha`, `ck_audit_quarantine_size`, `ck_audit_quarantine_status`, `ck_audit_quarantine_resolved`, `ck_audit_quarantine_record`.

**Chỉ mục.** `ix_audit_quarantine_pending`, `ix_audit_quarantine_record`, `ix_audit_quarantine_purge`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_audit_quarantine_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ xóa dòng đã qua mốc `purge_after` (trigger `tg_audit_quarantine_ret`).

**Ghi chú.** Có thể chứa giá trị Nhạy cảm nên cột `raw_payload` không cấp cho vai trò báo cáo `ph13_readonly`. Cột bất biến sau khi tạo: `id`, `tenant_id`, `du_code`, `topic`, `reason`, `error_code`, `payload_sha256`, `raw_payload`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `du_code` | `varchar(32)` | x |  | DU nguồn. |
| `topic` | `varchar(249)` | x |  | Topic Kafka nhận bản ghi. |
| `kafka_partition` | `integer` |  |  | Partition Kafka (null với kênh dự phòng). |
| `kafka_offset` | `bigint` |  |  | Offset Kafka (null với kênh dự phòng). |
| `record_id` | `uuid` |  |  | id (UUID v7) của bản ghi khi đọc được; DU sửa rồi gửi lại cùng id, khử trùng chỉ xét audit_event nên không bị chặn. |
| `reason` | `varchar(20)` | x |  | Giá trị: `UNPARSABLE`, `SCHEMA_INVALID`, `SOURCE_UNAUTHORIZED`, `TENANT_MISMATCH`, `SENSITIVE_VALUE`, `CHAIN_CLOSED`. |
| `error_code` | `varchar(16)` | x |  | Mẫu `^ERR-13-[0-9]{3}$`. |
| `payload_sha256` | `char(64)` | x |  | Mẫu `^[0-9a-f]{64}$`. |
| `raw_payload` | `bytea` | x |  | Nguyên văn bytes; không phân tích được thì lưu thô (UNPARSABLE) vì kênh kiểm toán không có hàng đợi thư chết. Tối đa 1 MB. |
| `status` | `varchar(11)` | x | `'PENDING'` | Giá trị: `PENDING`, `RESUBMITTED`, `DISMISSED`. |
| `resolved_by` | `varchar(64)` |  |  | Người xử lý bản cách ly. |
| `resolved_at` | `timestamptz` |  |  | Thời điểm xử lý. |
| `purge_after` | `timestamptz` | x | `now() + interval '90 days'` | Hạn giữ mặc định 90 ngày (giả định, Q13-53); chỉ xóa được sau hạn này. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_audit.audit_quarantine`

#### 3.1.12. `audit_source_grant`

::: dac-ta
**Mục đích.** Cặp (DU, tenant) được phép gửi bản ghi kiểm toán; bộ tiếp nhận kiểm bước 1 (ERR-13-103, UC-SEC-09). Không xóa, thu hồi bằng REVOKED.

**FR phục vụ.** FR-13-010, 059.

**Khóa chính.** (id).

**Duy nhất.** `uq_audit_source_grant` (tenant_id, du_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_audit_source_grant_tenant`, `ck_audit_source_grant_du`, `ck_audit_source_grant_status`, `ck_audit_source_grant_revoked`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_audit_source_grant_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_audit_source_grant_nodel`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Cột bất biến sau khi tạo: `id`, `tenant_id`, `du_code`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `du_code` | `varchar(32)` | x |  | Mẫu `^[a-z][a-z0-9-]{1,31}$`. |
| `key_id` | `varchar(64)` | x |  | dh-kid của khóa HMAC nguồn ở OpenBao (chỉ định danh, không chứa khóa). |
| `status` | `varchar(7)` | x | `'ACTIVE'` | Giá trị: `ACTIVE`, `REVOKED`. |
| `granted_by` | `varchar(64)` | x |  | Người cấp quyền nguồn. |
| `revoked_at` | `timestamptz` |  |  | Thời điểm thu hồi. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_audit.audit_source_grant`

#### 3.1.13. `outbox`

::: dac-ta
**Mục đích.** Hộp thư đi (DD-11) của module audit cho EVT-13-05…09, 11, 12, ghi cùng giao dịch với đổi trạng thái; Debezium Outbox Router hoặc OutboxRelay đọc. Dọn sau 3 ngày. Bản ghi kiểm toán của DU không đi qua bảng này mà qua audit_outbox ở schema của DU (ADR-042).

**FR phục vụ.** Hạ tầng cho EVT-13-05…09, 11, 12 (FR-13-012, 014, 015, 017, 018).

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_audit_outbox_tenant`, `ck_audit_outbox_type`, `ck_audit_outbox_topic`, `ck_audit_outbox_topic_tenant`, `ck_audit_outbox_trace`.

**Chỉ mục.** `ix_audit_outbox_occurred`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_outbox_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Dọn sau 3 ngày. Bản ghi kiểm toán của DU không đi qua bảng này.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `event_id` | `uuid` | x |  | Mã sự kiện (UUID v7), khóa khử trùng ở bên nhận. |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `event_type` | `varchar(128)` | x |  | Mẫu `^EVT-13-[0-9]{2}$\|^[a-z][a-zA-Z0-9.]{2,127}$`. |
| `topic` | `varchar(249)` | x |  | Mẫu `^[a-z0-9]+\.obs\.[a-z0-9.-]+\.v[0-9]+$`. |
| `aggregate_type` | `varchar(64)` | x |  | Loại thực thể phát sinh sự kiện. |
| `aggregate_id` | `text` | x |  | Mã thực thể phát sinh sự kiện. |
| `payload` | `jsonb` | x |  | Nội dung sự kiện JSON; không chứa bí mật. |
| `trace_id` | `char(32)` | x |  | Mẫu `^[0-9a-f]{32}$`. |
| `occurred_at` | `timestamptz` | x | `now()` | Thời điểm phát sinh sự kiện. |

: Cột của bảng `ph13_audit.outbox`

#### 3.1.14. `shedlock`

::: dac-ta
**Mục đích.** Khóa tác vụ nền của module audit (AnchorScheduler, WormBatchWriter, VerificationService, ReconciliationService, PartitionManager); bảng kỹ thuật không có tenant_id.

**FR phục vụ.** Tác vụ nền của FR-13-012, 013, 014, 017, 018.

**Khóa chính.** (name).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không bật RLS. Bảng kỹ thuật không chứa dữ liệu nghiệp vụ, không có `tenant_id`.

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `name` | `varchar(64)` | x |  | Tên khóa tác vụ. |
| `lock_until` | `timestamptz` | x |  | Khóa có hiệu lực tới. |
| `locked_at` | `timestamptz` | x |  | Thời điểm lấy khóa. |
| `locked_by` | `varchar(255)` | x |  | Bản sao đang giữ khóa. |

: Cột của bảng `ph13_audit.shedlock`

### 3.2. Nhóm quan sát (schema `ph13_obs`)

Mười chín bảng của module `observability`: cấu hình tenant, luật và runbook, cảnh báo và vòng đời xử lý, thông báo và lịch trực, luật phát hiện và cảnh báo an ninh, SIEM, dashboard, kiểm tra tổng hợp và các bảng kỹ thuật. Không bảng nào chứa số liệu quan sát hay bí mật; mọi bảng có `tenant_id` và `FORCE ROW LEVEL SECURITY`.

#### 3.2.1. `tenant_obs_config`

::: dac-ta
**Mục đích.** EN-13-19 Cấu hình quan sát của tenant: tham số 13.*, hạn mức, sổ bước khởi tạo S1…S6 (FR-13-059, 061). Nguồn sự thật của OverridesReconciler; tham số kiểm miền ở CHECK (ERR-13-040).

**FR phục vụ.** FR-13-059, 061.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_obs_config_tenant` (tenant_id).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_tenant_obs_config_tenant`, `ck_tenant_obs_config_scale`, `ck_tenant_obs_config_params`, `ck_tenant_obs_config_quota`, `ck_tenant_obs_config_state`, `ck_tenant_obs_config_hash`, `ck_tenant_obs_config_provisioned`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_tenant_obs_config_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_tenant_obs_config_nodel`).

**Ghi chú.** Hàm `fn_params_valid` kiểm khóa và miền của tham số `13.*`; khóa lạ hoặc ngoài miền làm `CHECK` thất bại (ERR-13-040). Cột bất biến sau khi tạo: `id`, `tenant_id`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `scale` | `varchar(10)` | x | `'QM-VUA'` | Giá trị: `QM-NHO`, `QM-VUA`, `QM-LON`, `QM-CHUNG`. |
| `params` | `jsonb` | x | `'{}'` | Chỉ khóa 13.* theo FRS §8.3, giá trị trong miền; vắng khóa thì dùng mặc định của nền tảng. |
| `quota` | `jsonb` | x | `'{}'` | Hạn mức theo scale (số chuỗi, tốc độ nhận log, trace); không vượt trần của PA (ERR-13-041, kiểm ở dịch vụ). JSON object. |
| `provision_key` | `varchar(64)` |  |  | `Idempotency-Key` của lần khởi tạo. |
| `provision_hash` | `char(64)` |  |  | Mẫu `^[0-9a-f]{64}$`. |
| `provision_state` | `jsonb` | x | `'{}'` | Sổ bước {"S1":{"status":"DONE","at":"…"},…}; gọi lại cùng provision_key chạy tiếp từ bước dở, khác provision_hash trả ERR-13-042. JSON object. |
| `provisioned_at` | `timestamptz` |  |  | Đặt khi đủ S1…S6; null thì tenant chưa khởi tạo xong. |
| `grafana_org_id` | `bigint` |  |  | Mã tổ chức Grafana của tenant. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.tenant_obs_config`

#### 3.2.2. `runbook`

::: dac-ta
**Mục đích.** EN-13-08 Runbook năm mục: ý nghĩa, kiểm tra đầu tiên, nguyên nhân thường gặp, cách xử lý, khi nào báo cấp trên (FR-13-042, 043; BR-13-008). Xóa mềm (RETIRED), mã không dùng lại. Runbook scope=PLATFORM nhân bản từ Git cho từng tenant.

**FR phục vụ.** FR-13-042, 043.

**Khóa chính.** (id).

**Duy nhất.** `uq_runbook_code` (tenant_id, runbook_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_runbook_tenant`, `ck_runbook_code`, `ck_runbook_scope`, `ck_runbook_five_sections`, `ck_runbook_status`, `ck_runbook_platform_source`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_runbook_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_runbook_nodel`).

**Ghi chú.** Năm mục bắt buộc đều có `CHECK` độ dài từ 1 đến 4.000 ký tự sau khi cắt khoảng trắng (BR-13-008). Trigger bảo vệ: `tg_runbook_platform` (mục `scope = PLATFORM` chỉ ghi qua StandardRuleCatalog). Cột bất biến sau khi tạo: `id`, `tenant_id`, `runbook_code`, `scope`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `runbook_code` | `varchar(64)` | x |  | Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `title` | `varchar(255)` | x |  | Tiêu đề runbook. |
| `scope` | `varchar(8)` | x | `'TENANT'` | PLATFORM: runbook chuẩn nạp bởi StandardRuleCatalog, tenant không sửa; TENANT: do tenant tạo. Giá trị: `PLATFORM`, `TENANT`. |
| `meaning` | `text` | x |  | Từ 1 đến 4000 ký tự. |
| `first_checks` | `text` | x |  | Từ 1 đến 4000 ký tự. |
| `common_causes` | `text` | x |  | Từ 1 đến 4000 ký tự. |
| `remediation` | `text` | x |  | Từ 1 đến 4000 ký tự. |
| `escalation_when` | `text` | x |  | Từ 1 đến 4000 ký tự. |
| `status` | `varchar(7)` | x | `'ACTIVE'` | Giá trị: `ACTIVE`, `RETIRED`. |
| `source_revision` | `varchar(64)` |  |  | Mã commit của kho cấu hình Git cho runbook chuẩn (bắt buộc khi scope=PLATFORM). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.runbook`

#### 3.2.3. `alert_rule`

::: dac-ta
**Mục đích.** EN-13-07 Luật cảnh báo (PromQL, LogQL) kèm runbook bắt buộc (FR-13-042, 043, 044). Không có trạng thái nháp: runbook_id NOT NULL. Luật scope=PLATFORM nhân bản từ Git cho từng tenant, tenant không sửa, không tắt (BR-13-032). Xóa mềm, mã không dùng lại.

**FR phục vụ.** FR-13-042, 043, 044.

**Khóa chính.** (id).

**Duy nhất.** `uq_alert_rule_code` (tenant_id, rule_code).

**Khóa ngoại.** (runbook_id, tenant_id) → `runbook`.

**Ràng buộc CHECK.** `ck_alert_rule_tenant`, `ck_alert_rule_code`, `ck_alert_rule_scope`, `ck_alert_rule_expr`, `ck_alert_rule_lang`, `ck_alert_rule_for`, `ck_alert_rule_eval`, `ck_alert_rule_severity`, `ck_alert_rule_critical_symptom`, `ck_alert_rule_resource_only`, `ck_alert_rule_status`, `ck_alert_rule_group_labels`, `ck_alert_rule_hash`, `ck_alert_rule_retired`, `ck_alert_rule_platform_source`.

**Chỉ mục.** `ix_alert_rule_status`, `ix_alert_rule_runbook`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_alert_rule_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_alert_rule_nodel`).

**Ghi chú.** Luật `scope = PLATFORM` chỉ ghi được trong giao dịch của StandardRuleCatalog (`app.rule_catalog = on`). Trigger bảo vệ: `tg_alert_rule_platform` (mục `scope = PLATFORM` chỉ ghi qua StandardRuleCatalog); `tg_alert_rule_guard` (Số luật riêng ≤ 13.alert.max-rules (mặc định 500)). Cột bất biến sau khi tạo: `id`, `tenant_id`, `rule_code`, `scope`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `rule_code` | `varchar(64)` | x |  | Mã luật; cùng `tenant_id` trỏ tới bảng luật. Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `name` | `varchar(255)` | x |  | Tên hiển thị. |
| `description` | `varchar(2000)` |  |  | Mô tả tự do. |
| `scope` | `varchar(8)` | x | `'TENANT'` | Giá trị: `PLATFORM`, `TENANT`. |
| `expr` | `text` | x |  | Biểu thức đã qua ExpressionGuard; nhãn tenant do RulePublisher ghi đè khi đẩy tới Ruler (BR-13-027). Từ 1 đến 8000 ký tự. |
| `expr_language` | `varchar(7)` | x | `'PROMQL'` | Giá trị: `PROMQL`, `LOGQL`. |
| `for_seconds` | `integer` | x | `300` | Từ 0 đến 86400. |
| `eval_interval_seconds` | `integer` |  |  | Null: dùng 13.alert.eval-interval-seconds (30 giây). Từ 30 đến 300. |
| `severity` | `varchar(8)` | x |  | Giá trị: `CRITICAL`, `WARNING`, `INFO`. |
| `symptom` | `varchar(1000)` |  |  | Mô tả triệu chứng người dùng; bắt buộc khi severity = CRITICAL (BR-13-009). |
| `resource_only` | `boolean` | x | `false` | SeverityPolicy đặt true khi mọi chỉ số trong biểu thức thuộc nhóm tài nguyên thuần (CPU, bộ nhớ, đĩa); khi đó tối đa WARNING. |
| `runbook_id` | `uuid` | x |  | Runbook bắt buộc; khóa ngoại kèm `tenant_id`. |
| `notify_group` | `varchar(64)` |  |  | Mã nhóm nhận thông báo (lịch trực). |
| `group_key_labels` | `varchar(32)[]` | x | `'{}'` | Nhãn dùng gom nhóm (group_by của Alertmanager); cấm nhãn có số giá trị không giới hạn (BR-13-026). |
| `status` | `varchar(8)` | x | `'ACTIVE'` | Giá trị: `ACTIVE`, `DISABLED`, `RETIRED`. |
| `owner` | `varchar(64)` | x |  | Người sở hữu (mã người dùng). |
| `source_revision` | `varchar(64)` |  |  | Mã commit của kho cấu hình Git đã nạp mục này. |
| `expr_hash` | `char(64)` | x |  | SHA-256 của biểu thức chuẩn hóa; RuleReconciler so với nhóm luật trong Mimir để tự lành (SDD §4.16). Mẫu `^[0-9a-f]{64}$`. |
| `retired_at` | `timestamptz` |  |  | Thời điểm ngừng dùng (xóa mềm). |
| `retired_reason` | `varchar(500)` |  |  | Lý do ngừng dùng. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.alert_rule`

#### 3.2.4. `notification_channel`

::: dac-ta
**Mục đích.** EN-13-13 Kênh gửi cảnh báo: thư, SMS, webhook, trong ứng dụng (FR-13-048). Bí mật (khóa ký webhook) ở OpenBao, bảng chỉ giữ đường dẫn secret_ref. Xóa mềm, mã không dùng lại.

**FR phục vụ.** FR-13-048.

**Khóa chính.** (id).

**Duy nhất.** `uq_notification_channel_code` (tenant_id, channel_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_notification_channel_tenant`, `ck_notification_channel_code`, `ck_notification_channel_kind`, `ck_notification_channel_webhook`, `ck_notification_channel_sms`, `ck_notification_channel_secret`, `ck_notification_channel_status`, `ck_notification_channel_test`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_notification_channel_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_notification_channel_nodel`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Cột bất biến sau khi tạo: `id`, `tenant_id`, `channel_code`, `kind`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `channel_code` | `varchar(64)` | x |  | Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `name` | `varchar(255)` | x |  | Tên hiển thị. |
| `kind` | `varchar(7)` | x |  | Giá trị: `EMAIL`, `SMS`, `WEBHOOK`, `INAPP`. |
| `target` | `varchar(512)` | x |  | Hòm thư nhóm, URL HTTPS nằm trong danh sách FQDN của cổng thoát (SEC-16) hoặc mã nhóm; không lưu số điện thoại hay thư cá nhân (PH-18 phân giải từ mã người dùng). Mẫu `^https://[A-Za-z0-9.-]+(:[0-9]{2,5})?(/.*)?$`. |
| `secret_ref` | `varchar(255)` |  |  | Đường dẫn OpenBao kv/dh/...; bắt buộc với WEBHOOK (chữ ký webhook-signature, SEC-47). Mẫu `^kv/dh/[A-Za-z0-9/_-]+$`. |
| `external` | `boolean` | x | `false` | Kênh độc lập với hạ tầng của site (SMS qua nhà mạng, Q13-16); nhóm nhận Nghiêm trọng cần ít nhất một kênh external (BR-13-022, kiểm ở ScheduleValidator). |
| `enabled` | `boolean` | x | `true` | Bật hoặc tắt; tắt thì không tham gia xử lý. |
| `status` | `varchar(7)` | x | `'ACTIVE'` | Giá trị: `ACTIVE`, `RETIRED`. |
| `last_test_at` | `timestamptz` |  |  | Lần kiểm tra kênh gần nhất. |
| `last_test_ok` | `boolean` |  |  | Kết quả lần kiểm tra gần nhất. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.notification_channel`

#### 3.2.5. `oncall_schedule`

::: dac-ta
**Mục đích.** EN-13-12 Lịch trực theo nhóm nhận: ca theo thứ trong tuần, thứ tự leo thang, múi giờ (FR-13-048). Lịch hợp lệ (không hở giờ, không chồng ca, nhóm Nghiêm trọng đủ kênh) do ScheduleValidator kiểm trước khi lưu (ERR-13-034).

**FR phục vụ.** FR-13-048.

**Khóa chính.** (id).

**Duy nhất.** `uq_oncall_schedule_code` (tenant_id, schedule_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_oncall_schedule_tenant`, `ck_oncall_schedule_code`, `ck_oncall_schedule_group`, `ck_oncall_schedule_tz`, `ck_oncall_schedule_rotation`, `ck_oncall_schedule_escalation`, `ck_oncall_schedule_status`.

**Chỉ mục.** `ix_oncall_schedule_group`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_oncall_schedule_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_oncall_schedule_nodel`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Cột bất biến sau khi tạo: `id`, `tenant_id`, `schedule_code`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `schedule_code` | `varchar(64)` | x |  | Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `name` | `varchar(255)` | x |  | Tên hiển thị. |
| `group_code` | `varchar(64)` | x |  | Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `timezone` | `varchar(40)` | x | `'Asia/Ho_Chi_Minh'` | Mẫu `^[A-Za-z_]+(/[A-Za-z_+-]+)+$\|^UTC$`. |
| `rotation` | `jsonb` | x |  | Mảng ca [{"days":[1..7],"from":"HH:mm","to":"HH:mm","level1":"mã người dùng","level2":"…","level3":"…"}]; chỉ mã người dùng, không thông tin liên lạc. JSON array. |
| `escalation_order` | `jsonb` | x |  | Tối đa 3 cấp [{"level":1,"channels":["mã kênh"]}…]; cấp 2 ở 15 phút, cấp 3 ở 30 phút theo 13.alert.escalate-minutes. JSON array. |
| `status` | `varchar(7)` | x | `'ACTIVE'` | Giá trị: `ACTIVE`, `RETIRED`. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.oncall_schedule`

#### 3.2.6. `alert`

::: dac-ta
**Mục đích.** EN-13-09 Cảnh báo: một lần luật được thỏa; FIRING, ACKNOWLEDGED, SILENCED, RESOLVED (FR-13-044, 045, 047). Khóa tự nhiên (tenant, rule_code, fingerprint) chỉ một bản đang mở nên webhook Alertmanager lũy đẳng. Giữ 2 năm.

**FR phục vụ.** FR-13-044, 045, 047, 050.

**Khóa chính.** (id).

**Duy nhất.** `ux_alert_open` (tenant_id, rule_code, fingerprint) (một phần).

**Khóa ngoại.** (tenant_id, rule_code) → `alert_rule`.

**Ràng buộc CHECK.** `ck_alert_tenant`, `ck_alert_fingerprint`, `ck_alert_status`, `ck_alert_severity`, `ck_alert_labels`, `ck_alert_escalation`, `ck_alert_resolution`, `ck_alert_resolution_kind`, `ck_alert_silence`, `ck_alert_ack`, `ck_alert_time`.

**Chỉ mục.** `ix_alert_list`, `ix_alert_group`, `ix_alert_rule_time`, `ix_alert_escalation`, `ix_alert_silence_expiry`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_alert_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ xóa dòng quá hạn lưu 2 năm tính từ `ended_at` (trigger `tg_alert_ret`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Trigger bảo vệ: `tg_alert_guard` (Bảng chuyển trạng thái cảnh báo (FRS §4.3), hạn tạm ẩn ≤ 13.alert.silence-max-days (Nghiêm trọng ≤ 24 giờ), leo thang từng cấp). Cột bất biến sau khi tạo: `id`, `tenant_id`, `rule_code`, `fingerprint`, `started_at`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `rule_code` | `varchar(64)` | x |  | Mã luật; cùng `tenant_id` trỏ tới bảng luật. |
| `fingerprint` | `varchar(64)` | x |  | Dấu vân tay của Alertmanager cho tổ hợp nhãn; cùng luật, cùng fingerprint chỉ một cảnh báo mở. Mẫu `^[0-9a-f]{16,64}$`. |
| `status` | `varchar(12)` | x | `'FIRING'` | Giá trị: `FIRING`, `ACKNOWLEDGED`, `SILENCED`, `RESOLVED`. |
| `severity` | `varchar(8)` | x |  | Giá trị: `CRITICAL`, `WARNING`, `INFO`. |
| `labels` | `jsonb` | x |  | Nhãn chuẩn (mục 4.8 FRS); luôn có tenant khớp tenant_id (BR-13-027); không trace_id, user_id, client_ip. JSON object. |
| `summary` | `varchar(1000)` | x |  | Tóm tắt từ chú thích của luật; không chứa dữ liệu cá nhân. |
| `group_key` | `varchar(128)` | x |  | Khóa gom nhóm: cùng nguyên nhân hiển thị và thông báo gộp (FR-13-045). |
| `started_at` | `timestamptz` | x | `now()` | Thời điểm `FIRING` đầu tiên. |
| `ended_at` | `timestamptz` |  |  | Thời điểm đóng (`RESOLVED`). |
| `escalation_level` | `smallint` | x | `1` | 1…3; thuộc tính, không phải trạng thái; chỉ CRITICAL leo thang (BR-13-022). Từ 1 đến 3. |
| `resolution` | `varchar(6)` |  |  | Giá trị: `MANUAL`, `AUTO`. |
| `acknowledged_by` | `varchar(64)` |  |  | Người xác nhận. |
| `acknowledged_at` | `timestamptz` |  |  | Thời điểm xác nhận (tính MTTA). |
| `silence_until` | `timestamptz` |  |  | Hạn tạm ẩn; trigger kiểm ≤ 13.alert.silence-max-days, CRITICAL ≤ 24 giờ (BR-13-021). Đặt null khi quay về FIRING. |
| `silence_reason` | `varchar(500)` |  |  | Lý do tạm ẩn, bắt buộc khi `SILENCED`. |
| `silence_id` | `varchar(64)` |  |  | Mã silence ở Alertmanager để hủy khi đóng sớm. |
| `last_firing_at` | `timestamptz` | x | `now()` | Lần cuối webhook báo `firing`. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.alert`

#### 3.2.7. `alert_action`

::: dac-ta
**Mục đích.** EN-13-11 Thao tác xử lý cảnh báo: xác nhận, đóng, tạm ẩn, leo thang; chỉ thêm, ghi cùng giao dịch với đổi trạng thái (FR-13-047). Giữ 2 năm; xóa theo cảnh báo khi hết hạn.

**FR phục vụ.** FR-13-047, 050.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (alert_id, tenant_id) → `alert` xóa theo.

**Ràng buộc CHECK.** `ck_alert_action_tenant`, `ck_alert_action_kind`, `ck_alert_action_outcome`, `ck_alert_action_resolve`, `ck_alert_action_silence`, `ck_alert_action_escalate`.

**Chỉ mục.** `ix_alert_action_alert`, `ix_alert_action_actor`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_alert_action_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ thêm, chặn UPDATE (trigger `tg_alert_action_append`, BR-13-002); Chỉ xóa dòng quá hạn lưu 2 năm tính từ `at` (trigger `tg_alert_action_ret`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `alert_id` | `uuid` | x |  | Cảnh báo được xử lý. |
| `action` | `varchar(8)` | x |  | Giá trị: `ACK`, `RESOLVE`, `SILENCE`, `ESCALATE`. |
| `actor` | `varchar(64)` | x |  | Mã người dùng, hoặc system:alertmanager, system:escalation cho thao tác tự động. |
| `at` | `timestamptz` | x | `now()` | Thời điểm thao tác. |
| `cause` | `varchar(1000)` |  |  | Nguyên nhân (bắt buộc khi đóng thủ công). |
| `measure` | `varchar(1000)` |  |  | Hành động đã làm (bắt buộc khi đóng thủ công). |
| `outcome` | `varchar(9)` |  |  | FIXED (đã khắc phục), NO_ACTION (báo giả, không cần làm gì), EXTERNAL (nguyên nhân bên ngoài); dùng tính tỷ lệ cảnh báo giả (FR-13-050). Giá trị: `FIXED`, `NO_ACTION`, `EXTERNAL`. |
| `silence_until` | `timestamptz` |  |  | Hạn tạm ẩn (khi `SILENCE`). |
| `silence_id` | `varchar(64)` |  |  | Mã silence ở Alertmanager. |
| `reason` | `varchar(500)` |  |  | Lý do tạm ẩn. |
| `level_to` | `smallint` |  |  | Cấp leo thang mới (khi `ESCALATE`). Từ 2 đến 3. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `ph13_obs.alert_action`

#### 3.2.8. `detection_rule`

::: dac-ta
**Mục đích.** EN-13-14 Luật phát hiện bất thường an ninh, nạp 25 luật UC-SEC-01…25 của D03-07 §7.5 cho từng tenant, kèm hai luật phụ của PH-13 (FR-13-051). Cán bộ ATTT chỉ tinh chỉnh threshold trong biên; thay đổi ghi kiểm toán (SECURITY.RULE.TUNE).

**FR phục vụ.** FR-13-051, 052.

**Khóa chính.** (id).

**Duy nhất.** `uq_detection_rule_code` (tenant_id, rule_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_detection_rule_tenant`, `ck_detection_rule_code`, `ck_detection_rule_impl`, `ck_detection_rule_severity`, `ck_detection_rule_recipients`, `ck_detection_rule_json`, `ck_detection_rule_limit`, `ck_detection_rule_threshold`, `ck_detection_rule_fixed`, `ck_detection_rule_tuned`.

**Chỉ mục.** `ix_detection_rule_impl`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_detection_rule_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_detection_rule_nodel`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Cột bất biến sau khi tạo: `id`, `tenant_id`, `rule_code`, `source`, `impl`, `threshold_default`, `threshold_limit`, `can_disable`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `rule_code` | `varchar(40)` | x |  | Mã luật; cùng `tenant_id` trỏ tới bảng luật. Mẫu `^(UC-SEC-[0-9]{2}\|[A-Z][A-Z0-9-]{2,39})$`. |
| `name` | `varchar(255)` | x |  | Tên hiển thị. |
| `source` | `varchar(40)` | x |  | Nguồn dữ liệu của luật (Keycloak, APISIX, AUDIT…). |
| `impl` | `varchar(8)` | x | `'RULER'` | RULER: luật Mimir hoặc Loki Ruler; ENGINE: DetectionEngine truy vấn bản ghi kiểm toán; BREAK: UC-SEC-20 do BreakHandler phát thẳng (SDD §4.20). Giá trị: `RULER`, `ENGINE`, `BREAK`. |
| `threshold` | `jsonb` | x |  | Ngưỡng hiện hành (JSON); đổi ghi `SECURITY.RULE.TUNE`. JSON object. |
| `threshold_default` | `jsonb` | x |  | Ngưỡng mặc định của D03-07 §7.5; bất biến. JSON object. |
| `threshold_limit` | `jsonb` | x | `'{}'` | {"khóa":{"dir":"MAX"\|"MIN","bound":số}}: MAX nới lên tới bound (≤ 2 lần mặc định), MIN nới xuống tới bound (≥ nửa mặc định); {} là luật "mọi sự kiện", không có ngưỡng số. JSON object. |
| `severity` | `varchar(8)` | x |  | NT của D03-07 → CRITICAL; C, TB → WARNING (giả định, Q13-54). Giá trị: `CRITICAL`, `WARNING`, `INFO`. |
| `recipients` | `varchar(8)[]` | x | `'{SO}'` | Vai trò nhận cảnh báo (`SO`, `TA`, `PA`, `AU`). |
| `enabled` | `boolean` | x | `true` | Bật hoặc tắt; tắt thì không tham gia xử lý. |
| `can_disable` | `boolean` | x | `true` | false cho luật mức Nghiêm trọng kiểu "mọi sự kiện": không tắt, không đổi ngưỡng (ck_detection_rule_fixed). |
| `source_revision` | `varchar(64)` |  |  | Mã commit của kho cấu hình Git đã nạp mục này. |
| `tuned_by` | `varchar(64)` |  |  | Người tinh chỉnh ngưỡng gần nhất. |
| `tuned_at` | `timestamptz` |  |  | Thời điểm tinh chỉnh. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.detection_rule`

#### 3.2.9. `security_alert`

::: dac-ta
**Mục đích.** EN-13-15 Cảnh báo an ninh do luật phát hiện sinh ra; NEW, ACKNOWLEDGED, CLOSED; đóng phải có kết luận (FR-13-052, 053; BR-13-024). Gom theo (luật, chủ thể) khi còn mở. Giữ 3 năm sau khi đóng.

**FR phục vụ.** FR-13-052, 053.

**Khóa chính.** (id).

**Duy nhất.** `ux_security_alert_open` (tenant_id, rule_code, subject) (một phần).

**Khóa ngoại.** (tenant_id, rule_code) → `detection_rule`.

**Ràng buộc CHECK.** `ck_security_alert_tenant`, `ck_security_alert_status`, `ck_security_alert_severity`, `ck_security_alert_evidence`, `ck_security_alert_count`, `ck_security_alert_ack`, `ck_security_alert_verdict_kind`, `ck_security_alert_closed`, `ck_security_alert_accepted`, `ck_security_alert_incident`.

**Chỉ mục.** `ix_security_alert_list`, `ix_security_alert_rule`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_security_alert_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ xóa dòng quá hạn lưu 3 năm tính từ `closed_at` (trigger `tg_security_alert_ret`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Trigger bảo vệ: `tg_security_alert_guard` (NEW→ACKNOWLEDGED→CLOSED hoặc NEW→CLOSED). Cột bất biến sau khi tạo: `id`, `tenant_id`, `rule_code`, `detected_at`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `rule_code` | `varchar(40)` | x |  | Mã luật; cùng `tenant_id` trỏ tới bảng luật. |
| `status` | `varchar(12)` | x | `'NEW'` | Giá trị: `NEW`, `ACKNOWLEDGED`, `CLOSED`. |
| `severity` | `varchar(8)` | x |  | Giá trị: `CRITICAL`, `WARNING`, `INFO`. |
| `subject` | `varchar(255)` | x |  | Chủ thể bị nghi (mã người dùng, client, mã HTTT, IP đã băm theo luật); không dữ liệu cá nhân thô. |
| `evidence` | `jsonb` | x | `'{}'` | Bằng chứng: số đếm, khoảng thời gian và tối đa 100 audit_id ở khóa auditIds; không chứa dữ liệu gốc (SDD §4.20). JSON object. |
| `occurrence_count` | `integer` | x | `1` | Số lần luật thỏa với cùng chủ thể khi còn mở. |
| `detected_at` | `timestamptz` | x | `now()` | Lần phát hiện đầu. |
| `last_seen_at` | `timestamptz` | x | `now()` | Lần phát hiện gần nhất. |
| `assignee` | `varchar(64)` |  |  | Cán bộ ATTT đang điều tra. |
| `acknowledged_at` | `timestamptz` |  |  | Thời điểm tiếp nhận. |
| `verdict` | `varchar(18)` |  |  | Giá trị: `CONFIRMED_INCIDENT`, `FALSE_POSITIVE`, `ACCEPTED_RISK`. |
| `verdict_note` | `varchar(1000)` |  |  | Ghi chú kết luận (bắt buộc khi `ACCEPTED_RISK`). |
| `closed_by` | `varchar(64)` |  |  | Người đóng. |
| `closed_at` | `timestamptz` |  |  | Thời điểm đóng. |
| `incident_ref` | `varchar(64)` |  |  | Mã hồ sơ ứng cứu (D03-07 §8) khi kết luận CONFIRMED_INCIDENT. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.security_alert`

#### 3.2.10. `incident_report`

::: dac-ta
**Mục đích.** EN-13-22 Báo cáo sự cố an ninh mạng và thông báo vi phạm dữ liệu cá nhân dạng nháp, dựng từ mẫu (FR-13-055, Đợt sau; cờ obs.incident-report.enabled tắt ở MVP). Việc gửi cho cơ quan do chủ quản thực hiện ngoài hệ thống (Q13-10). Giữ 5 năm.

**FR phục vụ.** FR-13-055.

**Khóa chính.** (id).

**Duy nhất.** `uq_incident_report_code` (tenant_id, report_code).

**Khóa ngoại.** (security_alert_id, tenant_id) → `security_alert`.

**Ràng buộc CHECK.** `ck_incident_report_tenant`, `ck_incident_report_kind`, `ck_incident_report_content`, `ck_incident_report_status`, `ck_incident_report_deadline`, `ck_incident_report_final`.

**Chỉ mục.** `ix_incident_report_deadline`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_incident_report_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ xóa dòng quá hạn lưu 5 năm tính từ `created_at` (trigger `tg_incident_report_ret`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Trigger bảo vệ: `tg_incident_report_guard` (Báo cáo FINAL bất biến (giữ 5 năm, SEC-74)). Cột bất biến sau khi tạo: `id`, `tenant_id`, `report_code`, `kind`, `detected_at`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `report_code` | `varchar(64)` | x |  | Mã báo cáo, không dùng lại. |
| `kind` | `varchar(12)` | x |  | Giá trị: `CYBER`, `DLCN_BREACH`. |
| `template` | `varchar(64)` | x |  | Mã mẫu báo cáo. |
| `security_alert_id` | `uuid` |  |  | Cảnh báo an ninh gốc (có thể rỗng). |
| `content` | `jsonb` | x | `'{}'` | Nội dung theo mẫu, đã loại dữ liệu cá nhân; không đính kèm bằng chứng gốc. JSON object. |
| `status` | `varchar(5)` | x | `'DRAFT'` | Giá trị: `DRAFT`, `FINAL`. |
| `detected_at` | `timestamptz` | x |  | Thời điểm phát hiện, mốc tính hạn 72 giờ. |
| `deadline_at` | `timestamptz` |  |  | Hạn 72 giờ kể từ detected_at cho DLCN_BREACH (SEC-75); null với CYBER. |
| `finalized_at` | `timestamptz` |  |  | Thời điểm chốt `FINAL`. |
| `finalized_by` | `varchar(64)` |  |  | Người chốt. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.incident_report`

#### 3.2.11. `alert_notification`

::: dac-ta
**Mục đích.** EN-13-10 Lượt gửi thông báo cho cảnh báo vận hành (alert_id) hoặc cảnh báo an ninh (security_alert_id), đúng một trong hai; ghi PENDING cùng giao dịch với cảnh báo, NotificationDispatcher lấy việc bằng FOR UPDATE SKIP LOCKED, thử lại 30 giây, 2 phút, 10 phút rồi chuyển kênh dự phòng (FR-13-046). Khóa lũy đẳng (cảnh báo, kênh, cấp, người nhận) bằng ux_alert_notification. Giữ 2 năm.

**FR phục vụ.** FR-13-046, 053.

**Khóa chính.** (id).

**Duy nhất.** `ux_alert_notification` (coalesce(alert_id, security_alert_id), channel_id, level, recipient).

**Khóa ngoại.** (alert_id, tenant_id) → `alert` xóa theo, (security_alert_id, tenant_id) → `security_alert` xóa theo, (channel_id, tenant_id) → `notification_channel`.

**Ràng buộc CHECK.** `ck_alert_notification_tenant`, `ck_alert_notification_subject`, `ck_alert_notification_level`, `ck_alert_notification_status`, `ck_alert_notification_attempt`, `ck_alert_notification_sent`, `ck_alert_notification_error`, `ck_alert_notification_recipient`.

**Chỉ mục.** `ix_alert_notification_queue`, `ix_alert_notification_alert`, `ix_alert_notification_security`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_alert_notification_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ xóa dòng quá hạn lưu 2 năm tính từ `created_at` (trigger `tg_alert_notification_ret`).

**Ghi chú.** Thư và SMS chỉ mang mã cảnh báo, mức, tóm tắt, liên kết (FR-00-062); `recipient` là mã người dùng hoặc nhóm, `CHECK` chặn địa chỉ thư và số điện thoại. Khóa lũy đẳng `ux_alert_notification` dùng `coalesce(alert_id, security_alert_id)`; mỗi dòng thuộc đúng một loại cảnh báo (`ck_alert_notification_subject`). Cột bất biến sau khi tạo: `id`, `tenant_id`, `alert_id`, `security_alert_id`, `channel_id`, `level`, `recipient`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `alert_id` | `uuid` |  |  | Cảnh báo được thông báo. |
| `security_alert_id` | `uuid` |  |  | Cảnh báo an ninh được thông báo (mức Nghiêm trọng gửi SO ngay, TA sau 15 phút); null khi thông báo cho cảnh báo vận hành. |
| `channel_id` | `uuid` | x |  | Kênh gửi; khóa ngoại kèm `tenant_id`. |
| `channel_code` | `varchar(64)` | x |  | Mã kênh tại thời điểm gửi. |
| `recipient` | `varchar(64)` | x |  | Mã người dùng hoặc mã nhóm; không lưu địa chỉ thư hay số điện thoại (PH-18 phân giải khi gửi). |
| `level` | `smallint` | x | `1` | Cấp leo thang 1…3 của lượt gửi. Từ 1 đến 3. |
| `status` | `varchar(7)` | x | `'PENDING'` | Giá trị: `PENDING`, `SENT`, `FAILED`, `SKIPPED`. |
| `attempt` | `smallint` | x | `0` | Số lần đã thử, tối đa 10. |
| `next_attempt_at` | `timestamptz` | x | `now()` | Thời điểm thử kế tiếp khi `PENDING`. |
| `sent_at` | `timestamptz` |  |  | Thời điểm gửi thành công. |
| `error` | `varchar(500)` |  |  | Mã lỗi và thông điệp ngắn (ERR-13-120); không chứa nội dung thông báo. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.alert_notification`

#### 3.2.12. `siem_target`

::: dac-ta
**Mục đích.** EN-13-16 Mục tiêu SIEM, SOC: giao thức, lược đồ ECS hoặc OCSF, bộ lọc (FR-13-054). Điểm xuất purpose=AUTHORITY (cơ quan chuyên trách) tắt mặc định, chỉ bật kèm basis_ref (BR-13-034). Xóa mềm, mã không dùng lại.

**FR phục vụ.** FR-13-054.

**Khóa chính.** (id).

**Duy nhất.** `uq_siem_target_code` (tenant_id, target_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_siem_target_tenant`, `ck_siem_target_code`, `ck_siem_target_protocol`, `ck_siem_target_endpoint`, `ck_siem_target_schema`, `ck_siem_target_purpose`, `ck_siem_target_filter`, `ck_siem_target_authority`, `ck_siem_target_status`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_siem_target_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_siem_target_nodel`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Cột bất biến sau khi tạo: `id`, `tenant_id`, `target_code`, `protocol`, `purpose`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `target_code` | `varchar(64)` | x |  | Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `name` | `varchar(255)` | x |  | Tên hiển thị. |
| `protocol` | `varchar(10)` | x |  | Giá trị: `SYSLOG_TLS`, `OTLP`. |
| `endpoint` | `varchar(512)` | x |  | host:port (SYSLOG_TLS, RFC 5424 trên TLS) hoặc URL HTTPS (OTLP); phải nằm trong danh sách FQDN của cổng thoát (SEC-16, kiểm ở dịch vụ, ERR-13-039). Mẫu `^[A-Za-z0-9.-]+:[0-9]{2,5}$`. |
| `schema_kind` | `varchar(4)` | x | `'ECS'` | Giá trị: `ECS`, `OCSF`. |
| `purpose` | `varchar(9)` | x | `'SIEM'` | Giá trị: `SIEM`, `AUTHORITY`. |
| `filter` | `jsonb` | x | `'{}'` | Bộ lọc loại dữ liệu cá nhân và nội dung Nhạy cảm theo danh sách khóa cho phép (SEC-66). JSON object. |
| `basis_ref` | `varchar(255)` |  |  | Số hiệu văn bản yêu cầu của cơ quan chuyên trách; bắt buộc khi bật purpose=AUTHORITY. |
| `enabled` | `boolean` | x | `true` | Bật hoặc tắt; tắt thì không tham gia xử lý. |
| `status` | `varchar(7)` | x | `'ACTIVE'` | Giá trị: `ACTIVE`, `RETIRED`. |
| `last_ok_at` | `timestamptz` |  |  | Lần gửi thử hoặc gửi thật thành công gần nhất. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.siem_target`

#### 3.2.13. `dashboard_set`

::: dac-ta
**Mục đích.** EN-13-17 Bộ dashboard chuẩn khai báo bằng mã, nhân bản cho từng tenant ở tổ chức Grafana riêng (FR-13-041). Chỉ lưu trạng thái đồng bộ, không lưu số liệu hay nội dung panel.

**FR phục vụ.** FR-13-041, 059.

**Khóa chính.** (id).

**Duy nhất.** `uq_dashboard_set_code` (tenant_id, set_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_dashboard_set_tenant`, `ck_dashboard_set_code`, `ck_dashboard_set_version`, `ck_dashboard_set_hash`, `ck_dashboard_set_status`, `ck_dashboard_set_synced`, `ck_dashboard_set_error`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_dashboard_set_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_dashboard_set_nodel`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Cột bất biến sau khi tạo: `id`, `tenant_id`, `set_code`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `set_code` | `varchar(64)` | x |  | Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `content_version` | `integer` | x | `1` | Phiên bản nội dung bộ dashboard (không phải version khóa lạc quan). |
| `content_hash` | `char(64)` | x |  | Băm nội dung bộ đã nhân bản; so với kho Git để phát hiện lệch. Mẫu `^[0-9a-f]{64}$`. |
| `grafana_org_id` | `bigint` |  |  | Tổ chức Grafana của tenant. |
| `status` | `varchar(11)` | x | `'PENDING'` | Giá trị: `PENDING`, `SYNCED`, `SYNC_FAILED`. |
| `source_revision` | `varchar(64)` |  |  | Mã commit của kho cấu hình Git đã nạp mục này. |
| `synced_at` | `timestamptz` |  |  | Lần đồng bộ thành công gần nhất. |
| `last_error` | `varchar(500)` |  |  | Lỗi đồng bộ gần nhất. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.dashboard_set`

#### 3.2.14. `saved_query`

::: dac-ta
**Mục đích.** EN-13-18 Truy vấn đã lưu (bộ lọc tra log, kiểm toán, nhật ký truy cập) theo người dùng, có thể chia sẻ trong tenant (FR-13-026). Xóa cứng khi chủ sở hữu xóa. Không lưu dữ liệu kết quả.

**FR phục vụ.** FR-13-026.

**Khóa chính.** (id).

**Duy nhất.** `uq_saved_query_name` (tenant_id, owner, kind, name).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_saved_query_tenant`, `ck_saved_query_kind`, `ck_saved_query_query`, `ck_saved_query_name`.

**Chỉ mục.** `ix_saved_query_list`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_saved_query_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Cột bất biến sau khi tạo: `id`, `tenant_id`, `kind`, `owner`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `kind` | `varchar(6)` | x |  | Giá trị: `LOG`, `AUDIT`, `ACCESS`. |
| `name` | `varchar(120)` | x |  | Tên hiển thị. |
| `query` | `jsonb` | x |  | Bộ lọc dạng danh sách trắng (không biểu thức tự do); không chứa số định danh người bị tra cứu (BR-13-005), nếu có thì lưu object_key_hmac. JSON object. |
| `shared` | `boolean` | x | `false` | true: chia sẻ cho người dùng khác trong tenant. |
| `owner` | `varchar(64)` | x |  | Chủ sở hữu (mã người dùng). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.saved_query`

#### 3.2.15. `probe_definition`

::: dac-ta
**Mục đích.** EN-13-20 Định nghĩa kiểm tra tổng hợp: gọi API quan trọng của tenant mỗi 13.probe.interval-seconds qua đường biên ngoài với cờ x-dh-synthetic, đo thành công và độ trễ (FR-13-008). Kết quả ở chỉ số dh_probe_*, không lưu ở bảng.

**FR phục vụ.** FR-13-008.

**Khóa chính.** (id).

**Duy nhất.** `uq_probe_definition_code` (tenant_id, probe_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_probe_definition_tenant`, `ck_probe_definition_code`, `ck_probe_definition_api`, `ck_probe_definition_method`, `ck_probe_definition_interval`, `ck_probe_definition_status_code`, `ck_probe_definition_timeout`, `ck_probe_definition_params`, `ck_probe_definition_state`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_probe_definition_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không cho xóa dòng, đổi trạng thái thay vì xóa (trigger `tg_probe_definition_nodel`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag. Cột bất biến sau khi tạo: `id`, `tenant_id`, `probe_code`, `created_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `probe_code` | `varchar(64)` | x |  | Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `target_api` | `varchar(255)` | x |  | Mẫu `^/[A-Za-z0-9._~/{}:-]+$`. |
| `method` | `varchar(6)` | x | `'GET'` | Giá trị: `GET`, `HEAD`, `POST`. |
| `interval_seconds` | `integer` | x | `60` | Từ 30 đến 300. |
| `expected_status` | `smallint` | x | `200` | Từ 100 đến 599. |
| `timeout_ms` | `integer` | x | `5000` | Từ 500 đến 30000. |
| `sample_params` | `jsonb` | x | `'{}'` | Giá trị mẫu cố định cho tham số bắt buộc của API đích: dữ liệu thử, không phải dữ liệu thật. JSON object. |
| `enabled` | `boolean` | x | `true` | Tắt thì ngừng kiểm tra (ví dụ tenant tạm ngừng). |
| `status` | `varchar(7)` | x | `'ACTIVE'` | Giá trị: `ACTIVE`, `RETIRED`. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ph13_obs.probe_definition`

#### 3.2.16. `pii_finding`

::: dac-ta
**Mục đích.** Kết quả quét dữ liệu cá nhân trong log hằng ngày 02:00: chỉ DU, logger, mã mẫu, số lần; KHÔNG lưu giá trị phát hiện (BR-13-011, NFR-13-021). Giữ 12 tháng. Tái phạm 3 ngày liên tiếp thì nâng CRITICAL và đề nghị quarantine.

**FR phục vụ.** FR-13-005.

**Khóa chính.** (id).

**Duy nhất.** `uq_pii_finding` (tenant_id, scan_date, du_code, logger, pattern_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_pii_finding_tenant`, `ck_pii_finding_du`, `ck_pii_finding_pattern`, `ck_pii_finding_count`.

**Chỉ mục.** `ix_pii_finding_date`, `ix_pii_finding_du`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_pii_finding_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ xóa dòng quá hạn lưu 12 tháng tính từ `created_at` (trigger `tg_pii_finding_ret`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` (nếu có) là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `scan_date` | `date` | x |  | Ngày quét. |
| `du_code` | `varchar(32)` | x |  | Mẫu `^[a-z][a-z0-9-]{1,31}$`. |
| `logger` | `varchar(255)` | x |  | Tên logger của DU nơi lọt giá trị. |
| `pattern_code` | `varchar(16)` | x |  | ID12 (số định danh 12 chữ số có kiểm cấu trúc), PHONE, EMAIL, CARD (qua Luhn), KEY_NAME (khóa tên nhạy cảm có giá trị khác ***). Giá trị: `ID12`, `PHONE`, `EMAIL`, `CARD`, `KEY_NAME`. |
| `occurrences` | `integer` | x |  | Số lần phát hiện trong ngày; không lưu giá trị. |
| `consecutive_days` | `smallint` | x | `1` | Số ngày liên tiếp tái phạm. |
| `quarantine` | `boolean` | x | `false` | Cờ obs.pii.quarantine theo DU do SO duyệt: cấu hình gateway loại log của DU khỏi kho tra cứu tới khi sửa. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |

: Cột của bảng `ph13_obs.pii_finding`

#### 3.2.17. `detect_cursor`

::: dac-ta
**Mục đích.** Mốc đã xử lý của DetectionEngine theo (tenant, luật); sau gián đoạn chạy bù theo bước 5 phút từ mốc, tối đa 24 giờ (SDD §4.20). Bảng kỹ thuật, khóa tự nhiên.

**FR phục vụ.** FR-13-052.

**Khóa chính.** (tenant_id, rule_code).

**Duy nhất.** Không.

**Khóa ngoại.** (tenant_id, rule_code) → `detection_rule`.

**Ràng buộc CHECK.** `ck_detect_cursor_tenant`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_detect_cursor_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Bảng kỹ thuật với khóa tự nhiên, không có `id`, không có cột sửa ngoài `processed_until`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `rule_code` | `varchar(40)` | x |  | Mã luật; cùng `tenant_id` trỏ tới bảng luật. |
| `processed_until` | `timestamptz` | x |  | Cửa sổ đã xử lý tới thời điểm này. |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |

: Cột của bảng `ph13_obs.detect_cursor`

#### 3.2.18. `outbox`

::: dac-ta
**Mục đích.** Hộp thư đi (DD-11) của module observability cho EVT-13-01…04, 10, 13, 14, ghi cùng giao dịch với đổi trạng thái; Debezium Outbox Router (QM-VUA, QM-LON) hoặc OutboxRelay (QM-NHO) đọc. Dọn sau 3 ngày. Chặn khóa bí mật trong payload.

**FR phục vụ.** Hạ tầng cho EVT-13-01…04, 10, 13, 14 (FR-13-044, 047, 053, 061).

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_obs_outbox_tenant`, `ck_obs_outbox_type`, `ck_obs_outbox_topic`, `ck_obs_outbox_topic_tenant`, `ck_obs_outbox_trace`, `ck_obs_outbox_no_secret`.

**Chỉ mục.** `ix_obs_outbox_occurred`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_outbox_{select,insert,update,delete}` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Dọn sau 3 ngày; chặn khóa bí mật trong `payload`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `event_id` | `uuid` | x |  | Mã sự kiện (UUID v7), khóa khử trùng ở bên nhận. |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `PLATFORM`; khóa RLS (`app.tenant_id`). |
| `event_type` | `varchar(128)` | x |  | Mẫu `^EVT-13-[0-9]{2}$\|^[a-z][a-zA-Z0-9.]{2,127}$`. |
| `topic` | `varchar(249)` | x |  | Mẫu `^[a-z0-9]+\.obs\.[a-z0-9.-]+\.v[0-9]+$`. |
| `aggregate_type` | `varchar(64)` | x |  | Loại thực thể phát sinh sự kiện. |
| `aggregate_id` | `text` | x |  | Mã thực thể phát sinh sự kiện. |
| `payload` | `jsonb` | x |  | Nội dung sự kiện JSON; không chứa bí mật. |
| `trace_id` | `char(32)` | x |  | Mẫu `^[0-9a-f]{32}$`. |
| `occurred_at` | `timestamptz` | x | `now()` | Thời điểm phát sinh sự kiện. |

: Cột của bảng `ph13_obs.outbox`

#### 3.2.19. `shedlock`

::: dac-ta
**Mục đích.** Khóa tác vụ nền của module observability (RuleReconciler, EscalationScheduler, NotificationDispatcher, DetectionEngine, PiiScanner, SyntheticProbeRunner, OverridesReconciler); bảng kỹ thuật không có tenant_id.

**FR phục vụ.** Tác vụ nền của FR-13-008, 044, 046, 052, 059.

**Khóa chính.** (name).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không bật RLS. Bảng kỹ thuật không chứa dữ liệu nghiệp vụ, không có `tenant_id`.

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `name` | `varchar(64)` | x |  | Tên khóa tác vụ. |
| `lock_until` | `timestamptz` | x |  | Khóa có hiệu lực tới. |
| `locked_at` | `timestamptz` | x |  | Thời điểm lấy khóa. |
| `locked_by` | `varchar(255)` | x |  | Bản sao đang giữ khóa. |

: Cột của bảng `ph13_obs.shedlock`

<!-- gen:tables:end -->

### 3.3. Truy vấn chính và chỉ mục phục vụ

Bảng dưới liệt kê các truy vấn quyết định thiết kế chỉ mục. Mọi truy vấn trên `audit_event` luôn có điều kiện `tenant_id` đứng đầu và, khi có thể, cận `recorded_at` để PostgreSQL loại phân vùng ngoài khoảng khi thực thi (đã kiểm bằng `EXPLAIN ANALYZE`: truy vấn có cận dưới và cận trên báo "Subplans Removed: 7" trên 8 phân vùng).

| Truy vấn | Bảng | Chỉ mục | Ghi chú |
|---|---|---|---|
| Tra cứu theo thời gian, phân trang con trỏ `(recorded_at, seq)`, tối đa 200 dòng | `audit_event` | `ix_audit_event_time` | Đếm trước tối đa 1.000.001 dòng để chặn phạm vi quá rộng (BR-13-029, FR-13-020) |
| Lịch sử một đối tượng (tab "Lịch sử") | `audit_event` | `ix_audit_event_object` | `(tenant_id, object_type, object_id, recorded_at DESC)` (FR-13-022) |
| Theo người thao tác, theo hành động, theo `trace_id`, theo phiên | `audit_event` | `ix_audit_event_actor`, `_action`, `_trace`, `_session` | Bộ lọc là danh sách trắng, không biểu thức tự do (SDD §4.9) |
| Tra theo đối tượng bị tra cứu (HMAC) | `audit_event` | `ix_audit_event_keyhmac` (một phần) | Chỉ bản ghi có khóa nhạy cảm; số định danh không bao giờ lưu (BR-13-005, FR-13-023) |
| Khử trùng bản ghi theo `id` | `audit_event` | `ix_audit_event_id` | Kèm cận `recorded_at` bằng thời điểm nhỏ nhất trong lô trừ 1 ngày, chỉ chạm một đến hai phân vùng (SDD §4.3) |
| Đối chiếu số lượng theo (DU, ngày) | `audit_event` | `ix_audit_event_source` | Quét phân vùng của tháng ngày `D` và tháng kế tiếp (SDD §4.8) |
| Kiểm tra toàn vẹn đọc theo `seq` | `audit_event` | Khóa chính `(tenant_id, seq, recorded_at)` | Con trỏ khóa, trang 10.000; dùng `last_recorded_at` của neo làm cận phân vùng (SDD §4.7) |
| Trigger đầu chuỗi đếm đoạn liền kề | `audit_event` | Khóa chính | Cận dưới `last_recorded_at` cũ, cận trên `last_recorded_at` mới; đo thử lô 500 bản ghi trung bình 85 đến 94 ms với bảng 200.000 dòng (mục 4.3) |
| Neo gần nhất của tenant | `audit_anchor` | `ix_audit_anchor_seq` | Điểm xuất phát của kiểm tra gia tăng |
| Lô WORM chưa đối chiếu | `audit_worm_batch` | `ix_audit_worm_batch_unverified` | `PartitionManager` chỉ chốt `SEALED` khi không còn lô chưa xác minh |
| Hàng đợi xuất bằng chứng, tệp hết hạn | `audit_export` | `ix_audit_export_queue`, `ix_audit_export_expiry` | Worker lấy việc bằng `FOR UPDATE SKIP LOCKED` (SDD §8.1) |
| Upsert cảnh báo từ webhook Alertmanager | `alert` | `ux_alert_open` | Khóa tự nhiên `(tenant_id, rule_code, fingerprint)` chỉ cho cảnh báo mở; gửi lặp không nhân đôi (SDD §4.17) |
| Danh sách cảnh báo theo trạng thái, mức | `alert` | `ix_alert_list` | UI-13-10 |
| Quét leo thang mỗi 30 giây | `alert` | `ix_alert_escalation` (một phần) | Chỉ `CRITICAL` đang `FIRING` (BR-13-022) |
| Hết hạn tạm ẩn | `alert` | `ix_alert_silence_expiry` (một phần) | Quay về `FIRING` nếu điều kiện còn (BR-13-021) |
| Gom nhóm, thống kê hiệu quả (MTTA, MTTR, tỷ lệ cảnh báo giả) | `alert`, `alert_action` | `ix_alert_group`, `ix_alert_rule_time`, `ix_alert_action_alert` | FR-13-045, 050 |
| Hàng đợi gửi thông báo | `alert_notification` | `ix_alert_notification_queue` (một phần) | `FOR UPDATE SKIP LOCKED`, thử lại 30 giây, 2 phút, 10 phút (FR-13-046) |
| Cảnh báo an ninh mở của (luật, chủ thể) | `security_alert` | `ux_security_alert_open` | Gom trong cửa sổ khi còn mở (FR-13-052) |
| Hạn báo cáo sự cố 72 giờ | `incident_report` | `ix_incident_report_deadline` (một phần) | Nhắc ở 24, 48, 60 giờ (FR-13-055) |

: Truy vấn chính và chỉ mục phục vụ

## 4. DDL và changelog Liquibase

Chương này nêu nơi đặt DDL, cách chia changeset, kết quả chạy thử trên PostgreSQL sạch, kết quả bài kiểm cô lập và bất biến, số đo tốc độ ghi chuỗi, và bảng ánh xạ lỗi của CSDL sang mã lỗi PH-13 để lớp dịch vụ bắt đúng lỗi.

### 4.1. Tệp

Hai tệp DDL là nguồn duy nhất, chia changeset bằng `-- @file`, `-- @changeset`, `-- @rollback` như PH-04, PH-05, PH-07: [`ph13/ddl/ph13_audit.sql`](ph13/ddl/ph13_audit.sql) cho schema `ph13_audit` và [`ph13/ddl/ph13_obs.sql`](ph13/ddl/ph13_obs.sql) cho schema `ph13_obs`. Hai tệp độc lập, chạy thứ tự nào cũng được (cả hai tạo vai trò dùng chung theo kiểu idempotent); không có khóa ngoại giữa hai schema. Changelog Liquibase sinh từ các dấu này bằng công cụ của PH-07 sau khi tham số hóa tên phân hệ và tác giả (như PH-05); thuộc tính `splitStatements:false` đã đặt cho changeset chứa thân hàm.

| Tệp (dấu `@file`) | Nội dung |
|---|---|
| `13-0000-bootstrap.sql` | Sáu vai trò, `btree_gist`, schema `ph13_audit`, biến phiên |
| `13-0001-functions.sql` | `tg_touch`, `p_enable_rls`, `tg_append_only`, `tg_forbid_delete`, `tg_guard_retention`, `tg_immutable`, `fn_hash` |
| `13-0010-chain.sql` | `audit_signing_key`, `audit_chain`, `audit_event` kèm phân vùng, chỉ mục, trigger chuỗi |
| `13-0020-anchor.sql` | `audit_anchor`, `audit_anchor_publish` |
| `13-0030-worm.sql` | `audit_worm_batch` |
| `13-0040-verify-export.sql` | `audit_verification`, `audit_export` |
| `13-0050-reconcile-partition.sql` | `audit_reconciliation`, `audit_partition`, thủ tục `p_archive_partition` |
| `13-0060-ingest.sql` | `audit_quarantine`, `audit_source_grant` |
| `13-0070-misc.sql` | `outbox`, `shedlock` của `ph13_audit` |
| `13-0900-grants.sql` | Quyền theo bảng, chạy lại mỗi lần (`runAlways`) |
| `13-0950-seed.sql` | Dòng `audit_partition` cho các phân vùng vừa tạo (context `seed`) |
| `13-1000-bootstrap.sql`, `13-1001-functions.sql` | Vai trò, schema `ph13_obs`, hàm chung, `fn_params_valid`, `fn_threshold_ok`, `fn_limit_ok` |
| `13-1010-config.sql` | `tenant_obs_config` |
| `13-1020-rules.sql` | `runbook`, `alert_rule` |
| `13-1030-notify.sql` | `notification_channel`, `oncall_schedule` |
| `13-1040-alert.sql` | `alert`, `alert_action` |
| `13-1050-security.sql` | `detection_rule`, `security_alert`, `incident_report` |
| `13-1055-notification.sql` | `alert_notification` (sau `security_alert` vì trỏ tới cả hai loại cảnh báo) |
| `13-1060-misc.sql` | `siem_target`, `dashboard_set`, `saved_query`, `probe_definition`, `pii_finding`, `detect_cursor`, `outbox`, `shedlock` |
| `13-1900-grants.sql` | Quyền theo bảng và theo cột (`runAlways`) |
| `13-1950-seed.sql` | Thủ tục `p_seed_tenant` (cấu hình, kênh, 27 luật phát hiện) |

: Tệp và changeset của DDL PH-13

Mỗi changeset có `-- @rollback` (xóa bảng, hàm vừa tạo); riêng vai trò và quyền không thu hồi khi rollback. Thủ tục và hàm dùng `$f$ … $f$`, nên các changeset đó đặt `splitStatements:false`.

### 4.2. Kết quả chạy thử

Chạy ngày 26/11/2026 trên PostgreSQL 16.16, CSDL chưa có schema `ph13_*`:

- [`ph13_audit.sql`](ph13/ddl/ph13_audit.sql) và [`ph13_obs.sql`](ph13/ddl/ph13_obs.sql) chạy không lỗi với `ON_ERROR_STOP`, theo cả hai thứ tự; tạo 33 bảng, 6 phân vùng `audit_event` (tháng trước và 5 tháng tới), 124 chính sách RLS.
- Bài kiểm [`ph13/test/ph13_isolation_test.sql`](ph13/test/ph13_isolation_test.sql) chạy với bốn tài khoản đăng nhập thử (thành viên `ph13_app` và `ph13_obs_app`, `ph13_verify`, `ph13_archive`, `ph13_readonly`); mỗi khối chạy sau `SET ROLE` sang tài khoản thử hoặc `ph13_owner`, không chạy với quyền siêu người dùng, đạt **171/171 khối** (mỗi khối kiểm một điều: lỗi mong đợi bị bắt và phải đúng mã `SQLSTATE`, sai thì dừng cả tệp). Bảng kiểm toán chỉ thêm nên bài kiểm chỉ chạy được trên CSDL rỗng; CI dựng PostgreSQL mới cho mỗi lần chạy.
- Công cụ `tools/gen_tables_md.py` và `tools/them_dac_ta_bang.py` sinh toàn bộ chương 3 từ DDL (33 bảng, 517 cột).

Bảng sau tóm tắt các nhóm kiểm và điều được chứng minh.

| Nhóm (khối) | Số khối | Điều được chứng minh |
|---|---|---|
| A. Chuỗi và cô lập (0 đến 8) | 27 | Nối lô liền kề; T01 không đọc, không chèn dòng của T68; phiên không có tenant thấy 0 dòng; `ph13_app` không `UPDATE`, `DELETE`, `TRUNCATE`, không tắt trigger, không đọc phân vùng; chủ bảng cũng bị trigger chặn; khoảng trống `seq`, `prev_hash` sai, bản ghi mồ côi, `head_seq` giảm, `head_hash` không khớp đều bị chặn; khóa `password` mang giá trị thật bị chặn |
| B. Neo, WORM (9 đến 12) | 13 | Neo không lùi, không vượt đầu chuỗi, không sửa; khóa ký chưa có bị chặn; tenant không ghi được khóa ký nhưng đọc được; lô WORM liền kề không chồng, không vượt đầu chuỗi; `retain_until` chỉ kéo dài |
| C. Xác minh, xuất, đối chiếu (13 đến 18) | 19 | Mỗi tenant một lượt `RUNNING`; kết quả chốt không sửa; xuất bằng chứng không nhảy trạng thái, `READY` thiếu chữ ký bị chặn, không chạy trùng phạm vi; `MATCH` khi còn chênh lệch bị chặn |
| D. Cách ly, nguồn (19 đến 21) | 5 | Bản cách ly không xóa trước hạn, không sửa nguyên văn; cấp nguồn không xóa |
| E. Đóng chuỗi (22) | 6 | Chuỗi `CLOSED` không nhận bản ghi, không mở lại, vẫn đọc được; `SUSPECT` thiếu vị trí bị chặn |
| F. Lưu trữ phân vùng (23 đến 25) | 13 | Chỉ `ph13_archive` gọi được thủ tục; từ chối khi chưa xác minh WORM, chưa đến hạn, chưa `SEALED`; lưu trữ xong bản ghi rời bảng, đầu chuỗi giữ nguyên, không chuyển ngược `ARCHIVED` |
| G. Vai trò đọc (26 đến 27) | 5 | `ph13_verify` chỉ đọc; `ph13_readonly` không đọc `audit_event` hay nguyên văn bản cách ly |
| H. Quan sát (30 đến 43) | 83 | Nạp 27 luật phát hiện lũy đẳng; runbook đủ năm mục; luật Nghiêm trọng cần triệu chứng; luật chuẩn tenant không sửa; vòng đời, tạm ẩn, leo thang cảnh báo; tham số ngoài miền; ngưỡng ngoài biên; đóng cảnh báo an ninh cần kết luận; thông báo cho cảnh báo vận hành và an ninh, kênh, SIEM, outbox, báo cáo sự cố; cách ly obs |

: Nhóm bài kiểm và điều được chứng minh

Bài kiểm này là cơ sở cho nhóm ca cô lập tenant, bất biến nhật ký và tách nhiệm của D05-02-PH13; trong CI nó được bọc bằng `TenantIsolationIT` (Testcontainers, như D03-02-PH13 §12).

### 4.3. Đo thử tốc độ ghi chuỗi

[`ph13/test/ph13_bench_chain.sql`](ph13/test/ph13_bench_chain.sql) ghi 400 lô, mỗi lô 500 bản ghi (200.000 bản ghi) cho một tenant, mỗi bản ghi mang `before`, `after` nhỏ, 10 chỉ mục, RLS và đủ `CHECK`; mỗi lô kết thúc bằng một `UPDATE audit_chain` kích hoạt trigger kiểm liền kề. Đo trên máy chạy CI (4 nhân, 15 GB bộ nhớ, PostgreSQL 16 cấu hình mặc định, đĩa chung), vòng lặp PL/pgSQL trong một giao dịch mỗi lô, không có mạng và không có khóa tư vấn tranh chấp.

| Chỉ số | Giá trị |
|---|---|
| Thời gian một lô 500 bản ghi, trung bình | 85 đến 94 ms (ba lần chạy) |
| p95, tối đa | 135 đến 141 ms, tối đa 176 ms |
| Thông lượng suy ra cho một tenant | khoảng 5.300 đến 5.900 bản ghi/giây |
| Yêu cầu | NFR-13-008: ghi tới cam kết p95 ≤ 2 giây, toàn nền tảng ≥ 1.000 bản ghi/giây; giả định cao điểm 400 bản ghi/giây (GĐ-13-02) |

: Tốc độ ghi chuỗi đo thử

Số đo cho thấy phần CSDL (kể cả trigger kiểm liền kề) chiếm khoảng 0,14 giây ở p95 cho một lô trong ngân sách 2 giây của NFR-13-008, còn dư lớn cho khóa tư vấn, mạng và `fsync` ở hạ tầng thật. Đây là số đo trên máy thử, chưa phản ánh hạ tầng `HT-A`, `HT-B`; kiểm lại ở môi trường thật khi có bộ kiểm thử tải của D05-02-PH13.

### 4.4. Ánh xạ lỗi của CSDL sang mã lỗi PH-13

Lớp dịch vụ bắt `SQLException` và đổi sang lỗi RFC 9457 theo bảng dưới; tên ràng buộc ổn định nên dùng làm khóa ánh xạ. Mã lỗi ở FRS §9.1.

| `SQLSTATE` | Ràng buộc hoặc trigger | Mã lỗi PH-13 |
|---|---|---|
| `23514` | `ck_runbook_five_sections`, khóa ngoại `fk_alert_rule_runbook` | ERR-13-017 (luật thiếu runbook hoặc runbook thiếu mục) |
| `23514` | `ck_alert_rule_critical_symptom`, `ck_alert_rule_resource_only` | ERR-13-003 kèm `errors[]` (BR-13-009) |
| `23514` | `tg_alert_rule_guard` (vượt `13.alert.max-rules`) | ERR-13-041 |
| `23514` | `ck_tenant_obs_config_params` | ERR-13-040 |
| `23514` | `tg_alert_guard` (hạn tạm ẩn, leo thang), `ck_alert_silence` | ERR-13-021 |
| `23514` | `ck_alert_action_resolve` | ERR-13-022 |
| `23514` | `ck_security_alert_closed`, `ck_security_alert_accepted` | ERR-13-023 |
| `23514` | `ck_detection_rule_threshold`, `_limit`, `_fixed` | ERR-13-024 |
| `23514` | `ck_siem_target_authority`, `ck_siem_target_endpoint` | ERR-13-039 |
| `23514` | `tg_audit_chain_guard`, `tg_audit_event_covered` | ERR-13-106 (ChainWriter hủy và thử lại giãn dần) |
| `23514` | `ck_audit_event_no_secret` | ERR-13-105 (cách ly, không vào chuỗi) |
| `23514` | `p_archive_partition` (chưa đủ điều kiện) | ERR-13-125 |
| `23514` | `ck_audit_export_ready`, `_no_orphan_file`, `_failed` | ERR-13-026 (không ký được thì không xuất) |
| `23514` | `ck_audit_export_reason`, `_basis` | ERR-13-008 (thiếu lý do, căn cứ) |
| `23505` | `ux_audit_verification_running` | ERR-13-032 |
| `23505` | `ux_audit_export_active` | ERR-13-025 (đã có yêu cầu cùng phạm vi) |
| `23505` | `uq_alert_rule_code`, `uq_runbook_code`, `uq_*_code` | ERR-13-002 (mã trùng, mã không dùng lại) |
| `23505` | `ux_alert_open`, `ux_security_alert_open` | Không phải lỗi: upsert lũy đẳng (webhook, gom nhóm) |
| `55000` | `tg_alert_guard`, `tg_security_alert_guard`, `tg_audit_export_guard`, `tg_audit_partition_guard` (trạng thái không hợp lệ) | ERR-13-020 |
| `55000` | `tg_platform_guard` | ERR-13-019 |
| `55000` | `tg_audit_chain_guard` (chuỗi đã đóng) | ERR-13-043 |
| `55000` | `tg_audit_event_append`, `tg_forbid_delete`, `tg_guard_retention`, `tg_immutable` | Lỗi lập trình hoặc can thiệp: ghi nhật ký mức Nghiêm trọng, không trả chi tiết cho người dùng |
| `42501` | Chính sách RLS (`rls_*`) khi ghi chéo tenant | ERR-13-044; khi đọc, RLS lọc im lặng nên dòng của tenant khác không lộ (kể cả sự tồn tại) |
| `42501` | Thiếu quyền bảng hoặc cột | Lỗi cấu hình vai trò: ghi nhật ký mức Nghiêm trọng, không trả chi tiết cho người dùng |

: Ánh xạ lỗi của CSDL sang mã lỗi PH-13

Ràng buộc định dạng không nêu ở bảng (mẫu mã, độ dài, kiểu JSON) trả ERR-13-003 kèm `errors[]` theo D03-04-PH13. Lỗi `23505` hay `23514` xảy ra ở lô ghi kiểm toán không đi qua bảng này: `ChainWriter` hủy giao dịch, ghi ERR-13-106 và thử lại giãn dần (SDD §8.4).

## 5. Dữ liệu khởi tạo

DDL không nạp dữ liệu nghiệp vụ vì phần lớn dữ liệu khởi tạo phụ thuộc môi trường (khóa, tenant, người dùng). Hai nhóm được nạp bằng SQL (phân vùng và dữ liệu mặc định theo tenant); phần còn lại do `ObsProvisioner` và `StandardRuleCatalog` nạp ở ứng dụng (FR-13-059).

| Dữ liệu | Tenant | Nội dung | Nguồn |
|---|---|---|---|
| Phân vùng `audit_event` | Chung | Sáu phân vùng (tháng trước và 5 tháng tới) và dòng `audit_partition` tương ứng; tháng đã qua ở `SEALED` | `13-0950-seed.sql`, `p_ensure_month_partitions` |
| Cấu hình quan sát | Mỗi tenant | Một dòng `tenant_obs_config` với `scale` theo hồ sơ, tham số rỗng (dùng mặc định của nền tảng) | `p_seed_tenant`, FR-13-059 bước S6 |
| Kênh trong ứng dụng | Mỗi tenant | Kênh `inapp-default` | `p_seed_tenant`, bước S5 |
| Luật phát hiện | Mỗi tenant | 27 dòng: 25 luật UC-SEC-01…25 (19 nạp ở Ruler, 7 do `DetectionEngine` chạy trên bản ghi kiểm toán gồm UC-SEC-10, 11, 12, 14, 25 và hai luật phụ, 1 do `BreakHandler` phát: UC-SEC-20); năm luật không tắt được: UC-SEC-04, 09, 18, 20, 23 | `p_seed_tenant`, D03-07 §7.5, SDD §4.20 |
| Khóa ký `audit_signing_key` | `PLATFORM` | Phiên bản 1: khóa công khai lấy từ OpenBao Transit lúc cài nền tảng | `ObsProvisioner` (không đặt trong DDL vì phụ thuộc môi trường) |
| Chuỗi kiểm toán `audit_chain` | Mỗi tenant, `PLATFORM` | Dòng với `genesis_hash = SHA-256("genesis:" ‖ mã ‖ thời điểm ‖ nonce)`, tệp `_genesis.json` ghi WORM | FR-13-059 bước S1 |
| Cấp nguồn `audit_source_grant` | Mỗi tenant | Cặp (DU nguồn, tenant) cho từng DU có kiểm toán | FR-13-059 bước S1 |
| Luật chuẩn, runbook chuẩn, bộ dashboard | Mỗi tenant | 26 luật chuẩn của FR-13-043 kèm runbook năm mục, bộ dashboard chuẩn; nhân bản từ Git với tham số SLO của tenant | `StandardRuleCatalog`, bước S4, S5 |
| Lịch trực, kiểm tra tổng hợp mặc định | Mỗi tenant | Lịch gán nhóm TA; kiểm tra tổng hợp cho API quan trọng | `ObsProvisioner`, bước S5 (cần người dùng thật) |

: Dữ liệu khởi tạo

`p_seed_tenant(tenant, scale)` phải được gọi trong phiên đã đặt `app.tenant_id` bằng đúng tenant đó (bài kiểm 30b), và lũy đẳng (`ON CONFLICT DO NOTHING`, bài kiểm 30c). Tenant `PLATFORM` dùng cùng thủ tục khi dựng nền tảng. Phân vùng và `audit_partition` chạy dưới phiên `PLATFORM`.

## 6. Kho lưu trữ ngoài PostgreSQL

PostgreSQL chỉ giữ siêu dữ liệu và bản ghi kiểm toán trực tuyến. Bản không sửa được của nhật ký nằm ở kho WORM; số liệu quan sát nằm ở bốn kho chuyên dụng; sự kiện đi qua Kafka. Chương này nêu từng kho, khóa đối tượng, thời hạn giữ và cách cô lập tenant, để DBA và kỹ sư biết dữ liệu nào ở đâu và bảng PostgreSQL nào trỏ tới nó.

### 6.1. Kho đối tượng

Kho WORM là Ceph RGW, tách bucket, khóa và tài khoản quản trị khỏi kho sao lưu và khỏi Garage (BR-13-013, Q306, Q347). Hai tài khoản S3 của kho WORM tách quyền và xoay 90 ngày ở OpenBao KV: `worm-writer` chỉ `PutObject`, `GetObject`, `ListBucket` (không xóa, không đặt hạn khóa); `worm-retention` chỉ `PutObjectRetention` để kéo dài hạn khi tenant nâng thời hạn (SDD §4.6).

| Bucket (kho) | Đối tượng và khóa | Cấu hình | Giữ | Bảng PostgreSQL trỏ tới |
|---|---|---|---|---|
| `dh-worm-audit` (Ceph RGW) | Lô `audit/{tenant}/{yyyy}/{MM}/{dd}/{seqĐầu}-{seqCuối}.jsonl.zst` và `….manifest.json`; điểm khởi đầu `audit/{tenant}/_genesis.json` | Object Lock `COMPLIANCE`, bật versioning, mã hóa phía máy chủ, `Content-MD5` khi ghi | `13.audit.worm-retention-years` (mặc định 5, tenant đặt 3 đến 10), chỉ kéo dài | `audit_worm_batch.object_key`, `manifest_key` |
| `dh-worm-audit` | Neo `anchors/{tenant}/{yyyy}/{MM}/{dd}/{HH}.json`; khóa công khai `keys/dh-audit-sign.json` | Như trên | Như bản ghi | `audit_anchor_publish.worm_object`, `audit_signing_key.worm_object` |
| `dh-evidence` (Ceph RGW) | Chứng cứ đứt chuỗi: khoảng bản ghi nghi vấn từ bảng và từ WORM, kết quả kiểm tra, biên bản băm | Object Lock | Theo quy trình ứng cứu (SEC-75) | Tham chiếu qua `EVT-13-05` |
| `dh-audit-export-tmp` (Garage) | Gói bằng chứng `exports/{tenant}/{exportId}.zip` | Vòng đời xóa sau 7 ngày | 7 ngày (liên kết tải 15 phút) | `audit_export.file_object` |
| `dh-seclog-archive` (Garage) | Log an ninh nén của tenant | Vòng đời 3 năm | 3 năm | Không có bảng (đường dẫn theo tenant và ngày) |

: Kho đối tượng của PH-13

Quy ước khóa đối tượng của lô WORM được kiểm bằng `ck_audit_worm_batch_key` (phải bắt đầu `audit/{tenant}/…` và kết thúc `{seqĐầu}-{seqCuối}.jsonl.zst`), nên không thể ghi siêu dữ liệu cho một đối tượng đặt sai chỗ. D03-09 ghi bucket `dh-worm-audit` với tiền tố `{tenant}/`; thiết kế này đặt `audit/` trước tiền tố tenant để cùng bucket chứa lô, neo và khóa mà vẫn cô lập theo tiền tố, ghi ở mục đề nghị đồng bộ. Vòng đời bucket xóa đối tượng sau hạn giữ cộng 30 ngày; RGW từ chối xóa khi khóa còn hiệu lực nên quy tắc an toàn khi tenant đã kéo dài hạn.

### 6.2. Kafka

Kafka giữ bản ghi kiểm toán đến PH-13 và sự kiện PH-13 phát đi. Topic tạo bằng tài nguyên Strimzi trong kho GitOps của tenant (ADR-072); tên topic mang tenant bằng chữ thường (tenant `PLATFORM` dùng `platform`) và là nguồn sự thật của tenant cho bộ tiếp nhận (không đọc tenant từ nội dung, BR-13-027).

| Topic | Chiều | Giữ | Ghi chú |
|---|---|---|---|
| `{tenant}.obs.audit.recorded.v1`, `platform.obs.audit.recorded.v1` | `dh-audit` của DU → bộ tiếp nhận | 7 ngày | `acks=all`; offset xác nhận sau khi cam kết ghi chuỗi (BR-13-004); khóa phân vùng là `id` bản ghi (giả định: không cần thứ tự vì PH-13 gán `seq`); không có hàng đợi thư chết, bản lỗi vào `audit_quarantine` |
| `{tenant}.obs.access.logged.v1` | APISIX `kafka-logger` → ClickHouse | 3 ngày | Siêu dữ liệu lượt gọi, không thân bản tin (FR-13-006) |
| `{tenant}.obs.…` (14 sự kiện EVT-13-01…14) | Outbox của PH-13 → PH-18, PH-01, SIEM, trung tâm thông báo | Theo cấp phát GitOps của PH-10 | Bảng nguồn nêu ở bảng sau |

: Topic Kafka của PH-13

Mỗi sự kiện đi qua đúng một bảng `outbox` theo module phát; `ck_audit_outbox_topic_tenant` và `ck_obs_outbox_topic_tenant` bảo đảm tiền tố topic khớp `tenant_id`.

| Bảng `outbox` | Sự kiện (topic `{tenant}.obs.` + phần dưới) |
|---|---|
| `ph13_audit.outbox` | EVT-13-05 `audit.chain-broken.v1`, 06 `audit.anchor-created.v1`, 07 `audit.verification-completed.v1`, 08 `audit.export-ready.v1`, 09 `audit.reconciliation-mismatch.v1`, 11 `audit.partition-archived.v1`, 12 `audit.cross-tenant-access.v1` |
| `ph13_obs.outbox` | EVT-13-01 `alert.fired.v1`, 02 `alert.resolved.v1`, 03 `alert.escalated.v1`, 04 `security-alert.raised.v1`, 10 `rule.changed.v1`, 13 `probe.failed.v1`, 14 `capacity.warning.v1` |

: Bảng outbox theo sự kiện

### 6.3. ClickHouse

ClickHouse (`dh-olap`, Z5) giữ siêu dữ liệu lượt gọi API 12 tháng và tổng hợp theo giờ 5 năm (FR-13-006, NFR-13-006, NFR-13-018; Q13-06 đã chốt ở SDD). Thiết kế dưới đây là đặc tả cho kỹ sư `dh-platform` và vận hành; chưa chạy thử vì runner không có ClickHouse, sẽ kiểm ở môi trường thử.

```sql
CREATE TABLE dh_obs.access_log ON CLUSTER dh_olap
(
  ts DateTime64(3, 'UTC'), tenant_id LowCardinality(String), route_id LowCardinality(String),
  api_code LowCardinality(String), system_code LowCardinality(String),
  method LowCardinality(String), path_template String,
  status UInt16, error_code LowCardinality(String),
  latency_ms UInt32, upstream_latency_ms UInt32, request_bytes UInt32, response_bytes UInt32,
  trace_id FixedString(32), client_ip String, synthetic UInt8
)
ENGINE = ReplicatedMergeTree
PARTITION BY toYYYYMM(ts)
ORDER BY (tenant_id, route_id, ts)
TTL toDateTime(ts) + INTERVAL 12 MONTH DELETE;
```

Bảng `access_log` nhận từ bảng động cơ Kafka của topic `{tenant}.obs.access.logged.v1` qua view vật chất hóa; một view khác tổng hợp theo giờ vào `access_log_hourly` (số lượt, lỗi theo lớp `2xx`…`5xx`, p50, p95, p99 độ trễ, theo `(tenant_id, route_id, system_code, api_code)`) với `TTL` 5 năm. Cô lập tenant: ClickHouse không có RLS theo phiên như PostgreSQL, nên mọi truy vấn đi qua `ClickHouseClient` trong `observability.internal.query` (luật R4 của SDD §3.6) và tài khoản truy vấn chịu `ROW POLICY … USING tenant_id = getSetting('SQL_dh_tenant')` với cài đặt tùy biến do cổng truy vấn đặt cho từng truy vấn; bộ kiểm thử rò rỉ T90, T91 kiểm lại hằng ngày (NFR-13-022). Bản ghi không khớp tiền tố topic bị bỏ và đếm (ERR-13-104).

### 6.4. Mimir, Loki, Tempo và Valkey

Ba kho quan sát cô lập bằng mã tổ chức `X-Scope-OrgID` bằng đúng tenant do cổng truy vấn đặt một nơi duy nhất (FR-13-009); PH-13 không tạo bảng PostgreSQL cho dữ liệu của chúng.

| Kho | Cô lập | Giữ | Ghi chú |
|---|---|---|---|
| Mimir (chỉ số) | OrgID = tenant | 90 ngày chi tiết, 25 tháng tổng hợp SLO | Tối đa `13.series.max-active` chuỗi (mặc định 250.000); luật ghi lại cho bảng điều khiển |
| Loki (log) | OrgID = tenant; log an ninh ở `{tenant}-security` | Log vận hành 90 ngày; log an ninh 12 tháng, 3 năm ở kho nén | Giả định log JSON; không giá trị Nhạy cảm (BR-13-011) |
| Tempo (vết) | OrgID = tenant | 14 ngày | Lấy mẫu theo đuôi (BR-13-010) |
| Valkey (đệm) | Khóa dựng bằng hàm tạo tên có tenant (SEC-82) | Ngắn hạn | Cửa sổ chống bão cảnh báo, đệm truy vấn; không là nguồn sự thật |

: Kho quan sát ngoài PostgreSQL

Bảng ánh xạ giữa bảng PostgreSQL và kho ngoài, để biết khi nào một dòng PostgreSQL chỉ là con trỏ: `audit_worm_batch`, `audit_anchor_publish`, `audit_signing_key`, `audit_export` trỏ WORM và kho tạm; `alert_rule.expr` được `RulePublisher` đẩy tới Ruler của Mimir (nguồn sự thật là bảng, `expr_hash` để đối soát); `dashboard_set` trỏ tổ chức Grafana; `probe_definition` chỉ định nghĩa, kết quả ở chỉ số.

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

Dữ liệu kiểm toán là bằng chứng nên có hai bản độc lập: bảng trong PostgreSQL và lô trong kho WORM; mỗi bản có đường khôi phục riêng và bản này kiểm chứng bản kia. Chương này nêu mô hình sao lưu, quy trình khôi phục chuỗi sau sự cố, mã hóa, thời hạn lưu và cách dọn, bảo trì.

### 7.1. Sao lưu và mục tiêu khôi phục

Hai schema nằm trên `pg-core`, chịu chính sách sao lưu chung của cụm (WAL liên tục và sao lưu đầy lưu ở bucket sao lưu chung của Ceph RGW, tách khỏi `dh-worm-audit`, Q341; DR hai site active–standby, ADR-034). PH-13 không đặt chính sách riêng ngoài mục tiêu của kiểm toán ở bảng dưới, vì NFR-13-011, 012 đã quy định.

| Dữ liệu | Cơ chế | Mục tiêu | Ghi chú |
|---|---|---|---|
| Bản ghi kiểm toán đã cam kết | Nút phụ đồng bộ cùng site (luật chuẩn `pg-no-sync-standby` cảnh báo khi mất) | 0 mất khi mất 1 nút (NFR-13-012) | Cam kết xong mới xác nhận offset Kafka |
| Bản ghi kiểm toán khi mất cả site | Bản sao DR bất đồng bộ cộng lô WORM 5 phút | RPO ≤ 5 phút (lô WORM gần nhất), RTO ≤ 4 giờ theo control plane (NFR-00-014) | Phần thiếu nạp lại từ WORM, phần chưa lên WORM nạp lại từ hộp thư đi và Kafka (mục 7.2) |
| Bản ghi chờ khi PH-13, PostgreSQL, OpenBao hoặc WORM ngừng | Hộp thư đi của DU, Kafka giữ 7 ngày | 0 mất khi ngừng tới 4 giờ (NFR-13-011) | Khử trùng theo `id` khi gửi lại |
| `ph13_obs` | Như `pg-core` | Theo mục tiêu control plane (D03-09) | Luật chuẩn, runbook chuẩn, bộ dashboard dựng lại được từ Git; cảnh báo và thao tác xử lý đã đóng không dựng lại được nên nằm trong sao lưu |
| Đối tượng WORM | Nhân bản của Ceph RGW giữa hai site, Object Lock | Theo D03-09 | Không dùng bản sao lưu PostgreSQL để khôi phục WORM, và ngược lại |

: Mục tiêu sao lưu và khôi phục

### 7.2. Khôi phục chuỗi kiểm toán sau sự cố mất dữ liệu

Khôi phục là đường ngoại lệ so với BR-13-033 (PH-13 không có chức năng nối lại chuỗi): đây là thủ tục của đội vận hành, có biên bản, không có màn hình hay API, và chỉ thêm lại các bản ghi vốn đã tồn tại và kiểm chứng được bằng neo. Trigger `tg_audit_chain_guard` vẫn áp dụng nên không thể dựng chuỗi sai.

1. Khôi phục PostgreSQL tới điểm gần nhất (PITR hoặc chuyển sang bản sao DR) và mở ở chế độ chỉ-đọc; chưa cho `ingest` ghi.
2. So `audit_chain.head_seq` và `head_hash` của từng tenant với lô WORM mới nhất (`audit_worm_batch` của bản khôi phục và danh sách đối tượng thực ở WORM) và với neo gần nhất.
3. Nếu bảng đứng sau WORM (mất tối đa khoảng 5 phút), công cụ `AuditRestore` chạy dưới vai trò di trú trong cửa sổ bảo trì: đọc lô từ WORM, kiểm băm lô và băm từng bản ghi, chèn nguyên văn (giữ `seq`, `recorded_at`, `prev_hash`, `hash`) theo thứ tự rồi nhích đầu chuỗi; `tg_audit_chain_guard` kiểm liền kề và nối đúng. Phân vùng của các tháng liên quan phải có sẵn (`p_ensure_month_partitions`).
4. Mở cho `ingest` ghi lại. Bản ghi chưa kịp lên WORM được DU gửi lại từ hộp thư đi hoặc Kafka (giữ 7 ngày); khử trùng theo `id` bỏ bản đã nạp từ WORM, bản còn lại nhận `seq` mới nối tiếp.
5. Chạy lượt xác minh `ON_DEMAND` toàn chuỗi cho từng tenant; chỉ khi đạt mới coi là xong. Bản ghi `AUDIT.CHAIN.RESTORE` (lý do, số tenant, khoảng `seq` nạp lại) được ghi vào chuỗi `PLATFORM` và gửi SIEM.
6. Biên bản ký bởi cán bộ ATTT và quản trị nền tảng, lưu ở `dh-evidence`.

Quy trình này chưa có FR, UC hay SDD nên được ghi ở mục đề nghị đồng bộ; thiết kế CSDL đã hỗ trợ (chèn nguyên văn qua đường kiểm liền kề) nhưng cần xác nhận quyền chạy `AuditRestore` dưới `ph13_owner` ở D04-02.

### 7.3. Mã hóa và bảo vệ dữ liệu

Bảng nêu từng lớp và nơi giữ khóa. Quy tắc chung: không khóa bí mật nào nằm trong PostgreSQL; bảng chỉ giữ khóa công khai, định danh khóa và đường dẫn OpenBao.

| Lớp | Biện pháp | Nguồn |
|---|---|---|
| Truyền | TLS 1.3; mTLS trong mesh, kể cả kết nối PostgreSQL và Kafka | NFR-13-023, SEC-15 |
| Lưu ở PostgreSQL | Mã hóa ổ đĩa ở lớp lưu trữ của `pg-core`; sao lưu và WAL mã hóa; WORM mã hóa phía máy chủ | D03-09, NFR-13-023 |
| Khóa ký neo và gói | `dh-audit-sign` (ECDSA P-256) ở OpenBao Transit, không xuất, xoay 12 tháng; bảng giữ khóa công khai mọi phiên bản | SDD §4.5, Q13-13 |
| Khóa HMAC số định danh | `dh-{tenant}-audit-hmac` ở Transit, không xuất; `object_key_hmac` chỉ chứa kết quả HMAC | BR-13-005 |
| Tài khoản CSDL | Cấp động bởi OpenBao, TTL 1 giờ; `ph13_archive` TTL 15 phút | SEC-33 |
| Bí mật kênh thông báo, SIEM | OpenBao KV; bảng giữ `secret_ref` dạng `kv/dh/…` (có `CHECK`) | SEC-47 |
| Giá trị Nhạy cảm | Che trước khi vào `before`, `after`, `reason`; `CHECK` chặn khóa bí mật mang giá trị chưa che; bản vi phạm vào `audit_quarantine` | BR-13-035, SEC-32 |
| Dữ liệu cá nhân còn lại | `actor_id`, `actor_name`, `source_ip`, `user_agent` cần cho kiểm toán (giữ ở mức tối thiểu); thư, SMS cảnh báo chỉ mang mã, mức, tóm tắt, liên kết; dữ liệu đẩy SIEM loại dữ liệu cá nhân | FR-00-062, BR-13-034 |
| Bản cách ly | `raw_payload` có thể chứa giá trị Nhạy cảm: không cấp cho `ph13_readonly`, giữ 90 ngày; mã hóa mức cột chờ Q13-53 | SDD §4.3 |

: Mã hóa và bảo vệ dữ liệu

### 7.4. Lưu giữ và dọn dữ liệu

Thời hạn lấy từ FRS §8.2. Dòng nào có hạn lưu thì có trigger `tg_guard_retention` chỉ cho `DELETE` khi đã quá hạn, nên tác vụ dọn không thể xóa nhầm dòng còn trong hạn dù có lỗi lập trình.

| Dữ liệu | Hạn lưu ở PostgreSQL | Cách dọn |
|---|---|---|
| `audit_event` | 12 tháng (tenant đặt 12 đến 24; phân vùng giữ theo giá trị lớn nhất) | Tách cả phân vùng bằng `p_archive_partition` khi đủ điều kiện; không `DELETE` từng dòng |
| `audit_chain`, `audit_anchor`, `audit_anchor_publish`, `audit_worm_batch`, `audit_signing_key`, `audit_partition`, `audit_source_grant` | Không xóa | Không có |
| `audit_verification`, `audit_export`, `audit_reconciliation` | 5 năm | Tác vụ dọn hằng ngày xóa dòng quá hạn (tệp gói bằng chứng đã xóa sau 7 ngày) |
| `audit_quarantine` | Tới `purge_after` (90 ngày, giả định) | Tác vụ dọn xóa dòng quá hạn |
| `alert`, `alert_action`, `alert_notification` | 2 năm kể từ khi đóng (`alert`), từ thao tác (`alert_action`), từ ngày tạo (`alert_notification`) | Xóa `alert` quá hạn kéo theo xóa `alert_action`, `alert_notification` (`ON DELETE CASCADE`) |
| `security_alert` | 3 năm sau khi đóng | Tác vụ dọn |
| `incident_report` | 5 năm | Tác vụ dọn |
| `pii_finding` | 12 tháng | Tác vụ dọn |
| `outbox` (hai schema) | 3 ngày | Tác vụ dọn sau khi bộ chuyển xác nhận |
| `saved_query` | Tới khi chủ sở hữu xóa | Xóa cứng bởi người dùng |
| Luật, runbook, kênh, lịch trực, SIEM, luật phát hiện, dashboard, kiểm tra tổng hợp, cấu hình tenant | Vĩnh viễn | Xóa mềm (`RETIRED`), mã không dùng lại (BR-13-031) |

: Lưu giữ và cách dọn dữ liệu PostgreSQL

### 7.5. Bảo trì

Các điểm bảo trì dưới đây là khuyến nghị cho đội vận hành cơ sở dữ liệu, rút ra từ đặc điểm ghi chỉ-thêm và phân vùng theo tháng của PH-13; giá trị tham số ghi ở đây là giả định ban đầu, hiệu chỉnh sau khi đo ở môi trường tải.

- `audit_chain` và `shedlock` cập nhật mỗi lô hoặc mỗi chu kỳ nên đặt `fillfactor = 70` và `autovacuum_vacuum_scale_factor = 0,02` để cập nhật nằm trong cùng trang (HOT); `alert`, `alert_notification` đặt `fillfactor = 80`. Các tham số này có trong DDL.
- Phân vùng đã `SEALED` không còn ghi: nên chạy `VACUUM (FREEZE)` một lần dưới vai trò di trú để không phải viết lại trang khi gần tràn số giao dịch; việc này không làm thay đổi dòng nào nên không kích hoạt UC-SEC-20 (`TamperProbe` chỉ đếm `n_tup_upd`, `n_tup_del`).
- Sau khi tạo phân vùng mới chạy `ANALYZE` bảng cha để bộ lập kế hoạch có thống kê của phân vùng đang ghi.
- `TamperProbe` đọc `pg_stat_user_tables` của từng phân vùng mỗi phút nên không đặt lệnh bảo trì nào làm tăng `n_tup_upd` hoặc `n_tup_del` trên `audit_event`; `pgaudit` ghi mọi DDL.
- Truy vấn kiểm toán nặng (khoảng trên 31 ngày) và `ph13_verify` chạy trên bản sao đọc với `statement_timeout = 30s` (ERR-13-015); độ trễ bản sao được cắt bằng `min(head của bản sao, seq neo)` ở lượt xác minh (SDD §4.7).

## 8. Ánh xạ dữ liệu hệ cũ sang thiết kế mới

Phần lớn chức năng giám sát của hệ cũ (Bus, Hub, APIM, PayGov) lưu số liệu ở Prometheus, bộ nhớ của agent hay tệp log chứ không ở bảng quan hệ, và được thay bằng LGTM (FR-13 nhóm A, D, E); phần duy nhất có bảng cần ánh xạ là nhật ký kiểm toán. Chương này liệt kê từng đối tượng dữ liệu hệ cũ có liên quan, quyết định chuyển hay không chuyển và lý do, làm đầu vào cho D06-01. Quy tắc xuyên suốt: không nối dữ liệu hệ cũ vào chuỗi băm mới, vì chuỗi mới có `tenant_id`, `source_ip`, `user_agent`, `trace_id` bắt buộc mà dữ liệu cũ không có, và vì chuỗi chỉ có giá trị chứng cứ khi mọi bản ghi do `dh-audit` sinh (Q13-09).

### 8.1. Theo mã chức năng hệ cũ

Bảng dưới trả lời, với từng chức năng giám sát và nhật ký của hệ cũ (`LGC-*`), dữ liệu cũ nằm ở đâu, sẽ được lưu ở đâu trong thiết kế mới và quyết định giữ, bỏ hay chuyển; chỗ kiểm kê hệ cũ chưa đủ thông tin được ghi thành giả định hoặc câu hỏi mở.

| LGC | Dữ liệu hệ cũ | Nơi lưu mới | Quyết định |
|---|---|---|---|
| LGC-APIM-027 | Bảng audit của APIM (thông tin tác động hệ thống; tên bảng và cột chưa có trong kiểm kê, GĐ-13-08) | Bản xuất tệp ở WORM, không vào `audit_event` | Xuất nguyên bản thành JSON Lines nén, băm SHA-256, ghi vào `dh-worm-audit` dưới `legacy/apim-audit/` kèm bảng kê băm; tra cứu bằng công cụ ngoại tuyến, không qua UI-13-13 (Q13-09) |
| LGC-APIM-022 | Log mọi request tới API của Application | ClickHouse `access_log` (mục 6.3) | Không chuyển: dữ liệu mới tự tích lũy 12 tháng; nếu cần xem lại thì giữ tệp log cũ ở kho nén của tỉnh |
| LGC-APIM-023; 024, 025, 026 | Danh sách gateway, chi tiết, CPU và Java heap, dashboard hoạt động | Mimir (chỉ số APISIX), `dashboard_set` (trạng thái bộ dashboard) | Không chuyển: số liệu tức thời; cấu hình dashboard khai báo lại bằng mã |
| LGC-BUS-007, 014, 015, 016, 017, 019, 027, 030, 038 | Histogram, trạng thái agent, bộ nhớ, CPU, route, endpoint, JMX, trace routing | Mimir, Tempo | Không chuyển: số liệu thời gian thực của hệ cũ |
| LGC-BUS-029, LGC-NFR-004 | Log agent, log có cấu trúc | Loki | Không chuyển; log mới theo JSON có `trace_id`, `tenant_id` |
| LGC-HUB-005, 006 | % bộ nhớ, % CPU theo giây | Mimir (chỉ số cụm Kafka) | Không chuyển; độ phân giải 15 giây (Q13-15) |
| LGC-PAY-009 | Thông báo lỗi kết nối nhà cung cấp thanh toán | `alert_rule` chuẩn `payment-provider-connection-error`, `alert` | Không chuyển; luật mới thay thông báo cũ |
| LGC-PAY-021 | Nhật ký giao dịch | `ph19_payment.integration_log` (PH-19) | PH-19 giữ dữ liệu; PH-13 chỉ tra qua API (FR-13-030) |
| LGC-NFR-005 | Sao lưu log mỗi tháng một lần | `audit_worm_batch` (lô 5 phút) | Thay bằng sao lô liên tục; không có dữ liệu để chuyển |

: Ánh xạ dữ liệu hệ cũ theo mã chức năng

### 8.2. Bảng của mã hiện tại (`apps/control`, W1)

Mã thử nghiệm hiện có một bảng liên quan: `ph01.application_audit` (changelog `004-c-onboarding-lifecycle.yaml`, đối tượng `AuditEntryDto`), ghi lịch sử chuyển trạng thái hồ sơ kết nạp, không chuỗi băm, không tenant (GAP-13-01 của SDD §2.4). Dữ liệu này là dữ liệu hệ thử nghiệm nên không chuyển vào chuỗi mới (Q13-09); `apps/control` chuyển sang gọi `dh-audit` từ bản phát hành đầu. Bảng dưới cho thấy các cột tương ứng, dùng khi cần đọc bản xuất cũ hoặc kiểm tra tính đầy đủ của dữ liệu mới.

| Cột cũ (`ph01.application_audit`) | Kiểu cũ | Cột mới (`audit_event`) | Chuyển đổi |
|---|---|---|---|
| `id` | `UUID` | `id` | Không dùng lại (UUID mới v7 do `dh-audit` sinh); giữ `id` cũ trong bản xuất |
| `application_id` | `UUID` | `object_id` (với `object_type = 'application'`) | Chuỗi |
| `action` | `VARCHAR(32)` | `action` | Đổi sang dạng `{MIỀN}.{HÀNH_ĐỘNG}`, ví dụ `ONBOARDING.SUBMIT` |
| `from_status`, `to_status` | `VARCHAR(32)` | `before`, `after` | `{"status": "…"}` ở mỗi vế |
| `actor` | `VARCHAR(128)` | `actor_id`, `actor_type` | `actor_type = 'USER'`; tác vụ tự động thành `SYSTEM` với `system:{du}` |
| `note` | `TEXT` | `reason` | Cắt còn 500 ký tự; đã che giá trị Nhạy cảm |
| `created_at` | `TIMESTAMPTZ` | `occurred_at` | Cùng kiểu; `recorded_at` do PH-13 gán |
| Không có | | `tenant_id`, `source_ip`, `user_agent`, `session_hash`, `trace_id`, `source_du`, `seq`, `prev_hash`, `hash` | Bắt buộc ở bảng mới, dữ liệu cũ không có nên là lý do chính không chuyển |

: Cột của application_audit và cột tương ứng ở audit_event

Cách lưu bản xuất: `\copy (SELECT row_to_json(a) FROM ph01.application_audit a ORDER BY created_at, id) TO 'application_audit.jsonl'`, nén `zstd`, băm SHA-256, ghi vào `dh-worm-audit` dưới `legacy/apps-control/` kèm bảng kê gồm số dòng và băm. Bảng cũ đổi tên thành `application_audit_legacy_w1` sau khi xuất (không xóa, để đối soát).

### 8.3. Ánh xạ DD-05 của từ điển dữ liệu

D02-07 định nghĩa DD-05 Bản ghi kiểm toán (chủ quản PH-13, thực thể EN-13-01). Bản ghi thiết kế ở đây mở rộng DD-05 theo FRS §4.7; bảng dưới là ánh xạ để D02-07 cập nhật (đề nghị đồng bộ ở chương 10).

| Trường DD-05 | Trường `audit_event` | Ghi chú |
|---|---|---|
| `audit_id` (`T-ID`) | `id` | UUID v7 do DU sinh |
| `trace_id` (`T-TRACE`) | `trace_id` | 32 ký tự thập lục |
| `actor` (`T-JSON`: `user_id` hoặc `client_id`, `system_id`, `source_ip`) | `actor_type`, `actor_id`, `actor_name`, `actor_home_tenant`, `source_ip`, `user_agent`, `session_hash`, `source_du` | Tách thành cột để lập chỉ mục và để băm chuẩn tắc ổn định |
| `action` (`READ`, `WRITE`, `APPROVE`, `EXPORT`…) | `action` | Dạng `{MIỀN}.{HÀNH_ĐỘNG}`, ví dụ `PII.REVEAL`; nhóm hành vi gốc suy từ hậu tố |
| `resource` (`VARCHAR(255)`) | `object_type`, `object_id` | Hai cột để tab "Lịch sử" truy vấn theo đối tượng |
| `subject_id` (`T-ID`, chủ thể dữ liệu) | `object_key_hmac` | Chỉ lưu HMAC theo khóa tenant, không lưu số định danh (BR-13-005) |
| `purpose` (`T-CODE`) | `purpose` | Giữ nguyên |
| `decision` (`PERMIT`, `DENY`) | `outcome` (`SUCCESS`, `DENIED`, `FAILED`) | `DENY` thành `DENIED`; thêm `FAILED` cho lỗi hệ thống |
| `fields_accessed` (`T-JSON`) | `after.fieldsAccessed` (hoặc `before`, `after` của thao tác) | Danh sách tên trường, không giá trị |
| `occurred_at` (`T-TS`) | `occurred_at` | Cùng nghĩa; thêm `recorded_at` do PH-13 gán |
| `integrity_anchor` (`T-HASH`) | `prev_hash`, `hash`, cộng `audit_anchor` | Một băm thành chuỗi hai băm cộng neo ký |

: Ánh xạ DD-05 sang audit_event

### 8.4. Chuyển đổi kiểu

Khi ánh xạ khái niệm nhật ký của hệ cũ sang bảng kiểm toán mới ở PostgreSQL, các kiểu dữ liệu đổi theo bảng dưới; mỗi dòng nêu kiểu cũ, kiểu mới và quy tắc chuyển để kỹ sư không phải đoán.

| Hệ cũ | Hệ mới | Quy tắc |
|---|---|---|
| `UUID` | `uuid` | UUID v7 cho dữ liệu mới; dữ liệu cũ không giữ làm khóa |
| `TIMESTAMPTZ` | `timestamptz` (`T-TS`) | Giữ nguyên; phân vùng tính theo múi giờ `Asia/Ho_Chi_Minh` |
| `VARCHAR(128)` người thao tác | `varchar(128)` `actor_id` | Giữ nguyên độ dài |
| `TEXT` ghi chú | `varchar(500)` `reason` | Cắt, ghi cờ cắt vào bản xuất |
| `JSON` tự do | `jsonb` đối tượng, tối đa 64 KB | Chỉ đối tượng; khóa bí mật chỉ mang `***` |
| Mã hành vi `READ`, `WRITE`… | `{MIỀN}.{HÀNH_ĐỘNG}` | Theo bảng hành động phải kiểm toán của FR-13-019, FR-00-040 |
| `PERMIT`, `DENY` | `SUCCESS`, `DENIED`, `FAILED` | Xem mục 8.3 |

: Chuyển đổi kiểu dữ liệu

### 8.5. Đối soát sau xuất bản cũ

Vì không nạp vào chuỗi mới nên đối soát chỉ gồm ba việc: (1) số dòng của tệp xuất bằng số dòng bảng nguồn; (2) băm SHA-256 của tệp tính lại sau khi đọc từ WORM bằng băm trong bảng kê; (3) bảng cũ đã đổi tên và chỉ đọc. Kết quả ký bởi cán bộ ATTT và lưu cùng bảng kê. Với APIM, việc xuất phụ thuộc xác nhận GĐ-13-08 (hệ cũ xuất được bảng audit ra tệp); chưa xác nhận thì ghi nhận là rủi ro di trú ở D06-01.

## 9. Câu hỏi mở

Các câu hỏi dưới đây chưa có trả lời chốt; thiết kế dùng giả định đã nêu trong từng câu cho tới khi có ý kiến. Dải Q13-50…54 theo D00-04 §3; câu hỏi của FRS (Q13-01…19), SDD (Q13-20…27) và use case (Q13-45…49) không lặp lại ở đây.

> **Câu hỏi mở Q13-50:** Ranh giới tháng của phân vùng `audit_event` tính theo múi giờ nào. Giả định: `Asia/Ho_Chi_Minh` (00:00 ngày 1 theo giờ Việt Nam) để tháng lưu trùng tháng người dùng thấy và trùng ngày đối chiếu của FR-13-017; hằng số nằm trong `p_ensure_month_partitions`. Nếu chốt UTC thì đổi hằng số cho phân vùng mới (phân vùng đã tạo giữ nguyên), kèm quy ước đường dẫn WORM `{yyyy}/{MM}/{dd}` và `audit_reconciliation.day` cùng múi giờ.

> **Câu hỏi mở Q13-51:** `ALTER TABLE … DETACH PARTITION … CONCURRENTLY` không chạy được trong hàm hay thủ tục, nên `p_archive_partition` dùng `DETACH PARTITION` thường (khóa ngắn mức cao nhất trên bảng cha `audit_event`, phân vùng cần tách đã `SEALED` nên không có ghi). SDD §4.8 viết `CONCURRENTLY`. Giả định: chấp nhận khóa ngắn, chạy ngoài giờ cao điểm (03:00). Nếu không chấp nhận, chuyển `ArchiveService` chạy lệnh ngoài giao dịch bằng vai trò có quyền chủ bảng, mất lợi thế "chỉ có thủ tục kiểm điều kiện mới tách được phân vùng" và phải kiểm điều kiện hoàn toàn ở ứng dụng.

> **Câu hỏi mở Q13-52:** Cảnh báo an ninh do `DetectionEngine` đẩy vào Alertmanager (`kind = security`) có quay về webhook của `dh-platform` và được ghi vào bảng `alert` không. Giả định: không; webhook bỏ qua `kind = security`, `security_alert` là kho duy nhất, và lượt thông báo cho cảnh báo an ninh ghi vào `alert_notification.security_alert_id` (lược đồ đã hỗ trợ). Nếu phải ghi cả hai thì `alert` cần cột phân loại `kind` và khóa ngoại `fk_alert_rule` chuyển sang `alert_rule` hoặc `detection_rule` tùy loại.

> **Câu hỏi mở Q13-53:** Thời hạn giữ và mức bảo vệ của `audit_quarantine.raw_payload`, vì bản cách ly do giá trị Nhạy cảm (ERR-13-105) chứa chính giá trị đó. Giả định: giữ 90 ngày rồi xóa, quyền cột không cấp cho vai trò báo cáo, chưa mã hóa mức cột. Cần quyết định có mã hóa cột bằng khóa tenant (khóa HMAC hay khóa mã hóa riêng ở OpenBao) và có cho DU nguồn tự xem bản cách ly của mình không, hay chỉ cán bộ ATTT.

> **Câu hỏi mở Q13-54:** Ánh xạ mức luật phát hiện của D03-07 §7.5 (NT nghiêm trọng, C cao, TB trung bình) sang ba mức của PH-13 (`CRITICAL`, `WARNING`, `INFO`). Giả định: NT thành `CRITICAL`; C và TB thành `WARNING` (cảnh báo an ninh mức Cao vẫn tới SO ngay trong ứng dụng nhưng chỉ gọi SMS khi `CRITICAL`). Nếu C phải gọi người trực thì cần thêm một mức hoặc nâng C lên `CRITICAL`, ảnh hưởng chuẩn BR-13-009 và định cỡ kênh trực.

## 10. Đề nghị đồng bộ cho tài liệu khác

Tập này không sửa tài liệu dùng chung và không tạo ADR; các thay đổi dưới đây do chủ tài liệu tương ứng cập nhật.

| Tài liệu | Đề nghị |
|---|---|
| D02-03-PH13 (FRS) §4.2 | Ghi 33 bảng cho 22 thực thể (11 bảng hỗ trợ nêu ở đầu chương 3); EN-13-02: `worm_object`, `siem_ack_at` chuyển sang `audit_anchor_publish`; EN-13-05: thêm `scope_hash`, `reauth_at`, `manifest_signature`, `key_version`, `download_count`; EN-13-14: thêm `impl`, `threshold_default`, `recipients`; EN-13-09: thêm `fingerprint`, `silence_reason`, `acknowledged_*`; EN-13-21: `tenant_id` luôn `PLATFORM`, thêm `archive_after`; mục 4.7: thêm `clock_skew`, `hash_version`; EN-13-10: thông báo cho cảnh báo an ninh qua `security_alert_id` |
| D02-03-PH13 (FRS) §6, D02-04-PH13 (UC) | Thêm chức năng hoặc use case "Khôi phục chuỗi kiểm toán sau sự cố" (mục 7.2) như đường ngoại lệ có biên bản của BR-13-033; giữ ý kiến SDD về FR-13-014 bước 1 (kiểm lại toàn bộ chuỗi trực tuyến mỗi ngày) |
| D03-02-PH13 (SDD) §4.4, §4.8 | Ghi trigger `tg_audit_chain_guard` và constraint trigger `tg_audit_event_covered` là hai lớp CSDL bổ sung cho `ChainWriter`; thay `DETACH … CONCURRENTLY` bằng thủ tục `p_archive_partition` (Q13-51); ghi `ph13_app` có `INSERT` (cột) trên `audit_chain` |
| D03-04-PH13 (API) | Enum, độ dài, mẫu của DTO khớp `CHECK` ở chương 3; ánh xạ lỗi theo mục 4.4; `If-Match` theo cột `version` |
| D02-07 (từ điển dữ liệu) | Cập nhật DD-05 theo bảng ánh xạ ở mục 8.3 (tách `actor`, `decision` thành `outcome`, thêm `object_key_hmac`, `prev_hash`, `hash`) |
| D03-10 (đa tenant) | Ghi PH-13 dùng mẫu P kể cả cho tenant `PLATFORM` (chuỗi riêng) và mẫu S cho dòng `PLATFORM` thay vì `COMMON` (`audit_signing_key`); nêu tầng "nhật ký kiểm toán" với chuỗi băm theo tenant |
| D03-09 (hạ tầng) | Định cỡ `pg-core` thêm khoảng 2,5 TB mỗi 12 tháng cho `ph13_audit` ở 34 tenant `QM-VUA` (giả định mục 1.5), tới 5 TB nếu có tenant giữ 24 tháng; WAL khoảng 120 KB/giây trung bình; xem xét cụm `pg-audit` riêng cho `ph13_audit` khi vượt ngưỡng (đề xuất ADR, chưa tạo); thống nhất khóa đối tượng WORM `audit/{tenant}/…` với tiền tố `{tenant}/` của bucket `dh-worm-audit` (mục 6.1); bản sao đọc cho `ph13_verify`; ClickHouse `access_log` (mục 6.3) |
| D03-07 (ATTT) | Bảng SEC: ghi `ck_audit_event_no_secret`, trigger chỉ-thêm và thủ tục lưu trữ là biện pháp kỹ thuật của SEC-32, SEC-61 đến SEC-67 ở mức CSDL; Q13-54 về ánh xạ mức NT, C, TB |
| D04-02 (quy trình kỹ thuật) | CI dựng PostgreSQL mới và chạy `ph13_audit.sql`, `ph13_obs.sql`, `ph13_isolation_test.sql`; Semgrep cấm `UPDATE`, `DELETE`, `TRUNCATE` trên `ph13_audit.audit_event`, `audit_anchor`; xác nhận quyền chạy `AuditRestore` (mục 7.2) |
| D05-02-PH13 (ca kiểm thử) | Dùng 171 khối của bài kiểm làm cơ sở nhóm ca cô lập tenant, bất biến nhật ký, tách nhiệm; thêm ca rò rỉ T90, T91 cho ClickHouse (chưa có ở bài kiểm PostgreSQL) |
| D00-04 (sổ tra cứu) | Dải Q13-50…54 đã dùng hết; ghi PH-13 dùng hai schema `ph13_audit`, `ph13_obs` (D00-04 §4 mô tả một schema mỗi phân hệ) |
| PH-18 | Thủ tục khôi phục chuỗi (mục 7.2) và xử lý bản cách ly (ERR-13-105) cần nằm trong sổ tay vận hành |
| PH-20 | Saga khởi tạo gọi `p_seed_tenant` trong phiên đã đặt đúng tenant; đóng tenant gọi đóng chuỗi (`status = CLOSED`) |

: Đề nghị đồng bộ cho tài liệu khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: hai schema `ph13_audit`, `ph13_obs` (33 bảng, 22 thực thể), chuỗi băm chỉ-thêm theo tenant, RLS, trigger bất biến, thủ tục lưu trữ phân vùng; DDL đã chạy thử trên PostgreSQL 16; bài kiểm cô lập và bất biến 171 khối đạt; đo thử tốc độ ghi chuỗi; kho ngoài PostgreSQL; sao lưu, khôi phục, ánh xạ dữ liệu hệ cũ; 5 câu hỏi mở Q13-50…54 |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà chéo bảy tập PH-13: thêm đoạn mở cho các mục 0.2, 0.5, 7.5, 8.1, 8.4 |


