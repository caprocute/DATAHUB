---
ma_tai_lieu: D03-03-PH14
ten: Thiết kế cơ sở dữ liệu phân hệ PH-14 Kết nối quốc gia
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư dh-integration, DBA, cán bộ ATTT, hội đồng thẩm định
phan_he: PH-14
mo_ta: Thiết kế cơ sở dữ liệu của phân hệ Kết nối quốc gia gồm 36 bảng trong schema ph14_national, ràng buộc bốn mắt và bất biến, RLS theo tenant, DDL đã chạy thử với 85 khối kiểm, kho ngoài PostgreSQL, lưu giữ, sao lưu và ánh xạ dữ liệu hệ cũ.
tai_lieu_lien_quan: D02-03-PH14 FRS; D02-04-PH14 Use case; D03-02-PH14 SDD; D03-04-PH14 API; D03-10 Đa tenant; D02-07 Từ điển dữ liệu
---

# D03-03-PH14 · Thiết kế CSDL Kết nối quốc gia

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu thiết kế nơi PH-14 lưu dữ liệu quản trị của kết nối tới các nền tảng quốc gia: danh mục nền tảng và dịch vụ quốc gia, đặc tả có phiên bản, luật định tuyến, chứng thư số và chuỗi tin cậy, hạn mức, điểm cuối chiều vào, sổ giao dịch dùng đối soát với trung ương, nhật ký khai thác và cảnh báo bất thường. Mục tiêu là để mọi quy tắc "không được phép sai" của PH-14 (không lưu bí mật, bốn mắt, bất biến, cô lập tenant) bị khóa ngay ở CSDL, không chỉ ở dịch vụ.

**Phạm vi.** Schema `ph14_national` trên cụm `pg-core` có 36 bảng, trong đó 6 bảng khối lượng lớn phân vùng theo tháng, cho 15 thực thể EN-14-01…15 của [D02-03-PH14](../../02-yeu-cau/frs/D02-03-PH14-frs-ket-noi-quoc-gia.md) §4.2 và các bảng hỗ trợ của [D03-02-PH14](../sdd/D03-02-PH14-sdd-ket-noi-quoc-gia.md). Mặt phẳng dữ liệu `national-gateway` của `dh-runtime` không kết nối schema này: cổng ghi bền qua Kafka, `dh-integration` ghi lại. Bộ đếm hạn mức, đệm phản hồi nằm ở Valkey; nội dung bản tin mã hóa nằm ở Ceph RGW.

**Căn cứ pháp lý.** CMP-LAW-03 và CMP-LAW-19 (Nghị định 278/2025/NĐ-CP) về kết nối, chia sẻ dữ liệu quốc gia và nghĩa vụ đối soát; CMP-LAW-05 (Luật BVDLCN 91/2025) về mục đích khai thác, tối thiểu hóa, thời hạn lưu nội dung; CMP-LAW-06 và CMP-LAW-08 (Nghị định 331/2026, TCVN 14423:2026) về quản lý bí mật, chứng thư, nhật ký; CMP-LAW-16 (Luật An ninh mạng 116/2025). Quyết định kiến trúc nền: ADR-003 (PostgreSQL và RLS), ADR-046 (bốn mắt dùng chung), ADR-047 (phân vùng theo tháng), ADR-057 (đồng bộ quốc gia qua PH-14).

**Những điểm hội đồng cần lưu ý.**

1. **Không có bí mật, khóa riêng, nội dung bản tin hay định danh thô trong CSDL.** Chứng thư chỉ lưu chuỗi công khai và `keyRef` tới OpenBao `transit` của đúng tenant; ràng buộc `CHECK` chặn khối `PRIVATE KEY` và khóa bí mật trong tham số lệnh, sự kiện, sự cố; đối tượng được tra cứu chỉ còn dạng `lookup_key_hash` (HMAC theo khóa tenant) để phát hiện tra hàng loạt (BR-14-004, BR-14-005, BR-14-021).
2. **Sổ giao dịch là bằng chứng đối soát nên chỉ tiến, không xóa.** `national_transaction` phân vùng theo tháng, mỗi dòng gắn mã đối soát, HTTT, mục đích, mã hồ sơ, kết quả ký và xác minh; trigger chỉ cho chuyển trạng thái tiến, cấm xóa dòng; 12 tháng trực tuyến rồi xuất kho WORM 5 năm (BR-14-020, SEC-62).
3. **Bốn mắt và tách nhiệm được khóa ở CSDL.** Bảy loại đối tượng (nền tảng, chứng thư, neo tin cậy, luật định tuyến, hạn mức môi trường thật, điểm cuối chiều vào, yêu cầu duyệt chung) có `CHECK` người duyệt khác người đề nghị; chứng thư và đặc tả đã kích hoạt bất biến; mỗi nền tảng chỉ một chứng thư ký hiện hành (BR-14-017, BR-14-018, BR-14-022).
4. **Cô lập tenant bằng `FORCE ROW LEVEL SECURITY` trên 35 bảng nghiệp vụ.** Nền tảng, dịch vụ, đặc tả của tenant `COMMON` đọc được ở mọi tỉnh nhưng chỉ phiên `PLATFORM` ghi; khóa ngoại luôn kèm `tenant_id`; bài kiểm [ph14_isolation_test.sql](ph14/test/ph14_isolation_test.sql) đạt 85 khối (§4.2).
5. **Thiết kế dựa trên giả định có ghi cơ sở.** Đặc tả NDXP hiện hành chưa xác minh (Q14-01) nên mọi giá trị đặc thù (mã dịch vụ, cách xác thực, hạn mức) là dữ liệu cấu hình theo tenant, không nằm trong cấu trúc bảng; dung lượng tính theo hồ sơ "tỉnh vừa" (GĐ-14-03); 5 câu hỏi mở ở chương 9.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Bảng | 36 (35 bảng nghiệp vụ có RLS, 1 bảng kỹ thuật `shedlock`); 6 bảng phân vùng theo tháng |
| Cột, khóa, chỉ mục | 662 cột; 36 khóa chính, 33 ràng buộc duy nhất và 13 chỉ mục duy nhất từng phần, 20 khóa ngoại kèm tenant, 53 chỉ mục thường |
| Ràng buộc nghiệp vụ | 276 ràng buộc `CHECK`, 18 trigger bảo vệ (bất biến, chỉ tiến, tổng phân bổ, điều kiện bật) |
| Tệp DDL | 6 tệp `ph14_*.sql`, 47 changeset, 1.919 dòng; đã chạy trên PostgreSQL 16 sạch |
| Kiểm thử | 85 khối kiểm đạt (cô lập tenant, bốn mắt, bí mật, bất biến, quyền vai trò) |
| Dung lượng giả định | Khoảng 62 GB mỗi tenant "tỉnh vừa" ở mức lưu giữ tối đa, gần 97% là sổ giao dịch (§7.3) |

: Con số chính của thiết kế CSDL PH-14

## 0. Giới thiệu

### 0.1. Mục đích

Tài liệu đặc tả lược đồ dữ liệu của PH-14 để kỹ sư `dh-integration` viết mã truy cập, DBA vận hành, cán bộ ATTT thẩm tra và hội đồng thẩm định đánh giá. Mỗi bảng có mục đích, khóa, ràng buộc, chỉ mục, cách ly tenant, phân vùng, lưu giữ; mỗi quy tắc nghiệp vụ được chốt ở CSDL nêu rõ quy tắc `BR-14-*` và mã lỗi `ERR-14-*` tương ứng.

### 0.2. Phạm vi

Gồm 36 bảng của schema `ph14_national`, vai trò và quyền, DDL và changelog, dữ liệu khởi tạo, các kho ngoài PostgreSQL mà thiết kế dựa vào (Valkey, Kafka, Ceph RGW, OpenBao), sao lưu, khôi phục, lưu giữ, ánh xạ dữ liệu hệ cũ. Không gồm: giá trị tham số `14.*` (lưu ở PH-18), kết nối và bí mật (PH-05, OpenBao), hợp đồng API (D03-04-PH14), thiết kế mã (D03-02-PH14).

### 0.3. Người đọc

Mỗi nhóm người đọc cần một phần khác nhau của tài liệu; bảng dưới chỉ ra phần nên đọc trước.

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-integration` (module `national`) | Chương 1, 3, 4, 6 |
| DBA, vận hành `pg-core` | Chương 1, 4, 7 |
| Cán bộ ATTT | Chương 1.2, 1.4, 3 (bảng chứng thư, sự cố, sổ giao dịch), 7 |
| Kiểm thử viên | Chương 1.4, 1.5, 4.2 (đầu vào cho D05-02-PH14) |
| Hội đồng thẩm định | Tóm tắt, chương 2, 8, 9 |

: Người đọc và phần cần đọc

### 0.4. Thuật ngữ và chữ viết tắt

Các thuật ngữ dưới đây xuất hiện nhiều lần ở các chương sau; thuật ngữ nghiệp vụ dùng chung theo D02-03-PH14 §1.4 và D00-01.

| Thuật ngữ | Giải thích |
|---|---|
| RLS (Row Level Security) | Cơ chế của PostgreSQL lọc dòng theo chính sách; `FORCE` áp dụng cả với chủ sở hữu bảng |
| Mẫu P, mẫu S | Hai mẫu chính sách RLS của D03-10: P chỉ dòng của tenant phiên; S đọc thêm dòng `COMMON` |
| `COMMON`, `PLATFORM` | `COMMON` là tenant toàn quốc; `PLATFORM` là giá trị `app.tenant_id` của phiên quản trị nền tảng, được ghi dòng `COMMON` |
| NDXP, NDOP | Nền tảng trao đổi dữ liệu quốc gia (trước đây NGSP); Nền tảng dữ liệu mở quốc gia |
| HTTT | Hệ thống thông tin của tỉnh gọi dịch vụ quốc gia qua PH-14 |
| DLCN | Dữ liệu cá nhân |
| `keyRef` | Tham chiếu tới khóa trong OpenBao `transit`; không phải khóa |
| CRL | Danh sách thu hồi chứng thư |
| WORM | Lưu một lần, đọc nhiều lần, không sửa, không xóa; dùng cho sổ giao dịch quá 12 tháng |
| UPSERT theo hạng | `INSERT … ON CONFLICT DO UPDATE … WHERE` chỉ cập nhật khi trạng thái mới có hạng cao hơn |
| Outbox | Bảng ghi sự kiện cùng giao dịch với thay đổi miền, rồi phát lên Kafka (DD-11) |
| ULID | Định danh 26 ký tự có thứ tự thời gian, dùng làm `Idempotency-Key` |

: Thuật ngữ và chữ viết tắt

### 0.5. Tài liệu tham chiếu

[D02-03-PH14](../../02-yeu-cau/frs/D02-03-PH14-frs-ket-noi-quoc-gia.md) (FRS, thực thể §4.2, quy tắc §7, tham số §8.2, giả định §12.2); [D02-04-PH14](../../02-yeu-cau/use-case/D02-04-PH14-use-case-ket-noi-quoc-gia.md) (use case); [D03-02-PH14](../sdd/D03-02-PH14-sdd-ket-noi-quoc-gia.md) (SDD, mô hình miền §4.1, nhất quán §8); [D03-01](../D03-01-sad.md) §4 (đơn vị triển khai, vùng mạng); [D03-10](../D03-10-thiet-ke-da-tenant.md) (mẫu RLS P và S); D00-01 §5 (kiểu dữ liệu chuẩn, trường ngữ cảnh); ADR-003, 031, 032, 035, 042, 046, 047, 057 (thư mục `00-chung/adr`); D03-07 (SEC-60, 62, 80, 82, 87, 88); D03-09 (sao lưu, DR).

### 0.6. Cấu trúc tài liệu

Tài liệu đi từ chiến lược chung xuống từng bảng, rồi sang các kho ngoài, lưu giữ và hệ cũ; bảng dưới là mục lục theo chương.

| Chương | Nội dung |
|---|---|
| 1 | Chiến lược lưu trữ: schema, vai trò, cách ly tenant, quy ước, quy tắc chốt ở CSDL, chuyển lỗi sang `ERR-14-*`, dung lượng |
| 2 | Sơ đồ thực thể và quan hệ (bốn hình theo nhóm) |
| 3 | Đặc tả 36 bảng: danh sách, khối 10 mục và danh sách cột từng bảng; truy vấn chính |
| 4 | DDL, changelog Liquibase, kết quả chạy thử |
| 5 | Dữ liệu khởi tạo |
| 6 | Kho ngoài PostgreSQL: Valkey, Kafka, Ceph RGW, OpenBao |
| 7 | Sao lưu, khôi phục, mã hóa, lưu giữ, dung lượng |
| 8 | Ánh xạ hệ cũ sang thiết kế mới |
| 9 | Câu hỏi mở |
| Cuối | Đề nghị đồng bộ cho tài liệu dùng chung; lịch sử phiên bản |

: Cấu trúc tài liệu

## 1. Chiến lược lưu trữ

### 1.1. Schema, vai trò và kết nối

Schema `ph14_national` (quy ước `ph{nn}_{miền}`) do `ph14_owner` (`NOLOGIN`) sở hữu, nằm trên cụm `pg-core` ở vùng nền tảng Z5 cùng các schema `ph04`, `ph05`, `ph07`. Module `national` của `dh-integration` kết nối bằng `dh_integration_app`, thành viên `ph14_app` (chỉ DML, không `BYPASSRLS`); Liquibase chạy bằng `dh_integration_migrator`, thành viên `ph14_owner`; báo cáo và kiểm toán đọc bằng `ph14_readonly`. Các module cùng đơn vị triển khai chỉ đọc ghi schema của mình: PH-14 lấy thông tin kết nối qua `AdapterReferenceApi` của module `adapter` (PH-05), không truy vấn `ph05_adapter`.

| Vai trò | Đăng nhập | Quyền | Hạn chế đáng chú ý |
|---|---|---|---|
| `ph14_owner` | Không | Sở hữu schema, bảng, hàm; tháo và xóa phân vùng quá hạn | Chỉ dùng cho migrator và thủ tục `SECURITY DEFINER` |
| `ph14_app` | Qua `dh_integration_app` | `SELECT`, `INSERT`, `UPDATE`, `DELETE` trên bảng cha | Không `DELETE` sổ giao dịch, chứng thư, neo tin cậy, sự cố chữ ký, cảnh báo, yêu cầu duyệt; không `UPDATE` `outbox`; không quyền trên phân vùng |
| `ph14_readonly` | Qua `dh_report_ro` | `SELECT` | Không đọc `national_transaction.lookup_key_hash` và `service_spec.content` (quyền theo cột); chịu RLS như vai trò khác |

: Vai trò và quyền của schema ph14_national

`dh-runtime` (hồ sơ `national-gateway`, hai vai trò `gateway` và `worker`) **không** kết nối schema này (SDD §2.1). Cổng nhận cấu hình bằng ảnh chụp có phiên bản (nguồn là `config_revision` và các bảng danh mục), ghi bản ghi giao dịch, mức dùng, thống kê đệm qua Kafka (EVT-14-11 và chủ đề `quota.usage`), và `dh-integration` tiêu thụ rồi ghi vào đây. Debezium của `pg-core` chỉ đọc WAL của bảng `outbox` qua vai trò sao chép do nền tảng quản; Kafka Connect không có quyền trên các bảng còn lại.

Thủ tục `p_ensure_month_partitions` được khai báo `SECURITY DEFINER` (chạy với quyền `ph14_owner`, `search_path` cố định) để `PartitionMaintenanceJob` chạy bằng `ph14_app` vẫn tạo được phân vùng mới mà không cần cấp quyền tạo bảng; thủ tục `p_enable_rls` không cấp cho ai ngoài chủ sở hữu. Quyền được cấp trên bảng cha, không cấp trên phân vùng, nên không ai đọc thẳng phân vùng để vòng qua quyền theo cột; truy vấn qua bảng cha vẫn chịu RLS.

### 1.2. Cách ly tenant

Mọi bảng nghiệp vụ có `tenant_id varchar(16)` (T-TENANT) và bật `FORCE ROW LEVEL SECURITY` qua `ph14_national.p_enable_rls(bảng, mẫu)`, theo hai mẫu của [D03-10](../D03-10-thiet-ke-da-tenant.md) như PH-04, PH-05.

| Mẫu | Đọc | Ghi | Bảng |
|---|---|---|---|
| P (riêng) | Dòng có `tenant_id` bằng tenant của phiên; dòng `COMMON` chỉ khi phiên là `PLATFORM` | Cùng điều kiện đọc | 32 bảng tác nghiệp |
| S (dùng chung) | Dòng của tenant phiên và dòng `COMMON` | Dòng của tenant phiên (tỉnh); dòng `COMMON` chỉ khi phiên là `PLATFORM` | `national_platform`, `national_service`, `service_spec` |

: Cách ly tenant

Ba bảng mẫu S bảo đảm BR-14-029: dịch vụ và nền tảng `COMMON` (kết nối `NDXP_DMDC` của danh mục dùng chung, ADR-057) đọc được ở mọi tỉnh nhưng chỉ quản trị nền tảng sửa. Mười tám bảng mẫu P còn lại cho phép dòng `COMMON` (chứng thư, hạn mức, sổ giao dịch của cổng `COMMON`…) nhưng dòng đó chỉ phiên `PLATFORM` thấy; 14 bảng mẫu P chỉ nhận tenant tỉnh `T{nn}` (đồng bộ, chiều vào, bất đồng bộ, cảnh báo, chạy song song, nhập hệ cũ, luật định tuyến). `CHECK` `ck_*_tenant` ở mỗi bảng bảo đảm dạng mã.

Biến phiên `app.tenant_id` được đặt đầu mỗi giao dịch bằng `TenantAwareTransactionManager` (`SET LOCAL`) từ token đã xác minh; thiếu biến thì truy vấn báo lỗi, biến rỗng thì không thấy dòng nào (trừ dòng `COMMON` của bảng mẫu S). Tác vụ nền liên tenant (`CertificateExpiryJob`, `HealthRollupJob`, `AnomalyDetector`) lặp từng tenant; `LedgerConsumer` gom lô theo tenant của bản ghi và đặt biến phiên cho từng nhóm (dòng `COMMON` đặt `PLATFORM`, xem Q14-53). `shedlock` là bảng kỹ thuật không có `tenant_id` nên không bật RLS.

Mọi khóa ngoại là khóa kép `(x_id, tenant_id)` nên một dòng không thể trỏ sang dòng của tenant khác. Một số liên kết cố ý theo **mã**, không có khóa ngoại, vì khác schema hoặc khác đơn vị sở hữu, hoặc vì bảng khối lượng lớn phân vùng theo tháng.

| Liên kết theo mã | Cột | Lý do không dùng khóa ngoại | Nơi kiểm |
|---|---|---|---|
| Kết nối PH-05 | `national_platform.connection_code` | Khác schema; tenant `COMMON` dùng kết nối `COMMON` | `AdapterReferenceApi`, ERR-14-005 |
| Dịch vụ trong luật, hạn mức, giao dịch | `routing_rule.*_service_code`, `quota_policy.service_code`, `async_request.service_code`, `national_transaction.service_code` | Có thể là dịch vụ `COMMON`; bảng giao dịch khối lượng lớn, phân vùng | Dịch vụ quản trị, ERR-14-014 |
| HTTT PH-01 | `system_code` ở hạn mức, giao dịch, cảnh báo | Khác schema | Bản sao danh mục HTTT của PH-01 (đăng ký sử dụng dịch vụ) |
| Luồng PH-04 | `inbound_route.flow_code` | Khác schema | ERR-14-039 |
| API PH-02 | `service_exposure.api_code` | Khác schema; điền khi PH-02 phát sự kiện đã công bố | FR-14-009 |
| Nền tảng của bảng phân vùng | `quota_usage.platform_id`, `health_sample.platform_id` | Phân vùng tháng tháo gọn, không giữ ràng buộc | Dịch vụ ghi |

: Liên kết theo mã không có khóa ngoại

### 1.3. Quy ước bảng

Theo D00-01 §5.1 mọi bảng có `id uuid` (UUID v7 sinh ở ứng dụng), `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (trigger `tg_touch` cập nhật `updated_at`, tăng `version` cho ETag). Ngoại lệ có chủ đích:

| Bảng | Ngoại lệ | Lý do |
|---|---|---|
| `national_transaction` | Khóa `(tenant_id, transaction_code, started_at)`, không có `id`, `version`, cột người tạo, sửa; chỉ UPSERT tiến | Sổ đối soát; mã giao dịch là khóa tự nhiên; phân vùng tháng |
| `quota_usage`, `cache_stats`, `usage_hourly`, `health_sample`, `parallel_sample` | Khóa tự nhiên, không có `id` và cột kiểm toán | Dữ liệu đo do cổng sinh, ghi lũy đẳng theo khóa; phân vùng tháng |
| `health_state` | Khóa `(tenant_id, platform_id, env)`, không có `id`, `version` | Một dòng hiện hành cho mỗi nền tảng và môi trường |
| `sync_record`, `platform_outage` | Không có `created_by`, `updated_*` (`platform_outage` còn không có `version`) | Bản ghi do `worker` sinh qua Kafka |
| `outbox` | Khóa `event_id`, chỉ có `occurred_at` | DD-11 |
| `shedlock` | Bảng của thư viện ShedLock | Bảng kỹ thuật |

: Ngoại lệ so với trường ngữ cảnh bắt buộc

Kiểu dữ liệu theo D00-01 §5 với các điều chỉnh sau, đều có lý do:

| Chuẩn | Dùng ở PH-14 | Lý do |
|---|---|---|
| `T-CODE` `varchar(64)` chữ hoa | Mã bất biến `varchar(63)` chữ thường, mẫu `^[a-z][a-z0-9-]{2,62}$` (`code`, `platform`, `service`, `certificate`…) | FRS §6 đặt mã chữ thường vì dùng trong đường dẫn, khóa Valkey, tên topic; cùng cách của PH-05 |
| `T-ENUM` `varchar(32)` + `CHECK` | `varchar(n)` với n vừa đủ giá trị dài nhất + `CHECK … IN (…)` | Tiết kiệm chỉ mục; thêm giá trị là một changeset mới |
| `T-SECRET-REF` | `national_certificate.key_ref varchar(255)` | `CHECK` ép dạng `transit/keys/dh-{tenant}-…` |
| `T-TRACE` | `char(32)` ở `trace_id`; kiểm mẫu 32 ký tự hexa | Theo chuẩn |
| `T-TS` | `timestamptz` mọi cột thời điểm | Theo chuẩn |
| (không có) | `limit_count` thay vì `limit` | `limit` là từ khóa SQL |

: Điều chỉnh kiểu dữ liệu

Khóa duy nhất của giao dịch phải chứa cột phân vùng (`started_at`) nên mã giao dịch chỉ duy nhất trong cùng `started_at`. Cổng gắn `started_at` vào bản ghi đầu của giao dịch và giữ nguyên ở mọi bản ghi sau, nhờ đó UPSERT không nhân đôi; khác với PH-19, PH-14 không có bảng chỉ mục mã giao dịch không phân vùng (Q14-50).

### 1.4. Quy tắc nghiệp vụ chốt ở CSDL

Bảng dưới liệt kê các ràng buộc và trigger giữ quy tắc ở CSDL như lớp phòng thủ thứ hai, sau `FourEyesGuard` và dịch vụ. Tên ràng buộc theo mẫu `ck_{bảng}_{ý}`, `uq_{bảng}_{ý}`, `tg_{bảng}_{ý}`; toàn bộ danh sách ở khối 10 mục của từng bảng (chương 3).

