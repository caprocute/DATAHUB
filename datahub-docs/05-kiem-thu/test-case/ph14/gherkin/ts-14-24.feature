# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-24
Tính năng: TS-14-24 · Chiều vào: đăng ký, tiếp nhận, chuyển luồng PH-04

  @TC-14-060 @P1 @Dương
  Kịch bản: TC-14-060 Đăng ký điểm cuối, nguồn được phép, xác nhận vân tay
    # Truy vết: FR-14-039 · API-14-048, 049, 050, 051, 052, 090 · UI-14-10, 17 · UC-14-26 · BR-14-027.
    Biết U-T68-TA, U-T68-SO; luồng PH-04 `lg-nhan-tb` đã phát hành.
    Khi `POST /inbound-endpoints` mã `ndxp-vao`, ánh xạ luồng.
    Và `PUT …/allowed-senders` với vân tay chứng thư S-NDXP-IN.
    Và SO `POST …:confirm` vân tay; `GET /inbound-endpoints`.
    Thì điểm cuối `ACTIVE` sau xác nhận bốn mắt; danh sách nguồn lưu đúng; `PATCH` đổi trạng thái được ghi kiểm toán.

  @TC-14-061 @P1 @Âm
  Kịch bản: TC-14-061 Đăng ký sai: trùng, nguồn rỗng, luồng chưa phát hành
    # Truy vết: FR-14-039 · API-14-049, 052 · ERR-14-023, 024, 039.
    Biết `ndxp-vao` đã có; luồng `lg-chua-phat-hanh` ở `DRAFT`.
    Khi `POST` điểm cuối trùng mã, rồi trùng đường dẫn.
    Và `PUT …/allowed-senders` danh sách rỗng.
    Và `POST` điểm cuối ánh xạ luồng `lg-chua-phat-hanh`.
    Thì `409` ERR-14-023 hai lần; `422` ERR-14-024; `422` ERR-14-039.

  @TC-14-062 @P1 @Dương
  Kịch bản: TC-14-062 Tiếp nhận yêu cầu, chuyển luồng PH-04, trả phản hồi có ký
    # Truy vết: FR-14-040, 041 · API-14-084 · UC-14-27 · BR-14-027, 028 · NFR-14-016.
    Biết S-NDXP-IN; E-NDXP-IN `ACTIVE`; luồng `lg-nhan-tb` trả mẫu.
    Khi `POST /inbound/v1/ndxp-vao/tra-cuu-dan-cu` có chữ ký hợp lệ và `messageId` mới.
    Và xem giao dịch `INBOUND`.
    Thì `200` phản hồi có chữ ký của tỉnh; luồng PH-04 nhận đúng một lần; tenant lấy từ điểm cuối, không từ thân; giao dịch `INBOUND` đủ `traceId`.

  @TC-14-063 @P1 @Âm @Bảo @mật
  Kịch bản: TC-14-063 Chiều vào bị từ chối: nguồn, mTLS, định dạng, lặp, tần suất, luồng lỗi
    # Truy vết: FR-14-040, 041 · API-14-084 · ERR-14-119, 120, 121, 122, 123, 124 · BR-14-027, 028 · NFR-14-016.
    Biết S-NDXP-LA; chứng thư mTLS hết hạn; `14.inbound.rate-limit-per-second = 50`; luồng PH-04 lỗi hoặc quá `14.inbound.timeout-ms`.
    Khi S-NDXP-LA gọi; gọi với chứng thư mTLS hết hạn.
    Và gửi bản tin thiếu chữ ký, và loại thông báo sai.
    Và gửi lại `messageId`; gửi lại cũ ngoài cửa sổ `14.inbound.replay-window-seconds`.
    Và gửi 80 lượt/giây trong 3 giây.
    Và bật luồng lỗi, rồi luồng chậm.
    Thì `403` ERR-14-119; `401` ERR-14-120; `400` ERR-14-121; lặp `409` ERR-14-122; `429` ERR-14-123; `502` ERR-14-124. Từ chối ≤ 50 ms (p99), luồng PH-04 không nhận bản tin chưa xác minh.

  @TC-14-127 @P2 @Âm @Bảo @mật
  Kịch bản: TC-14-127 Thông báo thay đổi sai: loại lạ, nguồn lạ, thiếu trường, đối tượng không có
    # Truy vết: FR-14-042 · API-14-085 · UC-14-28 · ERR-14-119, 120, 121 · BR-14-027, 028 · EVT-14-17.
    Biết S-NDXP-IN, S-NDXP-LA; E-NDXP-IN `ACTIVE`; V-HT có đệm; không có dịch vụ `tc-khong-co`.
    Khi S-NDXP-IN gửi `notificationType = KHAC`.
    Và S-NDXP-IN gửi thông báo thiếu `objectCodes`.
    Và S-LA gửi `DATA_CHANGED` hợp lệ.
    Và gửi `DATA_CHANGED` không có chữ ký.
    Và S-NDXP-IN gửi `SERVICE_CHANGED` nêu `tc-khong-co`.
    Thì bước 1 và 2 `400` ERR-14-121 "Thông báo không đúng định dạng.", đệm không bị xóa. Bước 3 `403` ERR-14-119, cảnh báo cho SO, không có đề xuất nào sinh ra. Bước 4 `400` ERR-14-121 hoặc `401` ERR-14-120 nếu chứng thư mTLS sai, không chuyển tiếp. Bước 5 `202`, giao dịch ghi `ignored = true`, không có đề xuất, không phát EVT-14-17. Cấu hình dịch vụ không bị sửa trong bất kỳ bước nào.
