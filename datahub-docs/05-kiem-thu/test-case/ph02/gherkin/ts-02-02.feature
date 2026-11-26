# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-02
Tính năng: TS-02-02 · Danh mục cho máy, mức hiển thị và cách ly tenant khi đọc

  @TC-02-006 @P1 @Dương
  Kịch bản: TC-02-006 Danh mục cho máy theo mức hiển thị và điều kiện `304`
    # Truy vết: FR-02-004 · API-02-004, 005, 081 · UC-02-02 · BR-02-037 · NFR-02-001 · EVT-02-05.
    Biết S-PORTAL; A-DATDAI mức hiển thị `NATIONAL`, một API `TENANT`, một API `PUBLIC`.
    Khi S-PORTAL gọi `GET /internal/portal/catalog`, ghi `ETag`.
    Và gọi lại với `If-None-Match`.
    Và `GET /catalog/apis` bằng token máy `catalog:read`.
    Thì bước 1 trả API `PUBLIC` và `NATIONAL` theo hợp đồng PH-15, không trả API `TENANT`. Bước 2: `304`. Bước 3: chỉ các API `PUBLISHED`.

  @TC-02-007 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-007 Đọc danh mục với tenant khác và token sai scope
    # Truy vết: FR-02-004 · API-02-004, 005, 081 · BR-02-033 · ERR-02-001, 014 · NFR-02-013.
    Biết A-T01; token S-GW (scope `catalog:gateway-read`).
    Khi người dùng T68 gọi `GET /catalog/apis/tc-chi-t01` và `GET /apis/khong-co`.
    Và S-GW gọi `GET /internal/portal/catalog`.
    Thì bước 1: hai lời gọi đều 404-ẩn, thân giống nhau trừ `traceId`. Bước 2: 403-PQ.

  @TC-02-008 @P3 @Dương
  Kịch bản: TC-02-008 Dịch vụ sự kiện hiển thị chỉ đọc, không thao tác vòng đời
    # Truy vết: FR-02-009 · API-02-013 · UI-02-01 · UC-02-04 · BR-02-038.
    Biết hai topic PH-10 đã công bố ở T68 (Đợt 2).
    Khi `GET /event-services`.
    Và mở UI-02-01 tab "Dịch vụ sự kiện", tìm nút đăng ký.
    Thì có hai topic kèm liên kết sang PH-10; không có nút đăng ký hay duyệt ở PH-02.

  @TC-02-087 @P1 @Dương @Âm @Biên
  Kịch bản: TC-02-087 Danh mục cho máy: phần thay đổi theo `updatedSince`, danh sách gỡ và giới hạn tần suất
    # Truy vết: FR-02-004 · API-02-004, 005 · UC-02-02 · BR-02-037, 039 · ERR-02-003 · NFR-02-001.
    Biết token máy `catalog:read` của H-KHAITHAC-1; A-DATDAI, A-DEPREC; một API sắp chuyển `RETIRED`.
    Khi `GET /catalog/apis` lấy `ETag` và mốc `T0`; sửa mô tả A-DATDAI; chuyển một API sang `RETIRED`.
    Và `GET /catalog/apis?updatedSince=T0` kèm `If-None-Match` cũ.
    Và `GET /catalog/apis?updatedSince=hôm-qua`.
    Và gọi 61 lần trong một phút bằng cùng client.
    Thì bước 2: `200`, `items` chỉ có A-DATDAI, `removed[]` có mã API đã `RETIRED`. Bước 3: `400` ERR-02-003 nêu trường `updatedSince`. Bước 4: lần thứ 61 trả `429` kèm `Retry-After` (giới hạn 60 yêu cầu mỗi phút mỗi client); các lần trước đó trả `304` hoặc `200` đúng.

  @TC-02-088 @P2 @Âm @Bảo @mật
  Kịch bản: TC-02-088 Dịch vụ sự kiện: không lộ topic tenant khác và không có thao tác ghi ở PH-02
    # Truy vết: FR-02-009 · API-02-013 · UI-02-01 · UC-02-04 · BR-02-033, 038 · ERR-02-001, 014.
    Biết topic `tc-su-kien-t68` ở T68 và `tc-su-kien-t01` ở T01 (PH-10, giả lập M-TOPIC); token máy không có scope `catalog:read`.
    Khi U-T68-VW gọi `GET /event-services`.
    Và gọi `GET /event-services` bằng token máy thiếu scope.
    Và đối chiếu tập operation của OpenAPI `dh-connect` (CI-5) với đường dẫn `/event-services`.
    Thì bước 1: chỉ thấy `tc-su-kien-t68`; không dấu vết của topic T01. Bước 2: `403` ERR-02-014. Bước 3: chỉ có `GET`, không có tạo, sửa, xóa hay đăng ký ở PH-02 (BR-02-038).
