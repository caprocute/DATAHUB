# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-06
Tính năng: TS-15-06 · Tài liệu API, phiên bản, so sánh, mẫu mã

  @TC-15-032 @P1 @Dương
  Kịch bản: TC-15-032 Hiển thị OpenAPI 3.1
    # Truy vết: FR-15-009 · UC-15-05 · API-15-016, 017 · UI-15-05 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN; đặc tả `tra-cuu-ho-tich` 1.0.0 (12 thao tác, 3 tag, ví dụ, lỗi RFC 9457).
    Khi `GET /catalog/apis/tra-cuu-ho-tich/versions/1.0.0/operations`.
    Và mở UI-15-05, chọn thao tác `getHoTich`, mở bằng neo `#getHoTich`.
    Thì danh sách thao tác theo tag, tham số, lược đồ yêu cầu/đáp ứng, ví dụ, mã lỗi RFC 9457, bảo mật OAuth2; neo mở đúng thao tác; neo sai thì về đầu trang không lỗi.

  @TC-15-033 @P2 @Dương
  Kịch bản: TC-15-033 Hiển thị AsyncAPI 3.0 và 2.x
    # Truy vết: FR-15-010 · UC-15-05 · API-15-018 · UI-15-05 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết topic `ho-tich.moi-dang-ky` (3.0) và `topic-cu` (2.x).
    Khi mở UI-15-05 của hai topic.
    Thì 3.0: kênh, thông điệp, lược đồ, ví dụ, máy chủ; 2.x: hiển thị thô kèm cảnh báo "Hiển thị ở chế độ tương thích.".

  @TC-15-034 @P1 @Âm
  Kịch bản: TC-15-034 Đặc tả chưa nạp hoặc không đọc được
    # Truy vết: FR-15-009 · UC-15-05 · API-15-016, 017 · UI-15-05 · ERR-15-009 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết phiên bản có F-SPEC-BAD, chưa từng có bản hợp lệ.
    Khi `GET .../operations` và `.../spec`.
    Và mở UI-15-05.
    Thì `422` ERR-15-009; UI "Đặc tả của dịch vụ này chưa đọc được. Liên hệ đầu mối của dịch vụ." kèm nút Báo lỗi tài liệu; không `500`.

  @TC-15-035 @P1 @Dương
  Kịch bản: TC-15-035 Chọn phiên bản và tải đặc tả có kiểm toán
    # Truy vết: FR-15-011 · UC-15-05 · API-15-015, 016 · UI-15-05 · BR-15-002 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `tra-cuu-ho-tich` 0.9.0 DEPRECATED và 1.0.0.
    Khi `GET /catalog/apis/tra-cuu-ho-tich/versions`.
    Và tải đặc tả `1.0.0` dạng YAML và JSON bằng nút "Tải đặc tả".
    Thì danh sách phiên bản có trạng thái, gợi ý kế nhiệm lên đầu cho DEPRECATED; tệp tải về có băm khớp `contentHash`, mở được bằng trình soạn OpenAPI; KT: có (`DOWNLOAD_SPEC`).

  @TC-15-036 @P2 @Dương
  Kịch bản: TC-15-036 So sánh hai phiên bản
    # Truy vết: FR-15-011 · UC-15-05 · API-15-020 · UI-15-05 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết hai phiên bản có sự khác biệt đã biết: thêm 2 thao tác, đổi 1 kiểu trường, xóa 1 tham số.
    Khi `GET /catalog/apis/tra-cuu-ho-tich/diff?tu=0.9.0&den=1.0.0`.
    Thì báo đúng 2 thêm, 1 đổi, 1 xóa; thay đổi phá vỡ được đánh dấu; chỉ ở mức đọc, không có thao tác sửa.

  @TC-15-037 @P2 @Âm
  Kịch bản: TC-15-037 So sánh sai đối tượng
    # Truy vết: FR-15-011 · API-15-020 · ERR-15-001, 003, 038 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `tra-cuu-ho-tich`, `dm-hanh-chinh`, `ban-do-cu`.
    Khi so sánh phiên bản của hai API khác nhau.
    Và so sánh phiên bản không tồn tại.
    Và so sánh với phiên bản RETIRED.
    Thì lần lượt `400` ERR-15-003, `404` ERR-15-001, `410` ERR-15-038.

  @TC-15-038 @P1 @Dương
  Kịch bản: TC-15-038 Mẫu mã sáu ngôn ngữ chạy được trên sandbox
    # Truy vết: FR-15-012 · UC-15-05 · API-15-019 · UI-15-05, 06 · NFR-15-022 · LGC-APIM-017; LGC-IAM-006.
    Biết U-T68-DEV-AN; ứng dụng và credential sandbox; sáu ngôn ngữ `curl`, `java`, `python`, `javascript`, `csharp`, `go`.
    Khi `GET /catalog/apis/tra-cuu-ho-tich/samples?ngon-ngu={x}&thao-tac=getHoTich` cho từng ngôn ngữ.
    Và chạy mẫu trong container tương ứng với `clientId`, `clientSecret` thật điền vào chỗ giữ.
    Thì mẫu có URL sandbox, phương thức, tiêu đề, ví dụ tham số; hướng dẫn lấy token bằng `client_credentials` (không dùng grant `password`); chỗ giữ `<CLIENT_SECRET>`; cả sáu mẫu chạy trả `200` MOCK; ở khung thử mẫu phản ánh đúng yêu cầu đang soạn.

  @TC-15-039 @P2 @Âm
  Kịch bản: TC-15-039 Mẫu không có ngôn ngữ hoặc thao tác
    # Truy vết: FR-15-012 · API-15-019 · ERR-15-001, 003 · LGC-APIM-017; LGC-IAM-006.
    Biết U-T68-DEV-AN.
    Khi `?ngon-ngu=ruby`.
    Và `?thao-tac=khongco`.
    Thì `400` ERR-15-003 "Chưa có mẫu cho ngôn ngữ này"; `404` ERR-15-001.

  @TC-15-040 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-040 Tài liệu dữ liệu nhạy cảm: cán bộ xem có kiểm toán, nhà phát triển không thấy
    # Truy vết: FR-15-009 · UC-15-05 · API-15-016 · BR-15-004 · ERR-15-001 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `tra-cuu-dat-dai` SENSITIVE; U-T68-OR; U-T68-DEV-AN.
    Khi bình `GET /catalog/apis/tra-cuu-dat-dai/versions/1.0.0/spec`.
    Và an làm lại.
    Thì bình `200`, KT: có (`VIEW_SENSITIVE_DOCS`, `PORTAL_*`); An `404` ERR-15-001.
