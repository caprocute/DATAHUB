# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-07
Tính năng: TS-15-07 · Soạn trang nội dung Markdown

  @TC-15-041 @P1 @Dương
  Kịch bản: TC-15-041 Tạo trang nháp lũy đẳng
    # Truy vết: FR-15-014 · UC-15-06 · API-15-022, 023, 024 · UI-15-21 · BR-15-034 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-SV (có `PERM-15-content-write`); mã `bat-dau-nhanh`.
    Khi `POST /content/pages` {pageCode, type `QUICKSTART`, lang `vi`, audience `LOGGED_IN`, nội dung Markdown} với `Idempotency-Key` K1.
    Và gửi lại đúng yêu cầu với K1.
    Và `GET /content/pages/bat-dau-nhanh`.
    Thì bước 1 `201`, `ETag`, trạng thái `DRAFT`; bước 2 trả cùng phản hồi, không tạo bản thứ hai; bước 3 có phiên bản nháp 1 và tên người soạn.

  @TC-15-042 @P1 @Âm
  Kịch bản: TC-15-042 Mã trùng, sai mẫu, dùng lại mã đã lưu trữ
    # Truy vết: FR-15-014 · UC-15-06 · API-15-023 · ERR-15-002, 003 · BR-15-007 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-SV; `bat-dau-nhanh` tồn tại; `da-luu-tru` đã ARCHIVED.
    Khi tạo lại `bat-dau-nhanh`; tạo `Bat_Dau`; tạo `da-luu-tru`.
    Thì `409` ERR-15-002 "Mã bat-dau-nhanh đã được dùng. Chọn mã khác."; `400` ERR-15-003 (mẫu `^[a-z0-9][a-z0-9-]{1,62}$`); `409` ERR-15-002 (mã không dùng lại sau lưu trữ).

  @TC-15-043 @P1 @Âm
  Kịch bản: TC-15-043 Lọc Markdown nguy hiểm
    # Truy vết: FR-15-014 · UC-15-06 · API-15-025 · ERR-15-021 · BR-15-013 · NFR-15-011 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết F-MD-XSS: `<script>`, `<iframe>`, `<img onerror>`, `[x](javascript:alert(1))`, `![x](https://evil.test/a.png)`, HTML thô `<div style>`, `<svg onload>`.
    Khi `PUT /content/pages/bat-dau-nhanh` với từng mẫu (kèm `If-Match`).
    Và `PUT` bản có `[ok](https://example.org)`; mở UI-15-07.
    Thì mỗi mẫu `422` ERR-15-021 nêu phần không được phép và dòng; bản hợp lệ lưu được, liên kết ngoài có `rel="noopener nofollow"`; không mẫu nào được lưu vào CSDL.

  @TC-15-044 @P2 @Biên
  Kịch bản: TC-15-044 Biên cỡ trang 200 KB
    # Truy vết: FR-15-014 · API-15-025 · ERR-15-021 · BR-15-013 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-SV; hai nội dung Markdown 204.800 byte và 204.801 byte.
    Khi `PUT` hai nội dung.
    Thì bản 204.800 byte `200`; bản 204.801 byte `422` ERR-15-021 (mã lỗi cho vượt cỡ chờ Q15-41).

  @TC-15-045 @P2 @Dương
  Kịch bản: TC-15-045 Đính kèm ảnh hợp lệ và đọc lại
    # Truy vết: FR-15-014, 017 · API-15-033, 138 · BR-15-013 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-SV; F-IMG-OK (PNG 1 MB), WebP 4,9 MB.
    Khi `POST /content/attachments` hai tệp.
    Và `GET /content/attachments/{attachmentId}` bằng U-T68-DEV-AN trong trang đã đăng.
    Thì `201` có `attachmentId`; ảnh phục vụ bằng URL ký có hạn, đúng `Content-Type`, `nosniff`; ảnh nằm trong kho của cổng (không liên kết ra ngoài).

  @TC-15-046 @P1 @Âm
  Kịch bản: TC-15-046 Đính kèm không hợp lệ hoặc nhiễm mã độc
    # Truy vết: FR-15-014 · API-15-033 · ERR-15-024 · BR-15-013 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết F-IMG-SVG, ảnh 5,1 MB, EICAR đội vỏ PNG (ClamAV), polyglot GIF+JS, tệp đổi đuôi `.png`.
    Khi `POST /content/attachments` với từng tệp.
    Thì mỗi tệp `422` ERR-15-024; không tệp nào được lưu; ClamAV ghi nhận EICAR.

  @TC-15-047 @P2 @Âm
  Kịch bản: TC-15-047 Hai người sửa cùng lúc
    # Truy vết: FR-15-014 · API-15-025 · ERR-15-006 · BR-15-034 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-SV và U-T68-CA cùng mở phiên bản nháp, cùng `ETag` E1.
    Khi SV `PUT` với `If-Match: E1`; CA `PUT` với `If-Match: E1`.
    Thì lần hai `412` ERR-15-006 "Nội dung đã được người khác thay đổi. Tải lại rồi sửa tiếp."; nội dung lần một không bị ghi đè.

  @TC-15-048 @P1 @Âm
  Kịch bản: TC-15-048 Nhà phát triển và kiểm toán viên không soạn được
    # Truy vết: FR-15-014 · API-15-022, 023 · ERR-15-005 · BR-15-012 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN, U-T68-AU, U-T68-OR (không có `PERM-15-content-write`).
    Khi mỗi người `POST /content/pages`, `GET /content/pages`.
    Thì `403` ERR-15-005; không có bản ghi; menu soạn nội dung không hiện ở UI.
