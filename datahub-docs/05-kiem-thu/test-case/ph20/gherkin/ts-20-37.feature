# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-37
Tính năng: TS-20-37 · Cô lập tenant và rò rỉ chéo tenant theo nhóm API

  @TC-20-186 @P1 @Âm
  Kịch bản: TC-20-186 Rò rỉ chéo tenant nhóm API tỉnh: mọi đối tượng của T90 mà người dùng T91 gọi đều trả 404
    # Truy vết: SEC-87 · FR-20-066, 070 · API-20-135, 137, 139, 140, 141, 142, 143, 145, 151, 154, 157, 159, 161 · ERR-20-002 · NFR-20-019
    Biết `U-T91-TA`, `U-T90-TA`; `T90` có tổ chức `SO-KHCN`, lô nhập `importId-90`, đề xuất `proposalId-90`; F-LEAK.
    Khi `U-T91-TA` gọi từng API đọc theo mã của `T90`: `GET T/organizations/SO-KHCN`, `.../SO-KHCN/history`, `GET T/organization-imports/{importId-90}`, `GET T/organization-sync-proposals` (đối chiếu `proposalId-90`)
    Và gọi API ghi theo mã của `T90`: `PATCH T/organizations/SO-KHCN`, `POST .../SO-KHCN:dissolve`, `POST T/organization-imports/{importId-90}:confirm`, `POST .../{proposalId-90}:decide`
    Và gọi `GET T/settings`, `T/usage`, `T/quotas`, `T/cross-tenant-access-log`, `T/audit-events` đổi `tenantCode`, `X-Tenant-Id`, `tenantId` giả sang `T90`
    Và đối chiếu số dòng và kiểm tra nhật ký rò rỉ
    Thì bước 1, 2 `404` `ERR-20-002` cho mọi mã của `T90`, nội dung phản hồi không phân biệt "không có" và "của tenant khác". Bước 3 mọi API trả dữ liệu của `T91` (tenant ngữ cảnh lấy từ danh tính, bỏ qua tham số giả), không có dòng nào của `T90`. Bước 4 không có sự cố rò rỉ.

  @TC-20-187 @P1 @Âm
  Kịch bản: TC-20-187 Rò rỉ nhóm API nền tảng: người dùng tỉnh gọi API nền tảng, và chiều ngược lại
    # Truy vết: SEC-87 · FR-20-066 · API-20-001, 003, 004, 086, 109, 118, 129, 130, 131 · ERR-00-403 · ERR-20-002
    Biết `U-T90-TA`, `U-T90-VW`, `U-PA1`; `T91` `ACTIVE`; kế hoạch sáp nhập T91→T90.
    Khi `U-T90-TA` `GET P/tenants`, `GET P/tenants/T91`, `GET P/merge-plans`, `GET P/releases`, `GET P/dashboard`
    Và `U-T90-TA` `PATCH P/tenants/T91` và `POST P/tenants/T91/lifecycle-requests`
    Và `U-PA1` `GET T/organizations` (không có ngữ cảnh tenant)
    Thì bước 1, 2 `403` `ERR-00-403` (người dùng tỉnh không thuộc tenant `PLATFORM`; quyết định 0.2: nhóm `/api/platform/v1` trả `403` vì đường dẫn nền tảng không phải tài nguyên của một tỉnh, không có gì để che; tài nguyên của tenant khác ở `/api/tenant/v1` và `/internal/tenant/v1` trả `404`, xem TC-20-186, 188). Bước 3 `403` `ERR-00-403` do token `PLATFORM` không có ngữ cảnh tenant, không trả dữ liệu của tenant nào. Không bản ghi nào bị đổi.

  @TC-20-188 @P1 @Âm
  Kịch bản: TC-20-188 Rò rỉ nhóm API nội bộ: sai scope, sai bên báo, tenant không thuộc ngữ cảnh
    # Truy vết: SEC-87 · FR-20-065, 057 · API-20-162, 163, 164, 165, 166, 167, 168, 169, 170, 171 · ERR-20-104, ERR-20-002
    Biết `S-PH03` (`tenant:registry-read`), `S-PH01` (`tenant:org-read`), `S-PH10` (`tenant:provision-report`), `S-NOSCOPE`; kế hoạch, lần chạy `T93`.
    Khi `S-PH01` gọi `GET I/tenants`, `GET I/tenants/T93/enforcement`
    Và `S-PH03` gọi `GET I/organizations`, `POST I/organizations:lookup`
    Và `S-PH10` báo bước của phân hệ khác (bước `S09_GATEWAY` là của PH-03)
    Và `S-NOSCOPE` gọi mọi API nội bộ
    Và `S-PH01` `GET I/organizations/KHONG-CO` với ngữ cảnh `T93`; với mã của `T90` khi ngữ cảnh `T91`
    Thì bước 1, 2 `403` `ERR-20-104` ("Tài khoản dịch vụ không có quyền tenant:registry-read."). Bước 3 `403` `ERR-20-104` (không phải bên thực hiện của bước). Bước 4 `403` `ERR-20-104`. Bước 5 `404` `ERR-20-002`, không lộ tổ chức của tenant khác.

  @TC-20-189 @P1 @Âm
  Kịch bản: TC-20-189 RLS PostgreSQL: vai ứng dụng chỉ thấy dòng của tenant mình, không ghi bảng tenant
    # Truy vết: SEC-87 · NFR-20-024 · FR-20-066 · BR-20-009
    Biết postgreSQL thật; DDL `ph20_tenant`; tenant `T90`, `T91`, `T92`; vai `dh_platform_app`, `dh_platform_ctl`, `dh_report_ro`; tệp `ph20_isolation_test.sql`.
    Khi chạy `psql -v ON_ERROR_STOP=1 -f ph20_isolation_test.sql` trên CSDL rỗng sau DDL
    Và với phiên đặt biến `app.tenant_id = T90`, truy vấn mọi bảng có `tenant_id`; ghi dòng `tenant_id = T91`
    Và với phiên không đặt biến `app.tenant_id`, đọc bảng tenant; chạy khối "thiếu biến phiên"
    Và với phiên `PLATFORM` (vai nền tảng), đọc tổ chức mọi tenant; thử ghi nhóm bảng tự quản của tỉnh
    Và kiểm vai không có `BYPASSRLS`, `SUPERUSER`; bảng không thuộc sở hữu vai ứng dụng; bảng điều khiển bốn mắt, duy nhất có điều kiện, máy trạng thái, bất biến, phân vùng
    Thì bước 1 tệp chạy hết 14 khối, mọi ca ghi PASS, tổng kiểm cuối đạt. Bước 2 chỉ thấy dòng `T90`; ghi `T91` bị chặn. Bước 3 trả 0 dòng, không lỗi lộ dữ liệu. Bước 4 đọc được, ghi bị chặn. Bước 5 không vai nào vượt RLS; ràng buộc nghiệp vụ chặn đúng.

  @TC-20-190 @P1 @Âm
  Kịch bản: TC-20-190 ACL Kafka theo tiền tố: principal tenant không đọc, ghi được topic tenant khác
    # Truy vết: SEC-87 · FR-20-065 · EVT-20-13 · EVT-20-04 · UC-20-35
    Biết kafka thật; `T90`, `T91`; principal nội bộ `T90` theo ACL tiền tố `t90.`; topic `t91.tenant.org.changed.v1`, `platform.tenant.status-changed.v1`.
    Khi principal `T90` đọc topic `t91.tenant.org.changed.v1`
    Và principal `T90` ghi vào `t91.tenant.org.changed.v1`
    Và principal `T90` đọc `platform.tenant.status-changed.v1`
    Và PH-20 tạo tổ chức ở `T90`, kiểm EVT-20-13 ở topic `t90.`
    Thì bước 1, 2 bị từ chối (ACL). Bước 3 bị từ chối (topic nền tảng chỉ cho phân hệ đăng ký). Bước 4 sự kiện chỉ ở topic `t90.`, `tenantCode = T90`, không ở topic tenant khác.

  @TC-20-191 @P1 @Âm
  Kịch bản: TC-20-191 Giả mạo ngữ cảnh tenant: header, token, tham số bị bỏ qua
    # Truy vết: SEC-87 · FR-20-066 · API-20-135, 143 · ERR-20-002
    Biết `U-T91-TA`; token realm `T91`; mesh giả lập.
    Khi gọi `GET T/organizations` với `X-Tenant-Id: T90`
    Và gọi với token realm `T91` nhưng path chứa mã của `T90`
    Và gọi với `tenantId=T90` ở query và body
    Và gọi với token realm đã hết hạn, và token ký sai
    Thì bước 1, 3 trả dữ liệu `T91` (tham số, header bị bỏ qua). Bước 2 `404` `ERR-20-002`. Bước 4 `401` `ERR-00-401`. Không dòng nào của `T90`.

  @TC-20-192 @P2 @Dương @Hiệu @năng
  Kịch bản: TC-20-192 Kiểm thử rò rỉ hằng đêm phủ 100 % API công bố trong 60 phút
    # Truy vết: SEC-87 · FR-20-070 · API-20-132, 134 · NFR-20-019
    Biết PERF; `T90`, `T91` kiểm thử; danh mục 171 API (F-LEAK).
    Khi chạy `POST P/leak-tests` `ALL` và đo thời gian
    Và đếm API có kết quả `PASSED`, `SKIPPED`, `LEAKED`
    Thì hoàn tất ≤ 60 phút; mỗi API công bố có kết quả (phủ 100 %); `LEAKED = 0`; ca `SKIPPED` có lý do.

  @TC-20-193 @P1 @Âm
  Kịch bản: TC-20-193 Ghi vào tenant MERGED, SUSPENDED, DECOMMISSIONED ở data plane và control plane
    # Truy vết: FR-20-066 · BR-20-021 · ERR-20-001, ERR-20-101, ERR-20-102, ERR-20-103, ERR-20-115, ERR-20-118 · NFR-20-004
    Biết `T90` `ACTIVE`; `T92` `SUSPENDED`; `T88` `DECOMMISSIONED`; `T91` `MERGED`; `T94` `PROVISIONING`; `T90` tắt PH-19; `T96` `ACTIVE` đang nâng cấp.
    Khi gọi ghi data plane theo từng tenant, qua `S-PH03` đọc API-20-164
    Và gọi đọc data plane của `T92`, `T91`
    Và gọi phân hệ bị tắt của `T90`
    Và ghi ở `T96` đang bảo trì nâng cấp
    Thì bước 1 `T92` `403` `ERR-20-001`; `T88` `410` `ERR-20-102`; `T91` `409` `ERR-20-115`; `T94` `503` `ERR-20-101`. Bước 2 đọc `200` cho `T92`, `T91`. Bước 3 `503` `ERR-20-103`. Bước 4 `503` `ERR-20-118`.
