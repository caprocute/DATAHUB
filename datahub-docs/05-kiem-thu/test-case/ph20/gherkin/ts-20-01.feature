# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-01
Tính năng: TS-20-01 · Tra cứu và xem chi tiết tenant toàn nền tảng

  @TC-20-001 @P1 @Dương
  Kịch bản: TC-20-001 Liệt kê, tìm, lọc, sắp xếp và xuất CSV danh sách tenant
    # Truy vết: FR-20-002, 060 · UC-20-01 · API-20-001 · UI-20-01 · `PERM-20-read`
    Biết `U-PA1`, `U-PO`, `U-PAU`; `T90…T99`, `PLATFORM`, `COMMON` đã có; `T90` kênh `STABLE`, phiên bản 2.3.1.
    Khi `GET P/tenants?page=0&size=20`
    Và `GET P/tenants?status=ACTIVE&isolationMode=SHARED&scaleProfile=QM-VUA`
    Và `GET P/tenants?q=T90`
    Và `GET P/tenants?channel=STABLE&currentVersion=2.3.1&testTenant=true&sort=tenantCode`
    Và `GET P/tenants?format=csv`
    Và lặp bước 1 bằng `U-PO` rồi `U-PAU`
    Thì bước 1 `200`, mỗi mục có `tenantCode`, `name`, `kind`, `status`, `isolationMode`, `scaleProfile`, `deploymentProfile`, `currentVersion`, `channel`, `testTenant`; `PLATFORM`, `COMMON` có `kind` tương ứng. Bước 2 chỉ tenant `ACTIVE` `SHARED` `QM-VUA`. Bước 3 trả `T90`. Bước 4 trả `T90` và các tenant cùng kênh, cùng phiên bản, theo thứ tự `tenantCode`. Bước 5 trả tệp CSV có dòng tiêu đề và đủ cột, không dữ liệu cá nhân. Bước 6 cả ba vai trò đều `200`. Không phát sự kiện; không có bản ghi kiểm toán (đọc).

  @TC-20-002 @P1 @Âm
  Kịch bản: TC-20-002 Bộ lọc sai, vai trò tỉnh và chưa xác thực khi liệt kê tenant
    # Truy vết: FR-20-002 · API-20-001 · ERR-20-004 · UI-20-01
    Biết `U-PA1`, `U-T90-TA`, `U-T90-VW`.
    Khi `GET P/tenants?size=5000`
    Và `GET P/tenants?status=XYZ`
    Và `GET P/tenants?isolationMode=KHONG-CO&page=-1`
    Và `U-T90-TA` gọi `GET P/tenants`
    Và `U-T90-VW` gọi `GET P/tenants`
    Và gọi `GET P/tenants` không có token
    Thì bước 1 đến 3 `400` `ERR-20-004`, `errors[]` trỏ `size`, `status`, `isolationMode`, `page`. Bước 4, 5 `403` `ERR-00-403` (TA, VW không gọi được `/api/platform/v1`, FRS mục 3.2). Bước 6 `401` `ERR-00-401`. Không có dữ liệu tenant nào trong thân lỗi.

  @TC-20-003 @P1 @Dương
  Kịch bản: TC-20-003 Xem chi tiết tenant theo khối include và tenant đặc biệt
    # Truy vết: FR-20-003 · UC-20-01 · API-20-003 · UI-20-03, 01 · `PERM-20-read`
    Biết `U-PA1`, `U-PAU`; `T90`, `PLATFORM`.
    Khi `GET P/tenants/T90`
    Và `GET P/tenants/T90?include=summary&include=config&include=contacts&include=modules&include=quotas&include=lastRun`
    Và `GET P/tenants/PLATFORM` bằng `U-PAU`
    Và mở `/nen-tang/tenant/T90` ở `dh-console`, đi qua bảy tab
    Thì bước 1 `200` có khối tóm tắt (`status = ACTIVE`, `realm = dh-t90`, `templateCode`, `templateVersion`, `channel`). Bước 2 trả thêm `config` (`syncStatus`, `driftStatus`, `configVersionNo`), `contacts`, `modules`, `quotas`, `lastRun`. Bước 3 `200`; tenant `PLATFORM` xem được nhưng nhãn bảo vệ hiển thị. Bước 4 bảy tab Tổng quan, Cấu hình nền tảng, Hợp đồng và đầu mối, Phân hệ, Hạn mức, Lịch sử vòng đời, Kiểm toán hiển thị theo `allowedActions[]`; `U-PAU` không thấy nút ghi.

  @TC-20-004 @P1 @Âm
  Kịch bản: TC-20-004 Chi tiết tenant không tồn tại, mã sai mẫu, khối include sai
    # Truy vết: FR-20-003 · API-20-003 · ERR-20-002, ERR-20-004 · UI-20-03
    Biết `U-PA1`; mã `T89` chưa từng khai báo.
    Khi `GET P/tenants/T89`
    Và `GET P/tenants/T9`
    Và `GET P/tenants/T90?include=khong-co`
    Và `U-T90-TA` gọi `GET P/tenants/T91`
    Thì bước 1 `404` `ERR-20-002`. Bước 2, 3 `400` `ERR-20-004`. Bước 4 `403` `ERR-00-403`, thân không nêu `T91` có tồn tại hay không. Màn UI-20-03 với mã không tồn tại dùng `ST-08`, câu "Không tìm thấy tenant T89 trong phạm vi được xem." và không lộ khác biệt giữa "không tồn tại" và "ngoài quyền xem".
