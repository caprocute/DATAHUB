---
ma_tai_lieu: D03-03-PH03
ten: Thiết kế cơ sở dữ liệu phân hệ PH-03 Cổng API
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, DBA, ATTT, hội đồng thẩm định
phan_he: PH-03
mo_ta: Thiết kế cơ sở dữ liệu mặt phẳng điều khiển của phân hệ Cổng API gồm 35 bảng schema ph03_gateway, ràng buộc nghiệp vụ, RLS theo tenant, máy trạng thái, DDL đã chạy thử, kho ngoài PostgreSQL, sao lưu và ánh xạ dữ liệu hệ cũ.
tai_lieu_lien_quan: D02-03-PH03 FRS; D02-04-PH03 Use case; D03-02-PH03 SDD; D03-10 Đa tenant; D02-07 Từ điển dữ liệu
---

# D03-03-PH03 · Thiết kế CSDL Cổng API

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Schema `ph03_gateway` trên cụm `pg-core` lưu toàn bộ dữ liệu **điều khiển** của cổng API: route, upstream, consumer, chính sách chiếu từ gói sử dụng, ngoại lệ luật WAF, yêu cầu thay đổi bốn mắt, siêu dữ liệu ảnh chụp cấu hình và tham số `gw.*` của từng tenant. Schema có 35 bảng, hiện thực 14 trong 15 thực thể của [D02-03-PH03](../../02-yeu-cau/frs/D02-03-PH03-frs-cong-api.md) §4.2 (thực thể nút gateway được suy ra từ chỉ số, không lưu) cùng các bảng phụ trợ. Dữ liệu **lượt gọi** (nhật ký, bộ đếm hạn mức, chỉ số) không ở PostgreSQL mà ở ClickHouse, Valkey và Mimir (chương 6), vì APISIX không kết nối cơ sở dữ liệu lúc chạy (NFR-03-007).

**Phạm vi.** Tài liệu gồm chiến lược lưu trữ và cách ly tenant, sơ đồ thực thể, đặc tả 35 bảng trích từ DDL, kho ngoài PostgreSQL, sao lưu và lưu giữ, ánh xạ dữ liệu hệ cũ. DDL [`ph03/ddl/ph03_gateway.sql`](ph03/ddl/ph03_gateway.sql) đã chạy thử trên PostgreSQL 16.16 và bài kiểm [`ph03/test/ph03_isolation_test.sql`](ph03/test/ph03_isolation_test.sql) đạt 80/80 phép kiểm (§4.2).

**Căn cứ.** NFR-00 (cách ly tenant, nhật ký, lưu giữ), SEC-24, SEC-80, SEC-81, SEC-87 (D03-07), ADR-003 (PostgreSQL, RLS theo `tenant_id`), ADR-005 và ADR-033 (APISIX khai báo, không etcd), CMP-LAW-09 (Công văn 631/THH-THHT: thời hạn chờ tối đa 30.000 ms), CMP-LAW-05 (Luật BVDLCN 91/2025: không ghi dữ liệu cá nhân).

**Những điểm hội đồng cần lưu ý.**

1. **Cơ sở dữ liệu là nguồn sự thật, gateway chỉ nhận bản phái sinh.** Cấu hình đi tới nút APISIX bằng ảnh chụp có số phiên bản và chữ ký; số phiên bản được cấp trong một giao dịch có khóa và không bao giờ lùi, nội dung đã ký bất biến ở cả bảng lẫn trigger. Mất Valkey hay bucket không làm mất dữ liệu, vì tác vụ đối chiếu dựng lại từ PostgreSQL (§1.6).
2. **Không có bí mật trong CSDL.** Bảng chỉ lưu vân tay chứng thư, băm khóa API và đường dẫn tới OpenBao. Ràng buộc `CHECK` chặn khóa API dạng rõ, khóa riêng PEM trong chứng thư CA, khóa có tên bí mật trong sự kiện (SEC-24, BR-03-007); đây là lớp phòng thủ thứ hai sau bộ lọc `SecretFieldGuard` ở dịch vụ.
3. **Quy tắc bốn mắt, thời hạn và vòng đời được khóa ở CSDL, không chỉ ở dịch vụ.** Ngoại lệ WAF tối đa 90 ngày và người duyệt khác người đề nghị; mở route ra Internet và đổi WAF sang chặn cần yêu cầu thay đổi đã duyệt; WAF chỉ sang `BLOCK` sau 14 ngày phát hiện; mã route, consumer không dùng lại; mười một máy trạng thái chỉ đi theo bảng chuyển trạng thái. Người viết dịch vụ sai thì CSDL vẫn từ chối.
4. **Cách ly tenant bằng `FORCE ROW LEVEL SECURITY` trên 32 bảng** và khóa ngoại luôn kèm `tenant_id`. Chỉ có năm khóa duy nhất cắt ngang tenant (host, vân tay chứng thư, băm khóa API, số phiên bản ảnh chụp theo site, tenant nguồn của chuyển tiếp sáp nhập), mỗi khóa có lý do ở §1.2; hai khóa đầu có rủi ro lộ sự tồn tại và được nêu ở Q03-53.
5. **Hệ cũ không có bảng tương ứng.** Gateway cũ cấu hình bằng tệp YAML viết tay (`ApisixRouteWriter`) và khối APIM kiểu Gravitee có lược đồ chưa được cung cấp; việc chuyển dữ liệu đi qua nhập gói xuất có duyệt (FR-03-059), không chép bảng (chương 8, Q03-50).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Bảng | 35 (32 có RLS: 28 mẫu P, 4 mẫu S; 3 bảng kỹ thuật không có `tenant_id`) |
| Ràng buộc | 214 `CHECK`, 24 khóa ngoại, 27 khóa duy nhất, 35 khóa chính; 110 chỉ mục (29 chỉ mục một phần) |
| Trigger, hàm | 72 trigger, 10 hàm và thủ tục |
| Máy trạng thái ở CSDL | 11 máy, 47 cặp chuyển hợp lệ |
| Dữ liệu khởi tạo | 66 tham số `gw.*`, 47 cặp chuyển trạng thái, 2 bộ đếm site |
| Kiểm thử | 80 phép kiểm ở 40 nhóm, đạt trên CSDL rỗng và trên schema dựng lại |

: Con số chính của thiết kế CSDL PH-03

## 0. Giới thiệu

### 0.1. Mục đích và phạm vi

Tài liệu đặc tả lược đồ dữ liệu của PH-03 trong schema `ph03_gateway` của `pg-core`: chiến lược lưu trữ và cách ly tenant (chương 1), sơ đồ thực thể – quan hệ (chương 2), đặc tả 35 bảng (chương 3), DDL và changelog (chương 4), dữ liệu khởi tạo (chương 5), kho ngoài PostgreSQL (chương 6), sao lưu và lưu giữ (chương 7), ánh xạ dữ liệu hệ cũ (chương 8). Mỗi bảng ở chương 3 mở đầu bằng một bảng đặc tả 10 mục (Mục đích, FR phục vụ, Khóa chính, Duy nhất, Khóa ngoại, Ràng buộc CHECK, Chỉ mục, Cách ly tenant, Phân vùng và chỉ thêm, Ghi chú) trích từ DDL đã chạy thử, rồi đến danh sách cột.

Phạm vi là **mặt phẳng điều khiển** của PH-03 ở `dh-connect` (module `gateway`). Phần mặt phẳng dữ liệu (APISIX, plugin, `dh-sync`) không có CSDL; dữ liệu của nó là tệp ảnh chụp, khóa Valkey và chỉ số, được mô tả ở chương 6 vì hai mặt phẳng chung các định dạng đó (SDD §3.4).

### 0.2. Người đọc

| Người đọc | Phần cần đọc |
|---|---|
| Kỹ sư `dh-connect` (module `gateway`) | Chương 1, 3, 4, 6 |
| DBA, vận hành | Chương 1, 4, 6, 7 |
| Cán bộ ATTT | Mục 1.2, 1.4, 1.5; bảng 3.7, 3.15 đến 3.17, 3.19, 3.20, 3.28; chương 7 |
| Hội đồng thẩm định | Tóm tắt, chương 2, chương 8, chương 9 |

: Người đọc và phần cần đọc

### 0.3. Thuật ngữ và chữ viết tắt

Thuật ngữ dùng chung với [D02-03-PH03](../../02-yeu-cau/frs/D02-03-PH03-frs-cong-api.md) §1.4 và D00-01 (kiểu dữ liệu chuẩn ở D00-01 §5). Một số thuật ngữ riêng của tài liệu này:

| Thuật ngữ | Nghĩa |
|---|---|
| RLS (Row Level Security) | Cơ chế của PostgreSQL lọc dòng theo chính sách; `FORCE` áp cả cho chủ bảng |
| Mẫu P, mẫu S | Hai mẫu chính sách RLS của D03-10: P riêng từng tenant, S dùng chung có dòng `COMMON` |
| Phiên `PLATFORM` | Phiên kỹ thuật (`app.tenant_id = 'PLATFORM'`) dùng cho dữ liệu `COMMON` và dữ liệu khởi tạo; không phải tenant |
| Ảnh chụp cấu hình | Tệp khai báo đầy đủ trạng thái mong muốn của gateway, có số phiên bản và chữ ký; nội dung ở bucket và Git, siêu dữ liệu ở bảng `config_snapshot` |
| Bốn mắt | Thay đổi cần người thứ hai, khác tài khoản người đề nghị, duyệt (BR-03-019) |
| Xóa mềm | Không xóa dòng, chuyển trạng thái hoặc đặt `retired_at`, `deleted_at`; mã không dùng lại (BR-03-029) |
| Ghi một lần (write-once) | Cột đã có giá trị thì không sửa được; trigger `tg_write_once` |
| EN, BR, FR, EVT | Mã thực thể, quy tắc nghiệp vụ, yêu cầu chức năng, sự kiện của PH-03 theo FRS |

: Thuật ngữ riêng của tài liệu

### 0.4. Tài liệu tham chiếu

D02-03-PH03 (FRS: thực thể EN-03, BR-03, tham số §8.2, sự kiện §9.3), D03-02-PH03 (SDD: §3.4 hợp đồng dữ liệu, §4.7 mô hình miền, §8.1 bảng chuyển trạng thái), D03-10 (đa tenant: mẫu RLS P và S, hạn mức tenant, sáp nhập), D02-07 (thực thể dùng chung, DD-11 outbox), D03-07 (SEC), D03-09 (hạ tầng, sao lưu), D00-01 §5 (kiểu chuẩn, cột ngữ cảnh), `docs/07-srs/SRS-PH-03-gateway.md` §M4 (mô hình dữ liệu của SRS cũ).

### 0.5. Cấu trúc tài liệu

| Chương | Nội dung |
|---|---|
| 1 | Chiến lược lưu trữ: schema, vai trò, cách ly tenant, quy ước, quy tắc chốt ở CSDL, máy trạng thái, nơi lưu từng loại dữ liệu |
| 2 | Sơ đồ thực thể – quan hệ (ba hình) |
| 3 | Đặc tả 35 bảng theo bảy nhóm A đến G; truy vấn chính và chỉ mục |
| 4 | DDL, changelog Liquibase, kết quả chạy thử |
| 5 | Dữ liệu khởi tạo |
| 6 | Kho ngoài PostgreSQL: Valkey, bucket và Git, OpenBao, Kafka, ClickHouse, Mimir |
| 7 | Sao lưu, khôi phục, mã hóa, lưu giữ |
| 8 | Ánh xạ dữ liệu hệ cũ sang thiết kế mới |
| 9 | Câu hỏi mở; sau đó là Đề nghị đồng bộ |

: Cấu trúc chương của D03-03-PH03

## 1. Chiến lược lưu trữ

### 1.1. Schema, vai trò và kết nối

Schema `ph03_gateway` (quy ước `ph{nn}_{miền}`) do `ph03_owner` (NOLOGIN) sở hữu. `dh-connect` kết nối bằng `dh_connect_app`, thành viên của `ph03_app` (chỉ DML, không `BYPASSRLS`); Liquibase chạy bằng `dh_connect_migrator` (thành viên `ph03_owner`); báo cáo và kiểm toán đọc bằng `ph03_readonly`, vai trò này không đọc được nội dung luật vá WAF (`waf_virtual_patch.rule_text`), thân phản hồi lũy đẳng và bản PEM của bộ CA (quyền theo cột, `03-0900-grants.sql`). Module `gateway` và các module cùng DU (`catalog` của PH-02, `onboarding` của PH-01) mỗi module chỉ đọc ghi schema của mình; PH-03 lấy dữ liệu nguồn qua `catalog.api` và `onboarding.api` (lớp `SourceReader`), không truy vấn schema của PH-01, PH-02.

Ba thành phần **không** kết nối schema này: (1) APISIX và plugin, vì nút chỉ đọc ảnh chụp ở bucket hoặc ConfigMap, khóa Valkey và gửi chỉ số, nên control plane ngừng thì gateway vẫn phục vụ tối thiểu 24 giờ (NFR-03-007); (2) `dh-sync` cạnh pod; (3) bộ chạy kiểm tra tổng hợp ở `dh-runtime`, nhận cấu hình qua ảnh chụp riêng (SDD §4.16). Không có schema cũ cần thay: bảng `ph04.route` (W2) là route của luồng tích hợp, khác route cổng API và giữ tách bạch (GAP-03-07).

### 1.2. Cách ly tenant

Mọi bảng nghiệp vụ có `tenant_id varchar(16)` và bật `FORCE ROW LEVEL SECURITY` qua `ph03_gateway.p_enable_rls(bảng, mẫu)`, cùng hai mẫu với PH-04 và PH-05. `TenantContextFilter` đặt `SET LOCAL app.tenant_id` đầu mỗi giao dịch từ token (D03-10 §3, SEC-81); biến phiên rỗng thì không thấy dòng nào.

| Mẫu | Đọc | Ghi | Bảng |
|---|---|---|---|
| P (riêng) | Dòng của tenant phiên; dòng `COMMON` chỉ phiên `PLATFORM` | Dòng của tenant phiên (`T{nn}`); dòng `COMMON` chỉ phiên `PLATFORM` | 28 bảng tác nghiệp |
| S (dùng chung) | Dòng của tenant phiên và `COMMON` | Dòng tenant khi phiên là tenant; dòng `COMMON` chỉ phiên `PLATFORM` | `waf_virtual_patch`, `edge_certificate`, `client_ca`, `param_definition` |

: Cách ly tenant

Tenant `COMMON` giữ phần dùng chung của nền tảng: tham số `gw.*` mặc định, chứng thư dùng chung (ví dụ `*.datahub.gov.vn`), CA của HTTT, luật vá WAF phạm vi nền tảng, và các dòng nền tảng của ảnh chụp (`scope = PLATFORM`). Mười bảng ở mẫu P cho phép dòng `COMMON` (`edge_host`, `upstream`, `upstream_node`, `route`, `route_state_event`, `config_snapshot`, `snapshot_violation`, `source_cursor`, `tls_exception`, `outbox`) để route nền tảng như cổng nhà phát triển và callback dùng chung có chỗ lưu (Q03-52); các bảng còn lại chỉ nhận `T{nn}` bằng `CHECK`.

Khóa ngoại luôn là `FOREIGN KEY (x_id, tenant_id) REFERENCES …(id, tenant_id)` nên một dòng không thể trỏ sang dòng của tenant khác (ca 8b, 8c của bài kiểm). Năm khóa duy nhất **cắt ngang tenant** có chủ đích; mỗi khóa phải toàn cục vì dữ liệu mà gateway hoặc luồng nghiệp vụ tra không có sẵn ngữ cảnh tenant:

| Khóa | Bảng | Lý do toàn cục | Rủi ro và cách xử lý |
|---|---|---|---|
| `uq_edge_host_pattern` | `edge_host` | Một host chỉ thuộc một tenant (BR-03-026) | Lỗi trùng lộ host đã có của tenant khác; dịch vụ ánh xạ về một thông báo chung (BR-03-028, Q03-53) |
| `uq_consumer_credential_thumb` | `consumer_credential` | Gateway tra consumer theo vân tay chứng thư khách (FR-03-014) | Một chứng thư dùng cho nhiều tenant bị chặn; HTTT quốc gia xem Q03-53 |
| `uq_consumer_credential_keyhash` | `consumer_credential` | Tra theo băm khóa API (giai đoạn chuyển đổi, SEC-24) | Băm 256 bit nên xác suất trùng ngẫu nhiên không đáng kể |
| `uq_config_snapshot_version` | `config_snapshot` | Số phiên bản tăng đơn điệu **theo site**, mọi tenant chung một dãy (BR-03-018) | Tenant chỉ thấy số của các lần tổng hợp do mình kích hoạt; số của tenant khác không lộ vì RLS |
| `uq_tenant_redirect_active` | `tenant_redirect` | Mỗi tenant nguồn chỉ một chuyển tiếp đang chạy; dòng thuộc tenant đích nên khóa không thể theo `tenant_id` (FR-03-037, ERR-03-025) | Khi tạo chuyển tiếp cho tenant nguồn đã có chuyển tiếp sang nơi khác, lỗi trùng cho biết sự tồn tại của nó; chỉ PA (`PERM-03-admin`) tạo chuyển tiếp nên chấp nhận được |

: Năm khóa duy nhất cắt ngang tenant

Ba bảng kỹ thuật không có `tenant_id` và không bật RLS: `state_transition` (bảng tham chiếu, ứng dụng chỉ đọc), `snapshot_counter` (một dòng mỗi site, chỉ chứa số) và `shedlock` (khóa tác vụ nền). Bài kiểm nhóm 40 kiểm bằng truy vấn danh mục rằng không bảng nào ngoài ba bảng này thiếu `FORCE RLS`, mọi bảng RLS có `tenant_id` và đủ bốn chính sách, và không vai trò nào có `BYPASSRLS`.

### 1.3. Quy ước bảng

Theo D00-01 §5.1: `id uuid` (UUID v7 sinh ở ứng dụng), `tenant_id`, `created_at`, `created_by`, `updated_at`, `updated_by`, `version` (trigger `tg_touch` tăng `version` và đặt `updated_at`). Trạng thái và danh mục nhỏ dùng `varchar` kèm `CHECK` liệt kê đúng FRS §4.3 đến §4.5; thêm giá trị là một changeset mới, không dùng kiểu `enum` của PostgreSQL vì khó đổi. Cột `jsonb` chỉ dùng cho cấu trúc cấu hình mở (`health_check`, `breaker`, `cors`, `rate_limits`, `quotas`, `payload`, `params`, `findings`) và luôn có `CHECK (jsonb_typeof(…))`. Tên ràng buộc theo tiền tố `pk_`, `uq_`, `fk_`, `ck_`, `ix_`, `tg_`, `rls_`.

| Bảng | Ngoại lệ so với cột ngữ cảnh | Lý do |
|---|---|---|
| `route_state_event`, `snapshot_violation` | Không có `version`, `updated_*`; có `occurred_at` hoặc `created_at` | Nhật ký chỉ thêm, không bao giờ sửa |
| `revoked_token`, `idempotency_key` | Không có `updated_*`, `version` | Chỉ thêm, xóa khi hết hạn; không bao giờ sửa |
| `outbox` | Khóa `event_id`, không có `id`, `version` | DD-11, cùng mẫu PH-04, PH-05 |
| `state_transition`, `shedlock`, `snapshot_counter` | Không có `tenant_id` | Bảng kỹ thuật (mục 1.2) |
| `config_snapshot` | Có thêm các cột thời điểm `built_at`, `signed_at`, `published_at`, `applied_at` | Vòng đời ảnh chụp (mục 4.5 FRS) |
| `route`, `consumer`, `emergency_block`, `waf_exception`, `waf_virtual_patch`, `rate_limit_override`, `ip_block`, `edge_host`, `tenant_redirect`, `tls_exception`, `change_request`, `config_snapshot`, `tenant_hold`, `waf_mode`, `param_definition`, `snapshot_counter` | Không xóa cứng; ứng dụng không có quyền `DELETE`, trigger `tg_no_delete` chặn cả chủ schema | BR-03-029: mã không dùng lại |

: Quy ước bảng và ngoại lệ

### 1.4. Quy tắc nghiệp vụ chốt ở CSDL

Bảng dưới liệt kê quy tắc của FRS mà CSDL tự bảo đảm, tách khỏi quy tắc chỉ kiểm ở dịch vụ. Mỗi dòng có ca kiểm tương ứng ở bài kiểm (cột cuối).