| Ràng buộc hoặc trigger | Quy tắc | BR, FR, ERR |
|---|---|---|
| `ck_national_platform_four_eyes`, `ck_national_certificate_four_eyes`, `ck_trust_anchor_four_eyes`, `ck_routing_rule_four_eyes`, `ck_quota_policy_four_eyes`, `ck_inbound_endpoint_four_eyes` | Người duyệt khác người đề nghị; hạn mức chỉ bắt buộc ở môi trường `PROD` | BR-14-022, ERR-14-007 |
| `ck_approval_request_four_eyes`, `ck_approval_request_mfa`, `tg_approval_request_frozen` | Người quyết định khác người đề nghị và người sửa gần nhất đối tượng; kích hoạt chứng thư cần cả hai xác thực nhiều yếu tố; đã quyết định thì bất biến | BR-14-018, BR-14-022, ERR-14-007 |
| `ck_national_certificate_key_ref`, `ck_national_certificate_no_private_key`, `ck_trust_anchor_pem` | `keyRef` chỉ trỏ khóa `transit` của đúng tenant; chuỗi PEM không chứa `PRIVATE KEY` | BR-14-004, SEC-88 |
| `uq_national_certificate_signing`, `uq_national_certificate_tls` | Mỗi (nền tảng, mục đích) tối đa một chứng thư đang ký hiện hành; chứng thư cũ có `supersede_at` nhường chỗ trong thời gian chuyển tiếp | BR-14-017, ERR-14-020 |
| `tg_national_certificate_immutable`, `tg_national_certificate_nodelete`, `tg_trust_anchor_*` | Chủ thể, khóa, chuỗi, hiệu lực không đổi; không xóa chứng thư và neo, kể cả hết hạn | BR-14-019, ERR-14-022 |
| `ck_worker_command_no_secret`, `ck_outbox_no_secret`, `ck_signature_incident_detail`, `ck_anomaly_alert_evidence` | Không có khóa bí mật, thân bản tin hay định danh thô trong tham số lệnh, sự kiện, sự cố, bằng chứng cảnh báo | BR-14-005, BR-14-021, NFR-14-015 |
| `ck_national_service_cache`, `ck_national_service_stale`, `ck_national_service_purpose`, `ck_national_service_procedure` | Không đệm dịch vụ `SENSITIVE` hay thao tác ghi; chỉ đọc mới cho dùng dữ liệu quá hạn; dịch vụ trả DLCN bắt buộc mục đích | BR-14-008, BR-14-014, BR-14-016, ERR-14-038 |
| `ck_national_service_discontinued`, `tg_national_service_retired`, `tg_national_platform_retired` | Nhãn `DISCONTINUED` chỉ đi cùng `DEPRECATED` hoặc `RETIRED`; `RETIRED` là trạng thái cuối, mã không dùng lại | BR-14-024, ERR-14-002 |
| `tg_service_spec_frozen`, `uq_service_spec_one_active`, `ck_service_spec_breaking`, `uq_service_spec_version` | Đặc tả `ACTIVE` bất biến; mỗi dịch vụ một bản `ACTIVE`; thay đổi phá vỡ phải có người duyệt; cùng số phiên bản không nhận nội dung khác | BR-14-024, BR-14-025, ERR-14-010, ERR-14-012 |
| `ck_national_platform_hold`, `ck_signature_incident_ack`, `ck_signature_incident_conclusion`, `ix_signature_incident_open` | `SECURITY_HOLD` có thời điểm đặt; sự cố phải xác nhận rồi mới kết thúc, kết luận ≥ 10 ký tự; chỉ mục từng phần phục vụ điều kiện giải trừ "không còn sự cố `OPEN`" | BR-14-003, ERR-14-003, ERR-14-004 |
| `ck_routing_rule_fallback_read`, `ck_routing_rule_fallback`, `uq_routing_rule_active` | Không chuyển hướng dự phòng thao tác ghi; luật dự phòng phải nêu dịch vụ dự phòng; không trùng (điều kiện, mức ưu tiên) khi `ACTIVE` | BR-14-023, ERR-14-013, ERR-14-015 |
| `ck_quota_policy_basis`, `tg_quota_allocation_sum`, `tg_quota_policy_limit`, `uq_quota_policy_active` | Hạn mức phải có căn cứ văn bản; tổng phân bổ hữu hạn không vượt hạn mức và không hạ hạn mức xuống dưới tổng đã phân bổ (hoãn tới cuối giao dịch); một chính sách `ACTIVE` mỗi (nền tảng, dịch vụ, chu kỳ, môi trường) | BR-14-011, ERR-14-016, ERR-14-018 |
| `tg_transaction_forward`, `ck_national_transaction_unknown`, `ck_national_transaction_cache`, `ck_national_transaction_finished` | Giao dịch chỉ chuyển trạng thái tiến theo hạng, không xóa; `UNKNOWN_RESULT` chỉ cho thao tác ghi; chỉ đọc mới trúng đệm | BR-14-014, BR-14-020, BR-14-030 |
| `ck_inbound_endpoint_code`, `tg_inbound_endpoint_enable`, `ck_inbound_endpoint_unsigned` | Mã điểm cuối kết thúc bằng mã tenant nên xác định tenant từ điểm cuối; bật chỉ khi có nguồn được phép và tuyến luồng; tắt chữ ký cần lý do và SO đồng ý | BR-14-027, BR-14-028, ERR-14-024, ERR-14-039 |
| `uq_sync_run_open`, `ck_sync_run_reconcile`, `uq_reconcile_run_open` | Mỗi (tenant, loại) một phiên đồng bộ chưa kết thúc; phiên kết thúc đối soát gửi = nhận + từ chối + chờ | BR-14-026, ERR-14-026 |
| `tg_parallel_run_read_only`, `uq_parallel_run_running`, `ck_parallel_run_revocation` | Chạy song song chỉ cho thao tác đọc, một phiên mỗi dịch vụ; đóng phiên phải xác nhận thu hồi khóa cũ | BR-14-033, BR-14-034, ERR-14-004, ERR-14-033 |
| `uq_credential_rotation_open`, `ck_credential_rotation_receipt` | Một lần xoay mở mỗi (nền tảng, môi trường); hoàn tất phải có biên nhận thu hồi khóa cũ | FR-14-025, BR-14-034 |
| `ck_async_request_key`, `uq_async_request_idempotency` | `Idempotency-Key` là ULID, duy nhất theo (tenant, HTTT) | BR-14-030, ERR-14-116 |
| `uq_anomaly_alert_open`, `ck_anomaly_alert_reason` | Mỗi (HTTT, dịch vụ, luật) một cảnh báo `OPEN`; kết thúc cần quyết định và lý do | FR-14-053, ERR-14-003 |
| `ck_outbox_topic_tenant`, `ck_trust_anchor_crl_ref`, `ck_national_transaction_payload`, `ck_async_request_result_ref`, `ck_sync_run_batch` | Topic, khóa đối tượng Ceph luôn mang tiền tố đúng tenant | NFR-14-024, SEC-82 |

: Quy tắc nghiệp vụ chốt ở CSDL

### 1.5. Chuyển lỗi CSDL sang mã lỗi API

Ràng buộc là lớp phòng thủ cuối; dịch vụ vẫn kiểm trước để trả mã lỗi thân thiện. Khi một ràng buộc vẫn bị vi phạm (đua giữa hai yêu cầu), lớp ánh xạ lỗi lưu trữ của `national.internal` (đề xuất, Đề nghị đồng bộ) ánh xạ SQLSTATE và tên ràng buộc sang `ERR-14-*` theo bảng dưới, không bao giờ lộ tên bảng, cột hay giá trị ra người dùng.

| SQLSTATE | Nguồn | Ánh xạ |
|---|---|---|
| `23505` (unique) | `uq_*_code`, `uq_*_national_code` | ERR-14-002 (409) |
| `23505` | `uq_routing_rule_active` | ERR-14-013 (409) |
| `23505` | `uq_inbound_endpoint_code`, `uq_service_exposure_path` | ERR-14-023 (409) |
| `23505` | `uq_sync_run_open`, `uq_reconcile_run_open` | ERR-14-026 (409) |
| `23505` | `uq_parallel_run_running` | ERR-14-033 (409) |
| `23505` | `uq_service_spec_version` | ERR-14-010 (409) |
| `23505` | `uq_async_request_idempotency` | ERR-14-116 (409) nếu khác nội dung; trả lại kết quả cũ nếu cùng nội dung |
| `23505` | Các `uq_*_open`, `uq_*_active`, `uq_*_pending` còn lại | ERR-14-006 hoặc ERR-14-004 (409) tùy đối tượng |
| `23514` (check) | `ck_*_four_eyes`, `ck_approval_request_four_eyes` | ERR-14-007 (403) |
| `23514` | `ck_national_service_cache`, `ck_national_service_stale` | ERR-14-038 (422) |
| `23514` | `ck_quota_policy_basis`, `ck_routing_rule_basis` | ERR-14-016 (422) |
| `23514` | `tg_quota_allocation_sum` | ERR-14-018 (422) |
| `23514` | `ck_*_conclusion`, `ck_*_reason`, `ck_*_note` | ERR-14-003 (400) |
| `23514`, `23503` | Các ràng buộc còn lại | ERR-14-003 (400) hoặc ERR-14-004 (409); khóa ngoại sai tenant trả ERR-14-001 |
| `55000` | `tg_*_frozen`, `tg_*_immutable`, `tg_*_retired`, `tg_transaction_forward` | ERR-14-004 (409), riêng đặc tả ACTIVE ERR-14-010 |
| `42501` (RLS) | Chính sách `rls_*` khi chèn hoặc sửa chéo tenant | ERR-14-001 (404, cùng thân với không tồn tại, BR-14-029); ghi sự kiện an ninh |

: Chuyển lỗi CSDL sang mã lỗi API

### 1.6. Dung lượng và hiệu năng ghi

Hồ sơ "tỉnh vừa" (GĐ-14-03): khoảng 150.000 lượt gọi quốc gia mỗi ngày, 9 lượt/giây ở cao điểm, mọi lượt (kể cả trúng đệm) để lại một dòng giao dịch. `LedgerConsumer` ghi theo lô 500 bản ghi hoặc 200 ms bằng `INSERT … ON CONFLICT DO UPDATE … WHERE` theo hạng; ở 9 lượt/giây mỗi lượt có hai đến ba bản ghi (`RECEIVED`, `SENT`, kết thúc) tức khoảng 30 dòng/giây, thấp xa năng lực của `pg-core` (hàng nghìn dòng/giây). Giả định kích thước mỗi dòng giao dịch khoảng 1,1 KB gồm dữ liệu (520 byte) và 9 chỉ mục (mỗi chỉ mục khoảng 70 byte): 150.000 × 1,1 KB ≈ 165 MB mỗi ngày, khoảng 5 GB mỗi tháng. Bảng tổng hợp dung lượng ở §7.3.

## 2. Sơ đồ thực thể – quan hệ

Bốn hình dưới chia 36 bảng theo nhóm để đọc được trên khổ A4. Đường liền là khóa ngoại thật, luôn kèm `tenant_id` (`FOREIGN KEY (x_id, tenant_id)`); đường chấm là liên kết theo mã không có khóa ngoại (§1.2). Bảng `outbox` và `shedlock` đứng riêng ở hình 4.

```{.mermaid caption="Nhóm danh mục: nền tảng, dịch vụ, đặc tả, cung cấp lại, đối chiếu, định tuyến, duyệt"}
erDiagram
  national_platform ||--o{ national_service : "dịch vụ của nền tảng"
  national_service ||--o{ service_spec : "đặc tả theo phiên bản"
  national_service ||--o| service_exposure : "cung cấp lại thành API"
  national_platform ||--o{ reconcile_run : "đối chiếu danh mục"
  national_platform ||--o{ credential_rotation : "xoay thông tin xác thực"
  routing_rule }o..o{ national_service : "đích, dự phòng (theo mã)"
  approval_request }o..o{ national_platform : "duyệt bốn mắt (theo mã đối tượng)"
  worker_command }o..o{ national_platform : "lệnh kiểm tra, thử token (theo mã)"
  config_revision ||..o{ national_platform : "ảnh chụp cấu hình (theo tenant, môi trường)"
```

Hình cho thấy `national_platform` là gốc của nhóm: dịch vụ, đối chiếu, xoay thông tin xác thực đều treo vào nền tảng bằng khóa ngoại kép. `service_spec` và `service_exposure` treo vào dịch vụ; mỗi dịch vụ có nhiều phiên bản đặc tả nhưng tối đa một cung cấp lại. Luật định tuyến, duyệt bốn mắt và lệnh cho `worker` tham chiếu đối tượng theo mã vì có thể trỏ dịch vụ `COMMON` hoặc nhiều loại đối tượng khác nhau.

```{.mermaid caption="Nhóm tin cậy và hạn mức: chứng thư, chuỗi tin cậy, sự cố chữ ký, hạn mức, mức dùng, đệm"}
erDiagram
  national_platform ||--o{ national_certificate : "chứng thư (tùy chọn theo nền tảng)"
  national_platform ||--o{ trust_anchor : "neo tin cậy (tùy chọn)"
  national_platform ||--o{ signature_incident : "sự cố chữ ký"
  national_platform ||--o{ quota_policy : "hạn mức trung ương áp"
  quota_policy ||--o{ quota_allocation : "phân bổ cho HTTT"
  quota_policy ||..o{ quota_usage : "mức dùng theo chu kỳ (theo mã)"
  national_service ||..o{ cache_stats : "thống kê đệm theo giờ (theo mã)"
  national_certificate }o..o{ signature_incident : "chứng thư gây sự cố (vân tay)"
```

Hình cho thấy hai cụm. Cụm tin cậy: chứng thư số và neo tin cậy gắn nền tảng hoặc dùng chung cho tenant (khóa ngoại để trống); sự cố chữ ký luôn thuộc một nền tảng. Cụm hạn mức: chính sách, phân bổ có khóa ngoại và có trigger kiểm tổng; mức dùng và thống kê đệm là dữ liệu đo khối lượng lớn nên chỉ liên kết theo mã, không khóa ngoại.

```{.mermaid caption="Nhóm chiều vào, bất đồng bộ và đồng bộ"}
erDiagram
  national_platform ||--o{ inbound_endpoint : "điểm cuối chiều vào"
  inbound_endpoint ||--o{ allowed_sender : "nguồn được phép"
  inbound_endpoint ||--o{ inbound_route : "tuyến tới luồng PH-04"
  national_platform ||--o{ sync_run : "phiên đồng bộ"
  sync_run ||--o{ sync_record : "kết quả từng bản ghi"
  async_request }o..o{ national_service : "dịch vụ gọi (theo mã)"
```

Hình cho thấy chiều vào là một cây ba tầng (điểm cuối, nguồn được phép, tuyến) có `ON DELETE CASCADE` khi xóa điểm cuối nháp; đồng bộ là cây hai tầng (phiên, bản ghi). `async_request` là hàng chờ gọi bất đồng bộ, không có khóa ngoại vì do `AsyncStateConsumer` ghi từ Kafka.

```{.mermaid caption="Nhóm vận hành: sổ giao dịch, mức dùng, sức khỏe, cảnh báo bất thường, chuyển đổi, sự kiện"}
erDiagram
  national_transaction }o..o{ national_service : "dịch vụ, HTTT (theo mã)"
  national_transaction ||..o{ usage_hourly : "cộng dồn theo giờ"
  national_platform ||--|| health_state : "mức sức khỏe hiện hành"
  national_platform ||--o{ platform_outage : "khoảng gián đoạn"
  national_platform ||..o{ health_sample : "mẫu kiểm tra (theo id)"
  anomaly_alert ||--o{ access_block : "danh sách chặn"
  anomaly_alert }o..o{ anomaly_waiver : "cửa sổ đã báo (theo HTTT, dịch vụ)"
  parallel_run ||--o{ parallel_sample : "mẫu so sánh hai đường"
  national_platform ||--o{ legacy_import : "nhập từ phụ lục NGSP"
  outbox }o..o{ national_platform : "sự kiện miền (theo mã đối tượng)"
```

Hình cho thấy sổ giao dịch là nguồn của bốn dòng dữ liệu dẫn xuất: mức dùng theo giờ (`usage_hourly`), đường chuẩn và bằng chứng cho cảnh báo bất thường, báo cáo sử dụng và hồ sơ đối soát. Cảnh báo và danh sách chặn là cặp có khóa ngoại; chạy song song có mẫu so sánh chỉ chứa băm. `outbox` và `shedlock` không có quan hệ nghiệp vụ.

## 3. Đặc tả bảng

Chương này đặc tả 36 bảng của `ph14_national`. Mục 3.1 là danh sách bảng theo nhóm với thực thể, khối lượng giả định và thời hạn lưu giữ để hội đồng nắm bức tranh chung; mục 3.2 đến 3.37 là đặc tả từng bảng. Mỗi bảng mở đầu bằng khối 10 mục (Mục đích, FR phục vụ, Khóa chính, Duy nhất, Khóa ngoại, Ràng buộc CHECK, Chỉ mục, Cách ly tenant, Phân vùng và chỉ thêm, Ghi chú) trích từ DDL đã chạy thử, rồi đến danh sách cột. Mục 3.38 nêu truy vấn chính và chỉ mục phục vụ.

Phần đặc tả bảng được sinh bằng [`ph14/tools/gen_tables_md.py`](ph14/tools/gen_tables_md.py) (danh sách cột, từ `CREATE TABLE` và `COMMENT ON`) và [`ph14/tools/them_dac_ta_bang.py`](ph14/tools/them_dac_ta_bang.py) (khối 10 mục); sửa ở DDL rồi sinh lại, không sửa tay giữa hai dấu `gen`. Ghi chú của cột không có `COMMENT` được rút từ ràng buộc `CHECK` (danh sách giá trị, mẫu, miền).

### 3.1. Danh sách bảng

Khối lượng tính cho một tenant "tỉnh vừa" với giả định quy mô của FRS §12.2 (GĐ-14-03: 150.000 lượt gọi mỗi ngày; GĐ-14-08: 10 nền tảng, 300 dịch vụ mỗi tenant); số liệu thật lấy khi khảo sát và đo ở kiểm thử dung lượng NFR-14-019.

| STT | Bảng | Nhóm | Thực thể | Khối lượng giả định mỗi tenant | Lưu giữ |
|---|---|---|---|---|---|
| 1 | `national_platform` | Danh mục | EN-14-01 | ≤ 10 | Vĩnh viễn |
| 2 | `national_service` | Danh mục | EN-14-02 | ≤ 300 | Vĩnh viễn |
| 3 | `service_spec` | Danh mục | EN-14-03 | ≤ 1.500 (5 phiên bản mỗi dịch vụ) | Vĩnh viễn |
| 4 | `service_exposure` | Danh mục | EN-14-11 | ≤ 300 | Vĩnh viễn |
| 5 | `reconcile_run` | Danh mục | EN-14-10 (đối chiếu) | ≈ 120 mỗi năm | 3 năm |
| 6 | `config_revision` | Danh mục | Hỗ trợ ảnh chụp cấu hình | 3 (TEST, STAGING, PROD) | Vĩnh viễn |
| 7 | `routing_rule` | Danh mục | EN-14-04 | ≤ 1.000 | Vĩnh viễn |
| 8 | `approval_request` | Danh mục | Hỗ trợ bốn mắt (ADR-046) | ≈ 200 mỗi năm | Vĩnh viễn |
| 9 | `worker_command` | Danh mục | Hỗ trợ lệnh cho `worker` | ≈ 1.500 đang giữ | 30 ngày |
| 10 | `credential_rotation` | Tin cậy | Hỗ trợ xoay thông tin xác thực | ≈ 10 mỗi năm | Vĩnh viễn |
| 11 | `national_certificate` | Tin cậy | EN-14-05 | ≤ 20 | Vĩnh viễn |
| 12 | `trust_anchor` | Tin cậy | Hỗ trợ chuỗi tin cậy | ≈ 10 | Vĩnh viễn |
| 13 | `signature_incident` | Tin cậy | EN-14-12 | 0 đến 50 mỗi năm | 5 năm |
| 14 | `quota_policy` | Hạn mức | EN-14-06 | ≤ 300 | Vĩnh viễn |
| 15 | `quota_allocation` | Hạn mức | EN-14-07 | ≤ 3.000 | Theo chính sách |
| 16 | `quota_usage` | Hạn mức | EN-14-06 (mức dùng) | ≈ 0,2 triệu mỗi năm | 2 năm |
| 17 | `cache_stats` | Hạn mức | Hỗ trợ báo cáo đệm | ≈ 0,9 triệu mỗi năm | 13 tháng |
| 18 | `async_request` | Chiều vào, hàng chờ | EN-14-13 | ≈ 5.000 mỗi ngày | 90 ngày sau khi kết thúc |
| 19 | `inbound_endpoint` | Chiều vào, hàng chờ | EN-14-09 | ≤ 50 | Vĩnh viễn |
| 20 | `allowed_sender` | Chiều vào, hàng chờ | EN-14-09 | ≤ 200 | Theo điểm cuối |
| 21 | `inbound_route` | Chiều vào, hàng chờ | Hỗ trợ chiều vào | ≤ 500 | Theo điểm cuối |
| 22 | `sync_run` | Đồng bộ | EN-14-10 | ≈ 400 mỗi năm | 3 năm |
| 23 | `sync_record` | Đồng bộ | EN-14-10 (bản ghi) | ≈ 30.000 mỗi năm | 3 năm |
| 24 | `national_transaction` | Sổ giao dịch | EN-14-08 | ≈ 55 triệu mỗi năm | 12 tháng trực tuyến, 5 năm WORM |
| 25 | `usage_hourly` | Sổ giao dịch | Hỗ trợ báo cáo sử dụng | ≈ 1,6 triệu mỗi năm | 24 tháng |
| 26 | `health_sample` | Sức khỏe | Hỗ trợ giám sát | ≈ 1,5 triệu đang giữ | 90 ngày |
| 27 | `health_state` | Sức khỏe | Hỗ trợ giám sát | ≤ 30 | Hiện hành |
| 28 | `platform_outage` | Sức khỏe | Hỗ trợ sẵn sàng | ≤ 200 mỗi năm | 3 năm |
| 29 | `anomaly_alert` | Cảnh báo | EN-14-14 | ≤ 500 mỗi năm | 5 năm |
| 30 | `anomaly_waiver` | Cảnh báo | Hỗ trợ cảnh báo | ≤ 100 | Theo hiệu lực |
| 31 | `access_block` | Cảnh báo | Hỗ trợ cảnh báo | ≤ 50 | Theo hiệu lực |
| 32 | `parallel_run` | Chuyển đổi | EN-14-15 | ≤ 50 | Vĩnh viễn |
| 33 | `parallel_sample` | Chuyển đổi | EN-14-15 (mẫu) | ≈ 1,5 triệu đang giữ | 90 ngày |
| 34 | `legacy_import` | Chuyển đổi | Hỗ trợ nhập hệ cũ | ≤ 10 | 3 năm |
| 35 | `outbox` | Nền tảng | Hỗ trợ DD-11 | ≤ 50.000 đang giữ | 3 ngày |
| 36 | `shedlock` | Nền tảng | Hỗ trợ ShedLock | ≈ 10 | Hiện hành |

: Danh sách 36 bảng của schema ph14_national

Số thứ tự ở bảng trên trùng với số mục `3.n+1` bên dưới (STT 1 là mục 3.2).

<!-- gen:tables:start -->
### 3.2. `national_platform`

::: dac-ta
**Mục đích.** EN-14-01 Nền tảng quốc gia (NDXP, NDOP, REGISTRY) của một tenant hoặc của COMMON (FR-14-001, 002, 003). Địa chỉ và bí mật nằm ở kết nối PH-05 theo connection_code; mã bất biến, không dùng lại kể cả khi RETIRED.

**FR phục vụ.** FR-14-001, 002, 003, 024, 047.

**Khóa chính.** (id).

