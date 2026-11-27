# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-19
Tính năng: TS-20-19 · Phân hệ đọc registry, tổ chức và thực thi trạng thái tenant

  @TC-20-085 @P1 @Dương
  Kịch bản: TC-20-085 Phân hệ đọc registry, bản ghi tenant và cấu hình thực thi
    # Truy vết: FR-20-065 · UC-20-19 · API-20-162, 163, 164 · NFR-20-003 · BR-20-036 · `tenant:registry-read`
    Biết `S-PH03`, `S-PH12`, `S-PH10`; `T90…T99` có trạng thái khác nhau.
    Khi `S-PH03` gọi `GET I/tenants?status=ACTIVE`
    Và `S-PH12` gọi `GET I/tenants?module=PH-16&updatedSince=2026-11-01T00:00:00+07:00`
    Và `S-PH03` gọi `GET I/tenants/T90` và `GET I/tenants/T90/enforcement`
    Và đổi trạng thái `T92` rồi gọi lại bước 1
    Thì bước 1 chỉ tenant `ACTIVE`. Bước 2 lọc đúng phân hệ và thời điểm. Bước 3 `enforcement` có `hosts`, `apiPrefix`, `quotas[]`, `redirects[]`, `configVersion`, `essentialApisAllowed`. Bước 4 EVT-20-04 vô hiệu đệm, kết quả mới trong ≤ `20.registry.cache-seconds`. Không có dữ liệu cá nhân trong bản ghi.

  @TC-20-086 @P1 @Âm @Bảo @mật
  Kịch bản: TC-20-086 Registry với scope sai, token người dùng, tenant không có
    # Truy vết: FR-20-065 · API-20-162, 163, 164, 165 · ERR-20-002, ERR-20-004, ERR-20-104, ERR-00-401
    Biết `S-NOSCOPE`, `S-PH01` (chỉ `tenant:org-read`); `U-PA1` (người dùng).
    Khi `S-NOSCOPE` gọi `GET I/tenants`
    Và `S-PH01` gọi `GET I/tenants/T90/enforcement`
    Và `U-PA1` gọi `GET I/tenants`
    Và `S-PH03` gọi `GET I/tenants/T89`
    Và `S-PH03` gọi `GET I/tenants?status=XYZ`
    Và gọi không có chứng chỉ mTLS hoặc token
    Thì bước 1, 2 `403` `ERR-20-104`. Bước 3 `403` `ERR-20-104` (token người dùng không đi cổng nội bộ). Bước 4 `404` `ERR-20-002`. Bước 5 `400` `ERR-20-004`. Bước 6 `401` `ERR-00-401`.

  @TC-20-087 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-20-087 Thực thi trạng thái tenant ở mặt phẳng dữ liệu theo từng trạng thái
    # Truy vết: FR-20-066 · UC-20-19 · API-20-142, 163 · BR-20-021, 026, 036 · ERR-20-001, ERR-20-101, ERR-20-102, ERR-20-103, ERR-20-115, ERR-20-118 · NFR-20-004
    Biết `gw-sim`, `mod-sim`; tenant theo trạng thái: `T92` `SUSPENDED`, `T97` `PROVISIONING`, `T94` `FAILED`, `T88` `DECOMMISSIONED`, `T91` `MERGED`, `T90` PH-17 `DISABLED`, `T90` đang bảo trì nâng cấp; `20.suspend.essential-api-allowed = false`.
    Khi gọi API dữ liệu bằng token từng tenant ở trên
    Và bật `20.suspend.essential-api-allowed = true`, gọi API thiết yếu chỉ đọc và API ghi của `T92`
    Và gọi `GET T/context` ở mọi tenant trên
    Thì `T92` `403` `ERR-20-001`; `T97`, `T94` `503` `ERR-20-101`; `T88` `410` `ERR-20-102`; `T91` đọc theo chuyển tiếp, ghi `409` `ERR-20-115`; PH-17 tắt `503` `ERR-20-103`; đang bảo trì ghi `503` `ERR-20-118`. Bước 2 API thiết yếu chỉ đọc `200`, API ghi vẫn `403` `ERR-20-001`. Bước 3 `context` luôn `200`. Mỗi từ chối có thân `problem+json` đúng câu thông báo FRS mục 9.2.

  @TC-20-088 @P1 @Dương
  Kịch bản: TC-20-088 Phân hệ đọc tổ chức: danh sách, một tổ chức, tra hàng loạt
    # Truy vết: FR-20-057, 058 · UC-20-19 · API-20-169, 170, 171 · NFR-20-013 · BR-20-028, 036 · `tenant:org-read`
    Biết `S-PH01`, `S-PH07`; `T90` có F-ORG, tổ chức `SO-CU` đã `DISSOLVED` (có `successorCode`), 5 tổ chức là chủ quản dữ liệu.
    Khi `S-PH01` gọi `GET I/organizations?status=ACTIVE&orgType=DEPARTMENT`
    Và `S-PH01` gọi `GET I/organizations?isDataOwner=true`
    Và `S-PH01` gọi `GET I/organizations?asOf=2025-06-30&updatedSince=2026-11-01T00:00:00+07:00`
    Và `S-PH07` gọi `GET I/organizations/SO-CU`
    Và `S-PH08` gọi `POST I/organizations:lookup` với 500 mã và `asOf`
    Thì bước 1 chỉ sở `ACTIVE`. Bước 2 đúng năm tổ chức chủ quản. Bước 3 trả tổ chức theo hiệu lực tại ngày `asOf`. Bước 4 `200` kể cả đã giải thể, có `status = DISSOLVED`, `successorCode`. Bước 5 trả đủ 500 mã (mã không có đánh dấu không tìm thấy). p95 ≤ 100 ms (NFR-20-013); tenant ngữ cảnh lấy từ token máy.

  @TC-20-089 @P2 @Âm
  Kịch bản: TC-20-089 Tra tổ chức: quá 500 mã, scope sai, tổ chức không có
    # Truy vết: FR-20-057 · API-20-169, 170, 171 · ERR-20-002, ERR-20-004, ERR-20-104
    Biết `S-PH01`, `S-NOSCOPE`, `S-PH03` (chỉ `tenant:registry-read`).
    Khi `POST I/organizations:lookup` với 501 mã
    Và `GET I/organizations/KHONG-CO`
    Và `S-NOSCOPE` và `S-PH03` gọi `GET I/organizations`
    Và `GET I/organizations?asOf=2026-13-45`
    Thì bước 1 `400` `ERR-20-004`. Bước 2 `404` `ERR-20-002`. Bước 3 `403` `ERR-20-104`. Bước 4 `400` `ERR-20-004`.