| Ràng buộc hoặc trigger | Quy tắc | BR, FR | Ca kiểm |
|---|---|---|---|
| `ck_consumer_credential_key`, `_cert`, `_key_ttl` | Chỉ lưu băm SHA-256 hex của khóa API (hạn ≤ 180 ngày) và vân tay chứng thư; không lưu khóa dạng rõ | SEC-24, FR-03-046 | 17, 17b |
| `ck_consumer_credential_slot`, `uq_consumer_credential_slot` | Tối đa hai vân tay chứng thư cùng lúc | FR-03-046 | 17c |
| `ck_edge_certificate_ref`, `ck_client_ca_pem` | Chứng thư biên chỉ lưu đường dẫn kho bí mật; bộ CA không chứa khóa riêng | FR-03-049 | 32, 32b |
| `ck_outbox_no_secret`, `ck_idempotency_key_no_secret` | Không khóa `password`, `secret`, `clientSecret`, `apiKey`, `token`, `privateKey`, `passphrase`, `authorization` trong sự kiện và phản hồi lũy đẳng | BR-03-007 | 31b |
| `ck_waf_exception_ttl`, `_four_eyes`, `_approved`, `uq_waf_exception_live` | Ngoại lệ WAF có lý do, ≤ 90 ngày, người duyệt khác người đề nghị, một ngoại lệ còn hiệu lực cho mỗi cặp route và mã luật | BR-03-006, BR-03-019, FR-03-007 | 19 đến 22c |
| `ck_waf_virtual_patch_*` | Luật vá có cùng quy tắc; phạm vi `PLATFORM` chỉ ở `COMMON` | FR-03-008 | (cùng cơ chế nhóm 19) |
| `ck_change_request_four_eyes`, `uq_change_request_pending` | Người duyệt khác người đề nghị; một yêu cầu đang chờ cho cùng đối tượng | BR-03-019 | 15c, 15d |
| `tg_route_ext_guard`, `ck_route_exposure_ext` | Route `EXT` phải trỏ yêu cầu `ROUTE_EXPOSURE_EXT` đã duyệt của đúng route | BR-03-015, FR-03-038 | 15, 15b |
| `tg_waf_mode_guard`, `ck_waf_mode_block`, `ck_waf_mode_detect_period` | `BLOCK` cần yêu cầu `WAF_MODE` đã duyệt và ≥ 14 ngày chạy `DETECT` (tenant kiểm thử `T9x` được miễn) | BR-03-019, FR-03-006, ERR-03-027 | 23, 23b |
| `ck_route_sensitive_mtls` | API mức `SENSITIVE` bắt buộc `require_mtls` | BR-03-004 | 11 |
| `ck_route_cors` | Cấm ký tự đại diện ở nguồn gốc CORS | BR-03-012 | 12 |
| `ck_route_sunset` | `sunset_at` cách `deprecated_at` tối thiểu 180 ngày | BR-03-030, CHK-11 | 13 |
| `ck_route_state_reason` | Dừng hoặc tạm ngừng route phải có lý do 10…500 ký tự | FR-03-036, 047 | 10b |
| `ck_upstream_timeouts`, `ck_upstream_node_host_safe` | Thời hạn chờ ≤ 30.000 ms; không trỏ loopback, link-local (chống SSRF) | CV 631, CHK-10, SEC-43 | 14, 14b |
| `uq_edge_host_pattern` và khóa ngoại `fk_route_host` | Host chỉ thuộc một tenant, route chỉ trỏ host cùng tenant | BR-03-026 | 8, 8b |
| `uq_route_host_path`, `uq_route_code` | Hai route cùng host, đường dẫn, phương thức không cùng tồn tại; mã route không dùng lại kể cả khi `RETIRED` | CHK-05, BR-03-029 | 8d, 9, 9c |
| `uq_emergency_block_active`, `ck_emergency_block_lift` | Một khối tạm ngừng đang hoạt động cho mỗi đối tượng; mở lại có lý do và người mở | FR-03-047, ERR-03-019 | 34, 34b |
| `ck_config_snapshot_signed`, `tg_write_once`, `uq_config_snapshot_version`, `tg_counter_monotonic` | Từ `SIGNED` phải có số phiên bản, băm manifest, khóa ký; nội dung đã ký và số phiên bản bất biến; số phiên bản duy nhất theo site và bộ đếm chỉ tăng | BR-03-016, BR-03-018 | 27 đến 29 |
| `ck_plan_policy_rate`, `_quota` | `rate_limits` chỉ khóa `second`, `minute`; `quotas` chỉ `hour`, `day`, `month` | LGC-APIM-012; 013 | 26 |
| `uq_rate_limit_override_live` (`NULLS NOT DISTINCT`), `ck_rate_limit_override_target` | Một ghi đè hiệu lực cho mỗi bộ (phạm vi, consumer, route, cửa sổ); phạm vi khớp đối tượng | FR-03-024 | 24, 25 |
| `tg_tenant_param_guard` | Tham số `gw.*` đúng kiểu, trong miền nền tảng; khóa lưu ở bảng khác bị từ chối | FR-03-056 | 30 đến 30e |
| `ck_tenant_redirect_*`, `uq_tenant_redirect_active` | Dòng thuộc tenant đích; ≤ 365 ngày; mỗi tenant nguồn một chuyển tiếp đang chạy | FR-03-037, ERR-03-025 | 35, 35b |
| `ck_ip_block_width` | Không chặn dải rộng hơn /16 (IPv4) hoặc /48 (IPv6) | FR-03-004 (giả định, tránh chặn nhầm cả sở) | 36 |
| `ck_tenant_hold_window` | Giữ tổng hợp sau quay lui ≤ 168 giờ, một giữ hoạt động mỗi tenant | FR-03-044 | (cấu trúc) |

: Quy tắc nghiệp vụ chốt ở CSDL

Hai quy tắc quan trọng **không** thể chốt ở CSDL vì cần dữ liệu ngoài schema, nên chỉ kiểm ở dịch vụ và bộ kiểm tra CHK: mã luật tồn tại trong CRS đang dùng (ERR-03-009), trần hợp đồng của tenant ở PH-20 (ERR-03-018), `KEYLESS` chỉ cho API dữ liệu mở (CHK-06, cần `data_class` của route khác bảng), HTTT còn đăng ký hiệu lực khi xóa consumer (ERR-03-017, đọc qua `catalog.api`).

### 1.5. Máy trạng thái ở CSDL

Mười một máy trạng thái lưu ở PostgreSQL. Cặp chuyển hợp lệ nằm ở bảng `state_transition` (47 dòng, dữ liệu khởi tạo ở chương 5); trigger `tg_state_guard('<MÁY>')` chặn mọi cập nhật cột `state` ngoài bảng, nên người viết dịch vụ không thể bỏ sót kiểm tra. So với SDD §8.1 (tám máy lưu ở PostgreSQL), bản này thêm ba máy: luật vá WAF (`WAF_PATCH`, cùng quy tắc ngoại lệ), giữ tổng hợp sau quay lui (`TENANT_HOLD`) và nhập hệ cũ (`IMPORT_JOB`); ba máy còn lại của SDD (chế độ WAF của nút, trạng thái nạp của `dh-sync`, đồng bộ nút) là trạng thái suy ra hoặc cục bộ của nút, không có bản ghi.

| Máy (`entity`) | Bảng | Trạng thái | Số cặp | Trạng thái cuối |
|---|---|---|---|---|
| `ROUTE` | `route` | `PENDING`, `ACTIVE`, `STOPPED`, `SUSPENDED`, `SUNSET`, `RETIRED` | 9 | `RETIRED` |
| `CONSUMER` | `consumer` | `ACTIVE`, `SUSPENDED`, `DELETED` | 4 | `DELETED` |
| `WAF_EXCEPTION` | `waf_exception` | `REQUESTED`, `ACTIVE`, `EXPIRING`, `REJECTED`, `EXPIRED`, `REVOKED` | 7 | `REJECTED`, `EXPIRED`, `REVOKED` |
| `WAF_PATCH` | `waf_virtual_patch` | như ngoại lệ WAF | 7 | như ngoại lệ WAF |
| `SNAPSHOT` | `config_snapshot` | `BUILT`, `REJECTED`, `SIGNED`, `PUBLISHED`, `APPLIED`, `PARTIAL`, `SUPERSEDED` | 9 | `REJECTED`, `SUPERSEDED` |
| `CHANGE_REQUEST` | `change_request` | `PENDING`, `APPROVED`, `REJECTED`, `EXPIRED` | 3 | ba trạng thái sau `PENDING` |
| `EMERGENCY_BLOCK` | `emergency_block` | `ACTIVE`, `LIFTED` | 1 | `LIFTED` |
| `TENANT_REDIRECT` | `tenant_redirect` | `ACTIVE`, `ENDED` | 1 | `ENDED` |
| `TLS_EXCEPTION` | `tls_exception` | `ACTIVE`, `ENDED` | 1 | `ENDED` |
| `TENANT_HOLD` | `tenant_hold` | `ACTIVE`, `RELEASED` | 1 | `RELEASED` |
| `IMPORT_JOB` | `legacy_import_job` | `UPLOADED`, `SCANNED`, `PROPOSED`, `APPLIED`, `FAILED` | 4 | `APPLIED`, `FAILED` |

: Máy trạng thái lưu ở PostgreSQL

Hai cặp mở rộng so với FRS: `ROUTE PENDING → RETIRED` (API bị gỡ trước khi có ảnh chụp chứa route, nếu không route kẹt ở `PENDING`) và `SNAPSHOT PUBLISHED → SUPERSEDED` (bản mới hơn được phát khi chưa nút nào báo, nếu không ảnh chụp kẹt ở `PUBLISHED`); cả hai có ghi chú ở cột `note` và đang chờ xác nhận ở Q03-51. Trạng thái ban đầu do `DEFAULT` và `CHECK` bảo đảm, trigger chỉ kiểm chuyển trạng thái khi `UPDATE`.

### 1.6. Nơi lưu từng loại dữ liệu

Nguyên tắc của SDD §8.2: **PostgreSQL là nguồn sự thật, Valkey và bucket là bản phái sinh**; mọi ghi vào Valkey hoặc bucket xảy ra sau khi giao dịch cơ sở dữ liệu commit và có tác vụ đối chiếu sửa khi lệch.

| Dữ liệu | Nơi lưu | Lý do |
|---|---|---|
| Cấu hình route, upstream, consumer, ngoại lệ, tham số | PostgreSQL (`ph03_gateway`) | Cần giao dịch, ràng buộc, kiểm toán, cách ly tenant |
| Nội dung ảnh chụp cấu hình | Bucket `dh-platform-gateway` và Git `gateway/{site}/` | Nút đọc không qua control plane; lịch sử vĩnh viễn ở Git (NFR-03-026) |
| Siêu dữ liệu ảnh chụp (phiên bản, băm, trạng thái) | PostgreSQL (`config_snapshot`) | Truy vấn, quay lui, tính trạng thái đồng bộ |
| Khóa chặn token, tạm ngừng khẩn cấp | Valkey (đường nhanh) **và** PostgreSQL (`revoked_token`, `emergency_block`, bản bền) | Hiệu lực vài giây; dựng lại khi Valkey mất |
| Bộ đếm hạn mức (giây, phút, giờ, ngày, tháng) | Valkey; số liệu chính xác dài hạn từ ClickHouse | Tần suất ghi cao, mất thì đặt lại (Q03-12) |
| Nhật ký lượt gọi (siêu dữ liệu, che dữ liệu) | ClickHouse của PH-13 | 5 triệu bản ghi/ngày/tenant, giữ 12 tháng (NFR-03-022) |
| Chỉ số, trạng thái nút | Mimir; trạng thái nút suy ra, không lưu bảng | Chỉ số `dh_gateway_*`; nút không gọi về control plane |
| Khóa riêng chứng thư, khóa ký ảnh chụp | OpenBao | Không bao giờ ở bảng, Git hay bucket (NFR-03-016) |
| JWKS, ngoại lệ luật đang hiệu lực | Bộ nhớ nút (`lua_shared_dict`), nạp từ ảnh chụp | Gateway không gọi control plane mỗi lượt |

: Nơi lưu từng loại dữ liệu

## 2. Sơ đồ thực thể – quan hệ

Ba hình dưới chia schema theo ba nhóm cho vừa trang: định tuyến và consumer (hình 1), lớp biên, WAF và yêu cầu thay đổi (hình 2), ảnh chụp cấu hình và tham số (hình 3). Các cột trong hình chỉ là khóa và vài cột chính; đầy đủ ở chương 3. Đường liền là khóa ngoại thật, đều kèm `tenant_id` (`FOREIGN KEY (x_id, tenant_id)`) nên không thể trỏ chéo tenant; ngoại lệ duy nhất là `tenant_param` tới `param_definition`, tham chiếu danh mục dùng chung của tenant `COMMON` theo khóa `param_key`.

```{.mermaid caption="Sơ đồ thực thể – quan hệ nhóm định tuyến, consumer và hạn mức"}
erDiagram
  edge_host ||--o{ route : "host của route"
  upstream ||--o{ upstream_node : "nút backend"
  upstream ||--o{ route : "chuyển tiếp tới"
  route ||--o{ route_state_event : "lịch sử trạng thái"
  consumer ||--o{ consumer_credential : "vân tay, băm khóa"
  consumer ||--o{ subscription_ref : "đăng ký"
  route ||--o{ subscription_ref : "được đăng ký"
  plan_policy ||--o{ subscription_ref : "gói áp dụng"
  route ||--o{ rate_limit_override : "ghi đè theo route"
  consumer ||--o{ rate_limit_override : "ghi đè theo consumer"
  route ||--o{ emergency_block : "tạm ngừng route"
  consumer ||--o{ emergency_block : "tạm ngừng consumer"
  route ||--o{ synthetic_check : "kiểm tra tổng hợp"
  route {
    uuid id PK
    varchar route_code UK
    uuid host_id FK
    uuid upstream_id FK
    varchar exposure
    varchar state
  }
  consumer {
    uuid id PK
    varchar consumer_code UK
    varchar priority_group
    varchar state
  }
  plan_policy {
    uuid id PK
    varchar policy_code UK
    varchar security_mode
    jsonb rate_limits
  }
```

Hình 1 cho thấy `route` là trung tâm: mỗi route thuộc đúng một host (`edge_host`, bảo đảm host chỉ của một tenant) và một upstream; `consumer` gặp `route` qua `subscription_ref` (bản chiếu đăng ký sử dụng của PH-02) và qua `plan_policy` (bản chiếu gói). Hạn mức ghi đè và khối tạm ngừng khẩn cấp tham chiếu `route` hoặc `consumer` bằng khóa ngoại thật, nhưng chỉ một trong hai (ràng buộc `ck_*_target`). `route_state_event` là nhật ký chỉ thêm.

```{.mermaid caption="Sơ đồ thực thể – quan hệ nhóm WAF, biên và yêu cầu thay đổi"}
erDiagram
  route ||--o{ waf_exception : "ngoại lệ luật"
  route ||--o{ waf_virtual_patch : "luật vá phạm vi route"
  route ||--o{ waf_mode : "chế độ theo route"
  edge_host ||--o{ tls_exception : "TLS 1.2 có hạn"
  change_request ||--o{ route : "duyệt mở cửa Internet"
  change_request ||--o{ waf_mode : "duyệt đổi sang BLOCK"
  change_request ||--o{ rate_limit_override : "duyệt hạ hạn mức tenant"
  change_request ||--o{ tenant_param : "duyệt tham số bốn mắt"
  waf_exception {
    uuid id PK
    uuid route_id FK
    varchar rule_id
    varchar state
    timestamptz expires_at
  }
  change_request {
    uuid id PK
    varchar change_type
    varchar target_code
    varchar requested_by
    varchar decided_by
    varchar state
  }
```

Hình 2 gom các thay đổi rủi ro cao. `change_request` là cổng bốn mắt cho ba loại thay đổi (`WAF_MODE`, `ROUTE_EXPOSURE_EXT`, `TENANT_LIMIT_DECREASE`) và được các bảng đích tham chiếu bằng khóa ngoại; trigger kiểm yêu cầu đã `APPROVED` đúng loại và đúng đối tượng. Ngoại lệ WAF và luật vá có máy trạng thái riêng nhưng dùng cùng nguyên tắc người duyệt khác người đề nghị. Bảng độc lập không có khóa ngoại (`ip_block`, `edge_certificate`, `client_ca`, `tenant_redirect`, `revoked_token`) không vẽ ở đây.

```{.mermaid caption="Sơ đồ thực thể – quan hệ nhóm ảnh chụp cấu hình và tham số"}
erDiagram
  config_snapshot ||--o{ snapshot_violation : "kết quả kiểm tra"
  config_snapshot ||--o{ tenant_hold : "giữ sau quay lui"
  param_definition ||--o{ tenant_param : "định nghĩa tham số"
  snapshot_counter ||..o{ config_snapshot : "cấp số theo site"
  source_cursor }o..o{ config_snapshot : "con trỏ nguồn trong built_from"
  state_transition }o..o{ config_snapshot : "bảng chuyển trạng thái"
  config_snapshot {
    uuid id PK
    varchar site
    bigint snapshot_version UK
    varchar state
    char content_hash
    varchar signature_key_id
  }
  snapshot_counter {
    varchar site PK
    bigint last_issued
    bigint last_published
  }
  param_definition {
    uuid id PK
    varchar param_key UK
    varchar value_type
    varchar four_eyes
  }
```

Hình 3 cho thấy hai dòng dữ liệu độc lập. Ảnh chụp: `snapshot_counter` cấp số phiên bản theo site (liên kết theo giá trị `site`, không có khóa ngoại vì là bảng kỹ thuật không tenant), `config_snapshot` giữ siêu dữ liệu, `snapshot_violation` giữ kết quả kiểm tra, `tenant_hold` giữ tổng hợp sau quay lui. Tham số: `param_definition` (dùng chung ở `COMMON`) định nghĩa kiểu và miền, `tenant_param` giữ giá trị ghi đè của tenant và được trigger kiểm theo định nghĩa. Đường chấm là liên kết theo giá trị hoặc theo tập hợp, không phải khóa ngoại: `built_from` là mảng JSON chứa con trỏ nguồn đã dùng; `state_transition` được trigger tra cứu lúc chạy. Các bảng không xuất hiện ở ba hình là bảng độc lập: `ip_block`, `edge_certificate`, `client_ca`, `tenant_redirect`, `revoked_token`, `idempotency_key`, `policy_template_setting`, `legacy_import_job`, `outbox`, `shedlock`.

## 3. Đặc tả bảng

35 bảng chia bảy nhóm theo chủ đề; thứ tự trình bày theo nhóm (khác thứ tự tạo trong DDL vì `change_request` phải có trước `route`). Cột "Thực thể" nối bảng với EN của FRS §4.2: 14 trong 15 thực thể EN-03-01 đến 15 được hiện thực bằng 16 bảng (EN-03-02 có thêm `upstream_node`, EN-03-09 có thêm `snapshot_violation`); riêng **EN-03-10 (nút gateway) không có bảng** vì SDD §4.16 quy định trạng thái nút suy ra từ chỉ số Mimir, không lưu (Q03-50 đề nghị đồng bộ FRS). Năm bảng dẫn xuất từ FR nhưng chưa có EN ở FRS được ghi "đề xuất" (EN-03-16 đến 20, xem "Đề nghị đồng bộ"); 14 bảng còn lại là bảng phụ trợ hoặc kỹ thuật.

<!-- gen:index:start -->
| Nhóm | Mục, bảng | Thực thể | Số cột | FR phục vụ |
|---|---|---|---|---|
| A | 3.1 `edge_host` | EN-03-16 (đề xuất) | 10 | FR-03-013, 028, 037, 038 |
| A | 3.2 `upstream` | EN-03-02 | 19 | FR-03-029, 030, 031 |
| A | 3.3 `upstream_node` | EN-03-02 | 12 | FR-03-029, 030 |
| A | 3.4 `route` | EN-03-01 | 37 | FR-03-028, 035, 036, 038, 039, 047 |
| A | 3.5 `route_state_event` | Phụ trợ | 10 | FR-03-035, 036, 047 |
| B | 3.6 `consumer` | EN-03-03 | 18 | FR-03-014, 016, 046, 047 |
| B | 3.7 `consumer_credential` | EN-03-04 | 15 | FR-03-002, 014, 046 |
| B | 3.8 `idempotency_key` | Phụ trợ | 9 | FR-03-046 |
| B | 3.9 `revoked_token` | Phụ trợ | 11 | FR-03-018 |
| B | 3.10 `emergency_block` | EN-03-12 | 18 | FR-03-047 |
| C | 3.11 `plan_policy` | EN-03-05 | 17 | FR-03-015, 016, 017, 020, 021, 022 |
| C | 3.12 `subscription_ref` | EN-03-17 (đề xuất) | 15 | FR-03-016, 046 |
| C | 3.13 `rate_limit_override` | EN-03-06 | 20 | FR-03-021, 023, 024 |
| C | 3.14 `policy_template_setting` | EN-03-18 (đề xuất) | 11 | FR-03-048 |
| D | 3.15 `waf_exception` | EN-03-07 | 21 | FR-03-007 |
| D | 3.16 `waf_virtual_patch` | EN-03-08 | 24 | FR-03-008 |
| D | 3.17 `waf_mode` | Phụ trợ | 13 | FR-03-005, 006 |
| D | 3.18 `ip_block` | EN-03-14 | 12 | FR-03-003, 004 |
| D | 3.19 `edge_certificate` | EN-03-11 | 19 | FR-03-001, 049 |
| D | 3.20 `client_ca` | EN-03-19 (đề xuất) | 14 | FR-03-002, 049 |
| D | 3.21 `tls_exception` | EN-03-20 (đề xuất) | 13 | FR-03-001 |
| D | 3.22 `tenant_redirect` | EN-03-13 | 15 | FR-03-037 |
| E | 3.23 `snapshot_counter` | Phụ trợ | 4 | FR-03-041, 042, 044 |
| E | 3.24 `config_snapshot` | EN-03-09 | 28 | FR-03-039…045 |
| E | 3.25 `snapshot_violation` | EN-03-09 | 9 | FR-03-040 |
| E | 3.26 `tenant_hold` | Phụ trợ | 13 | FR-03-044 |
| E | 3.27 `source_cursor` | Phụ trợ | 11 | FR-03-039 |
| F | 3.28 `change_request` | EN-03-15 | 22 | FR-03-006, 023, 038, 056 |
| F | 3.29 `param_definition` | Phụ trợ | 17 | FR-03-056 |
| F | 3.30 `tenant_param` | Phụ trợ | 10 | FR-03-023, 056 |
| F | 3.31 `synthetic_check` | Phụ trợ | 16 | FR-03-053 |
| F | 3.32 `legacy_import_job` | Phụ trợ | 18 | FR-03-059 |
| G | 3.33 `state_transition` | Phụ trợ | 5 | FR-03-035, 036, 040, 044, 047 (bảng chuyển trạng thái) |
| G | 3.34 `outbox` | Phụ trợ | 9 | Mọi FR phát sự kiện (EVT-03-01…08, 10…12); FR-03-042 (EVT-03-01) |
| G | 3.35 `shedlock` | Phụ trợ | 4 | FR-03-007, 018, 026, 039, 045, 049 (tác vụ định kỳ) |

: Danh sách 35 bảng của schema ph03_gateway theo nhóm A đến G
<!-- gen:index:end -->