**Duy nhất.** `uq_national_platform_code` (tenant_id, code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_national_platform_tenant`, `ck_national_platform_code`, `ck_national_platform_type`, `ck_national_platform_scope`, `ck_national_platform_auth`, `ck_national_platform_spec_status`, `ck_national_platform_timeout`, `ck_national_platform_state`, `ck_national_platform_tested`, `ck_national_platform_active`, `ck_national_platform_four_eyes`, `ck_national_platform_suspended`, `ck_national_platform_retired`, `ck_national_platform_hold`, `ck_national_platform_breaker`.

**Chỉ mục.** `ix_national_platform_type_state` (tenant_id, platform_type, state), `ix_national_platform_connection` (tenant_id, connection_code), `ix_national_platform_name_trgm` (lower(name) gin_trgm_ops).

**Cách ly tenant.** RLS mẫu S (FORCE): đọc dòng của tenant phiên và dòng `COMMON`; ghi chỉ dòng tenant phiên, dòng `COMMON` chỉ khi phiên là `PLATFORM`; chính sách `rls_national_platform_*` (mục 1.2).

**Phân vùng, chỉ thêm.** RETIRED là trạng thái cuối, không đảo ngược, không dùng lại mã (trigger `tg_national_platform_retired`).

**Ghi chú.** Mẫu S: dòng COMMON đọc được ở mọi tenant nhưng chỉ phiên PLATFORM ghi (BR-14-029). Địa chỉ, bí mật ở kết nối PH-05 theo `connection_code`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `code` | `varchar(63)` | x |  | Mẫu: `^[a-z][a-z0-9-]{2,62}$`. |
| `name` | `varchar(200)` | x |  |  |
| `platform_type` | `varchar(10)` | x |  | Giá trị: `NDXP`, `NDOP`, `REGISTRY`. |
| `scope` | `varchar(6)` | x | `'TENANT'` | COMMON chỉ khi tenant_id = COMMON (chỉ PA khai báo, BR-14-029). |
| `connection_code` | `varchar(63)` | x |  | Mã kết nối của PH-05 (schema ph05_adapter) cùng tenant; không khóa ngoại vì khác schema và khác đơn vị sở hữu, kiểm ở dịch vụ (BR-14-025). |
| `auth_mode` | `varchar(20)` | x |  | Giá trị: `CLIENT_SECRET`, `PRIVATE_KEY_JWT`, `TLS_CLIENT_AUTH`. |
| `spec_status` | `varchar(12)` | x | `'OFFICIAL'` | PROVISIONAL: nền tảng đang dùng đặc tả tạm, giao diện hiển thị rõ (BR-14-025). |
| `default_timeout_ms` | `integer` | x | `15000` | Miền: 1000 đến 60000. |
| `owner_agency` | `varchar(200)` |  |  |  |
| `state` | `varchar(20)` | x | `'DRAFT'` | Giá trị: `DRAFT`, `TESTED`, `PENDING_ACTIVATION`, `ACTIVE`, `SUSPENDED`, `RETIRED`. |
| `state_reason` | `varchar(1000)` |  |  |  |
| `tested_at` | `timestamptz` |  |  | Lần kiểm tra kết nối đạt gần nhất; ACTIVE chỉ khi còn trong 24 giờ và khớp tested_connection_version (BR-14-022, ERR-14-008). |
| `tested_connection_version` | `integer` |  |  | Phiên bản cấu hình kết nối PH-05 lúc kiểm tra đạt (config_version). |
| `activation_requested_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `activation_requested_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `activated_by` | `varchar(64)` |  |  | Người duyệt bật; phải khác activation_requested_by (bốn mắt, ck_national_platform_four_eyes). |
| `activated_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `suspended_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `retired_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `security_hold` | `boolean` | x | `false` | Cờ SECURITY_HOLD: từ chối lượt cần dữ liệu mới khi sự cố chữ ký dồn dập; chỉ cổng hoặc SO đặt, chỉ SO giải trừ khi không còn sự cố OPEN (BR-14-003, ERR-14-004). |
| `security_hold_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `security_hold_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `breaker_override` | `jsonb` | x | `'{}'` | Cờ ép ngắt mạch theo nhóm dịch vụ, ví dụ {"LLTP":"FORCE_OPEN"}; cờ ép thắng trạng thái tự động (FR-14-038). Vào ảnh chụp cấu hình. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `national_platform`

### 3.3. `national_service`

::: dac-ta
**Mục đích.** EN-14-02 Dịch vụ quốc gia với chính sách đệm, ký số, ưu tiên, mức nhạy cảm (FR-14-004, 005, 006, 007). Dịch vụ thuộc nền tảng cùng tenant; dịch vụ COMMON do PA khai báo ở nền tảng COMMON.

**FR phục vụ.** FR-14-004…007, 009, 014, 017…023, 035.

**Khóa chính.** (id).

**Duy nhất.** `uq_national_service_code` (tenant_id, code), `uq_national_service_national_code` (tenant_id, platform_id, national_service_code, direction).

**Khóa ngoại.** (platform_id, tenant_id) → `national_platform`.

**Ràng buộc CHECK.** `ck_national_service_tenant`, `ck_national_service_code`, `ck_national_service_national_code`, `ck_national_service_group`, `ck_national_service_direction`, `ck_national_service_protocol`, `ck_national_service_operation`, `ck_national_service_idempotent`, `ck_national_service_sensitivity`, `ck_national_service_cache`, `ck_national_service_cache_ttl`, `ck_national_service_stale`, `ck_national_service_priority`, `ck_national_service_signing`, `ck_national_service_verify`, `ck_national_service_purpose`, `ck_national_service_procedure`, `ck_national_service_timeout`, `ck_national_service_label`, `ck_national_service_state`, `ck_national_service_discontinued`, `ck_national_service_retired`.

**Chỉ mục.** `ix_national_service_platform_state` (tenant_id, platform_id, state), `ix_national_service_group_state` (tenant_id, service_group, state), `ix_national_service_label` (tenant_id, reconcile_label) khi reconcile_label <> 'STILL', `ix_national_service_name_trgm` (lower(name) gin_trgm_ops).

**Cách ly tenant.** RLS mẫu S (FORCE): đọc dòng của tenant phiên và dòng `COMMON`; ghi chỉ dòng tenant phiên, dòng `COMMON` chỉ khi phiên là `PLATFORM`; chính sách `rls_national_service_*` (mục 1.2).

**Phân vùng, chỉ thêm.** RETIRED là trạng thái cuối, không đảo ngược, không dùng lại mã (trigger `tg_national_service_retired`).

**Ghi chú.** Mẫu S như nền tảng. Khóa ngoại kèm `tenant_id` nên dịch vụ chỉ gắn nền tảng cùng tenant; luật định tuyến và hạn mức tham chiếu dịch vụ theo mã.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `platform_id` | `uuid` | x |  |  |
| `code` | `varchar(63)` | x |  | Mẫu: `^[a-z][a-z0-9-]{2,62}$`. |
| `national_service_code` | `varchar(80)` | x |  | Giá trị Service-code gửi trung ương; khác code (mã nội bộ bất biến). |
| `name` | `varchar(200)` | x |  |  |
| `service_group` | `varchar(10)` | x |  | Giá trị: `LLTP`, `HO_TICH`, `BHXH`, `DVQHNS`, `DKDN`, `VBQPPL`, `DMDC`, `OTHER`. |
| `direction` | `varchar(8)` | x | `'OUTBOUND'` | Giá trị: `OUTBOUND`, `INBOUND`. |
| `protocol` | `varchar(4)` | x |  | Giá trị: `REST`, `SOAP`. |
| `operation_type` | `varchar(5)` | x |  | Giá trị: `READ`, `WRITE`. |
| `idempotent` | `boolean` |  |  |  |
| `sensitivity` | `varchar(10)` | x |  | Giá trị: `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE`. |
| `cacheable` | `boolean` | x | `false` | Không đệm dịch vụ SENSITIVE, thao tác WRITE (BR-14-014); cache_ttl_seconds ≤ 14.cache.max-ttl-seconds kiểm ở dịch vụ (ERR-14-036, ERR-14-038). |
| `cache_ttl_seconds` | `integer` |  |  |  |
| `stale_allowed` | `boolean` | x | `false` |  |
| `priority` | `varchar(10)` | x | `'NORMAL'` | Giá trị: `ESSENTIAL`, `NORMAL`, `BACKGROUND`. |
| `signing_mode` | `varchar(8)` | x | `'NONE'` | Giá trị: `NONE`, `XMLDSIG`, `WSSE`, `JWS`. |
| `verify_mode` | `varchar(8)` | x | `'NONE'` | Giá trị: `NONE`, `XMLDSIG`, `WSSE`, `JWS`. |
| `purpose_required` | `boolean` | x |  | Bắt buộc với dịch vụ trả dữ liệu cá nhân (RESTRICTED trở lên, BR-14-008). |
| `procedure_code_required` | `boolean` | x | `false` |  |
| `timeout_ms` | `integer` |  |  | Miền: 1000 đến 60000. |
| `spec_url` | `varchar(1000)` |  |  |  |
| `reconcile_label` | `varchar(14)` | x | `'UNKNOWN'` | Nhãn đối chiếu STILL, SPEC_CHANGED, DISCONTINUED, UNKNOWN; không phải trạng thái vòng đời (BR-14-024). |
| `reconciled_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `state` | `varchar(10)` | x | `'DRAFT'` | Giá trị: `DRAFT`, `ACTIVE`, `DEPRECATED`, `RETIRED`. |
| `state_reason` | `varchar(1000)` |  |  |  |
| `retired_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `legacy_ref` | `varchar(255)` |  |  | Dòng trong phụ lục NGSP hệ cũ khi dịch vụ được nhập (FR-14-056); không chứa bí mật (BR-14-034). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `national_service`

### 3.4. `service_spec`

::: dac-ta
**Mục đích.** EN-14-03 Đặc tả dịch vụ theo phiên bản, kèm hợp đồng (FR-14-008, 014). Bản ACTIVE bất biến, chỉ được chuyển SUPERSEDED (trigger tg_service_spec_frozen). Nội dung đặc tả (≤ 5 MB) lưu cùng để kích hoạt trong một giao dịch.

**FR phục vụ.** FR-14-008, 014.

**Khóa chính.** (id).

**Duy nhất.** `uq_service_spec_version` (tenant_id, service_id, spec_version), `uq_service_spec_one_active` (tenant_id, service_id) khi state = 'ACTIVE'.

**Khóa ngoại.** (service_id, tenant_id) → `national_service`.

**Ràng buộc CHECK.** `ck_service_spec_tenant`, `ck_service_spec_version`, `ck_service_spec_kind`, `ck_service_spec_checksum`, `ck_service_spec_contract_version`, `ck_service_spec_size`, `ck_service_spec_contract`, `ck_service_spec_source`, `ck_service_spec_state`, `ck_service_spec_breaking`, `ck_service_spec_activated`, `ck_service_spec_superseded`.

**Chỉ mục.** `ix_service_spec_service` (tenant_id, service_id, created_at DESC).

**Cách ly tenant.** RLS mẫu S (FORCE): đọc dòng của tenant phiên và dòng `COMMON`; ghi chỉ dòng tenant phiên, dòng `COMMON` chỉ khi phiên là `PLATFORM`; chính sách `rls_service_spec_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Bản ACTIVE bất biến, chỉ được chuyển SUPERSEDED, không xóa (ERR-14-010) (trigger `tg_service_spec_frozen`).

**Ghi chú.** Mẫu S. Nội dung đặc tả ≤ 5 MB lưu trong bảng (TOAST nén) để kích hoạt và ảnh chụp cấu hình cùng giao dịch; `ph14_readonly` không đọc cột `content`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `service_id` | `uuid` | x |  |  |
| `spec_version` | `varchar(32)` | x |  | Mẫu: `^[0-9A-Za-z][0-9A-Za-z._-]{0,31}$`. |
| `kind` | `varchar(12)` | x |  | Giá trị: `OPENAPI`, `WSDL`, `XSD`, `JSON_SCHEMA`. |
| `checksum` | `char(64)` | x |  | Mẫu: `^[0-9a-f]{64}$`. |
| `contract_version` | `varchar(16)` | x |  | Số chính.phụ của hợp đồng; thay đổi phá vỡ (breaking) phải tăng số chính (ERR-14-012). |
| `breaking` | `boolean` | x | `false` |  |
| `content` | `text` | x |  | Nội dung OpenAPI, WSDL, XSD hoặc JSON Schema đã quét mã độc và chặn XXE (FR-14-008); công khai về nghiệp vụ, không chứa bí mật. |
| `contract` | `jsonb` | x | `'{}'` | Hợp đồng dịch vụ: thao tác, tham số vào, trường ra, mã lỗi, subjectKeyPaths, ignorePaths, operations[].cacheTtlSeconds, exposedFields (SDD §4.1). |
| `diff` | `jsonb` |  |  |  |
| `source` | `varchar(6)` | x | `'UPLOAD'` | Giá trị: `UPLOAD`, `REMOTE`. |
| `source_url` | `varchar(1000)` |  |  |  |
| `state` | `varchar(10)` | x | `'DRAFT'` | Giá trị: `DRAFT`, `ACTIVE`, `SUPERSEDED`. |
| `breaking_approved_by` | `varchar(64)` |  |  | Người có PERM-14-approve duyệt thay đổi phá vỡ trước khi kích hoạt. |
| `activated_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `activated_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `superseded_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `note` | `varchar(500)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `service_spec`

### 3.5. `service_exposure`

::: dac-ta
**Mục đích.** EN-14-11 Cung cấp lại dịch vụ quốc gia thành API ở PH-02 (FR-14-009). Tối đa một cung cấp lại cho mỗi dịch vụ ở mỗi tenant; request_id là khóa chống trùng khi gọi PH-02 nên thử lại không tạo hai API nháp.

**FR phục vụ.** FR-14-009.

**Khóa chính.** (id).

**Duy nhất.** `uq_service_exposure_service` (tenant_id, service_id), `uq_service_exposure_path` (tenant_id, path), `uq_service_exposure_api` (tenant_id, api_code).

**Khóa ngoại.** (service_id, tenant_id) → `national_service`.

**Ràng buộc CHECK.** `ck_service_exposure_tenant`, `ck_service_exposure_path`, `ck_service_exposure_contract_version`, `ck_service_exposure_fields`, `ck_service_exposure_alloc`, `ck_service_exposure_state`, `ck_service_exposure_active`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_service_exposure_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `service_id` | `uuid` | x |  |  |
| `api_code` | `varchar(64)` |  |  |  |
| `path` | `varchar(255)` | x |  | Mẫu: `^/quoc-gia/[a-z0-9][a-z0-9/-]{1,200}$`. |
| `contract_version` | `varchar(16)` | x |  | Mẫu: `^[0-9]+\.[0-9]+$`. |
| `response_fields` | `text[]` | x |  | Trường được phép trả cho HTTT (nguyên tắc tối thiểu hóa, BR-14-009); chỉ gồm trường có trong đặc tả. |
| `default_allocation` | `jsonb` | x | `'{}'` |  |
| `requires_approval` | `boolean` | x | `true` |  |
| `description` | `varchar(1000)` |  |  |  |
| `state` | `varchar(16)` | x | `'DRAFT'` | FAILED_CREATE: PH-02 lỗi khi tạo API nháp, người dùng thử lại; PENDING_PUBLISH chờ sự kiện đã công bố của PH-02. |
| `state_reason` | `varchar(1000)` |  |  |  |
| `request_id` | `uuid` | x |  |  |
| `published_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `service_exposure`

### 3.6. `reconcile_run`

::: dac-ta
**Mục đích.** Phiên đối chiếu danh mục dịch vụ với danh mục hiện hành của NDXP, kind SERVICE_RECONCILE của EN-14-10 (FR-14-007). Giữ 3 năm. Mỗi nền tảng tối đa một phiên RUNNING (ERR-14-026).

**FR phục vụ.** FR-14-007.

**Khóa chính.** (id).

**Duy nhất.** `uq_reconcile_run_open` (tenant_id, platform_id) khi state = 'RUNNING'.

**Khóa ngoại.** (platform_id, tenant_id) → `national_platform`.

**Ràng buộc CHECK.** `ck_reconcile_run_tenant`, `ck_reconcile_run_source`, `ck_reconcile_run_match`, `ck_reconcile_run_state`, `ck_reconcile_run_file`, `ck_reconcile_run_summary`, `ck_reconcile_run_finished`, `ck_reconcile_run_applied`.

**Chỉ mục.** `ix_reconcile_run_platform` (tenant_id, platform_id, started_at DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_reconcile_run_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ 3 năm (FR-14-007).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `platform_id` | `uuid` | x |  |  |
| `source` | `varchar(6)` | x |  | Giá trị: `FILE`, `REMOTE`. |
| `match_by` | `varchar(24)` | x | `'NATIONAL_SERVICE_CODE'` | Giá trị: `NATIONAL_SERVICE_CODE`, `NAME`. |
| `dry_run` | `boolean` | x | `true` | true: chỉ báo cáo, không gán nhãn; APPLIED chỉ khi dry_run = false. |
| `state` | `varchar(8)` | x | `'RUNNING'` | Giá trị: `RUNNING`, `PREVIEW`, `APPLIED`, `FAILED`. |
| `file_name` | `varchar(255)` |  |  |  |
| `file_sha256` | `char(64)` |  |  | Mẫu: `^[0-9a-f]{64}$`. |
| `summary` | `jsonb` | x | `'{}'` |  |
| `proposals` | `jsonb` | x | `'[]'` | Mảng đề xuất {nationalServiceCode, current, proposed, reason}; không chứa dữ liệu cá nhân. |
| `applied_choices` | `jsonb` |  |  |  |
| `error_code` | `varchar(16)` |  |  |  |
| `started_by` | `varchar(64)` | x |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `started_at` | `timestamptz` | x | `now()` | Thời điểm (T-TS, lưu UTC). |
| `finished_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `applied_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `applied_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `reconcile_run`

### 3.7. `config_revision`

::: dac-ta
**Mục đích.** Số phiên bản ảnh chụp cấu hình của cổng, mỗi tenant và môi trường một dòng (FR-14-054, NFR-14-026). ConfigRevisionService.bump tăng revision trong cùng giao dịch với thay đổi bảng có mặt trong ảnh chụp; cổng bỏ sự kiện có revision nhỏ hơn bản đang giữ.

**FR phục vụ.** FR-14-054; NFR-14-026.

**Khóa chính.** (id).

**Duy nhất.** `uq_config_revision` (tenant_id, env).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_config_revision_tenant`, `ck_config_revision_env`, `ck_config_revision_rev`, `ck_config_revision_hash`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_config_revision_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `env` | `varchar(8)` | x |  | Giá trị: `TEST`, `STAGING`, `PROD`. |
| `revision` | `bigint` | x | `1` |  |
| `snapshot_hash` | `char(64)` |  |  | SHA-256 của ảnh chụp đã phát; công việc đêm dựng lại và so để phát hiện chỗ quên bump (SDD §4.3). |
| `built_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `config_revision`

### 3.8. `routing_rule`

::: dac-ta
**Mục đích.** EN-14-04 Luật định tuyến tới nền tảng và dịch vụ đích (FR-14-012, 013). Số priority lớn là ưu tiên cao. Dịch vụ tham chiếu theo mã, không khóa ngoại, vì có thể là dịch vụ COMMON; kiểm ACTIVE và cùng nhóm ở dịch vụ (ERR-14-014, 015).

**FR phục vụ.** FR-14-012, 013.

**Khóa chính.** (id).

**Duy nhất.** `uq_routing_rule_active` (tenant_id, coalesce(match_service_code, ''), coalesce(match_group, ''), coalesce(operation_type, ''), priority) khi state = 'ACTIVE'.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_routing_rule_tenant`, `ck_routing_rule_match`, `ck_routing_rule_group`, `ck_routing_rule_operation`, `ck_routing_rule_priority`, `ck_routing_rule_basis`, `ck_routing_rule_fallback`, `ck_routing_rule_fallback_read`, `ck_routing_rule_fallback_distinct`, `ck_routing_rule_state`, `ck_routing_rule_four_eyes`.

**Chỉ mục.** `ix_routing_rule_state_priority` (tenant_id, state, priority DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_routing_rule_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `match_service_code` | `varchar(63)` |  |  |  |
| `match_group` | `varchar(10)` |  |  | Giá trị: `LLTP`, `HO_TICH`, `BHXH`, `DVQHNS`, `DKDN`, `VBQPPL`, `DMDC`, `OTHER`. |
| `operation_type` | `varchar(5)` |  |  | Giá trị: `READ`, `WRITE`. |
| `primary_service_code` | `varchar(63)` | x |  |  |
| `fallback_service_code` | `varchar(63)` |  |  |  |
| `allow_fallback` | `boolean` | x | `false` | Chuyển hướng dự phòng chỉ cho thao tác đọc (BR-14-023); khóa ở CSDL cho luật theo nhóm, luật theo dịch vụ kiểm thêm ở ứng dụng vì loại thao tác nằm ở national_service. |
| `priority` | `integer` | x |  | Miền: 1 đến 1000. |
| `basis` | `varchar(500)` | x |  | Căn cứ văn bản hướng dẫn của trung ương, 10 đến 500 ký tự. |
| `effective_from` | `timestamptz` |  |  |  |
| `state` | `varchar(16)` | x | `'DRAFT'` | Giá trị: `DRAFT`, `PENDING_APPROVAL`, `ACTIVE`, `DISABLED`. |
| `requested_by` | `varchar(64)` |  |  | Người đề nghị; ACTIVE chỉ khi approved_by khác người đề nghị (BR-14-022). |
| `approved_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `approved_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `routing_rule`

### 3.9. `approval_request`

::: dac-ta
**Mục đích.** Đề nghị duyệt bốn mắt dùng chung cho tám loại thay đổi của BR-14-022 (ADR-046, FourEyesGuard). Người quyết định phải khác người đề nghị và người sửa gần nhất đối tượng; kích hoạt chứng thư cần cả hai xác thực nhiều yếu tố (BR-14-018). Đã quyết định thì bất biến.

**FR phục vụ.** FR-14-003, 005, 013, 028, 030, 032, 039, 045, 054.

**Khóa chính.** (id).

**Duy nhất.** `uq_approval_request_pending` (tenant_id, request_type, object_type, object_code) khi status = 'PENDING'.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_approval_request_tenant`, `ck_approval_request_type`, `ck_approval_request_object_type`, `ck_approval_request_proposed`, `ck_approval_request_status`, `ck_approval_request_expiry`, `ck_approval_request_decided`, `ck_approval_request_four_eyes`, `ck_approval_request_reject_note`, `ck_approval_request_mfa`.

**Chỉ mục.** `ix_approval_request_inbox` (tenant_id, status, expires_at), `ix_approval_request_object` (tenant_id, object_type, object_code, requested_at DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_approval_request_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ vĩnh viễn, không xóa (kiểm toán bốn mắt); Đã quyết định thì bất biến, không xóa (trigger `tg_approval_request_frozen`).

**Ghi chú.** Một bảng chung cho tám loại thay đổi của BR-14-022 (ADR-046); chỉ một yêu cầu PENDING cho mỗi (loại, đối tượng).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `request_type` | `varchar(32)` | x |  | Giá trị: `PLATFORM_ACTIVATE`, `ROUTING_RULE`, `QUOTA_PROD`, `CERT_ACTIVATE`, `SERVICE_RELAX_CONTROL`, `INBOUND_ENABLE`, `OPEN_DATA_FIRST_PUBLISH`, `SECURITY_PARAM_CHANGE`. |
| `object_type` | `varchar(24)` | x |  | Giá trị: `PLATFORM`, `ROUTING_RULE`, `QUOTA_POLICY`, `CERTIFICATE`, `TRUST_ANCHOR`, `SERVICE`, `INBOUND_ENDPOINT`, `OPEN_DATASET`, `PARAMETER`. |
| `object_code` | `varchar(128)` | x |  |  |
| `summary` | `varchar(500)` |  |  |  |
| `proposed_change` | `jsonb` | x |  | Thay đổi đề xuất (giá trị trước, sau của thuộc tính chính sách); không chứa bí mật. |
| `last_modified_by` | `varchar(64)` |  |  | Người sửa đối tượng gần nhất tại lúc đề nghị; so sánh theo mã người dùng, không theo vai trò (ERR-14-007). |
| `requested_by` | `varchar(64)` | x |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `requested_at` | `timestamptz` | x | `now()` | Thời điểm (T-TS, lưu UTC). |
| `requester_mfa_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `reason` | `varchar(1000)` |  |  |  |
| `status` | `varchar(10)` | x | `'PENDING'` | Giá trị: `PENDING`, `APPROVED`, `REJECTED`, `EXPIRED`, `CANCELLED`. |
| `decided_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `decided_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `approver_mfa_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `decision_note` | `varchar(1000)` |  |  |  |
| `expires_at` | `timestamptz` | x |  | Hết hạn sau 7 ngày kể từ requested_at (giả định theo ADR-046). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `approval_request`

### 3.10. `worker_command`

::: dac-ta
**Mục đích.** Lệnh dh-integration gửi vai trò worker của cổng (probe, cert.selftest, token.test, sync.run, spec.fetch, catalog.fetch) và kết quả (FR-14-002, 008, 043, 047). id là commandId, kết quả xử lý lũy đẳng theo id; quá deadline_at chuyển TIMED_OUT. Giữ 30 ngày (giả định), đếm giới hạn 14.test.max-per-hour.

**FR phục vụ.** FR-14-002, 007, 008, 043, 047.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_worker_command_tenant`, `ck_worker_command_type`, `ck_worker_command_target`, `ck_worker_command_state`, `ck_worker_command_deadline`, `ck_worker_command_finished`, `ck_worker_command_trace`, `ck_worker_command_no_secret`.

**Chỉ mục.** `ix_worker_command_open` (tenant_id, deadline_at) khi state IN ('PENDING', 'DISPATCHED'), `ix_worker_command_target` (tenant_id, target_type, target_code, command_type, requested_at DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_worker_command_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ 30 ngày (giả định), tác vụ dọn xóa theo `finished_at`.

**Ghi chú.** `id` là `commandId`; kết quả xử lý lũy đẳng theo `id`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `command_type` | `varchar(24)` | x |  | Giá trị: `probe`, `cert.selftest`, `token.test`, `sync.run`, `spec.fetch`, `catalog.fetch`. |
| `target_type` | `varchar(24)` | x |  | Giá trị: `PLATFORM`, `CERTIFICATE`, `SERVICE`, `SYNC_RUN`. |
| `target_code` | `varchar(128)` | x |  |  |
| `params` | `jsonb` | x | `'{}'` |  |
| `state` | `varchar(10)` | x | `'PENDING'` | Giá trị: `PENDING`, `DISPATCHED`, `SUCCEEDED`, `FAILED`, `TIMED_OUT`. |
| `requested_by` | `varchar(64)` | x |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `requested_at` | `timestamptz` | x | `now()` | Thời điểm (T-TS, lưu UTC). |
| `deadline_at` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `finished_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `result` | `jsonb` |  |  | Kết quả từng bước (DNS, TCP, TLS, token, ký thử); không có giá trị bí mật, token (BR-14-005). |
| `error_code` | `varchar(16)` |  |  |  |
| `trace_id` | `char(32)` |  |  | Mẫu: `^[0-9a-f]{32}$`. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `worker_command`

### 3.11. `credential_rotation`

::: dac-ta
**Mục đích.** Trạng thái xoay vòng thông tin xác thực với nền tảng quốc gia, mỗi (nền tảng, môi trường) tối đa một lần xoay mở (FR-14-024, 025). Giá trị bí mật chỉ ở OpenBao qua PH-05; bảng chỉ lưu số phiên bản chờ và biên nhận thu hồi (BR-14-005, BR-14-034). Giữ vĩnh viễn để truy vết.

**FR phục vụ.** FR-14-024, 025.

**Khóa chính.** (id).

**Duy nhất.** `uq_credential_rotation_open` (tenant_id, platform_id, env) khi state NOT IN ('DONE', 'CANCELLED').

**Khóa ngoại.** (platform_id, tenant_id) → `national_platform`.

**Ràng buộc CHECK.** `ck_credential_rotation_tenant`, `ck_credential_rotation_env`, `ck_credential_rotation_trigger`, `ck_credential_rotation_state`, `ck_credential_rotation_pending`, `ck_credential_rotation_overlap`, `ck_credential_rotation_done`, `ck_credential_rotation_receipt`, `ck_credential_rotation_cancel`.

**Chỉ mục.** `ix_credential_rotation_platform` (tenant_id, platform_id, started_at DESC), `ix_credential_rotation_overlap` (overlap_until) khi state = 'OVERLAP'.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_credential_rotation_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ vĩnh viễn để truy vết.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `platform_id` | `uuid` | x |  |  |
| `env` | `varchar(8)` | x |  | Giá trị: `TEST`, `STAGING`, `PROD`. |
| `trigger_kind` | `varchar(12)` | x | `'SCHEDULED'` | Giá trị: `SCHEDULED`, `ON_DEMAND`, `COMPROMISE`. |
| `state` | `varchar(24)` | x | `'AWAITING_PENDING_VALUE'` | Giá trị: `AWAITING_PENDING_VALUE`, `PENDING_VERIFY`, `OVERLAP`, `AWAITING_REVOCATION`, `DONE`, `CANCELLED`. |
| `reason` | `varchar(500)` |  |  |  |
| `started_by` | `varchar(64)` | x |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `started_at` | `timestamptz` | x | `now()` | Thời điểm (T-TS, lưu UTC). |
| `pending_secret_version` | `integer` |  |  | Số phiên bản bí mật chờ ở PH-05 (OpenBao kv); không phải giá trị bí mật. |
| `tested_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `switched_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `switched_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `overlap_until` | `timestamptz` |  |  | Hết cửa sổ chuyển tiếp = switched_at + 14.secret.overlap-hours (mặc định 24 giờ). |
| `revocation_receipt` | `varchar(500)` |  |  | Số biên nhận hoặc văn bản xác nhận trung ương đã thu hồi khóa cũ; bắt buộc để DONE, và để đóng chạy song song (ERR-14-004). |
| `revocation_confirmed_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `revocation_confirmed_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `done_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `cancel_reason` | `varchar(500)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `credential_rotation`

### 3.12. `national_certificate`

::: dac-ta
**Mục đích.** EN-14-05 Chứng thư số chuyên dùng công vụ để ký bản tin hoặc xác thực TLS khách (FR-14-026, 028, 029). Chỉ lưu chuỗi công khai và keyRef tới OpenBao transit; không có khóa riêng (BR-14-004). Không xóa chứng thư, kể cả đã hết hạn (BR-14-019).

**FR phục vụ.** FR-14-026, 028, 029.

**Khóa chính.** (id).

**Duy nhất.** `uq_national_certificate_code` (tenant_id, code), `uq_national_certificate_fingerprint` (tenant_id, fingerprint_sha256), `uq_national_certificate_signing` (tenant_id, coalesce(platform_id, '00000000-0000-0000-0000-000000000000'::uuid)) WHERE state IN ('ACTIVE', 'EXPIRING') AND supersede_at IS NULL AND purpose IN ('SIGNING', 'BOTH'), `uq_national_certificate_tls` (tenant_id, coalesce(platform_id, '00000000-0000-0000-0000-000000000000'::uuid)) WHERE state IN ('ACTIVE', 'EXPIRING') AND supersede_at IS NULL AND purpose IN ('TLS_CLIENT', 'BOTH').

**Khóa ngoại.** (platform_id, tenant_id) → `national_platform`.

**Ràng buộc CHECK.** `ck_national_certificate_tenant`, `ck_national_certificate_code`, `ck_national_certificate_purpose`, `ck_national_certificate_fingerprint`, `ck_national_certificate_validity`, `ck_national_certificate_key_ref`, `ck_national_certificate_no_private_key`, `ck_national_certificate_state`, `ck_national_certificate_requested`, `ck_national_certificate_approved`, `ck_national_certificate_four_eyes`, `ck_national_certificate_supersede`, `ck_national_certificate_revoked`.

**Chỉ mục.** `ix_national_certificate_expiry` (not_after) khi state IN ('ACTIVE', 'EXPIRING'), `ix_national_certificate_platform` (tenant_id, platform_id, state).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_national_certificate_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ vĩnh viễn, kể cả hết hạn (BR-14-019); Cột bất biến sau INSERT: `code`, `platform_id`, `purpose`, `subject`, `issuer`, `serial_number`, `fingerprint_sha256`, `not_before`, `not_after`, `key_ref`, `public_chain` (trigger `tg_national_certificate_immutable`); Không cho xóa dòng (trigger `tg_national_certificate_nodelete`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `code` | `varchar(63)` | x |  | Mẫu: `^[a-z][a-z0-9-]{2,62}$`. |
| `platform_id` | `uuid` |  |  | Rỗng: chứng thư dùng chung cho mọi nền tảng của tenant (FR-14-028). |
| `purpose` | `varchar(10)` | x |  | Giá trị: `SIGNING`, `TLS_CLIENT`, `BOTH`. |
| `subject` | `varchar(500)` | x |  |  |
| `issuer` | `varchar(500)` | x |  |  |
| `serial_number` | `varchar(64)` | x |  |  |
| `fingerprint_sha256` | `char(64)` | x |  | Mẫu: `^[0-9a-f]{64}$`. |
| `not_before` | `timestamptz` | x |  |  |
| `not_after` | `timestamptz` | x |  |  |
| `key_ref` | `varchar(255)` | x |  | Tham chiếu khóa transit của đúng tenant, dạng transit/keys/dh-{tenant}-… ; ck_national_certificate_key_ref chặn trỏ sang khóa tenant khác (SEC-88). |
| `public_chain` | `text` | x |  | Chứng thư và chuỗi trung gian dạng PEM, ≤ 64 KB; CHECK chặn khối PRIVATE KEY lọt vào. |
| `state` | `varchar(20)` | x | `'UPLOADED'` | Giá trị: `UPLOADED`, `PENDING_ACTIVATION`, `ACTIVE`, `EXPIRING`, `EXPIRED`, `SUPERSEDED`, `REVOKED`. |
| `note` | `varchar(500)` |  |  |  |
| `uploaded_by` | `varchar(64)` | x |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `activation_requested_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `activation_requested_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `activation_approved_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `activation_approved_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `supersede_at` | `timestamptz` |  |  | Thời điểm sẽ SUPERSEDED khi chứng thư mới cùng mục đích kích hoạt (= lúc kích hoạt + 14.cert.overlap-hours); trong lúc chờ chỉ dùng để xác minh, không ký (BR-14-017). |
| `last_warned_days` | `integer` |  |  | Mốc cảnh báo hạn đã gửi gần nhất (60, 30 hoặc 7 ngày) để CertificateExpiryJob không gửi trùng. |
| `revoked_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `revoked_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `revoked_reason` | `varchar(500)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `national_certificate`

### 3.13. `trust_anchor`

::: dac-ta
**Mục đích.** Chuỗi tin cậy: chứng thư gốc, trung gian của trung ương dùng xác minh phản hồi, kèm siêu dữ liệu CRL (FR-14-027, 030). Thay đổi neo cần bốn mắt (BR-14-018). Tệp CRL nằm ở bucket dh-nat-trust, bảng chỉ giữ khóa đối tượng và băm.

**FR phục vụ.** FR-14-027, 030.

**Khóa chính.** (id).

**Duy nhất.** `uq_trust_anchor_code` (tenant_id, code), `uq_trust_anchor_fingerprint` (tenant_id, fingerprint_sha256).

**Khóa ngoại.** (platform_id, tenant_id) → `national_platform`.

**Ràng buộc CHECK.** `ck_trust_anchor_tenant`, `ck_trust_anchor_code`, `ck_trust_anchor_kind`, `ck_trust_anchor_fingerprint`, `ck_trust_anchor_pem`, `ck_trust_anchor_state`, `ck_trust_anchor_requested`, `ck_trust_anchor_approved`, `ck_trust_anchor_four_eyes`, `ck_trust_anchor_crl`, `ck_trust_anchor_crl_ref`.

**Chỉ mục.** `ix_trust_anchor_state` (tenant_id, state, not_after), `ix_trust_anchor_crl_next` (crl_next_update) khi state = 'ACTIVE'.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_trust_anchor_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ vĩnh viễn để xác minh giao dịch cũ (BR-14-019); Cột bất biến sau INSERT: `code`, `platform_id`, `anchor_kind`, `subject`, `issuer`, `fingerprint_sha256`, `not_after`, `pem` (trigger `tg_trust_anchor_immutable`); Không cho xóa dòng (trigger `tg_trust_anchor_nodelete`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `code` | `varchar(63)` | x |  | Mẫu: `^[a-z][a-z0-9-]{2,62}$`. |
| `platform_id` | `uuid` |  |  |  |
| `name` | `varchar(200)` | x |  |  |
| `anchor_kind` | `varchar(12)` | x |  | Giá trị: `ROOT`, `INTERMEDIATE`. |
| `subject` | `varchar(500)` | x |  |  |
| `issuer` | `varchar(500)` | x |  |  |
| `fingerprint_sha256` | `char(64)` | x |  | Mẫu: `^[0-9a-f]{64}$`. |
| `not_after` | `timestamptz` | x |  |  |
| `pem` | `text` | x |  |  |
| `crl_url` | `varchar(1000)` |  |  |  |
| `ocsp_url` | `varchar(1000)` |  |  |  |
| `crl_ref` | `varchar(255)` |  |  | Khóa đối tượng CRL ở bucket dh-nat-trust, bắt đầu bằng tiền tố tenant chữ thường. |
| `crl_sha256` | `char(64)` |  |  | Mẫu: `^[0-9a-f]{64}$`. |
| `crl_this_update` | `timestamptz` |  |  |  |
| `crl_next_update` | `timestamptz` |  |  | nextUpdate của CRL; quá 14.crl.max-age-days thì cảnh báo mức cao, và theo 14.crl.fail-mode HARD thì từ chối xác minh. |
| `crl_refreshed_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `state` | `varchar(20)` | x | `'UPLOADED'` | Giá trị: `UPLOADED`, `PENDING_ACTIVATION`, `ACTIVE`, `EXPIRED`, `REVOKED`. |
| `uploaded_by` | `varchar(64)` | x |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `activation_requested_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `activation_approved_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `activation_approved_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `note` | `varchar(500)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `trust_anchor`

### 3.14. `signature_incident`

::: dac-ta
**Mục đích.** EN-14-12 Sự cố chữ ký, chuỗi tin cậy, thời điểm ký hoặc phát lại: xử lý như sự cố an ninh (FR-14-027, 031, 040, BR-14-003). Giữ 5 năm, không xóa. Giải trừ SECURITY_HOLD chỉ khi không còn dòng OPEN (ERR-14-004).

**FR phục vụ.** FR-14-027, 031, 040.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (platform_id, tenant_id) → `national_platform`.

**Ràng buộc CHECK.** `ck_signature_incident_tenant`, `ck_signature_incident_kind`, `ck_signature_incident_direction`, `ck_signature_incident_fingerprint`, `ck_signature_incident_detail`, `ck_signature_incident_state`, `ck_signature_incident_classification`, `ck_signature_incident_action`, `ck_signature_incident_ack`, `ck_signature_incident_resolved`, `ck_signature_incident_conclusion`.

**Chỉ mục.** `ix_signature_incident_platform` (tenant_id, platform_id, detected_at DESC), `ix_signature_incident_open` (tenant_id, platform_id) khi state = 'OPEN', `ix_signature_incident_unresolved` (tenant_id, detected_at) khi state <> 'RESOLVED', `ix_signature_incident_txn` (tenant_id, transaction_code) khi transaction_code IS NOT NULL.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_signature_incident_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ 5 năm (EN-14-12), không xóa; Cột bất biến sau INSERT: `platform_id`, `kind`, `direction`, `transaction_code`, `cert_fingerprint`, `detected_at` (trigger `tg_signature_incident_immutable`); Không cho xóa dòng (trigger `tg_signature_incident_nodelete`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `platform_id` | `uuid` | x |  |  |
| `kind` | `varchar(20)` | x |  | Giá trị: `SIGNATURE_MISMATCH`, `UNTRUSTED_CHAIN`, `REVOKED_CERT`, `STALE_TIMESTAMP`, `REPLAY`. |
| `direction` | `varchar(8)` | x |  | Giá trị: `OUTBOUND`, `INBOUND`. |
| `transaction_code` | `varchar(40)` |  |  |  |
| `service_code` | `varchar(63)` |  |  |  |
| `cert_fingerprint` | `char(64)` |  |  | Mẫu: `^[0-9a-f]{64}$`. |
| `detail` | `jsonb` | x | `'{}'` | Dấu vết kỹ thuật đã che (mã lỗi thư viện, vị trí phần tử XML); không có thân bản tin, khóa hay chữ ký thô (BR-14-021). |
| `state` | `varchar(12)` | x | `'OPEN'` | Giá trị: `OPEN`, `ACKNOWLEDGED`, `RESOLVED`. |
| `assignee` | `varchar(64)` |  |  |  |
| `classification` | `varchar(24)` |  |  | Giá trị: `CONFIG_ERROR`, `CERT_ROTATED_BY_CENTER`, `SUSPECTED_ATTACK`. |
| `action_taken` | `varchar(24)` |  |  | Giá trị: `REFRESH_TRUST`, `KEEP_BLOCK`, `OPEN_SECURITY_INCIDENT`. |
| `conclusion` | `varchar(1000)` |  |  | Kết luận xử lý, tối thiểu 10 ký tự để RESOLVED (ERR-14-003). |
| `hold_applied` | `boolean` | x | `false` |  |
| `detected_at` | `timestamptz` | x | `now()` | Thời điểm (T-TS, lưu UTC). |
| `acknowledged_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `acknowledged_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `resolved_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `resolved_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `signature_incident`

### 3.15. `quota_policy`

::: dac-ta
**Mục đích.** EN-14-06 Hạn mức truy vấn do trung ương áp theo nền tảng hoặc dịch vụ và chu kỳ (FR-14-032, 033). Phải có căn cứ văn bản (BR-14-011); ở môi trường thật cần người thứ hai duyệt (BR-14-022). Bộ đếm lượt dùng ở Valkey.

**FR phục vụ.** FR-14-032, 033.

**Khóa chính.** (id).

**Duy nhất.** `uq_quota_policy_active` (tenant_id, platform_id, coalesce(service_code, ''), period, env) khi state = 'ACTIVE'.

**Khóa ngoại.** (platform_id, tenant_id) → `national_platform`.

**Ràng buộc CHECK.** `ck_quota_policy_tenant`, `ck_quota_policy_period`, `ck_quota_policy_env`, `ck_quota_policy_limit`, `ck_quota_policy_basis`, `ck_quota_policy_state`, `ck_quota_policy_superseded`, `ck_quota_policy_four_eyes`.

**Chỉ mục.** `ix_quota_policy_platform` (tenant_id, platform_id, state).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_quota_policy_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Constraint trigger hoãn: không hạ hạn mức xuống dưới tổng đã phân bổ (ERR-14-018) (trigger `tg_quota_policy_limit`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `platform_id` | `uuid` | x |  |  |
| `service_code` | `varchar(63)` |  |  | Rỗng: áp cho cả nền tảng. Tham chiếu theo mã, không khóa ngoại. |
| `period` | `varchar(5)` | x |  | Giá trị: `HOUR`, `DAY`, `MONTH`. |
| `env` | `varchar(8)` | x | `'PROD'` | Giá trị: `TEST`, `STAGING`, `PROD`. |
| `limit_count` | `bigint` | x |  | Miền: 1 đến 2000000000. |
| `basis_document` | `varchar(500)` | x |  | Số, ngày, trích yếu văn bản thông báo hạn mức, 10 đến 500 ký tự. |
| `effective_from` | `timestamptz` | x | `now()` |  |
| `state` | `varchar(16)` | x | `'DRAFT'` | Giá trị: `DRAFT`, `PENDING_APPROVAL`, `ACTIVE`, `SUPERSEDED`. |
| `requested_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `approved_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `approved_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `superseded_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `quota_policy`

### 3.16. `quota_allocation`

::: dac-ta
**Mục đích.** EN-14-07 Phần hạn mức Datahub chia cho từng HTTT theo dịch vụ (FR-14-034). Trigger hoãn đến cuối giao dịch bảo đảm tổng phân bổ hữu hạn không vượt hạn mức của chính sách (ERR-14-018); phân bổ UNLIMITED chỉ bị chặn bởi hạn mức toàn cục.

**FR phục vụ.** FR-14-034.

**Khóa chính.** (id).

**Duy nhất.** `uq_quota_allocation` (tenant_id, policy_id, system_code, service_code).

**Khóa ngoại.** (policy_id, tenant_id) → `quota_policy` (xóa theo).

**Ràng buộc CHECK.** `ck_quota_allocation_tenant`, `ck_quota_allocation_limit`, `ck_quota_allocation_share`.

**Chỉ mục.** `ix_quota_allocation_system` (tenant_id, system_code).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_quota_allocation_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Constraint trigger hoãn: tổng phân bổ hữu hạn không vượt hạn mức (ERR-14-018) (trigger `tg_quota_allocation_sum`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `policy_id` | `uuid` | x |  |  |
| `system_code` | `varchar(64)` | x |  |  |
| `service_code` | `varchar(63)` | x |  |  |
| `limit_count` | `bigint` |  |  |  |
| `unlimited` | `boolean` | x | `false` | true khi limit_count rỗng: HTTT không bị trần riêng (dịch vụ ESSENTIAL, Q14-24). |
| `share_of_reserve` | `numeric(5,4)` | x | `0` | Tỷ lệ HTTT được hưởng trong phần dự phòng chưa phân bổ (0 đến 1). |
| `note` | `varchar(500)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `quota_allocation`

### 3.17. `quota_usage`

::: dac-ta
**Mục đích.** Ảnh chụp mức dùng hạn mức theo chu kỳ, cập nhật từ chủ đề quota.usage (FR-14-033, 057). Khóa tự nhiên, upsert nhận giá trị lớn hơn. Phân vùng tháng, giữ 2 năm (NFR-14-021). Số liệu nóng ở Valkey; bảng này phục vụ báo cáo, dự báo cạn và đối soát.

**FR phục vụ.** FR-14-033, 057.

**Khóa chính.** (tenant_id, platform_id, env, service_key, period, bucket_start).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_quota_usage_tenant`, `ck_quota_usage_env`, `ck_quota_usage_period`, `ck_quota_usage_counts`, `ck_quota_usage_reset`, `ck_quota_usage_level`.

**Chỉ mục.** `ix_quota_usage_platform` (tenant_id, platform_id, bucket_start DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_quota_usage_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Phân vùng RANGE theo tháng trên `bucket_start` (thủ tục `p_ensure_month_partitions`); Lưu giữ 2 năm (NFR-14-021), DETACH phân vùng quá hạn.

**Ghi chú.** Khóa tự nhiên, không có `id`, `version`; UsageConsumer upsert nhận giá trị lớn hơn.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `platform_id` | `uuid` | x |  |  |
| `env` | `varchar(8)` | x |  | Giá trị: `TEST`, `STAGING`, `PROD`. |
| `service_key` | `varchar(63)` | x | `''` | Mã dịch vụ; chuỗi rỗng là bộ đếm cả nền tảng. |
| `period` | `varchar(5)` | x |  | Giá trị: `HOUR`, `DAY`, `MONTH`. |
| `bucket_start` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `used` | `bigint` | x | `0` |  |
| `denied` | `bigint` | x | `0` |  |
| `limit_snapshot` | `bigint` |  |  | Hạn mức hiệu lực lúc ghi; giữ để báo cáo đúng khi hạn mức đổi sau đó. |
| `reset_at` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `last_warned_level` | `smallint` | x | `0` | Ngưỡng cảnh báo đã phát trong chu kỳ: 0 chưa, 1 là 70%, 2 là 85%, 3 là 95% (14.quota.warn-levels); tránh phát EVT-14-07 lặp. |
| `synced_at` | `timestamptz` | x | `now()` | Thời điểm (T-TS, lưu UTC). |

: Cột của bảng `quota_usage`

### 3.18. `cache_stats`

::: dac-ta
**Mục đích.** Thống kê đệm tổng hợp theo giờ và dịch vụ, ghi từ EVT-14-11 (FR-14-035, 036, 037, 057). Phân vùng tháng, giữ 13 tháng (đủ so sánh cùng kỳ năm trước; chủ đầu tư chốt 27/11/2026). Tỷ lệ trúng đệm = hits / (hits + misses) (NFR-14-005).

**FR phục vụ.** FR-14-035, 036, 037, 057.

**Khóa chính.** (tenant_id, service_code, hour_start).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_cache_stats_tenant`, `ck_cache_stats_counts`, `ck_cache_stats_hour`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_cache_stats_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Phân vùng RANGE theo tháng trên `hour_start` (thủ tục `p_ensure_month_partitions`); Lưu giữ 13 tháng (chủ đầu tư chốt 27/11/2026), DETACH phân vùng quá hạn.

**Ghi chú.** Khóa tự nhiên (tenant, dịch vụ, giờ); không có `id`, `version`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `service_code` | `varchar(63)` | x |  |  |
| `hour_start` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `hits` | `bigint` | x | `0` |  |
| `misses` | `bigint` | x | `0` |  |
| `stale_served` | `bigint` | x | `0` |  |
| `invalidations` | `integer` | x | `0` |  |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |

: Cột của bảng `cache_stats`

### 3.19. `async_request`

::: dac-ta
**Mục đích.** EN-14-13 Yêu cầu gọi bất đồng bộ (FR-14-016, 038). Kafka là nguồn sự thật của việc chấp nhận, bảng là bản dẫn xuất do AsyncStateConsumer ghi lũy đẳng theo id. Thao tác ghi bắt buộc Idempotency-Key ULID (BR-14-030). Giữ 90 ngày sau khi kết thúc (chủ đầu tư chốt 27/11/2026), siêu dữ liệu giao dịch nằm ở national_transaction 5 năm.

**FR phục vụ.** FR-14-016, 038.

**Khóa chính.** (id).

**Duy nhất.** `uq_async_request_idempotency` (tenant_id, system_code, idempotency_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_async_request_tenant`, `ck_async_request_priority`, `ck_async_request_state`, `ck_async_request_key`, `ck_async_request_hash`, `ck_async_request_attempts`, `ck_async_request_expiry`, `ck_async_request_final`, `ck_async_request_cancelled`, `ck_async_request_result_ref`.

**Chỉ mục.** `ix_async_request_open` (tenant_id, state, accepted_at) khi state IN ('QUEUED', 'SENDING'), `ix_async_request_unknown` (tenant_id, accepted_at) khi state = 'UNKNOWN_RESULT', `ix_async_request_system` (tenant_id, system_code, accepted_at DESC), `ix_async_request_expiry` (finished_at) khi finished_at IS NOT NULL.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_async_request_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ 90 ngày sau khi kết thúc (chủ đầu tư chốt 27/11/2026), tác vụ dọn xóa theo `finished_at`.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | requestId trả cho HTTT; khóa Kafka của hàng chờ. |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `service_code` | `varchar(63)` | x |  |  |
| `operation` | `varchar(63)` |  |  |  |
| `system_code` | `varchar(64)` | x |  |  |
| `purpose_code` | `varchar(64)` |  |  |  |
| `procedure_code` | `varchar(64)` |  |  |  |
| `case_code` | `varchar(128)` |  |  |  |
| `priority` | `varchar(10)` | x |  | Giá trị: `ESSENTIAL`, `NORMAL`, `BACKGROUND`. |
| `state` | `varchar(16)` | x | `'QUEUED'` | UNKNOWN_RESULT: quá hạn chờ với thao tác ghi, không tự gửi lại mà đối soát trước (BR-14-030). |
| `attempts` | `smallint` | x | `0` |  |
| `idempotency_key` | `char(26)` | x |  | Mẫu: `^[0-9A-HJKMNP-TV-Z]{26}$`. |
| `payload_hash` | `char(64)` | x |  | SHA-256 nội dung yêu cầu để phát hiện cùng khóa khác nội dung (ERR-14-116); không lưu nội dung. |
| `transaction_code` | `varchar(40)` |  |  |  |
| `result_ref` | `varchar(255)` |  |  | Khóa đối tượng kết quả mã hóa trong dh-nat-payload dạng {tenant}/async/{id}.res.enc, giữ 72 giờ. |
| `error_code` | `varchar(16)` |  |  |  |
| `accepted_at` | `timestamptz` | x | `now()` | Thời điểm (T-TS, lưu UTC). |
| `not_before` | `timestamptz` |  |  |  |
| `expires_at` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `last_attempt_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `finished_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `cancelled_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `async_request`

### 3.20. `inbound_endpoint`

::: dac-ta
**Mục đích.** EN-14-09 Điểm cuối chiều vào do tenant đăng ký với trung ương (FR-14-039, 040, 041). Mã bắt buộc kết thúc bằng -{tenant} nên duy nhất toàn cụm mà không cần chỉ mục chéo tenant: tenant được xác định từ điểm cuối, không từ nội dung bản tin (BR-14-027).

**FR phục vụ.** FR-14-039, 040, 041.

**Khóa chính.** (id).

**Duy nhất.** `uq_inbound_endpoint_code` (tenant_id, code).

**Khóa ngoại.** (platform_id, tenant_id) → `national_platform`.

**Ràng buộc CHECK.** `ck_inbound_endpoint_tenant`, `ck_inbound_endpoint_code`, `ck_inbound_endpoint_unsigned`, `ck_inbound_endpoint_rate`, `ck_inbound_endpoint_size`, `ck_inbound_endpoint_state`, `ck_inbound_endpoint_active`, `ck_inbound_endpoint_four_eyes`, `ck_inbound_endpoint_retired`.

**Chỉ mục.** `ix_inbound_endpoint_platform` (tenant_id, platform_id, state).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_inbound_endpoint_*` (mục 1.2).

**Phân vùng, chỉ thêm.** RETIRED là trạng thái cuối, không đảo ngược, không dùng lại mã (trigger `tg_inbound_endpoint_retired`); Chỉ ACTIVE khi có nguồn được phép đang bật và tuyến tới luồng PH-04 (ERR-14-024, 039) (trigger `tg_inbound_endpoint_enable`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `code` | `varchar(63)` | x |  | Mẫu: `^[a-z][a-z0-9-]{2,62}$`. |
| `platform_id` | `uuid` | x |  |  |
| `path` | `varchar(80)` | x | `sinh: '/inbound/v1/' \|\| code` | Đường dẫn công bố /inbound/v1/{code}; cột sinh tự động. |
| `signature_required` | `boolean` | x | `true` | false chỉ khi SO đồng ý và có lý do ≥ 10 ký tự (ck_inbound_endpoint_unsigned). |
| `unsigned_reason` | `varchar(500)` |  |  |  |
| `unsigned_approved_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `rate_limit_per_second` | `integer` |  |  | Miền: 1 đến 500. |
| `max_message_kb` | `integer` | x | `512` | Miền: 1 đến 2048. |
| `state` | `varchar(20)` | x | `'DRAFT'` | Giá trị: `DRAFT`, `PENDING_ACTIVATION`, `ACTIVE`, `SUSPENDED`, `RETIRED`. |
| `state_reason` | `varchar(1000)` |  |  |  |
| `activation_requested_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `activation_approved_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `activation_approved_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `retired_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `inbound_endpoint`

### 3.21. `allowed_sender`

::: dac-ta
**Mục đích.** Nguồn được phép gọi vào một điểm cuối: mã đơn vị gửi theo văn bản trung ương, vân tay SHA-256 chứng thư mTLS, danh sách dịch vụ INBOUND được gọi (FR-14-039). Danh sách đi vào ảnh chụp và bộ lọc ở APISIX (EVT-14-13).

**FR phục vụ.** FR-14-039, 040.

**Khóa chính.** (id).

**Duy nhất.** `uq_allowed_sender_code` (tenant_id, endpoint_id, sender_code), `uq_allowed_sender_fingerprint` (tenant_id, endpoint_id, cert_fingerprint).

**Khóa ngoại.** (endpoint_id, tenant_id) → `inbound_endpoint` (xóa theo).

**Ràng buộc CHECK.** `ck_allowed_sender_tenant`, `ck_allowed_sender_fingerprint`, `ck_allowed_sender_services`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_allowed_sender_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `endpoint_id` | `uuid` | x |  |  |
| `sender_code` | `varchar(64)` | x |  |  |
| `cert_fingerprint` | `char(64)` | x |  | Mẫu: `^[0-9a-f]{64}$`. |
| `service_codes` | `text[]` | x |  | Mã dịch vụ direction = INBOUND; kiểm tồn tại ở dịch vụ, không khóa ngoại mảng. |
| `enabled` | `boolean` | x | `true` |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `allowed_sender`

### 3.22. `inbound_route`

::: dac-ta
**Mục đích.** Ánh xạ (điểm cuối, dịch vụ chiều vào) tới luồng PH-04 đã phát hành (FR-14-041). flow_code tham chiếu theo mã sang schema của PH-04, không khóa ngoại; kiểm đã phát hành ở dịch vụ (ERR-14-039).

**FR phục vụ.** FR-14-041.

**Khóa chính.** (id).

**Duy nhất.** `uq_inbound_route` (tenant_id, endpoint_id, service_code).

**Khóa ngoại.** (endpoint_id, tenant_id) → `inbound_endpoint` (xóa theo).

**Ràng buộc CHECK.** `ck_inbound_route_tenant`, `ck_inbound_route_flow`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_inbound_route_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `endpoint_id` | `uuid` | x |  |  |
| `service_code` | `varchar(63)` | x |  |  |
| `flow_code` | `varchar(63)` | x |  | Mẫu: `^[a-z][a-z0-9-]{2,62}$`. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `inbound_route`

### 3.23. `sync_run`

::: dac-ta
**Mục đích.** EN-14-10 Phiên đồng bộ danh mục dịch vụ, dữ liệu chủ, dữ liệu mở (FR-14-043, 044, 045, 046). Mỗi (tenant, loại) tối đa một phiên chưa kết thúc (ERR-14-026). Đối soát: gửi = nhận + từ chối + chờ; error_count là phần lỗi kỹ thuật nằm trong rejected. Giữ 3 năm. Phiên đối chiếu danh mục (SERVICE_RECONCILE) lưu ở reconcile_run.

**FR phục vụ.** FR-14-043, 044, 045, 046.

**Khóa chính.** (id).

**Duy nhất.** `uq_sync_run_open` (tenant_id, kind) khi state IN ('PLANNED', 'RUNNING').

**Khóa ngoại.** (platform_id, tenant_id) → `national_platform`.

**Ràng buộc CHECK.** `ck_sync_run_tenant`, `ck_sync_run_kind`, `ck_sync_run_trigger`, `ck_sync_run_state`, `ck_sync_run_batch`, `ck_sync_run_counts`, `ck_sync_run_reconcile`, `ck_sync_run_completed`, `ck_sync_run_retry`, `ck_sync_run_finished`.

**Chỉ mục.** `ix_sync_run_kind` (tenant_id, kind, created_at DESC), `ix_sync_run_success` (tenant_id, kind, finished_at DESC) khi state IN ('COMPLETED', 'COMPLETED_WITH_ERRORS').

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_sync_run_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ 3 năm (EN-14-10), tác vụ dọn xóa phiên quá hạn (kéo theo sync_record).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `platform_id` | `uuid` | x |  |  |
| `kind` | `varchar(16)` | x |  | Giá trị: `SERVICE_CATALOG`, `MASTER_DATA`, `OPEN_DATA`. |
| `trigger_kind` | `varchar(10)` | x |  | Giá trị: `SCHEDULE`, `EVENT`, `MANUAL`, `RETRY`. |
| `state` | `varchar(24)` | x | `'PLANNED'` | Giá trị: `PLANNED`, `RUNNING`, `COMPLETED`, `COMPLETED_WITH_ERRORS`, `FAILED`. |
| `dry_run` | `boolean` | x | `false` |  |
| `only_changed` | `boolean` | x | `true` |  |
| `batch_ref` | `varchar(255)` |  |  | Khóa đối tượng lô bản ghi trong bucket dh-nat-sync, bắt đầu bằng tiền tố tenant. |
| `command_id` | `uuid` |  |  |  |
| `retry_of` | `uuid` |  |  | Phiên gốc khi thử lại chỉ các bản ghi lỗi (tối đa 14.sync.max-retries). |
| `attempt` | `smallint` | x | `1` |  |
| `sent` | `integer` | x | `0` |  |
| `accepted` | `integer` | x | `0` |  |
| `rejected` | `integer` | x | `0` |  |
| `pending` | `integer` | x | `0` |  |
| `error_count` | `integer` | x | `0` |  |
| `error_summary` | `varchar(1000)` |  |  |  |
| `triggered_by` | `varchar(64)` | x |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `started_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `finished_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `sync_run`

### 3.24. `sync_record`

::: dac-ta
**Mục đích.** Kết quả từng bản ghi trong một phiên đồng bộ: nhận, từ chối, lỗi, kèm biên nhận để đối soát (FR-14-043, 046). content_hash dùng chọn bản ghi mới hoặc đổi (onlyChanged). Xóa theo phiên khi quá 3 năm.

**FR phục vụ.** FR-14-043, 046.

**Khóa chính.** (id).

**Duy nhất.** `uq_sync_record` (tenant_id, run_id, record_ref).

**Khóa ngoại.** (run_id, tenant_id) → `sync_run` (xóa theo).

**Ràng buộc CHECK.** `ck_sync_record_tenant`, `ck_sync_record_kind`, `ck_sync_record_hash`, `ck_sync_record_outcome`, `ck_sync_record_attempts`.

**Chỉ mục.** `ix_sync_record_outcome` (tenant_id, run_id, outcome) khi outcome <> 'ACCEPTED', `ix_sync_record_ref` (tenant_id, record_kind, record_ref, created_at DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_sync_record_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ Xóa theo phiên khi quá 3 năm (khóa ngoại ON DELETE CASCADE).

**Ghi chú.** Không có cột người tạo, sửa vì bản ghi do worker sinh qua Kafka; có `version` cho ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `run_id` | `uuid` | x |  |  |
| `record_kind` | `varchar(14)` | x |  | Giá trị: `SERVICE`, `MASTER_RECORD`, `DATASET`. |
| `record_ref` | `varchar(128)` | x |  | Mã dịch vụ chia sẻ, khóa bản ghi dữ liệu chủ hoặc mã tập dữ liệu mở; không chứa dữ liệu cá nhân. |
| `content_hash` | `char(64)` | x |  | Mẫu: `^[0-9a-f]{64}$`. |
| `outcome` | `varchar(16)` | x | `'PENDING'` | Giá trị: `PENDING`, `ACCEPTED`, `REJECTED`, `REJECTED_LOCAL`, `ERROR`. |
| `receipt_ref` | `varchar(128)` |  |  |  |
| `error_code` | `varchar(16)` |  |  |  |
| `error_message` | `varchar(500)` |  |  |  |
| `attempts` | `smallint` | x | `0` |  |
| `last_attempt_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `sync_record`

### 3.25. `national_transaction`

::: dac-ta
**Mục đích.** EN-14-08 Sổ giao dịch quốc gia: mỗi lượt gọi ra hoặc nhận vào một dòng với mã đối soát, mục đích, mã hồ sơ, kết quả ký, xác minh (FR-14-010, 049, 050, 051, 052; BR-14-020). Chỉ siêu dữ liệu, không có nội dung hay định danh thô (BR-14-021). Phân vùng tháng theo started_at; 12 tháng trực tuyến rồi xuất WORM 5 năm trước khi tháo phân vùng (SEC-62). Không xóa dòng; chỉ chuyển trạng thái tiến (UPSERT của LedgerConsumer).

**FR phục vụ.** FR-14-010, 049, 050, 051, 052.

**Khóa chính.** (tenant_id, transaction_code, started_at).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_national_transaction_tenant`, `ck_national_transaction_code`, `ck_national_transaction_direction`, `ck_national_transaction_optype`, `ck_national_transaction_state`, `ck_national_transaction_unknown`, `ck_national_transaction_cache`, `ck_national_transaction_duration`, `ck_national_transaction_sign`, `ck_national_transaction_sigfail`, `ck_national_transaction_trace`, `ck_national_transaction_payload`, `ck_national_transaction_lookup`, `ck_national_transaction_finished`.

**Chỉ mục.** `ix_national_transaction_started` (tenant_id, started_at DESC), `ix_national_transaction_code` (tenant_id, transaction_code), `ix_national_transaction_system` (tenant_id, system_code, started_at DESC), `ix_national_transaction_service` (tenant_id, service_code, started_at DESC), `ix_national_transaction_case` (tenant_id, case_code, started_at DESC) khi case_code IS NOT NULL, `ix_national_transaction_unknown` (tenant_id, started_at) khi state = 'UNKNOWN_RESULT', `ix_national_transaction_lookup` (tenant_id, system_code, started_at DESC) khi lookup_key_hash IS NOT NULL, `ix_national_transaction_trace` (trace_id).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_national_transaction_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Phân vùng RANGE theo tháng trên `started_at` (thủ tục `p_ensure_month_partitions`); Lưu giữ 12 tháng trực tuyến rồi xuất WORM 5 năm kèm chuỗi băm (LedgerArchiver) trước khi DETACH (SEC-62); Chỉ chuyển trạng thái tiến theo hạng, chỉ cột kết quả được sửa, không xóa dòng (BR-14-020) (trigger `tg_national_transaction_forward`).

**Ghi chú.** Khóa UPSERT (`tenant_id`, `transaction_code`, `started_at`). `lookup_key_hash` không cấp cho `ph14_readonly`. Quyền cấp trên bảng cha, không cấp trên phân vùng.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `transaction_code` | `varchar(40)` | x |  | Mã giao dịch duy nhất, gửi trung ương làm mã đối soát; cùng started_at ổn định qua mọi bản ghi của giao dịch nên làm khóa UPSERT. |
| `started_at` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `direction` | `varchar(8)` | x |  | Giá trị: `OUTBOUND`, `INBOUND`. |
| `platform_code` | `varchar(63)` | x |  |  |
| `service_code` | `varchar(63)` | x |  |  |
| `operation` | `varchar(63)` |  |  |  |
| `operation_type` | `varchar(5)` | x |  | Giá trị: `READ`, `WRITE`. |
| `system_code` | `varchar(64)` | x |  | HTTT của tỉnh gọi (chiều ra) hoặc mã đơn vị gửi của trung ương (chiều vào); lấy từ token, không từ nội dung yêu cầu (BR-14-007). |
| `purpose_code` | `varchar(64)` |  |  |  |
| `procedure_code` | `varchar(64)` |  |  |  |
| `case_code` | `varchar(128)` |  |  |  |
| `state` | `varchar(20)` | x |  | Giá trị: `RECEIVED`, `REJECTED`, `COMPLETED_CACHE`, `QUOTA_EXCEEDED`, `SENT`, `SUCCEEDED`, `FAILED`, `TIMEOUT`, `SIGNATURE_FAILED`, `UNKNOWN_RESULT`. |
| `state_rank` | `smallint` | x | `sinh: ph14_national.f_txn_rank(state)` | Hạng tiến trình sinh từ state (RECEIVED 10 < SENT 20 < TIMEOUT 30 < UNKNOWN_RESULT 40 < trạng thái cuối 90); bản ghi hạng thấp hơn đến muộn bị bỏ. |
| `from_cache` | `boolean` | x | `false` |  |
| `stale` | `boolean` | x | `false` | true: phục vụ từ dữ liệu đệm quá hạn có cờ (BR-14-016); chỉ khi from_cache. |
| `routed_via` | `varchar(63)` |  |  |  |
| `duration_ms` | `integer` |  |  |  |
| `error_code` | `varchar(16)` |  |  |  |
| `cert_code` | `varchar(63)` |  |  |  |
| `sign_result` | `varchar(6)` | x | `'NA'` | Giá trị: `NA`, `OK`, `FAILED`. |
| `verify_result` | `varchar(6)` | x | `'NA'` | Giá trị: `NA`, `OK`, `FAILED`. |
| `trace_id` | `char(32)` | x |  | Mẫu: `^[0-9a-f]{32}$`. |
| `payload_ref` | `varchar(255)` |  |  | Khóa đối tượng nội dung mã hóa ở dh-nat-payload dạng {tenant}/{yyyy}/{MM}/{code}.req.enc; rỗng khi không lưu hoặc hàng đệm đầy (ERR-14-031). |
| `payload_hash` | `char(64)` |  |  | Mẫu: `^[0-9a-f]{64}$`. |
| `lookup_key_hash` | `char(64)` |  |  | HMAC-SHA256 định danh đối tượng được tra bằng khóa tenant, để đếm đối tượng khác nhau mà không lưu định danh (SEC-60, THR-54, FR-14-053); không cấp cho ph14_readonly. |
| `idempotency_key` | `varchar(64)` |  |  |  |
| `finished_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `ingested_at` | `timestamptz` | x | `now()` | Thời điểm (T-TS, lưu UTC). |

: Cột của bảng `national_transaction`

### 3.26. `usage_hourly`

::: dac-ta
**Mục đích.** Tổng hợp lượt gọi theo (giờ, HTTT, dịch vụ, mục đích, kết quả, nguồn đệm) cho báo cáo sử dụng và đường chuẩn phát hiện bất thường (FR-14-052, 053, 057). UsageAggregator chỉ cộng khi dòng giao dịch vừa được chèn nên đúng cả khi Kafka giao lại. Phân vùng tháng, giữ 24 tháng (khớp mức dùng hạn mức 2 năm NFR-14-021; chủ đầu tư chốt 27/11/2026).

**FR phục vụ.** FR-14-033, 052, 053, 057.

**Khóa chính.** (tenant_id, hour_start, system_code, service_code, purpose_code, outcome, from_cache).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_usage_hourly_tenant`, `ck_usage_hourly_hour`, `ck_usage_hourly_outcome`, `ck_usage_hourly_counts`.

**Chỉ mục.** `ix_usage_hourly_system` (tenant_id, system_code, hour_start DESC), `ix_usage_hourly_service` (tenant_id, service_code, hour_start DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_usage_hourly_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Phân vùng RANGE theo tháng trên `hour_start` (thủ tục `p_ensure_month_partitions`); Lưu giữ 24 tháng (chủ đầu tư chốt 27/11/2026), DETACH phân vùng quá hạn.

**Ghi chú.** Khóa tự nhiên; chỉ cộng dồn khi dòng giao dịch vừa được chèn mới (đúng khi Kafka giao lại).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `hour_start` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `system_code` | `varchar(64)` | x |  |  |
| `service_code` | `varchar(63)` | x |  |  |
| `purpose_code` | `varchar(64)` | x | `''` | Chuỗi rỗng khi lượt không khai mục đích (bị từ chối); là một phần khóa nên không dùng NULL. |
| `outcome` | `varchar(20)` | x |  | Giá trị: `REJECTED`, `COMPLETED_CACHE`, `QUOTA_EXCEEDED`, `SUCCEEDED`, `FAILED`, `TIMEOUT`, `SIGNATURE_FAILED`, `UNKNOWN_RESULT`. |
| `from_cache` | `boolean` | x | `false` |  |
| `calls` | `bigint` | x | `0` |  |
| `stale_calls` | `bigint` | x | `0` |  |
| `duration_sum_ms` | `bigint` | x | `0` |  |
| `duration_max_ms` | `integer` | x | `0` |  |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |

: Cột của bảng `usage_hourly`

### 3.27. `health_sample`

::: dac-ta
**Mục đích.** Mẫu kiểm tra kết nối chủ động, thụ động hoặc thủ công theo từng bước DNS, TCP, TLS, token, deep (FR-14-047, 048). Giữ 90 ngày, gộp theo giờ (granularity HOUR) sau 7 ngày bởi HealthRollupJob; DETACH phân vùng quá hạn. Không có bí mật hay token.

**FR phục vụ.** FR-14-047, 048.

**Khóa chính.** (tenant_id, platform_id, env, granularity, probe_kind, sampled_at).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_health_sample_tenant`, `ck_health_sample_env`, `ck_health_sample_granularity`, `ck_health_sample_kind`, `ck_health_sample_level`, `ck_health_sample_step`, `ck_health_sample_ok`, `ck_health_sample_counts`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_health_sample_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Phân vùng RANGE theo tháng trên `sampled_at` (thủ tục `p_ensure_month_partitions`); Lưu giữ 90 ngày, gộp theo giờ sau 7 ngày (HealthRollupJob), DETACH phân vùng quá hạn.

**Ghi chú.** Khóa tự nhiên; không khóa ngoại để phân vùng tháng tháo gọn.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `platform_id` | `uuid` | x |  |  |
| `env` | `varchar(8)` | x |  | Giá trị: `TEST`, `STAGING`, `PROD`. |
| `granularity` | `varchar(6)` | x | `'MINUTE'` | Giá trị: `MINUTE`, `HOUR`. |
| `probe_kind` | `varchar(8)` | x |  | Giá trị: `ACTIVE`, `PASSIVE`, `MANUAL`. |
| `sampled_at` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `ok` | `boolean` | x |  |  |
| `level` | `varchar(10)` | x |  | Giá trị: `HEALTHY`, `DEGRADED`, `UNHEALTHY`, `UNKNOWN`. |
| `failed_step` | `varchar(5)` |  |  | Giá trị: `DNS`, `TCP`, `TLS`, `TOKEN`, `DEEP`. |
| `dns_ms` | `integer` |  |  |  |
| `tcp_ms` | `integer` |  |  |  |
| `tls_ms` | `integer` |  |  |  |
| `token_ms` | `integer` |  |  |  |
| `deep_ms` | `integer` |  |  |  |
| `tls_server_not_after` | `timestamptz` |  |  | Hạn chứng thư máy chủ của nền tảng quan sát ở bước TLS, để cảnh báo trước khi trung ương đổi chứng thư. |
| `calls_ok` | `integer` | x | `0` |  |
| `calls_error` | `integer` | x | `0` |  |
| `p95_ms` | `integer` |  |  |  |

: Cột của bảng `health_sample`

### 3.28. `health_state`

::: dac-ta
**Mục đích.** Mức sức khỏe hiện hành của mỗi (nền tảng, môi trường) do HealthStateStore ghi từ kết quả của worker (FR-14-047, 048); chống dao động bằng consecutive_failures (hai chu kỳ để xuống UNHEALTHY, một chu kỳ để lên). Dùng cho UI-14-01, 02.

**FR phục vụ.** FR-14-047, 048.

**Khóa chính.** (tenant_id, platform_id, env).

**Duy nhất.** Không.

**Khóa ngoại.** (platform_id, tenant_id) → `national_platform`.

**Ràng buộc CHECK.** `ck_health_state_tenant`, `ck_health_state_env`, `ck_health_state_level`, `ck_health_state_failures`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_health_state_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Một dòng cho mỗi (nền tảng, môi trường); không có `id`, `version`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `platform_id` | `uuid` | x |  |  |
| `env` | `varchar(8)` | x |  | Giá trị: `TEST`, `STAGING`, `PROD`. |
| `level` | `varchar(10)` | x | `'UNKNOWN'` | Giá trị: `HEALTHY`, `DEGRADED`, `UNHEALTHY`, `UNKNOWN`. |
| `since_at` | `timestamptz` | x | `now()` | Thời điểm (T-TS, lưu UTC). |
| `last_probe_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `last_ok_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `consecutive_failures` | `smallint` | x | `0` |  |
| `reason` | `varchar(255)` |  |  |  |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |

: Cột của bảng `health_state`

### 3.29. `platform_outage`

::: dac-ta
**Mục đích.** Khoảng gián đoạn của nền tảng (OutageRecorder) để tính sẵn sàng 99,9% (NFR-14-008) và báo cáo cho lãnh đạo (FR-14-048). Thời gian nền tảng quốc gia ngừng không tính vào chỉ tiêu của Datahub. Giữ 3 năm (giả định).

**FR phục vụ.** FR-14-047, 048.

**Khóa chính.** (id).

**Duy nhất.** `uq_platform_outage_open` (tenant_id, platform_id, env, cause) khi ended_at IS NULL.

**Khóa ngoại.** (platform_id, tenant_id) → `national_platform`.

**Ràng buộc CHECK.** `ck_platform_outage_tenant`, `ck_platform_outage_env`, `ck_platform_outage_cause`, `ck_platform_outage_range`.

**Chỉ mục.** `ix_platform_outage_platform` (tenant_id, platform_id, env, started_at DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_platform_outage_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ 3 năm (giả định).

**Ghi chú.** Không có cột sửa; `duration_seconds` là cột sinh từ `started_at`, `ended_at`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `platform_id` | `uuid` | x |  |  |
| `env` | `varchar(8)` | x |  | Giá trị: `TEST`, `STAGING`, `PROD`. |
| `cause` | `varchar(14)` | x |  | Giá trị: `PROBE`, `PASSIVE`, `SECURITY_HOLD`, `MANUAL_SUSPEND`. |
| `started_at` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `ended_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `duration_seconds` | `integer` | x | `sinh: extract(epoch FROM (ended_at - started_at))::integer` |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |

: Cột của bảng `platform_outage`

### 3.30. `anomaly_alert`

::: dac-ta
**Mục đích.** EN-14-14 Cảnh báo khai thác bất thường: tra hàng loạt, ngoài giờ, tăng đột biến, một hồ sơ tra nhiều đối tượng (FR-14-053, THR-51). Mỗi (HTTT, dịch vụ, luật) tối đa một cảnh báo OPEN. Kết thúc cần quyết định và lý do ≥ 10 ký tự (ERR-14-003). Giữ 5 năm, không xóa. Bằng chứng chỉ gồm số liệu và mã giao dịch mẫu, không có định danh đối tượng.

**FR phục vụ.** FR-14-053.

**Khóa chính.** (id).

**Duy nhất.** `uq_anomaly_alert_open` (tenant_id, system_code, service_code, rule) khi state = 'OPEN'.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_anomaly_alert_tenant`, `ck_anomaly_alert_rule`, `ck_anomaly_alert_window`, `ck_anomaly_alert_evidence`, `ck_anomaly_alert_state`, `ck_anomaly_alert_decision`, `ck_anomaly_alert_resolved`, `ck_anomaly_alert_reason`.

**Chỉ mục.** `ix_anomaly_alert_time` (tenant_id, detected_at DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_anomaly_alert_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ 5 năm (EN-14-14), không xóa; Cột bất biến sau INSERT: `system_code`, `service_code`, `rule`, `window_start`, `window_end`, `detected_at` (trigger `tg_anomaly_alert_immutable`); Không cho xóa dòng (trigger `tg_anomaly_alert_nodelete`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `system_code` | `varchar(64)` | x |  |  |
| `service_code` | `varchar(63)` | x |  |  |
| `rule` | `varchar(16)` | x |  | Giá trị: `MASS_LOOKUP`, `OFF_HOURS`, `SPIKE`, `CASE_FANOUT`. |
| `window_start` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `window_end` | `timestamptz` | x |  |  |
| `evidence` | `jsonb` | x | `'{}'` | Số liệu tóm tắt và danh sách mã giao dịch mẫu; CHECK chặn các khóa định danh thô. |
| `state` | `varchar(8)` | x | `'OPEN'` | Giá trị: `OPEN`, `RESOLVED`. |
| `decision` | `varchar(24)` |  |  | Giá trị: `CONFIRMED_LEGITIMATE`, `REVOKE_REQUESTED`, `SERVICE_BLOCKED`. |
| `decision_reason` | `varchar(1000)` |  |  |  |
| `decided_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `decided_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `detected_at` | `timestamptz` | x | `now()` | Thời điểm (T-TS, lưu UTC). |
| `notified_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `anomaly_alert`

### 3.31. `anomaly_waiver`

::: dac-ta
**Mục đích.** Cửa sổ "đã báo trước" do TA khai để luật phát hiện bỏ qua, ví dụ đợt đối chiếu cuối tháng (FR-14-053). Tối đa 31 ngày mỗi cửa sổ (giả định), có lý do.

**FR phục vụ.** FR-14-053.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_anomaly_waiver_tenant`, `ck_anomaly_waiver_range`, `ck_anomaly_waiver_reason`.

**Chỉ mục.** `ix_anomaly_waiver_scope` (tenant_id, system_code, service_code, valid_to).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_anomaly_waiver_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `system_code` | `varchar(64)` | x |  |  |
| `service_code` | `varchar(63)` | x |  |  |
| `valid_from` | `timestamptz` | x |  |  |
| `valid_to` | `timestamptz` | x |  |  |
| `reason` | `varchar(500)` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `anomaly_waiver`

### 3.32. `access_block`

::: dac-ta
**Mục đích.** Danh sách chặn blocks[] của ảnh chụp cấu hình: quyết định "tạm dừng dịch vụ cho HTTT đó" của SO khi xử lý cảnh báo; PurposeStage từ chối lượt khớp với ERR-14-106 sau tối đa 30 giây (FR-14-053). Hết hạn tự động theo expires_at; mỗi (HTTT, dịch vụ) tối đa một mục đang hiệu lực.

**FR phục vụ.** FR-14-053.

**Khóa chính.** (id).

**Duy nhất.** `uq_access_block_active` (tenant_id, system_code, service_code) khi lifted_at IS NULL.

**Khóa ngoại.** (source_alert_id, tenant_id) → `anomaly_alert`.

**Ràng buộc CHECK.** `ck_access_block_tenant`, `ck_access_block_reason`, `ck_access_block_expiry`, `ck_access_block_lifted`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_access_block_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `system_code` | `varchar(64)` | x |  |  |
| `service_code` | `varchar(63)` | x |  |  |
| `reason` | `varchar(1000)` | x |  |  |
| `source_alert_id` | `uuid` |  |  |  |
| `expires_at` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `lifted_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `lifted_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `access_block`

### 3.33. `parallel_run`

::: dac-ta
**Mục đích.** EN-14-15 Phiên chạy song song đường mới với kết nối NGSP cũ, chỉ thao tác đọc (FR-14-055, BR-14-033). Mỗi dịch vụ tối đa một phiên RUNNING. Đóng phiên chỉ khi đã xác nhận thu hồi khóa cũ ở trung ương (BR-14-034, ERR-14-004). Khác biệt chỉ để cảnh báo, không bao giờ tự sửa kết quả.

**FR phục vụ.** FR-14-055.

**Khóa chính.** (id).

**Duy nhất.** `uq_parallel_run_running` (tenant_id, service_code) khi state = 'RUNNING'.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_parallel_run_tenant`, `ck_parallel_run_ratio`, `ck_parallel_run_source`, `ck_parallel_run_state`, `ck_parallel_run_counts`, `ck_parallel_run_ready`, `ck_parallel_run_closed`, `ck_parallel_run_revocation`.

**Chỉ mục.** `ix_parallel_run_service` (tenant_id, service_code, start_at DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_parallel_run_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Chỉ tạo phiên cho dịch vụ thao tác đọc (ERR-14-033, BR-14-033) (trigger `tg_parallel_run_read_only`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `service_code` | `varchar(63)` | x |  |  |
| `sample_ratio` | `numeric(5,4)` | x | `0.1` |  |
| `ignore_fields` | `text[]` | x | `'{}'` |  |
| `observation_source` | `varchar(10)` | x | `'PH04_FLOW'` | Giá trị: `PH04_FLOW`. |
| `state` | `varchar(8)` | x | `'RUNNING'` | Giá trị: `RUNNING`, `STOPPED`, `CLOSED`. |
| `start_at` | `timestamptz` | x | `now()` | Thời điểm (T-TS, lưu UTC). |
| `samples` | `bigint` | x | `0` |  |
| `matched` | `bigint` | x | `0` |  |
| `match_ratio` | `numeric` | x | `sinh: CASE WHEN samples > 0 THEN round(matched::numeric / samples, 5) END` | Tỷ lệ khớp = matched / samples, cột sinh tự động; ngưỡng 14.parallel.match-ratio xét ở ParallelRunService theo từng ngày. |
| `consecutive_ok_days` | `smallint` | x | `0` |  |
| `ready_for_cutover` | `boolean` | x | `false` | Đạt tỷ lệ khớp liên tục 14.parallel.min-days ngày với ≥ 14.parallel.min-samples mẫu (CSDL chỉ chặn dưới 100 mẫu, bằng cận dưới của tham số). |
| `ready_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `old_key_revocation_confirmed` | `boolean` | x | `false` |  |
| `closed_by` | `varchar(64)` |  |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `closed_at` | `timestamptz` |  |  | Thời điểm (T-TS, lưu UTC). |
| `close_reason` | `varchar(500)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `parallel_run`

### 3.34. `parallel_sample`

::: dac-ta
**Mục đích.** Mẫu so sánh hai đường: khớp, khác ở trường nào, lỗi một bên (FR-14-055). Chỉ lưu băm trường và đường dẫn trường khác nhau, không bao giờ lưu nội dung dữ liệu cá nhân (SDD §4.19). Giữ 90 ngày, dọn bằng DETACH phân vùng.

**FR phục vụ.** FR-14-055.

**Khóa chính.** (tenant_id, run_id, sample_id, sampled_at).

**Duy nhất.** Không.

**Khóa ngoại.** (run_id, tenant_id) → `parallel_run`.

**Ràng buộc CHECK.** `ck_parallel_sample_tenant`, `ck_parallel_sample_outcome`, `ck_parallel_sample_diff`, `ck_parallel_sample_hash`, `ck_parallel_sample_trace`.

**Chỉ mục.** `ix_parallel_sample_run` (tenant_id, run_id, sampled_at DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_parallel_sample_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Phân vùng RANGE theo tháng trên `sampled_at` (thủ tục `p_ensure_month_partitions`); Lưu giữ 90 ngày (FR-14-055), DETACH phân vùng quá hạn.

**Ghi chú.** Chỉ lưu băm và đường dẫn trường khác biệt, không lưu nội dung dữ liệu cá nhân.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `run_id` | `uuid` | x |  |  |
| `sample_id` | `uuid` | x |  |  |
| `sampled_at` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `outcome` | `varchar(10)` | x |  | Giá trị: `MATCH`, `DIFF`, `ERROR_NEW`, `ERROR_OLD`, `ERROR_BOTH`. |
| `diff_paths` | `text[]` | x | `'{}'` |  |
| `new_hash` | `char(64)` |  |  | Mẫu: `^[0-9a-f]{64}$`. |
| `old_hash` | `char(64)` |  |  | Mẫu: `^[0-9a-f]{64}$`. |
| `trace_id` | `char(32)` |  |  | Mẫu: `^[0-9a-f]{32}$`. |

: Cột của bảng `parallel_sample`

### 3.35. `legacy_import`

::: dac-ta
**Mục đích.** Lần nhập cấu hình dịch vụ từ phụ lục NGSP của hệ cũ (CSV, XLSX), tất cả hoặc không: một dòng sai thì không dịch vụ nào được tạo (FR-14-056, ERR-14-032). findings ghi vị trí (dòng, cột) cột chứa bí mật đã bỏ qua, không bao giờ ghi giá trị (BR-14-034). Giữ 3 năm (giả định).

**FR phục vụ.** FR-14-056.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (platform_id, tenant_id) → `national_platform`.

**Ràng buộc CHECK.** `ck_legacy_import_tenant`, `ck_legacy_import_hash`, `ck_legacy_import_mode`, `ck_legacy_import_duplicate`, `ck_legacy_import_state`, `ck_legacy_import_counts`, `ck_legacy_import_all_or_nothing`, `ck_legacy_import_findings`.

**Chỉ mục.** `ix_legacy_import_platform` (tenant_id, platform_id, created_at DESC).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên; chính sách `rls_legacy_import_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ 3 năm (giả định).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}`; khóa RLS và khóa ngoại kép. |
| `platform_id` | `uuid` | x |  |  |
| `file_name` | `varchar(255)` | x |  |  |
| `file_sha256` | `char(64)` | x |  | Mẫu: `^[0-9a-f]{64}$`. |
| `mode` | `varchar(7)` | x |  | Giá trị: `PREVIEW`, `APPLY`. |
| `on_duplicate` | `varchar(16)` | x | `'SKIP'` | Giá trị: `SKIP`, `OVERWRITE_DRAFT`. |
| `state` | `varchar(10)` | x |  | APPLIED khi mode APPLY và rows_error = 0 (ck_legacy_import_all_or_nothing); REJECTED khi APPLY có dòng lỗi. |
| `rows_total` | `integer` | x | `0` |  |
| `rows_created` | `integer` | x | `0` |  |
| `rows_skipped` | `integer` | x | `0` |  |
| `rows_error` | `integer` | x | `0` |  |
| `findings` | `jsonb` | x | `'{}'` |  |
| `imported_by` | `varchar(64)` | x |  | Mã người dùng thực hiện (hoặc `system:*`). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `legacy_import`

### 3.36. `outbox`

::: dac-ta
**Mục đích.** Outbox (DD-11) cho EVT-14-01…06, 08, 09, 12, 13, 14, 16 và lệnh cho worker (worker.command), ghi cùng giao dịch với thay đổi miền (SDD §8.2). Debezium của pg-core hoặc bộ quét 500 ms đẩy lên Kafka; khóa phân vùng là mã đối tượng. Dọn sau 3 ngày. EVT-14-07, 10, 11, 15, 17 do cổng phát qua LedgerSpool, không qua bảng này. Payload không chứa bí mật, nội dung bản tin.

**FR phục vụ.** Mọi FR phát sự kiện EVT-14-01…06, 08, 09, 12, 13, 14, 16 và lệnh worker.

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_tenant`, `ck_outbox_type`, `ck_outbox_topic`, `ck_outbox_topic_tenant`, `ck_outbox_trace`, `ck_outbox_no_secret`.

**Chỉ mục.** `ix_outbox_occurred` (occurred_at).

**Cách ly tenant.** RLS mẫu P (FORCE): chỉ thấy và ghi dòng có `tenant_id = app.tenant_id` của phiên (hoặc dòng `COMMON` khi phiên là `PLATFORM`); chính sách `rls_outbox_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Lưu giữ Dọn sau 3 ngày khi Debezium đã gửi.

**Ghi chú.** Khóa `event_id`; chỉ thêm (ứng dụng không có quyền UPDATE), xóa khi dọn. Phát lên Kafka bởi Debezium hoặc bộ quét 500 ms.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `event_id` | `uuid` | x |  |  |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` hoặc `COMMON` (bảng có dòng toàn quốc); khóa RLS và khóa ngoại kép. |
| `event_type` | `varchar(128)` | x |  | Mẫu: `^vn\.datahub\.national\.[a-z-]+\.[a-z-]+\.v[0-9]+$`. |
| `topic` | `varchar(249)` | x |  | Dạng {tenant}.national.{thực-thể}.{sự-kiện}.v{n} chữ thường; tiền tố phải khớp tenant (ck_outbox_topic_tenant, SEC-82). |
| `aggregate_type` | `varchar(64)` | x |  |  |
| `aggregate_id` | `text` | x |  |  |
| `payload` | `jsonb` | x |  |  |
| `trace_id` | `char(32)` | x |  | Mẫu: `^[0-9a-f]{32}$`. |
| `occurred_at` | `timestamptz` | x | `now()` | Thời điểm (T-TS, lưu UTC). |

: Cột của bảng `outbox`

### 3.37. `shedlock`

::: dac-ta
**Mục đích.** Khóa tác vụ nền của ShedLock (CertificateExpiryJob, CrlRefresher, SyncScheduler, ComplianceWatcher, AnomalyDetector, HealthRollupJob, PartitionMaintenanceJob, PayloadRetentionApplier, QuotaForecaster); bảng kỹ thuật không có tenant_id.

**FR phục vụ.** FR-14-029, 043, 047, 053 (tác vụ định kỳ).

**Khóa chính.** (name).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không bật RLS: bảng kỹ thuật không có `tenant_id` và không chứa dữ liệu nghiệp vụ.

**Phân vùng, chỉ thêm.** Không.

**Ghi chú.** Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ nên không bật RLS.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `name` | `varchar(64)` | x |  |  |
| `lock_until` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `locked_at` | `timestamptz` | x |  | Thời điểm (T-TS, lưu UTC). |
| `locked_by` | `varchar(255)` | x |  | Mã người dùng thực hiện (hoặc `system:*`). |

: Cột của bảng `shedlock`

<!-- gen:tables:end -->

### 3.38. Truy vấn chính và chỉ mục phục vụ

Bảng dưới nối các truy vấn thường xuyên hoặc nặng của PH-14 với chỉ mục phục vụ; chỉ mục "một phần" (có `WHERE`) nhỏ hơn đáng kể vì chỉ chứa dòng đang mở. Truy vấn trên bảng phân vùng luôn kèm điều kiện thời gian để cắt tỉa phân vùng.

| Truy vấn | API, tác vụ | Chỉ mục |
|---|---|---|
| Danh sách nền tảng lọc loại, trạng thái, sức khỏe | API-14-001, UI-14-02 | `ix_national_platform_type_state`; nối `health_state` theo khóa chính |
| Tìm dịch vụ theo tên, nhóm, trạng thái, nhãn đối chiếu | API-14-010 | `ix_national_service_name_trgm` (`pg_trgm`), `ix_national_service_group_state`, `ix_national_service_platform_state`, `ix_national_service_label` (một phần) |
| Phiên bản đặc tả của dịch vụ; bản đang dùng | API-14-018, SnapshotBuilder | `ix_service_spec_service`, `uq_service_spec_one_active` |
| Luật định tuyến đưa vào ảnh chụp | SnapshotBuilder | `ix_routing_rule_state_priority`, `uq_routing_rule_active` |
| Chứng thư sắp hết hạn | CertificateExpiryJob 06:00 hằng ngày | `ix_national_certificate_expiry` (một phần) |
| CRL sắp quá hạn | CrlRefresher mỗi `14.trust.refresh-hours` | `ix_trust_anchor_crl_next` (một phần) |
| Sự cố chữ ký còn mở của nền tảng; biểu ngữ không ẩn được | Điều kiện giải trừ ERR-14-004, UI-14-01 | `ix_signature_incident_open`, `ix_signature_incident_unresolved` (một phần) |
| Hộp việc duyệt bốn mắt; chặn đề nghị trùng | FR-00-070 | `ix_approval_request_inbox`, `uq_approval_request_pending` |
| Lệnh `worker` quá hạn; đếm lần kiểm tra tay mỗi giờ | Quét 30 giây; `14.test.max-per-hour` | `ix_worker_command_open` (một phần), `ix_worker_command_target` |
| Hạn mức hiệu lực của nền tảng | API-14-041, SnapshotBuilder | `uq_quota_policy_active`, `ix_quota_policy_platform` |
| Phân bổ theo HTTT | API-14-044 | `ix_quota_allocation_system` |
| Mức dùng và dự báo cạn | API-14-043, QuotaForecaster | Khóa chính của `quota_usage`, `ix_quota_usage_platform` |
| Yêu cầu bất đồng bộ đang treo; tra theo khóa chống trùng | API-14-077 (đường dự phòng), `AsyncStateConsumer` | `ix_async_request_open` (một phần), `uq_async_request_idempotency` |
| Kết quả chưa rõ chờ đối soát | `UnknownResultReconciler` | `ix_national_transaction_unknown`, `ix_async_request_unknown` (một phần) |
| Tra giao dịch theo mã | API-14-062 | `ix_national_transaction_code` |
| Danh sách giao dịch theo thời gian, HTTT, dịch vụ, mã hồ sơ (khoảng tối đa 31 ngày, phân trang keyset) | API-14-061, UI-14-12 | `ix_national_transaction_started`, `_system`, `_service`, `_case` (một phần) |
| Số đối tượng khác nhau mỗi HTTT trong giờ gần nhất | `AnomalyDetector` luật `MASS_LOOKUP` | `ix_national_transaction_lookup` (một phần, `INCLUDE lookup_key_hash`) |
| Báo cáo sử dụng theo HTTT, dịch vụ | API-14-065, UI-14-13 | `ix_usage_hourly_system`, `ix_usage_hourly_service` |
| Lần đồng bộ thành công gần nhất; phiên chưa kết thúc | `ComplianceWatcher`; chống chạy chồng | `ix_sync_run_success` (một phần), `uq_sync_run_open` |
| Bản ghi chưa nhận của một phiên, để thử lại | API-14-057 | `ix_sync_record_outcome` (một phần) |
| Mẫu và khoảng gián đoạn của nền tảng | API-14-058, UI-14-01 | Khóa chính của `health_sample`, `ix_platform_outage_platform`, `uq_platform_outage_open` |
| Cảnh báo bất thường; cửa sổ đã báo; danh sách chặn hiệu lực | API-14-067, SnapshotBuilder | `ix_anomaly_alert_time`, `uq_anomaly_alert_open`, `ix_anomaly_waiver_scope`, `uq_access_block_active` |
| Mẫu so sánh của một phiên chạy song song | API-14-073 | `ix_parallel_sample_run` |
| Quét outbox để phát lên Kafka | Bộ quét 500 ms | `ix_outbox_occurred` |

: Truy vấn chính và chỉ mục phục vụ

## 4. DDL và changelog Liquibase

### 4.1. Tệp

Thư mục [`ph14/ddl/`](ph14/ddl/ph14_00_bootstrap.sql) chứa sáu tệp `ph14_*.sql` là nguồn duy nhất của lược đồ. Mỗi tệp chia changeset bằng `-- @file`, `-- @changeset <id> [thuộc tính]`, `-- @rollback <SQL>` như PH-04, PH-05, PH-07; changelog Liquibase (formatted SQL) sinh bằng `../ph07/tools/gen_liquibase.py` sau khi tham số hóa tên phân hệ, các dòng chỉ dành cho `psql` (`\set`, `SET ROLE`, `RESET ROLE`) bị bỏ. Thứ tự chạy là thứ tự tên tệp.

| Tệp | Nội dung | Changeset |
|---|---|---|
| [`ph14_00_bootstrap.sql`](ph14/ddl/ph14_00_bootstrap.sql) | Vai trò, `pg_trgm`, schema, biến phiên; hàm `tg_touch`, `p_enable_rls`, `p_ensure_month_partitions`, `tg_append_only`, `tg_no_delete`, `tg_retired_final` | 7 |
| [`ph14_10_catalog.sql`](ph14/ddl/ph14_10_catalog.sql) | `national_platform`, `national_service`, `service_spec` (+ trigger bất biến), `service_exposure`, `reconcile_run`, `config_revision`, `routing_rule`, `approval_request`, `worker_command` | 9 |
| [`ph14_20_trust.sql`](ph14/ddl/ph14_20_trust.sql) | Hàm `tg_immutable`; `credential_rotation`, `national_certificate`, `trust_anchor`, `signature_incident` | 5 |
| [`ph14_30_quota_inbound.sql`](ph14/ddl/ph14_30_quota_inbound.sql) | `quota_policy`, `quota_allocation` (+ trigger tổng phân bổ), `quota_usage` và `cache_stats` (phân vùng), `async_request`, `inbound_endpoint`, `allowed_sender`, `inbound_route` (+ trigger điều kiện bật) | 8 |
| [`ph14_40_operations.sql`](ph14/ddl/ph14_40_operations.sql) | `sync_run`, `sync_record`, `national_transaction` (+ hàm `f_txn_rank`, trigger chỉ tiến), `usage_hourly`, `health_sample`, `health_state`, `platform_outage`, `anomaly_alert`, `anomaly_waiver`, `access_block`, `parallel_run`, `parallel_sample`, `legacy_import`, `outbox`, `shedlock` | 15 |
| [`ph14_90_seed_grants.sql`](ph14/ddl/ph14_90_seed_grants.sql) | Dữ liệu khởi tạo (§5) và quyền theo vai trò, chạy lại mỗi lần (`runAlways`) | 3 |

: Tệp DDL của schema ph14_national

Khối `@file` đặt tên tệp changelog theo `14-nnnn-{ý}.sql` (ví dụ `14-0010-catalog.sql`, `14-0041-transaction.sql`); mã changeset có dạng `ph14-nnnn-{ý}` (ví dụ `ph14-0420-national-transaction`). Changeset tạo hàm hoặc trigger dùng `splitStatements:false` để dấu chấm phẩy trong thân hàm không bị cắt. Changeset `ph14-0810-seed-demo-t90` có `context:demo` nên chỉ chạy ở môi trường phát triển và kiểm thử.

### 4.2. Kết quả chạy thử

Chạy ngày 26/11/2026 trên PostgreSQL 16.16 cài sạch (người dùng có quyền tạo vai trò và extension), dữ liệu giả, bằng [`ph14/tools/chay_thu.sh`](ph14/tools/chay_thu.sh) (xóa schema, chạy sáu tệp DDL với `ON_ERROR_STOP`, chạy bài kiểm):

- Sáu tệp DDL chạy lần lượt không lỗi; tạo 36 bảng, 662 cột, 35 bảng `FORCE ROW LEVEL SECURITY` (khối 7 của bài kiểm đếm đúng 35), 6 bảng phân vùng, mỗi bảng phân vùng có 5 phân vùng tháng.
- Bài kiểm [`ph14_isolation_test.sql`](ph14/test/ph14_isolation_test.sql) chạy dưới `dh_integration_app` (thành viên `ph14_app`) và `dh_report_ro` (thành viên `ph14_readonly`), đạt **85 khối**; mỗi khối bắt lỗi mong đợi và ghi `PASS`, sai thì dừng tệp. Bảng dưới nhóm các khối.

| Nhóm | Số khối | Điều được kiểm |
|---|---|---|
| A. Cô lập tenant | 11 | T01 không đọc, không chèn, không sửa, không xóa dòng T68 (kể cả bảng phân vùng); biến phiên rỗng không thấy dòng nào; tenant tỉnh đọc nhưng không ghi được nền tảng và dịch vụ `COMMON`; chứng thư `COMMON` chỉ phiên `PLATFORM` thấy; 35 bảng đều `FORCE RLS` và có `CHECK` dạng tenant |
| B. Chống lộ bí mật | 6 | Khóa bí mật trong tham số lệnh, sự kiện bị chặn; topic sai tenant bị chặn; chứng thư chứa khóa riêng, `keyRef` sang tenant khác, sự cố mang thân bản tin bị chặn |
| C. Bốn mắt | 7 | Người duyệt bật nền tảng trùng người đề nghị bị chặn, người thứ hai được; yêu cầu duyệt trùng người đề nghị hoặc người sửa gần nhất bị chặn; đã quyết định thì bất biến; luật định tuyến `ACTIVE`, hạn mức `PROD` thiếu người duyệt bị chặn |
| D. Chính sách dịch vụ | 5 | Không đệm `SENSITIVE`; DLCN bắt buộc mục đích; nhãn Ngừng không đi cùng `ACTIVE`; `RETIRED` không đảo ngược; khóa ngoại kép không trỏ nền tảng tenant khác |
| E. Đặc tả và chứng thư | 8 | Đặc tả `ACTIVE` bất biến, mỗi dịch vụ một bản `ACTIVE`, trùng phiên bản bị từ chối, thay đổi phá vỡ chưa duyệt bị chặn; một chứng thư ký hiện hành, chuyển tiếp qua `supersede_at`, chủ thể bất biến, không xóa |
| F. Hạn mức | 4 | Căn cứ văn bản bắt buộc; tổng phân bổ 1.001 vượt hạn mức 1.000 bị chặn khi kết thúc giao dịch; `UNLIMITED` không đi cùng trần; không hạ hạn mức xuống dưới tổng đã phân bổ |
| G. Sổ giao dịch | 7 | Chuyển RECEIVED, SENT, SUCCEEDED; không lùi trạng thái; định danh bất biến; không xóa; UPSERT theo hạng bỏ bản đến muộn và không nhân đôi dòng; `UNKNOWN_RESULT` chỉ cho ghi; không đệm thao tác ghi |
| H. Chiều vào | 4 | Mã điểm cuối phải kết thúc bằng mã tenant; tắt chữ ký cần lý do; bật khi thiếu nguồn hoặc tuyến bị chặn, đủ thì bật được, đường dẫn sinh đúng |
| I. Vận hành | 24 | Phiên đồng bộ chồng và đối soát số liệu; chạy song song chỉ đọc, một phiên mỗi dịch vụ, đóng phiên cần thu hồi khóa cũ, tỷ lệ khớp sinh tự động; cảnh báo không mang định danh, một cảnh báo mở, kết thúc cần lý do; xoay thông tin xác thực; luật dự phòng; CRL; sự cố chữ ký; cung cấp lại; bất đồng bộ ULID; bẫy NULL của `CHECK` |
| J. Quyền vai trò, phân vùng | 9 | `outbox` chỉ thêm; không đọc thẳng phân vùng; ứng dụng tạo phân vùng mới qua thủ tục có quyền chủ sở hữu và ghi được vào đó; ứng dụng không gọi `p_enable_rls`; vai trò báo cáo đọc được nhưng không ghi, không đọc `lookup_key_hash`, `content` và vẫn bị RLS |

: Nhóm khối kiểm của ph14_isolation_test.sql

Các mức kiểm thử Tích hợp (PostgreSQL 16 có RLS bằng Testcontainers) và Bảo mật (rò rỉ chéo tenant cho mọi API đọc, NFR-14-024) của D03-02-PH14 §12 tự động hóa các ca này trong CI; tệp SQL là bản chạy tay để DBA và kiểm thử viên đối chiếu, và là đầu vào cho nhóm ca cô lập, tách nhiệm, chống lộ bí mật của D05-02-PH14.

### 4.3. Điều soát và chạy thử phát hiện

Quá trình soát DDL và chạy thử phát hiện ba lỗi thiết kế, đã sửa trong DDL; ghi lại để người sau không lặp lại. Lỗi thứ nhất do bài kiểm bắt được khi chạy; hai lỗi còn lại do soát trước khi chạy và có khối kiểm khóa lại.

| Phát hiện | Hậu quả nếu không sửa | Cách sửa |
|---|---|---|
| Cột sinh `state_rank` chưa được tính khi trigger `BEFORE UPDATE` chạy, `NEW.state_rank` là `NULL` | Trigger chỉ-tiến không bao giờ chặn, giao dịch lùi trạng thái được | Đặt hạng trong hàm `IMMUTABLE` `f_txn_rank(state)` dùng chung cho cột sinh và trigger |
| `CHECK (state <> 'X' OR char_length(cột) >= n)` cho kết quả `NULL` khi cột rỗng nên **lọt qua** | Sự cố kết thúc không kết luận, xoay hoàn tất không biên nhận, dịch vụ đệm không `cacheTtlSeconds` vẫn được ghi | Bọc `coalesce(…, 0)` hoặc thêm `IS NOT NULL`; có ba khối kiểm riêng (24c, 24d, 24e) |
| Tại giao dịch kiểm thử, `UPDATE` trong khối có `EXCEPTION` bị hoàn tác cùng lỗi | Kiểm thử báo đạt giả | Đặt các bước chuẩn bị ngoài khối bắt lỗi (khối 11, 12, 16) |

: Phát hiện khi chạy thử DDL

## 5. Dữ liệu khởi tạo

Dữ liệu khởi tạo ít vì PH-14 không có danh mục cố định trong CSDL: danh mục mục đích khai thác và mã thủ tục ở PH-07 (`CatalogLookupApi`), tham số `14.*` ở PH-18, đặc tả dịch vụ quốc gia là dữ liệu cấu hình do tenant nạp (BR-14-025). Seed chạy dưới `app.tenant_id` tương ứng, lũy đẳng (`ON CONFLICT DO NOTHING`).

| Dữ liệu | Tenant | Nội dung | Nguồn |
|---|---|---|---|
| Số phiên bản cấu hình của cổng `COMMON` | `COMMON` | 2 dòng `config_revision` (`TEST`, `PROD`), `revision = 1` | §3.7, SDD §4.3 |
| Số phiên bản cấu hình của tenant tỉnh | Mỗi tenant | 3 dòng (`TEST`, `STAGING`, `PROD`) do `ConfigRevisionService` tạo khi tenant được cấp phát (D03-10 §5.2), không seed ở DDL | SDD §4.3 |
| Bộ mẫu phát triển, kiểm thử | `T90` | `context:demo`: 1 nền tảng `ndxp-t90` (`PROVISIONAL`) và 7 dịch vụ đại diện bảy nhóm với chính sách mặc định ở bảng dưới; 2 dòng `config_revision` | SDD §4.6 |
| Chính sách mặc định theo nhóm dịch vụ | Không lưu | Đóng trong mã của `dh-integration` cùng bộ điều hợp (như loại kết nối ở PH-05); dùng khi nhập hệ cũ (FR-14-056) và khi mở form dịch vụ mới; tenant đổi bằng cách sửa dịch vụ | SDD §4.6, §4.19 |
| Tham số `14.*` | PH-18 | 51 tham số mặc định theo FRS §8.2; giá trị bảo mật (★) đổi qua `approval_request` loại `SECURITY_PARAM_CHANGE` | FR-14-054 |
| Chuỗi tin cậy gốc của trung ương | Không seed | Nạp bằng FR-14-030, thay đổi neo cần bốn mắt (BR-14-018) | FR-14-030 |

: Dữ liệu khởi tạo

Bảy dịch vụ của bộ mẫu `T90` thể hiện chính sách mặc định của từng nhóm; giá trị là giả định theo SDD §4.6 cho tới khi Q14-01 (danh mục NDXP hiện hành) được trả lời.

| Nhóm | Mã dịch vụ mẫu | Thao tác | Nhạy cảm | Đệm | Dùng dữ liệu quá hạn | Ưu tiên | Ký, xác minh | Mục đích, mã hồ sơ |
|---|---|---|---|---|---|---|---|---|
| `LLTP` | `lltp-tra-trang-thai` | Đọc | `SENSITIVE` | Không | Không | `ESSENTIAL` | `JWS` | Có, có |
| `HO_TICH` | `hotich-dang-ky-khai-sinh` | Ghi (không idempotent), SOAP | `SENSITIVE` | Không | Không | `ESSENTIAL` | `XMLDSIG` | Có, có |
| `BHXH` | `bhxh-tra-ho-gia-dinh` | Đọc | `RESTRICTED` | 300 giây | Không | `NORMAL` | `JWS` | Có, có |
| `DVQHNS` | `dvqhns-ds-ho-so-theo-ngay` | Đọc | `INTERNAL` | Không | Không | `BACKGROUND` | `JWS` | Không |
| `DKDN` | `dkdn-du-lieu-doanh-nghiep` | Đọc | `INTERNAL` | 3.600 giây | Có | `NORMAL` | `JWS` | Không |
| `VBQPPL` | `vbqppl-tim-kiem` | Đọc | `PUBLIC` | 3.600 giây | Có | `NORMAL` | Không | Không |
| `DMDC` | `dmdc-lay-du-lieu` | Đọc | `PUBLIC` | Không (chỉ chuyển tiếp, BR-14-036) | Không | `BACKGROUND` | `JWS` | Không |

: Chính sách mặc định của bảy dịch vụ mẫu ở tenant T90

## 6. Kho lưu trữ ngoài PostgreSQL

PH-14 dùng bốn kho ngoài PostgreSQL. PostgreSQL giữ cấu hình, hồ sơ và bằng chứng; Valkey giữ bộ đếm và đệm nóng của đường gọi; Kafka là đường bền từ mặt phẳng dữ liệu về `dh-integration`; Ceph RGW giữ nội dung lớn hoặc cần mã hóa riêng; OpenBao giữ khóa và bí mật. Bảng dưới là hợp đồng dữ liệu giữa các kho; thiết kế mã ở [D03-02-PH14](../sdd/D03-02-PH14-sdd-ket-noi-quoc-gia.md).

### 6.1. Valkey

Mọi khóa của một tenant mang tiền tố `{tenant}:nat:` với thẻ băm `{tenant}` để các khóa của tenant nằm cùng một slot và script Lua chạy trên một nút (SDD §4.10). Người dùng ACL theo tenant, mẫu khóa `~{tenant}:nat:*` (SEC-82); `dh-integration` chỉ được `INCR` khóa thế hệ đệm.

| Mẫu khóa | Nội dung | Thời hạn | Ghi bởi | Quan hệ với PostgreSQL |
|---|---|---|---|---|
| `{t}:nat:q:s:{dịch vụ}:{chu kỳ}:{mốc}` | Bộ đếm hạn mức theo dịch vụ (chu kỳ lịch) | Chu kỳ cộng 1 giờ | `QuotaGate` (script Lua) | `UsageSnapshotter` ghi ảnh chụp vào `quota_usage` qua Kafka |
| `{t}:nat:qs:…` | Hash 60 ô cho cửa sổ trượt (`14.quota.window-mode = SLIDING`) | Độ dài cửa sổ cộng dự phòng | `QuotaGate` | Như trên |
| `{t}:nat:qw:{phạm vi}:{chu kỳ}:{mốc}:{mức}` | Cờ `SET NX` mức cảnh báo đã phát (70%, 85%, 95%) | Hết chu kỳ | `QuotaGate` | `quota_usage.last_warned_level` |
| `{t}:nat:c:{thế hệ}:{dịch vụ}:{thao tác}:{băm}` | Phản hồi đệm (mã hóa theo khóa tenant với dữ liệu `RESTRICTED`) | `cacheTtlSeconds` cộng `14.cache.stale-max-seconds` | `CacheStage` | `cache_stats` tổng hợp theo giờ từ EVT-14-11 (cờ `fromCache`, `stale`) |
| `{t}:nat:gen:{dịch vụ}` | Số thế hệ của đệm; `INCR` là vô hiệu đệm (FR-14-036) | Không hết hạn | `dh-integration` (chỉ `INCR`) | EVT-14-09 |
| `{t}:nat:brk:{nền tảng}:{nhóm}` | Trạng thái ngắt mạch hiện hành | Theo chu kỳ ngắt | Cổng | Cờ ép ở `national_platform.breaker_override` |
| `{t}:nat:as:{requestId}` | Trạng thái nóng của yêu cầu bất đồng bộ | 96 giờ | `AsyncAcceptor`, `AsyncWorker` | Bản dẫn xuất ở `async_request` |
| `{t}:nat:hs:{nền tảng}:{phút}` | Số lượt tốt, lỗi, thùng độ trễ theo phút (sức khỏe thụ động) | Tối thiểu 10 phút | Cổng `gateway` | `health_sample` loại `PASSIVE` |
| `{t}:nat:sigfail:{nền tảng}` | ZSET sự cố chữ ký trong cửa sổ trượt 10 phút | 10 phút | Cổng | `signature_incident` |
| `{t}:nat:hold:{nền tảng}` | Cờ `SECURITY_HOLD` do cổng đặt ngay khi đủ ngưỡng | Tới khi SO giải trừ | Cổng; SO xóa qua API | `national_platform.security_hold` (nguồn để dựng lại khi Valkey mất) |
| Khóa chống trùng ghi và `messageId` chiều vào | Bản ghi `SET NX` kết quả thao tác ghi; chống phát lại | 24 giờ; `14.inbound.replay-window-seconds` | Cổng | Không (Q14-27 của SDD) |

: Khóa Valkey của PH-14

Valkey là kho nóng, mất được: bộ đếm dựng lại từ `quota_usage` (có thể thiếu vài phút lượt dùng, cổng chuyển sang đếm cục bộ chia đều theo số bản sao trong lúc đó và vẫn kiểm hạn mức), cờ `SECURITY_HOLD` dựng lại từ `security_hold` và sự cố `OPEN`, đệm rỗng thì gọi thật (tốn hạn mức nhưng không sai dữ liệu).

### 6.2. Kafka

Chủ đề theo quy ước `{tenant}.{miền}.{thực-thể}.{sự-kiện}.v{n}` chữ thường; ACL theo principal và tiền tố tenant (SEC-82), cấp phát qua GitOps (ADR-072); lược đồ ở Apicurio, chế độ BACKWARD (NFR-14-022).

| Chủ đề | Chủ | Phân vùng, giữ | Khóa | Nội dung |
|---|---|---|---|---|
| `{tenant}.national.{platform,service,routing,certificate,signature,quota,cache,inbound,exposure,anomaly,sync}.….v1` (EVT-14-01…06, 08, 09, 12, 13, 14, 16) | `dh-integration` qua `outbox` | 3, giữ 7 ngày | Mã đối tượng (`platformCode`, `serviceCode`, `certCode`…) | Sự kiện miền, không bí mật, không nội dung bản tin |
| `{tenant}.national.transaction.recorded.v1` (EVT-14-11) | Cổng qua `LedgerSpool` | 3, giữ 7 ngày | `transactionCode` | Bản ghi giao dịch (siêu dữ liệu, `payloadRef`, `payloadHash`, `lookupKeyHash`); nguồn của `national_transaction` và `usage_hourly` |
| `{tenant}.national.quota.threshold-reached.v1`, `….breaker.changed.v1`, `….health.changed.v1`, `….notification.received.v1` (EVT-14-07, 10, 15, 17) | Cổng qua `LedgerSpool` | 3, giữ 7 ngày | Mã đối tượng | Sự kiện từ mặt phẳng dữ liệu |
| `{tenant}.national.quota.usage.v1` (nội bộ) | Cổng | 3, giữ 7 ngày | Khóa bộ đếm | Ảnh chụp mức dùng → `quota_usage` |
| `{tenant}.national.async.state.v1` (nội bộ) | Cổng | 3, giữ 7 ngày | `requestId` | Trạng thái yêu cầu bất đồng bộ → `async_request` |
| `{tenant}.national.asyncqueue.{essential,normal,background}.v1` | Cổng (`AsyncAcceptor`) | 6, 3 bản sao, giữ 96 giờ, `min.insync.replicas = 2` | `requestId` | Phong bì yêu cầu, thân mã hóa theo khóa tenant (ADR-032) |
| `{tenant}.national.asyncqueue.retry-{1m,5m,30m}.v1` | Cổng | 3, giữ 96 giờ | `requestId` | Thông điệp hoãn kèm tiêu đề `not-before` |
| `{tenant}.national.worker.command.v1`, `….worker.result.v1` (nội bộ) | `dh-integration` qua `outbox`; `worker` | 3, giữ 7 ngày | `commandId` | Lệnh và kết quả → `worker_command` |
| `{tenant}.national.signature.failed.v1` (nội bộ) | Cổng | 3, giữ 7 ngày | `platformCode` | Sự cố chữ ký → `signature_incident` |
| `{tenant}.national.trust.crl.v1` (nội bộ) | `worker` (`CrlRefresher`) | 1, nén (`compact`) | `anchorCode` | Con trỏ CRL (khóa đối tượng, SHA-256, `thisUpdate`, `nextUpdate`) |

: Chủ đề Kafka của PH-14

Ghi vào PostgreSQL từ Kafka luôn lũy đẳng theo khóa tự nhiên (`transactionCode`, `requestId`, `commandId`), ít nhất một lần: `LedgerConsumer` dùng UPSERT theo hạng, `AsyncStateConsumer` dùng `ON CONFLICT (id)`, kết quả lệnh xử lý theo `commandId`. Khi ghi PostgreSQL lỗi, bộ tiêu thụ thử lại lùi theo hàm mũ tới 60 giây và không bỏ lô vì Kafka giữ thông điệp 7 ngày (SDD §8.3).

### 6.3. Ceph RGW

Ba bucket riêng theo mục đích và vòng đời, cộng một bucket WORM cho sổ giao dịch quá 12 tháng. Khóa đối tượng luôn bắt đầu bằng tiền tố tenant để chính sách bucket và ACL cô lập theo tenant (SEC-82).

| Bucket | Nội dung | Khóa đối tượng | Vòng đời |
|---|---|---|---|
| `dh-nat-payload` | Nội dung yêu cầu, phản hồi mã hóa AES-256-GCM bằng DEK của tenant (AAD gồm tenant, mã giao dịch, loại); kết quả bất đồng bộ | `{tenant}/{yyyy}/{MM}/{transactionCode}.{req,res}.enc`; `{tenant}/async/{requestId}.res.enc` | Theo `14.txn.payload-retention-days` (mặc định 30, tối đa 180, 0 là không ghi); kết quả bất đồng bộ 72 giờ; `PayloadRetentionApplier` đặt luật vòng đời theo tiền tố tenant; không WORM |
| `dh-nat-trust` | Tệp CRL và chuỗi tin cậy đã kiểm chữ ký | `{tenant}/crl/{anchorCode}/{thisUpdate}.crl` | Giữ 30 ngày (giả định), bản hiện hành luôn giữ |
| `dh-nat-sync` | Lô bản ghi đồng bộ (JSON Lines), không chứa DLCN | `{tenant}/{runId}.jsonl` | 3 năm, theo `sync_run` |
| Bucket WORM của sổ giao dịch (tên theo D03-09, đề xuất `dh-nat-ledger-worm`) | Phân vùng `national_transaction` quá 12 tháng xuất nén kèm chuỗi băm (ADR-031) | `{tenant}/{yyyy}/{MM}` (định dạng nén, đề xuất Parquet như ADR-047) và tệp băm chuỗi | 5 năm, khóa đối tượng không xóa được trong thời hạn (SEC-62); tách bucket theo Q306, Q341 |

: Kho đối tượng Ceph RGW của PH-14

Cột `payload_ref` ở `national_transaction` và `result_ref` ở `async_request` chỉ lưu khóa đối tượng và `CHECK` ép tiền tố tenant; xem nội dung đầy đủ cần quyền riêng, xác thực lại nhiều yếu tố, lý do và để lại vết trước khi đọc (FR-14-050, BR-14-021).

### 6.4. OpenBao

PH-14 không lưu khóa hay bí mật nào ở CSDL: mọi thứ nhạy cảm nằm ở OpenBao và bảng chỉ giữ tham chiếu. Bảng dưới liệt kê đường dẫn mà các cột `key_ref`, `connection_code` và `pending_secret_version` trỏ tới.

| Đường dẫn | Nội dung | Ai ghi, ai đọc |
|---|---|---|
| `transit/keys/dh-{tenant}-nat-sign-*` (ví dụ ở FRS: `dh-t68-national-sign`) | Khóa ký bản tin; chỉ ký, không xuất; `national_certificate.key_ref` trỏ tới đây | Tạo, nhập (BYOK nếu Q14-03 cho phép) bởi quản trị khóa; hồ sơ `national-gateway` của đúng tenant gọi `sign` (BR-14-004) |
| `transit/keys/dh-{tenant}-nat-auth` | Khóa ký xác nhận khách khi nền tảng dùng `private_key_jwt` | Cổng |
| `transit/keys/dh-{tenant}-nat-config` | Khóa ký ảnh chụp cấu hình | `dh-integration` ký; cổng xác minh |
| `transit/keys/dh-{tenant}-nat-evidence` | Khóa ký gói bằng chứng giao dịch (Đợt 2) | `dh-integration` |
| `transit/keys/dh-{tenant}-pii` | Mã hóa nội dung bản tin ở `dh-nat-payload`, giải mã khi xem có lý do | Cổng mã hóa; `dh-integration` giải mã (`RevealService`) |
| `kv/dh/{tenant}/conn/{code}/{env}` (PH-05) | Thông tin xác thực nền tảng quốc gia; ghi một chiều, không API nào trả giá trị (BR-14-005) | `dh-integration` ghi qua PH-05; cổng đọc; `credential_rotation` chỉ giữ số phiên bản chờ |

: Đường dẫn OpenBao PH-14 dựa vào

Mọi `key_ref` phải khớp `transit/keys/dh-{tenant chữ thường}-…` nên cả hai kiểu đặt tên của FRS và SDD đều hợp lệ; thống nhất tên ở D03-07 (Đề nghị đồng bộ).

### 6.5. Đĩa của pod và kho chỉ số

Hai tệp ngoài mọi kho trên ở mặt phẳng dữ liệu: ảnh chụp cấu hình `/var/lib/dh/national/snapshot.json` (nguồn là `config_revision` và các bảng danh mục, có chữ ký) giúp cổng chạy khi `dh-integration` hoặc `pg-core` ngừng, và `LedgerSpool` (tệp ghi trước, tối đa `14.spool.max-mb` = 512 MiB) giữ bản ghi giao dịch chưa gửi được lên Kafka. Chỉ số vận hành (`national_*`) nằm ở kho LGTM của PH-13, không dùng ClickHouse; bằng chứng kiểm toán nằm ở PH-13. Nếu `national_transaction` vượt 50 triệu dòng mỗi tháng ở một tenant, phương án chuyển truy vấn lịch sử sang ClickHouse của PH-13 được đánh giá ở Q14-51.

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

### 7.1. Lưu giữ và dọn dữ liệu

Mỗi bảng có thời hạn lưu giữ và cơ chế dọn riêng. Bảng khối lượng lớn dọn bằng tháo phân vùng thay vì xóa dòng để không gây phình và khóa bảng (ADR-047); bảng bằng chứng bị trigger chặn xóa.

| Đối tượng | Lưu giữ | Cơ chế dọn |
|---|---|---|
| `national_transaction` | 12 tháng trực tuyến; WORM 5 năm (BR-14-020, SEC-62) | `LedgerArchiver` xuất phân vùng quá 12 tháng sang bucket WORM kèm chuỗi băm, xác minh rồi `DETACH` và `DROP` dưới `ph14_owner` |
| `usage_hourly` | 24 tháng (chủ đầu tư chốt 27/11/2026) | `DETACH` phân vùng quá hạn |
| `quota_usage` | 2 năm (NFR-14-021) | `DETACH` phân vùng quá hạn |
| `cache_stats` | 13 tháng (chủ đầu tư chốt 27/11/2026) | `DETACH` phân vùng quá hạn |
| `health_sample` | 90 ngày; gộp theo giờ sau 7 ngày | `HealthRollupJob` 01:30; `DETACH` phân vùng quá hạn |
| `parallel_sample` | 90 ngày (FR-14-055) | `DETACH` phân vùng quá hạn |
| `signature_incident`, `anomaly_alert` | 5 năm, không xóa | Không dọn; trigger chặn xóa |
| `national_certificate`, `trust_anchor` | Vĩnh viễn, kể cả hết hạn (BR-14-019) | Không dọn; trigger chặn xóa |
| `sync_run` và `sync_record`, `reconcile_run`, `platform_outage`, `legacy_import` | 3 năm | `RetentionJob` 02:40 xóa theo `finished_at` (kéo theo `sync_record` bằng `ON DELETE CASCADE`) |
| `async_request` | 90 ngày sau khi kết thúc (chủ đầu tư chốt 27/11/2026) | `RetentionJob` 02:40 |
| `worker_command` | 30 ngày (giả định) | `RetentionJob` 02:40 |
| `outbox` | 3 ngày | Sau khi Debezium đã gửi |
| `national_platform`, `national_service`, `service_spec`, `routing_rule`, `quota_policy`, `credential_rotation`, `approval_request`, `parallel_run` | Vĩnh viễn | Không dọn |
| Phân vùng mới | Luôn có 3 tháng tới cho 6 bảng phân vùng | `PartitionMaintenanceJob` 01:00 hằng ngày dưới ShedLock |

: Lưu giữ và cơ chế dọn

`RetentionJob`, `HealthRollupJob`, `PartitionMaintenanceJob`, `LedgerArchiver` chạy dưới khóa ShedLock (`shedlock`), mỗi tenant một lượt để RLS luôn có hiệu lực; việc `DROP` phân vùng dùng `ph14_owner` qua thủ tục có kiểm soát vì `ph14_app` không có quyền trên phân vùng.

### 7.2. Sao lưu và khôi phục

Schema `ph14_national` sao lưu theo `pg-core`: WAL liên tục và sao lưu cơ sở hằng ngày lên Ceph RGW, bất biến (ADR-035), RPO 5 phút, DR hai site active–standby (ADR-034, D03-09). Phục hồi theo thời điểm khôi phục cả sổ giao dịch lẫn `usage_hourly` về cùng thời điểm vì hai bảng cùng được ghi trong một giao dịch; sau đó `LedgerConsumer` phát lại từ vị trí Kafka (giữ 7 ngày) và UPSERT theo hạng làm việc phát lại an toàn, không nhân đôi dòng và không cộng lặp mức dùng.

| Tình huống | Hệ quả | Xử lý |
|---|---|---|
| Khôi phục PostgreSQL về thời điểm cũ hơn OpenBao | `key_ref` của chứng thư trỏ khóa còn tồn tại; `pending_secret_version` có thể thấp hơn thật | Tác vụ đối soát đọc siêu dữ liệu OpenBao và sửa; cổng không bị ảnh hưởng vì dùng ảnh chụp |
| Khôi phục OpenBao về thời điểm cũ hơn PostgreSQL | `key_ref` hoặc số phiên bản bí mật không còn tồn tại | `KeyMatchChecker` báo ERR-14-020 và cổng chặn ký (không gửi bản tin chưa ký, BR-14-001); người dùng nạp lại khóa; sổ tay DR ghi rõ khôi phục OpenBao trước, PostgreSQL sau |
| Mất Valkey | Bộ đếm, đệm, cờ hold mất | §6.1: đếm cục bộ suy giảm có cảnh báo; dựng lại cờ hold từ `security_hold` |
| Kafka ngừng kéo dài, `LedgerSpool` đầy | Cổng ngừng nhận lượt cần gọi ra mới (ERR-14-127) thay vì bỏ bản ghi | Khôi phục Kafka; `LedgerConsumer` ghi bù; độ trễ đo bằng `national_ledger_lag_seconds` |
| Mất đồng thời Kafka và pod ghi spool | Mất các bản ghi giao dịch chưa gửi | Rủi ro dư của SDD §13.2 (Q14-22); đối soát với trung ương theo `transactionCode` |
| Mất phân vùng đã `DETACH` nhưng chưa xuất WORM | Mất bằng chứng quá 12 tháng | `LedgerArchiver` chỉ `DETACH` sau khi xác minh băm đối tượng WORM; phân vùng đã tháo giữ 7 ngày rồi mới `DROP` |

: Tình huống khôi phục

### 7.3. Dung lượng

Tính cho một tenant "tỉnh vừa" ở mức lưu giữ tối đa; giả định kích thước dòng gồm dữ liệu và chỉ mục, làm tròn; số dòng theo §3.1.

| Đối tượng | Số dòng mỗi năm | Byte mỗi dòng | Dung lượng đang giữ |
|---|---|---|---|
| `national_transaction` | 54,75 triệu (150.000 mỗi ngày) | 1.100 | ≈ 60 GB (12 tháng trực tuyến) |
| `usage_hourly` | 1,6 triệu | 150 | ≈ 0,5 GB (24 tháng) |
| `parallel_sample` | 1,5 triệu trong đợt chuyển đổi | 200 | ≈ 0,3 GB (90 ngày) |
| `async_request` | 1,8 triệu | 600 | ≈ 0,3 GB (90 ngày) |
| `health_sample` | 17.000 mỗi ngày | 130 | ≈ 0,2 GB (90 ngày) |
| `service_spec` | 1.500 phiên bản | 150.000 trước nén | ≈ 0,1 GB sau nén TOAST (≤ 0,2 GB) |
| `cache_stats`, `quota_usage` | 1,1 triệu | 100 | ≈ 0,2 GB |
| `outbox`, các bảng còn lại | Nhỏ | — | ≈ 0,1 GB |
| **Tổng PostgreSQL** | | | **≈ 62 GB mỗi tenant**; cận trên toàn cụm 34 tenant khoảng 2,1 TB nếu mọi tenant là "tỉnh vừa" |
| Ceph `dh-nat-payload` | Hai đối tượng mỗi lượt gọi thật, 4 KiB mỗi đối tượng (giả định) | — | ≈ 36 GB ở mặc định 30 ngày (cận trên) |
| Ceph WORM sổ giao dịch | 54,75 triệu dòng mỗi năm nén 4:1 | — | ≈ 15 GB mỗi năm, 75 GB sau 5 năm |

: Dung lượng giả định mỗi tenant

Sổ giao dịch chiếm gần 97% dung lượng PostgreSQL; phân vùng tháng giữ mỗi phân vùng khoảng 5 GB nên bảo trì, sao lưu và `DETACH` đều nhẹ. Dung lượng thật đo ở kiểm thử dung lượng NFR-14-019; số này dùng cho định cỡ `pg-core` ở D03-09.

### 7.4. Mã hóa

Không cột nào của schema chứa bí mật hay dữ liệu cá nhân thô nên không cần mã hóa trường ở PostgreSQL (khác PH-19 có DLCN người nộp): nội dung bản tin mã hóa envelope ở Ceph (ADR-032), đối tượng được tra chỉ còn `lookup_key_hash` (HMAC-SHA256 bằng khóa tenant, không đảo ngược, không đối chiếu được giữa các tenant), chứng thư chỉ chuỗi công khai. Phần còn lại dựa vào mã hóa ổ đĩa và sao lưu của `pg-core`, TLS giữa ứng dụng và CSDL theo D03-09, và cách ly tenant ở §1.2.

## 8. Ánh xạ dữ liệu hệ cũ sang thiết kế mới

Hệ cũ chỉ có hai nguồn liên quan tới kết nối quốc gia: (a) cấu hình NGSP của LGSP đang vận hành, nằm trong "phụ lục kết nối NGSP" (tài liệu, không phải bảng CSDL) cùng tệp cấu hình của dịch vụ gọi (D00-03 `LGC-NGSP-001…008`, `LGC-DMDC-019`); (b) mô hình dữ liệu trong SRS cũ của repo (`docs/07-srs/SRS-PH-14-national.md` §4), chưa được triển khai thành CSDL. Lược đồ CSDL thật của Bus và Aita chưa có trong tài liệu được cung cấp (giả định: không có bảng riêng cho kết nối NGSP; đối chiếu khi có bản xuất của tỉnh). Vì vậy di trú là **nhập có duyệt** (FR-14-056), không chép bảng; bảng ở 8.2 bảo đảm mô hình mới không sót thuộc tính của mô hình cũ và là đầu vào cho D06-01.

### 8.1. Phụ lục kết nối NGSP của hệ cũ

Phụ lục NGSP là tài liệu có cấu trúc dạng bảng nên nhập được bằng tệp CSV hoặc XLSX. Bảng dưới nói từng loại thông tin của phụ lục đi đâu trong mô hình mới và loại nào cố ý không được chuyển.

| Nguồn hệ cũ | Đích | Cách chuyển |
|---|---|---|
| Mã dịch vụ (`Service-code`) từng dòng phụ lục | `national_service.national_service_code` | Nhập CSV hoặc XLSX, ghép theo (nền tảng, mã, hướng); mã nội bộ `code` sinh từ tên theo mẫu `^[a-z][a-z0-9-]{2,62}$` |
| Tên dịch vụ, nhóm (bảy phụ lục LLTP, hộ tịch, BHXH, ĐVQHNS, ĐKDN, VBQPPL, danh mục dùng chung) | `name`, `service_group` | Nhóm gán theo phụ lục chứa dòng; dòng không rõ nhóm vào `OTHER` |
| Thao tác (tra cứu, đăng ký, cập nhật) | `operation_type` (`READ`, `WRITE`), `idempotent` | Thao tác ghi mặc định `idempotent = false` cho tới khi xác nhận (Q14-01) |
| Địa chỉ WSDL, địa chỉ dịch vụ | `spec_url` | Chỉ giữ nếu nằm trong danh sách egress; địa chỉ IP công khai chạy HTTP không chuyển |
| Mỗi dòng phụ lục | `legacy_ref` | Ghi tên tệp và số dòng để truy vết; không chứa bí mật |
| Consumer Key, Secret (văn bản trong phụ lục) | Không chuyển | `SecretColumnGuard` bỏ cột; `legacy_import.findings` ghi vị trí (dòng, cột), không ghi giá trị; sau cắt chuyển phải cấp lại khóa và xác nhận khóa cũ đã thu hồi (BR-14-034, FR-14-025) |
| Địa chỉ và cổng lấy token (AM) | `national_platform.connection_code` | Kết nối PH-05 theo từng môi trường qua TLS; xác thực `client_credentials` (OAuth 2.1) thay cho Consumer Key |
| Kết nối danh mục dùng chung của Aita (`LGC-DMDC-019`) | Nền tảng `NDXP_DMDC` ở `COMMON` | Khai báo mới bởi PA; thông tin xác thực không chuyển (Q14-14 của FRS) |
| Thời hạn chờ, số lần thử lại trong cấu hình cũ | `default_timeout_ms`, `timeout_ms`; tham số `14.retry.*` ở PH-18 | Chuyển giá trị nếu nằm trong miền; ngoài miền dùng mặc định và ghi cảnh báo |

: Phụ lục kết nối NGSP của hệ cũ sang thiết kế mới

### 8.2. Mô hình dữ liệu của SRS cũ trong repo

Bảng liệt kê từng thực thể và cột của SRS cũ, kèm chuyển đổi kiểu. Cột có dấu mũi tên là chuyển đổi cần quy tắc; thuộc tính mới không có ở mô hình cũ (bốn mắt, bất biến, nội dung mã hóa) không nằm trong bảng.

| Thực thể, cột cũ | Đích | Chuyển đổi |
|---|---|---|
| `NEN_TANG_QG.nen_tang_id` UUID | `national_platform.id` | `uuid` giữ nguyên |
| `ma_nen_tang` ∈ `NDXP`, `NDOP`, `HTBO` | `platform_type` ∈ `NDXP`, `NDOP`, `REGISTRY` | `HTBO` (hệ thống của Bộ) thành `REGISTRY`; thêm `code` chữ thường bất biến |
| `ten`, `co_quan_chu_quan` | `name`, `owner_agency` | `varchar(120)` sang `varchar(200)` |
| `diem_cuoi` varchar(300) | Không lưu | Địa chỉ thuộc kết nối PH-05 (`connection_code`), một nơi duy nhất |
| `giao_thuc` ∈ `SOAP`, `REST`, `MQ` | `national_service.protocol` ∈ `REST`, `SOAP` | Chuyển xuống mức dịch vụ; `MQ` không hỗ trợ ở PH-14 (qua PH-05, PH-10) |
| `trang_thai` ∈ `ACTIVE`, `REGISTERING`, `SUSPENDED`, `INACTIVE` | `state` | `ACTIVE`→`ACTIVE`; `REGISTERING`→`DRAFT`; `SUSPENDED`→`SUSPENDED`; `INACTIVE`→`RETIRED`; thêm `TESTED`, `PENDING_ACTIVATION` |
| `dac_ta_tam_thoi` boolean | `spec_status` ∈ `OFFICIAL`, `PROVISIONAL` | `true`→`PROVISIONAL` |
| `DICH_VU_QG.ma_dich_vu` varchar(80) UNIQUE | `national_service_code` | Khóa duy nhất theo (tenant, nền tảng, mã, hướng) thay vì toàn cục |
| `csdl_dich` (`DANCU`, `DKKD`, `BHXH`…) | `service_group` | `DKKD`→`DKDN`; `BHXH`→`BHXH`; còn lại→`OTHER` cho tới khi có phụ lục (Q14-01) |
| `wsdl_uri`, `dinh_dang` | `spec_url`; `service_spec.kind` | Đặc tả nạp thành phiên bản `service_spec` có `checksum` |
| `timeout_ms` integer | `timeout_ms integer` | Ràng buộc miền 1.000 đến 60.000 |
| `cache_ttl_giay`, `cho_phep_dem` | `cache_ttl_seconds`, `cacheable` | `cacheable` bị ép `false` với `SENSITIVE` và thao tác ghi |
| `muc_uu_tien` smallint | `priority` ∈ `ESSENTIAL`, `NORMAL`, `BACKGROUND` | 1→`ESSENTIAL`, 2→`NORMAL`, từ 3→`BACKGROUND` (giả định, đổi từ số sang liệt kê) |
| `LUAT_DINH_TUYEN.loai_du_lieu`, `csdl_dich`, `thao_tac` | `match_group`, `operation_type` | Luật theo nhóm; luật theo một dịch vụ dùng `match_service_code` |
| `dich_vu_id`, `dich_vu_du_phong` (UUID) | `primary_service_code`, `fallback_service_code` (mã) | Đổi từ khóa ngoại sang mã vì có thể là dịch vụ `COMMON` |
| `do_uu_tien` smallint | `priority` 1 đến 1.000 | Số lớn là ưu tiên cao; nếu mô hình cũ nhỏ là cao thì đảo (`1001 - giá trị`), xác nhận khi có dữ liệu |
| `can_cu` | `basis` | `varchar` 10 đến 500 ký tự, bắt buộc |
| `CHUNG_THU.ma_chung_thu` (số sê-ri) | `serial_number`; `code` chữ thường | Hai khái niệm tách đôi |
| `chu_the`, `to_chuc_cap` | `subject`, `issuer` | `varchar(300)`, `varchar(200)` sang `varchar(500)` |
| `vault_key_ref` varchar(200) | `key_ref` varchar(255) | Vault sang OpenBao `transit/keys/dh-{tenant}-…`; không khớp mẫu thì từ chối |
| `hieu_luc_tu`, `het_han` | `not_before`, `not_after` | `timestamptz` giữ nguyên |
| `trang_thai` ∈ `ACTIVE`, `EXPIRING`, `EXPIRED`, `REVOKED` | `state` | Thêm `UPLOADED`, `PENDING_ACTIVATION`, `SUPERSEDED` |
| `muc_dich` | `purpose` | Giữ ba giá trị `SIGNING`, `TLS_CLIENT`, `BOTH` |
| `GIAO_DICH_QG.ma_giao_dich` UNIQUE | `transaction_code` | Duy nhất theo (tenant, mã, `started_at`) vì phân vùng (Q14-50) |
| `dich_vu_id`, `chung_thu_id` | `service_code`, `cert_code` | Theo mã |
| `chieu` | `direction` | Giữ `OUTBOUND`, `INBOUND` |
| `trace_id` varchar(64) | `trace_id char(32)` | Bắt buộc 32 ký tự hexa theo W3C; giá trị khác định dạng không chuyển được |
| `trang_thai` ∈ `SENT`, `SUCCESS`, `FAILED`, `TIMEOUT`, `REJECTED`, `QUOTA_EXCEEDED` | `state` | `SUCCESS`→`SUCCEEDED`; thêm `RECEIVED`, `COMPLETED_CACHE`, `SIGNATURE_FAILED`, `UNKNOWN_RESULT` |
| `thoi_gian_phan_hoi_ms`, `tu_dem` | `duration_ms`, `from_cache` | Giữ |
| `ma_loi` TEXT | `error_code varchar(16)` | Mã chuẩn hóa `ERR-14-1xx`; nội dung lỗi gốc của trung ương không lưu vì có thể chứa DLCN |
| `gui_luc`, `nhan_luc` | `started_at`, `finished_at` | `timestamptz` |
| `KET_QUA_XAC_MINH` (bốn cờ boolean, `chi_tiet_loi` TEXT) | `verify_result`, `signature_incident.kind`, `detail` | Bốn cờ thành loại sự cố (`SIGNATURE_MISMATCH`, `UNTRUSTED_CHAIN`, `REVOKED_CERT`, `STALE_TIMESTAMP`); chi tiết lỗi thành `jsonb` đã che |
| `HAN_MUC.ma_dich_vu`, `chu_ky`, `gioi_han` bigint | `quota_policy.service_code`, `period`, `limit_count bigint` | Giữ; `limit` đổi tên vì từ khóa |
| `can_cu_van_ban` varchar(300) | `basis_document varchar(500)` | Bắt buộc 10 đến 500 ký tự (BR-14-011) |
| `SU_DUNG_HAN_MUC.ngay` date, `da_dung`, `dat_lai_luc` | `quota_usage.bucket_start`, `used`, `reset_at` | `date` thành `timestamptz` đầu chu kỳ (giờ Việt Nam); thêm `period`, `env` |
| `TRANG_THAI_KET_NOI` (`muc_suc_khoe`, `do_tre_ms`, `ty_le_thanh_cong`, `so_loi_chu_ky`) | `health_sample` (`level`, `p95_ms`, `calls_ok`, `calls_error`) | Giữ 90 ngày theo NFR-14-021 thay cho 1 năm của mô hình cũ |
| `DONG_BO_DANH_MUC` (`so_dich_vu_gui`, `so_chap_nhan`, `so_tu_choi`) | `sync_run` (`sent`, `accepted`, `rejected`, `pending`) | Thêm `pending`; đối soát gửi = nhận + từ chối + chờ |

: Mô hình dữ liệu SRS cũ sang thiết kế mới

### 8.3. Đối soát sau nhập và cắt chuyển

`legacy_import` ghi mỗi lần nhập: số dòng, số dịch vụ tạo, bỏ qua, lỗi và các vị trí cột bí mật đã bỏ. Nhập tất cả hoặc không (`ck_legacy_import_all_or_nothing`): một dòng sai thì không dịch vụ nào được tạo (ERR-14-032). Đầu vào nghiệm thu bước chuyển đổi của D06-01: số dịch vụ nhập bằng số dòng phụ lục trừ dòng trùng bỏ qua; mọi dịch vụ nhập vào ở `DRAFT`, `reconcile_label = UNKNOWN`; sau chạy song song, `parallel_run.ready_for_cutover = true` cho từng dịch vụ đọc và `old_key_revocation_confirmed = true` trước khi đóng phiên; mỗi (nền tảng, môi trường) có một `credential_rotation` `DONE` với biên nhận thu hồi khóa cũ.

## 9. Câu hỏi mở

> **Câu hỏi mở Q14-50:** Khóa duy nhất của `national_transaction` chứa `started_at` nên mã giao dịch chỉ duy nhất trong cùng `started_at`; PH-19 giải quyết bằng bảng chỉ mục mã giao dịch không phân vùng (ADR-047). Có cần bảng tương tự cho PH-14 để chặn trùng khi cổng gửi lại bản ghi đầu với `started_at` khác? Đề xuất tạm: không thêm, cổng giữ nguyên `started_at` ở mọi bản ghi của giao dịch (đã là hợp đồng của EVT-14-11); kiểm bằng ca hỗn loạn Kafka giao lại ở D05-02-PH14. Cần kiến trúc sư `dh-runtime` xác nhận.

> **Câu hỏi mở Q14-51:** Dung lượng `national_transaction` ở "tỉnh vừa" khoảng 60 GB cho 12 tháng trực tuyến (§7.3); với 34 tenant tới 2,1 TB ở `pg-core`. Chấp nhận giữ 12 tháng trực tuyến ở PostgreSQL, hay giảm xuống 3 đến 6 tháng và truy vấn lịch sử qua ClickHouse của PH-13? Đề xuất tạm: giữ 12 tháng (khớp SEC-62), đánh giá chuyển khi một tenant vượt 50 triệu dòng mỗi tháng hoặc truy vấn p95 vượt NFR-14-025. Cần nhóm vận hành `pg-core` và PH-13 xác nhận.

> **Câu hỏi mở Q14-52:** Nội dung đặc tả dịch vụ (≤ 5 MB) lưu trong `service_spec.content` (TOAST nén) để kích hoạt cùng giao dịch. PH-05 lưu tệp tương tự ở bucket `dh-adapter-spec`. Có nên dùng chung bucket đó (khóa `{tenant}/national/{dịch vụ}/{phiên bản}/{sha256}`) để giảm kích thước CSDL và thống nhất cách lưu? Đề xuất tạm: giữ trong PostgreSQL vì cổng cần nạp trong 30 giây không phụ thuộc thêm kho ngoài, ước tính dưới 0,2 GB mỗi tenant. Cần trưởng nhóm PH-05 và PH-14 thống nhất.

> **Câu hỏi mở Q14-53:** Dòng `COMMON` của bảng mẫu P (sổ giao dịch, chứng thư, hạn mức, sức khỏe của cổng `COMMON`) chỉ ghi được khi `app.tenant_id = 'PLATFORM'`, nên `LedgerConsumer` và các tác vụ nền phải đặt `PLATFORM` cho lô `COMMON`; vai trò có quyền rộng hơn mức cần. Có cần vai trò riêng giới hạn (ví dụ `ph14_common_writer` chỉ ghi dòng `COMMON`) hay chấp nhận `PLATFORM`? Đề xuất tạm: chấp nhận `PLATFORM` vì phiên này không dùng được từ API người dùng (token tenant không đặt được), kèm kiểm thử rò rỉ chéo ở CI (SEC-87). Cần ATTT xác nhận.

> **Câu hỏi mở Q14-54 (đã chốt một phần 27/11/2026):** Chủ đầu tư chốt 27/11/2026: `usage_hourly` giữ 24 tháng, `cache_stats` giữ 13 tháng, `async_request` giữ 90 ngày sau khi kết thúc; ba giá trị này đã vào NFR-14-021 và không còn là giả định. Các thời hạn còn ghi "giả định" (`worker_command` 30 ngày, `platform_outage` và `legacy_import` 3 năm, `health_sample` 90 ngày thay cho 1 năm của SRS cũ) vẫn dùng như bảng cho tới khi có quyết định riêng; mọi giá trị là tham số của tác vụ dọn, đổi không cần đổi cấu trúc bảng.

## Đề nghị đồng bộ

> **Đợt đồng bộ chéo cuối (27/11/2026).** Các đề nghị dưới đây đã được xét; kết luận từng dòng (đã sửa, đã khớp sẵn, câu hỏi mở, không làm) ghi ở [D00-03-01 Sổ đồng bộ chéo cuối](../../00-chung/D00-03-01-so-dong-bo-cuoi.md).

Các việc dưới đây cần sửa ở tài liệu dùng chung hoặc tài liệu của phân hệ khác; tập này không sửa trực tiếp vì các luồng viết chạy song song. Đề nghị thực hiện trong đợt đồng bộ cuối. Không có đề xuất ADR mới ngoài bốn ADR đã nêu ở mục Đề nghị đồng bộ của SDD.

| Tài liệu | Nội dung đề nghị | Lý do |
|---|---|---|
| D03-02-PH14 (SDD) §4.16, §8.1 | Ghi rõ `LedgerConsumer` dùng `INSERT … ON CONFLICT (tenant_id, transaction_code, started_at) DO UPDATE … WHERE` theo hạng (không phải `DO NOTHING` như §4.16), và `UsageAggregator` chỉ cộng khi dòng vừa chuyển sang trạng thái cuối (`finished_at` vừa được đặt) | Hai đoạn của SDD hiện nói khác nhau; CSDL hiện thực cách thứ hai (khối kiểm 14e) |
| D03-02-PH14 (SDD) §4 | Bổ sung bảng và cột phát sinh từ thiết kế CSDL: `approval_request`, `worker_command`, `access_block`, `inbound_route`, `health_state`, `cache_stats`; `breaker_override` ở `national_platform`; `last_warned_level` ở `quota_usage`; hợp đồng dịch vụ ở `service_spec.contract`; khóa đối tượng kết quả bất đồng bộ `{tenant}/async/{requestId}.res.enc` thay cho `dh-nat-payload/async/` để có tiền tố tenant | Khớp SDD với DDL |
| D03-02-PH14 (SDD) §3, §8 | Thêm các tác vụ nền: `PartitionMaintenanceJob`, `HealthRollupJob`, `RetentionJob`, `LedgerArchiver` (đã có), bộ quét lệnh `worker` quá hạn, dọn `outbox`, và lớp ánh xạ lỗi lưu trữ theo §1.5 | Việc vận hành phát sinh từ phân vùng và lưu giữ |
| D02-03-PH14 (FRS) §4.2 | Sửa EN-14-10: loại `SERVICE_RECONCILE` lưu ở `reconcile_run`, không ở `sync_run`; thêm thực thể hỗ trợ `approval_request`, `worker_command`, `inbound_route`, `access_block`, `credential_rotation`, `trust_anchor` | Khớp FRS với thiết kế dữ liệu |
| D02-03-PH14 (FRS) §8.1 | Thêm vào NFR-14-021 thời hạn `usage_hourly`, `cache_stats`, `async_request` sau khi Q14-54 được trả lời | Đủ các thời hạn lưu giữ |
| D03-04-PH14 (API) | Dùng bảng chuyển lỗi §1.5 cho `PersistenceExceptionMapper`; phân trang keyset theo (`started_at`, `transaction_code`); `ETag` là `version` | API và CSDL nhất quán |
| D03-10 | Ghi PH-14 dùng mẫu S cho `national_platform`, `national_service`, `service_spec`; ghi quy ước phiên `PLATFORM` ghi dòng `COMMON` của bảng mẫu P và rủi ro Q14-53 | Mẫu RLS dùng chung |
| D03-09 | Định cỡ `pg-core` thêm khoảng 62 GB mỗi tenant "tỉnh vừa" ở năm đầu (cận trên 2,1 TB cho 34 tenant); định cỡ Ceph `dh-nat-payload`, `dh-nat-trust`, `dh-nat-sync` và bucket WORM sổ giao dịch (tên chính thức, vòng đời) | Số liệu §7.3 |
| D03-07 | Thống nhất tên khóa `transit` (`dh-{tenant}-nat-sign-*` ở SDD, `dh-{tenant}-national-sign` ở FRS) theo mẫu `^transit/keys/dh-{tenant}-[a-z0-9-]+$` mà CSDL kiểm; ghi `lookup_key_hash` là biện pháp cho THR-54 | Nhất quán tên khóa |
| D05-02-PH14 | Dùng 85 khối của `ph14_isolation_test.sql` làm cơ sở cho nhóm ca cô lập tenant, bốn mắt, chống lộ bí mật, bất biến; thêm ca hỗn loạn Kafka giao lại (Q14-50) | Khung kiểm thử |
| D06-01 | Dùng §8 làm bảng ánh xạ cho di trú NGSP; kiểm đối soát §8.3 | Di trú và cắt chuyển |

: Đề nghị đồng bộ cho tài liệu dùng chung và phân hệ khác

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu của tập CSDL PH-14 theo khuôn K-CSDL và chuẩn trình bày K-TRINH-BAY: chiến lược lưu trữ, 36 bảng (khối 10 mục sinh từ DDL), bốn sơ đồ thực thể, DDL sáu tệp 47 changeset, 85 khối kiểm cô lập đạt, kho ngoài PostgreSQL, lưu giữ và dung lượng, ánh xạ hệ cũ, 5 câu hỏi mở (Q14-50…54) và mục Đề nghị đồng bộ. Căn cứ: FRS, use case, SDD PH-14, SAD §4, ADR-003, 046, 047, 057, D03-10 |
| 0.2 | 27/11/2026 | Nhóm viết tài liệu (Claude) | Đồng bộ chéo cuối: Số tham số 51; chốt câu hỏi mở đợt đồng bộ: Q420 |




