# SRS-00 — Từ điển dữ liệu dùng chung toàn hệ thống

> **Loại tài liệu**: xuyên suốt (không phải phân hệ runtime).
> **Mục đích**: nơi duy nhất định nghĩa các **thực thể chia sẻ** và **trường chuẩn** xuất hiện ở nhiều phân hệ. Mọi SRS phân hệ khi dùng lại một khái niệm ở đây **phải tham chiếu tới mã trong tài liệu này thay vì định nghĩa lại**.
> **Quan hệ với `EN-{PH}-{nn}`**: `EN-{PH}-{nn}` là thực thể **thuộc sở hữu** của một phân hệ. `DD-{nn}` dưới đây là **khái niệm dùng chung** — hoặc là kiểu dữ liệu chuẩn, hoặc là thực thể có một phân hệ chủ quản và nhiều phân hệ tiêu thụ.
> Danh mục phân hệ → [README.md](README.md) · checklist → [CHECKLIST.md](CHECKLIST.md) · ma trận quyền → [SRS-19](SRS-19-rbac-matrix.md).

---

## Mục lục

1. [Nguyên tắc](#1-nguyên-tắc)
2. [Kiểu dữ liệu chuẩn](#2-kiểu-dữ-liệu-chuẩn)
3. [Trường ngữ cảnh bắt buộc](#3-trường-ngữ-cảnh-bắt-buộc)
4. [Thực thể chia sẻ `DD-01…12`](#4-thực-thể-chia-sẻ)
5. [Bảng chủ quản ↔ tiêu thụ](#5-bảng-chủ-quản--tiêu-thụ)
6. [Quy ước đặt tên](#6-quy-ước-đặt-tên)
7. [Bảng mã trạng thái dùng chung](#7-bảng-mã-trạng-thái-dùng-chung)
8. [Chính sách lưu giữ tổng hợp](#8-chính-sách-lưu-giữ-tổng-hợp)

---

## 1. Nguyên tắc

| # | Nguyên tắc | Hệ quả thực tiễn |
|---|---|---|
| **NT-1** | **Một khái niệm — một chủ quản.** Mỗi thực thể chia sẻ có đúng một phân hệ được quyền **ghi**; các phân hệ khác chỉ **đọc** qua API hoặc sự kiện. | Không có hai nguồn sự thật cho cùng một thực thể; xung đột dữ liệu chủ được ngăn từ thiết kế |
| **NT-2** | **Tham chiếu bằng định danh, không sao chép nội dung.** Phân hệ tiêu thụ lưu khóa ngoại (`system_id`, `service_id`…), không nhân bản toàn bộ bản ghi. | Khi chủ quản đổi dữ liệu, bên tiêu thụ không bị lệch; chỉ cache có TTL rõ ràng |
| **NT-3** | **Trường ngữ cảnh bắt buộc đi cùng mọi bản tin.** Xem [§3](#3-trường-ngữ-cảnh-bắt-buộc). | Truy vết đầu-cuối và ghi vết kiểm toán khả thi ở mọi chặng (CMP-28) |
| **NT-4** | **Kiểu dữ liệu lấy từ [§2](#2-kiểu-dữ-liệu-chuẩn), không tự định nghĩa.** | Ánh xạ giữa phân hệ không cần chuyển đổi kiểu; giảm lỗi biên |
| **NT-5** | **Dữ liệu cá nhân luôn mang nhãn phân loại** của `DD-11` trước khi rời phân hệ chủ quản. | PH-09 áp được chính sách ẩn danh/giả danh tự động (CMP-32) |

---

## 2. Kiểu dữ liệu chuẩn

| Mã | Kiểu | Định dạng | Ví dụ | Ghi chú |
|---|---|---|---|---|
| `T-ID` | `VARCHAR(36)` | UUID v4 | `9f1c…` | Khóa chính mặc định của mọi thực thể |
| `T-TRACE` | `VARCHAR(32)` | W3C Trace Context `trace-id` (32 hex) | `4bf92f3577b34da6a3ce929d0e0e4736` | Không dùng UUID có dấu gạch |
| `T-CODE` | `VARCHAR(64)` | `^[A-Z0-9_]{2,64}$` | `HE_THONG_MOT_CUA` | Mã nghiệp vụ do người đặt, bất biến sau khi phát hành |
| `T-TS` | `TIMESTAMPTZ` | RFC 3339, **luôn UTC**, độ chính xác mili giây | `2026-08-03T07:15:02.334Z` | Hiển thị theo `Asia/Ho_Chi_Minh`, lưu theo UTC |
| `T-VER` | `VARCHAR(16)` | SemVer `MAJOR.MINOR.PATCH` | `2.1.0` | Áp cho API, lược đồ, danh mục, mô hình AI |
| `T-JSON` | `JSONB` | JSON hợp lệ | — | Có chỉ mục GIN khi cần truy vấn theo khóa |
| `T-CCCD` | `VARCHAR(12)` | 12 chữ số | — | **Dữ liệu cá nhân** — bắt buộc nhãn `DD-11` |
| `T-MST` | `VARCHAR(14)` | 10 hoặc 13 chữ số có gạch | `0101243150-001` | Mã số thuế doanh nghiệp |
| `T-ORG` | `VARCHAR(20)` | Mã cơ quan theo danh mục QG | — | Tra từ `DD-06` |
| `T-MONEY` | `NUMERIC(18,2)` | VND, không ký hiệu | `1500000.00` | Không dùng kiểu dấu phẩy động |
| `T-ENUM` | `VARCHAR(32)` | `^[A-Z_]+$` | `ACTIVE` | Giá trị lấy từ [§7](#7-bảng-mã-trạng-thái-dùng-chung) |
| `T-HASH` | `CHAR(64)` | SHA-256 hex thường | — | Dùng cho neo toàn vẹn, `stackTraceHash` |

**Vì sao lưu UTC mà hiển thị giờ Việt Nam.** Bản tin đi qua nhiều phân hệ, nhiều pod, có thể nhiều vùng triển khai. Nếu mỗi nơi lưu giờ địa phương, việc dựng lại trình tự sự kiện khi truy vết sự cố sẽ sai lệch trong ngày chuyển đổi hoặc khi vùng khác múi giờ. Quy ước "lưu UTC — hiển thị địa phương" đặt việc quy đổi ở đúng một chỗ: lớp giao diện.

---

## 3. Trường ngữ cảnh bắt buộc

Mọi bản tin đi qua trục (đồng bộ hoặc bất đồng bộ) **phải** mang đủ các trường sau. Thiếu bất kỳ trường nào là lỗi cấu hình, không phải lỗi dữ liệu.

| Trường | Kiểu | Nguồn sinh | Bắt buộc | Mô tả |
|---|---|---|:-:|---|
| `traceId` | `T-TRACE` | PH-03 sinh; PH-04 lan truyền (`FR-04-023`) | ✓ | Định danh phiên xử lý đầu-cuối |
| `spanId` | `VARCHAR(16)` | Từng chặng tự sinh | ✓ | Định danh một chặng trong `traceId` |
| `correlationId` | `T-ID` | Bên gọi hoặc PH-04 khi tách/gộp | — | Gom nhóm các bản tin cùng một giao dịch nghiệp vụ |
| `clientId` | `T-CODE` | PH-12 cấp khi kết nạp | ✓ | Định danh ứng dụng gọi |
| `systemId` | `T-ID` | PH-01 cấp (`DD-01`) | ✓ | Hệ thống thành viên chủ quản lời gọi |
| `subjectId` | `T-ID` | Bên gọi | — | Đối tượng dữ liệu bị tra cứu; **bắt buộc** khi truy cập dữ liệu cá nhân |
| `purpose` | `T-CODE` | Bên gọi | ✓ khi có `subjectId` | Mục đích sử dụng dữ liệu — căn cứ kiểm tra tính hợp pháp |
| `privacyMode` | `T-ENUM` | PH-09 quyết định | ✓ khi có dữ liệu cá nhân | `RAW` · `PSEUDONYMIZED` · `ANONYMIZED` |
| `receivedAt` | `T-TS` | PH-03 | ✓ | Thời điểm tiếp nhận tại biên |
| `schemaId` | `T-CODE` | PH-10 Schema Registry | ✓ với bản tin sự kiện | Định danh lược đồ để giải mã |
| `eventType` | `T-CODE` | Bên phát | ✓ với bản tin sự kiện | Loại sự kiện nghiệp vụ |

**Ràng buộc kèm theo.** `subjectId` xuất hiện mà thiếu `purpose` → PH-04 từ chối bản tin và ghi vết; đây là điều kiện để PH-13 chứng minh mọi truy cập dữ liệu cá nhân đều có mục đích khai báo (CMP-23, CMP-28).

---

## 4. Thực thể chia sẻ

### DD-01 — HE_THONG_THANH_VIEN (Hệ thống thông tin thành viên)

**Chủ quản**: PH-01 (`EN-01-04`). **Tiêu thụ**: PH-02, PH-03, PH-04, PH-05, PH-12, PH-13, PH-14, PH-16, PH-18.

| Trường | Kiểu | Bắt buộc | Mô tả |
|---|---|:-:|---|
| `system_id` | `T-ID` | ✓ | Khóa chính |
| `system_code` | `T-CODE` | ✓ | Mã hệ thống, duy nhất toàn trục, bất biến |
| `system_name` | `VARCHAR(255)` | ✓ | Tên đầy đủ theo quyết định thành lập |
| `org_code` | `T-ORG` | ✓ | Cơ quan chủ quản → `DD-06` |
| `contact_owner` | `T-JSON` | ✓ | Đầu mối kỹ thuật + đầu mối nghiệp vụ (họ tên, chức vụ, điện thoại, thư điện tử) |
| `security_level` | `INT` | ✓ | Cấp độ an toàn 1–5 theo NĐ 85/2016 (CMP-18) |
| `status` | `T-ENUM` | ✓ | `DRAFT` · `PENDING` · `ACTIVE` · `SUSPENDED` · `TERMINATED` |
| `onboarded_at` | `T-TS` | — | Thời điểm bàn giao |

*Ràng buộc*: `system_code` không được sửa sau khi `status = ACTIVE` — mọi ghi vết lịch sử đều neo vào mã này.

### DD-02 — DICH_VU (Dịch vụ chia sẻ dữ liệu)

**Chủ quản**: PH-02 (`EN-02-01`). **Tiêu thụ**: PH-03, PH-04, PH-14, PH-15, PH-16.

| Trường | Kiểu | Bắt buộc | Mô tả |
|---|---|:-:|---|
| `service_id` | `T-ID` | ✓ | Khóa chính |
| `service_code` | `T-CODE` | ✓ | Mã dịch vụ, duy nhất |
| `provider_system_id` | `T-ID` | ✓ | Hệ thống cung cấp → `DD-01` |
| `version` | `T-VER` | ✓ | Phiên bản đang xét |
| `lifecycle_state` | `T-ENUM` | ✓ | `DESIGN` · `TEST` · `PUBLISHED` · `DEPRECATED` · `RETIRED` |
| `data_classification` | `T-ENUM` | ✓ | Mức nhạy cảm cao nhất mà dịch vụ trả về → `DD-11` |
| `sla_ref` | `T-ID` | — | Cam kết SLA → `EN-02-05` |

### DD-03 — NGUOI_DUNG (Danh tính người dùng)

**Chủ quản**: PH-12 (`EN-12-01`, đồng bộ từ Keycloak). **Tiêu thụ**: PH-01, PH-06, PH-09, PH-11, PH-13, PH-15, PH-17, PH-18, SRS-19.

| Trường | Kiểu | Bắt buộc | Mô tả |
|---|---|:-:|---|
| `user_id` | `T-ID` | ✓ | Khóa chính, khớp `sub` trong token OIDC |
| `username` | `VARCHAR(128)` | ✓ | Định danh đăng nhập |
| `org_code` | `T-ORG` | ✓ | Cơ quan công tác → `DD-06` |
| `roles` | `T-JSON` | ✓ | Mảng mã vai trò chuẩn → [SRS-19](SRS-19-rbac-matrix.md) |
| `status` | `T-ENUM` | ✓ | `ACTIVE` · `SUSPENDED` · `DISABLED` |

*Lưu ý*: **không** phân hệ nào ngoài PH-12 được lưu mật khẩu, khóa bí mật hay yếu tố xác thực. Các phân hệ khác chỉ lưu `user_id` làm khóa ngoại.

### DD-04 — VAI_TRO và QUYEN

**Chủ quản**: SRS-19 định nghĩa danh mục; PH-12 thực thi (`EN-12-03`). **Tiêu thụ**: mọi phân hệ có giao diện quản trị.

| Trường | Kiểu | Bắt buộc | Mô tả |
|---|---|:-:|---|
| `role_code` | `T-CODE` | ✓ | Mã vai trò chuẩn, ví dụ `INTEGRATION_REVIEWER` |
| `permission_code` | `T-CODE` | ✓ | Dạng `{PH}:{resource}:{action}`, ví dụ `PH04:route:approve` |
| `scope` | `T-ENUM` | ✓ | `GLOBAL` · `ORG` · `SYSTEM` — phạm vi áp dụng |

### DD-05 — BAN_GHI_KIEM_TOAN (Bản ghi kiểm toán)

**Chủ quản**: PH-13 (`EN-13-01`). **Tiêu thụ**: PH-09, PH-16, PH-17 (đọc để báo cáo).

| Trường | Kiểu | Bắt buộc | Mô tả |
|---|---|:-:|---|
| `audit_id` | `T-ID` | ✓ | Khóa chính |
| `trace_id` | `T-TRACE` | ✓ | Neo về phiên xử lý |
| `actor` | `T-JSON` | ✓ | `{ user_id | client_id, system_id, source_ip }` |
| `action` | `T-CODE` | ✓ | Hành vi: `READ` · `WRITE` · `APPROVE` · `EXPORT`… |
| `resource` | `VARCHAR(255)` | ✓ | Đối tượng bị tác động |
| `subject_id` | `T-ID` | — | Chủ thể dữ liệu, khi truy cập dữ liệu cá nhân |
| `purpose` | `T-CODE` | — | Mục đích khai báo |
| `decision` | `T-ENUM` | ✓ | `PERMIT` · `DENY` |
| `fields_accessed` | `T-JSON` | — | Danh sách trường đã trả về |
| `occurred_at` | `T-TS` | ✓ | Thời điểm xảy ra |
| `integrity_anchor` | `T-HASH` | ✓ | Băm chuỗi → `EN-13-02` |

*Bất biến (WORM)*: chỉ ghi thêm, không sửa, không xóa trước hạn lưu giữ.

### DD-06 — DANH_MUC_DUNG_CHUNG (Bảng mã dùng chung)

**Chủ quản**: PH-07 (`EN-07-01…03`). **Tiêu thụ**: mọi phân hệ.

| Trường | Kiểu | Bắt buộc | Mô tả |
|---|---|:-:|---|
| `catalog_code` | `T-CODE` | ✓ | Mã danh mục, ví dụ `DM_DON_VI_HANH_CHINH` |
| `version` | `T-VER` | ✓ | Phiên bản danh mục |
| `item_code` | `T-CODE` | ✓ | Mã mục trong danh mục |
| `item_name` | `VARCHAR(255)` | ✓ | Tên hiển thị |
| `parent_code` | `T-CODE` | — | Mã cha, cho danh mục phân cấp |
| `effective_from` / `effective_to` | `T-TS` | ✓ / — | Khoảng hiệu lực |
| `national_ref` | `T-CODE` | — | Mã tương ứng trong danh mục quốc gia (CMP-31) |

*Quy tắc*: bản ghi danh mục **không bị xóa** — hết hiệu lực thì đặt `effective_to`, giữ nguyên để dữ liệu lịch sử vẫn giải mã được.

### DD-07 — THUC_THE_VANG (Bản ghi vàng)

**Chủ quản**: PH-06 (`EN-06-01`). **Tiêu thụ**: PH-04, PH-08, PH-11, PH-14.

| Trường | Kiểu | Bắt buộc | Mô tả |
|---|---|:-:|---|
| `golden_id` | `T-ID` | ✓ | Khóa chính bản ghi vàng |
| `entity_type` | `T-ENUM` | ✓ | `CITIZEN` · `ENTERPRISE` · `ORG` · `LAND` … |
| `natural_key` | `T-JSON` | ✓ | Khóa tự nhiên đã chuẩn hóa (CCCD, MST…) — **dữ liệu cá nhân** |
| `source_links` | `T-JSON` | ✓ | Danh sách `{ system_id, source_record_id, confidence }` → `EN-06-03` |
| `survivorship_version` | `INT` | ✓ | Số hiệu lần hợp nhất gần nhất |

### DD-08 — VET_XU_LY_BAN_TIN (Message trace)

**Chủ quản**: PH-04 (`EN-04-06`). **Tiêu thụ**: PH-13, PH-18, PH-15.

| Trường | Kiểu | Bắt buộc | Mô tả |
|---|---|:-:|---|
| `trace_id` | `T-TRACE` | ✓ | Khóa tra cứu chính, có chỉ mục |
| `route_id` | `T-ID` | ✓ | Luồng xử lý → `EN-04-01` |
| `hop_seq` | `INT` | ✓ | Thứ tự chặng |
| `status` | `T-ENUM` | ✓ | `OK` · `RETRY` · `FAILED` · `SKIPPED` |
| `latency_ms` | `INT` | ✓ | Độ trễ chặng |
| `error_class` | `T-CODE` | — | Phân loại lỗi khi `status = FAILED` |

### DD-09 — BAN_TIN_LOI (DLQ message)

**Chủ quản**: PH-18 (`EN-18-01`). **Tiêu thụ**: PH-04 (phát lại), PH-13 (cảnh báo).

Trường bắt buộc tối thiểu — thống nhất với `FR-04-021`: `dlq_id`, `trace_id`, `route_id`, `original_payload`, `current_payload`, `error_class`, `error_message`, `stack_trace_hash` (`T-HASH`), `attempt_count`, `first_failed_at`, `last_failed_at`, `source_system` (→ `DD-01`), `target_system`, `error_category`, `replayable` (`BOOLEAN`).

### DD-10 — SU_KIEN_NGHIEP_VU (Bản tin sự kiện)

**Chủ quản**: PH-10 (`EN-10-01…02`). **Tiêu thụ**: PH-04, PH-05, PH-06, PH-11, PH-13.

Phong bì sự kiện chuẩn (CloudEvents-tương thích):

| Trường | Kiểu | Bắt buộc | Mô tả |
|---|---|:-:|---|
| `id` | `T-ID` | ✓ | Định danh sự kiện, dùng để khử trùng |
| `source` | `T-CODE` | ✓ | Hệ thống phát → `DD-01` |
| `type` | `T-CODE` | ✓ | Loại sự kiện, dạng `{miền}.{thực thể}.{hành vi}` |
| `time` | `T-TS` | ✓ | Thời điểm phát sinh nghiệp vụ (không phải thời điểm gửi) |
| `schema_id` | `T-CODE` | ✓ | Lược đồ để giải mã `data` |
| `trace_id` | `T-TRACE` | ✓ | Neo truy vết |
| `data` | `T-JSON` | ✓ | Tải nghiệp vụ |

*Ngữ nghĩa*: **ít nhất một lần** — mọi bên tiêu thụ bắt buộc xử lý idempotent theo `id` (`BR-04-008`).

### DD-11 — PHAN_LOAI_DU_LIEU (Nhãn phân loại)

**Chủ quản**: PH-09 (`EN-09-01`). **Tiêu thụ**: PH-02, PH-04, PH-06, PH-08, PH-13, PH-17.

| Giá trị `data_classification` | Nghĩa | Hệ quả xử lý |
|---|---|---|
| `PUBLIC` | Công khai | Không hạn chế |
| `INTERNAL` | Nội bộ cơ quan | Cần xác thực; không ra ngoài trục |
| `PERSONAL` | Dữ liệu cá nhân | Bắt buộc `subjectId` + `purpose`; ghi vết trường đã truy cập |
| `SENSITIVE_PERSONAL` | Dữ liệu cá nhân nhạy cảm | Như trên + bắt buộc `privacyMode ≠ RAW` khi ra khỏi phân hệ chủ quản |
| `RESTRICTED` | Hạn chế theo quy định riêng | Chỉ đi theo luồng được phê duyệt đích danh |

### DD-12 — THANH_PHAN_KIEN_TRUC (Architecture component)

**Chủ quản**: PH-16 (`EN-16-01`). **Tiêu thụ**: PH-15 (hiển thị), PH-13 (gắn chỉ số).

| Trường | Kiểu | Bắt buộc | Mô tả |
|---|---|:-:|---|
| `component_id` | `T-ID` | ✓ | Khóa chính |
| `component_code` | `T-CODE` | ✓ | Mã thành phần |
| `layer` | `T-ENUM` | ✓ | Lớp theo Khung TTQGS: `L1`…`L4` |
| `owner_org` | `T-ORG` | ✓ | Cơ quan chịu trách nhiệm |
| `nas_sync_state` | `T-ENUM` | ✓ | `NOT_SYNCED` · `SYNCED` · `FAILED` (CMP-33) |

---

## 5. Bảng chủ quản ↔ tiêu thụ

| Thực thể chia sẻ | Chủ quản (ghi) | Phân hệ tiêu thụ (đọc) | Cách truy cập |
|---|---|---|---|
| `DD-01` Hệ thống thành viên | PH-01 | 02, 03, 04, 05, 12, 13, 14, 16, 18 | API + sự kiện `system.member.*` |
| `DD-02` Dịch vụ | PH-02 | 03, 04, 14, 15, 16 | API + sự kiện `catalog.service.*` |
| `DD-03` Người dùng | PH-12 | 01, 06, 09, 11, 13, 15, 17, 18, SRS-19 | Token OIDC + API quản trị |
| `DD-04` Vai trò/quyền | SRS-19 (định nghĩa) · PH-12 (thực thi) | mọi PH có quản trị | Token claim + OPA |
| `DD-05` Bản ghi kiểm toán | PH-13 | 09, 16, 17 | API truy vấn (chỉ đọc) |
| `DD-06` Danh mục dùng chung | PH-07 | mọi PH | API + cache TTL ≤ 15 phút |
| `DD-07` Bản ghi vàng | PH-06 | 04, 08, 11, 14 | API tra cứu |
| `DD-08` Vết xử lý bản tin | PH-04 | 13, 15, 18 | API `/traces/{traceId}` |
| `DD-09` Bản tin lỗi | PH-18 | 04, 13 | API + chủ đề DLQ |
| `DD-10` Sự kiện nghiệp vụ | PH-10 | 04, 05, 06, 11, 13 | Kafka |
| `DD-11` Nhãn phân loại | PH-09 | 02, 04, 06, 08, 13, 17 | API + đi kèm bản tin |
| `DD-12` Thành phần kiến trúc | PH-16 | 13, 15 | API |

**Đọc bảng này thế nào.** Khi một SRS cần dữ liệu ở cột 1, nó **không** tạo bảng riêng mà gọi theo cột 4. Trường hợp bắt buộc phải cache (hiệu năng), SRS đó phải nêu rõ TTL và cách làm mới trong mục M4 của mình.

---

## 6. Quy ước đặt tên

| Đối tượng | Quy ước | Ví dụ |
|---|---|---|
| Bảng CSDL | `snake_case`, số ít, tiền tố phân hệ | `ph04_route`, `ph18_dlq_message` |
| Cột | `snake_case` | `created_at`, `system_id` |
| Trường JSON / API | `camelCase` | `traceId`, `systemId` |
| Chủ đề Kafka | `{miền}.{thực thể}.{phiên bản}` | `catalog.service.v1` |
| Đường dẫn API quản trị | `/api/admin/v{n}/{tài-nguyên}` | `/api/admin/v1/routes` |
| Đường dẫn API nghiệp vụ | `/api/v{n}/{miền}/{tài-nguyên}` | `/api/v1/dan-cu/cong-dan` |
| Mã lỗi | `{PH}-{nhóm}-{số}` | `PH04-VAL-001` |
| Nhãn chỉ số (metric) | `snake_case`, hậu tố đơn vị | `messages_received_total`, `route_latency_ms` |

**Vì sao CSDL dùng `snake_case` còn API dùng `camelCase`.** Hai lớp có hai cộng đồng quy ước khác nhau: PostgreSQL không phân biệt hoa thường nếu không trích dẫn, nên `snake_case` tránh lỗi tinh vi; còn JSON tiêu thụ chủ yếu bởi JavaScript/Java nên `camelCase` là mặc định. Ranh giới chuyển đổi đặt tại lớp ánh xạ của từng phân hệ — một chỗ duy nhất, không rải rác.

---

## 7. Bảng mã trạng thái dùng chung

| Nhóm | Giá trị | Dùng ở |
|---|---|---|
| **Vòng đời phát hành** | `DRAFT` → `PENDING` → `PUBLISHED` → `DEPRECATED` → `RETIRED` | `DD-02`, danh mục, lược đồ, mô hình AI |
| **Trạng thái vận hành** | `ACTIVE` · `SUSPENDED` · `TERMINATED` | `DD-01`, `DD-03`, route |
| **Kết quả xử lý** | `OK` · `RETRY` · `FAILED` · `SKIPPED` | `DD-08`, `DD-09`, job |
| **Quyết định truy cập** | `PERMIT` · `DENY` | `DD-05`, PH-12 |
| **Chế độ riêng tư** | `RAW` · `PSEUDONYMIZED` · `ANONYMIZED` | `DD-11`, PH-09 |
| **Kết quả phê duyệt** | `PENDING` · `APPROVED` · `REJECTED` · `WITHDRAWN` | PH-01, PH-04 duyệt route, PH-17 HITL |

*Quy tắc*: không phân hệ nào được đặt giá trị đồng nghĩa khác chữ (`INACTIVE` thay cho `SUSPENDED`, `SUCCESS` thay cho `OK`). Thêm giá trị mới phải cập nhật bảng này trước.

---

## 8. Chính sách lưu giữ tổng hợp

| Loại dữ liệu | Thời hạn tối thiểu | Căn cứ | Sau hạn |
|---|---|---|---|
| Bản ghi kiểm toán `DD-05` | **5 năm** | NĐ 47/2020, CMP-28 | Chuyển kho lạnh MinIO, giữ neo toàn vẹn |
| Vết xử lý bản tin `DD-08` | 90 ngày chi tiết · 13 tháng tổng hợp | Nhu cầu vận hành + KPI năm | Nén thành số liệu tổng hợp |
| Bản tin lỗi `DD-09` | 180 ngày | Thời hạn phát lại thực tế | Lưu trữ, xóa tải trọng gốc |
| Sự kiện Kafka `DD-10` | 7 ngày trên chủ đề · lưu trữ dài hạn tùy miền | Dung lượng cụm | Nén log/nén khóa theo chủ đề |
| Hồ sơ kết nạp `DD-01` | Vô thời hạn khi `ACTIVE`; 5 năm sau `TERMINATED` | Trách nhiệm pháp lý | Lưu trữ |
| Danh mục `DD-06` | Vô thời hạn | Dữ liệu lịch sử phải giải mã được | Không xóa |
| Dữ liệu cá nhân trong bản tin thử | 30 ngày | Nguyên tắc tối thiểu hóa | Xóa cứng |

**Nguyên tắc xung đột.** Khi một bản ghi thuộc nhiều dòng, áp **thời hạn dài nhất**. Khi hạn lưu giữ mâu thuẫn với yêu cầu xóa dữ liệu cá nhân, ưu tiên nghĩa vụ lưu vết kiểm toán nhưng chuyển trường cá nhân sang trạng thái giả danh hóa — giữ được chứng cứ truy vết mà không giữ danh tính.

---

## Liên kết

- Danh mục phân hệ & quy ước SRS → [README.md](README.md)
- Checklist tiến độ → [CHECKLIST.md](CHECKLIST.md)
- Ma trận phân quyền → [SRS-19-rbac-matrix.md](SRS-19-rbac-matrix.md)
- Ma trận truy vết tuân thủ CMP → [01-legal](../01-legal/README.md#3-ma-trận-truy-vết-tuân-thủ)
- Kiến trúc dữ liệu → [02-architecture §6](../02-architecture/README.md#6-kiến-trúc-dữ-liệu)
