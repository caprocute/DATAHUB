# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-01
Tính năng: TS-14-01 · Nền tảng quốc gia: khai báo, liệt kê, chi tiết

  @TC-14-001 @P2 @Dương
  Kịch bản: TC-14-001 Liệt kê nền tảng và mức sức khỏe
    # Truy vết: FR-14-001 · API-14-001, 003 · UI-14-02 · UC-14-01.
    Biết U-T68-VW; P-NDXP, P-NDOP; `COMMON` có một nền tảng mẫu.
    Khi mở UI-14-02; lọc loại `NDXP`.
    Và `GET /platforms?type=NDXP` rồi `GET /platforms/ndxp`.
    Thì `200`, có `ndxp` với `state = ACTIVE`, `health` (`HEALTHY`, `DEGRADED`, `UNHEALTHY`, `UNKNOWN`), nền tảng `COMMON` đọc được; chi tiết không có trường bí mật; U-T68-VW không thấy nút Khai báo.

  @TC-14-002 @P1 @Dương
  Kịch bản: TC-14-002 Khai báo nền tảng hợp lệ ở trạng thái Nháp
    # Truy vết: FR-14-002 · API-14-002, 004 · UI-14-03 · UC-14-01 · BR-14-025 · LGC-NGSP-008.
    Biết U-T68-TA; kết nối PH-05 `ndxp-oauth` (OAuth 2.1) `ACTIVE`; P-NEW chưa có.
    Khi Ở UI-14-03 chọn loại NDXP, mã `ndxp-moi`, địa chỉ mô phỏng, kết nối `ndxp-oauth`, bấm "Tạo".
    Và `PATCH /platforms/ndxp-moi` với `If-Match` đổi tên hiển thị.
    Thì bước 1 `201`, `Location`, `ETag`, `state = DRAFT`; địa chỉ, mã dịch vụ nằm ở cấu hình theo tenant, không ghi cứng. Bước 2 `200`, `ETag` mới. Kiểm toán ghi hai thao tác.

  @TC-14-003 @P1 @Âm
  Kịch bản: TC-14-003 Khai báo nền tảng sai: trùng mã, kết nối sai loại, tham số sai
    # Truy vết: FR-14-002 · API-14-002 · ERR-14-002, 003, 005 · BR-14-025.
    Biết U-T68-TA; `ndxp` đang có; nền tảng `ndxp-cu` đã `RETIRED`; kết nối PH-05 loại `http-basic`.
    Khi `POST /platforms` mã `ndxp`.
    Và `POST /platforms` mã `ndxp-cu`.
    Và `POST /platforms` cách xác thực OAuth nhưng gắn kết nối `http-basic`; rồi gắn kết nối không tồn tại.
    Và `POST /platforms` thiếu `type`.
    Thì bước 1, 2 trả `409` ERR-14-002 (kể cả đã ngừng dùng); bước 3 `422` ERR-14-005; bước 4 `400` ERR-14-003 kèm danh sách trường lỗi. Không đối tượng nào được tạo.

  @TC-14-004 @P1 @Âm @Bảo @mật
  Kịch bản: TC-14-004 Nền tảng của tenant khác trả như không tồn tại
    # Truy vết: FR-14-001 · API-14-003 · ERR-14-001 · BR-14-029 · NFR-14-024.
    Biết U-T68-TA; `T01` có nền tảng `chi-t01` mà T68 không có.
    Khi U-T68-TA gọi `GET /platforms/khong-co`.
    Và U-T68-TA gọi `GET /platforms/chi-t01`.
    Thì cả hai `404` ERR-14-001, thân giống nhau trừ `traceId`; không có thông tin tenant khác trong nhật ký trả về.
