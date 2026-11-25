# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-18
Tính năng: TS-07-18 · Danh mục COMMON, PLATFORM và nạp gói nền

  @TC-07-214 @P1 @Dương @Âm
  Kịch bản: TC-07-214 Tỉnh đọc COMMON, không ghi được
    # Truy vết: FR-07-048 · BR-07-001 · ERR-07-003 · LGC-DMDC-017
    Biết CAT-GT (COMMON).
    Khi U-T68-VW `GET /catalogs/GIOI_TINH/items`.
    Và U-T68-TA tạo bản nháp `GIOI_TINH`.
    Và U-T68-TA sửa thông tin `GIOI_TINH`.
    Thì bước 1 `200`, 3 bản ghi, `scope = COMMON`. Bước 2, 3 `403` `ERR-07-003`. KT: không cho bước 1; nhật ký an ninh ghi bước 2, 3.

  @TC-07-215 @P1 @Dương
  Kịch bản: TC-07-215 PLATFORM ghi COMMON, mọi tenant thấy phiên bản mới
    # Truy vết: FR-07-048 · EVT-07-05
    Biết danh mục `TC215_COMMON` tạo bởi U-PA.
    Khi U-PA tạo, thêm 2 bản ghi, trình; U-PA2 duyệt và phát hành.
    Và U-T68-VW và U-T01-DS đọc `TC215_COMMON`.
    Thì bước 2: cả hai tenant nhận cùng 2 bản ghi; bộ đệm L2 dùng khóa của `COMMON`, không nhân bản theo tenant.

  @TC-07-216 @P1 @Dương @Âm
  Kịch bản: TC-07-216 HYBRID: bổ sung trong dải mã địa phương
    # Truy vết: FR-07-048 · BR-07-010 · ERR-07-008, 012
    Biết CAT-DT68 (`^68\.[0-9]{2}$`).
    Khi U-T68-TA thêm bản ghi `68.03` vào bản nháp `DAN_TOC_T68`.
    Và thêm bản ghi `56`.
    Và thêm bản ghi `01` (trùng mã gốc).
    Thì bước 1 `201`. Bước 2 `422` `ERR-07-012`. Bước 3 `409` `ERR-07-008`.

  @TC-07-217 @P1 @Dương
  Kịch bản: TC-07-217 Nạp gói danh mục nền cho tenant mới
    # Truy vết: FR-07-049 · API-07-073 · BR-07-011
    Biết tenant `T99` vừa tạo ở PH-20 (`PROVISIONING`); gói nền chuẩn `seed-2026.11` gồm 12 danh mục.
    Khi client PH-20 gọi `POST /api/platform/rdm/v1/tenants/T99:seed` với `Idempotency-Key`.
    Và thăm dò tới khi xong.
    Thì `202`; T99 có 12 danh mục, mỗi danh mục một phiên bản `PUBLISHED`, `origin = SEED`, `effectiveFrom` theo BR-07-011; bucket `dh-t99-rdm` có ảnh chụp; EVT-07-01 và EVT-07-05 phát trên topic `t99.*`.

  @TC-07-218 @P1 @Âm
  Kịch bản: TC-07-218 Chạy lại nạp gói, gói hỏng, tenant sai trạng thái
    # Truy vết: FR-07-049 · ERR-07-019, 022, 045, 048
    Biết T99 đã nạp ở TC-07-217.
    Khi gọi lại với cùng `Idempotency-Key`, cùng thân.
    Và gọi với cùng khóa, thân khác gói.
    Và gọi với gói có tệp băm SHA-256 sai.
    Và gọi cho `T404` không tồn tại.
    Và gọi cho tenant `SUSPENDED`.
    Thì bước 1 trả kết quả cũ, không tạo thêm danh mục. Bước 2 `409` `ERR-07-022`. Bước 3 `422` `ERR-07-019`, không có danh mục nào được tạo (tất cả hoặc không). Bước 4 `404` `ERR-07-045`. Bước 5 `409` `ERR-07-048`.

  @TC-07-219 @P2 @Khả @dụng @Âm
  Kịch bản: TC-07-219 Nạp gói khi kho đối tượng chưa sẵn sàng
    # Truy vết: FR-07-049 · ERR-07-047
    Biết minIO (thay Garage) dừng.
    Khi gọi nạp gói cho `T98`.
    Và khởi động lại MinIO, gọi lại với cùng `Idempotency-Key`.
    Thì bước 1 `503` `ERR-07-047` có `Retry-After`, không để lại danh mục dở dang. Bước 2 thành công như TC-07-217.