Nhóm: A Định tuyến; B Consumer và chặn nhanh; C Chính sách chiếu từ gói và hạn mức; D Lớp biên và WAF; E Ảnh chụp cấu hình; F Yêu cầu thay đổi, tham số, vận hành; G Kỹ thuật. Phần dưới sinh bằng [`ph03/tools/gen_tables_md.py`](ph03/tools/gen_tables_md.py) từ DDL (`COMMENT ON`), khối đặc tả 10 mục bằng [`ph03/tools/them_dac_ta_bang.py`](ph03/tools/them_dac_ta_bang.py); sửa ở DDL rồi sinh lại, không sửa tay.

<!-- gen:tables:start -->
### 3.1. `edge_host`

::: dac-ta
**Mục đích.** Gắn host với đúng một tenant (BR-03-026): khóa duy nhất toàn cục trên host_pattern, route chỉ trỏ tới host cùng tenant bằng khóa ngoại kèm tenant_id. Không dùng lại host đã gỡ (BR-03-029). Dẫn xuất từ FR-03-013, 028, 037, 038 (không có EN riêng ở FRS §4.2, đề nghị EN-03-16).

**FR phục vụ.** FR-03-013, 028, 037, 038.

**Khóa chính.** (id).

**Duy nhất.** `uq_edge_host_pattern` (host_pattern).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_edge_host_tenant`, `ck_edge_host_pattern`, `ck_edge_host_purpose`, `ck_edge_host_state`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_edge_host_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Cột ghi một lần: `host_pattern`, `tenant_id` (trigger `tg_edge_host_once`). Không xóa cứng (trigger `tg_edge_host_nodelete`, BR-03-029).

**Ghi chú.** Khóa duy nhất toàn cục trên `host_pattern` (khác các khóa duy nhất theo tenant) để một host chỉ thuộc một tenant (BR-03-026); lỗi trùng host của tenant khác lộ sự tồn tại của host nên dịch vụ trả cùng một thông báo chung.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `host_pattern` | `varchar(253)` | x |  | Tên miền chữ thường, có thể bắt đầu bằng *. (ví dụ t68.api.datahub.gov.vn). |
| `purpose` | `varchar(3)` | x | `'API'` | API: API máy (giới hạn IP gw.ip.apiReqPerSecond, mức hoang tưởng gw.waf.paranoia.api); UI: đường dẫn giao diện. |
| `state` | `varchar(8)` | x | `'ACTIVE'` | Một trong: `ACTIVE`, `RETIRED`. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `edge_host`

### 3.2. `upstream`

::: dac-ta
**Mục đích.** EN-03-02 Upstream: nhóm backend dùng chung cho nhiều route (FR-03-029, 030, 031). Thời hạn chờ tối đa 30.000 ms (CV 631).

**FR phục vụ.** FR-03-029, 030, 031.

**Khóa chính.** (id).

**Duy nhất.** `uq_upstream_code` (tenant_id, upstream_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_upstream_tenant`, `ck_upstream_code`, `ck_upstream_scheme`, `ck_upstream_balancer`, `ck_upstream_chash`, `ck_upstream_retries`, `ck_upstream_timeouts`, `ck_upstream_health_check`, `ck_upstream_breaker`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_upstream_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `upstream_code` | `varchar(127)` | x |  | Mẫu `^[a-z][a-z0-9.-]{2,126}$`. |
| `name` | `varchar(255)` | x |  |  |
| `scheme` | `varchar(5)` | x | `'https'` | Một trong: `http`, `https`, `grpc`. |
| `balancer` | `varchar(10)` | x | `'roundrobin'` | Một trong: `roundrobin`, `chash`. |
| `chash_key` | `varchar(64)` |  |  | Khóa băm khi balancer = chash (route cần dính phiên), ví dụ header:x-session. |
| `tls_verify` | `boolean` | x | `true` |  |
| `retries` | `smallint` | x | `1` |  |
| `connect_timeout_ms` | `integer` | x | `3000` |  |
| `read_timeout_ms` | `integer` | x | `10000` |  |
| `health_check` | `jsonb` | x | `'{}'` | Kiểm tra sức khỏe: {"active":{"path":"/health","intervalSeconds":5,"timeoutMs":1000,"healthyStatuses":[200]},"passive":{"failures":3,"statuses":[500,502,503,504]},"failThreshold":3,"successThreshold":2}. |
| `breaker` | `jsonb` | x | `'{}'` | Ngắt mạch: {"failures":5,"openSeconds":10,"halfOpenProbes":1,"unhealthyStatuses":[500,502,503,504]} (FR-03-031). |
| `retired_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `upstream`

### 3.3. `upstream_node`

::: dac-ta
**Mục đích.** EN-03-02 (nút của upstream): địa chỉ, cổng, trọng số. Chặn địa chỉ loopback và link-local ở CSDL như lớp thứ hai của CHK-10 (chống SSRF, SEC-43); dải quản trị Z7 do bộ kiểm tra ở dịch vụ.

**FR phục vụ.** FR-03-029, 030.

**Khóa chính.** (id).

**Duy nhất.** `uq_upstream_node` (tenant_id, upstream_id, host, port).

**Khóa ngoại.** (upstream_id, tenant_id) → `upstream` xóa theo.

**Ràng buộc CHECK.** `ck_upstream_node_tenant`, `ck_upstream_node_port`, `ck_upstream_node_weight`, `ck_upstream_node_host`, `ck_upstream_node_host_safe`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_upstream_node_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `upstream_id` | `uuid` | x |  |  |
| `host` | `varchar(253)` | x |  | Mẫu `^[A-Za-z0-9]([A-Za-z0-9.:-]{0,250}[A-Za-z0-9])?$`. |
| `port` | `integer` | x |  |  |
| `weight` | `integer` | x | `1` |  |
| `enabled` | `boolean` | x | `true` |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `upstream_node`

### 3.4. `route`

::: dac-ta
**Mục đích.** EN-03-01 Route: trạng thái thực thi của một API đã công bố ở PH-02 (FR-03-028, 035, 036, 038, 039). Mã bất biến, không dùng lại kể cả khi RETIRED (BR-03-029); chuyển trạng thái theo bảng state_transition.

**FR phục vụ.** FR-03-028, 035, 036, 038, 039, 047.

**Khóa chính.** (id).

**Duy nhất.** `uq_route_code` (tenant_id, route_code), `uq_route_host_path` (host_id, path_pattern, methods) có điều kiện khi state <> 'RETIRED'.

**Khóa ngoại.** (host_id, tenant_id) → `edge_host`, (upstream_id, tenant_id) → `upstream`, (exposure_request_id, tenant_id) → `change_request`.

**Ràng buộc CHECK.** `ck_route_tenant`, `ck_route_code`, `ck_route_api_version`, `ck_route_path`, `ck_route_methods`, `ck_route_priority`, `ck_route_exposure`, `ck_route_exposure_ext`, `ck_route_ip_allow`, `ck_route_class`, `ck_route_sensitive_mtls`, `ck_route_scopes`, `ck_route_body`, `ck_route_paranoia`, `ck_route_cors`, `ck_route_state`, `ck_route_state_reason`, `ck_route_retired`, `ck_route_sunset`, `ck_route_sunset_state`.

**Chỉ mục.** `ix_route_state`, `ix_route_api`, `ix_route_upstream`, `ix_route_ext`, `ix_route_sunset`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_route_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Chuyển trạng thái theo bảng `state_transition` máy `ROUTE` (trigger `tg_route_state`). Cột ghi một lần: `route_code`, `api_code`, `api_version`, `host_id` (trigger `tg_route_once`). Không xóa cứng (trigger `tg_route_nodelete`, BR-03-029).

**Ghi chú.** Bảng lõi: `host_id`, `upstream_id` cùng tenant nhờ khóa ngoại kèm `tenant_id`; trigger `tg_route_ext_guard` kiểm yêu cầu thay đổi đã duyệt khi mở ra Internet.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `route_code` | `varchar(127)` | x |  | Mã API ở PH-02 kèm phiên bản, ví dụ tra-cuu-cong-dan.v1; duy nhất trong tenant. |
| `api_code` | `varchar(127)` | x |  |  |
| `api_version` | `varchar(8)` | x |  | Mẫu `^v[0-9]{1,3}$`. |
| `host_id` | `uuid` | x |  |  |
| `path_pattern` | `varchar(512)` | x |  | Mẫu đường dẫn đã chuẩn hóa, ví dụ /ho-tich/v1/*; hai route cùng host, đường dẫn, phương thức không cùng tồn tại (CHK-05). |
| `methods` | `varchar(7)[]` | x |  |  |
| `priority` | `integer` | x | `0` |  |
| `exposure` | `varchar(3)` | x | `'INT'` | INT: chỉ nạp ở apisix-int; EXT: nạp thêm ở apisix-ext, chỉ khi có yêu cầu thay đổi ROUTE_EXPOSURE_EXT đã duyệt (BR-03-015, trigger tg_route_ext_guard). |
| `exposure_request_id` | `uuid` |  |  | Yêu cầu thay đổi đã duyệt cho việc mở ra Internet; bắt buộc khi exposure = EXT. |
| `ip_allow_cidrs` | `cidr[]` | x | `'{}'` | Dải IP cố định được phép khi route EXT (ví dụ dải nhà cung cấp thanh toán); đi vào dh-ip-block của route. |
| `upstream_id` | `uuid` | x |  |  |
| `policy_set_code` | `varchar(64)` |  |  |  |
| `data_class` | `varchar(10)` | x |  | Mức phân loại dữ liệu của API (SEC-24): SENSITIVE bắt buộc require_mtls (BR-03-004). |
| `required_scopes` | `varchar(64)[]` | x | `'{}'` |  |
| `require_mtls` | `boolean` | x | `false` |  |
| `body_max_bytes` | `integer` | x | `1048576` |  |
| `waf_paranoia` | `smallint` |  |  |  |
| `cors` | `jsonb` | x | `'{}'` | {"allowedOrigins":[...],"allowedMethods":[...],"allowedHeaders":[...],"exposedHeaders":[...],"allowCredentials":false,"maxAgeSeconds":600}; cấm ký tự đại diện * ở allowedOrigins (BR-03-012). |
| `openapi_ref` | `varchar(255)` |  |  | Tham chiếu lược đồ OpenAPI đã duyệt ở PH-02 (CHK-02); thiếu thì route không được phát (BR-03-014). |
| `opa_policy` | `varchar(255)` |  |  | Gói chính sách OPA, ví dụ dh/authz/ho_tich/allow (CHK-03). |
| `critical` | `boolean` | x | `false` | API quan trọng: có kiểm tra tổng hợp mỗi phút (FR-03-053). |
| `deprecated_at` | `timestamptz` |  |  |  |
| `sunset_at` | `timestamptz` |  |  | Ngày kết thúc phiên bản; cách deprecated_at tối thiểu 180 ngày (BR-03-030, CHK-11). |
| `successor_route_code` | `varchar(127)` |  |  |  |
| `state` | `varchar(10)` | x | `'PENDING'` | Một trong: `PENDING`, `ACTIVE`, `STOPPED`, `SUSPENDED`, `SUNSET`, `RETIRED`. |
| `state_reason` | `varchar(500)` |  |  | Lý do 10…500 ký tự khi STOPPED hoặc SUSPENDED (FR-03-036, 047). |
| `state_changed_at` | `timestamptz` | x | `now()` |  |
| `state_changed_by` | `varchar(64)` |  |  |  |
| `source_version` | `bigint` | x | `0` | Phiên bản bản ghi nguồn ở PH-02 đã chiếu vào; lũy đẳng khi nhận lại sự kiện cũ. |
| `retired_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `route`

### 3.5. `route_state_event`

::: dac-ta
**Mục đích.** Lịch sử trạng thái thực thi của route, chỉ thêm (UI-03-02, FR-03-036, 047). Bản kiểm toán đầy đủ đi qua outbox tới PH-13; bảng này phục vụ hiển thị nhanh.

**FR phục vụ.** FR-03-035, 036, 047.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (route_id, tenant_id) → `route`.

**Ràng buộc CHECK.** `ck_route_state_event_tenant`, `ck_route_state_event_state`, `ck_route_state_event_source`, `ck_route_state_event_trace`.

**Chỉ mục.** `ix_route_state_event_route`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_route_state_event_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Chỉ thêm, chặn UPDATE và DELETE (trigger `tg_route_state_event_append`).

**Ghi chú.** Nhật ký chỉ thêm: ứng dụng không có UPDATE, DELETE và trigger chặn cả chủ schema. Không có `version`, `updated_*`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `route_id` | `uuid` | x |  |  |
| `from_state` | `varchar(10)` |  |  |  |
| `to_state` | `varchar(10)` | x |  | Một trong: `PENDING`, `ACTIVE`, `STOPPED`, `SUSPENDED`, `SUNSET`, `RETIRED`. |
| `reason` | `varchar(500)` |  |  |  |
| `actor` | `varchar(64)` | x |  |  |
| `source` | `varchar(10)` | x | `'API'` | Một trong: `API`, `SYSTEM`, `SNAPSHOT`, `IMPORT`. |
| `trace_id` | `char(32)` | x |  | Mẫu `^[0-9a-f]{32}$`. |
| `occurred_at` | `timestamptz` | x | `now()` |  |

: Cột của bảng `route_state_event`

### 3.6. `consumer`

::: dac-ta
**Mục đích.** EN-03-03 Consumer: hình chiếu trên gateway của một client của HTTT (FR-03-046). Không có trường bí mật (SEC-24); mã trùng clientId ở Keycloak, bất biến và không dùng lại (BR-03-029).

**FR phục vụ.** FR-03-014, 016, 046, 047.

**Khóa chính.** (id).

