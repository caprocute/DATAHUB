# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-05
Tính năng: TS-15-05 · Chi tiết dịch vụ, đường dẫn sử dụng, lộ trình ngừng

  @TC-15-027 @P1 @Dương
  Kịch bản: TC-15-027 Chi tiết, "Cách gọi API" và SLA
    # Truy vết: FR-15-006 · UC-15-03 · API-15-007, 008 · UI-15-04 · BR-15-006 · LGC-APIM-017; LGC-IAM-006.
    Biết U-T68-DEV-AN và U-T68-OR; S-PH02 trả đường dẫn sử dụng của `tra-cuu-ho-tich` theo FR-02-005.
    Khi `GET /catalog/apis/tra-cuu-ho-tich` và `/usage`.
    Và mở UI-15-04 bằng hai vai.
    Thì gateway URL và context path khớp S-PH02 (đúng tenant); hiện SLA, chủ quản, HTTT cung cấp, nhãn `dataClass`; cán bộ có nút "Đăng ký sử dụng", nhà thầu không có nút đó (chỉ "Thử API", "Tài liệu"); có nút Hỏi đáp và Báo lỗi.

  @TC-15-028 @P2 @Âm
  Kịch bản: TC-15-028 PH-02 không trả mẫu gọi
    # Truy vết: FR-15-006 · UC-15-03 · API-15-008 · UI-15-04 · ERR-15-030 · LGC-APIM-017; LGC-IAM-006.
    Biết S-PH02 trả `503` cho đường dẫn sử dụng.
    Khi mở UI-15-04 của `tra-cuu-ho-tich`.
    Thì khối "Cách gọi API" hiện "Chưa tải được mẫu gọi. Thử lại."; phần còn lại của trang hiển thị bình thường; chỉ ghi nhật ký ERR-15-030, không lỗi toàn trang.

  @TC-15-029 @P1 @Dương
  Kịch bản: TC-15-029 Phiên bản DEPRECATED: banner lộ trình ngừng, thông báo bắt buộc
    # Truy vết: FR-15-013 · UC-15-03 · API-15-015, 021 · UI-15-04, 05 · BR-15-027 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `tra-cuu-ho-tich` có `0.9.0` DEPRECATED (ngừng 31/03/2027, kế nhiệm `1.0.0`) và `1.0.0` PUBLISHED; U-T68-DEV-AN.
    Khi `GET /catalog/apis/tra-cuu-ho-tich?phien-ban=0.9.0` và `/changelog`.
    Và mở UI-15-04, UI-15-05 ở phiên bản `0.9.0`.
    Thì banner nêu ngày ngừng và liên kết phiên bản kế nhiệm; changelog liệt kê thay đổi theo thời gian, đánh dấu thay đổi phá vỡ; mặc định hiện `1.0.0`; thông báo ngừng khuyến nghị là loại bắt buộc (xem TC-15-148).

  @TC-15-030 @P2 @Biên
  Kịch bản: TC-15-030 Phiên bản SUSPENDED ẩn Thử API
    # Truy vết: FR-15-006 · UC-15-03 · UI-15-04, 06 · ERR-15-122 · BR-15-002 · LGC-APIM-017; LGC-IAM-006.
    Biết `tra-cuu-tam-ngung` SUSPENDED; U-T68-DEV-AN có ứng dụng `app-tra-cuu-ho-tich`.
    Khi mở UI-15-04.
    Và `POST /try/requests` cho API đó.
    Thì có nhãn "Tạm ngừng", nút Thử API bị ẩn; bước 2 `403` ERR-15-122.

  @TC-15-031 @P2 @Âm
  Kịch bản: TC-15-031 Phiên bản đã ngừng hẳn trả 410, changelog rỗng
    # Truy vết: FR-15-006, 009, 011, 013 · API-15-015, 016, 021 · ERR-15-038 · LGC-APIM-017; LGC-IAM-006.
    Biết `ban-do-cu` v1 RETIRED; `tra-cuu-nhay-cam` chưa có thay đổi nào; U-T68-OR.
    Khi `GET /catalog/apis/ban-do-cu/versions/1/spec`.
    Và `GET /catalog/apis/bao-cao-noi-bo/changelog`.
    Thì bước 1 `410` ERR-15-038 "Phiên bản này đã ngừng cung cấp."; bước 2 `200`, danh sách rỗng, UI hiện "Chưa có thay đổi nào được ghi nhận.".
