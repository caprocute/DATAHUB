# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-09
Tính năng: TS-15-09 · Nhập Git và di trú nội dung portal cũ

  @TC-15-057 @P2 @Dương
  Kịch bản: TC-15-057 Đồng bộ nội dung từ kho Git
    # Truy vết: FR-15-018 · UC-15-08 · API-15-038, 039, 040 · UI-15-21, 27 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-SV; kho F-GIT-OK (`portal.yaml`, 12 tệp `.md`, 4 ảnh); S-GIT.
    Khi `POST /content/git-sources` rồi `:sync`; sau đó đồng bộ lại.
    Và gọi webhook của kho.
    Thì 12 trang `DRAFT` (không tự đăng), ảnh nạp vào kho; lần hai không nhân bản (so băm); webhook kích hoạt đồng bộ ngay; chu kỳ `15.git.sync-interval-minutes` đúng.

  @TC-15-058 @P2 @Âm
  Kịch bản: TC-15-058 Kho lỗi hoặc cấu trúc sai
    # Truy vết: FR-15-018 · API-15-040 · ERR-15-025, 026, 024 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết kho không với tới; kho thiếu `portal.yaml`; kho có `.exe` và `.svg`.
    Khi `:sync` từng kho.
    Thì `502` ERR-15-025; `422` ERR-15-026 "Kho thiếu tệp portal.yaml hoặc sai cấu trúc"; tệp cấm bị bỏ và báo; không trang nào tạo từ kho lỗi.

  @TC-15-059 @P1 @Dương
  Kịch bản: TC-15-059 Di trú portal Gravitee
    # Truy vết: FR-15-062 · UC-15-08 · API-15-135, 136, 137 · UI-15-27 · BR-15-012, 013 · LGC-APIM-006.
    Biết U-T68-TA; F-ZIP-GRAVITEE (xuất portal cũ: 8 trang, 5 ảnh, 3 tài liệu API, có thẻ `<script>`).
    Khi `POST /admin/migrations` tải gói; theo dõi `GET /admin/migrations/{id}`.
    Và `POST .../{id}:confirm`.
    Thì báo cáo xem trước: 8 trang, 5 ảnh, 3 tài liệu, phần bị loại; sau xác nhận có 11 trang `DRAFT` phải qua duyệt bốn mắt mới đăng; `<script>` bị loại; ảnh nằm trong kho cổng; mọi trang nằm đúng mục hướng dẫn.

  @TC-15-060 @P2 @Âm
  Kịch bản: TC-15-060 Gói di trú sai, nhiễm mã độc, chạy song song
    # Truy vết: FR-15-062 · API-15-135, 137 · ERR-15-024, 026, 035 · BR-15-013 · LGC-APIM-006.
    Biết gói thiếu cấu trúc, gói có `.exe`, gói có EICAR, gói 51 MB; U-T68-TA, U-T68-DEV-AN.
    Khi tải từng gói; tải gói hợp lệ lần hai khi lần một đang chạy.
    Và an `POST /admin/migrations`.
    Thì `422` ERR-15-026 (ba gói đầu), `422` ERR-15-024 (EICAR); `409` ERR-15-035; An `403` ERR-15-005.