**Duy nhất.** `uq_consumer_code` (tenant_id, consumer_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_consumer_tenant`, `ck_consumer_code`, `ck_consumer_auth`, `ck_consumer_priority`, `ck_consumer_trusted`, `ck_consumer_state`, `ck_consumer_deleted`, `ck_consumer_version`.

**Chỉ mục.** `ix_consumer_system`, `ix_consumer_state`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_consumer_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Chuyển trạng thái theo bảng `state_transition` máy `CONSUMER` (trigger `tg_consumer_state`). Cột ghi một lần: `consumer_code`, `system_code` (trigger `tg_consumer_once`). Không xóa cứng (trigger `tg_consumer_nodelete`, BR-03-029).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `consumer_code` | `varchar(63)` | x |  | Mẫu `^[a-z][a-z0-9-]{2,62}$`. |
| `system_code` | `varchar(64)` | x |  | Mã HTTT ở PH-01 (bản sao); không khóa ngoại vì khác schema, kiểm ở dịch vụ. |
| `auth_method` | `varchar(8)` | x |  | Một trong: `OAUTH2`, `MTLS`, `API_KEY`. |
| `priority_group` | `varchar(9)` | x | `'NORMAL'` | ESSENTIAL được nới tần suất và không bị điều tiết khi backend yếu (BR-03-009). |
| `trusted_source` | `boolean` | x | `false` | true miễn giới hạn theo IP (gw.ip.trustedCidrs); chỉ SO duyệt, bắt buộc có trusted_approved_by. |
| `trusted_approved_by` | `varchar(64)` |  |  |  |
| `state` | `varchar(9)` | x | `'ACTIVE'` | Một trong: `ACTIVE`, `SUSPENDED`, `DELETED`. |
| `state_reason` | `varchar(500)` |  |  |  |
| `consumer_version` | `integer` | x | `1` | Tăng mỗi lần ghi consumer hoặc thông tin xác thực công khai; NodeStateEvaluator so với builtFrom để tính syncState cho saga (SDD §4.13). |
| `legacy_ref` | `varchar(255)` |  |  | Vị trí trong gateway cũ khi tạo từ nhập hệ cũ (FR-03-059). |
| `deleted_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `consumer`

### 3.7. `consumer_credential`

::: dac-ta
**Mục đích.** EN-03-04 Thông tin xác thực công khai của consumer: vân tay chứng thư (tối đa 2 ô khi xoay) hoặc băm khóa API cho giai đoạn chuyển đổi (SEC-24). Không lưu khóa dạng rõ, không lưu client_secret (FR-03-046).

**FR phục vụ.** FR-03-002, 014, 046.

**Khóa chính.** (id).

**Duy nhất.** `uq_consumer_credential_slot` (tenant_id, consumer_id, kind, slot), `uq_consumer_credential_thumb` (cert_thumbprint) có điều kiện khi cert_thumbprint IS NOT NULL, `uq_consumer_credential_keyhash` (api_key_hash) có điều kiện khi api_key_hash IS NOT NULL.

**Khóa ngoại.** (consumer_id, tenant_id) → `consumer`.

**Ràng buộc CHECK.** `ck_consumer_credential_tenant`, `ck_consumer_credential_kind`, `ck_consumer_credential_slot`, `ck_consumer_credential_cert`, `ck_consumer_credential_key`, `ck_consumer_credential_key_ttl`.

**Chỉ mục.** `ix_consumer_credential_expiry`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_consumer_credential_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Vân tay chứng thư và băm khóa API duy nhất toàn cục vì gateway tra theo giá trị này; không có cột chứa bí mật.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `consumer_id` | `uuid` | x |  |  |
| `kind` | `varchar(8)` | x |  | Một trong: `CERT`, `API_KEY`. |
| `slot` | `smallint` | x | `1` | Ô 1 hoặc 2: tối đa hai vân tay cùng lúc khi xoay chứng thư (vân tay thứ ba bị từ chối). |
| `cert_thumbprint` | `char(64)` |  |  | SHA-256 dạng hex 64 ký tự của chứng thư khách; duy nhất toàn cục vì gateway tra theo vân tay (FR-03-014). |
| `cert_subject` | `varchar(255)` |  |  |  |
| `cert_not_after` | `timestamptz` |  |  |  |
| `api_key_hash` | `char(64)` |  |  | SHA-256 hex của khóa API; hạn tối đa 180 ngày kể từ lúc tạo. |
| `api_key_not_after` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `consumer_credential`

### 3.8. `idempotency_key`

::: dac-ta
**Mục đích.** Khóa lũy đẳng của lệnh ghi consumer (Idempotency-Key, giữ 24 giờ): cùng khóa cùng thân trả đúng phản hồi cũ, cùng khóa khác thân trả ERR-03-003 (SDD §4.13). Saga PH-01 thử lại không sinh bản sao.

**FR phục vụ.** FR-03-046.

**Khóa chính.** (id).

**Duy nhất.** `uq_idempotency_key` (tenant_id, operation, idem_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_idempotency_key_tenant`, `ck_idempotency_key_status`, `ck_idempotency_key_expiry`, `ck_idempotency_key_no_secret`.

**Chỉ mục.** `ix_idempotency_key_expiry`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_idempotency_key_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Khóa tự nhiên `(tenant_id, operation, idem_key)`; chỉ thêm và xóa khi hết hạn 24 giờ; không có cột sửa vì không bao giờ cập nhật.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `operation` | `varchar(64)` | x |  |  |
| `idem_key` | `varchar(128)` | x |  |  |
| `request_hash` | `char(64)` | x |  | SHA-256 hex của thân đã chuẩn hóa. |
| `response_status` | `smallint` | x |  |  |
| `response_body` | `jsonb` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `expires_at` | `timestamptz` | x | `(now() + interval '24 hours')` |  |

: Cột của bảng `idempotency_key`

### 3.9. `revoked_token`

::: dac-ta
**Mục đích.** Bản ghi bền của thu hồi token để ValkeyRebuilder dựng lại khóa {T}:revoked:* khi Valkey mất (FR-03-018, SDD §4.12). Thu hồi theo jti hoặc theo sub (kèm notBefore). Dọn khi token đã hết hạn cộng 60 giây; chỉ chứa định danh token, không chứa token.

**FR phục vụ.** FR-03-018.

**Khóa chính.** (id).

**Duy nhất.** `uq_revoked_token_jti` (tenant_id, jti) có điều kiện khi kind = 'JTI', `uq_revoked_token_sub` (tenant_id, sub) có điều kiện khi kind = 'SUB'.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_revoked_token_tenant`, `ck_revoked_token_kind`, `ck_revoked_token_fields`, `ck_revoked_token_reason`, `ck_revoked_token_expiry`.

**Chỉ mục.** `ix_revoked_token_expiry`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_revoked_token_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Dòng chỉ thêm; xóa khi token đã hết hạn cộng 60 giây. Chỉ chứa định danh `jti`, `sub`, không chứa token. Không có cột sửa.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `kind` | `varchar(3)` | x |  | Một trong: `JTI`, `SUB`. |
| `jti` | `varchar(128)` |  |  |  |
| `sub` | `varchar(128)` |  |  |  |
| `not_before` | `timestamptz` |  |  | Với kind = SUB: token của sub có iat nhỏ hơn mốc này bị chặn; token cấp mới sau khi xoay khóa client dùng lại được. |
| `token_expires_at` | `timestamptz` | x |  |  |
| `reason` | `varchar(500)` | x |  |  |
| `revoked_by` | `varchar(64)` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `OR` | `(kind = 'SUB' AND sub IS AND jti IS NULL AND not_before IS))` | x |  |  |

: Cột của bảng `revoked_token`

### 3.10. `emergency_block`

::: dac-ta
**Mục đích.** EN-03-12 Lệnh tạm ngừng khẩn cấp route hoặc consumer (FR-03-047). Một khối đang hoạt động cho mỗi đối tượng; mở lại ghi lifted_at, lifted_by và lý do. Là bản bền của khóa Valkey {T}:kill:* (đường nhanh chỉ để thêm chặn).

**FR phục vụ.** FR-03-047.

**Khóa chính.** (id).

**Duy nhất.** `uq_emergency_block_active` (tenant_id, target_type, target_code) có điều kiện khi state = 'ACTIVE'.

**Khóa ngoại.** (route_id, tenant_id) → `route`, (consumer_id, tenant_id) → `consumer`.

**Ràng buộc CHECK.** `ck_emergency_block_tenant`, `ck_emergency_block_target`, `ck_emergency_block_target_ref`, `ck_emergency_block_reason`, `ck_emergency_block_state`, `ck_emergency_block_lift`.

**Chỉ mục.** `ix_emergency_block_reminder`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_emergency_block_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Chuyển trạng thái theo bảng `state_transition` máy `EMERGENCY_BLOCK` (trigger `tg_emergency_block_state`). Cột ghi một lần: `target_type`, `target_code`, `route_id`, `consumer_id`, `reason` (trigger `tg_emergency_block_once`). Không xóa cứng (trigger `tg_emergency_block_nodelete`, BR-03-029).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `target_type` | `varchar(8)` | x |  | Một trong: `ROUTE`, `CONSUMER`. |
| `route_id` | `uuid` |  |  |  |
| `consumer_id` | `uuid` |  |  |  |
| `target_code` | `varchar(127)` | x |  |  |
| `reason` | `varchar(500)` | x |  |  |
| `state` | `varchar(6)` | x | `'ACTIVE'` | Một trong: `ACTIVE`, `LIFTED`. |
| `lifted_by` | `varchar(64)` |  |  |  |
| `lifted_at` | `timestamptz` |  |  |  |
| `lift_reason` | `varchar(500)` |  |  |  |
| `reminded_at` | `timestamptz` |  |  | Lần nhắc SO và TA gần nhất; sau 4 giờ chưa mở lại thì nhắc (đề xuất Q03-46 của UC). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |
| `OR` | `(target_type = 'CONSUMER' AND consumer_id IS AND route_id IS NULL))` | x |  |  |

: Cột của bảng `emergency_block`

### 3.11. `plan_policy`

::: dac-ta
**Mục đích.** EN-03-05 Chính sách chiếu từ gói sử dụng của PH-02: phương thức bảo mật, hạn mức giây và phút, hạn ngạch giờ, ngày, tháng, danh sách đường dẫn cho phép và chặn (FR-03-015, 020, 021, 022). PH-02 là nguồn sự thật; PH-03 chỉ giữ bản chiếu để sinh cấu hình.

**FR phục vụ.** FR-03-015, 016, 017, 020, 021, 022.

**Khóa chính.** (id).

**Duy nhất.** `uq_plan_policy_code` (tenant_id, policy_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_plan_policy_tenant`, `ck_plan_policy_mode`, `ck_plan_policy_rate`, `ck_plan_policy_quota`, `ck_plan_policy_paths`, `ck_plan_policy_state`.

**Chỉ mục.** `ix_plan_policy_api`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_plan_policy_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `policy_code` | `varchar(127)` | x |  |  |
| `plan_code` | `varchar(64)` | x |  |  |
| `api_code` | `varchar(127)` | x |  |  |
| `security_mode` | `varchar(8)` | x |  | KEYLESS chỉ cho API dữ liệu mở: kiểm ở CHK-06, không kiểm ở CSDL vì cần data_class của route. |
| `rate_limits` | `jsonb` | x | `'{}'` | Chỉ khóa second, minute, ví dụ {"second":20,"minute":600} (LGC-APIM-012). |
| `quotas` | `jsonb` | x | `'{}'` | Chỉ khóa hour, day, month, ví dụ {"hour":20000,"day":200000} (LGC-APIM-013); chỉ để bảo vệ hệ thống và thống kê, không tính tiền (BR-03-020). |
| `path_allow` | `text[]` | x | `'{}'` |  |
| `path_deny` | `text[]` | x | `'{}'` |  |
| `state` | `varchar(7)` | x | `'ACTIVE'` | Một trong: `ACTIVE`, `RETIRED`. |
| `source_version` | `bigint` | x | `0` |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `plan_policy`

### 3.12. `subscription_ref`

::: dac-ta
**Mục đích.** Bản chiếu đăng ký sử dụng của PH-02 (consumer x route x gói) cho FR-03-016: gateway chỉ cho consumer có đăng ký hiệu lực đi qua (dh-auth.allowedConsumers). Hết hạn (valid_to) do ExpiryScheduler chuyển EXPIRED. Dẫn xuất, đề nghị EN-03-17.

**FR phục vụ.** FR-03-016, 046.

**Khóa chính.** (id).

**Duy nhất.** `uq_subscription_ref` (tenant_id, consumer_id, route_id).

**Khóa ngoại.** (consumer_id, tenant_id) → `consumer`, (route_id, tenant_id) → `route`, (plan_policy_id, tenant_id) → `plan_policy`.

**Ràng buộc CHECK.** `ck_subscription_ref_tenant`, `ck_subscription_ref_state`, `ck_subscription_ref_window`.

**Chỉ mục.** `ix_subscription_ref_route`, `ix_subscription_ref_consumer`, `ix_subscription_ref_expiry`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_subscription_ref_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `consumer_id` | `uuid` | x |  |  |
| `route_id` | `uuid` | x |  |  |
| `plan_policy_id` | `uuid` | x |  |  |
| `state` | `varchar(9)` | x | `'ACTIVE'` | Một trong: `ACTIVE`, `SUSPENDED`, `EXPIRED`, `REVOKED`. |
| `valid_from` | `timestamptz` | x | `now()` |  |
| `valid_to` | `timestamptz` |  |  |  |
| `source_ref` | `varchar(64)` | x |  | Mã đăng ký ở PH-02, khóa lũy đẳng khi nhận lại sự kiện. |
| `source_version` | `bigint` | x | `0` |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `subscription_ref`

### 3.13. `rate_limit_override`

::: dac-ta
**Mục đích.** EN-03-06 Ghi đè hạn mức theo bốn phạm vi CONSUMER, CONSUMER_ROUTE, ROUTE, TENANT (FR-03-023, 024). Thứ tự ưu tiên giải ở bộ tổng hợp (SDD §4.4). Hạn mức toàn tenant (scope TENANT, cửa sổ 1 giây) là nơi lưu gw.tenantRateLimit.perSecond và burst; hạ thấp cần change_request đã duyệt (BR-03-019).

**FR phục vụ.** FR-03-021, 023, 024.

**Khóa chính.** (id).

**Duy nhất.** `uq_rate_limit_override_live` (tenant_id, scope, consumer_id, route_id, window_seconds) (NULLS NOT DISTINCT) có điều kiện khi retired_at IS NULL.

**Khóa ngoại.** (consumer_id, tenant_id) → `consumer`, (route_id, tenant_id) → `route`, (change_request_id, tenant_id) → `change_request`.

**Ràng buộc CHECK.** `ck_rate_limit_override_tenant`, `ck_rate_limit_override_scope`, `ck_rate_limit_override_target`, `ck_rate_limit_override_window`, `ck_rate_limit_override_tenant_window`, `ck_rate_limit_override_limit`, `ck_rate_limit_override_burst`, `ck_rate_limit_override_reason`.

**Chỉ mục.** `ix_rate_limit_override_route`, `ix_rate_limit_override_expiry`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_rate_limit_override_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Không xóa cứng (trigger `tg_rate_limit_override_nodelete`, BR-03-029).

**Ghi chú.** Nơi lưu thật của hạn mức toàn tenant (`scope = TENANT`); khóa duy nhất dùng `NULLS NOT DISTINCT` để hai ghi đè cùng phạm vi không cùng hiệu lực.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `scope` | `varchar(14)` | x |  | Một trong: `CONSUMER`, `CONSUMER_ROUTE`, `ROUTE`, `TENANT`. |
| `consumer_id` | `uuid` |  |  |  |
| `route_id` | `uuid` |  |  |  |
| `window_seconds` | `integer` | x |  | 1 giây, 60 giây, 3600 (giờ), 86400 (ngày), 2592000 (tháng 30 ngày). |
| `limit_value` | `bigint` | x |  |  |
| `burst_percent` | `smallint` | x | `0` | Dung sai đột biến theo phần trăm (gw.tenantRateLimit.burst mặc định 20%). |
| `reason` | `varchar(500)` | x |  |  |
| `expires_at` | `timestamptz` |  |  |  |
| `change_request_id` | `uuid` |  |  |  |
| `retired_at` | `timestamptz` |  |  | Gỡ là xóa mềm (BR-03-029); chỉ một ghi đè đang hiệu lực cho mỗi bộ (phạm vi, consumer, route, cửa sổ). |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |
| `OR` | `(scope = 'CONSUMER_ROUTE' AND consumer_id IS AND route_id IS)` | x |  |  |
| `OR` | `(scope = 'ROUTE' AND consumer_id IS NULL AND route_id IS)` | x |  |  |
| `OR` | `(scope = 'TENANT' AND consumer_id IS NULL AND route_id IS NULL))` |  |  |  |

: Cột của bảng `rate_limit_override`

### 3.14. `policy_template_setting`

::: dac-ta
**Mục đích.** Bật, tắt và tham số hóa mẫu chính sách gateway được duyệt sẵn theo tenant (FR-03-048). Danh mục mẫu và plugin cho phép đi cùng bản phát hành (PluginTemplateRegistry), không lưu ở CSDL; không có đường tải plugin hay mã Lua của tenant (BR-03-017). Dẫn xuất, đề nghị EN-03-18.

**FR phục vụ.** FR-03-048.

**Khóa chính.** (id).

**Duy nhất.** `uq_policy_template_setting` (tenant_id, template_code).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_policy_template_setting_tenant`, `ck_policy_template_setting_code`, `ck_policy_template_setting_version`, `ck_policy_template_setting_params`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_policy_template_setting_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `template_code` | `varchar(64)` | x |  | Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `template_version` | `varchar(16)` | x |  | Mẫu `^[0-9]+\.[0-9]+(\.[0-9]+)?$`. |
| `enabled` | `boolean` | x | `true` |  |
| `params` | `jsonb` | x | `'{}'` | Tham số chỉnh trong miền mẫu cho phép: hạn mức mặc định, mức hoang tưởng, thời hạn chờ. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `policy_template_setting`

### 3.15. `waf_exception`

::: dac-ta
**Mục đích.** EN-03-07 Ngoại lệ luật WAF có thời hạn (FR-03-007): bỏ qua một mã luật CRS cho một route. Có lý do, hạn tối đa 90 ngày, người duyệt khác người đề nghị (BR-03-006, BR-03-019); không có ngoại lệ vĩnh viễn, không gia hạn tự động (muốn kéo dài phải đề nghị lại).

**FR phục vụ.** FR-03-007.

**Khóa chính.** (id).

**Duy nhất.** `uq_waf_exception_live` (tenant_id, route_id, rule_id) có điều kiện khi state IN ('REQUESTED', 'ACTIVE', 'EXPIRING').

**Khóa ngoại.** (route_id, tenant_id) → `route`.

**Ràng buộc CHECK.** `ck_waf_exception_tenant`, `ck_waf_exception_rule`, `ck_waf_exception_reason`, `ck_waf_exception_state`, `ck_waf_exception_ttl`, `ck_waf_exception_four_eyes`, `ck_waf_exception_approved`, `ck_waf_exception_rejected`, `ck_waf_exception_revoked`.

**Chỉ mục.** `ix_waf_exception_route`, `ix_waf_exception_expiry`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_waf_exception_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Chuyển trạng thái theo bảng `state_transition` máy `WAF_EXCEPTION` (trigger `tg_waf_exception_state`). Cột ghi một lần: `route_id`, `rule_id`, `requested_by`, `requested_at`, `expires_at`, `reason` (trigger `tg_waf_exception_once`). Không xóa cứng (trigger `tg_waf_exception_nodelete`, BR-03-029).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `route_id` | `uuid` | x |  |  |
| `rule_id` | `varchar(8)` | x |  | Mã luật OWASP CRS (6 đến 8 chữ số, ví dụ 942100); tồn tại trong CRS đang dùng do dịch vụ kiểm (ERR-03-009). |
| `reason` | `varchar(1000)` | x |  |  |
| `state` | `varchar(9)` | x | `'REQUESTED'` | Một trong: `REQUESTED`, `ACTIVE`, `EXPIRING`, `REJECTED`, `EXPIRED`, `REVOKED`. |
| `requested_by` | `varchar(64)` | x |  |  |
| `requested_at` | `timestamptz` | x | `now()` |  |
| `approved_by` | `varchar(64)` |  |  |  |
| `approved_at` | `timestamptz` |  |  |  |
| `decision_note` | `varchar(1000)` |  |  |  |
| `expires_at` | `timestamptz` | x |  | Hết hạn tuyệt đối, tối đa requested_at + 90 ngày (gw.waf.exception.maxDays có thể đặt thấp hơn); bất biến sau khi đề nghị. |
| `expiring_notified_at` | `timestamptz` |  |  | Lần phát EVT-03-06 (còn gw.waf.exception.warnDays ngày). |
| `revoked_by` | `varchar(64)` |  |  |  |
| `revoked_at` | `timestamptz` |  |  |  |
| `revoke_reason` | `varchar(500)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `waf_exception`

### 3.16. `waf_virtual_patch`

::: dac-ta
**Mục đích.** EN-03-08 Luật vá ảo WAF khẩn cấp khi có lỗ hổng chưa có bản vá (FR-03-008, mức S, Đợt 2). Cùng quy tắc ngoại lệ: lý do, hạn tối đa 90 ngày, bốn mắt. Phạm vi PLATFORM lưu ở tenant COMMON (mọi tenant đọc, chỉ PLATFORM ghi); phạm vi TENANT, ROUTE lưu ở tenant của mình.

**FR phục vụ.** FR-03-008.

**Khóa chính.** (id).

**Duy nhất.** `uq_waf_virtual_patch_code` (tenant_id, patch_code).

**Khóa ngoại.** (route_id, tenant_id) → `route`.

**Ràng buộc CHECK.** `ck_waf_virtual_patch_tenant`, `ck_waf_virtual_patch_code`, `ck_waf_virtual_patch_scope`, `ck_waf_virtual_patch_rule`, `ck_waf_virtual_patch_reason`, `ck_waf_virtual_patch_state`, `ck_waf_virtual_patch_ttl`, `ck_waf_virtual_patch_four_eyes`, `ck_waf_virtual_patch_approved`, `ck_waf_virtual_patch_revoked`.

**Chỉ mục.** `ix_waf_virtual_patch_live`, `ix_waf_virtual_patch_expiry`.

**Cách ly tenant.** RLS mẫu S (FORCE): tenant đọc dòng của mình và dòng `COMMON`; chỉ ghi dòng của mình, dòng `COMMON` chỉ phiên `PLATFORM` ghi; chính sách `rls_waf_virtual_patch_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Chuyển trạng thái theo bảng `state_transition` máy `WAF_PATCH` (trigger `tg_waf_virtual_patch_state`). Cột ghi một lần: `patch_code`, `scope`, `route_id`, `rule_text`, `requested_by`, `requested_at`, `expires_at` (trigger `tg_waf_virtual_patch_once`). Không xóa cứng (trigger `tg_waf_virtual_patch_nodelete`, BR-03-029).

**Ghi chú.** Vai trò báo cáo không đọc cột `rule_text` (nội dung luật vá lộ chi tiết lỗ hổng chưa vá).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `patch_code` | `varchar(64)` | x |  | Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `scope` | `varchar(8)` | x |  |  |
| `route_id` | `uuid` |  |  |  |
| `rule_text` | `text` | x |  | Luật SecLang của Coraza, 10…4000 ký tự; được CHK-01 kiểm cú pháp trước khi phát; không chứa dữ liệu bí mật. |
| `reason` | `varchar(1000)` | x |  |  |
| `state` | `varchar(9)` | x | `'REQUESTED'` | Một trong: `REQUESTED`, `ACTIVE`, `EXPIRING`, `REJECTED`, `EXPIRED`, `REVOKED`. |
| `requested_by` | `varchar(64)` | x |  |  |
| `requested_at` | `timestamptz` | x | `now()` |  |
| `approved_by` | `varchar(64)` |  |  |  |
| `approved_at` | `timestamptz` |  |  |  |
| `decision_note` | `varchar(1000)` |  |  |  |
| `expires_at` | `timestamptz` | x |  |  |
| `revoked_by` | `varchar(64)` |  |  |  |
| `revoked_at` | `timestamptz` |  |  |  |
| `revoke_reason` | `varchar(500)` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |
| `OR` | `(scope = 'TENANT' AND tenant_id <> 'COMMON' AND route_id IS NULL)` |  |  |  |
| `OR` | `(scope = 'ROUTE' AND tenant_id <> 'COMMON' AND route_id IS))` | x |  |  |

: Cột của bảng `waf_virtual_patch`

### 3.17. `waf_mode`

::: dac-ta
**Mục đích.** Chế độ WAF theo phạm vi TENANT hoặc một route (gw.waf.mode, FR-03-006). Khóa lưu thật của tham số có bốn mắt: đổi sang BLOCK cần change_request WAF_MODE đã duyệt và đã chạy DETECT liên tục tối thiểu 14 ngày (ERR-03-027; tenant kiểm thử T90…T99 được miễn). Tự hạ ở nút (dh-waf-guard) không đổi bảng này.

**FR phục vụ.** FR-03-005, 006.

**Khóa chính.** (id).

**Duy nhất.** `uq_waf_mode_scope` (tenant_id, scope_kind, route_id) (NULLS NOT DISTINCT).

**Khóa ngoại.** (route_id, tenant_id) → `route`, (change_request_id, tenant_id) → `change_request`.

**Ràng buộc CHECK.** `ck_waf_mode_tenant`, `ck_waf_mode_scope`, `ck_waf_mode_mode`, `ck_waf_mode_block`, `ck_waf_mode_detect_period`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_waf_mode_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Không xóa cứng (trigger `tg_waf_mode_nodelete`, BR-03-029).

**Ghi chú.** Nơi lưu thật của `gw.waf.mode`; `tenant_param` không nhận khóa này. Trigger `tg_waf_mode_guard` kiểm yêu cầu thay đổi `WAF_MODE` đã duyệt.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `scope_kind` | `varchar(6)` | x | `'TENANT'` |  |
| `route_id` | `uuid` |  |  |  |
| `mode` | `varchar(6)` | x | `'DETECT'` | Một trong: `DETECT`, `BLOCK`. |
| `detect_since` | `timestamptz` | x | `now()` | Bắt đầu chuỗi ngày liên tục ở DETECT của phạm vi; đặt lại khi hạ từ BLOCK về DETECT. |
| `blocked_at` | `timestamptz` |  |  | Thời điểm chuyển sang BLOCK; NULL khi DETECT. |
| `change_request_id` | `uuid` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `waf_mode`

### 3.18. `ip_block`

::: dac-ta
**Mục đích.** EN-03-14 Địa chỉ nguồn bị chặn (FR-03-004): danh sách chặn tay do PA, TA khai (đi vào plugin_metadata của dh-ip-block) và bản ghi chặn tự động do nút báo (AUTO có hạn). Chặn tự động chạy cục bộ ở pod, không phụ thuộc kho nào. Không chặn dải rộng hơn /16 (IPv4) hoặc /48 (IPv6) (giả định chống chặn nhầm cả sở).

**FR phục vụ.** FR-03-003, 004.

**Khóa chính.** (id).

**Duy nhất.** `uq_ip_block_live` (tenant_id, cidr) có điều kiện khi retired_at IS NULL.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_ip_block_tenant`, `ck_ip_block_source`, `ck_ip_block_width`, `ck_ip_block_auto_expiry`, `ck_ip_block_reason`.

**Chỉ mục.** `ix_ip_block_expiry`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_ip_block_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Không xóa cứng (trigger `tg_ip_block_nodelete`, BR-03-029).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `cidr` | `cidr` | x |  | Dải bị chặn; không thuộc gw.ip.trustedCidrs và dải hạ tầng nền tảng (ERR-03-024, kiểm ở dịch vụ). |
| `source` | `varchar(6)` | x |  | Một trong: `AUTO`, `MANUAL`. |
| `reason` | `varchar(500)` | x |  |  |
| `expires_at` | `timestamptz` |  |  |  |
| `retired_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `ip_block`

### 3.19. `edge_certificate`

::: dac-ta
**Mục đích.** EN-03-11 Siêu dữ liệu chứng thư TLS biên (FR-03-049): chủ thể, host, hạn, vân tay, nhà phát hành. Khóa riêng chỉ ở OpenBao (secret_ref là đường dẫn, không phải khóa). Chứng thư dùng chung (ví dụ *.datahub.gov.vn) ở tenant COMMON, mọi tenant đọc, chỉ PLATFORM ghi. Gia hạn thay bằng chứng thư mới và đánh REPLACED, không sửa vân tay.

**FR phục vụ.** FR-03-001, 049.

**Khóa chính.** (id).

**Duy nhất.** `uq_edge_certificate_code` (tenant_id, cert_code), `uq_edge_certificate_fp` (tenant_id, fingerprint).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_edge_certificate_tenant`, `ck_edge_certificate_code`, `ck_edge_certificate_hosts`, `ck_edge_certificate_fp`, `ck_edge_certificate_validity`, `ck_edge_certificate_source`, `ck_edge_certificate_state`, `ck_edge_certificate_ref`.

**Chỉ mục.** `ix_edge_certificate_expiry`.

**Cách ly tenant.** RLS mẫu S (FORCE): tenant đọc dòng của mình và dòng `COMMON`; chỉ ghi dòng của mình, dòng `COMMON` chỉ phiên `PLATFORM` ghi; chính sách `rls_edge_certificate_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Cột ghi một lần: `cert_code`, `fingerprint`, `not_after`, `secret_ref` (trigger `tg_edge_certificate_once`).

**Ghi chú.** Không có khóa riêng ở bảng; `secret_ref` là đường dẫn OpenBao. Chứng thư dùng chung ở `COMMON`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `cert_code` | `varchar(64)` | x |  | Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `subject` | `varchar(255)` | x |  |  |
| `hosts` | `varchar(253)[]` | x |  |  |
| `issuer` | `varchar(255)` | x |  |  |
| `fingerprint` | `char(64)` | x |  | Mẫu `^[0-9a-f]{64}$`. |
| `not_before` | `timestamptz` | x |  |  |
| `not_after` | `timestamptz` | x |  |  |
| `source` | `varchar(12)` | x |  | Một trong: `CERT_MANAGER`, `MANUAL`. |
| `secret_ref` | `varchar(255)` | x |  | Đường dẫn OpenBao hoặc tên Secret chứa khóa riêng, ví dụ kv/dh/common/edge-cert/wildcard; bị chặn nếu chứa chữ PRIVATE (phòng dán nhầm khóa). |
| `state` | `varchar(8)` | x | `'ACTIVE'` | Một trong: `ACTIVE`, `EXPIRING`, `EXPIRED`, `REPLACED`. |
| `warned_30d_at` | `timestamptz` |  |  | Lần phát EVT-03-08 mức Cao (còn dưới 30 ngày); 7 ngày là mức Nghiêm trọng (warned_7d_at). |
| `warned_7d_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `edge_certificate`

### 3.20. `client_ca`

::: dac-ta
**Mục đích.** Bộ CA tin cậy để xác minh chứng thư khách mTLS (FR-03-002, FR-03-049 bước 6): CA HTTT của Datahub (OpenBao PKI) ở COMMON, CA do tỉnh chấp nhận ở tenant. Chỉ chứa chứng thư công khai của CA; thay đổi bộ CA đi theo ảnh chụp có kiểm tra hợp lệ. Dẫn xuất, đề nghị EN-03-19.

**FR phục vụ.** FR-03-002, 049.

**Khóa chính.** (id).

**Duy nhất.** `uq_client_ca_code` (tenant_id, ca_code), `uq_client_ca_fp` (tenant_id, fingerprint).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_client_ca_tenant`, `ck_client_ca_code`, `ck_client_ca_fp`, `ck_client_ca_pem`, `ck_client_ca_crl`, `ck_client_ca_state`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu S (FORCE): tenant đọc dòng của mình và dòng `COMMON`; chỉ ghi dòng của mình, dòng `COMMON` chỉ phiên `PLATFORM` ghi; chính sách `rls_client_ca_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Cột ghi một lần: `ca_code`, `fingerprint`, `public_pem` (trigger `tg_client_ca_once`).

**Ghi chú.** Chỉ chứng thư công khai của CA; vai trò báo cáo chỉ đọc cột siêu dữ liệu.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `ca_code` | `varchar(64)` | x |  | Mẫu `^[a-z][a-z0-9-]{2,63}$`. |
| `subject` | `varchar(255)` | x |  |  |
| `fingerprint` | `char(64)` | x |  | Mẫu `^[0-9a-f]{64}$`. |
| `not_after` | `timestamptz` | x |  |  |
| `public_pem` | `text` | x |  | Chứng thư CA dạng PEM (công khai); bị chặn nếu chứa PRIVATE KEY. |
| `crl_url` | `varchar(512)` |  |  | Địa chỉ CRL làm mới mỗi giờ (FR-03-002). |
| `state` | `varchar(8)` | x | `'ACTIVE'` | Một trong: `ACTIVE`, `DISABLED`, `EXPIRED`. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `client_ca`

### 3.21. `tls_exception`

::: dac-ta
**Mục đích.** Ngoại lệ cho phép TLS 1.2 trên một host chuyên dụng (FR-03-001, BR-03-003): có lý do, hạn tối đa 180 ngày, PA tạo; không bao giờ dưới TLS 1.2. Không phải EN của FRS §4.2 (đề nghị EN-03-20).

**FR phục vụ.** FR-03-001.

**Khóa chính.** (id).

**Duy nhất.** `uq_tls_exception_active` (tenant_id, host_id) có điều kiện khi state = 'ACTIVE'.

**Khóa ngoại.** (host_id, tenant_id) → `edge_host`.

**Ràng buộc CHECK.** `ck_tls_exception_tenant`, `ck_tls_exception_reason`, `ck_tls_exception_state`, `ck_tls_exception_ttl`, `ck_tls_exception_ended`.

**Chỉ mục.** `ix_tls_exception_expiry`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_tls_exception_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Chuyển trạng thái theo bảng `state_transition` máy `TLS_EXCEPTION` (trigger `tg_tls_exception_state`). Cột ghi một lần: `host_id`, `expires_at`, `reason` (trigger `tg_tls_exception_once`). Không xóa cứng (trigger `tg_tls_exception_nodelete`, BR-03-029).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `host_id` | `uuid` | x |  |  |
| `reason` | `varchar(1000)` | x |  |  |
| `state` | `varchar(6)` | x | `'ACTIVE'` | Một trong: `ACTIVE`, `ENDED`. |
| `expires_at` | `timestamptz` | x |  |  |
| `ended_by` | `varchar(64)` |  |  |  |
| `ended_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `tls_exception`

### 3.22. `tenant_redirect`

::: dac-ta
**Mục đích.** EN-03-13 Chuyển tiếp lượt gọi của tenant đã sáp nhập sang tenant đích (FR-03-037, D03-10 §5.4). Dòng thuộc tenant đích (tenant_id = to_tenant, ADR-003); tenant nguồn ở trạng thái MERGED nên không còn phiên. Mặc định 180 ngày (gw.redirect.defaultDays), tối đa 365; mỗi tenant nguồn chỉ một chuyển tiếp đang chạy.

**FR phục vụ.** FR-03-037.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_redirect_active` (from_tenant) có điều kiện khi state = 'ACTIVE'.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_tenant_redirect_tenant`, `ck_tenant_redirect_from`, `ck_tenant_redirect_window`, `ck_tenant_redirect_state`, `ck_tenant_redirect_ended`.

**Chỉ mục.** `ix_tenant_redirect_end`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_tenant_redirect_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Chuyển trạng thái theo bảng `state_transition` máy `TENANT_REDIRECT` (trigger `tg_tenant_redirect_state`). Cột ghi một lần: `from_tenant`, `to_tenant`, `start_at` (trigger `tg_tenant_redirect_once`). Không xóa cứng (trigger `tg_tenant_redirect_nodelete`, BR-03-029).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `from_tenant` | `varchar(16)` | x |  | Tenant nguồn (MERGED); token của tenant này bị từ chối ERR-03-106 kèm hướng dẫn nhận thông tin xác thực mới. |
| `to_tenant` | `varchar(16)` | x |  |  |
| `start_at` | `timestamptz` | x | `now()` |  |
| `end_at` | `timestamptz` | x |  |  |
| `state` | `varchar(6)` | x | `'ACTIVE'` | Một trong: `ACTIVE`, `ENDED`. |
| `reason` | `varchar(500)` |  |  |  |
| `ended_by` | `varchar(64)` |  |  |  |
| `ended_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `tenant_redirect`

### 3.23. `snapshot_counter`

::: dac-ta
**Mục đích.** Bộ đếm số phiên bản ảnh chụp, một dòng mỗi site (SnapshotCounter, SDD §4.10). Cấp số bằng SELECT … FOR UPDATE ngay trước bước ký để không trùng, không lùi kể cả khi hai bản sao dh-connect cùng chạy. Bảng kỹ thuật toàn nền tảng, không có tenant_id (chỉ chứa số).

**FR phục vụ.** FR-03-041, 042, 044.

**Khóa chính.** (site).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_snapshot_counter_site`, `ck_snapshot_counter_order`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không bật RLS: bảng kỹ thuật không có `tenant_id` (mục 1.2), ứng dụng chỉ chạm tới dữ liệu không thuộc tenant nào.

**Phân vùng, chỉ thêm.** Không phân vùng. Trigger `tg_snapshot_counter_monotonic` (`tg_counter_monotonic`). Không xóa cứng (trigger `tg_snapshot_counter_nodelete`, BR-03-029).

**Ghi chú.** Bảng kỹ thuật toàn nền tảng, một dòng mỗi site (`dc1`, `dc2` ở dữ liệu khởi tạo), chỉ chứa số; trigger `tg_counter_monotonic` không cho lùi. Ứng dụng không có INSERT, DELETE.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `site` | `varchar(8)` | x |  | Mẫu `^[a-z][a-z0-9]{1,7}$`. |
| `last_issued` | `bigint` | x | `0` | Số lớn nhất đã cấp; khoảng trống chỉ có khi ký thất bại sau khi cấp (nút chỉ yêu cầu "lớn hơn"). |
| `last_published` | `bigint` | x | `0` | Số lớn nhất đã phát; ảnh chụp có số nhỏ hơn bị bỏ (ERR-03-006). Khi chuyển site (DR) site mới bắt đầu từ số lớn nhất đã biết cộng gw.snapshot.drGap. |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |

: Cột của bảng `snapshot_counter`

### 3.24. `config_snapshot`

::: dac-ta
**Mục đích.** EN-03-09 Siêu dữ liệu ảnh chụp cấu hình (FR-03-039…044): nội dung ở Git và bucket dh-platform-gateway, bảng chỉ giữ phiên bản, băm, chữ ký, trạng thái. Mỗi dòng là một lần tổng hợp của một tenant (tenant_id) trên một site; số phiên bản tăng đơn điệu theo site, chỉ cấp ngay trước khi ký. Nội dung đã ký bất biến; quay lui sinh dòng mới (BR-03-018).

**FR phục vụ.** FR-03-039…045.

**Khóa chính.** (id).

**Duy nhất.** `uq_config_snapshot_version` (site, snapshot_version).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_config_snapshot_tenant`, `ck_config_snapshot_site`, `ck_config_snapshot_scope`, `ck_config_snapshot_state`, `ck_config_snapshot_trigger`, `ck_config_snapshot_hash`, `ck_config_snapshot_version`, `ck_config_snapshot_signed`, `ck_config_snapshot_unsigned`, `ck_config_snapshot_published`, `ck_config_snapshot_applied`, `ck_config_snapshot_rejected`, `ck_config_snapshot_rollback`, `ck_config_snapshot_built_from`, `ck_config_snapshot_counts`.

**Chỉ mục.** `ix_config_snapshot_tenant`, `ix_config_snapshot_open`, `ix_config_snapshot_git`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_config_snapshot_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Chuyển trạng thái theo bảng `state_transition` máy `SNAPSHOT` (trigger `tg_config_snapshot_state`). Cột ghi một lần: `site`, `scope`, `content_hash`, `manifest_hash`, `snapshot_version`, `signature_key_id`, `built_from`, `rollback_of_version`, `signed_at` (trigger `tg_config_snapshot_once`). Không xóa cứng (trigger `tg_config_snapshot_nodelete`, BR-03-029).

**Ghi chú.** Nội dung đã ký bất biến: `site`, `scope`, `content_hash`, `manifest_hash`, `snapshot_version`, `signature_key_id`, `built_from`, `signed_at` ghi một lần (trigger `tg_write_once`). Không xóa cứng, giữ siêu dữ liệu vĩnh viễn.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `site` | `varchar(8)` | x |  | Mẫu `^[a-z][a-z0-9]{1,7}$`. |
| `scope` | `varchar(8)` | x |  | TENANT: mảnh của một tenant; PLATFORM: phần dùng chung ở tenant COMMON (global_rules, plugin_configs, plugin_metadata, ssls). |
| `snapshot_version` | `bigint` |  |  | NULL khi BUILT hoặc REJECTED (chưa cấp số); bắt buộc từ SIGNED. Duy nhất theo site. |
| `state` | `varchar(10)` | x | `'BUILT'` | Một trong: `BUILT`, `REJECTED`. |
| `trigger_type` | `varchar(10)` | x |  | Một trong: `EVENT`, `RECONCILE`, `MANUAL`, `ROLLBACK`, `EXPIRY`, `EMERGENCY`, `RELEASE`. |
| `content_hash` | `char(64)` | x |  | SHA-256 của bản ghép đã chuẩn hóa (YAML chính tắc); tổng hợp là hàm thuần nên cùng đầu vào cùng băm, trùng băm bản đang chạy thì không phát (NO_CHANGE, không tạo dòng). |
| `manifest_hash` | `char(64)` |  |  | SHA-256 của manifest.json chuẩn hóa, là thứ được ký (ECDSA P-256 qua OpenBao transit). |
| `signature_key_id` | `varchar(64)` |  |  | Khóa ký dạng dh-gateway-snapshot:3 (xoay 12 tháng); không lưu chữ ký, chữ ký nằm ở manifest.sig. |
| `built_from` | `jsonb` | x | `'[]'` | Con trỏ nguồn đã dùng, ví dụ [{"source":"catalog","cursor":"e-1204455"}]; dùng tính syncState của consumer. |
| `route_count` | `integer` | x | `0` |  |
| `size_bytes` | `bigint` | x | `0` |  |
| `bucket_prefix` | `varchar(255)` |  |  |  |
| `git_commit` | `char(40)` |  |  |  |
| `git_pending` | `boolean` | x | `false` | true khi đã ghi bucket nhưng commit Git lỗi, đang xếp hàng thử lại tới 1 giờ. |
| `rollback_of_version` | `bigint` |  |  | Phiên bản cũ được sao nội dung khi quay lui; ảnh chụp mới luôn mang số lớn hơn. |
| `reject_summary` | `varchar(500)` |  |  |  |
| `requested_by` | `varchar(64)` | x |  |  |
| `built_at` | `timestamptz` | x | `now()` |  |
| `signed_at` | `timestamptz` |  |  |  |
| `published_at` | `timestamptz` |  |  |  |
| `applied_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `config_snapshot`

### 3.25. `snapshot_violation`

::: dac-ta
**Mục đích.** Kết quả kiểm tra hợp lệ gắn với ảnh chụp (ValidationReport, FR-03-040): mỗi vi phạm quy tắc CHK-nn mức ERROR (từ chối cả ảnh chụp) hoặc WARNING (không chặn). Thông điệp không chứa giá trị cấu hình nhạy cảm; chỉ thêm, xóa theo ảnh chụp khi dọn.

**FR phục vụ.** FR-03-040.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** (snapshot_id, tenant_id) → `config_snapshot`.

**Ràng buộc CHECK.** `ck_snapshot_violation_tenant`, `ck_snapshot_violation_rule`, `ck_snapshot_violation_level`, `ck_snapshot_violation_error`.

**Chỉ mục.** `ix_snapshot_violation_snapshot`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_snapshot_violation_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Chỉ thêm, chặn UPDATE (trigger `tg_snapshot_violation_append`).

**Ghi chú.** Dòng chỉ thêm (trigger chặn UPDATE); xóa cùng ảnh chụp khi dọn. Thông điệp không chứa giá trị cấu hình nhạy cảm.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `snapshot_id` | `uuid` | x |  |  |
| `rule_id` | `varchar(8)` | x |  | Mẫu `^CHK-[0-9]{2}$`. |
| `level` | `varchar(7)` | x |  | Một trong: `ERROR`, `WARNING`. |
| `object_ref` | `varchar(255)` |  |  | Đối tượng vi phạm, ví dụ route:tra-cuu-ho-tich.v1. |
| `error_code` | `varchar(10)` |  |  |  |
| `message` | `varchar(1000)` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |

: Cột của bảng `snapshot_violation`

### 3.26. `tenant_hold`

::: dac-ta
**Mục đích.** Bảng giữ tổng hợp tự động sau quay lui (HoldService, FR-03-044): trong thời gian giữ BuildCoordinator xếp hàng sự kiện, không tổng hợp. Mặc định gw.rollback.holdHours = 24, tối đa 168 giờ; hết hạn mà chưa bỏ giữ thì cảnh báo, không tự bỏ. Một giữ đang hoạt động mỗi tenant.

**FR phục vụ.** FR-03-044.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_hold_active` (tenant_id) có điều kiện khi state = 'ACTIVE'.

**Khóa ngoại.** (rollback_snapshot_id, tenant_id) → `config_snapshot`.

**Ràng buộc CHECK.** `ck_tenant_hold_tenant`, `ck_tenant_hold_reason`, `ck_tenant_hold_window`, `ck_tenant_hold_state`, `ck_tenant_hold_released`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_tenant_hold_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Chuyển trạng thái theo bảng `state_transition` máy `TENANT_HOLD` (trigger `tg_tenant_hold_state`). Không xóa cứng (trigger `tg_tenant_hold_nodelete`, BR-03-029).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `reason` | `varchar(500)` | x |  |  |
| `rollback_snapshot_id` | `uuid` |  |  |  |
| `hold_until` | `timestamptz` | x |  |  |
| `state` | `varchar(8)` | x | `'ACTIVE'` | Một trong: `ACTIVE`, `RELEASED`. |
| `released_by` | `varchar(64)` |  |  |  |
| `released_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `tenant_hold`

### 3.27. `source_cursor`

::: dac-ta
**Mục đích.** Con trỏ nguồn đã chiếu vào PH-03 theo tenant: PH-02 (CATALOG), PH-01 (ONBOARDING), PH-12 (IAM), PH-20 (TENANT_MGMT). Tác vụ đối chiếu 5 phút so con trỏ này với nguồn để bắt sự kiện bị lỡ; nguồn không trả quá 24 giờ thì cảnh báo, dùng bản chiếu gần nhất (SDD §4.8).

**FR phục vụ.** FR-03-039.

**Khóa chính.** (id).

**Duy nhất.** `uq_source_cursor` (tenant_id, source).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_source_cursor_tenant`, `ck_source_cursor_source`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_source_cursor_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `source` | `varchar(12)` | x |  | Một trong: `CATALOG`, `ONBOARDING`, `IAM`, `TENANT_MGMT`. |
| `last_cursor` | `varchar(64)` | x |  |  |
| `last_synced_at` | `timestamptz` | x | `now()` |  |
| `stale_since` | `timestamptz` |  |  | Thời điểm nguồn bắt đầu không trả lời; dh_gateway_source_stale_seconds. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `source_cursor`

### 3.28. `change_request`

::: dac-ta
**Mục đích.** EN-03-15 Yêu cầu thay đổi bốn mắt: đổi chế độ WAF, mở route ra cửa Internet, hạ hạn mức toàn tenant (FR-03-006, 023, 038; BR-03-019). Người duyệt khác người đề nghị, so theo tài khoản. Ngoại lệ và luật vá WAF có máy trạng thái riêng.

**FR phục vụ.** FR-03-006, 023, 038, 056.

**Khóa chính.** (id).

**Duy nhất.** `uq_change_request_pending` (tenant_id, change_type, target_type, target_code) có điều kiện khi state = 'PENDING'.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_change_request_tenant`, `ck_change_request_type`, `ck_change_request_target`, `ck_change_request_state`, `ck_change_request_reason`, `ck_change_request_payload`, `ck_change_request_decision`, `ck_change_request_four_eyes`, `ck_change_request_rejected_note`, `ck_change_request_substitute`, `ck_change_request_applied`.

**Chỉ mục.** `ix_change_request_inbox`, `ix_change_request_expiry`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_change_request_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Chuyển trạng thái theo bảng `state_transition` máy `CHANGE_REQUEST` (trigger `tg_change_request_state`). Cột ghi một lần: `change_type`, `target_type`, `target_code`, `requested_by`, `requested_at`, `payload` (trigger `tg_change_request_once`). Không xóa cứng (trigger `tg_change_request_nodelete`, BR-03-029).

**Ghi chú.** Đối tượng và nội dung bất biến sau khi tạo (trigger `tg_write_once`); chỉ đổi trạng thái và quyết định.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `change_type` | `varchar(24)` | x |  | Một trong: `WAF_MODE`, `ROUTE_EXPOSURE_EXT`, `TENANT_LIMIT_DECREASE`. |
| `target_type` | `varchar(12)` | x |  | Một trong: `TENANT`, `ROUTE`. |
| `target_code` | `varchar(127)` | x |  | Mã route khi target_type = ROUTE; mã tenant khi TENANT. |
| `payload` | `jsonb` | x | `'{}'` | Giá trị mong muốn, ví dụ {"mode":"BLOCK"} hoặc {"perSecond":300}; không chứa bí mật. |
| `reason` | `varchar(1000)` | x |  |  |
| `urgent` | `boolean` | x | `false` | Hạ WAF về DETECT khi có sự cố cảnh báo giả diện rộng: vẫn bốn mắt nhưng đánh dấu khẩn (FR-03-006). |
| `state` | `varchar(10)` | x | `'PENDING'` | Một trong: `APPROVED`, `REJECTED`. |
| `requested_by` | `varchar(64)` | x |  |  |
| `requested_at` | `timestamptz` | x | `now()` |  |
| `decided_by` | `varchar(64)` |  |  |  |
| `decided_at` | `timestamptz` |  |  |  |
| `decision_note` | `varchar(1000)` |  |  |  |
| `substitute_approval` | `boolean` | x | `false` | true khi PA duyệt thay vì tenant chỉ có một SO (gw.approval.substitute, Q03-02); kiểm toán ghi "duyệt thay". |
| `expires_at` | `timestamptz` | x | `(now() + interval '14 days')` | Hết hạn chờ sau 14 ngày (giả định, cơ sở: tránh việc treo vô hạn, SDD §8.1). |
| `applied_at` | `timestamptz` |  |  | Thời điểm bộ xử lý (ChangeHandlerRegistry) áp thay đổi; thay đổi chỉ vào gateway khi ảnh chụp mới được nạp. |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `change_request`

### 3.29. `param_definition`

::: dac-ta
**Mục đích.** Mô tả tham số gw.* của FRS §8.2: kiểu, mặc định, miền, có bốn mắt hay không (SDD §4.16 "bảng mô tả tham số"). Danh mục toàn nền tảng ở tenant COMMON: mọi tenant đọc, chỉ phiên PLATFORM ghi. Miền là giới hạn nền tảng; trần hợp đồng của tenant (PH-20) do dịch vụ kiểm (ERR-03-018).

**FR phục vụ.** FR-03-056.

**Khóa chính.** (id).

**Duy nhất.** `uq_param_definition_key` (param_key).

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_param_definition_tenant`, `ck_param_definition_key`, `ck_param_definition_type`, `ck_param_definition_range`, `ck_param_definition_enum`, `ck_param_definition_four_eyes`, `ck_param_definition_managed`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu S (FORCE): tenant đọc dòng của mình và dòng `COMMON`; chỉ ghi dòng của mình, dòng `COMMON` chỉ phiên `PLATFORM` ghi; chính sách `rls_param_definition_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Không xóa cứng (trigger `tg_param_definition_nodelete`, BR-03-029).

**Ghi chú.** Danh mục toàn nền tảng ở tenant `COMMON`, dữ liệu khởi tạo 66 tham số (§5); tenant chỉ đọc.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x | `'COMMON'` | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `param_key` | `varchar(64)` | x |  | Mẫu `^gw\.[A-Za-z0-9.]+$`. |
| `value_type` | `varchar(10)` | x |  | Một trong: `INT`, `DECIMAL`, `BYTES`, `PERCENT`, `BOOL`, `ENUM`, `CIDR_LIST`. |
| `default_value` | `jsonb` | x |  |  |
| `min_value` | `numeric` |  |  |  |
| `max_value` | `numeric` |  |  |  |
| `allowed_values` | `text[]` |  |  |  |
| `unit` | `varchar(16)` |  |  |  |
| `four_eyes` | `varchar(11)` | x | `'NONE'` | NONE; ALWAYS: đổi cần change_request đã duyệt; ON_DECREASE: chỉ khi hạ thấp (gw.tenantRateLimit.perSecond). |
| `managed_in` | `varchar(32)` |  |  | Khác NULL: giá trị của tenant lưu ở bảng được nêu (waf_mode, rate_limit_override) chứ không ở tenant_param. |
| `description` | `varchar(500)` | x |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `param_definition`

### 3.30. `tenant_param`

::: dac-ta
**Mục đích.** Giá trị tham số gw.* ghi đè mặc định theo tenant (FR-03-056). Trigger tg_tenant_param_guard kiểm kiểu, miền theo param_definition; tham số có bốn mắt phải mang change_request_id; tham số lưu ở bảng khác (managed_in) bị từ chối. Không có dòng nghĩa là dùng mặc định.

**FR phục vụ.** FR-03-023, 056.

**Khóa chính.** (id).

**Duy nhất.** `uq_tenant_param` (tenant_id, param_key).

**Khóa ngoại.** (param_key) → `param_definition`, (change_request_id, tenant_id) → `change_request`.

**Ràng buộc CHECK.** `ck_tenant_param_tenant`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_tenant_param_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Trigger `tg_tenant_param_guard` (`tg_tenant_param_guard`).

**Ghi chú.** Trigger `tg_tenant_param_guard` kiểm kiểu, miền và bốn mắt theo `param_definition`; không có dòng nghĩa là dùng mặc định.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `param_key` | `varchar(64)` | x |  |  |
| `param_value` | `jsonb` | x |  | Giá trị JSON đúng kiểu: số, true/false, chuỗi ENUM hoặc mảng CIDR; trần hợp đồng PH-20 do dịch vụ kiểm. |
| `change_request_id` | `uuid` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `tenant_param`

### 3.31. `synthetic_check`

::: dac-ta
**Mục đích.** Cấu hình kiểm tra tổng hợp cho API quan trọng (FR-03-053, BR-03-027): gọi qua địa chỉ thật của cửa vào bằng consumer dh-synthetic-{tenant}, mỗi phút. Chỉ phương thức đọc; lượt gọi mang tiêu đề đánh dấu, không tính hạn mức của HTTT thật và bị loại khỏi báo cáo. Kết quả nằm ở Mimir (dh_gateway_synthetic_up), không lưu bảng.

**FR phục vụ.** FR-03-053.

**Khóa chính.** (id).

**Duy nhất.** `uq_synthetic_check_code` (tenant_id, check_code).

**Khóa ngoại.** (route_id, tenant_id) → `route`.

**Ràng buộc CHECK.** `ck_synthetic_check_tenant`, `ck_synthetic_check_code`, `ck_synthetic_check_method`, `ck_synthetic_check_path`, `ck_synthetic_check_status`, `ck_synthetic_check_timeout`, `ck_synthetic_check_interval`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_synthetic_check_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `check_code` | `varchar(63)` | x |  | Mẫu `^[a-z][a-z0-9-]{2,62}$`. |
| `route_id` | `uuid` | x |  |  |
| `method` | `varchar(7)` | x | `'GET'` | Một trong: `GET`, `HEAD`, `OPTIONS`. |
| `path` | `varchar(512)` | x |  | Đường dẫn thật, không có chuỗi truy vấn (tham số truy vấn có thể là dữ liệu cá nhân). |
| `expected_status` | `integer[]` | x | `'{200}'` |  |
| `expected_body_jsonpath` | `varchar(255)` |  |  |  |
| `timeout_ms` | `integer` | x | `10000` |  |
| `interval_seconds` | `integer` | x | `60` |  |
| `enabled` | `boolean` | x | `true` |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `synthetic_check`

### 3.32. `legacy_import_job`

::: dac-ta
**Mục đích.** Lần nhập cấu hình từ gateway cũ (FR-03-059): gói xuất tối đa 50 MiB được LegacyBundleScanner chỉ đọc dữ liệu (không thực thi, từ chối trường bí mật), ánh xạ thành cấu hình nháp. Nội dung gói không lưu ở bảng, chỉ băm, kích thước và báo cáo; áp dụng nháp là thao tác riêng tạo dữ liệu nguồn ở PH-02, PH-01 chứ không ghi thẳng vào ảnh chụp.

**FR phục vụ.** FR-03-059.

**Khóa chính.** (id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_legacy_import_job_tenant`, `ck_legacy_import_job_sha`, `ck_legacy_import_job_size`, `ck_legacy_import_job_mode`, `ck_legacy_import_job_state`, `ck_legacy_import_job_findings`, `ck_legacy_import_job_applied`, `ck_legacy_import_job_four_eyes`.

**Chỉ mục.** `ix_legacy_import_job_tenant`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_legacy_import_job_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng. Chuyển trạng thái theo bảng `state_transition` máy `IMPORT_JOB` (trigger `tg_legacy_import_job_state`).

**Ghi chú.** Cột ngữ cảnh theo D00-01 §5.1; `version` là khóa lạc quan, thành phần của ETag (`If-Match`).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | x |  | Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5). |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `file_name` | `varchar(255)` | x |  |  |
| `file_sha256` | `char(64)` | x |  | Mẫu `^[0-9a-f]{64}$`. |
| `size_bytes` | `bigint` | x |  |  |
| `mapping_mode` | `varchar(12)` | x | `'PROPOSE_ONLY'` | Một trong: `PROPOSE_ONLY`, `APPLY`. |
| `state` | `varchar(8)` | x | `'UPLOADED'` | Một trong: `UPLOADED`, `SCANNED`, `PROPOSED`, `APPLIED`, `FAILED`. |
| `findings` | `jsonb` | x | `'[]'` | Danh sách mục không ánh xạ được hoặc cảnh báo, mỗi mục {path, code, message}; không chép giá trị bí mật (chỉ vị trí). |
| `summary` | `jsonb` | x | `'{}'` | Số lượng theo loại: {"apis":{"found":40,"mapped":37},"plans":{...},"applications":{...},"subscriptions":{...}}. |
| `requested_by` | `varchar(64)` | x |  |  |
| `scanned_at` | `timestamptz` |  |  |  |
| `applied_by` | `varchar(64)` |  |  |  |
| `applied_at` | `timestamptz` |  |  |  |
| `created_at` | `timestamptz` | x | `now()` | Thời điểm tạo. |
| `created_by` | `varchar(64)` | x |  | Người tạo (mã người dùng hoặc `system:*`). |
| `updated_at` | `timestamptz` | x | `now()` | Thời điểm sửa cuối (trigger `tg_touch`). |
| `updated_by` | `varchar(64)` | x |  | Người sửa cuối. |
| `version` | `integer` | x | `0` | Khóa lạc quan; thành phần của ETag (`If-Match`). |

: Cột của bảng `legacy_import_job`

### 3.33. `state_transition`

::: dac-ta
**Mục đích.** Bảng tham chiếu các cặp chuyển trạng thái hợp lệ; trigger tg_state_guard tra bảng này khi UPDATE cột state (FRS §4.3–4.5, SDD §8.1). Thêm cặp là một changeset mới.

**FR phục vụ.** FR-03-035, 036, 040, 044, 047 (bảng chuyển trạng thái).

**Khóa chính.** (entity, from_state, to_state).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_state_transition_distinct`.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không bật RLS: bảng kỹ thuật không có `tenant_id` (mục 1.2), ứng dụng chỉ chạm tới dữ liệu không thuộc tenant nào.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Bảng tham chiếu kỹ thuật không có `tenant_id`; ứng dụng chỉ đọc (REVOKE INSERT, UPDATE, DELETE), đổi bằng changeset Liquibase. Có 47 cặp cho 11 máy trạng thái; hai cặp mở rộng so với FRS ghi ở cột `note` (Q03-51).
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `entity` | `varchar(32)` | x |  |  |
| `from_state` | `varchar(16)` | x |  |  |
| `to_state` | `varchar(16)` | x |  |  |
| `command` | `varchar(64)` | x |  |  |
| `note` | `varchar(255)` |  |  |  |

: Cột của bảng `state_transition`

### 3.34. `outbox`

::: dac-ta
**Mục đích.** Outbox (DD-11, ADR-042) cho EVT-03-01…08, 10…12 và bản ghi kiểm toán gửi PH-13, ghi cùng giao dịch với thay đổi trạng thái; Debezium đẩy lên topic {tenant}.gateway.*, khóa phân vùng là mã đối tượng. EVT-03-09 do APISIX phát qua kafka-logger (không qua bảng này). Dọn sau 3 ngày.

**FR phục vụ.** Mọi FR phát sự kiện (EVT-03-01…08, 10…12); FR-03-042 (EVT-03-01).

**Khóa chính.** (event_id).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** `ck_outbox_tenant`, `ck_outbox_type`, `ck_outbox_topic`, `ck_outbox_topic_tenant`, `ck_outbox_trace`, `ck_outbox_no_secret`.

**Chỉ mục.** `ix_outbox_occurred`.

**Cách ly tenant.** RLS mẫu P (FORCE): mọi thao tác chỉ thấy dòng có `tenant_id = app.tenant_id` của phiên; dòng `COMMON` chỉ phiên `PLATFORM` thấy và ghi; chính sách `rls_outbox_*` (mục 1.2).

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Chỉ thêm và xóa khi dọn (ứng dụng không có UPDATE); Debezium đọc WAL. Khóa chính `event_id`, không có `id`, `version`.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `event_id` | `uuid` | x |  |  |
| `tenant_id` | `varchar(16)` | x |  | Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép. |
| `event_type` | `varchar(128)` | x |  | Mẫu `^vn\.datahub\.gateway\.[a-z-]+\.[a-z-]+\.v[0-9]+$`. |
| `topic` | `varchar(249)` | x |  | Mẫu `^(t[0-9]{2}\\|common)\.(gateway\\|audit)\.[a-z-]+(\.[a-z-]+)?\.v[0-9]+$`. |
| `aggregate_type` | `varchar(64)` | x |  |  |
| `aggregate_id` | `text` | x |  |  |
| `payload` | `jsonb` | x |  |  |
| `trace_id` | `char(32)` | x |  | Mẫu `^[0-9a-f]{32}$`. |
| `occurred_at` | `timestamptz` | x | `now()` |  |

: Cột của bảng `outbox`

### 3.35. `shedlock`

::: dac-ta
**Mục đích.** Khóa tác vụ nền (ExpiryScheduler, tác vụ đối chiếu 5 phút, ValkeyRebuilder, CertificateService mỗi giờ, NodeStateEvaluator); bảng kỹ thuật không có tenant_id.

**FR phục vụ.** FR-03-007, 018, 026, 039, 045, 049 (tác vụ định kỳ).

**Khóa chính.** (name).

**Duy nhất.** Không.

**Khóa ngoại.** Không.

**Ràng buộc CHECK.** Không.

**Chỉ mục.** Chỉ khóa chính và khóa duy nhất.

**Cách ly tenant.** Không bật RLS: bảng kỹ thuật không có `tenant_id` (mục 1.2), ứng dụng chỉ chạm tới dữ liệu không thuộc tenant nào.

**Phân vùng, chỉ thêm.** Không phân vùng.

**Ghi chú.** Bảng kỹ thuật của thư viện ShedLock, không chứa dữ liệu nghiệp vụ và không có `tenant_id`; tác vụ nền liên tenant lặp từng tenant bên trong tác vụ.
:::

| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |
|---|---|---|---|---|
| `name` | `varchar(64)` | x |  |  |
| `lock_until` | `timestamptz` | x |  |  |
| `locked_at` | `timestamptz` | x |  |  |
| `locked_by` | `varchar(255)` | x |  |  |

: Cột của bảng `shedlock`

<!-- gen:tables:end -->

### 3.36. Truy vấn chính và chỉ mục phục vụ

Bảng dưới nối từng truy vấn thường xuyên của `dh-connect` với chỉ mục phục vụ nó, để người viết dịch vụ không phải đoán và DBA biết chỉ mục nào có lý do tồn tại. Số liệu cỡ bảng ở chương 7; hồ sơ "tỉnh vừa" (GĐ-07) có khoảng 1.000 route và 200 consumer mỗi tenant, hồ sơ `QM-CHUNG` có khoảng 70.000 route toàn nền tảng (NFR-03-017).

| Truy vấn | API, tác vụ | Chỉ mục |
|---|---|---|
| Đọc mọi route `ACTIVE`, `PENDING` của một tenant để tổng hợp | `SnapshotAssembler` (FR-03-039) | `ix_route_state` |
| Danh sách route lọc trạng thái, API, phiên bản | UI-03-02, API-03-001 | `ix_route_state`, `ix_route_api` |
| Route dùng chung một upstream | Xóa hoặc đổi upstream | `ix_route_upstream` |
| Route đang mở ra Internet (rà soát định kỳ) | UI-03-17, FR-03-038 | `ix_route_ext` (một phần) |
| Route đến ngày `SUNSET` | `ExpiryScheduler` mỗi phút | `ix_route_sunset` (một phần) |
| Lịch sử trạng thái của route | UI-03-02 | `ix_route_state_event_route` |
| Consumer theo HTTT, theo trạng thái | UI-03-04, FR-03-046 | `ix_consumer_system`, `ix_consumer_state` |
| Chứng thư, khóa API sắp hết hạn | Cảnh báo hạn thông tin xác thực | `ix_consumer_credential_expiry` |
| Tra consumer theo vân tay chứng thư | FR-03-014, đối soát | `uq_consumer_credential_thumb` |
| Danh sách consumer được phép của một route (`allowedConsumers`) | `PluginChainComposer` | `ix_subscription_ref_route` |
| Đăng ký của một consumer | UI-03-05 | `ix_subscription_ref_consumer` |
| Đăng ký đến hạn `valid_to` | `ExpiryScheduler` | `ix_subscription_ref_expiry` (một phần) |
| Ghi đè hạn mức của một route để giải thứ tự ưu tiên | `PolicyResolver` (FR-03-024) | `ix_rate_limit_override_route` (một phần) |
| Ghi đè hạn mức hết hạn | `ExpiryScheduler` | `ix_rate_limit_override_expiry` |
| Ngoại lệ WAF của route; ngoại lệ sắp hết hạn | UI-03-07, 08; `ExpiryScheduler` | `ix_waf_exception_route`, `ix_waf_exception_expiry` |
| Luật vá còn hiệu lực của tenant | `TenantShardRenderer` | `ix_waf_virtual_patch_live` |
| Hộp việc duyệt, yêu cầu quá 14 ngày | UI-03-17, `ExpiryScheduler` | `ix_change_request_inbox`, `ix_change_request_expiry` |
| Ảnh chụp mới nhất của tenant | UI-03-10 | `ix_config_snapshot_tenant` |
| Ảnh chụp chưa `APPLIED`, chờ trạng thái nút | `NodeStateEvaluator` mỗi 30 giây | `ix_config_snapshot_open` (một phần) |
| Ảnh chụp có commit Git đang chờ | `SnapshotPublisher` thử lại | `ix_config_snapshot_git` (một phần) |
| Vi phạm của một ảnh chụp | UI-03-10, API-03-058 | `ix_snapshot_violation_snapshot` |
| Dựng lại Valkey: token thu hồi chưa hết hạn | `ValkeyRebuilder` | `ix_revoked_token_expiry`, `uq_revoked_token_jti`, `uq_revoked_token_sub` |
| Dựng lại Valkey: khối tạm ngừng đang hoạt động | `ValkeyRebuilder`, nhắc sau 4 giờ | `uq_emergency_block_active`, `ix_emergency_block_reminder` |
| Chứng thư biên sắp hết hạn | `CertificateService` mỗi giờ | `ix_edge_certificate_expiry` (một phần) |
| Chuyển tiếp sáp nhập, ngoại lệ TLS đến hạn | `ExpiryScheduler` | `ix_tenant_redirect_end`, `ix_tls_exception_expiry` |
| Chặn địa chỉ hết hạn | `ExpiryScheduler` | `ix_ip_block_expiry` |
| Dọn khóa lũy đẳng, outbox | Tác vụ dọn hằng giờ | `ix_idempotency_key_expiry`, `ix_outbox_occurred` |
| Lần nhập hệ cũ gần nhất | UI-03-18 | `ix_legacy_import_job_tenant` |

: Truy vấn chính và chỉ mục phục vụ

## 4. DDL và changelog Liquibase

### 4.1. Tệp

[`ph03/ddl/ph03_gateway.sql`](ph03/ddl/ph03_gateway.sql) là nguồn duy nhất, chia 12 tệp changeset bằng `-- @file` và 49 changeset bằng `-- @changeset`, mỗi changeset có `-- @rollback`, như PH-04, PH-05, PH-07. Changelog Liquibase sinh bằng công cụ của PH-07 sau khi tham số hóa tên phân hệ (đề nghị đồng bộ). Thứ tự tạo bảng khác thứ tự trình bày ở chương 3 vì `change_request` phải có trước `route` (khóa ngoại `exposure_request_id`).

| Tệp | Nội dung |
|---|---|
| `03-0000-bootstrap.sql` | Vai trò `ph03_owner`, `ph03_app`, `ph03_readonly`; schema; biến phiên `PLATFORM` |
| `03-0001-functions.sql` | `tg_touch`, `p_enable_rls`, `tg_append_only`, `tg_no_delete`, `tg_write_once`, `tg_state_guard`; bảng `state_transition` kèm 47 cặp |
| `03-0010-change-request.sql` | `change_request` |
| `03-0020-routing.sql` | `edge_host`, `upstream`, `upstream_node`, `route` kèm trigger `tg_route_ext_guard`, `route_state_event` |
| `03-0030-consumer.sql` | `consumer`, `consumer_credential`, `idempotency_key`, `revoked_token`, `emergency_block` |
| `03-0040-policy.sql` | `plan_policy`, `subscription_ref`, `rate_limit_override`, `policy_template_setting` |
| `03-0050-edge.sql` | `waf_exception`, `waf_virtual_patch`, `waf_mode` kèm `tg_waf_mode_guard`, `ip_block`, `edge_certificate`, `client_ca`, `tls_exception`, `tenant_redirect` |
| `03-0060-snapshot.sql` | `snapshot_counter` kèm `tg_counter_monotonic`, `config_snapshot`, `snapshot_violation`, `tenant_hold`, `source_cursor` |
| `03-0070-params.sql` | `param_definition`, `tenant_param` kèm `tg_tenant_param_guard` |
| `03-0080-ops.sql` | `synthetic_check`, `legacy_import_job`, `outbox`, `shedlock` |
| `03-0800-seed.sql` | 66 tham số `gw.*`, bộ đếm hai site (chạy lại được, `runOnChange`) |
| `03-0900-grants.sql` | Quyền theo vai trò; chạy lại mỗi lần (`runAlways`) |

: Tệp changeset của DDL

### 4.2. Kết quả chạy thử

Chạy ngày 26/11/2026 trên PostgreSQL 16.16, dữ liệu giả:

- DDL chạy không lỗi trên **database rỗng** (tạo mới, chạy `ph03_gateway.sql` rồi bài kiểm trong cùng một phiên) và trên schema dựng lại (`DROP SCHEMA … CASCADE` rồi chạy lại). Kết quả danh mục: 35 bảng, 32 bảng `FORCE ROW LEVEL SECURITY` với 128 chính sách (4 mỗi bảng), 214 `CHECK`, 24 khóa ngoại, 110 chỉ mục, 72 trigger, 66 tham số và 47 cặp chuyển trạng thái khởi tạo.
- [`ph03_isolation_test.sql`](ph03/test/ph03_isolation_test.sql) dưới tài khoản `dh_connect_app` (và `dh_gateway_report` cho nhóm 39) đạt **80 phép kiểm ở 40 nhóm**, toàn bộ trong một giao dịch rồi `ROLLBACK` nên chạy lại được. Nhóm A (1 đến 8d): tenant T01 không đọc, không chèn, không sửa được dòng T68 ở 12 bảng; biến phiên rỗng thấy 0 dòng; tenant không ghi được dòng `COMMON`; tham số nền tảng đọc được 66 dòng nhưng không sửa; chứng thư và luật vá dùng chung đọc được; host chỉ thuộc một tenant; route không trỏ được host, upstream của tenant khác; hai route trùng host, đường dẫn, phương thức bị chặn. Nhóm B đến C (9 đến 10d): mã route, consumer bất biến; không xóa cứng kể cả chủ schema; máy trạng thái route chặn `PENDING → STOPPED` và `STOPPED → SUSPENDED`; dừng route thiếu lý do bị chặn. Nhóm D đến F (11 đến 18b): API `SENSITIVE` thiếu mTLS, CORS `*`, `SUNSET` dưới 180 ngày, upstream link-local, thời hạn chờ 45.000 ms bị chặn; mở route ra Internet khi chưa duyệt, người đề nghị tự duyệt, yêu cầu trùng bị chặn; khóa API dạng rõ, khóa quá 180 ngày, vân tay thứ ba, vân tay trùng giữa hai tenant bị chặn. Nhóm G đến J (19 đến 30e): người đề nghị không tự duyệt ngoại lệ WAF, ngoại lệ quá 90 ngày, trùng cặp route và mã luật, kéo dài hạn tại chỗ bị chặn; `BLOCK` thiếu yêu cầu đã duyệt hoặc chưa đủ 14 ngày bị chặn; hạn mức toàn tenant thứ hai bị chặn; ảnh chụp `SIGNED` thiếu số phiên bản, số phiên bản và băm đã ký đổi được, số phiên bản trùng giữa hai tenant, bộ đếm lùi đều bị chặn; tham số ngoài miền, sai kiểu, sai ENUM, CIDR sai, `gw.waf.mode` ghi thẳng bị chặn. Nhóm K đến N (31 đến 40): outbox sai tenant hoặc chứa `apiKey`, CA chứa khóa riêng, `secret_ref` chứa khóa bị chặn; thu hồi `jti` kèm `sub`, khối tạm ngừng thiếu lý do hoặc trùng, chuyển tiếp sáp nhập sai tenant hoặc trùng, chặn dải /8 bị chặn; lịch sử trạng thái chỉ thêm kể cả với chủ schema; ứng dụng không sửa được `state_transition`; vai trò báo cáo đọc theo tenant, không ghi, không đọc `rule_text` và `public_pem`; kiểm cấu trúc: không bảng nghiệp vụ nào thiếu `FORCE RLS`, `tenant_id` hay đủ bốn chính sách, không vai trò nào `BYPASSRLS`.
- Bài kiểm **phát hiện hai lỗi của chính DDL bản nháp** và đã sửa trước khi chốt: (1) `CHECK` dùng `char_length(cột_có_thể_NULL) >= 10` cho kết quả `NULL` nên lý do rỗng lọt qua (sửa bằng `coalesce(…, 0)` ở `route`, `emergency_block`, `waf_exception`, `waf_virtual_patch`); (2) cột `tenant_redirect.state` rộng 5 ký tự không chứa được `ACTIVE`. Một đoạn mã quét đối chiếu độ rộng cột `varchar(n)` với mọi `CHECK … IN (…)` của DDL không còn báo lỗi nào.
- Chưa chạy: sinh changelog Liquibase (công cụ PH-07 đang gắn cứng tên phân hệ, chờ đợt đồng bộ) và kiểm thử tải truy vấn trên dữ liệu cỡ `QM-CHUNG`; cả hai là việc của giai đoạn hiện thực.

Bài kiểm `TenantIsolationIT` (D03-02-PH03 §12) tự động hóa các ca này trong CI bằng Testcontainers, dùng chính tệp SQL này làm bộ ca nền (SEC-87).

## 5. Dữ liệu khởi tạo

| Dữ liệu | Tenant | Nội dung | Nguồn |
|---|---|---|---|
| Tham số `gw.*` | `COMMON` | 66 dòng `param_definition`: kiểu, mặc định, miền, bốn mắt; id tất định theo khóa (`md5('ph03-param:' \|\| khóa)`) | FRS §8.2; `gw.approval.substitute` từ SDD §4.14 |
| Cặp chuyển trạng thái | không tenant | 47 dòng `state_transition` cho 11 máy | FRS §4.3 đến §4.5, SDD §8.1, mục 1.5 |
| Bộ đếm phiên bản | không tenant | Hai dòng `snapshot_counter` (`dc1`, `dc2`), `last_issued = 0` | SDD §4.10, D03-09 (hai site active–standby, ADR-034) |
| Mẫu chính sách và danh mục plugin | Không lưu | Đóng trong bản phát hành (`PluginTemplateRegistry`); tenant chỉ có `policy_template_setting` khi bật hoặc chỉnh tham số | SDD §4.8, BR-03-017 |
| Dữ liệu theo tenant mới | `T{nn}` | Khi PH-20 phát sự kiện tạo tenant, `dh-connect` tạo: một dòng `waf_mode` phạm vi `TENANT` ở `DETECT` (FR-03-006); bốn dòng `source_cursor`; một ghi đè hạn mức `TENANT` theo hợp đồng (mặc định 500 lượt/giây, dung sai 20%); hai host `{tenant}.api.datahub.gov.vn`, `{tenant}.datahub.gov.vn` ở `edge_host` (giả định đặt tên, chờ D03-10 §5.2 và Q03-53) | FR-03-006, 023, 038; D03-10 §5.2 |

: Dữ liệu khởi tạo

Seed chạy dưới `app.tenant_id = 'PLATFORM'`, lũy đẳng (`ON CONFLICT DO UPDATE`), và thuộc changeset `runOnChange` nên bản phát hành đổi mặc định chỉ cần sửa tệp seed. `param_definition` chỉ chứa mặc định nền tảng; giá trị của tenant ở `tenant_param`, hoặc ở `waf_mode` và `rate_limit_override` đối với hai khóa `managed_in` (`gw.waf.mode`, `gw.tenantRateLimit.*`).

## 6. Kho lưu trữ ngoài PostgreSQL

Chương này mô tả dữ liệu của PH-03 nằm ngoài `ph03_gateway`, vì cả hai mặt phẳng cùng đọc các định dạng này và vì quy tắc "PostgreSQL là nguồn sự thật" (mục 1.6) phải thể hiện được ở từng kho.

### 6.1. Valkey

Mọi khóa lập bởi `FastKeys` với tiền tố `{tenant}` (dấu ngoặc nhọn là hash tag của Valkey cluster ở `QM-CHUNG` để kịch bản nhiều khóa rơi vào một slot); không nơi nào ghép tên khóa bằng tay (luật Semgrep, SEC-82). Plugin có tài khoản ACL chỉ `GET`, `EVALSHA`, `XADD` trên tiền tố tenant; `dh-connect` có quyền ghi khóa chặn; hai tài khoản tách nhau.

| Khóa | Giá trị | Thời hạn | Bản bền ở PostgreSQL | Dựng lại khi mất |
|---|---|---|---|---|
| `{T68}:revoked:jti:{jti}` | `1` | Còn lại của token cộng 60 giây | `revoked_token` (`kind = JTI`) | Nạp lại dòng chưa hết hạn bằng `SET` lũy đẳng |
| `{T68}:revoked:sub:{sub}` | `notBefore` (giây epoch) | Thời gian sống tối đa của token | `revoked_token` (`kind = SUB`) | Như trên |
| `{T68}:kill:route:{routeCode}` | Mã lệnh `SUSPENDED` | Tới khi mở lại | `emergency_block` (`ROUTE`, `ACTIVE`) | Nạp lại khối `ACTIVE`; đường bền đã đặt `SUSPENDED` trong ảnh chụp |
| `{T68}:kill:consumer:{consumerCode}` | Mã lệnh | Tới khi mở lại | `emergency_block` (`CONSUMER`, `ACTIVE`) | Như trên |
| `{T68}:rl:t` | Bộ đếm tenant, cửa sổ 1 giây | 2 giây | Giới hạn ở `rate_limit_override` (`TENANT`); bộ đếm không bền | Đếm lại từ 0 |
| `{T68}:rl:c:{consumer}:{route}:{s\|m}` | Hai bộ đếm cửa sổ kề nhau | 2 chu kỳ | Giới hạn ở `plan_policy.rate_limits`, `rate_limit_override` | Đếm lại từ 0 |
| `{T68}:q:{consumer}:{route}:{h\|d\|mo}:{mốc}` | Bộ đếm hạn ngạch | Hết chu kỳ cộng 1 giờ | Giới hạn ở `plan_policy.quotas`; số chính xác ở ClickHouse | Chấp nhận đặt lại; mở có cảnh báo (BR-03-025, Q03-12) |
| `{T68}:evt:quota` | Stream sự kiện ngưỡng | 24 giờ, tối đa 10.000 mục | Không (EVT-03-07 ghi vào `outbox` sau khi `QuotaEventConsumer` đọc) | Mất cảnh báo trong chu kỳ đó |

: Khóa Valkey và bản bền tương ứng

`ValkeyRebuilder` thăm dò `PING` mỗi 10 giây; khi Valkey từ mất sang lên, nó nạp lại mọi dòng `revoked_token` chưa hết hạn và mọi `emergency_block` đang `ACTIVE` rồi quét đối chiếu để xóa khóa mồ côi. Ước lượng cỡ (giả định, cơ sở: 200 consumer, trung bình 6 đăng ký mỗi consumer, ba chu kỳ hạn ngạch, hai cửa sổ tần suất): khoảng 6.000 khóa đếm mỗi tenant, khoảng 200.000 khóa ở `QM-CHUNG` với 34 tenant, dưới 100 MiB.

### 6.2. Bucket và Git

Bucket `dh-platform-gateway` trên Ceph RGW (không WORM, vì nội dung tái lập được từ PostgreSQL) và kho Git cấu hình thư mục `gateway/{site}/`. Cấu trúc theo SDD §3.4 và đề nghị đồng bộ D03-09 §6.1 của FRS:

| Đường dẫn | Nội dung | Ghi chú |
|---|---|---|
| `snapshots/{site}/{version}/manifest.json`, `manifest.sig` | Manifest (băm từng tệp, `builtFrom`, `apisixImage`) và chữ ký ECDSA P-256 | Ghi `If-None-Match`, không ghi đè; khớp `config_snapshot.manifest_hash` |
| `snapshots/{site}/{version}/int.yaml`, `ext.yaml` | Bản ghép cho từng cửa | Khớp `config_snapshot.content_hash` (băm bản ghép đã chuẩn hóa) |
| `snapshots/{site}/{version}/shards/{tenant}-{gate}.yaml` | Mảnh tenant để so sánh, quay lui theo tenant | Một tenant quay lui không động tới tenant khác |
| `snapshots/{site}/current` | Số phiên bản và băm manifest, **ghi sau cùng** | Nút chỉ đọc bản đã đủ tệp |
| Git `gateway/{site}/` | Bản ghép và manifest, không khóa riêng | Lịch sử vĩnh viễn; `config_snapshot.git_commit`, cờ `git_pending` |

: Bucket và Git

Bucket giữ `gw.snapshot.retain` (50) phiên bản gần nhất; Git giữ vĩnh viễn (NFR-03-026). `config_snapshot.bucket_prefix` ghi tiền tố thư mục để quay lui và dọn.

### 6.3. OpenBao

| Đường dẫn | Nội dung | Ai ghi, ai đọc |
|---|---|---|
| `transit/keys/dh-gateway-snapshot` | Khóa ký ECDSA P-256 không xuất được, xoay 12 tháng; `config_snapshot.signature_key_id` ghi phiên bản khóa đã ký | `dh-connect` có quyền ký, không đọc khóa; khóa công khai các phiên bản còn hiệu lực đưa vào ConfigMap cho `dh-sync` |
| `kv/dh/{tenant}/edge-cert/{certCode}` (tên giả định, SDD chưa chốt) | Khóa riêng của chứng thư nhập tay | `dh-connect` ghi một lần khi nhập; External Secrets đưa vào Secret; `edge_certificate.secret_ref` trỏ tới đây |
| `kv/dh/common/gateway-git-deploy` (tên giả định) | Khóa triển khai ghi Git cấu hình | `dh-connect` đọc |
| `pki-…` (CA HTTT của Datahub, cấp qua PH-01) | Chứng thư khách của HTTT | Phần công khai của CA ở `client_ca.public_pem` |

: OpenBao

### 6.4. Kafka

Sự kiện nghiệp vụ của `dh-connect` đi qua `outbox` (ADR-042) rồi Debezium tới topic `{tenant}.gateway.{thực-thể}.{sự-kiện}.v1`; khóa phân vùng là mã đối tượng nên sự kiện một đối tượng giữ thứ tự; bên tiêu thụ lũy đẳng theo `eventId`. Phần nền tảng dùng `common.gateway.*` (ràng buộc `ck_outbox_topic` cho phép). Lược đồ tương thích BACKWARD ở Apicurio (ADR-070). Số phân vùng và thời gian giữ là giả định theo PH-05 (3 phân vùng, 7 ngày), chốt ở D03-09; khóa phân vùng ở bảng dưới theo nguyên tắc "mã đối tượng" của SDD §8.2 và được chốt ở D03-04-PH03 §7.

| Mã | Topic | Khóa phân vùng (đề xuất) | Nguồn ở CSDL |
|---|---|---|---|
| EVT-03-01 | `{tenant}.gateway.snapshot.published.v1` | `scope` | `config_snapshot` → `PUBLISHED` |
| EVT-03-02 | `{tenant}.gateway.snapshot.rolled-back.v1` | `scope` | `config_snapshot` (`trigger_type = ROLLBACK`), `tenant_hold` |
| EVT-03-03 | `{tenant}.gateway.route.state-changed.v1` | `routeCode` | `route.state`, `route_state_event` |
| EVT-03-04 | `{tenant}.gateway.consumer.state-changed.v1` | `consumerCode` | `consumer` |
| EVT-03-05 | `{tenant}.gateway.waf-exception.changed.v1` | `exceptionId` | `waf_exception`, `waf_virtual_patch` |
| EVT-03-06 | `{tenant}.gateway.waf-exception.expiring.v1` | `exceptionId` | `waf_exception.expiring_notified_at` |
| EVT-03-07 | `{tenant}.gateway.quota.threshold-reached.v1` | `consumerCode` | Stream Valkey `evt:quota` |
| EVT-03-08 | `{tenant}.gateway.certificate.expiring.v1` | `certCode` | `edge_certificate.warned_30d_at`, `warned_7d_at` |
| EVT-03-09 | `{tenant}.gateway.security.alert-raised.v1` | `routeCode` | Do APISIX phát qua `kafka-logger`; `dh-connect` chỉ ghi `outbox` khi tạm ngừng khẩn cấp |
| EVT-03-10 | `{tenant}.gateway.tenant-redirect.changed.v1` | `fromTenant` | `tenant_redirect` |
| EVT-03-11 | `{tenant}.gateway.limit.changed.v1` | `scopeKey` | `rate_limit_override`, `tenant_param` |
| EVT-03-12 | `{tenant}.gateway.snapshot.rejected.v1` | `scope` | `config_snapshot` → `REJECTED`, `snapshot_violation` |

: Kafka

### 6.5. ClickHouse (siêu dữ liệu lượt gọi, của PH-13)

Nhật ký lượt gọi không ở PostgreSQL. `file-logger` ghi một dòng JSON mỗi lượt gọi, OTel Collector che lần hai (SEC-32), gắn nhãn `tenant`, từ chối bản ghi thiếu nhãn (SEC-84) rồi ghi vào bảng của PH-13. DDL ClickHouse thuộc PH-13; bảng dưới là **hợp đồng cột** PH-03 yêu cầu (FRS FR-03-050; ghi vào đề nghị đồng bộ). Không cột nào chứa thân bản tin, giá trị tiêu đề xác thực hay giá trị tham số truy vấn (BR-03-007).

| Cột | Kiểu ClickHouse | Nội dung |
|---|---|---|
| `ts` | `DateTime64(3, 'UTC')` | Thời điểm nhận lượt gọi |
| `tenant` | `LowCardinality(String)` | Mã tenant; điều kiện lọc bắt buộc ở mọi truy vấn (BR-03-028) |
| `trace_id`, `span_id` | `FixedString(32)`, `FixedString(16)` | Định danh truy vết (FR-03-032) |
| `route_code`, `api_version`, `consumer_code` | `LowCardinality(String)` | Khớp `route.route_code`, `route.api_version`, `consumer.consumer_code` |
| `method`, `path_template`, `query_names` | `LowCardinality(String)`, `String`, `Array(String)` | Mẫu đường dẫn của route (không phải đường dẫn thật) và tên tham số, không giá trị |
| `status`, `error_code` | `UInt16`, `LowCardinality(String)` | Mã HTTP; `ERR-03-1xx` khi gateway từ chối |
| `latency_ms`, `upstream_ms`, `bytes_in`, `bytes_out` | `UInt32`, `UInt32`, `UInt64`, `UInt64` | Độ trễ và kích thước |
| `src_ip` | `IPv6` | Chỉ người có `PERM-03-log-read` thấy (Q03-48 của UC về che octet cuối) |
| `auth_result`, `limit_result`, `waf_result`, `opa_result` | `LowCardinality(String)` | Kết quả từng chốt |
| `synthetic` | `UInt8` | **Đề xuất thêm**: 1 với lượt kiểm tra tổng hợp để loại khỏi báo cáo (BR-03-027) |

: Hợp đồng cột nhật ký lượt gọi ở ClickHouse

Đề xuất bố trí: `ENGINE = MergeTree`, `PARTITION BY toYYYYMM(ts)`, `ORDER BY (tenant, ts, route_code)`, `TTL ts + INTERVAL 12 MONTH`. Cỡ (giả định): 5 triệu bản ghi mỗi ngày mỗi tenant ở mức cao điểm theo NFR-03-022; nếu mỗi dòng nén còn khoảng 60 byte (cơ sở: dòng thô khoảng 600 byte, cột lặp nén tốt) thì mỗi tenant khoảng 110 GB mỗi năm; truy vấn theo thời gian và HTTT đạt p95 ≤ 3 giây (NFR-03-022).

### 6.6. Mimir

Trạng thái nút và đồng bộ không lưu ở PostgreSQL: `NodeStateEvaluator` truy vấn Mimir mỗi 30 giây lấy `dh_gateway_config_version` và `dh_gateway_sync_total{result}` của từng pod, so với phiên bản `PUBLISHED` mới nhất của site rồi **cập nhật cột `state` của `config_snapshot`** (`APPLIED`, `PARTIAL`) và phản hồi `syncState` cho saga của PH-01. Mimir không trả lời thì màn hình hiển thị "không có số liệu" (ERR-03-026), không ghi trạng thái. Chỉ số `dh_gateway_source_stale_seconds{source}` phản ánh cột `source_cursor.stale_since`.

## 7. Sao lưu, khôi phục, mã hóa và lưu giữ

### 7.1. Lưu giữ

| Đối tượng | Lưu giữ | Cơ chế dọn |
|---|---|---|
| Schema `ph03_gateway` | Sao lưu theo `pg-core`: WAL liên tục và base backup hằng ngày lên Ceph RGW, RPO 5 phút (D03-09) | |
| `route`, `consumer`, `edge_host`, `config_snapshot`, `waf_exception`, `waf_virtual_patch`, `waf_mode`, `change_request`, `emergency_block`, `tenant_redirect`, `tls_exception`, `rate_limit_override`, `ip_block`, `tenant_hold`, `tenant_param`, `source_cursor` | Vĩnh viễn (xóa mềm); là chứng cứ kiểm toán và bảo đảm mã không dùng lại (BR-03-029) | Không dọn |
| `route_state_event` | Vĩnh viễn, khối lượng nhỏ (giả định không quá 10 sự kiện mỗi route mỗi năm); bản kiểm toán đầy đủ WORM 5 năm ở PH-13 (NFR-00-027) | Không dọn (chỉ thêm) |
| `consumer_credential` | Vĩnh viễn trong vòng đời consumer | Thay dòng khi xoay |
| `plan_policy`, `subscription_ref` | Theo nguồn ở PH-02; dòng `RETIRED`, `EXPIRED`, `REVOKED` giữ 12 tháng | `ConsumerPlanPurgeJob` hằng đêm |
| `snapshot_violation` | 12 tháng | `SnapshotRetentionJob` hằng đêm; ảnh chụp giữ nguyên |
| `legacy_import_job` | 12 tháng (không giữ nội dung gói, chỉ băm và báo cáo) | `ImportJobRetentionJob` |
| `revoked_token` | Đến khi token hết hạn cộng 60 giây | `RevokedTokenPurgeJob` mỗi phút |
| `idempotency_key` | 24 giờ (tối đa 48 giờ bằng `CHECK`) | Tác vụ dọn hằng giờ |
| `outbox` | 3 ngày | Sau khi Debezium đã gửi |
| Nội dung ảnh chụp | Bucket 50 phiên bản gần nhất (`gw.snapshot.retain`); Git vĩnh viễn | Dọn bucket sau mỗi lần phát |
| Siêu dữ liệu lượt gọi | 12 tháng trực tuyến ở ClickHouse | TTL của bảng (NFR-03-022, NFR-03-026) |
| Nhật ký WAF, xác thực (an ninh) | 12 tháng | PH-13 |
| Nhật ký vận hành | 90 ngày | PH-13 |
| Kiểm toán thao tác cấu hình | 12 tháng trực tuyến, WORM 5 năm | PH-13 qua `outbox` (NFR-00-027) |
| Khóa Valkey | Không sao lưu bắt buộc; dựng lại từ PostgreSQL (mục 6.1) | TTL |
| OpenBao | Snapshot Raft hằng giờ, mã hóa, sang site DR (D03-09) | Khóa ký xoay 12 tháng, giữ phiên bản cũ để xác minh |

: Lưu giữ

Các tác vụ dọn là tác vụ ShedLock của `dh-connect` (bảng `shedlock`), lặp từng tenant và chạy dưới `dh_connect_app`; không bảng nào của PH-03 phân vùng theo thời gian vì khối lượng nhỏ (mục 7.2), khác `health_sample` hay `db_access_record` của PH-05.

### 7.2. Dung lượng ước tính

Số liệu dưới đây là **giả định** để định cỡ `pg-core`; cơ sở là hồ sơ "tỉnh vừa" (GĐ-07: 200 HTTT, 1.000 route mỗi tenant) và hồ sơ `QM-CHUNG` (34 tenant, NFR-03-017), đo lại ở kiểm thử tải.

| Bảng | Tỉnh vừa (một tenant) | `QM-CHUNG` (34 tenant) | Cơ sở |
|---|---|---|---|
| `route`, `upstream`, `upstream_node` | 1.000 + 300 + 600 dòng | 70.000 route toàn nền tảng | NFR-03-017 |
| `consumer`, `consumer_credential` | 300 + 400 dòng | 10.000 + 14.000 dòng | 200 HTTT, 1,5 consumer mỗi HTTT |
| `subscription_ref` | 1.800 dòng | 61.000 dòng | 6 đăng ký mỗi consumer |
| `config_snapshot` | 7.300 dòng mỗi năm (20 lần tổng hợp thực sự mỗi ngày) | 250.000 dòng mỗi năm | Gom sự kiện 3 giây, bỏ lần không đổi băm |
| `waf_exception` | Dưới 100 dòng mỗi năm | Dưới 4.000 dòng mỗi năm | Ngoại lệ có bốn mắt, hiếm |
| Tổng cỡ schema | Dưới 100 MiB | Dưới 5 GiB sau 3 năm | Mỗi dòng trung bình 1 KiB kể cả chỉ mục |

: Dung lượng ước tính (giả định)

### 7.3. Mã hóa

Dữ liệu ở trạng thái nghỉ được mã hóa ở lớp đĩa của `pg-core` và của bản sao lưu trên Ceph RGW (D03-09); trên đường truyền, `dh-connect` kết nối PostgreSQL bằng TLS trong mạng dịch vụ. Schema không chứa bí mật nên không cần mã hóa cột; thay vào đó dữ liệu nhạy cảm được **không lưu**: khóa riêng ở OpenBao, token không lưu (chỉ `jti`, `sub`), khóa API chỉ lưu băm. Hai cột có nội dung cần hạn chế người đọc là `waf_virtual_patch.rule_text` (lộ chi tiết lỗ hổng chưa vá) và `idempotency_key.response_body`; vai trò `ph03_readonly` bị thu hồi quyền đọc hai cột này (mục 1.1). `created_by` và `requested_by` là mã tài khoản, không phải dữ liệu cá nhân của người dân (CMP-LAW-05).

### 7.4. Khôi phục

Thứ tự khôi phục sau sự cố nặng: (1) OpenBao, (2) PostgreSQL `pg-core`, (3) Valkey tự dựng lại, (4) tổng hợp lại ảnh chụp cho mọi tenant. Trong lúc đó các nút APISIX vẫn phục vụ bằng ảnh chụp đang chạy (NFR-03-007), nên khôi phục không làm gián đoạn lượt gọi. Ba điểm cần chú ý:

1. **PostgreSQL khôi phục về thời điểm cũ hơn bucket.** `snapshot_counter.last_issued` có thể thấp hơn số phiên bản các nút đang chạy; nút từ chối phiên bản không lớn hơn bản đang chạy (BR-03-018) nên ảnh chụp mới sẽ bị bỏ. Quy trình DR đặt lại bộ đếm bằng **số lớn nhất trong con trỏ `snapshots/{site}/current` và trong các nút, cộng `gw.snapshot.drGap` (1.000)** trước khi cho phép tổng hợp; trigger `tg_counter_monotonic` chỉ cho tăng nên thao tác này là cập nhật tăng, hợp lệ.
2. **OpenBao khôi phục cũ hơn PostgreSQL.** `config_snapshot.signature_key_id` có thể trỏ phiên bản khóa chưa tồn tại; ảnh chụp cũ vẫn xác minh được vì khóa công khai của mọi phiên bản còn hiệu lực nằm ở ConfigMap của nút, còn ảnh chụp mới được ký bằng phiên bản khóa hiện có. Sổ tay DR ghi khôi phục OpenBao trước, CSDL sau (như PH-05).
3. **Valkey mất sau khi PostgreSQL khôi phục.** `ValkeyRebuilder` nạp lại khóa chặn từ `revoked_token` và `emergency_block`; thu hồi token ghi sau thời điểm khôi phục bị mất, nhưng token chỉ sống tối đa 5 phút (SEC-25) nên cửa sổ rủi ro không quá 5 phút; tạm ngừng khẩn cấp ghi sau thời điểm khôi phục phải được vận hành viên khai lại (nhật ký kiểm toán ở PH-13 cho biết đã mất lệnh nào).

## 8. Ánh xạ dữ liệu hệ cũ sang thiết kế mới

Hệ cũ không có bảng PostgreSQL nào cho cổng API: gateway hiện tại cấu hình bằng tệp (`deploy/apisix/apisix.yaml`, `ApisixRouteWriter` ghi `deploy/apisix/routes/*.yaml`), còn khối APIM của hệ cũ có mô hình tương tự Gravitee với kho dữ liệu riêng của sản phẩm (D00-03 §4.4). Do đó di trú là **nhập có duyệt** (FR-03-059) chứ không chép bảng, và mục này gồm bốn phần: khái niệm APIM cũ, bảng thiết kế cũ của repo (SRS cũ §M4), mã hiện tại, đối soát. Chiến lược chung là chạy song song, thay dần (strangler).

### 8.1. Khối APIM của hệ cũ

Lược đồ chi tiết của APIM cũ chưa có trong tài liệu được cung cấp (giả định: cấu hình ở kho riêng của sản phẩm, không ở PostgreSQL của Datahub; Q03-50). Bảng dưới ánh xạ khái niệm, theo D00-03 phần A.

| Khái niệm hệ cũ | Đích ở PH-03 | Cách chuyển |
|---|---|---|
| API: tên, phiên bản, context-path, URL backend (LGC-APIM-002; 018) | PH-02 `api`; PH-03 `route`, `upstream`, `upstream_node` | `LegacyGatewayImporter` đề xuất cấu hình nháp; route sinh lại từ API đã công bố ở PH-02, không chép |
| Start, Stop API (LGC-APIM-005) | `route.state`: `ACTIVE`, `STOPPED` | "Stop" thành `STOPPED` kèm lý do mặc định "Nhập từ hệ cũ" |
| Plan bước Secure: Keyless, API key (LGC-APIM-011) | `plan_policy.security_mode` | `KEYLESS` giữ nhưng CHK-06 chỉ cho API dữ liệu mở; khóa API cũ **không chuyển**, HTTT xin credential mới (OAuth 2.1 hoặc mTLS) |
| Plan bước Restriction: rate limit giây, phút (LGC-APIM-012) | `plan_policy.rate_limits` | Giữ nguyên giá trị |
| Plan bước Restriction: quota giờ, ngày, tháng (LGC-APIM-013) | `plan_policy.quotas` | Giữ nguyên giá trị |
| Plan: whitelist, blacklist đường dẫn (LGC-APIM-014) | `plan_policy.path_allow`, `path_deny` | Giữ nguyên; đường dẫn chuẩn hóa theo FR-03-020 |
| Plan bước Policies (LGC-APIM-015) | `policy_template_setting` | Chỉ ánh xạ policy trùng mẫu được duyệt; policy tự do vào `legacy_import_job.findings` |
| Application, Client ID (LGC-APIM-019; 020) | `consumer`, `consumer_credential` | PH-01 và PH-12 tạo client mới; consumer lấy `clientId` mới; bí mật cũ không chuyển |
| Subscription | `subscription_ref` | Tạo từ đăng ký của PH-02 sau khi nhập |
| Danh sách gateway (LGC-APIM-023) | Không bảng (Mimir) | Thay bằng trạng thái nút suy ra |
| Log request (LGC-APIM-022) | ClickHouse (mục 6.5) | Nhật ký cũ không chuyển; hệ cũ giữ nhật ký tới khi tắt |
| Audit (LGC-APIM-027) | `outbox` tới PH-13 | Không chuyển lịch sử |
| Bảo mật route: Basic, SSL, WS-Security (LGC-BUS-041) | `route.require_mtls`, `plan_policy.security_mode`, `edge_certificate`, `client_ca` | Phần bảo mật ra HTTT ở PH-05, phần mã hóa trường ở PH-04, PH-12 |

: Khái niệm APIM cũ sang bảng mới

### 8.2. Mô hình dữ liệu trong SRS cũ của repo (§M4)

SRS cũ (`docs/07-srs/SRS-PH-03-gateway.md` §M4) mô tả 10 thực thể chưa có DDL. Bảng dưới ghi mỗi thực thể và cột cũ sang đích mới, kể cả chuyển đổi kiểu và những gì **không** chuyển.

| Thực thể, cột cũ | Đích | Chuyển đổi |
|---|---|---|
| `GW_ROUTE.route_id` (UUID), `route_code` (VARCHAR(80)) | `route.id`, `route.route_code` (varchar(127), mẫu `^…\.v[0-9]+$`) | Mã mới có đuôi phiên bản; mã cũ không có đuôi thì thêm `.v1` |
| `duong_dan` (VARCHAR(300)), `phuong_thuc` (VARCHAR(60) danh sách) | `path_pattern` (varchar(512)), `methods` (`varchar(7)[]`) | Chuỗi phương thức tách thành mảng, kiểm theo danh sách HTTP |
| `do_uu_tien` (SMALLINT), `bat_buoc_mtls`, `pham_vi_yeu_cau` (JSONB) | `priority` (integer 0…1000), `require_mtls`, `required_scopes` (`varchar(64)[]`) | JSONB thành mảng |
| `timeout_ms` (INTEGER ≤ 30000) | `upstream.connect_timeout_ms`, `read_timeout_ms` | Chuyển từ route sang upstream, vẫn trần 30.000 ms |
| `max_body_bytes` (BIGINT, mặc định 10 MiB) | `route.body_max_bytes` (integer, mặc định 1 MiB) | Mặc định đổi theo `gw.body.maxBytes`; giá trị riêng giữ, tối đa 10 MiB |
| `trang_thai` ∈ {`ACTIVE`, `DISABLED`} | `route.state` | `DISABLED` thành `STOPPED`; thêm `PENDING`, `SUSPENDED`, `SUNSET`, `RETIRED` |
| `GW_UPSTREAM` (thuật toán cân bằng, health check, ngưỡng) | `upstream` (`balancer`, `health_check`, `breaker`) | Cột đơn thành `jsonb` có cấu trúc; thêm `scheme`, `tls_verify`, `retries` |
| `UPSTREAM_NODE` (host, port, trọng số) | `upstream_node` | `trang_thai_suc_khoe`, `kiem_tra_cuoi` **không lưu**: là trạng thái chạy của nút |
| `GW_PLUGIN` (tên plugin, thứ tự, cấu hình, bật) | Không bảng | Chuỗi plugin do `PluginChainComposer` dựng từ bản phát hành; không có đường nhập plugin của tenant (BR-03-017) |
| `RATE_LIMIT_POLICY` (phạm vi `CONSUMER`, `CONSUMER_ROUTE`, `GLOBAL`, `IP`; `gioi_han`, `cua_so_giay`, `burst_cho_phep`) | `rate_limit_override` (`CONSUMER`, `CONSUMER_ROUTE`, `ROUTE`, `TENANT`; `limit_value`, `window_seconds`, `burst_percent`) | `GLOBAL` thành `TENANT`; `IP` thành tham số `gw.ip.*` (không bảng); burst từ số tuyệt đối sang phần trăm |
| `CONSUMER` (`client_id`, `ten_he_thong`, `nhom_uu_tien`, `mien_tru_gioi_han_ip`, `trang_thai` ∈ {`ACTIVE`, `SUSPENDED`, `BLOCKED`}) | `consumer` (`consumer_code`, `system_code`, `priority_group`, `trusted_source` + `trusted_approved_by`, `state`) | `ten_he_thong` bỏ (lấy từ PH-01 qua `system_code`); `BLOCKED` thành `SUSPENDED`; miễn giới hạn IP nay cần người duyệt |
| `CONSUMER_QUOTA` (`han_ngach`, `da_dung`, `dat_lai_luc`) | `plan_policy.quotas` (giới hạn); `da_dung` ở Valkey `{T}:q:…` | Bộ đếm không lưu PostgreSQL (mục 6.1) |
| `WAF_EXCEPTION` (`ma_luat`, `ly_do`, `nguoi_duyet`, `het_han`) | `waf_exception` (`rule_id`, `reason`, `requested_by`, `approved_by`, `expires_at`, `state`) | Thêm người đề nghị và máy trạng thái; hạn ≤ 90 ngày kiểm bằng `CHECK` |
| `SSL_CERT` (`ten_mien`, `chung_thu` text, `vault_key_ref`, hiệu lực, hết hạn) | `edge_certificate` (`subject`, `hosts`, `fingerprint`, `not_before`, `not_after`, `secret_ref`) | **Không lưu chứng thư dạng văn bản** (nằm ở Secret do cert-manager hoặc External Secrets quản lý); chỉ siêu dữ liệu và đường dẫn |
| `REVOKED_TOKEN` (`jti`, `subject`, `thu_hoi_luc`, `token_het_han`, `ly_do`) | `revoked_token` (`kind`, `jti`, `sub`, `not_before`, `token_expires_at`, `reason`) | Thêm thu hồi theo `sub` kèm `not_before` |

: Thực thể SRS cũ sang bảng mới

### 8.3. Mã hiện tại của repo

| Hiện trạng | Đích | Cách chuyển |
|---|---|---|
| `ApisixRouteWriter` ghi từng route ra `deploy/apisix/routes/*.yaml` | Module `gateway` của `dh-connect`: `SnapshotAssembler` (GAP-03-04) | Không có bảng để di trú; route ghi qua PH-02 rồi tổng hợp |
| `deploy/apisix/apisix.yaml` viết tay (route demo, CORS `*`, `limit-count` 100/60 giây, `client_secret` trong tệp) | Ảnh chụp do `dh-sync` ghi | Xóa route demo và bí mật khỏi cấu hình (GAP-03-03); không nhập |
| Bảng `ph04.route` (W2) | Giữ nguyên, thuộc PH-04 | Không dùng chung (GAP-03-07) |

: Mã hiện tại của repo

Không có changeset di trú kiểu `migrate-w1` như PH-05 vì không có bảng W1 hay W2 của PH-03 để đổi tên.

### 8.4. Đối soát sau di trú

`LegacyImportReport` (đọc từ `legacy_import_job.summary` và `findings`) liệt kê: số API, plan, application, subscription tìm thấy; số đã ánh xạ thành `plan_policy`, `consumer`, `subscription_ref`; mục chưa ánh xạ (policy tự do, khóa API cũ, Basic Auth); consumer chưa có thông tin xác thực công khai; route còn `PENDING` chưa có ảnh chụp. Trước khi cắt chuyển từng API khỏi hệ cũ, so sánh số lượt gọi bảy ngày giữa hệ cũ và `access_log` của hệ mới theo `route_code`, chênh lệch quá 1% thì chưa cắt (giả định, cơ sở: dung sai lấy mẫu); đây là điều kiện nghiệm thu cùng tiêu chí 10 của FRS mục 14.

## 9. Câu hỏi mở

> **Câu hỏi mở Q03-50:** Lược đồ và kho dữ liệu thật của khối APIM cũ (Gravitee hay tương tự) chưa có, nên mục 8.1 chỉ ánh xạ khái niệm. Cần bản xuất cấu hình của ít nhất một tỉnh để xác nhận định dạng gói xuất mà `LegacyGatewayImporter` đọc (FR-03-059, Q03-49 của UC), và để biết hệ cũ lưu khóa API dạng băm hay dạng rõ. Đề xuất tạm: coi mọi khóa API cũ là dạng rõ, không nhập, HTTT xin credential mới.

> **Câu hỏi mở Q03-51:** Bản này thêm hai cặp chuyển trạng thái so với FRS để tránh trạng thái kẹt: `ROUTE PENDING → RETIRED` (API bị gỡ trước khi có ảnh chụp) và `SNAPSHOT PUBLISHED → SUPERSEDED` (bản mới hơn được phát khi chưa nút nào báo). Cần xác nhận hoặc bác bỏ, và nếu bác bỏ thì nói cách xử lý ảnh chụp kẹt `PUBLISHED`. Đề xuất: chấp nhận cả hai và cập nhật FRS §4.3, §4.5.

> **Câu hỏi mở Q03-52:** Schema cho phép tenant `COMMON` ở `route`, `upstream`, `edge_host` và các bảng liên quan để lưu route nền tảng (cổng nhà phát triển, callback dùng chung của PH-19). Cần xác nhận route nền tảng có thuộc PH-03 hay chỉ do PH-15, PH-19 khai bằng tenant riêng, và ai có phiên `PLATFORM` được ghi chúng. Đề xuất: giữ cho phép `COMMON`, chỉ PA có phiên `PLATFORM`, không cho phép ghi đè hạn mức tenant lên route `COMMON`.

> **Câu hỏi mở Q03-53:** Hai khóa duy nhất toàn cục có hệ quả cần quyết. (1) `uq_edge_host_pattern`: lỗi trùng lộ sự tồn tại của host thuộc tenant khác, trái tinh thần BR-03-028; có cấp sẵn không gian tên host theo tenant (`{tenant}.api.datahub.gov.vn`, `{tenant}.datahub.gov.vn`) ở PH-20 để mọi host thêm vào đều dưới tiền tố của tenant, khi đó trùng chỉ xảy ra trong nội bộ tenant. Đề xuất: có; thêm `CHECK` kiểm tiền tố host theo `tenant_id` khi D03-10 §5.2 chốt quy ước đặt tên, và ánh xạ lỗi trùng sang `ERR-03-002` với thân chung. (2) `uq_consumer_credential_thumb`: chặn một HTTT cấp quốc gia (ví dụ NDXP) dùng cùng một chứng thư để gọi vào nhiều tenant; muốn cho phép thì khóa phải là `(tenant_id, cert_thumbprint)` và gateway xác định tenant từ host hoặc token trước khi tra vân tay (FR-03-013). Đề xuất: giữ toàn cục ở MVP vì tenant của lượt gọi chỉ lấy từ token (BR-03-002), HTTT quốc gia xin chứng thư riêng cho từng tenant; xem lại ở Đợt 2 nếu có nhu cầu thật.

> **Câu hỏi mở Q03-54:** Giá trị `AUTO` của `ip_block.source` (EN-03-14 ở FRS) chưa có đường ghi: chặn tự động chạy cục bộ trong pod (`dh-ip-block`, không dùng Valkey) và nút không gọi về control plane. Ai ghi dòng `AUTO`. Đề xuất: MVP chỉ dùng `MANUAL` và hiển thị chặn tự động từ nhật ký, giữ giá trị `AUTO` trong `CHECK` cho tương lai khi `SecurityAlertService` ghi từ EVT-03-09.

## Đề nghị đồng bộ

Tập này không sửa tài liệu dùng chung; các việc dưới đây để đợt đồng bộ cuối thực hiện (hoặc các luồng phân hệ khác tiếp nhận).

| Tài liệu | Đề nghị |
|---|---|
| D02-03-PH03 §4.2, §4.3, §4.5 (FRS) | Thêm EN-03-16 `edge_host`, EN-03-17 `subscription_ref`, EN-03-18 `policy_template_setting`, EN-03-19 `client_ca`, EN-03-20 `tls_exception`; ghi EN-03-10 (nút gateway) là thực thể suy ra, không có bảng; ghi `gw.waf.mode` lưu ở `waf_mode` và hạn mức toàn tenant lưu ở `rate_limit_override`; hai cặp chuyển trạng thái mở rộng (Q03-51); ba máy trạng thái thêm (`WAF_PATCH`, `TENANT_HOLD`, `IMPORT_JOB`); `ip_block.source = AUTO` (Q03-54) |
| D03-02-PH03 §4.7, §8.1 (SDD) | Đối chiếu tên bảng với chương 3; ghi 11 máy trạng thái lưu ở PostgreSQL thay vì 8; bảng `state_transition` và trigger `tg_state_guard` là nơi kiểm chuyển trạng thái; `tg_write_once` cho nội dung ảnh chụp đã ký |
| D03-10 §4, §5.2 | Ghi mẫu RLS P và S áp cho schema `ph03_gateway`, phiên `PLATFORM` cho dữ liệu `COMMON`; quy ước đặt tên host theo tenant (Q03-53); danh sách dữ liệu mặc định PH-03 tạo khi khởi tạo tenant (mục 5) |
| D03-09 | Cỡ `pg-core` thêm cho PH-03 (dưới 5 GiB sau 3 năm ở `QM-CHUNG`, giả định mục 7.2); cỡ ClickHouse cho nhật ký lượt gọi (khoảng 110 GB mỗi tenant mỗi năm ở mức cao điểm, giả định mục 6.5); quy trình DR đặt lại `snapshot_counter` cộng `gw.snapshot.drGap` (mục 7.4) |
| D03-03 của PH-13 (tập sau) | DDL ClickHouse cho bảng nhật ký lượt gọi theo hợp đồng cột mục 6.5, thêm cột `synthetic` (BR-03-027); TTL 12 tháng |
| D03-04-PH03 (API) | Trường API ↔ cột: `If-Match` ↔ `version`; `Idempotency-Key` ↔ `idempotency_key.idem_key`; lỗi `unique_violation` của `uq_edge_host_pattern` ánh xạ về `ERR-03-002` thân chung |
| D05-02-PH03 (test) | Dùng 40 nhóm ca của `ph03_isolation_test.sql` làm bộ ca nền cho `TenantIsolationIT`, nhóm cô lập chéo tenant và tách nhiệm (SEC-87) |
| `build/tools`, `csdl/ph07/tools/gen_liquibase.py` | Tham số hóa tên phân hệ (hiện gắn cứng `ph07`) để sinh `liquibase/` cho `ph03_gateway`; công cụ `them_dac_ta_bang.py` của PH-03 chép từ PH-19 nên cân nhắc gộp thành một công cụ dùng chung có tham số |
| D00-04 §3.2 | Chạy lại `kiem_tra_ma.py --cap-nhat-so-tra-cuu` sau khi hợp nhất: câu hỏi mở Q03-50…54 |

: Đề nghị đồng bộ của tập CSDL PH-03

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu theo khuôn K-CSDL và quy chuẩn K-TRINH-BAY: schema `ph03_gateway` 35 bảng (32 RLS), 11 máy trạng thái ở CSDL, ba ERD, đặc tả 10 mục cho từng bảng trích từ DDL, kho ngoài PostgreSQL, sao lưu và lưu giữ, ánh xạ hệ cũ; DDL chạy thử trên PostgreSQL 16.16 sạch, kiểm cô lập 80/80; 5 câu hỏi mở Q03-50…54 |
